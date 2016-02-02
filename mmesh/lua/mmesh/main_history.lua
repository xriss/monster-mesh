-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local socket=require("socket")

local cmsgpack = require("cmsgpack")       
local wstr     = require("wetgenes.string")


local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,history)
	local opts=main.opts
	history.modname=M.modname

	local msg     = main.rebake("mmesh.main_msg")

-- our history of opus packets that we can play and or pass on to others
-- indexed by source name
	history.opus={}
	history.opus_max=64      -- maximum entries to keep for each addr
	history.opus_lifetime=64 -- how long do we keep these entries alive 

-- info about currently playing sources, ie the last sound we made
-- indexed by source name
	history.play={}
	history.play_lifetime=64 -- how long do we keep these entries alive 

-- info about currently available sources and from who they are available
-- indexed by source name
	history.avail={}
	history.avail_lifetime=32 -- how long do we keep these entries alive 


history.setup=function()

end

	
history.clean=function()

end



history.remove_old=function()

	local nowtime=socket.gettime()

	for i=#history.avail,1,-1 do local v=history.avail[i]
		if  v.time > nowtime+history.avail_lifetime then
			table.remove(history.avail,i)
		end
	end

	for i=#history.play,1,-1 do local v=history.play[i]
		if  v.time > nowtime+history.play_lifetime then
			table.remove(history.play,i)
		end
	end

	for addr,tab in pairs(history.opus) do
		while #tab>history.max do table.remove(tab,1) end
	end

end


-- a packet has been requested, find the best packet we have to broadcast
history.best=function(from,idx)
	local ret
	local tab=history.opus[ from ]
	if tab then
		for i,v in ipairs(tab) do
			if v.idx>=idx then
				if (not ret) or (ret.idx>=v.idx) then -- look for lowest idx that is the same or greater
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
		local tab=history.opus[ from ]
		for i,v in ipairs(tab or {}) do
			if v.idx==idx then return v end
		end
	end
end

-- find the highest idx we have, returns nil if we have none
history.max=function(from)
	local tab=history.opus[ from ]
	return tab and tab[#tab] and tab[#tab].idx
end

-- add a new item to our history cache
history.new_opus=function(it)

	if it and it.from and it.idx then
	
		if history.find(it.from,it.idx) then return end -- already have this packet...
	
		local tab=history.opus[ it.from ] or {}
		history.opus[ it.from ]=tab
		
		it._time=socket.gettime() -- remember our time stamp, we strip out all _ prefixed data before passing the msg on
		table.insert(tab,it)
		table.sort(tab,function(a,b) return a.idx<b.idx end) -- keep table sorted by idx
		
		while #tab>history.opus_max do table.remove(tab,1) end
		
	end

end

-- return map of highest packet id we have available from each broadcaster in our history
-- this is then sent in a had packet
history.gots=function(from)
	if from then -- only this broadcaster please
		return { [from] = history.max(from) }
	else -- all
		local r={}
		for addr,tab in pairs(history.opus) do
			r[addr]=history.max(addr)
		end
		return r
	end
end

-- return map of packets we can see (other peoples gots) that we want
history.wants=function(from)

--	for addr,idx in pairs( m.gots ) do
--		if idx > ( history.max(addr) or 0 ) then -- something new

--			local m={} -- new msg
			
--			m.cmd="wants"
--			m.wants={ [addr] = (history.max(addr) or 0)+1 }
--			m.time=socket.gettime()

--			msg.send(m)

--		end
--	end
end


	return history
end



