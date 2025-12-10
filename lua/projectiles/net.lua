AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    util.AddNetworkString("projectile");
end

local band = bit.band;
local cur_time = CurTime;

projectile_store = projectile_store or {};
local projectile_store = projectile_store;

local BUFFER_SIZE = 0x400; -- must be power of 2

if SERVER then
    local entity_meta = FindMetaTable("Entity");
    local eye_pos = entity_meta.EyePos;

    local net_start = net.Start;
    local write_entity = net.WriteEntity;
    local write_vector = net.WriteVector;
    local write_float = net.WriteFloat;
    local write_uint = net.WriteUInt;
    local send_pvs = net.SendPVS;

    local crc = util.CRC;
    local tonumber = tonumber;

    local vector = Vector;

    function broadcast_projectile(shooter, weapon, pos, dir, speed, damage, drag, penetration_power, penetration_count, constpen, mass, drop, min_speed, max_distance, reliable)
        weapon.bullet_idx = (weapon.bullet_idx or 0) + 1;

        local time = cur_time();
        local random_seed = tonumber(crc(tostring(pos) .. tostring(dir))); -- random seed for ricochet

        net_start("projectile", reliable and true or false);
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
        write_float(constpen);
        write_float(mass);
        write_float(drop);
        write_float(min_speed);
        write_float(max_distance);
        write_uint(random_seed, 32); -- random seed for ricochet
        --send_pvs(eye_pos(shooter));
        send_pvs(pos);

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
                    drag = nil,
                    penetration_power = nil,
                    penetration_count = nil,
                    constpen = nil,
                    last_hit_entity = nil,
                    mass = nil,
                    drop = nil,
                    min_speed = nil,
                    distance_traveled = nil,
                    max_distance = nil,
                    random_seed = nil,
                    old_pos = vector(),
                    trace_filter = {nil, nil, nil},
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
        projectile.drag = drag;
        projectile.penetration_power = penetration_power;
        projectile.penetration_count = penetration_count;
        projectile.constpen = constpen;
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

        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;
    end
end

if CLIENT then
    local local_player = LocalPlayer;
    local read_entity = net.ReadEntity;
    local read_vector = net.ReadVector;
    local read_float = net.ReadFloat;
    local read_uint = net.ReadUInt;
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
        local constpen = read_float();
        local mass = read_float();
        local drop = read_float();
        local min_speed = read_float();
        local max_distance = read_float();
        local random_seed = read_uint(32);

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
                    drag = nil,
                    penetration_power = nil,
                    penetration_count = nil,
                    constpen = nil,
                    last_hit_entity = nil,
                    mass = nil,
                    drop = nil,
                    min_speed = nil,
                    distance_traveled = nil,
                    max_distance = nil,
                    random_seed = nil,
                    old_pos = vector(),
                    trace_filter = {nil, nil, nil},
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
        projectile.drag = drag;
        projectile.penetration_power = penetration_power;
        projectile.penetration_count = penetration_count;
        projectile.constpen = constpen;
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

        projectile_store[shooter].active_projectiles[#projectile_store[shooter].active_projectiles + 1] = projectile;
    end)
end

print("loaded projectiles net")