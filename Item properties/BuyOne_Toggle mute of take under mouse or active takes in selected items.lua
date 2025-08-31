--[[
ReaScript name: BuyOne_Toggle mute of take under mouse or active takes in selected items.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	Out of the box REAPER doesn't provide tools to 
		automatically mute individual takes. It only allows
		having either the active take play or all item takes 
		at once. That's the gap the script aims to fill in.
		
		The script only makes sense when applied
		to multi-take audio items in which 'Play all takes'
		option is enabled.  		
		Muting with the script allows leaving only a selection 
		of takes playing.  			
		The script first targets take under mouse cursor and
		if not found targets active takes in all selected items.
		
		When audio take is muted its waveform disappears.
		
		To ensure immediate effect of muting and unmuting on
		the playback in live setting the script is best used 
		with minimal buffer settings or with buffering disabled 
		at Preferences -> Audio -> Buffering.  
		For example the effect is immediate when 
		'Media buffer size' is set to 0 or if the preference
		'Disable media buffering for tracks that are selected'
		is enabled and the track the item belongs to is selected.
]]


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
-- caps and spaced are booleans, caps doesn't apply to non-ANSI characters
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
--[[ IF USING WITH gfx
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 arguments which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the gfx window
]]
local text = caps and text:upper() or text
local utf8 = '[\0-\127\194-\244][\128-\191]*'
local text = spaced and text:gsub(utf8,'%0 ') or text -- supporting UTF-8 char
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


function Un_Mute_Take(take, scr_name)

local GetSet_String, Set_Val = r.GetSetMediaItemTakeInfo_String, r.SetMediaItemTakeInfo_Value
local ret, ext_data = GetSet_String(take, 'P_EXT:'..scr_name, '', false) -- isSet false
local midi_take = r.TakeIsMIDI(take)
local param = midi_take and 'D_VOL' or 'I_CHANMODE'
local value = r.GetMediaItemTakeInfo_Value(take, param)
local diff = #ext_data > 0 and (midi_take and value ~= 0 or not midi_take and value ~= 257)

	if #ext_data == 0 or diff then -- mute if the take hasn't been muted yet, is unmuted (in both cases extened data will be absent) or user changed the value manually after muting
	value = r.GetMediaItemTakeInfo_Value(take, param)
	Set_Val(take, param, midi_take and 0 or 257) -- if midi take set volume (velocity in this case) to 0 which is -Inf, else set channel index to 257 which is the max stereo channel index, opted for because a file with that many channels is unlikely to be encountered in real life, 258 cannot be used because it exceeds supported range // setting volume to 0 could be used for audio takes as well as a means of muting
	GetSet_String(take, 'P_EXT:'..scr_name, value, true) -- isSet false // store original channel mode to be able to unmute
	else -- unmute
	Set_Val(take, param, ext_data+0)
	GetSet_String(take, 'P_EXT:'..scr_name, '', true) -- clear extended data
	end

r.UpdateItemInProject(r.GetMediaItemTake_Item(take)) -- update graphics so that the waveform within take disappers immediately

end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+') -- without path and extension
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, false) -- allow_locked false

local err = not take and r.CountSelectedMediaItems(0) == 0 and ' no take under mouse \n\n and no selected items'
or item and not take and 'empty take is not supported' -- take inserted with the action 'Item: Add an empty take after/before the active take' which doesn't have a pointer

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 10) -- caps, spaced true, x is 10 to move the tooltip away from under the cursor because it blocks clicks while stays on
	return r.defer(no_undo)
	end


r.Undo_BeginBlock()

local count, undo = 0, ''

	if take then
	Un_Mute_Take(take, scr_name)
	undo = 'take under mouse'
	else
	-- REAPER devs don't recommend using CountSelectedMediaItems()
	-- and GetSelectedMediaItem in favor of CountMediaItems()
	-- and IsMediaItemSelected() instead
	-- https://forum.cockos.com/showthread.php?p=2807092#post2807092
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local take = r.GetActiveTake(item)
			if take and r.IsMediaItemSelected(item) then -- if take was inserted with the action 'Item: Add an empty take after/before the active take' or the item is an empty one, take doesn't have a pointer
			Un_Mute_Take(take, scr_name)
			count = count+1
			end
		end
	undo = 'active takes in selected items'
	end

	if not take and count == 0 then
	Error_Tooltip('\n\n no valid active takes \n\n    in selected items \n\n', 1, 1) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo)
	end

r.Undo_EndBlock('Toggle mute '..undo,-1)


