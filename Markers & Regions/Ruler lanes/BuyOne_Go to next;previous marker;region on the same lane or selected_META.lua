--[[
ReaScript name: BuyOne_Go to next;previous marker;region on the same lane or selected_META.lua (10 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Improved ruler height update when new lane is added
Licence: WTFPL
REAPER: at least v7.62
Provides: [main=main,midi_editor,mediaexplorer] .
		. > BuyOne_Go to next marker or region on the same lane.lua
		. > BuyOne_Go to previous marker or region on the same lane.lua
		. > BuyOne_Go to next marker on the same lane.lua
		. > BuyOne_Go to previous marker on the same lane.lua
		. > BuyOne_Go to first selected marker or region.lua
		. > BuyOne_Go to first selected marker.lua
		. > BuyOne_Go to next selected marker or region.lua
		. > BuyOne_Go to previous selected marker or region.lua
		. > BuyOne_Go to next selected marker.lua
		. > BuyOne_Go to previous selected marker.lua
About: 	If this script name is suffixed with META, when
		executed it will automatically spawn all individual
		scripts included in the package into the directory
		of the META script and will import them into the
		Action list from that directory.

		If there's no META suffix in this script name it will
		perfom the operation indicated in its name.


		NOTES REGARDING BEHAVIOR OF SCRIPTS WHICH PERFORM
		NAVIGATION BETWEEN MARKERS/REGIONS ON THE SAME LANE

		1. If, when the script is executed, there's no marker 
		or region at the edit cursor, the lane is determined 
		by the lane of the marker/region in which immediately 
		precedes (if moving to next) or immediately follows 
		(if moving to previous) the edit cursor.  
		When there's no such reference marker (or region in 
		relevant scripts), the cursor will be moved to the marker 
		or region closest to the edit cursor in the relevant 
		direction.

		2. If start or end points of markers/regions closest to
		the edit cursor on different lanes overlap, the lane 
		is determined by the lane of the marker/region with the 
		greatest (if moving to next) or smallest (if moving to 
		previous) number.

		3. During playback the scripts will only work reliably 
		if the lane was identified at least once before the 
		playback start. And for the scripts to remain latched 
		onto such lane the playback must start while this 
		particular lane remains the last one identified.  
		All this admittedly is quite clunky, so a more 
		straightforward and reliable alternative could be 
		using one of the scripts included in 
		BuyOne_Toggle exclusive visibility of Ruler lanes_META.lua
		inside a custom action, e.g.

			Custom: Go to next marker on lane 1 / project end
			Script: BuyOne_Toggle exclusive visibility of Ruler lane 1.lua
			Markers: Go to next marker/project end
			Script: BuyOne_Toggle exclusive visibility of Ruler lane 1.lua

			Custom: Go to previous marker on lane 1 / project start
			Script: BuyOne_Toggle exclusive visibility of Ruler lane 1.lua
			Markers: Go to previous marker/project start
			Script: BuyOne_Toggle exclusive visibility of Ruler lane 1.lua

		The first script instance only leaves Ruler lane 1 visible
		which prevents the action 'Markers: Go to next marker/project end'
		from being pulled to a marker/region on any other lane. 
		The second script instance restore the original lane 
		visibility. Be aware that during the custom action 
		execution the Ruler will be jumping as visible lane 
		count changes.

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



function collect_regions_as_markers(want_reverse, time_init)
-- storing regions start and end times separately,
-- instead of traversing them in the timeline order
-- based on their start point
-- which results in ealier regions end points getting
-- priority over later regions end points even if
-- later regions end ponints are earlier on the time line
-- as is the case with overlapping or enclosed regions,
-- so instead of looking for the time properties based on
-- the index, run the function and look for the index based
-- on the time properties

local init_pos = init_pos or not want_reverse and 0 or r.GetProjectLength(0)
local i, t = 0, {}
	repeat
	local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(i)
		if retval > 0 and isrgn
		and (want_reverse and (rgnend <= init_pos or pos <= init_pos)
		or not want_reverse and (pos >= init_pos or rgnend >= init_pos))
		then
		table.insert(t,{idx=i, pos=pos})
		table.insert(t,{idx=i, pos=rgnend})
		end
	i=i+1
	until retval == 0

--[[ OR
proj_end = r.GetProjectLength(0)
local init_pos = init_pos or not want_reverse and 0 or proj_end
local t = {seen={}}
	repeat
	local mrkr_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, init_pos)
		if reg_idx > -1 and not t.seen[reg_idx] then -- only unique indices
		local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(reg_idx)
		table.insert(t,{idx=reg_idx, pos=pos})
		table.insert(t,{idx=reg_idx, pos=rgnend})
		t.seen[reg_idx] = ''
		end
	init_pos = init_pos + (not want_reverse and 0.1 or -0.1) -- decrement by 100 ms
	until not want_reverse and init_pos >= proj_end or init_pos <= 0
--]]

table.sort(t,
function(a, b) return want_reverse and a.pos > b.pos or not want_reverse and a.pos < b.pos end)

return t

end



function Get_Reference_Marker_or_Region(want_next, want_prev, selected, want_mrkr, rgns_t)
-- want_next is boolean, false means previous
-- want_mrkr is boolean, if true, only markers are sought out,
-- otherwise both markers and regions

local Get = r.GetRegionOrMarkerInfo_Value
	if not Get then return end -- only supported since build 7.62
local cur_pos = r.GetCursorPosition()
local retval, mrkr_cnt, reg_cnt = r.CountProjectMarkers(0)
local i = want_next and 0 or want_prev and mrkr_cnt+reg_cnt-1 or selected and 0
local ref_idx, ref_pos

	repeat
	local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(i)
	local obj = r.GetRegionOrMarker(0, i, '')
		if not isrgn and obj then
			if Get(0, obj, 'B_VISIBLE') == 1
			and (not selected or Get(0, obj, 'B_UISEL') == 1)
			and (want_next and pos <= cur_pos or want_prev and pos >= cur_pos or not want_next and not want_prev)
			then
			ref_idx, ref_pos = i, pos
			end
		end
	i = want_next and i+1 or want_prev and i-1 or selected and i+1
	until retval == 0

	if not want_mrkr then

		for k, props in ipairs(rgns_t) do
		local idx, pos = props.idx, props.pos
		local obj = r.GetRegionOrMarker(0, idx, '')
			if obj then
				if Get(0, obj, 'B_VISIBLE') == 1
				and (not selected or Get(0, obj, 'B_UISEL') == 1) then
				pos = want_next and (ref_pos and pos >= ref_pos and pos <= cur_pos
				or not ref_pos and pos <= cur_pos)	and pos
				-- previous
				or want_prev and (ref_pos and pos <= ref_pos and pos >= cur_pos
				or not ref_pos and pos >= cur_pos) and pos
				or not want_next and not want_prev and selected and pos
					if pos then
					ref_idx, ref_pos = idx, pos
					end
				end
			end
		end
	end

return ref_idx, ref_pos

end




function Get_Next_or_Prev_or_Sel_Marker_Pos(ref_idx, ref_pos, nxt, prev, selected, want_mrkr, rgns_t, scr_name)
-- want_mrkr is boolean, if true, only markers are sought out,
-- otherwise both markers and regions

local Get = r.GetRegionOrMarkerInfo_Value

	if not Get then return end -- only supported since build 7.62

-- ref_idx may be nil if there's no reference marker/region,
-- i.e. none to the left of cursor for next and selected and none to the right of cursor for previous
ref_idx = ref_idx or -1
local proj_end, cur_pos = r.GetProjectLength(0), r.GetCursorPosition()
ref_pos = ref_pos or nxt and 0 or prev and (proj_end < cur_pos and cur_pos or proj_end) or selected and 0
local ref_obj = r.GetRegionOrMarker(0, ref_idx, '')

-- store last lane to use it when the transport is in play mode,
-- latching into a particular lane during playback isn't possible otherwise
-- because the playhead passes markers and regions on multiple lanes
-- and detection of current lane in real time will break all consistency
-- as at different points on the time line reference marker/region
-- on different lane will be used
local last_ref_lane = r.GetExtState(scr_name, 'LAST_LANE')
local plays = r.GetPlayState() > 0
local ref_lane = plays and last_ref_lane or ref_obj and Get(0, ref_obj, 'I_LANENUMBER')
ref_lane = tonumber(ref_lane)
	if ref_lane then
	r.SetExtState(scr_name, 'LAST_LANE', ref_lane, false) -- persist false
	end

local retval, mrkr_cnt, reg_cnt = r.CountProjectMarkers(0)
local i = nxt and 0 or prev and mrkr_cnt+reg_cnt-1 or selected and 0
local target_pos

	-- look among markers, next or selected
	repeat
	local retval, isrgn, pos, rgnend, name, num = r.EnumProjectMarkers(i)
	local obj = r.GetRegionOrMarker(0, i, '')
		if not isrgn and obj then
		local lane = Get(0, obj, 'I_LANENUMBER')
			if Get(0, obj, 'B_VISIBLE') == 1
			and (not selected and (not ref_lane or lane == ref_lane) or selected and Get(0, obj, 'B_UISEL') == 1)
			and (nxt and pos > ref_pos or prev and pos < ref_pos or selected and not nxt and not prev) then
			target_pos = pos
			break
			end
		end
	i = nxt and i+1 or prev and i-1 or selected and i+1
	until retval == 0

	if not want_mrkr then -- look among regions as well

		for k, props in ipairs(rgns_t) do
		local idx, pos = props.idx, props.pos
		local obj = r.GetRegionOrMarker(0, idx, '')
			if obj then
			local lane = Get(0, obj, 'I_LANENUMBER')
				if Get(0, obj, 'B_VISIBLE') == 1
				and (not selected and (not ref_lane or lane == ref_lane)
				or selected and Get(0, obj, 'B_UISEL') == 1) then
				pos =
				-- next
				nxt and (target_pos and pos < target_pos and pos > ref_pos
				or not target_pos and pos > ref_pos) and pos
				-- previous
				or prev and (target_pos and pos > target_pos and pos < ref_pos
				or not target_pos and pos < ref_pos) and pos
				or selected and not nxt and not prev and (target_pos and pos < target_pos or not target_pos) and pos
					if pos then target_pos = pos break end
				end
			end
		end
	end

return target_pos, ref_lane and math.floor(ref_lane+1)

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button


	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+_(.+)%.%w+') -- without path, scripter name & ext // suitable for individual scripts

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Go to next;previous marker;region on the same lane_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[-------- NAME TESTING -------------
local t = {
'Go to next marker or region on the same lane',
'Go to previous marker or region on the same lane',
'Go to next marker on the same lane',
'Go to previous marker on the same lane',
'Go to first selected marker or region',
'Go to first selected marker',
'Go to next selected marker or region',
'Go to previous selected marker or region',
'Go to next selected marker',
'Go to previous selected marker',
}
scr_name = t[3]
--]]------------------------------------


	if not Invalid_Script_Name(scr_name, 'next', 'previous', 'selected')
	or not Invalid_Script_Name(scr_name, 'marker')
	then return r.defer(no_undo) end

local nxt, prev = scr_name:match('next'), scr_name:match('previous')
local selected = scr_name:match('selected')
local only_mrkrs = not scr_name:match('region')
local retval, mrkr_cnt, reg_cnt = r.CountProjectMarkers(0)
local err = only_mrkrs and mrkr_cnt == 0 and 'no markers in the project'
or mrkr_cnt+reg_cnt == 0 and 'no markers or regions in the project'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local rgns_t = collect_regions_as_markers(prev) -- want_reverse depends on movenent direction
local ref_idx, ref_pos = Get_Reference_Marker_or_Region(nxt, prev, selected, only_mrkrs, rgns_t)

local target_time, lane = Get_Next_or_Prev_or_Sel_Marker_Pos(ref_idx, ref_pos, nxt, prev, selected, only_mrkrs, rgns_t, scr_name)

	if not target_time then
	local err = selected and 'no '..(nxt or prev or '')..' selected '
	..((nxt or prev) and not only_mrkrs and '\n\n ' or '')
	..(prev and not only_mrkrs and '   ' or '')..'marker'..(only_mrkrs and '' or ' or region')
	or not only_mrkrs and (nxt and '\t no next' or '    no previous')
	..' \n\n marker'..(only_mrkrs and '' or ' or region ')..'\n\n\ton lane '..lane
	or 'no '..(nxt or 'previous')..' marker on lane '..lane
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

r.SetEditCurPos(target_time, true, false) -- moveview true, seekplay false

do return r.defer(no_undo) end

