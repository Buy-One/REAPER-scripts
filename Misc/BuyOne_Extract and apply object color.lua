--[[
ReaScript name: BuyOne_Extract and apply object color.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
About:  Apply color of one object to other objects. Can be done manually
	but it's tedious.
	
	Objects are: tracks, items, takes, envelopes, project markers/regions
	
	Order of source objects precedence at the extraction stage:
	
	1. Objects at the mouse cursor: project marker, region, 
	take (in multi-take items), item, TCP (track control panel)
	Among these take and item have precedence over merker/region 
	if both object types are found at the mouse cursor.
	For project marker, region to be detected as a source the mouse
	cursor must be located within the Arrange area; 
	2. Objects at the edit cursor: project marker, region  
	Edit cursor must be aligned with marker or with region start/end; 
	3. Selected envelope
	'Send Volume' and 'Send Pan' envelopes aren't supported due
	to REAPER color assignment mechanism;  
	4. Selected/active objects in the active context  
	Active context Arrange: active take (in multi-take items), item
	Active context Track: track  
	The contexts are activated with the mouse click within Arrange
	or within the Tracklist respectively.
	
	Order of target objects precedence at the application stage:
	
	1. Objects at the mouse cursor: take (in multi-take items), item, 
	TCP, project marker/region;
	Among these take and item have precedence over merker/region 
	if both object types are found at the mouse cursor;		
	2. Project markers, regions within time selection;
	Alignment with the time selection start/end is considered being
	within time selection;  
	3. Selected/active objects in the active context 
	Active context Arrange: active takes (in multi-take items), items
	Active context Track: tracks  
	The contexts are activated with the mouse click within Arrange
	or within the Tracklist respectively.
	
	Refer to the current context readout in the Apply dialogue making
	sure that it matches the one you're aiming at.
	
	Applying color to envelopes isn't supported because the applied 
	color cannot be saved with the project anyway. If it's not saved
	into the theme it will be loaded from reaper.ini file on the next 
	REAPER startup and apply to all projects.
	
	With MIDI items and tracks the color may differ depending on whether 
	their default non-selected and selected state colors are customized 
	in the 'Theme development / tweaker' dialogue'. However the color 
	which is extracted and applied is that of the non-selected state.
	
	Once color is applied to selected tracks/items they get de-selected
	so that the new color is apparent.
	
	Once color is applied it's cleared from the buffer.
	To clear the stored color from the buffer without applying it, make
	sure that there're no markers/regions within time selection or at the 
	mouse cursor, then: 
	A1) Deselect all items (by default it's left click within Arrange area)
	or deselect all items and click within the Arrange area
	OR
	A2) Deselect all tracks and click empty space beneath the track list
	(this option is less convenient)
	B) Run the script and assent to the prompt.
	Alternatively run the script, remove color codes from the Apply
	dialogue and click OK, in which case no prompt will be called.
	
	When there's color data in the buffer the script toggle state is ON.
	If the script is linked to a toolbar button or a menu item these
	are lit or checkmarked respectively while its toggle state is ON.

]]


local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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


function GetUserInputs(title, field_cnt, field_names, field_cont, separator, comment_field, comment)
-- title string, field_cnt integer, field_names string separator delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string unless they must be initially filled
-- to fill out only specific fields precede them with as many separator characters
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5
-- separator is a sring, character which delimits the fields
-- comment_field is boolean, comment is string to be displayed in the comment field
	if field_cnt == 0 then return end

	local function add_separators(field_cnt, field_cont, sep)
	-- add delimiting separators when they're fewer than field_cnt
	-- due to lacking field names or field content
	local _, sep_cnt = field_cont:gsub(sep,'')
	return sep_cnt == field_cnt-1 and field_cont -- -1 because the last field isn't followed by a separator
	or sep_cnt < field_cnt-1 and field_cont..(sep):rep(field_cnt-1-sep_cnt)
	end

-- for field names sep must be a comma because that's what field names list is delimited by
-- regardless of internal 'separator=' argument
local field_names = type(field_names) == 'table' and table.concat(field_names,',') or field_names
field_names = add_separators(field_cnt, field_names, ',')
local sep = separator or ','
local field_cont = add_separators(field_cnt, field_cont, sep)
local comment = comment_field and #comment > 0 and comment or ''
local field_cnt = comment_field and #comment > 0 and field_cnt+1 or field_cnt
field_names = comment_field and #comment > 0 and field_names..',Comment:' or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = separator and ',separator='..separator or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=150'..separator, field_cont)
output = #comment > 0 and output:match('(.+'..sep..')') or output -- exclude comment field keeping separator to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement
	if not ret then return 'cancel'
	elseif field_cnt > 1 and output:gsub(' ','') == (sep):rep(field_cnt-1)
	or #output:gsub(' ','') == 0 then return 'empty' end
local t = {}
	for s in output:gmatch('(.-)'..sep) do
		if s then t[#t+1] = s end
	end
return t, output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it
end



function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end



function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
-- also see https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
-- but in X-Raym's template get_action_context() isn't used also outside of the function
-- it's been noticed that if it is, then inside a function it won't return proper values
-- so my version accounts for this issue
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end



function Get_TCP_Under_Mouse() -- based on the function Get_Object_Under_Mouse_Curs()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
-- master track is supported
local right_tcp = r.GetToggleCommandStateEx(0,42373) == 1 -- View: Show TCP on right side of arrange
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor // https://forum.cockos.com/showthread.php?t=227524#2 the function has 6 arguments; screen_x_start and screen_x_end (3d and 4th args) are not return values, they are for specifying where start_time and end_time should be on the screen when non-zero when isSet is true // when the Arrange is scrolled all the way to the start the function ignores project start time offset and any offset start still treats as 0
--local TCP_width = tonumber(cont:match('leftpanewid=(.-)\n')) -- only changes in reaper.ini when dragged
r.PreventUIRefresh(1)
local edge = right_tcp and start_time-5 or end_time+5
r.SetEditCurPos(edge, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +/-5 sec to move edit cursor beyond right/left edge of the Arrange view to be completely sure that it's far away from the mouse cursor // if start_time is 0 and there's negative project start offset the edit cursor is still moved to the very start, that is past 0, the function ignores negative start offset therefore is fully compatible with GetSet_ArrangeView2()
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping // works along the entire screen Y axis outside of the TCP regardless of whether the program window is under the mouse
local new_cur_pos = r.GetCursorPosition()
local tcp_under_mouse = new_cur_pos == edge or new_cur_pos == 0 -- if the TCP is on the right and the Arrange is scrolled all the way to the project start or close enough to it start_time-5 won't make the edit cursor move past the project start hence the 2nd condition, but it can move past the right edge
-- Restore orig. edit cursor pos
--[[
local min_val, subtr_val = table.unpack(new_cur_pos == edge and {curs_pos, edge} -- TCP found, edit cursor remained at edge
or new_cur_pos ~= edge and {curs_pos, new_cur_pos} -- TCP not found, edit cursor moved
or {0,0})
r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
--]]
--[-[ OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
--]]
r.PreventUIRefresh(-1)

return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())

end



function Get_Marker_Reg_At_Mouse_Or_EditCursor(to_apply)
-- to_apply is a boolean for the application stage to only get marker/region at mouse cursor
-- because if after the color is extracted from marker/region at edit cursor it is likely
-- to remain there and will trigger context of the same marker/region overriding other context
-- because it's higher in the order of precedence

	local function get_mrkr_reg(cur_pos)
	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name, ID, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
			if retval > 0 and (pos == cur_pos or isrgn and rgnend == cur_pos) then
			return color, {idx=i, isrgn=isrgn, pos=pos, rgnend=rgnend, name=name, ID=ID}
			end
		i = i+1
		until retval == 0 -- until no more markers/regions
	end

local cur_pos = r.GetCursorPosition()
local color, mrkr_reg_props_t

	if not to_apply then -- only at the extraction stage
	color, mrkr_reg_props_t = get_mrkr_reg(cur_pos) -- at the edit cursor
	end

	if not color and r.GetTrackFromPoint(r.GetMousePosition()) then -- the edit cursor is not aligned with marker or region start/end // look for these at the mouse cursor // GetTrackFromPoint() prevents this context from activation if the script is run from a toolbar or the Action list window floating over Arrange or if mouse cursor is outside of Arrange
	r.PreventUIRefresh(1)
	ACT(40513) -- View: Move edit cursor to mouse cursor [with snapping so it can snap to marker / region start/end]
	local new_cur_pos = r.GetCursorPosition()
	color, mrkr_reg_props_t = get_mrkr_reg(new_cur_pos)
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit curs pos
	r.PreventUIRefresh(-1)
	end

	if color then
	local key = not mrkr_reg_props_t.isrgn and 'marker' or 'region'
	color = color == 0 and r.GetThemeColor(key, 0) -- get default theme color, determined by the settings in the 'Theme development/tweaker' dialogue: Markers, Regions
	or color -- either default theme color or custom
	local rgb = {r.ColorFromNative(color)}
	local hex_color = rgb2hex(table.unpack(rgb))
	return hex_color, rgb, color|0x1000000, mrkr_reg_props_t
	end

end


function Get_Marker_Reg_In_Time_Sel(mrkrs, rgns)
-- both args are booleans
local t, i = {}, 0
local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false

	if start == fin then return end -- no time selection

	repeat
	local retval, isrgn, pos, rgnend, name, ID = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
		if rgns and isrgn
		and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin -- region start or end is within time sel
		or pos >= start and rgnend <= fin) -- whole region is within time sel
		or not isrgn and mrkrs and pos >= start and pos <= fin
		then
		t[#t+1] = {idx=i, isrgn=isrgn, pos=pos, rgnend=rgnend, name=name, ID=ID} -- color isn't needed because to markers/regions in time selection it's only applied
		end
	i = i+1
	until retval == 0 -- until no more markers/regions

	if #t > 0 then return t end

end



function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function rgb2hex(r, g, b)
-- https://gist.github.com/yfyf/6704830
    return string.format("%0.2X%0.2X%0.2X", r, g, b)
end


function Get_Env_Custom_Colors()
-- suffices that the String is included in the FX param name
-- color associated with the first string match is applied
local path = r.GetResourcePath()
local sep = path:match('[\\/]')
local path = path..sep..'reaper-env-colors.ini'
	if r.file_exists(path) then
	local f = io.open(path,'r')
	local data = f:read('*a')
	f:close()
	local t = {}
		for line in data:gmatch('[^\n\r]+') do
			if line and line:match('%d') == '1' then -- enabled
			local name, hex = line:match('%d "?(.*)"? (.+)')
				if name and hex then
				t[name] = hex
				end
			end
		end
	return t
	end
end



function Extract_Color(obj)
-- obj is track, item, active take (in multi-take items), envelope

local env_col_key_t = {
tr = {
	['Playrate'] = 'col_env5', -- Envelope: Master playrate -- current RGB: 0,0,0
	['Tempo map'] = 'col_env6', -- Envelope: Master tempo -- current RGB: 0,255,255
	['Volume (Pre-FX)'] = 'col_env1', -- Envelope: Volume (pre-FX) -- current RGB: 0,220,128
	['Volume'] = 'col_env2', -- Envelope: Volume -- current RGB: 64,128,64
	['Pan (Pre-FX)'] = 'col_env3', -- Envelope: Pan (pre-FX) -- current RGB: 255,0,0
	['Pan'] = 'col_env4', -- Envelope: Pan -- current RGB: 255,150,0
	['Trim Volume'] = 'env_trim_vol', -- Envelope: Trim Volume -- current RGB: 0,0,0
	-- Until build 6.11 Trim volume env color was linked to Master track playrate envelope color
	-- https://forum.cockos.com/showthread.php?t=235873
	-- 6.11 changelog: Themes: allow separate configuration of Trim Volume envelope color
	['Mute'] = 'env_track_mute', -- Envelope: Mute -- current RGB: 192,0,0
	['Width'] = 'col_env7', -- Envelope: Send volume -- current RGB: 128,0,0 // incl. pre-FX width
	-- Width color wasn't documented until build 6.59 https://forum.cockos.com/showthread.php?t=267111
	-- 6.59 changelog: Theme: update theme tweaker description for shared theme color
	['Send Mute'] = 'env_sends_mute', -- Envelope: Send mute -- current RGB: 192,192,0
--[[
	Send Volume/Pan (2) explanation https://forum.cockos.com/showthread.php?t=260829
	the color depends on the original order of the sends in the list of receives
	in the desination track: odd - regular color, even - color 2
	BUT if one of the volume/pan sends is deleted the env colors don't update to match the new order
	so there's no way to know which of the colors is active because deleted envelopes
	cannot be accounted for
	hence getting both regular send/volume and send/volume 2 env color is not supported
	['Send Volume'] = 'col_env7', -- Envelope: Send volume -- current RGB: 128,0,0 // same as prev
	['Send Pan'] = 'col_env8', -- Envelope: Send pan -- current RGB: 0,128,128
	'col_env9', -- Envelope: Send volume 2 -- current RGB: 0,128,192
	'col_env10', -- Envelope: Send pan 2 -- current RGB: 0,64,0
--	]]
	['Audio Hardware Output: Volume'] = 'col_env11', -- Envelope: Audio hardware output volume -- current RGB: 0,255,255
	['Audio Hardware Output: Pan'] = 'col_env12', -- Envelope: Audio hardware output pan -- current RGB: 255,255,0
	['Audio Hardware Output: Mute'] = 'env_sends_mute' -- Envelope: Send mute -- current RGB: 192,192,0 // same as ['Send Mute']
	},
take = {
	['Volume'] = 'env_item_vol', -- Envelope: Item take volume -- current RGB: 128,0,0
	['Pan'] = 'env_item_pan', -- Envelope: Item take pan -- current RGB: 0,128,128
	['Mute'] = 'env_item_mute', -- Envelope: Item take mute -- current RGB: 192,192,0
	['Pitch'] = 'env_item_pitch' -- Envelope: Item take pitch -- current RGB: 0,255,255
	},
fx = {
	[0] = 'col_env13', -- Envelope: FX parameter 1 -- current RGB: 128,0,255
	[1] = 'col_env14', -- Envelope: FX parameter 2 -- current RGB: 64,128,128
	[2] = 'col_env15', -- Envelope: FX parameter 3 -- current RGB: 0,0,255
	[3] = 'col_env16' -- Envelope: FX parameter 4 -- current RGB: 255,0,128
	}
}

	local function extract_itm_take_color(color, obj, is_take, is_itm)
	-- item take color if not set explicitly is inherited from the item if item color has been customized and is take default color
	local GetItm, GetTr = r.GetMediaItemInfo_Value, r.GetMediaTrackInfo_Value
		if is_take and color == 0 then -- default take color, i.e. may be inherited from item if item color has been customized, get item color
		local item = r.GetMediaItemTake_Item(obj)
		local color = GetItm(item, 'I_CUSTOMCOLOR')
			-- item color if not set explicitly is inherited from the track if track color has been customized and is item default color
			if color == 0 then -- default item color, inherited from track if track color has been customized, get track color
			color = GetTr(r.GetMediaItemTrack(item), 'I_CUSTOMCOLOR')
				if color ~= 0 and color ~= 16576 then return color end -- only return if not default track color because only in this case it overrides item default color // track default color integer is 16576 immediatedly after REAPER startup which equals 192,64,0 - RGB, the color selected in the track color picker by default but not applied; if 'Track: Set to default color' action was applied at least once the value becomes 0 (relevant to versions 5 - 7, didn't test earlier)
			else -- item custom color
			return color
			end
		-- item color if not set explicitly is inherited from the track if track color has been customized and is item default color
		elseif is_itm and color == 0 then -- default item color, inherited from track if track color has been customized, get track color
		local color = GetTr(r.GetMediaItemTrack(obj), 'I_CUSTOMCOLOR')
			if color ~= 0 and color ~= 16576 then return color end -- only return if not default track color because only in this case it overrides item default color // see comment above
		end
	return color -- no change
	end

local is_tr, is_itm, is_take, is_env = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem*'),
r.ValidatePtr(obj, 'MediaItem_Take*'), r.ValidatePtr(obj, 'TrackEnvelope*')
local GET = is_tr and r.GetMediaTrackInfo_Value or is_itm and r.GetMediaItemInfo_Value
or r.GetMediaItemTakeInfo_Value
local color

	if is_env then
	local retval, env_name = r.GetEnvelopeName(obj)
	local tr_env = obj == r.GetSelectedTrackEnvelope(0)
	local custom_env_col_t = Get_Env_Custom_Colors()
	-- first try to tetrieve custom color, supported since REAPER 7
	-- if none set or not REAPER 7 custom_env_col_t will be nil
		if custom_env_col_t then
			for name, hex_color in pairs(custom_env_col_t) do
				if env_name:match(Esc(name)) then -- all types of envelopes
				-- suffices that the String is included in the FX param name
				-- color associated with the first string match is applied
				local rgb = {hex2rgb(hex_color)}
				return hex_color, rgb, r.ColorToNative(table.unpack(rgb))|0x100000
				end
			end
		end
	--	if custom color wasn't returned, look for theme colors
		if env_name == 'Send Volume' or env_name == 'Send Pan' then
		local err = ' send volume/pan envelope color \n\n   cannot be extracted reliably'
		Error_Tooltip('\n\n'..err..'\n\n', 1,1) -- caps, spaced true
		return 'env error'
		end
	local key = tr_env and env_col_key_t.tr[env_name] or env_col_key_t.take[env_name]
		if not key then -- fx envelope
		local GetParentObj, GetParmName =
		table.unpack(tr_env and {r.Envelope_GetParentTrack, r.TrackFX_GetParamName}
		or {r.Envelope_GetParentTake, r.TakeFX_GetParamName})
		local par_obj, fx_idx, parm_idx = GetParentObj(obj)
		key = parm_idx <= 4 and parm_idx or parm_idx%4 -- env colors repeat every 4 parameters
		key = env_col_key_t.fx[key]
		end
	color = key and r.GetThemeColor(key, 0) -- 0 current color rather than theme's default
	elseif obj then -- objects other than envelope
	color = GET(obj, 'I_CUSTOMCOLOR')
	color = is_tr and color or extract_itm_take_color(color, obj, is_take, is_itm)
	end

-- https://www.color-hex.com/

local tr_color_alt

	if color and not is_env then -- process color of objects other than envelope
	-- col_mi_bg (Media item odd tracks) until 7.15 was officially referring to odd tracks when in fact refers to even	
	-- col_mi_bg2 (Media item even tracks) until 7.15 was officially referring to even tracks when in fact refers to odd
	-- bug report https://forum.cockos.com/showthread.php?t=289479
	-- col_tr1_itembgsel (Media item selected odd tracks)
	-- col_tr2_itembgsel (Media item selected even tracks)
	-- col_seltrack : Selected track control panel background
	-- col_seltrack2 : Unselected track control panel background (enabled with 'Theme overrides' checkbox above) // if the checkbox is enabled the color integer is negative otherwise positive, should be used as is
	local key
	local tr_default_col = color == 16576 or color == 0 -- default (theme settings dependent) color // track default color integer is 16576 immediatedly after REAPER startup which equals 192,64,0 - RGB, the color selected in the track color picker by default but not applied; if 'Track: Set to default color' action was applied at least once the value becomes 0 (relevant to versions 5 - 7, didn't test earlier)
		if is_tr and tr_default_col then
		key = 'col_seltrack2' -- only non-selected state color is extracted
		elseif (is_take or is_itm) and color == 0 then -- default theme settings dependent color
		local obj = is_take and r.GetMediaItemTake_Item(obj) or obj
		local tr_No = r.CSurf_TrackToID(r.GetMediaItemTrack(obj), false) -- mcpView false // get track number because default item color may differ on odd and even tracks if changed in the 'Theme development/tweaker' dialogue and will be displayed if their track color isn't custom
		key = tr_No%2 > 0 and 'col_mi_bg2' or tr_No%2 == 0 and 'col_mi_bg' -- non-selected on odd or even track, until build 7.15 these were mixed up in the 'Theme development/tweaker', see link to bug report above, the bug fix was cosmetic with no change in the keys association
		end
	color = key and r.GetThemeColor(key, 0) -- get default theme color, determined by the setting in the 'Theme development/tweaker' dialogue: Media item background (odd, even), Unselected track control panel background
	or color -- either default theme color or custom
	tr_color_alt = is_tr and tr_default_col and color > 0 and r.GSC_mainwnd(4) -- default unselected track color value is negative when 'Theme overrides' checkbox is enabled, i.e. theme default rather than OS default background color is used, when it's positive the OS default background color is used // thanks to cfillion https://forum.cockos.com/showthread.php?t=289509#7 for helping to figure out a way to retrieve the OS default background color, COLOR_WINDOW attribute for Win32 GetSysColor() https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsyscolor
	-- the default OS background color appears to only be relevant to derivates of the Classic theme, v5 and v6 default themes
	end

	if color then
	local rgb = {r.ColorFromNative(color)}
	local hex_color = rgb2hex(table.unpack(rgb))
	return hex_color, rgb, color|0x1000000, tr_color_alt and tr_color_alt|0x1000000
	end

end


function Extract_Stored_Colors(colors)
local hex_color, rgb, native_color = colors:match('(.-);(.-);(.+)')
local native_color, tr_color_alt = table.unpack(native_color:match(';')
and {native_color:match('(.-);(.+)')} or {native_color})
return hex_color, {rgb:match('(%d+),(%d+),(%d+)')}, native_color, tr_color_alt
end


function CLEAR_COLOR_TOGGLE_OFF(mess, title, named_ID, sect_ID, cmd_ID, typ)
local resp = r.MB(mess,title, typ or 4)
	if resp == 7 and typ == 3 then -- NO, typ 3 Yes/No/Cancel
	return true -- to trigger RETRY to apply alt track color
	elseif resp == 6 then -- YES if typ 4 or 3
	r.DeleteExtState(named_ID, 'COLOR', true) -- persist false
	Re_Set_Toggle_State(sect_ID, cmd_ID, 0)
	end
end


-- MAIN ROUTINE


local sel_env = r.GetSelectedEnvelope(0)
local x, y = r.GetMousePosition()
local item_at_mouse, take_at_mouse = r.GetItemFromPoint(x, y, true) -- allow_locked true
local build_6_36 = tonumber(r.GetAppVersion():match('[%d%.]+')) >= 6.36 -- 1st build in which GetThingFromPoint() is supported
local tcp_at_mouse = build_6_36 and ({r.GetThingFromPoint(x,y)})[2]:match('tcp') or Get_TCP_Under_Mouse()
tcp_at_mouse = tcp_at_mouse and r.GetTrackFromPoint(x,y)
local timeline = r.GetTrackFromPoint(x, y)
local ctx = r.GetCursorContext2(true) -- want_last_valid true
local tr_ctx, itm_ctx = ctx == 0, ctx == 1
local track = tcp_at_mouse or tr_ctx and r.GetSelectedTrack2(0,0, true) -- wantmaster true
local item = item_at_mouse or itm_ctx and r.GetSelectedMediaItem(0,0)
local take = item and r.CountTakes(item) > 1 and (take_at_mouse or r.GetActiveTake(item))

local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val = r.get_action_context() -- placed here because it seems to affect GetThingFromPoint() ( and GetTrackFromPoint() ) if placed before it in a scenario when the script is run after manual closure of ReaScript Console, strange intermittent behavior
local named_ID = r.ReverseNamedCommandLookup(cmd_ID) -- convert to named

local colors = r.GetExtState(named_ID, 'COLOR')

local hex_color, rgb, native_color, mrkr_reg_props_t = Get_Marker_Reg_At_Mouse_Or_EditCursor(#colors > 0) -- to_apply is true at the application stage only // get at edit/mouse cursor at the extraction stage and only at mouse cursor at the application stage
local mrkr_reg_t = Get_Marker_Reg_In_Time_Sel(1, 1) -- mrkrs, rgns true // marker/region context for application stage only


	if #colors > 0 then	-- apply, envelopes aren't supported

	local sel_itms_cnt = r.CountSelectedMediaItems(0)
	local sel_tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true
	local hex_color, rgb, native_color, tr_color_alt = Extract_Stored_Colors(colors)

	-- the dialogue is only for representation, feedback and ablility to copy color values if needed
	-- the actual useful values are native_color and tr_color_alt taken from the extended state, the last one is returned by Extract_Color() function and stored when 'Theme overrides normal Windows colors' checkbox is disabled in 'Theme development/tweaker' dialogue because in this case in some themes, v5 and v6 default in particular, the actual displayed track color will be OS color and not the one set in the said dialogue

	local ctx = item_at_mouse and (take and 'Take' or 'Item') or tcp_at_mouse and 'Tracks' -- take/item/tcp under mouse
	or mrkr_reg_props_t and 'Marker/Region at cursor' -- marker/region under mouse
	or mrkr_reg_t and 'Markers/Regions in time selection'
	or take and 'Take' or item and 'Items' or track and 'Tracks' -- selected items (active take) / tracks

	ctx = ctx or not item_at_mouse and itm_ctx and sel_itms_cnt == 0 and 'Items: no selected items'
	or not tcp_at_mouse and tr_ctx and sel_tr_cnt == 0 and 'Tracks: no selected tracks'

		if not ctx or ctx:match('no selected') then
		local mess = ctx and (ctx:match('items') and '  ' or '')..'CONTEXT '..ctx:upper() or '\tNO VALID CONTEXT.'
		mess = mess..'\n\n   WISH TO CLEAR THE COLOR DATA\n\n\tFROM THE BUFFER?'
		CLEAR_COLOR_TOGGLE_OFF(mess, 'ERROR', named_ID, sect_ID, cmd_ID)
		return r.defer(no_undo) end

	local title = 'APPLY COLOR : Context - '..ctx
	local sep = ';'
	local field_cont = table.concat(rgb, ', ')..sep..hex_color
	local outputs_t, output = GetUserInputs(title, 2, 'RGB,Hexadecimal', field_cont, sep) -- separator is sep, comment_field, comment are nil

		if outputs_t == 'empty' then -- dialogue was submitted empty, clear color from extended state
		r.DeleteExtState(named_ID, 'COLOR', true) -- persist false
		Re_Set_Toggle_State(sect_ID, cmd_ID, 0)
		return r.defer(no_undo)
		elseif outputs_t == 'cancel' then return r.defer(no_undo)-- dialogue was cancelled or submitted empty
		end

	::RETRY::

	r.Undo_BeginBlock()
	native_color = native_color+0 -- convert to numeral
	local parm = 'I_CUSTOMCOLOR'
	local t = t or {itms = {}, tr = {}} -- to collect selected objects in case of a retry loop to be able to re-select them beforehand, because they get deselected in the process

		if take_at_mouse then -- take/item at mouse cursor
			if r.CountTakes(r.GetMediaItemTake_Item(take_at_mouse)) > 1 then
			r.SetMediaItemTakeInfo_Value(take_at_mouse, parm, native_color)
			else
			r.SetMediaItemInfo_Value(item_at_mouse, parm, native_color)
			end
			if r.IsMediaItemSelected(item_at_mouse) then
			r.SetMediaItemSelected(item_at_mouse, false) -- deselect to reveal applied color
			t.itms[1] = item_at_mouse
			end
		r.UpdateItemInProject(item_at_mouse)

		elseif tcp_at_mouse then -- track at mouse cursor
		r.SetMediaTrackInfo_Value(tcp_at_mouse, parm, native_color)
			if r.IsTrackSelected(tcp_at_mouse) then
			r.SetTrackSelected(tcp_at_mouse, false) -- deselect to reveal applied color
			t.tr[1] = tcp_at_mouse
			end

		elseif mrkr_reg_props_t then -- or any other two return values of Get_Marker_Reg_At_Mouse_Or_EditCursor() instead of mrkr_reg_props_t
		local t = mrkr_reg_props_t -- for brevity
		r.SetProjectMarkerByIndex(0, t.idx, t.isrgn, t.pos, t.rgnend, t.ID, t.name, native_color)

		elseif mrkr_reg_t then -- markers/regions within time selection
			for _, t in ipairs(mrkr_reg_t) do
			r.SetProjectMarkerByIndex(0, t.idx, t.isrgn, t.pos, t.rgnend, t.ID, t.name, native_color)
			end

		elseif itm_ctx then -- Arrange context
			for i=0, sel_itms_cnt-1 do
			local item = r.GetSelectedMediaItem(0,i)
			t.itms[#t.itms+1] = item
			local takes_cnt = r.CountTakes(item)
				if takes_cnt > 1 then
				r.SetMediaItemTakeInfo_Value(r.GetActiveTake(item), parm, native_color)
				elseif takes_cnt > 0 then -- not an empty item
				r.SetMediaItemInfo_Value(item, parm, native_color)
				end
			r.UpdateItemInProject(item)
			end
		r.SelectAllMediaItems(0, false) -- selected false // deselect all to reveal deselected state color

		elseif tr_ctx then -- Track context
			for i=0, sel_tr_cnt-1 do
			local tr = r.GetSelectedTrack2(0,i,true) -- wantmaster true
			t.tr[#t.tr+1] = tr
			r.SetMediaTrackInfo_Value(tr, parm, native_color)
			end
		-- deselect all tracks to reveal deselected state color
		local tr = r.GetTrack(0,0)
		r.SetOnlyTrackSelected(tr)
		r.SetTrackSelected(tr, false) -- selected false

		end

	r.Undo_EndBlock('Apply #'..hex_color..' color to '..(ctx:match('Marker%a?/Region%a?') or ctx), -1)

	local mess = not tr_color_alt and 'CLEAR THE COLOR DATA FROM THE BUFFER?'
	or 'IF THE APPLIED COLOR DIFFERS FROM THE EXTRACTED COLOR'
	..'\n\nIT\'S POSSIBLE THAT THE EXTRACTED TRACK COLOR IS OS DEFAULT COLOR.'
	..'\n\nCLICK  "NO"  TO RE-APPLY IT AND EXIT.\n\nCLICK  "YES"  TO KEEP COLOR '
	..'AND DELETE IT FROM THE BUFFER.\n\nCLICK  "CANCEL"  TO KEEP COLOR AND EXIT.'
	local typ = not tr_color_alt and 4 or 3 -- 4 Yes/No, 3 Yes/No/Cancel
		if not RETRY then -- to prevent re-loading after one retry
		RETRY = CLEAR_COLOR_TOGGLE_OFF(mess, 'PROMPT', named_ID, sect_ID, cmd_ID, typ)
			if RETRY then
			r.Undo_DoUndo2(0)
			native_color = tr_color_alt
			-- convert alt color to hex to list in the undo point name
			local R,G,B = r.ColorFromNative(tr_color_alt)
			hex_color = rgb2hex(R, G, B)
			-- re-select originally selected objects, if any, after their deselection above
				for _, itm in ipairs(t.itms) do
				r.SetMediaItemSelected(itm, true) -- selected true
				r.UpdateItemInProject(item)
				end
				for _, tr in ipairs(t.tr) do
				r.SetTrackSelected(tr, true) -- selected true
				end
			goto RETRY
			end
		end

	else -- extract

	local typ = item_at_mouse and (take and 'take' or item and 'item') or tcp_at_mouse and track and 'track' -- objects at mouse cursor
	or rgb and (mrkr_reg_props_t.isrgn and 'region' or 'marker')
	or sel_env and 'selected envelope'
	or take and 'take' or item and 'item' or track and 'track' -- selected item (active take) / track

	local mess

		if not rgb then -- no marker / region start/end at mouse/edit cursor, explore other objects
		hex_color, rgb, native_color, tr_color_alt = Extract_Color(sel_env or take or item or track) -- tr_color_alt is only returned if 'Theme overrides normal Windows colors' option is disabled in the 'Theme development/tweaker dialogue' to condition special option for apply track color dialogue
		end

		if not typ then
		mess = 'no valid context'
		elseif not rgb and hex_color ~= 'env error' then -- or native_color return value instead of rgb, hex_color is returned as 'env error' when 'Send Volume/Pan (2)' envelopes happen to be selected because their color cannot be reliably extracted for reasons explained in the comments to env_col_key_t table inside Extract_Color() function
		mess = 'the '..typ..' color \n\n could not be extracted'

		elseif rgb then -- or hex_color or native_color return values instead of rgb, store
		local colors = hex_color..';'..table.concat(rgb,',')..';'..native_color..(tr_color_alt and ';'..tr_color_alt or '')
		local mess = 'Extract '..typ..' color?'
		local resp = r.MB(mess:upper(),'PROMPT',1)
			if resp == 2 then -- cancel
			return r.defer(no_undo) end
		r.SetExtState(named_ID, 'COLOR', colors, false) -- persist false
		Re_Set_Toggle_State(sect_ID, cmd_ID, 1)
		end

		if mess then
		Error_Tooltip('\n\n '..mess..' \n\n', 1,1) -- caps, spaced true
		end


	return r.defer(no_undo)

	end





