--[[
ReaScript name: BuyOne_Center Arrange view around time selection.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions:
Provides: [main=main,midi_editor] .
About: 	Scrolls the Arrange view until the time selection is
		at its center.  
		If time selection is longer than the Arrange view 
        the script is auto-zooms out the Arrange view to it
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



local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

local time_sel, loop = scr_name:match('time selection'), scr_name:match('loop points')
local start, fin = r.GetSet_LoopTimeRange(false, loop and true or false, 0, 0, false) -- isSet false, allowautoseek false

	if start == fin then
	Error_Tooltip('\n\n '..(time_sel and time_sel..' is' or loop and loop..' are')..' not set \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false, screen_x_start & screen_x_end both 0 = GET
local zoom = r.GetHZoomLevel()
local vert_scrollbar_width = 17/zoom
end_time = end_time - vert_scrollbar_width -- offsetting vertical scrollbar witdh included in end_rime value despite not being part of the effective Arrange width, so that center is calculated between start and end of the visible part of the Arrange

local length_diff = end_time - start_time <= fin - start -- time selection / loop is longer than visible time lime

	-- Zoom out to time selecttion / loop
	-- Placed here to continue to scroll routine after zooming
	-- because scroll position adjustment may be required
	if length_diff then -- if time selection / loop length is greater than Arrange width, zoom out to fit them within visible time line
	-- zoom out to time selection / loop, depending on the script
	reaper.GetSet_ArrangeView2(0, true, 0, 0, start, fin) -- isSet true
	local zoom = r.GetHZoomLevel() -- get new zoom level after setting Arrange view zoom to time selection / loop, because it has changed
	local offset = 100/zoom -- calculate time per 100 px at current zoom level, ensures consistent gap size at all zoom levels
	-- adjust start/end so that there's gap between Arrangre view start/end and time selection / loop start/end
	-- 'fin' argument doesn't seem to need offset, start offset is allocated to start and end
	-- after the adjustment the gaps combined usually amount to ~75 px
	-- which after scroll state adjustment will be allocated differently between the start and the end
	reaper.GetSet_ArrangeView2(0, true, 0, 0, start-offset, fin) -- isSet true

	-- get new values after setting Arrange view zoom to time selection / loop and adding gap
	-- without exiting the script here because after zoom adjustment scroll position may need to be adjusted as well
	start, fin = r.GetSet_LoopTimeRange(false, loop and true or false, 0, 0, false)
	start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)
	end


local mid_point = start + (fin-start)/2
local zoom = r.GetHZoomLevel()
local vert_scrollbar_width = 17/zoom
end_time = end_time - vert_scrollbar_width -- offsetting vertical scrollbar witdh included in end_rime value despite not being part of the effective Arrange width, so that center is calculated between start and end of the visible part of the Arrange
local view_center = start_time + (end_time - start_time)/2
local distance = view_center - mid_point
local px_to_sroll = math.abs(distance*zoom)

	if length_diff and (mid_point == view_center or px_to_sroll <= 16) then return r.defer(no_undo) end -- already at the center

local proj_len = r.GetProjectLength(0)
local atrr, be = time_sel and (' '):rep(4)..time_sel or loop and '\t '..loop, time_sel and 'is' or 'are'
local err = (mid_point == view_center or px_to_sroll <= 16) -- scrolling will move time selection / loop points mid_point farther from the center than it already is, because horiz scroll minimum step in CSurf_OnScroll() is 16 px
and atrr..' \n\n '..be..' already centered'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local xdir = mid_point < view_center and -1 or 1

local i=0
local scrolled_px = 0
r.PreventUIRefresh(1)
	repeat
	r.CSurf_OnScroll(xdir, 0) -- ydir 0
	i=i+1
	until i*16 >= px_to_sroll -- each execution of CSurf_OnScroll() moves horiz scroll position by 16 px, so multiply by the number of loop cycles
r.PreventUIRefresh(-1)

	if xdir < 0 and start_time < distance then -- cannot scroll left past project start to time selecton / loop to the center
	Error_Tooltip('\n\n cannot move view any further \n\n', 1,1) -- caps, spaced true
	end

	do return r.defer(no_undo) end







