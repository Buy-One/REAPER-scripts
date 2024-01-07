--[[
ReaScript name: BuyOne_(Re)Store Razor edit areas slots #1-5_META.lua (10 scripts)
Author: BuyOne
Version: 1.1
Changelog: v1.1 #Added REAPER version check
		#Corrected minimal supported version in the header
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v6.54
Metapackage: true
Provides: 	[main] . > BuyOne_Store Razor edit areas slot 1.lua
		[main] . > BuyOne_Store Razor edit areas slot 2.lua
		[main] . > BuyOne_Store Razor edit areas slot 3.lua
		[main] . > BuyOne_Store Razor edit areas slot 4.lua
		[main] . > BuyOne_Store Razor edit areas slot 5.lua
		[main] . > BuyOne_Restore Razor edit areas slot 1.lua
		[main] . > BuyOne_Restore Razor edit areas slot 2.lua
		[main] . > BuyOne_Restore Razor edit areas slot 3.lua
		[main] . > BuyOne_Restore Razor edit areas slot 4.lua
		[main] . > BuyOne_Restore Razor edit areas slot 5.lua
About:	If this script name is suffixed with META it will spawn 
    		all individual scripts included in the package into 
    		the directory supplied by the user in a dialogue.
    		These can then be manually imported into the Action list 
    		from any other location. If there's no META suffix 
    		in this script name it will perfom the operation indicated 
    		in its name.
    		
    		If more store/restore slots are needed, duplicate any two
    		of the complementing individual scripts and increase the slot 
    		number in their names so it's greater than the currently 
    		available maximum number.

]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function no_undo()
do return end
end


function META_Spawn_Scripts(fullpath, scr_name, names_t)

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

		if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)

	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD

	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local user_path = Dir_Exists(output) -- validate user supplied path
		if not user_path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(user_path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
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


function Re_Store_Razor_Edit_Areas(store, restore, slot)
-- store, restore is boolean, slot is string

local sect = '(Re)Store Razor edit areas'
local slot = 'SLOT'..slot
local tr_cnt = r.CountTracks(0)
	
	if store then
	
	local data = ''
		for i=0, tr_cnt-1 do
		local tr = r.GetTrack(0,i)
		local retval, raz_edit = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS_EXT', '', false) -- setNewValue false
		-- retval is always true as long as the param name is correct so unreliable
			if #raz_edit > 0 then
			data = data..tostring(tr)..':'..raz_edit..';'
			end
		end
		if #data == 0 then
		Error_Tooltip('\n\n no razor edit areas to store \n\n', 1, 1) -- caps, spaced true
		return end
	r.SetExtState(sect, slot, data, false) -- persist false
	
	elseif restore then
	
	local data = r.GetExtState(sect, slot)
		if #data == 0 then
		Error_Tooltip('\n\n no stored razor edit \n\n    areas in the slot \n\n', 1, 1) -- caps, spaced true
		end
	local t = {}
		for data in data:gmatch('(.-);') do
			if #data > 0 then
			local tr, raz_edits = data:match('(.+):'), data:match('.+:(.+)')
			t[tr] = raz_edits
			end
		end
		for i=0, tr_cnt-1 do
		local tr = r.GetTrack(0,i)
			if t[tostring(tr)] then
			r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS_EXT', t[tostring(tr)], true) -- setNewValue true
			end
		end

	end
	
end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.54 then
	-- in 6.54 'P_RAZOREDITS_EXT' parm was added to GetSetMediaTrackInfo_String() 
	Error_Tooltip('\n\n\tthe script is supported \n\n in REAPER builds 6.54 onwards \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, fullpath, sectionID, cmdID, mode, resolution, val = r.get_action_context()
local scr_name = fullpath:match('.+[\\/].-_(.+)%.%w+') -- without path, extension and author name

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, 'BuyOne_(Re)Store Razor edit areas slots #1-5_META.lua', names_t)
	then return r.defer(no_undo) end -- abort if META script but continue if not


--scr_name = 'Store Razor edit areas slot 2' ----------- NAME TESTING

local store, restore = scr_name:match('Store'), scr_name:match('Restore')
local slot = scr_name:match('slot (%d+)')

	if (not restore and not store) or not slot or not scr_name:match('Razor edit area') then
	local br = '\n\n'
	local err = [[The script name has been changed]]..br..space(4)..[[which renders it inoperable.]]..br
	..space(5)..[[restore the original name]]..br..space(8)..[[referring to the list]]..br
	..'\t\t'..[[in the header.]]
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


Re_Store_Razor_Edit_Areas(store, restore, slot)

do return r.defer(no_undo) end




