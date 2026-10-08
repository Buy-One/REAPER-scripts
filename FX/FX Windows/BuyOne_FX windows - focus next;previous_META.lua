--[[
ReaScript name: BuyOne_FX windows - focus next;previous_META.lua (25 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962, v7.74 is recommended unless SWS/S&M extension is installed 
Extensions: SWS/S&M as the first priority, or js_ReaScriptAPI, recommended
Metapackage: true
Provides: 	[main=main,midi_editor] .
  				. > BuyOne_FX windows - focus next track or take window.lua
  				. > BuyOne_FX windows - focus previous track or take window.lua
  				. > BuyOne_FX windows - focus next track or take window on selected tracks.lua
  				. > BuyOne_FX windows - focus previous track or take window on selected tracks.lua				
  				. > BuyOne_FX windows - focus next track window.lua
  				. > BuyOne_FX windows - focus previous track window.lua
  				. > BuyOne_FX windows - focus next track window on selected tracks.lua
  				. > BuyOne_FX windows - focus previous track window on selected tracks.lua
  				. > BuyOne_FX windows - focus next take window.lua
  				. > BuyOne_FX windows - focus previous take window.lua
  				. > BuyOne_FX windows - focus next take window on selected tracks.lua
  				. > BuyOne_FX windows - focus previous take window on selected tracks.lua
  				. > BuyOne_FX windows - focus next track or take window on selected tracks (effect).lua
  				. > BuyOne_FX windows - focus previous track or take window on selected tracks (effect).lua
  				. > BuyOne_FX windows - focus next track or take window (effect).lua
  				. > BuyOne_FX windows - focus previous track or take window (effect).lua
  				. > BuyOne_FX windows - focus next track window (effect).lua
  				. > BuyOne_FX windows - focus previous track window (effect).lua
  				. > BuyOne_FX windows - focus next track window on selected tracks (effect).lua
  				. > BuyOne_FX windows - focus previous track window on selected tracks (effect).lua
  				. > BuyOne_FX windows - focus next track window (instrument).lua
  				. > BuyOne_FX windows - focus previous track window (instrument).lua
  				. > BuyOne_FX windows - focus next track window on selected tracks (instrument).lua
  				. > BuyOne_FX windows - focus previous track window on selected tracks (instrument).lua				
  				. > BuyOne_FX windows - focus open window (menu).lua
About:	If this script file name is suffixed with META, 
  			when executed it will automatically spawn all 
  			individual scripts included in the package into 
  			the directory of the META script and will import 
  			them into the Action list from that directory.
  
  			If there's no META suffix in this script file 
  			name it will perfom the operation indicated in 
  			its name.
  
  			The script brings already open FX chain and 
  			floating FX windows into focus one by one in 
  			ascending or descending order depending in 
  			the script name.
  
  			The order is determined by the track/item/take
  			order within the project rather than by the arbitrary 
  			order effected manually by shuffling FX windows.
  
  			The ascending order of FX windows is as follows:
  			1. track main FX chain
  			2. track input FX chain (Monitoring FX for the Master track)
  			3. take FX chains
  			The actual FX source object types (track, take 
  			or both) depend on the script name.
  
  			To be able to run the script with a shortcut
  			the shortcut mode must be 'Global + text fields'.
  
  
  			LIMITATIONS
  
  			1. In builds older than 7.06 the script doesn't 
  			support FX inside containers   
  			2. It doesn't support floating windows of bridged 
  			x86 bit plugins on x64 bit systems, unless the 
  			option  
  			Run As -> Embed bridged UI  
  			in the plugin right click context menu in the 
  			FX Browser is enabled.
  
  			If the script contains '(instrument)' appendage
  			in its name, it will only recognize plugins other
  			than JSFX. Conversely if it containes '(effect)'
  			appendage it will recognize all JSFX plugins, 
  			effects as well as intstruments.
  			
  			In the menu script, container name is listed when 
  			FX UI is displayed within a container open in a 
  			floating window and the container name is aliased, 
  			i.e. not the generic 'Container', otherwise the
  			FX name is listed. The item of the currently focused 
  			FX as well as that of its parent track are checkmarked
  			in the menu provided the window of currently focused 
  			fx is valid, i.e. displays an FX UI. If there's no
  			checkmark in the menu, the currently focused window
  			is ignored by the script as irrelevant.
  
  			See also an ancillary script
  			BuyOne_Align all open FX windows with the focused FX window in the Z-order.lua
  			which will place ALL currently open FX windows
  			on top of each other at the coordinates of the 
  			currently focused window maintaining their 
  			current order so they take up less screen real 
  			estate and then can be focused (brought to the 
  			foreground) one by one with the individual 
  			scripts included in this package.
]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function no_undo()
-- do return end
end


function space(n) -- number of repeats, integer
return (' '):rep(n)
end


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- ONLY NEEDED IF SCRIPTS INSTALLATION PATH IS PROVIDED BY THE USER, which is disabled in this function and META script path is used automatically
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
	local sep = path:match('[\\/]')
		if not sep then
			-- if path is disk root where the separator isn't listed, use forward slash, which should work on Windows as well
			if path:match('^%u:$') then sep = '/'
			else return -- likely not a string representing a path
			end
		end
	path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed so the path is properly formatted for os.rename()
	local OS = r.GetAppVersion()
	local win = not OS:match('/') or OS:match('/x')
		if win then
		local _, mess = io.open(path)
		return #path:gsub('[%c%.]', '') > 0 and mess and mess:match('Permission denied') and path..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
		else
		-- on Windows this doesn't work for directories in REAPER but works with external Lua runtimes, in ZeroBrane for example
		local ok, mess, code = os.rename(path, path)
		return (ok or code == 13) and path..sep -- 13 is error code for 'exists but permission denied' on some systems
		end
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

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
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

		if not ret or #output:gsub('[%s%c]','') == 0 then return end -- must be aborted outside of the function

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

		------------------------------------------------------------------------------------
		-- spawn scripts
		-- NO USER SETTINGS
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag // commented out to keep META script original name in the header so user can find it later and re-generate individual scripts if needed
		new_script:write(content)
		new_script:close()
		end
		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found;
-- if elements are patterns or contain patterns Esc() function
-- in scr_name:lower():match(Esc(elm:lower())) should not be used

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(Esc(elm:lower())) then return elm end -- at least one match was found
		end
	end

	local function Rep(n) -- number of repeats, integer
	return (' '):rep(n)
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end




function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
-- caps and spaced are booleans, caps doesn't apply to non-ANSI characters
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
--[[ IF USING WITH gfx
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 arguments which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the gfx window
]]
local text = caps and text:upper() or text
local utf8 = '[\0-\127\194-\244][\128-\191]*'
local text = spaced and text:gsub(utf8,'%0 ') or text -- supporting UTF-8 char
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



function re_store_config_var(key, bit, val)
-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html#fxfloat_focus
-- requires either build 7.74 or sws extension
-- key is string represnting reaper.ini key;
-- bit is integer, the bit in the bitfield which matches the target preference
-- see https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
-- BUT NOT ALL VALUES ARE BITFIELDS,
-- and the function assumes that when the bit is set the preference is enabled
-- which is not always the case and for preferences which work in reverse
-- the expression 'cur_val+0&bit == bit' will have to be replaced with 'cur_val+0&bit ~= bit';
-- val is the original value assosiated with the key
-- which is returned at the storage stage and restored at the restoration stage;
-- arg val must be nil in the storage stage while bit arg may be nil at the restoration stage

	if not key or type(key) ~= 'string' then return end

local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.74 -- where set_config_var_string() isn't supported
	if old_build and not r.SNM_SetIntConfigVar then return end -- in older builds values can only be set with SWS extension API


local ret, cur_val = r.get_config_var_string(key)

	if not cur_val or #cur_val == 0 then return end

local upd_val

	if not val then -- get to store
	local bit_set = cur_val+0&bit == bit
		if not bit_set then
		upd_val = cur_val+0 | bit
		end
	end

--local key = 'fxfloat_focus', 65536
local set = old_build and {r.SNM_SetIntConfigVar, key, val}
or {r.set_config_var_string, key, val, not val and 0 or 1} -- persist arg in set_config_var_string() depends on the stage, at the storage stage it's 0 so he value is not written into reaper.ini, otherwise 1 for the restored value to be written, OR PROBABLY since at the storage stage it's not written it will be preserved anyway so at the restoration stage 0 can be ued as well

	if upd_val or val then -- store or restore
	set[3] = val or upd_val -- update with the calculated value if val arg is nil, i.e. storage stage
	set[1](table.unpack(set, 2)) -- unpack starting from index 2
	end
	if not val and upd_val then -- OR 'if upd_val' // only return at the storage stage provided the setting
	return cur_val+0
	end

end



function Plugin_Is_Instrument(obj, fx_idx, temp_tr, delete_temp_tr)
-- TrackFX_GetInstrument() IS UNSUITABLE BECAUSE IT DOESN'T QUERY FX AT SPECIFIC INDEX;
-- ALTERNATIVE IS GetNamedConfigParm(obj, fx_idx, 'is_instrument') SUPPORTED SINCE 7.40;
-- all JSFX which don't contain the words reverb or delay in their name,
-- are considered instrument because there's no way to reliably determine
-- whether they're FX or instrument otherwise;
-- if there're multiple plugins to evaluate
-- and there's likelihood of using a temporary track
-- for the sake of the evaluation (see below)
-- it's more efficient to create it once and then
-- re-use until all are done
-- so temp_tr arg is temporary track pointer
-- either created outside of this function
-- or inside it and returned by it for re-use;
-- delete_temp_tr is boolean to instruct the function
-- to delete it once all plugins have been evaluated,
-- unless it's supposed to be deleted outside of this function;
-- IF THE FUNCTION EXITS BEFORE temp_tr IS RE-USED, ITS POINTER
-- WON'T BE RETURNED FOR FURTHER REUSE, SO DEVISE A METHOD TO MAINTAIN
-- ITS VALID POINTER OUTSIDE OF THE FUNCTION, i.e.
-- local instr, temp = Plugin_Is_Instrument(tr, i, temp_tr)
-- temp_tr = temp_tr or temp;
-- MIND THAT IF THE ROUTINE REACHES THE STAGE
-- OF TEMPORARY TRACK, COPYING AND REMOVING FX
-- CREATES UNDO POINTS, THEREFORE THE FUNCTION MUST
-- BE CALLED WTTHING THE UNDO BLOCK TO PREVENT
-- CREATION OF SEPARATE UNDO POINTS

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local FXName, ConfigParm, Copy = table.unpack(tr and {r.TrackFX_GetFXName, r.TrackFX_GetNamedConfigParm, r.TrackFX_CopyToTrack}
or take and {r.TakeFX_GetFXName, r.TakeFX_GetNamedConfigParm, r.TakeFX_CopyToTrack})

	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.40 then
	local ret, instr = ConfigParm(obj, fx_idx, 'is_instrument') -- ret is useless here because it's always true
	return instr == '1'
	end

-- retrieve from the instance name in FX chain
-- unless renamed
local ret, name = FXName(obj, fx_idx)
local prefix = name:match('^([23ACDLPSTUVXi]+): ')
--local JSFX = name:match('^JS:') and (name:lower():match('delay') or name:lower():match('reverb')) or not name:match('^JS:')
local JSFX = name:match('^JS:')

	if prefix then return prefix:match('.+i')
	elseif JSFX then return
	end

-- retrieve from plugin name in the FX browser, supported since build 6.37
-- unless renamed there
local ret, name = ConfigParm(obj, fx_idx, 'original_name')
prefix = name:match('^([23ACDLPSTUVXi]+): ')
local JSFX = name:match('^JS:')

	if prefix then return prefix:match('.+i')
	elseif JSFX then return
	end

-- copy to a temporary track and retrieve from chunk
r.PreventUIRefresh(1)
local temp_tr = temp_tr
	if not temp_tr then
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
	temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
	r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange
	end
r.TrackFX_Delete(temp_tr, 0) -- delete previously evaluated plugin if any
Copy(obj, fx_idx, temp_tr, 0, false) -- isMove false // COPYING/MOVING FX SEEMS TO NOT RESULT IN AUTO-FLOATING THEIR WINDOWS EVEN IF ENABLED IN THE PREFERENCES
local ret, chunk = r.GetTrackStateChunk(temp_tr, '', false) -- isundo false
prefix = chunk:match('.-"([23ACDLPSTUVX]+i:) ') -- within a chunk fx type prefix with plugin name displayed in the FX browser are enclosed within quotes
Msg(prefix, 'prefix')
	if delete_temp_tr and temp_tr then r.DeleteTrack(temp_tr) end
r.PreventUIRefresh(-1)

return prefix and prefix:match('.+i'), temp_tr

end



function Get_FX_Type(obj, fx_idx) -- used in Get_FX_Shown_In_Container()
-- https://forum.cockos.com/showthread.php?t=277103
local plug_types_t = {[0] = 'DX', [1] = 'LV2', [2] = 'JSFX', [3] = 'VST',
[4] = '', [5] = 'AU', [6] = 'Video processor', [7] = 'CLAP', [8] = 'Container'}
local validate = r.ValidatePtr
local GetIOSize = obj and (validate(obj, 'MediaItem_Take*') and r.TakeFX_GetIOSize
or validate(obj, 'MediaTrack*') and r.TrackFX_GetIOSize)
	if GetIOSize then
--Msg(fx_idx, type(fx_idx))
	local plug_type, inputPins_cnt, outputPins_cnt = GetIOSize(obj, fx_idx)
	return plug_types_t[plug_type]
	end
end



-- used in Collect_Open_FX()
function Get_FX_Shown_In_Container(obj, cont_idx, respect_empty_cont)
-- find the fx currently shown in the open innermost container;
-- cont_idx is index of the outermost selected container;
-- respect_empty_cont is boolean to instruct the function to return
-- index of the innermost selected/shown container in case it's empty
-- because due to its being empty nil will be returned otherwise

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetIOSize, GetParm = table.unpack(take and {r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm}
or tr and {r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm})

	if GetIOSize(obj, cont_idx) ~= 8 then return cont_idx end -- not container

local i = 0
	repeat
	local ret, count = GetParm(obj, cont_idx, 'container_count')
		if count == '0' then return respect_empty_cont and cont_idx end -- empty container
	local ret, cont_chain_addr = GetParm(obj, cont_idx, 'container_item.0') -- container_item.0 to query value to be used as container chain address alongside chain_sel attribute and which must correspond to 0 used to address the main chain, much like 0x1000000 is used to address the input/monitoring chain // THE ABSOLUTELY CRUCIAL PART https://forum.cockos.com/showthread.php?t=310132
	local ret, sel_idx = GetParm(obj, cont_chain_addr, 'chain_sel') -- returns regular 0-based index
	ret, sel_idx = GetParm(obj, cont_idx, 'container_item.'..sel_idx) -- convert into container aware format
	sel_idx = #sel_idx > 0 and sel_idx+0 -- convert into integer
		if GetIOSize(obj, sel_idx) ~= 8 then -- fx, not container
		return sel_idx
		else -- get container chain address for the next cycle as loop advances along container hierarchy
		cont_idx = sel_idx -- update for the next cycle
		end
	i=i+1
	until not sel_idx

end



-- used in Collect_Open_FX(), in Construct_Menu() and in main routine
function Get_First_Floating_Container(obj, fx_idx)
-- fx_idx is index of the fx open in the innermost container
-- returned by Get_FX_Shown_In_Container()

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

	if fx_idx < 0x2000000 or not tr and not take then return end

local GetConfigParm, GetFloatingWnd = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFloatingWindow}
or {r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFloatingWindow})

local retval
	repeat
	retval, fx_idx = GetConfigParm(obj, fx_idx, 'parent_container')
		if retval and GetFloatingWnd(obj, fx_idx+0) then return fx_idx+0
		end
	until not retval -- or #fx_idx == 0

end



function Collect_Open_FX(scr_name)

	local function focus(obj, fx_idx, showFlag1, showFlag2, wnd)
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local Show = tr and r.TrackFX_Show or take and r.TakeFX_Show
		return function()
		-- if extensions are available use them so that windows switch is smoother
		-- mainly relevant to switching to floating container windows because these are bulky
		-- and toggling them closed-open with the native API is noticeable
		local SetForegroundWnd = wnd and (r.BR_Win32_SetForegroundWindow or r.JS_Window_SetForeground)
			if SetForegroundWnd then
			SetForegroundWnd(wnd)
			else
			Show(obj, fx_idx, showFlag1); Show(obj, fx_idx, showFlag2)
			end
		end
	end


	local function store(t, obj, temp_tr, scr_name, old_build, input_fx, container_idx) -- input_fx is boolean, container_idx is only used in recursive loop

	local fx_instr = scr_name:match('instrument')
	local fx_effect = scr_name:match('effect')
	local no_cat = not fx_instr and not fx_effect

	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local ChainVis, FloatingWnd, Count, GetGUID, GetParm, GetFXName = table.unpack(take and {r.TakeFX_GetChainVisible, r.TakeFX_GetFloatingWindow, r.TakeFX_GetCount, r.TakeFX_GetFXGUID, r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFXName}
	or tr and {input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow, input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_GetFXGUID, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFXName})

	local chain_vis_idx = ChainVis(obj) -- for input fx the designated function returns regular index
	local chain_vis_floating = FloatingWnd(obj, chain_vis_idx + (input_fx and 0x1000000 or 0)) -- THIS VALUE IS ADDED TO TABLES OF ALL STORED FX BECAUSE IT'S RELEVANT WHEN SWITCHING TO ANY FX WINDOW, HENCE PLACED OUTSIDE OF THE LOOP, reason see in the decription in the main routine starting with 'THE MAJOR PROBLEM IS'
	local ret, count = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_count')}
	or {true, Count(obj)})
	count = ret and count+0 or count -- convert into integer if count of fx inside container because GetParm() returns string

		for i=0, count-1 do
		local fx_chain_vis = not container_idx and chain_vis_idx == i -- OR ChainVis(obj) == i -- for input fx the designated function returns regular index // the condition is irrelevant for conainer fx because ChainVis() the designated function only returns main chain indices
		local ret, i = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_item.'..i)} or {true, i})
		i = i + (input_fx and not container_idx and 0x1000000 or 0) -- convert into input fx index format if not container fx or into integer if index of fx inside container because GetParm() returns string and it doesn't require addition of 0x1000000
		local floating = FloatingWnd(obj, i)
		local container = Get_FX_Type(obj, i) == 'Container'
		local cont_fx_idx = container and Get_FX_Shown_In_Container(obj, i) -- since container doesn't have a UI, get the fx whose UI is displayed inside the innermost open container if container is selected in the main fx chain, in theory there may not be any fx if all nested containers are empty, in which case the return value is nil
		local float_cont_idx = cont_fx_idx and Get_First_Floating_Container(obj, cont_fx_idx) -- get the deepest floating container, if any, because the fx whose index is returned by Get_FX_Shown_In_Container() will be displayed in it in which case current container will not have to be stored because there's no point focusing window without fx UI

		fx_chain_vis = fx_chain_vis and (cont_fx_idx and not float_cont_idx and not FloatingWnd(obj, cont_fx_idx) or not container and not floating) -- if container is selected in the main fx chain, only validate fx chain window if inside the innermost nested container there's an fx whose UI isn't displayed in a floating window or inside a floating window of a child container, likewise if a regular fx is selected in the chain, only validate the fx chain window if such fx is not displayed in a floating window, because only in these cases focusing fx chain window makes sense // this expression will be irrelevant for floating nested containers when this function is executed recursively because only main chain fx are respected by FX_GetChainVisible()
		floating = floating and (cont_fx_idx and float_cont_idx == i and not FloatingWnd(obj, cont_fx_idx) or not container) and floating -- if container in the main fx chain is open in a floating window only validate its floating window if inside the innermost nested container there's an fx whose UI isn't displated in a floating window and is displayed inside the current container floating window because only in this case focusing container floating window makes sense // re-assigning floating as the final value when true because it will be passed to focus() function as an argument and must be data rather than boolean

		local instr, temp
			if (floating or fx_chain_vis) and (fx_instr or fx_effect) then
			instr, temp = Plugin_Is_Instrument(obj, i, temp_tr)
			temp_tr = temp_tr or temp -- keep the valid pointer throughout the loop
			end

			if (floating or fx_chain_vis) and (fx_instr and instr or fx_effect and not instr or no_cat)
			and (container and not old_build or not container) then -- only store containers if build is newer than 7.06 where it's easy to retrieve their props of the outermost parent container if a focused fx is inside a container in order to get table index of the currently focused fx, because container chain itself cannot be focused, but it's the outermost parent container GUID which is stored in the table

				-- if fx is displayed inside container and container name is aliased,
				-- display container name instead of the plugin name in the menu script
				if scr_name:match('menu') and cont_fx_idx then
				local ret, name = GetFXName(obj, i)
					if name ~= 'Container' then cont_fx_idx = i end -- assign container index to cont_fx_idx var stored in the table
				end

			t[#t+1] = {obj=obj, fx_idx=i, cont_fx=cont_fx_idx, sel_floating=chain_vis_floating, focus=focus(obj, i, floating and 2 or 0, floating and 3 or 1, floating)} -- prefer fx floating window because if it's also selected in the open fx chain window its UI won't be visible so focusing the chain window won't make sense // also storing fx properties to be able to query whether it's open in a floating window // also storing the result of a query for a fx which is both selected in fx chain and is open in a floating window becaue it overrides all other windows and must be dealt with // cont_fx_idx is only stored for menu concatenation in order to retrieve the name of the plugin displayed within the container selected in the main fx chain

			t[GetGUID(obj, i)] = #t -- store table index associated with the stored fx in the table to be able to determine next/previous fx window ralative to the focused one in case this window is focused

			end

			if container and not old_build then -- go recursive
			store(t, obj, temp_tr, scr_name, old_build, input_fx, i)
			end

		end
	-- t and temp_tr don't have to be returned because the upvalues are identical to the argument variables
	end


	local function collect_take_fx(t, tr, scr_name, old_build, sel, temp_tr)
	local Count, Get = table.unpack(tr and {r.CountTrackMediaItems, r.GetTrackMediaItem} or {r.CountMediaItems, r.GetMediaItem})
		for itm_idx=0, Count(tr or 0)-1 do
		local item = Get(tr or 0, itm_idx)
		local sel_tr = r.IsTrackSelected(r.GetMediaItemTrack(item))
			if not sel or sel_tr then
				for take_idx=0, r.CountTakes(item)-1 do
				local take = r.GetTake(item, take_idx)
					if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
					store(t, take, temp_tr, scr_name, old_build, input_fx) -- input_fx is nil
					end
				end
			end
		end
	-- t and temp_tr don't have to be returned because the upvalues are identical to the argument variables
	end


local obj_both = scr_name:match('track or take') or scr_name:match('menu')
local tr_fx = scr_name:match('track ') and not obj_both -- space after track to disambiguate from 'on selected tracks' for scripts which only support takes, OR 'track%A'
local take_fx = scr_name:match('take') and not obj_both
local sel = scr_name:match('selected')
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
local t = {}
local temp_tr -- used by Plugin_Is_Instrument()

	if tr_fx or obj_both then
		for tr_idx=-1, r.CountTracks(0)-1 do -- start from -1 to accommodate master track
		local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
			if tr and (not sel or r.IsTrackSelected(tr)) then
			-- main fx chain windows
			store(t, tr, temp_tr, scr_name, old_build)
			-- input fx windows
			store(t, tr, temp_tr, scr_name, old_build, 1) -- input_fx true
				-- take fx windows
				if obj_both then
				collect_take_fx(t, tr, scr_name, old_build, temp_tr)
				end
			end
		end
	end

	if take_fx and not obj_both then
	collect_take_fx(t, nil, scr_name, old_build, sel)
	end

	if temp_tr then r.DeleteTrack(temp_tr) end

return t

end




function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20
local master_tr = r.GetMasterTrack(0)
local mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
local is_mon_fx_float
	if mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
		for i = 0, r.TrackFX_GetRecCount(master_tr) do
			if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
			mon_fx_idx = i; is_mon_fx_float = true break end
		end
	end
return mon_fx_idx, is_mon_fx_float -- expected >= 0, true
end



function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20
-- DUE TO REASCRIPT API BEHAVIOR DOESN'T RETURN TRUTH IMMEDIATELY AFTER IMPORT
-- OF A TRACK TEMPLATE OF AN FX CHAIN PRESET SAVED WITH OPEN FX WINDOWS;
-- IN THIS SCENARIO, IF UI OF THE FX SELECTED IN THE OPEN FX CHAIN
-- IS DISPLAYED IN A FLOATING WINDOW, CLICKING THE FX CHAIN WINDOW
-- DOESN'T MAKE THE FX LAST FOCUSED AND THE FUNCTION STILL RETURNS FALSE

	if not r.GetTouchedOrFocusedFX then -- older than 7.0

	local retval, tr_num, itm_num, fx_num = r.GetFocusedFX()
	-- Returns 1 if a track FX window has focus or was the last focused and still open, 2 if an item FX window has focus or was the last focused and still open, 0 if no FX window has focus. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber and fxnumber are zero-based. If item FX, fxnumber will have the high word be the take index, the low word the FX index.
	-- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx itm_num is -1, if retval is 0 the rest return values are 0 as well
	-- if src_take_num is 0 then track or no object ???????

	local mon_fx_num = GetMonFXProps() -- expected >= 0 or > -1

	local tr = retval > 0 and (r.GetTrack(0,tr_num-1) or r.GetMasterTrack()) or retval == 0 and mon_fx_num >= 0 and r.GetMasterTrack() -- prior to build 6.20 Master track has to be gotten even when retval is 0

	local item = retval == 2 and r.GetTrackMediaItem(tr, itm_num)
	-- high word is 16 bits on the left, low word is 16 bits on the right
	local take_num, take_fx_num = fx_num>>16, fx_num&0xFFFF -- high word is right shifted by 16 bits (out of 32), low word is masked by 0xFFFF = binary 1111111111111111 (16 bit mask); in base 10 system take fx numbers starting from take 2 are >= 65536
	local take = retval == 2 and r.GetMediaItemTake(item, take_num)
	local fx_num = retval == 2 and take_fx_num or retval == 1 and fx_num or mon_fx_num >= 0 and 0x1000000+mon_fx_num -- take or track fx index (incl. input/mon fx) // unlike in GetLastTouchedFX() input/Mon fx index is returned directly and need not be calculated // prior to build 6.20 Mon FX have to be gotten when retval is 0 as well // 0x1000000+mon_fx_num is equivalent to 16777216+mon_fx_num
	--	local mon_fx = retval == 0 and mon_fx_num >= 0
	--	local fx_num = mon_fx and mon_fx_num + 0x1000000 or fx_num -- mon fx index

	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well

		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm, GetEnabled, GetOffline = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, r.TakeFX_GetEnabled, r.TakeFX_GetOffline}
		or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetEnabled, r.TrackFX_GetOffline}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num)
		local fx_name = fx_alias
		-- in builds older than 6.31 fx_name return value will be indentical to fx_alias
			if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.31 then
			local ret
			ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
			fx_name = fx_name:match('^JS:') and fx_name:match('JS: (.+) %[') -- excluding path
			or fx_name:match('^[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
			end

		local bypassed = not GetEnabled(obj, fx_num)
		local offline = GetOffline(obj, fx_num)
		local input_fx = fx_num >= 0x1000000

		return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_alias, fx_name, fx_GUID, 	 bypassed, offline, input_fx -- tr_num = -1 means Master;
		end

	else -- supported since v7.0

	local retval, tr_num, itm_num, take_num, fx_num, parm_num = r.GetTouchedOrFocusedFX(1) -- 1 focused mode // parm_num only relevant for querying last touched (mode 0) or if the last focused window is still open, value 1 // supports Monitoring FX and FX inside containers, container itself can also be focused
	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = tr and r.GetTrackMediaItem(tr, itm_num)
	local take = item and r.GetTake(item, take_num)
	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well

		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm, GetEnabled, GetOffline = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, r.TakeFX_GetEnabled, r.TakeFX_GetOffline}
		or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetEnabled, r.TrackFX_GetOffline}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID, is_cont = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num), GetIOSize(obj, fx_num) == 8
		local ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
		fx_name = fx_name:match('^JS:') and fx_name:match('JS: (.+) %[') -- excluding path
		or fx_name:match('^[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor or Container

		local input_fx = fx_num >= 0x1000000 and fx_num <= 0x2000000 or fx_num-0x2000000 >= 0x1000000 -- or 16777216 instead of 0x1000000 and 33554432 instead of 0x2000000 // TrackFX_GetRecChainVisible() gives false positives because it's valid regardless of the window being focused
		local cont_fx = fx_num >= 33554432 -- or fx_num >= 0x2000000
		local mon_fx = retval and tr_num == -1 and input_fx
		local bypassed = not GetEnabled(obj, fx_num)
		local offline = GetOffline(obj, fx_num)

		return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, bypassed, offline, input_fx, cont_fx, is_cont -- tr_num = -1 means Master
		end
	end

end



function Get_FX_All_Parent_Containers(obj, fx_idx, want_hash)
-- supported since build 7.06
-- return table where container indices are listed in ascending order
-- i.e. from the outermost to the innermost

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

	if fx_idx > 0x2000000 and (tr or take) then -- range fx inside containers, or > 33554432
	local GetConfigParm = tr and r.TrackFX_GetNamedConfigParm or take and r.TakeFX_GetNamedConfigParm
	local t, retval = want_hash and {hash={}} or {}
		repeat
		retval, fx_idx = GetConfigParm(obj, fx_idx, 'parent_container')
			if retval then
			table.insert(t, 1, fx_idx+0)
				if want_hash then
				t.hash[fx_idx+0] = ''
				end
			end
		until not retval -- or #fx_idx == 0
	return t
	end

end



function Focus(obj, fx_idx, chain)
local validate = r.ValidatePtr
local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
local Show = take and r.TakeFX_Show or tr and r.TrackFX_Show
-- if switching to target fx within the chain because chain arg is true
-- as is the case when another fx selected in the chain is open in a floating window,
-- closing and reopening the chain is not required to make floating window
-- of the target fx focused, it becomes that automatically, provided another
-- fx floating window is focused currently, HOWEVER if it's the actual fx chain window
-- which is focused while another fx selected there and open in a floating window
-- is located not imediately behind the fx chain window in the Z-order
-- single execution of the function won't suffice, fx chain window will remain focused,
-- and even if followed by t[targ_idx].focus() in the main routine single execution
-- will result in the floating window currently selected in the chain becoming focused
-- despite the switch in the chain, and the target fx will only be brought above the fx chain window,
-- so since when extensions aren't installed it's impossible to determine the Z-order
-- it's safer to toggle the windows to cover all possible scenarios
Show(obj, fx_idx, chain and 0 or 2); Show(obj, fx_idx, chain and 1 or 3)
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



function get_align_script(scr_path)

local path = scr_path:match('.+[\\/]')
path = path..'BuyOne_Align all open FX windows with the focused FX window in the Z-order.lua'
local grayout = r.file_exists(path) and (r.BR_Win32_SetWindowPos or r.JS_Window_SetPosition) and '' or '#' -- the above script requires extensions
local menu_item = grayout..'Align open FX windows|'..grayout..'with the focused FX window|||'

return path, menu_item

end



function Construct_Menu(t, focused_obj, focused_idx) -- t is table returned by Collect_Open_FX()

	-- since with non-floating container fx what's likely to be stored in the table
	-- is their parent container, get fx index which is most likely to be associated
	-- with the focused fx and included in the table
	-- and thus relevant for the the menu concatenation
	-- in oder to checkmark the relevant menu item
local tr, take = r.ValidatePtr(focused_obj, 'MediaTrack*'), r.ValidatePtr(focused_obj, 'MediaItem_Take*')
GetFloatingWindow = take and r.TakeFX_GetFloatingWindow or r.TrackFX_GetFloatingWindow
	if focused_idx > 0x2000000 and not Get_FX_Type(focused_obj, focused_idx) ~= 'Container'
	and not GetFloatingWindow(focused_obj, focused_idx) then
	local idx = Get_First_Floating_Container(focused_obj, focused_idx)
	local parents_t = not idx and Get_FX_All_Parent_Containers(focused_obj, focused_idx) -- if no parent container is open in a floating window, get the outermost (top level) parent container because it's the one whose index will be stored in the table
	focused_idx = parents_t and parents_t[1] or idx or focused_idx
	end

local validate = r.ValidatePtr
local menu, track, track_check = ''

	for k, v in ipairs(t) do
	local obj, fx_idx = v.obj, v.cont_fx or v.fx_idx -- if container is selected in the main fx chain window or a nested container open in a floating window with plugin UI displayed (v.cont_fx valid in both cases), the name of the plugin will be retrieved rather than the name of the container unless container generic name is aliased (v.cont_fx valid but contains container index)
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local GetFXName = tr and r.TrackFX_GetFXName or r.TakeFX_GetFXName
	tr = tr and obj or r.GetMediaItemTake_Track(obj)
	local master = tr == r.GetMasterTrack(0)
		if tr ~= track then -- current fx window is associated with another track, create new track submenu
			if #menu > 0 and track_check then -- fx window associated with previous track was focused, checkmarks previous track submenu item
			menu = menu:match('.*>')..'!'..menu:match('.*>(.+)') -- * operator to accommodate scenario where checkmark is added to the very first submenu item and where + operator would produce nil because the menu starts with >
			track_check = nil -- reset
			end
		local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
		local ret, name = r.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false) -- is_set false
		menu = #menu > 0 and menu:match('(.+|).-|')..'<'..menu:match('.+|(.-|)') or menu -- close previous track submenu
		menu = menu..'>'..(master and 'Master track' or 'Track '..tr_idx)
		..(name:match('%S') and ' "'..name..'"|' or '|')
		track = tr -- store for comparison in the subsequent cycles
		end
	local check = focused_idx == v.fx_idx and obj == focused_obj and '!' or ''	-- compare focused idx with v.fx_idx because this is stored index of the fx whose window can be brought into focus // checkmark may end up being empty if the index associated with the focused window isn't stored in the table because the window doesn't display fx UI
	track_check = track_check or #check > 0 -- store until the fx windows associated with another track come along during the loop in order to add a checkmark, if applies, to the previous track fx submenu item above
	local ret, fx_name = GetFXName(obj, fx_idx, '')
	local input_fx = fx_idx >= 0x1000000 and fx_idx <= 0x2000000 or fx_idx-0x2000000 >= 0x1000000
	input_fx = input_fx and (master and ' (monitoring FX)' or ' (input FX)') or ''
	local take_fx = take and ' (take FX)' or ''
	menu = menu..check..fx_name..input_fx..take_fx..(fx_idx > 0x2000000 and ' [cont]' or '')..'|'
	end

	if track_check then -- if wasn't reset then the checkmark must be added to the last submenu item
	menu = menu:match('.*>')..'!'..menu:match('.*>(.+)') -- * operator to accommodate scenario where checkmark is added to the very first submenu item and where + operator would produce nil because the menu starts with >
	end

return menu

end



Error_Tooltip('') -- clear any lingering tooltip

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // for META scripts without menu // due to .+[\\/] WILL ONLY WORK IF THE SCRIPT ISN'T LOCATED IN THE ROOT OF THE /Scripts folder, alternative pattern is ('[^\\/]+_(.+)%.%w+')

	-- doesn't run in non-META scripts
	-- !!! IF THE META SCRIPT IS ITSELF FUNCTIONAL (INCLUDES MENU) THE 'if ... then ... end' STATEMENT IS UNNECESSARY
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_FX windows - focus next;previous_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[ --------------- NAME TESTING
scr_name = {
'focus next track or take window',
'focus previous track or take window',
'focus next track or take window on selected tracks',
'focus previous track or take window on selected tracks',

'focus next track window',
'focus previous track window',
'focus next track window on selected tracks',
'focus previous track window on selected tracks',

'focus next take window',
'focus previous take window',
'focus next take window on selected tracks',
'focus previous take window on selected tracks',

'focus next track or take window (effect)',
'focus previous track or take window (effect)',
'focus next track or take window on selected tracks (effect)',
'focus previous track or take window on selected tracks (effect)',

'focus next track window (effect)',
'focus previous track window (effect)',
'focus next track window on selected tracks (effect)',
'focus previous track window on selected tracks (effect)',

'focus next track window (instrument)',
'focus previous track window (instrument)',
'focus next track window on selected tracks (instrument)',
'focus previous track window on selected tracks (instrument)',

'focus open window (menu)'

}
scr_name = scr_name[25]
--]]



	if not Invalid_Script_Name(scr_name, 'next', 'previous', 'menu')
	or not Invalid_Script_Name(scr_name, 'track', 'take', 'track or take', 'menu') then
	return r.defer(no_undo) end


local master = r.GetMasterTrack(0)
local err = r.GetNumTracks() == 0 and r.TrackFX_GetCount(master) + r.TrackFX_GetRecCount(master)== 0
and space(4)..'no tracks in the project \n\n and no fx on the master track'
or scr_name:match('selected') and not r.GetSelectedTrack2(0, 0, true) -- wantmaster true
and 'no selected tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

-- the native focus functions ignore FX selected in the FOCUSED FX chain
-- but whose UI is open in the NON-FOCUSED floating window
-- they return props of the last focused fx instead;
-- this also applies to floating container windows when the fx selected inside the container
-- is open in a non-focused floating window, as well as to floating windows of empty containers,
-- as a result window navigation gets stuck at such window
local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, bypassed, offline, is_input_fx, is_cont_fx, is_cont = GetFocusedFX()

local t = Collect_Open_FX(scr_name)

local sws = r.BR_Win32_GetForegroundWindow

-- GetFocusedFX() doesn't return truth immediately after import
-- of a track template of an fx chain preset saved with open fx windows;
-- if the template/preset was saved with open fx chain window
-- and a foreground floating window of an fx belonging to such chain,
-- after import it's the open fx chain window which will end up being in the foreground;
-- in this scenario, if UI of the fx selected in the open fx chain
-- is displayed in a floating window, clicking the fx chain window
-- doesn't make the fx last focused and the function still returns false;

	if not retval then
		if #t > 0 then
		r.MB(space(10)..'The currently open FX windows don\'t seem\n\n'
		..space(11)..'to have ever been focused in this session.\n\n'
		..space(4)..'To proceed click on any FX window displaying a UI.', 'ERROR', 0)
		else
		Error_Tooltip('\n\n no (last) focused fx window \n\n', 1, 1) -- caps, spaced true
		end
	return r.defer(no_undo)
	elseif #t == 0 then
	local s = scr_name
	local fx_cat = (s:match('instr') or s:match('effect')) and 'no windows of supported fx'
	local takes = s:match('take') and not s:match('track ') and s:match('selected')
	and 'no items on selected tracks'
	local err = fx_cat and takes and '  '..fx_cat..' \n\n or '..takes or fx_cat or takes
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.74 -- where set_config_var_string() isn't supported
local ret, create_fx_undo = r.get_config_var_string('fxfloat_focus')
create_fx_undo = create_fx_undo+0&65536 ~= 65536

-- In the script, navigating open fx windows by focusing them is based on toggling them closed-open,
-- therefore when fx chain window has to be focused this way, the toggle is apparent, especially
-- when such window is docked (which must not be supported but the native API doesn't allow
-- querying its docked state and using extensions it will be too convoluted),
-- when the tab of the docked fx chain window is not active in the multi-tab docker
-- the API will recognize such window as closed so the plugin selected in the chain
-- won't be included in the table returned by Collect_Open_FX();
-- considering this navigation mechanism, if the preference at
-- Preferences -> Plugins -> Do not create undo points when closing FX windows
-- is disabled, enable it with re_store_config_var() for the duration of script execution
-- to prevent creation of multiple undo points when fx windows are toggled closed and open
-- in order to get them focused without extensions (or with them when the target window is fx chain window
-- which cannot be accessed with extensions because its handle is irretrievable with the native API)
-- and if REAPER build the user runs doesn't support that function due to being old or due to lack of the SWS extension
-- and the preference is disabled, create a single custom undo point, the good thing about which
-- is that it won't multiply at repeated script executions
-- and will only be created if the last action in the undo hitory is different
-- so it will be created in-between other actions but won't inundate the undo history
-- when the script is executed several times in a row to navigate between windows
	if old_build and not sws and create_fx_undo then -- in older builds values can only be set with SWS extension API
	r.Undo_BeginBlock() -- so initialize undo block
	end

local fxfloat_focus = re_store_config_var('fxfloat_focus', 65536) -- store original pref value and disable creation of undo point when fx windows are toggled // will only run if build is 7.74 or sws extension is installed

local obj = take or tr -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive

-- fx containers cannot be focused, so if fx UI is displayed 
-- inside fx container floating window, fx data will be returned
-- by GetFocusedFX() and not container data;
-- if fx inside a container is the one currently focused,
-- evaluate how it's open, look for its innermost parent container
-- open in a floating window in order to determine fx index actually stored in the table
-- returned by Collect_Open_FX() and then current table index associated with
-- the found fx index via GUID stored in the table,
-- provided the REAPER build is 7.06+ where analyzing container fx is easy
local par_cont_idx
	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.06 then
	local GetConfigParm, GetGUID, GetFloatWnd = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFXGUID, r.TakeFX_GetFloatingWindow} or {r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFXGUID, r.TrackFX_GetFloatingWindow}) -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive
		if fx_num >= 0x2000000 and not GetFloatWnd(obj, fx_num) then -- focused container fx isn't open in a floating window, so its index hasn't been stored in the table returned by Collect_Open_FX()
		local float_cont_idx = Get_First_Floating_Container(obj, fx_num) -- find index of the focused fx first parent container open in a floating window, if any, because that's where the fx UI will be displayed and whose index will be stored in the table
		local parents_t = Get_FX_All_Parent_Containers(obj, fx_num) -- if no parent container is open in a floating window, get the outermost (top level) parent container because it's the one whose index will be stored in the table
		par_cont_idx = parents_t[1] -- outermost parent container index, for conditioning focus of the only open fx window
		fx_GUID = float_cont_idx and GetGUID(obj, float_cont_idx) -- get GUID of the first parent container open in a floating window, if any, to find table index associated with currently focused fx and be able to calculate next/previous fx; the return value will be nil due to float_cont_idx being nil only when table length is 1, in which case calculating next/previous fx won't be necessary as the routine won't reach that stage
		end
	end

	if #t == 1 then
	-- check if the same fx is both active in the open fx chain window and in a floating window
	-- in order to focus its floating window because in this scenario its UI won't be displayed in the fx chain
	local GetChainVis, GetFloatingWnd = table.unpack(take and {r.TakeFX_GetChainVisible, r.TakeFX_GetFloatingWindow}
	or {is_input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow})
	local chain_vis_idx, floating = GetChainVis(obj), GetFloatingWnd(obj, t[1].fx_idx)
	chain_vis_idx = chain_vis_idx + (is_input_fx and 0x1000000 or 0) -- convert into proper format because GetRecChainVisible() returns regular index

	local mess = function() return not sws and not r.JS_Window_GetTitle and Error_Tooltip('\n\n'..space(5)..'this is the only \n\n supported fx window \n\n', 1, 1) end -- caps, spaced true

	local topmost = sws and r.BR_Win32_GetForegroundWindow() or r.JS_Window_GetForeground and r.JS_Window_GetForeground()
	local title
		if topmost then
		local ret
		ret, title = table.unpack(sws and {r.BR_Win32_GetWindowText(topmost)} or r.JS_Window_GetTitle and {nil, r.JS_Window_GetTitle(topmost)} or {}) -- the js extension function only returns a single value so matching to 2 return values of the sws function
		end
		if chain_vis_idx == (par_cont_idx or t[1].fx_idx) and floating and topmost ~= floating then -- the only valid fx is both open in the fx chain and floating, switch to floating because the fx UI in this case isn't visible in the fx chain window // if extensions are unavailable the switch will be performed even if floating window is already focused/in the foreground because there's no way to determine the foreground window with the native API // if extensions are available and the floating window is already in the foregound, the condition will only be true if the floating window is not focused, i.e. not selected, WHICH WILL ALWAYS BE THE CASE WHEN THE SCRIPT IS NOT RUN WITH A SHORTCUT/MIDI/OSC BECAUSE THE CLICKED WINDOW WILL BE IN THE FOREGROUND
	--	Show(obj, fx_num, 2); Show(obj, fx_num, 3)
		Focus(obj, t[1].fx_idx)
		mess()
		elseif floating and topmost and topmost ~= floating -- extensions are installed, fx is open in a floating window
		or not floating and title and not title:match('FX: ') -- extensions are installed, fx is open in fx chain window
		or obj ~= t[1].obj then -- extensions aren't installed and invalid fx window (empty chain) of another object or another application window is focused (in the foreground) // if extensions are unavailable the switch will be performed even if fx window is already focused/in the foreground because there's no way to determine the foreground window with the native API // if extensions are available and the fx window is already in the foregound, the condition will only be true if the floating window is not focused, i.e. not selected, WHICH WILL ALWAYS BE THE CASE WHEN THE SCRIPT IS NOT RUN WITH A SHORTCUT/MIDI/OSC BECAUSE THE CLICKED WINDOW WILL BE IN THE FOREGROUND
		t[1].focus()
		mess()
		else
		Error_Tooltip('\n\n\tthe only supported \n\n fx window is already open \n\n', 1, 1) -- caps, spaced true
		end
		-- handle undo
		if old_build and not sws and create_fx_undo then -- in older builds values can only be set with SWS extension API
		r.Undo_EndBlock('Focus FX window',-1)
		end
	re_store_config_var('fxfloat_focus', 65536, fxfloat_focus) -- restore original pref value, arg 2 is irrelevant here // will only run if build is 7.74 or sws extension is installed
	return r.defer(no_undo) end

local targ_idx

	if scr_name:match('menu') then

	local align_script, align_menu_item = get_align_script(fullpath_init)

	local menu = Construct_Menu(t, take or tr, fx_num) -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive
	menu = align_menu_item..menu
	targ_idx = Reload_Menu_at_Same_Pos(menu)

		if targ_idx < 3 then
			if targ_idx > 0 then	dofile(align_script) end
		return r.defer(no_undo)
		end

	targ_idx = targ_idx-2 -- -2 to offset the align menu items to accurately target entries in the table t returned by Collect_Open_FX()

	else -- next/previous

	local cur_idx = t[fx_GUID] -- index of the focused fx within the table
	local nxt = scr_name:match('next')
	
	-- get index of the target fx within the table
	targ_idx = nxt and (cur_idx and cur_idx+1 or 1) or cur_idx and cur_idx-1 or #t -- handle target index being nil because focused fx window belongs to an object type the current script doesn't support
	targ_idx = targ_idx < 1 and #t or targ_idx > #t and 1 or targ_idx -- handle target index being out if the table range

	end


-- THE MAJOR PROBLEM IS OVERRIDING THE FX WHICH IS BOTH
-- SELECTED IN THE OPEN FX CHAIN AND OPEN IN A FLOATING WINDOW:
-- IF ITS FLOATING WINDOW IS CURRENTLY FOCUSED, THE FLOATING WINDOW
-- OF THE TARGET FX BELONGING TO THE SAME FX CHAIN
-- IS SUCCESSFULLY TOGGLED TO CLOSE AND RE-OPEN BUT THE FOCUS IS STUCK
-- ON THE CURRENTLY FOCUSED FLOATING FX WINDOW,
-- IF THE OPEN FX CHAIN WINDOW IS FOCUSED INSTEAD, TOGGLING TARGET FX FLOATING WINDOW
-- ONLY MAKES THE FLOATING WINDOW OF FX SELECTED IN THE OPEN FX CHAIN BECOME FOCUSED,
-- i.e. BRINGS IT TO THE FOREGROUND, AND FURTHER NAVIGATION IS STUCK FROM THIS POINT ONWARDS AS DESCRIBED ABOVE,
-- THE FLOATING FX WINDOW OF SUCH FX ALSO OVERRIDES ANY OTHER TARGET FLOATING WINDOW
-- IN THE SAME FX CHAIN EVEN IF SUCH FX ITSELF ISN'T FOCUSED INITIALLY;
-- TWO WAYS TO OVERCOME THIS:
-- 1. BY USING EXTENSION API DO DIRECTLY AFFECT ORDER POSITION OF THE TARGET FX WINDOW
-- 2. BY CHANGING THE FX SELECTED IN THE OPEN FX CHAIN WINDOW TO THE TARGET FX
-- SO THAT ITS FLOATING WINDOW CAN BE BROUGHT INTO FOCUS BY TOGGLING AS IS DONE BELOW

-- fx chain window will only be brought into focus if target fx UI is displayed there
-- if it's not and neither is it displayed in a floating window,
-- it's simply not included in the table returned by Collect_Open_FX()

local targ_fx_idx, targ_fx_obj = t[targ_idx].fx_idx, t[targ_idx].obj
local sel_floating = t[targ_idx].sel_floating -- the fx whose UI is displayed in a floating window is selected in the fx chain // THIS IS ONLY TRUE IF THE RELEVANT FX CHAIN WINDOW IS OPEN AS WELL as stored inside Collect_Open_FX() // THE VARIABLE IS ONLY USED AS BOOLEAN, not for setting the window as foreground with the extension functions because it's only valid for fx selected in the chain

	if sel_floating then -- window of fx chain to which belongs the fx whose UI is displayed in a floating window, is open
	-- DEAL WITH THE PROBLEM DESCRIBED ABOVE IN ALL CAPS
	local SetForegroundWnd = r.BR_Win32_SetForegroundWindow or r.JS_Window_SetForeground
		if SetForegroundWnd then -- extensions are available
		-- if the fx whose UI is displayed in the floating window
		-- is also selected in the open fx chain, the fx chain won't be brought above other windows
		-- which is what happens when the extensions aren't available, see next condition
		local GetFloatingWnd = r.ValidatePtr(targ_fx_obj,'MediaItem_Take*') and r.TakeFX_GetFloatingWindow
		or r.ValidatePtr(targ_fx_obj,'MediTrack*') and r.TrackFX_GetFloatingWindow
		SetForegroundWnd(GetFloatingWnd(targ_fx_obj, targ_fx_idx)) -- floating window handle must be retrieved for each window individually, sel_floating is unsuitable because it only refers to fx selected in the chain
		else -- extensions aren't available
		Focus(targ_fx_obj, targ_fx_idx, 1) -- chain arg 1 true // activate the target fx in the fx chain, by closing the chain window and re-opening with the target fx selected there, this ensures the ability to focus the target fx floating window next // FX_SetOpen() isn't suitable, because if fx is alerady open in a floating window won't be activate in the fx chain
		-- since now the fx chain is focused, focus the target fx floating window, i.e. bring it to the foreground
		-- as a result, the fx chain window will also be brought above other windows
		-- which initially where above it
		t[targ_idx].focus()
		end
	else -- window of fx chain to which belongs the fx whose UI is displayed in a floating window, is not open
	t[targ_idx].focus()
	end

	if old_build and not sws and create_fx_undo then -- in older builds values can only be set with SWS extension API
	r.Undo_EndBlock('Focus FX window',-1)
	end

re_store_config_var('fxfloat_focus', 65536, fxfloat_focus) -- restore original pref value, arg 2 is irrelevant here // will only run if build is 7.74 or sws extension is installed

do return r.defer(no_undo) end

