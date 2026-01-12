AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    util.AddNetworkString("projectile");
end

local band = bit.band;
local cur_time = CurTime;
local vector = Vector;
local tick_interval = engine.TickInterval();
local NULL = NULL;
local maxplayers = game.MaxPlayers();

local entity_meta = FindMetaTable("Entity");
local entindex = entity_meta.EntIndex;

projectile_store = projectile_store or {};
local projectile_store = projectile_store;

local BUFFER_SIZE_PLAYERS = 256; -- must be power of 2
local BUFFER_SIZE_NPCS = 128; -- must be power of 2

local zero_color = Color(0, 0, 0, 0);

function create_new_projectile_store(shooter)
    --print("creating new projectile store for shooter", shooter);
    projectile_store[shooter] = {
        received = 0,
        last_received_idx = 0,
        buffer = {},
        active_projectiles = {},
        buffer_size = entindex(shooter) > maxplayers and BUFFER_SIZE_NPCS or BUFFER_SIZE_PLAYERS,
    };

    for i = 1, projectile_store[shooter].buffer_size do
        projectile_store[shooter].buffer[i] = {
            hit = true,
            weapon = NULL,
            time = 0.0,
            pos = vector(),
            dir = vector(),
            speed = 0.0,
            damage = 0.0,
            damage_initial = 0.0,
            drag = 0.0,
            penetration_power = 0.0,
            penetration_count = 0,
            last_hit_entity = NULL,
            mass = 0.0,
            drop = 0.0,
            min_speed = 0.0,
            distance_traveled = 0.0,
            max_distance = 0.0,
            random_seed = 0,
            old_pos = vector(),
            trace_filter = {NULL, NULL, NULL},
            tracer_colors = {zero_color, zero_color},
            is_gmod_turret = false,
            spawn_pos = vector(),
            spawn_time = 0.0,
            vel = vector(),
            old_vel = vector(),
            dropoff_start = 0.0,
            dropoff_end = 0.0,
            dropoff_min_multiplier = 0.0,
            ammo_type = "",
        };
    end

    projectile_store[shooter].active_projectiles = {};
end

if SERVER then
    local entity_meta = FindMetaTable("Entity");
    local eye_pos = entity_meta.EyePos;

    local convar_meta = FindMetaTable("ConVar");
    local get_bool = convar_meta.GetBool;
    local get_int = convar_meta.GetInt;

    local net_start = net.Start;
    local write_entity = net.WriteEntity;
    local write_vector = net.WriteVector;
    local write_float = net.WriteFloat;
    local write_uint = net.WriteUInt;
    local write_color = net.WriteColor;
    local write_bool = net.WriteBool;
    local write_string = net.WriteString;
    local send_pvs = net.SendPVS;
    local send_pas = net.SendPAS;
    local broadcast = net.Broadcast;

    local floor = math.floor;
    local bxor = bit.bxor;

    local vector = Vector;

    local engine_tick_count = engine.TickCount;

    local cv_net_send_method = GetConVar("pro_net_send_method");

    local function hash_projectile(px, py, pz, dx, dy, dz)
        local h = floor(px * 0.1) * 73856093 + floor(py * 0.1) * 19349663 + floor(pz * 0.1) * 83492791;
        h = h + floor(dx * 10000) * 2654435761 + floor(dy * 10000) * 2246822519 + floor(dz * 10000) * 3266489917;
        h = band(h, 0xFFFFFFFF);
        h = bxor(h, band(h / 8192, 0xFFFFFFFF));
        h = band(h * 48271, 0xFFFFFFFF);
        return band(h, 0x7FFFFFFF);
    end

    function broadcast_projectile(shooter, weapon, pos, dir, speed, damage, drag, penetration_power, penetration_count, mass, drop, min_speed, max_distance, tracer_colors, is_gmod_turret, dropoff_start, dropoff_end, dropoff_min_multiplier, ammo_type, reliable, bullet_idx)
        weapon.bullet_idx = (weapon.bullet_idx or 0) + 1;

        local time = cur_time();
        local tick = floor(0.5 + time / tick_interval);
        
        local seed_counter = band(tick * 73856093 + entindex(shooter) * 19349663 + (bullet_idx or 1) * 83492791, 0x7FFFFFFF);

        net_start("projectile", not reliable);
        write_entity(shooter);
        write_entity(weapon);
        write_float(pos.x); -- we write individual components to prevent precision issues
        write_float(pos.y);
        write_float(pos.z);
        write_float(dir.x);
        write_float(dir.y);
        write_float(dir.z);
        write_uint(speed, 16);
        write_uint(damage, 16);
        write_uint(penetration_count, 8);
        write_float(drag);
        write_float(penetration_power);
        write_float(mass);
        write_float(drop);
        write_float(min_speed);
        write_float(max_distance);
        write_uint(seed_counter, 32); -- random seed for ricochet
        write_color(tracer_colors[1]);
        write_color(tracer_colors[2]);
        write_bool(is_gmod_turret);
        write_float(dropoff_start);
        write_float(dropoff_end);
        write_float(dropoff_min_multiplier);
        write_uint(tick, 32);
        write_string(ammo_type);

        local send_method = get_int(cv_net_send_method);
        if send_method == 0 then
            send_pvs(pos);
        elseif send_method == 1 then
            send_pas(pos);
        else
            broadcast();
        end

        if not projectile_store[shooter] then 
            create_new_projectile_store(shooter);
        end

        projectile_store[shooter].last_received_idx = projectile_store[shooter].last_received_idx + 1;
        local projectile_idx = band(projectile_store[shooter].last_received_idx - 1, projectile_store[shooter].buffer_size - 1) + 1;

        local projectile = projectile_store[shooter].buffer[projectile_idx];
        projectile.weapon = weapon;
        projectile.time = time;
        projectile.pos.x = pos.x;
        projectile.pos.y = pos.y;
        projectile.pos.z = pos.z;
        projectile.dir.x = dir.x;
        projectile.dir.y = dir.y;
        projectile.dir.z = dir.z;
        projectile.speed = speed;
        projectile.damage = damage;
        projectile.damage_initial = damage;
        projectile.drag = drag;
        projectile.penetration_power = penetration_power;
        projectile.penetration_count = penetration_count;
        projectile.last_hit_entity = nil;
        projectile.hit = false;
        projectile.mass = mass;
        projectile.drop = drop;
        projectile.min_speed = min_speed;
        projectile.distance_traveled = 0.0;
        projectile.max_distance = max_distance;
        projectile.random_seed = seed_counter;
        projectile.old_pos.x = pos.x;
        projectile.old_pos.y = pos.y;
        projectile.old_pos.z = pos.z;
        projectile.tracer_colors[1] = tracer_colors[1];
        projectile.tracer_colors[2] = tracer_colors[2];
        projectile.is_gmod_turret = is_gmod_turret;
        projectile.spawn_pos.x = pos.x;
        projectile.spawn_pos.y = pos.y;
        projectile.spawn_pos.z = pos.z;
        projectile.spawn_time = time;
        projectile.vel.x = dir.x * speed;
        projectile.vel.y = dir.y * speed;
        projectile.vel.z = dir.z * speed;
        projectile.old_vel.x = projectile.vel.x;
        projectile.old_vel.y = projectile.vel.y;
        projectile.old_vel.z = projectile.vel.z;
        projectile.dropoff_start = dropoff_start;
        projectile.dropoff_end = dropoff_end;
        projectile.dropoff_min_multiplier = dropoff_min_multiplier;
        projectile.ammo_type = ammo_type;
        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;

        --print("random seed on server", seed_counter);
    end
end

if CLIENT then
    local local_player = LocalPlayer;
    local read_entity = net.ReadEntity;
    local read_vector = net.ReadVector;
    local read_float = net.ReadFloat;
    local read_uint = net.ReadUInt;
    local read_color = net.ReadColor;
    local read_bool = net.ReadBool;
    local read_string = net.ReadString;
    local vector = Vector;
    local is_singleplayer = game.SinglePlayer();

    net.Receive("projectile", function()
        local shooter = read_entity();
        if not is_singleplayer and shooter == local_player() then return; end -- todo: probably better way to handle singleplayer sessions

        local weapon = read_entity();
        local pos_x = read_float();
        local pos_y = read_float();
        local pos_z = read_float();
        local dir_x = read_float();
        local dir_y = read_float();
        local dir_z = read_float();
        local speed = read_uint(16);
        local damage = read_uint(16);
        local penetration_count = read_uint(8);
        local drag = read_float();
        local penetration_power = read_float();
        local mass = read_float();
        local drop = read_float();
        local min_speed = read_float();
        local max_distance = read_float();
        local random_seed = read_uint(32);
        local tracer_color_core = read_color();
        local tracer_color_glow = read_color();
        local is_gmod_turret = read_bool();
        local dropoff_start = read_float();
        local dropoff_end = read_float();
        local dropoff_min_multiplier = read_float();
        local tick = read_uint(32);
        local ammo_type = read_string();

        if not projectile_store[shooter] then 
            create_new_projectile_store(shooter);
        end

        projectile_store[shooter].last_received_idx = projectile_store[shooter].last_received_idx + 1;
        local projectile_idx = band(projectile_store[shooter].last_received_idx - 1, projectile_store[shooter].buffer_size - 1) + 1;

        local projectile = projectile_store[shooter].buffer[projectile_idx];
        projectile.weapon = weapon;
        projectile.time = tick * tick_interval;
        projectile.pos.x = pos_x;
        projectile.pos.y = pos_y;
        projectile.pos.z = pos_z;
        projectile.dir.x = dir_x;
        projectile.dir.y = dir_y;
        projectile.dir.z = dir_z;
        projectile.speed = speed;
        projectile.damage = damage;
        projectile.damage_initial = damage;
        projectile.drag = drag;
        projectile.penetration_power = penetration_power;
        projectile.penetration_count = penetration_count;
        projectile.last_hit_entity = nil;
        projectile.hit = false;
        projectile.mass = mass;
        projectile.drop = drop;
        projectile.min_speed = min_speed;
        projectile.distance_traveled = 0.0;
        projectile.max_distance = max_distance;
        projectile.random_seed = random_seed;
        projectile.old_pos.x = pos_x;
        projectile.old_pos.y = pos_y;
        projectile.old_pos.z = pos_z;
        projectile.tracer_colors[1] = tracer_color_core;
        projectile.tracer_colors[2] = tracer_color_glow;
        projectile.is_gmod_turret = is_gmod_turret;
        projectile.spawn_pos.x = pos_x;
        projectile.spawn_pos.y = pos_y;
        projectile.spawn_pos.z = pos_z;
        projectile.spawn_time = tick * tick_interval;
        projectile.vel.x = dir_x * speed;
        projectile.vel.y = dir_y * speed;
        projectile.vel.z = dir_z * speed;
        projectile.old_vel.x = projectile.vel.x;
        projectile.old_vel.y = projectile.vel.y;
        projectile.old_vel.z = projectile.vel.z;
        projectile.dropoff_start = dropoff_start;
        projectile.dropoff_end = dropoff_end;
        projectile.dropoff_min_multiplier = dropoff_min_multiplier;
        projectile.ammo_type = ammo_type;
        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;
    end)
end

print("loaded projectiles net")