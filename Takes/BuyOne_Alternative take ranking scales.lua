--[[
ReaScript name: BuyOne_Alternative take ranking scales.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.09
Extensions: SWS/S&M recommended, not mandatory
Provides: [main=main,midi_editor] .
About:	The script provides an alternative to REAPER built-in take rank scale
			which was introduced in build 7.17 AND allows to conveniently rank takes 
			in earlier builds where take markers are supported, that is starting from
			6.09.  
			Besides ranking the script can be used for labeling items/takes for other 
			purposes, but since take ranking is its primary purpose the following text 
			will only refer to ranking.
			
			The script targets take under mouse cursor and if none is detected it 
			targets active takes of all selected items under the edit cursor.   			
			Within take the script targets take marker directly under mouse/edit cursor 
			and if none is detected it targets the first take marker left of cursor.  
			If at cursor or to the left of it there's no rank marker the script will 
			insert a new take marker, otherwise it'll update the found take marker.
			
			!!! Define target items before running the script so that when the rank 
			menu opens you only need to press a button.
			
			If a new marker is needed and there's not enough space between the cursor 
			and the item start, move the existing marker to the right beyond the cursor 
			position or insert a new marker using REAPER native action and then set its 
			rank with the script.
			
			If the rank scale used in the marker detected by the script differs from 
			the script active rank scale defined in SCALE_TYPE settings, up/down-ranking 
			options will be grayed out.  
			Therefore if you changed the script active scale, in order to change rank 
			of a marker ranked in a different scale use menu items meant for explicit 
			rank setting.
			
			Up/down-ranking options aren't cyclic.
			
			To delete all or specific rank markers use Region/Marker Manager with 
			'Take markers' option checked so they're listed. The feature is supported
			since REAPER build 7.17.			
					
			Locked items are ignored by the script.

			
			ADDITIONAL OPTIONS
			
			► Options 
			'Select items with active take ranked as...'  
			'Select items with any take ranked as...'  
			 AND  
			'Set take ranked as... active'
			
			are toggle mutually exclusive options. The elipsis in their titles implies 
			a user selected rank, so in order to execute the actions associated with 
			them, after enabling an option click a rank button in the rank menu.  
			When acting on options 1 and 2, before selecting items the script deselects
			all items in the project. When acting on option 3, if there're several takes 
			which match the user selected rank, the first found take is the one which will 
			be set active, however the currently active take is ignored even if it does 
			match the user selected rank.  
			The target item priority is as follows:  
			in options 1 and 2: item under mouse, items on selected tracks, all items in 
			the project on tracks visible in Arrange;   
			in option 3: item under mouse, selected items, items on selected tracks, all 
			items in the project on tracks visible in Arrange.			
			
			► Options under 'OTHER OPERATIONS' submenu
			
			'Sort takes in items by rank in desceding/ascending order'  
			'Calculate take average/median rank'
			
			When sorting takes with multiple rank markers in the active scale, if direction 
			is descending, only marker ranked the highest within take will be respected;
			if direction is ascending, only the marker ranked the lowest within take will 
			be respected. E.g. out of markers ranked 5, 3 and 1 in the active scale within 
			the same take when sorting in descending order only marker ranked 5 will be 
			respected, and when sorting in ascending order only marker ranked 1 will be 
			respected.
			
			After sorting the last active take status is maintained regardless of its 
			position. Takes which are unranked or ranked in a scale different from the 
			active one are relegated to the bottom take lanes.
			
			When calculating average and median rank only markers ranked in the active scale 
			are respected and if within take there're multiple markers ranked in the active 
			scale the marker ranked the highest is always given priority.
			
			The target item priority for these options: item under mouse, selected items, 
			items on selected tracks, all items in the project on tracks visible in Arrange.
			
			---------
			
			To target all items in the project besides selecting all items explicitly, either 
			deselect all tracks (e.g. select one and then deselect it with Ctrl/Cmd+Click) 
			or select all tracks.  
			If during script execution all tracks are selected the script will leave only 
			the first one selected after completing the task successfully.
			
			-----------------------------------------
			
			Proceed to USER SETTINGS below.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- SCALE_TYPE CODES:
-- |CODE| SCALE
-- |  1 | verbose 1 (customizable): BAD, MEDIOCRE, AVERAGE, GOOD, GREAT
-- |  2 | verbose 2 (customizable): 1. BAD, 2. MEDIOCRE, 3. AVERAGE, 4. GOOD, 5. GREAT
-- |  3 | numeric: 1, 2, 3, 4, 5
-- |  4 | numeric extended: 1, 2(—/+), 3(—/+), 4(—/+), 5(—/+)
-- |  5 | numeric Roman: I, II, III, IV, V
-- |  6 | numeric Roman Unicode: (5 ranks, won't display inside the script)
-- |  7 | numeric pictogram 1: (encircled numbers black on white,
--        5 ranks, won't display inside REAPER IDE)
-- |  8 | numeric pictogram 2: (encircled numbers white on black,
--        5 ranks, corrupted inside REAPER IDE)
-- |  9 | alphabetic: F, D, C, B, A
-- | 10 | alphabetic extended: F, D(—/+), C(—/+), B(—/+), A(—/+)
-- | 11 | pictogram (customizable): *, **, ***, ****, ***** (the original
--        pictogram is "Black Star" (U+2605), corrupted inside REAPER IDE)

-- Between the quotation marks insert a number which
-- corresponds to the scale type from the table above;
-- the setting can be empty when ENABLE_COLOR_SCALE setting
-- is enabled below if you only intend to use rank color scale;
-- if not empty but invalid defaults to scale 1
SCALE_TYPE = "1"


-- Only relevant if SCALE_TYPE number is 11
-- otherwise this setting is ignored
-- characters !, # and | are unsupported
CUSTOM_PICTOGRAM = ""


-- Enable by inserting any alphanumeric character between
-- the quotes to instruct the script to color take markers
-- when adding rank value;
-- the default rank color scale consists of 5 colors:
-- 5) green, 4) blue, 3) orange, 2) red, 1) black
-- and can be cuztomized with the CUSTOM_COLOR_SCALE
-- setting below;
-- this setting can complement SCALE_TYPE setting
-- or be used alone;
-- if enabled SCALE_TYPE is longer than the color scale,
-- either default or custom, the colors will repeat every
-- as many ranks as the length of the color scale,
-- e.g. if SCALE_TYPE length is 9 while color scale length
-- is 5, when rank 7 is selected, scale color 2 will be
-- applied because 7-5 is 2 and so on;
-- when this setting is disabled, the color of rank markers
-- in takes will be set to theme's default, unless
-- the CUSTOM_DEFAULT_MARKER_COLOR setting is enabled below
ENABLE_COLOR_SCALE = "1"


-- If SCALE_TYPE is 1 or 2 the scale can be customized
-- either partially or entirely both with respect to rank
-- descriptors and to their overall count;
-- for this between the quotation marks insert a comma separated
-- list of words to describe ranks in ascending order;
-- if you only need to customize certain rank descriptors
-- in the current scale, e.g. the 1st or the 1st and the 2nd,
-- etc., then listing all isn't necessary,
-- to customize selection of ranks add commas without adding
-- the description for ranks whose description does't need
-- modification, e.g. "awful,,so so" -- only ranks 1 and 3
-- OR ",passable,,decent" -- only ranks 2 and 4;
-- if you customize the scale selectively the scale length
-- must not exceed the one enabled in the SCALE_TYPE setting;
-- upper case rank descriptors are advisable for greater
-- readability;
-- when customizing SCALE_TYPE 2 no need to precede rank
-- descriptors with numbers, those will be added automatically;
-- of course custom scale doesn't have to be focused on
-- the degrees of greatness, it can be comprised of a list
-- of other quality descriptors, e.g.
-- "SAD, HAPPY, FUNNY, WIERD, JARRING, QUIET" etc.,
-- basically anything you might find useful to label the
-- items/takes with, including names of categories, chords,
-- tempos, instrument types, sound types, origin etc. etc.
CUSTOM_VERBOSE_SCALE = ""


-- If ENABLE_COLOR_SCALE setting is enabled the color scale
-- can be customized partially or entirely both with respect
-- to colors and their overall count;
-- for this between the quotation marks insert a comma
-- separated list of HEX color codes in ascending order;
-- if you only need to customize certain colors in the default
-- color scale which includes 5 colors (see their list in the
-- description of ENABLE_COLOR_SCALE setting above),
-- e.g. the 1st or the 1st and the 2nd, etc., specifying all
-- 5 isn't necessary, to customize selection of rank colors
-- add commas without adding the HEX code for ranks whose color
-- does't need modification, e.g. "#4287f5,,#ec42f5" -- only
-- ranks 1 and 3 OR ",#4287f5,,#ec42f5" -- only ranks 2 and 4;
-- the HEX code may or may not be preceded with hash # sign,
-- can consist of only 3 digits if they repeat,
-- i.e. #0fc (same as #00ffcc), the letter register is
-- immaterial, i.e. #0fc = #0FC;
-- if the HEX code happens to be invalid, it's ignored
-- and script default rank color is used;
-- if you customize the scale selectively the scale length
-- must not exceed 5, which is the default color scale length;
-- if SCALE_TYPE is disabled, ENABLE_COLOR_SCALE setting
-- is enabled and custom color scale is chosen in this
-- setting, the menu won't list names of the custom colors,
-- only corresponding rank numbers;
-- if you wish to unclude the names in the menu, append color
-- labels to the HEX code after a colon, e.g.
-- "#4287f5:my color1,,#ec42f5:my color3"
CUSTOM_COLOR_SCALE = ""


-- Enable by inserting any alphanumeric character between
-- the quotes to instruct the script to add a block fill
-- to the take rank marker name field to make the rank
-- color more apparent;
-- only relevant if ENABLE_COLOR_SCALE setting is enabled
-- and SCALE_TYPE setting is disabled
FILL = "1"


-- Insert color HEX code between the quotation marks
-- if with ENABLE_COLOR_SCALE setting being is disabled
-- you'd still like rank markers color to be different
-- from the theme's default take marker color;
-- note that in REAPER builds supporting different theme
-- color for marker in selected and non-selected items,
-- this setting will apply to marker regardless of the item
-- selection;
-- the HEX code may or may not be preceded with hash # sign,
-- can consist of only 3 digits if they repeat,
-- i.e. #0fc (same as #00ffcc), the letter register is
-- immaterial, i.e. #0fc = #0FC;
-- if the setting is invalid theme's default take marker
-- color will be used
CUSTOM_DEFAULT_MARKER_COLOR = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------



local r = reaper


local Debug = not select(2, r.get_action_context()):match('.+[\\/]BuyOne_') -- in public scripts audomatically disabled
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
--	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	if Debug then
	r.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function no_undo()
do return end
end


function space(n) -- number of repeats, integer
return (' '):rep(n)
end


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
-- want_color is boolean to enable temporary ruler coloring to emphasize the error
-- want_blink is boolean to enable ruler color blinking
local x, y = r.GetMousePosition()
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


function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return
	end
return c
end


function HEX_color_2_integer(HEX)
-- tonumber(HEX:gsub('#',''), 16) isn't suitable because it converts into a big endian number whereas color code is little endian
local r,g,b = HEX:match('(%x%x)(%x%x)(%x%x)')
r, g, b = tonumber(r,16), tonumber(g,16), tonumber(b,16)
return r|g<<8|b<<16 -- OR r+(g<<8)+(b<<16)
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
	-- by the absence if the gfx window therefore only disable it in builds
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



function Get_Lock_Settings()
local lock_sett_t = {
1135, -- Options: Toggle locking // always Off when there're no set flags
-- and cannot be set to On without at least one flag being set

-- 0, -- placeholder for no_flags var // USELESS because when lock (above action)
-- isn't enabled the following toggle actions don't report the state of their flags
-- so it's impossible to find which flags are set unless lock is enabled,
-- when no flag is set lock cannot be enabled

-- all following actions are On ONLY if 'Options: Toggle locking' is On
-- they don't report On state when their flag is set but the lock isn't enabled
-- when lock isn't enabled toggling them to On automatically enables lock
40573, -- Locking: Toggle time selection locking mode
40576, -- Locking: Toggle full item locking mode
40585, -- Locking: Toggle track envelope locking mode
40591, -- Locking: Toggle marker locking mode
40588, -- Locking: Toggle region locking mode
40594, -- Locking: Toggle time signature marker locking mode
40579, -- Locking: Toggle left/right item locking mode
40582, -- Locking: Toggle up/down item locking mode
40597, -- Locking: Toggle item edges locking mode
40600, -- Locking: Toggle item fade/volume handles locking mode
40629, -- Locking: Toggle loop points locking mode
41851, -- Locking: Toggle take envelope locking mode
41854 -- Locking: Toggle item stretch marker locking mode
}

	for i, cmd_ID in ipairs(lock_sett_t) do
	lock_sett_t[i] = r.GetToggleCommandStateEx(0, cmd_ID) == 1
	end

return lock_sett_t -- 14 return values
-- enabled, time_sel, itms_full, tr_env, proj_mrk, rgn, time_sig_mrk, itm_horiz_move, itm_vert_move, itm_edges, itm_fade_vol_hand, loop_pts, take_env, stretch_mrk

end



function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end



function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local sws_ext_err_mess = "              The size of data requires\n\n     the SWS/S&M extension to handle them.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
local sws_ext_link = 'Get the SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
local resp = r.MB(sws_ext_err_mess,'ERROR',0)
	if resp == 1 then r.ShowConsoleMsg(sws_ext_link, r.ClearConsole()) return end
end



function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
local env = r.ValidatePtr(obj, 'TrackEnvelope*') -- works for take envelope as well
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



function CountVisibleTracks(want_tcp, want_mcp)
local cnt = 0
	for i=0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local tcp = r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1
	local mcp = r.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER') == 1
	-- OR
	-- tcp = r.IsTrackVisible(tr, false) -- mixer_vis false
	-- mcp = r.IsTrackVisible(tr, true) -- mixer_vis true
		if want_tcp and want_mcp and tcp and mcp
		or want_tcp and tcp or want_mcp and mcp then
		cnt = cnt+1
		end
	end
return cnt
end



function Select_Items_With_Take_Of_Particular_Rank(item, act_scale_t, color_scale_t, rank_idx, want_active)
-- item is item under mouse which will be retrieved before the menu is called
-- because if attempted to be retrieved afterwards the result will likely be false
-- since when the menu is clicked the mouse will be away from the item
-- rank_idx is calculated index returned by the menu
-- want_active is boolean to only target markers in active take

	local function SELECT_ITEMS(item, scale_t, act_scale_t, val, was_selected)
	local act_take = r.GetActiveTake(item)
		for i=0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, i)
			if want_active and take == act_take or not want_active then -- empty items don't have takes, as soon as take marker is added to an empty item a take is created in it
				for i=0, r.GetNumTakeMarkers(take)-1 do
				local pos, name, color = r.GetTakeMarker(take, i)
					if act_scale_t and val == name or val == color-0x1000000 -- subtracting the value which allows to apply the color returned with the color value
					then
						if not was_selected then
						r.SelectAllMediaItems(0, false) -- deselect all once a marker was found
						was_selected = 1 -- prevent deselection in subsequent cycles
						end
					r.SetMediaItemSelected(item, true)
					return true end
				end -- markers loop end
			end
		end -- takes loop end
	end

local scale_t = act_scale_t or color_scale_t
local val = scale_t[rank_idx]
local where = 'items '
local was_selected

	if item and r.GetTake(item, 0) then -- item with takes under mouse, empty items don't have takes
	where = 'under mouse'
	r.SelectAllMediaItems(0, false) -- deselect all once a marker was found
	was_selected = SELECT_ITEMS(item, scale_t, act_scale_t, val)
	else
	local cnt = r.CountSelectedTracks(0)
	local tr_cnt = cnt > 0 and cnt or r.CountTracks(0)
	local GetTrack = cnt > 0 and r.GetSelectedTrack or r.GetTrack
	where = cnt > 0 and 'on selected tracks' or 'in the project'
		for i=0, tr_cnt-1 do
		local tr = GetTrack(0,i)
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- only visible in Arrange
				for i=0, r.CountTrackMediaItems(tr)-1 do
				local item = r.GetTrackMediaItem(tr,i)
				local retval = SELECT_ITEMS(item, scale_t, act_scale_t, val, was_selected)
				was_selected = was_selected or retval
				end -- items loop end
			end
		end
		-- if operation on all items in project is successful while all visible tracks are selected
		-- only leave the 1st one selected
		if was_selected and r.CountSelectedTracks(0) == CountVisibleTracks(1) then -- want_tcp true
		r.SetOnlyTrackSelected(r.GetSelectedTrack(0,0))
		end
	end

val = act_scale_t and val or math.floor(#color_scale_t-rank_idx+1) -- for color scale only list calculated rank number (calculated because it won't match its index in the table where ranks are arranged in descending order, so 1 in the default color scale table will match rank 5); trimming trailing decimal zero

	if not was_selected then
	local act = want_active and 'active ' or ''
	Error_Tooltip('\n\n no '..act..'takes \n\n ranked '..val..' \n\n were found '..where..' \n\n', 1, 1) -- caps, spaced true
	return end

r.UpdateArrange() -- to update change in selection

return val..' '..where

end


function Set_Take_Of_Particular_Rank_Active(item, act_scale_t, color_scale_t, rank_idx)
-- item is item under mouse which will be retrieved before the menu is called
-- because if attempted to be retrieved afterwards the result will likely be false
-- since when the menu is clicked the mouse will be away from the item
-- rank_idx is calculated index returned by the menu

	local function SET_ACTIVE(item, act_scale_t, scale_t, val)
	local take_cnt = r.CountTakes(item)
		if take_cnt == 1 then return end -- no point to continue because a single take is always active
		for i=0, take_cnt-1 do
		local take = r.GetTake(item, i)
			if r.GetActiveTake(item) ~= take then -- OR r.GetMediaItemInfo_Value(item, 'I_CURTAKE') == i
				for i=0, r.GetNumTakeMarkers(take)-1 do
				local pos, name, color = r.GetTakeMarker(take, i)
					if act_scale_t and val == name or val == color-0x1000000 -- subtracting the value which allows to apply the color returned with the color value
					then
					r.SetActiveTake(take)
					return true end
				end
			end
		end
	end


local scale_t = act_scale_t or color_scale_t
local val = scale_t[rank_idx]
local was_set, where

	if item then -- item under mouse
	where = 'in item under mouse'
	was_set = SET_ACTIVE(item, act_scale_t, scale_t, val)
	elseif r.CountSelectedMediaItems(0) > 0 then -- selected items
	where = 'in selected items'
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if r.IsMediaItemSelected(item) then
			local retval = SET_ACTIVE(item, act_scale_t, scale_t, val)
			was_set = was_set or retval
			end
		end
	else -- selected tracks or all tracks/all items
	local cnt = r.CountSelectedTracks(0)
	local tr_cnt = cnt > 0 and cnt or r.CountTracks(0)
	local GetTrack = cnt > 0 and r.GetSelectedTrack or r.GetTrack
	where = 'in items '
	where = cnt > 0 and where..'on selected tracks' or where..'in the project'
		for i=0, tr_cnt-1 do
		local tr = GetTrack(0,i)
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- only visible in Arrange
				for i=0, r.CountTrackMediaItems(tr)-1 do
				local item = r.GetTrackMediaItem(tr,i)
				local retval = SET_ACTIVE(item, act_scale_t, scale_t, val)
				was_set = was_set or retval
				end
			end
		end
		-- if operation on all items in project is successful while all visible tracks are selected
		-- only leave the 1st one selected
		if was_set and r.CountSelectedTracks(0) == CountVisibleTracks(1) then -- want_tcp true
		r.SetOnlyTrackSelected(r.GetSelectedTrack(0,0))
		end
	end

val = act_scale_t and val or math.floor(#color_scale_t-rank_idx+1) -- for color scale only list calculated rank number (calculated because it won't match its index in the table where ranks are arranged in descending order, so 1 in the default color scale table will match rank 5); trimming trailing decimal zero

	if not was_set then
	Error_Tooltip('\n\n no (inactive) takes \n\n ranked '..val..' were found \n\n '..where..'\n\n', 1, 1) -- caps, spaced true
	return end

r.UpdateArrange() -- to update change in selection

return val..' active '..where

end



function Collect_Take_Data_For_Sorting(item, act_scale_t, color_scale_t, sort_dir, calc)
-- the sorting is done with Sort_Takes()
-- item is item under mouse which will be retrieved with GetItemFromPoint() before the menu is called
-- because if attempted to be retrieved afterwards the result will likely be false
-- since when the menu is clicked the mouse will be away from the item

	local function collect_take_data(item, act_scale_t, color_scale_t, scale_t, sort_dir, take_t, calc)
	-- collecting take rank and GUID data for subsequent sorting
	-- take_t structure:
	-- t[item1] = {[take idx 1] = {rank}, [take idx 2] = {rank}, ...}
	-- t[item2] = {[take idx 1] = {rank}, [take idx 2] = {rank}, ...}
	local desc, asc = sort_dir == 'desc', sort_dir == 'asc'
	local no_mrkrs = 1
	local take_cnt = r.CountTakes(item)
	-- empty items don't have takes, as soon as take marker is added to an empty item a take is created in it
		if take_cnt == 1 and not calc then return end -- no point to continue because a single take cannot be sorted, unless the data is collected for average/median rank calculation with Calculate_Average_And_Median_Take_Rank()
		for i=0, take_cnt-1 do
		local take = r.GetTake(item, i)
		local ret, GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
			if not take_t then -- will be true at the very loop start for takes of the first item if there're many
			take_t = {}
			end
		take_t[item] = take_t[item] or {} -- to collect take data, either reuse or intialize
		local len1 = #take_t[item]
		take_t[item][len1+1] = {} -- OR take_t[item][i+1] -- using 1-based take indices // table to collect take data
		take_t[item][len1+1].rank = {} -- OR take_t[item][i+1].rank using 1-based take indices // first collect all rank markers of the active scale in the take, in case there're more than 1, to be able to determine the highest/lowest amongst them
			for i=0, r.GetNumTakeMarkers(take)-1 do
			local pos, name, color = r.GetTakeMarker(take, i)
				for k, rank in ipairs(scale_t) do
					if act_scale_t and rank == name or rank == color-0x1000000 -- matching rank marker found, subtracting the value which is returned with the color value
					then
					local idx = #scale_t-k+1 -- calculate rank index so it matches the actual rank because scale table indices don't match the rank for the sake of easiness of the menu concatenation, i.e. in 5 rank scale table index 1 will match rank 5
					local len2 = #take_t[item][len1+1].rank
					take_t[item][len1+1].rank[len2+1] = idx
					end
				end
			end
			if #take_t[item][len1+1].rank > 0 then -- there're take markers in the take, sort
			local t = take_t[item][len1+1].rank -- for brevity
				if #t > 1 then -- probably unnecessary, but just in case for efficiency
				-- sort rank markers within take
				-- if overall sorting order is descending, marker with the highest rank will be preferred within the take
				-- if overall sorting order is ascending, marker with the lowest rank will be preferred within the take
				table.sort(t, function(a,b) return desc and a > b or asc and a < b end)
				end
			take_t[item][len1+1].rank = take_t[item][len1+1].rank[1] -- assign final rank for the take for subsequent take sorting, having replaced the marker table with the rank value
			no_mrkrs = not calc and #take_t[item] == 1 -- if there's only one take with markers ranked in the active scale, keep no_mrkrs true because in this case as well no sorting is possible, unless the data is collected for  average/median rank calculation with Calculate_Average_And_Median_Take_Rank()
			else
			-- if there're no markers or no rank markers or no rank markers in the active scale in the take
			-- the take after sorting will be relegated to the very bottom of the item regardless of the sorting direction
			take_t[item][len1+1].rank = desc and 0 or asc and #scale_t+1
			end
		end
	return take_t, no_mrkrs
	end


local scale_t = act_scale_t or color_scale_t
local where --, vailable
local take_t, no_mrkrs

	if item then -- item under mouse
	where = 'in item under mouse'
	take_t, no_mrkrs = collect_take_data(item, act_scale_t, color_scale_t, scale_t, sort_dir, take_t, calc)
	elseif r.CountSelectedMediaItems(0) > 0 then -- selected items
	where = 'in selected items'
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if r.IsMediaItemSelected(item) then
			take_t, no_mrkrs = collect_take_data(item, act_scale_t, color_scale_t, scale_t, sort_dir, take_t, calc)
			end
		end
	else -- selected tracks or all tracks/all items
	local cnt = r.CountSelectedTracks(0)
	local tr_cnt = cnt > 0 and cnt or r.CountTracks(0)
	local GetTrack = cnt > 0 and r.GetSelectedTrack or r.GetTrack
	where = 'in items '
	where = cnt > 0 and where..'\n\n on selected tracks' or where..'\n\n in the project'
		for i=0, tr_cnt-1 do
		local tr = GetTrack(0,i)
			for i=0, r.CountTrackMediaItems(tr)-1 do
			local item = r.GetTrackMediaItem(tr,i)
			take_t, no_mrkrs = collect_take_data(item, act_scale_t, color_scale_t, scale_t, sort_dir, take_t, calc)
			end
		end
	end

	if not take_t or no_mrkrs then
	local take = 'multiple takes'
	local take = not take_t and take or take..' \n\n ranked in active scale'
	Error_Tooltip('\n\n no '..take..' \n\n were found '..where..' \n\n', 1, 1) -- caps, spaced true
	return end

return take_t, where

end



function Sort_Takes(take_t, sort_dir)
-- take_t comes from Collect_Take_Data_For_Sorting()
-- take_t structure:
-- t[item1] = {[take idx 1] = {rank}, [take idx 2] = {rank}, ...}
-- t[item2] = {[take idx 1] = {rank}, [take idx 2] = {rank}, ...}

	local function is_table_already_sorted(t, dir)
	-- dir is integer, sorting direction to be evaluated
	-- 1 - ascending, 2 descending
	---------------------------------
	-- collect ranks of each take into temp table t2
	local t2 = {}
		for k, tab in ipairs(t) do
		t2[k] = tab.rank
		end
	local t2_concat = table.concat(t2,',') -- convert into string before sorting
	local asc, desc = dir == 1, dir == 2
	-- if ascending the function isn't needed but leaving it for consistency
	table.sort(t2, function(a,b) return asc and a < b or desc and a > b end) -- sort the temp table
	return t2_concat == table.concat(t2,',') -- compare before and after sorting
	end

local desc, asc = sort_dir == 'desc', sort_dir == 'asc'
local failed, sorted = 1, 1

r.PreventUIRefresh(1)

	for item, t in pairs(take_t) do -- t contains take tables which contain rank data
		if not is_table_already_sorted(t, desc and 2 or asc and 1) then -- preventing the action on already sorted items
		sorted = nil
		local ret, chunk = GetObjChunk(item)
			if chunk then -- chunk was extracted, if error the second value isn't returned
			failed = nil
		-- store to re-enable after sorting to maintain the active take
		-- because currently active take is likely to move
			local act_take = r.GetActiveTake(item)
			local ret, act_GUID = r.GetSetMediaItemTakeInfo_String(act_take, 'GUID', '', false) -- setNewValue false // this will ensure that the same take remains active no matter the position
			-- split chunk between takes
			local header = chunk:match('(.-)\nNAME')
			t[#t].chunk = chunk:match('.+(\nNAME.+)\n>') -- last take chunk just before item chunk closure >, add to last take table
			local i, st, fin, capt = 1, 0, 0
				repeat
				st, fin, capt = chunk:find('(\nNAME.-)\nTAKE[%W]', fin) -- excluding TAKE token from the capture because the first one won't have it anyway, will be re-added afterwards
					if not st then break
					else
					t[i].chunk = capt; i=i+1
					end
				until not st
			table.sort(t, function(a,b) return desc and a.rank > b.rank or asc and a.rank < b.rank end)
			-- reconstruct chunk
			local chunk_sorted = header
				for k, data in ipairs(t) do
				chunk_sorted = chunk_sorted..(k > 1 and '\nTAKE' or '')..data.chunk -- take 1 isn't preceded by TAKE token
				end
			chunk_sorted = chunk_sorted..'\n>' -- close item chunk
			SetObjChunk(item, chunk_sorted)
			local act_take = r.GetMediaItemTakeByGUID(0, act_GUID) -- this ensures that the same take remains active no matter the position
			r.SetActiveTake(act_take)
			end
		end
	end

local mess = sorted and 'all tagret items are sorted'
or failed and '   unfortunately sorting \n\n has failed. likely due to \n\n\t inaccessibility \n\n\t   of item data'

	if mess then
	Error_Tooltip('\n\n '..mess..' \n\n', 1, 1) -- caps, spaced true
	return end

r.UpdateArrange() -- to update change in active take

r.PreventUIRefresh(-1)

return true

end



function Calculate_Average_And_Median_Take_Rank(item, take_t, act_scale_t, color_names_t, typ, SCALE_TYPE)
-- item is item under mouse which will be retrieved with GetItemFromPoint() before the menu is called
-- because if attempted to be retrieved afterwards the result will likely be false
-- since when the menu is clicked the mouse will be away from the item
-- take_t comes from Collect_Take_Data_For_Sorting()
-- color_names table is used because SCALES.colors contains integer color values which don't make sense for the user
-- take_t structure:
-- t[item1] = {[take idx 1] = {rank}, [take idx 2] = {rank} ...}
-- t[item2] = {[take idx 1] = {rank}, [take idx 2] = {rank} ...}
-- typ is 'average' or 'median' determined by the menu output

	local function constr_ext_scale_descr(val, scale_t)
	-- used inside construct_result_descr()
	-- for extended scale the final rank is calculated here by converting 13 ranks scale into the 5 ranks one because minuses and pluses still represent fractions of the 5 rank scale, plus reprensents the range between the whole rank and 0.4 of the rank above it, e.g. between 4 and 4.49, minus represents range between whole rank and 0.5 rank below it, e.g. between 5 and 4.5
	local fl = math.floor
	local val_conv = fl((val/(13/5)*(10^2) + 0.5))/10^2 -- convert val from 13 rank scale (number of rank items in extended scale) into 5 rank scale which it actually is, rounding the value down to 2 decimal places
	local val_rnd = math.floor(val_conv+0.5)
	return val_rnd..(val_rnd > val_conv and '—' or val_rnd < val_conv and '+' or '') -- append plus or minus depending on the range above or below the rounded value
	..' ( '..(fl(val) == val and fl(val) or val)..' out of '..#scale_t -- numeric average in the scale of 13 ranks
	..' OR '..(val_rnd == val_conv and val_rnd or val_conv)..' out of 5 )' -- numeric average in the scale of 5 ranks
	end

	local function construct_result_descr(val, scale_t, SCALE_TYPE)
	-- val is a calculated average or median value
	---------------------- accounting for extended scales ------------
	local ext_scale = SCALE_TYPE == 4 or SCALE_TYPE == 10 -- scales with pluses and minuses
	local idx = not ext_scale and math.floor(val+0.5) -- calculate integer value to use for extraction of rank descriptor from active scale table scales_t // ignoring extended scale
	local desc = not ext_scale and (idx < val and 'Above ' or idx > val and 'Below ' or '') -- define description depending on whether the index is smaller or greater than the original value or is equal to it // ignoring extended scale, for extended scales above/below are irrelevant because minuses and pluses by themselves indicate whether the value is above or below the whole value
	idx = not ext_scale and #scale_t-idx+1 -- calculate rank index relevant for the scale_t table because there rank descriptors are arranged in descending order for ease of menu concatenation and rank indices don't match ranks, i.e. 1 = rank 5, 2 = rank 4, 3 = rank 3, 4 = rank 2, 5 = rank 1 // ignoring extended scale
	-------------------------------------------------------------------
	local fl = math.floor
	return ext_scale and constr_ext_scale_descr(val, scale_t)
	or desc..scale_t[idx]..'  ( '..(fl(val) == val and fl(val) or val)..' out of '..#scale_t..' )' -- trimming trailing decimal 0 in integer	// OR string.format('%s%s ( %s out of %s )', desc, scale_t[idx], (fl(val) == val and fl(val) or val), #scale_t)
	end

local average, median = typ == 'average', typ == 'median'
local scale_t = act_scale_t or color_names_t -- color_scale_t values aren't suitable for rank names display concatenated inside construct_result_descr() function because it contains color integer values rather than rank descriptors
local rank_mrkr_cnt, rank_sum = 0, 0
local median_t = {}
-- 'where' variable depends on Collect_Take_Data_For_Sorting() because
-- that's where the target is determined and takes are collected
local where = item and 'item at cursor' or r.CountSelectedMediaItems(0) > 0 and 'selected items'
or r.CountSelectedTracks(0) < CountVisibleTracks(1) and 'items on selected tracks' -- want_tcp true
or 'items in the project'
local val

	for item, t in pairs(take_t) do -- t contains take tables which contain rank data
		for k, data in ipairs(t) do
		local rank = data.rank
		local within_range = rank > 0 and rank <= #scale_t -- if there're no rank markers in take it's rank is either set to 0 or to #scale_t+1 in Collect_Take_Data_For_Sorting() depending on the sort_dir value so basically outside of rank scale scope, if it's 0, it won't affect the sum, if it's #scale_t+1 set it to 0 here so it's ignored; although for average and median calculation it will be set to 0 inside Collect_Take_Data_For_Sorting(); the rank value is taken in Collect_Take_Data_For_Sorting() from the active scale table index
			if average then
			rank_sum = rank_sum + (within_range and rank or 0)
			rank_mrkr_cnt = rank_mrkr_cnt + (within_range and 1 or 0) -- the length of t is equal the number of takes in item, each take has 1 rank, for the current operation marker ranked the highest will have priority in takes with multiple markers ranked in the active scale; however takes with no rank, i.e. whose rank is set to 0 or #scale_t+1 will not be counted
			elseif median and within_range then
			median_t[#median_t+1] = rank
			end
		end
	end

	if average then
	val = math.floor((rank_sum/rank_mrkr_cnt)*(10^2) + 0.5)/10^2 -- truncating down to two decimal places
	val = construct_result_descr(val, scale_t, SCALE_TYPE)
	elseif median then
	table.sort(median_t, function(a,b) return a > b end) -- make sure that the sequence is sorted in descending order because this is how ranks are arranged in the active scale table scale_t, the order won't affect the median value
	local idx = (#median_t+1)/2 -- adding 1 allows dividing odd length (number of values) without remainder and thus figuring out the center index, e.g. in table 1,2,3 the center index is 2 which will be calculated by dividing 4 (3+1) by 2
	-- if the length (number of values) is even, e.g. 1,2,3,4, dividing 5 (4+1) by 2 will produce 2.5
	-- which in turn will point at two incices 2 and 3 which share the center
		if (#median_t+1)%2 == 0 then -- OR math.floor(idx) == idx // divided without remainder, i.e. odd number sequence
		val = median_t[idx]
		else -- even number sequence, calculate between two central values
		val = (median_t[math.floor(idx)] + median_t[math.ceil(idx)])/2
		end
	val = construct_result_descr(val, scale_t, SCALE_TYPE)
	end

	if val then -- display value
	r.MB(val, typ:upper()..' rank in '..where, 0)
	return end

end





function Proj_Time_2_Item_Time(proj_time, item, take)
-- e.g. edit/play cursor, proj markers/regions time
-- to take envelope points, take/stretch markers and transient guides time

local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
--OR
--local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local within_view = proj_time >= item_pos and proj_time <= item_end -- can be used as a condition to return value if only visible item area is relevant
local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset and take marker pos
local item_time = (proj_time - item_pos + offset)*playrate

return item_time

end


function Item_Time_2_Proj_Time(item_time, item, take)
-- such as take envelope points, take/stretch markers and transient guides time,
-- item_time is their position within take media source returned by the corresponding functions
-- e.g. take envelope points, take/stretch markers and transient guides time
-- to edit/play cursor, proj markers/regions time

local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
--OR
--local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
local item_end = item_pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset and take marker pos
local proj_time = item_pos + (item_time - offset)/playrate

return proj_time >= item_pos and proj_time <= item_end and proj_time -- ignoring content outside of item bounds

end



function Get_Mrkrs_Of_Takes_At_Mouse_Or_Edit_Curs()

	local function get_take_mrkrs_at_curs(t, item, take, curs_pos)
		for i=r.GetNumTakeMarkers(take)-1,0,-1 do -- in reverse to catch the first take marker left of mouse cursor if there's none under the mouse
		local pos, name, color = r.GetTakeMarker(take, i)
		local pos_proj = Item_Time_2_Proj_Time(pos, item, take) -- the function only returns value if marker is within visible item area
			if pos_proj and pos_proj <= curs_pos then -- take marker is within visible item area and under or just left of the mouse cursor
			t[item].mrkr_idx, t[item].pos, t[item].name, t[item].col = i, pos, name, color
			break end
		end
	return t
	end

local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, false) -- 0 allow_locked false
local curs_pos_init = r.GetCursorPosition()
local GET = r.GetMediaItemInfo_Value

local t = {}
	if take then -- if take under mouse, track from point prevents getting
		if GET(item, 'C_LOCK')&1 == 1 then
		Error_Tooltip('\n\n the item is locked \n\n', 1, 1) -- caps, spaced true
		return end
	-- get mouse position
	r.PreventUIRefresh(1)
	r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)
	local curs_pos = r.GetCursorPosition()
	r.SetEditCurPos(curs_pos_init, false, false) -- moveview, seekplay false // restore
	r.PreventUIRefresh(-1)
	local take_idx = r.GetMediaItemTakeInfo_Value(take, 'IP_TAKENUMBER')
	t[item] = {idx=take_idx} -- if no markers in the take or no left of cursor one will be inserted; item pointer and take index are stored to be able to get take with GetTake(item, t.idx)
	t = get_take_mrkrs_at_curs(t, item, take, curs_pos)
	curs_pos_init = curs_pos -- assign mouse position to the var so that's what's returned at the end of the function
	else -- scan items under the edit cursor
	-- REAPER devs don't recommend using CountSelectedMediaItems()
	-- and GetSelectedMediaItem but to rely on CountMediaItems()
	-- and IsMediaItemSelected() instead
	-- https://forum.cockos.com/showthread.php?p=2807092#post2807092
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if GET(item, 'C_LOCK')&1 ~= 1 then -- not locked
			local item_st = GET(item, 'D_POSITION')
			local item_end = item_st + GET(item, 'D_LENGTH')
				if r.IsMediaItemSelected(item) and curs_pos_init > item_st and curs_pos_init <= item_end then -- item under edit cursor
				local take = r.GetActiveTake(item)
					if take then -- only respecting active take in each item and ignoring empty items which don't have takes
					local take_idx = r.GetMediaItemTakeInfo_Value(take, 'IP_TAKENUMBER')
					t[item] = {idx=take_idx} -- if no markers in the take or no left of cursor one will be inserted; item pointer and take index are stored to be able to get take with GetTake(item, t.idx)
					t = get_take_mrkrs_at_curs(t, item, take, curs_pos_init)
					end
				end
			end
		end
	end

return t, curs_pos_init

end



function reuse_short_array_over_long(t1, t2, k2)
-- if two arrays must be used in parallel
-- and index k2 of the long array t2 exceeds the range of the short one t1
-- cycle indices of the short array, reusing its values
-- but in reverse, e.g. if t2 is '1,2,3,4,5,6,7'
-- and t1 is 'a,b,c', count from 7 and c respectively,
-- and when k2 goes beyond 5 the count of t1 is restarted
-- so that 4 matches c, 3 matches b and 2 matches 1
-- and so on

local k1 = k2
	if #t1 < #t2 then
	-- limit is the value after which the shorter table cycle is restarted
	local limit = #t2 - #t1
	k1 = k2 - limit
		if k2 <= limit then
		local int, fraq = math.modf(k2/#t1)
		local modulo = (#t2-k2)%#t1
		k1 = modulo == 0 and #t1 or #t1-modulo
		end
	end
return k1
end



function Set_Or_Change_Rank(mrkrs_t, SCALES, rank_new, curs_pos, act_scale_t, CUSTOM_DEFAULT_MARKER_COLOR)
-- rank_new is integer which comes from the menu item if directly sent from the menu
-- if however up/down-rank buttons were used rank_new will be 0 for up-rank and -1 for down-rank
-- cur_pos is only relevant for setting markers

local no_mrkr_cnt, undo = 0
local scales_diff = 1 -- used as a condition to generate error message if the scale of all markers is different from the active one when up/down-ranking options are used, which will prevent rank change
local rank_col = act_scale_t and reuse_short_array_over_long(SCALES.colors, act_scale_t, rank_new) or rank_new -- if only color scale is enabled in which case act_scale_t is nil so no need to match between active and color scales, apply the user choice directly

	for item, props in pairs(mrkrs_t) do
	local take_idx, mrkr_idx, mrkr_pos, mrkr_name, mrkr_col = props.idx, props.mrkr_idx, props.pos, props.name, props.col
	local take = r.GetTake(item, take_idx)
		if mrkr_idx then -- marker exists, analyze and change rank
			if rank_new < 1 then -- up/down-rank by incrementing current rank, because in this case rank_new value is set to 0 or -1 respectively
			local up, down = rank_new == 0, rank_new < 0
			local was_set
				if act_scale_t then -- will be nil if only color scale is enabled
				-- find marker current rank and change relative to it
					for scale_name, scale_t in pairs(SCALES) do
						if #scale_t == #act_scale_t -- only respecting scales equal in length to the current
						and scale_name ~= 'colors' then -- ignoring colors table because it's not based on labels, fill table is ignored naturally because its length won't match any act_scale_t length
							for rank, descr in ipairs(scale_t) do
								if mrkr_name == descr then -- current rank found
								scales_diff = nil -- one matching scale suffices to prevent the error message generated at the bottom of the function

								local mrkr_name = up and act_scale_t[rank-1] or down and act_scale_t[rank+1] -- ranks in the menu are arranged in descending order where the highest is the topmost, therefore the direction of index selection is reversed because the higher the rank the smaller its menu index

									if mrkr_name then -- act_scale_t and hence mrkr_name may be nil if up/down-ranking exceeds the scale range OR if the marker rank scale is shorter than the active scale (which is nevertheless unlikely because of evaluation of scales length equality above AND MAINLY BECAUSE up/down-rank menu buttons get grayedout if marker scale differs from the active scale, unless those scales have common rank descriptors)

									--	if the active scale is longer than the color scale, the latter will repeat
									local up_idx = reuse_short_array_over_long(SCALES.colors, act_scale_t, rank-1)
									local down_idx = reuse_short_array_over_long(SCALES.colors, act_scale_t, rank+1)

									mrkr_col = ENABLE_COLOR_SCALE and
									( up and SCALES.colors[up_idx]
									or down and SCALES.colors[down_idx] )

									or not ENABLE_COLOR_SCALE and CUSTOM_DEFAULT_MARKER_COLOR  -- when up-ranking 1 is subtracted because ranks are arranged in descending order so the higher the rank the closer it is to the table start and vice versa hence 1 is added when down-ranking; if the color scale is shorter than the active scale, loop around when the index exceeds its range, if ENABLE_COLOR_SCALE is disabled set the color to user/theme's default

									was_set = r.SetTakeMarker(take, mrkr_idx, mrkr_name, mrkr_pos, mrkr_col and mrkr_col|0x1000000 or 0) -- converting custom color into REAPER format, if no custom color reset to theme's default, value 0
									end
								break end -- exit scale_t loop
							end -- scale_t loop end
							if was_set then break end -- exit SCALES loop
						end -- scales equality cond end
					end -- SCALES loop end

				else -- only color scale is enabled, act_scale_t is nil
					for k, color in ipairs(SCALES.colors) do
						if color|0x1000000 == mrkr_col then -- current rank color has been found
						mrkr_col = up and SCALES.colors[k-1] or down and SCALES.colors[k+1] -- when up-ranking 1 is subtracted because ranks are arranged in descending order so the higher the rank the closer it is to the table start and vice versa hence 1 is added when down-ranking
							if mrkr_col then
							mrkr_name = FILL and SCALES.fill[2] or ''
							was_set = r.SetTakeMarker(take, mrkr_idx, mrkr_name, mrkr_pos, mrkr_col|0x1000000) -- converting color into REAPER format
							end
						scales_diff = nil -- one matching color suffices to prevent the error message
						break
						end
					end
				end
			undo = undo or was_set and (rank_new == 0 and 'Up-rank' or 'Down-rank')..' takes' -- will be valid if at least 1 marker rank was changed because it will keep the undo value

			-- rank button was pressed, rank_new is > 0
			elseif act_scale_t and (act_scale_t[rank_new] ~= mrkr_name) -- only if current rank differs from the one selected by the user, act_scale_t may be nil if only color scale us enabled
			or not act_scale_t and ENABLE_COLOR_SCALE and SCALES.colors[rank_new] ~= mrkr_col -- or only color scale is enabled and color of the new rank differs from the current
			then
			mrkr_name = act_scale_t and act_scale_t[rank_new] or FILL and SCALES.fill[2] or '' -- act_scale_t may be nil if only color scale is enabled, FILL is only true if only color scale is enabled

			--	if the active scale is longer than the color scale, the latter will repeat
			mrkr_col = ENABLE_COLOR_SCALE and
			SCALES.colors[rank_col] -- rank_col is calculated at the top of the function
			or not ENABLE_COLOR_SCALE and CUSTOM_DEFAULT_MARKER_COLOR -- if color scale is disabled set to user/theme's default color
			r.SetTakeMarker(take, mrkr_idx, mrkr_name, mrkr_pos, mrkr_col and mrkr_col|0x1000000 or 0) -- converting custom color into REAPER format, if no custom color reset to theme's default, value 0
			undo = 'Rank takes as '..(act_scale_t and mrkr_name or math.floor(#SCALES.colors-rank_new+1)) -- if only color scale is enabled (in which case act_scale_t is nil, list rank index instead but reversed because higher ranks have lower index in the menu, trimming trailing decimal zero
			end

		elseif rank_new > 0 then -- no marker, insert, only if specific rank button was clicked, ignoring up/down-ranking as there's nothing to u/down-rank yet
		curs_pos = Proj_Time_2_Item_Time(curs_pos, item, take)

		mrkr_name = act_scale_t and act_scale_t[rank_new] or FILL and SCALES.fill[2] or '' -- act_scale_t may be nil if only color scale is enabled, FILL is only true if only color scale is enabled

		--	if the active scale is longer than the color scale, the latter will repeat
		mrkr_col = ENABLE_COLOR_SCALE and
		SCALES.colors[rank_col] -- rank_col is calculated at the top of the function
		or not ENABLE_COLOR_SCALE and CUSTOM_DEFAULT_MARKER_COLOR -- if color scale is disabled set to user/theme's default color
		r.SetTakeMarker(take, -1, mrkr_name, curs_pos, mrkr_col and mrkr_col|0x1000000 or 0) -- idx -1 to insert // converting custom color into REAPER format, if no custom color reset to theme's default, value 0
		undo = 'Insert take markers with rank '..(act_scale_t and mrkr_name or math.floor(#SCALES.colors-rank_new+1)) -- if only color scale is enabled (in which case act_scale_t is nil, list rank index instead but reversed because higher ranks have lower index in the menu, trimming trailing decimal zero

		elseif not mrkr_idx then -- no take marker at cursor
		no_mrkr_cnt = no_mrkr_cnt+1
		end
	end

local err = (no_mrkr_cnt == r.CountSelectedMediaItems(0) or no_mrkr_cnt == 1) -- no marker at cursor either in all selected items or in the one under the mouse // usually when up/down-ranking buttons are used
and 'no take marker at the cursor'
or rank_new < 1 and scales_diff -- marker ranks could not be set in all target items with up/down-ranking (rank_new < 1), usually when the marker scale and the active scale differ
and 'new rank could not be set \n\n\t try rank buttons'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, -450) -- caps, spaced true, x2 -450 to prevent overlapping the tooltip by the menu because when up/down-ranking the menu is reloaded
	return end

return undo

end


function Display_Script_Help_Txt(scr_path)
-- scr_path stems from get_action_context()

local help_t = {}
	for line in io.lines(scr_path) do
		if #help_t == 0 and line:match('About:') then
		help_t[#help_t+1] = line:match('About:%s*(.+)')
		about = 1
		elseif line:match(('%-'):rep(41)) then -- excluding the last line and preceding dashed line
		r.ShowConsoleMsg(table.concat(help_t,'\n'), r.ClearConsole()) return -- trimming the first line of user settings section because it's captured by the loop
		elseif about then
		help_t[#help_t+1] = line:match('%s*(.-)$')
		end
	end
end



function up_down_rank_grayout(mrkrs_t, act_scale_t, color_scale)
local up_rank_grayout, down_rank_grayout = '#','#'

-- grayout if all markers at cursor are ranked the highest or the lowest
local scale_t = act_scale_t or color_scale
	for item, props in pairs(mrkrs_t) do
	local val = act_scale_t and props.name or props.col and props.col-0x1000000 -- subtracting the value which allows to apply the color returned with the color value // both props.name and props.col can be nil if no markers at cursor
		if val then -- can be nil if no markers at cursor
			for k, rank in ipairs(scale_t) do
				if val == rank then
					if k ~= 1 then up_rank_grayout = ''	end -- clear grayout char if at least one marker isn't top ranked
					if k ~= #scale_t then down_rank_grayout = '' end -- same for bottom ranked markers
				end
			end
		end
	end

return up_rank_grayout, down_rank_grayout

end


function get_sett(sett, idx)
-- ensures that if setting has never been used yet
-- it will be stored as 0 and not as empty string
local sett = sett:sub(idx,idx)
return #sett > 0 and sett or '0'
end


function menu_check(sett)
return sett == '1' and '!' or ''
end


SCALE_TYPE = SCALE_TYPE:gsub(' ','')
ENABLE_COLOR_SCALE = #ENABLE_COLOR_SCALE:gsub(' ','') > 0

local ref_t = {'verbose','verbose_num','numeric','numeric_ext','num_Roman','num_Roman_uni',
'num_pict','num_pict2','alphabet','alphabet_ext','pict'} -- to redirect user choices to SCALES nested tables

local lock_sett_t = Get_Lock_Settings()

local err = not r.GetMediaItem(0,0) and 'no items in the project'
or not ENABLE_COLOR_SCALE and (#SCALE_TYPE == 0 and 'scale type isn\'t selected' -- since color can be used as rank scale, only allow non-set scale type if color scale is selected
or not tonumber(SCALE_TYPE) and 'scale type is not a number'
or SCALE_TYPE+0 <= 0 and 'not a valid scale number')
or tonumber(SCALE_TYPE) and not ref_t[SCALE_TYPE+0] and 'non-existing scale number'
or lock_sett_t[1] and lock_sett_t[3] and 'items are locked globally'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


CUSTOM_PICTOGRAM = #CUSTOM_PICTOGRAM:gsub(' ','') > 0 and not CUSTOM_PICTOGRAM:match('[!#|]+') and CUSTOM_PICTOGRAM -- excluding menu special characters
FILL = #FILL:gsub(' ','') > 0 and #SCALE_TYPE == 0 and ENABLE_COLOR_SCALE -- fill is only respected if rank color scale is enabled alone


-- Define scales --

-- colors scale can be used along with other scales
-- all scales are arranged in descening order so that in the menu their ranks are arranged from highest to lowest, from the smallest menu index to the greatest
local SCALES = {}
SCALES.verbose = {'GREAT','GOOD','AVERAGE','MEDIOCRE','BAD'} -- OR POOR instead of BAD, variant {'TOP','HIGH','MEDIUM','LOW','BOTTOM'}
-- SCALES.urban = {'FIRE/LIT','DOPE','AAIGHT','ASS','DOODOO/GARBAGE/TRASH'}
SCALES.verbose_num = {'5. GREAT','4. GOOD','3. AVERAGE','2. MEDIOCRE','1. BAD'}
SCALES.colors = {48896, 16711680, 32767, 255, 0} -- green, blue, orange, red, black; need to be added 0x1000000 to have them applied with the function
SCALES.numeric = {5,4,3,2,1}
SCALES.numeric_ext = {'5+','5','5—','4+','4','4—','3+','3','3—','2+','2','2—','1'}
SCALES.alphabet = {'A','B','C','D','F'}
SCALES.alphabet_ext = {'A+','A','A—','B+','B','B—','C+','C','C—','D+','D','D—','F'}
SCALES.num_Roman = {'V','IV','III','II','I'}
-- https://www.vertex42.com/ExcelTips/unicode-symbols.html
-- https://www.compart.com/en/unicode/U+2160
SCALES.num_Roman_uni = {'Ⅴ','Ⅳ','Ⅲ','Ⅱ','Ⅰ'} -- U+2164-2160
-- https://symbl.cc/en/unicode-table/#enclosed-alphanumerics
-- https://symbl.cc/en/unicode-table/#dingbats
SCALES.num_pict = {'⑤','④','③','②','①'} -- U+2464-2460; https://www.compart.com/en/unicode/U+2460
SCALES.num_pict2 = {'❺','❹','❸','❷','❶'} -- U+277A-2776; https://www.compart.com/en/unicode/U+2776
--SCALES_hexagram = {'☰','☱','☳','☷'} -- U+2630-37
SCALES.pict = {}
	for i=5,1,-1 do
	SCALES.pict[#SCALES.pict+1] = (CUSTOM_PICTOGRAM or '★'):rep(i) -- U+2605; https://www.compart.com/en/unicode/U+2605
	end
SCALES.fill = {'▓▓▓▓▓▓▓▓▓▓▓','██','███████████'} -- U+2593 or U+2588,  either one or the other, to complement colors scale so that the color is more apparent within the take; other fills, thinner, U+25A4-25A9


-- Manage verbose scale if it's active --

local utf8 = '[\0-\127\194-\244][\128-\191]*'

SCALE_TYPE = tonumber(SCALE_TYPE) -- may be nil if only color scale is enabled
local act_scale_t = SCALES[ref_t[SCALE_TYPE]]
CUSTOM_VERBOSE_SCALE = #CUSTOM_VERBOSE_SCALE:gsub('[%s,]','') > 0 and CUSTOM_VERBOSE_SCALE

	if SCALE_TYPE and SCALE_TYPE < 3 then -- if verbose scale

		if CUSTOM_VERBOSE_SCALE then -- add user custom rank descriptions // ONLY IF SCALE_TYPE is 1 or 2
		-- storing in reverse because custom scale is constructed in ascending order while the rank table must list ranks in descending for the sake of easiness of menu concatenation so that the highest is at the top having the smallest index, i.e. start of the table
		local i = #act_scale_t
		 for w in CUSTOM_VERBOSE_SCALE:gmatch('[^,]*') do
				if #w:gsub('%s','') > 0 then
					if i > 0 then -- while i is within the act_scale_t table range
					act_scale_t[i] = w
					else -- when exceeds because custom scale is longer, insert at the table start
					table.insert(act_scale_t,1,w)
					end
				elseif i < 1 then
				-- e.g. such as ",,,,,,,eight" or ",,,,,,seven," while the current SCALE_TYPE scale is less than eight ranks long
				-- this type of customization will produce nils in the table
				Error_Tooltip('\n\n\tcustom scale exceeds \n\n the active one and has gaps \n\n', 1, 1) -- caps, spaced true
				return r.defer(no_undo)
				end
			i=i-1
			end
		end

		for k, rank in ipairs(act_scale_t) do -- space out and trim trailing and leading spaces
		rank = rank:match('%s*(.+)'):gsub(utf8,'%0 '):match('(.-)%s*$') -- utf-8 support, trimming leading and trailing spaces
			if CUSTOM_VERBOSE_SCALE and SCALE_TYPE == 2 then -- add numbers to rank descriptors of custom verbose scale 2
			-- after spacing out to prevent spacing out leading numbers and dots, e.g. 1. 2.
			rank = math.floor(#act_scale_t-k+1)..'.  '..rank -- calculating number in descending order because that's how ranks are ordered in the table, trimming trailing decimal zero, adding 2 spaces after the dot to conform to the spaced out formatting
			end
		act_scale_t[k] = rank
		end
	end


-- Manage color scale and menu --

CUSTOM_COLOR_SCALE = #CUSTOM_COLOR_SCALE:gsub('[%s,]','') > 0 and CUSTOM_COLOR_SCALE
local color_names = {'5. Green','4. Blue','3. Orange','2. Red','1. Black'} -- to list in the menu

	if not act_scale_t then -- color names are only displayed if no scale is enabled in SCALE_TYPE setting, if both SCALE_TYPE and ENABLE_COLOR_SCALE are disabled the script won't reach this stage due to an error message
		for k, name in ipairs(color_names) do -- space out and trim trailing spaces
		name = name:gsub(utf8,'%0 '):sub(1,-2) -- utf-8 support, removing double space after dot (e.g. 1.) and trimming trailing space
		color_names[k] = name:gsub('%d %. ', function(c) return c:match('%d')..'.' end) -- remove space between digit and dot and reduce space following the dot // due to respecting utf8 characters space is lengtened twice instead of once, once as \32 - regular space and the second time as \160 - no-break space, so the dot ends up being followed by 3 spaces one of which needs trimming
		end
	end

	if CUSTOM_COLOR_SCALE then -- add user custom colors
	-- storing in reverse because custom scale is constructed in ascending order while the rank table must list ranks in descending for the sake of easiness of menu concatenation so that the highest is at the top having the smallest index, i.e. start of the table
	local i = #SCALES.colors
		for hex in CUSTOM_COLOR_SCALE:gmatch('[^,]*') do
		local hex, label = hex:match('%x+'), hex:match(':(.+)')
			if hex and Validate_HEX_Color_Setting(hex) then
			hex = HEX_color_2_integer(hex)
				if i > 0 then -- while i is within the SCALES.colors table range
				SCALES.colors[i] = hex
				else -- when exceeds because custom scale is longer, insert at the table start
				table.insert(SCALES.colors,1,hex)
				end
			local idx = i > 0 and color_names[i]:match('%d') or #SCALES.colors -- while within default SCALES.colors range use its rank numbers, once exceeds, take the numbers from SCALES.colors table length as it keeps growing
			color_names[i] = idx..'.'..(label and '  '..label or '') -- in custom scale for custom ranks color name isn't listed, only number, unless they're appended to the hex code after colon
			elseif i < 1 then
			-- e.g. such as ",,,,,,,#f0f0f0" or ",,,,,,#f0f0f0," while the default scale is only 5 ranks long
			-- this type of customization will produce nils in the table
			Error_Tooltip('\n\n  custom color scale exceeds \n\n the default one and has gaps \n\n', 1, 1) -- caps, spaced true
			return r.defer(no_undo)
			end
		i=i-1
		end
	end


CUSTOM_DEFAULT_MARKER_COLOR = #CUSTOM_DEFAULT_MARKER_COLOR > 0 and Validate_HEX_Color_Setting(CUSTOM_DEFAULT_MARKER_COLOR)
CUSTOM_DEFAULT_MARKER_COLOR = CUSTOM_DEFAULT_MARKER_COLOR and HEX_color_2_integer(CUSTOM_DEFAULT_MARKER_COLOR) -- convert to base 10

-- Manage the menu --

::RELOAD::

local mrkrs_t, curs_pos = Get_Mrkrs_Of_Takes_At_Mouse_Or_Edit_Curs()

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named

local opts = r.GetExtState(named_ID, 'OPTIONS')
-- the options are mutually exclusive
local opt1 = get_sett(opts, 1)
local opt2 = get_sett(opts, 2)
local opt3 = get_sett(opts, 3)

local opts_menu = menu_check(opt1)..'Select items with active take ranked as... |'
..menu_check(opt2)..'Select items with any take ranked as... |'..menu_check(opt3)..'Set take ranked as... active||'

local sort_takes = 'Sort takes in items by rank in descending order'
local aver_median = 'Calculate takes average rank'
local sort_menu = '>OTHER OPERATIONS|'..sort_takes..'||'..sort_takes:gsub('descending','ascending')
..'||'..aver_median..'||'..aver_median:gsub('average','median')..'|||<Display script HELP'

-- if an option is enabled or no marker at cursor, gray out up/down-rank menu items
local up, down = table.unpack(opts:match('1') and {'#','#'} or {up_down_rank_grayout(mrkrs_t, act_scale_t, SCALES.colors)})

local color_menu = table.concat(color_names, '||'):upper()
local menu = not SCALE_TYPE and ENABLE_COLOR_SCALE and color_menu or table.concat(act_scale_t,'||')
menu = opts_menu..sort_menu..'|||'..up..'Up-rank||'..down..'Down-rank|||'..menu

-- must be retrieved before calling the menu for setting items selected,
-- take active, and sorting by rank because in these tasks mrkr_t table isn't
-- constructed and so attempt to retrieve it afterwards will likely fail
-- because when the menu is clicked the cursor will move away from the item
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, false) -- 0 allow_locked false

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

local t = {[1]=opt1, [2]=opt2, [3]=opt3} -- table indices must be equal to expected menu output values

	if output == 0 then return r.defer(no_undo)
	elseif output < 4 then -- options indices
	-- toggle, the options are mutually exclusive
	local opts = ('0'):rep(#t) -- initialize all off // wouldn't be necessary if the settings weren't mutually exclusive
		for k, opt in ipairs(t) do
			if output == k then
		local new_val = opt == '1' and '0' or '1' -- toggle
			local i = 0
			opts = opts:gsub('0', function() i=i+1 if i==k then return new_val end end)
			break end
		end
	r.SetExtState(named_ID, 'OPTIONS', opts, false) -- persist false
	goto RELOAD
	end

local rank_new = output == 9 and 0 or output == 10 and -1 or output-10 -- 0 is uprank, -1 is downrank, otherwise offsetting 10 first menu items

local err = output > 8 and not next(mrkrs_t)
	for k, opt in ipairs(t) do
		if opt == '1' then err = nil break end
	end
	if err then
--	OR
--	if opt1 == '0' and opt2 == '0' and opt3 == '0' and not next(mrkrs_t) then
	-- if any option is enabled (value 1) there's no requirement of meeting the prerequisites
	-- for applying rank (cursor position) and having mrkrs_t table populated
	-- because the operation is meant to be different,
	-- so the error is moved here from before the menu initialization
	-- to allow the user to open it if they only wish to use the options, not to set rank;
	-- if all are disabled and the table is empty throw the error
	-- when a rank button is clicked, up/down-rank buttons at this stage are grayed out
	Error_Tooltip('\n\n  no take under mouse \n\n and no selected items '
	..'\n\n under the edit cursor \n\n   or items are locked \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end -- error message is inside the function


r.Undo_BeginBlock()

local undo

	if opt1 == '1' or opt2 == '1' then -- select by rank
	local rank = Select_Items_With_Take_Of_Particular_Rank(item, act_scale_t, SCALES.colors, rank_new, opt1 == '1') -- want_active is opt1 == '1'
		if rank then
		undo = 'Select items with active take ranked '
		undo = ( opt1 == '1' and undo or undo:gsub('active take', 'takes') )..rank
		end
	elseif opt3 == '1' then -- set take active by rank
	local rank = Set_Take_Of_Particular_Rank_Active(item, act_scale_t, SCALES.colors, rank_new)
		if rank then
		undo = 'Set takes ranked '..rank
		end
	elseif output > 3 and output < 8 then -- sorting and calculating average/median
	local typ = output == 6 and 'average' or output == 7 and 'median'
	local sort_dir = (output == 4 or typ) and 'desc' or output == 5 and 'asc' -- when calculating average/median always prefer the marker ranked the highest within take with mutliple rank markers in the active scale
	local t, where = Collect_Take_Data_For_Sorting(item, act_scale_t, SCALES.colors, sort_dir, typ) -- returns take data table, cal arg is typ which makes sure that for average/median rank calculation all relevant takes are counted, unlike for sorting where single take items are ignored
		if t then
			if output < 6 then -- sorting
			Sort_Takes(t, sort_dir)
			undo = 'Sort takes in '..sort_dir..'ending order '..where -- 'ending' is completion of 'desc' and 'asc'
			else
			Calculate_Average_And_Median_Take_Rank(item, t, act_scale_t, color_names, typ, SCALE_TYPE)
			-- undo isn't needed
			end
		end
	elseif output == 8 then
	Display_Script_Help_Txt(scr_name)
	-- undo isn't needed
	else -- rank setting
	undo = Set_Or_Change_Rank(mrkrs_t, SCALES, rank_new, curs_pos, act_scale_t, CUSTOM_DEFAULT_MARKER_COLOR)
	end

	if not undo then -- rank wasn't applied
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	else
	r.Undo_EndBlock(undo,-1)
	end

	if output > 8 and output < 11 then goto RELOAD end -- reload when up/down-ranking incrementally





