--[[
ReaScript name: BuyOne_FX windows - align all open with the focused in the Z-order.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M or js_ReaScriptAPI
Provides: 	[main=main,midi_editor] .
About:	The script is an ancillary to the package
		BuyOne_Focus next;previous FX window_META.lua.
		It places ALL currently open FX windows at the
		top left corner X and Y coordinates of the last
		focused FX window maintaining their current order
		so that they overlay each other in the Z-order,
		thereby making use of scripts spawned by
		BuyOne_Focus next;previous FX window_META.lua
		script make more sense.

		LIMITATIONS

		The script doesn't support floating windows
		of bridged x86 bit plugins on x64 bit systems,
		unless the option Run As -> Embed bridged UI
		in the plugin right click context menu in the
		FX Browser is enabled.

]]


local Debug = ""
function Msg(param, cap) -- caption second or none
	if #Debug:gsub(' ','') > 0 then -- OR Debug:match('%S') // declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local cap = cap and tostring(cap)..' = ' or ''
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
	end
end


local r = reaper



function no_undo()
-- do return end
end


function space(n) -- number of repeats, integer
return (' '):rep(n)
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



-- used in GetFocusedFX()
function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20
local master_tr = r.GetMasterTrack(0)
local mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
local is_mon_fx_float
	if mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
		for i = 0, r.TrackFX_GetRecCount(master_tr) do
			if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
			mon_fx_idx = i; is_mon_fx_float = true break end
		end
	end
return mon_fx_idx, is_mon_fx_float -- expected >= 0, true
end




function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20
-- DUE TO REASCRIPT API BEHAVIOR DOESN'T RETURN TRUTH IMMEDIATELY AFTER IMPORT
-- OF A TRACK TEMPLATE OF AN FX CHAIN PRESET SAVED WITH OPEN FX WINDOWS;
-- IN THIS SCENARIO, IF UI OF THE FX SELECTED IN THE OPEN FX CHAIN
-- IS DISPLAYED IN A FLOATING WINDOW, CLICKING THE FX CHAIN WINDOW
-- DOESN'T MAKE THE FX LAST FOCUSED AND THE FUNCTION STILL RETURNS FALSE

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
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm, GetEnabled, GetOffline = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, r.TakeFX_GetEnabled, r.TakeFX_GetOffline}
		or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetEnabled, r.TrackFX_GetOffline}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num)
		local fx_name = fx_alias
		-- in builds older than 6.31 fx_name return value will be indentical to fx_alias
			if tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.31 then
			local ret
			ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
			-- commented out to keep the entire name
		--	fx_name = fx_name:match('^JS:') and fx_name:match('JS: (.+) %[') -- excluding path
		--	or fx_name:match('^[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor
			end

		local bypassed = not GetEnabled(obj, fx_num)
		local offline = GetOffline(obj, fx_num)
		local input_fx = fx_num >= 0x1000000

		return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0, fx_alias, fx_name, fx_GUID, 	 bypassed, offline, input_fx -- tr_num = -1 means Master;
		end

	else -- supported since v7.0

	local retval, tr_num, itm_num, take_num, fx_num, parm_num = r.GetTouchedOrFocusedFX(1) -- 1 focused mode // parm_num only relevant for querying last touched (mode 0) or if the last focused window is still open, value 1 // supports Monitoring FX and FX inside containers, container itself can also be focused
	local tr = tr_num > -1 and r.GetTrack(0, tr_num) or retval and r.GetMasterTrack(0) -- Master track is valid when retval is true, tr_num in this case is -1
	local item = tr and r.GetTrackMediaItem(tr, itm_num)
	local take = item and r.GetTake(item, take_num)
	local obj = take or tr -- take is first to prevent false positive because when take is valid track is valid as well

		if obj then
		local GetFXName, GetFXGUID, GetIOSize, GetNamedConfigParm, GetEnabled, GetOffline = table.unpack(take and {r.TakeFX_GetFXName, r.TakeFX_GetFXGUID, r.TakeFX_GetIOSize, r.TakeFX_GetNamedConfigParm, r.TakeFX_GetEnabled, r.TakeFX_GetOffline}
		or tr and {r.TrackFX_GetFXName, r.TrackFX_GetFXGUID, r.TrackFX_GetIOSize, r.TrackFX_GetNamedConfigParm, r.TrackFX_GetEnabled, r.TrackFX_GetOffline}) -- take is first to prevent false positive because when take valid track valud as well
		local fx_alias, fx_GUID, is_cont = select(2, GetFXName(obj, fx_num)), GetFXGUID(obj, fx_num), GetIOSize(obj, fx_num) == 8
		local ret, fx_name = GetNamedConfigParm(obj, fx_num, 'fx_name')
		-- commented out to keep the entire name
	--	fx_name = fx_name:match(^'JS:') and fx_name:match('JS: (.+) %[') -- excluding path
	--	or fx_name:match(^'[VSTAUCLPDXi3]+:') and fx_name:match(': (.+)') or fx_name -- if Video processor or Container

		local input_fx = fx_num >= 0x1000000 and fx_num <= 0x2000000 or fx_num-0x2000000 >= 0x1000000 -- or 16777216 instead of 0x1000000 and 33554432 instead of 0x2000000 // TrackFX_GetRecChainVisible() gives false positives because it's valid regardless of the window being focused
		local cont_fx = fx_num >= 33554432 -- or fx_num >= 0x2000000
		local mon_fx = retval and tr_num == -1 and input_fx
		local bypassed = not GetEnabled(obj, fx_num)
		local offline = GetOffline(obj, fx_num)

		return retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, bypassed, offline, input_fx, cont_fx, is_cont -- tr_num = -1 means Master
		end
	end

end



-- used in Collect_Open_FX() and collect_container_fx()
function Get_FX_Type(obj, fx_idx)
-- https://forum.cockos.com/showthread.php?t=277103
local plug_types_t = {[0] = 'DX', [1] = 'LV2', [2] = 'JSFX', [3] = 'VST',
[4] = '', [5] = 'AU', [6] = 'Video processor', [7] = 'CLAP', [8] = 'Container'}
local validate = r.ValidatePtr
local GetIOSize = obj and (validate(obj, 'MediaItem_Take*') and r.TakeFX_GetIOSize
or validate(obj, 'MediaTrack*') and r.TrackFX_GetIOSize)
	if GetIOSize then
--Msg(fx_idx, type(fx_idx))
	local plug_type, inputPins_cnt, outputPins_cnt = GetIOSize(obj, fx_idx)
	return plug_types_t[plug_type]
	end
end



-- used in collect_container_fx()
function Collect_All_Container_FX_Indices(obj, t, recFX, parent_cntnr_idx, parents_fx_cnt)
-- creates table containing indices of fx inside containers in nested tables
-- following container hierarchy;
-- obj is track or take, t must be nil, recFX is boolean to target input/Monitoring FX,
-- parent_cntnr_idx, parents_fx_cnt must be nil
-- fx indices from the outermost fx chain (the object main fx chain) are of course stored as well
-- see Loop_Over_FX_Container_Table() next

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

local FXCount, GetIOSize, GetConfig = table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetIOSize,
r.TrackFX_GetNamedConfigParm} or take and {r.TakeFX_GetCount, r.TakeFX_GetIOSize,
r.TakeFX_GetNamedConfigParm} or {})

local fx_cnt = not parent_cntnr_idx and (recFX and r.TrackFX_GetRecCount(obj) or FXCount(obj))
fx_cnt = fx_cnt or ({GetConfig(obj, parent_cntnr_idx, 'container_count')})[2]

local t = t or {} -- add table for the outermost FX chain on the very first run

--[-[ LOOP COMBINING TWO LOOPS BELOW INTO ONE, UNTESTED
	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	local retval, cont_fx_cnt = GetConfig(obj, i, 'container_count') -- retval true even if container is empty
		if GetIOSize(obj, i) == 8 and cont_fx_cnt+0 > 0 then -- non-empty container
		t[#t] = {i, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and i or 0x2000000+i+1 -- 0x2000000 is only added once, to the index of the outermost parent container
		local parents_fx_cnt = (parents_fx_cnt or 1) * (fx_cnt+1) -- fx_cnt is fx count in the parent container
		-- the function must not return table here, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[#t][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end
--]]

--[[
	-- collect all fx instances in a chain, including containers
	for i = 0, fx_cnt-1 do
	local i = not parent_cntnr_idx and recFX and i+0x1000000 or i
	i = parent_cntnr_idx and (i+1)*parents_fx_cnt+parent_cntnr_idx or i
	t[#t+1] = i
	end

	-- search for containers in the fx chain data stored above
	-- and if found go recursive to collect fx instances inside them
	for i, fx_idx in ipairs(t) do
	local container = GetIOSize(obj, fx_idx) == 8
	local retval, cont_fx_cnt = GetConfig(obj, fx_idx, 'container_count') -- retval true even if container is empty
		if container and cont_fx_cnt+0 > 0 then -- non-empty container
		t[i] = {fx_idx, {}} -- replace container index with a nested table containing its index and another nested table to collect indices of fx inside it
		local parent_cntnr_idx = parent_cntnr_idx and fx_idx or 0x2000000+fx_idx+1 -- 0x2000000 is only added once, to the index of the outermost parent container
		local parents_fx_cnt = (parents_fx_cnt or 1) * (#t+1) -- #t is equal to fx count in the parent container
		-- the function must not return table here, otherwise its structure will be reversed
		-- starting from the innermost fx chain with no way to get higher
		-- the table is the same throughout the entire recursive loop anyway
		Collect_All_Container_FX_Indices(obj, t[i][2], recFX, parent_cntnr_idx, parents_fx_cnt) -- go recursive // t[i][2] is the address of the nested table for collecting container fx indices
		end
	end

--]]

return t

end



-- used in collect_container_fx()
function Loop_Over_FX_Container_Table(obj, t, t2)
-- obj is track or take, t is the table returned by Collect_All_Container_FX_Indices() above

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Floating = take and r.TakeFX_GetFloatingWindow or r.TrackFX_GetFloatingWindow

	-- target fx instances in a chain ignoring containers
	for k, fx_idx in ipairs(t) do
		if tonumber(fx_idx) then -- fx instance // if container, evaluation will be false since the value is a table
		local wnd = Floating(obj, fx_idx)
			if wnd then
			t2[#t2+1], t2[wnd] = wnd, '' -- dummy entries are stored to be able to get windows count for error message generation
			end
		end
	end
	-- target containers, ignoring fx instances
	for k, cont in ipairs(t) do
		if not tonumber(cont) then -- a table storing container index and its fx list
		local wnd = Floating(obj, cont[1])
			if wnd then
			t2[#t2+1], t2[wnd] = wnd, '' -- dummy entries are stored to be able to get windows count for error message generation
			end
		Loop_Over_FX_Container_Table(obj, cont[2], t2) -- go recursive to loop over container fx, cont[2] is the address of the nested table with container fx indices list, at cont[1] container own index is stored
		end
	end

end



-- used in Collect_Open_FX()
function collect_container_fx(obj, cont_idx, recFX, t)

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local Count, Get_Parm, Floating = table.unpack(take and {r.TakeFX_GetCount,r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFloatingWindow} or tr and {recFX and r.TrackFX_GetRecCount or r.TrackFX_GetCount,  r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFloatingWindow})

local build = tonumber(r.GetAppVersion():match('[%d%.]+'))

	if build >= 7 and build < 7.06 then
	local cont_fx_t = Collect_All_Container_FX_Indices(obj, _, recFX, 0x2000000+cont_idx+1, Count(obj)+1)
	Loop_Over_FX_Container_Table(obj, cont_fx_t, t)
	elseif build >= 7.06 then
	local ret, count = Get_Parm(obj, cont_idx, 'container_count')
		if count == '0' then return end
		for i=0, count-1 do
		local ret, fx_idx = Get_Parm(obj, cont_idx, 'container_item.'..i)
		fx_idx = fx_idx+0
		local wnd = Floating(obj, fx_idx)
			if wnd then
			t[#t+1], t[wnd] = wnd, '' -- dummy entries are stored to be able to get windows count for error message generation
			end
			if Get_FX_Type(obj, fx_idx) == 'Container' then -- go recursive
			collect_container_fx(obj, fx_idx, recFX, t)
			end
		end
	end

end



function Collect_Open_FX()

	local function collect_take_fx(t, tr)
	local Count, Get = table.unpack(tr and {r.CountTrackMediaItems, r.GetTrackMediaItem} or {r.CountMediaItems, r.GetMediaItem})
		for itm_idx=0, Count(tr or 0)-1 do
		local item = Get(tr or 0, itm_idx)
			for take_idx=0, r.CountTakes(item)-1 do
			local take = r.GetTake(item, take_idx)
			local chain_vis_idx = r.TakeFX_GetChainVisible(take) ~= -1
				if chain_vis_idx then t[#t+1] = '' end -- dummy entry to signal that there's open fx chain window
				for i=0, r.TakeFX_GetCount(take)-1 do
				local wnd = r.TakeFX_GetFloatingWindow(take, i)
					if wnd then
					t[#t+1], t[wnd] = wnd, '' -- dummy entries are stored to be able to get windows count for error message generation
					end
					if Get_FX_Type(take, i) == 'Container' then
					collect_container_fx(take, i, recFX, t) -- recFX nil
					end
				end
			end
		end
	end


local t = {}

	for tr_idx=-1, r.CountTracks(0)-1 do -- start from -1 to accommodate master track
	local tr = r.GetTrack(0,tr_idx) or r.GetMasterTrack(0)
	local chain_vis_idx = r.TrackFX_GetChainVisible(tr) ~= -1
		if chain_vis_idx then t[#t+1] = '' end -- dummy entry to signal that there's open fx chain window
		for i=0, r.TrackFX_GetCount(tr)-1 do
		local wnd = r.TrackFX_GetFloatingWindow(tr, i)
			if wnd then
			t[#t+1], t[wnd] = wnd, '' -- dummy entries are stored to be able to get windows count for error message generation
			end
			if Get_FX_Type(tr, i) == 'Container' then
			collect_container_fx(tr, i, recFX, t) -- recFX nil
			end
		end
		-- input fx windows
	local chain_vis_idx = r.TrackFX_GetRecChainVisible(tr) ~= -1 -- the function returns regular index
		if chain_vis_idx then t[#t+1] = '' end -- dummy entry to signal that there's open fx chain window
		for i=0, r.TrackFX_GetRecCount(tr)-1 do
		local wnd = r.TrackFX_GetFloatingWindow(tr, i+0x1000000)
			if wnd then
			t[#t+1], t[wnd] = wnd, ''
			end
			if Get_FX_Type(tr, i) == 'Container' then
			collect_container_fx(tr, i, 1, t) -- recFX 1 true
			end
		end
	-- take fx windows
	collect_take_fx(t, tr)
	end

return t

end




-- used in Concat_Container_FX_Wnd_Title()
function Get_FX_All_Parent_Container_Names(obj, fx_idx)
-- supported since build 7.06
-- return table where container names are listed in descending order
-- i.e. from the innermost to the outermost

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

	if fx_idx+0 > 0x2000000 and (tr or take) then -- range fx inside containers, or > 33554432
	local GetConfigParm, GetName, GetEnabled =
	table.unpack(tr and {r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFXName, r.TrackFX_GetEnabled}
	or take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFXName, r.TakeFX_GetEnabled})
	local t, retval = {}
		repeat
		retval, fx_idx = GetConfigParm(obj, fx_idx, 'parent_container')
			if retval then
			local ret, name = GetName(obj, fx_idx+0, '')
			local bypassed = not GetEnabled(obj, fx_idx+0)
		--	table.insert(t, 1, fx_idx+0)
			t[#t+1] = name..(bypassed and ' [BYPASSED]' or '')
			end
		until not retval -- or #fx_idx == 0
	return t, fx_idx
	end

end



-- used in Concat_Container_FX_Wnd_Title()
function Get_Regular_Cont_FX_Index(obj, fx_idx)
-- retrieve regular 1-based index of fx inside container
-- supported since build 7.06

local fx_idx = fx_idx and fx_idx+0 -- convert to integer just in case

	if fx_idx < 0x2000000 then return fx_idx end -- not fx inside container

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
GetConfigParm = take and r.TakeFX_GetNamedConfigParm or tr and r.TrackFX_GetNamedConfigParm
local ret, parent_cont_idx = GetConfigParm(obj, fx_idx, 'parent_container')
local ret, cont_fx_cnt = GetConfigParm(obj, parent_cont_idx+0, 'container_count')

	for i=0, cont_fx_cnt-1 do
	local ret, idx = GetConfigParm(obj, parent_cont_idx+0, 'container_item.'..i)
		if idx+0 == fx_idx then return i+1, cont_fx_cnt+0 end -- converting to 1-based index and to integer
	end

end



function Concat_Container_FX_Wnd_Title(obj, obj_name, tr_idx, fx_idx, fx_name, fx_bypassed, input_fx)
-- the title pattern of a floating window of fx inside container or child container (without angle brackets and NOT ALL CAPS):
-- <BYPASSED -><FX INSTANCE NAME> - <PARENT CONTAINER NAME [BYPASSED]> / <NEXT CONTAINER NAME> / <OUTERMOST CONTAINER NAME> / TRACK <INDEX> <"NAME"> or ITEM <"NAME"> [BYPASSED] [<1-BASED FX INDEX>/<TOTAL FX COUNT INSIDE CONTAINER>]
-- 'BYPASSED -' precedes target fx name if it's bypassed, [BYPASSED] follows name of any bypassed parent container
-- if track, track name in quotes follows track index if track name isn't empty;
-- if master track, 'Master Track' appendage appears instead of Track <index>;
-- if monitoring fx, 'Monitoring' appendage appears instead of 'Master Track';
-- if take fx, instead of Track <index> 'Item' with optional take name is added in quotes if take name isn't empty;
-- total count of fx inside container and 1-based index of the current fx are only listed if there're more than 1 fx inside the container;
-- if input fx chain, '(input fx chain)' appendage is tucked between track index and the concluding part in the square brackets if any, doesn't apply to Monitoring chain;
-- if track main fx chain, Master Track chain or Monitoring chain and the chain is bypassed '[BYPASSED]' indicator is tucked between regular track index, 'Master Track' or 'Monitoring' titles and the concluding part in the square brackets if any


	if fx_idx < 0x2000000 then return end -- not fx inside container

	local function concat_wnd_title(obj, obj_name, tr_idx, fx_idx, fx_name, fx_bypassed, input_fx, take, tr)
	local master = r.GetMasterTrack(0) == obj
	local chain_bypassed = master and input_fx and r.GetToggleCommandStateEx(0, 41884) == 1 -- Monitoring FX: Toggle bypass
	or tr and r.GetMediaTrackInfo_Value(obj, 'I_FXEN') == 0
	local t = Get_FX_All_Parent_Container_Names(obj, fx_idx) -- regarding take precendence see comment above
	local fx_idx_reg, cont_fx_cnt = Get_Regular_Cont_FX_Index(obj, fx_idx)
	return (fx_bypassed and 'BYPASSED %- ' or '')..Esc(fx_name)..' %- '
	..(t and table.concat(t, ' / ')..' / ' or '') -- escaping dashes // t will be nil when the parent container happens to be the outermost
	..(master and (not input_fx and 'Master Track' or 'Monitoring') or tr and 'Track '..tr_idx+1 or take and 'Item')
	..((master or #obj_name == 0 and '') or ' "'..Esc(obj_name)..'"')
	..(not master and not take and input_fx and ' %(input FX chain%)' or '')
	..(chain_bypassed and ' %[BYPASSED%]' or '')
	..(cont_fx_cnt and cont_fx_cnt > 1 and ' %['..fx_idx_reg..'/'..cont_fx_cnt..'%]' or '') -- cont_fx_cnt will be nil when the parent container happens to be the outermost
	end

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')

-- since when fx inside a container is focused it's impossible to determine
-- whether it's focused in its own floating window or inside one of its parent container floating windows
-- retrieve data of the first parent container open in a floating window
-- to concatenate its title as well and then evaluate both
local GetConfigParm, GetFXName, GetEnabled, Floating = table.unpack(take and {r.TakeFX_GetNamedConfigParm, r.TakeFX_GetFXName, r.TakeFX_GetEnabled, r.TakeFX_GetFloatingWindow}
or tr and {r.TrackFX_GetNamedConfigParm, r.TrackFX_GetFXName, r.TrackFX_GetEnabled, r.TrackFX_GetFloatingWindow})

local i, parent_cont_idx = 0, fx_idx
	repeat
	local ret
	ret, parent_cont_idx = GetConfigParm(obj, parent_cont_idx, 'parent_container')
		if tonumber(parent_cont_idx) and Floating(obj, parent_cont_idx) then break end
	i=i+1
	until not tonumber(parent_cont_idx) -- OR #parent_cont_idx == ''

local parent_cont_title
	if tonumber(parent_cont_idx) then
	local ret, parent_cont_name = GetFXName(obj, parent_cont_idx)
	local parent_cont_bypassed = not GetEnabled(obj, parent_cont_idx)
	parent_cont_title = concat_wnd_title(obj, obj_name, tr_idx, parent_cont_idx, parent_cont_name, parent_cont_bypassed, input_fx, take, tr)
	end

-- returns titles of fx floating window and its first parent container open in a floating window
return concat_wnd_title(obj, obj_name, tr_idx, fx_idx, fx_name, fx_bypassed, input_fx, take, tr), parent_cont_title

end



function Get_Sibling_Windows(wnd, excl_orig)
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
-- excl_orig is boolean to ignore wnd when collecting data

	if not wnd then return end

local sws, js = r.BR_Win32_GetWindow, r.JS_Window_GetRelated

	if not sws and js then return end

-- get first sibling window
local i, wnd, sibl = 0, wnd
	repeat
	wnd = sws and r.BR_Win32_GetWindow(wnd, 3) -- 3 = GW_HWNDPREV
	or r.JS_Window_GetRelated(wnd, 'PREV')
	sibl = wnd or sibl
	i=i+1
	until not wnd

	if not sibl then return end

local i, t = 0, {}
	repeat
	sibl = sws and r.BR_Win32_GetWindow(sibl, 2) -- 2 = GW_HWNDNEXT
	or r.JS_Window_GetRelated(sibl, 'NEXT')
		if sibl and (excl_orig and sibl ~= wnd or not excl_orig) then
		local ret, txt = table.unpack(sws and {r.BR_Win32_GetWindowText(sibl)} or {nil, r.JS_Window_GetTitle(sibl)}) -- the js extension function only returns a single value so matching to 2 return values of the sws function
--Msg(txt)
		t[#t+1] = {sibl=sibl, title=txt}
	--[[ -- OR, depending on the design
		t[txt] = sibl
	]]
		end
	i=i+1
	until not sibl

return #t > 0 and t

end



function get_greatest_smallest_value(want_smallest, field, ...)
-- vararg is a list of tables, nested tables aren't supported,
-- OR variables containing numbers;
-- field is either integer representing index in an indexed table
-- or string represending field in an associative array,
-- can be nil if variables are passed instead of tables;
-- to evaluate values in nested tables inside several indexed tables
-- this function must be first applied to nested tables,
-- then to the resulting values of all tables;
-- also useful for determining the longest indexed table out of several,
-- to make the function return table pointer along with the value
-- embed the table length in its field, see embed_table_length functions
local t = {...}
	local function select_source(s,field)
	return field and type(s) == 'table' and s[field] or s
	end
table.sort(t, function(a,b) local a, b = select_source(a,field), select_source(b,field)
return want_smallest and a < b or not want_smallest and a > b end)
local tbl = type(t[1]) == 'table' -- 1 because due to sorting the target field will end up at index 1
return field and tbl and t[1][field] or t[1], field and tbl and t[1] -- return value and the table it belongs to if table values were sorted
end



Error_Tooltip('') -- clear any lingering tooltip

local sws, js = r.BR_Win32_SetWindowPos, r.JS_Window_SetPosition
local master = r.GetMasterTrack(0)
local err = r.GetNumTracks() == 0 and r.TrackFX_GetCount(master) + r.TrackFX_GetRecCount(master)== 0
and space(4)..'no tracks in the project \n\n and no fx on the master track'
or not sws and not js and 'extensions aren\'t installed'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

-- the native focus functions ignore FX selected in the FOCUSED FX chain
-- but whose UI is open in the NON-FOCUSED floating window
-- they return props of the last focused fx instead
local retval, tr_num, tr, itm_num, item, take_num, take, fx_num, mon_fx, fx_alias, fx_name, fx_GUID, bypassed, offline, is_input_fx, is_cont_fx, is_cont = GetFocusedFX() -- SINCE THE SCRIPT RELIES SOLELY ON EXTENSIONS TO ALIGN WINDOWS THIS FUNCTION COULD HAVE BEEN DISPENSED WITH AND THE FOREGROUND (REFERENCE) FX WINDOW COULD HAVE BEEN SEARCHED FOR IN THE TABLE RETURNED BY Get_Sibling_Windows() FUNCTION, WHERE THE 1ST FX WINDOW WOULD BE IT AS THE ONE HAVING THE LOWEST INDEX IN THE ORDER

-- GetFocusedFX() doesn't return truth immediately after import
-- of a track template of an fx chain preset saved with open fx windows;
-- if the template/preset was saved with open fx chain window
-- and a foreground floating window of an fx belonging to such chain,
-- after import it's the open fx chain window which will end up being in the foreground;
-- in this scenario, if UI of the fx selected in the open fx chain
-- is displayed in a floating window, clicking the fx chain window
-- doesn't make the fx last focused and the function still returns false
local open_wnds_t = Collect_Open_FX() -- only includes fx floating windows, not fx chain windows, and only fx not inside containers

	if not retval then
		if #open_wnds_t > 0 then
		r.MB(space(10)..'The currently open FX windows don\'t seem\n\n'
		..space(11)..'to have ever been focused in this session.\n\n'
		..space(4)..'To proceed click on any FX window displaying a UI.', 'ERROR', 0)
		else
		Error_Tooltip('\n\n no (last) focused fx window \n\n', 1, 1) -- caps, spaced true
		end
	return r.defer(no_undo)
	end


-- get last focused fx window even if it's not currently active
-- and inaccessible to GetForegroundWindow()
-- so that the script can be successfully executed by click as well
-- in which case active window will be different from the last focused fx window
-- and GetForegroundWindow() will return an irrelevant handle so not suitable

-- 3 levels of earch are employed, for focused fx chain window, floating window of fx in the main chain,
-- and floating window of fx inside a container

local GetFloatingWnd, GetName, GetChainVis = table.unpack(take and {r.TakeFX_GetFloatingWindow, r.GetSetMediaItemTakeInfo_String, r.TakeFX_GetChainVisible}
or {r.TrackFX_GetFloatingWindow, r.GetSetMediaTrackInfo_String, not mon_fx and not is_input_fx and r.TrackFX_GetChainVisible or r.TrackFX_GetRecChainVisible}) -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive

local _7_06 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 7.06
local chain_open = GetChainVis(take or tr) > -1 -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive
-- ONLY USED WHEN NOT CONTAINER FX BECAUSE SINCE GetFocusedFX() DOESN'T RETURN INDEX OF CONTAINER OPEN IN A FLOATING WINDOW WHERE FX IS SELECTED WHOSE OWN UI IS OPEN IN A FLOATING WINDOW, GetFloatingWnd() WHEN PASSED INDEX OF SUCH FX WILL RETURN THE HANDLE OF THE FX FLOATING WINDOW WHICH DOESN'T NECESSARILY OCCUPY THE FOREGROUND IN THE Z-ORDER AND THUS WILL STEER THE SCRIPT LOGIC IN THE WRONG DIRECTION, Concat_Container_FX_Wnd_Title() below provides a reliable alternative
local floating_wnd = not is_cont_fx and not offline and GetFloatingWnd(take or tr, fx_num) -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive // offline fx cannot be dispayed in a floating window


-- if the focused fx is selected in the fx chain and its UI is displayed in a floating window
-- GetFocusedFX() won't be enough to determine which window is actually last focused,
-- so get the fx chain window by its title and then determine which of the two windows
-- is relatively higher (closer to the foreground) in the Z-order
-- having collected all siblings of the REAPER main window
-- with Get_Sibling_Windows() below;
-- construct title of the fx chain window,
-- there's a glitch of take name not being updated in the take FX chain window
-- after undo https://forum.cockos.com/showthread.php?t=310418
-- so as an edge case it's possible that focused take FX chain window won't be found
-- based on the constructed name
local ret, name = GetName(take or tr, 'P_NAME', '', false) -- is_set false
local master = r.GetMasterTrack(0) == tr
local chain_bypassed = not take and (not is_input_fx and r.GetMediaTrackInfo_Value(tr, 'I_FXEN') == 0
or master and is_input_fx and r.GetToggleCommandStateEx(0, 41884) == 1) -- Monitoring FX: Toggle bypass
local parent = take and '' or r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1 and ' (folder)' or ''
local focused_chain_name = chain_open and 'FX: '
..(take and 'Item' or master and (not is_input_fx and 'Master Track' or 'Monitoring') or 'Track' or '')
..(not take and not master and ' '..tr_num+1 or '')..parent
..(#name > 0 and (take or not master) and ' "'..name..'"' or '')
..(not take and is_input_fx and not master and ' (input FX chain)' or '')
..(chain_bypassed and ' [BYPASSED]' or '')

local cont_fx_float_wnd_name, cont_fx_parent_cont_float_wnd_name
	-- if focused fx is fx inside a container, concatenate its window name
	-- as well as window name of its first parent container open in a floating window (if any)
	-- to be able to search them by name among sibling windows returned by Get_Sibling_Windows()
	-- because if the fx UI is displayed within a container open in a floating window it won't be found
	-- among siblings by the window handle which won't be returned by GetFloatingWnd()
	-- to which index of actual focused fx (rather than of the parent container)
	-- that itself isn't floating would be passed, that's why for container fx
	-- focused fx floating window isn't evaluated as unreliable
	if is_cont_fx and not floating_wnd and not offline and _7_06 then -- offline fx cannot be dispayed in a floating window // 'not floating_wnd' condition is redundant here because handle of the focused fx floating window isn't used to find it in the window list
	cont_fx_float_wnd_name, cont_fx_parent_cont_float_wnd_name = Concat_Container_FX_Wnd_Title(take or tr, name, tr_num, fx_num, fx_alias, bypassed, mon_fx or is_input_fx) -- take takes precedence because when take is valid track is valid as well and being placed first will produce false positive // returns escaped names
	end


local sibling_t = Get_Sibling_Windows(r.GetMainHwnd()) -- collect all siblings of the main program window, among which both FX chain and FX floating windows are included and among which focused fx floating window, if any, will be searched for // non-embedded windows of bridged x86 bit plugins aren't supported because when the script is run with a click or some other window is brought into focus with the mouse they auto-close on click and when the script is run with a shortcut and such window is focused it won't pass through the shortcut with global + text fields scope to the REAPER window to trigger the script

-- TASK 1:
-- search for the fx chain window handle in the array of the main window siblings
-- to be able to then compare its position in the Z-order relative to the fx floating window (if valid)
-- and obtain the coordinates of the actual last focused window
-- which will be used as target coordinates for all other windows to move to;
-- since Get_Sibling_Windows() collects windows using 2 (GW_HWNDNEXT) argument
-- the lower the index the heigher (closer to the foreground) the window is in the Z-order
-- TASK 2:
-- IF FOCUSED WINDOW IS DOCKED, WHEN ALIGN LOOP IS EXECUTED FURTHER BELOW, ALL OTHER WINDOWS DISAPPEAR
-- AND TO RE-INITIALIZE THEM, OBJECT FX CHAIN MUST BE RE-OPENED, SO THIS BEHAVIOR HAS TO BE PREVENTED;
-- docked FX window, which can only be FX chain window, is a CHILD of the main REAPER window
-- so it won't be included in sibling_t table and thus cannot be evaluated with DockIsChildOfDock(),
-- so verify whether open fx chain window associated with the focused fx is docked by finding
-- if focused_chain_name concatenated above is included in sibling_t

-- if fx is focused in the open fx chain and fx chain window title isn't found in sibling_t
-- it is docked and focused_wnd will end up being nil below;
-- if fx chain window where the focused fx is selected is docked
-- and the focused fx itself is open in a floating window,
-- only the floating window will be found in sibling_t table loop below
-- so comparison between positions of the two in order to determine the foreground
-- window won't be necessary, because the only valid window found in the loop
-- will be the floating window

-- TASK 1
local focused, pos1, pos2, pos3 = {}, math.huge, math.huge, math.huge
local focused_chain_docked = chain_open -- initialize as true
	for k, t in ipairs(sibling_t) do
		if chain_open and t.title:match(Esc(focused_chain_name)) then -- fx chain window
		focused[k], pos1 = t.sibl, k
		focused_chain_docked = nil -- reset, because if fx chain window title is found in sibling_t table it's not a child of the main REAPER window so cannot be docked
		elseif cont_fx_float_wnd_name then
		-- either floating window of fx inside container or floating window of its parent container,
		-- doing both because using ReaScript API it's impossible to determine
		-- which window it is when fx inside container is focused, FX_GetFloatingWindow() doesn't support these
			if t.title:match(cont_fx_float_wnd_name) then
			focused[k], pos2 = t.sibl, k
			end
			if cont_fx_parent_cont_float_wnd_name and t.title:match(cont_fx_parent_cont_float_wnd_name) then
			focused[k], pos3 = t.sibl, k
			end
		elseif t.sibl == floating_wnd then -- fx floating window
		focused[k], pos2 = floating_wnd, k
		end
	end


-- TASK 2
-- Determine which window out of possible focused fx window candidates is the closest to the foreground
local focused_wnd = focused[get_greatest_smallest_value(1, nil, pos1, pos2, pos3)] -- want_smallest true // the lower the index the heigher (closer to the foreground) the window is in the Z-order

	if not focused_wnd and focused_chain_docked then
	Error_Tooltip('\n\n focused fx window is docked. \n\n'
	..space(5)..'aligning other windows \n\n'
	..space(13)..'is impossible \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end


local GetWndCoord = sws and r.BR_Win32_GetWindowRect or r.JS_Window_GetRect
local retval, X, Y = GetWndCoord(focused_wnd)

local open_t, found = {}

	for i=#sibling_t,1,-1 do -- in reverse to preserve original Z-order, because in ascending order windows with greater index end up closer to the foreground after their position is set despite being farther from it in the original Z-order
	local t = sibling_t[i]
		-- WINDOW TITLES ARE NOT GUARANTEED TO INCLUDE PLUGIN ARCHITECTURE PREFIX
		-- BECAUSE THE INSTANCES CAN BE RENAMED BY THE USER;
		-- HOWEVER SEARCHING BY WINDOW TITLE IS THE ONLY WAY TO TARGET WINDOWS OF FX INSIDE CONTAINERS
		if t.title:match('^FX: ') --  fx chain window
		-- fx floating windows
		or t.title:match('^VST.-: ')
		or t.title:match('^JS: ') or t.title:match('^AU.-: ')
		or t.title:match('^LV2.-: ') or t.title:match('^CLAP.-: ')
		or t.title:match('^DX.-: ')
		or t.title:match('^Container %- ')
		or open_wnds_t[t.sibl] -- matches handle of the floating window stored with Collect_Open_FX() regardless of the title // including these here rather than in a separate loop is important for preserving original Z-order when moving // may be unnecessary because all the patterns above and below cover all window title patterns
		-- options for windows of fx whose instance name was changed
		or t.title:match('%(input FX chain %)') or t.title:match('^BYPASSED %-')
		or t.title:match('%- .+/ Track %d+') or t.title:match('%- .+/ Master Track')
		or t.title:match('%- .+/ Monitoring') or t.title:match('%- .+/ Item ')
		-- options for title of the outermost parent container floating window
		-- which will be included in sibling_t BUT WILL ALSO in the table returned by Collect_Open_FX()
		-- as being a floating window of fx in the main chain, which nevertheless doesn't cause conflict
		or t.title:match('%- Track %d+') or t.title:match('%- Master Track')
		or t.title:match('%- Monitoring') or t.title:match('%- Item ')
		then
		found = found or t.sibl ~= focused_wnd -- store handle of at least 1 window which isn't the focused one
		open_t[#open_t+1] = t.sibl
		end
	end

	-- align loop
	if found then -- only move windows if there's at least one window bsides the focused one to prevent the latter becoming focused when it's the only one open fx window and a not focused window
		for k, wnd in ipairs(open_t) do
		local retval, R, T, L, B = GetWndCoord(wnd)
			if sws then
			r.BR_Win32_SetWindowPos(wnd, '', X, Y, L-R, B-T, 0)
			elseif js then
			r.JS_Window_SetPosition(wnd, X, Y, L-R, B-T)
			end
		end
	else
	Error_Tooltip('\n\n no other open fx windows \n\n', 1, 1) -- caps, spaced true
	end

do return r.defer(no_undo) end



