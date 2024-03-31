--[[
ReaScript name: BuyOne_Apply TCP layout to selected tracks.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script displays a menu of TCP layouts available
	in the current theme.
	
	It's meant to be used within a custom action with
	any of the track insert actions, such as
	Track: Insert new track
	Track: Insert new track at end of mixer
	Track: Insert new track at end of track list
	Track: Insert multiple new tracks...
	
	and follow such action within the custom action.
]]


local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
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


function Show_Menu_Dialogue(menu)
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
-- the earliest appearence of a particular character in the menu can be used as a shortcut
-- in this case they don't have to be preceded with ampersand '&'
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest appearance in the menu
-- some characters still do need ampresand, e.g. < and >
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
-- screen reader used by blind users with OSARA extension may be affected
-- by the absence if the gfx window herefore only disable it in builds
-- newer than 6.82 if OSARA extension isn't installed
-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
local init = (old or OSARA) and gfx.init('', 0, 0)
-- open menu at the mouse cursor
-- https://www.reaper.fm/sdk/reascript/reascripthelp.html#lua_gfx_variables
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
return gfx.showmenu(menu)
end

local tr_cnt = r.CountSelectedTracks(0)

	if tr_cnt == 0 then
	Error_Tooltip('\n\n no selected tracks \n\n', 1, 1, -30) -- caps, spaced true, x2 -30
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local layout_type = scr_name:match('TCP') or scr_name:match('MCP')

local i, t = 0, {}

	repeat
	local retval, layout = r.ThemeLayout_GetLayout(layout_type, i)
		if retval and #layout > 0 then t[#t+1] = layout	end
	i = i+1
	until not retval

local output = Show_Menu_Dialogue(table.concat(t,'|'))

	if output > 0 then
	r.Undo_BeginBlock()
	local layout = t[output]
		for i = 0, tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		r.GetSetMediaTrackInfo_String(tr, 'P_TCP_LAYOUT', layout, true) -- setNewValue true
		end
	r.Undo_EndBlock('Apply TCP layout "'..layout..'" to selected tracks', -1)
	end












