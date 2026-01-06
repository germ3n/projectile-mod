AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    util.AddNetworkString("projectile");
end

local band = bit.band;
local cur_time = CurTime;
local tick_interval = engine.TickInterval();

projectile_store = projectile_store or {};
local projectile_store = projectile_store;

local BUFFER_SIZE = 0x400; -- must be power of 2

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
    local send_pvs = net.SendPVS;
    local send_pas = net.SendPAS;
    local broadcast = net.Broadcast;

    local crc = util.CRC;
    local tonumber = tonumber;
    local floor = math.floor;

    local vector = Vector;

    local engine_tick_count = engine.TickCount;

    local cv_net_send_method = GetConVar("pro_net_send_method");

    function broadcast_projectile(shooter, weapon, pos, dir, speed, damage, drag, penetration_power, penetration_count, mass, drop, min_speed, max_distance, tracer_colors, is_gmod_turret, dropoff_start, dropoff_end, dropoff_min_multiplier, reliable)
        weapon.bullet_idx = (weapon.bullet_idx or 0) + 1;

        local time = cur_time();
        local tick = floor(0.5 + time / tick_interval);
        local random_seed = tonumber(crc(tostring(pos) .. tostring(dir))); -- random seed for ricochet

        net_start("projectile", reliable and false or true);
        write_entity(shooter);
        write_entity(weapon);
        --write_uint(band(weapon.bullet_idx, 255), 8);
        write_float(time);
        --write_vector(pos);
        --write_vector(dir);
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
        write_uint(random_seed, 32); -- random seed for ricochet
        write_color(tracer_colors[1]);
        write_color(tracer_colors[2]);
        write_bool(is_gmod_turret);
        write_float(dropoff_start);
        write_float(dropoff_end);
        write_float(dropoff_min_multiplier);
        write_uint(tick, 32);

        local send_method = get_int(cv_net_send_method);
        if send_method == 0 then
            send_pvs(pos);
        elseif send_method == 1 then
            send_pas(pos);
        else
            broadcast();
        end

        if not projectile_store[shooter] then 
            projectile_store[shooter] = {
                received = 0,
                last_received_idx = 0,
                buffer = {},
                active_projectiles = {},
                buffer_size = BUFFER_SIZE, -- N projectiles
            };

            for i = 1, BUFFER_SIZE do
                projectile_store[shooter].buffer[i] = {
                    hit = true,
                    weapon = nil,
                    time = nil,
                    pos = vector(),
                    dir = vector(),
                    speed = nil,
                    damage = nil,
                    damage_initial = nil,
                    drag = nil,
                    penetration_power = nil,
                    penetration_count = nil,
                    last_hit_entity = nil,
                    mass = nil,
                    drop = nil,
                    min_speed = nil,
                    distance_traveled = nil,
                    max_distance = nil,
                    random_seed = nil,
                    old_pos = vector(),
                    trace_filter = {nil, nil, nil},
                    tracer_colors = {nil, nil},
                    is_gmod_turret = false,
                    spawn_pos = vector(),
                    spawn_time = nil,
                    vel = vector(),
                    old_vel = vector(),
                    dropoff_start = nil,
                    dropoff_end = nil,
                    dropoff_min_multiplier = nil,
                };
            end

            projectile_store[shooter].active_projectiles = {};
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
        projectile.random_seed = random_seed;
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
        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;
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
    local vector = Vector;

    net.Receive("projectile", function()
        local shooter = read_entity();
        --if shooter == local_player then return; end -- no need to process own projectiles

        local weapon = read_entity();
        local time = read_float();
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

        if not projectile_store[shooter] then 
            projectile_store[shooter] = {
                received = 0,
                last_received_idx = 0,
                buffer = {},
                buffer_size = BUFFER_SIZE, -- N projectiles
            };

            for i = 1, BUFFER_SIZE do
                projectile_store[shooter].buffer[i] = {
                    hit = true,
                    weapon = nil,
                    time = nil,
                    pos = vector(),
                    dir = vector(),
                    speed = nil,
                    damage = nil,
                    damage_initial = nil,
                    drag = nil,
                    penetration_power = nil,
                    penetration_count = nil,
                    last_hit_entity = nil,
                    mass = nil,
                    drop = nil,
                    min_speed = nil,
                    distance_traveled = nil,
                    max_distance = nil,
                    random_seed = nil,
                    old_pos = vector(),
                    trace_filter = {nil, nil, nil},
                    tracer_colors = {nil, nil},
                    is_gmod_turret = false,
                    spawn_pos = vector(),
                    spawn_time = nil,
                    vel = vector(),
                    old_vel = vector(),
                    dropoff_start = nil,
                    dropoff_end = nil,
                    dropoff_min_multiplier = nil,
                };
            end

            projectile_store[shooter].active_projectiles = {};
        end

        projectile_store[shooter].last_received_idx = projectile_store[shooter].last_received_idx + 1;
        local projectile_idx = band(projectile_store[shooter].last_received_idx - 1, projectile_store[shooter].buffer_size - 1) + 1;

        local projectile = projectile_store[shooter].buffer[projectile_idx];
        projectile.weapon = weapon;
        projectile.time = time;
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
        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;
    end)
end

print("loaded projectiles net")