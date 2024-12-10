--[[
ReaScript name: BuyOne_Temporary FX presets.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 	#Improved backward compatibility with v1.0
	   1.1 	#Fixed typo in the only preset deletion warning message  
		#Fixed user preset name format to allow multi-word names (with spaces)  
		#Fixed the title of preset rename dialogue  
		#Fixed 'Keep menu open' option so that the menu is sure to reload
		at exactly the same position regardless of the last clicked item  
		#Fixed menu loading at the very start of the session when there's 
		no focsed FX and there're preset data stored in the project file  
		#Fixed menu reloading when 'Keep menu open' is enabled and there's
		no focused FX  
		#Added support for FX inside containers
		#Added option to apply the last stored preset  
		#Added option to display presets in the menu in descending order  
		#Added option to offset the displayed preset list
		#Added per FX nested options menu to the FX list dsplayed when no FX is in focus  
		#Added error message if preset name only consists of empty spaces	 
		#Added support for quick preset storage via the preset store dialogue  
		#Added menu quick access shortcuts to be triggered by input from keyboard
		#Enabled reloading of preset Save, Rename, Delete dialogues if user input is invalid
		#Changed data storage format to minimize likelihood of clash with data stored by other scripts 
		#Made sure the preset data dumped to the project file can be successfully saved into 
		it right after the dumping  
		#Improved clarity of focused FX option names  
		#Updated quick preset name format having separated the number from 'preset'  
		#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962 but 6.31 is recommended for best performance
About:  IF AFTER RUNNING THIS VERSION OF THE SCRIPT YOU HAPPEN TO 
	DISCOVER LOST PRESETS YOU'D SAVED WITH THE PROJECT FILE USING v1.0, 
	PLEASE CONTACT ME AND WE WILL TRY TO SORT IT OUT.

	The script allows storing presets temporarily for the purpose 
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
	Options in this menu allow batch managing all presets of all FX 
	which have been stored so far.  
	By clicking on FX names in the menu, individual FX options nested 
	menu can be accessed. The options in this menu are identical to those 
	available under 'Other options' submenu of the focused FX menu,
	but in this case their accessibility doesn't depend on the FX being 
	in focus. To exit such individual FX options nested menu click
	on the FX name at the top.
	
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
	
	Different presets can have identical names, but they will differ by
	their ordinal number. Presets cannot be overwritten, only deleted.
	
	The setting 'Offset preset list by:' doesn't apply to FX preset lists
	the number of presets in which is smaller than or equal to the set value.
	
	Menu items which end with a letter inside square brackets, e.g. [ s ]
	can be triggered from keyboard by pressing the corresponding key while
	the menu is open.  
	
	Container presets are not supported, only presets of FX inside container.
	
	
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



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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

	local fx_name
		if take then
		fx_name = select(2, r.TakeFX_GetFXName(take, fx_num))
		elseif tr then
		fx_name = select(2, r.TrackFX_GetFXName(tr, fx_num))
		end

	return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_name -- tr_num = -1 means Master;

	else

	-- supported since v7.0
	local retval, tr_num, itm_num, take_num, fx_num, parm_num = reaper.GetTouchedOrFocusedFX(1) -- 1 last touched mode // parm_num only relevant for querying last touched (mode 0) // supports Monitoring FX and FX inside containers, container itself can also be focused
	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = r.GetMediaItem(0, itm_num)
	local take = item and r.GetTake(0, take_num)
	local fx_name, is_cont

		if take then
		fx_name = select(2, r.TakeFX_GetFXName(take, fx_num))
		is_cont = r.TakeFX_GetIOSize(take, fx_num) == 8
		elseif tr then
		fx_name = select(2, r.TrackFX_GetFXName(tr, fx_num))
		is_cont = r.TrackFX_GetIOSize(tr, fx_num) == 8
		end

		if is_cont then return end -- container presets aren't supported

	local input_fx, cont_fx = tr and r.TrackFX_GetRecChainVisible(tr) ~= -1, fx_num >= 33554432 -- or fx_num >= 0x2000000 // fx_num >= 0x1000000 or fx_num >= 16777216 for input_fx gives false positives if fx is inside a container in main fx chain hence chain visibility evaluatiion
	local mon_fx = retval and tr_num == -1 and input_fx

	return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_name, input_fx, cont_fx, is_cont -- tr_num = -1 means Master

	end

end


function Load_Preset_List(tr, take, fx_idx, scr_name, desc_order, list_offset)

local first_run = r.GetExtState(scr_name, 'FIRST RUN') -- check if it's the first script run since REAPER start to condition loading data from project dump if exists
first_run = #first_run == 0

	if first_run then -- load from project buffer
	local ret, plugin_name_list = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_list, false) -- persist false
		for plugin_name in plugin_name_list:gmatch('[^:]+') do
			if plugin_name then -- load presets, deleting current
			local idx = 0
				for i=1,100 do
				local ret, preset = r.GetProjExtState(0, scr_name..'::'..plugin_name, i)
					if ret == 0 then
					-- check whether the data was stored with v1.0 of the script where section name didn't include script name
					ret, preset = r.GetProjExtState(0, plugin_name, i)
						if ret == 1 then
						r.SetProjExtState(0, plugin_name, i, '') -- delete in old format
						r.SetProjExtState(0, scr_name..'::'..plugin_name, i, preset) -- store in new format
						r.MarkProjectDirty(0) -- so that the updated data can be saved with project file right away
						end
					end
					if ret == 1 then
					idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
					r.SetExtState(scr_name..'::'..plugin_name, idx, preset, false) -- persist false
					end
				end
			end
		end
	-- store state so that in all subsequent runs the data is loaded from non-project buffer
	r.SetExtState(scr_name, 'FIRST RUN', '1', false) -- persist false
	end

	local function convert_to_new_format(fx_name, i, scr_name)
	-- meant to address presets stored in the project file with v1.0 of the script
	-- where storage format was different, the section name didn't include the script name
	-- which may not be loaded within the 'first_run' block above because
	-- in v1.0 full plugin list would only be stored if the dump option was applied
	-- in batch mode, when no fx is in focus, rather than individually per plugin
	local ret, preset = r.GetProjExtState(0, fx_name, i)
		if ret == 1 then
		r.SetProjExtState(0, fx_name, i, '') -- delete in old format
		r.SetProjExtState(0, scr_name..'::'..fx_name, i, preset) -- store in new format
		r.MarkProjectDirty(0) -- so that the updated data can be saved with project file right away
		r.SetExtState(scr_name..'::'..fx_name, i, preset, false) -- persist false // store in RAM

		local plugin_name_lst = r.GetExtState(scr_name, 'PLUGIN NAME LIST')
		plugin_name_lst = #plugin_name_lst > 0 and not plugin_name_lst:match(Esc(fx_name))
		and plugin_name_lst..'::'..fx_name -- append fx_name to the list
		or #plugin_name_lst == 0 and fx_name -- add the first name if no previously stored presets at all
			if plugin_name_lst then
			r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_lst, false) -- persist false
			end
		end
	return preset
	end

-- Get fx name
local GetNamedConfigParm, GetFXName, GetIOSize = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFXName, r.TakeFX_GetIOSize} or tr and {r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFXName, r.TrackFX_GetIOSize} or {})
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.31 -- getting pre-aliased fx name with GetNamedConfigParm is only supported since buid 6.31
local obj = take or tr
local t, preset_menu, fx_name, retval = {}, ''

-- load focused fx presets
	if obj then
	retval, fx_name = table.unpack(old and {GetFXName(obj, fx_idx)} or {GetNamedConfigParm(obj, fx_idx, 'fx_name')})
	fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[')
	or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
	local st, fin, dir = table.unpack(desc_order and {100,1,-1} or {1,100,1})
		for i = st, fin, dir do
		local preset = r.GetExtState(scr_name..'::'..fx_name, i)
			if #preset == 0 and (first_run or not select(2, r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')):match(Esc(fx_name)) ) then -- in v1.0 of the script plugin name list wasn't updated in the project dump when presets were stored per plugin therefore it's likely that on first script run in the session only some selected plugin presets would load from project ext state, so for backward compatibility extract plugin data by plugin name, this will only target v1.0 stored data because after running convert_to_new_format() function below the script plugin name list will be updated in the project dump and for such plugins GetProjExtState() evaluation will be false on the next run which will prevent auto-reloading of presets from updated project dump if all have been deleted from regular extended state
			preset = convert_to_new_format(fx_name, i, scr_name)
			end
			if #preset > 0 then
			t[i] = preset -- ensures that presets are loaded and stored in ascending order regardless of desc_order setting which is only meant to affect their display order
			preset_menu = preset_menu..i..'. '..preset:match('(.+)::')..'|' -- extract preset names separating from the data
			end
		end
	end


local list_offset = tonumber(list_offset)
	if list_offset and list_offset > 0 and list_offset < #t then -- prevending offset if the list is shorter than or equal to the value
	local i = 0
	preset_menu = preset_menu:gsub('.-|', function(c) i = i+1 if i <= list_offset then return '' end end)
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

return t, preset_menu, fx_name, stored_plugin_names_t, plugin_name_idx -- plugin_name_idx isn't used anywhere in the script
end



function Get_Presets_By_FX_Name(scr_name, fx_name)
local t = {}
	for i = 1, 100 do
	local preset = r.GetExtState(scr_name..'::'..fx_name, i)
		if #preset > 0 then
		t[i] = preset
		end
	end
return t
end


function Re_Store_Plugin_Settings(tr, take, fx_idx, parm_list)
-- used inside Save_Preset() to store and as a standalone to apply
-- if applied to focused fx then fx_idx must be obtained from custom GetFocusedFX() function
-- parm_list comes from preset_t which in turn comes from Load_Preset_List()
local r = reaper
local obj = take or tr
local GetNumParams, GetParam, SetParam = table.unpack(tr and {r.TrackFX_GetNumParams, r.TrackFX_GetParam, r.TrackFX_SetParam} or take and {r.TakeFX_GetNumParams, r.TakeFX_GetParam, r.TakeFX_SetParam} or {nil})

	if not parm_list then -- store
	local t = {}
		for parm_idx = 0, GetNumParams(obj, fx_idx)-1 do
		local retval, minval, maxval = GetParam(obj, fx_idx, parm_idx)
		t[#t+1] = retval
		end
	return t
	elseif parm_list ~= '' then -- restore, i.e. apply
	local t = (function(parm_list) -- if restoring on second run in which case the t will be nil // function in place
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

local retval, output, ret, preset_name

	if not quick_save then
	::RETRY::
	retval, output = r.GetUserInputs('STORE TEMPORARY PRESET',1,'Type in name or submit blank,extrawidth=100','')
	preset_name = output:match('^%s*(.+)%s*$') -- trimming leading and trailing spaces // output:gsub(' ', '')
	local ret, preset_dump = table.unpack(fx_name and {r.GetProjExtState(0, scr_name..'::'..fx_name, 1)} or {})
		if not retval then return #preset_t == 0 and ret == 0 -- '#preset_t == 0 and ret == 0' cond ensures that if 'Keep menu open' is enabled and there're no presets or proj dump and hence no menu, the cancelled or empty dialogue isn't reloaded and that it is reloaded if there're no presets but there's proj dump
		elseif #output > 0 and #output:gsub(' ', '') == 0 then
		Error_Tooltip('\n\n preset name cannot only \n\n consist of empty spaces \n\n', 1,1,150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
		goto RETRY
		end
	end

local preset_name = not preset_name and 'preset '..#preset_t+1 or preset_name -- accounting for quick_save option

local err = #preset_t == 100 and '   preset number limit reached. \n\n\t\tto free up slots \n\n delete another temporary preset.'
or #stored_plugin_names_t == 100 and 'plugin number limit reached. \n\n\t   to free up slots \n\n delete all temporary presets\n\n\t   for some plugins.'

	if err then
	Error_Tooltip('\n\n '..err..'\n\n', 1,1) -- caps, spaced are true
	return true end

local preset_parm_t = Re_Store_Plugin_Settings(tr, take, fx_idx) -- parm_list arg is nil, store

local plugin_name_lst = #stored_plugin_names_t > 0 and #preset_t == 0 and
table.concat(stored_plugin_names_t, '::')..'::'..fx_name -- append fx_name to the list if it's the first preset to have been stored
or #stored_plugin_names_t == 0 and fx_name -- add a single name if no previously stored presets at all

	if plugin_name_lst then -- only update if new plugin name has to be added
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', plugin_name_lst, false) -- persist false
	end

-- add the saved preset at the last index
r.SetExtState(scr_name..'::'..fx_name, #preset_t+1, preset_name..'::'..table.concat(preset_parm_t, ';'), false) -- persist false

end



function Rename_Preset(preset_t, fx_name, scr_name)

::RETRY::
local ret, output = r.GetUserInputs('RENAME TEMPORARY PRESET',2,'Type in preset number,Type in preset new name,extrawidth=100','')
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
	Error_Tooltip('\n\n '..err..' \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
	goto RETRY
	end

-- split preset data
local preset_name, preset_data = preset_t[preset_idx]:match('(.+)::(.+)')
preset_t[preset_idx] = preset_new_name..'::'..preset_data

r.SetExtState(scr_name..'::'..fx_name, preset_idx, preset_t[preset_idx], false) -- persist false

end


function Delete_Preset(preset_t, fx_name, stored_plugin_names_t, scr_name)

	if #preset_t == 1 then -- one preset only, so no dialogue for specifying preset number is necessary
	local resp = r.MB('The only preset is going to be deleted.', 'WARNING', 1)
		if resp == 2 then return end -- cancelled by the user
	r.DeleteExtState(scr_name..'::'..fx_name, 1, true) -- persist true
	-- remove plugin name from extended state if all its presets have been deleted
		for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
			if plugin_name == fx_name then
			table.remove(stored_plugin_names_t, name_idx)
			break end
		end
	-- resave updated plugin names list
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false
	--[[ OR
	local ret, stored_plugin_names = r.GetExtState(scr_name, 'PLUGIN NAME LIST')
		if stored_plugin_names:match(Esc(fx_name)) then
		stored_plugin_names = stored_plugin_names:gsub('[^:]+', function(c) if c == fx_name then return '' end end)
		r.SetExtState(scr_name, 'PLUGIN NAME LIST', stored_plugin_names, false) -- persist false
		end
	]]
	local ret = r.GetProjExtState(0, scr_name..'::'..fx_name, 1)
	return ret == 0 end -- to prevent triggering 'Save preset' dialogue if no presets and proj dump data left while if 'Keep menu open' sett is enabled

::RETRY::
local ret, output = r.GetUserInputs('DELETE TEMPORARY PRESET',1,'Type in preset number,extrawidth=100','')
local preset_idx = output:gsub(' ', '')
	if not ret or #preset_idx == 0 then return end

preset_idx = tonumber(preset_idx)
local err = not preset_idx and 'the input is not a number'
or preset_idx ~= math.floor(preset_idx) and 'the input is not an integer'
or (preset_idx < 1 or preset_idx > #preset_t) and 'the number is out of range'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
	goto RETRY
	end

	-- delete all, because after deletion of one indices order becomes disrupted
	for idx in ipairs(preset_t) do
	r.DeleteExtState(scr_name..'::'..fx_name, idx, true) -- persist true
	end

table.remove(preset_t, preset_idx)

-- resave with new indices
	for idx, preset_props in ipairs(preset_t) do
	r.SetExtState(scr_name..'::'..fx_name, idx, preset_props, false) -- persist false
	end

	if #preset_t == 0 then -- remove plugin name from extended state if all its presets have been deleted
		for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
			if plugin_name == fx_name then
			table.remove(stored_plugin_names_t, name_idx)
			break end
		end
	-- resave updated plugin names list
	r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false
	--[[ OR
	local ret, stored_plugin_names = r.GetExtState(scr_name, 'PLUGIN NAME LIST')
		if stored_plugin_names:match(Esc(fx_name)) then
		stored_plugin_names = stored_plugin_names:gsub('[^:]+', function(c) if c == fx_name then return '' end end)
		r.SetExtState(scr_name, 'PLUGIN NAME LIST', stored_plugin_names, false) -- persist false
		end
	]]
	end

end


function Delete_All_For_Current_Plugin(preset_t, fx_name, stored_plugin_names_t, scr_name)

local resp = r.MB('    All temporary presets which have been saved so far \n\n   for the focused FX are going to be irreversibly deleted!', 'WARNING',1)
	if resp == 2 then return end -- cancelled by the user

	for idx in ipairs(preset_t) do
	r.DeleteExtState(scr_name..'::'..fx_name, idx, true) -- persist true
	end

	-- remove plugin name from extended state if all its presets have been deleted
	for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
		if plugin_name == fx_name then
		table.remove(stored_plugin_names_t, name_idx)
		break end
	end
-- resave updated plugin names list
r.SetExtState(scr_name, 'PLUGIN NAME LIST', table.concat(stored_plugin_names_t,'::'), false) -- persist false

local ret = r.GetProjExtState(0, scr_name..'::'..fx_name, 1)

return ret == 0 -- to prevent triggering 'Save preset' dialogue if no presets and proj dump data left while if 'Keep menu open' sett is enabled

end


function Delete_All(preset_t, stored_plugin_names_t, scr_name)

local resp = r.MB('   All temporary presets which have been saved so far \n\n\tare going to be irreversibly deleted!', 'WARNING',1)
	if resp == 2 then return end -- cancelled by the user

r.DeleteExtState(scr_name, 'PLUGIN NAME LIST', true) -- persist true
	for name_idx, plugin_name in ipairs(stored_plugin_names_t) do
		for i=1,100 do
		r.DeleteExtState(scr_name..'::'..plugin_name, i, true) -- persist true
		end
	end

local ret = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')

return ret == 0 -- will prevent re-loading of the menu after deletion of all presets if no proj dump and 'Keep menu open' sett is enabled

end


function Dump_To_Project_File(fx_name, scr_name, preset_t, stored_plugin_names_t)

	if fx_name then -- only dump focused plugin presets
	-- first delete any previously stored ones, because if current preset list is shorter than the one stored previously there'll be remaining presets in the proj. ext state assigned to greater indices
	r.SetProjExtState(0, scr_name..'::'..fx_name, '', '') -- key and value are empty strings to delete them
		-- dump
		for idx, preset in ipairs(preset_t) do
		r.SetProjExtState(0, scr_name..'::'..fx_name, idx, preset) -- preset data contains preset name
		end
	-- update plugin name list
	local ret, stored_plugin_names = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST')
	stored_plugin_names = ret == 1 and not stored_plugin_names:match(Esc(fx_name)) and stored_plugin_names..'::'..fx_name
	or ret == 0 and fx_name
		if stored_plugin_names then
		r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST', stored_plugin_names)
		end
	else -- dump all
	r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST',table.concat(stored_plugin_names_t,'::')) -- dump plugin names list
		for _, plugin_name in ipairs(stored_plugin_names_t) do -- dump presets
		-- first delete any previously stored ones, because if current preset list is shorter than the one stored previously there'll be remaining presets in the proj. ext state assigned to greater indices
		r.SetProjExtState(0, scr_name..'::'..plugin_name, '', '') -- key and value are empty strings to delete them
			for i=1, 100 do
			local preset = r.GetExtState(scr_name..'::'..plugin_name, i)
				if #preset > 0 then
				r.SetProjExtState(0, scr_name..'::'..plugin_name, i, preset) -- preset data contains preset name
				end
			end
		end
	end

Error_Tooltip('\n\n\t\t   d o n e ! \n\n make sure to save the project \n\n', 1,1) -- caps, spaced are true

r.MarkProjectDirty(0) -- needed to be able to save right after dumping because it's not registered as change by REAPER and saving won't work if no other change has been registered

return true	-- to prevent re-loading of the menu if 'Keep menu open' sett is enabled so that the tooltip isn't overstaged by it

end


function Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)

-- only display warning if there's data risking to be overwritten
local mess = fx_name and #r.GetExtState(scr_name..'::'..fx_name, 1) > 0 and '      All temporary presets which have been saved so far \n\n for the focused FX are going to be irreversibly overwtitten!' or not fx_name and #r.GetExtState(scr_name, 'PLUGIN NAME LIST') > 0 and '   All temporary presets which have been saved so far \n\n'..(' '):rep(13)..'are going to be irreversibly overwtitten!'
local resp = mess and r.MB(mess, 'WARNING',1)
	if resp == 2 then return end -- canlcelled by the user

	local function delete_current(fx_name)
		for i=1,100 do
		r.DeleteExtState(scr_name..'::'..fx_name, i, true) -- persist true
		end
	end

	if fx_name then
	local ret, preset = r.GetProjExtState(0, scr_name..'::'..fx_name, 1)
		if ret == 0 then
		Error_Tooltip('\n\n no dump found to load from \n\n', 1,1) -- caps, spaced are true // likely redundant because if there's no dump the menu item is grayed out
		return true
		end
	-- if found, first delete all currently in the RAM
	delete_current(fx_name)
	-- load
	local idx = 0
		for i=1,100 do
		local ret, preset = r.GetProjExtState(0, scr_name..'::'..fx_name, i)
			if ret == 1 then
			idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
			r.SetExtState(scr_name..'::'..fx_name, idx, preset, false) -- persist false
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
				local ret, preset = r.GetProjExtState(0, scr_name..'::'..plugin_name, i)
					if ret == 1 then
					idx = idx+1 -- just a means to ensure gapless indexing in case GetProjExtState returns data with gaps
					r.SetExtState(scr_name..'::'..plugin_name, idx, preset, false) -- persist false
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

	if fx_name then -- only dump focused plugin dump
	r.SetProjExtState(0, scr_name..'::'..fx_name, '', '') -- key and value are empty strings to delete them
		for idx, plugin_name in ipairs(names_t) do
			if plugin_name == fx_name then table.remove(names_t, idx) break end
		end
	-- resave updated plugin names list
	r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST', table.concat(names_t,'::'))
	else -- delete all
	-- delete presets
		for idx, plugin_name in ipairs(names_t) do
		r.SetProjExtState(0, scr_name..'::'..plugin_name, '', '') -- key and value are empty strings to delete them
		end
	r.SetProjExtState(0, scr_name, 'PLUGIN NAME LIST', '') -- delete plugin names list
	end

Error_Tooltip('\n\n\t  d o n e ! \n\n to make permanent \n\n  save the project \n\n', 1,1) -- caps, spaced are true

r.MarkProjectDirty(0) -- needed to be able to save right after dumping because it's not registered as change by REAPER and saving won't work if no other change has been registered

return true	-- to prevent re-loading of the menu if 'Keep menu open' sett is enabled so that the tooltip isn't overstaged by it

end



function Manage_Menu_Toggle_Setting(scr_name, sett_name, enabled)

local toggle = enabled and '0' or '1'
r.SetProjExtState(0, scr_name, sett_name, toggle)
return toggle == '1'

end


function Manage_Preset_List_Offset(list_offset, preset_t, scr_name)
::RETRY::
local ret, output = r.GetUserInputs('SET PRESET LIST OFFSET',1,'Type in integer or submit blank,extrawidth=100',list_offset)
local num = output:gsub(' ', '')
	if not ret then return
	elseif #num == 0 or tonumber(num) == 0 then
	r.SetProjExtState(0, scr_name, 'PRESET LIST OFFSET', '')
	elseif not tonumber(num) then
	Error_Tooltip('\n\n invalid input \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
	goto RETRY
	elseif tonumber(num) then
	local int, frac = math.modf(num)
	local err = frac > 0 and 'decimals are not supported' or int >= #preset_t and '  the number exceeds/equals \n\n the number of stored presets'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1,1, 150) -- caps, spaced are true, x 150 to move tooltip away from the OK buttn because it blocks it
		goto RETRY
		end
	r.SetProjExtState(0, scr_name, 'PRESET LIST OFFSET', num)
	end
end




function Reload_Menu_at_Same_Pos(menu, OPTION) -- still doesn't allow keeping the menu open after clicking away
-- local x, y = r.GetMousePosition()
--	if x+0 <= 100 then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with OPTION is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and OPTION) and gfx.init('', 0, 0)
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

end


::RELOAD::

local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias = GetFocusedFX()

local _, scr_name, scr_sect_ID, cmd_ID, _,_,_ = r.get_action_context()
scr_name = scr_name:match('([^\\/]+)%.%w+')

local ret, desc_order = r.GetProjExtState(0, scr_name, 'LIST PRESETS IN DESC ORDER')
desc_order = desc_order == '1'
local ret, list_offset = r.GetProjExtState(0, scr_name, 'PRESET LIST OFFSET')

local preset_t, preset_menu, fx_name, stored_plugin_names_t, plugin_name_idx = Load_Preset_List(tr, take, fx_num, scr_name, desc_order, list_offset) -- plugin_name_idx isn't used anywhere in the script

local ret, plugin_names_lst_dump = r.GetProjExtState(0,scr_name,'PLUGIN NAME LIST')

	if not fx_name then
		if #stored_plugin_names_t == 0 and ret == 0 then -- allows loading the menu with the names list if proj data is stored
		Error_Tooltip('\n\n no focused fx \n\n', 1,1) -- caps, spaced are true
		return r.defer(no_undo) end
	end

local ret, keep_open = r.GetProjExtState(0, scr_name, 'KEEP MENU OPEN')
keep_open = keep_open == '1'

local ret, preset_dump = table.unpack(fx_name and {r.GetProjExtState(0, scr_name..'::'..fx_name, 1)} or {}) -- the return values are only used as conditions

	if #preset_t == 0 and fx_name then
		if ret == 0 then -- allows loading the menu without presets when proj dump is stored to be able to load from the dump
		local err = Save_Preset(tr, take, fx_name, fx_num, preset_t, scr_name, stored_plugin_names_t)
			if keep_open and not err then goto RELOAD end -- if dialogue is cancelled err will be true to prevent re-loading
		return r.defer(no_undo) end
	end

function checkbox(enabled)
return enabled and '[+]' or '[  ]'
end

	if fx_name then
	local greyout1 = #preset_menu == 0 and '#' or '' -- to grayout irrelevant menu items when only proj dump is available
	local greyout2 = #preset_dump == 0 and '#' or '' -- to grayout irrelevant menu items when proj dump is unavailable
	preset_menu = fx_name..':|'..preset_menu --(#preset_menu > 0 and fx_name..':|' or '')..preset_menu
	menu = '&Store preset [ s ]|&Quick store preset [ q ]|'..greyout1..'&Apply the last stored preset [ a ]|'..greyout1..'&Rename preset [ r ]|'..greyout1..'&Delete preset [ d ]|>&Other options [ o ]|'..greyout1..'Delete all for focused FX|'..greyout1..'Dump focused FX presets to project file|'..greyout2..'Force load focused FX presets from project dump|'..greyout2..'Delete focused FX presets from project dump||Keep menu open '..checkbox(keep_open)..'|Display presets in descending order '..checkbox(desc_order)..'|<Offset preset list by: '..list_offset..'|'..(#preset_menu > 0 and '||' or '')..preset_menu
	else
	local greyout1 = #stored_plugin_names_t == 0 and '#' or '' -- to grayout irrelevant menu items when only proj dump is available
	local greyout2 = #plugin_names_lst_dump == 0 and '#' or '' -- to grayout irrelevant menu items when proj dump is unavailable
	local sep = #stored_plugin_names_t > 0 and '|||' or ''
	menu = greyout1..'Delete &all [ a ]|'..greyout1..'Dump all to the &project file [ p ]|'..greyout2..'&Force load all from project dump [ f ]|'..greyout2..'&Delete all from project dump [ d ]'..sep..table.concat(stored_plugin_names_t,'|')
	end

	if fx_name then -- there's focused fx
	local output = Reload_Menu_at_Same_Pos(menu, keep_open)
		if output > 0 and output < 3 then
		local quick_save = output == 2
		err = Save_Preset(tr, take, fx_name, fx_num, preset_t, scr_name, stored_plugin_names_t, quick_save)
		elseif output == 3 then
		local parm_list = preset_t[#preset_t]:match('::(.+)') -- excluding preset name
		Re_Store_Plugin_Settings(tr, take, fx_num, parm_list) -- Apply last stored
		elseif output == 4 then
		Rename_Preset(preset_t,fx_name, scr_name)
		elseif output == 5 then
		err = Delete_Preset(preset_t, fx_name, stored_plugin_names_t, scr_name)
		elseif output == 6 then
		err = Delete_All_For_Current_Plugin(preset_t, fx_name, stored_plugin_names_t, scr_name)
		elseif output == 7 then
		err = Dump_To_Project_File(fx_name, scr_name, preset_t)
		elseif output == 8 then
		err = Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)
		elseif output == 9 then
		err = Delete_Proj_Dump(scr_name, fx_name)
		elseif output == 10 then
		keep_open = Manage_Menu_Toggle_Setting(scr_name, 'KEEP MENU OPEN', keep_open) -- will prevent reload after toggling to Off
		elseif output == 11 then
		Manage_Menu_Toggle_Setting(scr_name, 'LIST PRESETS IN DESC ORDER', desc_order)
		elseif output == 12 then
		Manage_Preset_List_Offset(list_offset, preset_t, scr_name)
		elseif output > 13 then -- accounting for plugin name menu item which is 11th item
		output = output-13 -- offset to be able to access table fields
		local idx = desc_order and #preset_t+1-output or output -- account for list arrangement in descending order
		list_offset = #list_offset > 0 and list_offset or 0
		idx = idx + (list_offset+0) * (desc_order and -1 or 1) -- account for preset list display offset
		local parm_list = preset_t[idx]:match('::(.+)') -- excluding preset name
		Re_Store_Plugin_Settings(tr, take, fx_num, parm_list) -- Apply
		end

		if output > 0 and keep_open and not err then goto RELOAD end -- only reload when error isn't generated otherwise it's not visible because the menu window overrides the tooltip

	else -- no focused fx

	local output = Reload_Menu_at_Same_Pos(menu, keep_open)
		if output == 1 then
		err = Delete_All(preset_t, stored_plugin_names_t, scr_name)
		elseif output == 2 then
		Dump_To_Project_File(fx_name, scr_name, preset_t, stored_plugin_names_t) -- fx_name here is nil
		elseif output == 3 then
		err = Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name) -- fx_name here is nil
		elseif output == 4 then
		err = Delete_Proj_Dump(scr_name, fx_name) -- fx_name here is nil
		elseif output > 4 then -- per fx name options menu
		local fx_name = stored_plugin_names_t[output-4]
		local greyout = r.GetProjExtState(0, scr_name..'::'..fx_name, 1) == 1 and '' or '#' -- whether there's fx data stored in the project file
		local menu = fx_name..'||'..'Delete all FX presets|'..'Dump FX presets to project file|'
		..greyout..'Force load FX presets from project dump|'..greyout..'Delete FX presets from project dump'
		local preset_t = Get_Presets_By_FX_Name(scr_name, fx_name)
		local output = Reload_Menu_at_Same_Pos(menu)
			if output == 2 then
			Delete_All_For_Current_Plugin(preset_t, fx_name, stored_plugin_names_t, scr_name)
			err = r.GetProjExtState(0, scr_name, 'PLUGIN NAME LIST') == 0 and r.GetExtState(scr_name, 'PLUGIN NAME LIST') == ''
			elseif output == 3 then
			Dump_To_Project_File(fx_name, scr_name, preset_t)
			elseif output == 4 then
			Force_Load_From_Proj_Dump(scr_name, stored_plugin_names_t, fx_name)
			elseif output == 5 then
			err = Delete_Proj_Dump(scr_name, fx_name)
			end
		end

		if (not fx_name and output == 1 or output > 2 or fx_name and output > 1) and keep_open and not err then goto RELOAD end

	end

do return r.defer(no_undo) end


