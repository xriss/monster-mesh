-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local cmsgpack = require("cmsgpack")       
local wstr     = require("wetgenes.string")


local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,history)
	local opts=main.opts
	history.modname=M.modname

	local msg     = main.rebake("mmesh.main_msg")

	history.tabmax=64 -- maximum entries for each from addr
	history.table={}

-- info about currently playing sources
	history.playing={}

history.setup=function()

end

	
history.clean=function()

end



history.remove_old=function()

	for addr,tab in pairs(history.table) do
		while #tab>history.max do table.remove(tab,1) end
	end

end


-- a packet has been requested, find the best packet we have to broadcast
history.best=function(from,idx)
	local ret
	local tab=history.table[ from ]
	if tab then
		for i,v in ipairs(tab) do
			if v.idx<=idx then
				if not ret or ret.idx>=v.idx then -- look for lowest idx that is the same or greater
					ret=v
				end
			end
		end
	end
	return ret
end

-- find a given packet idx only
history.find=function(from,idx)
	if from then
		local tab=history.table[ from ]
		for i,v in ipairs(tab or {}) do
			if v.idx==idx then return v end
		end
	end
end

-- find the highest idx we have, returns nil if we have none
history.max=function(from)
	local tab=history.table[ from ]
	return tab[#tab] and tab[#tab].idx
end

-- add a new item to our history cache
history.add_new=function(it)

	if it and it.from and it.idx then
	
		if history.find(it.from,it.idx) then return end -- already have this packet...
	
		local tab=history.table[ it.from ] or {}
		history.table[ it.from ]=tab
		
		it._time=os.time() -- remember our time stamp, we strip out all _ prefixed data before passing the msg on
		table.insert(tab,it)
		table.sort(tab,function(a,b) return a.idx<b.idx end) -- keep table sorted by idx
		
		while #tab>history.tabmax do table.remove(tab,1) end
		
	end

end

-- return map of highest packet id we have available for each broadcaster in our history
-- this is then sent in a had packet
history.gots=function(from)
	if from then -- only this broadcaster please
		return { from = history.max(from) }
	else -- all
		local r={}
		for addr,tab in pairs(history.table) do
			r[addr]=history.max(addr)
		end
		return r
	end
end


	return history
end



