--[[
ReaScript name: BuyOne_Trigger action by audio signal or silence.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Improved logic of trigger track insertion within the tracklist
Licence: WTFPL
REAPER: 6.71 or newer
Extensions: SWS/S&M unless REAPER build is 6.71 or newer
About: 	The script executes user defined actions depending
	on the signal level registered at the designated trigger
	track. 
	Two actions can be defined, one for signal and another
	for silence.
	Once launched via the RUN button of the USER SETTINGS
	menu the script will run in the background monitoring
	the signal level at the designated tracks.
	If the script is linked to a toolbar button, the button
	will be lit while the script is running.
	
	In order for the action to be triggered by the signal
	silence or signal below the user defined threshold must be 
	detected first, so that the transition from a signal below 
	the threshold to the level at or above it creates a trigger.
	Therefore after the action has been executed once, in order 
	for the script to get primed for next execution of the action, 
	signal level below the threshold must be detected again.
	
	Likewise in order for the action to be triggered by silence
	a signal above the threshold must be detected first, so that 
	the transition from signal above the threshold to the level 
	at or below it creates a trigger. Therefore after the action 
	has been executed once, in order for script to get primed for
	next execution of the action, signal level above the threshold 
	must be detected again.
	
	If the signal fluctuates around the threshold, which happens
	when the threshold is relatively high, the action will be 
	triggered repeatedly as long as the signal is present, because 
	the trigger will be reset almost immediately. But of course 
	the time intervals between executions won't necessarily be 
	consistent. Such scenario isn't good for triggering recording 
	unless VALIDATION_COUNTDOWN or TRIGGER_RESET_DELAY settings 
	are enabled in the USER SETTINGS.

	Because of the script update rate of about 30 ms which cannot 
	be reduced due to ReaScript API constraints, the actions will 
	be triggered either with a delay relative to the moment the 
	threshold has been reached or crossed during recording, or with 
	a delay or advance during playback because audio buffering allows 
	anticipating in-project audio before the playhead. So you'll have 
	to adjust your timing accodringly. The difference won't necessarily 
	be 30 ms long because the script update frequency is unlikely to 
	match the timing of the trigger appearence, so it will be either 
	slighly smaller or greater.
	
	Muting the designated trigger tracks disables the triggers
	even though they may still receive the signal.
	
	The most obvious use case for the script is triggering recording
	with signal trigger and stopping recording with silence trigger.
	However due to the inherent trigger delay mentioned above be
	sure to adjust the recording start time so that the very first 
	40 ms of the recording aren't cut off.
	
	
	BASIC SETUP			
	Create trigger tracks using relevant USER SETTINGS menu items
	or one track named 'signal silence trigger'. The register of 
	characters in the trigger track label is immaterisal, any 
	punctuation marks are ignored, so it can be modified afterwards.
	The trigger track is inserted after the last selected track 
	and if none is selected - at the end of the track list.  
	Create to the trigger track a send from another track or sends 
	from several tracks a signal from which will serve as the trigger.
	
	To use signal/silence trigger when recording from external 
	source on another track set the trigger track to receive signal 
	from the same input as any of the recording tracks because 
	routing signal from recording tracks via sends in this scenario 
	won't work. Enable 'Record: disable (input monitoring only)' so 
	that the trigger track itself doesn't record, and record arm it, 
	its meter should be able to register the input signal.
	
	When trying to trigger 'Transport: Record' action by a signal
	sent from a track with a VST instrument in order to record it live 
	as you play the instrument from the VKB, QWERTY or MIDI Editor 
	keyboard be sure to enable the preference  
	**Preferences -> Plug-ins -> VST -> Don't flush synthesizer plug-ins on stop/reset**
	so that the signal isn't choked at the very beginning of the
	recording due to flushing of the audio buffer.
	
	To trigger an action by MIDI signal with this script you'll 
	have to convert a MIDI message into an audio signal.  
	For example by routing MIDI from other tracks via send or 
	directly via track input and placing a ReaSynth plugin instance 
	on the trigger track so that it can emit audio signal upon 
	receiving a MIDI Note-On message. If MIDI signal is received 
	directly from a MIDI input the trigger track must be armed.
	
	Besides monitoring signal received from other tracks the 
	signal on the trigger track itself can be monitored being 
	received from an audio item placed on the track. This way 
	you'd be able to trigger actions by an audio item strategically 
	placed on the time line.  
	If both signal and silence triggers are enabled, at the 
	beginning of such item one action would be triggered and 
	immediately following its end another one would be executed.
	Be aware that if the signal does not fall below or rise 
	above the threshold abruptly or if the threshhold is fairly 
	low the distance between two closest items may not suffice for 	
	the trigger to be reset and for the script to be primed for 
	another execution of the action which will result in the action
	not be triggered when the playhead comes across the next item.

	The USER SETTINGS can be managed and the script launched via 
	a menu if MANAGE_SETTINGS_VIA_MENU setting is enabled 
	USER SETTINGS section below, which is its default state. 
	Detailed explanation of each setting see in the USER SETTINGS 
	section.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric
-- character between the quotes to be able
-- to manage the following settings and launch
-- the script via a menu;
-- best being disabled if you plan to launch the script
-- via a custom action or are not going to update
-- the settings very often
MANAGE_SETTINGS_VIA_MENU = "1"


-- If both triggers are enabled below and TRIGGER_QUIT setting
-- is enabled for both or if one is enabled and
-- the associated TRIGGER_QUIT setting is enabled as well
-- the script will be auto-terminated (stopped) once both actions
-- or the relevant action respectively have been executed;
-- if both triggers are enabled but TRIGGER_QUIT setting
-- is only enabled for one of them, such trigger will get disabled
-- once the associated action has been executed and can only
-- be re-enabled by stopping and relaunching the script;
-- however if both triggers are enabled and TRIGGER_QUIT setting
-- is only enabled for one of them while the second one doesn't have
-- a dedicated trigger track from which to derive the trigger
-- then even if its TRIGGER_QUIT setting is not enabled the script
-- will still auto-terminate after execition of the action
-- associated with the trigger which does have a dedicated
-- trigger track

------- SIGNAL TRIGGER SETTINGS -------

-- Enable by inserting any alphanumeric
-- character between the quotes
SIGNAL_TRIGGER = ""

-- Action/script command ID,
-- only Action list Main section actions
-- are supported
SIGNAL_TRIGGERED_ACTION = ""

-- Level in dB at or above which the signal will
-- trigger the action whose command ID is specified
-- in SIGNAL_TRIGGERED_ACTION setting above,
-- if not set, defaults to -60 dB
SIGNAL_TRIGGER_THRESHOLD = ""

-- Time in seconds after rising of the signal
-- to or above the threshold until it falls below
-- the threshold again, which if occurs within
-- the set time span will invalidate the trigger,
-- if not set, no change in the signal level can
-- invalidate the trigger until the action is executed,
-- negative values are rectified into positive
-- because they aren't valid,
-- if SIGNAL_TRIGGER_DELAY setting is enabled below,
-- signal validation time is added on top
-- of the trigger delay time
SIGNAL_VALIDATION_COUNTDOWN = ""

-- Time in seconds between rising of the signal
-- to or above the threshold and the moment the action is triggered,
-- the setting is not affected by subsequent change
-- in signal level once it reached the threshold,
-- negative values are rectified into positive
-- because they aren't valid,
-- if SIGNAL_VALIDATION_COUNTDOWN setting is enabled above,
-- signal validation time is added on top
-- of the trigger delay time
SIGNAL_TRIGGER_DELAY = ""

-- Time in seconds between execution of the action
-- and resetting of the trigger, i.e. falling the signal
-- to the level at or below the threshold so the action can
-- be repeated once the signal rises to or above the threshold again,
-- negative values are rectified into positive
-- because they aren't valid,
-- the setting is irrelevant if SIGNAL_TRIGGER_QUIT setting below
-- is enabled
SIGNAL_TRIGGER_RESET_DELAY = ""

-- Enable by inserting any alphanumetic
-- character between the quotes to prevent recurrence
-- of the action when the signal level changes,
-- how exactly it affects the script see in detail
-- at the beginning of this USER SETTINGS section above
SIGNAL_TRIGGER_QUIT = ""

------- SILENCE TRIGGER SETTINGS -------

-- Silence here means not absolute silence but
-- the signal level at or below the threshold defined
-- in the SILENCE_TRIGGER_THRESHOLD setting

-- Enable by inserting any alpahnumeric
-- character between the quotes
SILENCE_TRIGGER = ""

-- Action/script command ID,
-- only Action list Main section actions
-- are supported
SILENCE_TRIGGERED_ACTION = ""

-- Level in dB at or below which the signal will
-- trigger the action whose command ID is specified
-- in SILENCE_TRIGGERED_ACTION setting above,
-- if not set, defaults to -60 dB
SILENCE_TRIGGER_THRESHOLD = ""

-- Time in seconds after falling of the signal
-- to or below the threshold until it rises above
-- the threshold again, which if occurs within
-- the set time span will invalidate the trigger,
-- negative values are rectified into positive
-- because they aren't valid,
-- if SILENCE_TRIGGER_DELAY setting is enabled below,
-- seilence validation time is added on top
-- of the trigger delay time
SILENCE_VALIDATION_COUNTDOWN = ""

-- Time in seconds between falling of the signal
-- to or below the threshold and the moment the action is triggered,
-- the setting is not affected by subsequent change
-- in signal level once it reached the threshold,
-- negative values are rectified into positive
-- because they aren't valid,
-- if SILENCE_VALIDATION_COUNTDOWN setting is enabled above,
-- silence validation time is added on top
-- of the trigger delay time
SILENCE_TRIGGER_DELAY = ""

-- Time in seconds between execution of the action
-- and resetting of the trigger, i.e. raising the signal
-- to the level at or above the threshold so the action can
-- be repeated once the signal falls to or below the threshold again,
-- negative values are rectified into positive
-- because they aren't valid,
-- the setting is irrelevant if SILENCE_TRIGGER_QUIT setting below
-- is enabled
SILENCE_TRIGGER_RESET_DELAY = ""

-- Enable by inserting any alpahnumetic
-- character between the quotes to prevent recurrence
-- of the action when the signal level changes,
-- how exactly it affects the script see in detail
-- at the beginning of this USER SETTINGS section above
SILENCE_TRIGGER_QUIT = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only display output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
-- both refer to the upper left hand corner of the tooltip,
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




function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest instance of a particular character at the start of a menu item
-- can be used as a shortcut provided this character is unique in the menu
-- in this case they don't have to be preceded with ampersand '&'
-- if it's not unique, inputting it from keyboard will select
-- the menu item starting with this character
-- and repeated input will oscilate the selection between menu items
-- which start with it without actually triggering them
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest instance at the start of a menu item
-- some characters still do need ampresand, e.g. < and >;
-- characters which aren't the first in the menu item name
-- must also be explicitly preceded with ampersand

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and keep_menu_open) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if keep_menu_open is enabled the menu opens every time at the same spot
		if keep_menu_open and not coord_t then -- keep_menu_open is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not keep_menu_open then
		coord_t = nil
		end

	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y

	return gfx.showmenu(menu) -- menu string

	end

end


function validate_delay_time(sett)
local sett = tonumber(sett)
return sett and math.abs(sett) -- rectifying in case negative, only relevant in cases where settings were configured manually because the menu disallows invalid input
end


function Get_Action_Name(cmdID, section_ID)

	function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'):gsub('\\','%0%0')
	return str
	end

	local function script_exists(line, name)
	-- how paths external to \Scripts folder may look on MacOS
	-- https://github.com/Buy-One/Samelot_Reaper
	local f_path = line:match(Esc(name)..' "(.+)"$') or line:match(Esc(name)..' (.+)$') -- path either with or without spaces, in the former case it's enclosed within quotation marks
	local f_path = f_path:match('^%u:') and f_path or path..sep..'Scripts'..sep..f_path -- full (starts with the drive letter and a colon) or relative file path; in reaper-kb.ini full path is stored when the script resides outside of the 'Scripts' folder of the REAPER instance being used // NOT SURE THE FULL PATH SYNTAX IS VALID ON OSs OTHER THAN WIN
	return r.file_exists(f_path)
	end

	if not cmdID then return end

local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local named_cmd = tonumber(cmdID) and r.ReverseNamedCommandLookup(cmdID) -- ReverseNamedCommandLookup() accepts integers in string format as well, if the cmdID belongs to a native action or is 0 ReverseNamedCommandLookup() return value is nil
local act_name, mess

	if r.kbd_getTextFromCmd or r.CF_GetCommandText then -- accept command both as integer and as a string, covers all types of actions
		if not section_ID then return end
	local cmdID = named_cmd and cmdID or r.NamedCommandLookup(cmdID) -- if cmdID is integer use it, otherwise look up numeric command ID
	local GetCommandText = r.kbd_getTextFromCmd or r.CF_GetCommandText
	local args = r.kbd_getTextFromCmd and {cmdID, section_ID} or r.CF_GetCommandText and {section_ID, cmdID} -- the order of args in the functions differ
	act_name = GetCommandText(table.unpack(args))
		if named_cmd and act_name and act_name:match('Script') then -- named_cmd var makes the condition focus on non-native actions thereby excluding narive actions containing the word 'Script' in their name such as 'ReaScript: Close all running ReaScripts'
		local scr_name = act_name:gsub('Script:', 'Custom:') -- evaluate if script exists having made a replacement to conform to the reaper-kb.ini syntax
			for line in io.lines(path..sep..'reaper-kb.ini') do
				if line:match(Esc(scr_name)) then
				scr_exists = script_exists(line, '"'..scr_name..'"')
				break end
			end
		mess = not scr_exists and '  the script doesn\'t exist \n\n at the registered location'
		end
	elseif named_cmd then -- custom action or a script
		for line in io.lines(path..sep..'reaper-kb.ini') do -- much quicker than using io.read() which freezes UI
		act_name = line:match('ACT.-("'..Esc(named_cmd)..'" ".-")') or line:match('SCR.-('..Esc(named_cmd)..' ".-")') -- extract command ID and name
			if act_name then
				if line:match('SCR') then -- evaluate if script exists
				scr_exists = script_exists(line, name)
				end
			act_name = act_name:gsub('Custom:', 'Script:', 1) -- make script data retrieved from reaper-kb.ini conform to the name returned by CF_GetCommandText() and kbd_getTextFromCmd() which prefix the name with 'Script:' following their appearance in the Action list instead of 'Custom:' as they're prefixed in reaper-kb.ini file
			mess = not scr_exists and '  the script doesn\'t exist \n\n at the registered location'
			break end
		end
	end

	if mess then
	Error_Tooltip('\n\n '..mess..' \n\n', 1, 1, 0, -150) -- caps, spaced true, x2 0, y2 -150 to move tooltip away from the mouse cursor above the dialogue window so it doesn't block the dialogue OK button
	return
	end

return act_name, mess -- mess is optional, returned if not used as a condition for error display above

end



function Validate_Command_ID(cmdID, section_ID)
local cmdID = cmdID:gsub(' ','')
local named_cmd_ID = cmdID:gsub('_','')
local err = cmdID == '' and 'the field is empty'
local invalid = 'invalid action command ID'
err = err or tonumber(cmdID) and
(#cmdID > 6 or r.kbd_getTextFromCmd and #r.kbd_getTextFromCmd(cmdID, section_ID) == 0 -- not native action
or r.CF_GetCommandText and #r.CF_GetCommandText(section_ID, cmdID) == 0)
and '  '..invalid..'\n\n or the action doesn\'t belong \n\n\t to the Main section'
or not tonumber(cmdID) and
(#named_cmd_ID ~= 32 and #named_cmd_ID ~= 42 and #named_cmd_ID ~= 47 -- neither custom action nor script
or r.NamedCommandLookup(cmdID) == 0)
and invalid
	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 0, -150) -- caps, spaced true, x2 0, y2 -150 to move tooltip away from the mouse cursor above the dialogue window so it doesn't block the dialogue OK button
	return
	end
return true
end


function User_Input_Dialogue(input, trig_type, action, sett_type)

	if not input and not (action or sett_type) then return end

::RELOAD::

local trig_type = trig_type:upper()..' '
local sett_type = sett_type and sett_type:upper()
local capts = action and {'PASTE ACTION COMMAND ID',trig_type..'COMMAND ID:'}
or sett_type:match('THRESHOLD') and {'INPUT A dB VALUE', trig_type..sett_type..':'}
or {'INPUT TIME IN SECONDS (to disable submit 0)', trig_type..sett_type..':'}
local extrawidth = action and 220 or 50
local ret, output = r.GetUserInputs(capts[1],1,capts[2]..',extrawidth='..extrawidth, input or '')
output = output:gsub('[%c%s]+','')

	if not ret or #output == 0 then return end

	if action then
	local num_cmdID = tonumber(output) and math.abs(output) -- rectify negative integer
	local cmdID = (num_cmdID or output:sub(1,1) == '_') and output or '_'..output -- add leading underscore if none to named command ID
		if not Validate_Command_ID(cmdID, 0) -- section_ID is 0, only Main section is supported
		or not Get_Action_Name(cmdID, 0) -- section_ID is 0, only Main section is supported
		then
		-- error messages are generated inside Validate_Command_ID() and Get_Action_Name() functions
		input = num_cmdID or output -- using rectified numeric command ID
		goto RELOAD
		end
	output = cmdID
	elseif sett_type then
	local err = ' cannot be negative'
	local err = not tonumber(output) and 'invalid input'
	or (sett_type:match('VALID') or sett_type:match('TRIGGER')) and tonumber(output) < 0 -- Singal/Silence validation countdown or two types of Delay
	and (sett_type:match('VALID') and 'countdown' or 'delay time')..err -- the captions were capitalized at the beginning of the function
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 0, -150) -- caps, spaced true, x2 0, y2 -150 to move tooltip away from the mouse cursor above the dialogue window so it doesn't block the dialogue OK button
		input = output
		goto RELOAD
		end
	end

return output

end


function Trigger_Track_Present(label)
local label = label..' trigger'
	for i=0, r.GetNumTracks()-1 do
	local track = r.GetTrack(0,i)
	local tr_name = r.GetTrackState(track):lower():match('^%s*(.-)%s*$')
		if tr_name and (tr_name == label
		or tr_name:match('signal') and tr_name:match('silence') and tr_name:match('trigger')) then
		return true
		end
	end
end


function Insert_Trigger_Track(label)
-- only visible tracks are respected
-- inserted after the last selected track or the last track if none is selected

local sel_tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true
local master_tr = r.GetMasterTrack(0)
local master_vis = r.GetMasterTrackVisibility()&1 == 1
local last_sel_tr = sel_tr_cnt > 0 and r.GetSelectedTrack2(0, sel_tr_cnt-1, true) -- wantmaster true

	if last_sel_tr == master_tr and not master_vis -- &1 is visibility in TCP, if last selected is the Master this means it's the only one selected and since it's hidden the loop below won't start
	or last_sel_tr and r.GetMediaTrackInfo_Value(last_sel_tr, 'B_SHOWINTCP') == 0 then -- get last visible selected track
	last_sel_tr = nil -- reset to be able to fall back on the last visible track in the tracklist
		for i=sel_tr_cnt-2,0,-1 do -- -2 to exclude the last selected track which turned out to be hidden
		local tr = r.GetSelectedTrack2(0, i, true)
			if tr ~= last_sel_tr and (tr == master_tr and master_vis
			or tr ~= master_tr and r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1) then
			last_sel_tr = tr break
			end
		end		
	end
	
	if not last_sel_tr then -- if no visible selected track was found, opt for the last visible in the tracklist
		for i=r.GetNumTracks()-1,0,-1 do
		local tr = r.GetTrack(0,i)
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then
			last_sel_tr = tr break
			end
		end
	end


local last_sel_tr_idx = 0
	if last_sel_tr then -- if no tracks in the project this var will be nil in which case index 0 will be used for the trig track
	last_sel_tr_idx = r.CSurf_TrackToID(last_sel_tr, false) -- mcpView false // OR r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')
	end

r.Undo_BeginBlock()
r.InsertTrackAtIndex(last_sel_tr_idx, false) -- wantDefaults false
local trig_tr = r.GetTrack(0, last_sel_tr_idx)
local Set = r.SetMediaTrackInfo_Value
Set(trig_tr, 'B_MAINSEND',0) -- turn off Master/parent send
Set(trig_tr, 'I_RECMON',1) -- enable monitoring normal
local name = label..' trigger'
r.GetSetMediaTrackInfo_String(trig_tr, 'P_NAME', name, true) -- setNewValue true
r.Undo_EndBlock('Insert '..name..' track', -1)

end



function Settings_Management_Menu_And_Help(condition, want_help, want_run)
-- manage script settings from a menu
-- the function updates the actual script file
-- relies on Reload_Menu_at_Same_Pos() and Esc() functions
-- want_help is boolean if About text needs to be displayed to the user
-- want_run is a boolean to create a menu button to execute the script;
-- any user settings not explicitly listed in user_sett table below
-- will be ignored in the menu

::RELOAD::

local sett_t, help_t, about = {}, want_help and {} -- help_t is optional if help is important enough
	for line in io.lines(scr_name) do
	-- collect settings
		if line:match('----- USER SETTINGS ------') and #sett_t == 0 then
		sett_t[#sett_t+1] = line
		elseif line:match('END OF USER SETTINGS')
		and not sett_t[#sett_t]:match('END OF USER SETTINGS') then
		sett_t[#sett_t+1] = line
		break
		elseif #sett_t > 0 then
		sett_t[#sett_t+1] = line
		end
		-- collect help
		if want_help then
			if #help_t == 0 and line:match('About:') then
			help_t[#help_t+1] = line:match('About:%s*(.+)')
			about = 1
			elseif line:match('----- USER SETTINGS ------') then
			about = nil -- reset to stop collecting lines
			elseif about then -- collect lines
			help_t[#help_t+1] = line:match('%s*(.-)$')
			end
		end
	end


local user_sett = {'SIGNAL_TRIGGER', 'SIGNAL_TRIGGERED_ACTION',
'SIGNAL_TRIGGER_THRESHOLD', 'SIGNAL_VALIDATION_COUNTDOWN', 'SIGNAL_TRIGGER_DELAY',
'SIGNAL_TRIGGER_RESET_DELAY', 'SIGNAL_TRIGGER_QUIT',
'SILENCE_TRIGGER', 'SILENCE_TRIGGERED_ACTION',
'SILENCE_TRIGGER_THRESHOLD', 'SILENCE_VALIDATION_COUNTDOWN', 'SILENCE_TRIGGER_DELAY',
'SILENCE_TRIGGER_RESET_DELAY', 'SILENCE_TRIGGER_QUIT'}

local menu_sett = {}
	for k, v in ipairs(user_sett) do
		for k, line in ipairs(sett_t) do
		local sett = line:match(v..'%s*=%s*"(.-)"')
			if sett then
			menu_sett[#menu_sett+1] = sett
			end
		end
	end

local act_prompt = 'CLICK TO ADD ACTION'	
	
-- validate settings
local sett1 = #menu_sett[1]:gsub(' ','') > 0 and '!' or '' -- signal boolean
local sett2 = #menu_sett[2]:gsub(' ','') > 0 and (Get_Action_Name(menu_sett[2]:gsub(' ',''), 0) or menu_sett[2]:gsub(' ','')) or act_prompt -- section is 0, only Main is supported, if name cannot be retrieved, list action ID or empty string
local sett3 = tonumber(menu_sett[3]) or -60 -- threshold
local sett4 = validate_delay_time(menu_sett[4]) -- signal validation countdown
local sett5 = validate_delay_time(menu_sett[5]) -- trigger delay
local sett6 = validate_delay_time(menu_sett[6]) -- reset delay
local sett7 = #menu_sett[7]:gsub(' ','') > 0 and '!' or '' -- quit
sett1 = #sett2==0 and '#'..sett1:gsub('!','') or sett1 -- gray out trigger boolean setting item if action isn't set

local sett8 = #menu_sett[8]:gsub(' ','') > 0 and '!' or '' -- silence boolean
local sett9 = #menu_sett[9]:gsub(' ','') > 0 and (Get_Action_Name(menu_sett[9]:gsub(' ',''), 0) or menu_sett[9]:gsub(' ','')) or act_prompt -- section is 0, only Main is supported, if name cannot be retrieved, list action ID or empty string
local sett10 = tonumber(menu_sett[10]) or -60 -- threshold
local sett11 = validate_delay_time(menu_sett[11]) -- silence validation countdown
local sett12 = validate_delay_time(menu_sett[12]) -- trigger delay
local sett13 = validate_delay_time(menu_sett[13]) -- reset delay
local sett14 = #menu_sett[14]:gsub(' ','') > 0 and '!' or '' -- quit
sett8 = #sett9==0 and '#'..sett8:gsub('!','') or sett8 -- gray out trigger boolean setting item if action isn't set

local signal_tr_present, silence_tr_present = Trigger_Track_Present('signal'), Trigger_Track_Present('silence')
local RUN = ((sett1=='!' and signal_tr_present or sett8=='!' and silence_tr_present) and '' or '#')..('RUN'):gsub('.','%0 ') -- gray out if both triggers are disabled or their trigger tracks are absent

	local function track_present(present)
	-- if trigger boolean setting is disabled the track presence menu item will be grayed out
	return 'trigger track:  '..(present and 'PRESENT|' or 'ABSENT|')
	end

-- type in actual setting names as labels
local labels = {'trigger|',  'Action:  ', 'Threshold:  ', 'Validation countdown:  ', 'Trigger delay:  ',
'Trigger reset delay:  ', 'Quit after execution||'}
local menu = ('USER SETTINGS'):gsub('.','%0 ')..'||SIGNAL TRIGGER SETTINGS||'..sett1..'Signal '..labels[1]
..labels[2]..sett2..'|'..labels[3]..sett3..' dB|'..labels[4]..(sett4 or 0)..' sec|'..labels[5]..(sett5 or 0)..' sec|'
..labels[6]..(sett6 or 0)..' sec|'..sett7..labels[7]
..'SILENCE TRIGGER SETTINGS||'..sett8..'Silence '..labels[1]
..labels[2]..sett9..'|'..labels[3]..sett10..' dB|'..labels[4]..(sett11 or 0)..' sec|'..labels[5]..(sett12 or 0)..' sec|'
..labels[6]..(sett13 or 0)..' sec|'..sett14..labels[7]
-- if trigger boolean setting is disabled the track presence menu item will be grayed out
-- if it's enabled and the track is present, track insert option is not available
..(sett1=='' and '#' or '')..'>Signal '..track_present(signal_tr_present)..(signal_tr_present and '<|' or '<Insert track|')
..(sett8=='' and '#' or '')..'>Silence '..track_present(silence_tr_present)..(silence_tr_present and '<||' or '<Insert track||')
..(want_run and RUN or ' ')

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return -- will trigger script abort to prevent activation of the main routine when menu is exited
	elseif output == 18 then
		if not signal_tr_present then Insert_Trigger_Track('signal') end
	goto RELOAD
	elseif output == 19 then
		if not signal_tr_present then Insert_Trigger_Track('silence') end
	goto RELOAD
	elseif want_run and output == 20 then -- THE output VALUE DEPENDS ON THE NUMBER OF MENU ITEMS
	return sett2, sett9, table.unpack(menu_sett) -- returning also action names to be used as undo point name, must precede table.unpack, because if they follow only the 1st table entry will be returned
	elseif output < 3 or output == 10 then -- THE VALUES DEPEND ON THE NUMBER OF MENU ITEMS
	goto RELOAD -- if clicked on an invalid item, i.e. title or blank
	end

output = output-2 -- offset first two menu items which are titles

local trig_type = output < 8 and 'signal' or 'silence'
local var, repl

	if output == 1 or output == 7 or output == 9 or output == 15 then -- Trigger, Quit booleans
	output = output > 7 and output-1 or output -- normalize output indices for slience trigger settings to match those in the table
	var = user_sett[output]
	local sett = #menu_sett[output]:gsub(' ','') > 0 and '' or '1' -- toggle
	repl = var..' = "'..sett..'"'
	elseif output == 2 or output == 10 then -- Action
	output = output == 10 and output-1 or output -- normalize output index for slience trigger settings to match those in the table
	local cmdID = User_Input_Dialogue(menu_sett[output], trig_type, 1) -- action true
	local cur_sett = menu_sett[output]
		if cmdID and cmdID ~= cur_sett then
		var = user_sett[output]
		repl = var..' = "'..cmdID..'"'
		end
	else -- Threshold, Validation countdown, Trigger delay, Reset delay
	output = output > 7 and output-1 or output -- normalize output index for silence trigger settings to match those in the table
	local sett_type = (output == 3 or output == 10) and 'threshold' or (output == 4 or output == 11) and 'validation'
	or (output == 5 or output == 12) and 'trigger delay' or (output == 6 or output == 13) and 'trigger reset'
	local user_input = User_Input_Dialogue(menu_sett[output], trig_type, nil, sett_type) -- action nil
	user_input = user_input and (sett_type ~= 'threshold' and user_input:match('^[%-0]+$') and '' or user_input) -- if delay or countdown is 0 or -0, the setting is disabled by passing an empty string
	local cur_sett = menu_sett[output]
		if user_input and user_input ~= cur_sett then
		var = user_sett[output]
		repl = var..' = "'..user_input..'"'
		end
	end


	if repl then -- settings were updated, get script
	local cur_settings = table.concat(sett_t,'\n')
	local upd_settings, cnt = cur_settings:gsub(var..'%s*=%s*".-"', repl, 1)
	local f = io.open(scr_name,'r')
	local cont = f:read('*a')
	f:close()
	local cur_settings = Esc(cur_settings)
	local upd_settings = upd_settings:gsub('%%','%%%%')
	cont, cnt = cont:gsub(cur_settings, upd_settings)
		if cnt > 0 then -- settings were updated, write to file
		local f = io.open(scr_name,'w')
		f:write(cont)
		f:close()
		end
	end

goto RELOAD

end



function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error
-- " cannot use '...' outside a vararg function near '...' "
-- without there being elipsis in function() as well, but gave direction;
-- if original function has arguments they MUST be passed to the Wrapper() function
-- regardless of their scope (global or local);
-- if it doesn't, the upvalues must all be global and it doesn't matter
-- whether they're passed to the Wrapper() function
-- syntax: r.atexit(Wrapper(FUNC_NAME, arg1, arg2, arg3)) -- for defer scripts
local t = {...}
return function() func(table.unpack(t)) end
end



function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function Is_Same_Track(tr, label)
local name = r.GetTrackState(tr):lower()
return name:match(label) and name:match('trigger')
end



function Monitor(tr, name, threshold) -- threshold isn't used in this design

-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Values/X-Raym_Val%20to%20dB%20-%20dB%20to%20Val.lua
-- https://forum.cockos.com/showthread.php?t=170003
	function dBFromVal(val)
	return 20*math.log(val, 10)
	end

local signal = name:lower():match('signal')
local tr = tr and Is_Same_Track(tr, signal or 'silence') and tr

	if not tr then -- only runs at initial launch and if the trigger track has changed
		for i=0, r.GetNumTracks()-1 do
		local track = r.GetTrack(0,i)
		local tr_name = r.GetMediaTrackInfo_Value(track, 'B_MUTE') == 0 and r.GetTrackState(track):lower():match('^%s*(.-)%s*$')
			if tr_name and (tr_name == name
			or tr_name:match('signal') and tr_name:match('silence') and tr_name:match('trigger')) then
			tr = track
			break
			end
		end
	end

	if tr then
	local L_ch = dBFromVal(r.Track_GetPeakInfo(tr, 0))
	local R_ch = dBFromVal(r.Track_GetPeakInfo(tr, 1))
	return tr, signal and math.max(L_ch, R_ch) or math.min(L_ch, R_ch) -- for signal trigger return max of two, for silence - min of two
	end

end


function Trigger_Action(named_cmdID, undo)
r.Undo_BeginBlock()
local num_cmd_ID = r.NamedCommandLookup(named_cmdID) -- supports native numeric command IDs as a string, returns the same string
r.Main_OnCommand(num_cmd_ID, 0)
--local undo = r.kbd_getTextFromCmd and r.kbd_getTextFromCmd(num_cmd_ID, 0) or typ..' triggered action'
r.Undo_EndBlock(undo,-1)
end


function Signal_Trigger()

local val
signal_trig_tr, val = Monitor(signal_trig_tr, 'signal trigger') -- string is the track name

	if expendedA then
		if r.time_precise()-expendedA >= SIGNAL_TRIGGER_RESET_DELAY then
		silenceA, signalA, delayA, expendedA = nil
		end
	elseif val and r.GetMediaTrackInfo_Value(signal_trig_tr, 'B_MUTE') == 0 then -- ignoring muted trigger track
	silenceA = silenceA or val < SIGNAL_TRIGGER_THRESHOLD
	signalA = signalA or silenceA and val >= SIGNAL_TRIGGER_THRESHOLD and r.time_precise() -- only register a signal after silence has been registered

		if signalA and SIGNAL_VALIDATION_COUNTDOWN and not signal_ON then
		signal_ON = r.time_precise()
		silenceA = nil -- reset to be able to detect signal falling below the threshold
		elseif signal_ON and silenceA and r.time_precise()-signal_ON < SIGNAL_VALIDATION_COUNTDOWN then -- signal fell below the threshold again before time has elapsed
		signalA, signal_ON = nil -- reset to be able to re-start the monitoring
		elseif signal_ON and not silenceA and r.time_precise()-signal_ON >= SIGNAL_VALIDATION_COUNTDOWN then -- before time has elapsed signal didn't fall below the threshold again
		silenceA, signalA = true, r.time_precise() -- re-enable silenceA, assign new time stamp to signalA to measure SIGNAL_TRIGGER_DELAY against in case enabled
		end

	delayA = silenceA and signalA and (not SIGNAL_TRIGGER_DELAY or r.time_precise()-signalA >= SIGNAL_TRIGGER_DELAY)

		if delayA then
		signal_ON = nil -- reset, cannot be reset outside of this block because SIGNAL_VALIDATION_COUNTDOWN condition will become true again and so on which will prevent the routine from reaching this point
		-- RUN SIGNAL_TRIGGERED_ACTION
		Trigger_Action(SIGNAL_TRIGGERED_ACTION, SIGNAL_TRIGGER_UNDO)
			if SIGNAL_TRIGGER_QUIT then return true, signal_trig_tr
			else -- reset
				if not SIGNAL_TRIGGER_RESET_DELAY then
				silenceA, signalA, delayA = nil
				else
				expendedA = r.time_precise()
				end
			end
		end
	end

end


function Silence_Trigger()

local val
silence_trig_tr, val = Monitor(silence_trig_tr, 'silence trigger') -- string is the track name

	if expendedB then
		if r.time_precise()-expendedB >= SILENCE_TRIGGER_RESET_DELAY then
		silenceB, signalB, delayB, expendedB = nil
		end
	elseif val and r.GetMediaTrackInfo_Value(silence_trig_tr, 'B_MUTE') == 0 then -- ignoring muted trigger track
	signalB = signalB or val >= SILENCE_TRIGGER_THRESHOLD
	silenceB = silenceB or signalB and val <= SILENCE_TRIGGER_THRESHOLD and r.time_precise() -- only register silence after the signal has been registered

		if silenceB and SILENCE_VALIDATION_COUNTDOWN and not silence_ON then
		silence_ON = r.time_precise()
		signalB = nil -- reset to be able to detect signal raising above the threshold
		elseif silence_ON and signalB and r.time_precise()-silence_ON < SILENCE_VALIDATION_COUNTDOWN then -- signal rose above the threshold again before time has elapsed
		silenceB, silence_ON = nil -- reset to be able to re-start the monitoring
		elseif silence_ON and not signalB and r.time_precise()-silence_ON >= SILENCE_VALIDATION_COUNTDOWN then -- before time has elapsed signal didn't rise above the threshold again
		signalB, silenceB = true, r.time_precise() -- re-enable signalB, assign new time stamp to silenceB to measure SILENCE_TRIGGER_DELAY against in case enabled
		end

	delayB = signalB and silenceB and (not SILENCE_TRIGGER_DELAY or r.time_precise()-silenceB >= SILENCE_TRIGGER_DELAY)

		if delayB then
		silence_ON = nil -- reset, cannot be reset outside of this block because SILENCE_VALIDATION_COUNTDOWN condition will become true again and so on which will prevent the routine from reaching this point
		-- RUN SILENCE_TRIGGERED_ACTION
		Trigger_Action(SILENCE_TRIGGERED_ACTION, SILENCE_TRIGGER_UNDO)
			if SILENCE_TRIGGER_QUIT then return true, silence_trig_tr
			else -- reset
				if not SILENCE_TRIGGER_RESET_DELAY then
				silenceB, signalB, delayB = nil
				else
				expendedB = r.time_precise()
				end
			end
		end
	end

end



function RUN()

	if not quitA and SIGNAL_TRIGGER then -- quitA ensures that if QUIT is enabled the action won't run recurrently after the first execution
	quitA, signal_trig_tr = Signal_Trigger()
	end

	if not quitB and SILENCE_TRIGGER then -- quitB ensures that if QUIT is enabled the action won't run recurrently after the first execution
	quitB, silence_trig_tr = Silence_Trigger()
	end

	-- the condition will also be true if both triggers are enabled,
	-- QUIT is enabled for one of them which also has a dedicated trigger track
	-- but the second one doesn't have such track which means it will never work
	-- and even if QUIT is enabled for it as well it will never become true
	-- to begin with to condition quitting by QUIT coming from both triggers,
	-- that ensures that the script doesn't run idly after execution
	-- of the trigger set to quit after execution needlessly waiting for another
	-- trigger which will never come
	if SIGNAL_TRIGGER and SILENCE_TRIGGER and (quitA and quitB
	or quitA and not silence_trig_tr or quitB and not signal_trig_tr)
	or SIGNAL_TRIGGER and quitA or SILENCE_TRIGGER and quitB then
	Re_Set_Toggle_State(scr_sect_ID, scr_cmd_ID, 0)
	return
	end

r.defer(RUN)

end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.71
	and not r.CF_GetCommandText then
	Error_Tooltip('\n\n  reaper build is older than 6.71 \n\n'
	..'\t and sws/S&M extension \n\n\t\tsisn\'t installed \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


is_new_value, scr_name, scr_sect_ID, scr_cmd_ID, mode, resol, val, contextstr = r.get_action_context() -- global so that scr_sect_ID, scr_cmd_ID are accessible to Re_Set_Toggle_State() inside RUN() function, scr_name is used inside Settings_Management_Menu_And_Help()

	if #MANAGE_SETTINGS_VIA_MENU:gsub(' ','') > 0 then
	SIGNAL_TRIGGER_UNDO, SILENCE_TRIGGER_UNDO,
	SIGNAL_TRIGGER, SIGNAL_TRIGGERED_ACTION, SIGNAL_TRIGGER_THRESHOLD, SIGNAL_VALIDATION_COUNTDOWN,
	SIGNAL_TRIGGER_DELAY, SIGNAL_TRIGGER_RESET_DELAY, SIGNAL_TRIGGER_QUIT,
	SILENCE_TRIGGER, SILENCE_TRIGGERED_ACTION, SILENCE_TRIGGER_THRESHOLD, SILENCE_VALIDATION_COUNTDOWN,
	SILENCE_TRIGGER_DELAY, SILENCE_TRIGGER_RESET_DELAY, SILENCE_TRIGGER_QUIT
	= Settings_Management_Menu_And_Help(condition, want_help, 1) -- want_run true

		if not SIGNAL_TRIGGER_UNDO then return r.defer(no_undo) end -- menu was exited or item is invalid
	end


SIGNAL_TRIGGER = #SIGNAL_TRIGGER:gsub(' ','') > 0
SIGNAL_TRIGGER_QUIT = #SIGNAL_TRIGGER_QUIT:gsub(' ','') > 0
SIGNAL_TRIGGER_THRESHOLD = tonumber(SIGNAL_TRIGGER_THRESHOLD) or -60
SIGNAL_VALIDATION_COUNTDOWN = validate_delay_time(SIGNAL_VALIDATION_COUNTDOWN)
SIGNAL_TRIGGER_DELAY = validate_delay_time(SIGNAL_TRIGGER_DELAY)
SIGNAL_TRIGGER_RESET_DELAY = validate_delay_time(SIGNAL_TRIGGER_RESET_DELAY)
SIGNAL_TRIGGERED_ACTION = #SIGNAL_TRIGGERED_ACTION:gsub(' ','') > 0 and SIGNAL_TRIGGERED_ACTION:gsub(' ','')

SILENCE_TRIGGER = #SILENCE_TRIGGER:gsub(' ','') > 0
SILENCE_TRIGGER_QUIT = #SILENCE_TRIGGER_QUIT:gsub(' ','') > 0
SILENCE_TRIGGER_THRESHOLD = tonumber(SILENCE_TRIGGER_THRESHOLD) or -60
SILENCE_VALIDATION_COUNTDOWN = validate_delay_time(SILENCE_VALIDATION_COUNTDOWN)
SILENCE_TRIGGER_DELAY = validate_delay_time(SILENCE_TRIGGER_DELAY)
SILENCE_TRIGGER_RESET_DELAY = validate_delay_time(SILENCE_TRIGGER_RESET_DELAY)
SILENCE_TRIGGERED_ACTION = #SILENCE_TRIGGERED_ACTION:gsub(' ','') > 0 and SILENCE_TRIGGERED_ACTION:gsub(' ','')

-- if not run via menu validate command ID
SIGNAL_TRIGGER_UNDO = SIGNAL_TRIGGER_UNDO or Get_Action_Name(SIGNAL_TRIGGERED_ACTION, 0) -- section is 0, only Main is supported
SILENCE_TRIGGER_UNDO = SILENCE_TRIGGER_UNDO or Get_Action_Name(SILENCE_TRIGGERED_ACTION, 0)

-- the error is only possible if the settings are not managed via the menu
-- because everything is validated at the menu level
local err = ' trigger action is invalid'
err = SIGNAL_TRIGGER and not SIGNAL_TRIGGER_UNDO and SILENCE_TRIGGER and not SILENCE_TRIGGER_UNDO and
'\tsignal and silence\n\n'..err:gsub('action is','actions are')
or SIGNAL_TRIGGER and not SIGNAL_TRIGGER_UNDO and 'signal'..err
or SILENCE_TRIGGER and not SILENCE_TRIGGER_UNDO and 'silence'..err

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

	if r.set_action_options then r.set_action_options(1) end -- terminate when re-launched

local signal_trig_tr, silence_trig_tr, signalA, signalB, silenceA, silenceB,
delayA, delayB, quitA, quitB, expendedA, expendedB, signal_ON, silence_ON

Re_Set_Toggle_State(scr_sect_ID, scr_cmd_ID, 1)

RUN()

r.atexit(Wrapper(Re_Set_Toggle_State, scr_sect_ID, scr_cmd_ID, 0))



