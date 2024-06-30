--[[
ReaScript name: BuyOne_Track visibility menu.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
Provides: [main=main,midi_editor] .
About: 	The script generates menu with the track list allowing toggling 
	individual track visibility by clicking the track entry in the menu 
	and changing visibility of visible selected or hidden tracks in 
	a batch. It's similar to the native Track Manager but is probably
	more convenient to use and offers some options the Track Manager 
	does not.
	
	Hidden tracks are marked in the list with a symbol which can
	be customized using HIDDEN_TRACK_INDICATOR setting in the USER SETTINGS.
	
	The visibility state of the tracks listed in the menu depends
	on their visibility in the current context which can be either Arrange
	when the Mixer window is closed, or Mixer when it's open. Likewise
	changing visibility status of individual track (by clicking its entry
	in the menu) only applies to its status in the current context.
	
	The track menu respects track folder structure and indents children
	tracks inside folders. The amount of indentation and its indicator
	type can be customized in the USER SETTINGS.
	
	The name of a collapsed folder parent track is preceded in the menu with 
	vertical double arrow ↕ and in Arrange context its children tracks aren't 
	listed in the menu regardless of their visibility status.  	
	In the Mixer context the name of a collapsed folder parent track is only 
	preceded with vertical double arrow ↕ indicator when at least one child 
	track is not hidden. If all are hidden the indicator doesn't appear and 
	all hidden children tracks are listed in the menu preceded by the hidden
	track indicator. So basically in the Mixer a folder is only considered 
	collapsed if there're visible children in it. This is due to limitations 
	of ReaScript API which could be overcome but the solution would be 
	unnecessarily taxable on the computer resources for such trivial task.
	
	Change in visibility status of individual track which is a folder parent 
	track can apply to all its descendants (children and grand ... children) 
	and in visibility status of a folder child track - to its relatives 
	(immediate parent track and siblings) provided the options 1 and 2 in
	the OPTIONS: submenu are enabled. The options 1 and 2 affect all 
	track visibility status changes effected with the script.
	
	Items 1 and 2 of the main menu allow hiding all selected tracks either
	in the current context or in both contexts respectively. When the option 
	5 in the OPTIONS: menu is enabled these items work in reverse - instead 
	of hiding the selected tracks they leave selected tracks visible while 
	hiding the rest. However in the Mixer the Master track isn't hidden
	along with other non-selected tracks.
	
	Items 3 and 4 of the main menu allow unhiding tracks in the current 
	context or in both contexts respectively. Item 4 is only available if 
	there're hidden tracks in both Arrange and Mixer contexts, but not 
	necessarily the same tracks. If option 4 in the OPTIONS: submenu is 
	enabled these items only unhide tracks hidden with this script without 
	affecting tracks hidden by other means.
				
	When the option 3 of the OPTIONS: submenu is enabled the track menu 
	starts from the topmost/leftmost track (depending on the current context) 
	regardless of its visibility status while the tracks beyond the topmost/leftmost 
	scroll position are ignored, also regardless of their visibility status. 
	Activation of this option is convenient in projects with large number 
	of tracks because it provides access to hide/show actions for what's 
	immediately within view in the current context which would otherwise 
	neccesitate scrolling the menu down.  
	The option doesn't apply to the Master track which always listed in the 
	menu either visible or hidden.   
	While the option is enabled, hiding the topmost/leftmost track (depending 
	on the current context) hides it from the menu because the next one becomes 
	the topmost/leftmost.  
	When all tracks end up being hidden and there's no topmost/leftmost 
	track, the option ceases to affect the menu and the entire track list 
	re-appears.
				
	When an individual track is unhidden, if it ends up being completely 
	or mainly out of sight in the Arrange context, it's scrolled into view 
	at the top of the track list. This is what the extensions are 
	recommended for. If installed, when the track just unhidden is sufficiently 
	visible at the bottom it won't be scrolled into view at the top. In 
	the Mixer context the unhidden track is scrolled to the lefmost position.
	When tracks are (un)hidden in a batch the script attempts to preserve track 
	scroll position.  
	When the Master track is unhidden in Arrange context the entire tracklist 
	is scrolled up, in the Mixer context no scrolling to the Master track 
	is needed as it's not affected by the scroll position there.
				
	If option 4 of the OPTIONS: menu is enabled the menu only lists tracks
	hidden with the script in the current context. The option doesn't apply 
	to the Master track, its hidden status is indicated regardless of the
	way it was hidden.
	
	All visibility status changes create an undo point.
	
	Option 6 of the OPTIONS: submenu if enabled makes the menu reload 
	after each action run. Toggling any of the options always makes the 
	menu reload.
	
	The digits preceding the menu items re designed be used as a quick 
	access shortcuts to run menu actions from keyboard.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the character to represent indentation
-- of folder child tracks:
-- empty space, dot . , underscore _ , hyphen - , horiz line ─ ,
-- double oblique hyphen ⸗ , colons :, ꞉, ⁞,
-- equal sign/double horizontal line = or ꞊ or ═ ,
-- almost equal ≈ , identical to ≡ , ellipsis … , double dot ‥ ,
-- light vertical │ , double vertical line ‖ , broken bar ¦ ,
-- asterisk *, tilde ~, Greek ῀, multiply × , primes ′ , ″ , ‴ ,
-- single quote ' , double angle quote », slash ⁄ or / , sharp ♯ ,
-- right arrowhead ˃ (U+02C3), Greek capical Xi Ξ ,
-- any of ░ ▒ ▓ ;
-- if the setting is empty or any of the menu special characters are used,
-- i.e. ! # & | > <
-- the setting defaults to 3 dots
INDENT_TYPE = ""

-- Between the quotes insert integer (whole number) as a multiplier
-- of the indent character selected in the INDENT_TYPE setting above;
-- indent character multiplied by this setting will represent
-- one level inside a track folder;
-- the lower the level, the longer the indent indicator will be, e.g.
-- for the 1st level under the top level its length will match these
-- settings exactly, for the 2nd level the number of the indent indicator
-- repeats will be doubled and so on, meaning that if INDENT_TYPE
-- is 3 dots and this INDENT_LENGTH setting is 3, the first level under
-- the top will be indicated by 9 dots, the 2nd level by 18 dots etc.;
-- if this setting is not an integer only its whole integral part
-- will be respected, if it's negative it will be rectified and if
-- it's not a number it'll default to 3
INDENT_LENGTH = ""

-- Options: •, ◦, ▪, ▫, °, Ⱶ, ⱶ, ›, ˣ, ►, ◊, ♦
-- if the setting is empty defaults to ›
HIDDEN_TRACK_INDICATOR = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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
-- by the absence if the gfx window herefore only disable it in builds
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



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end



function Is_Collapsed_MCP_Folder(tr)
-- tr is a parent track pointer
-- can only reliably identify a collapsed MCP folder if at least one child track is not explicitly hidden, for 100% reliability 'BUSCOMP' values from the chunk must be used

local decs_t = Get_All_Descendants(tr)
local depth = r.GetTrackDepth(tr)

	if #decs_t > 0 then
		for k, tr in ipairs(decs_t) do
			if r.GetTrackDepth(tr) - depth == 1 -- since Get_All_Descendants() returns ALL descendants, here only evaluating direct descendants, i.e. children (exactly 1 depth level below the parent), ignoring grandchildren because these have their own parent which may be collapsed
			and r.IsTrackVisible(tr, true) -- mixer true // visible
			and r.CSurf_TrackToID(tr, true) == -1 -- mixer true // doesn't return index if hidden explicitly or simply being located inside a collapsed folder, hence is preceded IsTrackVisible() to exclude truly hidden tracks
			then -- is a child of a collapsed MCP folder
			return true
			end
		end
	end

end



function Get_Track_Tree_With_Indicators(idx, tr_t, depth, menu_t, scr_name)

local idx = idx or 0
local tr_t = tr_t or {}
--local menu = menu or ''
local menu_t = menu_t or {}
local tr_cnt = r.CountTracks(0)
local depth_last = depth or 0
local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible // when Mixer is open only lists hidden in the Mixer, otherwise hidden in Arrange

	local function space(num)
	return (' '):rep(num)
	end

	for i = idx, tr_cnt-1 do
		if not tr_t[i+1] then -- ensures that a track isn't stored twice if it was already stored in the folder recursive loop, because the main loop continues from the same track it was exited at into the recursive one // i+1 because table is indexed from 1
		local tr = r.GetTrack(0,i)
		local tr_name = r.GetTrackState(tr)
		tr_name = #tr_name:gsub(' ','') == 0 and 'Track #'..(i+1) or tr_name -- display track number if name is empty
		local tr_depth = r.GetTrackDepth(tr)
			if tr_depth < depth_last and tr_depth > 0 then -- ensures exit in the folder recursive loop once current folder level is exited, while being false in the main loop to be able to store top level tracks whose depth is 0
			break
			else
			tr_t[#tr_t+1] = tr
			local is_parent = r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1
			local collapsed = mixer_vis and Is_Collapsed_MCP_Folder(tr, scr_name)
			or r.GetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT') == 2
			local vis = not r.IsTrackVisible(tr, mixer_vis) and tr_depth == 0 and collapsed and HIDDEN_TRACK_INDICATOR..' ↕'..space(1)
			or not r.IsTrackVisible(tr, mixer_vis) and HIDDEN_TRACK_INDICATOR..space(2) or tr_depth == 0 and collapsed and ' ↕'..space(1) or space(3)

			local pad1 = tr_depth > 0 and space(1) or space(0) -- to add padding between track depth indicator and the track name
			local pad2 = tr_depth > 0 and space(2) or space(0) -- to add more padding between track depth indicator and non-collapsed parent track names to better allign with the marked collapsed ones

			local pad2 = is_parent and (tr_depth > 0 and collapsed and '↕ ' or pad2) or pad2

			menu_t[#menu_t+1] = vis..(INDENT_TYPE):rep(INDENT_LENGTH):rep(tr_depth)..pad1..pad2..tr_name

				if is_parent then -- folder // store uncollapsed and collapsed, the children of the latter will be excluded with Exclude_Collapsed_Folder_Children(), it's difficult to exclude them within this loop due to 'if not tr_t[i+1]' condition at its start which ensures that no child track is stored twice, because if they're not stored inside the recursive loop (excluded) this condition will be false and they will end up being stored within the main loop
				tr_t, menu_t = Get_Track_Tree_With_Indicators(i+1, tr_t, tr_depth, menu_t, scr_name) -- go recursive to scan folders // i+1 to start recursive loop from first child track
					if #tr_t == tr_cnt then break end -- if track list ends with a folder, exit to prevent any higher level loop from continuing
				end
			end
		depth_last = tr_depth -- keep track of last track depth to use as a condition of exiting the recursive loop above
		end
	end

return tr_t, menu_t

end


function Exclude_Tracks_NOT_Hidden_With_The_Script(t1, t2, only_list_and_unhide_script_hidden_tracks, scr_name) -- relies on track extended data

	if only_list_and_unhide_script_hidden_tracks == '1' then
	local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible // when Mixer is open only lists hidden in the Mixer, otherwise hidden in Arrange
	local fin = #t1 -- store table length because it may change during the loop
		for i = fin,1,-1 do
		local tr = t1[i]
		local ext_data = mixer_vis and 'REXIM' or 'EGNARRA' -- Mixer or Arrange
		local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
			if not r.IsTrackVisible(tr, mixer_vis)
			and not data:match(ext_data)
			then
			table.remove(t1,i)
			table.remove(t2,i)
			end
		end
	end

return t1, t2

end


function Exclude_Collapsed_Folder_Children(t1, t2, st)
-- st arg is nil initially, only added for recursive loop

	function exclude(t, st, fin)
		for i = #t, 1, -1 do
			if i <= fin and i >= st then
			table.remove(t,i)
			end
		end
	return t
	end

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible

local Get = r.GetMediaTrackInfo_Value
local st_idx, fin_idx
local depth
local t_len = #t1
local st = st or 1

	for k = st, #t1 do
	local tr = t1[k]
		if not st_idx -- prevents getting st_idx again until the last child of the found folder is found, because the folder may contain collapsed nested folders which will otherwise produce truth as well but are redundant if located inside an already collapsed folder
		and Get(tr, 'I_FOLDERDEPTH') == 1 -- folder parent
		and (mixer_vis and Is_Collapsed_MCP_Folder(tr) or Get(tr, 'I_FOLDERCOMPACT') == 2)
		then -- collapsed folder
		st_idx = k+1 -- +1 because k is parent's index, parent track is retained
		depth = r.GetTrackDepth(tr)
		elseif st_idx then
		local depth2 = r.GetTrackDepth(tr)
		fin_idx = depth2 <= depth and k-1 or depth2 > depth and k == #t1 and k -- -1 because k is index of the 1st track with smaller depth, i.e. above the level of the collapsed folder children; otherwise if the last track happens to be a child track indside a collapsed folder k value should not be offset by 1
		end
		if fin_idx then
		t1 = exclude(t1, st_idx, fin_idx)
		t2 = exclude(t2, st_idx, fin_idx)
			if fin_idx < k then
			-- go recursive with new table lengths and adjusted new start value accounting for table length reduction because after table shortening the current loop will be broken
			return Exclude_Collapsed_Folder_Children(t1, t2, k-(t_len-#t1))
		--[[ -- OR
			t1, t2 = Exclude_Collapsed_Folder_Children(t1, t2, k-(t_len-#t1))
			break
			]]
			end
		end
	end

return t1, t2 -- returned when the loop runs through without entering next recursive loop, so basically these are returned from the innermost recursive loop into the main loop above and then from the main loop outwards

end



function Get_Top_Left_most_Visible_Track(t, want_selected)

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible // when Mixer is open leftmost visible, otherwise topmost
local H_W = mixer_vis and 'I_MCPW' or 'I_TCPH'
local Y_X = mixer_vis and 'I_MCPX' or 'I_TCPY'
local st, fin = t and 1 or 0, t and #t or r.CountTracks(0)-1

	for i = st, fin do
	local tr = t and t[i] or r.GetTrack(0,i)
		if r.IsTrackVisible(tr, mixer_vis) 
		and (not want_selected or want_selected and r.IsTrackSelected(tr))
		then
		local H_W = r.GetMediaTrackInfo_Value(tr, H_W) -- excluding EVP for TCP
		local Y_X = r.GetMediaTrackInfo_Value(tr, Y_X)
			if Y_X >= 0 or Y_X + H_W/2 >= 0 -- OR (Y_X < 0 and Y_X*-1 <= H_W/2) OR (Y_X < 0 and Y_X*2*-1 <= H_W) -- // either entire TCP/MCP is visible or the visible part is greater or equal to the invisible one, *-1 to rectify the negative Y/X value for the sake of accurate comparison when TCP/MCP is partially visible
			then
			return i, tr
			end
		end
	end

end



function Truncate_Track_Arrays(tr_t, menu_t, sync_to_scroll_pos)

local tr_idx = sync_to_scroll_pos and Get_Top_Left_most_Visible_Track(tr_t) -- tr_t containing the list of tracks is fed in case there're collapsed folders because in this case the table will not include their children tracks after being shortened with Exclude_Collapsed_Folder_Children() function and iteration over the complete track list rather than the shortened table will produce index that will not match index of the relevant track inside tr_t table which is going to be truncated below

	if tr_idx then
	tr_t = {table.unpack(tr_t, tr_idx, #tr_t)}
	menu_t = {table.unpack(menu_t, tr_idx, #menu_t)}
	end

return tr_t, menu_t

end



function Get_All_Descendants(...)
-- arg is either parent track idx or parent track pointer

local arg = {...}
local tr_idx, tr
	if #arg > 0 then
		if tonumber(arg[1]) then tr_idx = arg[1]
		elseif r.ValidatePtr(arg[1], 'MediaTrack*') then tr = arg[1]
		else return
		end
	else return
	end

	if not tr then tr = r.CSurf_TrackFromID(tr_idx, false) end -- mcpView false
	if not tr_idx then tr_idx = r.CSurf_TrackToID(tr, false)-1 end -- mcpView false


local depth = r.GetTrackDepth(tr)
local desc_t = {}
	for i = tr_idx+1, r.CountTracks(0)-1 do -- starting from the next track
	local tr = r.GetTrack(0,i)
	local tr_depth = r.GetTrackDepth(tr)
		if tr_depth > depth then
		desc_t[#desc_t+1] = tr
		elseif tr_depth <= depth then break
		end
	end

return desc_t

end


function Get_All_Relatives(arg)
-- parent and siblings, NOT descendants
-- arg is either track idx or track pointer

	if not arg then return end

local tr_idx, tr

	if tonumber(arg) then tr_idx = arg
	elseif r.ValidatePtr(arg, 'MediaTrack*') then tr = arg
	else return
	end

	if not tr then tr = r.CSurf_TrackFromID(tr_idx, false) end -- mcpView false

local relative_t = {}

local parent = r.GetParentTrack(tr)
	if parent then -- source track is a child
	local idx = r.CSurf_TrackToID(parent, false) -- mcpView false // returns 1-based index which will correspond to the 1st child track
	local depth = r.GetTrackDepth(tr)
	relative_t[1] = parent
		for i = idx, r.CountTracks(0)-1 do -- starting from the 1st child track, the source track will be added during the loop
		local tr = r.GetTrack(0,i)
		local tr_depth = r.GetTrackDepth(tr)
			if tr_depth == depth then
			relative_t[#relative_t+1] = tr
			elseif tr_depth < depth then break -- one level above the source track
			end
		end
	end

return relative_t

end



function Update_Track_Ext_Data(tr, scr_name, new_val)
-- new val is the value used in GetSetMediaTrackInfo_String()
-- when setting visibility, either 1 or 0

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible
local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false

local ext_data_new = mixer_vis and (data:match('REXIM') and data or data..' '..'NEDDIH_REXIM')
or data:match('EGNARRA') and data or 'NEDDIH_EGNARRA'..' '..data -- to be used on the next line for hiding and keeping another context data

ext_data_new = new_val == 0 and ext_data_new -- if new_val is 0 i.e. hiding
or mixer_vis and data:gsub('NEDDIH_REXIM','') or data:gsub('NEDDIH_EGNARRA','') -- otherwise, if unhiding clear context specific string from the data

ext_data_new = #ext_data_new:gsub(' ','') == 0 and '' or ext_data_new -- remove lingering space if no context specific string has remained
r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..scr_name, ext_data_new, true) -- setNewValue is always true because of the need to store data when hiding track and then deleted it when showing it by passing empty string as stringNeedBig arg
end



function GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name, output, selected, incl_descendants, incl_relatives, only_list_and_unhide_script_hidden_tracks, both_ctx) -- relies on and manipulates track extended data
-- PARAM arg value depends on the Mixer visibility to either target TCP or MCP
-- Update_Track_Ext_Data is a function, passed to be accessible to the internal local function
-- selected, incl_descendants, incl_relatives, only_list_and_unhide_script_hidden_tracks and both_ctx are booleans
-- both_ctx is to show tracks in both Arrange and Mixer

	local function Show(t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx, incl_descendants)
	local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
	local GetSet_Ext_Data = r.GetSetMediaTrackInfo_String
		for _, tr in ipairs(t) do
			if not r.IsTrackVisible(tr, mixer_vis) then -- Get_All_Descendants() and Get_All_Relatives() don't evaluate visibility status hence needed here
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..scr_name, '', true) -- setNewValue true // clear extended state
			local desc_t = incl_descendants and Get_All_Descendants(tr)
				if both_ctx then -- hide in Arrange and Mixer
				local arrange_state = Get(tr, 'B_SHOWINTCP')
				local mixer_state = Get(tr, 'B_SHOWINMIXER')
				Set(tr, 'B_SHOWINTCP', 1)
				Set(tr, 'B_SHOWINMIXER', 1)
				local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
				data = arrange_state == 0 and arrange_state == mixer_state and ''
				or arrange_state == 0 and data:gsub('NEDDIH_EGNARRA','')
				or mixer_state == 0 and data:gsub('NEDDIH_REXIM','') or ''
				data = #data:gsub(' ','') == 0 and '' or data -- remove lingering space if no context specific string has remained
				GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, data, true) -- setNewValue true
				else -- hide in current context
				Set(tr, PARAM, 1)
				Update_Track_Ext_Data(tr, scr_name, 1) -- new_val is 1, show
				end
				if desc_t and #desc_t > 0 then -- show relative descendants if the main table is relatives table
				Show(desc_t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx)
				end
			end
		end
	end

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible
-- OR
-- mixer_vis = not not PARAM:match('MIXER')
local ctx_vis_cntr, mix_vis_cntr, arrange_vis_cntr = 0, 0, 0 -- counters for current context and for both Arrange and Mixer
local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
local GetSet_Ext_Data = r.GetSetMediaTrackInfo_String
local desc_t, rel_t

		for i = 0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)

			if selected and r.IsTrackSelected(tr) or not selected then -- selected is true when exclusively_show_tracks option is enabled to condition main menu items 1 & 2

			local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
			local hidden_in_arrange, hidden_in_mixer = data:match('EGNARRA'), data:match('REXIM')

				if only_list_and_unhide_script_hidden_tracks and (hidden_in_arrange or hidden_in_mixer) -- either hidden in Arrange or Mixer or in both
				or not only_list_and_unhide_script_hidden_tracks then

					if not output then -- GET, count hidden tracks to condition greying out the main menu Unhide items (3 & 4) if there's none so there's nothing to unhide

					-- in current context
						if Get(tr, PARAM) == 0 and (not only_list_and_unhide_script_hidden_tracks
						or only_list_and_unhide_script_hidden_tracks and (mixer_vis and hidden_in_mixer
						or not mixer_vis and hidden_in_arrange) )
						then
						ctx_vis_cntr = ctx_vis_cntr+1
						end
						-- in Arrange and/or in Mixer
						if (Get(tr, 'B_SHOWINTCP') == 0 or Get(tr, 'B_SHOWINMIXER') == 0)
						and (not only_list_and_unhide_script_hidden_tracks
						or only_list_and_unhide_script_hidden_tracks and (hidden_in_arrange or hidden_in_mixer))
						then
						arrange_vis_cntr = Get(tr, 'B_SHOWINTCP') == 0 and arrange_vis_cntr+1 or arrange_vis_cntr
						mix_vis_cntr = Get(tr, 'B_SHOWINMIXER') == 0 and mix_vis_cntr+1 or mix_vis_cntr
						end

					if ctx_vis_cntr > 0 and arrange_vis_cntr > 0 and mix_vis_cntr > 0 then break end -- exit early because 1 hidden track per menu item 3 or 1 hidden track per context for menu item 4 are enough

					else -- set visible

						if both_ctx then -- in Arrange and Mixer
						local arrange_state = Get(tr, 'B_SHOWINTCP')
						local mixer_state = Get(tr, 'B_SHOWINMIXER')
						Set(tr, 'B_SHOWINTCP', 1)
						Set(tr, 'B_SHOWINMIXER', 1)
						local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
						data = arrange_state == 0 and arrange_state == mixer_state and ''
						or arrange_state == 0 and data:gsub('NEDDIH_EGNARRA','')
						or mixer_state == 0 and data:gsub('NEDDIH_REXIM','') or ''
						data = #data:gsub(' ','') == 0 and '' or data -- remove lingering space if no context specific string has remained
						else -- in current context
						Set(tr, PARAM, 1)
						Update_Track_Ext_Data(tr, scr_name, 1) -- new_val is 1, show
						end

						if selected then
						desc_t = incl_descendants and Get_All_Descendants(tr)
						relative_t = incl_relatives and Get_All_Relatives(tr)
						end

						if desc_t and #desc_t > 0 then -- hide source track descendants
						Show(desc_t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx)
						end
						if relative_t and #relative_t > 0 then -- hide source track relatives and descendants of relatives in relevant cases
						Show(relative_t, PARAM, Update_Track_Ext_Data, scr_name, both_ctx, mixer_vis, incl_descendants)
						end

					end -- output cond end

				end -- only_list_and_unhide_script_hidden_tracks cond end

			end -- selected cond end

		end

return ctx_vis_cntr > 0, arrange_vis_cntr > 0 and mix_vis_cntr > 0 -- relevant for Get routine

end



function Visible_Selected_Tracks_Exist()

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible

	for i = 0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0,i, true) -- wantmaster true
	local master = tr == r.GetMasterTrack(0)
	local master_state = r.GetMasterTrackVisibility()
		if master
		and (not mixer_vis and master_state&1 == 1 -- visible in Arrange
		or mixer_vis and master_state&2 ~= 2) -- or in the Mixer
		or not master and r.IsTrackVisible(tr, mixer_vis) then -- 'not master' cond. is required in case the previous condition is false because IsTrackVisible() always returns true for the Master track and will produce false positive if used alone
		return true
		end
	end

end



function HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, all, incl_descendants, incl_relatives, both_ctx) -- manipulates track extended data
-- PARAM arg value depends on the Mixer visibility to either target TCP or MCP
-- Update_Track_Ext_Data is a function, passed to be accessible to the internal local function
-- all, incl_descendants, incl_relatives and both_ctx are booleans
-- when all is true all tracks get hidden to then only unhide selected, otherwise only selected ones
-- both_ctx is boolean to hide tracks in both Arrange and Mixer

	local function Hide(t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx, incl_descendants)
	local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
	local GetSet_Ext_Data = r.GetSetMediaTrackInfo_String
		for _, tr in ipairs(t) do
			if r.IsTrackVisible(tr, mixer_vis) then -- Get_All_Descendants() and Get_All_Relatives() don't evaluate visibility status hence needed here
			local desc_t = incl_descendants and Get_All_Descendants(tr)
				if both_ctx then -- hide in Arrange and Mixer
				local arrange_state = Get(tr, 'B_SHOWINTCP')
				local mixer_state = Get(tr, 'B_SHOWINMIXER')
				Set(tr, 'B_SHOWINTCP', 0)
				Set(tr, 'B_SHOWINMIXER', 0)
				local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
				data = arrange_state == 1 and arrange_state == mixer_state and 'NEDDIH_EGNARRA NEDDIH_REXIM'
				or arrange_state == 1 and (not data:match('EGNARRA') and 'NEDDIH_EGNARRA '..data or data)
				or mixer_state == 1 and (not data:match('REXIM') and data..' NEDDIH_REXIM' or data)
				GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, data, true) -- setNewValue true
				else -- hide in current context
				Set(tr, PARAM, 0)
				Update_Track_Ext_Data(tr, scr_name, 0) -- new_val is 0 hide
				end
				if desc_t and #desc_t > 0 then -- hide relative descendants if the main table is relatives table
				Hide(desc_t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx)
				end
			end
		end
	end

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible
-- OR
-- local mixer_vis = not not PARAM:match('MIXER')
local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
local GetSet_Ext_Data = r.GetSetMediaTrackInfo_String

local st, fin = table.unpack(all and {-1, r.CountTracks(0)} or {0, r.CountSelectedTracks2(0, true)}) -- wantmaster true

	for i = st, fin-1 do
	local tr = not all and r.GetSelectedTrack2(0,i, true) -- wantmaster true
					or all and (r.GetTrack(0,i) or r.GetMasterTrack(0))
		if tr == r.GetMasterTrack(0) then
		local state = r.GetMasterTrackVisibility()
			if both_ctx then
			-- condition by track visibility because state~bit expression is a toggle
				if state&1 == 1 then -- visible in Arrange
				r.SetMasterTrackVisibility(state~1)
				local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
				data = not data:match('EGNARRA') and 'NEDDIH_EGNARRA '..data or data
				GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, data, true) -- setNewValue true // store extended state for Arrange
				end
			state = r.GetMasterTrackVisibility() -- get new state after processing Master track in Arrange above
				if state&2 ~= 2 then -- visible in the Mixer // in the Mixer Master track isn't hidden when option 5 of the OPTIONS: submenu is enabled because undo doesn't store its state and Ctrl+Z won't restore Master track visibility
				r.SetMasterTrackVisibility(state~2)
				local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false // re-get after hiding in Arrange above
				data = not data:match('REXIM') and data..' NEDDIH_REXIM' or data
				GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, data, true) -- setNewValue true // store extended state for Mixer
				end
			else -- either in Arrange or in Mixer
			local bit = mixer_vis and state&2 ~= 2 and 2 or not mixer_vis and state&1 == 1 and 1 -- condition by track visibility because state~bit expression is a toggle
				if bit == 2 or bit == 1 then -- in the Mixer Master track isn't hidden when option 5 of the OPTIONS: submenu is enabled because undo doesn't store its state and Ctrl+Z won't restore Master track visibility
				r.SetMasterTrackVisibility(state~bit)
				Update_Track_Ext_Data(tr, scr_name, 0) -- new_val is 0 hide
				end
			end
		elseif r.IsTrackVisible(tr, mixer_vis) then -- mixer is mixer_vis // visible in the current context
		local desc_t = incl_descendants and Get_All_Descendants(tr)
		local relative_t = incl_relatives and Get_All_Relatives(tr)
			if both_ctx then -- hide source track in Arrange and Mixer
			local arrange_state = Get(tr, 'B_SHOWINTCP')
			local mixer_state = Get(tr, 'B_SHOWINMIXER')
			Set(tr, 'B_SHOWINTCP', 0)
			Set(tr, 'B_SHOWINMIXER', 0)
			local ret, data = GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, '', false) -- setNewValue false
			data = arrange_state == 1 and arrange_state == mixer_state and 'NEDDIH_EGNARRA NEDDIH_REXIM'
			or arrange_state == 1 and (not data:match('EGNARRA') and 'NEDDIH_EGNARRA '..data or data)
			or mixer_state == 1 and (not data:match('REXIM') and data..' NEDDIH_REXIM' or data)
			GetSet_Ext_Data(tr, 'P_EXT:'..scr_name, data, true) -- setNewValue true
			else -- hide source track in current context
			Set(tr, PARAM, 0)
			Update_Track_Ext_Data(tr, scr_name, 0) -- new_val is 0 hide
			end
			if desc_t and #desc_t > 0 then -- hide source track descendants
			Hide(desc_t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx)
			end
			if relative_t and #relative_t > 0 then -- hide source track relatives and descendants of relatives in relevant cases
			Hide(relative_t, PARAM, Update_Track_Ext_Data, scr_name, mixer_vis, both_ctx, incl_descendants)
			end
		end
	end

end


function Toggle_Master_Track_Visibility(scr_name)

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible

local state = r.GetMasterTrackVisibility()
local bit = mixer_vis and 2 or 1
r.SetMasterTrackVisibility(state~bit) -- toggle

end


function Toggle_Media_Track_Visibility(tr, PARAM, Update_Track_Ext_Data, scr_name, incl_descendants, incl_relatives) -- manipulates track extended data
-- PARAM arg value depends on the Mixer visibility to either target TCP or MCP
-- Update_Track_Ext_Data is a function, passed to be accessible to the internal local function
-- incl_descendants, incl_relatives are booleans

	local function Show_Hide_Track(t, PARAM, Update_Track_Ext_Data, scr_name, new_val, incl_descendants)
		for _, tr in ipairs(t) do
		r.SetMediaTrackInfo_Value(tr, PARAM, new_val) -- show/hide relative track
		Update_Track_Ext_Data(tr, scr_name, new_val)
			if incl_descendants then
			local desc_t = Get_All_Descendants(tr)
			Show_Hide_Track(desc_t, PARAM, Update_Track_Ext_Data, scr_name, new_val) -- show/hide descendants of the relative
			end
		end
	end

local state = r.GetMediaTrackInfo_Value(tr, PARAM)
local new_val = state~1 -- toggle // will be used for descendants and relatives as well regardless of their current state so their visibility stays in sync with that of the source track
r.SetMediaTrackInfo_Value(tr, PARAM, new_val) -- toggle visibility of the source track
Update_Track_Ext_Data(tr, scr_name, new_val)

local desc_t = incl_descendants and Get_All_Descendants(tr)
local relative_t = incl_relatives and Get_All_Relatives(tr)

	if desc_t and #desc_t > 0 then -- show/hide track descendants
	Show_Hide_Track(desc_t, PARAM, Update_Track_Ext_Data, scr_name, new_val) -- incl_descendants nil
	end
	if relative_t and #relative_t > 0 then -- show/hide track relatives and descendants of relatives in relevant cases
	Show_Hide_Track(relative_t, PARAM, Update_Track_Ext_Data, scr_name, new_val, incl_descendants)
	end

return desc_t and #desc_t > 0, relative_t and #relative_t > 0 -- used to condition undo point text

end


function re_store_sel_trks(t)
-- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do -- not >= 0 because sel_trk_cnt is not reduced by 1, i-1 is on the next line
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master, wantmaster true
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- selected 0 or false // unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t --and #t > 0
	then
	r.PreventUIRefresh(1)
--	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	-- deselect all tracks, this ensures that if none was selected originally
	-- none will end up selected because re-selection loop below won't start
	local master = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master) -- select master
	r.SetTrackSelected(master, 0) -- immediately deselect
		for _,v in next, t do
		r.SetTrackSelected(v,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
	end
end


function Get_Arrange_Dims()
-- requires SWS or js_ReaScriptAPI extensions
local sws, js = r.BR_Win32_FindWindowEx, r.JS_Window_Find
-- OR
-- local sws, js = r.APIExists('BR_Win32_FindWindowEx'), r.APIExists('JS_Window_Find')

	if sws or js then -- if SWS/js_ReaScriptAPI ext is installed
	-- thanks to Mespotine https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/blob/master/ultraschall_api/misc/misc_docs/Reaper-Windows-ChildIDs.txt
	local main_wnd = r.GetMainHwnd()
	-- trackview wnd height includes bottom scroll bar, which is equal to track 100% max height + 17 px, also changes depending on the header height and presence of the bottom docker
	local arrange_wnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, '', 'trackview', false, true) -- search by window name // OR r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, 'REAPERTrackListWindow', '', true, false) -- search by window class name
	or js and r.JS_Window_Find('trackview', true) -- exact true // OR r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000) -- 1000 is 'trackview' window ID
	local retval, lt1, top1, rt1, bot1 = table.unpack(sws and {r.BR_Win32_GetWindowRect(arrange_wnd)}
	or js and {r.JS_Window_GetRect(arrange_wnd)})
	local retval, lt2, top2, rt2, bot2 = table.unpack(sws and {r.BR_Win32_GetWindowRect(main_wnd)} or js and {r.JS_Window_GetRect(main_wnd)})
	local top2 = top2 == -4 and 0 or top2 -- top2 can be negative (-4) if window is maximized
	local arrange_h, header_h, wnd_h_offset = bot1-top1-17, top1-top2, top2 -- arrange_h tends to be 1 px smaller than the one obtained via calculations following 'View: Toggle track zoom to maximum height' when extensions aren't installed, using 16 px instead of 17 fixes the discrepancy; header_h is distance between arrange and program window top; wnd_h_offset is a coordinate of the program window top which is equal to its distance from the screen top (Y coordinate 0) when shrunk // !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
	return arrange_h, header_h, wnd_h_offset
	end
end


function Scroll_Track_To_Top(tr)
local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
local dir = tr_y < 0 and -1 or tr_y > 0 and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			else break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y <= 0 or dir < 0 and Y >= 0
	end
r.PreventUIRefresh(-1)
end



function Get_First_Visible_Track(want_scroll_pos, want_arrange, want_selected)
-- if want_scroll_pos is false will return the very first visible
-- even if out of sight

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible

	if not mixer_vis and want_arrange then return -- prevents getting Arrange data twice in the main routine in actions targetting both contexts, because when mixer is closed there's no point in getting the Arrange data with the second instance of the function and want_arrange arg being true, as it would be returned by the first instance of the function
	elseif want_arrange then mixer_vis = false end -- to be able to get Arrange data on demand with want_arrange arg being true when mixer is open
	
local H_W = mixer_vis and 'I_MCPW' or 'I_TCPH'
local Y_X = mixer_vis and 'I_MCPX' or 'I_TCPY'
local Get = r.GetMediaTrackInfo_Value
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local H_W = Get(tr, H_W)
	local Y_X = Get(tr, Y_X)
		if r.IsTrackVisible(tr, mixer_vis) and
		(not want_selected or want_selected and r.IsTrackSelected(tr))
		then
			if not want_scroll_pos or want_scroll_pos
			and (Y_X >= 0 or Y_X + H_W/2 >= 0) then -- either fully visible or mostly visible, i.e. at least half the height/width is visible
			return tr, Y_X end
		end	
	end
end




function Scroll_Visible_Track_Into_View(tr, tr_y_orig, want_middle, want_arrange)
-- want_middle is boolean to scroll to the middle of the tracklist
-- in Arrange, otherwise to the top
-- want_arrange is boolean to force the function target Arrange tracklist if the Mixer is open

	if not tr then return end

local is_Master = tr == r.GetMasterTrack(0)
local Get = r.GetMediaTrackInfo_Value
local mixer_vis = not want_arrange and r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible
local PARAM = mixer_vis and 'B_SHOWINMIXER' or 'B_SHOWINTCP'
local tr_vis = is_Master and r.GetMasterTrackVisibility()&1 == 1 or Get(tr, PARAM) == 1 -- OR 'or r.IsTrackVisible(tr, mixer_vis)'

	if tr_vis then -- only scroll when track is visible that is has been unhidden
		if mixer_vis and not is_Master then -- in the Mixer Master track can't be scrolled to
		r.SetMixerScroll(tr) -- only works if Mixer is visible
		elseif not mixer_vis then -- Arrange context
			if is_Master then
			Scroll_Track_To_Top(tr)
			else
			-- scroll track vertically into view if out of sight
			local tr_h = Get(tr, 'I_TCPH')
			local tr_y = Get(tr, 'I_TCPY')
			local arrange_h, header_h, wnd_h_offset = Get_Arrange_Dims() -- only returns values if extensions are installed
				if tr_h and 
				(tr_y_orig and tr_y ~= tr_y_orig -- track position changed
				or tr_y + tr_h/2 < 0) -- fully or mainly out of sight at the top
				or arrange_h and tr_h/2 + tr_y > arrange_h -- fully or mainly out of sight at the bottom
				or not arrange_h -- extensions aren't installed, will be scrolled even if sufficiently within view at the bottom
				then
					if not want_middle then
					Scroll_Track_To_Top(tr) -- SCROLL TO TOP
					else
					-- SCROLL TO THE MIDDLE OF THE TRACKLIST
					local t = re_store_sel_trks() -- store
					r.SetOnlyTrackSelected(tr) -- select track so that it can be affected by the action
					ACT(40913) -- Track: Vertical scroll selected tracks into view (Master isn't supported, scrolled with (Master isn't supported, scrolled with Scroll_Track_To_Top() )
					re_store_sel_trks(t) -- restore
					end					
				end
			end
		end
	end

end


--------------- VALIDATE USER SETTINGS ---------------

-- prevent using menu special characters as INDENT_TYPE setting, defaulting to 3 dots
	for _, char in ipairs({'!','#','&','|', '>','<'}) do
		if INDENT_TYPE:match(char) or #INDENT_TYPE == 0 then
		INDENT_TYPE = '...' break end
	end

INDENT_LENGTH = tonumber(INDENT_LENGTH)
INDENT_LENGTH = INDENT_LENGTH and math.abs(math.floor(INDENT_LENGTH)) or 3 -- default to 3 if invalid
HIDDEN_TRACK_INDICATOR = #HIDDEN_TRACK_INDICATOR:gsub(' ','') > 0 and HIDDEN_TRACK_INDICATOR or '›' -- default to › if invalid

----------- VALIDATE USER SETTINGS END ---------------


::RELOAD::

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)')

function get_sett(sett, idx)
-- ensures that if setting has never been used yet
-- it will be stored as 0 and not as empty string
local sett = sett:sub(idx,idx)
return #sett > 0 and sett or '0'
end

local sett = r.GetExtState(scr_name, 'SETTINGS')
local incl_descendants = get_sett(sett,1)
local incl_relatives = get_sett(sett,2)
local sync_to_scroll_pos = get_sett(sett,3)
local only_list_and_unhide_script_hidden_tracks = get_sett(sett,4)
local exclusively_show_tracks = get_sett(sett,5)
local reload_menu = get_sett(sett,6)

	function checkmark(sett)
	return sett == '1' and '!' or ''
	end

local tr_t, menu_t = Get_Track_Tree_With_Indicators(idx, tr_t, depth, menu_t, scr_name) -- all args are nils, only relevant inside the function

tr_t, menu_t = Exclude_Tracks_NOT_Hidden_With_The_Script(tr_t, menu_t, only_list_and_unhide_script_hidden_tracks, scr_name)
tr_t, menu_t = Exclude_Collapsed_Folder_Children(tr_t, menu_t)
tr_t, menu_t = Truncate_Track_Arrays(tr_t, menu_t, sync_to_scroll_pos == '1') -- according to the scroll position
local menu = table.concat(menu_t, '|')

local mixer_vis = r.GetToggleCommandState(40078) == 1 -- View: Toggle mixer visible

local master_vis = r.GetMasterTrackVisibility()
master_vis = mixer_vis and master_vis&2 ~= 2 or not mixer_vis and master_vis&1 == 1 -- contrary to the old versions of the API doc &2 == 2 is true when the Master track is hidden in the Mixer

master_vis = master_vis and '  ' or HIDDEN_TRACK_INDICATOR..' '

local PARAM = mixer_vis and 'B_SHOWINMIXER' or 'B_SHOWINTCP' -- when Mixer is open affect visibility in the Mixer, otherwise in Arrange

--------------- CONSTRUCT MENU ---------------

local hide_target_or_rest = exclusively_show_tracks ~= '1' and 'Hide non-hidden selected tracks'
or 'Exclusively show visible selected tracks'
local context = mixer_vis and '(Mixer)' or '(Arrange)'
local selected = Visible_Selected_Tracks_Exist() and '' or '#' -- wantmaster true

local hid_exist, hid_exist_global = GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name)
hid_exist = hid_exist and '' or '#' -- in current context
hid_exist_global = hid_exist_global and '' or '#' -- in both Arrange and Mixer
local any_or_scr_hidden = only_list_and_unhide_script_hidden_tracks ~= '1' and 'Unhide all tracks'
or 'Unhide only script hidden tracks'

menu = '>'..('OPTIONS'):gsub('.', '%0 ')..':|'
..checkmark(incl_descendants)..'&1. (Un)Hiding parent includes all descendants|'
..checkmark(incl_relatives)..'&2. (Un)Hiding child includes parent and siblings|'
..checkmark(sync_to_scroll_pos)..'&3. Sync menu to scroll position in current context|'
..checkmark(only_list_and_unhide_script_hidden_tracks)..'&4. Only list and unhide tracks hidden with this script|'
..'    (affects items 3 and 4 of the main menu)|'
..checkmark(exclusively_show_tracks)..'&5. Exclusively show / keep visible target track(s)|'
..'    (affects items 1 and 2 of the main menu)|'
..checkmark(reload_menu)..'&6. Reload menu after running an action|<|||'
..selected..'&1. '..hide_target_or_rest..' in current context '..context..'|'
..selected..'&2. '..hide_target_or_rest..' in Arrange and Mixer||'
..hid_exist..'&3. '..any_or_scr_hidden..' (bar Master) in current context '..context..'|'
..hid_exist_global..'&4. '..any_or_scr_hidden..' (bar Master) in Arrange and Mixer||'
--..hid_exist..'Show all tracks (bar Master) in current context '..context..'|'
--..hid_exist_global..'Show all tracks (bar Master) in Arrange and Mixer||'
..master_vis..'Master Track|'..menu

------------- CONSTRUCT MENU END --------------


----------------- MAIN ROUTINE ----------------

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo) end

local sett_t = {desc = incl_descendants, rel = incl_relatives, sync = sync_to_scroll_pos,
scr_hidden = only_list_and_unhide_script_hidden_tracks, excl_show = exclusively_show_tracks,
reload = reload_menu}
local ctx = mixer_vis and 'Mixer' or 'Arrange'
local tr, tr_y_orig
local undo

	if output > 8 then r.Undo_BeginBlock() end -- items 1 - 7 contain options which don't need undo

	if output < 9 then -- concatenate settings data accounting for toggle
	sett = (output == 1 and (sett_t.desc == '1' and '0' or '1') or sett_t.desc)
	..(output == 2 and (sett_t.rel == '1' and '0' or '1') or sett_t.rel)
	..(output == 3 and (sett_t.sync == '1' and '0' or '1') or sett_t.sync)
	..((output == 4 or output == 5) and (sett_t.scr_hidden == '1' and '0' or '1') or sett_t.scr_hidden)
	..((output == 6 or output == 7) and (sett_t.excl_show == '1' and '0' or '1') or sett_t.excl_show)
	..(output == 8 and (sett_t.reload == '1' and '0' or '1') or sett_t.reload)
	r.SetExtState(scr_name, 'SETTINGS', sett, true) -- persist true

	elseif output == 9 then -- hide selected / only keep selected visible in current context
		
		if sett_t.excl_show=='1' then -- exclusively_show_tracks is enabled
		
		-- scroll all the way to the top in Arrange, scrolling before hiding tracks produces in Arrange a more reliable result if initially there're selected tracks which are out of sight at the top; in Mixer scrolling in this scenario is immaterial
		local tr = Get_First_Visible_Track() -- want_scroll_pos, want_mixer, want_selected nil
		Scroll_Visible_Track_Into_View(tr, tr_y_orig)
		
		-- hide all
		HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, true, sett_t.desc=='1', sett_t.rel=='1') -- incl_descendants is sett_t.desc, all is true, incl_relatives is sett_t.rel, both_ctx arg is nil
		
		-- only show selected
		GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name, output, true, sett_t.desc == '1', sett_t.rel == '1', sett_t.scr_hidden == '1') -- selected true, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, sett_t.scr_hidden is only_list_and_unhide_script_hidden_tracks, both_ctx arg is nil
		undo = 'Only keep selected tracks visible, hide the rest (context: '..ctx..')'

		else
		
		tr = Get_First_Visible_Track(1) -- want_scroll_pos true, want_mixer, want_selected nil // before hiding because 1st visible track is likely to change as a result
		HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, nil, sett_t.desc=='1', sett_t.rel=='1') -- all is nil, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, both_ctx arg is nil		
		
		undo = 'Hide selected tracks (context: '..ctx..')'
		
		end

	elseif output == 10 then -- hide selected / only keep selected visible in Arrange and Mixer
		
		if sett_t.excl_show=='1' then -- exclusively_show_tracks is enabled
		
		-- scroll all the way to the top in Arrange, scrolling before hiding tracks produces in Arrange a more reliable result if initially there're selected tracks which are out of sight at the top; in Mixer scrolling in this scenario is immaterial
		local tr = Get_First_Visible_Track() -- want_scroll_pos, want_mixer, want_selected nil	
		Scroll_Visible_Track_Into_View(tr, tr_y_orig, nil, 1) -- want_middle nil, want_arrange true, if want_arrange is false and Mixer is visible the function will focus on the Mixer track list which in this case is not necessary
		
		-- hide all
		HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, true, sett_t.desc=='1', sett_t.rel=='1', 1) -- incl_descendants is sett_t.desc, all is true, incl_relatives is sett_t.rel, both_ctx arg is true
		
		-- only show selected
		GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name, output, true, sett_t.desc == '1', sett_t.rel == '1', sett_t.scr_hidden == '1', 1) -- selected true, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, sett_t.scr_hidden is only_list_and_unhide_script_hidden_tracks, both_ctx arg is true
		
		undo = 'Only keep selected tracks visible in Arrange and Mixer'
		
		else
		
		tr = Get_First_Visible_Track(1) -- want_scroll_pos true, want_selected nil // before hiding because 1st visible track is likely to change as a result
		local tr_arrange = Get_First_Visible_Track(1, 1) -- want_scroll_pos nil, want_arrange true, want_selected nil // track in Arrange, Arrange tracklist can be scrolled when Mixer is open but Mixer tracklist cannot if it's closed
		HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, nil, sett_t.desc=='1', sett_t.rel=='1', 1) -- incl_descendants is sett_t.desc, all is false, incl_relatives is sett_t.rel, both_ctx arg is true
			
			if tr_arrange then -- when Mixer is open, track in Arrange is scrolled here, Mixer - at the end of the routine, otherwise track in Arrange will be scrolled at the end of the routine
			r.TrackList_AdjustWindows(true) -- isMinor true, TCP // VERY IMPORTANT AFTER (UN)HIDING, WIHOUT IT TCP DATA WON'T UPDATE AND TRACK SCROLL POSITION WON'T BE RESTORED
			Scroll_Visible_Track_Into_View(tr_arrange, tr_y_orig, nil, tr_arrange) -- want_middle nil, want_arrange is tr_arrange, i.e. true
			end
			
		undo = 'Hide selected tracks in Arrange and Mixer'
		
		end
	
	elseif output == 11 then -- unhide all in current context
	
	tr, tr_y_orig = Get_First_Visible_Track(1) -- want_scroll_pos true, want_selected nil // before showing because 1st visible track is likely to change as a result

	GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name, output, nil, sett_t.desc == '1', sett_t.rel == '1', sett_t.scr_hidden == '1') -- selected nil, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, sett_t.scr_hidden is only_list_and_unhide_script_hidden_tracks, both_ctx arg is nil
	
	undo = 'Unhide all hidden tracks (context: '..ctx..')'
	
	elseif output == 12 then -- unhide all in Arrange and Mixer
	
	tr, tr_y_orig = Get_First_Visible_Track(1) -- want_scroll_pos true, want_selected nil // before hiding because 1st visible track is likely to change as a result
	local tr_arrange, tr_y_orig_arrange = Get_First_Visible_Track(1, 1) -- want_scroll_pos true, want_arrange true, want_selected nil // track in Arrange, Arrange tracklist can be scrolled when Mixer is open but Mixer tracklist cannot if it's closed
	
	GetSetAllTracksVisible(PARAM, Update_Track_Ext_Data, scr_name, output, nil, sett_t.desc == '1', sett_t.rel == '1', sett_t.scr_hidden == '1', 1) -- selected nil, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, sett_t.scr_hidden is only_list_and_unhide_script_hidden_tracks, both_ctx arg is true
	
		if tr_arrange then -- when Mixer is open, track in Arrange is scrolled here, Mixer - at the end of the routine, otherwise track in Arrange will be scrolled at the end of the routine
		r.TrackList_AdjustWindows(true) -- isMinor true, TCP // VERY IMPORTANT AFTER (UN)HIDING, WIHOUT IT TCP DATA WON'T UPDATE AND TRACK SCROLL POSITION WON'T BE RESTORED
		Scroll_Visible_Track_Into_View(tr_arrange, tr_y_orig_arrange, nil, tr_arrange) -- want_middle nil, want_arrange is tr_arrange, i.e. true
		end	
	
	undo = 'Unhide all hidden tracks in Arrange and Mixer'
	
	elseif output == 13 then -- show/hide Master
		
	local master_vis = #master_vis:gsub(' ','') == 0	
	
	tr = master_vis and Get_First_Visible_Track(1) -- want_scroll_pos true
	or r.GetMasterTrack(0) -- before toggling because 1st visible track is likely to change after hiding
	
	Toggle_Master_Track_Visibility(scr_name)
	
	undo = (master_vis and 'Hide' or 'Unhide')..' Master track in '..ctx
	
	else -- show/hide media tracks depending on current context
	
	local idx = output-13 -- output-13 because the track tree is preceded by 13 menu items
	tr = tr_t[idx]
	local idx = math.floor(r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')) -- truncating the trailing decimal zero // using function because if tr_t table was truncated to exclude tracks outside of the scroll position, children tracks of collapsed folders or hidden tracks which were hidden by means other than the script when the relevant options are enabled, the table index won't match the track index in the track list; CSurf_TrackToID() is finicky because in the Mixer it doesn't return index of hidden tracks and child tracks of collapsed folders so its use must be conditioned with track visibility status (i.e. either before hiding or after hiding)
	local track_vis = r.IsTrackVisible(tr, mixer_vis)
	local tr_name = r.GetTrackState(tr)	
	local is_vis = sett_t.excl_show=='1' and 'Exclusively keep visible' or track_vis and 'Hide' or 'Unhide' -- precede the function Toggle_Media_Track_Visibility() because visibility state will change unless exclusively_show_tracks option is enabled
		
		if sett_t.excl_show=='1' then -- exclusively_show_tracks is enabled
		-- scroll all the way to the top in Arrange, scrolling before hiding tracks produces in Arrange a more reliable result; in Mixer scrolling in this scenario is immaterial; the track initialized above will be hidden by the time the routine reaches Scroll_Visible_Track_Into_View() function below so it won't run
		local tr = Get_First_Visible_Track() -- want_scroll_pos, want_mixer, want_selected nil
		Scroll_Visible_Track_Into_View(tr)
		-- hide all
		HideVisibleTracks(PARAM, Update_Track_Ext_Data, scr_name, true, sett_t.desc=='1', sett_t.rel=='1') -- all is true, incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, both_ctx arg is nil
		end
	
	local desc, rel = Toggle_Media_Track_Visibility(tr, PARAM, Update_Track_Ext_Data, scr_name, sett_t.desc == '1', sett_t.rel == '1') -- incl_descendants is sett_t.desc, incl_relatives is sett_t.rel, both_ctx arg is nil

	tr = track_vis and sett_t.excl_show ~= '1' and Get_First_Visible_Track(1) or not track_vis and tr  -- want_scroll_pos true // either track to scroll to after hiding, which will be the 1st visible or after unhiding which will be the target track; when sett_t.excl_show is 1 scrolling to the track is irrevant because in this case the tracklist is scrolled all the way to the top before hiding all above, tr var will end up false and won't trigger Scroll_Visible_Track_Into_View() function at the end of the routine // THIS EXPRESSION ONLY WORKS AFTER Toggle_Media_Track_Visibility() BECAUSE THE TRACKLIST ISN'T UPDATED WITH r.TrackList_AdjustWindows() WHICH ALLOWS Get_First_Visible_Track() FUNCTION TO GET 1ST TRACK VISIBLE BEFORE Toggle_Media_Track_Visibility() IS EXECUTED, OTHERWISE AFTER HIDING TRACKS ABOVE THE TOPMOST VISIBLE THE TOPMOST VISIBLE WILL CHANGE AND RESTORATION OF THE ORIGINAL TOPMOST VIISBLE TRACK WILL BE IMPOSSIBLE, in which case one would have to get this track before executing Toggle_Media_Track_Visibility() and use for it a variable diferrent from 'tr'
	
	desc = desc and 'descendants' or ''
	rel = rel and 'relatives' or ''
	local accomp = ((#desc > 0 or #rel > 0) and ' with ' or '')..desc..(#desc > 0 and #rel > 0 and ' and ' or '')..rel
	
	undo = is_vis..' track '..(#tr_name:gsub(' ','') > 0 and '"'..tr_name..'"' or '#'..idx)..accomp..' in '..ctx --

	end

r.TrackList_AdjustWindows(false) -- isMinor false, both TCP and MCP // VERY IMPORTANT AFTER (UN)HIDING, WIHOUT IT TCP DATA WON'T UPDATE AND TRACK SCROLL POSITION WON'T BE RESTORED
	
	if tr then
	r.PreventUIRefresh(1)
	Scroll_Visible_Track_Into_View(tr, tr_y_orig, want_middle)
	r.PreventUIRefresh(-1)
	end


	if undo then r.Undo_EndBlock(undo, -1) end

	-- ensures that the menu reloads when options are toggled
	-- and when otherwise reload option is enabled
	if output < 9 or reload_menu == '1' then goto RELOAD end

	
	
