--[[
ReaScript name: BuyOne_Project list menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Provides an open project list in a menu form 
	allowing selecting them from this menu.
	
	Useful when many projects are open and their 
	exact names are not apparent in the project tab.
	
	Idea by akademie https://forum.cockos.com/showthread.php?t=280658

]]


local r = reaper

function Error_Tooltip(text, caps, spaced, x2) -- caps and spaced are booleans, x2 is integer
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2 = x2 and math.floor(x2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
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
		t[#t+1] = {proj=proj, name=path:match('.+[\\/](.+)%.[RrPp]+') or 'Not saved'}
		end
	i = i+1
	until not proj
	
	if #t == 1 then 
	Error_Tooltip('\n\nonly one project is open\n\n', caps, spaced, x2) 
	return r.defer(no_undo) end
	
local menu = ''
	for k, data in ipairs(t) do
	local check = data.proj == r.EnumProjects(-1) and '!' or ''
	local pad = k < 10 and '  ' or k < 100 and ' ' or ''
	menu = menu..check..pad..k..'. '..data.name..'|'
	end
	

gfx.init('', 0, 0)
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
	
local output = gfx.showmenu(menu) -- menu string

	if output > 0 then
	r.SelectProjectInstance(t[output].proj)
	end

gfx.quit()
	
do return r.defer(no_undo) end


	
	
