-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local socket=require("socket")

local cmsgpack=require("cmsgpack")
local zlib=require("zlib")

local wstr=require("wetgenes.string")
local wpack=require("wetgenes.pack")


local function dprint(a) print(wstr.dump(a)) end

-- turn a timeout into a success
local oktimeout=function(...)
	local a={...}
	if not a[1] and a[2]=="timeout" then return true,a[2] end
	return ...
end


--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,sock)
	local opts=main.opts
	local sock=sock or {}
	sock.modname=M.modname


sock.setup=function()

	sock.in_udp=assert(socket.udp())
	assert( sock.in_udp:settimeout(0) )
	assert( sock.in_udp:setsockname(opts.host, opts.inport) )

	sock.out_udp=assert(socket.udp())
	assert( sock.out_udp:settimeout(0) )
	assert( sock.out_udp:setsockname(opts.host,0) )
	
-- find out our ip
	local t=socket.udp()
	assert( t:settimeout(0) )
	assert( t:setsockname(opts.host,0) )
	assert( t:setpeername("fe80::1%"..opts.device,opts.outport) ) -- we want the link local address
	socket.hostname=t:getsockname()
	
--	print( socket.hostname )

end

	
sock.clean=function()

	sock.in_udp:close()
	sock.out_udp:close()

end

sock.count=0
sock.time=0
sock.update=function()

--print(sock.count)

	sock.count=sock.count+1

	local m={}
--	m.count=sock.count
	m.cmd="test"
	m.time=os.time()
	
	math.random()
	
	if m.time>sock.time then
		sock.time=m.time
		local p=math.random(1,opts.range)-1 -- add this for a random broadcast range
		assert(sock.out_udp:sendto( cmsgpack.pack(m) , opts.addr.."%"..opts.device , opts.outport+p ))
	end

	local data, ip, port
	
	repeat -- grab all incoming data packets and setup client/play buffers ( we also broadcast to ourselves )
	
		data, ip, port = sock.in_udp:receivefrom()
		if data then
			local m=cmsgpack.unpack(data)
			print( m.count, ip, port.."->"..opts.inport , m.cmd , m.time )
		else
			if ip~="timeout" then assert(data,ip) end -- timeout is not an error, but anything else is
		end
		
	until not data

end

sock.get_from=function()
	return sock.in_udp
end


	return sock
end



