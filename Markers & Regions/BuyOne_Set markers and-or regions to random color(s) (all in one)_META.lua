--[[
ReaScript name: BuyOne_Set markers and-or regions to random color(s) (all in one)_META.lua (7 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.3
Changelog:  v1.3 #Fixed individual script installation function
		 #Made individual script installation function more efficient  
	    v1.2 #Fixed compatibility with installer script
	    v1.1 #The script has been in large part rewritten to work more robustly	
		 #The META instance now contains all options and can work by itself
		 #The menu is auto-reloaded after mouse click
		 #Added functionality of automatic creation and installation of
		 individual scripts. These are created in the directory the META script 
		 is located in and from there are imported into the Action list.
		 #Updated About text
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides: [main=main,midi_editor] .
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers and-or regions to random color(s) (all in one)_META.lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers to random colors (respecting time sel.).lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers to 1 random color (respecting time sel.).lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set regions to random colors (respecting time sel.).lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set regions to 1 random color (respecting time sel.).lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers + regions to random colors (respecting time sel.).lua
	  [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers + regions to 1 random color (respecting time sel.).lua
About: 	Sets project markers and/or regions to random colors obeying time selection, if any.
	The script comes in 7 instances, 1 includes all available options as a menu and the 
	other 6 specialize in one type of operation only, being suitable to be included 
	in custom actions.  

	If this script name is suffixed with META, when executed it will automatically spawn 
	all individual scripts included in the package into the directory of the META script 
	and will import them into the Action list from that directory. It will also display
	a menu with all available options as menu items which can be run with a numeric
	keyboard shortcut corresponding to the number of such menu item.	
	If there's no META suffix in this script name it will perfom only the operation 
	indicated in its name.
   
	In the script 'BuyOne_Set markers and-or regions to random color(s) (all in one)_META' 
	which contains all available options in a menu, a menu item can be run with a numeric
	keyboard shortcut corresponding to the number of such menu item.	 

Other available scripts with some or all functionalities of this one:  
X-Raym_Color current region or regions in time selection randomly with same color.lua  
X-Raym_Color current region or regions in time selection randomly.lua  
zaibuyidao_Random Marker Color.lua  
zaibuyidao_Random Marker Region Color.lua  
zaibuyidao_Random Region Color.lua

]]



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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

	if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts but allow their execution to continue

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

--[[ GETTING PATH FROM THE USER INPUT

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

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		-- spawn scripts
		for k, scr_name in ipairs(names_t) do	
		local new_script = io.open(path..scr_name, 'w') -- create new file
		content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
		new_script:write(content)
		new_script:close()
		end

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
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


function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
-- keep_menu_open is boolean
-- left_edge_dist is integer to only display the menu
-- when the mouse cursor is within the sepecified distance in px from the screen left edge
-- only useful for looking up the result of a toggle action, below see a more practical example

left_edge_dist = left_edge_dist and left_edge_dist > 0 and math.floor(left_edge_dist)
local x, y = r.GetMousePosition()

	if left_edge_dist and x <= left_edge_dist or not left_edge_dist then -- 100 px within the screen left edge
	-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
	-- https://forum.cockos.com/showthread.php?t=280658#25
	-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
	-- BUT LACK OF gfx WINDOW DOESN'T ALLOW RE-OPENING THE MENU AT THE SAME POSITION via ::RELOAD::
	-- therefore enabled with keep_menu_open is valid
	local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
	local init = (old or not old and keep_menu_open) and gfx.init('', 0, 0)
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


function RANDOM_RGB_COLOR()
math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count

local RGB = {r = 0, g = 0, b = 0}
	for k in pairs(RGB) do -- adds randomization (i think) thanks to pairs which traverses in no particular order // once it picks up a particular order it keeps at it throughout the entire main repeat loop when multiple colors are being set
	RGB[k] = math.random(1,256)-1 -- seems to produce 2 digit numbers more often than (0,255), but could be my imagination
	end

return RGB

end



::RELOAD::

local _, fullpath_init, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath:match('([^\\/_]+)%.%w+') -- sans path, scripter name and extension
local all_in_one = scr_name:match('%(all in one%)')


META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Set markers and-or regions to random color(s) (all in one)_META.lua', names_t)

	if all_in_one then

	menu = {'&1: Set MARKERS to random colors','||&2: Set MARKERS to 1 random color','||&3: Set REGIONS to random colors','||&4: Set REGIONS to 1 random color','||&5: Set markers + regions to random colors','||&6: Set markers + regions to 1 random color','||#            TIME SELECTION IS RESPECTED|#       IF NO MARKER OR REGION IS WITHIN|#TIME SELECTION — A MESSAGE IS GENERATED'} -- to be used for undo point naming as well
	output = Reload_Menu_at_Same_Pos(table.concat(menu), 1) -- keep_menu_open true

	else

	-------------- FOR INDIVIDUAL SCRIPTS ---------------
	scr_name = scr_name:match('(.+) %(res')
	menu = {['Set markers to random colors'] = 1, ['Set markers to 1 random color'] = 2, ['Set regions to random colors'] = 3, ['Set regions to 1 random color'] = 4, ['Set markers + regions to random colors'] = 5, ['Set markers + regions to 1 random color'] = 6}
	output = menu[scr_name]
	-----------------------------------------------------

	end


local retval, mrkr_cnt, rgn_cnt = r.CountProjectMarkers(0)
local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = start ~= fin

	if not output or output == 0 then return r.defer(no_undo) -- only relevant for 'all in one' version // output is nil when the script is executed via dofile() from the installer script

	else

	local RGB = RANDOM_RGB_COLOR()
	local both = output == 5 or output == 6

	-- If objects tergeted by selected option don't exist in the project; presence in time selection is evaluated further below
		if not time_sel then
		obj = both and mrkr_cnt+rgn_cnt == 0 and 'markers or regions'
		or not both and (output < 3 and mrkr_cnt == 0 and 'markers' or output > 2 and rgn_cnt == 0 and 'regions')
			if obj then -- non of the targeted objects is found in the project
			local space = not obj:match(' or ') and '' or (' '):rep(8)
			Error_Tooltip('\n\n there\'re no '..obj..' \n\n'..space..'     in the project \n\n ', 1, 1, -500) -- caps, spaced true, x2 -500 to shift the tooltip far from the menu otherwise when it's reloaded it will cover it
				if all_in_one then goto RELOAD
				else return r.defer(no_undo)
				end
			end

		obj = both and (mrkr_cnt == 0 and 'markers' or rgn_cnt == 0 and 'regions')
			if obj then
			Error_Tooltip('\n\n there\'re no '..obj..' \n\n     in the project \n\n ', 1, 1, -500) -- caps, spaced true, x2 -500 to shift the tooltip far from the menu otherwise when it's reloaded it will cover it
			end
		end


	r.Undo_BeginBlock()

	local i = 0
	-- count markers and regions within time selection
	local mrkr_cnt = 0
	local rgn_cnt = 0
		repeat
		local retval, isrgn, pos, rgnend, name, markrgnidx, color = r.EnumProjectMarkers3(0, i)
		local mrkr_cond = not isrgn and (output == 1 or output == 2 or both) and (not time_sel or time_sel and pos >= start and pos <= fin)
		local rgn_cond = isrgn and (output == 3 or output == 4 or both) and (not time_sel or time_sel and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin))
			if mrkr_cond or rgn_cond then
			-- count markers/regions within time selection when it's there to generate an alert message or tooltip below
			mrkr_cnt = mrkr_cond and mrkr_cnt + 1 or mrkr_cnt
			rgn_cnt = rgn_cond and rgn_cnt + 1 or rgn_cnt
			local time = r.time_precise()
				repeat -- gives the API time to process the following expression, otherwise one color ends up being applied regardless of the selected option // the version of the routine below isn't affected by this problem probably because there one loop cycle runs longer which is enough for the API
				until r.time_precise() - time >= .002
			RGB = output%2 == 0 and RGB or RANDOM_RGB_COLOR() -- one color or many
			r.SetProjectMarker3(0, markrgnidx, isrgn, pos, rgnend, '', r.ColorToNative(RGB.r,RGB.g,RGB.b)|0x1000000) -- isrgn as rgn_cond which is true or false
			end
		i = i+1
		until time_sel and pos > fin or retval == 0

		if time_sel then

		obj = both and mrkr_cnt+rgn_cnt == 0 and 'markers or regions' or not both and (output < 3 and mrkr_cnt == 0 and 'markers' or output > 2 and rgn_cnt == 0 and 'regions')

			if obj then -- if none of the targeted objects is found within time selection
			local space = not obj:match(' or ') and '' or (' '):rep(8)
			Error_Tooltip('\n\n there\'re no '..obj..' \n\n'..space..'   in time selection \n\n ', 1, 1, -500) -- caps, spaced true, x2 -500 to shift the tooltip far from the menu otherwise when it's reloaded it will cover it
			r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- this is meant to prevent display of the generic 'ReaScript: Run' message in the Undo readout which is generated because this message follows Undo_BeginBlock(), done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
			-- technically the evaluation could have been done before Undo_BeginBlock() and the main loop but that's a bit of a hassle
				if all_in_one then goto RELOAD
				else return r.defer(no_undo)
				end
			end

		obj = both and (mrkr_cnt == 0 and 'markers' or rgn_cnt == 0 and 'regions')

			if obj then -- if both objects are targeted and one of them isn't found within time selection
			Error_Tooltip('\n\n there\'re no '..obj..' \n\n   in time selection \n\n ', 1, 1, -500) -- caps, spaced true, x2 -500 to shift the tooltip far from the menu otherwise when it's reloaded it will cover it
			end

		end

	local undo = menu[output] and menu[output]:match('Set.+')..(time_sel and ' in time selection' or '') or scr_name -- excluding menu numbers and separators
	undo = both and (obj == 'markers' and undo:gsub(obj..' %+ ', '') or obj == 'regions' and undo:gsub(' %+ '..obj, '')) or undo -- exclude from undo point name mention of the object absent in project or time selection

	r.Undo_EndBlock(undo, -1)

	end

	if all_in_one then goto RELOAD end







