--[[
ReaScript name: BuyOne_Store last audio buffer size in project file and display warning if changed between sessions.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Created in response to a feature request  
	https://forum.cockos.com/showthread.php?t=247801
	
	To be used efficiently the script must be run at the moment 
	of opening a project and at every project save.  
	This ensures immediate accessibility and update of the 
	relevant data.  
	For that, create two custom actions, one for project loading
	and another one for saving:
	
	*Project loading* (in the following order)
	
	File: Open project
	BuyOne_Store last audio buffer size in project file and display warning if changed between sessions.lua
	
	*Project saving* (in the following order)
	
	BuyOne_Store last audio buffer size in project file and display warning if changed between sessions.lua
	File: Save project
	
	
	Unfortunately the project must be loaded via the file browser.  
	Running the script along with opening a recent project from 
	the list isn't possible.
	
	At the moment only Windows is supported. Can be upgraded at user
	request and with their assistance.
	
]]

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function no_undo()
do return end
end


function Get_OS()
local OS = r.GetAppVersion()
return (not OS:match('/') or OS:match('/x')) and 'win'
or OS:match('OS') and 'mac' or OS:match('linux')
-- OR
-- local OS = r.GetOS()
-- return OS:match('Win') or OS:match('OSX') and 'Mac' or 'Other'
end

local OS = Get_OS()

	if OS ~= 'win' then r.MB('The script only recognizes Windows\n\n'..(' '):rep(12)..'audio device properties.\n\n'..(' '):rep(14)..'For your OS support\n\n  please contact the script developer\n\n'..(' '):rep(13)..'at the addresses listed\n\nin the Website tag of the script header.','INFO',0) return r.defer(no_undo) end


function Display_Data(OS, device_name_t, device_idx, buff, blocks, use_asio)
local device_idx = device_idx+1 -- because at reaper.ini 'mode' key device_idx is 0-based
local name = device_name_t[OS][device_idx]
local data = (device_idx >= 1 and device_idx <= 3) and 'Buffers: '..blocks..' x '..buff..' samples'
or device_idx == 4 and (use_asio == '1' and '☑' or '☐')..' Request block size: '..buff
or (device_idx == 5 and 'Buffer' or 'Block')..' size: '..buff..' samples'
return name..'\n\n'..data
end

function Bump_Proj_Change_Cnt() -- API functions seems to not update project change count, most of them anyway
r.Main_OnCommand(41156,0) -- Options: Selecting one grouped item selects group
r.Main_OnCommand(41156,0)
end

-- can be expanded to include MacOS and Linux audio device parameter keys
local parm_t = {
-- audio device parameter keys in reaper.ini, dummy keys are unsupported by the device, will be stored as 0
win = {
	{'ks_bs', 'ks_numblocks', 'dummy'}, -- WDM kernel - 0
	{'dsound_bs', 'dsound_numblocks','dummy'}, -- DirectSound - 1
	{'waveout_bs', 'waveout_numblocks', 'dummy'}, -- WaveOut - 2
	{'asio_bsize', 'dummy', 'asio_bsize_use'}, -- ASIO - 3, asio_bsize_use is 'Request blocksize' checkbox state
	{'dummy_blocksize', 'dummy1', 'dummy2'}, -- DummyAudio - 4
	{'wasapi_bs', 'dummy1', 'dummy2'} -- WASAPI - 5
	},
mac={ {}, {} },
linux={ {}, {} }
}

-- can be expanded to include MacOS and Linux audio device names
local device_name_t = { -- r.GetAudioDeviceInfo() doesn't return some names, could be because those devices aren't properly installed
win={'WDM Kernel Streaming','DirectSound','WaveOut','ASIO','DummyAudio','WASAPI'},
mac={},
linux={}
}

local ret, stored_data = r.GetProjExtState(0, 'AUDIO BUFFER LAST PROPERTIES', 'data')
local proj = tostring(r.EnumProjects(-1)):match(': (.+)')
--local stored_proj = r.GetExtState('AUDIO BUFFER LAST PROPERTIES', 'project') -- unsuitable for detection of newly opened project since REAPER assigns project pointer based on the project tab index, so if the project was closed and then re-opened in a tab with the same index the pointer will be the same
local ignore = #r.GetExtState('AUDIO BUFFER LAST PROPERTIES', 'ignore') > 0
local project_change_cnt = r.GetProjectStateChangeCount(0)


local audioconfig
	for line in io.lines(r.get_ini_file()) do -- extract [audioconfig] section
		if line == '[audioconfig]' then audioconfig = ''
		elseif audioconfig and line:match('%[.+%]') -- new section
		then break -- if end of file the loop will exit naturally
		elseif audioconfig then
		audioconfig = audioconfig..'\n'..line
		end
	end


local device_idx = audioconfig:match('mode=(%d)')
local parm_t = parm_t[OS][device_idx+1] -- select device properties nested table, device index is 0-based hence +1
	for idx, key in ipairs(parm_t) do -- store current values
	parm_t[idx] = audioconfig:match(key) and audioconfig:match(key..'=(%d+)') or '0'
	end
local data = device_idx..':'..table.concat(parm_t,':') -- format is 'device idx:buffer size:num of blocks:use ASIO buffer size', device index is 0-based, parameters unsupported by the device will be 0

	if ret == 0 -- never stored
	or ret == 1 and not ignore and project_change_cnt > 2 -- project has been opened for some time and change count has increased and user didn't cancel the dialogue on start to prevent updating project extended state data already stored (ignore)
	then -- store
	r.SetProjExtState(0, 'AUDIO BUFFER LAST PROPERTIES', 'data', data)
	elseif ret == 1 and project_change_cnt <= 2 -- project has just been opened, if the recommended 'open project' custom action is used, immediately after project loading the change count will be 2
	then
	r.DeleteExtState('AUDIO BUFFER LAST PROPERTIES', 'ignore', true) -- persist true // in case the project was closed and re-peopened without quitting REAPER, because until REAPER is quit 'ignore' command will remain in the memory and will keep preventing to update the extended project data
	local dev_idx, buff, blocks, use_asio = stored_data:match('(%d+):(%d+):(%d+):(%d+)')
	local differs = dev_idx ~= device_idx or dev_idx == device_idx and (buff ~= parm_t[1] or blocks ~= parm_t[2] or use_asio ~= parm_t[3])
		if differs then
		local stored = 'LAST USED: '..Display_Data(OS, device_name_t, dev_idx, buff, blocks, use_asio)
		local current = 'CURRENT: '..Display_Data(OS, device_name_t, device_idx, parm_t[1], parm_t[2], parm_t[3])
		local lb = '\n\n'
		local asterisks = ('*'):rep(45)
		local mess = stored..lb..current..lb..'YES — update project data with current settings\n\nNO  — open Audio device preferences to adjust\n\nCancel — Keep stored settings for the rest of the session\n\n'..asterisks..'\n\nSelection of YES or NO will allow project data be updated\n\nwith new audio device settings on Save with a custom\n\naction recommended in the script instructions.'
		local resp = r.MB(mess, 'Audio device settings difference', 3)
			if resp == 6 then
			r.SetProjExtState(0, 'AUDIO BUFFER LAST PROPERTIES', 'data', data)
			r.MarkProjectDirty(0)
			elseif resp == 7 then
			r.Main_OnCommand(40099, 0) -- Open audio device preferences // or r.ViewPrefs(0x076, ''), source: cfillion_Open preferences page.lua, but these numbers may change between builds
			r.MarkProjectDirty(0)
			else
			r.SetExtState('AUDIO BUFFER LAST PROPERTIES', 'ignore', '+', false) -- will make sure that the data stored as extened project state last time isn't updated when the project is saved under new audio device settings
			end
		end
	Bump_Proj_Change_Cnt() -- bump project change count to prevent re-triggering the dialogue
	end


do return r.defer(no_undo) end






