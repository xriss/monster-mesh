-- copy all globals into locals, some locals are prefixed with a G to reduce name clashes
local coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,Gload,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require=coroutine,package,string,table,math,io,os,debug,assert,dofile,error,_G,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,_VERSION,xpcall,module,require

local cmsgpack=require("cmsgpack")
local zlib=require("zlib")

local wstr=require("wetgenes.string")
local wpack=require("wetgenes.pack")

local wopus_core=require("wetgenes.opus.core")


local al=require("al")
local alc=require("alc")
--local kissfft=require("kissfft.core")
--local wzips=require("wetgenes.zips")

local function dprint(a) print(wstr.dump(a)) end

--module
local M={ modname=(...) } ; package.loaded[M.modname]=M

M.bake=function(main,sound)
	local opts=main.opts
	local sound=sound or {}
	sound.modname=M.modname

	local history = main.rebake("mmesh.main_history")
	local msg     = main.rebake("mmesh.main_msg")
	local gpios   = main.rebake("mmesh.main_gpios")

-- configurable defaults
sound.samplerate=48000
sound.quality=(sound.samplerate*16)/16	-- opus bitrate, I think we want audio packets of less than 1k each
sound.packet_ms=60 --60
sound.packet_size=sound.packet_ms*sound.samplerate/1000
sound.echo_ms=sound.packet_ms*5 -- sound.packet_ms*3
sound.echo_size=sound.echo_ms*sound.samplerate/1000
sound.playback_buffers=math.floor(240/sound.packet_ms)

sound.echo_count=0

sound.setup=function()

	pcall(function()
		sound.dev=alc.CaptureOpenDevice(nil,sound.samplerate,al.FORMAT_MONO16,sound.samplerate*1)
		alc.CaptureStart(sound.dev)
		print("CAPTURE START")
	end)
	
--	sound.fft=kissfft.start(sound.fftsiz)
--	sound.dsamples=pack.alloc(sound.fftsiz*2)
--	sound.u8_dat=pack.alloc(sound.fftsiz)

	sound.count=0
	sound.div=1
	
	sound.encoder=wopus_core.encoder_create(sound.samplerate,1,nil,sound.quality)
	sound.decoder=wopus_core.decoder_create(sound.samplerate,1)
	sound.echo   =wopus_core.echo_create(sound.packet_size,sound.echo_size)
	
	sound.encode_wav_echo=wpack.alloc(sound.packet_size*2)
	sound.encode_wav=wpack.alloc(sound.packet_size*2)
	sound.encode_dat=wpack.alloc(sound.packet_size*2)

	sound.decode_wav=wpack.alloc(sound.packet_size*2)
--	sound.decode_dat=wpack.alloc(sound.packet_size*2)

	sound.zero_wav=string.rep("\0",sound.packet_size*2) -- empty wav
	


	local data="00000000zzzzzzzz" -- fake test sample data should be squarewave ishhh
	
	sound.ctx=alc.setup()
	sound.source=al.GenSource()
	sound.buffers_empty={} for i=1,sound.playback_buffers do sound.buffers_empty[i]=al.GenBuffer() end
	sound.buffers_queue={}
	sound.wav_played={}

	al.Listener(al.POSITION, 0, 0, 0)
	al.Listener(al.VELOCITY, 0, 0, 0)
	al.Listener(al.ORIENTATION, 0, 0, -1, 0,1,0 )

	al.Source(sound.source, al.PITCH, 1)
	al.Source(sound.source, al.GAIN, 1)
	al.Source(sound.source, al.POSITION, 0, 0, 0)
	al.Source(sound.source, al.VELOCITY, 0, 0, 0)
	al.Source(sound.source, al.LOOPING, al.FALSE)

--	al.BufferData(sound.buffer,al.FORMAT_MONO16,data,#data,261.626*8) -- C4 hopefully?

--	al.Source(sound.source, al.BUFFER, sound.buffer)
--	al.Source(sound.source, al.LOOPING,al.TRUE)
--	al.SourcePlay(sound.source)
	
--	al.CheckError()

	sound.active=true

end


sound.clean=function()
	if not sound.active then return end

	al.DeleteSource(sound.source)
	al.DeleteBuffer(sound.buffer)
	sound.ctc:clean() -- destroy context

	sound.encoder=wopus_core.encoder_destroy(sound.encoder)
	sound.decoder=wopus_core.decoder_destroy(sound.decoder)

	if sound.dev then
		alc.CaptureStop(sound.dev)
		alc.CaptureCloseDevice(sound.dev)
	end

end

sound.update=function()
	if not sound.active then return end


-- remove finished buffers from buffers_queue and place them in buffers_empty
	while al.GetSource(sound.source,al.BUFFERS_PROCESSED)>0 do
		local b=al.SourceUnqueueBuffer(sound.source)
		local idx
		for i,v in ipairs(sound.buffers_queue) do -- find and remove it
			if v==b then idx=i break end
		end
		assert(idx)
		table.remove(sound.buffers_queue,idx)
		table.insert(sound.buffers_empty,b)
--print("unqueue ",b)

	end

-- fill any buffers in buffers_empty with data then place them in buffers_queue
	if sound.buffers_empty[1] then -- fill the empty queue
		local b=sound.buffers_empty[1]
		
		sound.mix_s16_init( sound.packet_size )
		if opts.play then
			for i,v in ipairs( history.get_play_packets() ) do -- find all new packets to play
				sound.decode_siz=wopus_core.decode(sound.decoder, v.opus ,sound.decode_wav,0) -- decode the packet
				sound.mix_s16_push( sound.decode_wav ) -- and add it to the mix
			end
		end
		local wav=sound.mix_s16_pull() -- this is our buffer to play

		sound.wav_played[#sound.wav_played+1]=wav -- remember what we played
		al.BufferData(b,al.FORMAT_MONO16,wav,sound.packet_size*2,sound.samplerate)

		al.SourceQueueBuffer(sound.source,b)
--print("queue ",b)
		table.remove(sound.buffers_empty,1)
		table.insert(sound.buffers_queue,b)
	end

	local astate=al.GetSource(sound.source, al.SOURCE_STATE)
	if astate ~= al.PLAYING then
--print("PLAY",astate,al.PLAYING)
		al.SourceStop(sound.source)
		al.SourcePlay(sound.source)
	end

if sound.dev then
	local c=alc.Get(sound.dev,alc.CAPTURE_SAMPLES) -- check available samples
	if c>=sound.packet_size then -- we have one packets worth so grab it and encode
		
-- capture some audio
		alc.CaptureSamples(sound.dev,sound.encode_wav_echo,sound.packet_size) -- get

		if not sound.wav_played[1] then print("ECHO BUFFER UNDERFLOW") end

		local wav=sound.wav_played[1] or sound.zero_wav -- use last played sound or zero buffer
		wopus_core.echo_cancel(sound.echo,sound.encode_wav_echo,wav,sound.encode_wav)
		if sound.wav_played[1] then table.remove(sound.wav_played,1) end -- remove the used buffer
		while sound.wav_played[8] do table.remove(sound.wav_played,1) end -- and trim the fat so we don't get out of sync
-- encode to an opus packet with echo cancellation
		sound.encode_siz=wopus_core.encode(sound.encoder,sound.encode_wav,sound.encode_dat) 
-- check for encoder errors
		assert(sound.encode_siz~=-1)

-- remember the compressed opus packet and broadcast it	out to anyone listening
		if opts.record then
		
			if gpios.is_button_down() then -- only record whilst button is pressed
				msg.opus(wpack.tostring(sound.encode_dat,sound.encode_siz))
			end
		end


	end
end

end

-- dumb rawlua sound mixing (probably an okish speed actually thanks to luajit)
-- all buffers are len samples long
sound.mix_s16_init=function(len) -- initialise data to this size
	local data={}
	for i=1,len do data[i]=0 end -- zero all
	
	sound.mix_s16_push=function(buff) -- add this sound buffer to the data

		local t=wpack.load_array(buff,"s16",0,len*2)

--print(len,#data,#t)
		for i=1,len do
			data[i] = data[i] + t[i] -- add
		end
		
	end
	
	sound.mix_s16_pull=function() -- save the data to a string

		local r=wpack.save_array(data,"s16",0,len)

--print(#r)

		return r

	end

end
sound.mix_s16_push=function()end -- sanity
sound.mix_s16_pull=function()end -- and safety


	return sound
end



