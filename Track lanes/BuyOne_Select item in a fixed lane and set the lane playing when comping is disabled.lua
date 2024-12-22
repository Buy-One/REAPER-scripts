--[[
ReaScript name: BuyOne_Select item in a fixed lane and set the lane playing when comping is disabled.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: 7
About: 	Meant to allow simultaneous item selection and lane playback
	activation.  
	Can be bound to the left mouse click in the 'Media item'
	context of Mouse modifiers. There's no native way to bind 
	the action 'Track lanes: Play only lane under mouse' to
	a mouse modifier because there's no context for fixed
	lanes outside of comping mode.
]]

local r = reaper

local Debug = "1"
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
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


function no_undo()
do return end
end


function Fixed_Lanes_State(tr)
--[[
FIXEDLANES 9 0 0 0 0 -- Big Lanes (lanes maximized)
FIXEDLANES 9 0 2 0 0 -- lanes collapsed (imploded) down to one visible lane, option 'Fixed item lanes' is disabled
FIXEDLANES token is absent if Small Lanes (lanes minimized)
FIXEDLANES 33 0 0 0 0 -- Small Lanes + Hide Lane Buttons
FIXEDLANES 41 0 0 0 0 -- Big Lanes + Hide Lane Buttons
LANESOLO 8 0 0 0 0 0 0 0 -- absent in track with no lanes, same as r.GetMediaTrackInfo_Value(tr, 'I_FREEMODE') ~= 2
]]
local ret, chunk = r.GetTrackStateChunk(tr, '', false) -- isundo false
return chunk:match('LANEREC [%-%d]+ 0 [%-%d]+'), -- when disabled the 2nd flag is -1
not chunk:match('FIXEDLANES %d %d 2 %d %d')
end


Error_Tooltip('') -- clear any stuck tooltops

local x, y = reaper.GetMousePosition()
local item, take = reaper.GetItemFromPoint(x, y, false) -- allow_locked false

	if not item then
	Error_Tooltip('\n\n no item under mouse \n\n', 1, 1, 50) -- caps, spaced true, x2 is 100
	return r.defer(no_undo) end

	if item then
	local item_tr = reaper.GetMediaItemTrack(item)
	local fixed_lanes_on = reaper.GetMediaTrackInfo_Value(item_tr, 'I_FREEMODE') == 2 -- 2 is track fixed lanes enabled
	local comping_on, imploded_lanes = Fixed_Lanes_State(item_tr)
	local err = not fixed_lanes_on and 'fixed lane mode \n\n  is not enabled'
	or comping_on and 'comping is enabled' -- this mess will only be generated if the script is run with a shortcut rather than via a mouse click because when comping is enabled GetItemFromPoint() is blocked and item will be nil
--	or imploded_lanes and 'the fixed lanes are imploded' -- excluded because if more than one lane is enabled for playback, items from all will be avalable in the imploded mode so it will still be possible to activate just one lane
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 50) -- caps, spaced true, x2 is 100
		return r.defer(no_undo) end
	reaper.Main_OnCommand(42478,0) -- Track lanes: Play only lane under mouse
	end




