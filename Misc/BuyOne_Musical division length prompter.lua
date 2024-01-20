--[[
ReaScript name: BuyOne_Musical division length prompter.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
About:	Displays length of musical divisions in seconds, samples or frames
    		for the current BPM and allows selecting the values for pasting
    		into input fields.
    		
    		To paste values into FX parameter fields you may need to use Paste
    		option from the right mouse button context menu rather than Ctrl/Cmd+V
    		keyboard shortcut.
]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Show_Menu_Dialogue(menu)
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
local init = old and gfx.init('', 0, 0)
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
return gfx.showmenu(menu)
end


function Music_Div_To_Sec(val)
-- val is either integer (whole bars/notes) or quotient of a fraction x/x, i.e. 1/2, 1/3, 1/4, 2/6 etc
	if not val or val == 0 then return end
return 60/r.Master_GetTempo()*4*val -- multiply crotchet's length by 4 to get full bar length and then multiply the result by the note division
end


function truncate(num, places)
local val = num > 0 and 0.5 or 0.05
return math.floor(num*(10^places)+val)/10^places
end


function Format_Menu_Item(t, i, val_type)
local t2 = {'S','T','D'}
local dec_places = val_type:match('[FM]+') and 0 or 3 -- FM only present in the words 'samples' and 'frames', which are to be rounded off, seconds are rounded down to 3 decimal places because that's minimal ms resolution
	for k, v in ipairs(t) do
	local div = k == 2 and i > 1 and t2[k]..' [1/'..math.floor(i+i/2)..']' or t2[k] -- format triplet readout
	v = truncate(v, dec_places)
	v = dec_places == 0 and math.floor(v) or v -- remove trailing decimal zero from sample and frame vals
	t[k] = div..' — '..v
	end
return table.concat(t, '  ●  ')
end


::RELOAD_1::
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)') -- whole script name without path
local ret, val_type = r.GetProjExtState(0,scr_name,'VAL TYPE')
val_type = #val_type > 0 and val_type or 'SECONDS'
local samples, frames = val_type == 'SAMPLES', val_type == 'FRAMES'
local units = samples and r.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false) -- is_set false
or frames and r.TimeMap_curFrameRate(0) or 1 -- the last alternative is seconds, no scaling


local t = {}
local i = 1
	while i <= 128 do
	local straight_val = Music_Div_To_Sec(1/i)
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
..check(samples)..'S A M P L E S (rounded off)|'..check(frames)..'F R A M E S (rounded off)'
menu = ' |'..menu..'| ||'..unit_selector..'||Legend: S — straight  ●  T — triplet  ●  D — dotted||Click menu item to access values'

::RELOAD_2::
local output = Show_Menu_Dialogue(menu)

	if output == 0 then return r.defer(no_undo) end

	if output < 2 or output > 9 and output < 12
	or output > #t+6 then --return r.defer(no_undo) -- 2 because the readout starts from menu item 2
	goto RELOAD_1

	elseif output > #t+2 and output <= #t+6 then -- +1 to offset by empty menu item

	local val_type
		if output - #t == 4 then
		val_type = 'SECONDS'
		elseif output - #t == 5 then
		val_type = 'SAMPLES'
		elseif output - #t == 6 then
		val_type = 'FRAMES'
		end
	r.SetProjExtState(0,scr_name,'VAL TYPE',val_type)
	goto RELOAD_1

	else

	gfx.quit()
	local vals = table.concat(t[output-1],',') -- offset since the readout starts from menu item 2
	local tripl = vals:match('%[.-%]') or '' -- empty if 1 bar division
	vals = {vals:match('— ([%.%d]+,).- — ([%.%d]+,).- — ([%.%d]+)')}
	local title = '1/'..math.floor(2^(output-2))..' in '..val_type..' (click OK to return to the list)' -- offset 1 since the readout starts from menu item 2, and 1 more to accurate calculate note notation
	local ret, output = r.GetUserInputs(title, 3, 'Straight,Triplet '..tripl..',Dotted,extrawidth=50', table.concat(vals))
		if not ret then return r.defer(no_undo)
		else goto RELOAD_2
		end

	end







