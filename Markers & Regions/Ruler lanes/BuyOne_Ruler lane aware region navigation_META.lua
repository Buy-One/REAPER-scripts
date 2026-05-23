--[[
ReaScript name: BuyOne_Ruler lane aware region navigation_META.lua (22 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Improved ruler height update when new lane is added
Licence: WTFPL
REAPER: at least v7.62
Provides: [main=main,midi_editor] .
		. > BuyOne_Go to next region on lane 1 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 2 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 3 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 4 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 5 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 6 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 7 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on lane 8 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 1 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 2 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 3 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 4 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 5 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 6 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 7 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on lane 8 after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to next region on the same lane after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to previous region on the same lane after current region finishes playing (smooth seek).lua
		. > BuyOne_Go to first selected region after current region finishes playing (smooth seek).lua
		. > BuyOne_Set loop points to next region on the same lane.lua
		. > BuyOne_Set loop points to previous region on the same lane.lua
		. > BuyOne_Set loop points to selected region.lua
About: 	If this script name is suffixed with META, when
		executed it will automatically spawn all individual
		scripts included in the package into the directory
		of the META script and will import them into the
		Action list from that directory.

		If there's no META suffix in this script name it will
		perfom the operation indicated in its name.

		In scripts targeting regions on the same lane, if start
		and end points of regions on different lanes overlap,
		the lane of the target region will be determined relative 
		to the current region with the greatest number.		

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
-- if Debug then - ONLY IF CONDITIONED BY SCRIPT NAME
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
			for _, sectID in ipairs{0,32060,32063} do -- Main, MIDI Ed, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end



function no_undo()
do return end -- unnecessary
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
			if scr_name:lower():match(elm:lower()) then return elm end -- at least one match was found
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



function set_loop_direction(st, fin, condition) -- used in Get_Next_or_Prev_or_Sel_Region()
-- condition being true sets descending loop order (i.e. in reverse);
-- returns start, end and direction
return table.unpack(not condition and {st, fin, 1} or {fin, st, -1})
-- OR
-- local a, b = not condition and math.min or math.max, not condition and math.max or math.min
-- return a(st, fin), b(st, fin), b(1, -1)
--[[ -- OR
a, b = math.min, math.max
	if condition then a, b = b, a end
return a(st, fin), b(st, fin), b(1, -1)
--]]
end



function Get_Next_or_Prev_or_Sel_Region(reg_idx, lane_idx, nxt, selected)

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local cur_reg = r.GetRegionOrMarker(0, reg_idx, '') -- playing region
local cur_reg_lane = Get(0, cur_reg, 'I_LANENUMBER')

local st, fin, dir = set_loop_direction(0, r.GetNumRegionsOrMarkers(0)-1, not nxt and not selected)
local retval, num_markers, reg_cnt = r.CountProjectMarkers(0)
local reg_cnt = not nxt and not selected and reg_cnt+1 or 0 -- since the main function GoToRegion() only respects 1-based region count, ignoring markers, count regions so that the resulting index is relevant to regions, because i and retval variables in the loop below give global index relevant to both markers and regions // respecting the loop direction // +1 to prevent reduction of the last region index at the first cycle of the reverse loop

	for i=st, fin, dir do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(i)
	reg_cnt = isrgn and reg_cnt + (not nxt and not selected and -1 or 1) or reg_cnt
	local obj_lane_idx = Get(0, obj, 'I_LANENUMBER')
		-- evaluate region order
		if isrgn and (nxt and i > reg_idx or not nxt and not selected and i < reg_idx or selected and Get(0, obj, 'B_UISEL') == 1) -- not nxt and not selected means previous
		and Get(0, obj, 'B_VISIBLE') == 1 -- B_VISIBLE is also false when the entire lane is hidden
		-- evaluate region lane
		and (lane_idx and obj_lane_idx+1 == lane_idx+0 -- +1 because internal lane indices are 0-based, +0 to convert string to numeral
		or not lane_idx and not selected and obj_lane_idx == cur_reg_lane
		or selected)
	--	and r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..obj_lane_idx, 0, false) == 0 -- isSet false // the attribute works without the colon as well // essentially redundant because B_VISIBLE is also false when the entire lane is hidden
		then
		return reg_cnt, pos, rgnend
		end
	end

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Ruler lane aware region navigation_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[-------- NAME TESTING -------------
local t = {
'Go to next region on lane 1 after current region finishes playing (smooth seek)',
'Go to previous region on lane 1 after current region finishes playing (smooth seek)',
'Go to next region on the same lane after current region finishes playing (smooth seek)',
'Go to previous region on the same lane after current region finishes playing (smooth seek)',
'Go to first selected region after current region finishes playing (smooth seek)',
'Set loop points to next region on the same lane',
'Set loop points to previous region on the same lane',
'Set loop points to selected region'
}
scr_name = t[7]
--]]------------------------------------


	if not Invalid_Script_Name(scr_name, 'next', 'previous', 'selected')
	or not Invalid_Script_Name(scr_name, 'lane %d+', 'same lane', 'selected')
	then return r.defer(no_undo) end


local markeridx, reg_idx = r.GetLastMarkerAndCurRegion(0, r.GetPlayState() > 0 and r.GetPlayPosition() or r.GetCursorPosition()) -- GetPlayPosition() returns last tored play position if the transport doesn't run

	if reg_idx == -1 then
	Error_Tooltip('\n\n current region wasn\'t found \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local lane_idx = scr_name:match('lane (%d+)')
local nxt = scr_name:match('next')
local selected = scr_name:match('selected')
local target_rgn_idx, st, fin = Get_Next_or_Prev_or_Sel_Region(reg_idx, lane_idx, nxt, selected)

	if not target_rgn_idx then
	Error_Tooltip('\n\n '..(nxt and (' '):rep(lane_idx and 0 or not selected and 4)..nxt or selected or 'previous')
	..' region \n\n '..(lane_idx and (' '):rep(nxt and 3 or 5)..'on lane '..lane_idx
	or not selected and 'on the same lane' or '')
	..(selected and '' or' \n\n ')..(nxt and (' '):rep(lane_idx and 0 or not selected and 3) or (' '):rep(2))..'wasn\'t found \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

	if scr_name:match('loop points') then
	r.Undo_BeginBlock()
	r.GetSet_LoopTimeRange(true, true, st, fin, false) -- isSet true, isLoop true, allowautoseek false
	r.Undo_EndBlock(scr_name, -1)
	else
	r.GoToRegion(0, target_rgn_idx, true) -- +1 because the function respects 1-based indexing, use_timeline_order is true because target_rgn_idx is a timeline index // ONLY COUNTS REGIONS, MARKERS ARE IGNORED SO INDEX MUST BE RELATIVE TO OTHER REGIONS
	end

do return r.defer(no_undo) end

