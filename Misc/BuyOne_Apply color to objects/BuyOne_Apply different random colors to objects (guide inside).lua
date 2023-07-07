--[[
ReaScript name: BuyOne_Apply different random colors to objects (guide inside).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script is designed to be a one stop shop for object coloration
    		with the different random colors in REAPER. It colors objects randomly 
    		according to 3 criteria: being encolsed within razor edit area, 
    		within time selection and being selected.  
    		The objects are project markers and regions, take markers, items/takes
    		and tracks.  
    		The criteria are evaluated in the following order:   
    		razor edit areas+time selection, razor edit areas, time selection, 
    		item selection, track selection.  
    		When one criterion is not met, the next one is evaluated.  
    		
    		Razor edit areas are relevant for project markers and regions and take
    		markers. To color these enclose them within razor edit areas. The 
    		multiplicity of razor edit ares allows coloration of non-contiguous 
    		objects. For region color to be affected by the script its start or 
    		end ust be enclosed within a razor edit area or coincide with either 
    		of its edges. The same applies to markers with the exception of the 
    		end which they don't have. In multi-take items all take markers in all 
    		takes are affected as long as they fall within razor edit area bounds.
    		
    		For project markers and regions and take markers time selection is also 
    		relevant, however time selection only allows coloring non-contiguos
    		objects. Like in the case of razor edit areas objects must be either
    		encolsed within time selection or conicide with either of its edges.
    		To affect take markers the item must be selected. In multi-take items 
    		only markers in the active take are affected.
    		
    		Item selection only relevant for items and track selection is only 
    		relevant for tracks. By default if item consists of multiple takes
    		the color is applied to the active take. This can be changed in the
    		USER SETTINGS.   
    		This particular script has another criterion for items which is razor
    		edit area + time selection which instructs the script to apply different
    		random colors to all item takes. If there's only one take in an item 
    		the random color will be applied to the take and not the item. When this
    		criterion is met ALWAYS_COLOR_ITEM setting in the USER SETTINGS has no
    		effect. To activate this criterion first create time selection which 
    		includes at least 1 target item (it seems impossible to keep razor edit 
    		areas and create time selection, hence it must come first), then create 
    		razor edit areas over all items to be affected by the script. Neither 
    		the time selection nor a razor edit area has to cover the entire item.
    	
    		
    		Select target objects using the means described above and run the script.
    		
    		When selected items are being colored they will appear blinking once.
    		That's done on purpose to reveal the new color, because depending on
    		the theme selection color may mask the actual item/take color, so without
    		temporarily clearing the selection automatically, in order to assess the
    		coloration result the selection would have to be cleared manually and then
    		re-stored if the result wasn't satistactory.
    		
    		
    		If you happen to forget what criteria are applied to which object 
    		type, run the script with a shortcut having placed the mouse cursor 
    		within 100 px of the left edge of the screen (not REAPER window) to 
    		display a hint. The hint can only be displayed before the color picker 
    		has been loaded.
    		
    		Check out also:  
    		BuyOne_Apply color to objects (guide inside).lua  
    		BuyOne_Apply same random color to objects (guide inside).lua
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character
-- between the quotes if you'd like the script to
-- color the entire item regardless of the number
-- of takes it consists of, which for multi-take items
-- will mean the same color for all takes because
-- if they have custom color it will be reset;
-- the applied color will also be default color
-- for all new takes which don't have custom color;
-- if the setting isn't enabled here, it can be toggled
-- via menu if the script is run with a shortcut while
-- the mouse cursor is located within 100 px of the
-- left edge of the screen (not REAPER window);
-- the state of the setting changed via the menu
-- is stored in the project and will be available
-- in the next session provided the project is saved;
-- besides this one it will be used by another 2 scripts:
-- BuyOne_Apply color to objects (guide inside).lua
-- BuyOne_Apply same random color to objects (guide inside).lua
ALWAYS_COLOR_ITEM = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

REF = [[
script name  H E L P:
 
1. Project markers/regions
A) Non-contiguous — razor edit areas
B) Contiguous — razor edit areas or time selection

2. Take markers
A) In all item takes — razor edit areas
B) In the active take — time selection and item selection

3. Items (item selection)
A) Active take only — default
B) All takes same color — ALWAYS_COLOR_ITEM setting is enabled

4. Tracks (track selection)
]] -- 'script name' will be dynamically replaced with the actual script name; the line under the title line must contain at least 1 space so the separator isn't added and there's an empty line instead in the hint


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x, y, true) -- topmost true
--[[
-- a time loop can be added to run when certan condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function Center_Message_Text(mess, spaced)
-- to be used before Error_Tooltip()
-- spaced is boolean, must be true if the same argument is true in  Error_Tooltip()
local t, max = {}, 0
	for line in mess:gmatch('[^%c]+') do
		if line then
		t[#t+1] = line
		max = #line > max and #line or max
		end
	end
local coeff = spaced and 1.5 or 2 -- 1.5 seems to work when the text is spaced out inside Error_Tooltip(), otherwise 2 needs to be used
	for k, line in ipairs(t) do
	local shift = math.floor((max - #line)/2*coeff+0.5)
	local lb = k < #t and '\n\n' or ''
	t[k] = (' '):rep(shift)..line..lb
	end
return table.concat(t)
end


-- used in Display_REF_Popup()
function Convert_Text_To_Menu(text, max_line_len, ALWAYS_COLOR_ITEM) -- max_line_len is integer, determines length of line as a menu item, 70 seems optimal

local text = text:gsub('|', 'ㅣ') -- replace pipe, if any, with Hangul character for /i/ since its a menu special character
local text = text:gsub('&', '+') -- convert ampersand to + because it's a menu special character used as a quick access shortuct hence not displayed in the menu
local text = text:gsub('\n', '|')-- OR text:gsub('\r', '|') // convert user line breaks into pipes to divide lines by creating menu items, otherwise user line breaks aren't respected; multiple line break is created thanks to the space between pipes originally left after each \n character, if there's none a solid line is displayed instead or several thereof starting from 3 pipes and more
local t = {}
	for w in text:gmatch('[%w%p\128-\255]+[%s%p]*') do -- split into words + trailing space if any; [%w%p] makes sure that words with apostrophe <it's>, <don't> aren't split up; [%s%p] makes menu divider pipes and special characters (!#<>), if any, attached to the words bevause they're punctuation marks (%p); accounting for utif-8 characters
		if w then
		t[#t+1] = w end
	end

local text, menu = '',''
	for k, w in ipairs(t) do
	local text_clean = (text..w):gsub('|','') -- doesn't seem to make a difference with or without the pipe
		if #text_clean > max_line_len or text:match('(.+)|') then -- dump text var to menu var and reset text, if not dumped immediately when the text var ends with line break then when text var will exceed the length limit containing a user line break, hanging words will appear after such line break because they will now be included in the menu var and next time length of text var will be evaluated without them, e.g.:
		-- | text = 'The generated Lorem Ipsum is therefore | always' -- assuming the string exceeds the length limit, 'always' will be left hanging ...
		-- | menu = menu..'The generated Lorem Ipsum is therefore | always'..pipe -- line break is created after 'always' with pipe var, next time text var will be added after the pipe, so the result will look like:
		-- | 'The generated Lorem Ipsum is therefore
		-- | always
		-- | free from repetition, injected humor
		-- whereas 'always' has to be grouped with 'free from repetition, injected humor'
		local pipe = text:match('(.+)|') and '' or '|' -- when the above condition is true because text end with pipe the pipe is user's line break so no need to add another one, otherwise when condition is true because the line length exceeds the limit pipe is added to delimit lines as menu items
		text = #pipe == 0 and text:gsub('[!#<>]',' %0') or text -- make sure that menu special characters at the beginning of a new line (menu item) are ignored prefacing them with space; when string stored in the text var has pipe in the end, if ther're any menu special characters in the user text, they will follow the pipe due to the way user text are split into words at the beginning of the function, so if there're any specal characters placed at the beginning of a new line in the user text they will necessarily be found in the text var right next to the new line character converted at the beginning of the function into pipe to conform to the menu syntax and such new line character is attached to the preceding line
		menu = menu..text..pipe -- between menu and text pipe isn't needed because it's added after the text and next time will be at the end of the menu
		text = ''
		end
		if k == #t then
		menu = ' |'..menu..text..w..(not ALWAYS_COLOR_ITEM and '||||' or ' ') -- add padding
		else
		text = text..w
		end
	end
return menu
end


function Display_REF_Popup(REF, ALWAYS_COLOR_ITEM, always_color_item)
local x, y = r.GetMousePosition()
	if x <= 100 then
	local menu = Convert_Text_To_Menu(REF, 70, ALWAYS_COLOR_ITEM)
	local _, line_cnt
		if not ALWAYS_COLOR_ITEM then -- only add the setting to the menu if it's not enabled in the script
		local tmp = menu
		_, line_cnt = tmp:gsub('|+','') -- count pipe clusters which format lines to find out the number of lines
		menu = menu..(always_color_item == '1' and '[✔]' or '[   ]')..' Toggle ALWAYS_COLOR_ITEM setting| ' -- adding chekmark if the setting is enabled
		end
	-- open menu at the upper left corner, lower left on Mac
	gfx.init('', 0, 0)
	gfx.x = gfx.mouse_x
	gfx.y = gfx.mouse_y
	local input = gfx.showmenu(menu) -- menu string
		if line_cnt and input == line_cnt+1 then -- only if the menu item exists
		local sett = always_color_item == '1' and '0' or '1'
		r.SetProjExtState(0, 'BuyOne_Apply color to objects (3 scripts)', 'ALWAYS_COLOR_ITEM', sett)
		end
	gfx.quit()
	return true
	end
end


function Parse_Razor_Edit_Data(data) -- used inside of Collect_Razor_Edit_Areas()
local t = {}
	for st, fin in data:gmatch('([%.%d]+) ([%.%d]+)') do
		if st and fin then
		t[#t+1] = {st=st+0, fin=fin+0} -- converting to numbers
		end
	end
return t
end


function Collect_Razor_Edit_Areas()
local t, raz_edit_last, tr_first, tr_last, found = {}, 0
	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local exists, raz_edit_data = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false) -- stringNeedBig empty string, setNewValue false // exists return value is useless because it's always true
		if #raz_edit_data > 0 then
		found = 1 -- 1 is enough
		tr_first = not tr_first and i+1 or tr_first
		tr_last = i+1
		t[tr] = Parse_Razor_Edit_Data(raz_edit_data)
		local len = #t[tr]
		raz_edit_last = t[tr][len].fin > raz_edit_last and t[tr][len].fin or raz_edit_last -- will be used to abort markers/regons loop if beyond the last razor edit area
		end
	end
t.raz_edit_last = raz_edit_last
t.tr_first, t.tr_last = tr_first, tr_last
return found and t
end


function Color_MrkrsRgns(raz_edit_t, time_sel_t, color, randomize_diff, rand, mask)
-- when color arg is nil the function runs in the evaluation mode
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = st ~= fin
local i, found, cnt = 0
	repeat
	local retval, is_rgn, pos, rgn_end, name, mrk_idx, color_old = r.EnumProjectMarkers3(0, i) -- mrk_idx is the actual marker ID displayed in Arrange which may differ from retval // markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
		if retval > 0 then
		color = randomize_diff and math.random(0, rand)|mask or color
			if raz_edit_t then
				if color and pos > raz_edit_t.raz_edit_last then -- if marker/region is beyond the last razor edit area right edge // only at the color setting stage
				break end
				for tr, data in pairs(raz_edit_t) do
					if not tonumber(data) then -- table
						for _, area_t in ipairs(data) do
						local st, fin = area_t.st, area_t.fin
							if is_rgn and rgn_end >= st and rgn_end <= fin
							or pos >= st and pos <= fin then
							found = 1
							local set = color and r.SetProjectMarker3(0, mrk_idx, is_rgn, pos, rgn_end, name, color)
							end
						end
					end
				end
			elseif time_sel_t and time_sel then -- time_sel var ensures that the original time selection is intact because it can be cleared while the color picker is open
				if color and pos > time_sel_t.fin then -- only at the color setting stage
				break end
			local st, fin = time_sel_t.st, time_sel_t.fin
				if is_rgn and rgn_end >= st and rgn_end <= fin
				or pos >= st and pos <= fin then
				found = 1
				local set = color and r.SetProjectMarker3(0, mrk_idx, is_rgn, pos, rgn_end, name, color)
				end
			end
		cnt = 1
		end
	i = i+1
	until retval == 0 -- until no more markers/regions

return cnt, found -- to generate messages outside

end


-- used inside Color_TakeMrkrs_Within_RazEd_Areas()
function Item_Time_2_Proj_Time(item_time, item, take) -- such as take, stretch markers and transient guides time, item_time is their position within take media source returned by the corresponding functions
-- e.g. take, stretch markers and transient guides time to edit/play cursor, proj markers/regions time
--local cur_pos = r.GetCursorPosition()
local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
--OR
--local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset and take marker pos
local proj_time = item_pos + (item_time - offset)/playrate
return proj_time >= item_pos and proj_time <= item_end and proj_time -- ignoring content outside of item bounds
end



function Color_TakeMrkrs(raz_edit_t, time_sel_t, color, randomize_diff, rand, mask)
-- when color arg is nil the function runs in the evaluation mode
local mrkrs_cnt, found
local itm_cnt = raz_edit_t and r.CountMediaItems(0) or time_sel_t and r.CountSelectedMediaItems(0)
local GetItem = raz_edit_t and r.GetMediaItem or time_sel_t and r.GetSelectedMediaItem
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = st ~= fin
	for i = 0, itm_cnt-1 do
	local itm = GetItem(0,i)
	local itm_start = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
	local itm_tr = r.GetMediaItemTrack(itm)
	local itm_tr_idx = r.CSurf_TrackToID(itm_tr, false) -- mcpView false
	local raz_edit_end = raz_edit_t and raz_edit_t[itm_tr] and raz_edit_t[itm_tr][#raz_edit_t[itm_tr]].fin

		if raz_edit_t and itm_tr_idx > raz_edit_t.tr_last then break end -- exit after the last track with razor edit areas has been reached

		if raz_edit_t and itm_tr_idx >= raz_edit_t.tr_first or time_sel_t and time_sel then -- only run if item's track has razor edit areas or if there's time selection; time_sel var ensures that the original time selection is intact because it can be cleared while the color picker is open

			for i = 0, r.CountTakes(itm)-1 do

				if color and (raz_edit_t and (not raz_edit_end or itm_start > raz_edit_end)
				or time_sel_t and itm_start > time_sel_t.fin)
				then break end -- only if item start is before the end of the last razor edit area or time selection end point or if there're no razor edit areas on the track, placed within takes loop to allow item loop to proceed evaluating following items

			local take = r.GetTake(itm, i)
				for i = 0, r.GetNumTakeMarkers(take)-1 do
				mrkrs_cnt = 1
				local src_pos, name, color_old = r.GetTakeMarker(take, i)
				local pos = Item_Time_2_Proj_Time(src_pos, itm, take)
					if pos then -- will be nil if outside of item bounds
					color = randomize_diff and math.random(0, rand)|mask or color
						if raz_edit_t then -- in all takes
							for tr, data in pairs(raz_edit_t) do
								if tr == itm_tr then
									for _, area_t in ipairs(data) do
									local st, fin = area_t.st, area_t.fin
										if pos >= st and pos <= fin then
										found = 1
										local set = color and r.SetTakeMarker(take, i, name, src_pos, color)
										end
									end
								end
							end
						elseif time_sel_t and r.GetActiveTake(itm) == take then -- only in the active take
						local st, fin = time_sel_t.st, time_sel_t.fin
							if pos >= st and pos <= fin then
							found = 1
							local set = color and r.SetTakeMarker(take, i, name, src_pos, color)
							end
						end
					end
				end -- markers loop end
			end -- take loop end
		end
	end

return mrkrs_cnt, found -- to generate messages outside

end


function Color_Sel_Items(raz_edit_t, time_sel_t, color, randomize_diff, rand, mask, ALWAYS_COLOR_ITEM, itm_within_time_sel)

local random_multi_take_color = raz_edit_t and time_sel_t
local itm_cnt = random_multi_take_color and r.CountMediaItems(0) or r.CountSelectedMediaItems(0)
local GetItem = random_multi_take_color and r.GetMediaItem or r.GetSelectedMediaItem
local t = {}
local itm_within_time_sel = itm_within_time_sel -- at evaluation stage the var will be nil, at the processing stage it will hold value 1

	for i = 0, itm_cnt-1 do
	local found
	local itm = GetItem(0,i)
	t[#t+1] = itm
		if random_multi_take_color then -- only in randomize_diff type script when items aren't selected, to randomize takes color within one item // instead of random_multi_take_color cond r.CountSelectedMediaItems(0) == 0 could be used since in this case no item is supposed to be selected
		local itm_start = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
		local itm_end = itm_start + r.GetMediaItemInfo_Value(itm, 'D_LENGTH')
		local time_st, time_end = time_sel_t.st, time_sel_t.fin
		local within_time_sel = itm_within_time_sel and itm_within_time_sel == 1 or (time_st >= itm_start and time_st < itm_end
		or time_end <= itm_end and time_end > itm_start) -- at evaluation stage only evaluate once since it siffices that one item be marked with time selection, then use the upvalue, at the processing stage itm_within_time_sel will already hold value 1
			if within_time_sel then
				if not color then itm_within_time_sel = -1 end -- only at evaluation stage where color var is nil
			local itm_tr = r.GetMediaItemTrack(itm)
				for tr, data in pairs(raz_edit_t) do
					if tr == itm_tr then
						for _, area_t in ipairs(data) do
						local st, fin = area_t.st, area_t.fin
							if area_t.st >= itm_start and area_t.st < itm_end
							or area_t.fin <= itm_end and area_t.fin > itm_start then
							found = 1
							itm_within_time_sel = 1
							break end -- to proceed to return values at evaluation stage or to take processing
						end
					end
					if not color and itm_within_time_sel == 1 or found then break end -- proceed to return values at evaluation stage where color var is nil or to take processing
				end
			end
		end
		if not color and found then -- evaluation stage
		break
		elseif color then -- processing stage
			if ALWAYS_COLOR_ITEM and not random_multi_take_color then -- color item, it will function as default take color for takes which don't have take color set; takes will be decolorized below to assume item color (revert to their default); only if the script is not of randomize_diff type with no selected items // instead of random_multi_take_color cond r.CountSelectedMediaItems(0) > 0 could be used since in the latter case no item is supposed to be selected
			color = randomize_diff and math.random(0, rand)|mask or color
			r.SetMediaItemInfo_Value(itm, 'I_CUSTOMCOLOR', color, true) -- newvalue true
			end
			for i= 0, r.CountTakes(itm)-1 do
			local take = r.GetTake(itm,i)
				if random_multi_take_color and found or not random_multi_take_color and (not ALWAYS_COLOR_ITEM and take == r.GetActiveTake(itm) or ALWAYS_COLOR_ITEM) then -- if ALWAYS_COLOR_ITEM, decolorize all takes so that they assume item color applied above, otherwise only color active take
				local color = (found or randomize_diff and not ALWAYS_COLOR_ITEM) and math.random(0, rand)|mask or ALWAYS_COLOR_ITEM and 0 or color -- 0 to decolorize take // color is selected when randomize_diff is false and ALWAYS_COLOR_ITEM is false in which case it's applied to active take of all selected items
				r.SetMediaItemTakeInfo_Value(take, 'I_CUSTOMCOLOR', color, true) -- newvalue true
				end
			end
		end

	end

r.UpdateArrange()

	if not raz_edit_t and not time_sel_t then -- only run when condition for randomization of takes color within one item isn't met, not randomize_diff type script or randomize_diff type with no selected items // instead of 'not raz_edit_t and not time_sel_t' cond r.CountSelectedMediaItems(0) == 0 could be used since in this case no item is supposed to be selected

	-- this will only work if the main routine isn't enclosed between PreventUIRefresh() functions
	r.SelectAllMediaItems(0, false) -- selected false // deselect all to reveal the color change
	r.UpdateArrange()

	local v = 0
		for i = 1, 1000000 do -- create a pause to reveal the color change because depending on the theme the color may be masked with selection color like it is in the default 5.0 theme where this color is white
		r.SelectAllMediaItems(0, false) -- selected false // deselect all // the function slows down the loop thereby extending thep pause
		end

		for k, itm in ipairs(t) do -- restore selection to be able to apply new color right away if needed
		r.SetMediaItemSelected(itm, true) -- selected true
		end
	end

return itm_within_time_sel

end



function Color_Sel_Tracks(color, randomize_diff, rand, mask)
	for i = 0, r.CountSelectedTracks(0)-1 do
	local tr = r.GetSelectedTrack(0,i)
	color = randomize_diff and math.random(0, rand)|mask or color
	r.SetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR', color, true) -- newvalue true
	end
end


function Generate_Radom_Color_Val()
-- https://stackoverflow.com/questions/36756331/js-generate-random-boolean
-- https://stackoverflow.com/questions/29851873/convert-a-number-between-1-and-16777215-to-a-colour-value
math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count; math.floor() because the seeding number must be integer
return math.random(0, 16777215) -- the range of values returned by GR_SelectColor()
end


function Evaluate_Selection_x_Generate_Error(raz_edit_t, time_sel_t, sel_itms)

local mrkrs_rgns_exist, found1 = Color_MrkrsRgns(raz_edit_t, time_sel_t, nil) -- color is nil, evaluation stage, raz_edit_t and time_sel_t are nil depending on the type of the current selection, one of them will ve valid
local take_mrkrs_exist, found2 = Color_TakeMrkrs(raz_edit_t, time_sel_t, nil) -- color is nil, evaluation stage, raz_edit_t and time_sel_t is nil depending on the type of the current selection, one of them will ve valid
local mess1 = not mrkrs_rgns_exist and 'no markers/regions\n\nin the project.' or not found1 and (raz_edit_t and 'no markers/regions\n\nwithin razor edit areas.' or time_sel_t and 'no markers/regions\n\nwithin time selection.') or ''
local mess2 = raz_edit_t and (not take_mrkrs_exist and 'no take markers\n\non the target tracks.' or not found2 and 'no take markers within\n\nrazor edit areas.') or time_sel_t and (sel_itms == 0 and 'no selected items.' or sel_itms > 0 and (not take_mrkrs_exist and 'no take markers in selected items.' or not found2 and 'no take markers within\n\ntime selection.' or '') ) or ''
return #mess1 > 0 and #mess2 > 0 and mess1..'\n\n'..mess2 --or #mess1 > 0 and mess1 or #mess2 > 0 and mess2

end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol,val = r.get_action_context()
scr_name = scr_name:match('.+[\\/].-_(.+objects).+%.lua')
ALWAYS_COLOR_ITEM = #ALWAYS_COLOR_ITEM:gsub(' ','') > 0
local ret, always_color_item = table.unpack(not ALWAYS_COLOR_ITEM and {r.GetProjExtState(0, 'BuyOne_Apply color to objects (3 scripts)', 'ALWAYS_COLOR_ITEM')} or {}) -- only if the setting isn't enabled in the script, the setting will be shared by 3 scripts: 'BuyOne_Apply color to objects', 'BuyOne_Apply same random color to objects', 'BuyOne_Apply different random colors to objects'
local randomize_same = scr_name:match('same random')
local randomize_diff = scr_name:match('different random')
REF = REF:gsub('script name', scr_name)
REF = REF:gsub('ALWAYS_COLOR_ITEM setting is enabled', '%0\nC) All takes different colors — razor edit areas + time selection')
	if Display_REF_Popup(REF, ALWAYS_COLOR_ITEM, always_color_item) then -- the function only runs if mouse cursor is within 100 px of the X and Y axes start
	return r.defer(no_undo) end -- abort to prevent color change in randomize scripts
ALWAYS_COLOR_ITEM = always_color_item == '1' or ALWAYS_COLOR_ITEM


r.Undo_BeginBlock()

::RETRY::
local mask = 0x1000000 -- 0x1000000 is 16777216 (16777215 in zero based count) -- it's not a mask but let it be
local raz_edit_t = Collect_Razor_Edit_Areas() --do return end
--Msg(raz_edit_t)
local st, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = st ~= fin and {st=st, fin=fin}
local sel_itms = r.CountSelectedMediaItems(0)
local sel_tracks = r.CountSelectedTracks(0)
local undo_var = randomize_same and 'Apply same random color to' or randomize_diff and 'Apply different random colors to' or 'Color'

	if randomize_diff and raz_edit_t and time_sel then
	local itm_within_time_sel = Color_Sel_Items(raz_edit_t, time_sel, nil, randomize_diff, rand, mask) -- color nil, evaluation stage
	local mess = not itm_within_time_sel and 'no item within time selection' or itm_within_time_sel == -1 and 'the item within time selection\n\nis not within razor edit area'
		if mess then
		local spaced = true
		mess = Center_Message_Text(mess, spaced)
		Error_Tooltip('\n\n'..mess..'\n\n ', true, spaced) -- caps true
		return r.defer(no_undo)
		else
		local rand = Generate_Radom_Color_Val() -- must be generated separatedly since if randomize_diff true the function isn't fast enough inside the loops in Color_MrkrsRgns() and Color_TakeMrkrs() which leads to the same result as randomize_same
		Color_Sel_Items(raz_edit_t, time_sel, true, randomize_diff, rand, mask, ALWAYS_COLOR_ITEM, itm_within_time_sel) -- color true to trigger the relevant routine
		undo = undo_var..'item takes'
		end

	-- COLOR MARKERS & REGIONS BASED ON RAZOR EDIT SELECTION
	elseif raz_edit_t then
	local mess = Evaluate_Selection_x_Generate_Error(raz_edit_t, time_sel, sel_itms)
		if mess then -- only if no valid object has been found
			if not retval then -- the color picker hasn't been opened yet
			local spaced = true
			mess = Center_Message_Text(mess, spaced)
			Error_Tooltip('\n\n'..mess..'\n\n ', true, spaced) -- caps true
			return r.defer(no_undo)
			else -- the color picker is open and the selection has changed
			local spaced = true
			mess = Center_Message_Text(mess, spaced)
			local resp = r.MB('    '..mess:gsub('\n\n', '%0      '):upper(), 'ERROR', 5)
				if resp == 2 then return r.defer(no_undo)
				else retval = nil -- reset to trigger reloading of the color picker below
				end
			end
		end
	local rand = Generate_Radom_Color_Val() -- must be generated separatedly since if randomize_diff true the function isn't fast enough inside the loops in Color_MrkrsRgns() and Color_TakeMrkrs() which leads to the same result as randomize_same
		if randomize_same then -- to all selected markers the same random color is applied
		color = math.random(0, rand) -- gives greater randomization
		elseif not randomize_diff and not retval then -- during the second run from the beginning retval will be true so the color picker won't load again
		retval, color = r.GR_SelectColor()
			if retval == 0 then return r.defer(no_undo) end -- user canceled the dialogue
		goto RETRY -- run from the beginning to check if the selection changed while the color picker is open
		end
	color = not randomize_diff and color|mask or true -- or mask|color
	Color_MrkrsRgns(raz_edit_t, nil, color, randomize_diff, rand, mask) -- time_sel_t is nil
	Color_TakeMrkrs(raz_edit_t, nil, color, randomize_diff, rand, mask) -- time_sel_t is nil
	undo = undo_var..' project markers/regions and/or take markers in razor edit areas'

	-- COLOR MARKERS & REGIONS BASED ON TIME SELECTION
	elseif time_sel then -- look for time selection
	local mess = Evaluate_Selection_x_Generate_Error(raz_edit_t, time_sel, sel_itms)
		if mess then -- only if no valid object has been found
			if not retval then -- the color picker hasn't been opened yet
			local spaced = true
			mess = Center_Message_Text(mess, spaced)
			Error_Tooltip('\n\n'..mess..'\n\n ', true, spaced) -- caps true
			return r.defer(no_undo)
			else -- the color picker is open and the selection has changed
			local spaced = true
			mess = Center_Message_Text(mess, spaced)
			local resp = r.MB('    '..mess:gsub('\n\n', '%0      '):upper(), 'ERROR', 5)
				if resp == 2 then return r.defer(no_undo)
				else retval = nil -- reset to trigger reloading of the color picker below
				end
			end
		end
	local rand = Generate_Radom_Color_Val() -- must be generated separatedly since if randomize_diff true the function isn't fast enough inside the loops in Color_MrkrsRgns() and Color_TakeMrkrs() which leads to the same result as randomize_same
		if randomize_same then -- to all selected markers the same random color is applied
		color = math.random(0, rand) -- gives greater randomization
		elseif not randomize_diff and not retval then -- during the second run from the beginning retval will be true so the color picker won't load again
		retval, color = r.GR_SelectColor()
			if retval == 0 then return r.defer(no_undo) end -- user canceled the dialogue
		goto RETRY -- run from the beginning to check if the selection changed while the color picker is open
		end
	color = not randomize_diff and color|mask or true -- or mask|color
	Color_MrkrsRgns(nil, time_sel, color, randomize_diff, rand, mask) -- raz_edit_t is nil
	Color_TakeMrkrs(nil, time_sel, color, randomize_diff, rand, mask) -- raz_edit_t is nil
	undo = undo_var..' project markers/regions and/or take markers in time selection'

	-- COLOR ITEMS
	elseif sel_itms > 0 or retval1 then -- retval1 will be true in RETRY routine
	local rand = Generate_Radom_Color_Val() -- must be generated separatedly since if randomize_diff true the function isn't fast enough inside the loops in Color_Sel_Items() which leads to the same result as randomize_same
		if randomize_same then -- to all selected items the same random color is applied
		color = math.random(0, rand) -- gives greater randomization
		elseif not randomize_diff then
		retval1, color = r.GR_SelectColor()
			if retval == 0 then return r.defer(no_undo) end -- user canceled the dialogue
		end
		if r.CountSelectedMediaItems(0) > 0 then -- must be retrieved with the function in case RETRY routine was executed because in this case sel_itms > 0 cond will still be false
		color = not randomize_diff and color|mask or true -- or mask|color
		Color_Sel_Items(nil, nil, color, randomize_diff, rand, mask, ALWAYS_COLOR_ITEM) -- raz_edit_t, time_sel nil
		undo = undo_var..' selected items / active takes'
		end

	-- COLOR TRACKS
	elseif sel_tracks > 0 or retval2 then -- retval2 will be true in RETRY routine
	local rand = Generate_Radom_Color_Val() -- must be generated separatedly since if randomize_diff true the function isn't fast enough inside the loops in Color_Sel_Tracks() which leads to the same result as randomize_same
		if randomize_same then -- to all selected tracks the same random color is applied
		color = math.random(0, rand) -- gives greater randomization
		elseif not randomize_diff then
		retval2, color = r.GR_SelectColor()
			if retval == 0 then return r.defer(no_undo) end -- user canceled the dialogue
		end
		if r.CountSelectedTracks(0) > 0 then -- must be retrieved with the function in case RETRY routine was executed because in this case sel_tracks > 0 cond will still be false
		color = not randomize_diff and color|mask or true -- or mask|color
		Color_Sel_Tracks(color, randomize_diff, rand, mask)
		undo = undo_var..' selected tracks'
		end

	end


	-- items and tracks error routine
	if not undo and r.CountSelectedMediaItems(0) + r.CountSelectedTracks(0) == 0 then -- must be retrieved with the functions in case RETRY routine was executed because in this case sel_itms and sel_tracks vars won't reflect the new selection state
	local mess = 'no selected items or tracks'
		if not retval1 and not retval2 then -- the color picker hasn't been opened yet
		Error_Tooltip('\n\n '..mess..' \n\n', true, true) -- caps and spaced true
		return r.defer(no_undo)
		else -- the color picker is open and the selection has changed
		local resp = r.MB(mess:upper(), 'ERROR', 5)
			if resp == 2 then return r.defer(no_undo)
			else
		--	retval = nil -- reset to trigger reloading of the color picker above
			goto RETRY -- run from the beginning to check if the selection changed while the color picker is open
			end
		end
	end

r.Undo_EndBlock(undo,-1)




