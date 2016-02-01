-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

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

msg.setup=function()

end

	
msg.clean=function()

end


-- send out pulse msgs from here
msg.time=0
msg.update=function()

	local nowtime=os.time()
	if nowtime>msg.time then -- every second
		msg.time=nowtime

		local m={}
		
		m.cmd="gots"
		m.time=nowtime
		m.gots=history.gots()
		
		sock.send(m)

	end

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
	m.time=os.time()     -- local time, probably way out of sync
	m.from=sock.hostname -- hopefully this is a unique id per device

	history.add_new(m)
	
end


-- push msgs into here
msg.push=function(m)

	
	if     m.cmd=="wants" then -- if we have a requested packet then broadcast it

		print( m._ip, m._port.."->"..opts.inport , m.cmd , m.time , #m.wants )
		
		for addr,idx in pairs(m.wants) do
			
			local v=history.best(addr,idx)
			if v then
				msg.send(v) -- broadcast this opus msg
			end
		
		end

	elseif m.cmd=="gots" then -- someone is telling us what packets they have
		local c=0 for i,v in pairs( m.gots ) do c=c+1 end
		print( m._ip, m._port.."->"..opts.inport , m.cmd , m.time , c )

	elseif m.cmd=="opus" then -- keep opus packets in history

		if type(m.hops)=="number" then m.hops=m.hops+1 end -- inc hops
		history.add_new(m)

		print( m._ip, m._port.."->"..opts.inport , m.cmd , m.time , m.hops )

	else

		print( m._ip, m._port.."->"..opts.inport , m.cmd , m.time )
	
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



