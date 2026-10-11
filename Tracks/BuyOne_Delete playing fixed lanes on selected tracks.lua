--[[
ReaScript name: BuyOne_Delete playing fixed lanes on selected tracks.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	Script complementing native actions
		which only allow deleting non-playing lanes.

]]


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

function no_undo()
end


function Deselect_All_Tracks() -- API alternative to the action 'Track: Unselect all tracks' (40297)
local master = r.GetMasterTrack(0) -- Master track because it's always there
r.SetOnlyTrackSelected(master)
r.SetTrackSelected(master, false) -- selected is false
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



local sel_tr_cnt = r.CountSelectedTracks()

	if sel_tr_cnt == 0 then
	Error_Tooltip('\n\n no selected tracks \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local t = {}
local lanes_play

	for i=0, r.CountSelectedTracks()-1 do
	local tr = r.GetSelectedTrack(0,i)
	local lane_cnt = r.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES')
		if lane_cnt > 1 then
		t[tr] = {}
			for i=0, lane_cnt-1 do
				if r.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..i) > 0 then -- lane plays
				table.insert(t[tr], i)
				lanes_play = 1
				end
			end
		end
	end


local selected = 'on selected tracks'
local err = not next(t) and 'no multiple fixed lanes \n\n    '..selected
or not lanes_play and '  no playing lanes \n\n '..selected
	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)

	for tr, playing_lanes in pairs(t) do
	Deselect_All_Tracks() -- deselect all because the action affects all sekected tracks at once which pverents granular lane deletion
	r.SetTrackSelected(tr, true) -- selected true // select track so that action affects it
	r.SetMediaTrackInfo_Value(tr, 'C_ALLLANESPLAY', 1) -- set all play
		for i=#playing_lanes, 1, -1 do -- in reverse due to deletion
		local idx = playing_lanes[i]
		r.SetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:'..idx, 0) -- turn lane off
		r.Main_OnCommand(42691, 0) -- Track lanes: Delete lanes (including media items) that are not playing
		end
	r.SetMediaTrackInfo_Value(tr, 'C_ALLLANESPLAY', 0) -- turn remaining lanes off, because that's supposed to be the state after deletion of all playing lanes
	end

	-- restore track selection
	for tr in pairs(t) do
	r.SetTrackSelected(tr, true) -- selected true
	end

r.TrackList_AdjustWindows(true) -- isMinor, TCP only
r.PreventUIRefresh(-1)
r.Undo_EndBlock('Delete playing lanes on selected tracks', -1)






