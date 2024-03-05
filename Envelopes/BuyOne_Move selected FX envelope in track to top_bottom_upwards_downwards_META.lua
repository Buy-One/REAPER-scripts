--[[
ReaScript name: BuyOne_Move selected FX envelope in track to top_bottom_upwards_downwards_META.lua (6 scripts)
Author: BuyOne
Version: 1.6
Changelog:  v1.6 #Fixed main functionality in cases where extended data is stored in envelope chunk
		 #Fixed swap functionality and made it more logical when the selected envelope is at the top or bottom
		 #Optimized undo point display when script is aborted due to error
		 #Added error messages
		 #Added a menu to the META script so it's now functional as well
		 allowing to use from a single menu all options available as individual scripts
		 #Updated About text
	    v1.5 #Fixed individual script installation function
		 #Made individual script installation function more efficient
	    v1.4 #Creation of individual scripts has been made hands-free. 
		 These are created in the directory the META script is located in
		 and from there are imported into the Action list.
		 #Updated About text
	    v1.3 #Added functionality to export individual scripts included in the package
		 #Added swap scripts behavior clarification to the About text.
		 #Updated About text
	    v1.2 #Fixed script crach when applying to the only envelope of a particular FX
	    v1.1 #Added swap mode to complement cyclic mode
		 #Fixed a bug of respecting hidden envelopes during reordering
Author URL: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif
Extensions: SWS/S&M extension (not mandatory but recommended)
Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20FX%20envelope%20in%20track%20to%20top_bottom_upwards_downwards.gif		
Metapackage: true
Provides: 	[main] .
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to top lane.lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track to bottom lane.lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track up one lane (cycle).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track down one lane (cycle).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track up one lane (swap).lua
		[main] . > BuyOne_Move selected FX envelope/BuyOne_Move selected FX envelope in track down one lane (swap).lua
About:	If this script name is suffixed with META, when executed 
	it will automatically spawn all individual scripts included 
	in the package into the directory of the META script and will 
	import them into the Action list from that directory. That's 
	provided such scripts don't exist yet, if they do, then in 
	order to recreate them they have to be deleted from the Action 
	list and from the disk first. It will also display a menu
	allowing to execute all actions available as individual scripts.
	Each menu item is preceded with a quick access shortcut so
	it can be triggered from keyboard.  
	If there's no META suffix in this script name it will perfom 
	the operation indicated in its name. Individual scripts can
	be included in custom actions.

	The individual scripts move selected FX envelope 
	of a track to the top/bottom lane, upwards/downwards 
	one lane depending on the script name.   
	
	(cycle) in the script name means that all envelopes move 
	upwards/downwards in unison with the selected one.  
	(swap) in the script name means that the selected envelope 
	is swapped with the one immediately above/below it while other 
	envelopes maintain their lanes. Unless the selected envelope 
	is at the top or at the bottom lane and being at the top 
	it should move up or being at the bottom it should move down, 
	in which case they're swapped with the bottom and top envelope 
	lanes respectively while lanes in between maintain their position.		
	
	Upwards/downwards movement is cyclic, i.e. if an envelope is pushed
	past top/bottom lane its movement continues from the oppostite end.  
	
	Reordering only affects active envelopes of the track FX
	the selected envelope belongs to, as all envelopes of a particular
	FX are grouped together and envelopes of different FX cannot be 
	mixed while TCP envelopes always precede any FX envelopes and themselves
	cannot be reordered. Hence the movement is not relative to ALL 
	active/visible track envelopes but only to those of the same FX
	as the selected envelope.  

]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function no_undo()
do return end
end


function META_Spawn_Scripts(fullpath, fullpath_init, scr_name, names_t)

	local function Dir_Exists(path) -- short
	local path = path:match('^%s*(.-)%s*$') -- remove leading/trailing spaces
	local sep = path:match('[\\/]')
	local path = path:match('.+[\\/]$') and path:sub(1,-2) or path -- last separator is removed to return 1 (valid)
	local _, mess = io.open(path)
	return mess:match('Permission denied') and path..sep -- dir exists // this one is enough
	end

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

	if not fullpath:match(Esc(scr_name)) then return true end -- will allow to continue the script execution outside, since it's not a META script

local names_t, content = names_t

	if not names_t or names_t == 0 then -- if names table isn't supplied search names list in the header
	-- load this script
	local this_script = io.open(fullpath, 'r')
	content = this_script:read('*a')
	this_script:close()
	names_t, found = {}
		for line in content:gmatch('[^\n\r]+') do
			if line and line:match('Provides:') then found = 1 end
			if found and line:match('%.lua') then
			names_t[#names_t+1] = line:match('.+[/](.+)') or line:match('BuyOne.+[%w]') -- in case the new script name line includes a subfolder path, the subfolder won't be created
			elseif found and #names_t > 0 then
			break -- the list has ended
			end
		end
	end

	if names_t and #names_t > 0 then

--[[ GETTING PATH FROM THE USER INPUT

	r.MB('              This meta script will spawn '..#names_t
	..'\n\n     individual scripts included in the package'
	..'\n\n     after you supply a path to the directory\n\n\t    they will be placed in'
	..'\n\n\twhich can be temporary.\n\n           After that the spawned scripts'
	..'\n\n will have to be imported into the Action list.','META',0)

	local ret, output -- to be able to autofill the dialogue with last entry on RELOAD

	::RETRY::
	ret, output = r.GetUserInputs('Scripts destination folder', 1,
	'Full path to the dest. folder, extrawidth=200', output or '')

		if not ret or #output:gsub(' ','') == 0 then return end -- must be aborted outside of the function

	local path = Dir_Exists(output) -- validate user supplied path
		if not path then Error_Tooltip('\n\n invalid path \n\n', 1, 1) -- caps, spaced true
		goto RETRY end
	]]

		-- load this script if wasn't loaded above to parse the header for file names list
		if not content then
		local this_script = io.open(fullpath, 'r')
		content = this_script:read('*a')
		this_script:close()
		end

		local path = fullpath:match('(.+[\\/])') -- WHEN NOT GETTING PATH FROM USER INPUT, USE META SCRIPT PATH

		-- spawn scripts
		for k, scr_name in ipairs(names_t) do
			if not r.file_exists(path..scr_name) then -- only spawn if doesn't already exist, this is meant to prevent accidental overwriting of custom USER SETTINGS in individial scripts OR wtiring to disk each time META script is run if it's equipped with a menu // if spawned script update is required it must be done via installer script, or manually by copy and paste, or by deleting it and running this script
			local new_script = io.open(path..scr_name, 'w') -- create new file
			content = content:gsub('ReaScript name:.-\n', 'ReaScript name: '..scr_name..'\n', 1) -- replace script name in the About tag
			new_script:write(content)
			new_script:close()
			end
		end

		-- CONDITION BY THE SCRIPT BEING INSTALLED TO OTHERWISE ALLOW SPAWNING SCRIPTS WITH INSTALLER SCRIPT VIA dofile() WITHOUT INSTALLATION ONLY FOR THE SAKE OF SETTINGS TRANSFER WHICH IS SUPPOSED TO BE DONE WHILE THE SCRIPT IS IN A TEMP FOLDER, get_action_context() alone is useless as a condition since when this script is executed via dofile() from the installer script the function returns props of the latter
	--	if script_is_installed(fullpath) then -- install individual scripts
	-- OR, which is more efficient, in the scenario described above this condition will be false
		if fullpath_init:match('.+[\\/](.+)') == scr_name then -- install individual scripts
			for _, sectID in ipairs{0} do -- Main // per script list
				for k, scr_name in ipairs(names_t) do
				local result = r.AddRemoveReaScript(true, sectID, path..scr_name, true) -- add, commit true // doesn't affect the props of an already installed script if attempts to install it again, so is safe
				end
			end
		end

	end

end



local function GetObjChunk(obj)
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
  -- Try standard function -----
	local t = tr and {r.GetTrackStateChunk(obj, '', false)} or item and {r.GetItemStateChunk(obj, '', false)} -- isundo = false
	local ret, obj_chunk = table.unpack(t)
		if ret and obj_chunk and #obj_chunk >= 4194303 and not r.APIExists('SNM_CreateFastString') then return 'err_mess'
		elseif ret and obj_chunk and #obj_chunk < 4194303 then return ret, obj_chunk -- 4194303 bytes = (4096 kb * 1024 bytes) - 1 byte
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
local err_mess = 'The size of track data requires\n\nSWS/S&M extension to handle them.\n\nIf it\'s installed then it needs to be updated.\n\nGet the latest build of SWS/S&M extension at\nhttps://www.sws-extension.org/\n\n'
r.ShowConsoleMsg(err_mess, r.ClearConsole())
end


local function SetObjChunk(obj, obj_chunk)
	if not (obj and obj_chunk) then return end
local tr = r.ValidatePtr(obj, 'MediaTrack*')
local item = r.ValidatePtr(obj, 'MediaItem*')
	return tr and r.SetTrackStateChunk(obj, obj_chunk, false) or item and r.SetItemStateChunk(obj, obj_chunk, false) -- isundo is false
end


function Is_Track_FX_Envelope(env) -- 1st return val being nil means not a track FX envelope
local tr, fx_idx, parm_idx = r.Envelope_GetParentTrack(env)
	if fx_idx > -1 then return tr, fx_idx, parm_idx end
end


function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
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


function Move_Sel_Envelope(env, env_GUID, fx_chunk, scr_name)

	local function gmatch_alt(str, ...)
	local i = 1
	local t = {...}
		return function()
		local st, fin, retval
			for k, capt in ipairs(t) do
			st, fin, retval = str:find('('..capt..')',i)
				if retval then
					if retval:match('<PROGRAMENV') and k < #t then
					-- pattern <.-<EXT.->.-> will capture <PROGRAMENV and next <PARMENV block
					-- if the first found <PARMENV block doesn't include <EXT block but one of dthe next one does,
					-- in this case switch to '<.->' pattern which will ignore the next block
					st, fin, retval = str:find('('..t[k+1]..')',i)
					end
				break
				end
			end
		i = fin and fin+1 or i+1
		return retval
		end
	end

local t = {}
local str = ''
local vis_env_cnt = 0

	for block in gmatch_alt(fx_chunk, '<.-<EXT.->.->', '<.->') do -- construct a table merging <PROGRAMENV block with preceding <PARMENV block of the same fx param in one table slot and only adding new slots when a block of a visible envelope has been found, thereby attaching to them blocks of hidden envelopes to prevent hidden envelopes being accounted for in reordering below
	str = #str > 0 and str..'\n'..block or str..block -- concatenate a string as long as there're no blocks of visible envelopes
		if block:match('\nVIS 1 ') then t[#t+1] = str -- once a block of a visible evelope, dump the string concatenated above into the table
		str = '' -- reset the string
		vis_env_cnt = vis_env_cnt+1 -- count visible envelopes to condition error mess
		elseif #t > 0 and block:match('<PROGRAMENV') and t[#t]:match('\nVIS 1 ') then -- merge <PROGRAMENV block with preceding <PARMENV block of a visible envelope, hidden envelopes data are collected into the str above and dumped into the table along with the next found visible envelope <PARMENV block
		t[#t] = t[#t]..'\n'..str
		str = '' -- reset the string
		end
	end

	if vis_env_cnt == 1 then return _, _, '    the selected envelope is  \n\n  the only visible in relevant fx' end -- abort when the sel env is the only FX env visible // 3 return values to match those at the end of the function

local env_block_orig = table.concat(t,'\n')--:gsub('\n\n','\n')

	for k, env_block in ipairs(t) do -- reorder
		if env_block:match(Esc(env_GUID)) then -- if matches selected env GUID
			if scr_name:match('top') then
			table.insert(t, 1, env_block) -- copy to top
			table.remove(t, k+1) -- delete old slot, +1 since the table lengthens after insert above
			elseif scr_name:match('bottom') then
			table.insert(t, #t+1, env_block) -- copy to after the last slot
			table.remove(t, k) -- delete old slot
			elseif scr_name:match(' up ') then
				if scr_name:match('cycle') then
				table.insert(t, #t+1, t[1]) -- copy 1st slot to after the last
				table.remove(t, 1) -- delete old 1st slot
				else -- swap
				local dest = k-1 == 0 and #t+1 or k-1 -- destination slot to insert // if 1st slot, move to the last
				local rem = k-1 == 0 and 1 or k+1 -- slot to remove
				table.insert(t, dest, env_block)
				table.remove(t, rem)
					if k-1 == 0 then -- if 1st slot, after moved to the last above, move former last (now penultimate) to the first slot, swapping 1st with the last leaving lanes in between intact
					table.insert(t, 1, t[#t-1])
					table.remove(t, #t-1)
					end
				end
			elseif scr_name:match(' down ') then
				if scr_name:match('cycle') then
				table.insert(t, 1, t[#t]) -- copy last slot to 1st
				table.remove(t, #t) -- delete old last slot
				else -- swap
				local dest = k == #t and 1 or k+2 > #t and #t+1 or k+2 -- destination slot to insert // when the envelope is the last, penultimate or other // if last slot move to the 1st // +2 because to land after of the next (+1) slot, the one following the next must be replaced (which makes it +2)
				local rem = k == #t and #t+1 or k -- slot to remove // when the envelope is the last or other // +1 because after insertion below, the table lengthens and the last slot index increases
				table.insert(t, dest, env_block)
				table.remove(t, rem)
					if k == #t then -- if last slot, after moved to the 1st above, move former 1st (now second) to the last slot, swapping last with the 1st leaving lanes in between intact
					t[#t+1] = t[2] --table.insert(t, #t+1, t[2])
					table.remove(t, 2)
					end
				end
			end
		break end
	end

local env_block_upd = table.concat(t,'\n')

local no_change = env_block_orig == env_block_upd
local mess = no_change and scr_name:match('top') and 'top' or no_change and scr_name:match('bottom') and 'bottom' or no_change and not scr_name:match('top') and not scr_name:match('bottom') and not scr_name:match(' up ') and not scr_name:match(' down ') and 'wrong script name' -- last option in case neither of the 4 direction words is found in the script name

return env_block_orig, env_block_upd, mess -- orig and updated versions + string for err message

end


local _, fullpath_init, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local fullpath = debug.getinfo(1,'S').source:match('^@?(.+)') -- if the script is run via dofile() from installer script the above function will return installer script path which is irrelevant for this script
local scr_name = fullpath_init:match('.+[\\/].-_(.+)%.%w+') -- without path, scripter name and file ext // fullpath_init insures that if the script functionality depends on its name the script doesn't run when executed via dofile() or loadfile() from the installer script because get_action_context() returns path to the installer script

-- doesn't run in non-META scripts
META_Spawn_Scripts(fullpath, fullpath_init, 'BuyOne_Move selected FX envelope in track to top_bottom_upwards_downwards_META.lua', names_t)

	if scr_name:lower():match('^script updater and installer') -- whether this script is run via installer script in which case get_action_context() returns the installer script path
	then return r.defer(no_undo) end


local names_t = {'Move selected|FX envelope in track|',
'&1. To top lane',
'&2. To bottom lane',
'&3. Up one lane (cycle)',
'&4. Down one lane (cycle)',
'&5. Up one lane (swap)',
'&6. Down one lane (swap)'
}

local META = scr_name:match('.+_META$')

::RELOAD::

local output = META and Reload_Menu_at_Same_Pos(table.concat(names_t,'|'), 1) -- keep_menu_open true

	if output == 0 then return r.defer(no_undo) -- output is 0 when the menu in the META script is clicked away from
	elseif output < 3 then -- menu title was clicked
	goto RELOAD
	end

local sel_env = r.GetSelectedTrackEnvelope(0)
local err = not sel_env and 'no selected track fx envelope'
or not Is_Track_FX_Envelope(sel_env) and 'not a track fx envelope'

	if err then
	local x = META and -380 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
	Error_Tooltip('\n\n  '..err..'  \n\n', 1, 1, x) -- caps, spaced true
		if META then goto RELOAD
		else return r.defer(no_undo) end
	end

scr_name = META and names_t[output-1] or scr_name -- -1 to offset the menu title
scr_name = scr_name:lower():gsub('&%d%.','') -- removing menu shortcuts while leaving space

local tr, fx_idx, parm_idx = r.Envelope_GetParentTrack(sel_env)

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local retval, env_chunk = r.GetEnvelopeStateChunk(sel_env, '', false) -- isundo false
local env_GUID = env_chunk:match('EGUID (.-)\n')
local fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx)
local next_fx_GUID = r.TrackFX_GetFXGUID(tr, fx_idx+1)
local ret, chunk = GetObjChunk(tr)
	if ret == 'err_mess' then
	Err_mess()
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		if META then goto RELOAD
		else return r.defer(no_undo) end
	end
local capt1 = Esc(fx_GUID)..'.-<PARMENV.+<PROGRAMENV.+>' -- <PROGRAMENV block follows <PARMENV block of the same effect, hence must be evaluated first // covers code from the 1st <PARMENV to the last <PROGRAMENV block
local capt2 = Esc(fx_GUID)..'.-<PARMENV.+<PARMENV.+>'
local capt3 = Esc(fx_GUID)..'.-<PARMENV.->'
local fx_chunk = next_fx_GUID and ( chunk:match('('..capt1..').-WAK.-'..Esc(next_fx_GUID))
or chunk:match('('..capt2..').-WAK.-'..Esc(next_fx_GUID)) ) -- if there's main track fx downstream
or chunk:match('('..capt1..').-WAK.-<FXCHAIN_REC') or chunk:match('('..capt2..').-WAK.-<FXCHAIN_REC') -- if there's input fx block downstream
or chunk:match('('..capt1..').-WAK.-<ITEM') or chunk:match('('..capt2..').-WAK.-<ITEM') -- if there's item block downstream
or chunk:match('('..capt1..').-WAK.+') or chunk:match('('..capt2..').-WAK.+') -- if the fx is the last in the chunk
or chunk:match('('..capt3..').-WAK.+') -- the only envelope in fx

local env_block_orig, env_block_upd, mess = Move_Sel_Envelope(env, env_GUID, fx_chunk, scr_name)

	if mess then
	mess = not env_block_orig and mess or mess:match('wrong') and mess or 'the selected envelope  \n\n  is already at the '..mess
	local x = META and -380 or 0 -- if META script shift the tooltip away from the menu so it's not gets covered by it when the menu is reloaded
	Error_Tooltip('\n\n  '..mess..'  \n\n', 1, 1, x) -- caps, spaced true
	r.Undo_EndBlock(r.Undo_CanUndo2(0) or '', -1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated when the script is aborted following  Undo_BeginBlock() (to display an error for example), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		if META then goto RELOAD
		else return r.defer(no_undo) end
	end

local chunk_no_env = chunk:gsub(Esc(env_block_orig), '') -- remove envelopes

SetObjChunk(tr, chunk_no_env) -- set without envelopes

local chunk1, chunk2 = chunk:match('(.+'..Esc(fx_GUID)..')(.+)')
local chunk_upd = chunk1..'\n'..env_block_upd..chunk2

SetObjChunk(tr, chunk_upd) -- set with reordered envelopes


local sel_env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create false // after setting the chunk and reordering envelopes, originally selected envelope pointer ends up belonging to another envelope, so in order to keep the original envelope selected its new pointer must be retrieved because now it will differ from the originally selected envelope pointer

r.SetCursorContext(2, sel_env) -- restore env selection


r.PreventUIRefresh(-1)
local undo = META and 'Move selected FX envelope in track'..scr_name or scr_name
r.Undo_EndBlock(undo,-1)

	if META then goto RELOAD end






