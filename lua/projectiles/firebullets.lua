AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    local broadcast_projectile = broadcast_projectile;
    local calculate_lean_pos = calculate_lean_pos;
    local get_weapon_speed = get_weapon_speed;
    local get_weapon_damage = get_weapon_damage;
    local get_weapon_spread = get_weapon_spread;

    local player_meta = FindMetaTable("Player");
    local get_lean_amount = player_meta.GetLeanAmount;
    local player_get_active_weapon = player_meta.GetActiveWeapon;
    local is_player = player_meta.IsPlayer;

    local vector_meta = FindMetaTable("Vector");
    local angle = vector_meta.Angle;

    local NULL = NULL;
    local entity_meta = FindMetaTable("Entity");
    local get_class = entity_meta.GetClass;

    local npc_meta = FindMetaTable("NPC");
    local is_npc = npc_meta.IsNPC;
    local npc_get_active_weapon = npc_meta.GetActiveWeapon;

    local convar_meta = FindMetaTable("ConVar");
    local get_bool = convar_meta.GetBool;

    local cv_projectiles_enabled = GetConVar("pro_projectiles_enabled");

    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if projectiles.disable_fire_bullets or not get_bool(cv_projectiles_enabled) then return; end
        if not shooter or shooter == NULL then return; end

        --print(shooter, data.Inflictor, data.Damage);

        local inflictor;
        local lean_amount = get_lean_amount and shooter:IsPlayer() and get_lean_amount(shooter) or 0.0;
        if data.Inflictor and data.Inflictor == NULL and shooter ~= NULL then
            if shooter:IsPlayer() then--if is_player(shooter) then
                inflictor = player_get_active_weapon(shooter);
            elseif shooter:IsNPC() then--elseif is_npc(shooter) then
                inflictor = npc_get_active_weapon(shooter);
            end
        else
            inflictor = data.Inflictor;
        end

        if not inflictor or inflictor == NULL then
            return;
        end

        local inflictor_class = get_class(inflictor);
        local speed = get_weapon_speed(inflictor, inflictor_class);
        local damage = get_weapon_damage(inflictor, inflictor_class, data.Damage);
        local src = calculate_lean_pos and calculate_lean_pos(data.Src, angle(data.Dir), lean_amount, shooter) or data.Src;
        for idx = 1, data.Num do
            local spread_dir = get_weapon_spread(inflictor, inflictor_class, data.Dir, data.Spread);
            broadcast_projectile(
                shooter,
                inflictor,
                src,
                spread_dir, 
                speed,
                damage,
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