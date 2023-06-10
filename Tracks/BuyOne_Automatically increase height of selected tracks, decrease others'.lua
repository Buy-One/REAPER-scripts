--[[
ReaScript name: Automatically increase height of selected tracks, decrease others'
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 2.1
Changelog: v2.1 #Added IGNORE_OTHER_PROJECTS setting
	   v2.0 #Complete code overhaul. Glitches and limitations stemming from previous design have been fixed
Licence: WTFPL
REAPER: at least v5.962
About:	The script works similalrly to the combination of preference  
        'Always show full control panel on armed track' and option 
	'Automatic record-arm when track selected' for any track in that 
	it expands selected track TCP up to the size specified 
	in the USER SETTINGS and contracts all de-selected TCPs down to the size 
	specified in the USER SETTINGS. 

	After launch the script runs in the background.  
	To stop it start it again and interact with the 'ReaScript task control' dialogue.

	If user defined MIN_HEIGHT value is smaller than the theme minimal track height, 
	the latter will be used.

	Children tracks in collapsed folders and tracks whose height is locked 
	are ignored.

	If the script is linked to a toolbar button the latter will be lit while 
	the script is running.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable this setting by inserting any alphanumeric
-- character between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-- Insert values for Max and Min track heights between the quotes;
-- if empty, invalid or 0, default to 100
-- and the theme minimum track height respectively,
-- if fractional, rounded down to the integer
-- and if rounding of MIN_HEIGHT results in 0 or value smaller
-- than the theme minimum track height then the 1st conditon applies;
-- if the MAX_HEIGHT value happens to be smaller than or equal
-- to MIN_HEIGHT the script won't run

MAX_HEIGHT = "100"
MIN_HEIGHT = ""


-- If enabled by inserting any alphanumeric character
-- between the quotes, when parent folder track is selected
-- along with it all its children and grandchildren
-- are expanded provided the folder and its subfolders
-- are uncollapsed
INCLUDE_FOLDER_CHILDREN = ""


-- If enabled by inserting any alphanumeric character 
-- between the quotes, the script will only affect tracks 
-- in a project under which it was originally launched 
-- if several project tabs are open;
-- if original project tab has been closed the script will
-- automatically be re-linked to whatever project whose tab 
-- is currently open;
-- to re-link the script to another project when several
-- projects are open in tabs, open another tab and toggle
-- Master track visibility via the main 'View' menu;
-- if the script is assigned to a readily available toolbar button
-- then it can be re-linked by simply stopping it and re-launching
-- under another tab
IGNORE_OTHER_PROJECTS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end

	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end


function Get_Track_Minimum_Height() -- may be different from 24 px in certain themes
local tr = r.GetTrack(0,0)
local H_orig = r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', 1) -- decrease height
r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275
local H_min = r.GetMediaTrackInfo_Value(tr, 'I_TCPH') -- store
r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', H_orig) -- restore
r.TrackList_AdjustWindows(true)
return H_min
end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function At_Exit_Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function Get_Sel_Tracks()
local GetValue = r.GetMediaTrackInfo_Value
local t, sel_cnt = {}, 0
	for i = 0, r.CountSelectedTracks(0)-1 do
	local tr = r.GetSelectedTrack(0,i)
	t[tr] = {folder=GetValue(tr, 'I_FOLDERDEPTH'), -- folder status
	collapsed=GetValue(tr, 'I_FOLDERCOMPACT'), -- folder collapse state
	locked_h=GetValue(tr, 'B_HEIGHTLOCK')} -- locked track height
	sel_cnt = sel_cnt+1
	end
t.sel_cnt = sel_cnt
return t
end


function Selection_Changed(sel_tr_t)
local GetValue = r.GetMediaTrackInfo_Value
	if r.CountSelectedTracks(0) ~= sel_tr_t.sel_cnt then return true end -- overall selection count changed
	for tr, tr_props in pairs(sel_tr_t) do
		if r.ValidatePtr(tr, 'MediaTrack*') and
		( not r.IsTrackSelected(tr) -- overall sel count didn't change but selection did // validation prevents error when project is closed while the script is running
		or tr_props.folder ~= GetValue(tr, 'I_FOLDERDEPTH') -- folder status
		or tr_props.collapsed ~= GetValue(tr, 'I_FOLDERCOMPACT') -- folder collapse state
		or tr_props.locked_h ~= GetValue(tr, 'B_HEIGHTLOCK') ) -- locked track height
		then
		return true
		end
	end
end


function Manage_Track_Heights(MIN_HEIGHT, MAX_HEIGHT, theme_min_tr_height)

local CUST_MIN_HEIGHT = MIN_HEIGHT > theme_min_tr_height

	local function All_Parent_Folders_Uncollapsed(tr)
	local parent = r.GetParentTrack(tr)
		if parent then
			if r.GetMediaTrackInfo_Value(parent, 'I_FOLDERCOMPACT') > 0
			then return false
			else return All_Parent_Folders_Uncollapsed(parent)
			end
		end
	return true
	end

	local function Expand_Children(tr, MAX_HEIGHT)
		if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 0 -- not folder
		or r.GetMediaTrackInfo_Value(tr, 'I_FOLDERCOMPACT') > 0 -- collapsed folder
		then return end
	local tr_idx = r.CSurf_TrackToID(tr, false)-1 -- mcpView false
	local depth = r.GetTrackDepth(tr)
		for i = tr_idx, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local tr_depth = r.GetTrackDepth(tr)
			if tr_depth > depth and All_Parent_Folders_Uncollapsed(tr) and
			r.GetMediaTrackInfo_Value(tr, 'B_HEIGHTLOCK') == 0 then -- not locked
			r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', MAX_HEIGHT)
			end
		end
	end

local uppermost_tr, Y_init

	for i = 0, r.CountTracks(0)-1 do
	uppermost_tr = r.GetTrack(0,i)
	local H = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPH') -- excl. envelopes as they seem useless
	Y_init = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
		if Y_init >= 0 or Y_init < 0 and Y_init + H > 0 -- store to restore scroll position after setting all tracks to MIN_HEIGHT and expanding selected track(s) to MAX_HEIGHT when MIN_HEIGHT > 24 because this routine changes scroll position if track in the middle in the track list is selected // include tracks partly visible at the top of the tracklist
		then break end
	end

	-- SET ALL TO MINIMUM HEIGHT
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
		if All_Parent_Folders_Uncollapsed(tr) -- not child in a collapsed folder
		and
		r.GetMediaTrackInfo_Value(tr, 'B_HEIGHTLOCK') == 0 then -- not locked
		r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', MIN_HEIGHT or 1)
		end
	end
r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275

	-- SET SELECTED TO MAXIMUM HEIGHT
	if r.CountSelectedTracks(0) > 0 then --- this cond isn't really necessary as selection is checked in the MAIN() function
		for i = 0, r.CountSelectedTracks(0)-1 do
		local tr = r.GetSelectedTrack(0,i)
			if All_Parent_Folders_Uncollapsed(tr) -- not child in a collapsed folder
			and r.GetMediaTrackInfo_Value(tr, 'B_HEIGHTLOCK') == 0 then -- not locked
			r.SetMediaTrackInfo_Value(r.GetSelectedTrack(0,i), 'I_HEIGHTOVERRIDE', MAX_HEIGHT)
			end
			if INCLUDE_FOLDER_CHILDREN then
			Expand_Children(tr, MAX_HEIGHT)
			end
		end
	r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275
	end

local Y = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
	if Y ~= Y_init then
	r.PreventUIRefresh(1)
	local dir = Y > Y_init and 1 or Y < Y_init and -1 -- 1 = 8, -1 = -8 px; 1 down so that tracklist moves up and vice versa
		if dir then
			repeat -- restore sel tracks scroll position // not ideal due to the minimum scroll unit being 8 px which makes the scroll diviation from the target value accrue and gradually nudge the scroll bar
			r.CSurf_OnScroll(0, dir)
			local Y_monit = r.GetMediaTrackInfo_Value(uppermost_tr, 'I_TCPY')
			--	if Y ~= y_monitor then y_monitor = Y
				if Y_monit ~= Y then Y = Y_monit
				else break end -- in case the scroll cannot go any further because after contraction of tracks the tracklist becomes shorter and the track cannot reach the original value, especially it it's close to the bottom, otherwise the loop will become endless and freeze REAPER
			until dir > 0 and Y <= Y_init or dir < 0 and Y >= Y_init
		end
	r.PreventUIRefresh(-1)
	end

end


function Link_To_New_Project()
-- if orig proj tab has been closed
local i = 0
	repeat
	local p = r.EnumProjects(i)
		if p == proj then return end -- original project is still open
	i = i+1
	until not p
return r.EnumProjects(-1) -- original project wasn't found, switch to currently open
end


MAX_HEIGHT = tonumber(MAX_HEIGHT) and math.floor(MAX_HEIGHT+0) > 0 and math.floor(MAX_HEIGHT+0) or 100
MIN_HEIGHT = tonumber(MIN_HEIGHT) and math.floor(MIN_HEIGHT+0) > 0 and math.floor(MIN_HEIGHT+0)
local stored_min_height, last_theme, incl_fold_children = r.GetExtState('EXPAND SELECTED TRACKS', 'DATA'):match('(.-);(.+)')
theme_min_tr_height = r.GetLastColorThemeFile() == last_theme and #stored_min_height > 0 and stored_min_height+0 or Get_Track_Minimum_Height()

	if not stored_min_height or last_theme ~= r.GetLastColorThemeFile()	then r.SetExtState('EXPAND SELECTED TRACKS', 'DATA', theme_min_tr_height..';'..r.GetLastColorThemeFile()..';'..INCLUDE_FOLDER_CHILDREN, false) end -- persist false // update if first run during session or if the theme changed since previous launch

MIN_HEIGHT = (not MIN_HEIGHT or MIN_HEIGHT < theme_min_tr_height) and theme_min_tr_height or math.floor(MIN_HEIGHT+0)

	if MAX_HEIGHT <= MIN_HEIGHT then
	Error_Tooltip('\n\n maximum height is smaller than \n\n    or equal to minimum height \n\n')
	return r.defer(function() do return end end) end

INCLUDE_FOLDER_CHILDREN = #INCLUDE_FOLDER_CHILDREN:gsub(' ','') > 0
IGNORE_OTHER_PROJECTS = #IGNORE_OTHER_PROJECTS:gsub(' ','') > 0

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

proj = r.EnumProjects(-1) -- -1 current, project the script was launched under
local new_tab, master_vis = proj

function MAIN()

--r.PreventUIRefresh(1) -- prevents monitoring track height change when actions are applied since prevents actual height change

-- re-ordering proj tabs doesn't affect linkage
proj = IGNORE_OTHER_PROJECTS and r.EnumProjects(-1) ~= proj and Link_To_New_Project() or proj -- switch to currently open proj if the orig one wasn't found

	if IGNORE_OTHER_PROJECTS then
		if r.EnumProjects(-1) ~= new_tab then -- another project tab, store its current Master track visibility
		master_vis = r.GetMasterTrackVisibility()&1 -- store current Master track visibility under new tab
		new_tab = r.EnumProjects(-1) -- update to make this condition false in subsequent cycles
		elseif master_vis and master_vis ~= r.GetMasterTrackVisibility()&1 then -- re-link to another project if its Master track visibility has been toggled
		proj, master_vis = r.EnumProjects(-1), nil -- update project, reset Master track visibility status
		end
	end

	if IGNORE_OTHER_PROJECTS and r.EnumProjects(-1) == proj or not IGNORE_OTHER_PROJECTS then
	
		if r.CountSelectedTracks(0) > 0  and ( not t or t and Selection_Changed(t) ) then
		t = Get_Sel_Tracks()
		Manage_Track_Heights(MIN_HEIGHT, MAX_HEIGHT, theme_min_tr_height)
		end

		if r.CountTracks(0) ~= tr_cnt_init then t = nil -- prevents error in Selection_Changed(t) after deletion of selected tracks because they cannot be found in the table // validating track pointer inside the function doesn't work because it doesn't condition table update like t being nil does
		tr_cnt_init = r.CountTracks(0)
		end
		
	end

r.defer(MAIN)

end



MAIN()



r.atexit(At_Exit_Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0))

do return r.defer(function() do return end end) end


