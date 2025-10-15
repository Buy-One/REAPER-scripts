--[[
ReaScript name: BuyOne_Transcribing B - Prepare transcript for rendering.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: 1.1 #Included a version of the stock 'Overlay: Text/Timecode' preset in which
				each line of a multi-line caption is centered independently
				#Added support for this version in a caption with shadow
				#Simplified OVERLAY_PRESET default setting
				#Updated 'About' text
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing B workflow set of scripts
		alongside
		BuyOne_Transcribing B - Create and manage segments (MAIN).lua  
		BuyOne_Transcribing B - Real time preview.lua  
		BuyOne_Transcribing B - Format converter.lua  
		BuyOne_Transcribing B - Import SRT or VTT file as regions.lua  
		BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
		BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
		BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua  
		BuyOne_Transcribing B - Replace text in the transcript.lua
		
		Its purpose is to allow embedding transcript in a video file or
		audio file.
		
		V I D E O
		
		If VIDEO option is chosen by the user in the pop-up menu the script
		creates a new track named as specified in the RENDER_TRACK_NAME
		setting and inserts on it items with Video processor plugin 
		at regions which correspond to segments and having segment 
		transcript included in their take names in order to display 
		the transcript within video context.  
		The script deletes from the project all segment regions with no
		transcript to only insert items for segments with text. Existing 
		markers and non-segment regions are left intact.  
		New line tag <n> supported by this set of scripts is converted into
		a new line character which is recognized by 'Overlay: Text/Timecode' 
		preset of the Video processor.
		
		The said render track must be placed above the track with the 
		video item.  

		When the items are created they become locked so in order to manually
		delete them they must be unlocked first. Or the render track itself
		can be deleted without unlocking the items beforehand.  
		
		Once set up the video can be rendered out as normal.
		
		A U D I O
		
		If AUDIO option is selected the script deletes from the project all 
		markers and segment regions, and then creates markers taking their 
		positions from original segment regions. Non-segment regions are 
		left intact.
		
		The transcript of each segment is added to the corresponding marker
		name. All new line tags <n> supported by this set of scripts and 
		all other formatting markup supported by the SRT or VTT formats is 
		cleared.  
		If 'With chapter tags' option is enabled before opting for AUDIO
		option, in each created marker the transcript will be preceded with
		'CHAP' tag and will be recognized as a chapter by media players which 
		support it. To have chapter tags embedded in the file the output format
		must be mp3, flac, ogg or opus and 'Add new metadata' option must be 
		enabled in the Render window.  
		To embed the segment markers with the transcript inside files in formats 
		which don't support 'CHAP' tag such as wav, instead of enabling the 
		metadata select 'Markers only' option from the drop-down menu at the 
		bottom of the Render window. Adding chapter tag in this case is 
		unnecessary.
		
		The menu options can be triggered from keyboard by hitting the key
		which corresponds to the first character of the menu item.
		
		This script along with  
		'BuyOne_Transcribing B - Import SRT or VTT file as markers and SWS track Notes.lua'
		can be used to embed 3d party SRT/VTT subtitles in a video/audio 
		file.
		
		
		O V E R L A Y  P R E S E T

		By default the script implies usage of the stock
		'Overlay: Text/Timecode' preset to display transcript segments.  
		OVERLAY_PRESET setting in the USER SETTING below allows
		defining a custom overlay preset which the script will
		use.  
		The stock 'Overlay: Text/Timecode' preset does support
		multi-line captions but it centers the text as a single
		unit, so each line starts at the same X coordinate on the
		screen, i.e.
		My line
		My second line
		My line after the second

		To have lines centered individually use a mod of the 
		stock preset whose code is provided at the bottom of this
		script. Paste the code into the Video processor instance,
		hit Ctrl/Cmd + S to store it, save as a named preset
		and specify this preset name in the OVERLAY_PRESET 
		setting of the USER SETTINGS below. Alternatively import
		the preset dump file  
		'Overlay_Text-Timecode (centered multi-lines).RPL' 
		located in the script folder.  
		The resulting multi-line caption will look like so
		(the following may not display correctly within the 
		ReaScript IDE)
				 My line
			  My second line
		My line after the second
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes specify HEX color either preceded
-- or not with hash # sign, can consist of only 3 digits
-- if they're are repeated, i.e. #0fc;
-- MUST DIFFER FROM THE THEME DEFAULT REGION COLOR
-- AND MATCH THE SAME SETTING IN THE SCRIPT
-- 'BuyOne_Transcribing B - Create and manage segments (MAIN).lua'
SEGMENT_REGION_COLOR = "#b564a6"

-- Between the quotes insert the name of the track
-- on which items with segment trabscript will be inserted;
-- after the track is created it must be placed above the
-- track with the video item;
-- if the render track isn't found the script will
-- create it automatically
RENDER_TRACK_NAME = "RENDER"

-- If empty, the script will use the Video processor stock
-- "Overlay: Text/Timecode" preset to create transcript
-- preview in video context;
-- if you use a customized version of this preset, specify
-- its name in this setting between the quotes,
-- it's advised that the customized preset name be different
-- from the stock one, otherwise its settings may get
-- affected by the script
OVERLAY_PRESET = ""

-- Enable by inserting any alphanumeric character between
-- the quotes;
-- only relevant if OVERLAY_PRESET setting is the stock
-- "Overlay: Text/Timecode" preset or the one which supports
-- centered multi-lines and is named 
-- "Overlay: Text/Timecode (centered multi-lines)"
-- see 'OVERLAY PRESET' paragraph in the 'About' text 
-- in the script header
TEXT_WITH_SHADOW = ""

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
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end



function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return
	end
return c
end



function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
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
-- the earliest appearence of a particular character in the menu can be used as a shortcut
-- in this case they don't have to be preceded with ampersand '&'
-- only if particular instance of a character should be used as a shortcut
-- such character must be preceded with ampresand '&' otherwise it will be overriden
-- by its earliest appearance in the menu
-- some characters still do need ampresand, e.g. < and >

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



function Get_Transcript(reg_color, evaluate)
-- evaluate is boolean to only check if there're segment regions with transcript
-- at the preliminary error stage

	local function clear_markup(line)
	local t = {'a','b','i','u','v','font'}
		for _, tag in ipairs(t) do
			if tag == 'v' then -- VTT tag
			local speaker = line:match('<v (.-)>')
				if speaker then
				line = line:gsub('<v.->',speaker..': ')
				end
			elseif tag == 'a' then
			line = line:gsub('{\a%d+}','')
			else
			line = line:gsub('[<{]+/?'..tag..'.-[>}]','')
			end
		end
	return line
	end

local i, t = r.CountProjectMarkers(0)-1, {}
-- iterating in reverse due to possible deletion of empty segment regions
	repeat
	local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
		if retval > 0 and isrgn and color == reg_color then
			if #name:gsub('[%s%c]','') > 0 then
				if evaluate then return true
				else
				table.insert(t, 1, {pos=pos, fin=rgnend, transcr=clear_markup(name:match('^%s*(.-)%s*$'))}) -- stripping leading and trailing spaces // insert always at index 1 which will ensure storage in ascending order as if iterated forwards
				end
			elseif not evaluate then
			r.DeleteProjectMarkerByIndex(0, i)
			end
		end
	i = i-1
	until retval == 0

return not evaluate and t

end



function insert_new_track(tr_name)
r.InsertTrackAtIndex(r.CountTracks(0), true) -- wantDefaults true
local tr = r.GetTrack(0,r.CountTracks(0)-1)
r.GetSetMediaTrackInfo_String(tr, 'P_NAME', tr_name, true) -- setNewValue true
r.TrackList_AdjustWindows(false) -- isMinor false i.e. in both TCP and MCP, otherwise name isn't updated until the script has run through and if the track is up for deletion due to unavailability of overlay preset in video render preparation the name won't be displayed as long as the Message Box is shown
return tr
end


function Get_Track(name_setting)

	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
		if name:match('^%s*'..Esc(name_setting)..'%s*$') then
		return tr
		end
	end

-- insert if not found
return insert_new_track(name_setting)

end



function Remove_All_Segment_Regions_Or_Markers(reg_color, want_all)
-- they will be recreated based on the transcript in Insert_Items_At_Regions()
-- and Insert_Regions_For_Audio()
-- want_all is boolean to also delete all markers in preparation
-- for audio render so that irrelevant markers don't get embedded in the media

local i = r.CountProjectMarkers(0)-1
	repeat
	local retval, isrgn, pos, rgnend, name, markr_idx, color = r.EnumProjectMarkers3(0,i)
		if retval > 0 then
			if not want_all and isrgn and color == reg_color -- only segment regions
			or want_all and (isrgn and color == reg_color or not isrgn) -- -- only segment regions and all markers
			then
			r.DeleteProjectMarkerByIndex(0, i)
			end
		end
	i = i-1
	until retval == 0

end



function Insert_Items_At_Regions(rend_tr, reg_t, reg_color, OVERLAY_PRESET, TEXT_WITH_SHADOW)

	function insert_item(rend_tr, pos, len, transcr, OVERLAY_PRESET, TEXT_WITH_SHADOW)
--[[	these are only relevant if inserting with action
	r.SetOnlyTrackSelected(rend_tr)
	r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
]]
	local act = r.Main_OnCommand
	local item = r.GetTrackMediaItem(rend_tr,0) -- select 1st item on the track
	local take = item and r.GetActiveTake(item)
		if not item then -- if absent, create at edit cursor which has been moved to marker
	--[[ WORKS
		r.SetOnlyTrackSelected(rend_tr)
		--r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
		act(40214, 0) -- Insert new MIDI item...
		item = r.GetSelectedMediaItem(0,0) -- newly inserted item is exclusively selected
		take = r.GetActiveTake(item)
	]]
		-- ALTERNATIVE WHICH RESULTS IN ALL ITEM BUTTONS BEING HIDDEN EVEN IF ENABLED
		-- SPECIFICALLY LOCK AND FX, LOOKS TIDIER AND THE ITEMS CANNOT BE OPENED IN THE MIDI EDITOR
		-- WHEN CLICKED BEHAVE LIKE EMPTY ITEMS
		item = r.AddMediaItemToTrack(rend_tr)
		take = r.AddTakeToMediaItem(item)

		-- insert Video processor and apply preset
		r.TakeFX_AddByName(take, 'Video processor', -1000) -- instantiate -1000 first fx chain slot
		-- 'Overlay: Text/Timecode' preset doesn't work if applied via the API
		-- without opening the Video processor beforehand
		-- because the parameter values shift downwards between parameters
		-- while 'text height' param ends up at 0 so the text becomes invisible
		-- bug report https://forum.cockos.com/showthread.php?t=293212
		-- fixed in build 7.20
		local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.20
		local show = old and r.TakeFX_Show(take, 0, 3) -- showFlag 3 show floating window
		local ok = r.TakeFX_SetPreset(take, 0, OVERLAY_PRESET) -- fx 0

			if not ok then return end -- preset wasn't found
			-- only set parameters if the preset is stock or its multi-line version 
			-- because in the user's own version everything will be set within the preset itself
			local stock, multi_line = OVERLAY_PRESET == 'Overlay: Text/Timecode', OVERLAY_PRESET == 'Overlay: Text/Timecode (centered multi-lines)'
			if stock or multi_line then
				if TEXT_WITH_SHADOW then
				r.TakeFX_CopyToTake(take, 0, take, 1, false) -- ismove false // add another instance
				-- table for overlay version with shadow which requires two Video proc instances
				-- the shadow is provided by the 2nd instance
				-- only values different from the default 'Overlay: Text/Timecode' preset are included
				-- 1 - y pos, 2 - x pos, 4 - text bright, 5 - text alpha, 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
				local t = {[0] = {[6]=0, [7]=1, [8]=1}, [1] = {[1]=0.953, [2]=0.504, [4]=0.6, [5]=0.5, [6]=0, [7]=0}}
					for fx_idx, vals_t in pairs(t) do
						for parm_idx, val in pairs(vals_t) do
						r.TakeFX_SetParam(take, fx_idx, parm_idx, val)
						end
					end
				else
					for parm_idx, val in pairs({[6] = 0, [7] = 1, [8] = 1}) do -- 6 - bg bright, 7 - bg alpha, 8 - fit bg to text
					r.TakeFX_SetParam(take, 0, parm_idx, val)
					end
				end
			end

		local hide = old and r.TakeFX_Show(take, 0, 2) -- showFlag 2 hide floating window
		else -- if present, copy and paste at edit cursor which has been moved to marker
		r.SelectAllMediaItems(0, false) -- deselect all
		r.SetMediaItemSelected(item, true) -- selected true
		act(40698,0) -- Edit: Copy items
		act(42398,0) -- Item: Paste items/tracks // the item is pasted at the edit cursor but it's immaterial because its position and other properties will be adjusted in the loop below
		item = r.GetSelectedMediaItem(0,0) -- newly inserted item is exclusively selected action
		take = r.GetActiveTake(item)
		end

		for parm, val in pairs({D_POSITION=pos, D_LENGTH=len, B_LOOPSRC=0, C_LOCK=1}) do
		r.SetMediaItemInfo_Value(item, parm, val)
		end

	-- When new MIDI item is inserted either with action or the API
	-- (commented out above), its loop source setting is disabled
	-- and length is increased a visible notch is created in the
	-- item UI at the spot where the new loop iteration would start
	-- which spoils the optics, wiggling item edge with a mouse or
	-- toggling Item properties On/Off manually fixes this, but via
	-- API this doesn't work, hence actions must be applied;
	-- although the item length will change in real time to only
	-- last one segment (a space between two adjacent markers)
	-- the initial length is set to project length because when
	-- a shorter item is extented via the API it's affected with
	-- the same notch issue which doesn't occur when the longer item
	-- is shortened
	act(40636, 0) -- Item properties: Loop item source // re-sable
	act(40636, 0) -- Item properties: Loop item source // disnable
	r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', transcr:gsub('%s*<n>%s*','\n'), true) -- setNewValue true // converting new line tag into new line char
	return item -- if not reached this point, the overlay preset wasn't found
	end

	for k, reg in ipairs(reg_t) do
	r.SetOnlyTrackSelected(rend_tr) -- must be selected because with action items are pasted to the selected track
	local index = r.AddProjectMarker2(0, true, reg.pos, reg.fin, reg.transcr, -1, reg_color) -- isrgn true, wantidx -1 auto-assignment of index
	local item = insert_item(rend_tr, reg.pos, reg.fin-reg.pos, reg.transcr, OVERLAY_PRESET, TEXT_WITH_SHADOW)
		if not item then
		r.DeleteProjectMarker(0, index, true) -- isrgn true
			if r.CountTrackMediaItems(rend_tr) == 1 then
			r.DeleteTrack(rend_tr)
			else
			r.DeleteTrackMediaItem(r.GetMediaItemTrack(item), item)
			end
		return end
	end


r.SetEditCurPos(reg_t[1].pos, true, false) -- moveview true, seekplay false

return true -- if not reached this point, the overlay preset wasn't found

end



function Insert_Markers_For_Audio(reg_t, chapters, reg_color)

	for k, reg in ipairs(reg_t) do
	local transcr = (chapters and 'CHAP=' or '')..reg.transcr:match('^%s*(.-)%s*$'):gsub('%s*<n>%s*',' ') -- stripping trailing spaces, replacing new line tag and surrounding spaces with a single space
	r.AddProjectMarker2(0, false, reg.pos, 0, transcr, -1, reg_color) -- isrgn false, rgnend 0, wantidx -1 auto-assignment of index
	end

r.SetEditCurPos(reg_t[1].pos, true, false) -- moveview true, seekplay false

end



function space(str)
return str:gsub('.','%0 '):match('(.+) ')
end

REG_COLOR = Validate_HEX_Color_Setting(SEGMENT_REGION_COLOR)

local err = 'the segment_region_color \n\n'
err = #SEGMENT_REGION_COLOR:gsub(' ','') == 0 and err..'\t  setting is empty'
or not REG_COLOR and err..'\t setting is invalid'
or #RENDER_TRACK_NAME:gsub(' ','') == 0 and 'RENDER_TRACK_NAME \n\n   setting is empty'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local theme_reg_col = r.GetThemeColor('region', 0)
REG_COLOR = r.ColorToNative(table.unpack{hex2rgb(REG_COLOR)})

err = REG_COLOR == theme_reg_col and "the segment_region_color \n\n\tsetting is the same\n\n"
.."    as the theme's default\n\n     which isn't suitable\n\n\t   for the script"
or not Get_Transcript(REG_COLOR|0x1000000, 1) and 'no segment regions \n\n   with transcript' -- evaluate true

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


REG_COLOR = REG_COLOR|0x1000000 -- convert color to the native format returned by object functions
OVERLAY_PRESET = #OVERLAY_PRESET:gsub('[%s%c]','') > 0 and OVERLAY_PRESET or 'Overlay: Text/Timecode'
TEXT_WITH_SHADOW = (OVERLAY_PRESET == 'Overlay: Text/Timecode' or OVERLAY_PRESET == 'Overlay: Text/Timecode (centered multi-lines)') 
and #TEXT_WITH_SHADOW:gsub(' ','') > 0

::RELOAD::
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
local chapt_tags = r.GetExtState(named_ID, 'CHAPTERS')

local pad = ('▓'):rep(5)
function s(n) return (' '):rep(n) end
local menu = '|'..pad..space(' VIDEO ')..pad
..'|||'..pad..space(' AUDIO ')..pad
..'||'..chapt_tags..s(8)..'With chapter tags|'..s(7)..'(toggle, audio only)'
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true

	if output == 0 or output == 4 then return r.defer(no_undo) end

local video, audio = output == 1, output == 2

	if output == 3 then
	chapt_tags = #chapt_tags > 0 and '' or '!'
	r.SetExtState(named_ID, 'CHAPTERS', chapt_tags, false) -- persist false
	goto RELOAD
	end


Error_Tooltip("\n\n the process is underway... \n\n", 1, 1) -- caps, spaced true

	if video then

		if #OVERLAY_PRESET:gsub('[%s%c]','') == 0 then
		Error_Tooltip("\n\n overlay_preset setting is empty \n\n", 1, 1) -- caps, spaced true
		return r.defer(no_undo) end

	r.Undo_BeginBlock()

	local rend_tr = Get_Track(RENDER_TRACK_NAME)
	local itm_cnt = r.CountTrackMediaItems(rend_tr)

		if itm_cnt > 100 then
		local resp = r.MB(s(8)..'There\'re already '..itm_cnt..' items\n\n'..s(9)
		..'on the "'..RENDER_TRACK_NAME..'" track.'..'\n\n'..s(7)..'Wish to recreate them all?', 'PROMPT', 4)
			if resp == 7 then
			r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
			return r.defer(no_undo) end
		end

	local reg_t = Get_Transcript(REG_COLOR)
	Remove_All_Segment_Regions_Or_Markers(REG_COLOR) -- want_all is false

		r.PreventUIRefresh(1)

		if not Insert_Items_At_Regions(rend_tr, reg_t, REG_COLOR, OVERLAY_PRESET, TEXT_WITH_SHADOW) then
		r.MB('\tThe overlay preset\n\n"'..OVERLAY_PRESET..'" wasn\'t found', 'ERROR', 0)
		r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		return r.defer(no_undo) end

	r.SetOnlyTrackSelected(rend_tr)
	r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view

	r.PreventUIRefresh(-1)

	elseif audio then

	r.Undo_BeginBlock()

	local reg_t = Get_Transcript(REG_COLOR)
	Remove_All_Segment_Regions_Or_Markers(REG_COLOR, 1) -- want_all is true, delete all segment regions and all proj markers

	Insert_Markers_For_Audio(reg_t, #chapt_tags > 0, REG_COLOR)

	end

Error_Tooltip('')	-- undo the 'process underway' tooltip

r.Undo_EndBlock('Transcribing B: Prepare transcript for rendering', -1)


--[[ VIDEO PROCESSOR PRESET CODE

-------------------- COPY FROM NEXT LINE ---------------------
// Overlay: Text/Timecode (centered multi-lines)
// Mod of the stock preset to make multi-lines
// effected by new line character '\n', centered
// relative to each other instead of all being
// justified to the same x coordinate
// Example:
/*
Stock

    my line one
    my line one one
    my line one one one

This preset

        my line one
      my line one one
    my line one one one

*/
// To create visibly empty lines use space,
// genuinely empty lines aren't recognized



/////////////// CODE START ///////////////


// Insert your text if not fetched from
// track or take name
#text="";
// Font name can be changed, i.e.
// Times New Roman, Verdana, Courier New, Tahoma
font="Arial";


/////////////// MAIN CODE ///////////////

//@param1:size 'text height' 0.05 0.01 0.2 0.1 0.001
//@param2:ypos 'y position' 0.95 0 1 0.5 0.01
//@param3:xpos 'x position' 0.5 0 1 0.5 0.01
//@param4:border 'bg pad' 0.1 0 1 0.5 0.01
//@param5:fgc 'text bright' 1.0 0 1 0.5 0.01
//@param6:fga 'text alpha' 1.0 0 1 0.5 0.01
//@param7:bgc 'bg bright' 0.75 0 1 0.5 0.01
//@param8:bga 'bg alpha' 0.5 0 1 0.5 0.01
//@param9:bgfit 'fit bg to text' 0 0 1 0.5 1
//@param10:ignoreinput 'ignore input' 0 0 1 0.5 1

//@param12:tc 'show timecode' 0 0 1 0.5 1
//@param13:tcdf 'dropframe timecode' 0 0 1 0.5 1

input = ignoreinput ? -2:0;
project_wh_valid===0 ? input_info(input,project_w,project_h);
gfx_a2=0;
gfx_blit(input,1);
gfx_setfont(size*project_h,font);
tc>0.5 ? (
  t = floor((project_time + project_timeoffs) * framerate + 0.0000001);
  f = ceil(framerate);
  tcdf > 0.5 && f != framerate ? (
    period = floor(framerate * 600);
    ds = floor(framerate * 60);
    ds > 0 ? t += 18 * ((t / period)|0) + ((((t%period)-2)/ds)|0)*2;
  );
  sprintf(#text,"%02d:%02d:%02d:%02d",(t/(f*3600))|0,(t/(f*60))%60,(t/f)%60,t%f);
) : strcmp(#text,"")==0 ? input_get_name(-1,#text);


/////////////// MOD START ///////////////

function split_string_at_new_line_char(str)
(
  str_len = strlen(str); // store source string length
  count = 0;
  offset = 0;
  substr_len = 1;
  while(
    // Keep scanning and storing substring to memory address until \n comes along
    strcpy_substr(count, str, offset, substr_len);
    single_new_line_char = substr_len == 1 && match("\n", count);
    found = match("*\n", count); // operators + and +? work as well
      // If the substring sarts with a new line char
      // it immediately follows the preceding new line character
      // of the previous capture and will be included in the current capture
      // at its start, so skip it because it will throw off calculations
      single_new_line_char ? (
      offset += substr_len;
      substr_len = 0;
      ) :
      ( found || offset + substr_len == str_len) ? ( // \n is found in the substring or end of the source string
        // Strip trailing new line char from the substring if found, i.e. not if the end of the string,
        // resaving it at the same address
        trim = found ? substr_len-1 : substr_len;
        strcpy_substr(count, str, offset, trim);
        // Increment count to advance to next memory address for storage,
        // the value will also be used to iterate over them in a loop
        // to display the stored substrings
        count += 1;
        // Update offset to restart scanning from the last position
        offset += substr_len;
        // Reset to start the scanning from the 1st subtring byte,
        // will be incremented below
        substr_len = 0;
      );
    // Constantly increment by 1 to advance within the source string towards its end
    substr_len += 1;
    // Continue looping as long as this is true
    offset + substr_len <= str_len;
  );
  count;
);


function get_longest_str_idx(array_st, array_end)
// Couldn't make it work with while() loop
(
// First find the greatest length value
range = array_end-array_st;
i = array_st;
  loop(range,
  a = strlen(i);
  mx = max(a, mx);
  i+=1;
  );
// Now find the index of memory address
// where the longest string is stored
i = array_st;
  loop(range,
  // If string length happens to be equal to mx value, store its index
  // otherwise maintain ogirinal mx value
  mx = strlen(i) == mx ? i : mx;
  i+=1;
  );
  mx;
);

// Split the text, store substrings and get
// line count
count = split_string_at_new_line_char(#text);
// Get the longest line so that the backround
// is only shrunk with 'fit bg to text'
// as much as this line width allows
mx = get_longest_str_idx(0, count);
// Print the longest line
// to be able to get its dimensions
sprintf(#text,"%s",mx);
// Get the longest line width and height,
// height can be taken from any line
// because they're all affected by the same
// 'text height' parameter
gfx_str_measure(#text,txtw_mx,txth);
// Multiply line height by the number of lines
// to be used in background height calculation
// so that the background covers all
txth*=count;

// Calculate and draw background
// using the longest string width;
// this is the original code where txtw
// variable is substrituted with txtw_mx
b = (border*txth)|0;
yt = ((project_h - txth - b*2)*ypos)|0;
xp = (xpos * (project_w-txtw_mx))|0;
gfx_set(bgc,bgc,bgc,bga);
bga>0?gfx_fillrect(bgfit?xp-b:0, yt, bgfit?txtw_mx+b*2:project_w, txth+b*2);
gfx_set(fgc,fgc,fgc,fga);

// Draw text lines

i=count-1; // -1 because string address indexing starts from 0
y_offset = 0;

loop(count,

  sprintf(#text,"%s",i);
  gfx_str_measure(#text,txtw,txth);

  // Only calculate x coordinate for the longest line,
  // calculating the x coordinate for other lines
  // relative to it so that when lines are moved from the center
  // with 'x position' parameter, they remain centered
  // relative to each other;
  xp = (xpos * (project_w-txtw_mx))|0;
  x_offset = txtw !== txtw_mx ? (txtw_mx-txtw)/2;
  // OR
  // x_offset = i !== mx ? (txtw_mx-txtw)/2;

  gfx_str_draw(#text, xp+x_offset, yt+b+txth*(count-1)-y_offset);

  // Keep incrementing so that each next line
  // is drawn above the current one;
  // empty strings wouldn't affect the offset calculation
  // because their txth value is 0
  y_offset+=txth;
  // Iterating in reverse because y coordinate offsetting
  // must start from the bottommost line which is the line
  // last captured inside split_string_at_new_line_char()
  i-=1;
);
-------------------- COPY UNTIL THE PREVIOUS LINE ---------------------


]]



