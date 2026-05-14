--[[
ReaScript name: BuyOne_Select tracks to the start of tracklist in TCP (Ctrl+Shift+Home).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	Selects tracks visible in the TCP
		to the start of the tracklist 
		starting from the currently selected 
		track.
		
		Mimics behavior of text processors
		where text can be selected from the
		carriage position to the very start 
		of the document.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric 
-- character between the quotes
-- for the track list to be scrolled 
-- to the topmost track
WANT_SCROLL = ""

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



function Scroll_Track_To_Top(tr, env)
-- env arg is optional, only if the first envelope
-- displayed in its own lane needs to be scrolled to
-- THE FUNCTION MUST NOT BE RUN BETWEEN PreventUIRefresh() FUNCTION
-- INSTANCES BECAUSE THEY PREVENT GETTING CURRENT TRACK Y COORDINATE
-- FOR FURTHER CALCULATIONS

-- calculate height of the pinned tracks (supported since 7.46)
-- only if pinned tracks are displayed in the pinned area
-- i.e. Track: Override/unpin all pinned tracks in TCP option is Off;
-- track spacers aren't included because they're not supported
-- in pinned tracks area
local top_Y = 0
	if r.GetToggleCommandState(43573) == 0 then -- Track: Override/unpin all pinned tracks in TCP
		for i=-1, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
			if r.IsTrackVisible(tr, false) -- mixer false
			and r.GetMediaTrackInfo_Value(tr, 'B_TCPPIN') == 1 then
			top_Y = top_Y + r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl. envelopes
			end
		end
	top_Y = top_Y > 0 and top_Y+10 or top_Y -- 10 px is pinned track area separator width
	end
-- OR 
-- local top_Y = Get_Pinned_Tracks_Height()

local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
--local tr_h = GetValue(tr, 'I_TCPH')
local env_y = env and r.GetEnvelopeInfo_Value(env, 'I_TCPY') or 0 -- the result is the same as with tr_h

local dir = tr_y < top_Y and -1 or tr_y > top_Y and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			else break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y+env_y <= top_Y or dir < 0 and Y+env_y >= top_Y
	end
r.PreventUIRefresh(-1)
end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

-- NAME TESTING
--------------------------
-- scr_name = 'start'
-------------------------

local sel_tr = r.GetSelectedTrack(0,0)

	if not sel_tr then 
	Error_Tooltip('\n\n no selected tracks \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end
	
local sel_tr_idx = r.CSurf_TrackToID(sel_tr, false)-1 -- mcpView false
local st, fin, dir = table.unpack(scr_name:match('end') and {sel_tr_idx, r.GetNumTracks()-1, 1} 
or scr_name:match('start') and {sel_tr_idx,0,-1} or {})

	if not st then
	Error_Tooltip('\n\n sript name is not recognized \n\n', 1,1) -- caps, spaced true
	return r.defer(function() end)
	end

	for i=st, fin, dir do 
	local tr = r.GetTrack(0,i)
		if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then
		r.SetTrackSelected(tr, true) -- selected true
		sel_tr = tr
		end
	end
	
--[[
-- alternatively could have been accomplished with actions
-- SCROLLS AUTOMATICALLY
local fin, ID = table.unpack(scr_name:match('end') and {r.GetNumTracks()-sel_tr_idx, 40287} -- Track: Go to next track (leaving other tracks selected)
or scr_name:match('start') and {sel_tr_idx, 40288}) -- Track: Go to previous track (leaving other tracks selected)
r.PreventUIRefresh(1)
	for i=1, fin do
	r.Main_OnCommand(ID, 0)
	end
r.PreventUIRefresh(-1)
--]]
	
	if WANT_SCROLL:match('%S') then
	Scroll_Track_To_Top(sel_tr)
	end
	
do r.defer(function() end) end
	
	
	
	
	
	
