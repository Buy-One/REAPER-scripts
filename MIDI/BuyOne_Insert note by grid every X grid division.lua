--[[
ReaScript name: BuyOne_Insert note by grid every X grid division.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962; 7.37+ for greater versatility
Extensions: 
Provides: [main=midi_editor] .
About: 	The script opens a dialogue with the following options
			which need to be activated before its execution:

			► Step (every X grid division)  
			Expects a number. Can be empty if 'Probability' field is enabled
			in which case the notes will be inserted at each grid division,
			i.e. no need to type in 1 explicitly.  
			The step value is stored between script runs.

			► Reduced probability  
			Makes the script insert notes at step defined in the 'Step' 
			field with probability lower than 100%. To enable type in 
			any alphanumeric character.  
			Using reduced probability isn't recommended when the number 
			of steps available in the target grid (original or visible) 
			is relatively small because the likelihood of no note being 
			eventually inserted is high.

			► Velocity  
			Empty - notes are inserted at MIDI Editor current default 
			velocity, same as if drawn manually;  
			Number - notes are inserted at the specified velocity;  
			Range of numbers in the format X - Y, spaces around the dash 
			and order of numbers are incosequential. If range bounds are 
			outside of the valid velocity range of 1-127, the specified 
			range is clamped to the standard. If range is defined, 
			inserted notes velocity is randomized within the specified 
			range.  
			The velocity value is stored between script runs.

			► Use visible grid  
			A conditional option only avalable in REAPER builds 7.37+ 
			when 'Snap to visible grid' option is enabled and visible 
			grid differs from the grid set in the MIDI Editor 'Grid:' 
			menu.  
			When the visible grid doesn't match the grid setting and 
			in builds 7.37+ 'Snap to visible grid' option is disabled or 
			'Use visible grid' option of the script isn't opted for, and 
			in earlier builds always, the script will automatically adjust 
			the MIDI Editor zoom level so that the visible grid matches 
			the grid setting.  
			Still when visible grid support is available, only straight 
			notes can be inserted by visible grid even when triplet or 
			dotted grid is selected in the grid setting, because this is 
			how REAPER collapses grid in the MIDI Editor at low zoom levels.
			To enable the option type in any alphanumeric character.  

			► Within time selection  
			A conditional option only avalable if time selection is active 
			and it overlaps the MIDI item. To enable type in any alphanumeric 
			character. If enabled, notes are only inserted within the time 
			selection.

			► Between loop points  
			A conditional option only avalable if loop points are set and 
			the looped area overlaps the MIDI item. To enable type in any 
			alphanumeric character. If enabled, notes are only inserted 
			between the loop points.


			LIMITATIONS

			During execution script changes default note length setting to
			be Grid but restores it before termination. However be aware 
			that it cannot restore 1, 2 and 4 measure note setting and if 
			these were initially active the script will activate 1 measure 
			straight setting in their stead.

]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end

function Msg2(f, ...)
-- same as Msg(...) above but with argument f which is integer
-- to modify floating point numbers precision;
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption

-- https://stackoverflow.com/questions/1133639/how-can-i-print-a-huge-number-in-lua-without-using-scientific-notation
local function form(f, s)
return string.format(tonumber(s) and f and '%.'..f..'f' or '%s', s)
end

	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and form(f, t[1])..'\n' or not t[1] and 'nil\n' or ''
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..form(f, cap)..' = '..form(f, val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end



local r = reaper

function no_undo()
do return end
end


function space(num)
return (' '):rep(num)
end



function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
-- caps and spaced are booleans, caps doesn't apply to non-ANSI characters
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
--[[ IF USING WITH gfx
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 arguments which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the gfx window
]]
local text = caps and text:upper() or text
local utf8 = '[\0-\127\194-\244][\128-\191]*'
local text = spaced and text:gsub(utf8,'%0 ') or text -- supporting UTF-8 char
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
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end



function GetUserInputs_Alt(title, field_cnt, field_names, field_cont, separator, comment_field, comment)
-- title string, field_cnt integer, field_names string separator delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string unless they must be initially filled
-- to fill out only specific fields precede them with as many separator characters
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5
-- separator is a string, character which delimits the fields
-- comment_field is boolean, comment is string to be displayed in the comment field
-- extrawidth parameter is inside the function

	if (not field_cnt or field_cnt <= 0) then -- if field_cnt arg is invalid, derive count from field_names arg
		if #field_names:gsub(' ','') == 0 and not comment_field then return end
	field_cnt = select(2, field_names:gsub(',',''))+1 -- +1 because last field name isn't followed by a comma and one comma less was captured
	--	if field_cnt-1 == 0 and not comment_field then return end -- SAME AS THE ABOVE CONDITION
	end

	if field_cnt >= 16 then
	field_cnt = 16 -- clamp to the limit supported by the native function
	comment_field = nil -- disable comment if field count hit the limit, just in case
	end

	local function add_separators(field_cnt, arg, sep)
	-- for field_names and field_cont as arg
	-- add delimiting separators when they're fewer than field_cnt
	-- due to lacking field names or field content
	-- which means they will delimit trailing empty fields
	local _, sep_cnt = arg:gsub(sep,'')
	return sep_cnt == field_cnt-1 and arg -- -1 because the last field isn't followed by a separator
	or sep_cnt < field_cnt-1 and arg..(sep):rep(field_cnt-1-sep_cnt) -- add trailing separators
	or arg:match(('.-'..sep):rep(field_cnt)):sub(1,-2) -- truncate arg when field_cnt value is smaller than the number of fields, excluding the last separator captured with the pattern inside string.match because the last field isn't followed by a separator
	end

	local function format_fields(arg, sep, field_cnt)
	-- for field_names and field_cont as arg
	local arg = type(arg) == 'table' and table.concat(arg, sep) or arg
	return add_separators(field_cnt, arg, sep):gsub(sep..' ', sep) -- if there's space after separator, remove because with multiple fields the field names/content will not line up vertically
	end

-- for field names sep must be a comma because that's what field names list is delimited by
-- regardless of internal 'separator=' argument
local field_names = format_fields(field_names, ',', field_cnt) -- if commas needed in field names and the main separator is not a comma (because if it is comma cannot delimit field names), pass here the separator arg from the function
local sep = separator and #separator > 0 and separator or ','
local field_cont = field_cont or ''
field_cont = format_fields(field_cont, sep, field_cnt)
local comment = comment_field and comment and type(comment) == 'string' and #comment > 0 and comment or ''
local comment_field_cnt = select(2, comment:gsub(sep,''))+1 -- +1 because last comment field isn't followed by the separator so one less will be captured
local field_cnt = comment_field and #comment > 0 and field_cnt+comment_field_cnt or field_cnt

	if field_cnt >= 16 then
	-- disable some or all comment fields if field count hit the limit after comment fields have been added
	comment_field_cnt = field_cnt - 16
	field_cnt = 16
	end

field_names = comment_field and #comment > 0 and field_names..(',Comments:') or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = sep ~= ',' and ',separator='..sep or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=220'..separator, field_cont)
local comment_pattern = ('.-'..sep):rep(comment_field_cnt-1) -- -1 because the last comment field isn't followed by a separator
output = #comment > 0 and output:match('(.+'..sep..')'..comment_pattern) or output -- exclude comment field(s) and include trailing separator to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement

	if not ret or (field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0) then return end
	--[[ OR
	-- to condition action by the type of the button pressed
	if not ret then return 'cancel'
	elseif field_cnt > 1 and output:gsub(' ','') == (sep):rep(field_cnt-1)
	or #output:gsub(' ','') == 0 then return 'empty' end
	]]
local t = {}
	for s in output:gmatch('(.-)'..sep) do
--	for s in output:gmatch('[^'..sep..']*') do -- allow capturing empty fields and the last field which doesn't end with a separator // alternative to 'if #comment == 0 then' block below
		if s then t[#t+1] = s end
	end
	if #comment == 0 then
	-- if the last field isn't comment,
	-- add it to the table because due to lack of separator at its end
	-- it wasn't caught in the above loop
	t[#t+1] = output:match('.*'..sep..'(.*)') -- * operator to account for empty 1st field if there're only two of them
	end
return t, #comment > 0 and output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it
end


function validate_dialogue_field(var, caption)
return var and caption or ''
end


function re_store_sel_MIDI_notes(take, deselect_all, t)
-- store and restore (in the current MIDI channel if Channel filter is enabled)

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

	if not t then
	local sel_note_t, sel_notes_pitch = {}, {}
		for i = 0, notecnt-1 do
		local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel // if looking for all notes use Clear_Restore_MIDI_Channel_Filter() to disable filter if enabled and re-enable afterwards
			if sel then
			sel_note_t[#sel_note_t+1] = i
			sel_notes_pitch[pitch] = startpos
			end
		end
		if deselect_all then
			for k, note_idx in ipairs(sel_note_t) do
			r.MIDI_SetNote(take, note_idx, false) -- selectedIn false, the rest is ignored
			end
		end
	return sel_note_t, sel_notes_pitch
	elseif #t > 0 then
		for _, v in ipairs(t) do
		r.MIDI_SetNote(take, v, true, false, -1, -1, 0, -1, -1, true) -- noteidx - v, selectedIn - true, mutedIn - false, startppqposIn and endppqposIn both -1, chanIn - 0, velIn -1, noSortIn - true since only one note params are set
		end
	end

r.MIDI_Sort(take)

end



function notes_at_current_pitch_exist(ME, take, time_st, time_end, loop_st, loop_end)
-- this is also used to store all current notes
-- to then be able to isolate the inserted notes and apply velocity to them
-- if chose by the user
local cur_pitch = r.MIDIEditor_GetSetting_int(ME, 'active_note_row') -- store
local t, exist = {}
local i = 0
	repeat
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i) -- only targets notes in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel
	t[#t+1] = {[pitch] = startpos} -- storing Y coordinate - pitch and X coordinate - position, pitch is primary because notes are inserted at specific pitch at positions likely unoccupied previosuly by other notes, while position may match notes of other pitches
	local pos = r.MIDI_GetProjTimeFromPPQPos(take, startpos)
		if pitch == cur_pitch and not time_st and not loop_st
		or (time_st and time_end and pos >= time_st and pos < time_end
		or loop_st and loop_end and pos >= loop_st and pos < loop_end)
		then exist = 1
		end
	i=i+1
	until not retval
return exist, t
end



function Apply_Velocity(take, notes_t, range_lo, range_hi, sel_notes_pitch)
-- if fixed velocity only range_lo will be valid

	local function find_new_note(t, start, pitch, sel_notes_pitch)
		for k, props in ipairs(t) do
			if not props[pitch] or props[pitch] and props[pitch] ~= start 
			then return true
			end
		end
	end

local range_lo = range_lo < 1 and 1 or range_lo -- math.random range must start from 1 and 0 is not a meaningful velocity value
local range_hi = range_hi and range_hi > 127 and 127 or range_hi

	if range_hi then
	math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count; math.floor() because the seeding number must be integer
	end
	
local i = 0
	repeat
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
	local new_vel
	local newly_inserted_note = not sel_notes_pitch[pitch] or sel_notes_pitch[pitch] and startpos ~= sel_notes_pitch[pitch] 
		if range_hi and newly_inserted_note and find_new_note(notes_t, startpos, pitch) -- new note // may not be true if the note was inserted exactly on top of existing identical note, which is not very likely
		then
		new_vel = math.random(range_lo, range_hi)
		elseif not range_hi and range_lo and newly_inserted_note then -- fixed new velocity
		new_vel = range_lo
		end
		if vel ~= new_vel then
		r.MIDI_SetNote(take, i, sel, mute, startpos, endpos, chan, pitch, new_vel, true) -- noSortIn - true
		end
	i=i+1
	until not retval

r.MIDI_Sort(take)
	
end



function Get_MIDI_Ed_Grid_Setting(take)

local grid_QN, swing_val, note_len = r.MIDI_GetGrid(take) -- in QN, quarter note is 1, 1/8th is 0.5 and so on. Swing is between -1 and 1 (the API doc is inaccurate in saying 0 and 1), when swing is negative the grid is shifted leftwards. Note length is 0 if it follows the grid size.; triplet is 1.5 of the straight division, 1/4T = 1/4 / 1.5 = 1 / 1.5; dotted is 1.5 times straight, 1/4D = 1/4 * 1.5 = 1 * 1.5; swing doesn't affect grid_QN value because it's returned as swing_val
-- exact grid divisions up to 1 measure can be calculated by the expression 4000/grid_QN
-- triplet notes in this case produce integer greater by 1/3 than the straight note value,
-- dotted notes are fractional and trickier to recognize, their fractionl part
-- alternates between 0.333333333333 and 0.666666666667

local mult = 1.5 -- to calculate triplets and dotted notes
local t = {['Grid'] = 0, -- Grid value is used in note_len evaluation
['4'] = 16, ['4T'] = 16/mult, ['4D'] = 16*mult,
['2'] = 8, ['2T'] = 8/mult, ['2D'] = 8*mult,
['1'] = 4, ['1T'] = 4/mult, ['1D'] = 4*mult,
['1/2'] = 2, ['1/2T'] = 2/mult, ['1/2D'] = 2*mult,
['1/4'] = 1, ['1/4T'] = 1/mult, ['1/4D'] = 1.5,
['1/8'] = 1/2, ['1/8T'] = 1/2/mult, ['1/8D'] = 1/2*1.5,
['1/16'] = 1/4, ['1/16T'] = 1/4/mult, ['1/16D'] = 1/4*mult,
['1/32'] = 1/8, ['1/32T'] = 1/8/mult, ['1/32D'] = 1/8*mult,
['1/64'] = 1/16, ['1/64T'] = 1/16/mult, ['1/64D'] = 1/16*mult,
['1/128'] = 1/32, ['1/128T'] = 1/32/mult, ['1/128D'] = 1/32*mult}

local grid, swing, note

	for div, val in pairs(t) do
		if grid_QN == val then grid, swing = div, swing_val*100 break end -- converting the swing value to percentage
	end

	for div, val in pairs(t) do
		if note_len == val then note = div break end
	end

return grid, swing, note, grid_QN

end



function Get_MIDI_Ed_Visible_Grid(ME, take)
-- the function is only compatible with builds 7.37+
-- where insert note actions respect visible grid
-- when the option 'Snap to visible grid' (first introduced in build 7.36)
-- is enabled and minimum line spacing setting applies to the MIDI Editor grid
-- so when the line spacing produced by the original grid type is smaller
-- than the minimum line spacing value, actual (visible) grid resolution
-- can be learned by inserting a note and measuring its length;
-- IN MIDI EDITOR, FOLDED VISIBLE GRID OF TRIPLET, DOTTED AND SWUNG
-- DIVISIONS PRODUCES LINE SPACING OF MAINLY STRAIGHT NOTES;
-- relies on re_store_sel_MIDI_notes();
-- !!! IMPORTANT:
-- 1) THE FUNCTION MUST BE INCLUDED WITHIN THE UNDO BLOCK
-- BECAUSE THE ACTION 'Edit: Insert note at edit cursor' CREATES
-- AN UNDO POINT AND IF PLACED OUTSIDE OF THE UNDO BLOCK, MIDI EVENT
-- IT TEMPORARILY INSERTS GETS RESTORED WHEN CHANGE PRODUCED
-- BY THE SCRIPT IS UNDONE
-- 2) IT MUST BE PRECEDED BY:
--[[
local note_div, note_mode = Re_Store_Note_Length_Setting(take) -- store settings
	if note_mode ~= 'Grid' then
	r.MIDIEditor_LastFocused_OnCommand(41295, false) -- islistviewcommand false // Set length for next inserted note: grid // ENABLE SO THAT 'Edit: Insert note at edit cursor' ACTION INSERTS NOTE BY GRID, ORIGINAL OR VISIBLE (in bilds 7.37+)
	end
]]
-- AND FOLLOWED BY:
--[[
	if note_mode ~= 'Grid' then
	Re_Store_Note_Length_Setting(take, note_div, note_mode) -- restore settings
	end
]]
-- 3) BE MINDFUL OF THE USE OF PreventUIRefresh() BEFORE THE FUNCTION
-- BECAUSE IT MAY PREVENT EDIT CURSOR POSITION CHANGE EFFECTED
-- WITH 'View: Go to start of file' BELOW FROM BEING ACCESSIBLE
-- TO 'Edit: Insert note at edit cursor', THIS HASN'T BEEN TESTED


-- the function is an alternative to Get_Visible_Grid_Div_Length()
-- which works reliably for Arrange grid but is not relable in the MIDI Editor
-- becasue MIDI Editor grid when folded doesn't respect mimimum line spacing value
-- set in the grid settings (never respected before build 7.37 and only partially
-- respects since) and instead creates greater line spacing which is impossible
-- to calculate with the said function because the function looks for time value in sec
-- corresponding to mimimum line spacing value in pixels and cannot guess
-- by how much actual line spacing of the visible MIDI Editor grid is greater
-- than the minimum value,
-- that said Get_Visible_Grid_Div_Length() function is still able to give an indication
-- when the MIDI Editor visible grid doesn't match the grid setting in builds 7.37+

-- SINCE THE FUNCTION IS INTRUSIVE IT MUST BE CONDITIONED
-- BY DIFFERENCE BETWEEN LINE SPACING IN THE ORIGINAL GRID AND THE VISIBLE GRID
-- SO IT DOESN'T RUN UNNECESSARY
local grid_QN, swing_val, note_len = r.MIDI_GetGrid(take) -- grid_QN is effective grid setting in quarter notes
local grid_div_len = 60/r.Master_GetTempo()*grid_QN -- grid division length in sec
local retval, min_spacing = r.get_config_var_string('projgridmin') -- minimum visible grid resolution // setting in Snap/Grid Settings dialogue 'Show grid, line spacing: ... minimum: ... pixels'
local _7_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.37

	if _7_37 and min_spacing+0 > 0 and grid_div_len*r.GetHZoomLevel() >= min_spacing+0 then return end -- build 7.37+, original grid line spacing in px is NOT smaller than the setting, i.e. visible grid resolution is NOT active, so no need to determine its line spacing

-- The routine runs when build is 7.37+, original grid line spacing in px is smaller
-- than min_spacing setting, i.e. visible grid is active
-- or when min_spacing setting is 0 so there's no clear rule determining when the grid
-- folds to fit the zoom level, so whether there's difference between original
-- and visible grids will have to be determined using this function return value
-- and based on this decision will have to be made which one to opt for.
-- OR when build is older than 7.37 allowing to get grid line spacing regardles if whether
-- it matches the original or the visible grid

local sel_notes = re_store_sel_MIDI_notes(take, 1) -- deselect_all true because note insert action doesn't make the note exclusively selected
local cur_pitch = r.MIDIEditor_GetSetting_int(ME, 'active_note_row') -- store
local edit_cur_pos = r.GetCursorPosition() -- store
local snap_to_vis_grid = r.GetToggleCommandStateEx(32060, 42473) == 1 -- Options: Snap to visible grid

local ACT = r.MIDIEditor_LastFocused_OnCommand

r.PreventUIRefresh(1)

	if not snap_to_vis_grid then -- toggle to ON, must be enaled for the insert note action to respect visible grid
	ACT(42473, false) -- islistviewcommand // Options: Snap to visible grid
	end

r.MIDIEditor_SetSetting_int(ME, 'active_note_row', 0)
ACT(40036, false) -- islistviewcommand // View: Go to start of file
ACT(40051, false) -- islistviewcommand // Edit: Insert note at edit cursor // inserts notes at grid resolution even if global Snap is disabled as long as note length setting is Grid
local note_st, note_end, note_idx

-- get first selected note because when note is inserted by action above
-- it ends up being the only one selected because the rest were preemptively deselected above
local i = 0
	repeat
	local retval, sel, muted, startppqpos, endppqpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
		if sel then note_st, note_end, note_idx = startppqpos, endppqpos, i break end
	i=i+1
	until not retval

-- Restore everything
	if not snap_to_vis_grid then -- toggle to OFF if was intially OFF
	ACT(42473, false) -- islistviewcommand // Options: Snap to visible grid
	end

	if note_idx then r.MIDI_DeleteNote(take, note_idx) end

re_store_sel_MIDI_notes(take, nil, sel_notes) -- deselect_all nil, irrelevant at the restoration stage
r.MIDIEditor_SetSetting_int(ME, 'active_note_row', cur_pitch) -- restore
r.SetEditCurPos(edit_cur_pos, false, false) -- moveview, seekplay false // restore

r.PreventUIRefresh(-1)

-- exact grid divisions up to 1 measure can be calculated by the expression 4000/grid_QN
-- triplet notes in this case produce integer greater by 1/3 than the straight note value,
-- dotted notes are fractional and trickier to recognize, their fractionl part
-- alternates between 0.333333333333 and 0.666666666667
local mult = 1.5 -- to calculate triplets and dotted notes
local t = {
['4'] = 16, ['4T'] = 16/mult, ['4D'] = 16*mult,
['2'] = 8, ['2T'] = 8/mult, ['2D'] = 8*mult,
['1'] = 4, ['1T'] = 4/mult, ['1D'] = 4*mult,
['1/2'] = 2, ['1/2T'] = 2/mult, ['1/2D'] = 2*mult,
['1/4'] = 1, ['1/4T'] = 1/mult, ['1/4D'] = 1.5,
['1/8'] = 1/2, ['1/8T'] = 1/2/mult, ['1/8D'] = 1/2*1.5,
['1/16'] = 1/4, ['1/16T'] = 1/4/mult, ['1/16D'] = 1/4*mult,
['1/32'] = 1/8, ['1/32T'] = 1/8/mult, ['1/32D'] = 1/8*mult,
['1/64'] = 1/16, ['1/64T'] = 1/16/mult, ['1/64D'] = 1/16*mult,
['1/128'] = 1/32, ['1/128T'] = 1/32/mult, ['1/128D'] = 1/32*mult}

	if note_idx then
	local sec = r.MIDI_GetProjTimeFromPPQPos(take, note_end)-r.MIDI_GetProjTimeFromPPQPos(take, note_st) -- length in sec
	local QN = r.MIDI_GetProjQNFromPPQPos(take, note_end)-r.MIDI_GetProjQNFromPPQPos(take, note_st) -- length in QN
	local vis_QN = QN or sec/(60/r.Master_GetTempo()) -- visible grid division in quarter notes
		for div, val in pairs(t) do
		-- due to floating point rounding errors and long fractional parts
		-- it's impossible to reliably evaluate equality by direct comparison
		-- between two floating point numbers
		-- because numbers functionally the same will differ in minute fraction,
		-- this is always an ussue with notes length, which seems to be related
		-- to their measurement in ppq per quarter note, and value in quarter notes
		-- ends up being slightly larger than the value it's supposed to be equal to,
		-- mainly with triplets whose floating point precision is 18 decimal places
		-- i.e. 1/64T: val = 0.041666666666666664 VS vis_QN = 0.041666666666666741,
		-- so a way to compare them is by converting them into strings, tostring()
		-- function automatically rounds off long floating point numbers of up to about
		-- 15 decimal places which seems enough for reliable comparison because the
		-- difference is smaller;
		-- employing this solution for completeness because folded grid only matches
		-- whole notes except when extremely folded in which case it matches 1/2D
			if tostring(val/vis_QN) == '1.0' -- the fractional part of the quotient of the division is so small that after being rounded by conversion into string all which remains of it is decimal zeros
	--[[ OR
		if val..'' == vis_QN..'' or val..'' == (vis_QN..''):gsub('%.0','') -- this works BUT craps out at whole numbers because when vis_QN is converted into string there's a trailing decimal zero while in the table whole numbers lack such zero which causes the evaluation to fail, hence the gsub
		]]
			then
			return div, sec, min_spacing, QN end -- return grid type, grid div length in sec, min line spacing defined by user in grid settings(applies to MIDI Editor since build 7.37), div length in quarter motes
		end
	end

end


function Get_Note_Name_At_Current_Pitch(ME)
local ME = ME or r.MIDIEditor_GetActive()
local pitch = r.MIDIEditor_GetSetting_int(ME, 'active_note_row')
local note_t = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'}
return pitch/12 < 0 and note_t[pitch+1] or note_t[pitch%12+1]..tostring(math.floor(pitch/12-1)) -- +1 in pitch+1 and pitch%12+1 because range starts at 0 and at each C note modulo is 0 while notes table is indexed from 1; -1 in pitch/12-1 because MIDI Editor keyboard starts from octave -1, so 0 in the 0-127 range of the pitch var refers to C-1 rather than C0 and everything must be shifted downwards by 1 to match the keyboard labels and note readouts; math.floor to truncate trailing decimal 0 before conversion into string
end


function Re_Store_Zoom(zoom)

	local function round(num, idp) -- idp = number of decimal places, 0 means rounding to integer
	-- http://lua-users.org/wiki/SimpleRound
	-- round to N decimal places
	  local mult = 10^(idp or 0)
	  return math.floor(num * mult + 0.5) / mult
	end

local cur_zoom = r.GetHZoomLevel()
	if not zoom then -- store
	return cur_zoom
	else -- restore
	local cur_zoom, zoom = round(cur_zoom, 12), round(zoom, 12) -- minute difference in floating point results in inequality between numbers otherwise equal down to the 12th decimal place which are displayed in ReaScript console, so round down to 12 decimal places to prevent that // another method of dealing with these see in floats_are_equal()
	local amt = cur_zoom < zoom and 1 or cur_zoom > zoom and -1
		if amt then -- not equal to stored zoom
		r.PreventUIRefresh(1)
			repeat
			r.adjustZoom(amt, 0, true, 0) -- forceset 0, doupd true, centermode 0 // HORIZONTAL ZOOM ONLY // amt > 0 zooms in, < 0 zooms out, the greater the value the greater the zoom, amt value smaller than 1 is supported, however the zoom amount produced by the amt value seems to depend on the initial zoom level and as zoom level increases/decreases the delta between previous and next zoom levels gradually increases/decreases in comparison with the delta produced by the initial change, so it's hard to calculate in advance the amt value required for a particular zoom level to be able to set it in one go without the loop even though it's known that the zoom amount changes by a factor 10 time greater than the amt value i.e. 0.001 produces change by 0.0X px/sec, WITHOUT PreventUIRefresh() with values under 1 THE ZOOM CHANGES VERY SLOWLY, adusting by r.GetHZoomLevel()/1000 changes zoom by 0.3 px/sec; forceset ~= 0 zooms out, if amt value is 1 then zooms out fully, if amt is greater then depends on the amt value but the relationship isn't clear, if bound to mousewheel, amt can be modified by val return value of get_action_context() function to change direction of the zoom, positive IN, negative OUT; doupd (do update) if false, no zoomming; centermode: 0 < or > 1 no center, window horizontally scrolls all the way rightwards (even though as per the API doc -1 for default, presumably as set at Pref -> Appearance -> Zoom/Scroll/Offset -> Horizontal zoom center), 0 or 1 edit cursor is the center, is adjusted so that the edit cursor ends up at the center, to use mouse as the center the action 'View: Move edit cursor to mouse cursor (no snapping)' must be used, then edit cursor pos should be restored
			until amt == 1 and r.GetHZoomLevel() >= zoom or amt == -1 and r.GetHZoomLevel() <= zoom
		r.PreventUIRefresh(-1)
		end
	end
end



function Set_Horiz_Zoom_Level(target_val)
-- target val is pixel/sec
local dir = r.GetHZoomLevel() > target_val and -1 or r.GetHZoomLevel() < target_val and 1
local cnt = 0
	if dir then
	r.PreventUIRefresh(1)
		repeat
		cnt = cnt+1
		r.adjustZoom(0.1*dir, 0, true, 0) -- forceset 0, doupd true, centermode 0 // HORIZONTAL ZOOM ONLY // amt > 0 zooms in, < 0 zooms out, the greater the value the greater the zoom, the amt arg unit seems to be sec where 0.001 is 1 ms, can be smaller, however the zoom amount produced by the amt value seems to depend on the initial zoom level so it's hard to calculate in advance the amt value required for a particular zoom level to set it in one go without the loop, WITHOUT PreventUIRefresh() with values under 1 THE ZOOM CHANGES VERY SLOWLY, adusting by r.GetHZoomLevel()/1000 changes zoom by 0.3 px/sec; forceset ~= 0 zooms out, if amt value is 1 then zooms out fully, if amt is greater then depends on the amt value but the relationship isn't clear, if bound to mousewheel, amt can be modified by val return value of get_action_context() function to change direction of the zoom, positive IN, negative OUT; doupd (do update) if false, no zoomming; centermode: 0 < or > 1 no center, window horizontally scrolls all the way rightwards (even though as per the API doc -1 for default, presumably as set at Pref -> Appearance -> Zoom/Scroll/Offset -> Horizontal zoom center), 0 or 1 edit cursor is the center, is adjusted so that the edit cursor ends up at the center, to use mouse as the center the action 'View: Move edit cursor to mouse cursor (no snapping)' must be used, then edit cursor pos should be restored
		local zoom = r.GetHZoomLevel()
		until dir < 0 and zoom <= target_val or dir > 0 and zoom >= target_val
	r.PreventUIRefresh(-1)
	end
end



function Re_Store_Note_Length_Setting(take, note_div, note_mode)
-- note division and mode settings at the bottom of the MIDI Editor
-- take must be valid is chunk is going to be used
-- TO BE ABLE TO RESTORE SETTINGS VIA CHUNK
-- AT THE RESTORATION STAGE THE FUNCTION MUST BE PRECEDED WITH:
-- r.MIDIEditor_LastFocused_OnCommand(2, false) -- File: Close window
-- AND FOLLOWED BY:
-- r.SelectAllMediaItems(0, false) -- deselect all
-- r.SetMediaItemSelected(r.GetMediaItemTake_Item(take), true)
-- r.Main_OnCommand(40153,0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)

	-- store
	if not note_div and not note_mode -- IF USING ACTIONS, in this case note_mode will certainly be valid at the restoration stage and assigned command ID 41711 (straight note mode) even if note_div is nil
	-- if not note_div -- IF USING CHUNK, note_mode can come in as nil if the data was collected from chunk, but note_div will always be valid
	then
	local note_div_sett_t = {
	-- these actions always keep their toggle state as long as note division
	-- is active regardles of the way it was activated
	-- while actions without 'preserving division type' verbiage change
	-- their toggle state and therefore unreliable;
	-- there're no actions to enable 2 and 4 measures in the note menu
	-- so these cannot be stored and restored
	41710, -- Set length for next inserted note: 1 preserving division type
	41709, -- Set length for next inserted note: 1/2 preserving division type
	41708, -- Set length for next inserted note: 1/4 preserving division type
	41707, -- Set length for next inserted note: 1/8 preserving division type
	41706, -- Set length for next inserted note: 1/16 preserving division type
	41705, -- Set length for next inserted note: 1/32 preserving division type
	41704, -- Set length for next inserted note: 1/64 preserving division type
	41703, -- Set length for next inserted note: 1/128 preserving division type
	41295 -- Set length for next inserted note: grid
	}
	local note_mode_sett_t = {
	-- with whole notes, dotted 1 whole note is supported, however
	-- when 1 measure dotted is set via action it ends up displayed as 1/1 instead of 1
	-- and if the pull-up note list is opened, 1/128 becomes automatically selected;
	-- there's no single action to enable 1 measure dotted unlike with smaller note divisions;
	-- when triplet 1 whole note and all non-straight types of 2 and 4 measure note
	-- are manually enabled in the note menu the toggle state of the triplet
	-- and dotted actions listed below is set to OFF while the toggle state of the
	-- straight action is set to ON,
	-- when triplet and dotted modes are enabled for 2 and 4 measure notes via action,
	-- the mode remains straight, but note notation is shown as a fraction, i.e. 4/3,
	-- or a decimal fraction, repeated execution of the triplet or dotted action keeps
	-- calculating the new fractional note value, while for 1 measure note this is
	-- only the case with triplet mode set via action, however if set, dotted mode
	-- action starts to affect it as well;
	41712, -- Set length for next inserted note: dotted preserving division length
	41711, -- Set length for next inserted note: straight preserving division length
	41713 -- Set length for next inserted note: triplet preserving division length
	}
	local note_div, note_mode
		for k, act_ID in ipairs(note_div_sett_t) do
			if r.GetToggleCommandStateEx(32060, act_ID) == 1
			then note_div = act_ID
			end
		end
		for k, act_ID in ipairs(note_mode_sett_t) do
			if r.GetToggleCommandStateEx(32060, act_ID) == 1
			then note_mode = act_ID
			end
		end

	return note_div, note_mode -- returns action command IDs

	else

	local note_div = note_div or 41710 -- if note_div came in as nil because note was set to 2 or 4 measures, set to 1 because there're no actions for 2 and 4 measure notes
	local set = note_div and r.MIDIEditor_LastFocused_OnCommand(note_div, false) -- islistviewcommand
	-- THE PROBLEM IS THAT WHEN 1 measure dotted IS RESTORED IT MAY END UP DISPLAYED AS 1/1 INSTEAD OF 1
	-- and if the drop-down note list is opened 1/128 becomes automatically selected;
	-- there's no single action to enable 1 measure dotted unlike with smaller note divisions
	local note_mode = note_div and note_div ~= 41710 and note_mode -- only set mode when note_div var is valid, which excluses 2 and 4 measure note because they cannot be set via actions, OR when note_div is NOT 1 measure because setting dotted mode for 1 measure note results in the note value not being properly displayed in the menu, see above, while for 1 measure, straight explicit mode setting isn't necessary anyway; so for 1,2,4 measure notes only restore 1 straight
	local note_mode = note_mode and r.MIDIEditor_LastFocused_OnCommand(note_mode, false) -- islistviewcommand
	end

end


function ACT(cmdID)
r.MIDIEditor_LastFocused_OnCommand(cmdID, false) -- islistviewcommand false
end


function get_time_sel_or_loop_len(want_loop)
local want_loop = want_loop or false
local st, fin = r.GetSet_LoopTimeRange(false, want_loop, 0, 0, false) -- isSet, allowautoseek false
return st, fin, fin-st
end


function determine_bounds(st, fin, item_pos, item_end)
return st < item_pos and item_pos or st, fin > item_end and item_end or fin
end


function is_space_sufficient(step, div_len, item_pos, left_bound, right_bound)
-- comparing number of whole steps which can fit within space between item start
-- and right bound of time selection or loop, on the one hand
-- to number of whole steps which can fit within space between item start
-- and left bound of time selection or loop, on the other
local floor = math.floor
local divisor = step*div_len
local resolution1 = (right_bound-item_pos)/divisor
	if resolution1 < 1 then return end
local resolution2 = (left_bound-item_pos)/divisor
return floor(resolution1-resolution2+0.5) >= 1
end


-------------- MAIN ROUTINE ----------------


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local err = sect_ID ~= 32060 and space(3)..'the script must be run \n\n'
..space(5)..'from the midi editor \n\n section of the action list'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced
	return r.defer(no_undo)
	end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)
local item = r.GetMediaItemTake_Item(take)
local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_pos+r.GetMediaItemInfo_Value(item, 'D_LENGTH')

local grid_resol, swing, note_len, QN = Get_MIDI_Ed_Grid_Setting(take)

local grid_div_len = 60/r.Master_GetTempo()*QN -- in sec, Grid setting

-- visible grid can only be respected in builds 7.37+
-- where 'snap to visible grid' option is available in the MIDI Editor and it's ON
local snap_to_vis_grid = r.GetToggleCommandStateEx(32060, 42473) == 1 -- Options: Snap to visible grid

r.Undo_BeginBlock() -- must be placed here because otherwise action 'Edit: Insert note at edit cursor' inside Get_MIDI_Ed_Visible_Grid() creates its own undo point, and the deleted temporary note event gets restored when the change produced by the script is undone

local note_div, note_mode = Re_Store_Note_Length_Setting(take) -- store before setting note length to Grid to be able to use 'Edit: Insert note at edit cursor' action inside Get_MIDI_Ed_Visible_Grid() function and in the main loop because it respects note length/mode setting and otherwise won't insert note by grid if the grid and note length setting differ

	if snap_to_vis_grid and note_len ~= 'Grid' then -- set note length to grid for 'Edit: Insert note at edit cursor' action used inside Get_MIDI_Ed_Visible_Grid() function, unless it's already set to match the grid
	ACT(41295) -- Set length for next inserted note: grid // ENABLE SO THAT 'Edit: Insert note at edit cursor' ACTION INSERTS NOTE BY GRID, ORIGINAL OR VISIBLE (in bilds 7.37+)
	end

local vis_grid_resol, vis_grid_div_len, min_line_spacing = table.unpack(snap_to_vis_grid and {Get_MIDI_Ed_Visible_Grid(ME, take)} or {}) -- only returns value if visible grid line spacing is greater than that of the original grid in builds 7.37+

	if snap_to_vis_grid and note_len ~= 'Grid' then -- restore if note setting was changed to 'Grid' above, so that when the dialogue loads the original setting is displayed to the user, unless it's already set to match the grid
	Re_Store_Note_Length_Setting(take, note_div, note_mode)
	end

-- reformat note name
grid_resol = grid_resol:gsub('.+[TD]+', function(c) local mode = c:sub(-1) return (mode=='D' and 'dotted ' or mode=='T' and 'triplet 'or '')..c:sub(1,-2) end)
local note_name = Get_Note_Name_At_Current_Pitch(ME)
local caption = 'Insert '..(swing ~= 0 and 'swinged ' or ' ')..grid_resol..'  '..note_name..'  note'

local time_st, time_end, time_len = get_time_sel_or_loop_len()
local loop_st, loop_end, loop_len = get_time_sel_or_loop_len(1) -- want_loop true
time_len = time_len > 0 and time_st < item_end and time_end > item_pos and time_len -- validate
loop_len = loop_len > 0 and loop_st < item_end and loop_end > item_pos and loop_len -- validate
local field_cnt = 3
field_cnt = field_cnt + (vis_grid_resol and 1 or 0) + (time_len and 1 or 0) + (loop_len and 1 or 0)
local field_capt = 'Step (every X grid division),Reduced probability,Velocity (empty or value),'
..validate_dialogue_field(vis_grid_resol, vis_grid_resol and 'Use visible grid (straight '..vis_grid_resol..'),')
..validate_dialogue_field(time_len,'Within time selection,')
..validate_dialogue_field(loop_len,'Between loop points')
local comment = 'To enable any option but <Step> and <Reduced probability>,\rtype in any alphanumeric character,\rto randomize velocity, type in range, e.g. 1-15 or 111 - 127'

local autofill

::RELOAD::

local state = r.GetExtState(named_ID, 'LATEST')
local step, vel = state:match('(.-)\r(.-)$')
local field_cont = (step or '')..'\r\r'..(vel or '') -- relevant for the first run during the session when there's no state yet, otherwise empty step and vel are captured as empty strings so no alternative is required

local output_t, output = GetUserInputs_Alt(caption, field_cnt, field_capt, autofill or field_cont, '\r', comment, comment)

	if not output_t then
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) end

autofill = output
local step = output_t[1]:match('^%s*(%d+)%s*$')
local randomize = #output_t[2]:gsub(' ','') > 0
local velocity = output_t[3]:match('^%s*(%d+[%s%-]+%d+)%s*$') -- range
or output_t[3]:match('^%s*(%d+)%s*$') -- fixed
local use_vis_grid = vis_grid_resol and #output_t[4]:gsub(' ','') > 0
local time_sel = time_len and #output_t[vis_grid_resol and 5 or 4]:gsub(' ','') > 0
local loop = loop_len and
#output_t[vis_grid_resol and time_len and 6 or (vis_grid_resol or time_len) and 5 or 4]:gsub(' ','') > 0

local move_edit_cur_right_by_grid_action = build < 7.37
or build >= 7.37 and build < 7.40 and (snap_to_vis_grid and not use_vis_grid or not snap_to_vis_grid)
or build >= 7.40 -- in all these scenarios the 'snap to visible grid' option is ignored so that 'Navigate: Move edit cursor right by grid' action is certain to run in note insertion loop to skip grid divisions where notes aren't supposed to be inserted, it won't work however when 'snap to visible grid' option has to be respected because Cockos forgot to make it compatible with this option and at visible grid it gets stuck, bug report https://forum.cockos.com/showthread.php?t=300723, which was fixed in 7.40, but now 'Navigate: Move edit cursor right by grid' ALWAYS follows visible grid, regardless of 'snap to visible grid' option which is not how 'Edit: Insert note at edit cursor' action works and it only happens to suit this script because if 'snap to visible grid' option is disabled or enabled but user has not opted for visible grid, MIDI editor zoom is adjusted so that the visible grid matches the original grid, so whether or not visible grid must be respected the action will accurately follow the grid, HOWEVER IT WOULD NOT WORK IF NOTES WERE TO BE INSERTED BY THE ORIGINAL WHILE VISIBLE GRID WAS ACTIVE AND A FUNCTION WOULD HAVE TO BE USED INSTEAD TO MOVE THE CURSOR BY THE ORIGINAL GRID LIKE IT WAS IN BUILDS WERE IT WOULD BREAK DOWN AT THE VISIBLE GRID

local div_len = move_edit_cur_right_by_grid_action and grid_div_len or vis_grid_div_len

local left_bound, right_bound = table.unpack(time_sel and {determine_bounds(time_st, time_end, item_pos, item_end)}
or loop and {determine_bounds(loop_st, loop_end, item_pos, item_end)} or {item_pos, item_end})
local invalid_vel = not velocity and #output_t[3]:gsub(' ','') > 0 or tonumber(velocity) and (velocity+0<1 or velocity+0>127)

err = not step and not randomize and 'invalid input' or time_sel and loop
and ' combination of time selection\n\n and loop points isn\'t supported'
or invalid_vel and 'invalid velocity value'
or step and not is_space_sufficient(step, div_len, item_pos, left_bound, right_bound) and ' the step size exceeds \n\n the available distance'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced
	goto RELOAD
	end

local notes_exist, notes_t = notes_at_current_pitch_exist(ME, take, time_sel and time_st, time_end, loop and loop_st, loop_end)

	if notes_exist
	and r.MB('There\'re notes at current pitch '..note_name..'.\n\n  Wish to insert notes over them?','PROMPT',4) == 7
	then
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) end


r.SetExtState(named_ID, 'LATEST', (step or '')..'\r'..(velocity or ''), false) -- persist false

	if build < 7.37 and grid_div_len*r.GetHZoomLevel() < 16
	-- 1. in builds older than 7.36 the action 'Edit: Insert note at edit cursor'
	-- used in the script doesn't respect visible grid different from original grid, which is activated
	-- when grid division length falls below 16 px, after which the grid keeps folding exponentially,
	-- i.e. when below 8, 4, 2, 1 px,
	-- so before inserting notes adjust visible grid until it matches actual
	-- grid setting so that it doesn't look as if some notes were inserted off grid;
	-- 2. in build 7.36 Cockos added 'snap to visible grid' option in the MIDI Editor
	-- but forgot to make the following actions compatible:
	-- Edit: Insert note at edit cursor (no advance edit cursor)
	-- Edit: Insert note at edit cursor
	-- Step input: Insert note at current note
	-- Edit: Move notes right/left one grid unit
	-- which resulted in the actions getting stuck when zoom level was too low for the UI to display
	-- the original grid and when a sparser (visible) grid was activated instead
	-- and consequently the note insert loop below which uses 'Edit: Insert note at edit cursor'
	-- was getting stuck as well
	-- only fixed in 7.37, so point 1 mechanism above applies to build 7.36 as well
	---------------------------------------------------------
	-- in builds 7.37+ where 'snap to visible grid' option is available
	-- adjust the grid as well when visible grid doesn't match the grid setting and
	-- A) the option is enabled but user has not chosen to respect it
	-- so that the action 'Edit: Insert note at edit cursor' follows the grid defined in the settings
	-- rather than the visible one, OR
	-- B) the option is disabled, because in this case the action 'Edit: Insert note at edit cursor'
	-- in the loop below won't insert note at visible grid and if the grid differs from the original
	-- it may seem as if some notes were inserted off grid
	or vis_grid_resol -- valid when visible grid line spacing is greater than that of the original grid in builds 7.37+
	and snap_to_vis_grid and not use_vis_grid
	or not snap_to_vis_grid then
	min_spacing = build < 7.37 and 16 or min_line_spacing -- first two conditions in this block // in builds older than 7.37 MIDI Editor grid begins folding when line spacing falls below 16 px, since the said build this depends on the minimum line spacing setting // min_line_spacing var will be valid when snap_to_vis_grid is enabled
	local retval
		if not min_spacing then -- 2 above conditions weren't met, extract directly, matches 3d above condition, i.e. build 7.37+ and snap_to_vis_grid is disabled
		retval, min_spacing = r.get_config_var_string('projgridmin') -- minimum visible grid resolution // setting in Snap/Grid, applies to the MIDI Editor in builds 7.37+
		end
	local synced = r.GetToggleCommandStateEx(32060, 40640) == 1 -- Timebase: Toggle sync to arrange view // if MIDI Editor zoom is synced to Arrange, View -> Piano roll time base -> Project synced
	local zoom
		if not synced then
		zoom = Re_Store_Zoom() -- store Arrange zoom
		r.MIDIEditor_LastFocused_OnCommand(40640, false) -- enable
		end
	Set_Horiz_Zoom_Level(min_spacing/grid_div_len) -- passing expected zoom level in px/sec
		if not synced then
		r.MIDIEditor_LastFocused_OnCommand(40640, false) -- disable
		Re_Store_Zoom(zoom) -- restore Arrange zoom
		end
	vis_grid_resol = nil -- reset to ignore in the undo point concatenation
	end


	if move_edit_cur_right_by_grid_action then -- only enable when using action to move the edit cursor by grid, because when MoveEditCursor() or SetEditCurPos() functions are used UI refresh prevention makes latest edit cursor position unavaliable to the action 'Edit: Insert note at edit cursor' and note events are inserted back to back at the start of the item following edit cursor movement effected by the action itself (because it advances edit cursor automatically), instead of according to user chosen pattern
	r.PreventUIRefresh(1)
	end

	if note_len ~= 'Grid' then
	ACT(41295) -- 'Set length for next inserted note: grid' // ENABLE SO THAT 'Edit: Insert note at edit cursor' ACTION INSERTS NOTE BY GRID, ORIGINAL OR VISIBLE (in bilds 7.37+)
	end

local edit_cur_pos_init = r.GetCursorPosition() -- store
ACT(40036) -- View: Go to start of file

-- determine user velocity setting
local a, b = velocity and velocity:match('^%s*(%d+)'), velocity and velocity:match('%-%s*(%d+)')
local vel_range_lo, vel_range_hi
	if a and b then -- range for randomization
	vel_range_lo = math.min(a+0, b+0)
	vel_range_hi = math.max(a+0, b+0)
	elseif a then -- fixed velocity
	velocity = a+0
	else velocity = nil -- MIDI Editor current default, i.e. no change
	end

local rand_val

	if randomize then
	math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count; math.floor() because the seeding number must be integer
	end

local rand_range_end = step and randomize and 2 or 3 -- range greater than 2 produces greater variation but when step is followed randomly greater range reduces the number of notes which are already inserted sparsely

local sel_notes, sel_notes_pitch = re_store_sel_MIDI_notes(take)

local counter = 1 -- will count blank grid divisions in between notes
	repeat
	local cur_pos = r.GetCursorPosition()
	rand_val = randomize and math.random(1, rand_range_end)
		if cur_pos >= left_bound and -- only start from left bound
		(step and rand_val and rand_val == 1 and counter%step+0 == 0 -- insert randomly but following step pattern
		or not step and rand_val and rand_val == 1 -- insert at random steps
		or not rand_val and counter%step+0 == 0) then -- insert following step pattern
		ACT(40051) -- Edit: Insert note at edit cursor // inserts notes at grid resolution even if global Snap is disabled as long as note length setting is Grid
		else
			if move_edit_cur_right_by_grid_action --or build > 7.39
			then -- in builds newer than 7.39 'Navigate: Move edit cursor right by grid' works on visible grid as well
			ACT(40048) -- Navigate: Move edit cursor right by grid
			else -- due to bug described above use API instead of the action to move edit cursor by grid when 'snap to visible grid' option is enabled and user has opted for visible grid; advancing by the grid with the function is safe when Swing is enabled because in visible grid swung divisions are ignored, so no special calculation of swung divisons is required
			r.MoveEditCursor(div_len, false) -- dosel false
		-- OR
		--	r.SetEditCurPos(item_pos+div_len*counter, false, false) -- moveview, seekplay false // restore
			end
		end
	counter = counter+1
	until cur_pos + div_len >= right_bound -- stop as soon as right bound is about to be reached or overshot in the next loop cycle, because if it's item end this will prevent its extension by note insertion, which is effected by note insert actions even if the opton 'Allow MIDI note edit to extend the media item' is NOT enabled as long as 'Loop source' flag isn't set either in the Item Properties, and will also prevent note insertion outside of time selection, loop end point


	if velocity then -- at least this is valid, relevant valid value is selected during function call
	Apply_Velocity(take, notes_t, vel_range_lo or velocity, vel_range_hi, sel_notes_pitch)
	end


	if note_len ~= 'Grid' then
	Re_Store_Note_Length_Setting(take, note_div, note_mode) -- restore
	end

r.SetEditCurPos(edit_cur_pos_init, false, false) -- moveview, seekplay false // restore

	if move_edit_cur_right_by_grid_action then -- see explanation above
	r.PreventUIRefresh(-1)
	end

local undo = caption..(randomize and ' randomly' or '')..(step and ' every '..step or '')
..(vis_grid_resol and ' visible' or '')..(step and ' grid divisions' or ' by grid')..
(time_sel and ' within time selection' or loop and ' between loop points' or '')
..(vel_range_lo and ' at velocity range '..vel_range_lo..'-'..vel_range_hi or velocity and ' at velocity '..velocity or '')

r.Undo_EndBlock(undo, -1)




