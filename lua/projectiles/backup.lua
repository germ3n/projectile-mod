AddCSLuaFile();

if CLIENT then return; end

PROJECTILES_BACKUP_SURFACEPROPS = 0x1;
PROJECTILES_BACKUP_WEAPON_CONFIG = 0x2;
PROJECTILES_BACKUP_CVARS = 0x4;
PROJECTILES_BACKUP_ALL = bit.bor(PROJECTILES_BACKUP_SURFACEPROPS, PROJECTILES_BACKUP_WEAPON_CONFIG, PROJECTILES_BACKUP_CVARS);

PROJECTILES_BACKUP_TYPES = {
    "json",
    "sqlite",
};

function projectiles_backup_config(type, flags)
    local backup = {};

    if bit.band(flags, PROJECTILES_BACKUP_SURFACEPROPS) ~= 0 then
        backup["surfaceprops"] = SURFACE_PROPS_PENETRATION;
    end

    if bit.band(flags, PROJECTILES_BACKUP_WEAPON_CONFIG) ~= 0 then
        backup["weapon_config"] = CONFIG_TYPES;
    end

    if bit.band(flags, PROJECTILES_BACKUP_CVARS) ~= 0 then
        backup.cvars = {};
        for idx, cvar in next, PROJECTILE_CVAR_NAMES do
            backup.cvars[cvar] = GetConVar(cvar):GetString();
        end
    end

    if type == "json" then
        return util.TableToJSON(backup);
    end

    return nil;
end

local PROJECTILES_BACKUP_ALL = PROJECTILES_BACKUP_ALL;
local NULL = NULL; 

local player_meta = FindMetaTable("Player");
local is_superadmin = player_meta.IsSuperAdmin;

concommand.Add("projectiles_backup_config_json", function(ply, cmd, args)
    if ply ~= NULL and (not is_superadmin(ply)) then return; end
    local flags = PROJECTILES_BACKUP_ALL;
    local backup = projectiles_backup_config("json", flags);
    print(backup);
end, nil, "Backup projectiles config");