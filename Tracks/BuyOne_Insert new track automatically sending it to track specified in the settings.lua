--[[
ReaScript name: BuyOne_Insert new track automatically sending it to track specified in the settings.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: v1.1 #Additional SEND_MODE error proofing
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: Configure USER SETTINGS
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of the destination bus track
DESTINATION_TRACK_NAME = ""

-- Between the quotes insert the number corresponding to the send mode:
-- 1 - post-fader (post-pan), 2 - pre-fader (pre-fx), 3 - pre-fader (post-fx)
-- if not set or invalid, defaults to 1
SEND_MODE = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function no_undo()
do return end
end

function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end

local x, y = r.GetMousePosition()

DESTINATION_TRACK_NAME = DESTINATION_TRACK_NAME:match('^%s*(.-)%s*$') -- stripping leading & trailing spaces


	if #DESTINATION_TRACK_NAME == 0 then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACK NAME \n\n      SETTING IS EMPTY'):gsub('.','%0 ')
	..' \n\n ', x, y, true) -- topmost true
	return r.defer(no_undo) end

local bus_tr

	for i=0,r.GetNumTracks()-1 do --find the bus track
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
		if name:match('^%s*'..Esc(DESTINATION_TRACK_NAME)..'%s*$') -- stripping leading & trailing spaces
		then bus_tr = tr break end 
	end

	if not bus_tr then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACK WASN\'T FOUND'):gsub('.','%0 ')
	..' \n\n ', x, y, true) -- topmost true
	return r.defer(no_undo) end

SEND_MODE = tonumber(SEND_MODE) or 1 -- default to 1 (post-fader)
SEND_MODE = (SEND_MODE > 0 and SEND_MODE < 3) and SEND_MODE-1 or SEND_MODE > 3 and 1 or SEND_MODE -- -1 to conform to 0-based index of post-fader (0) and pre-fx (1), excluding illegal numbers

r.Undo_BeginBlock()

r.Main_OnCommand(40001,0) -- Track: Insert new track // will be exclusively selected

	for i=0, r.CountSelectedTracks(0)-1 do -- the tracks inserted with action are always exclusively selected
	local tr = r.GetSelectedTrack(0,i)
	r.CreateTrackSend(tr, bus_tr)
	r.SetTrackSendInfo_Value(tr, 0, 0, 'I_SENDMODE', SEND_MODE) -- category 0 (send), sendidx 0,
	end


r.Undo_EndBlock('Insert track sending it to track "'..DESTINATION_TRACK_NAME..'"', -1)


















