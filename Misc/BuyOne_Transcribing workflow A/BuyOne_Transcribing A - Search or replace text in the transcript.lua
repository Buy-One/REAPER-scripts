--[[
ReaScript name: BuyOne_Transcribing A - Search or replace text in the transcript.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.7
Changelog: 1.7 	#Imroved capture of replacement mode code
		#Improved handling of invalid replacement mode code
	   1.6 	#Fixed headless mode
		#Updated replacement functionality description in the 'About' text
		#Made search circular within the notes of the only track
		#Updated search functionality description in the 'About' text
		#Fixed calculation of the match location for highlighting 
		when there're more than one within the same line
		#Ensured that in word by word replacement mode (code 2) replacements
		continue only until all matches have been replaced
	   1.5 	#Added text replacement functionality
		#Renamed the script to reflect the new feature
		#Updated 'About' text
	   1.4	#Fixed search match highlihgting in notes which were copied and pasted from another window
	   1.3	#Updated headless search mode description in the About text
	   1.2	#Fixed endless loop when calling the search dialogue while the SWS Notes window 
		is open without any track being selected
		#Fixed 'Match case' setting
		#Added scrolling selected track into view on Notes window opening or refreshing in all scenarios
	   1.1 	#Cleaned up code
		#Added search settings explanation to the About text
		#Optimized search in non-ASCII texts
Licence: WTFPL
REAPER: at least v5.962; recommended 7.03 and newer
Extensions: SWS/S&M build 2.14.03 and later mandatory; js_ReaScriptAPI is recommended, especially if SWS build is older				
About:	The script is part of the Transcribing A workflow set of scripts
	alongside  
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua   
	BuyOne_Transcribing A - Real time preview.lua  
	BuyOne_Transcribing A - Format converter.lua  
	BuyOne_Transcribing A - Import SRT or VTT file as markers and SWS track Notes.lua  
	BuyOne_Transcribing A - Prepare transcript for rendering.lua   
	BuyOne_Transcribing A - Select Notes track based on marker at edit cursor.lua  
	BuyOne_Transcribing A - Go to segment marker.lua  
	BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua  
	BuyOne_Transcribing A - Offset position of markers in time selection by specified amount.lua
	
	Meant to search transcript created with the script  
	BuyOne_Transcribing A - Create and manage segments (MAIN).lua
	or replace text in it.
	
	► SEARCH
	
	The search starts from the first selected track whose Notes 
	contain the transcript, if there're several such tracks.
	If no track is selected or no transcript track is selected
	the search starts from the 1st track whose Notes contain 
	the transcript if there're several such tracks.  
	Within the transcript the search starts from the line where 
	the cursor (caret) was located most recently and if the 
	search term was found and the search continues it will resume
	from the location on the line immediately following the found 
	match. Running search in headless mode (see below) allows 
	retreating or advancing search within the Notes window by 
	clicking above or below the line of the latest search match.  
	If the SWS Notes window isn't open before the script is executed
	the script will open it and in this case the search will start 
	from the 1st line of the transcript displayed in the opened 
	Notes window.  			
	Once a search match is found the search dialogue is reloaded 
	with fields already filled out with the last search settings. 
	To continue the search press OK button.  
	The search is curcular, after parsing the transcript part stored
	in the notes of last Notes track it loops back to the 1st
	Notes track, or, if there's a single track, after reaching end
	of its Notes it loops back to its start.
	
	In order to enable the search settings 'Match case' and
	'Match exact word' insert any character in the corresponding
	field.			
	
	The Notes window is scrolled towards the line containing the 
	search match if there's enough scrolling space. The match itself 
	is also highlighted within the line, however due to the fact that 
	the search dialogue is a modal window it assumes absolute focus 
	as long as it's open therefore the text highlighting inside the 
	Notes window isn't visible.  
	To overcome this shortcoming a headless search mode has been devised.
	To use it:  
	1. Arm the script. For example from the 'Transcribing A' toolbar button
	(see script BuyOne_Transcribing A - Generate Transcribing A toolbar ReaperMenu file.lua)  
	Arming must be done before running the script because being modal
	search dialogue will prevent interaction with other windows as long
	as it stays open.  
	2. Run it by clicking anywhere over the Arrange view canvas as long
	as the letter 'A' is displayed next to the mouse cursor signifying
	script's armed state.  
	2A If this is the first search during session in which case there're
	no search settings in the buffer, the search dialogue will pop up.
		I. When it does, fill out search settings and click OK.  
		II. Continue the search with the latest search setting by clicking on 
		the Arrange view canvas. The dialogue won't be reloaded because of 
		the script's armed state.  
	2B If the latest search settings have already been stored in the buffer
	which they have if the search was excuted at least once, the seatch will 
	continue.  
	3. To access the search dialogue again unarm the script and run it 
	as normal. 
	
	SWS/S&M extension provides Find utility which also allows searching 
	track notes however it doesn't make the Notes window scroll to bring 
	the search match into view nor does it highlight the found match. 
	It's also only does non-circular search.
	
	If the REAPER build you're using is older than 7.03, then running 
	search with this script you're likely to encounter 'ReaScript task control' 
	dialogue pop up. Once it does, checkmark 'Remember my answer for 
	this script' checkbox and press 'New instance' button, this will 
	prevent the pop up from appearing in the future.
	
	► REPLACEMENT
	
	There're 3 replacement modes: 
	0 - batch replacement in the Notes of all tracks containing the transcript, 
	which can be several if the transcript exceeds 65,535 bytes.  
	1 - batch replacement in the only or the first selected track containing 
	the transcript  
	2 - replacement word by word
	
	To activate a mode, type a digit which represents it above in the 
	'Enable replacement' field of the search dialogue.  
	All other fields relevant to search are also relevant to replacement.
	
	When track notes displayed in the Notes window are updated in modes 0 and 1, 
	the window scroll position is reset, therefore it's advised to have
	js_ReaScriptAPI extension installed which will allow restoration of the
	Notes window scroll position in such cases.

	Since modes 0 and 1 could be resource intensive REAPER may freeze
	for a number of seconds while the replacements are being made.  
	In mode 2 replacement is circular like the search until all matches 
	have been found and replaced.  
	In all 3 replacement modes if replacement is attempted on a long 
	transcript where all matches have been replaced or when the transcript 
	contains no matches or the distance between them is significant, REAPER 
	may freeze for a number of seconds until the script will have parsed 
	the entire transcript.
	
	The 'Enable replacement' setting is not stored between script launches 
	for safety reasons to prevent inadvertent replacement, even though the 
	rest of the settings are kept.

	Headless mode is not supported in replacement functionality. If after
	exiting the search dialogue the script is armed and executed again
	the search will be performed.
	
	Of course replacements in the transctipt can also be made outside 
	of REAPER and the SWS Notes window with any 3d party software.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes insert the name of track(s)
-- where Notes with the transcript are stored;
-- must match the same setting in the script
-- 'BuyOne_Transcribing A - Create and manage segments (MAIN).lua';
-- CHANGING THIS SETTING MIDPROJECT IS NOT RECOMMENDED
-- BECAUSE SCRIPT ACCESS TO THE NOTES TRACKS WILL BE LOST
NOTES_TRACK_NAME = "TRANSCRIPT"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


local Debug = ""
function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
	if #Debug:gsub(' ','') > 0 then -- declared outside of the function, allows to only didplay output when true without the need to comment the function out when not needed, borrowed from spk77
	reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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


function is_utf8(str)
-- capturing trailing (continuation bytes)
-- returns a string (likely empty) if true and nil if false
return str:match('[\128-\191]')
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


function SWS_Version_Check(ver, older, newer, same)
-- ver is a string contaning a version number
-- to compare current version againts
-- the rest are booleans which are comparison criteria
-- obviously older and newer are mutually exclusive
-- and option 'older' has priority if both are true
-- same is compatible with both and complementary
-- or can be used by itself
	if r.CF_GetSWSVersion then -- accounting for versions before this function was available
	-- https://forums.cockos.com/showthread.php?p=2026809 2.9.8
	-- remove all dots so it looks like an integer and convert to number
	local ver = ver:gsub('%.','')+0
	local curr_ver = r.CF_GetSWSVersion():gsub('%.','')+0
	local result = older and curr_ver < ver or not older and newer and curr_ver > ver -- 'not older' ensures that when both older and newer args are true the function doesn't return truth if first evaluaton fails because not older
	return result or same and curr_ver == ver
	end
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end



function convert_case_in_unicode(str, want_upper_case)
-- by default converts to lower case
-- want_case is boolean to convert to upper case
-- if false/nil convertion into lower will be done
-- https://stackoverflow.com/questions/41855842/converting-utf-8-string-to-ascii-in-pure-lua/41859181#41859181
-- https://stackoverflow.com/questions/13235091/extract-the-first-letter-of-a-utf-8-string-with-lua
-- https://www.ibm.com/docs/en/i/7.3?topic=tables-unicode-lowercase-uppercase-conversion-mapping-table -- this is only a list of ordinal number correspondence within the table, such as at https://www.charset.org/utf-8, not actual code point values
-- https://stackoverflow.com/questions/29966782/how-to-embed-hex-values-in-a-lua-string-literal-i-e-x-equivalent

-- t table below contains Unicode code points, i.e. U+codepoint in base 10 rather than hex for brevity
-- code points reference table see at https://www.charset.org/utf-8
-- fields order: upper case, lower case
local t = {
-- the commented out code is basic latin code points which are supported by the stock lua string lib so redundant
-- {65,97}, {66,98}, {67,99}, {68,100}, {69,101}, {70,102}, {71,103}, {72,104}, {73,105}, {74,106}, {75,107}, {76,108}, {77,109}, {78,110}, {79,111}, {80,112},
{81,113},{82,114},{83,115},{84,116},{85,117},{86,118},{87,119},{88,120},{89,121},{90,122},{192,224},{193,225},{194,226},{195,227},{196,228},{197,229},{198,230},{199,231},{200,232},{201,233},{202,234},{203,235},{204,236},{205,237},{206,238},{207,239},{208,240},{209,241},{210,242},{211,243},{212,244},{213,245},{214,246},{216,248},{217,249},{218,250},{219,251},{220,252},{221,253},{222,254},{376,255},{256,257},{258,259},{260,261},{262,263},{264,265},{266,267},{268,269},{270,271},{272,273},{274,275},{276,277},{278,279},{280,281},{282,283},{284,285},{286,287},{288,289},{290,291},{292,293},{294,295},{296,297},{298,299},{300,301},{302,303},{73,305},{306,307},{308,309},{310,311},{313,314},{315,316},{317,318},{319,320},{321,322},{323,324},{325,326},{327,328},{330,331},{332,333},{334,335},{336,337},{338,339},{340,341},{342,343},{344,345},{346,347},{348,349},{350,351},{352,353},{354,355},{356,357},{358,359},{360,361},{362,363},{364,365},{366,367},{368,369},{370,371},{372,373},{374,375},{377,378},{379,380},{381,382},{386,387},{388,389},{391,392},{395,396},{401,402},{408,409},{416,417},{418,419},{420,421},{423,424},{428,429},{431,432},{435,436},{437,438},{440,441},{444,445},{452,454},{455,457},{458,460},{461,462},{463,464},{465,466},{467,468},{469,470},{471,472},{473,474},{475,476},{478,479},{480,481},{482,483},{484,485},{486,487},{488,489},{490,491},{492,493},{494,495},{497,499},{500,501},{506,507},{508,509},{510,511},{512,513},{514,515},{516,517},{518,519},{520,521},{522,523},{524,525},{526,527},{528,529},{530,531},{532,533},{534,535},{385,595},{390,596},{394,599},{398,600},{399,601},{400,603},{403,608},{404,611},{407,616},{406,617},{412,623},{413,626},{415,629},{425,643},{430,648},{433,650},{434,651},{439,658},{902,940},{904,941},{905,942},{906,943},{913,945},{914,946},{915,947},{916,948},{917,949},{918,950},{919,951},{920,952},{921,953},{922,954},{923,955},{924,956},{925,957},{926,958},{927,959},{928,960},{929,961},{931,963},{932,964},{933,965},{934,966},{935,967},{936,968},{937,969},{938,970},{939,971},{908,972},{910,973},{911,974},{994,995},{996,997},{998,999},{1000,1001},{1002,1003},{1004,1005},{1006,1007},{1040,1072},{1041,1073},{1042,1074},{1043,1075},{1044,1076},{1045,1077},{1046,1078},{1047,1079},{1048,1080},{1049,1081},{1050,1082},{1051,1083},{1052,1084},{1053,1085},{1054,1086},{1055,1087},{1056,1088},{1057,1089},{1058,1090},{1059,1091},{1060,1092},{1061,1093},{1062,1094},{1063,1095},{1064,1096},{1065,1097},{1066,1098},{1067,1099},{1068,1100},{1069,1101},{1070,1102},{1071,1103},{1025,1105},{1026,1106},{1027,1107},{1028,1108},{1029,1109},{1030,1110},{1031,1111},{1032,1112},{1033,1113},{1034,1114},{1035,1115},{1036,1116},{1038,1118},{1039,1119},{1120,1121},{1122,1123},{1124,1125},{1126,1127},{1128,1129},{1130,1131},{1132,1133},{1134,1135},{1136,1137},{1138,1139},{1140,1141},{1142,1143},{1144,1145},{1146,1147},{1148,1149},{1150,1151},{1152,1153},{1168,1169},{1170,1171},{1172,1173},{1174,1175},{1176,1177},{1178,1179},{1180,1181},{1182,1183},{1184,1185},{1186,1187},{1188,1189},{1190,1191},{1192,1193},{1194,1195},{1196,1197},{1198,1199},{1200,1201},{1202,1203},{1204,1205},{1206,1207},{1208,1209},{1210,1211},{1212,1213},{1214,1215},{1217,1218},{1219,1220},{1223,1224},{1227,1228},{1232,1233},{1234,1235},{1236,1237},{1238,1239},{1240,1241},{1242,1243},{1244,1245},{1246,1247},{1248,1249},{1250,1251},{1252,1253},{1254,1255},{1256,1257},{1258,1259},{1262,1263},{1264,1265},{1266,1267},{1268,1269},{1272,1273},{1329,1377},{1330,1378},{1331,1379},{1332,1380},{1333,1381},{1334,1382},{1335,1383},{1336,1384},{1337,1385},{1338,1386},{1339,1387},{1340,1388},{1341,1389},{1342,1390},{1343,1391},{1344,1392},{1345,1393},{1346,1394},{1347,1395},{1348,1396},{1349,1397},{1350,1398},{1351,1399},{1352,1400},{1353,1401},{1354,1402},{1355,1403},{1356,1404},{1357,1405},{1358,1406},{1359,1407},{1360,1408},{1361,1409},{1362,1410},{1363,1411},{1364,1412},{1365,1413},{1366,1414},{4256,4304},{4257,4305},{4258,4306},{4259,4307},{4260,4308},{4261,4309},{4262,4310},{4263,4311},{4264,4312},{4265,4313},{4266,4314},{4267,4315},{4268,4316},{4269,4317},{4270,4318},{4271,4319},{4272,4320},{4273,4321},{4274,4322},{4275,4323},{4276,4324},{4277,4325},{4278,4326},{4279,4327},{4280,4328},{4281,4329},{4282,4330},{4283,4331},{4284,4332},{4285,4333},{4286,4334},{4287,4335},{4288,4336},{4289,4337},{4290,4338},{4291,4339},{4292,4340},{4293,4341},{7680,7681},{7682,7683},{7684,7685},{7686,7687},{7688,7689},{7690,7691},{7692,7693},{7694,7695},{7696,7697},{7698,7699},{7700,7701},{7702,7703},{7704,7705},{7706,7707},{7708,7709},{7710,7711},{7712,7713},{7714,7715},{7716,7717},{7718,7719},{7720,7721},{7722,7723},{7724,7725},{7726,7727},{7728,7729},{7730,7731},{7732,7733},{7734,7735},{7736,7737},{7738,7739},{7740,7741},{7742,7743},{7744,7745},{7746,7747},{7748,7749},{7750,7751},{7752,7753},{7754,7755},{7756,7757},{7758,7759},{7760,7761},{7762,7763},{7764,7765},{7766,7767},{7768,7769},{7770,7771},{7772,7773},{7774,7775},{7776,7777},{7778,7779},{7780,7781},{7782,7783},{7784,7785},{7786,7787},{7788,7789},{7790,7791},{7792,7793},{7794,7795},{7796,7797},{7798,7799},{7800,7801},{7802,7803},{7804,7805},{7806,7807},{7808,7809},{7810,7811},{7812,7813},{7814,7815},{7816,7817},{7818,7819},{7820,7821},{7822,7823},{7824,7825},{7826,7827},{7828,7829},{7840,7841},{7842,7843},{7844,7845},{7846,7847},{7848,7849},{7850,7851},{7852,7853},{7854,7855},{7856,7857},{7858,7859},{7860,7861},{7862,7863},{7864,7865},{7866,7867},{7868,7869},{7870,7871},{7872,7873},{7874,7875},{7876,7877},{7878,7879},{7880,7881},{7882,7883},{7884,7885},{7886,7887},{7888,7889},{7890,7891},{7892,7893},{7894,7895},{7896,7897},{7898,7899},{7900,7901},{7902,7903},{7904,7905},{7906,7907},{7908,7909},{7910,7911},{7912,7913},{7914,7915},{7916,7917},{7918,7919},{7920,7921},{7922,7923},{7924,7925},{7926,7927},{7928,7929},{7944,7936},{7945,7937},{7946,7938},{7947,7939},{7948,7940},{7949,7941},{7950,7942},{7951,7943},{7960,7952},{7961,7953},{7962,7954},{7963,7955},{7964,7956},{7965,7957},{7976,7968},{7977,7969},{7978,7970},{7979,7971},{7980,7972},{7981,7973},{7982,7974},{7983,7975},{7992,7984},{7993,7985},{7994,7986},{7995,7987},{7996,7988},{7997,7989},{7998,7990},{7999,7991},{8008,8000},{8009,8001},{8010,8002},{8011,8003},{8012,8004},{8013,8005},{8025,8017},{8027,8019},{8029,8021},{8031,8023},{8040,8032},{8041,8033},{8042,8034},{8043,8035},{8044,8036},{8045,8037},{8046,8038},{8047,8039},{8072,8064},{8073,8065},{8074,8066},{8075,8067},{8076,8068},{8077,8069},{8078,8070},{8079,8071},{8088,8080},{8089,8081},{8090,8082},{8091,8083},{8092,8084},{8093,8085},{8094,8086},{8095,8087},{8104,8096},{8105,8097},{8106,8098},{8107,8099},{8108,8100},{8109,8101},{8110,8102},{8111,8103},{8120,8112},{8121,8113},{8152,8144},{8153,8145},{8168,8160},{8169,8161},{9398,9424},{9399,9425},{9400,9426},{9401,9427},{9402,9428},{9403,9429},{9404,9430},{9405,9431},{9406,9432},{9407,9433},{9408,9434},{9409,9435},{9410,9436},{9411,9437},{9412,9438},{9413,9439},{9414,9440},{9415,9441},{9416,9442},{9417,9443},{9418,9444},{9419,9445},{9420,9446},{9421,9447},{9422,9448},{9423,9449},{65313,65345},{65314,65346},{65315,65347},{65316,65348},{65317,65349},{65318,65350},{65319,65351},{65320,65352},{65321,65353},{65322,65354},{65323,65355},{65324,65356},{65325,65357},{65326,65358},{65327,65359},{65328,65360},{65329,65361},{65330,65362},{65331,65363},{65332,65364},{65333,65365},{65334,65366},{65335,65367},{65336,65368},{65337,65369},{65338,65370}
}

	local function unicode_to_utf8(code)
	-- credit belongs to Egor Skripunoff
	-- https://stackoverflow.com/questions/41855842/converting-utf-8-string-to-ascii-in-pure-lua/41859181#41859181
	-- converts numeric UTF code (U+code) to UTF-8 string, i.e. actual character
	-- code arg is a hex number, i.e. 0x0000 or integer in base 10
	-- from the UTF-8 code page 2nd or 1st columns here https://www.charset.org/utf-8
	local t, h = {}, 128
		while code >= h do
			t[#t+1] = 128 + code%64
			code = math.floor(code/64)
			h = h > 32 and 32 or h/2
		end
	t[#t+1] = 256 - 2*h + code
	return string.char(table.unpack(t)):reverse()
	end

	for _, pair in ipairs(t) do
	local cap, small = pair[1], pair[2]
	local what = want_upper_case and small or cap
	local with = want_upper_case and cap or small
	what = unicode_to_utf8(what)
		if str:match(what) then
		with = unicode_to_utf8(with)
		-- replace one case character instances with their other case instances
		-- doing that 1 by 1, one character per repeat loop cycle
		-- which is supposedly safer and more reliable especially when
		-- str is long because string.gsub only supports a max of 32 replacements
		local i = 1
			repeat
			str, cnt = str:gsub(what, with, 1) -- 1 instance only
			i = i+1
			until cnt == 0 -- until no more replacaments
		end
	end

return str

end



function GetUserInputs_Alt(title, field_cnt, field_names, field_cont, separator, comment_field, comment)
-- title string, field_cnt integer, field_names string comma delimited
-- the length of field names list should obviously match field_cnt arg
-- it's more reliable to contruct a table of names and pass the two vars field_cnt and field_names as #t, t
-- field_cont is empty string unless they must be initially filled
-- to fill out only specific fields precede them with as many separator characters
-- as the number of fields which must stay empty
-- in which case it's a separator delimited list e.g.
-- ,,field 3,,field 5
-- separator is a string, character which delimits the fields
-- MULTIPLE CHARACTERS CANNOT BE USED AS FIELD SEPARATOR, FIELD NAMES LIST OR ITS FORMATTING BREAKS
-- comment_field is boolean, comment is string to be displayed in the comment field
-- extrawidth parameter is inside the function

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
field_names = field_names:gsub(', ', ',') -- if there's space after comma, remove because with multiple fields the names will not line up vertically
local sep = separator or ','
local field_cont = add_separators(field_cnt, field_cont, sep)
local comment = comment_field and type(comment) == 'string' and #comment > 0 and comment or ''
local field_cnt = comment_field and #comment > 0 and field_cnt+1 or field_cnt
field_names = comment_field and #comment > 0 and field_names..',Comment:' or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = separator and ',separator='..separator or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=180'..separator, field_cont)
output = #comment > 0 and output:match('(.+'..sep..')') or output -- exclude comment field keeping separator to simplify captures in the loop below
field_cnt = #comment > 0 and field_cnt-1 or field_cnt -- adjust for the next statement
	if not ret or (field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0) then return end
	--[[ OR
	-- to condition action by the type of the button pressed
	if not ret then return 'cancel'
	elseif field_cnt > 1 and output:gsub('[%s%c]','') == (sep):rep(field_cnt-1)
	or #output:gsub('[%s%c]','') == 0 then return 'empty' end
	]]
-- construct table out of input fields
local t = {}
	for s in output:gmatch('(.-)'..sep) do
		if s then t[#t+1] = s end
	end
	if #comment == 0 then
	-- if the last field isn't comment,
	-- add it to the table because due to lack of separator at its end
	-- it wasn't caught in the above loop
	t[#t+1] = output:match('.+'..sep..'(.*)')
	end
-- return fields content in a table and as a string to refill the dialogue on reload
return t, #comment > 0 and output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it
end


function validate_output(str)
return #str:gsub('[%c%s]','') > 0
end



function Find_Window_SWS(wnd_name, want_main_children)
-- finds main window children, their siblings, their grandchildren and their siblings, including docked ones, floating windows and probably their children as well
-- want_main_children is boolean to search for internal or non-dockable main window children and for their children regardless of the dock being open, the dock condition in the routine is only useful for validating visibility of windows which can be docked

-- 1. search windows with BR_Win32_FindWindowEx(), including docked
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindowtexta#return-value
-- 2. search floating docker with BR_Win32_FindWindowEx() using 2 title options, and loop to find children and siblings
-- 3. search dockers attached to the main window with r.GetMainHwnd() and loop to find children and siblings

	local function Find_Win(title)
	return r.BR_Win32_FindWindowEx('0', '0', '', title, false, true) -- hwndParent, hwndChildAfter '0', className empty string, searchClass false, searchName true // does find single windows and single windows docked in floating dockers with '(docked)' appendage in the title, doesn't find children windows, such as docked in multi-tab docks and single docked in dockers attached to the main window, hence the actual function Find_Window_SWS()
	end

	local function get_wnd_siblings(hwnd, val, wnd_name)
	-- val = 2 next; 3 prev doesn't work if hwnd belongs
	-- to the very 1st child returned by BR_Win32_GetWindow() with val 5, which seems to always be the case
	local Get_Win = r.BR_Win32_GetWindow
	-- evaluate found window
	local ret, tit = r.BR_Win32_GetWindowText(hwnd)
		if tit == wnd_name then return hwnd
		elseif tit == 'REAPER_dock' then -- search children of the found window
		-- dock windows attached to the main window have 'REAPER_dock' title and can have many children, each of which is a sibling to others, if nothing is attached the child name is 'Custom1', 15 'REAPER_dock' windows are siblings to each other
		local child = Get_Win(hwnd, 5) -- get child 5, GW_CHILD
		local hwnd = get_wnd_siblings(child, val, wnd_name) -- recursive search for child siblings
			if hwnd then return hwnd end
		end
	local sibl = Get_Win(hwnd, 2) -- get next sibling 2, GW_HWNDNEXT
		if sibl then return get_wnd_siblings(sibl, val, wnd_name) -- proceed with recursive search for dock siblings and their children
		else return end
	end

	local function search_floating_docker(docker_hwnd, docker_open, wnd_name) -- docker_hwnd is docker window handle, docker_open is boolean, wnd_name is a string of the sought window name
		if docker_hwnd and docker_open then -- windows can be found in closed dockers hence toggle state evaluation
	-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
		local child = r.BR_Win32_GetWindow(docker_hwnd, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
		local ret, tit = r.BR_Win32_GetWindowText(child) -- floating docker window 1st child name is 'REAPER_dock', attached windows are 'REAPER_dock' child and/or the child's siblings
		return get_wnd_siblings(child, 2, wnd_name) -- go recursive enumerating child siblings; sibling 2 (next) - GW_HWNDNEXT, 3 (previous) - GW_HWNDPREV, 3 doesn't seem to work regardless of the 1st child position in the docker, probably because BR_Win32_GetWindow with val 5 always retrieves the very 1st child, so all the rest are next
		end
	end

-- search for floating window
-- won't be found if closed
local wnd = Find_Win(wnd_name)

	if wnd then return wnd end -- if not found the function will continue

-- docker toggle states are used for visibility validation instead of extension functions due to unreliabiliy of the latter which return false in multi-window docker scenarios when a window is inactive
local tb_dock = r.GetToggleCommandStateEx(0, 41084) == 1 -- 'Toolbar: Show/hide toolbar docker' // non-toolbar windows can be attached to a floating toolbar docker as well
local dock = r.GetToggleCommandStateEx(0, 40279) == 1 -- 'View: Show docker'

-- search for a floating docker with one attached window
local docker = Find_Win(wnd_name..' (docked)') -- when a single window is attached to a floating docker its title is 'Name (docked)' with '(docked)' added regardless of whether this a regular docker or a toolbar docker
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd and (r.JS_Window_IsVisible and r.JS_Window_IsVisible(wnd) or dock) then return wnd -- JS_Window_IsVisible() isn't suitable for multi-window dockers because it returns false when a window is inactive, but it works reliably when floating docker only has one attached window which cannot be inactive
	end -- if not found the function will continue

-- search toolbar docker with multiple attached windows which can house regular windows
docker = Find_Win('Toolbar Docker') -- when toolbars are collected in the floating toolbar docker to begin with and there're more than 1, its title is 'Toolbar Docker', non-toolbar windows can be attached to a floating toolbar docker as well
wnd = search_floating_docker(docker, tb_dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search floating docker with multiple attached windows which can house toolbars
docker = Find_Win('Docker') -- when a docker attached to the main window is detached from it by toggling 'Attach docker to the main window' and there're several windows in it, the floating docker title is 'Docker'
wnd = search_floating_docker(docker, dock, wnd_name)
	if wnd then return wnd end -- if not found the function will continue

-- search docks attached to the main window
	if dock and not want_main_children or want_main_children then -- windows can be found in closed dockers hence toggle state evaluation
	local main = r.GetMainHwnd() -- the name of the dock window is 'REAPER_dock' of which there're 15 all being children of the main window and siblings of each other, attached windows are dock children and are siblings of each other
	local child = r.BR_Win32_GetWindow(main, 5) -- get child 5, GW_CHILD // 1st docker child is the last added window
	return get_wnd_siblings(child, 2, wnd_name)
	end

end


function Get_Child_Windows_SWS(parent_wnd)
-- https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow
-- the function doesn't cover grandchildren
-- once window handles have been collected
-- they can be analyzed further for presence of certain string
-- using BR_Win32_GetWindowText()

	if not parent_wnd then return end

local child = r.BR_Win32_GetWindow(parent_wnd, 5) -- 5 = GW_CHILD, returns 1st child
	if not child then return end -- no children
local i, t = 0, {}
	repeat
		if child then
		local ret, txt = r.BR_Win32_GetWindowText(child)
		t[#t+1] = {child=child, title=txt} -- title field isn't used in this script
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return #t > 0 and t
end



function GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos)

	if not r.JS_Window_Find then return end

	if not scroll_pos then -- Get
	local retval, top_pos, pageSize, min_px, max_px, scroll_pos = r.JS_Window_GetScrollInfo(notes_wnd, 'VERT') -- 'v' vertical scrollbar, or 'SB_VERT', or 'VERT' // the shorter the window the greater the bottomost scroll_pos value
	return scroll_pos
	else -- Set
	r.JS_Window_SetScrollPos(notes_wnd, 'v', scroll_pos) -- 'v' vertical scrollbar, or 'SB_VERT', or 'VERT'
	end

end


function Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local tr_t = {}

	for i = 0, r.GetNumTracks()-1 do
	local tr = r.GetTrack(0,i)
	local retval, name = r.GetTrackName(tr)
	local ret, data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:'..NOTES_TRACK_NAME, '', false) -- setNewValue false
	local index = data:match('^%d+')
		if name:match('^%s*%d+ '..Esc(NOTES_TRACK_NAME)..'%s*$') and tonumber(index) then
		tr_t[#tr_t+1] = {tr=tr, name=name, idx=index}
		end
	end


-- sort the table by integer in the track extended state
table.sort(tr_t, function(a,b) return a.idx+0 < b.idx+0 end)

-- collect Notes from all found tracks
local notes = ''
	for k, t in ipairs(tr_t) do
	notes = notes..(#notes == 0 and '' or '\n')..r.NF_GetSWSTrackNotes(t.tr) -- don't add line break when statring to accrue notes so that they start at the top of the Notes window
	end

return tr_t, notes

end



function Get_SWS_Track_Notes_Caret_Line_Idx(child_wnd_t, tr_t)
-- child_wnd_t is Notes window children table returned by Get_Child_Windows_SWS()
-- tr_t stems from Get_Notes_Tracks_And_Their_Notes()
-- and contains notes tracks data
-- relies on Get_Child_Windows_SWS()
-- https://learn.microsoft.com/en-us/windows/win32/controls/em-lineindex
-- EM_LINEINDEX 0x00BB
-- https://learn.microsoft.com/en-us/windows/win32/controls/em-linefromchar
-- EM_LINEFROMCHAR 0x00C9

-- Search for the first selected notes track to determine where the transcript search must start from

-- tr_t is sorted in ascending order, so first selected track is the one
-- whose Notes must be evaluated, unless it's preceded by an outside track
local tr, tr_idx
	for k, props in ipairs(tr_t) do
		if r.IsTrackSelected(props.tr) and props.tr == r.GetSelectedTrack(0,0) then
		tr, tr_idx = props.tr, k  -- if the first selected notes track is also the first selected in the project use it; idx will be used to determine the track loop start below
		break end
	end


-- when not_found is true because no notes track was selected and 1st notes track is fallen back on,
-- selecting the 1st notes track with SetOnlyTrackSelected() before getting the Notes window children
-- doesn't make the Notes window update fast enough and at this point it's still focused
-- on the outside or no track notes, so what must be evaluated is the Notes
-- of the outside track which is currently selected, if any
local not_found = not tr
tr = tr or r.GetSelectedTrack(0,0) --or tr_t[1].tr -- if no selected notes track was found but there's a selected outside track, use it for track notes state evaluation, in this case the 1st notes track will be subsequently selected for the transcript search

-- Determine the index of the line which holds the caret within the selected track Notes depending on the track notes state
-- and open track notes if necessary by either opening the Notes window or if open by switching it to track notes

	function center_line_equal(str1, str2, cent_line_idx)
	local patt = ('\n.-'):rep(cent_line_idx-1)..'(\n.-)\n' -- -1, i.e. 1 less than the center line index so that the last capture is surely the center line
	-- removing carriage return char \r from both to be sure,
	-- this char is included in the text returned from window
	return str1:gsub('\r',''):match(patt) == str2:gsub('\r',''):match(patt)
	end

local start_line_idx -- index of a caret line inside the notes of tr which transcript search must start or continue from
local open_tr_notesID = r.NamedCommandLookup('_S&M_TRACKNOTES')
local act = r.Main_OnCommand
local child_wnd -- to retrieve non-zero start line index if start_line_idx remains nil
local notes_wnd_open = r.GetToggleCommandStateEx(0, r.NamedCommandLookup('_S&M_SHOW_NOTES_VIEW')) == 1

	if tr and notes_wnd_open then -- notes track is selected and Notes window is open
	local notes = r.NF_GetSWSTrackNotes(tr)
	-- TRACK NOTES RETURNED BY NF_GetSWSTrackNotes() WILL ALMOST NEVER BE DIRECTLY EQUAL TO THOSE RETURNED FROM THE WINDOW
	-- BECAUSE INSIDE WINDOW EACH LINE IS TERMINATED WITH CARRIAGE RETURN \r
	-- BUT EVEN WHEN THEY'RE ALL DELETED THERE'LL STILL BE 1 OR 2 BYTE DIFFERENCE IN THE STRING LENGTH
	-- therefore their equality must be evaluated by other means, such as by evaluating the center line
	local line_cnt = select(2, notes:gsub('\n','')) -- the very 1st line is not counted because it doesn't start with \n
	local cent_line_idx = math.floor((line_cnt+1)/2) -- +1 to count the 1st line as well which isn't preceded with \n char and hence isn't counted in the expression above

	local test_str = 'ISTRACKNOTES' -- the test string is initialized without line break char to be able to successfully find it in the window text because search with the line break char will fail due to carriage return \r being added to the end of the line and thus preceding the line break, i.e. 'ISTRACKNOTES\r\n'
		if #notes:gsub('[%c%s]','') == 0 or center_line_idx == 1 then r.NF_SetSWSTrackNotes(tr, test_str..'\n'..notes) end -- if notes are empty or there's 1 line only add test string so track notes active status can be evaluated, otherwise active non-track empty notes will produce truth as well, manipulating the notes isn't a problem because in this case start_line_idx will be 0 anyway, in other case it would be reset

	local is_active
		-- search for notes in Notes window children windows title
		for k, data in ipairs(child_wnd_t) do
		local ret, txt = r.BR_Win32_GetWindowText(data.child)
			if txt:match('^'..test_str) or center_line_equal(txt, notes, cent_line_idx) -- txt == notes_tmp
			or r.JS_Window_GetTitle -- use js_ReaScriptAPI ext if installed
			and (r.JS_Window_GetTitle(data.child):match('^'..test_str) or center_line_equal(r.JS_Window_GetTitle(data.child), notes, cent_line_idx) ) --r.JS_Window_GetTitle(data.child) == notes_tmp
			then
			is_active = 1
			child_wnd = data.child -- will be used to get caret line index if it's other than 0
			break end
		end

		if r.NF_GetSWSTrackNotes(tr):match('^'..test_str) then -- test string was used to validate empty track notes active status
		r.NF_SetSWSTrackNotes(tr, notes) -- restore original notes without the test string added above
		end

		if not is_active then -- track notes section isn't active in the open Notes window, toggle to open it
	--	r.BR_Win32_ShowWindow(notes_wnd, 0) -- 0 SW_HIDE, hide window -- doesn't close the docker so can't be toggled On with action
		act(open_tr_notesID, 0)
		end
		-- if no selected notes track is found fall back on the very first notes track
		-- and set its index as the transcript search start
		if not_found then
		tr = tr_t[1].tr
		tr_idx = 1
		-- selection isn't necessary here because the final selection target
		-- is determined after search inside Search_Track_Notes()
		r.SetOnlyTrackSelected(tr) -- select the 1st Notes track to ensure that the Notes window is populated with its transcript, although this may not be necessary if the transcript search term will be found in some other notes track
		act(40913,0) -- Track: Vertical scroll selected tracks into view
		r.SetCursorContext(0, r.GetSelectedEnvelope(0)) -- mode 0 TCP // REQUIRED TO GET NOTES WINDOW FOCUS UPDATED WHEN SWITCHING TO THE TRACK AFTER SWITCHING TO TRACK NOTES FROM ANOTHER NOTES WINDOW SECTION
		end
	start_line_idx = not is_active and 0 -- when notes window section is just activated the caret line index is reset to 0 (the topmost line)
	else -- either notes or an outside track is selected OR none is selected and Notes window is either open or closed
		if not_found then
		-- if no selected notes track is found fall back on the very first notes track
		-- and set its index as the transcript search start
		tr = tr_t[1].tr
		tr_idx = 1
		-- selection isn't necessary here because the final selection target
		-- is determined after search inside Search_Track_Notes()
		r.SetOnlyTrackSelected(tr) -- select the 1st Notes track to ensure that the Notes window is populated with its transcript, although this may not be necessary if the transcript search term will be found in some other notes track
		act(40913,0) -- Track: Vertical scroll selected tracks into view
		r.SetCursorContext(0, r.GetSelectedEnvelope(0)) -- mode 0 TCP // REQUIRED TO GET NOTES WINDOW FOCUS UPDATED WHEN SWITCHING TO THE TRACK AFTER SWITCHING TO TRACK NOTES FROM ANOTHER NOTES WINDOW SECTION
		end
		if not notes_wnd_open then -- toggle Notes window open if closed
		act(open_tr_notesID, 0)
		end
	start_line_idx = 0 -- when the notes window is just opened the caret line index is reset to 0 (the topmost line)
	end

	if not start_line_idx then -- OR 'if child_wnd' // caret line index other than 0
	start_line_idx = r.BR_Win32_SendMessage(child_wnd, 0x00C9, -1, 0) -- EM_LINEFROMCHAR 0x00C9, wParam is -1 to get index of the line which holds the caret or the line containing selection start regardless of the Notes window being active/focused; when the Notes are switched between objects by their selection or the Notes window is closed and reopened or another type of notes is selected in the Notes window the caret position is reset to the first line, index 0
	end

return tr_idx, start_line_idx+1, child_wnd -- converting start_line_idx to 1-based count, two first values will be fed into Search_Track_Notes() function, the 3d to Scroll_SWS_Notes_Window()

end



function Replace_In_Track_Notes(replace_mode, tr_t, tr_idx, start_line_idx, search_term, replace_term, cmdID, ignore_case, exact, notes_wnd)
-- tr_idx, start_line_idx are only rekevant for one-by-one replacement mode
-- and stem from Get_SWS_Track_Notes_Caret_Line_Idx()
-- and reprsent index of the notes track in whose notes
-- the transcript search must start and line holding the caret
-- which the search must start from in the track notes;
-- if ignore_case is true first the target word in original case must be found inside the line
-- in order to be able to replace it in the original line
-- searching by changing the line case is a wrong approach
-- because replacement must not affect the original case of all other words
-- and simple case change of the search term during search won't work
-- because this will still miss words with capitalized first letter, i.e. mixed case words;
-- segment time stamps must be excluded from search/replacement


	local function get_replace_term_bounds(st, line, replace_term, exact)
	-- used inside replace_capture()
	-- to exclude unicode extra bytes before and within capture
	-- so that 1 character corresponds to 1 byte because text highliting inside Scroll_SWS_Notes_Window() is based on characters
	local st, fin = line:find(Esc(replace_term), st)
	local pre_capt_extra = select(2, line:sub(1,st-1):gsub('[\128-\191]',''))
	local capt_extra = select(2, replace_term:gsub('[\128-\191]',''))
	-- to exclude padding characters when searching exact match
	-- to exclude padding characters when searching exact match
	-- because padding characters are included in the capture start and end values despite being outside of it
	return st - pre_capt_extra, fin, fin - pre_capt_extra - capt_extra -- returning both original byte based fin value and adjusted character based one, the first is for storage as 'LAST SEARCH' data, the second is for text highlighting inside Scroll_SWS_Notes_Window()
	end

	local function get_capture(line, search_term, ignore_case, exact, fin, rerun)
	-- used inside replace_capture()
	-- using string.find to extract original target term from the original line with st and end index
	-- in case ignore_case is true, because simple extraction by lowering the case won't work for replacement
	-- since it's the original word which must be replaced, not the one retrieved after changing case;
	-- when ignore_case is true, the match wasn't found and the notes or the search term contain non-ASCII characters
	-- rerun will be true to condition recursive run of the parent function replace_capture()
	-- to try to find match after converting non-ASCII characters to lower case
	-- beause string.lower() ignores these which is likely to result in negative outcome with non-ASCII characters
	local s = not exact and Esc(search_term) or search_term -- if exact, search_term arg is a pattern, not the original search term therefore it must not be escaped to avoid pattern corruption, otherwise special chars will be treated as literals, the search term is escaped by itself in the parent function replace_capture()
	s = ignore_case and (rerun and convert_case_in_unicode(s) or s:lower()) or s
	local line_tmp = ignore_case and (rerun and convert_case_in_unicode(line) or line:lower()) or line -- using a line copy to be able to use the original to extract the original match from below
	local st_idx = fin or 1 -- fin ensures that the search continues from where it had left off to prevent endless loop inside parent function replace_capture() when search and replacement terms only differ in case because if ignore_case is true string.find will get stuck at the first replacement keeping returning valid capture endlessly
	local st, fin = line_tmp:find(s, st_idx)
		if st then
		return line:sub(st, fin), st, fin, line_tmp:sub(st, fin) -- st is only needed in one-by-one mode; last return value is only relevant when exact and ignore_case are true
		end
	end

	local function replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, rerun)
	-- used inside search_and_replace()
	-- rerun is boolean to condition recursive run once when ignore_case is true but no replacement was done
	-- because no match was found due to search_term or notes contaning non-ASCII characters ignored by string.lower()
	-- in order to terty after converting non-ASCII characters to lower case

	local timestamp, transcr = line:match('(.+%d+:%d+:%d+%.%d+)(.+)') -- split off segment time stamp to exclude it from search and replacement // ONLY RELEVANT FOR TRANSCRIBING SCRIPTS WHERE THERE'S TIME STAMP IN THE TEXT
	local transcr = transcr or line -- keeping original line to be able to pass it into the recursive instance of the function
	local replace_term = replace_term:gsub('%%','%%%%') -- must be escaped if contains % which is unlikley but just in case
	local fin, replace_cnt = pos_in_line, 0 -- pos_in_line (assigned to fin var) will be valid in one-by-one mode, fin is needed in one-by-one mode or otherwise to prevent search from getting stuck, see comment below
	fin = timestamp and fin > #timestamp and fin - #timestamp or fin -- subtract length of timestamp portion from fin value so that it's counted from the beginning of the segment transcript because when fin is returned and stored in 'LAST SEARCH' data it's counted from the actual line start which includes the time stamp // ONLY RELEVANT FOR TRANSCRIBING SCRIPTS WHERE THERE'S TIME STAMP IN THE TEXT
	local capt, st, count

		if not exact then
		capt, st, fin = get_capture(transcr, search_term, ignore_case, exact, fin, rerun) -- fin is returned to be passed as new start index inside string.find because if the search and replacement terms only differ in case while ignore_case is true, at each loop cycle string.find will get stuck at the first replacement leading to an endless loop because count and capt both will keep being valid; rerun arg is relevant in recursive run of the function to search after changing case of non-ASCII characters // st is only needed in one-by-one mode
			repeat
				if capt then
					if capt ~= replace_term then -- only replace a match which hasn't been replaced yet; when all have been replaced a message of no replacements will be shown
					capt = Esc(capt)
					transcr, count = transcr:gsub(capt, replace_term, 1) -- replace capture because it was retuned with the correct case, doing it 1 by 1 which is presumably safer and more reliable because string.gsub has a limit of 32 replacements
					replace_cnt = replace_cnt+count
						if one_by_one then break end
					end	
				capt, st, fin = get_capture(transcr, search_term, ignore_case, exact, fin, rerun) -- prime for the next cycle
				else break end
			until count == 0 or not capt
		else
		-- patterns where the search term is only allowed to be padded with non-alphanumeric characters if 'Match exact word' option is enabled // 3 capture patterns are used because pattern with repetition * operator, e.g. '%W*'..s..'%W*', will match search term contained within words as well because '%W*' will also match alphanumeric characters hence unsuitable, start/end anchors are also meant to exclude alphanumeric characters in case the search term is only padded with non-alphanumeric character on one side
		local pad = '[\0-\47\58-\64\91-\96\123-191]' -- use punctuation marks explicitly by referring to their code points instead of %W because when the search term is surrounded with non-ASCII characters %W will match all non-ASCII characters in addition to punctuation marks so in these cases pattern such as '%W'..s..'%W' will fail to produce exact match and will return non-exact matches as well, the pattern range also includes control characters beyond code point 127 which is the end of ASCII range, codes source https://www.charset.org/utf-8
		local s = Esc(search_term)
			for _, patt in ipairs({pad..s..pad, pad..s..'$', '^'..s..pad}) do
			local capt_tmp
			capt, st, fin, capt_low = get_capture(transcr, patt, ignore_case, exact, fin, rerun) -- fin is returned to be passed as new start index inside string.find because if the search and replacement terms only differ in case while ignore_case is true, at each loop cycle string.find will get stuck at the first replacement leading to an endless loop because count and capt both will keep being valid; rerun arg is relevant in recursive run of the function to search after changing case of non-ASCII characters // st is only needed in one-by-one mode // capt_low is the capture after lowering the case when ignore_case is true, will be used to construct replace pattern for replacement of the original capture returned as capt which maintains the original case of the match so it can be found and replaced with gsub
				
				repeat
				
					if capt then
					
						if not capt:match(Esc(replace_term)) then -- only replace a match which hasn't been replaced yet, using string.match because the capture will contain surrounding characters; when all have been replaced a message of no replacements will be shown
						
						-- if ignore_case is true, lower the s (search term) case to match its case inside capt_low string, which in this event will be a lower case copy of capt string which is the original match, to be able to find it and replace within capt_low thereby constructing a replacement pattern for the original match in the source string
						s = ignore_case and (rerun and convert_case_in_unicode(s) or s:lower()) or s
						local repl_patt = capt_low:gsub(s, replace_term) -- first replace the target word inside the capture to keep all punctuation characters included in capt
						capt, repl_patt = Esc(capt), repl_patt:gsub('%%','%%%%') -- repl_patt must be escaped if contains % which is unlikley but just in case
						transcr, count = transcr:gsub(capt, repl_patt, 1) -- replace along with the originally captured punctuation marks, doin it 1 by 1 which is presumably safer and more reliable because string.gsub has a limit of 32 replacements
						replace_cnt = replace_cnt+count
							
							if one_by_one then break end
						
						end
					
					capt, st, fin, capt_low = get_capture(transcr, patt, ignore_case, exact, fin, rerun) -- prime for the next cycle
					
					else break end
					
				until count == 0 or not capt

				if capt and one_by_one then break end -- exit the 'for' loop

			end -- 'for' loop end

		end

		-- if not found with ignore_case being true, retry lowering case of non-ASCII characters as long as they're present
		if replace_cnt == 0 and not rerun and ignore_case
		and (is_utf8(line) or is_utf8(search_term)) then -- only if non-ASCII characters are present, i.e. those containing trailing (continuation) bytes, because in this case after lowering the case with string.lower the match is likely to not be found despite being there
		return replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, 1) -- rerun is true to only allow a single recursive run, otherwise an endless loop will be set off
		end

	local line = (timestamp or '')..transcr -- re-assemble the original line by appending back the time stamp // placed here so that in one-by-one mode st and fin values are calculated below from the original line start
	local fin_adj

		if one_by_one and capt then
		st = timestamp and st + #timestamp or st -- add length of timestamp portion to st value in case it was retrieved without it so that it's counted from the actual line start // ONLY RELEVANT FOR TRANSCRIBING SCRIPTS WHERE THERE'S TIME STAMP IN THE TEXT
		st, fin, fin_adj = get_replace_term_bounds(st, line, replace_term) -- subtracting extra (continuation or trailing) bytes in case text is non_ASCII so the value matches the actual character count // keeping orig fin value to store for the next cycle in 'LAST SEARCH' data because it all bytes must be taken account in it, fin_adj will be used for text highlighting inside Scroll_SWS_Notes_Window() where character count matters and not bytes
		end

	return line, st, fin, fin_adj, replace_cnt -- st, fin and fin_adj are only needed in one-by-one mode

	end


	local function search_and_replace(notes, search_term, start_line_idx, pos_in_line, replace_term, ignore_case, exact, one_by_one)
	local notes = notes:sub(-1) ~= '\n' and notes..'\n' or notes -- ensures that the last line is captured with gmatch search
	local t, replace_cnt, line_cnt = {}, 0, 0
	local line_upd, st, fin, fin_adj
		for line in notes:gmatch('(.-)\n') do
		line_cnt = line_cnt+1 -- could have been placed at the end of the loop so that only lines preceding the target line are counted which would obviate subtraction of 1 inside Scroll_SWS_Notes_Window() // ONLY RELEVANT IN ONE-BY-ONE MODE
			if #line:gsub(' ','') > 0 then -- for the sake of efficiency ignore empty lines
				if start_line_idx and line_cnt >= start_line_idx or not start_line_idx then -- start_line_idx is only relevant within the notes of a track where the start line belongs, if the search term wasn't found there and search has progressed to the next notes track these won't be relevant because there the search begins from the very first line // start_line_idx is ONLY RELEVANT IN ONE-BY-ONE MODE
				pos_in_line = start_line_idx and line_cnt == start_line_idx and pos_in_line or 1 -- pos_in_line other than 1 is only used if the search resumes from the same line in the same track notes and only on such line, in all other cases it's 1 // ONLY RELEVANT IN ONE-BY-ONE MODE
				local cnt
				line_upd, st, fin, fin_adj, cnt = replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one) -- st, fin, fin_adj are only relevant in one-by-one mode
					if cnt > 0 then
					replace_cnt = replace_cnt + cnt
						if one_by_one then -- replace line within Notes with its updated version and exit
						line, line_upd = Esc(line), line_upd:gsub('%%','%%%%')
						notes = notes:gsub(line, line_upd)
						break end
					end
				end
			end
		t[#t+1] = line_upd or line -- collect all lines into the table
		end

		if replace_cnt > 0 then
		return one_by_one and notes or table.concat(t, '\n'), replace_cnt, {line_cnt, replace_term, fin, fin_adj, line_upd, st} -- the last table return value is only relevant in one-by-one replacement mode
		end -- if no replacaments return nil

	end


local in_all_tracks, in_sel_track, one_by_one = replace_mode == '0', replace_mode == '1', replace_mode == '2'

-------------- INITIALIZE VARS FOR ONE-BY-ONE REPLACEMENT MODE -------------

-- Extract values of the last search to determine the position it must be resumed from
-- relying on storage because of not being aware of the way to get current caret position
-- within window other than from the capture returned by string.find();
-- otherwise the search will get stuck at the line of the last search hit
-- because of restarting from the beginning of this line and ending up at the same search hit
local stored = r.GetExtState(cmdID, 'LAST SEARCH') -- contains track index, start line index, search term, search term end pos in line
local stored_t = {}
	if #stored > 0 then
	stored = stored..'\n' -- to capture last entry
		for entry in stored:gmatch('(.-)\n') do
		stored_t[#stored_t+1] = entry
		end
	end

-- tr_idx and start_line_idx vars will only be valid when the script is first launched,
-- but once the CONTINUE loop has been set off these will be nil while the stored values will be valid
local tr_idx = one_by_one and (tr_idx or stored_t[1]+0)
local start_line_idx = one_by_one and (start_line_idx or stored_t[2]+0)
local pos_in_line = one_by_one and (stored_t[#stored_t] and stored_t[#stored_t]+0 or 1) -- value to be used as index argument in sting.find to mark location within line to resume the search from, if no stored value as is the case when the script is first launched default to 1 to start search from the beginning of the line
local t, tr = {}

------------------------------------------------------------------

local sel_tr = r.GetSelectedTrack(0,0) -- selected track is the one whose track Notes are displayed in the Notes window; the selected track will necessarily be one of the notes tracks because these are selected by Get_SWS_Track_Notes_Caret_Line_Idx() and in the course of search
local scroll_pos = GetSet_Notes_Wnd_Scroll_Pos(notes_wnd) -- to restore Notes window scroll pos if selected track Notes will have been updated because this causes scroll pos reset
local replace_cnt, cnt, sel_tr_idx = 0

	for i=tr_idx or 1, #tr_t do
	tr = tr_t[i].tr
		if not in_sel_track or tr == sel_tr -- in selected track replacement mode only run the routine when the loop reaches the first selected Notes track
		then
		local start_line_idx, pos_in_line = t and start_line_idx, t and pos_in_line or 1 -- start_line_idx will be valid and pos_in_line can be other than 1 in the 1st loop cycle only, because if the search term wasn't found in notes of the start search track and the search has proceded to the next track notes, it must begin from the very 1st line and in this case t var will be nil after being reset by an unsuccessful search in the 1st loop cycle below // ONLY RELEVANT IN ONE-BY-ONE MODE
		local notes = r.NF_GetSWSTrackNotes(tr)
		notes, cnt, t = search_and_replace(notes, search_term, start_line_idx, pos_in_line, replace_term, ignore_case, exact, one_by_one) -- t return value is only relevant in one-by-one mode
			if notes then -- if no replacemens will be nil
			r.NF_SetSWSTrackNotes(tr, notes) -- overwrite notes
			replace_cnt = replace_cnt+cnt -- store to display the replacement result to the user in modes other than one-by-one
				if in_sel_track and tr == sel_tr or one_by_one then -- notes of the 1st selected track (those displayed in the Notes window) have been updated
				sel_tr_idx = i -- store to return along with start_line_idx to condition and use inside Scroll_SWS_Notes_Window() because when notes are updated with NF_SetSWSTrackNotes() the notes window scroll position is reset so will need to be restored
					if one_by_one then
					r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..table.concat(t,'\n', 1, 3), false) -- persist false // alongside notes track index only store first 3 values: line index, replacement term and capture original end pos within line, replacement term is actually redundant here as it's never evaluated
					end
				break end -- in selected track or one by one replacement mode exit as soon as the 1st selected Noted track notes have been processed
			end
		end
	end


	if one_by_one and (tr_idx > 1 or start_line_idx > 1 or pos_in_line > 1) and not t then -- OR not sel_tr_idx // if in one-by-one mode after searching from the notes track other than the 1st or from the 1st or the only track but not from its 1st line or from the 1st line and not from its very start the search term wasn't found, restart from the 1st line of the 1st or the only track and continue until the track the search originally started from (which could be the same track if there's only one) to scan the so far non-scanned part of the transcript
		for i=1, #tr_t do
		tr = tr_t[i].tr
		local notes = r.NF_GetSWSTrackNotes(tr)
		notes, cnt, t = search_and_replace(notes, search_term, nil, 1, replace_term, ignore_case, exact, one_by_one) -- -- start_line_idx is nil, pos_in_line is 1; t return value is only relevant in one-by-one mode
			if notes then -- if no replacemens will be nil
			r.NF_SetSWSTrackNotes(tr, notes) -- overwrite notes
			replace_cnt = replace_cnt+cnt -- store to display the replacement result to the user in modes other than one-by-one, still leaving for consistency to be used in this mode to condition message of no replacements
			sel_tr_idx = i -- store to return along with start_line_idx to condition and use inside Scroll_SWS_Notes_Window() because when notes are updated with NF_SetSWSTrackNotes() the notes window scroll position is reset so will need to be restored
			r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..table.concat(t,'\n', 1, 3), false) -- persist false // alongside notes track index only store first 3 values: line index, replacement term and capture original end pos within line, replacement term is actually redundant here as it's never evaluated
			break end -- in selected track or one by one replacement mode exit as soon as the 1st selected Noted track notes have been processed
		end
	end


-- Construct result message ------
local mess = ' replacements \n\n have been made'
local repl_dest = in_all_tracks and ' \n\n in all '..NOTES_TRACK_NAME..' tracks '
or in_sel_track and ' \n\n in selected '..NOTES_TRACK_NAME..' track ' --or '' -- empty string in one-by-one mode
mess = not one_by_one and replace_cnt > 0
and math.floor(replace_cnt)..mess..repl_dest
or (one_by_one and replace_cnt == 0 or not one_by_one)
and 'no'..mess..(one_by_one and '' or repl_dest)..'\n\n or all matches \n\n have been replaced.' -- in one-by-one mode only display message if no replacements have been made, in one-by-one mode t could be used as a condition instead of replace_cnt in the previous line
	if mess then
	Error_Tooltip('\n\n '..mess..' \n\n', 1, 1, 100) -- caps, spaced true, x is 100 to move the tooltip away from the cursor so it doesn't stand between the cursor and search/replace dialogue OK button and doesn't block the click
	end
----------------------------------

	if replace_cnt > 0 then -- this will be valid for all 3 replacement modes unlike sel_tr_idx which doesn't cover in_all_tracks '0'
	-- return values if the currently selected or the 1st selected Notes track notes have been updated,
	-- to restore Notes window scroll position BUT ONLY if replacement was run right after search
	-- without closing the search dialogue, because in this case LAST SEARCH data containing caret line index will be available
		if one_by_one then
		return tr, tr_idx, sel_tr_idx, t[1], t[5], t[6], t[4], replace_cnt -- from the t table return line index to scroll, line itself to count its 1st character index inside notes, replacement term start/end within line to highlight it inside Scroll_SWS_Notes_Window(); comparison between last track index tr_idx and sel_tr_idx can be used in the main routine to condition a way of scrolling the Notes window with Scroll_SWS_Notes_Window(), although sel_tr_idx could be ommitted because tr_idx is used to retrieve track pointer from tr_t and compare it with tr return value; replace cound is returned to condition undo in the main routine
		else
		local stored = r.GetExtState(cmdID, 'LAST SEARCH') -- contains track index, start line index, search term, search term end pos in line
		local last_search_line_idx = stored:match('\n(.-)\n') -- stored on line 2
			if last_search_line_idx then
			return sel_tr, sel_tr_idx, nil, last_search_line_idx+0, nil, nil, nil, replace_cnt -- converting last_search_line_idx to number if was extracted from LAST SEARCH ext state; replace count is returned to condition undo in the main routine; irrelevant return values are set to be nil just to serve as placeholders matching return values of one-by-one mode above
			else
			-- if LAST SEARCH data is unavaliable, the replacement has been run right after opening the search dialogue
			-- and although at this stage start_line_idx can be taken from Get_SWS_Track_Notes_Caret_Line_Idx(),
			-- it's useless because it refers to the caret line index and not to the topmost line, i.e. scroll position
			-- and these can differ, so use js_ReaScriptAPI function to restore scroll position
			GetSet_Notes_Wnd_Scroll_Pos(notes_wnd, scroll_pos)
			return nil, nil, nil, nil, nil, nil, nil, replace_cnt -- adding nils as placeholders for return values which are irrelevant in this scenario to match the return values above otherwise replace_cnt will be treated as sel_tr return value outside
			end
		end
	end

end



function Search_Track_Notes(tr_t, tr_idx, start_line_idx, search_term, cmdID, ignore_case, exact)
-- tr_t stems from Get_Notes_Tracks_And_Their_Notes()
-- and contains notes tracks data
-- tr_idx, start_line_idx stem from Get_SWS_Track_Notes_Caret_Line_Idx()
-- and reprsent index of the notes track in whose notes
-- the transcript search must start and line holding the caret
-- which the search must start from in the track notes
-- search_term comes from user input dialogue
-- cmdID stems from get_action_context() converted to named command ID
-- ignore_case stems from the user input options

	local function get_capture(line, search_term, pos_in_line, exact, ignore_case, rerun)
	-- used inside search_notes()
	-- in order to return the capture string.find requires
	-- explicit formatting of the pattern or literal string as a capture
	-- rerun is boolean to condition recursive run once in case match wasn't found
	-- in order to convert non-ASCII characters to lower case and retry
	local s = Esc(search_term)-- for brevity
	local st, fin, capt
		if not exact then
		st, fin, capt = line:find('('..s..')', pos_in_line)
		else
		-- patterns where the search term is only allowed to be padded with non-alphanumeric characters if 'Match exact word' option is enabled // the capture start and end return values from string.find include the padding even if it's outside of the capture so to simplify start and end calculation for highlighting with Scroll_SWS_Notes_Window() it makes sense to include the padding in the capture to offset after the fact inside offset_capture_indices() otherwise there's no easy way to ascertain whether there was any padding // 3 capture patterns are used because pattern with repetition * operator, e.g. '%W*'..s..'%W*', will match search term contained within words as well because '%W*' will also match alphanumeric characters hence unsuitable, start/end anchors are also meant to exclude alphanumeric characters in case the search term is only padded with non-alphanumeric character on one side
		local pad = '[\0-\47\58-\64\91-\96\123-191]' -- use punctuation marks explicitly by referring to their code points instead of %W because when the search term is surrounded with non-ASCII characters %W will match all non-ASCII characters in addition to punctuation marks so in these cases pattern such as '%W'..s..'%W' will fail to produce exact match and will return non-exact matches as well, the pattern range also includes control characters beyond code 127 which is the end of ASCII range, codes source https://www.charset.org/utf-8
		--	for _, patt in ipairs({'%W'..s..'%W', '%W'..s..'$', '^'..s..'%W'}) do
			for _, patt in ipairs({pad..s..pad, pad..s..'$', '^'..s..pad}) do
			st, fin, capt = line:find('('..patt..')', pos_in_line)
				if capt then break end -- OR st OR fin BUT capture is required for processing inside offset_capture_indices()
			end
		end

	-- for efficiency sake converting non-ASCII sttings line by line instead of the entire Notes
	-- before the actual search as with ASCII
	-- and even so it may be a tad sluggish, on my PC anyway, but if there's a single match across several tracks
	-- reloading of the search dialogue as the script traverses all of them track by track to come back
	-- to the starting point may take a few seconds
		if not st and not rerun and ignore_case
		and (is_utf8(line) or is_utf8(s)) then -- only if non-ASCII characters are present, i.e. those containing trailing (continuation) bytes, because in this case after lowering the case with string.lower the match is likely to not be found if it's there
		line = convert_case_in_unicode(line, want_upper_case) -- want_upper_case false
		s = convert_case_in_unicode(s, want_upper_case) -- want_upper_case false
		return get_capture(line, s, pos_in_line, exact, ignore_case, 1) -- rerun is true to only allow a single recursive run, otherwise an endless loop will be set off
		end

	return st, fin, capt, line -- return line as well in case its case was lowered above, to be passed to offset_capture_indices() because after case lowering the returned non-ASCII capture won't be found in the original line; instead the case lowered search term could be returned
	end

	local function offset_capture_indices(st, fin, line, capt, search_term, exact)
	-- used inside search_notes()
	-- to exclude unicode extra bytes before and within capture
	-- so that 1 character corresponds to 1 byte because text highliting inside Scroll_SWS_Notes_Window() is based on characters
	local pre_capt_extra = select(2, line:sub(1,st-1):gsub('[\128-\191]',''))
	local capt_extra = select(2, capt:gsub('[\128-\191]',''))
	-- to exclude padding characters when searching exact match
	-- because padding characters are included in the capture start and end values despite being outside of it
	local pad_st = exact and capt:match('.') ~= search_term:match('.') and 1 or 0 -- first char // 1 because there'll be only 1 padding char due to the capture pattern used in get_capture()
	local pad_fin = exact and capt:match('.+(.)') ~= search_term:match('.+(.)') and 1 or 0 -- last char // 1 because there'll be only 1 padding char due to the capture pattern used in get_capture()
	return st - pre_capt_extra + pad_st, fin - pre_capt_extra - capt_extra - pad_fin -- + pad_st to shift start rightwards towards capture start offsetting padding, - pad_fin to shift end leftwards towards capture end
	end

	local function search_notes(notes, search_term, start_line_idx, pos_in_line, exact, ignore_case)
	local notes = notes:sub(-1) ~= '\n' and notes..'\n' or notes -- ensures that the last line is captured with gmatch search
	local line_cnt = 0
		for line in notes:gmatch('(.-)\n') do	-- accounting for empty lines because all must be counted
		line_cnt = line_cnt+1 -- could have been placed at the end of the loop so that only lines preceding the target line are counted which would obviate subtraction of 1 inside Scroll_SWS_Notes_Window()
			if start_line_idx and line_cnt >= start_line_idx or not start_line_idx then -- start_line_idx is only relevant within the notes of a track where the start line belongs, if the search term wasn't found there and search has progressed to the next notes track these won't be relevant because there the search begins from the very first line
			pos_in_line = start_line_idx and line_cnt == start_line_idx and pos_in_line or 1 -- pos_in_line other than 1 is only used if the search resumes from the same line in the same track notes and only on such line, in all other cases it's 1
			local st, fin, capt, line_cased
				if #line:gsub(' ','') > 0 then -- for the sake of efficiency ignore empty lines
				st, fin, capt, line_cased = get_capture(line, search_term, pos_in_line, exact, ignore_case) -- return line as well in case its case was lowered inside the function, to be passed to offset_capture_indices() below because after case lowering the returned non-ASCII capture won't be found in the original line; instead the case lowered search term could be returned
				end
				if capt then -- OR st OR fin BUT capture is required for processing inside offset_capture_indices() below
				local st, fin_adj = offset_capture_indices(st, fin, line_cased, capt, search_term, exact) -- subtracting extra (continuation or trailing) bytes in case text is non_ASCII so the value matches the actual character count and padding characters included in the capture start and end values when searching exact match despite being outside of it, all for the sake of accurate text selection/highlighting // keeping orig fin value to store for the next cycle because it all bytes must be taken account in it, fin_adj will be used for text highlighting where character count matters and not bytes
				return {line_cnt, search_term, fin, fin_adj, line, st}  -- storing search_term instead of capt because capture may include padding due to capture formatting inside get_capture() when 'Match exact word' is true
				end
			end
		end
	end


-- Extract values of the last search to determine the position it must be resumed from
-- relying on storage because of not being aware of the way to get current caret position
-- within window other than from the capture returned by string.find();
-- otherwise the search will get stuck at the line of the last search hit
-- because of restarting from the beginning of this line and ending up at the same search hit
local stored = r.GetExtState(cmdID, 'LAST SEARCH') -- contains track index, start line index, search term, search term end pos in line
local stored_t = {}
	if #stored > 0 then
	stored = stored..'\n' -- to capture last entry
		for entry in stored:gmatch('(.-)\n') do
		stored_t[#stored_t+1] = entry
		end
	end


-- tr_idx and start_line_idx vars will only be valid when the script is first launched,
-- but once the CONTINUE loop has been set off these will be nil while the stored values will be valid
local tr_idx = tr_idx or stored_t[1]+0
local start_line_idx = start_line_idx or stored_t[2]+0
local pos_in_line = stored_t[#stored_t] and stored_t[#stored_t]+0 or 1 -- value to be used as index argument in sting.find to mark location within line to resume the search from, if no stored value as is the case when the script is first launched default to 1 to start search from the beginning of the line
local t, tr, tr_idx_new = {}

	for i=tr_idx, #tr_t do
	tr = tr_t[i].tr
	local start_line_idx, pos_in_line = t and start_line_idx, t and pos_in_line or 1 -- start_line_idx will be valid and pos_in_line can be other than 1 in the 1st loop cycle only, because if the search term wasn't found in notes of the start search track and the search has proceded to the next track notes, it must begin from the very 1st line and in this case t var will be nil after being reset by an unsuccessful search in the 1st loop cycle below
	local notes = r.NF_GetSWSTrackNotes(tr)
		if ignore_case then notes = notes:lower() end
	t = search_notes(notes, search_term, start_line_idx, pos_in_line, exact, ignore_case) -- ignore_case will be used inside get_capture() to convert case of non-ASCII characters which arent supported by string.lower
		if t then
		tr_idx_new = i
		r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..table.concat(t,'\n', 1, 3), false) -- persist false // alongside notes track index only store first 3 values: line index, search term and capture original end pos within line, search term is actually redundant here as it's never evaluated
		break end
	end


	if (tr_idx > 1 or start_line_idx > 1 or pos_in_line > 1) and not t then -- OR not tr_idx_new // if after searching from the notes track other than the 1st or from the 1st or the only track but not from its 1st line or from the 1st line but not from its very beginning, restart from the 1st line of the 1st or the only track and continue until the track the search originally started from (which could be the same track if there's only one) to scan the so far non-scanned part of the transcript // the multitude of conditions is meant to ensure that the search isn't re-run when the search term hasn't been found after scanning the entire transcript for the sake efficiency
		for i=1, tr_idx do
		tr = tr_t[i].tr
		local notes = r.NF_GetSWSTrackNotes(tr)
			if ignore_case then notes = notes:lower() end
		t = search_notes(notes, search_term, nil, 1, exact, ignore_case) -- start_line_idx is nil, pos_in_line is 1, -- ignore_case will be used inside get_capture() to convert case of non-ASCII characters which arent supported by string.lower
			if t then
			tr_idx_new = i
			r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..table.concat(t,'\n', 1, 3), false) -- persist false // alongside notes track index only store first 3 values: line index, search term and capture original end pos within line, search term is actually redundant here as it's never evaluated
			break end
		end
	end


	if t then
	return tr, tr_idx, tr_idx_new, t[1], t[5], t[6], t[4] -- from the t table return line index to scroll, line itself to count its 1st character index inside notes, capture start/end within line to highlight it inside Scroll_SWS_Notes_Window(); comparison between last track index tr_idx and tr_idx_new can be used in the main routine to condition a way of scrolling the Notes window with Scroll_SWS_Notes_Window(), although tr_idx_new could be ommitted because tr_idx is used to retrieve track pointer from tr_t and compare it with tr return value
	else
	Error_Tooltip("\n\n the search term wasn't found \n\n", 1, 1) -- caps, spaced true
	end

end



function Scroll_SWS_Notes_Window(notes_wnd, tr, capt_line_idx, capt_line, capt_st, capt_end, ignore_case, replace_mode)
-- notes_wnd stems from Get_SWS_Track_Notes_Caret_Line_Idx()
-- the rest stem from Search_Track_Notes()

local SendMsg = r.BR_Win32_SendMessage

--	set scrollbar to top to procede from there on down by lines
SendMsg(notes_wnd, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
	for i=1, capt_line_idx-1 do -- -1 to stop scrolling at the target line and not scroll past it
	SendMsg(notes_wnd, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, lParam 0, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll but in fact the message code must be passed here as lParam while wParam must be 0, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage
	-- WM_VSCROLL is equivalent of EM_SCROLL 0x00B5 https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll
	end

	if capt_line then -- will be nil if this function is executed following Replace_In_Track_Notes() and capt_line_idx is valid because in this case only scroll position needs to be restored, text highligting isn't necessary

	r.BR_Win32_SetFocus(notes_wnd) -- window must be focused for selection to work

	local notes = r.NF_GetSWSTrackNotes(tr)

		if ignore_case and not replace_mode then notes = notes:lower() end -- this applies to ASCII characters because Notes case is lowered before the search inside Search_Track_Notes() and a line returned by search_notes() inside Search_Track_Notes() contains characters whose case was lowered, but for non-ASCII characters the case is lowered line by line during the search while the character case in the original line which is returned remains unaltered therefore here no separate change in the non-ASCII character case is required; NOT FOR REPLACEMENT MODE because this will prevent capturing the replacement term with string.find below if its case is upper or mixed

	local capt_line_st = notes:find('\n'..Esc(capt_line)) -- if not the first line, new line char \n must be taken into account for start value to refer to the visible start of the line otherwise the start will be offset by 1

	local carriage_return_cnt = notes:match('\r') and 0 or capt_line_idx-1 -- count carriage return chars \r preceding the capture line in the Notes window because in the window these terminate each line followed by a new line char so must be taken into account in determination of the text selection range, their count is equal to capt_line_idx-1, that is 1 per line excluding the capture line itself because selection starts within it; in Notes retrieved with NF_GetSWSTrackNotes() carriage return chars can only be present if the notes were copied between Notes windows in which case they'd be included within the copied text, so if there're any, assign 0 because their count will be taken into account in capt_line_st value so adding won't be necessary, otherwise count them; had the Notes been retrieved directly fron the Notes window with BR_Win32_GetWindowText() or JS_Window_GetTitle() they'd already contain carriage returns and capt_line_st value would account for them so adding would be unnecessary, but using these functions is less reliable because before SWS ext build 2.14.0.3 BR_ function only supported 1 kb buffer which would likely prevent retrieval of the Notes in full and JS_extension simply may happen to not be installed

	capt_line_st = capt_line_st and capt_line_st + carriage_return_cnt or 0 -- add carriage return count if any; if capt_line_st is nil because capt_line is the first line, assign 0

	-- correct the char count of notes preceding the capture line by subtracting extra (continuation or trailing) bytes count
	-- in case non-ASCII chars are present so that search term selection/highlighting is accurate
	-- because it's performed on the basis of characters rather than bytes
	capt_line_st = capt_line_st > 0 and
	capt_line_st - select(2, notes:match('(.-)'..Esc(capt_line)):gsub('[\128-\191]','')) -- or #notes:match('(.-)'..Esc(capt_line)):gsub('[\128-\191]','')
	or capt_line_st

	local capt_len = capt_end+1-capt_st -- +1 to get accurate length otherwise the last character isn't counted

	local capt_st = capt_line_st+capt_st-1 -- global capture start // -1 to start selection before the first capture character so it's included

	-- selection is only visible when the window is active
	-- but since in the CONTINUE loop in the main routine search dialogue window is active
	-- text selection in the Notes window won't be apparent
	-- it will become visible after the search dialogue is closed
	-- and the floating Notes window is put into focus or immediately
	-- if the Notes window is docked because main window which the dock is a child of gets into focus
	-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
	SendMsg(notes_wnd, 0x00B1, capt_st, capt_st+capt_len) -- EM_SETSEL 0x00B1, wParam capt_st, lParam capt_st+capt_len
	--	r.BR_Win32_SetFocus(r.GetMainHwnd()) -- removing focus clears selection

	end

end


function DEFERRED_WAIT()
-- when t is invalid the function is used to get the Notes window pointer after track selection 
-- in the scenario where no track is initially selected while the Notes window is open,
-- both with Get_SWS_Track_Notes_Caret_Line_Idx()
-- when t is valid the function is used to scroll the Notes window and select text inside it
-- when switching track selection
	if r.time_precise() - time_init > 0.1 then -- 0.03 also works but leaving 100 ms for a leeway
		if t then
		Scroll_SWS_Notes_Window(table.unpack(t)) -- table contains notes_wnd, tr, capt_line_idx, capt_line, capt_st, capt_end, ignore_case
		end
	time_init = nil -- resetting will allow the main routine to run when the function was launched to get Notes window while no track was initially selected, to be able to scroll the window and highlight text, as the script needs time to do that
	return end
r.defer(DEFERRED_WAIT)
end


function RESTART_FROM_DEFER(cmdID)
r.Main_OnCommand(cmdID, 0)
end


---------------- MAIN ROUTINE START ----------------


NOTES_TRACK_NAME = #NOTES_TRACK_NAME:gsub(' ','') > 0 and NOTES_TRACK_NAME

local err = not r.NF_SetSWSTrackNotes and 'SWS extension isn\'t installed'
or not SWS_Version_Check('2.14.0.3', nil, 1, 1) and not JS_Window_GetTitle
and 'the installed SWS extension \n\n  is old and js_reascriptAPI \n\n   extension isn\'t installed'
or not NOTES_TRACK_NAME and 'NOTES_TRACK_NAME \n\n  setting is empty'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end


local tr_t, notes = Get_Notes_Tracks_And_Their_Notes(NOTES_TRACK_NAME)

local err = 'tracks named "" \n\n weren\'t found'
err = #tr_t == 0 and err:gsub('""', '"'..NOTES_TRACK_NAME..'"')
or #notes:gsub('[%s%c]','') == 0 and 'No Notes in the tracks'

	if err then
	Error_Tooltip('\n\n '..err..' \n\n', 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmdID_init, mode, resol, val, contextstr = r.get_action_context()
cmdID = r.ReverseNamedCommandLookup(cmdID_init)


::CONTINUE:: -- must be placed here in case Notes window is closed at script launch, to allow getting its handle with Find_Window_SWS() and Get_Child_Windows_SWS() in the first CONTINUE cycle once opened inside Get_SWS_Track_Notes_Caret_Line_Idx() at the launch before the loop starts

-- these vars are global to keep them valid during the CONTINUE loop, so that the functions are only run once
-- when the script is first launched
-- upvalues remain valid within CONTINUE loop, such as tr_t, but variables local to the loop get reset at each cycle
-- like in other type of loops, unless global
-- STILL they're all reset after the script is relaunched as required
-- for re-loading the search dialogue while switching Notes between tracks, more on that below
notes_wnd = notes_wnd or Find_Window_SWS('Notes', want_main_children) -- want_main_children nil
child_wnd_t = child_wnd_t or Get_Child_Windows_SWS(notes_wnd)
local last_search_data = r.HasExtState(cmdID, 'LAST SEARCH')
local tr_idx, start_line_idx

	if not last_search_data or r.HasExtState(cmdID, 'RELAUNCHED') then
	-- for the sake of efficiency only run the  Get_SWS_Track_Notes_Caret_Line_Idx() function once before CONTINUE loop starts and before the last search data have been stored in the buffer inside Search_Track_Notes(), in order to determine location for the initial search start within Notes; once stored the location will be taken inside Search_Track_Notes()() function from the data stored inside Search_Track_Notes() function; notes_wnd var is being kept global to remain valid within the CONTINUE loop because it will be required below to prime the script for switching to another Notes track with DEFERRED_WAIT() function by changing focus to the program main window with BR_Win32_SetFocus()
	-- OR RUN the function after relaunching the script via atexit() when DEFERRED_WAIT() has exited because in this case all variables are reset, notes_wnd var above will be again storing Notes window parent handle from Find_Window_SWS(), but since by this stage last search data will have been already stored, using absence of these stored data as a condition alone won't work and notes window child handle needed for window scrolling and text highlighting inside Scroll_SWS_Notes_Window() won't be re-initialized
	-- OR when the script is executed headlessly conditioned by its armed state because in this scenario
	-- 'LAST SEARCH' data may not be available having been deleted if the search dialogue was exited with Cancel
	-- but 'RELAUNCHED' ext state will be true in any case because it's stored in the block within which DEFERRED_WAIT()
	-- function is launched needed in headless search mode to perform scrolling of the Notes window;
	-- running this function in the headless mode allows retreating and advancing the search by moving
	-- the caret up and down within the Notes window because the function returns caret position as start_line_idx
	-- which isn't possible in non-headless mode because search dialogue being a modal window blocks interaction
	-- with other windows so the function is skipped and the caret pos is taken from 'LAST SEARCH' data instead
	r.DeleteExtState(cmdID, 'RELAUNCHED', true) -- persist true
	tr_idx, start_line_idx, notes_wnd = Get_SWS_Track_Notes_Caret_Line_Idx(child_wnd_t, tr_t) -- notes_wnd here is Notes child window containing the text, isolated from child_wnd_t
		if not notes_wnd then -- this will be true if at the moment of the script launch the Notes window is closed OR open without any track being selected, so return to get the Notes window handles after opening it inside Get_SWS_Track_Notes_Caret_Line_Idx() otherwise window scrolling won't work as by the time the CONTINUE loop will have been started the HasExtState conditions will be false
			if r.GetToggleCommandStateEx(0, r.NamedCommandLookup('_S&M_SHOW_NOTES_VIEW')) == 1 then -- Notes window is open and no track is selected
			-- starting CONTINUE loop in this scenario will set off endless loop even though a track gets selected
			-- inside Get_SWS_Track_Notes_Caret_Line_Idx()
			-- that's because loading Notes of a track just selected into the Notes window takes some time
			-- but by the time this function is triggered again, this time within the CONTINUE loop,
			-- they still won't be accessible, so notes_wnd var will remain nil
			-- and in turn will again trigger CONTINUE loop;
			-- DEFERRED_WAIT() puts the script on hold for 100 ms which is enough for the selected track notes
			-- to be loaded into the Notes window which will allow getting its handle as notes_wnd;
			-- this issue doesn't occur when the Notes window is initially closed probably because
			-- when the window opens the Motes load immediately
			time_init = r.time_precise()
			DEFERRED_WAIT()
			else -- Notes window is closed
			goto CONTINUE
			end
		end
	end

	
local search_sett = r.GetExtState(cmdID, 'SEARCH SETTINGS')
local sep = '`'
local headless_mode = #search_sett > 0 and r.GetArmedCommand() == cmdID_init -- initialized outside of the next block to be accessible inside 'if time_init' block at the end, otherwise the script will run in a loop in the headless mode
local output_t, output	
	
	if not time_init then -- only run if DEFERRED_WAIT() launched above to get Motes window when initially no track was selected has exited, time_init will be reset inside DEFERRED_WAIT(); the condition is needed because after DEFERRED_WAIT() launch the routine continues to run until the end but without window handle no window operations will be performed which is a flaw

	----------- S E A R C H  D I A L O G U E  S E T T I N G S ----------------

	local i = 0
	search_sett = last_search_data and search_sett or search_sett:gsub('[^'..sep..']*', function(c) i = i+1 if i == 4 then return '' end end) -- disable 'Enable replacement' option by removing the flag from the stored search settings so that every time the script is launched in search rather than in replace mode for safety reasons, when the script is launched last_search_data is false because the data is deleted each time the search dialogue is exited

		-- If the script is armed and there're stored 'SEARCH SETTINGS' data don't load the search dialogue
		-- and run the search headlessly in which case the script isn't restarted via atexit()
		-- to prevent setting off endless CONTINUE loop
		-- and is run from the start at each mouse click
		if not headless_mode then

		output_t, output = GetUserInputs_Alt('TRANSCRIPT SEARCH  (insert any character to enable search settings)', 5, 'SEARCH TERM:,Match case (register):,Match exact word:,Enable replacement (h for Help): ,Replace with:', search_sett, sep) -- autofill the dialogue with the last search settings

		elseif #search_sett:gsub('[%s'..sep..']','') > 0 then
		output_t = {}
		--[[ WORKS BUT MORE VERBOSE THAN THE sring.match METHOD BELOW
			for sett in (search_sett..sep):gmatch('[^'..sep..']*') -- adding trailing field separator so that gmatch pattern captures the last field content as well, but keeping original search_sett value intact
			output_t[#output_t+1] = sett
			end
		]]
		local patt = '(.-)'..sep
		output_t = {(search_sett..sep):match(patt:rep(5))} -- adding trailing field separator so that all fields are captured with the pattern, repeating the pattern as many times are there're fields in the dialogue // alternative to gmatch
		output = search_sett -- assign to output var because this is what's being saved as extended state below
		end


		if not output_t or #output_t[1]:gsub(' ','') == 0 then -- all fields are empty or the search term field only
		r.DeleteExtState(cmdID, 'LAST SEARCH', true) -- persist true // the search ext state data stored inside Search_Track_Notes() are kept as long as the search dialogue is kept open in which case the script keeps running or if the search is run headlessly while the script is armed; the data are only deleted when the dialogue is exited
		return r.defer(no_undo) end


	r.SetExtState(cmdID, 'SEARCH SETTINGS', output, false) -- persist false // keep latest search settings during REAPER session to autofill the search dialogue when it's opened and to get them in the headless search

	local ignore_case = not validate_output(output_t[2])
	local search_term = ignore_case and output_t[1]:lower() or output_t[1] -- convert to lower case if 'Match case' is not enabled
	local exact = validate_output(output_t[3])
	local replace_term = output_t[5]
	local replace_mode = #output_t[4]:gsub(' ','') > 0 and output_t[4]

	-------------------------------------------------------------------------

		-- SEARCH AND REPLACE
		if replace_mode then
		local valid_vals = 'Valid values are:\n\n0 — batch replace in all transcript tracks\n\n'
		..'1 — batch replace in the only or the 1st\n       selected transcript track\n\n2 — replace word by word'
		local is_num = replace_mode:match('^%s*([\1-\255])%s*$') -- accounting for non-ASCII input by the user, otherwise is_num will end up being nil, only allowing padding with spaces
			if is_num and is_num:match('[hH]') then
			r.MB(valid_vals,'HELP',0)
			is_num = nil -- to prevent execution of Replace_In_Track_Notes() below, alternative to goto CONTINUE
			else
				is_num = tonumber(replace_mode)
				if not is_num or is_num and math.floor(is_num) ~= is_num or is_num < 0 or is_num > 2 then
				r.MB('INVALID REPLACE MODE "'..output_t[4]..'".\n\n'..valid_vals, 'ERROR', 0)
				is_num = nil -- to prevent execution of Replace_In_Track_Notes() below, alternative to goto CONTINUE
				end
			end
			if not ignore_case and search_term == replace_term then -- only if ignore_case is true because otherwise if they're same the match and the replace term can still differ in their case so replacement will make sense
			Error_Tooltip('\n\n the search and replacement \n\n\tterms are identical \n\n', 1, 1, 100) -- caps, spaced true, x is 100 to move the tooltip away from the cursor so it doesn't stand between the cursor and search/replace dialogue OK button and doesn't block the click
			elseif is_num then
			r.Undo_BeginBlock()
			tr, tr_idx_old, tr_idx_new, capt_line_idx, capt_line, capt_st, capt_end, replace_cnt =
			Replace_In_Track_Notes(replace_mode, tr_t, tr_idx, start_line_idx, search_term, replace_term, cmdID, ignore_case, exact, notes_wnd)
			local undo = replace_mode == '0' and 'in entire transcript' or replace_mode == '1' and 'in selected track transcript' or ''
			undo = replace_cnt and replace_cnt > 0 and 'Transcribing A: Replace '..search_term..' with '..replace_term..' '..undo
			r.Undo_EndBlock(undo or r.Undo_CanUndo2(0) or '',-1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated if no replacements were made following Undo_BeginBlock(), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
			end
		-- SEARCH
		else
		tr, tr_idx_old, tr_idx_new, capt_line_idx, capt_line, capt_st, capt_end =
		Search_Track_Notes(tr_t, tr_idx, start_line_idx, search_term, cmdID, ignore_case, exact) -- search_term
		end

		if tr then
		r.SetOnlyTrackSelected(tr) -- select the track so its notes are dispayed in the Notes window
		r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
			if tr_t[tr_idx_old].tr ~= tr then -- OR if tr_idx_old ~= tr_idx_new
			r.BR_Win32_SetFocus(r.GetMainHwnd()) -- when the search term was found in another track Notes, for the SWS Notes window to focus on the newly selected track the program window must be active because while the dialogue is open its the one being active; this is in addition to DEFERRED_WAIT() function below and must be done before it is launched
			end
		end

	t = {notes_wnd, tr, capt_line_idx, capt_line, capt_st, capt_end, ignore_case, replace_mode} -- global so it's accessinble inside DEFERRED_WAIT() function if needed


		if tr and tr_t[tr_idx_old].tr == tr and not headless_mode then -- OR if tr_idx_old == tr_idx_new // if as a result of search track selection hasn't changed // only if the script is unarmed, i.e. the seatch doesn't run headlessly otherwise it needs more time to process scrolling which will be done with DEFERRED_WAIT() in the next block
		Scroll_SWS_Notes_Window(table.unpack(t))
		goto CONTINUE
		elseif tr then -- track selection has changed or the search is run headlessly while the script is armed
		-- deferred function must be used to wait until the window is fully loaded
		-- because when changing track selection or when running search headlessly window update takes time
		-- and the script fails to make the window scroll due to running through faster
		-- that's unlike in BuyOne_Transcribing A - Create and manage segments (MAIN).lua
		-- where execution of Scroll_SWS_Notes_Window() doesn't need to be delayed with a defer loop
		-- probably because that script runs longer giving enough time for the window to load
		-- and be successfully affected by scroll position change
		r.SetExtState(cmdID, 'RELAUNCHED', '', false) -- persist false // store to condition re-running Get_SWS_Track_Notes_Caret_Line_Idx() after defer loop has exited and the script has been relaunched via atexit() in order to re-get notes_wnd handle needed for Notes window scrolling, because when the script is relaunched all variables are reset
		time_init = r.time_precise()
		DEFERRED_WAIT()
		elseif replace_mode then -- if after batch replacement with Replace_In_Track_Notes() Notes window scroll position doesn't require restoration because selected Notes track notes haven't been updated, tr and tr_idx_old vars will be nil and this block will be activated
		goto CONTINUE
		end
	
	end -- end 'if not time_init' block

do
	if time_init then
		-- if DEFERRED_WAIT() has been launched (time_init vat is valid)
		-- set the script to relaunch after termination and re-launch as an action
		-- with Main_OnCommand() via atexit(), Main_OnCommand() alone won't work because
		-- no function is registered at termination apart from atexit(),
		-- all that is because using 'goto CONTINUE' while the defer loop is running sets off an endless loop
		if r.set_action_options then r.set_action_options(1|2) end -- set to re-launch after termination, supported since build 7.03
		-- script flag for auto-relaunching after termination in reaper-kb.ini is 516, e.g. SCR 516, but if changed
		-- directly while REAPER is running the change doesn't take effect, so in builds older than 7.03 user input is required
		if not headless_mode then -- only restart if the search isn't run headlessly, i.e. the script isn't armed otherwise endless loop will be set off
		r.atexit(Wrapper(RESTART_FROM_DEFER, cmdID_init))
		end
	end
return r.defer(no_undo) end






