--[[
ReaScript name: BuyOne_Insert automation item on selected envelope at selected items on the same track.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.1
Changelog: v1.1 #Added support for getting envelope under mouse cursor if SWS extension is installed
		#Fixed error when the first one of multiple selected items happens to not belong to 
		the same track as the envelope
		#Updated About text, USER SETTINGS description
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
About: 	The script creates automaion items (AI) of the same length as each
	of selected media items. The selected media items and the selected 
	envelope must belong to the same track. If media items on different 
	tracks are selected, only the parent track of the 1st selected item 
	will be respected.
	
	If the SWS/S&M extension is installed the envelope doesn't have to 
	be selected as long as the mouse cursor points at it. In this case
	automation items are inserted under the selected items in a single
	script execution.
	
	If the SWS/S&M extension isn't installed or the script isn't run with
	a shortcut which doesn't allow free movement of the mouse cursor, then
	the script should be executed in two steps since making media items 
	and envelope selected at the same time isn't very convenient or 
	intuitive in REAPER:
	
	STEP 1
	1. Make item selection.
	2. Run the script to store selected items.
	
	STEP 2
	1. Select envelope on the items track.
	2. Run the script to insert automation items.
	
	Or do this in reverse, first select an envelope, store it, then select
	media items and run the script to insert AIs. The first option is more
	convenient if you're going to create pooled AIs, because when the pool
	source AI gets selected the envelope gets selected along with it. When 
	it's items which have to be selected at STEP 2 to keep the pool source 
	AI selected Ctrl/Cmd or Shift keys must be held down.
	
	The data stored in STEP 1 is kept in the buffer until STEP 2 is 
	executed or as long as the time specified in the STORAGE_TIME 
	setting of the USER SETTINGS hasn't elapsed.
	
	If you changed your mind after executing STEP 1 and need to clear 
	the buffer to correct the selection, deselect all items if envelope 
	was stored or deselect envelope if items were stored and run the script
	in which case you'll be presented with a dialogue to clear the buffer.
	
	As long as the stored data is in the buffer the toobar button or a menu 
	item the script is linked to will be lit or checkmarked respectively.
	
	The script stores media item or envelope indices therefore if between 
	the script execution steps items or envelope order changes the AI will
	be inserted on a different envelope and under different media items
	than the ones which were selected originally.
	
	If there's a selected AI on the selected envelope, the newly inserted AI 
	will be its pooled copy, otherwise it will be an independent non-pooled AI. 
	When a pooled copy is created if there're envelope points at the location 
	where the new AI is inserted these will be preserved and the AI will be placed 
	over them. Only the first selected AI is treated as a pool source for the
	new AI. The pooled copy is stretched or shrunk to fit item length if necessary.
	If a non-pooled AI is created, the existing envelope points, if any, will 
	be absorbed into it instead.
	
	Whether the newly inserted AI overwrites any AI present at the location it's 
	inserted at or whether it's inserted on top of it on a new AI lane depends 
	on the option  
	'Options: Trim content behind automation items when editing or writing automation'
	
	However if as a result of insertion of the new AI the pool source AI is going
	to be trimmed due to overlap, the above option won't affect the pool source AI 
	even if enabled and the pooled AI will be inserted on another AI lane.
			
	Without pooling and only for a single item at a time the same operation can be 
	realized as a custom action:
	
	Custom: Insert AI on selected envelope at selected item 
	(select item, use Ctrl+Shift+click to select envelope)
	  Time selection: Set time selection to items
	  Envelope: Insert automation item
	  Time selection: Remove (unselect) time selection

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert time in seconds
-- of how long the selected items or envelope
-- data must be kept in the buffer before
-- the main action (step 2) is executed;
-- if empty or invalid, defaults to 60 sec;
-- only relevant when the script is executed
-- in 2 steps
STORAGE_TIME = ""

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


function Show_Menu_Dialogue(menu)
-- before build 6.82 gfx.showmenu didn't work on Windows without gfx.init
-- https://forum.cockos.com/showthread.php?t=280658#25
-- https://forum.cockos.com/showthread.php?t=280658&page=2#44
local old = tonumber(r.GetAppVersion():match('[%d%.]+')) < 6.82
local init = old and gfx.init('', 0, 0)
-- open menu at the mouse cursor
gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y
return gfx.showmenu(menu)
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


function space(n) -- number of repeats, integer
local n = not n and 0 or tonumber(n) and math.abs(math.floor(n)) or 0
return string.rep(' ',n)
-- OR
-- return (' '):rep(n)
end


function Is_Env_Visible(env)
	if r.CountEnvelopePoints(env) > 0 then -- validation of fx envelopes
	local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
	return env_chunk:match('\nVIS 1 ')
	end
end


local is_new_value, fullpath, sectionID, cmdID, mode, resolution, val = reaper.get_action_context()
local namedID = r.ReverseNamedCommandLookup(cmdID)

local data = r.GetExtState(namedID, 'DATA')
local storage_time = data:match('time:(.-) ')
STORAGE_TIME = STORAGE_TIME:gsub('[%s%-]','') -- removing spaces and minus
STORAGE_TIME = tonumber(STORAGE_TIME) or 60 -- default to 60 sec if not set or malformed

local sel_item = r.GetSelectedMediaItem(0,0)
local sel_env = r.GetSelectedTrackEnvelope(0)

local sws = r.APIExists('BR_GetMouseCursorContext_Envelope')
local wnd, segm, details = table.unpack(sws and {r.BR_GetMouseCursorContext()} or {}) -- must come before BR_GetMouseCursorContext_Envelope() because it relies on it
local env, takeEnv = table.unpack(sws and {r.BR_GetMouseCursorContext_Envelope()} or {})
sel_env = env or sel_env
local err = '    take envelopes don\'t \n\n support automation items'
err = not sel_item and (sws and (takeEnv and err
or not sel_env and '\t  no track envelope \n\n under the mouse or selected \n\n\tand no selected items')
or not sel_env and ' no selected items\n\n or track envelope') or sel_item and takeEnv and err

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

	if env then -- sws extension is installed and envelope under mouse

	data = 'mouse' -- dummy data just to be able to activate AI creation routine in a scenario when there's envelope under mouse cursor

	else -- STEP 1

		if #data > 0 and storage_time and #storage_time > 0
		and r.time_precise()-storage_time >= STORAGE_TIME -- clear data, reset toggle state
		then

		r.DeleteExtState(namedID, 'DATA', true) -- persist true
		Error_Tooltip('\n\n\tthe data has expired \n\n repeat the data storage step \n\n', 1, 1) -- caps, spaced true
		local toggle = r.GetToggleCommandStateEx(sectionID, cmdID)
			if toggle == 1 then r.SetToggleCommandState(sectionID, cmdID, 0) end

		return r.defer(no_undo)

		elseif #data == 0 then

			if sel_item then
			-- only respect selected items on the same track as the first selected one
			local tr = r.GetMediaItemTrack(sel_item)
			local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
				for i = 0, r.GetTrackNumMediaItems(tr)-1 do
				local item = r.GetTrackMediaItem(tr, i)
					if r.IsMediaItemSelected(item) then	-- storing track item idex, alternatively their pointers or GUIDs could be stored to account for possible reorder/removal between script runs, but not sure it's a compelling enough reason
					data = (#data == 0 and data..'tr:'..tr_idx..' items:' or data)..i..',' -- only storing track idx once
					end
				end
			elseif sel_env then
			local tr = r.GetEnvelopeInfo_Value(sel_env, 'P_TRACK')
				for i = 0, r.CountTrackEnvelopes(tr)-1 do
				local env = r.GetTrackEnvelope(tr, 0)
				local env = r.CountEnvelopePoints(env) > 0 and env -- validate because in REAPER builds before 7.06 fx param envelopes are valid if param modulation is enabled without any actual envelope, such ghost envelopes don't have points, although in this particular case this is redundant because non-existing envelope cannot be selected
					if env == sel_env then -- storing env index, alternatively its more immutable properties could be stored to account for possible removal/re-opening in a different order, but like with items not sure it's a compelling enough reason
					local tr_idx = r.CSurf_TrackToID(tr, false) -- mcpView false
					data = data..'tr:'..tr_idx..' env:'..i
					break end
				end
			end

			if #data > 0 then
			r.SetExtState(namedID, 'DATA', 'time:'..r.time_precise()..' '..data, false) -- persist false
			r.SetToggleCommandState(sectionID, cmdID, 1) ----- UNCOMMENT !!!!!!!
			local mess = sel_item and 'the item data has been stored' or 'the envelope data \n\n  has been stored'
			Error_Tooltip('\n\n '..mess..' \n\n', 1, 1) -- caps, spaced true
			return r.defer(no_undo) end -- abort to prevent automatically going to the step 2
		end

	end


	if #data > 0 then -- there's stored data or sws extension is installed and there's envelope under mouse cursor

		local function Is_Same_Track(tr)
			for i = 0, r.CountSelectedMediaItems(0)-1 do
			local item = r.GetSelectedMediaItem(0,i)
			local itm_tr = r.GetMediaItemTrack(item)
				if itm_tr == tr then return true end -- one is enough
			end
		end

	local itm_idx_t, env, tr = {}, sel_env

		if data == 'mouse' then -- envelope under mouse cursor

			if not sel_item then
			Error_Tooltip('\n\n no selected items \n\n', 1, 1) -- caps, spaced true
			return r.defer(no_undo) end

		tr = r.GetEnvelopeInfo_Value(env, 'P_TRACK')

			if not Is_Same_Track(tr) then
			Error_Tooltip('\n\n     the selected items \n\n and the envelope belong '
			..'\n\n    to different tracks \n\n', 1, 1) -- caps, spaced true
			return r.defer(no_undo) end

		else -- stored data // STEP 2

			function PROMPT(err, spaces_cnt, prompt, response)
			local err = ' |'..space(spaces_cnt)..err:upper():gsub('.','%0 ')..'| '
			return Show_Menu_Dialogue(err..'|'..prompt..'||'..response)
			end

		local prompt = ('    Wish to clear the buffer?'):gsub('.','%0 ')
		local response = (space(15)..'Y E S'):gsub('.','%0 ')

		local tr_idx = data:match('tr:(.-) ')
		tr = r.CSurf_TrackFromID(tr_idx, false) -- mcpView false
		local env_idx = data:match('env:(.+)')
		local items_data = data:match('items:(.+)') -- isolate item data

			if not env_idx then -- not env was stored but items

				for itm_idx in items_data:gmatch('[^,]+') do
					if itm_idx then
					itm_idx_t[#itm_idx_t+1] = itm_idx
					end
				end

			env = r.GetSelectedTrackEnvelope(0)
			local env_tr = env and r.GetEnvelopeInfo_Value(env, 'P_TRACK')
			local err = not env and 'no selected track envelope'
			or env_tr ~= tr and 'the items and the envelope '
			..'\n\n belong to different tracks'

				if err then
					if not env then
					local output = PROMPT(err, 0, prompt, response)
						if output == 5 then
						r.DeleteExtState(namedID, 'DATA', true) -- persist true
						end
					else
					Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
					end
				return r.defer(no_undo) end

			else -- env was stored and not items

			local sel_item = r.GetSelectedMediaItem(0,0)

				if not sel_item then
				local output = PROMPT('no selected items', 13, prompt, response)
					if output == 5 then
					r.DeleteExtState(namedID, 'DATA', true) -- persist true
					end
				return r.defer(no_undo) end

				for i = 0, r.CountTrackEnvelopes(tr)-1 do -- search for env index among track envs and get its pointer
					if i == env_idx+0 then
					env = r.GetTrackEnvelope(tr, 0)
						if r.CountEnvelopePoints(env) > 0 -- validate because in REAPER builds before 7.06 fx param envelopes are valid if param modulation is enabled without any actual envelope, such ghost envelopes don't have points
						then break
						else
						env = nil -- reset
						end
					end
				end

			local err = not env and 'the stored envelope wasn\'t found'
			or not Is_Same_Track(tr) and 'the items and the envelope \n\n belong to different tracks '
			or not Is_Env_Visible(env) and 'the stored envelope is hidden '

				if err then
				Error_Tooltip('\n\n '..err..'\n\n', 1, 1) -- caps, spaced true
				return r.defer(no_undo) end

			end

		end


	-- get index of the first selected AI on the envelope, which will be pool source for the newly inserted AI
	local GetSetAI = r.GetSetAutomationItemInfo
	local pool_src_idx--, pre_existing_AI
		for AI_idx = 0, r.CountAutomationItems(env)-1 do
			if GetSetAI(env, AI_idx, 'D_UISEL', -1, false) > 0 -- selected; value -1, is_set false
			then
			pool_src_idx = AI_idx
			break
			end
		end

	r.Undo_BeginBlock()

	local st, fin = table.unpack(#itm_idx_t > 0 and {1, #itm_idx_t} or {0, r.GetTrackNumMediaItems(tr)-1}) -- depending on what was stored, envelope or items

		for i = st, fin do
		local item_idx = #itm_idx_t > 0 and itm_idx_t[i]+0 or i -- +0 to convert to number
		local item = r.GetTrackMediaItem(tr, item_idx)
			if #itm_idx_t > 0 or r.IsMediaItemSelected(item) then -- if item was stored it doesn't have to be selected
			item_st, item_len = r.GetMediaItemInfo_Value(item, 'D_POSITION'), r.GetMediaItemInfo_Value(item, 'D_LENGTH')
				if pool_src_idx then
				-- collect props of the pool source AI
				local pool_ID = GetSetAI(env, pool_src_idx, 'D_POOL_ID', -1, false)
				local src_start = GetSetAI(env, pool_src_idx, 'D_POSITION', -1, false)
				local src_len = GetSetAI(env, pool_src_idx, 'D_LENGTH', -1, false)
				local src_playrate = GetSetAI(env, pool_src_idx, 'D_PLAYRATE', -1, false) -- pool source playrate isn't preserved in the inserted pooled instance, it defaults to 1, therefore the source playrate needs to be retrieved from the source

				local overlap = src_start >= item_st and src_start < item_st+item_len -- partial overlap incl. enclosed overlap
				or src_start+src_len > item_st and src_start+src_len <= item_st+item_len -- partial overlap incl. enclosed overlap
				or src_start <= item_st and src_start+src_len >= item_st+item_len -- full overlap

				local trim_ON = overlap and r.GetToggleCommandStateEx(0, 42206)	== 1 -- Options: Trim content behind automation items when editing or writing automation
				local disable = trim_ON and r.Main_OnCommand(42206, 0) -- toggle off to prevent trimming the pool source AI with the newly inserted one if they are going to overlap before playrate and length are fitted to match the item length
				-- however if there's a pre-existing AI under the item, turning off trimming to spare the pool source will prevent trimming such AIs as well

				-- trimming behind only works when pasting, it doesn't work when the length is changed,
				-- so if there's pre-existing AI under item and the pool source is shorter, in the pre-exiting AI
				-- only the part equal to the pool source length will be trimmed
				-- therefore the new AI must be created at full item length and playrate is dealt with afterwards
				local new_AI_idx = r.InsertAutomationItem(env, pool_ID, item_st, item_len)

				-- always set playrate to cover all cases, including cases when the pool source is already under the item
				-- and has the same length when inserting a new AI on top of the pool source
				local src_orig_len = src_len*src_playrate -- calculate orig pool source length, new length is created by division of orig length by playrate, so this is reverse operation

				local new_playrate = src_orig_len/item_len -- calc playrate required for fitting AI length to item length
				GetSetAI(env, new_AI_idx, 'D_PLAYRATE', new_playrate, true) -- is_set true

					if trim_ON then r.Main_OnCommand(42206, 0) end -- re-enable

				GetSetAI(env, new_AI_idx, 'D_UISEL', 0, true) -- value 0, is_set true // de-select the newly added AI
				local new_AI_st = GetSetAI(env, new_AI_idx, 'D_POSITION', -1, false)
				pool_src_idx = new_AI_st < src_start and pool_src_idx+1 or pool_src_idx
				GetSetAI(env, pool_src_idx, 'D_UISEL', 1, true) -- value 1, is_set true // re-select pool source AI because at insertion of the new AI it gets de-selected, so all subsequent new AI if any use the same source

				pool = '& pool'

				else

				r.InsertAutomationItem(env, -1 , item_st, item_len) -- if no selected AI pool_id -1 absorbs env points

				end

			end -- item condition end

		end

		if not pool_src_idx then
		Error_Tooltip('\n\n no selected ai to pool with \n\n', 1, 1) -- caps, spaced true
		end

		r.DeleteExtState(namedID, 'DATA', true) -- persist true
		r.SetToggleCommandState(sectionID, cmdID, 0) -- reset toggle state	----- UNCOMMENT !!!!!!!

	r.Undo_EndBlock('Insert automation item on selected envelope at selected items on the same track '..(pool or ''), -1)

	end
