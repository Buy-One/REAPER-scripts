--[[
ReaScript name: BuyOne_Copy project JSFX to project folder.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: v6.37 recommended
Provides: [main=main,midi_editor] .
About: 	Copies project JSFX into a subfolder /Effects
			under the project folder which ensures project
			portability at least as far as JSFX are concerned.

			As long as the project folder contains a file of
			JSFX used in the project that's what the project 
			will fall back on absent the JSFX file at the path 
			it was originally loaded from.

			Subfolders in the project /Effects folder aren't 
			supported by REAPER therefore possible file name
			conflicts are resolved by preventing file ovewriting.
			So if there're identically named JSFX loaded from 
			different locations inside the main /Effects folder, 
			the file collected or found later won't ovetwrite 
			the one already copied to the project folder.	

			In builds older then 6.37 JSFX will only be collected
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


local fx = FX_Select_Function_Type()


function collect(obj, t, input_fx)
local path = r.GetResourcePath()
local sep = path:match('[\\/]')
	for i = 0, fx.GetCount(obj, input_fx)-1 do
	local i = input_fx and i+0x1000000 or i
	local ret, name = fx.GetFXName(obj, i, '')
	local ret, orig_name = fx.GetNamedConfigParm(obj, i, 'fx_name')
	local patt = '^JS:.-%[(.-)%]'
	name = name:match(patt) or orig_name:match(patt)
		if name then
		local path = path..sep..'Effects'..sep..name
			if not t[path] then
			t[path] = ''
			end
		end
	end
return t
end


function File_Exists(path)
-- CROSS-PLATFORM
local ok, mess, code = os.rename(path, path)
return (ok or code == 13) and path -- 13 is error code for 'exists but permission denied' on some systems
end


function Copy_Or_Move_File(cur_file_path, new_file_path, want_move)
-- cur_file_path includes file name
-- new_file_path excludes file name
local f = io.open(cur_file_path,'rb')
local cont = f:read('*a')
	if want_move then -- remove from old location
	os.remove(cur_file_path)
	end
local sep = new_file_path:match('[\\/]')
local path = new_file_path..(new_file_path:sub(-1) == sep and '' or sep)..cur_file_path:match('.+[\\/](.+)') -- concatenate full path of the file at the new location
	if not File_Exists(path) then
	f = io.open(path,'wb')
	f:write(cont)
	f:close()
	return File_Exists(path) and path
	end
end


local t = {}

	for i=-1, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
	t = collect(tr, t)
	t = collect(tr, t, 1) -- input_fx true
		for i=0, r.CountTrackMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr, i)
			for i=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, i)
				if take then
				t = collect(take, t)
				end
			end
		end
	end


local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.37
local proj, path = r.EnumProjects(-1)
local err = not next(t) and (' '):rep(old and 3 or 0)..'no jsfx found in the project'
..(old and '\n\n or their instances were renamed' or '')
or #path == 0 and '   no saved project file \n\n and no project directory'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

local proj, path = r.EnumProjects(-1)
path = path:match('.+[\\/]') -- strip project file name

	if path:match('^%u:[\\/]$')
	and r.MB('The project folder is disk '..path:match('%u')..' root directory.\n\n'
	..(' '):rep(11)..'Wish to copy the JSFX there?', 'PROMPT', 1) == 2 then
	return r.defer(no_undo)
	end

local sep = path:match('[\\/]')
path = path..'Effects'
r.RecursiveCreateDirectory(path, 0) -- create 'Effects' subfolder in the project folder

	for cur_path in pairs(t) do
	Copy_Or_Move_File(cur_path, path) -- full new path is concatenated inside the function
	end


do return r.defer(no_undo) end





