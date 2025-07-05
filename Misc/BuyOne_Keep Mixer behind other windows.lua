--[[
ReaScript name: BuyOne_Keep Mixer behind other windows.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The use case for this script is mixing with open and
			floating Mixer and preventing the Mixer window from 
			obscuring floating plugin windows when it or the MCP 
			is brought into focus, by automatically pushing it to 
			background. Because using pin in the plugin windows 
			to make them float on top of the Mixer could get tedious 
			when there're lots of them.

			The script doesn't differentiate between plugin and other
			type of windows therefore all windows receive priority
			over the Mixer window.

			When track label slot is activated for keyboard input the 
			Mixer window isn't pushed to the background. The track label
			slot can be deactivated and Mixer window sent to the background
			with double click on another MCP, by bringing another window 
			into focus with mouse click or by pressing Enter key.

			Once launched the script runs in the background. To terminate
			it launch it again.
]]


local r = reaper

function no_undo()
do return end
end

function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
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


function run()
local mixer, is_docked = r.BR_Win32_GetMixerHwnd()
local focused_wnd = mixer and r.BR_Win32_GetFocus()
local parent = focused_wnd and r.BR_Win32_GetParent(focused_wnd) -- in case MCP is focused

last_focused = focused_wnd ~= mixer and parent ~= mixer and focused_wnd or last_focused -- store handle of the focused window which isn't the Mixer and isn't MCP (whose parent window is Mixer)

	if mixer and (focused_wnd == mixer or parent == mixer) and not is_docked then -- move Mixer to the backround as soon as it or the MCP is brought into focus, because window is moved to the foreground as soon as it becomes focused
	local retval, lt, t, rt, b = r.BR_Win32_GetWindowRect(mixer)
	local main = r.BR_Win32_HwndToString(r.GetMainHwnd())
	r.BR_Win32_SetWindowPos(mixer, main, lt, t, rt-lt, b-t, 0) -- flags are 0, not needed, but if they were used they should have been 0x0001 SWP_NOSIZE to retain the current size ignoring the width and height values, e.g. r.BR_Win32_SetWindowPos(mixer, main, lt, t, 0, 0, 0x0001)
	r.BR_Win32_SetFocus(last_focused) -- restore focus to the window which was in focus immediately before the Mixer
	end
r.defer(run)
end


Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

	if not r.BR_Win32_GetFocus then
	Error_Tooltip('\n\n the sws/s&m extension\n\nisn\'t installed \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

	if r.set_action_options then r.set_action_options(1) end -- terminate without ReaScript task control dialogue

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
Re_Set_Toggle_State(sect_ID, cmd_ID, 1)
local last_focused


run()


r.atexit(function() Re_Set_Toggle_State(sect_ID, cmd_ID, 0) end)




