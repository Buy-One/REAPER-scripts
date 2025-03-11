--[[
ReaScript name: BuyOne_Custom action step-through previewer.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: recommended 6.71 or newer
Extensions: SWS/S&M unless REAPER build is 6.71 or newer
About: 	The script allows importing/replicating custom actions
			to run them step by step while monitoring the progress
			either to debug existing custom actions or to build new
			ones from scratch.  
			
			Actions supposed to be run with the mousewheel cannot
			be tested with this script.
			
			When the script is launched its click pad box will be 
			opened. Left-click inside the box will call the script
			menu interface. To be able to use the script the box must 
			stay open. It can be closed when not needed. To close the 
			click pad box press Escape key when it's focused or click 
			the close button at its upper right-hand corner. 
			On re-opening the clock pad box window is opened at its last 
			location, not at the mouse cursor.  
			The latest configuration is saved and will be available 
			during the same REAPER session. The script doesn't store 
			any data outside of the current session so in each new 
			session it will start out completely reset.  
			If you wish to make the custom action available to the
			script in subsequent sessions export is as an .ReaperKeyMsp
			file (see EXPORTING THE CUSTOM ACTION paragraph below).
			

			ADDING CUSTOM ACTION TO THE SCRIPT
			
			There're 2.5 ways to add a custom action to the script:
			1a. To import it by supplying its command ID taken from the
			Action list (right click -> Copy selected action command ID);  
			1b. To import it from a .ReaperKeyMap file;  
			2. To add by arming actions one by one.
			
			To import use IMPORT CUSTOM ACTION option. To import from 
			a .ReaperKeyMap file submit the import dialogue empty to call
			a file browser.  
			If the script menu alerady contains a list of actions imported
			or added earlier, deleting them prior to the import is not
			necessary because the import option will allow to replace
			them with the imported ones.
			
			In order to be able to add an armed action 
			1. Enable the ADD ARMED ACTION option
			2. Open the Action list and arm the target action,
			as soon as it's armed it will be added to the action sequence
			after the checkmarked action item and immediately unarmed, 
			if no action is checkmarked it will be added to the bottom 
			of the list unless this behavior is changed in the 
			USER SETTINGS. The newly created action item doesn't get
			checkmarked which can be changed in the USER SETTINGS. 
			Actions cannot be added with the Action list closed even 
			by arming them via a toolbar.  
			While the armed action is being added, the script menu will be 
			closed because it has lost the mouse focus, but will open as 
			soon as a new action has been added, to reflect the change.  
			While ADD ARMED ACTION option is enabled the option RUN ACIONS
			which triggers the actions will be inactive.		
			
			Only import/addition of actions belonging to the Main, MIDI Editor 
			and MIDI Event List sections of the Action list is supported. 
			
			When importing from .ReaperKeyMap file containing multiple custom 
			actions only the first found custom action will be imported.
			
			When importing a custom action via the dialogue on top of the 
			existing list of actions and opting for 'Append' option, the custom
			action sequence will be added after the last action entry of the 
			current list. When adding actions to the existing list by arming
			they're added after the ckeckmarked action entry and if there's
			none they're added after the last action entry.
			
			The initial import/addition determine the association with the 
			Action list section for all actions appended later to the existing 
			list of actions, that is the newly added actions must belong to the 
			same Action list section as the first imported custom action or 
			the first action added by arming. Actions from other sections will 
			be rejected. 
			
			
			ACTION MANAGEMENT OPTIONS
			
			Once custom action has been imported or a list of actions 
			has been built the individual action entries can be managed 
			with the management options hidden in the OPERATION submenu.  
			These are enabled and disabled automatically depending on the 
			state of the list of actions and their total number.  
			To be able to affect an action entry in the list with the 
			management options checkmark it.  
			The management options can be exploded to the main menu for
			ease of access with 'Explode list menagement menu' item, which 
			is especially convenient when an action needs to be moved more 
			than one position in any direction.  
			The MOVE ACTION UP/DOWN operation is circular.
			
			The script allows disabling action items which will prevent
			execution of actions linked to them when the sequence is
			stepped through, they will be skipped instead. Disabled action
			items can be stored with the exported .ReaperKeyMap file and 
			re-disabled when the file is imported into the script. 
			On a 64 bit system a maximum of first 63 actions can be stored, 
			while on a 32 bit system it's the first 52 actions.
			
			
			EXECUTING THE CUSTOM ACTION
			
			The execution is performed by repetative clicking on the 
			RUN ACTIONS menu item. 
			To run MIDI Editor and MIDI Event List actions the MIDI Editor 
			must be open.
			The entry of the latest excuted action gets checkmarked in 
			the list. 
			In order to start the execution from the top no action item 
			in the list must be checkmarked. The only way to achieve that 
			is by un-checkmarking the very last action item in the list which 
			is the only one whose checkmark can be toggled. So if not 
			initially checkmarked its checkmark must be toggled to On to 
			clear checkmark from any other action item and then to Off. 
			Otherwise the action sequence is executed from the currently 
			checkmarked action item, unless it's the last one because  
			the execution cannot go past the last action item.  
			
			During action sequence execution the checkmark indicates the 
			latest excuted action.
			
			Disabled actions are skipped during the sequence execution.
			
			
			UNDOING
			
			Undo operation always runs from the last action executed
			by the script regardless of the currently checkmarked action 
			item. It's possible to shuttle between RUN ACTIONS and UNDO 
			operations back and forth without reaching the end of the 
			custom action sequence.
			
			To undo MIDI Editor and MIDI Event List actions with the 
			script the MIDI Editor must be open.
			
			The UNDO menu item stays inactive as long as the latest undo
			point in REAPER undo history was not created by this script.
			It's activated when action sequence execution starts.
			The UNDO menu item is deactivated as soon as the the first undo 
			point created by the script has been undone, if action sequence 
			execution is interrupted by other REAPER operations which create 
			their own undo points, or if the undo point index doesn't match
			the action position in the sequence which can happen if the 
			actions have been reordered. 
			
			During undoing of the action sequence the checkmark indicates 
			action preceding the latest undone action, that is the latest 
			not yet undone.
			
			Of course custom action steps can be undone by conventional 
			means while the menu us closed. 
			
			When undo is being performed by means other than the script, i.e. 
			while the menu is closed, checkmark is not moved to the latest
			not yet undone action and stays where it was before the menu was
			exited. When the action sequence has been fully undone, i.e. when 
			the undo point preceding the 1st undo point created by the script
			in REAPER undo history has been reached, the checkmark is cleared 
			from action items regardless of the way undo has been performed.


			EXPORTING THE CUSTOM ACTION
			
			The action sequence is exported from the script as a custom 
			action with 'EXPORT as .ReaperKeyMap' option.  
			On export the custom action command ID and name are determined 
			by the command ID and name of the initially imported custom 
			action. If the action sequence was built by arming actions,
			on the very first export the command ID will be generated 
			automatically while the name of the exported custom action will
			be user chosen, and both will be preserved in the memory for 
			future exports until all actions are deleted, a new custom action
			is imported deleting the current one or REAPER session is finished.  
			The exported .ReaperKeyMap file is placed in the /KeyMaps folder 
			inside REAPER resource directory being named after the custom
			action.  
			Export of a custom action imported via its command ID from the 
			Action list without any changes to the order or array of the 
			actions it's made up of is prevented because it makes no sense. 
			Such custom action can be exported directly from the Action list.
			
			
			RUN ACTIONS and ADD ARMED ACTION options sre mutually exclusive.
			
			
			Quick access shortcuts (the register is immaterial):
			
			(UN)DISABLE MARKED ACTION	- n
			MOVE MARKED ACTION UP		- p
			MOVE MARKED ACTION DOWN		- d
			RUN ACTIONS						- r
			UNDO								- u
			
			They're underscored in the menu.
			
			
			CAVEATS
			
			The script doesn't support actions whose functionality depends
			on mouse cursor position because when it's executed the mouse
			cursor is engaged with the actions sequence menu.
			
			The script usability is limited by the screen resolution because
			only so many menu items can be visible at once. If the menu size
			cannot fit within the screen height the extra items will only
			be accessible by scrolling the menu which besides being 
			enconvenient makes using the script impractical because when the
			menu is reloaded after each click to stay visible its scroll state
			is reset and the item just accessed will again become hidden and
			requiring scrolling.  
			At screen height resolution of 768 px a max of 36 action items are 
			visible in the menu. For every additional 17 px one more action item 
			can be displayed, conversely, every reduction by 17 px will result 
			in one fewer visible action item.
			
]]	



	-- To be able to execute the sequence of actions from the very beginning make sure that no action item is checkmarked, if there're checkmarked action items other than the last double click the last one to checkmark is and immediately clear, if the last item is checkmarked click it once. Otherwise the sequence of actions will be executed from the currently checkmarked item unless it's the last one

-- actions exclusive to custom actions, that is those starting with the 'Action:' prefix are not supported,
-- they will be included among the imported/added actions but won't perform the function they're designed
-- to perform when run within custom actions

	-- RUN ACTIONS and ADD ARMED ACTION options sre mutually exclusive

	-- in RUN ACTIONS the checkmark indicates the latest excuted action, UNDO - the action preceding the latest undone action, that is the latest not yet undone

--[[ OLD AND IRRELEVANT
-- For the script to store the custom action UNDO history 3 conditions must be met:
-- 1. The execution must start from the very first action in the sequence (technically it's possible to start from any action by checkmarking it). If it's not the custom action UNDO hostory storage won't initialize.
-- 2. The execution must not be interrupted by other actions run by means other than the script which leave undo points in REAPER undo history. If it is the UNDO option gets disabled.
-- 3. All actions in the sequence must be executed effectively, that is leave an undo point in REAPER undo history. If certain prerequisites for successful custom action execution have not been in place (such as selection of objects, time selection being active, the edit cursor position, actions/options/settings toggle state etc.) the undo operation may fail in the middle because certain actions didn't leave undo points in REAPER undo history.
-- 4. Before undoing the list of actions must not be reordered.
-- If script undo history becomes longer than the number of steps in the custom action or the last action stored in it doesn't match the last action in the custom action sequence or there's a mismatch between the actions stored in the script undo history and in REAPER undo history the script undo history will be automatically reset.
-- Of course custom action steps can be undone by the conventional means. However if some steps have been undone with REAPER native undo function attempt to continue UNDO operation from the script will result in a failure, the action preceding the latest undo action in this case will also not be checkmarked in the custom action menu unlike when undo is performed from the script.
]] 
	-- UNDO operation always runs from the last executed action regardless of the currently checkmarked action item. It's possible to shuttle between RUN ACTIONS and UNDO operations back and forth without reaching the end of the custom action sequence.
	-- to undo MIDI Editor and MIDI Event List actions with the script the MIDI Editor must be open

	-- if no custom action was imported prior to adding a new action, the section of the Action list the custom action is associated with will be determined by the section of such new action and will be reflected in the code of the exported .ReaperKeyMap file
	-- When imported and edited custom action is exported, its original command ID is preserved; if the actions were added one by one through arming, the very 1st time they're exported as a .ReaperKeyMap file the resulting custom action is assigned a unique command ID which is then maintained in subsequent exports until all actions are deleted or a new custom action is imported
	-- .ReaperKeyMap file is exported to the /KeyMaps folder inside REAPER resource directory
	-- with file dialogue a custom action can be imported from a .ReaperKeyMap file located anywhere on the disk however exported .ReaperKeyMap file will always be placed in the /KeyMaps folder in REAPER resource directory;


-- to exit menu the window top bar can be clicked or any other place outside of the window


---------------------------------------------------------------------------

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert any alphanumeric
-- character between the quotation marks


----------- ADD ARMED ACTION option settings

-- Enable to have the armed action added to the top
-- of the action sequence when there's no checkmarked
-- action item;
-- by default it's added to the bottom of the list
ADD_TO_TOP_OF_THE_LIST = ""

-- Enabled to have the newly created action item checkmarked 
-- after addition of an armed action to the sequence;
-- by default the checkmarked action item remains the same
-- or nothing gets checkmarked if there's no checkmarked item
CHECKMARK_ADDED = ""


----------- DUPLICATE MARKED ACTION operation setting

-- Enable to have the copy of duplicated 
-- action item checkmarked;
-- by default the source menu item remains checkmarked
CHECKMARK_DUPLICATED = ""


----------- DELETE MARKED ACTION operation setting

-- Enable to move the checkmark
-- to the action entry which follows
-- the deleted one;
-- by default the checkmarked action entry
-- is deleted with the checkmark
INHERIT_CHECKMARK = ""


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


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0'):gsub('\\','%0%0')
return str
end


function validate_sett(sett)
return #sett:gsub(' ','') > 0
end


function sanitize_file_name(name)
-- the name must exclude extension
-- https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names
local OS = r.GetAppVersion()
local lin, mac = OS:match('lin'), OS:match('OS')
local win = not lin and not mac
local t = win and {'<','>',':','"','/','\\','|','?','*'}
or lin and {'/'} or mac and {'/',':'}
	for k, char in ipairs(t) do
	name = name:gsub(char, '')
	end
local win_illegal = 'CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9'
	if win then
		for ill_name in win_illegal:gmatch('[^,]+') do
			if name:match('%s*'..ill_name..'%s*') then name = '' break end -- illegal names padded with spaces aren't allowed either
		end
	end
	if #name > 0 then -- if after the sanitation there're characters left
	return name
	end

end



function sanitize_file_path(f_path)
-- the limit is 256 characters
-- truncating the file name if needed

-- make the stock function count characters rather than bytes
-- the change applies to the entire environment scope
-- doesn't affect # operator
--[[
string.len = 	function(self)
					return #self:gsub('[\128-\191]','')
					end
]]
-- OR
function string.len(self)
return #self:gsub('[\128-\191]','') -- discard the continuation bytes, if any
end
-- OR
function utf8_len(str)
return utf8.len(str) or #str
end

-- make the stock function reverse non-ASCII strings as well
-- the change applies to the entire environment scope
function string.reverse(self)
local str_reversed = ''
	for char in self:gmatch('[\192-\255]*.[\128-\191]*') do
	str_reversed = char..str_reversed
	end
return str_reversed
end

local path, name, ext = f_path:match('(.+[\\/])(.+)(%.%w+)')
local diff = 256 - (path:len()+ext:len())
local mess = ''

	if diff <= 0 then
	Error_Tooltip('\n\n the file path length \n\n   exceeds the limit. \n\n', 1, 1) -- caps, spaced true
	return
	elseif 256-(path:len()+ext:len()) < name:len() then -- truncate file name
	name = name:sub(1,256-(path:len()+ext:len())) -- allow only as many characters as the difference between 256 and the path+extension
	-- after truncation the file name may happen to match an existing file
	-- if so reverse the name, not 100% failproof but the odds that the reversed file name will still clash are fairly low
	local reversed = ''
		if r.file_exists(path..name..ext) then
		name = name:reverse()
		reversed = '\n\n   and reversed to prevent clash with an existing file.'
		end
	mess = '\tThe file name has been truncated'..(reversed or '.')..'\n\n'
	end

return path..name..ext, mess

end


function dec2hex(dec_int)
-- input arg is a decimal integer
-- https://www.rapidtables.com/convert/number/decimal-to-hex.html algo

	if not dec_int then return end
	
local dec_int2

	if dec_int > 0xfffffffffffff then  -- 2^52
	-- math.maxinteger is supported from Lua 5.3
		if tonumber(_VERSION:match('[%.%d]+')) < 5.3 or math.maxinteger == 0x7fffffff then -- either Lua older than 5.3 or 32 bit system, 0x7fffffff == 2147483647
		return dec_int -- on a 32 bit system integers above 2^31 Lua encodes as double floating point numbers while in older Lua versions all integers are encoded as double floating point numbers; in all versions of Lua floating point precision limit is 2^53-1 (about 15 - 17 decimal places) after which rounding errors start to occur, so in these two cases no point to convert a number above 2^53-1 (in practical terms above 2^52, because in division and modulo operations employed for conversion into hex this is the limit of accuracy) because it will be fed in with rounding erros from the outset
		end
	-- the following assumes that integers up to 2^53-1 are represented natively rather than as floating point numbers, 
	-- which is good for REAPER since native integer representaion is supported in Lua 5.3+
	-- run by all REAPER versions with Lua support
	local diff = math.floor(math.log(dec_int)/math.log(2))-52 -- find by how much the input exponent exceeds the Lua max floating point number precision limit which is 53 bit i.e. ~15-17 decimal places, because numbers whose decimal places exceed this limit lose precision and cause wrong calculation result, this workround is needed because the employed conversion method to hex relies on division and modulo operaions which produce decimal numbers for which precision is important; using value 52 instead of 53 because in division and modulo operations the limit of accuracy is 52 bit; formula to calculate exponend of the value by specific base comes from  https://www.gammon.com.au/scripts/doc.php?lua=math.log
	dec_int, dec_int2 = dec_int >> diff, dec_int >> 52 -- shift the input value right by the difference to only leave bits whose total doesn't affect precision, then shift the input value right by 52 bits to isolate the remaining upper bits, those which have been discarded in shifting right by the difference // this is the correct splitting method for subsequent string concatenaton because it produces parts with different bit width just as would occur in splitting a string for example '256' into '56' and '2', because maintaining original width i.e. '056' and '200' would not allow accurate concatenation resulting in 200056
	end

local hex = ''
local t  = {[0]=0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f'}
	repeat
	local quotient = math.modf(dec_int/16) -- OR math.floor(dec_int/16)
	hex = t[dec_int%16]..hex
-- OR
--	hex = t[dec_int-16*quotient] and t[dec_int-16*quotient]..hex or hex
	dec_int = quotient
	until quotient == 0

local hex2
	if dec_int2 then -- if the input number exponent exceeds the Lua floating point number max precision limit, convert the remaining upper bits, those which exceed 52 bits and concatenate the results placing the upper bits conversion result at the front as that's where they're placed in the bitfield
	hex2 = dec2hex(dec_int2)
	hex = hex2:sub(3)..hex
	end
	
return '0x'..hex

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

-- local x, y = r.GetMousePosition()
local x, y = 0,0 -- set to 0 so that they can be overridden with x2 and y2 which are passed as gfx.clienttoscreen(0,0) so that the tooltip is displayed over the click pad box
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



function embellish_string(str, ornam_code_t, want_spaces)
-- ornam_code_t is a table of integers corresponding to indices of keys 
-- holding the utf-8 char codes in the below tables
-- want_spaces is boolean to apply the ornament to space char as well;
-- the description is relevant to ornament display in the menu
-- 1 - sparse dashed underline (lower under digits)
-- 2/17 - sparse dotted underline; 4/12 - bold dotted underline; 5 - solid underline; 
-- 6/16 - bold dashed underline; 7 - tilde strikethrough; 8 - dash srtikethrough;
-- 9 - solid line strikethrough; 10/11 - short/long slash srikethrough;
-- 13 - solid bold overline; 14 - tilde overline (lower above digits); 
-- 15 - sold bold underline; 18 - dotted overline which crosses characters at the top;

-- when ornament is applied to spaces its level under/above the line
-- may differ from that applied to characters when displayed in the menu;
-- the level under/above numerals may also differ from the level under/above 
-- alphabetic chars when displayed in the menu;
-- https://www.charset.org/utf-8
--[[
local t = {'\xCC\xA0','\xCC\xA3','\xCC\xA4','\xCC\xA5','\xCC\xB2','\xCC\xB3','\xCC\xB4',
'\xCC\xB5','\xCC\xB6','\xCC\xB7','\xCC\xB8','\xCC\xBB','\xCC\xBF','\xCD\x82','\xCD\x87',
'\xCD\x9A','\xDF\xB2','\xDF\xB3'}
--]]
--[-[ OR
local t = {'\204\160','\204\163','\204\164','\204\165','\204\178','\204\179','\204\180',
'\204\181','\204\182','\204\183','\204\184','\204\187','\204\191','\205\130','\205\135',
'\205\154','\223\178','\223\179'}
--]]
table.sort(ornam_code_t) -- some chars may not mix well if inserted not in ascending order
-- e.g. 18,5 or 18,1
local ornam = ''
	for k, v in ipairs(ornam_code_t) do
	ornam = ornam..t[v]
	end
local str = str:gsub('[\192-\255]*.[\128-\191]*', function(c) return not want_spaces and #c:gsub(' ','') == 0 and c or c..ornam end) -- accounting for non-ASCII characters by including leading and trailing bytes if any
return str
end


function MIDIEditor_GetActiveAndVisible()
-- solution to the problem described at https://forum.cockos.com/showthread.php?t=278871
local ME = r.MIDIEditor_GetActive()
local dockermode_idx, floating = r.DockIsChildOfDock(ME) -- floating is true regardless of the floating docker visibility
local dock_pos = r.DockGetPosition(dockermode_idx) -- -1=not found, 0=bottom, 1=left, 2=top, 3=right, 4=floating
-- OR
-- local floating = dock_pos == 4 -- another way to evaluate if docker is floating
-- the MIDI Editor is either not docked or docked in an open docker attached to the main window
	if ME and (dockermode_idx == -1 or dockermode_idx > -1 and not floating
	and r.GetToggleCommandStateEx(0,40279) == 1) -- View: Show docker
	then return ME, dock_pos
-- the MIDI Editor is docked in an open floating docker
	elseif ME and floating then
	-- INSTEAD OF THE LOOP below the following function can be used
	local ret, val = r.get_config_var_string('dockermode'..dockermode_idx)
		if val == '32768' then -- OR val ~= '98304' // open floating docker OR not closed floating docker
		return ME, 4
		end
	--[[ OR
		for line in io.lines(r.get_ini_file()) do
			if line:match('dockermode'..dockermode_idx)
			and line:match('32768') -- open floating docker
			-- OR
			-- and not line:match('98304') -- not closed floating docker
			then return ME, 4 -- here dock_pos will always be floating i.e. 4
			end
		end
		]]
	end
end


function Reload_Menu_at_Same_Pos_gfx(menu)
	if gfx.mouse_y > gfx.y and gfx.mouse_y < gfx.h then
	gfx.y = gfx.mouse_y + 3 -- open the menu 3 px under the mouse cursor to prevent activation of the top item submenu, only when the menu is opened by a mouse click, otherwise (when armed action is added) it will open at gfx window 0 y coordinate which doesn't include the title bar
	end
return gfx.showmenu(menu) -- menu string
end



function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error
-- " cannot use '...' outside a vararg function near '...' "
-- without there being elipsis in function() as well, but gave direction;
-- if original function has arguments they MUST be passed to the Wrapper() function
-- regardless of their scope (global or local);
-- if it doesn't, the upvalues must all be global and it doesn't matter
-- whether they're passed to the Wrapper() function
-- syntax: r.atexit(Wrapper(FUNC_NAME, arg1, arg2, arg3)) -- for defer scripts
local t = {...}
return function() func(table.unpack(t)) end
end


function insert_get_delete_bckgrnd_track(scr_cmdID, delete)
-- delete is boolean
-- the function is used inside force_create_undo_point(),
-- before RUN_MENU() to insert initially, inside it to delete the track
-- when the script is terminated by the user
-- and at the end of the script do delete the track on script termination
-- which is probably redundant because in the case of error the script
-- is aborted without reaching the end
local take_GUID = r.GetExtState(scr_cmdID, 'TAKE_GUID')
-- string gGUID = reaper.stringToGuid(string str, string gGUID)
local take = #take_GUID > 0 and r.GetMediaItemTakeByGUID(0, take_GUID) -- if take isn't found returns nil
local tr = take and r.GetMediaItemTake_Track(take)
	if (not take or not tr) and not delete then -- create if not yet created or deleted // take is evaluated first because track can exist without take
	r.PreventUIRefresh(1)
		if not tr then
		local SET = r.SetMediaTrackInfo_Value		
		r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false
		local idx = r.GetNumTracks()-1
		tr = r.GetTrack(0, idx)
		SET(tr, 'B_SHOWINTCP', 0); SET(tr, 'B_SHOWINMIXER', 0);	SET(tr, 'B_MAINSEND', 0)
		end
		if not take then
		local item = r.AddMediaItemToTrack(tr) -- length is 0 so will be invisible
		take = r.AddTakeToMediaItem(item) -- add take to be able to find track via the take and dispense with iterating over all tracks in the project
		local retval, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', false) -- setNewValue false
		r.SetExtState(scr_cmdID, 'TAKE_GUID', take_GUID, false) -- persist false
		end
	r.PreventUIRefresh(-1)
	elseif tr and delete then
	r.DeleteTrack(tr) return
	elseif tr then -- if track has been unhidden by the user or its master/parent send was enabled, restore
		for k, attr in ipairs({'B_SHOWINMIXER','B_SHOWINTCP','B_MAINSEND'}) do
			if r.GetMediaTrackInfo_Value(tr, attr) == 1 then
			SET(tr, 0)
			end
		end
	end
return tr, take
end


function force_create_undo_point(scr_cmdID)
-- used inside RUN_MENU()
-- REAPER doesn't create undo points for changes
-- which don't affect project, such as toggles, action arming,
-- acton types exclusive to custom actions which only modify
-- their behavior, or if identical actions follow each other
-- the undo point is only created for the first one, 
-- which makes it difficult to create a complete undo sequence
-- for the tested custom actions
-- the solution is in making inconsequential changes in the background
-- so REAPER registers a change to the project, such as setting 
-- and clearing the label of a background track
local tr, take = insert_get_delete_bckgrnd_track(scr_cmdID)
local GETSET = r.GetSetMediaTrackInfo_String
local retval, tr_name = GETSET(tr, 'P_NAME', '', false) -- setNewValue false
local is_set = #tr_name:gsub(' ','') > 0
local set = GETSET(tr, 'P_NAME', is_set and '' or 'name', true) -- setNewValue true
end


function Get_Armed_Action()
-- relies on Esc() function
-- for full functionality requires build 6.71+ or SWS extension

-- only run the function if Action list window is open to force deliberate use 
-- and prevent accidents in case some action is already armed for other purposes
	if r.GetToggleCommandStateEx(0,40605) == 0 then -- Show action list
	return 'the action list is closed'
	end

local path = r.GetResourcePath()
local sep = path:match('[\\/]')

	local function script_exists(line, name)
	-- how paths external to \Scripts folder may look on MacOS
	-- https://github.com/Samelot/Reaper/blob/master/reaper-kb.ini
	local f_path = line:match(Esc(name)..' "(.+)"$') or line:match(Esc(name)..' (.+)$') -- path either with or without spaces, in the former case it's enclosed within quotation marks
	local f_path = f_path:match('^%u:') and f_path or path..sep..'Scripts'..sep..f_path -- full (starts with the drive letter and a colon) or relative file path; in reaper-kb.ini full path is stored when the script resides outside of the 'Scripts' folder of the REAPER instance being used // NOT SURE THE FULL PATH SYNTAX IS VALID ON OSs OTHER THAN WIN
	return r.file_exists(f_path)
	end

local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
['MIDI Inline Editor']=32062,['Media Explorer']=32063}

local cmd, section = r.GetArmedCommand() -- cmd is 0 when no armed action, empty string section is 'Main' section
r.ArmCommand(0, section) -- 0 unarm all

	local function space(length)
	return (' '):rep(length)
	end

	if cmd > 0 then
	local named_cmd = r.ReverseNamedCommandLookup(cmd) -- if the cmd belongs to a native action or is 0 the return value is nil
	local name, scr_exists, mess = false, true -- mess is nil // scr_exists is true by default to accomodate actions which can't be removed, if removed, such as custom actions, they can't be armed since they're removed directly from reaper-kb.ini unlike scripts which are only referenced there and appear in the Action list even after having been removed from their original location
		if cmd > 0 and not named_cmd and not r.kbd_getTextFromCmd and not r.CF_GetCommandText then -- native action is armed; without kbd_getTextFromCmd() which was added in build 6.71 and CF_GetCommandText() there's no way to retrieve native action name, only script and custom action names via reaper-kb.ini; without the sws extension cycle actions aren't available
		mess = space(4)..'Since REAPER build is older \n\n than 6.71 and the sws extension \n\n'..space(13)..'is not installed \n\n  only non-cycle custom actions \n\n'..space(6)..'and scripts are supported'
		elseif named_cmd and not r.kbd_getTextFromCmd and not r.CF_GetCommandText then -- without kbd_getTextFromCmd() which was added in build 6.71 and CF_GetCommandText() there's no way to retrieve the sws extension action names, only custom actions and scripts from reaper-kb.ini; without the sws extension cycle actions aren't available anyway
			for line in io.lines(path..sep..'reaper-kb.ini') do -- much quicker than using io.read() which freezes UI
			name = line:match('ACT.-("'..Esc(named_cmd)..'" ".-")') or line:match('SCR.-('..Esc(named_cmd)..' ".-")') -- extract command ID and name
				if name then
					if line:match('SCR') then -- evaluate if script exists
					scr_exists = script_exists(line, name)
					end
				name = name:gsub('Custom:', 'Script:', 1) -- make script data retrieved from reaper-kb.ini conform to the name returned by CF_GetCommandText() which prefixes the name with 'Script:' following their appearance in the Action list instead of 'Custom:' as they're prefixed in reaper-kb.ini file
				break end
			end
		elseif cmd > 0 then -- either build 6.71+ or sws extension is installed
	--	local build_6_71 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.71
		local GetCommandText = r.kbd_getTextFromCmd or r.CF_GetCommandText
		local section = sect_t[section] or sect_t[section:match('alt')]
		local args = r.kbd_getTextFromCmd and {cmd, section} or r.CF_GetCommandText and {section,cmd} -- the order of args in the functions differ
		name = cmd > 0 and GetCommandText(table.unpack(args))
			if name and name:match('Script') then
			local scr_name = name:gsub('Script:', 'Custom:') -- evaluate if script exists having made a replacement to conform to the reaper-kb.ini syntax
				for line in io.lines(path..sep..'reaper-kb.ini') do
					if line:match(Esc(scr_name)) then
					scr_exists = script_exists(line, '"'..scr_name..'"')
					break end
				end
			end
		end
	mess = mess or not scr_exists and '  the script doesn\'t exist \n\n at the registered location'
		if mess then
		return mess
		end
	return cmd, name, sect_t[section] or sect_t[section:match('alt')] -- OR sect_t['alt']
	end


end



function get_custom_action(cmdID)
-- used inside import_custom_action()
local path = r.GetResourcePath()
path = path..path:match('[\\/]')..'reaper-kb.ini'
cmdID = cmdID:sub(1,-#cmdID) == '_' and cmdID:sub(2) or cmdID -- strip leading underscore because in reaper-kb.ini it's absent
	for line in io.lines(path) do
		if line:match('ACT %d+ %d+ "'..cmdID..'"') then -- adding leading content because the custom action may be a part of another custom action and its ID will be captured inside code related to the latter
		return line:match('ACT %d+ (%d+) "'..cmdID..'" "Custom: (.+)" (.+)') -- return section, name and custom action sequence
		end
	end
end



function get_action_names(sect, custom_act_str, disabled_bitfield)
-- used inside import_custom_action()

local sect = sect+0 -- convert to number from string
local GetCommandText = r.kbd_getTextFromCmd or r.CF_GetCommandText
local bitfield = tonumber(disabled_bitfield..'', 16) -- convert to decimal // converting to string first in case disabled_bitfield is 0 because no bitfield is included in the custom action name

	if math.maxinteger == 0x7fffffff and 0x1fffffffffffff < bitfield then -- in case the disabled actions bitfield stored on a 64 bit system is loaded on a 32 bit system while storing over 52 actions (a max Lua v5.3+ can handle on a 32 bit system) // 0x7fffffff, i.e. 2^31, is the max signed integer Lua supports natively on a 32 bit system, but it can handle integers up to 0x1fffffffffffff i.e. 2^53-1 encoding them as floating point numbers // using numbers here to avoid calculation of rasing to power
	r.MB('    The system doesn\'t support\n\n disabled actions beyond first 52.'
	..'\n\n    Only as many will be restored.','WARNING',0)
	bitfield = 0x1fffffffffffff
	end
	
local names_menu, cntr = '', 0 -- counter is used to evaluate the bitfield in recalling originally disabled actions
	for cmdID in custom_act_str:gmatch('[^%s]+') do
		if cmdID then
		cntr = cntr+1
		cmdID = r.NamedCommandLookup(cmdID) -- convert into integer
		local args = r.kbd_getTextFromCmd and {cmdID, sect} or r.CF_GetCommandText and {sect, cmdID} -- the order of args in the functions differ
	local act_name = GetCommandText(table.unpack(args))
	local bit = 2^(cntr-1)
			if bit <= bitfield and bitfield&bit == bit -- was originally disabled // bit <= bitfield ensures that the bit value is within the system supported range (because the number of actions in the sequence may exceed system maximum bitwidth, i.e. over 63 on a 64 bit system and over 52 on a 32 bit system), otherwise 'number has no integer representation' error message will be thrown
			or unsupported_t[clear_tog_armed_indic(act_name)] -- clearing indicators if any
			or act_name:match(unsupported_t.to_mouse)
			or act_name:match(unsupported_t.at_mouse)
			or act_name:match(unsupported_t.under_mouse) -- unsupported_t is initialized before RUN_MENU() function; on loading, unsupported actions won't count against the disabled actions limit because their presence in the sequence means that the custom action wasn't exported from the script and thus doesn't contain disabled actions bitfield; if not deleted by the user, after the export they will be included in the total count of disabled actions
			then
			act_name = embellish_string(act_name,{9},1) -- strike through, want_spaces true
			end
		names_menu = names_menu..'|'..act_name
		end
	end
return names_menu
end



function import_custom_action(scr_cmdID)

local imported_exists = r.HasExtState(scr_cmdID,'IMPORTED')
local ext_state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION')
local s = (' '):rep(11)
-- the text depends on whether a custom action is imported on top of another custom action
-- or on top of actions added through arming
local YES = imported_exists and 
'custom action\n'..s..'(the name and the command ID\n'..s..'of the current one will be retained)'
or #ext_state > 0 and 
'list of actions\n'..s..'(the name and the command ID\n'..s..'of the imported action will be ignored)'
local NO = imported_exists and 'custom action' or #ext_state > 0 and 'list of actions'

local append

	if YES then -- or if NO
	local s = (' '):rep(11)
	local resp = r.MB('YES — Append to the current '..YES..'\n\nNO — Replace current '..NO,'PROMPT',3)
		if resp == 2 then return end -- user cancelled
	append = resp == 6
	end


::RELOAD::
local ret, cmdID = r.GetUserInputs('PASTE CUSTOM ACTION COMMAND ID (or submit empty to call file dialogue)',1,'COMMAND ID or empty,extrawidth=220','')
cmdID = cmdID:gsub('[%c%s]+','')

	if not ret then return end

local sect, name, act_cmdIDs

	if cmdID == '' then -- allow loading from .ReaperKeyMap when empty dialogue is submitted, only the 1st custom action will be loaded
	local last_path = r.GetExtState(scr_cmdID,'LAST_PATH')
	local sep = r.GetResourcePath():match('[\\/]')
	last_path = #last_path == 0 and r.GetResourcePath()..sep..'KeyMaps'..sep or last_path -- if last_path is empty use /KeyMaps as the default path
	local ret, file = r.GetUserFileNameForRead(last_path, 'Select .ReaperKeyMap file', '.ReaperKeyMap')
		if last_path ~= file:match('.+[\\/]') then -- update the last path
		r.SetExtState(scr_cmdID,'LAST_PATH',file:match('.+[\\/]'), false) -- persist false
		end
		if not ret then return end
		for line in io.lines(file) do
			if line:match('ACT %d+ %d+ ') then
			sect, cmdID, name, act_cmdIDs = line:match('ACT %d+ (%d+) "(.-)" "Custom: (.-)" (.*)\n?')			
			break
			end
		end
		if not sect then
		Error_Tooltip('\n\n the file doesn\'t contain \n\n   custom actions code \n\n', 1, 1, 200) -- caps, spaced true, x2 - 200 to move tooltip away from the mouse cursor so it doesn't block the OK button
		goto RELOAD
		end
	else -- use the command ID to retrieve from reaper-kb.ini
	local err = cmdID == '' and 'the field is empty' -- this option is redundant now after empty field was made to trigger file dialogue above
	or (#cmdID:gsub('_','') ~= 32 or cmdID:match('[^_]+'):match('[%u%p]+'))
	and '\t  the ID doesn\'t seem\n\n to belong to a custom action'
		if err then
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, 200) -- caps, spaced true, x2 - 200 to move tooltip away from the mouse cursor so it doesn't block the OK button
		goto RELOAD
		end
	sect, name, act_cmdIDs = get_custom_action(cmdID)
	end

local sect_t = {['32063'] = '"Media Explorer"', ['32062'] = '"MIDI Inline Editor"'}

local cust_act_name, act_names_menu, act_ids, section, cust_act_ID = ext_state:match(('(.-)\n\n'):rep(4)..'(.-)$') -- will be used if user has opted for appending to existing custom action; last capture with non-greedy operator bacause if the actions were added by arming them and never exported the command ID will be empty string

local err = not sect and 'the custom action wasn\'t found'
or sect ~= '0' and sect ~= '32060' and 'custom actions from \n\n section '..sect_t[sect]..' \n\n are not supported'
or append and sect ~= section and 'new custom action section \n\n\tdiffers from that \n\n\tof the current one'

	if err then return err end

local disabled_bitfield = name:match('___0x(%x+)') or 0
name = name:match('(.+)___0x%x+') or name -- strip of disabled actions bitfield if any

local names_menu = get_action_names(sect, act_cmdIDs, disabled_bitfield)

	if append then
	name, names_menu, act_cmdIDs, cmdID = cust_act_name, act_names_menu..'|'..names_menu, act_ids..' '..act_cmdIDs, cust_act_ID -- sect is the same because merger of custom actions from different sections isn't allowed, command ID of the originally imported custom action as well as its name are retained unless the existing actions were added by arming and have never been exported in which case cust_act_ID will be an empty string
	end

-- the custom action command ID can be imported either with or without the leading underscore, depending on the user input
-- this is taken into account in export_as_keymap()
r.SetExtState(scr_cmdID,'CUSTOM_ACTION', name..'\n\n'..names_menu..'\n\n'..act_cmdIDs..'\n\n'..sect..'\n\n'..cmdID, false) -- persist false
r.SetExtState(scr_cmdID,'IMPORTED','1',false) -- persist false // will be used in custom action name lookup and in appending to custom action imported earlier

end



function add_armed_action(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID, sett_t)

local cmd, name, section = Get_Armed_Action() -- cmd is integer or string if error message

local err = tonumber(cmd) and ( unsupported_t[cmd] or name:match(unsupported_t.at_mouse) 
or name:match(unsupported_t.under_mouse) or name:match(unsupported_t.to_mouse) )
and 'the action is not supported \n\n\t  in custom actions' -- the table is intialized before RUN_MENU() function
or cmd and not tonumber(cmd) and cmd -- returned as error message

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, gfx.clienttoscreen(0,0)) -- caps, spaced true // coordinates match those of the click pad gfx window so the tooltip overlays it
	cmd = nil -- reset to exit below
	end

	if not cmd then return
	elseif cust_act_section and section..'' ~= cust_act_section then -- convert section to string because custom action section number is stored as a string // cust_act_section can be nil if no custom action was imported prior to adding an action
	Error_Tooltip('\n\n the action and the custom action \n\n belong to different sections\n\n', 1, 1, gfx.clienttoscreen(0,0)) -- caps, spaced true // coordinates match those of the click pad gfx window so the tooltip overlays it
	else
	local checked_action_idx
	-- search for the checkmarked action index to add the new action after it
		if act_names_menu_t then -- will be nil if no custom action was imported prior to adding an action
			for k, act_name in ipairs(act_names_menu_t) do
				if act_name:match('^!') then
					if sett_t.checkmark_armed then
					act_names_menu_t[k] = act_name:sub(2) -- if setting to checkmark added action is enabled, clear current checkmark
					end
				checked_action_idx = k break
				end
			end
		end

	act_IDs_t, act_names_menu_t = act_IDs_t or {}, act_names_menu_t or {} -- table vars will be nil if no custom action was imported prior to adding an action
	checked_action_idx = checked_action_idx or sett_t.add_to_top and 0 or #act_names_menu_t -- if no checked action the new one will be added to the top of the list or to its bottom depending on the setting
	table.insert(act_IDs_t,checked_action_idx+1,cmd) -- insert after the checked action
	local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to insert armed action after the marked one than a string retrieved from 'CUSTOM_ACTION' extended state
	table.insert(act_names_menu_t,checked_action_idx+1,name) -- insert after the checked action
		if sett_t.checkmark_armed then
		act_names_menu_t[checked_action_idx+1] = '!'..name -- add checkmark
		end

	-- update ext state data
	local cust_act_name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^(.-)\n\n') -- retrieve custom action name here to not clutter the arg list
	cust_act_name = cust_act_name and #cust_act_name > 0 and cust_act_name or '' -- add name placeholder if actions were added by arming them and haven't been exported yet in which case no custom action name will have been stored yet

	r.SetExtState(scr_cmdID,'CUSTOM_ACTION',cust_act_name..'\n\n'..table.concat(act_names_menu_t,'|')
	..'\n\n'..act_ids..'\n\n'..(cust_act_section or section)..'\n\n'..(cust_act_ID or ''), false) -- persist false // if no custom action was imported prior to adding an action cust_act_section var will be nil so the custom action section will be determined by the section of the first imported action; likewise cust_act_ID, if a custom action wasn't imported it will be nil so fall back on empty string, it will be generated at the export stage
	return true -- to trigger menu reload to display the action just added
	end

end


function remove_action_or_all(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID, mode, settings_t)

local one, all = mode == 1, mode == 2
local mess

	if all then
	mess = {'  All actions are about to be removed.\n\n'..(' '):rep(12)
	..'The result is irreversible,\n\nunless they\'ve alerady been converted\n\n'
	..'\tinto a custom action.', 'WARNING',1}
	elseif one then
	mess = {'Confirm removal of the marked action.','PROMPT',1}
	end
	
	if r.MB(table.unpack(mess)) == 2 then return end -- user canceled

-- search for the checked action index to remove it
local found
	for k, act_name in ipairs(act_names_menu_t) do
		if one and act_name:match('^!') then
		table.remove(act_names_menu_t,k)
		table.remove(act_IDs_t,k)		
			if settings_t.inherit_checkmark then -- checkmark next action
			local next_act_idx = k+1 == #act_names_menu_t and 1 or k -- k is because after deletion the next action assumes position of the deleted one
			local next_act_name = act_names_menu_t[next_act_idx]
			act_names_menu_t[next_act_idx] = '!'..next_act_name
			end
		found = 1
		break end
	end

	if one and not found then return 'no marked actions' end

-- update ext state data
local name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^.-\n\n') -- retrieve here to not clutter the arg list // if name hasn't been stored yet it will be empty string
local act_ids = not all and #act_IDs_t > 0 and table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
local data = all and '' or one and #act_IDs_t > 0 and name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids..'\n\n'
..cust_act_section..'\n\n'..cust_act_ID or '' -- if after removal no action is left store empty string
r.SetExtState(scr_cmdID,'CUSTOM_ACTION',data, false) -- persist false

	if data == '' then -- clear this as well in case imported custom action has been cleared
	r.DeleteExtState(scr_cmdID, 'IMPORTED', true) -- persist true
	end

end



function duplicate_action(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID, mode, sett_t)
-- mode arg is used in move_up_or_down() and remove_action_or_all() and is irrelevant here
-- but included here because it's used in a table of arguments passed to all management operation 
-- functions inside RUN_MENU()

-- search for the checked action index to duplicate it
	for k, act_name in ipairs(act_names_menu_t) do
		if act_name:match('^!') then
		table.insert(act_names_menu_t,k+1,act_name:sub(2)) -- insert after the checked action, removing the checkmark
		table.insert(act_IDs_t,k+1,act_IDs_t[k])
			if sett_t.checkmark_dup then
			act_names_menu_t[k+1] = act_name -- re-add with checkmark
			act_names_menu_t[k] = act_name:sub(2) -- OR act_name:match('^!(.+)') -- clear from previous instance			
			end
		break end
	end

-- update ext state data
local name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^.-\n\n') -- retrieve here to not clutter the arg list // if name hasn't been stored yet it will be empty string
local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
r.SetExtState(scr_cmdID,'CUSTOM_ACTION', name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids..'\n\n'
..cust_act_section..'\n\n'..cust_act_ID, false) -- persist false

end



function move_up_or_down(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID, mode)

local up, down = mode == 1, mode == 2

-- search for the checked action index to remove it
	for k, act_name in ipairs(act_names_menu_t) do
		if act_name:match('^!') then
		local k_new = up and (k == 1 and #act_names_menu_t or k-1)
		or down and (k == #act_names_menu_t and 1 or k+1) -- k+1, even though normally k+2 would be required because table.insert pushes the current value at index k+1 farther and adds the inserted value in its stead thereby maintaining the current order where the target action precedes the one it's supposed to replace, after deletion of the value at the old index k, the table shortens and k needs to be advanced by 1 place only, this also simplifies down movement when there're only 2 actions in the list, because k+2 would cause removal of the action which is meant to be pushed to position before the moved action
		local act_cmdID = act_IDs_t[k]
		-- remove and insert in this order
		table.remove(act_names_menu_t,k,act_name)
		table.insert(act_names_menu_t,k_new,act_name)
		table.remove(act_IDs_t,k,act_cmdID)
		table.insert(act_IDs_t,k_new,act_cmdID)
		break end
	end

-- update ext state data
local name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^.-\n\n') -- retrieve here to not clutter the arg list // if name hasn't been stored yet it will be empty string
local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
r.SetExtState(scr_cmdID,'CUSTOM_ACTION', name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids..'\n\n'
..cust_act_section..'\n\n'..cust_act_ID, false) -- persist false

end


function toggle_disable_action(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID)

	for k, act_name in ipairs(act_names_menu_t) do
		if act_name:match('^!') then
			if act_name:match('\204\182') then -- OR '\xCC\xB6', strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336) // disabled
			act_name = act_name:gsub('\204\182','') -- clear
				if unsupported_t[clear_tog_armed_indic(act_name:sub(2))] -- stripping of the ckeckmark and clearing indicators if any; prevent re-enabling
				or act_name:match(unsupported_t.at_mouse) 
				or act_name:match(unsupported_t.under_mouse)
				or act_name:match(unsupported_t.to_mouse)
				then 
				return 'the action is not supported' -- the table is initialized before RUN_MENU() function
				end
			else
			act_name = embellish_string(act_name,{9},1) -- strikethrough, want_spaces true
			end
		act_names_menu_t[k] = act_name -- resave
		-- update ext state data
		local name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^.-\n\n') -- retrieve here to not clutter the arg list // if name hasn't been stored yet it will be empty string
		local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
		r.SetExtState(scr_cmdID,'CUSTOM_ACTION', name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids..'\n\n'
		..cust_act_section..'\n\n'..cust_act_ID, false) -- persist false
		return
		end
	end

end


function re_enable_all_del_disabled_actions(scr_cmdID, act_names_menu_t, act_IDs_t, cust_act_section, cust_act_ID, mode)

local re_enable, delete = mode == 1, mode == 2

	for k = #act_names_menu_t, 1, -1 do -- in reverse due to delete if true
	local act_name = act_names_menu_t[k]
		if act_name:match('\204\182') then -- OR '\xCC\xB6', strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336) // disabled
			if re_enable then
			act_names_menu_t[k] = act_name:gsub('\204\182','') -- OR '\xCC\xB6', clear
			elseif delete then
			table.remove(act_names_menu_t,k)
			table.remove(act_IDs_t,k)
			end
		end
	end

local mess
	
	if delete and #act_names_menu_t == 0 then -- all action items have been removed because all were disabled
	local s = ' '
	mess = {s:rep(8)..'Since all actions are disabled\n\n'..s:rep(9)..'all are about to be removed.\n\n'..s:rep(12)
	..'The result is irreversible,\n\nunless they\'ve alerady been converted\n\n\tinto a custom action.','WARNING',1}
	elseif delete then
	mess = {'Confirm removal of disabled actions.','PROMPT',1}
	end
	
	if mess and r.MB(table.unpack(mess)) == 2 then return end -- user canceled

	-- update ext state data	
	local name = r.GetExtState(scr_cmdID,'CUSTOM_ACTION'):match('^.-\n\n') -- retrieve here to not clutter the arg list // if name hasn't been stored yet it will be empty string
	local act_ids = #act_IDs_t > 0 and table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
	local data = delete and #act_names_menu_t == 0 and '' or name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids..'\n\n'
	..cust_act_section..'\n\n'..cust_act_ID -- if after removal no action is left store empty string
	r.SetExtState(scr_cmdID,'CUSTOM_ACTION', data, false) -- persist false
	
	if data == '' then -- clear this as well in case imported custom action has been cleared
	r.DeleteExtState(scr_cmdID, 'IMPORTED', true) -- persist true
	end

end


function en_de_code_disabled_actions(act_names_menu_t, bitfield)
-- used in export_as_keymap() and import_custom_action()
-- only stores the max of 63 values on a 64 bit systems
-- and 52 on 32 bit systems
-- https://stackoverflow.com/questions/46442411/how-big-can-a-64-bit-unsigned-integer-be
-- https://stackoverflow.com/questions/6003492/how-big-can-a-64bit-signed-integer-be

local limit = math.maxinteger == 9223372036854775807 and 63 or 52 -- OR math.maxinteger == 2^63 // setting the limit depending on the system bit width, because a max signed integer Lua v5.3+ can handle on a 32 bit system is 9007199254740991 or 0x1fffffffffffff, i.e. 2^53-1, in practical terms of conversion into hex value with dec2hex() function it's 2^52 0xfffffffffffff which prevents loss of precision, so the function can store a max of first 52 actions, while on a 64 bit system it's 9223372036854775807 or 0x7fffffffffffffff, i.e. 2^63, and a max of first 63 actions // only a max of FIRST 63 or 52 actions respectively can be stored because the storage depends on the action position in the sequence which corresponds to the bit position in the bitfield, and depending on the system the integer created by bit setting cannot exceed 2^63 or 2^52 respectively // using numbers here to avoid calculation of rasing to power

local s = ' '

	if not bitfield then -- encode
	local bitfield = 0
		for k, act_name in ipairs(act_names_menu_t) do
			if act_name:match('\204\182') then -- OR \xCC\xB6 strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336)
				-- must be placed before bit setting in case the limit has been reached while there're still unaccounted for disabled actions, if it were placed after the setting it wouldn't be possible to ascertain that there're unaccounted for disabled actions because that could have been the loop end, so a counter would have to be employed
				if k > limit then return
			-- OR
			--	if bitfield == 9223372036854775807 then return -- only valid for 64 bit system
				s:rep(7)..'The system doesn\'t support\n\n'..s:rep(8)..'storage of disabled actions'
				..'\n\n'..s:rep(9)..'at index greater than '..limit..'.'
				end
			bitfield = bitfield|2^(k-1)
			end
		end
	return bitfield
	------ THIS CONDITION ISN'T USED IN THE SCRIPT
	else -- decode
		for k, act_name in ipairs(act_names_menu_t) do
		local bit = 2^(k-1)
			if bitfield&bit == bit then
			act_names_menu_t[k] = embellish_string(act_name,{9}, 1) -- strikethrough, want_spaces true
			end
		end
	return act_names_menu_t
	end
end


function get_first_non_disabled_action(act_names_menu_t, next_act_idx)
-- next_act_idx is index of action item following the checkmarked one
	
	if next_act_idx > #act_names_menu_t -- custom action sequence has been reached
	or not act_names_menu_t[next_act_idx]:match('\204\182') then -- OR '\xCC\xB6' strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336), non-disabled, keep the same index
	return next_act_idx
	else -- disabled, look for the first non-disabled
		for i = next_act_idx+1, #act_names_menu_t do
			if not act_names_menu_t[i]:match('\204\182') then -- OR '\xCC\xB6'
			return i
			end
		end
	end

-- if non-disabled action item wasn't found, return this to trigger 'end of custom action action' message
return #act_names_menu_t+1

end



function parse_custom_action(scr_cmdID)

local ext_state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION') -- the data is stored in import_custom_action()
local cust_act_name, names_menu, act_ids, section, cust_act_ID = ext_state:match(('(.-)\n\n'):rep(4)..'(.*)') -- * operator because command ID will be absent if action were only added by arming them

local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
['MIDI Inline Editor']=32062,['Media Explorer']=32063}

local t = {names={}, ids={}}
	if act_ids then
		for cmdID in act_ids:gmatch('[^%s]+') do -- OR '%S'
			if cmdID then
			t.ids[#t.ids+1] = r.NamedCommandLookup(cmdID) -- convert to integer, the function supports numeric IDs as strings
			end
		end
		for name in names_menu:gmatch('[^|]+') do
			if name then
			local idx = #t.names+1
			local toggle_state = r.GetToggleCommandStateEx(section+0, t.ids[idx])
			local toggle_indicator = toggle_state == 1 and '▪' or toggle_state == 0 and '◦' or '' -- different shapes because in the menu the same shape blank is indistingushable from the filled one
			local name, cnt = name:gsub('[▪◦]+', toggle_indicator, 1)
			name = name..(cnt == 0 and #toggle_indicator > 0 and ' '..toggle_indicator or '') -- if the name hasn't yet been marked with the indicator, append, otherwise append nothing because it has been updated in the line above
			local cmd, sect = r.GetArmedCommand() -- armed_section is empty string if Main 0
			sect = sect_t[armed_section] or sect_t['alt']
			local armed = t.ids[idx]+0 == cmd and section+0 == sect -- only if the armed action belongs to the same section as the first added or imported custom action, will always be true because actions from other sections cannot be added/imported
			local arm_marked = name:match('.+%s%(A%)$')
			name = armed and (not arm_marked and name..' (A)' or name) or arm_marked and name:sub(1,-5) or name -- -5 to trim (A) with preceding space
			t.names[idx] = name
			end
		end
	return t.names, t.ids, section, cust_act_ID
	end

end


function generate_cust_act_ID()
-- the ID is a GUID, thanks to schwa https://forums.cockos.com/showthread.php?t=291057#12
-- https://stackoverflow.com/a/2867925/8883033 how GUID is constructed
return r.genGuid(''):lower():gsub('[%-{}]+','') -- convert to lower register and remove hyphens and curly brackets
end


function export_as_keymap(scr_cmdID, act_names_menu_t)

local ext_state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION')
local cust_act_name, names_menu, act_ids, section, cust_act_ID = ext_state:match(('(.-)\n\n'):rep(4)..'(.*)') -- * operator because command ID will be absent if actions were only added by arming them

local bitfield = en_de_code_disabled_actions(act_names_menu_t, bitfield) -- bitfield arg is nil, encoding, returns an error message if the number of disabled actions cannot fit within the max integer supported by the system (63 on a 64 bit system and 31 on a 32 bit one)
bitfield = tonumber(bitfield) and (bitfield > 0 and dec2hex(bitfield) or '') or bitfield -- will end up as empty string if 0 because no disabled actions or as an error message string if the count exceeds the system limit

	if #bitfield > 0 then -- will be true both when there're disabled action and when their count exceeds the system limit
	local resp = r.MB('There\'re disabled actions. Choose the following options:\n\n'
	..'YES —\tKeep the disabled actions\n\t(only useful if the custom action\n\twon\'t be imported '
	..'into the Action list).\n\tTheir disabled status will be recalled\n\ton re-import into the script.'
	..'\n\nNO —\tDelete the disabled actions\n\t(useful if this exported version\n\t'
	..'will be imported into the Action list).','PROMPT',3)
		if resp == 2 then return -- cancelled by the user
		elseif resp == 7 then -- don't keep
		local to_remove_t = {}
			for k, act_name in ipairs(act_names_menu_t) do
				if act_name:match('\204\182') then -- OR '\xCC\xB6' strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336)
				to_remove_t[k] = '' -- dummy value
				end
			end
		-- doing it this way instead of removing and extracting from act_IDs_t because the table holds numeric command IDs as apposed to named which are listed in the custom action code
		local i = 0
		act_ids = act_ids:gsub('[%w%p]+%s', function(c) i=i+1 return to_remove_t[i] and '' or c end ) -- if iterator value matches index of a disabled action return empty string to remove
		bitfield = '' -- won't be stored in the custom action name
		else -- store disabled actions
			if not bitfield:match('0x%x+') then -- not a hex value but the error message of excess in the number of disabled action over the system limit
			r.MB(bitfield,'ERROR',0)
			return end
		bitfield = ('_'):rep(3)..bitfield
		end
	end
	
local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local code, act_ids_orig, ret, user_name

	-- if a custom action existing in the Action list was imported
	-- find out whether its composition has changed and get its data except action IDs
	if #cust_act_ID > 0 then -- OR #cust_act_name > 0 look up the original sequence // cust_act_ID and cust_act_name may be empty strings if actions were only added by arming them and never exported, at the first export the generated command ID and user chosen name will be then stored and reused in subsequent exports
	local path = path..sep..'reaper-kb.ini'
	local cust_act_ID = cust_act_ID:sub(1,-#cust_act_ID) == '_' and cust_act_ID:sub(2) or cust_act_ID -- strip leading if any underscore because in reaper-kb.ini it's absent because custom action ID could have been imported along with it in import_custom_action()
		for line in io.lines(path) do
			if line:match('ACT %d+ %d+ "'..cust_act_ID..'"') then -- adding leading content because the custom action may be a part of another custom action and its ID will be captured inside code related to the latter
			code, act_ids_orig = line:match('(ACT %d+ %d+ "'..cust_act_ID..'" "Custom:.+") (.+)')
			break end
		end
		if act_ids == act_ids_orig then
		return 'the action composition \n\n\thasn\'t changed'
		end
	end

	if code then -- custom action imported from the Action list whose original code was retrieved above
	code = code:gsub('Custom:.+', function(c) return c:sub(1,#c-1)..bitfield..'"' end)..' '..act_ids -- append updated action IDs sequence
	else -- construct code and generate a named ID
	::RELOAD::
	ret, user_name = r.GetUserInputs('GIVE IT A NAME',1,'Custom action name:,extrawidth=200', cust_act_name) -- autofill with the last chosen name if exported at least once before
		if not ret then return
		elseif #user_name:gsub(' ','') == 0 then
		Error_Tooltip('\n\n the name cannot be empty \n\n', 1, 1, 200) -- caps, spaced true, x2 - 200 to move tooltip away from the mouse cursor so it doesn't block the OK button
		goto RELOAD
		end
	local cmdID = #cust_act_ID > 0 and cust_act_ID or generate_cust_act_ID() -- if actions were exported once, the generated command ID will have been stored so re-use it
	code = 'ACT 1 '..math.floor(section)..' "'..cmdID..'" "Custom: '..user_name..bitfield..'" '..act_ids -- truncating the trailing decimal 0 from section integer

		if cmdID ~= cust_act_ID then -- OR 'if #cust_act_ID == 0' // only save once, when the command ID was generated, so it can be re-used in subsequent exports to prevent accrual of the cmdID, otherwise concatenation of all elements would be required instead, e.g. names_menu..'\n\n'..act_ids etc.
		r.SetExtState(scr_cmdID,'CUSTOM_ACTION', ext_state:gsub('\n\n', user_name..'%0', 1)..cmdID, false) -- persist false // store custom action name and custom action command ID; ext_state is preceded with double new line char added in add_armed_action() so these must be appended with the custom action name, ext_state already ends with double new line char added in add_armed_action() so none is needed before cmdID
		end

		if #cust_act_name > 0 and user_name ~= cust_act_name then -- update custom action name if user changed it, by this state cust_act_name will have already been stored
		cust_act_name = Esc(cust_act_name)
		r.SetExtState(scr_cmdID,'CUSTOM_ACTION', ext_state:gsub(cust_act_name, user_name, 1), false) -- persist false // store or update custom action name, and store custom action command ID
		end

	cust_act_name = user_name

	end

	local function space(length)
	return (' '):rep(length)
	end

-- Custom action name in sanitized form is used as the file name

cust_act_name = sanitize_file_name(cust_act_name) -- before using as file name

local timestamp = os.date("%d.%m.%y %H-%M-%S")
local generic_name = ''

	if not cust_act_name then -- will be nil if all characters in the name were illegal and therefore removed inside sanitize_file_name(), pretty unlikely
	generic_name = space(8)..'A generic name has been applied to the file.\n\n'
	cust_act_name = 'Custom action step-through previewer output '..timestamp
	end

local f_path = path..sep..'KeyMaps'..sep..cust_act_name..'.ReaperKeyMap'
local overwrite

	if r.file_exists(f_path) then -- without direct user involvement only possible with imported custom action which was already exported earlier
	local name = #cust_act_ID > 0 and 'custom action' or 'chosen'
	local resp = r.MB('The file with the '..name..' name already exists.\n\nTo overwrite click " YES "\n\nTo create a new one click " NO "','PROMPT',3) -- 3 - yes/no/cancel
		if resp == 2 then return -- cancelled
		elseif resp == 7 then -- No (create new), update the file name
		f_path = path..sep..'KeyMaps'..sep..cust_act_name..' '..timestamp..'.ReaperKeyMap'
		else
		overwrite = 1
		end
	end

local f_path, mess = sanitize_file_path(f_path) -- returns both as nils if exceeds 256 even if truncated

	if f_path then

	local f = io.open(f_path,'w')
	f:write(code)
	f:close()

	local cust_act_name = not ret and #(generic_name..mess) == 0 and ' named after\n\n\tthe custom action' or '' -- will be displayed when imported custom action was exported, ret will be nil if imported custom action name is used, because ret stems from user cutom action name input dialogue which is only called when the actions have been added one by one rather than retrieved from an existing custom action; only add if non-generic and non-truncated name is applied
	local action = overwrite and 'updated' or 'placed'
	local mess = r.file_exists(f_path) and {generic_name..mess..space(overwrite and 8 or 10)
	..'The .ReaperKeyMap file'..cust_act_name..' has been '..action..'\n\nin the /KeyMaps folder in REAPER resource directory.\n\n'
	..space(10)..'Click YES to open the resource directory.',4}
	or {'.ReaperKeyMap file creation has failed\n\n'..space(11)..'for uknown reasons. Sorry!',0}

	mess[1] = #cust_act_name > 0 and mess[1]:gsub('The .ReaperKeyMap','    %0') or mess[1] -- adjust the top line position when exporting the imported custom action to account for additional text

		if r.MB(mess[1], 'REPORT', mess[2]) == 6 then -- open resource directory
		r.Main_OnCommand(40027, 0) -- Show REAPER resource path in explorer
		end

	end

end



-- used inside store_undo_sequence(), undo(), update_undo_state_on_menu_load()
-- get_action_names(), toggle_disable_action()
function clear_tog_armed_indic(str)
-- black small square: \xE2\x96\AA OR \226\150\170, white bullet: \xE2\x9\xA6 OR \226\151\166
--	local bl_small_sq, white_bul = '\226\150\170', '\226\151\166' -- used to indicate toggle state in the action name
--	return str:gsub('['..bl_small_sq..white_bul..']*','')
	if str then
	str = str:gsub('%s[▪◦]+', '')
	str = str:match('%s%(A%)$') and str:sub(1,-5) or str -- -5 to trim (A) with preceding space
	end
return str
end



function undo(scr_cmdID, act_names_menu_t, act_IDs_t, section, menu)

	local function un_arm(act_cmdID, section, is_armed)
	local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
	['MIDI Inline Editor']=32062,['Media Explorer']=32063}
	local cmd, sect = r.GetArmedCommand() -- sect is empty string if Main 0
	sect = sect_t[sect] or sect_t['alt']
		if cmd == act_cmdID and sect == section+0 and not is_armed then		
		r.ArmCommand(0, section+0) -- 0 unarm all
		elseif is_armed then
		r.ArmCommand(act_cmdID, section+0)
		end
	end

	local function toggle(cmdID, section, undone_toggle_state)
	-- change toggle state of the action is a toggle because it's not stored in REAPER undo history and thus isn't undone
	local toggle_state = r.GetToggleCommandStateEx(section+0, cmdID)
		if toggle_state ~= -1 and toggle_state == undone_toggle_state then -- change toggle state if after undo it happens to be the same as before that which for toggle actions isn't possible because they change their state when executed and the state before the execution restored by the undo must differ from the one indicated in the undo point name
		local ACT = section == '0' and r.Main_OnCommand or MIDIEditor_GetActiveAndVisible() and r.MIDIEditor_LastFocused_OnCommand
		local islistviewcommand = section == '32061' or r.MIDIEditor_GetMode(r.MIDIEditor_GetActive()) == 1		
		ACT(cmdID, section == '0' and 0 or islistviewcommand) -- in Main_OnCommand 2nd argument is 0, in MIDIEditor_LastFocused_OnCommand it's islistviewcommand
		end
	end

r.Undo_DoUndo2(0)
local undone = r.Undo_CanRedo2(0)
local prev = r.Undo_CanUndo2(0) -- the action the undo history has landed on after the undo, the next to be undone
local both = undone and prev and undone:match('^%d+#') and prev:match('^%d+#')

local undone_idx, prev_idx = undone and undone:match('^(%d+)#'), prev and prev:match('^(%d+)#')
local undone_toggle_state = undone and (undone:match('▪') and 1 or undone:match('◦') and 0 or -1) -- not 100% failproof because the undo point name may be truncated if long and the toggle state indicator at its very end will be lost
local prev_armed = prev and prev:match('%s%(A%)$') -- not 100% failproof for the same reason as above but with regard to armed (A) indicator which is also tagged to the very end

-- clear toggle and armed indicators if any to simplify comparison because these are likely not to match
undone = undone and clear_tog_armed_indic(undone:match('^.-#(.+)')) -- excluding the index and the hash sign
prev = prev and clear_tog_armed_indic(prev:match('^.-#(.+)'))

	if both then
		for k = #act_names_menu_t, 1, -1 do -- here doesn't matter whether or not in reverse because the actions in the sequence are selected by their indices extracted from undo point names they'e prefixed with in the format x#... // the loop is only really needed to clear the checkmark
		local action = act_names_menu_t[k]
		local action = action:match('^!') and action:sub(2) or action -- removing checkmark is any, unlikely but just in case
			if k == undone_idx+0 and clear_tog_armed_indic(action):match(Esc(undone)) then -- using this method to accomodate toggle actions which are suffixed with toggle state indicator and which are likely not to match, evaluating by matching because undo point name may be truncated if too long so won't be equal to the original action name // 'found' variable ensures that if there're identical actions only the first found one and the closest to the loop start gets processed
			act_names_menu_t[k] = action -- without the checkmark because the action has been undone
			toggle(act_IDs_t[k], section, undone_toggle_state) -- change toggle state of the action is a toggle because it's not stored in REAPER undo history and thus isn't undone // act_IDs_t table contains numeric command IDs which are converted inside parse_custom_action() in RUN_MENU() function			
			elseif k == prev_idx+0 and clear_tog_armed_indic(action):match(Esc(prev)) then
			act_names_menu_t[k] = '!'..action -- with the checkmark because the sequence has moved to the prev action
			un_arm(act_IDs_t[k], section, prev_armed) -- change armed state because it's not stored in REAPER undo history // if undo point was created when the action was armed, arm it and vice versa, the approach is different from restoring toggle state because an action changes its toggle state when it's executed and its toggle indicator in the undo point name reflects the state after execution implying that prior to that the state was different, while armed an action can only be by the dedicated option from outside or by the action 'Action: Arm next action', hence armed state isn't changed for the undone action because it cannot change by itself
			elseif k ~= undone_idx+0 and k ~= prev_idx+0 and act_names_menu_t[k]:match('^!') then -- clearing checkmark from all the rest // using table value for evaluation because checkmark has been cleared from action var above // it's possible that two action items be checkmarked while undoing if the action item corresponding to 'prev' undo point is later in the action sequence than the currently checkmarked item which was checkmarked manually
			act_names_menu_t[k] = action
			end		
		end

	else -- either both or one undo point weren't created by the script

	local UNDO = '&U\204\178NDO' -- with utf-8 Combining Low Line (818) character which underscores the quick access shortcut

		if menu:match('|'..UNDO..'$') then
		menu = menu:gsub('|'..UNDO,'|#'..UNDO,1) -- if UNDO item was active gray it out
		end

		if undone_idx+0 == 1 then
		-- delete the value stored in skip_next_act_and_set_cc() and used in skip_next_action_if()
		-- action simulator functions when the custom action has been fully undone
		-- extended state isn't saved with undo point so cannot be undone the regular way
		r.DeleteExtState(cmdID,'CC_PARM',true) -- persist true
		end
		
		if undone then -- the last action in the sequence has been undone, i.e. one undo point wasn't created by the script, the prev
		-- restore the name format in case the action is toggle and remove checkmark from all
			for k, action in ipairs(act_names_menu_t) do			
			local action = action:match('^!') and action:sub(2) or action -- removing checkmark if any, unlikely but just in case
				if k == undone_idx+0 and clear_tog_armed_indic(action):match(Esc(undone)) then -- using this method to accomodate toggle actions which are suffixed with toggle state indicator, see above
				act_names_menu_t[k] = action -- without the checkmark because the action has been undone
				toggle(act_IDs_t[k], section, undone_toggle_state) -- change toggle state of the action is a toggle because it's not stored in REAPER undo history and thus isn't undone // act_IDs_t table contains numeric command IDs which are converted inside parse_custom_action() in RUN_MENU() function
				elseif act_names_menu_t[k]:match('^!') then -- clearing checkmark from all the rest // using table value for evaluation because checkmark has been cleared from action var above // it's possible that two action items be checkmarked while undoing if the action item corresponding to 'prev' undo point is later in the action sequence than the currently checkmarked item which was checkmarked manually
				act_names_menu_t[k] = action -- re-storting without checkmark which was removed at the loop start
				end
			end
		end

	end

return menu, act_names_menu_t	
	
end



function update_undo_state_on_menu_load(scr_cmdID, act_names_menu_t, menu)
local undo = r.Undo_CanUndo2(0)
local redo = r.Undo_CanRedo2(0)
local to_undo_idx = undo and undo:match('^(%d+)#')
local fully_undone = redo and redo:match('^1#')
undo = undo and clear_tog_armed_indic(undo:match('^.-#(.+)')) -- excluding the index and the hash sign and clearing toggle indicator if any
local act_name = to_undo_idx and act_names_menu_t and act_names_menu_t[to_undo_idx+0]
local matches = act_name and act_name:match(Esc(undo)) -- evaluating by matching because undo point name may be truncated if too long so won't be equal to the original action name
local UNDO = '&U\204\178NDO' -- with utf-8 Combining Low Line (818) character which underscores the quick access shortcut
	if not undo or not matches	then
		if fully_undone then -- if current (not yet undone) undo point in REAPER undo history wasn't created by the script but the next one was and it's the 1st action in the sequence that means that the sequence was fully undone so the checkmark can be cleared, it won't be cleared if the sequence in the undo history was simply interrupted by a stray action so the last executed/undone action will remain checkmarked in the action menu
		local clear = act_names_menu_t and clear_action_checkmark_and_get_idx(act_names_menu_t)
		end
	menu = menu:gsub('|'..UNDO, '|#'..UNDO,1) -- gray out of the active undo point in REAPER undo history wasn't created by the script
	else
		if menu:match('|#'..UNDO) then -- activate UNDO item as soon as undo point created by the script appears in REAPER undo history
		menu = menu:gsub('|#'..UNDO, '|'..UNDO,1)
		end
	end
return menu, act_names_menu_t

end



function lookup_custom_action_props(scr_cmdID)
local ext_state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION')
local name, sect = ext_state:match('^(.-)\n'), ext_state:match('.+\n(.+)\n\n')
sect_t = {[0] = 'Main', [32060] = 'MIDI Editor', [32061] = 'MIDI Event List Editor'}
r.GetUserInputs('IMPORTED CUSTOM ACTION PROPERTIES',2,'Action list section:,Name:,extrawidth=200',sect_t[sect+0]..','..name)
end



function un_grayout_menu_items(scr_cmdID, menu, act_names_menu_t)

local ext_state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION')
local cust_action = #ext_state > 0
local imported = r.HasExtState(scr_cmdID, 'IMPORTED') -- stored in import_custom_action(), removed in remove_action_or_all()

-- gray-out toggle
	if imported then
	menu = menu:gsub('#LOOK UP IMPORTED', 'LOOK UP IMPORTED',1)
	else
	menu = menu:gsub('|LOOK UP IMPORTED', '|#LOOK UP IMPORTED',1) -- pipe here is an anchor to ensure that if there's already hash # sign between it and the menu item name, no replacement will occur
	end

local t = {'EXPORT AS','REMOVE ALL','REMOVE ALL DISABLED','RE-ENABLE ALL','REMOVE MARKED','DUPLICATE MARKED', 
'(U&N\204\178)DISABLE MARKED', 'MOVE MARKED ACTION U&P\204\178','MOVE MARKED ACTION &D\204\178OWN', '&R\204\178UN ACTIONS', '&U\204\178NDO'} -- including utf-8 Combining Low Line (818) character which underscores the quick access shortcut // MOVE UP quick access shortcut is 'p' rather than 'u' because the latter is allocated to UNDO and these would clash when operations menu is exploded into the main menu

	if not cust_action then -- gray out
	r.DeleteExtState(scr_cmdID,'UNDO_HISTORY',true) -- persist true
		for k, item in ipairs(t) do
		local esc_item = Esc(item) -- to accommodate 'RE-ENABLE' and '(UN)DISABLE'
		menu = menu:gsub('|<?'..esc_item, function(c) return c:match('[|<]+')..'#'..item end, 1) -- < submenu closure tag is meant to accommodate 'MOVE MARKED ACTION DOWN' item
		end

	else -- un-gray out

	local several_acts = cust_action and ext_state:match('^.-\n\n(.-)\n\n'):match('|') -- names menu is stored on the 2nd line, if there're more than 1 action name, there'll be menu item separator
	local add_action = #r.GetExtState(scr_cmdID, 'ADD_ACTION') > 0
	
	local t = {table.unpack(t,1,10)} -- excluding UNDO which is handled by update_undo_state_on_menu_load()

		-- un-grayout all
		for k, item in ipairs(t) do
		local esc_item = Esc(item) -- to accommodate 'RE-ENABLE' and '(UN)DISABLE'
		menu = menu:gsub('#'..esc_item, item, 1)
		end
		
	local disabled = table.concat(act_names_menu_t):match('\204\182') -- OR '\xCC\xB6', contains strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336)
		if not disabled then -- gray out because the operations only apply to disabled action items
			for i = 3, 4 do -- remove all disabled / re-enable all
			local item = t[i]
			local esc_item = Esc(item) -- to accommodate 'RE-ENABLE ALL'
			menu = menu:gsub('|<?'..esc_item, function(c) return c:match('[|<]+')..'#'..item end, 1) -- < submenu closure tag is meant to accommodate cases where the management options are exploded from the submenu into the main menu in which 'RE-ENABLE ALL' closed the submenu
			end
		end

	local checkmarked = act_names_menu_t and ('|'..table.concat(act_names_menu_t,'|')):match('|!') -- preceding with pipe in case the 1st action item is checkmarked because it won't be preceded with pipe after concatenation // act_names_menu_t will be nil if no actions have been added

		if not checkmarked then -- gray out management options which only target checkmarked action items
			for i = 5, 9 do -- excluding first 4 and RUN ACTIONS
			local item = t[i]
			local esc_item = Esc(item) -- to accommodate '(UN)DISABLE'
			menu = menu:gsub('|<?'..esc_item, function(c) return c:match('[|<]+')..'#'..item end, 1) -- < submenu closure tag is meant to accommodate 'MOVE MARKED ACTION DOWN' item
			end
		end

		if not several_acts then -- gray out (un)disable and move marked up/down from evaluation when there's only one action, because there's no point in disabling a single action entry and because one action entry cannot be moved
		table.remove(t,6) -- exclude 'duplicate marked'
			for i = 6, 9 do -- excluding RUN ACTIONS
			local item = t[i]
			local esc_item = Esc(item) -- to accommodate '(UN)DISABLE'
			menu = menu:gsub('|<?'..esc_item, function(c) return c:match('[|<]+')..'#'..item end, 1) -- < submenu closure tag is meant to accommodate 'MOVE MARKED ACTION DOWN' item
			end		
		end
		
	local all_disabled = 1
		for k, act_name in ipairs(act_names_menu_t) do
			if not act_name:match('\204\182') then -- OR '\xCC\xB6', at least one action name doesn't contain strikethrough char 'Combining Long Stroke Overlay' (UTF-8 U+0336)
			all_disabled = nil -- reset
			break end
		end
		
		if all_disabled then -- when all actions are disabled, EXPORT AS is grayed out because there's no point to export disabled sequence
		menu = menu:gsub('|EXPORT AS', '|#EXPORT AS',1)
		end
		
		if add_action or all_disabled then -- when ADD ARMED ACTION option is On or all actions are disabled, RUN ACTIONS stays grayed out and vice versa
		menu = menu:gsub('|&R\204\178UN ACTIONS', '|#&R\204\178UN ACTIONS',1)
		end
	
	end
	
return menu

end


-- used inside update_undo_state_on_menu_load() and RUN_MENU()
function clear_action_checkmark_and_get_idx(act_names_menu_t)
local checked_act_idx
	for k, action in ipairs(act_names_menu_t) do
		if action:match('^!')
		then
			if not keep then
			act_names_menu_t[k] = action:gsub('!','',1) -- only 1st occurrence in case the action name includes !
			end
		checked_act_idx = k -- k is the index of the currently checkmarked action to calculate the next action index to run with RUN ACTIONS option
		break
		end
	end
return act_names_menu_t, checked_act_idx or 0 -- in case no action item is checked

end



function checkmark_option(scr_cmdID, option_key, option_name, menu)
local enabled = #r.GetExtState(scr_cmdID, option_key) > 0
local pipe = option_name == 'OPERATIONS' and '>' or '|'
return enabled and menu:gsub(pipe..option_name, pipe..'!'..option_name,1) or menu:gsub('!'..option_name, option_name,1), -- need to use | as an anchor because simple option name will fit '!'..option_name as well and the exclamation marks will accrue at each menu reload
enabled
end


function is_momentary_action(cmdID)
-- used inside RUN_MENU() to prevent changing toggle state indicator
-- for actions 'Action: Momentarily send next action to next project tab XXX'
-- because they're always Off
local t = {{3002,3011},{3032,3041},{3061,3065},{3091,3095},{3120,3120}} -- the last is pair for the sake of conformity and simplification
	for k, t in ipairs(t) do
		if cmdID >= t[1] and cmdID <= t[2] then
		return true
		end
	end
-- OR
--return cmdID >= 3061 and cmdID <= 3065 or cmdID >= 3091 and cmdID <= 3095 or cmdID == 3120
--or cmdID >= 3002 and cmdID <= 3011 or cmdID >= 3032 and cmdID <= 3041
end


function get_gfx_scale()
-- https://forum.cockos.com/showthread.php?t=230120
-- ideally should be included in the defer function as well to monitor any changes
-- by the user at runtime or moving the window to a monitor with different scale
-- for retina detection the function must be run twice, before and after gfx.init()
-- to make gfx.ext_retina value update if retina is supported on the user monitor
-- on Mac the retina value must not be applied to gfx window size because there it
-- will update automatically, but must be applied to all other elements;
-- gfx.ext_retina arg must be passed to the 2nd instance of the function

local retval, dpi = r.ThemeLayout_GetLayout('tcp', -3)
--[[
-- the scale unit is 256/100 because 256 is scale 1 and 512 is scale 2 which correspond to values 1 and 2 in Pref -> General -> Advanced UI/system tweaks -> Scale UI elements of .., the minimal step between 1 and 2 is 0.01, so 100 in total, after calculation decimal values are rounded off, e.g. scale 1.01 = 259 (rounded 256+2.56), scale 1.02 = 261 (rounded 256+2.56*2)
local cur_scale = ((dpi+0-256)/100/2.56) -- OR (dpi+0-256)/2.56/100
cur_scale = math.floor(cur_scale*100+0.5)/100 + 1 -- if cur_scale value is < 1, 0.5 is too big and roudning off will produce 0, hence temporarily updscaling the value and then restoring, adding 1 since no scaling equals 1, plus if user scaling value is < 1 cur_scale value will be negative because dpi < 256 and +1 will rectify it into a correct positive one
]]
-- OR much simpler
local cur_scale = dpi/256 -- 256 is scale 1, 512 is 2
	if not gfx.ext_retina then -- initial gfx.ext_retina value is nil, once set to 1 will auto-update to 2 on second function call after gfx.init() to indicate retina support if any otherwise will be set to 0
	gfx.ext_retina = 1
	end
local mult = gfx.ext_retina == 2 and gfx.ext_retina or 1
return cur_scale * mult -- multiplying by retina value which will be set to 2 if retina is supported, otherwise no change in the scale because when no retina mult var will be set to 1
end


function click_pad(scr_cmdID, w, h, cur_scale)
-- cur_scale arg stems from get_gfx_scale()
local scale = cur_scale or 1
local w, h = w*scale, h*scale
local stored_coord = r.GetExtState(scr_cmdID, 'LAST_GFX_COORDINATES') -- load coordinates stored last during session
local x, y = stored_coord:match('(%d+),(%d+)')
local mouse_x, mouse_y = r.GetMousePosition()
x, y = table.unpack(x and {x,y} or {mouse_x-w/2, mouse_y-23-h/2}) -- when opening for the first time during session open so that the box center is at mouse, 23 is the height of the box top bar not included in its height value, then during session open at the last position, stored in store_or_update_coordinates_after_quitting() // mouse_x-w to place the window's upper right hand corner at the mouse
gfx.init('Custom Action Step-Through Previewer', w, h, 0, x, y) -- height value doesn't include the top bar whose height is 23 px
gfx.setfont(1,"Arial Black", 16*scale)
-- both following alternatives work, the first may be preferable for handling manual window resize
--[-[
--local char_w, char_h = gfx.measurechar('C')
local str = ('CLICK'):gsub('.','%0'..(' '):rep(8))..'K'
local str_w, str_h = gfx.measurestr(str)
gfx.x, gfx.y = (w-str_w)/2, (h-str_h)/2
gfx.drawstr(str)
--]]
--[[
gfx.x, gfx.y = 50*scale, 7*scale
gfx.drawstr(('CLICK'):gsub('.','%0'..(' '):rep(8)))
--]]
end


function keep_click_pad_size(w, h, cur_scale)
local scale = cur_scale or 1
local w, h = w*scale, h*scale
	if gfx.w ~= w or gfx.h ~= h then
	gfx.init('', w, h)
	end
-- the crucial part is the empty window name
-- Thanks to Justin & amagalma
-- https://www.askjf.com/?q=5895s
-- https://forum.cockos.com/showpost.php?p=2493416&postcount=40

-- this must always run because when the window is resized the text disappears,
-- can't be restored fast enough in the block above probably needs more time
-- both alternatives work, the first may be preferable for handling manual window resize
--[-[
local str = ('CLIC'):gsub('.','%0'..(' '):rep(8))..'K'
local str_w, str_h = gfx.measurestr(str)
gfx.x, gfx.y = (w-str_w)/2, (h-str_h)/2
gfx.drawstr(str)
--]]
--[[
gfx.x, gfx.y = 50*scale, 7*scale
gfx.drawstr(('CLICK'):gsub('.','%0'..(' '):rep(8)))
--]]
end


function mouse_click()
gfx.x, gfx.y = 0, 0 -- reset for mouse capture
return gfx.mouse_cap&1 == 1 and gfx.mouse_x > gfx.x and gfx.mouse_x < gfx.w
and gfx.mouse_y > gfx.y and gfx.mouse_y < gfx.h
end



function store_or_update_coordinates_after_quitting(scr_cmdID)
-- THE STORAGE ROUTINE IN THIS FUNCTION ENSURES THAT
-- the window is always re-opened at the same location
-- regardless of whether it was closed by clicking its
-- close button or with Esc and regardless of the current
-- mouse cursor position

-- when gfx window has been closed by mouse click or with a key press
-- gfx.clienttoscreen(0,0) will only return zeros because there's no window any longer
-- however fetching coordinates relative to the mouse cursor
-- allows calculating the window more or less exact original location on the screen;
-- when closing with the click on the close button located in the upper right hand corner:
-- x = mouse_x-gfx.w+5 (or 10), accounting for gfx window width because the close button
-- is located opposite to the X axis start but short of the window's right edge
-- y = mouse_y-10, accounting for mouse location which is below the gfx window top edge
-- by about 10 px;
-- otherwise the coordinates need to be updated constantly while the script runs
-- this however isn't suitable for closing with key press because mouse cursor can be anywhere

-- https://forums.cockos.com/showthread.php?p=2015361
local click, escape = gfx.getchar() == -1, gfx.getchar() == 27

	if click or escape then -- WITH ESCAPE AND LIKELY ANY KEY PRESS THIS REQUIRES LONG PRESS UNTIL IT'S REGISTERED, HOWEVER IN THE MAIN DEFER FUNCTION THIS FUNCTION RUNS INSIDE gfx.getchar() == 27 CAN BE REGISTERED IMMEDIATELY WITH THE FOLLOWING SYNTAX:
	-- 'if gfx.getchar() == 27 or gfx.getchar() == -1 then'
	-- INSIDE THIS FUNCTION HOWEVER EVEN THIS ORDER OF CONDITIONS DOESN'T PRODUCE IMMEDIATE RESPONSE
	-- the code inside the function doesn't need adjustment, just add the same condition outside of it
	-- in the main defer function
	-- on top of the condition inside it, i.e.:
	--[[ if gfx.getchar() == 27 or gfx.getchar() == -1 then -- gfx.getchar() == 27 doesn't work immediately if preceded by gfx.getchar() == -1
		store_or_update_coordinates_after_quitting(cmdID)
		end
	]]

	local stored_coord = r.GetExtState(scr_cmdID, 'LAST_GFX_COORDINATES') -- load coordinates stored last during session
	local x, y = stored_coord:match('(%d+),(%d+)')
	local cur_x, cur_y = table.unpack(click and {r.GetMousePosition()} or escape and {gfx.clienttoscreen(0,0)} or {})
		
		if not x or cur_x ~= x+0 or cur_y+0 ~= y then
		x, y = table.unpack(click and {cur_x-gfx.w+5, cur_y-10} or escape and {cur_x, cur_y}) -- if click, subtraction of the window width ensures that when re-opened it's situated more or less at the same spot, otherwise the window will be re-opened at the last click coordinate which is the close button X location thus shifting righwards by its length from the last location // +5 (10 also works) and -10 adjust the coordinates so if the mouse cursor stays put the window will open with the close button presicely under the cursor, because the close button doesn't sit on the window's right edge so gfx.w is greater than cursor's cur_x value at the moment of the click, likewise cursor's cur_y value doesn't match the window y coordinate exactly because the close button sits lower than the window's top edge
		r.SetExtState(scr_cmdID, 'LAST_GFX_COORDINATES', math.floor(x)..','..math.floor(y), false) -- persist false // truncating the trailing decimal zero from integers
	--	gfx.quit() -- only needed if quitting at a key press rathen than by a click on the close button, placed here to allow getting coordinates above while the window is open // REDUNDANT BECAUSE IN THE MAIN DEFER FUNCTION THIS FUNCTION WILL BE FOLLOWED BY A RETURN STATEMENT TO QUIT THE SCRIPT SO THE WINDOW WILL CLOSE ALL THE SAME, gfx.quit() alone won't make the window close on Esc
		end

	end

end


function get_action_simulator_functions_from_file(file_path)

local func = ''
	for line in io.lines(file_path) do
		if line then
			if line:match('return function') or #func > 0 then
			func = func..(#func > 0 and '\n' or '')..line
			end
		end
	end

func = func:match('.+(return function.+end)') -- exclude any trailing and preceding content, only the last 'return function' is included in case it occurs elsewhere in the script, should not feature in the nested functions 

	if func then
	-- https://stackoverflow.com/questions/48629129/what-does-load-do-in-lua
	-- https://forum.luanti.org/viewtopic.php?t=27810
	local func, err = load(func)() -- closing double brackets are a must even though they're not mentioned in Lua documentation, they turn the namespace into an executable function
		if err then return err
		else
		-- https://www.gammon.com.au/scripts/doc.php?lua=pcall
		-- http://lua-users.org/lists/lua-l/2009-11/msg00269.html
		local ok, t = pcall(func) -- t is a table returned by the function
			if ok then return t
			else
			r.MB('Function '..func..' has failed', 'ERROR', 0)
			end
		end
	end

end



function run_action_simulator_functions(func_t, next_cmdID, output, act_names_menu_t, scr_cmdID, act_IDs_t, section)

local err, output_next = func_t[next_cmdID](output, act_names_menu_t, scr_cmdID, act_IDs_t, section)

	if err or output_next == output then -- this is mainly geared towards 'Prompt to go to action loop start' action simulator function when the action is the last in the sequence so that declining the dialogue results in the action ending up being checkmarked (because there's nowhere to advance) rather than leaving the previous one checlmarked which is the result of canceling the dialogue altogether, when the dialogue is declined the original output value passed as the argument doesn't change
	return err, output
	end

local next_cmdID = act_IDs_t[output_next]

	if not err and func_t[next_cmdID] then
		if output_next <= #act_names_menu_t then -- go recursive to address any custom action specific action which follows the one at the output index in the custom action sequence it's the last in the sequence
		return run_action_simulator_functions(func_t, next_cmdID, output_next, act_names_menu_t, scr_cmdID, act_IDs_t, section) 
		end
	end
	
return err, output_next

end



function RUN_MENU()

-- https://forums.cockos.com/showthread.php?p=2015361
	if gfx.getchar() == 27 or gfx.getchar() == -1 then -- gfx.getchar() == 27 doesn't work immediately if preceded by gfx.getchar() == -1	
	store_or_update_coordinates_after_quitting(cmdID)
	r.SetExtState(cmdID, 'MENU_STATE', menu, false) -- persist false // store exploded/impolded list management options and grayedout menu items, will be called by the script on start
	insert_get_delete_bckgrnd_track(cmdID, 1) -- delete is 1 true
	return end -- click pad window has been closed by the user, terminate the script

keep_click_pad_size(265, 30, cur_scale) -- must be placed after window closing condition, otherwise doesn't close on mouse click when the window is scaled
gfx.update() -- just in case, probably unnecessary in this design

	if #r.GetExtState(cmdID, 'ADD_ACTION') > 0 then -- use extended state to obviate menu opening to get add_armed_action var, so that actions can be added after closing and reopening the click pad box and the error message can be displayed	
	local cur_armed_act = {r.GetArmedCommand()} -- armed action command ID is 0 when nothing is armed // armed state is exclusive across all Action list sections

		-- preventing adding actions which were armed prior to activation of ADD ARMED ACTION option
		if last_armed_act and (cur_armed_act[1] == 0 or last_armed_act[1] ~= cur_armed_act[1]
		or last_armed_act[2] ~= cur_armed_act[2]) or not last_armed_act then
		last_armed_act = nil -- reset
		act_names_menu_t, act_IDs_t, section, cust_act_ID = parse_custom_action(cmdID) -- must be here as well because while actions are being armed one by one mouse_click() will be false and the data won't come from the block below // cust_act_ID will be empty string if no custom action was imported and actions were only added by arming them until exported at least once // act_IDs_t contains integer command IDs // section is a string
		added = operations_t[4](cmdID, act_names_menu_t, act_IDs_t, section, cust_act_ID, settings_t) -- add_armed_action() // added return value will trigger menu opening once action has been added to reflect the result
		end
	end

	if mouse_click() or time_init and r.time_precise()-time_init >= 2 or added then -- open the menu, once opened it stays open even though mouse click condition is false by that point OR after 2 sec of error tooltip display

	added, time_init, err = nil -- reset

	::RELOAD::	

	-- add toggle indicators to the menu items after toggling the corresponding options in response to menu clicks below
	menu, add_armed_action = checkmark_option(cmdID, 'ADD_ACTION', 'ADD ARMED ACTION', menu)
	menu = checkmark_option(cmdID, 'ADD_ACTION', 'OPERATIONS', menu) -- checkmark the submenu title when 'add armed action' option is enabled to make its status apparent

	act_names_menu_t, act_IDs_t, section, cust_act_ID = parse_custom_action(cmdID) -- cust_act_ID will be empty string if no custom action was imported and actions were only added by arming them until exported at least once // act_IDs_t contains integer command IDs // section is a string
	menu, act_names_menu_t = update_undo_state_on_menu_load(cmdID, act_names_menu_t, menu) -- will gray out UNDO option if the latest undo point in REAPER undo history wasn't created by this script or if the index of undo history point created by the script is greater than the number of custom action steps and change or remove action menu checkmark according to the latest undone action in REAPER undo history
	menu = un_grayout_menu_items(cmdID, menu, act_names_menu_t)
	
	local names_menu = act_names_menu_t and '||'..table.concat(act_names_menu_t,'|') or ''
	local output = Reload_Menu_at_Same_Pos_gfx(menu..names_menu) -------------- UNCOMMENT

	local err -- seems superfluous but leaving for safety to prevent possible endless menu reload loop

		if output == 4 then -- toggle ADD ARMED ACTION option // conditions add_armed_action() function above as operations_t[3]
			if not add_armed_action then
			last_armed_act = {r.GetArmedCommand()} -- storing currently armed action while ADD ARMED ACTON option is disabled, will be used to prevent adding actions which were armed prior to activation of the option // armed state is exclusive across all Action list sections
			end		
		-- toggle RUN ACIONS menu item grayout when ADD ARMED ACTON is toggled while there're actions, if no actions it stays grayed out, armed state is exclusive across all Action list sections
		r.SetExtState(cmdID, 'ADD_ACTION', add_armed_action and '' or '1', false) -- persist false // toggle ADD ARMED ACTION option

		elseif output == 5 then -- explode/implode list management menu moving it from the submenu to the main menu and vice versa

		local re_enable_all_act = menu:match('#?RE%-ENABLE ALL ACTIONS')
		local re_enable_escaped = Esc(re_enable_all_act)
		local DOWN = ' &D\204\178OWN' -- including utf-8 Combining Low Line (818) character which emphasizes the quick access shortcut
		local grayedout = menu:match('#MOVE MARKED ACTION'..DOWN) and '#' or '' -- keeping grayedout state which is active when there're no actions
		local list = 'plode list '
			if menu:match('|<'..grayedout..'MOVE MARKED ACTION'..DOWN) then -- explode			
			menu = menu:gsub('<'..grayedout..'MOVE MARKED ACTION'..DOWN, grayedout..'MOVE MARKED ACTION'..DOWN,1):gsub(re_enable_escaped, '<'..re_enable_all_act, 1):gsub('Ex'..list,'Im'..list,1)
			else -- implode
			menu = menu:gsub('<'..re_enable_escaped, re_enable_all_act, 1):gsub(grayedout..'MOVE MARKED ACTION'..DOWN, '<%0', 1):gsub('Im'..list,'Ex'..list,1)
			end
		
		elseif output > 0 and output < 14 then -- management and other operations
			
		local mode = (output == 8 or output == 9 or output == 12) and 1 or (output == 6 or output == 7 or output == 13) and 2 -- for re-enable all/remove marked/move up and remove all/remove all disabled/move down
		local main_data = {cmdID, act_names_menu_t, act_IDs_t, section, cust_act_ID, mode, settings_t} -- adding mode argument for move_up_or_down(), remove_action_or_all() and en_de_code_disabled_actions(), will be ignored in duplicate_action(), settings_t is for duplicate_action() and remove_action_or_all() will be ignored in the rest
		local arg = (output == 2 or output > 5 and output < 14) and main_data -- export / remove all / remove disabled / re-enable disabled / remove marked / (un)disable marked / duplicate / move up/down	
		or output < 4 and {cmdID}

		err = operations_t[output](table.unpack(arg)) -- return error message to display and schedule re-loading of the menu, so that while the tooltip message is displayed the menu is closed because otherwise the menu may obscure it and it's nearly impossible to choose optimal coordinates for the message because the size of the menu and its direction relative to the mouse cursor cannot be ascertained

		elseif output == 16 then -- UNDO
		menu, act_names_menu_t = undo(cmdID, act_names_menu_t, act_IDs_t, section, menu) -- act_names_menu_t will be used below to update the 'CUSTOM_ACTION' extended state // menu extended state is updated when the script is terminated

		elseif output == 15 or output > 16 then -- actions, either run with RUN ACTIONS menu item or click individually to checkmark for being affected by management options or set RUN ACTIONS sequence start		
		local run_acts = output == 15
		act_names_menu_t, marked_act_idx = clear_action_checkmark_and_get_idx(act_names_menu_t) -- since checkmark is exclusive, clear it from whatever action name which is currently checkmarked, the last clicked action menu item will be checkmarked below
		local output = (run_acts and output+1+marked_act_idx+1 or output)-16 -- when clicking RUN ACTIONS (output 15) using index of the action item which follows currently checkmarked because it matches the indices in act_names_menu_t table, or offsetting 16 menu items which precede the action menu when clicking on individual action items to checkmark them for management
		
		output = run_acts and get_first_non_disabled_action(act_names_menu_t, output) or output -- if running actions find if the next action item isn't disabled and if it is get the first not-disabled downstream, otherwise keep the value
		
		-- RUN ACTION SIMULATOR FUNCTIONS
		local act_ID = act_IDs_t[output]	-- act_ID is integer
			if run_acts and cust_act_func_t[act_ID] then
			err, output = run_action_simulator_functions(cust_act_func_t, act_ID, output, act_names_menu_t, cmdID, act_IDs_t, section) 
				if err == true then goto RELOAD end
			end			
		
		act_name = act_names_menu_t[output]

		local ACT = section == '0' and r.Main_OnCommand or MIDIEditor_GetActiveAndVisible() and r.MIDIEditor_LastFocused_OnCommand
		err = err or run_acts and (not ACT and 'no active midi editor' or output > #act_names_menu_t 
		and '     end of the custom action.\n\n uncheck the last action to reset') -- when running actions output var will end up being greater than the name table length after the calculation if the last action item was checkmarked // the error will be displayed after the output block

			if not err then -- will be valid for original output > 13 (individually clicked action items) and for valid RUN ACTION calculated output value
			
				if run_acts then -- when clicking RUN ACTONS
				local islistviewcommand = section == '32061' or r.MIDIEditor_GetMode(r.MIDIEditor_GetActive()) == 1
				r.Undo_BeginBlock()
				force_create_undo_point(cmdID)
				act_ID = act_IDs_t[output]	-- act_ID is integer
				ACT(act_ID, section == '0' and 0 or islistviewcommand) -- act_IDs_t table contains numeric command IDs which are converted inside parse_custom_action() // in Main_OnCommand 2nd argument is 0, in MIDIEditor_LastFocused_OnCommand it's islistviewcommand
				local tog_state = r.GetToggleCommandStateEx(section+0, act_ID)
				-- there's no point evaluating the actual toggle state because it doesn't change fast enough
				-- to be detected a couple of lines later, so only ensuring that the action is a toggle and swapping the toggle indicators
				-- which are added based on the toggle state at the moment of custom action import or armed action addition
				-- only swapping when RUN ACTIONS setting is enabled because toggle state doesn't change when an action isn't executed
				-- add toggle indicators before closing the undo block so that the latest ones are included
				-- in the undo point name;
				-- change in toggle state of actions 'Action: Momentarily send next action to project tab xxxx'
				-- is momentary, so they always stay Off therefore changing their state indicator to On isn't necessary
				act_name = run_acts and tog_state > -1 and not is_momentary_action(act_ID) and ( act_name:match('◦') and act_name:gsub('◦','▪') -- different shapes because in the menu the same shape blank is indistingushable from the filled one // run_acts condition is redundant here because the entire block is conditioned by it
				or act_name:match('▪') and act_name:gsub('▪', '◦') ) or act_name
				
					if output >= #act_names_menu_t then
					-- delete the value stored in skip_next_act_and_set_cc() and used in skip_next_action_if()
					-- action simulator functions when the custom action sequence has run through
					-- extended state isn't saved with undo point so cannot be undone the regular way
					r.DeleteExtState(cmdID,'CC_PARM',true) -- persist true
					end

				r.Undo_EndBlock(math.floor(output)..'#'..act_name, -1) -- add # as a prefix to undo point name to tie it to this script and allow ignoring all others
				
				end

			-- at fast click rate directly on action items it's possible to make more than one action name checkmarked
			-- this condition remedies that; traversing the entire act_names_menu_t table inside clear_action_checkmark_and_get_idx() above
			-- and then before goto statement or after ::RELOAD:: gave unsatisfactory results only reducing
			-- max number of sumultanelusly checkmarked action names to two
				if act_name and act_name:match('^!') then -- remove checkmark // act_name will be valid if calculated output is valid, i.e. no message 'end of the custom action'
				act_name = act_name:sub(2)
				end

				if output ~= #act_names_menu_t -- allows switching checkmark between different action items and adding one when there's none, disallowing clearing checkmark by clicking the same item unless it's the last item in the list
				or output == #act_names_menu_t and output > marked_act_idx -- allows clearing checkmark from the last action item by preventing the below assignment so that after call to clear_action_checkmark_and_get_idx() above checkmark isn't added here
				then
				act_names_menu_t[output] = '!'..act_name -- add checkmark to the name of the latest clicked action menu item			
				end
				
			end

		end

		if err and err ~= true then -- only strings // err as boolean true is returned from run_action_simulator_functions() by prompt_to_continue() and prompt_to_goto_act_loop_start()
		Error_Tooltip('\n\n '..err..' \n\n', 1, 1, gfx.clienttoscreen(0,0)) -- caps, spaced true // coordinates match those of the click pad gfx window so the tooltip overlays it
		time_init = r.time_precise() -- must be global along with err to be accesible outside of the click block to prolong the tooltip display
		elseif output > 0 and output ~= 14 and output ~= 2 then -- 14 is exit menu item hence excluded, 2 is export as keymap; only set off goto loop if no error message in which case time_init is false
			if output >= 15 then -- update the data when RUN ACTIONS or UNDO is run or action items are clicked
			local name = r.GetExtState(cmdID,'CUSTOM_ACTION'):match('.-\n\n')
			local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
			r.SetExtState(cmdID,'CUSTOM_ACTION', name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids
			..'\n\n'..section..'\n\n'..cust_act_ID, false) -- persist false
			end
		goto RELOAD
		end

	end

	if time_init and err and err ~= true then -- this makes the tooltip stick around longer, until time_init and err are reset once the menu is reloaded, because even though the menu reload schedule has been set to 2 sec, the tooltip disappears sooner // err as boolean true is returned from run_action_simulator_functions() by prompt_to_continue() and prompt_to_goto_act_loop_start()
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, gfx.clienttoscreen(0,0))
	end

r.defer(RUN_MENU)

end


	if not r.CF_GetCommandText then -- SWS extension is needed anyway for undo settings toggle even if build supports kbd_getTextFromCmd
	Error_Tooltip('\n\n the sws/s&m extension \n\n\tisn\'t installed \n\n', 1, 1)
	return r.defer(no_undo)
	end

local is_new_value, scr_name, sect_ID, cmdID_init, mode, resol, val, contextstr = r.get_action_context()
cmdID = r.ReverseNamedCommandLookup(cmdID_init)

settings_t = {add_to_top = validate_sett(ADD_TO_TOP_OF_THE_LIST), checkmark_armed = validate_sett(CHECKMARK_ADDED),
checkmark_dup = validate_sett(CHECKMARK_DUPLICATED), inherit_checkmark = validate_sett(INHERIT_CHECKMARK)} -- settings for add_armed_action(), duplicate_action() and remove_action_or_all()

operations_t = {import_custom_action, export_as_keymap, lookup_custom_action_props, add_armed_action, _, remove_action_or_all, re_enable_all_del_disabled_actions, re_enable_all_del_disabled_actions, remove_action_or_all, toggle_disable_action, duplicate_action, move_up_or_down, move_up_or_down} -- _ is a placeholder for 'Explode list management menu' option

-- used in get_action_names(), add_armed_action() and toggle_disable_action()
-- either command ID is evaluated or name, depending on the function
unsupported_t = {[2003]=1,['Action: Modify MIDI CC/mousewheel: Negative']=1,-- dummy value
[2004]=1,['Action: Modify MIDI CC/mousewheel: 0.5x']=1,
[2005]=1,['Action: Modify MIDI CC/mousewheel: 2x']=1,
[2006]=1,['Action: Modify MIDI CC/mousewheel: +10%']=1, 
[2007]=1,['Action: Modify MIDI CC/mousewheel: -10%']=1,
[2999]=1,['Action: Repeat the most recent action']=1,
[3000]=1,['Action: Repeat the action prior to the most recent action']=1,
[3120]=1,['Action: Momentarily send next action to previously active project tab']=1,
[41060]=1,['ReaScript: Run ReaScript (EEL2 or lua)...']=1,
[41065]=1,['ReaScript: Open ReaScript documentation (html)...']=1,
[41935]=1,['ReaScript: Edit new ReaScript (EEL2 or lua)...']=1,
[65535]=1,['No-op (no action)']=1,
at_mouse='at mouse', under_mouse='under mouse', to_mouse='to mouse'}


menu = r.GetExtState(cmdID, 'MENU_STATE') -- either with exploded or impolded list management options // stored at script exit within RUN_MENU()
menu = menu and #menu > 0 and menu or '>OPERATIONS|IMPORT A CUSTOM ACTION||#EXPORT AS .ReaperKeyMap file||#LOOK UP IMPORTED CUSTOM ACTION PROPERTIES||ADD ARMED ACTION (toggle)|||Explode list management menu||#REMOVE ALL ACTIONS||#REMOVE ALL DISABLED ACTIONS||#RE-ENABLE ALL ACTIONS||#REMOVE MARKED ACTION||#(U&N\204\178)DISABLE MARKED ACTION||#DUPLICATE MARKED ACTION||#MOVE MARKED ACTION U&P\204\178||<#MOVE MARKED ACTION &D\204\178OWN|||EXIT MENU (or click the box top bar or Esc)||#&R\204\178UN ACTIONS||&U\204\178NDO'  -- including utf-8 Combining Low Line (818) character which emphasizes the quick access shortcut // MOVE UP quick access shortcut is 'p' rather than 'u' because the latter is allocated to UNDO and these would clash when operations menu is exploded into the main menu

local act_names_menu_t, act_IDs_t, section

get_gfx_scale() -- run 1st time to intialize gfx.ext_retina value before gfx.init() inside click_pad()

-- the gfx click pad simplifies menu handling, because otherwise
-- one would have to devise a way to keep the script running in defer loop
-- without displaying the menu and display it only on click,
-- to detect click get_action_context() val could have probably been used
-- and the menu display location would have to be decided upon
click_pad(cmdID, 265, 30, cur_scale) -- must be located outside of the defer loop so that closing with gfx.getchar() == -1 works

cur_scale = get_gfx_scale() -- run 2nd time after gfx.init() inside click_pad() to update gfx.ext_retina if retina is supported and accounr for it in the scale value

insert_get_delete_bckgrnd_track(cmdID)

cust_act_func_t = get_action_simulator_functions_from_file(scr_name)


RUN_MENU()

	-- prevent ReaScript task control dialogue when the running script is clicked again to be terminated,
	-- supported since build 7.03
	-- script flag for auto-relaunching after termination in reaper-kb.ini is 4, e.g. SCR 4, but if changed
	-- directly while REAPER is running the change doesn't take effect, so in builds older than 7.03 user input is required
	if r.set_action_options then r.set_action_options(1) end

r.atexit(Wrapper(insert_get_delete_bckgrnd_track, cmdID, 1)) -- delete background track, delete arg is true


------------------------------------------------------------------------------------

--- FUNCTIONS TO SIMULATE ACTONS SPECIFIC TO CUSTOM ACTIONS ---
-- will be called with get_action_simulator_functions_from_file() before RUN_MENU()
-- RETURN THIS FUNCTION START
return function()

local action_IDs = {
2000, -- Action: Prompt to continue (only valid within custom actions)
2001, -- Action: Set action loop start (only valid within custom actions)
2002, -- Action: Prompt to go to action loop start (only valid within custom actions)
2008, -- Action: Wait 0.1 seconds before next action
2009, -- Action: Wait 0.5 seconds before next action
2010, -- Action: Wait 1 second before next action
2011, -- Action: Wait 5 seconds before next action
2012, -- Action: Wait 10 seconds before next action
2013, -- Action: Skip next action if CC parameter <0/mid
2014, -- Action: Skip next action if CC parameter >0/mid
2015, -- Action: Skip next action if CC parameter <=0/mid
2016, -- Action: Skip next action if CC parameter >=0/mid
2017, -- Action: Skip next action if CC parameter ==0/mid
2018, -- Action: Skip next action if CC parameter !=0/mid
2019, -- Action: Arm next action
2020, -- Action: Disarm action
2021, -- Action: Toggle arm of next action
2022, -- Action: Skip next action, set CC parameter to relative +1 if action toggle state enabled, -1 if disabled, 0 if toggle state unavailable.
2023, -- Action: Skip next action, set CC parameter to relative +1 if action armed, 0 otherwise
-- THESE DON'T WORK INSIDE CUSTOM ACTIONS
-- 2999, -- Action: Repeat the most recent action
-- 3000, -- Action: Repeat the action prior to the most recent action
3002, -- Action: Momentarily send next action to project tab 1
3003, -- Action: Momentarily send next action to project tab 2
3004, -- Action: Momentarily send next action to project tab 3
3005, -- Action: Momentarily send next action to project tab 4
3006, -- Action: Momentarily send next action to project tab 5
3007, -- Action: Momentarily send next action to project tab 6
3008, -- Action: Momentarily send next action to project tab 7
3009, -- Action: Momentarily send next action to project tab 8
3010, -- Action: Momentarily send next action to project tab 9
3011, -- Action: Momentarily send next action to project tab 10
3032, -- Action: Momentarily send next action to project tab N
3033, -- Action: Momentarily send next action to project tab N-1
3034, -- Action: Momentarily send next action to project tab N-2
3035, -- Action: Momentarily send next action to project tab N-3
3036, -- Action: Momentarily send next action to project tab N-4
3037, -- Action: Momentarily send next action to project tab N-5
3038, -- Action: Momentarily send next action to project tab N-6
3039, -- Action: Momentarily send next action to project tab N-7
3040, -- Action: Momentarily send next action to project tab N-8
3041, -- Action: Momentarily send next action to project tab N-9
3061, -- Action: Momentarily send next action to next project tab 1
3062, -- Action: Momentarily send next action to next project tab 2
3063, -- Action: Momentarily send next action to next project tab 3
3064, -- Action: Momentarily send next action to next project tab 4
3065, -- Action: Momentarily send next action to next project tab 5
3091, -- Action: Momentarily send next action to previous project tab 1
3092, -- Action: Momentarily send next action to previous project tab 2
3093, -- Action: Momentarily send next action to previous project tab 3
3094, -- Action: Momentarily send next action to previous project tab 4
3095, -- Action: Momentarily send next action to previous project tab 5
-- 3120, -- Action: Momentarily send next action to previously active project tab // CANNOT BE DETECTED
}

local r = reaper -- must be included here, because this assignment in the main code won't be seen inside the function due to being local, they only have access to global variables in the main code; alternatively it can be passed as an argument to this function

-- All functions are fed the following arguments:
-- output, act_names_menu_t, scr_cmdID, act_IDs_t, section
-- output is index of the action after the checkmarked one,
-- i.e. the one to be executed,
-- all functions return the following return values:
-- err, output+1 OR only err

	local function prompt_to_continue(...)
	local output, act_names_menu_t = table.unpack({...})
		if r.MB('Continue running the custom action?','Action paused',1) == 1 -- user assented
		then 
		return err, output == #act_names_menu_t and output or output+1 -- -- if 'Prompt to continue' is the last action maintain the output value, otherwise output+1, next action
		else return true -- instead of an error string, to trigger 'goto RELOAD' outside of the function
		end
	end

	local function set_act_loop_start(...)
	local output, act_names_menu_t = table.unpack({...})
		if output == #act_names_menu_t then
		return ' loop start cannot be set \n\n at the end of the sequence'
		end
	return err, get_first_non_disabled_action(act_names_menu_t, output+1) -- next non-disabled action
	end

	local function prompt_to_goto_act_loop_start(...)
	-- clear_tog_armed_indic(str)
	local output, act_names_menu_t = table.unpack({...})
			-- the name evaluation is in fact redundant because the function
			-- will only be called if the action command ID has been selected as the next action
			-- but leaving for reliability sake
			-- using match() to ignore additional marks which would cause == to fail
			if act_names_menu_t[output]:match('Action: Prompt to go to action loop start') 
			then
			local resp = r.MB('Loop the custom action from step 1?','Action paused', 3)
				if resp == 6 then -- Yes
					for k, act in ipairs(act_names_menu_t) do
						if act:match('Action: Set action loop start %(only valid within custom actions%)') then
							if k > output and k < #act_names_menu_t then
							return 'the loop start cannot \n\n   follow the loop end'
							elseif k+1 < #act_names_menu_t then -- excluding cases where the loop start action is the last in the sequence
							return err, get_first_non_disabled_action(act_names_menu_t, k+1) -- k+1 action which immediately follows loop start action
							else
							return 'the loop start is the last \n\n   action in the sequence'
							end
						end
					end
				elseif resp == 7 then -- No, so continue
				return err, output == #act_names_menu_t and output or get_first_non_disabled_action(act_names_menu_t, output+1) -- if 'Go to loop start' is the last action maintain the output value, otherwise next non-disabled action
				else -- user cancelled the dialogue
				return true -- instead of an error string, to trigger 'goto RELOAD' outside of the function
				end
			end
	return 'action loop start \n\n    step is absent'
	end

	local function wait_before_next_action(...)
	local output, act_names_menu_t = table.unpack({...})
	local sec = act_names_menu_t[output]:match('[%d%.]+')
	local time_init = r.time_precise()
		repeat
		until r.time_precise() - time_init >= sec+0
	return err, output == #act_names_menu_t and output or get_first_non_disabled_action(act_names_menu_t, output+1) -- if 'Wait' is the last action maintain the output value, otherwise next non-disabled action
	end

	
	local function skip_next_action_if(...)
	local output, act_names_menu_t, scr_cmdID = table.unpack({...})
		if output == #act_names_menu_t then
		return err, output -- if 'Skip' is the last active action maintain the output value
		end
	local act_name = act_names_menu_t[output]
	local cc = r.GetExtState(scr_cmdID,'CC_PARM') -- either -1, 0 or 1 // stored in skip_next_act_and_set_cc() and is cleared when the last action item of the action sequence has been reached inside RUN_MENU() and in undo() when the sequence has been fully undone
		if #cc > 0 then
		cc = cc+0
		local t = {['<0']=cc<0,['>0']=cc>0,['<=0']=cc<=0,['>=0']=cc>=0,['==0']=cc==0,['!=0']=cc~=0}	
			for op, truth in pairs(t) do
				if truth and act_name:match(op) then				
					if output+2 > #act_names_menu_t then
					return 'cannot skip beyond the sequence'
					else
					local err = 'no active action to skip'
					local output = get_first_non_disabled_action(act_names_menu_t, output+1) -- using index of the skipped action
						if output > #act_names_menu_t then return err
						else
						local output = get_first_non_disabled_action(act_names_menu_t, output+1) -- using index of the action to skip to
						return output > #act_names_menu_t and err..' to'
						end
					end
				break end
			end
		else
		return 'the cc parameter \n\n    is undefined'
		end
	local output_next = get_first_non_disabled_action(act_names_menu_t, output+1) -- next non-disabled action, no skipping
	return err, output_next > #act_names_menu_t and output or output_next -- if no active, stop at the 'Skip' action itself
	end

	local function un_arm_toggle_next_action(...)
	-- in order to accurately simulate these actions
	-- the RUN ACTION sequence must NOT start with them, i.e.  
	-- they must not be already checkmarked in the actions menu
	-- because checkmark signifies an action which has been executed,
	-- the checkmark must be placed at any preceding action item instead
	-- or cleared altogether to run the sequence from the top
	
	local output, act_names_menu_t, scr_cmdID, act_IDs_t, section = table.unpack({...})
	local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
	['MIDI Inline Editor']=32062,['Media Explorer']=32063}
	local cmd, sect = r.GetArmedCommand() -- sect is empty string if Main 0
	sect = sect_t[sect] or sect_t['alt']
	local act_name = act_names_menu_t[output]
	local arm, unarm, toggle = act_name:match('Arm'), act_name:match('Disarm'), act_name:match('Toggle arm')

	local output_next = get_first_non_disabled_action(act_names_menu_t, output+1) -- using new var to not overwrite original output val because it will be returned
	local next_actID = act_IDs_t[output_next]
	local no_active = output_next > #act_names_menu_t and 'active ' or ''	

		if not next_actID then -- OR output_next < #act_names_menu_t or output_next < #act_IDs_t // end ot the sequence
			if (arm or cmd == 0 and toggle) then
			return 'no '..no_active..'next action to '..(arm or toggle) --(arm or unarm or toggle):lower() // only relevant if an action must be armed because arming is specific whereas unarming applies to all at once across all Action list sections
			else -- unarm or toggle unarm, this can finish the action sequence as it doesn't have to be followed by a specific action
			r.ArmCommand(0,0) -- unarm all
			return err, output -- maintain the output value so that the last action item ends up being checkmarked
			end
		elseif not toggle then
		next_actID = arm and next_actID or unarm and 0 -- 0 to unarm all
		r.ArmCommand(next_actID, section+0)
		else
		next_actID = cmd == 0 and next_actID or 0 -- if no action is armed, arm the next, otherwise unarm all because unarming is global across all Action list sections
		r.ArmCommand(next_actID, section+0)
		end
	return err, output -- since it's not a Skip action, the output value must be maintained rather than advance to the next action
	end


	local function skip_next_act_and_set_cc(...)
	local output, act_names_menu_t, scr_cmdID, act_IDs_t, section = table.unpack({...})
		if output == #act_names_menu_t
		or get_first_non_disabled_action(act_names_menu_t, output+1) > #act_names_menu_t 
		then
		return err, output -- if 'Skip' is the last active action maintain the output value
		elseif output+1 == #act_names_menu_t then -- edge case where the 'Skip' action is itself skipped
		return 'cannot skip beyond the sequence'
		end

	local act_name = act_names_menu_t[output]
	
	local err = 'no active action to skip'
	
	-- get index of the skipped action
	local output = get_first_non_disabled_action(act_names_menu_t, output+1)

		if output > #act_names_menu_t then return err end -- all following actions are disabled
		
	local next_actID = act_IDs_t[output]
	
	-- get index of the first non-disabled action after the skipped one
	-- must be evaluated in advance to prevent unecessarily setting cc value 
	-- without there being an action to skip to
	output = get_first_non_disabled_action(act_names_menu_t, output+1)

		if output > #act_names_menu_t then return err..' to' end -- all following actions are disabled

	err = nil -- reset so it's not returned as a valid value
	local cc_val
		if act_name:match('if action armed') then
		local sect_t = {['']=0,['alt']=0,['MIDI Editor']=32060,['MIDI Event List Editor']=32061,
		['MIDI Inline Editor']=32062,['Media Explorer']=32063}
		local cmd, sect = r.GetArmedCommand() -- sect is empty string if Main 0
		sect = sect_t[sect] or sect_t['alt']
		cc_val = cmd == next_actID and sect == section+0 and 1 or 0
		elseif act_name:match('if action toggle state') then
		local toggle_state = r.GetToggleCommandStateEx(section+0, next_actID)
		cc_val = toggle_state == 1 and 1 or toggle_state == 0 and -1 or 0
		end
		
	r.SetExtState(scr_cmdID, 'CC_PARM', cc_val, false) -- persist false // this is evaluated in skip_next_action_if() and is cleared when the last action item of the action sequence has been reached inside RUN_MENU() and in undo() when the sequence has been fully undone	

	return err, output -- non-disabled action after the first non-disabled action, since the first non-disabled action is skipped
	end

	
	local function send_next_act_to_proj_tab(...)
	local output, act_names_menu_t, scr_cmdID, act_IDs_t, section = table.unpack({...})
		if output == #act_names_menu_t then
		return end

	local act_name = act_names_menu_t[output]
	
	output = get_first_non_disabled_action(act_names_menu_t, output+1) -- index of the action to be sent to another proj tab

		if output > #act_names_menu_t then return 'no active next action' end
	
	local cur_proj = r.EnumProjects(-1)

	-- collect project pointers
	local proj_t = {}
	local i, cur_proj_idx = 0
		repeat
		local proj = r.EnumProjects(i)
			if proj then proj_t[#proj_t+1] = proj end
			if proj == cur_proj then cur_proj_idx = #proj_t end
		i=i+1
		until not proj

	local nxt, prev = act_name:match('next proj'), act_name:match('previous proj')
	local proj_idx = act_name:match('[%-%d]+')
	proj_idx = act_name:match('N[%s◦]*$') and #proj_t or proj_idx:match('%-') and #proj_t+proj_idx or proj_idx -- either last tab, or last - X (but using addition in #proj_t+proj_idx because the index is captured with minus) or relative to current, i.e. next or previous // the actions are toggles but only report Off state hence will be marked with Off indicator
	proj_idx = nxt and cur_proj_idx+proj_idx or prev and cur_proj_idx-proj_idx or proj_idx+0 -- proj_idx will remain a string after evaluation of actions 'send ... to project tab X' hence conversion into numeral

		if proj_idx < 1 or proj_idx > #proj_t then
		return 'the target project tab \n\n   is out of the range. \n\n there\'re only so many \n\n\tproject tabs'
		end
	
	local dest_proj = proj_t[proj_idx]
	r.SelectProjectInstance(dest_proj)
	act_name = act_names_menu_t[output] -- get name of the action which will be executed
	r.Undo_BeginBlock(dest_proj) -- using Undo_EndBlock2 to limit the undo point to the destination project, if regular Undo_EndBlock() is used the undo point is created in both projects // ALTHOUGH IT'S NOT ROCK SOLID, IF THE DEST TAB IS FAR REMOVED FROM THE CURRENT THE POINT IS LIKELY TO BE CREATED IN THE CURRENT PROJECT AS WELL probably due to sluggishness of UI update
	force_create_undo_point(scr_cmdID)
	local act_ID = act_IDs_t[output]
	r.Main_OnCommand(act_ID, section == '0' and 0 or islistviewcommand) -- act_IDs_t table contains numeric command IDs which are converted inside parse_custom_action() // in Main_OnCommand 2nd argument is 0, in MIDIEditor_LastFocused_OnCommand it's islistviewcommand
	local tog_state = r.GetToggleCommandStateEx(section+0, act_ID)
	-- there's no point evaluating the actual toggle state because it doesn't change fast enough
	-- to be detected a couple of lines later, so only ensuring that the action is a toggle and swapping the toggle indicators
	-- which are added based on the toggle state at the moment of custom action import or armed action addition
	-- only swapping when RUN ACTIONS setting is enabled because toggle state doesn't change when an action isn't executed
	-- add toggle indicators before closing the undo block so that the latest ones are included
	-- in the undo point name;
	-- change in toggle state of actions 'Action: Momentarily send next action to project tab xxxx'
	-- is momentary, so they always stay Off therefore changing their state indicator to On isn't necessary
	act_name = tog_state > -1 and not is_momentary_action(act_ID) and ( act_name:match('◦') and act_name:gsub('◦','▪') -- different shapes because in the menu the same shape blank is indistingushable from the filled one
	or act_name:match('▪') and act_name:gsub('▪', '◦') ) or act_name
	r.Undo_EndBlock2(dest_proj, math.floor(output)..'#'..act_name, -1) -- add # as a prefix to undo point name to tie it to this script and allow ignoring all others
	
	r.SelectProjectInstance(cur_proj) -- return to the original project as the actions do
	
	-- update checkmark and extended state
	-- must all be done here rather than inside RUN_MENU() function
	-- because of project tab switching, which complicates the routine
	act_names_menu_t[output] = '!'..act_name -- add checkmark to the name of the executed action item, from the last checkmarked action item it's cleared inside RUN_MENU() before this function runs 
	local state = r.GetExtState(scr_cmdID,'CUSTOM_ACTION')
	local name, cust_act_ID = state:match('.-\n\n'), state:match('.+\n\n(.-)$') -- cust_act_ID could be empty string if custom action was imported and hasn't be exported yet
	local act_ids = table.concat(act_IDs_t,' '):gsub('%d+', function(c) return r.ReverseNamedCommandLookup(c+0) and '_'..r.ReverseNamedCommandLookup(c+0) or c end) -- since act_IDs_t contains numeric command IDs, convert them to named in case non-native action to conform to custom action format adding leading underscore to named command ID as they appear in custom action code which will simplify the export, it will be converted back to integer inside parse_custom_action() so it can be executed // if the cmd belongs to a native action or is 0 the return value is nil // easier to use the table to manage actions than a string retrieved from 'CUSTOM_ACTION' extended state
	r.SetExtState(scr_cmdID,'CUSTOM_ACTION', name..table.concat(act_names_menu_t,'|')..'\n\n'..act_ids
	..'\n\n'..section..'\n\n'..cust_act_ID, false) -- persist false
	return true -- return true to trigger goto RELOAD statement because after the update no point to continue the routine inside RUN_MENU()
	end


-- table indices associated with the functions
-- match those associated with the corresponding actions
-- in action_IDs table above
local action_func_names = {
{prompt_to_continue,1}, -- the 2nd field is the number of function repetitions needed in the table
{set_act_loop_start,1},
{prompt_to_goto_act_loop_start,1},
{wait_before_next_action,5},
{skip_next_action_if,6},
{un_arm_toggle_next_action,3},
{skip_next_act_and_set_cc,2,},
-- repeat_action,
-- repeat_action,
{send_next_act_to_proj_tab,30}
}

-- must be either included here or placed in the main code
-- upstream of get_action_simulator_functions_from_file() function
-- so that pcall() evaluation there doesn't fail
	local function build_array_of_multiple_repeating_items(t)
	-- t is an array containing nested 2-part arrays
	-- consisting of the item needing repetition and the number
	-- of such repetitions, e.g. { {a,2}, {b,3} }
	-- var 'a' should be repeated twice, var 'b' should be repeated trice
	-- the resulting table is supposed to contain
	-- 2 instances of var 'a' followed by 3 instances of var 'b'
	-- and be 5 fields long
	local t2 = {}
		for k, data in ipairs(t) do
			for i=1,data[2] do
			table.insert(t2, data[1]) -- inserting at the last index, index arg (2) is ommitted
		-- OR
		--	t2[#t2+1] = data[1]
			end
		end
	return t2
	end

action_func_names = build_array_of_multiple_repeating_items(action_func_names)
	
-- construct function table
-- associating action command IDs with simulator functions
local actions = {}
	for k, func in ipairs(action_func_names) do
	local act_ID = action_IDs[k]
	actions[act_ID] = func
	end

return actions

end
-- RETURN THIS FUNCTION END







