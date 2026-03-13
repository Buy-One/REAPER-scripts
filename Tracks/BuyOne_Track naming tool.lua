--[[
ReaScript name: BuyOne_Track naming tool.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script was inspied by DiGiCo Digital Mixing Console
		Channel Name utility
		https://www.digico.org/DiGiCo_Manuals/SD_Software_Reference_V2.pdf#page=10
		OR  
		https://digico.biz/wp-content/uploads/2022/03/SD-Quantum-Software-Reference-Issue-E-V1528.pdf#page=15
        AND
		https://youtu.be/v0R1jz2v2Us?t=179
		
		and is designed to facilitate quick labeling of tracks with
		predefined labels.

		Labels are applied to selected tracks or to a newly 
		inserted track via clicking a label in the categories menu.


		T H E  S E T T I N G S

		1. Replace label
		2. Add label
			a. prepend
			b. append

		Settings 1 and 2 are mutually exclusive. Options a. and b.
		of the setting 2. determine where the added label is placed
		relative to the current track label. When settin 1 is enabled
		they're grayed out.

		3. Define initial numeral for auto-enumeration 
		in multi-track selection:
			a. prepend to label
			b. append to label

		Setting 3 allows defining initial numeral of numeric sequence
		to be applied to a track label in multi-track selection. To define 
		one, click the menu item to call a dialogue. To clear a defined 
		numeral submit empty dialogue. If no numeral is defined the setting 
		is ignored, options a. and b. are grayed out. It's also ignored 
		when a numeral from default DIGITS category is applied.
		Options a. and b. determine where the numeral is added to the
		original track label. The options are toggles and mutually 
		exclusive when at least one of them is enabled, i.e. both can be
		disabled to turn the Initial numeral setting off without having
		to remove the actual numeral.  
		If this setting isn't used, enumeration will have to be done after 
		label from the categories menu is applied, i.e. in two steps, first 
		apply label, then apply number from DIGITS category.


		Settings 1, 2 and 3 are ignored when brackets are applied from 
		default SEPARATORS / BRACKETS category, because brackets are 
		applied around the current track label.


		4. Change DIGITS order of magnitude: 1

		The setting is cyclic where repeated clicks change order of 
		magnitude of numbers included in the default DIGITS category
		from 1 to 100, except 0, and allow applynig numeric sequences 
		above 9 to multi-track selections.

		5. Capitalize

		When enabled, labels are applied to tracks in all caps. The 
		register of actual labels in the menu however doesn;t change.

		6. Create new track with label

		When enabled, track selection is ignored, settings 1-3 get grayed 
		out as irrelevant. New track is created in response to clicking 
		a label in the menu.

		7. Edit lists

		The setting changes the script mode of operation from applying
		labels to their editing. When enabled, settings 1-6,8-10 are 
		grayed out and clicking a label in the category menu calls a 
		dialogue where the label can be modified and new labels can be 
		added. For label list formatting rules see the descripton of 
		CATEGORIES setting in the USER SETTINGS below. To remove a 
		clicked label submit the dialogue empty. Be aware that labels
		containing commas, if any, in the editor are wrapped in
		quoation marks as required by the label list formatting rules
		so when submitted back to the menu they're treated as a single 
		label rather than as several comma separated ones.  
		Submitting the dialogue, results in updating the category list 
		in the CATEGORIES setting within the script.  
		Only user categories defined in the CATEGORIES setting are 
		editable so if that setting is empty or otherwise unreadable,
		in which case default categories are loaded, '7. Edit lists'
		menu item is grayed out.


		8. Store settings as default

		Allows storing current settings as script default to be used
		for every new project.
		When settings current state is identical to defaults the menu
		item is grayed out.


		9. Reset to defaults

		Script defaults are:
		Setting 1 is enabled 
		Option b. of Setting 2 is enabled
		Setting 4 value is 1
		The settings are listed in the main menu

		If you stored your own defaults with option 8 above, that's what
		the settings will be reset to.  
		When settings current state is identical to defaults the menu
		item is grayed out.


		10. Undo

		Undo only works for undo points created by the script and the 
		menu item is grayed out when the latest undo point wasn't created 
		by it.

		MOVE SETTINGS TO SUBMENU

		The option allows moving settings 1-9 into a submenu so that
		there's more space for label categories on the screen.


		The script stores the state of settings 
		1, 2(a, b), 3(a,b), 4, 5, 6 during session and in between
		project sessions.		

		Categories DIGITS, CHANNELS and SEPARATORS / BRACKETS are
		fixed and available regardless of presence of user defined 
		label categories.

		Use CATEGORIES setting in the USER SETTINGS below to define 
		custom track label categories.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the double square brackets below
-- type in your label category titles and comma delimited
-- label lists;
-- if a category only contains a single label it doesn't
-- have to be followed by a comma;
-- multi-word labels which contain commas must be enclosed
-- within quotation marks to disambiguate their commas from
-- commas used as labels delimiter in the list;
-- enclosing within quotes multi-word labels which don't
-- contain commas will result in the quoation marks being
-- included in the label in the menu;
-- if you wish to enclose within quotes labels which do
-- contain commas, simply enclose the label within those
-- along with quotes indicating a comma delimited label,
-- e.g. ""label1, label2"", the external instances of the
-- quotation mark will indicate to the script a label which
-- contains commas while the internal ones will be included
-- in the label itself;
-- THE FORMAT IS AS FOLLOWS:
--[[
Category
label, label, "label1, label2" , label, label
--]]
-- i.e. every 1st line is a category title, every 2nd line
-- is a label list (all labels must occupy a single line);
-- presence of spaces around category title and labels,
-- the length of such spaces, presence of empty lines
-- are immaterial;
-- pipe character | isn't supported because it's a menu
-- formatting operator, it will be auto-replaced by a similar
-- character; if a label starts with any other menu formatting
-- operator, i.e. <, >, ! or #, the menu item is shifted
-- in the menu by a single space to prevent these characters
-- from affecting the menu display;
-- if this setting is empty or only contains a single line
-- of text, script default categories will be used

CATEGORIES = [=[

YOUR CATEGORIES GO HERE

]=]

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


function space(n) -- number of repeats, integer
local n = n and tonumber(n) and math.abs(math.floor(n)) or 0
return (' '):rep(n)
end


function spaceout(str)
return str:gsub('.', '%0 '):match('(.+) ') -- space out text, trimming trailing space
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist) -- used in Menu_With_Toggle_Options()
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



function esc_menu_ops(str) -- used in parse_categories() and Menu_With_Toggle_Options()
	for k, op in ipairs({'!','#','>','<','|', '\226\157\152'}) do
		if str:match('^%s*|') or str:match('^%s*'..'\226\157\152') then -- if pipe (Vetcial Line (U+007C) '\124') or Light Vertical Bar (U+2758) '\226\157\152' which is interpreted by REAPER as pipe, replace with Full Width Vertical Line (U+FF5C) '\239\189\156', OR can be replaced with Box Drawings Light Vertical (U+2502) '\226\148\132' or with Hangul character for /i/ (U+3163) '\227\133\163'
		str = str:gsub('[|\226\157\152]', '\239\189\156', 1)
		elseif str:sub(1,1) == op then
		str = '\r'..str -- when operator other than pipe is preceeded by space or any other character it's ignored by gfx library, so if it's not the very first character in the string it doesn't need fixing
		end
	end
return str
end



function parse_categories(categories) -- used inside Menu_With_Toggle_Options()

local t, cat, cat_title = {}

	for line in categories:gmatch('[^\n]+') do
		if line and #line:match('%S') then -- ignoring empty lines
			if not cat then -- store category title
			cat = 1
			local line = line:match('%S.*%S') or line:match('%S') -- strip leading/trailing space // * operator instead of + to account for strings consisting of 2 characters only which are already covered by two %S operators // the alternative is meant to account for strings constisting of a single character on which first match will produce nil
			cat_title = line
			table.insert(t, '|>'..esc_menu_ops(line))
			elseif cat then -- category items line, category title line has already been parsed and stored above
			cat = nil -- reset for the next category loop cycle
				if line:sub(1,1) == ',' then line = line:sub(2) end -- remove leading comma
				if line:sub(-1) ~= ',' then line = line..','	end
				-- parse items comma separated list
				-- items which themselves include commas must be enclosed within
				-- quotes, in which case they're reconstructed because
				-- using alternative capture patterns in gmatch is difficult
				-- and unreliable
			local temp
				for item in line:gmatch('(.-),') do -- OR '[^,]+'
					if item:match('%S') then
					local closing_quote = item:match('"%s*$')
					quote_item = item:match('(%S.-)%s*$') -- stripping leading/trailing space
						if temp then
							if closing_quote then -- closing quotes
							table.insert(t, '|'..temp..','..item:match('(.+%S)"')) -- dump to table stripping off quotation mark and removing trailing space
							temp = nil -- reset
							else
							temp = temp..','..item -- keep collecting until closing quotes come along
							end
						elseif item:match('^%s*"') and not closing_quote then -- opening quote but not closing, i.e. there're commas inside the label
						temp = esc_menu_ops(item:match('"(%S.+)')) -- store stripping off quotation mark and removing leading space
						else -- capture not enclosed within quotes
						item = item:match('%S.*%S') or item:match('%S') -- strip leading/trailing space // * operator instead of + to account for strings consisting of 2 characters only which are already covered by two %S operators // the alternative is meant to account for strings constisting of a single character on which first match will produce nil
						table.insert(t, '|'..esc_menu_ops(item))
						end
					end
				end

				if temp then -- temp wasn't reset, i.e. the label list wasn't stored
				local s = space(4)
				Error_Tooltip('\n\n  THERE\'S NON-PAIRED \n\n'..s..'QUOTATION MARK \n\n'
				..s..'IN LABEL '..quote_item..' \n\n'..s..'IN THE CATEGORY \n\n "'..cat_title..'" \n\n', nil, 1) -- caps nil, spaced true
				return
				end
			t[#t] = t[#t]:gsub('|','|<') -- close submenu
			end
		end
	end
return t
end



function process_init_numeral(init_numeral) -- used inside Menu_With_Toggle_Options()
local ret, num
::RETRY::
Error_Tooltip('') -- clear tooltip
local input = num or init_numeral or ''
ret, num = 
r.GetUserInputs('INITIAL NUMERAL OR EMPTY', 1, 'Type in or clear integer number,extrawidth=50,separator=\n', input) -- using new line as separator in order to ensure correct display of decimal numbers with comma as decimal separator rather than dot which are invalid as numbers but comma, being default GetUserInputs separator after reload makes GetUserInputs treat them as input for two fields and since there's one field only in the function settings the part which follows comma gets lost
num = num:gsub('%s+','')
	if ret then
		if num:match('%S') then -- OR #num > 0 because all spaces were cleared with gsub
		local err = 'the input is not '
		err = not tonumber(num) and err..'a number' or num+0 ~= math.floor(num+0) and err..'an integer'
			if err then
			Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
			pause(2)
			goto RETRY
			else
			init_numeral = num
			end
		else -- empty to clear
		init_numeral = num
		end
	end
return init_numeral
end


function calc_user_cat_label_index(output, menu_len, cat_t) -- used in Menu_With_Toggle_Options()
-- output is the clicked menu item index

-- first calculate index based on the menu
-- i.e. with no regard to category title entries
-- contained in cat_t
local idx = output-menu_len

-- increment idx with each found category title entry
-- inside cat_t which precede the entry at idx in the table
-- to offset idx value in order to obtain index relevant for cat_t
-- i.e. accounting for category title entries
local i, cat = 1
	repeat
		if cat_t[i]:match('|>') then -- category title menu formatting operators
		cat = cat_t[i]:gsub('|>','',1)
		idx = idx+1
		end
	i=i+1
	until i > idx

return idx, cat

end


function process_label_edit(line, cat_title) -- used in Menu_With_Toggle_Options()
-- line is GetUserInputs() output
-- cat_title stems from calc_user_cat_label_index()

local t = {}

	if line:sub(1,1) == ',' then line = line:sub(2) end -- remove leading comma
	-- add trailing comma to simplify capture of the last item
	-- if '(.-),' pattern is used in gmatch below to parse menu items
	if line:sub(-1) ~= ',' then line = line..','	end

-- parse items comma separated list
-- items which themselves include commas must be enclosed within
-- quotes, in which case they're reconstructed because
-- using alternative capture patterns in gmatch is difficult
-- and unreliable
local temp
	for item in line:gmatch('(.-),') do -- OR '[^,]+'
		if item:match('%S') then
		local closing_quote = item:match('"%s*$')
		quote_item = item:match('(%S.-)%s*$') -- stripping leading/trailing space
			if temp then
				if closing_quote then -- closing quotes
				table.insert(t, temp..','..item:match('(.+%S)"')) -- dump to table stripping off quotation mark and removing trailing space
				temp = nil -- reset
				else
				temp = temp..','..item -- keep collecting until closing quotes come along
				end
			elseif item:match('^%s*"') and not closing_quote then -- opening quote but not closing, i.e. there're commas inside the label
			temp = esc_menu_ops(item:match('"(%S.+)')) -- store stripping off quotation mark and removing leading space
			else -- capture not enclosed within quotes
			item = item:match('%S.*%S') or item:match('%S') -- strip leading/trailing space // * operator instead of + to account for strings consisting of 2 characters only which are already covered by two %S operators // the alternative is meant to account for strings constisting of a single character on which first match will produce nil
			table.insert(t, esc_menu_ops(item))
			end
		end
	end
	if temp then -- temp wasn't reset, i.e. the label list wasn't stored
	local s = space(4)
	Error_Tooltip('\n\n  THERE\'S NON-PAIRED \n\n'..s..'QUOTATION MARK \n\n'
	..s..'IN LABEL '..quote_item..' \n\n'..s..'IN THE CATEGORY \n\n "'..cat_title..'" \n\n', nil, 1) -- caps nil, spaced true
	pause(2.5)
	return
	end
return t
end



function update_script_data(cats_t) -- used in Menu_With_Toggle_Options()

local is_new_value, scr_path, sectID, cmdID, mode, resol, val, contextstr = r.get_action_context()

local data, found

	for line in io.lines(scr_path) do
		if line:match('CATEGORIES%s*=%s*%[=%[') then
		found = 1
		elseif found then
		local closure = line:match('^%]=%]')
			if line:match('%S') and not closure then -- continue collecting lines
			data = (data and data..'\n' or '')..line
			elseif closure then
			break
			end
		end
	end

local count, cats = 0

	for k, label in ipairs(cats_t) do
	local title = label:match('|>')
	count = (title or count == 1) and count+1 or count -- only increment when title and first category label have been detected
	label = label:match('|+[><]?\r?(.+)') -- removing menu formatting // '|+' accounts for double pipe if added to separate edited/newly added label in the reloaded menu
	label = label:match(',') and '"'..label..'"' or label -- enclose within quotes labels containing commans
	cats = (cats and cats or '')..(title and (cats and '\n' or '') or count == 2 and '' or ', ')..label..(title and '\n' or '') --  only preceding with new line a category title which isn't the very first; count == 2 once first label after title comes along which doesn't need to be preceded with a comma
	count = count == 2 and 0 or count -- once first category label has been detected (count == 2) reset it so that the label list is correctly formatted above
	end

local cats = cats:gsub('%%','%%%%') -- escape % just in case

local f = io.open(scr_path,'r')
local cont = f:read('*a')
f:close()
data = Esc(data)
cont = cont:gsub(data, cats, 1)
local f = io.open(scr_path,'w')
f:write(cont)
f:close()

return true

end


function store_settings_as_default(settings) -- used in Menu_With_Toggle_Options()

local is_new_value, scr_path, sectID, cmdID, mode, resol, val, contextstr = r.get_action_context()

--[[
local bytecode
--	for char in ('local DEFAULT_SETTINGS'):gmatch('.') do
--	bytecode = (bytecode and bytecode..' ' or '')..char:byte()
	for char in ('108 111 99 97 108 32 68 69 70 65 85 76 84 95 83 69 84 84 73 78 71 83'):gmatch('%d+') do
	bytecode = (bytecode or '')..string.char(char)
	end
do return end
--]]

-- reverse so that the string isn't captured
-- by gsub below, because it precedes the actual setting line
-- within the file;
-- alternative way of preventing that is using the string
-- bytecode listed above, in the format '\108\111\99\97\108\32 etc.'
local sett = 'SGNITTES_TLUAFED lacol'

local f = io.open(scr_path,'r')
local cont = f:read('*a')
f:close()
cont = cont:gsub(sett:reverse()..' = ".-"', sett:reverse()..' = "'..settings..'"', 1)
local f = io.open(scr_path,'w')
f:write(cont)
f:close()

end




function Menu_With_Toggle_Options(scr_cmd_ID, CATEGORIES, default_cats, DEFAULT_SETTINGS)
-- stores enabled settings as a bitfield
-- rather than as a literal base 2 value;
-- scr_cmd_ID comes from get_action_context();
-- relies on Reload_Menu_at_Same_Pos() function

Error_Tooltip('') -- clear tooltips

local KEY, user_categ_t, DEFAULT_SETTINGS_temp = 'TRACK NAMING TOOL SETTINGS'

::RELOAD::

-- DEFAULT_SETTINGS_temp is assigned latest settings
-- after storing them to this script with menu item
-- '8. Store settings as default' to be able to gray
-- out this menu item when current and stored settings
-- become identical, because due to menu reload loop
-- and Menu_With_Toggle_Options() functon being located
-- downstream of the DEFAULT_SETTINGS var initialization
-- in the main routine the main var isn't updated with
-- the latest data;
-- a more reliable way of doing this would be after storing
-- the setting to exit this function before goto RELOAD
-- statement and initiate a goto loop in the main routine
-- restarting it just before DEFAULT_SETTINGS var which at
-- that stage would be updated, but this way is pretty twisted
-- due to many hoops
DEFAULT_SETTINGS = DEFAULT_SETTINGS_temp or DEFAULT_SETTINGS
local settings = r.GetExtState(scr_cmd_ID, KEY)
local ret
	if #settings == 0 then -- first use after project load or project creation
	ret, settings = r.GetProjExtState(0, scr_cmd_ID, KEY)
	settings = ret == 1 and settings or DEFAULT_SETTINGS
	end

local bitfield, init_numeral, order_of_magn, collapse_sett = settings:match('^(.-);(.-);(.-);(.-)$')
-- default bitfield format is as follows
-- 1|2|4|8|16 etc., i.e. all 5 options are On by default,
-- 1|4 - options 1 and 3 are On by defaullt,
-- 2|8|16 - options 2,4 and 5 are On by default
bitfield = bitfield and bitfield+0 or 1|2 -- if not set use default
init_numeral = init_numeral or ''
order_of_magn = tonumber(order_of_magn) or 1
collapse_sett = collapse_sett or '0'
local repl, create_new_tr = bitfield&1 == 1, bitfield&32 == 32
-- declare all possible undo point names here
-- to gray out '10. Undo' menu item when it cannot be used
local undo = create_new_tr and 'Create new track with label' or repl and 'Replace track labels' or 'Add track labels'
local gray_undo = r.Undo_CanUndo2(0) ~= undo and '#' or ''

local s = space(4)

-- POPULATE WITH NAMES OF TOGGLE SETTINGS AS THEY APPEAR IN THE MENU
local sett_t = sett_t
or {'1. Replace label', -- &1
s..'b. append', -- &2
s..'a. prepend to label', -- &4
s..'b. append to label', -- &8
'5. Capitalize', -- &16
'6. Create new track with label', -- &32
(default_cats and '#' or '')..'7. Edit lists'} -- &64 // gray out when default categories are used

-- associate indices of boolean settings from sett_t
-- with menu_t indices of their mutually exclusive counterparts
-- i.e. 1 (Replace label) with menu index 2 (Add label),
-- 2 (b. append) with menu index 3 (a. prepend) etc.
local excl_sett_t = {[2]=1,[3]=2}--,[7]=3} -- 7 because item '3. Define initial..' takes up two menu places, so 'b. append to label' index is 7 after offsetting menu output by -1 below

local act_state = settings == DEFAULT_SETTINGS and '#' or ''

local menu_t = menu_t
or {sett_t[1]..'|', -- '1. Replace label'
'2. Add label|',
s..'a. prepend|',
sett_t[2]..'||', -- 'b. append'
'3. Define initial numeral for auto-enumeration|    in multi-track selection:  '..init_numeral..'|',
sett_t[3]..'|', -- 'a. prepend to label'
sett_t[4]..'||', -- 'b. append to label'
'4. Change DIGITS order of magnitude: '..order_of_magn..'||',
sett_t[5]..'||', -- '5. Capitalize'
sett_t[6]..'||', -- '6. Create new track with label'
sett_t[7]..'||', -- '7. Edit lists'
act_state..'8. Store settings as default||', -- gray out when defaults are active
act_state..'9. Reset settings to defaults||', -- gray out when defaults are active
gray_undo..'10. Undo||',
'MOVE SETTINGS TO SUBMENU|||',
'>DIGITS|',
'>CHANNELS|',
'>SEPARATORS / BRACKETS|'
}
-- associate indices of boolean settings from sett_t with menu_t indices or ranges or non-contiguous sequences
-- of items which should be grayed out when a boolean is true,
-- i.e. '2. Add label' optons a. and b. (indices 3 and 4 respectively in menu_t) with '1. Replace label',
-- options a. and b. of setting '3. Define initial numeral ...' (menu indices 1-7) with '6. Create new track with label'
-- all settings and default categories (indices 1-16) with '7. Edit lists'
local grayout_t = {[1]={3,4}, [6]={1,7}, [7]={1,18}}

local sett_indices_t = {}
	for menu_idx, item in ipairs(menu_t) do
		for sett_idx, sett in ipairs(sett_t) do
		if item:gsub('|','') == sett then
		sett_indices_t[menu_idx] = sett_idx -- store settings array index under menu index
		break end
		end
	end

-- Extract set bits
local sett_bools_t = {}
	for k in ipairs(sett_t) do
	local bit = 2^(k-1)
	sett_bools_t[k] = bit == 32 and default_cats and false or bitfield&bit == bit -- if default categories are loaded unset bit 32 if set because in this case '7. Edit lits' option is grayed out and keeping it enabled is pointless
	end

	-- Checkmark enabled settings in the menu
	for sett_idx, truth in ipairs(sett_bools_t) do
		for menu_idx, item_idx in pairs(sett_indices_t) do
			if item_idx == sett_idx then -- a setting index in the menu has been found
			local sett = menu_t[menu_idx]
			menu_t[menu_idx] = (truth and '!' or '')..sett
			break end
		end
	end

	-- Checkmark menu settings which are mutually exclusive
	-- to the booleans stored in the bitfield
	if excl_sett_t then
		for menu_idx, bool_idx in pairs(excl_sett_t) do
		local sett = menu_t[menu_idx]
		menu_t[menu_idx] = (not sett_bools_t[bool_idx] and '!' or '')..sett
		end
	end


	-- Gray out items in the menu
	if grayout_t then
		for bool_idx, range in pairs(grayout_t) do
			if sett_bools_t[bool_idx] then -- true
				for menu_idx=range[1], range[#range] do
					if sett_indices_t[menu_idx] ~= bool_idx then -- prevent graying out the very menu item which triggers graying out of other menu items in case its own index is included within the range
					local menu_item = menu_t[menu_idx]
						if menu_item:sub(1,1) ~= '#' then -- prevent accrual of hash signs if item was already grayed out in previous cycles
						local _, lines_cnt = menu_item:gsub('%w|[%s%w]+','')
							if lines_cnt > 0 then -- menu item which occupies several menu lines
							menu_item = menu_item:gsub('|','|#',lines_cnt) -- if menu item doesn't start with pipe |, as is the case here, hash # will only be applied to lines other than the 1st
							end
							if menu_idx ~= 15 then -- not 'COLLAPSE SETTINGS MENU'
							menu_t[menu_idx] = '#'..menu_item
							end
						end
					end
				end
			end
		end
	end


	if #init_numeral == 0 then -- gray out '3. Define initial numeral..' options when init numeral isn't defined
		for k, v in ipairs({6,7}) do
		menu_t[v] = '#'..menu_t[v]
		end
	end

	-- populate 'DIGITS' category
	for i=9,0,-1 do -- in reverse due to cicrular replacement with table.insert targeting the same index
	local digit = (i == 9 and '<' or '')..math.floor(i*order_of_magn)..'|' -- closing the submenu at the end of the loop
	table.insert(menu_t, 17, digit) -- 17 is index of CHANNELS category in menu_t so it's pushed forward making room for digits submenu
	end

-- populate 'CHANNELS' category
local ch_t = {'L','R','Mono','Stereo','Mon', 'St', 'Multi-Ch'}
local idx = #menu_t -- get index of SEPARATORS category in menu_t so it's pushed forward making room for CHANNELS submenu
	for i=#ch_t,1,-1 do
	local v = ch_t[i]
	v = (i == #ch_t and '<' or '')..v..'|' -- closing the submenu at the end of the loop
	table.insert(menu_t, idx, v)
	end

-- populate 'SEPARATORS / BRACKETS' category
local sep_t = {':','::','/','-','–','—','..',';','+','~','|','*','<','>','–>','<–','( )','[ ]','{ }'}
	for k, v in ipairs(sep_t) do -- this loop only suits to populate the last default category in the menu
	menu_t[#menu_t+1] = (k == #sep_t and '<' or '')..esc_menu_ops(v)..'|' -- closing the submenu at the end of the loop
	end


	-- collapse settings menu into a submenu
	if collapse_sett=='1' then
	menu_t[15] = '<MOVE SETTINGS TO MAIN MENU||' -- precede table.insert otherwise collapse menu item index will be different
	table.insert(menu_t, 1, '>'..spaceout('SETTINGS')..'|') -- inserting SETTINGS submenu title
	end


user_categ_t = user_categ_t or parse_categories(CATEGORIES)

	if not user_categ_t then return end -- non-paired opening quotation mark is found in one of the labels, the error message is generated inside parse_categories

local output = Reload_Menu_at_Same_Pos(table.concat(menu_t)..table.concat(user_categ_t), 1) -- keep_menu_open true

	local function remove_cat_titles(t)
		for i=#t,1,-1 do
			if t[i]:match('^|?>') then
			table.remove(t, i)
			end
		end
	return t
	end

-- remove category titles from stock categories DIGITS AND CHANNEL
-- so that they don't count against indexing
-- and the menu output matches indices of meaningful menu_t entries
menu_t = remove_cat_titles(menu_t)

-- offset extra line in menu item '3. Define initial..'
-- so that menu output value matches menu_t table indices
output = output > 5 and output-1 or output

	if output == 0 then return -- menu exited

	elseif sett_indices_t[output] or excl_sett_t and excl_sett_t[output] then -- toggle a setting

	local idx = sett_indices_t[output] or excl_sett_t and excl_sett_t[output] -- extract index relevant for sett_t table
	sett_bools_t[idx] = not sett_bools_t[idx] -- flip because it's a toggle

		-- make setting 3 options 'a. prepend to label' and 'b. append to label' mutually exclusuve
		-- but only if one of them has just be set ON, this allows setting both to OFF state
		-- thereby disabling setting 3 without having to delete the number
		if output > 5 and output < 8 -- OR if idx > 2 and idx < 5 // idx value which is extracted above from sett_indices_t
		and sett_bools_t[idx] then
		local t = {[3]=4,[4]=3} -- associate indices of mutually exclusive options relevant for sett_bools_t table
		local idx = t[idx] -- get index of the option opposite of the one which has been set to ON
		sett_bools_t[idx] = false -- disable it
		end

	elseif output == 5 then -- set/clear setting 3 init numeral

	local num = process_init_numeral(init_numeral)

		if num ~= init_numeral and #num > 0
		and not sett_bools_t[sett_indices_t[output+1]] and not sett_bools_t[sett_indices_t[output+2]] then
		Error_Tooltip('\n\n ENABLE THE OPTIONS "a" OR "b" \n\n    TO ACTIVATE THIS SETTING \n\n', nil, 1) -- caps nil, spaced true
		pause(3)
		end

	init_numeral = num -- assign, for it to be stored inside extended state further below

	elseif output == 8 then -- set order of magnitude

	local orders = {1,10,100}
		for k, v in ipairs(orders) do
			if v == order_of_magn then
			order_of_magn = orders[k+1] or orders[1]
			break end
		end

	elseif output == 12 then -- store current settings as default

	store_settings_as_default(settings)
	DEFAULT_SETTINGS_temp = settings -- assign to be able to gray out '8. Store settings as default' menu item once stored and current settings become identical, see a more detailed explanation of the logic at the beginning of this function where DEFAULT_SETTINGS_temp var is initialized

	elseif output == 13 then -- reset to defaults, only keeping settings menu collapse state

		if #init_numeral > 0 and #DEFAULT_SETTINGS:match('.-;(.-);') == 0
		and r.MB('Reset will clear the initial numeral\n\n\tof the setting 3','WARNING',1) == 1
		or #init_numeral == 0
		then
		r.SetExtState(scr_cmd_ID, 'TRACK NAMING TOOL SETTINGS', DEFAULT_SETTINGS, false) -- persist false
		--	r.DeleteExtState(scr_cmd_ID, 'TRACK NAMING TOOL SETTINGS', true) -- persist true
		end

	elseif output == 14 then -- undo

	r.Undo_DoUndo2(0)

	elseif output == 15 then -- move settings menu to sub/main menu

	collapse_sett = collapse_sett=='1' and '0' or '1'

	else -- apply OR edit labels

	local b = bitfield
	local repl, add_append, init_num_prepend, init_num_append, caps, create_new_tr, edit =
	b&1 == 1, b&2 == 2, b&4 == 4, b&8 == 8, b&16 == 16, b&32 == 32, b&64 == 64
	local label = menu_t[output]

		if not edit then -- apply

			if not label then -- user category label, which stored inside user_categ_t and not in menu_t
			user_categ_t = remove_cat_titles(user_categ_t) -- remove category titles to calculate user_categ_t local label index
			label = user_categ_t[output-#menu_t]
			user_categ_t = nil -- reset so that it's built anew when the menu is reloaded because otherwise it will lack category titles removed above for the sake of accurate indexing
			end

		label = (caps and label:upper() or label):match('|*<?\r?(.-)|?$') -- stripping menu operators and \r escape character which are prepended to the labels inside parse_categories() function // labels of stock categories DIGITS, CHANNELS and BRACKETS/SEPARATORS don't start with formatting operators but end with a pipe // '|*' accounts for double pipe if added to a label to separate edited/newly added in the reloaded menu, see Edit routine below
		local brackets = label:match('^[%(%[{] [%)%]}]$')

			if not create_new_tr then -- '6. Create new track with label' is disabled so to apply the label there have to be selected tracks
			local tr, sel_tr = r.GetTrack(0,0), r.GetSelectedTrack(0,0)
			local err = ' selected tracks'
			err = not tr and 'no tracks in the project' or not sel_tr and 'no'..err
			or not r.IsTrackVisible(sel_tr, false) and 'no visible'..err -- mixer false
				if err then
				Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
				pause(1)
				end
			else -- insert new track
			r.Main_OnCommand(40001, 0) -- Track: Insert new track
			-- OR
			-- r.InsertTrackAtIndex(r.CSurf_TrackToID(r.GetSelectedTrack(0,0), false), true) -- wantDefaults true, mcpView false // inerting after the first selected to mimic 'Track: Insert new track' behavior
			end

		local DIGITS = output > 15 and output < 26
		local init_num = tonumber(init_numeral)
		local sel_tr_cnt = r.CountSelectedTracks(0)
		local mult_tr = sel_tr_cnt > 1
		r.Undo_BeginBlock()
			for i=0, sel_tr_cnt-1 do
			local tr = r.GetSelectedTrack(0,i)
				if r.IsTrackVisible(tr, false) then -- mixer false
				local ret, tr_label = r.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false) -- setNewValue false
					if create_new_tr or brackets then -- if track was created initial numeral doesn't apply if enabled neither do other settings
					tr_label = brackets and label:sub(1,1)..tr_label..label:sub(3,3) or label
					else
					local space = tr_label:match('%S') and ' ' or ''
					tr_label = repl and label or (not add_append and label..space or '') -- add prepend
					..tr_label..(add_append and space..label or '') -- add append
					tr_label = not DIGITS and init_num and (init_num_prepend and mult_tr and init_num..' ' or '')..tr_label
					..(init_num_append and mult_tr and ' '..init_num or '') or tr_label
					end
				r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_label, true) -- setNewValue true
				init_num = init_num and init_num+1 -- increment for the next cycle
				label = DIGITS and label+1 or label -- increment numeral for the next cycle if the label belongs to DIGITS category
				end
			end
		r.Undo_EndBlock(undo, -1)

		else -- edit

		local idx, cat_title = calc_user_cat_label_index(output, #menu_t-3, user_categ_t) -- -3 to exclude from the menu length two stock category titles DIGITS and CHANNELS which don't count against the menu output value; output value has already been offset by -1 above to match the single menu_t entry '3. Define initial numeral' which in the menu occupies 2 lines
		local label = user_categ_t[idx]
		local closure = label:match('^|<')
		local only_label = user_categ_t[idx-1]:match('^|>') and (not user_categ_t[idx+1] or user_categ_t[idx+1]:match('^|>')) -- either only label of the last category or only label in between category titles
		label = label:match('^|+<?\r?(.+)') -- stripping menu operators and \r escape character which are prepended to the labels inside parse_categories() function // '|+' accounts for double pipe if added to separate edited/newly added in the reloaded menu, see below
		label = label:match(',') and '"'..label..'"' or label -- enclose label containing commas within quotes to conform to label list formatting rules and so that if submitted without changes it's still parsed as a single label and not several comma separated

		local ret, output

		::EDIT::
		ret, output = r.GetUserInputs('CATEGORY EDITOR (single label or comma separated)', 1, 'Label(s),extrawidth=200,separator=\n',
		output or label) -- using new line as a separator because the default comma cuts off rest of the phrases which contain commas // OPTED FOR A SINGLE FIELD DIALOGUE, BECAUSE IF MULTIPLE FIELDS AND AN EDITED LABEL CONTAINS NON-PAIRED QUOTATION MARK OR UNBALANCED APOSTROPHE OR PARENTHESIS, WHEN AFTER ERROR DISPLAY THE OUTPUT IS FED BACK INTO THE RELOADED DIALOGUE, FIELD SEPARATION BREAKS DOWN (https://forum.cockos.com/showthread.php?t=288046), WHICH IS CURABLE BY RESOLVING THE UNBALANCED CHARACTERS WITH resolve_all_or_restore_apostrophe() BUT THIS SOLUTION IS HIGHLY UNWIELDY AND CONFUSING TO THE USER

			if ret then -- user didn't cancel the dialogue, i.e. submitted it

			local output_t = process_label_edit(output, cat_title)

				if not output_t then goto EDIT end -- the edit contains non-paired quotation mark which will break label list when saved into the script // the erro message is generated inside process_label_edit

			table.remove(user_categ_t,idx) -- remove the entry of the clicked label because it will be either re-added in the loop below along with new labels or will remain removed

				if #output_t > 0 -- some labels will be added to the menu
				and user_categ_t[idx] and not user_categ_t[idx]:match('|>') -- if not end of categories list and not a next category title, i.e. the label wasn't the last in the list
				and not user_categ_t[idx]:match('||') -- and there's no separator yet at the bottom
				then
				user_categ_t[idx] = '|'..user_categ_t[idx] -- add one other pipe to label which will follow the newly added ones to visually separate them at the bottom when the menu is reloaded, a visual separator at the top will be added in the output_t loop
				elseif #output_t == 0 and user_categ_t[idx] then -- label has been removed without anything added and the label isn't the last in the categories menu
				user_categ_t[idx] = user_categ_t[idx]:gsub('||','|') -- replace double pipe as a bottom separator with a single one in case left from previous edit
				end

			local length_init = #user_categ_t -- store length of the table after the label has been removed to compare to its length after adding labels from user output // unnecessary if '#output_t == 0' evaluation is used below intead of '#user_categ_t == length_init'

				for i=#output_t,1,-1 do -- iterate in reverse because table.insert pushes entry at idx closer to table end so that each ealier entry from output_t pushes out a later one thereby maintaining their original order inside output_t
				local label = output_t[i]
					if label:match('%S') then -- not empty
					-- format the label for the menu;
					-- if the original label included submenu closure, close the first inserted item
					-- i.e. the last valid inside output_t
					-- because due to the reversed loop it will end up being the last in the labels submenu;
					--	label = '|'..(closure and '<' or '')..esc_menu_ops(label:match('(%S.-)%s*$')) -- stripping surrounding spaces -- OLD
					--	label = '|'..(closure and '<' or '')..label -- OLD
					-- to the last added label, i.e. the first in label sequence, add double pipe
					-- to separate the newly added labels at the top when the menu is reloaded
					-- unless it's the very first label in the list
					label = (i == 1 and not user_categ_t[idx-1]:match('|>') and '||' or '|')..(closure and '<' or '')..label
					table.insert(user_categ_t, idx, label)
					closure = nil -- reset for subsequent cycles
					end
				end

				if #user_categ_t == length_init then -- OR #output_t == 0 // the label was deleted from the category and nothing was added
					if only_label then -- the only label was deleted
						if r.MB('The "'..user_categ_t[idx-1]:match('^|>(.+)')..'" category\n\n\thas been left empty.\n\n'
						..'The category title will be deleted as well.','WARNING',1) == 2 then -- user cancelled
						else -- delete the category title
						table.remove(user_categ_t,idx-1)
						end
					elseif closure then -- if the clicked label was the last in the list, closure formatting must be added to the preceding one after its removal
					local label = user_categ_t[idx-1]
					user_categ_t[idx-1] = '|<'..label:sub(2) -- 2 to trim preceding pipe
					end
				end

			update_script_data(user_categ_t)

			end

		end

	end


	if sett_indices_t[output] or excl_sett_t and excl_sett_t[output] then -- this condition will likely need expansion to include indices of other menu items which aren't settings
	-- Store new bitfield
	bitfield = 0
		for k, truth in ipairs(sett_bools_t) do
			if truth then
			bitfield = bitfield|2^(k-1)
			end
		end
	end

	if output == 5 -- '3. Define initial numeral'
	or output == 8 -- '4. Change DIGITS order of magn'
	or output == 12 -- '8. Store settings as default'
	or output == 15 -- 'MOVE SETTINGS TO SUB/MAIN MENU'
	or sett_indices_t[output] -- a toggle setting state was changed
	or excl_sett_t and excl_sett_t[output] then -- mutually exclusive toggle settings state was changed
	local data = bitfield..';'..init_numeral..';'..order_of_magn..';'..collapse_sett
	r.SetExtState(scr_cmd_ID, KEY, data, false) -- persist false
	r.SetProjExtState(0, scr_cmd_ID, KEY, data)
	end

goto RELOAD

end



------------ MAIN ROUTINE ------------


Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID)

::RELOAD::

local DEFAULT_SETTINGS = "3;;1;0"

local default = [[

Category1
|label1, >label2, <label3, !label4, #label5
Category2
|label1, "label2, te,st, 123", label3, label4, "label5 раз два три test"
Category3
|label1, >label2, <label3, !label4, #label5
Category4
|label1, "label2, te,st, 123", label3, label4, "label5 раз два три test"

]]

local default = [[

DRUM KIT
Bass Drum, Bell, China, Crash, Cup, Drums, Cl. Hat, Hi Hat, Op. Hat, Ride, Rimshot, Snare, Splash, Tom

STRINGS
Banjo, Bass, Cello, Dulcimer, A. Guitar, E. Guitar, Fiddle, Harp, Lute, Mandoline, Strings, Violin, Viola

PERCUSSION
Agogo, Bongo, Cabasa, Castanets, Chimes, Clave, Conga, Cowbell, Cuica, Djembe, Gong, Guiro, Flexatone, Finger Snap, Maracas, Percussion, Rainstick, Shaker, Sleigh Bell, Tambourine, Triangle, Vibraslap, Whistle, Woodblock

CHROMATIC PERC
Celesta, Glockenspiel, Handpan, Marimba, Steelpan, Timpani, Tubular bells, Vibraphone, Xylophone

BRASS
Brass, Cornet, Flugelhorn, French Horn, Trombone, Trumpet, Tuba

WOODWINDS / REED
Bassoon, Clarinet, Contrabassoon, English Horn, Flute, Oboe, Pan Flute, Piccolo, Recorder, Reed, Saxophone, Woodwind

KEYS
Accordion, Clavichord, Clavinet, Digi Piano, E. Piano, Grand Piano, Keys, Harpsichord, Mellotron, Melodica, Organ, Synth, Upright Piano

ARTICULATIONS
Accent, Arpeggiated, Glissando, Legato, Marcato, Muted, Pizzicato, Pluck, Portamento, Portato, Roll, Sforzando, Sforzato, Spiccato, Staccato, Strum, Sostenuto, Tremolo, Trill, Vibrato

PART TYPES (A-L)
Ad-lib, Arpeggio, Backbeat, Background, Backing, Break, Bridge, Build-up, Choir, Chords, Chorus, Click, Coda, Countermelody, Double, Drone, Drop, Fill, Foreground, FX, Groove, Harmony, High, Hit, Interlude, Intro, Lead, Loop, Low,

PART TYPES (M-U)
Melody, Mic, Mid, Midground, Motif, Noise, Octave, Obbligato, Ostinato, Outro, Pad, Pre-chorus, Post-chorus, Refrain, Reprise, Reverse, Riser, Rhythmic, Solo, Soundscape, Stab, Stem, Submix, Swell, Texture, Theme, Topline, Transition, Turnaround, Unison, Verse, Vocal, Vox

]]

local default_cats = not CATEGORIES:match('\n?%s*%S%s*\n%s*%S%s*')
local CATEGORIES = not default_cats and CATEGORIES or default -- only use user categories if there're at least two lines, i.e. category title and a label

Menu_With_Toggle_Options(named_ID, CATEGORIES, default_cats, DEFAULT_SETTINGS)


do return r.defer(no_undo) end

