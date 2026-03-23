--[[
ReaScript name: BuyOne_Insert marker or region on a new lane_META.lua (8 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 	#Added four new scripts to insert marker/region relative 
			to the lane of selected marker, region
			#Improved ruler height update when new lane is added
Licence: WTFPL
REAPER: at least v7.62
Provides: 	[main=main,midi_editor] .
			. > BuyOne_Insert marker on a new lane at the bottom.lua
			. > BuyOne_Insert region on a new lane at the bottom.lua
			. > BuyOne_Insert marker on a new lane at the top.lua
			. > BuyOne_Insert region on a new lane at the top.lua
			. > BuyOne_Insert marker on a new lane below the lane of first selected marker, region.lua
			. > BuyOne_Insert region on a new lane below the lane of first selected marker, region.lua
			. > BuyOne_Insert marker on a new lane above the lane of first selected marker, region.lua
			. > BuyOne_Insert region on a new lane above the lane of first selected marker, region.lua
About: 	If this script name is suffixed with META, when executed 
			it will automatically spawn all individual scripts included 
			in the package into the directory of the META script and will 
			import them into the Action list from that directory.

			If there's no META suffix in this script name it will perfom 
			the operation indicated in its name.

			If this script is designed to insert a marker, a marker
			is inserted at mouse cursor unless the mouse cursor
			is outside of the Arrange area, i.e. hovers over 
			a TCP, MCP, Ruler, a toolbar button, a menu, or the Action 
			list etc., in which case the marker is inserted at 
			at the edit cursor.

			If this script is designed to insert a region, a region
			is always inserted at time selection provided there's
			one.

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end

local r = reaper



function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

		if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

local names_t, content = names_t

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])')

		------------------------------------------------------------------------------------
		-- spawn scripts
		-- NO USER SETTINGS
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
		end
		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060,32062} do -- Main, MIDI Ed, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(Esc(elm:lower())) then return elm end -- at least one match was found
		end

	end

	local function Rep(n) -- number of repeats, integer
	return (' '):rep(n)
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end



function REAPER_Ver_Check(build, want_later, want_earlier, want_current)
-- build is REAPER build number or sring, the function must be followed by 'do return end'
-- want_later, want_earlier and want_current are booleans
-- obviously want_later and want_earlier are mutually exclusive
-- want_later includes current, want_earlier is the up-to version
local build = build and tonumber(build)
local cur_buld = tonumber(r.GetAppVersion():match('[%d%.]+'))
local later, earlier, current = cur_buld >= build, cur_buld < build, cur_buld == build
local err = '   the script requires \n\n  '
local err = want_later and not later and err..'reaper '..build..' and later '
or want_earlier and not earlier and err..'reaper no later than '..build
or want_current and not current and 'reaper build '..build
	if err then
--[[
	local x,y = r.GetMousePosition()
	err = err:upper():gsub('.','%0 ')
	r.TrackCtl_SetToolTip(err, x, y+10, true) -- topmost true
--]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return true
	end -- 'ReaScript:Run' caption is displayed in the menu bar but no actual undo point is created because Undo_BeginBlock() isn't yet initialized, here and elsewhere
end



function Get_TCP_MCP_Under_Mouse(want_mcp)
-- takes advantage of the fact that the action 'View: Move edit cursor to mouse cursor'
-- doesn't move the edit cursor when the mouse cursor is over the TCP;
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP;
-- master track is supported;
-- want_mcp is boolean to address MCP under mouse, supported in builds 6.36+

-- in builds < 6.36 the function also detects MCP under mouse regardless of want_mcp argument
-- because when the mouse cursor is over the MCP the action 'View: Move edit cursor to mouse cursor'
-- does move the edit cursor unless the focused MCP is situated to the left of the Arrange view start
-- or to the right of the Arrange view end depending on the 'View: Show TCP on right side of arrange'
-- setting, which makes 'new_cur_pos == edge or new_cur_pos == 0' expression true because the edit cursor
-- being unable to move to the mouse cursor is moved to the Arrange view start_time/end_time,
-- in later builds this is prevented by conditioning the return value with info:match('tcp')
-- so that the focus is solely on TCP if want_mcp arg is false

-- for builds 6.36+ where GetThingFromPoint() is supported
local tr, info = table.unpack(r.GetThingFromPoint and {r.GetThingFromPoint(r.GetMousePosition())} or {})
	if info then
	return (want_mcp and info:match('mcp') or not want_mcp and info:match('tcp')) and tr
	end

local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end



function Get_Mouse_Or_Edit_Curs_Pos()
-- relies on Get_TCP_MCP_Under_Mouse() to ensure that the mouse cursor is not over TCP or MCP
-- if it is, edit cursor pos is returned

local edit_curs_pos = r.GetCursorPosition() -- store
local cur_pos

local tr, info = r.GetTrackFromPoint(r.GetMousePosition())
-- ensuring that mouse cursor is over Arrange allows ignoring mouse position
-- when the script is run via toolbar button, menu item or from the Action list
-- because in this case tr var is nil
	if tr and not Get_TCP_MCP_Under_Mouse() and not Get_TCP_MCP_Under_Mouse(1) -- want_mcp true
	and info ~= 2 then -- not FX window
	r.PreventUIRefresh(1)
	r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
	cur_pos = r.GetCursorPosition()
	r.SetEditCurPos(edit_curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
	r.PreventUIRefresh(-1)
	end

return cur_pos or edit_curs_pos

end




function Get_Lane_Of_The_First_Selected_Vis_Mrkr_Region()
-- want_mrkr boolean, if true gets marker, otherwise region

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local GetSet = r.GetSetProjectInfo

	for i=0, r.GetNumRegionsOrMarkers(0)-1 do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local st = Get(0, obj, 'D_STARTPOS')
	local fin = Get(0, obj, 'D_ENDPOS') -- only for regions
	local region = fin ~= st -- OR r.GetRegionOrMarkerInfo_Value(0, obj, 'B_ISREGION') == 1 // in markers start and end values are equal
	local vis = Get(0, obj, 'B_VISIBLE') == 1
	local sel = Get(0, obj, 'B_UISEL') == 1
	local lane_idx = Get(0, obj, 'I_LANENUMBER')
	local lane_vis = GetSet(0, 'RULER_LANE_HIDDEN:'..lane_idx, 0, false) == 0 -- isSet false // the attribute works without the colon as well // essentially redundant because B_VISIBLE is also false when the entire lane is hidden
		if vis and sel and lane_vis then
		return lane_idx
		end
	end

end



function Get_Ruler_Lane_Count() -- user in Set_Ruler_Height()
-- since as of build 7.65 lane count isn't accessible via API
-- the function uses a hack of creating a temp marker
-- and force moving it to another lane starting from lane
-- at index 100
-- if lane at the destination index doesn't exist the marker
-- is not moved and its original lane index remains the same,
-- but it's moved as soon as a valid lane index is found
-- and since the movement is attempted in reverse,
-- the first lane index associated with successful movement
-- will be the index of the last available lane

	-- only supported since build 7.62
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end

r.PreventUIRefresh(1)
local index = r.AddProjectMarker(0, false, 0, 0, '', 0xFFFF) -- isrgn false, pos 0, rgnend 0, wantidx 0xFFFF, to be able to easily find it for deletion // insert temp marker
local obj = r.GetRegionOrMarker(0, 0, '') -- index 0, guidStr empty
r.SetRegionOrMarkerInfo_Value(0, obj, 'B_HIDDEN', 1) -- hide, although not strictly necessary thanks to PreventUIRefresh()
local lane_idx_init = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
local lane_count
	for i=100,0,-1 do
	r.SetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER', i)
	local lane_idx = r.GetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER')
		if lane_idx ~= lane_idx_init then
		-- if the very last lane is default for markers, the temp marker will be inserted there
		-- and during the loop will only be able to move to a lane at a lower index,
		-- in which case fall back on the original lane index as the heighest
		lane_count = lane_idx < lane_idx_init and lane_idx_init or lane_idx
		break
		end
	end
r.DeleteProjectMarker(0, index, false) -- isrgn false // delete temp marker
--r.UpdateTimeline() -- required for proper UI update after change, but unnecessary due to PreventUIRefresh()
r.PreventUIRefresh(-1)

-- if there's one lane only the temp marker won't be able to move anywhere
-- hence fall back on its original lane index
return (lane_count or lane_idx_init)+1 -- +1 because lane index returned by GetRegionOrMarkerInfo_Value is 0-based

end



function Set_Ruler_Height()

	-- only supported since build 7.62
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end
	
local lane_cnt = Get_Ruler_Lane_Count()
local hidden

	-- filter out hidden lanes
	for i=0, lane_cnt-1 do
		if r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 1 then -- is_set false
		lane_cnt = lane_cnt-1
		hidden = 1
		end
	end

	if lane_cnt > 0 then
	r.GetSetProjectInfo(0, 'RULER_HEIGHT', (26+(hidden and 4 or 0))*lane_cnt, true) -- isSet true // when there're hidden lanes 26 px per lane seems insufficient whereas when all are visible 30 px seems a bit excessive
	end

end




function Insert_Mrkr_Region_On_Lane_X(scr_name)
-- want_mrkr boolean, if true inserts marker, otherwise region

	-- only supported since build 7.62
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end

local want_mrkr = scr_name:match('Insert marker ')
local top = scr_name:match(' top')
local below, above = scr_name:match(' below'), scr_name:match(' above')
local sel_obj_lane = scr_name:match(' selected') and Get_Lane_Of_The_First_Selected_Vis_Mrkr_Region()

-- only for markers, regions are inserted at time selection;
-- first try to get mouse position, but if conditions aren't met
-- i.e. the script is run from a toolbar, menu item or from the Action list
-- the function will return edit cursor pos
local cur_pos = want_mrkr and Get_Mouse_Or_Edit_Curs_Pos()

-- only for regions
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false

st = want_mrkr and cur_pos or st
fin = want_mrkr and 0 or fin

local err = not want_mrkr and st == fin and 'no active time selection'
or (below or above) and not sel_obj_lane and 'no visible selected \n\n   markers/regions'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return end

local idx = r.AddProjectMarker(0, not want_mrkr, st, fin, '', -1)	-- name empty, wantidx -1, i.e. auto // returns user facing index

-- get timeline index
local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(i)
		if (want_mrkr and not isrgn or not want_mrkr and isrgn) and num == idx
		then idx = i break end
	i=i+1
	until retval == 0 -- until no more markers/regions

local obj = r.GetRegionOrMarker(0, idx, '') -- guidStr is empty string, i.e. getting by index

local ruler_h = r.GetSetProjectInfo(0, 'RULER_HEIGHT', 0, false) -- isSet false

--r.PreventUIRefresh(1)
r.Undo_BeginBlock()
local lane_idx = r.GetSetProjectInfo(0, 'RULER_LANE_ORDER:0', -1, true) -- value -1 to create new at lane_idx, is_set true
r.UpdateTimeline() -- refresh UI for the changes to display immediately
r.SetRegionOrMarkerInfo_Value(0, obj, 'I_LANENUMBER', lane_idx)
	if top and lane_idx ~= 0 then
	r.GetSetProjectInfo(0, 'RULER_LANE_ORDER:'..lane_idx, 0, true) -- value 0 to move to top positon, is_set true
	elseif sel_obj_lane then
	local targ_lane_idx = above and sel_obj_lane or sel_obj_lane+1
	r.GetSetProjectInfo(0, 'RULER_LANE_ORDER:'..lane_idx, targ_lane_idx, true) -- is_set true
	end
r.Undo_EndBlock(scr_name,-1)
--r.PreventUIRefresh(-1)
r.UpdateTimeline() -- NOT ALWAYS RELIABLE, DOESN'T PROPERLY REFRESH RULER SIZE WHEN LANES ARE RELATIVELY SHORT

	if r.GetSetProjectInfo(0, 'RULER_HEIGHT', 0, false) == ruler_h then -- isSet false
	Set_Ruler_Height() -- when new lane is added via API and moved to top Ruler height doesn't get updated UNLESS UpdateTimeline() works
	end

return true

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Insert marker or region on a new lane_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not



--[[-------- NAME TESTING -------------
local t = {
'Insert marker on a new lane at the bottom',
'Insert region on a new lane at the bottom',
'Insert marker on a new lane at the top',
'Insert region on a new lane at the top',

'Insert marker on a new lane below the lane of first selected marker, region',
'Insert region on a new lane below the lane of first selected marker, region',
'Insert marker on a new lane above the lane of first selected marker, region',
'Insert region on a new lane above the lane of first selected marker, region'
}
scr_name = t[7]
--]]------------------------------------



local elm1, elm2, elm3, elm4, elm5, elm6, elm7 = 'insert ', 'marker', 'region', 'bottom', 'top', 'below', 'above'

	if not Invalid_Script_Name(scr_name, elm1..elm2, elm1..elm3)
	or not Invalid_Script_Name(scr_name, elm4, elm5, elm6, elm7)
	then return r.defer(no_undo) end

	if not Insert_Mrkr_Region_On_Lane_X(scr_name) then -- error message
	return r.defer(no_undo) end



