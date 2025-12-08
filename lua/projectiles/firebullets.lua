AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    local broadcast_projectile = broadcast_projectile;
    local calculate_lean_pos = calculate_lean_pos;
    local get_weapon_speed = get_weapon_speed;
    local get_weapon_damage = get_weapon_damage;

    local player_meta = FindMetaTable("Player");
    local get_lean_amount = player_meta.GetLeanAmount;

    local vector_meta = FindMetaTable("Vector");
    local angle = vector_meta.Angle;

    local NULL = NULL;
    local entity_meta = FindMetaTable("Entity");
    local get_class = entity_meta.GetClass;

    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if projectiles.disable_fire_bullets then return; end

        --print(shooter, data.Inflictor, data.Damage);

        local inflictor_class = data.Inflictor ~= NULL and get_class(data.Inflictor) or "default";

        for idx = 1, data.Num do
            broadcast_projectile(
                shooter,
                data.Inflictor,
                calculate_lean_pos and calculate_lean_pos(data.Src, angle(data.Dir), get_lean_amount(shooter), shooter) or data.Src,
                data.Dir, 
                get_weapon_speed(data.Inflictor, inflictor_class),
                get_weapon_damage(data.Inflictor, inflictor_class, data.Damage),
                0.0, -- drag
                2.5, -- penetration power
                10, -- penetration count
                2.5 -- constpen
            );
        end

        return false;
    end);
end

if CLIENT then
    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        return false;
    end);
end

print("loaded projectiles firebullets");