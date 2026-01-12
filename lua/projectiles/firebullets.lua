AddCSLuaFile();

local projectiles = projectiles;

local zero_vec = Vector(0, 0, 0);
local rand = math.Rand;
local abs = math.abs;
local shared_random = util.SharedRandom;
local band = bit.band;

projectiles.shooter_velocities = projectiles.shooter_velocities or {};

local angle_meta = FindMetaTable("Angle");
local right = angle_meta.Right;
local up = angle_meta.Up;

local vector_meta = FindMetaTable("Vector");
local angle = vector_meta.Angle;
local vec_dot = vector_meta.Dot;

local CONFIG_TYPES = CONFIG_TYPES;

local function get_weapon_spread(weapon, class_name, dir, spread, seed)
    if spread.x == 0.0 and spread.y == 0.0 then
        return dir;
    end

    local WEAPON_SPREAD_BIAS = CONFIG_TYPES["spread_bias"];
    local bias = WEAPON_SPREAD_BIAS[class_name] or WEAPON_SPREAD_BIAS["default"];
    local flatness = abs(bias * 0.5);
    local final_spread_x, final_spread_y;
    local angle_dir = angle(dir);
    local vec_right = right(angle_dir);
    local vec_up = up(angle_dir);

    local attempt = 1;
    repeat
        final_spread_x = shared_random("spread_x1", -1, 1, band(seed + attempt, 0x7FFFFFFF)) * flatness + shared_random("spread_x2", -1, 1, band(seed + attempt * 1000, 0x7FFFFFFF)) * (1.0 - flatness);
        final_spread_y = shared_random("spread_y1", -1, 1, band(seed + attempt * 2000, 0x7FFFFFFF)) * flatness + shared_random("spread_y2", -1, 1, band(seed + attempt * 3000, 0x7FFFFFFF)) * (1.0 - flatness);
        if bias < 0.0 then
            final_spread_x = final_spread_x >= 0.0 and 1.0 - final_spread_x or -1.0 -final_spread_x;
            final_spread_y = final_spread_y >= 0.0 and 1.0 - final_spread_y or -1.0 -final_spread_y;
        end
        attempt = attempt + 1;
    until (final_spread_x * final_spread_x + final_spread_y * final_spread_y) <= 1.0;

    local final_dir = dir + (final_spread_x * spread.x * vec_right) + (final_spread_y * spread.y * vec_up);
    return final_dir;
end

local TURRET_AND_MOUNTED_WEAPONS_WHITELIST = {
    ["npc_turret_floor"] = true,
    ["npc_turret_ceiling"] = true,
    ["npc_turret_ground"] = true,
    ["prop_vehicle_airboat"] = true,
};

local OTHER_TURRETS_FIX = {
    ["func_tank"] = true,
    ["gmod_turret"] = true,
};

local broadcast_projectile = broadcast_projectile;
local calculate_lean_pos = calculate_lean_pos;
local get_weapon_speed = get_weapon_speed;
local get_weapon_damage = get_weapon_damage;
local get_weapon_spread = get_weapon_spread;
local get_weapon_penetration_power = get_weapon_penetration_power;
local get_weapon_penetration_count = get_weapon_penetration_count;
local get_weapon_drag = get_weapon_drag;
local get_weapon_mass = get_weapon_mass;
local get_weapon_drop = get_weapon_drop;
local get_weapon_min_speed = get_weapon_min_speed;
local get_weapon_max_distance = get_weapon_max_distance;
local get_weapon_tracer_colors = get_weapon_tracer_colors;
local get_weapon_dropoff_start = get_weapon_dropoff_start;
local get_weapon_dropoff_end = get_weapon_dropoff_end;
local get_weapon_dropoff_min_multiplier = get_weapon_dropoff_min_multiplier;
local is_weapon_blacklisted = is_weapon_blacklisted;

if SERVER then
    local player_meta = FindMetaTable("Player");
    local get_lean_amount = player_meta.GetLeanAmount;
    local player_get_active_weapon = player_meta.GetActiveWeapon;
    local is_player = player_meta.IsPlayer;

    local vector_meta = FindMetaTable("Vector");
    local angle = vector_meta.Angle;
    local get_normalized = vector_meta.GetNormalized;
    local vec_length = vector_meta.Length;

    local NULL = NULL;
    local entity_meta = FindMetaTable("Entity");
    local get_class = entity_meta.GetClass;

    local npc_meta = FindMetaTable("NPC");
    local is_npc = npc_meta.IsNPC;
    local npc_get_active_weapon = npc_meta.GetActiveWeapon;

    local npc_pistol_effect_fix = npc_pistol_effect_fix;

    local get_velocity = entity_meta.GetVelocity;
    local get_ground_entity = entity_meta.GetGroundEntity;
    local vector = Vector;

    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if projectiles.disable_fire_bullets or not projectiles["pro_projectiles_enabled"] then return; end
        if not shooter or shooter == NULL then return; end
        --print(shooter, data.Inflictor, data.Damage);

        local inflictor;
        local is_gmod_turret = false;
        local is_npc = shooter:IsNPC();
        local is_player = shooter:IsPlayer();
        local is_weapon = shooter:IsWeapon();
        local lean_amount = get_lean_amount and is_player and get_lean_amount(shooter) or 0.0;
        if (not data.Inflictor or data.Inflictor == NULL) and shooter ~= NULL then
            local shooter_class = get_class(shooter);
            if is_player then--if is_player(shooter) then
                inflictor = player_get_active_weapon(shooter);
            elseif is_npc then--elseif is_npc(shooter) then
                if not TURRET_AND_MOUNTED_WEAPONS_WHITELIST[shooter_class] then
                    inflictor = npc_get_active_weapon(shooter);
                else
                    inflictor = shooter;
                end
            elseif OTHER_TURRETS_FIX[shooter_class] and data.Attacker ~= NULL then -- emplacement gun/turret fix
                inflictor = shooter;
                shooter = data.Attacker;
                is_gmod_turret = shooter_class == "gmod_turret";
            end
        else
            inflictor = data.Inflictor;
        end

        if is_weapon then -- fix for https://steamcommunity.com/sharedfiles/filedetails/?id=3490724227
            local owner = shooter:GetOwner();
            if owner ~= NULL then
                shooter = owner;
            end
        end

        if not inflictor or inflictor == NULL or shooter == NULL then
            return;
        end

        local inflictor_class = get_class(inflictor);
        if is_weapon_blacklisted(inflictor, inflictor_class) then
            return;
        end

        local damage = get_weapon_damage(inflictor, inflictor_class, data.Damage);
        local speed = get_weapon_speed(inflictor, inflictor_class, damage, data.AmmoType);
        damage = damage * projectiles["pro_weapon_damage_scale"];
        speed = speed * projectiles["pro_speed_scale"];
        local src = calculate_lean_pos and calculate_lean_pos(data.Src, angle(data.Dir), lean_amount, shooter) or data.Src;
        
        if is_npc then
            local npc_offset = projectiles["pro_npc_shootpos_forward"];
            if npc_offset > 0 then
                src = src + data.Dir * npc_offset;
            end
        end
        local penetration_power = get_weapon_penetration_power(inflictor, inflictor_class) * projectiles["pro_penetration_power_scale"];
        local penetration_count = get_weapon_penetration_count(inflictor, inflictor_class);
        local drag = get_weapon_drag(inflictor, inflictor_class);
        local mass = get_weapon_mass(inflictor, inflictor_class);
        local drop = get_weapon_drop(inflictor, inflictor_class);
        local min_speed = get_weapon_min_speed(inflictor, inflictor_class);
        local max_distance = get_weapon_max_distance(inflictor, inflictor_class);
        local tracer_colors = get_weapon_tracer_colors(inflictor, inflictor_class);
        local dropoff_start = get_weapon_dropoff_start(inflictor, inflictor_class);
        local dropoff_end = get_weapon_dropoff_end(inflictor, inflictor_class);
        local dropoff_min_multiplier = get_weapon_dropoff_min_multiplier(inflictor, inflictor_class);
        local dir = data.Dir;
        local spread = data.Spread;
        for idx = 1, data.Num do
            local final_dir = get_weapon_spread(inflictor, inflictor_class, dir, spread, idx * 1000);
            local final_speed = speed;

            if projectiles["pro_inherit_shooter_velocity"] then -- todo: fix other turrets, currently player-spawned npc_turrt_floor for example will inherit the player's velocity, we only need to inherit the ground entity's velocity
                local inherited_vel = is_gmod_turret and zero_vec or projectiles.shooter_velocities[shooter] or get_velocity(shooter);
                if projectiles["pro_inherit_ground_entity_velocity"] then
                    local ground = get_ground_entity(shooter); -- should probably recurse through parents here
                    if ground and ground ~= NULL then
                        inherited_vel = inherited_vel + get_velocity(ground);
                    end
                end
                
                --if vec_dot(dir, get_normalized(inherited_vel)) >= 0.0 then
                    local scale = projectiles["pro_inherit_shooter_velocity_scale"];
                    local combined_vel = final_dir * speed + inherited_vel * scale;
                    
                    final_dir = get_normalized(combined_vel);
                    final_speed = vec_length(combined_vel);
                --end
            end

            broadcast_projectile(
                shooter,
                inflictor,
                src,
                final_dir, 
                final_speed,
                damage,
                drag,
                penetration_power,
                penetration_count,
                mass,
                drop,
                min_speed,
                max_distance,
                tracer_colors,
                is_gmod_turret,
                dropoff_start,
                dropoff_end,
                dropoff_min_multiplier,
                data.AmmoType,
                projectiles["pro_net_reliable"],
                idx
            );
        end

        npc_pistol_effect_fix(shooter, data);

        return false;
    end);
end

if CLIENT then
    local local_player = LocalPlayer;
    local band = bit.band;
    local bxor = bit.bxor;
    local cur_time = CurTime;
    local vector = Vector;
    local NULL = NULL;
    local projectile_store = projectile_store;
    local BUFFER_SIZE = 0x400;
    local floor = math.floor;
    local tick_interval = engine.TickInterval();
    
    local function hash_projectile(px, py, pz, dx, dy, dz)
        local h = floor(px * 0.1) * 73856093 + floor(py * 0.1) * 19349663 + floor(pz * 0.1) * 83492791;
        h = h + floor(dx * 10000) * 2654435761 + floor(dy * 10000) * 2246822519 + floor(dz * 10000) * 3266489917;
        h = band(h, 0xFFFFFFFF);
        h = bxor(h, band(h / 8192, 0xFFFFFFFF));
        h = band(h * 48271, 0xFFFFFFFF);
        return band(h, 0x7FFFFFFF);
    end
    
    local entity_meta = FindMetaTable("Entity");
    local get_class = entity_meta.GetClass;
    local get_velocity = entity_meta.GetVelocity;
    local get_ground_entity = entity_meta.GetGroundEntity;
    local entindex = entity_meta.EntIndex;
    
    local player_meta = FindMetaTable("Player");
    local get_lean_amount = player_meta.GetLeanAmount;
    local player_get_active_weapon = player_meta.GetActiveWeapon;
    
    local vector_meta = FindMetaTable("Vector");
    local angle = vector_meta.Angle;
    local get_normalized = vector_meta.GetNormalized;
    local vec_length = vector_meta.Length;
    
    local create_new_projectile_store = create_new_projectile_store;
    local function create_local_projectile(shooter, weapon, pos, dir, speed, damage, drag, penetration_power, penetration_count, mass, drop, min_speed, max_distance, tracer_colors, dropoff_start, dropoff_end, dropoff_min_multiplier, ammo_type, bullet_idx)
        if not projectile_store[shooter] then 
            create_new_projectile_store(shooter);
        end

        local time = cur_time();
        local tick = floor(0.5 + time / tick_interval);
        local random_seed = band(tick * 73856093 + entindex(shooter) * 19349663 + (bullet_idx or 1) * 83492791, 0x7FFFFFFF);

        local projectile_idx = band(projectile_store[shooter].received - 1, projectile_store[shooter].buffer_size - 1) + 1;

        local projectile = projectile_store[shooter].buffer[projectile_idx];
        projectile_store[shooter].received = projectile_store[shooter].received + 1;
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
        projectile.is_gmod_turret = false;
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

        --print("random seed on client", random_seed);
    end

    local is_first_time_predicted = IsFirstTimePredicted;
    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if not projectiles["pro_projectiles_enabled"] then return; end
        if projectiles.currently_using_firebullets then return; end
        if not is_first_time_predicted() then return false; end
        local local_ply = local_player();
        if shooter ~= local_ply then
            if shooter:IsWeapon() then
                shooter = shooter:GetOwner();
            end

            if shooter ~= local_ply then
                return false;
            end
        end

        local inflictor = data.Inflictor;
        if not inflictor or inflictor == NULL then
            inflictor = player_get_active_weapon(shooter);
        end

        if not inflictor or inflictor == NULL then
            return false;
        end

        local inflictor_class = get_class(inflictor);
        if is_weapon_blacklisted(inflictor, inflictor_class) then
            return;
        end

        local damage = get_weapon_damage(inflictor, inflictor_class, data.Damage);
        local speed = get_weapon_speed(inflictor, inflictor_class, damage, data.AmmoType);
        damage = damage * projectiles["pro_weapon_damage_scale"];
        speed = speed * projectiles["pro_speed_scale"];
        local lean_amount = get_lean_amount and get_lean_amount(shooter) or 0.0;
        local src = calculate_lean_pos and calculate_lean_pos(data.Src, angle(data.Dir), lean_amount, shooter) or data.Src;
        local penetration_power = get_weapon_penetration_power(inflictor, inflictor_class) * projectiles["pro_penetration_power_scale"];
        local penetration_count = get_weapon_penetration_count(inflictor, inflictor_class);
        local drag = get_weapon_drag(inflictor, inflictor_class);
        local mass = get_weapon_mass(inflictor, inflictor_class);
        local drop = get_weapon_drop(inflictor, inflictor_class);
        local min_speed = get_weapon_min_speed(inflictor, inflictor_class);
        local max_distance = get_weapon_max_distance(inflictor, inflictor_class);
        local tracer_colors = get_weapon_tracer_colors(inflictor, inflictor_class);
        local dropoff_start = get_weapon_dropoff_start(inflictor, inflictor_class);
        local dropoff_end = get_weapon_dropoff_end(inflictor, inflictor_class);
        local dropoff_min_multiplier = get_weapon_dropoff_min_multiplier(inflictor, inflictor_class);
        local dir = data.Dir;
        local spread = data.Spread;
        for idx = 1, data.Num do
            local final_dir = get_weapon_spread(inflictor, inflictor_class, dir, spread, idx * 1000);
            local final_speed = speed;

            if projectiles["pro_inherit_shooter_velocity"] then
                local inherited_vel = projectiles.shooter_velocities[shooter] or get_velocity(shooter);
                if projectiles["pro_inherit_ground_entity_velocity"] then
                    local ground = get_ground_entity(shooter);
                    if ground and ground ~= NULL then
                        inherited_vel = inherited_vel + get_velocity(ground);
                    end
                end
                
                --if vec_dot(dir, get_normalized(inherited_vel)) >= 0.0 then
                    --print("inheriting velocity", vec_dot(dir, get_normalized(inherited_vel)));
                    local scale = projectiles["pro_inherit_shooter_velocity_scale"];
                    local combined_vel = final_dir * speed + inherited_vel * scale;
                    
                    final_dir = get_normalized(combined_vel);
                    final_speed = vec_length(combined_vel);
                --else
                --    print("not inheriting velocity", vec_dot(dir, get_normalized(inherited_vel)));
                --end
            end

            create_local_projectile(
                shooter,
                inflictor,
                src,
                final_dir,
                final_speed,
                damage,
                drag,
                penetration_power,
                penetration_count,
                mass,
                drop,
                min_speed,
                max_distance,
                tracer_colors,
                dropoff_start,
                dropoff_end,
                dropoff_min_multiplier,
                data.AmmoType,
                idx
            );
        end

        return false;
    end);
end

print("loaded projectiles firebullets");