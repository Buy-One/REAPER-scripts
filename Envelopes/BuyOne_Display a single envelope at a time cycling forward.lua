--[[
ReaScript name: BuyOne_Display a single envelope at a time cycling forward.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	Inspired by actions introduced in build 7.47
		Track: Hide envelope, display next/previous envelope on same track (cycle)
		but works slightly differently and supports
		take envelopes.
				
		The script doesn't allow making multiple envelopes 
		of the same object visible at once.  
		If multiple envelopes have been made visible manually, 
		the script will hide all and unhide the first hidden 
		envelope which followed the last visible one.  
		If no such envelope is found, i.e. all active envelopes 
		are initially visible, the script will leave the very 
		first one unhidden.  
		If no envelope is visible and there's only one active
		envelope the script will unhide it.
		
		The object targeting priority is as follows: 
		take under mouse
		track under mouse
		parent take of the selected take envelope
		parent track of the selected track envelope
		active take of selected item
		selected track
		last touched track
]]


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
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
do return end
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


function Is_Selected_Track_Or_Take_Env()
local env = r.GetSelectedEnvelope(0)
-- local take_env = r.GetSelectedTrackEnvelope(0) ~= env
-- return env and not take_env, env and take_env -- track env, take env // 2 return values
-- OR
-- return env and (not take_env and 'track' or 'take') -- track env, take env // 1 return value
-- OR
-- local take_env = env and r.GetSelectedTrackEnvelope(0) ~= env
-- return env, take_env
-- OR
	if env then
	return r.Envelope_GetParentTrack(env), r.Envelope_GetParentTake(env)
	end
end


function Get_Active_Envelopes(obj)
	local function get_hidden_built_in_track_env(env)
	local env_name_t = {VOLENV='', VOLENV2='', VOLENV3='', PANENV='', PANENV2='',
	DUALPANENVL='', DUALPANENV='', DUALPANENVL2='', DUALPANENV2='', WIDTHENV='',
	WIDTHENV2='', MUTEENV='', AUXVOLENV='', AUXPANENV='', AUXMUTEENV='', PARMENV='', TEMPOENVEX=''}
	local ret, env_name = r.GetEnvelopeName(env)
		if env_name_t[env_name] then
		local retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			if not chunk:match('\nPT %d') then return env end
		end
	end
local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Count_Envs, GetEnv = table.unpack(take and {r.CountTakeEnvelopes, r.GetTakeEnvelope}
or tr and {r.CountTrackEnvelopes, r.GetTrackEnvelope})

local t = {}
	for i=0, Count_Envs(obj)-1 do
	local env = GetEnv(obj, i)
		if r.CountEnvelopePoints(env) > 0 or get_hidden_built_in_track_env(env) then -- validation of fx envelopes in REAPER builds prior to 7.06 // SUCH VALIDATION IS ALWAYS TRUE FOR VALID TRACK FX ENVELOPES AND ALL TAKE ENVELOPES REGARDLESS OF VISIBILITY, FOR VISIBLE BUILT-IN TRACK ENVELOPES REGARDLESS OF PRESENCE OF USER CREATED POINTS AND FOR HIDDEN BUILT-IN TRACK ENVELOPES WHICH HAVE USER CREATED POINTS; FOR TRACK BUILT-IN ENVELOPES WITHOUT USER CREATED POINTS HIDDEN PROGRAMMATICALLY IT'S FALSE THEREFORE THEY MUST BE VALIDATED VIA CHUNK IN WHICH CASE IT LACKS PT (point) ATTRIBUTE i.e. 'not env_chunk:match('\nPT %d')', BECAUSE EVEN THOUGH IN THE ENVELOPE MANAGER THEY'RE NOT MARKED AS ACTIVE WHILE BEING HIDDEN, FUNCTIONS DO RETURN THEIR POINTER, HIDDEN VIA THE ENVELOPE MANAGER SUCH ENVELOPES BECOME INVALID
		local ret, name = r.GetEnvelopeName(env)
		t[#t+1] = {name=name, env=env}
		end
	end
return t
end


function Get_Env_State(env, attr)
-- attr is integer:
-- 1 - visibility, 2 - bypass state, 3 - armed state
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.19
local attr = attr == 1 and (old_build and 'VIS' or 'VISIBLE') or attr == 2 and (old_build and 'ACT' or 'ACTIVE')
or attr == 3 and 'ARM' -- same in chunk and as a function attribute
local retval, chunk, state
	if old_build then
	retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	else
	retval, state = r.GetSetEnvelopeInfo_String(env, attr, '', false) -- setNewValue false
	end
return state and state == '1' or env_chunk and env_chunk:match('\n'..attr..' 1') or false
end


function Toggle_Env_State(arg, attr, state)
-- arg is either an envelope pointer or an array of envelope pointers
-- attr is integer:
-- 1 - visibility, 2 - bypass state, 3 - armed state
-- state: nil - set the state signified by attr argument of all envelopes to off, true/false - toggle
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.99 -- changes produced with the function GetSetEnvelopeInfo_String() aren't registered so undo point cannot be created, bug report https://forum.cockos.com/showthread.php?t=303814, and toggling must be done via a chunk, or with actions listed above that require selecting envelope which may not be the optimal solution, so using build number with a leeway until fixed
local attr = attr == 1 and (old_build and 'VIS' or 'VISIBLE') or attr == 2 and (old_build and 'ACT' or 'ACTIVE')
or attr == 3 and 'ARM' -- same in chunk and as a function attribute
local t, env = type(arg) == 'table' and arg, r.ValidatePtr(arg, 'TrackEnvelope*') and arg
local hide = state == nil -- only for visibility state
local state = state and 0 or 1
local st, fin = 1, env and 1 or t and #t

	for i=st, fin do
	local env = env or t[i].env
		if old_build then
		local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
		-- when using chunk, arm state cannot be toggled
		-- in a bypassed envelope, because arm flag 1 isn't cleared
		-- on bypassing, so it first must be unbypassed,
		-- this is not a problem when using GetSetEnvelopeInfo_String() function
			if attr == 'ARM' and env_chunk:match('\nACT 0') then
			env_chunk = env_chunk:gsub('\nACT 0', '\nACT 1')
			end
		env_chunk = env_chunk:gsub('\n'..attr..' %d', '\n'..attr..' '..(hide and 0 or state))
		r.SetEnvelopeStateChunk(env, env_chunk, false) -- isundo false
		else
		r.GetSetEnvelopeInfo_String(env, attr, hide and 0 or state, true) -- setNewValue true
		local take = r.Envelope_GetParentTake(env)
		-- redraw the graphics
			if take then
			r.UpdateItemInProject(r.GetMediaItemTake_Item(take))
			else
			r.TrackList_AdjustWindows(true) -- isMinor true, TCP only
			end
		end
	end
end


function Select_Envelope(env)
r.SetCursorContext(2, env) -- select visible envelope
local take = r.Envelope_GetParentTake(env)
-- redraw the graphics, only needed for take envelopes
	if take then
	r.UpdateItemInProject(r.GetMediaItemTake_Item(take))
	end
end



local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

----------------------
--	scr_name = 'cycling backwards' -------------- NAME TESTING
----------------------

local forward, backwards = scr_name:match('cycling forward'), scr_name:match('cycling backwards')
	if not forward and not backwards then
	Error_Tooltip('\n\n script name isn\'t recognized \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

-- priority is as follows: take under mouse, track under mouse, selected take envelope, selected track envelope, active take of selected item, selected track, last touched track
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, false) -- allow_locked false
local tr, info = r.GetTrackFromPoint(x, y)
	if not take and not tr then -- no object under mouse
	tr, take = Is_Selected_Track_Or_Take_Env()
	end
	if not take and not tr then -- no selected envelope
	local item = r.GetSelectedMediaItem(0,0)
	take = item and r.GetActiveTake(item)
	tr = not take and r.GetSelectedTrack(0,0) -- no selected item
	tr = tr or r.GetLastTouchedTrack() -- no selected track
	end

	if not take and not tr then
	Error_Tooltip('\n\n no target object \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end


local env_t = Get_Active_Envelopes(take or tr)

local vis_cnt, vis_idx = 0, 0
	for k, v in ipairs(env_t) do
	local vis = Get_Env_State(v.env, 1) -- attr argument is 1 - visibility
	vis_cnt = vis and vis_cnt+1 or vis_cnt
	vis_idx = forward and (vis and k or vis_idx) or backwards and (vis_idx ~= 0 and vis_idx or vis and k or 0) -- when cycling forward, get last visible envelope index in case there're many visible updating the variable each time a new visible envelope is found, when cycling backwards, get the very first visible envelope index and maintain its pointer throughout the loop falling back to 0 if none is visible
	end

local err = #env_t == 0 and 'no active envelopes' or #env_t == 1 and vis_idx > 0 and 'one active visible envelope \n\n\t nothing to cycle' -- OR vis_idx == 1 OR vis_cnt == 1 instead of vis_idx > 0

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

r.Undo_BeginBlock()

	if vis_idx > 0 then
	Toggle_Env_State(vis_cnt > 1 and env_t or env_t[vis_idx].env, 1) -- attr argument is 1 - visibility, if multiple envelopes are visible loop over the table to hide, otherwise hide the exclusively visible envelope, vis arg is nil - hide condition
	end

local env_idx = backwards and (vis_idx > 1 and vis_idx-1 or #env_t)
or forward and (vis_idx < #env_t and vis_idx+1 or 1)
local env = env_t[env_idx].env
Toggle_Env_State(env, 1, false) -- attr argument is 1 - visibility, state is false, invisible
Select_Envelope(env) -- select visible envelope
local name = env_t[env_idx].name
undo = (vis_cnt > 1 and 'Leave ' or 'Set ')..(take and 'take' or 'track')..' "'..name..'" envelope exclusively visible'

r.Undo_EndBlock(undo, -1)



