--[[
ReaScript name: BuyOne_Apply folder parent track color to all child tracks.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	If any tracks are selected the colors will be applied
        to their children tracks only, if any. Otherwise to 
        children tracks of all parent tracks if any is found.
        
        When tracks are selected the script respects sub-folders, 
        meaning the subfolder parent track color will only be 
        applied to this subfolder children tracks.
        
        Among selected tracks within the same folder structure 
        higher level parent track color overrides lower level 
        parent track colors.

]]


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



function Get_All_Children(t, ...) -- arg is either track idx or track pointer

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
t[tr] = {}
local child_t = t[tr]
	for i = tr_idx+1, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local tr_depth = r.GetTrackDepth(tr)
		if tr_depth > depth then
		child_t[#child_t+1] = tr
		elseif tr_depth <= depth then break
		end
	end

end


local tr_cnt = r.CountSelectedTracks(0)
tr_cnt = tr_cnt > 0 and tr_cnt or r.CountTracks(0)

	if tr_cnt == 0 then
	Error_Tooltip('\n\n no tracks in project \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end
	
local GetTrack = r.CountSelectedTracks(0) > 0 and r.GetSelectedTrack or r.GetTrack

local t = {}	
	
	for i=0, tr_cnt-1 do -- collect parent and their children tracks
	local tr = GetTrack(0,i)
	Get_All_Children(t, tr)
	end	
	
	
r.Undo_BeginBlock()
	
local counter, child_cnt = 0, 0
	for tr, child_t in pairs(t) do -- apply color
	local color = r.GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')
	child_cnt = child_cnt+#child_t
		for _, child_tr in ipairs(child_t) do		
			if r.GetMediaTrackInfo_Value(child_tr, 'I_CUSTOMCOLOR') ~= color then			
			r.SetMediaTrackInfo_Value(child_tr, 'I_CUSTOMCOLOR', color|0x100000, true) -- isSet true
			counter = counter+1
			end
		end
	end

local err = child_cnt == 0 and 'no parent tracks were found' or counter == 0 and '  no colors were applied \n\n because they didn\'t differ'
	
	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo) end
	
	
r.Undo_EndBlock('Apply folder parent track color to all child tracks',-1)

	

