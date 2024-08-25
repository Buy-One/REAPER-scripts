--[[
ReaScript name: BuyOne_Transcribing - Generate Transcribing toolbar ReaperMenu file.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: #Fixed resources search while generating the toolbar code
	   #Disabled user prompt for the target toolbar number in builds newer than 7.21
Licence: WTFPL
REAPER: at least v5.962
About:	The script is part of the Transcribing workflow set of scripts
	alongside
	BuyOne_Transcribing - Create and manage segments.lua  
	BuyOne_Transcribing - Real time preview.lua  
	BuyOne_Transcribing - Format converter.lua  
	BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing - Prepare transcript for rendering.lua  
	BuyOne_Transcribing - Select Notes track based on marker at edit cursor.lua			

	The script generates a ReaperMenu file for a toolbar 
	to which all scripts and custom actions included in this 
	script set are linked, except this script. So that if
	the user would like have one they wouldn't have to create
	one from scratch.   
	After that the generated file named   
	'Transcribing workflow toolbar.ReaperMenu'  
	and placed in the MenuSets folder in the REAPER resource
	directory need to be imported into the Menu/Toolbar editor.
	
	While generating the user is prompted for the number of the 
	target toolbar because REAPER can only import menu sets for
	a specific toolbar. The toolbar number can be input from
	the keyboard while the prompt menu is open or by clicking
	the digits in the menu. To create the file hit T key on the
	keyboard or click the 'TOOLBAR #:' line in the menu. The 
	wrong input can be corrected with the < character.
	
	When the toolbar menu set file is generated for the first time
	the script also loads an image of the toolbar layout to help
	the user find their way around it provided such image was
	downloaded with the set of scripts.

]]


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


function GetSet_Track_Zoom_100_Perc(targ_tr)
-- track 100 zoom is the same as current Arrange height
-- 100% zoom depends on the bottom docker being open
-- which limits Arrange height

--[[INEFFICIENT
-- get 'Maximum vertical zoom' set at Preferences -> Editing behavior, which affects max track height set with 'View: Toggle track zoom to maximum height', introduced in build 6.76
local cont
	if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.76 then
	local f = io.open(r.get_ini_file(),'r')
	cont = f:read('*a')
	f:close()
	end

local max_zoom = cont and cont:match('maxvzoom=([%.%d]+)\n') -- min value is 0.125 (13%) which is roughly 1/8th, max is 8 (800%)
local max_zoom = not max_zoom and 100 or math.floor(max_zoom*100+0.5) -- ignore in builds prior to 6.76 by assigning 100 so that when track height is divided by 100 and multiplied by 100% nothing changes, otherwise convert to conventional percentage value; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is accurate, otherwise there's ±1 px diviation, because the actual track height in pixels isn't fractional like the one obtained through calculation therefore some part is lost
]]

local act = r.Main_OnCommand

local retval, max_zoom = r.get_config_var_string('maxvzoom')-- min value is 0.125 (13%) which is roughly 1/8th, max is 8 (800%)
max_zoom = retval and max_zoom*100 or 100 -- ignore in builds prior to 6.76 by assigning 100 so that when track height is divided by 100 and multiplied by 100% nothing changes, otherwise convert to conventional percentage value

-- Store track heights
local t = {}
	for i=0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	t[#t+1] = r.GetMediaTrackInfo_Value(tr, 'I_TCPH')
	end

local ref_tr = r.GetTrack(0,0) -- reference track (any) to scroll back to in order to restore scroll state after track heights restoration
local ref_tr_y = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPY')

-- Get the data
-- When the actions are applied the UI jolts, but PreventUIRefresh() is not suitable because it blocks the function GetMediaTrackInfo_Value() from getting the return value
-- toggle to minimum and to maximum height are mutually exclusive // selection isn't needed, all are toggled
act(40110, 0) -- View: Toggle track zoom to minimum height
act(40113, 0) -- View: Toggle track zoom to maximum height [in later builds comment '(limit to 100% of arrange view) has been added' and another action introduced to zoom to maxvzoom value]
------------------------------------
-- The following two lines only serve a few builds starting from 6.76
-- in which action 40113 was zooming in to maxvzoom value rather than 100%
local tr_h = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPH')/max_zoom*100 -- not including envelopes, action 40113 doesn't take envs into account; calculating track height as if it were zoomed out to the entire Arrange height by taking into account 'Maximum vertical zoom' setting at Preferences -> Editing behavior
local tr_h = math.floor(tr_h+0.5) -- round; if 100 can be divided by the percentage (max_zoom) value without remainder (such as 50, 25, 20) the resulting value is integer, otherwise the calculated Arrange height is fractional because the actual track height in pixels is integer which is not what it looks like after calculation based on percentage (max_zoom) value, which means the value is rounded in REAPER internally because pixels cannot be fractional and the result is ±1 px diviation compared to the Arrange height calculated at percentages by which 100 can be divided without remainder
------------------------------------

-- Restore track heights
	for k, height in ipairs(t) do
	local tr = r.GetTrack(0,k-1)
	r.SetMediaTrackInfo_Value(tr, 'I_HEIGHTOVERRIDE', height)
	end

	if targ_tr then -- set to 100% height
	r.SetMediaTrackInfo_Value(targ_tr, 'I_HEIGHTOVERRIDE', tr_h)
	r.SetOnlyTrackSelected(targ_tr)
	act(40913,0) -- Track: Vertical scroll selected tracks into view
	ref_tr = targ_tr
	ref_tr_y = 0
	end

r.TrackList_AdjustWindows(true) -- isMinor is true // updates TCP only https://forum.cockos.com/showthread.php?t=208275

-- Restore scroll position or scroll the zoomed-in targ_tr to top
r.PreventUIRefresh(1)
r.CSurf_OnScroll(0, -1000) -- scroll all the way up as a preliminary measure to simplify scroll pos restoration because in this case you only have to scroll in one direction so no need for extra conditions
local Y_init = 0
	repeat -- restore track scroll
	r.CSurf_OnScroll(0, 1) -- 1 vert scroll unit is 8 px
	local Y = r.GetMediaTrackInfo_Value(ref_tr, 'I_TCPY')
		if Y ~= Y_init then Y_init = Y else break end -- when the track list is scrolled all the way down and the script scrolls up the loop tends to become endless because for some reason the 1st track whose Y coord is used as a reference can't reach its original pos, this happens regardless of the preliminary scroll direction above, therefore exit loop if it's got stuck, i.e. Y value hasn't changed in the next cycle; this doesn't affect the actual scrolling result, tracks end up where they should // unlike track size value, track Y coordinate accessibility for monitoring isn't affected by PreventUIRefresh()
	until Y <= ref_tr_y
r.PreventUIRefresh(-1)

return tr_h

end



function Insert_Image()

local chunk = [[
<ITEM
POSITION 0
SNAPOFFS 0
LENGTH 8
LOOP 1
ALLTAKES 0
FADEIN 1 0 0 1 0 0 0
FADEOUT 1 0 0 1 0 0 0
MUTE 0 0
SEL 1
IGUID {3E42B32C-B52E-4644-A494-DFDBCFB163B9}
IID 1
RESOURCEFN "F:\Program Files\REAPER (x64)\Scripts\MY\my_Transcribing\Transcribing toolbar layout.png"
IMGRESOURCEFLAGS 5
NOTESWND 197 95 1198 659
>
]]

r.Undo_BeginBlock()
-- the function will faulter here if it's already used outside of the function
-- in which case scr_name will have to be passed as an argument
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local img_name = 'Transcribing toolbar layout.png'
local path = scr_name:match('.+[\\/]')..img_name
	if r.file_exists(path) then
	local GetSet = r.GetSetMediaTrackInfo_String
	local img_tr
	-- search for an empty file with the image inserted earler to prevent duplication on successive script runs
	-- when the toolbar file gets overwritten this function doesn't run
		for i=r.GetNumTracks()-1, 0, -1 do
		local tr = r.GetTrack(0,i)
		local ret, ext = GetSet(tr, 'P_EXT:'..img_name, '', false) -- setNewValue false
			if ret then
				for i=0,r.CountTrackMediaItems(tr)-1 do
				local item = r.GetTrackMediaItem(tr,i)
					if r.CountTakes(item) == 0 then -- OR not r.GetActiveTake(item) // empty items don't have takes
					local ret, chunk = r.GetItemStateChunk(item, '', false) -- isundo false
						if chunk:match('RESOURCEFN "'..Esc(path)..'"') then return end -- already exists
					end
				end
			img_tr = tr
			break end
		end
		if not img_tr then
		r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefault false
		img_tr = r.GetTrack(0,r.GetNumTracks()-1)
		end
	local item = r.AddMediaItemToTrack(img_tr)
	GetSet(img_tr, 'P_NAME', 'Transcribing toolbar layout', true) -- setNewValue true
	GetSet(img_tr, 'P_EXT:'..img_name, '1', true) -- setNewValue true
	chunk = chunk:gsub('RESOURCEFN.-\n', 'RESOURCEFN "'..path..'"\n')
	r.SetItemStateChunk(item, chunk, false) -- isundo false
	local st_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
	r.SetMediaItemInfo_Value(item, 'D_LENGTH', end_time)
		if r.GetCursorPosition() < end_time then -- prevent edit cursor crossing the image
		r.SetEditCurPos(0,true,false) -- moveview true, seekplay false
		end
	-- The image may end up being a bit cut off on the left if zoom level is not high enough
	-- but couldn't figure out a way to ensure the sweet spot of the zoom level, Set_Horiz_Zoom_Level() didn't help
	r.CSurf_OnScroll(-400,0) -- scroll horizontally left, 1 scroll unit is 16 px so scroll 6400 px which should be enough to reach the project start
	GetSet_Track_Zoom_100_Perc(img_tr)
	end
r.Undo_EndBlock('Insert Transcribing toolbar layout image', -1)

end


function Dir_Exists(path)
-- path is a directory path, not file
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = path:match('[\\/]')
	if not sep then return end -- likely not a string represening a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
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


local toolbar1 = [[
[Floating toolbar 2]
icon_0=text_wide
icon_1=text_wide
icon_2=text_wide
icon_3=text_wide
icon_4=text_wide
icon_5=text_wide
icon_6=text_wide
icon_7=text_wide
icon_8=text_wide
icon_9=text_wide
icon_10=text_wide
icon_11=text_wide
]]

local toolbar2 = [[
item_0= MAIN
item_1= Create loop
item_2=40634 Clear loop points
item_3= loop right >>
item_4= Loop to >> segment
item_5= Loop to << segment
item_6= Live PEVIEW
item_7= FORMAT
item_8= Go to Notes track
item_9= Go to segm marker
item_10= Prepare for rendering
item_11= Import SRT/VTT/TXT
]]

local ref_t = {'BuyOne_Transcribing - Create and manage segments',
'Create loop points between adjacent project markers',
'', -- line to match menu item item_2=40634 which doesn't need command ID update
'Transcribing - Shift loop right by the loop length',
'Transcribing - Move loop points to next segment',
'Transcribing - Move loop points to previous segment',
'BuyOne_Transcribing - Real time preview',
'BuyOne_Transcribing - Format converter',
'BuyOne_Transcribing - Select Notes track based on marker at edit cursor',
'BuyOne_Transcribing - Go to segment marker',
'BuyOne_Transcribing - Prepare transcript for rendering',
'BuyOne_Transcribing - Import SRT or VTT file as markers and SWS track Notes'
}


Error_Tooltip('\n\n analyzing the action list \n\n', 1,1) -- caps, spaced true

-- construct button links code table
local toolbar2_t = {}
	for line in toolbar2:gmatch('[^\n]+') do
		if line then
		toolbar2_t[#toolbar2_t+1] = line
		end
	end

-- update command IDs in the button link entries
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local author = scr_name:match('.+[\\/](.-)_')
local sep = r.GetResourcePath():match('[\\/]')
local path = r.GetResourcePath()..sep
local cntr = 0

	for line in io.lines(path..'reaper-kb.ini') do -- parse action list contents
		for k, item in ipairs(ref_t) do
		local item = Esc(item)
			if k ~= 3 -- ignoring 40634 Clear loop points menu item which is 3d item and doesn't require command ID update
			and (line:match(item..'%.lua') -- script
			or not line:match(author..'_.-%.lua') and line:match(item)) -- custom action
			then
			local cmdID = line:match('%u+ %d+ %d+ "?(.-)"? ') -- script command IDs aren't enclosed within quotes
			toolbar2_t[k] = toolbar2_t[k]:gsub('=', '=_'..cmdID)
			cntr = cntr+1
			break end
		end
		if cntr == 11 then break end -- all entries have been found
	end

local absent = ''
	for k, item in ipairs(toolbar2_t) do
		if k ~= 3 and not item:match('=_') then -- command ID wasn't added in the loop above
		absent = absent..'\n'..ref_t[k]
		end
	end

Error_Tooltip('') -- clear the 'analyzing' tooltip, because it sticks for some excessive time

function space(int) return (' '):rep(int) end

	if cntr < 11 then -- or #absent > 0
	r.MB('Not all toolbar resources were found in the action list.\n\n'
	..space(14)..'Be sure to import there all scripts AND\n\n"Transcribing workflow custom actions.ReaperKeyMap"\n\n\t'
	..space(11)..'file included in the set.\n\nMissing resources:\n'..absent, 'ERROR', 0)
	return r.defer(no_undo) end


local build = tonumber(r.GetAppVersion():match('[%d%.]+')) 
local tb_No

	if build < 7.22 then -- since build 7.22 numbers of the source and target toolbars don't have to match at import of .ReaperMenu file so no need to prompt user for the number on order to update it in the code

	::RELOAD::

	local shade = ('▓'):rep(23)
	local digits = {'1','2','3','4','5','6','7','8','9','0','<'}
	local menu = {'&1','&2','&3','4','5','&6','&7','8','9','0','&< (backspace)'} -- ampersand only at certain digits to disambiguate because these appear in the menu title earlier
	line = line or ''
	--Msg(line)
	menu = shade..'|ON THE KEYBOARD TYPE THE NUMBER|'..space(7)..'OF THE TOOLBAR TO IMPORT|'
	..space(9)..'THE ReaperMenu FILE INTO|'..space(6)..'(1 — 16 or 1 — 32 in REAPER 7)|'
	..space(12)..'AND HIT THE " T " KEY|'..shade..'|'..table.concat(menu,'|')
	..'||&'..('toolbar'):upper():gsub('.','%0 ')..'#: '..line..'||'
	local output = Reload_Menu_at_Same_Pos(menu, true) -- keep_menu_open true, left_edge_dist false

		if output == 0 then return r.defer(no_undo)
		elseif output < 7 then goto RELOAD -- title lines
		end

		if output > 7 and output < 19 then
		output = output-7 -- offset by the number of title lines
		local input = digits[output]
		line = line..input
		line = input == '<' and line:sub(1,-3) or line
		goto RELOAD
		elseif output == 19 then
		tb_No = line:match('%d+')
		tb_No = tonumber(tb_No)
		local reaper7 = build >= 7
		local err = not tb_No and '   toolbar number \n\n hasn\'t been typed in'
		or (tb_No == 0 or reaper7 and tb_No > 32 or not reaper7 and tb_No > 16) and 'invalid toolbar number'
			if err then
			Error_Tooltip('\n\n '..err..' \n\n', 1,1, -400) -- caps, spaced true, x2 -400 to move the tooltip away from the menu otherwie it gets covered by it when the menu is reloaded
			goto RELOAD
			end
		end
		
	end

-- use MenuSets folder as a more reliable and stable location, scripts folder can be overwritten,
-- placing in the project folder doesn't make sense since the file isn't project specific
local reamenu_path = path..'MenuSets'..sep..'Transcribe workflow toolbar.ReaperMenu'
local exists

	if r.file_exists(reamenu_path) then
	exists = 1
		if r.MB('File "Transcribe workflow toolbar.ReaperMenu"'
		..'\n\n     already exists in the "MenuSets" folder.\n\n\t     Wish to overwrite it?',
		'PROMPT', 4) == 7 then -- No
		return r.defer(no_undo) end
	end

toolbar1 = build >= 7.22 and toolbar1 or toolbar1:gsub('Floating toolbar %d+', 'Floating toolbar '..tb_No)
local toolbar = toolbar1..table.concat(toolbar2_t,'\n')
	if not exists and not Dir_Exists(reamenu_path:match('.+[\\/]')) then -- create MenuSets folder if absent
	r.RecursiveCreateDirectory(reamenu_path:match('.+[\\/]'), 1) -- ignored 1 whose meaning isn't clear
	end
local f = io.open(reamenu_path,'w')
f:write(toolbar)
f:close()
local insert_img = not exists and Insert_Image() -- only when generating the ReaperMenu file for the first time
local result = exists and 'updated' or 'created'
local go = r.MB('A file named "Transcribe workflow toolbar.ReaperMenu"\n\n'
..space(10)..'has been '..result..' in the "MenuSets" folder\n\n\t'
..space(5)..'of REAPER resource directory\n\n'
..space(14)..'Import it into the Menu/toolbar editor.\n\n'
..space(10)..'Wish to open the resource directory now?','PROMPT',4) == 6
and r.Main_OnCommand(40027,0) -- Show REAPER resource path in explorer


do return r.defer(no_undo) end



