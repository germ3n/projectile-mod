AddCSLuaFile();

if CLIENT then return; end

PROJECTILES_BACKUP_SURFACEPROPS = 0x1;
PROJECTILES_BACKUP_WEAPON_CONFIG = 0x2;
PROJECTILES_BACKUP_CVARS = 0x4;
PROJECTILES_BACKUP_RICOCHET_CHANCES = 0x8;
PROJECTILES_BACKUP_ALL = bit.bor(PROJECTILES_BACKUP_SURFACEPROPS, PROJECTILES_BACKUP_WEAPON_CONFIG, PROJECTILES_BACKUP_CVARS, PROJECTILES_BACKUP_RICOCHET_CHANCES);

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
        for cvar_name, cvar in next, PROJECTILES_CVARS do
            backup.cvars[cvar_name] = cvar:GetString();
        end
    end

    if bit.band(flags, PROJECTILES_BACKUP_RICOCHET_CHANCES) ~= 0 then
        backup["ricochet_mat_chance_multipliers"] = {};
        for mat_type, chance in next, RICOCHET_MAT_CHANCE_MULTIPLIERS do
            backup["ricochet_mat_chance_multipliers"][MAT_TYPE_NAMES[mat_type]] = chance;
        end
    end

    if type == "json" then
        return util.TableToJSON(backup, true);
    end

    return nil;
end

function projectiles_restore_config(data)
    if data["surfaceprops"] then
        table.Merge(SURFACE_PROPS_PENETRATION, data["surfaceprops"]);
        print("restored surfaceprops");
    end

    if data["weapon_config"] then
        table.Merge(CONFIG_TYPES, data["weapon_config"]);
        print("restored weapon config");
    end
    
    if data["cvars"] then
        for cvar, value in next, data["cvars"] do
            if not PROJECTILES_CVARS[cvar] then continue; end
            RunConsoleCommand(cvar, value);
        end

        print("restored cvars");
    end

    if data["ricochet_mat_chance_multipliers"] then
        for mat_type, chance in next, data["ricochet_mat_chance_multipliers"] do
            if not MAT_TYPE_NAMES[_G[mat_type]] then continue; end
            RICOCHET_MAT_CHANCE_MULTIPLIERS[_G[mat_type]] = chance;
        end

        print("restored ricochet mat chance multipliers");
    end

    print("restored projectiles config");

    --PrintTable(data);
    --todo: add syncing to clients
end

local PROJECTILES_BACKUP_ALL = PROJECTILES_BACKUP_ALL;
local NULL = NULL; 

local player_meta = FindMetaTable("Player");
local is_superadmin = player_meta.IsSuperAdmin;

concommand.Add("pro_config_backup_json", function(ply, cmd, args)
    if ply ~= NULL and (not is_superadmin(ply)) then return; end
    local file_name = args[1];
    local flags = PROJECTILES_BACKUP_ALL;
    local backup = projectiles_backup_config("json", flags);
    if not file_name then
        local chunk_size = 4095;
        local chunks = math.ceil(string.len(backup) / chunk_size);
        for i = 1, chunks do
            local start_pos = (i - 1) * chunk_size + 1;
            local end_pos = math.min(start_pos + chunk_size, string.len(backup));
            local chunk = string.sub(backup, start_pos, end_pos);
            Msg(chunk);
        end

        print("\nbackup complete");
    else
        file.Write("projectiles/backup/" .. file_name .. ".json", backup);
        print("backup complete to garrysmod/data/projectiles/backup/" .. file_name .. ".json");
    end
end, nil, "Backup projectiles config either to console or a file");