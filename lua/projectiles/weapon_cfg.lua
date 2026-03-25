AddCSLuaFile();

local is_function = isfunction;
local tonumber = tonumber;
local tostring = tostring;
local NULL = NULL;
local Color = Color;
local player_iterator = player.Iterator;

local TRACER_TYPE_TO_INDEX = {
    ["core"] = 1,
    ["glow"] = 2,
};

local WEAPON_BLACKLIST = {
    ["default"] = false,
};

HL2_WEAPON_CLASSES = {
    "weapon_pistol",
    "weapon_357",
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_ar2",
    "weapon_alyxgun",
    "weapon_annabelle",
    "npc_turret_floor",
    "npc_turret_ceiling",
    "npc_turret_ground",
    "prop_vehicle_airboat",
    "func_tank",
    "gmod_turret",
};

local WEAPON_SPEEDS = {
    ["default"] = 3000,
};

local WEAPON_DAMAGES = {
    ["weapon_pistol"] = 5,
    ["weapon_357"] = 40,
    ["weapon_shotgun"] = 8,
    ["weapon_smg1"] = 4,
    ["weapon_ar2"] = 8,
    ["weapon_annabelle"] = 8,
    ["weapon_alyxgun"] = 5,
    ["npc_turret_floor"] = 3,
    ["npc_turret_ceiling"] = 3,
    ["npc_turret_ground"] = 3,
    ["prop_vehicle_airboat"] = 3,
    ["func_tank"] = 15,
    ["default"] = 10,
};

local WEAPON_PENETRATION_POWERS = {
    ["default"] = 2.5,
};

local WEAPON_PENETRATION_COUNTS = {
    ["default"] = 10,
};

local WEAPON_SHAPE = {
    ["weapon_shotgun"] = 3,
    ["weapon_ar2"] = 3,
    ["default"] = 1,
};

local WEAPON_COEFFICIENT = {
    ["weapon_pistol"] = 0.165,
    ["weapon_357"] = 0.21,
    ["weapon_shotgun"] = 0.039,
    ["weapon_smg1"] = 0.15,
    ["weapon_ar2"] = 0.3,
    ["default"] = 0.1,
};

local WEAPON_DRAG = {
    ["weapon_shotgun"] = 0.9,
    ["default"] = 0.1,
};

local WEAPON_MASS = {
    ["default"] = 8.0,
};

local WEAPON_CALIBER = {
    ["default"] = 10,
};

local WEAPON_DROP = {
    ["default"] = 1.0,
};

local WEAPON_ZERO_RANGE = {
    ["default"] = 3937,
};

local WEAPON_MIN_SPEED = {
    ["default"] = 50.0,
};

local WEAPON_MAX_DISTANCE = {
    ["default"] = 60000.0,
    ["weapon_shotgun"] = 60000.0,
    ["weapon_annabelle"] = 60000.0,
};

local WEAPON_TRACER_COLORS = {
    ["default"] = { Color(255, 200, 100, 255), Color(255, 100, 100, 150) },
    ["weapon_ar2"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
    ["npc_turret_floor"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
    ["npc_turret_ceiling"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
    ["npc_turret_ground"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
    ["prop_vehicle_airboat"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
    ["func_tank"] = { Color(200, 255, 255, 255), Color(60, 255, 180, 185) },
};

local WEAPON_TRACER_FLAGS = {
    ["default"] = 0,
};

local WEAPON_SPREAD_BIAS = {
    ["default"] = 1.0,
    ["weapon_shotgun"] = 0.0,
};

local WEAPON_DROPOFF_START = {
    ["default"] = 5000.0,
    ["weapon_shotgun"] = 500.0,
    ["weapon_annabelle"] = 700.0,
};

local WEAPON_DROPOFF_END = {
    ["default"] = 10000.0,
    ["weapon_shotgun"] = 1500.0,
    ["weapon_annabelle"] = 2000.0,
};

local WEAPON_DROPOFF_MIN_MULTIPLIER = {
    ["default"] = 0.5,
};

CONFIG_TYPES = {
    ["blacklist"] = WEAPON_BLACKLIST,
    ["speed"] = WEAPON_SPEEDS,
    ["damage"] = WEAPON_DAMAGES,
    ["penetration_power"] = WEAPON_PENETRATION_POWERS,
    ["penetration_count"] = WEAPON_PENETRATION_COUNTS,
    ["shape"] = WEAPON_SHAPE,
    ["coefficient"] = WEAPON_COEFFICIENT,
    ["drag"] = WEAPON_DRAG,
    ["mass"] = WEAPON_MASS,
    ["caliber"] = WEAPON_CALIBER,
    ["drop"] = WEAPON_DROP,
    ["zero_range"] = WEAPON_ZERO_RANGE,
    ["min_speed"] = WEAPON_MIN_SPEED,
    ["max_distance"] = WEAPON_MAX_DISTANCE,
    ["tracer_colors"] = WEAPON_TRACER_COLORS,
    ["tracer_flags"] = WEAPON_TRACER_FLAGS,
    ["spread_bias"] = WEAPON_SPREAD_BIAS,
    ["dropoff_start"] = WEAPON_DROPOFF_START,
    ["dropoff_end"] = WEAPON_DROPOFF_END,
    ["dropoff_min_multiplier"] = WEAPON_DROPOFF_MIN_MULTIPLIER,
};

local CONFIG_TYPES = CONFIG_TYPES;
local HL2_WEAPON_CLASSES = HL2_WEAPON_CLASSES;

function is_weapon_blacklisted(weapon, class_name)
    return WEAPON_BLACKLIST[class_name] == true;
end

local AMMO_CHARACTERISTICS = { -- todo: make configurable? 
    ["Pistol"] = { base_speed = 3000, mass = 8.0, caliber = 9, caliber_factor = 0.9 , drag_coef = 0.25, shape = 1},
    ["357"] = { base_speed = 3500, mass = 16, caliber = 10.9, caliber_factor = 1.1 , drag_coef = 0.2, shape = 1},
    ["SMG1"] = { base_speed = 6500, mass = 3.5, caliber = 5.7, caliber_factor = 0.85 , drag_coef = 0.17, shape = 2},
    ["AR2"] = { base_speed = 9000, mass = 10, caliber = 7.8, caliber_factor = 1.0 , drag_coef = 0.15, shape = 2},
    ["Buckshot"] = { base_speed = 4500, mass = 3.5, caliber = 8.4, caliber_factor = 0.7, drag_coef = 0.47, shape = 3},
    ["SniperRound"] = { base_speed = 12000, mass = 50, caliber = 13, caliber_factor = 1.2 , drag_coef = 0.13, shape = 2},
    ["HelicopterGun"] = { base_speed = 9000, mass = 16, caliber = 8, caliber_factor = 1.1 , drag_coef = 0.15, shape = 3},
    ["default"] = { base_speed = 8000, mass = 8.0, caliber = 7.62, caliber_factor = 1.0 , drag_coef = 0.2629, shape = 1},
};

function get_ammo_property(ammo_type, property)
    local key = ammo_type
    if not AMMO_CHARACTERISTICS[key] then
        key = "default"
    end

    local char = AMMO_CHARACTERISTICS[key]
    if char and char[property] ~= nil then
        return char[property]
    else
        return AMMO_CHARACTERISTICS["default"][property]
    end
end

local clamp = math.Clamp;
function get_weapon_speed(weapon, class_name, damage, ammo_type)
    local has_speed_entry = WEAPON_SPEEDS[class_name] ~= nil;
    local auto_calc_speed_enabled = projectiles["pro_auto_calculate_speed"];

    if not has_speed_entry and auto_calc_speed_enabled then
        damage = damage or get_weapon_damage(weapon, class_name, damage, ammo_type) or WEAPON_DAMAGES["default"];
        local speed_multiplier = projectiles["pro_speed_scale"]; 
        local auto_multiplier = projectiles["pro_auto_calculate_speed_mult"]; 
        local calculated_speed = speed
        if not projectiles["pro_auto_calculate_speed_kinetic"] then  
            local damage_influence = 1.0 + ((damage - 10) / 150);
            damage_influence = clamp(damage_influence, 0.7, 2.5); 
            calculated_speed = clamp(get_ammo_property(ammo_type, "base_speed") * get_ammo_property(ammo_type, "caliber_factor") * damage_influence, 50.0, 25000.0);
        else
            local caliber = WEAPON_CALIBER[class_name] or get_ammo_property(ammo_type, "caliber")
            local mass = WEAPON_MASS[class_name] or get_ammo_property(ammo_type, "mass")
            --print(CLIENT and "CLIENT" or "SERVER", "Weapon:", class_name, "Ammo type:", ammo_type, "Damage:",  damage, damage_influence, "Caliber:", caliber, "Mass:",  mass);
            calculated_speed = ((2 * damage^2) / ((mass / 1000) * caliber^0.3))^0.5 * auto_multiplier * 1/0.0254;
        end
        --print(CLIENT and "CLIENT" or "SERVER", "Calculated speed:", calculated_speed*speed_multiplier);
        return calculated_speed;
    end

    return WEAPON_SPEEDS[class_name] or WEAPON_SPEEDS["default"];
end


function get_weapon_damage(weapon, class_name, damage, ammo_type)
    if WEAPON_DAMAGES[class_name] then
        return WEAPON_DAMAGES[class_name];
    end

    if damage == 0 and weapon ~= NULL and weapon.ArcCW then
        return weapon:GetDamage(0, true);
    end

    if IsValid(weapon) and weapon:IsWeapon() then
        if weapon.Primary and weapon.Primary.Damage then
            return weapon.Primary.Damage
        end

        local dmg = weapon:GetNWInt("Damage", 0) or 0
        if dmg > 0 then return dmg end
    end

    local wep_tbl = weapons.GetStored(class_name)
    if wep_tbl then
        if wep_tbl.Primary and wep_tbl.Primary.Damage then
            return wep_tbl.Primary.Damage
        end
        if wep_tbl.Damage then
            return wep_tbl.Damage
        end
    end

    local wep_tbl = weapons.GetStored(class_name)
    if wep_tbl and (wep_tbl.TacRP or string.find(class_name:lower(), "^tacrp_")) then
        local dmg = wep_tbl.Damage_Max 
                 or wep_tbl.DamageMax 
                 or (wep_tbl.BalanceStats and wep_tbl.BalanceStats[TacRP.BALANCE_SBOX] and wep_tbl.BalanceStats[TacRP.BALANCE_SBOX].Damage_Max)
                 or wep_tbl.Damage

        if wep_tbl.BalanceStats then
            local mode = TacRP.BALANCE_SBOX
            if wep_tbl.BalanceStats[mode] and wep_tbl.BalanceStats[mode].Damage_Max then
                dmg = wep_tbl.BalanceStats[mode].Damage_Max
            end
        end

        return dmg
    end

    if damage and damage > 0 then
        return damage
    else
        return WEAPON_DAMAGES["default"]
    end;
end

function get_weapon_penetration_power(weapon, class_name, speed, ammo_type)
    local has_pen_entry = WEAPON_PENETRATION_POWERS[class_name] ~= nil
    local auto_calc_pen_enabled = projectiles["pro_auto_calculate_penetration"]

    if auto_calc_pen_enabled and not has_pen_entry then
        local speed = (speed or WEAPON_SPEEDS["default"]) * 0.0254;
        
        local caliber = WEAPON_CALIBER[class_name] or get_ammo_property(ammo_type, "caliber")
        local mass = WEAPON_MASS[class_name] or get_ammo_property(ammo_type, "mass")
        -- De Marre penetration formula
        local calculated_pen = ((speed/2400)^1.43) * (((mass/1000)^0.71)/((caliber/100)^1.07)) * 100 * 1/25.4
        --print(CLIENT and "CLIENT" or "SERVER", "Calculated pen:", calculated_pen, "Weapon:", class_name, "Ammo type:", ammo_type, "Caliber:", caliber, "Mass:",  mass, "Speed:",  speed);
        return calculated_pen
    end

    return WEAPON_PENETRATION_POWERS[class_name] or WEAPON_PENETRATION_POWERS["default"]
end

function get_weapon_penetration_count(weapon, class_name)
    return WEAPON_PENETRATION_COUNTS[class_name] or WEAPON_PENETRATION_COUNTS["default"];
end

function get_weapon_shape(weapon, class_name, ammo_type)
    if WEAPON_SHAPE[class_name] then
        return WEAPON_SHAPE[class_name]
    end

    local shape = get_ammo_property(ammo_type, "shape")
    return shape
end

function get_weapon_coefficient(weapon, class_name, ammo_type)
    local has_coef_entry = WEAPON_COEFFICIENT[class_name] ~= nil;
    local auto_calc_drag_enabled = projectiles["pro_auto_calculate_drag"];
    if auto_calc_drag_enabled and not has_coef_entry then
        local cd = get_ammo_property(ammo_type, "drag_coef")
        local caliber = WEAPON_CALIBER[class_name] or get_ammo_property(ammo_type, "caliber")
        local mass = WEAPON_MASS[class_name] or get_ammo_property(ammo_type, "mass")
        local shape = WEAPON_SHAPE[class_name] or get_ammo_property(ammo_type, "shape")
        if shape == 3 then
            cd = 0.47
        end
        local calculated_coefficient = ((mass * 15.4324) / ((caliber / 25.4) ^ 2 * 7000)) / (cd / 0.2629);
        return calculated_coefficient;
    end

    return WEAPON_COEFFICIENT[class_name] or WEAPON_COEFFICIENT["default"];
end

function get_weapon_drag(weapon, class_name, ammo_type)
    local has_drag_entry = WEAPON_DRAG[class_name] ~= nil;
    local auto_calc_drag_enabled = projectiles["pro_auto_calculate_drag"];
    if auto_calc_drag_enabled and not has_drag_entry then
        local caliber = WEAPON_CALIBER[class_name] or get_ammo_property(ammo_type, "caliber")
        local mass = WEAPON_MASS[class_name] or get_ammo_property(ammo_type, "mass")
        local calculated_drag = caliber / mass * 0.4;
        return calculated_drag;
    end

    return WEAPON_DRAG[class_name] or WEAPON_DRAG["default"];
end

function get_weapon_mass(weapon, class_name, ammo_type)
    if WEAPON_MASS[class_name] then
        return WEAPON_MASS[class_name]
    end
        local mass = get_ammo_property(ammo_type, "mass")
    return mass
end

function get_weapon_caliber(weapon, class_name, ammo_type)
    if WEAPON_CALIBER[class_name] then
        return WEAPON_CALIBER[class_name]
    end
    local caliber = get_ammo_property(ammo_type, "caliber")
    return caliber
end

function get_weapon_drop(weapon, class_name)
    return WEAPON_DROP[class_name] or WEAPON_DROP["default"];
end

function get_weapon_zero_range(weapon, class_name, speed)
    local has_zero_entry = WEAPON_ZERO_RANGE[class_name] ~= nil;
    local auto_calc_zero_enabled = projectiles["pro_auto_calculate_zero"];
    if auto_calc_zero_enabled and not has_zero_entry then
    local calculated_zero = (speed*0.0254)^0.75*1/0.0254
    return calculated_zero;
end
    return WEAPON_ZERO_RANGE[class_name] or WEAPON_ZERO_RANGE["default"];
end

function get_weapon_min_speed(weapon, class_name)
    return WEAPON_MIN_SPEED[class_name] or WEAPON_MIN_SPEED["default"];
end

function get_weapon_max_distance(weapon, class_name)
    return WEAPON_MAX_DISTANCE[class_name] or WEAPON_MAX_DISTANCE["default"];
end

function get_weapon_tracer_colors(weapon, class_name)
    local colors = WEAPON_TRACER_COLORS[class_name] or WEAPON_TRACER_COLORS["default"];

    return { Color(colors[1].r, colors[1].g, colors[1].b, colors[1].a), Color(colors[2].r, colors[2].g, colors[2].b, colors[2].a) };
end

function get_weapon_tracer_flags(weapon, class_name)
    return WEAPON_TRACER_FLAGS[class_name] or WEAPON_TRACER_FLAGS["default"];
end

function get_weapon_spread_bias(weapon, class_name)
    return WEAPON_SPREAD_BIAS[class_name] or WEAPON_SPREAD_BIAS["default"];
end

function get_weapon_dropoff_start(weapon, class_name)
    return WEAPON_DROPOFF_START[class_name] or WEAPON_DROPOFF_START["default"];
end

function get_weapon_dropoff_end(weapon, class_name)
    return WEAPON_DROPOFF_END[class_name] or WEAPON_DROPOFF_END["default"];
end

function get_weapon_dropoff_min_multiplier(weapon, class_name)
    return WEAPON_DROPOFF_MIN_MULTIPLIER[class_name] or WEAPON_DROPOFF_MIN_MULTIPLIER["default"];
end

if SERVER then
    util.AddNetworkString("projectile_weapon_config_sync");
    util.AddNetworkString("projectile_weapon_config_sync_start");
    util.AddNetworkString("projectile_weapon_config_sync_chunk");
    util.AddNetworkString("projectile_weapon_config_update");
    util.AddNetworkString("projectile_weapon_config_reset");
    util.AddNetworkString("projectile_weapon_tracer_colors_update");

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
                                local has_old_suffix = false;
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
                                        has_old_suffix = true;
                                        break;
                                    end
                                end
                                
                                if not has_old_suffix then
                                    local color_str = tostring(row.value);
                                    local colors = string.Explode("|", color_str);
                                    if #colors == 2 then
                                        local c1_parts = string.Explode(",", colors[1]);
                                        local c2_parts = string.Explode(",", colors[2]);
                                        
                                        if #c1_parts == 4 and #c2_parts == 4 then
                                            target_table[raw_name] = {
                                                Color(tonumber(c1_parts[1]) or 255, tonumber(c1_parts[2]) or 200, tonumber(c1_parts[3]) or 100, tonumber(c1_parts[4]) or 255),
                                                Color(tonumber(c2_parts[1]) or 255, tonumber(c2_parts[2]) or 140, tonumber(c2_parts[3]) or 0, tonumber(c2_parts[4]) or 150)
                                            };
                                        end
                                    end
                                end
                            else
                                if target_table["default"] ~= nil and type(target_table["default"]) == "boolean" then
                                    target_table[raw_name] = (val == 1);
                                else
                                    target_table[raw_name] = val;
                                end
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
        ["blacklist"] = table.Copy(WEAPON_BLACKLIST),
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
        ["tracer_flags"] = table.Copy(WEAPON_TRACER_FLAGS),
        ["spread_bias"] = table.Copy(WEAPON_SPREAD_BIAS),
        ["dropoff_start"] = table.Copy(WEAPON_DROPOFF_START),
        ["dropoff_end"] = table.Copy(WEAPON_DROPOFF_END),
        ["dropoff_min_multiplier"] = table.Copy(WEAPON_DROPOFF_MIN_MULTIPLIER),
    };

    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;
    local NULL = NULL;
    local CONFIG_TYPES = CONFIG_TYPES;

    local function reset_config_to_db(cfg_type, class_name)
        local key = cfg_type .. "|" .. class_name;
        local safe_key = sql.SQLStr(key);
        local query = "DELETE FROM projectile_weapon_data WHERE key = " .. safe_key;
        local res = sql.Query(query);
        
        if res == false then
            print("sql error resetting config: " .. key .. ": " .. sql.LastError());
        end

        if CONFIG_TYPES[cfg_type] then
            CONFIG_TYPES[cfg_type][class_name] = nil;--ORIGINAL_TABLES[cfg_type][class_name];
        end
    end

    function weapon_cfg_clear_db()
        sql.Query("DELETE FROM projectile_weapon_data");
        print("cleared projectile_weapon_data table");
    end

    function weapon_cfg_save_all_to_db()
        for cfg_type, cfg_table in next, CONFIG_TYPES do
            for class_name, val in next, cfg_table do
                if cfg_type == "tracer_colors" then
                    if type(val) == "table" and val[1] and val[2] then
                        local color_str = string.format("%d,%d,%d,%d|%d,%d,%d,%d", val[1].r, val[1].g, val[1].b, val[1].a, val[2].r, val[2].g, val[2].b, val[2].a);
                        local key = "tracer_colors|" .. class_name;
                        local safe_key = sql.SQLStr(key);
                        local safe_val = sql.SQLStr(color_str);
                        local query = "REPLACE INTO projectile_weapon_data (key, value) VALUES(" .. safe_key .. ", " .. safe_val .. ")";
                        local res = sql.Query(query);
                        
                        if res == false then
                            print("sql error saving tracer colors: " .. key .. ": " .. sql.LastError());
                        end
                    end
                else
                    local is_bool = type(val) == "boolean";
                    
                    if is_bool then
                        save_config_to_db(cfg_type, class_name, val and 1 or 0);
                    else
                        save_config_to_db(cfg_type, class_name, val);
                    end
                end
            end
        end

        print("saved all weapon configs to database");
    end

    concommand.Add("pro_weapon_config_reset_single", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        local cfg_type = args[1];
        local class_name = args[2];
        reset_config_to_db(cfg_type, class_name);

        net.Start("projectile_weapon_config_reset");
        net.WriteString(cfg_type);
        net.WriteString(class_name);
        net.Broadcast();

        print("reset weapon config: " .. cfg_type .. " for " .. class_name);
    end, nil, "Reset a single weapon config value");

    concommand.Add("pro_weapon_config_reset_single_all", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end

        local class_name = args[1];
        for cfg_type, cfg_table in next, CONFIG_TYPES do
            reset_config_to_db(cfg_type, class_name);

            net.Start("projectile_weapon_config_reset");
            net.WriteString(cfg_type);
            net.WriteString(class_name);
            net.Broadcast();
        end

        print("reset weapon config: " .. class_name .. " to defaults");
    end, nil, "Reset a weapon to defaults");

    function send_weapon_config_chunked(ply, broadcast)
        if not broadcast and not IsValid(ply) then return; end
        local config_data = {
            WEAPON_BLACKLIST,
            WEAPON_SPEEDS,
            WEAPON_DAMAGES,
            WEAPON_PENETRATION_POWERS,
            WEAPON_PENETRATION_COUNTS,
            WEAPON_SHAPE,
            WEAPON_COEFFICIENT,
            WEAPON_DRAG,
            WEAPON_MASS,
            WEAPON_CALIBER,
            WEAPON_DROP,
            WEAPON_ZERO_RANGE,
            WEAPON_MIN_SPEED,
            WEAPON_MAX_DISTANCE,
            WEAPON_TRACER_COLORS,
            WEAPON_SPREAD_BIAS,
            WEAPON_DROPOFF_START,
            WEAPON_DROPOFF_END,
            WEAPON_DROPOFF_MIN_MULTIPLIER,
            WEAPON_TRACER_FLAGS,
        };

        local compressed_data = util.Compress(util.TableToJSON(config_data));
        local compressed_size = string.len(compressed_data);
        local chunk_size = 60000;
        local total_chunks = math.ceil(compressed_size / chunk_size);

        net.Start("projectile_weapon_config_sync_start");
        net.WriteUInt(total_chunks, 16);
        net.WriteUInt(compressed_size, 32);
        if broadcast then
            net.Broadcast();
        else
            net.Send(ply);
        end

        local chunk_idx = 0;
        local function send_next_chunk()
            chunk_idx = chunk_idx + 1;

            if chunk_idx > total_chunks then
                return;
            end

            if not broadcast and not IsValid(ply) then return; end

            local start_pos = (chunk_idx - 1) * chunk_size + 1;
            local end_pos = math.min(start_pos + chunk_size - 1, compressed_size);
            local chunk = string.sub(compressed_data, start_pos, end_pos);

            net.Start("projectile_weapon_config_sync_chunk");
            net.WriteUInt(chunk_idx, 16);
            net.WriteUInt(string.len(chunk), 32);
            net.WriteData(chunk, string.len(chunk));
            if broadcast then
                net.Broadcast();
            else
                net.Send(ply);
            end

            timer.Simple(0.1, send_next_chunk);
        end

        send_next_chunk();
    end 

    concommand.Add("pro_weapon_config_reset_all", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end

        sql.Query("DELETE FROM projectile_weapon_data");

        table.CopyFromTo(ORIGINAL_TABLES["blacklist"], WEAPON_BLACKLIST);
        table.CopyFromTo(ORIGINAL_TABLES["speed"], WEAPON_SPEEDS);
        table.CopyFromTo(ORIGINAL_TABLES["damage"], WEAPON_DAMAGES);
        table.CopyFromTo(ORIGINAL_TABLES["penetration_power"], WEAPON_PENETRATION_POWERS);
        table.CopyFromTo(ORIGINAL_TABLES["penetration_count"], WEAPON_PENETRATION_COUNTS);
        table.CopyFromTo(ORIGINAL_TABLES["shape"], WEAPON_SHAPE);
        table.CopyFromTo(ORIGINAL_TABLES["coefficient"], WEAPON_COEFFICIENT);
        table.CopyFromTo(ORIGINAL_TABLES["drag"], WEAPON_DRAG);
        table.CopyFromTo(ORIGINAL_TABLES["mass"], WEAPON_MASS);
        table.CopyFromTo(ORIGINAL_TABLES["caliber"], WEAPON_CALIBER);
        table.CopyFromTo(ORIGINAL_TABLES["drop"], WEAPON_DROP);
        table.CopyFromTo(ORIGINAL_TABLES["zero_range"], WEAPON_ZERO_RANGE);
        table.CopyFromTo(ORIGINAL_TABLES["min_speed"], WEAPON_MIN_SPEED);
        table.CopyFromTo(ORIGINAL_TABLES["max_distance"], WEAPON_MAX_DISTANCE);
        table.CopyFromTo(ORIGINAL_TABLES["tracer_colors"], WEAPON_TRACER_COLORS);
        table.CopyFromTo(ORIGINAL_TABLES["tracer_flags"], WEAPON_TRACER_FLAGS);
        table.CopyFromTo(ORIGINAL_TABLES["spread_bias"], WEAPON_SPREAD_BIAS);
        table.CopyFromTo(ORIGINAL_TABLES["dropoff_start"], WEAPON_DROPOFF_START);
        table.CopyFromTo(ORIGINAL_TABLES["dropoff_end"], WEAPON_DROPOFF_END);
        table.CopyFromTo(ORIGINAL_TABLES["dropoff_min_multiplier"], WEAPON_DROPOFF_MIN_MULTIPLIER);
        CONFIG_TYPES["blacklist"] = WEAPON_BLACKLIST;
        CONFIG_TYPES["speed"] = WEAPON_SPEEDS;
        CONFIG_TYPES["damage"] = WEAPON_DAMAGES;
        CONFIG_TYPES["penetration_power"] = WEAPON_PENETRATION_POWERS;
        CONFIG_TYPES["penetration_count"] = WEAPON_PENETRATION_COUNTS;
        CONFIG_TYPES["shape"] = WEAPON_SHAPE;
        CONFIG_TYPES["coefficient"] = WEAPON_COEFFICIENT;
        CONFIG_TYPES["drag"] = WEAPON_DRAG;
        CONFIG_TYPES["mass"] = WEAPON_MASS;
        CONFIG_TYPES["caliber"] = WEAPON_CALIBER;
        CONFIG_TYPES["drop"] = WEAPON_DROP;
        CONFIG_TYPES["zero_range"] = WEAPON_ZERO_RANGE;
        CONFIG_TYPES["min_speed"] = WEAPON_MIN_SPEED;
        CONFIG_TYPES["max_distance"] = WEAPON_MAX_DISTANCE;
        CONFIG_TYPES["tracer_colors"] = WEAPON_TRACER_COLORS;
        CONFIG_TYPES["tracer_flags"] = WEAPON_TRACER_FLAGS;
        CONFIG_TYPES["spread_bias"] = WEAPON_SPREAD_BIAS;
        CONFIG_TYPES["dropoff_start"] = WEAPON_DROPOFF_START;
        CONFIG_TYPES["dropoff_end"] = WEAPON_DROPOFF_END;
        CONFIG_TYPES["dropoff_min_multiplier"] = WEAPON_DROPOFF_MIN_MULTIPLIER;

        send_weapon_config_chunked(nil, true);

        print("reset all weapon configs");
    end, nil, "Reset all weapon configs");

    concommand.Add("pro_weapon_config_copy_single", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        local cfg_type = args[1];
        if cfg_type == "tracer_colors" then print("not supported yet"); return; end

        local from_class_name = args[2];
        local to_class_name = args[3];
        local target_table = CONFIG_TYPES[cfg_type];
        if target_table then
            target_table[to_class_name] = target_table[from_class_name];
            if target_table[to_class_name] ~= nil then
                local val = target_table[to_class_name];
                local is_bool = type(val) == "boolean";
                
                if is_bool then
                    save_config_to_db(cfg_type, to_class_name, val and 1 or 0);
                else
                    save_config_to_db(cfg_type, to_class_name, val);
                end

                net.Start("projectile_weapon_config_update");
                net.WriteString(cfg_type);
                net.WriteString(to_class_name);
                net.WriteBool(is_bool);
                if is_bool then
                    net.WriteBool(val);
                else
                    net.WriteFloat(val);
                end

                net.Broadcast();
            else
                reset_config_to_db(cfg_type, to_class_name);

                net.Start("projectile_weapon_config_reset");
                net.WriteString(cfg_type);
                net.WriteString(to_class_name);
                net.Broadcast();
            end

            print("copied weapon config: " .. cfg_type .. " from " .. from_class_name .. " to " .. to_class_name);
        else
            print("weapon config: " .. cfg_type .. " not found");
        end
    end, nil, "Copy a single weapon config value");

    concommand.Add("pro_weapon_config_copy_all", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        local from_class_name = args[1];
        local to_class_name = args[2];

        for cfg_type, cfg_table in next, CONFIG_TYPES do
            if cfg_type == "tracer_colors" then print("skipping tracer colors, not supported yet"); continue; end

            reset_config_to_db(cfg_type, to_class_name);
            cfg_table[to_class_name] = cfg_table[from_class_name];

            if cfg_table[to_class_name] ~= nil then
                local val = cfg_table[to_class_name];
                local is_bool = type(val) == "boolean";
                
                if is_bool then
                    save_config_to_db(cfg_type, to_class_name, val and 1 or 0);
                else
                    save_config_to_db(cfg_type, to_class_name, val);
                end

                net.Start("projectile_weapon_config_update");
                net.WriteString(cfg_type);
                net.WriteString(to_class_name);
                net.WriteBool(false);
                net.WriteBool(is_bool);
                if is_bool then
                    net.WriteBool(val);
                else
                    net.WriteFloat(val);
                end

                net.Broadcast();
            end

            print("copied weapon config: " .. cfg_type .. " from " .. from_class_name .. " to " .. to_class_name);
        end
    end, nil, "Copy all weapon configs");

    concommand.Add("pro_weapon_config_set_tracer_colors", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        
        local class_name = args[1];
        local r1 = tonumber(args[2]) or 255;
        local g1 = tonumber(args[3]) or 200;
        local b1 = tonumber(args[4]) or 100;
        local a1 = tonumber(args[5]) or 255;
        local r2 = tonumber(args[6]) or 255;
        local g2 = tonumber(args[7]) or 140;
        local b2 = tonumber(args[8]) or 0;
        local a2 = tonumber(args[9]) or 150;
        
        CONFIG_TYPES["tracer_colors"][class_name] = { Color(r1, g1, b1, a1), Color(r2, g2, b2, a2) };
        
        local color_str = string.format("%d,%d,%d,%d|%d,%d,%d,%d", r1, g1, b1, a1, r2, g2, b2, a2);
        local key = "tracer_colors|" .. class_name;
        local safe_key = sql.SQLStr(key);
        local safe_val = sql.SQLStr(color_str);
        local query = "REPLACE INTO projectile_weapon_data (key, value) VALUES(" .. safe_key .. ", " .. safe_val .. ")";
        local res = sql.Query(query);
        
        if res == false then
            print("sql error saving tracer colors: " .. key .. ": " .. sql.LastError());
        end
        
        net.Start("projectile_weapon_tracer_colors_update");
        net.WriteString(class_name);
        net.WriteUInt(r1, 8);
        net.WriteUInt(g1, 8);
        net.WriteUInt(b1, 8);
        net.WriteUInt(a1, 8);
        net.WriteUInt(r2, 8);
        net.WriteUInt(g2, 8);
        net.WriteUInt(b2, 8);
        net.WriteUInt(a2, 8);
        net.Broadcast();
        
        print("set tracer colors for " .. class_name);
    end, nil, "Set tracer colors for a weapon");

    initialize_db();

    hook.Add("PlayerInitialSpawn", "projectile_config_full_sync", function(ply)
        timer.Simple(1, function()
            send_weapon_config_chunked(ply, false);
        end);
    end)

    net.Receive("projectile_weapon_config_update", function(len, ply)
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
                    print("updated weapon config: " .. cfg_type .. " for " .. class_name);
                    
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
            local is_bool = net.ReadBool();
            local target_table = CONFIG_TYPES[cfg_type];
            if target_table then
                if is_bool then
                    local val = net.ReadBool();
                    print("updated weapon config: " .. cfg_type .. " for " .. class_name .. " -> " .. tostring(val));
                    
                    target_table[class_name] = val;
                    save_config_to_db(cfg_type, class_name, val and 1 or 0);

                    net.Start("projectile_weapon_config_update");
                    net.WriteString(cfg_type);
                    net.WriteString(class_name);
                    net.WriteBool(true);
                    net.WriteBool(val);
                    net.Broadcast();
                else
                    local val = net.ReadFloat();
                    
                    if cfg_type == "tracer_flags" then
                        val = math.floor(val + 0.5);
                    end
                    
                    print("updated weapon config: " .. cfg_type .. " for " .. class_name .. " -> " .. val);
                    
                    target_table[class_name] = val;
                    save_config_to_db(cfg_type, class_name, val);

                    net.Start("projectile_weapon_config_update");
                    net.WriteString(cfg_type);
                    net.WriteString(class_name);
                    net.WriteBool(false);
                    net.WriteFloat(val);
                    net.Broadcast();
                end
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

        --[[[net.Start("projectile_weapon_config_update");
        net.WriteString("tracer_colors");
        net.WriteString(class_name);
        net.WriteColor(tracer_colors[1]);
        net.WriteColor(tracer_colors[2]);
        net.Broadcast();]]
    end, nil, "Set the tracer colors for a weapon");
    
    print("loaded weapon config sql");
end

if CLIENT then
    local weapon_config_chunks = {};
    local weapon_config_expected_chunks = 0;
    local weapon_config_total_size = 0;

    net.Receive("projectile_weapon_config_sync_start", function()
        weapon_config_expected_chunks = net.ReadUInt(16);
        weapon_config_total_size = net.ReadUInt(32);
        weapon_config_chunks = {};

        print("weapon config sync: expecting " .. weapon_config_expected_chunks .. " chunks (" .. weapon_config_total_size .. " bytes)");
    end);

    net.Receive("projectile_weapon_config_sync_chunk", function()
        local chunk_idx = net.ReadUInt(16);
        local chunk_size = net.ReadUInt(32);
        local chunk_data = net.ReadData(chunk_size);

        weapon_config_chunks[chunk_idx] = chunk_data;

        if #weapon_config_chunks == weapon_config_expected_chunks then
            local compressed_data = table.concat(weapon_config_chunks);
            local json_data = util.Decompress(compressed_data);

            if not json_data then
                print("weapon config sync: failed to decompress data");

                return;
            end

            local config_data = util.JSONToTable(json_data);

            if not config_data or #config_data < 15 then
                print("weapon config sync: failed to parse config data");

                return;
            end

            WEAPON_BLACKLIST = config_data[1];
            WEAPON_SPEEDS = config_data[2];
            WEAPON_DAMAGES = config_data[3];
            WEAPON_PENETRATION_POWERS = config_data[4];
            WEAPON_PENETRATION_COUNTS = config_data[5];
            WEAPON_SHAPE = config_data[6];
            WEAPON_COEFFICIENT = config_data[7];
            WEAPON_DRAG = config_data[8];
            WEAPON_MASS = config_data[9];
            WEAPON_CALIBER = config_data[10];
            WEAPON_DROP = config_data[11];
            WEAPON_ZERO_RANGE = config_data[12];
            WEAPON_MIN_SPEED = config_data[13];
            WEAPON_MAX_DISTANCE = config_data[14];
            WEAPON_TRACER_COLORS = config_data[15];
            WEAPON_SPREAD_BIAS = config_data[16];
            WEAPON_DROPOFF_START = config_data[17];
            WEAPON_DROPOFF_END = config_data[18];
            WEAPON_DROPOFF_MIN_MULTIPLIER = config_data[19];
            WEAPON_TRACER_FLAGS = config_data[20] or {};
            if not WEAPON_TRACER_FLAGS["default"] then
                WEAPON_TRACER_FLAGS["default"] = 0;
            end

            CONFIG_TYPES["blacklist"] = WEAPON_BLACKLIST;
            CONFIG_TYPES["speed"] = WEAPON_SPEEDS;
            CONFIG_TYPES["damage"] = WEAPON_DAMAGES;
            CONFIG_TYPES["penetration_power"] = WEAPON_PENETRATION_POWERS;
            CONFIG_TYPES["penetration_count"] = WEAPON_PENETRATION_COUNTS;
            CONFIG_TYPES["shape"] = WEAPON_SHAPE;
            CONFIG_TYPES["coefficient"] = WEAPON_COEFFICIENT;
            CONFIG_TYPES["drag"] = WEAPON_DRAG;
            CONFIG_TYPES["mass"] = WEAPON_MASS;
            CONFIG_TYPES["caliber"] = WEAPON_CALIBER;
            CONFIG_TYPES["drop"] = WEAPON_DROP;
            CONFIG_TYPES["zero_range"] = WEAPON_ZERO_RANGE;
            CONFIG_TYPES["min_speed"] = WEAPON_MIN_SPEED;
            CONFIG_TYPES["max_distance"] = WEAPON_MAX_DISTANCE;
            CONFIG_TYPES["tracer_colors"] = WEAPON_TRACER_COLORS;
            CONFIG_TYPES["tracer_flags"] = WEAPON_TRACER_FLAGS;
            CONFIG_TYPES["spread_bias"] = WEAPON_SPREAD_BIAS;
            CONFIG_TYPES["dropoff_start"] = WEAPON_DROPOFF_START;
            CONFIG_TYPES["dropoff_end"] = WEAPON_DROPOFF_END;
            CONFIG_TYPES["dropoff_min_multiplier"] = WEAPON_DROPOFF_MIN_MULTIPLIER;

            weapon_config_chunks = {};
            weapon_config_expected_chunks = 0;
            weapon_config_total_size = 0;

            print("received full weapon config sync (" .. chunk_idx .. " chunks)");
        end
    end);

    net.Receive("projectile_weapon_config_update", function()
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
            local is_bool = net.ReadBool();
            local target_table = CONFIG_TYPES[cfg_type];
            if target_table then
                if is_bool then
                    local val = net.ReadBool();
                    target_table[class_name] = val;
                    LocalPlayer():ChatPrint("Updated " .. cfg_type .. " for " .. class_name .. " to " .. tostring(val));
                else
                    local val = net.ReadFloat();
                    
                    if cfg_type == "tracer_flags" then
                        val = math.floor(val + 0.5);
                    end
                    
                    target_table[class_name] = val;
                    LocalPlayer():ChatPrint("Updated " .. cfg_type .. " for " .. class_name .. " to " .. val);
                end
            end
        end
    end);

    net.Receive("projectile_weapon_config_reset", function()
        local cfg_type = net.ReadString();
        local class_name = net.ReadString();
        local target_table = CONFIG_TYPES[cfg_type];
        if target_table then
            target_table[class_name] = nil;
            LocalPlayer():ChatPrint("Reset " .. cfg_type .. " for " .. class_name .. " to default");
        end
    end);

    net.Receive("projectile_weapon_tracer_colors_update", function()
        local class_name = net.ReadString();
        local r1 = net.ReadUInt(8);
        local g1 = net.ReadUInt(8);
        local b1 = net.ReadUInt(8);
        local a1 = net.ReadUInt(8);
        local r2 = net.ReadUInt(8);
        local g2 = net.ReadUInt(8);
        local b2 = net.ReadUInt(8);
        local a2 = net.ReadUInt(8);
        
        CONFIG_TYPES["tracer_colors"][class_name] = { Color(r1, g1, b1, a1), Color(r2, g2, b2, a2) };
    end);
end

print("loaded projectile weapon config");