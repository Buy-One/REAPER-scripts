--[[
ReaScript name: BuyOne_Send selected tracks to designated track for monitoring.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:	The script creates sends from selected tracks 
    		to the designated track whose name is specified
    		in the MONITOR_TRACK_NAME setting in the USER SETTINGS
    		below.
    		
    		It's designed to mimic the 'Current track' feature of
    		FL Studio: https://www.youtube.com/watch?v=0zcZum7BPeM, quote
    		"The specially named 'Current' track can only receive audio 
    		from the currently selected track. Its main purpose is to 
    		hold an Edison plugin, ready to record any selected tracks 
    		audio OR visualization plugins, such as WaveCandy"
    		(https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/mixer_iorouting.htm)
    		
    		Needless to say that it can also be used for monitoring
    		purposes housing analyzers and such.
    		
    		In the case of this script however all selected tracks are 
    		routed to the designated track.
    		
    		The Master send on the designated track is disabled to prevent
    		duplication of the signal on the Master track.
    		
    		Receives from selected tracks on the designated track are 
    		mutually exclusive, any current receive whose source track 
    		isn't selected is automatically removed, unless no track or
    		only the designated track is selected in which case receives
    		remain intact. Sends from tracks already routed to the designated
    		track aren't duplicated in case the same track is featured 
    		in different track selections.
    		
    		The script can be executed in manual and auto modes. In manual
    		mode to make it perform operations described above it much be 
    		run each time new track selection has to be sent to the designated
    		track. If AUTO setting is enabled in the USER SETTINGS the script
    		will run in the background and automatically send any selected 
    		track to the designated track.  
    		
    		When the script runs in AUTO mode toolbar button or menu item 
    		it's linked to are lit or checkmarked respectively.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Specify the name of the designated track
-- to be used for monitoring;
-- the match between this setting and
-- the actual name of the designated track in the project
-- must be exact disregarding leading and trailing spaces
MONITOR_TRACK_NAME = "Current"

-- To enable, insert any alphanumeric
-- character between the quotes
AUTO = ""

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


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function REAPER_Ver_Check(build, want_later, want_earlier, want_current)
-- build is REAPER build number or sring, the function must be followed by 'do return end'
-- want_later, want_earlier and want_current are booleans
-- obviously want_later and want_earlier are mutually exclusive
-- want_later includes current, want_earlier is the up-to version
local build = build and tonumber(build)
cur_buld = tonumber(r.GetAppVersion():match('[%d%.]+'))
local later, earlier, current = cur_buld >= build, cur_buld < build, cur_buld == build
local err = '   the script requires \n\n  '
local err = not later and err..'reaper '..build..' and later '
or not earlier and err..'reaper not later than '..build
	if err then
	local x,y = r.GetMousePosition()
	err = err:upper():gsub('.','%0 ')
	r.TrackCtl_SetToolTip(err, x, y+10, true) -- topmost true
	return true
	end -- 'ReaScript:Run' caption is displayed in the menu bar but no actual undo point is created because Undo_BeginBlock() isn't yet initialized, here and elsewhere
end


function Get_Designated_Track(tr, MONITOR_TRACK_NAME)
local tr_name = tr and r.GetTrackState(tr)
	if tr and tr_name:match('[%w%p]*[%w%p]') == MONITOR_TRACK_NAME
	then return tr
	else
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local tr_name = r.GetTrackState(tr)
			if tr_name:match('[%w%p]*[%w%p]') == MONITOR_TRACK_NAME -- trimming any leading and trailing spaces and accounting for 1 character name
			then return tr
			end
		end
	end
end


function Track_Selection_Changed(t)
local sel_tr_cnt = r.CountSelectedTracks(0)
	if sel_tr_cnt > 0 and t then -- if no selected, everything remains the same
		if sel_tr_cnt ~= #t then return true -- count has changes
		else
			for _, tr_idx in ipairs(t) do
			local tr = r.GetTrack(0,tr_idx-1) -- -1 since in the passed table they're stored in 1-based count
				if not r.IsTrackSelected(tr) then
				return true end -- track selection has changed
			end
		end
	elseif
	-- takes care of cases when the script was launched in AUTO mode
	-- without tracks or a designated track in a project
	sel_tr_cnt > 0 then return true
	end
end


function Remove_Track_Receives(tr)
-- single loop isn't enough, if more than 2 receives
-- after the loop GetTrackNumSends() still returns a number greater than 0
-- probably due to sluggish update
-- the result is duplcation of send from the some tracks
-- since original send couldn't be deleted fast enough, before another one was created
	for i=0, r.GetTrackNumSends(tr, -1)-1 do -- category -1 receives
	r.RemoveTrackSend(tr, -1, i) -- category -1 receives
	end
	if r.GetTrackNumSends(tr, -1) > 0 then
	Remove_Track_Receives(tr)
	end
end


function Create_Sends_From_Sel_Tracks(mon_tr)
	if mon_tr then
		if r.GetMediaTrackInfo_Value(mon_tr, 'B_MAINSEND') == 1 then
		r.SetMediaTrackInfo_Value(mon_tr, 'B_MAINSEND', 0) -- disable master/parent send just in case it isn't
		end
		-- clear current recieves
		if not (r.CountSelectedTracks(0,0) == 1 and r.IsTrackSelected(mon_tr)) then
		-- the condition prevents receives removal when in AUDO mode
		-- the designated track is the only one selected
		Remove_Track_Receives(mon_tr)
		end
	local tr_numbers = {} -- to be used in the undo point description
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
			if r.IsTrackSelected(tr) then
			r.CreateTrackSend(tr, mon_tr)
			tr_numbers[#tr_numbers+1] = i+1
			end
		end
		-- disable MIDI sends https://forum.cockos.com/showthread.php?t=287218
		for i=0, r.GetTrackNumSends(mon_tr, -1)-1 do -- category -1 receives
		r.SetTrackSendInfo_Value(mon_tr, -1, i, 'I_MIDIFLAGS', 31) -- category -1 receives
		end
	return tr_numbers
	end
end


function RUN()

	if Track_Selection_Changed(tr_numbers) then
	mon_tr = Get_Designated_Track(mon_tr, MONITOR_TRACK_NAME)
	tr_numbers = Create_Sends_From_Sel_Tracks(mon_tr)
	end

r.defer(RUN)

end


MONITOR_TRACK_NAME = MONITOR_TRACK_NAME:match('[%w%p]*[%w%p]') -- trimming any leading and trailing spaces and accounting for 1 character name
AUTO = #AUTO:gsub(' ','') > 0

local err = not r.GetTrack(0,0) and 'no tracks in the project'
or not r.GetTrack(0,1) and '\tthere\'s only 1 \n\n track in the project'
or not r.GetSelectedTrack(0,0) and 'no selected tracks'
or #MONITOR_TRACK_NAME:gsub(' ','') == 0 and 'designated track name is not set'

	if err and not AUTO then -- only in manual mode
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

mon_tr = Get_Designated_Track(tr, MONITOR_TRACK_NAME)

err = not mon_tr and '    the designated monitor \n\n track "'..MONITOR_TRACK_NAME..'" wasn\'t found'
or r.IsTrackSelected(mon_tr) and not r.GetSelectedTrack(0,1) and 'the designated monitor track \n\n     is the only one selected'

	if err and not AUTO then -- only in manual mode
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end

is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()

	if not AUTO then
	r.Undo_BeginBlock()
	end

tr_numbers = Create_Sends_From_Sel_Tracks(mon_tr)

	if not AUTO then
	r.Undo_EndBlock('Send tracks '..table.concat(tr_numbers, ', ')..'  to designated monitor track',-1)
	end

	if AUTO then
	Re_Set_Toggle_State(sect_ID, cmd_ID, 1)
	RUN()
	end

	if AUTO then
	r.atexit(Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0)) -- for defer scripts
	end





