--[[
ReaScript name: BuyOne_Insert multiple new tracks with default input FX chain.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
About:	To create a default input FX chain to be used with this script
	when you save a regular default FX chain via 
	FX chain right click menu -> FX cgains -> Save all FX as defaut chain for new tracks
	add to it the FX needed to be inserted by default into the input
	FX chain preceded with an FX instance (ANY) named "input chain start"
	which is a title instance, so that your chain looks something like so:
		FX 1
		FX 2
		FX 3
		input chain start
		FX A
		FX B
		FX C
	
	FX which precede the title instance named 'input chain start' will
	remain in the main FX chain, while those which follow it will
	be moved to the input FX chain.
	The title instance name can be padded with spaces.
	
	If you only need to save input FX chain as defaut chain, don't
	precede the title instance with any FX, so that your chain starts
	with the title instance, e.g:
		input chain start
		FX A
		FX B
		FX C
	
	When the chain is applied to the input FX chain the title instance
	is deleted.
	
	!!!!! CAVEAT
	
	If FX in your default chain are linked through parameter modulation, 
	parameter modulation linkage won't be preserved when they're moved 
	to the input FX chain. For this use another script			
	BuyOne_Insert multiple new tracks with default input FX chain + PM.lua
	OR
	BuyOne_Apply FX chain preset to input FX chain in selected tracks.lua
				
	To insert news tracks select a track which they'll be inserted after.
	If no track is selected the new tracks will be inserted at the end
	of the track list.
]]

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


function Split_Chain(single)

	for i=0, r.CountSelectedTracks(0)-1 do -- when tracks are inserted with actions they end up being selected
	local tr = r.GetSelectedTrack(0,i)
	local fx_cnt = r.TrackFX_GetCount(tr)
		if fx_cnt == 0 then -- no default FX chain
		Error_Tooltip('\n\n there\'s no default fx chain \n\n in the newly inserted track'..(not single and 's' or '')..' \n\n', 1, 1) -- caps, spaced true
		return end
	local cntr, found = 0
		for i=0, fx_cnt-1 do
		local ret, name = r.TrackFX_GetFXName(tr, i, '')
			if name:match('^%s*input chain start%s*$') then found = i
			elseif found then
			r.TrackFX_CopyToTrack(tr, i, tr, 0x1000000|cntr, false) -- is_move false to not break the loop by moving
			cntr = cntr+1 -- fx insert index for the next cycle
			end
		end
		-- delete all copied fx from the main chain + the title fx instance
		for i = fx_cnt-1, found, -1 do
		r.TrackFX_Delete(tr, i)
		end
	end
return true
end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
scr_name = scr_name:match('[^\\/]+%.lua')
local single, mult = scr_name:match('single new track'), scr_name:match('multiple new tracks')

	if not single and not mult then
	Error_Tooltip('\n\n incorrect script name \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local sel_tr = r.GetSelectedTrack(0,0)
local actID = single and (sel_tr and 40001 or 40702) -- Track: Insert new track OR Track: Insert new track at end of track list
or mult and sel_tr and 41067 -- Track: Insert multiple new tracks... // insert multiple tracks dialogue is a modal window so the script will pause as long as it's active // the native actions insert tracks after the last touched track, which may not be obvious, in particular if the preference at Appearence -> Highlight edit cursor over last selected track is disabled or build is earlier than 6.25 where the last touched track isn't indicated with the edit cursor

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local ACT = r.Main_OnCommand
	if single then
	ACT(actID,0)
	else
		if actID then -- there's selected track
		ACT(actID,0)
		else -- no selected track, insert at the end of the track list
		ACT(40702,0) -- Track: Insert new track at end of track list // insert temporarily to move insert focus so that multiple tracks are inserted at the end as well
		r.DeleteTrack(r.GetSelectedTrack(0,0)) -- delete the temp track
		ACT(41067,0) -- Track: Insert multiple new tracks...
		end
	end

local ok = Split_Chain(single)

local undo = ok and 'Insert '..(single or multiple)..' with default input FX chain'

r.Undo_EndBlock(undo or r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
r.PreventUIRefresh(-1)




