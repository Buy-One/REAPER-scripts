--[[
ReaScript name: BuyOne_Script updater and installer.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.3
Changelog: 1.3 	#Added support for Media Explorer script installation
		#Optimized installation function
		#Updated 'About' text
	   1.2 	#Made user setting transfer report message a bit more descriptive
	   1.1  #Reworded installation report message
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About:	THIS SCRIPT MUST BE INSTALLED FIRST
	
	***  H O W   T O   U S E  ***
	
	1. INSTALLATION
	
	When you install BuyOne's scripts for the first time,
	after downloading the entire collection from the repo 
	at https://github.com/Buy-One/REAPER-scripts simply
	extract the folder 'REAPER-scripts-main', preferably
	name it after the scripter so it's clear whose scripts
	it contains and drop the folder into the /Scripts folder
	in REAPER's resource directory or external main scripts
	folder in case you don't keep your scripts in REAPER's
	resource directory.  
	
	Import into the Main section of the Action list this 
	very script only.  
	
	Run this script and in the dialogue supply the path
	to BuyOne's scripts folder, the one you just dropped
	into your main scripts folder as described above.
	
	Click OK.
	
	In the dialogue which will pop up click YES to run
	installation in the native mode, that's a mode designed
	for installation of BuyOne's scripts.
	
	During the operation REAPER may freeze, so just be patient.
	
	When the installation is complete another pop up will appear.
	Click OK and you're done.
	
	During the installation all script instances included in 
	META scripts will be installed as well so separate execution
	of META scripts after the installation isn't necessary.
	
	2. SETTINGS TRANSFER		
	
	If you have BuyOne's scripts already installed but wish to
	update them with their latest versions and add new scripts, 
	do not drop the downloaded folder with the scripts as you'd 
	do when installing them for the first time. Many scripts 
	feature USER SETTINGS and if you simply overwrite the older 
	files the settings will revert to their defaults. By the way 
	this is the problem with ReaPack which is agnostic of user
	settings.
	
	Instead extract the newly downloaded scripts into a 
	temporary folder.
	
	Run this script which by that time will already be installed,
	and in the dialogue supply path to such temporary folder.
	In the pop up dialogue click YES to launch transfer of the
	custom user settings to newer versions of the scripts.
	
	During the operation REAPER may freeze, so just be patient.
	
	When the transfer is complete another pop up will appear.
	Click OK to exit.
	
	The settings will be transfered to individual instances of 
	META scripts as well.
	
	AS A SAFETY MEASURE, BEFORE PERFORMING THE NEXT STEP CREATE 
	A BACKUP COPY OF THE CURRENTLY INSTALLED VERSIONS OF THE 
	SCRIPTS YOU'RE GOING TO OVEWRITE.
	
	Now peform the actions described in paragraph 1. INSTALLATION
	above to overwrite the older versions of the scripts in BuyOne's
	scripts folder and install any new ones.
	
	Check a couple which you know well and if everything is fine, 
	you can delete the backup copy if one was created as suggested
	above.
	
			***  N U A N C E S  ***
	
	This script can also be used to install 3d party scripts BUT 
	NOT to transfer their user settings.
	
	In the native mode scripts are installed in the section of the
	Action list designated to them by BuyOne. In the non-native
	installation mode all scripts will be installed in both Main
	and MIDI Editor sections of the Action list regardless of their
	actual purpose just to be on the safe side.
	
	If in the native mode you only wish to transfer the settings 
	between or install scripts in specific folder, supply path to 
	such folder in the dialogue. Scripts in subfolders of this folder, 
	if any, will be processed as well.
	
	The specifics of native and non-native installation modes are
	also laid out in the pop uo dialogue so be sure to refer to them
	in case of a doubt.
	
	The successful installation stats include all scripts which were
	submitted for installation regardless their being already installed.
		
]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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

function space(len)
return (' '):rep(len)
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


function GetUserInputs(title, field_cnt, field_names, field_cont, comment_field, comment)
-- title string, field_cnt integer, field_names string comma delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars as #t, t
-- field_cont empty string unless they must be initially filled
-- to fill out only specific fields precede them with as many commas
-- as the number of fields which must stay empty
-- in which case it's a comma delimited list
-- comment_field is boolean, comment is string to be displayed in the comment field
	if field_cnt == 0 then return end

	local function add_commas(field_cnt, field_prop)
	-- add delimiting commas when they're fewer than field_cnt
	-- due to lacking field names or field content
	local _, comma_cnt = field_prop:gsub(',','')
	return comma_cnt == field_cnt-1 and field_prop
	or comma_cnt < field_cnt-1 and field_prop..(','):rep(field_cnt-1-comma_cnt)
	end

local field_names = type(field_names) == 'table' and table.concat(field_names,',') or field_names
field_names = add_commas(field_cnt, field_names)
local field_cont = add_commas(field_cnt, field_cont)
local comment = comment_field and #comment > 0 and comment or ''
local field_cnt = #comment > 0 and field_cnt+1 or field_cnt
field_names = #comment > 0 and field_names..',Comment:' or field_names
field_cont = #comment > 0 and field_cont..','..comment or field_cont
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=150', field_cont)
output = #comment > 0 and output:match('(.+,)') or output -- exclude comment field keeping delimiter (comma) to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement
	if not ret or (field_cnt > 1 and #output:gsub(' ','') == (','):rep(field_cnt-1)
	or #output:gsub(' ','') == 0) then return end
local t = {}
	for s in output:gmatch('(.-),') do
		if s then t[#t+1] = s end
	end
return t, output:match('(.+),') or output -- remove hanging comma if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the comma will be added with it
end


function Dir_Exists(path) -- short
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string represening a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


function Collect_Files(path, MIDI_FIT_FOLDERS, t, midi, native_install_mode)
-- path is user supplied via GetUserInputs()
-- MIDI_FIT_FOLDERS comes from the DEVELOPER SETTINGS
-- native_install_mode boolean arg comes from user choice, meaning scripts by BuyOne
-- t and midi will be initialized within the function
-- thanks to MPL and Lokasenna // https://forum.cockos.com/showthread.php?t=206933
-- the function collects all scripts found at the path, both already installed and not yet installed

	local function is_specific_section_script(scr_path, section) -- section in the format of 'Provides:' header tag
	local start
		for line in io.lines(scr_path) do
			if line:match('ReaScript name:') then start = 1 -- header start
			elseif start and line:match('Provides:') then -- looking for line 'Provides: [main=main,midi_editor]'			
				if line:match(section) then return true end
			elseif line:match('About:') or line:match(']]') then break -- header end
			end
		end
	end

local sep = path:match('[\\/]')
path = path:match('(.-)[\\/]?$') -- remove last separator since in the following function it's not needed

-- folders scripts in which are fit for the MIDI Editor section of the action list
local midi = path:match('.+[\\/](.+)') -- folder name

-- scripts from the /MIDI folder are installed exclusively in the MIDI Editor section of the action list
	for _, fldr in ipairs(MIDI_FIT_FOLDERS) do
		if midi and midi:lower():match(fldr) then
		midi = 1 break
		end
	end

midi = midi == 1 -- folder fit for MIDI Editor section

r.EnumerateFiles(r.GetResourcePath(), 0) -- reset cache, works in all versions
local i, t = 0, t or {midi = {}, mx = {}, total={} }

-- first spawn scripts from any META scripts found in the folder in order to get accurate final stats
-- these will be installed directly by this script using Install_Scripts() function
-- rather than by running the META script with Main_OnCommand()
	repeat
	local file_n = r.EnumerateFiles(path, i)
		if file_n then
		local ext = file_n:sub(#file_n-3,#file_n)
			if ext == '.lua' or ext == '.eel' or ext:match('%.py$') then
				if file_n:match('_META%.[aelruy]+') then
				dofile(path..sep..file_n) -- for META scripts with USER SETTINGS will only be spawned if not already exist as designed by the META_Spawn_Scripts() function used in such META scripts to prevent accidental overwriting of custom USER SETTINGS in individual scripts with the default settings of the META script
				end
			end
		end
	i=i+1
	until not file_n

-- second collect files in the root directory, the one supplied by the user
r.EnumerateFiles(r.GetResourcePath(), 0) -- reset cache, works in all versions
i = 0
	repeat
	local file_n = r.EnumerateFiles(path, i)
		if file_n then
		local ext = file_n:sub(#file_n-3,#file_n)
			if ext == '.lua' or ext == '.eel' or ext:match('%.py$') then
			local f_path = path..sep..file_n
				if native_install_mode and -- only collect scripts fit for the MIDI Editor if native_install_mode is true
				(midi -- folder fit for the MIDI Editor as per loop above
				or file_n:lower():match('midi') -- file name ...
				or is_specific_section_script(f_path, 'midi_editor') ) -- or header indicating fitness of the script for the MIDI Editor
				or not native_install_mode -- scripts by other devs, which will all be installed in both Main and MIDI Editor sections
				then -- a script fit for the MIDI Editor section
				t.midi[#t.midi+1] = f_path
				end
				if native_install_mode and (file_n:lower():match('Media Explorer') 
				or is_specific_section_script(f_path, 'media_explorer') ) then
				t.mx[#t.mx+1] = f_path
				end				
				if (not native_install_mode -- if not native_install_mode collect all scripts regardless of their designation
				or native_install_mode and not path:lower():match('.+[\\/]midi')) then -- not MIDI folder // UP FOR CUSTOMIZATION BY OTHER SCRIPTERS
				t[#t+1] = f_path
				end
			t.total[#t.total+1] = '' -- dummy entry only for the sake of keeping script count for final stats
			elseif ext == '.zip' then
			-- if 'Set default mouse modifier...' actions in Lua format (relevant for REAPER 7).zip archive
			t.zip = path..sep..file_n
			end
		end
	i=i+1
	until not file_n

-- collect subdirectories and files recursively
r.EnumerateSubdirectories(r.GetResourcePath(), 0) -- reset cache, works in all versions
local i = 0
	repeat
	local subdir = r.EnumerateSubdirectories(path, i)
		if subdir then
		Collect_Files(path..sep..subdir, MIDI_FIT_FOLDERS, t, midi, native_install_mode)
		end
	i=i+1
	until not subdir

return t

end


function Collect_Scripts_With_Settings(path, t)
-- collect scripts in a temporary folder outside of the main scripts installation folder
-- for the sake of transferring USER SETTINGS to the newer instances
-- path is user supplied via GetUserInputs()
-- t will be initialized within the function
-- thanks to MPL and Lokasenna // https://forum.cockos.com/showthread.php?t=206933

	local function is_script_with_settings(scr_path)
	-- iterating by lines is inefficient because if no USER SETTING section is found the script will be iterated over till the end
	local f = io.open(scr_path,'r')
		if f then
		local cont = f:read('*a')
		f:close()
		return cont:match('%- END OF USER SETTINGS %-')
		end
	end

local sep = path:match('[\\/]')
path = path:match('(.-)[\\/]?$')

r.EnumerateFiles(r.GetResourcePath(), 0) -- reset cache, works in all versions
local i, t = 0, t or {}

-- first collect files in the root directory
	repeat
	local file_n = r.EnumerateFiles(path, i)
		if file_n then
		local ext = file_n:sub(#file_n-3,#file_n)
		local f_path = path..sep..file_n
			if not t[file_n] -- efficiency device in the 2nd run of the function after spawning META scripts to prevent re-adding scripts already stored // SEEMS SUPERFLUOUS, leaving just in case
			and (ext == '.lua' or ext == '.eel' or ext:match('%.py$'))
			and is_script_with_settings(f_path) then
			t[file_n] = f_path
			end
		end
	i=i+1
	until not file_n

-- collect subdirectories and files recursively
r.EnumerateSubdirectories(r.GetResourcePath(), 0) -- reset cache, works in all versions
local i = 0
	repeat
	local subdir = r.EnumerateSubdirectories(path, i)
		if subdir then
		Collect_Scripts_With_Settings(path..sep..subdir, t)
		end
	i=i+1
	until not subdir

return t

end


function Spawn_META_Scripts(t) -- for the sake of USER SETTINGS transfer
-- t is table returned by Collect_Scripts_With_Settings(), it holds current paths of newly downloaded scripts
	for scr_name, scr_path in pairs(t) do -- associative array hence pairs
		if scr_name:match('_META%.[aelruy]+') then -- UP FOR CUSTOMIZATION BY OTHER SCRIPTERS
		dofile(scr_path)
		end
	end
end


function Transfer_User_Settings(SCRIPTER_NAME, t)
-- t is table returned by Collect_Scripts_With_Settings(), it holds current paths of newly downloaded scripts

	local function get_script_name(line, SCRIPTER_NAME)
		for _, ext in ipairs{'lua','eel','py'} do
		local scr_name = line:match(SCRIPTER_NAME..'_.-%.'..ext)
			if scr_name then return scr_name end
		end
	end

	local function get_set_script_cont(scr_path, new_cont)
	local mode = new_cont and 'w' or 'r' -- write or read
	local f = io.open(scr_path, mode)
	local cont = not new_cont and f:read('*a')
		if new_cont then f:write(new_cont) end
	f:close()
	return not new_cont and cont
	end

	local function transfer(old_user_sett, new_user_sett) -- UP FOR CUSTOMIZATION BY OTHER SCRIPTERS
	-- the function ensures that any new user settings absent in the old version of the script
	-- are kept intact and only the old settings are transfered, which wouldn't happen with mere string.gsub()
	local t = {}
		for line in new_user_sett:gmatch('[^\n\r]*') do -- * is meant to preserve empty lines between setting variables
			if not line:match('^%-%-') then -- setting variable, which isn't preceded with double dash unlike comments are
			local sett_var = line:match('(.-)%s*=') -- extract setting name
			line = sett_var and #sett_var > 0 and old_user_sett:match('\n%s*('..sett_var..'.-)\n') or line
			end
		t[#t+1] = line
		end
	return table.concat(t,'\n')
	end

local sep = r.GetResourcePath():match('[\\/]')
local ini_path = r.GetResourcePath()..sep..'reaper-kb.ini'
local f = io.open(ini_path,'r')
	if f then
	local cont = f:read('*a')
	f:close()
		if cont:match(SCRIPTER_NAME..'_') then -- at least one developer's script is installed
		local upd_cnt = 0
			for line in cont:gmatch('[^\n\r]+') do -- search for the installed scripts with settings in reaper-kb.ini
			local scr_name = get_script_name(line, SCRIPTER_NAME)
				if scr_name and t[scr_name] then -- script with settings whose name was stored to a table in Collect_Scripts_With_Settings()
				-- Update user settings in the newly downloaded instance of a script with those of the installed instance
				local scr_path = line:match('.-%.lua" "?(.+%.lua)') -- the path is only enclosed within quotes if it contains spaces
				scr_path = scr_path:match('^%u:'..sep) and scr_path or r.GetResourcePath()..sep..'Scripts'..sep..scr_path -- reaper-kb.ini lists path relative to the \Scripts folder unless the script is loaded from external location
				scr_path = scr_path:gsub('/', sep) -- because in reaper-kb.ini forward slash separator is used, so the concatenated path becomes a mix of the forward and backward slashes on systems using backward slash as separator and the path comparison below will always fail
					if r.file_exists(scr_path) and scr_path ~= t[scr_name] then -- peventing operation on a file which resides at the same location as the installed one, i.e. on itself
					local old_inst_cont = get_set_script_cont(scr_path)
					local new_inst_cont = get_set_script_cont(t[scr_name])
					local patt = '%-%- USER SETTINGS.+END OF USER SETTINGS' -- UP FOR CUSTOMIZATION BY OTHER SCRIPTERS
					local old_user_sett = old_inst_cont:match(patt)
					local new_user_sett = new_inst_cont:match(patt)
						if old_user_sett ~= new_user_sett then
						local updated_user_sett = transfer(old_user_sett, new_user_sett)
						updated_user_sett = updated_user_sett:gsub('%%','%%%%') -- only % must be escaped in the replacement string
						new_user_sett = Esc(new_user_sett)
						new_inst_cont = new_inst_cont:gsub(new_user_sett, updated_user_sett)
						get_set_script_cont(t[scr_name], new_inst_cont) -- updating content of a new script instance in a temp folder
						upd_cnt = upd_cnt+1
						end
					end
				t[scr_name] = nil -- to prevent repeating the routine with scripts which are listed more the once in reaper-kb.ini due to being installed in different Action list sections
				end
			end -- loop end
		return upd_cnt -- to condition report message
		end
	end
return 0 -- update count
end


function Install_Scripts(t)
-- t is table returned by Collect_Files()

	local function install(t, sectionID) -- sectionID is integer
		for i = #t,1,-1 do -- in reverse because fields of scripts installed successfully will be deleted to only keep failed for final stats
		local scr = t[i]
			if type(scr) == 'string' then -- ignoring midi and total fields which are tables
			local cmdID = r.AddRemoveReaScript(true, sectionID, scr, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				if cmdID > 0 then -- successfully installed, only keep failed for final stats
				table.remove(t, i)
				end
			end
		end		
	end
	
	for k, tab in ipairs({ {t, 0}, {t.midi, 32060}, {t.mx, 32063} }) do
	install(tab[1], tab[2])
	end
	
return t

end

function INSTALL(path, MIDI_FIT_FOLDERS, native_install_mode)
-- path is user supplied via GetUserInputs()
-- native_install_mode boolean arg comes from user choice, meaning scripts by BuyOne

local t = Collect_Files(path, MIDI_FIT_FOLDERS, t, midi, native_install_mode) -- t, midi nil

local orig_cnt = #t + #t.midi + #t.mx -- store because the entries will be deleted inside Install_Scripts()

	if orig_cnt == 0 then
	r.MB('No scripts were found at the provided path.','REPORT',0)
	return end

t = Install_Scripts(t, native_install_mode)

local failed_cnt = #t + #t.midi + #t.mx
local zip = t.zip and '\tThere\'s a .zip archive in the /Misc folder'
..'\n\n      scripts in which cannot be installed with the installer.'
..'\n\n     If you find them useful, you can install them manually.' or ''
local br = t.zip and '\n\n\n' or ''
local failure = failed_cnt > 0
and (t.zip and space(15) or space(16))..failed_cnt..' installations have failed out of '..orig_cnt..',\n\n'
..(t.zip and space(18) or space(9))..'see the list in the ReaScript console.'..(br or '') or ''
local success = #failure == 0 and (t.zip and space(4) or space(6))..#t.total -- the successful installation count includes scripts both installed previously and newly installed, all which were collected at the user supplied path

	if failed_cnt > 0 then -- list all scripts which failed to get installed
	Msg('MAIN:\n\n'..table.concat(t,'\n')..'\n\nMIDI EDITOR:\n\n'..table.concat(t.midi,'\n'), r.ClearConsole())
	end
	r.MB(success..failure..zip, 'REPORT', 0)

end


function TRANSFER_USER_SETTINGS(path, SCRIPTER_NAME)
-- path is user supplied via GetUserInputs()

local t = Collect_Scripts_With_Settings(path)

	if not next(t) then
	r.MB(' No scripts with USER SETTINGS\n\nwere found at the provided path.','REPORT',0)
	return end

Spawn_META_Scripts(t)

t = Collect_Scripts_With_Settings(path, t) -- add spawned scripts to the table

local upd_cnt = Transfer_User_Settings(SCRIPTER_NAME, t)
local s = ' '
local explan = upd_cnt == 0 and '\n\n'..s:rep(7)..'either because no differences were detected\n'
..s:rep(9)..'or because no installed instances of scripts\n\t'
..s:rep(7)..'with settings were found.\n\n\n' or '.\n\n\n'

r.MB('  USER SETTINGS of '..upd_cnt..' scripts have been transeferred'..explan
..'    Now move the scripts into your main scripts folder\n\n\t   overwriting their older versions\n\n'
..'   and run this script again to install any new scripts\n\n'
..'     which happen to have come with the download.', 'REPORT', 0)

end


function Third_Party_Mode_Prompt(FREEZE_WARNING)
local resp = r.MB('Click « Y E S » to install the scripts in the native mode,'
..'\ni.e. according to the purpose designated for them by BuyOne.\n\n'
..'Click « N O » to install the scripts in the 3d party mode,\n'
..'which is relevant for installation of scripts by scripters other than BuyOne.\n'
..'In this mode all scripts are installed in both Main and MIDI Editor sections\n'
..'of the Action list regardless of their indended use.\n\n'
..FREEZE_WARNING, 'PROMPT', 3)
return resp
end


------------------------------------------------------------------
----------------------- DEVELOPER SETTINGS -----------------------
------------------------------------------------------------------

-- Used in Transfer_User_Settings() function to find scripter's
-- scripts in the reaper-kb.ini file and transfer their settings
-- to their newer instances inside TRANSFER_USER_SETTINGS()
SCRIPTER_NAME = "BuyOne"

-- Used in Collect_Files() to prime scripts from the listed folders
-- for installation into the MIDI Editor section of the Action list
-- with INSTALL()
MIDI_FIT_FOLDERS = {'midi', 'fx', 'markers & regions', 'takes'}


-------------------------------------------------------------------
-------------------- END OF DEVELOPER SETTINGS --------------------
-------------------------------------------------------------------


::RETRY::

ret, output = r.GetUserInputs('PATH TO THE TOP LEVEL FOLDER WITH SCRIPTS',1,'PATH:,extrawidth=200', output or '')
	if not ret or #output:gsub(' ','') == 0 then return r.defer(no_undo) end

path = Dir_Exists(output)

	if not path then
	Error_Tooltip('\n\n the path wasn\'t found \n\n', 1, 1) -- caps, spaced true
	goto RETRY
	end

local sep = path:match('[\\/]')

local FREEZE_WARNING = '     !!! DURING THE OPERATION REAPER MAY TEMPORARILY FREEZE.\n\t\t\tDON\'T PANIC !!!'

	if path:match(r.GetResourcePath()..sep..'Scripts') then -- the user supplied folder path is in the Scripts folder

	local mode = Third_Party_Mode_Prompt(FREEZE_WARNING)

		if mode ~= 2 then -- either Yes or No was clicked
		INSTALL(path, MIDI_FIT_FOLDERS, mode == 6) -- mode == 6 native installation mode is true
		end

	else -- the user supplied folder path is outside of the Scripts folder

	local resp = r.MB('The supplied path is outside of REAPER native /Scripts folder.'
	..'\n\nThis may be\n\n'
	..'A. A temporary path before you overwrite the older versions of the files\n'
	..'     in REAPER /Scripts folder\n\n      O R\n\nB. Your original main scripts folder\n\n'
	..('_ _ '):rep(20)..'\n\n'
	..'If any of the scripts are by BuyOne, in case A. click « Y E S » to transfer USER SETTINGS from the older files.\n'
	..'Once transfered move the newer files manually to your main scripts folder ovewriting their older versions, '
	..'and then run this script again supplying the folder path in your main scripts folder '
	..'to install any new scripts which happen to have come with the download.\n\n'
	..'In case B. click « N O » to install the scripts from the provided location.\n\n'..FREEZE_WARNING, 'PROMPT', 3)
		if resp == 6 then -- YES

		TRANSFER_USER_SETTINGS(path, SCRIPTER_NAME)

		elseif resp == 7 then -- NO

		local mode = Third_Party_Mode_Prompt(FREEZE_WARNING)

			if mode ~= 2 then -- either Yes or No was clicked
			INSTALL(path, MIDI_FIT_FOLDERS, mode == 6) -- mode == 6 native installation mode is true
			end

		end

	end


do return r.defer(no_undo) end




