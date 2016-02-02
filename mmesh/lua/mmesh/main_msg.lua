-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local socket=require("socket")

local wstr     = require("wetgenes.string")


local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,msg)
	local opts=main.opts
	local msg=msg or {}
	msg.modname=M.modname

	local sock    = main.rebake("mmesh.main_sock")
	local history = main.rebake("mmesh.main_history")
	
msg.str={}

-- convert time to something printable
msg.str.time=function(v) -- ignore top bits
	return string.format("%04d",math.floor(100*(v%100)))
end

-- convert ip to something printable
msg.str.ip=function(v)
	local p=#v+1
	local l=msg.str.ip_last
	msg.str.ip_last=v
	if l then
		for i=1,#v do
			if l:sub(1,i) ~= v:sub(1,i) then p=i break end
		end
	end
	return v:sub(p) -- the unique part ( compared to the last ip ) 
end


msg.setup=function()

end

	
msg.clean=function()

end


-- we can handle pulse style repetitive actions here
msg.time_1s=0
msg.time_500ms=0
msg.time_200ms=0
msg.update=function()

	local nowtime=socket.gettime()

	if nowtime>=msg.time_1s+1 then -- every second
		msg.time_1s=nowtime


	end

	if nowtime>=msg.time_500ms+0.5 then -- every 500ms
		msg.time_500ms=nowtime
		
		msg.send_gots()
		
	end

	if nowtime>=msg.time_200ms+0.2 then -- every 200ms
		msg.time_200ms=nowtime
		
		msg.send_wants()
		
	end

end

-- check what we have and whats available
-- then send out our gots and wants
msg.send_wants=function()

	local m={}
	
	m.cmd="wants"
	m.time=socket.gettime()
	m.wants=history.wants()
	
--	sock.send(m)

end

-- check what we have and whats available
-- then send out our gots and wants
msg.send_gots=function()

	local m={}
	
	m.cmd="gots"
	m.time=socket.gettime()
	m.gots=history.gots()
	
	sock.send(m)

end


-- push new (localy generated) opus packet data into here
-- we add meta data and send it to history for later use
msg.opus_idx=0
msg.opus=function(w)

	msg.opus_idx=msg.opus_idx+1

	local m={} -- new msg
	
	m._local=true -- flag as generated on this machine
	m.cmd="opus"
	m.opus=w
	m.hops=0	-- number of hops to get to us, inc when received
	
	m.idx=msg.opus_idx    -- increment counter, should probably wrap it at 0x7fffffff or something
	m.time=socket.gettime()     -- local time, probably way out of sync
	m.from=sock.hostname..":"..opts.inport -- hopefully this is a unique id per device

	history.new_opus(m)

	local v={}
	
	v.cmd="gots"
	v.time=socket.gettime()
	v.gots=history.gots(m.from)
	
	sock.send(v)
	
end


-- push msgs into here
msg.push=function(m)

	
	if     m.cmd=="wants" then -- if we have a requested packet then broadcast it

		local t
		local c=0 for i,v in pairs( m.wants ) do c=c+1 t=t or {i,v} end
		print( msg.str.ip(m._ip), m._port.."->"..opts.inport , m.cmd , msg.str.time(m.time) , c , c>0 and t[1] , c>0 and t[2] )
		
		for addr,idx in pairs(m.wants) do
			
			repeat
				local v=history.best(addr,idx)

--print(addr,idx,v, #(history.table[ addr ] or {}) )

				if v then
					msg.send(v) -- broadcast this opus msg
				end
				
				idx=idx+1
			until not v
		
		end

	elseif m.cmd=="gots" then -- someone is telling us what packets they have
		local t
		local c=0 for i,v in pairs( m.gots ) do c=c+1 t=t or {i,v} end
		print( msg.str.ip(m._ip), m._port.."->"..opts.inport , m.cmd , msg.str.time(m.time) , c ,c>0 and msg.str.ip(t[1]),c>0 and t[2])
		
		for addr,idx in pairs( m.gots ) do
			if idx > ( history.max(addr) or 0 ) then -- something new

--				local m={} -- new msg
				
--				m.cmd="wants"
--				m.wants={ [addr] = (history.max(addr) or 0)+1 }
--				m.time=socket.gettime()

--				msg.send(m)

			end
		end

	elseif m.cmd=="opus" then -- keep opus packets in history

		if type(m.hops)=="number" then m.hops=m.hops+1 end -- inc hops
		
		history.new_opus(m)

		print( msg.str.ip(m.from) , m.idx , m.cmd , msg.str.time(m.time) , m.hops )

	else

		print( msg.str.ip(m._ip), m._port.."->"..opts.inport , m.cmd , msg.str.time(m.time) )
	
	end
	
--[[
	m.test={ok="ok",_ok="_ok"}
	dprint( m )
	dprint( msg.filter(m) )
]]

end

-- return a new message with all _ prefixes filtered out
msg.filter=function(m)

	local f
	
	f=function(m)
		local t={}
		for i,v in pairs(m) do
			if (type(i)~="string") or (i:sub(1,1)~="_") then -- ignore strings beginning with _
				if type(v)=="table" then 
					t[i]=f(v) -- recurse
				else
					t[i]=v
				end
			end
		end
		return t
	end

	return f(m)
end

-- filter and then send
msg.send=function(m)
	sock.send( msg.filter(m) )
end

	return msg
end



