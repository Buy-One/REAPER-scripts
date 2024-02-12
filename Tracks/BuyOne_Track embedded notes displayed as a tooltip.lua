--[[
ReaScript name: BuyOne_Track embedded notes displayed as a tooltip.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.2
Changelog: 
	  v1.2 #Fixed logic of TCP detection under mouse
	  v1.1 #Added support for TCP on the right side of the Arrange
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
About: 	##MANAGING TRACK NOTES

	1. Arm the script. The easiest way is to link it
	to a toolbar button and right click the button. 
	It will change its color. Now when the mouse cursor 
	is over the Arrange canvas its pointer is displayed 
	as the letter 'A' (for armed). This is the edit mode.
	Be reminded that since arming is exclusive, any other
	armed action/script will be unarmed.

	2. Either hover the mouse cursor over the TCP
	of a track to write notes for and execute a shortcut
	the script has been bound to, or simply select the track
	and click anywehere within the Arrange, a notes track 
	and item will be created under the target track. 
	The notes item will be inserted on a new track under
	the target track spanning the entire project length so
	it can be accessed from anywhere in the project.  
	If the track already has notes stored they will
	be displayed inside the notes item.  

	3. Type in your notes in the notes item notes window
	or remove the existing notes if you wish to delete them.

	4. To save notes click Apply (the notes window will 
	remain open) or OK (the notes window will close).

	5. Click anywhere within the Arrange to exit the edit
	mode and store the notes inside the track. 
	If the same track remains the target (selected or pointed
	at with the mouse cursor) the edit mode will be exited.  
	If there's nothing to store because there's no change in 
	the notes, the edit mode will remain active. Leading and
	trailing spaces and line breaks aren't considered new 
	content and are ignored.  
	The edit mode will also remain active if at this moment 
	another track is targeted as decribed in the step 2, in
	which case the edit mode will apply to such other track.  
	In either case the notes track and item for the last target
	track will be deleted.  
	This stores the notes for the current session. To keep 
	the stored notes inside the track permanently the project 
	must be saved.  
	The notes are only stored while the edit mode is active.

	To exit the edit mode without storing notes click the 
	armed toolbar button the script is linked to, to unarm it. 
	In this case the notes track and item won't be deleted.  
	They will be deleted the next time track notes are viewed 
	unless you delete them manually. !!! Therefore notes track 
	and item should not be used for any other purpose because 
	they will be eventually deleted by the script.


	##VIEWING TRACK NOTES

	When the script is not in the edit mode (the toolbar 
	button is not lit) either hover the mouse cursor over 
	the TCP of a track to view the notes for and execute 
	a shortcut the script has been bound to, or simply 
	select the track and click either the toolbar button 
	or a menu item the script is linked to.  

	To display the notes the script uses menu interface, not
	a traditional tooltip.

	---

	The advantage if this script over SWS/S&M extension track 
	notes utility is that it stores notes in a way which makes 
	them accessible from track templates, if that's important.  
	The script can also convert them into the format supported 
	by it.

	##CAVEATS

	The script doesn't support ampersand sign (&). If it
	is used in the notes it will be converved into +, because
	plus is often used synonynously with 'and' denoted by
	ampersand.

	---

	The script only creates undo point when notes track and item
	are inserted.

	See also USER SETTINGS.		
]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings (bar the last) 
-- insert any alphanumeric character between the quotes.

-- if enabled the notes will be displayed
-- in ReaScript console rather than a tooltip,
-- will have to be closed manually
DISPLAY_IN_CONSOLE = ""

-- By defauilt when notes have been stored
-- and no new track has been selected
-- the edit mode is automatically exited,
-- enable this setting to be able to remain
-- in the edit mode by assenting to the prompt
PROMPT_TO_CONTINUE_EDITING = ""

-- To notes the script adds a time stamp,
-- which is only displayed in the tooltip,
-- the following settings allow to modify
-- the time stamp slightly

-- MMDDYYYY
US_DATE_ORDER = ""

-- XX AM/PM
_12_HOUR_FORMAT = ""

-- Enable to allow the script to look for
-- and display stored SWS/S&M extension track notes
-- when the track does not contain notes stored
-- with the script;
-- !!! since via a script the most recent edition
-- of SWS/S&M notes can only be accessed
-- once the project has been saved,
-- before viewing them save the project,
-- if not saved a warning will be added to the tooltip,
-- these will be displayed without time stamp;
-- if SWS/S&M track notes are viewed in the edit mode
-- they can be edited and stored inside the track
-- which is not the location used by the SWS/S&M extension notes utility;
ACCESS_SWS_TRACK_NOTES = ""

-- Any character or a combination thereof
-- to prefix the track name with to indicate that
-- the track has embedded notes, e.g. 'tag MY TRACK NAME'
-- for this to work correctly space must be maintained 
-- between the tag and the track name,
-- the tag itself doesn't suppport spaces;
-- will be removed if notes are deleted
-- unless the NOTES_TAG has been changed or disabled 
-- in the interim in which case the script will not find it
-- in the track name unless it was updated manually,
-- and a new tag will be added on top of the old one
-- to names of tracks with existing notes
NOTES_TAG = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function validate_sett(sett) -- validate setting, can be either a non-empty string or any number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function multibyte_str_len(str)
-- https://stackoverflow.com/questions/43125333/lua-string-length-cyrillic-in-utf8
-- https://stackoverflow.com/questions/22129516/string-sub-issue-with-non-english-characters
-- https://www.splitbrain.org/blog/2020-09/03-regexp_to_match_multibyte_character
-- https://stackoverflow.com/questions/9356169/utf-8-continuation-bytes
-- https://www.freecodecamp.org/news/what-is-utf-8-character-encoding/
-- count string length in characters regardless of the number of bytes they're represented by
-- Lua string library counts bytes, and UTF-8 characters produce inaccurate count because they're multi-byte, consisting also of leading (leader) bytes (192-254) and continuation (trailing) bytes (128-191), the continuation bytes must be discarded so only the basic ASCII (0-127) remain
return #str:gsub('[\128-\191]','') -- OR #str:gsub('[\x80-\xbf]','') -- same in HEX
end



function format_time(US_order, _12_hour, Isr_date, Roman_month, dot) -- all booleans
-- US_order - month first
-- _12_hour - 12 hour cycle + AM/PM
-- Isr_date - zeros in day and month are discared
-- Roman_month - Roman month number delimited with slash
-- Isr_date and Roman_month are only relevant if US_order is false
-- dot instead of slash, incompatible with Roman_month, the latter has priority
local d = US_order and '%m/%d' or '%d/%m' -- month first
local t = _12_hour and '%I' or '%H'
local period = t == '%I' and (os.date('%H')+0 < 12 and ' AM' or ' PM') or ''
local date = os.date(d..'/%Y '..t..':%M'..period)
	local function roman(str)
	local t = {'I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'}
	return '/'..t[tonumber(str:match('%d+'))]..' '
	end
	local function isr(str)
		if str:match('0%d/0%d') then return str:gsub('0','')
		elseif str:match('0%d/%d+') then return str:match('%d(%d/%d+/)') -- or str:sub(2)
		elseif str:match('%d+/0%d') then return str:gsub('/0', '/')
		end
	end
-- local date = '02/01/2023 15:29' -- TESTING
local date = not US_order and
(Roman_month and date:gsub('/%d+/', roman) or Isr_date and date:gsub('%d+/%d+/', isr))
or date
local date = not Roman_month and dot and date:gsub('/','.') or date
return date
end


function Error_Tooltip(text, caps, spaced) -- caps and spaced are booleans
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
r.TrackCtl_SetToolTip(text, x+50, y-10, true) -- topmost true
--[[
-- a time loop can be added to run when certan condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Get_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
local tcp_under_mouse = r.GetCursorPosition() == edge or r.GetCursorPosition() == start_time -- if the TCP is on the right and the Arrange is scrolled all the way to the project start start_time-5 won't make the edit cursor move past project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local new_curs_pos = r.GetCursorPosition()
local min_val, subtr_val = table.unpack(new_curs_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_curs_pos ~= edge and {curs_pos, new_curs_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
]]
--  OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end


-- used within Insert_Empty_Item_To_Display_Text()
function Re_Store_Selected_Objects(t1,t2) -- when storing the arguments aren't needed

r.PreventUIRefresh(1)

local t1, t2 = t1, t2

	if not t1 then
	-- Store selected items
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
		if sel_itms_cnt > 0 then
		t1 = {}
		local i = sel_itms_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local item = r.GetSelectedMediaItem(0,i)
			t1[#t1+1] = item
		--	r.SetMediaItemSelected(item, false) -- selected false; deselect item // OPTIONAL
			i = i - 1
			end
		end
	elseif t1 and #t1 > 0 then -- Restore selected items
--	r.Main_OnCommand(40289,0) -- Item: Unselect all items
--	OR
	r.SelectAllMediaItems(0, false) -- selected false
		for _, item in ipairs(t1) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	r.UpdateArrange()
	end

	if not t2 then
	-- Store selected tracks
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
		if sel_trk_cnt > 0 then
		t2 = {}
		local i = sel_trk_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local tr = r.GetSelectedTrack2(0,i,true) -- plus Master, wantmaster true
		--	r.SetTrackSelected(tr, false) -- selected false; deselect track // OPTIONAL
			t2[#t2+1] = tr
			i = i - 1
			end
		end
	elseif t2 and #t2 > 0 then -- restore selected tracks
--	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetOnlyTrackSelected(t2[1]) -- select one to be restored while deselecting all the rest
	r.SetTrackSelected(r.GetMasterTrack(0), false) -- unselect Master
	-- OR
	-- r.SetOnlyTrackSelected(t2[1])
		for _, tr in ipairs(t2) do
		r.SetTrackSelected(tr, true) -- selected true
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	end

r.PreventUIRefresh(-1)

return t1, t2

end


function FindAndDelete_Existing_Notes_TrackAndItem()
	for i = r.CountMediaItems(0)-1, 0, -1 do
	local item = r.GetMediaItem(0,i)
	local ret, data = r.GetSetMediaItemInfo_String(item, 'P_EXT:NOTES_ITEM', '', false) -- setNewValue false
		if ret then
		local notes_tr = r.GetMediaItemTrack(item)
		local ret, data = r.GetSetMediaTrackInfo_String(notes_tr, 'P_EXT:NOTES_TRACK', '', false) -- setNewValue false
			if ret then r.DeleteTrack(notes_tr)
			else
			r.DeleteTrackMediaItem(notes_tr, item)
			end
		end
	end
	for i = r.CountTracks(0)-1, 0, -1 do -- delete empty notes tracks
	local tr = r.GetTrack(0,i)
		if r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NOTES_TRACK', '', false) -- setNewValue false
		then
		r.DeleteTrack(tr)
		end
	end
end



function Load_SWS_Track_Notes(tr)
local retval, projfn = r.EnumProjects(-1) -- -1 current project
local tr_GUID = r.GetTrackGUID(tr)
local last_save_time
local notes = ''
local found
	for line in io.lines(projfn) do
		if line:match('REAPER_PROJECT') then last_save_time = line:match('.+ (%d+)') end -- the integer represents Unix time at the moment the project was last saved https://www.askjf.com/index.php?q=6650s
	local line = line:match('%s*(.+)') -- trimming leading space and line breaks; OR '.-([%w%p].*)'
		if line:match('S&M_TRACKNOTES') then
		local GUID = line:match('.+ ({.+})')
			if GUID == tr_GUID then found = 1 end
		elseif found and line:match('^>') then -- notes section closure, must be the 1st character on the line, because in the body of the comment the 1st one is pipe
		break
		elseif found then
		notes = notes..(#notes == 0 and '' or '\r\n ')..line:sub(2) -- each line of S&M notes is preceded by a pipe, line break was trimmed with space above, so excluding the pipe and re-adding line break statring from line 2; space after line break is necessary when multiple line breaks occur to prevent creation of solid dividers during convertion into menu, so that each line with or without text is converted into a menu item; carriage return is for correct display in the item notes window because it doesn't recognize line breaks alone https://forum.cockos.com/showthread.php?t=214861#2
		end
	end

local notes = notes:match('[%w%p].+[%w%p]') -- trimming leading/trailing spaces and line breaks
-- add warning if there's a gap of more than 20 sec since project last save time
local notes = os.time() - last_save_time > 20 and notes..'\n\nThis may be not the most recent SWS notes edition!' or notes

return notes

end


function Insert_Empty_Item_To_Display_Text(tr) -- tr is the target track whose notes are to be edited
-- relies on Re_Store_Selected_Objects(); for the item notes to recognize line breaks in the output they must be replaced with '\r\n' if the string wasn't previously formatted in the notes field https://forum.cockos.com/showthread.php?t=214861#2

local tr_GUID = r.GetTrackGUID(tr)
local retval, tr_name = r.GetTrackName(tr)
local ret, notes = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NOTES', '', false)
local notes = not ret and ACCESS_SWS_TRACK_NOTES and Load_SWS_Track_Notes(tr):gsub('\n\n','\r\n\r\n') or notes -- load SWS track notes if no notes and the setting is enabled, adding carriage retun char to the notes edition warning divider, if any, for correct display in the item notes window
local notes = notes:match('([\0-\255]+)\n \n%d+') or notes -- exlude date if there're stored notes

local sel_itms_t, sel_trk_t = Re_Store_Selected_Objects() -- store
local cur_pos = r.GetCursorPosition() -- store

-- Insert notes track and configure
local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
local tr_idx = tr_idx == 0 and 0 or tr_idx -- CSurf_TrackToID returns idx 0 for the master track and 1-based idx for the rest
r.InsertTrackAtIndex(tr_idx, false) -- wantDefaults false
local notes_tr = r.CSurf_TrackFromID(tr_idx+1, false) -- mcpView false
r.GetSetMediaTrackInfo_String(notes_tr, 'P_NAME', 'Track '..tr_idx..' notes', true) -- setNewValue true
r.GetSetMediaTrackInfo_String(notes_tr, 'P_EXT:NOTES_TRACK', '+', true) -- setNewValue true // add extended data to be able to find the track later if left undeleted

-- Insert notes item and configure
r.SetEditCurPos(-3600, false, false) -- moveview seekplay false // move to -3600 or -1 hour mark in case project time start is negative, will surely move cursor to the very project start to reveal the notes item // thanks to moveview false the notes item will be accessible from anywehere in the project since its length will be set to full project length below
local notes_item = r.AddMediaItemToTrack(notes_tr)
r.SetMediaItemSelected(notes_item, true) -- selected true // to be able to open notes with action
local proj_len = r.GetProjectLength(0)
r.SetMediaItemInfo_Value(notes_item, 'D_LENGTH', proj_len == 0 and 5 or proj_len) -- set notes item length to full project length if there're time line objects, if there's none and so proj length is 0 then set to 5 sec
r.AddTakeToMediaItem(notes_item) -- creates a quasi-MIDI item so label can be added to it since label (P_NAME) is a take property // the item is affected by actions 'SWS/BR: Add envelope points...', 'SWS/BR: Insert 2 envelope points...' and 'SWS/BR: Insert envelope points on grid...' when applied to the Tempo envelope which cause creation of stretch markers in the item
r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(notes_item), 'P_NAME', 'track "'..tr_name..'"', true) -- setNewValue true // add label to the notes item
r.GetSetMediaItemInfo_String(notes_item, 'P_NOTES', notes, true) -- setNewValue true // load notes
r.GetSetMediaItemInfo_String(notes_item, 'P_EXT:NOTES_ITEM', tr_GUID, true) -- setNewValue true // add extended data to be able to find the item later if left undeleted and to find the target track to store the notes to
-- Open the empty item notes
r.Main_OnCommand(40850,0) -- Item: Show notes for items...

Re_Store_Selected_Objects(sel_itms_t, sel_trk_t) -- restore originally selected objects
r.SetEditCurPos(-3600, true, false) -- moveview true, seekplay false // move to -3600 or -1 hour mark in case project time because the Arrange view may move when the item is inserted in case Preferences -> Editing behavior -> Move edit cursor when pasing/insering media is enabled
r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false; restore position

end


function Store_Notes(tr)
-- search for the notes item
	for i = r.CountMediaItems(0)-1, 0, -1 do
	local item = r.GetMediaItem(0,i)
	local ret, targ_tr_GUID = r.GetSetMediaItemInfo_String(item, 'P_EXT:NOTES_ITEM', '', false) -- setNewValue false
		if ret then
		local ret, notes = r.GetSetMediaItemInfo_String(item, 'P_NOTES', '', false) -- setNewValue false // ret is always true in this case
		-- first search for the target track assuming it's not been moved and is still sitting above the notes track
		local notes_tr = r.GetMediaItemTrack(item)
		local target_tr_idx = r.CSurf_TrackToID(notes_tr, false)-2 -- mcpView false
		local target_tr = r.CSurf_TrackFromID(target_tr_idx, false) or r.GetMasterTrack(0) -- mcpView false
			if r.GetTrackGUID(target_tr) ~= targ_tr_GUID then -- if displaced, search through the entire track list
				for i = -1, r.CountTracks(0)-1 do -- i = -1 to accommodate master track
				local track = r.GetTrack(0,i) or r.GetMasterTrack(0)
					if r.GetTrackGUID(track) == targ_tr_GUID then target_tr = track break end
				end
			end

		-- store notes as extended data
		local ret, old_notes = r.GetSetMediaTrackInfo_String(target_tr, 'P_EXT:NOTES', '', false) -- setNewValue false
		local old_notes = old_notes:match('(.+)\n \n%d+') or old_notes -- excluding date
		local notes = notes:match('.-([\128-\255%w%p].+[\128-\255%w%p])') or '' -- trimming leading / trailing space and line breaks, accounting for utf-8 characters and ignoring leading / trailing space in evaluation of the difference between old and current notes
			if old_notes ~= notes then -- covers all, adding, changing and deleting notes
			
			local date = format_time(US_DATE_ORDER, _12_HOUR_FORMAT, Isr_date, Roman_month, dot)
			local notes = notes and #notes > 0 and notes..'\n \n'..date or '' -- only adding date when not deleting notes
			r.GetSetMediaTrackInfo_String(target_tr, 'P_EXT:NOTES', notes, true) -- setNewValue true // store notes
			
			-- Managing notes tag in the track name
			local ret, target_tr_name = r.GetSetMediaTrackInfo_String(target_tr, 'P_NAME', '', false) -- setNewValue false
				if NOTES_TAG then
				local name_tagged = target_tr_name:match('^'..Esc(NOTES_TAG))
					if #notes > 0 and not name_tagged then -- add notes tag when adding or changing notes
					target_tr_name = NOTES_TAG..' '..target_tr_name
					elseif #notes == 0 and name_tagged then -- remove notes tag when deleting notes
					target_tr_name = target_tr_name:match('^'..Esc(NOTES_TAG)..'%s+(.+)') or '' -- exclude tag accounting for nameless tracks and for variable length of space between the tag and the name // string:sub() isn't suitable because a user may use multi-byte characters whose length isn't accurately counted with #string
					end
				r.GetSetMediaTrackInfo_String(target_tr, 'P_NAME', target_tr_name, true) -- setNewValue true
				end
			
			local same_track = r.GetTrackGUID(tr) == targ_tr_GUID
			local resp = same_track and PROMPT_TO_CONTINUE_EDITING and r.MB('   The notes have been stored\n\nWish to remain in the edit mode?', 'PROMPT', 4)
			local exit_edit_mode = resp == 7 or not resp -- response is No or the setting not enabled

				if exit_edit_mode then -- delete notes track and item
					if r.GetSetMediaTrackInfo_String(notes_tr, 'P_EXT:NOTES_TRACK', '', false) -- setNewValue false
					then -- if the track the notes item is sitting on is the original notes track, delete it
					r.DeleteTrack(notes_tr)
					else -- otherwise only delete the item
					r.DeleteTrackMediaItem(notes_tr, item)
					end
				end

				if same_track then -- target track hasn't changed
					if exit_edit_mode then r.Main_OnCommand(2020,0) end -- Action: Disarm action
				return -- notes item will not be (re-)created with Insert_Empty_Item_To_Display_Text() for the current target track, whenre exiting or keepin edit mode
				else return true -- will trigger notes item (re-)creaton with Insert_Empty_Item_To_Display_Text() for new target track when there's a notes item open for the last target track, at this point the notes item and track for the last track will have been deleted above
				end
			-- notes haven't changed
			else
				if r.GetTrackGUID(tr) == targ_tr_GUID then return -- if track is the same do not trigger Insert_Empty_Item_To_Display_Text() function because new notes item isn't needed
				else -- if track is different, delete current notes track and item
					if r.GetSetMediaTrackInfo_String(notes_tr, 'P_EXT:NOTES_TRACK', '', false) -- setNewValue false
					then -- if the track the notes item is sitting on is the original notes track, delete it
					r.DeleteTrack(notes_tr)
					else -- otherwise only delete the item
					r.DeleteTrackMediaItem(notes_tr, item)
					end
				return true -- trigger notes item creaton with Insert_Empty_Item_To_Display_Text() for the new target track
				end
			end
		end
	end
return true -- will trigger notes item (re-)creaton with Insert_Empty_Item_To_Display_Text() for current target track when there's no notes item
end


function Convert_Text_To_Menu(notes)

local notes, stat = notes:gsub('|', 'ㅣ') -- replace pipe, if any, with Hangul character for /i/ since its a menu special character
local notes, stat = notes:gsub('&', '+') -- convert ampersand to + because it's a menu special character used as a quick access shortuct hence not displayed in the menu
local notes, stat = notes:gsub('\n', '|') -- OR notes:gsub('\r', '|') // convert user line breaks into pipes to divide lines by creating menu items, otherwise user line breaks aren't respected; multiple line break is created thanks to the space between pipes originally left after each \n character, if there's none a solid line is displayed instead or several thereof starting from 3 pipes and more

local t = {}
	for w in notes:gmatch('[%w%p\128-\255]+[%s%p]*') do -- split into words + trailing space if any; [%w%p] makes sure that words with apostrophe <it's>, <don't> aren't split up; [%s%p] makes menu divider pipes and special characters (!#<>), if any, attached to the words bevause they're punctuation marks (%p); accounting for utf-8 characters
		if w then
		t[#t+1] = w end
	end

local notes, menu = '',''
	for k, w in ipairs(t) do
	local notes_clean = (notes..w):gsub('|','') -- doesn't seem to make a difference with or without the pipe
		if multibyte_str_len(notes_clean) > 70 or notes:match('(.+)|') then -- dump notes var to menu var and reset notes, if not dumped immediately when the notes var ends with line break then when notes var will exceed the length limit containing a user line break, hanging words will appear after such line break because they will now be included in the menu var and next time length of notes var will be evaluated without them, e.g.:
		-- | notes = 'The generated Lorem Ipsum is therefore | always' -- assuming the string exceeds the length limit, 'always' will be left hanging ...
		-- | menu = menu..'The generated Lorem Ipsum is therefore | always'..pipe -- line break is created after 'always' with pipe var, next time notes var will be added after the pipe, so the result will look like:
		-- | 'The generated Lorem Ipsum is therefore
		-- | always
		-- | free from repetition, injected humor
		-- whereas 'always' has to be grouped with 'free from repetition, injected humor'
		local pipe = notes:match('(.+)|') and '' or '|' -- when the above condition is true because notes end with pipe the pipe is user's line break so no need to add another one, otherwise when condition is true because the line length exceeds the limit pipe is added to delimit lines as menu items
		notes = #pipe == 0 and notes:gsub('[!#<>]',' %0') or notes -- make sure that menu special characters at the beginning of a new line (menu item) are ignored prefacing them with space; when string stored in the notes var has pipe in the end, if ther're any menu special characters in the user notes, they will follow the pipe due to the way user notes are split into words at the beginning of the function, so if there're any specal characters placed at the beginning of a new line in the user notes they will necessarily be found in the notes var right next to the new line character converted at the beginning of the function into pipe to conform to the menu syntax and such new line character is attached to the preceding line
		menu = menu..notes..pipe -- between menu and notes pipe isn't needed because it's added after the notes and next time will be at the end of the menu
		notes = ''
		end
		if k == #t then
		menu = ' |'..menu..notes..w..'| |' -- add padding
		else
		w = w:match('%d+/%d+/%d+') and k == #t-1 and '|'..w or w -- add divider before the time stamp; the date is stored in the penultimate index hence #t-1, the time is in the very last, the time stamp is split into two separate words
		notes = notes..w
		end
	end

return menu

end


DISPLAY_IN_CONSOLE = validate_sett(DISPLAY_IN_CONSOLE)
PROMPT_TO_CONTINUE_EDITING = validate_sett(PROMPT_TO_CONTINUE_EDITING)
US_DATE_ORDER = validate_sett(US_DATE_ORDER)
_12_HOUR_FORMAT = validate_sett(_12_HOUR_FORMAT)
ACCESS_SWS_TRACK_NOTES = validate_sett(ACCESS_SWS_TRACK_NOTES)
NOTES_TAG = NOTES_TAG:gsub(' ','')
local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID)


local comm_ID, sect = r.GetArmedCommand()
local scr_armed = comm_ID == cmd_ID
local x, y = r.GetMousePosition()
local tr = Get_TCP_Under_Mouse() or r.GetSelectedTrack2(0,0, true) -- wantmaster true
local notes_tr = tr and r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NOTES_TRACK', '', false) -- setNewValue false


local err = not tr and 'no track under mouse or selected' or notes_tr and 'notes track cannot be used'

	if err then
		if not scr_armed and notes_tr then
		r.DeleteTrack(tr) -- notes track which has been left behind after edit mode was exited
		else
		Error_Tooltip('\n\n'..err..'\n\n', true, true) -- caps, spaced true
		end
	return r.defer(no_undo)
	elseif tr and scr_armed then
	r.PreventUIRefresh(1) -- wrapping the entire routine with these causes delay in deletion of notes item/track while the notes are displayed in the next condition below
		if Store_Notes(tr) then
		r.Undo_BeginBlock()
		Insert_Empty_Item_To_Display_Text(tr)
		r.Undo_EndBlock('Insert notes track and item', -1)
		end
	r.PreventUIRefresh(-1)
	elseif tr then
	FindAndDelete_Existing_Notes_TrackAndItem()
	local ret, notes = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:NOTES', '', false) -- setNewValue false
	local notes = not ret and ACCESS_SWS_TRACK_NOTES and Load_SWS_Track_Notes(tr) or notes
	local notes = notes:gsub(' ','') == '' and ('\n   NO TRACK NOTES  \n'):gsub('.', '%0 ') or notes -- for defer loop (if used) notes must be global
		if DISPLAY_IN_CONSOLE then
		r.ShowConsoleMsg(notes:match('^%s*(.+)'), r.ClearConsole())-- removing leading space from 'no track notes' message
		else
			if notes == ('\n   NO TRACK NOTES  \n'):gsub('.', '%0 ') then
			Error_Tooltip(' \n'..notes..'\n ') -- caps, spaced false
			local time = r.time_precise()
				repeat
				until r.time_precise() - time > 1
			else
			local notes = Convert_Text_To_Menu(notes)
			-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
			-- https://forum.cockos.com/showthread.php?t=280658#25
			-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
				if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82 then gfx.init('', 0, 0) end
			gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
			gfx.showmenu(notes)
			gfx.quit()
			end
		end
	end



do return r.defer(no_undo) end




