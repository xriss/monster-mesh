-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local cmsgpack = require("cmsgpack")       
local wstr     = require("wetgenes.string")


local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,history)
	local opts=main.opts
	local history=history or {}
	history.modname=M.modname

	history.table={}

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
history.best=function(from,id)
	local ret
	if from then
		local tab=history.table[ from ]
		if tab then
			if id then
				for i,v in ipairs(tab) do
					if v.id<=id then
						if not ret or ret.id>=v.id then -- look for lowest id that is the same or greater
							ret=v
						end
					end
				end
			end
		end
	end

	return ret
end

-- find a given packet id only
history.find=function(from,id)
	if from then
		local tab=history.table[ from ]
		for i,v in ipairs(tab or {}) do
			if v.id==id then return v end
		end
	end
end

-- find the highest id we have, returns nil if we have none
history.max=function(from)
	local tab=history.table[ it.from ]
	return tab[#tab] and tab[#tab].id
end

-- add a new item to our history cache
history.add_new=function(it)

	if it and it.from and it.id then
	
		if history.find(it.from,it.id) then return end -- already have this packet...
	
		local tab=history.table[ it.from ] or {}
		history.table[ it.from ]=tab
		
		table.insert(tab,it)
		table.sort(tab,function(a,b) return a<b end) -- keep table sorted
		
	end

end



	return history
end



