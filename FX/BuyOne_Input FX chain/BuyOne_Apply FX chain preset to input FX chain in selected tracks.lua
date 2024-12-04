--[[
ReaScript name: BuyOne_Apply FX chain preset to input FX chain in selected tracks.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
About:	Although the script can be used by itself, 
			its primary purpose was to be used inseide 
			a custom action with the native actions
			Track: Insert new track
			Track: Insert new track at end of mixer
			Track: Insert new track at end of track list
			Track: Insert multiple new tracks...
			E.g.  
			Custom: Insert new track with default input FX chain
				Track: Insert new track
				BuyOne_Apply FX chain preset to input FX chain in selected tracks.lua
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of the FX chain preset file
-- you want the script to apply to input FX chain,
-- with or without the extension,
-- the file must be located in the 'FXChains' folder
-- of the REAPER resource directory
FX_CHAIN_FILE_NAME = ""

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


function Update_Chunk(tr_chunk, fx_cnt, chain_chunk)
local ch_cnt = chain_chunk:match('REQUIRED_CHANNELS (%d+)') -- will be absent if the chain only uses 2 channels
	if ch_cnt then
	tr_chunk = tr_chunk:gsub('NCHAN %d+', 'NCHAN '..ch_cnt)
	chain_chunk = chain_chunk:match('REQUIRED_CHANNELS %d+(\n.+)') -- exclude channel data because it's not part of the chunk
	else
	chain_chunk = '\n'..chain_chunk -- add new line char to match structure of chain with channel data for appending to the track chunk
	end
local tr_chunk1, tr_chunk2 = tr_chunk:match('(.+)(>)') -- split the chunk
-- adding fx chain to track after items code isn't a problem,
-- REAPER then places them in correct order
return tr_chunk1..'<FXCHAIN_REC'..chain_chunk..'>\n'..tr_chunk2 -- works without '>\n' as well
end


function Apply_FXChain(chain_chunk)
-- if target chain already contains fx they're replaced,
-- REAPER seems to respect the chain chunk which appears later in the track chunk
-- so existence of several chain chunks of the same type doesn't break it,
-- for tracks, existing track items aren't a problem

	for i=0, r.CountSelectedTracks(0)-1 do -- when tracks are inserted with actions they end up being selected
	local tr = r.GetSelectedTrack(0,i)
	local fx_cnt = r.TrackFX_GetCount(tr)
	local ret, tr_chunk = r.GetTrackStateChunk(tr, '', false) -- isundo false
	tr_chunk = Update_Chunk(tr_chunk, fx_cnt, chain_chunk)
	r.SetTrackStateChunk(tr, tr_chunk, false) -- isundo false
	end

end


local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local f_path = path..sep..'FXChains'..sep..(FX_CHAIN_FILE_NAME:match('.+%.RfxChain') or FX_CHAIN_FILE_NAME..'.RfxChain') -- adding extension if absent in the setting
local sel_tr = r.GetSelectedTrack(0,0)
local err = #FX_CHAIN_FILE_NAME:gsub(' ','') == 0 and 'INPUT FX CHAIN FILE NAME \n\n\t     is empty'
or not r.file_exists(f_path) and 'the specified fx chain file \n\n\t   doesn\'t exist'
or not sel_tr and 'no selected tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local f = io.open(f_path, 'r')
local chain_chunk = f:read('*a')
f:close()

	if #chain_chunk:gsub('[%s%c]','') == 0 then
	Error_Tooltip('\n\n the fx chain file is empty \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
scr_name = scr_name:match('([^\\/_]+)%.lua')

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

Apply_FXChain(chain_chunk)

r.Undo_EndBlock(scr_name, -1)
r.PreventUIRefresh(-1)




