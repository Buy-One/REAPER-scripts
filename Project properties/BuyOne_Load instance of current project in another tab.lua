--[[
ReaScript Name: Load instance of current project in another tab
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About: 	Makes REAPER open a new tab and load last SAVED 
		instance of the currently open project in it.

		The feature was introduced natively via action
		in build 7.44
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local retval, projfn = r.EnumProjects(-1) -- -1 = current project // or local projfn = r.GetProjectName(0, '')
r.Main_OnCommand(40859,0) -- New project tab
r.Main_openProject('noprompt:'..projfn) -- noprompt: - don't prompt for saving // here not really necessary because it's a blank tab and the prompt isn't generated anyway





