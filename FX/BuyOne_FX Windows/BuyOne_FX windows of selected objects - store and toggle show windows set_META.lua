--[[
ReaScript name: BuyOne_FX windows of selected objects - store and toggle show windows set_META.lua (17 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962, v7.74 is recommended unless SWS/S&M extension is installed
Extensions: SWS/S&M is recommended
Metapackage: true
Provides: 	[main=main,midi_editor] .
			. > BuyOne_FX windows of selected objects - store set 1.lua
			. > BuyOne_FX windows of selected objects - store set 2.lua
			. > BuyOne_FX windows of selected objects - store set 3.lua
			. > BuyOne_FX windows of selected objects - store set 4.lua
			. > BuyOne_FX windows of selected objects - store set 5.lua
			. > BuyOne_FX windows of selected objects - store set 6.lua
			. > BuyOne_FX windows of selected objects - store set 7.lua
			. > BuyOne_FX windows of selected objects - store set 8.lua
			. > BuyOne_FX windows of selected objects - toggle show set 1.lua
			. > BuyOne_FX windows of selected objects - toggle show set 2.lua
			. > BuyOne_FX windows of selected objects - toggle show set 3.lua
			. > BuyOne_FX windows of selected objects - toggle show set 4.lua
			. > BuyOne_FX windows of selected objects - toggle show set 5.lua
			. > BuyOne_FX windows of selected objects - toggle show set 6.lua
			. > BuyOne_FX windows of selected objects - toggle show set 7.lua
			. > BuyOne_FX windows of selected objects - toggle show set 8.lua
			. > BuyOne_FX windows of selected objects - store and toggle show windows set (menu).lua
About:	If this script file name is suffixed with META, 
		when executed it will automatically spawn all 
		individual scripts included in the package into 
		the directory of the META script and will import 
		them into the Action list from that directory.

		If there's no META suffix in this script file 
		name it will perfom the operation indicated in 
		its name.

		In the 'toggle show' and the menu scripts the 
		toggle direction is determined by the set active
		status, i.e. visibility of all windows and FX UIs
		stored in the set. If at least one window is 
		closed or FX UI isn't visible the set is re-activated.

		Since the stored data are project specific, in 
		order for them to be available in the next project
		session the project must be saved.

		The order windows are opened in doesn't 
		necessarily follow their order at the moment 
		of set storage.  	
		The priority in opening is as follows:
		1. track main FX chain
		2. track input FX chain (Monitoring FX for the Master track)
		3. take FX chains
		FX belonging to the same FX chain are opened 
		in ascending order.

		LIMITATIONS

		1. In builds older than 7.06 the script doesn't 
		support FX inside containers   
		2. It doesn't support floating windows of bridged 
		x86 bit plugins on x64 bit systems, unless the 
		option  
		Run As -> Embed bridged UI  
		in the plugin right click context menu in the 
		FX Browser is enabled.

		If you run REAPER build older than 7.74 and don't have
		SWS/S&M extension installed, it's recommended to enabled
		the preference at
		Preference -> Plugins -> Do not create undo points when closing FX windows

		SETTINGS

		The behavior of the scripts included in the package, 
		except the 'menu' script, can be modified with
		the settings available in the script  
		BuyOne_FX windows - toggle show windows - SETTINGS.lua

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



function check(sett)
return sett and '!' or ''
end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
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



function re_store_config_var(key, bit, disable, val) -- used in Toggle_FX_Windows()
-- requires either build 7.74 or sws extension
-- key is string represnting reaper.ini key;
-- bit is integer, the bit in the bitfield which matches the target preference
-- see https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
-- BUT NOT ALL VALUES ARE BITFIELDS,
-- disable is boolean to disable preference if enabled
-- and the argument assumes that disable means unsetting the bit in a bitfield,
-- keep it false/nil if in order to disable a preference its bit must be set;
-- val is the original value assosiated with the key
-- which is returned at the storage stage and restored at the restoration stage;
-- arg val must be nil in the storage stage while bit and disable args may be nil at the restoration stage

	if not key or type(key) ~= 'string' then return end

local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.74 -- where set_config_var_string() isn't supported

	if old_build and not r.SNM_SetIntConfigVar then return end -- in older builds values can only be set with SWS extension API

local ret, cur_val = r.get_config_var_string(key)

	if not cur_val or #cur_val == 0 then return end

local upd_val

	if not val then -- get to store
	local bit_set = cur_val+0&bit == bit
		if not disable and not bit_set then
		upd_val = cur_val+0 | bit -- set bit
		elseif disable and bit_set then
		upd_val = cur_val+0 ~ bit -- unset bit
		end
	end

--local key = 'fxfloat_focus', 65536
local set = old_build and {r.SNM_SetIntConfigVar, key, val}
or {r.set_config_var_string, key, val, not val and 0 or 1} -- persist arg in set_config_var_string() depends on the stage, at the storage stage it's 0 so the value is not written into reaper.ini, otherwise 1 for the restored value to be written, OR PROBABLY since at the storage stage it's not written it will be preserved anyway so at the restoration stage 0 can be ued as well

	if upd_val or val then -- update value at the storage stage or restore
	set[3] = val or upd_val -- update with the calculated value if val arg is nil, i.e. storage stage
	set[1](table.unpack(set, 2)) -- unpack starting from index 2
	end
	if not val and upd_val then -- OR 'if upd_val' // only return at the storage stage provided the setting was updated
	return cur_val+0
	end

end



-- used in close_all_fx_windows(), Store_FX_Windows(), Toggle_FX_Windows()
function Get_FX_Type(obj, fx_idx)
-- https://forum.cockos.com/showthread.php?t=277103
local plug_types_t = {[0] = 'DX', [1] = 'LV2', [2] = 'JSFX', [3] = 'VST',
[4] = '', [5] = 'AU', [6] = 'Video processor', [7] = 'CLAP', [8] = 'Container'}
local validate = r.ValidatePtr
local GetIOSize = obj and (validate(obj, 'MediaItem_Take*') and r.TakeFX_GetIOSize
or validate(obj, 'MediaTrack*') and r.TrackFX_GetIOSize)
	if GetIOSize then
	local plug_type, inputPins_cnt, outputPins_cnt = GetIOSize(obj, fx_idx)
	return plug_types_t[plug_type]
	end
end



-- used in Set_FX_Shown_In_Container(), Store_FX_Windows(), active_set()
function Get_FX_Shown_In_Container(obj, cont_idx, respect_empty_cont)
-- find the fx currently shown in the open innermost container;
-- cont_idx is index of the outermost selected container;
-- respect_empty_cont is boolean to instruct the function to return
-- index of the innermost selected/shown container in case it's empty
-- because due to its being empty nil will be returned otherwise

--[-[
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

do return end

--]]--------------------------------------------------
-- THE FOLLOWING WORKS AS WELL BUT RELIES ON Get_FX_Container_Chunk()
-- WHICH MAY INTRODUCE UNNECESSARY OVERHEAD


local chunk = Get_FX_Container_Chunk(obj, cont_idx)

	if not chunk then return end

-- get simple index of the fx currently shown in the container
local sel_fx = chunk:match('SHOW (%d+)') -- since SHOW value is 1-based, 0 means the fx chain is closed or no UI is shown because the container itself or one of its parent containers are not selected in the chain; when an empty innermost container is selected in the chain the value will still be 1, but the function will return nil because there's no fx // when SHOW value isn't 0 it's identical to LASTSEL because in order for fx UI to be shown in the fx chain the fx must be selected, in this case they only differ by 1 because SHOW is 1-based while LASTSEL is 0-based

	if sel_fx == '0' then return end

sel_fx = sel_fx-1 -- convert to 0-based
local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetIOSize, GetParm = table.unpack(take and {r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm}
or tr and {r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm})
--local retval, fx_cnt = GetParm(obj, cont_idx, 'container_count') -- get count of fx inside container
--	if fx_cnt == '0' then return end
local ret, sel_fx_idx = GetParm(obj, cont_idx, 'container_item.'..sel_fx) -- get container based index of the selected fx, i.e. with added 0x2000000

	if not ret then return end -- empty container

sel_fx_idx = sel_fx_idx+0 -- converting to integer because GetParm() return value is a string

	-- verify if it's a nested container
	if GetIOSize(obj, sel_fx_idx) ~= 8 then return sel_fx_idx -- fx, not container, return its container based index
	else -- if nested container which cannot be displayed due to lack of a UI
		if respect_empty_cont then
		local ret, count = GetParm(obj, sel_fx_idx, 'container_count')
			if count == '0' then return sel_fx_idx end -- empty container, no point to go recursive, return its own index
		end
	return Get_FX_Shown_In_Container(obj, sel_fx_idx) -- go recursive until a plugin is reached // may be nil if the innermost container is empty
	end

end



-- used in Toggle_FX_Windows()
function Set_FX_Shown_In_Container(obj, fx_idx, fx_GUID, want_parent)
-- fx_idx is container aware index of the container fx
-- which has to be selected across the entire container hierarchy
-- fx_GUID is optional, an expected GUID of the fx at fx_idx
-- as a safeguard against change of fx position
-- within its immediate parent container;
-- want_parent is boolean to only select the fx in its immediate
-- parent container rather than across the entire container hierarchy

	local function convert_fx_idx(fx_idx)
	-- convert to 0-based index
		if fx_idx < 0x2000000 then return fx_idx end
	local ret, par_idx = GetParm(obj, fx_idx, 'parent_container')
	local ret, fx_cnt = GetParm(obj, par_idx, 'container_count')
		for i=0, fx_cnt-1 do
		local ret, idx = GetParm(obj, par_idx, 'container_item.'..i)
			if idx+0 == fx_idx then return i end
		end
	end

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
GetGUID, GetParm, SetParm = table.unpack(take and {r.TakeFX_GetFXGUID, r.TakeFX_GetNamedConfigParm, r.TakeFX_SetNamedConfigParm}
or tr and {r.TrackFX_GetFXGUID, r.TrackFX_GetNamedConfigParm, r.TrackFX_SetNamedConfigParm})
local ret, GUID = GetGUID(obj, fx_idx)
local ret, par_idx = GetParm(obj, fx_idx, 'parent_container')

	if not ret then return end -- not container fx

	if fx_GUID and GUID ~= fx_GUID then
	-- GUIDs don't match, the original fx instance index
	-- may have changed due to fx being moved within its parent container
	-- find its current index
	fx_idx = nil -- reset
	local ret, fx_cnt = GetParm(obj, par_idx, 'container_count')
		for i=0, fx_cnt-1 do
		local ret, idx = GetParm(obj, par_idx, 'container_item.'..i)
		local GUID = GetGUID(obj, idx)
			if GUID == fx_GUID then fx_idx = idx+0 break end -- 0-based index
		end
	if not fx_idx then return end -- the original fx wasn't found in its parent container
	-- could have been searched across the entire fx chain, but that's probably overkill
	end

-- first select fx inside its immediate parent container
local ret, cont_chain_addr = GetParm(obj, par_idx, 'container_item.0') -- container_item.0 to query value to be used as container chain address alongside chain_sel attribute and which must correspond to 0 used to address the main chain, much like 0x1000000 is used to address the input/monitoring chain // THE ABSOLUTELY CRUCIAL PART https://forum.cockos.com/showthread.php?t=310132
SetParm(obj, cont_chain_addr, 'chain_sel', convert_fx_idx(fx_idx))

	if want_parent then return end -- no need to continue after fx has been selected in its immediate parent container

-- continue, selecting parent containers across the entire
-- parent container hierarchy starting from par_idx
local fx_idx, i = par_idx+0, 0
	repeat
	local ret, par_idx = GetParm(obj, fx_idx, 'parent_container')
		if not ret then -- reached the outermost chain
		SetParm(obj, fx_idx-0x2000000 < 0x1000000 and 0 or 0x1000000, 'chain_sel', convert_fx_idx(fx_idx)) -- adjust container chain address depending on the chain type, main or input/monitoring
		break
		else
		-- select latest found container in its own container
		local ret, cont_chain_addr = GetParm(obj, par_idx, 'container_item.0')
		SetParm(obj, cont_chain_addr, 'chain_sel', convert_fx_idx(fx_idx))
		fx_idx = par_idx+0 -- update for the next cycle
		end
	i=i+1
	until not ret

end



-- used in close_all_fx_windows()
function Collect_All_Container_FX_Indices(obj, t, recFX, parent_cntnr_idx, parents_fx_cnt)
-- creates table containing indices of fx inside containers in nested tables
-- following container hierarchy;
-- t must be nil, obj is track or take, recFX is boolean to target input/Monitoring FX
-- parent_cntnr_idx, parents_fx_cnt must be nil
-- fx indices from the outermost fx chain (the object main fx chain) are of course stored as well
-- see Loop_Over_FX_Container_Table() next

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

local FXCount, GetIOSize, GetConfig = table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize,
r.TrackFX_GetNamedConfigParm} or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize,
r.TakeFX_GetNamedConfigParm} or {})

local fx_cnt = not parent_cntnr_idx and (recFX and r.TrackFX_GetRecCount(obj) or FXCount(obj))
fx_cnt = fx_cnt or ({GetConfig(obj, parent_cntnr_idx, 'container_count')})[2]

local t = t or {} -- add table for the outermost FX chain on the very first run

	-- collect all fx instances in a chain, including containers
	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	end

	-- search for containers in the fx chain data stored above
	-- and if found go recursive to collect fx instances inside them
	for i, fx_idx in ipairs(t) do
	local container = GetIOSize(obj, fx_idx) == 8
	local retval, cont_fx_cnt = GetConfig(obj, fx_idx, 'container_count') -- retval true even if container is empty
		if container and cont_fx_cnt+0 > 0 then -- non-empty container
		t[i] = {fx_idx, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and fx_idx or 0x2000000+fx_idx+1
		local parents_fx_cnt = (parents_fx_cnt or 1) * (#t+1) -- #t is equal to fx count in the parent container
		-- the function must not return table, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[i][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end

return t

end




-- used in close_all_fx_windows()
function Loop_Over_FX_Container_Table(obj, t)
-- obj is track or take, t is the table returned by Collect_All_Container_FX_Indices() above

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

-- add functions as necessary depending on the type of fx processing needed
local FXCount, GetIOSize, GetConfig, SetConfig, GetFXName, GetOpen, Show =
table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm,
r.TrackFX_SetNamedConfigParm, r.TrackFX_GetFXName, r.TrackFX_GetOpen, r.TrackFX_Show}
or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm,
r.TakeFX_SetNamedConfigParm, r.TakeFX_GetFXName, r.TakeFX_GetOpen, r.TakeFX_Show} or {})

	-- target fx instances in a chain ignoring containers
	for k, fx_idx in ipairs(t) do
		if tonumber(fx_idx) then -- fx instance // if container evaluation will be false since the value is a table
			if GetOpen(obj, fx_idx) then Show(obj, fx_idx, 2) end
		end
	end
	-- target containers, ignoring fx instances
	for k, cont in ipairs(t) do
		if not tonumber(cont) then -- table storing container index and its fx list
			if GetOpen(obj, cont[1]) then Show(obj, cont[1], 2) end
		Loop_Over_FX_Container_Table(obj, cont[2]) -- go recursive to loop over container fx, cont[2] is the address of the nested table with container fx indices list, at cont[1] container own index is stored
		end
	end

end



-- used in Toggle_FX_Windows()
function close_all_fx_windows()
-- relies on Collect_All_Container_FX_Indices(), Get_FX_Type() and Loop_Over_FX_Container_Table()
-- to address floating windows of fx inside containers;
-- docked fx chain windows are also closed

	for tr_idx=-1, r.CountTracks(0)-1 do -- start from -1 to accommodate master track
	local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
	local chain_vis_idx = r.TrackFX_GetChainVisible(tr)
		if chain_vis_idx ~= -1 then r.TrackFX_Show(tr, chain_vis_idx, 0) end
		for i=0, r.TrackFX_GetCount(tr)-1 do
		local floating = r.TrackFX_GetFloatingWindow(tr, i)
			if floating then r.TrackFX_Show(tr, i, 2) end
			if Get_FX_Type(tr, i) == 'Container' then
			local t = Collect_All_Container_FX_Indices(tr)
			Loop_Over_FX_Container_Table(tr, t) -- since with container fx it's impossble to query whether UI is open in a floating window due to API limitation, closing them straight just in case they're open
			end
		end
	local chain_vis_idx = r.TrackFX_GetRecChainVisible(tr)
		if chain_vis_idx ~= -1 then r.TrackFX_Show(tr, chain_vis_idx+0x1000000, 0) end -- for input fx the designated function returns regular	index hence adding 0x1000000
		for i=0, r.TrackFX_GetRecCount(tr)-1 do
		local i = i+0x1000000
		local floating = r.TrackFX_GetFloatingWindow(tr, i)
			if floating then r.TrackFX_Show(tr, i, 2) end
			if Get_FX_Type(tr, i) == 'Container' then
			local t = Collect_All_Container_FX_Indices(tr)
			Loop_Over_FX_Container_Table(tr, t, 1) -- since with container fx it's impossble to query whether UI is open in a floating window due to API limitation, closing them straight just in case they're open // recFX true
			end
		end
		for i=0, r.CountTrackMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr, i)
			for i=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, i)
				if take then
				local chain_vis_idx = r.TakeFX_GetChainVisible(take)
					if chain_vis_idx ~= -1 then r.TakeFX_Show(take, chain_vis_idx, 0) end
					for i=0, r.TakeFX_GetCount(take)-1 do
					local floating = r.TakeFX_GetFloatingWindow(take, i)
						if floating then r.TakeFX_Show(take, i, 2) end
						if Get_FX_Type(take, i) == 'Container' then
						local t = Collect_All_Container_FX_Indices(take)
						Loop_Over_FX_Container_Table(take, t) -- since with container fx it's impossble to query whether UI is open in a floating window due to API limitation, closing them straight just in case they're open
						end
					end
				end
			end
		end
	end

end



function Store_FX_Windows(set_idx, menu)

	local function store(set_idx, obj, input_fx, container_idx) -- input_fx is boolean
	local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local ChainVis, FloatingWnd, Count, GetGUID, GetParm, GetSet = table.unpack(take and {r.TakeFX_GetChainVisible, r.TakeFX_GetFloatingWindow, r.TakeFX_GetCount, r.TakeFX_GetFXGUID, r.TakeFX_GetNamedConfigParm, r.GetSetMediaItemTakeInfo_String}
	or tr and {input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow, input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_GetFXGUID, r.TrackFX_GetNamedConfigParm, r.GetSetMediaTrackInfo_String})
	local chain_vis_idx = ChainVis(obj) -- for input fx the designated function returns regular index
	local title = 'P_EXT:'..set_idx..':'..(input_fx and 'input_fx:' or '')

		-- clear all data for these keys before storage
		if not container_idx then -- without this condition, in recursive loop everything will be cleared again
		GetSet(obj, title..'chain', '', true) -- is_set true
		GetSet(obj, title..'float', '', true)
		GetSet(obj, title..'cont_vis', '', true)
		end

	local ret, count = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_count')}
	or {true, Count(obj)})
	local exist
		for i=0, count-1 do
		local fx_chain_vis = not container_idx and chain_vis_idx == i -- for input fx the designated function returns regular index // the condition is irrelevant for conainer fx because ChainVis() function only returns main chain indices, besides this main fx chain window cannot be opened by FX_Show() where container fx index is passed because instead of the main fx chain a floating window of such fx first parent container is opened
		local ret, i = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_item.'..i)} or {true, i})
		i = i + (input_fx and not container_idx and 0x1000000 or 0) -- convert into input fx index format if not container fx or into integer if index of fx inside container because GetParm() returns string and it doesn't require addition of 0x1000000
		local floating = FloatingWnd(obj, i)
		local GUID = GetGUID(obj, i)
			if fx_chain_vis then
			GetSet(obj, title..'chain', GUID, true) -- is_set true
			exist = 1
				if Get_FX_Type(obj, i) == 'Container' then -- store properties of container fx supposed to be displayed in the chain in order to restore its visibility across all parent containers
				local idx = Get_FX_Shown_In_Container(obj, i, 1) -- respect_empty_cont true
				local GUID_vis = GetGUID(obj, idx)
				local floating = FloatingWnd(obj, idx) and '1' or '0' -- store the display mode of this fx for evaluation of set active state, the set will be considered non-active if the fx actual display mode doesn't match the stored one
				GetSet(obj, title..'cont_vis', idx..GUID_vis..floating, true) -- is_set true
				end
			end
			if floating then
			local ret, floats = GetSet(obj, title..'float', '', false) -- is_set false
			floats = floats..GUID
			GetSet(obj, title..'float', floats, true) -- is_set true
			exist = 1
			end
			if Get_FX_Type(obj, i) == 'Container' and not old_build then -- go recursive
			exist = store(set_idx, obj, input_fx, i) or exist
			end
		end
	return exist
	end


	local function store_in_set_list(obj, set_idx, exist)
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local GetSet = take and r.GetSetMediaItemTakeInfo_String or tr and r.GetSetMediaTrackInfo_String
	local ret, data = GetSet(obj, 'P_EXT:sets', '', false)
	local bit, data = 2^(set_idx-1), #data > 0 and data+0 or 0
	local stored, data_new = data&bit == bit
	local data_new = exist and not stored and data|bit or stored and not exist and data~bit -- include or exclude
		if data_new then -- update
		GetSet(obj, 'P_EXT:sets', data_new == 0 and '' or data_new, true) -- is_set true // deleting the extended state when the object isn't associated with any set
		end
	end


local exist

	for i=0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0,i,true) -- wantmaster true
	exist = store(set_idx, tr, nil) -- main chain // input_fx nil, passed because one argument is requred between tr and container_idx inside store() when it's called recursively
	local exist_here = store(set_idx, tr, 1) -- input chain // input_fx true
	store_in_set_list(tr, set_idx, exist_here) -- store or remove to be able to reliably ascertain that there's no stored set, independently of the value returned by active_set() so that the error message inside Toggle_FX_Windows() is better tailored to the situation when collect() returns an empty table
	exist = exist or exist_here
	end

	for i=0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
		for take_idx=0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, take_idx)
			if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
			local exist_here = store(set_idx, take, nil) -- input_fx nil, passed because one argument is requred between take and container_idx inside store() when it's called recursively
			store_in_set_list(take, set_idx, exist_here)
			exist = exist or exist_here
			end
		end
	end


	if exist then
	Error_Tooltip('\n\n fx windows set '..set_idx..' \n\n  has been stored \n\n', 1, 1) -- caps, spaced true
	return 1 -- truth, only for the menu script
	else
	Error_Tooltip('\n\n no supported fx windows \n\n  or their parent objects \n\n\t aren\'t selected\n\n', 1, 1) -- caps, spaced true
	local dur = menu and 2 or 3.5 -- if menu, extend the pause on top of the one initialized in the main routine
	pause(dur)
	end


end




function Toggle_FX_Windows(set_idx, set_is_active, stored_set, t, menu)
-- set_is_active, stored_set stem from active_set()
-- t stems from get_settings()

	local function collect(set_idx, fx_t, obj, input_fx, container_idx) -- input_fx is boolean
	local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local ChainVis, FloatingWnd, Count, GetGUID, GetParm, GetSet = table.unpack(take and {r.TakeFX_GetChainVisible, r.TakeFX_GetFloatingWindow, r.TakeFX_GetCount, r.TakeFX_GetFXGUID, r.TakeFX_GetNamedConfigParm, r.GetSetMediaItemTakeInfo_String}
	or tr and {input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow, input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_GetFXGUID, r.TrackFX_GetNamedConfigParm, r.GetSetMediaTrackInfo_String})
	local ret, count = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_count')} or {true, Count(obj)})
		for i=0, count-1 do
		local fx_chain_vis = not container_idx and ChainVis(obj) == i -- for input fx the designated function returns regular index // validating if current fx is the one open in the fx chain window // the condition is irrelevant for conainer fx because ChainVis() function only returns main chain indices, besides this main fx chain window cannot be opened by FX_Show() where container fx index is passed because instead of the main fx chain a floating window of such fx first parent container is opened
		local ret, i = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_item.'..i)} or {true, i})
		i = i + (input_fx and not container_idx and 0x1000000 or 0) -- convert into input fx index format if not container fx or into integer if index of fx inside container because GetParm() returns string and it doesn't require addition of 0x1000000
		local GUID = GetGUID(obj, i)
		local floating = FloatingWnd(obj, i)
		local title = 'P_EXT:'..set_idx..':'..(input_fx and 'input_fx:' or '')
		local ret, chain = GetSet(obj, title..'chain', '', false) -- is_set false
		local ret, float = GetSet(obj, title..'float', '', false) -- is_set false
		chain, float = chain == GUID, float:match(Esc(GUID))
			if chain or float then
			fx_t[#fx_t+1] = {idx=i, obj=obj}
			end
			if Get_FX_Type(obj, i) == 'Container' and not old_build then -- go recursive
			collect(set_idx, fx_t, obj, input_fx, i)
			end
		end
	-- fx_t doesn't have to be returned because the original table var is used inside the function
	end


	local function toggle(set_idx, obj, fx_idx, show)
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local input_fx = fx_idx >= 0x1000000 and fx_idx <= 0x2000000 or fx_idx-0x2000000 >= 0x1000000
	local GetGUID, ChainVis, FloatingWnd, Show, GetSet = table.unpack(take and {r.TakeFX_GetFXGUID, r.TakeFX_GetChainVisible, r.TakeFX_GetFloatingWindow, r.TakeFX_Show, r.GetSetMediaItemTakeInfo_String}
	or tr and {r.TrackFX_GetFXGUID, input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow, r.TrackFX_Show, r.GetSetMediaTrackInfo_String})
	local GUID = GetGUID(obj, fx_idx)
	local title = 'P_EXT:'..set_idx..':'..(input_fx and 'input_fx:' or '')
	local ret, chain = GetSet(obj, title..'chain', '', false) -- is_set false
	local ret, float = GetSet(obj, title..'float', '', false) -- is_set false
	chain, float = chain == GUID, float:match(Esc(GUID))
	local ret, cont_vis = GetSet(obj, title..'cont_vis', '', false)
	local cont_vis_idx, cont_vis_GUID, floating = cont_vis:match('^(%d+)({.+})(%d)')

	-- first close all
	local flag = chain and 0 or float and 2
	Show(obj, fx_idx, flag)
		if chain and float then -- same fx is selected in the chain and open in a floating window
		Show(obj, fx_idx, 2) -- close the floating window
		end
		if floating == '0' and FloatingWnd(obj, cont_vis_idx+0) then
		-- container fx displayed in the innermost container wasn't open in a floating window
		-- at the moment of storage, but is currently open in a floating window, so close
		Show(obj, cont_vis_idx+0, 2)
		end
	-- then open if must be shown
	flag = show and (chain and 1 or float and 3)
		if flag then
			if chain and cont_vis_idx then -- restore before opening the fx chain
			Set_FX_Shown_In_Container(obj, cont_vis_idx+0, cont_vis_GUID)
			end
		Show(obj, fx_idx, flag)
			if chain and float then -- same fx must be selected in the chain and opened in a floating window
			Show(obj, fx_idx, 3) -- open the floating window
			end
		end
	end


	local function is_set_stored(set_idx, obj)
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local GetSet = take and r.GetSetMediaItemTakeInfo_String or tr and r.GetSetMediaTrackInfo_String
	local ret, data = GetSet(obj, 'P_EXT:sets', '', false)
	local bit, data = 2^(set_idx-1), #data > 0 and data+0 or 0
	return data+0&bit == bit
	end

local show_excl, ignore_muted, respect_all_takes = table.unpack(t) -- ignore_muted covers bypassed chain as well
local master = r.GetMasterTrack(0)
local monitoring_on = r.GetToggleCommandStateEx(0, 41884) ~= 1 -- Monitoring FX: Toggle bypass

-- first collect fx in order to validate their existence
local fx_t = {}
local stored_data

	for i=0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0,i,true) -- wantmaster true
	stored_data = stored_data or is_set_stored(set_idx, tr) -- retrieve value stored inside Store_FX_Windows() to reliably ascertain that there's no stored set, independently of the value returned by active_set() so that the error message below is better tailored to the situation when collect() returns an empty table
	local muted, bypassed_fx = r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 1, r.GetMediaTrackInfo_Value(tr, 'I_FXEN') == 0
		if not set_is_active and (not ignore_muted or not muted and not bypassed_fx) or set_is_active then
		collect(set_idx, fx_t, tr, nil) -- main chain // input_fx nil, passed because one argument is requred between tr and container_idx inside collect() when it's called recursively // 'not set_is_active' ensures that the settings only affect closed fx windows so that if they were enabled while the windows of the affected objects were open those windows could still be closed
		end
		if not set_is_active and (not ignore_muted or not muted and (tr == master and monitoring_on or tr ~= master))
		or set_is_active then -- input chain cannot be bypassed, only monitoring // for 'not set_is_active' see explanation above
		collect(set_idx, fx_t, tr, 1) -- input chain // input_fx true
		end
	end

	for i=0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local item_tr = r.GetMediaItemTrack(item)
	local muted = r.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 or r.GetMediaTrackInfo_Value(item_tr, 'B_MUTE') == 1
	local not_muted_or_active = not set_is_active and (not ignore_muted or not muted) or set_is_active -- for 'not set_is_active' see explanation above
	local play_all = r.GetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY') == 1
		if not respect_all_takes or not play_all then
		local take = r.GetActiveTake(item)
			if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
			stored_data = stored_data or is_set_stored(set_idx, take) -- explanation of the purpose see in track loop above
				if not_muted_or_active then
				collect(set_idx, fx_t, take, nil) -- input_fx nil, passed because one argument is requred between take and container_idx inside collect() when it's called recursively
				end
			end
		else
			for take_idx=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, take_idx)
				if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
				stored_data = stored_data or is_set_stored(set_idx, take) -- explanation of the purpose see in track loop above
					if not_muted_or_active then
					collect(set_idx, fx_t, take, nil) -- input_fx nil, passed because one argument is requred between take and container_idx inside collect() when it's called recursively
					end
				end
			end
		end
	end

	if #fx_t == 0 then
	local err = stored_set and '\t no fx windows \n\n which could be toggled'
	or not stored_data and '   fx windows set '..set_idx..' \n\n  appears to be empty \n\n for selected objects'
	or '\t  fx instances \n\n belonging to the set '..set_idx..' \n\n\tweren\'t found \n\n   in selected objects'

	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
		if err:match('objects') then
		local dur = menu and 2 or 3.5 -- if menu, extend the pause on top of the one initialized in the main routine
		pause(dur)
		end
	return end

local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.74 -- where set_config_var_string() isn't supported
local sws = r.BR_Win32_GetForegroundWindow
local ret, create_fx_undo = r.get_config_var_string('fxfloat_focus')
create_fx_undo = create_fx_undo+0&65536 ~= 65536

-- if the preference at Preferences -> Plugins -> Do not create undo points when closing FX windows
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

local fxfloat_focus = re_store_config_var('fxfloat_focus', 65536, disable) -- disable false because the preference must be enabled to prevent undo point creation // store original pref value and disable creation of undo point when fx windows are toggled // will only run if build is 7.74 or sws extension is installed

	if not set_is_active
	and show_excl then -- close all before toggling windows open
	close_all_fx_windows()
	end

	for k, data in ipairs(fx_t) do
	toggle(set_idx, data.obj, data.idx, not set_is_active) -- if not set_is_active toggle to On
	end

	if old_build and not sws and create_fx_undo then -- in older builds values can only be set with SWS extension API
	r.Undo_EndBlock('Toggle FX windows set '..set_idx..' in selected objects',-1)
	end

re_store_config_var('fxfloat_focus', 65536, disable, fxfloat_focus) -- restore original pref value, arg 2 and 3 a irrelevant here // will only run if build is 7.74 or sws extension is installed

return 1 -- truth, only for the menu script

end



function active_set(set_idx, t)

	local function evaluate(set_idx, obj, input_fx, container_idx, count_stored, count_open) -- input_fx is boolean
	local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06
	local validate = r.ValidatePtr
	local tr, take = validate(obj, 'MediaTrack*'), validate(obj, 'MediaItem_Take*')
	local ChainVis, FloatingWnd, Count, GetGUID, GetParm, GetSet = table.unpack(take and {r.TakeFX_GetChainVisible,
	r.TakeFX_GetFloatingWindow, r.TakeFX_GetCount, r.TakeFX_GetFXGUID, r.TakeFX_GetNamedConfigParm, r.GetSetMediaItemTakeInfo_String}
	or tr and {input_fx and r.TrackFX_GetRecChainVisible or r.TrackFX_GetChainVisible, r.TrackFX_GetFloatingWindow, input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount, r.TrackFX_GetFXGUID, r.TrackFX_GetNamedConfigParm, r.GetSetMediaTrackInfo_String})
	local ret, fx_cnt = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_count')} or {true, Count(obj)})
	local count_stored, count_open = count_stored or 0, count_open or 0
		for i=0, fx_cnt-1 do
		local ret, i = table.unpack(container_idx and {GetParm(obj, container_idx, 'container_item.'..i)} or {true, i})
		local GUID = GetGUID(obj, i + (input_fx and not container_idx and 0x1000000 or 0))
		local title = 'P_EXT:'..set_idx..':'..(input_fx and 'input_fx:' or '')
		local ret, chain = GetSet(obj, title..'chain', '', false) -- is_set false
		local ret, float = GetSet(obj, title..'float', '', false) -- is_set false
		chain, float = chain == GUID, float:match(Esc(GUID)) -- fx GUID matches stored GUID
			if chain or float then
			count_stored = count_stored+1
			local fx_chain_vis = chain and not container_idx and ChainVis(obj) == i -- for input fx the designated function returns regular index // validating if current fx is the one open in the fx chain window // the condition is irrelevant for conainer fx because ChainVis() function only returns main chain indices, besides this main fx chain window cannot be opened by FX_Show() where container fx index is passed because instead of the main fx chain a floating window of such fx first parent container is opened
			i = i + (input_fx and not container_idx and 0x1000000 or 0)
			local ret, cont_vis = GetSet(obj, title..'cont_vis', '', false)
			local cont_vis_idx, cont_vis_GUID, floating = cont_vis:match('^(%d+)({.+})(%d)')
			local idx = fx_chain_vis and cont_vis_idx and Get_FX_Type(obj, i) == 'Container'
			and Get_FX_Shown_In_Container(obj, i, 1) -- respect_empty_cont true // cont_vis_idx can only be valid if container was stored under 'chain' key
			local cont_fx_vis = not cont_vis_idx or cont_vis_idx+0 == idx and GetGUID(obj, idx) == cont_vis_GUID
			and (floating == '1' and FloatingWnd(obj, idx) or floating == '0' and not FloatingWnd(obj, idx)) -- either no stored visible cont fx index or the stored one and the current one match including the display mode, inside the chain or in a floating window
			local floating = float and FloatingWnd(obj, i)
			local both = fx_chain_vis and floating -- scenario where fx is both selected in the main fx chain and open in a floating window
				if both and cont_fx_vis or fx_chain_vis and cont_fx_vis and not float or floating and not chain then -- only respect saved configuration, i.e. fx is both selected in the chain and open in a floating window or either one without the second, to enure that if the first scenario doesn't occur the set is considered inactive
				count_open = count_open+1
				end
			end
		i = i + (input_fx and not container_idx and 0x1000000 or 0) -- adjust the i value here as well because the above adjustment is inside a block which even if performed, won't be accessible here
			if Get_FX_Type(obj, i) == 'Container' and not old_build then
			local stored, open = evaluate(set_idx, obj, input_fx, i, count_stored, count_open)
			count_stored = count_stored + stored
			count_open = count_open + open
			end
		end
	return count_stored, count_open
	end


local dot = ' \226\128\162' -- Bullet U+2022
-- local dot = ' \226\151\143' -- Black Circle U+25CF
local show_excl, ignore_muted, respect_all_takes = table.unpack(t) -- show_excl is unused here // ignore_muted covers bypassed chain as well
local master = r.GetMasterTrack(0)
local monitoring_on = r.GetToggleCommandStateEx(0, 41884) ~= 1 -- Monitoring FX: Toggle bypass
local stored_exist, inactive

-- evaluate() function isn't conditioned by the settings in order to able to recognize a set with stored data,
-- the settings condition the early loop exit return values instead, which are ignored
-- when the condition is false as if evaluate() function has never been called

	for i=0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0,i,true) -- wantmaster true
	local stored, open = evaluate(set_idx, tr, nil) -- input_fx nil, passed because one argument is requred between tr and container_idx inside evaluate() when it's called recursively
	stored_exist = stored_exist or stored > 0
	inactive = inactive or stored ~= open
	local muted, bypassed_fx = r.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 1, r.GetMediaTrackInfo_Value(tr, 'I_FXEN') == 0
		if not ignore_muted or not muted and not bypassed_fx then
			if stored > 0 and stored ~= open then return '', dot end -- not all are open, dot indicates stored set
		end

	local stored, open = evaluate(set_idx, tr, 1) -- input_fx true
	stored_exist = stored_exist or stored > 0
	inactive = inactive or stored ~= open
		if not ignore_muted or not muted and (tr == master and monitoring_on or tr ~= master) then -- input chain cannot be bypassed, only monitoring
			if stored > 0 and stored ~= open then return '', dot end -- not all are open, dot indicates stored set
		end
	end

	for i=0, r.CountSelectedMediaItems(0)-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local item_tr = r.GetMediaItemTrack(item)
	local muted = r.GetMediaItemInfo_Value(item, 'B_MUTE') == 1 or r.GetMediaTrackInfo_Value(item_tr, 'B_MUTE') == 1
	local play_all = r.GetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY') == 1
		if not respect_all_takes or not play_all then
		local take = r.GetActiveTake(item)
			if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
			local stored, open = evaluate(set_idx, take, nil) -- input_fx nil, passed because one argument is requred between take and container_idx inside evaluate() when it's called recursively
			stored_exist = stored_exist or stored > 0
			inactive = inactive or stored ~= open
				if not ignore_muted or not muted then
					if stored > 0 and stored ~= open then return '', dot end -- not all are open, dot indicates stored set
				end
			end
		else
			for take_idx=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, take_idx)
				if take then -- in case take is empty, i.e. added with actions 'Item: Add an empty take before/after the active take'
				local stored, open = evaluate(set_idx, take, nil) -- input_fx nil, passed because one argument is requred between take and container_idx inside evaluate() when it's called recursively
				stored_exist = stored_exist or stored > 0
				inactive = inactive or stored ~= open
					if not ignore_muted or not muted then
						if stored > 0 and stored ~= open then return '', dot end -- not all are open, dot indicates stored set
					end
				end
			end
		end
	end

	if not stored_exist then return '', ''
	else return inactive and '' or '!', dot
	end

end



function get_settings(want_proj)
local sect = want_proj and 'FX WINDOWS SET OF SELECTED OBJECTS (menu)' or 'BuyOne_FX windows - toggle show settings' -- the second section name for global extended state is shared by non-menu scripts from this package and from 'FX windows - store and toggle show windows set_META.lua'
local key = 'settings'
local ret, sett = table.unpack(want_proj and {r.GetProjExtState(0, sect, key)} or {true, r.GetExtState(sect, key)})
sett = #sett == 0 and 0 or sett+0
local t = {}
	for i=0,2 do
	local bit = 2^i
	t[#t+1] = sett&bit == bit
	end
return t, sett
end



function settings_explication()
local e = [[
❶ Show window set exclusively — when a set is activated, all other
currently open FX windows get closed.

❷ Ignore muted objects and bypassed chains — FX windows included
in a set stemming from muted tracks/items, bypassed track main
FX chain and bypassed Master track main and monitoring FX chains,
will be ignored when the set is activated; track muted state also affects
take FX windows in items on such track.

❸ Respect all item takes when all set to play — when 'Play all takes'
option is enabled in the item properties, FX windows from all item takes
included in the set will be shown, otherwise only FX windows stemming
from the active take will be respected; the setting only applies to toggling,
whereas when a set is stored, open FX windows from all takes in a multi-
take item are included in it.


The settings only affect FX windows of STORED INACTIVE sets so that
if the settings change while the set is active, the windows stemming
from the affected objects could still be closed when the set is deactivated.

The settings are project based, so to have their state carried over
to the next session the project must be saved.
]]
r.MB(e, 'Settings Explication', 0)
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



Error_Tooltip('') -- clear any lingering tooltip

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // for META scripts without menu // due to .+[\\/] WILL ONLY WORK IF THE SCRIPT ISN'T LOCATED IN THE ROOT OF THE /Scripts folder, alternative pattern is ('[^\\/]+_(.+)%.%w+')

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_FX windows - store and toggle show windows of selected objects_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


--[[ --------------- NAME TESTING
scr_name = {
'store windows set 1',
'toggle show windows set 1',
'store windows set 5',
'toggle show windows set 5',
'store and toggle show windows sets (menu)'
}
scr_name = scr_name[5]
--]]


	if not Invalid_Script_Name(scr_name, 'store', 'toggle show', 'menu')	then
	return r.defer(no_undo)
	elseif r.CountSelectedTracks2(0, true) + r.CountSelectedMediaItems(0) == 0 then
	Error_Tooltip('\n\n no selected objects \n\n'..space(6)..'in the project \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


::RELOAD::

local set_idx = scr_name:match('%d+')
local store = scr_name:match('store')
local toggle = scr_name:match('toggle show')
local menu = scr_name:match('menu')
local sett_t, sett = get_settings(menu) -- want_proj true if menu script
local set_is_active, stored_set


	if menu then

	local underscore = '\204\178' -- Combining Low Line U+0332
	local menu = ''
		for i=1,16 do
		local item = i < 9 and 'Toggle show' or 'Store'
		local active, stored = active_set(i < 9 and i or i-8, sett_t)
		menu = menu..(#menu == 0 and '' or i == 9 and '|||' or '|')
		..(i < 9 and active or '') -- only items 1-8
		..item..' FX windows set '..(i < 9 and '&'..i..underscore or i-8)
		..(i > 8 and stored or '') -- only items 8-16
		end

	local settings = check(sett_t[1])..'❶ &S'..underscore..'how window set exclusively|' -- U+2776
	..check(sett_t[2])..'❷ &I'..underscore..'gnore muted objects and bypassed chains|' -- U+2777
	..check(sett_t[3])..'❸ &R'..underscore..'espect all item takes when all set to play||' -- U+2778
	..'(settings explication)|||'
	local output = Reload_Menu_at_Same_Pos(settings..menu, 1) -- keep_menu_open true

		if output == 0 then return r.defer(no_undo)
		elseif output < 4 then
		sett_t[output] = not sett_t[output] -- toggle
		local bit = 2^(output-1)
		sett = sett_t[output] and sett|bit or sett~bit -- update
		r.SetProjExtState(0, 'FX WINDOWS SET OF SELECTED OBJECTS (menu)', 'settings', sett)
		goto RELOAD
		elseif output == 4 then
		settings_explication()
		goto RELOAD
		end

	output = output-4 -- offset settings items
	set_idx = math.floor(output < 9 and output or output-8) -- or output == 8 and output or output%8 // stripping trailing 0

	local dot = ' \226\128\162' -- Bullet U+2022
-- local dot = ' \226\151\143' -- Black Circle U+25CF
	set_is_active = menu:match('!Toggle show FX windows set &'..set_idx..underscore)
	stored_set = menu:match('Store FX windows set '..set_idx..dot)
	store, toggle = output > 8, output < 9

	end

	if store then

		if not menu then
		local _, stored = active_set(set_idx, sett_t)
		stored_set = #stored > 0
		end

		if stored_set and r.MB('Wish to overwrite FX windows set '..set_idx..'?','PROMPT',1) == 2 then
		return r.defer(no_undo)
		end

		if not Store_FX_Windows(set_idx, menu) and menu then
		pause(1.5)
		goto RELOAD end

	elseif toggle then

		if not menu then
		set_is_active, stored_set = active_set(set_idx, sett_t)
		set_is_active, stored_set = #set_is_active > 0, #stored_set > 0
		end

		if not Toggle_FX_Windows(set_idx, set_is_active, stored_set, sett_t, menu) and menu then
		pause(1.5)
		goto RELOAD end

	end

do return r.defer(no_undo) end


