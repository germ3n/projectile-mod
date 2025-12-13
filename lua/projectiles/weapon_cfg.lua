AddCSLuaFile();

local tonumber = tonumber;
local tostring = tostring;
local NULL = NULL;

local TRACER_TYPE_TO_INDEX = {
    ["core"] = 1,
    ["glow"] = 2,
};

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

local WEAPON_TRACER_COLORS = {
    ["default"] = { Color(255, 200, 100, 255), Color(255, 140, 0, 150) },
    ["weapon_ar2"] = { Color(200, 255, 255, 255), Color(60, 120, 255, 180) }
};

local WEAPON_SPREAD_BIAS = {
    ["default"] = 1.0,
    ["weapon_shotgun"] = -1.0,
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
    ["tracer_colors"] = WEAPON_TRACER_COLORS,
    ["spread_bias"] = WEAPON_SPREAD_BIAS,
};

local CONFIG_TYPES = CONFIG_TYPES;
local HL2_WEAPON_CLASSES = HL2_WEAPON_CLASSES;

function get_weapon_speed(weapon, class_name, speed)
    return speed or WEAPON_SPEEDS[class_name] or WEAPON_SPEEDS["default"];
end

function get_weapon_damage(weapon, class_name, damage)
    if damage == 0 and weapon ~= NULL and weapon.ArcCW then
        return weapon:GetDamage(0, true);
    end

    return damage or WEAPON_DAMAGES[class_name] or WEAPON_DAMAGES["default"];
end

function get_weapon_penetration_power(weapon, class_name, penetration_power)
    return penetration_power or WEAPON_PENETRATION_POWERS[class_name] or WEAPON_PENETRATION_POWERS["default"];
end

function get_weapon_penetration_count(weapon, class_name, penetration_count)
    return penetration_count or WEAPON_PENETRATION_COUNTS[class_name] or WEAPON_PENETRATION_COUNTS["default"];
end

function get_weapon_drag(weapon, class_name, drag)
    return drag or WEAPON_DRAG[class_name] or WEAPON_DRAG["default"];
end

function get_weapon_mass(weapon, class_name, mass)
    return mass or WEAPON_MASS[class_name] or WEAPON_MASS["default"];
end

function get_weapon_drop(weapon, class_name, drop)
    return drop or WEAPON_DROP[class_name] or WEAPON_DROP["default"];
end

function get_weapon_min_speed(weapon, class_name, min_speed)
    return min_speed or WEAPON_MIN_SPEED[class_name] or WEAPON_MIN_SPEED["default"];
end

function get_weapon_max_distance(weapon, class_name, max_distance)
    return max_distance or WEAPON_MAX_DISTANCE[class_name] or WEAPON_MAX_DISTANCE["default"];
end

function get_weapon_tracer_colors(weapon, class_name, tracer_colors)
    return tracer_colors or WEAPON_TRACER_COLORS[class_name] or WEAPON_TRACER_COLORS["default"];
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
                local color_map = {
                    ["core_red"]   = {1, "r"}, ["core_green"] = {1, "g"}, ["core_blue"]  = {1, "b"}, ["core_alpha"] = {1, "a"},
                    ["glow_red"]   = {2, "r"}, ["glow_green"] = {2, "g"}, ["glow_blue"]  = {2, "b"}, ["glow_alpha"] = {2, "a"}
                };
    
                for _, row in next, data do
                    local key = row.key;
                    local val = tonumber(row.value);
                    
                    local parts = string.Explode("|", key);
                    if #parts == 2 then
                        local cfg_type = parts[1];
                        local raw_name = parts[2];
                        local target_table = CONFIG_TYPES[cfg_type];
    
                        if target_table then
                            if cfg_type == "tracer_colors" then
                                for suffix, map in next, color_map do
                                    if string.EndsWith(raw_name, suffix) then
                                        local class_name = string.sub(raw_name, 1, #raw_name - #suffix);
                                        
                                        if not target_table[class_name] then
                                            local def = target_table["default"];
                                            target_table[class_name] = {
                                                Color(def[1].r, def[1].g, def[1].b, def[1].a),
                                                Color(def[2].r, def[2].g, def[2].b, def[2].a)
                                            };
                                        end
    
                                        target_table[class_name][map[1]][map[2]] = val;
                                        break;
                                    end
                                end
                            else
                                target_table[raw_name] = val;
                            end
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

    local ORIGINAL_TABLES = {
        ["speed"] = table.Copy(WEAPON_SPEEDS),
        ["damage"] = table.Copy(WEAPON_DAMAGES),
        ["penetration_power"] = table.Copy(WEAPON_PENETRATION_POWERS),
        ["penetration_count"] = table.Copy(WEAPON_PENETRATION_COUNTS),
        ["drag"] = table.Copy(WEAPON_DRAG),
        ["mass"] = table.Copy(WEAPON_MASS),
        ["drop"] = table.Copy(WEAPON_DROP),
        ["min_speed"] = table.Copy(WEAPON_MIN_SPEED),
        ["max_distance"] = table.Copy(WEAPON_MAX_DISTANCE),
        ["tracer_colors"] = table.Copy(WEAPON_TRACER_COLORS),
        ["spread_bias"] = table.Copy(WEAPON_SPREAD_BIAS),
    };

    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;
    local NULL = NULL;

    local function reset_config_to_db(cfg_type, class_name)
        local key = cfg_type .. "|" .. class_name;
        local safe_key = sql.SQLStr(key);
        local query = "DELETE FROM projectile_weapon_data WHERE key = " .. safe_key;
        local res = sql.Query(query);
        
        if res == false then
            print("sql error resetting config: " .. key .. ": " .. sql.LastError());
        end

        if CONFIG_TYPES[cfg_type] then
            CONFIG_TYPES[cfg_type][class_name] = ORIGINAL_TABLES[cfg_type][class_name];
        end
    end

    concommand.Add("pro_weapon_config_reset_single", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        local cfg_type = args[1];
        local class_name = args[2];
        reset_config_to_db(cfg_type, class_name);

        net.Start("projectile_config_update");
        net.WriteString(cfg_type);
        net.WriteString(class_name);
        net.WriteFloat(ORIGINAL_TABLES[cfg_type][class_name] or ORIGINAL_TABLES[cfg_type]["default"]);
        net.Broadcast();

        print("reset weapon config: " .. cfg_type .. " for " .. class_name);
    end, nil, "Reset a single weapon config");

    concommand.Add("pro_weapon_config_reset_all", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        sql.Query("DELETE FROM projectile_weapon_data");

        table.CopyFromTo(ORIGINAL_TABLES["speed"], WEAPON_SPEEDS);
        table.CopyFromTo(ORIGINAL_TABLES["damage"], WEAPON_DAMAGES);
        table.CopyFromTo(ORIGINAL_TABLES["penetration_power"], WEAPON_PENETRATION_POWERS);
        table.CopyFromTo(ORIGINAL_TABLES["penetration_count"], WEAPON_PENETRATION_COUNTS);
        table.CopyFromTo(ORIGINAL_TABLES["drag"], WEAPON_DRAG);
        table.CopyFromTo(ORIGINAL_TABLES["mass"], WEAPON_MASS);
        table.CopyFromTo(ORIGINAL_TABLES["drop"], WEAPON_DROP);
        table.CopyFromTo(ORIGINAL_TABLES["min_speed"], WEAPON_MIN_SPEED);
        table.CopyFromTo(ORIGINAL_TABLES["max_distance"], WEAPON_MAX_DISTANCE);
        table.CopyFromTo(ORIGINAL_TABLES["tracer_colors"], WEAPON_TRACER_COLORS);
        table.CopyFromTo(ORIGINAL_TABLES["spread_bias"], WEAPON_SPREAD_BIAS);
        CONFIG_TYPES["speed"] = WEAPON_SPEEDS;
        CONFIG_TYPES["damage"] = WEAPON_DAMAGES;
        CONFIG_TYPES["penetration_power"] = WEAPON_PENETRATION_POWERS;
        CONFIG_TYPES["penetration_count"] = WEAPON_PENETRATION_COUNTS;
        CONFIG_TYPES["drag"] = WEAPON_DRAG;
        CONFIG_TYPES["mass"] = WEAPON_MASS;
        CONFIG_TYPES["drop"] = WEAPON_DROP;
        CONFIG_TYPES["min_speed"] = WEAPON_MIN_SPEED;
        CONFIG_TYPES["max_distance"] = WEAPON_MAX_DISTANCE;
        CONFIG_TYPES["tracer_colors"] = WEAPON_TRACER_COLORS;
        CONFIG_TYPES["spread_bias"] = WEAPON_SPREAD_BIAS;
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
        net.WriteTable(WEAPON_TRACER_COLORS);
        net.WriteTable(WEAPON_SPREAD_BIAS);
        net.Broadcast();

        print("reset all weapon configs");
    end, nil, "Reset all weapon configs");

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
            net.WriteTable(WEAPON_TRACER_COLORS);
            net.WriteTable(WEAPON_SPREAD_BIAS);
            net.Send(ply);
        end)
    end)

    net.Receive("projectile_config_update", function(len, ply)
        if not IsValid(ply) then 
            return;
        elseif not ply:IsSuperAdmin() then 
            ply:ChatPrint("You are not authorized to use this command.");
            return;
        end

        local cfg_type = net.ReadString();
        if cfg_type == "tracer_colors" then
            local target_table = CONFIG_TYPES[cfg_type];
            if target_table then
                local class_name = net.ReadString();
                local tracer_colors = { net.ReadColor(), net.ReadColor() };
                if target_table then
                    print("updated weapon config: " .. cfg_type .. " for " .. class_name .. " -> " .. val);
                    
                    target_table[class_name] = tracer_colors;
                    -- this is so stupid lmao
                    save_config_to_db(cfg_type, class_name .. "core_red", tracer_colors[1].r);
                    save_config_to_db(cfg_type, class_name .. "core_green", tracer_colors[1].g);
                    save_config_to_db(cfg_type, class_name .. "core_blue", tracer_colors[1].b);
                    save_config_to_db(cfg_type, class_name .. "core_alpha", tracer_colors[1].a);
                    save_config_to_db(cfg_type, class_name .. "glow_red", tracer_colors[2].r);
                    save_config_to_db(cfg_type, class_name .. "glow_green", tracer_colors[2].g);
                    save_config_to_db(cfg_type, class_name .. "glow_blue", tracer_colors[2].b);
                    save_config_to_db(cfg_type, class_name .. "glow_alpha", tracer_colors[2].a);
                end
            end
        else
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
        end
    end);

    concommand.Add("pro_weapon_set_tracer_color", function(ply, cmd, args)
        if #args < 5 or (ply ~= NULL and (not is_superadmin(ply))) then return; end
        local class_name = args[1];
        local tracer_type = args[2];
        local tracer_color = Color(tonumber(args[3]), tonumber(args[4]), tonumber(args[5]), args[6] and tonumber(args[6]) or 255);

        if not CONFIG_TYPES["tracer_colors"][class_name] then
            local def = CONFIG_TYPES["tracer_colors"]["default"];
            CONFIG_TYPES["tracer_colors"][class_name] = {
                Color(def[1].r, def[1].g, def[1].b, def[1].a),
                Color(def[2].r, def[2].g, def[2].b, def[2].a)
            };
        end

        CONFIG_TYPES["tracer_colors"][class_name][TRACER_TYPE_TO_INDEX[tracer_type]] = tracer_color;
        save_config_to_db("tracer_colors", class_name .. tracer_type .. "_red", tracer_color.r);
        save_config_to_db("tracer_colors", class_name .. tracer_type .. "_green", tracer_color.g);
        save_config_to_db("tracer_colors", class_name .. tracer_type .. "_blue", tracer_color.b);
        save_config_to_db("tracer_colors", class_name .. tracer_type .. "_alpha", tracer_color.a);

        print("set tracer color: " .. class_name .. " " .. tracer_type .. " to (" .. tracer_color.r .. ", " .. tracer_color.g .. ", " .. tracer_color.b .. ", " .. tracer_color.a .. ")");

        --[[[net.Start("projectile_config_update");
        net.WriteString("tracer_colors");
        net.WriteString(class_name);
        net.WriteColor(tracer_colors[1]);
        net.WriteColor(tracer_colors[2]);
        net.Broadcast();]]
    end, nil, "Set the tracer colors for a weapon");
    
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
        WEAPON_TRACER_COLORS = net.ReadTable();
        WEAPON_SPREAD_BIAS = net.ReadTable();
        CONFIG_TYPES["speed"] = WEAPON_SPEEDS;
        CONFIG_TYPES["damage"] = WEAPON_DAMAGES;
        CONFIG_TYPES["penetration_power"] = WEAPON_PENETRATION_POWERS;
        CONFIG_TYPES["penetration_count"] = WEAPON_PENETRATION_COUNTS;
        CONFIG_TYPES["drag"] = WEAPON_DRAG;
        CONFIG_TYPES["mass"] = WEAPON_MASS;
        CONFIG_TYPES["drop"] = WEAPON_DROP;
        CONFIG_TYPES["min_speed"] = WEAPON_MIN_SPEED;
        CONFIG_TYPES["max_distance"] = WEAPON_MAX_DISTANCE;
        CONFIG_TYPES["tracer_colors"] = WEAPON_TRACER_COLORS;
        CONFIG_TYPES["spread_bias"] = WEAPON_SPREAD_BIAS;
        print("received full weapon config sync");
    end)

    net.Receive("projectile_config_update", function()
        local cfg_type = net.ReadString();
        local class_name = net.ReadString();
        if cfg_type == "tracer_colors" then
            local tracer_colors = { net.ReadColor(), net.ReadColor() };
            local target_table = CONFIG_TYPES[cfg_type];
            if target_table then
                target_table[class_name] = tracer_colors;
                LocalPlayer():ChatPrint("Updated " .. cfg_type .. " for " .. class_name .. " to " .. tracer_colors[1] .. " and " .. tracer_colors[2]);
            end
        else
            local val = net.ReadFloat();
            local target_table = CONFIG_TYPES[cfg_type];
            if target_table then
                target_table[class_name] = val;
                LocalPlayer():ChatPrint("Updated " .. cfg_type .. " for " .. class_name .. " to " .. val);
            end
        end
    end)
end

print("loaded projectile weapon config");