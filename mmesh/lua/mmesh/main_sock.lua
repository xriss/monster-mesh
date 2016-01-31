-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local socket=require("socket")

local cmsgpack=require("cmsgpack")
local zlib=require("zlib")

local wstr=require("wetgenes.string")
local wpack=require("wetgenes.pack")


local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,sock)
	local sock=sock or {}
	sock.modname=M.modname

-- configurable defaults
sock.host="::"
sock.broad="ff02::1%wlan0"
sock.in_port=17071
sock.out_port=17071


sock.setup=function()

	sock.in_udp=assert(socket.udp())
	assert( sock.in_udp:settimeout(0) )
	assert( sock.in_udp:setsockname(sock.host, sock.in_port) )

	if sock.out_port == sock.in_port then -- send and receive on same port
		sock.out_udp=sock.in_udp
	else
		sock.out_udp=assert(socket.udp())
		assert( sock.out_udp:settimeout(0) )
	end

end

	
sock.clean=function()

	sock.udp:close()

end

sock.count=0
sock.update=function()

--print(sock.count)

	sock.count=sock.count+1

	local m={}
	m.count=sock.count
	m.cmd="test"
	m.time=os.time()
	
	
--	assert(
	 sock.out_udp:sendto( cmsgpack.pack(m) , sock.broad , sock.out_port )
--	 )

	local data, ip, port
	
	repeat -- grab all incoming data packets and setup client/play buffers ( we also broadcast to ourselves )
	
		data, ip, port = sock.in_udp:receivefrom()
		if data then
			local m=cmsgpack.unpack(data)
			print( m.count, ip, port , m.cmd , m.time )
		end
		
	until not data

end


	return sock
end



