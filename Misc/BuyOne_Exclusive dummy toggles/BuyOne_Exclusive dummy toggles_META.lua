--[[
ReaScript name: BuyOne_Exclusive dummy toggles_META.lua (10 scripts)
Author: BuyOne
Version: 1.2
Changelog: v1.2 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		#Updated About text
	   v1.1 #Added functionality to export individual scripts included in the package
		#Updated About text
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M extension (recommended for ability to use Cycle action editor)
About:	If this script name is suffixed with META, when executed it will automatically spawn 
	all individual scripts included in the package into the directory of the META script
	and will import them into the Action list from that directory.  
	If there's no META suffix in this script name it will perfom the operation indicated 
	in its name.

	This set of 10 scripts borrows the concept of SWS extension 'SWS/S&M: Dummy toggle' 
	actions but makes dummy toggle exclusive within the scope of an Action list section,
	meaning that when one of 10 scripts toggle state is ON, toggle state of the rest 9 is OFF 
	while the state of a given script in one Action list section is completely independent 
	from its state in other Acton list sections.  
	These can be useful in switching between options/modes of operation depending 
	on the state of a specific dummy toggle script, for example with the SWS Cycle actions 
	through conditional statements or within other scripts. One such use case is switching
	between velocity presets in the MIDI Editor, another - mouse tool switcher. The switching 
	can be done from a toolbar or a menu via toolbar buttons or menu items linked to the dummy 
	toggle scripts.  
	You can expand the script set by duplicating any instance, giving its duplicate a unique 
	number and importing it into every Action list section.  
	With the USER SETTINGS the script set can be divided into subsets (groups) so that every 
	script in a subset only affects toggle state of other scripts in this subset. This way 
	each subset can be dedicated to a specific task which requires mutually exclusive modes.
	Division into subsets is specific to the Action list section so in each section the dummy 
	toggle script set can have its own subset division scheme.
		
        The dummy toggle script whose toggle state is currently ON is stored. This allows restoring 
        its state on REAPER startup using 'BuyOne_Exclusive dummy toggle startup script.lua' script 
        from the Main section of the Action list, provided it's included in the SWS extension Startup 
	actions.
				
	SCREENSHOTS:  
	https://raw.githubusercontent.com/Buy-One/screenshots/main/Exclusive%20dummy%20toggle%20scripts.gif  
	Use case  https://raw.githubusercontent.com/Buy-One/screenshots/main/Insert%20note%20at%20constant%20velocity%20depending%20on%20dummy%20toggle%20scripts.gif
Metapackage: true
Provides: 	[main=main,midi_editor] .
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 1.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 2.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 3.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 4.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 5.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 6.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 7.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 8.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 9.lua
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] . > BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle 10.lua
		
		These scripts are available separately:
		[main=main,midi_editor,midi_inlineeditor,midi_eventlisteditor,mediaexplorer] BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle - spawn new script.lua
		[main] BuyOne_Exclusive dummy toggles/BuyOne_Exclusive dummy toggle startup script.lua
]]
-------------------------------------------------------------------------------------
---------------------------------- USER SETTINGS ------------------------------------
-------------------------------------------------------------------------------------

-- Add a letter between quotation marks to define a subset
-- per Action list section (the register doesn't matter);
-- to have mutually exclusive toggle states all scripts of a subset
-- in the corresponding Action list section should be assigned the same letter,
-- e.g. scripts 1 through 5 in the Main section could have A subset letter
-- (Main = "A") while scripts 6 through 10 could have B subset letter (Main = "B"),
-- consequently scripts 1 through 5 on the one hand and scripts 6 through 10
-- on the other would be mutually exclusive;
-- by default all scripts in the set are assigned the same letter per Action
-- list section which makes toggle states of all mutually exclusive;
-- empty slots and entries other than alphabetical (English) are not supported.

Main = "A"
MIDI_Ed = "A"
MIDI_Inline_Ed = "A"
MIDI_Ev_List = "A"
Media_Ex = "A"

-------------------------------------------------------------------------------------
------------------------------ END OF USER SETTINGS ---------------------------------
-------------------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function META_Spawn_Scripts(fullpath, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end
	
	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and fullpath:match(Esc(path)) then -- installed 
			return true end
		end
	end

	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then
	
--[[ GETTING PATH FROM THE USER INPUT

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)
	
	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD
	
	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]	
	
		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH
		
		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
		end
		
		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH BATCH SCRIPT INSTALLER VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTNIGS TRANSFER, get_action_context() is useless as a conditon since when this script is executed via dofile() from the installer script the function returns props of the latter		
		if script_is_installed(fullpath) then
			for _, sectID in ipairs{0,32060,32061,32062,32063} do -- Main, MIDI Ed, MIDI Evnt List, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end
		
	end

end



function Get_Dummy_Toggle_Scripts(sect_ID, SECT, curr_subset) -- collect all dummy toggle scripts in the same section and of the same subset as the current script to be able to set their state to OFF when the state of the current script is ON
local sep = r.GetResourcePath():match('[\\/]')
local res_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') -- path with separator
local cont
local f = io.open(res_path..'reaper-kb.ini', 'r')
	if f then -- if file available, just in case
	cont = f:read('*a')
	f:close()
	end
local t = {}
	if cont and cont ~= '' then
		for line in cont:gmatch('[^\n\r]*') do -- parse reaper-kb.ini code
		local comm_ID, scr_path = line:match('SCR %d+ '..sect_ID..' (.+) "Custom: .+_Exclusive dummy toggle %d+%.lua" "(.+)"')
			if comm_ID then
			-- get subset assignment of a found dummy toggle script
			local f = io.open(res_path..'Scripts'..sep..scr_path, 'r') -- get dummy toggle script code
			local cont = f:read('*a')
			f:close()
			local subset = cont:match('\n'..SECT[sect_ID]..' = "(.-)"') -- leading line break to exclude captures from the settings explanation text (Main = "A")
				if subset == curr_subset then
				t[#t+1] = r.NamedCommandLookup('_'..comm_ID) -- converting to integer
				end
			end
		end
	end
return t
end


local _, fullpath, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, 'BuyOne_Exclusive dummy toggles_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not

local SUBSETS = {[0] = Main, [32060] = MIDI_Ed, [32062] = MIDI_Inline_Ed, [32061] = MIDI_Ev_List, [32063] = Media_Ex}
local SECT = {[0] = 'Main', [32060] = 'MIDI_Ed', [32062] = 'MIDI_Inline_Ed', [32061] = 'MIDI_Ev_List', [32063] = 'Media_Ex'}
local curr_subset = SUBSETS[sect_ID]:gsub(' ',''):upper() -- removing spaces, capitalizing

	if #curr_subset == 0 or not curr_subset:match('[A-Z]') then -- throw an error if a subset setting is invalid
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n  invalid subset setting \n\n     for '..SECT[sect_ID]..' section \n\n  '):gsub('.','%0 '):upper(), x, y, true) -- topmost true
	return r.defer(no_undo)
	end

local t = Get_Dummy_Toggle_Scripts(sect_ID, SECT, curr_subset)
local toolbar = r.RefreshToolbar2
local section_name = 'BuyOne_Exclusive dummy toggle'

	for _, comm_ID in ipairs(t) do -- set ALL dummy toggle scripts in the same Action list section and of the same subset as the current one to OFF state
	r.SetToggleCommandState(sect_ID, comm_ID, 0)
	toolbar(sect_ID, comm_ID)
	end

r.SetToggleCommandState(sect_ID, cmd_ID, 1) -- set current one to ON
toolbar(sect_ID, cmd_ID)
r.SetExtState(section_name, 'section:'..sect_ID..'|subset:'..curr_subset, '_'..r.ReverseNamedCommandLookup(cmd_ID), true) -- persist true // update stored dummy toggle slot to be able to restore it at the start of the next REAPER session provided 'BuyOne_Exclusive dummy toggle startup script.lua' script is added to SWS startup actions; converted to named command ID so it's consistent across sessions (not sure this will be the case with numeric one)


do return r.defer(no_undo) end -- no Undo point






