#!/usr/local/bin/gamecake

local global=require("global") -- prevent accidental global use

require("apps").default_paths() -- default search paths so things can easily be found

math.randomseed( os.time() ) -- try and randomise a little bit better

-- special bake and serv with out an oven (IE no window)

local main=require("mmesh.main")
return main.bake({...}):serv()
