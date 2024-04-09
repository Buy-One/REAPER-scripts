--[[
ReaScript name: BuyOne_Duplicate project marker.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: 	[main=main,midi_editor] .
About:	Order of precedence of source and target marker locations:
		1. Mouse cursor
		2. Edit cursor
		3. Time selection (time selection start as target location)
		4. 50 px to the right of the source marker (only relevant 
		as a target location and when other target locations are
		invalid, which is only possible when duplicating a marker 
		at the edit cursor)
		
		The source marker current location cannot be also the target 
		location, hence three other available options should be 
		considered.
		
		For the mouse cursor position to be valid it must be located
		within Arrange opposite of a TCP.
		
		When duplicating a marker in time selection the script
		only respects the first marker found in time selection.
		
		For a more reliable detection of the source marker at the 
		mouse cursor it's recommended that the snaping and snap 
		to markers be enabled.

]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function Get_Set_Marker_Reg_In_Time_Sel_At_Edit_Mouse_Curs(mrkrs, rgns)

	local function get_mouse_curs_pos(curs_pos, at_mouse, to_mouse)	

		if r.GetTrackFromPoint(r.GetMousePosition()) -- look for the mouse cursor pos // GetTrackFromPoint() prevents this context from activation if the script is run from a toolbar or the Action list window floating over Arrange or if mouse cursor is outside of Arrange because in this case GetTrackFromPoint() returns nil
		then
		-- the action for setting stage must not respect snapping to allow placing marker anywhere
		local act = at_mouse and 40513 -- View: Move edit cursor to mouse cursor [with snapping so it can snap to marker / region start/end]
		or to_mouse and 40514 -- View: Move edit cursor to mouse cursor (no snapping)
		r.PreventUIRefresh(1)
		ACT(act)
		local new_cur_pos = r.GetCursorPosition()
		r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig edit curs pos
		r.PreventUIRefresh(-1)
		return new_cur_pos
		end

	end

local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
start = start ~= fin and start

local curs_pos = r.GetCursorPosition()
local mouse_pos = get_mouse_curs_pos(curs_pos, true, to_mouse) -- at_mouse true // action with snapping

local max_ID, mouse_cur_mrkr, edit_cur_mrkr, time_mrkr = math.huge*-1

local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, ID, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
	local t = {idx=i, isrgn=isrgn, pos=pos, rgnend=rgnend, name=name, ID=ID, col=color}	
		
		if not isrgn then
		max_ID = ID > max_ID and ID or max_ID
		end

		if rgns and isrgn then -- regions			
		
			if mouse_pos and (pos == mouse_pos or rgnend == mouse_pos) then			
			-----
			end
			
			if start and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin -- region start or end is within time sel
			or pos >= start and rgnend <= fin) -- whole region is within time sel
			then			
			-----
			end
			
			if curs_pos and (pos == curs_pos or rgnend == curs_pos) then			
			-----
			end

		elseif not isrgn and mrkrs then -- markers
		
			if mouse_pos and (pos == mouse_pos or rgnend == mouse_pos) then
			mouse_cur_mrkr = t
			end
			
			if start and pos >= start and pos <= fin then
			-- only 1st marker found if time selection
			time_mrkr = time_mrkr or t
			end

			if pos == curs_pos then
			edit_cur_mrkr = t
			end

		end
	i = i+1
	until retval == 0 -- until no more markers/regions

	if not mouse_cur_mrkr and not time_mrkr and not edit_cur_mrkr then
	Error_Tooltip('\n\n no project marker \n\n    in the expected \n\n  source locations \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 to move tooltip away from the mouse so it doesn't block clicks
	return end

mouse_pos = get_mouse_curs_pos(curs_pos, at_mouse, true)-- to_mouse true // re-get as a tatget position with action without snapping

-- select source marker props according to the order of precedence
local t = mouse_cur_mrkr or edit_cur_mrkr or time_mrkr

-- select target marker location according to the order of precedence and the source marker location
-- source marker location type is excluded from target location types since it's already taken 
local pos = mouse_cur_mrkr and (start or curs_pos)
or edit_cur_mrkr and (mouse_pos or start) -- this expression is error prone because both time and mouse position can be false, if false will fall back on 50 px option below
or time_mrkr and (mouse_pos or curs_pos)
or t.pos+50/r.GetHZoomLevel() -- 50 px to the right from the source // without 50 px option 

-- check if there's already a marker at the target position
local markeridx, regionidx = r.GetLastMarkerAndCurRegion(0, pos) -- includes marker/region at time as well, not only before
	if markeridx > -1 then
	local retval, isrgn, mrkr_pos = r.EnumProjectMarkers3(0, markeridx)
		if mrkr_pos == pos then
		local loc = pos == start and '   (time selection start)' or pos == curs_pos and '\t   (edit cursor)'
	--	or pos == mouse_pos and '(mouse cursor)' -- this can't ever be true because when mouse points at a marker it's always the source marker due to the designed order of preference: mouse curs, edit curs, time
		or pos == t.pos+50/r.GetHZoomLevel() and '     (50 px to the right)'
		Error_Tooltip('\n\n there\'s already a marker \n\n   at the target position \n\n'..loc..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 to move tooltip away from the mouse so it doesn't block clicks
		return end
	end

r.AddProjectMarker2(0, false, pos, 0, t.name, t.ID+1, t.col) -- isrgn false, rgnend 0

return 1

end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = fullpath_init:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

r.Undo_BeginBlock()

	if not Get_Set_Marker_Reg_In_Time_Sel_At_Edit_Mouse_Curs(true, rgns) -- mrkrs true
	then
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	else
	r.Undo_EndBlock(scr_name,-1)
	end





