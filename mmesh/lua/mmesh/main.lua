-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wwin=require("wetgenes.win") -- handle windows and other system functions

local wpack=require("wetgenes.pack")
local wstr=require("wetgenes.string")

local socket=require("socket")

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(opts,main)
	main=main or {}
	main.modname=M.modname

	main.sound=require("mmesh.main_sound").bake(main)
	main.sock=require("mmesh.main_sock").bake(main)
	main.gpios=require("mmesh.main_gpios").bake(main)


main.setup=function()

	print("Setting up MMesh...")
	for i,v in pairs(opts) do
		print(i,v)
	end
	
--	main.sock.setup()
	main.sound.setup()
	main.gpios.setup()
	
end


main.clean=function()

--	main.sock.clean()
	main.sound.clean()
	main.gpios.clean()

end


main.update=function()

--	main.sock.update()
	main.sound.update()
	main.gpios.update()

end


function main.serv()

	main.setup()
	
	print("Starting MMesh loop...")
	while true do
		main.update()
--		socket.sleep(0.0001) -- 100hz ish
	end

	main.clean()

end



	return main
end

