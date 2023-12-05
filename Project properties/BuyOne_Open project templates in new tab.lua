--[[
ReaScript name: BuyOne_Open project templates in new tab.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: v1.1 #Made project templates open anonymously as they should
Licence: WTFPL
REAPER: at least v5.962
About: 	An alternative to REAPER's native 'Project templates' submenu  
	which opens project template in a new tab.

	Also allows opening in another tab an instance of an already open
	project template which the native option doesn't allow.		

	If the script is run under an opened project template its name won't be 
	checkmarked in the script menu as active because the template is loaded
	anonymously.
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Enable to make the list display titles of project templates set at:
-- File -> Project settings... -> Notes -> Title;
-- if a project template has no title its file name is displayed instead

PROJECT_TITLES = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

function validate_sett(sett) -- can be either a non-empty string or a number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end

function get_proj_title(projpath)

	local function get_from_file(projpath)
	local f = io.open(projpath,'r')
	local cont = f:read('a*')
	f:close()
	return cont:match('TITLE "?(.-)"?\n') -- quotation marks only if there're spaces in the title
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


-- collect project template files
local proj_t = {}
r.EnumerateFiles(r.GetResourcePath(), 0) -- clear cache
local sep = r.GetProjectPath(''):match('[\\/]')
local path = r.GetResourcePath()..sep..'ProjectTemplates'..sep -- last separator isn't necessary but leaving to simplify concatenation with the file name
local i = 0
	repeat
	local proj_file = r.EnumerateFiles(path, i) -- returns file name or nil
		if proj_file and proj_file:match('.+[%.RrPp]+$') then -- excluding files other than .rpp
		proj_t[#proj_t+1] = path..proj_file
		end
	i=i+1
	until not proj_file

PROJECT_TITLES = validate_sett(PROJECT_TITLES)

local _, projfn = r.EnumProjects(-1) -- currently open proj
-- OR r.GetProjectPath('')..r.GetProjectPath(''):match('[\\/]')..r.GetProjectName(0,'')

local menu_t = {}
	for i = 1, #proj_t do
	local name = PROJECT_TITLES and get_proj_title(proj_t[i]) or proj_t[i]:match('.+[\\/](.-)%.[RrPp]+') -- strip away path and extension if either proj title setting isn't enabled or if proj doesn't have a title
	name = proj_t[i] == projfn and '!'..name or name -- adding checkmark to the menu item of the currently open project
	menu_t[#menu_t+1] = name
	end

-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
		if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82 then gfx.init('', 0, 0) end

gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y

local output = gfx.showmenu(table.concat(menu_t, '|'))

local projfn = output > 0 and proj_t[output]:match('!?(.+)') -- remove ! signifying checkmark of an open project in case such project is selected for loading

	if projfn and r.file_exists(projfn) then
	r.Main_OnCommand(40859,0) -- New project tab
	r.Main_openProject('template:'..projfn)
	return r.defer(function() do return end end) end -- prevent generic undo point in case the above error message is displayed

gfx.quit()




