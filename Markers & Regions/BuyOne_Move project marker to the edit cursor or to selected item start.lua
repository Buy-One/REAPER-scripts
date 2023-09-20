--[[
ReaScript name: BuyOne_Move project marker to the edit cursor or to selected item start.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	REAPER only offers actions to move markers 1 - 10 to the edit cursor.
	The script overcomes this limitation and enhances the functionality
	by allowing moving a marker to the start of the first selected item. 

	In REAPER marker/region position in their properties is shown in beats 
	rather than in milliseconds. The edit cursor position in beats can be 
	extracted from the 'Jump to time/marker/region' utility by double clicking 
	the Transport. However moving by beats isn't precise therefore action 
	or a script are needed.		
	
	C or c is the target operator for the edit cursor.
	I or i is the target operator for a selected item.
	
	The order of marker number and the operator in the dialogue doesn't
	matter.
	
	Since the script requires user input it may not be suitable for inclusion 
	in custom actions.
	
	If you need to have this functionality inside custom actions, create
	as many Lua files as needed with the following code, specify unique 
	marker number in the MARKER_NUMBER setting, target operator in
	the TARGET setting, and name them accordingly:
	
	------------------------------ START ------------------------------
	
	-- Between the quotes specify marker number to be moved
	-- to the edit cursor
	MARKER_NUMBER = ""
	
	-- Insert target operator between the quotes:
	-- C or c for the edit cursor, I or i for first selected item 
	TARGET = ""
	
	local cursor = TARGET:match('[Cc]+')
	local item = TARGET:match('[Ii]+')
	
	local pos = cursor and reaper.GetCursorPosition()	
	or item and reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0), 'D_POSITION')
	
		if pos then
		reaper.Undo_BeginBlock()

		reaper.SetProjectMarker(MARKER_NUMBER, false, pos, 0, '') -- isrgn false, rgnend 0

		reaper.Undo_EndBlock('Move marker '..MARKER_NUMBER..' to '..(cursor and 'the edit cursor' or item and 'selected item start'), -1)
		end
	
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


::RETRY::
local ret, output = r.GetUserInputs('Specify displayed marker number',1,'Positive integer,extrawidth=100',autofill or '')

output = output:gsub(' ','')

	if not ret or #output == 0 then return no_undo() end

local retval, num_markers, num_regions = r.CountProjectMarkers(0)	
	
local mrkr_num = output:match('[%-%.%d]+')
local mrkr_num = mrkr_num and tonumber(mrkr_num)
local target = output:match('[CcIi]+')
local cursor = target and target:lower():match('c+')
local item = target and target:lower():match('i+')

local err = not mrkr_num and 'no marker number \n\n has been specified'
or (mrkr_num < 0 or mrkr_num ~= math.floor(mrkr_num)) and 'invalid marker number'
or mrkr_num and not target and 'no target operator \n\n  has been specified'
or mrkr_num and cursor and item and 'mixed target operator \n\n    has been specified'
or mrkr_num and num_markers == 0 and 'there\'re no markers \n\n     in the project'
or mrkr_num and item and not r.GetSelectedMediaItem(0,0) and 'no selected item'

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


local pos = cursor and r.GetCursorPosition() or item and r.GetMediaItemInfo_Value(r.GetSelectedMediaItem(0,0),'D_POSITION')

r.Undo_BeginBlock()

r.SetProjectMarker(mrkr_num, false, pos, 0, '') -- isrgn false, rgnend 0

r.Undo_EndBlock('Move marker '..mrkr_num..' to '..(cursor and 'the edit cursor' or item and 'selected item start'), -1)












