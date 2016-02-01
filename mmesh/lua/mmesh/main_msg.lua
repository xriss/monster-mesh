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
		
		m.cmd="test"
		m.id=0
		m.t=nowtime
		sock.send(m)

	end

end


-- push msgs into here
msg.got=function(m)

	print( m._ip, m._port.."->"..opts.inport , m.cmd , m.id , m.t )
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



