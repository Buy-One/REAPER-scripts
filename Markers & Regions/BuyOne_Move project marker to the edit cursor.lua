--[[
ReaScript name: BuyOne_Move project marker to the edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	REAPER only offers actions to move markers 1 - 10 to the edit cursor.
    		The script overcomes this limitation.  
    		
    		Marker and region position in their properties is shown in beats rather
    		than milliseconds. The edit cursor position in beats can be extracted
    		from the 'Jump to time/marker/region' utility by double clicking the Transport.
    		However moving by beats isn't precise therefore action or a script are needed.		
    		
    		Since the script requires user input it may not be suitable for inclusion 
    		in custom actions.
    		
    		If you need to have this functionality inside custom actions, create
    		as many Lua files as needed with the following code, specify unique 
    		marker number in the MARKER_NUMBER setting, and name them accordingly:
		
		------------------------------ START ------------------------------
		
		-- Between the quotes specify marker number to be moved
		-- to the edit cursor
		MARKER_NUMBER = ""
		
		local cursor_pos = r.GetCursorPosition()		
		
		r.Undo_BeginBlock()

		r.SetProjectMarker(MARKER_NUMBER, false, cursor_pos, 0, '') -- isrgn false, rgnend 0

		r.Undo_EndBlock('Move marker '..MARKER_NUMBER..' to the edit cursor', -1)
		
		------------------------------- END --------------------------------
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


local function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end

function no_undo()
do return end
end


local retval, num_markers, num_regions = r.CountProjectMarkers(0)

	if num_markers == 0 then
	Error_Tooltip('\n\n there\'re no markers \n\n     in the project \n\n', 1, 1) -- caps and spaced are true
	return no_undo() end

::RETRY::
local ret, output = r.GetUserInputs('Specify displayed marker number',1,'Positive integer,extrawidth=100',autofill or '')

output = output:gsub(' ','')

	if not ret or #output == 0 then return no_undo() end

mrkr_num = tonumber(output)
local err = (not mrkr_num or mrkr_num < 0 or mrkr_num ~= math.floor(mrkr_num)) and 'invalid input'

	if not err then
	local found
		for i=0, num_markers-1 do
		local retval, isrgn, pos, rgnend, name, idx = r.EnumProjectMarkers(i)
			if idx == mrkr_num then found = 1 break end
		end
		if not found then err = 'the marker number isn\'t found' end
	end

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps and spaced are true
	autofill = output
	goto RETRY
	end


local cursor_pos = r.GetCursorPosition()

r.Undo_BeginBlock()

r.SetProjectMarker(mrkr_num, false, cursor_pos, 0, '') -- isrgn false, rgnend 0


r.Undo_EndBlock('Move marker '..output..' to the edit cursor', -1)












