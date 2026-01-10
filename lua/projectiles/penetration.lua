AddCSLuaFile();

local projectiles = projectiles;
local trace_to_exit = trace_to_exit;
local get_surface_data = util.GetSurfaceData;
local MAT_GRATE = MAT_GRATE;
local MAT_GLASS = MAT_GLASS;
local MAT_FLESH = MAT_FLESH;
local MAT_WOOD = MAT_WOOD;
local MAT_METAL = MAT_METAL;
local MAT_PLASTIC = MAT_PLASTIC;
local SURFACE_PROPS_PENETRATION = SURFACE_PROPS_PENETRATION;
local get_convar = GetConVar;
local lower = string.lower;
local debug_overlay = debugoverlay;
local debug_line = debug_overlay.Line;
local debug_box = debug_overlay.Box;
local debug_text = debug_overlay.Text;
local string_split = string.Split;
local string_format = string.format;
local tonumber = tonumber;
local color = Color;
local vector = Vector;

local vector_meta = FindMetaTable("Vector");
local dot = vector_meta.Dot;
local get_normalized = vector_meta.GetNormalized;
local len = vector_meta.Length;
local len_sqr = vector_meta.LengthSqr;
local vec_mul = vector_meta.Mul;
local dist_sqr = vector_meta.DistToSqr;
local distance = vector_meta.Distance;

local tick_count = engine.TickCount;
local max = math.max;
local bxor = bit.bxor;
local band = bit.band;

local function seeded_random(seed, min_val, max_val)
    seed = band(seed, 0xFFFFFFFF);
    seed = bxor(seed, band(seed / 8192, 0xFFFFFFFF));
    seed = band(seed * 48271, 0xFFFFFFFF);
    seed = bxor(seed, band(seed / 131072, 0xFFFFFFFF));
    seed = band(seed, 0x7FFFFFFF);
    return min_val + (seed / 2147483647.0) * (max_val - min_val);
end

local function debug_ricochet(projectile_data, enter_trace, chance, reflect, spread)
    local dur = projectiles["pro_debug_duration"];
    local col_vec = string_split(projectiles["pro_debug_color"], " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_text(enter_trace.HitPos, "ricochet", dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 10), string_format("chance: %.2f", chance), dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 20), string_format("reflect: %.2f %.2f %.2f", reflect.x, reflect.y, reflect.z), dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 30), string_format("spread: %.2f %.2f %.2f", spread.x, spread.y, spread.z), dur, false);
end

--todo: use surface props instead
RICOCHET_MAT_CHANCE_MULTIPLIERS = SURFACE_PROPS_RICOCHET_CHANCE_MULTIPLIERS;

if SERVER then
    util.AddNetworkString("projectile_ricochet_mat_chance_multipliers_sync");
    util.AddNetworkString("projectile_ricochet_mat_chance_multipliers_update");

    local RICOCHET_MAT_CHANCE_MULTIPLIERS_ORIGINAL = table.Copy(RICOCHET_MAT_CHANCE_MULTIPLIERS);
    local RICOCHET_MAT_CHANCE_MULTIPLIERS = RICOCHET_MAT_CHANCE_MULTIPLIERS;

    local net_start = net.Start;
    local write_table = net.WriteTable;
    local write_string = net.WriteString;
    local write_float = net.WriteFloat;
    local broadcast = net.Broadcast;
    local send = net.Send;
    local read_string = net.ReadString;
    local read_float = net.ReadFloat;

    local IsValid = IsValid;
    local tonumber = tonumber;
    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;

    local function initialize_db()
        if sql.TableExists("ricochet_mat_chance_multipliers") then
            local schema = sql.Query("PRAGMA table_info(ricochet_mat_chance_multipliers)");
            if schema and schema[1] then
                local key_type = string.upper(schema[1].type);
                if key_type == "INTEGER" then
                    print("detected old ricochet_mat_chance_multipliers table with integer keys, dropping...");
                    sql.Query("DROP TABLE ricochet_mat_chance_multipliers");
                end
            end
        end

        if not sql.TableExists("ricochet_mat_chance_multipliers") then
            local res = sql.Query("CREATE TABLE ricochet_mat_chance_multipliers (key TEXT PRIMARY KEY, value FLOAT)");
            if res == false then
                print("sql error creating ricochet_mat_chance_multipliers table: " .. sql.LastError());
            end
        else
            local data = sql.Query("SELECT * FROM ricochet_mat_chance_multipliers");
            if data then
                for idx, row in ipairs(data) do
                    local key = row.key;
                    local val = tonumber(row.value);
                    RICOCHET_MAT_CHANCE_MULTIPLIERS[key] = val;
                    print("loaded ricochet mat chance multiplier: " .. key .. " -> " .. val);
                end
            end
        end
    end

    initialize_db();

    local function save_ricochet_mat_multiplier_to_db(surface_prop, chance)
        local safe_key = sql.SQLStr(surface_prop);
        local query = "REPLACE INTO ricochet_mat_chance_multipliers (key, value) VALUES(" .. safe_key .. ", " .. chance .. ")";
        local res = sql.Query(query);
        
        if res == false then
            print("sql error saving ricochet mat chance multiplier: " .. surface_prop .. ": " .. chance .. ": " .. sql.LastError());
        end
    end

    local function update_ricochet_mat_chance_multipliers(surface_prop, chance)
        RICOCHET_MAT_CHANCE_MULTIPLIERS[surface_prop] = chance;
        save_ricochet_mat_multiplier_to_db(surface_prop, chance);
        net_start("projectile_ricochet_mat_chance_multipliers_update");
        write_string(surface_prop);
        write_float(chance);
        broadcast();
    end

    hook.Add("PlayerInitialSpawn", "ProjectilesRicochetMatChanceMultipliers", function(player)
        timer.Simple(1, function()
            if not IsValid(player) then return; end
            net_start("projectile_ricochet_mat_chance_multipliers_sync");
            write_table(RICOCHET_MAT_CHANCE_MULTIPLIERS);
            send(player);
        end);
    end);

    concommand.Add("pro_ricochet_surfaceprop_update", function(player, cmd, args)
        if not IsValid(player) then 
            return; 
        elseif not is_superadmin(player) then
            player:ChatPrint("You are not authorized to use this command.");
            return;
        end

        local surface_prop = args[1];
        if not surface_prop then
            player:ChatPrint("Invalid surface prop: " .. tostring(args[1]));
            return;
        end

        local chance = tonumber(args[2]);
        if not chance then
            player:ChatPrint("Invalid chance: " .. tostring(args[2]));
            return;
        end

        update_ricochet_mat_chance_multipliers(surface_prop, chance);
    end, nil, "Update the ricochet surface prop chance multipliers");

    concommand.Add("pro_ricochet_surfaceprop_reset", function(player, cmd, args)
        if not IsValid(player) then 
            return; 
        elseif not is_superadmin(player) then
            player:ChatPrint("You are not authorized to use this command.");
            return;
        end
        
        table.CopyFromTo(RICOCHET_MAT_CHANCE_MULTIPLIERS_ORIGINAL, RICOCHET_MAT_CHANCE_MULTIPLIERS);
        net_start("projectile_ricochet_mat_chance_multipliers_sync");
        write_table(RICOCHET_MAT_CHANCE_MULTIPLIERS);
        broadcast();

        print("reset ricochet mat chance multipliers");
    end, nil, "Reset the ricochet surface prop chance multipliers");
end

local RICOCHET_MAT_CHANCE_MULTIPLIERS = RICOCHET_MAT_CHANCE_MULTIPLIERS;

if CLIENT then
    net.Receive("projectile_ricochet_mat_chance_multipliers_sync", function()
        table.CopyFromTo(net.ReadTable(), RICOCHET_MAT_CHANCE_MULTIPLIERS);
        print("received full ricochet mat chance multipliers sync");
        LocalPlayer():ChatPrint("Received full ricochet mat chance multipliers sync");
    end);
    
    net.Receive("projectile_ricochet_mat_chance_multipliers_update", function()
        local surface_prop = net.ReadString();
        local chance = net.ReadFloat();
        RICOCHET_MAT_CHANCE_MULTIPLIERS[surface_prop] = chance;
        print("updated ricochet mat chance multiplier for " .. surface_prop .. " to " .. chance);
        LocalPlayer():ChatPrint("Updated ricochet mat chance multiplier for " .. surface_prop .. " to " .. chance);
    end);
end

function handle_penetration(shooter, projectile_data, src, dir, penetration_power, enter_trace)
    if not enter_trace.MatType then 
        return true, nil, nil;
    end

    local enter_surf_data = get_surface_data(enter_trace.SurfaceProps);
    if projectiles["pro_ricochet_enabled"] then
        local enter_name = enter_surf_data and enter_surf_data.name and lower(enter_surf_data.name) or "unknown";
        local hit_normal = enter_trace.HitNormal;
        local dot_result = dot(dir, hit_normal);
    
        local seed_base = projectile_data.random_seed + projectile_data.penetration_count * 1000;
        local chance = seeded_random(seed_base, 0, 1);
        local mat_chance = RICOCHET_MAT_CHANCE_MULTIPLIERS[enter_name];
        local angle_scale = 1.0 + dot_result;
        local chance_threshold = projectiles["pro_ricochet_chance"] * mat_chance * angle_scale;
        if chance < chance_threshold then
            local reflect = dir - (2 * dot_result * hit_normal);
            local spread_x = seeded_random(seed_base * 73856093, -1, 1);
            local spread_y = seeded_random(seed_base * 19349663, -1, 1);
            local spread_z = seeded_random(seed_base * 83492791, -1, 1);
            local spread = vector(spread_x, spread_y, spread_z);    
            vec_mul(spread, projectiles["pro_ricochet_spread"]);
    
            projectile_data.dir = get_normalized(reflect + spread);
            projectile_data.speed = projectile_data.speed * projectiles["pro_ricochet_speed_multiplier"];
            projectile_data.damage = projectile_data.damage * projectiles["pro_ricochet_damage_multiplier"];
            projectile_data.pos = enter_trace.HitPos + (projectile_data.dir * 2);
    
            if projectiles["pro_debug_ricochet"] then debug_ricochet(projectile_data, enter_trace, chance, reflect, spread); end

            return false, nil, nil;
        end
    end

    if projectile_data.penetration_count <= 0 or projectile_data.penetration_power <= 0.0 then 
        return true, nil, nil;
    end

    local exit_pos, exit_trace = trace_to_exit(enter_trace, src, dir, projectile_data.mins, projectile_data.maxs, shooter);
    if not exit_pos then
        return true, nil, nil;
    end

    local exit_surf_data = get_surface_data(exit_trace.SurfaceProps);

    local exit_name = exit_surf_data and exit_surf_data.name and lower(exit_surf_data.name) or "unknown";
    local enter_name = enter_surf_data and enter_surf_data.name and lower(enter_surf_data.name) or "unknown";
    
    local exit_pen = 1.0 - (exit_surf_data and SURFACE_PROPS_PENETRATION[exit_name] or 1.0);
    local enter_pen = 1.0 - (enter_surf_data and SURFACE_PROPS_PENETRATION[enter_name] or 1.0);

    local resistance = (enter_pen + exit_pen) * 0.5;
    
    local entry_cost_mult = projectiles["pro_penetration_entry_cost_multiplier"];
    local entry_cost = enter_pen * entry_cost_mult;
    local exit_cost = exit_pen * (entry_cost_mult * projectiles["pro_penetration_exit_cost_multiplier"]);

    local dist = distance(exit_trace.HitPos, enter_trace.HitPos);
    
    local thickness_scale = 1.0;
    local thin_threshold = projectiles["pro_penetration_thin_material_threshold"];
    if dist < thin_threshold and thin_threshold > 0 then
        local min_scale = projectiles["pro_penetration_thin_material_scale"];
        local thickness_ratio = dist / thin_threshold;
        thickness_scale = min_scale + (thickness_ratio * (1.0 - min_scale));
    end
    
    local power_cost_multiplier = projectiles["pro_penetration_power_cost_multiplier"];
    local power_cost = (dist * (resistance + entry_cost + exit_cost)) * power_cost_multiplier * thickness_scale;
    if projectile_data.penetration_power < power_cost then
        return true, nil, nil;
    end

    local dmg_tax_per_unit = projectiles["pro_penetration_dmg_tax_per_unit"];
    local dmg_loss = dmg_tax_per_unit * dist * (resistance + entry_cost + exit_cost) * thickness_scale;

    projectile_data.damage = projectile_data.damage - dmg_loss;

    if projectile_data.damage < 1.0 then
        return true, nil, nil;
    end

    projectile_data.penetration_count = projectile_data.penetration_count - 1;
    projectile_data.penetration_power = projectile_data.penetration_power - power_cost;
    
    return false, exit_trace.HitPos, exit_trace;
end

--todo: make this configurable
local HITGROUP_MULTIPLIERS = {
    [HITGROUP_GENERIC] = 1.0,
    [HITGROUP_HEAD] = 4.0,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.0,
    [HITGROUP_LEFTARM] = 1.0,
    [HITGROUP_RIGHTARM] = 1.0,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
    [HITGROUP_GEAR] = 1.0,
};

function get_damage_multiplier(hitgroup)
    if not projectiles["pro_damage_scaling"] then
        return 1.0;
    end

    return HITGROUP_MULTIPLIERS[hitgroup] or 1.0;
end

print("loaded projectiles penetration");