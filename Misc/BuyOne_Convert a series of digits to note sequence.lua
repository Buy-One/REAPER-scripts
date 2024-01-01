--[[
ReaScript name: BuyOne_Convert a series of digits to note sequence.lua
Author: BuyOne
Version: 1.0
Changelog: #Initial release
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v5.962  		
About: 	The initial idea proposed by a user on REAPER sub-reddit 
	was to convert phone numbers to melodies to be used as 
	a ringtone to identify the caller.  
	
	But besides phone numbers convertion the script can be 
	used as a general purpose creative tool because the number 
	of digits which can be processed isn't limited. Any random
	sequence of digits will do.
	
	The digits supplied by the user represent scale degrees, 
	namely: 1 - tonic, 2 - supertonic, 3 - mediant, 4 - subdominant,
	5 - dominant, 6 - submediant, 7 - subtonic / leading tone, 
	8 - octave, 9 - supertonic 1 octave higher, 3 - mediant 1 octave higher.

	https://en.wikipedia.org/wiki/Degree_(music)#Scale_degree_names		
	
	The tonic is determined by the first digit and is relative 
	to the middle C, where if the first digit is 1 the tonic is 
	middle C itself, otherwise it's a degree from the middle C.
	This means that the tonic will always be a natural note, 
	which is a limitation but which can be cured by transposing
	the sequence manually after the fact.
	
	Digits from the 2nd onwards represent scale degrees from 
	the tonic. Thus the resulting note sequence mostly does make 
	musical sense.

	Forcing it to make rhythmical sense is more challenging.
	By default digits are converted into 8th notes. 'r' or 'R' 
	modifier allows randomization of note lengths. Currently in 
	random mode 4th, 8th, 16th notes and their dotted versions 
	are supported. Still the melodic sequence itself may give 
	an idea how it could sound best rhythmically.
	
	Other available modifiers are:
	'-' (minus) - to create descending sequence meaning that the 
	degrees will be calculated from the tonic lowered by 1 octave 
	while keeping the original octave of the tonic itself;
	'm' or 'M' - to create sequence in minor scale;
	'p' or 'P' - to add random rests between notes, whose duration 
	when the 'r/R' modifier isn't used defaults to 8th note, 
	otherwise it's randomly selected out of 8th, 16th and their
	dotted versions.
	
	The order in which the modifiers are added before the digit
	series is immaterial. Spaces in the input field are ignored.
	
	The script can be imported into and run from both Main 
	and MIDI Editor sections of the Action list. Before running 
	from the Main section select an empty MIDI item to be 
	populated with notes. If no item is selected, one will 
	be created automatically at the edit cursor on the first 
	selected track and if none is selected - on the last touched 
	one and the track list will be scrolled to it if it's not 
	within view.
	
	If selected MIDI item already contains notes, these will 
	be deleted if user assents to the prompt.
	
	The MIDI item length is adjusted to fit the length of the note
	sequence.
	
	The user input is reflected in the undo points created by
	the script.

]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Delete_Notes(take, chan, want_active_ch)
-- only deletes notes in the active MIDI channel when channel filter is enabled
-- otherwise in all channels
-- chan is integer, 0-15, to only delete notes in particular channel
-- want_active_ch is boolean to only delete notes in the channel currently selected in the channel filter
-- if both chan and want_active_ch are valid, chan has proirity
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
local ME = r.MIDIEditor_GetActive()
local def_chan = want_active_ch and r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- channel selected in the channel filter regardless of the filter being enabled, Omni is 0, same as channel 1
local ch = chan or want_active_ch

	for i=notecnt-1,0,-1 do -- in reverse due to deletion
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
		if ch and chan == ch -- delete from specific channel
		or not ch then -- delete from all channels
		r.MIDI_DeleteNote(take, i)
		end
	end

end


function Get_Default_MIDI_Chan(take, cmdID)
-- the one selected in the channel filter regardless of its being enabled
-- 'All channels' option defaults to channel 1
r.PreventUIRefresh(1)
	if cmdID ~= 32060 then -- script isn't run from the MIDI Editor section // open MIDI Editor
	r.Main_OnCommand(40153,0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
	end
local chan = r.MIDIEditor_GetSetting_int(r.MIDIEditor_GetActive(), 'default_note_chan')
	if cmdID ~= 32060 then -- script isn't run from the MIDI Editor section // close MIDI editor
	r.MIDIEditor_LastFocused_OnCommand(2, false) -- islistviewcommand false // File: Close window
	end
r.PreventUIRefresh(-1)
return chan
end


function Time_Sel_Or_Loop_Exist(want_loop)
local want_loop = want_loop or false -- isLoop arg doesn't accept nil
local start, fin = r.GetSet_LoopTimeRange(false, want_loop, 0, 0, false) -- isSet, allowautoseek false
return start ~= fin
end


function Music_Div_To_Sec(val)
-- val is either integer (whole bars/notes) or quotient of a fraction x/x, i.e. 1/2, 1/3, 1/4, 2/6 etc
	if not val or val == 0 then return end
return 60/r.Master_GetTempo()*4*val -- multiply crotchet's length by 4 to get full bar length and then multiply the result by the note division
end

function Randomize_Array(t)
	for k, v in ipairs(t) do
	local r = math.random(1, #t)
	t[r], t[k] = t[k], t[r]
	end
end


function Force_MIDI_Undo_Point(take)
-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points, therefore Undo_Begin/EndBlock() functions must stay
-- https://forum.cockos.com/showpost.php?p=1925555
local item = take and r.GetMediaItemTake_Item(take) or r.GetMediaItemTake_Item(r.MIDIEditor_GetTake(r.MIDIEditor_GetActive()))
local is_item_sel = r.IsMediaItemSelected(item)
r.SetMediaItemSelected(item, not is_item_sel)
r.SetMediaItemSelected(item, is_item_sel)
end


local maj_degrees = {['1']=0,['2']=2,['3']=4,['4']=5,['5']=7,['6']=9,['7']=11,['8']=12,['9']=14,['0']=16} -- values are semintones from the tonic, the degree 0 (table key 1) means the tonic itself, thus in determining the tonic if the 1st digit is 0 the tonic will be the middle C
local min_degrees = {['1']=0,['2']=2,['3']=3,['4']=4,['5']=7,['6']=8,['7']=10,['8']=12,['9']=14,['0']=15} -- values are semintones from the tonic, same


local is_new_value,filename,sectID,cmdID,mode,resol,val = r.get_action_context()

local sel_item = r.GetSelectedMediaItem(0,0)
local take = sel_item and r.GetActiveTake(sel_item)
local delete

	if sectID >= 0 and sectID <= 16 or sectID == 100 then
	-- the script is run from the Main section of the action list
	-- accounting for REAPER 7 Main alt sections and Rec alt section
		if sel_item and not take or take and not r.TakeIsMIDI(take) then
		Error_Tooltip('\n\n the active take isn\'t midi \n\n',1,1) -- caps, spaced true
		return r.defer(no_undo) end
	end

-- the script is run either from the Main and Main-alt section of the Action list
-- or from the MIDI Editor section
take = (sectID >= 0 and sectID <= 16 or sectID == 100) and take
or sectID == 32060 and r.MIDIEditor_GetTake(r.MIDIEditor_GetActive())

	if take then
	local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
		if notecnt > 0 then
		local resp = r.MB('     The item contains MIDI notes'
		..'\n\n'..(' '):rep(10)..'which all will be deleted', 'WARNING', 1)
			if resp == 2 then -- cancelled
			return r.defer(no_undo) end
		delete = true
		end
	end


local named_cmdID = r.ReverseNamedCommandLookup(cmdID):gsub('7d3c_','') -- strip off the MIDI Editor identifier so that the buffer is shared between Main and MIDI Editor sections


::RETRY::

local autofill = r.GetExtState(named_cmdID, 'autofill')
local comment = '- descending sequence, m/M - minor scale, r/R - random note length, p/P - rest'

local ret, output = r.GetUserInputs('Digits to notes (optionally prefix digits with modifiers)', 2, 'Input a series of digits,(supported modifiers legend):,extrawidth=310,separator=:', autofill..':'..comment)

output = ret and output:match('(.+):') -- exclude comment, if ret is false only the 1st field is returned out of several

	if not ret or output and #output:gsub(' ','') == 0 or not output then -- not output when ret is true and the input field is empty
		if output and not tonumber(output:lower():match('[mrp%-]*(.+)')) then -- besides modifiers the input field doesn't contain digits
		r.DeleteExtState(named_cmdID, 'autofill', true) -- persist true // delete invalid input from buffer
		end
	return r.defer(no_undo) end

r.SetExtState(named_cmdID, 'autofill', output, false) -- persist false // store output for autofilling the dialogue on the next load

local output = output:gsub(' ',''):lower() -- remove spaces	and convert to lower register
local descend = output:match('[%-]+')
local minor = output:match('[m]+')
local rand_len = output:match('[r]+')
local rest = output:match('[p]+')
local digits = output:match('[mrp%-]*(.+)')

	if not tonumber(digits) then
	Error_Tooltip('\n\n\t\tinvalid input.\n\n   besides modifier prefixes '
	..'\n\n   only digits are supported. \n\n',1,1) -- caps, spaced true
	goto RETRY
	end

r.Undo_BeginBlock()

	if (sectID >= 0 and sectID <= 16 or sectID == 100) then
	-- the script is run from the Main section of the action list
	-- accounting for REAPER 7 Main alt sections and Rec alt section
	local ACT = r.Main_OnCommand
		if not take then -- insert new MIDI item
		local cur_pos = r.GetCursorPosition()
		r.PreventUIRefresh(1)
		ACT(40214,0) -- Insert new MIDI item... (inserted at mouse cursor 1 bar long and becomes the only one selected, if there's time selection, inserted within time selection and fills it, but this is fixed below)
		sel_item = r.GetSelectedMediaItem(0,0)
			if Time_Sel_Or_Loop_Exist(want_loop) then -- want_loop false
			r.SetEditCurPos(cur_pos, true, false) -- moveview true, seekplay false
			r.SetMediaItemInfo_Value(sel_item, 'D_POSITION', cur_pos) -- set start to orig cursor position
			r.SetMediaItemInfo_Value(sel_item, 'D_LENGTH', Music_Div_To_Sec(1)) -- set length to 1 bar
			end
		take = r.GetActiveTake(sel_item)
		end
	ACT(40297,0) -- Track: Unselect (clear selection of) all tracks
	local itm_tr = r.GetMediaItemTrack(sel_item)
	r.SetTrackSelected(itm_tr, true) -- selected true
	ACT(40913,0) -- Track: Vertical scroll selected tracks into view
	r.PreventUIRefresh(-1)
	end


local digits_t = {}

	for digit in digits:gmatch('%d') do
	digits_t[#digits_t+1] = digit
	end

local tonic = (minor and min_degrees[digits_t[1]] or maj_degrees[digits_t[1]]) + 60 -- adding the degree corresponding to the 1st digit to 60 which is the middle C

local quaver_sec = Music_Div_To_Sec(1/8) -- default note length is 1/8th
local take_start = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')

	if rand_len then
	math.randomseed(math.floor(r.time_precise()*1000)) -- math.floor() because the seeding number must be integer; seems to facilitate greater randomization at fast rate thanks to milliseconds count, not necessary in this script though
	end

local note_dur = {1/4,3/8,1/8,3/16,1/16,3/32} -- each straight is followed by dotted
Randomize_Array(note_dur)

local rest_dur = rest and {0, rand_len and Music_Div_To_Sec(Randomize_Array({1/8,3/16,1/16,3/32})) or quaver_sec} -- when no randomize modifier the rest is either 0 or 8th note, otherwise either 0 or one of 4 notes

	for k, digit in ipairs(digits_t) do -- collect future notes properties
	local pitch = k == 1 and tonic -- keep the tonic which is represented by the 1st digit
	or tonic + (minor and min_degrees[digit] or maj_degrees[digit]) - (descend and 12 or 0) -- if descend modifier, subtract 12 to lower the octave
	local start_ppq = r.MIDI_GetPPQPosFromProjTime(take, take_start)
	local note = rand_len and note_dur[math.random(1,#note_dur)]
	local note_len_sec = note and Music_Div_To_Sec(note) or quaver_sec
	local end_ppq = r.MIDI_GetPPQPosFromProjTime(take, take_start+note_len_sec) -- take_start val is carried over from prev loop cycle
	digits_t[k] = {pitch=pitch, start=start_ppq, fin=end_ppq}
	local rest = rest and k < # digits_t and rest_dur[math.random(1,#rest_dur)] or 0 -- only adding rest in cycles other than the last to prevent unnecesarily increasing take_start val by adding rest after the last note because it'll be used to adjust item length
	take_start = take_start+note_len_sec + rest -- increment each next note start by the duration of the note adding random rest, will be used in the next cycle
	end

	if delete then Delete_Notes(take) end -- delete notes existing in the selected item

local chan = Get_Default_MIDI_Chan(take, cmdID)

	for k, note in ipairs(digits_t) do
	r.MIDI_InsertNote(take, false, false, note.start, note.fin, chan, note.pitch, 127, true) -- selected, muted false, chan -1 (Omni?), vel 127, noSortIn true
	end

r.MIDI_Sort(take)

local item = sel_item or r.GetMediaItemTake_Item(take) -- accounting for item open in the MIDI Editor without being selected
local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')

	if r.GetMediaItemInfo_Value(item, 'D_LENGTH') ~= take_start - item_start then -- extend/trim item if note sequence exceeds/falss short of its original length
	local is_looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1
	local loop_off = is_looped and r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 0) -- disable loop
	r.SetMediaItemInfo_Value(item, 'D_LENGTH', take_start - item_start)
	local loop_on = is_looped and r.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 1) -- re-enable loop
	end

	if sectID == 32060 then -- only if the script is run from the MIDI Editor section of the action list
	Force_MIDI_Undo_Point(take)
	end

r.UpdateItemInProject(item) -- required when the script is run from the Main section and selected MIDI item is used
-- OR
-- r.UpdateTimeline()
-- OR
-- r.UpdateArrange()

r.Undo_EndBlock('Convert a series of digits ('..output..')  to note sequence',-1) -- the only problem is that when notes are inserted in Arrange into an existing item for some reason not the latest but the penultimate undo point is listed in the Undo point readout of the main menu; nothing which was tried to cure this worked









