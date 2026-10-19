--[[
ReaScript name: BuyOne_MIDI Editor Event filter presets menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Menu options explanation

		Store - store event filter settings preset with a custom 
		name, although the dialogue can be submitted empty in which 
		case the preset will be assigned a generic name 'Preset <No>'.

		Quick store - store event filter settings preset without a
		dialogue, i.e. with a generic preset name 'Preset <No>'.

		Update - click to enable, then click a menu item of a preset
		you wish to update with new data.

		Rename - click to enable, then click a menu item of a preset
		whose name you wish to change; submitting empty dialogue
		clears the preset name in which case it assumes the generic
		name 'Preset <No>'

		Delete - click to enable, then click a menu item of a preset
		which you wish to delete.

		The options Update, Rename and Delete are mutually exclusive
		and only persist as long as the menu is open. When none of
		them is active, clicking preset menu item activates the 
		corresponding preset.

		Toggle Event filter open - self-explanatory, but if the script
		is run from any section of the Action list but MIDI Editor 
		there will have to be a selected MIDI item in which case it 
		will be opened in the MIDI Editor in order for the Event filter 
		to be activated.

		Other options:

		Display in descending order - enable to have the preset list
		in the menu displayed in reverse which may be useful in order
		to access preset menu items invisible due to the length of 
		the preset list and accessibility of which would otherwise
		require scrolling the menu.

		Keep menu open - enable to force the menu reload after a click
		so that if several operations need to be performed in a row you 
		won't have to call the script again for each of them; this option
		is enabled automatically when the options Update, Rename or 
		Delete get enabled so that their active state persists.

		Offset preset list by: - supply the number by which to offset
		the preset list in the menu; like the option   
		'Display in descending order' is useful for being able to access
		preset menu items invisible due to the preset list length.

		Delete all - self explanatory.


		Presets can be managed without having the Event filter open.

		To apply a preset, click a corresponding menu item while the 
		options Update, Rename or Delete are disabled.	
		For being able to store or apply a preset the MIDI Editor 
		or the Event filter don't have to be open, i.e. the script
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
		The script options managed via the menu are stored in 
		reaper-extstate.ini file and also as a backup at the very end 
		of this script.
		
		The number of presets is limited to 100 but not sure one
		would need even half as many.

		In the MIDI Editor to be able to open this script and the Event
		filter simultaneously use the following custom action:

		--|Filter: Enable/disable event filter and show/hide filter window...
		--|BuyOne_MIDI Editor Event filter presets.lua

		See also script BuyOne_MIDI Editor Event filter presets_META.lua
		The presets stored by this menu script and by scripts included in 
		that META package are separate.
]]


local r = reaper

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
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
-- do return end
end



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


-- checkmarking menu items when setting is enabled
function check(sett1, sett2)
return sett2 and '#' or sett1 and '!' or ''
end



function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
end



function set_loop_direction(st, fin, condition)
-- condition being true sets descending loop order (i.e. in reverse);
-- returns start, end and direction
return table.unpack(not condition and {st, fin, 1} or {fin, st, -1})
-- OR
-- local a, b = not condition and math.min or math.max, not condition and math.max or math.min
-- return a(st, fin), b(st, fin), b(1, -1)
--[[ -- OR
a, b = math.min, math.max
	if condition then a, b = b, a end
return a(st, fin), b(st, fin), b(1, -1)
--]]
end



function replace_pipe(str)
	if str:match('|') or str:match('\226\157\152') then -- if pipe (Vetcial Line (U+007C) '\124') or Light Vertical Bar (U+2758) '\226\157\152' which is interpreted by REAPER as pipe, replace with Full Width Vertical Line (U+FF5C) '\239\189\156', OR can be replaced with Box Drawings Light Vertical (U+2502) '\226\148\132' or with Hangul character for /i/ (U+3163) '\227\133\163'
	str = str:gsub('[|\226\157\152]', '\239\189\156')
	end
return str
end



function add_leading_zeros(max_num, cur_num)
	local function calc(num)
		for i=10,0,-1 do
			if 10^i <= num then return i end -- equality operator accommodates tens, hundreds etc.
		end
	end
local max_0 = calc(max_num)
local min_0 = calc(cur_num)
min_0 = cur_num == 0 and 0 or min_0
return ('0'):rep(max_0-min_0)
end



function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end



-- used in Get_Filter_Current_State()
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



-- used in Get_Filter_Current_State()
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



-- used in Update_or_Retrieve_from_Script()
function Restore_Script_Backup_Settings(cont, cur_sett, new_cont)
-- in case deleted by the user
-- cur_sett is setting currently being modified by the script
-- new_cont is new data for such setting
local t = {}
local settings = cont:match('.+return r%.defer%(no_undo%)(.*)$') -- capture settings, if any, excluding the script code up to the last line, because parsing it with match() during the loop freezes REAPER
local lack
	for k, sett in ipairs({'EVENT_FILTER_PRESETS','DESCENDING_ORDER','KEEP_MENU_OPEN','PRESET_LIST_OFFSET'}) do
	local scr_sett = settings:match('.*('..sett..'%s*=%C*)')
		if not scr_sett then lack = 1 end
		if sett == cur_sett then -- add new data to the setting currently being modified by the script, whether it exists or not
		scr_sett = sett..' = '..new_cont
		end
	t[#t+1] = scr_sett or sett..' = ' -- either storing existing or updated setting OR re-adding non-existing setting empty
	end
	if lack then -- if at least one setting name was absent, re-add the entire section into the script with those which are present
	local cont = cont:match('.+return r%.defer%(no_undo%)') -- capture the entire script up to the last line
	local sett = '-- DATA BACKUP\n--[[\n'..table.concat(t,'\n')..'\n]]'
	return cont..('\n'):rep(10)..sett..('\n'):rep(2) -- return script code with appended backup settings section
	end
end



-- used in Store_or_Update_Preset(), Load_Data(), Store_or_Update_Preset(),
-- Rename_Preset(), Delete_Preset_or_All(), Manage_Preset_List_Offset() and in the main routine
function Update_or_Retrieve_from_Script(path, sett, new_cont)
local f = io.open(path,'r')
local cont = f:read('*a')
f:close()
	if not sett then return cont -- retrieve
	else -- update
	local updated_cont = Restore_Script_Backup_Settings(cont, sett, new_cont)
		if updated_cont then
		cont = updated_cont
		else -- no restoration is required, use the current
		local cur_sett = cont:match('.*('..sett..'%s*=%C*)') or cont:match(sett..'%s*=%s*') -- OR ('.*('..sett..'%s*=.-)\n') // the pattern ensures capturing a single line only, ('.*('..sett..'%s*=%s*.-)\n') would capture the next line as well if the target line doesn't include any value after '=' sign
		cur_sett = Esc(cur_sett)
		new_cont = new_cont:gsub('%%', '%%%%')
		cont, repl = cont:gsub(cur_sett, sett..' = '..new_cont, 1)
		end
	end
local f = io.open(path,'w')
f:write(cont)
f:close()
end



function Load_Data(scr_name, scr_path)

local sett_t = {'EVENT_FILTER_PRESETS', 'DESCENDING_ORDER', 'KEEP_MENU_OPEN', 'PRESET_LIST_OFFSET'}
local t = {}
	for k, sect in ipairs(sett_t) do
	t[#t+1] = r.GetExtState(scr_name, sect)
	end

local preset_list = t[1]

local script = Update_or_Retrieve_from_Script(scr_path) -- retrieve
local settings = script:match('.+return r%.defer%(no_undo%)(.*)$') -- capture settings, if any, excluding the script code up to the last line, to prevent possible REAPER freeze when parsing the entire code with match()

	if #preset_list == 0 then -- search this script
	preset_list = settings:match('.+EVENT_FILTER_PRESETS.-=(%C*)') -- OR ('.+EVENT_FILTER_PRESETS.-=(.-)\n') , the pattern ensures capturing a single line only // ('.+EVENT_FILTER_PRESETS.-=%s*(.-)\n') would capture the next line as well if the target line doesn't include any value or space after '=' sign
	preset_list = preset_list:match('%S.+') -- strip leading space if any
	end

-- if extended state happens to be empty in case of its loss, retrieve from script
-- if extended state is intact, the script data are supposed to be in sync with it
	for i = 2, #sett_t do -- starting from index 2 because preset list was processed separately above
	local sett = sett_t[i]
	t[i] = t[i]:match('%S') or settings:match('.*'..sett..'.-=(%C*)') -- OR ('.*'..sett..'%s*=(.-)\n'), the pattern ensures capturing a single line only // ('.*('..sett..'%s*=%s*.-)\n') would capture the next line as well if the target line doesn't include any value or space after '=' sign
	t[i] = t[i] and t[i]:match('%S+') -- remove any spaces if retrieved from the script
	end

desc_order, menu_open, list_offset = table.unpack(t, 2) -- skipping index 1 because preset list was processed separately above // nils don't prevent unpacking valid values
return preset_list and preset_list..'||' or '', desc_order,  menu_open, tonumber(list_offset) or 0 -- add traling separator character to preset_list to be able to capture last entry in gmatch loop

end



function Get_Filter_Current_State(take)
-- Event filter keeps the same settings across all item takes in multi-take item even though it has a dedicated attribute in each take chunk and different data can be applied to different takes while the Event filter is closed, but as soon as Event filter is opened, whatever settings are now active will be applied to ALL item takes; still for the sake of specificity here targeting current take

local ret, chunk = GetObjChunk(take)
	if ret == 'err_mess' then return end

local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- is_set false
return chunk:match(Esc(take_GUID)..'.-EVTFILTER (.-)\n'), chunk
end



function Store_or_Update_Preset(take, preset_t, scr_name, scr_path, filt_state, quick_save, menu_open, idx)
-- filt_state stems from Get_Filter_Current_State()
-- quick_save is boolean, if idx is valid preset is updated
-- Event filter keeps the same settings across all item takes in multi-take item even though it has a dedicated attribute in each take chunk and different data can be applied to different takes while the Event filter is closed, but as soon as Event filter is opened, whatever settings are now active will be applied to ALL item takes; still for the sake of specificity here targeting current take

	if not idx and #preset_t == 100 then
	Error_Tooltip('\n\n cannot store preset, \n\n     the limit of 100 \n\n    has been reached. \n\n', 1, 1) -- caps, spaced are true
		if menu_open then pause(2.3) end -- make the error message stick longer by preventing immediate menu reload which will obscure it
	return end

local name

	if not quick_save and not idx then
	local ret
	ret, name = r.GetUserInputs('STORE PRESET',1,'Type in name or submit blank,extrawidth=100','')
		if not ret then return end
	name = replace_pipe(name:match('^%s*(.+)%s*$') or 'Preset') -- trimming leading and trailing spaces // OR ('(%S.+)%s*$') // replacing pipe because it's incompatible with the menu and therefore is also used as stoted data separator
	elseif quick_save then
	name = 'Preset' -- generic
	end

	if idx then -- update
	name = preset_t[idx]:match('(.+|)')
	preset_t[idx] = name..filt_state
	end

local data = table.concat(preset_t, '||')..(idx and '' or (#preset_t > 0 and '||' or '')..name..'|'..filt_state) -- either updating or adding new preset appending it at the end of the list

r.SetExtState(scr_name, 'EVENT_FILTER_PRESETS', data, true) -- persist true
Update_or_Retrieve_from_Script(scr_path, 'EVENT_FILTER_PRESETS', data)

end



function Apply_Preset(take, preset_t, idx, chunk)
-- chunk stems from Get_Filter_Current_State();
-- Event filter keeps the same settings across all item takes in multi-take item even though it has a dedicated attribute in each take chunk and different data can be applied to different takes while the Event filter is closed, but as soon as Event filter is opened, whatever settings are now active will be applied to ALL item takes; still for the sake of specificity here targeting current take

local ret, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- is_set false
local cur_chunk = chunk:match('('..Esc(take_GUID)..'.-EVTFILTER .-)\n')
local upd_chunk = cur_chunk:match('.+EVTFILTER%s')..preset_t[idx]:match('|(.+)')
--local take_chunk_upd = take_chunk:gsub('EVTFILTER .-\n', 'EVTFILTER '..data..'\n')
cur_chunk = Esc(cur_chunk)
upd_chunk = upd_chunk:gsub('%%', '%%%%')
chunk = chunk:gsub(cur_chunk, upd_chunk)

SetObjChunk(take, chunk)

end




function Rename_Preset(preset_t, scr_name, scr_path, idx)

local preset = preset_t[idx]
local name, data = preset:match('(.+)|(.+)')
local ret, new_name = r.GetUserInputs('RENAME PRESET',1,'Type in name or submit blank,extrawidth=100',name == 'Preset' and '' or name)

	if not ret then return end

new_name = new_name:match('%S') and new_name:match('^%s*(.+)%s*$') or 'Preset' -- trimming leading and trailing spaces // OR ('(%S.+)%s*$')
preset_t[idx] = replace_pipe(new_name or 'Preset')..'|'..data -- replacing pipe because it's incompatible with the menu and therefore is also used as stoted data separator

local data = table.concat(preset_t, '||')
r.SetExtState(scr_name, 'EVENT_FILTER_PRESETS', data, true) -- persist true
Update_or_Retrieve_from_Script(scr_path, 'EVENT_FILTER_PRESETS', data)

end



function Delete_Preset_or_All(preset_t, scr_name, scr_path, menu_open, idx)
-- if idx is invalid all are deleted

	if #preset_t == 0 then
	Error_Tooltip('\n\n no presets to delete \n\n', 1,1) -- caps, spaced true
		if menu_open then pause(2) end -- make the error message stick longer by preventing immediate menu reload which will obscure it
	return end

local data

	if idx and #preset_t == 1 or not idx then -- one preset only, so no dialogue for specifying preset number is necessary
	local mess = not idx and 'All presets are' or 'The only preset is'
		if r.MB(mess..' going to be deleted.', 'WARNING', 1) == 2 then return end -- cancelled by the user
	data = ''
	else
	local name = preset_t[idx]:match('(.+)|')
	local idx = math.floor(idx) -- strip trailing decimal 0 from integer
		if r.MB('Wish to delete preset '..(name == 'Preset' and idx or '\n\n'..idx..'. '..name)..'?', 'WARNING', 1) == 2
		then return end
	table.remove(preset_t, idx)
	data = table.concat(preset_t, '||')
	end

r.SetExtState(scr_name, 'EVENT_FILTER_PRESETS', data, true) -- persist true
Update_or_Retrieve_from_Script(scr_path, 'EVENT_FILTER_PRESETS', data)

end



function Manage_Preset_List_Offset(preset_t, scr_name, scr_path, list_offset)
local sect = 'PRESET_LIST_OFFSET'
::RETRY::
local ret, output = r.GetUserInputs(sect:gsub('_',' '),1,'Type in integer or submit blank,extrawidth=100', list_offset)
local num = output:gsub(' ', '')
	if not ret then return
	elseif #num == 0 or tonumber(num) == 0 then
	list_offset = ''
	elseif not tonumber(num) then
	Error_Tooltip('\n\n invalid input \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
	goto RETRY
	else
	local int, frac = math.modf(num)
	local status = int == #preset_t and 'equals' or int > #preset_t and 'exceeds'
	local err = frac > 0 and 'decimals are not supported' or int >= #preset_t and '\t  the number '..status..' \n\n the number of stored presets'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
		goto RETRY
		end
	list_offset = num
	end
r.SetExtState(scr_name, sect, list_offset, true) -- persist true
Update_or_Retrieve_from_Script(scr_path, sect, list_offset)
end




function Reload_Menu_at_Same_Pos(menu, keep_open) -- still doesn't allow keeping the menu open after clicking away
-- local x, y = r.GetMousePosition()
--	if x+0 <= 100 then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and keep_open) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if keep_open is enabled the menu opens every time at the same spot
		if keep_open and not coord_t then -- keep_open is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not keep_open then
		coord_t = nil
		end
	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y
	return gfx.showmenu(menu) -- menu string
--	end
end



Error_Tooltip('') -- clear any lingering tooltips

local _, scr_path, scr_sect_ID, cmd_ID, _,_,_ = r.get_action_context()
-- in order to be able to run script from ouside of the MIDI Editor section of the Action list
-- there has to be valid active MIDI take in selected item
local ME = r.MIDIEditor_GetActive()
local sel_itm = r.GetSelectedMediaItem(0,0)
local take = ME and r.MIDIEditor_GetTake(ME) or sel_itm and r.GetActiveTake(sel_itm)

local scr_name = scr_path:match('([^\\/]+)%.%w+')

local update, rename, delete

::RELOAD::

local preset_list, desc_order, menu_open, list_offset = Load_Data(scr_name, scr_path)

local t = {}
	for preset in preset_list:gmatch('(.-)||') do
	t[#t+1] = preset
	end

local st, fin, dir = set_loop_direction(1, #t, desc_order)
local preset_menu, offset_cntr = '', 0
local filt_state, chunk = table.unpack(take and {Get_Filter_Current_State(take)} or {})

	for i=st,fin,dir do
	preset = t[i]
	offset_cntr = offset_cntr+1
		if list_offset == 0 or offset_cntr > list_offset then
		local name, data = preset:match('(.+)|(.+)')
		name = name == 'Preset' and name..' '..i or name -- i is generic preset number
		preset_menu = preset_menu..(#preset_menu == 0 and '' or '|')
		..check(filt_state == data)..add_leading_zeros(#t, i)..i..'. '..name -- i is preset number in the list
		end
	end


local underscore = '\204\178' -- Combining Low Line U+0332
local filter_open = r.GetToggleCommandStateEx(32060, 40762) == 1 -- Filter: Show/hide filter window...
list_offset = list_offset == 0 and '' or list_offset
local menu = '&S'..underscore..'tore|&Q'..underscore..'uick store|'
..check(update, rename or delete)..'&U'..underscore..'pdate [toggle]|'
..check(rename, update or delete)..'&R'..underscore..'ename [toggle]|'
..check(delete, update or rename)..'&D'..underscore..'elete [toggle]|'
..check(filter_open)..'&T'..underscore..'oggle Event filter open|'
..'>Other options:|'..check(desc_order)..'Display in descending &o'..underscore..'rder [toggle]|'
..check(menu_open)..'&K'..underscore..'eep menu open [toggle]|'
..'Offset &p'..underscore..'reset list by: '..list_offset..'|<Delete &a'..underscore..'ll||'

local output = Reload_Menu_at_Same_Pos(menu..preset_menu, 1) -- keep_open is true, independent from menu_open variable to ensure that when 'Keep menu open' option gets activated, the menu is reloaded at the initial coordinates rather than at the coordinates stemming from the option location within the menu

	if take and r.TakeIsMIDI(take) and not filt_state
	and (output < 3 or output > 10 and (update or not rename and not delete)) then
	-- chunk retrieval failed - store, update or apply error message
	Err_mess()
	output = 0
	end

local mult_items = r.CountSelectedMediaItems(0) > 1
-- the error messages pertain to storage, updating and applying operations
-- performed outside of the MIDI Editor
local err = cmd_ID ~= 32060 and not ME and (not sel_itm and 'no selected items'
or mult_items and 'a single selected \n\n  item is expected'
or (not take or not r.TakeIsMIDI(take)) and 'the active take is not midi')

	if output == 0 then return r.defer(no_undo)
	elseif output < 3 then -- store
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo)
		end
	Store_or_Update_Preset(take, t, scr_name, scr_path, filt_state, output == 2, menu_open) -- quick_save arg depends on the output value, idx is ommitted to trigger storage of a new preset
	elseif output < 6 then -- runtime boolean options, reset when script is terminated
	output = output-2 -- offset 3 first menu items
	local t = {update, rename, delete}
	t[output] = not t[output] -- toggle
	update, rename, delete = table.unpack(t, 1, 3) -- providing indices to accommodate nils
		if t[output] and not menu_open then --  since update, rename and delete options aren't persistent and only work while the script is running, once enabled, KEEP_MENU_OPEN option must be enabled as well, so that the script isn't terminated and one of those options keeps being active for further menu editing by the user
		r.SetExtState(scr_name, 'KEEP_MENU_OPEN', '1', true) -- persist true
		Update_or_Retrieve_from_Script(scr_path, 'KEEP_MENU_OPEN', '1')
		menu_open = 1
		end
	elseif output == 6 then
		if not ME then
		r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
		end
	r.MIDIEditor_LastFocused_OnCommand(40762, false) -- islistviewcommand // Filter: Show/hide filter window...
	elseif output < 9 then -- storable boolean options
	local t = {[7] = desc_order, [8] = menu_open}
	t[output] = not t[output] -- toggle
	local data = t[output] and '1' or ''
	local sect = {[7] = 'DESCENDING_ORDER', [8] = 'KEEP_MENU_OPEN'}
	r.SetExtState(scr_name, sect[output], data, true) -- persist true
	Update_or_Retrieve_from_Script(scr_path, sect[output], data)
	menu_open = output == 8 and t[output] or output ~= 8 and menu_open
	elseif output == 9 then
	Manage_Preset_List_Offset(t, scr_name, scr_path, list_offset)
	elseif output == 10 then
	Delete_Preset_or_All(t, scr_name, scr_path, menu_open) -- idx is ommitted, delete all
	else
	output = output-10 -- offset options
	list_offset = tonumber(list_offset) or 0
	local idx = desc_order and #t+1-output or output -- account for list arrangement in descending order
	idx = idx + list_offset * (desc_order and -1 or 1) -- account for preset list display offset
		if err and (update or not rename and not delete) then -- update or apply error message
		Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
		pause(2)
		elseif update then
		Store_or_Update_Preset(take, t, scr_name, scr_path, filt_state, quick_save, menu_open, idx)
		elseif rename then
		Rename_Preset(t, scr_name, scr_path, idx)
		elseif delete then
		Delete_Preset_or_All(t, scr_name, scr_path, menu_open, idx)
		else -- apply
		Apply_Preset(take, t, idx, chunk)
		end
	end

	if menu_open then goto RELOAD end

return r.defer(no_undo)




-- DATA BACKUP
--[[
EVENT_FILTER_PRESETS =
DESCENDING_ORDER =
KEEP_MENU_OPEN =
PRESET_LIST_OFFSET =
]]

