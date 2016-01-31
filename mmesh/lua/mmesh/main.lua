-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

--local wwin=require("wetgenes.win") -- handle windows and other system functions

local wpack=require("wetgenes.pack")
local wstr=require("wetgenes.string")

local socket=require("socket")

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(opts,main)
	main=main or {}
	main.modname=M.modname
	
	local t={} -- process command line opts
	local lastkey
	for i,l in ipairs(opts) do
		local k,v=string.match(l, "%-%-([^=]+)=([^=]+)")   -- check for --key=value
		if not k then k=string.match(l, "%-%-([^=]+)") end -- check for just --key
		if k then
			t[k]=v or true
			if not v then lastkey=k else lastkey=nil end
		else
			if not(l=="--" and i==1) then -- skip the first -- which is just telling the lua executable to ignore my args
				if lastkey then
					t[lastkey]=l
				else
					t[#t+1]=l
				end
				lastkey=nil
			end
		end
	end
	opts=t
	main.opts=opts -- remember these processed opts

--print(wstr.dump(t))
--os.exit()

-- configurable defaults
	opts.host    =opts.host               or "::"
	opts.addr    =opts.addr               or "ff02::1" -- "ff02::1%wlan0"
	opts.inport  =tonumber(opts.inport)   or 17071
	opts.outport =tonumber(opts.outport)  or 17071
	opts.range   =tonumber(opts.range)    or 1

	print("Setting up MMesh...")
	print("")
	if opts.verbose then
		for i,v in pairs(opts) do
			print(i,v)
		end
	end
	print("")

	main.sound=require("mmesh.main_sound").bake(main)
	main.sock=require("mmesh.main_sock").bake(main)
	main.gpios=require("mmesh.main_gpios").bake(main)


main.setup=function()

	
	main.sock.setup()
--	main.sound.setup()
--	main.gpios.setup()
	
end


main.clean=function()

	main.sock.clean()
--	main.sound.clean()
--	main.gpios.clean()

end


main.update=function()

	main.sock.update()
--	main.sound.update()
--	main.gpios.update()

end


function main.serv()

	main.setup()
	
	print("Starting MMesh loop...")
	while true do
		main.update()
		socket.sleep(0.0001) -- 10khz ish just to keep us idle
	end

	main.clean()

end



	return main
end

