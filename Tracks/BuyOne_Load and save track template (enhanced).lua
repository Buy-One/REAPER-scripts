--[[
ReaScript name: BuyOne_Load and save track template (enhanced).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.53
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The purpose of the script is to simplify saving track template,
	making it similar to saving project, i.e. without having to
	select a specific file at each save, as required by REAPER's 
	native action, and saving automatically last loaded file instead.

	Like with projects this workflow only makes sense if you work 
	on a relatively elaborate template which takes time and thus 
	invites periodic saves to ensure preservation of the latest 
	changes.

	LOADING

	Track templates must be loaded with this script so that
	it stores the path of the last loaded template and is able
	to fulfill its purpose which is re-saving a template without
	having to each time select the destination file as required
	by REAPER's native action 
	'Track: Save tracks as track template...'

	Before any template was loaded during the current REAPER
	session the script is pointed to /TrackTempalates folder 
	at REAPER's resource path unless a different one has been 
	configured with 
	ALTERNATIVE_TRACK_TEMPLATE_PATH setting in the USER SETTINGS.

	The script keeps track of the path of the last loaded 
	template and uses it for loading the next template and 
	re-saving the last loaded.

	To load a template submit the dialogue with the 'File name'
	field empty. If you wish to load a template without certain
	resource types (envelopes, items, hidden tracks), enable
	'Exclude resources when loading' option in the dialogue to
	call a sub-dialogue where options pertaining to loading
	are avaliable.

	Track template is inserted after the last selected track
	and if no track is selected - after the last track. That's 
	unlike REAPER native action which inserts a template after 
	the last touched track whether selected or not which may not 
	always be obvious although edit cursor indicator can help 
	if enabled.

	SAVING

	Before any template was loaded the save destination path is
	/TrackTempalates folder at REAPER's resource path, unless 
	a different one has been configured with 
	ALTERNATIVE_TRACK_TEMPLATE_PATH setting in the USER SETTINGS.

	In order to save a template before any template is loaded
	in the current REAPER session, type the template name in the
	'File name' field, configure settings and click OK. The template
	will be saved at the default destination path. To save at a 
	different location in this scenario follow the steps described 
	in the last paragraph of this section.

	Once a template has been loaded, the save destination path
	becomes the path of the last loaded file, so a template, whether 
	with the same name or with a different one in case it was changed 
	manually in the dialogue, is saved at the same location on 
	the disk the last template was loaded from.

	If the template is saved with the same name as the last loaded
	template, its file is ovewrtitten without a warning much like
	when a project is saved, which is the whole purpose of the script, 
	to be able to save a track template without going through 
	additional dialogues required by the native save track template 
	action. That's unless it was loaded without some resources, to
	prevent its inadvertent overwriting with less content than it 
	was originally loaded with.  
	When trying to save a tempate with a name different from that 
	of the last loaded one, if a template file with the same name 
	already exists at the target path the user is presented with
	a warning.

	If there're selected tracks, only these will be saved as a track 
	template, otherwise all tracks are saved much like in case of
	project saving.

	The active options in the dialogue reflect the presence of 
	objects on the tracks or within selection of tracks which are 
	going to be saved. To disable any of the options remove the + 
	sign from its field. Conversely, to enable one, insert any 
	alphanumeric character in the option field.

	There're 2 ways to save template at a path different from the 
	path of the last loaded template:  
	1. Insert full path of the file about to be created into the
	'File name' field of the dialogue and click OK. Extension isn't 
	necessary.  
	2. Type the question mark ? into the 'File name' field and click 
	OK. As a result a 'Save Project' (not 'Save track template') 
	dialogue will pop up. This is needed to be able to store the path 
	of the newly saved template so it can be re-saved later without 
	selecting the file again. The file can be saved with .RPP or 
	.RTrackTemplate extension. In case of the former it will be 
	changed into .RTrackTemplate automatically.  
	The drawback is that each time you save a template at a new 
	location the saved file is added to the 'Recent projects' submenu 
	under 'File' main menu (if recent project list is enabled at 
	Preferences -> General -> Recent project list display button)
	and project media folder gets created if one is configured in the 
	project settings of project template and REAPER is set to start 
	new project with project template, or if you have saved default 
	project settings in which default media path is configured, or 
	if you have configued one at  
	Preferences -> General -> Paths -> Default recording path.  
	If you change your mind after 'Save Project' dialogue has been 
	called and click 'Cancel', in the next prompt which will pop up
	titled 'REAPER Query' asking to save an unsaved project, click
	'No' rather than 'Cancel' so that the temporary tab under which
	'Save Project' dialogue was opened is closed and doesn't remain
	open unnecessarily.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Within the double square brackets insert
-- an alternative default path to load templates
-- from and to save at if no other path is
-- available to the script, however during script execution
-- the path is constantly updated to the path
-- of the last loaded template;
-- if empty, /TrackTemplates folder at REAPER's
-- resource path will be used
ALTERNATIVE_TRACK_TEMPLATE_PATH = [[ ]]


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
	local t = {...}
	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
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


function validate_sett(sett, is_literal)
-- validate setting, can be either a non-empty string or any number
-- is_literal is boolean to determine the gsub pattern
-- in case literal string is used for a setting, e.g. [[ ]]

-- if literal string is used for a setting it may happen to contain
-- implicit new lines which should be accounted for in evaluation
local pattern = is_literal and '[%s%c]' or ' '
return type(sett) == 'string' and #sett:gsub(pattern,'') > 0 or type(sett) == 'number'
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function sanitize_file_name(name)
-- the name must exclude extension
-- https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names
-- relies on Error_Tooltip() function

local orig_len = #name
local OS = r.GetAppVersion()
local lin, mac = OS:match('lin'), OS:match('OS')
local win = not lin and not mac
local t = win and {'<','>',':','"','/','\\','|','?','*'}
or lin and {'/','\0'} or mac and {'/',':'}
	for k, char in ipairs(t) do
	name = name:gsub(char, '')
	end

	if #name:gsub(' ','') == 0 then
	Error_Tooltip('\n\n   the file name does not \n\n include valid characters. \n\n', 1, 1, -100, -255) -- caps, spaced true, x2 -100, y2 -255 to raise the tooltip above the dialogue window moving it away from the mouse cursor to prevent blocking the OK button which the mouse cursor will be pointing at
	return end

local win_illegal = 'CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9'
	if win then
		for ill_name in win_illegal:gmatch('[^,]+') do
			if name:match('^%s*'..ill_name..'%s*$') or name:match('^%s*'..ill_name:lower()..'%s*$')
			then name = '' break end -- illegal names padded with spaces aren't allowed either
		end
	end

	if #name > 0 then -- if after the sanitation there're characters left
	local shorter = #name < orig_len
		if shorter then
		Error_Tooltip('\n\n\t the file name has been \n\n stripped of illegal characters. '
		..'\n\n\t      please review it \n\n', 1, 1, -100, -280) -- caps, spaced true, x2 -100, y2 -280 to raise the tooltip above the dialogue window moving it away from the mouse cursor to prevent blocking the OK button which the mouse cursor will be pointing at
		end
	return name, shorter
	end

end



function sanitize_file_path(f_path)
-- the limit is 256 characters
-- truncating the file name if needed
-- relies on Error_Tooltip() function

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

-- make the stock function reverse non-ANSI strings as well
-- the change applies to the entire environment scope
function string.reverse(self)
local str_reversed = ''
	for char in self:gmatch('[\192-\255]*.[\128-\191]*') do
	str_reversed = char..str_reversed
	end
return str_reversed
end

local path, name, ext = f_path:match('(.+[\\/])(.+)(%.%w+)')

local OS = r.GetAppVersion()
local lin, mac = OS:match('lin'), OS:match('OS')
local win = not lin and not mac
local t = win and {'<','>',':','"','/','|','%?','%*'} -- escaping magic characters
or lin and {'\0'} or mac and {':', '/.'} -- OSX doesn't recognize file/folder names starting with a dot
-- https://care.acronis.com/s/article/Illegal-Characters-on-Various-Operating-Systems?language=en_US
-- https://superuser.com/questions/1499950/what-are-invalid-names-for-a-directory-under-linux

	for k, char in ipairs(t) do
		if path:match('^%s*%u:.-'..char) then -- this message is only possible if path to new location was insered manually into the 'File name' field
		Error_Tooltip('\n\n the file path contains \n\n    illegal characters \n\n', 1, 1, -80, -300)
		return nil, f_path end -- f_path is parallel to mess return value below
	end

local diff = 256 - (path:len()+ext:len())
local mess

	if diff <= 0 then
	local excess = diff < 0 and '\n\n   by '..math.abs(diff)..' characters.' or ''
	Error_Tooltip('\n\n the file path length \n\n   exceeds the limit '..excess..' \n\n', 1, 1, -65, -275) -- caps, spaced true, x2 and y2 to display the tooltip above the dialogue
	mess = name
	elseif diff < name:len() then -- truncate file name
	name = name:sub(1, diff)
	--[[ OR in a more convoluted way
	local diff = diff-name:len() -- subtracting smaller from greater to obtain negative value
	name = name:sub(1, diff-1) -- additional -1 because the end argument includes the last character, i.e. 1 greater than the actual difference
	--]]
	-- after truncation the file name may happen to match an existing file
	-- if so reverse the name, not 100% failproof but the odds that the reversed file name will still clash are fairly low
	local reversed, y2 = '', -245
		if r.file_exists(path..name..ext) then
		name = name:reverse()
		reversed = '\n\n\tand reversed to prevent \n\n     clash with an existing file.'
		y2 = y2-50
		end
	Error_Tooltip('\n\n the file name has been truncated \n\n    due to excessive path length. '..reversed..' \n\n', 1, 1, -170, y2) -- caps, spaced true, x2 and y2 to display the tooltip above the dialogue
	mess = name
	end

return path..name..ext, mess, (path..name..ext):len() < f_path:len(), name:len() -- 3d value to indicate whether the name was truncated, 4th value the length of the new name

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


function Dir_Exists(path, sep)
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = sep or path:match('[\\/]')
	if not sep then return end -- likely not a string representing a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- to return 1 (valid) last separator must be removed
local _, mess = io.open(path)
return #path:gsub('[%c%.]', '') > 0 and mess:match('Permission denied') and path..sep -- dir exists // this one is enough HOWEVER THIS IS ALSO THE RESULT IF THE path var ONLY INCLUDES DOTS, therefore gsub ensures that besides dots there're other characters
end



function Active_Track_Envelopes_Exist(want_sel_tracks)
-- want_sel_tracks is boolean to only evaluate selected tracks
local TrackCount, GetTrack = table.unpack(want_sel_tracks and {r.CountSelectedTracks, r.GetSelectedTrack}
or {r.GetNumTracks, r.GetTrack})
	for i=0, TrackCount(0)-1 do
	local tr = GetTrack(0,i)
		if tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.06 then
			if r.CountTrackEnvelopes(tr) > 0 then return true end
		else
		-- in REAPER builds prior to 7.06 CountTrack/TakeEnvelopes() lists ghost envelopes when fx parameter modulation was enabled at least once without the parameter having an active envelope, hence must be validated with CountEnvelopePoints(env) because in this case there're no points; ValidatePtr(env, 'TrackEnvelope*'), ValidatePtr(env, 'TakeEnvelope*') and ValidatePtr(env, 'Envelope*') on the other hand always return 'true' therefore are useless
			for i=0, r.CountTrackEnvelopes(tr)-1 do
			local env = r.GetTrackEnvelope(tr,i)
				if r.CountEnvelopePoints(env) > 0 then return true end
			end
		end
	end
end



function Media_Items_Exist(want_sel_tracks)
-- want_sel_tracks is boolean to only evaluate selected tracks
	if not want_sel_tracks and r.CountMediaItems(0) > 0 then return true end
	for i=0, r.CountSelectedTracks()-1 do
	local tr = r.GetSelectedTrack(0,i)
		if r.GetTrackNumMediaItems(tr) > 0 then
		return true
		end
	end
end



function In_Visible_Tracks_Exist(want_visible, want_sel_tracks)
-- want_visible is boolean to evaluate existence of visible tracks
-- otherwise invisible;
-- want_sel_tracks is boolean to only evaluate selected tracks
local state = want_visible and 1 or 0
local TrackCount, GetTrack = table.unpack(want_sel_tracks and {r.CountSelectedTracks, r.GetSelectedTrack}
or {r.GetNumTracks, r.GetTrack})
	for i=0, TrackCount(0)-1 do
	local tr = GetTrack(0,i)
		if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == state then return true end
	end
end



function Get_Last_Sel_or_Last_Track()
-- only visible tracks are respected

local sel_tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true
local master_tr = r.GetMasterTrack(0)
local master_vis = r.GetMasterTrackVisibility()&1 == 1 -- &1 is visibility in TCP
local last_sel_tr = sel_tr_cnt > 0 and r.GetSelectedTrack2(0, sel_tr_cnt-1, true) -- wantmaster true

	if last_sel_tr == master_tr and not master_vis -- &1 is visibility in TCP, if last selected is the Master this means it's the only one selected and since it's hidden the loop below won't start
	or last_sel_tr and r.GetMediaTrackInfo_Value(last_sel_tr, 'B_SHOWINTCP') == 0 then -- get last visible selected track
	last_sel_tr = nil -- reset to be able to fall back on the last visible track in the tracklist
		for i=sel_tr_cnt-2,0,-1 do -- -2 to exclude the last selected track which turned out to be hidden
		local tr = r.GetSelectedTrack2(0, i, true)
			if tr ~= last_sel_tr and (tr == master_tr and master_vis
			or tr ~= master_tr and r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1) then
			last_sel_tr = tr break
			end
		end
	end

	if not last_sel_tr then -- if no visible selected track was found, opt for the last visible in the tracklist
		for i=r.GetNumTracks()-1,0,-1 do
		local tr = r.GetTrack(0,i)
			if r.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') == 1 then
			last_sel_tr = tr break
			end
		end
	end

local last_sel_tr_idx = 0
	if last_sel_tr then -- if no tracks in the project this var will be nil in which case index 0 will be used for the trig track
	last_sel_tr_idx = r.CSurf_TrackToID(last_sel_tr, false) -- mcpView false // OR r.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')
	end

return last_sel_tr, last_sel_tr_idx -- idx is 1-based and is also index for inserting or moving a track after it

end



function Load_Track_Template(named_ID, path, items, env, hidden_tracks)
-- items, env, hidden_tracks args stem from the Load sub-dialogue
-- where resources to be excluded can be selected

local sep = r.GetResourcePath():match('[\\/]')
local path = path or r.GetResourcePath()..sep..'TrackTemplates'..sep

local retval, file = r.GetUserFileNameForRead(path, 'Load Track Template', '.RTrackTemplate')

	if not retval then return end

-- exclude content
local template_content, items_removed, env_removed, hid_tracks_removed
	if items or env or hidden_tracks then
	template_content, items_removed, env_removed, hid_tracks_removed = Process_Project_Or_Template_File(file, not items, not env, not hidden_tracks) -- converting true arguments into false because removal inside the function is based on falsehood implied in the main dialogue settings for INcluding resources
	end

--r.Main_openProject(file) -- DOES THE SAME THING AS THE CODE BELOW BUT INSERTS TEMPLATE AFTER LAST TOUCHED TRACK WHICH MAY NOT BE SELECTED AND THIS MAY NOT BE OBVIOUS
--do return end

-- split to track chunks
local t = {}
local chunk_start, items, env
	for line in (template_content and template_content:gmatch('[^\r\n]*') or io.lines(file)) do
		if line:match('^%s*<TRACK') then -- track chunk start
		chunk_start = 1
		t[#t+1] = line
		elseif chunk_start then -- continuation of the track chunk
		items = items or line:match('^%s*<ITEM[%s{%-%d}]*') -- in some track template files the <ITEM block start may not include the GUID
		env = env or line:match('^%s*<.-ENV[%w]*%s*')
		t[#t] = t[#t]..'\n'..line
		end
	end


	if #t == 0 then
	Error_Tooltip('\n\n invalid track template \n\n', 1, 1) -- caps, spaced true
	return end


local sel_tr, index = Get_Last_Sel_or_Last_Track()

	-- insert tracks and associate track chunks with them
	for i=0,#t-1 do
	local index = index+i
	r.InsertTrackAtIndex(index, false) -- wantDefaults false
	t[r.GetTrack(0, index)] = t[i+1]
	end

r.Undo_BeginBlock()

	-- deselect all tracks before highlighting those inserted from track template
	if r.CountSelectedTracks2(0, true) > 0 then -- wantmaster true
	r.SetOnlyTrackSelected(r.GetMasterTrack(0))
	r.SetTrackSelected(r.GetMasterTrack(0), false) -- selected false
	end

	-- apply track chunks to the newly inserted tracks and highlight them by selecting mimicking REAPER native action behavior
	for tr, chunk in pairs(t) do
		if not tonumber(tr) then -- track pointer rather than table index which was preserved in the loop above
		r.SetTrackStateChunk(tr, chunk, false) -- isundo false
		r.SetTrackSelected(tr, true) -- selected true
		end
	end

r.Undo_EndBlock('Load track template (enhanced): '..file:match('.+[\\/](.+)%.%w+$'), -1)

return file, items_removed, env_removed, hid_tracks_removed -- return full file path to store so the file can be resaved at the same location, + what resources were removed if any

end



function Close_Tab_Without_Warning()
-- use inside Save_Template_As_Proj_File_At_New_Path
-- creates temp project file, uses it, then deletes it
-- for consistency's sake path is the path of the last loaded/saved template
-- stemming from the extended state
-- if not stored yet, use REAPER own last/current working directory
local script_path = debug.getinfo(1,'S').source:match('@(.+[\\/])') -- without the name
local section, key = ('DUMMY PROJECT FILE'):reverse(), ('PATH'):reverse()
local dummy_proj = r.GetExtState(section, key)
dummy_proj = r.file_exists(dummy_proj) and dummy_proj
or script_path..'BuyOne_dummy project (do not rename).RPP'
	if not r.file_exists(dummy_proj) then
	r.SetExtState(section, key, dummy_proj, true) -- persist true
	local f = io.open(dummy_proj,'w')
	f:write('<REAPER_PROJECT\nTITLE "THIS FILE IS USED BY SOME SCRIPTS"\n>')
	f:close()
		if r.file_exists(dummy_proj) then
		r.Main_openProject('noprompt:'..dummy_proj) -- open suppressing prompt to save currently unsaved project // THIS CHANGES CURRENT WORKING DIRECTORY, SO NEXT TIME THE OPEN PROJECT DIALOGUE WILL POINT TO THE DUMMY PROJ FILE DIRECTORY
		r.Main_OnCommand(40860, 0) -- Close current project tab
	--	os.remove(path)
		end
	end
end



function Save_Template_As_Proj_File_At_New_Path(named_ID, items, env, hidden_tracks)

local ALT -- if true, instead of copying ALL tracks to temp proj tab, only selected are copied because if there're selected tracks they're the only ones to be saved as a track template, and all tracks are copied only if none is initally selected; if false all tracks are copied regardless and then if there're selected tracks the non-selected ones are removed from the project file inside Process_Project_Or_Template_File() function, which although is a less clean method in terms of coding still cleaner visually because under the temp project tab the track content is indistinguishable from the source tab and presence of the temp tab may not even be noticed by the user

local restore_track_selection

	if not ALT then
		function restore_track_selection(t)
		-- deselect all
		r.SetOnlyTrackSelected(r.GetMasterTrack(0))
		r.SetTrackSelected(r.GetMasterTrack(0), false) -- selected false
		-- OR
		-- ACT(40297, 0) Track: Unselect (clear selection of) all tracks
			for k, tr_idx in ipairs(t) do
			r.SetTrackSelected(r.CSurf_TrackFromID(tr_idx, false), true) -- mcpview fales, selected true
			end
		r.TrackList_AdjustWindows(true) -- isMinor true // may be unnecessary
		end
	end

local ACT = r.Main_OnCommand
local cur_proj = r.EnumProjects(-1)

local sel_tracks
	if ALT then
	sel_tracks = r.CountSelectedTracks(0) > 0
	else
	sel_tracks = {}
	end

	if not ALT then
	-- store selected tracks to be able to restore later
		for i=0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
		sel_tracks[i+1] = r.CSurf_TrackToID(r.GetSelectedTrack2(0,i, true), false) -- mcpview false, store indices because track pointers cannot be used in the temp proj tab to recreate selection
		end
	end

	if ALT and not sel_tracks -- select all tracks under the source proj tab if none is selected to be able to copy them
	or not ALT -- select all regardless
	then
		for i=0, r.GetNumTracks()-1 do
		r.SetTrackSelected(r.GetTrack(0,i), true) -- selected true
		end
	-- OR
	-- ACT(40296, 0) -- Track: Select all tracks
	end

ACT(40210, 0) -- Track: Copy tracks

	if ALT then
		if not sel_tracks then -- deselect all to restore their original state under the source proj tab
		r.SetOnlyTrackSelected(r.GetMasterTrack(0))
		r.SetTrackSelected(r.GetMasterTrack(0), false) -- selected false
		end
	else
	restore_track_selection(sel_tracks) -- restore original track selection under the source proj tab
	end

ACT(41929, 0) -- New project tab (ignore default template)
ACT(42398, 0) -- Item: Paste items/tracks

	if not ALT then
	-- recreate original track selection under the temp tab because by this point
	-- all tracks will have been selected because it was necessary for copying
	-- ESSENTIALLY NOT NEEDED BECAUSE THE FILE WILL BE SAVED AS .RPP
	-- AND WILL INCLUDE ALL TRACKS WHICH WILL BE WEEDED OUT IN Process_Project_Or_Template_File()
	-- SO JUST FOR THE SAKE OF OPTICS
	restore_track_selection(sel_tracks)
	end

r.Main_SaveProject('', true) -- forceSaveAsIn true, if proj arg is project pointer the relevant project tab will be switched to
--ACT(42347, 0) -- File: Save copy of project as... // not suitable because doesn't update the project tab from which file name will be retrieved
local temp_tab, new_path = r.EnumProjects(-1)
ACT(40860, 0) -- Close current project tab // generates prompt to save unsaved project if Save Project dialogue was cancelled
	if r.ValidatePtr(temp_tab, 'ReaProject*') then -- OR #new_path == 0 // if user cancels the prompt generated by 'Close current project tab' the temporary tab won't be closed, so force close it before switching to the original tab
	Close_Tab_Without_Warning()
	end

r.SelectProjectInstance(cur_proj)

	-- abort because if the file was saved as .RPP and there's already namesake .RTrackTemplate file
	-- at the new path, renaming of the the project file extension into RTrackTemplate after processing
	-- inside Process_Project_Or_Template_File() will fail
	if new_path:match('.+%.RPP$') and
	r.file_exists(new_path:sub(1,-4)..'RTrackTemplate') then
	local name = new_path:match('.+[\\/](.+)%.%w+$')
	local s = function(num) return (' '):rep(num) end
	-- r.MB('Save failed because track template file \n\n named "'..name..'" already exists.', 'ERROR', 0)
		if r.MB(s(12)..'Track template file \n\n named "'..name..'" already exists.\n\n'
		..s(10)..'Wish to overwrite it?', 'PROMPT', 4) == 7 then
		os.remove(new_path)
		return
		else -- remove track template file, keeping the saved project file for further processing
		os.remove(new_path:sub(1,-4)..'RTrackTemplate')
		end
	end

	if #new_path > 0 then -- user saved the file, the temp proj tab was populated with the file name
	local template_content = Process_Project_Or_Template_File(new_path, items, env, hidden_tracks, not ALT and #sel_tracks > 0) -- remove irrelevant content, non_sel_tracks arg depends on the ALT mode and presence of selected tracks to trigger removal of the non-selected track chunks because into the project file all tracks are saved and if any are selected only these must remain in the track template which the project file is converted into inside the function
	local path_to_store = new_path:match('.+%.RTrackTemplate$') and new_path or new_path:sub(1,-4)..'RTrackTemplate' -- keep the path in case user chose to save the file with track template extension, otherwise replace the extension
	r.SetExtState(named_ID, 'LAST_LOADED', path_to_store, false) -- persist false // update last loaded path re-adding the extension in case it's .RPP
	return new_path, template_content
	end

end



function Remove_Track_Chunk_By_Criteria(code, pattern)
-- from project file or track template content
-- code is string contaning project file or track template content
-- pattern is string for string.match() function
-- to evaluate the chunk content
-- used inside Process_Project_Or_Template_File()

local reassembled, chunk, criteria, item
local removed
	for line in code:gmatch('[^\n\r]+') do
		if line:match('^%s*<ITEM') then item = 1 end -- item is used to disambiguate track attributes from item atrributes which are likely to produce false positives otherwise, one such attribute is SEL
		if line:match(pattern) and not item then criteria = 1; removed = 1
		elseif criteria and line:match('^%s*<TRACK') then -- next track chunk has come along
		chunk = nil -- reset latest track chunk because it belongs to a non-selected track
		criteria = nil -- reset because new chunk has come along
		item = nil
		end
		if chunk and line:match('^%s*<TRACK') then -- next track chunk has come along
		reassembled = reassembled and reassembled..'\n'..chunk or chunk -- add to the rest of the chunks
		chunk = line -- restart chunk collection
		item = nil -- reset
		else
		chunk = chunk and chunk..'\n'..line or line
		end
	end

-- if last track matches the criteria its chunk won't be reset within the loop
-- because line:match('^%s*<TRACK') condition for reset won't be met, so criteria
-- var remains true in which case return reassembled right away;
-- if last track doesn't match the criteria its chunk won't be added to reassembled
-- within the loop likewise because line:match('^%s*<TRACK') condition won't be met
-- so add it inline;
-- if only one track is being saved the loop won't reach reassembled concatenation stage
-- hence fall back on chunk var whether valid or not, so may be nil if track matched
-- the criteria
return criteria and reassembled or reassembled and reassembled..'\n'..chunk or chunk, removed

end



function Process_Project_Or_Template_File(file_path, items, env, hidden_tracks, non_sel_tracks)
-- non_sel_tracks arg instructs to remove from the proj file chunks of the non-selected tracks
-- if any are selected because only these are supposed to be saved into a track template
-- unless none is selected in which case all are saved;
-- used in the main routine and inside Save_Template_As_Proj_File_At_New_Path()
-- to process project file and inside Load_Track_Template() to process template file

local t, chunk_start = {}

	-- collect the code to the exclusion of extended data
	for line in io.lines(file_path) do
		if line:match('<EXTENSIONS') or line:match('<EXTSTATE') then break -- these, if any, come at the bottom of the .RPP file so ignore them
		elseif line:match('^%s*<TRACK') or chunk_start then -- track chunk start, in project file TRACK token is followed by GUID unlike in the track template, but that's immaterial
		chunk_start = 1
		t[#t+1] = line
		end
	end

local items_removed, env_removed, hid_tracks_removed -- will be returned and used to prevent inadvertent overwriting of template which was loaded without any of these resources, only evaluated when loading, so collected inside Load_Track_Template() function

	if not items then -- weed out item chunks
	local item
		for k, line in ipairs(t) do
			if line:match('^%s*<TRACK') or k == #t then item = nil -- reset, k==#t ensures preservation of the last track block closure which is the last field in the table
			elseif (line:match('^%s*<ITEM') or item) -- in some track template files the <ITEM block start may not include the GUID as it doesn't in the project file
			and t[k+1] and not t[k+1]:match('^%s*<TRACK') then -- preventing deletion of the current track block closure if the next track block starts on the next line
			item = 1
			t[k] = ''
			items_removed = 1
			end
		end
	end

	if not env then -- weed out envelope chunks
	local env
		for k, line in ipairs(t) do
			if line:match('^%s*<.-ENV[%w]*%s*') or #line > 0 and env then -- ignoring empty fields from items loop, if any
			env = 1
			t[k] = ''
			env_removed = 1
			env = not line:match('^%s*>') -- if closure, reset, there're no nested blocks within envelope blocks so weeding them out is simple // ternary expression of 'env = line:match('^%s*>') and nil/false or env' to reset won't work because true env will always end up being selected and this will keep being true
			-- OR
			--	if line:match('^%s*>') then env = nil end
			end
		end
	end

-- remove empty lines, although works with them as long as blocks integrity is preserved
local length = #t -- store the original table length because it will get shorter during the loop
	for i = length, 1, -1 do
		if t[i] == '' then table.remove(t,i) end
	end

local templ = table.concat(t,'\n')

	if not hidden_tracks then -- weed out hidden tracks
	templ, hid_tracks_removed = Remove_Track_Chunk_By_Criteria(templ, '^%s*SHOWINMIX %d [%.%d]+ [%.%d]+ 0')
	end

	if non_sel_tracks then
	templ = Remove_Track_Chunk_By_Criteria(templ, '^%s*SEL 0')
	end

return templ, items_removed, env_removed, hid_tracks_removed -- 3 last return values are only collected inside Load_Track_Template() function to store in extended state what was excluded and prevent inadvertent overwriting of the template file when re-saved

end


function Save_Processed_Project_File_As_Track_Template(file_path, reversed_file_name, template_content)
-- used in the main routine
-- reversed_file_name arg will only contain reversed file name
-- if the template is saved with .RPP extension and clashes
-- with another project file at the destination path
-- template_content arg stems from Process_Project_Or_Template_File()

local templ_file_path = file_path:match('.+%.[Rr][Pp]+$') and file_path:sub(1,-4)..'RTrackTemplate' or file_path -- only replace if file was saved with .RPP extension, in Save_Template_As_Proj_File_At_New_Path() it can also be saved with track template extension in which case keep the original path

	if reversed_file_name then -- if .RPP file name was reversed to prevent clash with another project file, restore
	templ_file_path = templ_file_path:match('.+[\\/]')..reversed_file_name:reverse()..'.RTrackTemplate' -- reassemble, reverse function works with non-ANSI characters as well because the native one was overwritten inside sanitize_file_path() function
	end

local templ_file_exists = r.file_exists(templ_file_path)

-- if template file already exists, open it to update its contents, then delete the project file
-- because os.rename() won't be able to rename the project file with the name of an already existing file
-- this is relevant when saving at the same path or at the new path supplied in the 'File name' field,
-- i.e. without 'Save Project' dialogue used inside Save_Template_As_Proj_File_At_New_Path(),
-- because in these scenarios file extension depends on existence of track selection
local f = io.open(templ_file_exists and templ_file_path or file_path, 'w')
f:write(template_content)
f:close()
	if templ_file_exists and templ_file_path ~= file_path then -- delete the project file and its backup file if any, preventing deletion in cases where the file was originally saved with track template extension
	os.remove(file_path)
	os.remove(file_path..'-bak') -- remove temp project backup file
	else -- rename the project file
	os.rename(file_path, templ_file_path)
	end

end



function GetUserInputs_Alt(title, field_cnt, field_names, field_cont, separator, comment_field, comment)
-- title string, field_cnt integer, field_names string separator delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string or nil unless they must be initially filled
-- to fill out only specific fields precede them with as many separator characters
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5
-- separator is a string, character which delimits the fields
-- comment_field is boolean, comment is string to be displayed in the comment field
-- extrawidth parameter is inside the function

	if (not field_cnt or field_cnt <= 0) then -- if field_cnt arg is invalid, derive count from field_names arg
		if #field_names:gsub(' ','') == 0 and not comment_field then return end
	field_cnt = select(2, field_names:gsub(',',''))+1 -- +1 because last field name isn't followed by a comma and one comma less was captured
	--	if field_cnt-1 == 0 and not comment_field then return end -- SAME AS THE ABOVE CONDITION
	end

	if field_cnt >= 16 then
	field_cnt = 16 -- clamp to the limit supported by the native function
	comment_field = nil -- disable comment if field count hit the limit, just in case
	end

	local function add_separators(field_cnt, arg, sep)
	-- for field_names and field_cont as arg
	-- add delimiting separators when they're fewer than field_cnt
	-- due to lacking field names or field content
	-- which means they will delimit trailing empty fields
	local _, sep_cnt = arg:gsub(sep,'')
	return sep_cnt == field_cnt-1 and arg -- -1 because the last field isn't followed by a separator
	or sep_cnt < field_cnt-1 and arg..(sep):rep(field_cnt-1-sep_cnt) -- add trailing separators
	or arg:match(('.-'..sep):rep(field_cnt)):sub(1,-2) -- truncate arg when field_cnt value is smaller than the number of fields, excluding the last separator captured with the pattern inside string.match because the last field isn't followed by a separator
	end

	local function format_fields(arg, sep, field_cnt)
	-- for field_names and field_cont as arg
	local arg = type(arg) == 'table' and table.concat(arg, sep) or arg
	return add_separators(field_cnt, arg, sep):gsub(sep..' ', sep) -- if there's space after separator, remove because with multiple fields the field names/content will not line up vertically
	end

-- for field names sep must be a comma because that's what field names list is delimited by
-- regardless of internal 'separator=' argument
local field_names = format_fields(field_names, ',', field_cnt) -- if commas needed in field names and the main separator is not a comma (because if it is comma cannot delimit field names), pass here the separator arg from the function
local sep = separator and #separator > 0 and separator or ','
local field_cont = field_cont or ''
field_cont = format_fields(field_cont, sep, field_cnt)
local comment = comment_field and comment and type(comment) == 'string' and #comment > 0 and comment or ''
local comment_field_cnt = select(2, comment:gsub(sep,''))+1 -- +1 because last comment field isn't followed by the separator so one less will be captured
local field_cnt = comment_field and #comment > 0 and field_cnt+comment_field_cnt or field_cnt

	if field_cnt >= 16 then
	-- disable some or all comment fields if field count hit the limit after comment fields have been added
	comment_field_cnt = field_cnt - 16
	field_cnt = 16
	end

field_names = comment_field and #comment > 0 and field_names..(',Comments:') or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = sep ~= ',' and ',separator='..sep or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=250'..separator, field_cont)
local comment_pattern = ('.-'..sep):rep(comment_field_cnt-1) -- -1 because the last comment field isn't followed by a separator
output = #comment > 0 and output:match('(.+'..sep..')'..comment_pattern) or output -- exclude comment field(s) and include trailing separator to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement
	if not ret or (field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0) then return end
	--[[ OR
	-- to condition action by the type of the button pressed
	if not ret then return 'cancel'
	elseif field_cnt > 1 and output:gsub(' ','') == (sep):rep(field_cnt-1)
	or #output:gsub(' ','') == 0 then return 'empty' end
	]]
local t = {}
	for s in output:gmatch('(.-)'..sep) do
--	for s in output:gmatch('[^'..sep..']*') do -- allow capturing empty fields and the last field which doesn't end with a separator // alternative to 'if #comment == 0 then' block below
		if s then t[#t+1] = s end
	end
	if #comment == 0 then
	-- if the last field isn't comment,
	-- add it to the table because due to lack of separator at its end
	-- it wasn't caught in the above loop
	t[#t+1] = output:match('.*'..sep..'(.*)') -- * operator to account for empty 1st field if there're only two of them
	end
return t, #comment > 0 and output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it
end


	if tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.53 then -- build since which Main_SaveProjectEx() is supported
	Error_Tooltip('\n\n the script requires \n\n  reaper build 6.53+ \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named
or scr_name -- if an non-installed script is run via 'ReaScript: Run (last) ReaScript (EEL2 or lua)' actions get_action_context() won't return valid command ID, in which case fall back on the script full path
local sep = r.GetResourcePath():match('[\\/]')
local path = r.GetResourcePath()..sep..'TrackTemplates'..sep
path = validate_sett(ALTERNATIVE_TRACK_TEMPLATE_PATH, 1) and Dir_Exists(ALTERNATIVE_TRACK_TEMPLATE_PATH) -- invalid alternative path
or not validate_sett(ALTERNATIVE_TRACK_TEMPLATE_PATH, 1) and path -- empty setting so fall back on \TrackTemplates

	if not path then
	Error_Tooltip('\n\n the alternative path is invalid \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local last_loaded = r.GetExtState(named_ID, 'LAST_LOADED')
local file_name = last_loaded:match('.+[\\/](.+)%.%w+$') or '' -- isolate file name, will be fed into GetUserInputs_Alt()
local file_path = last_loaded:match('.+[\\/]') or path -- fall back on /TrackTamplates folder or user defined if nothing stored yet

local sel_tracks = r.CountSelectedTracks(0) > 0 and r.CountSelectedTracks(0)
local items = Media_Items_Exist(sel_tracks) -- do not activate items option if there're no items in the project when no track is selected or on selected tracks because if there are any selected tracks, only they will be saved to template
local env = Active_Track_Envelopes_Exist(sel_tracks) -- same for envelopes, if there're selected tracks only they will be saved hence only existence of envelopes on selected tracks is evaluated
local hidden_tracks = In_Visible_Tracks_Exist(want_visible, sel_tracks) -- same for hidden tracks, want_visible false

local items_removed, env_removed, hid_tracks_removed

::RELOAD:: -- placed here to preserve user settings when the dialogue is reloaded by excluding assignments above

local comment = 'To load, submit with empty "File name" field;\rto save with current settings at current location click OK;\rto save at a new location, type ?  in the "File name" field ...\r... or insert in it full path without file extension'
comment = (sel_tracks and r.GetNumTracks() ~= sel_tracks and 'ONLY SELECTED TRACKS WILL BE SAVED' or 'ALL TRACKS WILL BE SAVED')..'\r'..comment -- only display if not all tracks are selected
or comment
local output_t = GetUserInputs_Alt('LOAD/SAVE TRACK TEMPLATE', 5, 'File name (when saving),Include items,Include envelopes,Include hidden tracks,Exclude resources when loading', file_name..'\r'
..(items and '+' or '')..'\r'..(env and '+' or '')..'\r'..(hidden_tracks and '+' or ''), '\r', comment, comment)

	if not output_t then return r.defer(no_undo) end -- aborted by the user or submitted empty

file_name = output_t[1] -- user submitted name

	if not validate_sett(file_name) then -- empty file name submitted, LOAD track template
	local items, env, hidden_tracks
		if validate_sett(output_t[5]) then -- load dialogue to exclude resources from the template being loaded
		local output_t = GetUserInputs_Alt('Load leaving out some resources', 3, 'Exclude items,Exclude envelopes,Exclude hidden tracks','')
			if not output_t then return r.defer(no_undo) end -- either aborted by the user or submitted empty
		items, env, hidden_tracks = validate_sett(output_t[1]), validate_sett(output_t[2]), validate_sett(output_t[3])
		end

	file_path, items_removed, env_removed, hid_tracks_removed = Load_Track_Template(named_ID, file_path, items, env, hidden_tracks) -- using path of the last loaded template or /TrackTemplates in REAPER resource directory before any template was loaded or saved

		if file_path then
		r.SetExtState(named_ID, 'LAST_LOADED', file_path, false) -- persist false
			if items_removed or env_removed or hid_tracks_removed then
			r.SetExtState(tostring(r.EnumProjects(-1)), 'LAST_LOADED_ABRIDGED', (items_removed and '1,' or '0,')
			..(env_removed and '1,' or '0,')..(hid_tracks_removed and '1' or '0'), false) -- persist false // saving under project pointer as section title to disambiguate tempplates loaded under different project tabs
			end
		end

	else -- SAVE

		if r.GetNumTracks() == 0 then
		Error_Tooltip('\n\n no tracks in the project \n\n', 1, 1) -- caps, spaced true
		return r.defer(no_undo)
		elseif not In_Visible_Tracks_Exist(1) -- want_visible true
		and r.MB('      No visible tracks in Arrange.\n\nWish to save an invisible template?', 'PROMPT', 4) == 7 -- user declined
		then
		return r.defer(no_undo)
		end

	items, env, hidden_tracks = validate_sett(output_t[2]), validate_sett(output_t[3]), validate_sett(output_t[4])

		if file_name:match('^[%s%?]+$') -- save at a new location via dialogue; when saving via 'Save Project' dialogue file name will be specified in the dialogue; using ? as an operator to save at a new location because it's a character which is illegal in file names so cannot be confused for a legit file name choice
		then
		local file_path, template_content = Save_Template_As_Proj_File_At_New_Path(named_ID, items, env, hidden_tracks)
			if not file_path then goto RELOAD end -- error message is displayed inside the function
		Save_Processed_Project_File_As_Track_Template(file_path, reversed_file_name, template_content) -- reversed_file_name here nil
		return r.defer(no_undo) end

	-- validating new location path user inserted into the 'File name' field
	local new_path
		if file_name:match('^%s*%u:[\\/]+') then -- likely a path to a new location, different from that of the last loaded template
		new_path = file_name:match('^%s*(.-)%s*$')
			if new_path:sub(-1):match('[\\/]') then -- the path ends with a separator, without a file name
			Error_Tooltip('\n\n the new path doesn\'t \n\n include the file name \n\n', 1, 1, -65, -275) -- caps, spaced true, x2 and y2 to display the tooltip above the dialogue
			goto RELOAD
			elseif (new_path:match('(.+)%.RTrackTemplate$') or new_path) ~= file_path:match('(.+)%.RTrackTemplate$') then -- if new path is different from the stored one, truncating extension if added by the user
			file_path, file_name = new_path:match('(.+[\\/])'), new_path:match('.+[\\/](.+)') -- file path will be sanitized further below
			end
		end

	local new_file_path = file_path..file_name:gsub('%.RTrackTemplate','') -- removing template extension in case added by user, final extension will be determined below

		-- when saving at the same path as the that of the last loaded or saved template but under different name, validate uniqueness
		if not new_path and last_loaded:match('.+[\\/](.+)%.') ~= file_name:gsub('%.RTrackTemplate','')  -- removing extension in case added by user
		then
		-- validate the file name
			if not r.file_exists(new_file_path..'.RTrackTemplate') then -- only validate if file doesn't exist, because if it does then it's sure to be valid
			file_name, shorter = sanitize_file_name(file_name:gsub('%.RTrackTemplate','')) -- removing file extension in case added by user, error messages are generated inside the function
				if not file_name or file_name and shorter then
					if new_path then
					file_name = file_path..(file_name or new_path:match('.+[\\/](.+)')) -- update for the re-loaded dialogue, either append sanitized file name to the path or re-use the original invalid one if it failed sanitation, the error message inside sanitize_file_name() will indicate what's what
					else
					file_name = file_name or output_t[1] -- user submitted name to feed back into the re-loaded dialogue, same
					end
				goto RELOAD
				end
			elseif r.MB('File with the same name already exists.\n\n\tWish to overwrite it?','WARNING',4) == 7 then -- user declined
			goto RELOAD
			end
		end

	local hidden_exist = In_Visible_Tracks_Exist(nil, sel_tracks) -- want_visible nil
	local flags = sel_tracks and (hidden_tracks or not hidden_exist) and 1|(items and 2 or 0)|(env and 4 or 0) or 0 -- when no selected tracks, flags is 0 to be able to save project file without updating the currently open one, in which case all tracks will be included in the resulting template, that's instead of saving track template because track template cannot be saved with no selected tracks and if attempted an error message is thrown; the project file extension after processing is replaced by track template extension; additionally validating hidden track setting to prevent unecessary project file saving and processing when the setting to include them is disabled without there being any hidden tracks to remove

	local new_file_path, mess = sanitize_file_path(new_file_path..'.RTrackTemplate') -- add extension to be able to evaluate final file path length, if the length with track template extension will be valid all the more so with .RPP extension in case the file will be initially saved as project file // new_file_path is returned with extension // error messages are generated inside the function // when the path stems from the last loaded/saved template this validation will always be sucessful, it only may fail if the path was manually supplied by the user when saving at a new location

		if mess then -- if path is malformed mess var includes full path with file extension
		file_name = new_path or file_name -- assign user input in its original format to feed back into the dialogue, depending on their intent, i.e. to save at a new path providing the full path or to the currently stored path prividing the file name only
		goto RELOAD
		-- there's already a file with the same name at a new path
		elseif new_path and r.file_exists(new_file_path) then -- new_file_path returned by sanitize_file_path() above includes extension
			if r.MB('File with the same name already exists.\n\n\tWish to overwrite it?','WARNING',4) == 7 then -- user declined
			file_name = new_path -- assign user input in its original format to feed back into the dialogue
			goto RELOAD
			end
		elseif not Dir_Exists(file_path, sep) then
		Error_Tooltip('\n\n the path doesn\'t exist \n\n', 1, 1, -65, -275) -- caps, spaced true, x2 and y2 to display the tooltip above the dialogue
		file_name = new_path -- assign user input in its original format to feed back into the dialogue
		goto RELOAD
		end

	new_file_path = new_file_path:gsub('%.RTrackTemplate','')..(flags == 0 and '.RPP' or '.RTrackTemplate') -- removing extension from new_file_path before adding final one, sanitize_file_path() above returns this var with RTrackTemplate extension

		-- if the file is gonna be saved with .RPP extension (flags 0) and it happens to clash
		-- with another .RPP file, reverse the name to prevent that
		-- which will be restored inside Process_Project_Or_Template_File() when its extension
		-- is changed into .RTrackTemplate;
		-- opted for reverse rather than adding extra content in order
		-- to preserve the path length in case it's at its limit of 255 chars
	local reversed_file_name
		if flags == 0 and r.file_exists(new_file_path) then
			if file_name:gsub('%.RTrackTemplate',''):len() == 1 then -- cannot reverse a single character name // len function supports non-ANSI charaters as well because the native function was overwritten inside sanitize_file_path() function
			local mode = r.file_exists(new_file_path:gsub('%.RPP','')..'.RTrackTemplate') and 'overwrite' or 'save' -- determine the save mode, if namesake template file already exists then user has confirmed its overwriting above
			-- it's possible to devise a way to prevent clash with a single character name file
			-- by temporarily adding more characters for example,
			-- but since it's a super edge case, it's simpler to just throw an error message
			local x, y = mode=='save' and -100 or 0, mode=='save' and -275 or -215
			Error_Tooltip('\n\n could\'t '..mode..' the file. \n\n Choose a different name. \n\n', 1, 1, x, y) -- caps, spaced true
			file_name = new_path or file_name -- assign user input in its original format to feed back into the dialogue
			goto RELOAD
			end
		reversed_file_name = file_name:gsub('%.RTrackTemplate',''):reverse() -- reverse function supports non-ANSI charaters as well because the native function was ovewrwritten inside sanitize_file_path() function // removing track template extension in case was added by the user
		new_file_path = new_file_path:match('.+[\\/]')..reversed_file_name..'.RPP' -- simpler than replacing with gsub which requires escaping the source and replacement strings
		end

			-- warn user if they're about to re-save template which was loaded without some resources
			if last_loaded == new_file_path:match('(.+)%.%w+$')..'.RTrackTemplate' then -- re-adding extension in case it's .RPP
			local cur_proj = tostring(r.EnumProjects(-1))
			local state = r.GetExtState(cur_proj, 'LAST_LOADED_ABRIDGED')
				if #state > 0 then
				items_removed, env_removed, hid_tracks_removed = state:match('^1,'), state:match(',1,'), state:match(',1$')
					if items_removed or env_removed or hid_tracks_removed then
					local removed = (items_removed and 'Items\n' or '')..(env_removed and 'Envelopes\n' or '')..(hid_tracks_removed and 'Hidden tracks\n' or '')
						if r.MB((' '):rep(9)..'You\'re about to re-save template\n\nwhich was loaded without following resorces:'
						..'\n\n'..removed..'\n\t'..(' '):rep(10)..'Are you sure?','WARNING', 4) == 7 then -- user declined
						goto RELOAD
						end
					r.DeleteExtState(cur_proj, 'LAST_LOADED_ABRIDGED', true) -- perist true // reset
					end
				end
			end

	r.Main_SaveProjectEx(0, new_file_path, flags) -- the function can save file with arbitrary extension and with no extension as well, and tacitly overwrites any namesake file, if only file name is passed with .RPP extension and flags arg is set to 8 gives name to the project tab without saving anything, if a file with the same name already exists in the current working directory (lastcwd) the tab will be asossiated with it and the project file will be overwritten if project content happens to differ from such project file content
		if flags == 0 then -- if project file was saved, process it
		local template_content = Process_Project_Or_Template_File(new_file_path, items, env, hidden_tracks, sel_tracks, reversed_file_name) -- non_sel_tracks arg is sel_tracks, i.e. remove non-selected if selected exist
		Save_Processed_Project_File_As_Track_Template(new_file_path, reversed_file_name, template_content)
		end
	new_file_path = new_file_path:match('(.+)%.%w+$')..'.RTrackTemplate' -- re-add the extension in case it was .RPP above
		if r.file_exists(new_file_path) then -- store the last name the template was saved under to pass into the dialogue on dialogue load
		r.SetExtState(named_ID, 'LAST_LOADED', new_file_path, false) -- persist false
		end
	end


do return r.defer(no_undo) end




