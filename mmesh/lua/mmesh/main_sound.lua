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

-- configurable defaults
sound.samplerate=48000
sound.quality=(sound.samplerate*16)/32
sound.packet_ms=60
sound.packet_size=sound.packet_ms*sound.samplerate/1000
sound.echo_ms=sound.packet_ms*3
sound.echo_size=sound.echo_ms*sound.samplerate/1000


sound.setup=function()

	pcall(function()
		sound.dev=alc.CaptureOpenDevice(nil,sound.samplerate,al.FORMAT_MONO16,16384)
		alc.CaptureStart(sound.dev)
	end)
	
--	sound.fft=kissfft.start(sound.fftsiz)
--	sound.dsamples=pack.alloc(sound.fftsiz*2)
--	sound.u8_dat=pack.alloc(sound.fftsiz)

	sound.count=0
	sound.div=1
	
	sound.encoder=wopus_core.encoder_create(sound.samplerate,1,nil,sound.quality) -- 1/16th the size seems good quality?
	sound.decoder=wopus_core.decoder_create(sound.samplerate,1)
	sound.echo   =wopus_core.echo_create(sound.packet_size,sound.echo_size)
	
	sound.encode_wav_echo=wpack.alloc(sound.packet_size*2)
	sound.encode_wav=wpack.alloc(sound.packet_size*2)
	sound.encode_dat=wpack.alloc(sound.packet_size*2)

	sound.decode_wav=wpack.alloc(sound.packet_size*2)
--	sound.decode_dat=wpack.alloc(sound.packet_size*2)
	


	local data="00000000zzzzzzzz" -- fake test sample data should be squarewave ishhh
	
	sound.ctx=alc.setup()
	sound.source=al.GenSource()
	sound.buffers_empty={al.GenBuffer(),al.GenBuffer(),al.GenBuffer()}
	sound.buffers_queue={}
	sound.wav_queue={}
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


-- remove finished buffers
	for i=1,al.GetSource(sound.source,al.BUFFERS_PROCESSED) do
		local b=al.SourceUnqueueBuffer(sound.source)
		local idx
		for i,v in ipairs(sound.buffers_queue) do -- find and remove, it should be the first one.
			if v==b then idx=i break end
		end
		assert(idx)
		table.remove(sound.buffers_queue,idx)
		table.insert(sound.buffers_empty,b)
--print("unqueue ",b)
	end

	if sound.buffers_empty[1] and sound.wav_queue[1] then -- fill the empty queue
		local b=sound.buffers_empty[1]
		sound.wav_played[#sound.wav_played+1]=sound.wav_queue[1]
		al.BufferData(b,al.FORMAT_MONO16,sound.wav_queue[1],sound.packet_size*2,sound.samplerate)
		table.remove(sound.wav_queue,1)
--		wopus_core.echo_playback(sound.echo,sound.decode_wav)
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
	local c=alc.Get(sound.dev,alc.CAPTURE_SAMPLES) -- available samples
	if c>=sound.packet_size then
	
		alc.CaptureSamples(sound.dev,sound.encode_wav_echo,sound.packet_size)
		wopus_core.echo_cancel(sound.echo,sound.encode_wav_echo,sound.wav_played[1] or sound.decode_wav,sound.encode_wav)
		if sound.wav_played[1] then table.remove(sound.wav_played,1) end

--		alc.CaptureSamples(sound.dev,sound.encode_wav_echo,sound.packet_size)
--		wopus_core.echo_capture(sound.echo,sound.encode_wav_echo,sound.encode_wav)

		sound.encode_siz=wopus_core.encode(sound.encoder,sound.encode_wav,sound.encode_dat)
		assert(sound.encode_siz~=-1)
--		print(sound.packet_size , sound.encode_siz)
		sound.decode_dat=wpack.copy(sound.encode_dat,sound.encode_siz) -- trim to correct size

		sound.decode_siz=wopus_core.decode(sound.decoder,sound.decode_dat,sound.decode_wav,0)

		local wtab,wlen=wpack.load_array( {buffer=sound.decode_wav,sizeof=sound.packet_size*2,offset=0} , "s16")
--print(sound.packet_size,#wtab,wlen)

		sound.wav_queue[ #sound.wav_queue+1 ]=wpack.copy(sound.decode_wav,sound.packet_size*2)
		
--print("sound in",sound.encode_siz,sound.decode_siz,sound.decode_dat)

--[[

local pit={}
pit.cmd="test"
pit.data=wpack.tostring(sound.encode_dat,sound.encode_siz)
pit.count=123

local pd1=(wstr.serialize(pit,{compact=true}))
local pd2=cmsgpack.pack(pit)
local pz1=zlib.deflate()(pd1,"finish")
local pz2=zlib.deflate()(pd2,"finish")
print((sound.encode_siz),#pd1.." > "..#pz1,#pd2.." > "..#pz2)

--print(wstr.serialize( cmsgpack.unpack(pd2) ,{compact=true} ))

]]

	end
end



end


	return sound
end



