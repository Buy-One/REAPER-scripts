--[[
ReaScript name: BuyOne_Project timebase menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v7.46
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script makes the project timebase menu, 
		available since build 7.46 under a transport button
		in v7 themes, accessible for users of v4 - v6 
		themes as well but without making it embedded 
		in the transport.
		
		FYI, besides v7 themes the built-in menu is also 
		accessible by default in classic, v2 and v3 themes.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric
-- character between the quotes
-- to have the menu be only called when
-- the mouse cursor is over the transport,
-- for this to work the script must be run
-- with a shortcut or MIDI/OSC/web control message
DISPLAY_OVER_TRANSPORT = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Show_Menu_Dialogue(menu)
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
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
local old = reaper.GetOS():match('Win') and tonumber(reaper.GetAppVersion():match('[%d%.]+')) < 6.82
-- screen reader used by blind users with OSARA extension may be affected
-- by the absence if the gfx window therefore only disable it in builds
-- newer than 6.82 if OSARA extension isn't installed
-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
local OSARA = reaper.GetToggleCommandState(reaper.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
local init = (old or OSARA) and gfx.init('', 0, 0)
-- open menu at the mouse cursor
-- https://www.reaper.fm/sdk/reascript/reascripthelp.html#lua_gfx_variables
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
return gfx.showmenu(menu)
end


function check(cmdID)
return reaper.GetToggleCommandStateEx(0, cmdID) == 1 and '!' or ''
end


local t = {menu = {
'Project timebase: time',
'Project timebase: beats (position, length, rate)',
'Project timebase: beats (position only)',
'Project timebase: beats (auto-stretch at tempo changes)',
'Project timebase affects MIDI items',
'|Project settings...'
},
cmdID = {43461, 43462, 43463, 43640, 43641, 40021}
}



local x, y = reaper.GetMousePosition()
local retval, info = reaper.GetThingFromPoint(x,y)

local err = reaper.GetAppVersion():match('[%d%.]+')+0 < 7.46 and 'requires reaper 7.46+'
or DISPLAY_OVER_TRANSPORT:match('%S+') and not info:match('trans') and 'not transport'

	if err then
	local x, y = reaper.GetMousePosition()
	reaper.TrackCtl_SetToolTip('\n\n   '..err:gsub('.','%0 '):upper()..' \n\n ', x, y, true) -- topmost true
	return reaper.defer(function() do return end end)
	end

	for k, v in ipairs(t.menu) do
	t.menu[k] = check(t.cmdID[k])..v
	end

	-- When 'Project timebase: beats (auto-stretch at tempo changes)' is enabled
	-- 'Project timebase: beats (position, length, rate)' gets enabled as well
	-- so removing checkmark from the second to match the menu look under the
	-- project timebase button in v7 theme transport, which is also accessible
	-- in classic, v2 and v3 default themes
	if t.menu[4]:sub(1,1) == '!' then
	t.menu[2] = t.menu[2]:sub(2)
	end

-- Action 'Project: Project timebase affects MIDI items' 43641 isn't a toggle
-- the state must be retieved via API
t.menu[5] = (reaper.GetSetProjectInfo(0, 'PROJECT_TIMEBASE_FLAGS', 0, false)&1 == 1 and '|!' or '|')..t.menu[5]

local output = Show_Menu_Dialogue(table.concat(t.menu,'|'))
local act = reaper.Main_OnCommand

	if output > 0 then
	act(t.cmdID[output], 0)
	end

return reaper.defer(function() do return end end)

