--[[
ReaScript name: BuyOne_Extract frozen FX chains to a new track.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M recommended, not mandatory
Provides: [main=main,midi_editor] .
About:	The new track is created immediately
			above the frozen track whose FX chains
			are being extracted.
--]]


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

	output = gfx.showmenu(menu)
		if output == 0 then return output end -- menu exited

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



local tr = r.GetTrackFromPoint(r.GetMousePosition())
tr = tr or r.GetSelectedTrack(0,0)
local frozen = tr and Is_Track_Frozen(tr) > 0
local err = not tr and 'no track under mouse \n\n\t  or selected' or not frozen and 'the track isn\'t frozen'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local fx_chain_chunk, chain_type_info = Extract_Frozen_FX_Chain(tr)
local abort

	if fx_chain_chunk == 0 then -- menu exited without slection
	abort = 1
	elseif fx_chain_chunk == 'err_mess' then -- track chunk couldn't be retrieved
	Err_mess()
	abort = 1
	elseif not fx_chain_chunk then
	Error_Tooltip('\n\n no frozen fx \n\n', 1, 1) -- caps, spaced true
	abort = 1
	end

	if abort then return r.defer(no_undo) end


r.Undo_BeginBlock()

local idx = r.CSurf_TrackToID(tr, false) -- mcp_view false
r.InsertTrackAtIndex(idx-1, false) -- wantDefaults false to prevent auto-added default fx chain if any // insert above selected track
local tr = r.GetTrack(0, idx-1)
local retval = Apply_FX_Chain_Chunk(tr, fx_chain_chunk) -- recFX ommitted, nil

	if not retval then -- newly inserted track chunk couldn't be retrieved, delete inserted track // unlikely scenario because the track is empty so chunk size is tiny
	r.DeleteTrack(tr)
	end

r.GetSetMediaTrackInfo_String(tr, 'P_NAME', chain_type_info, true) -- is_set true

local obj = chain_type_info:match('track') or 'take'
r.Undo_EndBlock('Extract frozen '..obj..' FX chain to new track', -1)







