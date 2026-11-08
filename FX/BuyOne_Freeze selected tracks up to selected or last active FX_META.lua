--[[
ReaScript name: BuyOne_Freeze selected tracks up to selected or last active FX_META.lua (6 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M if REAPER build is older than 7.06
Provides: 	[main=main,midi_editor] .
			. > BuyOne_Freeze selected tracks to mono up to selected FX.lua
			. > BuyOne_Freeze selected tracks to stereo up to selected FX.lua
			. > BuyOne_Freeze selected tracks to multichannel up to selected FX.lua
			. > BuyOne_Freeze selected tracks to mono up to last active FX.lua
			. > BuyOne_Freeze selected tracks to stereo up to last active FX.lua
			. > BuyOne_Freeze selected tracks to multichannel up to last active FX.lua
About:	If this script file name is suffixed with META, 
		when executed it will automatically spawn all 
		individual scripts included in the package into 
		the directory of the META script and will import 
		them into the Action list from that directory.

		If there's no META suffix in this script file 
		name it will perfom the operation indicated in 
		its name.

		The set of scripts makes actions only available
		in the FX chain menu, available in the Action list.
		
		In the scripts containing the phrase 
		'up to last active FX', active means not bypassed
		and not offline.
]]


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


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Esc(str)
		if not str then return end -- prevents error
	-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
	local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
	return str
	end

	local function script_is_installed(fullpath)
	local sep = r.GetResourcePath():match('[\\/]')
		for line in io.lines(r.GetResourcePath()..sep..'reaper-kb.ini') do
		local path = line and line:match('.-%.lua["%s]*(.-)"?')
			if path and #path > 0 and fullpath:match(Esc(path)) then -- installed
			return true end
		end
	end

		if not fullpath:match(Esc(scr_name)) then return true end -- will prevent running the function in individual scripts, but allow their execution to continue if the META script isn't functional (doesn't include a menu), if it is - other means of management are employed in the main routine

local names_t, content = names_t

	if not names_t or #names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+[%w])') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created, trimming trailing spaces if any because they invalidate file path
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

	local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		------------------------------------------------------------------------------------
		-- spawn scripts
		-- NO USER SETTINGS
		for k, scr_name in ipairs(names_t) do
		local new_script = io.open(path..scr_name, 'w') -- create new file
	--	content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag // commented out to keep META script original name in the header so user can find it later and re-generate individual scripts if needed
		new_script:write(content)
		new_script:close()
		end

		--------------------------------------------------------------------------------------

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0,32060} do -- Main, MIDI Ed // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

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



function Invalid_Script_Name(scr_name,...)
-- check if necessary elements, case agnostic, are found in script name and return the one found;
-- if elements are patterns or contain patterns Esc() function
-- in scr_name:lower():match(Esc(elm:lower())) should not be used

	if scr_name then
	local t = {...}

		for k, elm in ipairs(t) do
			if scr_name:lower():match(elm:lower()) then return elm end -- at least one match was found
		end
	end

	local function Rep(n) -- number of repeats, integer
	return (' '):rep(n)
	end

-- either no keyword was found in the script name or no keyword arguments were supplied
local br = '\n\n'
r.MB([[The script name has been changed]]..br..Rep(7)..[[which renders it inoperable.]]..br..
[[   please restore the original name]]..br..[[  referring to the name in the header,]]..br..
Rep(20)..[[or reinstall it.]], 'ERROR', 0)

end



-- used in Get_FX_Selected_In_Main_Chain()
function GetObjChunk(obj)
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



-- used in FREEZE_AND_STORE_PROPS()
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



-- used in FREEZE_AND_STORE_PROPS()
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
	ret, idx = GetParm(obj, input_fx and 0x1000000 or 0, 'chain_sel')
	else
	local ret, chunk = GetObjChunk(obj)
		if ret == 'err_mess' then return end
	chunk = tr and input_fx and (chunk:match('(<FXCHAIN_REC.*>)\n<ITEM')
	or chunk:match('(<FXCHAIN_REC.*WAK.*>)\n>')) or chunk
	idx = chunk:match('LASTSEL ([%-%d]+)')
	end
idx = tonumber(idx)
-- due to the bug mentioned above, when value is -1 it must be validated by getting fx count
-- because it's only accurate when there're no fx in the chain;
-- when the chain is empty this value returns false
return idx > -1 and idx or CountFX(obj) > 0 and 0
end



function FREEZE(actID, selected, last_unbypassed_online)

-- store selected tracks to be able to freeze them one by one
-- if selected or last_unbypassed_online are valid
-- because freeze actions freeze all selected at once
-- which won't allow excluding fx in each track;
-- and traverse them in order to store their props
local sel_tr = {}
	for i=0, r.CountSelectedTracks(0)-1 do
	sel_tr[#sel_tr+1] = r.GetSelectedTrack(0,i)
	end

	if not selected and not last_unbypassed_online then r.Main_OnCommand(actID, 0) end -- freeze all selected at once

local tmp_tr = Create_Temp_Track_Move_FX_To_From()
local failed = {}

-- isolate fx which won't be included in the freeze
	for k, tr in ipairs(sel_tr) do
	r.SetOnlyTrackSelected(tr)
	local sel_fx = selected and Get_FX_Selected_In_Main_Chain(tr)
	local fx_cnt = r.TrackFX_GetCount(tr)
	local st, active = sel_fx or 0
		if st == -1 and fx_cnt > 0 then
		failed[#failed+1] = math.floor(r.CSurf_TrackToID(tr, false)) -- mcpView false // last sel fx value may be -1 even when there're fx in the chain due to bug in builds older than 7.83 https://forum.cockos.com/showthread.php?t=311951, so collect the affected tracks indices to inform the user
		end
		if st ~= -1 then -- only run when > -1, i.e. there're fx in the chain and the value is not affected by the bug above beause the index of the last selected fx cannot be reliably determined, a pretty edge case because normally a user would explicitly select an fx in the chain before freezing in 'up to selected' mode
			for i=fx_cnt-1, st, -1 do -- in reverse because fx are removed
			active = active or not r.TrackFX_GetOffline(tr, i) and r.TrackFX_GetEnabled(tr, i) -- as soon as the farthest active fx is found, the condition becomes always true to prevent movement of previous fx
				if sel_fx and i > sel_fx or last_unbypassed_online and not active then
				Create_Temp_Track_Move_FX_To_From(tr, i, tmp_tr, 1) -- move true, move fx to temp track
				end
			end
		end
	r.Main_OnCommand(actID, 0) -- freeze
		-- restore isolated fx back to the source track in the original order
		for i=r.TrackFX_GetCount(tmp_tr)-1, 0, -1 do -- in reverse because fx are removed
		Create_Temp_Track_Move_FX_To_From(tr, i, tmp_tr) -- move false, return fx to the source track
		end
	end

r.DeleteTrack(tmp_tr)

-- restore track selection
	for k, tr in ipairs(sel_tr) do
	r.SetTrackSelected(tr, true) -- selected true
	end

return sel_tr, failed

end



local is_new_value, fullpath_init, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile(), loadfile() or require() from installer script or a host script the above function will return installer/host script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // for cases where META script itself does display menu when executed // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script as fullpath_init, in fact fits both cases, i.e. META script with and without menu

	-- doesn't run in non-META scripts
	if not META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Freeze selected tracks up to selected or last active FX_META.lua', names_t) -- names_t is optional only if constructed outside of the function, otherwise names are collected from the list in the header
	then return r.defer(no_undo) end -- abort if META script but continue if not

--[[ name testing
t = {
'mono selected',
'stereo last active'
}
scr_name = t[2]
--]]


	if not Invalid_Script_Name(scr_name, 'mono', 'stereo', 'multichannel')
	or not Invalid_Script_Name(scr_name, 'selected', 'last active')
	then return r.defer(no_undo)
	end


	if r.CountSelectedTracks(0) == 0 then
	Error_Tooltip('\n\n no selected tracks \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


local mono, stereo, mutlichan = scr_name:match('mono'), scr_name:match('stereo'), scr_name:match('multichannel')
local actID = mono and 40901 -- Track: Freeze to mono (render pre-fader, save/remove items and online FX)
or stereo and 41223 -- Track: Freeze to stereo (render pre-fader, save/remove items and online FX)
or mutlichan and 40877 -- Track: Freeze to multichannel (render pre-fader, save/remove items and online FX)

r.Undo_BeginBlock()

local selected, active = scr_name:match('selected'), scr_name:match('active')
local sel_trks_t, failed_tr_t = FREEZE(actID, selected, active)

local up_to_sel_failed = #failed_tr_t == #sel_trks_t

	if #failed_tr_t > 0 then
	r.MB('Freezing of the following tracks:\n\n'..table.concat(failed_tr_t, ', ')..'\n\nfailed due to inability\n\nto accurately determine\n\nthe last selected FX', up_to_sel_failed and 'ERROR' or 'INFO', 0)
	end

-- even if freeze to selected FX failed in all tracks, undo point is still created
-- because the tracks do get frozen, just with all fx rather than some
local undo = 'Freeze selected tracks to '..(mono and 'mono' or stereo and 'stereo' or multichan and 'multichannel')
..(selected and not up_to_sel_failed and ' up to selected FX' or  active and ' up to last active FX' or '')
r.Undo_EndBlock(undo, -1)

