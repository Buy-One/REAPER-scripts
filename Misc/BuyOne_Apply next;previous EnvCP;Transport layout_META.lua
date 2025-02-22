--[[
ReaScript name: BuyOne_Apply next;previous EnvCP;Transport layout_META.lua (4 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962, 6.36+ recommended
Metapackage: true
Provides:	[main=main,midi_editor] .
		. > BuyOne_Apply next EnvCP layout.lua
		. > BuyOne_Apply previous EnvCP layout.lua
		. > BuyOne_Apply next Transport layout.lua
		. > BuyOne_Apply previous Transport layout.lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.

	The script name is self-explanatory.

	In the script targetting envelope control panel layout,
	first found visible envelope control panel is scrolled
	into view.

	Cycling the layouts essentially cycles its Global  
	default layouts, those listed under 
	Options -> Layouts -> Transport / Envelope panel
	which means that once its layout is switched to, it will apply 
	to all new and other projects.

	Layout change doesn't create an undo point due to REAPER design.

	To cycle layouts with the individual scripts in both 
	directions, use the following custom actions:

	Custom: Cycle ECP layouts  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Apply previous ECP layout.lua  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Apply next ECP layout.lua


	Custom: Cycle Transport layouts  
		Action: Skip next action if CC parameter >0/mid  
		BuyOne_Apply previous Transport layout.lua  
		Action: Skip next action if CC parameter <0/mid  
		BuyOne_Apply next Transport layout.lua  


	And bind them to the mousewheel. The associaton between 
	the mousewheel scroll direction and the performed action
	is as follows: mousewheel forward/out/up - next,  
	mousewheel backward/in/down - previous. 
	To reverse the direction add action   
	'Action: Modify MIDI CC/mousewheel: Negative'  
	at the very beginning of each custom action sequence.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumetic
-- character between the quotes
-- to prevent script operation if the target object, i.e.
-- envelope control panel or transport depending
-- on the script name, is invisible
PREVENT_IF_INVISIBLE = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of caption and value
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...}
	local str = #t > 1 and '' or tostring(t[1])..'\n'
		if #t > 1 then -- OR if #str == 0
			for i=1,#t,2 do
				if i > #t then break end
			local cap, val = t[i], t[i+1]
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



function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

		if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

local names_t, content = names_t

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		------------------------------------------------------------------------------------
		-- THERE'RE USER SETTINGS OR THE META SCRIPT IS ALSO FUNCTIONAL SO FILES AREN'T UNNECESSARILY CREATED WHEN IT RUNS
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR writing to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end
		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe ---------------- !!!!!!!! INCOMMENT
				end
			end
		end

	end

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


function Get_TCP_MCP_Under_Mouse(want_mcp)
-- takes advantage of the fact that the action 'View: Move edit cursor to mouse cursor'
-- doesn't move the edit cursor when the mouse cursor is over the TCP;
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP;
-- master track is supported;
-- want_mcp is boolean to address MCP under mouse, supported in builds 6.36+

-- in builds < 6.36 the function also detects MCP under mouse regardless of want_mcp argument
-- because when the mouse cursor is over the MCP the action 'View: Move edit cursor to mouse cursor'
-- does move the edit cursor unless the focused MCP is situated to the left of the Arrange view start
-- or to the right of the Arrange view end depending on the 'View: Show TCP on right side of arrange'
-- setting, which makes 'new_cur_pos == edge or new_cur_pos == 0' expression true because the edit cursor
-- being unable to move to the mouse cursor is moved to the Arrange view start_time/end_time,
-- in later builds this is prevented by conditioning the return value with info:match('tcp')
-- so that the focus is solely on TCP if want_mcp arg is false

-- for builds 6.36+ where GetThingFromPoint() is supported
local tr, info = table.unpack(r.GetThingFromPoint and {r.GetThingFromPoint(r.GetMousePosition())} or {})
	if info then
	return (want_mcp and info:match('mcp') or not want_mcp and info:match('tcp')) and tr
	end

local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end


function Is_Env_Visible(env)
	if r.CountEnvelopePoints(env) > 0 then -- validation of fx envelopes in REAPER builds prior to 7.06 // SUCH VALIDATION IS ALWAYS TRUE FOR VALID TRACK FX ENVELOPES AND ALL TAKE ENVELOPES REGARDLESS OF VISIBILITY, FOR VISIBLE BUILT-IN TRACK ENVELOPES REGARDLESS OF PRESENCE OF USER CREATED POINTS AND FOR HIDDEN BUILT-IN TRACK ENVELOPES WHICH HAVE USER CREATED POINTS; FOR HIDDEN TRACK BUILT-IN ENVELOPES WITHOUT USER CREATED POINTS IT'S FALSE THEREFORE THEY MUST BE VALIDATED VIA CHUNK IN WHICH CASE IT LACKS PT (point) ATTRIBUTE
	local retval, chunk, is_vis
			if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.19 then
			retval, chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
			else
			retval, is_vis = r.GetSetEnvelopeInfo_String(env, 'VISIBLE', '', false) -- setNewValue false
			end
	return is_vis and is_vis == '1' or env_chunk and env_chunk:match('\nVIS 1 ')
	end
end


function Scroll_Track_To_Top(tr, env)
local GetValue = r.GetMediaTrackInfo_Value
local tr_y = GetValue(tr, 'I_TCPY')
--local tr_h = GetValue(tr, 'I_TCPH')
local env_y = env and r.GetEnvelopeInfo_Value(env, 'I_TCPY') or 0 -- the result is the same as with tr_h
local dir = tr_y < 0 and -1 or tr_y > 0 and 1 -- if less than 0 (out of sight above) the scroll must move up to bring the track into view, hence -1 and vice versa
r.PreventUIRefresh(1)
local Y_init -- to store track Y coordinate between loop cycles and monitor when the stored one equals to the one obtained after scrolling within the loop which will mean the scrolling can't continue due to reaching scroll limit when the track is close to the track list end or is the very last, otherwise the loop will become endless because there'll be no condition for it to stop
	if dir then
		repeat
		r.CSurf_OnScroll(0, dir) -- unit is 8 px
		local Y = GetValue(tr, 'I_TCPY')
			if Y ~= Y_init then Y_init = Y -- store
			else break end -- if scroll has reached the end before track has reached the destination to prevent loop becoming endless
		until dir > 0 and Y+env_y <= 0 or dir < 0 and Y+env_y >= 0
	end
r.PreventUIRefresh(-1)
end



function Get_Vis_Envelope(last_idx)
-- relies on Scroll_Track_To_Top()
-- first find track which is likely visible, i.e. its TCP Y coordinate is >= 0
-- or Y < 0 and Y+height > 0, to prevent changing the scroll state drastically,
-- if within view nothing is found, first matching track
-- out of sight at the bottom will be brought into view,
-- if such track wasn't be found, search is performed again from
-- the first visible track up in reverse,
-- that is among tracks out of sight at the top,
-- so that always the track closest to the visible tracklist start
-- is scrolled into view at the top

local tr_cnt = r.GetNumTracks()
local last_idx = last_idx
local st, fin, dir = table.unpack(not last_idx and {0,tr_cnt-1,1} or {last_idx-1,0,-1})

	for i=st, fin, dir do
	local tr = r.GetTrack(0,i)
	local retval, flags = r.GetTrackState(tr)
		if flags&512 ~= 512 then -- visible in TCP
		local Y = r.GetMediaTrackInfo_Value(tr, 'I_TCPY')
		local H = r.GetMediaTrackInfo_Value(tr, 'I_WNDH') -- incl envelopes
			if not last_idx and (Y >= 0 or Y < 0 and Y+H > 0) or last_idx then
			last_idx = i
				for i=0, r.CountTrackEnvelopes(tr)-1 do
				local env = r.GetTrackEnvelope(tr,i)
					if Is_Env_Visible(env) then
					r.PreventUIRefresh(1)
					Scroll_Track_To_Top(r.GetTrack(0,0)) -- first scroll the very 1st track to top resetting tracklist scroll position to ensure that the ECP scroll position doesn't drift with each script run which happens because after each scroll the Y coordinate it stops at slightly changes
					Scroll_Track_To_Top(tr,env) -- scroll to the target track ECP
					r.PreventUIRefresh(-1)
					return true
					end
				end
			end
		end
	end

return Get_Vis_Envelope(last_idx) -- if not found after the first visible track run the loop again from the first visible at last_idx backwards to the tracklist start

end


function Apply_Next_Previous_Layout(layout_t, layout_type, dir, attr)

local nxt, prev = dir == 'next', dir == 'previous'
local master = tr == r.GetMasterTrack(0)
local retval, layout

-- with ECP/Transport current layout is always Global default, so essentially changing the layout changes the Global default
retval, layout = r.ThemeLayout_GetLayout(layout_type, -1) -- -1 to quiery current default value
--[[-- OR via reaper.ini
local key = layout_type == 'ECP' and 'layout_envcp' or layout_type == 'trans' and 'layout_trans'
retval, layout = r.get_config_var_string(key)
]]

layout = #layout == 0 and layout_t[1] or layout -- if empty string or in reaper.ini no name is stored or the key is absent, the very first layout is used as default
local cur_layout_idx = layout_t[layout] or 1 -- if the returned by ThemeLayout_GetLayout() Global default layout stored in reaper.ini at the key layout_master_mcp=/layout_master_tcp= belongs to another theme, layout_t[layout] will be nil in which case fall back on index 1 of the table holding current theme layouts
layout = nxt and (layout_t[cur_layout_idx+1] or layout_t[1])
or prev and (layout_t[cur_layout_idx-1] or layout_t[#layout_t]) -- if out of range, wrap around

r.ThemeLayout_SetLayout(layout_type, layout) -- this will change Global default layout

return layout

end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext


	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Apply next;previous EnvCP;Transport layout_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

--scr_name = 'previous Transport' ------------------ NAME TESTING

local layout_type = scr_name:match('EnvCP') and 'envcp' or scr_name:match('Transport') and 'trans'

local nxt, prev = scr_name:match('next'), scr_name:match('previous')

	if not nxt and not prev or not layout_type then
	Error_Tooltip('\n\n  script name is not recognized. \n\n please restore the original name\n\n', 1, 1, 50) -- caps, spaced true, x2 50
	return r.defer(no_undo)
	end

local prevent = #PREVENT_IF_INVISIBLE:gsub(' ','') > 0

	if prevent then
		if layout_type == 'trans' and r.GetToggleCommandStateEx(0, 40259) == 0 -- View: Toggle transport visible
		or layout_type == 'envcp' and not Get_Vis_Envelope() then
		local obj = layout_type == 'trans' and 'Transport' or 'track envelope control panel \n\n\t'..(' '):rep(4)
		Error_Tooltip('\n\n '..obj..' is not visible \n\n', 1, 1, 50) -- caps, spaced true, x2 50
		return r.defer(no_undo)
		end
	end


local i, layout_t = 0, {}

	repeat
	local retval, layout = r.ThemeLayout_GetLayout(layout_type, i) -- layout_type arg is apparently case agnostic // doesn't include 'Global Default' layout returned by GetSetMediaTrackInfo_String() as an empty string, must be queried with i arg being -1
		if retval and #layout > 0 then
		local idx = #layout_t+1
		layout_t[idx] = layout
		layout_t[layout] = idx
		end
	i = i+1
	until not retval

	if #layout_t < 2 then
	Error_Tooltip('\n\n no layouts to switch to \n\n', 1, 1, 50) -- caps, spaced true, x2 50
	else
	local layout = Apply_Next_Previous_Layout(layout_t, layout_type, nxt or prev)
	Error_Tooltip('\n\n '..layout..' \n\n ', nil, nil, 50) -- caps, spaced nil, x2 50
	end

do	return r.defer(no_undo) end














