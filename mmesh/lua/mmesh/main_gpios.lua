-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local wstr=require("wetgenes.string")
local wpack=require("wetgenes.pack")

local periphery=require("periphery")

local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,gpios)
	local gpios=gpios or {}
	gpios.modname=M.modname

-- configurable defaults


local newpulse=function(pin)
	local p={}
	
	p.pin=pin
	p.dest=1
	
	p.hist={}
	p.acc=0
	p.max=100
	
	p.pull=function()
-- remove any old values so we have space to push one more in
		while #p.hist >= p.max do
			local v=table.remove(p.hist,1) -- fifo rolling sample buffer
			p.acc=p.acc-v
		end
-- return current fraction
		return p.acc/p.max
	end
	
	p.push=function(v) -- 1 or 0 
		p.hist[#p.hist+1]=v
		p.acc=p.acc+v
	end
	
	p.update=function()
		local t=p.pull()
		if t<p.dest then	p.pin:write(true) 	p.push(1)
		else				p.pin:write(false)	p.push(0)
		end
	end

	return p
end


gpios.setup=function()

	local GPIO=periphery.GPIO

-- may fail, we may not be on a PI, so no gpios to fiddle with	
-- if it fails we just keep going without it
	pcall(function()
		gpios.pinR=assert( GPIO( {pin=13,direction="high"} ) )
		gpios.pinG=assert( GPIO( {pin=19,direction="high"} ) )
		gpios.pinB=assert( GPIO( {pin=26,direction="high"} ) )
		gpios.pinS=assert( GPIO( {pin=16,direction="in"} ) )
		
		gpios.pulse={}
		
		gpios.pulse.R=newpulse(gpios.pinR)
		gpios.pulse.G=newpulse(gpios.pinG)
		gpios.pulse.B=newpulse(gpios.pinB)
		
		print("GPIO setup")
		
		gpios.active=true
	end)
end

gpios.color=function(r,g,b)
	if not gpios.active then return end
	
	if not g then -- just one number so split to rgb
		b=(math.floor(r)%256)/255
		g=(math.floor(r/256)%256)/255
		r=(math.floor(r/65536)%256)/255
	end

	gpios.pulse.R.dest=r
	gpios.pulse.G.dest=g
	gpios.pulse.B.dest=b

end

	
gpios.clean=function()
	if not gpios.active then return end
end

gpios.button_state=false
gpios.button_press=false
gpios.button_release=false

local colors={
	0x000000,0x0000ff,
	0xff0000,0xff00ff,
	0x00ff00,0x00ffff,
	0xffff00,0xffffff,
}
local color_idx=2

gpios.update=function()
	if not gpios.active then return end
	
	local b=not gpios.pinS:read() -- read button
--	print(gpios.pinS.direction,b)
	
	gpios.button_press=false
	gpios.button_release=false
	if b~=gpios.button_state then -- flag state change
		gpios.button_state=b
		if b then gpios.button_press=true else gpios.button_release=true end
	end
	
	if gpios.button_press then
		print("!CLICK!")
		color_idx=color_idx+1
		if color_idx>#colors then color_idx=1 end
	end

	gpios.color(colors[color_idx])

-- update RGB color
	for i,v in pairs(gpios.pulse) do v.update() end
	
end

gpios.is_button_down=function()

	if not gpios.active then return true end -- always held down

	if gpios.pinS:read() then return true else return false end -- test the real button
	
end

	return gpios
end



