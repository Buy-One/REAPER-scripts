--[[
ReaScript name: BuyOne_Multi-line caption editor (for use with Video processor).lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v6.37
Extensions: 
About:	This script is ancillary to 
			BuyOne_Multi-line caption aide (for use with Video processor).lua
			
			The only difference in functionality of the caption 
			editor called by this script from the caption editor 
			accessible from the main script is that unlike in
			the main script, where type of the editor (single or
			multi-take caption editor) depends on the clicked menu 
			item, here it depends on the state of 'Play all takes' 
			option in the target item properties. When it's enabled, 
			Type 2 caption editor is loaded. So if you begin 
			creation of Type 2 multi-line caption with this script
			make sure this option in the item properties is enabled.
			
			The concept and caption editor workflow are the same
			as described in the 'About' section of the main script.

]]


-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------


-- Between the quotes insert the character
-- or a combination thereof which you wish
-- to signal a line break in a take name
-- and which will be converted by the script
-- into the actual line break, 
-- obviously it must be unique to not be
-- confused with valid characters within text,
-- space is not supported; 
-- if empty, defaults to \n
OPERATOR = ""


-- Insert the name of the Video processor overlay 
-- preset if you're using a custom one;
-- if empty or only contains spaces the stock
-- preset 'Overlay: Text/Timecode' will be used
OVERLAY_PRESET = ""


-- For Type 2 caption the setting determines how caption 
-- lines are removed from the caption via the caption 
-- editor, simple deletion of a take name 
-- is not enough because the text placeholder will remain
-- visible on the screen;
-- for Type 1 caption the setting determines how entire
-- caption is removed if the editor is submitted with all
-- lines empty; 
-- 1 - bypass Video processor instance
-- 2 - set Video processor instance offline
-- 3 - delete Video processor instance
-- 4 - delete the take
-- with modes 1-3 take name is preserved,
-- re-enabling a line excluded from the caption 
-- with modes 1-3, will have to be done manually;
-- empty or invalid setting defaults to mode 1 
-- as the least intrusive and destructive
LINE_REMOVAL_MODE = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper


local Debug = ""
function Msg(...)
-- accepts either a single arg, or multiple pairs of value and caption
-- caption must follow value because if value is nil
-- and the vararg ends with it, it will be ignored
-- because nil isn't a valid table value, and won't be displayed
-- so vararg must not be allowed to end with nil when multiple
-- arguments are passed, i.e. always end with a caption
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	local t = {...} -- constucting table this way, i.e. by packing, allows getting table length even if it contains nils
--	local str = #t == 1 and tostring(t[1])..'\n' or not t[1] and 'nil\n' or ''
	local str = #t < 2 and tostring(t[1])..'\n' or ''
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


function no_undo()
do return end
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function space(str)
return str:gsub('.','%0 ')
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



function GetUserInputs_Alt(title, field_cnt, field_names, field_cont, separator, comment_field, comment, empty_comm_fields)
-- title string, field_cnt integer which can be smaller or greater 
-- than the number of fields in field_names arg, in which case fields will
-- be subtracted, or added but without names, if 0 <= field_cnt 
-- then field_cnt will be derived from field_names arg 
-- and if field_names is empty but comment_field is enabled
-- field_cnt will default to 1 to add one field besides the comment field(s),
-- otherwise the dialogue won't load because field count 0 disables it in the native function
-- while negative value generates a blank window with buttons, which is prevented here,
-- field_cnt doesn't account for the comment field,
-- if final field count exceeds the total limit of 16, 
-- it gets clamped to 16 and disables the comment if enabled,
-- if fields count isn't constant because their appearance is conditional
-- it may prove more relialbe to calculate the field_cnt value in the code 
-- outside of the function because extra separators which separate fields
-- whose appearance condition isn't met will affect the internal
-- calculation;
-- field_names is table or string comma delimited
-- OR separator delimited IF commas must be used in field names, 
-- because 'separator=' setting applies to field name separation as well, 
-- OR empty string,
-- it's safer to use \n or \r or \t or any other control char as a separator
-- to ensure that the separator has no chance of clashing with the user content
-- because literal control characters input by the user won't be recognized as such,
-- in this case however such characters must be excluded from the user content
-- to prevent them from being recognized as control chars when the content
-- is processed internally;
-- unbalanced quotes, apostrophes and parenthesis break field separation
-- SEE ALSO resolve_all_or_restore_apostrophe() above;
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names
-- and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string or nil unless they must be initially filled,
-- to fill out only specific fields precede them with as many separator characters
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5,
-- if some/all fields must initially be filled out field_cont may be a table;
-- separator is a string, character which delimits the fields,
-- if invalid / empty string, defaults to comma
-- the function relies on Esc() function if separator character needs escaping,
-- MULTIPLE CHARACTERS CANNOT BE USED AS FIELD SEPARATOR 
-- BECAUSE FIELD NAMES LIST OR ITS FORMATTING BREAKS,
-- Lua string library magic characters are NOT recommended as separators
-- because if these characters also present in the text fields
-- captures won't work accurately, \n, \r and \t are the safest because 
-- they're not confused with their literal look-alikes;
-- comment_field is boolean, comment is string to be displayed in the comment field(s),
-- if comment_field is true but comment arg is an empty string 
-- or only contains separators, comment_field arg is ignored 
-- and no comment field(s) is displayed, UNLESS empty_comm_fields arg is true,
-- multiple comments must be delimited by the character used as the separator arg
-- or by comma if separator is the comma,
-- if comment text contains commas, separator arg must be set specifically 
-- to be anything but comma, 
-- if final field count with comment fields hits or exceeds the limit of 16, 
-- comment fields number is reduced, text of any extra comment fields is merged 
-- into the last visible comment field if any remains;
-- empty_comm_fields arg is boolean, allows having empty comment fields
-- if their intended use is other than comment;
-- extrawidth parameter is to be set diectly inside the function code;

	if (not field_cnt or field_cnt <= 0) then -- if field_cnt arg is invalid, derive count from field_names arg
		if #field_names:gsub(' ','') == 0 and not comment_field then return end
	field_cnt = select(2, field_names:gsub(',',''))+1 -- +1 because last field name isn't followed by a comma and one comma less was captured
	--	if field_cnt-1 == 0 and not comment_field then return end -- SAME AS THE ABOVE CONDITION
	end
	
	if field_cnt >= 15 then
	field_cnt = 15 -- clamp to the limit of 15 fields, max supported by the native function minus 1 for one comment field
--	comment_field = nil -- disable comment if field count hit the limit, just in case
	end

	local function add_separators(field_cnt, arg, sep)
	-- for field_names and field_cont as arg
	-- add delimiting separators when they're fewer than field_cnt
	-- due to lacking field names or field content
	-- which means they will delimit trailing empty fields
	local sep_esc = Esc(sep)
	local _, sep_cnt = arg:gsub(sep_esc,'')
	return sep_cnt == field_cnt-1 and arg -- -1 because the last field isn't followed by a separator
	or sep_cnt < field_cnt-1 and arg..(sep):rep(field_cnt-1-sep_cnt) -- add trailing separators
	or arg:match(('.-'..sep_esc):rep(field_cnt)):sub(1,-2) -- truncate arg when field_cnt value is smaller than the number of fields, excluding the last separator captured with the pattern inside string.match because the last field isn't followed by a separator
	end

	local function format_fields(arg, sep, field_cnt, trim_leading_space)
	-- for field_names and field_cont as arg
	local sep_esc = Esc(sep)
	local arg = type(arg) == 'table' and table.concat(arg, sep) or arg
	local formatted = add_separators(field_cnt, arg, sep)
	return not trim_leading_space and formatted or formatted:gsub(sep_esc..' ', sep) -- if there's space after labels separator, remove because with multiple fields the field names will not line up vertically
	end

-- for field names sep must be a comma because that's what field names list is delimited by
-- regardless of internal 'separator=' argument
-- but if comma must be used in field names, they must be delimited
-- by the main separator
local field_names = format_fields(field_names, ',', field_cnt, 1) -- trim_leading_space true // if commas need to be used in field names and the main separator is not a comma (because if it is comma cannot delimit field names), pass here the separator arg from the function
local sep = separator and #separator > 0 and separator or ','
local sep_esc = Esc(sep)
local field_cont = field_cont or ''
field_cont = format_fields(field_cont, sep, field_cnt) -- trim_leading_space nil but may need to be true, depending on the field content and script design
local sep_cnt = comment and select(2,comment:gsub(sep_esc,''))
local comment_field = comment_field and type(comment) == 'string' and (#comment ~= sep_cnt or empty_comm_fields)
local comment = comment_field and comment or ''
local comment_field_cnt = select(2, comment:gsub(sep_esc,''))+1 -- +1 because last comment field isn't followed by the separator so one less will be captured
local field_cnt = comment_field and field_cnt+comment_field_cnt or field_cnt

--[[ allows retention of the comment field if field count reaches or exceeds 16
	if field_cnt >= 16 then 
	-- disable some or all comment fields if field count hit the limit after comment fields have been added	
	comment_field_cnt = field_cnt - 16
	field_cnt = 16
	end
]]

field_names = comment_field and field_names..(',Scratch field:'):rep(comment_field_cnt) or field_names
field_cont = comment_field and field_cont..sep..comment or field_cont
local separator = sep ~= ',' and ',separator='..sep or '' -- if commas need to be used in field names, these must be delimited by the main separator which also should be used here
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=300'..separator, field_cont) -- same as above regarding delimiter
local comment_pattern = (sep_esc..'.*'):rep(comment_field_cnt)
comment = comment_field and output:match('.*('..comment_pattern..')') -- captured with leading separator which separates comment(s) from the main fields
output = comment_field and output:match('(.*)'..comment_pattern) or output -- strip comment fields content // * operator accommodates single empty field // output capture doesn't include trailing separator
field_cnt = comment_field and field_cnt-comment_field_cnt or field_cnt -- adjust for the next statement
	
	if not ret	
	--[[
	-- this condition will need commenting out if empty dialogue
	-- sumbission is allowed by script design, mainly if there're multiple fields in the dialogue	
	or (not comment_field and output or output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)) -- if there're comment fields, exclude trailing separator left behind after stripping comment fields content above // * operator accommodates single empty field // -1 because the last field doesn't end with a separator	
	--]]
	then return end
	--[[ OR
	-- to condition action by the type of the button pressed
	-- which will be assigned to the first return value that's supposed to be output_t
	if not ret then return 'cancel'
	elseif not comment_field and output or output:gsub('[%s%c]','') == (sep):rep(field_cnt-1) -- if there're comment fields, exclude trailing separator left behind after stripping comment fields content above // * operator accommodates single empty field // -1 because the last field doesn't end with a separator
	then return 'empty' end
	--]]

-- construct table out of input fields, empty fields and fields only filled with spaces are permitted
-- must be validated after values return
local t = {}
output = output..sep -- add trailing separator to be able to capture last field in the dialogue or last before comment field(s) because it doesn't end with a separator
	for s in output:gmatch('(.-)'..sep_esc) do
		if s then t[#t+1] = s end
	end

-- return fields content in a table and as a string to refill the dialogue on reload
return t, output:match('(.*)'..sep_esc), comment and comment:match(sep_esc..'(.*)') -- remove hanging separator from output return value to simplify re-filling the dialogue in case of reload, when there's a comment field the separator will be added with it, comment isn't included in the returned output // * operator accommodates single empty field // comment is returned without leading separator to be collected and fed back into the dialogue if it's generated dynamically and needs preserving when the dialogue is reloaded

end



function insert_video_proc_with_preset(take, preset) -- used inside Manage_Multiline_Caption()
-- if there're video processor instances insert after the last, otherwise insert at the top of the chain

local video_proc_idx
	for i=0, r.TakeFX_GetCount(take)-1 do
	local plug_type = r.TakeFX_GetIOSize(take, i)
		if plug_type == 6 then -- video proc
		local ret, presetname = r.TakeFX_GetPreset(take, i, '')
			if presetname == preset then 
			local ret, name = r.TakeFX_GetFXName(take, i)
				if name ~= 'Caption' then
				r.TakeFX_SetFXName(take, i)
				end
			return -- if overlay preset is already activated in any of the video proc instances, abort operation
			else
			video_proc_idx = i -- keep collecting video processors indices, if any
			end
		end
	end

local fx_idx = video_proc_idx and video_proc_idx+1 or -1000 -- if there're video processor instances insert after the last, otherwise insert at the top of the chain

r.TakeFX_AddByName(take, 'Video processor', fx_idx)
fx_idx = fx_idx < 0 and 0 or fx_idx -- change to target for processing
-- in builds older than 7.20 'Overlay: Text/Timecode' preset doesn't work if applied via the API
-- without opening the Video processor beforehand
-- because the parameter values shift downwards between parameters
-- while 'text height' param ends up at 0 so the text becomes invisible
-- bug report https://forum.cockos.com/showthread.php?t=293212
local old_build = tonumber(r.GetAppVersion():match('[%d%.]+')) < 7.20
	if old_build then r.TakeFX_Show(take, fx_idx, 3) end -- showFlag 3 show floating window
r.TakeFX_SetPreset(take, fx_idx, preset)
	if old_build then r.TakeFX_Show(take, fx_idx, 2) end -- showFlag 2 hide floating window
r.TakeFX_SetNamedConfigParm(take, fx_idx, 'renamed_name', 'Caption')

return true

end



function Duplicate_Active_Take_Contiguously(sel_item, want_above) -- used in Manage_Multiline_Caption()

-- duplicate and place immediately below the source take
-- or above if want_above arg is valid
-- contrary to the stock action which places it at the bottom;
-- the function must be applied to each selected item separately
-- because action is involved which affects all selected items
-- simultaneously, so the function must be preceded and followed 
-- by storage and restoration of item selection;
-- the function must be executed within the Undo block
-- to prevent creation of undo points by actions
-- of which there'll be several

	local function to_top()
	r.Main_OnCommand(41380,0) -- Item: Move active takes to top
	end

local ACT, Activate = r.Main_OnCommand, r.SetActiveTake
local item = sel_item or r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local act_take_idx = item and r.GetMediaItemTakeInfo_Value(act_take, 'IP_TAKENUMBER') -- OR r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
local take_cnt = item and r.CountTakes(item)

-- empty take inserted with 'Item: Add an empty take after the active take' doesn't have a pointer
-- even though it can be active
	if not item or not act_take then return end
	
ACT(40639, 0) -- Take: Duplicate active take // this will be placed at the bottom
local new_take_idx = r.CountTakes(item)-1 -- placed at the bottom hence the 0-based index is equal to take count-1
local new_take = r.GetTake(item, new_take_idx)
--[[ OR
local new_take = r.GetTake(item, r.CountTakes(item)-1)
local new_take_idx = r.GetMediaItemTackInfo_Value(new_take, 'IP_TAKENUMBER')
--]]

	if act_take_idx ~= take_cnt-1 or want_above then -- if active take is last and want_above is false, not need to cycle, everything will fall in place, even though cycing would still work
	
		if not want_above then
		to_top() -- new take is active, move it to top
		Activate(act_take) -- activate originally active take so it can be affected by the action
		to_top() -- move active take to top, now they're in the expected order relative to each other but at wrong places within the item
		else
		Activate(act_take) -- set originally active take active, because cuurently the duplicate take is active
		to_top() -- move to top
		Activate(new_take) -- set duplicate take active
		to_top() -- move to top, now they're in the expected order relative to each other but at wrong places within the item
		end
	
	-- Cycle takes until the originally active take ends up at its original index
	-- and is immediately followed by the new take,
	-- at this point the index of oringinally active take is 0 
	-- and of the new take is 1
		for i=1, act_take_idx do -- cycle as many times as the index of the originally active take, because it reflects the number of takes which preceded it and whose original position must be restored
		Activate(r.GetTake(item, act_take_idx+1)) -- target take which now occupies position of the originally active take, +1 to account for the newly inserted take which precedes such take in the new take order
		to_top() -- move to top
		end
	end

Activate(new_take) -- activate newly added take
r.UpdateItemInProject(item) -- to make re-activated take immediately visible

return new_take

end



function Manage_Multiline_Caption(multi_take, operator, preset) -- caption editor
-- multi_take is boolean
-- relies on Esc() function

	local function split_lines(output_t, operator, t)
	-- t is take properties table and will only be valid 
	-- if caption is multi-take

		local function update_caption_table(t, i, cnt, substr)
			if t then
			-- take is the line original source take to be used as a source for creation of a new take, fx_idx is the same as that of the original take, new_line is boolean to trigger creation of a new take
			table.insert(t, i+cnt, {take=t[i].take, idx=t[i].idx, name=substr, new_line=1})
			end
		end

	local operator = Esc(operator)
		for i=#output_t,1,-1 do
		local line = output_t[i]
			if line:match(operator) then
			table.remove(output_t, i) -- remove original line // removing here and starting substrings storage at the original line index ensures correct order of newly created lines
			local cnt, buf = 0, ''
				for byte in line:gmatch('.') do
				buf = buf..byte
					if buf:match('(.-)'..operator) then
					local substr = buf:match('(.-)'..operator)
					table.insert(output_t, i+cnt, substr) -- store up until the operator
						if t and i+cnt ~= i then -- add new fields in the take props table to match new fields created in the dialogue to be able to then create new takes for them 
						update_caption_table(t, i, cnt, substr) -- add new nested table for future new take which will be inserted, BUT ONLY when cnt is greater than the original line field index, because if the string is updated at the original index in the table the actual take name won't be updated in the take name update routine triggered by 'line ~= name' condition after dialogue submission, or if it IS ALLOWED to be updated inside the table, then in the take name update routine the line content taken from the dialogue output must be compared to take name retrieved directly from take rather than to its table stored version // in fact instead of substr an empty string can be stored because in the take name update routine after dialogue submission, newly created entries are identified not by the table 'name' field but by 'new_line' field added inside update_caption_table() function
						end
					buf = '' -- empty to restart collecting text
					cnt = cnt+1					
					end
				end
				if #buf > 0 then -- if there's outstanding content in the buffer, dump it to table
				table.insert(output_t, i+cnt, buf)
				update_caption_table(t, i, cnt, buf) -- add new nested table for future new take which will be inserted // in fact instead of buf an empty string can be stored because in the take name update routine after dialogue submission, newly created entries are identified not by the table 'name' field but by 'new_line' field added inside update_caption_table() function
				else -- if at the end of the gmatch loop buf is empty, the string ended with an operator, so store an empty line which is supposed to follow the operator
				table.insert(output_t, i+cnt, '')
				update_caption_table(t, i, cnt, '') -- add new nested table for future new take which will be inserted
				end
			end
		end
	end
	
	
	local function warning(str, extra_takes)
	local opt = extra_takes or 'The entire item is'
	return #str == 0 -- if the dialogue has been sibmitted with all fields empty
	and LINE_REMOVAL_MODE == 4
	and r.MB(opt..' about to be deleted','WARNING', 1) == 2
	end
	
	local function line_limit_info(field_cnt, multi_take)
		if field_cnt > 15 then
		local msg = '    The editor only supports first 15 lines.'
		r.MB(msg..(multi_take and '\n\n\t      To edit other lines\n\n'
		..'    call the editor having the 16th take active.' or ''),'INFO', 0)
		end
	end
		
	local function delete_take(take)
	local active_take = r.GetActiveTake(r.GetMediaItemTake_Item(take)) -- store active take
	r.SetActiveTake(take)
	r.Main_OnCommand(40129, 0) -- Take: Delete active take from items
		if active_take ~= take then r.SetActiveTake(active_take) end -- restore active take
	end
	
	local function exec_action(mode, take, fx_idx)
	-- the functions are wrapped in an anonymous function
	-- to prevent their execution at the time of table construction
	-- which is inevitable
	local actions = {function() return r.TakeFX_SetEnabled(take, fx_idx, false) end, -- enabled false // bypass video proc instance
	function() return r.TakeFX_SetOffline(take, fx_idx, true) end, -- offline true // set video proc instance offline
	function() return r.TakeFX_Delete(take, fx_idx) end, function() return delete_take(take) end} -- delete video proc instance, delete take
	return actions[mode]()
	end
	
	
	
local item = r.GetSelectedMediaItem(0,0)
local act_take = r.GetActiveTake(item)
local act_take_idx = r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
local take_cnt = r.CountTakes(item)
LINE_REMOVAL_MODE = tonumber(LINE_REMOVAL_MODE) or 1
LINE_REMOVAL_MODE = LINE_REMOVAL_MODE > 0 and LINE_REMOVAL_MODE < 5 
and math.floor(LINE_REMOVAL_MODE) == LINE_REMOVAL_MODE and LINE_REMOVAL_MODE or 1
local vid_proc_idx

local t = {}

	-- Collect lines
	if not multi_take then
		if act_take then -- empty take inserted with 'Item: Add an empty take after the active take' cannot have name so it cannot be used as a caption source, neither can it be retrieved with GetActiveTake(item) or with GetTake(item, GetMediaItemInfo_Value(item, 'I_CURTAKE')), act_take will be nil // empty take also cannot have name and FX chain so caption cannot be added and video processor cannot be inserted
		local ret, name = r.GetSetMediaItemTakeInfo_String(act_take, 'P_NAME', '', false) -- isSet false
			for line in name:gmatch('[^\n]*') do
				if line then t[#t+1] = line end
			end
		end
	else -- all takes are being traversed from the top regardless of the active take
	act_take = nil
	local multi_take = take_cnt > 1
		for i=0, take_cnt-1 do
		local take = r.GetTake(item, i)
		act_take = act_take or r.GetActiveTake(item) == take and take
			if act_take then -- empty take inserted with 'Item: Add an empty take after the active take' cannot have name so it cannot be used as a caption source, neither can it be retrieved with GetActiveTake(item) or with GetTake(item, GetMediaItemInfo_Value(item, 'I_CURTAKE')), act_take will be nil // empty take also cannot have name and FX chain so caption cannot be added and video processor cannot be inserted // SO IF ACTIVE TAKE IS AN EMPTY TAKE THE TABLE WON'T BE CONSTRUCTED DUE TO act_take REMAINING FALSE UNTIL THE END OF THE LOOP
			local ret, name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- isSet false			
			local fx_idx = find_video_proc_instances(take, preset) -- ensure that there's overlay preset
				if not name:match('\n') -- ignoring takes whose name includes new line characters, because these cannot be properly handled by Type 2 multi-line editor, they can be loaded but not resaved to the same take
				and (fx_idx or not multi_take) then -- allow loading the editor when the item only has one take in which case presence of the video proc isn't necessary as it will be inserted in the caption update routine
				t[#t+1] = {take=take, idx=fx_idx, name=name}
				end
			end
		end
	end
	
	if #t == 0 then return end

line_limit_info(#t, multi_take)
	
local orig_line_cnt = #t -- store here to use in multi-take caption error message evaluation, before any new lines are added in the editor
local orig_bot_line_y = multi_take and t[#t].idx and r.TakeFX_GetParam(t[#t].take, t[#t].idx, 1) -- for multi-take caption store buttommost line y position parameter to apply it to the new bottommost line if the old is excluded or new one is added // if item only contains one take it's allowed to lack a video proc instance in which case t[#t].idx will be nil

-- Dialogue arguments, will be updated if new lines are created
local caption = ''
local field_cnt = #t

	for k, v in ipairs(t) do
	caption = caption..(k > 1 and '\n' or '')..(type(v) == 'string' and v or v.name) -- OR 'v.name or v', v.name comes from multi-take captions table, \n is used in GetUserInputs_Alt() as field separator
	end

local input = caption -- store to compare to the output because caption var will be updated to be fed back into the dialogue

local editor_type = string.upper((multi_take and 'multi-' or 'single ')..'take')
local scratch_field, output_t, output = '' -- scratch_field is declared before the dialogue so that its content is preserved when the dialogue is reloaded, hence output_t, output must follow suite to remain local, because being first initialized as GetUserInputs_Alt() return values they would have to be global for scratch_field to not be re-initialized as a local variable which will prevent its content from being accessible when the dialogue is reloaded

::RELOAD::
local i = 0
local fields = ('Line,'):rep(field_cnt):gsub('Line', function(c) i = i+1; return c..' '..i end)

output_t, output, scratch_field = GetUserInputs_Alt(editor_type..' CAPTION EDITOR', field_cnt, fields, caption, '\n', 1, scratch_field, 1) -- comment_field and empty_comm_fields true to activate Scratch field

	-- Manage
	if not output_t -- not ret -- the dialogue was closed
	then return false -- this will prevent error tooltip when the dialogue was simply closed
	else
	r.PreventUIRefresh(1)
		if output:match(Esc(operator)) then -- create new fields in the dialogue by splitting lines at the operator	and reload the dialogue
		
		split_lines(output_t, operator, multi_take and t)
		caption = table.concat(output_t, '\n') -- update for passing to GetUserInputs_Alt()
		field_cnt = #output_t -- update for passing to GetUserInputs_Alt()
		line_limit_info(field_cnt, multi_take)
		goto RELOAD
		
		else
		
			if input == output then return 'no change in the caption' end
		
		
			if not multi_take then -- single take multi-line caption
		
		-- Delete empty lines
			for i=#output_t,1,-1 do
				if #output_t[i] == 0 then
				table.remove(output_t, i)
				end
			end

			local caption = table.concat(output_t,'\n')
				-- if the editor has been submitted empty
				if warning(caption:gsub('\n',''), take_cnt > 1 and 'The active take') -- user aborted // if besides the caption source take there're other takes in the item, only the source take will be deleted under LINE_REMOVAL_MODE setting 4
				then return '' -- empty string prevents triggering of an error tooltip outside of the function
				elseif #caption:gsub('\n','') == 0 then
				exec_action(LINE_REMOVAL_MODE, act_take, vid_proc_idx)
				return '' -- empty string prevents triggering of an error tooltip outside of the function
				end

			r.GetSetMediaItemTakeInfo_String(act_take, 'P_NAME', caption, true) -- isSet true
			insert_video_proc_with_preset(act_take, preset) -- insert if absent
		
			else -- multi-take multi-line caption
			
				-- if the editor has been submitted empty
				if warning(output:gsub('\n',''), take_cnt > orig_line_cnt and 'Caption takes are') -- user aborted // if besides the caption takes there're other takes in the item, only the caption takes will be deleted under LINE_REMOVAL_MODE setting 4 // comparing original line count because if any new lines were created in the editor they won't affect the final take count because of being empty and thus ignored
				then return '' -- empty string prevents triggering of an error tooltip outside of the function
				end
				
			-- AFTER CREATION OF A NEW LINE IN THE DIALOGUE WHICH **PRECEDES** THE ORIGINAL LINE, 
			-- e.g. with syntax '\n my line', WHERE \n IS THE OPERATOR,
			-- THE NEW TAKE WILL STILL BE CREATED WHILE LINE IN THE ORIGINAL TAKE WILL BE EXCLUDED 
			-- OR IT THE TAKE WILL BE DELETED DEPENDING ON 'LINE_REMOVAL_MODE' SETTING,
			-- THAT'S BECAUSE THE NEW EMPTY LINE OCCUPIES POSITION OF THE ORIGINAL ONE IN THE LINE SEQUENCE
			-- AND new_line FIELD ISN'T ADDED TO THE TABLE INDEX CORRESPONDING TO THE LINE POSITION INSIDE split_lines() FUNCTION
			-- TO MARK IT AS NEW, SO EMPTY STRING IS INRERPRETED AS A COMMAND TO EXCLUDE THE LINE, 
			-- WHILE THE LINE WHERE THE ORIGINAL LINE TEXT REMAINS IS MARKED AS THE NEW ONE WITH THE new_line FIELD
			-- AND SINCE IT'S NOT EMPTY IT TRIGGERES CREATION OF A NEW TAKE,
			-- THE END RESULT IS TWO TAKES WITH IDENTICAL NAMES, ONE DISABLED (UNLESS DELETED) AND ANOTHER ACTIVE
			
				-- when video proc idx of the 1st take is nil, it's a single take item
				-- without a video proc, so insert one, store its idx which will invariabky be 0
				-- and store its y position parameter for comparison below in order to apply
				-- it to a new bottommost take if one was added so that it serves as a lines offset
				-- basis for Offset_Multi_Take_Caption_Lines_Vertically() function
				if not t[1].idx then
				insert_video_proc_with_preset(t[1].take, preset)
				t[1].idx = 0
				orig_bot_line_y = r.TakeFX_GetParam(t[#t].take, 0, 1) -- store buttommost line y position parameter to apply it to the new bottommost line if one is added
				end
			local lines_to_remove = {}
			local line_excl, name_upd, take_inserted
			output = output..'\n' -- append to the end so that the pattern is consistent and last line can be captured
			-- at this stage table t will include entries for takes which must correspond
			-- to caption lines including those added via the dalogue with split_lines() function
			-- where the table t was updated as well, but with added new_line field to be used as a trigger
			-- to create new takes with Duplicate_Active_Take_Contiguously() function
				for k, take_t in ipairs(t) do
				local take, fx_idx, name, new_line = take_t.take, take_t.idx, take_t.name, take_t.new_line
				local line = output:match(('.-\n'):rep(k-1)..'(.-)\n') -- k-1 to skip all previous lines, \n is used as field separator in  GetUserInputs_Alt() // OR local line = output_t[k]
					if line == '' and not new_line then -- exclude line // new_line condition is a safeguard against error message if dialogue is submitted with empty lines which have just been created for which there're no corresponding takes, take var will still be valid because original line source take gets associated with the new line entries
				
					-- do not exclude lines here and only mark the instance for processing, because if LINE_REMOVAL_MODE setting is 4 (delete) deletion will disrupt new take creation for new lines depriving them of a source take for duplication; besides that, in the scenario described at the start of the routine in upper case, if in the original take the Video processor has been bybassed/set offline/deleted, depending on LINE_REMOVAL_MODE setting, after take duplication to create a new take, Video processor will be bypassed/set offline or absent there as well
					line_excl = 1
					t[k].remov = 1					
					
					else -- update take name or add new take, if necessary, and name it
					new_line = #line > 0 and new_line -- new_line field is true if the corresponding line was created within the dialogue, so insert new take to match it, provided it's not empty, creation new take for an empty line is pointless
						if new_line then
						r.SetActiveTake(t[k-1] and t[k-1].take or take) -- set take active as duplication source for the new take using take associated with line immediately preceding the current one, continue to the explanation in the next comment // falling back on current take as an alernative probably serves an unlikely scenario but leaving just in case to prevent error
						take = Duplicate_Active_Take_Contiguously(item)
						t[k].take = take -- store pointer of the newly created take in case it will be followed by another new take so that the current take can be set active and act as its duplication source, because in order to maintain proper line order inside Duplicate_Active_Take_Contiguously() function, the duplication source for every new take must be take holding the line immediately preceding the new one
						t[k].idx = t[k].idx or 0
						take_inserted = 1
						end
						if #line > 0 and line ~= name or new_line then -- #line > 0 ensures that empty string doesn't replace take name in one of the original (not newly created) takes which can happen when newly created dialogue field is submitted empty, in which case the new take won't be created thanks to new_line condition above but the empty string will end up being applied to the original take
						r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', line, true) -- isSet true
						name_upd = 1
						end
					end
				end		
				
				if line_excl then -- exclude lines which were submitted empty
					for i=#t,1,-1 do
					local take_t = t[i]
						if take_t.remov then
						exec_action(LINE_REMOVAL_MODE, take_t.take, take_t.idx)
						table.remove(t, i) -- remove entries of excluded lines to allow accurate re-calculation of the y coordinate offset if the bottommost line has changed, because after removal the bottommost line entry will end up at the end of the table and will be easy to access
						end
					end
				end
			
				-- If some, but not all, lines were excluded or new take was inserted, update offset of the remaining lines
				if line_excl and #t > 0 or take_inserted then
				local bot_line_y = r.TakeFX_GetParam(t[#t].take, t[#t].idx, 1) -- get current bottommost line y position parameter
					if bot_line_y ~= orig_bot_line_y then
					r.TakeFX_SetParam(t[#t].take, t[#t].idx, 1, orig_bot_line_y) -- apply stored buttommost line y position parameter to the current bottommost line if the old was excluded or new one was added
					end
				r.SetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY', 1) -- if the setting was disabled after split with Split_Active_Take_Name() or the editor was used to split for the first time, set to play all takes so that all relevant take names are displayed
				r.SetActiveTake(act_take) -- ensure that the originally active take status is restored because Offset_Multi_Take_Caption_Lines_Vertically() function only addresses active video proc instances from the active take onwards
				Offset_Multi_Take_Caption_Lines_Vertically(preset) 
				end
				
			end
		end
	r.PreventUIRefresh(-1)
	end

return true

end



function find_video_proc_instances(take, preset, want_disabled)
-- want_disabled is boolean to detect disabled (bypassed or offline)
-- video proc instance in order to re-activate it

	for i=0, r.TakeFX_GetCount(take)-1 do
	local plug_type = r.TakeFX_GetIOSize(take, i)
	local vid_proc = plug_type == 6
	local ret, name = r.TakeFX_GetFXName(take, i)
	local ret, presetname = r.TakeFX_GetPreset(take, i, '')		
		if vid_proc and presetname == '' then -- will be true after bringing a video proc instance online in builds older than 7.46, in the preset list its name will be replaced with (Customized preset) https://forum.cockos.com/showthread.php?t=303014, so identify the preset by its parameter names and order
		local parm_names = {'text height', 'y position', 'x position', 'bg pad'}
			for ii=0, r.TakeFX_GetNumParams(take, i)-1 do
			local retval, parm_name = r.TakeFX_GetParamName(take, i, ii, '')
				if parm_name == parm_names[ii+1] -- +1 to match 0-based inetator count with 1-based table indexation
				or parm_name == 'text size' and ii == 0 then -- making allowance for variable name of the first parameter 
				presetname = preset
				break
				end
			end
		end
	local off = r.TakeFX_GetOffline(take, i)
	local unbypassed = r.TakeFX_GetEnabled(take, i)
		if vid_proc
		and presetname == preset and name == 'Caption'
		and (not want_disabled and not off and unbypassed or (off or not unbypassed) and want_disabled)
		then
			if want_disabled then -- reenable
			r.TakeFX_SetEnabled(take, i, true) -- enabled true
			r.TakeFX_SetOffline(take, i, false) -- offline false
			end
		return i
		end
	end
end



function get_vid_proc_preset_code_data(obj, fx_GUID, chunk, ...) -- used inside Offset_Multi_Take_Caption_Lines_Vertically()
-- vararg is list of variables or one variable to extract data of
-- each variable is a string;
-- relies on Esc() function
local chunk, ret = chunk
	if not chunk then
	local tr, take = r.ValidatePtr(obj,'MediaTrack*'), r.ValidatePtr(obj,'MediaItem_Take*')
	local obj = take and r.GetMediaItemTake_Item(obj) or obj
	local GetChunk = tr and r.GetTrackStateChunk or take and r.GetItemStateChunk
	ret, chunk = GetChunk(obj, '', false) -- isundo false
	end
local t = {...}
local fx_GUID = Esc(fx_GUID)
local code, vid_proc = {}
	for line in chunk:gmatch('[^\n\r]+') do
		if vid_proc and line:match('^FXID') then
			if not line:match(fx_GUID) then 
			-- reset, wrong take or wrong video proc instance
			code = {}
			vid_proc = nil
			else -- found, FX GUID is listed after the preset code
			break end
		elseif not vid_proc and line and line:match('^<VIDEO_EFFECT') or vid_proc then
		vid_proc = 1
		code[#code+1] = line
		end
	end
local code = table.concat(code,'\n')
	for k, var in ipairs(t) do
	t[k] = var:match('@') and code:match(var..'.-\'(.-)\'') or not var:match('@') and code:match('|%s*'..var..'="(.-)"%s*;') -- either control line or variable
	end
return t
end


function get_user_pref_video_size() -- used in Offset_Multi_Take_Caption_Lines_Vertically()
local ret, w = r.get_config_var_string('projvidw')
local ret, h = r.get_config_var_string('projvidh')
-- if not set at Peoject settings -> Video tab -> Preferred video size
-- defaults to 1280 x 720 https://forum.cockos.com/showthread.php?t=302722
return w == '0' and 1280 or w+0, h == '0' and 720 or h+0
end


function calc_caption_y_coord(y, t, H, line_cnt) -- used in Offset_Multi_Take_Caption_Lines_Vertically()

local font, size, y_pos, border = t.font, t.size, t.y, t.border -- font and y_pos value aren't used

--[[ PRODUCES THE SAME RESULT AS math.floor(size*H) below
gfx.init('',0,0,-100,-100)
gfx.setfont(16, font, size*H) -- fractional sized are rounded off
local txt_w, txt_h = gfx.measurestr(t.name)
gfx.quit()
--]]

local txt_h = math.floor(size*H) -- video proc EEL2 API's gfx_setfont() used in the overlay preset code, seems to always round down decimal values rather than round to the closest integer, which is what Lua's gfx.setfont() used above seems to do as well

txt_h = txt_h * line_cnt

local border = math.floor(txt_h*border) -- truncate instead of rounding off, because the value is truncated in the overlay preset code

-- in the overlay preset the border is accounted for in two stages because of other calculations, 
-- and border value is added to the already calculated y value while the text is drawn:
--------------------------
-- b = (border*txth)|0; -- border
-- yt = ((project_h - txth - b*2)*ypos)|0; -- y coordinate calculated with 'y position' parameter and truncated
-- gfx_str_draw(#text,xp,yt+b); -- final y coordinate
--------------------------
-- so it will be accounted for by the video proc internally and doesn't need to be added to the return value

return y - txt_h - border*2

end



function Offset_Multi_Take_Caption_Lines_Vertically(preset) -- used in Manage_Multiline_Caption()
-- offset in multi-take multi-line caption
-- by changing hight of each line with 'text height' parameter of the overlay preset

local t = {}

	for i = 0, r.CountMediaItems(0)-1 do
	local item = r.GetMediaItem(0,i)
		if r.IsMediaItemSelected(item) then
		local take_cnt = r.CountTakes(item)
		local act_take_idx = r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
		local act_take = r.GetTake(item, act_take_idx)
			if take_cnt > 1 and act_take and act_take_idx+1 < take_cnt then -- not the very last take // empty take inserted with 'Item: Add an empty take after the active take' cannot have name so it cannot be used as a caption source, neither can it be retrieved with GetActiveTake() or with GetTake(), take var will be nil			
			local video_proc_idx = find_video_proc_instances(act_take, preset)
				if video_proc_idx then
				local fx_GUID = r.TakeFX_GetFXGUID(act_take, video_proc_idx)
				local params = get_vid_proc_preset_code_data(act_take, fx_GUID, chunk, 'font', '@param1', '@param2') -- get overlay preset font setting, title of the text height and y coordinate controls // font return value is not used in final version of calc_caption_y_coord() function
				-- overlay preset where controls position and names were modified is ignored by the script
					if params[2] and (params[2]:match('text height') or params[2]:match('text size'))
					and params[3] and params[3]:match('y position') then
						for i=act_take_idx, take_cnt-1 do
						local take = r.GetTake(item, i)
							if take then -- empty take inserted with 'Item: Add an empty take after the active take' cannot have name so it cannot be used as a caption source, neither can it be retrieved with GetActiveTake() or with GetTake(), take var will be nil // empty take also cannot have name and FX chain so caption cannot be added and video processor cannot be inserted
							local video_proc_idx = find_video_proc_instances(take, preset)
								if video_proc_idx then
								local ret, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- isSet false // OR r.GetTakeName(take)
								-- this is assuming that in the user overlay preset 
								-- text height (font size), y position and bg pad parameter indices 
								-- will be the same as in the built-in preset
								local font_size = r.TakeFX_GetParam(take, video_proc_idx, 0)
								local y_pos = r.TakeFX_GetParam(take, video_proc_idx, 1)
								local border = r.TakeFX_GetParam(take, video_proc_idx, 3)
								t[item] = t[item] or {}
								table.insert(t[item], {take=take, fx_idx=video_proc_idx, 
								name=take_name, font=params[1], size=font_size, y=y_pos, border=border})
								end
							end
						end
					end
				end
			end
		end
	end

	if not next(t) then return end
	
	local function count_lines(take_name)
	-- add trailing operator to catch last line if it doesn't end with one
	local cntr = 0
		for line in take_name:gmatch('[^\n]+') do
			if #line > 0 then
			cntr = cntr+1
			end
		end
	-- falling back on 1 to not affect the result of multiplication 
	-- when no new lines were found in the name
	return cntr > 0 and cntr or 1
	end	
	
local result

local W, H = get_user_pref_video_size() -- video proc API default project_h var value when no preferred size is specified in the proj settings is 720 px https://forum.cockos.com/showthread.php?t=302722, this value is needed because it's a basis for text y coordinate calculation in the overlay preset replicated with calc_caption_y_coord() function below

	for item, takes_t in pairs(t) do
	local y = H -- initial y coordinate is equal to project_h var
	local base_y, prev_size, prev_border, prev_line_cnt
		for i=#takes_t,1,-1 do -- in reverse because the heigher the take within the item the heigher its name must appear in the video and its y coordinate depends on the font size and y coordinate of captions fetched from the preceeding takes
		line_cnt = count_lines(takes_t[i].name)	
			if i < #takes_t then -- only offset names of takes above the bottommost, y pos setting of the bottommost remains intact
			y = calc_caption_y_coord(y, takes_t[i], H, line_cnt)
				if takes_t[i].size ~= prev_size or takes_t[i].border ~= prev_border or line_cnt ~= prev_line_cnt then -- if current caption text or background size settings or the number of lines (when takes contain Type 1 multi-line caption) differ from the previous (the one below it) the previously calculated base_y coordinate will provide an incorrect base value for calculation of the value to which y position parameter much be set, because the calculation must be performed relative to y coordinate of an assumed bottomost caption with parameters of the current one, i.e. when its y position parameter value is 1
				base_y = calc_caption_y_coord(H, takes_t[i], H, line_cnt) -- using video size H value as first argument to calculate y coordinate of an assumed bottomost caption with text and background size parameters of the current one and y position value 1
				end
			local val = r.TakeFX_GetParam(takes_t[i].take, takes_t[i].fx_idx, 1)
				if val ~= y/base_y then -- update if differs from current value
				r.TakeFX_SetParam(takes_t[i].take, takes_t[i].fx_idx, 1, y/base_y)
				result = '' -- to trigger undo in the main routine
				end	
			else
			base_y = calc_caption_y_coord(y, takes_t[i], H, line_cnt) -- y coordinate of the bottommost caption BEFORE multiplication by 'y position' value, i.e. at value 1 of 'y position' parameter; will only be useful if text size and y position settings of all captions are identical, will be updated in the subsequent cycles if not
			y = base_y*takes_t[i].y -- effective y coordinate of the bottommost caption AFTER multiplication by 'y position' value	
			end
		prev_size, prev_border = takes_t[i].size, takes_t[i].border -- store for comparison with parameters of each following (upper) caption during the loop
		prev_line_cnt = line_cnt
		end
	end
	
return result or 'no change in offset' 

end


local sel_item = r.GetSelectedMediaItem(0,0)
	if not sel_item then
	Error_Tooltip('\n\n no selected items \n\n', 1,1) -- caps, spaced true
	return r.defer(no_undo) end
	
	
OPERATOR = #OPERATOR:gsub('%s+','') > 0 and OPERATOR or '\\n'
OVERLAY_PRESET = #OVERLAY_PRESET:gsub('%s+','') > 0 and OVERLAY_PRESET or 'Overlay: Text/Timecode'

r.Undo_BeginBlock()

local multi_take = r.GetMediaItemInfo_Value(sel_item, 'B_ALLTAKESPLAY') == 1

local msg, undo

local result = Manage_Multiline_Caption(multi_take, OPERATOR, OVERLAY_PRESET) -- multi_take arg depends on 'Play all takes' setting being ON
	if result and result == true then -- boolean
	undo = 'Edit '..(multi_take and 'multi-' or 'single ')..'take multi-line caption'
	else -- result is nil or false or message
	msg = result or result == false and '' or 'either not multi-line caption, \n\n\tor no video processor \n\n     or it\'s bypassed/offline, \n\n\tor no overlay preset \n\n "'..OVERLAY_PRESET..'"' -- result is a message or is false if dialogue was closed or nil
	end
	
	if msg and not undo then
		if #msg > 0 then
		Error_Tooltip('\n\n '..msg..' \n\n', 1,1) -- caps, spaced true
		end
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
	return r.defer(no_undo)
	end

r.Undo_EndBlock(undo, -1)



