--[[
ReaScript name: BuyOne_FX windows - toggle show windows - SETTINGS.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: 	[main=main,midi_editor] .
About:	The script provides settings to modify behavior
		of scripts included in the packages

		BuyOne_FX windows - store and toggle show windows set_META.lua
		BuyOne_FX windows - store and toggle show windows of selected objects_META.lua

		except the 'menu' scripts.

		These settings are global, i.e. affect the scripts 
		behavior across all projects and are stored inside
		reaper-extstate.ini file under
		'BuyOne_FX windows - toggle show settings' section.
		The file is located in the REAPER resource directory.

--]]


local Debug = "1"
--local Debug = not select(2, r.get_action_context()):match('.+[\\/]BuyOne_') -- in public scripts audomatically disabled
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
--	if Debug then -- ONLY IF CONDITIONED BY SCRIPT NAME
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper



function no_undo()
-- do return end
end



function check(sett)
return sett and '!' or ''
end



function settings_explication()
local e = [[
These settings modify behavior of scripts included in the packages:

BuyOne_FX windows - store and toggle show windows set_META.lua

BuyOne_FX windows - store and toggle show windows of selected objects_META.lua

except the 'menu' scripts.


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

❹ Respect selected objects only — only toggle visibility of FX windows
in selected objects.


Settings 1 — 3 only affect FX windows of STORED INACTIVE sets so that 
if the settings change while the set is active, the windows stemming 
from the affected objects could still be closed when the set is deactivated.

Setting 4 only affects scripts included in the package
BuyOne_FX windows - store and toggle show windows set_META.lua
]]
r.MB(e, 'FX windows toggle settings explication', 0)
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



::RELOAD::

local sett = r.GetExtState('BuyOne_FX windows - toggle show settings', 'settings')
sett = #sett == 0 and 0 or sett+0
local t = {}
	for i=0,3 do
	local bit = 2^i
	t[#t+1] = sett&bit == bit
	end

local underscore = '\204\178' -- Combining Low Line U+0332
local settings = check(t[1])..'❶ &S'..underscore..'how window set exclusively|' -- U+2776
..check(t[2])..'❷ &I'..underscore..'gnore muted objects and bypassed chains|' -- U+2777
..check(t[3])..'❸ &R'..underscore..'espect all item takes when all set to play|' -- U+2778
..check(t[4])..'❹ Respect selected &o'..underscore..'bjects only||' -- U+2779
..'(settings explication)'
local output = Reload_Menu_at_Same_Pos(settings, 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo)
	elseif output < 5 then
	t[output] = not t[output] -- toggle
	local bit = 2^(output-1)
	sett = t[output] and sett|bit or sett~bit -- update
	r.SetExtState('BuyOne_FX windows - toggle show settings', 'settings', sett, true) -- persist true
	goto RELOAD
	elseif output == 5 then
	settings_explication()
	goto RELOAD
	end

do return r.defer(no_undo) end







