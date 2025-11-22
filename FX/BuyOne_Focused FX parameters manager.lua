--[[
ReaScript name: BuyOne_Focused FX parameters manager.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: 7.06+ is recommended for full functionality
Extensions: SWS/S&M recommended for reliablity
Provides: [main=main,midi_editor] .
About: 	The script is desined to allow management of multiple 
			FX parameter aliases and visibility in TCP from a single 
			persistent menu, which is more convenient than jumping 
			between submenus using REAPER native interface and having 
			to re-open them after each click.

			Admittedly management of multiple parameters visibility
			in TCP is already possible from the Envelope Manager
			and FX parameter list of FX inside containers accessible
			under PARAM button. So if parameter visibility is the only
			property you're interested in, this script is likely
			redundant.

			To enable/disable a parameter for being shown in the TCP
			(relevant to FX and FX containers in the main FX chain) or
			to be mapped across all containers (relevant to FX and FX 
			containers located inside container), click its item in the 
			menu to (un)checkmark it.  
			If 'Edit parameter name' option is enabled clicking a parameter 
			menu item will allow aliasing its name via the editor. Clicking
			in this case doesn't affect menu item checkmarking. To restore 
			original parameter name in the menu submit the editor empty, 
			which is supported in REAPER builds 6.37+.			

			Thus parameter names of FX and FX containers in the main 
			FX chain are checkmarked on menu load if these parameters are 
			shown in the TCP while for FX inside containers they're checkmarked 
			if they're mapped across the entire container hierarchy up to 
			the outermost container, i.e. the one belonging to the main 
			FX chain.  
			Parameters of FX inside containers shown in the TCP are marked
			with additional indicator following parameter name in the menu.
			Aliased parameter names are preceded with a dot, this applies 
			to paremeters of all FX regardless of their location.

			In order to apply parameter alias or restore its original name 
			(in supported REAPER builds) its item in the menu doesn't require 
			(un)ckeckmarking.  
			Applying parameter alias or restoring original parameter name 
			(in supported REAPER builds) of container FX parameters mapped 
			across the entire container hierarchy applies/restores it within 
			this scope as well, unless 'Apply parameter names locally' option 
			is enabled.

			To apply choices click APPLY menu item. While user defines their
			choices the choices are stored in the memory until APPLY is executed 
			or the menu is exited.  
			APPLY menu item will be disabled if there's no difference between 
			parameters current state (usually right after applying user choices)
			and user choices or user choices haven't been stored yet.

			OPTIONS submenu

			- Edit parameter names - click to enable parameter name aliasing,
			to call parameter name editor click its menu item; the option is
			enabled by default and cannot be disabled for focused FX instance
			in the main take or track input FX chain because parameter aliasing
			is the only meaningful operation.

			- Apply parameter names locally - only relevant for FX inside
			containers mapped across the entire container hierarchy; enable to 
			apply parameter alias to FX own parameter list only; when disabled, 
			the alias is applied across the entire container hierarchy; aliases
			of non-mapped parameters are always applied locally; the option is 
			disabled for FX in the main FX chain.

			- Show/Hide container FX parameters in TCP - click to activate
			the feature of setting container FX parameters for being shown/hidden
			in the TCP (see explanation below); the option is disabled for FX 
			in the main FX chain.

			- View current state / View last user choices - click to view the 
			current parameters state and switch back to view last user choices
			for the the plugin / FX container currently in focus;  
			when the menu is switched to 'current state', no management 
			operations are possible because this is purely monitoring mode to 
			compare user choices with parameters current state; the option is 
			disabled when user choices don't differ from the current state;
			on load this option automatically switches to 'View last user choices'


			Unlike parameter user choices whose storage in between script 
			executions depends on KEEP_USER_CHOICES setting below, options are 
			stored in the memory for the duration of REAPER session and recalled 
			at each script execution.


			SHOWING/HIDING CONTAINER FX PAREMETERS IN THE TCP

			Unlike with FX in the main FX chain, for FX inside containers
			(un)chekmarking parameters in the menu doesn't prime them for 
			being shown/hidden in the TCP but rather for being mapped across 
			the entire container hierarchy. In order to be able to set them
			shown/hidden in the TCP enable the option  
			'Show/Hide container FX parameters in TCP'  
			in the OPTIONS submenu.  
			When enabled, parameters already mapped across container
			hierarchy can be shown/hidden in the TCP, while parameters not yet 
			mapped across containers can be mapped and shown in one go.			
			Unchecking parameters in the menu will not affect their mapped state, 
			only their visibility in the TCP.  			
			When the menu is auto-reloaded after user choices have been applied
			with the APPLY button, names of all parameters mapped across
			container hierarchy will be checkmarked (as they're designed to be)
			while presence of the indicator reflecting parameter visibility in 
			the TCP will depend on the results of the operation just performed.
			!!! While the option is enabled aliases can only be applied/cleared
			along with parameter visibility state. To be able to apply aliases 
			only it must stay disabled.


			The script doesn't support hash (#) and exclamation mark (!) 
			as a leading character in default paremeter names because they will 
			interfere with the menu functionality. So if these are present, they 
			will be stripped off. These characters are however supported 
			in parameter aliases.  
			For the same reason the pipe (|) character is replaced with slash (/)
			in default parameter names and in aliases created using REAPER's 
			built-in 'Alias parameter' functionality, but they're not supported 
			in aliases created with this script.

			Where more than one option is supported option status numeric
			indicators are displayed in the OPTIONS submenu title.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character 
-- between the quotes to make the script store
-- last user choices for focused FX in between script 
-- executions and recall them on load;
-- MAY BE CONFUSING IF YOU HAPPEN TO FORGET THAT
-- YOU DIDN'T APPLY YOUR LAST CHOICES BEFORE EXITING
-- THE SCRIPT MENU AND ASSUME THAT ON LOAD IT REFLECTS
-- THE ACTUAL PARAMETER STATE IN REAPER;
-- to distingush between user choices and actual parameter
-- state look at APPLY menu item, if it's grayed out
-- the menu reflects the actual parameter state in REAPER
-- otherwise it shows last user choices;
-- if in between script runs parameter state is changed 
-- by means other than this script, stored user choices 
-- are cleared and the menu will show parameter latest state;
-- if disabled or invalid, user choices are cleared 
-- immediatedly at the menu exit
KEEP_USER_CHOICES = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
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


local r = reaper


function no_undo()
do return end
end


function validate_sett(sett, is_literal)
-- validate setting, can be either a non-empty string or any number
-- is_literal is boolean to determine the gsub pattern
-- in case literal string is used for a setting, e.g. [[ ]]

-- if literal string is used for a setting it may happen to contain 
-- implicit new lines which should be accounted for in evaluation
local pattern = is_literal and '[%s%c]' or ' '
return type(sett) == 'string' and #sett:gsub(pattern,'') > 0 or type(sett) == 'number'
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
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
	--	local mon_fx = retval == 0 and mon_fx_num >= 0
	--	local fx_num = mon_fx and mon_fx_num + 0x1000000 or fx_num -- mon fx index

	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well
		
		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm} or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num)		
		local fx_name, _ = fx_alias
		-- in builds older than 6.31 fx_name return value will be indentical to fx_alias
			if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.31 then
			local ret
			ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
			fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
			or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
			end

		return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_alias, fx_name, fx_GUID -- tr_num = -1 means Master;
		end

	else -- supported since v7.0
	
	local retval, tr_num, itm_num, take_num, fx_num, parm_num = reaper.GetTouchedOrFocusedFX(1) -- 1 focused mode // parm_num only relevant for querying last touched (mode 0) // supports Monitoring FX and FX inside containers, container itself can also be focused
	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = tr and r.GetTrackMediaItem(tr, itm_num)
	local take = item and r.GetTake(item, take_num)
	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well
		
		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm} or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID, is_cont = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num), GetIOSize(obj, fx_num) == 8
		local ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
		fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
		or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor or Container

		local input_fx, cont_fx = tr and r.TrackFX_GetRecChainVisible(tr) ~= -1, fx_num >= 33554432 -- or fx_num >= 0x2000000 // fx_num >= 0x1000000 or fx_num >= 16777216 for input_fx gives false positives if fx is inside a container in main fx chain hence chain visibility evaluatiion
		local mon_fx = retval and tr_num == -1 and input_fx

		return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, input_fx, cont_fx, is_cont -- tr_num = -1 means Master
		end

	end

end


local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, env = table.unpack(t)
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
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



function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local sws_ext_err_mess = "      The size of the track data requires\n\n  the SWS/S&M extension to handle them.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
local sws_ext_link = 'Get the SWS/S&M extension at\n\nhttps://www.sws-extension.org/\n\nOR\n\nhttps://github.com/reaper-oss/sws/tags'
local resp = r.MB(sws_ext_err_mess,'ERROR',0)
	if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end



local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, env = table.unpack(t)
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



function Get_FX_Chunk(obj, obj_chunk, fx_idx, take_idx)
-- obj is track or item pointer; 
-- if no take_idx arg is supplied, the active take will be used;
-- for track input FX and Mon FX fx_idx argument must look like 
-- fx_idx+0x1000000 or fx_idx+16777216; 
-- relies on Esc() function
-- since REAPER 7 'WAK 0 0' may be followed by PARALLEL 1 or PARALLEL 2 
-- if 'Run selected FX in parallel with previous FX' 
-- or 'Run selected FX in parallel with previous FX (merge MIDI)' 
-- options are enabled respectively;
-- due to introduction of FX containers in REAPER 7 
-- 'WAK 0 0' and 'PARALLEL X' tokens can be found in FX container chunk 
-- and the function may return incomlete chunk 
-- not having reached the end of the chain

local track = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local take = item and (take_idx and r.GetTake(obj, take_idx) or r.GetActiveTake(obj))

local GetFXGUID, GetIOSize = table.unpack(take and {r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize} or {r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize})

local obj = track and obj or take

local MON_FX = obj == r.GetMasterTrack(0) and fx_idx >= 16777216 -- OR 0x1000000

	if MON_FX then
	local path = r.GetResourcePath()
	local sep = r.GetResourcePath():match('[\\/]+') -- or package.config:sub(1,1)
	local f = io.open(path..sep..'reaper-hwoutfx.ini', 'r')
	obj_chunk = f:read('*a') -- not global so isn't accessible outside of the function
	f:close()
	end

local target_fx_GUID = obj and fx_idx and GetFXGUID(obj, fx_idx)

	if not target_fx_GUID then return end
	
local fx_container = GetIOSize(obj, fx_idx) == 8
local patt = fx_container and '.+\n(FLOATPOS.-'..Esc(target_fx_GUID)..'.-WAK.-)\n' 
or '.+\n(BYPASS %d %d[%s%d]*.-'..Esc(target_fx_GUID)..'.-WAK.-)\n' -- in older REAPER versions BYPASS only has 2 flags; originally the capture was ending with 'WAK %d %d', but was changed to accommodate possible expansion of flags in the future

return obj_chunk:match(patt)

end


function Get_FX_All_Parent_Containers(obj, fx_idx) -- used inside APPLY_parm_aliases_across_containers() and in the main routine
-- supported since build 7.06

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

	if fx_idx > 0x2000000 and (tr or take) then -- range fx inside containers, or > 33554432
	local GetConfigParm = tr and r.TrackFX_GetNamedConfigParm or take and r.TakeFX_GetNamedConfigParm
	local t, retval = {}	
		repeat
		retval, fx_idx = GetConfigParm(obj, fx_idx, 'parent_container')
			if retval then
			table.insert(t, 1, fx_idx+0) -- inserting always at index 1 so that the order is from the outermost contanter to the innermost object
			end
		until not retval -- or #fx_idx == 0
	return t
	end

end



function GetSetClear_FX_Parm_Mapping_Across_Containers(obj, fx_idx, parm_idx, parent_cont_t, set)
-- up to the outermost;
-- only works for container fx;
-- fx_idx is index of target container fx;
-- parm_idx is index of the target container fx parameter;
-- parent_cont_t is optional, a table of all parent containers 
-- stored from the outermost to the innermost, comes from Get_FX_All_Parent_Containers()
-- if empty or invalid it will be created inside this function;
-- set arg: 1 or any valid value apart from 2 - map parameter across all containers (set), 
-- 2 - unmap parameter across all containers (clear),
-- integers 1, 2 were opted for because relying on booleans true/false 
-- gets tricky in ternary expression
-- where false is diffucult to assign reliably due to its being weak value
-- i.e. expression local mode = a and not b and true or not a and b and false or nil
-- instead of false will always fall back on nil,
-- otherwise (nil) run in get mode,
-- i.e. evaluate whether parm_idx is mapped across all containers;
-- function is supported since build 7.06

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

	if fx_idx > 0x2000000 and (tr or take) then -- range fx inside containers, or > 33554432
	local GetConfigParm = tr and r.TrackFX_GetNamedConfigParm or take and r.TakeFX_GetNamedConfigParm
	local parent_cont_t = parent_cont_t and #parent_cont_t > 0 and parent_cont_t or {}
		if #parent_cont_t == 0 then -- collect parent container indices
		local fx_idx, retval = fx_idx
			repeat
			retval, fx_idx = GetConfigParm(obj, fx_idx, 'parent_container')
				if retval then
				table.insert(parent_cont_t, 1, fx_idx+0) -- store in descending order, from the outermost to the innermost container
				end
			until not retval -- or #fx_idx == 0
		end
		if #parent_cont_t > 0 then -- map across containers or collect data for unmapping and unmap or find it mapped across containers
		local child_cont_idx, mapped_parm_idx = fx_idx, parm_idx -- assign current fx parameters to variables which will be updated during the loop // parm_idx is 0-based
		local map_t = set ~= 1 and {} -- initialize to collect indices associated with parameter across all containers // use separate table because if a table passed as parent_cont_t arg has this exact name, it will be modified and likely unusable for further operations outside the function
		-- first current fx parameter is mapped to its parent container parameter list
		-- and then this parameter is mapped across containers using its index in the child container parameter list
			for i = #parent_cont_t,1,-1 do -- loop in reverse because container indices are stored from the outermost to the innermost and it's the innermost container which parameter of an fx inside a container must be mapped to first so that there's something to map to further up the chain
			local cont_idx = parent_cont_t[i]
			local parmname = 'container_map.'..(set and 'add.' or 'get.')..child_cont_idx..'.'..mapped_parm_idx -- this parameter must be applied to container therefore the 2nd argument in GetConfigParm is always container index // in the very first cycle child_cont_idx is parent container of the fx whose index is passed as fx_idx, in subsequent cycles it's always a child container of container at cont_idx
			retval, mapped_parm_idx = GetConfigParm(obj, cont_idx, parmname) -- return mapped parameter index associated with it in the parent container parameter list, for the next cycle to map it to next parent container
				if not set and not retval then return -- if set is nil, i.e. get mode, retval being false means that parameter mapping hasn't reached the current (cont_idx) container, i.e. it's not mapped across all containers, therefore abort as there's no point to continue
				elseif set ~= 1 then -- collect parameter indices associated with parameter list of each container for unmapping or returning to the main routine
				map_t[i] = {cont_idx=cont_idx, parm_idx=mapped_parm_idx}
				end
			child_cont_idx = cont_idx -- update for the next cycle, for the next container (one level above current) current one becomes child
			end
			if not set then return true, map_t -- if set is nil, i.e. get mode, return true if the loop above wasn't aborted preemptively, which means that the parameter is mapped across ALL parent containers, plus return table with the parameter data
			elseif set == 2 then -- unmap parameter across all parent containers
				for k, data in ipairs(map_t) do -- here loop directly because unmapping must be performed in the order opposite to mapping, i.e. from the outermost container down to the innermost
				GetConfigParm(obj, data.cont_idx, 'param.'..data.parm_idx..'.container_map.delete')
				end
			end
		end
	end

end



function Get_FX_Parm_Orig_Name_s(obj, fx_idx, parm_idx)
-- in case it's been aliased by the user
-- obj is track or take;
-- if parm_idx is valid, returns name of parameter 
-- at parm_idx, otherwise collects
-- all parameter names;
-- works with builds 6.37+ since which original non-aliased
-- fx name can be retrieved for use in TrackFX_AddByName()


local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetConfig = tr and r.TrackFX_GetNamedConfigParm or take and r.TakeFX_GetNamedConfigParm
-- get fx name displayed in fx browser
local retval, fx_name = GetConfig(obj, fx_idx, 'original_name') -- or 'fx_name'
-- insert temp track
r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
-- insert FX instance on the temp track
-- the fx names retrieved with GetNamedConfigParm() always contains fx type prefix,
-- the function FX_AddByName() supports fx type prefixing but in the retrieved fx name
-- the fx type prefix is followed by space which wasn't allowed in FX_AddByName()
-- before build 7.06 so it must be removed, otherwise the function will fail
-- https://forum.cockos.com/showthread.php?t=285430
fx_name = fx_name:gsub(' ','',1) -- 1 is index of the 1st space in the string
r.TrackFX_AddByName(temp_track, fx_name, 0, -1) -- insert // recFX 0 = false, instantiate is -1
-- search for the name of parameter at the same index as the one being evaluated
local t, retval, parm_name = {}
	for i = 0, r.TrackFX_GetNumParams(temp_track, 0)-1 do -- fx_idx 0
	retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, i, '') -- fx_idx 0
		if parm_idx and parm_idx > -1 and i == parm_idx then break -- must break rather than return to allow deletion of the temp track before returning the value
		else
		t[#t+1] = parm_name -- 1-based indexing
		end
	end
r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)

return parm_idx and parm_idx > -1 and parm_name, #t > 0 and t

end



function Get_Container_Parm_Source_Props(obj, cont_idx, parm_idx)
-- function is supported since build 7.06

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetIOSize, GetNamedConfigParm, GetNumParams, GetFXName, GetParamName = 
table.unpack(take and {r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, 
r.TakeFX_GetNumParams, r.TakeFX_GetFXName, r.TakeFX_GetParamName}
or tr and {r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetNumParams, 
r.TrackFX_GetFXName, r.TrackFX_GetParamName})

	if GetIOSize and GetIOSize(obj, cont_idx) ~= 8 then return end -- not container

-- container built-in parameters (Bypass, Wet, Delta) follow all mapped parameters, i.e. 3 very last
local ret, src_fx_idx = GetNamedConfigParm(obj, cont_idx, 'param.'..parm_idx..'.container_map.fx_index') -- 0-based index // src_fx_idx is string // returns false and empty string if parm_idx refers to container built-in parameter or is out of range
local parm_cnt = GetNumParams(obj, cont_idx)-1 -- -1 to conform to 0-based parameter indexation

	if not ret and parm_idx > parm_cnt then return -- parm_idx is out of range
	elseif parm_idx > parm_cnt-3 then -- container built-in parameter (Bypass, Wet, Delta)
	local parm_idx = parm_idx - (parm_cnt-3)
	local t = {[1]='Bypass', [2]='Wet', [3]='Delta'}
	return t[parm_idx] -- return original name of a built-in parameter
	else
	local ret, src_fx_idx = GetNamedConfigParm(obj, cont_idx, 'container_item.'..src_fx_idx) -- 0x2000000 based index to be passed to all regular FX functions // src_fx_idx is string
	src_fx_idx = src_fx_idx+0 -- converting index from string into integer
	local ret, src_parm_idx = GetNamedConfigParm(obj, cont_idx, 'param.'..parm_idx..'.container_map.fx_parm') --  src_parm_idx is string
	-- local ret, src_fx_name = GetNamedConfigParm(obj, src_fx_idx, 'original_name') -- or 'fx_name'
	src_parm_idx = src_parm_idx+0 -- converting index from string into integer
	local ret, src_fx_name = GetFXName(obj, src_fx_idx) -- returns aliased instance name if changed by the user; if parameter is mapped from a child container parameter list, returns name of the child container
	--Msg(src_fx_name,'src_fx_name')
	local ret, src_parm_name = GetParamName(obj, src_fx_idx, src_parm_idx) -- if aliased by user returns aliased name; if parameter is mapped from a grandchild container parameter list, returns full path to the parameter starting from grandchild container name, i.e. if source fx resides inside a grandchild container named 'cont123' the returned path will look like 'cont123: src FX name: src parm name'; the aliased path which is returned may be aliased at any level of container hierarchy
	--Msg(src_parm_name,'src_parm_name')
	-- concatenate mapped parameter name as it's supposed to appear in container parameter list in default format which is:
	-- [container1 name]: [container2 name] ...: [FX instance name]: [param name]
	-- when fx is deep within container hierarchy, for each container the parameter name is added container name;
	-- when src_fx_name is not a container name, non-aliased FX instance name is stripped off the plugin type prefix and vendor name
	local cont_parm_format = (src_fx_name:match('^[ADCJLPSTXVi]+:') and (src_fx_name:match('.-: (.-)%s%(') 
	or src_fx_name:match('.-: (.+)')) or src_fx_name)..': '..src_parm_name
	return cont_parm_format, src_fx_idx, src_parm_idx, src_fx_name, src_parm_name
	end

end



function Collect_FX_Parm_Aliases(fx_chunk) -- used inside APPLY_parm_aliases_across_containers() and in the main routine
local t = {}
	for line in fx_chunk:gmatch('[^\n\r]+') do
		if line:match('PARMALIAS') then
		local parm_idx, alias = line:match('PARMALIAS (%d+).- "?(.+)') -- '.-' becase since presumably build 6.48 between index and the alias, parameter identifier (returned by r.Track/TakeFX_GetParamIdent) or VST3/CLAP internal param index can be tucked in separated by a colon
		t[parm_idx+0] = alias:match('[%s#]+') and alias:sub(1,-2) or alias  -- converting index into a number and truncating trailing quotation mark if alias contains spaces or hash (#) because it's captured along with it
		end
	end
return t
end


function Toggle_Option(option, data, output, scr_ID)
local option = option == '1' and '0' or '1'
local i = 0
local data = data:gsub('%d', function() i=i+1; if i==output then return option end end)
r.SetExtState(scr_ID, 'OPTIONS', data, false) -- persist false
end


function APPLY(obj, chunk, fx_chunk, parm_t, shown_parms_t, fx_GUID, want_return)
-- obj is take or track pointer, chunk is object chunk
-- in parm_aliases_t and shown_parms_t field indexing 
-- is 0-based to match parameter original index
-- and hence is not guaranteed to be sequential, 
-- though IS guaranteed to be in ascending order;
-- parameters of fx inside container can be shown
-- in the TCP directly the same way as parameters
-- of fx in the main chain, they are automatically
-- mapped to container and appear in the container
-- 'Show in track controls' submenu and can be turned
-- on and off from there;
-- want_return argument is only relevant for the use of the function
-- inside APPLY_parm_aliases_across_containers()

-- Replacing the entire subchunks by newly concatenated ones 
-- is much simpler than editing them
-- by removing parameters which have been excluded 
-- and adding those which have been included

-- get current parameter aliases data
local aliases_subchunk = ''
	for line in fx_chunk:gmatch('[^\n\r]+') do
		if line:match('PARMALIAS') then		
		aliases_subchunk = aliases_subchunk..(#aliases_subchunk > 0 and '\n' or '')..line
		end
	end
-- create a clean version by removing any parameter identifiers
-- included in the aliases data since about build 6.48,
-- i.e. PARMALIAS 5:_1__Feedback "1: Feedback Alias",
-- to be able to compare it with the aliases data version based
-- on user choices, because the latter ommits identifiers 
-- for the sake of simplicity of handling, which is allowed by REAPER
local aliases_cur_clean = aliases_subchunk:gsub('PARMALIAS %d+:[%w%p]+', function(c) return c:gsub(':[%w%p]+','') end)

-- get current TCP shown parameters data
local tcp_shown_subchunk = fx_chunk:match('(PARM_TCP.+)\n') -- capturing as a whole to be replaced entirely with new, updated or the same data, i.e. without isolation of parameter indices and comparing them to user choices, because the data also contains parameter identifiers making indices isolation inconvenient
-- create a clean version by only including parameter indices
-- that is using older format still supported by REAPER and
-- used by the user choices data, to be able to compare the two
local tcp_shown_cur_clean = {}
	for k in pairs(shown_parms_t) do
	tcp_shown_cur_clean[#tcp_shown_cur_clean+1] = k
	end
table.sort(tcp_shown_cur_clean) -- sort in ascending order because keys in shown_parms_t represening parameter indices aren't necessarily sequential, i.e. likely to have gaps, and the loop above uses pairs iterator because of this and because the first index may happen to be 0 since parameter indices are stored in their original 0-based format, so isn't guaranteed to loop sequentially either
	
local alias_dot = '\xE2\x96\xAA' -- ▪ Black Small Square
local shown_mark = '\xC2\xA4' -- ¤ Currency Sign // indicator for container fx params shown in tcp
local aliases_subchunk_nu, tcp_shown_subchunk_nu = '', ''

	for k, parm_name in pairs(parm_t) do -- works in a not sequential loop as well, REAPER seems to sort indices internally before applying via chunk // using non-sequential iretator to accommodate structure of the table fed from APPLY_parm_aliases_across_containers() function
	local k = k-1 -- convert to 0-based
		if parm_name:match('^.-'..alias_dot) then -- alias indicator is present, aliased
		local shown = parm_name:match('.+ '..shown_mark..'$') -- indicator of container fx param shown in tcp
		local parm_name = (parm_name:sub(1,1) == '!' and parm_name:sub(2) or parm_name):gsub(alias_dot..' ','', 1):gsub(shown and ' '..shown_mark or '', '') -- remove '!' special char signifying checkmark in case the aliased param of main chain fx is also set to be shown in the TCP, an alias indicator and an indicator of container fx param shown in tcp, otherwise only remove the alias indicator		
		aliases_subchunk_nu = aliases_subchunk_nu..(#aliases_subchunk_nu > 0 and '\n' or '')..'PARMALIAS '..k..' '
		..(parm_name:match('[%s#]+') and '"'..parm_name..'"' or parm_name) -- ignoring format introduced in build 6.48 where REAPER specific parameter index is followed by parameter identifier either alphabetic or numeric which is internal to the plugin and enclosing within quotes aliases which contain spaces and hash (#) BECAUSE HASH REQUIRES QUOTES EVEN IF ATTACHED TO A WORD
		end
		if parm_name:sub(1,1) == '!' then -- if parameter of an fx in the main fx chain is checkmarked whether as user choice or as one already shown in the TCP, in the latter case the data will be re-added even if identical, which is easier to handle than limiting the data only to parameters which aren't yet shown, because if all checked parameters are already shown tcp_shown_subchunk_nu var will remain empty and trigger deletion of the shown parameters data from the chunk, but disallowing empty tcp_shown_subchunk_nu var will prevent disabling of all currently shown parameters; comparison between currently shown parameters and user choices to condition processing is inconvenient because the data is mixed, containing both parameter indices and identifiers requiring isolation of numerals representing the indices
		tcp_shown_subchunk_nu = tcp_shown_subchunk_nu..(#tcp_shown_subchunk_nu > 0 and ' ' or '')..k
		end
	end

local chunk_nu = chunk
Msg(aliases_subchunk_nu, 'aliases_subchunk_nu')

	if #(aliases_subchunk_nu..aliases_subchunk) > 0 and aliases_subchunk_nu ~= aliases_cur_clean
	then
	-- if aliases_subchunk is empty string, use fx GUID as an anchor for aliases_subchunk_nu to update the chunk with because GUID is unique
	local GUID = 'FXID '..fx_GUID
	-- is subchunk exists (there're aliased parameters), use the new subchunk as is otherwise attach it to fx GUID
	aliases_subchunk_nu = #aliases_subchunk > 0 and aliases_subchunk_nu or aliases_subchunk_nu..'\n'..GUID	
	aliases_subchunk_nu = aliases_subchunk_nu:gsub('%%', '%%%%') -- or ('%0'):rep(4) as replacement string // escape
	aliases_subchunk = #aliases_subchunk > 0 and aliases_subchunk or GUID
	aliases_subchunk = Esc(aliases_subchunk)
	chunk_nu = chunk_nu:gsub(aliases_subchunk, aliases_subchunk_nu)
	end

	if not want_return and -- the function is also used inside APPLY_parm_aliases_across_containers() where it's only supposed to process parameter aliases, so exclude tcp display routine
	not (#tcp_shown_subchunk_nu == 0 and not next(shown_parms_t)) 
	and tcp_shown_subchunk_nu ~= table.concat(tcp_shown_cur_clean, ' ')
	then
	tcp_shown_subchunk_nu = #tcp_shown_subchunk_nu > 0 and 'PARM_TCP '..tcp_shown_subchunk_nu or ''
		if not tcp_shown_subchunk then
		-- if tcp_shown_subchunk is nil because subchunk doesn't exist (there're no parameters shown in TCP), 
		-- first update the chunk from fx GUID to 'WAK x x' using fx GUID as an anchor because it's unique
		-- having attached new subchunk to WAK attr
		local WAK = fx_chunk:match('WAK %d %d')
		tcp_shown_subchunk = fx_chunk:match(Esc(fx_GUID)..'.-'..WAK)
		-- attach the new subchunk to WAK attr
		tcp_shown_subchunk_nu = tcp_shown_subchunk_nu:gsub('%%', '%%%%')..'\n'..WAK -- or ('%0'):rep(4) as replacement string // escape
		tcp_shown_subchunk_nu = tcp_shown_subchunk:gsub(WAK, tcp_shown_subchunk_nu)
		end
	tcp_shown_subchunk = Esc(tcp_shown_subchunk)
	tcp_shown_subchunk_nu = tcp_shown_subchunk_nu:gsub('%%', '%%%%') -- or ('%0'):rep(4) as replacement string // escape
	chunk_nu = chunk_nu:gsub(tcp_shown_subchunk, tcp_shown_subchunk_nu)
	end
	
	if #chunk_nu > 0 and chunk_nu ~= chunk and not want_return then
	local Validate = r.ValidatePtr
	local tr, take = Validate(obj, 'MediaTrack*'), Validate(obj, 'MediaItem_Take*')
	local SetChunk = tr and r.SetTrackStateChunk or take and r.SetItemStateChunk
	obj = take and r.GetMediaItemTake_Item(obj) or obj
	SetChunk(obj, chunk_nu, false) -- inundo false
	else -- return modified chunk, only relant for the use of this function inside APPLY_parm_aliases_across_containers() when applying parameter aliases data locally, i.e. not across all containers
	return chunk_nu
	end

end



function APPLY_parm_aliases_across_containers(obj, chunk, fx_chunk, fx_idx, parm_t)
-- obj is take or track pointer, chunk is object chunk

	if fx_idx < 0x2000000 then return end -- not an fx container or fx instance inside a container

local Validate = r.ValidatePtr
local tr, take = Validate(obj, 'MediaTrack*'), Validate(obj, 'MediaItem_Take*')
local GetFXGUID, SetChunk = table.unpack(take and {r.TakeFX_GetFXGUID, r.SetItemStateChunk} 
or tr and {r.TrackFX_GetFXGUID, r.SetTrackStateChunk})
local item = take and r.GetMediaItemTake_Item(obj) -- get item for use with Get_FX_Chunk()

-- collect user parameters, sorting them as mapped across containers and non-mapped
-- because they will be processed differently
local parm_name_data = {mapped={}, non_mapped={}}
	for k, parm_name in ipairs(parm_t) do
	local is_mapped = parm_name:sub(1,1) == '!' -- for parameters of container fx checkmark (!) indicates its being mapped across all containers
	local t = parm_name_data[is_mapped and 'mapped' or 'non_mapped']
	local k = is_mapped and k-1 or k -- convert to 0-based if mapped across all containers but keep 1-based index for non-mapped because their index will be converted to 0-based inside APPLY() function
	t[k] = parm_name
	end

local chunk_nu = chunk

	if next(parm_name_data.non_mapped) then -- apply or reset locally using regular method
	local fx_GUID = GetFXGUID(obj, fx_idx)
	chunk_nu = APPLY(obj, chunk, fx_chunk, parm_name_data.non_mapped, {}, fx_GUID, 1) -- shown_parms_t arg is an empty table just to prevent error inside the function, but tcp shown parameters won't be processed there; want_return arg is 1 (true) to prevent setting chunk inside APPLY function
	end

	if next(parm_name_data.mapped) then
	local cont_hierarchy_t = Get_FX_All_Parent_Containers(obj, fx_idx) -- the table contains indices of parent containers of the focused conrainer or fx, from the outermost to the innermost

	-- add focused fx or fx container to cont_hierarchy_t table because it's not included
	cont_hierarchy_t[#cont_hierarchy_t+1] = {index=fx_idx}
	
		for parm_idx, parm_name in pairs(parm_name_data.mapped) do
		cont_hierarchy_t[#cont_hierarchy_t][parm_idx] = parm_name
		end

	-- collect mapped parameter indices per container
	local GetConfigParm = take and r.TakeFX_GetNamedConfigParm or tr and r.TrackFX_GetNamedConfigParm
	local child_idx = fx_idx
		for i = #cont_hierarchy_t-1,1,-1 do -- loop in reverse because parameters are mapped across containers from the innermost to the outermost and in order to retrieve their indices associated with each parent container using 'container_map.get.FXID.PARMIDX' command, their index at the child container must be known; statring the loop from the penultimate field, i.e. #cont_hierarchy_t-1 because in the last field focused fx or fx container data has already been stored above and will be used as child data to retrieve data relevant for current at the current index, i.e. cont_idx below
			if i > 0 then
			local cont_idx = cont_hierarchy_t[i]
			cont_hierarchy_t[i] = {index=cont_idx} -- replace index with the table to store data to
				for parm_idx, parm_name in pairs(cont_hierarchy_t[i+1]) do -- access parameter data of child container or fx, i.e. next in the cont_hierarchy_t table while the table is looped in reverse at the main loop
					if tonumber(parm_idx) then -- ensure that parm_idx var is index and not 'index' field name which are also stored and in a non-sequential loop (pairs) will also be accessed
					local parmname = 'container_map.get.'..child_idx..'.'..parm_idx -- this parameter must be applied to container therefore the 2nd argument in GetConfigParm is always container index
					local retval, mapped_parm_idx = GetConfigParm(obj, cont_idx, parmname) -- return mapped parameter index associated with it in the current container parameter list
					cont_hierarchy_t[i][mapped_parm_idx+0] = parm_name -- store
					end				
				end
			child_idx = cont_idx -- store as child index for the next cycle of the main loop 
			end
		end
		
	local alias_dot = '\xE2\x96\xAA' -- ▪ Black Small Square	
	
		-- apply or reset aliases across all containers and to and at the focused fx object (fx instance or container),
		-- iterating over the focused fx object and all parent containers 
		-- one by one and processing portions of chunk of each in turn,
		-- the logic is that aliases fetched from chunk of fx at fx_idx
		-- are combined or replaced with user choices within parm_t table
		-- and then ovewrite aliases in the original fx chunk inside APPLY() function
		for k, data in ipairs(cont_hierarchy_t) do
		local fx_idx = data.index
		local fx_chunk = Get_FX_Chunk(item or obj, chunk_nu, fx_idx)
		local parm_aliases = Collect_FX_Parm_Aliases(fx_chunk)
		local parm_t = {}
		-- convert 0-based indices to 1-based to conform to APPLY() function logic
			for k, v in pairs(parm_aliases) do
			parm_t[k+1] = alias_dot..' '..v -- store, appending alias indicator so that it's recognized as such inside APPLY() function
			end
		-- add user choices to parm_t table which may contain pre-existing aliases
		-- of other plugins if fx_idx belongs to fx container
		-- so that the entire list which includes current user choices is used as a replacement
		-- if mapped parameters indices match indices of parameters aliased at the container level
		-- these will be replaced with user choices set via this script
			for k, parm_name in pairs(data) do
				if tonumber(k) then -- ensure that k var is index and 'index' field name which are also stored and in a non-sequential loop (pairs) will also be accessed
				parm_t[k+1] = parm_name -- converting into 1-based index to conform to APPLY() function logic and overwriting pre-existing alias data in case indices match
				end
			end
		local fx_GUID = GetFXGUID(obj, fx_idx)
		chunk_nu = APPLY(obj, chunk_nu, fx_chunk, parm_t, {}, fx_GUID, 1) -- shown_parms_t arg is an empty table just to prevent error inside the function, but tcp shown parameters won't be processed there; want_return arg is 1 (true) to prevent setting chunk inside APPLY function
		end		
	end

	if #chunk_nu > 0 and chunk_nu ~= chunk then
	SetChunk(item or obj, chunk_nu, false) -- inundo false
	return true
	end
	
end



function Show_Hide_Cont_FX_Params_TCP(tr, chunk, fx_idx, parent_containers_t, parm_t)

-- get chunk of the outermost container
local cont_idx =  parent_containers_t[1] -- outermost container index
local fx_chunk = Get_FX_Chunk(tr, chunk, cont_idx)

	if fx_chunk then
	-- get current TCP shown parameter data at the outermost container level
	-- local tcp_shown_subchunk = fx_chunk:match('(PARM_TCP.+)\n') -- capturing as a whole to be replaced entirely with new, updated or the same data
	-- collect indices of the shown parameters	
	local shown_t = {}
	local GetConfigParm = r.TrackFX_GetNamedConfigParm
	-- collect parameters of the outermost container
	-- which are shown in the tcp
	local parm_cnt = r.TrackFX_GetNumParams(tr, cont_idx)
		for i=0, r.CountTCPFXParms(0, tr)-1 do
		local retval, fx_idx, parm_idx = r.GetTCPFXParm(0, tr, i)
			if fx_idx == cont_idx then
			shown_t[#shown_t+1] = parm_idx
			end
		end
	
	-- store initial data in case all shown parameters belong to the source fx
	-- and all are set to be hidden, because in this case shown_t will be emptied
	-- completely in the loop below and the initial data will be lost
	local src_subchunk_init = table.concat(shown_t, ' ')	

	-- find matches between parameters of the outermost container
	-- which are shown in the tcp and indices of the mapped parameters
	-- of the focused fx and collect 
	local repl_subchunk = ''
		for k, parm in ipairs(parm_t) do
		local checkmarked = parm:sub(1,1) == '!'
		local is_mapped, map_t = GetSetClear_FX_Parm_Mapping_Across_Containers(tr, fx_idx, k-1, parent_containers_t) -- k-1 to convert param index to the expected 0-based format because indexing in parm_t is 1-based
		local mapped_parm_idx = is_mapped and map_t[1].parm_idx+0 -- convert to integer to reliable compare with parm_idx from shown_t below
			if is_mapped then
			local found
				for k, parm_idx in ipairs(shown_t) do
					if parm_idx == mapped_parm_idx then found = k break end
				end
				if checkmarked and not found then -- include in the replacement data
				local ret, persist_idx = GetConfigParm(tr, cont_idx, 'param.'..mapped_parm_idx..'.container_map.hint_id')
				repl_subchunk = repl_subchunk..(#repl_subchunk > 0 and ' ' or '')..mapped_parm_idx--..':'..persist_idx -- persist_idx IS DISCARDED, SEE EXPLANATION ABOVE
				elseif not checkmarked and found then -- exclude from the list of currently shown parameters			
				table.remove(shown_t, found)
				end
				-- if checkmarked and found, stays as is
			end
		end
		
	local chunk_nu = chunk
	local src_subchunk = table.concat(shown_t, ' ')
	repl_subchunk = src_subchunk..(#src_subchunk > 0 and #repl_subchunk > 0 and ' ' or '')..repl_subchunk -- repl_subchunk will end up being empty if no parameter is shown in tcp and all parameter menu items are unchecked, APPLY button in this case is still functional to allow setting params shown/hidden in tcp freely by (un)checking coresponding menu items // AFTER EMPLOYING tcp_shown_state VAR IN THE MAIN ROUTINE TO PREVENT ACTIVATION OF APPLY BUTTON WHEN THERE'S NOTHING TO APPLY THIS IS NO LONGER TRUE BUT LEAVING JUST IN CASE

		if #(src_subchunk_init..repl_subchunk) > 0 and src_subchunk_init ~= repl_subchunk then -- the latter two vars will end up being equal if no param state has changed in the menu, i.e. no paremeter is checkmarked in the menu, APPLY button in this scenario will still be functional // AFTER EMPLOYING tcp_shown_state VAR IN THE MAIN ROUTINE TO PREVENT ACTIVATION OF APPLY BUTTON WHEN THERE'S NOTHING TO APPLY THIS IS NO LONGER TRUE BUT LEAVING JUST IN CASE
		repl_subchunk = #repl_subchunk > 0 and 'PARM_TCP '..repl_subchunk or ''
		src_subchunk = #src_subchunk_init > 0 and 'PARM_TCP '..src_subchunk_init or ''
			if #src_subchunk == 0 then
			-- if src_subchunk_init is empty because subchunk doesn't exist (there're no parameters shown in TCP), 
			-- first update the chunk from container GUID to 'WAK x x' using container GUID as an anchor because it's unique
			-- having attached replacement subchunk to WAK attr
			local GUID = r.TrackFX_GetFXGUID(tr, cont_idx)
			local WAK = fx_chunk:match('WAK %d %d')
			src_subchunk = fx_chunk:match(Esc(GUID)..'.-'..WAK)
			-- attach replacement_chunk to WAK attr
			repl_subchunk = repl_subchunk:gsub('%%', '%%%%')..'\n'..WAK -- or ('%0'):rep(4) as replacement string // escape
			repl_subchunk = src_subchunk:gsub(WAK, repl_subchunk)
			end
		src_subchunk = Esc(src_subchunk)
		repl_subchunk = repl_subchunk:gsub('%%', '%%%%') -- or ('%0'):rep(4) as replacement string // escape
		chunk_nu = chunk_nu:gsub(src_subchunk, repl_subchunk)
		end
		if #chunk_nu > 0 and chunk_nu ~= chunk then
		r.SetTrackStateChunk(tr, chunk_nu, false) -- inundo false		
		end

	end

end



function sanitize_string_for_menu(name)
-- stripping leading !, #, < and > and replacing all instances of | with slash
-- so that being menu special characters they don't affect 
-- the way string is displayed in the menu
return name:sub(1,1):match('[!#<>]+') and name:sub(2) or name
end


function enabled(opt)
return opt == '1' and '!' or ''
end



function readout(...)
-- vararg is a list of option vars holding strings '1' or '0'
-- in place of irrelevant options false must passed instead of nil
-- so that ipairs loop below doesn't break
local result
	for k, opt in ipairs({...}) do
	result = (result or '')
	..(not opt and '' or opt == '1' and string.char(226,157,181+k)..' ' or string.char(226,145,159+k)..' ') -- Dingbat Negative Circled Digit X OR Circled Digit X, starting from 1, 226,157,182 or 226,145,160 respectively
	-- OR
	-- ..(not opt and '' or opt == '1' and string.char(0xE2,0x9D,B5+k)..' ' or string.char(0xE2,0x91,0x9F+k)..' ')
	end
return result
end


function Create_Submenus_Dynamically(t, limit)
-- meant for creation of a menu with a limited number
-- of items in the main menu in order to fit within the screen height
-- and placing all items in excess inside submenus 
-- accessible from the main menu;
-- t is either a table with values to be displayed as menu items
-- or integer in which case numerals will be used as menu items;
-- limit is integer denoting main menu max item count,
-- if exceeded, for every next menu items count which equals the limit
-- a submenu is created;
-- the main menu is shortened by the number of submenus
-- to accommodate submenu items and prevent exceeding the limit
-- in the main menu itself;
-- if the limit is smaller than the submenu count, 
-- main_menu_cnt var will end up being negative
-- and submenus will be created from the very first menu item;
-- one extra submenu over submenu_count value could be added
-- to accommodate remaining outstanding menu items

local tab = type(t) == 'table'
local max_cnt = tab and #t or t
local int, frac = math.modf(max_cnt/limit)
-- count submenus
local submenu_count = int < 1 and 0 or int + (frac ~= 0 and 1 or 0) - 1 -- if there's fractional part count it as another submenu, because it exceeds the items count limit per submenu, subtract 1 to exclude the main menu items because these don't go into the submenu but this isn't mandatory
local main_menu_cnt = limit-submenu_count -- allocate as many items to the main menu as there're going to be submenus by shortening it by submenu count so that main menu's own item count doesn't exceed the limit when submenus are created // the var will be negative if the limit is smaller than the submenu count
local menu, count = '', 0
	for k=1, max_cnt do
	local v = tab and t[k] or k
	count = k > main_menu_cnt and (count == limit and 1 or count+1) or 0 -- reset once the limit is reached to start next submenu, keeping at 0 while main menu is being concatenated, i.e. as long as main_menu_cnt hasn't been exceeded
	local opening = count == 1 and '>'..k..'-'..(max_cnt-k > limit and k+limit-1 or max_cnt)..'|' or ''
	local closure = count == limit and '<' or ''
	menu = menu..(#menu > 0 and '|' or '')..opening..closure..v
	end
return menu

end


-- MAIN ROUTINE --

	
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, is_input_fx, is_cont_fx, is_cont = GetFocusedFX()

local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local build_7_06 = build >= 7.06
local err = ' FX aren\'t supported'
err = not tr and 'no focused FX' --or item and 'take'..err 
--or is_input_fx and 'track input'..err 
or mon_fx and 'monitoring'..err --or is_cont_fx and 'use fx parameter list \n\n of the top level container'
or is_cont_fx and not build_7_06 and '     container fx \n\n are only supported \n\n    since build 7.06'

	if err then Error_Tooltip('\n\n '..err..' \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end
	
local build_6_37 = build >= 6.37
local alias_dot = '\xE2\x96\xAA' -- ▪ Black Small Square
local shown_mark = '\xC2\xA4' -- ¤ Currency Sign // indicator for container fx params shown in tcp
local parent_containers_t = is_cont_fx and Get_FX_All_Parent_Containers(tr, fx_num)
KEEP_USER_CHOICES = KEEP_USER_CHOICES:match('%S+')


::RELOAD::
	
-- find all parameters of the focused FX
-- whose controls are already displayed in the TCP
local shown_parms_t = {}
	if not take then -- tcp shown params only apply to track fx
		for i=0, r.CountTCPFXParms(0, tr)-1 do
		local retval, fx_idx, parm_idx = r.GetTCPFXParm(0, tr, i)
			if retval and (not is_cont_fx and fx_idx == fx_num 
			or is_cont_fx and fx_idx == parent_containers_t[1]) then -- parameter of the focused fx or of the outermost contrainer of a container fx
			local retval, parm_name = r.TrackFX_GetParamName(tr, fx_num, parm_idx, '')
			shown_parms_t[parm_idx] = parm_name
			end
		end
	end


GetNumParams, GetParamName, GetFXName = 
table.unpack(take and {r.TakeFX_GetNumParams, r.TakeFX_GetParamName, r.TakeFX_GetFXName} 
or tr and {r.TrackFX_GetNumParams, r.TrackFX_GetParamName, r.TrackFX_GetFXName})

-- get all aliased parameters from the chunk
local parm_aliases_t = {}
local retval, chunk = GetObjChunk(item or tr)
local fx_chunk
	if retval ~= 'err_mess' then
	fx_chunk = Get_FX_Chunk(item or tr, chunk, fx_num) --Msg(fx_chunk) do return end
	parm_aliases_t = Collect_FX_Parm_Aliases(fx_chunk)
	else
	Err_mess() return r.defer(no_undo)
	end
	
local options = r.GetExtState(named_ID, 'OPTIONS')
options = #options > 0 and options or (take or is_input_fx) and not is_cont_fx and '1001' or '0001' -- '0011' is defaults, for non-container take and input fx 'edit' is enabled by default and cannot be disabled because that's the only meaningful operation (show/hide in tcp is obviously irrelevant)
local edit, local_params, show_cont_fx_tcp, user_choices = options:match('(%d)(%d)(%d)(%d)')
edit = (take or is_input_fx) and not is_cont_fx and '1' or edit -- keep edit always enabled for non-container take and input fx because that's the only meaningful operation

-- collect last user choices
local last_stored = r.GetExtState(named_ID, fx_GUID)
local parm_t_user = {}
	if #last_stored > 0 and user_choices ~= '0' then -- user_choices == 0 when the option 'View current state' is enabled
	last_stored = last_stored..'\n'
		for parm_name in last_stored:gmatch('(.-)\n') do
		parm_t_user[#parm_t_user+1] = parm_name
		end
	end
	
-- collect parameter current properties, the data is used
-- at the initial stage when no user choices have been stored as extended state (below)
-- and for comparison with the stored user choices
local last_state = KEEP_USER_CHOICES and r.GetExtState(named_ID, 'LAST: '..fx_GUID)
local parm_t_cur = {}
local tcp_shown_state -- used to evaluate parameters state with regard to being shown in the tcp to condition activation of APPLY button
	for i=0, GetNumParams(take or tr, fx_num)-1 do
	local retval, parm_name = GetParamName(take or tr, fx_num, i, '')
	-- add checkmark to parameter name of fx in the main fx chain if it's already displayed in the TCP
	-- and to parameter name of fx inside container or of child fx container if it's mapped across
	-- container hierarchy,
	-- and mark it as aliased if relevant
	local mapped, map_t = GetSetClear_FX_Parm_Mapping_Across_Containers(take or tr, fx_num, i, parent_containers_t)
	local shown = (not is_cont_fx and shown_parms_t[i] and shown_parms_t[i] == parm_name 
	or is_cont_fx and mapped) and '!' or ''
	local shown_cont_fx = is_cont_fx and map_t and shown_parms_t[map_t[1].parm_idx+0] and ' '..shown_mark or '' -- +0 to convert to indegere because parm_idx data is string
	local aliased = parm_aliases_t[i] and alias_dot..' ' or ''
	local is_user_checked = parm_t_user[i+1] and parm_t_user[i+1]:sub(1,1) == '!'
	tcp_shown_state = tcp_shown_state or #parm_t_user > 0 and (#shown_cont_fx == 0 and is_user_checked 
	or #shown_cont_fx > 0 and not is_user_checked) 
	or #parm_t_user == 0 and mapped and #shown_cont_fx == 0 -- tcp_shown_state evaluates to truth when there're stored user choices if at least one container fx parameter is checkmarked but NOT shown in tcp or NOT checkmarked but shown in tcp OR when there's a mapped parameter not shown in tcp while there're no stored user choices, i.e. at the very first script execution during session or right after applying user choices (because in this case they're cleared) (#parm_t_user == 0), otherwise will evaluate to false because the menu will reflect the actual parameters state, so nothing to apply

	-- with sanitize_string_for_menu() stripping leading special characters
	-- if parameter name is not aliased and not checkmarked
	-- because if it is, the indicators push them from the 1st positon 
	-- so they can't affect the menu rendering, replacing pipe with slash always,
	-- and stripping alias and shown in tcp (shown_mark) indicator characters if they
	-- happen to feature in a default parameter name at the same position, 
	-- so these aren't confused with indicators added by the script
	parm_name = (#(shown..aliased) > 0 and parm_name or sanitize_string_for_menu(parm_name)):gsub('|', '/')	
	parm_name = parm_name:match('^'..alias_dot) and parm_name:match(alias_dot..'(.+)') or parm_name
	parm_name = parm_name:match('.+'..shown_mark..'$') and parm_name:match('(.+)'..shown_mark) or parm_name
	parm_t_cur[i+1] = shown..aliased..parm_name..shown_cont_fx
	end
	
-- clear user choices if between script executions
-- parameter state was changed by means other than this script
-- so that on load the menu reflects the latest current state
local cur_state = table.concat(parm_t_cur, '\n')
	if KEEP_USER_CHOICES and last_state ~= cur_state then
	r.DeleteExtState(named_ID, fx_GUID, true) -- persist true
	parm_t_user, last_stored = {}, '' -- reset the user choices ext state var and table for evaluations below
	r.SetExtState(named_ID, 'LAST: '..fx_GUID, cur_state, false) -- persist false // update stored current state data
	end

local user_equal_current = #parm_t_user > 0 and table.concat(parm_t_user,'\n') == cur_state
tcp_shown_state = is_cont_fx and not take and not is_input_fx and show_cont_fx_tcp == '1' and tcp_shown_state -- will condition APPLY button activation for track main fx chain if user_equal_current is false and show/hide option is enabled, i.e. there're parameters which can be shown in / hidden from tcp

-- gray out APPLY option if no last stored user choices, the switch isn't set to display user choices and user choices are equal to the current state OR no parameter can be shown in / hidden from tcp because either all shown are checkmarked or all hidden are uncheckmarked so nothing to apply
local apply = user_choices ~= '0' and (tcp_shown_state
or (is_cont_fx and show_cont_fx_tcp ~= '1' or not is_cont_fx) and #last_stored > 0 and not user_equal_current) and '' or '#'

local switch = '4. View '
switch = user_choices == '1' and switch..'current state' or switch..'last user choices'
switch = (#last_stored == 0 and '#' or '')..switch

local grayout = user_choices == '1' and '' or '#'
local readout = is_cont_fx and readout(edit, local_params, not take and not is_input_fx and show_cont_fx_tcp, user_choices) or readout(not take and not is_input_fx and edit, false, false, user_choices) -- for track main fx chain only 'edit parameter names' and 'view state' readouts are shown; for container fx in take and track input fx chains 'show/hide container fx parameters in tcp' readout isn't shown because of being irrelevant and the actual option being disabled; for track input and take main fx chain only 'view state' readout is shown, 'edit parameter names' is active always hence not shown

local options_menu = '>OPTIONS '..readout..'|'..grayout..enabled(edit)..'1. Edit parameter names||'
..(is_cont_fx and grayout or '#')..enabled(local_params)..'2. Apply parameter names locally||'
..(not take and not is_input_fx and is_cont_fx and (grayout..enabled(show_cont_fx_tcp)) or '#')
..'3. Show/Hide container FX parameters in TCP||' -- the option is disabled for take / input fx and main fx chain fx because the latter are set shown/hidden in tcp by dint of being (un)checkmarked
..'<'..switch..'||'..apply..'APPLY||'
local parm_t = #parm_t_user > 0 and parm_t_user or parm_t_cur
local menu = options_menu..Create_Submenus_Dynamically(parm_t, 25)
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then 
		if not KEEP_USER_CHOICES then
		r.DeleteExtState(named_ID, fx_GUID, true) -- persist true // clear user choices at menu closure
		end
	Toggle_Option('0', options, 4, named_ID) -- re-enable user_choices option (index 4) on menu exit by passing disabled value (0) in case the menu was exited when it was swithed to showing current state, because when KEEP_USER_CHOICES is false and user choices are cleared on menu exit while options are stored, when it's called again the shown state is current and displaying 'View current state' menu option won't make sense
	return r.defer(no_undo)
	elseif output == 1 and (not take and not is_input_fx or is_cont_fx) then -- edit parameter names option // disallowing turning the option off for non-container take and input fx because that's the only meaningful operation // ALTHOUGH THIS IS REDUNDANT BECAUSE THE PERSISTENT STATE IS ENSURED WTIH 'edit = (take or is_input_fx) and not is_cont_fx and '1' or edit' EXPRESSION ABOVE
	Toggle_Option(edit, options, output, named_ID)
	elseif output < 5 then -- apply param names locally (2) show/hide in tcp (container fx params) (3) and switch states option (4)
	local option = output == 2 and local_params or output == 3 and show_cont_fx_tcp or user_choices
	Toggle_Option(option, options, output, named_ID)
	elseif output < 6 then -- apply (5)
	r.Undo_BeginBlock()
		if is_cont_fx then
		-- if focused fx is inside a container or itself is a child container, (un)map across all containers
			for k, parm_name in ipairs(parm_t) do
			local idx = k-1 -- k-1 to conform parm index to 0-based parameter indexing, because parm_t table is indexed from 1
			local mapped = GetSetClear_FX_Parm_Mapping_Across_Containers(take or tr, fx_num, idx, parent_containers_t) -- 'set' arg is ommitted, i.e. get mode
			local checked = parm_name:sub(1,1) == '!' -- OR parm_name:match('^!')
			local mode = checked and not mapped and 1 or show_cont_fx_tcp == '0' and not checked and mapped and 2 -- only unmap if show/hide in tcp option is disabled to prevent unpamming unchecked parameter names because in this case presence/absence of a checkmark sets parameter for activation/deactivation of disply in tcp // mapped checkmarked parameters will stay mapped, non-mapped checkmarked parameters will be mapped, non-checked will be ignored here so if they're mapped their mapping isn't cleared
				if mode then
				GetSetClear_FX_Parm_Mapping_Across_Containers(take or tr, fx_num, idx, t, mode) -- set
				end
			end
		local retval, chunk = GetObjChunk(item or tr) -- re-get chunk after (un)mapping parameters
		-- apply aliases locally (if item isn't checkmarked) and across containers (if checkmarked)
			if local_params == '0' then
			APPLY_parm_aliases_across_containers(take or tr, chunk, fx_chunk, fx_num, parm_t)
			else
			local chunk_nu = APPLY(take or tr, chunk, fx_chunk, parm_t, shown_parms_t, fx_GUID, 1) -- want_return 1 - true
				if #chunk_nu > 0 and chunk_nu ~= chunk then					
				local obj = take or tr
				local Validate = r.ValidatePtr
				local tr, take = Validate(obj, 'MediaTrack*'), Validate(obj, 'MediaItem_Take*')
				local SetChunk = tr and r.SetTrackStateChunk or take and r.SetItemStateChunk
				obj = take and r.GetMediaItemTake_Item(obj) or obj
				SetChunk(obj, chunk_nu, false) -- inundo false
				end
			end
			if show_cont_fx_tcp == '1' then -- sets container fx params sets paremeters shown/hidden in tcp
			retval, chunk = GetObjChunk(item or tr) -- re-get chunk after aliases processing
			Show_Hide_Cont_FX_Params_TCP(tr, chunk, fx_num, parent_containers_t, parm_t)
			end
		else -- main fx chain fx, applies aliases and sets paremeters shown/hidden in tcp
		APPLY(take or tr, chunk, fx_chunk, parm_t, shown_parms_t, fx_GUID)
		end		
	local ret, fx_name = GetFXName(take or tr, fx_num, '')
	r.Undo_EndBlock('Change '..fx_name..' parameter properties', -1)
	r.DeleteExtState(named_ID, fx_GUID, true) -- persist true // clear user choices after applying // doesn't have to be included in the undo block because after undoing the data will be re-read on script load anyway

	-- define user choices (6+)
	elseif user_choices == '1' and ((take or is_input_fx) and (is_cont_fx or edit == '1') or not take and not is_input_fx) then -- for take and input fx only allow checkmarking container fx params because this is required for applying alias across containers and for non-container fx params only allow aliasing, showing in tcp is obviously not supported for either type, for track main chain fx everything is allowed // operations in menu items are only allowed when 'View last user choices' option is active
	output = output-5 -- offset first 5 menu items
	local name = parm_t[output]
	local checked = name:sub(1,1) == '!'
	local aliased = checked and name:sub(2):match('^'..alias_dot..' ') or name:match('^'..alias_dot..' ')
	local shown = name:match('.+ '..shown_mark..'$')
		if edit == '1' and user_choices == '1' then
		::reload::
		local name = (checked and name:sub(2) or name):gsub(aliased and alias_dot..' ' or '','', 1):gsub(shown and ' '..shown_mark or '', '') -- strip off the checkmark character '!' if checked, alias indicator if already aliased and shown in tcp indicator for container fx parameters
		local caption = 'Alias'..(build_6_37 and ' or empty to restore' or '')
		local ret, alias = r.GetUserInputs('PARAMETER '..math.floor(output)..': '..name, 1, caption..',extrawidth=200', name)
			if alias:match('|') then
			-- pipe isn't supported in aliases but # and ! are 
			-- because they will be preceded by alias indicator and thus will not be the 1st character on the line
			-- which otherwise would make them behave like the menu special characters
			Error_Tooltip('\n\n pipe | character isn\'t supported \n\n ', 1,1) -- caps, spaced
			goto reload
			end
			if alias:match('%S+') then -- not empty		
			local orig_name = build_6_37 and Get_FX_Parm_Orig_Name_s(take or tr, fx_num, output-1) -- -1 to conform to 0-based parameter indexing
			orig_name = orig_name and orig_name:gsub('|','/') -- replace pipes with slash
				if alias ~= name then -- update name if different from current and from the original
				parm_t[output] = (checked and '!' or '')..(alias ~= orig_name and alias_dot..' ' or '')..alias..(shown and ' '..shown_mark or '') -- restoring original checkmark and shown in tcp indicator for container fx params if any, and only adding alias indicator if new name differs from the original // in builds older than 6.37 alias indicator will be added always, even if aliased name happens to match the original one, because there's no way to retrieve the original for comparison
				end
			elseif ret and not alias:match('%S+') then -- empty dialogue submitted
			-- restore original parameter name
				if not build_6_37 then
				-- in older builds restoration of parameter original name 
				-- by submitting an empty dialogue will not be possible
				-- because without the ability to reliably load the plugin for evaluation on a temp track 
				-- from FX browser by addressing its original name (which in older builds cannot be ascertained)
				-- the original parameter name cannot be retrieved	
				Error_Tooltip('\n\n the option requires REAPER 6.37+ \n\n', 1,1) -- caps, spaced
				else
				local orig_name = not is_cont and Get_FX_Parm_Orig_Name_s(take or tr, fx_num, output-1) -- -1 to conform to 0-based parameter indexing
				or Get_Container_Parm_Source_Props(take or tr, fx_num, output-1)
				orig_name = orig_name and orig_name:gsub('|','/') -- replace pipes with slash
					if orig_name and name ~= orig_name then -- store to display when the menu is reloaded
					parm_t[output] = (checked and '!' or '')..orig_name..(shown and ' '..shown_mark or '') -- restoring shown in tcp indicators for main chain fx and for container chain fx 
					end
				end
			end
		elseif edit == '0' then -- toggle checkmark for showing/hiding in the TCP
		parm_t[output] = checked and name:sub(2) or '!'..name
		end
		if parm_t[output] ~= name then -- if user chosen name has changed or checkmark was toggled, update stored data
		r.SetExtState(named_ID, fx_GUID, table.concat(parm_t,'\n'), false) -- pesrist false
		end
	end

goto RELOAD


