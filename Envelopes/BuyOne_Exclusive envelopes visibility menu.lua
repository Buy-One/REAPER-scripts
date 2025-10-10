--[[
ReaScript name: BuyOne_Exclusive envelopes visibility menu.lua
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
			
			The menu is designed to toggle exclusive visibility 
			of active envelopes, so that only one envelope is
			visible at a time.  			
			The script doesn't allow making multiple envelopes 
			of the same object visible at once.  
			If multiple envelopes have been made visible manually, 
			clicking one visible envelope menu item hides all other 
			visible envelopes while the envelope of the clicked menu 
			item remains visible.  
			In REAPER when an armed envelope is bypassed, it's 
			automatically unarmed, therefore a checkmark will be 
			cleared from  
			'Toggle arming of the visible envelope' menu item when 
			'Toggle bypass of the visible envelope' menu item is clicked
			And vice versa, when a bypassed envelope is armed, it's 
			automatically unbypassed, therefore a checkmark will be 
			cleared from 
			'Toggle bypass of the visible envelope' menu item when 
			'Toggle arming of the visible envelope' menu item is clicked
			
			The object targeting priority is as follows: 
			take under mouse
			track under mouse
			parent take of the selected take envelope
			parent track of the selected track envelope
			active take of selected item
			selected track
			last touched track
]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character
-- between the quotes if you wish the menu to stay
-- open after menu item is clicked;
-- the setting can be managed directly from the menu
KEEP_OPEN = "1"


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- the earliest instance of a particular character at the start of a menu item
-- can be used as a shortcut provided this character is unique in the menu
-- in this case they don't have to be preceded with ampersand '&'
-- if it's not unique, inputting it from keyboard will select
-- the menu item starting with this character
-- and repeated input will oscilate the selection between menu items
-- which start with it without actually triggering them
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest instance at the start of a menu item
-- some characters still do need ampresand, e.g. < and >;
-- characters which aren't the first in the menu item name
-- must also be explicitly preceded with ampersand

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	-- screen reader used by blind users with OSARA extension may be affected
	-- by the absence if the gfx window therefore only disable it in builds
	-- newer than 6.82 if OSARA extension isn't installed
	-- ref: https://github.com/Buy-One/REAPER-scripts/issues/8#issuecomment-1992859534
	local OSARA = r.GetToggleCommandState(r.NamedCommandLookup('_OSARA_CONFIG_reportFx')) >= 0 -- OSARA extension is installed
	local init = (old or OSARA or not old and not OSARA and keep_menu_open) and gfx.init('', 0, 0)
	-- open menu at the mouse cursor, after reloading the menu doesn't change its position based on the mouse pos after a menu item was clicked, it firmly stays at its initial position
		-- ensure that if keep_menu_open is enabled the menu opens every time at the same spot
		if keep_menu_open and not coord_t then -- keep_menu_open is the one which enables menu reload
		coord_t = {x = gfx.mouse_x, y = gfx.mouse_y}
		elseif not keep_menu_open then
		coord_t = nil
		end

	gfx.x = coord_t and coord_t.x or gfx.mouse_x
	gfx.y = coord_t and coord_t.y or gfx.mouse_y

	return gfx.showmenu(menu) -- menu string

	end

end


function Toggle_Setting_From_Menu(sett_name, scr_path)

-- load the setting
local settings, sett_line
	for line in io.lines(scr_path) do
		if not settings and line:match('----- USER SETTINGS ------') then
		settings = 1
		elseif settings and line:match('^%s*'..sett_name..'%s*=%s*".-"') then -- ensuring that it's the setting line and not reference to it elsewhere
		sett_line = line
		break
		elseif line:match('END OF USER SETTINGS') then
		break
		end
	end

local sett_new_state = sett_line:match('^%s*'..sett_name..'%s*=%s*"(%S+)"') and '' or '1' -- toggle

-- update
local f = io.open(scr_path,'r')
local cont = f:read('*a')
f:close()
local sett_upd = sett_name..' = "'..sett_new_state..'"'
local cont, cnt = cont:gsub(sett_name..'%s*=%s*".-"', sett_upd, 1)
	if cnt > 0 then -- settings were updated, write to file
	local f = io.open(scr_path,'w')
	f:write(cont)
	f:close()
	end

return sett_new_state

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
		if r.CountEnvelopePoints(env) > 0 or get_hidden_built_in_track_env(env) then -- validation of fx envelopes in REAPER builds prior to 7.06 // SUCH VALIDATION IS ALWAYS TRUE FOR VALID TRACK FX ENVELOPES AND ALL TAKE ENVELOPES REGARDLESS OF VISIBILITY, FOR VISIBLE BUILT-IN TRACK ENVELOPES REGARDLESS OF PRESENCE OF USER CREATED POINTS AND FOR HIDDEN BUILT-IN TRACK ENVELOPES WHICH HAVE USER CREATED POINTS; FOR HIDDEN TRACK BUILT-IN ENVELOPES WITHOUT USER CREATED POINTS IT'S FALSE THEREFORE THEY MUST BE VALIDATED VIA CHUNK IN WHICH CASE IT LACKS PT (point) ATTRIBUTE i.e. 'not env_chunk:match('\nPT %d')', BECAUSE EVEN THOUGH IN THE ENVELOPE MANAGER THEY'RE NOT MARKED AS ACTIVE WHILE BEING HIDDEN, FUNCTIONS DO RETURN THEIR POINTER
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

-- priority is as follows: take under mouse, track under mouse, selected take envelope, selected track envelope, active take of selected item, selected track, last touched track
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, false) -- allow_locked false
local tr, info = r.GetTrackFromPoint(x, y)
	if not take and not tr then
	tr, take = Is_Selected_Track_Or_Take_Env()
	end
	if not take and not tr then
	local item = r.GetSelectedMediaItem(0,0)
	take = item and r.GetActiveTake(item)
	tr = not take and r.GetSelectedTrack(0,0)
	tr = tr or r.GetLastTouchedTrack()
	end

	if not take and not tr then
	Error_Tooltip('\n\n no target object \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end


::RELOAD::

local env_t = Get_Active_Envelopes(take or tr)

	if #env_t == 0 then
	Error_Tooltip('\n\n no active envelopes \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local menu, vis_cnt = '', 0
	for k, v in ipairs(env_t) do
	local vis = Get_Env_State(v.env, 1) -- attr argument is 1 - visibility
	vis_cnt = vis and vis_cnt+1 or vis_cnt
	menu = menu..(#menu > 0 and '|' or '')..(vis and '!' or '')..v.name
	end

-- get first currently visible envelope
-- it will be conditioned by vis_cnt value to ensure that it's
-- exclusively visible as it may not match the envelope of the clicked menu item
-- if more than one envelope is visible or none is,
-- meant mainly for bypass and arm toggle menu items
local vis_env
	for k, v in ipairs(env_t) do
		if Get_Env_State(v.env, 1) then -- attr argument is 1 - visibility
		vis_env = v.env
		break end
	end

-- only get the state if exactly one envelope is visible
-- in order to checkmark relevant menu items
-- because if more than one is visible or none, checkmarking in pointless
local is_unbypassed = vis_cnt == 1 and Get_Env_State(vis_env, 2) -- attr argument is 2 - bypass
local is_armed = vis_cnt == 1 and Get_Env_State(vis_env, 3) -- attr argument is 3 - arming

	function grayout(cnt, state, item_name)
	return ((cnt > 1 or cnt == 0) and '#' or state and '!' or '')..item_name..'||'
	end

local GetObjName = take and r.GetSetMediaItemTakeInfo_String or tr and r.GetSetMediaTrackInfo_String
local ret, obj_name = GetObjName(take or tr, 'P_NAME', '', false) -- setNewValue false
-- when track is named, its index is added to 'Track' label,
-- otherwise index is used instead of the name
local tr_idx = tr and r.CSurf_TrackToID(tr, false) -- mcpView false
local obj_name = (take and 'Take: ' or tr and 'Track'..(#obj_name > 0 and ' '..tr_idx or '')..': ')
..(#obj_name > 0 and obj_name or tr and tr_idx or 'No name') -- mcpView false
local bypass = grayout(vis_cnt, not is_unbypassed, 'Toggle bypass of the visible envelope') -- gray out when more than 1 envelope is visible because the action is only applicable to a single visible envelope
local armed = grayout(vis_cnt, is_armed, 'Toggle arming of the visible envelope') -- gray out when more than 1 envelope is visible because the action is only applicable to a single visible envelope
--local output = Show_Menu_Dialogue(obj_name..'||'..bypass..armed..menu)
KEEP_OPEN = KEEP_OPEN:match('%S+')
local keep_open = (KEEP_OPEN and '!' or '')..'Keep menu open after click||'
local output = Reload_Menu_at_Same_Pos(obj_name..'||'..keep_open..bypass..armed..menu, 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo) end

local vis_env_name = vis_env and select(2, r.GetEnvelopeName(vis_env)) or 'NAME' -- or 'vis_cnt == 1' inetead of 'vis_env' // if no envelope is visible add placeholder which in the undo point name will be replaced with the actual name of the envelope set to be visible
local undo = 'Set "'..vis_env_name..(take and '" take' or '" track')..' envelope '

r.Undo_BeginBlock()

	if output == 2 then
	KEEP_OPEN = Toggle_Setting_From_Menu('KEEP_OPEN', scr_path)
	elseif output < 5 then
	undo = undo:gsub('Set', '%0 visible')
		if output == 3 then -- toggle bypass
		Toggle_Env_State(vis_env, 2, is_unbypassed) -- attr argument is 2 - bypass
		undo = undo..(is_unbypassed and 'bypassed' or 'unbypassed')
		elseif output == 4 then -- toggle arming
		Toggle_Env_State(vis_env, 3, is_armed) -- attr argument is 3 - arming
		undo = undo..(is_armed and 'unarmed' or 'armed')
		end
	else -- toggle visibility
	output = output-4 -- offset first 3 menu items
	local env = env_t[output].env
	local vis = Get_Env_State(env, 1) -- attr argument is 1 - visibility // evaluate whether visible, before hiding all
		if vis_env and env ~= vis_env or vis_cnt > 1	then
		Toggle_Env_State(env_t, 1) -- attr argument is 1 - visibility, vis arg is nil - hide condition
		end
		if not vis_env or env ~= vis_env or vis_cnt > 1 then -- only execute if menu item of an envelope other than currently visible has been clicked or when all envelopes are hidden or when more than one is visible, i.e. do not execute if menu item of the currently exclusively visible envelope has been clicked so it's not toggled to hidden
		Toggle_Env_State(env, 1, vis_cnt == 1 and vis) -- attr argument is 1 - visibility // vis_cnt == 1 cond ensures that visibility is toggled only if the envelope is exclusively visible, while if more envelopes are visible, after all get hidden the visibility of the envelope of the clicked menu item is restored, i.e. it's not toggled to hidden or remains hidden with the rest
		end
	local name = vis_env_name
		if undo:match('NAME') or vis_env ~= env then -- if initially no envelope was visible or many were visible and the envelope of the clicked menu item is not the envelope retrieved as vis_env above
		name = select(2, r.GetEnvelopeName(env))
		end

	Select_Envelope(env) -- select visible envelope

	undo = vis_cnt > 1 and 'Set '..(take and 'take' or 'track')..' envelopes hidden except "'..name..'"'
	or undo..(vis_cnt == 1 and (vis and 'hidden' or 'visible') or vis_cnt == 0 and 'visible')
		if name then -- replace name placeholder when no envelope was initially visible
		undo = undo:gsub('NAME', name)
		end
	end

r.Undo_EndBlock(undo, -1)

	if output > 0 and KEEP_OPEN then goto RELOAD end



