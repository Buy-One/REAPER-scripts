--[[
ReaScript name: BuyOne_Open recent projects in new tab.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog: 	1.4 #Fixed error when VALID_PROJECTS_ONLY setting is disabled and the project file path is inavlid
				#Added menu option to open project in read-only mode (supported since REAPER build 7.74)
			1.3 #Fixed REAPER version evaluation
			1.2 #Added support for display of project title instead 
				of project path or file name, if set in Project settings -> Notes
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About: 
	An alternative to REAPER's native 'Recent projects menu' capable 
	of opening recent projects in a new tab, which in my opinion should 
	be a native feature and has been requested a couple of times:
	https://forum.cockos.com/showthread.php?t=113259 (2012)
	https://forum.cockos.com/showthread.php?t=249615 (2021)
	----------------------------------------------------------
	An alternative to REAPER's native 'Recent projects menu' capable 
	of opening recent projects in a new tab, desisgned before a
	native option was added in build 6.43:  	
	+ Projects: hold shift to open recent project in new project tab   
	
	Can still be used if holding shift isn't viable for some reason.
	
	Also allows opening in another tab an instance of an already open
	project which the native option doesn't allow.  
	https://forum.cockos.com/showthread.php?t=265300
	
	However unlike in the native menu, if project file or path are 
	no longer valid, its entry cannot be cleared from the script menu 
	and will be listed as long as it's present in reaper.ini file.   
	To compensate for this a setting VALID_PROJECTS_ONLY has been added
	to the USER SETTINGS

]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Enable to have the menu only display project file names instead of paths;
-- the feature is supported natively since build 6.57;
-- the max number of projects in the recent project list still depends
-- on the setting at:
-- Preferences -> General -> Maximum projects in recent project list:

PROJECT_NAMES_ONLY = ""

-- Enable to make the list display titles of projects set at:
-- File -> Project settings... -> Notes -> Title;
-- only relevant if PROJECT_NAMES_ONLY setting is enabled;
-- if a project has no title its file name is displayed instead;
-- the feature is supported natively since build 6.57.

PROJECT_TITLES = ""


-- Enable to have the menu only list valid (loadable) projects
-- since the script doesn't allow removing invalid entries from the list
-- as long as they're present in reaper.ini file.

VALID_PROJECTS_ONLY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function no_undo()
-- do return end
end


function validate_sett(sett) -- can be either a non-empty string or a number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function grayout(sett)
return sett and '' or '#'
end


function get_proj_title(projpath)

	local function get_from_file(projpath)
	local f = io.open(projpath,'r')
		if f then
		local cont = f:read('a*')
		f:close()
		return cont:match('TITLE "?(.-)"?\n') -- quotation marks only if there're spaces in the title
		end
	end

local proj_title, retval

local i = 0
	repeat
	local ret, projfn = r.EnumProjects(i) -- find if the project is open in a tab
		if projfn == projpath then retval = ret break end
	i = i+1
	until not ret
	if retval then -- the project is open in a tab // retval is project pointer
		if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.43 then -- if can be retrieved via API regardless of being saved to the project file // API for getting title was added in 6.43
		retval, proj_title = r.GetSetProjectInfo_String(retval, 'PROJECT_TITLE', '', false) -- is_set false // retval is a proj pointer, not an index
		else -- retrieve from file which in theory may be different from the latest title in case the project hasn't been saved
		proj_title = get_from_file(projpath)
		end
	else
	proj_title = get_from_file(projpath)
	end

	return proj_title and proj_title:match('[%w]+') and proj_title -- if there're any alphanumeric chars // proj_title can be nil when extracted from .RPP file because without the title there's no TITLE key, if returned by the API function it's an empty string, when getting, retval is useless because it's always true unless the attribute, i.e. 'PROJECT_TITLE', is an empty string or invalid 

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




VALID_PROJECTS_ONLY = validate_sett(VALID_PROJECTS_ONLY)

-- collect recent project paths
local t = {}
	for line in io.lines(r.get_ini_file()) do
		if line == '[Recent]' then found = true
		elseif found and line:match('%[.-%]') and line ~= '[Recent]' then -- next section
		break end
		if found and line ~= '[Recent]' then -- collect paths excluding the section name
		local projpath = line:gsub('recent%d+=','') -- or line:match('=(.+)') // strip away the key
			if VALID_PROJECTS_ONLY and r.file_exists(projpath) then
			t[#t+1] = projpath
			elseif not VALID_PROJECTS_ONLY then
			t[#t+1] = projpath
			end
		end
	end


PROJECT_NAMES_ONLY = validate_sett(PROJECT_NAMES_ONLY)
PROJECT_TITLES = validate_sett(PROJECT_TITLES)

local _, projfn = r.EnumProjects(-1) -- OR r.GetProjectPath('')..r.GetProjectPath(''):match('[\\/]')..r.GetProjectName(0,'')

local recent_proj_t = {}
local menu_t = {}
	for i = #t,1,-1 do -- in reaper.ini recent projects are listed in descending order, thus table should be reordered
	recent_proj_t[#recent_proj_t+1] = t[i] == projfn and '!'..t[i] or t[i] -- adding checkmark to the menu item of the currently open project
		if PROJECT_NAMES_ONLY then
		local name = PROJECT_TITLES and get_proj_title(t[i]) or t[i]:match('.+[\\/](.-)%.[RrPp]+') -- if not title, strip away path and extension
		menu_t[#menu_t+1] = t[i] == projfn and '!'..name or name -- adding checkmark to the menu item of the currently open project
		end
	end


local menu_t = #menu_t == 0 and recent_proj_t or menu_t -- if PROJECT_NAMES_ONLY is not ON, display full paths in the menu

local read_only_support = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.74
local read_only = 'Open As Read-Only'..(read_only_support and '' or ' (requires builds 7.74+)')

::RELOAD::

local menu = grayout(read_only_support)..read_only..'|||'..table.concat(menu_t, '|')
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

local projfn = output > 1 and recent_proj_t[output-1]:match('!?(.+)') -- remove ! signifying checkmark of an open project in case such project is selected for loading // output-1 to offset read-only toggle option

	if output == 1 then -- toggle read-only
	read_only = read_only:sub(1,1) == '!' and read_only:sub(2) or '!'..read_only
	goto RELOAD
	elseif projfn then
		if r.file_exists(projfn) then
		r.Main_OnCommand(40859,0) -- New project tab
		r.Main_openProject(projfn)
			if read_only:sub(1,1) == '!' then r.GetSetProjectInfo(0, 'READONLY', 1, true) end -- is_set true
		else
		r.MB('The file is not available at the stored path\n\n'..recent_proj_t[output-1]
		..'\n\nEither enable VALID_PROJECTS_ONLY script setting\n\nOR remove invalid project paths at'
		..'\n\nPreferences -> General -> Recent project list display -> Remove missing projects from recent list'
		,'ERROR',0) -- output-1 to offset read-only toggle option
		goto RELOAD
		end
	end 

do return r.defer(no_undo) end -- prevent generic undo point when the menu is exited



