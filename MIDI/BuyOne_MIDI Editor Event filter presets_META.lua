--[[
ReaScript name: BuyOne_MIDI Editor Event filter presets_META.lua (16 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions:
Metapackage: true
Provides: 	[main=main,midi_editor] .
				. > BuyOne_MIDI Editor Event filter - store preset 1.lua
				. > BuyOne_MIDI Editor Event filter - store preset 2.lua
				. > BuyOne_MIDI Editor Event filter - store preset 3.lua
				. > BuyOne_MIDI Editor Event filter - store preset 4.lua
				. > BuyOne_MIDI Editor Event filter - store preset 5.lua
				. > BuyOne_MIDI Editor Event filter - store preset 6.lua
				. > BuyOne_MIDI Editor Event filter - store preset 7.lua
				. > BuyOne_MIDI Editor Event filter - store preset 8.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 1.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 2.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 3.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 4.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 5.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 6.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 7.lua
				. > BuyOne_MIDI Editor Event filter - apply preset 8.lua
About:	If this script file name is suffixed with META, when executed 
			it will automatically spawn all individual scripts included 
			in the package into the directory of the META script
			and will import them into the Action list from that directory.
			That's provided such scripts don't exist yet, if they do, then 
			in order to recreate them they have to be deleted from the disk 
			first, not necessarily from the Action list where their entries
			may remain.  

			If there's no META suffix in this script file name it will 
			perfom the operation indicated in its name.

			For being able to store or apply a preset the MIDI Editor 
			or the Event filter don't have to be open, i.e. the scripts
			can be installed in any section of the Action list, but the 
			take whose content is going to be affected by the Event filter 
			with the applied preset must be active in a selected item. 

			While the Event filter is closed, different Event filter preset
			can be applied to different MIDI takes in a multi-take item.
			However once Event filter is open, whatever settings are 
			associated with the active take will automatically apply to 
			all MIDI takes in the same item regardless of the preset applied
			to them previously, WHICH DOESN'T MEAN that content of the 
			inactive takes will be affected by Event filter settings applied 
			to the content of the active take.

			In the MIDI Editor to be able to execute any of the scripts 
			included and at the same time open the Event filter use the 
			following custom actions:

			--|Filter: Enable/disable event filter and show/hide filter window...
			--|BuyOne_MIDI Editor Event filter - store preset X.lua

			--|Filter: Enable/disable event filter and show/hide filter window...
			--|BuyOne_MIDI Editor Event filter - apply preset X.lua

			See also script BuyOne_MIDI Editor Event filter presets menu.lua
			The presets stored by scripts of this package and by that menu 
			script are separate.

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end

local r = reaper


function no_undo()
do return end
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

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		------------------------------------------------------------------------------------
		-- spawn scripts, but only if non-existent yet
		-- to prevent overwriting preset backup variable
		-- in the 'store' scripts
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- if a spawned script update is required it must be done or by deleting it and running this META script again
			local new_script = io.open(path..scr_name, 'w') -- create new file
		--	content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag  // commented out to keep META script original name in the header so user can find it later and re-generate individual scripts if needed
			new_script:write(content)
			new_script:close()
			end
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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found;
-- if elements are patterns or contain patterns Esc() function
-- in scr_name:lower():match(Esc(elm:lower())) should not be used

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(elm:lower()) then return elm end -- at least one match was found
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



-- used in Store_Preset() and Apply_Preset()
local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'MediaItem_Take*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, take, env = table.unpack(t)
-- Try standard function -----
local obj = take and r.GetMediaItemTake_Item(obj) or obj
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or (item or take) and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or (item or take) and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end



-- used in Store_Preset() and Apply_Preset()
function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local sws_ext_err_mess = "            The size of the data requires\n\n  the SWS/S&M extension to handle them.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
local sws_ext_link = 'Get the SWS/S&M extension at\n\nhttps://www.sws-extension.org/\n\nOR\n\nhttps://github.com/reaper-oss/sws/tags'
local resp = r.MB(sws_ext_err_mess,'ERROR',0)
	if resp == 1 then r.Main_OnCommand(42663, 0) -- ReaScript: Show ReaScript console // to override preference at Plug-ins -> ReaScript -> Do not auto-open ReaScript console which was added in 7.28, while the action was added in 7.0
	r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end



-- used in Apply_Preset()
local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'MediaItem_Take*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, take, env = table.unpack(t)
local obj = take and r.GetMediaItemTake_Item(obj) or obj
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or (item or take) and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



function Update_Script(path, sett, new_cont)
local f = io.open(path,'r')
local cont = f:read('*a')
f:close()
local cur_sett = cont:match('.*('..sett..'%s*=%C*)') or cont:match(sett..'%s*=%s*') -- OR ('.*('..sett..'%s*=.-)\n') // the pattern ensures capturing a single line only, ('.*('..sett..'%s*=%s*.-)\n') would capture the next line as well if the target line doesn't include any value after '=' sign
cur_sett = Esc(cur_sett)
new_cont = new_cont:gsub('%%', '%%%%')
cont, repl = cont:gsub(cur_sett, sett..' = "'..new_cont..'"', 1) -- store preset data as a string
local f = io.open(path,'w')
f:write(cont)
f:close()
end



function Store_Preset(take, scr_name, scr_path, idx)
-- Event filter keeps the same settings across all item takes in multi-take item even though it has a dedicated attribute in each take chunk and different data can be applied to different takes while the Event filter is closed, but as soon as Event filter is opened, whatever settings are now active will be applied to ALL item takes; still for the sake of specificity here targeting current take

local ret, chunk = GetObjChunk(take)
	if chunk == 'err_mess' then Err_mess() return end

local sect = 'BuyOne_MIDI Editor Event filter presets'
local preset_count = 8 -- IF THE NUMBER OF INDIVIDUAL SCRIPTS WILL BE INCREASED, INCREASE THIS VALUE OR PRESETS AT INDICES ABOVE 8 WON'T BE STORED

local preset_list = r.GetExtState(sect, 'preset_list')
preset_list = #preset_list > 0 and preset_list..'||' or preset_list -- add traling separator character to preset_list to be able to capture last entry by match()
local t = {}
	for i=1, preset_count do -- retrieving this way because with individual scripts the stored preset list will have gaps between preset indices, and this ensures storage of a new preset while maintaining the list's ascending order //
	local preset = preset_list:match('(preset '..i..'|.-)||')
	t[i] = preset or ''
	end

	if idx then
		if #t[idx] > 0
		and r.MB('Wish to overwrite current preset '..idx..'?', 'WARNING', 1) == 2 then -- used has declined
		return
		end
	local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- is_set false
	local filter_state = chunk:match(Esc(take_GUID)..'.-EVTFILTER (.-)\n')
	t[idx] = 'preset '..idx..'|'..filter_state
	-- concatenating via loop rather than with table.concat()
	-- because of having to prevent adding the separator '||'
	-- for empty preset fields which are likely to be present
	-- if presets aren't being saved in a descending order
	-- or being saved selectively
	local data = ''
		for k, preset in ipairs(t) do
		data = data..(#data > 0 and #preset > 0 and '||' or '')..preset
		end
	r.SetExtState(sect, 'preset_list', data, true) -- persist true
	Update_Script(scr_path, 'PRESET', filter_state)
	end

end



function Apply_Preset(take, scr_path, idx)
-- Event filter keeps the same settings across all item takes in multi-take item even though it has a dedicated attribute in each take chunk and different data can be applied to different takes while the Event filter is closed, but as soon as Event filter is opened, whatever settings are now active will be applied to ALL item takes; still for the sake of specificity here targeting current take

local ret, chunk = GetObjChunk(take)
	if ret == 'err_mess' then Err_mess() return end

local preset_list = r.GetExtState('BuyOne_MIDI Editor Event filter presets', 'preset_list')
preset_list = #preset_list > 0 and preset_list..'||' or preset_list -- add traling separator character to preset_list to be able to capture last entry
local preset = preset_list:match('preset '..idx..'|(.-)||')

	if not preset then -- if extended state is empty, look in the 'store' script
	-- 'require' syntax for loading module from the same path
	-- as the host script
	package.path = scr_path:match('.+[\\/]') .. '?.lua'
	preset = require('BuyOne_MIDI Editor Event filter - store preset '..idx) -- OR require 'my module' // the script returns PRESET variable
	end

	if not preset or #preset == 0 then
	Error_Tooltip('\n\n no stored preset \n\n', 1,1) -- caps, spaced are true
	return end

local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- is_set false
local cur_chunk = chunk:match('('..Esc(take_GUID)..'.-EVTFILTER .-)\n')
local upd_chunk = cur_chunk:match('.+EVTFILTER%s')..preset
--local take_chunk_upd = take_chunk:gsub('EVTFILTER .-\n', 'EVTFILTER '..data..'\n')
cur_chunk = Esc(cur_chunk)
upd_chunk = upd_chunk:gsub('%%', '%%%%')
chunk = chunk:gsub(cur_chunk, upd_chunk)

SetObjChunk(take, chunk)

end


local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile(), loadfile() or require() from installer script or a host script the above function will return installer/host script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // for cases where META script itself does display menu when executed // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script as fullpath_init, in fact fits both cases, i.e. META script with and without menu

	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_MIDI Editor Event filter presets_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not


Error_Tooltip('') -- clear any lingering tooltips


-- to each function call mutually exclusive script name elements must be passed
-- or a single element if it doesn't have mutually exclusive counterpart
	if not Invalid_Script_Name(scr_name, 'MIDI Editor Event filter')
	or not Invalid_Script_Name(scr_name, 'store', 'apply')
	or not Invalid_Script_Name(scr_name, '%d+')
	then return r.defer(no_undo) end

local mult_items = r.CountSelectedMediaItems(0) > 1
local ME = r.MIDIEditor_GetActive()
local sel_itm = r.GetSelectedMediaItem(0,0)
local take = ME and r.MIDIEditor_GetTake(ME) or sel_itm and r.GetActiveTake(sel_itm)
local err = cmd_ID ~= 32060 and not ME and (not sel_itm and 'no selected items'
or mult_items and 'a single selected \n\n  item is expected'
or (not take or not r.TakeIsMIDI(take)) and 'the active take is not midi')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return r.defer(no_undo)
	end

local preset_idx = scr_name:match('%d')

	if scr_name:match('store') then
	-- this block only runs when a 'store' script is executed directly
	-- because only in this case scr_name will contain the word 'store'
	-- captured from path returned by get_action_context();
	-- if it's called via require() with Apply_Preset() in an 'apply' script,
	-- get_action_context() will return the 'apply' script path
	-- so scr_name:match('store') will be invalid

	Store_Preset(take, scr_name, fullpath_init, preset_idx+0)

	elseif scr_name:match('apply') and fullpath_init == fullpath then
	-- this block only runs when 'apply' script is executed directly,
	-- but not if a 'store' script (which will also include it)
	-- is executed via require() used in Apply_Preset(),
	-- because only when a script is executed directly do its paths returned
	-- by get_action_context() and debug.getinfo() match, i.e. fullpath_init == fullpath,
	-- otherwise get_action_context() will return the host script path
	-- and if a 'store' script is called via require() scr_name variable
	-- being captured from get_action_context() path will contain 'apply'
	-- rather than 'store' which will cause 'apply' script execution from inside itself,
	-- will set off an endless loop and result in stack overflow error;
	-- so if called via require() all a 'store' script does is return
	-- the preset value below

	Apply_Preset(take, fullpath_init, preset_idx+0)

	end


-- the variable will be updated with Store_Preset() called in a 'store' script
-- and returned when 'store' scripts is called via require() with Apply_Preset() in a 'apply' script
PRESET = ''
return PRESET, r.defer(no_undo) -- allows returning value AND preventing generic 'ReaScript: Run' message in the menu bar



