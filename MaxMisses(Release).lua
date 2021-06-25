local ref = gui.Reference("Ragebot", "Accuracy")
local guiSettingsBlock = gui.Groupbox(ref, "Max Misses", 16, 550, 295, 250);
local guiClearKey = gui.Keybox(guiSettingsBlock , "clear_key", "Clear statistics (Manual)", 0);
local guiMissesSlider = gui.Slider(guiSettingsBlock, "miss_slider", "Count of max misses", 1, 1, 10);

-- Class
local wTypes = { 'shared', 'zeus', 'pistol', 'hpistol', 'smg', 'rifle', 'shotgun', 'scout', 'asniper', 'sniper', 'lmg' };
--

--Temp Vars
local cfgSaved = false;
local baimSetted = false;
local oldHitBoxses = {};
local shotsList = {};
local shotsCount = 0;
local missCount = 0;
--

-- Fonts
local courierFont = draw.CreateFont("Courier New", 15);
local courierFont2 = draw.CreateFont("Courier New", 12);
--

function split(str, character)
  result = {}

  index = 1
  for s in string.gmatch(str, "[^"..character.."]+") do
    result[index] = s
    index = index + 1
  end

  return result
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

local function event_handler(event)
	if event:GetName() == "weapon_fire" then
		if entities.GetByUserID(event:GetInt("userid")):GetIndex() == entities.GetLocalPlayer():GetIndex() then
			if input.IsButtonDown(1) then return; end
			
			table.insert(shotsList, {globals.TickCount(), false});
			shotsCount = shotsCount + 1;
			print("[SHOT] Registred");
		end
	elseif event:GetName() == "player_hurt" then
		if not shotsList[1] then return; end
		
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
		
		print("[HIT] Registred");
		if shotsCount then
			shotsList[shotsCount][2] = true;
		end
	elseif event:GetName() == "round_start" then
		restore_user_cfg();
		cfgSaved = false;
		baimSetted = false;
		shotsList = {};
		shotsCount = 0;
		missCount = 0;
	end
end

local function shots_handler()
	if not shotsList[1] then return; end

	for i = 1, #shotsList do
		if not shotsList[i][2] then
			local localPlayer = entities.GetLocalPlayer();
			local playerResources = entities.GetPlayerResources();
			iPing = playerResources:GetPropInt("m_iPing", localPlayer:GetIndex());

			if i == shotsCount then
				if globals.TickCount() - shotsList[i][1] < iPing then
					goto continue;
				end
			end
			missCount = missCount + 1;
			print("[MISS] a.ch ticks ["..globals.TickCount() - shotsList[i][1].."] | side ["..math.random(0,3).."]");
		end
		
		table.remove(shotsList, i);
		shotsCount = shotsCount - 1;
		::continue::
	end
end

local function self_connection_handler()
	if not entities.GetLocalPlayer() then
		shotsList = {};
		shotsCount = 0;
		missCount = 0;
	end
end

local function miss_handler()
	if not entities.GetLocalPlayer() then return; end
	
	if guiClearKey:GetValue() ~= 0 then
		if input.IsButtonDown(guiClearKey:GetValue()) then
			shotsList = {};
			shotsCount = 0;
			missCount = 0;
		end
	end
	
	if missCount >= guiMissesSlider:GetValue() then
		if not cfgSaved then
			save_user_cfg();
			cfgSaved = true;
		end
		if not baimSetted then
			set_baim();
			baimSetted = true;
		end
	else
		if cfgSaved then
			restore_user_cfg();
			cfgSaved = false;
		end
	end
end

local function on_lua_unload()
	restore_user_cfg();
end

-- Get rights for listeners
client.AllowListener("weapon_fire");
client.AllowListener("player_hurt");
client.AllowListener("round_start");
--

callbacks.Register("Draw", miss_handler);
callbacks.Register("FireGameEvent", event_handler);
callbacks.Register("Draw", shots_handler);
callbacks.Register("Draw", self_connection_handler);
callbacks.Register("Unload", on_lua_unload);
