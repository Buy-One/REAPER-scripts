--[[
ReaScript name: BuyOne_Import metadata from media into the Project Render Metadata.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.30
Extensions: SWS/S&M can be useful, not mandatory
About: 	The script allows import of metadata from the media source 
    		of in-project media items to the Project Render Metadata
    		settings being mainly geared towards preserving metadata
    		at rendering without having to re-type it by hand.  
    		It only supports tags (IDs) listed in Project Render 
    		Metadata window + user tags including those added via
    		the Media Explorer as long as the're listed in the source
    		metadata.
    
    		WAYS TO SUPPLY METADATA TO THE SCRIPT
    
    		In REAPER builds 6.30 - 6.53 the metadata must be extracted
    		manually from the item source properties via the action
    		'Item properties: Show media item source properties',
    		the Properties button in the Media Item Properties dialogue
    		or the 'Source properties' item of item context menu.  
    		If the SWS extension is installed the metadata can be copied
    		into the clipboard and will be accessed from there provided
    		no item is selected.  
    		Alternatively they can be pasted into the notes of any item
    		and for the script to be able to access them such item must 
    		be selected.  
    		The 2nd option is preferable since metadata from several items
    		can be collected within items notes whereas the clipboard only
    		holds the last copied data.
    		
    		Since REAPER 6.54 metadata can be collected by the script from
    		selected items. However in this scenario BWF metadata stored
    		under the IXML scheme (particularly after being embedded in
    		REAPER) won't be extracted so if this is required the options
    		described above should be opted for.
    		
    		So from build 6.54 the script supports multiple item selection. 
    		If these contain different data for the same metadata keys (IDs)
    		or if project metadata settings already contain data for such keys, 
    		entries from different sources get separated by double slash //.
    		
    		Since ReaScript API doesn't allow to undo metadata setting,
    		the script provides an option to undo the last metadata import.
    		The undo option is available for 30 minutes after the last 
    		import.  
    		It also provides options for clearing all metadata or metadata
    		of a particular scheme from the project render settings. These 
    		options however clear all entries including those which were 
    		added by means other than this script.
		
]]



local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Error_Tooltip(text, caps, spaced, x2, y2)
-- the tooltip sticks under the mouse within Arrange
-- but quickly disappears over the TCP, to make it stick
-- just a tad longer there it must be directly under the mouse
-- caps and spaced are booleans
-- x2, y2 are integers to adjust tooltip position by
local x, y = r.GetMousePosition()
local text = caps and text:upper() or text
local text = spaced and text:gsub('.','%0 ') or text
local x2, y2 = x2 and math.floor(x2) or 0, y2 and math.floor(y2) or 0
r.TrackCtl_SetToolTip(text, x+x2, y+y2, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
-- r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
--[[
-- a time loop can be added to run until certain condition obtains, e.g.
local time_init = r.time_precise()
repeat
until condition and r.time_precise()-time_init >= 0.7 or not condition
]]
r.UpdateTimeline() -- might be needed because tooltip can sometimes affect graphics
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Parse_Extracted_Metadata_String(item)
-- format string extracted with GetMediaFileMetadata()
-- to be used in Parse_Copied_Metadata_String()

	local function Convert_IXML_to_BWF(t, scheme, ID)
	local conversion_t = {BWF_DESCRIPTION='Description', BWF_LOUDNESS_RANGE='LoudnessRange',
	BWF_LOUDNESS_VALUE='LoudnessValue', BWF_MAX_MOMENTARY_LOUDNESS='MaxMomentaryLoudness',
	BWF_MAX_SHORT_TERM_LOUDNESS='MaxShortTermLoudness', BWF_MAX_TRUE_PEAK_LEVEL='MaxTruePeakLevel',
--	BWF_TIME_REFERENCE_HIGH='', BWF_TIME_REFERENCE_LOW='', -- these don't seem to have separate IDs even though listed in the metadata
	BWF_ORIGINATION_DATE='OriginationDate', BWF_ORIGINATION_TIME='OriginationTime',
	BWF_ORIGINATOR='Originator', BWF_ORIGINATOR_REFERENCE='OriginatorReference'} -- 'Originator' tag is also listed under BWF scheme
		if scheme == 'IXML' then
			for from, to in pairs(conversion_t) do
				if ID == from then -- store under BWF scheme
				t.BWF = t.BWF or {}
				t.BWF[#t.BWF+1] = to
				ID = nil
				break end
			end
			if ID and (ID:match('^%u+$') or ID:match('USER')) then -- IXML tags are all upper case unless it's a user defined tag, excluding non-standard BWF tags because these don't return any value
			t.IXML = t.IXML or {}
			t.IXML[#t.IXML+1] = ID
			elseif ID and ID:match('[%l]') then -- lower case ID, belongs to BWF scheme but appears under IXML, excluding any non-standard BWF tags which weren't converted above because these don't return any value
			t.BWF = t.BWF or {}
			t.BWF[#t.BWF+1] = ID
			end
		return '' end
	return ID -- if not found return original
	end

local src = r.GetMediaItemTake_Source(r.GetActiveTake(item))
local ret, metadata = r.GetMediaFileMetadata(src, '') -- as ret var returns the number of schemes for which metadata are embedded, as metadata var returns the list of all tags (IDs) in each scheme for which metadata are embedded, without values, save for IXML which lists non-standard BWF tags described in Store_Converting_IXML_to_BWF() inside Parse_Copied_Metadata_String()

local t, found = {}
	for line in metadata:gmatch('[^\n\r]+') do -- collect all tags for each scheme whose data are found in the media
	local scheme = line:match('([%u%d]-):')
		if scheme and #scheme > 0 and scheme ~= found then -- scheme can be empty string if the title is 'Generic:' because it won't be captured by string.match() above
		t[scheme] = {}
		found = scheme
		end
		if found then
		local ID = line:match(found..':BWF:(.-):') or line:match(found..':BWF:(.+)') or line:match(found..':(.+)') -- BWF with or without value
			if ID then
			ID = Convert_IXML_to_BWF(t, found, ID)
				if #ID > 0 then -- will be empty if BWF tag is found under the IXML scheme, it will be converted and stored inside Convert_IXML_to_BWF()
				local len = #t[scheme]
				t[scheme][len+1] = ID
				end
			end
		end
	end

-- collect values
	for scheme, ID_t in pairs(t) do
		for k = #ID_t, 1, -1 do
		local ID = ID_t[k]
			if ID then -- can be nil if no tags were found for the scheme, mainly relevant for IXML whose data was stored under the BWF scheme
			local ret, value = r.GetMediaFileMetadata(src, scheme..':'..ID)
				if ret == 1 then -- value exists // OR #value > 0
				ID_t[k] = {ID=ID, value=value}
				else
				table.remove(ID_t, k) -- if no value was retrieved which is likely only to apply to the BWF scheme
				end
			end
		end
	end


return ret > 0 and t -- or ret == 1 or #metadata > 0 and t

end


function Parse_Copied_Metadata_String(metadata)
-- user custom tags are supported for ID3, APE, VORBIS & IXML schemes as per MX dialogue
-- for adding Metadata custom column
-- the syntax to add user defined tags with GetSetProjectInfo_String() is USER:<description>|<data>
-- where the <decription> can be arbitrary, it will be listed in the Description column
-- of the 'Project Render Metadata' window
-- the <data> part will be written into the Value column
-- the combination USER:<description> is a tag ID listed in the ID column of the 'Project Render Metadata' window
-- !!! it's possible in the 4 aforementioned schemes to use the syntax USER|<data> (User is also supported),
-- to add value to the row whose description in the 'Project Render Metadata' window is 'User Defined'
-- BUT this is a bug because that field isn't supposed to hold any value, it's meant for manual entering
-- in the format of Key=Value as mentioned in the 'Format' column, after which a new line is created
-- with Key displayed in the 'Description' column and the Value in the 'Value' column,
-- running 'User Defined|<data>' syntax afterwards removes all user defined tags
-- and then adding any new user tags becomes impossible
-- https://forum.cockos.com/showthread.php?t=285710;
-- <decription> corresponds to the 'Key:' field of the MX custom metadata column dialogue
-- <data> corresponds to the content of the column displayed opposite of the file which is user editable
-- In MX the content of the 'Description:' field of the custom metadata dialogue is displayed
-- as the custom column title, it's not reflected in the 'Project Render Metadata' window

	local function Store_Converting_IXML_to_BWF(t, scheme, ID, data)
	-- some (in fact most) BWF tags appear under IXML scheme even if only BWF tags were embedded in REAPER
	-- e.g. BWF:BWF_DESCRIPTION: DESC
	-- that's regardless of 'write BWF chunk' option being enabled
	-- so converting BWF tags which appear under IXML scheme to their proper IDs;
	-- after rendering they're still listed under the IXML scheme in both formats
	-- however the capitalized value strings with the underscores cannot be used to set the metatag
	local conversion_t = {BWF_DESCRIPTION='Description', BWF_LOUDNESS_RANGE='LoudnessRange',
	BWF_LOUDNESS_VALUE='LoudnessValue', BWF_MAX_MOMENTARY_LOUDNESS='MaxMomentaryLoudness',
	BWF_MAX_SHORT_TERM_LOUDNESS='MaxShortTermLoudness', BWF_MAX_TRUE_PEAK_LEVEL='MaxTruePeakLevel',
--	BWF_TIME_REFERENCE_HIGH='', BWF_TIME_REFERENCE_LOW='', -- these don't seem to have separate IDs even though listed in the metadata
	BWF_ORIGINATION_DATE='OriginationDate', BWF_ORIGINATION_TIME='OriginationTime',
	BWF_ORIGINATOR='Originator', BWF_ORIGINATOR_REFERENCE='OriginatorReference'} -- 'Originator' tag is also listed under BWF scheme

		if scheme == 'IXML' and ID:match('BWF:BWF_') then -- convert BWF tags listed under IXML scheme and store in the table
		local ID = ID:match(':(.+)')
			for from, to in pairs(conversion_t) do
				if ID == from then
				t.BWF = t.BWF or {}
				t.BWF[#t.BWF+1] = {ID=to, value=data:match(': (.+)')} -- isolating value from the content of the data var, e.g. 'BWF_ORIGINATOR: ORIGINATOR'
				return
				end
			end
		elseif scheme == 'IXML' and (ID:match('^%u+:') or ID:match('USER')) then -- IXML tags are all upper case unless it's a user defined tag, excluding non-standard BWF tags because these don't return any value
		local len = #t[scheme]
		t[scheme][len+1] = {ID=ID, value=( data:match(': (.+)') or data )} -- isolate value because the data var may include user tag already included in ID var, e.g. 'TXXX:Name: NAME' - ID = 'TXXX:Name:', data = 'Name: NAME' (ID3 scheme) or 'USER:NEW_TAG: TEST123' - ID = 'USER:NEW_TAG', data = 'NEW_TAG: TEST123' (IXML scheme)
		return
		end

	-- store other data which didn't need conversion
	local len = #t[scheme]
--	t[scheme][len+1] = ID..'|'..( data:match(': (.+)') or data ) -- see comment above
	t[scheme][len+1] = {ID=ID, value=( data:match(': (.+)') or data )} -- see comment above
	end

local t = {}
local found
	for line in metadata:gmatch('[^\n\r]+') do -- look for scheme titles
	local scheme = line:match('([%u%d]+) tags:')
		if scheme then
		t[scheme] = {}
		found = scheme
		elseif found and line:match('.+:%s?.+') then
		local ID, data = line:match('%s*(.+):'), line:match(':%s?(.+)')
			if ID and data then
			Store_Converting_IXML_to_BWF(t, found, ID, data) -- found var holds scheme name
			end
		else
		found = nil
		end
	end
return found and t
end


function Process_Undo(cmd_ID, clear_undo_data)
-- clear_undo_data is boolean to be used before import and storage of new data

local scheme_t = {'APE','ASWG','AXML','BWF','CAFINFO','CART','CUE',
'FLACPIC','ID3','IFF','INFO','IXML','VORBIS','WAVEXT','XMP'}

local undo -- to condition an error message if undo wasn't performed

	for _, scheme in ipairs(scheme_t) do

	local i = 0 -- iterate over scheme per item

		repeat

		local j = 1 -- iterate over data per scheme

			repeat

			local data = r.GetExtState(cmd_ID..':'..i, scheme..':'..j)

				if #data == 0 then break end

				if not clear_undo_data then -- Undo

				local ID, value = data:match('(.+)::'), data:match('::(.+)')
				local _, cur_value = r.GetSetProjectInfo_String(0, 'RENDER_METADATA', scheme..':'..ID, false) -- is_set false

				-- the condition also takes care of cases of duplicate BWF scheme entries
				-- in case they were found under the IXML scheme
				-- and stored under BWF in functions Parse_Copied_Metadata_String()
				-- and Parse_Extracted_Metadata_String()
				-- by preventing their re-adding after they've been deleted once in which case
				-- cur_value will be an empty string
				-- it also prevents re-adding the undone data on subsequent executions of the script undo option
					if #cur_value > 0 then -- data present

					value = Esc(value)

						if cur_value:match(' // '..value..'$') then
						value = cur_value:gsub(' // '..value, '')
						elseif cur_value:match(value..' // ') then
						value = cur_value:gsub(value..' // ', '')
						elseif cur_value:match(value) then
						value = cur_value:gsub(value, '')
						end

						if value then -- Delete

						undo = 1

						r.GetSetProjectInfo_String(0, 'RENDER_METADATA', scheme..':'..ID..'|'..value, true) -- is_set true

						end
					end
				end

			r.DeleteExtState(cmd_ID..':'..i, scheme..':'..j, true) -- persist true

			j=j+1

			until #data == 0 -- data per scheme iteration end

		i=i+1

		until #r.GetExtState(cmd_ID..':'..i, scheme..':1') == 0 -- scheme per item iteration end

	end -- scheme_t loop end

return undo

end


function Clear_Metadata(index, cmd_ID) -- index is the menu integer output

local scheme_t = {'APE','ASWG','AXML','BWF','CAFINFO','CART','CUE',
'FLACPIC','ID3','IFF','INFO','IXML','VORBIS','WAVEXT','XMP'}
local ret, list = r.GetSetProjectInfo_String(0, 'RENDER_METADATA', '', false) -- is_set false // get list of keys (IDs) having values in the Render Metadata settings
	for k, scheme in ipairs(scheme_t) do
	local found
		for ID in list:gmatch('[^;]+') do
			if not found and ID:match(scheme) then found = 1
			elseif found and not ID:match(scheme) then break
			end
			if found then
			scheme_t[scheme] = scheme_t[scheme] or {}
			local len = #scheme_t[scheme]
			scheme_t[scheme][len+1] = ID
			end
		end
	found = nil
	end

	if index == 0 then -- menu item 'All'

		for k, scheme in ipairs(scheme_t) do
			if scheme_t[scheme] then -- data in the selected scheme exists
				for k, ID in ipairs(scheme_t[scheme]) do
				r.GetSetProjectInfo_String(0, 'RENDER_METADATA', ID, true) -- is_set true
				end
			end
		end

	Process_Undo(cmd_ID, 1) -- clear_undo_data true

	elseif scheme_t[scheme_t[index]] then -- data in the selected scheme exists

		for k, ID in ipairs(scheme_t[scheme_t[index]]) do
		r.GetSetProjectInfo_String(0, 'RENDER_METADATA', ID, true) -- is_set true
		end

	end

end


function Expiry_Timer(cmd_ID, threshold)
-- threshold is integer, time in seconds
-- useful for limiting the time of data storage in the buffer
local timestamp = tonumber(r.GetExtState(cmd_ID, 'EXPIRY TIMER'))
	if not timestamp and not threshold then -- this conditions timer setting after import
	r.SetExtState(cmd_ID, 'EXPIRY TIMER', r.time_precise(), false) -- persist false
	elseif timestamp and threshold and r.time_precise()-timestamp >= threshold then
	-- this conditions greyed out Undo menu item after time has elapsed
	r.DeleteExtState(cmd_ID, 'EXPIRY TIMER', true) -- persist true
	Process_Undo(cmd_ID, true) -- clear_undo_data true
	return true
	elseif not timestamp and threshold then
	-- this conditions greyed out Undo menu item when the script hasn't been run yet
	-- and so the timer hasn't been set
	return true
	end
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


--- Main routine

local current_build = tonumber(r.GetAppVersion():match('[%d%.]+'))
local build_6_30 = current_build >= 6.30 and current_build < 6.54 -- build in which RENDER_METADATA param was added to GetSetProjectInfo_String
local build_6_54 = current_build >= 6.54 -- build in which GetMediaFileMetadata() was added

	if not build_6_30 and not build_6_54 then
	Error_Tooltip('\n\n the secript requires \n\n\tREAPER 6.30+ \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local sws = r.APIExists('CF_GetClipboard')
local sel_itm = r.GetSelectedMediaItem(0,0)

	if sws and not sel_itm then -- only look for the clipboard if no item is selected
	metadata = r.CF_GetClipboard()
	metadata_t = Parse_Copied_Metadata_String(metadata)
	end

	if sws and not metadata_t and not sel_itm then
	Error_Tooltip('\n\n no metadata in the clipboard \n\n\tand no selected items \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, fullpath, sect_ID, cmd_ID, mode, resolution, val = r.get_action_context()
cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)


local undo_state = Expiry_Timer(cmd_ID, 60*30) and '#' or '' -- keep undo data for 30 min
local undo_menu = undo_state..'UNDO LAST METADATA IMPORT|'
..undo_state..'(if there\'s only a single value in the field|'
..undo_state..'it\'s the one which will be cleared)||'
local scheme_lst = 'All|APE|ASWG|AXML|BWF|CAFINFO|CART|CUE|FLACPIC|ID3|IFF|INFO|IXML|VORBIS|WAVEXT'
local menu = 'IMPORT ITEMS METADATA||'..undo_menu..'>CLEAR PROJECT METADATA| '..scheme_lst:gsub('.','%0 ')..'|< X M P'

local output = Reload_Menu_at_Same_Pos(menu, keep_menu_open, left_edge_dist)
	if output == 0 then return r.defer(no_undo) end
	if output > 1 and output < 5 then
	local clear_all = output == 5 -- accounting for the 2nd item with 2-line comment
	local retval = Process_Undo(cmd_ID) -- undo last import
		if not retval then
		Error_Tooltip('\n\n nothing was undone \n\n', 1, 1) -- caps, spaced true
		end
	return r.defer(no_undo)
	elseif output > 4 then
	Clear_Metadata(output-5, cmd_ID) -- 5 to offset preceding menu items + All in the scheme submenu
	return r.defer(no_undo)
	end

local itm_cnt = metadata_t and 1 or r.CountSelectedMediaItems(0) -- if metadata were retrieved from the clipboard only allow 1 loop cycle

	for i = 0, itm_cnt-1 do

	local sel_itm = r.GetSelectedMediaItem(0,i)

		if not metadata_t then -- not retrieved from the clibpoard

			if build_6_54 then -- extract metadata directly from the selected media file
			metadata_t = Parse_Extracted_Metadata_String(sel_itm)
			else
			-- otherwise retrieve the metadata from the notes of the selected item pasted by the user after copying from the item source properties (not necessarily the one the metadata belong to)
			ret, metadata = r.GetSetMediaItemInfo_String(sel_itm, 'P_NOTES', '', false) -- setNewValue false
				if ret == 1 then
				metadata_t = Parse_Copied_Metadata_String(metadata)
				end
			end

		end -- not metadata_t block end

	function manage_and_append_values(scheme, ID, value)
	local ret, existing_value = r.GetSetProjectInfo_String(0, 'RENDER_METADATA', scheme..':'..ID, false) -- is_set false // ret var is true even if there's no data to be returned as existing_value, so useless
		for v in existing_value:gmatch('%s*([^/]+)') do
		v = v:match('.*[%p%w]+') -- * to account for value consisting of only 1 character
			if v == value then
			return existing_value end -- prevent appending identical data
		end
	return existing_value..(#existing_value > 0 and ' // ' or '')..value
	end

		if metadata_t then

			if i == 0 then -- clear previous undo data
			-- only run once to prevent clearing data just stored during the loop
			Process_Undo(cmd_ID, 1) -- clear_undo_data true
			end

			for scheme, data_t in pairs(metadata_t) do
				for k, data in ipairs(data_t) do
				local ID, value = data.ID, data.value
					if ID and value then -- value can be nil if the table was constructed with Parse_Extracted_Metadata_String() and no value was retrieved from the file, mainly applies to BWF scheme data which appears under the IXML scheme in the metadata chunk but cannot be retrieved by addressing BWF scheme
					local fin_value = manage_and_append_values(scheme, ID, value)
					r.GetSetProjectInfo_String(0, 'RENDER_METADATA', scheme..':'..ID..'|'..fin_value, true) -- is_set true
					imported = true
					r.SetExtState(cmd_ID..':'..i, scheme..':'..k, ID..'::'..value, false) -- pertist false // store for undo
					end
				end
			end

		end

	metadata_t = nil -- reset

	end -- selected items loop end

	if not imported then
	Error_Tooltip('\n\n no metadata was found \n\n', 1, 1) -- caps, spaced true
	else Expiry_Timer(cmd_ID) -- set the timer
	end


do return r.defer(no_undo) end


