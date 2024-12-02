--[[
ReaScript name: BuyOne_Transcribing B - Replace text in the transcript.lua
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058 or https://github.com/Buy-One/REAPER-scripts/issues
Version: 1.0
Changelog: #Initial release
Licence: WTFPL
REAPER: recommended 7.03 and newer
Extensions: SWS/S&M or js_ReaScriptAPI is recommended			
About:	The script is part of the Transcribing B workflow set of scripts
  			alongside 
  			BuyOne_Transcribing B - Create and manage segments (MAIN).lua  
        BuyOne_Transcribing B - Real time preview.lua  
  			BuyOne_Transcribing B - Format converter.lua  
  			BuyOne_Transcribing B - Import SRT or VTT file as regions.lua  
  			BuyOne_Transcribing B - Prepare transcript for rendering.lua  
  			BuyOne_Transcribing B - Generate Transcribing B toolbar ReaperMenu file.lua  
  			BuyOne_Transcribing B - Show entry of region selected or at cursor in Region-Marker Manager.lua  
  			BuyOne_Transcribing B - Offset position of regions in time selection by specified amount.lua
  			
  			Installation of extensions isn't absolutely necessary as the script 
  			can do the job without them but they may enhance the user experience
  			because they help isolating in the Region/Marker Manager the targeted
  			segment region for the sake of visual freedback of the replacement
  			result.
  			
  			The script offers 4 replacement modes:  
  			0. Batch replace in all segment regions
  			1. Batch replace in segment regions within time selection
  			2. Batch replace in segment regions from the edit/mouse cursor onwards
  			3. Batch replace from the first segment region up to the edit/mouse cursor
  			4. Word by word starting from the segment region at the edit/mouse cursor
  			
  			In mode 2 time selection may include region start, region end, both
  			or be inside the region.  
  			In mode 4 replacement starts from the region at the edit cursor which 
  			includes the entire region width but not its end marker.  		
  			If there's no region at cursor the closest next region will be used 
  			as the starting point.  			
  			To look up the modes, type character h or H (for help) in the field 
  			'5. Mode' of the replacement dialogue.
  
  
  			► js_ReaScriptAPI extension
  
  			With js_ReaScriptAPI extension in modes 0-3 the script is able to scroll 
  			the Region/Marker Manager towards the entry of the first segment region 
  			whose name was changed in the range affected by the script and in mode 4 
  			towards the entry of the segment region whose name was edited last, UNLESS 
  			SUCH ENTRY IS ALREADY WITHIN VIEW. If not within view such entry is scrolled 
  			into view either at the bottom or at the top of the Region/Marker Manager list.  
  			Unlike with the SWS extension it's not possible to automatically fill out 
  			the Region/Marker Manager filter field with he replacement term to isolate 
  			entries containing the replacement term so that they're more apparent in
  			the list. However the replacement term can be copied from the replacement
  			dialogue and pasted in the Region/Marker Manager filter field. In this
  			respect there're a couple of guidelines:  
  			1. If you search to replace the exact match (field '4. Match exact word' is
  			enabled in the dialogue), enclose the replacement term in the Region/Marker 
  			Manager filter field within single or double quotes which is the exact match
  			operator in REAPER.
  			2. Since in REAPER words AND, OR, NOT (in upper case) are used as list filter 
  			operators, if the replacement term contains them, in the Region/Marker Manager 
  			filter field change their case to lower so that they're interpreted as regular
  			words and not as operators. 
  			
  			If the REAPER build you're using is older than 7.03, then using this script 
  			with js_ReaScriptAPI extension and having the replacement term in the 
  			Region/Marker Manager filter field you're likely to encounter 'ReaScript task control' 
  			dialogue pop up. Once it does, checkmark 'Remember my answer for this script' 
  			checkbox and press 'New instance' button, this will prevent the pop up from 
  			appearing in the future.
  			
  			
  			► SWS/S&M extension
  
  			With the SWS/S&M extension in modes 0-3 the Region/Marker Manager list 
  			is by default filtered with the replacement term and is scrolled towards 
  			the entry of the first segment region whose stranscript was changed 
  			in the range affected by the script while in mode 4 the entry of the
  			segment region whose name was changed last can either be scrolled into
  			view or isolated in the list through insertion of either the updated segment
  			transcript or the replacement term into the Manager's filter field depending 
  			on the USER SETTINGS. When scrolled, such segment region entry is scrolled 
  			to the top of the list as long as the list is long enough.  
  			In order for scrolling to be accurate Region/Marker Manager display settings
  			('Regions', 'Markers', and 'Take markers' checkboxes) are changed so that 
  			only regions are listed. The entries in the Region/Marker Manager must be 
  			sorted by start in ascending order otherwise the scrolling won't be performed.
  
  			If both extensions are installed js_ReaScriptAPI has priority which can be 
  			changed in the USER SETTINGS.	
  			
  			In replacement mode 4 the edit cursor follows the replacement progress and
  			is moved to the segment region whose transcript was edited the last.  
  			
  			If extensions are installed and the Region/Marker Manager is closed at the
  			moment of the script execution, the script will open it so that the user 
  			can get visual feedback of the changes to the transcript.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Between the quotes specify HEX color either preceded
-- or not with hash # sign, can consist of only 3 digits
-- if they're are repeated, i.e. #0fc;
-- MUST DIFFER FROM THE THEME DEFAULT REGION COLOR
-- AND MATCH THE SAME SETTING IN THE SCRIPT
-- 'BuyOne_Transcribing B - Create and manage segments (MAIN).lua'
SEGMENT_REGION_COLOR = "#b564a6"

-- To enable the following settings insert any alphanumeric character
-- between the quotes.

-- If enabled the script will use SWS/S&M extension
-- instead of js_ReaScriptAPI to display in the Region/Marker Manager
-- the entries of the segment regions whose transcript were edited;
-- if only js_ReaScriptAPI is installed the setting is ignored
PREFER_SWS_EXT_API = ""

-- Only relevant if SWS/S&M extension is installed, it's
-- preferred over js_ReaScriptAPI extension by having the setting
-- PREFER_SWS_EXT_API above enabled and replacement mode is 4;
-- if this setting is enabled, instead of scrolling
-- the Region/Marker Manager towards the entry of the segment region
-- whose transcript was edited last, the script will isolate
-- the relevant region entry in the list by insering its transcript
-- into the Manager's filter field
FILTER_BY_SEGMENT_TRANSCRIPT = ""

-- Only relevant if SWS/S&M extension is installed, it's
-- preferred over js_ReaScriptAPI extension by having the setting
-- PREFER_SWS_EXT_API above enabled and replacement mode is 4;
-- if this setting is enabled, the Region/Marker Manager list
-- will be filtered by the replacement term and scrolled towards
-- the entry of the segment region whose transcript was edited
-- last as it's being added to the filtered list;
-- since in REAPER words AND, OR, NOT (in upper case) are used as
-- list filter operators, if the replacement term contains them,
-- in the Region/Marker Manager filter field it will be pasted with
-- these words in lower case so that they're interpreted as regular
-- words and not as operators
FILTER_BY_REPLACEMENT_TERM = ""

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
field_names = comment_field and #comment > 0 and field_names..',Current segment:' or field_names
field_cont = comment_field and #comment > 0 and field_cont..sep..comment or field_cont
local separator = separator and ',separator='..separator or ''
local ret, output = r.GetUserInputs(title, field_cnt, field_names..',extrawidth=200'..separator, field_cont)
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
return t, #comment > 0 and output:match('(.+)'..sep) or output -- remove hanging separator if there was a comment field, to simplify re-filling the dialogue in case of reload, when there's a comment the separator will be added with it, comment isn't included in the returned output
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
		t[txt] = child
		end
	child = r.BR_Win32_GetWindow(child, 2) -- 2 = GW_HWNDNEXT // get next sibling of each next found child window advancing until no child is found
	i=i+1
	until not child
return next(t) and t
end



function Scroll_Region_Marker_Mngr_SWS(mngr_child_t, line_idx)
-- mngr_child_t stems from Get_Child_Windows_SWS()
-- line_idx stems from Replace_In_Segment_Regions()
local wnd
	for title, child in pairs(mngr_child_t) do
	-- 'Region/Marker Manager' list window is named 'List2', address is '0x10033C',
	-- discovered with Get_All_Child_Wnds(), the hex value with JS_Window_ListAllChild()
		if title == 'List2' then wnd = child break end
	end
	if wnd then
	local SendMsg = r.BR_Win32_SendMessage
	--	set scrollbar to top to procede from there on down by lines
	SendMsg(wnd, 0x0115, 6, 0) -- msg 0x0115 WM_VSCROLL, 6 SB_TOP, 7 SB_BOTTOM, 2 SB_PAGEUP, 3 SB_PAGEDOWN, 1 SB_LINEDOWN, 0 SB_LINEUP https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll
		for i=1, line_idx-1 do -- -1 to stop scrolling at the target line and not scroll past it
		SendMsg(wnd, 0x0115, 1, 0) -- msg 0x0115 WM_VSCROLL, lParam 0, wParam 1 SB_LINEDOWN scrollbar moves down / 0 SB_LINEUP scrollbar moves up that's how it's supposed to be as per explanation at https://learn.microsoft.com/en-us/windows/win32/controls/wm-vscroll but in fact the message code must be passed here as lParam while wParam must be 0, same as at https://stackoverflow.com/questions/3278439/scrollbar-movement-setscrollpos-and-sendmessage
		-- WM_VSCROLL is equivalent of EM_SCROLL 0x00B5 https://learn.microsoft.com/en-us/windows/win32/controls/em-scroll
		end
	end
end


function Get_Region_Marker_Mngr_Settings()
-- used inside Manage_Region_Mrkr_Mngr_Settings()
local sett_flags, sort_flag
	for line in io.lines(r.get_ini_file()) do
		if line == '[regmgr]' then found = 1
		elseif found then
		sett_flags = sett_flags or line:match('flags=(.+)')
		sort_flag = sort_flag or line:match('sort=(.+)')
			if sett_flags and sort_flag then break end
		end
	end
sett_flags = tonumber(sett_flags)
local t = {}
	-- the power values are arranged in the order of settings reflected in the list below
	for k,  power in ipairs({0,1,7,8,10,9,6,2,5}) do
	local bit = 2^power
	-- some flags are set when the setting is disabled
	-- therefore inequality must be evaluated rather than equality
		if power == 0 or power == 7 or power == 9 or power == 5 then
		t[k] = sett_flags&bit == bit
		else -- flags which are set when the setting is disabled
		-- but since we're collecting truth when a setting is enabled
		-- what's evaluated is inequality, which will be true when a setting is enabled
		t[k] = sett_flags&bit ~= bit
		end
	end
--[[ the order or the settings in the table, follows the order in Manager from top to bottom:
'flags' key
Markers: 1 - unchecked false, checked true
Regions: 2 - unchecked true, checked false
Take markers: 128 - unchecked false, checked true
List markers, regions and take markers separately: 256 - unchecked true, checked false
Only display visible take markers in active takes: 1024 - unchecked true, checked false
Add/remove child tracks to render list when adding/removing folder parent: 512 - unchecked false, checked true
Show track render dropdown list nested by folders: 64 - unchecked true, checked false
Seek playback when selecting a marker or region: 4 - unchecked true, checked false
Play region through then repeat or stop when selecting a region: 32 - unchecked false, checked true
'sort' key
sort flag
0 - color descending by HSV value https://forum.cockos.com/showthread.php?p=2822865
1 - index ascending
2 - name ascending
3 - start ascending
4 - end ascending
5 - length ascending
6 - render track list descending
7 - info descending
16 - color ascending by HSV value
17 - index descending
18 - name descending
19 - start descending
20 - end descending
21 - length descending
22 - render track list ascending
23 - info descending
]]
return t, sort_flag -- in the table the setting is true if enabled and false if disabled
end



function Manage_Region_Mrkr_Mngr_Settings(mngr_child_t)

local sett_flags_t, sort_flag = Get_Region_Marker_Mngr_Settings()
-- checkbox window names: Regions, Markers, Take markers

	if sort_flag ~= '3' then -- items are sorted by a criterion other than start or by start but not in ascending order
	Error_Tooltip("\n\n       region entries \n\n are not sorted by start \n\n     in ascending order."
	.." \n\n scrolling will not work \n\n", 1, 1, 200) -- caps, spaced true, x is 200 to move the tooltip away from the dialogue OK button beause its blocks the click
	return end

	local function mouse_click(wnd)
	local Send = r.BR_Win32_SendMessage
--	https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttondown
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-lbuttonup
		for k, msg in ipairs({0x0201,0x0202}) do -- WM_LBUTTONDOWN 0x0201, WM_LBUTTONUP 0x0202
		Send(wnd, msg, 0x0001, 1+1<<16) -- MK_LBUTTON 0x0001, x (low order) and y (high order) are 1, in lParam client window refers to the actual target window, x and y coordinates are relative to the client window and have nothing to do with the actual mouse cursor position, 1 px for both is enough to hit the window
		end
	end

	for k, wnd_tit in ipairs({'Markers','Regions','Take markers'}) do -- window titles are arranged in the order of settings stored inside sett_flags_t
		if k == 2 and not sett_flags_t[k] -- if regions option isn't enabled
		or k ~= 2 and sett_flags_t[k] then -- of proj/take markers options are enabled
		mouse_click(mngr_child_t[wnd_tit]) -- toggle
		end
	end

return true -- to condition scrolling, if exited earlier, the condition will be false due to lack of sorting by start in ascending order

end



function Insert_String_Into_Field_SWS(child_t, str)
-- child_t is table with Region/Marker Manager children windows
-- stemming from Get_Child_Windows_SWS()
-- one of which is the filter field window that's nameless if empty

local filter_wnd, filter_cont

	for title, hwnd in pairs(child_t) do
	local match
		for k, tit in ipairs({'Clear', 'List2', 'Markers', -- the window title list is as of build 7.22
		'Options', 'Regions', 'Render Matrix...', 'Take markers'}) do
			if title == tit then match = 1 break end
		end
		if not match then -- if title didn't match any of the fixed name window, it must be the filter field window
		filter_wnd, filter_cont = hwnd, title
		break end
	end

	if not filter_wnd or title == str then return end

local SendMsg = r.BR_Win32_SendMessage

--------------- CLEAR ROUTINE  --------------------------------------------

-- https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
-- https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#keystroke-message-flags -- scan codes are listed in a table in 'Scan 1 Make' colum in Scan Codes paragraph
-- https://handmade.network/forums/articles/t/2823-keyboard_inputs_-_scancodes%252C_raw_input%252C_text_input%252C_key_names
-- 'Home' (extended key) scan code 0xE047 (move cursor to start of the line) or 0x0047, 'Del' (extended key) scan code 15, Backspace scancode 0x000E or 0x0E (14), Forward delete (regular delete) 0xE053 (extended), Left arrow 0xE04B (extended key), Left Shift 0x002A or 0x02A, Right shift 0x0036 or 0x036 // all extended key codes start with 0xE0
-- BR_Win32_SendMessage only needs the scan code, not the entire composite 32 bit value, not even the extended key flag, the repeat count, i.e. bits 0-15, is ignored, no matter the integer the command only runs once
	-- #filter_cont count works accurately here for Unicode characters as well for some reason
	--[[
	-- move cursor to start of the line
	SendMsg(filter_wnd, 0x0100, 0x24, 0xE047) -- 0x0100 WM_KEYDOWN, 0x24 VK_HOME HOME key, 0xE047 HOME key scan code
		for i=1,#filter_cont do -- run Delete for each character
		SendMsg(filter_wnd, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 DEL key scan code
		end
	--]]
	--[[ OR
		for i=1,#filter_cont do -- move cursor from line end left character by character deleting them
		SendMsg(filter_wnd, 0x0100, 0x25, 0xE04B) -- 0x25 LEFT ARROW key, 0xE04B scan code
		SendMsg(filter_wnd, 0x0100, 0x2E, 0xE053) -- 0x2E VK_DELETE DEL key, 0xE053 scan code
		end
	--]]
	--[-[ OR
	-- https://learn.microsoft.com/en-us/windows/win32/controls/em-setsel
	-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-clear
	SendMsg(filter_wnd, 0x00B1, 0, -1) -- EM_SETSEL 0x00B1, wParam start char index, lParam -1 to select all text or end char index
	SendMsg(filter_wnd, 0x0303, 0, 0) -- WM_CLEAR 0x0303
	--]]

--------------------------------------------------------------
r.CF_SetClipboard(str)
SendMsg(filter_wnd, 0x0302, 0, 0) -- WM_PASTE 0x0302 // gets input from clipboard
-- https://learn.microsoft.com/en-us/windows/win32/dataxchg/wm-paste
--	https://ecs.syr.edu/faculty/fawcett/Handouts/CoreTechnologies/windowsprogramming/WinUser.h

end



function Get_Child_Windows_JS(parent_name, want_exact)
local parent_wnd = r.JS_Window_Find(parent_name, want_exact)
	if parent_wnd then
	local retval, list = r.JS_Window_ListAllChild(parent_wnd)
	local t = {}
		for address in list:gmatch('0x%x+') do
		local wnd = r.JS_Window_HandleFromAddress(address)
		t[r.JS_Window_GetTitle(wnd)] = wnd
		end
	return next(t) and t
	end
end



function Is_Filter_Field_FilledOut_JS(child_t, repl_term)
return child_t[repl_term]
end



function Scroll_Region_Mngr_To_Item_JS(rgn_mngr_closed, rgn_name)
-- supports selected markers as well
-- rgn_mngr_closed value must be obtained before opening the Manager
-- rgn_name is only relevant when no region/marker is selected
-- because in this case the entry for scrolling into view
-- is searched for by region name

	if not r.JS_Window_Find then return end

local parent_wnd = r.JS_Window_Find('Region/Marker Manager', true) -- exact true // covers both docked and undocked window

	if parent_wnd then

	local mngr_list_wnd = r.JS_Window_FindChild(parent_wnd, 'List2', true) -- exact true, 'Region/Marker Manager' list window is named 'List2', address is '0x10033C', discovered with Get_All_Child_Wnds(), the hex value with JS_Window_ListAllChild()
	local list_itm_cnt = r.JS_ListView_GetItemCount(mngr_list_wnd)

		for idx=0, list_itm_cnt-1 do
			if not rgn_name then -- look for highlighted item in the list
			local highlighted = r.JS_ListView_GetItemState(mngr_list_wnd, idx) == 2 -- items in the Region/Marker Manager aren't selected by a click on a region/marker in Arrange but are highlighted, they're selected when clicked directly, code is 3 which is irrelevant for this script
				if highlighted then
				-- this doesn't need scrolling with JS_Window_SetScrollPos() at all;
				-- if Region/Marker Manager is closed when the script is executed
				-- and then is opened by the script, JS_ListView_GetItemState()
				-- sometimes seems to make the color of entries of non-selected objects
				-- brighter than the selected MARKERS (within range between 10 to 30
				-- counting from the 1st marker), same with JS_ListView_GetItem()
				-- which returns both text and state,
				-- never happens with selected regions and when moving into view based
				-- on the region/marker name below;
				-- to compensate for this added JS_Window_SetFocus() so that
				-- if the Manager window is initially closed, when opened
				-- the entry of the selected object becomes darker and thus more discernible,
				-- JS_Window_Update() doesn't help in this regard
				local focus = rgn_mngr_closed and r.JS_Window_SetFocus(mngr_list_wnd)
				r.JS_ListView_EnsureVisible(mngr_list_wnd, idx, false) -- partialOK false
				return true end
			else -- no item is highlighted, search by text in the column, in this case region name
				for col_idx=0,15 do -- currently (build 7.22) there're 10 columns in Region/Marker Manager, but using 16 in case the number will increase in the future
				-- colums can be reordered therefore all must be traversed to find the right one
					if r.JS_ListView_GetItemText(mngr_list_wnd, idx, col_idx) == rgn_name then -- item arg is row index, subitem is column index, both 0-based
					r.JS_ListView_EnsureVisible(mngr_list_wnd, idx, false) -- partialOK false
					end
				end
			end
		end
	end

end



function Validate_HEX_Color_Setting(HEX_COLOR)
local c = type(HEX_COLOR)=='string' and HEX_COLOR:gsub('[%s%c]','') -- remove empty spaces and control chars just in case
c = c and (#c == 3 or #c == 4) and c:gsub('%w','%0%0') or c -- extend shortened (3 digit) hex color code, duplicate each digit
c = c and #c == 6 and '#'..c or c -- adding '#' if absent
	if not c or #c ~= 7 or c:match('[G-Zg-z]+')
	or not c:match('#%w+') then return
	end
return c
end


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- trimming leading '#'
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function Get_Segment_Regions(reg_color)

local err
local retval, markr_cnt, reg_cnt = r.CountProjectMarkers(0)
	if reg_cnt == 0 then
	err = 'no regions in the project'
	end

local time_st, time_fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = time_st ~= time_fin
local reg_t = {}
local segm_reg_cnt, transcr_reg_cnt, transcr_reg_time_cnt

	if not err then
	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name, idx, color = r.EnumProjectMarkers3(0, i)
			if retval > 0 and isrgn then -- store all project regions so that if js_ReaScriptAPI extension is installed for scrolling Region/Marker Manager list, region entry exact index could be calculated based on its index in the table, the specific conditions to filter out irrelevant regions will be applied inside Replace_In_Segment_Regions()
			reg_t[#reg_t+1] = {color==reg_color and pos, rgnend, name, idx, color}
				if color == reg_color then
				segm_reg_cnt = 1
					if #name:gsub('[%s%c]','') > 0 then
					transcr_reg_cnt = 1
						if time_sel --and pos >= time_st and rgnend <= time_fin
						and (pos >= time_st and pos <= time_fin or rgnend >= time_st and rgnend <= time_fin
						or pos <= time_st and rgnend >= time_fin) then
						transcr_reg_time_cnt = 1
						end
					end
				end
			end
		i = i+1
		until retval == 0
	end


local err2 = 'no segment regions '
err = err or not segm_reg_cnt and err2..'\n\n     in the project'
or time_sel and not transcr_reg_time_cnt and ' '..err2..'\n\n    with transcript \n\n   in time selection'
or not transcr_reg_cnt and ' '..err2..'\n\n    with transcript'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	else
	return reg_t
	end

end



function Get_TCP_Under_Mouse() -- used inside Get_Marker_Reg_At_Time_OR_Mouse_Or_EditCursor()
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




function Get_Marker_Reg_At_Time_OR_Mouse_Or_EditCursor(time, want_mouse, want_prev_reg)
-- can be used to get marker/region at time or edit/mouse cursor if time is false/nil
-- without the need to traverse all of them
-- if want_mouse is true, relies on Get_TCP_Under_Mouse()

	local function get_next_prev_region(cur_pos, want_prev_reg)
	local i, proj_len = 0, r.GetProjectLength(0)
		repeat
		local incr = want_prev_reg and -0.1 or 0.1
		cur_pos = cur_pos+incr -- increment by 100 ms until a region is found
		local mrkr_idx, reg_idx = r.GetLastMarkerAndCurRegion(0, cur_pos)
			if reg_idx > -1 then return reg_idx end
		i=i+1
		until reg_idx > -1 or want_prev_reg and cur_pos <= 0 or not want_prev_reg and cur_pos >= proj_len -- if not found stop at the start/end of the project depending on direction
	end

local tr, info = r.GetTrackFromPoint(r.GetMousePosition())
-- ensuring that mouse cursor is over Arrange allows ignoring mouse position
-- when the script is run via toolbar button, menu item or from the Action list

local cur_pos = time or r.GetCursorPosition() -- store in case want_mouse is true

	if not time and want_mouse and tr and not Get_TCP_Under_Mouse() and info ~= 2 then -- not FX window
	r.PreventUIRefresh(1)
	r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
	end

local mrkr_idx, rgn_idx = r.GetLastMarkerAndCurRegion(0, cur_pos)
local t = {}
t.mrkr = mrkr_idx > -1 and {r.EnumProjectMarkers3(0,mrkr_idx)}
t.rgn = rgn_idx > -1 and {r.EnumProjectMarkers3(0,rgn_idx)}

	if not t.rgn then -- the cursor/time is outside a region or coincide with its end because EnumProjectMarkers() ignores region end
	-- marker invalid idx -1 is only possible when the cursor/time precedes the very first project marker, provided there're any
	-- so no function is needed to find the next valid marker because this will be the very 1st one in the project
	rgn_idx = get_next_prev_region(cur_pos, want_prev_reg)
	t.rgn = rgn_idx and {r.EnumProjectMarkers3(0,rgn_idx)}
	end

	if t.mrkr then table.insert(t.mrkr,1,t.mrkr[3] == cur_pos) end
	if t.rgn then table.insert(t.rgn,1,t.rgn[3] == cur_pos) end
-- fields:
-- 1 - true if marker or region start are exactly at the cur_pos, false if last marker before cur_pos
-- or region start before cur_pos
-- 2 - sequential index on the cur_pos line, same as mrkr_idx and rgn_idx
-- 3 - isrgn, 4 - position, 5 - rgn_end, 6 - name, 7 - displayed index, 8 - color
-- nil t.mrkr or t.rgn table - no marker or region respectively before or at the cur_pos

	if not time and want_mouse and r.GetCursorPosition() ~= cur_pos then -- restore
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
	r.PreventUIRefresh(-1)
	end

return t

end



function Replace_In_Segment_Regions(reg_t, repl_mode, search_term, replace_term, ignore_case, exact, mngr_wnd, cmdID)
-- reg_t stems from Get_Segment_Regions()
-- if ignore_case is true first the target word in original case must be found inside the line
-- in order to be able to replace it in the original line
-- searching by changing the line case is a wrong approach
-- because replacement must not affect the original case of all other words
-- and simple case change of the search term during search won't work
-- because this will still miss words with capitalized first letter, i.e. mixed case words;


	local function get_replace_term_bounds(st, line, replace_term)
	-- used inside replace_capture()
	-- to exclude unicode extra bytes before and within capture
	-- so that 1 character corresponds to 1 byte because text highliting inside the replacement dialogue in one-by-one mode is based on characters
	local st, fin = line:find(Esc(replace_term), st)
	local pre_capt_extra = select(2, line:sub(1,st-1):gsub('[\128-\191]',''))
	local capt_extra = select(2, replace_term:gsub('[\128-\191]',''))
	return st - pre_capt_extra, fin, fin - pre_capt_extra - capt_extra -- returning both original byte based fin value and adjusted character based one, the first is for storage as 'LAST SEARCH' data, the second is for text highlighting inside the replacement dialogue in one-by-one mode (wasn't implemented)
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
	local line_tmp = ignore_case and (rerun and convert_case_in_unicode(line) or line:lower()) or line -- using a line copy to be able to use the original to extract the original match below because it's the original which needs to be replaced
	local st_idx = fin or 1 -- fin ensures that the search continues from where it had left off to prevent endless loop inside parent function replace_capture() when search and replacement terms only differ in case because if ignore_case is true string.find will get stuck at the first replacement keeping returning valid capture endlessly
	local st, fin = line_tmp:find(s, st_idx)
		if st then
		return line:sub(st, fin), st, fin, line_tmp:sub(st, fin) -- st is only needed in one-by-one mode; last return value is only relevant when exact and ignore_case are true
		end
	end

	local function replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, rerun, i, start_idx)
	-- used inside search_and_replace()
	-- rerun is boolean to condition recursive run once when ignore_case is true but no replacement was done
	-- because no match was found due to search_term or notes contaning non-ASCII characters ignored by string.lower()
	-- in order to terty after converting non-ASCII characters to lower case

			-- this block only runs as long as i < start_idx which is only possible in modes 1 & 2
			-- when no replacements are supposed to be made
			-- in all other scenarios i < start_idx will be false
			if i and i < start_idx then -- count regions which contain the replace term but precede the replacement range start to be able to accurately scroll Region/Marker Manager list filered with the replace term towards the entry of the first segment regon in the range whose name was changed, in replacement modes 1 & 2 with the SWS extension, because filter will isolate out of range region entries as well where no replacements have been made and which may originally contain the replace term
			local preced_cnt, capt = 0
			local ignore_case = rerun and false or true -- ignore_case true if not rerun, because with regards to ASCII characters Region/Marker Manager filter is case agnostic so use lower case for the sake of match search, but for non-ASCII characters case matters
				if not exact then
				capt = get_capture(line, replace_term, ignore_case, exact, nil, rerun) -- fin is nil, will default to 1 inside the function as st_idx
				else
				-- regarding the choices in this loop see comments in the main routine below
				local pad = '[\0-\47\58-\64\91-\96\123-191]'
				local s = Esc(replace_term)
					for _, patt in ipairs({'^'..s..pad, pad..s..pad, pad..s..'$'}) do
					capt = get_capture(line, patt, ignore_case, exact, nil, rerun) -- fin is nil, will default to 1 inside the function as st_idx
						if capt then break end -- exit as soon as at least one match is found so its count corresponds to the line count
					end
				end

				if capt then
				preced_cnt = preced_cnt+1 -- increment by 1 only to match segment region count because segment region name may contain several matches which otherwise would be counted here as well and unnecessarily increase preceding region count
				elseif not rerun then -- 'not rerun' ensures that the recursive loop doesn't become endless and the block is only executed once
				return replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, 1, i, start_idx) -- rerun is true to only allow a single recursive run, otherwise an endless loop will be set off
				end

			-- return immediately because 1 found repace term match is enough so that the preced_cnt value is true to the overall count of preceding regions
			return nil, nil, nil, nil, 0, preced_cnt -- replace_cnt is 0 to prevent error in evaluation inside search_and_replace()
			end

	local replace_term = replace_term:gsub('%%','%%%%') -- must be escaped if contains % which is unlikley but just in case
	local fin, replace_cnt = pos_in_line, 0 -- pos_in_line (assigned to fin var) will be valid and st is only needed in one-by-one mode, fin is needed in one-by-one mode or otherwise to prevent search from getting stuck, see comment below
	local capt, st, count
		if not exact then
		capt, st, fin = get_capture(line, search_term, ignore_case, exact, fin, rerun) -- fin is returned to be passed as new start index inside string.find because if the search and replacement terms only differ in case while ignore_case is true, at each loop cycle string.find will get stuck at the first replacement leading to an endless loop because count and capt both will keep being valid; rerun arg is relevant in recursive run of the function to search after changing case of non-ASCII characters // st is only needed in one-by-one mode
			repeat
				if capt then
					if capt ~= replace_term then -- only replace a match which hasn't been replaced yet; when all have been replaced a message of no replacements will be shown
					capt = Esc(capt)
					line, count = line:gsub(capt, replace_term, 1) -- replace capture because it was retuned with the correct case, doing it 1 by 1 which is presumably safer and more reliable because string.gsub has a limit of 32 replacements
					replace_cnt = replace_cnt+count
						if one_by_one then break end
					end
				fin = fin + (#replace_term-#search_term) -- OR st + #replace_term // if replace term is mutli-word and terminated with the search term the search might get stuck, and in general the length difference between the search and replace terms must be accounted for when search continues in the updated line
				capt, st, fin = get_capture(line, search_term, ignore_case, exact, fin, rerun) -- prime for the next cycle
				else break end
			until count == 0 or not capt
		else
		-- patterns where the search term is only allowed to be padded with non-alphanumeric characters if 'Match exact word' option is enabled // 3 capture patterns are used because pattern with repetition * operator, e.g. '%W*'..s..'%W*', will match search term contained within words as well because '%W*' will also match alphanumeric characters hence unsuitable, start/end anchors are also meant to exclude alphanumeric characters in case the search term is only padded with non-alphanumeric character on one side
		local pad = '[\0-\47\58-\64\91-\96\123-191]' -- use punctuation marks explicitly by referring to their code points instead of %W because when the search term is surrounded with non-ASCII characters %W will match all non-ASCII characters in addition to punctuation marks so in these cases pattern such as '%W'..s..'%W' will fail to produce exact match and will return non-exact matches as well, the pattern range also includes control characters beyond code point 127 which is the end of ASCII range, codes source https://www.charset.org/utf-8
		local s = Esc(search_term)
			for _, patt in ipairs({'^'..s..pad, pad..s..pad, pad..s..'$'}) do -- in this order of captures, because if there're several matches in the line the one at the very beginning will be ignored in favor of the later ones if '^'..s..pad pattern is not the 1st
			local fin = fin or pos_in_line -- this ensures that pos_in_line value is maintained throughout the loop because if the search term isn't found at the 1st cycle the fin var will return as nil and being global will be fed as such back into get_capture() function where it will be assigned value 1 instead of pos_in_line and if the replace term contains the search term, its instance inserted earlier will end up being captured because the search will re-start from 1, i.e. if search term 'have' is replaced with 'must have' the replace term 'have' will keep being captured, resulting in 'must must must have' indefinitely // this would not be a poblem if get_capture() return values were local but they need to be accessible outside of this loop to be returned by this function in one-by-one mode so must remain global to this loop
			capt, st, fin, capt_low = get_capture(line, patt, ignore_case, exact, fin, rerun) -- fin is returned to be passed as new start index inside string.find because if the search and replacement terms only differ in case while ignore_case is true, at each loop cycle string.find will get stuck at the first replacement leading to an endless loop because count and capt both will keep being valid; rerun arg is relevant in recursive run of the function to search after changing case of non-ASCII characters // st is only needed in one-by-one mode // capt_low is the capture after lowering the case when ignore_case is true, will be used to construct replace pattern for replacement of the original capture returned as capt which maintains the original case of the match so it can be found and replaced with gsub
				repeat
					if capt then
						if not capt:match(Esc(replace_term)) then -- only replace a match which hasn't been replaced yet, using string.match because the capture will contain surrounding characters; when all have been replaced a message of no replacements will be shown
						-- if ignore_case is true, lower the s (search term) case to match its case inside capt_low string, which in this event will be a lower case copy of capt string which is the original match, to be able to find it and replace within capt_low thereby constructing a replacement pattern for the original match in the source string
						s = ignore_case and (rerun and convert_case_in_unicode(s) or s:lower()) or s
						local repl_patt = capt_low:gsub(s, replace_term) -- first replace the target word inside the capture to keep all punctuation characters included in capt
						capt, repl_patt = Esc(capt), repl_patt:gsub('%%','%%%%') -- repl_patt must be escaped if contains % which is unlikley but just in case
						line, count = line:gsub(capt, repl_patt, 1) -- replace along with the originally captured punctuation marks, doing it 1 by 1 which is presumably safer and more reliable because string.gsub has a limit of 32 replacements
						replace_cnt = replace_cnt+count

							if one_by_one then break end

						end

					fin = fin + (#replace_term-#search_term) -- OR st + #replace_term // if replace term is mutli-word and terminated with the search term the search might get stuck, and in general the length difference between the search and replace terms must be accounted for when search continues in the updated line
					capt, st, fin, capt_low = get_capture(line, patt, ignore_case, exact, fin, rerun) -- prime for the next cycle

					else break end

				until count == 0 or not capt

				if capt and one_by_one then break end -- exit the 'for' loop

			end -- 'for' loop end

		end

		-- if not found with ignore_case being true, retry lowering case of non-ASCII characters as long as they're present
		if replace_cnt == 0 and not rerun and ignore_case -- 'not rerun' ensures that the recursive loop doesn't become endless and the block is only executed once
		and (is_utf8(line) or is_utf8(search_term)) then -- only if non-ASCII characters are present, i.e. those containing trailing (continuation) bytes, because in this case after lowering the case with string.lower the match is likely to not be found despite being there
		return replace_capture(line, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, 1, i, start_idx) -- rerun is true to only allow a single recursive run, otherwise an endless loop will be set off
		end

	local fin_adj

		if one_by_one and capt then
		st, fin, fin_adj = get_replace_term_bounds(st, line, replace_term) -- subtracting extra (continuation or trailing) bytes in case text is non_ASCII so the value matches the actual character count // keeping orig fin value to store for the next cycle in 'LAST SEARCH' data because it all bytes must be taken account in it, fin_adj will be used for text highlighting inside Scroll_SWS_Notes_Window() where character count matters and not bytes
		end

	return line, st, fin, fin_adj, replace_cnt -- st, fin and fin_adj are only needed in one-by-one mode

	end


	local function search_and_replace(name, search_term, pos_in_line, replace_term, ignore_case, exact, one_by_one, i, start_idx)
	local name, st, fin, fin_adj, cnt, preced_cnt = replace_capture(name, search_term, replace_term, pos_in_line, ignore_case, exact, one_by_one, rerun, i, start_idx) -- st, fin, fin_adj are only relevant in one-by-one mode
	local replace_cnt = replace_cnt and replace_cnt + cnt or cnt
		if replace_cnt > 0 then
		return name, replace_cnt, preced_cnt, {fin, fin_adj, name, st} -- the last table return value is only relevant in one-by-one replacement mode
		elseif i and i < start_idx then -- if no replacements return nil or preced_cnt as long as region range start hasn't been reached in replacement modes 1-3
		return nil, nil, preced_cnt, nil -- adding nils as placeholders for return values which are irrelevant in this scenario to match the return values above
		end
	end


local repl_mode = tonumber(repl_mode)
local one_by_one = repl_mode == 4


-------------- INITIALIZE VARS -------------

-- Extract values of the last search to determine the region and line position it must be resumed from
local stored = r.GetExtState(cmdID, 'LAST SEARCH') -- contains track index, start line index, search term, search term end pos in line
local stored_t = {}
	if #stored > 0 then
	stored = stored..'\n' -- to capture last entry
		for entry in stored:gmatch('(.-)\n') do
		stored_t[#stored_t+1] = entry
		end
	end
-- OR
-- stored = stored..'\n' -- to capture last entry
-- local stored_t = stored:match(('(.-)\n'):rep(4))

local err = "\n\n the cursor is not followed \n\n\t   by any regions \n\n"
local time_st, time_fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = repl_mode == 1 and time_st ~= time_fin -- time sel is only relevant in mode 1
local t1 = Get_Marker_Reg_At_Time_OR_Mouse_Or_EditCursor(time_sel and time_st, 1) -- want_mouse true, get region at cursor in all replacement modes bar 0 (all) because they depend on it; when time_sel var is false due to mode not being 1, the function retrieves segment region at or immediately following the mouse/edit cursor

	if repl_mode%2 == 0 and not t1.rgn then -- applies to modes 2 (from cursor) and 4 (one by one)
	Error_Tooltip(err, 1, 1) -- caps, spaced true
	return end

local start_idx = (repl_mode == 1 and time_sel or repl_mode == 2) and t1.rgn[2]
or one_by_one and (stored_t[1] and stored_t[1]+0 or t1.rgn[2]) or 1 -- index is 1 in modes 0 and 3 // in one-by-one mode before the LAST SEARCH data have been stored if region is at cursor use its index (or the next), afterwards use index retrieved from the LAST SEARCH until the replace dialogue is exited
local t2 = Get_Marker_Reg_At_Time_OR_Mouse_Or_EditCursor(time_sel and time_fin, 1, 1) -- want_mouse and want_prev_reg true; ; when time_sel var is false due to mode not being 1, the function retrieves segment region at or immediately preceding the mouse/edit cursor

	if repl_mode == 3 and not t2.rgn then
	Error_Tooltip(err:gsub('followed','preceded'), 1, 1) -- caps, spaced true
	return end

local end_idx = (repl_mode == 1 and time_sel or repl_mode == 3) and t2.rgn[2] or #reg_t -- end index is #reg_t in modes 0 (all), 2 (from cursor) and 4 (one by one) // in one-by-one mode the replacement loop will be exited as soon as one replacement has been made

local pos_in_line = one_by_one and (stored_t[#stored_t] and stored_t[#stored_t]+0 or 1) -- value to be used as index argument in sting.find to mark location within line to resume the search from, if no stored value as is the case when the script is first launched default to 1 to start search from the beginning of the line
local t, reg_idx = {}
local preced_cnt_out, preced_cnt = 0 -- initialize count of segment regions which already contain the replacement term but precede the replacement range start to be able to accurately scroll Region/Marker Manager filtered with the replacement term towards the entry of the 1st region in the range with SWS extension in modes 1 & 2 because filtered list will include out of range region entries as well and reg_idx in this scenario will be useless being based on the absolute count while only a selection of regions will remain listed in the Manager
local prefer_sws = not r.JS_Window_Find or #PREFER_SWS_EXT_API:gsub(' ','') > 0
local filter_by_replace_term = one_by_one and #FILTER_BY_REPLACEMENT_TERM:gsub(' ','') > 0
local start = r.BR_Win32_FindWindowEx and prefer_sws and (repl_mode == 1 or repl_mode == 2 or filter_by_replace_term) and 1
or start_idx -- start from 1 to be able to count regions with replace term matches which precede the replacement range start for the sake of accurate scrolling of the Region/Marker Manager list filtered by the replace term in modes 1 & 2 with the SWS extension

local replace_cnt, cnt, upd_reg_name = 0

-----------------------------------------------------------------

	for i=start, end_idx do
	local pos, fin, name, idx, color = table.unpack(reg_t[i])
		if pos and #name:gsub(' ','') > 0 -- pos will be nil if not segment region
		and (repl_mode == 1 and (pos >= time_st and pos <= time_fin or fin >= time_st and fin <= time_fin
		or pos <= time_st and fin >= time_fin) or repl_mode ~= 1 or i < start_idx) then
		local pos_in_line = (t or filter_by_replace_term and i <= start_idx) and pos_in_line or 1 -- pos_in_line can be other than 1 in the 1st loop cycle only, because if the search term wasn't found in the name of the start search region and the search has proceded to the next region, it must begin from the very 1st character and in this case t var will be nil after being reset by an unsuccessful search in the 1st loop cycle below, THAT'S UNLESS filter_by_replace_term option is enabled to count segments regions whose name contains the replacement term and which precede the target segment region, in this case pos_in_line var is only reset to 1 once the loop iterator exceeds the target segment region index // ONLY RELEVANT IN ONE-BY-ONE MODE
		name, cnt, preced_cnt, t = search_and_replace(name, search_term, pos_in_line, replace_term, ignore_case, exact, one_by_one, i, start_idx) -- t return value is only relevant in one-by-one mode
		preced_cnt_out = preced_cnt and preced_cnt_out+preced_cnt or preced_cnt_out -- keep count of regions which already contain the replace term but precede the replacement range start
			if name then -- if no replacemens name var will be nil
			r.SetProjectMarker3(0, idx, true, pos, fin, name, color) -- overwrite name // isrgn true, the color is set only because it wasn't stored in the table
			replace_cnt = replace_cnt+cnt -- store to display the replacement result to the user in modes other than one-by-one
				if one_by_one then -- name of region at cursor has been updated
				reg_idx = i -- store to use for scrolling Region/Marker Manager window with sws extension
				r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..t[1], false) -- persist false // alongside segment region index only store end pos within name
				r.SetEditCurPos(pos, true, true) -- moveview, seekplay true
				break -- in one by one replacement mode exit as soon as one segment region has been processed
				end
			upd_reg_name = upd_reg_name or name -- store name of the 1st region where replacement was made for scrolling with js extension in modes other than one_by_one
			end
		end
	end


preced_cnt_out = one_by_one and preced_cnt_out > 0 and stored_t[1] and preced_cnt_out+1 or preced_cnt_out -- when the replacement loop in one-by-one mode first starts, the LAST SEARCH data are absent and once the match is found its line index is stored first time in the LAST SEARCH data, in the 2nd cycle start_idx is assigned this line index and since preced_cnt_out var stores the count of lines preceding the start_idx value the result is the same line count in the 2nd cycle as it was in the very 1st cycle after which it remains consistently offset by 1 making the Manager scrolled towards the segment region entry where the replacement was made in the previous cycle, so the expression here corrects this offset by adding 1 when stored LAST SEARCH data exist and holds line index value which lags behind the current one by 1 position; this correction doesn't of course affect the count for modes other than one-by-one

	if one_by_one and (start_idx > 1 or pos_in_line > 1) and not t then -- OR not reg_idx // if in one-by-one mode after searching from a segment region other than the 1st or not from very start of its name and the search term wasn't found, restart from the 1st segment region continue until the segmenr region the search originally started from to scan the so far non-scanned part of the transcript
	preced_cnt_out = 0 -- reset since the search will return to the start which isn't preceded by anything
		for i=1, start_idx do
		local pos, fin, name, idx, color = table.unpack(reg_t[i])
			if pos then-- pos will be nil if not segment region
			name, cnt, preced_cnt, t = search_and_replace(name, search_term, 1, replace_term, ignore_case, exact, one_by_one) -- pos_in_line is 1; t return value is only relevant in one-by-one mode
				if name then -- if no replacemens will be nil
				r.SetProjectMarker3(0, idx, true, pos, fin, name, color) -- overwrite name // isrgn true, the color is set only because it wasn't stored in the table
				replace_cnt = replace_cnt+cnt -- store to display the replacement result to the user in modes other than one-by-one, still leaving for consistency to be used in this mode to condition message of no replacements
				reg_idx = i -- store to use for scrolling Region/Marker Manager window with sws extension
				r.SetExtState(cmdID, 'LAST SEARCH', i..'\n'..t[1], false) -- persist false // alongside segment region index only store end pos within name
				r.SetEditCurPos(pos, true, true) -- moveview, seekplay true
				break -- in one by one replacement mode exit as soon as one segment region has been processed
				end
			end
		end
	end


-- Construct result message ------
local mess = ' replacements \n\n have been made'
local repl_dest = repl_mode == 0 and '\n\n in all segment regions'
or repl_mode == 1 and '\n\n in segment regions \n\n within time selection'
or repl_mode == 2 and '\n\n in segment regions \n\n following the cursor'
or repl_mode == 3 and '\n\n in segment regions \n\n preceding the cursor'
mess = not one_by_one and replace_cnt > 0
and math.floor(replace_cnt)..mess..repl_dest
or (one_by_one and replace_cnt == 0 or not one_by_one)
and 'no'..mess..(one_by_one and '' or repl_dest)..' \n\n or all matches \n\n have been replaced.' -- in one-by-one mode only display message if no replacements have been made, in one-by-one mode t could be used as a condition instead of replace_cnt in the previous line
	if mess then
	Error_Tooltip('\n\n '..mess..' \n\n', 1, 1, 200) -- caps, spaced true, x is 200 to move the tooltip away from the cursor so it doesn't stand between the cursor and search/replace dialogue OK button and doesn't block the click
	end
----------------------------------

	if replace_cnt > 0 then -- this will be valid for all 5 replacement modes
		if one_by_one then
		return reg_idx, t[4], t[2], t[3], replace_cnt, preced_cnt_out -- from the t table return replacement term start/end within name to highlight it inside additional field of the replacement dialogue (haven't been implemented) and updated segment text; replace count is returned to condition undo in the main routine, preced_cnt_out is returned to scroll the Manager to the entry of the 1st region in the range whose transcript was edited in the list filtered by the replace term when the sws extension is used
		else
		return reg_idx, nil, nil, upd_reg_name, replace_cnt, preced_cnt_out -- upd_reg_name is returned when js extension is used to find the region entry in the Manager and scroll to, replace count is returned to condition undo in the main routine, preced_cnt_out is returned to scroll the Manager to the entry of the 1st region in the range whose transcript was edited in the list filtered by the replace term when the sws extension is used; adding nils as placeholders for return values which are irrelevant in this scenario to match the return values above otherwise replace_cnt will be treated as replacement term start return value outside
		end
	end

end



function replace_term_lower(replace_term)

-- since in the Region/Marker Manager upper case AND, OR and NOT are used as operators
-- they won't filter the items therefore their case must be lowered
	for k, v in ipairs({'AND', 'OR', 'NOT'}) do
		if replace_term == v then return replace_term:lower() end
	-- otherwise parse the entire replace_term in search for the operators
	local i = 1
		repeat
		local st, fin = replace_term:find(v,i)
			-- if the capture is preceded or followed by an alphanumeric character
			-- it's a word containing the operator so its case doesn't need lowering because it's not standalone
			if st and not replace_term:sub(st-1, st-1):match('%w')
			and not replace_term:sub(fin+1, fin+1):match('%w')
			then
			local t = replace_term
			local part1, part2 = st == 1 and '' or t:sub(1,st-1), fin == #replace_term and '' or t:sub(fin+1)
			replace_term = part1..t:sub(st,fin):lower()..part2 -- reconstruct, gsub is unsuitable because it replaces regardless of whether capture is standalone or nested
			elseif not st then break -- no capture was found
			end
		i = st and fin+1 or i+1
		until not st or i > #replace_term
	end

return replace_term

end



function DEFERRED_WAIT()
	if r.time_precise() - time_init >= 0.2 then -- less than 0.2 isn't always enough for the floating Manager window
	Scroll_Region_Mngr_To_Item_JS(nil, reg_name) -- rgn_mngr_closed arg is nil as unnecessary
	return end
r.defer(DEFERRED_WAIT)
end


function RESTART_FROM_DEFER(cmdID)
r.Main_OnCommand(cmdID, 0)
end


function Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.defer() and r.atexit()
-- func is function name, the elipsis represents the list of function arguments
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


REG_COLOR = Validate_HEX_Color_Setting(SEGMENT_REGION_COLOR)

local err = 'the segment_region_color \n\n'
err = #SEGMENT_REGION_COLOR:gsub(' ','') == 0 and err..'\t  setting is empty'
or not REG_COLOR and err..'\t setting is invalid'

	if err then
	Error_Tooltip("\n\n "..err.." \n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

local theme_reg_col = r.GetThemeColor('region', 0)
REG_COLOR = r.ColorToNative(table.unpack{hex2rgb(REG_COLOR)})

	if REG_COLOR == theme_reg_col then
	Error_Tooltip("\n\n the segment_region_color \n\n\tsetting is the same\n\n    as the theme's default"
	.."\n\n     which isn't suitable\n\n\t   for the script\n\n", 1, 1) -- caps, spaced true
	return r.defer(no_undo) end

REG_COLOR = REG_COLOR+0x1000000 -- convert color to the native format returned by object functions

local filter_by_transcr = #FILTER_BY_SEGMENT_TRANSCRIPT:gsub(' ','') > 0
local filter_by_repl_term = #FILTER_BY_REPLACEMENT_TERM:gsub(' ','') > 0
local js, sws = r.JS_Window_Find, r.BR_Win32_FindWindowEx
local prefer_sws = not js or #PREFER_SWS_EXT_API:gsub(' ','') > 0
local mngr_wnd = sws and prefer_sws and Find_Window_SWS('Region/Marker Manager', want_main_children) -- want_main_children nil
local mngr_child_t = sws and prefer_sws and Get_Child_Windows_SWS(mngr_wnd)
or Get_Child_Windows_JS('Region/Marker Manager', false) -- want_exact false to include docked window name

local current_segm -- used to display last edited segment transcript in the replacement dialogue when js extension is used in mode 4

::CONTINUE::

local reg_t = Get_Segment_Regions(REG_COLOR)

	if not reg_t then -- error is generated inside Get_Segment_Regions()
	return r.defer(no_undo) end

local is_new_value, scr_name, sect_ID, cmdID_init, mode, resol, val, contextstr = r.get_action_context()
cmdID = r.ReverseNamedCommandLookup(cmdID_init)

local replace_sett = r.GetExtState(cmdID, 'REPLACE SETTINGS')
local sep = '`'

-----------  R E P L A C E  D I A L O G U E  S E T T I N G S ----------------

local ext = r.GetExtState(cmdID, 'UPDATED SEGMENT') -- ext state is stored when the script uses js extension to scroll the Manager in mode 4 and the Manager filter contains the replacement term which requires scrolling with DEFERRED_WAIT() function and current_segm var won't work when the script is restarted after defer loop termination
current_segm = current_segm or #ext > 0 and ext

local output_t, output = GetUserInputs_Alt('REPLACE IN TRANSCRIPT (insert any character to enable settings 3 and 4)', 5, '1. Replace target:,2. Replace with:,3. Match case (register):,4. Match exact word:,5. Mode (h for Help):', replace_sett, sep, current_segm and 1, current_segm) -- autofill the dialogue with the last search settings, comment_field is 1, true, in the comment field the currently edited segment will be displayed in one-by-one mode

	if not output_t or #output_t[1]:gsub(' ','') == 0 then -- all fields are empty or the search term field only
	r.DeleteExtState(cmdID, 'LAST SEARCH', true) -- persist true // the search ext state data stored inside Search_Track_Notes() are kept as long as the search dialogue is kept open in which case the script keeps running or if the search is run headlessly while the script is armed; the data are only deleted when the dialogue is exited
	r.DeleteExtState(cmdID, 'UPDATED SEGMENT', true) -- persist true
	return r.defer(no_undo) end

r.SetExtState(cmdID, 'REPLACE SETTINGS', output, false) -- persist false // keep latest search settings during REAPER session to autofill the search dialogue when it's opened and to get them in the headless search

local search_term = output_t[1]
local replace_term = output_t[2]
local ignore_case = not validate_output(output_t[3])
local exact = validate_output(output_t[4])
local repl_mode = #output_t[5]:gsub(' ','') > 0 and output_t[5]

	if not repl_mode then
	Error_Tooltip("\n\n\treplace mode \n\n has not been selected \n\n", 1, 1, 200) -- caps, spaced true, x is 200 to move the tooltip away from the dialogue OK button beause its blocks the click
	end


local valid_vals = 'Valid values are:\n\n0 — batch replace in all segment regions\n\n'
..'1 — batch replace in segment regions within time selection\n\n2 — batch replace from the edit/mouse cursor onwards'
..'\n\n3 — batch replace up to the edit/mouse cursor\n\n4 — replace word by word from mouse/edit cursor\n\n'
local is_num = repl_mode and repl_mode:match('^%s*([\1-\255])%s*$') -- accounting for non-ASCII input by the user, otherwise is_num will end up being nil


	if is_num and is_num:match('[hH]') then
	r.MB(valid_vals,'HELP',0)
	is_num = nil -- to trigger CONTINUE loop below
	elseif repl_mode then -- only if replace mode field is filled out to not supercede the error tooltip generated above when no mode has beens selected
	local time_st, time_fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
	is_num = tonumber(repl_mode)
	local err = (not is_num or is_num and math.floor(is_num) ~= is_num or is_num < 0 or is_num > 4)
	and 'INVALID REPLACE MODE "'..output_t[5]..'".\n\n'..valid_vals
		if err then
		r.MB(err, 'ERROR', 0)
		is_num = nil -- to trigger CONTINUE loop below
		elseif is_num == 1 and time_st == time_fin then
		Error_Tooltip("\n\n no active time selection \n\n", 1, 1, 200) -- caps, spaced true, x is 200 to move the tooltip away from the dialogue OK button beause its blocks the click
		is_num = nil -- to trigger CONTINUE loop below
		end
	end


	if not is_num then
	goto CONTINUE
	else
	r.Undo_BeginBlock()
	local reg_idx, st, fin, upd_reg_name, replace_cnt, preced_cnt = Replace_In_Segment_Regions(reg_t, repl_mode, search_term, replace_term, ignore_case, exact, mngr_wnd, cmdID)
	local undo = ' in segments '
	undo = is_num == 0 and undo:gsub('in', '%0 all') or is_num < 4 and undo..(is_num == 1 and 'within time selection'
	or is_num == 2 and 'following the cursor' or is_num == 3 and 'preceding the cursor') or reg_idx and ' in region '..reg_idx
	undo = replace_cnt and replace_cnt > 0 and 'Transcribing A: Replace '..search_term..' with '..replace_term..undo
	r.Undo_EndBlock(undo or r.Undo_CanUndo2(0) or '',-1) -- prevent display of the generic 'ReaScript: Run' message in the Undo readout generated if no replacements were made following Undo_BeginBlock(), this is done by getting the name of the last undo point to keep displaying it, if empty space is used instead the undo point name disappears from the readout in the main menu bar
		if not undo and is_num == 4 then goto CONTINUE
		elseif undo then -- undo cond will only be true when some replacements were made, only in this case there's point to proceed

			if (js or sws) and r.GetToggleCommandStateEx(0, 40326) == 0 then -- View: Show region/marker manager window // the Manager is initially closed // only open it if at least one of the extension is installed otherwise it's pointless
			r.Main_OnCommand(40326,0) -- View: Show region/marker manager window // toggle to open

				if (sws or prefer_sws) then -- will be required if Region/Marker Manager is initially closed beause in this case the data won't be retrieved upstream of the CONTNIUE statement // when using js_ReaScriptAPI extention the window pointers are retrieved inside the scrolling function Scroll_Region_Mngr_To_Item_JS()
				mngr_wnd = Find_Window_SWS('Region/Marker Manager', want_main_children) -- want_main_children nil
				mngr_child_t = Get_Child_Windows_SWS(mngr_wnd)
				elseif js then
				mngr_child_t = Get_Child_Windows_JS('Region/Marker Manager', false) -- want_exact false to include docked window name
				end
			end

			if js and not prefer_sws then -- in any mode
				if is_num == 4 and Is_Filter_Field_FilledOut_JS(mngr_child_t, replace_term) then -- mngr_child_t is meant to allow evaluation of filter field state // if Manager list is filtered with the replacement term its window won't be able to update fast enough to display the latest edited segment transcript before the dialogue is re-opened in one-by-one mode, therefore give it time by running DEFERRED_WAIT(), after which the script will be terminated and relaunched
				time_init = r.time_precise() -- initialize to compare elapsed time inside DEFERRED_WAIT(), must be global to be accesible there
				reg_name = upd_reg_name -- initialize global copy of updated segment transcr string to be accessible within the deferred function
				DEFERRED_WAIT()
				else
				-- scrolling with js extention function doesn't depend on the number of items in the Manager's list
				-- because the relevant item is searched by name
				Scroll_Region_Mngr_To_Item_JS(nil, upd_reg_name) -- rgn_mngr_closed arg is nil as unnecessary
				end

			elseif sws then
				if is_num == 4 and not filter_by_repl_term then -- one-by-one mode
					if filter_by_transcr then -- insert updated segment transcript into the Manager's filter field to isolate region entry
					Insert_String_Into_Field_SWS(mngr_child_t, upd_reg_name)
					else -- scroll
					-- scrolling with the sws extension does depend on the number of items in the Manager's list
					-- because the relevant item is searched by its index, so the Manager must necessarily
					-- only list regions, to ensure this display settings must be adjusted if necessary
					local scroll = Manage_Region_Mrkr_Mngr_Settings(mngr_child_t)
						if scroll then -- scroll var will be nil if region entries (or actually all entries) aren't sorted by start in ascending order
						Scroll_Region_Marker_Mngr_SWS(mngr_child_t, reg_idx)
						end
					end
				else -- mode other than 4 or 4 and filter_by_repl_term
					if is_num == 4 and filter_by_repl_term or is_num ~= 4 then
					replace_term = replace_term_lower(replace_term) -- lower the case of the words AND/OR/NOT in the replace term so that they're inserted into the Manager's filter field in the lower case because uppercase AND/OR/NOT is a syntax reserved for filter operators and they won't filter the entries in the list, otherwise the Manager filter is case agnostic as far as ASCII characters are concerned
					replace_term = exact and '"'..replace_term..'"' or replace_term -- in REAPER filters respect double quotation marks as exact operator
					Insert_String_Into_Field_SWS(mngr_child_t, replace_term) -- insert into the Region/Marker Manager filter field so that all target segment region entries are listed
					end
				local scroll = Manage_Region_Mrkr_Mngr_Settings(mngr_child_t)
					if scroll then -- scroll var will be nil if regions aren't sorted by start in ascending order
					local scroll_distance = (is_num == 4 and filter_by_repl_term or is_num ~= 4) and preced_cnt+1 or reg_idx -- +1 because preced_cnt value unlike reg_idx doesn't include target line which is subtracted inside the function // IF Insert_String_Into_Field_SWS() FUNCTION ISN'T USED TO FILTER THE MANAGER LIST, USE reg_idx INSTEAD OF preced_cnt
					Scroll_Region_Marker_Mngr_SWS(mngr_child_t, scroll_distance)
					end
				end

			end -- js and not prefer_sws cond end

			-- one-by-one mode, regardless of extensions being installed
			if is_num == 4 then
				if not time_init then -- one-by-one mode, if DEFERRED_WAIT() hasn't been launched to scroll the Manager with js extension otherwise DEFERRED_WAIT() will be blocked by the re-opened dialogue and won't be able to complete its task
				current_segm = upd_reg_name -- store updated segment transcript to display in the replace dialogue
				goto CONTINUE
				else -- DEFERRED_WAIT() has been launched when js extension is used and the Manager list is filtered with the replacement term
				r.SetExtState(cmdID, 'UPDATED SEGMENT', upd_reg_name, false) -- persist false // store to be able to display the last edited segment transcript in the gialogue after DEFERRED_WAIT() exits and the script is re-launched because at that point current_segm var from above would have been invalid if it were initialized
				end
			end

		end -- undo cond end

	end



	if time_init then
		-- if DEFERRED_WAIT() has been launched (time_init vat is valid)
		-- set the script to relaunch after termination and re-launch as an action
		-- with Main_OnCommand() via atexit(), Main_OnCommand() alone won't work because
		-- no function is registered at termination apart from atexit(),
		-- all that is because using 'goto CONTINUE' while the defer loop is running sets off an endless loop
		if r.set_action_options then r.set_action_options(1|2) end -- set to re-launch after termination, supported since build 7.03
		-- script flag for auto-relaunching after termination in reaper-kb.ini is 516, e.g. SCR 516, but if changed
		-- directly while REAPER is running the change doesn't take effect, so in builds older than 7.03 user input is required
		r.atexit(Wrapper(RESTART_FROM_DEFER, cmdID_init))
	end



