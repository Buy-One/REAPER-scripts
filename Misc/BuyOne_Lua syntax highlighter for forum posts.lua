--[[
ReaScript name: BuyOne_Lua syntax highlighter for forum posts.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.0
Extensions: SWS/S&M recommended but not mandatory
About: 	The script formats Lua code with syntax highlighting for posting
	on Cockos offical forum http://forum.cockos.com

	If the script is run from inside REAPER it retrieves the original code
	from the selected item notes and outputs formatted code into the notes
	of a new item automatically placed next to the original one. 
	If SWS/S&M extension is installed it also stores the formatted code
	in the clipboard so no need to copy it manually from the item notes
	which pop up.

	If the script isn't run from inside REAPER it looks for the original code
	in the INPUT setting of the USER SETTINGS and outputs the formatted code
	to a file named FORMATTED CODE.txt at the path specified in the
	OUTPUT_FILE_PATH setting of the USER SETTINGS or, if no path is specified,
	the formatted code is output directly to a console.

	If block comments or multi-line literal strings are malformed, all code
	following thereafter is colored with block comment or literal string 
	color respectively. Also an error will be raised to alert about the fact.

	The script seems to work well with minified code but hasn't been tested 
	extensively in this respect and wasn't designed to support it to begin with.

	The only inconvenience in using the sctipt is that after formatting, the code
	becomes pretty much uneditable inside the forum post editor and to update
	the code in the forum post after editing, it must be run through this script
	again.		
	
	!!!! Formatting may take a while, especially when all USER SETTINGS are
	enabled and the code is relatively long, so have patience.
	If the script is run within REAPER its finishing will be indicated by 
	creation of an item with the formatted code.
	
	The resulting code is wrapped between [CODE][/CODE] tags and is ready 
	to be posted.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- The script offers 3 default color schemes activated 
-- when this setting is either empty or contains digits
-- 1 or 2 respectively between the quotes;
-- if the setting isn't empty but otherwise invalid
-- it is considered to be empty and the corresponding
-- default color scheme is applied;
-- any default color scheme can be fully or partially 
-- overriden with custom color scheme, see below
DEFAULT_COLOR_SCHEME = ""

-- To enable the following settings insert any alphanumeric
-- character between the quotes

-- Enable to have the corresponding syntax element italicized,
-- these settings don't apply to the relevant elements inside
-- comments and strings;
-- the first two settings are applied based on the color setting
-- therefore if any other element is set to the same color
-- as the one for which italics are enabled below
-- it will be italicized as well;
-- to exclude such other elements from italicizing it siffices
-- to slightly change the color code of the italicized element
-- or of other elements
KEYWORDS_ITALIC = "1"
COMMENT_ITALIC = "1"
-- this setting doesn't depend on the color as metamethods
-- are not colored separately
METAMETHOD_ITALIC = "1"

-- May be unnecessary if the code will be displayed
-- on a light background
COLOR_PUNCT_AND_OPERATORS = "1"

-- Color methods of Lua libraries, applies to both
-- default and user color schemes
COLOR_LUA_LIBS = "1"

-- All ReaScript API functions, incl. 3d party
COLOR_REAPER_LIB = "1"

-- Color separator dot between library and method names,
-- e.g. table.unpack, reaper.GetSelectedTrack,
-- this will also reduce the overall number of color tags;
-- doesn't apply to user function names in the table.key format
-- when COLOR_USER_FUNCTIONS setting is enabled below
COLOR_METHOD_DOT = "1"

-- Only if the function name is attached to parentheses,
-- e.g. my_function()
COLOR_USER_FUNCTIONS = "1"


-- This setting enables user custom colors configured
-- below and allows disabling them without the
-- need to delete their codes from the settings
-- to trigger the script default colors
USE_CUSTOM_COLORS = ""

----------------------------------------------------------

-- If you wish to change any of the default colors
-- insert HEX color code between the quotes
-- opposite of the corresponding element name, e.g. #000000,
-- shortened color format, e.g. #000, is supported,
-- the preceding hash sign is optional;
-- if no or invalid color code is supplied the script
-- default color will be used

KEYWORDS = ""
PUNCTUATION = ""
STRING = ""
NUMERAL = ""
COMMENT = ""
LITERAL_STRING = ""
-- Lua libraries
BASE_LIB = ""
COROUTINE_LIB = ""
DEBUG_LIB = ""
IO_LIB = ""
MATH_LIB = ""
OS_LIB = ""
PACKAGE_LIB = ""
STRING_LIB = ""
TABLE_LIB = ""
UTF8_LIB = ""
-- ReaScript API
REAPER_LIB = ""
GFX_LIB = ""
-- User
USER_FUNCTION = ""


------------------------------------------------------

-- Specify output file path between the double square brackets
-- either with or without the final separator;
-- !!!! only relevant if the script is run outside of REAPER,
-- the output file name will be 'FORMATTED CODE.txt';
-- it this setting is empty the code will be output
-- to the application console
OUTPUT_FILE_PATH = [[ ]]

-- Insert your original code between
-- the double square brackets
INPUT = [=[


]=] -- must be kept on a new line

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub('[%s%c]','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub('[%s%c]','') > 0 or type(sett) == 'number'
end

function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
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



function format_and_store_regular_strings(line, color, placeholder)

local start, prev_char
local str_form = ''
local counter, start_idx = 0 -- these variables ensure that a string is only formatted once its closure has been found to prevent false positives in the form of apostrophes in words inside comments which don't come in pairs like those which define a string

	for c in line:gmatch('.') do

	counter = c and counter + 1 or counter

		if c:match('[\'"]') and not start then -- OR '[\34\39]', \34 is ", \39 is ' // string opening character found, will ignore these chars within a string
		start = c
		start_idx = counter -- store possible regular string start
		str_form = str_form..c -- for now continue to reassemble the string until the genuine closure is found, if ever

		elseif start and c == start and prev_char ~= '\\' then -- string closing character found
		-- when string closing/opening character is used within the string is must be escaped with backslash
		-- therefore when closing character is found but the previous character was backslash
		-- it's certainly not the string closing character
		-- unless it's an apostrophe which in comments doesn't require escaping

		str_form = start_idx == 1 and '[color="'..color..'"]'..str_form:sub(1, counter-1)..c..'[/color]'
		or str_form:sub(1, start_idx-1)..'[color="'..color..'"]'..str_form:sub(start_idx, counter-1)..c..'[/color]'
		counter = counter + (#str_form-counter) -- increase counter value by the number of characters added as color tags; the length of the color tags by which str_form has been lengthened is 25 char, but this formula can account for additional tags if used

		start = nil -- reset
		else -- string characters between opening and closure and rest of the characters
		str_form = str_form..c -- keep re-assembling the line
		end

	prev_char = c -- store last character to be used as a condition of string closure

	end


-- store formatted strings and replace with a placeholder to restore later
local str_t = {}
local pattern = '%[color="'..color..'"%].-%[/color%]'
	for str in str_form:gmatch(pattern) do -- literal string is only valid when square brackets aren't separated by space
		if str then
		str_t[#str_t+1] = str
		end
	end

local i, s = 0, ' '
local str_form = str_form:gsub(pattern, function() i=i+1 return s..placeholder..i..s end) -- replace the original captures with numbered placeholders
return str_form, str_t, placeholder

end



function restore_regular_strings(line, t, placeholder, clear_format)
-- is used to restore regular string captures from placeholders which replaced them in format_and_store_regular_strings()
-- replaces code placeholder with the original code which was temporarily replaced by it
	if line and placeholder and t and #t > 0 then
	local s = ' '
		for i = 1, #t do
		local repl = t[i]
		repl = (clear_format and repl:gsub('%[color=".-"%]',''):gsub('%[/color%]', '')
		or repl):gsub('%%','%%%%')
		line = line:gsub(s..placeholder..i..s, repl)
		end
	end
return line
end



function get_first_unbalanced_opening(line)
-- used inside format_multi_line_or_unfinished_block()

	local function locate_not_long_block(line)
	local i = 1
	local counter = 0
		repeat
		local st, fin, capt = line:find('([%[%]]+)', i)
			if capt then
			-- only respect not long openings/closures because nested unfinished blocks cannot break a long block,
			-- conversely nested unfinished long blocks cannot break a not long block;
			-- use select and gsub to count captures because the capture may include stray square brackets,
			-- i.e. [=[]] or several openings/closures [[[[ if there's no gap between them
			counter = counter + select(2,capt:gsub('%[%[',''))
			counter = counter - select(2,capt:gsub('%]%]',''))
				if counter == 0 then return fin end
			end
		i = capt and fin+1 or i+1
		until i > #line
	end

local i = 1

	repeat
	local st_init, fin_init, capt_init = line:find('(%[=*%[)', i) -- requires capture parenthesis to return captured string, for start/end it's not required
		if not capt_init or st_init > 3 and line:sub(st_init-3,fin_init):match('%-%-[%-%s]+')
		then return end -- no block opening on the line and ignoring an opening preceded by comment hyphens unattached to it or more than 2 in number which form a single line comment occupying the rest of the line, or if after the captured opening there's no closure which could happen in case it's a multi-line block comment opening
	local length = capt_init:match('=+') or ''
		if #length > 0 then -- long block
		-- the pattern can accurately capture a long block because
		-- it's closed as soon as a closure balancing out its opening (containing the same number of = signs) is found
		-- unfinished nested blocks cannot break a long block
		local pattern = '%['..length..'%[.-%]'..length..'%]'
		local st, fin, capt = line:find('('..pattern..')', i)
			if capt then i=fin+1
			else
			return st_init
			end
		elseif capt_init then -- not long block
		-- examine not long block capture integrity by counting openings and closures which must evaluate to 0 if block is finished,
		-- use of pattern to capture not long block is flawed because - (dash) operator
		-- cannot capture the last closure if there're nested blocks, e.g. in '[[ [[ ]] ]]' the pattern '%[%[.-%]%]'
		-- will capture the first closure as the closest whereas the actual block ends further along the line
		-- +/* operators aren't suitable either because they're prone to capture content between blocks
		-- which must be formatted separately, e.g. in '--[[ ]] some code --[[ ]]' the pattern '%[%[.*%]%]' will capture everything
		local block_fin = locate_not_long_block(line:sub(st_init))
			if block_fin then i = st_init+block_fin+1
			else
			return st_init
			end
		else -- this condition is unlikely to be true, leaving as a safeguard against loop errors
		i=i+1
		end
	until i >= #line

end



function is_regular_comment_start(line)
-- used as a condition before format_multi_line_or_unfinished_block() and inside it

-- search for a regular string opening
-- the function only works accurately because the string which is fed in
-- lacks single line block comments / literal strings due to their replacement with placehlders,
-- which obviates detection of closures,
-- and the detected opening will necesarily belong to a mutli-line block comment / literal string
local i = 1
	repeat
	local st1, fin1, capt = line:find('(%-%-)', i)
		if st1 then
			if line:find('(%-%-%[=*%[)', st1) then
			-- the double hyphen is attached to a multi-line block comment opening
			return end
		-- look for any multi-line block literal string opening which precedes the double hyphen
		-- in which case the found double hyphen will be inside the block and thus irrelevant
		local i = 1
			repeat
			local st2, fin2 = line:find('(%[=*%[)', i)
				if st2 and st2 < st1 then
				-- there's a multi-line block literal string opening which precedes the double hyphen
				return end
			i = i+1
			until i > st1
		return true end
	i=i+1
	until i > #line
end



function find_closure(line, multi_line_block_st, nested_block_cnt)
-- used inside format_multi_line_or_unfinished_block()

local pattern = ('='):rep(#multi_line_block_st)
local long = #multi_line_block_st > 0
local i = 1
local closure, line_rest
	repeat
	local st, fin, capt = line:find('([%[%]=]+)', i)
		if capt and not long then
		-- use select and gsub to count captures because the capture may include stray square brackets,
		-- i.e. [=[]] or several openings/closures [[[[ if there's no gap between them
		nested_block_cnt = nested_block_cnt + select(2, capt:gsub('%[%[', ''))
		nested_block_cnt = nested_block_cnt - select(2, capt:gsub('%]%]', ''))
		--	if capt == '[[' then nested_block_cnt = nested_block_cnt+1
		--	elseif capt == ']]' then nested_block_cnt = nested_block_cnt-1
		--	end
			if nested_block_cnt == 0 then  -- all openings and closures are balanced out, i.e. finished block
			closure, line_rest = line:sub(1,fin), line:sub(fin+1,#line) -- return closure with enclosed code and any code which follows it
			break
			end
		i = fin+1
		elseif capt and capt:match('%]'..pattern..'%]') then -- closure balancing out the opening, i.e. finished long block
		-- when the block is long the nested blocks don't matter, the only thing which matters
		-- is existence of a balancing closure, the first one found is the one which closes a long block
		closure, line_rest = line:sub(1,fin), line:sub(fin+1,#line) -- return closure with enclosed code and any code which follows it
		break
		end
	i = i+1
	until i > #line
return closure, line_rest or line, nested_block_cnt -- fall back on original line var to be able to process and return it otherwise line_rest return value will overwrite the original line outside if nil
end


function format_multi_line_or_unfinished_block(...) -- block comment and block literal string

local lines_t, line, i, COLOR, multi_line_block_st, nested_block_cnt, block_comment, block_liter_str, err, regul_str_t, regul_str_placeholder, block_comment_t, comment_placeholder, liter_str_t, liter_str_placeholder = table.unpack({...},1,15) -- start and end args ensure than nil fields are unpacked as well // nested_block_cnt is fed in as a numeral so is always valid; specify start and end indices to prevent nils from breaking the unpack function

-- these two are only used to assign appropriate color, pattern and error message values depending on the type of content
local block_comment, block_liter_str, st_idx = block_comment, block_liter_str

	if not (block_comment or block_liter_str) then -- block's first line
	-- get start of the first opening without matching closure
	-- this will be either multi-line block opening or an unfinished block opening
	st_idx = get_first_unbalanced_opening(line)
		if st_idx then
		local line = line:sub(st_idx > 2 and st_idx-2 or 1) -- rewind the string 2 places to search for comment double hyphen in order to determine the block type, because the double hyphen is ignored in the above function; the ternary expression is needed in case the returned index is 1, -2 will produce negative number which will rewind the string from the end
		block_comment, block_liter_str = line:match('^%-%-%['), line:match('%[')
		end
	end

local color = block_comment and COLOR.comment or block_liter_str and COLOR.liter_string
local block_type = block_comment and 'block comment' or block_liter_str and 'literal string' -- for the error messages
local line_form, block_pre, block_post, allow_once
local unfinished_block_err = block_type and ' there\'s an unfinished \n\n\t '..block_type..' \n\n   in the input string'
local err = err

-- literal string and block comment is only valid when there's no space between square brackets, between hyphens and between hyphens and square brackets // square brackets can also be separated by equal sign if the block itself includes square brackets

	if st_idx and not multi_line_block_st then
	-- split the line into the block part and preceding part
	-- the line var could end up as an empty string if the block starts at the beginning of the line,
	-- because end arg value 0 in string.sub() produces empty string
	-- line var will go through the rest of the formatting subroutines of the main loop thanks to allow_once var
	-- and be added to the table as line_form var at the end of the loop cycle
	line, block_post = table.unpack(block_comment and {line:sub(1, st_idx-3), line:sub(st_idx-2)}
	or block_liter_str and {line:sub(1, st_idx-1), line:sub(st_idx)})
	multi_line_block_st = block_post:match('%[(.-)%[') -- store equal signs, if any, between the opening brackets to be able to identify the genuine closing brackets which must include the same number of equal signs, if any // assign here because block_post var will be updated below
	-- count openings on the first line of the block
	-- when the block isn't long, only counting not long openings because they're the ones
	-- which along with closures determine when a not long block is finished if ever
	-- nested long blocks are inconsequential in this case
	-- first line with closures doesn't get through to this function being intercepted earlier
	-- and fed into color_unfinished_block()
	nested_block_cnt = #multi_line_block_st == 0 and nested_block_cnt + select(2, block_post:gsub('%[%[', '')) or 0
	block_post = '[color="'..color..'"]'..block_post..(i == #lines_t and '[/color]' or '') -- close if it's the last line in which case it will be an unfinished block
	allow_once = 1
	err = i == #lines_t and unfinished_block_err -- opening is on the last line which means the block is unfinished, if there were a closure it would have been a single line block but these are replaced with placeholders upstream of this function in the main loop, therefore if opening is there, it's certainly not a single line block but an unfinished multi-line

	elseif multi_line_block_st then

	block_pre, line, nested_block_cnt = find_closure(line, multi_line_block_st, nested_block_cnt)

		if block_pre then -- closure of a finished block
		block_pre = block_pre..'[/color]' -- will be re-added back to the formatted line as a prefix at the end of the current loop cycle
			if not line then -- not line because the block's last line is alone on the line with no following code or empty spaces
			line = '' -- assign empty string to let it through the rest of the routine to be added back into the lines_t table as line_form var at the end of the loop cycle
			end
		multi_line_block_st, multi_line_block_end, block_comment, block_liter_str = nil -- reset to let the detached code through for further formatting downstream of this function even if line var is empty because it will be added empty as well
		else -- lines between block comment bounds, nothing to format OR block closure which doesn't balances out its opening
		line_form = line..(i == #lines_t and '[/color]' or '') -- if nested_block_cnt isn't reset to 0 due to unbalanced square brackets in the nested blocks, keep adding the following code lines and only close the color tag at the end of the loop
		err = i == #lines_t and nested_block_cnt >= 0 and 'there\'s an unbalanced \n\n '..(block_type:match('comm')
		and block_type or '    '..block_type:gsub('literal', 'multi-line %0'):gsub('string','\n\n\t%0'))
		..' opening \n\n    in the input string'
		or err -- i == #lines_t will only be true here is there's a malformed block in which case nested_block_cnt > 0 because it's not totally offset by closures as is the case of a finished block, unless there're no nested blocks in which case nested_block_cnt will be 0; the number of offending line isn't included because figuring it out is not straightforward
		end

	end

-- Process block which starts on the same line which the current block ends on
-- e.g. "foo ]] bla bla [[ bar"
	if block_pre then -- last line of the current block followed by the rest of the code
	-- line var will contain the code which follows the closure of the current block

		if line:match('%[=*%[') and not is_regular_comment_start(line) then
		-- get start of the first opening without matching closure
		-- this will be either new multi-line block opening or an unfinished block opening
		local st_idx = get_first_unbalanced_opening(line)
			if st_idx then
			local line_tmp = line:sub(st_idx > 2 and st_idx-2 or 1) -- rewind the string 2 places to search for comment double hyphen in order to determine the block type, because the double hyphen is ignored in the above function; the ternary expression is needed in case the returned index is 1, -2 will produce negative number which will rewind the string from the end
			block_comment, block_liter_str = line_tmp:match('^%-%-%['), line_tmp:match('%[')
			-- split the line into the block part and preceding part
			-- the line var could end up as an empty string if the block starts at the beginning of the line,
			-- because end arg value 0 in string.sub() produces empty string
			-- line var will go through the rest of the formatting subroutines of the main loop thanks to allow_once var
			-- and be added to the table as line_form var at the end of the loop cycle
			line, block_post = table.unpack(block_comment and {line:sub(1, st_idx-3), line:sub(st_idx-2)}
			or block_liter_str and {line:sub(1, st_idx-1), line:sub(st_idx)})
			-- reinitialize the variables which were reset so that this function can be triggered
			-- on the next loop cycle to process lines of the new block
			-- same as in the routine above
			multi_line_block_st = block_post:match('%[(.-)%[') -- store equal signs, if any, between the opening brackets to be able to identify the genuine closing brackets which must include the same number of equal signs, if any // comes before formatting with color tags to ensure accurate capture
			nested_block_cnt = #multi_line_block_st == 0 and nested_block_cnt + select(2, block_post:gsub('%[%[', '')) or 0 -- count openings of a non long block on the first line of the new block
			allow_once = 1 -- to allow line var content between blocks closure and opening to be processed further, because multi_line_block_st will keep being true and otherwise prevent processing downstream
			local color = block_comment and COLOR.comment or block_liter_str and COLOR.liter_string
			block_post = '[color="'..color..'"]'..block_post..(i == #lines_t and '[/color]' or '') -- close if it's the last line in which case it will be an unfinished block
			err = err or i == #lines_t and unfinished_block_err -- generate error if it's the last line with an unfinished new block
			end
		end
	end

-- restore original regular strings, single line block comments / literal strings
-- inside the block which have been replaced with a placeholder
-- inside functions which precede this function in the main loop
-- this helps to ignore nested openings / closures formatted in regular string syntax, e.g. '[[some code]]'
-- and single line block openings / closures, e.g. --[[foo]] or [=[ bar ]=]
-- in counting the overall number of nested blocks in order to determine whether the main block is finished,
-- along the way other regular strings, single line block comments / literal strings
-- will have been replaced with a placeholder so all need restoration
-- because there's no point in coloring them inside the block and because if they're left formatted
-- their color will take precedence over the block color as in Cockos forum nested color tags take precedence
local clear_format = 1
	if line_form then -- line within the block
	line_form = restore_regular_strings(line_form, regul_str_t, regul_str_placeholder, clear_format)
	line_form = re_store_single_line_block_comment_or_liter_str(line_form, block_comment_t, comment_placeholder,
	clear_format, COLOR)
	line_form = re_store_single_line_block_comment_or_liter_str(line_form, liter_str_t, liter_str_placeholder,
	clear_format, COLOR)
	end
	if block_post then -- first line of the block which follows the preceding code
	block_post = restore_regular_strings(block_post, regul_str_t, regul_str_placeholder, clear_format)
	block_post = re_store_single_line_block_comment_or_liter_str(block_post, block_comment_t, comment_placeholder,
	clear_format, COLOR)
	block_post = re_store_single_line_block_comment_or_liter_str(block_post, liter_str_t, liter_str_placeholder,
	clear_format, COLOR)
	end
	if block_pre then -- last line of the block which preceded the rest of the code
	block_pre = restore_regular_strings(block_pre, regul_str_t, regul_str_placeholder, clear_format)
	block_pre = re_store_single_line_block_comment_or_liter_str(block_pre, block_comment_t, comment_placeholder,
	clear_format, COLOR)
	block_pre = re_store_single_line_block_comment_or_liter_str(block_pre, liter_str_t, liter_str_placeholder,
	clear_format, COLOR)
	end

return multi_line_block_st, line, line_form, allow_once, block_pre,
block_post, nested_block_cnt, err, block_comment, block_liter_str

end


function get_regular_comment_opening(str)
local i = 1
	repeat
	local st, en = str:find('%-%-', i)
		if st then
		local substr = str:sub(st+2)
			-- disambiguating from opening of a block comment
			-- which is processed separately
			if not substr:match('^%[=*%[') then
			return str:sub(st)
			else i = en+1
			end
		else
		i = i+1
		end
	until i > #str
end



function re_store_single_line_block_comment_or_liter_str(line, t, placeholder, clear_format, color_t, hyphens, regul_str_t, regul_str_placeholder)
-- single line block comment or literal string are only valid
-- when square brackets aren't separated by space,
-- but they could be saperated by identical number of = signs;
-- if this routine has been actualized such single line block will
-- necessarily be finished, because infinished ones are intercepted
-- at the beginning of the main loop with color_unfinished_block()

	local function locate_not_long_block(line)
	local i = 1
	local counter = 0
		repeat
		local st, fin, capt = line:find('([%[%]]+)', i)
			if capt then
			-- only respect not long openings/closures because nested unfinished blocks cannot break a not long block
			-- use select and gsub to count captures because the capture may include stray square brackets,
			-- i.e. [=[]] or several openings/closures [[[[ if there's no gap between them
			counter = counter + select(2,capt:gsub('%[%[',''))
			counter = counter - select(2,capt:gsub('%]%]',''))
				if counter == 0 then return fin end
			end
		i = capt and fin+1 or i+1
		until i > #line
	end

local t = t or {}

	if hyphens then -- storage stage

	local color_code = placeholder:reverse():match('LITERALSTRING') and color_t.liter_string or color_t.comment
	local line_tmp, s, w1 = line, ' ' -- use copy line_tmp to traverse the line to allow formatting the original line during the loop without lengthening the loop and complicating the capture

	local i = 1
		repeat
		local st_init, fin_init, capt_init = line_tmp:find('('..hyphens..'%[=*%[)', i) -- requires capture parenthesis to return captured string, for start/end it's not required
			if not capt_init --or st > 3 and line_tmp:sub(st-3):match('%-%-[%-%s]+')
			or not line_tmp:sub(fin_init+1):match('%]=*%]')
			then -- no block opening on the line or no closure which could happen in case it's a multi-line block comment opening
			break end
		local length = capt_init:match('=+') or ''
			if #length > 0 then -- long block
			-- the pattern can accurately capture a long block because it's closed
			-- as soon as a closure balancing out its opening (containing the same number of = signs) is found
			-- unfinished nested blocks cannot break a long block
			local pattern = '%['..length..'%[.-%]'..length..'%]'
			local st, fin, capt = line_tmp:find('('..pattern..')', i)
				if capt then
				-- if the single line block comment / literal string processed here includes regular strings
				-- e.g. [[foo = "some string"]] or --[[foo = "some string"]]
				-- the 'line' arg will come in with the regular string replaced by a placeholder
				-- after format_and_store_regular_strings()
				-- so restore them using their placeholders and remove any formatting
				-- so that the orginal code is included in the block comment / literal string
				capt1 = restore_regular_strings(capt, regul_str_t, regul_str_placeholder, 1) -- clear_formatting 1 true
				t[#t+1] = '[color="'..color_code..'"]'..capt1..'[/color]' -- store to the table to be restored at the end of the main loop cycle to simplify processing of other elements because the added color tags won't stand in the way
				capt = Esc(capt) -- use original 'capt' var in case it contains regular string placeholders, because after restoration above 'capt1' var won't contain them and replacement on the next line won't work
				line = line:gsub(capt, s..placeholder..#t..s, 1) -- replace original comment / literal string with a placeholder to be restored at the end of the main loop cycle, the processing of the modified line will continue after the function // only 1 replacement per gsub run to prevent replacing identical captures with identically numbered placeholders
				i=fin+1
				else
				i=i+1
				end
			elseif capt_init then -- not long block
			-- examine not long block capture integrity by counting openings and closures which must evaluate to 0
			-- if block is finished, use of pattern to capture not long block is flawed because - (dash) operator
			-- cannot capture the last closure if there're nested blocks, e.g. in '[[ [[ ]] ]]' the pattern '%[%[.-%]%]'
			-- will capture the first closure as the closest whereas the actual block ends further along the line
			-- +/* operators aren't suitable either because they're prone to capture content between blocks
			-- which must be formatted separately, e.g. in '--[[ ]] some code --[[ ]]' the pattern '%[%[.*%]%]' will capture everything
			local block_fin = locate_not_long_block(line_tmp:sub(st_init))
				if block_fin then -- comments for expressions see above
				capt = line_tmp:sub(st_init, st_init+block_fin):match('.+%]') -- trimming possible trailing code because block_fin doesn't becessarily indicate the last square bracket position
				capt1 = restore_regular_strings(capt, regul_str_t, regul_str_placeholder, 1)
				t[#t+1] = '[color="'..color_code..'"]'..capt1..'[/color]'
				capt = Esc(capt)
				line = line:gsub(capt, s..placeholder..#t..s, 1)
				i = st_init+block_fin+1
				else
				i=i+1
				end
			else -- this condition is unlikely to be true, leaving as a safeguard against loop errors
			i=i+1
			end
		until i > #line_tmp

	else -- restoration stage
		if t and #t > 0 then -- re-add single line block comments / literal strings
		local s = ' '
			for k, v in ipairs(t) do
			local v = (clear_format and v:gsub('%[color=".-"%]',''):gsub('%[/color%]','') or v):gsub('%%','%%%%')
			line = line:gsub(s..placeholder..k..s, v) -- only found placeholders are restored
			end
		end
	end

return line, t -- t return value is only collected at the storage stage

end



function format_rest(str, syntax_t, color_t, format_sett_t)
-- find, format, store numerals and temporarily replace with a placeholder in order to prevent hex color code hash sign # being recognized as a punctuation mark requring formatting
-- placed before formatting of punctuation marks and other syntax to prevent misinterpreting of hex color numeric code as a numeral requiring formatting
-- numerals inside strings won't be affected because strings have been excluded
-- from the line in the main loop outside of the function

local num_t = {}
local placeholder = (' ORIGINALNUMERAL '):reverse()
	for w in str:gmatch('[%w_%.]+') do -- %w allows to capture alphabetic characters and thereby exclude numerals included in variable names which may also contain underscore, because tonumber(w) below will produce falsehood, including the dot in case the capture is a decimal number which also ensures that the dot is colored along with the digits
		if w and tonumber(w) then
		num_t[#num_t+1] = '[color="'..color_t.numeral..'"]'..w..'[/color]'
		str = str:gsub(w, placeholder) -- replace original numeral with a placeholder to be restored at the end of the function
		end
	end

local punct_color = syntax_t.punct.color
local closure = '%[/color%]'
local COLOR_PUNCT_AND_OPERATORS = format_sett_t.color_punct_and_operators
local punct_form = COLOR_PUNCT_AND_OPERATORS and '%[color="'..punct_color..'"%]' or ''
local dot_form = COLOR_PUNCT_AND_OPERATORS and punct_form..'%.'..closure or '%.'

-- format punctuation marks and re-assemble the string to prevent confusion with color tag punctuation marks
local str_form = ''

	if COLOR_PUNCT_AND_OPERATORS then

		for w in str:gmatch('.') do
		local found
			for k, punct in ipairs(syntax_t.punct) do
				if punct == w then
				str_form = str_form..'[color="'..punct_color..'"]'..w..'[/color]'
				found = 1
				break end
			end
			if not found then
			str_form = str_form..w
			end
		end

	local repl = (punct_form..'..'..closure):gsub('%%', '') -- de-escape
	str_form = str_form:gsub((punct_form..'%.'..closure):rep(2), repl) -- merge formatting of concatenation dots because they've been formatted individually

	end

str_form = #str_form > 0 and str_form or str -- if COLOR_PUNCT_AND_OPERATORS setting is active str_form won't be empty

-- format reaper functions
local str = str_form -- use copy to traverse to prevent lengthening the loop of the string formatted above as further formatting is added
local COLOR_REAPER_LIB = format_sett_t.color_reaper_lib

	if COLOR_REAPER_LIB then

		for w in str_form:gmatch('%w+') do
			if w == 'reaper' or w == 'gfx' then -- gfx functions, gfx global vars are colored in the syntax_t loop below
			local reaper_func = str_form:match(w..dot_form..'(.-)'..punct_form..'.-%(')
				if reaper_func then
				local reaper_form = '[color="'..color_t.reaper..'"]'
				dot_form_repl = dot_form:gsub('%%', '') -- de-escape for replacement
				str = str:gsub(w..dot_form..reaper_func, reaper_form..w..'[/color]'..dot_form_repl
				..reaper_form..reaper_func..'[/color]')
				end
			end
		end

	end

local colon_form = COLOR_PUNCT_AND_OPERATORS and punct_form..':'..closure or ':'
local COLOR_LUA_LIBS = format_sett_t.color_lua_libs

	if COLOR_LUA_LIBS then

		for k, tab in pairs(syntax_t) do
			if k ~= 'punct' and k ~= 'base_lib' and k ~= 'keywords' and k ~= 'metamethods'
			and (COLOR_REAPER_LIB and k == 'gfx_vars' or k ~= 'gfx_vars') then -- ignoring punctuation marks because they've been already formatted above, keywords, base_lib because its methods aren't attached to a lib name and don't follow colon
			local lib, color = tab[1], tab.color -- lib name and color
				for i, method in ipairs(tab) do
				local pattern1 = lib..dot_form..method -- e.g. string.match
				local pattern2 = colon_form..method -- e.g. :match
				local method_form = '[color="'..color..'"]'
				local pattern, repl
					if str:match(pattern1) then
					pattern = pattern1
					repl = method_form..lib..closure..dot_form..method_form..method..closure
					elseif str:match(pattern2) and k ~= 'gfx_vars' then -- REAPER gfx library globar vars don't follow colon but since a few of them only consist of 1 letter this condition may produce false positives in such methods as ':gsub' because one of gfx global vars is 'g'
					pattern = pattern2
					repl = colon_form..method_form..method..closure
					end
					if pattern then
					repl = repl:gsub('%%','') -- de-escape
					str = str:gsub(pattern, repl)
					end
				end
			end
		end

	end

-- process base library and keywords

	local function format_exact_capture(str, word, opening, closure)
	-- meant to exclude variables which include keywords or base library methods
	-- e.g. 'selected' which includes method 'select' or 'ending' which includes keyword 'end'
	-- for this reason gsub on the entire str is a flawed approach because
	-- it will format both exact and included words whereas the latter must be ignored,
	-- probably supports minified code
	local i,ii = 1,1
	local str_form = ''
		repeat
		local window = str:sub(i,ii)
		local capt = window:match(word)
			if capt then
				-- make sure the word is not a part of another word such as user variable
				-- in which case it will be either preceded with alphabetic characters
				-- or followed by alphanumeric characters, or underscore in both cases,
				-- being preceded with numerals makes variable invalid, but can be followed with numerals
				if not str:sub(i == 1 and 1 or i-1, ii):match('[%a_]+'..word) -- rewind 1 char back and evaluate
				and not str:sub(i, ii+1):match(word..'[%w_]+') -- advance 1 char forward and evaluate
				then
					if word ~= 'unpack'
					-- disambiguate 'unpack' from table.unpack and string.unpack which have been formatted
					-- in the libs loop earlier
					or not str:sub(i > 17 and i-17 or i-(i-1), ii):match('%[color=.-%]unpack') -- 17 is the length of opening color tag
					then
					repl = (opening..word..closure):gsub('%%','') -- de-escape
					window = window:gsub(word, repl)
					end
				end
			str_form = str_form..window
			elseif ii == #str then -- add final window here if capt was invalid above meaning the window wasn't added above
			str_form = str_form..window
			end
		ii = ii+1; i = capt and ii or i -- only advance start value once capture has been found, to begin a new search
		until ii > #str
	return str_form
	end

	for k, tab in pairs(syntax_t) do
	local color = tab.color
	local formatted = color and '[color="'..color..'"]' -- tab.color can be invalid if tab is 'metamethods'
	-- the following two loops can be made into one for brevity, but leaving as is
		if k == 'base_lib' and COLOR_LUA_LIBS then
			for k, method in ipairs(tab) do
				if str:match(method)
				then -- do not condition by presence of a following function parenthesis because str arg is fed into this function without spaces in which case the parenthis may not be included in the string if separated from the function name by space (which is allowed)
				str = format_exact_capture(str, method, formatted, closure)
				end
			end
		elseif k == 'keywords' then
			for k, word in ipairs(tab) do
			str = format_exact_capture(str, word, formatted, closure)
			end
		end
	end

	if #num_t > 0 then -- re-add numerals instead of the placeholder
	local i = 0
	str = str:gsub(placeholder, function() i=i+1 return num_t[i] end)
	end

-- remove punctuation color formatting of dots separating methods from library names,
-- e.g. string.rep(), so that all are colored with the library color
-- OPTIONAL, I PREFER THE SEPARATOR DOT NON-COLORED
str_form = str -- use copy to traverse to prevent lengthening the loop of the string formatted above as further formatting is added

	if format_sett_t.color_method_dot then
		-- Lua functions
		for k, tab in pairs(syntax_t) do
			if k ~= 'punct' and k ~= 'keywords' and k ~= 'metamethods' then -- ignoring punctuation marks, keywords and metamethods, because only library method names are targeted
			local lib, color = tab[1], tab.color -- lib name and color
				for i, method in ipairs(tab) do
				local pattern = '%[color="'..color..'.-'..lib..'.-'..dot_form..'.-'..color..'"%]'..method -- using lib and method names explicitly to exclude user associative tables
					for w in str_form:gmatch(pattern) do
						if w then
						local color_tag = '[color="'..color..'"]'
						local repl = color_tag..lib..'.'..method..'[/color]'
						str = str:gsub(pattern..'%[/color%]', repl)
						end
					end
				end
			end
		end

	-- REAPER functions
	local reaper_form = '%[color="'..color_t.reaper..'"%]'
	local pattern = reaper_form..'reaper'..closure..dot_form..reaper_form..'.-'..closure
		for w in str_form:gmatch('('..pattern..').-%(') do
			if w then
			local reaper_func = w:match(dot_form..reaper_form..'(.-)'..closure)
			local repl = (reaper_form..'reaper.'..reaper_func..closure):gsub('%%','') -- de-escape for replacement
			str = str:gsub(pattern, repl)
			end
		end

	end

return str

end


function format_user_functions(str, syntax_t, color_t, format_sett_t)

	local function gmatch_alt(str, ...)
	-- vararg is a list of alternative capture patterns
	local i = 1
	local t = {...}
		return function()
		local st, fin, retval
			for _, capt in ipairs(t) do -- the t contains capture patterns, traverse until one of them produces valid capture
			st, fin, retval = str:find('('..capt..')',i)
				if retval then break end
			end
		i = fin and fin+1 or i+1 -- advance only after all capture patterns have been tried
		return retval
		end
	end

	function is_lua_method(str, syntax_t, punct_opening)
	-- the function mainly addresses the case of COLOR_LUA_LIBS user setting being disabled
	local opening, closure = '%[color=".-"%]', '%[/color%]'
		for k, tab in pairs(syntax_t) do
			if k ~= 'punct' and k ~= 'keywords' and k ~= 'gfx_vars' then -- ignoring punctuation marks, keywords and gfx globals, because only method names are targeted, gfx methods are addressed in the main function loop by additional condtition
			local lib_name = tab[1]
				for i, method in ipairs(tab) do
				-- the following patterns are determined by the capture of the main function gmatch_alt() loop
				-- which will always start with function name and end with a parenthesis either formatted or not
					if str:match('^'..lib_name..punct_opening..'%.'..closure..method) -- only punctuaton is formatted
					or str:match('^'..lib_name..'%.'..method) -- neither punctiation nor lua lib is formatted
					or str:match('^'..method..punct_opening) -- only punctuaton is formatted
					or str:match('^'..method..'%(') -- neither punctiation nor lua lib is formatted
					then return true
					end
				end
			end
		end
	end


	if format_sett_t.color_user_func then

	local punct_color = color_t.punct
	local str_form = str -- use copy to traverse to prevent lengthening the loop of the string formatted above as further formatting is added

	local COLOR_PUNCT_AND_OPERATORS = format_sett_t.color_punct_and_operators
	local closure = '%[/color%]'
	local punct_opening = '%[color="'..punct_color..'"%]'
	local dot_form = COLOR_PUNCT_AND_OPERATORS and punct_opening..'%.'..closure or '%.'
	local parenth = COLOR_PUNCT_AND_OPERATORS and punct_opening..'%(' or '%('
	local strength = COLOR_PUNCT_AND_OPERATORS and '.-' or ''
	-- strength is used for precision to prevent capturing variables detached from function parenthesis which is not be colored
	-- and to accurately capture separator dot depending on COLOR_PUNCT_AND_OPERATORS setting
	local pattern1 = '[%w_]+'..parenth -- regular variable as function name, e.g. my_function() or MyFunction()
	local punct = COLOR_PUNCT_AND_OPERATORS and '%[%]="/' or ''
	local pattern2 = '[%w_]+'..dot_form..'[%w_%.'..punct..']+'..strength..parenth -- the pattern captures multi-level table.key sequences, e.g. table.key1.key2 etc.
	local func_form = '[color="'..color_t.user_func..'"]'

		for w in gmatch_alt(str_form, pattern2, pattern1) do -- in this order of patterns because pattern1 can be captured when the source matches pattern2
			if w and not w:match('reaper'..dot_form) and not w:match('gfx'..dot_form) -- excluding REAPER functions in case COLOR_REAPER_LIB is not enabled because this will make them capturable here, not failproof because these can be used as user table keys
			and (not w:match('^color[=%]"]+') or w:match('^color=.-%][;=]')) -- excluding capture beginning with an opening or closing color tag because it's a false positive produced by pattern1 which would fit already formatted methods or 'function' keyword unless the user function name is preceded by ; or = without spaces // NOT SURE THESE CAPTURES ARE POSSIBLE, LEAVING JUST IN CASE
			and not is_lua_method(w, syntax_t, punct_opening) -- the function mainly addresses the case of COLOR_LUA_LIBS user setting being disabled
			then
			local repl1 = w:match(pattern1) and func_form..w:match('([%w_]+)'..parenth)..closure..parenth -- the match capture ensures that only the function name is captured in cases where it's attached to preceding syntax without spaces
			local repl2
				if w:match(pattern2) then -- traverse capture
				repl2 = ''
			 	local patt = COLOR_PUNCT_AND_OPERATORS and '([%w_]+)'..punct_opening or '([%w_]+)%p'
					for s in w:gmatch(patt) do
						if s then
						repl2 = repl2..func_form..s..closure..dot_form -- re-assemble, more reliable than simple gsub in scenarios where key names are fully or partly identical because the replacement is applied to all unless replace_capture_by_capture_number() function is employed
						end
					end
				repl2 = repl2:gsub('%%','') -- de-escape
				repl2 = #repl2 > 0 and repl2:match('(.+)'..dot_form)..parenth -- truncating the last dot and replacing with the parenthesis because the dot was added at the end of the above loop (which can't be detected) instead of the parenthesis
				end
			local repl = (repl2 or repl1):gsub('%%','') -- de-escape
				if not repl2 then -- handle cases where function name is attached to preceding syntax without spaces in which case such elements will be included in the capture w, therefore first replace the code inside the original capture and then use it as a new replacement string; doesn't apply to pattern2 captures
				local w1 = Esc(w:match('[%w_]+'..parenth))
				repl = w:gsub(w1,repl)
				end
			w = Esc(w)
			str = str:gsub(w, repl)
			end
		end

	end

return str

end


function add_extra_formatting(code, color_t, syntax_t, format_sett_t)

	local function extra_formatting(code, color, ital, bold)

		if not ital and not bold then return code end

	-- construct additional formatting tags
	local extra_form_start = (ital and '[i]' or '')..(bold and '[b]' or '')
	local extra_form_end = extra_form_start:gsub('%[', '%0/') -- closure

	-- the search for keywords and comments is based on color formatting
	-- with keywords this ensures that inside blocks and comments they won't be
	-- italicized/bolded because in there they're not color coded separately;
	-- to add additonal formatting to comments and keywords not based on color
	-- the condition of adding tags for italics must be included, for comments -
	-- in format_multi_line_or_unfinished_block(), re_store_single_line_block_comment_or_liter_str() functions
	-- and single line (stream) comment loop, and for keywords - in format_rest() function,
	-- however even in this case keywords won't be formatted inside blocks and comments
	-- because these aren't processed by format_rest() function;
	-- with metamethods the color is ignored because these aren't colored separately

	-- color arg contains either hex color code or metamethod name because the latter aren't colored separately
	-- so won't have a color tag by which they could be found
	local metamethod = color:match('^__%a+')
	local opening = metamethod and '' or '%[color="'..color..'"%]' -- either metamethod or color code
	local closure = metamethod and '' or '%[/color%]'
	local i, ii = 1, 1
	local code_form = ''

		repeat
		local window = code:sub(i, ii)
		local pattern = metamethod or opening..'(.-)'..closure -- when metamethods are processed color arg contains metamethod name because these aren't colored and must be searched directly rather than by color
		local capt = window:match(pattern)
		-- make sure the metamethod name is not a part of another word such as user variable
		-- in which case it will be either preceded with alphabetic characters
		-- or followed by alphanumeric characters, or underscore in both cases,
		-- being preceded with numerals makes variable invalid, but it can be followed by numerals
		local false_metamethod = capt and metamethod and
		(code:sub(i == 1 and 1 or i-1, ii):match('[%a_]+'..capt) -- rewind 1 char back and evaluate
		or code:sub(i, ii+1):match(capt..'[%w_]+')) -- advance 1 char forward and evaluate

			if capt and (not metamethod or metamethod and not false_metamethod)	then
			local repl
				if capt:match('%-%-') then -- comment
				--	accounting for non-block (regular) comment
				local st = capt:match('^%-%-[%[=]+') or ''
				local fin = #st > 0 and capt:match('[%]=]+%s*$') or '' -- taking into account possible trailing spaces
				local capt = capt:sub(#st+1, #capt-#fin) -- get block comment without square brackets, i.e. --[[ ]], regular comment hyphens will be included within italics tags because they're not visibly affected by formatting, capt must be local here to prevent overwriting original capt which will be used in gsub below
				-- OR
				-- local capt = capt:match(Esc(st)..'(.+)'..Esc(fin))
				repl = opening:gsub('%%','')..st..extra_form_start..capt..extra_form_end..fin..closure:gsub('%%','') -- construct adding extra formatting tags inside the comment tags, i.e. without formatting -- or --[[ ]] (this is choice designed for italics, won't look consistent if applied to formatting in bold, at this point however bold isn't supported), re-adding color tags since they've been left outside of capture and de-escaping inline because original escaped opening/closure will be needed in gsub
				end
			repl = (repl or opening:gsub('%%','')..extra_form_start..capt..extra_form_end..closure:gsub('%%','')):gsub('%%','%%%%') -- de-escape inside the parentheses and inline because original escaped opening/closure will be needed in gsub, and escape % outside
			capt = Esc(capt)
			window = window:gsub(opening..capt..closure, repl)
			code_form = code_form..window -- add to the previosuly re-assembled code
			end

			if capt and false_metamethod
			or ii == #code and not capt
			then
			code_form = code_form..window -- either add window when false metamethod was captured or add final window if capt was invalid above meaning the window wasn't added above
			end

		ii = ii+1; i = capt and ii or i -- only advance start value once capture has been found, to begin a new search
		until ii > #code
	return code_form
	end

	local function add_remove_placeholders(code, t, color, placeholder, add) -- add is boolean
		if #t == 0 then return code end
	local s, i = ' ', 0
	local placeholder = placeholder:reverse()
		if add then	-- replace
		return code:gsub('%[color="'..color..'"%].-%[/color%]',
		function() i=i+1 return s..placeholder..i..s end) -- replace the original captures with numbered placeholders
		else -- restore
			for i = 1, #t do
			local repl = t[i]:gsub('%%','%%%%')
			code = code:gsub(s..placeholder..i..s, repl)
			end
		return code
		end
	end

	if format_sett_t.metamethods then

	-- store and replace comments, regular strings and blocks with placeholders to prevent
	-- formatting these inside comments, regular strings and and blocks for the sake of consistency
	-- because in the current design neither are keywords formatted inside comments, regular strings and blocks,
	-- if COMMENT_ITALIC setting is enabled, italicized metamethods won't be discernable in the comments anyway
	-- but for the sake of design simplicity they won't be italicized in the italicized comments either
	local t = {comments = {}, str = {}, liter_str = {}}
	-- store
		for k, color in ipairs({color_t.comment, color_t.string, color_t.liter_string}) do
			for capt in code:gmatch('%[color="'..color..'"%].-%[/color%]') do
				if capt then
				local t = k == 1 and t.comments or k == 2 and t.str or t.liter_str
				t[#t+1] = capt
				end
			end
		end

	-- replace comments, regular strings and blocks with placeholders
	code = add_remove_placeholders(code, t.comments, color_t.comment, 'COMMENT', 1) -- add 1 true
	code = add_remove_placeholders(code, t.str, color_t.string, 'REGULSTRING', 1) -- add 1 true
	code = add_remove_placeholders(code, t.liter_str, color_t.liter_string, 'LITERSTRING', 1) -- add 1 true

		-- format metamethods
		for _, metamethod in ipairs(syntax_t.metamethods) do
		code = extra_formatting(code, metamethod, true, bold) -- color arg is metamethod, indicates that it's metamethod and will be used to capture it, ital is true, bold nil
		end

	-- restore comments, regular strings and blocks from placeholders
	code = add_remove_placeholders(code, t.comments, color_t.comment, 'COMMENT') -- add nil
	code = add_remove_placeholders(code, t.str, color_t.string, 'REGULSTRING') -- add nil
	code = add_remove_placeholders(code, t.liter_str, color_t.liter_string, 'LITERSTRING')  -- add nil

	end

	if next(format_sett_t.italics) then

		for elm, is_enabled in pairs(format_sett_t.italics) do
			if is_enabled then
			code = extra_formatting(code, color_t[elm], is_enabled, bold) -- color is color_t[elm], ital is is_enabled true, bold nil
			end
		end

	end

return code

end



function Get_Code_From_Item_Notes_OLD(err1, err2)

local item = r.GetSelectedMediaItem(0,0)

	if not item then
	Error_Tooltip('\n\n no selected item \n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
	return end

local ret, code = r.GetSetMediaItemInfo_String(item, 'P_NOTES', '', false) -- isSet false
local err = #code:gsub('[%c%s]', '') == 0 and err1
or select(2,code:gsub('%[color=".-"%].-%[/color%]','%0')) > 0 and err2

	if err then
	Error_Tooltip('\n\n '..err..'\n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
	return end

return code:gsub('\r','') -- removing carriage return which is auto-added to the notes

end


function Get_Code_From_Item_Notes()

local item = r.GetSelectedMediaItem(0,0)

	if not item then
	Error_Tooltip('\n\n no selected item \n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
	return end

local ret, code = r.GetSetMediaItemInfo_String(item, 'P_NOTES', '', false) -- isSet false

return code:gsub('\r','') -- removing carriage return which is auto-added to the notes

end


function Display_Formatted_Code_In_Item_Notes(code)

local item = r.GetSelectedMediaItem(0,0)
	if item then
	local item_fin = r.GetMediaItemInfo_Value(item, 'D_POSITION') + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	r.SetEditCurPos(item_fin, true, false) -- moveview true, seekplay false
	local act = r.Main_OnCommand
	act(40698, 0) -- Edit: Copy items
	act(42398, 0) -- Item: Paste items/tracks
	local item = r.GetSelectedMediaItem(0,0) -- pasted copy
	r.GetSetMediaItemInfo_String(item, 'P_NOTES', '', true) -- isSet true, delete the original code
	r.GetSetMediaItemInfo_String(item, 'P_NOTES', code, true) -- isSet true, insert formatted code
	r.UpdateItemInProject(item) -- to display the updated code inline if it's an empty item
	act(40850, 0) -- Item: Show notes for items...
		if r.CF_SetClipboard then r.CF_SetClipboard(code) end -- must be placed after 'Edit: Copy items' because the action overwrites the clipboard
	end

end


function Validate_Folder_Path(path)
-- Validate path supplied in the user settings
-- returns empty string if path is empty and nil if it's not a string
	if type(path) == 'string' then
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	-- return not path:match('.+[\\/]$') and path:match('[\\/]') and path..path:match('[\\/]') or path -- add last separator if none
-- more efficient:
	return path..(not path:match('.+[\\/]$') and path:match('[\\/]') or '') -- add last separator if none
	end
end



function Dir_Exists(path) -- short
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string represening a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
end


-- table containing user color settings
local COLOR = {
keywords = KEYWORDS,
punct = PUNCTUATION,
string = STRING,
liter_string = LITERAL_STRING,
numeral = NUMERAL,
comment = COMMENT,
-- libraries
base_lib = BASE_LIB,
coroutine_lib = COROUTINE_LIB,
debug_lib = DEBUG_LIB,
io_lib = IO_LIB,
math_lib = MATH_LIB,
os_lib = OS_LIB,
package_lib = PACKAGE_LIB,
string_lib = STRING_LIB,
table_lib = TABLE_LIB,
utf8_lib = UTF8_LIB,
-- ReaScript API
reaper = REAPER_LIB,
gfx = GFX_LIB,
-- user
user_func = USER_FUNCTION
}


-- these values are used if user color values are empty or otherwise invalid
-- as a fallback option
local COLOR_default = {
keywords = "#0000FF",
punct = "#000080",
string = "#757575",
liter_string = "#FF268B",
numeral = "#FF8000",
comment = "#008000",
-- libraries
base_lib = "#0080C0",
coroutine_lib = "#0000A0",
debug_lib = "#0000A0",
io_lib = "#0000A0",
math_lib = "#8000FF",
os_lib = "#0000A0",
package_lib = "#0000A0",
string_lib = "#8000FF",
table_lib = "#8000FF",
utf8_lib = "#8000FF",
-- ReaScript API
reaper = "#95004A",
gfx = "#874104",
-- user
user_func = "#4F4F09"
}



local COLOR_default_tomorrow = {
-- https://github.com/chriskempson/tomorrow-theme/blob/master/notepad%2B%2B/tomorrow.xml
keywords = '#4271AE',
punct = '#3E999F',
string = '#718C00',
numeral = '#C82829',
comment = '#8E908C',
liter_string = '#718C00',
-- libraries
base_lib = '#4D4D4C',
coroutine_lib = '#4D4D4C',
debug_lib = '#4D4D4C',
io_lib = '#4D4D4C',
math_lib = '#4D4D4C',
os_lib = '#4D4D4C',
package_lib = '#4D4D4C',
string_lib = '#4D4D4C',
table_lib = '#4D4D4C',
utf8_lib = '#4D4D4C',
-- ReaScript API
reaper = '#4D4D4C',
gfx = '#4D4D4C',
-- user
user_func = '#4D4D4C'
}


local COLOR_default_dracula = {
-- based on the following but modified a lot
-- https://draculatheme.com/notepad-plus-plus
-- https://raw.githubusercontent.com/dracula/notepad-plus-plus/master/Dracula.xml
keywords = '#008639',
punct = '#ff0091',
string = '#0E0573',
numeral = '#6900ff',
comment = '#6272A4',
liter_string = '#FF5555',
-- libraries
base_lib = '#AF0584',
coroutine_lib = '#AF0584',
debug_lib = '#AF0584',
io_lib = '#AF0584',
math_lib = '#AF0584',
os_lib = '#AF0584',
package_lib = '#AF0584',
string_lib = '#AF0584',
table_lib = '#AF0584',
utf8_lib = '#AF0584',
-- ReaScript API
reaper = '#AF0584',
gfx = '#AF0584',
-- user
user_func = '#AF0584'
}


function assign_color_val(t1,t2,key)
local c = type(t1[key])=='string' and t1[key]:gsub(' ','')
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return t2[key] or '#000000' -- default to black for keys the default table doesn't have
	end
return c
end

local scheme = tonumber(DEFAULT_COLOR_SCHEME)
COLOR_default = scheme == 1 and COLOR_default_tomorrow or scheme == 2 and COLOR_default_dracula or COLOR_default

	-- if user colors aren't enabled use the dafault ones
	if not validate_sett(USE_CUSTOM_COLORS) then
	COLOR = COLOR_default
	else -- assign default color values to all non-set user color settings
		for key in pairs(COLOR) do
		COLOR[key] = assign_color_val(COLOR,COLOR_default,key)
		end
	end


local SYNTAX = {}
SYNTAX.keywords = {color = COLOR.keywords, 'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while'}
SYNTAX.punct = {color = COLOR.punct, '#', '%', '&', '(', ')', '*', '+', ',',
'-', '.', '/', ':', ';', '<', '=', '>', '[', ']', '^', '{', '}', '|', '~'} -- underscore '_' is excluded because it bears no special meaning, other string library magic or escape chars (?,$,\) are excluded since they must be colored as part of a string rather than as standalone
SYNTAX.base_lib = {color = COLOR.base_lib, '_G', '_ENV', '_VERSION', 'assert', 'collectgarbage', 'dofile',
'error', 'gcinfo', 'getfenv', 'getmetatable', 'ipairs', 'load', 'loadfile', 'loadlib', 'loadstring',
'module', 'next', 'pairs', 'pcall', 'print', 'rawequal', 'rawget', 'rawset', 'require', 'select', 'setfenv',
'setmetatable', 'tonumber', 'tostring', 'type', 'unpack', 'warn', 'xpcall'}
SYNTAX.coroutine_lib = {color = COLOR.coroutine_lib, 'coroutine', 'close', 'create', 'isyieldable', 'resume',
'running', 'status', 'wrap', 'yield'}
SYNTAX.debug_lib = {color = COLOR.debug_lib, 'debug', 'debug', 'getfenv', 'gethook', 'getinfo', 'getlocal',
'getmetatable', 'getregistry', 'getupvalue', 'getuservalue', 'setfenv', 'sethook', 'setlocal', 'setmetatable',
'setupvalue', 'setuservalue', 'traceback', 'upvalueid', 'upvaluejoin'}
SYNTAX.io_lib = {color = COLOR.io_lib, 'io',  'close', 'flush', 'input', 'lines', 'open', 'output', 'popen',
'read', 'seek', 'setvbuf', 'stderr', 'stdin', 'stdout', 'tmpfile',  'type', 'write'}
SYNTAX.math_lib = {color = COLOR.math_lib, 'math', 'abs', 'acos', 'asin', 'atan', 'atan2', 'ceil', 'cos', 'cosh',
'deg', 'exp', 'floor', 'fmod', 'frexp', 'huge', 'ldexp', 'log', 'log10', 'max', 'maxinteger', 'min', 'mininteger',
'modf', 'pi', 'pow', 'rad', 'random', 'randomseed', 'sin', 'sinh', 'sqrt', 'tan', 'tanh', 'tointeger', 'type', 'ult'}
SYNTAX.os_lib = {color = COLOR.os_lib, 'os', 'clock', 'date', 'difftime', 'execute', 'exit', 'getenv', 'remove',
'rename', 'setlocale', 'time', 'tmpname'}
SYNTAX.package_lib = {color = COLOR.package_lib, 'package', 'config', 'cpath', 'loaded', 'loadlib', 'path', 'preload',
'searchers', 'searchpath'}
SYNTAX.string_lib = {color = COLOR.string_lib, 'string', 'byte', 'char', 'dump', 'find', 'format',
'gfind', 'gmatch', 'gsub', 'len', 'lower', 'match', 'pack', 'packsize', 'rep', 'reverse', 'sub', 'unpack', 'upper'}
SYNTAX.table_lib = {color = COLOR.table_lib, 'table', 'concat', 'foreach', 'foreachi', 'getn', 'insert', 'maxn', 'move',
'pack', 'remove', 'setn', 'sort', 'unpack'}
SYNTAX.utf8_lib = {color = COLOR.utf8_lib, 'utf8', 'charpattern', 'codes', 'codepoint', 'len', 'offset'}
SYNTAX.gfx_vars = {color = COLOR.gfx, 'gfx', 'r', 'g', 'b', 'a2', 'a', 'mode', 'w', 'h', 'x', 'y', 'clear', 'dest', 'texth', 'ext_retina', 'mouse_x', 'mouse_y', 'mouse_wheel', 'mouse_hwheel', 'mouse_cap'} -- global vars
SYNTAX.metamethods = {'__index', '__newindex', '__mode', '__call', '__metatable', '__tostring', '__len',
'__gc', '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__concat', '__unm', '__eq', '__lt', '__le'}


------------------ GENERATE ERROR MESSAGES START -------------------

local err1 = 'the input is empty'
local err2 = '\tthe input seems \n\n to be already formatted '

	if reaper then
	INPUT = Get_Code_From_Item_Notes()
		if not INPUT then return r.defer(no_undo) end
	end

local is_formatted_code = select(2,INPUT:gsub('%[color=".-"%].-%[/color%]','%0'))
local err = #INPUT:gsub('[%s%c]','') == 0 and err1 or is_formatted_code > 0 and err2
local wait_mess = 'the input is being formatted. \n\n\t\tplease wait...'
local path

	if err then
		if reaper then
		Error_Tooltip('\n\n '..err..'\n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
		else -- if run outside of REAPER
		print('\n'..err:gsub('%s+', ' '):upper()) -- replace multiple spaces designed for message display in REAPER with a single space; the leading new line char makes part of the script path show up in the error message if error() function is used; line breaks are ignored by native error and assert functions
		end
	return
	elseif reaper then -- inside REAPER
	-- display the tootip as long as the script runs
	-- for cases where the input is big and it takes time for the script to finish
	-- the tooltip will be unset after the main loop so it doesn't linger
	Error_Tooltip('\n\n '..wait_mess..' \n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
	else -- outside of REAPER
	-- the error will be used as a condition at the end of the routine 
	-- to either print to console or dump to file
	local non_empty_path = #OUTPUT_FILE_PATH:gsub('[%s%c]','') > 0
	err = '\n\nthe code will be output directly to the console'
	path = non_empty_path and Validate_Folder_Path(OUTPUT_FILE_PATH)
	err = not (non_empty_path or path) and 'the output_file_path is invalid'..err
	or non_empty_path and not Dir_Exists(path) and 'the output_file_path does\'t exist'..err
		if err then print('\n'..err:upper()) end
	print('\n'..wait_mess:gsub('%s+',' '):upper()) -- replace multiple spaces designed for message display in REAPER with a single space; the leading new line char makes part of the script path show up in the error message if error() function is used; line breaks are ignored by native error and assert functions
	end

------------------- GENERATE ERROR MESSAGES END -------------------


-- split into lines
local lines_t = {}
	for line in INPUT:gmatch('(.-)\n') do -- respecting empty lines
		if line then
		lines_t[#lines_t+1] = line
		end
	end

-- in the forum post formatting the nested color has precedence,
-- i.e. in [color="A"][color="B"]123[/color][/color] it's color B
-- multiple spaces and tab spaces are truncated down to a single space in the forum post

local FORMAT_SETTINGS = {
italics = {keywords = validate_sett(KEYWORDS_ITALIC), comment = validate_sett(COMMENT_ITALIC)},
metamethods = validate_sett(METAMETHOD_ITALIC),
color_punct_and_operators = validate_sett(COLOR_PUNCT_AND_OPERATORS),
color_lua_libs = validate_sett(COLOR_LUA_LIBS),
color_reaper_lib = validate_sett(COLOR_REAPER_LIB),
color_method_dot = validate_sett(COLOR_METHOD_DOT),
color_user_func = validate_sett(COLOR_USER_FUNCTIONS)
}


local multi_line_block_st
local block_comment, block_liter_str
local nested_block_cnt, malformed_block_err = 0
local liter_str_placeholder, regul_str_placeholder, comment_placeholder = ('LITERALSTRING'):reverse(),
('REGULARSTRING'):reverse(), ('COMMENTPLCHLDR'):reverse() -- placeholders must be alphabetic because random sequences of letters aren't colored unless attached to function parentheses while COLOR_USER_FUNCTIONS setting is enabled which doesn't apply to placeholders because these are padded with spaces when replacing the original pieces of code; reverse to make it more unique in case the code being formatted happens to include a namesake variable


-- In the main loop only 'line' variable goes through all the stages in each loop cycle unless
-- it contains code between opening / closing lines
-- of multi-line block comment / literal string.
-- Strings and comments are excluded from the main code by either temporary replacement
-- with placeholders (regular/literal strings, single line block comments),
-- by splitting off from the content of the 'line' variable and then
-- adding back at the end of each cycle (opening/closing line of a multi-line block comment,
-- regular aka stream comment) or by conditions preventing 'line' variable from
-- going through other formatting stages (code inside multi-line block comment / literal string)
-- because within strings and comments all syntax is formatted with the same color


	for i, line in ipairs(lines_t) do

	local line_form = ''
	local block_comment_t, liter_str_t, regul_str_t
	local block_pre, block_post
	local allow_once

	-- 1. Store regular strings
	-- precede comment / literal string routines in case their syntax is formatted
	-- as a regular string e.g. "[[some code]]"; "-- [[some code]]"; "-- some code"
	-- in which comment / literal string formatting will be misidentified as genuine
	-- because the following routines don't account for a possiblity of comment / literal string syntax
	-- being enclosed within quotes which form regular string,
	-- this also helps to ignore double square brackets formatted as regular strings in detecting genuine
	-- block comments / literal strings and counting nested blocks inside
	-- format_multi_line_or_unfinished_block() function
	-- to determine whether the block is finished;
	-- the original strings will then be restored inside the block
	-- or at the end of the current loop cycle if they don't inclosed within a block
	line, regul_str_t = format_and_store_regular_strings(line, COLOR.string, regul_str_placeholder) -- returns original line with all regular strings replaced with a modified placeholder to be restored at the end of the current loop cycle from the returned table in which the original formatted strings are stored, the processing of the modified line will continue below

	-- 2. Handle unfinished blocks and multi-line block comments / literal strings

		if line:match('%[=*%[') and not line:match('^%s*%-%-[%-%s]+%[') -- regular comment at the start of the line // a gap which follows the double hyphen or more than two hyphens make the entire line a regular comment so doesn't fit
		and not is_regular_comment_start(line) -- regular comment which starts elsewhere on the line
		or multi_line_block_st then
		multi_line_block_st, line, line_form, allow_once, block_pre, block_post, nested_block_cnt, malformed_block_err, block_comment, block_liter_str = format_multi_line_or_unfinished_block(lines_t, line, i, COLOR, multi_line_block_st, nested_block_cnt, block_comment, block_liter_str, malformed_block_err, regul_str_t, regul_str_placeholder, block_comment_t, comment_placeholder, liter_str_t, liter_str_placeholder) -- multi_line_block_end, nested_block_cnt, block_comment, block_liter_str are only returned to be fed back into the function, aren't used outside of it; malformed_block_err is fed back in order to preserve the stored message preventing it's overwriting by subsequent nil return value
		line_form = line_form or '' -- reinstate original line_form value assigned at the loop start if it's returned as nil
		line = line or lines_t[i] -- reinstate orig 'line' value when 'line' return value of the above function is nil because no block opening was found inside it
		nested_block_cnt = nested_block_cnt or 0 -- reinstate if returned as nil
		end

		if not multi_line_block_st or allow_once then -- only when block comment / literal string is false to prevent formatting code elements inside the block individually or when block opening/closure shares a line with the rest of the code

		--	3. format single line comment, placed before single line literal string routine
		--	because single line comment can be formatted as a block comment, e.g. --[[comment]]
		--	and would otherwise be captured by single line literal string pattern
		--	the originals will then be restored at the end of the current loop cycle

		--	3A. process regular comment (not single line block comment, i.e. not --[[ ]])
		-- 	must come before single line block comments are processed
		--	to avoid replacing such comments with placeholders
		--	if found inside the regular comment, because this will compicate their restoration

		local w = get_regular_comment_opening(line)
			if w then
			local clear_format = 1
			local w_form = restore_regular_strings(w, regul_str_t, regul_str_placeholder, clear_format)
			w_form = re_store_single_line_block_comment_or_liter_str(w_form, block_comment_t, comment_placeholder,
			clear_format) -- restore
			w_form = re_store_single_line_block_comment_or_liter_str(w_form, liter_str_t, liter_str_placeholder,
			clear_format) -- restore
			w_form = ('[color="'..COLOR.comment..'"]'..w_form..'[/color]'):gsub('%%','%%%%')
			local w = Esc(w)
			line = line:gsub(w, w_form)
			line, block_post = line:match('(.-)(%[color="'..COLOR.comment..'"%]%-%-.*)') -- detach comment from further processing to re-add back to the formatted line as a suffix at the end of the current loop cycle
			end

		-- 3B. Store single line block comments of which there can be several on the same line
		-- by storing them and replacing with a placeholder which will be replaced
		-- with the original comment at the end of current loop cycle,
		-- this will prevent misinetrpretation of their opening/closure square brackets
		-- as color tag square brackets in the following sub-loops
		line, block_comment_t = re_store_single_line_block_comment_or_liter_str(line, block_comment_t, comment_placeholder, nil, COLOR, '%-%-', regul_str_t, regul_str_placeholder) -- clear_format nil, hyphens '%-%-'

		-- 4. Store single line literal strings, of which there can be several on the same line
		-- before formatting the rest of the line
		-- by storing them and replacing with a placeholder which will be replaced
		-- with the original strings at the end of current loop cycle,
		-- this will prevent misinetrpretation their opening/closure square brackets
		-- as color tag square brackets in the following sub-loops
		line, liter_str_t = re_store_single_line_block_comment_or_liter_str(line, liter_str_t, liter_str_placeholder, nil, COLOR, '', regul_str_t, regul_str_placeholder) -- clear_format nil, hyphens empty string


		-- 5. format the rest

			for w, space in line:gmatch('([%w%p]*)(%s*)') do -- even though in the output code original extra spaces are retained, they're auto-reduced in the forum post if posted as a regular post or quote, they're preserved if the code is enclosed within [CODE][/CODE] tags which the output of this script is

			local w_form = format_rest(w, SYNTAX, COLOR, FORMAT_SETTINGS)
			w_form = format_user_functions(w_form, SYNTAX, COLOR, FORMAT_SETTINGS)
				if w_form then
				line_form = line_form..w_form..space
				end
			end

		end -- end of 'not multi_line_block_st or allow_once' condition

	-- 6. Restore block comments / literal strings and regular strings from placeholders
	line_form = re_store_single_line_block_comment_or_liter_str(line_form, liter_str_t, liter_str_placeholder)
	line_form = re_store_single_line_block_comment_or_liter_str(line_form, block_comment_t, comment_placeholder)

		if regul_str_t and #regul_str_t > 0 then -- restore regular strings from placeholders
		line_form = restore_regular_strings(line_form, regul_str_t, regul_str_placeholder)
		end

	-- 7. Re-add formatted line
	lines_t[i] = (block_pre or '')..line_form..(block_post or '') -- comment var must have been disambiguated with _pre and _post to prevent adding one before AND after the code in cases where code preceded or follows multi-line closure on the same line

	end


local link = '[url="https://github.com/Buy-One/REAPER-scripts/tree/main/Misc/'
..'BuyOne_Lua code highlighter.lua"][i][size="1"]Formatted with Lua code highlighter[/size][/i][/url]'
local code_form = '[CODE]\n'..table.concat(lines_t,'\n')..'\n[/CODE]\n'..link


-- generate warning if color associated with extra formatting is used for another element
-- for which extra formatting isn't supported
-- for now it's only italics, bold isn't supported
local shared_color_list, shared_color_mess = '', ''
	for elm1, is_enabled in pairs(FORMAT_SETTINGS.italics) do
	local color1 = COLOR[elm1]
		if is_enabled then
			for elm2, color2 in pairs(COLOR) do
				if elm1 ~= elm2 and color1 == color2 then
				shared_color_list = shared_color_list..(#shared_color_list == 0 and '' or ', ')..elm2
				end
			end
		end
	end
	if #shared_color_list > 0 then
	shared_color_mess =
	'The colors associated with italics formatting have been found in the following unrelated elements: '..shared_color_list
		if reaper then
		local resp = r.MB(shared_color_mess..'\n\nClick YES to apply extra formatting nonetheless.', 'WARNING', 1)
			if resp == 1 then -- OK
			shared_color_list = '' -- reset, just to reuse existing variable as a conditon for running add_extra_formatting() function below, shared_color_mess could have been reused instead
			end
		end
	end

	-- add extra formatting
	if #shared_color_list == 0 or not reaper then
	-- will run if user OK'ed the warning in REAPER or if the script is run outside of REAPER
	code_form = add_extra_formatting(code_form, COLOR, SYNTAX, FORMAT_SETTINGS)
	end


	-- export formatted code
	if reaper then
	Display_Formatted_Code_In_Item_Notes(code_form)
		if malformed_block_err then
		Error_Tooltip('\n\n '..malformed_block_err..' \n\n', 1, 1, -200, y2) -- caps, spaced true, x2 -200
		end
	-- Undo the tooltip informing that the input is being formatted
	-- generated before the main loop
	Error_Tooltip('', 1, 1, -200, y2) -- caps, spaced true, x2 -200
	return r.defer(no_undo)

	else -- run outside of REAPER

		if not err then -- err var is initialized before the main loop and stems from path being invalid					
		local f = io.open(path..'FORMATTED CODE.txt', 'w')
			if not f then print('\nCOULD\'T CREATE OR OPEN THE OUTPUT FILE') return end
		f:write(code_form)
		f:close()
		end
		if malformed_block_err or #shared_color_list > 0 then
		local addendum = '. These elements have been italicized as well.'
		local mess = malformed_block_err and shared_color_mess and malformed_block_err..'. '..shared_color_mess..addendum
		or malformed_block_err or shared_color_mess..addendum
		print('\n'..mess:gsub('%s+',' '):upper()) -- replace multiple spaces designed for message display in REAPER with a single space; the leading new line char makes part of the script path show up in the error message if error() function is used; line breaks are ignored by native error() and assert() functions which aren't used here
		end
	local output = not err and ('the formatted code has been saved into the file '):upper()..path..'FORMATTED CODE.txt'
	or code_form -- print the formatted code into console if the output file path is empty
	print('\n'..output)
	end



