--[[
ReaScript name: BuyOne_Copy project JSFX to project folder.lua OR BuyOne_Update broken JSFX instances in the RPP file.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 1.2 #Improved reliability of evaluation of JSFX instance being broken in
				BuyOne_Update broken JSFX instances in the RPP file.lua script
				#Fixed updating broken JSFX instances in 
				BuyOne_Update broken JSFX instances in the RPP file.lua script
			1.1 #Added support for container FX
				#Excluded FX in the Monitorong FX chain because they're global
				#Enabled copying JSFX dependencies, i.e. image files, API libraries, data files,
				/Data folder contents
				#Added prompts and status messages
				#Added a feature of copying this script into the project /Effects
				folder under a different name (details see in 'About' text)
				#Updated 'About' text
Licence: WTFPL
REAPER: v6.37+ recommended
Provides: [main=main,midi_editor] .
About: 	The script operation depends on its name.

		When named 
		'BuyOne_Copy project JSFX to project folder.lua'
		which is its default name, it copies project JSFX 
		into the /Effects subfolder under the project folder 
		to ensure project portability, at least as far 
		as JSFX are concerned.

		When named 
		'BuyOne_Update broken JSFX instances in the RPP file.lua'
		which is an instance produced by its main version,
		it repairs broken JSFX associations in FX chains
		for JSFX local to project but located in subfolders
		because REAPER doesn't do so automatically.

		IN DETAIL

		As long as the project folder contains a file of
		JSFX used in the project that's what the project 
		will automatically fall back on absent the JSFX 
		file at the path it was originally loaded from.
		This mechanism only works if JSFX local to project
		is located directly in the project /Effects
		subfolder. However this isn't always possible
		or reliable in terms of JSFX file structure.
		JSFX which include dependencies such as image files
		and API libraries located in different folders
		will break if their directory structure isn't 
		preserved. Therefore plugins which do include them
		will be copied by the main script with their 
		directory structure intact and placed in a 
		dedicated subfolder under the /Effects folder 
		in the project directory. Because of this their 
		instances won't be automatically updated by REAPER
		in FX chains to point to the file copy local 
		to project. 

		The solution is to force their update by using 
		a second version of the script which is placed 
		by the main version in the project /Effects folder 
		along with copies of JSFX files, being named
		'BuyOne_Update broken JSFX instances in the RPP file.lua'.
		To be executed this script won't have to be imported 
		into the Action list, although it might. Instead 
		it can be run from the disk via action  
		'ReaScript: Run ReaScript (EEL2 or Lua)...'
		To update the broken JSFX associations open the
		project as normal and run the script. The project
		has to be open for the script to detect broken
		instances. The script will update the RPP project 
		file which will then have to be reloaded. The script
		will display a dialogue with a diagnostic message 
		and an option to reload the project after the 
		update, and if confirmed the updated file will be 
		open in a new tab just to be on the safe side so 
		that if something went awry during the file update 
		you will still have access to the original project 
		and be able to re-save it.  
		If the dialogue is declined in order to reload the 
		project manually, it's strongly recommended to open 
		it in a new tab. Additonally, before running the 
		script create a backup copy of the project file.  

		Even if the project was saved with updated JSFX
		instances associations, whether updated automatically
		by REAPER or with the abovementioned script, once 
		copies of the JSFX local to project become available 
		at their default location in the /Effects folder 
		at REAPER resource path, their instances in FX chains 
		get automatically re-pointed back to the source.

		If any plugins rely on external content located
		in the /Data folder, such content is copied to 
		the /_Data subfolder in the project /Effects
		folder or in the dedicated plugin subfolder under
		/Effects. This content will not be available to
		the plugin until moved to the /Data folder of the
		current REAPER install if necessary.

		In builds older than 6.37 JSFX will only be collected
		if their instances in FX chains were not renamed.

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
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
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


function space(num)
return tonumber(num) and (' '):rep(num) or ''
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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



function FX_Select_Function_Type()
-- to target either track or take;
-- after execution, the functions can be accessed
-- with the syntax fx[function_name] or fx.function_name
-- using function names listed in the table t below;
-- differs from FX_Select_Function_Type1()
-- in that this function doesn't have to be called
-- only when the object pointer is available,
-- enough to run it once at the very beginning of the script
-- to be able to access the FX functions matching object type
-- anywhere in the script;
-- obviously both arguments and return values remain
-- as required by the ReaScript API;
-- !!! IMPORTANT: names GetCount and GetChainVisible
-- cover input/monitoring fx chains as well
-- and for input/monitoring fx chains, boolean true as a 2nd argument must be passed,
-- while GetEnvelope covers envelopes in both object types,
-- the relevant version is selected at runtime


local t = {'AddByName','CopyToTake','CopyToTrack','Delete','EndParamEdit','FormatParamValue','FormatParamValueNormalized','GetChainVisible','GetCount','GetEnabled','GetEQ','GetEQBandEnabled','GetEQParam','GetEnvelope','GetFloatingWindow','GetFXGUID','GetFXName','GetIOSize','GetNamedConfigParm','GetNumParams','GetOffline','GetOpen','GetParam','GetParameterStepSizes','GetParamEx','GetParamFromIdent','GetParamIdent','GetParamName','GetParamNormalized','GetParamSectionName','GetPinMappings','GetPreset','GetPresetIndex','GetRecChainVisible','GetRecCount','GetUserPresetFilename','NavigatePresets','SetEnabled','SetEQBandEnabled','SetEQParam','SetNamedConfigParm','SetOffline','SetOpen','SetParam','SetParamNormalized','SetPinMappings','SetPreset','SetPresetByIndex','Show'
}

--[[ -- SEE USAGE IN THE LOOP BELOW
	local function sel(name)
	-- the function has to be returned as anonymous so that it's not executed during table construction,
	-- data passed as the 'name' argument being an upvalue will be stored inside the returned function
	-- and concatenated on the fly the moment the stored function is executed
	-- i.e. fx.AddByName();
		return function(...)
		local obj, input_fx = t[1], #t > 1 and t[#t] -- input_fx boolean value is only used for two functions for which only 1 argument is required, i.e. object, therefore whenever there're two, the last can be used as an indicator of input fx function, in all other cases where multiple arguments are expected the last argument won't affect function name selection even if true
		local input_fx = fx_idx < 0x2000000 and fx_idx >= 0x1000000 or fx_idx >= fx_idx-0x2000000
		local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
		local pref = tr and 'TrackFX_' or 'TakeFX_'
		local name = name == 'GetEnvelope' and tr and 'GetFXEnvelope'
		or input_fx and (name == 'GetChainVisible' and pref..'GetRecChainVisible'
		or name == 'GetCount' and pref..'GetRecCount')
		or pref..name
		return reaper[name](table.unpack(t))
		end
	end
--]]

local fx = {}
	for k, name in ipairs(t) do
	fx[name] = 	function(...)
					-- the 'name' var is stored inside the function and contcatenated on the fly
					-- the moment the stored function is executed
					-- i.e. fx.AddByName(),
					-- due to being anonymous the function isn't executed while being stored
					local t = {...}
					local obj, input_fx = t[1], #t > 1 and t[#t] -- input_fx boolean value is only used for two functions for which only 1 argument is required, i.e. object, therefore whenever there're two, the last can be used as an indicator of input fx function, in all other cases where multiple arguments are expected the last argument won't affect function name selection even if true
					local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
					local pref = tr and 'TrackFX_' or 'TakeFX_'
					local name = name == 'GetEnvelope' and tr and 'GetFXEnvelope'
					or input_fx and (name == 'GetChainVisible' and pref..'GetRecChainVisible'
					or name == 'GetCount' and pref..'GetRecCount')
					or pref..name
					return reaper[name](table.unpack(t))
					end
-- OR
-- fx[name] = sel(name) -- using above local function
	end

return fx

end
-- USE:
-- fx = FX_Select_Function_Type() -- run once at the beginning of the script
-- fx.AddByName(tr or take, name, instantiate) fx.CopyToTake(tr or take, fx_idx1, take, fx_idx2, false) etc.


local fx = FX_Select_Function_Type()


-- used collect(), store() inside collect_container_fx(),
-- in Copy_File() and in the main routine
function file_exists(path)
-- CROSS-PLATFORM
local ok, mess, code = os.rename(path, path)
return (ok or code == 13) and path -- 13 is error code for 'exists but permission denied' on some systems
end


-- used in store() inside collect_container_fx() and in collect()
function FX_Is_Accessible(obj, fx_idx)
-- relies on the fact that fx inaccessible
-- to REAPER at their registered installation path,
-- and showing the text
-- 'The following effect plugin could not be loaded
-- (effect configuration is preserved)'
-- in their instance UI
-- cannot be open in a floating window

	if fx.GetFloatingWindow(obj, fx_idx) then return true end -- if fx is open in a floating window it's 100% accessible

-- offlined fx too cannot be open in a floating window
-- so set online if necessary to prevent false positive
local offline = fx.GetOffline(obj, fx_idx)
	if offline then fx.SetOffline(obj, fx_idx, not offline) end
	
fx.Show(obj, fx_idx, 3) -- 3 show in floating window
local ok
	-- restore states
	if fx.GetFloatingWindow(obj, fx_idx) then
	fx.Show(obj, fx_idx, 2) -- close floating window
	ok = 1
	end
	if offline then fx.SetOffline(obj, fx_idx, offline) end
	
return ok

end



-- used in get_JSFX_external_links()
function process_directory_depth(relat_path, src_path)
-- concatenate path relative to src_path
-- based on relative path format,
-- expected relat_path format:
-- ../zz_libraries/colours_03_DS.png
-- DS_files/DS_Keyboard4oct_04.png
-- src_path is an absolute path;
-- the type of the separator is immaterial, can be mixed
relat_path = relat_path:sub(1,1):match('[\\/]') and relat_path:sub(2) or relat_path -- strip leading separator if any
local sep = src_path:match('[\\/]')
src_path = src_path:sub(-1) == sep and src_path or src_path..sep -- ensure that the src_path ends with a separator so that capture pattern works
local target_depth = select(2, relat_path:gsub('%.%.[\\/]', ''))
local current_depth = select(2, src_path:gsub('.-[\\/]+', ''))
relat_path = relat_path:match('.*%.%.[\\/](.+)') or relat_path
return src_path:match(('.-[\\/]'):rep(current_depth-target_depth))..relat_path
end



-- used in get_JSFX_external_links()
function collect_files_in_folder(path, t)
-- r.EnumerateFiles(path..'..', 0) -- reset EnumerateFiles() cache by accessing a valid dummy dir, e.g. r.EnumerateFiles(r.GetResourcePath(), 0)
-- r.EnumerateFiles(path, -1) -- -1 to clear the cache, or pass another directory (invalid one is suppported), since 6.20
-- https://forum.cockos.com/showthread.php?t=203235
-- applies to r.EnumerateSubdirectories() as well

r.EnumerateFiles(r.GetResourcePath(), 0) -- clear cache

local path = path:sub(-1):match('[\\/]') and path:sub(1,-2) or path -- strip trailing separator
local sep = path:match('[\\/]')
local i = 0
	repeat
	local file = r.EnumerateFiles(path, i) -- only returns file names
		if file then
		t[#t+1] = path..sep..file
		end
	i = i+1
	until not file
return t
end




-- used in get_JSFX_external_links()
function scan_path_for_file(path, filename, t)

r.EnumerateFiles(r.GetResourcePath(), 0) -- clear cache

local path = path:sub(-1):match('[\\/]') and path:sub(1,-2) or path -- strip trailing separator
local sep = path:match('[\\/]')
local i = 0
	repeat
	local file = r.EnumerateFiles(path, i)
		if file == filename then
		t[#t+1] = path..sep..file
		i = nil -- reset to signal found file
		break end
	i = i+1
	until not file

	if i then  -- file wasn't found, look in subdirectories
	r.EnumerateSubdirectories(r.GetResourcePath(), 0) -- clear cache
	local i = 0
		repeat
		local dir = r.EnumerateSubdirectories(path, i)
			if dir then
			t = scan_path_for_file(path..sep..dir, filename, t) -- do recursive search
			end
		i = i+1
		until not dir
	end

return t

end



-- used in collect() as well as in store() inside collect_container_fx()
function get_JSFX_external_links(path, t, plugin_path)
-- path is the jsfx file absolute path;
-- t is table passed inside collect();
-- plugin_path is jsfx path for concateneting paths
-- of files loaded via file_open() inside imported libraries
-- when this function is executed recursively in the '-- includes'
-- block of the loop below, required because in the recursive loop
-- 'path' arg will contain path to the library file which may be
-- located outside of the plugin's folder

local f = io.open(path,'r')
local cont = f:read('*a')
f:close()
local src_path = path:match('.+[\\/]') -- strip jsfx file name
-- check if outside of usual file declarations there're paths
-- used elsewhere in the code with file_open() to collect them as well
local path_patt = '"[%w%p/]-%.%w+"'
local paths_exist = cont:match('@serialize.-'..path_patt) or cont:match('@init.-'..path_patt)

local sep = path:match('[\\/]')
local comment
	for line in cont:gmatch('[^\n\r]+') do -- or io.lines(path)
		if line:match('/%*') then comment = 1
		elseif comment and line:match('%*/') then comment = nil
		elseif not paths_exist and (line:match('@serialize') or line:match('@init')) then break -- blocks which follow all file declarations unless paths found elsewhere in the code for use with file_open()
		elseif not comment then
			-- assets
			if line:match('filename:') then -- paths inside the jsfx file folder in /Effects directory
			local asset_relat_path = line:match('^%s*filename:%s*%d+,%s*(.+)')
			local asset_path = process_directory_depth(asset_relat_path, src_path)
			table.insert(t.assets, asset_path)
			-- data files
			elseif line:match('^%s*slider%d+:%s*/') then -- /Data directory subfolder
			local data_path = r.GetResourcePath()..sep..'Data'..line:match(':(/.-):')
			t.data = collect_files_in_folder(data_path, t.data) -- scan the /Data directory subfolder
			-- includes
			elseif line:match('import .+') then
			local incl_file = line:match('import (.+)') -- included library files
			local plugin_folder = src_path:match('(.+Effects[\\/].-[\\/])') -- isolate plugin parent folder, in case it itself resides in a subfolder, to search in parent and all of its subfolders
			t.imported = scan_path_for_file(plugin_folder, incl_file, t.imported)
			local included_file = t.imported[#t.imported]
				if included_file then -- dependencies may have their own dependencies, so scan those for additional files recursively
				t = get_JSFX_external_links(included_file, t, src_path) -- src_path is plugin path for concatenating paths of files loaded via file_open() in the code of the included library
				end
			-- files loaded via file_open() from elsewhere in the code,
			-- and these can be located either at the plugin path or in the /Data folder
			elseif line:match(path_patt) then
			local file_path = line:match(path_patt)
			local data_path = src_path:match('(.-[\\/])Effects')..'Data'..sep
			-- files loaded via file_open() in the code may be found in the plugin folder or in /Data folder
			local path1, path2 = (plugin_path or src_path)..file_path, data_path..file_path
			file_path = file_exists(path1) and path1 or file_exists(path2) and path2
				if file_path then
				table.insert(t.opened, file_path)
				end
			end
		end
	end
return t
end



-- used in collect_container_fx()
function Collect_All_Container_FX_Indices(obj, t, recFX, parent_cntnr_idx, parents_fx_cnt)
-- creates table containing indices of fx inside containers in nested tables
-- following container hierarchy;
-- obj is track or take, t must be nil, recFX is boolean to target input/Monitoring FX,
-- parent_cntnr_idx, parents_fx_cnt must be nil
-- fx indices from the outermost fx chain (the object main fx chain) are of course stored as well
-- see Loop_Over_FX_Container_Table() next

local fx_cnt = not parent_cntnr_idx and (recFX and fx.GetRecCount(obj) or fx.GetCount(obj))
fx_cnt = fx_cnt or ({fx.GetNamedConfigParm(obj, parent_cntnr_idx, 'container_count')})[2]

local t = t or {} -- add table for the outermost FX chain on the very first run

	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	local retval, cont_fx_cnt = fx.GetNamedConfigParm(obj, i, 'container_count') -- retval true even if container is empty
		if fx.GetIOSize(obj, i) == 8 and cont_fx_cnt+0 > 0 then -- non-empty container
		t[#t] = {i, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and i or 0x2000000+i+1 -- 0x2000000 is only added once, to the index of the outermost parent container
		local parents_fx_cnt = (parents_fx_cnt or 1) * (fx_cnt+1) -- fx_cnt is fx count in the parent container
		-- the function must not return table here, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[#t][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end

return t

end



-- used in collect_container_fx()
function Loop_Over_FX_Container_Table(obj, t, t2, store, update)
-- obj is track or take, t is the table stemming from collect_container_fx()
-- and returned by Collect_All_Container_FX_Indices(),
-- t2 is table stemming from collect_container_fx() to store the data in,
-- store is finction stemming from collect_container_fx()
-- update is boolean stemming from collect_container_fx()

local not_found = 0

	-- target fx instances in a chain ignoring containers
	for k, fx_idx in ipairs(t) do
		if tonumber(fx_idx) then -- fx instance // if container, evaluation will be false since the value is a table
		local count
		t, count = store(obj, fx_idx, t2, update)
		not_found = not_found+count
		end
	end

	-- target containers, ignoring fx instances
	for k, cont in ipairs(t) do
		if not tonumber(cont) then -- a table storing container index and its fx list
		local count
		t, count = Loop_Over_FX_Container_Table(obj, cont[2], t2, store) -- go recursive to loop over container fx, cont[2] is the address of the nested table with container fx indices list, at cont[1] container own index is stored
		not_found = not_found+count
		end
	end

return t, not_found

end



-- used in collect()
function collect_container_fx(obj, cont_idx, recFX, t, update)
-- update is boolean stemming from collect()

	local function store(obj, fx_idx, t, update)
	local path = r.GetResourcePath()
	local sep = path:match('[\\/]')
	local not_found = 0
	local ret, name = fx.GetFXName(obj, fx_idx, '')
	local ret, orig_name = fx.GetNamedConfigParm(obj, fx_idx, 'fx_name')
	-- if jsfx instance in fx chain was loaded from a copy local to project
	-- its default name and its original name will both include <Project>/ prefix
	-- so accounting for that
	local patt1, patt2 = '^JS:.-%[(.-)%]', '^JS:.-<Project>/(.+)'
	name = name:match(patt1) or name:match(patt2) or orig_name:match(patt1) or orig_name:match(patt2)
		if name and (not update or update and not FX_Is_Accessible(obj, fx_idx)) then
		local path = not update and path..sep..'Effects'..sep..name or name
			if not t[path] then
				if not update and not file_exists(path) then -- file_exists() validates paths of plugins in case they were deleted from their original location
				not_found = 1
				else
				t[path] = not update and {assets={}, data={}, imported={}, opened={}} or ''
					if not update then
					t[path] = get_JSFX_external_links(path, t[path])
					end
				end
			end
		end
	return t, not_found
	end

local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local not_found = 0

	if build >= 7 and build < 7.06 then
	local Count = recFX and fx.GetRecCount or fx.GetCount
	local cont_fx_t = Collect_All_Container_FX_Indices(obj, _, recFX, 0x2000000+cont_idx+1, Count(obj)+1)
	t, not_found = Loop_Over_FX_Container_Table(obj, cont_fx_t, t, store, update)
	elseif build >= 7.06 then
	local ret, count = fx.GetNamedConfigParm(obj, cont_idx, 'container_count')
		if count == '0' then return end
		for i=0, count-1 do
		local ret, fx_idx = fx.GetNamedConfigParm(obj, cont_idx, 'container_item.'..i)
		local count
			if fx.GetIOSize(obj, fx_idx) == 8 then -- container, go recursive
			t, count = collect_container_fx(obj, fx_idx, recFX, t, update)			
			else
			t, count = store(obj, fx_idx, t, update)
			end
		not_found = not_found+count
		end
	end

return t, not_found

end





function collect(obj, t, input_fx, update)
local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local not_found = 0
	for i = 0, fx.GetCount(obj, input_fx)-1 do
	local i = input_fx and i+0x1000000 or i
	local ret, name = fx.GetFXName(obj, i, '')
	local ret, orig_name = fx.GetNamedConfigParm(obj, i, 'fx_name')
	-- if jsfx instance in fx chain was loaded from a copy local to project
	-- its default name and its original name will both include <Project>/ prefix
	-- so accounting for that
	local patt1, patt2 = '^JS:.-%[(.-)%]', '^JS:.-<Project>/(.+)'
	name = name:match(patt1) or name:match(patt2) or orig_name:match(patt1) or orig_name:match(patt2)
		if name and (not update or update and not FX_Is_Accessible(obj, i)) then
		local path = not update and path..sep..'Effects'..sep..name or name
			if not t[path] then
				if not update and not file_exists(path) then -- file_exists() validates paths of plugins in case they were deleted from their original location
				not_found = not_found+1
				else
				t[path] = not update and {assets={}, data={}, imported={}, opened={}} or ''
					if not update then
					t[path] = get_JSFX_external_links(path, t[path])
					end
				end
			end
		elseif fx.GetIOSize(obj, i) == 8 then -- container
		t = collect_container_fx(obj, i, input_fx, t, update)
		end
	end
return t, not_found
end



-- used in copy_files() and in the main routine
function Copy_File(cur_file_path, new_file_path, want_move)
-- cur_file_path includes file name
-- new_file_path excludes file name

local f = io.open(cur_file_path,'rb')
local cont = f:read('*a')
f:close()
	if want_move then -- remove from old location
	os.remove(cur_file_path)
	end
local sep = new_file_path:match('[\\/]')
local path = new_file_path..(new_file_path:sub(-1) == sep and '' or sep)..cur_file_path:match('.+[\\/](.+)') -- concatenate full path of the file at the new location

	if not file_exists(path) then
	f = io.open(path,'wb')
	f:write(cont)
	f:close()
	return file_exists(path) and path
	end
end



function Create_Script_Copy(scr_path, target_path)
local f = io.open(scr_path, 'rb')
local cont = f:read('*a')
f:close()
local sep = target_path:match('[\\/]')
f = io.open(target_path..sep..'BuyOne_Update broken JSFX instances in the RPP file.lua', 'wb')
f:write(cont)
f:close()
end



function copy_files(t, path, plugin_path)
-- path is the path to /Effects folder
	for k, file in ipairs(t) do
	local file_path = file:match('.+Effects([\\/].+)[\\/]')
	local data_path = file:match(Esc(r.GetResourcePath())..'.-Data([\\/].+)[\\/]') -- accounting for paths of files loaded via file_open() stored inside t.opened table which may be located in the /Data folder, BUT copied they will be to the plugin folder because they can be loaded from there as well
	local path = file_path and path..file_path
	or data_path and path..plugin_path:match('.+Effects([\\/].+)[\\/]')..data_path or path -- for files loaded via file_open() and found in the /Data folder concatenate path inside the plugin folder to copy it there
	r.RecursiveCreateDirectory(path, 0) -- if already exists, nothing will change
	Copy_File(file, path)
	end
end



function open_directory(dir)
-- the action 'Show render path in explorer' is supported since 7.73
-- dir is path to the directory to open
	if not dir then return end
local retval, render_path = r.GetSetProjectInfo_String(0, 'RENDER_FILE', '', false) -- is_set false
-- temporarily set render path to project path to open it with the action;
-- alternatively RECORD_PATH and RECORD_PATH_SECONDARY could be used
-- along with actions 'Show record path in explorer' and 'Show secondary record path in explorer'
-- but if for some reason its restoration fails, potential damage is far greater
r.GetSetProjectInfo_String(0, 'RENDER_FILE', dir, true) -- is_set true
r.Main_OnCommand(43206, 0) -- Show render path in explorer // open the dir
-- restore original render path
r.GetSetProjectInfo_String(0, 'RENDER_FILE', render_path, true) -- is_set true
end



function open_dir_in_file_browser(dir) -- see also open_directory() below
local OS = r.GetOS():sub(1,3)
local command = OS == 'Win' and {'explorer'} or (OS == 'OSX' or OS == 'mac') and {'open'} or {'nautilus', 'dolphin', 'gnome-open', 'xdg-open', 'gio open', 'caja', 'browse'}
-- https://askubuntu.com/questions/31069/how-to-open-a-file-manager-of-the-current-directory-in-the-terminal
	for k,v in ipairs(command) do
	local result = r.ExecProcess(v..' '..dir, -1) -- timeoutmsec is -1 = no wait/terminate // -- if dir is system root with slash, e.g. C:/ opens 'My Documents' on Windows, must be either 'C:' or 'C:\\'
		if result then return end
	end
end



local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local update_instances = scr_name:lower():match('update broken jsfx')

local t = {}
local master = r.GetMasterTrack(0)

	for i=-1, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i) or master
	t = collect(tr, t, nil, update_instances) -- input_fx nil
		if tr ~= master then -- excluding monitoring fx because they're global
		t = collect(tr, t, 1, update_instances) -- input_fx true
		end
		for i=0, r.CountTrackMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr, i)
			for i=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, i)
				if take then
				t = collect(take, t, nil, update_instances) -- input_fx nil
				end
			end
		end
	end



local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local old = build < 6.37
local proj, path = r.EnumProjects(-1)
local err = #path == 0 and '   no saved project file \n\n and no project directory'
or not next(t) and (update_instances and space(3)..' no broken jsfx \n\n found in the project'
or not_found == 0 and space(old and 3 or 0)..'no jsfx found in the project'..(old and '\n\n or their instances were renamed' or '')
or not_found > 0 and 'project jsfx source files \n\n\t  weren\'t found, \n\n\t nothing to copy.')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end


local proj, proj_path = r.EnumProjects(-1)
local path = path:match('.+[\\/]') -- strip project file name

	if path:match('^%u:[\\/]$')
	and r.MB('The project folder is disk '..path:match('%u')..' root directory.\n\n'
	..(' '):rep(11)..'Wish to copy the JSFX there?', 'PROMPT', 1) == 2 then
	return r.defer(no_undo)
	end

local sep = path:match('[\\/]')
path = path..'Effects'
r.RecursiveCreateDirectory(path, 0) -- create 'Effects' subfolder in the project folder // if already exists, nothing will change


	if not update_instances then

	-- THIS LOOP RECREATES ORIGINAL FX DIRECTORY STRUCTURE
	-- BUT WHEN FX WHICH HAS INSTANCES IN FX CHAINS, IS NOT AVAILABLE AT ITS ORIGINAL PATH,
	-- IT'S COPY LOCAL TO PROJECT IS AUTOMATICALLY PICKED UP BY REAPER
	-- ONLY IF LOCATED DIRECTLY UNDER /Effects IN THE PROJECT FOLDER,
	-- SUBFOLDERS MAKE THIS IMPOSSIBLE EVEN THOUGH THEY'RE STILL REGISTERED IN THE FX BROWSER;
	-- AT THE SAME TIME INSTANCES OF AN FX LOCAL TO PROJECT
	-- WILL BE AUTOMATICALLY PICKED UP BY REAPER FROM THE MAIN /Effects DIRECTORY
	-- IF AVAILABLE, REGARDLESS OF THEIR COPY AVAILABILITY IN THE PROJECT FOLDER;
	-- IF JSFX BECOMES UNAVAILABLE AT ITS ORIGINAL LOCATION WHILE PROJECT IS OPEN
	-- ITS INSTANCES IN FX CHAINS REMAIN FUNCTIONAL

	local want_script_copy

		for cur_path in pairs(t) do

		-- copy actual jsfx
		local plugin_dir = cur_path:match('.+Effects([\\/].+)[\\/]')
		local t = t[cur_path] -- extra content table
		local extras = #t.assets + #t.imported + #t.opened > 0
		want_script_copy = want_script_copy or extras
		plugin_dir = plugin_dir and extras and path..plugin_dir or path -- add plugin folder path which may include the dedicated dev folder and another, nested, folder if not directly in the dev folder root and only if plugin has dependencies, so that its original structure is preserved, if not dependences - copy straight into the /Effects folder
		r.RecursiveCreateDirectory(plugin_dir, 0) -- if already exists, nothing will change
		Copy_File(cur_path, plugin_dir) -- full new path is concatenated inside the function

		-- handle assets, dependencies and files loaded via file_open()
		copy_files(t.assets, path) -- assets, i.e. image files
		copy_files(t.imported, path) -- dependencies, i.e. API libraries // using imported files original relative path even though they can reside anywhere in the fx parent directory, i.e. directory right below /Effects at any depth
		copy_files(t.opened, path, cur_path) -- files loaded via file_open()

		-- handle data files whose path is declared in a slider
			for k, data in ipairs(t.data) do
			local data_subfolder = data:match('.+Data([\\/].-)[\\/]')
			local path = (plugin_dir:match('.+Effects[\\/][^\\/]+') or path)..sep..'_Data'..data_subfolder -- capturing only fx parent directory path in case it itself resides in a subfolder // data content of plugins without dependencies which (the plugins) are copied directly into the /Effects folder in the project directory will be copied to the /_Data folder also directly under /Effects there
			-- creating 'Data' folder in the fx parent directory, i.e. right under /Effects
			r.RecursiveCreateDirectory(path, 0) -- if already exists, nothing will change
			Copy_File(data, path)
			end
		end

	local script_new_path = path..scr_path:match('.+([\\/].+)')
		if want_script_copy and not file_exists(script_new_path) then -- only create if there're jsfx whose directory structure was preserved and which will certianly end up being broken
		Create_Script_Copy(scr_path, path)
		end

	local open_directory = build >= 7.73 and open_directory or open_dir_in_file_browser
	local mess = not_found > 0 and 'Some JSFX source files weren\'t found\n\n'..space(13)..'so couldn\'t be copied.\n\n' or ''	
		if r.MB(mess..' Wish to open project /Effects folder?', 'PROMPT', 4) == 6 then
		open_directory(path)
		end

	else

	-- WHEN INSTANCE OF AN FX WHICH WAS LOCATED IN THE MAIN /Effects FOLDER
	-- IS AUTOMATICALLY SUBSTITUTED BY REAPER WITH A COPY LOCAL TO PROJECT,
	-- THE INSTANCE NAME IN FX CHAIN DOESN'T CHANGE, WHETHER IT'S DEFAULT OR USER ALIASED;
	-- WHEN AN INSTANCE OF AN FX LOCAL TO PROJECT IS EXCPLICITLY ADDED
	-- TO AN FX CHAIN FROM THE FX BROWSER, IT RECEIVES <Project>/ PREFIX,
	-- HOWEVER WHEN FORCE UPDATING FX INSTANCES BY ADDING <Project>/ TO
	-- THEIR CHUNK ENTRIES TO MAKE THEM POINT TO JSFX COPIES
	-- LOCAL TO PROJECT THAT RESIDE IN SUBFOLDERS UNDER /Effects BECAUSE
	-- SUCH LOCATION PREVENTS THEIR AUTOMATIC UPDATE BY REAPER,
	-- APPEARANCE OF <Project>/ PREFIX IN DEFAULT FX NAME IN FX CHAIN
	-- IS INEVITABLE, ALIASED NAMED REMAIN UNCHANGED

	local updated_RPP, broken, updated, missing = '', 0, 0, 0
		for line in io.lines(proj_path) do
			if line:match('<JS') then
			local js_path = line:match('<JS "(.+)" "') or line:match('<JS (.-) "') -- path either with or withous spaces
				if js_path then
				local copy_local_to_proj = path..sep..js_path -- recreating jsfx path relative to project ditectory, because only instances of fx whose directory structure has been preserved aren't automatically updated in fx chains and are treated here
					if t[js_path] then -- broken instance, stored inside collect()
					broken = broken+1
						if file_exists(copy_local_to_proj) then
						local patt = Esc(js_path:match('%s') and '"'..js_path..'"' or js_path)
						local repl_patt = (js_path:match('%s') and '"<Project>/'..js_path..'"' or '<Project>/'..js_path):gsub('%%', '%%%%')
						line, count = line:gsub(patt, repl_patt, 1)
						updated = updated+count
						else
						missing = missing+1
						end
					end
				end
			end
		updated_RPP = updated_RPP..(#updated_RPP > 0 and '\n' or '')..line
		end
		if updated > 0 then
		local f = io.open(proj_path, 'w')
		f:write(updated_RPP)
		f:close()
		end
	local mess = broken > 0 and broken == missing and 'JSFX sources of the broken instances\n\nweren\'t found in the project directory.\n\n'..space(5)
	or updated > 0 and missing > 0 and 'Some JSFX are missing in the project directory.\n\n'..space(10)
	..'Their instances weren\'t updated.\n\n'..space(10)
	or broken == 0 and 'No broken JSFX instances were found.\n\n'..space(6)
	or 'Broken JSFX instances have been updated.\n\n'..space(10)
		if r.MB(mess..'Wish to reload the project now?', 'STATUS INFO', 4) == 6 then
		r.Main_OnCommand(40859, 0) -- New project tab // open updated file in a new tab to retain the current one for salvaging the project in case the update went wrong
		r.Main_openProject('noprompt:'..proj_path)
		end
	end


do return r.defer(no_undo) end


