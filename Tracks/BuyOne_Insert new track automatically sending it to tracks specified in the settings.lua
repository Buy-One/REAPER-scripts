--[[
ReaScript name: BuyOne_Insert new track automatically sending it to tracks specified in the settings.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: v1.2 #Made the number of destination tracks limitless
		#Added prompt if destination track name is found in more than on track
		#Added user setting to disable master/parent send in the newly inserted track
		#Updated script name to reflect new functionality
		#Updated About text
	   v1.1 #Additional SEND_MODE error proofing			
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	Configure USER SETTINGS
		
	See also 
	BuyOne_Insert multiple new tracks automatically sending them to tracks specified in the settings.lua
	BuyOne_Send selected tracks to track specified in the settings.lua
	BuyOne_Send selected tracks to designated track for monitoring.lua

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the double square brackets insert names 
-- of the destination tracks, one line per track name
DESTINATION_TRACK_NAMES = [[

]]-- keep on a separate line

-- Between the quotes insert the number corresponding to the send mode:
-- 1 - post-fader (post-pan), 2 - pre-fader (pre-fx), 3 - pre-fader (post-fx)
-- if not set or invalid, defaults to 1
SEND_MODE = ""

-- To enable the setting insert any alphanumeric character
-- between the quotes
DISABLE_MASTER_PARENT_SEND = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
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

	if #DESTINATION_TRACK_NAMES:gsub('[%s%c]','') == 0 then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACK NAMES \n\n      SETTING IS EMPTY'):gsub('.','%0 ')
	..' \n\n ', x, y, true) -- topmost true
	return r.defer(no_undo) end
	
-- add trailing line break in case the setting closing square brackets have been moved
-- to the line of the last track name, otherwise the last line won't be captured with the pattern
-- in the gmatch loop below
DESTINATION_TRACK_NAMES = not DESTINATION_TRACK_NAMES:match('.+\n%s*$') and DESTINATION_TRACK_NAMES..'\n' or DESTINATION_TRACK_NAMES

local dest_tr_name_t = {}

		for name in DESTINATION_TRACK_NAMES:gmatch('(.-)\n') do
			if #name:gsub(' ','') > 0 then -- ignoring empty lines
			dest_tr_name_t[#dest_tr_name_t+1] = name
			end
		end

local dest_tr_t = {}

	for i=0,r.GetNumTracks()-1 do -- find the destination tracks
	local tr = r.GetTrack(0,i)
	local retval, tr_name = r.GetTrackName(tr)
		for _, name in ipairs(dest_tr_name_t) do
			if tr_name:match('^%s*'..Esc(name)..'%s*$') then -- stripping leading & trailing spaces
			dest_tr_t[#dest_tr_t+1] = tr
			end
		end
	end


	if #dest_tr_t == 0 then
	r.TrackCtl_SetToolTip('\n\n  '
	..('DESTINATION TRACKS WEREN\'T FOUND'):gsub('.','%0 ')
	..' \n\n ', x, y, true) -- topmost true
	return r.defer(no_undo)
	elseif #dest_tr_t > #dest_tr_name_t then
	local resp = r.MB('    SOME OR ALL DESTINATION TRACKS NAMES\n\n  HAVE BEEN FOUND IN MORE THAN ONE TRACK', 'PROMPT', 1)
		if resp == 2 then -- canceled
		return r.defer(no_undo) end
	end

SEND_MODE = tonumber(SEND_MODE) or 1 -- default to 1 (post-fader)
SEND_MODE = (SEND_MODE > 0 and SEND_MODE < 3) and SEND_MODE-1 or SEND_MODE > 3 and 1 or SEND_MODE -- -1 to conform to 0-based index of post-fader (0) and pre-fx (1), excluding illegal numbers

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local cmd_ID = scr_name:match('multiple new tracks') and 41067 -- Track: Insert multiple new tracks...
or 40001 -- Track: Insert new track
local undo = cmd_ID == 41067 and 'Insert multiple tracks sending them' or 'Insert track sending it'
undo = undo..' to tracks '..table.concat(dest_tr_name_t, '; ')

r.Undo_BeginBlock()

r.Main_OnCommand(cmd_ID,0) -- insert tracks

	for i=0, r.CountSelectedTracks(0)-1 do -- the tracks inserted with action are always exclusively selected
	local tr = r.GetSelectedTrack(0,i)
		for k, dest_tr in ipairs(dest_tr_t) do
		local retval = r.CreateTrackSend(tr, dest_tr)
			if retval > 0 then -- success
			r.SetTrackSendInfo_Value(tr, 0, k-1, 'I_SENDMODE', SEND_MODE) -- category 0 (send), sendidx k-1 because send indices count is 0-based // since the track is new it doesn't have sends therefore table keys can be used for numbering, with existing tracks snds_cnt-1 must be used
				if #DISABLE_MASTER_PARENT_SEND:gsub(' ','') > 0
				and r.GetMediaTrackInfo_Value(tr, 'B_MAINSEND') == 1 then
				r.SetMediaTrackInfo_Value(tr, 'B_MAINSEND', 0)
				end
			end
		end
	end


r.Undo_EndBlock(undo, -1)


