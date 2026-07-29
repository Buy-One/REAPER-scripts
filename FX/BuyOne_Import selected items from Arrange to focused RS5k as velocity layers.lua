--[[
ReaScript name: BuyOne_Import selected items from Arrange to focused RS5k as velocity layers.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main] .
About: 	If selected item has multiple takes
			  the script only respects the active take.

		  	The items are imported in the order
			  of their selection.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert
-- any alphanumeric character between the quotes.

-- Both 'Pitch adjust' setting and take pitch envelope;
-- only the value of the first point
-- of the take pitch envelope is respected;
-- if enabled and multiple items are selected
-- the final pitch value applied to RS5k will be
-- taken from the last selected item
RESPECT_ITEM_PITCH = "1"

-- Both item volume and active take volume;
-- the final volume applied to RS5k will be
-- taken from the last selected item
RESPECT_ITEM_VOLUME = "1"

-- Respect item trimming;
-- if trimmed to the point of the source
-- not being visible, the setting is ignored
-- and the take source is imported untrimmed;
-- the final sample bounds applied to RS5k
-- will be taken from the last selected item
RESPECT_ITEM_BOUNDS = "1"

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



function is_audio_src(obj)
-- obj is either take source or take pointer
-- take is advised in cases where source may be set to section or reversed

local validate = r.ValidatePtr
local src, take = validate(obj, 'PCM_source*'), validate(obj, 'MediaItem_Take*')
	if src then
	src = obj
	elseif take then
		if r.TakeIsMIDI(obj) then return end
	src = r.GetMediaItemTake_Source(obj) -- won't return accurate pointer for reversed source and source sections, that is those which have either 'Section' or 'Reverse' checkboxes checked in the 'Item properties' window, hence next line
	src = r.GetMediaSourceParent(src) or src
	end

	if src then
	local typ = r.GetMediaSourceType(src, '')
		for k, v in ipairs({'MIDI', 'RPP', 'EMPTY', 'CLICK', 'LTC', 'VIDEO'}) do
			if typ:match(v) then
				if v == 'VIDEO' then -- as of build 7.52 wma and m4a files are recognized as video even though they only contain audio, so need to be validated further https://forum.cockos.com/showthread.php?t=304924
				local ext = r.GetMediaSourceFileName(src, ''):match('.+%.(.+)$')
					if ext == 'wma' or ext == 'm4a' then
					return true
					end
				end
			return
			end
		end
	return true
	end

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

	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well

		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm} or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num)
		local fx_name = fx_alias
		-- in builds older than 6.31 fx_name return value will be indentical to fx_alias
			if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.31 then
			local ret
			ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
			fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
			or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
			end

		return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_alias, fx_name, fx_GUID -- tr_num = -1 means Master;
		end

	else -- supported since v7.0

	local retval, tr_num, itm_num, take_num, fx_num, parm_num = r.GetTouchedOrFocusedFX(1) -- 1 focused mode // parm_num only relevant for querying last touched (mode 0) or if the last focused window is still open, value 1 // supports Monitoring FX and FX inside containers, container itself can also be focused

	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = tr and r.GetTrackMediaItem(tr, itm_num)
	local take = item and r.GetTake(item, take_num)
	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well

		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm} or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID, is_cont = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num), GetIOSize(obj, fx_num) == 8
		local ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
		fx_name = fx_name:match('JS:') and fx_name:match('JS: (.+) %[') -- excluding path
		or fx_name:match('[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor or Container

		local input_fx, cont_fx = tr and r.TrackFX_GetRecChainVisible(tr) ~= -1, fx_num >= 33554432 -- or fx_num >= 0x2000000 // fx_num >= 0x1000000 or fx_num >= 16777216 for input_fx gives false positives if fx is inside a container in main fx chain hence chain visibility evaluatiion
		local mon_fx = retval and tr_num == -1 and input_fx

		return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, input_fx, cont_fx, is_cont -- tr_num = -1 means Master
		end
	end

end



function Validate_FX_Identity(obj, fx_idx, fx_name, parm_t, parm_ident_t, TAG)
-- since v7 r.EnumInstalledFX() can be used to retrieve the name
-- listed in the FX browser and a unique identifier independent
-- of the name in case changed but the identifier must of course be known in advance
-- the function is based on Get_FX_Parm_Orig_Name_s() above
-- in case it's been aliased by the user;
-- obj is track or take;
-- fx_name is the original name of the plugin being validated
-- parm_t is a table indexed by param indices whose fields hold corresponding original param names
-- e.g. {[4] = 'parm name 4', [12] = 'parm name 12', [23] = 'parm name 23'}
-- parm_ident_t is a table indexed by param indices whose fields hold
-- corresponding param string identifiers, supported since build 6.37+
-- parm_t and parm_ident_t must be of the same length and have the same order of parameters;
-- TAG is a user TAG added to FX name in the FX chain
-- to mark it as a target for script, optional
-- works with builds 6.37+
-- relies on Esc() function

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local GetFXName, GetConfig, CopyFX, GetParmCount, GetParamName =
table.unpack(tr and {r.TrackFX_GetFXName, r.TrackFX_GetNamedConfigParm,
r.TrackFX_CopyToTrack, r.TrackFX_GetNumParams, r.TrackFX_GetParamName}
or take and {r.TakeFX_GetFXName, r.TakeFX_GetNamedConfigParm,
r.TakeFX_CopyToTrack, r.TakeFX_GetNumParams, r.TakeFX_GetParamName} or {})
-- get name displayed in fx chain
local retval, fx_chain_name = GetFXName(obj, fx_idx, '')
fx_chain_name = TAG and fx_chain_name:gsub(TAG,'') or fx_chain_name -- if TAG is supplied removing to be able to evaluate clean name // script specific
	if fx_chain_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix

-- if fx chain displayed name doesn't match the user supplied name, meaning was renamed
-- get fx browser displayed name in builds which support this option

local build_6_37 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.37

local retval, orig_fx_name

	if build_6_37 then
	retval, orig_fx_name = GetConfig(obj, fx_idx, 'original_name') -- or 'fx_name' // returned with fx type prefix
	-- In theory two different plugins can have identical names set by the user in the FX browser
	-- but in practice the odds are low
		if orig_fx_name:match(Esc(fx_name)) then return true end -- ignoring fx type prefix
	end

-- if validation by the original name failed or wasn't supported
-- validate using parameter names

-- add temp track and copy the fx instance to it
r.PreventUIRefresh(1)
r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false; insert new track at end of track list and hide it; action 40702 'Track: Insert new track at end of track list' creates undo point hence unsuitable
local temp_track = r.GetTrack(0,r.CountTracks(0)-1)
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINMIXER', 0) -- hide in Mixer
r.SetMediaTrackInfo_Value(temp_track, 'B_SHOWINTCP', 0) -- hide in Arrange
-- search for the name of fx parameter at the same index as the one being evaluated
-- in plugin copy on the temp track,
-- in builds older than 6.37 the evaluation isn't reliable
-- by 100% because some parameter names in the source fx may be aliased
-- and won't match the expected names
-- parameter identifiers supported since build 6.37 however are likely to be immutable
CopyFX(obj, fx_idx, temp_track, 0, false) -- is_move false

local parm_t = parm_t and type(parm_t) == 'table' and #parm_t > 0 and parm_t
local parm_ident_t = parm_ident_t and type(parm_ident_t) == 'table' and #parm_ident_t > 0 and parm_ident_t
local name_match = true

	if parm_t or parm_ident_t then
		for idx, name in pairs(parm_t) do
		local ident
		local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, idx, '') -- fx_idx 0
			if build_6_37 then
			retval, ident = r.TrackFX_GetParamIdent(temp_track, 0, idx)
			end
			if partm_t and name ~= parm_name
			or parm_ident_t and not ident:match(Esc(parm_ident_t[idx])) -- using string.match because returned identifiers incluse param index, i.e. 1:_identifier, while the table fed as argument doesn't
			then
			-- break rather than return to allow deletion of the temp track
			-- before returning the value
			name_match = false break
			end
		end
	else -- compare names and identifiers of up to 6 random parameters
	local src_parm_cnt = GetParmCount(obj, fx_idx)
	local tmp_parm_cnt = r.TrackFX_GetNumParams(temp_track, 0) -- 0 temp fx index
		if src_parm_cnt == tmp_parm_cnt then
		parm_t, parm_ident_t = {}, {}
		math.randomseed(math.floor(r.time_precise()*1000))
		local count = src_parm_cnt > 5 and 6 or src_parm_cnt -- look for 6 param names as long as the param count allows that, 6 is more reliable than 3 or 4 because random number may repeat which will reduce the number of options
			for i=1, count do
			-- collect parameter data from the source fx
			local ident
			local rnd = math.random(1, src_parm_cnt)-1 -- math.random range must start from 1
			local ret, parm_name = GetParamName(obj, fx_idx, rnd, '')
				if build_6_37 then
				ret, ident = r.TrackFX_GetParamIdent(obj, fx_idx, rnd)
				end
			local stock = parm_name == 'Bypass' or parm_name == 'Wet' or build_6_37 and parm_name == 'Delta' -- excluding 3 stock parameters because they're not unique to a plugin
				if parm_t[rnd] or parm_ident_t[rnd] or stock then -- prevent storing the same param several times if math.random generates the same number, and storing stock params
					repeat
					rnd = math.random(1, src_parm_cnt)-1
					ret, parm_name = GetParamName(obj, fx_idx, rnd, '')
					until not parm_t[rnd] and not parm_ident_t[rnd]
					and parm_name ~= 'Bypass' and parm_name ~= 'Wet'
					and (not build_6_37 or parm_name ~= 'Delta')
				end
			parm_t[rnd], parm_ident_t[rnd] = parm_name, ident -- store
			end
			-- compare collected parameter data with temp fx parameters
			for parm_idx, name in pairs(parm_t) do
			local ident
			local retval, parm_name = r.TrackFX_GetParamName(temp_track, 0, parm_idx, '') -- fx_idx 0
				if build_6_37 then
				retval, ident = r.TrackFX_GetParamIdent(temp_track, 0, parm_idx)
				end
				if name ~= parm_name or parm_ident_t[parm_idx] and parm_ident_t[parm_idx] ~= ident then
				-- break rather than return to allow deletion of the temp track
				-- before returning the value
				name_match = false break
				end
			end
		end
	end

r.DeleteTrack(temp_track)
r.PreventUIRefresh(-1)

return name_match

end



function Import_Item_To_RS5k(item, track, rs5k_idx, item_idx) -- doesn't set sample Mode and doesn't map to a keyboard key

RESPECT_ITEM_PITCH = RESPECT_ITEM_PITCH:match('%S')
RESPECT_ITEM_VOLUME = RESPECT_ITEM_VOLUME:match('%S')
RESPECT_ITEM_BOUNDS = RESPECT_ITEM_BOUNDS:match('%S')

local is_source_looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1
local take = r.GetActiveTake(item)
local pitch_shift = RESPECT_ITEM_PITCH and r.GetMediaItemTakeInfo_Value(take, 'D_PITCH') or 0 -- in semitones
local env = r.GetTakeEnvelopeByName(take, 'Pitch')
local pitch_env_val = 0
	if env and RESPECT_ITEM_PITCH then -- pitch of only the 1st point in the envelope is respected
	local retval, time, pitch, shape, tens, is_sel = r.GetEnvelopePointEx(env, -1, 0)
	pitch_env_val = pitch
	end

-- get original media source to calculate unit for convertion of item boundaries into region boundaries within RS5k
local src = r.GetMediaItemTake_Source(take)
src = r.GetMediaSourceParent(src) or src -- in case the item is a section or a reversed source; if item is a section the next function will return actual item length rather than the source's, hence unsuitable for unit calculation (for which full source length is required) neither suitable for file name retrieval and parent source must be retrieved
-- convert source length to sample region units used in rs5k (0 - 1)
local len_src, is_lengthInQN = r.GetMediaSourceLength(src)
local unit = 1/len_src

local file_name = r.GetMediaSourceFileName(src, '')

local src = r.GetMediaItemTake_Source(take) -- re-initialize to get the actual length of the section in Arrange, if any, rather than the source's which was retrieved above for the sake of unit calculation
local is_sect, start_offset_sect, len_sect, is_reversed = r.PCM_Source_GetSectionInfo(src) -- works for both section and full source

local start_offset_take = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') -- negative if start is extended beyond a non-looped source
local take_playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local len_item = r.GetMediaItemInfo_Value(item, 'D_LENGTH')*take_playrate
local vol_item = r.GetMediaItemInfo_Value(item, 'D_VOL')
local vol_item_dB = 20*math.log(vol_item,10)
local vol_take = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
local vol_take_dB = 20*math.log(vol_take,10)
local vol = RESPECT_ITEM_VOLUME and 10^((vol_item_dB + vol_take_dB)/20) or 1
-- val and dB conversion forumula from SPK77
-- https://forum.cockos.com/showthread.php?p=1608719

-- When item is looped only the very first iteration, which can be partial due to trim, is translated into RS5k sample area
-- Enabling reverse in Item Properties turns item into section even when Section option isn't explicitly checkmarked
-- After import into RS5k of a reversed item, section or not, trimmed or not, looped or not, the sample region accurately reflects boundaries of the non-reversed source; for original section boundaries to be respected special calculations are required which are pointless because the sample area won't match item playback anyway due to reverse
-- If a non-looped item is untrimmed (trimmed out) from the left, start_offset_take value is negative throwing the region start position off in RS5k since RS5k respects the negative offset, so it must be accounted for

-- Start is either Section: (first field) or 'Start in source' value in the Media Item Properties window; len is either Length (under Position) or Section: Length in Media Item Properties window; accounting for left and right edges trim
local start = not RESPECT_ITEM_BOUNDS and 0 or start_offset_take >= 0 and start_offset_sect + start_offset_take or start_offset_sect -- accounting for extension or trim of the left edge; when item source is looped item's left (and right for that matter) edge can't be extended beyond source, otherwise extension is ignored
local len = is_source_looped and len_item > len_sect - start_offset_take and len_sect - start_offset_take -- item is looped in Arrange
or start_offset_take < 0 and len_item + start_offset_take > len_sect and len_sect -- item is extended beyond its source at the start and at the end
or start_offset_take >= 0 and len_item > len_sect - start_offset_take and len_sect - start_offset_take -- item is extended beyond its source at the end
or start_offset_take < 0 and len_item + start_offset_take -- item is extended beyond its source at the start
or len_sect >= len_item and len_item -- item is or isn't trimmed at either end
len = (len == 0 or not RESPECT_ITEM_BOUNDS) and len_src or len -- if trimmed beyond the source on both sides, ignore trimming

-- https://forum.cockos.com/showpost.php?p=1817782&postcount=5
r.TrackFX_SetNamedConfigParm(track, rs5k_idx, 'FILE'..item_idx, file_name)
r.TrackFX_SetNamedConfigParm(track, rs5k_idx, 'DONE', '')

r.TrackFX_SetParam(track, rs5k_idx, 2, 0) -- 'Gain for minimum velocity' aka 'Min vol' // set to -inf
r.TrackFX_SetParam(track, rs5k_idx, 0, vol) -- 'Volume' // Normalized type of function must not be used since take (and item) volume scale isn't linear
-- no difference between the result of using functions below with or without Normalized
r.TrackFX_SetParamNormalized(track, rs5k_idx, 13, start*unit) -- 'Sample start offset'
-- r.TrackFX_SetParam(track, rs5k_idx, 13, start*unit)
r.TrackFX_SetParamNormalized(track, rs5k_idx, 14, (start+len)*unit) -- 'Sample end offset'
--r.TrackFX_SetParam(track, rs5k_idx, 14, (start+len)*unit)
r.TrackFX_SetParam(track, rs5k_idx, 15, 0.5+(pitch_shift+pitch_env_val)*1/160) -- 'Pitch offset' aka Pitch adjust // starting with 0.5 because pitch has positive and negative ranges and 0.5 represents pitch 0 (middle) in the parameter range of 0-1
end



local sel_itm_cnt = r.CountSelectedMediaItems(0)
local valid_item
	for i=0, sel_itm_cnt-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local take = r.GetActiveTake(item)
		if is_audio_src(take) then
		valid_item = 1
		break end
	end

local err = sel_itm_cnt == 0 and 'no selected items' or not valid_item and 'no selected audio items'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, is_input_fx, is_cont_fx, is_cont = GetFocusedFX()
	if not retval then
	Error_Tooltip('\n\n no focused RS5k \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end

local parm_t = {[11]='Obey note-offs', [19]='Probability of hitting', [26]='Release (note-off)'}
local parm_ident_t = {[11]='11:_Obey_note_offs', [19]='19:_Probability_of_hitting', [26]='26:_Release__note_off_'}
local rs5k = Validate_FX_Identity(take or tr, fx_num, 'ReaSamplOmatic5000', parm_t, parm_ident_t)
--Msg(rs5k)
	if not rs5k then
	Error_Tooltip('\n\n the focused fx is not RS5k \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo)
	end


r.Undo_BeginBlock()

	for i=0, sel_itm_cnt-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local take = r.GetActiveTake(item)
		if is_audio_src(take) then
		Import_Item_To_RS5k(item, tr, fx_num, i)
		end
	end

r.Undo_EndBlock('Import selected items from Arrange to focused RS5k as velocity layers', -1)








