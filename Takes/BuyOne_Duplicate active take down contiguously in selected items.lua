--[[
ReaScript name: BuyOne_Duplicate active take down contiguously in selected items.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script is an alternative to REAPER's native action
		'Take: Duplicate active take'   
		which places the duplicate at the very bottom in contrast
		to which the script places one immediately below the active
		take.

		Non-selected items grouped with selected items are affected 
		as well if 'Item grouping' option is enabled in REAPER and 
		unless IGNORE_GROUPED_ITEMS setting is enabled in the script
		USER SETTINGS. So you can make the script ignore grouped 
		items by either disabling REAPER's option or by enabling
		the said script setting.  
		If selected items are locked and IGNORE_LOCKED_ITEMS 
		setting is enabled, non-selected items grouped with them 
		will not be processed even if not locked.

		Empty takes aren't supported.

]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert
-- any alphanumeric character between the quotes


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



function Duplicate_Active_Take_Contiguously(sel_item, want_above, want_top)
-- duplicate and place immediately below the source take
-- or above if want_above arg is valid
-- contrary to the stock action which places it at the bottom;
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
local take_cnt = item and r.CountTakes(item)

ACT(40639, 0) -- Take: Duplicate active take // this will be placed at the bottom // ignores empty takes created with 'Item: Add an empty take after the active take' and locked items
local new_take_idx = r.CountTakes(item)-1 -- placed at the bottom hence the 0-based index is equal to take count-1
local new_take = r.GetTake(item, new_take_idx)

	if act_take_idx ~= take_cnt-1 or want_above then -- if active take is last and want_above is false, not need to cycle, everything will fall in place, even though cycling would still work

		if not want_above then
		to_top() -- new take is active, move it to top
		-- activate originally active take so it can be affected by the action
		Activate(act_take)
		to_top() -- move active take to top, now they're in the expected order relative to each other but at wrong places within the item
		else
		-- set originally active take active, because cuurently the duplicate take is active
		Activate(act_take)
		to_top() -- move to top
		-- set duplicate take active
		Activate(new_take) -- set duplicate take active
		to_top() -- move to top, now they're in the expected order relative to each other but at wrong places within the item
		end

	-- At this point the index of oringinally active take is 0
	-- and of the new take is 1,
	-- cycle takes until the originally active take ends up at its original index
	-- and is immediately followed by the new take
		for i=1, act_take_idx do -- cycle as many times as the original index of the originally active take, because it reflects the number of takes which preceded it and whose original position must be restored
		local idx = act_take_idx+1
		local take = r.GetTake(item, idx)
			if take then
			Activate(take) -- target take which now occupies position of the originally active take, +1 to account for the newly inserted take which precedes such take in the new take order
			else
			ACT(45000+idx, 0) -- use command ID of the action 'Take: Set 1st take active' to calculate command ID corresponding to the active take index when take is an empty take inserted with 'Item: Add an empty take before/after the active take' which doesn't have a pointer so cannot be set active with API
			end
		to_top() -- move to top
		end
	end

 -- activate newly added take
	if new_take then
	Activate(new_take)
	else
	ACT(45000+new_take_idx, 0)
	end

	if want_top then
	to_top()
	end

r.UpdateItemInProject(item) -- to make re-activated take immediately visible

end


function takes_excess(item)
-- empty takes inserted with 'Item: Add an empty take before/after the active take'
-- cannot be retrieved with GetActiveTake(item) or with GetTake(item, GetMediaItemInfo_Value(item, 'I_CURTAKE'))
-- so cannot be set active via API which is required for moving takes inside Duplicate_Active_Take_Contiguously(),
-- but with actions 'Take: Set X take active' they can
-- however the actions only cover takes 1 through 9
local take_cnt, cntr = r.CountTakes(item), 0
local act_take = r.GetActiveTake(item)
	if act_take then -- only if active take is valid, i.e. not an empty take
		for i=0, r.CountTakes(item)-1 do
			if not r.GetTake(item,i) then cntr = cntr+1 end
		end
	end
return not act_take, cntr > 9, take_cnt == cntr -- return whether the active take is valid, whether empty takes count doesn't exceed the limit set by the actions 'Take: Set X take active', whether item consists of empty takes only
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
--local locked, = 0
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


function process(item, up, top)
local result
	if not r.GetActiveTake(item) then return end -- empty take created by 'Item: Add an empty take after the active take' action which are ignored by the action 'Take: Duplicate active take' used inside Duplicate_Active_Take_Contiguously() to duplicate takes; empty takes don't have a pointer
local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1
local Set, unlock = r.SetMediaItemInfo_Value, not IGNORE_LOCKED_ITEMS and locked
	if IGNORE_LOCKED_ITEMS and not locked
	or not IGNORE_LOCKED_ITEMS then
	r.SelectAllMediaItems(0, false) -- deselect all
	r.SetMediaItemSelected(item, true) -- selected true
		if not takes_excess(item) then
		unlock = unlock and Set(item, 'C_LOCK', 0) -- temporarily unlock because action 'Take: Duplicate active take' used inside Duplicate_Active_Take_Contiguously() ignores locked items
		Duplicate_Active_Take_Contiguously(item, up, top)
		local re_lock = unlock and Set(item, 'C_LOCK', 1) -- restore lock
		result = 1
		end
	end
return result
end



local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

----------------
--		scr_name = 'Duplicate to top' ---------------- NAME TESTING
----------------

local t = {'up contiguously', 'down contiguously', 'to top'}
local valid
	for k, v in ipairs(t) do
	t[k] = scr_name:match('Duplicate.+'..v) or false -- false to disallow nil because it will prevent table unpacking
		if t[k] then
		valid = 1
		end
	end

	if not valid then
	Error_Tooltip('\n\n invalid script name \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


local SetToggle = r.SetToggleCommandState
SetToggle(sect_ID, cmd_ID, 1) -- set to On to prevent excution of next action or another instance of this script within custom action if the script throws an error, because the toggle state will remain On (custom action structure see in 'About' text in the script header), meant to prevent triggering of 'ReaScript control task' by execution of r.defer(no_undo) in several isnatnces of the script in close succession when the error message is generated by the script, because the speed of execution is greater than once in 30 ms which is the defer loop update cycle, resulting in following instance of the script being triggered while the current one is still running (in defer loop)

local ACT, GetToggle = r.Main_OnCommand, r.GetToggleCommandStateEx
IGNORE_LOCKED_ITEMS = IGNORE_LOCKED_ITEMS:match('%S+')
IGNORE_GROUPED_ITEMS = IGNORE_GROUPED_ITEMS:match('%S+')
local grouping_on = GetToggle(0, 1156) == 1 -- Options: Toggle item grouping and track media/razor edit grouping
local no_group =  item and r.GetMediaItemInfo_Value(item, 'I_GROUPID') == 0

local cnt = r.CountSelectedMediaItems(0)
local item = r.GetSelectedMediaItem(0,0)

local err = cnt == 0 and 'no selected items'
local active_empty_take, empty_take_excess, empty_takes_only = table.unpack(not err and {takes_excess(item)} or {})
Msg(IGNORE_GROUPED_ITEMS)
err = err or cnt == 1 and ( IGNORE_LOCKED_ITEMS and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 == 1 and 'locked item' -- grouped items will be ignored in this case so their own lock state is irrelevant
or (not grouping_on or IGNORE_GROUPED_ITEMS or no_group or r.CountMediaItems(0) == 1)
and (active_empty_take and 'empty active takes \n\n  aren\'t supported'
or empty_take_excess and '     item contains \n\n    excessive number \n\n of unsupported takes'
or empty_takes_only and 'item only contains empty takes \n\n\twhich aren\'t supported') ) -- accointing for the grouping settings because if grouped items are respected empty takes limitations may not apply to them

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


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
	return r.defer(no_undo)
	end

local up, down, top = table.unpack(t)

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local allow_sel_empty_takes = GetToggle(0, 41355) == 1 -- Options: Allow selecting empty takes
	if not allow_sel_empty_takes then ACT(41355, 0) end -- toggle to enable to be able to select empty takes with actions

	if grouping_on then ACT(1156, 0) end -- disable so that grouped items are not affected by actions inside Duplicate_Active_Take_Contiguously() if IGNORE_GROUPED_ITEMS is enabled or so that they can be processed separately if IGNORE_GROUPED_ITEMS is not enabled, because when 'Item grouping' option is enabled actions affect all grouped items at once and the script produces flawed result

local result
	for k, item in ipairs(sel_itms) do
		if process(item, up, top) then
		result = 1
		end
		if sel_itms[item] then -- process items grouped with the current
			for k, item in ipairs(sel_itms[item]) do
				if process(item, up, top) then
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
	..'  either because of lock state \n\n or excess of unsupported takes \n\n\t  or active empty take \n\n', 1, 1) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar; must be followed by 'return r.defer(no_undo)' to exit script
	return r.defer(no_undo)
	end

SetToggle(sect_ID, cmd_ID, 0) -- reset toggle state set at the beginning of the script
scr_name = IGNORE_GROUPED_ITEMS and scr_name or scr_name:gsub('selected', '%0 and grouped')
r.Undo_EndBlock(scr_name, -1)




