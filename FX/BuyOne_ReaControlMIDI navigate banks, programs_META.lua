--[[
ReaScript name: BuyOne_ReaControlMIDI navigate banks, programs_META.lua (15 scripts since build 7.16, 12 otherwise)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 #Allowed creation of LSB navigation scripts regardless of REAPER build,
		which in builds older than 7.16 will now generate an error message because 
		those contain a bug https://forum.cockos.com/showthread.php?t=289639
		preventing these scripts from functioning properly
	    1.1 #Added Bank/Program select list LSB support for builds older than 7.15
		#Fixed .reabank file REABANK_FILE setting validation when its name doesn't contain spaces
		#Improved program navigation readout tooltip
		#Made tooltips more verbose
		#Updated the About text
Licence: WTFPL
REAPER: at least v5.962, 7.16 recommended
Metapackage: true
Provides: 	[main=main,midi_editor] .
		. > BuyOne_ReaControlMIDI select next bank (MSB).lua
		. > BuyOne_ReaControlMIDI select previous bank (MSB).lua
		. > BuyOne_ReaControlMIDI select next program.lua
		. > BuyOne_ReaControlMIDI select previous program.lua
		. > BuyOne_ReaControlMIDI select next bank with Bank Select slider (MSB).lua
		. > BuyOne_ReaControlMIDI select previous bank with Bank Select slider (MSB).lua
		. > BuyOne_ReaControlMIDI select next bank with Bank Select slider (LSB).lua
		. > BuyOne_ReaControlMIDI select previous bank with Bank Select slider (LSB).lua
		. > BuyOne_ReaControlMIDI cycle through banks (MSB) (mousewheel).lua
		. > BuyOne_ReaControlMIDI cycle through programs.lua
		. > BuyOne_ReaControlMIDI cycle through banks with Bank Select slider (MSB) (mousewheel).lua
		. > BuyOne_ReaControlMIDI cycle through banks with Bank Select slider (LSB) (mousewheel).lua		
		. > BuyOne_ReaControlMIDI select next bank (LSB).lua
		. > BuyOne_ReaControlMIDI select previous bank (LSB).lua
		. > BuyOne_ReaControlMIDI cycle through banks (LSB) (mousewheel).lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. 
	That's provided such scripts don't exist yet, if they do, 
	then in order to recreate them they have to be deleted from 
	the Action list and from the disk first.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name.  

	The scripts included in the package target ReaControlMIDI 
	instance whose name in FX chain contains the TAG which has 
	been defined in the USER SETTINGS. All FX chain types are 
	supported.
	
	!!! IMPORTANT !!! The TAG must be be followed by a space 
	if it's appended to the beginning of the FX instance name 
	(e.g. 'TAG My plugin'), preceded by space at the end of
	the name (e.g. 'My plugin TAG'), bordered by spaces in the 
	middle of the name (e.g. 'My TAG plugin') unless it only 
	consist of the TAG.
	
	The script targets the first found tagged ReaControlMIDI 
	instance. First it looks among tracks, then among takes.		

	Tracks hidden in Arrange view and items on such tracks 
	are ignored. 
	
	Due to REAPER bug https://forum.cockos.com/showthread.php?t=289639
	in builds older than 7.16 in rare use cases where bank LSB 
	number matters, program navigation scripts only support .reabank 
	programs under bank LSB 0. Therefore if you intend to use the 
	script with .reabank files make sure that bank LSB number 
	of all relevant program lists is 0.  
	Because of this even if any other LSB bank number is selected
	in the LSB field under Bank/Program Select, only programs belonging
	to bank under the LSB 0 will be navigated, provided there's LSB 0 
	under the current bank MSB number and a .reabank file is selected.
	See PROGRAM/PRESET NAVIGATION paragraph below.
	
	In scripts which contain 'CC slider (MSB)' verbiage in the 
	name, that is those aimed at navigation of MSB bank numbers 
	with a slider, the navigation step size is 128 when 'Raw mode' 
	option is disabled, i.e.  0 (1), 128 (2), 256 (3), 384 (4), 
	512 (5), 740 (6) ... 16256 (127). When 'Raw mode' option is 
	enabled the step size is 1. Selection of an MSB bank value is 
	also a selection of LSB bank number 0.
	
	In scripts which contain 'CC slider (LSB)' verbiage in the 
	name, that is those aimed at navigation of LSB bank numbers 
	with a slider, the navigation is limited to the LSB range of 
	the current MSB bank value, i.e. the LSB range of the MSB bank 
	value 0 (1) is 0 - 127, the LSB range of the MSB bank value 128 
	(2) is 128 - 255, that is current MSB bank value + 127.
	
	
	PROGRAM/PRESET NAVIGATION
	
	Scripts which contain the word 'program' in the name, that is
	those aimed at navigation of programs can be used to navigate
	presets in other plugins. For this to work the tagged instance
	of ReaControlMIDI must be inserted upstream of such plugins
	and the plugins themselves have set to receive program change 
	message via the + button -> Link to MIDI program change -> 
	Link all channels sequentially OR Channel 1-16.  
	To be able to navigate a selection of plugin presets create a 
	custom .reabank file listing in it only numbers of presets you 
	want to be able to switch and load it into the tagged 
	ReaControlMIDI instance. Obviously a maximum of 128 presets are
	supported. Current bank MSB and LSB numbers don't matter.	
	
	Plugin preset navigation as described above can be automated 
	with SWS/S&M extension action markers on the fly during 
	playback/recording to select specific program/preset. Ation 
	markers feature must be turned on in the extension settings 
	at 'Extensions -> SWS Options -> Marker actions' from the main 
	menu or directly with 'SWS: Enable marker actions' 
	or 'SWS: Toggle marker actions enable' 
	actions in the Action list.				
	
	If program numbers are specified in action markers to trigger
	program/preset selection they must be 0-based, i.e. 0 = preset 1, 
	1 = preset 2, 2 = preset 3 and so on, that is using numbering 
	convention supported by .reabank files regardless of actual
	use of .reabank file.
	
	The action marker name must adhere to the following formats:

	1) !_RSceeb8ead418881000e42adc04b33bd67d04e3d79 ; 6		
	Where: '!' is the action marker modifier, always the same;
	'_RSceeb8ead418881000e42adc04b33bd67d04e3d79' is this script 
	command ID or a command ID of a custom/cycle action featuring this 
	script, which can be copied from their right click context menu 
	in the Action list with 'Copy selected action command ID' option, 
	will be different in your installation;
	and '6' is the program number which will trigger selection 
	of preset 7 (6+1) in the target plugin
	
	2) !_RSceeb8ead418881000e42adc04b33bd67d04e3d79 ; My program name
	Where: 'My program name' is the program name found in the .reabank 
	file. The program name will be searched in the entire .reabank file 
	and the number associated with the first found instance will trigger 
	preset selection in the target plugin.
	This format is only relevant if REABANK_FILE setting has been 
	enabled in the USER SETTINGS.
	
	The formats 1) and 2) are suitable in most cases because most 
	plugins don't support multiple banks and subbanks which could be 
	selected with MIDI Bank Select MSB and LSB messages.  
	
	Selection of plugin presets via ReaControlMIDI works regardless
	of bank MSB and LSB values, only program numbers matter.
	

	3) !_RSceeb8ead418881000e42adc04b33bd67d04e3d79 ; 0 0 6
	Where: first '0' is the bank MSB value, second '0' is the bank LSB 
	value and '6' is the program number which will trigger selection 
	of preset 7 in the target plugin
	
	4) !_RSceeb8ead418881000e42adc04b33bd67d04e3d79 ; 0 0 My program name
	Where: first '0' is the bank MSB value, second '0' is the bank LSB 
	value and 'My program name' is the program name in the listed MSB
	and LSB banks. The program number associated with the first found 
	instance of this program name will trigger preset selection in the 
	target plugin.  
	This format is only relevant if REABANK_FILE setting has been 
	enabled in the USER SETTINGS.
	
	The formats 3) and 4) are much less suitable for the same reason 
	why formats 1) and 2) are much more suitable.		
	
	C a v e a t

	If after a particular preset selection was triggered in the target 
	plugin from the action marker with one of program related scripts 
	as decribed above via ReaControlMIDI and then another preset was 
	selected manually or by other means in the target plugin, it won't
	be possible to re-trigger selection of the same preset again from
	the action marker unless selection of another preset was triggered
	via ReaControlMIDI. That's because after the first trigger, the 
	program value in ReaControlMIDI doesn't change or reset when another 
	preset is selected by other means in the target plugin, while program 
	select message sent by ReaControlMIDI is based on changing values.
	
	If you prefer selecting presets via ReaConrolMIDI plugin by relying 
	on a .reabank file you may be interested in the script 
	BuyOne_Generate .reabank file from FX preset list.lua
	https://github.com/Buy-One/REAPER-scripts/blob/main/FX/BuyOne_Generate%20.reabank%20file%20from%20FX%20preset%20list.lua
	
	
	MOUSEWHEEL
	
	When running scripts from the package which are supposed to be run 
	with the mouswheel (unclude 'mouswheel' verbiage in their name) 
	the mouse cursor must be located outside of ReaControlMIDI UI to prevent 
	on one hand affecting the controls with the mousewheel directly rather 
	than via the script when the preference at 'Editing Behavior -> Mouse -> 
	Ignore mousewheel on all faders' is disabled, and on the other to be able 
	to call the script to begin with when it's enabled because in this case
	mousewheel over the plugin UI will be ignored.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Place any alphanumeric character or a combination thereof
-- between the double square brackets;
-- leading/trailing spaces will be ignored
TAG = [[X]]


-- Optionally insert .reabank file name, with or without the extension,
-- to be able to navigate through a limited list of banks/programs;
-- the file must be located in the /Data folder inside REAPER
-- resource directory, where the stock GM.reabank file
-- is located, and since the ReaScript API doesn't allow detection
-- of the .reabank file loaded into the 'Bank/Pogram Select' section
-- of a ReaConrolMIDI instance, the file name must be specified
-- in this setting even if it's not loaded into the ReaConrolMIDI,
-- but if it is, both files must be the same so navigation makes
-- sense, otherwise bewildering irregularities will occur;
-- if no file has been loaded into the tagged instance of ReaControlMIDI
-- but 'Bank/Program Select' section has been enabled, the values will
-- only be displayed in the raw UI of ReaControlMIDI instance activated
-- with the UI button;
-- if no file name is specified in this setting, the script will cycle
-- through all 127 banks/programs sequentially
-- regardless of a .reabank file being loaded into ReaControlMIDI
REABANK_FILE = ""


-- Only relevant to scripts containing '(mousewheel)' verbiage
-- in their name;
-- the default direction is:
-- mousewheel out/up - ascending order,
-- mousewheel in/down - descending order;
-- Enable by inserting any alphanumeric character
-- between the quotes to reverse the direction
MOUSEWHEEL_REVERSE = ""

-- Enable by inserting any alphanumeric character between the quotes
-- to make the script create undo point after every run;
-- may not be desirable for script versions supporting mousewheel
-- because scrolling will inundate the undo history with multiple
-- undo points;
-- if the script is triggered from an action marker, an undo pount
-- will be created regardless of this setting
UNDO = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


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


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

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
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

		if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

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

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		-- spawn scripts
		-- THERE'RE USER SETTINGS OR THE META SCRIPT IS ALSO FUNCTIONAL SO FILES AREN'T UNNECESSARILY CREATED WHEN IT RUNS
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed, MIDI Evnt List, Media Ex // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found
-- only execute once
local t = {...}

	for k, elm in ipairs(t) do
		if scr_name:lower():match(Esc(elm:lower())) then return elm end -- at least one match was found
	end

end
-- USE:
--[[
local keyword = Invalid_Script_Name3(scr_name, 'right', 'left', 'up', 'down')
	if not keyword then r.defer(no_undo) end

	if keyword == 'right' then
	-- DO STUFF
	elseif keyword == 'left' then
	-- DO STUFF
	-- ETC.
	end
]]



function Parse_Script_Name(scr_name, ...)
-- meant for multi-functional scripts with mutually exclusive functionalities
-- which depend on the script name, e.g.
-- move forward, move backwards, select next, select previous, etc.
-- t contains strings of key words definding functionality included in the script name
-- case agnostic
local t = {...}
local t_len = #t -- store here since with nils length will be harder to get
	for k, elm in ipairs(t) do
	t[k] = scr_name:lower():match(Esc(elm:lower())) --or false -- to avoid nils in the table, although still works with the method below
	end
-- return table.unpack(t) -- without nils
return table.unpack(t,1,t_len) -- not sure why this works, not documented anywhere, but does return all values if some of them are nil even without the n value (table length) in the 1st field
-- found mentioned at
-- https://stackoverflow.com/a/1677358/8883033
-- https://stackoverflow.com/questions/1672985/lua-unpack-bug
-- https://uopilot.tati.pro/index.php?title=Unpack_(Lua)
end



function EvaluateTAG(fx_name,TAG)
return fx_name:match('^('..Esc(TAG)..')%s')
or fx_name:match('%s('..Esc(TAG)..')%s')
or fx_name:match('%s('..Esc(TAG)..')$')
or fx_name:match('^%s*'..Esc(TAG)..'%s*$') -- when the TAG is the whole name
end



function Process_Mouse_Wheel_Direction(val, mousewheel_reverse)
-- val comes from r.get_action_context()
-- mousewheel_reverse is boolean
-- if mouse scrolling up val = 15 - righwards, if down then val = -15 - leftwards
local left_down, right_up = table.unpack(mousewheel_reverse
and {val == 15, val < 0} or {val < 0, val == 15}) -- left/down, right/up
return left_down, right_up
end



function Parse_ReaBank_File(file_name)
-- the expected location is /Data folder in the REAPER resource directory
	if file_name then
	local file_name = file_name:match('^%s*(.-)%s*$') -- strip leading and trailing spaces
--Msg(file_name)
	file_name = file_name:lower():match('%.reabank') and file_name
	or file_name..'.reabank'
	local sep = r.GetResourcePath():match('[\\/]')
	local path = r.GetResourcePath()..sep..'Data'..sep..file_name
		if not r.file_exists(path) then
		Error_Tooltip('\n\n the .reabank file wasn\'t \n\n found in the /data folder \n\n', 1, 1) -- caps, spaced true
		return true end -- to condition abort outside
	local t, bank_MSB_init, bank_LSB_init = {}
		for line in io.lines(path) do
			if line:lower():match('^%s*bank') then -- this cond also ignores commented out lines
			-- if bank header is malformed in the file the bank won't be listed in ReaControlMIDI
			-- extra spaces are ignored
			-- the order of bank numbers in the .reabank file is immaterial for ReaControlMIDI
			local bank_MSB, bank_LSB, bank_name = line:match('[BbAaNnKk]+[%s\t]*(%d+)[%s\t]*(%d+)[%s\t]*(.*)')
				if bank_MSB and bank_LSB then -- collect bank numbers
					if bank_MSB ~= bank_MSB_init then -- new bank MSB number
					t[bank_MSB+0] = {[bank_LSB+0] = {name = #bank_name > 0 and bank_name or 'no bank name'}}
					else -- same bank MSB number, add new LSB table
					t[bank_MSB_init+0][bank_LSB+0] = {}
					t[bank_MSB_init+0][bank_LSB+0].name = #bank_name > 0 and bank_name or 'no bank name'
					end
				bank_MSB_init, bank_LSB_init = bank_MSB, bank_LSB -- store/update
				end
			-- order of the program numbers in the .reabank file doesn't affect their order
			-- in ReaControlMIDI, the numbering doesn't have to be sequential
			elseif bank_MSB_init and #line > 0 and not line:match('^[%s\t]*//') then -- OR match('^[%s\t]*%d+'), collect programs props, ignoring empty and commented out lines
			local prog_No, prog_name = line:match('^[%s\t]*(%d+)[%s\t]*(.*)')
				if prog_No then
				t[bank_MSB_init+0][bank_LSB_init+0][prog_No+0] = #prog_name > 0 and prog_name or 'no prog name'
				end
			end
		end
	return next(t) and t -- return if table is likely populated, only evaluates bank MSB field hence not failproof
	end
end


function Process_FX_Incl_In_All_Containers(obj, recFX, parent_cntnr_idx, parents_fx_cnt, TAG)
-- https://forum.cockos.com/showthread.php?t=282861
-- https://forum.cockos.com/showthread.php?t=282861#18
-- https://forum.cockos.com/showthread.php?t=284400

-- obj is track or take, recFX is boolean to target input/Monitoring FX
-- parent_cntnr_idx, parents_fx_cnt must be nil

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
-- OR
-- local tr, take = r.ValidatePtr(obj, 'MediaTrack*') and obj, r.ValidatePtr(obj, 'MediaItem_Take*') and obj // may be required to pass into the sub-function which does the processing

local FXCount, GetIOSize, GetConfig, SetConfig, GetFXName =
table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm,
r.TrackFX_SetNamedConfigParm, r.TrackFX_GetFXName}
or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm,
r.TakeFX_SetNamedConfigParm, r.TakeFX_GetFXName} or {})

local fx_cnt = not parent_cntnr_idx and (recFX and r.TrackFX_GetRecCount(obj) or FXCount(obj))
fx_cnt = fx_cnt or ({GetConfig(obj, parent_cntnr_idx, 'container_count')})[2]

	if tr or take then
		for i = 0, fx_cnt-1 do
		-- only add 0x1000000 to fx index to target input/Monitoring fx inside the outermost fx chain
		-- (at this stage parent_cntnr_idx is nil)
		local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
		-- only use formula to calculate indices of fx in containers once parent_cntnr_idx var is valid
		-- to keep the indices of fx in the root (outermost) fx chain intact
		i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
		local container = GetIOSize(obj, i) == 8
			if container then
			-- DO STUFF TO CONTAINER (if needed) and proceed to its FX;
			-- the following vars must be local to not interfere with the current loop and break i expression above
			-- only add 0x2000000+1 to the very 1st (belonging to the outermost FX chain) container index
			-- (at this stage parent_cntnr_idx is nil)
			-- and then keep container index obtained via the formula above throughout the recursive loop
			local parent_cntnr_idx = parent_cntnr_idx and i or 0x2000000+i+1
			-- multiply fx counts of all (grand)parent containers by the fx count
			-- of the current one + 1 as per the formula;
			-- accounting for the outermost fx chain where parents_fx_cnt is nil
			local parents_fx_cnt = (parents_fx_cnt or 1) * (fx_cnt+1)
			local fx_idx, fx_name = Process_FX_Incl_In_All_Containers(obj, recFX, parent_cntnr_idx, parents_fx_cnt, TAG) -- recFX can be nil/false // go recursive
				if fx_idx then return fx_idx, fx_name end
			else
			-- DO STUFF TO FX
			local ret, fx_name = GetFXName(obj, i, '')
				if EvaluateTAG(fx_name, TAG) then return i, fx_name end
			end
		end
	end

end



function Validate_FX_Identity(obj, fx_idx, fx_name, parm_t, TAG)
-- the function is based on Get_FX_Parm_Orig_Name() above
-- in case it's been aliased by the user
-- obj is track or take
-- fx_name is the original name of the plugin being validated
-- parm_t is a table indexed by param indices whose fields hold corresponding original param names
-- e.g. {[4] = 'parm name 4', [12] = 'parm name 12', [23] = 'parm name 23'}
-- TAG is a user TAG added to FX name in the FX chain
-- to mark is as a target for script, optional
-- works with builds 6.37+
-- relies on Esc() function
local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetFXName, GetConfig, CopyFX =
table.unpack(tr and {r.TrackFX_GetFXName, r.TrackFX_GetNamedConfigParm, r.TrackFX_CopyToTrack}
or take and {r.TakeFX_GetFXName, r.TakeFX_GetNamedConfigParm, r.TakeFX_CopyToTrack} or {})
-- get name displayed in fx chain
local retval, fx_chain_name = GetFXName(obj, fx_idx, '')
local TAG = TAG and Esc(TAG)
fx_chain_name = TAG and fx_chain_name:gsub(TAG,'') or fx_chain_name -- if TAG is supplied removing to be able to evaluate clean name
	if fx_chain_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix

-- if fx chain displayed name doesn't match the user supplied name, meaning was renamed
-- get fx browser displayed name in builds which support this option

local build_6_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37

local orig_fx_name

	if build_6_37 then
	retval, orig_fx_name = GetConfig(obj, fx_idx, 'original_name') -- or 'fx_name' // returned with fx type prefix
		if orig_fx_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix
	end

-- if validation by the original name failed or wasn't supported
-- validate using parameter names

-- add temp track and copy the fx instance to it
r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
-- search for the name of fx parameter at the same index as the one being evaluated, in the copy of the fx
-- on the temp track
CopyFX(obj, fx_idx, temp_track, 0, false) -- is_move false
local name_match = true
	for i = 0, r.TrackFX_GetNumParams(temp_track, 0)-1 do -- fx_idx 0
	local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, i, '') -- fx_idx 0
		if parm_t[i] and parm_t[i] ~= parm_name then
		-- break rather than return to allow deletion of the temp track
		-- before returning the value
		name_match = false break
		end
	end

-- if name_match ends up being false there's possibility that the parameters have been aliased
-- in which case collate parm names in the clean instance of the fx loaded from the fx browser in builds 6.37+
	if build_6_37 then
	-- delete fx instance copied in the previous routine to the temp track
	r.TrackFX_Delete(temp_track, 0)
	-- use fx name displayed in fx browser
	-- to insert FX instance on the temp track
	-- the fx names retrieved with GetNamedConfigParm() always contain fx type prefix,
	-- the function FX_AddByName() supports fx type prefixing but in the retrieved fx name
	-- the fx type prefix is followed by space which wasn't allowed in FX_AddByName()
	-- before build 7.06 so it must be removed, otherwise the function will fail
	-- https://forum.cockos.com/showthread.php?t=285430
	orig_fx_name = orig_fx_name:gsub(' ','',1) -- 1 is index of the 1st space in the string
	r.TrackFX_AddByName(temp_track, orig_fx_name, 0, -1000) -- insert // recFX 0 = false, instantiate at index 0
	name_match = true
		for i = 0, r.TrackFX_GetNumParams(temp_track, 0)-1 do -- fx_idx 0
		local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, i, '') -- fx_idx 0
			if parm_t[i] and parm_t[i] ~= parm_name then
			-- break rather than return to allow deletion of the temp track
			-- before returning the value
			name_match = false break
			end
		end
	end

r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)

return name_match

end



function Switch_Bank_Program(obj, fx_idx, scr_name, down, up, reabank_t)
-- obj is track or take
-- fx_idx is idx of the fx whose name in the fx chain contains the tag
local nxt, prev, MSB, LSB, bank_select, prog = Parse_Script_Name(scr_name, 'next', 'previous', '(MSB)', '(LSB)', 'Bank Select', 'program')
nxt, prev = up or nxt, down or prev
local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetNumParams, GetParm, SetParm, GetParmName = table.unpack(tr and {r.TrackFX_GetNumParams, r.TrackFX_GetParam, r.TrackFX_SetParam, r.TrackFX_GetParamName}
or take and {r.TakeFX_GetNumParams, r.TakeFX_GetParam, r.TakeFX_SetParam, r.TakeFX_GetParamName} or {})

--[[ ORDER: 0 Bank MSB, 1 Bank LSB, 2 Program, 3 <CC slot 1> Bank Select, 4 <CC slot 2> Pan
5 <CC slot 3> Pitch Wheel, 6 <CC slot 4>, 7 <CC slot 5>, 8 Channel, 9 Transpose,
10 Snap to Scale, 11 Scale Root, 12 Scale Type, 13 Bank/Program Enable, 14 CC Enable
15 = Bypass, 16 = Wet, 17 = Delta
ALL use normalized scale, 0-1, so no way to recognize param by its unique scale, only by name or order
]]

	local function get_new_val(cur_val, sought_val, nxt_val, prev_val, max_val, min_val)
	local nxt_val = (not nxt_val and sought_val > cur_val or nxt_val and sought_val > cur_val and sought_val < nxt_val)
	and sought_val or nxt_val
	local prev_val = (not prev_val and sought_val < cur_val or prev_val and sought_val < cur_val and sought_val > prev_val)
	and sought_val or prev_val
	local max_val = (not max_val and sought_val > cur_val or max_val and sought_val > max_val) and sought_val or max_val
	local min_val = (not min_val and sought_val < cur_val or min_val and sought_val < min_val) and sought_val or min_val
	return nxt_val, prev_val, max_val, min_val
	end

	local function get_reabank_value(t, MSB, LSB, prog, cur_msb, cur_lsb, cur_val, nxt, prev)
	local cur_val = math.floor(cur_val*127+0.5) -- convert to integer & round off
	-- min and max are for scenarios when the cur_val is the max or min respectively to wrap around
	local nxt_val, prev_val, max_val, min_val
		if MSB then
			for msb, data in pairs(t) do
			nxt_val, prev_val, max_val, min_val = get_new_val(cur_val, msb, nxt_val, prev_val, max_val, min_val)
			end
		elseif LSB and t[cur_msb] then -- SUPPORTED SINCE build 7.16 due to bug in previous builds
			for lsb, proggs in pairs(t[cur_msb]) do
			nxt_val, prev_val, max_val, min_val = get_new_val(cur_val, lsb, nxt_val, prev_val, max_val, min_val)
			-- proggs.name -- LSB bank name
			end
		elseif prog and t[cur_msb] and t[cur_msb][cur_lsb] then -- MSB and LSB bank is found in .reabank file
			for no, name in pairs(t[cur_msb][cur_lsb]) do -- look for programs
				if tonumber(no) then -- OR 'no ~= 'name', not name field which holds bank name associated with current bank LSB number
				nxt_val, prev_val, max_val, min_val = get_new_val(cur_val, no, nxt_val, prev_val, max_val, min_val)
				end
			end
		end
	local val_new = nxt and (nxt_val or min_val) or prev and (prev_val or max_val) -- wrapping around at the start or end of the list
	return val_new
	end

local mess, err
local undo = 'Set ReaControMIDI '

	if not bank_select and (MSB or LSB or prog) then -- Bank/Program file selector
		if GetParm(obj, fx_idx, 13) == 0 then -- 13 'Bank/Program Enable' is disabled
		mess = ' "Bank/Program Select" setting \n\n\t\t is disabled'
		err = true
		else
		local parm_idx = MSB and 0 or LSB and 1 or 2 -- 2 is program
		local typ = MSB and 'MSB' or LSB and 'LSB' or 'Program'
		local val, max, min = GetParm(obj, fx_idx, parm_idx)
	--	!!! In builds prior to 7.16 FX_GetParam() returns MSB value for LSB param and LSB param cannot be set reliably
	--	bug report https://forum.cockos.com/showthread.php?t=289639
		local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.16
		local val_new

			if reabank_t then -- content of the reabank file whose name has been supplied by the user; only navigate existing banks/programs
			local cur_msb, max, min = GetParm(obj, fx_idx, 0) -- get current MSB number to limit programs navigation to it and display in program readout tooltip
			cur_msb = math.floor(cur_msb*127+0.5)
			local cur_lsb = old_build and 0 or GetParm(obj, fx_idx, 1) -- get current LSB number to limit programs navigation to it, IN BUILDS OLDER THAN 7.16 DUE TO LSB RETURN VALUE BUG (see above) ONLY LSB VALUE 0 IS SUPPORTED
			cur_lsb = math.floor(cur_lsb*127+0.5) -- in buids older than 7.16 for consistency as if the value was returned by the GetParm() function, otherwise 0 doesn't need any calculation
			val_new = get_reabank_value(reabank_t, MSB, LSB, prog, cur_msb, cur_lsb, val, nxt, prev)
				if not val_new then
				mess = MSB and ' there\'s only 1 bank'
				or LSB and ' there\'s only 1 LSB bank\n\nunder current MSB bank '..cur_msb -- THIS IS ONLY RELEVANT FOR BUILDS NEWER THAN 7.16 DUE TO THE ABOVEMENTIONED BUG
				or prog and reabank_t[cur_msb] and not reabank_t[cur_msb][cur_lsb] -- THIS IS ONLY RELEVANT FOR BUILDS OLDER THAN 7.16 DUE TO THE ABOVEMENTIONED BUG WHERE PROGRAM NAVIGATION ONLY SUPPORTED FOR LSB 0 WHICH MIGHT BE ABSENT IN the .reabank file
				and '   bank LSB '..cur_lsb..' was\'t found \n\n     in the .reabank file \n\n under current bank msb '..cur_msb
				or prog and ' there\'s only 1 or no programs \n\n\t  in the current bank'
				err = true
				else
				-- concatenate a tooltip text
				local lsb_name = reabank_t[cur_msb][cur_lsb].name
				local prog_name = reabank_t[cur_msb][cur_lsb][val_new]
				mess = MSB and '  '..typ..' '..val_new..' '
				or LSB and ' MSB '..cur_msb..'\n\n LSB '..cur_lsb..' "'..lsb_name..'"' -- IN Bank/Program file selector LSB IS NOT SUPPORTED IN BUILDS OLDER THAN 7.16 DUE TO THE ABOVEMENTIONED BUG
				or prog and ' MSB '..cur_msb..'\n\n LSB '..cur_lsb..' "'..lsb_name..'" \n\n Program: '
				..val_new..' '..(#prog_name < 21 and prog_name or '\n\n '..prog_name) -- to make sure that the program name doesn't get split between two lines if long, however not failproof if its extra long and doesn't fit a full line after the line break

				undo = MSB and undo..'bank MSB to '..val_new or LSB and undo..'bank MSB '..cur_msb..' bank LSB to '..val_new
				or prog and undo..'bank MSB '..cur_msb..' bank LSB '..cur_lsb..' "'..lsb_name..'" program to '..val_new
				..' '..prog_name

				val_new = val_new*(1/127) -- convert to the normalized value to apply

				end

			else -- no reabank file name has been supplied by the user OR its content couldn't be parsed, switch sequentially in ascending/descending order
			val_new = nxt and (val == 1 and 0 or val + 1/127) or prev and (val == 0 and 1 or val - 1/127)

			local val_new = math.floor(val_new*127+0.5) -- round and strip trailing decimal 0, here and below // local var doesn't seem to override the global one above which is use to set the new value below with SetParm()
			local cur_msb = math.floor(GetParm(obj, fx_idx, 0)*127+0.5)
			local cur_lsb = old_build and 0 or math.floor(GetParm(obj, fx_idx, 1)*127+0.5) -- get current LSB number to limit programs navigation to it, IN BUILDS OLDER THAN 7.16 DUE TO LSB RETURN VALUE BUG (see above) ONLY LSB VALUE 0 IS SUPPORTED
			mess = MSB and '  '..typ..' '..val_new..' ' or LSB and ' MSB '..cur_msb..'   LSB '..val_new
			or prog and ' MSB '..cur_msb..'   LSB '..cur_lsb..'\n\n Program: '..val_new

			end

			local set = val_new and SetParm(obj, fx_idx, parm_idx, val_new)

		end

	elseif bank_select then -- CC slider
		if GetParm(obj, fx_idx, 14) == 0 then -- 14 'CC Enable' is disabled
		mess = ' "CC Slots" are disabled '
		err = true
		else
		local found

			for i=3, 7 do -- 5 Control Change slots, param indices from 3 to 7
			local ret, parm_name = GetParmName(obj, fx_idx, i, '')

				if parm_name:match('Bank Select') then
				local val, max, min = GetParm(obj, fx_idx, i)
				val = val > 1 and 1 or val < 0 and 0 or val -- rectify invalid values if any have been input manually
				local raw = parm_name:match('CC 0') -- CC slot name is preceded by CC # if Raw mode option is enabled, i.e. 7 bit resolution (0-127)
				local unit = raw and 1/127 or 1/16383 -- raw only allows access to MSB (7 bit) range
				local val_new

					if not raw and MSB then -- MSB values step size is 128

					local mult = val/(unit*128) -- find multiple of 128 in the current value (0 - 127 include 128 values)
					local integ = math.floor(mult+0.5) -- round off
					val_new = nxt and (integ == 128 and 0 or 128*(integ+1)*unit) -- wrap around if MSB is 127
					or prev and (val == 0 and 128*127*unit or 128*(integ-1)*unit) -- wrap around if MSB is 0
					mess = ' MSB '..math.floor(val_new/unit/128+0.5) -- tooltip

					elseif not raw and LSB then

					val = math.floor(val/unit+0.5) -- convert to regular integer which is much easier and more reliable to use for calculaions
					local mult1 = math.floor(val/128) -- find multiple of 128 in the current value
					val_new = nxt and val+1 or prev and val-1
					local mult2 = math.floor(val_new/128) -- find multiple of 128 in the new value
					val_new = nxt and (mult2 > mult1 and 128*mult1 or val_new) -- if value exceeds the next MSB value (mult2*128), wrap around to stay within the current MSB range, i.e. MSB - MSB+127
					or prev and (mult2 < mult1 and mult1*128+127 or val_new) -- if value goes past the current MSB value (mult1*128), wrap around to stay within the current MSB range, i.e. MSB - MSB+127
					local integ = math.modf(val_new/128) -- isolate the integral part of the multiple to calculate the MSB value
					local displ_val = val_new-integ*128 -- subtract MSB value
					mess = ' MSB '..integ..'   LSB '..displ_val -- tooltip

					val_new = val_new*unit -- normalize for setting the value

					elseif MSB then -- raw
					val_new = nxt and (val == 1 and 0 or val + unit) or prev and (val == 0 and 1 or val - unit)
					mess = ' Bank Number '..math.floor(val_new/unit+0.5) -- tooltip

					elseif LSB then -- raw

					mess = ' Raw Program Change range \n\n  doesn\'t include LSB range '
					err = true

					end

				local set = val_new and SetParm(obj, fx_idx, i, val_new)
				undo = MSB and undo..'Bank Select slider MSB value to '..mess:match('%d+') -- extracting from mess var where it's already calculated
				or not raw and LSB and undo..'Bank Select slider MSB '..mess:match('%d+')..' LSB value to '..mess:match('%d+.-(%d+)')
				found = 1
				break -- out of the loop
				end
			end
			if not found then
			mess = ' Bank Select message \n\n     is not enabled'
			err = true
			end
		end
	end

	if mess then
	Error_Tooltip('\n\n'..mess..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	end

return err, undo
end


function Re_Store_Data(named_ID, obj, fx_idx)
	if obj and fx_idx then -- store
	local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
	local GetFX_GUID = tr and r.TrackFX_GetFXGUID or take and r.TakeFX_GetFXGUID
	local fx_GUID = GetFX_GUID(obj, fx_idx)
	tr = take and r.GetMediaItemTake_Track(obj) or obj
	local take_idx = take and r.GetMediaItemTakeInfo_Value(obj, 'IP_TAKENUMBER') or ''
	local item = take and r.GetMediaItemTake_Item(obj) or 'userdata: ' -- or a placeholder to simplify capture when no item
	local data = string.format('%s %s %s %s %s', tostring(tr), fx_idx, fx_GUID, tostring(item), take_idx)
	r.SetExtState(named_ID, 'ReaControlMIDI', data, false) -- persist false
	else -- restore
	local data = r.GetExtState(named_ID, 'ReaControlMIDI')
	local tr, fx_idx, fx_GUID, item, take_idx = data:match('(userdata: .-) (.-) (.-) (userdata: .-) (.*)') -- or (.-)$ as last capture
	return tr, fx_idx, fx_GUID, item, take_idx
	end
end



function Get_Set_Program_From_Action_Marker(cmd_ID, reabank_t, mrkr_data, obj, fx_idx) -- only supported in program select scripts
-- mrkr_data arg is a table, only used at the Set stage

	if not mrkr_data then -- GET

	local mrkr_data = {}

	local play_state = r.GetPlayState()

		if r.GetToggleCommandStateEx(0, r.NamedCommandLookup('_SWSMA_TOGGLE')) == 1 -- SWS: Toggle marker actions enabled
		and (play_state & 1 == 1 -- playing
		or play_state & 4 == 4) -- recording
		then
		local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
		local play_pos = r.GetPlayPosition()
		local mrk_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, play_pos)
		local retval, isrgn, mrk_pos, rgnend, mrk_name, mrk_num = r.EnumProjectMarkers(mrk_idx)
		local prog = mrk_name:match('!%s*_'..cmd_ID..'.-%s;.-%s(.+)$') -- accounting for mulitple leading empty spaces // the command ID and program address must be separated by semi-colon ; padded with spaces, i.e. 'command_ID ; program address, because action markers allow multiple space separated command IDs and program number separated by a space only will be treated as another action command ID
		prog = prog:match('.*[%w%p]') -- trimming trailing empty space if any, accounting for a single numeral

			if tonumber(prog) then -- reabank file isn't needed
			mrkr_data = {prog+0} -- one numeral, i.e. program number // current msb/lsb will be used

			else
			msb, lsb, progNo = prog:match('(%d+) (%d+) (%d+)') -- DUE TO BUG https://forum.cockos.com/showthread.php?t=289639 IN BUILDS OLDER THAN 7.16 ONLY LSB 0 IS SUPPORTED, HERE AND BELOW

				if msb -- captures are valid, all are numerals
				then -- reabank file isn't needed
				mrkr_data = {msb+0, lsb+0, progNo+0} -- IN BUILDS OLDER THAN 7.16 ONLY LSB 0 IS SUPPORTED

				else -- see if program is represented by a name rather than by number, in which case reabank_t must be valid
				msb, lsb, prog_name = prog:match('(%d+) (%d+) (.+)')
				local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.16 -- used to condition LSB value 0 below for builds older than 7.16 due to the abovementioned bug
				local t = msb and reabank_t and (old_build and reabank_t[msb+0][0] or reabank_t[msb+0][lsb+0])
					if t then -- program is likely a string rather than a number
						for no, name in pairs(t) do
							if no ~= 'name' -- not name field which holds bank name associated with current bank LSB number
							and name:lower() == prog_name:lower() then
							mrkr_data = {msb+0, lsb+0, no} -- IN BUILDS OLDER THAN 7.16 ONLY LSB 0 IS SUPPORTED
							break end
						end
					end
				end

			end

			if prog and reabank_t then -- likely only program name, search in the entire .reabank content
				for msb_no, data in pairs(reabank_t) do
					for lsb_no, progs in pairs(data) do
						for no, name in pairs(progs) do
							if no ~= 'name' -- not name field which holds bank name associated with current bank LSB number
							and name:lower() == prog:lower() then
							mrkr_data = {msb_no, lsb_no, no}
							break end
						end
					end
				end
			end

			if #mrkr_data > 0 then
			return mrkr_data
			else
			Error_Tooltip('\n\n   the program specified \n\n in the action marker wasn\'t found \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
			end

		end -- action markers toggle and play state evaluation end

	else -- valid mrkr_data table, SET

	local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
	local GetParm, SetParm = table.unpack(tr and {r.TrackFX_GetParam, r.TrackFX_SetParam}
	or take and {r.TakeFX_GetParam, r.TakeFX_SetParam} or {})
	local unit = 1/127
	local err =  GetParm(obj, fx_idx, 13) == 0 and  -- 13 'Bank/Program Enable' is disabled
	'\t    ReaControlMIDI \n\n "Bank/Program Select" setting \n\n\t\t is disabled '
	or #mrkr_data == 1 and math.floor(GetParm(obj, fx_idx, 2)*127+0.5) == mrkr_data[1] and -- compare integers, floats are unreliable
	' The program number '..mrkr_data[1]..' \n\n  is already selected. \n\n   Cannot re-apply it. ' -- in case where the slave plugin preset was changed by means other than ReaControlMIDI the last ReaControlMIDI program value won't change and so cannot be re-applied on the next action marker trigger, must first be switched to another program; it's possible to toggle program numbers programmatically but this is likely to cause sonic glitches produced by the slave plugin at the moment of preset toggle and therefore is undesirable

		if err then -- 13 'Bank/Program Enable' is disabled
		Error_Tooltip('\n\n'..err..'\n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
		elseif #mrkr_data == 1 then -- only program number was included in the action marker
		SetParm(obj, fx_idx, 2, mrkr_data[1]*unit) -- set program in the current bank msb/lsb

		else -- full program address was included in the action marker: msb, lsb, program
			for idx, val in ipairs(mrkr_data) do -- set all 3 params: msb, lsb, program
			-- THE LSB BUG DOESN'T APPLY TO SETTING LSB VALUE
			SetParm(obj, fx_idx, idx-1, val*unit) -- idx-1 to accomodate 0-based param indices
			end
		end

	end

end



local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.16
	and scr_name:match('LSB') and not scr_name:match('slider') then
	-- prevent running of 'Bank/Program Select' LSB navigation scripts in builds older than 7.16 due to bug
	-- of FX_GetParam() function returning MSB value for LSB param https://forum.cockos.com/showthread.php?t=289639
	-- ReaControlMIDI select next bank (LSB).lua
	-- ReaControlMIDI select previous bank (LSB).lua
	-- ReaControlMIDI cycle through banks (LSB) (mousewheel).lua
	Error_Tooltip('\n\n      this script only works \n\n in reaper builds 7.16 onwards \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo)
	end


	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_ReaControlMIDI navigate banks, programs_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

--[[--------- NAME TESTING --------------
--REABANK_FILE = "GM"
--scr_name = 'next/previous bank (MSB)'
--scr_name = 'next/previous bank (LSB)' -- NOT SUPPORTED IN BUILDS OLDER THAN 7.16
--scr_name = 'ReaControlMIDI next/previous program'
--scr_name = 'next/previous bank select control change slider (MSB)'
--scr_name = 'next/previous bank select control change slider (LSB)'
--scr_name = 'scroll through banks (MSB) (LSB) / programs (mousewheel)'
--]]---------------------------------------


local elm1 = Invalid_Script_Name(scr_name, 'next','previous','cycle')
local elm2 = Invalid_Script_Name(scr_name, 'MSB','LSB','program')
local elm3 = Invalid_Script_Name(scr_name, 'bank with Bank Select slider', 'bank', 'program')
local elm4 = Invalid_Script_Name(scr_name, 'ReaControlMIDI')

local err

	if not (elm1 or elm2 or elm3 or elm4) then
	-- either no keyword was found in the script name or no keyword arguments were supplied
	err = 'The script name has been changed\n\n    which renders it inoperable. \n\n'
	..' please restore the original name\n\n\t referring to the names\n\n\t\t in the header,\n\n'
	..'\tor reinstall the package.'
	end

local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
TAG = TAG:match('[%w%p].+[%w%p]') or TAG:match('[%w%p]+') -- strip leading/trailing spaces, account for single character
err = err or not TAG and ' the tag has not been set\n\n in the script user settings'
or r.CSurf_NumTracks(true) + r.CountMediaItems(0) == 0 and 'no tracks or items in the project'
MOUSEWHEEL_REVERSE = validate_sett(MOUSEWHEEL_REVERSE)
local down, up = table.unpack(scr_name:match('mousewheel') and {Process_Mouse_Wheel_Direction(val, MOUSEWHEEL_REVERSE)}
or {})
err = err or scr_name:match('mousewheel') and not (down or up) and '   the script must be \n\n run with a mousewheel'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo)
	end

	if r.CSurf_NumTracks(true) + r.CountMediaItems(0) == 0 then
	Error_Tooltip('\n\n no visible tracks \n\n or not items in the project \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
	return r.defer(no_undo)
	end


REABANK_FILE = validate_sett(REABANK_FILE) and REABANK_FILE
UNDO = validate_sett(UNDO)

local reabank_t = REABANK_FILE and not scr_name:match('slider') and Parse_ReaBank_File(REABANK_FILE) -- only if script is meant to control 'Bank/Program Select' section
	if reabank_t == true then return r.defer(no_undo) end -- file wasn't found, error message is inside the function

local track, fx_idx, fx_GUID, item, take_idx = Re_Store_Data(named_ID) -- recall ReaControlMIDI instance props

local ret, fx_name, obj, found

local mrker_data = scr_name:lower():match('program') and Get_Set_Program_From_Action_Marker(cmd_ID, reabank_t) -- returns table, only in program select scripts

local undo = UNDO and not mrker_data and r.Undo_BeginBlock() -- placed here in case FX movements are performed inside Validate_FX_Identity() because these create undo points automatically // won't run if action marker is active because this will lead to creation of 2 undo pounts, one by this script and another one by the slave plugin, FX_SetParam() function creates an undo point on its own with the syntax 'Edit FX parameter: Track No: ReaControlMIDI' so one will still be created regardless of the UNDO setting and will include data for both ReaControlMIDI and the slave plugin

-- SEARCH FOR A TAGGED INSTANCE OF ReaControlMIDI

	if track then -- stored ReaControlMIDI instance data exist
		for i=-1, r.CountTracks(0)-1 do -- -1 to account for the Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
			if tostring(tr) == track -- target track found
			and r.IsTrackVisible(tr, false) -- mixer false
			then
				if item ~= 'userdata: ' then -- take fx // or #item > #('userdata: ') // item var contains actual pointer rather than a placeholder only as in the case of no item
					for i=0, r.GetTrackNumMediaItems(tr)-1 do
					local itm = r.GetTrackMediaItem(tr,i)
						if tostring(itm) == item then -- target item found
						local take = r.GetTake(itm, take_idx)
							if r.TakeFX_GetFXGUID(take, fx_idx) == fx_GUID then -- target FX found
							local ret, fx_name = r.TakeFX_GetFXName(take, fx_idx)
							obj = fx_name:match(Esc(TAG)) and take
							break end
						end
					end
				elseif r.TrackFX_GetFXGUID(tr, fx_idx) == fx_GUID:match('.+[%w%p]') then
				local ret, fx_name = r.TrackFX_GetFXName(tr, fx_idx)
				obj = fx_name:match(Esc(TAG)) and tr
				end
			end
			if obj then break end
		end
	end

-- The following routines run at the very 1st execution of the script in a session or when the stored data have become invalid

	if not obj then -- look among track FX
		for i=-1, r.CountTracks(0)-1 do -- -1 to account for the Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
			if r.IsTrackVisible(tr, false) then -- mixer false
			fx_idx, fx_name = Process_FX_Incl_In_All_Containers(tr, recFX, parent_cntnr_idx, parents_fx_cnt, TAG)
				if not fx_idx then -- look in the input/Montoring FX chain
				fx_idx, fx_name = Process_FX_Incl_In_All_Containers(tr, true, parent_cntnr_idx, parents_fx_cnt, TAG) -- recFX true
				end
				if fx_idx then -- tagged FX found
				found = 1
					if Validate_FX_Identity(tr, fx_idx, 'ReaControlMIDI', {[0]='Bank MSB',[1]='Bank LSB',[2]='Program'}, TAG)
					then
					obj = tr
					break end
				end
			end
		end
	end

	if not obj then -- look among take FX
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local tr = r.GetMediaItemTrack(item)
			if r.IsTrackVisible(tr, false) then -- mixer false
				for i=0, r.CountTakes(item)-1 do
				local take = r.GetTake(item,i)
				fx_idx, fx_name = Process_FX_Incl_In_All_Containers(take, recFX, parent_cntnr_idx, parents_fx_cnt, TAG)
					if fx_idx then -- tagged FX found
					found = 1
						if Validate_FX_Identity(take, fx_idx, 'ReaControlMIDI', {[0]='Bank MSB',[1]='Bank LSB',[2]='Program'}, TAG)
						then
						obj = take
						break end
					end
				end
			end
		end
	end

-- NAVIGATE IF FOUND

	if obj then
	local err, undo
		if mrker_data then -- switch program from action marker // only supported in program select scripts
		Get_Set_Program_From_Action_Marker(cmd_ID, reabank_t, mrker_data, obj, fx_idx)
		else
		err, undo = Switch_Bank_Program(obj, fx_idx, scr_name, down, up, reabank_t) -- down, up args stem from Process_Mouse_Wheel_Direction() function
		local undo = UNDO and r.Undo_EndBlock(err and (r.Undo_CanUndo2(0) or '') or undo, -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
			if found then -- 'found' var will only be valid when either there's no extended state yet i.e. very 1st execution of the script during session or when extended data has become invalid
			Re_Store_Data(named_ID, obj, fx_idx) -- store ReaControlMIDI instance props for the sake of efficiency so as to not search for it anew at every script run
			end
		end
	else
	local err = not found and ' tagged ReaControlMIDI plugin \n\n wasn\'t found in visible objects'
	or not obj and '   the tagged plugin\n\n is not ReaControlMIDI'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -200, 20) -- caps, spaced true, x2 -200, y2 20 // display the value placing the tooltip away from mouse cursor in case the script is run with a click otherwise tooltip blocks next mouse event
		end
	end

do return r.defer(no_undo) end









