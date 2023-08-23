--[[
ReaScript name: BuyOne_Project list menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Provides an open project list in a menu form 
	allowing navigating between them via the menu.
	
	Useful when many projects are open and their 
	exact names are not apparent in the project tab.
	
	Idea by akademie https://forum.cockos.com/showthread.php?t=280658

	A bonus custom action

	Custom: Switch to next/previous project tab with mousewheel
	  Action: Skip next action if CC parameter <0/mid
	  Next project tab
	  Action: Skip next action if CC parameter >0/mid
	  Previous project tab
	  
	Code for import into the Main section of the Action list:
	
	ACT 1 0 "d0dee33a246178498417b4586cffa562" "Custom: Switch to next/previous project tab with mousewheel" 2013 40861 2014 40862	
	
	insert into a .txt file, save, change the extension into .ReaperKeyMap, 
	import, bind to mousewheel.

	To reverse scrolling direction swap the actions:
	Action: Skip next action if CC parameter <0/mid
	AND
	Action: Skip next action if CC parameter >0/mid
	inside the custom action
  
]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Insert any alphanumeric character between the quotes
-- to keep the menu open after clicking a menu item
KEEP_OPEN = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

function Error_Tooltip(text, caps, spaced, x2) -- caps and spaced are booleans, x2 is integer
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2 = x2 and math.floor(x2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y, true) -- topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function no_undo()
do return end
end


local t = {}

local i = 0

	repeat
	local proj, path = r.EnumProjects(i)
		if proj then
		t[#t+1] = {proj=proj, name=path:match('.+[\\/](.+)%.[RrPp]+') or 'Unsaved'}
		end
	i = i+1
	until not proj
	
	if #t == 1 then 
	Error_Tooltip('\n\n only one project is open \n\n', 1, 1)  -- caps and spaced are true
	return r.defer(no_undo) end

	
::KEEP_OPEN::

local menu = ''
local cond1, cond2, cond3 = #t < 10, #t < 100, #t >= 100
	for idx, data in ipairs(t) do
	local check = data.proj == r.EnumProjects(-1) and '!#' or ''
	local pad = idx < 10 and (cond1 and '' or cond2 and '  ' or cond3 and '   ') or idx < 100 and cond3 and '  ' or ''
	menu = menu..check..pad..idx..'. '..data.name..'|'
	end


-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82 then gfx.init('', 0, 0) end
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
	
local output = gfx.showmenu(menu) -- menu string

	if output > 0 then
	r.SelectProjectInstance(t[output].proj)
		if #KEEP_OPEN:gsub(' ','') > 0 then goto KEEP_OPEN end
	end

gfx.quit()
	
do return r.defer(no_undo) end


	
