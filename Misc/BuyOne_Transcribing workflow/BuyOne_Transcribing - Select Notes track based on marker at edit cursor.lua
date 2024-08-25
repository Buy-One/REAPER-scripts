--[[
ReaScript name: BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Added character escaping to NOTES_TRACK_NAME setting evaluation to prevent errors caused unascaped characters
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M
About:	The script is part of the Transcribing workflow set of scripts
	alongside
	BuyOne_Transcribing - Create and manage segments (MAIN).lua  
	BuyOne_Transcribing - Real time preview.lua  
	BuyOne_Transcribing - Format converter.lua  
	BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing - Prepare transcript for rendering.lua  
	BuyOne_Transcribing - Go to segment marker.lua
	BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua
	
	It's a kind of the opposit of the script  
	'BuyOne_Transcribing - Go to segment marker.lua'
	
	Since the transcript can be divided between several tracks
	due to SWS Notes size limit per object, this script allows
	selecting the Notes track in which the time stamp of the
	marker closest to the edit cursor on the left or currently 
	at the edit cursor is found which simplifies the workflow.
	
	When REAPER is in play mode the reference position is taken
	from the play cursor, otherwise from the edit cursor.
	
	If you find it more convenient to point at a marker or a space
	between them with the mouse cursor, the following custom action
	can be used being mapped to a shortcut:
	
	Custom: Transcribing - Select Notes track based on marker at edit cursor  
		View: Move edit cursor to mouse cursor  
		BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua
		
	The script doesn't create an undo point.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of track(s)
-- where Notes with the transcript are stored;
-- must match the same setting in the script
-- 'BuyOne_Transcribing - Create and manage segments.lua';
-- CHANGING THIS SETTING MIDPROJECT IS NOT RECOMMENDED
-- BECAUSE SCRIPT ACCESS TO THE NOTES TRACKS WILL BE LOST
NOTES_TRACK_NAME = "TRANSCRIPT"

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


function Get_Segment_Mrkr_At_Edit_Play_Curs()

local mrkr_idx = r.GetPlayState()&1 == 1 and r.GetLastMarkerAndCurRegion(0, r.GetPlayPosition())
or r.GetLastMarkerAndCurRegion(0, r.GetCursorPosition())

	if mrkr_idx > -1 then -- there're markers left of the cursor
	local i = mrkr_idx
		repeat
		local retval, isrgn, pos, rgnend, name, markr_idx = r.EnumProjectMarkers(i)
			if retval > 0 and not isrgn and (r.parse_timestr(name) ~= 0 or name == '00:00:00.000')
			then return name
			end
		i=i-1
		until retval == 0
	end

end


function Get_Notes_Track(mrkr_name, NOTES_TRACK_NAME)
-- the function accounts for missing tracks
-- in which case the 'not found' message is displayed

local tr_t = {}

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index, st_stamp, end_stamp = data:match('^(%d+) (.-) (.*)')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index) then
		tr_t[#tr_t+1] = {tr=tr, name=name, idx=index, st=st_stamp, fin=end_stamp}
		end
	end


-- sort the table by integer in the track extended state
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

	local function time_stamp_exists(tr, stamp)
	local notes = r.NF_GetSWSTrackNotes(tr)
		for line in notes:gmatch('[^\n].*') do
			if line:match(stamp) then return
			true
			end
		end
	end

local parse = r.parse_timestr

	for k, props in ipairs(tr_t) do
	local st_stamp, end_stamp = props.st, props.fin
		if not st_stamp then -- in case the time stamps aren't stored in the track extended state, look in the notes
		local notes = r.NF_GetSWSTrackNotes(props.tr)
		st_stamp = notes:match('.-(%d%d:%d+:%d+%.%d+) ')
		end_stamp = notes:match('.+(%d%d:%d+:%d+%.%d+) ')
		end
		if st_stamp and parse(st_stamp) > parse(mrkr_name) then
		local tr = k > 1 and tr_t[k-1].tr -- previous track
			if tr and time_stamp_exists(tr, st_stamp) then return tr end
		elseif end_stamp and parse(end_stamp) >= parse(mrkr_name) then
		return props.tr -- current track
		end
	end

-- if there's only 1 Notes track
local tr = tr_t[1].tr
	if tr then
	local st_stamp, end_stamp = tr_t[1].st, tr_t[1].fin
		if not st_stamp then -- in case the time stamps aren't stored in the track extended state, look in the notes
		local notes = r.NF_GetSWSTrackNotes(tr)
		st_stamp = notes:match('.-(%d%d:%d+:%d+%.%d+) ')
		end_stamp = notes:match('.+(%d%d:%d+:%d+%.%d+) ')
		end
		if st_stamp and end_stamp
		and parse(mrkr_name) >= parse(st_stamp)
		and parse(mrkr_name) <= parse(end_stamp)
		then return tr
		end
	end

end



NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local mrkr_name = Get_Segment_Mrkr_At_Edit_Play_Curs()

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n   setting is empty'
or not mrkr_name and 'no segment marker \n\n at the edit cursor'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return end

local tr = Get_Notes_Track(mrkr_name, NOTES_TRACK_NAME)

	if not tr then
	Error_Tooltip("\n\n relevant notes track \n\n\twasn't found \n\n", 1, 1) -- caps, spaced true
	return end

r.SetOnlyTrackSelected(tr)
r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view

do return r.defer(no_undo) end





