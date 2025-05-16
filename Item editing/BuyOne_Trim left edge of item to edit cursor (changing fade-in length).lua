--[[
ReaScript name: BuyOne_Trim left edge of item to edit cursor (changing fade-in length).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: Alternative to the native action 
  		 'Item: Trim left edge of item to edit cursor'
  		 which preserves fade length while the script
  		 shortens/lengthens it following movement of
  		 item start.
  		 
  		 If difference between item edge old and new 
  		 time positions is greater than the fade length 
  		 the original fade length is preserved, i.e.
  		 the same fade is re-applied after trimming.
  		 
  		 To be able to use the script as alternative to 
  		 the native action
  		 'Item edit: Trim left edge of item under mouse to edit cursor'
  		 create the following custom action:
  		 
  		 Custom: Trim left edge of item under mouse to edit cursor (trimming fade-in)
  			 View: Move edit cursor to mouse cursor (no snapping)
  			 BuyOne_Trim left edge of item to edit cursor (trimming fade-in).lua

]]


local r = reaper

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	r.ShowConsoleMsg(str)
	end
end


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


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext
local cmd_ID = scr_name:lower():match('trim left edge') and 41305 or scr_name:lower():match('trim right edge') and 41311
local sel_itms_cnt = r.CountSelectedMediaItems(0)

local err = not cmd_ID and 'wrong script name' or sel_itms_cnt == 0 and 'no selected items'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

-- storing selected items to be able to process them
-- one by one selecting them exclusively
-- because native actions affect all selected items at once
-- and if several are selected, while one is processed
-- by the script all the rest will be affected by the action
-- before the script loop reaches them and adjusts their fade

local sel_items = {}

	for i=0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		if r.IsMediaItemSelected(item) then
		sel_items[#sel_items+1] = item
		end
	end


r.Undo_BeginBlock()
r.PreventUIRefresh(1) -- make items selection toggle unnoticeable

r.SelectAllMediaItems(0, false) -- selected false

local FADE_PARM = cmd_ID == 41305 and 'D_FADEINLEN' or 'D_FADEOUTLEN'
local fade_in = cmd_ID == 41305

	for k, item in ipairs(sel_items) do
	r.SetMediaItemSelected(item, true) -- selected true
	local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local edge = fade_in and pos or pos+r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	local fade_len = r.GetMediaItemInfo_Value(item, FADE_PARM)
	r.Main_OnCommand(cmd_ID,0) -- Item edit: Trim left/right edge of item to edit cursor
		if fade_len > 0 then
		local pos_new = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local edge_new = fade_in and pos_new or pos_new+r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local diff = fade_in and edge_new-edge or edge-edge_new
		diff = math.abs(diff) > fade_len and 0 or diff
	--[[ OR
		local diff = edge_new-edge
		diff = math.abs(diff) > fade_len and 0 or diff*(fade_in and 1 or -1)
	  ]]
		-- if difference between item edge coordinates is greater than the fade length
		-- preserve the original fade length
		r.SetMediaItemInfo_Value(item, FADE_PARM, math.abs(fade_len-diff))
		end
	end

	for k, item in ipairs(sel_items) do
	r.SetMediaItemSelected(item, true) -- selected true
	end

r.PreventUIRefresh(-1)
r.Undo_EndBlock(scr_name,-1)



