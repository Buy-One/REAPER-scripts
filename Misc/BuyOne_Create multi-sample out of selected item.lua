--[[
ReaScript name: BuyOne_Create multi-sample out of selected item.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script is desinged to create a multi-sample 
		out of a single sample by transposing it to different
		pitches according to the user preferences supplied
		to it via a dialogue. Which may in particular be useful
		for creating an RS5k instrument because RS5k doesn't
		do pitch shifting other than by way of resampling the
		audio which affects its speed.

		The multi-sample source can be an audio or a MIDI take.
		When a MIDI take is selected, the script expects at least 
		one instance of ReaSamplOmatic5000 (RS5k) on the item's track 
		able to be triggered by the note events in the MIDI take.
		The main idea of rendering a multi-sample from a MIDI take
		is to shape the source sample with RS5k envelope. If this
		is not necessary the sample can of course be dropped into
		REAPER as an audio item and used in this capacity.

		SAMPLE PREPARATION

		As a preparatory step add note name and octave to the
		source take name of selected item, the take must be active. 
		If you don't know what pitch your source sample is in, insert
		ReaTune on the item track or in the source take FX chain to
		look it up.  
		The take name may consist of only a note name or a note name 
		and a preceding text which can serve as a custom name for your 
		multi-sample. No text following the note name is allowed in 
		the take name. 

		If there're track and/or take FX which will be printed into 
		the multi-sample provided APPLY_FX setting is enabled in the 
		USER SETTINGS or you use a MIDI source take, you may want to 
		configure the FX tail at 
		Preferences -> Media -> Tail length when using Apply FX to items (for track FX)
		/ Take FX tail length... (for take FX)

		MIDI SOURCE 

		If the multi-sample is created from a MIDI take, set 
		RS5k 'Mode' to 'Sample (Ignores MIDI note)'. 
		'Obey notes off' option can be enabled if the original 
		sample must be cut short by the length of the MIDI note 
		which triggers it. If it must be played back in full, 
		leave it unchecked and have a sufficient MIDI item length 
		because length of the file created by the action  
		'Item: Apply track/take FX to items'  
		used in the script to render the sample will be equal 
		to the MIDI item length rather than MIDI note or note 
		sequence length, UNLESS the preference at  
		Preferences -> Media -> Tail length when using Apply FX to items 
		provides for a sufficient extra tail.  
		For the same reason in order to prevent addition of silent 
		tail to the rendered sample it's advised at the very least 
		to set the MIDI item length to the length of the triggering 
		MIDI note or note sequence as well as to keep the preferences at  
		Preferences -> Media -> Tail length when using Apply FX to items (for track FX) 
		/ Take FX tail length (for take FX) at 0 if you're rendering 
		dry sample, i.e. without any track FX and take FX with tails.  
		Having said all of the above, the script on its part 
		additionally attempts to truncate any leading and trailing 
		silence tails in the rendered sample.

		PITCH SHIFT ALGO

		The script uses the pitch shift algo enabled in the source 
		take. Pitch shift algos SoundTouch and Rubber Band Library 
		allow for very significant negative transposition. Elastique 
		is limited and produces click at the start of negatively 
		transposed sample instances. Simple Window (fast) is low 
		quality.  
		If you prefer SoundTouch or Rubber Band Library algos you 
		may want to enable PROMPT_FOR_PITCHSHIFT_ALGO setting in the 
		USER SETTINGS below to always be prompted whenever these're 
		not enabled in the source take pitch shift algo settings so 
		that the script enables them automatically. They obviously
		will be enabled with default settings whereas manual 
		activation allows changing their configuration.

		RANGE PROPERTIES DIALOGUE

		The multi-sample pitch range can be defined in terms 
		of notes or in terms of octaves. The array of pitches 
		which the multi-sample will be comprised of is further 
		modified by the step value. If the step value is not 
		specified it defaults to 1, meaning all pitches which 
		fall within the specified range will be included in the 
		multi-sample.  
		If the range is defined by notes and it's not a multiple 
		of the step value, which is only possible when the step 
		is other than 1, the root and/or end notes will not 
		necessarily fall within the range. The actual source 
		take pitch may end up not being included either.  
		If the range is defined by octaves, it necessarily starts 
		and ends with the root note in the respective lowest 
		and highest octaves, unless 'Step reset' mode is 
		activated (see below).

		In the note range only sharps # are supported as 
		accidentals. 

		The step value is added consecutively across all octaves 
		within the specified range and as a result multi-sample 
		notes are very likely to be different in different octaves.

		Outside of the 'Step reset' mode, in order to create 2 
		unique pitches per octave the range start note must be C 
		and step value be 6, so that the rendered notes are C and 
		F# in each octave.

		STEP RESET MODE

		Unlike the regular mode where the step value is added 
		consecutively across all octaves, in this mode it's reset 
		for each octave. This ensures that for each octave within 
		the specified range the same notes are being created.  
		In this mode only the range defined by octaves is supported 
		and it always starts with the C note in the lowest octave 
		of the range rather than with the root note in that octave.
		The C note is included in each octave, other notes depend 
		on the step value.
		If the step value is greater than 11 each octave will only 
		contain the C note.
		The mode is activated by inclusion of the letter R 
		(the register is immaterial) in the 'Step' field of the 
		dialogue. The rules applicable to the numeric step value 
		remain the same.

		The Range properties dialogue is case agnostic so note names
		can be in any register.

		THE RESULT

		The multi-sample is rendered to the project media directory
		which is one of the following:  
		for unsaved projects it's - 
		A) '%USER%\Documents\REAPER Media' (on Windows), if no path is 
		configured in any of the preferences;  
		B) path configured in 
		Project settings -> Media ->  Path to save media files (...) 
		(only if absolute);  
		C) path configured in 
		Preferences -> General -> Paths -> Default recording path;
		for saved projects -  
		A) path configured in 
		Project settings -> Media -> Path to save media files (...), 
		relative to project directory or absolute;  
		B) project directory root if no path is configured in the 
		Project Settings

		Each render pass creates a new set of files.
		If there's text preceding the note name in 
		the take name the resulting multi-sample file name format is 
		[preceding text]_[multi] [number]_[note name].ext   
		otherwise the file name format is  
		Instrument_[number]_[multi]_[note name].ext  
		If at the time of multi-sample creation the destination folder 
		already contains previously rendered multi-sample files with 
		the same name, the number in the file names of the currently 
		rendered multi-sample is incremented, unless there's a smaller 
		available number.

		The consistency of multi-sample item and file names depends 
		solely on the note being correct in the source take name 
		(source file name doesn't matter), therefore make sure to verify 
		the correct pitch of the source take using ReaTune and label 
		it accordingly.

		To finetune the script behavior proceed to the USER SETTINGS
		below.

		!!!!WARNING!!!!

		If you're going to export RS5k multi-sample instrument having
		enabled the relevant script settings be aware that root note
		name in some RS5k instances may be incorrect. This is due to
		RS5k bug which as of build 7.73 is yet to be fixed. Bug reports
		https://forum.cockos.com/showthread.php?t=308333
		https://forum.cockos.com/showthread.php?t=309056
		This bug doesn't affect the actual transposition, so all pitches
		will be correct.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable a setting insert any alphanumeric character
-- between the quotation marks

-- Apply take and track FX when the source take is rendered;
-- only relevant for audio take as multi-sample source
-- provided there're active FX in the take or track FX chain;
-- the channel count of the source take will be preserved
-- unless MONO setting is enabled below;
-- the setting isn't relevant when there're no active
-- track/take FX affecting the take or when the take is MIDI
-- because to MIDI take FX are always applied when rendering
APPLY_FX = ""


-- Include source item fade-in and out
-- only relevant for audio take as multi-sample source;
-- the setting doesn't apply when the take is MIDI
FADE = ""


-- Render in mono;
-- only relevant when the source take is MIDI
-- or audio while APPLY_FX setting is enabled above;
-- applies to stereo/multi-channel audio takes,
-- mono takes are always rendered in mono;
-- if disabled, the source take channel count
-- will be preserved in the sample unless the take
-- is MIDI, because RS5k triggered by it is only
-- able to output a max of two channels,
-- so multi-channel samples will be rendered
-- in stereo
MONO = ""


-- Enable to have the samples transposed
-- both down and up and thereby sharing the range
-- with adjacent samples in order to cover
-- all pitches;
-- if disabled, the samples are only transposed
-- down to prevent reduction in their duration
-- as a result of the transposition, save for
-- the very last sample which is trasposed both
-- down and up to fill the remaining upper range,
-- if any;
-- the setting only applies if at least one
-- of the settings SFZ, RS5K_TRACK_TEMPLT
-- or RS5K_FX_CHAIN is enabled below and if
-- there're pitch gaps of at least 2 semitones
-- between adjacent samples, which depends on
-- the step value
SHARED_RANGE = ""


-- Create a folder for the rendered
-- multi-sample;
-- for audio source take it's created
-- in the directory of the source take media
-- file, while for MIDI source take it's
-- created in the project media directory;
-- this setting can be enabled directly
-- from the source take name by prefacing
-- it with forward slash, i.e.
-- / My New Instrument C4
-- presense of spaces preceding and following
-- the slash is immaterial
MULTI_SAMPLE_FOLDER = ""


-- Export a basic sfz patch
-- to the directory of the multi-sample
SFZ = ""


-- Export RS5k multi-sample setup
-- as track template to the directory
-- of the multi-sample
RS5K_TRACK_TEMPLT = ""


-- Export RS5k multi-sample setup
-- as FX chain to the directory
-- of the multi-sample
RS5K_FX_CHAIN = ""


-- Insert ReaTune on the multi-sample track
REATUNE = "1"


-- Enable to be presented with a prompt to set
-- the source take pitch shift mode
-- to SoundTouch or Rubber Band with default settings,
-- unless aleady set
PROMPT_FOR_PITCHSHIFT_ALGO = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end

local r = reaper



function ACT(comm_ID) -- both string and integer work
r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end


function space(num)
return (' '):rep(num)
end


function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function trim_trailing_decimal_zeros(num)
-- in Lua positive diviser (1 in this case) modulo of negative numbers is still greater than 0
return num%1 == 0 and math.floor(num) or num
end



function create_unique_time_based_ID() -- used in Create_FX_Chain_Preset() and Create_Track_Template()
	local function to_base36(n)
	-- n is integer
	local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	local s = ''
		repeat
		  local r = n%36 + 1
		  s = chars:sub(r,r)..s
		  n = math.floor(n/36)
		until n == 0
	return s
	end
return to_base36(os.time())
end



function Dir_Exists(path)
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
local sep = path:match('[\\/]') or '/' -- extract the separator, if path is disk root where the separator isn't listed, use forward slash, which should work on Windows as well
	if not sep then return end -- likely not a string representing a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed so the path is properly formatted for io.open()
local _, mess = io.open(path)
return #path:gsub('[%c%.]', '') > 0 and mess and mess:match('Permission denied') and path..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
end



local function GetObjChunk(obj) -- used in Valid_RS5k_Exist()
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, env = table.unpack(t)
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end




function Calculate_Take_RMS_Loudness(take, block_size, time_window, gate_dB) -- used in Source_Too_Quiet_Or_Loud(), and RS5k_Get_Note_Gain_At_Current_Velocity() which has been discarded

-- author ChatGPT with edits;
-- block_size and time_window are mutually exclusive
-- where block_size have priority if both args are valid
-- block_size: 256 - 1024 more precise but slower
-- 2048 - 8192 less precise but faster,
-- if invalid and time_window is invalid as well defaults to 1024,
-- time_window is value in sec, for meaningful results
-- must be fraction of a second, about 1/100 i.e. 10/1000
-- so that the window width is small enough;
-- gate_dB is value in dB below which amplitude is considered
-- silence and so ignored to avoid skewing the calculation
-- of overall loudness by inclusion of effective silence, e.g. -60,
-- the difference between rms and peak is on everage 15 dB;
-- the function doesn't account for reversed source and source section

	if not take or r.TakeIsMIDI(take) then return end

local accessor = r.CreateTakeAudioAccessor(take)

	if not accessor then return end

local src = r.GetMediaItemTake_Source(take) -- returns pointer for the source including reversed and source section, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
--src = r.GetMediaSourceParent(src) or src -- UNNECESSARY BECAUSE PREVENTS GETTING SECTION OF THE SOURCE AND CALCULATE CORRECT START/END VALUES
local retval, offs, src_len, rev = r.PCM_Source_GetSectionInfo(src) -- OR r.GetMediaSourceLength(src) to get length
-- accessor start/end match item start/end, trimmed or not, looped or not
-- so making sure that if a non-looped take is extended beyond its source
-- any extra space is ignored, only positive start offset
-- and trimmed right item edge are respected
local startoffs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local item = r.GetMediaItemTake_Item(take)
local looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1

-- start offset value is affected by playrate which is irrelevant
-- for its actual length when take isn't looped, so if it's not,
-- calculating its actual length by canceling out playrate (dividing by it)
local st_offset = not looped and startoffs < 0 and startoffs/playrate or 0
-- offsetting start time by startoffset, relevant when non-looped item left edge
-- is extended beyond the take source, otherwise start time remains equal to accessor start time;
-- accessor's own start time is always 0, i.e. take start
local start_time = r.GetAudioAccessorStartTime(accessor)+math.abs(st_offset) -- OR -st_offset

local end_time = r.GetAudioAccessorEndTime(accessor) -- equals item end time
-- if take is extended beyond the source, looped or not,
-- end time is source length at current playrate
-- offset by startoffset value just like the start time,
-- otherwise it's accessor end time;
-- looped take startoffs is always positive;
-- since in looped takes each loop iteration equals either the full source
-- or a portion thereof, the calculated end time will equal the length
-- of the remaining portion if startoffs is not 0, i.e. the 1st
-- loop iteration isn't complete, which provides access to the entire source
-- length, unless the item right edge is trimmed which is the accessor's end time
local end_offset = not looped and startoffs > 0 and startoffs/playrate or 0
end_time = math.min(end_time, src_len/playrate-end_offset)

local gate = gate_dB and tonumber(gate_dB) and 10^(gate_dB/20) or 1e-15
local samplerate = r.GetMediaSourceSampleRate(src)
local num_channels = r.GetMediaSourceNumChannels(src)
local block_size = block_size or not time_window and 1024
block_size = block_size or math.floor(time_window * samplerate + 0.5)
local block_spl_cnt = block_size * num_channels
local buffer = r.new_array(block_spl_cnt)

local t, sum_total, spls_total = start_time, 0, 0

	while t < end_time do

	local is_audio = r.GetAudioAccessorSamples(accessor, samplerate, num_channels, t, block_size, buffer) -- return value is only a control flag, at each loop cycle the buffer initialized above is filled with another sample batch starting at t

		if is_audio ~= 1 then t = nil break end

	local sum = 0

		-- scan block
		for i = 1, block_spl_cnt do
		local v = buffer[i]
		sum = sum + v * v -- more efficient than v^2
		end

	local block_rms = math.sqrt(sum/block_spl_cnt) -- OR (sum/block_spl_cnt)^0.5

		if block_rms > gate then
		sum_total = sum_total + sum
		spls_total = spls_total + block_spl_cnt
		end

	t = t + (block_size/samplerate)

	end

r.DestroyAudioAccessor(accessor)

	if spls_total > 0 then -- preventing division by 0 in the next line
	local rms = math.sqrt(sum_total/spls_total)
		if rms <= 1e-15 then return -- 1e-15 ~ -300 dB, no meaningful RMS
		else
		return 20*math.log(rms, 10)
		end
	end

end



function Get_Audio_Peak_In_Take(take) -- used in Source_Too_Quiet_Or_Loud()
-- in particular useful in finding whether the take source is normalized

	if not take or r.TakeIsMIDI(take) then return end

local accessor = r.CreateTakeAudioAccessor(take)

	if not accessor then return end

local src = r.GetMediaItemTake_Source(take) -- returns pointer for the source including reversed and source section, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
local retval, offs, len, rev = r.PCM_Source_GetSectionInfo(src) -- OR r.GetMediaSourceLength(src) to get length
-- accessor start/end match item start/end, trimmed or not, looped or not
-- so making sure that if a non-looped take is extended beyond its source
-- any extra space is ignored, only positive start offset
-- and trimmed right item edge are respected
local startoffs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local item = r.GetMediaItemTake_Item(take)
local looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1

-- start offset value is affected by playrate which is irrelevant
-- for its actual length when take isn't looped, so if it's not,
-- calculating its actual length by canceling out playrate (dividing by it)
local st_offset = not looped and startoffs < 0 and startoffs/playrate or 0
-- offsetting start time by startoffset, relevant when non-looped item left edge
-- is extended beyond the take source, otherwise start time remains equal to accessor start time;
-- accessor's own start time is always 0, i.e. take start
local start_time = r.GetAudioAccessorStartTime(accessor)+math.abs(st_offset) -- OR -st_offset

local end_time = r.GetAudioAccessorEndTime(accessor) -- equals item end time
-- if take is extended beyond the source, looped or not,
-- end time is source length at current playrate
-- offset by startoffset value just like the start time,
-- otherwise it's accessor end time;
-- looped take startoffs is always positive;
-- since in looped takes each loop iteration equals either the full source
-- or a portion thereof, the calculated end time will equal the length
-- of the remaining portion if startoffs is not 0, i.e. the 1st
-- loop iteration isn't complete, which provides access to the entire source
-- length, unless the item right edge is trimmed which is the accessor's end time
local end_offset = not looped and startoffs > 0 and startoffs/playrate or 0
end_time = math.min(end_time, len/playrate-end_offset)

local samplerate = r.GetMediaSourceSampleRate(src)
local num_channels = r.GetMediaSourceNumChannels(src)
local block_size = math.floor(samplerate/1000+0.5) -- samples per ms, matches the sample rate, rounding for r.new_array()
local block_spl_cnt = block_size * num_channels
local buffer = r.new_array(block_spl_cnt)

local t, peak, clipped_count, last_peak, is_clipped = start_time, 0, 0

	while t < end_time do

	local is_audio = r.GetAudioAccessorSamples(accessor, samplerate, num_channels, t, block_size, buffer) -- return value is only a control flag, at each loop cycle the buffer initialized above is filled with another sample batch starting at t

		if is_audio ~= 1 then break end

		-- scan block
		for i = 1, block_spl_cnt do
		local v = math.abs(buffer[i])
		peak = v > peak and v or peak
		-- count consecutive peak samples which are relatively equal
		-- in amplitude (not necessarily identical) to identify clipping and flat plateaus
			if not is_clipped and v >= 0.999
			and (not last_peak or math.abs(v-last_peak) < 1e-5)
			then
			clipped_count = not last_peak and 1 or clipped_count+1
			is_clipped = is_clipped or clipped_count >= 8 -- at least 8 consecutive samples are at peak, i.e. the waveform is likely clipped
			last_peak = v
			else -- reset
			last_peak = nil
			end
		end

	t = t + (block_size/samplerate)

	end

r.DestroyAudioAccessor(accessor)

return peak > 0 and math.log(peak, 10)*20, is_clipped

end



function Source_Too_Quiet_Or_Loud(take)
-- only audio source take is examined here
	local function to_dB(val)
	return 20*math.log(val,10)
	end
local parm = 'D_VOL'
-- local vol_tr = r.GetMediaTrackInfo_Value(tr, parm) -- tr level is irrelevant because it's ignored by the actions 'Item: Apply track/take FX to items' and Glue
local vol_take = take and r.GetMediaItemTakeInfo_Value(take, parm) or 0
local vol_item = take and r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), parm) or 0

-- the actions 'Apply track/take FX as new take' and Glue used by the script print item/take volume as well
local rms_dB = Calculate_Take_RMS_Loudness(take, 256, time_window, -60) -- block_size 256, gate_dB -60 // returns nil for silent take
local peak, clipped
	if rms_dB then -- only search for peak if not silent
	peak, clipped = Get_Audio_Peak_In_Take(take)
	end
local vol_take_item = to_dB(vol_take)+to_dB(vol_item)
return not rms_dB and 0 or rms_dB+vol_take_item < -42 and 1 or peak+vol_take_item > 0 and 2, peak -- 0 silent, 1 quiet, 2 loud; peak is returned for further normalization if user opts for it after prompt

end



function Copy_FX_To_Multi_Sample_Track_And_Remove(src_tr, targ_tr)

	if src_tr and targ_tr then
		for i=0, r.TrackFX_GetCount(src_tr)-1 do
		r.TrackFX_CopyToTrack(src_tr, i, targ_tr, i, false) -- isMove false
		end
	elseif src_tr then
		for i=r.TrackFX_GetCount(src_tr)-1,0,-1  do
		r.TrackFX_Delete(src_tr, i)
		end
	end

end



function Normalize_Take(take, peak, vol_item, vol_take)
-- peak is take source peak amplitude in dB, stems from Source_Too_Quiet_Or_Loud()

local item = take and r.GetMediaItemTake_Item(take) or r.GetSelectedMediaItem(0,0)
local take = take or r.GetActiveTake(item)
local parm = 'D_VOL'

	if not (vol_item and vol_take) then -- normalize
	--[[
		if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.46 then
		ACT(40936) -- Item properties: Normalize items to +0dB peak (reset to unity if already normalized) // DESPITE THE NAME, ONLY CHANGES TAKE VOLUME VALUE // NORMALIZES TAKE EVEN IF IT'S GAIN IS ALREADY SET TO OR EXCEEDS 0 dB WITH ITEM VOLUME CONTROL
		else
	--]]
		local function to_dB(val)
		return math.log(val,10)*20
		end
	-- store original levels
	local vol_item = r.GetMediaItemInfo_Value(item, parm)
	local vol_take = r.GetMediaItemTakeInfo_Value(take, parm)
	local peak = peak or Get_Audio_Peak_In_Take(take)
	-- reset to unity
	r.SetMediaItemInfo_Value(item, parm, 1)
	r.SetMediaItemTakeInfo_Value(take, parm, 1)
	local norm_level = peak*-1 - 1 -- flip peak amplitude sign to make it positive so the gain is increased
	-- normalizing to -1 dB for more time stretch headroom
	-- setting take because after track/take FX are applied with action or glue
	-- this setting is auto-reset whereas item volume is kept
	-- and will affect source level in gluing within the transposition loop
	r.SetMediaItemTakeInfo_Value(take, parm, 10^(norm_level/20))
	return vol_item, vol_take -- to restore if needed
	else -- restore
	r.SetMediaItemTakeInfo_Value(take, parm, vol_take)
	r.SetMediaItemInfo_Value(item, parm, vol_item)
	r.UpdateItemInProject(item)
	end

end



function Valid_RS5k_Exist(tr)

local parm_t = {[3]='Note range start',[16]='Pitchbend range',[23]='Loop start offset'}
-- identifiers: '_Note_range_start','_Pitchbend_range','_Loop_start_offset'
local _6_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37
local ConfigParm, Enabled, Offline = r.TrackFX_GetNamedConfigParm, r.TrackFX_GetEnabled, r.TrackFX_GetOffline
local idx_t = {indices={}} -- indices of all valid rs5k instances will be collected to ascertain that in at least one of them note range matches note range of the midi item, so the sample can be triggered, as well as to evaluate the longest playing sample and alert the user about potential silent tail // indices nested table will be used inside Validate_MIDI_Item_Length() to search for FX other than RS5k more effeiciently

	for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
	local tab_len = #idx_t
		if Enabled(tr, fx_idx) and not Offline(tr, fx_idx) then
			if _6_37 then
			local retval, orig_fx_name = ConfigParm(tr, fx_idx, 'original_name') -- or 'fx_name' // returned with fx type prefix
				if orig_fx_name:lower():match('reasamplomatic5000') then
				local ret, file = ConfigParm(tr, fx_idx, 'FILE0') -- thanks to MPL for revealing the hidden file argument in his script mpl_Export selected Media Explorer items to RS5k instances on selected track (use original source).lua, first mentioned by Justin at https://forum.cockos.com/showthread.php?p=1817782#post1817782
					if ret then
					idx_t[#idx_t+1] = fx_idx
					idx_t.indices[fx_idx] = ''
					end
				end
			end
			if #idx_t == tab_len then -- wasn't found by original name above
			-- if build is older than 6.37 or plugin was renamed in the FX browser
			-- compare parameter names or identifiers as a way of plugin identification
			local cnt = 0
				for idx, name in pairs(parm_t) do
				cnt = cnt+1
				local ret, parm_name = r.TrackFX_GetParamName(tr, fx_idx, idx, '')
				local ident
					if _6_37 then -- get identifiers
					ret, ident = r.TrackFX_GetParamIdent(tr, fx_idx, idx)
					end
					if parm_name == name or ident and ident:match(name:gsub('%s','_')) then -- in case of the evaluated parameters the alphabetic part of their identifiers only differ from their names by underscores instead of spaces, leading underscore isn't needed for matching
					cnt = cnt-1
					end
				end
				if cnt == 0 then -- all additions ended up being deducted, i.e. all 3 parameters have matches
				local ret, file = ConfigParm(tr, fx_idx, 'FILE0') -- thanks to MPL for revealing the hidden file argument in his script mpl_Export selected Media Explorer items to RS5k instances on selected track (use original source).lua, first mentioned by Justin at https://forum.cockos.com/showthread.php?p=1817782#post1817782
					if ret then
					idx_t[#idx_t+1] = fx_idx
					idx_t.indices[fx_idx] = ''
					end
				end
			end
		end
	end

	if #idx_t == 0 then
	-- RS5k wasn't found among unbypassed, online instances with samples
	-- or its identification failed, by parameter names it failed
	-- likely due to parameter aliasing in builds older than 6.37,
	-- use chunk to find instance
	local _, chunk = GetObjChunk(tr)
		if chunk:match('reasamplomatic%.dll') then -- could however belong to input FX, container or take FX which are ignored in the following evaluation
			for GUID in chunk:gmatch('reasamplomatic%.dll.-FXID (.-)\n') do
				if GUID then
				idx_t[GUID] = ''
				end
			end
			if next(idx_t) then
				for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
					if Enabled(tr, fx_idx) and not Offline(tr, fx_idx)
					and idx_t[r.TrackFX_GetFXGUID(tr, fx_idx)] then
					idx_t[#idx_t+1] = fx_idx
					idx_t.indices[fx_idx] = ''
					end
				end
			end
		end
	end

return #idx_t > 0 and idx_t -- will be used in RS5k_vs_MIDI_Item_Note_Ranges() and Validate_MIDI_Item_Length()

end



function Get_RS5k_Note_Range(tr, idx) -- used in RS5k_vs_MIDI_Item_Note_Ranges() and Validate_MIDI_Item_Length()
local start_note = r.TrackFX_GetParam(tr, idx, 3)
local end_note = r.TrackFX_GetParam(tr, idx, 4)
local unit = 1/127
return math.floor(start_note/unit+0.5), math.floor(end_note/unit+0.5)
--[[
-- OR
local ret, start_note = r.TrackFX_GetFormattedParamValue(tr, 0, 3)
local ret, end_note = r.TrackFX_GetFormattedParamValue(tr, 0, 4)
return start_note+0, start_note+0
--]]
end


function Notes_Within_Range_Exist(take, st_note, end_note, t) -- used in RS5k_vs_MIDI_Item_Note_Ranges()
-- st_note, end_note are RS5k note range settings
local i, t = 0, t or {}
local item = r.GetMediaItemTake_Item(take)
local item_st = r.GetMediaItemInfo_Value(item,'D_POSITION')
local item_end = item_st+r.GetMediaItemInfo_Value(item,'D_LENGTH') -- NOT USED

	repeat
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled
		if retval and not mute and pitch >= st_note and pitch <= end_note then
		-- take playrate is automatically accounted for in note properties
		local st_time = r.MIDI_GetProjTimeFromPPQPos(take, startpos)
		local end_time = r.MIDI_GetProjTimeFromPPQPos(take, endpos)
		-- here only presence of visible non-muted notes is evaluated
		-- presence of notes with cut-off start and gap between item start and 1st note start
		-- is evaluated in Notes_Start_Gap_And_Cutoff()
			if end_time > item_st
			-- within view // only considering end time to be able to detect notes with start cut off in Notes_Start_Gap_And_Cutoff() // note end cut-off by trimmed item end is allowed
			then
			t[#t+1] = {st=st_time, fin=end_time, pitch=pitch, idx=retval, vel=vel}
			end
		end
	i=i+1
	until not retval

return t

end


function RS5k_vs_MIDI_Item_Note_Ranges(tr, rs5k_idx_t, take)
-- rs5k_idx_t stems from Valid_RS5k_Exist()
local notes_t = {take = take}
	for k, rs5k_idx in ipairs(rs5k_idx_t) do
	local st_note, end_note = Get_RS5k_Note_Range(tr, rs5k_idx)
	notes_t = Notes_Within_Range_Exist(take, st_note, end_note, notes_t)
	end
return #notes_t > 0 and notes_t
end


function Notes_Start_Gap_And_Cutoff(t)
-- t stems from RS5k_vs_MIDI_Item_Note_Ranges()
local take = t.take
local item_st = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take),'D_POSITION')
local chase = r.GetToggleCommandStateEx(0, 41992) == 1 -- Chase MIDI note-on/CC/PC/pitch in project playback, same command ID in Main and MIDI Editor sections of the Action list, so section 32060 could be used as well
local no_gap, cutoff_note_start
	for k, props in ipairs(t) do
	local st_time = props.st
		-- midi notes time value is notoriously fractional probably due to conversion
		-- from ppq, so equality comparison is unreliable due to very minute differences,
		-- difference by less than 1 ms is acceptable;
		-- only evaluate first note or notes if several are aligned with the first
		-- in case there's sequence in which case following notes are irrelevant for evaluation
		if st_time == item_st or st_time-item_st < 0.001 then no_gap = 1 end
		-- without chase enabled even 0.5 ms of note start cut-off will prevent note-on
		if not chase and item_st > st_time and item_st-st_time > 0.0005 then cutoff_note_start = 1 end
	end
return no_gap, cutoff_note_start
end



function Calculate_RS5k_Sample_Length(tr, fx_idx) -- used in Validate_MIDI_Item_Length()
local ret, file = r.TrackFX_GetNamedConfigParm(tr, 0, 'FILE0')
local src = r.PCM_Source_CreateFromFile(file)
local sec, QN = r.GetMediaSourceLength(src)
-- OR
-- local retval, offs, sec, rev = r.PCM_Source_GetSectionInfo(src)
local spl_st_offset = r.TrackFX_GetParam(tr, 0, 13)
local spl_end_offset = r.TrackFX_GetParam(tr, 0, 14)
return sec*spl_end_offset - sec*spl_st_offset
--[[
-- OR, source length isn't needed
local ret, st = r.TrackFX_GetFormattedParamValue(tr, 0, 13)
local ret, fin = r.TrackFX_GetFormattedParamValue(tr, 0, 14)
return fin+0 - st+0
--]]
end



function Calculate_RS5k_Sample_Playing_Time_At_Pitch(tr, fx_idx, spl_length, pitch) -- used in Validate_MIDI_Item_Length()
-- spl_length stems from Calculate_RS5k_Sample_Length(), length in sec
-- if invalid, the function relies on Calculate_RS5k_Sample_Length()
-- to get it;
-- fx_idx is RS5k index in track FX chain;
-- pitch is MIDI note pitch in the range of 1-127, supposed to
-- fall within range defined by RS5k 'Note start/end:' settings;
-- the function only makes sense when 'Obey note-offs' option is disabled in RS5k

local spl_length = spl_length or Calculate_RS5k_Sample_Length and Calculate_RS5k_Sample_Length(tr, fx_idx)

	if not spl_length then return end

local Param = {tr=tr,idx=fx_idx,
Get = function(self, parm_idx) return r.TrackFX_GetParam(self.tr, self.idx, parm_idx) end}

local unit = 1/127
local note_st = math.floor(Param:Get(3)/unit+0.5) -- 'Note start:'
local note_end = math.floor(Param:Get(4)/unit+0.5) -- 'Note end:'
--[[ -- OR, which obviates conversion from notmalized values to conventional notation
local Param = r.TrackFX_GetFormattedParamValue
local note_st = Param(tr, fx_idx, 3, '')
local note_end = Param(tr, fx_idx, 4, '')
--]]

	if pitch < note_st or pitch > note_end then return end

local ret, mode = r.TrackFX_GetNamedConfigParm(tr, fx_idx, 'MODE')

	if not ret then return end -- in REAPER builds where MODE the parameter isn't supported

-- these calculations apply to all 3 sample playback modes
local pitch_offset = Param:Get(15) -- range -80 + 80 st;
local unit = 1/160 -- 160 st is full range between -80 and +80 st, 1 is normalized full range of the parameters
local pitch_offset = (pitch_offset-0.5)/unit -- 0.5 equals pitch 0, values above it are within the range of 0-80, below -80-0 // in modes other than 'Sample (ignores MIDI note)' it's an offset on top of the offset produced by Pitch@start value towards the value of 'Note start', if negative it offsets Pitch@start value
--[[ OR, which obviates conversion from notmalized values to conventional notation
local pitch_offset = r.TrackFX_GetFormattedParamValue(tr, fx_idx, 15, '')
--]]

-- 'Sample (ignores MIDI note)'
local semitone_shift = pitch_offset -- if negative the sample plays slower, if positive - faster

	if mode ~= '1' then -- not 'Sample (ignores MIDI note)'
	local pitch_st = Param:Get(5) -- 'Pitch@start:' sett, range -80 + 80 st; relevant for modes 'Freely configurable shifted' and 'Note (semintone shifted)' // THE NOTE NAME INDICATES THE CALCULATED ROOT NOTE AFTER SHIFT TOWARDS THE NOTE AT 'Note start:' SETTING, NOT THE START NOTE AFTER SHIFT, i.e. if 'Note start' is C4 (60), Pitch@start 1 means that the current pitch at C4 is the result of the root note transposition up by 1 st, which makes the root note B3 (59), because 59+1=60; negative Pitch@start value shifts the root note up, i.e. with 'Note start' being C4 Pitch@start value -1 makes the root note C#4 because C#4 (61) - 1 = C4 (60)
	local pitch_st = math.floor((pitch_st-0.5)/unit+0.5) -- same calculation logic as pitch_offset, values above 0.5 it are within the range of 0-80, below -80-0
	local pitch_end = Param:Get(6) -- 'Pitch@end:' sett, range -80 + 80 st; relevant for mode 'Freely configurable shifted' // SAME LOGIC APPLIES TO THE END NOTE
	local pitch_end = math.floor((pitch_end-0.5)/unit+0.5) -- same calculation logic as pitch_offset, values above 0.5 it are within the range of 0-80, below -80-0
	--[[ -- OR, which obviates conversion from notmalized values to conventional notation
	local Param = r.TrackFX_GetFormattedParamValue
	local ret, pitch_st = Param(tr, fx_idx, 5, '')
	local ret, pitch_end = Param(tr, fx_idx, 6, '')
	local ret, pitch_offset = Param(tr, fx_idx, 15, '')
	--]]
		if mode == '2' then -- 'Note (semintone shifted)'
		local root_note = note_st - pitch_st
		semitone_shift = pitch - root_note + pitch_offset -- if negative the sample plays slower, if positive - faster
		else -- 'Freely configurable shifted'
		-- in this mode if both Pitch@start and Pitch@end settings are 0 the sample isn't transposed along the entire note range and plays at its original pitch which is equal to 'Sample (ignores MIDI note)' mode
		-- equal values transpose the sample by the same amount along the entire note range, i.e. it plays at constant but transposed pitch along the entire note range
		-- different values transpose the sample along the entire note range between 'Note start' and 'Note end' by as many semitones as the their sum, which can be between 1 and 160 semitones in either direction
		-- with Pitch@start positive or 0 and Pitch@end negative transposition can even be reversed so that pitch rises along note range in the opposite direction from heigher indexed notes to lower indexed
		local range = note_end - note_st
		local ratio = (pitch_st - pitch_end)/range -- calculate pitch shift ratio per semitone within the given range
		semitone_shift = pitch_st + (note_st - pitch) * ratio + pitch_offset -- pitch_st and pitch_offset are added in semitones on top of the pitch shift at the calculated ratio from note_st to pitch
		end

	end

local pitch_shift = semitone_shift/12 -- amount of pitch shift in octaves; pitch shift by 1 octave doubles or halves the speed/duration depending on direction

-- when pitch shift is negative, duration increases otherwise decreases by a factor of 2 per octave
-- negative exponent (sample pitched down) increases the product, i.e. longer playing time,
-- positive - dicreases, i.e. shorter playing time
local spl_duration = spl_length * 1/2^pitch_shift -- OR 0.5^pitch_shift OR 1/(2^pitch_shift)
-- OR
-- local spl_duration = spl_length / 2^pitch_shift

return spl_duration

end



function Plugin_Is_Instrument(obj, fx_idx, temp_tr, delete_temp_tr) -- used in FX_Exist() and in FX_Enabled()
-- FOR TRACK MAIN FX CHAIN TrackFX_GetInstrument() CAN BE USED INSTEAD,
-- BUT IT CAN'T DETERMINE THE TYPE OF JSFX PLUGINS EITHER
-- AND THERE'S NO COUNTERPART FUNCTION FOR TAKE FX CHAIN;
-- whether FX or instrument
-- if there're multiple plugins to evaluate
-- and there's likelihood of using a temporary track
-- for the sake of the evaluation (see below)
-- it's more efficient to create it once and then
-- re-use until all are done
-- so temp_tr arg is temporary track pointer
-- either created outside of this function
-- or inside it and returned by it for re-use;
-- delete_temp_tr is boolean to instruct the function
-- to delete it once all plugins have been evaluated,
-- unless it's supposed to be deleted outside of this function

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local FXName, ConfigParm, Copy = table.unpack(tr and {r.TrackFX_GetFXName, r.TrackFX_GetNamedConfigParm, r.TrackFX_CopyToTrack}
or take and {r.TakeFX_GetFXName, r.TakeFX_GetNamedConfigParm, r.TakeFX_CopyToTrack})

-- retrieve from the instance name in FX chain
-- unless renamed
local ret, name = FXName(obj, fx_idx)
local prefix = name:match('^([23ACDLPSTUVXi]+): ')
local JSFX = name:match('^JS:') and (name:lower():match('delay') or name:lower():match('reverb'))
or not name:match('^JS:')

	if prefix then return prefix:match('.+i') or not JSFX end -- non-delay/reverb JSFX are equated to instruments because they're unlikely to produce tail

-- retrieve from plugin name in the FX browser, supported since build 6.37
-- unless renamed there
local ret, name = ConfigParm(obj, fx_idx, 'original_name')
prefix = name:match('^([23ACDLPSTUVXi]+): ')
local JSFX = name:match('^JS:') and (name:lower():match('delay') or name:lower():match('reverb'))
or not name:match('^JS:')

	if prefix then return prefix:match('.+i') or not JSFX end

-- copy to a temporary track and retrieve from chunk
r.PreventUIRefresh(1)
local temp_tr = temp_tr
	if not temp_tr then
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
	temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange
	end
r.TrackFX_Delete(temp_tr, 0) -- delete previously evaluated plugin if any
Copy(obj, fx_idx, temp_tr, 0, false) -- isMove false
local ret, chunk = r.GetTrackStateChunk(temp_tr, '', false) -- isundo false
prefix = chunk:match('.-"([23ACDLPSTUVX]+i:) ') -- within a chunk fx type prefix with plugin name displayed in the FX browser are enclosed within quotes
local JSFX = chunk:match('.-<(JS.-)"')
JSFX = JSFX and (JSFX:lower():match('delay') or JSFX:lower():match('reverb')) or not JSFX
	if delete_temp_tr and temp_tr then r.DeleteTrack(temp_tr) end
r.PreventUIRefresh(-1)

return prefix and prefix:match('.+i') or not JSFX, temp_tr

end



function FX_Exist(obj) -- used in Validate_MIDI_Item_Length() and in the main routine
-- obj is either track with RS5k or a MIDI take;
-- other FX meaning other than RS5k but not VSTi
-- although VSTi's with long amplitude envelope releases
-- may also produce tail beyond note event length
-- which makes warning about silent tail dubious

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local NumParams, FXCount, Enabled, Offline, GetParam =
table.unpack(tr and {r.TrackFX_GetNumParams, r.TrackFX_GetCount, r.TrackFX_GetEnabled, r.TrackFX_GetOffline, r.TrackFX_GetParam}
or take and {r.TakeFX_GetNumParams, r.TakeFX_GetCount, r.TakeFX_GetEnabled, r.TakeFX_GetOffline, r.TakeFX_GetParam})
local temp_tr

	for i=0, FXCount(obj)-1 do
		if Enabled(obj, i) and not Offline(obj, i) -- not bypassed, not offline
		and GetParam(obj, i, NumParams(obj, i)-2) > 0 -- wet parameter isn't 0 // indices of REAPER plugin wrapper built-in parameters bypass, wet and delta can always be calculated relative to the total parameter count because these are always the last 3 parameters in the list
		then
		local instr
		instr, temp_tr = Plugin_Is_Instrument(obj, i, temp_tr) -- temp_tr, if created, will be re-used in subsequent cycles
			if not instr then
			local del = temp_tr and r.DeleteTrack(temp_tr)
			return 1
			end
		end
	end

end




function Validate_MIDI_Item_Length(tr, rs5k_t, notes_t, want_note_offs)
-- since action 'Item: Apply track/take FX to items' used in the script
-- renders the sample by the MIDI item length rather than MIDI note
-- or note sequence length
-- the function is meant to ensure that samples which are supposed to ring out
-- are rendered in full and those which aren't supposed to ring out
-- aren't cut short way ahead of the item end and that in either case
-- no silent tails are added,
-- taking into account 'Preferences -> Media -> Tail length when using Apply FX to items'
-- which creates tails in files rendered with the above action
-- beyond MIDI item length;
-- the sample itself may already contain non-trimmed silence
-- but the function doesn't account for that and considers it
-- having meaningful data along the entire length;
-- rs5k_t stems from Valid_RS5k_Exist()
-- note_t stems from RS5k_vs_MIDI_Item_Note_Ranges()
-- want_note_offs is boolean to evaluate duration of sample
-- in RS5k instances with Obey note-offs enabled to prevent
-- silent tails as a result of gap between notes and item end,
-- if false/nil duration of sample in RS5k instances
-- with Obey note-offs DISabled is evaluated instead;
-- in the main routine the function is run twice, once
-- with want_note_offs being false and once again with its being true


-- First ensure that there're no other FX in the source take and its parent track FX chains,
-- because if there're, warning about silent tail may be pointless,
-- the tail may be utilized by time based FX such as delay and reverb,
-- so any non-RS5k and non-VSTi instance is considered valid even if it doesn't benefit
-- from the tail, because evaluating the behavior of each and every FX
-- is either impossible or an unnecessary overhead,
-- that said, VSTi's with long amplitude envelope releases
-- may also produce tail beyond note event length
-- which makes warning about silent tail dubious,
-- in any case the silence will still be truncated with Truncate_Leading_And_Trailing_Silence()

	if FX_Exist(tr)
	or FX_Exist(notes_t.take)
	then return end

local Param = r.TrackFX_GetParam
local item = r.GetMediaItemTake_Item(notes_t.take)
local item_st = r.GetMediaItemInfo_Value(item,'D_POSITION')
local item_len = r.GetMediaItemInfo_Value(item,'D_LENGTH')
local ret, applyfxtail = r.get_config_var_string('applyfxtail') -- added on top of item length and allows sample to ring out
applyfxtail = applyfxtail/1000 -- convert to seconds

	for k, rs5k_idx in ipairs(rs5k_t) do
	local obey_note_off = Param(tr, rs5k_idx, 11) == 1
	local loop = Param(tr, rs5k_idx, 12) == 1
		if want_note_offs and obey_note_off or not want_note_offs and not obey_note_off and not loop then -- sample will ring out in full, but only if not loop because without note-offs looped sample plays infinitely
		local spl_length = Calculate_RS5k_Sample_Length(tr, rs5k_idx)
		local st_note, end_note = Get_RS5k_Note_Range(tr, rs5k_idx)
		local minim = math.huge*-1
		local farthest_pos, lowest_pitch_pos, lowest_pitch, farthest_pitch = minim, minim, 128 -- when want_note_offs is true only farthest_pos and farthest_pitch vars are relevant; deliberately out of range start values ensure that conditions below will be met at least once and all vars will end up being valid // using negative math.huge to accommodate note events which start ahead of item start and were allowed by the user to remain
		local spl_st -- will be added to sample length for notes triggered with Obey note-offs enabled
			for k, props in ipairs(notes_t) do
			local st_time, end_time, pitch = props.st-item_st, props.fin-item_st, props.pitch -- subtracting item start time because we're interested in item based time
				if pitch >= st_note and pitch <= end_note then -- note falls within the range of RS5k at current index
					if not want_note_offs then
					-- get farthest and lowest notes which trigger the sample within the item
					-- because the farthest is the closest to item end while the lowest
					-- has the longest playing time, to determine the final longest sample playing time;
					-- getting both because in theory the sample longest playing time
					-- isn't necessarily effected at pitch triggered by the farthest note
					-- if there're much lower notes which produce lower pitches and thus longer playing times
					-- fartest position and lowest position are searched for
					-- in note start times because when Obey note-offs is disabled
					-- the sample isn't cut off at the end of note event so note end is irrelevant
						if st_time > farthest_pos then
						farthest_pos = st_time
						farthest_pitch = pitch
						end
						if pitch < lowest_pitch then
						lowest_pitch = pitch
						lowest_pitch_pos = st_time
						end
					elseif want_note_offs and end_time > farthest_pos then
					-- farthest positon is searched for in note end times
					-- because when Obey note-offs is enabled sample is cut off
					-- at the end of note event and note length is equal to sample
					-- playing time
					farthest_pos = end_time
					farthest_pitch = pitch
					spl_st = st_time
					end
				end
			end

		local rendered_len_farthest, rendered_len_lowest
		farthest_pos = farthest_pos > 0 and farthest_pos or 0 -- if ends up being negative because note event starts ahead of item start (i.e. a cut off note) and it was allowed by the user to remain, clamp to 0 because rendering still starts at item start and no earlier
		local Duration = Calculate_RS5k_Sample_Playing_Time_At_Pitch -- for brevity

			-- calculate sample longest playing time
			if farthest_pitch and not want_note_offs then
			rendered_len_farthest = farthest_pos + Duration(tr, rs5k_idx, spl_length, farthest_pitch)
			-- this is only calculated for sample instances playing with Obey note-offs disabled
			rendered_len_lowest = farthest_pitch ~= lowest_pitch and lowest_pitch_pos + Duration(tr, rs5k_idx, spl_length, lowest_pitch) or rendered_len_farthest
			elseif farthest_pitch then -- may be nil if notes triggering sample in RS5k instance at current index weren't found
			farthest_pos = math.min(spl_st+spl_length, farthest_pos) -- for spl_length arg in below function select the shortest duration out of the sample and the note event it's triggered by because for samples playing with Obey note-offs enabled, farthest_pos var is note end which is either equal to or greater than the entire rendered sample length, the excessive note event length beyond sample duration will be included in the silent tail length
			rendered_len_farthest = Duration(tr, rs5k_idx, farthest_pos, farthest_pitch)
			rendered_len_lowest = 0 -- for calculating duration of sample triggered with Obey note-offs enabled this value is irrelevant, but making it valid and expressly smaller to simplify evaluations below
			end

			-- compare calculated sample longest playing time against expected render time
			if rendered_len_farthest then -- may be nil if REAPER build is old and doesn't support TrackFX_GetNamedConfigParm MODE attribute or if notes triggering RS5k instance at current index weren't found
			local rendered_len = math.max(rendered_len_farthest, rendered_len_lowest) -- select the longest of the two in case differ
			local remaining_space = item_len - rendered_len + applyfxtail -- space from the calculated farthest note event position until the end of expected render time; suntracting from item length because we're interested in item based time
			local mess, tail
				if not want_note_offs and remaining_space < 0 then -- sample won't be rendered in full // relevant for samples with Obey note-offs disabled
				mess = space(10)..'The item isn\'t long enough\n\n  for the sample to be rendered in full.\n\n'
				..space(8)..'At least '..math.ceil(rendered_len)..' sec are required.\n\n'..space(12)..'Wish to render anyway?'
				elseif remaining_space > 0.01 then -- silent tail longer than 10 ms will be added // relevant for samples with Obey note-offs both disabled and enabled
				applyfxtail = applyfxtail+0 == 0 and ''
				or ' and "Tail length when using Apply FX"\n\n'..space(20)..'preference at Preferences -> Media\n\n\t'
				tail = trim_trailing_decimal_zeros(math.floor(remaining_space*10^3+0.5)/10^3) -- rounding down fractional number to 3 decimal places, because 1 ms i.e. 1/1000th of a sec is the smallest time unit on REAPER time line
				mess = space(5)..'Due to item length'..applyfxtail..' a silent tail '..tail
				..' sec long will be added,\n\n\t'..space(10)..'though the script will attempt\n\n\t'
				..space(6)..'to truncate it as much as possible.\n\n\t\t   Wish to continue?'
				end
				if mess then return mess, tail end
			end
		end
	end

end



function Get_Take_Source_File(take) -- used in Truncate_Leading_And_Trailing_Silence() and in the main routine
	if take and not r.TakeIsMIDI(take) then
	local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed source and source sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
	src = r.GetMediaSourceParent(src) or src
	return r.GetMediaSourceFileName(src, ''), src -- src return value is used in APPLY_FX condition block
	end
end



function Find_Level_Relative_To_Thresh_In_Take(take, threshold, block_size, time_window, want_above, want_rms) -- used in Truncate_Leading_And_Trailing_Silence()
-- author ChatGPT;
-- returns project time where the level below threshold
-- was first detected within take;
-- threshold is val in dB, if invalid defaults to -60;
-- block_size and time_window are mutually exclusive
-- where block_size have priority if both args are valid
-- block_size: 256 - 1024 more precise but slower
-- 2048 - 8192 less precise but faster,
-- if invalid and time_window is invalid as well defaults to 1024,
-- time_window is value in sec, for meaningful results
-- must be fraction of a second, about 1/100 i.e. 10/1000
-- so that the window width is small enough;
-- want_rms is boolean to detect level in terms of rms
-- rather than peak;
-- want_above is boolean to detect average amplitude above threshold,
-- not sure how useful this is,
-- otherwise absolute amplitude below threshold;
-- the function doesn't account for reversed source and source section;
-- block_size and window may be made conditional on the
-- source length, the shorter the source the smaller/narrower
-- they must be for the sake of accuracy

	if not take or r.TakeIsMIDI(take) then return end

local accessor = r.CreateTakeAudioAccessor(take)

	if not accessor then return end

local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed source and source sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
src = r.GetMediaSourceParent(src) or src
local retval, offs, len, rev = r.PCM_Source_GetSectionInfo(src) -- OR r.GetMediaSourceLength(src) to get length
-- accessor start/end match item start/end, trimmed or not, looped or not
-- so making sure that if a non-looped take is extended beyond its source
-- any extra space is ignored, only positive start offset
-- and trimmed right item edge are respected
local startoffs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local item = r.GetMediaItemTake_Item(take)
local looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1

-- start offset value is affected by playrate which is irrelevant
-- for its actual length when take isn't looped, so if it's not,
-- calculating its actual length by canceling out playrate (dividing by it)
local st_offset = not looped and startoffs < 0 and startoffs/playrate or 0
-- offsetting start time by startoffset, relevant when non-looped item left edge
-- is extended beyond the take source, otherwise start time remains equal to accessor start time;
-- accessor's own start time is always 0, i.e. take start
local start_time = r.GetAudioAccessorStartTime(accessor)+math.abs(st_offset) -- OR -st_offset

local end_time = r.GetAudioAccessorEndTime(accessor) -- equals item end time
-- if take is extended beyond the source, looped or not,
-- end time is source length at current playrate
-- offset by startoffset value just like the start time,
-- otherwise it's accessor end time;
-- looped take startoffs is always positive;
-- since in looped takes each loop iteration equals either the full source
-- or a portion thereof, the calculated end time will equal the length
-- of the remaining portion if startoffs is not 0, i.e. the 1st
-- loop iteration isn't complete, which provides access to the entire source
-- length, unless the item right edge is trimmed which is the accessor's end time
local end_offset = not looped and startoffs > 0 and startoffs/playrate or 0
end_time = math.min(end_time, len/playrate-end_offset)

local samplerate = r.GetMediaSourceSampleRate(src)
local num_channels = r.GetMediaSourceNumChannels(src)
local block_size = block_size or not time_window and 1024
block_size = block_size or math.floor(time_window * samplerate + 0.5)
local threshold = threshold and 10^(threshold/20) or 0.001  -- ~ -60dB, 0.0001 ~ -80dB
local block_spl_cnt = block_size * num_channels
local buffer = r.new_array(block_spl_cnt)

local t = start_time

	while t < end_time do

	local is_audio = r.GetAudioAccessorSamples(accessor, samplerate, num_channels, t, block_size, buffer) -- return value is only a control flag, at each loop cycle the buffer initialized above is filled with another sample batch starting at t

		if is_audio ~= 1 then t = nil break end

	local max_amp, sum = 0, 0
	local above_t = want_above and {}

		-- scan block
		for i = 1, block_spl_cnt do
		local v = want_rms and buffer[i] or math.abs(buffer[i])
			if not want_rms then -- looking for peak below threshold
				if not want_above then
					if v > max_amp then max_amp = v end
				else -- collect sample values
				above_t[i] = v
				sum = sum + v
				end
			else -- looking for rms below threshold
			sum = sum + v * v -- more efficient than v^2
			end
		end

		if want_above then -- calc average peak value
		max_amp = #above_t > 0 and sum/#above_t or 0
		end

	local rms = want_rms and math.sqrt(sum / block_spl_cnt) -- OR (sum / block_spl_cnt)^0.5
	local val = not want_rms and max_amp or rms

		-- val < threshold will be true if all samples in the block are below the threshold
		-- val > threshold will be true if average amplitude of the block is above the threshold
		if not want_above and val < threshold or want_above and val > threshold then
		-- alternatively detection may use both peak and rms for more accuracy e.g.
		-- if rms < threshold and max_amp < threshold+10^(15/20) -- where 15 is average expected difference between rms and peak
		break
		end

	t = t + (block_size / samplerate)

	end

r.DestroyAudioAccessor(accessor)

--[[ CONTROL
	if t then
	local item = r.GetMediaItemTake_Item(take)
	-- when startoffs is positive, it's already accounted for in the t value
	-- when item is looped it's always positive
	local startoffs = startoffs < 0 and startoffs or 0
	local silence_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')-startoffs+t
	r.AddProjectMarker(0, false, silence_start, 0, '', -1)
--	local length = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
--	r.SetMediaItemInfo_Value(item, 'D_LENGTH', length-(length-t))
	end
--]]

-- return time within item, i.e. relative to item start
-- must be added to item start value to calculate project time
-- and subtracted from item length for trimming
-- as shown above under CONTROL
return t and t < end_time and t - (startoffs < 0 and startoffs or 0) -- only return if not outside of source right edge, i.e. no overshoot, accounting for negative start offset which is ignored in t calculation

end



function Truncate_Leading_And_Trailing_Silence(threshold, block_size, extended_st, time_wnd)

local threshold = threshold or -60
local block_size = block_size or 256

local item = r.GetSelectedMediaItem(0,0)
local take = r.GetActiveTake(item)

local trim_st = extended_st and Find_Level_Relative_To_Thresh_In_Take(take, threshold, block_size, time_window, 1, want_rms)-- want_above true

-- truncate in an orderly fashion so that for silent tail search
-- the take is scanned from the adjusted and thus final take start

	if trim_st then -- truncate leading silence
	local startoffs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
	r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', trim_st)
	end

local t = Find_Level_Relative_To_Thresh_In_Take(take, threshold, block_size, time_window, want_above, want_rms)

	if t then -- truncate trailing silence
	local length = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	r.SetMediaItemInfo_Value(item, 'D_LENGTH', length-(length-t)) -- silence start time t is relative to item start
	end

	if trim_st or t then	return 1	end

end




function Insert_Multi_Sample_Track(item)

ACT(40001) -- Track: Insert new track
local item_tr_idx = r.CSurf_TrackToID(r.GetMediaItem_Track(item), false) -- mcpView is false // reorder after track insert to get the track current index which would be different if obtained prior to insertion
r.ReorderSelectedTracks(item_tr_idx, 0) -- place added track right beneath the source track; index is 0-based; makePrevFolder is 0
local tr = r.GetSelectedTrack(0,0) -- the newly inserted track is exclusively selected
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', 'Multi-sample', true) -- setNewValue true

-- Delete all track envelopes which may have come with the copied item if the option 'Options: Move envelope points with media items' is ON
local move_env = r.GetToggleCommandStateEx(0, 40070) == 1 -- Options: Move envelope points with media items
	if move_env then
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr,i)
		local set = env and r.SetEnvelopeStateChunk(env, '>', false) -- delete by applying an invalid string, empty string doesn't work; isundo false
		end
	end
return tr
end



function FX_Enabled(item)

local take = r.GetActiveTake(item)
local tr = r.GetMediaItemTrack(item)

	local function find_active(tr, take)
	local Count, Unbypassed, Offline = table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetEnabled, r.TrackFX_GetOffline}
	or take and {r.TakeFX_GetCount, r.TakeFX_GetEnabled, r.TakeFX_GetOffline})
	local obj, instr, temp_tr = tr or take, true
		for i=0, Count(obj)-1 do
			if Unbypassed(obj, i) and not Offline(obj, i) then
			instr, temp_tr = Plugin_Is_Instrument(obj, i, temp_tr) -- temp_tr, if created, will be re-used in subsequent cycles
				if not instr then break end
			end
		end
	local del = temp_tr and r.DeleteTrack(temp_tr)
	return instr
	end

local active = r.GetMediaTrackInfo_Value(tr, 'I_FXEN') ~= 0 and find_active(tr, nil)
return active or find_active(nil, take)

end



function Insert_ReaTune(tr, REATUNE)

	if REATUNE:gsub(' ','') ~= '' then
	-- thanks to Mespotine
	-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html#fxfloat_focus
	local ret, fxfloat_focus = r.get_config_var_string('fxfloat_focus')
	local autofloat = fxfloat_focus+0&4 == 4
	r.TrackFX_AddByName(tr, 'ReaTune', 0, -1) -- recFX is 0; instantiate is -1
		if autofloat then
		r.TrackFX_Show(tr, 0, 2) -- 2 hide floating window
		end
	local _, chunk = r.GetTrackStateChunk(tr, '', false) -- isundo false
	local chunk = chunk:gsub('WAK 0 0', 'WAK 0 1') -- ReaTune will be the only plugin in FX chain and the item won't have take FX in it, so no need to search for it in the chunk, WAK flags will belong to ReaTune instance
	r.SetTrackStateChunk(tr, chunk, false) -- isundo false
		if r.GetMediaTrackInfo_Value(tr, 'I_TCPH') < 175 then -- increase height so that the embedded UI is visible
		r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', 175)
		end
	end

end



function Get_First_Available_Numeral(f_path, cust_name, want_folder)
-- in order to resolve file collision if any

	local function get_numerals(f_path, cust_name, greatest, want_folder)
	local Enum = want_folder and r.EnumerateSubdirectories or r.EnumerateFiles
	Enum(r.GetResourcePath(), 0) -- clear cache for builds older than 6.20, ref https://forum.cockos.com/showthread.php?t=203235
	local path, f_name, ext = f_path:match('(.+[\\/])(.+)(%.%w+)$')
	-- adding end of string operator so that in iteration over files
	-- reapeaks files are ignored if they're located next to the media files;
	-- ? and * operators to accommodate folder names which end with either 'multi' or a numeral
	local base_name_patt = want_folder and '(.+)_multi$' or '(.+)_multi_.+'..ext..'$'
	local tr_temp, fx_chain, sfz = '.+%.RTrackTemplate$', '.+%.RfxChain$', '.+%.sfz$'
	local i, t, greatest = 0, {}, greatest or 0
		repeat
		local f = Enum(path:sub(1,-2), i) -- path arg seems to work regardless of trailing separator, but it used to not work with one
			if f and not f:match(tr_temp) and not f:match(fx_chain) and not f:match(sfz) -- ignoring non-media files so lingering instances don't affect multi-sample instrument number incrementation and their own old versions can be overwritten
			then
			local name = f:match(base_name_patt)
				if cust_name and name == cust_name or not cust_name and name == 'Instrument' then
				t[0] = '' -- store to indicate base file name collision which will require resolution by appending a numeral
				end
			local patt = want_folder and '' or '_.+'..ext
			local name, index = f:match('(Instrument) (%d+)_multi'..patt..'$') -- generic multi-sample name
				if not name or not index then
				name, index = f:match('(.+)_multi (%d+)'..patt..'$') -- custom name // run separately because multiple assignment doesn't work in ternary expressions
				end
				if (cust_name and name == cust_name or not cust_name and name == 'Instrument') and index then -- collect all numerals found appended to the base file name
				t[index+0] = ''
				greatest = math.max(index+0, greatest)
				end
			end
		i = i+1
		until not f
	return t, greatest
	end

local t, greatest = get_numerals(f_path, cust_name, greatest) -- want_folder nil, scanning file names
local fld_t
	if want_folder then
	-- if a folder is going to be created for the multi-sample
	-- account for folder names as well so that when folder is created
	-- its name doesn't collide with an existing folder,
	-- identical index will be appended to file and to the folder names,
	-- so if at the destination path there's another multi-sample
	-- indexed 5 and a multi-sample folder indexed 10,
	-- current multi-sample will be indexed 11,
	-- unless there's smaller available index
	fld_t, greatest = get_numerals(f_path, cust_name, greatest, want_folder)
	end

local f_index
	for i=0, greatest do
		if not t[i] and (not fld_t or not fld_t[i]) then -- first numeral absent in both file and folder names and thus absent among the table keys
		f_index = i -- index 0 is associated with base file name
		break end
	end

-- when index 0 was assigned above f_index var here becomes invalid
-- because for base file name no numeral is required
f_index = not f_index and greatest+1 or f_index > 0 and f_index

return f_index

end



function calculate_note_idx_from_note_name(note) -- used in Map_Multisample_Across_Keyboard()
-- octave range is -1 onwards
-- either sharp # or flat b signs can be used in note names
local note = note:gsub(' ','') -- remove all spaces
local note, oct = note:match('([A-G#]+)(%-?%d+)')
	if not note or not oct then return end
local t = {'B#/C','C#/Db','D','D#/Eb','E/Fb','E#/F','F#/Gb','G','G#/Ab','A','A#/Bb','B/Cb'}
local note_idx
	for k, n in ipairs(t) do
	local a, b = n:match('[^/]+'), n:match('/(.+)')
		if (a == note or b == note) then note_idx = k-1 break end -- -1 because MIDI note indices are 0-based
	end
return note_idx + (oct+1)*12
end



function Map_Multisample_Across_Keyboard(t, shared_range) -- used in Create_RS5k_Instrument()
-- t is array containing multisample note names
-- or note indices within the range 0-127;
-- shared_range is boolean to share the range between
-- two adjacent samples when transposing each,
-- i.e. lower sampler is transposed by half-1
-- along the range and the higher one by half+1,
-- if false, the in-between range is fully occupied
-- by the higher sample which is transposed down
-- until the the very last sample which is transposed
-- both down and up to fill up the empty range to note
-- 127 if its own pitch is lower;
-- if it's note names, the function relies on
-- calculate_note_idx_from_note_name();
-- NOTE THAT THE SAME TABLE THAT'S PASSED AS t ARG
-- IS RETURNED BY THE FUNCTION WITH REPLACED VALUES
-- IF IT ORIGINALLY CONTAINED NOTE NAMES, WHICH WILL
-- BE REPLACED WITH INTEGERS OF NOTE INDICES

local names = not tonumber(t[1])
local t = t
	if names then
	-- convert into indices
	local dups_t = {}
		for k, f_name in ipairs(t) do
		local note_name = f_name:match('.-([A-G#]+%-?%d+)')
		local idx = calculate_note_idx_from_note_name(note_name)
			if idx and not dups_t[idx] then -- excluding possible duplicates in the process
			t[k] = idx
			dups_t[idx] = ''
			end
		end
	else -- remove duplicates from the array of indices
		local function cleanup(k, idx, t)
			for i=1,#t do
				if t[i] == idx and i~=k then
				table.remove(t,i)
				end
			end
		return t[k+1] and cleanup(k+1, t[k+1], t) or t
		end
	t = cleanup(1, t[1], t)
	end

table.sort(t) -- sort in case unordered

local map_t = {}

	for k, note_idx in ipairs(t) do
	local prev, nxt = t[k-1], t[k+1]
	prev, nxt = prev or 0, nxt or 127 -- accounting for scenarios where there's only one or two note indices in the array
	-- calculate downward transposition amount
	local down = prev > 0 and math.ceil((note_idx-1 - prev)/(shared_range and 2 or 1)) or note_idx -- -1 to exclude note_idx from the calculation of the difference, division by 2 to find middle note, math.ceil is to round the result up in order to transpose down by 1 semitone more than up (only relevant for valid shared_range arg), see up calculation; if not prev, cover the entire range from 0 up to current note
	prev = note_idx == 0 and note_idx or note_idx-down
	-- calculate upward transposition amount
	local up = shared_range and (nxt < 127 and math.floor((nxt-1 - note_idx)/2) or 127-note_idx) -- same logic, math.floor is to transpose up by 1 semitone less than down; if not nxt, cover the entire range from current note up to 127 // upward transposition is only performed when shared_range is true
	nxt = shared_range and (note_idx == 127 and note_idx or note_idx+up) or k==#t and nxt -- when shared_range is false, in the last cycle select 127 which will be assigned to nxt var above to fill up the range from the last sample up
	table.insert(map_t, {root=note_idx, lokey=prev, hikey=nxt or note_idx}) -- if shared_range arg is true, nxt will be false until the last cycle of the loop
	end

-- the root/start/end note indices can then be converted into plugin control settings
-- such as Pitch@start, Note start, Note end of RS5k

--[[ CONTROL
	for i=1, #map_t, 1 do
	local root, st, fin = map_t[i].root, map_t[i].lokey, map_t[i].hikey
Msg(root, 'root')
Msg(st, 'st')
Msg(fin,'fin')
	end
--]]

return map_t

end



function Scroll_Track_To_Top(tr, env)
-- env arg is optional, only if the first envelope
-- displayed in its own lane needs to be scrolled to

-- calculate height of the pinned tracks (supported since 7.46)
-- only if pinned tracks are displayed in the pinned area
-- i.e. Track: Override/unpin all pinned tracks in TCP option is Off
local top_Y = 0
	if r.GetToggleCommandState(43573) == 0 then -- Track: Override/unpin all pinned tracks in TCP
		if r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN') == 1 then return end -- pinned track cannot be scrolled
		for i=0, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i)
			if r.IsTrackVisible(tr, false) -- mixer false
			and r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN') == 1 then
			top_Y = top_Y + r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl. envelopes
			end
		end
	top_Y = top_Y > 0 and top_Y+10 or top_Y -- 10 px is pinned track area separator width
	end

local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
local env_y = env and r.GetEnvelopeInfo_Value(env, 'I_TCPY') or 0 -- the result is the same as with tr_h

local dir = tr_y < top_Y and -1 or tr_y > top_Y and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			else break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y+env_y <= top_Y or dir < 0 and Y+env_y >= top_Y
	end
r.PreventUIRefresh(-1)
end



function Create_RS5k_Instrument(t, shared_range, path, tr, f_name)
-- t contains rendered file names without path;
-- path is their path;
-- tr is multi-sample track;
-- f_name is base file name containing instrument name
-- !!! IN RS5k WHEN 'Note (semitone shifted)' MODE IS ENABLED
-- THE PREVIEW BUTTON TRIGGERS WHATEVER PITCH
-- WHICH WAS SENT LAST FROM THE MIDI KEYBOARD,
-- SO THE SAMPLE ORIGINAL PITCH CANNOT BE RELIABLY
-- AUDITIONED THIS WAY

local f_names = {table.unpack(t)} -- copy because the file names in table t will be replaced with indices inside Map_Multisample_Across_Keyboard() and the same table will be returned modified
local map_t = Map_Multisample_Across_Keyboard(t, shared_range)
ACT(40001) -- Track: Insert new track // placed right beneath the multi-sample track because it is selected
local rs5k_tr = r.GetSelectedTrack(0,0)
r.GetSetMediaTrackInfo_String(rs5k_tr, 'P_NAME', 'RS5k '..f_name, true) -- isSet true
local range_unit, pitch_shift_unit = 1/127, 1/160
local Set = r.TrackFX_SetParam -- r.TrackFX_SetParamNormalized
local SetConfig = r.TrackFX_SetNamedConfigParm

-- thanks to Mespotine
-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html#fxfloat_focus
local ret, fxfloat_focus = r.get_config_var_string('fxfloat_focus')
local autofloat = fxfloat_focus+0&4 == 4


local rs5k_idx=0
	for k, v in ipairs(map_t) do
	local transp = 0.5-(v.root-v.lokey)*pitch_shift_unit -- OR 0.5-(v.root-v.lokey)/160 // Pitch@start value is amount in semitones by which the root note must be offset to arrive at the value of Note start setting, when Note start is lower than the root note the value mist be negative (below 0.5), otherwise positive (above 0.5) so to calculate it the diff between root and Start note values must be subtracted from 0.5 which is equal to 0 in Pitch@start parm
	local note_st, note_end = v.lokey*range_unit, v.hikey*range_unit -- OR v.lokey/127, v.hikey/127
		if k == 1 then -- insert first instance
		r.TrackFX_AddByName(rs5k_tr, 'ReaSamplOmatic5000', false, -1) -- instantiate // recFX false
		Set(rs5k_tr, rs5k_idx, 2, 0) -- Min. volume
		Set(rs5k_tr, rs5k_idx, 11, 1) -- Obey note-offs
		SetConfig(rs5k_tr, rs5k_idx, 'MODE', '2') -- Mode 2 semitone shifted
			if autofloat then
			r.TrackFX_Show(rs5k_tr, rs5k_idx, 2) -- 2 hide floating window after adding plugin instance
			end
		else -- instantiate rest by copying
		r.TrackFX_CopyToTrack(rs5k_tr, 0, rs5k_tr, k-1, false) -- ismove false
		end
	-- IN BUILDS OLDER THAN 7.70 WHEN NOTE VALUES ARE SET VIA THE API,
	-- THE ROOT NOTE NAME READOUT IN Pitch@start MAY NOT REFLECT
	-- THE ACTUAL ROOT NOTE OF THE SAMPLE
	-- EVEN THOUGH THE CALCULATION AND TRANSPOSITION IN TERMS OF PITCH
	-- ARE CORRECT, BUG REPORT https://forum.cockos.com/showthread.php?t=308333
	-- THE ROUNDING DOWN WAS AN ATTEMPT TO OVERCOME THE BUG
	-- BUT IT DOESN'T SEEM TO MAKE ANY DIFFERENCE, IF ANYTHING
	-- IN CERTAIN CASES IT CEMENTS THE WRONG NOTE NAME READOUT SO THAT IT CANNOT
	-- BE VISUALLY CORRECTED EVEN BY A CLICK WITHIN Pitch@start NUMERIC VALUE FIELD,
	-- WHAT'S IMPORTANT IS THAT THE NUMERIC VALUE BE CORRECT, WHICH IT IS
	Set(rs5k_tr, rs5k_idx, 3, note_st) -- Note start
	Set(rs5k_tr, rs5k_idx, 4, note_end) -- Note end
	Set(rs5k_tr, rs5k_idx, 5, transp) -- Pitch@start
	SetConfig(rs5k_tr, rs5k_idx, 'FILE0', path..f_names[k])
	SetConfig(rs5k_tr, rs5k_idx, 'DONE', '')
	rs5k_idx=rs5k_idx+1 -- increment for the next cycle
	end

r.SetOnlyTrackSelected(tr) -- reselect the multi-sample track deselecting all the rest

return rs5k_tr

end



function Create_Track_Template(tr, f_name, path, want_itms, want_envs)
-- tr is returned by Create_RS5k_Instrument();
-- f_name is the desired name for the track template file;
-- path is the path at which it should be created,
-- if invalid, \TrackTemplates folder at the resource path is used;
-- want_itms, want_envs are booleans to keep items and/or envelopes;
-- for a single track same as
-- r.Main_SaveProjectEx(0, filename, 1) -- save selected tracks as template; &2 items, &4 envelopes
-- which is supported since 6.53

local sep = r.GetResourcePath():match('[\\/]')
local path = path or r.GetResourcePath()..sep..'TrackTemplates'
path = path:sub(-1) == sep and path or path..sep

	if r.Main_SaveProjectEx then
	r.SetOnlyTrackSelected(tr)
	local flags = 1|(want_itms and 2 or 0)|(want_envs and 4 or 0) -- 1 is track template flag
	r.Main_SaveProjectEx(0, path..f_name..'.RTrackTemplate', flags)
	return end

local ret, chunk = r.GetTrackStateChunk(tr, '', false) -- isundo false

	if not want_itms then -- remove all item chunks
		for i=0, r.CountTrackMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr, i)
		local ret, itm_chunk = r.GetItemStateChunk(item, '', false) -- isundo false
			if ret then
			itm_chunk = Esc(itm_chunk)
			chunk = chunk:gsub(itm_chunk, '')
			end
		end
	end
	if not want_envs then -- remove all envelope chunks
		for i=0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
		local ret, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			if ret then
			env_chunk = Esc(env_chunk)
			env_chunk = env_chunk:match('<PARMENV') and '<PARMENV.->' or env_chunk -- PARMENV is FX parm envelope, its first line in the track chunk differs from that of the envelope chunk, namely
			-- track chunk: <PARMENV 5:_Pitch_for_start_note 0 1 0.5 "parameter name / FX instance name"
			-- envelope chunk: <PARMENV 5:_Pitch_for_start_note 0.000000 1.000000 0.500000
			-- therefore as a source string in gsub the pattern used instead,
			-- all FX parm envelope chunks could have been removed outside of this loop
			-- in one go by simply passing the source string and not limiting the repacement count by 1
			chunk, repl = chunk:gsub(env_chunk..'\n*', '', 1)
			end
		end
	end

	if r.file_exists(path..f_name) then
	f_name = f_name..'_'..create_unique_time_based_ID() -- since path length increases may need length validation and truncation
	end

local f = io.open(path..f_name..'.RTrackTemplate', 'w')
	if not f then return end
f:write(chunk)
f:close()

end



function Create_FX_Chain_Preset(obj, f_name, path, want_input)
-- obj is track or take;
-- f_name is the desired name for the track template file;
-- path is the path at which it should be created,
-- if invalid, \FXChains folder at the resource path is used;
-- want_input is boolean to save input fx chain,
-- obviously only applies to tracks;
-- for takes relies on Esc()

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetChunk = tr and r.GetTrackStateChunk or take and r.GetItemStateChunk
local ret, GUID, item, nxt_GUID
	if take then
	ret, GUID = r.GetSetMediaItemTakeInfo_String(obj, 'GUID', '', false) -- isSet false
	GUID = Esc(GUID)
	local take_idx = r.GetMediaItemTakeInfo_Value(obj, 'IP_TAKENUMBER')
	item = r.GetMediaItemTake_Item(obj)
	local next_take = r.GetTake(item, take_idx+1)
		if next_take then
		ret, nxt_GUID = r.GetSetMediaItemTakeInfo_String(next_take, 'GUID', '', false) -- isSet false
		nxt_GUID = Esc(nxt_GUID)
		end
	end
local obj = tr and obj or item
local ret, chunk = GetChunk(obj, '', false) -- isundo false
local sect = tr and not want_input and '<FXCHAIN' or '<FXCHAIN_REC'
local fx_chain = tr and (chunk:match('.-('..sect..'.-WAK.+>)\n><FXCHAIN_REC')
or chunk:match('.-('..sect..'.-WAK.+>)\n<ITEM') or chunk:match('('..sect..'.-WAK.+>)\n>'))
or take and chunk:match(GUID..'.-(<TAKEFX.+WAK.->).-'..(nxt_GUID or ''))

-- remove all FX parameter envelopes, if any
fx_chain = fx_chain:gsub('<PARMENV.->\n*','')
-- exclude data which aren't present
-- in the REAPER generated FX chain preset
local clean_chunk, fx_chunk, complete = '', ''
	for line in fx_chain:gmatch('[^\n\r]+') do
		if line:match('^BYPASS') then -- new fx chunk, dump previously collected data
		clean_chunk = clean_chunk..(#clean_chunk > 0 and '\n' or '')..fx_chunk
		fx_chunk = line -- start new
		complete = 1
		elseif #fx_chunk > 0 then -- OR 'if complete'
		complete = nil -- reset
		fx_chunk = fx_chunk..(#fx_chunk > 0 and '\n' or '')..line
		end
	end
	if not complete then -- outstanding content of the last fx chunk
	clean_chunk = clean_chunk..'\n'..fx_chunk
	end

clean_chunk = clean_chunk:sub(1,-2):gsub('FLOATPOS.-\n','') -- removing last trailing closure and FLOATPOS coordinates

local sep = r.GetResourcePath():match('[\\/]')
local path = path or r.GetResourcePath()..sep..'FXChains'
local path = path:sub(-1) == sep and path or path..sep
	if r.file_exists(path..f_name) then
	f_name = f_name..'_'..create_unique_time_based_ID() -- since path length increases may need length validation and truncations
	end

local f = io.open(path..f_name..'.RfxChain', 'w')
	if not f then return end
f:write(clean_chunk)
f:close()

end



function Create_Folder_Move_Files_Update_Take_Sources(f_path, file_t, tr)
-- f_path is full path of the source file formatted
-- according to the script naming convention
-- and which is the basis for the newly created folder name;
-- file_t is an array of final file names formatted
-- according to the script naming convention;
-- tr is track of the rendered multi-sample items

local path, name, ext = f_path:match('(.+[\\/])(.+)(%.%w+)$') -- capture base name, including number, of the source file, excluding the note name
local sep = path:match('[\\/]')
local dir = path..(name:match('Instrument.-multi') or name:match('.-multi[%s%d]*')) -- either generic or custom mult-sample name, custom may end with a numeral, in generic the numeral precedes 'multi'
local result = r.RecursiveCreateDirectory(dir, 0)
	if result == 0 then
	return path, space(7)..'Directory creation failed.'
	..'\n\nThe multi-sample isn\'t affected.'
	end

local err = 'The multi-sample files couldn\'t be\n\n moved to the created directory.'

local failure

	for k, fn in ipairs(file_t) do
	-- read file at its current location
	local f = io.open(path..fn, 'rb')
		if not f then -- abort on failure at the 1st file, because no point to continue
			if k == 1 then return path, err
			else failure = 1 end
		end
	local cont = f:read('*a')
	f:close()
	local f = io.open(dir..sep..fn, 'wb')
		if not f then -- abort on failure at the 1st file, because no point to continue
			if k == 1 then return path, err
			else failure = 1 end
		end
	f:write(cont)
	f:close()
	end

	-- either change take sources and remove files from their old location if no failures
	-- or remove all files successfully created at the new path in case of failures during movement
	for k, fn in ipairs(file_t) do
		if not failure then
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		local item = r.GetTrackMediaItem(tr, k-1)
		r.SetMediaItemSelected(item, true) -- selected true // so that only this item offline state was toggled
		ACT(40440) -- Item: Set selected media temporarily offline // set offline before changing the source
		local take = r.GetActiveTake(item)
		local old_src = r.GetMediaItemTake_Source(take)
		local new_src = r.PCM_Source_CreateFromFile(dir..sep..fn)
		r.SetMediaItemTake_Source(take, new_src)
		r.PCM_Source_Destroy(old_src)
		ACT(40439) -- Item: Set selected media online
		end
	-- remove
	local path = failure and dir..sep..fn or path..fn
	local rem = #r.GetPeakFileName(path, '') > 0 and os.remove(r.GetPeakFileName(path, '')) -- remove peak files
	os.remove(path)
	end

	 -- failures registered during file movement loop other than at the very 1st file
	if failure then return path, err end

return dir..sep

end




-- WEED OUT ERROR STATES BEFORE DIALOGUE --

-- SETUP ERRORS --

local err = not Dir_Exists(r.GetProjectPath('')) and 'Project media directory is unavailable.\n\n'
..space(8)..'Creation of new files will fail.'
local item = r.GetSelectedMediaItem(0,0)
err = err or not item and 'No selected items.'
err = err or r.CountSelectedMediaItems(0) > 1 and 'More than one selected item.'
local take_cnt = item and r.CountTakes(item)
err = err or take_cnt == 0 and 'The selected item is not an audio or MIDI item.'
or r.GetMediaItemInfo_Value(item, 'B_MUTE_ACTUAL') == 1 and 'The item is muted.'

	if take_cnt and take_cnt > 1
	and r.MB(space(4)..'There\'re more than one take in selected item.\n\n'..space(14)..'Only the active take will be used.', 'PROMPT', 1) == 2 -- user canceled
	then return r.defer(no_undo)
	end

local take = item and r.GetActiveTake(item)
local midi = take and r.TakeIsMIDI(take)
local note_cnt = midi and ({r.MIDI_CountEvts(take)})[2] > 0
err = err or midi and (r.GetMediaTrackInfo_Value(r.GetMediaItemTrack(item), 'B_MUTE') == 1 and 'Item track is muted.' -- audio items are rendered with muted track as well
or not note_cnt and 'The selected MIDI item contains no notes.')
local tr = note_cnt and r.GetMediaItemTrack(item)

local valid_rs5k_idx_t = tr and Valid_RS5k_Exist(tr)
err = err or tr and not valid_rs5k_idx_t and space(12)..'No unbypassed online instance\n\n  of ReaSamplOmatic5000 with active sample\n\n    has been found in the track main FX chain.'
local notes_within_range_t = not err and valid_rs5k_idx_t and RS5k_vs_MIDI_Item_Note_Ranges(tr, valid_rs5k_idx_t, take)
local no_note_gap, note_cutoff
	if notes_within_range_t and not err then
	no_note_gap, note_cutoff = Notes_Start_Gap_And_Cutoff(notes_within_range_t)
	end
err = err or tr and (not notes_within_range_t and --space(10)..'Note range enabled in ReaSamplOmatic5000\n\ndoes not match non-muted note events in the MIDI item.'
'Non-muted note events which would match\n\n'..space(10)..'ReaSamplOmatic5000 note range\n\n'..space(10)..'weren\'t found within item bounds.'
or not no_note_gap and space(4)..'There\'s gap between MIDI item start\n\n\t  and valid note events\n\nwhich will add leading silence to the sample.\n\n'..space(21)..'Wish to continue?'
or r.GetMediaTrackInfo_Value(tr, 'I_FXEN') == 0 and 'ReaSamplOmatic5000 track FX chain is disabled.'
or r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 1 and 'ReaSamplOmatic5000 track is muted.')

local note_t = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'}
local retval, src_take_name, note_name, want_folder

	if not err or err:match('gap between') then
	retval, src_take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- setNewValue is false
	note_name = src_take_name:match('([A-G][#%-]*%d+)%s*$')
	want_folder = src_take_name:match('^%s*/')
	end


err = err or not note_name and space(25)..'No note name\n\n'..space(14)
..'in the item/active take name\n\n'..space(22)
..'or it is malformed.\n\n  Must include note name and octave number.'
or note_name and note_name:match('%-#') and 'Item/active take note name is malformed.'

local length_issue_mess, peak
	if not err then
		if midi then -- evaluate likelihood of silent tale after rendering
		local length_issue_mess1, tail1 = Validate_MIDI_Item_Length(tr, valid_rs5k_idx_t, notes_within_range_t) -- want_note_offs false, tail return value is only valid when the rendered item is going to include silent tail
		-- calculate tail length for samples triggered with RS5k Obey note-offs setting enabled
		-- to select the warning message with the shortest and thus more accurate tail value
		-- because in both function calls it's calculated relative to the farthest MIDI note event
		-- which triggers the sample without and with Obey note-offs setting enabled
		local length_issue_mess2, tail2 = Validate_MIDI_Item_Length(tr, valid_rs5k_idx_t, notes_within_range_t, 1) -- want_note_offs true
		-- select message with the shortest tail value
		length_issue_mess = length_issue_mess1 and (not tail1 -- insufficient render space
		or tail1 and not tail2 or tail1 <= tail2) -- excessive render space
		and length_issue_mess1
		or length_issue_mess2
		else -- evaluate take audio source loudness
		local result
		result, peak = Source_Too_Quiet_Or_Loud(take, tr, rs5k_t, note_t, midi) -- tr, rs5k_t, note_t arguments are irrelevant here
		local normal = result == 1 and 'The source take seems too quiet'
		or result == 2 and 'The source take seems loud'
		err = result == 0 and 'The source take is silent.'
		or normal and normal..'.\n\nYES  —  continue and normalize to -1 dB\n\nNO  —  continue without normalization'
		end
	end

local normalize

	if err then
		if not err:match('leading silence') and not err:match('normalize') then
		r.MB(err, 'ERROR', 0)
		return r.defer(no_undo)
		elseif err:match('normalization') then
		local resp = r.MB(err, 'WARNING', 3)
			if resp == 2 then return r.defer(no_undo) -- user canceled
			elseif resp == 6 then normalize = 1
			end
		end
	else
	local err = err or length_issue_mess
		if err and r.MB(err, 'WARNING', 1) == 2 then
		return r.defer(no_undo) -- user canceled
		end
	end

local CHASE

	if note_cutoff then
	local resp = r.MB('Some notes are cut off by the item start and won\'t play.\n\n'
	..'YES — Leave as is\n\nNO — Temporarily auto-enable "Chase MIDI note-ons"', 'WARNING', 3)
		if resp == 2 then	return r.defer(no_undo) -- user cancelled
		elseif resp == 7 then CHASE = 1 end
	end



-- DIALOGUE FOR USER INPUT --

local autofill

::RETRY::

local err

-- OPEN THE DIALOGUE
local is_new_value,filepath,sectionID,cmdID,mode,reso,val,contextstr = r.get_action_context()
local cmdID = r.ReverseNamedCommandLookup(cmdID)
local last_sett = r.GetExtState(cmdID, 'USER SETTINGS')
local comment = '\nFor step reset mode add letter R or r to the Step field'
local retval, user_output = r.GetUserInputs('Range properties (e.g. C-1 – G#4  or  0 – 3); oct. range: -1 – 9', 3,
'Range ( notes or octaves ),Step ( in semitones, empty = 1 ),Comment, separator=\n,extrawidth=190',
autofill or (#last_sett > 0 and last_sett or '\n')..comment)

	if not retval
	or user_output:gsub(' ',''):match('^\n\n$') -- empty fields or only contaning spaces
	or user_output:match('^%s*\n%s*\n%s*'..comment)
	then return r.defer(no_undo) end


local output = user_output:match('(.+)'..comment)
output = output:upper() -- allow lower case letters in note names, WHICH IS OK SINCE ONLY SHARPS # ARE SUPPORTED AS ACCIDENTALS, so flat sign 'b' will invalidate the input even if lowercase
local range, step = output:match('^(.*)\n(.*)$') -- if + instead of * and 'step' field is empty and thus nil, 'range' field returns nil as well

local patt = '([A-G%s]*[#%-%s]*%d+)' -- the pattern is desined to capture range start/end as both note and octave allowed by * operator; allowing spaces between elemens
--local note_patt, oct_patt = '([A-G%s]+[#%-%s]*%d+)', '(%-?%d+)'
local range_st = range and range:match('^%s*'..patt..'%s*%-') -- allow leading/trailing spaces
local range_end = range_st and range:match(range_st..'%s*%-%s*'..patt..'%s*$') -- capture separately, since if the 1st capture is nil, the 2nd one is nil as well even being valid
local range_st = range_st and range_st:gsub(' ','') -- strip out any spaces
local range_end = range_end and range_end:gsub(' ','') -- strip out any spaces


-- WEED OUT ERROR STATES AFTER THE DIALOGUE --

-- if range_st and range_end are valid after capture above
-- the only scenario when they're malformed is when negative octave indicator
-- and sharp sign are swapped which is permitted by the above pattern
err = (not range_st or range_st:match('-#')) and space(10)..'No range start or it\'s malformed' -- dash and range start
or (not range_end or range_end:match('-#')) and space(10)..'No range end or it\'s malformed' -- dash and range end
or not range_st and not range_end and space(10)..'No range start and end\n\n'..space(12)..'or they\'re malformed'

	if err then
		if r.MB(err, 'ERROR', 5) == 4 then
		autofill = user_output goto RETRY
		end
	return r.defer(no_undo) end


-- at this stage at least one type of range start/end notaion should be valid
-- either by note or by octave
local patt1, patt2 = '^[A-G][#%-]*%d+$', '^%-?%d+$'
local range_st_note = range_st:match(patt1)
local range_end_note	= range_end:match(patt1)
local range_st_oct = range_st:match(patt2)
local range_end_oct = range_end:match(patt2)


-- validate range notation consistency
err = range_st_note and range_st_note == range_end_note and 'Range start and end notes are the same'
or range_st_oct and range_st_oct == range_end_oct and 'Range start and end octaves are the same'
or (range_st_note and range_end_oct or range_st_oct and range_end_note)
and '\t'..space(9)..'Mixed range.\n\n'..space(8)..'Start and end must both be defined\n\n    by either note names or octave numbers.'

	if err then
		if r.MB(err, 'ERROR', 5) == 4 then
		autofill = user_output goto RETRY
		end
	return r.defer(no_undo) end


local st_num, end_num = range_st:match('%-?%d+'), range_end:match('%-?%d+')
-- validate range bounds
err = ' is outside of the note range'
err = st_num+0 < -1 and 'Range start is'..err or end_num+0 > 9 and 'Range end is'..err
or st_num+0 > end_num+0 and space(6)..'The range is chosen in reverse.\n\n Must start from a lower note/octave.'

	if err then
		if r.MB(err, 'ERROR', 5) == 4 then
		autofill = user_output goto RETRY
		end
	return r.defer(no_undo) end

-- validate step value
local step_val = step:gsub(' ','') -- strip out spaces // OR step:match('%S+')
local step_reset = step:match('[Rr]+')
err = #step_val > 0 and (not tonumber(step_val) and not step_reset or tonumber(step_val) and step_val+0 == 0)
and space(21)..'If the step value is supplied\n\n'..space(16)..'it must be a whole positive number.\n\n'
..space(17)..'If none is supplied it defaults to 1.\n\n'..space(27)..'Wish it to be set to 1?'
or range_st_note and step_reset and space(12)..'Step reset indicator is only supported\n\n'
..space(12)..'when the range is defined in octaves.\n\n\t'..space(12)..'Wish to discard it?'

	if err then
	local resp = r.MB(err, 'ERROR', 3)
		if resp == 6 then
		-- 'not range_st_note' is true when step reset indicator error is true
		step = not range_st_note and 1 or step
		step_reset = not range_st_note and step_reset or nil
		elseif resp == 7 then
		autofill = user_output goto RETRY
		else
		return r.defer(no_undo)
		end
	end

local step = step:match('%d+') or 1 -- no need to convert string to number if the string is a digit

local root_note, root_oct = note_name:match('(%a#?)(%-?%d+)')

-- no need to convert string to number if the string is a digit
local oct_st = range_st:match('%-?%d+')
local oct_end = range_end:match('%-?%d+')

-- all note indices will be 1-based because note_t indexing is 1-based
local root_idx, range_st_idx, range_end_idx, range_st_shift, range_end_shift

	if tonumber(range_st) and tonumber(range_end) then -- range in octaves // one var would suffice because they've been validated through error traps above

	-- no need to convert string to number if the string is a digit
	--	range_st_shift = (range_st - root_oct)*12 -- in semitones; full octaves
	--	range_end_shift = (range_end - root_oct)*12 -- in semitones; full octaves
	-- OR
	-- SAME AS ABOVE BUT USING DESIGNATED VARIABLES FOR START/END
	range_st_shift = (oct_st - root_oct)*12 -- in semitones; full octaves
	range_end_shift = (oct_end - root_oct)*12 -- in semitones; full octaves

		for k, v in ipairs(note_t) do
			if v == root_note then
				if not step_reset then
				root_idx, range_st_idx, range_end_idx = k, k, k -- note index within octave, since only octaves are specified, start/end notes indices within octave are identical to the root note index
				else -- when step_reset mode is chosen, range start index is always 1, i.e. C, and range end index is always 12, i.e. B
				root_idx, range_st_idx, range_end_idx = k, 1, 11 -- note indices within octave, 11 because the range ends with the note B of the last octave in the range
				end
			break
			end
		end

		if step_reset then -- ensure that the range starts at C note
		range_st_shift = range_st_shift + (range_st_idx - root_idx) -- adding to range_st_shift calculated above difference between C and root note indices within octave because the range must start at C
		range_end_shift = (oct_end+1 - root_oct)*12 -- end octave is increased by 1 because the end octave value only refers to octave start, i.e. C, to which step value must still be applied
		end

	elseif not tonumber(range_st) and not tonumber(range_end) then -- range in notes // one var would suffice because they've been validated through error traps above

	-- calc distance between the root note and the range start/end notes
		for k, v in ipairs(note_t) do
			if v == root_note then root_idx = k end -- OR 'if root_note:match(v) ...' if it weren't isolated above; root note index within octave
			if v == range_st:match('[A-G#]+') then range_st_idx = k end -- range start note index within octave
			if v == range_end:match('[A-G#]+') then range_end_idx = k end -- range end note index within octave
			if root_idx and range_st_idx and range_end_idx then break end
		end

		-- calculate shift in semitones within octave relative to the root (i.e. source item note)
		range_st_shift = range_st_idx - root_idx -- if root is greater, then the result is negative (picth down), otherwise - positive (pitch up)
		range_end_shift = range_end_idx - root_idx -- same

		-- calculate shift in semitones across octaves relative to the root (i.e. source item note)
		range_st_shift = (oct_st - root_oct)*12 + range_st_shift -- if root idx is greater, then the result is negative (picth down), otherwise - positive (pitch up)
		range_end_shift = (oct_end - root_oct)*12 + range_end_shift -- same

	end


-- Determine if the root and end notes are included in the range after 'step' is applied by determining if the diff between start and root and start and end is a multiple of the step value
local root_pitch, start_pitch, end_pitch = root_oct*12 + root_idx, oct_st*12 + range_st_idx, oct_end*12 + range_end_idx
local fract1 = (step_reset and root_idx > 1 and root_idx-1 or 0 or not step_reset and start_pitch - root_pitch)%step -- in step_reset mode only note indices within octave matter, the expression will only be true for notes other than C, because the count always starts at C, -1 because count starts at C which is itself doesn't fall within the range
local fract2 = step_reset and 0 or (end_pitch - start_pitch)%step -- OR start_pitch - end_pitch, doesn't matter here // in step_reset mode end_pitch is irrelevant
--[[ -- in the following variants step reset mode isn't taken into account
local fract1 = (start_pitch - root_pitch)%step
local fract2 = (end_pitch - start_pitch)%step -- OR start_pitch - end_pitch, doesn't matter here
-- OR
-- local whole, fract1 = math.modf((start_pitch - root_pitch)/step)
-- local whole, fract2 = math.modf((end_pitch - start_pitch)/step) -- OR start_pitch - end_pitch, doesn't matter here
-- OR
-- local fract1 = range_st_shift%step
-- local fract2 = (math.abs(range_st_shift)+math.abs(range_end_shift))%step
-- OR
--	local fract1 = tonumber(tostring((range_st_shift - root_pitch)/step):match('%.([%d]+)')) -- check decimal component; alternative
--	local fract2 = tonumber(tostring((range_st_shift - range_end)/step):match('%.([%d]+)')) -- check decimal component; alternative
fract1, fract2 = fract1+0, fract2+0 -- convert string to number for evaluation below
--]]


local prompt = '\n\n'..space(7)..'You may opt for step 1\n\nand after rendering decide which\n\n'..space(7)..'pitches you like to keep.\n\n  Click "NO" to make corrections.'
prompt = prompt:gsub('\n\n','%0'..space(15))
local root_note_mess = 'The root note won\'t be included in the final range\n\n'
..space(8)..'being skipped after the \'step\' is applied.'..prompt
-- fractional values aren't 0; message type is conditional on the range type (notes or octaves)
local note_range = range_end:match('[A-G]+') -- OR range_st:match('[A-G]+')
err = note_range and (fract1 ~= 0 and fract2 ~= 0
and space(18)..'The root and the end notes\n\n'..space(12)..'won\'t be included in the final range\n\n'
..space(9)..'being skipped after the \'step\' is applied.'..prompt
or fract1 ~= 0 and root_note_mess
or fract2 ~= 0 and 'The end note won\'t be included in the final range\n\n'
..space(8)..'being skipped after the \'step\' is applied.'..prompt)
or fract1 ~= 0 and root_note_mess -- only applies to step_reset mode because otherwise the range defined in octaves always starts at the root note so it's always included
or fract2 ~= 0 and space(5)..'The final range won\'t end with the root note\n\n'
..space(20)..'after the \'step\' is applied.'..prompt

	if err then resp = r.MB(err, 'PROMPT', 3)
		if resp == 7 then autofill = user_output goto RETRY
		elseif resp == 2 then return r.defer(no_undo) -- user canceled
		end
	end


	if PROMPT_FOR_PITCHSHIFT_ALGO:match('%S') then
	local I_PITCHMODE = r.GetMediaItemTakeInfo_Value(take, 'I_PITCHMODE')
		if I_PITCHMODE ~= 0 and I_PITCHMODE ~= 13 then -- SoundTouch or Rubber Band
		local resp = r.MB('Set the source take pitch shift mode\n\nYES  —  SoundTouch\n\nNO  —  Rubber Band', 'PROMPT', 3)
			if resp == 2 then return r.defer(no_undo)
			else
			r.SetMediaItemTakeInfo_Value(take, 'I_PITCHMODE', resp == 6 and 0 or 13<<16)
			end
		end
	end


-- M A I N  R O U T I N E  S T A R T --

r.SetExtState(cmdID, 'USER SETTINGS', user_output, false) -- persist false // store latest user settings to auto-fill the dialogue on next load

local pitch_shift_algo = r.GetMediaItemTakeInfo_Value(take, 'I_PITCHMODE') -- store source item pitch shift algo setting to apply to the copied item after applying FX / gluing since it resets to 'Project default', after 'Item: Apply track/take FX to items' it does as well

-- Placed before the undo block, because otherwise undos during the routine break it creating undo point for each action

	if want_folder then -- remove slash from the name so that when rendering REAPER doesn't convert it into underscore in the file name due to its being illegal character, as a result of which the underscore is recognized by the script as a custom file name and assigns it to f_name_part var below // THE SLASH IN THE TAKE NAME IS REINSTATED DOWNSTREAM
	r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', src_take_name:match('/%s*(.+)'), true) -- setNewValue is true
	end

local rs5k_src -- rs5k_src var is UNUSED going forward
MONO = #MONO:gsub(' ','') > 0 -- OR MONO:match('%S')

	if midi then -- render MIDI item to audio
	local enable = CHASE and ACT(41992) -- Options: Chase MIDI note-on/CC/PC/pitch in project playback // enable so that notes with cut-off start which were detected produce note-on message as user has chosen in the warning dialogue
	local APPLY = MONO and 40361 -- Item: Apply track/take FX to items (mono output)
	or 40209 -- Item: Apply track/take FX to items // multi-channel render action is ignored because RS5k can only output a max of 2 channels
	ACT(APPLY)
	ACT(40131) -- Take: Crop to active take in items // because processed take is added as new take to the item

	local take, src = r.GetActiveTake(r.GetSelectedMediaItem(0,0)) -- src var is only initialized for the next line
	rs5k_src, src = Get_Take_Source_File(take) -- selected item after render; store source path to delete it after copying and gluing to a unique file; done at this stage -- rs5k_src var is UNUSED going forward
	local rms_dB = Calculate_Take_RMS_Loudness(take, 256, time_window, -60) -- block_size 256, gate_dB -60 // returns nil for silent take
	local clipped
	peak, clipped = table.unpack(rms_dB and {Get_Audio_Peak_In_Take(take)} or {}) -- only get peak if not silent
	local err = not rms_dB and {'The rendered take is silent.', 'ERROR', 0}
	or rms_dB < -42 and {'The rendered take seems too quiet.\n\nYES  —  continue and normalize to -1 dB\n\nNO  —  continue without normalization', 'WARNING', 3}
	or clipped and {'The rendered take is likely clipped.\n\n\tWish to continue?', 'WARNING', 1}

	local abort
		if err then
		local resp = r.MB(table.unpack(err))
			if resp < 3 then abort = 1 -- either silent or user canceled
			elseif resp == 6 then normalize = 1
			end
		end

		if not abort then ACT(40698) end -- Edit: Copy items // copy if user hasn't aborted, placed before undo so that the rendered take is copied and not the original MIDI

	r.Undo_DoUndo2(0); r.Undo_DoUndo2(0) -- restore back to MIDI item // rolling back crop and apply track fx

	local disable = CHASE and ACT(41992) -- Options: Chase MIDI note-on/CC/PC/pitch in project playback // restore original state after rendering

		if abort then
		os.remove(r.GetPeakFileName(rs5k_src, '')) -- delete peaks file // using function in case peak files are set to be stored in a separate directory // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
		os.remove(rs5k_src)
			if r.ValidatePtr(src, 'PCM_source*') then r.PCM_Source_Destroy(src) end -- after undo, source pointer becomes invalid, but in case remained valid, destroy
		return r.defer(no_undo)
		end

	end



r.PreventUIRefresh(1)
r.Undo_BeginBlock()

-- COPY ITEM TO A NEW TRACK INSERTED RIGHT BELOW THE SOURCE TRACK --

-- Only copy if not MIDI item which is copied in its own routine above
local copy = not midi and ACT(40698) -- Edit: Copy items

local tr = Insert_Multi_Sample_Track(item)

ACT(40042) -- Transport: Go to start of project // OR r.SetEditCurPos(0, true, false) -- moveview true, seekplay false
ACT(42398) -- Item: Paste items/tracks // paste a copy of

local orig_take = take -- store before updating variables below
-- get pointers of the pasted source item copy
local item = r.GetSelectedMediaItem(0,0)
local take = r.GetActiveTake(item)


	if not midi and take_cnt > 1 then -- only relevant if source item is audio as midi item is processed differently
	ACT(40131) -- Take: Crop to active take in items // separate the copy of source take from the copy of its parent item
	end

-- The source item copy will be glued if in the USER SETTINGS
-- the user chose to embed fades
local GLUE = FADE:gsub(' ','') ~= '' and 40257 -- Item: Glue items, ignoring time selection, including leading fade-in and trailing fade-out
or 40362 -- Item: Glue items, ignoring time selection

	if midi then
	ACT(42228) -- Item: Set item start/end to source media start/end // expand then take before gluing for transposition so the tail, if any, isn't hidden
		if r.GetMediaItemInfo_Value(item, 'D_VOL') ~= 1 then -- if MIDI item volume was other than at unity, after action 'Apply track/take FX' is executed it won't be reset even though will have already affected the level of the rendered item, so set to unity to prevent it from affecting the take in subsequent gluing which also prints take/item volume to file
		r.GetMediaItemInfo_Value(item, 'D_VOL', 1)
		end
		if normalize then
		Normalize_Take(take, peak)
		local file_name = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(take), '') -- store original before gluing
		ACT(40362) -- Item: Glue items, ignoring time selection
		-- remove original rendered file
		os.remove(r.GetPeakFileName(file_name, '')) -- delete peaks file // using function in case peak files are set to be stored in a separate directory // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
		os.remove(file_name)
		end

	else -- Apply FX to take if user opted for and/or glue // only if NOT MIDI item, because MIDI item is rendered with take FX, if any, in any case by dint of relying on 'Item: Apply track/take FX to items' action

	-- get before updating the pointers below
	local orig_tr = r.GetMediaItemTake_Track(orig_take)

		if normalize then Normalize_Take(take, peak) end

	local render_fn

		if APPLY_FX:gsub(' ','') ~= '' -- OR APPLY_FX:match('%S')
		and FX_Enabled(item) then

		-- copy to be able to apply them to the take copy on the multi-sample track
		Copy_FX_To_Multi_Sample_Track_And_Remove(orig_tr, tr)
		local file, src = Get_Take_Source_File(take) -- r.GetActiveTake(r.GetSelectedMediaItem(0,0))
		local ch_cnt = r.GetMediaSourceNumChannels(src)
		local APPLY = (ch_cnt == 1 or MONO) and 40361 -- Item: Apply track/take FX to items (mono output)
		or ch_cnt == 2 and 40209 -- Item: Apply track/take FX to items
		or 41993 -- Item: Apply track/take FX to items (multichannel output)
		ACT(APPLY) -- Item: Apply track/take FX to items (...) // uncludes fx tail whose length is determined by the value at Preferences -> Media -> Take FX tail length: // resulting file contains 'render-00X.ext'
		render_fn = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(r.GetActiveTake(item)), '')
		Copy_FX_To_Multi_Sample_Track_And_Remove(tr) -- remove copied FX from the multi-sample track
		ACT(40131) -- Take: Crop to active take in items // because processed take is added as new take to the item
		ACT(42228) -- Item: Set item start/end to source media start/end // expand the take before gluing for transposition so the tail isn't hidden
		end

	ACT(GLUE) -- if 'Apply FX' was used above resulting file will contain 'render 00X-glued.ext, if not - glue to create a new file different from the source, resulting file will contain '-glued.ext'
		if render_fn then
		-- remove rendered file created to apply FX before gluing
		os.remove(r.GetPeakFileName(render_fn, '')) -- delete peaks file // using function in case peak files are set to be stored in a separate directory // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
		os.remove(render_fn)
		end
	end


	if want_folder then -- reinstate slash in the source take name after removing it so that when rendering REAPER doesn't convert it into underscore in the file name due to its being illegal character, as a result of which the underscore is recognized by the script as a custom file name and assigns it to f_name_part var above
	r.GetSetMediaItemTakeInfo_String(orig_take, 'P_NAME', src_take_name, true) -- setNewValue is true
	end


-- Insert ReaTune and its display in the TCP, supported since build 6.30
-- placed here after possible applying take FX with 'Item: Apply track/take FX to items'
-- to prevent applying ReaTune pitch correction as well in a remote case its enabled
-- via default preset which also gets auto-enabled when FX is instantiated via the API
Insert_ReaTune(tr, REATUNE)


-- Rename glued file into format 'name_multi_note name.ext' or 'Instrument X_multi_note name.ext', delete rendered file created pre-glue by 'Apply track/take FX to items action' (if any)
local remove_fade = GLUE == 40362 and ACT(41193) -- Item: Remove fade in and fade out // only if fade is disabled in the USER SETTINGS and hence GLUE action is 40362 which ignores fades
ACT(40440) -- Item: Set selected media temporarily offline // set offline before renaming the source file
local take = r.GetActiveTake(r.GetSelectedMediaItem(0,0))
r.SetMediaItemTakeInfo_Value(take, 'I_PITCHMODE', pitch_shift_algo) -- set in the copied item pitch shift algo selected in the source item // by this point the algo will have been reset to project default after multiple renders and glues because these don't preserve original algo
local fn = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(take), '')
local rem = #r.GetPeakFileName(fn, '') > 0 and os.remove(r.GetPeakFileName(fn, '')) -- remove lingering peak file with old name the glued file had before being renamed if located at the same path as the source media
local f_path, f_name = fn:match('^(.+[\\/])([^\\/]+)$') -- isolate file path and name with ext
local ext = f_name:match('%.%w+$')
local f_name_part = f_name:match('^(.+)[A-G][#%-]*%d+')
f_name_part = f_name_part and f_name_part:match('(.-)%s*$') -- exclude trailing space

want_folder = want_folder or MULTI_SAMPLE_FOLDER:match('%S')

local new_fn = f_name_part and f_name_part..'_multi_'..note_name
or 'Instrument_multi_'..note_name
local index = Get_First_Available_Numeral(f_path..new_fn..ext, f_name_part, want_folder)

	if index then -- index is valid because there's file name collision which must be resolved by adding it to the file name
	new_fn = new_fn:gsub(f_name_part and 'multi' or 'Instrument', '%0 '..index, 1)
	end

r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', new_fn, true) -- name the item after the file; setNewValue true
new_fn = f_path..new_fn..ext
local ok, message = os.rename(fn, new_fn)
local new_src = r.PCM_Source_CreateFromFile(new_fn)
r.SetMediaItemTake_Source(take, new_src) -- assign the renamed file as a source
ACT(40439) -- Item: Set selected media online
ACT(40441) -- Peaks: Rebuild peaks for selected items // for some reason the peak file isn't created after source setting

-- Duplicate the glued copy of the source item as many times as the number of pitches to be created
local count = not step_reset and (range_end_shift - range_st_shift)/step -- OR (end_pitch - start_pitch)/step
or (range_end_shift - range_st_shift)/12*math.floor(11/step)+(range_end_shift - range_st_shift)/12 - 1 -- number of octaves * number of steps + number of octaves - 1 // number of octaves is added because it equals the number of C note instances not covered by step but present in each octave, less by 1 because first C note instance already exists being represented by the rendered take

	-- if item is going to be transposed downwards
	-- extend item it at its edges beyond the media source
	-- so that the waveform is preserved in its entirety
	-- after transposition, otherwise item current length
	-- may not suffice to accommodate it
local extended_st
	if root_oct > oct_st then -- OR root_idx > range_st_idx
	local item = r.GetSelectedMediaItem(0,0)
	local length = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	local Set = r.SetMediaItemInfo_Value
	Set(item, 'B_LOOPSRC', 0) --  disable looping so that after length extension other loop iterations don't emerge
	Set(item, 'D_LENGTH', length+0.3) -- length increase may be redundant if there's alteady silent tail, but just to be sure
	local take = r.GetActiveTake(item)
	r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', -0.3)
	extended_st = 1
	end

	for i = 1, count do -- fractional count is automatically rounded down
	ACT(41295) -- Item: Duplicate items
	end

local octave = oct_st -- start from octave indicated in the range entry
local prev_item_end

	-- Pitch shift, glue, rename items
	for i = 0, r.CountTrackMediaItems(tr)-1 do

	r.SelectAllMediaItems(0,false) -- selected false // unselect all items
	local item = r.GetTrackMediaItem(tr, i)
	r.SetMediaItemSelected(item, true) -- selected true // select current item
	local take = r.GetActiveTake(item)
	r.SetMediaItemTakeInfo_Value(take, 'D_PITCH', range_st_shift) -- pitch shift (transpose)
	ACT(40362) -- Item: Glue items, ignoring time selection // Glue transposition

		-- truncate after gluing because otherwise it's not precise enough
		if Truncate_Leading_And_Trailing_Silence(-60, 256, extended_st) -- threshold -60, block_size 256 samples // MOVED HERE INSTEAD OF TRUNCATING THE SOURCE TAKE BECAUSE DOWNWARD TRANSPOSITION AFFECTS WAVEFORM LENGTH, SO AFTER TRUNCATING THE SOURCE TAKE, THE MEDIA SOURCE AND ITEM LENGTH MAY END UP BEING INSUFFICIENT TO ACCOMMODATE INCREASE IN THE WAVEFORM LENGTH AND IT WILL BE CUT OFF SOME SAMPLES AHEAD OF TIME
		then
		-- get properties of item after transposition gluing to delete its source once truncation is glued
		local item = r.GetSelectedMediaItem(0,0)
		local take = r.GetActiveTake(item)
		local file = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(take), '') -- get media file created by the previous glue (transposition) before next glue while the take is valid
		ACT(40362) -- Item: Glue items, ignoring time selection // Glue silence truncation
		os.remove(r.GetPeakFileName(file, '')) -- delete peaks file // using function in case peak files are set to be stored in a separate directory // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
		os.remove(file)
		end

	local item = r.GetTrackMediaItem(tr, i) -- re-get item since it's changed after gluing
	local take = r.GetActiveTake(item) -- re-get take since it's changed after gluing
	local note = note_t[range_st_idx] -- get note name
	local retval, name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- setNewValue is false
	local name_new = name:match('^(.*_multi[%s%d]*_)')..note..tostring(math.floor(octave)) -- math.floor() removes decimal 0
	r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', name_new, true) -- modify item name to reflect the note; setNewValue true

	-- truncation of silent tails in items creates gaps between them
	-- which have to be closed by moving all items other than the very 1st one to the left
	local length = r.GetMediaItemInfo_Value(item, 'D_LENGTH')

		if not prev_item_end then
		prev_item_end = length
		else
		r.SetMediaItemInfo_Value(item, 'D_POSITION', prev_item_end)
		prev_item_end = prev_item_end + length -- incremenet for the next cycle
		end

	range_st_shift = range_st_shift + step -- in semitones relative to the root pitch; advance pitch shift value towards the range end for the next cycle

		if range_st_idx + step <= 12 then -- advance note index in the note_t table by step value for the next cycle // since note indices are 1-based, 12 is still within the current octave
		range_st_idx = range_st_idx + step
		else -- adjust index within octave and advance by 1 octave once the next octave is crossed over to
		range_st_idx = range_st_idx + step - 12
		octave = octave+1
			if step_reset then -- in step reset mode switch range_st_shift value to C note of next octave once next octave has been crossed over to with the step, thereby resetting the note the step is counted from
			range_st_shift = octave*12+1 - (root_idx+root_oct*12) -- calculate difference between 1-based index of C note of the next octave and the root note index // +1 to convert C index to 1-based
			range_st_idx = 1 -- reset to index of C note within octave
			end
		end

	end


	if start_pitch ~= root_pitch then -- remove the source file of the glued and renamed copy of the original item/take which was used to create range items and itself was transposed and glued in the loop above under the comment 'Pitch shift, glue, rename items', but only if the source item was transposed as well and hence glued
	os.remove(r.GetPeakFileName(new_fn, '')) -- remove lingering peak files with old file names if located at the same path as the source media // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
	local ok, message = os.remove(new_fn)
	end

-- scroll Arrange back to the project start after gaps between items have been removed,
-- they may end up being out of sight after duplication
-- because the edit cursor will follow them and move the view rightwards
r.SetEditCurPos(0, true, false) -- moveview true, seekplay false

local file_t = {}

	-- Rename source files after take names set in the previous loop
	for i = 0, r.CountTrackMediaItems(tr)-1 do
	r.SelectAllMediaItems(0,0) -- unselect all items
	local item = r.GetTrackMediaItem(tr, i)
	r.SetMediaItemSelected(item, true) -- select current item
	ACT(40440) -- Item: Set selected media temporarily offline
	local take = r.GetActiveTake(item)
	local retval, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', 0) -- setNewValue is 0
	local fn = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(take), '')
	local f_path, f_name, ext = fn:match('^(.+[\\/])([^\\/]-)(%.%w+)$') -- isolate file path, name and ext
	local new_fn = f_path..take_name..ext
	file_t[#file_t+1] = take_name..ext
	local ok, message = os.rename(fn, new_fn)
	local rem = #r.GetPeakFileName(fn, '') > 0 and os.remove(r.GetPeakFileName(fn, '')) -- remove lingering peak files with old file names; may leave lone non-deleted peak files if placed in the middle of the routine, could be because the source file is valid until renamed
	local new_src = r.PCM_Source_CreateFromFile(new_fn)
	r.SetMediaItemTake_Source(take, new_src) -- assign the renamed file as a source
	ACT(40439) -- Item: Set selected media online
	end


local err -- reset any preliminary error message before calling Create_Folder_Move_Files_Update_Take_Sources() which may also return an error message

	if want_folder then -- create multi-sample folder and move the source file there // MUST BE EXECUTED AFTER GLUING ALL MULTI-SAMPLE PITCHES, BECAUSE EVEN IF SOURCE FILE IS MOVED TO THE CREATED FOLDER, THE GLUED FILES (AS WELL AS RENDERED FILES FOR THAT MATTER) ARE STILL CREATED IN THE PROJECT MEDIA DIRECTOR; BUT BEFORE SFZ PATCH, TRACK TEMPLATE AND FX CHAIN PRESET CREATION SO THAT THEY'RE PLACED INSIDE THE NEW FOLDER
	f_path, err = Create_Folder_Move_Files_Update_Take_Sources(new_fn, file_t, tr) -- the return value will be used for creating sfz patch, track template and fxchain preset
	end

ACT(40047) -- Peaks: Build any missing peaks // the action only works outside of the loop

local shared_range = SHARED_RANGE:match('%S')

-- Concatenate SFZ code and export a patch --

	if SFZ:gsub(' ','') ~= '' then

		function calc_lo_hi_key(note, note_t, step, shared_range, want_lokey) -- only used when the step is greater than 1
		local note, oct = note:match('(.-)([%-%d]+)')
		local shift = step-1 -- distance between two closest notes is exactly step-1 semitones

			for k, v in ipairs(note_t) do
				if v == note then
				local note_idx
					if want_lokey then
					shift = shared_range and math.ceil(shift/2) or shift -- math.ceil to cover more notes when transposing down because in downward transposition sample duration isn't reduced
					note_idx = k - shift <= 0 and 12 + k - shift or k - shift -- 'k - shift <= 0' when the lower octave is crossed over to
					oct = k - shift <= 0 and oct - 1 or oct -- same condition
					elseif shared_range then -- hikey, which is only calculated for shared_range, otherwise it's the same as root
					shift = math.floor(shift/2) -- math.floor to cover less notes when transpoting down because in upward transposition sample duration is reduced
					note_idx = k + shift > 12 and k + shift - 12 or k + shift -- 'k + shift > 12' when the next octave is crossed over to
					oct = k + shift > 12 and oct + 1 or oct -- same condition
					end
				return note_t[note_idx]..tostring(math.floor(oct)) -- math.floor removes decimal 0
				end
			end
		end

	local step = tonumber(step) -- OR step+0
	local step_cond = step > 1

	local SFZ = {}

		-- first and last samples are always transposed down and up respectively
		-- to fill the remaning range below and above the multi-sample range

		for k, v in ipairs(file_t) do
		local note = v:match('.+_(.+)%.%w+$') -- get note name from file name

		local lokey = k > 1 and step_cond and ' lokey='..calc_lo_hi_key(note, note_t, step, shared_range, 1) -- want_lokey is true
		or k == 1 and ' lokey=C-1' -- when a note for lokey isn't found because there's no previous note, it defaults to C-1, i.e. 0 regardless of step value
		or '' -- when step_cond is false, i.e. step is 1, and it's not the first sample, key= opcode will be used instead

		-- when only downward transposition is performed because shared_range var is false
		-- hikey opcode is ommitted except for the last sample to fill the remaining upper range
		local hikey = shared_range and step_cond and k < #file_t and ' hikey='..calc_lo_hi_key(note, note_t, step, shared_range) -- want_lokey is false
		or k == #file_t and ' hikey=127' -- 127 = G9 but rgc:audio sfz player only recognizes note names up to F#9 and G9 causes the range to shrink up to the latest pitch_keycenter note
		or '' -- when step_cond is false, i.e. step is 1, and it's not the last sample, key= opcode will be used instead

		local sample = 'sample='..v
		local pitch_keycenter = (step_cond or k == 1 or k == #file_t) and 'pitch_keycenter='..note or 'key='..note -- different opcodes dependeing on whether transposition is required
		SFZ[#SFZ+1] = '<region> '..sample..lokey..hikey..' '..pitch_keycenter -- note names based on REAPER MIDI Editor middle C (i.e. C4, 60) are compatible with rgc:audio sfz player, sfizz and Zampler
		end

	local sfz_fn = file_t[1]:match('(.-)%.')..' - '..file_t[#file_t]:match('.+_(.-)%.')..'.sfz'
	local group = '// \'trigger\' opcode can be set to \'release\' instead which is equal to one shot, the sample plays all the way through after note-on message\n\n// To turn off effect opcodes either comment them out with double forward slash // or remove values after equal sign =\n\n<group>\n\ntrigger=attack\n\neffect1=100 //reverb %\n\neffect2=25 //chorus %\n\n'

	local f = io.open(f_path..sfz_fn, 'w') -- f_path is path of the source take media
	f:write(group..table.concat(SFZ,'\n\n'))
	f:close()

	end


local template, chain = RS5K_TRACK_TEMPLT:match('%S'), RS5K_FX_CHAIN:match('%S')

	if template or chain then
	local f_name = new_fn:match('.+[\\/](.+[%s%d]*_multi)') or new_fn:match('.+[\\/].+_multi[%s%d]*') -- either generic multi-sample name or custom // new_fn var contains full path
	local tr = Create_RS5k_Instrument(file_t, shared_range, f_path, tr, f_name)
	local create = template and Create_Track_Template(tr, f_name, f_path, want_itms, want_envs)
	local create = chain and Create_FX_Chain_Preset(tr, f_name, f_path, want_input)
	end

r.PreventUIRefresh(-1)
Scroll_Track_To_Top(tr) -- track with the multi-sample // scroll beyond PreventUIRefresh() because it prevents getting track initial Y coordinate to calculate scrolling amount
r.Undo_EndBlock('Create multisample out of selected item',-1)

	if err then r.MB(err, 'ERROR', 0) end -- error message stemming from Create_Folder_Move_Files_Update_Take_Sources()

