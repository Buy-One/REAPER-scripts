-- ReaScript name: BuyOne_Extract download links (not for REAPER).lua

-- Not meant to be applied to REAPER but must be run from inside it to take advantage of its Lua engine
-- and one function if FILE_DIALOGUE setting is enabled;

-- copy save HTML code into a temp file or download the page containing links,
-- use Notepad++ to list all lines with links with 'Find -> Find all in current document',
-- save this list into a .txt file which will be the input file
-- figure out how links are formatted, adjust the capture in the script if needed, run within REAPER
-- the output file is placed in same directory as the input file and is named output.txt
-- then use uGet (or another download manager) batch download feature to download the list

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable by inserting any alphanumeric character between the quotes
-- to use 'Open file' dialogue to browse to the input file
-- instead of inserting the input file name below
FILE_DIALOGUE = "1"

-- Between double square brackets insert default path for the input file
-- MUST END WITH A SEPARATOR and not contain leading/trailing spaces;
-- if FILE_DIALOGUE setting is enabled will be used as an 'Open file'
-- dialogue default path, and if empty REAPER last stored path will be
-- used instead;
-- if FILE_DIALOGUE setting is not enabled will be used as the path for both
-- input and output files
INPUT_FILE_PATH = [[]]

-- Specify the name of your input file,
-- only relevant if FILE_DIALOGUE setting isn't enabled
INPUT_FILE_NAME = [[New Text Document.txt]]

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

FILE_DIALOGUE = #FILE_DIALOGUE:gsub(' ','') > 0
INPUT_FILE_PATH = #INPUT_FILE_PATH:gsub(' ','') > 0 and INPUT_FILE_PATH or ''

	if FILE_DIALOGUE then
	retval, filename = reaper.GetUserFileNameForRead(INPUT_FILE_PATH, 'Open file', 'txt')
		if not retval then return end
	else
	local err = #INPUT_FILE_PATH:gsub(' ','') == 0 and 'No input file path'
	or not INPUT_FILE_NAME:match('.+%.txt') and 'The input file isn\'t a txt file'
		if err then reaper.MB(err,'ERROR', 0) return end
	end

local path = FILE_DIALOGUE and filename or INPUT_FILE_PATH..INPUT_FILE_NAME

	if not FILE_DIALOGUE then -- validate settings
		do -- to isolate local path from the path above used in the next condition
		local path = INPUT_FILE_PATH:match('.+[\\/]$') and INPUT_FILE_PATH:sub(1,-2) or INPUT_FILE_PATH
		local f, mess = io.open(path)
			if mess:match('No such file or directory') then
			reaper.MB('Invalid  INPUT_FILE_PATH', 'ERROR', 0) return end
		end
	local f, mess = io.open(path, 'r')
		if mess and mess:match('No such file or directory') then
		reaper.MB('Invalid  INPUT_FILE_NAME', 'ERROR', 0) return
		else f:close()
		end
	end


local t = {}

	for line in io.lines(path) do
	local link = line:match('(https.-)"') -- link capture
	local exists = 1
		for _, v in ipairs(t) do
			if v == link then exists = false break end -- weed out duplicate links
		end
		if exists then t[#t+1] = link end
	end

	if #t == 0 then reaper.MB('No links were extracted.', 'INFO', 0) return end

local path = FILE_DIALOGUE and filename:match('.+[\\/]') or INPUT_FILE_PATH
local f = io.open(path..'output.txt', 'w')
f:write(table.concat(t, '\n'))
f:close()



