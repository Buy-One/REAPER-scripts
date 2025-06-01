--[[
ReaScript name: BuyOne_Change and store Ruler time unit.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script allows changing Ruler time unit
	from a menu and storing a specific setting
	to be able to re-enable it after it has
	been temporarily changed for example to
	look up marker/region time properties in
	seconds rather than beats.

	The stored setting is project specific and can 
	be different in each project tab just like 
	actual Ruler time unit setting, but for it to 
	be available to a particular project after REAPER 
	restart the project must be saved. 	

	Since REAPER stores last active Ruler time 
	unit in the project file, it may differ from 
	the setting stored by the script if the time 
	unit active at the moment of last project save 
	wasn't stored by the script via clicking 
	'STORE CURRENTLY ACTIVE' menu item.

]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
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


function spaceout(str)
return str:gsub('.', '%0 '):match('(.+) ') -- space out text, trimming trailing space
end


function no_undo()
do return end
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


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function concat_menu(t)
local menu, active, cmdID = ''
	for k, data in ipairs(t) do
	local enabled = r.GetToggleCommandStateEx(0, data[1]) == 1
	cmdID = cmdID or enabled and data[1]
	active = active or enabled and data[2]
	menu = menu..(#menu > 0 and '|' or '')..(active==data[2] and '!' or '')..data[2]
	end
return menu, active, cmdID
end



local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
or scr_name -- if an non-installed script is run via 'ReaScript: Run (last) ReaScript (EEL2 or lua)' actions get_action_context() won't return valid command ID, in which case fall back on the script full path

local unit_t = {
	primary = {
	{40368, 'Seconds'}, -- View: Time unit for ruler: Seconds
	{40365, 'Minutes:Seconds'}, -- View: Time unit for ruler: Minutes:Seconds
	{40370, 'Hours:Minutes:Seconds:Frames'}, -- View: Time unit for ruler: Hours:Minutes:Seconds:Frames
	{40367, 'Measures.Beats'}, -- View: Time unit for ruler: Measures.Beats
	{41916, 'Measures.Beats (minimal)'}, -- View: Time unit for ruler: Measures.Beats (minimal)
	{43205, 'Measures.Fractions'}, -- View: Time unit for ruler: Measures.Fractions // since 7.19
	{40369, 'Samples'}, -- View: Time unit for ruler: Samples
	{41973, 'Absolute frames'}, -- View: Time unit for ruler: Absolute frames
	},
	secondary = {
	{42362, 'Seconds'}, -- View: Secondary time unit for ruler: Seconds
	{42361, 'Minutes:Seconds'}, -- View: Secondary time unit for ruler: Minutes:Seconds
	{42364, 'Hours:Minutes:Seconds:Frames'}, -- View: Secondary time unit for ruler: Hours:Minutes:Seconds:Frames
	{42363, 'Samples'}, -- View: Secondary time unit for ruler: Samples
	{42365, 'Absolute frames'}, -- View: Secondary time unit for ruler: Absolute frames
--	{42360, ''}, -- View: Secondary time unit for ruler: None
	}
}



-- project time mode is stored in TIMEMODE attribute of the .RPP file
-- but it still may differ from the default for the script
-- if the time mode active at the time when the project was last saved
-- wasn't stored as default for the script by clicking 'STORE CURRENTLY ACTIVE AS DEFAULT' menu item

local cur_proj = tostring(r.EnumProjects(-1))

::RELOAD1::
local primary_menu, cur_primary, cmdID_primary = concat_menu(unit_t.primary)
local secondary_menu, cur_secondary, cmdID_secondary = concat_menu(unit_t.secondary)
local ret, default = r.GetProjExtState(0, named_ID, 'DEFAULT_GRID_UNIT') -- stored for each project tab individually
	if ret == 0 then
	-- if project is reloaded before project extended state was stored in the .RPP file
	-- the extended state is reset, so fall back on regular extended state
	default = r.GetExtState(cur_proj..named_ID, 'DEFAULT_GRID_UNIT') -- making section project specific
	end
local cmdID_prim_stored, primary_stored = default:match('(%d+) (.+)\r')
local cmdID_sec_stored, secondary_stored = default:match('\r(%d+) (.+)')
local active = tonumber(cmdID_prim_stored) == cmdID_primary
and tonumber(cmdID_sec_stored) == cmdID_secondary
local menu = ' |'..spaceout('STORED:|')..(active and '•  ' or '')..(primary_stored or spaceout('(empty)'))
..(secondary_stored and ' / '..secondary_stored or '') -- adding dot when currently active settings match the stored
..'||STORE CURRENTLY ACTIVE||'..spaceout('PRIMARY:|')..primary_menu..'||'
..spaceout('SECONDARY:|')..secondary_menu
..'||To disable secondary, click active option'
..'||To re-enable stored click menu item under STORED:'


::RELOAD2::
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then
	elseif output == 3 and cmdID_prim_stored then -- apply default
		if cmdID_prim_stored+0 ~= cmdID_primary then
		ACT(cmdID_prim_stored)
		end
		if cmdID_sec_stored and cmdID_sec_stored+0 ~= cmdID_secondary then -- can be nil if disabled
		ACT(cmdID_sec_stored)
		end
	elseif output < 4 or output > 19 then goto RELOAD2
	elseif output == 4 then -- store as default
	ACT(cmdID_primary); ACT(cmdID_secondary)
	local data = cmdID_primary..' '..cur_primary..'\r'..(cmdID_secondary and cmdID_secondary..' '..cur_secondary or '')
	r.SetProjExtState(0, named_ID, 'DEFAULT_GRID_UNIT', data) -- stored for each project tab individually
	r.SetExtState(cur_proj..named_ID, 'DEFAULT_GRID_UNIT', data, false) -- perist false // store to fall back on in case project file is reloaded before project extended state was stored in it, because this will reset the extended project state
	r.MarkProjectDirty(0)
	elseif output > 5 and output < 14 then -- primary, toggle exclusive
	local output = output-5 -- offset
	ACT(unit_t.primary[output][1])
	elseif output > 14 and output < 20 then -- secondary, both toggle exclusive and auto-toggle
	local output = output-14 -- offset
	local cmdID = unit_t.secondary[output][1] == cmdID_secondary and 42360 -- View: Secondary time unit for ruler: None // if active menu item is clicked toggle associated action to off
	or unit_t.secondary[output][1]
	ACT(cmdID)
	end

	if output > 2 and output < 20 and output ~= 5 and output ~= 14 then
	goto RELOAD1
	elseif output ~= 0 then
	goto RELOAD2
	end

do r.defer(no_undo) end




