--[[
ReaScript name: BuyOne_Center Arrange view around the edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1	#Excluded vertical scrollbar from Arrange width value
				#Accounted for time selection and loop points in project length
				to prevent scrolling beyond them
Licence: WTFPL
REAPER: at least v5.962
Extensions:
Provides: [main=main,midi_editor] .
About: Scrolls the Arrange view until the edit cursor is at its center
]]



local r = reaper

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t == 1 and tostring(t[1])..'\n' or ''
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


local edit_cur_pos = r.GetCursorPosition()
local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false, screen_x_start & screen_x_end both 0 = GET
local view_center = start_time + (end_time - start_time)/2
local zoom = r.GetHZoomLevel()
local distance = math.abs(view_center - edit_cur_pos)
local px_to_sroll = distance*zoom
local proj_len = r.GetProjectLength(0)

-- It's not trivial to determine available scroll space which is affected by time selection and loop points
-- way beyond nominal project length, so account for time selection and loop points in project length value
-- in order to minimize as much as possible scrolling beyong available scroll space which is allowed
local loop_start, loop_end = r.GetSet_LoopTimeRange(false, true, 0, 0, false) -- isSet false, isLoop true, allowautoseek false
local time_start, time_end = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet false, isLoop false, allowautoseek false
local loop_set, time_set = loop_start ~= loop_end, time_start ~= time_end
local time_loop_end = loop_set and time_set and math.max(loop_end, time_end) or loop_set and loop_end or time_set and time_end
proj_len = time_loop_end > proj_len and time_loop_end or proj_len

local cannot_move = 'cannot move view any further'
local err = (edit_cur_pos == view_center or px_to_sroll <= 16) -- scrolling will move cursor farther from the center than it already is, because horiz scroll minimum step in CSurf_OnScroll() is 16 px
and '\tthe edit cursor \n\n is already at the center'
or start_time > proj_len and cannot_move -- start time is already greater than project length // both CSurf_OnScroll() and stock actions 'View: Scroll horizontally...' and 'View: Scroll view left/right' don't have right scroll limit and will scroll the Arrange even when the scroll bar has reached the end of the scroll track
or edit_cur_pos > view_center and start_time + distance >= proj_len and ' cannot move view \n\n beyond project end' -- cursor is left of view center which will require right scroll to bring it to the center, and start time is still smaller than project length, so prevent infinite right scroll by disallowing scrolling which will otherwise result in project farthest point moving beyond Arrange start time

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local xdir = edit_cur_pos < view_center and -1 or 1

local i=0
local scrolled_px = 0
r.PreventUIRefresh(1)
	repeat
	r.CSurf_OnScroll(xdir, 0) -- ydir 0
	i=i+1
	until i*16 >= px_to_sroll -- each execution of CSurf_OnScroll() moves horiz scroll position by 16 px, so multiply by the number of loop cycles
r.PreventUIRefresh(-1)

	if xdir < 0 and start_time < distance then -- cannot scroll left past project start to bring the edit cursor to the center
	Error_Tooltip('\n\n '..cannot_move..' \n\n', 1,1) -- caps, spaced true
	end

	do return r.defer(no_undo) end







