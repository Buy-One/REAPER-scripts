--[[
ReaScript name: BuyOne_Adjust take pitch without preserving length (mousewheel).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main] .
About: 	Alternative to REAPER's built-in take pitch shift
		functionality meant to make item length follow
		take pitch changes rather than keep it fixed like
		REAPER does, so the behavior is similar to regular
		audio resampling without involvement if time stretch
		algos.

		Basically the same as bound to the mouewheel custom action

		--| Action: Skip next action if CC parameter <0/mid
		--| Xenakios/SWS: Nudge item pitch up (resampled) A
		--| Action: Skip next action if CC parameter >0/mid
		--| Xenakios/SWS: Nudge item pitch down (resampled) A

		when Item pitch nudge value is set to 1 at
		Extensions -> SWS/S&M -> Command parameters ... -> Nudges

--]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
	--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or '' -- covers cases when table only contains a single nil entry in which case its length is 0 or a single valid entry in which case its length is 1
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local val, cap = t[i], t[i+1]
			str = str..tostring(cap)..' = '..tostring(val)..'\n'
			end
		end
	reaper.ShowConsoleMsg(str)
	end
end


local r = reaper


function no_undo()
-- do return end
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


function Mousewheel_Or_Shortcut(val)
return math.abs(val) == 15 or mode == 1, val == 63 or mode == 0 -- mousewheel, shortcut or click
end


function pitch_shift(item, take, st)
local Set = r.SetMediaItemTakeInfo_Value
local len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local take = take or r.GetActiveTake(item)
local cur_rate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local preserve_pitch = r.GetMediaItemTakeInfo_Value(take, 'B_PPITCH')
local exp = math.abs(st)/12
local ratio = st > 0 and 2 or st < 0 and 0.5
local rate_at_pitch = cur_rate*(ratio^exp)
	if preserve_pitch == 1 then -- turn off Preseve pitch when changing rate
	Set(take, 'B_PPITCH', 0)
	end
Set(take, 'D_PLAYRATE', rate_at_pitch)
r.SetMediaItemInfo_Value(item, 'D_LENGTH', len/(ratio^exp))
	if preserve_pitch == 1 then -- restore original preserve pitch setting
	Set(take, 'B_PPITCH', preserve_pitch)
	end
end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local mousewheel = Mousewheel_Or_Shortcut(val)
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, true) -- allow_locked true
local err = not mousewheel and ' the script is meant \n\n     to be executed \n\n with the mousewheel'
or item and (not take or r.TakeIsMIDI(take)) and 'invalid take under mouse cursor'
or not item and r.CountSelectedMediaItems(0) == 0 and '  no selected items \n\n\tand no items \n\n under mouse cursor'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 20) -- caps, spaced true, x 20 to move tooltip away from mouse cursor because it blocks it
	return r.defer(no_undo)
	end

local t = {item} -- store item under mouse, if any, to access it in the loop below
	if not item then -- or #t == 0, or not t[1], which will be true if no item under mouse
		-- collect selected items
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local take = r.GetActiveTake(item)
			if r.IsMediaItemSelected(item) and take and not r.TakeIsMIDI(take) then
			t[#t+1] = item
			end
		end
	end

	if #t == 0 then
	Error_Tooltip('\n\n no valid active takes \n\n   in selected items \n\n', 1, 1, 20) -- caps, spaced true, x 20, to move tooltip away from mouse cursor because it blocks it
	return r.defer(no_undo)
	end

local st_step = val > 0 and 1 or -1

r.Undo_BeginBlock()

	for k, item in ipairs(t) do
	pitch_shift(item, take, st_step)
	end

r.Undo_EndBlock('Adjust pitch of '..(take and 'take under mouse cursor'
or 'active takes in selected items')..'by '..st_step..' st', 4) -- flag 4 - items only




