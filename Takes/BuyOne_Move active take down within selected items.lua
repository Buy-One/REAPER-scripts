--[[
ReaScript name: BuyOne_Move active take down within selected items.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog:	1.2 #Improved script performance within custom action when
				multiple instances run in close succession
			1.1 #Covered more cases with error messages
				#Made error message conditions more specific
				#Made undo point name more specific
				#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
About:	The script moves active take down within selected items.

		REAPER only offers a stock action to move active take to top:
		Item: Move active takes to top			

		The active take movement wraps around, i.e. once it reaches 
		the bottommost position it moves to top. This mode can be 
		disabled with the FINITE_MOVEMENT setting below.

		Non-selected items grouped with selected items are affected 
		as well if 'Item grouping' option is enabled in REAPER and 
		unless IGNORE_GROUPED_ITEMS setting is enabled in the script
		USER SETTINGS. So you can make the script ignore grouped 
		items by either disabling REAPER's option or by enabling
		the said script setting.  
		If selected items are locked and IGNORE_LOCKED_ITEMS 
		setting is enabled, non-selected items grouped with them 
		will not be processed even if not locked.

		The script can be used alongside its counterpart
		'BuyOne_Move active take up within selected items.lua'
		within a custom action mapped to a mousewheel, so that
		direction of take movement depends on the mousewheel 
		direction:

		Custom: Move active take up or down within selected items:
			Action: Skip next action if CC parameter <0/mid
			BuyOne_Move active take up within selected items.lua
			Action: Skip next action if CC parameter >0/mid
			BuyOne_Move active take down within selected items.lua

		Another custom action possible with this script is an action
		to move the active takes to bottom as an opposite to REAPER's
		native action 'Item: Move active takes to top'.
		There're two ways to achieve that: 

		1. By enabling FINITE_MOVEMENT setting in the USER SETTINGS 
		and packing into a custom action a bunch of this script 
		instances so the active take is sure to reach the bottom, e.g.
		
		Custom: Move active takes to bottom
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			...

		2. By enabling FINITE_MOVEMENT setting dynamically via an 
		ancillary script
		'BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua'
		which enables FINITE_MOVEMENT setting for this script when
		toggled to On, and packing into the custom action a bunch 
		of this script instances so the active take is sure to reach 
		the bottom, e.g.

		Custom: Move active takes to bottom
			Action: Skip next action, set CC parameter to relative +1 if action toggle state enabled, -1 if disabled, 0 if toggle state unavailable.
			Script: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua
			Action: Skip next action if CC parameter >0/mid
			Script: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			Script: BuyOne_Move active take down within selected items.lua
			...
			Action: Skip next action if CC parameter >0/mid
			Script: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert
-- any alphanumeric character between the quotes

-- Enable to prevent wrapping around, i.e. once
-- the active take reaches the bottom position
-- the script cannot continue moving it
FINITE_MOVEMENT = ""


-- Enable to prevent affecting locked items
IGNORE_LOCKED_ITEMS = ""


-- Enable to ignore items grouped with selected items
-- if 'Item grouping' option is enabled in REAPER, so that
-- they're not affected by the script
IGNORE_GROUPED_ITEMS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


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
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or ''
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



function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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



function Move_Active_Take_Within_Item(sel_item, down)
-- down is boolean to move down one take lane rather than up;
-- when take is the topmost or the bottommost the movement
-- wraps around;
-- the function must be applied to each selected item separately
-- because action is involved which affects all selected items
-- simultaneously, so the function must be preceded and followed
-- by storage and restoration of item selection;
-- the function must be executed within the Undo block
-- to prevent creation of undo points by actions
-- of which there'll be several

	local function to_top()
	r.Main_OnCommand(41380,0) -- Item: Move active takes to top
	end

local ACT, Activate = r.Main_OnCommand, r.SetActiveTake
local item = sel_item or r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local act_take_idx = item and act_take and r.GetMediaItemTakeInfo_Value(act_take, 'IP_TAKENUMBER') -- OR r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
act_take_idx = act_take_idx or get_active_take_index_via_chunk(item)
local take_cnt = item and r.CountTakes(item)

	if FINITE_MOVEMENT and (act_take_idx == 0 and not down or act_take_idx == take_cnt-1 and down)
	then return end

local fin, idx
	if not down then -- up
	to_top() -- start out by moving active take to top lane
	fin = act_take_idx > 0 and act_take_idx-1 or take_cnt-1 -- if active take isn't the topmost, after moving it to top, cycle as many times as take count less 2 because it itself and originally previous take which has not taken its place don't need moving to simulate exchange of places between them, otherwise cycle as many times as take count less 1 because it itself doesn't need moving and only waits until as a result of other takes movement in top in turns it ends up at the bottom in a wrap-round fashion relative to its top positon
	idx = act_take_idx > 0 and act_take_idx-1 or take_cnt-1 -- if active take is not the topmost, after moving it to top use prev take index because the originally previous take which has now assumed active take original index don't need moving in order to remain at the active take original position as if it exchanged places with the active take while the order or earlier takes needs to be restored by moving each of them to top in turns; if the active take is the topmost, use bottommsost take index to move to top in turns all takes which follow the active one as they end up at the bottom until the active take itself ends up at the bottom in a wrap-round fashion relative to its top positon
	else -- down
		if act_take_idx+1 < take_cnt then -- if active take is not the bottommost, first move to top the take which follows the active one so the active one replaces its in the take sequence, i.e. moves down
		-- set active the take which follows currently active take, so it can be moved to top with the action
		local take = r.GetTake(item, act_take_idx+1)
			if take then Activate(take)
			else
			ACT(45000+act_take_idx+1, 0) -- use command ID of the action 'Take: Set 1st take active' to calculate command ID corresponding to the take index when take is an empty take inserted with 'Item: Add an empty take before/after the active take' which doesn't have a pointer so cannot be set active with API
			end
		to_top() -- start out by moving the take which follows the active take, to top lane
		fin = act_take_idx -- cycle as many times as the active take index because that's how many take exchanges will have to be made to restore the original order of takes above the active one
		idx = act_take_idx -- use the active take index because when the following take is moved to top above and the active take is moved down one take lane the prevous take assumes active take index, and during cycling the take at the original active take index, i.e. now immediately above it, must be moved up in turn to restore original take order
		else to_top() -- move the bottommost active take to top in a wrap-round fashion
		end
	end
	if fin then -- fin will be nil if the bottomost take was moved down because by this point it will have been placed at its destination at the top in a wrap-round fashion in the code above
		for i=1, fin do
		local take = r.GetTake(item, idx)
			if take then
			Activate(take)
			else
			ACT(45000+idx, 0) -- use command ID of the action 'Take: Set 1st take active' to calculate command ID corresponding to the active take index when take is an empty take inserted with 'Item: Add an empty take before/after the active take' which doesn't have a pointer so cannot be set active with API
			end
		to_top()
		end
	end

-- restore active take active status
	if act_take then
	Activate(act_take)
	else
	local idx = 45000 + (act_take_idx == 0 and not down and take_cnt-1 or act_take_idx == take_cnt-1 and down and 0
	or not down and act_take_idx-1 or down and act_take_idx+1)
	ACT(idx, 0)
	end

r.UpdateItemInProject(item) -- to make re-activated take immediately visible

end


function invalid_takes_excess(item)
-- namely empty takes inserted with 'Item: Add an empty take before/after the active take'
-- cannot be retrieved with GetActiveTake(item) or with GetTake(item, GetMediaItemInfo_Value(item, 'I_CURTAKE'))
-- so cannot be set active via API which is required for moving takes inside Move_Active_Take_Within_Item(),
-- but with actions 'Take: Set X take active' they can
-- however the actions only cover takes 1 through 9
local cntr = 0
	for i=0, r.CountTakes(item)-1 do
		if not r.GetTake(item,i) then cntr = cntr+1 end
	end
return cntr > 9
end


function get_active_take_index_via_chunk(item)
local ret, chunk = r.GetItemStateChunk(item, '', false) -- isundo false
local cntr = 0
	for line in chunk:gmatch('[^\n\r]+') do
		if line:match('^TAKE$') or line:match('^TAKE ')then cntr = cntr+1 end
		if line:match('^TAKE SEL') or line:match('^TAKE NULL SEL') then return cntr end -- TAKE NULL is attribute of a take inserted with actions 'Item: Add an empty take before/after the active take'
	end
return 0 -- if no active take found in the chunk, it must be the topmost because in this case its TAKE attribute isn't listed
end


function get_same_group_items(item, sel_itms_t)
	local function get_group(item)
	return r.GetMediaItemInfo_Value(item, 'I_GROUPID')
	end
local group = get_group(item)
sel_itms_t[item] = {}
local t = sel_itms_t[item]
	if group > 0 then -- 0 no group
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if get_group(item) == group and not sel_itms_t[item] then -- store if not already stored as selected
				if r.IsMediaItemSelected(item) then -- if selected, store as selected in the main table
				sel_itms_t[#sel_itms_t+1] = item
				sel_itms_t[item] = ''
				else -- store as grouped
				table.insert(t, item)
				end
			end
		end
	end
return sel_itms_t
end


function process(item, down)
local result
	if IGNORE_LOCKED_ITEMS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 ~= 1
	or not IGNORE_LOCKED_ITEMS then
	r.SelectAllMediaItems(0, false) -- deselect all
	r.SetMediaItemSelected(item, true) -- selected true
		if not invalid_takes_excess(item) then
		Move_Active_Take_Within_Item(item, down)
		result = 1
		end
	end
return result
end




local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

----------------
--		scr_name = 'up within selected items' ---------------- NAME TESTING
----------------

local up, down = scr_name:match('up within selected items'), scr_name:match('down within selected items')

local ACT, GetToggle = r.Main_OnCommand, r.GetToggleCommandStateEx
IGNORE_LOCKED_ITEMS = IGNORE_LOCKED_ITEMS:match('%S+')
IGNORE_GROUPED_ITEMS = IGNORE_GROUPED_ITEMS:match('%S+')
local grouping_on = GetToggle(0, 1156) == 1 -- Options: Toggle item grouping and track media/razor edit grouping

local section, key = 'Move active take up-down within selected items', 'FINITE MOVEMENT'
local finite_movement = r.HasExtState(section, key) -- ext state is created with Move active take up-down within selected items - FINITE_MOVEMENT setting.lua script

local cnt = r.CountSelectedMediaItems(0)
local item = r.GetSelectedMediaItem(0,0)

local err = not up and not down and 'invalid script name' or cnt == 0 and 'no selected items'
or cnt == 1 and (IGNORE_LOCKED_ITEMS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1 and 'locked item' -- grouped items will be ignored in this case so their own lock state is irrelevant
or (not grouping_on or IGNORE_GROUPED_ITEMS) and invalid_takes_excess(item) -- accointing for the grouping settings because if grouped items are respected the excess may not apply to them
and '     item contains \n\n    excessive number \n\n of unsupported takes')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true	
		if not finite_movement then r.defer(no_undo) end -- only run defer to prevent generic undo point creation when the script isn't likely to be executed within a custom action where 'Move active take up-down within selected items - FINITE_MOVEMENT setting.lua' storing 'finite_movement' value is supposed to be executed as well, because with many instances inside the custom action each next instance will fire off before the defer loop started by previous instance has run its course causing 'ReaScript control task' dialogue to show up
	return end

FINITE_MOVEMENT = finite_movement or FINITE_MOVEMENT:match('%S+')

local sel_itms, locked = {}, 0
	for i=0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		if r.IsMediaItemSelected(item) and not sel_itms[item] then -- store if not already stored as a selected grouped item inside get_same_group_items()
		sel_itms[#sel_itms+1] = item
		sel_itms[item] = ''
			if IGNORE_LOCKED_ITEMS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1 then
			locked = locked+1
			end
			if not IGNORE_GROUPED_ITEMS and grouping_on then
			sel_itms = get_same_group_items(item, sel_itms)
			end
		end
	end

	if #sel_itms == locked then
	Error_Tooltip('\n\n locked items \n\n', 1, 1) -- caps, spaced true
		if not finite_movement then r.defer(no_undo) end -- see explanation in error message above
	return end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local allow_sel_empty_takes = GetToggle(0, 41355) == 1 -- Options: Allow selecting empty takes
	if not allow_sel_empty_takes then ACT(41355, 0) end -- toggle to enable to be able to select empty takes with actions

	if grouping_on then ACT(1156, 0) end -- disable so that grouped items are not affected by actions inside Move_Active_Take_Within_Item() if IGNORE_GROUPED_ITEMS is enabled or so that they can be processed separately if IGNORE_GROUPED_ITEMS is not enabled, because when 'Item grouping' option is enabled actions affect all grouped items at once and the script produces flawed result

local result
	for k, item in ipairs(sel_itms) do
		if process(item, down) then
		result = 1
		end
		if sel_itms[item] then -- process items grouped with the current
			for k, item in ipairs(sel_itms[item]) do
				if process(item, down) then
				result = 1
				end
			end
		end
	end

r.SelectAllMediaItems(0, false) -- deselect all

	for k, item in ipairs(sel_itms) do --restore selection
	r.SetMediaItemSelected(item, true) -- selected true
	end

	if not allow_sel_empty_takes then ACT(41355, 0) end -- toggle to disable, restoring original state
	if grouping_on then ACT(1156, 0) end -- toggle to re-enabled, restoring original state

r.PreventUIRefresh(-1)
	
	if not result then
	Error_Tooltip('\n\n\tno item was processed, \n\n'
	..'  either because of lock state \n\n or excess of unsupported takes \n\n', 1, 1) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar; must be followed by 'return r.defer(no_undo)' to exit script
		if not finite_movement then r.defer(no_undo) end -- see explanation in error message above
	return end

scr_name = IGNORE_GROUPED_ITEMS and scr_name or scr_name:gsub('selected', '%0 and grouped')
r.Undo_EndBlock(scr_name, -1)




