--[[
ReaScript name: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence:
REAPER: at least v5.962
About:	The script is an ancillary script mainly for 
			'BuyOne_Move active take down within selected items.lua'
			to be used within a custom action in order to move
			active take to bottom to complement REAPER native action
			'Item: Move active takes to top', i.e.

			Custom: Move active takes to bottom
				Action: Skip next action, set CC parameter to relative +1 if action toggle state enabled, -1 if disabled, 0 if toggle state unavailable.
				Script: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua
				Action: Skip next action if CC parameter >0/mid
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				Script: BuyOne_Move active take up within selected items.lua
				...
				Action: Skip next action if CC parameter >0/mid
				Script: BuyOne_Move active take up-down within selected items - FINITE_MOVEMENT setting.lua

			It can affect 'BuyOne_Move active take up within selected items.lua'
			as well but there's no use case for that other than 
			being able to change its FINITE_MOVEMENT setting
			externally.

]]


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


local is_new_value, scr_name, sect_ID, cmd_ID, mode, resol, val, contextstr = r.get_action_context()

local section, key = 'Move active take up-down within selected items', 'FINITE MOVEMENT'
local state = r.GetToggleCommandStateEx(sect_ID, cmd_ID)
state = state ~= -1 and state~1 or 1 -- flip if already set, otherwise set to On
r.SetToggleCommandState(sect_ID, cmd_ID, state)
-- OR TO SET TOGGLE STATE IN VERSONS 7+
-- state = state < 1 and 4 or 8
-- r.set_action_options(state)

r.RefreshToolbar2(sect_ID, cmd_ID)

-- the extended state is peeked by the main script
	if state == 1 then
	r.SetExtState(section, key, '', false) -- persist false
	else
	r.DeleteExtState(section, key, false) -- persist false
	end



