--[[
ReaScript name: BuyOne_Crop sample to selection in focused RS5k instance.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.37 for reliable performance
Extensions: 
Provides: [main=main,midi_editor,mediaexplorer] .
About: 	Keep in mind that if you undo the change produced 
	by the script the newly created cropped version
	of the sample file will remain on the disk.
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


function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

-- r.TrackFX_GetOpen(master_tr, integer fx)
	local master_tr = r.GetMasterTrack(0)
	local mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
	local is_mon_fx_float = false -- only relevant for pasting stage to reopen the fx in floating window
		if mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return mon_fx_idx, is_mon_fx_float -- expected >= 0, true
end


function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20

	if not r.GetTouchedOrFocusedFX then -- older than 7.0

	local retval, tr_num, itm_num, fx_num = r.GetFocusedFX()
	-- Returns 1 if a track FX window has focus or was the last focused and still open, 2 if an item FX window has focus or was the last focused and still open, 0 if no FX window has focus. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber and fxnumber are zero-based. If item FX, fxnumber will have the high word be the take index, the low word the FX index.
	-- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx itm_num is -1, if retval is 0 the rest return values are 0 as well
	-- if src_take_num is 0 then track or no object ???????

	local mon_fx_num = GetMonFXProps() -- expected >= 0 or > -1

	local tr = retval > 0 and (r.GetTrack(0,tr_num-1) or r.GetMasterTrack()) or retval == 0 and mon_fx_num >= 0 and r.GetMasterTrack() -- prior to build 6.20 Master track has to be gotten even when retval is 0

	local item = retval == 2 and r.GetTrackMediaItem(tr, itm_num)
	-- high word is 16 bits on the left, low word is 16 bits on the right
	local take_num, take_fx_num = fx_num>>16, fx_num&0xFFFF -- high word is right shifted by 16 bits (out of 32), low word is masked by 0xFFFF = binary 1111111111111111 (16 bit mask); in base 10 system take fx numbers starting from take 2 are >= 65536
	local take = retval == 2 and r.GetMediaItemTake(item, take_num)
	local fx_num = retval == 2 and take_fx_num or retval == 1 and fx_num or mon_fx_num >= 0 and 0x1000000+mon_fx_num -- take or track fx index (incl. input/mon fx) // unlike in GetLastTouchedFX() input/Mon fx index is returned directly and need not be calculated // prior to build 6.20 Mon FX have to be gotten when retval is 0 as well // 0x1000000+mon_fx_num is equivalent to 16777216+mon_fx_num
	--	local mon_fx = retval == 0 and mon_fx_num >= 0
	--	local fx_num = mon_fx and mon_fx_num + 0x1000000 or fx_num -- mon fx index

	local fx_alias, fx_GUID

		if take then
		fx_GUID = r.TakeFX_GetFXGUID(take, fx_num)
		fx_alias = select(2, r.TakeFX_GetFXName(take, fx_num))
		elseif tr then
		fx_alias = select(2, r.TrackFX_GetFXName(tr, fx_num))
		fx_GUID = r.TrackFX_GetFXGUID(tr, fx_num)
		end

	local fx_name, _ = fx_alias
	-- if older version fx_name return value will be indentical to fx_alias
		if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.31 then
		local obj = take or tr
		local GetNamedConfigParm = take and r.TakeFX_GetNamedConfigParm or tr and r.TrackFX_GetNamedConfigParm
			if obj then
			_, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
			fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
			or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
			end
		end

	return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_alias, fx_name, fx_GUID -- tr_num = -1 means Master;

	else

	-- supported since v7.0
	local retval, tr_num, itm_num, take_num, fx_num, parm_num = reaper.GetTouchedOrFocusedFX(1) -- 1 focused mode // parm_num only relevant for querying last touched (mode 0) // supports Monitoring FX and FX inside containers, container itself can also be focused
	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = tr and r.GetTrackMediaItem(tr, itm_num)
	local take = item and r.GetTake(item, take_num)
	local fx_alias, fx_GUID, is_cont

		if take then
		fx_alias = select(2, r.TakeFX_GetFXName(take, fx_num))
		fx_GUID = r.TakeFX_GetFXGUID(take, fx_num)
		is_cont = r.TakeFX_GetIOSize(take, fx_num) == 8
		elseif tr then
		fx_alias = select(2, r.TrackFX_GetFXName(tr, fx_num))
		fx_GUID = r.TrackFX_GetFXGUID(tr, fx_num)
		is_cont = r.TrackFX_GetIOSize(tr, fx_num) == 8
		end

	local obj = take or tr
		if obj then
		local GetNamedConfigParm = take and r.TakeFX_GetNamedConfigParm or tr and r.TrackFX_GetNamedConfigParm
		local ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
		fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
		or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor or Container

		local input_fx, cont_fx = tr and r.TrackFX_GetRecChainVisible(tr) ~= -1, fx_num >= 33554432 -- or fx_num >= 0x2000000 // fx_num >= 0x1000000 or fx_num >= 16777216 for input_fx gives false positives if fx is inside a container in main fx chain hence chain visibility evaluatiion
		local mon_fx = retval and tr_num == -1 and input_fx

		return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, input_fx, cont_fx, is_cont -- tr_num = -1 means Master
		end

	end

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
			or parm_ident and ident:match(parm_ident) -- without escaping because they're unlikely to include special characters, but worth being watchful
			then return i end
		end
	end
end



function Insert_Item_On_Temp_Track(want_midi_editor, tr_name, file_path, start_offs, length)

r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_tr = r.GetTrack(0,r.CountTracks(0)-1)
local name = tr_name and r.GetSetMediaTrackInfo_String(temp_tr, 'P_NAME', tr_name, true) -- setNewValue true
r.SetMediaTrackInfo_Value(temp_tr, 'B_SHOWINMIXER', 0) -- hide in Mixer
local temp_itm
	if not want_midi_editor then
	-- Must not be hidden in Arrange if a temp item on the temp track must be opened
	-- in the MIDI Editor, otherwise it may end up not being deleted after opening the MIDI Editor,
	-- it doesn't if the function is run on REAPER startup, may need testing in other scenarios
		if file_path then -- insert temp item
		temp_itm = r.AddMediaItemToTrack(temp_tr)
		end
	else -- insert temp MIDI item
	local ACT = reaper.Main_OnCommand
	ACT(40914, 0) -- Track: Set first selected track as last touched track (to make it the target for temp MIDI item insertion)
	ACT(40214, 0) -- Insert new MIDI item...
	ACT(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
	end

local take = r.AddTakeToMediaItem(temp_itm)
local pcm_src = r.PCM_Source_CreateFromFile(file_path)
r.SetMediaItemTake_Source(take, pcm_src)
r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', start_offs)
r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', file_path:match('[^\\/]+$'), true) -- setNewValue true, name after source file so that newly created files bears the name of the original
local Set_Item = r.SetMediaItemInfo_Value
Set_Item(temp_itm, 'D_LENGTH', length)
-- remove fades in case enabled automatically for inserted media
-- at Prefs -> Project -> Item Fade Defaults
Set_Item(temp_itm, 'D_FADEINLEN', 0)
Set_Item(temp_itm, 'D_FADEOUTLEN', 0)
r.SetMediaItemSelected(temp_itm, true) -- selected true // must be selected for Glue to work
r.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
pcm_src = r.GetMediaItemTake_Source(take)
file_path = r.GetMediaSourceFileName(pcm_src, '')

r.DeleteTrack(temp_tr)
r.PCM_Source_Destroy(pcm_src)

return file_path

end



	if r.CountTracks(0) + r.CountMediaItems(0) == 0 then
	Error_Tooltip('\n\n no tracks or items \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end

local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, is_input_fx, is_cont_fx, is_cont = GetFocusedFX()
local err = (retval == 0 and not mon_fx -- in versions older than 7.0
or not retval) and 'no focused fx' or not fx_name:match('ReaSamplOmatic5000') and 'the focused FX is not RS5k'

	if err then Error_Tooltip('\n\n '..err..' \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end

local obj = take or tr
GetNamedConfigParm, SetNamedConfigParm, FX_GetParam, FX_SetParam = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_SetNamedConfigParm, r.TakeFX_GetParam, r.TakeFX_SetParam} or tr and {r.TrackFX_GetNamedConfigParm, r.TrackFX_SetNamedConfigParm, r.TrackFX_GetParam, r.TrackFX_SetParam})

local retval, full_file_path = GetNamedConfigParm(obj, fx_num, "FILE"..(0))

	if not retval then
	Error_Tooltip('\n\n rs5k is empty \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end


local sample_start_idx = Get_FX_Parm_By_Name_Or_Ident(obj, fx_num, 'Sample start offset', '_Sample_start_offset', want_input_fx)
local sample_end_idx = Get_FX_Parm_By_Name_Or_Ident(obj, fx_num, 'Sample end offset', '_Sample_end_offset', want_input_fx)

	if not sample_start_idx or not sample_end_idx then
	Error_Tooltip('\n\n couldn\'t retrieve plugin info \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end

-- these values are percentage of the file length on scale of 0-1
-- so must be converted into sec after getting file PCM source length
local sample_start, minval, maxval = FX_GetParam(obj, fx_num, sample_start_idx)
local sample_end, minval, maxval = FX_GetParam(obj, fx_num, sample_end_idx)

	if sample_start == 0 and sample_end == 1 then
	Error_Tooltip('\n\n the sample length isn\'t trimmed. \n\n\t   nothing to crop to. \n\n ', 1,1) -- caps, spaced
	return r.defer(no_undo) end


local proj, proj_path = r.EnumProjects(-1)
local proj_media_path = r.GetProjectPath('') -- this returns default recording path, i.e. '%USER%\Documents\REAPER Media' for unsaved projects, a dedicated ABSOLUTE path if configured in default Project Settings, or global path configured at Prefs -> General -> Paths -> Default recording path, so by itself unreliable unless validated by proj_path not being empty, i.e. saved project; for saved projects returns the project folder path unless a project dedicated media path is specified in the project settings
local retval, proj_media_folder = r.GetSetProjectInfo_String(0, 'RECORD_PATH', '', false) -- is_set false
local move

	if #proj_path > 0 and Dir_Exists(proj_path:match('(.+)[\\/]')) and Dir_Exists(proj_media_path)
	and proj_media_path ~= full_file_path:match('(.+)[\\/]') then
	local mess = #proj_media_folder > 0 and space(13)..'The file is located outside\n\n   of the project dedicated media folder.\n\n'..space(6)..'Wish to move the cropped version\n\n'..space(10)..'into the project media folder?'
	or 'The file is located outside of the project folder.\n\n'..space(11)..'Wish to move the cropped version\n\n\t'..space(4)..'into the project folder?'
		if r.MB(mess, 'PROMPT', 4) == 6 then move = 1 end
	end

local src = r.PCM_Source_CreateFromFile(full_file_path)
local retval, sect_offset, length, reversed = r.PCM_Source_GetSectionInfo(src) -- if sect is false startoffs and len are 0

-- convert into seconds based on PCM source length
sample_start, sample_end = length*sample_start, length*sample_end
length = sample_end-sample_start

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

full_file_path = Insert_Item_On_Temp_Track(want_midi_editor, tr_name, full_file_path, sample_start, length)
r.PCM_Source_Destroy(src)

	if move then
	local f = io.open(full_file_path,'rb')
	local data = f:read('*a')
	os.remove(full_file_path)
	local path = proj_media_path..proj_media_path:match('[\\/]')..full_file_path:match('[^\\/]+$') -- concatenate new location path
	f = io.open(path,'wb')
	f:write(data)
	f:close()
	full_file_path = path
	end

SetNamedConfigParm(obj, fx_num, 'FILE0', full_file_path)
SetNamedConfigParm(obj, fx_num, 'DONE', '')
FX_SetParam(obj, fx_num, sample_start_idx, 0)
FX_SetParam(obj, fx_num, sample_end_idx, 1)

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Crop sample to selection in focused RS5k instance', -1)








