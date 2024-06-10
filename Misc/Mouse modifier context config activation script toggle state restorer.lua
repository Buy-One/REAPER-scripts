--[[
ReaScript name: Mouse modifier context config activation script toggle state restorer.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: v7.0 and later
About: 	The script is meant to restore on REAPER statrup 
			the toggle state of mouse modifier context config 
			activation scripts exported from the Mouse Modifier 
			section of the Preferences.
			
			It can restore toggle state of specific script instances 
			in the Main, MIDI Editor and MIDI Event List Editor 
			sections of the action list. The two latter if the 
			corresponding settings are enabled in the USER SETTINGS
			of this script.

			This script must be imported into the Main section 
			of the action list and its command ID must be added 
			to the SWS extension Startup actions or alternatively 
			to __startup.lua script which is to be placed in the 
			root of the \Scripts folder under REAPER resource directory.

			For the __startup.lua script the code must look as follows:

			--------------------------------------------

			local command_ID = reaper.NamedCommandLookup("_RSa0a817b9096ab2a5f7f61ca038c60992a3228147") -- !!! REPLACE THE COMMAND ID WITHIN THE QUOTES WITH THAT OF YOUR INSTANCE OF THIS SCRIPT

			reaper.Main_OnCommand(command_ID, 0)

			--------------------------------------------

			The __startup.lua file doesn't need to be imported into the 
			Action list or added to SWS startup actions, it is automatically 
			picked up by REAPER.
			
			
			TO BE ABLE TO USE THIS SCRIPT TO RESTORE TOGGLE STATE
			OF CONTEXT CONFIG ACTIVATON SCRIPTS EXPORTED FROM MOUSE MODIFIERS
			SECTION IN REAPER PREFERENCES some additional code must be 
			incorporated in them as follows:
			
			1. Find the line 'reaper.RefreshToolbar(0)'
			2. Immediately below it add the following line:
			Store_CommandID(is_set)
			3. Find the last word 'end' further down
			4. Add a few empty lines below it and insert the following code
			without the dashed lines:
			
			--------------------------------------------------------------------
			function Store_CommandID(is_set)
			-- store script command ID for restoration with 
			-- 'Mouse modifier context config activation script toggle state restorer.lua' script
			local is_new_val,f_name,sectID,cmdID,mode,resol,val,ctx_str = reaper.get_action_context()
			local MM_CTX
				-- find name of the context this script was exported from
				for line in io.lines(f_name) do
				MM_CTX = line:match('reaper.GetMouseModifier%(\'([%u_]+)')
					if MM_CTX then break end
				end
			local scr_name = f_name:match('.+[\\/](.+)')
			local sect = 'LAST ACTIVE MOUSE MODIFIER CONFIG ACTIVATION SCRIPT PER CONTEXT'
			-- for storage concatenate base named command ID excluding Action list section specific infix
			-- in case the script instance is run from a different Action list section
			-- because reliably only Main section scripts can be run from the API
			-- therefore 'Mouse modifier context config activation script toggle state restorer.lua'
			-- only targets scripts in this section
			local named_cmdID = ('_'..reaper.ReverseNamedCommandLookup(cmdID)):gsub('_RS7d3[c-f]_','_RS')
				if MM_CTX then
					if is_set then -- toggle state set to ON
					reaper.SetExtState(sect, MM_CTX, named_cmdID..' '..scr_name, true) -- persist true
					else
					-- remove this script command ID from storage if its command ID is the last to be stored
					-- at the moment of its toggle state being set to OFF;
					-- this can only happen when mouse modifiers config under the same context 
					-- was changed manually by the user;
					-- in this scenario toggle state of a script, if any, with the matching config
					-- will be auto-set to ON, if there's none the toggle state of all scripts 
					-- with the matching config will be set to OFF
					-- and toggling any of them on startup to ON with the script
					-- 'Mouse modifier context config activation script toggle state restorer.lua'
					-- will be pointless and misleading if command ID of one of them keeps being stored 
					-- in reaper-extstate.ini;
					-- on the other hand, when the mouse modifiers config is changed from another script 
					-- that script command ID becomes the last stored and by the time the equality below
					-- is evaluated the condition will be false, therefore the last stored command ID 
					-- of another script won't be deleted;
					local cmdID_named = reaper.GetExtState(sect, MM_CTX)
						if cmdID == reaper.NamedCommandLookup(cmdID_named) then
						reaper.DeleteExtState(sect, MM_CTX, true) -- persist true
						end
					end
				end
			end

			--------------------------------------------------------------------
				
			Below the line 'SET MOUSE MODIFIERS SCRIPT MIDIFICATION EXAMPLE'
			at the bottom of this script see an example of a complete 
			'Set mouse modifiers' script with the suggested additions applied 
			marked by lines 
			'INSERT THIS LINE HERE START'
			and 
			'INSERT THIS CODE HERE START'				
			
			https://forum.cockos.com/showthread.php?t=284185

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character between the quotes
-- to activate instances of mouse modifier context activation scripts
-- in the MIDI Editor sections of the Action list as well
-- on REAPER startup

MIDI_Editor_section = ""

MIDI_Event_List_section = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	r.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
--[[
-- a time loop can be added to run when certan condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function re_store_sel_trks(t)
-- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do -- not >= 0 because sel_trk_cnt is not reduced by 1, i-1 is on the next line
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- selected 0 or false // unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t --and #t > 0
	then
	r.PreventUIRefresh(1)
--	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	-- deselect all tracks, this ensures that if none was selected originally
	-- none will end up selected because re-selection loop below won't start
	local master = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master) -- select master
	r.SetTrackSelected(master, 0) -- immediately deselect
		for _,v in next, t do
		r.SetTrackSelected(v,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
	end
end


function Set_Toggle_State_To_On(named_cmd_ID, temp_tr)
-- remove action list section specific infix in case the exported
-- mouse modifier config script was toggled by an exported script
-- from Action list section other than the Main,
-- added just in case because the infix is removed at the storage stage
-- in the ancillary Store_CommandID() function to be added
-- to the exported mouse modifier config script
named_cmd_ID = named_cmd_ID:gsub('_RS7d3[c-f]_','_RS')
local cmd_ID = r.NamedCommandLookup(named_cmd_ID) -- convert to numeric command ID
-- if mouse modifier config activation script doesn't have an instance
-- in the Main section of the Action list the above function will return 0
-- and the following function will toggle nothing
	if cmd_ID > 0 then
	-- launch the mouse modifier config activation script
	-- it will set its own toggle state by itself
	r.Main_OnCommand(cmd_ID, 0) -- trigger the mouse modifier config activation script
	end

-- launch the same script instances in the MIDI Editor/Event List sections as well
-- by activating the MIDI Editor on startup

local path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-kb.ini'

-- check if there're script instances in the MIDI Editor / Event List sections
local MIDI_ED_SECT = #MIDI_Editor_section:gsub(' ','') > 0
local EVENT_LIST_SECT = #MIDI_Event_List_section:gsub(' ','') > 0
local midi_instance
	if MIDI_ED_SECT or EVENT_LIST_SECT then
		for line in io.lines(path) do
		-- in reaper-kb.ini command IDs lack leading underscore
		-- hence the replacement string lacks it as well
			if MIDI_ED_SECT and line:match(named_cmd_ID:gsub('_RS', 'RS7d3c_')) -- MIDI Editor section
			or EVENT_LIST_SECT and line:match(named_cmd_ID:gsub('_RS', 'RS7d3d_')) -- MIDI Event List section
			then
			midi_instance = 1 break
			end
		end
	end

	if midi_instance then -- script instance is found in at least one section, MIDI Editor or Event List
	local temp_tr = temp_tr
		if not temp_tr then -- insert temp track and MIDI item to activate the MIDI Editor
		local ACT = r.Main_OnCommand
		r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
		temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
		r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
		-- Must not be hidden in Arrange, otherwise it won't be deleted after opening the MIDI Editor
		--	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange
		r.SetOnlyTrackSelected(temp_tr)
		ACT(40914, 0) -- Track: Set first selected track as last touched track (to make it the target for temp MIDI item insertion)
		ACT(40214, 0) -- Insert new MIDI item...
		ACT(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
		end
		for idx, infix in ipairs({'7d3c', '7d3d'}) do -- trigger script instances in both MIDI sections
		local eventlist_active = r.GetToggleCommandStateEx(32061, 40056) == 1 -- Mode: Event List
		-- OR
		-- r.GetToggleCommandStateEx(32061, 40056) == 1
		local infix = idx == 1 and (MIDI_ED_SECT and infix or '') or EVENT_LIST_SECT and infix or '' -- make infix of the section disabled in the USER SETTINGS to be empty string so that no valid command ID could be extracted and 'cmd_ID > 0' condition below would be false
		local named_cmd_ID = named_cmd_ID:gsub('_RS','_RS'..infix..'_')
		local cmd_ID = r.NamedCommandLookup(named_cmd_ID)
			if cmd_ID > 0 then
			local sectID = 32059+idx -- either 32060 - MIDI Editor or 32061 - MIDI Event List
			local eventlist = sectID == 32061
				if not eventlist and eventlist_active then -- MIDI Ed section ID is selected in the loop while even list is active
				-- set MIDI Editor mode to Piano roll
				r.MIDIEditor_LastFocused_OnCommand(40042, eventlist_active) -- Mode: Piano roll, eventlist_active boolean depends on the currently active section
				elseif eventlist and not eventlist_active then -- vice versa
				-- set MIDI Editor mode to Event List
				r.MIDIEditor_LastFocused_OnCommand(40056, eventlist_active) -- Mode: Event List, eventlist_active boolean depends on the currently active section
				end
			r.MIDIEditor_LastFocused_OnCommand(cmd_ID, sectID == 32061) -- sectID == 32061 is listview boolean
			end
		end
	return temp_tr
	end

end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7
	then Error_Tooltip('\n\n  the script only works \n\n with reaper 7 and later \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end


-- get stored data related to last script with toggle state set to ON per mouse modifier context
local path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-extstate.ini'
local sect = 'LAST ACTIVE MOUSE MODIFIER CONFIG ACTIVATION SCRIPT PER CONTEXT'
local data_t, ok = {}
	for line in io.lines(path) do
		if line:match(sect) then ok = 1
		elseif ok then
		local new_sect = line:match('%[.+%]')
			if not new_sect then
			data_t[#data_t+1] = line:match('=(.-) ') -- end with space because it separates the ID from the script name
			else break
			end
		end
	end

r.PreventUIRefresh(1)

local sel_tr_t = re_store_sel_trks() -- store because a temp track will be selected inside Set_Toggle_State_To_On()

-- launch mouse modifier context config scripts
local temp_tr--, mode_init
	if #data_t > 0 then
		for _, named_cmd_ID in ipairs(data_t) do
		-- getting temp track to reuse it for multiple mouse modifier context activation scripts
		-- located in the MIDI editor and MIDI Event List sections
		temp_tr = Set_Toggle_State_To_On(named_cmd_ID, temp_tr)
		end
	end


local del = temp_tr and r.DeleteTrack(temp_tr) -- maybe nil if MIDI Editor sections aren't enabled in the USER SETTINGS

re_store_sel_trks(sel_tr_t) -- restore

r.PreventUIRefresh(-1)

do return r.defer(no_undo) end -- prefer undo point creation








----------------------------------------------------------------------------------------

--!!!!!======== SET MOUSE MODIFIERS SCRIPT MIDIFICATION EXAMPLE START ===========!!!!!!


was_set=-1

function UpdateState()
  local MM_CTX_ITEM_default=reaper.GetMouseModifier('MM_CTX_ITEM',0)
  local is_set =
    reaper.GetMouseModifier('MM_CTX_ITEM',0) == '13 m' and -- Move item ignoring time selection
    reaper.GetMouseModifier('MM_CTX_ITEM',1) == '14 m' and -- Move item ignoring snap and time selection
    reaper.GetMouseModifier('MM_CTX_ITEM',2) == '2 m' and -- Copy item
    reaper.GetMouseModifier('MM_CTX_ITEM',3) == '5 m' and -- Copy item ignoring snap
    reaper.GetMouseModifier('MM_CTX_ITEM',4) == '3 m' and -- Move item contents ignoring snap
    reaper.GetMouseModifier('MM_CTX_ITEM',5) == '12 m' and -- Adjust take pitch (fine)
    reaper.GetMouseModifier('MM_CTX_ITEM',6) == '32 m' and -- Move item vertically
    reaper.GetMouseModifier('MM_CTX_ITEM',7) == '39 m' and -- Copy item, pooling MIDI source data
    reaper.GetMouseModifier('MM_CTX_ITEM',8) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',9) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',10) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',11) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',12) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',13) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',14) == MM_CTX_ITEM_default and
    reaper.GetMouseModifier('MM_CTX_ITEM',15) == MM_CTX_ITEM_default
  if is_set ~= was_set then
    was_set=is_set
    reaper.set_action_options(3 | (is_set and 4 or 8))
    reaper.RefreshToolbar(0)
--------- INSERT THIS LINE HERE START ---------
	 Store_CommandID(is_set)
---------- INSERT THIS LINE HERE END ----------
  end
  reaper.defer(UpdateState)
end


--------- INSERT THIS CODE HERE START ---------
function Store_CommandID(is_set)
-- store script command ID for restoration with
-- 'Mouse modifier context config activation script toggle state restorer.lua' script
local is_new_val,f_name,sectID,cmdID,mode,resol,val,ctx_str = reaper.get_action_context()
local MM_CTX
	-- find name of the context this script was exported from
	for line in io.lines(f_name) do
	MM_CTX = line:match('reaper.GetMouseModifier%(\'([%u_]+)')
		if MM_CTX then break end
	end
local scr_name = f_name:match('.+[\\/](.+)')
local sect = 'LAST ACTIVE MOUSE MODIFIER CONFIG ACTIVATION SCRIPT PER CONTEXT'
-- for storage concatenate base named command ID excluding Action list section specific infix
-- in case the script instance is run from a different Action list section
-- because reliably only Main section scripts can be run from the API
-- therefore 'Mouse modifier context config activation script toggle state restorer.lua'
-- only targets scripts in this section
local named_cmdID = ('_'..reaper.ReverseNamedCommandLookup(cmdID)):gsub('_RS7d3[c-f]_','_RS')
	if MM_CTX then
		if is_set then -- toggle state set to ON
		reaper.SetExtState(sect, MM_CTX, named_cmdID..' '..scr_name, true) -- persist true
		else
		-- remove this script command ID from storage if its command ID is the last to be stored
		-- at the moment of its toggle state being set to OFF;
		-- this can only happen when mouse modifiers config under the same context
		-- was changed manually by the user;
		-- in this scenario toggle state of a script, if any, with the matching config
		-- will be auto-set to ON, if there's none the toggle state of all scripts
		-- with the matching config will be set to OFF
		-- and toggling any of them on startup to ON with the script
		-- 'Mouse modifier context config activation script toggle state restorer.lua'
		-- will be pointless and misleading if command ID of one of them keeps being stored
		-- in reaper-extstate.ini;
		-- on the other hand, when the mouse modifiers config is changed from another script
		-- that script command ID becomes the last stored and by the time the equality below
		-- is evaluated the condition will be false, therefore the last stored command ID
		-- of another script won't be deleted;
		local cmdID_named = reaper.GetExtState(sect, MM_CTX)
			if cmdID == reaper.NamedCommandLookup(cmdID_named) then
			reaper.DeleteExtState(sect, MM_CTX, true) -- persist true
			end
		end
	end
end
--------- INSERT THIS CODE HERE END ---------


-- SetMouseModifier can also be called like this:
-- reaper.SetMouseModifier('Media item left drag',0,'Move item ignoring time selection')
reaper.SetMouseModifier('MM_CTX_ITEM',0,'13 m') -- Move item ignoring time selection
reaper.SetMouseModifier('MM_CTX_ITEM',1,'14 m') -- Move item ignoring snap and time selection
reaper.SetMouseModifier('MM_CTX_ITEM',2,'2 m') -- Copy item
reaper.SetMouseModifier('MM_CTX_ITEM',3,'5 m') -- Copy item ignoring snap
reaper.SetMouseModifier('MM_CTX_ITEM',4,'3 m') -- Move item contents ignoring snap
reaper.SetMouseModifier('MM_CTX_ITEM',5,'12 m') -- Adjust take pitch (fine)
reaper.SetMouseModifier('MM_CTX_ITEM',6,'32 m') -- Move item vertically
reaper.SetMouseModifier('MM_CTX_ITEM',7,'39 m') -- Copy item, pooling MIDI source data
reaper.SetMouseModifier('MM_CTX_ITEM',8,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',9,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',10,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',11,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',12,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',13,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',14,'-1')
reaper.SetMouseModifier('MM_CTX_ITEM',15,'-1')

UpdateState()



--!!!!!======== SET MOUSE MODIFIERS SCRIPT MIDIFICATION EXAMPLE END ===========!!!!!!



