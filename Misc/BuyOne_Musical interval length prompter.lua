--[[
ReaScript name: BuyOne_Musical interval length prompter.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog:   1.2 #Excluded trailing decimal zero from integers
		 #Corrected the title of values dialogue 
		 #Updated About text
	     1.1 #Added options to display ReaDelay Length (musical)
		 and Parameter modulation LFO Tempo sync Speed values
		 #Updated About text
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About:	Displays length of musical divisions in seconds, samples or frames
	for the current BPM as well as values for ReaDelay Length (musical) 
	and Parameter modulation LFO Tempo sync Speed settings. Allows 
	selecting the values for pasting into input fields.
	
	To paste the values into FX parameter fields you may need to use Paste
	option from the right mouse button context menu rather than Ctrl/Cmd+V
	keyboard shortcut. Unless the option 'Send all keyboard input to plug-in'
	is enabled under the FX chain FX menu when the plugin is selected, which
	will allow inserting values with Ctrl/Cmd+V.
	
	The script stores last selected unit per project.

]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu 
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest appearence of a particular character in the menu can be used as a shortcut
-- in this case they don't have to be preceded with ampersand '&'
-- only if particular instance of a character should be used as a shortcut 
-- such character must be preceded with ampresand '&' otherwise it will be overriden 
-- by its earliest appearance in the menu
-- some characters still do need ampresand, e.g. < and >

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
	-- by the absence if the gfx window herefore only disable it in builds 
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


function Music_Div_To_Sec(val)
-- val is either integer (whole bars/notes) or quotient of a fraction x/x, i.e. 1/2, 1/3, 1/4, 2/6 etc
	if not val or val == 0 then return end
return 60/r.Master_GetTempo()*4*val -- multiply crotchet's length by 4 to get full bar length and then multiply the result by the note division
end


function truncate(num, places)
return math.floor(num*(10^places)+0.5)/10^places
end


function trim_trail_zero(num)
return math.floor(num) == num and math.floor(num) or num
end


function Format_Menu_Item(t, i, val_type)
local t2 = {'S','T','D'}
local dec_places = val_type:match('ES') and 0 -- ES is only present in the words 'samples' and 'frames', which are to be rounded off
or val_type == 'SECONDS' and 3 or 4 -- seconds are rounded down to 3 decimal places because that's minimal ms resolution, readelay and param mod values are rounded down to 4 decimal places for precision even though by default the readout values in readelay only display 2 and keep 2 after plugin re-opening
	for k, v in ipairs(t) do
	local div = k == 2 and i > 1 and t2[k]..' [1/'..math.floor(i+i/2)..']' or t2[k] -- format triplet readout
	v = trim_trail_zero(truncate(v, dec_places)) -- trimming trailing decimal zero
	t[k] = div..' — '..v
	end
return table.concat(t, '  ●  ')
end


::RELOAD_1::

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)') -- whole script name without path
local ret, val_type = r.GetProjExtState(0,scr_name,'VAL TYPE')
val_type = #val_type > 0 and val_type or 'SECONDS'
local samples, frames, readelay, parm_mod = val_type == 'SAMPLES', val_type == 'FRAMES', val_type == 'READELAY',
val_type == 'PARM_MOD'
local units = samples and r.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false) -- is_set false
or frames and r.TimeMap_curFrameRate(0) or readelay and 8 or parm_mod and 4 or 1 -- value 8 is used because in ReaDelay Length (musical) setting scale 1 = 1/8, so to adjust it to the whole bar from which the list begins in the descending order to ever more smaller fractions of a bar, it must be initially multiplied by 8, same is true for value 4 of parameter modulation LFO Tempo sync Speed setting in which 1 = 1/4; the last alternative is seconds, no scaling


local t = {}
local i = 1
	while i <= 128 do
	local straight_val = (units == 8 or units == 4) and 1/i or Music_Div_To_Sec(1/i) -- readelay and parm modulation values don't depend on the BPM because it's accounted for by REAPER
	t[#t+1] = {straight_val*units, straight_val/1.5*units, straight_val*1.5*units} -- + triplet and dotted
	i = i*2
	end

local menu, i = '', 1
	for k, tab in ipairs(t) do
	local pad = (' '):rep(5 - #(i..''))
	menu = menu..'1 / '..i..':'..pad..Format_Menu_Item(tab,i,val_type)..(k < #t and '||' or '')
	i = i*2
	end

function check(typ)
return typ and '!' or ''
end

local unit_selector = 'S E L E C T  U N I T :|'..check(val_type == 'SECONDS')..'S E C O N D S (rounded down to 3 decimal places)|'
..check(samples)..'S A M P L E S (rounded off)|'..check(frames)..'F R A M E S (rounded off)|'
..check(readelay)..'R E A D E L A Y [ Length (musical): ]|'
..check(parm_mod)..'PARAMETER MODULATION [ LFO -> Tempo sync -> Speed ]'
menu = ' |'..menu..'| ||'..unit_selector..'||Legend: S — straight  ●  T — triplet  ●  D — dotted||Click menu item to access values'

::RELOAD_2::

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo) end

	if output < 2 or output > 9 and output < 12 -- 2 because the readout starts from menu item 2
	or output > #t+8 then --return r.defer(no_undo) 
	goto RELOAD_1

	elseif output > #t+2 and output <= #t+8 then -- +1 to offset by empty menu item

	local val_type
		if output - #t == 4 then
		val_type = 'SECONDS'
		elseif output - #t == 5 then
		val_type = 'SAMPLES'
		elseif output - #t == 6 then
		val_type = 'FRAMES'
		elseif output - #t == 7 then
		val_type = 'READELAY'
		elseif output - #t == 8 then
		val_type = 'PARM_MOD'
		end
	r.SetProjExtState(0,scr_name,'VAL TYPE',val_type)
	goto RELOAD_1

	else

	gfx.quit()
	local vals = table.concat(t[output-1],',') -- offset since the readout starts from menu item 2
	local tripl = vals:match('%[.-%]') or '' -- empty if 1 bar division
	vals = {vals:match('— ([%.%d]+,).- — ([%.%d]+,).- — ([%.%d]+)')}
	local title = '1/'..math.floor(2^(output-2))..' in '..val_type..' (click OK to return to the list)' -- offset 1 since the readout starts from menu item 2, and 1 more to accurately calculate note notation
	local ret, output = r.GetUserInputs(title, 3, 'Straight,Triplet '..tripl..',Dotted,extrawidth=70', table.concat(vals))
		if not ret then return r.defer(no_undo)
		else goto RELOAD_2
		end

	end






