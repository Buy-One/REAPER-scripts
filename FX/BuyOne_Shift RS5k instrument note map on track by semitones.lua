--[[
ReaScript name: BuyOne_Shift RS5k instrument note map on track by semitones.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.7
Changelog:
	   v1.7 #Added lacking argument to the CopyFX function
	   v1.6 #Fixed note map restoration error when the track doesn't have named notes
		#Updated track note map storage mechanism so that the stored data are unique to each track
		#Updated undo point creation logic to make the note map data stored inside the track less
		susceptible to undo
		#Made track selection unnecessary if the script is run from the MIDI Editor section
		of the Action list
		#Changed the script name to reflect that
		#Updated the 'About' text
	   v1.5 #The mechanism of note map storage for restoration later has been made more reliable
	   v1.4 #Re-designed note names management mechanism to be more robust
		#Updated undo point creation mechanism to dispose of double undo points
		in closed FX chain scenario in REAPER builds older than 7.01
		#Added an option to store current note map as default for use in its restoration later
	   v1.3 #Undo point creation mechanism has been updated to work properly in builds newer than 7.001
	   v1.2 #Fixed undo point creation when RS5k UI is open
	   v1.1 #Fixed resetting FX selection to the 1st FX if the script is run with the FX chain closed
Licence: WTFPL
REAPER: at least v5.962, for best performance 7.01 is recommended
Extensions: SWS/S&M recommented, not mandatory
About:  If the track contains named notes associated with RS5k instances
	the names will be shifted as well along the Piano roll keyboard. 
	Any note names unrelated to the RS5k instrument notes which happen 
	to stand in the way of the related notes at the moment of shifting 
	will be deleted. Which is something to be aware of when choosing 
	the option to ignore bypassed RS5k instances because notes names
	associated with them will also be ignored.  
	Note names shifting is the feature for which SWS/S&M extension 
	is recommended.  So if it happens to faulter, first try installing 
	the extension and if this fails to fix it contact the developer.
	
	If the script is run from the MIDI Editor section of the action list
	it automatically targets the RS5k instrument of the track the 
	currently open MIDI item belongs to.  
	If it's run from the Main section of the action list it targets
	the first selected track.
	
	The script is able to restore the original note map but only after
	it's been run at least once. The original map is the one it detects
	at the very first run. After that if the RS5k instrument track is saved 
	with the project or as a track template the original map data
	will be retained in it and available for recall at a later time.  
	The script is also able to store current note map as default instead
	of the originally stored note map.
		
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


function Validate_FX_Identity(obj, fx_idx, fx_name, parm_t)
-- the function is based on Get_FX_Parm_Orig_Name() above
-- in case it's been aliased by the user
-- obj is track or take
--, fx_name is the original name of the plugin being validated
-- parm_t is a table indexed by param indices whose fields hold corresponding original param names
-- e.g. {[4] = 'parm name 4', [12] = 'parm name 12', [23] = 'parm name 23'}
-- works with builds 6.37+
-- relies on Esc() function
local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetFXName, GetConfig, CopyFX =
table.unpack(tr and {r.TrackFX_GetFXName, r.TrackFX_GetNamedConfigParm, r.TrackFX_CopyToTrack}
or take and {r.TakeFX_GetFXName, r.TakeFX_GetNamedConfigParm, r.TakeFX_CopyToTrack} or {})
-- get name displayed in fx chain
local retval, fx_chain_name = GetFXName(obj, fx_idx, '')
	if fx_chain_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix

-- if fx chain displayed name doesn't match the user supplied name, meaning was renamed
-- get fx browser displayed name in builds which support this option

local build_6_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37

local orig_fx_name

	if build_6_37 then
	retval, orig_fx_name = GetConfig(obj, fx_idx, 'original_name') -- or 'fx_name' // returned with fx type prefix
		if orig_fx_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix
	end

-- if validation by the original name failed or wasn't supported
-- validate using parameter names

-- add temp track and copy the fx instance to it
r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
-- search for the name of fx parameter at the same index as the one being evaluated, in the copy of the fx
-- on the temp track
CopyFX(obj, fx_idx, temp_track, 0, false) -- is_move false
local name_match = true
	for i = 0, r.TrackFX_GetNumParams(temp_track, 0)-1 do -- fx_idx 0
	local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, i, '') -- fx_idx 0
		if parm_t[i] and parm_t[i] ~= parm_name then
		-- break rather than return to allow deletion of the temp track
		-- before returning the value
		name_match = false break
		end
	end

-- if name_match ends up being false there's possibility that the parameters have been aliased
-- in which case collate parm names in the clean instance of the fx loaded from the fx browser in builds 6.37+
	if build_6_37 then
	-- delete fx instance copied in the previous routine to the temp track
	r.TrackFX_Delete(temp_track, 0)
	-- use fx name displayed in fx browser
	-- to insert FX instance on the temp track
	-- the fx names retrieved with GetNamedConfigParm() always contain fx type prefix,
	-- the function FX_AddByName() supports fx type prefixing but in the retrieved fx name 
	-- the fx type prefix is followed by space which wasn't allowed in FX_AddByName()
	-- before build 7.06 so it must be removed, otherwise the function will fail
	-- https://forum.cockos.com/showthread.php?t=285430	
	orig_fx_name = orig_fx_name:gsub(' ','',1) -- 1 is index of the 1st space in the string	
	r.TrackFX_AddByName(temp_track, orig_fx_name, 0, -1000) -- insert // recFX 0 = false, instantiate at index 0
	name_match = true
		for i = 0, r.TrackFX_GetNumParams(temp_track, 0)-1 do -- fx_idx 0
		local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, i, '') -- fx_idx 0
			if parm_t[i] and parm_t[i] ~= parm_name then
			-- break rather than return to allow deletion of the temp track 
			-- before returning the value
			name_match = false break
			end
		end
	end

r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)

return name_match

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


function Get_Track_MIDI_Note_Names(tr)
local note_names = '<MIDINOTENAMES'
	for note_idx = 0, 127 do -- note range
		for chan_idx = -1, 15 do -- MIDI channel range, -1 is omni
		local name = r.GetTrackMIDINoteNameEx(0, tr, note_idx, chan_idx)
			if name then
			-- enclose inside quotes if contains spaces as per REAPER format
			name = name:match(' ') and '"'..name..'"' or name
			-- concatenate <MIDINOTENAMES block line
			note_names = note_names..'\n'..chan_idx..' '..note_idx..' '..name..' 0 '..note_idx
			-- if name is found under onmi MIDI channel it will also be returned for all 16 channel
			-- so no point in continuing because this is not how the code looks in the track chunk
				if chan_idx == -1 then break end
			end
		end
	end
return note_names ~= '<MIDINOTENAMES' and note_names..'\n>' -- if longer than the 1st line
end


function Update_Stored_Data(tr, tr_GUID, key)
local global_ext_state = r.GetExtState(tr_GUID, key)
local ret, track_ext_state = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..key, '', false) -- setNewValue false
	if #global_ext_state > 0 then -- store inside the track if the data are present in the global extended state, to keep the data inside the track up-to-date as it's affected by undo and could be reverted to the previous state
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..key, global_ext_state, true) -- setNewValue true
	elseif ret and #track_ext_state > 0 then -- if the data don't happen to be present in the global extended state while being present in the track extended state, copy to the global one
	r.SetExtState(tr_GUID, key, track_ext_state, false) -- persist false
	end
end


local _, scr_name, scr_sect_ID, cmd_ID, _,_,_ = r.get_action_context()

local tr = scr_sect_ID == 32060 and r.GetMediaItemTake_Track(r.MIDIEditor_GetTake(r.MIDIEditor_GetActive()))
or r.GetSelectedTrack(0,0)

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
		if supported then -- this option is also used inside Validate_FX_Identity()
		local _, orig_name = r.TrackFX_GetNamedConfigParm(tr, fx_idx, 'fx_name') -- parmname could be 'original_name'
			if not orig_name:match('ReaSamplOmatic5000') then found = false end
		else
			for parm_idx, name in pairs(parm_names) do
				if not Validate_FX_Identity(obj, fx_idx, 'ReaSamplOmatic5000', parm_t) then found = false break end -- NEW
			end
		end
		if found then
		instances_cnt = instances_cnt+1
		local note_st, minval, maxval = r.TrackFX_GetParam(tr, fx_idx, 3) -- Note range start, parm index 3 as of build 6.81
		local note_end, minval, maxval = r.TrackFX_GetParam(tr, fx_idx, 4) -- Note range end, parm index 4 as of build 6.81
		rs5k[#rs5k+1] = {idx=fx_idx, start=note_st, fin=note_end}
		end
	end

table.sort(rs5k, function(a,b) return a.start < b.start end) -- in case the RS5k instances aren't ordered in ascending order

local err = tr_fx_cnt == 0 and 'there\'re no plugins \n\n  on selected track'
or tr_fx_cnt > 0 and instances_cnt == 0 and 'there\'re no rs5k instances \n\n       on selected track. \n\n     Or they\'re all offline.'

	if err then Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return r.defer(no_undo) end

-- Store original note map
local orig_map = ''
	for k, data in ipairs(rs5k) do
	local space = k == 1 and '' or ' '
	orig_map = orig_map..space..data.idx..':'..data.start..':'..data.fin
	end
	

-- note map storage must be based on track GUID so that it's stored for each track indivudually
local ret, tr_GUID = r.GetSetMediaTrackInfo_String(tr, 'GUID', '', false) -- setNewValue false

-- Store note data for future restoration
local STORED -- to condition error message if user happen to choose to store the same note map just stored, only relevant for the 1st ever script run which is exremely unlikely
local ret, stored_map = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map', '', false)-- setNewValue false
	
	if not ret or #stored_map == 0 then -- if there're no stored data in the track chunk, store
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map', orig_map, true) -- setNewValue true // store note map to be able to restore by typing 0 in the dialogue
	r.SetExtState(tr_GUID, 'RS5k instrument note map', orig_map, false) -- persist false
	STORED = 1
	local ret, stored_names = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note names', '', false)-- setNewValue false
		if not ret or #stored_names == 0 then
		local orig_note_names = Get_Track_MIDI_Note_Names(tr)
			if orig_note_names then
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note names', orig_note_names, true) -- setNewValue true // store note names to be able to restore by typing 0 in the dialogue
			r.SetExtState(tr_GUID, 'RS5k instrument note names', orig_note_names, false) -- persist false
			end
		end
	else -- if there're data in the track chunk

	Update_Stored_Data(tr, tr_GUID, 'RS5k instrument note map')
	Update_Stored_Data(tr, tr_GUID, 'RS5k instrument note names')
	
	end


function Get_Orig_Note_Map(str)
local t = {}
	for fx_idx, note_st, note_end in str:gmatch('(%d+):([%d%.]+):([%d%.]+)') do
	t[#t+1] = {idx=fx_idx, start=note_st, fin=note_end}
	end
return t
end


function Get_Orig_Note_Data(tr, note_map_t, ignore_bypassed) -- get numbers of notes associated with note names
-- note_map_t is rs5k table or the one returned by Get_Orig_Note_Map()
-- if user chose to restore the original map
-- the function supports note ranges, i.e. when RS5k note start and note end params aren't the same
local unit = 1/127
local t = {} -- to be used in note names shifting
	for k, data in ipairs(note_map_t) do
		if not ignore_bypassed
		or ignore_bypassed and r.TrackFX_GetParam(tr, data.idx, 30) == 0 -- Bypass parm, 0 unbupassed
		then
		local start, fin = math.floor(data.start/unit + 0.5), math.floor(data.fin/unit + 0.5) -- convert to regular numbers
			for i = start, fin do -- i represents note numbers // loop to account for all notes in the range in case note start and note end values in RS5k differ
			local note_name = r.GetTrackMIDINoteNameEx(0, tr, i, -1) -- chan -1 omni which is always the case when notes are named manually in the MIDI Editor // if no assigned note name returns nil // the function is more convenient than without Ex thanks to using track pointer rather than its index
				if note_name then -- store note number
				t[#t+1] = i
				end
			end
		end
	end
return t
end


function Shift_Map(tr, t, ignore_bypassed)
	for idx, data in ipairs(t) do
	local rs5k_idx, note_st, note_end = data.idx, data.start, data.fin
	-- make sure that the plugin about to be affected is indeed rs5k in case the order changed
	local retval, st_parm = r.TrackFX_GetParamName(tr, rs5k_idx, 3, '')
	local retval, end_parm = r.TrackFX_GetParamName(tr, rs5k_idx, 4, '')
	local rs5k = st_parm == 'Note range start' and end_parm == 'Note range end'
		if rs5k and (not ignore_bypassed or
		ignore_bypassed and r.TrackFX_GetParam(tr, data.idx, 30) == 0) -- Bypass parm, 0 unbupassed
		then
		r.TrackFX_SetParam(tr, tonumber(rs5k_idx), 3, tonumber(note_st)) -- parm 3, Note range start
		r.TrackFX_SetParam(tr, tonumber(rs5k_idx), 4, tonumber(note_end)) -- parm 4, Note range end
		end
	end
end



function Shift_Note_Names(chunk, orig_note_data, shift_by_val)
-- orig_note_data table stems from Get_Orig_Note_Data()
-- shift_by_val is the user supplied value via the dialogue

-- could be done with a function r.SetTrackMIDINoteName(tr, pitch, chan, name)
-- channel < 0 assigns note name to all channels. pitch 128 assigns name for CC0, pitch 129 for CC1, etc.
-- BUT it would require deleting the old then assigning the new

local t, last_sel_idx, found = {}, 0
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match('<MIDINOTENAMES') then found = 1 end
		if found then t[#t+1] = line end
		if found and line:match('>') then found = nil end
		if line:match('LASTSEL') then last_sel_idx = line:match('%d+') break end -- extract the index of fx selected in fx chain so that if the chain is closed it could be opened with this fx visible to make REAPER register change in the undo history
	end

local old_note_map = table.concat(t,'\n')

local new_note_map, note

	if #old_note_map > 0 then
		for k, line in ipairs(t) do -- change note numbers in the MIDINOTENAMES block to update the chunk with it
			if k > 1 and k < #t then -- excluding <MIDINOTENAMES block first and last lines
			local a, note1, c, d, note2 = line:match('(.-) (.-) ("?.+"?) (.-) (.-)') -- split line
				for _, note_num in ipairs(orig_note_data) do
					if note1+0 == note_num then
					note = math.floor(note1+shift_by_val) -- strip trailing decimal 0
					t[k] = a..' '..note..' '..c..' '..d..' '..note
					break end
				end

				-- after updating the relevant note number look for and delete from the original note names list
				-- the lines which have the same note number as the updated lines but which originally
				-- differ from the RS5k instrument note numbers and so not belonging to it
				-- to prevent scenario where after the update lines with the same note number but
				-- different name, which originally were unrelated to the RS5k instrument, will override
				-- the relevant note names due to being placed lower in the note names list
				-- because by REAPER design names placed lower have priority in case note numbers are the same
				-- after concatenation, the new_note_map var will contain list with empty lines
				-- but REAPER can handle these
				if note1+0 == note then
				t[k] = ''
				end
			end

		end
	new_note_map = table.concat(t,'\n')
	end

return old_note_map, new_note_map, last_sel_idx

end



function MAIN(tr, rs5k, shift_by_val, orig_note_data, orig_note_names, ignore_bypassed)
-- orig_note_data arg stems from Get_Orig_Note_Data()
-- orig_note_names stem from extented state inside the track chunk 
-- which is only used to restore the orig names if the user so chooses

r.Undo_BeginBlock()

local ret, chunk = GetObjChunk(tr)	
	if ret then
		if not orig_note_names then -- shifting, because if orig_note_names is valid restoration must be performed rather than shifting
		old_names, new_names, last_sel_idx = Shift_Note_Names(chunk, orig_note_data, shift_by_val) -- must be run here to extract last_sel_idx in order to open fx chain below at the last selected fx for consistency and better UX
		elseif orig_note_names and #orig_note_names > 0 then -- restoring
		-- parse and process current <MIDINOTNAMES block
		cur_names, last_sel_idx = chunk:match('<MIDINOTENAMES.->'), chunk:match('LASTSEL (%d+)')
			if cur_names then
			old_names = ''
				for line in cur_names:gmatch('(.-)\n') do
				local note_No = line:match('.- (%d+) ')
					if note_No and note_No+0 > 127 then
					break -- exclude CC lane names (note # > 127) in case present to avoid their overwriting
					else
					old_names = old_names..line..'\n'
					end
				end
			-- if old names block isn't closed due to presense of CC names which have been excluded above
			-- remove the closing angle bracket from the orig note data
			new_names = old_names:match('>') and orig_note_names or orig_note_names:match('(.+)>')
			end
		end
	end	
	
	
local undo = shift_by_val ~= 0 and 'Shift RS5k instrument note map by '..shift_by_val..' semitones' or 'Restore RS5K instrument note map'

Shift_Map(tr, rs5k, ignore_bypassed)

local ret, chunk = GetObjChunk(tr) -- retrieve the chunk again with the new data after note map shift with Shift_Map() above to apply note names shift to it below

	if ret and old_names and #old_names > 0 then -- if track chunk was retrieved and note map was found in it
	old_names = Esc(old_names)
	new_names = new_names:gsub('%%','%%%%') -- escape just in case otherwise gsub below won't work
	local new_chunk = chunk:gsub(old_names, new_names)
	SetObjChunk(tr, new_chunk)
	local ME = r.MIDIEditor_GetActive()
		if ME then -- when 'View: Hide unused and unnamed note rows' toggle state is On, shifting note names reveals unamed notes and conceals named ones, so restore visibility of only named notes by running the action even though its toggle state is already On, not clear if it was designed this way or a happenstance; the toggle state of this action and 3 other's, 'View: Hide unused note rows', 'View: Show all notes' and 'View: Show custom note row view' are mutually exclusive
		local take_tr = r.GetMediaItemTake_Track(r.MIDIEditor_GetTake(ME))
			if take_tr == tr and r.GetToggleCommandStateEx(32060, 40454) == 1 -- View: Hide unused and unnamed note rows
			then
			r.MIDIEditor_LastFocused_OnCommand(40454, false) -- islistviewcommand false
			end
		end
	end
	
	r.Undo_EndBlock(undo, old_names and #old_names > 0 and 1 or 2) -- when there're note names use flag 1 - UNDO_STATE_TRACKCFG which works for both track note names and FX chain in builds prior to 7.01, where -1 - UNDO_STATE_ALL doesn't work for FX data if FX chain is closed; if there're no note names use flag 2 - UNDO_STATE_FX because, unlike flag 1, when undone note map restoration data stored as the track extended state aren't affected // flag -1 - UNDO_STATE_ALL doesn't work for FX with closed FX chain in builds older than 7.01 https://forum.cockos.com/showthread.php?t=281778

end




::RETRY::
retval, output = r.GetUserInputs('Shift By (0 to restore original map)', 2, 'Prefix negative with —,Ignore bypassed (type any char),extrawidth=100', output or '')
	if not retval or output:gsub(' ','') == ',' then return r.defer(no_undo) end

local shift_by_val, ignore_bypassed = output:match('(.-),(.*)')

local err = #shift_by_val:gsub(' ','') == 0 and 'no value has been specified' or #shift_by_val:gsub(' ','') > 0 and not tonumber(shift_by_val) and 'not a numeric value' --or tonumber(shift_by_val) == 0 and 'zero isn\'t a valid value'
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

local orig_note_data = Get_Orig_Note_Data(tr, rs5k, ignore_bypassed) -- will be used to shift note names with Shift_Note_Names() inside MAIN(), hence must be based on the current note values stored inside rs5k table at this stage, not on the shifted values


	if shift_by_val == 0 then -- (re)store
	local resp = r.MB('YES —  Restore the original map\n\nNO —  Store current map for restoration later.','PROMPT', 3)
		if resp == 6 then -- response Yes, restore
		local orig_map = r.GetExtState(tr_GUID, 'RS5k instrument note map')
			if #orig_map == 0 then
			ret, orig_map = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map', '', false) -- setNewValue false
			end
			if not ret or #orig_map == 0 then Error_Tooltip('\n\n  the original map \n\n data wasn\'t found \n\n', 1,1) -- caps, spaced are true
			else
			local rs5k = Get_Orig_Note_Map(orig_map) -- parse orig_map data
			local orig_note_names = r.GetExtState(tr_GUID, 'RS5k instrument note names')
				if #orig_note_names == 0 then
				ret, orig_note_names = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note names', '', false) -- setNewValue false	
				end
			MAIN(tr, rs5k, shift_by_val, orig_note_data, orig_note_names, ignore_bypassed)
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map', orig_map, true) -- setNewValue true // store note map			
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note names', orig_note_names, true) -- setNewValue true // store note names
				if #orig_note_names > 0 then
				r.SetExtState(tr_GUID, 'RS5k instrument note map', orig_map, false) -- persist false
				r.SetExtState(tr_GUID, 'RS5k instrument note names', orig_note_names, false) -- persist false
				end
			end
		elseif 7 then -- response No, store replace stored map data with the current one

			if STORED then r.MB('The same map has just been stored in the background.','ERROR',0) end

		r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note map', orig_map, true) -- setNewValue true // store note map to be able to restore by typing 0 in the dialogue
		r.SetExtState(tr_GUID, 'RS5k instrument note map', orig_map, false) -- persist false
		local orig_note_names = Get_Track_MIDI_Note_Names(tr)
			if orig_note_names then
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:RS5k instrument note names', orig_note_names, true) -- setNewValue true // store note names to be able to restore by typing 0 in the dialogue
			r.SetExtState(tr_GUID, 'RS5k instrument note names', orig_note_names, false) -- persist false
			end
		else return -- cancelled by the user
		end
	return r.defer(no_undo)
	end


local unit = 1/127
	for k, data in ipairs(rs5k) do -- store shifted note numbers
	local note_st, note_end = data.start+shift_by_val*unit, data.fin+shift_by_val*unit
		if note_st < unit or note_end > 1 then
		Error_Tooltip('\n\n   cannot shift. \n\n note range limit \n\n has been reached.\n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo)
		end
	rs5k[k].start = note_st
	rs5k[k].fin = note_end
	end



MAIN(tr, rs5k, shift_by_val, orig_note_data, orig_note_names, ignore_bypassed)



