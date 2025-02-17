--[[
ReaScript name: BuyOne_Create bus track for selected tracks.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1 #Updated script name to better reflect its funcionality
		Updsated 'About' text.
Licence: WTFPL
About: 	Creates a bus track from track selection.
	Can be used to convert a folder of tracks into a bus track
	or to create a bus track for submix rendering.
	
	RULES
	
	1. If ROUTE_SEND_DESTINATION_TRACKS setting is enabled all 
	send destination tracks along the entire sends chain which
	starts with selected tracks (hereinafter 'send destination tracks')
	are routed to the bus track.  
	2. Selected and send destination tracks 
	(in case ROUTE_SEND_DESTINATION_TRACKS setting is enabled) 
	whose Master/Parent send AKA Master send (depending on 
	REAPER build) is disabled aren't routed to the bus track.  
	3. Selected folder child tracks aren't routed to the bus track 
	if at least one parent track of theirs is also selected and has 
	its Master/Parent send AKA Master send (depending on REAPER build) 
	enabled.  
	4. if ROUTE_SEND_DESTINATION_TRACKS setting is enabled send destination 
	tracks of child tracks in a folder whose parent track is routed 
	to the bus track are also routed to the bus track.
		
	The bus track is created immediately above the first track which
	has been routed to it.
	
	If ROUTE_SEND_DESTINATION_TRACKS setting is enabled and you'd like
	to look up send destination tracks which have been routed to the
	bus track along with the selected tracks, use the script  
	BuyOne_Navigate to track send destination or receive source track via menu.lua
	which will generate a menu where they will be listed under 'Receives:'

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Change the bus track name to the one you prefer,
-- if the setting is empty defaults to BUS TRACK
BUS_TRACK_NAME = "BUS TRACK"


-- Insert any alphanumeric character between the quotes
-- to be able to configure settings listed below via menu
-- before each script run, in which case the settings
-- in the script will be ignored;
-- the settings set via the menu will be stored for the
-- durarion of the REAPER session;
-- if this setting is disabled, the settings listed below
-- will be used instead, which is preferable if the script
-- is supposed to be executed from a custom action
RUN_VIA_MENU = ""

-- Insert any alphanumeric character between the quotes
-- to enable appending number to the bus track name
-- in case several bus tracks are created, which
-- with the default name will look like "BUS TRACK 1",
-- "BUS TRACK 2" etc.
ADD_AND_INCREMENT_NAME_NUMBER = "1"

-- Insert any alphanumeric character between the quotes
-- to enable routing to the bus track send destination tracks
-- along the entire sends chain which starts with selected tracks
ROUTE_SEND_DESTINATION_TRACKS = "1"

-- Between the quotes insert number corresponding
-- to the send mode:
-- 1 - Post-Fader (Post-Pan)
-- 2 - Pre-Fader (Post-FX)
-- 3 - Pre-Fader (Pre-FX)
-- if the setting is empty or invalid defaults to 1 - Post-Fader (Post-Pan)
SEND_MODE = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

local Debug = "1"
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
local text = spaced and text:gsub('.','%0 ') or text
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


function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest instance of a particular character at the start of a menu item
-- can be used as a shortcut provided this character is unique in the menu
-- in this case they don't have to be preceded with ampersand '&'
-- if it's not unique, inputting it from keyboard will select
-- the menu item starting with this character
-- and repeated input will oscilate the selection between menu items
-- which start with it without actually triggering them
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest instance at the start of a menu item
-- some characters still do need ampresand, e.g. < and >;
-- characters which aren't the first in the menu item name
-- must also be explicitly preceded with ampersand

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


function MENU(scr_cmdID, bus_tr_name)

	local function checkmark(item, sett)
	return sett == '1' and '!'..item or item
	end

local send_modes_t = {'Post-Fader (Post-Pan)', 'Pre-Fader (Post-FX)', 'Pre-Fader (Pre-FX)'}

::RELOAD::
local sett = r.GetExtState(scr_cmdID, 'SETTINGS')
sett = #sett > 0 and sett or '001' -- initialize defaults on the first load
local increment_name, route_dest_tr, send_mode = sett:match(('(%d)'):rep(3))
local i = 0 -- counter for gsub below
local idx = increment_name == '1' and Get_Bus_Track_Index(bus_tr_name)
local bus_tr_name = idx and bus_tr_name..' '..idx or bus_tr_name -- must be local so the name is updated in the menu when the increment_name setting is toggled and the menu is reloaded
local menu = '#Bus track name: '..bus_tr_name..'||'..checkmark('Increment number in bus track name', increment_name)
..'|'..checkmark('Route send destination tracks', route_dest_tr)..'|>'..'Send mode: '..send_modes_t[send_mode+0]
..'|'..table.concat(send_modes_t,'|'):gsub('|', function() i=i+1 if i == 2 then return '|<' end end)
..'||'..('CREATE BUS TRACK'):gsub('.','%0 ')

local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 then return
	elseif output < 4 then
	local pos = output == 2 and 1 or 2 -- in the menu increment_name setting is at index 2 but in the ext state it's at index 1, similarly route_dest_tr setting, so offset
	local i = 0 -- reset from gsub above
	sett = sett:gsub('%d', function(c) i=i+1 if i==pos then return math.floor(c+0~1) end end) -- flipping the bit
	elseif output < 7 then -- send modes
	send_mode = math.floor(output-3) -- offset by the preceeding menu items and strip off the trailing decimal 0
	local i = 0 -- reset from gsub above
	sett = sett:gsub('%d', function() i=i+1 if i==3 then return send_mode end end)
	else return true, bus_tr_name, send_mode -- create bus track
	end

	if output < 7 then
	r.SetExtState(scr_cmdID, 'SETTINGS', sett, false) -- persist false
	goto RELOAD end

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


function Get_Bus_Track_Index(bus_tr_name)
local max_idx = 0
	for i=0,r.GetNumTracks()-1 do
	local ret, name = r.GetSetMediaTrackInfo_String(r.GetTrack(0,i),'P_NAME','',false) -- setNewValue false
	local idx = name:match(Esc(bus_tr_name)..' (%d+)') or 0
--	max_cnt = idx > max_idx and idx or max_idx
-- OR
	max_idx = math.max(idx+0, max_idx) -- converting idx var into numeral in the process
	end
return max_idx+1
end


function get_track_parents(parent)
	return function()
	parent = r.GetParentTrack(parent) -- assigning to a global value (or upvalue passed as the argument) is crucial to make it work so that the var is constantly updated during the loop, returning r.GetParentTrack(parent) directly won't work because the var isn't updated, the var won't be accessible outside of the loop
	return parent
	end
end

function Is_Track_Parent_Included(tr, t)
	for parent in get_track_parents(tr) do
		if t[parent] and
		r.GetMediaTrackInfo_Value(parent, 'B_MAINSEND') == 1
		then
		return true end
	end
end


function get_track_children_and_grandchildren(tr)
local st_idx = r.CSurf_TrackToID(tr, false) -- mcpView false // starting loop from the 1st child
local depth = r.GetTrackDepth(tr)
return function()
	local chld_tr = r.GetTrack(0,st_idx)
		if chld_tr and r.GetTrackDepth(chld_tr) > depth then
		st_idx=st_idx+1
		return chld_tr
		end
	end
end


function Collect_Tracks(t, fin)

	local function collect_send_dest_tracks(i, t, tr)
	local snd_cnt = r.GetTrackNumSends(tr, 0) -- category 0 sends
		if snd_cnt > 0 then
			for snd_idx=0, snd_cnt-1 do
			local dest_tr = r.GetTrackSendInfo_Value(tr, 0, snd_idx, 'P_DESTTRACK') -- category 0 send
				if not t[dest_tr] then -- if it's not one of the selected or stored inside the recursive loop
				t[#t+1] = dest_tr
				t[dest_tr] = '' -- dummy value // store to be able to evaluate whether the track has already been stored without having to search for it in the entire table
				end
			end
		t = Collect_Tracks(t,i+1) -- go recursive collecting the entire send tree, fin arg is i+1 to stop where the main loop inside Collect_Tracks() left off for efficiency because the table length may increase and running full table loop is likely to cause endless recursive loop because the same sends will be detected over and over in tracks which have already been processed in higher lever recursive loops
		end
	return t
	end

local fin = fin or 1

	for i=#t,fin,-1 do -- in reverse because of removal of irrelevant tracks
	local tr = t[i]
		if --r.GetTrackDepth(tr) == 0 and -- top level track
		r.GetMediaTrackInfo_Value(tr, 'B_MAINSEND') == 0 -- isn't routed to Master
		or Is_Track_Parent_Included(tr, t) -- a parent of a child track has already been stored and has its Master/parent send enabled so no need to store and route the child track as well
		then
		table.remove(t,i)
		t[tr] = false
		end

		if ROUTE_SEND_DESTINATION_TRACKS then
		-- Get destinaton tracks of the track and its children (if any) sends
			if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and t[tr] then -- current track is a folder or subfolder parent track and hasn't been deleted above so is going to be routed to the bus while its children won't so their send desitnation tracks must be included in the routing
				for child in get_track_children_and_grandchildren(tr) do
				t = collect_send_dest_tracks(i, t, child) -- passing table index of the current track as i argument because the child track is not stored and passing its index would be wrong because it would refer to a completely different track in the table
				end
			end
		t = collect_send_dest_tracks(i, t, tr)
		end

	end

return t

end


local sel_tr = r.CountSelectedTracks(0)
local err = r.GetNumTracks() == 0 and 'no tracks in the project' or sel_tr == 0 and 'no selected tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced  true
	return r.defer(no_undo)
	end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
or scr_name -- if an non-installed script is run via 'ReaScript: Run (last) ReaScript (EEL2 or lua)' actions get_action_context() won't return valid command ID, in which case fall back on the script full path

local bus_tr_name = #BUS_TRACK_NAME:gsub(' ','') > 0 and BUS_TRACK_NAME or 'BUS TRACK'

	if #RUN_VIA_MENU:gsub(' ','') > 0 then
	output, bus_tr_name, SEND_MODE = MENU(named_ID, bus_tr_name)
		if not output then return r.defer(no_undo) end
	elseif #ADD_AND_INCREMENT_NAME_NUMBER:gsub(' ','') > 0 then
	local idx = Get_Bus_Track_Index(bus_tr_name)
	bus_tr_name = bus_tr_name..' '..idx
	end

local sel_tr_t = {}

	for i=0,sel_tr-1 do
	local sel_tr = r.GetSelectedTrack(0,i)
	sel_tr_t[#sel_tr_t+1] = sel_tr
	sel_tr_t[sel_tr] = '' -- dummy value // store to be able to evaluate whether the track has already been stored without having to search for it in the entire table
	end

ROUTE_SEND_DESTINATION_TRACKS = #ROUTE_SEND_DESTINATION_TRACKS:gsub(' ','') > 0

local sel_tr_t = Collect_Tracks(sel_tr_t)

	if #sel_tr_t <= 1 then
		if #sel_tr_t == 0 then
		Error_Tooltip('\n\n no track fit to be routed \n\n\tto the bus track \n\n', 1, 1) -- caps, spaced  true
		return r.defer(no_undo)
		elseif r.MB((' '):rep(11)..'Only a single track\n\nwill be routed to the bus track.','PROMPT',1) == 2 then
		return r.defer(no_undo)
		end
	end


-- Insert bus track above the first track routed to it
local idx = r.CSurf_TrackToID(sel_tr_t[1], false) -- mcpView false
r.InsertTrackAtIndex(idx-1, false) -- wantDefaults false
local bus_tr = r.GetTrack(0,idx-1)
r.GetSetMediaTrackInfo_String(bus_tr, 'P_NAME',bus_tr_name,true) -- setNewValue true

local send_modes_t = {['1'] = 0, ['2'] = 3, ['3'] = 1}
local send_mode = send_modes_t[SEND_MODE] or 0

	for k, tr in ipairs(sel_tr_t) do
	r.CreateTrackSend(tr, bus_tr) -- by default send mode is Post-Fader (Post-Pan), i.e. 0
		if send_mode ~= 0 then
		r.SetTrackSendInfo_Value(bus_tr, -1, r.GetTrackNumSends(bus_tr, -1)-1, 'I_SENDMODE', send_mode) -- category -1 receive
		end
	end

Scroll_Track_To_Top(bus_tr)

r.Undo_OnStateChangeEx('Create a bus track "'..bus_tr_name..'" for selected tracks', 1, -1) -- 1 flag UNDO_STATE_TRACKCFG 1, i.e. track/master vol/pan/routing, routing/hwout envelopes too, -1 default because track FX chain isn't affected



