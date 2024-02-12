--[[
ReaScript name: BuyOne_Useless calculator.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About:	OPERATORS:

	+ — add
	- — subtract or set numeral negative
	* — multiply
	/ — divide
	^ — raise to power
	= — calculate and display the result
	
	b — backspace, delete character which immediately precedes the cursor
	c — clear all
	e — export calculations as text
	m — store numeral which immediately precedes the cursor in the memory		
	n — add new line
	r — recall stored numeral inserting it immediately after the cursor
	
	< — move cursor left
	> — move cursor right
	{ — move cursor up
	" — move cursor down 
	
	BEHAVIOR
	
	Storage of a numeral ('m' operator)
	— The stored numeral is kept until REAPER is quit or it's overwritten 
	with another numeral.
	— If a numeral is broken with one part on one line and another on another line 
	(odd use case but it's not impossible), only the second part will be stored.		
	— Only genuinely negative numerals are stored as negative, a minus operator 
	between numerals doesn't make the second one negative; a genuinenly negative 
	numeral is one which is preceded with minus following other operator, negative 
	numeral which follows an opening parenthesis, one which starts an expression 
	or one which represents a result of calculation following '=' operator.
	— Storing 0 clears the memory.
	
	
	Recall of a stored numeral ('r' operator)
	— If as a result of recall a gap is created between digits it will be ignored 
	in the calculation and sequence of digits will be treated as a single number
	
	The input of numerals and operators is performed either directly from keyboard 
	or by clicking the list items.
	The user input is stored between script runs until REAPER is quit or 'c' operator 
	is used.

	A math expression can continue on a next line, either current line may end with 
	a math operator or the next line start with one. A line can also be broken at 
	a numeral with one part on one line and another on the next line, not practical 
	but possible.
	
	After displaying the result with '=' operator, calculation can continue with such 
	result being its first member PROVIDED the result is followed by a math operator 
	on the same line. If it's not followed by a math operator but followed by a new line 
	such result is ignored in further calculations and the first numeral on the new line 
	is considered the first member of a new expression. The last condition is always 
	true when CONTINUE_ON_NEW_LINE setting is enabled in the USER SETTINGS below.

]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- Enable by inserting any character between the quotes
-- to make the script create a new line automatically
-- after '=' operatior has been executed to display the result
-- of the latest calculations;
-- if enabled, the 'n' operator for manual new line creation
-- will be disabled

CONTINUE_ON_NEW_LINE = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
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

	--Msg(gfx.mouse_cap)

	return gfx.showmenu(menu) -- menu string

	end

end
-- USE:
--[[
local retval = Reload_Menu_at_Same_Pos2(menu)
	if retval == xyz then -- returned menu item index other than 0
-- 	DO STUFF
	end
	if retval > 0 then goto RELOAD
	else return r.defer(function() do return end end)
	end
]]


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function process_backspace(line)
line = line:match('|[%^%*/%+%-=]+ $') and line:sub(1,-3) or line:match('.+[%^%*/%+%-=]+ $') and line:sub(1,-4) -- delete operators accounting for surrounding spaces, first on the line without deleting the line and elsewhere
or ( line:match('^[%^%*/%+%-=]+ $') -- delete first operator on a line
or line:match('.+|.+$') and #line:match('.+|(.+)$') == 1 ) -- delete 1st digit on a line other than the 1st
-- line:sub(1,-3) -- the empty line will be deleted as well
and line:sub(1,-2) -- the empty line is not deleted
or (line:match('.+|.+$') or #line > 1) and line:sub(1,-2) -- delete digits, periods, parentheses
or #line == 1 and ' ' -- delete very first digit on the first line (ADD OPTION OF THE VERY 1st OPERATOR DELETION ON THE 1st LINE, seems done)
or line
line = #line:gsub(' ','') == 0 and '' or line:match('.+| $') and line:sub(1,#line-1) or line -- prevent handging spaces at the start of empty lines, this will interefere with parenthesis conditions
return line
end


function process_period(line, input)
local last_num = line:match('|[%-%s]*[%d%.]+$') or line:match('.*%D ([%-%d%.]+)$') or line:match('^[%-%s]*[%d%.]+$') -- either the very 1st on a line other than the 1st, very last numeral following operator or the only numeral
local result = line:match('.+%D [%-%d%.]+') and line:match('.+= [%-%d%.]+$')
input = last_num and not last_num:match('%.') and not result and input -- numeral doesn't already contain a period and it's not a calculation result
or '' -- prevent at the start of the 1st or any new empty line and all other cases
return input
end


function get_expression(str)
local substr = str:match('.+= (.+)')
	if not substr then return str -- equal sign not found
	else
	local new_line = str:match('= %-?%s*[%d%.]+|(.+)') -- new expression on a new line, because current ends with result
	return new_line or substr:match('[%^%*/%+%-]+[|%s]?') and substr -- only include last result in the new expression if the result is followed by an operator on the same line
	end
end


function process_mem(str)
	if str:sub(#str,#str) == '.' then return end -- prevent storing incomplete decimal
return
str:match('^[|%s]*%(?(%-%s*[%d%.]+)[|%s]*$') -- the only negative numeral incl. after opening parenthesis, accoutning for empty lines
or str:match('= (%-%s*[%d%.]+)$') -- negative last result after '=' sign
or str:match('= %-?[%d%.]+|(%- [%d%.]+)$') -- first negative numeral on a new line after result on the prev line
or str:match('[%^%*/%+]+%s*|?(%-%s*[%d%.]+)$') -- negative numeral after operators incl. on prev line

or str:match('[|%s]*%(?([%d%.]+)[|%s]*$') -- the only numeral, incl. after opening parenthesis, accoutning for empty lines
or str:match('= ([%d%.]+)$') -- last result after '=' sign
or str:match('|(%s*[%d%.]+)$') -- first numeral on a new line
end


function process_parenthesis(line, input)
local last_parenth = line:match('.*([%(%)]+)')
local input =
(#line == 0 or line:sub(#line,#line) == '|') and input == ')' and '' -- starting a line with closing parenthesis
or #line > 0 and (input == '(' and last_parenth ~= '(' and not line:match('.+[%^%*/%+%-]+ $') and not line:match('.+|$') -- adding opening parenthesis not preceded by an operator unless all preceding lines are empty
or input == ')' and last_parenth ~= ')' and not line:match('.+%d$') -- adding closing parenthesis not preceded by a numeral
or input == '(' and last_parenth == '(' and line:match('.+%d$') -- adding opening parenthesis immediately after numeral
or input == ')' and not line:match('.*%(') and line:match('.+%d$') ) -- adding closing parenthesis without there being at least one opening parenthesis; not completely failproof with nested parentheses but at least something
and ''
or input
return input
end


function process_operators(line)
-- if one operator is inserted immediately after another, it replaces the first one
return (line:match('^[%^%*/%+]+ $') or line:match('.+|[%^%*/%+]+ $')) and line:sub(1,-3) -- at the beginning of the 1st or any new line
or (line:match('^[%^%*/%+]+$') or line:match('.+|[%^%*/%+]+$')) and line:sub(1,-2) -- same but without preceding space
or line:match('.+[%^%*/%+%-]+ $') and line:sub(1,-4) -- elsewhere
or line:match('.+[%^%*/%+%-]+$') and line:sub(1,-3) -- same but without preceding space
or line
end


function move_cursor_horiz(src_str, input, cursor)
local idx = src_str:find(cursor) -- get current cursor pos, idx is the capture start value, returns correct value for multibyte characters as well
local str = src_str:gsub(cursor,'') -- remove cursor, also helps to get accurate string length if cursor is a multibyte character
local left, right = input == '<', input == '>'
idx = idx and (left and idx > 1 or right and idx < #str+1) and idx -- validate target position excluding outmost positions // +1 to compensate for cursor deletion above
	if idx and #str > 0 --and not str:match('|? ')
	then -- excluding empty lines with single space, used to make them visible, to prevent glitches
		if left then
		local pt1 = str:sub(1,idx-2)
		local pt2 = str:sub(idx-1,#str)
		pt1 = (pt1:match('| $') or pt1:match('^ $')) and pt1:sub(1,#pt1-1) or pt1 -- when lines are empty they start with a single space after the pipe '|' or with a single space only if it's the 1st line, so they're visible otherwise the pipe with turn into a separator, so when moving between the empty lines ignore the space and move the cursor straght to the line start as if there's no space
		pt2 = pt2:match('^||') and '| '..pt2:sub(2) or pt2 == '|' and '| ' or pt2 -- prevent pipe '|' glitches which convert them into separators on empty lines, by adding space between them
		return pt1..cursor..pt2
		elseif right then
		local pt1 = str:sub(1,idx)
		local pt2 = str:sub(idx+1,#str)
		pt1 = pt1:match('||$') and pt1:sub(1,#pt1-1)..' |' or pt1 == '|' and ' |' or pt1 -- prevent pipe '|' glitches which convert them into separators on empty lines, by adding space between them
		pt2 = pt2:match('^ ') and not pt1:match('[^|%s]+') and pt2:sub(2) or pt2 -- when lines are empty they start with a single space after the pipe '|' or with a single space only if it's the 1st line, so they're visible otherwise the pipe with turn into a separator, so when moving between the empty lines ognore the space and move the cursor straght to the line start as if there's no space
		return pt1..cursor..pt2
		end
	else
	return src_str
	end
end


function move_cursor_vert(str, input, cursor)

	local function split_into_lines(str)
	local t = {}
	local line = ''
		for c in str:gmatch('.[\128-\191]*') do -- by character accounting for multibyte chars
			if c ~= '|' then
			line = line..c -- keep getting the content
			else -- once line break char '|' found, store and continue recursively from this point
			-- this means that line break char '|' won't be included in the split content and will have to be re-added via table.concat(), this is good because the pipe won't be counted in calculation of new cursor position
			t[#t+1] = line
			line = '' -- reset to start bulding a new line from the next cycle
			end
		end
	t[#t+1] = line -- add last line, it won't be stored within the loop because the last line won't end with '|' pipe
	return t
	end

local lines_t = split_into_lines(str) -- idx_init 1 (loop start), t nil, will be initialized inside the function

	if #lines_t == 1 then return str end -- one line only, nowhere to move the cursor

	for line_idx, line in ipairs(lines_t) do -- move cursor between lines
	local cur_idx = line:find(cursor) -- get current cursor pos, cur_idx is the capture start value
		if cur_idx then
		local up, down = input == '{', input == '"'
		local line_idx_new = up and line_idx-1 or down and line_idx+1
			if not lines_t[line_idx_new] then -- OR if line_idx < 1 or line_idx > #lines_t // new line is out of range
			break end
		lines_t[line_idx] = line:gsub(cursor,'') -- remove cursor from the original line
			if #lines_t[line_idx] == 0 then lines_t[line_idx] = ' ' end -- if cursor was the only character on the line, prevent it from going empty because the pipe '|' will be turned into a separator and char table indexing will break
		local line = lines_t[line_idx_new]
			if line == ' ' then -- empty line
			lines_t[line_idx_new] = cursor
			elseif #line < cur_idx then -- if new line is shorter than the original cursor index, place it at the end of the new line
			lines_t[line_idx_new] = line..cursor
			else
			lines_t[line_idx_new] = line:sub(1,cur_idx-1)..cursor..line:sub(cur_idx,#line) -- insert cursor on the new line
			end
		break
		end
	end
return table.concat(lines_t,'|')
end


function format_exported_content(str, cursor)
local str = str:gsub(cursor,'')
local export = ''
	for i=1,#str do
	local char = str:sub(i,i)
		if char ~= '|' then -- keep adding
		export = export..char
		else -- line break
		char = export:match('= %-?%s*[%d%.]+$') and i ~= #str and '; ' -- line ends with result, the next line will be new expression so separate with space
		or ''
		export = export..char
		end
	end
return export
end


function overcome_GetUserInputs_bug(str)
-- if GetUserInputs retvals_csv arg contains odd parenthesis count
-- the fields string separation breaks if there're more than 1 field
-- bug report https://forum.cockos.com/showthread.php?t=288046
-- if there's odd number of parenthesis the calculation also won't work
-- so when the contents doesn't end with calculation result
-- don't display the URL of online calculator to allow double checking the result
-- because there's nothing to double check
	if str:match('= %-?[%d%.]+$') then -- if the content ends with calculation result
	return 2, ',Double-check the results:', str -- fields count, field names, the actual export string
	else
	return 1, '', str
	end
end


function calculate(str, capt)

	local function calc(num1, op, num2)
	-- if there're multiple and/or different operators in a row,
	-- the rest is ignored
	return op:match('%^') and num1^num2
	or op:match('%*') and num1*num2
	or op:match('/') and num1/num2
	or op:match('%+') and num1+num2
	or op:match('%-') and num1-num2
	end

str = str:gsub(' ','') -- remove spaces so they don't break captures
str = str:match('.+=(.+)') or str -- get expression after the last result if any
	if capt:match('[%+%-]+') then -- convert double operators only at the addition/subtraction stage
	str = str:gsub('%-%-', '+'):gsub('%-%+','-'):gsub('%+%-','-')
	end

local num1, op, num2 = str:match('(%-?[%d%.]+)(['..capt..']+)(%-?[%d%.]+)') -- minus is outside of the class pattern and precedes it to prevent capturing subtraction expressions

	if tonumber(num1) and op and tonumber(num2) then
	local result = calc(tonumber(num1), op, tonumber(num2))
	local substr = Esc(num1..op..num2)
	local str = str:gsub(substr, result, 1) -- replace the expression with its result in the orig string
	return calculate(str, capt) -- continue looking for similar expressions recursively
	end

return str

end

function CALCULATE_IN_PARENTHESIS(str) -- expressions in parenthesis (nested parenthesis NOT supported yet)
str = str:gsub(' ','') -- remove spaces so they don't break captures
local pt1, expr, pt2 = str:match('(.*)(%(.-%))(.*)') -- capturing the very last expression in parenthesis, as this is the sure way to capture only one when there're nested parentheses; capturing all parts to be able to combine with the parenthesis expression result below

	if expr then
	local substr = expr:gsub('[%(%)]','') -- remove parentheses
	--[-[
		for _, capt in ipairs({'%^','%*/','%+%-'}) do
		substr = calculate(substr, capt)
		end
	--]]
	--[[ OR
	substr = calculate(substr, '%^')
	substr = calculate(substr, '%*/')
	substr = calculate(substr, '%+%-')
	--]]
	local str = pt1..substr..pt2 -- re-combine, replacing the expression with its result in the orig string
	return CALCULATE_IN_PARENTHESIS(str) -- continue looking for next expression in parenthesis recursively
	end

return str

end


-- MAIN ROUTINE

CONTINUE_ON_NEW_LINE = #CONTINUE_ON_NEW_LINE:gsub(' ','') > 0

local off = CONTINUE_ON_NEW_LINE and ' (OFF)' or '' -- indicate new line operator as disabled if the setting is enabled // preferable over disabling the menu item with # because in the latter case when 'n' key is pressed the returned menu output will be 0 and will trigger menu exit

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named

function count_lines(str)
return select(2, str:gsub('[|]',''))
end

r.PreventUIRefresh(1)

::RELOAD::

local mem = r.GetExtState(named_ID,'MEMORY') -- saving 0 clears current memory

local num = {'m',1,2,3,4,5,6,7,8,9,0,'(',')',' + ',' - ',' / ',' * ',' ^ ','.','=','r','b','','|','<','>','{','"','e'}
-- the earliest appearence of a particular character in the menu can be used as a shortcut
-- in this case they don't have to be preceded with ampersand '&'
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest appearance in the menu
-- some characters still do need ampresand, e.g. < and >;
-- in this menu digits are preceded with ampersand because they may be overriden
-- by their instances appearing at the very start of a line in a mathematical expression
-- shortcut characters aren't preceded with it
-- because they won't appear anywehere else in the menu
local menu_num = {'m — Store in memory'..' ['..mem..']','&1','&2','&3','&4','&5','&6','&7','&8','&9','&0','(',')','&+','&-',
'&/ — Divide','&* — Multiply','&^ — Raise to power','&. — Period', '&= — Calculate (display result)', 'r — Recall memory',
'b — Backspace','c — Clear all','n — New line'..off,'&< — Cursor to left','&> — Cursor to right','{ — Cursor up',
'" — Cursor down','e — Export content'} -- ⁞

local cursor = '⁞'
local stored_input =  r.GetExtState(named_ID, 'INPUT')
line = line or #stored_input > 0 and stored_input or cursor..'' -- // typing line is at the top, cursor at the start

local line_cnt = count_lines(line)+2 -- 2 are title line + 1st line which doesn't contain pipe '|' character signifying a new line

local menu = 'T Y P I N G   L I N E||'..line..'||'..table.concat(menu_num,'|') -- // typing line is at the top

local output = Reload_Menu_at_Same_Pos(menu, true) -- keep_menu_open true, left_edge_dist false

	if output > 1 and output-line_cnt <= 0 or num[output-line_cnt] == 'e' then -- output the user input as text

	local output = #line:gsub('[|%s'..cursor..']','') > 0

		if not output then -- no expression or numerals
		goto RELOAD
		else
		local export = format_exported_content(line, cursor)
		local field_cnt, field_names, export = overcome_GetUserInputs_bug(export)
		export = export..(field_cnt > 1 and ',https://www.mathpapa.com/algebra-calculator.html' or '')
		local ret, output = r.GetUserInputs('YOUR CALCULATIONS (OK — reload the menu, Cancel — exit)',field_cnt,
		field_names..',extrawidth=150',export) -- stripping leading space and replacing new line char with space
			if not ret then return r.defer(no_undo) -- escape or Cancel close everything
			else goto RELOAD -- OK to reload the menu
			end
		end

	elseif output and output-line_cnt > 0 then -- // typing line is at the top
	output = output-line_cnt

	local input = num[output]

		if tonumber(input) or input == 'r' then -- type in numerals OR recall stored number from memory (r shortcut)

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')

			if not line1:match('.+%)$') then -- prevent immediately after closing parenthesis
			input = input == 'r' and mem or input
			line = line1..input..cursor..line2
			end

		elseif input == 'm' then -- store in memory (m shortcut)

		local line = line:match('(.*)'..cursor)
		local mem = process_mem(line)

			if mem then
			r.SetExtState(named_ID,'MEMORY', mem == '0' and '' or mem, false) -- persist false // remove from memory if 0 has been stored
			end

		elseif input:match('[<>]+') then -- move cursor horizontally

		line = move_cursor_horiz(line, input, cursor) -- ⁞

		elseif input:match('[%{"]+') then -- move cursor vertically

		line = move_cursor_vert(line, input, cursor) -- ⁞

		elseif input == '=' then -- calculate, display result (= operator)

		local str = get_expression(line) or line -- expression is a string after the last equal sign

			if not str:match('^[%-%s]*[%d%.]+'..cursor..'$') then -- don't run if expression consists of a single numeral, otherwise it'll be equal to itself

			str = str:gsub('[|'..cursor..']','') -- remove pipes of the menu formatting and cursor so they don't interfere, spaces are removed inside the functions

			str = CALCULATE_IN_PARENTHESIS(str)
				for _, capt in ipairs({'%^','%*/','%+%-'}) do
				str = calculate(str, capt)
				end

			str = str == '1.#INF' and str or tonumber(str) and ( tonumber(str) > math.floor(tonumber(str)) and str:match('%-?[%d%.]+') or math.floor(tonumber(str)) ) -- result of division by 0, or strip '+' operator from the result which will be added if the expression starts with '+', or strip lone hanging decimal 0
				if str then
				line = line:gsub(cursor,'')..' = '..str..(CONTINUE_ON_NEW_LINE and '|' or '')..cursor -- append the end result after '='
				end

			end

		elseif input == 'b' then -- backspace (b shortcut)

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		line1 = process_backspace(line1, cursor)

		line = line1..cursor..line2

		elseif input == '' then -- clear (c shortcut)

		line = cursor --'⁞ ' -- // typing line is at the top, only leaving cursor

		elseif input == '.' then -- decimal period

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		input = process_period(line1, input)
		line = line1..input..cursor..line2

		elseif input:match('[%(%)]+') then -- insert parenthesis preventing malformations

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		input = process_parenthesis(line1, input)

			if #input > 0 then
			line = line1..input..cursor..line2
			end

		elseif input:match('[%^%*/%+]+') then -- operators, except minus '-'

		-- prevent input of multiple operators by replacing the last with the current,
		-- minus can follow any operator
		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		line1 = process_operators(line1)
		local last_char = line1:sub(#line1,#line1)
		input = (last_char == '.' or last_char == '(' or line1:match('[%^%*/%+%-]+%s*|$') -- prevent adding after a decimal period or opening parenthesis or operator which ends the previous line
		or line1:match('= %-?%s*[%d%.]+|$') ) -- or on a new line if the prev line ends with result
		and ''
		or (line1 == '' or line1:match('.+|$')) and input:sub(2) or input -- stripping leading space from operators with spaces if they're inserted first on the very 1st or on a new line
		line = line1..input..cursor..line2

		elseif input == '|' then -- add new line (n shortcut)

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		input = CONTINUE_ON_NEW_LINE and '' or '|' -- disable new line operator when new lines are supposed to be added automatically immediately after calling the result with '=' operator, to prevent all sorts of glitches // preferable over disabling the menu item with # because in the latter case when 'n' key is pressed the returned menu output will be 0 and will trigger menu exit
		line1 = input == '|' and (line1 == '' or line1:match('|$')) and line1..' ' or line1 -- if current line ends up being empty after new one is created, add space so it remains visible
		line = line1..input..cursor..line2

		else -- minus '-' operator

		local line1, line2 = line:match('(.*)'..cursor), line:match(cursor..'(.*)')
		input = (line1:match('%-%s*$') or line1:match('%-%s*|$') or line1:match('.+%.$')) and '' -- preventing two minuses in a row, including from one line to the next, preventing minus after hanging decimal period
		or (line1 == '' or line1:match('.+|$')) and input:sub(2) -- stripping leading space from minus if inserted first on the very 1st or on a new line
		or input
		line = line1..input..cursor..line2

		end

	r.SetExtState(named_ID, 'INPUT', line, false) -- persist false // store user input in between script runs
	goto RELOAD
	elseif output == 1 then -- typing line title if 't' key is pressed
	goto RELOAD
	end

r.PreventUIRefresh(-1)


