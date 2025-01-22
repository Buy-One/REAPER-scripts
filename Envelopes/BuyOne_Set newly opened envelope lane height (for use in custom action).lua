--[[
ReaScript name: BuyOne_Set newly opened envelope lane height (for use in custom action).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
RREAPER: at least v5.962, 7.19 and later is recommended
About: 	The script sets newly opened envelope lane height
			to the user value definded in the USER SETTINGS,
			so that the user have enough space for drawing
			envelope curve as soon as the envelope shows up.
			It can be either envelope that's just been created
			or one that's been unhidden.  

			The script is only functional within a custom action
			alongside one of the following stock REAPER and 
			SWS extension actions:
			Take: Toggle take mute envelope
			Take: Toggle take pan envelope
			Take: Toggle take pitch envelope
			Take: Toggle take volume envelope
			Toggle show master tempo envelope
			Track: Toggle track mute envelope active
			Track: Toggle track mute envelope visible
			Track: Toggle track pan envelope active
			Track: Toggle track pan envelope visible
			Track: Toggle track pre-FX pan envelope active
			Track: Toggle track pre-FX pan envelope visible
			Track: Toggle track pre-FX volume envelope active
			Track: Toggle track pre-FX volume envelope visible
			Track: Toggle track trim envelope visible
			Track: Toggle track volume envelope active
			Track: Toggle track volume envelope visible
			FX: Activate/bypass track/take envelope for last touched FX parameter
			FX: Show/hide track/take envelope for last touched FX parameter
			SWS/BR: Show mute send envelopes for selected tracks
			SWS/BR: Show pan send envelopes for selected tracks
			SWS/BR: Show volume send envelopes for selected tracks
			SWS/BR: Show/hide pan track envelope for last adjusted send			
			SWS/BR: Show/hide track envelope for last adjusted send (volume/pan only)
			SWS/BR: Show/hide volume track envelope for last adjusted send
			SWS/BR: Toggle show active mute send envelopes for selected tracks
			SWS/BR: Toggle show active pan send envelopes for selected tracks
			SWS/BR: Toggle show active volume send envelopes for selected tracks
			SWS/BR: Toggle show mute send envelopes for selected tracks
			SWS/BR: Toggle show pan send envelopes for selected tracks
			SWS/BR: Toggle show volume send envelopes for selected tracks
			SWS/S&M: Show and unbypass take mute envelope
			SWS/S&M: Show and unbypass take pan envelope
			SWS/S&M: Show and unbypass take pitch envelope
			SWS/S&M: Show and unbypass take volume envelope
			SWS/S&M: Show take mute envelope
			SWS/S&M: Show take pan envelope
			SWS/S&M: Show take pitch envelope
			SWS/S&M: Show take volume envelope
			SWS/S&M: Toggle show take mute envelope
			SWS/S&M: Toggle show take pan envelope
			SWS/S&M: Toggle show take pitch envelope
			SWS/S&M: Toggle show take volume envelope
						
			
			THE CUSTOM ACTION SEQUENCE MUST LOOK AS FOLLOWS:
			
			BuyOne_Set newly opened envelope lane height (for use in custom action).lua
			--- REAPER/SWS Extension ACTION ---  
			BuyOne_Set newly opened envelope lane height (for use in custom action).lua

			The script can be combined within a custom action
			with BuyOne_Select newly opened envelope (for use in custom action).lua
			so that the envelope lane height is set and the
			envelope is selected simultaneously, e.g.
			
			BuyOne_Set newly opened envelope lane height (for use in custom action).lua
			BuyOne_Select newly opened envelope (for use in custom action).lua
			--- REAPER/SWS Extension ACTION ---  
			BuyOne_Set newly opened envelope lane height (for use in custom action).lua
			BuyOne_Select newly opened envelope (for use in custom action).lua


]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- Between the quotation marks insert the value
-- in pixels of the desired envelope lane height
-- when an envelope is opened;
-- in the context of take envelopes and track envelopes
-- dsplayed in media lane the height value is how much
-- of the item and TCP height respectively is allocated
-- to a single envelope had the envelopes been distributed
-- evenly which in practice is not necessarily the case because
-- the envelope vertical position depends on its current value,
-- so the result is simply setting of the item or the TCP
-- height respectively to the desired value multiplied by
-- the number of currently visible envelopes;
-- if the setting is zero or invalid it will default to 200, 100
-- and 100 px for track envelope in separate lane, media lane
-- and for take envelope respectively;
-- CAVEATS:
-- in mode 'Overlapping items displayed in lanes'
-- the resulting envelope lane height will be larger
-- or smaller by several pixels than the set value


-- for track envelopes displayed on separate lanes
TRACK_SEPARATE_LANE = ""

-- for track envelopes displayed in media lanes
TRACK_MEDIA_LANE = ""


TAKE_ENVELOPE = ""

---------------------------------------------------------

-- To enable the following settings insert any alphanumeric
-- character between the quotation marks

-- Enable to have envelope lane height set to the desired
-- value not only when it's smaller but when it's bigger
-- as well at the moment of envelope becoming visible;
-- ONLY APPLIES TO TAKE ENVELOPES AND TRACK ENVELOPES
-- DISPLAYED IN THE MEDIA LANE;
-- could be useful after deleting certain envelopes
-- which leaves extra space and takes up screen real estate;
-- the setting is overridden by SET_ALWAYS and
-- RESTORE_TRACK_DEFAULT_HEIGHT settings below
SET_WHEN_BIGGER = ""


-- Enable to have envelope lane height adjust always, both
-- when the envelope is made visible and when it gets hidden,
-- which means that the height of the TCP and item will depend
-- on the number of currently visible track envelopes displayed
-- in the media lane and in a take respectively, i.e. when
-- an envelope is made visible the height increases by the value
-- defined in the settings above and when it gets hidden the
-- height decreases by the same value;
-- ONLY APPLIES TO TAKE ENVELOPES AND TRACK ENVELOPES
-- DISPLAYED IN THE MEDIA LANE;
-- this setting overrides SET_WHEN_BIGGER setting above
-- and is overridden by RESTORE_TRACK_DEFAULT_HEIGHT below
SET_ALWAYS = "1"


-- Enable to make the script restore TCP default theme
-- height when the envelope whose visibility is toggled
-- by an action has been hidden, so that when it's shown
-- the envelope lane height defined in the settings above
-- is applied while when it gets hidden the TCP height is
-- reset to its default regadless of the envelope lane height
-- setting and the number of visible envelopes;
-- the logic is the same as in SET_ALWAYS setting above
-- with the only difference that the TCP height is reset
-- instead of being adjusted according to the number
-- of remaining visible envelopes;
-- ONLY APPLIES TO TAKE ENVELOPES AND TRACK ENVELOPES
-- DISPLAYED IN THE MEDIA LANE;
-- this setting overrides both SET_WHEN_BIGGER and
-- SET_ALWAYS settings above
RESTORE_TRACK_DEFAULT_HEIGHT = ""


-- Enable to prevent script activity in 'Free item
-- positioning', 'Fixed item lanes'
-- and 'Overlapping items displayed in lanes' modes,
-- since increase in TCP height when it's already
-- tall enough in order to accommodate multiple stacked up
-- items may be undesirable because of how much
-- screen space it consumes;
-- ONLY APPLIES TO TAKE ENVELOPES
IGNORE_EXTRA_MODES = ""


-- Enable to have track/item/take scroll into view when
-- envelope lane height increases, and discreases (when
-- SET_ALWAYS/RESTORE_TRACK_DEFAULT_HEIGHT settings
-- are enabled above) which is especially useful
-- in order to compensate for vertical focus shift
-- as a result of increase and reduction in TCP height;
-- APPLIES TO ALL ENVELOPES
SCROLL_INTO_VIEW = "1"


-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------



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


function Error_Tooltip(text, caps, spaced, x2, y2, want_color, want_blink)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- not directly under the mouse the tooltip sticks if mouse is over Arrange
-- but soon disappears if mouse is in the TCP area but not over the TCP
-- and immediately disappears if the mouse is over the TCP
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


function Item_Has_Top_Icon_Bar(item)
-- doesn't support FIP mode
local item_y = r.GetMediaItemInfo_Value(item, 'I_LASTY')
	if item_y == 15 then return true end
local tr = r.GetMediaItemTrack(item)
local item_h = r.GetMediaItemInfo_Value(item, 'I_LASTH')
local mode = r.GetMediaTrackInfo_Value(tr, 'I_FREEMODE')
local FIL = mode == 2 and r.GetMediaTrackInfo_Value(tr, 'C_LANESCOLLAPSED') == 0
	if FIL then -- FIL mode
	local FIL_cnt = r.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES')
	local FIL_idx = r.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
	return item_y - item_h * FIL_idx >= 15 -- OR item_y - item_h * (FIL_cnt-1) >= 15 -- in FIL mode the gap may be bigger hence >= 15
	elseif mode == 0 then -- applies to overlapping items displayed in lanes
		return item_y%item_h ~= 0 -- when there's top icon bar, Y coordinate of an overlapping item in any lane will be divided by item height with remainder that is non-integer quotient
	end
end



function Is_Overlapping_In_Lanes(item, want_count)
-- want_count is boolean to return the actual count of items
-- overlapping the source one and including it;
-- prior to build 6.54 overlapping items lanes could collapse of the track height wasn't sufficient
-- to accommodate them, since that build items are always displayed in lanes as long as the setting
-- at Preferences -> Appearance -> Zoom/Scroll/Offset -> Offset by ... of item height is not 0
-- the Preference path is as of build 7.22, in earlier builds it was different
	if r.GetToggleCommandStateEx(0, 40507) == 1 then -- Options: Offset overlapping media items vertically AKA Show overlapping media items in lanes (when room)
	local GetItem, GetTrack = r.GetMediaItemInfo_Value, r.GetMediaTrackInfo_Value
	local tr = r.GetMediaItemTrack(item)
	-- check if there're items overlapping the current one by comparing item and track height
	-- the difference between item_h and tr_h is greater than the offset measured with item_y
	-- even without the icon bar there's still difference, across all tested themes it's 4 px
		if GetTrack(tr, 'I_FREEMODE') == 0 -- not FIP and not FIL
		and GetTrack(tr, 'I_TCPH')-GetItem(item, 'I_LASTH')-GetItem(item, 'I_LASTY') > 4 -- I_LASTH doesn't include icon top bar if any, so if the difference is greater than 4 px the TCP size is greater than needed to accommodate 1 item which means there's at least 1 overlapping item
		then
			if not want_count then return true end
		local start = GetItem(item, 'D_POSITION')
		local length = GetItem(item, 'D_POSITION')
		local count = 1 -- accounting for the source item
		local item_idx
			for i = 0, r.GetTrackNumMediaItems(tr)-1 do
			local tr_itm = r.GetTrackMediaItem(tr, i)
			local st = GetItem(tr_itm, 'D_POSITION')
			local len = GetItem(tr_itm, 'D_LENGTH')
				if tr_itm ~= item and st < start+length and st+len > start then
				count = count+1
				elseif tr_itm == item then
				item_idx = i
				end
			end
		return count, item_idx -- item index doesn't necessarily indicate the index of its lane if the option 'Arrange in order they were created' isn't enabled at Preferences -> Appearance -> Zoom/Scroll/Offset
		end
	end

end



function Scroll_Item_To_Top(tr, item_Y)
-- tr is item parent track, item_Y is item I_LASTY attribute or calculated item/take top edge or item in a fixed lane top edge

local item_Y = item_Y*-1 -- converting to negative to reliably compare with track Y coordinate in determining the scroll direction, as a result item_Y coordinate will always be smaller than positive track Y coordinate to condition direction +1 (upwards, scrollbar moves down), and will always be greater than negative track Y coordinate to condition scroll direction -1 (downwards, scrollbar moves up)
local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
local dir = tr_y < item_Y and -1 or tr_y > item_Y and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			else break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y <= item_Y or dir < 0 and Y >= item_Y
	end
r.PreventUIRefresh(-1)
end



function Get_Env_Props(env)
local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	if build > 7.06 or r.CountEnvelopePoints(env) > 0 or not env_chunk:match('\nPT %d') then -- validation of fx envelopes in REAPER builds prior to 7.06 // SUCH VALIDATION IS ALWAYS TRUE FOR VALID TRACK FX ENVELOPES AND ALL TAKE ENVELOPES REGARDLESS OF VISIBILITY, FOR VISIBLE BUILT-IN TRACK ENVELOPES REGARDLESS OF PRESENCE OF USER CREATED POINTS AND FOR HIDDEN BUILT-IN TRACK ENVELOPES WHICH HAVE USER CREATED POINTS; FOR HIDDEN TRACK BUILT-IN ENVELOPES WITHOUT USER CREATED POINTS IT'S FALSE THEREFORE THEY MUST BE VALIDATED VIA CHUNK IN WHICH CASE IT LACKS PT (point) ATTRIBUTE
	local retval, is_vis, sep_lane
			if build < 7.19 then
			is_vis, sep_lane = env_chunk:match('\nVIS 1 '), env_chunk:match('\nVIS %d 1') -- the 2nd flag of take env VIS attribute (show in lane) is always 0
			else
			retval, is_vis = r.GetSetEnvelopeInfo_String(env, 'VISIBLE', '', false) -- setNewValue false
			retval, sep_lane = r.GetSetEnvelopeInfo_String(env, 'SHOWLANE', '', false) -- setNewValue false
			is_vis, sep_lane = is_vis == '1', sep_lane == '1'
			end
	return is_vis, sep_lane
	end
end



function Set_Env_Lane_Height(env, defaults_t, sep_lane)
-- sep_lane is boolean

-- if the parent object isn't valid returns 0 otherwise pointer
local track, take = r.GetEnvelopeInfo_Value(env, 'P_TRACK'), r.GetEnvelopeInfo_Value(env, 'P_TAKE')

	if track ~= 0 then
		if sep_lane then -- the newly opened envelope is in separate lane
		local height = r.GetEnvelopeInfo_Value(env, 'I_TCPH')
			if height < defaults_t.track_sep then
			local retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			r.SetEnvelopeStateChunk(env, chunk:gsub('\nLANEHEIGHT %d+', '\nLANEHEIGHT '..defaults_t.track_sep, 1), false) -- isundo false // LANEHEIGHT attribute for track env displayed in media lane still refers to its ECP height
			end
		else -- the newly opened envelope is in media lane
		-- count track envelopes currently displayed in media lane because the TCP height is divided equally between
		-- such envelope lanes, so it will have to be increased if height allocated to the newly opened envelope
		-- is lower than the user default value
		local total_h, media_lane_cnt = 0, 0
			for i = 0, r.CountTrackEnvelopes(track)-1 do
			local env = r.GetTrackEnvelope(track, i)
			local vis, sep_lane = Get_Env_Props(env)
				if vis and not sep_lane then
				media_lane_cnt = media_lane_cnt +1
				total_h = total_h + r.GetEnvelopeInfo_Value(env, 'I_TCPH')
				end
			end
		local tr_h = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
		local default_h = defaults_t.track_media
			if total_h > 0 and total_h/media_lane_cnt < default_h or tr_h < default_h -- if there're other visible envelopes and the height allocated to each including the newly opened one is smaller that the user default or if there're no other visible envelopes and the item height is smaller than the user default
			or (SET_WHEN_BIGGER or SET_ALWAYS) and (total_h > 0 and total_h/media_lane_cnt ~= default_h or tr_h ~= default_h)
			then
			r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', media_lane_cnt*default_h)
			r.TrackList_AdjustWindows(true) -- isMinor true TCP only // update UI
			end
		end

	elseif take ~= 0 then
	-- same logic as with track envelopes displayed in media lane
	local env_cnt = 0
		for i = 0, r.CountTakeEnvelopes(take)-1 do
		local env = r.GetTakeEnvelope(take,i)
			if Get_Env_Props(env) then
			env_cnt = env_cnt+1
			end
		end
	local GetItem, GetTrack = r.GetMediaItemInfo_Value, r.GetMediaTrackInfo_Value
	local item = r.GetMediaItemTake_Item(take) -- or r.GetEnvelopeInfo_Value(env, 'P_ITEM')
	local item_h = GetItem(item, 'I_LASTH') -- doesn't include item top icon bar
	local take_cnt = r.CountTakes(item)
	local take_h = item_h/take_cnt
	local default_h = defaults_t.take_env
		if env_cnt > 0 and take_h/env_cnt < default_h or take_h < default_h
		or (SET_WHEN_BIGGER or SET_ALWAYS) and (env_cnt > 0 and take_h/env_cnt ~= default_h or take_h ~= default_h)
		then
		local tr = r.GetMediaItemTakeInfo_Value(take, 'P_TRACK') -- or r.GetMediaItemInfo_Value(item, 'P_TRACK')
		local tr_h = GetTrack(tr, 'I_TCPH')
		local mode = GetTrack(tr, 'I_FREEMODE')
		local FIL_cnt = GetTrack(tr, 'I_NUMFIXEDLANES')
		local FIL_open = GetTrack(tr, 'C_LANESCOLLAPSED') == 0
		local FIP, FIL = mode == 1, mode == 2 and FIL_open
		local OIL_cnt = Is_Overlapping_In_Lanes(item, 1) -- overlapping in lanes, want_count true // returns count of items displayed in lanes overlapping the selected one including the selected one
		local extra_modes = FIP or FIL or OIL_cnt

			if extra_modes and IGNORE_EXTRA_MODES then return
			elseif FIL_cnt > 0 and GetTrack(tr, 'C_LANESETTINGS')&8 ~= 8 then
			Error_Tooltip('\n\n fixed lanes are set to be "small" \n\n', 1, 1, 0, 50) -- caps, spaced true, x2 - 0 , y2 - 50 -- small lanes prevent suffcient change in TCP height
			end

		local item_h_new = env_cnt*default_h*take_cnt

		-- Since in extra modes items are resized uniformly, no special calculations for takes are required
		tr_h = not extra_modes and item_h_new+(tr_h-item_h) -- OR tr_h+(item_h_new-item_h)
		or FIL and item_h_new+(tr_h/FIL_cnt-item_h) -- OR item_h_new+tr_h/(FIL_cnt-1) (math.floor((tr_h/FIL_cnt)*(item_h_new/item_h)+0.5) works but adds/subtracts extra pixels) // the difference between TCP and item height in non-FIP mode must be added because item may be shorter due to 15 px high icon bar on top of it (if icons/label on top are enabled) and some extra space and increasing bare TCP height doesn't achieve target envelope lane height as a result of which the condition of this block keeps being true, so this ensures that item height is what ultimately gets increased to the target value, more reliable for the end result than item_y coordinate because it doesn't account for differences elsewhere // FIL TCP height doesn't need to account for items in all lanes, setting height for one item automatically translates to items in other lanes
		or FIP and math.floor(tr_h*(item_h_new/item_h)+0.5) -- adds/subtracts pixels
		or OIL_cnt and tr_h+(item_h_new-item_h)*OIL_cnt -- adding the difference between original item height and its required height to TCP height multipled by the number of overlapping items because the change in TCP height is divided between items and without muliplication the amount allocated to the selected item would be reduced by the amount allocated to other items, the height of all items is increased equally because all overlapping items have the same height

			if SCROLL_INTO_VIEW then Scroll_Item_To_Top(tr, 0) end -- precede TCP height change so that the change happens while the track is within view; a work around the glitch which, after reduction of TCP height due to setting envelope invisible, prevents getting updated item hight below for the sake of scroll target coordinate calculation, probably because the track ends up being out of sight above, so item_Y value calculations for the main Scroll_Item_To_Top() instance below are thrown off; the glitch manifests in cases where target take is a high index take or item is a high index item in extra modes and take/item count is big, no stock update function helps

		r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', tr_h)
		r.TrackList_AdjustWindows(true) -- isMinor true TCP only // update UI

		-- scroll track to the top to make as much item visible as possible
			if SCROLL_INTO_VIEW then
			tr_h = GetTrack(tr, 'I_TCPH') -- re-get after change
			local tr_y = GetTrack(tr, 'I_TCPY')
			item_h = GetItem(item, 'I_LASTH') -- re-get after change
			local take_idx = r.GetMediaItemTakeInfo_Value(take, 'IP_TAKENUMBER')
			local FIL_idx = GetItem(item, 'I_FIXEDLANE')
			local free_y = math.floor(GetItem(item, 'F_FREEMODE_Y')*tr_h+0.5) -- or tr_h/(1/free mode y), in px F_FREEMODE_Y attribute is the distance from track Y coordinate to item top edge determined by the presence or absence of top icon bar
			local item_y = GetItem(item, 'I_LASTY') -- distance to the item top icon bar if any from track Y coordinate
			local top_icon_bar = (FIL or FIP or OIL_cnt) and Item_Has_Top_Icon_Bar(item) -- not needed for items displayed in regular mode

			local item_Y = (FIL or OIL_cnt) and (top_icon_bar and item_y-17 or item_y) -- in FIL and OIL_cnt modes subtracting 15 px of top icon bar plus 2 more px to leave the icon bar visible when it's active
			or FIP and (top_icon_bar and free_y-10 or free_y) -- in FIP mode subtraction of 10 px gives better result
			item_Y = take_cnt == 1 and item_Y or item_h/take_cnt*take_idx
			item_Y = item_Y or item_h/take_cnt*take_idx -- WHEN TOP TAKE, THE TRACK IS SCROLLED TO 0 i.e ITS OWN Y COORDINATE
			Scroll_Item_To_Top(tr, item_Y)
			end

		end

	end

end



function Store_Get_Env_Pointers(cmdID, pointer_t, orig_count, defaults_t)

local count = 0

	for tr_idx = -1, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
		local vis, sep_lane = Get_Env_Props(env)
			if vis then
			count = count+1
				if pointer_t and (not pointer_t[tostring(env)] or not next(pointer_t)) then -- envelope has been unhidden, expand // the table will be empty if initially there were no open envelopes
				Set_Env_Lane_Height(env, defaults_t, sep_lane)
				r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
					if SCROLL_INTO_VIEW then Scroll_Item_To_Top(tr, 0) end
				return
				elseif not pointer_t then -- store
				local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
				r.SetExtState(cmdID, 'POINTER_LIST', pointer_list..'\n'..tostring(env), false) -- persist false
				end
			elseif SET_ALWAYS and pointer_t and pointer_t[tostring(env)] and not sep_lane then -- envelope has been hidden, collapse // the envelope is invisible while its pointer is stored in the table, meaning it was initially visible
			Set_Env_Lane_Height(env, defaults_t)
				
				if not sep_lane and RESTORE_TRACK_DEFAULT_HEIGHT then
				r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', 0) -- 0 resets height to theme default
				r.TrackList_AdjustWindows(true) -- isMinor true TCP only // update UI
				end

				if SCROLL_INTO_VIEW then Scroll_Item_To_Top(tr, 0) end

			r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
			return
			end
		end
	end

	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		for i = 0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, i)
			for i = 0, r.CountTakeEnvelopes(take)-1 do
			local env = r.GetTakeEnvelope(take,i)
				if Get_Env_Props(env) then -- only visibility is needed for take envelopes
				count = count+1
					if pointer_t and (not pointer_t[tostring(env)] or not next(pointer_t)) then -- envelope has been unhidden, expand // the table will be empty if initially there were no open envelopes
					Set_Env_Lane_Height(env, defaults_t)
					r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
					return
					elseif not pointer_t then -- store
					local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
					r.SetExtState(cmdID, 'POINTER_LIST', pointer_list..'\n'..tostring(env), false) -- persist false
					end
				elseif SET_ALWAYS and pointer_t and pointer_t[tostring(env)] then -- envelope has been hidden, collapse // the envelope is invisible while its pointer is stored in the table, meaning it was initially visible
				Set_Env_Lane_Height(env, defaults_t)

					if RESTORE_TRACK_DEFAULT_HEIGHT then
					r.SetMediaTrackInfo_Value(r.GetMediaItemTake_Track(take), 'I_HEIGHTOVERRIDE', 0) -- 0 resets height to theme default
					r.TrackList_AdjustWindows(true) -- isMinor true TCP only // update UI
					Scroll_Item_To_Top(r.GetMediaItemTake_Track(take), 0) -- after restoring TCP default height scroll it into view at the top because when it gets shrunk it becomes hidden outside of the Arrange at the top, in this case the target coordinate is not item/take Y cordinate as inside Set_Env_Lane_Height() but TCP's own Y coordinate so that entire TCP is visible in Arrange // this scroll is independent of SCROLL_INTO_VIEW setting respected inside Set_Env_Lane_Height() function because it's used as a corrective measure after TCP default height restoration
					end

				r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
				return
				end
			end
		end
	end

	if not pointer_t then -- store
	local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
	r.SetExtState(cmdID, 'POINTER_LIST', count..pointer_list, false) -- persist false // store envelope count prior to action execution
	elseif pointer_t then -- if the function reached this point while pointer_t is valid, no newly open envelope was found
	r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
		if count == orig_count+0 then -- this prevents the error message when the toggle action is used within the custom action and the envelope has been toggled to off in which case there's also no newly opened envelope but their total count differs
		Error_Tooltip('\n\n   no newly opened envelope \n\n\t\twas found. \n\n\t or the script state \n\n'
		..' is out of sync, in which case \n\n\t   toggle it to OFF. \n\n', 1, 1) -- caps, spaced true
		end
	end

end



function validate_height_sett(sett, default)
return (not sett or sett == 0) and default or math.floor(math.abs(sett)) -- rectifying negative numbers and rounding decimal
end

function validate_sett(sett)
return #sett:gsub(' ','') > 0
end


local track_sep = validate_height_sett(tonumber(TRACK_SEPARATE_LANE), 200)
local track_media = validate_height_sett(tonumber(TRACK_MEDIA_LANE), 100)
local take_env = validate_height_sett(tonumber(TAKE_ENVELOPE), 100)
SET_WHEN_BIGGER = validate_sett(SET_WHEN_BIGGER)
SET_ALWAYS = validate_sett(SET_ALWAYS)
RESTORE_TRACK_DEFAULT_HEIGHT = validate_sett(RESTORE_TRACK_DEFAULT_HEIGHT)
IGNORE_EXTRA_MODES = validate_sett(IGNORE_EXTRA_MODES)
SCROLL_INTO_VIEW = validate_sett(SCROLL_INTO_VIEW)

defaults_t = {track_sep=track_sep, track_media=track_media, take_env=take_env}


local is_new_value, scr_name, sect_ID, cmdID_init, mode, resol, val, contextstr = r.get_action_context()
local cmdID = r.ReverseNamedCommandLookup(cmdID_init)
local togg_state = r.GetToggleCommandStateEx(sect_ID, cmdID_init)

local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')

-- toggle command state is set only as a means to re-sync the script storage/restoration
-- sequence if it has been disrupted due to the script error which prevented it's complete excution
-- it's referenced in the error message inside Store_Get_Env_Pointers()
-- within a custom action it's set to 1 and back to 0 because two instances are executed
-- one before and another one after the stock action


	if #pointer_list == 0 and togg_state <= 0 then -- store
	Store_Get_Env_Pointers(cmdID) -- envelope pointers are collected instead of GUIDs because their uniqueness isn't guaranteed, in copies of tracks/takes they stay the same until the envelope is deleted
	r.SetToggleCommandState(sect_ID, cmdID_init, 1)
	elseif #pointer_list > 0 and togg_state == 1 then -- evaluate after action execution and change envelope lane height
	local pointer_t = {}
		for pointer in pointer_list:gmatch('[^\n]+') do
			if pointer then
			pointer_t[pointer] = '' -- dummy entry
			end
		end
	local orig_count = pointer_list:match('^%d+')
	Store_Get_Env_Pointers(cmdID, pointer_t, orig_count, defaults_t)
	r.SetToggleCommandState(sect_ID, cmdID_init, 0)
	end






