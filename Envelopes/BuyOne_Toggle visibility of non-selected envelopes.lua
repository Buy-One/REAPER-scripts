--[[
ReaScript name: BuyOne_Toggle visibility of non-selected envelopes.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI recommended
Provides: [main] .
About: 	The purpose of the script is to reduce clutter when
    		working with multiple envelopes by allowing to only
    		have one envelope visible.
    
    		If track envelope is selected, the script will toggle 
    		visibility of envelopes in parent track of the selected 
    		envelope if such track is selected, otherwise it will 
    		toggle visibility of all track envelopes in the project.
    		
    		If take envelope is selected the script will toggle
    		visibility of other envelopes in the parent take of
    		the selected envelope.		
    	
    		Track envelope and take envelope definition also covers 
    		track and take FX envelopes respectively.
    		
    		The selected envelope and its parent track or the parent
    		track of the take envelope parent take must be visible 
    		for the toggle to work.
    		
    		The toggle state is determined by visibility of any 
    		envelope other than the selected. If any is visible, 
    		within the current scope, envelopes will get hidden, 
    		if none is visible, envelopes will get shown.
    		
    		If the parent track of selected envelope or of selected 
    		envelope parent take is out of sight, it will be scrolled 
    		vertically into view. If such parent track is out sight 
    		at the bottom of the tracklist it will only be scrolled 
    		into view if extensions mentioned in the header above 
    		are installed.  
    		If the parent take of selected take envelope is out of 
    		sight, the Arrange view will scroll to such take parent 
    		item, the item will be selected and the take activated.
			
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following setting insert any alphanumeric character
-- between the quotes.

-- Enable to set track envelopes unarmed when hidden
-- and armed when visible;
-- The setting depends on the preference:
-- Preferences -> Editing behavior -> Automation -> Hidden envelopes: Allow writing automation
-- which allows armed envelopes hidden manually or with actions 
-- to stay armed while hidden,
-- if both, this preference and this setting, are enabled 
-- the setting has no effect and an armed envelope will stay armed
-- after having been hidden
UNARM_WHEN_HIDDEN = ""

-- To disable, if you think it's unnecessary,
-- remove the 1 from within the quotes
ENABLE_UNDO = "1"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
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



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function Is_Env_Visible(env)
	if r.CountEnvelopePoints(env) > 0 then -- validation of fx envelopes in REAPER builds prior to 7.06
	local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	return env_chunk:match('\nVIS 1 ')
	end
end



function Set_Env_In_Visible(env, vis, UNARM_WHEN_HIDDEN) -- can be expanded to armed and active
-- vis is boolean, if true the envelope is set to visible
-- if false env is set to hidden
	if not env then return end
	if r.CountEnvelopePoints(env) > 0 then -- validation of fx envelopes in REAPER builds prior to 7.06
	local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	local state = vis and 0 or 1
		if env_chunk:match('\nVIS '..state) then
		env_chunk = env_chunk:gsub('\nVIS %d', '\nVIS '..(state~1)) -- ~1 bitwise NOT, flip 0 to 1 or 1 to 0	
			if UNARM_WHEN_HIDDEN then
			env_chunk = env_chunk:gsub('\nARM %d', '\nARM '..(state~1)) 
			end
		r.SetEnvelopeStateChunk(env, env_chunk, false) -- isundo false
		end
	end
end



function Toggle_Visibility_Of_Non_Selected_Envs(obj, sel_env, set, vis_exist, UNARM_WHEN_HIDDEN)
-- when set is false works for evaluation of active envelopes and visibility
-- otherwise toggles
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local take = r.ValidatePtr(obj, 'MediaItem_Take*')
local CountEvs, GetEnv = table.unpack(tr and {r.CountTrackEnvelopes, r.GetTrackEnvelope}
or take and {r.CountTakeEnvelopes, r.GetTakeEnvelope})
local env_cnt = CountEvs(obj)

	if tr or take then
	local active_env_exist
		for i=0, env_cnt-1 do
		local env = GetEnv(obj, i)
			if r.CountEnvelopePoints(env) > 0 -- validation of fx envelopes in REAPER builds prior to 7.06
			and env ~= sel_env then
				if not set then
				active_env_exist = 1
				local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
					if env_chunk:match('\nVIS 1 ') then
					return true, true -- visible and active envelopes are true
					end				
				else
					if vis_exist then Set_Env_In_Visible(env, nil, UNARM_WHEN_HIDDEN) -- vis nil - hide
					else
					Set_Env_In_Visible(env, 1, UNARM_WHEN_HIDDEN) -- vis true - show
					end
			--	OR, which is a bit less efficient because it retrieves chunk when it may not be necessary	
			--	Set_Env_In_Visible(env, not vis_exist, UNARM_WHEN_HIDDEN) -- vis true
				end
			end
		end
		if not set then return nil, active_env_exist -- at evaluation stage the loop reaches this line if there're no visible envelopes; nil is visible envelopes, active_env_exist is active envelopes to condition an error message of no active envelopes
		end
	end
end


function Get_Arrange_Height()

local sws, js = r.BR_Win32_FindWindowEx, r.JS_Window_Find

	if sws or js then -- if SWS/js_ReaScriptAPI ext is installed
	-- thanks to Mespotine https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/blob/master/ultraschall_api/misc/misc_docs/Reaper-Windows-ChildIDs.txt
	local main_wnd = r.GetMainHwnd()
	-- trackview wnd height includes bottom scroll bar, which is equal to track 100% max height + 17 px, also changes depending on the header height and presence of the bottom docker
	local arrange_wnd = sws and r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, '', 'trackview', false, true) -- search by window name // OR r.BR_Win32_FindWindowEx(r.BR_Win32_HwndToString(main_wnd), 0, 'REAPERTrackListWindow', '', true, false) -- search by window class name
	or js and r.JS_Window_Find('trackview', true) -- exact true // OR r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000)
	local retval, lt1, top1, rt1, bot1 = table.unpack(sws and {r.BR_Win32_GetWindowRect(arrange_wnd)}
	or js and {r.JS_Window_GetRect(arrange_wnd)})
	local retval, lt2, top2, rt2, bot2 = table.unpack(sws and {r.BR_Win32_GetWindowRect(main_wnd)} or js and {r.JS_Window_GetRect(main_wnd)})
	local top2 = top2 == -4 and 0 or top2 -- top2 can be negative (-4) if window is maximized
	local arrange_h, header_h, wnd_h_offset = bot1-top1-17, top1-top2, top2  -- !!!! MAY NOT WORK ON MAC since there Y axis starts at the bottom
	return arrange_h, header_h, wnd_h_offset -- arrange_h tends to be 1 px smaller than the one obtained via calculations following 'View: Toggle track zoom to maximum height' when extensions aren't installed, using 16 px instead of 17 fixes the discrepancy; header_h is distance between arrange and program window top; wnd_h_offset equals distance between 0 Y ccordinate and program window top edge Y coordinate
	end

end


function re_store_sel_trks(t) -- with deselection; t is the stored tracks table to be fed in at restoration stage
	if not t then
	local sel_trk_cnt = r.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
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
	elseif t then
	r.PreventUIRefresh(1)
	-- deselect all tracks, this ensures that if none was selected originally
	-- none will end up selected because re-selection loop below won't start
	local master = r.GetMasterTrack(0)
	r.SetOnlyTrackSelected(master) -- select one to be restored while deselecting all the rest
	r.SetTrackSelected(master, 0) -- immediately deselect
		for _, tr in ipairs(t) do
		r.SetTrackSelected(tr,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	r.PreventUIRefresh(-1)
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


function Scroll_Track_Into_View(tr, take, parent_tr_y)

-- scroll track vertically into view if hidden
local tr = take and r.GetMediaItemTake_Track(take) or tr
local tr_h = tr and r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
local tr_top = tr and r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
local arrange_h, header_h, wnd_h_offset = Get_Arrange_Height() -- only returns values if extensions are installed

	if tr_h and (parent_tr_y and tr_top ~= parent_tr_y -- track position changed
	or tr_h / 2 + tr_top < 0 -- fully or partially out of sight at the top
	or arrange_h and tr_h / 2 + tr_top > arrange_h) -- fully or partially out of sight at the bottom
	then
	local t = re_store_sel_trks() -- store
	r.SetOnlyTrackSelected(tr) -- select track so that it can be affected by the action
	ACT(40913) -- Track: Vertical scroll selected tracks into view (Master isn't supported, scrolled with Scroll_Track_To_Top() ) // seems to clear take envelope selection, will be restored in the main routine
	re_store_sel_trks(t) -- restore
	end

end


-- using Envelope manager or envelope window
-- track envelopes can remain selected even when hidden 
-- selection of track fx envelopes is cleared once they become hidden
-- both take and take fx envelopes can remain selected when hidden
-- however take fx envelope selection is cleared when take envelopes state changes: 
-- from hidden to visible but not vice versa, from active to inactive AND vice versa
local sel_env = r.GetSelectedEnvelope(0)
		
		if not sel_env then
		Error_Tooltip('\n\n no selected envelope \n\n', 1,1) -- caps, spaced true
		return r.defer(no_undo) end

local sel_env_tr = r.GetSelectedTrackEnvelope(0)
local take, fx_idx, parm_idx = table.unpack(sel_env and {r.Envelope_GetParentTake(sel_env)} or {})
local tr, fx_idx, parm_idx = table.unpack(sel_env and {r.Envelope_GetParentTrack(sel_env)} or {})

		if not Is_Env_Visible(sel_env) then
		Error_Tooltip('\n\n no visible selected envelope \n\n', 1,1) -- caps, spaced true
		return r.defer(no_undo) end


-- Preferences -> Editing behavior -> Automation -> Hidden envelopes: Allow writing automation
-- the preference is relevant for envelopes hidden manually or with action
-- Automatically add envelopes &1
-- Display read automation feedback &2 inverese: true when disabled, false when enabled
-- Allow writing automation &4			
local retval, val = r.get_config_var_string('env_autoadd') -- deleted from reaper.ini when 'Allow writing automation' is unchecked but the value is returned nontheless
UNARM_WHEN_HIDDEN = #UNARM_WHEN_HIDDEN:gsub(' ','') > 0 and (val+0)&4 ~= 4 -- condition the user setting by the preference, if the latter is enabled, the former has no effect
ENABLE_UNDO = #ENABLE_UNDO:gsub(' ','') > 0


r.PreventUIRefresh(1)

local undo
local no_envs_mess = '\n\n no other active envelopes \n\n'

	if sel_env_tr then
		
	local parent_tr_sel = r.IsTrackSelected(tr)
	
	local tr_cnt = parent_tr_sel and 0 or r.CountTracks(0)-1
	
	local vis_env_exist, active, active_env_exist
		for i=0, tr_cnt do -- evaluate visibilty to determine toggle direction or show all
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- accounting for tracks hidden in TCP
			local tr = parent_tr_sel and tr or r.GetTrack(0,i) or r.GetMasterTrack(0)
			vis_env_exist, active = Toggle_Visibility_Of_Non_Selected_Envs(tr, sel_env) -- set, vis_env_exist are nil, omitted
			active_env_exist = active or active_env_exist -- in case nil is returned, fall back on the truth returned earlier 
				if vis_env_exist then break end -- if at least one visible envelope besides the selected one
			end
		end
		
	local err = parent_tr_sel and r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 0 
	and '\n\n the current track is hidden \n\n'
	or not active_env_exist and (parent_tr_sel and no_envs_mess..'\tin current track \n\n' 
	or no_envs_mess..'\tin visible tracks \n\n ')
		
		if err then
		Error_Tooltip(err, 1,1) -- caps, spaced true
		return r.defer(no_undo) end

		if ENABLE_UNDO then -- after the error message above to prevent unnecessary start of undo block
		r.Undo_BeginBlock()
		end
		
	local parent_tr_y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY') -- store to trigger scroll inside Scroll_Track_Into_View() when the value changes due to opening/closing of envelopes in earlier tracks
	
		for i=0, tr_cnt do
		local tr = parent_tr_sel and tr or r.GetTrack(0,i) or r.GetMasterTrack(0)
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then -- accounting for tracks hidden in TCP
			Toggle_Visibility_Of_Non_Selected_Envs(tr, sel_env, true, vis_env_exist, UNARM_WHEN_HIDDEN) -- set is true; toggle direction is based on vis_env_exist value
			end
		end
	
	r.PreventUIRefresh(-1) -- opened at the very start of the routine to cover take envelopes as well
	
	undo = 'Toggle non-selected envelopes in '
	undo = parent_tr_sel and undo..'current track' or undo..'all tracks'
	undo = undo..' '..(vis_env_exist and 'hidden' or 'visible')		

	r.PreventUIRefresh(1) -- closed at the very end of the routine to cover take envelopes as well
	
		if tr == r.GetMasterTrack(0) then
		Scroll_Track_To_Top(tr)
		else		
		Scroll_Track_Into_View(tr, nil, parent_tr_y) -- take nil
		end
	
	-- scrolling with action 'Track: Vertical scroll selected tracks into view' 
	-- used inside Scroll_Track_Into_View() clears track envelope selection, restore
	r.SetCursorContext(2, sel_env) -- re-select envelope in case scrolled or it's an FX env whose selection is cleared after hiding	
		
	elseif sel_env then -- take

	local vis_env_exist, active_env_exist = Toggle_Visibility_Of_Non_Selected_Envs(take, sel_env) -- set, vis_env_exist are nil, omitted
	
	local parent_tr = r.GetMediaItemTake_Track(take)
	local err = r.GetMediaTrackInfo_Value(parent_tr, 'B_SHOWINTCP') == 0 
	and '\n\n\t the track \n\n of the current take \n\n\t is hidden \n\n '
	or not active_env_exist and no_envs_mess..'\t  in current take \n\n'
		
		if err then
		Error_Tooltip(err, 1,1) -- caps, spaced true
		return r.defer(no_undo) end
		
		if ENABLE_UNDO then -- after the error message above to prevent unnecessary start of undo block	
		r.Undo_BeginBlock()
		end

	local item = r.GetMediaItemTake_Item(take)
	local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')	
	local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0) -- isSet false, screen_x_start, screen_x_end, start_time, end_time are 0
	
		if start_time > pos or end_time < pos then -- item is out of sight
		-- scroll to the item with selected take envelope
		local cur_pos = r.GetCursorPosition()
		r.SetEditCurPos(pos, true, false) -- moveview true, seekplay false
		r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore curs pos
		-- select item and activate the take
		r.SetMediaItemSelected(item, true) -- selected true
		r.SetActiveTake(take)
		end
	
	Scroll_Track_Into_View(tr, take) -- parent_tr_y nil
	-- select item and activate the take
	r.SetMediaItemSelected(item, true) -- selected true
	r.SetActiveTake(take)
	
	Toggle_Visibility_Of_Non_Selected_Envs(take, sel_env, true, vis_env_exist, UNARM_WHEN_HIDDEN) -- set, vis_env_exist are true; toggle direction is based on vis_env_exist value which is sel_env in this case
	
	r.SetCursorContext(2, sel_env) -- re-select envelope because the action 'Track: Vertical scroll selected tracks into view' used inside Scroll_Track_Into_View() seems to clear take envelope selection
	
	undo = 'Toggle non-selected envelopes in take '..(vis_env_exist and 'hidden' or 'visible')
	
	end	

r.PreventUIRefresh(-1)

	if ENABLE_UNDO then
	r.Undo_EndBlock(undo, -1)
	else
	return r.defer(no_undo) end 







