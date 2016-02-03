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
	opts.device  =opts.device             or "wlan0"
	opts.host    =opts.host               or "::"
	opts.addr    =opts.addr               or "ff02::1"
	opts.inport  =tonumber(opts.inport)   or 17071
	opts.outport =tonumber(opts.outport)  or 17071
	opts.range   =tonumber(opts.range)    or 1

	opts.fakesound=opts.fakesound or false

	print("Setting up MMesh...")
	print("")
	if opts.verbose then
		for i,v in pairs(opts) do
			print(i,v)
		end
	end
	print("")
	
	main.baked={}
	main.rebake=function(n) -- allow simple cyclic dependencies
		if not main.baked[n] then
			main.baked[n]={}
			require(n).bake(main,main.baked[n])
		end
		return main.baked[n]
	end

	local msg     = main.rebake("mmesh.main_msg")
	local history = main.rebake("mmesh.main_history")
	local sound   = main.rebake("mmesh.main_sound")
	local sock    = main.rebake("mmesh.main_sock")
	local gpios   = main.rebake("mmesh.main_gpios")


	main.setup=function()

		
		msg.setup()
		history.setup()
		sock.setup()
		sound.setup()
		gpios.setup()
		
	end


	main.clean=function()

		msg.clean()
		history.clean()
		sock.clean()
		sound.clean()
		gpios.clean()

	end


	main.update=function()

		msg.update()
		sock.update()
		sound.update()
		gpios.update()

	end

local checktime=0
	function main.serv()

		main.setup()
		
		print("Starting MMesh loop...")
		while true do
			main.update()
			socket.sleep(0.0001) -- 10khz ish just to keep us mostly idle
			local t=socket.gettime()
			local d=t-checktime
			checktime=t
			if d>0.1 then
				print("OVERSLEPT",d)
			end
		end

		main.clean()

	end



	return main
end

