local ref = gui.Reference("Ragebot", "Accuracy")
local screenSizeX, screenSizeY = draw.GetScreenSize();
local guiSettingsBlock = gui.Groupbox(ref, "Max Miss", 16, 500, 295, 250);
local guiClearKey = gui.Keybox(guiSettingsBlock , "clear_key", "Clear statistics (Manual)", 0);
local guiMissesSlider = gui.Slider(guiSettingsBlock, "miss_slider", "Count of misses", 1, 1, 10);
local guiListViewX = gui.Slider(guiSettingsBlock, "listview_x", "Logger Positon (Left)", 500, 0, screenSizeX);
local guiListViewY = gui.Slider(guiSettingsBlock, "listview_y", "Logger Positon (Top)", 500, 0, screenSizeY);
local guiLoggerBackColor = gui.ColorPicker(guiSettingsBlock, "listview_back_color", "Logger Background Color", 0, 0, 0, 255);
local guiLoggerTextColor = gui.ColorPicker(guiSettingsBlock, "listview_text_color", "Logger Text Color", 255, 255, 255, 255);
local guiLoggerMarginColor = gui.ColorPicker(guiSettingsBlock, "listview_margin_color", "Logger Margin Color", 74, 224, 72, 255);
local guiLoggerYesColor = gui.ColorPicker(guiSettingsBlock, "listview_yes_color", "Logger \"Yes\" Color", 224, 72, 72, 255);
local guiLoggerNopeColor = gui.ColorPicker(guiSettingsBlock, "listview_nope_color", "Logger \"Nope\" Color", 74, 224, 72, 255);

local PlayersList = {};
local lastSimtime = {};
local wTypes = { 'shared', 'zeus', 'pistol', 'hpistol', 'smg', 'rifle', 'shotgun', 'scout', 'asniper', 'sniper', 'lmg' }

local isFired = false;
local isHit = false;
local cfgChanged = false;
local aimTarget = nil;
local oldHitBoxses = {};
local courierFont = draw.CreateFont("Courier New", 15);
local courierFont2 = draw.CreateFont("Courier New", 12);

function split(str, character)
  result = {}

  index = 1
  for s in string.gmatch(str, "[^"..character.."]+") do
    result[index] = s
    index = index + 1
  end

  return result
end

local function GetSizeOfLargestName()
	local maxW = 0;
	for i = 1, #PlayersList do
		local playernfo = PlayersList[i];
		local nameSizeW, nameSizeH = draw.GetTextSize(playernfo[1]);
		
		if not maxW then
			maxW = nameSizeW;
		elseif maxW < nameSizeW then
			maxW = nameSizeW;
		end
	end
	
	return maxW;
end

local function find_player(name)
	local playerIndex = 0;
	for i = 1, #PlayersList do
		local playerInfo = PlayersList[i];
		
		if playerInfo[1] == name then
			playerIndex = i;
			break;
		end
	end
	return playerIndex;
end

local function fill_players_list()
	local localPlayer = entities.GetLocalPlayer();
	local EntityList = entities.FindByClass("CCSPlayer");
	
    for i = 1, #EntityList do
        local entity = EntityList[i];

        if entity:IsPlayer() and entity:IsAlive() and entity:GetTeamNumber() ~= localPlayer:GetTeamNumber() then
			local playerName = entity:GetName();

			if find_player(playerName) == 0 then
				table.insert(PlayersList, {playerName, 0});
			end
        end
    end
end

local function save_user_cfg()
	for i=1, #wTypes do
		oldHitBoxses[i] = gui.GetValue("rbot.hitscan.points."..wTypes[i]..".scale");
	end
end

local function set_baim()
	for i=1, #wTypes do
		local tempHitbox = split(oldHitBoxses[i], " ");
		tempHitbox[1] = "0";
		tempHitbox[3] = "0";
		tempHitbox[6] = "0";
		tempHitbox[7] = "0";
		tempHitbox[8] = "0";

		if tempHitbox[2] == "0" and tempHitbox[4] == "0" and tempHitbox[5] == "0" then
			tempHitbox[2] = "1";
			tempHitbox[4] = "2";
			tempHitbox[5] = "3";
		end
		
		local tempHitbox2 = "";
		for x=1, #tempHitbox do
			if x ~= 1 then
				tempHitbox2 = tempHitbox2 .. " ";
			end
		
			tempHitbox2 = tempHitbox2 .. tempHitbox[x]; 
		end
		
		gui.SetValue("rbot.hitscan.points."..wTypes[i]..".scale", tempHitbox2);
	end
end

local function restore_user_cfg()
	for i=1, #wTypes do
		if oldHitBoxses[i] ~= nil then
			gui.SetValue("rbot.hitscan.points."..wTypes[i]..".scale", oldHitBoxses[i]);
		end
	end
end

local function draw_lua_info()
	if not entities.GetLocalPlayer() or not PlayersList[1] then return; end
	
	if guiClearKey:GetValue() ~= 0 then
		if input.IsButtonPressed(guiClearKey:GetValue()) then
			for i = 1, #PlayersList do
				PlayersList[i][2] = 0;
			end
		end
	end
	
	draw.SetFont(courierFont);
	
	local leftMargin = 5;
	local firstColumnSize = 55;
	local secondColumnSize = GetSizeOfLargestName() + 45;
	local thridColumnSize = 100;
	local fourthColumnSize = 70;
	local tablePosX = guiListViewX:GetValue();
	local tablePosEndX = leftMargin + tablePosX + firstColumnSize + secondColumnSize + thridColumnSize + fourthColumnSize;
	local tablePosY = guiListViewY:GetValue();
	local tablePosEndY = tablePosY + 19;
	
	draw.Color(guiLoggerBackColor:GetValue());
	draw.FilledRect(tablePosX, tablePosY, tablePosEndX, tablePosEndY);
	
	draw.Color(guiLoggerTextColor:GetValue());
	draw.TextShadow(leftMargin + tablePosX, tablePosY + 4, "ID");
	draw.TextShadow(leftMargin + tablePosX + firstColumnSize, tablePosY + 4, "NAME");
	draw.TextShadow(leftMargin + tablePosX + firstColumnSize + secondColumnSize,  tablePosY + 4, "HITBOX");
	draw.TextShadow(leftMargin + tablePosX + firstColumnSize + secondColumnSize + thridColumnSize,  tablePosY + 4, "MISSES");
	--
	
	local r, g, b, a = guiLoggerBackColor:GetValue();

	local currentY = tablePosEndY;
	for i = 1, #PlayersList do
		local playerInfo = PlayersList[i];
		local playerHitboxes = "";
		
		draw.Color(r, g, b, 110);
		draw.FilledRect(tablePosX, currentY, tablePosEndX, currentY + 19);
			
		draw.Color(guiLoggerMarginColor:GetValue());
		draw.FilledRect(tablePosX, currentY + 1, tablePosX + leftMargin - 2, currentY + 18);
		
		draw.Color(guiLoggerTextColor:GetValue());
		draw.TextShadow(leftMargin + tablePosX, currentY + 4, i);
		draw.TextShadow(leftMargin + tablePosX + firstColumnSize, currentY + 4, playerInfo[1]);
				
		if playerInfo[2] >= guiMissesSlider:GetValue() then
			draw.Color(guiLoggerYesColor:GetValue());
			playerHitboxes = "ONLY BODY";
		else
			draw.Color(guiLoggerNopeColor:GetValue());
			playerHitboxes = "ALL";
		end
		
		draw.TextShadow(leftMargin + tablePosX + firstColumnSize + secondColumnSize,  currentY + 4, playerHitboxes);
		
		draw.Color(guiLoggerTextColor:GetValue());
		draw.TextShadow(leftMargin + tablePosX + firstColumnSize + secondColumnSize + thridColumnSize,  currentY + 4, playerInfo[2]);
		
		currentY = currentY + 19;
	end
end

local function event_handler(event)
	if event:GetName() == "player_disconnect" then
		local playerIndex = find_player(event:GetString("name"));
		if playerIndex then
			table.remove(PlayersList, playerIndex);
		end
	elseif event:GetName() == "round_start" then
		PlayersList = {};
		fill_players_list();
		isFired = false;
		isHit = false;
		aimTarget = nil;
	else
		if not aimTarget then return; end
		
		if event:GetName() == "weapon_fire" then
			if entities.GetByUserID(event:GetInt("userid")):GetIndex() == entities.GetLocalPlayer():GetIndex() then
				if not aimTarget:GetIndex() then return; end
				isFired = true;
			end
		elseif event:GetName() == "player_hurt" then
			local localPlayer = entities.GetLocalPlayer();
			local localIndex = localPlayer:GetIndex();
			local localTeam = localPlayer:GetTeamNumber();
			local victim = entities.GetByUserID(event:GetInt("userid"));
			local victimIndex = victim:GetIndex();
			local attacker = entities.GetByUserID(event:GetInt("attacker"));
			local attackerIndex = attacker:GetIndex();
			
			if attackerIndex ~= localIndex then
				return;
			end
			
			if localTeam == victim:GetTeamNumber() then
				return;
			end
			
			if aimTarget:GetIndex() == victimIndex then
				isHit = true;
			end
		end
	end
end

local function shots_handler()
	if not aimTarget then return; end
	
	if not aimTarget:GetIndex() then return; end
	
	if isFired then
		local targetIndex = find_player(aimTarget:GetName());
		
		if not isHit then
			PlayersList[targetIndex][2] = PlayersList[targetIndex][2] + 1;
		end
		isHit = false;
		isFired = false;
	end
end

local function aimbot_target_hook(pEntity)
    aimTarget = pEntity;
end

local function baim_handler()
	if not aimTarget then return; end
	
	if not aimTarget:GetIndex() then return; end
	
	local targetIndex = find_player(aimTarget:GetName());	
	if PlayersList[targetIndex][2] >= guiMissesSlider:GetValue() then
		if not cfgChanged then
			save_user_cfg();
			cfgChanged = true;
		end
		set_baim();
	else
		if cfgChanged then
			restore_user_cfg();
			cfgChanged = false;
		end
	end
end

local function self_connection_handler()
	if not entities.GetLocalPlayer() then
		if PlayersList[1] then
			PlayersList = {};
			isFired = false;
			isHit = false;
			aimTarget = nil;
		end
	end
end

local function on_lua_unload()
	restore_user_cfg();
end

client.AllowListener("player_disconnect");
client.AllowListener("weapon_fire");
client.AllowListener("player_hurt");
client.AllowListener("round_start");

callbacks.Register("Draw", fill_players_list);
callbacks.Register("Draw", draw_lua_info);
callbacks.Register("FireGameEvent", event_handler);
callbacks.Register("AimbotTarget", aimbot_target_hook);
callbacks.Register("Draw", baim_handler);
callbacks.Register("Draw", shots_handler);
callbacks.Register("Draw", self_connection_handler);
callbacks.Register("Unload", on_lua_unload);