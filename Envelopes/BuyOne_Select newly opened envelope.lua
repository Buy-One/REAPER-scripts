--[[
ReaScript name: BuyOne_Select newly opened envelope.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
RREAPER: at least v5.962, 7.19 is recommended
About: 	The script sets the newly opened envelope selected.
			It can be either envelope that's just been created
			or one that's been unhidden.
			
			The script can only work as part of a custom action
			alongside one of the following stock REAPER actions:
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
			
			and SWS extension actions:
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
						
			If several envelopes are opened at once only the first 
			one found will be set selected. REAPER doesn't support 
			selection of several envelopes.
			
			THE CUSTOM ACTION SEQUENCE MUST LOOK AS FOLLOWS:
			
			BuyOne_Select newly opened envelope.lua
			--- REAPER/SWS Extension ACTION ---
			BuyOne_Select newly opened envelope.lua			

]]


local r = reaper

local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
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



function Is_Env_Visible(env)
	if r.CountEnvelopePoints(env) > 0 then -- validation of fx envelopes in REAPER builds prior to 7.06
	local build = tonumber(r.GetAppVersion():match('[%d%.]+'))
	local retval, chunk, is_vis
			if build < 7.19 then
			retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			else
			retval, is_vis = r.GetSetEnvelopeInfo_String(env, 'VISIBLE', '', false) -- setNewValue false
			end
	return is_vis and is_vis == '1' or env_chunk and env_chunk:match('\nVIS 1 ')
	end
end



function Store_Get_Env_Pointers(cmdID, pointer_t, orig_count)

local count = 0

	for tr_idx = 0, r.GetNumTracks() do
	local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
			if Is_Env_Visible(env) then
			count = count+1
				if pointer_t and (not pointer_t[tostring(env)] or not next(pointer_t)) then -- select // the table will be empty if initially there were no open envelopes
				r.SetCursorContext(2, env) -- 2 focus Arrange and select the envelope
				r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
				return
				elseif not pointer_t then -- store
				local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
				r.SetExtState(cmdID, 'POINTER_LIST', pointer_list..'\n'..tostring(env), false) -- persist false
				end
			end
		end
	end

	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		for i = 0, r.CountTakes(item)-1 do
		local take = r.GetTake(item, i)
			for i = 0, r.CountTakeEnvelopes(take)-1 do
			local env = r.GetTakeEnvelope(take,i)
				if Is_Env_Visible(env) then
				count = count+1
					if pointer_t and (not pointer_t[tostring(env)] or not next(pointer_t)) then -- select // the table will be empty if initially there were no open envelopes
					r.SetCursorContext(2, env) -- 2 focus Arrange and select the envelope
					r.UpdateItemInProject(item) -- so that selection is immediately visible
					r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
					return
					elseif not pointer_t then -- store
					local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
					r.SetExtState(cmdID, 'POINTER_LIST', pointer_list..'\n'..tostring(env), false) -- persist false
					end
				end
			end
		end
	end

	if not pointer_t then
	local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')
	r.SetExtState(cmdID, 'POINTER_LIST', count..pointer_list, false) -- persist false // store envelope count prior to action execution
	elseif pointer_t then -- if the function reached this point while pointer_t is valid, no newly open envelope was found
	r.DeleteExtState(cmdID, 'POINTER_LIST', true) -- persist true
		if count == orig_count+0 then -- this prevents the error message when the toggle action is used within the custom action and the envelope has been toggled to off in which case there's also no newly opened envelope but their total count differs
		Error_Tooltip('\n\n no newly opened envelope \n\n\t     was found \n\n', 1, 1) -- caps, spaced true
		end
	end

end


local is_new_value, scr_name, sect_ID, cmdID_init, mode, resol, val, contextstr = r.get_action_context()
local cmdID = r.ReverseNamedCommandLookup(cmdID_init)

local pointer_list = r.GetExtState(cmdID, 'POINTER_LIST')

	if #pointer_list == 0 then -- store
	Store_Get_Env_Pointers(cmdID) -- envelope pointers are collected instead of GUIDs because their uniqueness isn't guaranteed, in copies of tracks/takes they stay the same until the envelope is deleted
	else -- evaluate after action execution and select an envelope if any
	local pointer_t = {}
		for pointer in pointer_list:gmatch('[^\n]+') do
			if pointer then
			pointer_t[pointer] = '' -- dummy entry
			end
		end
	local orig_count = pointer_list:match('^%d+')
	Store_Get_Env_Pointers(cmdID, pointer_t, orig_count)
	end















