--[[
ReaScript name: BuyOne_Keep screen awake when AFK.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: at least v5.962, 7.0+ recommended
Extensions: 
Provides: [main=main,midi_editor] .
About: 	The script is for those who for whatever reason 
			don't want to change their display settings in 
			order to prevent the screen from going into 
			sleep mode, i.e. getting turned off which may be
			desirable for recording sessions.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes type in number in seconds,
-- should be smaller than the screen timeout time;
-- if empty or invalid defaults to 50 sec
UPDATE_RATE = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local time_init = reaper.time_precise()
local rate = UPDATE_RATE:match('%d+') or 50
    if reaper.set_action_options then
    reaper.set_action_options(1)
    end

function update()

    if reaper.time_precise() - time_init >= rate+0 then
        if gfx.getchar() == -1 then -- no window, open
        gfx.init('',1,1)
		  -- restore last mouse context when window is opened
        reaper.SetCursorContext(reaper.GetCursorContext2(true)) -- want_last_valid true 
        else -- window is open, close
        gfx.quit()
        end
    time_init = reaper.time_precise()
    end

reaper.defer(update)
end

update()


