--[[
ReaScript name: BuyOne_Toggle zoom of visible envelopes in the first selected track to available Arrange height.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main] .
About: 	If all visible track envelopes are displayed in the media lane, 
		the script zooms the TCP to available Arrange height,
		otherwise only zooms envelopes displayed in their own lane.

		For envelopes displayed in their own lanes the toggle direction
		is determined by the current height of the envelopes, i.e.
		if height of at least one envelope is different from the one
		calculated relative to the available Arrange height all envelopes
		are zoomed to the available Arrange height.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- The following settings only apply
-- when all track envelopes are displayed
-- in the track media lane because only in this case
-- TCP own height is being changed

-- Enable by inserting any alphanumeric character
-- to have TCP zoom toggled to last registered TCP height;
-- if disabled, the TCP height will be toggled
-- to the value chosen in the setting
-- MINIMUM_TCP_HEIGHT below
TOGGLE_TO_LAST_TCP_HEIGHT = "1"

-- Key in number of pixels the TCP
-- height must be toggled back to,
-- if empty, invalid or 0 defaults to fully minimized;
-- only applies when TOGGLE_TO_LAST_TCP_HEIGHT
-- setting above is disabled
MINIMUM_TCP_HEIGHT = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local Debug = ""
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



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
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



function Is_Env_Visible(env)
	local function get_hidden_built_in_track_env(env)
	local env_name_t = {
	-- regular track
	Volume='', ['Volume (Pre-FX)']='', ['Trim Volume']='', ['Send Volume']='',
	Pan='', ['Pan (Pre-FX)']='', ['Pan (Left)']='', ['Pan (Right)']='', ['Send Pan']='',
	Width='', ['Width (Pre-FX)']='', Mute='', ['Send Mute']='',
	 -- master track
	Playrate='', --['Tempo map']='' -- excluding tempo map envelope because when inactive and has no points at all it cannot be opened even though the chunk is there
	}
	local ret, env_name = r.GetEnvelopeName(env)
		if env_name_t[env_name] then
		local retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			if not chunk:match('\nPT %d') then return env end
		end
	end
	if r.CountEnvelopePoints(env) > 0 or get_hidden_built_in_track_env(env) then -- validation of fx envelopes in REAPER builds prior to 7.06 // SUCH VALIDATION IS ALWAYS TRUE FOR VALID TRACK FX ENVELOPES AND ALL TAKE ENVELOPES REGARDLESS OF VISIBILITY, FOR VISIBLE BUILT-IN TRACK ENVELOPES REGARDLESS OF PRESENCE OF USER CREATED POINTS AND FOR HIDDEN BUILT-IN TRACK ENVELOPES WHICH HAVE USER CREATED POINTS; FOR TRACK BUILT-IN ENVELOPES WITHOUT USER CREATED POINTS HIDDEN PROGRAMMATICALLY IT'S FALSE THEREFORE THEY MUST BE VALIDATED VIA CHUNK IN WHICH CASE IT LACKS PT (point) ATTRIBUTE i.e. 'not env_chunk:match('\nPT %d')', BECAUSE EVEN THOUGH IN THE ENVELOPE MANAGER THEY'RE NOT MARKED AS ACTIVE WHILE BEING HIDDEN, FUNCTIONS DO RETURN THEIR POINTER, HIDDEN VIA THE ENVELOPE MANAGER SUCH ENVELOPES MAY BECOME INVALID
	local retval, chunk, is_vis, own_lane
			if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.19 then
			retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			is_vis = chunk:match('\nVIS 1')
			own_lane = chunk:match('\nVIS %d+ 1')
			else
			retval, is_vis = r.GetSetEnvelopeInfo_String(env, 'VISIBLE', '', false) -- setNewValue false
			retval, own_lane = r.GetSetEnvelopeInfo_String(env, 'SHOWLANE', '', false) -- setNewValue false
			is_vis, own_lane = is_vis == '1', own_lane == '1'
			end
--	return is_vis and is_vis == '1' or env_chunk and env_chunk:match('\nVIS 1 ')
	return is_vis, own_lane
	end
end



function Get_Pinned_Tracks_Height()
local H = 0
	if r.GetToggleCommandState(43573) == 0 then -- Track: Override/unpin all pinned tracks in TCP
		for i=-1, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
			if r.IsTrackVisible(tr, false) -- mixer false
			and r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN') == 1 then
			H = H + r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl. envelopes
			end
		end
	end
return H > 0 and H+10 or H -- 10 px is pinned track area separator width
end



function GetSet_Track_Zoom_100_Perc(targ_tr)
-- track 100 zoom is the same as current Arrange height
-- 100% zoom depends on the bottom docker being open
-- which limits Arrange height;
-- targ_tr is optional, only used if there's a track
-- which must be set to 100% hight after the height value in pixels has been retrieved
-- it's also the one which will be scrolled to;
-- pinned tracks are taken into account as they're
-- not included in the Arrange height

local act = r.Main_OnCommand
local GetTrackVal = r.GetMediaTrackInfo_Value

local scroll_to_tr = r.GetTrack(0,0) -- track (any) to scroll back to in order to restore scroll state after track heights restoration
local scroll_to_tr_y = GetTrackVal(scroll_to_tr, 'I_TCPY')

-- Store track heights and get reference track
-- to scroll back to in order to restore scroll state after track heights restoration
-- since ref_tr is also used to get Arrange height, look for one with fixed lanes disabled (in v7)
-- because in these 100% height is allocated to just one lane
-- rather than to the entire TCP, so if there're more than one,
-- the I_TCPH value will be equal 100 * lane count
local v7 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7
local t, ref_tr = {} -- ref_tr is used to get Arrange height
	for i=0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local TCP_H = GetTrackVal(tr, 'I_TCPH')
	t[#t+1] = TCP_H
		-- in version 7 look for track with multi-lanes disabled or collapsed
		if v7 and ( GetTrackVal(tr,'I_NUMFIXEDLANES') == 1
		or GetTrackVal(tr,'C_LANESCOLLAPSED') == 1 )
		or not v7 then
		ref_tr = ref_tr or tr -- once found keep the value
		end
	end

local temp_tr
	if not ref_tr then -- possible in version 7 if all tracks have fixed lanes enabled, may be false if optional targ_t doesn't have fixed lanes enabled
	-- insert new track
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefault false
	ref_tr = r.GetTrack(0,r.GetNumTracks()-1)
	temp_tr = ref_tr
	end

-- Get the data
-- When the actions are applied the UI jolts, but PreventUIRefresh() is not suitable because it blocks the function GetMediaTrackInfo_Value() from getting the return value
-- toggle to minimum and to maximum height are mutually exclusive // selection isn't needed, all are toggled
-- bar pinned tracks, introduced in build 7.46, by the action 40113;
act(40110, 0) -- View: Toggle track zoom to minimum height // affects pinned tracks as well
act(40113, 0) -- View: Toggle track zoom to maximum height [in later builds comment '(limit to 100% of arrange view) has been added' and another action introduced to zoom to maxvzoom value] // the action doesn't affect pinned tracks
------------------------------------
-- The following is only relevant for a few builds starting from 6.76
-- in which action 40113 was zooming in to maxvzoom value rather than 100%
local retval, max_zoom = r.get_config_var_string('maxvzoom')-- min value is 0.125 (13%) which is roughly 1/8th, max is 8 (800%)
max_zoom = retval and max_zoom*100 or 100 -- ignore in builds prior to 6.76 by assigning 100 so that when track height is divided by 100 and multiplied by 100% nothing changes, otherwise convert to conventional percentage value
local tr_h = GetTrackVal(ref_tr, 'I_TCPH')/max_zoom*100 -- not including envelopes, action 40113 doesn't take envs into account; calculating track height as if it were zoomed out to the entire Arrange height by taking into account 'Maximum vertical zoom' setting at Preferences -> Editing behavior

-- if there're visible pinned tracks at the top (introduced in build 7.46), calculate their height because
-- their presence affects max track height obtained above
local pin_tracks_h = 0
	if r.GetToggleCommandState(43573) == 0 then -- Track: Override/unpin all pinned tracks in TCP
		for i=0, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i)
			if r.IsTrackVisible(tr, false) -- mixer false
			and GetTrackVal(tr, 'B_TCPPIN') == 1
			then
			pin_tracks_h = pin_tracks_h + GetTrackVal(tr, 'I_WNDH') -- incl. envelopes
			end
		end
	end

pin_tracks_h = pin_tracks_h > 0 and pin_tracks_h+10 or pin_tracks_h -- 10 px is pinned track area separator width
local tr_h = math.floor(tr_h + pin_tracks_h + 0.5) -- round; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is integer, otherwise the calculated Arrange height is fractional because the actual track height in pixels is integer which is not what it looks like after calculation based on percentage (max_zoom) value, which means the value is rounded in REAPER internally because pixels cannot be fractional and the result is ±1 px diviation compared to the Arrange height calculated at percentages by which 100 can be divided without remainder
local del = temp_tr and r.DeleteTrack(temp_tr) -- delete temp track if one was inserted
------------------------------------

-- Restore track heights
	for k, height in ipairs(t) do
	local tr = r.GetTrack(0,k-1)
	r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', height)
	end

	if targ_tr then -- set to 100% height
	r.SetMediaTrackInfo_Value(targ_tr, 'I_HEIGHTOVERRIDE', tr_h)
	r.SetOnlyTrackSelected(targ_tr)
	act(40913,0) -- Track: Vertical scroll selected tracks into view
	scroll_to_tr = targ_tr -- set scroll_to_tr to target track so that it's the one to scroll to
	scroll_to_tr_y = 0 -- to scroll the targ_tr to the top, where Y is 0
	end

r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275

-- Restore scroll position or scroll the zoomed-in targ_tr to top
r.PreventUIRefresh(1)
r.CSurf_OnScroll(0, -1000) -- scroll all the way up as a preliminary measure to simplify scroll pos restoration because in this case you only have to scroll in one direction so no need for extra conditions
local Y_init = 0
	repeat -- restore track scroll
	r.CSurf_OnScroll(0, 1) -- 1 vert scroll unit is 8 px
	local Y = GetTrackVal(scroll_to_tr, 'I_TCPY')
		if Y ~= Y_init then Y_init = Y else break end -- when the track list is scrolled all the way down and the script scrolls up the loop tends to become endless because for some reason the 1st track whose Y coord is used as a reference can't reach its original pos, this happens regardless of the preliminary scroll direction above, therefore exit loop if it's got stuck, i.e. Y value hasn't changed in the next cycle; this doesn't affect the actual scrolling result, tracks end up where they should // unlike track size value, track Y coordinate accessibility for monitoring isn't affected by PreventUIRefresh()
	until Y <= scroll_to_tr_y
r.PreventUIRefresh(-1)

return tr_h

end




local tr = r.GetSelectedTrack(0,0)

	if not tr then
	Error_Tooltip('\n\n no selected track \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end

local tcp_h = r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
local tcp_h_env = r.GetMediaTrackInfo_Value(tr, 'I_WNDH')
local diff = tcp_h_env-tcp_h

local t = {own_lane={}, media_lane={}}
	for i=0, r.CountTrackEnvelopes(tr)-1 do
	local env = r.GetTrackEnvelope(tr, i)
	local retval, is_vis = r.GetSetEnvelopeInfo_String(env, 'VISIBLE', '', false) -- setNewValue false
	local vis, own_lane = Is_Env_Visible(env)
		if vis then
		table.insert(own_lane and t.own_lane or t.media_lane, env)
		end
	end

	if #t.own_lane + #t.media_lane == 0 then
	Error_Tooltip('\n\n no visible envelopes \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end

local old_builds = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.62 --7.62
local arrange_h = old_builds and GetSet_Track_Zoom_100_Perc()
or r.GetSetProjectInfo(0, 'ARRANGE_H', 0, false) -- is_set false // doesn't account for pinned tracks

-- when toggling envelopes in their own lanes their parent track height must be accounted for
-- because it occupies part of Arrange height
arrange_h = arrange_h - (#t.own_lane > 0 and tcp_h or 0) - (old_builds and 0 or Get_Pinned_Tracks_Height())

local ecp_h = math.floor(arrange_h/#t.own_lane+0.5)
local new_ecp_h
	for k, env in ipairs(t.own_lane) do
	local ret, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	local cur_ecp_h = chunk:match('LANEHEIGHT (%-?%d+)') -- in case height value is negative as a result of some glitch
		if cur_ecp_h+0 ~= ecp_h then -- if height of at least a single ecp is different from the expected zoomed height, zoom in all
		new_ecp_h = ecp_h
		break end
	end

	for k, env in ipairs(t.own_lane) do
	local ret, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	local cur_ecp_h = chunk:match('LANEHEIGHT (%-?%d+)') -- in case height value is negative as a result of some glitch
	-- toggle height of all envelopes based on the presence of at least a single ecp whose height
	-- differs from the expected zoomed height
	-- so that their toggling remains uniform, i.e. performed in one directon only
	cur_ecp_h = Esc(cur_ecp_h) -- in case height value was negative as a result of some glitch and this contains minus which needs escaping
	chunk = chunk:gsub('LANEHEIGHT '..cur_ecp_h, 'LANEHEIGHT '..(new_ecp_h or 1))
	r.SetEnvelopeStateChunk(env, chunk, false) -- isundo false
	end

	if #t.own_lane == 0 and #t.media_lane > 0 then -- increase track own height to accommodate envelopes displayed in the media lane
	local restore_last_h = TOGGLE_TO_LAST_TCP_HEIGHT:match('%S')
	local I_TCPH = r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
	local ret, last_h
		if restore_last_h then
		ret, last_h = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:LAST_HEIGHT', '', false) -- isSet false
			if I_TCPH < arrange_h then -- store
			r.GetSetMediaTrackInfo_String(tr, 'P_EXT:LAST_HEIGHT', I_TCPH, true) -- isSet true
			end
		end
	local min_h = tonumber(MINIMUM_TCP_HEIGHT)
	min_h = min_h and min_h > 0 and math.floor(min_h) == min_h and min_h or 1
	I_TCPH = I_TCPH < arrange_h and arrange_h or last_h or min_h
	r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', I_TCPH)
	r.TrackList_AdjustWindows(true) -- isMinor true, TCP only // update so zoom is apparent immediately
	end


do return r.defer(function() end) end


