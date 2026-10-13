--[[
ReaScript name: BuyOne_Toggle items sharing the source with take under mouse or active take in selected item - offline.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	This script was needed in order to able to affect
			items sharing the same source with the reference
			take regardless of their take active status,
			as well as to be able to set all conforming items 
			to identical offline state.
			
			None of this is possible with the native actions.

			The offline state effected by the script is forced 
			rather than temporary, meaning if not toggled back
			it's saved with the project and is restored in the 
			next project load, unlike the temporary offline state.
			That's because ReaScript API doesn't allow querying
			the temporary offline state to be able to determine 
			toggle direction.
			
			A use case for the script is updating item source
			file in external editor without exiting the project
			or REAPER but keeping all other items online.			
			
]]



local Debug = "1"
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


function re_store_selected_items(t, keep_last_selected)
-- at the restoration stage when evaluating whether any items
-- were saved into the table, 'if next(t) then' statement is used
-- because the table isn't indexed and 'if #t > 0 then' won't work
	if not t then
	local t = {}
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if r.IsMediaItemSelected(item) then
			t[item] = '' -- dummy entry
			end
		end
	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	return t
	elseif t and next(t) then
		if not keep_last_selected then
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		end
		for item in pairs(t) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	end
r.UpdateArrange()
end



function Get_Take_Source_File(take)
	if take and not r.TakeIsMIDI(take) then
	local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed source and source sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
	src = r.GetMediaSourceParent(src) or src
	local typ = r.GetMediaSourceType(src, '')
		if typ ~= 'EMPTY' then return r.GetMediaSourceFileName(src, ''), typ:match('OFFLINE') end -- to typ string of a media source forced online _OFFLINE_ prefix is added, setting online temporarily with actions
		-- Item: Set selected media temporarily offline; Item: Set all media offline
		-- isn't reflected anywhere in the chunk and the state cannot be queried with the API
	end
end



local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, true) -- allow_locked true
local sel_itm = r.GetSelectedMediaItem(0,0)
local act_take = sel_itm and r.GetActiveTake(sel_itm)
local file, offline = Get_Take_Source_File(take or act_take)

local err = item and 'take under mouse is ' or sel_itm and 'active take in first selected \n\n'
err = item and (not take and err..'empty' or not file and err..'not media')
or not sel_itm and 'no take under mouse \n\n    or selected item' or not act_take and err..'\t\titem is empty'
or not file and err..'\t   item is not media'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local t = {}
local sel_itms_t = re_store_selected_items()

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

	for i=0, r.CountMediaItems(0)-1 do
	r.SelectAllMediaItems(0, false) -- deselect all
	local item = r.GetMediaItem(0,i)
		for i=0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, i)
			if take then
			local cur_file, is_offline = Get_Take_Source_File(take)
				if cur_file == file and (offline and is_offline or not offline and not is_offline) then
				r.SetMediaItemSelected(item, true) -- selected true
				r.Main_OnCommand(42356 ,0) -- Item: Toggle force media offline
				break end -- exit take loop, because the entire item is offlined
			end
		end
	end


re_store_selected_items(sel_itms_t)

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Toggle items sharing the same source offline', 4) -- 4 items flag


