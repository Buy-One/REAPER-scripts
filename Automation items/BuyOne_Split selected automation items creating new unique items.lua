--[[
ReaScript name: BuyOne_Split selected automation items creating new unique items.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The script splits selected automation items
	under the edit cusrsor.
	
	It's an alternative to the native action
	'Envelope: Split automation items'
	in that after automation items are split each part
	becomes a unique AI with its own length and can be
	immediately looped.
	
	After AI is split with the native action the parts
	of the split end up being simply trimmed instances 
	of the original AI, preserving all its envelope data
	and original AI length.

	The native AI behavior is showcased in this video
	https://www.youtube.com/watch?v=ql-e_LUqSB0&t=33s
	
	The script uses AI gluing to achieve the desired 
	result so it's simply an automated way of gluing.
		
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

local edit_cur_pos = r.GetCursorPosition()

local t = {}

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
		for env_idx = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr,env_idx)
			if r.CountEnvelopePoints(env) > 0 then -- in REAPER builds prior to 7.06 TakeFX_GetEnvelope() returns env even if there's none but parameter mudulation was enabled at least once for the corresponding fx parameter hence must be validated with CountEnvelopePoints(env) because in this case there're no points
				for AI_idx = 0, r.CountAutomationItems(env)-1 do
					if r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', -1, false) == 1 then -- is_set false // selected hence will be split
					local st = r.GetSetAutomationItemInfo(env, AI_idx, 'D_POSITION', -1, false)
					local fin = st + r.GetSetAutomationItemInfo(env, AI_idx, 'D_LENGTH', -1, false)
						if st < edit_cur_pos and fin > edit_cur_pos then
						t[#t+1] = {env=env,AI_idx=AI_idx}
						end
					end
				end
			end
		end
	end

	if #t == 0 then
	Error_Tooltip('\n\n    no selected automation \n\n items under the edit cursor \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end


r.Undo_BeginBlock()

local ACT = r.Main_OnCommand

ACT(42087,0) -- Envelope: Split automation items

function Select_AI_Parts(t, right_part, left_part)
	for k, data in pairs(t) do
	local env, AI_idx = data.env, data.AI_idx
	-- left part of the AI split retains the original index
	r.GetSetAutomationItemInfo(env, AI_idx, 'D_UISEL', right_part, true) -- is_set true
	-- to target the right part the original index must be incremented by 1
	r.GetSetAutomationItemInfo(env, AI_idx+1, 'D_UISEL', left_part, true) -- is_set true
	end
end

	Select_AI_Parts(t, 1, 0) -- left_part 1 select, right_part 0 de-select

	-- glue all selected
	ACT(42089,0) -- Envelope: Glue automation items // only leaves the last AI in the project selected

	Select_AI_Parts(t, 0, 1) -- left_part 0 de-select, right_part 1 select

	-- glue all selected
	ACT(42089,0) -- Envelope: Glue automation items // only leaves the last AI in the project selected

	-- re-select right part and de-select left part of the split in all AIs
	Select_AI_Parts(t, 0, 1) -- left_part 0 de-select, right_part 1 select

r.Undo_EndBlock('Split selected automation items creating new unique items',-1)






