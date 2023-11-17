--[[
ReaScript Name: BuyOne_Simplify FX names.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: v6.37+
About: Trims FX names in FX chains according to user preferences
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Reload_Menu_at_Same_Pos(menu, OPTION) -- still doesn't allow keeping the menu open after clicking away
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
local init = old and gfx.init('', 0, 0)
-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
	-- ensure that if OPTION is enabled the menu opens every time at the same spot
	if OPTION and not coord_t then -- OPTION is the one which enables menu reload
	coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
	elseif not OPTION then
	coord_t = nil
	end
gfx.x = coord_t and coord_t.x or gfx.mouse_x
gfx.y = coord_t and coord_t.y or gfx.mouse_y
return gfx.showmenu(menu) -- menu string

end



function Simplify_FX_Name(tr, take, recFX, prefix, dev_name, jsfx_filename)

	if tr or take then
	local GetFXName, FXCount, SetConfigParm = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetCount, r.TakeFX_SetNamedConfigParm}
	or {r.TrackFX_GetFXName, r.TrackFX_GetCount, r.TrackFX_SetNamedConfigParm})
	FXCount = recFX and r.TrackFX_GetRecCount or FXCount
	local obj = take or tr
	local fx_cnt = FXCount(obj)
		for i = 0, fx_cnt-1 do
		local _, fx_name = GetFXName(obj, recFX and i+0x1000000 or i, '')
		local simple_name = prefix and fx_name:match('.-: (.+)') or fx_name
		simple_name = dev_name and simple_name:match('(.+) [%(%[]+') or simple_name
		simple_name = jsfx_filename and simple_name:match('.+/(.+)%]') or simple_name
			if simple_name ~= fx_name then
			SetConfigParm(obj, recFX and i+0x1000000 or i, 'renamed_name', simple_name)
			end
		end
	end

end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.37 then
	Error_Tooltip('\n\n   the script is only compatible \n\n with reaper builds 6.37 and later\n\n ', 1, 1)	-- caps, spaced true
	return r.defer(no_undo) end

::RELOAD::

local itm_cnt = r.CountSelectedMediaItems(0) > 0 and r.CountSelectedMediaItems(0) or r.CountMediaItems(0)
local tr_cnt = r.CountSelectedTracks2(0, true) > 0 and r.CountSelectedTracks2(0, true) or r.CountTracks(0) -- wantmaster true

	if itm_cnt + tr_cnt == 0 then

	Error_Tooltip('n\n no objects in the project \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)

	elseif itm_cnt + tr_cnt > 0 then

	state1, state2, state3 = state1 or '', state2 or '', state3 or ''
	local menu = 'Set preferences by clicking them:||'..state1..'Trim prefix, e.g. VST(i): etc.|'
	..state2..'Trim developer name (file path in JSFX)|'..state3..'Only leave JSFX file name||R U N| ||'
	..'Affects FX in selected objects.|If none is selected, then in all objects.'

	local index = Reload_Menu_at_Same_Pos(menu, 1) -- 1 - open at the same pos 

		if index == 0 then return r.defer(no_undo) -- menu closed
		elseif index == 2 then state1 = #state1 == 0 and '!' or '' -- toggle
		elseif index == 3 then state2 = #state2 == 0 and '!' or ''
		elseif index == 4 then state3 = #state3 == 0 and '!' or ''
		end
		if index ~= 5 then goto RELOAD end -- not RUN and not 0

		if #(state1..state2..state3) == 0 then
		Error_Tooltip('\n\n no option has been enabled \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo) end

	TRIM_PREFIX = #state1 > 0
	TRIM_DEV_NAME = #state2 > 0
	ONLY_LEAVE_JSFX_FILENAME = #state3 > 0

	r.Undo_BeginBlock()

		for i = -1, tr_cnt-1 do -- -1 to accont for the Master when no track is selected
		local tr = r.GetSelectedTrack(0,i,true) or r.GetTrack(0,i) or r.GetMasterTrack(0)
			if tr then
			Simplify_FX_Name(tr, take, recFX, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- take, recFX false
			Simplify_FX_Name(tr, take, true, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- recFX true
			end
		end

		for i = 0, itm_cnt-1 do
		local item = r.GetSelectedMediaItem(0,i) or r.GetMediaItem(0,i)
		local take = r.GetActiveTake(item)
		Simplify_FX_Name(tr, take, recFX, TRIM_PREFIX, TRIM_DEV_NAME, ONLY_LEAVE_JSFX_FILENAME) -- tr, recFX false
		end

	r.Undo_EndBlock('Simplify FX names', -1)

	else return r.defer(no_undo)
	end








