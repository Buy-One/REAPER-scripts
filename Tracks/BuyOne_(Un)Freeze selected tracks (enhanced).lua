--[[
ReaScript name: BuyOne_(Un)Freeze selected tracks (enhanced).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M recommended, not mandatory
Provides: [main=main,midi_editor] .
About:	The script displays a menu with freeze settings
			and options and aims at exhausting all freeze
			related operations.

			The purpose of the settings is to change frozen
			track profile to make it less intrusive in the
			project and/or its frozen state more conspicuous
			as well as to reduce CPU consumption by children
			tracks of frozen folders.  
			The settings are only applied to tracks that 
			changed their state from unfrozen to frozen. 
			If a track frozen without using this script is 
			frozen again with it, its properties won't change 
			to reflect the settings.  
			Similarly, properties of a track frozen multiple
			times with the script will only be restored when
			it's unfrozen completely, i.e. all freeze 
			iterations are undone.

			Grayed out menu items indicate that conditions
			required for operations triggred by them are not
			met, i.e. no selected tracks, multiple selected
			tracks, the only selected track is not frozen.

			The menu items which affect the settings are always 
			accessible so that they could be changed at any time.

			When 'Extract frozen FX chain to a new track'
			action is executed from the script menu, the new
			track is created immediately above the selected
			frozen track.

			When track is unfrozen the freeze files are deleted
			from the disk.

			The underscored characters in the menu items can be 
			used to trigger the actions associated with them
			from keyboard when the relevant menu is active.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- THE SETTINGS ARE OPTIONAL, IF NONE IS ENABLED,
-- THE SCRIPT WILL EXECUTE REAPER STOCK (UN)FREEZE ACTIONS,
-- WHICH HOWEVER DEFEATS THE PURPOSE OF THE SCRIPT SAVE
-- FOR THE ABILITY TO DEFINE THE RANGE OF FROZEN FX
-- AND EXTRACT FROZEN FX CHAIN;
-- ALL THE SETTINGS ARE MANAGEABLE VIA A MENU DISPLAYED
-- BY THE SCRIPT SO DEFINING THEM MANUALLY HERE ISN'T NECESSARY

-- The settings whose names contain TRACK or TCP
-- part apply to the frozen track

-- Specify the file path between the double square
-- brackets in the following two settings;
-- the path may be either absolute, relative
-- or file name only;
-- relative path must be in the project directory
-- OR REAPER resource directory, the script will
-- search in both in this order;
-- if only file name is supplied the files will be
-- searched for in the project directory root,
-- in /Data/track_icons and and /Data/toolbar_icons folders
-- in REAPER resource directory in this order

TRACK_ICON_PATH = [[ ]]

FROZEN_ITEM_IMAGE_PATH = [[ ]]

----------------

-- Between the quotes insert hexadecimal color code,
-- 6 or 3 (if there're only 3 unique ones) characters long,
-- the preceding hash sign is optional
TRACK_COLOR = ""

-- Track label prefix will be separated from
-- the track label (if any) by a single space
TRACK_LABEL_PREFIX = ""

-- Between the quotes insert name of the TCP layout;
-- if the layout name isn't found in the current theme
-- it won't be applied;
-- be aware that the name may become invalid if you
-- switch to a different theme
TCP_LAYOUT_NAME = ""

------------------------------------------

-- To enable the following settings insert
-- any alphanumeric character between the quotes

LOCK_TRACK_CONTROLS = ""

-- When the height is locked it can't be changed
-- by vertical zoom, but by dragging it can
MINIMIZE_TCP_AND_LOCK_HEIGHT = ""

-- Only if track contains a single item,
-- if such item is multi-take - name of the active take
-- will be used;
-- doesn't apply to frozen folder parent tracks
-- which don't contain items
KEEP_ITEM_NAME_AFTER_FREEZING = ""

-- If enabled, the media source file of the
-- frozen item will be deleted from the disk
-- once the track is unfrozen, provided it's
-- not used by any other items in the project;
-- BE AWARE THAT IF THE FROZEN FILE IS DELETED
-- UNDOING THE UNFREEZE ACTION WILL RESULT
-- IN A MISSING MEDIA SOURCE
DELETE_FROZEN_FILE_AFTER_UNFREEZNG = ""


-- THE FOLLOWING 3 SETTINGS APPLY WHEN THE FROZEN TRACK IS FOLDER PARENT

-- Only applies to descendant tracks
-- that don't send via post-FX sends audio,
-- whether their own or received from other tracks,
-- to tracks outside of the folder they're
-- the descendants in or to tracks inside their folder
-- which themselves send audio to tracks outside of it
BYPASS_DESCENDANT_TRACK_FX = ""

-- Only applies to descendant tracks
-- that don't send audio or MIDI, whether
-- their own or received from other tracks,
-- to tracks outside of the folder they're
-- the descendants in or to tracks inside
-- their folder which themselves send audio
-- or MIDI to tracks outside of it;
-- may be useful when the option
-- Preferences -> Audio -> Mute/Solo
-- -> Do not process muted tracks
-- is enabled
MUTE_DESCENDANT_TRACKS = ""


COLLAPSE_DESCENDANT_TRACKS = ""

-----------------------------------

-- FREEZE MODES

UP_TO_SELECTED_FX = ""

UP_TO_LAST_UNBYPASSED_AND_ONLINE_FX = ""


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
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
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
-- do return end
end



function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if multiple var assignnments are performed outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end



function space(num)
return tonumber(num) and (' '):rep(num) or ''
end



function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause, REAPER will hang
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
end



-- used in Sett_Dialogue() and in the main routine
function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+') -- invalid letters
	or not c:match('#%w+') then return -- '#000000' -- black
	end
return c
end



function hex_col2int(hex)
local t = {}
	for byte in hex:gmatch('%x%x') do
	t[#t+1] = tonumber(byte, 16)
	end
local r, g, b = table.unpack(t)
return r+g*256+b*256^2
end



function check(sett1, sett2)
-- checkmarking menu item when relevant boolean setting is enabled
-- sett2 is optional, a variable of a boolean setting
-- with which sett1 are mutually exclusive
-- so that when sett2 is enabled, sett1 is grayed out,
-- can be passed as several settings which are mutually excluive
-- and 'or' operator
return sett2 and '#' or sett1 and '!' or ''
end



function access_key(item, char)
local item = item:gsub(char, '&'..char:gsub('.', '%0\204\178')) -- '\204\178' -- Combining Low Line U+0332 // internal gsub in case char arg contains more than a single character
return item
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




function Get_Script_Settings_Section(scr_path)
local sett_sect, sett_t, found = '', {}
	for line in io.lines(scr_path) do
		if line:match('----- USER SETTINGS ------') and #sett_t == 0 then found = 1
		elseif found and line:match('END OF USER SETTINGS') then break
		elseif found then
		sett_sect = sett_sect..(#sett_sect > 0 and '\n' or '')..line
			if line:match('^[%u%w_]+%s*=%s*') then
			sett_t[#sett_t+1] = line
			end
		end
	end
return sett_sect, sett_t
end



function Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
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



-- used in GetObjChunk()
function create_random_name(char_num)
-- char_num is integer, the desired number of characters
math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count; math.floor() because the seeding number must be integer
local alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local name = ''
	for i=1,char_num do
	local rand = math.random(1, #alphabet)
	name = name..alphabet:sub(rand, rand)
	end
return name
end



-- used in Is_Track_Frozen(), Get_FX_Selected_In_Main_Chain(), Add_Item_Image()
-- Extract_Frozen_FX_Chain() and Apply_FX_Chain_Chunk()
local function GetObjChunk(obj, want_proj)
-- obj is track, item, take or envelope;
-- want_proj is boolean to extract chunk from a temporary
-- project file rather than temporary track template if
-- certain data aren't stored in the latter, such as freeze chunks;
-- optionally relies on create_random_name();
-- in order to use temp track template to extract the chunk
-- the target track must be selected;
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
	if not obj then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'MediaItem_Take*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, take, env = table.unpack(t)
-- Try standard function -----
local obj = take and r.GetMediaItemTake_Item(obj) or obj
local t = tr and {r.GetTrackStateChunk(obj, '', false)} or (item or take) and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
local ret, obj_chunk = table.unpack(t)
-- OR
-- local ret, obj_chunk = table.unpack(tr and {r.GetTrackStateChunk(obj, '', false)} or (item or take) and {r.GetItemStateChunk(obj, '', false)} or env and {r.GetEnvelopeStateChunk(obj, '', false)} or {x,x}) -- isundo = false // https://forum.cockos.com/showthread.php?t=181000#9
	if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') -- OR not r.SNM_CreateFastString
	then
		if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.53 or not tr then
		return 'err_mess'
		elseif tr then	-- if no extension and the chunk is too large for the native function, extract chunk from a temporary track template or project file, mainly relevant for track chunk because it's potentially the largest, supported since 6.53
			if not want_proj and not r.IsTrackSelected(obj) then return 'err_mess' end
		local path = r.GetProjectPath() -- media path, if no project file returns default recording path
		path = path..path:match('[\\/]')..(create_random_name and create_random_name(4) or 'TMP_LATE') -- without file extension, unnecessary and lengthens file name risking to hit path character limit if too deep // since file extension is ommitted the likelihood of collision with existing file drops significantly so create_random_name() function could be dispensed with
		r.Main_SaveProjectEx(0, path, want_proj and 0 or 1|2|4) -- save as temp project or SELECTED tracks template with items and envelopes
		local f = io.open(path, 'r')
			if f then
			obj_chunk = f:read('*a'); f:close(); os.remove(path) -- if temp proj file was created, this will return its entire content
				if not want_proj then return true, obj_chunk
				else -- extract track chunk from temp proj file
				-- in project file '<TRACK' header is followed by the track GUID in the same line, but not in track template,
				-- still this doesn't break the track when such chunk is set
				local ret, GUID = r.GetSetMediaTrackInfo_String(obj, 'GUID', '', false) -- is_set false
				local chunk, found = ''
					for line in obj_chunk:gmatch('[^\n\r]+') do
					line = line:match('%S.*') -- flatten the identation in the project file data and accounting for a single character on the line such as <>, and empty line, which is likely to conclude the project file
						if line and line:match('<TRACK') then -- not validating track GUID on this line because this format only applies to project file
							if found then break -- track chunk which follows the target one
							else
							chunk = chunk..(#chunk > 0 and '\n' or '')..line -- start assembling chunk and keep until track GUID is validated
							end
						elseif #chunk > 0 then
						chunk = chunk..'\n'..line -- assemble the chunk
							if line:match('TRACKID') then
								if line:match('{.-}') == GUID then -- target track
								found = 1 -- target track found, the chunk will keep being assembled
								else
								chunk, found = '' -- reset
								end
							end
						end
					end
				return true, chunk
				end
			end
		end
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



function Err_mess() -- if chunk size limit is exceeded and SWS extension isn't installed
local sws_ext_err_mess = "            The size of the data requires\n\n  the SWS/S&M extension to handle them.\n\nIf it's installed then it needs to be updated.\n\n         After clicking \"OK\" a link to the\n\n SWS extension website will be provided\n\n\tThe script will now quit."
local sws_ext_link = 'Get the SWS/S&M extension at\n\nhttps://www.sws-extension.org/\n\nOR\n\nhttps://github.com/reaper-oss/sws/tags'
local resp = r.MB(sws_ext_err_mess,'ERROR',0)
	if resp == 1 then r.Main_OnCommand(42663, 0) end -- ReaScript: Show ReaScript console // to override preference at Plug-ins -> ReaScript -> Do not auto-open ReaScript console which was added in 7.28, while the action was added in 7.0
r.ShowConsoleMsg(sws_ext_link, r.ClearConsole())
end



-- used in Add_Item_Image()
local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local t = {}
-- 'TrackEnvelope*' works for take envelope as well
	for k, typename in ipairs({'MediaTrack*', 'MediaItem*', 'MediaItem_Take*', 'TrackEnvelope*'}) do
	t[#t+1] = r.ValidatePtr(obj, typename)
	end
local tr, item, take, env = table.unpack(t)
local obj = take and r.GetMediaItemTake_Item(obj) or obj
return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or (item or take) and r.SetItemStateChunk(obj, obj_chunk, false) or env and r.SetEnvelopeStateChunk(obj, obj_chunk, false) -- isundo is false // https://forum.cockos.com/showthread.php?t=181000#9
end



-- used in Process_Image_File_Paths()
function file_exists(path)
-- CROSS-PLATFORM, BUT RETURNS TRUE IF THE PATH DOESN'T INCLUDE THE ACTUAL FILE NAME
-- so for file path validation file name presence must be ensured
	if not path:match('.-%.%w+$') then return end
local ok, mess, code = os.rename(path, path)
return (ok or code == 13) and path -- 13 is error code for 'exists but permission denied' on some systems
end



function Process_File_Path(f_path)
-- searches depending on file path format:
-- file name: project folder root, /Data/track_icons, /Data/toolbar_icons
-- relative path: project folder subfolders, resource path subfolders
-- absolute path: at the actual path;
-- relies on file_exists()

local f_path = f_path:match('%S') and f_path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces // OR ('(%S.+)%s*$')
	if not f_path then return end

local resources = r.GetResourcePath()
local sep = resources:match('[\\/]')
local proj, proj_path = r.EnumProjects(-1) -- proj_path may be empty if project has never been saved
local t = not f_path:match('[\\/]') and f_path:match('.+%.%w+$') -- file name only, search in the project folder and /Data sufolders
and {proj_path..sep..f_path, resources..sep..'Data'..sep..'track_icons'..sep..f_path,
resources..sep..'Data'..sep..'toolbar_icons'..sep..f_path}
or not f_path:match('^%u:') -- relative path, search in resource and project directories
and {proj_path..sep..f_path, resources..sep..f_path}
or {f_path}

	for k, path in ipairs(t) do
		if file_exists(path) then return path end
	end

end




function find_layout(layout_name, want_mcp)
-- if layout_name is invalid returns current layout;
-- want_mcp is boolean to search among MCP layouts,
-- support for transport, EnvCP, master TCP and MCP
-- can be added;
-- if supplied layout_name is not found returns
-- false and layout count
local Get = r.ThemeLayout_GetLayout
	if layout_name then
	local i = 0
		repeat
		local retval, name = Get(want_mcp and 'mcp' or 'tcp', i)
			if name == layout_name then return 1 end
			i=i+1
		until not retval
	return false, i+1
	else
	local retval, name = Get(want_mcp and 'mcp' or 'tcp', -1)
	return name
	end
end



-- used in Image_Path_Edit_Dialogue(), in Track_Sends_Audio_Or_MIDI() and in the main routine
function valid_image_extension(path)
return ('PNG,JPG,JPEG'):lower():match(path:lower():match('.+%.(%w+)$'))
end



-- used in Sett_Dialogue()
function Image_Path_Edit_Dialogue(path)

	if #path > 0 then
	local resp = r.MB('Current path:\n\n'..path..'\n\nY E S  —  change\n\nN O  —  clear', 'EDIT IMAGE PATH', 3)
		if resp ~= 6 then
		return resp == 7 and '' or path -- clear path if NO was clicked, or original path if cancelled
		end
	end

::RELOAD::
local ret, file = r.GetUserFileNameForRead('', 'BROWSE FOR THE IMAGE FILE (.png, .jpg)', '')
	if not ret then return path -- file dialogue exited
	elseif not valid_image_extension(file) then
	Error_Tooltip('\n\n invalid extension \n\n', 1, 1, 50, 50) -- caps, spaced true, x2 50, y2 50
	goto RELOAD
	else return file
	end

end



-- used in TCP_Layout_Edit_Dialogue()
function Get_Layouts(section)
-- section is 'mcp', 'tcp', 'trans' etc.
local i, t = 1, {} -- 0 is index of the global default layout, for which the function returns empty string
	repeat
	local retval, name = r.ThemeLayout_GetLayout(section, i)
		if #name > 0 then -- or 'if retval'
		t[#t+1] = name
		end
	i=i+1
	until #name == 0 -- or not retval
return t
end



-- used in Sett_Dialogue()
function TCP_Layout_Edit_Dialogue(layout)
	if #layout > 0 then
	local resp = r.MB('Current layout:  '..layout..'\n\nY E S  —  change\n\nN O  —  clear', 'EDIT TCP LAYOUT', 3)
		if resp ~= 6 then
		return resp == 7 and '' or layout -- clear path if NO was clicked, or original path if cancelled
		end
	end
local t = Get_Layouts('tcp')
local esc_layout = Esc(layout)
local menu = table.concat(t, '|'):gsub(#layout > 0 and esc_layout or '', #layout > 0 and '!%0' or '')
local output = gfx.showmenu('BACK||'..menu) -- checkmarking layout matching current setting
return output > 1 and t[output-1] or layout -- return current value if layout menu was exited without selection, i.e. output 0, or 1 if BACK button was clicked
end



-- used in Sett_Dialogue()
function Color_Edit_Dialogue(color)
	if #color > 0 then
	local resp = r.MB('Current color:  '..color..'\n\nY E S  —  change\n\nN O  —  clear', 'EDIT TCP COLOR', 3)
		if resp ~= 6 then
		return resp == 7 and '' or color -- clear path if NO was clicked, or original path if cancelled
		end
	end
local retval, int = r.GR_SelectColor(r.GetMainHwnd()) -- if main window handle isn't passed, the main window will be able to obscure the color picker window // since build 7.83 opens color picker, OS supplied or REAPER's built-in, depending in the Preference -> Appearance -> Use OS provided color chooser
	if retval == 0 then return color -- canceled
	else return string.format('#%x', int) -- format as a hexadecimal to store in the script settings
	end
end



function Sett_Dialogue(path, color, prefix, layout)
-- only single argument must be valid'
-- path argument isn't used, for path editing
-- the function is superceded by Image_Path_Edit_Dialogue()

local sett = path or color or layout
local func = path and Image_Path_Edit_Dialogue or color and Color_Edit_Dialogue or layout and TCP_Layout_Edit_Dialogue

	if sett then return func(sett)
	else
	local ret, output = r.GetUserInputs('Edit track label prefix', 1, 'Submit empty to clear,extrawidth=100', prefix)
	return not ret and prefix or not output:match('%S') and '' or output
	end

end




-- used in Store_Track_Props(), UNFREEZE_AND_RESTORE_PROPS()
-- and main routine
function Is_Track_Frozen(tr)
-- returns freeze count, 0 if track is not frozen;
-- in builds older than 7.43 requires either SWS extension
-- or GetObjChunk() function
local cnt
	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.43 then
	cnt = r.GetMediaTrackInfo_Value(tr, 'I_FREEZECOUNT')
	elseif r.BR_GetMediaTrackFreezeCount then
	cnt = r.BR_GetMediaTrackFreezeCount(tr)
	else
	local ret
	ret, chunk = GetObjChunk(tr) -- this track is selected by design, in case the chunk must be extracted from temp track template
	cnt = chunk and select(2, chunk:gsub('<FREEZE', ''))
	end
return cnt
end



-- used in Store_Track_Props()
function Track_Controls_Locked(tr) -- locked is 1, not locked is nil
-- takes advantage of the inability to mute a track
-- whose controls are locked, even via API
	if tr == r.GetMasterTrack(0) then return end -- Master track controls cannot be locked
r.PreventUIRefresh(1)
local mute_state = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state ~ 1) -- flip the state
local mute_state_new = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
local locked
	if mute_state == mute_state_new then locked = 1
	else r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state) -- restore
	end
r.PreventUIRefresh(-1)
return locked
end



-- used in Store_Track_Props() and Restore_Track_Props()
function Get_All_Descendants(...)
-- arg is either parent track idx or parent track pointer

local arg = {...}

	if #arg == 0 then return end

local tr_idx, tr

	if tonumber(arg[1]) then tr_idx = arg[1]
	elseif r.ValidatePtr(arg[1], 'MediaTrack*') then tr = arg[1]
	else return
	end

tr = tr or r.CSurf_TrackFromID(tr_idx, false) -- mcpView false
tr_idx = tr_idx or r.CSurf_TrackToID(tr, false)-1 -- mcpView false

local desc_t = {}

	if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 then -- parent
	local depth = r.GetTrackDepth(tr)
		for i = tr_idx+1, r.CountTracks(0)-1 do -- starting from the next track
		local tr = r.GetTrack(0,i)
		local tr_depth = r.GetTrackDepth(tr)
			if tr_depth > depth then
			desc_t[#desc_t+1] = tr
			desc_t[tr] = ''
			elseif tr_depth <= depth then break
			end
		end
	end

return desc_t

end



-- used in Store_Track_Props() and Apply_Settings()
function Track_Sends_Audio_Or_MIDI(tr, sibl_t)
-- only meant to evaluate sends of children tracks
-- in a folder whose parent is being frozen
-- in order to determine whether to apply to them
-- BYPASS_DESCENDANT_TRACK_FX and MUTE_DESCENDANT_TRACKS settings;
-- tr is a folder child track,
-- sibl_t is table stemming from Get_All_Descendants()
-- containing all siblings of tr;
-- track is considered sending if it has active send
-- and is either itself has items or passes audio
-- or midi received from other tracks via receives


-- find at least one send to a destination which warrants
-- leaving the send operational, i.e. not muting the track
-- and not bypassing its fx chain
local Get, audio, midi, post_fx_snd = r.GetTrackSendInfo_Value
	for i=0, r.GetTrackNumSends(tr,0)-1 do -- 0 sends
	local audio_snd = Get(tr, 0, i, 'I_SRCCHAN') ~= -1 -- 0 send // audio send enabled
	local midi_snd = Get(tr, 0, i, 'I_MIDIFLAGS')&0x1F ~= 31 -- OR &31 ~= 31 // 5 bit mask, low 5 bits source channel, midi send not disabled // 0 send
		if audio_snd or midi_snd then
		local mode = Get(tr, 0, i, 'I_SENDMODE') -- 0 send
		local dest_tr = Get(tr, 0, i, 'P_DESTTRACK') -- 0 send
		-- not evaluating send level and mute state because these can be changed by the user any time
		-- so don't warrant ignoring send completely
			if mode ~= 8 -- not pre-receive send, otherwise the audio sent to current track from the pre-receive destination track receiving midi will be frozen at its parent track level and keeping send operational won't make sense
			and (not sibl_t[dest_tr] -- doesn't send to a sibling via the current send // otherwise the sibling receive will be frozen and the parent level and sibling Master/parent send will be auto-disabled by freeze action so keeping send operational won't make sense
			or Track_Sends_Audio_Or_MIDI(dest_tr, sibl_t)) -- or does send to a sibling and the sibling itself sends to outside tracks so audio path must remain open
			and not r.IsTrackSelected(dest_tr) -- doesn't send to a selected track which will be frozen itself by dint of being selected and whose receives will be automatically cleared so the send will be cleared too
			then
			-- running the loop til the end to catch at least one post-fx send
			-- to justify not bypassing the fx chain if 'bypass descendant FX' setting is enabled
			-- and catch all possible send types, i.e. audio and midi
			post_fx_snd = post_fx_snd or mode ~= 1 -- mode isn't pre-fx
			audio, midi = audio or audio_snd, midi or midi_snd
			end
		end
	end

	if not audio and not midi then return end -- no sends


	local function evaluate_track_send_data_src(tr, audio, midi)
	-- search for track send data source, which is either items on the track or its receives
		for i = 0, r.CountTrackMediaItems(tr)-1 do
		local item = r.GetTrackMediaItem(tr, i)
		local take = r.GetActiveTake(item)
		-- not evaluating take level, item mute status, audio source / midi note events
		-- being within visible take area or existing at all
		-- because these can be changed by the user any time
		-- so don't warrant ignoring such items completely
			if take then -- ensures that not an empty item
				if audio then
				local src = r.GetMediaItemTake_Source(take)
				src = src or r.GetMediaSourceParent(src) -- won't return accurate pointer for reversed source and source section, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
				local typ = r.GetMediaSourceType(src, ''):gsub('_OFFLINE_', '') -- media forced offline state when type includes _OFFLINE_ prefix
				local file = r.GetMediaSourceFileName(src, '')
					if typ:match('VIDEO') and not valid_image_extension(file) -- VIDEO type covers image files, which are irrelevant here, using match() to accommodate _OFFLINE_VIDEO type
					or ('WAVE,RPP_PROJECT,CLICK,LTC,MP3,VORBIS,OPUS,REX,FLAC,SD2,WAVPACK,SECTION'):match(typ)
					then return 1
					end
				end
				if midi and r.TakeIsMIDI(take) then return 1 end
			end
		end

	-- if audio/midi items weren't found, evaluate track receives
	local Get = r.GetTrackSendInfo_Value
		for i=0, r.GetTrackNumSends(tr,-1)-1 do -- -1 receives
		local audio_rcv = Get(tr, -1, i, 'I_SRCCHAN') ~= -1 -- arg -1 receive // audio send enabled
		local midi_rcv = Get(tr, -1, i, 'I_MIDIFLAGS')&0x1F ~= 31 -- OR &31 ~= 31 // 5 bit mask, low 5 bits source channel, midi send not disabled // -1 receive
		-- not evaluating send level and mute state because these can be changed by the user any time
		-- so don't warrant ignoring send
			if audio and audio_rcv or midi and midi_rcv then
			local src_tr = Get(tr, -1, i, 'P_SRCTRACK') -- -1 receive
				-- scan items on the receive source track and if not found
				-- scan its own receives recursively
				if evaluate_track_send_data_src(src_tr, audio, midi) then
				return 1
				end
			end
		end
	end

return evaluate_track_send_data_src(tr, audio, midi), post_fx_snd

end




function Store_Track_Props(tr)
-- TRACK_ICON_PATH, FROZEN_ITEM_IMAGE_PATH, TRACK_COLOR, TRACK_LABEL_PREFIX, TCP_LAYOUT_NAME, LOCK_TRACK_CONTROLS, MINIMIZE_TCP_AND_LOCK_HEIGHT, KEEP_ITEM_NAME_AFTER_FREEZING, BYPASS_DESCENDANT_TRACK_FX, MUTE_DESCENDANT_TRACKS, COLLAPSE_DESCENDANT_TRACKS

	-- don't store props of a frozen track
	-- because this is inconsistent with the script purpose,
	-- the props must stem from a completely unfrozen track
	-- so that a clear distinction between frozen and unfrozen
	-- is maintained, and also because if a track is freezed
	-- again over previous freeze effected by this script,
	-- its props will have been modified by the script
	-- and won't represent its props in unfrozen state which the script
	-- is designed to restore when the track is completely unfrozen
	if Is_Track_Frozen(tr) > 0 then return 1 end

local t = {}

local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value

	for k, attr in ipairs{'I_CUSTOMCOLOR', 'I_HEIGHTOVERRIDE', 'B_HEIGHTLOCK', 'I_FOLDERCOMPACT'} do
	local val = Get(tr, attr)
		if k == 1 then -- color
		val = val < 0x1000000 and 0 or val-0x1000000 -- subtract to ensure consistency of color values and then be able to set color by re-adding 0x1000000 // if returned color integer is smaller than 0x1000000 then it was stored but not applied, in which case the track with be colored with theme default color, integer 0; tcp default color integer is 16576 immediatedly after REAPER startup which equals 192,64,0 - RGB, the color selected in the track color picker by default, but not applied; if 'Track: Set to default color' action was applied at least once the value becomes 0 (relevant to versions 5 - 7, didn't test earlier), so this expression prevents storage of this non-applied color as default so that it's not applied at the restoration stagee
		end
	-- I_HEIGHTOVERRIDE value changes when TCP height is adjusted by dragging
	-- and is reset with 'Zoom vertically' and other actions which affect vertical zoom;
	-- value 0 resets TCP height to last height effected by 'Zoom vertically'
	-- or other actions which affect vertical zoom;
	-- I_HEIGHTOVERRIDE temporarily disables height locked status
	-- without clearing the checkmark in the track right click menu https://forum.cockos.com/showthread.php?p=2202082
	t[#t+1] = math.floor(attr == 'I_HEIGHTOVERRIDE' and val == 0 and r.GetMediaTrackInfo_Value(tr, 'I_TCPH') or val)
	end


local GetSet = r.GetSetMediaTrackInfo_String
local ret, icon = GetSet(tr, 'P_ICON', '', false) -- is_set false // contrary to the API doc returns FULL path to /Data/track_icons and /Data/toolbar_icons and file name or relative path to project directory, in the chunk in all 3 cases only the file name is listed in TRACKIMGFN attribute or relative path under the project directory, the same is true to item notes image chunk attribute RESOURCEFN
table.insert(t, 1, r.resolve_fn(icon, '')) -- the resolve function returns full path to the project directory // image_resolve_fn isn't suitable because will return path to /Data/track_icons if homonymous file is found there despite icon's being available in the project directory
local ret, name = GetSet(tr, 'P_NAME', '', false) -- is_set false
table.insert(t, 3, name)
local ret, layout = GetSet(tr, 'P_TCP_LAYOUT', '', false)
table.insert(t, 4, layout)
local controls_locked = Track_Controls_Locked(tr)
table.insert(t, 5, controls_locked and '1' or '0')

GetSet(tr, 'P_EXT:track_props', '"'..table.concat(t, '"\t"')..'"', true) -- is_set true

--[[
props order under 'track_props' extended state label
1. icon path, str
2. color, int
3. track name, str
4. layout name, str
5. locked controls boolean 0 or 1, int
6. height, int
7. height lock status, boolean 0 or 1, int
8. folder collapse state, 0, 1, 2, int
--]]

-- store props of children tracks, if any, in a folder whose parent track that's being frozen
local mute, bypass = MUTE_DESCENDANT_TRACKS:match('%S'), BYPASS_DESCENDANT_TRACK_FX:match('%S')
	if mute or bypass then
	local desc_t = Get_All_Descendants(tr)
	local to_mute, to_bypass_chain = '',''
		for k, tr in ipairs(desc_t) do
		local track_sends, post_fx_snd = Track_Sends_Audio_Or_MIDI(tr, desc_t)
		local ret, GUID = GetSet(tr, 'GUID', '', false) -- is_set false
		local fx_chain_on = Get(tr, 'I_FXEN') ~= 0 and r.TrackFX_GetCount(tr) > 0 -- I_FXEN returns 1 when the chain is empty as well
			if mute and not track_sends then -- track doesn't have sends which would be shut down if it were muted
			to_mute = to_mute..GUID
			end
			if bypass and fx_chain_on and not post_fx_snd then
			to_bypass_chain = to_bypass_chain..GUID
			end
		end
		-- storing in the parent track extended state
		if #to_mute > 0 then
		GetSet(tr, 'P_EXT:children_muted', to_mute, true) -- is_set true
		end
		if #to_bypass_chain > 0 then
		GetSet(tr, 'P_EXT:children_chain_bypassed', to_bypass_chain, true)
		end
	end

end



-- used in FREEZE__STORE_PROPS_AND_APPLY_SETTINGS()
function Apply_Settings(tr)
-- has been separated from Store_Track_Props() function
-- because with folders if settings to mute children tracks
-- and/or bypass their fx chain are enabled
-- and they're muted and/or fx chains are bypased before freezing,
-- their audio won't be included in the frozen item
-- or it won't be processed by the fx

-- the order: TRACK_ICON_PATH, FROZEN_ITEM_IMAGE_PATH, TRACK_COLOR, TRACK_LABEL_PREFIX, TCP_LAYOUT_NAME, LOCK_TRACK_CONTROLS, MINIMIZE_TCP_AND_LOCK_HEIGHT, KEEP_ITEM_NAME_AFTER_FREEZING, BYPASS_DESCENDANT_TRACK_FX, MUTE_DESCENDANT_TRACKS, COLLAPSE_DESCENDANT_TRACKS

local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
local GetSet = r.GetSetMediaTrackInfo_String
local color = Get(tr, 'I_CUSTOMCOLOR')
local height = Get(tr, 'I_HEIGHTOVERRIDE')
height = height ~= 0 and height or Get(tr, 'I_TCPH')
local ret, icon = GetSet(tr, 'P_ICON', '', false) -- is_set false // contrary to the API doc returns FULL path to /Data/track_icons and /Data/toolbar_icons and file name or relative path to project directory, in the chunk in all 3 cases only the file name is listed in TRACKIMGFN attribute or relative path under the project directory, the same is true to item notes image chunk attribute RESOURCEFN
icon = r.resolve_fn(icon, '') -- the resolve function returns full path to the project directory // image_resolve_fn isn't suitable because will return path to /Data/track_icons if homonymous file is found there despite icon's being available in the project directory
local ret, name = GetSet(tr, 'P_NAME', '', false) -- is_set false
local ret, layout = GetSet(tr, 'P_TCP_LAYOUT', '', false)

	if tonumber(TRACK_COLOR) and TRACK_COLOR ~= color-0x1000000 then Set(tr, 'I_CUSTOMCOLOR', TRACK_COLOR|0x1000000) end -- if valid, TRACK_COLOR at this stage is integer, converted outside from hex, otherwise empty string
		if MINIMIZE_TCP_AND_LOCK_HEIGHT:match('%S') then
			if height ~= 1 then Set(tr, 'I_HEIGHTOVERRIDE', 1) end -- collapse frozen track // doesn't affect active lock state
			if Get(tr, 'B_HEIGHTLOCK') == 0 then Set(tr, 'B_HEIGHTLOCK', 1) end
		end
	if COLLAPSE_DESCENDANT_TRACKS:match('%S') and Get(tr, 'I_FOLDERCOMPACT') ~= 2 then Set(tr, 'I_FOLDERCOMPACT', 2) end
	if #TRACK_ICON_PATH > 0 and TRACK_ICON_PATH ~= icon then GetSet(tr, 'P_ICON', TRACK_ICON_PATH, true) end -- is_set true
	-- FROZEN_ITEM_IMAGE_PATH is applied AFTER freezing in FREEZE__STORE_PROPS_AND_APPLY_SETTINGS() once item has been created
	if TRACK_LABEL_PREFIX:match('%S') then
		if not name:match('^'..Esc(TRACK_LABEL_PREFIX)) then -- only apply if track label doesn't already start with the prefix which will be the case if the track was already once frozen with the script but not unfrozen // alternatively 'if not Is_Track_Frozen(tr)' could be used as a condition but it's more expensive than string evaluation
		GetSet(tr, 'P_NAME', TRACK_LABEL_PREFIX..' '..name, true) -- is_set true
		end
	end
	if TCP_LAYOUT_NAME:match('%S') and TCP_LAYOUT_NAME ~= layout then GetSet(tr, 'P_TCP_LAYOUT', TCP_LAYOUT_NAME, true) end
	if LOCK_TRACK_CONTROLS:match('%S') and not Track_Controls_Locked(tr) then r.Main_OnCommand(41312, 0) end -- Track: Lock track controls // the track must be selected
	-- KEEP_ITEM_NAME_AFTER_FREEZING is applied AFTER freezing in FREEZE__STORE_PROPS_AND_APPLY_SETTINGS() once item has been created

-- store props of children tracks, if any, in a folder whose parent track that's being frozen
local mute, bypass = MUTE_DESCENDANT_TRACKS:match('%S'), BYPASS_DESCENDANT_TRACK_FX:match('%S')
	if mute or bypass then
	local desc_t = Get_All_Descendants(tr)
	local to_mute, to_bypass_chain = '',''
		for k, tr in ipairs(desc_t) do
		local track_sends, post_fx_snd = Track_Sends_Audio_Or_MIDI(tr, desc_t)
		local ret, GUID = GetSet(tr, 'GUID', '', false) -- is_set false
		local fx_chain_on = Get(tr, 'I_FXEN') ~= 0 and r.TrackFX_GetCount(tr) > 0 -- I_FXEN returns 1 when the chain is empty as well
			if mute and not track_sends and Get(tr, 'B_MUTE') == 0 then -- track doesn't have sends which would be shut down if it were muted
			Set(tr, 'B_MUTE', 1)
			end
			if bypass and fx_chain_on and (not track_sends or not post_fx_snd) then
			Set(tr, 'I_FXEN', 0)
			end
		end
	end

end




-- used in FREEZE__STORE_PROPS_AND_APPLY_SETTINGS()
function Create_Temp_Track_Move_FX_To_From(obj, fx_idx, tmp_tr, move)

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Copy = take and r.TrackFX_CopyToTake or r.TrackFX_CopyToTrack

	if not tmp_tr then
	r.PreventUIRefresh(1)
	local Copy = take and r.TakeFX_CopyToTrack or r.TrackFX_CopyToTrack
	-- r.Main_OnCommand(40702, 0) -- Track: Insert new track at end of track list and hide it // creates undo point hence unsuitable
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
	local tmp_tr = r.GetTrack(0,r.CountTracks(0)-1)
	r.SetMediaTrackInfo_Value(tmp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
	r.SetMediaTrackInfo_Value(tmp_tr, 'B_SHOWINTCP', 0) -- hide in Arrange
	-- fx are moved in reversed order to simplicity, to be able to return them
	-- in reversed order as well thereby restoring the original order
	r.PreventUIRefresh(-1)
	return tmp_tr -- will have to be deleted outside with r.DeleteTrack(tmp_tr)
	else
	local src, targ = table.unpack(move and {obj, tmp_tr} or {tmp_tr, obj})
	Copy(src, fx_idx, targ, 0, true) -- is_move true
	end

end




-- used in FREEZE__STORE_PROPS_AND_APPLY_SETTINGS()
function Get_FX_Selected_In_Main_Chain(obj, input_fx)
-- input_fx is boolean to target track input fx chain
-- relies on GetObjChunk() for builds older than 7.06
-- chunk LASTSEL and GetNamedConfigParm 'chain_sel' value may be -1
-- if no fx or if it's been reset after copying FX chain
-- as per the bug report https://forum.cockos.com/showthread.php?t=311951,
-- fixed in build 7.83 therefore must be additionally validated by FX_GetCount()

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetParm, CountFX = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetCount}
or {r.TrackFX_GetNamedConfigParm, input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetCount})
local idx
	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.06 then
	local ret
	ret, idx = GetParm(obj, input_fx and 0x1000000 or 0, 'chain_sel') -- idx is empty string if chain is empty
	else
	local ret, chunk = GetObjChunk(obj) -- track here is selected by design, in case the chunk must be extracted from temp track template
		if ret == 'err_mess' then return end
	chunk = tr and input_fx and (chunk:match('(<FXCHAIN_REC.*>)\n<ITEM')
	or chunk:match('(<FXCHAIN_REC.*WAK.*>)\n>')) or chunk
	idx = chunk:match('LASTSEL ([%-%d]+)')
	end

idx = tonumber(idx)
-- due to the bug mentioned above, when value is -1 it must be validated by getting fx count
-- because it's only accurate when there're no fx in the chain,
-- if selected fx cannot be determined due to the bug,
-- the index of the first is returned;
-- when the chain is empty the function returns false
return idx and idx > -1 and idx or CountFX(obj) > 0 and 0
end




function Add_Image_To_Remove_From_Item(item, f_path, mode)
-- when f_path is invalid the image, if any, is removed
-- mode is 1 - Center/tile image, 3 - Stretch image/text
-- or 5 - Full height image; not used here, defaults to 1
-- relies on GetObjChunk() and SetObjChunk()
-- when image is added text notes are unavailable
-- which is REAPER's behavior even if image is added manually

local ret, chunk = GetObjChunk(item)
		if ret == 'err_mess' or not chunk then return end -- chunk can be nil if frozen item has not been created due to lack of audio data

local curr_image = chunk:match('RESOURCEFN "(.-)"')

	if not f_path and not curr_image then return end -- when removing, exit if there's no image in the item

local src_patt = not curr_image and 'IGUID {.-}' or 'RESOURCEFN ".-"'
local repl_patt = (not curr_image and '%0\n' or '')..(f_path and 'RESOURCEFN "'..f_path:gsub('%%', '%%%%')..'"' or '')
chunk = chunk:gsub(src_patt, repl_patt, 1)

	if f_path then
	local IMGRESOURCEFLAGS = chunk:match('IMGRESOURCEFLAGS (%d+)')
	src_patt = not IMGRESOURCEFLAGS and 'RESOURCEFN ".-"' or 'IMGRESOURCEFLAGS %d+'
	-- to be able to change image display mode, word wrap bit must be set separately
	local word_wrap = IMGRESOURCEFLAGS and IMGRESOURCEFLAGS+0&8 == 8 -- &8 is Word wrap
	local bitfield = word_wrap and 1|8 or 1 -- &1 Center/Tile image
	repl_patt = (not IMGRESOURCEFLAGS and '%0\n' or '')..'IMGRESOURCEFLAGS '..bitfield
	chunk = chunk:gsub(src_patt, repl_patt, 1)
	end

SetObjChunk(item, chunk)

end



function Items_Exist_On_Descendant_Tracks(tr)

local desc_t = Get_All_Descendants(tr)
	for k, tr in ipairs(desc_t) do
		if r.CountTrackMediaItems(tr) > 0 then return 1 end
	end

end



function Active_Audio_Receives_Exist(tr)
local Get = r.GetTrackSendInfo_Value
	for i=0, r.GetTrackNumSends(tr,-1)-1 do -- -1 receives
	local audio_rcv = Get(tr, -1, i, 'I_SRCCHAN') ~= -1 -- arg -1 receive // audio send enabled
		if Get(tr, -1, i, 'B_MUTE') ~= 1 then -- receive not muted // OR == 0
		local src_tr = Get(tr, -1, i, 'P_SRCTRACK') -- -1 receive
			-- scan items on the receive source track and if not found
			-- scan its own receives recursively
			for i=0, r.CountTrackMediaItems(src_tr)-1 do
			local item = r.GetTrackMediaItem(src_tr, i)
				if r.GetActiveTake(item) and r.GetMediaItemInfo_Value(item, 'B_MUTE') == 0 -- valid take and not muted // presence of note events in MIDI items as well as items level aren't evaluated
				then return 1
				end
			end
		return Active_Audio_Receives_Exist(src_tr) -- if not exited early go recursive scanning the entire receive path
		end
	end
end




function FREEZE__STORE_PROPS_AND_APPLY_SETTINGS(sel_tr, actID, selected, last_unbypassed_online)
-- sel_tr is selected tracks table constructed in the main routine;
-- selected and last_unbypassed_online passed as booleans

local GetSet = r.GetSetMediaItemTakeInfo_String
local tmp_tr = Create_Temp_Track_Move_FX_To_From()
local valid_tracks, failed = 0, {}

	for k, props in ipairs(sel_tr) do
	local tr, to_freeze = props.tr, props.to_freeze
		if to_freeze then -- excluding selected tracks where there's nothing to freeze
		valid_tracks = valid_tracks+1
		r.SetOnlyTrackSelected(tr)
		-- handle fx chain
		local sel_fx = selected and Get_FX_Selected_In_Main_Chain(tr)
		local fx_cnt = r.TrackFX_GetCount(tr)
		local st, active = sel_fx or 0
			if st == -1 and fx_cnt > 0 then -- last sel fx value may be -1 even when there're fx in the chain due to bug in builds older than 7.83 https://forum.cockos.com/showthread.php?t=311951, so collect the affected tracks indices to inform the user
			failed[#failed+1] = math.floor(r.CSurf_TrackToID(tr, false)) -- mcpView false // stripping trailing decimal zero
			end
			if st ~= -1 then -- only run when > -1, i.e. there're fx in the chain and the value is not affected by the bug above because the index of the last selected fx cannot be reliably determined, a pretty edge case because normally a user would explicitly select an fx in the chain before freezing in 'up to selected' mode
				for i=fx_cnt-1, st, -1 do -- in reverse because fx are removed
				active = active or not r.TrackFX_GetOffline(tr, i) and r.TrackFX_GetEnabled(tr, i) -- as soon as the farthest active fx is found, the condition becomes always true to prevent movement of previous fx
					if sel_fx and i > sel_fx or last_unbypassed_online and not active then
					Create_Temp_Track_Move_FX_To_From(tr, i, tmp_tr, 1) -- move true, move fx to temp track
					end
				end
			end
		-- store item name before freezing
		local item_name
			-- if track gets frozen multiple times in a row the take original name
			-- will be retained across all freezes if the setting is enabled
			if KEEP_ITEM_NAME_AFTER_FREEZING:match('%S') and r.CountTrackMediaItems(tr) == 1 then
			local take = r.GetActiveTake(r.GetTrackMediaItem(tr, 0))
				if take then
				local ret
				ret, item_name = GetSet(take, 'P_NAME', '', false) -- is_set false
				end
			end
		r.Main_OnCommand(actID, 0) -- freeze
			-- restore isolated fx back to the source track in the original order
			for i=r.TrackFX_GetCount(tmp_tr)-1, 0, -1 do -- in reverse because fx are removed
			Create_Temp_Track_Move_FX_To_From(tr, i, tmp_tr) -- move false, return fx to the source track
			end
		local frozen_item = r.GetTrackMediaItem(tr, 0)
			-- apply name to the frozen item
			if item_name and r.CountTrackMediaItems(tr) == 1 then
			GetSet(r.GetActiveTake(frozen_item), 'P_NAME', item_name, true) -- is_set true
			end
			if #FROZEN_ITEM_IMAGE_PATH > 0 then -- apply item image at each freeze iteration because each next freeze not preceded with unfreeze updates the item and image applied earlier gets removed
			Add_Image_To_Remove_From_Item(frozen_item, FROZEN_ITEM_IMAGE_PATH)
			end
		Apply_Settings(tr)
		end
	end

r.DeleteTrack(tmp_tr)

-- restore track selection and apply settings
	for k, props in ipairs(sel_tr) do
	r.SetTrackSelected(props.tr, true) -- selected true
	end


return valid_tracks, failed

end



-- used in UNFREEZE_AND_RESTORE_PROPS()
function Restore_Track_Props(tr)

--[[
props order under 'track_props' extended state label
1. icon path, str
2. color, int
3. track name, str
4. layout name, str
5. locked controls boolean 0 or 1, int
6. height, int
7. height lock status, boolean 0 or 1, int
8. folder collapse state, 0, 1, 2, int
--]]

local GetSet = r.GetSetMediaTrackInfo_String
local Get, Set = r.GetMediaTrackInfo_Value, r.SetMediaTrackInfo_Value
local ret, props = GetSet(tr, 'P_EXT:track_props', '', false) -- is_set false
props = #props > 0 and props..'\t' or props -- add trailing tab space for the gmatch capture to work for the last entry
local cntr = 0
	for prop in props:gmatch('[^\t]+') do
		if prop then
		cntr = cntr + 1
		local prop = prop:sub(2,-2) -- strip quotation marks

		-- these 2 properties can be originally empty thus empty string has to be restored
		local set = cntr == 1 and GetSet(tr, 'P_ICON', prop, true) -- is_set true
		set = cntr == 3 and GetSet(tr, 'P_NAME', prop, true) -- is_set true

			if #prop > 0 then -- stored data
			local set = cntr == 1 and GetSet(tr, 'P_ICON', prop, true) -- is_set true
			set = cntr == 2 and Set(tr, 'I_CUSTOMCOLOR', prop+0 == 0 and 0 or prop+0|0x1000000) -- if track original color was default, apply default, i.e. 0 without 0x1000000
			set = cntr == 4 and GetSet(tr, 'P_TCP_LAYOUT', prop, true)
			set = cntr == 5 and prop == '0' and r.Main_OnCommand(41313, 0) -- Track: Unlock track controls
			set = cntr == 6 and Set(tr, 'I_HEIGHTOVERRIDE', prop)
			set = cntr == 7 and prop == '0' and Set(tr, 'B_HEIGHTLOCK', 0)
			set = cntr == 8 and prop ~= '2' and Set(tr, 'I_FOLDERCOMPACT', prop)
			end
		end
	end

-- restore children props
local ret, muted_children = GetSet(tr, 'P_EXT:children_muted', '', false)
local ret, bypassed_chain_children = GetSet(tr, 'P_EXT:children_chain_bypassed', '', false)
local child_t = Get_All_Descendants(tr)

	for k, tr in ipairs(child_t) do
	local ret, GUID = GetSet(tr, 'GUID', '', false)
		if muted_children:match(Esc(GUID)) then
		Set(tr, 'B_MUTE', 0)
		end
		if bypassed_chain_children:match(Esc(GUID)) then
		Set(tr, 'I_FXEN', 1)
		end
	end

r.TrackList_AdjustWindows(true) -- isMinor true tcp only

	-- clear extended states
	for k, ext_state in ipairs{'track_props', 'children_muted', 'children_chain_bypassed'} do
	GetSet(tr, 'P_EXT:'..ext_state, '', true)
	end

end



-- used in UNFREEZE_AND_RESTORE_PROPS()
function Get_And_Delete_Frozen_File(tr, file_path)

	local function get_file(take)
	local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed source and source sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
	src = r.GetMediaSourceParent(src) or src
	return r.GetMediaSourceFileName(src, '')
	end

	if tr then
	local item = r.GetTrackMediaItem(tr,0)
	local frozen_take = item and r.GetActiveTake(item)
	local ret, chunk = GetObjChunk(item)
		if frozen_take and chunk:match('FREEZE %d+ [%d%.]+ %d+') then -- frozen item
		local file = get_file(frozen_take)
		-- ensure that no other take uses the same freeze src file, just in case
			for i=0, r.CountMediaItems(0)-1 do
			local item = r.GetMediaItem(0,i)
				for i=0, r.CountTakes(item)-1 do
				local take = r.GetTake(item, i)
					if take ~= frozen_take then -- excluding the actual frozen take from the evaluation
					local file2 = get_file(take)
						if file2 == file then return end -- one suffices
					end
				end
			end
		return file -- src doesn't have to be resturned for destruction with PCM_Source_Destroy() because once frozen item is removed the src becomes invalid
		end
	elseif file_path then
	os.remove(r.GetPeakFileName(file_path, '')) -- delete peaks file //  using function in case peak files are set to be stored in a separate directory // deleting before the original file because for non-existing files the GetPeakFileName() function returns alternative path specified in Preferences -> Paths -> Store all peak caches... even if not ticked and where the peak file may not exist, so it'll be left behind at its original path
	os.remove(file_path)
--	r.PCM_Source_Destroy(src) -- doesn't need deletion because once frozen item is removed the src becomes invalid
	end
end




function UNFREEZE_AND_RESTORE_PROPS(unfreeze_completely)

local delete = DELETE_FROZEN_FILE_AFTER_UNFREEZNG:match('%S')

local t = {}
	for i=0, r.CountSelectedTracks(0)-1 do
	t[#t+1] = r.GetSelectedTrack(0, i)
	end

	for k, tr in ipairs(t) do
	r.SetOnlyTrackSelected(tr)
	local freeze_cnt = Is_Track_Frozen(tr)
		if freeze_cnt > 0 then -- frozen track, ignore non-frozen selected tracks
		freeze_cnt = unfreeze_completely and freeze_cnt or 1
			for i=1, freeze_cnt do
			local file
				if delete then
				file = Get_And_Delete_Frozen_File(tr)
				end
			r.Main_OnCommand(41644, 0) -- Track: Unfreeze tracks (restore previously saved items and FX)
				if delete and file then
				Get_And_Delete_Frozen_File(nil, file) -- tr is nil to trigger file deletion
				end
			end
			if Is_Track_Frozen(tr) == 0 then -- only restore settings if track has been fully unfrozen, i.e. no frozen data are remaining, in case track was frozen multiple times
			Restore_Track_Props(tr)
			end
		end
	end

-- restore track selection
	for k, tr in ipairs(t) do
	r.SetTrackSelected(tr, true) -- selected true
	end

end




function Extract_Frozen_FX_Chain(tr)

local ret, chunk = GetObjChunk(tr) -- this track is selected by design, in case the chunk must be extracted from temp track template
	if ret == 'err_mess' then return ret end

-- get frozen item GUID
local ret, GUID = r.GetSetMediaItemInfo_String(r.GetTrackMediaItem(tr, 0), 'GUID', '', false) -- is_set false
local chunk = chunk:match('(.+)<ITEM.-IGUID '..Esc(GUID)) -- cut off the frozen item chunk from the chunk data

-- extract freeze chunks
local t, freeze_cnt = {}, 0
	for line in chunk:gmatch('[^\n\r]+') do
		if line and line:match('<FREEZE') then
		freeze_cnt = freeze_cnt+1
		t[freeze_cnt] = {} -- initialize new nested table for a chunk
		table.insert(t[freeze_cnt], line) -- store first line of freeze chunk
		elseif freeze_cnt > 0 then
		table.insert(t[freeze_cnt], line) -- store subsequent lines of current freeze chunk
		end
	end


-- extract fx chain chunks from freeze chunks, fx containers are automatically included
local chain_cnt = 0
	for k, freeze_chunk in ipairs(t) do
	local fx_chain, take_chain, take_chains_t, counter, item = '', '', {}, 0
		for k, line in ipairs(freeze_chunk) do
			if line:match('<ITEM') then item = 1 end
			if line:match('<TAKEFX') or #take_chain > 0 then
			counter = counter + (line:match('%s*<') and 1 or line:match('%s*>') and -1 or 0)
			take_chain = take_chain..(#take_chain > 0 and '\n' or '')..line
				if counter == 0 then -- end of take fx chain chunk, store into table
				take_chains_t[#take_chains_t+1] = take_chain
				take_chain = '' -- reset for the next take, if any
				end
			elseif (line:match('<FXCHAIN') or #fx_chain > 0) and not item then -- excluding item chunk from the freeze chunk
			fx_chain = fx_chain..(#fx_chain > 0 and '\n' or '')..line
			end
		end
	-- replace nested table containing freeze chunk lines with fx chain chunk string
	-- and only if track fx chain chunk contains fx, i.e. BYPASS attribute is present
	-- because freeze chunks can contain empty fx chain chunks
	-- OR take chunks contain fx;
	-- if no take fx chains, unpacking take_chains_t will produce nils
	-- effectively making the stored nested table length 1
	fx_chain = fx_chain:match('\nBYPASS %d') and fx_chain or ''
	t[k] = (#fx_chain > 0 or #take_chains_t > 0) and {fx_chain, table.unpack(take_chains_t)} or false
	local per_freeze_count = t[k] and (#t[k][1] > 0 and 1 or 0) + #t[k]-1 -- adding track fx chain entry to take fx chain entries separately because one can be present without the other
	chain_cnt = chain_cnt + (per_freeze_count or 0)
	end

-- concatenate and display a menu if more than a single frozen fx chain
local menu_itm_count, output = 0
	if chain_cnt > 1 then -- valid chain chunk count is greater than 1 which warrants a menu
	local menu = ''
		for k, chunks_t in ipairs(t) do

			if chunks_t then -- may be false if no fx in the freeze chunks

			-- submenu track chain item
			local track_chain_item = #chunks_t > 1 and #chunks_t[1] > 0 and 'Track FX||' or '' -- track and take chains

			-- submenu take chain items
			local i = 0
			local take_chain_items = #chunks_t > 2 -- track and multiple take fx chains or only take fx chains
			and ('Take  FX|'):rep(#chunks_t-1):gsub('Take',
			function(c) i=i+1 return (i == #chunks_t-1 and '<' or '')..c..' '..math.floor(i) end) -- adding number to take fx chain menu item and closing the submenu at the last item
			or #chunks_t == 2 and #chunks_t[1] > 0 and '<Take FX|' -- single take fx chain which accompanies track fx chain

			-- single either track or take chain item without submenu, unless take_chain_items is valid
			local frozen_chain_item = take_chain_items and '>Freeze '..k..'  FX chains|'
			or 'Freeze '..k..'  '..(#chunks_t == 1 and 'track'
			or #chunks_t == 2 and #chunks_t[1] == 0 and 'take')..'  FX chain|'

			local menu_item = take_chain_items and frozen_chain_item..track_chain_item..take_chain_items
			or frozen_chain_item

			menu = menu..(#menu > 0 and v and '|' or '')..menu_item

			menu_itm_count = menu_itm_count + #chunks_t - (#track_chain_item == 0 and 1 or 0) -- count overall menu length to be able to calculate correct take fx chain index for the track label of extracted fx chain, because chunks table t isn't flat and addressing the field matching the clicked menu item by simply passing menu output value as index won't work

			end
		end

	output = gfx.showmenu(menu..'||BACK')
		if output == 0 or output > chain_cnt then return output end -- menu exited

	end

-- remove false entries, i.e. with no nested table containing fx chain chunks
-- due to absense of fx data in them
	local function cleanup(t)
		for i=#t,1,-1 do -- looping in ascending order works too
			if not t[i] then table.remove(t,i)
			return cleanup(t)
			end
		end
	return t
	end


t = cleanup(t)

-- move each fx chain chunk to a separate table field, i.e. flatten the table
-- so it can be addressed with the menu output index,
-- the resulting table indexing will match fx chain chunk menu item indices;
-- and concatenate label for the track of extracted fx chain
local chain_type_info = #t > 0 and ('Freeze '..(#t[1][1] > 0 and 'track' or t[1][2] and 'take')..' FX chain') -- concatenate extracted fx chain track label as if there's a single frozen fx chain only, if there're several the var will be overwritten in the following loop
local freeze_idx = #t+1 -- #t+1 to conform to the reverse looping
menu_itm_count = menu_itm_count+1 -- +1 to conform to the reverse looping
	for i=#t,1,-1 do -- in reverse in case the table is going to lengthen
	freeze_idx = freeze_idx-1
	local chains = t[i] -- chains nested table
		for ii=#chains, 1, -1 do -- in reverse to ensure that the entries are inserted in ascending order with table.insert bacause they're inserted under the same index
		local fx_chain = chains[ii]
		menu_itm_count = menu_itm_count - ((ii > 1 or #fx_chain > 0) and 1 or 0) -- count to keep track of the fx chain table global (or final) length whose indices will match menu output indices // only account for track fx chain entry (index 1) if not empty
			if menu_itm_count == output then -- entry which matches menu output index
			local take_idx = (#chains == 2 or ii-1 == 0) and '' or ' '..ii-1 -- omit take index if there's only one // take index is 0 when there's only take fx chain in the nested table
			chain_type_info = 'Freeze '..freeze_idx.. ' '..(fx_chain:match('<FXCHAIN') and 'track' or 'take'..take_idx)..' FX chain' -- ii-1 because take fx chain entries start from index 2, index 1 is occupied by track fx chain entry
			end
		local fx_chain = fx_chain:gsub('<TAKEFX', '<FXCHAIN') -- replace section header otherwise it will be rejected when applied to track
			if #chains > 1 then -- moving several chain entries
				if #fx_chain > 0 then -- excluding empty track fx chain entry, take fx chain entries cannot be empty, they're either valid or non-existent
					if ii == #chains then -- if last nested table entry, re-use the index in the main table to prevent creation of redundant fields left over from the old structure, which would be the case with using table.insert right away
					t[i] = fx_chain
					else
					table.insert(t, i, fx_chain)
					end
				end
			else -- moving the only fx chain entry
			t[i] = fx_chain
			end
		end
	end


return output and t[output] or t[1], chain_type_info -- return fx chunk, either selected by the user from the menu or the only one, may be nil if no fx have been frozen so not found in the freeze chunks

end




function Apply_FX_Chain_Chunk(tr, fx_chain_chunk)
-- fx_chain_chunk stems from Extract_Frozen_FX_Chain()

	if not tr then return end

-- OR USE custom SetObjChunk()
local SetChunk = tr and r.SetTrackStateChunk or item and r.SetItemStateChunk
local retval, chunk = GetObjChunk(tr)

	if not retval then Err_mess() end

local merged = chunk:match('(.+)>')..fx_chain_chunk..'\n>' -- works without trailing closure too

SetChunk(tr, merged, false) -- isundo false

return true

end





TRACK_ICON_PATH = TRACK_ICON_PATH:match('%S') and Process_File_Path(TRACK_ICON_PATH)
or not TRACK_ICON_PATH:match('%S') and ''
FROZEN_ITEM_IMAGE_PATH = FROZEN_ITEM_IMAGE_PATH:match('%S') and Process_File_Path(FROZEN_ITEM_IMAGE_PATH)
or not FROZEN_ITEM_IMAGE_PATH:match('%S') and ''
TRACK_COLOR = TRACK_COLOR:match('%S') and Validate_HEX_Color_Setting(TRACK_COLOR)
or not TRACK_COLOR:match('%S') and ''
local err = ' path seems invalid'
err = not TRACK_ICON_PATH and 'track icon'..err or not FROZEN_ITEM_IMAGE_PATH and 'item image'..err
or #TRACK_ICON_PATH > 0 and not valid_image_extension(TRACK_ICON_PATH) and 'invalid track icon extension'
or #FROZEN_ITEM_IMAGE_PATH > 0 and not valid_image_extension(FROZEN_ITEM_IMAGE_PATH) and 'invalid item image extension'
or not TRACK_COLOR and '\t  frozen track \n\n color format is invalid'
or TCP_LAYOUT_NAME:match('%S') and not find_layout(TCP_LAYOUT_NAME) and '\t   the specified \n\n tcp layout wasn\'t found'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local scr_name = scr_path:match('[^\\/]+_(.+)%.%w+') -- without path, scripter name & ext

local sett_t = {TRACK_ICON_PATH, FROZEN_ITEM_IMAGE_PATH, TRACK_COLOR, TRACK_LABEL_PREFIX, TCP_LAYOUT_NAME, LOCK_TRACK_CONTROLS, MINIMIZE_TCP_AND_LOCK_HEIGHT, KEEP_ITEM_NAME_AFTER_FREEZING, DELETE_FROZEN_FILE_AFTER_UNFREEZNG, BYPASS_DESCENDANT_TRACK_FX, MUTE_DESCENDANT_TRACKS, COLLAPSE_DESCENDANT_TRACKS, UP_TO_SELECTED_FX, UP_TO_LAST_UNBYPASSED_AND_ONLINE_FX}

local dot = ' \226\128\162' -- Bullet U+2022 •


::RELOAD::

local sett_menu_t = {
-- settings with dialogue
-- space before dot to prevent underscore from reaching it
access_key('1 . Track icon path', '1'),
access_key('2 . Frozen item icon path','2'),
access_key('3 . Track color', '3'),
access_key('4 . Track label prefix', '4'),
access_key('5 . TCP layout name', '5'),
-- boolean settings
access_key('6 . Lock track controls', '6'),
access_key('7 . Minimize TCP and lock height','7'),
access_key('8 . Keep item name after freezing','8'),
access_key('9 . Delete frozen file after unfreezing','9'),
access_key('10. Bypass descendant track FX', 'B'),
access_key('11. Mute descendant tracks', 'M'),
access_key('12. Collapse descendant tracks', 'C')
}


-- add indicators to non-boolean settings and checkmark enabled boolean settings
	for i=1, #sett_menu_t do
	local sett = sett_menu_t[i]
	local active = sett_t[i]:match('%S')
		if i < 6 and active then
		sett_menu_t[i] = sett..' '..dot
		else
		sett_menu_t[i] = (i == #sett_menu_t and '<' or '')..(active and '!' or '')..sett
		end
		if i == 5 then sett_menu_t[i] = sett_menu_t[i]..'|' end -- add a separator after 'TCP layout name' to create a visible separator between boolean and other settings
	end

local sel_tr_cnt = r.CountSelectedTracks(0)
local no_sel = sel_tr_cnt == 0
local single_frozen_tr = sel_tr_cnt == 1 and Is_Track_Frozen(r.GetSelectedTrack(0,0)) > 0 or sel_tr_cnt > 1
local sett_menu = '>'..('SETTING'):gsub('.', '%0 ')..'S|'..table.concat(sett_menu_t,'|')..'|'
-- space before dot to prevent underscore from reaching it
local act_menu = check(#sett_t[13] > 0)..access_key('1 . Up to selected FX||', '1')
..check(#sett_t[14] > 0)..access_key('2 . Up to last unbypassed and online FX|||', '2')
-- the following 5 items are only active when there're selected tracks
..check(nil, no_sel)..access_key('3 . To mono||','3')
..check(nil, no_sel)..access_key('4 . To stereo||','4')
..check(nil, no_sel)..access_key('5 . To multichannel|||','5')
..check(nil, no_sel or not single_frozen_tr)..access_key('6 . Unfreeze||','6')
..check(nil, no_sel or not single_frozen_tr)..access_key('7 . Unfreeze completely|||','7')
-- the following 2 items are only active when exactly 1 track is selected and it's frozen
..check(nil, not single_frozen_tr)..access_key('8 . Toggle show freeze details||','8')
..check(nil, not single_frozen_tr)..access_key('9 . Extract frozen FX chain to a new track','9')


local output = Reload_Menu_at_Same_Pos(sett_menu..'|'..act_menu, 1) -- keep_menu_open true

	if output == 0 then -- obviates usage of > 0 in subsequent conditions
	elseif output < 6 then -- non-boolean settings
	local sett = sett_t[output]
	sett_t[output] = Sett_Dialogue(output < 3 and sett, output == 3 and sett, output == 4 and sett, output == 5 and sett)
	elseif output < 15 then -- boolean settings
		if output == 9 and not sett_t[output]:match('%S') then -- delete frozen file
			if r.MB('Deletion of the frozen file will result\n\n'
			..space(9)..'in a missing media source\n\n'..space(11)..'if unfreezing is undone.', 'WARNING', 1) == 1 then
			sett_t[output] = '1'
			end
		else
		sett_t[output] = sett_t[output]:match('%S') and '' or '1' -- toggle
			-- mutually exclusive, but can be toggled individially
			if output == 13 and sett_t[output]== '1' then sett_t[14] = ''
			elseif output == 14 and sett_t[output]== '1' then sett_t[13] = ''
			end
		end
	elseif output == 20 then -- show freeze details
	r.Main_OnCommand(41654, 0) -- View: Show track freeze details
	elseif output == 21 then -- extract and apply frozen fx chain to a new track inserted immediately above the only selected one
	local sel_tr = r.GetSelectedTrack(0,0)
	local fx_chain_chunk, chain_type_info = Extract_Frozen_FX_Chain(sel_tr)
		if fx_chain_chunk == 'err_mess' then -- track chunk couldn't be retrieved
		Err_mess()
		output = 0 -- reset so that the menu doesn't reload
		elseif not fx_chain_chunk then
		Error_Tooltip('\n\n no frozen fx \n\n', 1, 1, 0, -200) -- caps, spaced true, x2 0, y2 -200 because it's the last menu item, mouse will be placed fairly low and the tooltip will be displayed too low
		pause(1.5) -- make the tooltip stick so that it's not immediately obscured by the reloaded menu
		elseif not tonumber(fx_chain_chunk) then -- fx chain chunk string, fx_chain_chunk var can be integer if the fx chain menu was exited
		r.Undo_BeginBlock()
		local idx = r.CSurf_TrackToID(sel_tr, false) -- mcp_view false
		r.InsertTrackAtIndex(idx-1, false) -- wantDefaults false to prevent auto-added default fx chain if any // insert above selected track
		local tr = r.GetTrack(0, idx-1)
		local retval = Apply_FX_Chain_Chunk(tr, fx_chain_chunk) -- recFX ommitted, nil
			if not retval then -- newly inserted track chunk couldn't be retrieved, delete inserted track // unlikely scenario because the track is empty so chunk size is tiny
			r.DeleteTrack(tr)
			end
		r.GetSetMediaTrackInfo_String(tr, 'P_NAME', chain_type_info, true) -- is_set true
		local obj = chain_type_info:match('track') or 'take'
		r.Undo_EndBlock('Extract frozen '..obj..' FX chain to new track', -1)
		output = 0 -- reset so that menu doesn't reload
		end
	else -- (un)freeze
	TRACK_ICON_PATH, FROZEN_ITEM_IMAGE_PATH, TRACK_COLOR, TRACK_LABEL_PREFIX, TCP_LAYOUT_NAME, LOCK_TRACK_CONTROLS, MINIMIZE_TCP_AND_LOCK_HEIGHT, KEEP_ITEM_NAME_AFTER_FREEZING, DELETE_FROZEN_FILE_AFTER_UNFREEZNG, BYPASS_DESCENDANT_TRACK_FX, MUTE_DESCENDANT_TRACKS, COLLAPSE_DESCENDANT_TRACKS, UP_TO_SELECTED_FX, UP_TO_LAST_UNBYPASSED_AND_ONLINE_FX = table.unpack(sett_t)
	TRACK_COLOR = #TRACK_COLOR > 0 and hex_col2int(TRACK_COLOR:gsub('#', '')) or '' -- convert to integer compatible with ReaScript API functions
	local mono, stereo, mutlichan = output == 15, output == 16, output == 17
	local actID = mono and 40901 -- Track: Freeze to mono (render pre-fader, save/remove items and online FX)
	or stereo and 41223 -- Track: Freeze to stereo (render pre-fader, save/remove items and online FX)
	or mutlichan and 40877 -- Track: Freeze to multichannel (render pre-fader, save/remove items and online FX)
	local undo

		if actID then -- freeze

		-- the selected tracks table construction and evaluation of existence
		-- of tracks eligible for freezing has to be done simultaneously
		-- to prevent repeated execution of Items_Exist_On_Descendant_Tracks()
		-- and Active_Audio_Receives_Exist() once for eligibility evaluation
		-- before FREEZE__STORE_PROPS_AND_APPLY_SETTINGS() function and again
		-- for storage of props of the eligible tracks only;
		-- both could have also been done inside the function in which case
		-- Undo_BeginBlock() would have to be called inside it as well because
		-- the evaluation result wouldn't be available outside of it
		local sel_trks_t, valid_track = {}
			for i=0, r.CountSelectedTracks(0)-1 do
			local tr = r.GetSelectedTrack(0,i)
			local to_freeze = r.CountTrackMediaItems(tr) > 0 or Items_Exist_On_Descendant_Tracks(tr) or Active_Audio_Receives_Exist(tr)
			valid_track = valid_track or to_freeze
				if to_freeze then -- only store props of selected tracks where there's something to freeze
				Store_Track_Props(tr)
				end
			sel_trks_t[#sel_trks_t+1] = {tr=tr, to_freeze=to_freeze} -- storing ALL selected tracks, indcluding those where there's nothing to freeze (and which will be excluded from the freeze loop) to be able to restore their selection when eligible tracks have been frozen
			end

			if not valid_track then
			Error_Tooltip('\n\n no audio to freeze \n\n', 1, 1) -- caps, spaced true
			output = 0 -- reset so that menu doesn't reload // not aborting script here to allow settings update if they were changed immediately prior to freezing attempt, hence the following 'else' keyword
			else
			local up_to_selected, last_unbypassed_online = UP_TO_SELECTED_FX:match('%S'),
			UP_TO_LAST_UNBYPASSED_AND_ONLINE_FX:match('%S')
			r.Undo_BeginBlock()
			local valid_tracks_cnt, failed_tr_t = FREEZE__STORE_PROPS_AND_APPLY_SETTINGS(sel_trks_t, actID, up_to_selected, last_unbypassed_online)

			local up_to_sel_failed = #failed_tr_t == valid_tracks_cnt
				if #failed_tr_t > 0 then
				r.MB('Freezing of the following tracks:\n\n'..table.concat(failed_tr_t, ', ')..'\n\nfailed due to inability\n\nto accurately determine\n\nthe last selected FX', up_to_sel_failed and 'ERROR' or 'INFO', 0)
				end

			-- even if freeze up to selected FX fails in all tracks, undo point is still created
			-- because the tracks do get frozen, just with all fx rather than some
			undo = 'Freeze selected tracks to '..(mono and 'mono' or stereo and 'stereo' or multichan and 'multichannel')
			..(up_to_selected and not up_to_sel_failed and ' up to selected FX'
			or last_unbypassed_online and ' up to last active FX' or '')..' (enhanced)'

			end

		else -- unfreeze

		local frozen_exists
			for i=0, r.CountSelectedTracks(0)-1 do
				if Is_Track_Frozen(r.GetSelectedTrack(0,i)) > 0 then frozen_exists = 1 break end
			end

			if not frozen_exists then
			Error_Tooltip('\n\n no selected frozen tracks \n\n', 1, 1) -- caps, spaced true
			output = 0 -- reset so that menu doesn't reload // not aborting script here to allow settings update if they were changed immediately prior to freezing attempt, hence the following 'else' keyword
			else
			r.Undo_BeginBlock()
			UNFREEZE_AND_RESTORE_PROPS(output == 19) -- unfreeze_completely depends on the menu item index
			undo = 'Unfreeze selected tracks'
			end

		end

		if output > 0 then -- when error, the output is set to 0 and Undo_BeginBlock isn't intitialized, so prevent the closing block when error
		r.Undo_EndBlock(undo, -1)
		end

	end

	if output ~= 0 then goto RELOAD end

-- on script exit
-- update script settings modified via the menu
local sett_sect, scr_sett_t = Get_Script_Settings_Section(scr_path)

-- update settings values retrieved from script with the values set via the menu
	for k, line in ipairs(scr_sett_t) do
		if k < 3 then
		line = line:match('.+=%s*%[%[')..sett_t[k]..']]' -- image file paths
		else
		line = line:match('.+=%s*"')..sett_t[k]..'"'
		end
	scr_sett_t[k] = line
	end

local updated_sect = sett_sect

-- update retrieved script settings section with new values
	for k, line in ipairs(scr_sett_t) do
	local sett_var = line:match('^(%s*[%u%w_]+%s*=)')
	line = line:gsub('%%', '%%%%')
	local cnt
	updated_sect = updated_sect:gsub(sett_var..'.-\n', line..'\n', 1)
	end


	if sett_sect ~= updated_sect then
	local f = io.open(scr_path,'r')
	local cont = f:read('*a')
	f:close()
	sett_sect = Esc(sett_sect)
	updated_sect = updated_sect:gsub('%%', '%%%%')
	cont = cont:gsub(sett_sect, updated_sect, 1)
	local f = io.open(scr_path,'w')
	f:write(cont)
	f:close()
	end

do r.defer(no_undo) end



