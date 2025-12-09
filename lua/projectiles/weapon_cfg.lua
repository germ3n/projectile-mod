AddCSLuaFile();

local is_function = isfunction;
local tonumber = tonumber;
local tostring = tostring;

local WEAPON_BLACKLIST = {};

local HL2_WEAPON_CLASSES = {
    "weapon_pistol",
    "weapon_357",
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_ar2",
};

local WEAPON_SPEEDS = {
    ["weapon_pistol"] = 2000,
    ["weapon_357"] = 500,
    ["weapon_shotgun"] = 2000,
    ["weapon_smg1"] = 2000,
    ["weapon_ar2"] = 2000,
    ["default"] = 2000,
};

local WEAPON_DAMAGES = {
    ["weapon_pistol"] = 10,
    ["weapon_357"] = 80,
    ["weapon_shotgun"] = 8,
    ["weapon_smg1"] = 20,
    ["weapon_ar2"] = 30,
    ["default"] = 10,
};

local WEAPON_PENETRATION_POWERS = {
    ["default"] = 2.5,
};

local WEAPON_PENETRATION_COUNTS = {
    ["default"] = 10,
};

local WEAPON_DRAG = {
    ["weapon_shotgun"] = 0.9,
    ["default"] = 0.1,
};

local WEAPON_MASS = {
    ["default"] = 1.0,
};

local WEAPON_DROP = {
    ["default"] = 0.005,
};

local WEAPON_MIN_SPEED = {
    ["default"] = 50.0,
};

local WEAPON_MAX_DISTANCE = {
    ["default"] = 10000.0,
    ["weapon_shotgun"] = 1500.0,
};

local CONFIG_TYPES = {
    ["speed"] = WEAPON_SPEEDS,
    ["damage"] = WEAPON_DAMAGES,
    ["penetration_power"] = WEAPON_PENETRATION_POWERS,
    ["penetration_count"] = WEAPON_PENETRATION_COUNTS,
    ["drag"] = WEAPON_DRAG,
    ["mass"] = WEAPON_MASS,
    ["drop"] = WEAPON_DROP,
    ["min_speed"] = WEAPON_MIN_SPEED,
    ["max_distance"] = WEAPON_MAX_DISTANCE,
};

function get_weapon_speed(weapon, class_name)
    local val = WEAPON_SPEEDS[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name) end
        return val;
    end
    return WEAPON_SPEEDS["default"];
end

function get_weapon_damage(weapon, class_name, damage)
    local val = WEAPON_DAMAGES[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, damage) end
        return val;
    end
    return damage or WEAPON_DAMAGES["default"];
end

function get_weapon_penetration_power(weapon, class_name, penetration_power)
    local val = WEAPON_PENETRATION_POWERS[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, penetration_power) end
        return val;
    end
    return penetration_power or WEAPON_PENETRATION_POWERS["default"];
end

function get_weapon_penetration_count(weapon, class_name, penetration_count)
    local val = WEAPON_PENETRATION_COUNTS[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, penetration_count) end
        return val
    end
    return penetration_count or WEAPON_PENETRATION_COUNTS["default"];
end

function get_weapon_drag(weapon, class_name, drag)
    local val = WEAPON_DRAG[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, drag) end
        return val;
    end
    return drag or WEAPON_DRAG["default"];
end

function get_weapon_mass(weapon, class_name, mass)
    local val = WEAPON_MASS[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, mass) end
        return val;
    end
    return mass or WEAPON_MASS["default"];
end

function get_weapon_drop(weapon, class_name, drop)
    local val = WEAPON_DROP[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, drop) end
        return val;
    end
    return drop or WEAPON_DROP["default"];
end

function get_weapon_min_speed(weapon, class_name, min_speed)
    local val = WEAPON_MIN_SPEED[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, min_speed) end
        return val;
    end
    return min_speed or WEAPON_MIN_SPEED["default"];
end

function get_weapon_max_distance(weapon, class_name, max_distance)
    local val = WEAPON_MAX_DISTANCE[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name, max_distance) end
        return val;
    end
    return max_distance or WEAPON_MAX_DISTANCE["default"];
end

if SERVER then
    util.AddNetworkString("projectile_config_sync");
    util.AddNetworkString("projectile_config_update");

    local function initialize_db()
        if not sql.TableExists("projectile_weapon_data") then
            local res = sql.Query("CREATE TABLE projectile_weapon_data (key TEXT PRIMARY KEY, value FLOAT)");
            if res == false then
                print("sql error creating projectile_weapon_data table: " .. sql.LastError());
            end
        else
            local data = sql.Query("SELECT * FROM projectile_weapon_data");
            if data then
                for idx, row in ipairs(data) do
                    local key = row.key;
                    local val = tonumber(row.value);
                    
                    local parts = string.Explode("|", key);
                    if #parts == 2 then
                        local cfg_type = parts[1];
                        local class_name = parts[2];
                        local target_table = CONFIG_TYPES[cfg_type];

                        if target_table then
                            target_table[class_name] = val;
                        end
                    end
                end
                print("loaded " .. #data .. " weapon configs from database.");
            end
        end
    end

    local function save_config_to_db(cfg_type, class_name, val)
        local key = cfg_type .. "|" .. class_name;
        local safe_key = sql.SQLStr(key);
        local safe_val = val;
        
        local query = "REPLACE INTO projectile_weapon_data (key, value) VALUES(" .. safe_key .. ", " .. safe_val .. ")";
        local res = sql.Query(query);
        
        if res == false then
            print("sql error saving config: " .. key .. ": " .. sql.LastError());
        end
    end

    initialize_db();

    hook.Add("PlayerInitialSpawn", "projectile_config_full_sync", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            net.Start("projectile_config_sync");
            net.WriteTable(WEAPON_SPEEDS);
            net.WriteTable(WEAPON_DAMAGES);
            net.WriteTable(WEAPON_PENETRATION_POWERS);
            net.WriteTable(WEAPON_PENETRATION_COUNTS);
            net.WriteTable(WEAPON_DRAG);
            net.WriteTable(WEAPON_MASS);
            net.WriteTable(WEAPON_DROP);
            net.WriteTable(WEAPON_MIN_SPEED);
            net.WriteTable(WEAPON_MAX_DISTANCE);
            net.Send(ply);
        end)
    end)

    net.Receive("projectile_config_update", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then 
            return;
        end

        local cfg_type = net.ReadString();
        local class_name = net.ReadString();
        local val = net.ReadFloat();
        
        local target_table = CONFIG_TYPES[cfg_type];

        if target_table then
            print("updated weapon config: " .. cfg_type .. " for " .. class_name .. " -> " .. val);
            
            target_table[class_name] = val;
            save_config_to_db(cfg_type, class_name, val);

            net.Start("projectile_config_update");
            net.WriteString(cfg_type);
            net.WriteString(class_name);
            net.WriteFloat(val);
            net.Broadcast();
        end
    end)
    
    print("loaded weapon config sql");
end

if CLIENT then
    net.Receive("projectile_config_sync", function()
        WEAPON_SPEEDS = net.ReadTable();
        WEAPON_DAMAGES = net.ReadTable();
        WEAPON_PENETRATION_POWERS = net.ReadTable();
        WEAPON_PENETRATION_COUNTS = net.ReadTable();
        WEAPON_DRAG = net.ReadTable();
        WEAPON_MASS = net.ReadTable();
        WEAPON_DROP = net.ReadTable();
        WEAPON_MIN_SPEED = net.ReadTable();
        WEAPON_MAX_DISTANCE = net.ReadTable();

        CONFIG_TYPES["speed"] = WEAPON_SPEEDS;
        CONFIG_TYPES["damage"] = WEAPON_DAMAGES;
        CONFIG_TYPES["penetration_power"] = WEAPON_PENETRATION_POWERS;
        CONFIG_TYPES["penetration_count"] = WEAPON_PENETRATION_COUNTS;
        CONFIG_TYPES["drag"] = WEAPON_DRAG;
        CONFIG_TYPES["mass"] = WEAPON_MASS;
        CONFIG_TYPES["drop"] = WEAPON_DROP;
        CONFIG_TYPES["min_speed"] = WEAPON_MIN_SPEED;
        CONFIG_TYPES["max_distance"] = WEAPON_MAX_DISTANCE;

        print("received full weapon config sync");
    end)

    net.Receive("projectile_config_update", function()
        local cfg_type = net.ReadString();
        local class_name = net.ReadString();
        local val = net.ReadFloat();

        local target_table = CONFIG_TYPES[cfg_type];
        if target_table then
            target_table[class_name] = val;
            print("updated " .. cfg_type .. " for " .. class_name .. " to " .. val);
        end
    end)

    local function open_editor()
        local frame = vgui.Create("DFrame");
        frame:SetSize(500, 700);
        frame:Center();
        frame:SetTitle("Weapon Config Editor");
        frame:MakePopup();

        local search = vgui.Create("DTextEntry", frame);
        search:Dock(TOP);
        search:SetPlaceholderText("Search Weapon Class...");
        
        local scroll = vgui.Create("DScrollPanel", frame);
        scroll:Dock(FILL);

        local list_layout = vgui.Create("DListLayout", scroll);
        list_layout:Dock(FILL);

        local weapon_list = weapons.GetList();
        local sorted_weapons = {};
        for idx = 1, #weapon_list do
            local wep = weapon_list[idx];
            table.insert(sorted_weapons, wep.ClassName);
        end
        for idx = 1, #HL2_WEAPON_CLASSES do
            local class_name = HL2_WEAPON_CLASSES[idx];
            table.insert(sorted_weapons, class_name);
        end
        table.sort(sorted_weapons);

        local function create_slider(parent, label_text, cfg_type, class_name, default_val, max_val, decimals)
            local panel = vgui.Create("DPanel", parent);
            panel:Dock(TOP);
            panel:SetTall(30);
            panel:SetBackgroundColor(Color(0, 0, 0, 0));
            
            local label = vgui.Create("DLabel", panel);
            label:SetText(label_text);
            label:Dock(LEFT);
            label:SetWide(120);
            label:SetTextColor(color_white);

            local slider = vgui.Create("DNumSlider", panel);
            slider:Dock(FILL);
            slider:SetMin(0);
            slider:SetMax(max_val);
            slider:SetDecimals(decimals);
            
            local current_table = CONFIG_TYPES[cfg_type];
            local current_val = current_table[class_name];

            if current_val and isnumber(current_val) then
                slider:SetValue(current_val);
            else
                local def = current_table["default"];
                if isnumber(def) then
                    slider:SetValue(def);
                else
                    slider:SetValue(default_val);
                end
            end

            local function send_update()
                if not LocalPlayer():IsSuperAdmin() then return; end
                net.Start("projectile_config_update");
                net.WriteString(cfg_type);
                net.WriteString(class_name);
                net.WriteFloat(math.Round(slider:GetValue(), decimals));
                net.SendToServer();
            end

            slider.Think = function(s)
                local isInteracting = s.Slider:GetDragging() or s.TextArea:IsEditing();
                if isInteracting then
                    s.HasChanged = true;
                elseif s.HasChanged then
                    s.HasChanged = false;
                    send_update();
                end
            end

            slider.TextArea.OnEnter = function()
                send_update();
                slider.HasChanged = false;
            end
        end

        local function populate_list(filter)
            list_layout:Clear();

            for _, class_name in ipairs(sorted_weapons) do
                if WEAPON_BLACKLIST[class_name] then continue end
                
                if filter and not string.find(string.lower(class_name), string.lower(filter), 1, true) then
                    continue;
                end

                local category = list_layout:Add("DCollapsibleCategory");
                category:SetLabel(class_name);
                category:SetExpanded(false);
                category:Dock(TOP);
                category:DockMargin(0, 0, 0, 5);

                local content = vgui.Create("DPanel");
                content:SetBackgroundColor(Color(40, 40, 40));
                
                create_slider(content, "Speed", "speed", class_name, 2000, 10000, 0);
                create_slider(content, "Damage", "damage", class_name, 10, 500, 0);
                create_slider(content, "Pen Power", "penetration_power", class_name, 2.5, 50, 2);
                create_slider(content, "Pen Count", "penetration_count", class_name, 10, 50, 0);
                create_slider(content, "Drag", "drag", class_name, 0, 10, 3);
                create_slider(content, "Mass", "mass", class_name, 1, 500, 2);
                create_slider(content, "Drop Multi", "drop", class_name, 1, 5, 3);
                create_slider(content, "Min Speed", "min_speed", class_name, 0, 500, 0);
                create_slider(content, "Max Dist", "max_distance", class_name, 10000, 50000, 0);

                content:SetTall(290); 
                category:SetContents(content);
            end
        end

        populate_list();

        search.OnChange = function(s)
            populate_list(s:GetValue());
        end
    end

    concommand.Add("pro_weaponconfig", function()
        if not LocalPlayer():IsSuperAdmin() then
            chat.AddText(Color(255, 50, 50), "You must be a SuperAdmin to use this menu.");
            return;
        end
        open_editor();
    end)
end

print("loaded projectile weapon config");