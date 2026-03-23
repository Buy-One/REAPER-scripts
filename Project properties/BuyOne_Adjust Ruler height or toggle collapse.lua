--[[
ReaScript name: BuyOne_Adjust Ruler height or toggle collapse.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v7.62
Provides: [main=main,midi_editor] .
About: 	When the script is executed with a mouse click 
		or a keyboard shortcut it toggles the Ruler
		height between fully collapsed and uncollapsed
		in the amount needed for all non-hidden lanes 
		to be shown.
		
		When executed with mousewheel/trackball/MIDI/OSC
		it changes Ruler height incrementally depending
		on the STEP_SIZE setting below.
		
		The script can be simultaneoulsy bound to both, 
		keyboard shortcut and the mousewheel with or 
		without modifier keys.
]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Step size in pixels for in/decrementing the Ruler height
-- with mousewheel/trackball/MIDI/OSC,
-- if empty defaults to 3 px which seems optimal
STEP_SIZE = ""

-- By default motion downwards (inwards, leftwards)
-- decreases the height, motion upwards (outwards, righttwards)
-- increases it,
-- enable by inserting any alphanumeric character
-- between the quotes to reverse mousewheel/trackball/MIDI/OSC
-- direction
REVERSE = ""

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


function no_undo()
do return end
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



function validate_positive_integer(int)
return tonumber(int) and math.floor(math.abs(int+0))
end



function Set_Ruler_Height()

	-- only supported since build 7.62
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 then return end

local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local amount
local GetSet = r.GetSetProjectInfo
local h = GetSet(0, 'RULER_HEIGHT', 0, false) -- isSet false

	if mode == 0 or contextstr:match('key:') then -- mouse click or keybpard shortcut
	local lane_cnt = Get_Ruler_Lane_Count()
	local collapsed, ref_lane_idx --, hidden -- ONLY USED IN THE INEFFICIENT METHOD OF UNCOLLAPSING BELOW
		-- filter out hidden lanes
		for i=0, lane_cnt-1 do
			if GetSet(0, 'RULER_LANE_HIDDEN:'..i, 0, false) == 0 then -- is_set false
			collapsed = collapsed or GetSet(0, 'RULER_LANE_VISIBLE:'..i, 0, false) == 0
			ref_lane_idx = i
			end
			if collapsed then break end
		end

		if lane_cnt > 1 then
			if not collapsed then
			GetSet(0, 'RULER_HEIGHT', 0, true) -- isSet true
			else
			local i = 0
			r.PreventUIRefresh(1)
				repeat
				h = GetSet(0, 'RULER_HEIGHT', h+1, true) -- isSet true
				i=i+1
				until GetSet(0, 'RULER_LANE_VISIBLE:'..ref_lane_idx, 0, false) == 1
			r.PreventUIRefresh(-1)
			end
		end
	elseif mode == 1 or math.abs(15) or contextstr:match('wheel:')
	or contextstr:match('mt[vhr]+') then -- mousewheel/trackball/MIDI/OSC in relative mode
	local step = validate_positive_integer(STEP_SIZE) or 3
	val = REVERSE:match('%S') and val*-1 or val
	amount = val < 0 and h-step or val > 0 and h+step
-- OR
--	amount = h + (val < 0 and step*-1 or val > 0 and step)
	end

	if amount then
	r.GetSetProjectInfo(0, 'RULER_HEIGHT', amount, true) -- isSet true
	end

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if REAPER_Ver_Check(7.62, 1) -- want_later true
	then return r.defer(no_undo) end

Set_Ruler_Height()

do return r.defer(no_undo) end -- ruler size change isn't registered with the undo state



