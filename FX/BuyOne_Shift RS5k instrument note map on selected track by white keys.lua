--[[
ReaScript name: BuyOne_Shift RS5k instrument note map on selected track by white keys.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 Fixed undo point creation when RS5k UI is open
	   v1.1 Fixed resetting FX selection to the 1st FX if the script is run with the FX chain closed
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M recommented, not mandatory
About:  The script only affects RS5k instances with drum note mapping, 
	i.e. Note range start = Note range end, that is 1 note per sample, 
	regardless of the 'Mode:' setting.
	
	While shifting it snaps note in each RS5k instance on selected track
	to natural (white) keys in case some are mapped to black keys.
	
	The shift value accepted from the user input is interpreted 
	as the number of white keys to shift by.
	
	If the track contains named notes the names will be shifted as well 
	along the Piano roll keyboard. This is the feature for which SWS/S&M 
	extension is recommended.  
	So if it happens to falter, first try installing the extension
	and if this fails to fix it contact the developer.

	The script is able to restore the original note map but only after
	it's been run at least once. The original map is the one it detects
	at the first run. After that if the RS5k instrument track is saved 
	with the project or as a track template the original map data
	will be retained in it and available for recall at a later time.
	
	!!! WARNING !!!
	
	Due to oddities of REAPER undo system 
	https://forum.cockos.com/showthread.php?t=281778
	if the track FX chain is closed the script needs to create two undo points, 
	one for RS5k instrument changes and another one for change in note names 
	association with Paino roll keys. That's provided the track of the RS5k 
	instrument does contain named notes displayed in the MIDI editor. If it 
	doesn't, a single undo point is created even if the track FX chain is closed.

]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
	if want_color then
	local color_init = r.GetThemeColor('col_tl_bg', 0)
	local color = color_init ~= 255 and 255 or 65535 -- use red or yellow of red is taken
		if want_blink then
		    for i = 1, 100 do
				if i == 1 or i == 40 or i == 80 then
				r.SetThemeColor('col_tl_bg', color, 0)
				elseif i == 20 or i == 60 or i == 100 then
				r.SetThemeColor('col_tl_bg', color_init, 0)
				end
				r.UpdateTimeline()
			end
		else
		r.SetThemeColor('col_tl_bg', color, 0) -- Timeline background
			for i = 1, 200 do -- ensures that the warning color sticks for some time
			-- without the function inside the loop the end (200) value must be much greater
			r.UpdateTimeline()
			end
		r.SetThemeColor('col_tl_bg', color_init, 0) -- Timeline background // restore the orig color
		r.UpdateTimeline() -- without this function the color will only be restored when user clicks within the Arrange
		end
	end
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
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


local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end


local tr = r.GetSelectedTrack(0,0)

local err = not tr and 'no selected tracks'
or r.CountSelectedTracks(0) > 1 and 'the script only supports \n\n     one selected track'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return r.defer(no_undo) end

local tr_fx_cnt = r.TrackFX_GetCount(tr)
local parm_names = {[2]='Gain for minimum velocity', [19]='Probability of hitting', [28]='Legacy voice re-use mode'} --  as of build 6.81
local instances_cnt = 0
local supported = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37 -- since this build FX_GetNamedConfigParm() can retrieve the original FX name, which obviates using chunk or parameter names to ascertain a particular fx

local rs5k = {}
	for fx_idx = 0, tr_fx_cnt-1 do
	local found = true	
		if supported then 
		local _, orig_name = r.TrackFX_GetNamedConfigParm(tr, fx_idx, 'fx_name') -- parmname could be 'original_name'
			if not orig_name:match('ReaSamplOmatic5000') then found = false end
		else
		local parm_cnt = r.TrackFX_GetNumParams(tr, fx_idx)
			if parm_cnt == 33 then -- RS5k parm count == 33 as of build 6.81
			-- NOT failproof because if at least 1 parameter has an alias, its name won't match
			-- currently the original name can only be verified via chunk
			-- feature request for doing this with FX_GetNamedConfigParm():
			-- https://forum.cockos.com/showthread.php?t=282037
				for parm_idx, name in pairs(parm_names) do
				local retval, parm_name = r.TrackFX_GetParamName(tr, fx_idx, parm_idx, '')
					if parm_name ~= name then found = false break end
				end
			end
		end
		if found then
		instances_cnt = instances_cnt+1
		local note_st, minval, maxval = r.TrackFX_GetParam(tr, fx_idx, 3) -- Note range start, parm index 3 as of build 6.81
		local note_end, minval, maxval = r.TrackFX_GetParam(tr, fx_idx, 4) -- Note range end, parm index 4 as of build 6.81
			if note_st == note_end then -- if drum style mapping, store
			rs5k[#rs5k+1] = {idx=fx_idx, note=note_st}
			end
		end		
	end

table.sort(rs5k, function(a,b) return a.note < b.note end) -- in case the RS5k instances aren't ordered in ascending order

local err = tr_fx_cnt == 0 and 'there\'re no plugins \n\n  on selected track'
or tr_fx_cnt > 0 and instances_cnt == 0 and 'there\'re no rs5k instances \n\n       on selected track. \n\n     Or they\'re all offline.'
or #rs5k == 0 and ' rs5k instances don\'t \n\n use drum note mapping'

	if err then Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return r.defer(no_undo) end

-- Store original note map
local orig_map = ''
	for k, data in ipairs(rs5k) do
	local space = k == 1 and '' or ' '
	orig_map = orig_map..space..data.idx..':'..data.note
	end

	if not r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map (drum style)', '', false) -- setNewValue false
	then
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map (drum style)', orig_map, true) -- setNewValue true // store orignal map to be able to restore by typing 0 in the dialogue
	end


function Offset_Shift_Value_To_Land_On_Natural_Keys(curr_val, shift_by_val)
-- returns actual MIDI note number, not the one used by RS5k 'Note range start/end' parameters

local unit = 1/127 -- normalized value used by Note range start/end parameters in the range of 0-1
local curr_val = math.floor(curr_val/unit + 0.5) -- convert to conventional 0-based note number to be able to use modulo below
local sign = shift_by_val < 0 and -1 or shift_by_val > 0 and 1 or 0
local natural_keys_cnt = 0
	for i = 1, 127 do -- shift original note number counting how many natural (white) keys have been passed along the way
	dest_val = curr_val+i*sign
		if dest_val == 0 or dest_val%12 == 0 or dest_val == 2 or dest_val%12 == 2 -- C or D
		or dest_val == 4 or dest_val%12 == 4 or dest_val == 5 or dest_val%12 == 5 -- E or F
		or dest_val == 7 or dest_val%12 == 7 or dest_val == 9 or dest_val%12 == 9 -- G or A
		or dest_val == 11 or dest_val%12 == 11 then -- B
		natural_keys_cnt = natural_keys_cnt+1*sign
		end
		if natural_keys_cnt == shift_by_val then return dest_val end -- return as soon as the number of counted white keys equals shift_by_val
	end

end

function Get_Orig_Note_Map(str)
local t = {}
	for fx_idx, note in str:gmatch('(%d+):([%d%.]+)') do
	t[#t+1] = {idx=fx_idx, note=note}
	end
return t
end

function Shift_Map(tr, t, ignore_bypassed)
	for idx, data in ipairs(t) do
	local rs5k_idx, note = data.idx, data.note
	-- make sure that the plugin about to be affected is indeed rs5k in case the order changed
	local retval, st_parm = r.TrackFX_GetParamName(tr, rs5k_idx, 3, '')
	local retval, end_parm = r.TrackFX_GetParamName(tr, rs5k_idx, 4, '')
	local rs5k = st_parm == 'Note range start' and end_parm == 'Note range end'
		if rs5k and (not ignore_bypassed or
		ignore_bypassed and r.TrackFX_GetParam(tr, data.idx, 30) == 0) -- Bypass parm, 0 unbupassed
		then
			for i = 3,4 do -- 3/4 - Note range start/end parameters
			r.TrackFX_SetParam(tr, tonumber(rs5k_idx), i, tonumber(note))
			end
		end
	end
end


function Shift_Note_Names(chunk, note_map_t)

local t, last_sel_idx, found = {}, 0
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match('<MIDINOTENAMES') then found = 1 end
		if found then t[#t+1] = line end
		if found and line:match('>') then found = nil end
		if line:match('LASTSEL') then last_sel_idx = line:match('%d+') break end -- extract the index of fx selected in fx chain so that if the chain is closed it could be opened with this fx visible to make REAPER register change in the undo history
	end

local old_note_map = table.concat(t,'\n')

local unit, new_note_map = 1/127

	if #old_note_map > 0 then
		for k, line in ipairs(t) do -- change note numbers in the MIDINOTENAMES block to update the chunk with it
			if k > 1 and k < #t then -- excluding MIDINOTENAMES block first and last lines
			local a, note1, c, d, note1 = line:match('(.-) (.-) ("?.+"?) (.-) (.-)') -- split line
			local note = math.floor(note_map_t[k-1].note/unit + 0.5) -- convert to conventional 0-based note number because the table will contain normalized value; k-1 to target corect field in note_map_t table because t starts with one 1 extra field with no note data
			t[k] = a..' '..note..' '..c..' '..d..' '..note
			end
		end
	new_note_map = table.concat(t,'\n')
	end

return old_note_map, new_note_map, last_sel_idx

end


function MAIN(tr, rs5k, shift_by_val, ignore_bypassed)

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local ret, chunk = GetObjChunk(tr)
	if ret then
	old_map, new_map, last_sel_idx = Shift_Note_Names(chunk, rs5k) -- must be run here to extract last_sel_idx in order to open fx chain below at the last selected fx for consistency and better UX
	end

-- Due to REAPER bug https://forum.cockos.com/showthread.php?t=281778
-- undo point for all RS5k instances is only created with open FX chain window
local chain_vis = r.TrackFX_GetChainVisible(tr) ~= -1
local last_sel_fx_floats = r.TrackFX_GetFloatingWindow(tr, last_sel_idx) -- if last selected fx window floats while the fx chain is closed, after toggling open-close the fx chain below the floating window will be closed because the function will use its index to keep it selected in the chain, so find if it floats to re-float it after toggling the fx chain open-close
local open = not chain_vis and r.TrackFX_SetOpen(tr, last_sel_idx or rs5k[1].idx, not chain_vis) -- open if closed, open arg is not chain_vis; fx index alternative in case last_sel_idx is invalid because the chunk size exceeds 4096 kb and the SWS extension isn't installed to help retrieve it

Shift_Map(tr, rs5k, ignore_bypassed)

local clse = not chain_vis and r.TrackFX_SetOpen(tr, last_sel_idx or rs5k[1].idx, chain_vis) -- close fx chain if was closed originally, open arg is chain_vis; fx index alternative in case last_sel_idx is invalid because the chunk size exceeds 4096 kb and the SWS extension isn't installed to help retrieve it
local re_float = not chain_vis and last_sel_fx_floats and r.TrackFX_Show(tr, last_sel_idx, 3) -- 3 show in a floating window

local undo = shift_by_val ~= 0 and 'Shift RS5k instrument note map by '..shift_by_val..' white keys' or 'Restore original RS5K instrument map'

	if not chain_vis then -- only create two undo points if FX chain is closed
	r.Undo_EndBlock('1. '..undo, 2) -- even with open FX chain for changes in RS5k an undo point is only created with flag 2 (UNDO_STATE_FX), with flag -1 it's only created once
	end
r.PreventUIRefresh(-1)

local ret, chunk = GetObjChunk(tr) -- retrieve the chunk again with the new data after note map shift with Shift_Map() above to apply note names shift to it below

	if ret and #old_map > 0 then -- if track chunk was retrieved and note map was found in it
	local old_map = Esc(old_map)
	local new_map = new_map:gsub('%%','%%%%') -- escape just in case otherwise gsub below won't work
	local new_chunk = chunk:gsub(old_map, new_map)
	SetObjChunk(tr, new_chunk)
		if not chain_vis then -- only create two undo points if FX chain is closed
		r.Undo_OnStateChangeEx('2. Shift RS5K instrument note names', -1, -1) -- whichStates arg (the 2nd) can be 1 and -1
		end
	local ME = r.MIDIEditor_GetActive()
		if ME then -- when 'View: Hide unused and unnamed note rows' toggle state is On, shifting note names reveals unamed notes and conceals named ones, so restore visibility of only named notes by running the action even though its toggle state is already On, not clear if it was designed this way or a happenstance; the toggle state of this action and 3 other's, 'View: Hide unused note rows', 'View: Show all notes' and 'View: Show custom note row view' are mutually exclusive
		local take_tr = r.GetMediaItemTake_Track(r.MIDIEditor_GetTake(ME))
			if take_tr == tr and r.GetToggleCommandStateEx(32060, 40454) == 1 -- View: Hide unused and unnamed note rows
			then
			r.MIDIEditor_LastFocused_OnCommand(40454, false) -- islistviewcommand false
			end
		end
	end
	
	if chain_vis then -- create single undo point if FX chain is open
	r.Undo_EndBlock(undo, 2) -- even with open FX chain for changes in RS5k an undo point is only created with flag 2 (UNDO_STATE_FX), with flag -1 it's only created once
	end

end


::RETRY::
retval, output = r.GetUserInputs('Shift By (count white keys, 0 to restore original map)', 2, 'Prefix negative with —,Ignore bypassed (type any char),extrawidth=100', output or '')
	if not retval or output:gsub(' ','') == ',' then return r.defer(no_undo) end

local shift_by_val, ignore_bypassed = output:match('(.-),(.*)')

local err = #shift_by_val:gsub(' ','') == 0 and 'no value has been specified' or #shift_by_val:gsub(' ','') > 0 and not tonumber(shift_by_val) and 'not a numeric value'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
		goto RETRY
		end

ignore_bypassed = #ignore_bypassed:gsub(' ','') > 0

	if ignore_bypassed then
	local active_cnt = 0
		for _, data in ipairs(rs5k) do
			if r.TrackFX_GetParam(tr, data.idx, 30) == 0 -- Bypass parm, 0 unbupassed
			then
			active_cnt = active_cnt+1
			end
		end
		if active_cnt == 0 then
		Error_Tooltip('\n\n no active rs5k instances \n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo) end
	end


shift_by_val = tonumber(shift_by_val)

	if shift_by_val == 0 then
	local resp = r.MB('Restore the original map?','PROMPT', 4)
		if resp == 6 then -- Yes
		local ret, orig_map = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map (drum style)', '', false) -- setNewValue false
			if not ret then Error_Tooltip('\n\n  the original map \n\n data wasn\'t found \n\n', 1,1) -- caps, spaced are true
			return r.defer(no_undo)
			else
			local rs5k = Get_Orig_Note_Map(orig_map)
			MAIN(tr, rs5k, shift_by_val, ignore_bypassed)
			return
			end
		else return r.defer(no_undo)
		end
	end


local unit = 1/127

	for k, data in ipairs(rs5k) do -- store shifted note numbers
	local note = Offset_Shift_Value_To_Land_On_Natural_Keys(data.note, shift_by_val)
		if note < 0 or note > 127 then
		Error_Tooltip('\n\n   cannot shift. \n\n note range limit \n\n has been reached.\n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo)
		end
	rs5k[k].note = note*unit -- store new value normalized
	end


MAIN(tr, rs5k, shift_by_val, ignore_bypassed)




