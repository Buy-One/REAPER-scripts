--[[
ReaScript name: BuyOne_Show next or previous non-empty ruler lane, hide others_META.lua (2 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v7.62
Provides: 	[main=main,midi_editor] .
			. > BuyOne_Show next non-empty ruler lane, hide others.lua
			. > BuyOne_Show previous non-empty ruler lane, hide others.lua
About: 	If this script name is suffixed with META, when executed
		it will automatically spawn all individual scripts included
		in the package into the directory of the META script and will
		import them into the Action list from that directory.

		If there's no META suffix in this script name it will perfom
		the operation indicated in its name.

		When all non-empty lanes are initially hidden, the 'next' script
		will start by unhiding the very 1st non-empty lane while the
		'previous' script will start by unhiding the last one.

		When all non-empty lanes are initially visible, the 'next' script 
		will only leave visible the first non-empty lane while the 
		'previous' script will leave visible the last one.

		While alternating between single lanes the script maintains
		Ruler height.

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end

local r = reaper



function no_undo()
do return end
end



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end



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



function Get_Ruler_Lane_Count()
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
		-- and during the loop will only be able to move to a lane at a lower index
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



function Get_Non_Empty_Ruler_Lanes()

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

local t = {non_empty={},shown={}} -- non_empty nested table is only there to prevent storing the same lane index more than once

	for i=0, r.GetNumRegionsOrMarkers(0)-1 do
	local obj = r.GetRegionOrMarker(0, i, '') -- guidStr is empty string, i.e. getting by index
	local lane_idx = Get(0, obj, 'I_LANENUMBER')
		if not t.non_empty[lane_idx] then
		t.non_empty[lane_idx] = ''
		t[#t+1] = lane_idx
			if r.GetSetProjectInfo(0, 'RULER_LANE_HIDDEN:'..lane_idx, 0, false) == 0 then
			table.insert(t.shown, lane_idx)
			end
		end
	end

-- sort to be able to find the lowest/highest index of the shown lanes
-- and after incrementing it depending on the direction, find the new index
-- among the non-empty lanes
table.sort(t)
table.sort(t.shown)

return t

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Show next or previous non-empty ruler lane, hide others_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[-------- NAME TESTING -------------
local t = {
'Show next non-empty ruler lane, hide others',
'Show previous non-empty ruler lane, hide others',
}
scr_name = t[1]
--]]------------------------------------


	if not Invalid_Script_Name(scr_name, 'next', 'previous')
	then return r.defer(no_undo) end

local t = Get_Non_Empty_Ruler_Lanes()
local err = #t == 0 and 'no non-empty ruler lanes'
or #t == 1 and #t.shown == 1 and 'no other non-empty ruler lanes'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local nxt = scr_name:match(' next')

-- get target lane index
local cur_lane_idx = nxt and t.shown[#t.shown] or t.shown[1] -- when there're visible non-empty lanes go to next/previous relative to the index of the last/first visible non-empty lane
local targ_lane_idx

	if not cur_lane_idx then -- no visible non-empty lanes
	targ_lane_idx = nxt and t[1] or t[#t]
	else -- find next non-empty lane
		for k, lane_idx in ipairs(t) do
			if lane_idx == cur_lane_idx then
			targ_lane_idx = nxt and t[k+1] or not nxt and t[k-1]
			break end
		end
	targ_lane_idx = targ_lane_idx or nxt and t[1] or t[#t] -- if out of range, wrap around to restart from the index of the very first/last non-empty lane, which will be the case when all non-empty lanes are initially visible
	end

local lane_cnt = Get_Ruler_Lane_Count()
local GetSet = r.GetSetProjectInfo
-- only get ruler height when exactly one lane is displayed
-- to restore it, because when a single lane is set visible
-- the ruler height gets auto-adjusted for one lane and doesn't
-- keep its original height;
-- not restoring when mutliple lanes are initially visible
-- because maintaining for a single lane the height meant
-- to accommodate mulitple lanes seems inconsistent
local ruler_h = #t.shown == 1 and GetSet(0, 'RULER_HEIGHT', 0, false)

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

	-- hide irrelevant lanes
	for i=0, lane_cnt-1 do
		if i ~= targ_lane_idx and GetSet(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0 -- is_set false
		then
		GetSet(0, 'RULER_LANE_HIDDEN:'..i, 1, true) -- is_set true // hide
		end
	end

-- can be placed either here or before the loop which hides the rest
GetSet(0, 'RULER_LANE_HIDDEN:'..targ_lane_idx, 0, true) -- is_set true // unhide

	if ruler_h then -- restore
	GetSet(0, 'RULER_HEIGHT', ruler_h, true) -- is_set true
	end

r.Undo_EndBlock(scr_name,-1)
r.PreventUIRefresh(-1)


