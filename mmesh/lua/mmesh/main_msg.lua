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
	if not v then return end
	return string.format("%04d",math.floor(100*(v%100)))
end

-- convert ip to something printable
msg.str.ip=function(v)
	if not v then return end
	return v:sub(-16)
end

msg.str.ipmember=function(t)
	if not t then return end
	local idx,val,count
	count=0
	for i,v in pairs(t) do
		if not idx then idx=i val=v end
		count=count+1
	end
	if idx and val and count then
		if type(idx)=="string" then
			return idx:sub(-16).."+"..string.format("%04d",(tonumber(val) or 0)).."#"..count
		else
			return "?-?-"..idx
		end
	end
end

-- convert a msg into a string and print it
msg.print=function(m)
	local s="%16s %8s %8s %1s %1s %1s %1s %20s"
	local t={"","","","","","","",""}

	t[1]=msg.str.ip(m.from or m._addr) or "?"
	t[2]=m.cmd
	t[3]=msg.str.time(m.time) or "????"

	if     m.cmd=="gots" then
	
		t[8]=msg.str.ipmember(m.gots) or "?"

	elseif m.cmd=="wants" then

		t[8]=msg.str.ipmember(m.wants) or "?"

	elseif m.cmd=="opus" then

		t[8]=(m.idx or 0).."#"..(m.opus and #m.opus or 0)

	else
	
	end

	print( string.format(s,unpack(t)) )
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

		history.remove_old() -- make sure we forget
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
	m.from=sock.addr
	m.time=socket.gettime()
	m.wants=history.wants()
	
	if m.wants then
		sock.send(m)
	end
end

-- check what we have and whats available
-- then send out our gots and wants
msg.send_gots=function()

	local m={}
	
	m.cmd="gots"
	m.from=sock.addr
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
	m.from=sock.addr -- hopefully this is a unique id per device

	history.new_opus(m)

	msg.send(m) -- always broadcast locally generated opus msgs
	
end


-- push msgs into here
msg.push=function(m)
	
	if     m.cmd=="wants" then -- if we have a requested packet then broadcast it

		msg.print(m)
		
		for addr,idx in pairs(m.wants) do
			
			repeat
				local v=history.best(addr,idx)

				if v then
					msg.send(v) -- just broadcast any requested opus packets we have
				end
				
				idx=idx+1
			until not v
		
		end

	elseif m.cmd=="gots" then -- someone is telling us what packets they have

		msg.print(m)

		history.new_gots(m)

	elseif m.cmd=="opus" then -- keep opus packets in history

		if type(m.hops)=="number" then m.hops=m.hops+1 end -- inc hops as the msg passes through
		msg.print(m)
		
		history.new_opus(m)

	else

		msg.print(m)
	
	end
	

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



