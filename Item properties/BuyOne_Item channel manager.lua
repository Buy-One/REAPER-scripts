--[[
ReaScript name: BuyOne_Item channel manager.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script is geared towards helping tp manage
		multi-channel audio media files treating their
		channels as takes within item. Simultaneous
		playback of several channels represented by takes
		is achieved by enabling 'Play all takes' setting
		in the Media Item Properties which is ensured
		by the script when a channel is added/removed.

		IF SOME CHANNELS IN THE MEDIA FILE ARE PANNED, 
		WHEN THEY'RE ADDED BY THE SCRIPT AS TAKES TO AN 
		ITEM THE ORIGINAL STEREO OR SURROUND IMAGE IS NOT 
		PRESERVED, BECAUSE TAKES ARE PANNED DEAD CENTER, 
		SO THE STEREO IMAGE WILL HAVE TO BE RESTORED BY 
		MANUAL PANNING OF THE TAKES, WHICH, DEPENDING 
		ON THE CURCUMSTANCE, MAY NOT BE AN OPTIMAL 
		SOLUTION.

		The script first looks for item under mouse cursor, 
		if not found looks for selected items. Take under
		mouse is ignored, therefore even in item under mouse
		the script affects all valid takes or the active take
		if settings 3 or 4 (see below) are enabled.

		The main menu lists numbers of all channels available
		in the media source of item under mouse or selected.
		Numbers of channels active within takes are checkmarked.
		When setting 3 is enabled (see next) only number of
		channel enabled in the active take is checkmarked and
		if in active takes in different selected items different
		channel is enabled, no channel menu item is checkmarked.
		When setting 5 is enabled the main menu only lists the
		checkmarked number(s) of channel or channel pair 
		currently enabled in the active take and numbers of 
		channels immediately preceding and following (if any) 
		these channel or channel pair.


		SETTINGS SUBMENU

		1. Include locked items
		2. Respect 2 channel items
		3. Change active take channel
			4. Randomize channel Uniformly
		5. Add/remove/replace 2nd channel in the active take
		6. Allow different take count in multi-item selection

		These correspond to the settings in the USER SETTINGS 
		section of the script. When their state is changed via 
		the menu, it's also updated within the script.  
		Settings 3 and 5 are mutually exclusive and can be 
		disabled completely.
		Setting 4 is only accessible when setting 3 is enabled
		and it modifies behavior of 'Randomize' actions accessible 
		in the main menu.
		Setting 6 is only displayed in the menu for reference
		of its state, being grayed out. The actual setting can
		only be changed directly within the script in the USER
		SETTINGS as ALLOW_DIFFERENT_TAKE_COUNT.

		WHAT'S NOT SUPPORTED (depending on the settings)

		locked items, unless setting 1, i.e. INCLUDE_LOCKED_ITEMS, 
		is enabled;	
		single take non-audio items;
		items with audio takes having mono media source;
		items with takes having stereo media source unless setting 2, 
		i.e. RESPECT_2_CHANNEL_ITEMS, is enabled;
		* multi-take items whose audio takes have different media source;
		* selection of multiple items with different take count
		unless ALLOW_DIFFERENT_TAKE_COUNT setting is enabled;
		* selection of multiple items with different take media 
		source channel count;
		* selection of multiple items with different set of active 
		channels in takes (the order of takes is immaterial as long 
		as the set of active channels is the same, active channels
		outside of media source channel range are ignored);
		** active take in which over 2 channels are displayed 
		simultaneously;
		** active take in which number of enabled channel is outside 
		of the media source channel range

		* Limitations marked with a single asterisk DON'T apply 
		when settings 3 or 4, i.e. CHANGE_ACTIVE_TAKE_CHANNEL or 
		ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE, are enabled.
		** Limitations marked with a double asterisk ONLY apply 
		when setting 4, i.e. ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE,
		is enabled.  
		If all the above conditions for multiple items selection 
		are met but the order of takes in terms of enabled channel 
		differ in different items or ALLOW_DIFFERENT_TAKE_COUNT 
		setting is enabled and item take counts differ, the take 
		submenu will not be displayed.  
		The take submenu is also not displayed when settings 3 or 4
		are enabled.

		So basically multiple item selection is only supported when 
		items have identical take count (unless 
		ALLOW_DIFFERENT_TAKE_COUNT setting is enabled), identical 
		media source channel count, and channels having the same 
		indices being active in takes regardless of the takes own 
		order within each item.  
		The actual take media source can be different in each item as 
		long as it's common to all takes within the same item.  
		When settings 3 or 4 are enabled the limtations not marked with 
		asterisks only apply to active takes. In this case the script 
		only cares that media source channel count and active channel
		(when setting 4 is enabled) in all active takes be identical, 
		it ignores all other item properties. When setting 3 is enabled
		and active channels in active takes of selected items differ
		no menu item representing channel is checkmarked.  		

		In multi-item selection the properties of the first valid item 
		with the greatest variety of active channels are determinative. 
		Valid item is one which can be managed by the script and which 
		isn't necessarily the first item in selection.  
		ITEMS WHOSE PROPERTIES DON'T CONFORM TO THE FIRST VALID ITEM ARE 
		DESELECTED FOR CLARITY.

		The script affects channels of the same number in all selected 
		items.
		Channels whose number is outside of the media source channel 
		range are ignored by the script, BUT the takes in which they're
		enabled are still included in the item take count.

		Non-audio takes are ignored by the script unless they're active
		and chosen script operation or a setting targets active takes. 
		The script displays an error message when no active take can be 
		affected by its operation.


		M A I N  F U N C T I O N S


		ADDING/REMOVING CHANNELS

		A channel is added as a new item take where the specific 
		channel is enabled when a non-ckeckmarked menu item 
		corresponding to the schannel number is clicked and 
		checkmarked. The placement of the new take within the item 
		follows ascending order of channel numbers taking into 
		account channels enabled in other takes.  
		In an item only contains takes where all channels are 
		enabled (Normal and Reverse Stereo channel modes) UNLESS 
		the media source channel count is 2 (provided setting 2 
		is enabled) or such take volume is at or below -96 dB,
		and/or where number of the enabled channel is outside of
		the media source channel range (which is possible, i.e. 
		channel 10 is enabled for a media source with only 5 
		channels which results in lack of waveform display within 
		the take), the specific channel will be applied to the 
		first of such takes and no new take will be created.			

		A channel is removed when the menu item corresponding to
		the channel number is uncheckmarked. All instances of such
		channel are removed from the item. If such channel is active
		as a single channel within take, the entire take is removed
		unless it's the only take within the selected item. If the 
		channel is part of an active channel pair, such channel is 
		removed from the channel pair and the second channel is left 
		intact within the take.  
		A channel is not removed when it's active in item's only 
		take as mentioned above (because this will mean deletion 
		of the item itself) and if after its deletion no audio take 
		will remain within the item.  
		Channel is also not removed when the take it's active in is 
		muted, i.e. its volume is at or below -96 dB.  
		Takes in which all channels are enabled (i.e. channel modes 
		Normal and Reverse stereo) of a media source whose total 
		channel count exceeds 2 are ignored. Although having such 
		takes within item would be counter-productive, unless it's 
		volume is turned off, because some channels are likely to have 
		duplicates among other takes where a single channel is active.

		When a channel is added or removed and there're more than one
		take in the item the script makes sure that 'Play all takes' 
		setting is enabled in the item properties.


		CHANGING CHANNEL IN ACTIVE TAKE

		To change active channel in active takes, setting 3,
		CHANGE_ACTIVE_TAKE_CHANNEL, must be enabled.  
		A channel in an active take is replaced when a menu item 
		corresponding to another channel is clicked and gets 
		checkmarked. The initial channel mode of the active take 
		is immaterial.  
		If take channel mode is a channel pair, L/R downmix, Normal 
		or Reverse stereo (the last two modes only if take media 
		source channel count is 2 and setting 2, 
		RESPECT_2_CHANNEL_ITEMS, is enabled) under which two menu 
		items are checkmarked, a channel can also be changed by 
		clicking one of the checkmarked menu items in which case 
		the channel corresponding TO THE CLICKED menu item 
		IS LEFT ACTIVE BY ITSELF in the take while the second 
		channel is removed (which may seem counter-intuitive 
		because usually one expects the checkmarked item to get 
		unchecked as a result of a click rather than remain 
		checkmarked, but this is meant to be consistent with the 
		operation applicable to changing a single channel).  
		When in different items included in multiple item selection 
		different channel is enabled in the active take, no menu 
		item is checkmarked, so channels can only be changed to 
		a single one even for takes with enabled channel pairs if
		such are included in selection.


		ADDING/REMOVING/REPLACING SECOND CHANNEL IN ACTIVE TAKE

		To add/remove/replace second channel in active takes, 
		setting 4, ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE 
		must be enabled.  
		A second channel is added to a take whose channel mode 
		is set to a single channel. To add a second channel click
		the menu item which immediately precedes or follows the
		checkmarked menu item that corresponds to the currently
		active channel. 	
		A second channel is replaced in a take whose channel mode 
		is set to channel pair (stereo) or L/R downmix. Its 
		channel mode can also be set to Normal or Reverse stereo 
		provided its media source only has two channels and 
		setting 2, RESPECT_2_CHANNEL_ITEMS is enabled. To replace
		one of the two channels click menu item which immediately 
		precedes the checkmarked menu item that sorresponds to the 
		left stereo channel of the active channel pair or follows 
		the checkmarked menu item that corresponds to the right 
		stereo channel of the active channel pair.  
		A second channel is removed in a take whose channel mode 
		is set to a channel pair (stereo) or to L/R downmix. Its
		channel mode can also be set to Normal or Reverse stereo 
		provided its media source only has two channels and 
		setting 2, RESPECT_2_CHANNEL_ITEMS is enabled. To remove 
		one of the two channels click the checkmarked menu item 
		which corresponds to the left or the right channel of the
		currenly active channel pair to uncheckmark it.


		ADDITIONAL ACTIONS

		Toggle mute/solo

		Toggle active audio take mute - a take is considered muted 
		when its volume is at -96 dB or lower, so when the volume is 
		heigher it's set to be much lower, i.e. the take gets muted, 
		and when it's at -96 dB or lower the original volume is 
		resrored if the take was originally muted with the script, 
		otherwise it will be set at 0 dB.

		Toggle active audio take solo - the same logic as above applies 
		to all item takes bar the active one; the active take is soloed,
		regadless of its own volume, when volume of at least one other 
		item take is above -96 dB, i.e. all other takes get muted, 
		otherwise they're unmuted which is tantamount to the active 
		take being unsoloed; if active take was muted manually in which
		case the script has no knowledge of its original volume, its 
		volume is restored to 0 dB; if all item takes are muted, 
		uncluding the active take, the latter is soloed, i.e. unmuted, 
		while all other takes remain muted.

		The mute actions will only work if the channel enabled in the 
		active takes is within the media source channel range.


		Move up/down

		Move active audio take up/down - the movement is finite, i.e.
		when a take reaches the topmost/buttommost take lane, it 
		cannot be moved any further in the same direction, no 
		wrap-around.


		Randomize channel (pair)

		Randomize active audio take channel - the action is only 
		available when setting 3 is enabled. In multi-item selection
		by default channel is randomized for each active take 
		separately. When setting 4 is enabled an indicator (U) is
		tagged on to the action name in the menu denoting uniform
		randomization for all active takes in multi-item selection, 
		i.e. setting all of them to a channel by the same random number.  
		Subject to randomization are only channels of media sources 
		whose channel count is greater than 2.

		Randomize active audio take channel pair - same as above
		except that instead of individual channels channel pairs are 
		randomized and applied. Subject to randomization are only 
		channels of media sources whose channel count is greater 
		than 3.

		Muted active takes, i.e. whose volume is at or below -96 dB, 
		and non-audio takes are ignored.


		Characters in the menu marked with underscore work as quick
		access shorcuts so the menu items can be triggered from 
		keyboard while the menu they belong to is focused.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- To enable the following settings insert
-- any alphanumeric character between the quotes.
-- All the settings bar the last one can be managed
-- dynamically via the menu as well

-- When enabled, the script
-- will NOT ignore locked items;
-- corresponds to setting 1 in the menu
INCLUDE_LOCKED_ITEMS = ""

-- When enabled, the script will respect items/takes
-- whose media source only has two channels (usually stereo)
-- otherwise stereo items/takes are ignored;
-- corresponds to setting 2 in the menu
RESPECT_2_CHANNEL_ITEMS = ""

-- When enabled, allows changing active take channel;
-- corresponds to setting 3 in the menu
CHANGE_ACTIVE_TAKE_CHANNEL = ""

-- When enabled, actions
-- 'Randomize active audio take channel (pair)'
-- accessible from the main menu
-- will activate channel by the same random number
-- in all active takes, otherwise channel
-- is randomized separately for each active take;
-- corresponds to setting 4 in the menu
RANDOMIZE_ACTIVE_TAKE_CHANNEL_UNIFORMLY = ""

-- When enabled, allows adding another, adjacent,
-- channel to the active take channel or removing
-- one from a channel pair enabled in the active take;
-- the setting is ignored if
-- CHANGE_ACTIVE_TAKE_CHANNEL setting above is enabled;
-- corresponds to setting 5 in the menu
ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE = ""

------------------------------------------------------------

-- Enable to allow selection of multiple items
-- with different take count, however the channels
-- displayed as takes in these items will still have to have
-- matches in each other, which means that items with greater
-- take count may have the same channel active in more than
-- one take unless its number is outside of the media source
-- channel range or take channel mode is Normal or Reverse stereo
-- and the media source channel count is greater than 2, in which
-- case the channel will be ignored;
-- the setting is listed in the script SETTINGS menu
-- without being accessible for toggling there;
-- not sure allowing different take counts is
-- a good idea conceptually, but it does work;
-- corresponds to the grayed out setting 6 in the menu
ALLOW_DIFFERENT_TAKE_COUNT = "1"

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
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
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
do return end
end


function check(sett)
return sett and '!' or ''
end


function Settings_State_Readout(...)
-- vararg is a list of setting vars holding true/false values;
-- meant to display in the main menu
-- the state of settings hidden in a submenu
local result
	for k, sett in ipairs({...}) do
		if k ~= 4 then -- 4 is RANDOMIZE_ACTIVE_TAKE_CHANNEL_UNIFORMLY whose state isn't shown in the main menu
		result = (result or '')
		..(sett and string.char(226,157,181+k)..' ' or string.char(226,145,159+k)..' ') -- Dingbat Negative Circled Digit X OR Circled Digit X, starting from 1, 226,157,182 or 226,145,160 respectively
		-- OR
		-- ..(sett and string.char(0xE2,0x9D,B5+k)..' ' or string.char(0xE2,0x91,0x9F+k)..' ')
		end
	end
return result
end



function Toggle_Settings_From_Menu(idx, sett_t, scr_path, exclusive_t)
-- idx is menu output value, i.e. index of the menu item
-- corresponding to the setting being toggled
-- and to the setting index within the table of settings
-- contructed below from the USER SETTINGS section,
-- if in the menu settings don't start at index 1
-- their indices will have to be offset and so idx,
-- because list of settings retrieved from the USER SETTINGS section
-- is indexed from 1;
-- sett_t is table of all settings boolean values in the order
-- they're listed in the USER SETTINGS section;
-- scr_path comes from get_action_context();
-- exclusive_t is and optional argument, a table of toggle settings
-- which are mutually exclusive, where keys are indices of the settings
-- in the menu offset so that the 1st setting has index 1 to match
-- USER SETTING section sequence, and where values are their boolean values;
-- the function is not designed to work
-- with menu loaded from extended state

-- load the settings
local settings, found = {}
	for line in io.lines(scr_path) do
		if #settings == 0 and line:match('----- USER SETTINGS ------') then
		found = 1
		elseif found and line:match('^%s*[%u%w_]+%s*=%s*".-"') then -- ensuring that it's the setting line and not reference to it elsewhere
		settings[#settings+1] = line
		elseif line:match('END OF USER SETTINGS') then
		break
		end
	end


local sett_new_state = sett_t[idx] and '' or '1' -- toggle
local sett_name = settings[idx]:match('^(%s*[%u%w_]+%s*=)')

-- handle mutually exclusive settings
local exclusive_toggle = exclusive_t and exclusive_t[idx] ~= nil and sett_new_state == '1' -- exclusive_t[idx] may be true or false
	if exclusive_toggle then
		for k in pairs(exclusive_t) do
			if k ~= idx and exclusive_t[k] then -- only if mutually exclusive setting is true to avoid unnecessary writing to this file
			exclusive_t[k] = ''
			end
		end
	end


-- update
local f = io.open(scr_path,'r')
local cont = f:read('*a')
f:close()
local sett_upd = sett_name..' "'..sett_new_state..'"'
local cont, cnt = cont:gsub(settings[idx], sett_upd, 1)

	-- update mutually exclusive setting state
	if exclusive_toggle then
		for k, state in pairs(exclusive_t) do
			if k ~= idx and state == '' then
			local sett_name = settings[k]:match('^(%s*[%u%w_]+%s*=)')
			local sett_upd = sett_name..' ""'
			cont, cnt = cont:gsub(settings[k], sett_upd, 1)
			end
		end
	end

	if cnt > 0 then -- settings were updated, write to file
	local f = io.open(scr_path,'w')
	f:write(cont)
	f:close()
	end

return sett_new_state == '1'

end


function pause(duration)
-- duration is time in seconds
-- during which the script execution
-- will pause
local t = r.time_precise()
	repeat
	until r.time_precise()-t >= duration
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



function Re_Store_Selected_Items(t, keep_last_selected)
-- keep_last_selected is boolean relevant for the restoration stage
-- to add last selected items to the original selection
-- at the restoration stage when evaluating whether any items
-- were saved into the table, 'if next(t) then' statement is used
-- because the table isn't indexed and 'if #t > 0 then' won't work

	if not t then
	local t = {}
		for i=0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
			if r.IsMediaItemSelected(item) then
			t[item] = '' -- dummy entry
			end
		end
--	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	return t
	elseif t and next(t) then
	--	if not keep_last_selected then
	--	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	--	end
		for item in pairs(t) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	end

r.UpdateArrange()

end



function is_audio_src(src) -- used inside Get_Items()
	if src then
	local typ = r.GetMediaSourceType(src, '')
		for k, v in ipairs({'MIDI', 'RPP', 'EMPTY', 'CLICK', 'LTC', 'VIDEO'}) do
			if typ:match(v) then
				if v == 'VIDEO' then -- as of build 7.52 wma and m4a files are recognized as video even though they only contain audio, so need to be validated further
				local ext = r.GetMediaSourceFileName(src, ''):match('.+%.(.+)$')
					if ext == 'wma' and ext == 'm4a' then
					return true
					end
				end
			return
			end
		end
	return true
	end
end


function get_take_src_channel_count(take)
	if not take then return end
local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
src = r.GetMediaSourceParent(src) or src
return r.GetMediaSourceNumChannels(src)
end


function get_valid_take(item) -- used in Get_Items() and get_lower_indexed_channel_take()
-- invalid is the take whose channel mode is normal or reverse stereo

	for i=0, r.CountTakes(item)-1 do
	local take = r.GetTake(item, i)
		if take then -- empty take doesn't have a pointer
		local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
		local src = r.GetMediaSourceParent(src) or src
			if is_audio_src(src) then
			return take
			end
		end
	end

end


function Get_Items(want_locked, want_2_ch, want_act_take, item_under_mouse)
-- want_locked and want_2_ch and are booleans, i.e.
-- INCLUDE_LOCKED_ITEMS and RESPECT_2_CHANNEL_ITEMS settings,
-- want_act_take is either boolean or integer 5, i.e.
-- CHANGE_ACTIVE_TAKE_CHANNEL or ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE settings (want_act_take==5),
-- 1st valid take of the 1st valid item is used
-- as a reference against which media sources
-- of all following takes and items are evaluated,
-- details on the evaluation priority see in the comment below;
-- item_under_mouse is pointer of the originally detected
-- item under mouse fed back into the function in the
-- RELOAD loop to keep the item focus regardless of content
-- under mouse which may change

local x, y = r.GetMousePosition()
local item = item_under_mouse
	if not item and not RELOAD then -- global RELOAD is set to true in the main routine just before 'goto RELOAD', this blocks detection of new items under mouse after menu reload to ensure that the originally detected item is still the focus
	item = r.GetItemFromPoint(x, y, false) -- allow_locked false
	end

	if not item and not r.GetSelectedMediaItem(0,0) then return end -- no item under mouse or selected

local count = item and 0 or r.CountMediaItems(0)-1 -- if item under mouse the loop runs only once and only item under mouse gets collected into the table

-- Identify reference item, against which all other items will be evaluated
-- i.e. the 1st item whose properties conform to script requirements (listed in the 'About' text)
-- AND which is the most diverse in terms of take active channels because this prevents false
-- positives inside Construct_Channel_Menu() function in scenarios where A) the same channel
-- is enabled in several takes or B) item take counts differ, i.e. A) when reference
-- item has channels 1,1,2 enabled while another item has channels 1,2,3 the other item will
-- not be excluded from selection because all reference item channels will be found
-- in the other item, same outcome results when B) reference item has 1,2 enabled while
-- another item has 1,2,3, all this is the consequence of allowing same channels be active
-- in different items in takes at different indices and allowing different take counts;
-- ref_take is a reference take against which all other takes in the 1st compatible
-- item will be evaluated, for item under mouse it's still the active take,
-- when want_act_take arg is true it's active take, in all other cases
-- it's the 1st valid (i.e. audio( take returned by get_valid_take(),
-- when reference take is active take, other takes of the same item are ignored
-- and only active takes in other items will be evaluated against it,
-- in this scenario active takes are allowed to have different media sources
-- but channel count must match reference take media source channel count
-- and active channel must be the same if ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE
-- setting is enabled, if CHANGE_ACTIVE_TAKE_CHANNEL is enabled instead
-- active channels may differ

local t = {}
local add_remove_ch = want_act_take == 5
local ref_take, ref_ch -- relevant to want_act_take mode
local unique_ch_cnt = 0

	for i=0, count do
	local ch_t = {}
	local item = item or r.GetMediaItem(0, i)
	local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK') &1 == 1
		if (not locked or want_locked) and (take or r.IsMediaItemSelected(item)) then -- only evaluate selected status if no item under mouse
		local act_take = r.GetActiveTake(item)
		ref_take = want_act_take and act_take and not r.TakeIsMIDI(act_take) and act_take
		or not want_act_take and get_valid_take(item) -- take under cursor, active take in single or multi item selection or item selection without focus on the active take

			if ref_take then
			local src = r.GetMediaItemTake_Source(ref_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
			local ch_cnt, src_file
				if is_audio_src(src) then
				ch_cnt = r.GetMediaSourceNumChannels(src)
				src_file = r.GetMediaSourceFileName(src, '')
				end

				if ch_cnt and (ch_cnt > 2 or ch_cnt == 2 and want_2_ch) then -- audio media source with channel count above 2 or 2 when RESPECT_2_CHANNEL_ITEMS setting is enabled
				ref_ch = r.GetMediaItemTakeInfo_Value(ref_take, 'I_CHANMODE')
				local ch = convert_ch_idx_2_ch_No(ref_ch)

					if want_act_take then -- either CHANGE_ACTIVE_TAKE_CHANNEL or ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE settings

						if add_remove_ch then -- ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting
							if ch_cnt > 2 and ref_ch < 2 then -- in normal (0) and reverse stereo (1) channel modes all channels are displayed, so if there're more than 2, the channel (main) menu won't make sense when ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting is enabled, because the menu for this setting must only include a maximum of 2 active channels and channel immediately preceding and following it/them, whereas when all are displayed it won't be possible to construct a menu which only allows adding/removing channels to/from a channel pair because all channels will have to be checkmarked and unchecking one of them won't result in its removal from the displayed array of channels as something technically impossible, likewise there's no criteria to decide whether the menu should focus on a single channel or a channel pair out of over 2 and only checkmark them, and which channel or a channel pair in particular
							ref_take = nil -- reset to prevent storage of this item after take loop
							else
							local a, b = table.unpack(tonumber(ch) and (ch+0 > 0 and {ch} or {1,2}) or {ch:match('(%d+)/(%d+)')}) -- if not channel pair, assign single channel index // ch value returned by convert_ch_idx_2_ch_No() is < 1 (i.e. -2, -1, 0) denotes normal, reverse stereo and L/R downmix channel modes and since in these modes only 2 channel media sources are supported as per the above condition when add_remove_ch var is true, only two channels are returned, i.e. {1,2}
								if a+0 > ch_cnt or b and b+0 - ch_cnt > 2 then -- if a single active channel index exceeds channel count, i.e. out of range of channels in the media source, or the right channel of a channel pairs exceeds it by 2 meaning the left channel is also out of range (which is possible, in which case an empty channel is displayed within take), disqualify the take
								ref_take = nil -- reset to prevent storage of this item after take loop
								end
							end
						end

					else -- mode NOT targetting the active take

					-- store ref_take channels, i.e. item's 1st valid take
					local a, b = table.unpack(tonumber(ch) and (ch+0 > 0 and {ch} or (ch == 0 or ch_cnt == 2) and {1,2})
					or not tonumber(ch) and {ch:match('(%d+)/(%d+)')} or {}) -- at this stage 'ch_cnt == 2' will be true only if want_2_ch is true as per condition before this block // ignoring normal (-2) and reverse stereo (-1) channel modes if media source channel count is above 2, because not being reflected in the main channel menu these are irrelevant in determining channel variety within item

						if a and a+0 <= ch_cnt or b and b+0 <= ch_cnt then	-- store channels if within media source channel range
						ch_t[a+0], ch_t.n = a+0, 1
							if b then ch_t[b+0], ch_t.n = b+0, ch_t.n+1 end
						end

						-- continue by storing unique channels from other takes in the same item
						for i=0, r.CountTakes(item)-1 do
						local take = r.GetTake(item, i)
							if take and not r.TakeIsMIDI(take) and take ~= ref_take then
							local take_src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
							take_src = r.GetMediaSourceParent(take_src) or take_src
							local take_src_ch_cnt = r.GetMediaSourceNumChannels(take_src)
							local take_src_file = r.GetMediaSourceFileName(take_src, '')
								if is_audio_src(take_src) and take_src_file ~= src_file then
								ref_take = nil -- reset to prevent storage of this item after take loop
								break
								end

							local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
							ch = convert_ch_idx_2_ch_No(ch)
							local a, b = table.unpack(tonumber(ch) and (ch+0 > 0 and {ch} or (ch == 0 or ch_cnt == 2) and {1,2})
							or not tonumber(ch) and {ch:match('(%d+)/(%d+)')} or {})
							-- store channels if absent in the table and increment counter
								if a and a+0 <= ch_cnt and not ch_t[a+0] then
								ch_t[a+0], ch_t.n = a+0, ch_t.n and ch_t.n+1 or 1
								end
								if b and b+0 <= ch_cnt and not ch_t[b+0] then
								ch_t[b+0], ch_t.n = b+0, ch_t.n+1
								end

							end

						end -- take loop end

					end -- want_act_take block closure

				else  -- 'if ch_cnt' statement alternative
				ref_take = nil -- this applies to want_act_take mode as an alternative to 'if is_audio_src(src)' statement result, resetting it immediately after the stament above would make it invalid for take loop after else in 'if ch_cnt' block and likely screw reference item evaluation which was already fine tuned
				end -- 'if ch_cnt' block closure

				if ref_take and (want_act_take or ch_t.n and unique_ch_cnt < ch_t.n) then -- only update when want_act_take mode or when current item's channel variety is greater than that of a previous item or if it's the first ever item
				unique_ch_cnt = ch_t.n -- only relevant when want_act_take mode is false
				t[1] = item
				t.ref_take = ref_take -- store for Construct_Channel_Menu() to be able to get accurate reference channel count
				t[item] = '' -- store also pointer as key to be able to quickly find an item in a loop which deselects unsupported item in mutli-item selection following this function in the main routine
					if want_act_take then break end -- otherwise don't exit to be able to evaluate channel variety in all items
				end

			end
		end
	end -- item loop end


	if item or #t == 0 and not ref_take then return t, item -- exit if no compatible item or it's item under mouse in which case there's nothing to further evaluate, item return value prevents deselection loop following the function in the main routine, using item instead of take because if take is empty its pointer is nil
	elseif #t == 0 and ref_take then -- will be true if selected item(s) only contain(s) takes with channel mode normal or reverse stereo while the media source channel count is over 2 OR with active channel index being outside of the source media channel count range because all these are ignored in the loop above as irrelevant for the main channel menu which is why they're not explicitly disqualified by resetting ref_take variable
	-- store reference take properties to proceed with the evaluation below because these weren't stored in the loop above
	local item = r.GetMediaItemTake_Item(ref_take)
	t[1], t[item] = item, ''
	t.ref_take = ref_take
	end

-- collect other selected items which conform to the properties of the reference item
local ref_item = t[1]
t[ref_item] = '' -- store also pointer as key to be able to quickly find the item in a loop which deselects unsupported item in mutli-item selection following this function in the main routine
local ref_take_cnt = r.CountTakes(ref_item)
local ref_ch_cnt = get_take_src_channel_count(t.ref_take)

	for i=0, count do
	local item = r.GetMediaItem(0, i)
	local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK') &1 == 1
		if not locked or want_locked then
		local itm_take_cnt = r.CountTakes(item)
			if item ~= ref_item and r.IsMediaItemSelected(item)
			and (locked and want_locked or not locked)
			and (want_act_take or ALLOW_DIFFERENT_TAKE_COUNT or itm_take_cnt == ref_take_cnt) -- take count must be the same across all selected items unless want_act_take is false because in this case e the active take is the only focus OR ALLOW_DIFFERENT_TAKE_COUNT setting is enabled // if ALLOW_DIFFERENT_TAKE_COUNT is enabled items will be further filtered inside Construct_Channel_Menu() via take menu and only items where enabled channels don't match those enabled in the reference item (the 1st in the table) will be disqualified, this allows having items with different take count as long as active channels are the same, which implies that same channel may be active in more than one take, mainly in items with greater take count
			then
				if want_act_take then -- only evaluate current item active take
				local cur_act_take = r.GetActiveTake(item)
						if not cur_act_take or r.TakeIsMIDI(cur_act_take) then item = nil break end
				local src = r.GetMediaItemTake_Source(cur_act_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
				src = r.GetMediaSourceParent(src) or src
					if is_audio_src(src) then
					local cur_ch_cnt = r.GetMediaSourceNumChannels(src)
					local cur_ch = r.GetMediaItemTakeInfo_Value(cur_act_take, 'I_CHANMODE')
						if cur_ch_cnt < ref_ch_cnt or add_remove_ch and cur_ch ~= ref_ch
						then
						item = nil break end -- reset to prevent item storage below
					else
					item = nil break -- reset to prevent item storage below
					end
				else
				local ref_src_file
					for i=0, itm_take_cnt-1 do
					local take = r.GetTake(item,i)
					--	if not take then item = nil break end -- empty take which doesn't have a pointer, reset to prevent item storage below
						if take and not r.TakeIsMIDI(take) then -- take will be nil if take is empty
						local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
						src = src and r.GetMediaSourceParent(src) or src
						local src_file = r.GetMediaSourceFileName(src, '')
							if is_audio_src(src) then
								if ref_src_file and src_file ~= ref_src_file then item = nil break end -- audio take within the same item with different media source, reset to prevent item storage below
							local cur_ch_cnt = r.GetMediaSourceNumChannels(src)
								if cur_ch_cnt ~= ref_ch_cnt then item = nil break end -- reset to prevent item storage below
							ref_src_file = ref_src_file or src_file -- assign when nil and maintain for subsequent cycles
							end
						end
					end
				end
				if item then
				t[#t+1] = item
				t[item] = '' -- store also pointer as key to be able to quickly find an item in a loop which deselects unsupported item in mutli-item selection following this function in the main routine
				end
			end
		end
	end

return t

end


function convert_ch_idx_2_ch_No(ch_idx) -- used in Construct_Channel_Menu(), Remove_Channel(), get_lower_indexed_channel_take(), Add_Remove_Replace_2nd_Channel_In_Active_Take()
local floor = math.floor
local ch_No = (ch_idx < 67 and ch_idx or (ch_idx > 130 and ch_idx < 195) and ch_idx-128) -- mono
local stereo = not ch_No
ch_No = ch_No or (ch_idx > 66 and ch_idx < 131 and ch_idx-64 or ch_idx > 194 and ch_idx-128) -- stereo // ch_idx > 66 isn't really necessary here due to preceding ch_No, but is useful when evaluating raw ch_idx value
ch_No = ch_No and ch_No-2 -- -2 because channel indexing starts from value 3, preceded by 0 - normal (i.e. stereo), 1 - reverse stereo and 2 - downmix, i.e. 2 meaningful values (excluding 0)
return ch_No and (stereo and floor(ch_No)..'/'..floor(ch_No+1) or floor(ch_No)) -- math.floor to strip trailing decimal 0 // for modes normal, reverse stereo and L/R downmix the return value is -2, -1 and 0 respectively
end


function convert_ch_No_2_ch_idx(ch_No) -- used in Remove_Channel(), Add_Channel(), Change_Act_Take_Channel(), Add_Remove_Replace_2nd_Channel_In_Active_Take()
-- ch_No can be integer or string for mono channels
-- and must be a string for stereo channels in the format '1/2'
-- mono and stereo channel ranges are 1-128 each;
-- ch_No values -2, -1 and 0 denote normal, reverse stereo and L/R dowmix
-- channel modes respectively
local ch_No = tonumber(ch_No) or ch_No:match('(%d+)/')
local stereo
	if not ch_No or ch_No+0 < -2 and ch_No+0 > 128 then return
	else
	stereo = type(ch_No) == 'string'
	ch_No = tonumber(ch_No)
	end
local ch_idx = not stereo and ch_No < 65 and ch_No or ch_No > 64 and ch_No+64 -- mono
ch_idx = ch_idx or ch_No < 65 and ch_No+64 or ch_No > 64 and ch_No+128 -- stereo
return ch_idx+2 -- +2 because channel indexing starts from value 3, preceded by 0 - normal (i.e. stereo), 1 - reverse stereo and 2 - downmix, i.e. 2 meaningful values (excluding 0)
end



function evaluate_take_active_channels(a, b) -- used inside Construct_Channel_Menu()
-- a is reference item take menu item readout
-- b is the evaluated item take menu readout
-- patt1 permits active channel equality between takes at different indices
-- patt2 permits active channel equality between single channels
-- individual channels in channel pairs, including L/R downmix,
-- and normal and reverse stereo modes when channel count is 2
-- because take menu item in this case looks like 1/2 (full)
local patt1, patt2 = ': (%d+)', ': %d+/(%d+)'
return a:match(patt1) == b:match(patt1)
or b:match('/') and (b:match(patt2) == a:match(patt1) or b:match(patt2) == a:match(patt2)) -- only 'b' uses patt2 because 'a' is split into individual channel indices when it comes as a channel pair
end


function same_active_channel(itm_t) -- used inside Construct_Channel_Menu()
-- itm_t comes from Get_Items()
local ref_ch
	for k, item in ipairs(itm_t) do
	local take = r.GetActiveTake(item)
		if take then -- active empty take won't return a pointer
		local ch = r.GetMediaItemTakeInfo_Value(r.GetActiveTake(item), 'I_CHANMODE')
			if ref_ch and ref_ch ~= ch then return
			else
			ref_ch = ch
			end
		end
	end
return true
end


function Construct_Channel_Menu(itm_t, act_take_sett)
-- itm_t comes from Get_Items()
-- act_take_sett is integer:
-- CHANGE_ACTIVE_TAKE_CHANNEL is 3, ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE is 5

local ref_item = itm_t[1]

	if not ref_item then return end

local take = act_take_sett and r.GetActiveTake(ref_item) or itm_t.ref_take -- get the active take of the 1st valid item if CHANGE_ACTIVE_TAKE_CHANNEL or ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE settings are enabled, or the valid take of the reference item, this is enough because the script doesn't support takes with different media sources within the same item and media sources with different channel count in multiple selected items, these scenarios are identfied inside Get_Items()

local ch_cnt = get_take_src_channel_count(take)
local sel_cnt = r.CountSelectedMediaItems(0) -- store value because it may change below due to exclusion of incompatible items

local ch_menu = {} -- main channel menu
	for i=1,ch_cnt do
	ch_menu[#ch_menu+1] = i -- (#ch_menu > 0 and '|' or '')..i
	end

-- construct take menu,
-- will only be displayed for a single selected item,
-- or if in multiple selected items same channels are active
-- in the takes at the same index and take count is identical,
-- discrepancies in take count are prevented inside Get_Items()
-- unless ALLOW_DIFFERENT_TAKE_COUNT setting is enabled,
-- while discrepancies in take indices vs active channel are evaluated
-- here as well as in take count if ALLOW_DIFFERENT_TAKE_COUNT setting
-- is enabled;
-- take menu won't be displayed when the script targets active takes,
-- i.e. when CHANGE_ACTIVE_TAKE_CHANNEL or ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE
-- settings are enabled
local take_menu = {} -- take channel list in a submenu

	if act_take_sett then -- active takes are the target
	-- checkmark channel (main) menu items corresponding to active channel(s) in active take
	-- unless channels enabled in active takes differ,
	-- in normal and reverse stereo channel modes where all media source channels are didplayed
	-- no menu item is checkmarked for CHANGE_ACTIVE_TAKE_CHANNEL (3) setting
	local add_remove = act_take_sett == 5
	local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
		if ch > 1 or add_remove and ch_cnt == 2 then -- ignoring normal (0) or reverse stereo (1) modes unless ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting is enabled and the media source only has 2 channels; inside Get_Items() when ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting is enabled, active take with these channel modes is disqualified for media sources whose channel count exceeds 2
		ch = convert_ch_idx_2_ch_No(ch) -- return value for normal and reverse stereo channel modes (all channels are visible) are -2 and -1, for L/R downmix (only 1/2 are visible) the return value is 0; normal and reverse stereo channel modes are only supported for 2 channel media source, rationale see in a comment inside Get_Items()
		local a, b = table.unpack(tonumber(ch) and (ch+0 > 0 and {ch} or {1,2}) or {ch:match('(%d+)/(%d+)')}) -- if not channel pair, assign single channel index // ch value returned by convert_ch_idx_2_ch_No() is < 1 (i.e. -2, -1, 0) denotes normal, reverse stereo and L/R downmix channel modes and since in these mode only 2 channel media sources are supported when add_remove var is true, only two channels are returned, i.e. {1,2}; normal and reverse stereo channel modes are excluded from this block when media source channel count exceeds 2

		local st, fin = table.unpack(not add_remove and (a+0 ~= 0 and {1,#ch_menu} or a+0 == 0 and {1,2})
		or not b and {a+0 <= 1 and 1 or a-1, a+0 == #ch_menu and #ch_menu or a+1}
		or {a+0 <= 1 and 1 or a-1, b+0 >= #ch_menu and #ch_menu or b+1})

			if same_active_channel(itm_t) then -- only checkmark if in all active takes the same channel is active
				for i=st,fin do
				local v = ch_menu[i]
				ch_menu[i] = ((v+0 == a+0 or b and v+0 == b+0) and '!' or '')..v -- checkmark menu items corresponding to active channels
				end
			end
			if add_remove then -- only leave adjacent channels, preceding and following the active channel(s), if any
				for i=#ch_menu,1,-1 do
					if i > fin or i < st then
					table.remove(ch_menu,i)
					end
				end
			end
		end

	else -- targetting all takes, active take settings are disabled

	-- Checkmark channel menu items and create take menu, all based on the 1st valid item which is the 1st in the table
	local ref_take_cnt = r.CountTakes(ref_item)
		for i=0, ref_take_cnt-1 do
		local take = r.GetTake(ref_item, i)
		local src = take and r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
		src = src and r.GetMediaSourceParent(src) or src
			if not take then -- empty take doesn't have a pointer
			take_menu[#take_menu+1] = '|#Take '..(i+1)..': (empty take)' -- gray out because empty take cannot be selected programmaticaly by clicking the menu item due to lacking pointer, and even though it can by action as long as its 0-based index doesn't exceed 8, there's no point in allowing to select it for the purposes this script is designed for
			elseif r.TakeIsMIDI(take) or not is_audio_src(src) then
			take_menu[#take_menu+1] = '|#Take '..(i+1)..': (MIDI or video processor take)' -- gray out because there's no point in allowing to select it for the purposes this script is designed for
			else
			local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
			ch = convert_ch_idx_2_ch_No(ch)
			local a, b = table.unpack(tonumber(ch) and {ch} or {ch:match('(%d+)/(%d+)')}) -- if not channel pair, assign single channel index
			-- checkmark channel (main) menu items corresponding to active channel(s) in each take
			local st, fin = table.unpack(a+0 < 0 and {1, #ch_menu} or a+0 == 0 and {1,2} or not b and {a,a} or {a+0,b+0}) -- normal, reverse stereo, L/R downmix, channel pair or single, < 0 because for normal and reverse stereo modes the function convert_ch_idx_2_ch_No() returns negative integers, -2 and -1 respectively, and 0 for L/R downmix
				for i=st,fin do
				local v = ch_menu[i]
					if tonumber(v) then -- not yet converted to string by checkmarking with !
					ch_menu[i] = ( (a+0 > -1 or ch_cnt == 2) and '!' or '')..v -- only checkmark channels when the channel display mode is not normal or reverse stereo unless there're only two channels, because having all checkmarked under those two modes creates confusion as to what should be done when one of the channel menu items is unchecked since obviously more than two channels cannot be enabled and displayed at once, which isn't a problem when there're 2 channels in total in the media source because when one is unchecked we're only left with a single channel which can be displayed
					end
				end
			-- for modes normal, reverse stereo and L/R downmix, convert_ch_idx_2_ch_No() return value is -2, -1 and 0 respectively
			local out_of_range = (b and b+0 > ch_cnt or a+0 > ch_cnt) and '(out of range)'
			ch = ch == -2 and '1'..(ch_cnt > 2 and ' – ' or '/')..ch_cnt..' (full)'
			or ch == -1 and '1'..(ch_cnt > 2 and ' – ' or '/')..ch_cnt..' (reversed 1/2)'
			or ch == 0 and '1/2 downmix' or ch
			ch = '|'..(ref_take_cnt > 1 and r.GetActiveTake(ref_item) == take and '!' or '')..'Take '..(i+1)..': '..(out_of_range or ch) -- checkmarking active take for multi-take items
			take_menu[#take_menu+1] = ch
			end
		end

	-- Evaluate other items against the reference one via values of take_menu table constructed above
	-- using their own provisional take_menu values;
	-- take index and take count mismatch is evaluated at two levels:
	-- item selection level and item level which allows resetting the variables
	-- at item level if item turns out to be non-compliant and has to be disqualified
	-- so that at item selection level only values obtained from valid items are stored
	local take_idx_mismatch, take_cnt_mismatch -- item selection level variables
	local ref_itm_act_take_idx = r.GetMediaItemInfo_Value(ref_item, 'I_CURTAKE')
		for k, item in ipairs(itm_t) do
			if k > 1 then -- excluding reference item itself which is the 1st in the table
			local take_cnt, idx_mismatch = r.CountTakes(item) -- item level variables

				for idx, channel in ipairs(take_menu) do
					if not channel:match('%(out of range%)')
					and (ch_cnt == 2 or not channel:match('full') and not channel:match('reversed'))
					and not channel:match('empty take') and not channel:match('MIDI') -- ignoring out of range channels, as well as normal and reverse stereo channel modes (marked as 'full' and 'reversed' in the take menu), unless media source channel count is 2, because none of those types is supposed to affect channel evaluation as not being reflected in the main channel menu, and empty and MIDI takes
					then
					-- since each channel of a channel pair must be evaluated, create subloop for a channel pair
					-- where each individual channel of a pair is evaluated against channel values of another item
					local ch_pair_t = channel:match('/') and {': '..channel:match('(%d+)/'), ': '..channel:match('/(%d+)')} or {channel}

						for _, channel in ipairs(ch_pair_t) do
						local ch_match
							for i=0, take_cnt-1 do
							local ch, out_of_range
							local take = r.GetTake(item,i)
							local src = take and r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
							src = src and r.GetMediaSourceParent(src) or src
								if take and is_audio_src(src) then
								ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
								ch = convert_ch_idx_2_ch_No(ch) -- for modes normal, reverse stereo and L/R downmix return value is -2, -1 and 0 respectively
								local a, b = table.unpack(tonumber(ch) and {ch} or {ch:match('(%d+)/(%d+)')}) -- if not channel pair, assign single channel index
								out_of_range = (b and b+0 > ch_cnt or a+0 > ch_cnt) and '(out of range)'
								ch = ch == -2 and '1'..(ch_cnt > 2 and ' – ' or '/')..ch_cnt..' (full)'
								or ch == -1 and '1'..(ch_cnt > 2 and ' – ' or '/')..ch_cnt..' (reversed 1/2)'
								or ch == 0 and '1/2 downmix' or ch
								ch = '|'..(take_cnt > 1 and r.GetActiveTake(item) == take and '!' or '')..'Take '..(i+1)..': '..(out_of_range or ch)
								end

								if not out_of_range and ch and not ch:match('%–') then -- since out of range channels, take with normal and reverse stereo channel modes (when media source channel count is above 2 which is reflected in the take menu readout as 1 - X), empty MIDI and video proc. takes are ignored, they're not supposed to affect evaluation because reference item's own out of range channels and normal and reverse stereo modes under the same conditions are filtered out before this take loop
								ch_match = evaluate_take_active_channels(channel, ch)
								idx_mismatch = idx_mismatch or ch_match and idx ~= i+1 -- i+1 because take indices are 0-based while indexing in take_menu table is 1-based
									if ch_match then break end -- one match is enough
								end

							end -- take loop end

							if not ch_match then -- reference item channel has no matches in the evaluated item, disqualify by excluding item from selection
							r.SetMediaItemSelected(item, false) -- deselect item
							r.UpdateItemInProject(item) -- refresh UI so deselection is immediately apparent
							idx_mismatch = nil -- reset to prevent storing truth at item selection level in case it's true, because affecting take menu state by properties of a disqualified item doesn't make sense
							break -- out of take_menu loop because continuation is pointless
							end

						end -- channel pair subloop end

					end -- channel type evaluation condition closure

				end -- take_menu loop end

				if r.IsMediaItemSelected(item) then -- item hasn't been disqualified above
					if r.GetMediaItemInfo_Value(item, 'I_CURTAKE') ~= ref_itm_act_take_idx then -- active status of takes at the same index in the reference item and in the evaluated one differ, clear the active status checkmark
					take_menu[ref_itm_act_take_idx+1] = take_menu[ref_itm_act_take_idx+1]:gsub('!','',1) -- i+1 because take indices are 0-based while indexing in take_menu table is 1-based
					end
				-- update item selection level variables
				take_cnt_mismatch = take_cnt_mismatch or ref_take_cnt ~= take_cnt
				take_idx_mismatch = take_idx_mismatch or idx_mismatch
				end

			end -- k > 1 condition closure
		end -- item loop end

		-- Reset take menu if there're discrepancies between the reference item and the rest in channel assignment or take count
		if take_idx_mismatch or take_cnt_mismatch then -- take_idx_mismatch is possible when the same channel of a media source is enabled in takes at different indices, take_cnt_mismatch is possible if ALLOW_DIFFERENT_TAKE_COUNT setting is enabled and items take counts do differ
		take_menu = {}
		end

	end


local cur_sel_cnt = r.CountSelectedMediaItems(0)
	if cur_sel_cnt ~= sel_cnt then -- some items were deselected in itm_t loop above the because the channel assignment within their takes didn't conform to that in takes of the reference item
	itm_t = {} -- re-collect remaining selected items
		for i=0, cur_sel_cnt-1 do
		itm_t[#itm_t+1] = r.GetSelectedMediaItem(0,i)
		end
	end


return ch_menu, take_menu, itm_t

end



function Activate_Take(itm_t, idx)
-- itm_t comes from Get_Items()
-- idx arg comes from the menu output
	for k, item in ipairs(itm_t) do
	r.SetActiveTake(r.GetTake(item, idx))
	r.UpdateItemInProject(item) -- redraw UI, might be redundant
	end
end



function Toggle_Mute_Solo_Act_Take(itm_t, toggle_mute)
-- itm_t comes from Get_Items()
-- toggle_mute is boolean, depends on the menu output index

local _96dB, inf = 1.5848931924611e-005, 1e-050 -- inf is lowest possible value set by Item Properties volume slider, opted for it instead of 0, because it preserves polarity sign required for original volume restoration, 0 cannot have sign so polarity wouldn't be preserved

local proceed, single_take, no_valid_takes
local t = {}
	if toggle_mute then
		for k, item in ipairs(itm_t) do
		local act_take = r.GetActiveTake(item)
			if act_take and not r.TakeIsMIDI(act_take) then -- active take pointer may be nil if it's an empty take
			local src = r.GetMediaItemTake_Source(act_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
				if is_audio_src(src) then
				local ch_cnt = get_take_src_channel_count(act_take)
				local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
				ch = convert_ch_idx_2_ch_No(ch)
				local a, b = table.unpack(tonumber(ch) and {ch < 0 and ch_cnt or ch == 0 and 2 or ch}
				or {ch:match('(%d+)/(%d+)')})
					if b and b+0 <= ch_cnt or a+0 <= ch_cnt then -- only allow if in the active take active channel number is within media source channel count range
					t[item] = act_take
					proceed = 1
					end
				end
			end
		end
	else -- solo
		for k, item in ipairs(itm_t) do
		local act_take = r.GetActiveTake(item)
			if r.CountTakes(item) == 1 then
			single_take=1
			elseif act_take and not r.TakeIsMIDI(act_take) then -- active take pointer may be nil if it's an empty take
			local src = r.GetMediaItemTake_Source(act_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
				if is_audio_src(src) then
				local ch_cnt = get_take_src_channel_count(act_take)
				local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
				ch = convert_ch_idx_2_ch_No(ch)
				local a, b = table.unpack(tonumber(ch) and {ch < 0 and ch_cnt or ch == 0 and 2 or ch}
				or {ch:match('(%d+)/(%d+)')})
					if b and b+0 <= ch_cnt or a+0 <= ch_cnt then -- only allow if in the active take active channel number is within media source channel count range
					t[item] = {act_take=act_take}
					-- collect other takes to mute
						for i=0, r.CountTakes(item)-1 do
						local take = r.GetTake(item, i)
							if take and take ~= act_take then -- take pointer may be nil if it's an empty take, although these must disqualify an item from selection or from being a target under mouse Get_Items()
							table.insert(t[item], take)
							t[item].solo = t[item].solo or math.abs(r.GetMediaItemTakeInfo_Value(take, 'D_VOL')) > _96dB -- active take will be soloed (rather than unsoloed) if volume of at least 1 take is above -96 dB // math.abs negates the polarity flip which makes vol value negative
							proceed = 1
							end
						end
						if not proceed then
						no_valid_takes=1
						end
					end
				end
			end
		end
	end


local err = not proceed and (single_take and 'can\'t solo single take'
or no_valid_takes and 'no valid other takes to mute' or ' no valid active take')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

	local function unmute(take, _96dB)
	local vol = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
		if math.abs(vol) <= _96dB then -- muted // math.abs negates the polarity flip which makes vol value negative
		local polarity = vol < 0 and -1 or 1 -- get current polarity in case changed in the interim
		local ret, stored_vol = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:VOL', '', false) -- setNewValue false
		vol = math.abs(ret and stored_vol+0 or 1)*polarity -- if no stored value use 1
		r.SetMediaItemTakeInfo_Value(take, 'D_VOL', vol)
		r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:VOL', '', true) -- setNewValue true //clear extended state
		return true
		end
	end

	local function toggle_solo_act_take(take, solo, _96dB, inf) -- by (un)muting the rest
		if solo then -- mute the rest
		local vol = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
			if math.abs(vol) > _96dB then -- mute // math.abs negates the polarity flip which makes vol value negative
			local polarity = vol < 0 and -1 or 1 -- get current polarity
			r.SetMediaItemTakeInfo_Value(take, 'D_VOL', inf*polarity) -- maintainting original polarity
			r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:VOL', vol, true) -- setNewValue true //clear extended state
			end
		else
		unmute(take, _96dB)
		end
	end

r.Undo_BeginBlock()

	for item, take in pairs(t) do -- take is either pointer (toggle mute mode) or table of take pointers (toggle solo mode)
	-- take with volume at -96 dB or lower is considered muted
		if toggle_mute then
		local vol = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
		local ret, stored_vol = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:VOL', '', false) -- setNewValue false
		local val = math.abs(vol) <= _96dB and (ret and stored_vol+0 or 1) or inf -- toggle value, if no stored value (like in a case when initial take volume is already <= -96 dB) use 1, i.e. 0 dB // comparing vol with -96 dB value ignoring polarity which if reversed makes the vol value negative
		local polarity = vol < 0 and -1 or 1 -- get current polarity before muting, and in case changed in the interim before unmuting
		val = vol ~= 0 and math.abs(val)*polarity or val -- set polarity according to current vol sign so after restoration it's preserved; if vol is 0 i.e. -Inf set programmatically, polarity cannot be determined (if -Inf was set manually with a Item Properties volume slider vol value is not 0 and polarity sign is preserved), in which case retain stored value sign
		r.SetMediaItemTakeInfo_Value(take, 'D_VOL', val)
		vol = val <= _96dB and vol or '' -- if val is less than or equal _96dB (mute), store current volume for restoration, else clear stored value
		r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:VOL', vol, true) -- setNewValue true
		else -- toggle solo
		-- first unmute active take if it's muted
		local was_muted = unmute(take.act_take, _96dB)
			for k, tk in ipairs(take) do
			toggle_solo_act_take(tk, was_muted or take.solo, _96dB, inf) -- the toggle direction also depends on the active take volume: if all takes are muted (in which case 'solo' var will be false), the active will be unmuted and the state of the rest isn't supposed to change, so 'was_muted' is introduced to override 'solo' var
			end
		end
	r.UpdateItemInProject(item) -- redraw UI
	end

r.Undo_EndBlock('Toggle active take '..(toggle_mute and 'mute' or 'solo'), -1)

end



function Move_Active_Take_Within_Items(itm_t, down)
-- itm_t stems from Get_Items()
-- down is boolean to move down one take lane rather than up;
-- when take is the topmost or the bottommost the movement
-- wraps around;
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

local ACT, Activate, proceed, terminal_pos, multi_take = r.Main_OnCommand, r.SetActiveTake, 0, 0

	for k, item in ipairs(itm_t) do
		if r.CountTakes(item) > 1 then
		multi_take=1
		local act_take = r.GetActiveTake(item)
			if not act_take or r.TakeIsMIDI(act_take) then
			itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
			else
			local src = r.GetMediaItemTake_Source(act_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
				if not is_audio_src(src) then
				itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
				else
				proceed=proceed+1
				local act_take_idx = r.GetMediaItemTakeInfo_Value(act_take, 'IP_TAKENUMBER')
				local take_cnt = r.CountTakes(item)
					if act_take_idx == 0 and not down or act_take_idx == take_cnt-1 and down then -- determine if take is already at its terminal position relative to the movement direction
					terminal_pos=terminal_pos+1
					end
				end
			end
		end
	end

local err = not multi_take and 'not enough takes' or proceed == 0 and 'no active audio take'
or proceed == terminal_pos and ' all active audio takes \n\n'..(' '):rep(down and 5 or 7)
..'are at the '..(down and 'bottom' or 'top')

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

r.Undo_BeginBlock()

	for k, item in ipairs(itm_t) do
		if itm_t[item] and r.CountTakes(item) > 1 then
		-- since an action is involved which affects all selected items simultaneously
		-- select each item individually for processing,
		-- items will be re-selected at the end of the script main routine
		r.SelectAllMediaItems(0, false) -- deselect all
		r.SetMediaItemSelected(item, true) -- selected true
		local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK') &1 == 1
			if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // unlock because actions used here don't affect locked items // if a locked item reached this stage it's allowed in the user settings, otherwise it would've been dseelected in the main routine
		local act_take = r.GetActiveTake(item)
		local act_take_idx = r.GetMediaItemTakeInfo_Value(act_take, 'IP_TAKENUMBER') -- OR r.GetMediaItemInfo_Value(item, 'I_CURTAKE')
		-- act_take_idx = act_take_idx or get_active_take_index_via_chunk(item) -- NOT NEEDED BECAUSE THIS SCRIPT DOESN'T SUPPORT MOVING NON-AUDIO TAKES
		local take_cnt = r.CountTakes(item)
			if act_take_idx > 0 and not down or act_take_idx < take_cnt-1 and down then -- prevent wrapping around of the top take when moving up and bottom take when moving down
			local fin, idx
				if not down then -- up
				to_top() -- start out by moving active take to top lane
				fin = act_take_idx > 0 and act_take_idx-1 or take_cnt-1 -- if active take isn't the topmost, after moving it to top, cycle as many times as take count less 2 because it itself and originally previous take which has not taken its place don't need moving to simulate exchange of places between them, otherwise cycle as many times as take count less 1 because it itself doesn't need moving and only waits until as a result of other takes movement in top in turns it ends up at the bottom in a wrap-round fashion relative to its top positon
				idx = act_take_idx > 0 and act_take_idx-1 or take_cnt-1 -- if active take is not the topmost, after moving it to top use prev take index because the originally previous take which has now assumed active take original index don't need moving in order to remain at the active take original position as if it exchanged places with the active take while the order or earlier takes needs to be restored by moving each of them to top in turns; if the active take is the topmost, use bottommsost take index to move to top in turns all takes which follow the active one as they end up at the bottom until the active take itself ends up at the bottom in a wrap-round fashion relative to its top positon
				else -- down
					if act_take_idx+1 < take_cnt then -- if active take is not the bottommost, first move to top the take which follows the active one so the active one replaces its in the take sequence, i.e. moves down
					-- set active the take which follows currently active take, so it can be moved to top with the action
					local take = r.GetTake(item, act_take_idx+1)
						if take then Activate(take)
						else
						ACT(45000+act_take_idx+1, 0) -- use command ID of the action 'Take: Set 1st take active' to calculate command ID corresponding to the take index when take is an empty take inserted with 'Item: Add an empty take before/after the active take' which doesn't have a pointer so cannot be set active with API
						end
					to_top() -- start out by moving the take which follows the active take, to top lane
					fin = act_take_idx -- cycle as many times as the active take index because that's how many take exchanges will have to be made to restore the original order of takes above the active one
					idx = act_take_idx -- use the active take index because when the following take is moved to top above and the active take is moved down one take lane the prevous take assumes active take index, and during cycling the take at the original active take index, i.e. now immediately above it, must be moved up in turn to restore original take order
					else to_top() -- move the bottommost active take to top in a wrap-round fashion
					end
				end
				if fin then -- fin will be nil if the bottomost take was moved down because by this point it will have been placed at its destination at the top in a wrap-round fashion in the code above
					for i=1, fin do
					local take = r.GetTake(item, idx)
						if take then
						Activate(take)
						else
						ACT(45000+idx, 0) -- use command ID of the action 'Take: Set 1st take active' to calculate command ID corresponding to the active take index when take is an empty take inserted with 'Item: Add an empty take before/after the active take' which doesn't have a pointer so cannot be set active with API
						end
					to_top()
					end
				end
				-- restore active take active status
				if act_take then
				Activate(act_take)
				else -- IRRELEVANT BECAUSE THIS SCRIPT DOESN'T SUPPORT MOVING ACTIVE NON-AUDIO TAKES, SO CANNOT BE INITIALLY ACTIVE
				local idx = 45000 + (act_take_idx == 0 and not down and take_cnt-1 or act_take_idx == take_cnt-1 and down and 0
				or not down and act_take_idx-1 or down and act_take_idx+1)
				ACT(idx, 0)
				end
			r.UpdateItemInProject(item) -- to make re-activated take immediately visible
			end -- no wrap around block closure
			if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // re-lock
		end -- item block closure
	end -- loop end

r.Undo_EndBlock('Move active audio take '..(down and 'down' or 'up'), -1)

end



function Apply_Random_Chan_2_Active_Takes(itm_t, ch_pair, uniformly)
-- itm_t stems from Get_Items()
-- ch_pair is boolean comes from menu output
-- uniformly is boolean, comes from setting 4
-- RANDOMIZE_ACTIVE_TAKE_CHANNEL_UNIFORMLY

	local function generate_random_ch_No(ch_cnt, ch_pair, ch_No)
	-- returns human readable real world channel values
	local t = {}
		for i=1, ch_cnt do
			if ch_pair and i > 1 or not ch_pair then -- if ch_pair start storage from channel 2 because there's no pair prior to that
			t[#t+1] = (ch_pair and math.floor(i-1)..'/' or '')..math.floor(i) -- math.floor to strip trailing decimal zero
			end
		end
	local ch
		repeat
		ch = t[math.random(1, #t)]
		until ch..'' ~= ch_No..'' -- making sure that current channel doesn't end up being enabled again // convert both to strings, because channel pair is always a string
	return ch
	end


local proceed_cnt, few_ch_cnt, muted_cnt = 0, 0, 0 -- ch_pair is default state of the randomize menu item, for which ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting doesn't have to be enabled, because it requires all active takes to have the same active channel pair, a condition which due to randomization will be quickly violated

local _96dB = 1.5848931924611e-005

	for k, item in ipairs(itm_t) do
	local act_take = r.GetActiveTake(item)
		if not act_take or r.TakeIsMIDI(act_take) then
		itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
		else
		local src = r.GetMediaItemTake_Source(act_take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
		src = r.GetMediaSourceParent(src) or src
			if not is_audio_src(src) then
			itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
			else
			proceed_cnt=proceed_cnt+1
			local ch_cnt = r.GetMediaSourceNumChannels(src)
			local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
				if ch_pair and ch_cnt < 4 or ch_cnt == 2 then -- if media source channel count is 2 there's nothing to really randomize as individual channel other than simply swap 1 single channel for another, and if it's below 3 there's nothing to randomize as channel pair in 2-channel source or nothing other than simply switch to another channel pair, L/R downmix though not strictly channel pair but there's still nowhere to randomize other than simply switch to 1/2
				few_ch_cnt = few_ch_cnt+1
				end
				if r.GetMediaItemTakeInfo_Value(act_take, 'D_VOL') <= _96dB then
				muted_cnt = muted_cnt+1
				end
			end
		end
	end

local err = proceed_cnt == 0 and 'no active audio take'
or proceed_cnt == few_ch_cnt and 'too few channels to randomize'
or proceed_cnt == muted_cnt and 'all active takes are muted'
or proceed_cnt <= few_ch_cnt+muted_cnt and 'no compatible active take'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

math.randomseed(math.floor(r.time_precise())*1000) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count; math.floor() because the seeding number must be integer	// MUST BE RUN ONCE BEFORE THE MAIN LOOP BELOW, because if run for each take the generated random number will be the same for all

r.Undo_BeginBlock()

local rand_ch, ch_No

	for k, item in ipairs(itm_t) do
		if itm_t[item] then
		local act_take = r.GetActiveTake(item)
		local ch_cnt = get_take_src_channel_count(act_take)
		local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
			if not ch_pair and ch_cnt > 2 or ch_cnt > 3 -- ignoring single channel take when media source channel count is 2 and channel pair take when media source channel count is below 4 because in these scenarios there's nothing to randomize
			and r.GetMediaItemTakeInfo_Value(act_take, 'D_VOL') > _96dB
			then
				if not uniformly or not rand_ch then
				ch_No = convert_ch_idx_2_ch_No(ch)
				ch_No = generate_random_ch_No(ch_cnt, ch_pair, ch_No)
				rand_ch = convert_ch_No_2_ch_idx(ch_No)
				end
			r.SetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE', rand_ch)
			r.GetSetMediaItemTakeInfo_String(act_take, 'P_NAME', 'CH '..ch_No, true) -- setNewValue true
			end
		end
	end

r.Undo_EndBlock('Randomize channel '..(ch_pair and 'pair ' or '')..'in active takes', -1)

end



function valid_takes_remain(item, ch_No) -- used inside Remove_Channel()
local total_cntr, entire_take_cntr, match_cntr, muted_cntr = 0, 0, 0, 0
local _96dB = 1.5848931924611e-005

	for i=0, r.CountTakes(item)-1 do
	local take = r.GetTake(item, i)
		if take and not r.TakeIsMIDI(take) then
		local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
		src = r.GetMediaSourceParent(src) or src
			if is_audio_src(src) then
			total_cntr = total_cntr+1
			local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
			ch = convert_ch_idx_2_ch_No(ch)
			local a, b = table.unpack(tonumber(ch) and (ch < 1 and {1,2} or {ch}) or {ch:match('(%d+)/(%d+)')}) -- normal (-2), reverse stereo (-1) (for two channel media sources) and L/R downmix (for any media source channel count) modes (return values < 1 of convert_ch_idx_2_ch_No() ), or single channel, or channel pair
				if a+0 == ch_No or b and b+0 == ch_No then -- matches target channel number
				match_cntr = match_cntr+1
					if math.abs(r.GetMediaItemTakeInfo_Value(take, 'D_VOL')) <= _96dB then
					muted_cntr = muted_cntr+1
					end
					if a+0 > 0 and not b and a == ch_No then -- single channel is active, the entire take will be deleted
					entire_take_cntr = entire_take_cntr+1
					end
				end
			end
		end
	end
return match_cntr == muted_cntr, total_cntr-entire_take_cntr > 0
end



function Remove_Channel(itm_t, ch_No)
-- itm_t comes from Get_Items()
-- ch_No arg comes from the menu output

-- a channel is removed by removing a take it's active in,
-- since a single take cannot be removed, first evaluate number of takes in items
-- so that the undo block isn't initialized unnecessarily
local proceed_cntr, match_muted_cntr = 0, 0
	for k, item in ipairs(itm_t) do
	-- not breaking out of the loop early once proceed var is set to true
	-- to be able to exclude single take items by setting their table value to false
		if r.CountTakes(item) > 1 then
		local all_muted, audio_takes_remain = valid_takes_remain(item, ch_No)
			if all_muted then
			match_muted_cntr=match_muted_cntr+1
			end
			if audio_takes_remain then -- only confirm if after take removal some audio takes will remain
			proceed_cntr=proceed_cntr+1
			else
			itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
			end
		else -- single take item
		local take = r.GetTake(item,0)
		local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
		ch = convert_ch_idx_2_ch_No(ch)
		local b = not tonumber(ch) and ch:match('/(%d+)')
			if b or ch < 1 then -- channel pair or normal (-2), reverse stereo (-1), or L/R downmix channel modes, i.e. there's no confusion as to what should happen when 1 of the channels is unchecked, i.e. the other channel of a channel pair is left intact within take // normal (-2), reverse stereo (-1) channel modes in this case are only supported with media source channel count is 2 in order to prevent any confusion as to the course of action, which is ensured inside Construct_Channel_Menu() by only checkmarking channel menu items when media source channel has 2 channels
			proceed_cntr=proceed_cntr+1
			else -- single take item with valid single channel which cannot be removed because this means deletion of the item
			itm_t[item] = false -- set to false to prevent operation on this item in the main loop below
			end
		end
	end

local err = #itm_t == match_muted_cntr and 'all takes containing \n\n channel '..math.floor(ch_No)..' are muted'
or proceed_cntr == 0 and 'can\'t remove the only audio take'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

r.Undo_BeginBlock()

local _96dB = 1.5848931924611e-005

	for k, item in ipairs(itm_t) do
		if itm_t[item] then -- may be false if excluded in the above loop due to only containing a single take which cannot be removed
		-- since an action is involved which affects all selected items simultaneously
		-- select each item individually for processing,
		-- items will be re-selected at the end of the script main routine
		r.SelectAllMediaItems(0, false) -- deselect all
		r.SetMediaItemSelected(item, true) -- selected true
		local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK') &1 == 1
			if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // unlock because actions used here don't affect locked items // if a locked item reached this stage it's allowed in the user settings, otherwise it would've been dseelected in the main routine
		local active_take = r.GetActiveTake(item) -- store active take
			for i=r.CountTakes(item)-1,0,-1 do -- in reverse because of deletion
			local take = r.GetTake(item, i)
				if take and math.abs(r.GetMediaItemTakeInfo_Value(take, 'D_VOL')) > _96dB then -- take pointer may be nil if it's an empty take, although these must disqualify an item from selection or from being a target under mouse Get_Items() // skipping takes whose vol is lower than -96 dB accounting for flipped polarity
				local ch_cnt = get_take_src_channel_count(take)
				local ch = r.GetMediaItemTakeInfo_Value(take, 'I_CHANMODE')
					if ch > 1 or ch_cnt == 2 then -- ch values 0, 1 and 2 denote normal, reverse stereo and L/R downmix channel modes, respecting first two only makes sense if media source channel count is 2 because both channel menu items are ckeckmarked and this allows leaving 1 channel after one has been removed, when channel count is greater it's impossible to leave all other channels visible, 3 channels may allow that only if 1st or last channels are removed but providing for this scenario is an unnecessary hassle; L/R downmix is allowed because in this mode only channels 1/2 are enabled regardless of the media source total channel count; SO TAKES WITH OVER 2 VISIBLE CHANNELS ARE DISQUALIFIED inside Construct_Channel_Menu()
					ch = convert_ch_idx_2_ch_No(ch)
					local a, b = table.unpack(tonumber(ch) and (ch < 1 and {1,2} or {ch}) or {ch:match('(%d+)/(%d+)')}) -- normal (-2), reverse stereo (-1) (for two channel media sources) and L/R downmix (for any media source channel count) modes (return values < 1 of convert_ch_idx_2_ch_No() ), or single channel, or channel pair
						if a+0 > 0 and not b and a == ch_No then -- single channel is active, delete the entire take
						r.SetActiveTake(take) --do return end
						r.Main_OnCommand(40129, 0) -- Take: Delete active take from items
						elseif b then -- channel pair is active, including L/R downmix mode and normal or reverse stereo when the media source channel count is 2, disable the channel which is supposed to be removed, preserving the other one
						ch = a+0 == ch_No and b or b+0 == ch_No and a -- select channel which needs to be preserved
							if ch then
							ch = convert_ch_No_2_ch_idx(ch)
							r.SetMediaItemTakeInfo_Value(take, 'I_CHANMODE', ch) -- set to a single remaining channel
							end
						end
					end
				end
				if r.CountTakes(item) == 1 then break end -- exit the take loop to prevent deletion of the only remaining take // relevant when the same single channel is enabled in all takes because single take items are excluded in the beginning of the function
			end
			if r.ValidatePtr(active_take, 'MediaItem_Take*') and active_take ~= take
			then r.SetActiveTake(active_take) end -- restore active take
		r.UpdateItemInProject(item) -- redraw UI
			if r.CountTakes(item) > 1 then -- ensure that 'play all takes' is enabled
			r.SetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY', 1)
			end
			if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // re-lock
		end
	end

r.Undo_EndBlock('Remove channel '..math.floor(ch_No), -1) -- stripping trailing decimal 0 from

end


function get_lower_indexed_channel_take(item, ch_No) -- used in Add_Channel()
-- ch_No arg comes from the menu output
-- find within item a take in which
-- index of the active channel is lower
-- than ch_No to use it as a source for
-- duplication for the sake of the target channel
-- activation in the newly created take;
-- the lower index channel index must be
-- the closest to ch_No

local take = get_valid_take(item) -- i.e. audio take, ignoring empty and MIDI takes
local ch_cnt = get_take_src_channel_count(take)
local take_cnt = r.CountTakes(item)
local Get = r.GetMediaItemTakeInfo_Value
local lower_ch_idx, lower_ch_idx_take

	for i=0, take_cnt-1 do
	local take = r.GetTake(item, i)
		if take then -- will be nil if take is empty
			if take and not r.TakeIsMIDI(take) then
			local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
				if is_audio_src(src) then
				local ch = Get(take, 'I_CHANMODE')
					if ch > 1 or ch_cnt == 2 then -- ignoring normal (0) and reverse stereo (1) channel modes if these are enabled in a take when the media source channel count exceeds 2 because we're looking for a single channel or a channel pair take to place the new take after which is only possible in the said scenario and not when all channels of a media source whose channel count exceeds 2 are displayed in normal and reverse stereo modes // 'ch_cnt == 2' IS ESSENTIALLY REDUNDANT BECAUSE WHEN 2-CHANNEL MEDIA SOURCE IS ACTIVE IN TAKE IN NORMAL OR REVERSE STEREO MODES i.e. > 1, CHANNELS CANNOT BE ADDED, ONLY REMOVED BECAUSE BOTH ARE CHECKMARKED IN THE MAIN CHANNEL MENU INSIDE Construct_Channel_Menu()
					ch = convert_ch_idx_2_ch_No(ch) -- returns -2, -1, 0 for normal, reverse stereo, L/R downmix
					ch = tonumber(ch) and (ch < 1 and 1 or ch) or ch:match('(%d+)/') -- normal, reverse stereo (for two channel media sources) and L/R downmix (for any channel count) modes (return values < 1 of convert_ch_idx_2_ch_No() ), or single channel, or channel pair // in channel pair only 1st (left) channel is relevant as having the lower index
						if not lower_ch_idx and ch+0 < ch_No or lower_ch_idx and ch+0 < ch_No and ch+0 > lower_ch_idx then
						lower_ch_idx = ch+0
						lower_ch_idx_take = take
						end
					end
				end
			end
		end
	end

local top, alt_take, all_ch_take

	if not lower_ch_idx_take then
		for i=0, take_cnt-1 do
		local take = r.GetTake(item, i)
			if take and not r.TakeIsMIDI(take) then
			local src = r.GetMediaItemTake_Source(take) -- won't return accurate pointer for reversed takes and sections, that is those which have either 'Reverse' or 'Section' checkboxes checked in the 'Item properties' window, hence next line
			src = r.GetMediaSourceParent(src) or src
				if is_audio_src(src) then -- look for take where channel mode is NOT normal or reverse stereo (unless their vol is at or below -96 dB) and channel index is WITHIN media source channel range to use as duplication source, otherwise channel will be enabled in takes of the filtered out types without new take creation
				local ch = Get(take, 'I_CHANMODE')
				ch = convert_ch_idx_2_ch_No(ch) -- returns -2, -1, 0 for normal, reverse stereo, L/R downmix
				ch = tonumber(ch) and (ch+0 > -1 or ch_cnt == 2) and ch or not tonumber(ch) and ch:match('(%d+)/') -- normal (-2), reverse stereo (-1) (for two channel media sources only) and L/R downmix (0) (for any channel count) modes, or single channel, or channel pair // in channel pair only 1st (left) channel is relevant as having the lower index // 'ch_cnt == 2' IS ESSENTIALLY REDUNDANT BECAUSE WHEN CHANNEL MODE OF A TAKE WHOSE CHANNEL MEDIA SOURCE HAS 2 CHANNELS IS NORMAL (-2) OR REVERSE STEREO (-1), BOTH CHANNELS ARE CHECKMARKED IN THE MENU INSIDE Construct_Channel_Menu() SO THERE'S NO WAY TO ADD A CHANNEL, ONLY TO REMOVE ONE
				local vol = math.abs(Get(take, 'D_VOL')) -- math.abs to rectify vol value which may be negative if polarity is flipped
				-- evaluate according to priority for clarity, although that isn't necessary
					if ch and ch+0 <= ch_cnt -- take whose channel is within the media source channel range
					then
					lower_ch_idx_take = lower_ch_idx_take or take -- store and keep the 1st
					top = true -- return value for want_above arg of duplicate_active_take_contiguously() function
					elseif ch or vol > 1.5848931924611e-005 then -- take meant to be reused for channel activation without new take creation, i.e. having mode normal or reverse stereo and volume above -96 dB or whose channel is outside of media source channel range
					alt_take = alt_take or take -- store and keep the 1st
					else -- normal or reverse stereo in muted take
					all_ch_take = all_ch_take or take -- store and keep the 1st
					top = true
					end
				end
			end
		end
	end

-- if at this point lower_ch_idx_take var is still nil, it's because
-- the item has a single take where all channels are active of a media source
-- whose channel count exceeds 2, OR a channel at index outside of the channel range
-- is enabled (i.e. no channel is displayed), so the target channel
-- will be enabled within this very take

	if lower_ch_idx_take then -- activate duplication source take
	r.SetActiveTake(lower_ch_idx_take)
	r.UpdateItemInProject(item) -- to make re-activated take immediately visible
	end

-- return according to priority:
-- A) take whose channel is within media source channel range
-- B) whose channel is outside of media source channel range
-- or whose mode is normal / reverse stereo and volume > -96 dB
-- C) take whose mode is normal / reverse stereo and volume <= -96 dB
-- in scenarios A and C top is true because take is not reused but used as a duplication source,
-- when there's at least one take with a channel within media source channel range
-- all alternatives are ignored

return lower_ch_idx_take or not alt_take and all_ch_take, alt_take, top

end



function duplicate_active_take_contiguously(sel_item, want_above) -- used in Add_Channel()

-- duplicate and place immediately below the source take
-- or above if want_above arg is valid
-- contrary to the stock action which places it at the bottom;
-- the function must be applied to each selected item separately
-- because and action is involved which affects all selected items
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

-- empty take inserted with 'Item: Add an empty take before/after the active take' doesn't have a pointer
-- even though it can be active
	if not item or not act_take then return end

ACT(40639, 0) -- Take: Duplicate active take // this will be placed at the bottom
local new_take_idx = r.CountTakes(item)-1 -- placed at the bottom hence the 0-based index is equal to take count-1
local new_take = r.GetTake(item, new_take_idx)
--[[ OR
local new_take = r.GetTake(item, r.CountTakes(item)-1)
local new_take_idx = r.GetMediaItemTackInfo_Value(new_take, 'IP_TAKENUMBER')
--]]

	if act_take_idx ~= take_cnt-1 or want_above then -- if active take is last, not need to cycle, everything will fall in place, even though cycing would still work

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
		local idx = act_take_idx+1
		local take = r.GetTake(item, idx)
			if take then -- if take is empty it won't have a pointer so cannot be activated via API
			Activate(take) -- target take which now occupies position of the originally active take, +1 to account for the newly inserted take which precedes such take in the new take order
			to_top() -- move to top
			elseif act_take_idx+1 < 9 then -- empty take, use action to activate, which only supports takes at indices 1-9, i.e. 1st eight, all empty takes at 0-based indices 9+ will be left unmoved and concentrated at the bottom of the item
			r.Main_OnCommand(45000+idx, 0) -- Take: Set X take active
			to_top() -- move to top
			end
		end
	end

Activate(new_take) -- activate newly added take
r.UpdateItemInProject(item) -- to make re-activated take immediately visible

return new_take

end


function Add_Channel(itm_t, ch_No)
-- itm_t comes from Get_Items()
-- ch_No arg comes from the menu output

r.Undo_BeginBlock()

local Set = r.SetMediaItemTakeInfo_Value

	for k, item in ipairs(itm_t) do
	-- since an action is involved which affects all selected items simultaneously
	-- select each item individually for processing,
	-- items will be re-selected at the end of the script main routine
	r.SelectAllMediaItems(0, false) -- deselect all
	r.SetMediaItemSelected(item, true) -- selected true
	local locked = r.GetMediaItemInfo_Value(item, 'C_LOCK') &1 == 1
		if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // unlock because actions used here don't affect locked items // if a locked item reached this stage it's allowed in the user settings, otherwise it would've been dseelected in the main routine
	local src_take, alt_take, want_above = get_lower_indexed_channel_take(item, ch_No) -- returns take to be used as a duplication source for duplicate_active_take_contiguously()
	local new_take = src_take and duplicate_active_take_contiguously(item, want_above) or alt_take -- when src_take is false, the item only has takes whose channel mode is normal or reverse stereo and whose media source channel count exceeds 2 and whose volume is above -96 dB OR only takes with channels outside of the media source channnel range, in which case new take isn't created for new channel and the channel is activated within the first of such takes
	local ch = convert_ch_No_2_ch_idx(ch_No)
	Set(new_take, 'I_CHANMODE', ch) -- set to a single remaining channel
	r.GetSetMediaItemTakeInfo_String(new_take, 'P_NAME', 'CH '..math.floor(ch_No), true) -- setNewValue true
		-- if vol is at or lower that -96 dB, set it to 0 dB
		if r.GetMediaItemTakeInfo_Value(new_take, 'D_VOL') <= 1.5848931924611e-005 then
		Set(new_take, 'D_VOL', 1)
		end
	r.UpdateItemInProject(item) -- redraw UI
	r.SetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY', 1) -- ensure that 'play all takes' is enabled
		if locked then r.Main_OnCommand(40687, 0) end -- Item properties: Toggle lock // re-lock
	end

r.Undo_EndBlock('Add channel '..math.floor(ch_No), -1) -- stripping trailing decimal 0 from

end


function Change_Act_Take_Channel(itm_t, ch_No)
-- itm_t comes from Get_Items()
-- ch_No arg comes from the menu output

local proceed

	for k, item in ipairs(itm_t) do
	local act_take = r.GetActiveTake(item)
		if act_take then -- if not an empty take which doesn't have a pointer
		local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
		ch = convert_ch_idx_2_ch_No(ch)
		local a, b = table.unpack(tonumber(ch) and (ch+0 < 1 and {1,2} or {ch}) or {ch:match('(%d+)/(%d+)')}) -- ch+0 < 1 is true when channel mode is normal (-2), reverse stereo (-1) or L/R downmix (0), first two only supported for two channel media sources when RESPECT_2_CHANNEL_ITEMS setting is enabled
		proceed = proceed or not b and a+0 ~= ch_No or b
		end
	end

	if not proceed then
	local alt = #itm_t > 1 and 's are empty' or ' is empty'
	Error_Tooltip('\n\n can\'t change channel to itself \n\n\t    or take'..alt..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

r.Undo_BeginBlock()

	for k, item in ipairs(itm_t) do
	local act_take = r.GetActiveTake(item)
		if act_take then -- if not an empty take which doesn't have a pointer
		local ch = convert_ch_No_2_ch_idx(ch_No)
		local cur_ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
			if ch ~= cur_ch then -- these may be equal in multi-item selection where different channels are enaled in active takes so to the user it's may not be clear that the channel they select from the menu is already enabled in at least one of the active takes
			r.SetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE', ch)
			r.GetSetMediaItemTakeInfo_String(act_take, 'P_NAME', 'CH '..math.floor(ch_No), true) -- setNewValue true
			end
		end
	end

r.Undo_EndBlock('Enable channel '..math.floor(ch_No)..' in active takes', -1) -- stripping trailing decimal 0 from

end


function Add_Remove_Replace_2nd_Channel_In_Active_Take(itm_t, output, ch_menu_t)
-- itm_t comes from Get_Items()
-- output is menu output
-- ch_menu_t comes from Construct_Channel_Menu()

local ch_No = ch_menu_t[output]:match('(%d+)')+0 -- OR ch_menu_t[output]:gsub('!','')+0, strip checkmark if any and convert into integer
local proceed

	for k, item in ipairs(itm_t) do
	local act_take = r.GetActiveTake(item)
		if act_take then -- if not an empty take which doesn't have a pointer, just in case because items with those are disqualified inside in Get_Items()
		local ch_cnt = get_take_src_channel_count(act_take)
		local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
		ch = convert_ch_idx_2_ch_No(ch)
		local a, b = table.unpack(tonumber(ch) and {ch} or {ch:match('(%d+)/(%d+)')})
		proceed = proceed or not b and ch_No ~= a or b
		end
	end

	if not proceed then
	local alt = #itm_t > 1 and 's are empty' or ' is empty'
	Error_Tooltip('\n\n can\'t remove the only channel \n\n\t    or take'..alt..' \n\n', 1, 1, x, -200) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(2)
	return end

r.Undo_BeginBlock()

local action_type

	for k, item in ipairs(itm_t) do
	local act_take = r.GetActiveTake(item)
		if act_take then -- if not an empty take which doesn't have a pointer, just in case because items with those are disqualified inside in Get_Items()
		local ch_cnt = get_take_src_channel_count(act_take)
		local ch = r.GetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE')
		ch = convert_ch_idx_2_ch_No(ch)
		local a, b = table.unpack(tonumber(ch) and (ch+0 < 1 and {1,2} or {ch}) or {ch:match('(%d+)/(%d+)')}) -- ch+0 < 1 is true when channel mode is normal (-2), reverse stereo (-1) or L/R downmix (0), first two only supported for two channel media sources when RESPECT_2_CHANNEL_ITEMS setting is enabled
		-- determine new channel value;
		-- the operation type (removal or addition) will be the same
		-- for all items, because Construct_Channel_Menu() ensures
		-- that the same channels are active in all items
		ch_No = math.floor(ch_No) -- strip trailing 0
		ch = ch_No == a+0 and b or b and ch_No+0 == b+0 and a -- logic if removing channel from a channel pair by unchecking menu item because menu items corresponding to active channels are checkmarked
		action_type = ch and 'Remove'
		ch = ch or b and ch_No > b+0 and b..'/'..ch_No or ch_No < a+0 and ch_No..'/'..math.floor(a+0) or ch_No > a+0 and math.floor(a)..'/'..ch_No -- logic of adding second channel to a single one to create channel pair, the available channels displayed in the menu are always within the range of 0 - media source channel count and always either precede or follow the checkmarked item which denotes active channel(s)
		action_type = action_type or b and 'Replace' or 'Add'
			if ch then -- ch is expected to always be valid, so evaluating just in case
			local ch_No = ch
			ch = convert_ch_No_2_ch_idx(ch)
			r.SetMediaItemTakeInfo_Value(act_take, 'I_CHANMODE', ch)
			ch = tonumber(ch_No) and math.floor(ch_No) or ch_No
			r.GetSetMediaItemTakeInfo_String(act_take, 'P_NAME', 'CH '..ch, true) -- setNewValue true
			end
		end
	end


r.Undo_EndBlock(action_type..' second channel '..(action_type == 'Replace' and 'with channel ' or '')..math.floor(ch_No)..' in active takes', -1) -- stripping trailing decimal 0 from

end


------------ MAIN ROUTINE ------------

Error_Tooltip('') -- clear other tooltips, such as toolbar button tooltip if the script is executed from a toolbar button

local sett = {INCLUDE_LOCKED_ITEMS:match('%S') or false, -- false alternative is needed for Settings_State_Readout() which doesn't support nil}
RESPECT_2_CHANNEL_ITEMS:match('%S') or false,
-- the following are mutually exclusive
CHANGE_ACTIVE_TAKE_CHANNEL:match('%S') or false,
RANDOMIZE_ACTIVE_TAKE_CHANNEL_UNIFORMLY:match('%S') or false,
not CHANGE_ACTIVE_TAKE_CHANNEL:match('%S') and ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE:match('%S') or false}

ALLOW_DIFFERENT_TAKE_COUNT = ALLOW_DIFFERENT_TAKE_COUNT:match('%S')

local itm_t, item_under_mouse

::RELOAD::

itm_t, item_under_mouse = Get_Items(sett[1], sett[2], sett[3] or sett[5] and 5, item_under_mouse) -- sett[1] want_locked, sett[2] want_2_ch, sett[3] or sett[5] are want_act_take, item_under_mouse return value is item under mouse to prevent item deselection loop below, item_under_mouse argument on the other hand is a pointer of item under mouse detected when the script was first excuted so that the script is latched onto it even if during menu reload another item falls under the mouse cursor as a result of the cursor movement over the menu to click menu items

	if not itm_t then
	Error_Tooltip('\n\n no item(s) under mouse \n\n\t  or selected \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo)
	end

local no_valid_itms = #itm_t == 0

	if no_valid_itms then
	local err = (sett[3] or sett[5]) and 'no valid active takes' or 'no supported items'
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1, x, -100) -- caps, spaced true
	-- make the error message stick for half a second, because when the menu loads it may get obscured by it
	pause(0.5)
	end

local sel_itm_t
	if not item_under_mouse and #itm_t > 0 then
	-- deselect all invalid items for clarity, only if at least one item IS valid,
	-- i.e. table is not empty, no point in deselecting if all are invalid
	-- because error message and menu structure will signal that
		for i=r.CountSelectedMediaItems(0)-1,0,-1 do -- in reverse due to deselection
		local item = r.GetSelectedMediaItem(0,i)
			if not itm_t[item] then
			r.SetMediaItemSelected(item, false)
			r.UpdateItemInProject(item) -- refresh UI so deselection is immediately apparent
			end
		end
	elseif item_under_mouse
	and r.IsMediaItemSelected(item_under_mouse) and r.CountSelectedMediaItems(0) > 1 then -- there's at least one selected item which isn't item under mouse
	-- store selected items because they may end up being deselected as a result of 'remove channel' and 'move active take within item' operations which affect items by selecting them individually due to use of actions, the selection will be restored at the end of the main routine
	sel_itm_t = Re_Store_Selected_Items()
	end


local ch_menu_t, take_menu_t, itm_t = Construct_Channel_Menu(itm_t, sett[3] and 3 or sett[5] and 5) -- itm_t may be returned updated if some items were deselected inside the function or as nil along with other return values if there're no valid items

local u = '\xCC\xB2' -- underscore, U+0332 COMBINING LOW LINE
local readout = Settings_State_Readout(table.unpack(sett))
local sett_menu = (no_valid_itms and '#' or '>')..'SETTINGS  '..(no_valid_itms and '|' or readout)..'|'
..check(sett[1])..'1. Include locked items|'
..check(sett[2])..'2. Respect 2 channel items|'
..check(sett[3])..'3. Change active take channel|'
..check(sett[4])..(sett[3] and '' or '#')..'    4. Randomize channel Uniformly|' -- grayed out when setting 3 is disabled
..check(sett[5])..'5. Add/remove/replace 2nd channel in the active take|'
..check(ALLOW_DIFFERENT_TAKE_COUNT)..'#6. Allow different take count in multi-item selection'
sett_menu = sett_menu:gsub('%d%.', function(c) if c ~= '6.' then return c:gsub('%d', u..'&%0'..u) end end) -- add underscore to numbers which are used as quick access shortcuts, avoiding '2nd' in the name of setting 5; excluding setting 6 which is grayed out; ampersand is required, otherwise keyboard input isn't registered unlike when there's no underscore character


-- In the end had to create two randomize menu items only dependent on CHANGE_ACTIVE_TAKE_CHANNEL setting
-- because making channel pair randomization dependent on ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE setting
-- requires all active takes to have the same active channel pair, a condition which due to randomization
-- will be quickly violated after initial selection,
-- making channel pair randomization the default randomization action without activation
-- of any of the two abovementioned settings cannot work either because in this case
-- the script will be bound by the general rule of items having to have identical active channel set
-- which for targetting active take is absolutely unnecessary and will impede the operation
local randomize = 'Randomize active audio take &channel'
local U = sett[4] and ' (U)' or ''
local action_menu = 'Toggle active audio take &mute|Toggle active audio take &solo'
..'|Move active audio take &up|Move active audio take &down|'
..(sett[3] and '' or '#')..randomize..U..'|'
..(sett[3] and '' or '#')..randomize:gsub('&','')..' &pair'..U
-- add underscore to quick access shortcuts
	for _, v in ipairs ({'m','s','u','d','c','p'}) do
	action_menu = action_menu:gsub('&'..v, '%0'..u)
	end


local take_menu, ch_menu
	if not no_valid_itms then
		if #take_menu_t == 0 then
		-- take_menu_t is empty when CHANGE_ACTIVE_TAKE_CHANNEL
		-- or ADD_REMOVE_REPLACE_2nd_CHANNEL_IN_ACTIVE_TAKE settings are enabled,
		-- so simply close the settings submenu
		take_menu = '<'
		else
		take_menu = table.concat(take_menu_t)
		-- close SETTINGS submenu after the last take menu item
		local i = 0
		take_menu = (#take_menu_t > 1 and '|#Click to change active take' or '')
		..take_menu:gsub('|', function(c) i = i+1; if i == #take_menu_t then return '|<' end end)
		end
	ch_menu = table.concat(ch_menu_t,'|')
	end

-- when no valid items, only load the SETTINGS menu so settings can be managed
local menu = sett_menu..(no_valid_itms and '' or '|'..take_menu..'||'..action_menu..'||'..ch_menu)
local output = Reload_Menu_at_Same_Pos(menu, 1) -- keep_menu_open true
local is_new_value, scr_path, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local take_menu_title = take_menu_t and #take_menu_t > 1 and 1 or 0 -- when there's only 1 take or no take menu (as when act_take_focus is true), take menu title is not displayed // take_menu_t is nil when there's no valid items because Construct_Channel_Menu() exits immediately
local act_take_focus = sett[3] or sett[5]

	if output == 0 then return r.defer(no_undo)
	elseif output < (no_valid_itms and 7 or 6) then -- when only settings menu is displayed there's also menu title hence 7
	local exclusive_t = {[3]=sett[3],[5]=sett[5]}
	output = no_valid_itms and output-1 or output -- when no_valid_itms or no_valid_act_takes is true first item is SETTINGS menu title
	sett[output] = Toggle_Settings_From_Menu(output, sett, scr_path, exclusive_t)
		-- handle mutually exclusive settings
		if exclusive_t and exclusive_t[output] ~= nil and sett[output] then -- exclusive_t[output] may be true or false, the condition ensures that this is one of the mutually exclusive settings; sett[output] is true so set the rest mutually exclusive to false
			for k in pairs(exclusive_t) do
				if k ~= output then
				sett[k] = false
				end
			end
		end
	elseif output <= 6 + take_menu_title + #take_menu_t then
	output = output-6 - take_menu_title -- offset SETTINGS submenu
	Activate_Take(itm_t, output-1) -- -1 to conform to 0-based take indexing // doesn't create undo point
	elseif output <= 6 + take_menu_title + #take_menu_t + 6 then -- +6 is toggle mute/solo, move active take up/down and two randomize actions
	output = output-6 - take_menu_title - #take_menu_t -- offset SETTINGS and take submenus
		if output < 3 then -- toggle mute/solo
		Toggle_Mute_Solo_Act_Take(itm_t, output == 1) -- output == 1 is toggle_mute argument // undo point is created inside
		elseif output < 5 then -- move up/down
		Move_Active_Take_Within_Items(itm_t, output == 4) -- down is output == 4
		else
		Apply_Random_Chan_2_Active_Takes(itm_t, output == 6, sett[4]) -- want_ch_pais is output == 6, sett[4] is uniformly
		end
	else
	output = output-6 - take_menu_title - #take_menu_t - 6 -- offset by settings submenu, take menu title + take menu, two toggle actions, two move actions and two randomize actions
	local enabled = (ch_menu_t[output]..''):match('^!') -- converting channel # to string in case not checkmarked when act_take_focus var is false, because if true, all values are converted into strings inside Construct_Channel_Menu()
		if not act_take_focus then
		local func = enabled and Remove_Channel or Add_Channel
		func(itm_t, output)
		else
		local func = sett[3] and Change_Act_Take_Channel or sett[5] and Add_Remove_Replace_2nd_Channel_In_Active_Take
		func(itm_t, output, ch_menu_t)
		end
	end


	if not item_under_mouse and itm_t then	-- itm_t may returned as nil from Construct_Channel_Menu() if there're no valid items
	-- re-select all originally selected valid items
	-- because they may have been deselected during operations
		for k, item in ipairs(itm_t) do
		r.SetMediaItemSelected(item, true) -- selected true
		r.UpdateItemInProject(item)
		end
	RELOAD = 1 -- inside Get_Items() this will prevent focus shifting to item under mouse when the menu is reloaded because due to menu clicks the mouse cursor is very likely to end up over some other item, item under mouse pointer is preserved as item_under_mouse only if it was the initial the focus when the script was first executed
	elseif item_under_mouse and sel_itm_t then -- restore item selection which will be lost after 'remove channel' and 'move active take within item' operations which affect items by selecting them individually due to use of actions
	Re_Store_Selected_Items(sel_itm_t)
	end


goto RELOAD





