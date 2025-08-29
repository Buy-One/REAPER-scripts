--[[
ReaScript name: BuyOne_Crop sample to selection in RS5k instances on selected objects.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.37 for reliable performance
Provides: [main=main,midi_editor,mediaexplorer] .
About: 	Object is either track or item or active take
	in a multi-take item.  
	Priority is given to selected tracks. If no track 
	is selected a prompt will offer to target selected 
	items if any are selected.  
	In tracks only main FX chain is targeted, input FX
	chain is ignored.  
	FX containers aren't supported. To target RS5k 
	instances inside containers use script 
	BuyOne_Crop sample to selection in focused RS5k instance.lua
	which obviously is able to affect one RS5k instance
	at a time.

	Cropped versions of the files are placed in and loaded
	to RS5k from the project folder or its dedicated 
	media folder if specified in the project settings, 
	provided the project is saved. Otherwise it will
	be located in the default media directory for 
	unsaved projects, which is either absolute path
	specified in the default project settings under
	Media -> Path to save media files, path specified
	at Preferences -> General -> Paths -> Default recoring path
	or REAPER default path %USER%\Documents\REAPER Media
	(on Windows).

	Keep in mind that if you undo the change produced 
	by the script the newly created cropped versions
	of the sample files will remain on the disk.
]]


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


function space(num)
return (' '):rep(num)
end


function Dir_Exists(path, sep)
local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
local sep = sep or path:match('[\\/]')
	if not sep then return end -- likely not a string representing a path
local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- to return 1 (valid) last separator must be removed
local _, mess = io.open(path)
return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
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


function Re_Store_Selected_Items(t, keep_last_selected)

	if not t then
	local t = {}
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if r.IsMediaItemSelected(item) then
			t[item] = '' -- dummy entry
			end
		end
	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	return t
	else
		if not keep_last_selected then
		r.SelectAllMediaItems(0, false) -- selected false // deselect all
		end
		for item in pairs(t) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	end

r.UpdateArrange()

end



function Get_FX_Parm_By_Name_Or_Ident(obj, fx_idx, parm_name, parm_ident, want_input_fx)
-- search by name/identifier in case index changes
-- yet a situation when index remains the same while name/identifier change
-- is just as likely;
-- param name can be aliased by user while identifier can't and so more reliable;
-- obj is track or take
-- want_input_fx is boolean to target input fx chain / Mointoring FX chain of the Master track
-- only valid if obj arg is track
local take, tr = r.ValidatePtr(obj,'MediaItem_Take*'), r.ValidatePtr(obj,'MediaTrack*')
local FX_CountParm, FX_GetParamName, FX_GetParamIdent = table.unpack(take and {r.TakeFX_GetNumParams, r.TakeFX_GetParamName, r.TakeFX_GetParamIdent} or tr and {want_input_fx and r.TrackFX_GetRecCount or r.TrackFX_GetNumParams, r.TrackFX_GetParamName, r.TrackFX_GetParamIdent})
	if take or tr then
	local _6_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37 -- support FX_GetParamIdent function
	local fx_idx = tr and want_input_fx and fx_idx < 0x100000 and fx_idx+0x1000000 or fx_idx
		for i=0, FX_CountParm(obj, fx_idx) do
		local retval, name = FX_GetParamName(obj, fx_idx, i)
		local retval, ident = table.unpack(_6_37 and {FX_GetParamIdent(obj, fx_idx, i)} or {})
			if parm_name and name == parm_name
			or parm_ident and ident:match(parm_ident) -- without escaping because they're unlikely to include special characters, but worth being watchful; and using string.match because returned identifiers incluse param index, i.e. 1:_identifier
			then return i end
		end
	end
end



function Insert_Item_On_Temp_Track()

r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
local name = tr_name and r.GetSetMediaTrackInfo_String(temp_tr, 'P_NAME', tr_name, true) -- setNewValue true
r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer // not hiding in TCP because this will prevent Gluing track item, the Glue action won't work
local temp_itm = r.AddMediaItemToTrack(temp_tr)
local take = r.AddTakeToMediaItem(temp_itm)

return temp_tr, temp_itm, take

end



function Add_File_To_Temp_Item_And_Glue(temp_tr, temp_itm, take, props)
-- props is table containing RS5k instance properties

-- create pcm source from file and get its properties
local src = r.PCM_Source_CreateFromFile(props.file_path) -- props.file_path is path to RS5k current sample
local retval, sect_offset, src_length, reversed = r.PCM_Source_GetSectionInfo(src)
-- convert into seconds based on PCM source length
local sample_start, sample_end = src_length*props.start, src_length*props['end']
local length = sample_end-sample_start

-- apply pcm source to take
local old_src = r.GetMediaItemTake_Source(take) -- this followed by destroying below ensures that in case of undoing the glued files can be deleted from the disk manually, otherwise there'll be a single locked file whose undestroyed source will prevent its deletion
r.SetMediaItemTake_Source(take, src)
r.PCM_Source_Destroy(old_src)

-- set item to full source length before adjusting to selection length for cropping,
-- for loop cycles other than the 1st because the temp item is being re-used
r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', 0)
r.SetMediaItemTakeInfo_Value(take, 'D_LENGTH', src_length)

-- set item bounds to sample cropped bounds
r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', sample_start)
local Set_Item = r.SetMediaItemInfo_Value
Set_Item(temp_itm, 'D_LENGTH', length)

-- name take after source file so that newly created file bears the name of the original
r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', props.file_path:match('[^\\/]+$'), true) -- setNewValue true

-- remove fades in case enabled automatically for inserted media
-- at Prefs -> Project -> Item Fade Defaults
Set_Item(temp_itm, 'D_FADEINLEN', 0)
Set_Item(temp_itm, 'D_FADEOUTLEN', 0)
r.SetMediaItemSelected(temp_itm, true) -- selected true // must be selected for Glue to work


r.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection

--[[ WORKS ON WINDOWS
local file_path = r.GetMediaSourceFileName(src, '')
local take = r.GetActiveTake(temp_itm) -- IT SEEMS THAT CREATING AND SETTING NEW TAKE PCM SOURCE FOLLOWED BY GLUING INVALIDATES ORIGINAL TAKE POINTER, SO FOR EACH NEXT SOURCE FILE TAKE POINTER MUST BE RE-GET; GLUING WITHOUT CHANGE IN TAKE PCM SOURCE HOWEVER DOESN'T CHANGE TAKE POINTER EVEN IN MULTIPLE PASSES
--]]
--[-[ this is a version of the lines in the block comment above in an attempt to fix a bug which cannot be replicated on Windows 7 https://forum.cockos.com/showthread.php?p=2887546, https://forum.cockos.com/showthread.php?p=2887580
local take = r.ValidatePtr(temp_itm, 'MediaItem*') and r.GetActiveTake(temp_itm) or r.GetActiveTake(r.GetSelectedMediaItem(0,0))
local src = r.GetMediaItemTake_Source(take)
local file_path = r.GetMediaSourceFileName(src, '')
--]]
return file_path, take

end


function Apply_Cropped_File_To_RS5k(obj, fx_num, sample_start_idx, sample_end_idx, file_path)
-- file_path stems from Add_File_To_Temp_Item_And_Glue()

SetNamedConfigParm(obj, fx_num, 'FILE0', file_path)
SetNamedConfigParm(obj, fx_num, 'DONE', '')
FX_SetParam(obj, fx_num, sample_start_idx, 0)
FX_SetParam(obj, fx_num, sample_end_idx, 1)

end



local sel_tracks_cnt = r.CountSelectedTracks(0)
local sel_itms_cnt = r.CountSelectedMediaItems(0)

	if sel_tracks_cnt + sel_itms_cnt == 0 then
	Error_Tooltip('\n\n no selected tracks or items \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end

	if sel_tracks_cnt == 0 and sel_itms_cnt > 0
	and r.MB('\t    No selected tracks.\n\nWant the script to target selected items?', 'PROMPT', 4) == 7 -- user declined
	then return r.defer(no_undo)
	end

local tracks = r.CountSelectedTracks(0) > 0
CountObjects, GetObject, CountFX, GetNamedConfigParm, SetNamedConfigParm, FX_GetParam, FX_SetParam = table.unpack(not tracks and {r.CountMediaItems, r.GetMediaItem, r.TakeFX_GetCount, r.TakeFX_GetNamedConfigParm, r.TakeFX_SetNamedConfigParm, r.TakeFX_GetParam, r.TakeFX_SetParam, } or tracks and {r.CountSelectedTracks, r.GetSelectedTrack, r.TrackFX_GetCount, r.TrackFX_GetNamedConfigParm, r.TrackFX_SetNamedConfigParm, r.TrackFX_GetParam, r.TrackFX_SetParam })

local t = {}
local sample_start_idx, sample_end_idx

	for i=0, CountObjects(0)-1 do
	local obj = GetObject(0,i)
		if tracks or r.IsMediaItemSelected(obj) then
		obj = tracks and obj or r.GetActiveTake(obj)
			for fx_idx=0, CountFX(obj)-1 do
			local ret, orig_name = GetNamedConfigParm(obj, fx_idx, 'fx_name')
			local RS5k = orig_name:match('ReaSamplOmatic5000')
				if not RS5k -- REAPER build older than 6.37 or plugin name changed in the FX browser
				or not sample_start_idx and not sample_end_idx -- no RS5k instances have been detected yet or vars have been reset during evaluation of the previous plugin which isn't RS5k
				then
				-- validating plugin identity concurrently with getting its parameter indices
				-- if return values are nil, the plugin is not RS5k
				sample_start_idx = Get_FX_Parm_By_Name_Or_Ident(obj, fx_idx, 'Sample start offset', '_Sample_start_offset', nil) -- want_input_fx nil
				sample_end_idx = Get_FX_Parm_By_Name_Or_Ident(obj, fx_idx, 'Sample end offset', '_Sample_end_offset', nil)
				end
			local retval, full_file_path = GetNamedConfigParm(obj, fx_idx, "FILE"..(0))
				if (RS5k or sample_start_idx and sample_end_idx) and retval then -- likely RS5k instance and it's not empty // if original name can be validated, sample_start_idx and end_parm_idx vars will have already been retrieved when the first instance was detected, if it cannot be validated sample_start_idx and sample_end_idx vars will be retrieved again, so they always belong to RS5k and indicate its presence
				-- these values are percentage of the file length on scale of 0-1
				-- so must be converted into sec after getting file PCM source length
				local sample_start, minval, maxval = FX_GetParam(obj, fx_idx, sample_start_idx)
				local sample_end, minval, maxval = FX_GetParam(obj, fx_idx, sample_end_idx)
					if sample_start > 0 or sample_end < 1 then -- only store if sample is trimmed, i.e. selection is active
						if not t[obj] then t[obj] = {} end
					t[obj][fx_idx] = {start=sample_start, ['end']=sample_end, file_path=full_file_path, start_idx=sample_start_idx, end_idx=sample_end_idx} -- storing sample start/end parameter indices within the table because if last plugin in the chain is not RS5k sample_start_idx and sample_end_idx vars will be reset to nil in the plugin identity evaluation above and will be unusable in the main loop below
					end
				end
			end
		end
	end

	if not next(t) then
	Error_Tooltip('\n\n    couldn\'t find rsk5 instances \n\n populated with a trimmed sample \n\n', 1,1) -- caps, spaced
	return r.defer(no_undo)
	end


r.Undo_BeginBlock()
r.PreventUIRefresh(1)


local sel_items_t = {}

		if sel_itms_cnt > 0 then -- if there're any selected items, they must be deselected to be restored later, otherwise Glue action inside Add_File_To_Temp_Item_And_Glue() will glue them as well, deselection will not interfere with cropping samples in take fx chain, because target take data have already been collected above
		sel_items_t = Re_Store_Selected_Items()
		end

local temp_tr, temp_itm, take = Insert_Item_On_Temp_Track()

	for obj, data in pairs(t) do -- objects loop
		for fx_idx, props in pairs(data) do -- RS5k instances loop
		file_path, take = Add_File_To_Temp_Item_And_Glue(temp_tr, temp_itm, take, props) -- returns path to the newly created glued file, and new take pointer after setting new take source and gluing for next loop cycle because the temp item is being re-used
		Apply_Cropped_File_To_RS5k(obj, fx_idx, props.start_idx, props.end_idx, file_path)
		end
	end

r.DeleteTrack(temp_tr)

	if next(sel_items_t) then Msg('RESTORE') Re_Store_Selected_Items(sel_items_t) end -- restore item selection

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Crop sample to selection in RS5k instances '..(tracks and 'on selected tracks' or 'in active takes'), -1)








