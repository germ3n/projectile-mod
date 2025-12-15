AddCSLuaFile();

local projectiles = projectiles;
local trace_to_exit = trace_to_exit;
local get_surface_data = util.GetSurfaceData;
local rand = math.Rand;
local vector_rand = VectorRand;
local MAT_GRATE = MAT_GRATE;
local MAT_GLASS = MAT_GLASS;
local MAT_FLESH = MAT_FLESH;
local MAT_WOOD = MAT_WOOD;
local MAT_METAL = MAT_METAL;
local MAT_PLASTIC = MAT_PLASTIC;
local SURFACE_PROPS_PENETRATION = SURFACE_PROPS_PENETRATION;
local random_seed = math.randomseed;
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

local cv_ricochet_enabled = get_convar("pro_ricochet_enabled");
local cv_ricochet_chance = get_convar("pro_ricochet_chance");
local cv_ricochet_spread = get_convar("pro_ricochet_spread");
local cv_ricochet_speed_multiplier = get_convar("pro_ricochet_speed_multiplier");
local cv_ricochet_damage_multiplier = get_convar("pro_ricochet_damage_multiplier");
local cv_penetration_power_cost_multiplier = get_convar("pro_penetration_power_cost_multiplier");
local cv_penetration_dmg_tax_per_unit = get_convar("pro_penetration_dmg_tax_per_unit");
local cv_penetration_entry_cost_multiplier = get_convar("pro_penetration_entry_cost_multiplier");
local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;
local get_string = convar_meta.GetString;

local vector_meta = FindMetaTable("Vector");
local dot = vector_meta.Dot;
local get_normalized = vector_meta.GetNormalized;
local len = vector_meta.Length;
local len_sqr = vector_meta.LengthSqr;
local mul = vector_meta.Mul;
local dist_sqr = vector_meta.DistToSqr;
local distance = vector_meta.Distance;

local tick_count = engine.TickCount;
local max = math.max;

local MAX_DISTANCE = 90 * 90;

local cv_debug_dur = get_convar("pro_debug_duration");
local cv_debug_col = get_convar("pro_debug_color");
local cv_debug_ricochet = get_convar("pro_debug_ricochet");

local function debug_ricochet(projectile_data, enter_trace, chance, reflect, spread)
    local dur = get_float(cv_debug_dur);
    local col_vec = string_split(get_string(cv_debug_col), " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_text(enter_trace.HitPos, "ricochet", dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 10), string_format("chance: %.2f", chance), dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 20), string_format("reflect: %.2f %.2f %.2f", reflect.x, reflect.y, reflect.z), dur, false);
    debug_text(enter_trace.HitPos + vector(0, 0, 30), string_format("spread: %.2f %.2f %.2f", spread.x, spread.y, spread.z), dur, false);
end

RICOCHET_MAT_CHANCE_MULTIPLIERS = {
    [MAT_ANTLION] = 0.0,
    [MAT_BLOODYFLESH] = 0.0,
    [MAT_CONCRETE] = 0.7,
    [MAT_DIRT] = 0.0,
    [MAT_EGGSHELL] = 0.6,
    [MAT_FLESH] = 0.0,
    [MAT_GRATE] = 0.0,
    [MAT_ALIENFLESH] = 0.0,
    [MAT_CLIP] = 0.0,
    [MAT_SNOW] = 0.0,
    [MAT_PLASTIC] = 0.0,
    [MAT_METAL] = 0.9,
    [MAT_SAND] = 0.0,
    [MAT_FOLIAGE] = 0.0,
    [MAT_COMPUTER] = 0.8,
    [MAT_SLOSH] = 0.0,
    [MAT_TILE] = 0.6,
    [MAT_GRASS] = 0.0,
    [MAT_VENT] = 0.0,
    [MAT_WOOD] = 0.1,
    [MAT_DEFAULT] = 0.0,
    [MAT_GLASS] = 0.0,
    [MAT_WARPSHIELD] = 0.9,
};

MAT_TYPE_NAMES = {
    [MAT_ANTLION] = "MAT_ANTLION",
    [MAT_BLOODYFLESH] = "MAT_BLOODYFLESH",
    [MAT_CONCRETE] = "MAT_CONCRETE",
    [MAT_DIRT] = "MAT_DIRT",
    [MAT_EGGSHELL] = "MAT_EGGSHELL",
    [MAT_FLESH] = "MAT_FLESH",
    [MAT_GRATE] = "MAT_GRATE",
    [MAT_ALIENFLESH] = "MAT_ALIENFLESH",
    [MAT_CLIP] = "MAT_CLIP",
    [MAT_SNOW] = "MAT_SNOW",
    [MAT_PLASTIC] = "MAT_PLASTIC",
    [MAT_METAL] = "MAT_METAL",
    [MAT_SAND] = "MAT_SAND",
    [MAT_FOLIAGE] = "MAT_FOLIAGE",
    [MAT_COMPUTER] = "MAT_COMPUTER",
    [MAT_SLOSH] = "MAT_SLOSH",
    [MAT_TILE] = "MAT_TILE",
    [MAT_GRASS] = "MAT_GRASS",
    [MAT_VENT] = "MAT_VENT",
    [MAT_WOOD] = "MAT_WOOD",
    [MAT_DEFAULT] = "MAT_DEFAULT",
    [MAT_GLASS] = "MAT_GLASS",
    [MAT_WARPSHIELD] = "MAT_WARPSHIELD",
};

if SERVER then
    util.AddNetworkString("projectile_ricochet_mat_chance_multipliers_sync");
    util.AddNetworkString("projectile_ricochet_mat_chance_multipliers_update");

    local RICOCHET_MAT_CHANCE_MULTIPLIERS_ORIGINAL = table.Copy(RICOCHET_MAT_CHANCE_MULTIPLIERS);
    local RICOCHET_MAT_CHANCE_MULTIPLIERS = RICOCHET_MAT_CHANCE_MULTIPLIERS;

    local net_start = net.Start;
    local write_table = net.WriteTable;
    local write_string = net.WriteString;
    local write_float = net.WriteFloat;
    local write_uint = net.WriteUInt;
    local broadcast = net.Broadcast;
    local send = net.Send;

    local IsValid = IsValid;
    local tonumber = tonumber;
    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;

    local function initialize_db()
        if not sql.TableExists("ricochet_mat_chance_multipliers") then
            local res = sql.Query("CREATE TABLE ricochet_mat_chance_multipliers (key INTEGER PRIMARY KEY, value FLOAT)");
            if res == false then
                print("sql error creating ricochet_mat_chance_multipliers table: " .. sql.LastError());
            end
        else
            local data = sql.Query("SELECT * FROM ricochet_mat_chance_multipliers");
            --print(data);
            if data then
                --PrintTable(data);
                for idx, row in ipairs(data) do
                    local key = tonumber(row.key);
                    local val = tonumber(row.value);
                    RICOCHET_MAT_CHANCE_MULTIPLIERS[key] = val;
                    print("loaded ricochet mat chance multiplier: " .. key .. " -> " .. val);
                end
            end
        end
    end

    initialize_db();

    local function save_ricochet_mat_multiplier_to_db(mat_type, chance)
        local query = "REPLACE INTO ricochet_mat_chance_multipliers (key, value) VALUES(" .. mat_type .. ", " .. chance .. ")";
        --print(query);
        local res = sql.Query(query);
        
        if res == false then
            print("sql error saving ricochet mat chance multiplier: " .. mat_type .. ": " .. chance .. ": " .. sql.LastError());
        end
    end

    local function update_ricochet_mat_chance_multipliers(mat_type, chance)
        RICOCHET_MAT_CHANCE_MULTIPLIERS[mat_type] = chance;
        save_ricochet_mat_multiplier_to_db(mat_type, chance);
        net_start("projectile_ricochet_mat_chance_multipliers_update");
        write_uint(mat_type, 8);
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

    concommand.Add("pro_ricochet_mat_chance_multipliers_update", function(player, cmd, args)
        if not IsValid(player) then 
            return; 
        elseif not is_superadmin(player) then
            player:ChatPrint("You are not authorized to use this command.");
            return;
        end

        local mat_type = tonumber(args[1]) or _G[args[1]];
        if not mat_type then
            player:ChatPrint("Invalid mat type: " .. args[1]);
            return;
        end

        local chance = tonumber(args[2]);
        if not chance then
            player:ChatPrint("Invalid chance: " .. args[2]);
            return;
        end

        update_ricochet_mat_chance_multipliers(mat_type, tonumber(chance));
    end, nil, "Update the ricochet mat chance multipliers");

    concommand.Add("pro_ricochet_mat_chance_multipliers_reset", function(player, cmd, args)
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
    end, nil, "Reset the ricochet mat chance multipliers");
end

local RICOCHET_MAT_CHANCE_MULTIPLIERS = RICOCHET_MAT_CHANCE_MULTIPLIERS;

if CLIENT then
    net.Receive("projectile_ricochet_mat_chance_multipliers_sync", function()
        table.CopyFromTo(net.ReadTable(), RICOCHET_MAT_CHANCE_MULTIPLIERS);
        print("received full ricochet mat chance multipliers sync");
        LocalPlayer():ChatPrint("Received full ricochet mat chance multipliers sync");
    end);
    
    net.Receive("projectile_ricochet_mat_chance_multipliers_update", function()
        local mat_type = net.ReadUInt(8);
        local chance = net.ReadFloat();
        RICOCHET_MAT_CHANCE_MULTIPLIERS[mat_type] = chance;
        print("updated ricochet mat chance multiplier for " .. mat_type .. " to " .. chance);
        LocalPlayer():ChatPrint("Updated ricochet mat chance multiplier for " .. mat_type .. " to " .. chance);
    end);
end

function handle_penetration(shooter, projectile_data, src, dir, penetration_power, enter_trace)
    if not enter_trace.MatType then 
        return true, nil, nil;
    end

    if get_bool(cv_ricochet_enabled) then
        random_seed(projectile_data.random_seed + projectile_data.penetration_count);

        local hit_normal = enter_trace.HitNormal;
        local dot_result = dot(dir, hit_normal);
    
        local chance = rand(0, 1);
        local mat_chance = RICOCHET_MAT_CHANCE_MULTIPLIERS[enter_trace.MatType] or RICOCHET_MAT_CHANCE_MULTIPLIERS[MAT_DEFAULT];
        local angle_scale = 1.0 + dot_result;
        local chance_threshold = get_float(cv_ricochet_chance) * mat_chance * angle_scale;
        if chance < chance_threshold then
            local reflect = dir - (2 * dot_result * hit_normal);
            local spread = vector_rand();
            mul(spread, get_float(cv_ricochet_spread));
    
            projectile_data.dir = get_normalized(reflect + spread);
            projectile_data.speed = projectile_data.speed * get_float(cv_ricochet_speed_multiplier);
            projectile_data.damage = projectile_data.damage * get_float(cv_ricochet_damage_multiplier);
            projectile_data.pos = enter_trace.HitPos + (projectile_data.dir * 2);
    
            if get_bool(cv_debug_ricochet) then debug_ricochet(projectile_data, enter_trace, chance, reflect, spread); end

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

    local enter_surf_data = get_surface_data(enter_trace.SurfaceProps);
    local exit_surf_data = get_surface_data(exit_trace.SurfaceProps);

    local enter_mat = enter_trace.MatType;
    local exit_mat = exit_trace.MatType;

    local is_grate_surf = (enter_mat == MAT_GRATE) or (enter_mat == MAT_GLASS);
    local resistance = 1.0;
    local entry_cost = 0.0;

    if is_grate_surf then
        resistance = 0.05;
        entry_cost = 0.05;
    --elseif enter_mat == MAT_FLESH then 
        --resistance = 0.05;
        --entry_cost = 1.0;
    else
        local exit_name = exit_surf_data and exit_surf_data.name and lower(exit_surf_data.name) or "unknown";
        local enter_name = enter_surf_data and enter_surf_data.name and lower(enter_surf_data.name) or "unknown";
        local exit_pen = 1.0 - (exit_surf_data and SURFACE_PROPS_PENETRATION[exit_name] or 1.0);
        local enter_pen = 1.0 - (enter_surf_data and SURFACE_PROPS_PENETRATION[enter_name] or 1.0);

        resistance = (enter_pen + exit_pen) * 0.5;
        entry_cost = enter_pen * get_float(cv_penetration_entry_cost_multiplier);
    end

    local dist = distance(exit_trace.HitPos, enter_trace.HitPos);
    local power_cost_multiplier = get_float(cv_penetration_power_cost_multiplier);
    local power_cost = (dist * (resistance + entry_cost)) * power_cost_multiplier;
    if projectile_data.penetration_power < power_cost then
        return true, nil, nil;
    end

    local dmg_tax_per_unit = get_float(cv_penetration_dmg_tax_per_unit);
    local dmg_loss = dmg_tax_per_unit * dist * (resistance + entry_cost);

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
    return HITGROUP_MULTIPLIERS[hitgroup] or 1.0;
end

print("loaded projectiles penetration");