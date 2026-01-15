AddCSLuaFile();

--if CLIENT then return; end

if SERVER then
    util.AddNetworkString("projectiles_restore_config_start");
    util.AddNetworkString("projectiles_restore_config_chunk");
    util.AddNetworkString("projectiles_query_configs");
end

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
        for cvar_name, cvar_data in next, PROJECTILES_CVARS do
            backup.cvars[cvar_name] = cvar_data[1]:GetString();
        end
    end

    if bit.band(flags, PROJECTILES_BACKUP_RICOCHET_CHANCES) ~= 0 then
        backup["ricochet_mat_chance_multipliers"] = SURFACE_PROPS_RICOCHET_CHANCE_MULTIPLIERS;
    end

    if type == "json" then
        return util.TableToJSON(backup, true);
    end

    return nil;
end

if CLIENT then return; end

function projectiles_restore_config(data, merge)
    if data["surfaceprops"] then
        if not merge then
            surfaceprops_clear_db();
        end

        if merge then
            table.Merge(SURFACE_PROPS_PENETRATION, data["surfaceprops"]);
        else
            table.CopyFromTo(data["surfaceprops"], SURFACE_PROPS_PENETRATION);
        end

        surfaceprops_save_all_to_db();
        print("restored surfaceprops");
    end

    if data["weapon_config"] then
        if not merge then
            weapon_cfg_clear_db();
        end

        if merge then
            for cfg_type, cfg_table in next, data["weapon_config"] do
                table.Merge(CONFIG_TYPES[cfg_type], cfg_table);
            end
        else
            for cfg_type, cfg_table in next, data["weapon_config"] do
                table.CopyFromTo(cfg_table, CONFIG_TYPES[cfg_type]);
            end
        end
        
        if not CONFIG_TYPES["tracer_flags"] then
            CONFIG_TYPES["tracer_flags"] = { ["default"] = 0 };
        elseif not CONFIG_TYPES["tracer_flags"]["default"] then
            CONFIG_TYPES["tracer_flags"]["default"] = 0;
        end

        weapon_cfg_save_all_to_db();
        print("restored weapon config");
    end
    
    if data["cvars"] then
        for cvar, value in next, data["cvars"] do
            if not PROJECTILES_CVARS[cvar] or cvar == "pro_wind_seed_random" then continue; end
            RunConsoleCommand(cvar, value);
        end

        print("restored cvars");
    end

    if data["ricochet_mat_chance_multipliers"] then
        if not merge then
            ricochet_clear_db();
        end

        if merge then
            table.Merge(SURFACE_PROPS_RICOCHET_CHANCE_MULTIPLIERS, data["ricochet_mat_chance_multipliers"]);
        else
            table.CopyFromTo(data["ricochet_mat_chance_multipliers"], SURFACE_PROPS_RICOCHET_CHANCE_MULTIPLIERS);
        end

        ricochet_save_all_to_db();
        print("restored ricochet mat chance multipliers");
    end

    print("restored projectiles config");

    if data["weapon_config"] then
        send_weapon_config_chunked(nil, true);
    end

    if data["surfaceprops"] then
        net.Start("projectile_surfaceprop_sync");
        net.WriteTable(SURFACE_PROPS_PENETRATION);
        net.Broadcast();
    end

    if data["ricochet_mat_chance_multipliers"] then
        net.Start("projectile_ricochet_mat_chance_multipliers_sync");
        net.WriteTable(SURFACE_PROPS_RICOCHET_CHANCE_MULTIPLIERS);
        net.Broadcast();
    end

    print("sent projectiles config to all players");
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

concommand.Add("pro_config_backup_json_flags", function(ply, cmd, args)
    if ply ~= NULL and (not is_superadmin(ply)) then return; end
    local file_name = args[1];
    local flags = tonumber(args[2]) or PROJECTILES_BACKUP_ALL;
    
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
end, nil, "Backup projectiles config with custom flags");

concommand.Add("pro_config_restore_json", function(ply, cmd, args)
    if ply ~= NULL and (not is_superadmin(ply)) then return; end
    local file_name = args[1];
    local backup = file.Read("projectiles/backup/" .. file_name .. ".json", "DATA");
    if not backup then
        print("backup file not found");
        return;
    end
    projectiles_restore_config(util.JSONToTable(backup), args[2] == "merge");
    print("backup restored from " .. file_name .. (args[2] == "merge" and " in merge mode" or " in replace mode"));
end, nil, "Restore projectiles config from a file (replace or merge mode)");

local restore_buffers = {};

net.Receive("projectiles_restore_config_start", function(len, ply)
    if not is_superadmin(ply) then return; end
    
    local total_chunks = net.ReadUInt(16);
    local compressed_size = net.ReadUInt(32);
    local merge_mode = net.ReadBool();
    
    restore_buffers[ply] = {
        chunks = {},
        total_chunks = total_chunks,
        compressed_size = compressed_size,
        received = 0,
        merge = merge_mode
    };
    
    print(string.format("[ProjectileMod] Starting config restore by player %s: %d chunks, %d bytes compressed, mode: %s", ply:Nick(), total_chunks, compressed_size, merge_mode and "merge" or "replace"));
end);

net.Receive("projectiles_restore_config_chunk", function(len, ply)
    if not is_superadmin(ply) then return; end
    
    local buffer = restore_buffers[ply];
    if not buffer then 
        print("[ProjectileMod] Error: No restore buffer found for player " .. ply:Nick());
        return;
    end
    
    local chunk_index = net.ReadUInt(16);
    local chunk_size = net.ReadUInt(32);
    local chunk_data = net.ReadData(chunk_size);
    
    buffer.chunks[chunk_index] = chunk_data;
    buffer.received = buffer.received + 1;
    
    if buffer.received >= buffer.total_chunks then
        local compressed_data = "";
        for i = 1, buffer.total_chunks do
            if buffer.chunks[i] then
                compressed_data = compressed_data .. buffer.chunks[i];
            else
                print("[ProjectileMod] Error: Missing chunk " .. i);
                restore_buffers[ply] = nil;
                return;
            end
        end
        
        local json_data = util.Decompress(compressed_data);
        if not json_data then
            print("[ProjectileMod] Error: Failed to decompress data");
            restore_buffers[ply] = nil;
            return;
        end
        
        local data = util.JSONToTable(json_data);
        if data then
            projectiles_restore_config(data, buffer.merge);
            print("[ProjectileMod] Config restored successfully");
        else
            print("[ProjectileMod] Error: Failed to parse JSON data");
        end
        
        restore_buffers[ply] = nil;
    end
end);

net.Receive("projectiles_query_configs", function(len, ply)
    if not is_superadmin(ply) then return; end
 
    local configs = file.Find("projectiles/backup/*.json", "DATA") or {};
    local config_list = {};
    
    for i = 1, #configs do
        local filename = configs[i];
        local filepath = "projectiles/backup/" .. filename;
        local file_time = file.Time(filepath, "DATA");
        local content = file.Read(filepath, "DATA");
        local backup_data = content and util.JSONToTable(content);
        
        local includes = {};
        if backup_data then
            if backup_data.surfaceprops then table.insert(includes, "Surface Props"); end
            if backup_data.weapon_config then table.insert(includes, "Weapons"); end
            if backup_data.cvars then table.insert(includes, "CVars"); end
            if backup_data.ricochet_mat_chance_multipliers then table.insert(includes, "Ricochet"); end
        end

        config_list[#config_list + 1] = {
            filename = filename,
            time = file_time,
            includes = includes
        };
    end
    
    net.Start("projectiles_query_configs");
    net.WriteUInt(#config_list, 16);
    for i = 1, #config_list do
        local cfg = config_list[i];
        net.WriteString(cfg.filename);
        net.WriteString(string.format("%.0f", cfg.time));
        net.WriteUInt(#cfg.includes, 8);
        for j = 1, #cfg.includes do
            net.WriteString(cfg.includes[j]);
        end
    end
    net.Send(ply);

    print("sent " .. #config_list .. " configs to " .. ply:Nick());
end);