--[[
ReaScript name: BuyOne_Project image files - copy to project directory.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M recommended for greater reliability
Provides: [main=main,midi_editor] .
About:  The script is meant to complement REAPER built-in
        functionality of copying media to the project 
        directory which ignores image files used in item
        notes and as track icons and only respects video take 
        source image files.
  
        The script copies image files used in the current
        project to the location in the project directory, which 
        is either project media path or a dedicated folder if 
        specified in the IMAGE_DIRECTORY setting.
  
        By default the script targets item notes image files. 
        If HANDLE_VIDEO_TAKE_IMAGE_SOURCES setting is enabled
        video take image source files are handled as well.
        If INCLUDE_TRACK_ICONS setting is enabled track icon files
        are handles too.  
  
        Image files located in the /Data folder in REAPER resource 
        directory are ignored by the script.
  
        If file path happens to exceed the limit of 256 characters 
        the file name will be truncated as much as possible to fit 
        within the limit. File name collisions are resolved by adding
        a numeric prefix to the file being copied/moved.
  
        See USER SETTINGS below.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Between the quotes insert the folder name, i.e. "Images"
-- to be used or created inside the project directory;
-- if the setting is empty, project media directory will be used,
-- if invalid a prompt will allow to choose further
-- course of actions, if not found it will be created
IMAGE_DIRECTORY = ""

-- To enable the following settings insert
-- any alphanumeric character between the quotes.

-- Enable to allow the script to handle video take source
-- images as well;
-- even though REAPER handles video take source images
-- natively when COPYING/MOVING media via the 'Save As...'
-- dialogue, allowing the script to handle them along with
-- other project image files may be a good idea because
-- in projects where image files happen to be used as both
-- video take source and as track icon or item notes image
-- this will ensure that no duplicate file instances are
-- created in the project directory which could be the case
-- if you managed video take images and other project images
-- separately, although REAPER seems to overwrite identical
-- files instead of creating duplicates, but it is certainly
-- advised if you wish do keep all project image files
-- inside a dedicated folder specified in the IMAGE_DIRECTORY
-- setting above, because REAPER has no knowledge of this
-- directory and only respects project media directory
-- when handling video take source image files
HANDLE_VIDEO_TAKE_IMAGE_SOURCES = ""

-- Enable for the script to also handle image files
-- used as track icons;
-- track icon images located in the /Data folder
-- in REAPER resource directory are ignored by the script
INCLUDE_TRACK_ICONS = "1"

-- After changing image file locations their
-- references within items and tracks (if
-- INCLUDE_TRACK_ICONS setting is enabled) are
-- updated, enable this setting so that the new
-- references are written into the project file
-- and become permanent;
-- alternatively you can opt for saving the
-- project manually or use the script as part
-- of a custom action:
--[[
BuyOne_Project image files - copy to project directory.lua
File: Save project
--]]
-- instead of enabling this setting, so that
-- you have freedom to choose when to auto-save
-- the project
SAVE_PROJECT_AFTERWARDS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper


function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Rep(n) -- number of repeats, integer
return (' '):rep(n)
end


function space(str)
return str:gsub('.','%0 ')
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



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist) -- used in  Remove_Confirmation_Dialogue()
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



function file_exists(path) -- used inside copy_delete_file(), resolve_file_name_collision(), reduce_file_name_length(), MANAGE()
local f, mess = io.open(path, 'r')
	if mess and mess:match('No such file or directory') then return
	else f:close() return true
	end
end


function dir_exists(path) -- used in MANAGE()
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string representing a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed so the path is properly formatted for io.open()
local _, mess = io.open(path)
return #path:gsub('[%c%.]', '') > 0 and mess and mess:match('Permission denied') and path..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
end


function invalid_chars(name, want_mess) -- used in the main routine
-- only suitable for file/folder names, not paths
-- https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names

local OS = r.GetAppVersion()
local lin, mac = OS:match('lin'), OS:match('OS')
local win = not lin and not mac
local t = win and {'<','>',':','"','/','\\','|','?','*'}
or lin and {'/','\0'} or mac and {'/',':'}

local invalid = {}

	for k, char in ipairs(t) do
		if name:match(Esc(char)) then invalid[#invalid+1] = char end
	end

local win_illegal = 'CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9'
	if win then
		for ill_name in win_illegal:gmatch('[^,]+') do
			if name:match('^%s*'..ill_name..'%s*$') or name:match('^%s*'..ill_name:lower()..'%s*$')
			then invalid[#invalid+1] = ill_name end -- illegal names padded with spaces aren't allowed either
		end
	end

	if #invalid > 0 then
		if want_mess then
		invalid = table.concat(invalid, ' ')
		local mess = 'The name of a dedicated image folder\n\n'..Rep(10)
		..'contains invalid characters:\n\n'..invalid
		..'\n\n'..Rep(15)..'Wish the script to use\n\n'..Rep(6)..'project media directory instead?'
		return r.MB(mess,'ERROR',1)
		else
		return true
		end
	end

end



function path_invalid_chars(path) -- used in MANAGE()
local sep = path:match('[\\/]')
local path = path:sub(-1) == sep and path or path..sep -- add to simplify capture below
local vol
	for name in path:gmatch('(.-)'..sep) do
		if not vol and name:match(':') then vol = 1
		elseif vol and invalid_chars(name)
		then return
		end
	end
--Msg('TEST')
return true
end



function file_path_limit(f_path) -- used inside copy_delete_file() and MANAGE()
-- the limit is 256 characters

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

return f_path:len() > 256

end



function resolve_file_name_collision(f_path) -- used inside copy_delete_file()
-- for preventing collision the function is supposed to be used after existence
-- of a homonymous file at the destination path
-- has already been ascertained with functions such as file_exists(),
-- but it can also be used for mere truncation of the file name
-- due to excessive path length;
-- f_path is the file new path it's supposed to have after
-- movement/copying;
-- appends a number to file name to resolve collision,
-- if the path after file name resolution exceeds 256 char
-- truncates file name from the end until collision is resolved
-- if not resolved after only 1 character has been left
-- of the original file name returns nil

	local function len(str)
	local l = #str:gsub('[\128-\191]','')
	return l
	end

local path, name, ext = f_path:match('(%S.+[\\/])(.+%.)(.+%S)$')

-- find name which doesn't collide with file names inside the destinaion folder
-- by appending numerical suffix inside parentheses to the target file name;
-- at this point the file path length may already be in excess,
-- but evaluating this before the loop below complicates the code
-- so if this indeed is the case will be determined in the course of the main loop;
-- file extension dot is used as an anchor for the numeric suffix
-- so that it's only modified at the end of the file name
-- in case there're matches elsewhere within the name

	for i=2,100 do -- starting with 2 to mark second or greater instance of the file
	local num = name:match('.+(%(%d+%)%.)')
	num = num and Esc(num)
	name = num and name:gsub(num, '('..i..').', 1) or name:sub(1,-2)..' ('..i..').' -- if file name already contains suffix of numeral inside paranthesis, only update the numeral
	f_path = path..name..ext
	local excess = len(f_path) > 256
		if not file_exists(f_path) and not excess then -- new file name doesn't occur in the destination folder AND path char limit hasn't been exceeded, good to use
		break
		elseif excess then
		local name_len = len(name)
		local extra_char = len(f_path) - 256
			if extra_char >= name_len then -- truncating name doesn't help
			return
			elseif extra_char == 1 then -- this allows removing 1 parenthesis and replacing the other one with underscore
			-- shorten the name by removing the parenthesis around the number
			local name, num = name:match('(.+)%((%d+)%)%.')
			f_path = path..name..'_'..num..ext
				if not file_exists(f_path) then break end
			else
			local name = name:match('(.+)%(%d+%)') -- exclude number in parenthesis completely, file with such name already exists at the destination path which is why this function is being executed in the first place, so it still should not collide and since inclusion of a number makes its path go over the character limit it needs truncation instead
			name_len = len(name) -- get length of name without number
				for i=1, name_len-1 do -- each cycle reduces name length by 1 character, -1 because otherwise the last cycle of the loop the name will reach with only the 1st character left, so no point to continue past that
				name = name:match('(.+)[\192-\255].[\128-\191]') or name:match('(.+)[\192-\255]*.[\128-\191]')
				or name:match('(.+)[\192-\255]*.[\128-\191]*') -- accounting for non-ASCII characters so that truncation occurs by character rather than bytes, accommodates all cases whether lead and continuation bytes present or not
				f_path = path..name..ext
					if len(f_path) <= 256 and not file_exists(f_path) then break end
				end

				if i < name_len then break -- break out of the main loop
				elseif i == name_len then return  -- in case all versions of the truncated file name collided with already existing files, a fairly unlikely scenario, exit to prevent returning the last concatenated f_path, or 'f_path = nil' could be used instead of return
				end

			end
		elseif i==100 then return -- by the end of the loop collision hasn't been resolved, exit to prevent returning the last concatenated f_path
		end
	end

return f_path

end



function reduce_file_name_length(f_path) -- used inside copy_delete_file()
-- to be used when file path exceeds the limit of 256 chars
-- relies on file_exists() function

	local function len(str)
	local l = #str:gsub('[\128-\191]','')
	return l
	end

local path, name, ext = f_path:match('(%S.+[\\/])(.+)(%..+%S)$')

	if len(path) >= 256 then return end -- the path length is in excess even without the file name

	if len(f_path) > 256 then
	local name_len = len(name)
		for i=1, name_len-1 do -- each cycle reduces name length by 1 character, -1 because otherwise the last cycle of the loop the name will reach with only the 1st character left, so no point to continue past that
		name = name:match('(.+)[\192-\255].[\128-\191]') or name:match('(.+)[\192-\255]*.[\128-\191]')
		or name:match('(.+)[\192-\255]*.[\128-\191]*') -- accounting for non-ASCII characters so that truncation occurs by character rather than bytes, accommodates all cases whether lead and continuation bytes present or not
		f_path = path..name..ext
			if len(f_path) <= 256 and not file_exists(f_path) then break end
		end

		if len(f_path) > 256 then return end -- in case all versions of the truncated file name collided with already existing files, a fairly unlikely scenario, exit to prevent returning the last concatenated f_path, or 'f_path = nil' could be used instead of return

	end

return f_path

end



function Invalid_Script_Name(scr_name,...) -- used in the main routine
-- check if necessary elements, case agnostic, are found in script name and return the one found
-- only execute once
local t = {...}

	for k, elm in ipairs(t) do
	local keyword = scr_name:lower():match(elm:lower())
		if keyword then return keyword end -- at least one match was found
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   Please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end



local function GetObjChunk(obj) -- used in process_obj_images()
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, env = table.unpack(t)
-- Try standard function -----
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then return 'err_mess'
	elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes (4.194303 Mb) = (4096 kb * 1024 bytes) - 1 byte // since build 4.20 http://reaper.fm/download-old.php?ver=4x
	end
-- If chunk_size >= max_size, use wdl fast string --
local fast_str = r.SNM_CreateFastString('')
	if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
	then obj_chunk = r.SNM_GetFastString(fast_str)
	end
r.SNM_DeleteFastString(fast_str)
	if obj_chunk then return true, obj_chunk end
end



local function SetObjChunk(obj, obj_chunk) -- used in process_obj_images()
	if not (obj and obj_chunk) then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, env = table.unpack(t)
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



function copy_delete_file(file_path, folder_path, delete_old) -- used in process_obj_images() and MANAGE()
-- folder_path is path of the new folder, must not end with a separator,
-- for cleanup operation it's image trash folder,
-- for copy/move operation it's a dedicated image folder or project media path,
-- if nil/false, file is immediately deleted from its current location

	if folder_path then
	local folder_path = folder_path:match('.+[\\/]$') and folder_path:sub(1,-2) or folder_path -- last separator is removed so the path is properly formatted for io.open()
	local sep = folder_path:match('[\\/]')
	local file_path = file_path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
	local file_name = file_path:match('.+[\\/](.+)')
	local new_path = folder_path..sep..file_name
	local exists = file_exists(new_path)
		if not exists and file_path_limit(new_path) then
		new_path = reduce_file_name_length(new_path)
			if not new_path then return end -- reduction didn't help to overcome the length excess
		elseif exists then
		new_path = resolve_file_name_collision(new_path) -- also reduces file name length if path length is in excess
		-- in case of collision REAPER overwrites namesake files unless at the very least their sizes differ
		-- in which case it resolves the collision by appending -001 suffix
			if not new_path then return end
		end

	local f = io.open(file_path,'rb')
		if not f then return end -- file not found
	local cont = f:read('*a')
	f:close()
	local f = io.open(new_path, 'wb') -- open at new location
	f:write(cont)
	f:close()
		if delete_old then
		-- validate
		local f = io.open(new_path, 'rb')
			if f:read('*a') == cont then -- if identical to original
			os.remove(file_path) -- remove from old location
			end
		f:close()
		end
	return new_path
	else -- delete immediately, relevant for cleanup operation
	os.remove(file_path) -- remove
	end

end



function ScanPath(path) -- used in MANAGE()
-- path is project media path

local path = path:match('^%s*(.-)%s*$') -- trim spaces
local path = #path > 0 and path:match('.+[\\/]$') and path:match('(.+)[\\/]$') or path -- remove last separator if any
local sep = path:match('[\\/]') and path:match('[\\/]') or '/' -- extract the separator, if path is disk root where the separator isn't listed, use forward slash, which works on Windows as well
local t = {}
local subdir_idx, file_idx, subdir = 0, 0
local ext = {PNG='',PCX='',JPG='',JPEG='',JFIF='',ICO='',BMP='',GIF=''}

	repeat
	local fn = r.EnumerateFiles(path, file_idx)
		if fn and (ext[fn:match('.+%.(.+)$')] or ext[fn:match('.+%.(.+)$'):upper()]) then
	--	t[#t+1] = path..sep..fn
		t[path..sep..fn] = ''
		end
	file_idx = file_idx + 1
	until not fn

return t

end


function Remove_Confirmation_Dialogue(t, status_t) -- used in MANAGE()

local status_t, f_list = status_t or {}

	for k, v in ipairs(t) do
	f_list = (f_list and f_list..'|' or '')..(not status_t[k] and '' or '!')
	..v:match('.+[\\/](.+)') -- only leaving file name
	end

local menu = space('REMOVE ALL')..'||'..space('REMOVE CHECKMARKED')..'|(click file name to toggle checkmark)||'
..'WARNING: These files may be in use in other projects||'..f_list
return menu:match('|!'), Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

end




function is_image_file(file_path) -- used in MANAGE()
local t = {PNG='',PCX='',JPG='',JPEG='',JFIF='',ICO='',BMP='',GIF=''} -- GIF format is only relevant for video takes
local ext = file_path:match('.+%.(.+)$')
return ext and t[ext:upper()]
end



function replace_take_src(take, new_file_path) -- used in process_obj_images()
local old_src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed audio takes and audio sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
old_src = r.GetMediaSourceParent(old_src) or old_src
local new_src = r.PCM_Source_CreateFromFile(new_file_path)
r.SetMediaItemTake_Source(take, new_src)
r.PCM_Source_Destroy(old_src)
r.UpdateItemInProject(r.GetMediaItemTake_Item(take))
end



function process_obj_images(t, media_path, move, vid_src_t, SetObjChunk, ...) -- used in MANAGE()
-- first copy, then update in objects, then remove from the original path if 'move' is true;
-- vid_src_t is only used in 'move' operation for evaluation to prevent removal
-- of files if they're also used as video take source images;
-- SetObjChunk function is only used in item notes image processing;
-- vararg is two tables: one for collecting (items stage) or which contains (video source and track stages)
-- a list of processed file paths and which at item processing stages
-- is returned by this function, and another containing paths of item image files
-- whose copy/move failed to prevent listing them twice when they pertain
-- to both item notes and video takes

local processed, cpy_move_failures = table.unpack({...}) -- inside MANAGE() 'processed' table will stem from item notes image processsing stage and be passed at video take source and track icon processing stages; cpy_move_failures table will stem from item notes image processsing stage and only be passed at video take sources processing stage containing the list of image files whose copy/move failed for further evaluation and collection

local total_cnt, failed_cpy_move_cnt, failed_update_cnt, itm_img = 0, 0, 0
	for f_path, obj_t in pairs(t) do
	local is_item = not r.ValidatePtr(obj_t[1],'MediaTrack*')
	total_cnt = (is_item and not processed[f_path] or not is_item) and total_cnt+1 or total_cnt -- for items only count files not processed earlier because item images are processed in two stages: item notes and video take source and copy/move failure stats are combined for both stages, within one stage duplicates doesn't occur being prevented at the stage of image paths collection inside MANAGE()
		if f_path:match('(.+)[\\/]') ~= media_path then -- ignoring files which are already located at the media path, redundant because this is evaluated inside MANAGE() at the stage of file paths collection

		local new_path = processed[f_path] or copy_delete_file(f_path, media_path) -- at this stage delete_old arg is nil, returns new path in case file name was changed to resolve name collision // only run the function if this file wasn't copied/moved earlier, otherwise re-use the copied/moved instance and just update the reference in the object
			if new_path	then
			local failed_update
				for k, obj in ipairs(obj_t) do -- update objects
					if not is_item then -- track icon image
					r.GetSetMediaTrackInfo_String(obj, 'P_ICON', new_path, true) -- setNewValue true
					else -- item notes or video take source image
					itm_img = 1
						if r.ValidatePtr(obj,'MediaItem*') then -- item notes image
						local ret, chunk = GetObjChunk(obj)
							if ret then
							chunk = chunk:gsub('RESOURCEFN "(.-)"', 'RESOURCEFN "'..new_path..'"')
							SetObjChunk(obj, chunk)
							else
							failed_update = 1
							end
						else -- video take source image, the condition will only be true if HANDLE_VIDEO_TAKE_IMAGE_SOURCES setting is On
						replace_take_src(obj, new_path)
						end
					end
				end
				if move and not failed_update
				and (HANDLE_VIDEO_TAKE_IMAGE_SOURCES or not vid_src_t[f_path]) then -- remove from the original location, only if not also used as video take source when HANDLE_VIDEO_TAKE_IMAGE_SOURCES is disabled or when it's enabled
				os.remove(f_path) -- remove
				end

				if failed_update then
				failed_update_cnt = failed_update_cnt+1
				t[f_path] = 1 -- store indicator for file status
				end

			else -- copy/move failed
				if is_item then itm_img = 1 end
			failed_cpy_move_cnt = failed_cpy_move_cnt+1
			t[f_path] = 2 -- store indicator for file status
			end
		processed[f_path] = new_path -- store properties of a processed file to evaluate and re-use in further cycles preventing creation of multiple copies when the file is used in several objects OR preventing moving attempt because after its deletion from original location during very first object processing there'll be nothing else to move and copy_delete_file() will fail
		end
	end

local action = move and 'MOVED' or 'COPIED'
local dest_dir = IMAGE_DIRECTORY and 'IMAGE' or 'PROJECT'
local title = 'THE FOLLOWING '..(itm_img and 'ITEM IMAGE FILES ' or 'TRACK ICON FILES ')..'COULDN\'T BE ' -- either items or tracks because with this function process_obj_images() they're processed separately inside MANAGE()
local failed_cpy_move = failed_cpy_move_cnt > 0 and title..action..' TO THE '..dest_dir..' DIRECTORY ('
..math.floor(failed_cpy_move_cnt)..' out of '..math.floor(total_cnt)..'):\n'
local failed_update = failed_update_cnt > 0 and title..'UPDATED ('
..math.floor(failed_update_cnt)..' out of '..math.floor(total_cnt)..'):\n'

failed_update = failed_update and {failed_update}
failed_cpy_move = cpy_move_failures or failed_cpy_move and {failed_cpy_move} -- reuse table from earlier stage if available

	if cpy_move_failures and #cpy_move_failures > 1 and failed_cpy_move_cnt > 0 then -- update total count value in the title stats, the failed count will be updated inside MANAGE() because final table length after two stages of processing is required for this // the update here is only relevant at video take source image files processing stage inside MANAGE(), cpy_move_failures table will only be valid at this stage, that's when the stats need adjustment // '> 1' because the table is supposed to contain more than the title stored in the 1st indexed field
	local title = failed_cpy_move[1]
	local prev_total = title:match('out of (%d+)')
	failed_cpy_move[1] = title:gsub('out of %d+', 'out of '..math.floor((prev_total+total_cnt)))
	end

	for f_path, val in pairs(t) do
		if val == 1 then -- only relevant for item notes images because of chunk involvement during the 1st run of this function inside MANAGE()
		table.insert(failed_update, f_path)
		elseif val == 2 and (itm_img and not failed_cpy_move[f_path] or not itm_img) then -- only store item image file paths if haven't been stored yet to prevent duplicate listings of paths pertaining to both item notes and video takes
		failed_cpy_move[f_path] = '' -- store for evaluation of item image paths on the next function run inside MANAGE()
		table.insert(failed_cpy_move, f_path)
		end
	end


return failed_cpy_move, processed, failed_update -- failed_update is returned last because it's only relevant for the 1st run of this function inside MANAGE()

end



function MANAGE(keyword)

-- natively REAPER only copies/moves files to
-- and does cleanup in project media directory
-- the script adheres to this rule

local move, copy, cleanup = keyword == 'move to', keyword == 'copy to', keyword:match('remove')
local retval, proj_path = r.EnumProjects(-1) -- -1 current project
local sep = proj_path:match('[\\/]')
-- for saved project returns setting at 'Project settings -> Path to save media files'
-- in theory, if project is dirty, the setting may be outdated and will be changed
-- by the time the project is saved, but there's no telling if this will be the case
-- so opting for the path available to the API

local err = #proj_path == 0 and 'the project is not saved'
or not file_exists(proj_path) and 'the project file\n\n has been deleted'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return end

	-- for cleanup, the image directory existence is evaluated here
	-- because that's where image file must be initially collected for further evaluation;
	--
	if cleanup and IMAGE_DIRECTORY and not dir_exists(proj_path:match('.+[\\/]')..IMAGE_DIRECTORY) then
		if r.MB('The specified image directory wasn\'t found.\n\n'
		..'\tWish the script to process\n\n'..Rep(6)..'image files at the project media path?',
		'PROMPT', 1) == 2 then -- user canceled
		return
		else
		IMAGE_DIRECTORY = nil -- reset
		end
	end

::RESTART::
local media_path = IMAGE_DIRECTORY and proj_path:match('.+[\\/]')..IMAGE_DIRECTORY or r.GetProjectPath()
local root = proj_path:match('(.+)[\\/]') == media_path and media_path:match('^%u:$')
and 'Project media path is disk root.\n\n'
local rsrc_path = r.GetResourcePath()
local handle_vid = HANDLE_VIDEO_TAKE_IMAGE_SOURCES

local in_proj_t = {items={},tracks={},vid_src={}}
local images_exist

	for i=0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
	local ret, chunk = r.GetItemStateChunk(item, '', false) -- isUndo false
	local img_path = chunk:match('RESOURCEFN "(.-)"') -- image path is always enclosed within quotation marks // RESOURCEFN only lists file name if it's located in the /Data/track_icons or /Data/toolbar_icons folders in REAPER resource directory, relative path if it's located in the project directory subfolder and full path if the file is located elsewhere, including directly in the /Data folder or directly in the project directory
		if img_path then
		images_exist = 1
		-- recreate full image file path depending on what's listed as RESOURCEFN
		img_path = img_path:match(':') and img_path -- full path, volume letter column (:) is present
		or img_path:match(sep) and proj_path:match('.+[\\/]')..img_path -- complete the relative path of a file in the project folder subfolder
		or rsrc_path..sep..'Data'..sep..img_path -- OR r.image_resolve_fn(img_path, '') // complete the name of a file inside REAPER /Data/track_icons or /Data/toolbar_icons folders, ommitting the actual subfolder because files inside the /Data folder are ignored by the script altogether
		local at_media_path = img_path == img_path:match(Esc(media_path)..sep..'[^'..sep..']+%.%a+') -- making sure that after sep no other separator occurs otherwise capture ('.+%.%a+') will produce false positive when project media path is disk root and the file location is elsewhere on the same disk

		-- for copying/moving collect files which are NOT in the project media directory,
		-- REAPER moves/copies media files to project media path even if they're located
		-- in the root of the project folder, unless it already serves as media path,
		-- for cleanup collect those which ARE;
		--	if not cleanup and not at_media_path --and img_path:match(sep) -- not located either at the project media path or in the root of the project folder, otherwise would lack separators
			if not img_path:match(Esc(rsrc_path)..sep..'Data') -- not in the /Data folder
			and (not cleanup and not at_media_path -- not located at the media path
			or cleanup and at_media_path) --or not img_path:match(sep))
			then
				if cleanup then
				in_proj_t.items[img_path] = item -- to simplify evaluation for cleanup, without traversing entire table, and to prevent duplicate entries of images inside the table
				else  -- store all items using image from the same path to update in all after moving/copying
				in_proj_t.items[img_path] = in_proj_t.items[img_path] or {}
				table.insert(in_proj_t.items[img_path], item)
				end
			end
		end

	-- look for video takes with image sources
	-- for cleanup to prevent deletion of the latter;
	-- reaper copies/moves video take sources natively
	-- so if the setting HANDLE_VIDEO_TAKE_IMAGE_SOURCES
	-- isn't enabled they're ignored in copy/move operation
	-- of the script, but in move operation store them
	-- for the sake of evaluation to prevent deletion
	-- of the files from their original location if they're
	-- used as a video take source as well as item image
		for i=0, r.CountTakes(item)-1 do
		local take = r.GetTake(item,i)
		local src = r.GetMediaItemTake_Source(take)
		local file_path = r.GetMediaSourceFileName(src, '')
			if is_image_file(file_path) then
			images_exist = handle_vid or images_exist -- this must only be true when handle_vid is enabled because images presence is only evaluated for supported/enabled object types, otherwise it'll cause false positive at message generation
			local at_media_path = file_path == file_path:match(Esc(media_path)..sep..'[^'..sep..']+%.%a+') -- located at the media path // making sure that after sep no other separator occurs otherwise capture ('.+%.%a+') will produce false positive when project media path is disk root and the file location is elsewhere on the same disk
				if cleanup and at_media_path then
				in_proj_t.items[file_path] = item -- to simplify evaluation for cleanup, without traversing entire table, and to prevent duplicate entries of images inside the table
				elseif not at_media_path then
					if not handle_vid and move then -- for evaluation during 'move' operation
					in_proj_t.vid_src[file_path] = '' -- dummy value
					elseif handle_vid then -- for copying/moving if the setting is enabled
					in_proj_t.vid_src[file_path] = in_proj_t.vid_src[file_path] or {}
					table.insert(in_proj_t.vid_src[file_path], take)
					end
				end
			end
		end

	end


	if INCLUDE_TRACK_ICONS or cleanup then -- collect, before cleanup as well to prevent deletion of track icons which may be stored at the project media path
		for i=0, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i)
		local retval, f_path = r.GetSetMediaTrackInfo_String(tr, 'P_ICON', '', false) -- setNewValue false // this returns relative path for icon files inside project folder subfolders, including media folder, and only file name for files located in the project folder root, HOWEVER ONLY AFTER THE PROJECT IS SAVED AND RELOADED, when icon has just been added the function returns its full path even at those locations and even after project save but before reloading; in the chunk TRACKIMGFN attribute only file name is also listed when the file is located in /Data/track_icons or /Data/toolbar_icons folder which is immaterial here
			if #f_path > 0 then -- icon is set, retval is no good because it's always true
			images_exist = 1
			-- re-create full path depending on what's returned by GetSetMediaTrackInfo_String()
			f_path = f_path:match(':') and f_path -- full path, volume letter column (:) is present
			or f_path:match(sep) and proj_path:match('.+[\\/]')..f_path -- complete the relative path of a file in the project folder subfolder
			or proj_path:match('.+[\\/]')..f_path -- OR r.image_resolve_fn(f_path, '') // complete the name of a file in the project folder root
			local at_media_path = f_path == f_path:match(Esc(media_path)..sep..'[^'..sep..']+%.%a+') -- making sure that after sep no other separator occurs otherwise capture ('.+%.%a+') will produce false positive when project media path is disk root and the file location is elsewhere on the same disk
				if not f_path:match(Esc(rsrc_path)..sep..'Data') -- not in the /Data folder
				and (not cleanup and not at_media_path
				or cleanup and at_media_path)
				then
					if cleanup then
					in_proj_t.tracks[f_path] = tr -- to simplify evaluation for cleanup, without traversing entire table, and to prevent duplicate entries of track icons inside the table, track pointer is useless here, a dummy value would do
					else -- copy/move track icons, INCLUDE_TRACK_ICONS is enabled
					-- store all tracks using icon from the same path to update in all after moving/copying
					in_proj_t.tracks[f_path] = in_proj_t.tracks[f_path] or {}
					table.insert(in_proj_t.tracks[f_path], tr)
					end
				end
			end
		end
	end


	if cleanup then

	local file_content = ScanPath(media_path)
	local to_remove = {} -- using separate table to be able to concatenate file paths for the menu

		if not next(file_content) then
		local folder = IMAGE_DIRECTORY and 'in the image directory' or 'in the project folder'
		Error_Tooltip('\n\n no supported image files \n\n'..Rep(3)..folder..'. \n\n', 1, 1) -- caps, spaced true
		pause(2.5) -- make the message stick for 2.5 sec
		return
		elseif root and r.MB(Rep(8)..root..'Wish to remove image files from there?', 'PROMPT', 1) == 2 then -- user canceled
		return
		end

	 -- collect files to remove
		for file in pairs(file_content) do
			if not in_proj_t.items[file] and not in_proj_t.tracks[file] then -- not found inside the project
			to_remove[#to_remove+1] = file -- store inside indexed table to be able to concatenate file paths for the menu
			end
		end

		if #to_remove == 0 then -- all found image files are used in the project
		Error_Tooltip('\n\n\tall found image files \n\n are used within the project. \n\n'
		..'\t  Nothing to remove. \n\n', 1, 1) -- caps, spaced true
		pause(2.5) -- make the message stick for 2.5 sec
		return end

	local status_t = {} -- will hold checkmark status of each file menu item
	-- display cleanup menu and handle user choices
	::RELOAD::
	local checkemarked, output = Remove_Confirmation_Dialogue(to_remove, status_t)
	local remove_checkmarked
		if output == 0 then return
		elseif output == 3 or output == 4 then goto RELOAD -- comments
		elseif output > 4 then -- file list click, change checkmark status
		output = output-4 -- offset first 3 menu items
		status_t[output] = not status_t[output] -- flip status to toggle checkmark
		goto RELOAD
		else -- remove, output 1 or 2
		remove_checkmarked = output == 2
			if remove_checkmarked and not checkemarked then
			Error_Tooltip('\n\n no checkmarked files \n\n', 1, 1, x, -100) -- caps, spaced true, y -100
			pause(1) -- make the error message stick for half a second, because when the menu loads it may get obscured by it
			goto RELOAD
			elseif TRASH_DIRECTORY then
			local exists, valid = dir_exists(TRASH_DIRECTORY), path_invalid_chars(TRASH_DIRECTORY)
			local long = file_path_limit(TRASH_DIRECTORY)
			local mess = not exists and {'Provided trash directory path doesn\'t exist.\n\n'
			..'What would you like to do?\n\nYES — create one\n\nNO — just delete the files', 3} -- yes/no/cancel
			or TRASH_DIRECTORY == media_path and {'Trash directory path is identical\n\n'..Rep(9)..'to project media path.\n\n'
			..'Wish to have the files deleted?', 4} -- yes/no
				if mess then
				local resp = r.MB(mess[1], 'PROMPT', mess[2])
					if mess[2] == 3 and resp == 2 or mess[2] == 4 and resp == 7 then return -- user canceled
					elseif mess[2] == 3 and resp == 7 or mess[2] == 4 and resp == 6 then TRASH_DIRECTORY = nil -- user chose deletion
					elseif mess[2] == 3 and resp == 6 then -- user chose to create trash dir
					local mess = Rep(8)..'Provided trash directory path\n\n'
					mess = not valid and mess..Rep(10)..'contains invalid characters.'
					or long and mess..'   exceeds the limit of 256 characters.'
						if mess then
							if r.MB(mess..'\n\n'..Rep(7)..'Wish to have the files deleted?','ERROR',1) == 2 then
							return -- user canceled
							else
							TRASH_DIRECTORY = nil
							end
						elseif r.RecursiveCreateDirectory(TRASH_DIRECTORY, 0) == 0 then
						local s = Rep(6)
							if r.MB(s..'Trash directory creation failed.\n\n'..s..'Wish to have the files deleted?', 'ERROR', 1) == 2
							then return -- used canceled after trash directory creation failure
							else
							TRASH_DIRECTORY = nil
							end
						end
					end
				end

			end
		end

		-- remove files
		local total_cnt = #to_remove
		for i=total_cnt,1,-1 do -- in reverse because references of sucessfully removed files will be removed from the table
		local f_path = to_remove[i]
			if remove_checkmarked and status_t[i] or not remove_checkmarked then -- when remove_checkmarked is false, all collected into to_remove table are removed
				if copy_delete_file(f_path, TRASH_DIRECTORY) then -- delete_old arg isn't used, if TRASH_DIRECTORY is nil immediately deletes from file's original location
				table.remove(to_remove,i)
				end
			end
		end
			if #to_remove == total_cnt then
			r.MB('No file could be removed','INFO',0)
			elseif #to_remove > 0 then -- list files which weren't removed due to path length excess for example or OS obstacles
			Msg(r.ClearConsole(),'THE FOLLOWING FILES COULDN\'T BE REMOVED\n\n'..table.concat(to_remove,'\n'))
			end

	else -- copy/move

	local action = move and 'move' or 'copy'
		if not next(in_proj_t.items) and (not INCLUDE_TRACK_ICONS or not next(in_proj_t.tracks))
		and (not handle_vid or not next(in_proj_t.vid_src)) then
		local mess = not images_exist and 'the project doesn\'t contain \n\n\t  images the script \n\n   is configured to process'
		or Rep(4)..'all project image files \n\n'..Rep(4)..'the script is configured \n\n'..Rep(5)..'to process are already \n\n '
		..'at their expected locations. \n\n'..Rep(10)..'Nothing to '..action
		Error_Tooltip('\n\n '..mess..'. \n\n', 1, 1) -- caps, spaced true
		pause(3) -- make the message stick for 2.5 sec
		return
		elseif root and r.MB(root..'Wish to '..action..' image files there?', 'PROMPT', 1) == 2 -- user canceled
		then return
		end

		-- create dedicated image directory if absent
		if media_path and not dir_exists(media_path) then -- media_path may not exist if the var was assigned IMAGE_DIRECTORY data at the function start, project media path cannot be absent
		media_path = media_path:match('.+[\\/]$') and media_path:sub(1,-2) or media_path -- last separator is removed so the path is properly used or created
			if IMAGE_DIRECTORY and r.RecursiveCreateDirectory(media_path, 0) == 0 -- integer arg is 0, not used by the function
			then
				if r.MB(Rep(9)..'Image directory wasn\'t found\n\n'..Rep(13)..'and could not be created.\n\n'
				..'Wish to use project media path instead?', 'PROMPT', 1) == 2 then
				return -- user cancelled after images directory creation failure
				else
				IMAGE_DIRECTORY = nil -- reset
				goto RESTART -- restart the routine so that if files are already located at the media path the message above 'files are already at their extected locations' can be generated
				end
			end
		end

		-- item notes image stage
		local failed_cpy_move, processed, failed_update = process_obj_images(in_proj_t.items, media_path, move, in_proj_t.vid_src, SetObjChunk, {}) -- the 4th argument {} will be returned as 'processed' var
		local failed = failed_update and #failed_update > 1 and table.concat(failed_update, '\n')..'\n\n' or '' -- '> 1' because it's supposed to contain more than the title stored in the 1st indexed field

			-- video take source image stage
			if handle_vid then
			failed_cpy_move, processed = process_obj_images(in_proj_t.vid_src, media_path, move, nil, nil, processed, failed_cpy_move) -- in_proj_t.vid_src and SetObjChunk are nil because neither is needed here, SetObjChunk it's not used in updating video take source, second in_proj_t.vid_src isn't needed for evaluation of video take sources during 'move' operation when they're handled by the script // AFTER THIS STAGE failed_cpy_move table, IF VALID, WILL ONLY CONTAIN A SINGLE TITLE FIELD (the very 1st) EVEN IF THERE WERE FAILED VIDEO TAKE SOURCE IMAGE FILES, this is taken care of inside process_obj_images()

				-- update failed count in the title stats, total count is updated inside process_obj_images()
				if failed_cpy_move then -- '> 1' because it's supposed to contain more than the title stored in the 1st indexed field
				local title = failed_cpy_move[1]
				local count = title:match('(%d+) out of')
				local failed_cnt = #failed_cpy_move-1 -- -1 to exclude the title field
					if failed_cnt ~= count+0 then -- update the stats
					failed_cpy_move[1] = title:gsub('%d+ out of', math.floor(failed_cnt)..' out of')
					end
				end

			failed = failed..(failed_cpy_move and table.concat(failed_cpy_move,'\n')..'\n\n' or '') -- combine item related stats collected so far
			end

		-- track icon stage
		failed_cpy_move = process_obj_images(in_proj_t.tracks, media_path, move, in_proj_t.vid_src, nil, processed) -- in_proj_t.tracks will be empty if INCLUDE_TRACK_ICONS isn't enabled, SetObjChunk is nil because it's not used in updating track icon paths

		failed = failed..(failed_cpy_move and table.concat(failed_cpy_move,'\n') or '') -- combine all collected stats

		if #failed > 0 then
		r.ClearConsole()
		Msg(failed)
		end

	end

end



Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_name:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

------------------------------------------------------
 -- scr_name = '' -------------- NAME TESTING
------------------------------------------------------

local keyword = Invalid_Script_Name(scr_name,'copy to','move to','remove unused from')

	if not keyword then return r.defer(no_undo) end

HANDLE_VIDEO_TAKE_IMAGE_SOURCES = HANDLE_VIDEO_TAKE_IMAGE_SOURCES:match('%S')
INCLUDE_TRACK_ICONS = INCLUDE_TRACK_ICONS:match('%S')
IMAGE_DIRECTORY = IMAGE_DIRECTORY:match('%S') and (invalid_chars(IMAGE_DIRECTORY, 1) -- want_mess true
or IMAGE_DIRECTORY)

local cleanup = keyword:match('remove')
	if not cleanup and not r.GetMediaItem(0,0)
	and (not INCLUDE_TRACK_ICONS or not r.GetTrack(0,0))
	then
	local tracks = INCLUDE_TRACK_ICONS and 'or tracks \n\n'..Rep(5) or ''
	Error_Tooltip('\n\n no items '..tracks..'in the project \n\n', 1, 1) -- caps, spaced true
	return end

	if IMAGE_DIRECTORY == 2 then return r.defer(no_undo) -- user canceled the dialogue called inside invalid_chars()
	elseif IMAGE_DIRECTORY == 1 then -- user chose to switch to project media path
	IMAGE_DIRECTORY = nil
	end

-- removing trailing separator if any
TRASH_DIRECTORY = cleanup and TRASH_DIRECTORY:match('%S')
and (TRASH_DIRECTORY:sub(-1) == TRASH_DIRECTORY:match('[\\/]') and TRASH_DIRECTORY:sub(1,-2) or TRASH_DIRECTORY)

MANAGE(keyword)

	if SAVE_PROJECT_AFTERWARDS:match('%S') then
	r.Main_SaveProject(0, false) -- forceSaveAsIn false
	end

do return r.defer(no_undo) end


