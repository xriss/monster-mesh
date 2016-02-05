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

	local times={}
	main.times=times
	
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

	opts.echo  =tonumber(opts.echo    or 1 ) ~= 0 -- use 0 to turn off
	opts.record=tonumber(opts.record  or 1 ) ~= 0 -- use 0 to turn off
	opts.play  =tonumber(opts.play    or 1 ) ~= 0 -- use 0 to turn off

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


		times.start("msg")
		msg.update()
		times.stop("msg")

		times.start("sock")
		sock.update()
		times.stop("sock")

		times.start("sound")
		sound.update()
		times.stop("sound")

		times.start("gpios")
		gpios.update()
		times.stop("gpios")

	end

local checktime=0
	function main.serv()

		main.setup()
		
		print("Starting MMesh loop...")
		while true do
			main.update()
			socket.sleep(0.0001) -- 10khz ish just to keep us mostly idle
			
			local d=times.stop("main")
			if d>0.1 then
				print( string.format("****OVERSLEPT**** main=%0.4f msg=%0.4f sock=%0.4f gpios=%0.4f sound=%0.4f:(u=%d,m=%d,q=%d,r=%d) ",
					times.last("main") , times.last("msg") , times.last("sock") , times.last("gpios") , times.last("sound") ,
					times.count("unqueue") , times.count("mix") , times.count("queue") , times.count("rec") ) )
			end
			times.start("main")
		end

		main.clean()

	end


times.start=function(name)
	times["count_"..name]=0
	times["start_"..name]=socket.gettime()
end

times.inc=function(name)
	times["count_"..name]=(times["count_"..name] or 0) + 1
end

times.stop=function(name)
	times["stop_"..name]=socket.gettime()
	return times.last(name)
end

times.last=function(name)
	return (times["stop_"..name] or 0) - (times["start_"..name] or 0)
end

times.count=function(name)
	return (times["count_"..name] or 0)
end

	return main
end

