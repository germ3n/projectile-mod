AddCSLuaFile();

local is_function = isfunction;
local tonumber = tonumber;
local tostring = tostring;
local NULL = NULL;

local WEAPON_BLACKLIST = {};

HL2_WEAPON_CLASSES = {
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

CONFIG_TYPES = {
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

local CONFIG_TYPES = CONFIG_TYPES;
local HL2_WEAPON_CLASSES = HL2_WEAPON_CLASSES;

function get_weapon_speed(weapon, class_name)
    local val = WEAPON_SPEEDS[class_name];
    if val then
        if is_function(val) then return val(weapon, class_name) end
        return val;
    end
    return WEAPON_SPEEDS["default"];
end

function get_weapon_damage(weapon, class_name, damage)
    if damage == 0 and weapon ~= NULL and weapon.ArcCW then
        return weapon:GetDamage(0, true);
    end

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
end

print("loaded projectile weapon config");