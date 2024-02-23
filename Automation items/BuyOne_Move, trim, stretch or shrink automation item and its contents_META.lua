--[[
ReaScript name: BuyOne_Move, trim, stretch or shrink automation item and its contents_META.lua (31 script)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.4
Changelog:  v1.4 #Fixed individual script installation function
		  #Made individual script installation function more efficient
	    v1.3 #Fixed automatic installation of individual scripts in the Action list
	    v1.2 #Creation of individual scripts has been made hands-free. 
	    	  These are created in the directory the META script is located in
	    	  and from there are imported into the Action list.
	    	  #Updated About text
	    v1.1 #Added support for getting envelope under mouse cursor if SWS extension is installed
	    	 #Updated About text
Metapackage: true
Licence: WTFPL
REAPER: at least v5.962
About: 	This package of 31 scripts aims at allowing operations with automation 
	items (AI) similar to those available for media items with native REAPER
	actions. The difference is that only one automation item at a time can 
	be affected. The target automation item must be selected. The envelope 
	the automation item belongs to must also be selected unless the SWS/S&M 
	extension is installed and the mouse cursor points at the envelope. If 
	several automation items are selected on an envelope only the first one 
	will be affected by the scripts.
	
	If this script name is suffixed with META, when executed it will 
	automatically spawn all individual scripts included in the package into 
	the directory of the META script and will import them into the Action list 
	from that directory. That's provided such scripts don't exist yet, if they 
	do, then in order to recreate them they have to be deleted from the Action 
	list and from the disk first.  
	If there's no META suffix in this script name it will perfom the operation 
	indicated in its name.
	
	THE SCRIPT LIST and the specifics of their behavior
	
	Move left/right edge of selected automation item to edit/mouse cursor (4)
	
	Move contents of selected automation item to edit/mouse cursor (2)		
	Behavior:	If cursor is to the left of the AI start, contents are moved left, 
				if it's to the right of the AI start, contents are moved right.
				The contents are moved by the distance between the cursor and
				the AI start.

	Move selected automation item to edit/mouse cursor preserving contents (2)
	Behavior: 	If cursor is to the left of the AI start, the AI is moved left, 
				if it's to the right of the AI start, the AI is moved right.

	Move contents of selected automation item 10 ms left/right (2)
	Move selected automation item 10 ms left/right preserving contents (2)
	These two scripts above can be duplicated and value 10 can be replaced in 
	the duplicates name with another value to be able to move to by a different
	distance.
	
	
	Trim left/right edge of selected automation item to edit/mouse cursor (4)
	Behavior:	The edit/mouse cursor must be located within the AI or outside
				of its target edge.
	
	Trim left/right edge of selected automation item to edit/mouse cursor and loop (4)
	Behavior: 	This is a variant of the previous script which enables AI loop 
				if it's not enabled
	
	Stretch or shrink left/right edge of selected automation item to edit/mouse cursor (4)
	Behavior:	The edit/mouse cursor must be located within the AI or outside
				of its target edge.

	The following scripts must be run with the mousewheel

	Move/trim/stretch of shrink edge of selected automation item to mouse cursor (mousewheel) (3)
	Behavior:	AI left edge is being affected when the mouse cursor is to the left 
				of the AI start and the mousewheel is in (down) or the mouse cursor 
				is between the AI start and its end and the mousewheel out (up). 
				AI right edge is being affected when the mouse cursor is to the right 
				of the AI end and the mousewheel is out (up) or the mouse cursor 
				is between the AI start and its end and the mousewheel in (down).
	
	Move contents of selected automation item to mouse cursor (mousewheel)
	Behavior:	If the mouse cursor is to the left of the AI start 
				and the mousewheel is in (down), contents are moved left, 
				the mousewheel out (up) is ignored.  
				If the mouse cursor is to the right of the AI start 
				and the mousewheel is out (up), contents are moved right, 
				the mousewheel in (down) is ignored.

	Move selected automation item to mouse cursor preserving contents (mousewheel)
	Behavior:	If the mouse cursor is to the left of the AI start 
				and the mousewheel is in (down), the AI is moved left, 
				the mousewheel is out (up) is ignored.  
				If the mouse cursor to the right of the AI start 
				and the mousewheel is out (up) the AI is moved right, 
				the mousewheel in (down) is ignored.

	Move contents of selected automation item 10 ms (mousewheel)
	Move selected automation item 10 ms preserving contents (mousewheel)
	Behavior:	The functionality of both scripts doesn't depend 
				on the mouse cursor position, only on the mouswheel direction.
	These two scripts above can be duplicated and value 10 can be replaced in 
	the duplicates name with another value to be able to move to by a different
	distance.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- The following settings only apply to scripts containing '(mouseweheel)'
-- part in their name

-- The default direction is: 
-- mousewheel in/down - leftwards, mousewheel out/up - rightwards
-- to reverse the direction activate by inserting 
-- any character between the quotes,
MOUSEWHEEL_REVERSE = ""

-- Between the quotes insert number of nudges needed
-- to trigger the script;
-- the higher the number the lower the sensitivity;
-- normally a single scroll consists of 5-6 nudges;
-- when empty the sensitivity is at the maximum, i.e. 1
MOUSEWHEEL_SENSITIVITY = ""

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


function space(n) -- number of repeats, integer
return (' '):rep(n)
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Invalid_Script_Name(scr_name,...)
-- check if necessary elements are found in script name, case agnostic
-- if more than 1 match is needed run twice or more times with different sets of elements which are supposed to appear in the same name, but elements within each set must not be expected to appear in the same name, that is they must be mutually exclusive
-- if running twice or more times the error message and Rep() function must be used outside of this function after expression 'if no_elm1 or no_elm2 then'
local t = {...}
	for k, elm in ipairs(t) do
		if scr_name:lower():match(Esc(elm:lower())) then return end
	end
return true
end


function Parse_Script_Name(scr_name, t)
-- case agnostic
local t_len = #t -- store here since with nils length will be harder to get
	for k, elm in ipairs(t) do
	t[k] = scr_name:lower():match(Esc(elm:lower())) --or false -- to avoid nils in the table, although still works with the method below
	end
-- return table.unpack(t) -- without nils
return table.unpack(t,1,t_len) -- not sure why this works, not documented anywhere, but does return all values if some of them are nil even without the n value (table length) in the 1st field
-- found mentioned at
-- https://stackoverflow.com/a/1677358/8883033
-- https://stackoverflow.com/questions/1672985/lua-unpack-bug
-- https://uopilot.tati.pro/index.php?title=Unpack_(Lua)
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
	
	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

	if names_t and #names_t > 0 then

--[[ GETTING PATH FROM THE USER INPUT
	
	r.MB('              This meta script will spawn 31\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)

	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD

	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
		
	]]

	-- load this script
	local this_script = io.open(fullpath, 'r')
	local content = this_script:read('*a')
	this_script:close()

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH
	
	local prefix, insert = 'BuyOne_', 'selected automation item'
		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
			if scr_name:match('edge') then
			scr_name = scr_name:gsub('edge', '%0 of '..insert)
			elseif scr_name:match('Move contents') then
			scr_name = scr_name:gsub('Move contents', '%0 of '..insert)
			elseif scr_name:match('Move') then
			scr_name = scr_name:gsub('Move', '%0 '..insert)
			end
		scr_name = prefix..scr_name..'.lua'
		names_t[k] = scr_name -- store for installation in the Action list below
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			local new_script = io.open(path..scr_name, 'w') -- create new file
			new_script:write(content)
			new_script:close()
			end
		end
		
		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0} do -- Main // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end
		
	end

end


function Process_Mousewheel_Sensitivity(val, cmdID, MOUSEWHEEL_SENSITIVITY, percent)
-- val & cmdID stem from r.get_action_context()
-- MOUSEWHEEL_SENSITIVITY unit is one mousewheel nudge, normally a single scroll consists of 5-6 nudges
-- percent is boolean if the sensitivity is measured in pecentage rather than in mousewheel nudges count,
-- i.e. 1 = 100% (1 nudge), 0.5 = 50% (2 nudges), 0.3 = 30% (3 nudges), 0.25 = 25% (4 nudges), 0.2 = 20% (5 nudges) etc
-- the lower the less sensitive in contrast with nudges count
local MW_sens = MOUSEWHEEL_SENSITIVITY
MW_sens = MW_sens:gsub(' ','')
MW_sens = tonumber(MW_sens) and (percent and MW_sens+0 < 1 and math.abs(MW_sens+0)
or not percent and MW_sens+0 > 1 and math.floor(math.abs(MW_sens+0)))
MW_sens = MW_sens and (percent and 1/MW_sens or MW_sens) or 1
--MW_sens = MOUSEWHEEL and val == 63 and 1 or MW_sens -- if mousewheel and mousewheel sensitivity are enabled but the script is run via a shortcut (val returned by get_action_context() is 63), disable the mousewheel sensitivity otherwise if it's greater than 4 the script won't be triggered at the first run because the expected value will be at least 5x15 = 75 (val returned by get_action_context() is ±15) while val will only produce 63 per execution, it will only be triggered on the next run since 63x2 = 126 > 75
	if MW_sens == 1 then return true end -- no scaling
local cmdID = r.ReverseNamedCommandLookup(cmdID) -- command ID differs in different Action list sections
local data = r.GetExtState(cmdID, 'MOUSEWHEEL')
data = #data == 0 and 0 or data+0
local diff_sign = data > 0 and val < 0 or data < 0 and val > 0
local val = diff_sign and val or data+val -- when the stored and current vals have diff signs, reset to prevent values offsetting which results in higher sensitivity when scroll direction is reversed, e.g. when sensitivity is 10, if scroll direction after 5 changes, the script will be triggered after only 5 nudges (5-5=0) instead of 10
val = math.abs(val/MW_sens) >= 15 and 0 or val
r.SetExtState(cmdID, 'MOUSEWHEEL', val, false) -- persist false
return val == 0
end


local names_t = {'Move left edge to edit cursor', 'Move left edge to mouse cursor',
'Move right edge to edit cursor', 'Move right edge to mouse cursor',
-- if cursor is to the left of the AI start contents are moved left,
-- if it's to the right of the AI start contents are moved right
'Move contents to edit cursor', 'Move contents to mouse cursor',
-- if cursor is to the left of the AI start the AI is moved left,
-- if it's to the right of the AI start the AI is moved right
'Move to edit cursor preserving contents', 'Move to mouse cursor preserving contents', -- moving items without moving contents
'Move contents 10 ms left', 'Move contents 10 ms right',
'Move 10 ms left preserving contents', 'Move 10 ms right preserving contents', -- moving items without moving contents
'Trim left edge to edit cursor', 'Trim left edge to mouse cursor',
'Trim left edge to edit cursor and loop', 'Trim left edge to mouse cursor and loop', -- variant of the above if AI isn't looped
'Trim right edge to edit cursor', 'Trim right edge to mouse cursor',
'Trim right edge to edit cursor and loop', 'Trim right edge to mouse cursor and loop', -- variant of the above if AI isn't looped
'Stretch or shrink left edge to edit cursor', 'Stretch or shrink left edge to mouse cursor',
'Stretch or shrink right edge to edit cursor', 'Stretch or shrink right edge to mouse cursor',
-- MOUSEWHEEL
-- left edge is being processed when cursor is to the left of the AI start and mousewheel is in
-- or cursor is between the AI start and end and mousewheel out
-- right edge is being processed when cursor is to the right of the AI end and mousewheel is out
-- or cursor is between the AI start and end and mousewheel in
'Move edge to mouse cursor (mousewheel)', 'Trim edge to mouse cursor (mousewheel)',
'Stretch or shrink edge to mouse cursor (mousewheel)',
-- if cursor is to the left of the AI start and mousewheel in contents are moved left, mousewheel out is ignored
-- if it's to the right of the AI start and mousewheel out contents are moved right, mousewheel in is ignored
'Move contents to mouse cursor (mousewheel)',
-- if cursor is to the left of the AI start and mousewheel in the AI is moved left, mousewheel out is ignored
-- if it's to the right of the AI start and mousewheel out the AI is moved right, mousewheel in is ignored
'Move to mouse cursor preserving contents (mousewheel)',
-- the functionality doesn't depend on the mouse cursor position only on mouswheel direction
'Move contents 10 ms (mousewheel)', 'Move 10 ms preserving contents (mousewheel)'
}


local is_new_value, fullpath_init, sectionID, cmdID, mode, resolution, val = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, extension and author name


	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Move, trim, stretch or shrink'
	..' automation item and its contents_META', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not


local not_cursor = Invalid_Script_Name(scr_name, 'cursor')
local not_mousewheel = Invalid_Script_Name(scr_name, 'mousewheel')
local not_elm1 = Invalid_Script_Name(scr_name, 'left', 'right', 'contents')
local not_elm2 = Invalid_Script_Name(scr_name, 'move', 'trim', 'stretch or shrink')
local not_elm3 = Invalid_Script_Name(scr_name, 'mouse', 'edit')
-- scipts without use of cursors
local not_elm4 = Invalid_Script_Name(scr_name, 'left', 'right')
local not_elm5 = Invalid_Script_Name(scr_name, 'edge', 'contents')

	if not not_mousewheel and (not_elm2 or not_elm3 or not_elm5) or not_mousewheel
	and (not not_cursor and (not_elm1 or not_elm2 or not_elm3) or not_cursor and (not_elm4 or not_elm5)) then
	local br = '\n\n'
	local err = [[The script name has been changed]]..br..space(4)..[[which renders it inoperable.]]..br
	..space(5)..[[restore the original name]]..br..space(8)..[[referring to the list]]..br
	..'\t\t'..[[in the header.]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local env_sel = r.GetSelectedTrackEnvelope(0)
local sws = r.APIExists('BR_GetMouseCursorContext_Envelope')
local wnd, segm, details = table.unpack(sws and {r.BR_GetMouseCursorContext()} or {}) -- must come before BR_GetMouseCursorContext_Envelope() because it relies on it
local env, takeEnv = table.unpack(sws and {r.BR_GetMouseCursorContext_Envelope()} or {})
env = env or env_sel
local err = sws and (takeEnv and '    take envelopes don\'t \n\n support automation items' 
or not env and 'no track envelope under \n\n      mouse or selected') or not env and 'no selected track envelope'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


-- get index of the first selected AI on the envelope
local GetSetAI = r.GetSetAutomationItemInfo
local sel_AI_idx
	for AI_idx = 0, r.CountAutomationItems(env)-1 do
		if GetSetAI(env, AI_idx, 'D_UISEL', -1, false) > 0 -- selected; value -1, is_set false
		then
		sel_AI_idx = AI_idx
		break
		end
	end

	if not sel_AI_idx then
	Error_Tooltip('\n\n no selected automation item \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local name_elms_t = {'left', 'right', 'move', 'trim', 'stretch or shrink',
'mouse cursor', 'edit', 'loop', 'contents', 'preserving', 'mousewheel'}
local left, right, move, trim, stretch_shrink, mouse_cur, edit_cur, loop, cont, preserv, mousewheel = Parse_Script_Name(scr_name, name_elms_t)

	if mousewheel and val == 63 then
	-- 63 is the value returned by get_action_context() when mouse click is executed
	-- when mousewheel is moved it's either 15 or -15
	-- however this condition doesn't account for MIDI shortcuts which can also hit value 63
	-- but are suitable for running mousewheel scripts
	Error_Tooltip('\n\n\tthe script is meant \n\n to be run with mousewheel \n\n', 1, 1) -- caps, spaced true
	elseif mousewheel then
		if not Process_Mousewheel_Sensitivity(val, cmdID, MOUSEWHEEL_SENSITIVITY, 1) then return r.defer(no_undo) end
	end


local ms = scr_name:match('[%d%.]+') or 10 -- default to 10 ms in case no value in script name
local sec = ms/1000 -- convert to sec for use in functions

-- collect sel AI props
local AI_start = GetSetAI(env, sel_AI_idx, 'D_POSITION', -1, false)
local AI_len = GetSetAI(env, sel_AI_idx, 'D_LENGTH', -1, false)
local AI_playrate = GetSetAI(env, sel_AI_idx, 'D_PLAYRATE', -1, false) -- pool source playrate isn't preserved in the inserted pooled instance, it defaults to 1, therefore the source playrate needs to be retrieved from the source
local AI_startoffs = GetSetAI(env, sel_AI_idx, 'D_STARTOFFS', -1, false)
local AI_loop = GetSetAI(env, sel_AI_idx, 'D_LOOPSRC', -1, false) > 0
local AI_end = AI_start+AI_len
local x, y = r.GetMousePosition()
local edit_cur_pos_init, edit_cur_pos = r.GetCursorPosition() -- store

	if mouse_cur then
	r.PreventUIRefresh(1)
	r.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping)
	edit_cur_pos = r.GetCursorPosition()
	r.SetEditCurPos(edit_cur_pos_init, false, false) -- moveview, seekplay false // restore
	r.PreventUIRefresh(-1)
	end

edit_cur_pos = edit_cur_pos or edit_cur_pos_init -- depending on whether target is the mouse or edit cursor
local left_down, right_up = table.unpack(#MOUSEWHEEL_REVERSE:gsub(' ','') > 0 and {val > 0, val < 0} or {val < 0, val > 0})


-- left edge is being processed when cursor is to the left of the AI start and mousewheel is in
-- or cursor is between the AI start and its end and mousewheel out
-- unless the target is content in which case the functionality doesn't depend on the mouse cursor position
-- only on mousewheel direction
left = mousewheel and
(not cont and mouse_cur and (left_down and edit_cur_pos <= AI_start or right_up and edit_cur_pos > AI_start
and edit_cur_pos < AI_end) or (cont and mouse_cur and edit_cur_pos <= AI_start or not mouse_cur) and left_down)
or not mousewheel and left
-- right edge is being processed when cursor is to the right of the AI end and mousewheel is out
-- or cursor is between the AI start and its end and mousewheel in
-- unless the target is content in which case the functionality doesn't depend on the mouse cursor position
-- only on mousewheel direction
right = mousewheel and
(not cont and mouse_cur and (right_up and edit_cur_pos >= AI_end or left_down and edit_cur_pos < AI_end
and edit_cur_pos > AI_start) or (cont and mouse_cur and edit_cur_pos > AI_start or not mouse_cur) and right_up)
or not mousewheel and right

	if not move and (left and (edit_cur and edit_cur_pos_init > AI_end or mouse_cur and edit_cur_pos > AI_end)
	or right and (edit_cur and edit_cur_pos_init < AI_start or mouse_cur and edit_cur_pos < AI_start))
	then
	local cur = edit_cur and '  the edit' or 'the mouse'
	Error_Tooltip('\n\n '..cur..' cursor \n\n  is out of bounds \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

r.Undo_BeginBlock()

	if move then
		if cont then
			if preserv then
			-- Move to mouse/edit cursor preserving contents:
			-- if cursor is to the left of the AI start AI is moved left
			-- if it's to the right of the AI start AI is are moved right
			-- Move to mouse cursor preserving contents mousewheel:
			-- if cursor is to the left of the AI start AI is moved left on mousweheel in, mousewheel out is ignored
			-- if it's to the right of the AI start AI is moved right on mousweheel out, mousewheel in is ignored
			-- if cursor is at AI start no movement occurs, not aborting to mimic the behavior of the native
			-- 'Item edit: Move contents of item to edit cursor'
			-- whose undo point name is listed in the undo history readout but no actual undo point is created in this case
			-- Move 10 ms preserving contents (mousewheel)
			local val = not mouse_cur and not edit_cur and (left and sec*-1 or right and sec) -- or not_cursor instead of 'not mouse_cur and not edit_cur'
			or (not mousewheel and (mouse_cur or edit_cur) or mousewheel and (left or right))
			and edit_cur_pos-AI_start
			-- val can be false when mousewheel is to the left of AI start and scrolled out
			-- or to the right of AI start and scrolled in, this is by design
			-- or in reverse if mousewheel reverse is enabled
				if val then
				GetSetAI(env, sel_AI_idx, 'D_POSITION', AI_start+val, true) -- is_set true
				GetSetAI(env, sel_AI_idx, 'D_STARTOFFS', AI_startoffs+val*AI_playrate, true) -- is_set true
				end
			else
			-- Move contents to edit/mouse cursor:
			-- if cursor is to the left of the AI start contents are moved left
			-- if it's to the right of the AI start contents are moved right
			-- Move contents to mouse cursor mousewheel:
			-- if cursor is to the left of the AI start contents are moved left on mousweheel in, mousewheel out is ignored
			-- if it's to the right of the AI start contents are moved right on mousweheel out, mousewheel in is ignored
			-- if cursor is at AI start no movement occurs, not aborting to mimic the behavior of the native
			-- 'Item edit: Move contents of item to edit cursor'
			-- whose undo point name is listed in the undo history readout but no actual undo point is created in this case
			-- Move contents 10 ms (mousewheel)

			local val = not mouse_cur and not edit_cur and (left and sec or right and sec*-1) -- or not_cursor instead of 'not mouse_cur and not edit_cur'
			or (not mousewheel and (mouse_cur or edit_cur) or mousewheel and (left or right))
			and (AI_start-edit_cur_pos)*AI_playrate
			-- val can be false when mousewheel is to the left of AI start and scrolled out
			-- or to the right of AI start and scrolled in, this is by design
			-- or in reverse if mousewheel reverse is enabled
				if val then
				GetSetAI(env, sel_AI_idx, 'D_STARTOFFS', AI_startoffs+val, true) -- is_set true
				local loop = not AI_loop and loop and GetSetAI(env, sel_AI_idx, 'D_LOOPSRC', 1, true) -- is_set true
				end
			end
		else
		-- Move left/right edge to edit/mouse cursor
		-- Move left/right edge to mouse cursor mousweheel
		local val = left and edit_cur_pos or right and AI_start+(edit_cur_pos-AI_end)
		-- val can be false when mousewheel is to the left of AI start and scrolled out
		-- or to the right of AI start and scrolled in, this is by design
		-- or in reverse if mousewheel reverse is enabled
			if val then
				if right and val < 0 then -- the val is greater than the distance between AI start and project start
				Error_Tooltip('\n\n not enough space to move the AI \n\n', 1, 1) -- caps, spaced true
				else
				GetSetAI(env, sel_AI_idx, 'D_POSITION', val, true) -- is_set true
				end
			end
		end
	elseif trim then
	local parm, val = table.unpack(left and {'D_STARTOFFS', (edit_cur_pos-AI_start)*AI_playrate}
	or right and {'D_LENGTH', AI_len+(edit_cur_pos-AI_end)} or {})
	-- val can be nil when mousewheel is to the left of AI start and scrolled out
	-- or to the right of AI end and scrolled in, this is by design
	-- or in reverse if mousewheel reverse is enabled
		if val then
		local loop = not AI_loop and loop and GetSetAI(env, sel_AI_idx, 'D_LOOPSRC', 1, true) -- is_set true
			if right then
			GetSetAI(env, sel_AI_idx, parm, val, true) -- is_set true
			elseif left then
			GetSetAI(env, sel_AI_idx, parm, AI_startoffs+val, true) -- is_set true
			GetSetAI(env, sel_AI_idx, 'D_POSITION', edit_cur_pos, true) -- is_set true
			GetSetAI(env, sel_AI_idx, 'D_LENGTH', AI_len-(edit_cur_pos-AI_start), true) -- is_set true // minus because when trimming leftwards the diff is negative while it must be added to the orig length and vice versa
			end
		end
	elseif stretch_shrink then
	-- Stretch or shrink left/right edge to edit/mouse cursor
	-- Stretch or shrink left/right edge to mouse cursor mousewheel
	local dist = left and AI_start-edit_cur_pos or right and edit_cur_pos-AI_end
	-- dist can be false when mousewheel is to the left of AI start and scrolled out
	-- or to the right of AI end and scrolled in, this is by design
	-- or in reverse if mousewheel reverse is enabled
		if dist then
		local new_len = AI_len+dist
		local new_playrate = AI_playrate * (AI_len/new_len)
		GetSetAI(env, sel_AI_idx, 'D_PLAYRATE', new_playrate, true) -- is_set true
		GetSetAI(env, sel_AI_idx, 'D_LENGTH', new_len, true) -- is_set true
			if left then
			GetSetAI(env, sel_AI_idx, 'D_POSITION', edit_cur_pos, true) -- is_set true
			end
		end
	end


r.Undo_EndBlock(scr_name, -1)



