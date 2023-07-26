--[[
ReaScript name: Move selected notes to a new MIDI item
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
Screensot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20notes%20to%20a%20new%20MIDI%20item.gif
About:	Does what the name suggests.   
        Select the notes to be moved, select the item, run. One item at a time.  
        The MIDI Editor can be open at the time of the execution.  
        The new MIDI item length will be equal to the original item
        regardless of the note selection length. The item will be placed
	on a new track beneath the original item.  
	
	Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Move%20selected%20notes%20to%20a%20new%20MIDI%20item.gif
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
--r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

local item = r.GetSelectedMediaItem(0,0)

	if not item then
	Error_Tooltip(' \n\n no selected item \n\n ')
	return r.defer(function() do return end end) end

ACT(40698,false) -- Edit: Copy items

r.PreventUIRefresh(1)

ACT(40153,false) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)
local noteidx = -1
	repeat
	noteidx = r.MIDI_EnumSelNotes(take, noteidx)
		if noteidx > 0 then break end -- at least 1 sel note
	until noteidx == -1

	if noteidx == -1 then
	Error_Tooltip(' \n\n no selected notes \n\n ')
	ACT(2,true) -- File: Close window
	return r.defer(function() do return end end) end

r.Undo_BeginBlock()

ACT(40002,true) -- Edit: Delete notes
ACT(2,true) -- File: Close window

local item_tr = r.GetMediaItemTrack(item)
local tr_idx = r.CSurf_TrackToID(item_tr, false) -- mcpView false // 1-based index
r.InsertTrackAtIndex(tr_idx, true) -- wantDefaults true
r.SetOnlyTrackSelected(r.GetTrack(0,tr_idx)) -- select the newly inserted track
local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
r.SetEditCurPos(pos, false, false) -- moveview, seekplay false
ACT(42398,false) -- Item: Paste items/tracks
ACT(40153,false) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
ACT(40501,true) -- Invert selection
ACT(40002,true) -- Edit: Delete notes
ACT(40214,true) -- Edit: Unselect all
ACT(2,true) -- File: Close window

r.Undo_EndBlock('Move selected notes to a new MIDI item', -1)
r.PreventUIRefresh(-1)
