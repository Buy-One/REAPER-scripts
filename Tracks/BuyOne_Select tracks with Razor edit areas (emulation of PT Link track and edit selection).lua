--[[
ReaScript name: BuyOne_Select tracks with Razor edit areas (emulation of PT Link track and edit selection).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Improved track selection consistency when left mouse button 
			is clicked while the mouse cursor is over Arrange
Licence: WTFPL
REAPER: at least v5.962
Extensions: js_ReaScriptAPI recommended for better performance
Provides: [main] .
About: 	The script is an emulation of a Pro Tools feature
		'Link track to edit selection'.  
		It selects track as soon as razor edit area is created 
		on it and deslects it as soon as one is cleared.

		Once launched the script runs in the background. If linked
		to a toolbar button or a menu item these will be lit or
		checkmarked respectively. To terminate the script launch it
		again. This offers toggle behavior similar to the said 
		Pro Tools feature.

		One quirk of the script stemming from the ReaScript API 
		is that tracks with razor edit areas on them get temporarily 
		deselected for as long as left mouse button is depressed 
		while the mouse cursor hovers over the Arrange. Once 
		released the selection is reinstated.  
		Having js_ReaScriptAPI installed helps to fix this behavior.
		When installed, tracks do not get deselected in response
		to left mouse click over Arrange. The tradeoff is that when 
		razor edit area position or vertical boundaries are changed 
		with left mouse drag, tracks on which Razor edit area is 
		cleared are only deselected once left mouse button is released.

		See USER SETTINGS
]]



-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- When enabled, selection of tracks with razor edits
-- is exclusive, i.e. tracks without razor edit areas
-- will be unselectable, tracks with cleared razor edit
-- areas and those which were selected when the script
-- was just launched will be deselected;
-- if disabled, other tracks can be selected as normal
EXCLUSIVE = "1"

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


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function Cleanup()
-- clear extended data
	for i=0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0, i)
	r.GetSetMediaTrackInfo_String(tr, 'P_EXT:LINK_TRACK_AND_EDIT_SELECTION','', true) -- setNewValue true
	end
end


function SELECT()
-- One quirk is that razor edit tracks get temporarily deselected as long as left mouse button is depressed
-- while the mouse cursor is over a razor edit area
-- because in this scenario the function GetSetMediaTrackInfo_String() returns empty razor edit data
-- which the script relies on, so having not detected such data it deselects tracks
-- https://forum.cockos.com/showthread.php?t=308465
-- fixed by preventing track selection update for as long as left mouse button is depressed
-- and mouse cursor is located within Arrange
	for i=0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0, i)
	local ret, exist = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS','',false) -- setNewValue false
	local exist = #exist > 0
	local ret, RE = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:LINK_TRACK_AND_EDIT_SELECTION', '', false) -- setNewValue false
	local RE_track = #RE > 0
	local is_sel = r.IsTrackSelected(tr)
		if not r.JS_Mouse_GetState or r.JS_Mouse_GetState(1) ~= 1 then -- only change selection state when there's no left mouse click as a means to overcome the problem described at the start of the function
			if EXCLUSIVE and exist ~= is_sel then -- don't run when the selection state already matches the status
			r.SetTrackSelected(tr, exist) -- toggle, select track with razor edit areas and deselect without
			elseif RE_track or exist then -- either former or current razor edit area track; if former, it will be deselected and the extended data will be cleared
			local status = RE_track and not exist and '' or exist and '1' -- if former razor edit area track without active razor edits, the extended data will be cleared
				if status == '' or not RE_track then -- update track extended data depending on the presence of razor edit areas
				r.GetSetMediaTrackInfo_String(tr, 'P_EXT:LINK_TRACK_AND_EDIT_SELECTION', status, true) -- setNewValue true
				end
			-- de/select tracks with razor edit areas, leaving other tracks selected
			status = status == '1'
				if status ~= is_sel then -- don't run when the selection state already matches the status
				r.SetTrackSelected(tr, status)
				end
			end
		end
	end
r.defer(SELECT)
end



	-- ensure ability to terminate script without ReaScript task control dialogue
	if r.set_action_options then
	r.set_action_options(1)
	end

	
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()	
 
Re_Set_Toggle_State(sect_ID, cmd_ID, 1) -- set toggle state to On

EXCLUSIVE = EXCLUSIVE:match('%S')

SELECT()

-- set toggle state to Off, do a cleanup as necessary
r.atexit(function() return Re_Set_Toggle_State(sect_ID, cmd_ID, 0), not EXCLUSIVE and Cleanup() end)

