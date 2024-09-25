--[[
ReaScript name: BuyOne_Transcribing A - Go to segment marker.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1 #Updated script name
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing A workflow set of scripts
	alongside
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua  
	BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua  
	BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua

	It's a kind of the opposite of the script  
	'BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua'
	
	Select the time stamp in the track Notes (it can be double clicked),
	copy it into the buffer with Ctrl/Cmd+C or from the right click
	context menu and run the script.	
	
	The script doesn't create an undo point.
	
	If the script is followed by the custom action 
	(included with the script set in the file 
	'Transcribing workflow custom actions.ReaperKeyMap' ):
	
	Custom: Create loop points between adjacent project markers (place edit cursor between markers or at the left one)  
	  Time selection: Remove (unselect) time selection and loop points  
	  View: Move cursor right 8 pixels  
	  Markers: Go to previous marker/project start  
	  Loop points: Set start point  
	  Markers: Go to next marker/project end  
	  Loop points: Set end point  
	  Markers: Go to previous marker/project start
	  
	within another custom action then in addition to jumping 
	to marker, loop points can be set to the relevant segment.
]]


local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
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



function Go_To_Segment_Marker()

local parse = r.parse_timestr
local clipboard = r.CF_GetClipboard()
local pos = clipboard:match('%d+:%d+:%d+%.%d+')
local err = #clipboard:gsub('[%s%c]','') == 0 and 'the clipboard is empty'
or not pos and 'no time stamp in the clipboard'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return end

r.SetEditCurPos(parse(pos), true, false) -- moveview true, seekplay false

local mrkr_name
local i = 0
	repeat
	local retval, isrgn, mrkr_pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
		if retval > 0 and not isrgn --and (parse(name) ~= 0 or name == '00:00:00.000')
		and parse(pos) == mrkr_pos
		then mrkr_name = name break
		end
	i=i+1
	until retval == 0

local err = not mrkr_name and 'there\'s no segment marker \n\n   at the target location'
or parse(mrkr_name) == 0 and mrkr_name ~= '00:00:00.000' and '\t  the marker name \n\n doesn\'t contain time stamp'
or mrkr_name ~= pos and '\t  the time stamp\n\n      in the marker name\n\n differs from its position'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	end

return true

end


	if not r.CF_GetClipboard then
	Error_Tooltip("\n\n SWS extension isn't installed \n\n", 1, 1) -- caps, spaced true
	return end

	if not Go_To_Segment_Marker() then end


do return r.defer(no_undo) end



