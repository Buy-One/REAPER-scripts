--[[
ReaScript name: BuyOne_Temporary FX presets.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962 but 6.31 is recommended for best performance
About:  The script allows storing presets temporarily for the purpose 
	of sound pallette exploration. Temporary presets are kept in the
	memory as long as REAPER runs unless they're explicitly deleted
	from the memory by the user.

	The number of plugins for which temporary presets can been stored
	and the number of presets per plugin are limited to 100 just out
	of consideration of practicality.
	
	Although 100 temporary presets can be stored for 1 of 100 plugins,
	temporary preset menu for each plugin is separate from the rest,
	meaning only presets of one specific plugin (the focused one) 
	are listed in the menu at a time.
	
	To be able to utilize the script the plugin must be placed into
	focus, i.e. its UI must be open with its window in focus.
	
	The menu will appear after the first temporary preset for a particular
	plugin has been stored or, if there're no presets in the memory, 
	as long as project dump data are available (see below).
	
	To view the list of all plugins for which temporary presets have
	been stored so far, run the script while all FX windows are closed 
	so that none is in focus.   
	To view the the list of plugins without closing FX windows, open
	a new project tab and run the script under it.
	
	The script can also be used to copy and paste settings between 
	plugin instances without saving them first as regular plugin
	presets.
	
	The script allows dumping temporary presets of a single plugin or 
	of all for which temporary presets have been stored, to the project 
	file, in case they're not saved as regular plugin presets and need 
	to be acessible in the next session. At some point after such dump 
	is made the project file must be saved so the data are embedded in it.
	On the next REAPER session these data are automatically loaded from
	such project file once on the first script run.
	
	The script also allows force loading presets per plugin or per all 
	plugins for which temporary presets have been stored in the session, 
	from project file dump, in which case all presets currently stored
	in the memory get overwritten per plugin or per all plugins respectively.
	
	Conversely, by using 'Delete all from project dump' option temporary 
	preset data can be cleared from the project file after they've been 
	dumped into it, per single plugin or per all plugins for which 
	temporary presets have been stored. To finalize the clean-up the 
	project file must be saved.
	
	CAVEATS
	
	The script only works well with plugins all controls of which are exposed
	to REAPER, i.e. automatable, which isn't always the case.
	It's sure to work well with REAPER stock plugins and with JSFX plugins.
	
	In REAPER builds older than 6.31 plugin names displayed in the FX browser
	cannot be retrieved via API, therefore if name of the focused plugin instance 
	differs from the plugin name in the FX browser, the name displayed in 
	the FX chain will feature in the menu and in the stored data which isn't 
	optimal in case its presets are to be applied to other instances named 
	differently in the FX chain.
	
]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
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


function GetMonFXProps() -- get mon fx accounting for floating window, GetFocusedFX() doesn't detect mon fx in builds prior to 6.20
	local master_tr = r.GetMasterTrack(0)
	local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
	local is_mon_fx_float = false -- only relevant if there's need to reopen the fx in floating window
		if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				src_mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return src_mon_fx_idx, is_mon_fx_float
end


function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20

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

local fx_name
	if take then
	fx_name = select(2, r.TakeFX_GetFXName(take, fx_num))
	elseif tr then
	fx_name = select(2, r.TrackFX_GetFXName(tr, fx_num))
	end

return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_name -- tr_num = -1 means Master;

end


function Load_Preset_List(tr, take, fx_idx, scr_name)

local first_run = r.GetExtState(scr_name, 'FIRST RUN') -- check if it's the first script run since REAPER start do condition loading data from project dump if exists
first_run = #first_run == 0

	if first_run then -- load from project buffer
	local ret, plugin_name_list = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_list, false) -- persist false
		for plugin_name in plugin_name_list:gmatch('[^:]+') do
			if plugin_name then -- load presets, deleting current
			local idx = 0
				for i=1,100 do
				local ret, preset = r.GetProjExtState(0, plugin_name, i)
					if ret == 1 then
					idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
					r.SetExtState(plugin_name, idx, preset, false) -- persist false
					end
				end
			end
		end
	-- store state so that in all subsequent runs the data is loaded from non-project buffer
	r.SetExtState(scr_name, 'FIRST RUN', '1', false) -- persist false
	end

-- Get fx name
local GetNamedConfigParm = take and r.TakeFX_GetNamedConfigParm or tr and r.TrackFX_GetNamedConfigParm
local GetFXName = take and r.TakeFX_GetFXName or tr and r.TrackFX_GetFXName
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.31 -- getting pre-aliased fx name with GetNamedConfigParm is only supported since buid 6.31
local obj = take or tr
local t, preset_menu, fx_name, _ = {}, ''

-- load focused fx presets
	if obj then
	retval, fx_name = table.unpack(old and {GetFXName(obj, fx_idx)} or {GetNamedConfigParm(obj, fx_idx, 'fx_name')})
	fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[')
	or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name == 'Video processor' and fx_name
		for i = 1, 100 do
		local preset = r.GetExtState(fx_name, i)
			if #preset > 0 then
			t[#t+1] = preset
			preset_menu = preset_menu..i..'. '..preset:match('(.+)::')..'|' -- extract preset names separating from the data
			end
		end
	end

local plugin_name_list = r.GetExtState(scr_name, 'PLUGIN NAME LIST')
local stored_plugin_names_t, cntr, plugin_name_idx = {}, 0
	for plugin_name in plugin_name_list:gmatch('[^:]+') do
		if plugin_name then
		stored_plugin_names_t[#stored_plugin_names_t+1] = plugin_name
		cntr = cntr+1
			if plugin_name == fx_name then plugin_name_idx = cntr end
		end
	end

return t, preset_menu, fx_name, stored_plugin_names_t, plugin_name_idx

end



function Re_Store_Plugin_Settings(tr, take, fx_idx, parm_list)
-- used inside Save_Preset() to store and as a standalone to apply
-- if applied to focused fx then fx_idx must be obtained from custom GetFocusedFX() function
local r = reaper
local obj = take or tr
local GetNumParams, GetParam, SetParam = table.unpack(tr and {r.TrackFX_GetNumParams, r.TrackFX_GetParam, r.TrackFX_SetParam} or take and {r.TakeFX_GetNumParams, r.TakeFX_GetParam, r.TakeFX_SetParam} or {nil})

	if not parm_list then -- store
	local t = {}
		for parm_idx = 0, GetNumParams(obj, fx_idx)-1 do
		local retval, minval, maxval = GetParam(obj, fx_idx, parm_idx)
		t[#t+1] = retval
		end
	-- setting ext state allows restoration on the second script run rather than within one run
	return t
	elseif parm_list ~= '' then -- restore
	local t = (function(parm_list)-- if restoring on second run in which case the t will be nil // function in place
					local t = {}
						for parm_val in parm_list:gmatch('[^;]+') do
						t[#t+1] = parm_val
						end
					return t
					end)(parm_list)

		for parm_idx = 0, GetNumParams(obj, fx_idx)-1 do
		SetParam(obj, fx_idx, parm_idx, t[parm_idx+1])
		end
	end

end


function Save_Preset(tr, take, fx_name, fx_idx, preset_t, scr_name, stored_plugin_names_t, quick_save) -- quick_save is boolean

local ret, output, preset_name

	if not quick_save then
	retval, output = r.GetUserInputs('SAVE TEMPORARY PRESET',1,'Type in preset name,extrawidth=100','')
	preset_name = output:gsub(' ', '')
	local ret, preset_dump = table.unpack(fx_name and {r.GetProjExtState(0,fx_name,1)} or {})
		if not retval or #preset_name == 0 then return #preset_t == 0 and ret == 0 end -- '#preset_t == 0 and ret == 0' cond ensures that if 'Keep menu open' is enabled and there're no presets or proj dump and hence no menu, the cancelled or empty dialogue isn't reloaded and that it is reloaded if there're no presets but there's proj dump
	end

local preset_name = not preset_name and 'preset'..#preset_t+1 or preset_name -- accounting for quick_save option

local err = #preset_t == 100 and '   preset number limit reached. \n\n\t\tto free up slots \n\n delete another temporary preset.'
or #stored_plugin_names_t == 100 and 'plugin number limit reached. \n\n\t   to free up slots \n\n delete all temporary presets\n\n\t   for some plugins.'

	if err then
	Error_Tooltip('\n\n '..err..'\n\n', 1,1) -- caps, spaced are true
	return true end

local preset_parm_t = Re_Store_Plugin_Settings(tr, take, fx_idx) -- parm_list is nil, store

local plugin_name_lst = #stored_plugin_names_t > 0 and #preset_t == 0 and
table.concat(stored_plugin_names_t, '::')..'::'..fx_name -- append fx_name to the list if it's the first preset to have been stored
or #stored_plugin_names_t == 0 and fx_name -- add a single name if no previously stored presets at all

	if plugin_name_lst then -- only update if new plugin name has to be added
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_lst, false) -- persist false
	end

-- add the saved preset at the last index
r.SetExtState(fx_name, #preset_t+1, preset_name..'::'..table.concat(preset_parm_t, ';'), false) -- persist false

end



function Rename_Preset(preset_t, fx_name)

local ret, output = r.GetUserInputs('DELETE TEMPORARY PRESET',2,'Type in preset number,Type in new preset name,extrawidth=100','')
local output = output:gsub(' ', '')
	if not ret or #output == ',' then return end

local preset_idx = output:match('(.-),')
local preset_new_name = output:match(',(.+)')

preset_idx = tonumber(preset_idx)
preset_new_name = preset_new_name and preset_new_name:match('%s*(.+)%s*')
local err = not preset_idx and 'the input is not a number'
or preset_idx ~= math.floor(preset_idx) and 'the input is not an integer'
or (preset_idx < 1 or preset_idx > #preset_t) and 'the number is out of range'
or (not preset_new_name or #preset_new_name:gsub(' ','') == 0) and 'new preset name is empty'
	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return true end

-- split preset data
local preset_name, preset_data = preset_t[preset_idx]:match('(.+)::(.+)')
preset_t[preset_idx] = preset_new_name..'::'..preset_data

r.SetExtState(fx_name, preset_idx, preset_t[preset_idx], false) -- persist false

end


function Delete_Preset(preset_t, fx_name, stored_plugin_names_t, scr_name)

	if #preset_t == 1 then -- one preset only, so no dialogue for specifying preset number is necessary
	local resp = r.MB('The only reset is going to be deleted.', 'WARNING', 1)
		if resp == 2 then return end -- cancelled by the user
	r.DeleteExtState(fx_name, 1, true) -- persist true
	-- remove plugin name from extended state if all its presets have been deleted
		for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
			if plugin_name == fx_name then
			table.remove(stored_plugin_names_t, name_idx)
			break end
		end
	-- resave updated plugin names list
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false
	local ret = r.GetProjExtState(0, fx_name, 1)
	return ret == 0 end -- to prevent triggering 'Save preset' dialogue if no presets and proj dump data left while if 'Keep menu open' sett is enabled


local ret, output = r.GetUserInputs('DELETE TEMPORARY PRESET',1,'Type in preset number,extrawidth=100','')
local preset_idx = output:gsub(' ', '')
	if not ret or #preset_idx == 0 then return end

preset_idx = tonumber(preset_idx)
local err = not preset_idx and 'the input is not a number'
or preset_idx ~= math.floor(preset_idx) and 'the input is not an integer'
or (preset_idx < 1 or preset_idx > #preset_t) and 'the number is out of range'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced are true
	return true end

	-- delete all, because after deletion of one indices order becomes disrupted
	for idx in ipairs(preset_t) do
	r.DeleteExtState(fx_name, idx, true) -- persist true
	end

table.remove(preset_t, preset_idx)

-- resave with new indices
	for idx, preset_props in ipairs(preset_t) do
	r.SetExtState(fx_name, idx, preset_props, false) -- persist false
	end

	if #preset_t == 0 then -- remove plugin name from extended state if all its presets have been deleted
		for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
			if plugin_name == fx_name then
			table.remove(stored_plugin_names_t, name_idx)
		--	r.DeleteExtState(fx_name, name_idx, true) -- persist true
			break end
		end
	-- resave updated plugin names list
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false
	end

end


function Delete_All_For_Current_Plugin(preset_t, fx_name, stored_plugin_names_t, scr_name)

local resp = r.MB('    All temporary presets which have been saved so far \n\n   for the focused FX are going to be irreversibly deleted!', 'WARNING',1)
	if resp == 2 then return end -- cancelled by the user

	for idx in ipairs(preset_t) do
	r.DeleteExtState(fx_name, idx, true) -- persist true
	end

	-- remove plugin name from extended state if all its presets have been deleted
	for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
		if plugin_name == fx_name then
		table.remove(stored_plugin_names_t, name_idx)
		break end
	end
-- resave updated plugin names list
r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false

local ret = r.GetProjExtState(0, fx_name, 1)

return ret == 0 -- to prevent triggering 'Save preset' dialogue if no presets and proj dump data left while if 'Keep menu open' sett is enabled

end


function Delete_All(preset_t, stored_plugin_names_t, scr_name)

local resp = r.MB('   All temporary presets which have been saved so far \n\n\tare going to be irreversibly deleted!', 'WARNING',1)
	if resp == 2 then return end -- cancelled by the user

r.DeleteExtState(scr_name, 'PLUGIN NAME LIST', true) -- persist true
	for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
		for i=1,100 do
		r.DeleteExtState(plugin_name, i, true) -- persist true
		end
	end

local ret = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')

return ret == 0 -- will prevent re-loading of the menu after deletion of all presets if no proj dump and 'Keep menu open' sett is enabled

end


function Dump_To_Project_File(fx_name, scr_name, preset_t, stored_plugin_names_t)

	if fx_name then -- only dump focused plugin presets
	-- first delete any previously stored ones, because if current preset list is shorter than the one stored previously there'll be remaining presets in the proj. ext state assigned to greater indices
	r.SetProjExtState(0, fx_name, '', '') -- key and value are empty strings to delete them
		-- dump
		for idx, preset in ipairs(preset_t) do
		r.SetProjExtState(0, fx_name, idx, preset) -- preset data contains preset name
		cntr = idx
		end
	else -- dump all
	r.SetProjExtState(0,scr_name,'PLUGIN NAME LIST',table.concat(stored_plugin_names_t,'::')) -- dump plugin names list
		for _, plugin_name in ipairs(stored_plugin_names_t) do -- dump presets
		-- first delete any previously stored ones, because if current preset list is shorter than the one stored previously there'll be remaining presets in the proj. ext state assigned to greater indices
		r.SetProjExtState(0, plugin_name, '', '') -- key and value are empty strings to delete them
			for i=1, 100 do
			local preset = r.GetExtState(plugin_name, i)
				if #preset > 0 then
				r.SetProjExtState(0, plugin_name, i, preset) -- preset data contains preset name
				end
			end
		end
	end

Error_Tooltip('\n\n\t\t   d o n e ! \n\n make sure to save the project \n\n', 1,1) -- caps, spaced are true

return true	-- to prevent re-loading of the menu if 'Keep menu open' sett is enabled so that the tooltip isn't overriden by it

end


function Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)

local mess = fx_name and '      All temporary presets which have been saved so far \n\n for the focused FX are going to be irreversibly overwtitten!' or '   All temporary presets which have been saved so far \n\n'..(' '):rep(13)..'are going to be irreversibly overwtitten!'
local resp = r.MB(mess, 'WARNING',1)
	if resp == 2 then return end -- canlcelled by the user

	local function delete_current(fx_name)
		for i=1,100 do
		r.DeleteExtState(fx_name,i, true) -- persist true
		end
	end

	if fx_name then
	local ret, preset = r.GetProjExtState(0, fx_name, 1)
		if ret == 0 then
		Error_Tooltip('\n\n no dump found to load from \n\n', 1,1) -- caps, spaced are true
		return true
		end
	-- if found, first delete all currently in the RAM
	delete_current(fx_name)
	-- load
	local idx = 0
		for i=1,100 do
		local ret, preset = r.GetProjExtState(0, fx_name, i)
			if ret == 1 then
			idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
			r.SetExtState(fx_name,idx,preset,false) -- persist false
			end
		end

	else

	local ret, plugin_name_list = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')
		if ret == 0 then
		Error_Tooltip('\n\n no dump found to load from \n\n', 1,1) -- caps, spaced are true
		return true
		end
	-- if found, first delete all currently in the RAM
		for _, plugin_name in ipairs(stored_plugin_names_t) do
		delete_current(plugin_name)
		end
	-- load
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_list, false) -- replace current, persist false
		for plugin_name in plugin_name_list:gmatch('[^:]+') do
			if plugin_name then -- load presets, deleting current
			delete_current(plugin_name)
			local idx = 0
				for i=1,100 do
				local ret, preset = r.GetProjExtState(0, plugin_name, i)
					if ret == 1 then
					idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
					r.SetExtState(plugin_name, idx, preset, false) -- persist false
					end
				end
			end
		end

	end

end


function Delete_Proj_Dump(scr_name, fx_name)

-- extract names
local ret, plugin_names_dump = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')
local names_t = {}
	for plugin_name in plugin_names_dump:gmatch('[^:]+') do
		if plugin_name then
		names_t[#names_t+1] = plugin_name
		end
	end

	if fx_name then
	r.SetProjExtState(0, fx_name, '', '') -- key and value are empty strings to delete them
		for idx, plugin_name in ipairs(names_t) do
			if plugin_name == fx_name then table.remove(names_t, idx) break end
		end
	-- resave updated plugin names list
	r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST', table.concat(names_t,'::'))
	else
	-- delete presets
		for idx, plugin_name in ipairs(names_t) do
		r.SetProjExtState(0, plugin_name, '', '') -- key and value are empty strings to delete them
		end
	r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST', '') -- delete plugin names list
	return #r.GetExtState(scr_name, 'PLUGIN NAME LIST') == 0 -- to prevent re-loading of the menu if no stored data left while 'Keep menu open' sett is enabled
	end

end


function Toggle_Keep_Menu_Open(scr_name, keep_open)

local toggle = keep_open and '0' or '1'
r.SetProjExtState(0, scr_name, 'KEEP MENU OPEN', toggle)
return toggle == '1'

end


function Reload_Menu_at_Same_Pos(menu, OPTION) -- still doesn't allow keeping the menu open after clicking away
-- local x, y = r.GetMousePosition()
--	if x+0 <= 100 then -- 100 px within the screen left edge
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	local init = old and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if OPTION is enabled the menu opens every time at the same spot
		if OPTION and not coord_t then -- OPTION is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not OPTION then
		coord_t = nil
		end
	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y
	return gfx.showmenu(menu) -- menu string
--	end
end


::RELOAD::

local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias = GetFocusedFX()

local _, scr_name, scr_sect_ID, cmd_ID, _,_,_ = r.get_action_context()
scr_name = scr_name:match('([^\\/]+)%.%w+')

local preset_t, preset_menu, fx_name, stored_plugin_names_t, plugin_name_idx = Load_Preset_List(tr, take, fx_num, scr_name)

local ret, plugin_names_lst_dump = r.GetProjExtState(0,scr_name,'PLUGIN NAME LIST')

	if not fx_name then
		if #stored_plugin_names_t == 0  and ret == 0 then -- allows loading the menu with the names list if proj data is stored
		Error_Tooltip('\n\n no focused fx \n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo) end
	end

local ret, keep_open = r.GetProjExtState(0, scr_name, 'KEEP MENU OPEN')
keep_open = keep_open == '1'

local ret, preset_dump = table.unpack(fx_name and {r.GetProjExtState(0,fx_name,1)} or {}) -- the return values are only used as conditions

	if #preset_t == 0 and fx_name then
		if ret == 0 then -- allows loading the menu without presets when proj dump is stored to be able to load from the dump
		local err = Save_Preset(tr, take, fx_name, fx_num, preset_t, scr_name, stored_plugin_names_t)
			if keep_open and not err then goto RELOAD end -- if dialogue is cancelled err will be true to prevent re-loading
		return r.defer(no_undo) end
	end

	if fx_name then -- or
	local checkbox = keep_open and '[+]' or '[  ]'
	local greyout1 = #preset_menu == 0 and '#' or '' -- to grayout irrelevant menu items when only proj dump is available
	local greyout2 = #preset_dump == 0 and '#' or '' -- to grayout irrelevant menu items when proj dump is unavailable
	preset_menu = fx_name..':|'..preset_menu --(#preset_menu > 0 and fx_name..':|' or '')..preset_menu
	menu = 'Store preset|Quick store preset|'..greyout1..'Rename preset|'..greyout1..'Delete preset|>Other options|'..greyout1..'Delete all for current FX|'..greyout1..'Dump all to project file|'..greyout2..'Force load all from project dump|'..greyout2..'Delete all from project dump|<Keep menu open '..checkbox..'|'..(#preset_menu > 0 and '||' or '')..preset_menu
	else
	local greyout1 = #stored_plugin_names_t == 0 and '#' or '' -- to grayout irrelevant menu items when only proj dump is available
	local greyout2 = #plugin_names_lst_dump == 0 and '#' or ''  -- to grayout irrelevant menu items when proj dump is unavailable
	local sep = #stored_plugin_names_t > 0 and '|||' or ''
	menu = greyout1..'Delete all|'..greyout1..'Dump all to the project file|'..greyout2..'Force load all from project dump|'..greyout2..'Delete all from project dump'..sep..table.concat(stored_plugin_names_t,'|')
	end

	if fx_name then
	local output = Reload_Menu_at_Same_Pos(menu, keep_open)
		if output > 0 and output < 3 then
		local quick_save = output == 2
		err = Save_Preset(tr, take, fx_name, fx_num, preset_t, scr_name, stored_plugin_names_t, quick_save)
		elseif output == 3 then
		err = Rename_Preset(preset_t, fx_name)
		elseif output == 4 then
		err = Delete_Preset(preset_t, fx_name, stored_plugin_names_t, scr_name)
		elseif output == 5 then
		err = Delete_All_For_Current_Plugin(preset_t, fx_name, stored_plugin_names_t, scr_name)
		elseif output == 6 then
		Dump_To_Project_File(fx_name, scr_name, preset_t)
		elseif output == 7 then
		err = Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)
		elseif output == 8 then
		Delete_Proj_Dump(scr_name, fx_name)
		err = #preset_t == 0 -- prevents menu re-loading if no presets and not project dump
		elseif output == 9 then
		keep_open = Toggle_Keep_Menu_Open(scr_name, keep_open) -- will prevent reload after toggling to Off
		elseif output > 10 then -- accounting for plugin name menu item
		output = output-10 -- offset to be able to access table fields 
		local parm_list = preset_t[output]:match('::(.+)') -- excluding preset name	
		Re_Store_Plugin_Settings(tr, take, fx_num, parm_list) -- Apply
		end
		
		if output > 0 and keep_open and not err then goto RELOAD end -- only reload when error isn't generayed otherwise it's not visible because the menu window overrides the tooltip
	else
	
	local output = Reload_Menu_at_Same_Pos(menu)
		if output == 1 then
		err = Delete_All(preset_t, stored_plugin_names_t, scr_name)
		elseif output == 2 then
		Dump_To_Project_File(fx_name, scr_name, preset_t, stored_plugin_names_t)
		elseif output == 3 then
		err = Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)
		elseif output == 4 then
		err = Delete_Proj_Dump(scr_name, fx_name)
		end
		
		if (output == 1 or output > 2) and keep_open and not err then goto RELOAD end
		
	end

do return r.defer(no_undo) end






