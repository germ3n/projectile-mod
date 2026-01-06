AddCSLuaFile();

if SERVER then
    util.AddNetworkString("projectile_update_cvar");

    local IsValid = IsValid;
    local RunConsoleCommand = RunConsoleCommand;
    local PROJECTILES_CVARS = PROJECTILES_CVARS;
    local NULL = NULL;
    local get_convar = GetConVar;
    local next = next;

    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;

    local convar_meta = FindMetaTable("ConVar");
    local get_default = convar_meta.GetDefault;

    net.Receive("projectile_update_cvar", function(len, ply)
        if not IsValid(ply) then 
            return;
        elseif not ply:IsSuperAdmin() then 
            ply:ChatPrint("You are not authorized to use this command.");
            return;
        end

        local cvar = net.ReadString();
        local value = net.ReadString();

        RunConsoleCommand(cvar, value);
    end);

    concommand.Add("pro_config_reset_cvars", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        for cvar_name, cvar in next, PROJECTILES_CVARS do
            RunConsoleCommand(cvar_name, get_default(cvar));
        end

        print("reset all projectile cvars");
    end, nil, "Reset all projectile cvars");
end

if CLIENT then
    local surface = surface;
    local vgui = vgui;
    local concommand = concommand;
    local string = string;
    local color = Color;
    local tonumber = tonumber;
    local table = table;
    local math = math;
    local CONFIG_TYPES = CONFIG_TYPES;
    local HL2_WEAPON_CLASSES = HL2_WEAPON_CLASSES;
    local SURFACE_PROPS_PENETRATION = SURFACE_PROPS_PENETRATION;
    local RICOCHET_MAT_CHANCE_MULTIPLIERS = RICOCHET_MAT_CHANCE_MULTIPLIERS;
    local MAT_TYPE_NAMES = MAT_TYPE_NAMES;
    
    local THEME = {
        bg_dark = Color(30, 30, 35, 250),
        bg_lighter = Color(40, 40, 45, 255),
        header_bg = Color(20, 20, 25, 255),
        accent = Color(70, 130, 180), -- Steel Blue
        accent_hover = Color(90, 150, 200),
        text = Color(230, 230, 230),
        text_dim = Color(150, 150, 150),
        divider = Color(60, 60, 65)
    };

    local function CreateControl(parent, data)
        if data.type == "header" then
            local panel = vgui.Create("DPanel", parent);
            panel:SetTall(30);
            panel:Dock(TOP);
            panel:DockMargin(0, 5, 0, 5);
            panel.Paint = function(s, w, h)
                draw.SimpleText(data.label, "DermaDefaultBold", 0, h/2, THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.RoundedBox(0, 0, h-2, w, 2, THEME.divider)
            end
            return panel;
            
        elseif data.type == "bool" then
            local panel = vgui.Create("DPanel", parent);
            panel:SetTall(30);
            panel:Dock(TOP);
            panel:DockMargin(0, 0, 0, 2);
            panel.Paint = function(s, w, h) end

            local check = vgui.Create("DCheckBox", panel);
            check:SetPos(0, 7);
            --check:SetConVar(data.cvar);
            check:SetChecked(GetConVar(data.cvar):GetBool());
            check.OnChange = function(s, value)
                if data.client then RunConsoleCommand(data.cvar, value and "1" or "0"); return; end
                net.Start("projectile_update_cvar");
                net.WriteString(data.cvar);
                net.WriteString(value and "1" or "0");
                net.SendToServer();
            end

            panel.UpdateValue = function(s)
                check:SetChecked(GetConVar(data.cvar):GetBool());
            end
            
            local label = vgui.Create("DLabel", panel);
            label:SetText(data.label);
            label:SetPos(25, 0);
            label:SetSize(300, 30);
            label:SetTextColor(THEME.text);
            
            return panel;

        elseif data.type == "float" then
            local panel = vgui.Create("DPanel", parent);
            panel:SetTall(40);
            panel:Dock(TOP);
            panel:DockMargin(0, 0, 0, 5);
            panel.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter)
            end

            local slider = vgui.Create("DNumSlider", panel);
            slider:Dock(FILL);
            slider:DockMargin(10, 0, 10, 0);
            slider:SetText(data.label);
            slider:SetMin(data.min);
            slider:SetMax(data.max);
            slider:SetDecimals(data.decimals);
            --slider:SetConVar(data.cvar);
            slider:SetValue(GetConVar(data.cvar):GetFloat());
            slider.OnValueChanged = function(s, value)
                if math.abs(GetConVar(data.cvar):GetFloat() - value) < 0.001 then return end
                
                timer.Create("projectile_update_cvar_timer_" .. data.cvar, 0.25, 1, function()
                    net.Start("projectile_update_cvar");
                    net.WriteString(data.cvar);
                    net.WriteString(tostring(value));
                    net.SendToServer();
                end);
            end

            slider.UpdateValue = function(s)
                if s.Slider:GetDragging() or s.TextArea:IsEditing() then return; end
                slider:SetValue(GetConVar(data.cvar):GetFloat());
            end
            
            slider.Label:SetTextColor(THEME.text)
            slider.TextArea:SetTextColor(THEME.text)
            
            return panel;
        elseif data.type == "color" then
            local panel = vgui.Create("DPanel", parent);
            panel:SetTall(160);
            panel:Dock(TOP);
            panel:DockMargin(0, 5, 0, 5);
            panel.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter)
            end

            local label = vgui.Create("DLabel", panel);
            label:SetText(data.label);
            label:SetTextColor(THEME.text);
            label:Dock(TOP);
            label:DockMargin(10, 5, 0, 0);

            local mixer = vgui.Create("DColorMixer", panel);
            mixer:Dock(FILL);
            mixer:DockMargin(10, 5, 10, 10);
            mixer:SetPalette(false);
            mixer:SetAlphaBar(false);
            mixer:SetWangs(true);
            
            local current_str = GetConVar(data.cvar):GetString();
            local parts = string.Split(current_str, " ");
            local init_col = color(tonumber(parts[1]) or 0, tonumber(parts[2]) or 0, tonumber(parts[3]) or 255);
            mixer:SetColor(init_col);

            mixer.ValueChanged = function(s, col)
                timer.Create("projectile_update_cvar_timer_" .. data.cvar, 0.25, 1, function()
                    local val = string.format("%d %d %d", col.r, col.g, col.b);
                    net.Start("projectile_update_cvar");
                    net.WriteString(data.cvar);
                    net.WriteString(val);
                    net.SendToServer();
                end);
            end

            mixer.UpdateValue = function(s)
                local current_str = GetConVar(data.cvar):GetString();
                local parts = string.Split(current_str, " ");
                local init_col = color(tonumber(parts[1]) or 0, tonumber(parts[2]) or 0, tonumber(parts[3]) or 255, parts[4] and tonumber(parts[4]) or 255);
                mixer:SetColor(init_col);
            end

            return panel;
        elseif data.type == "dropdown" then
            local panel = vgui.Create("DPanel", parent);
            panel:SetTall(40);
            panel:Dock(TOP);
            panel:DockMargin(0, 0, 0, 5);
            panel.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
            end

            local label = vgui.Create("DLabel", panel);
            label:SetText(data.label);
            label:Dock(LEFT);
            label:DockMargin(10, 0, 0, 0);
            label:SetWide(150);
            label:SetTextColor(THEME.text);

            local combo = vgui.Create("DComboBox", panel);
            combo:Dock(FILL);
            combo:DockMargin(10, 8, 10, 8);
            combo:SetTextColor(THEME.text);
            
            combo.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                if s:GetDisabled() then return end
                if s:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(255,255,255,10)) end
            end

            for idx, option in ipairs(data.options) do
                combo:AddChoice(option, idx - 1);
            end

            combo.OnSelect = function(s, index, value, data_val)
                local current_convar_val = GetConVar(data.cvar):GetInt();
                if current_convar_val == data_val then return; end

                if data.client then
                    RunConsoleCommand(data.cvar, tostring(data_val));
                else
                    net.Start("projectile_update_cvar");
                    net.WriteString(data.cvar);
                    net.WriteString(tostring(data_val));
                    net.SendToServer();
                end
            end

            panel.UpdateValue = function(s)
                if combo:IsMenuOpen() then return; end
                
                local current_val = GetConVar(data.cvar):GetInt();
                combo:ChooseOptionID(current_val + 1);
            end
            
            panel:UpdateValue();

            return panel;
        end
    end

    local menu_tabs = {
        {
            name = "General",
            icon = "icon16/wrench.png",
            vars = {
                { type = "header", label = "Global Settings" },
                { type = "bool", cvar = "pro_projectiles_enabled", label = "Enable Projectiles" },
                { type = "bool", cvar = "pro_ricochet_enabled", label = "Enable Ricochet" },
                { type = "bool", cvar = "pro_drag_enabled", label = "Enable Drag" },
                { type = "bool", cvar = "pro_gravity_enabled", label = "Enable Gravity" },
                { type = "bool", cvar = "pro_damage_scaling", label = "Enable Damage Scaling" },
                { type = "bool", cvar = "pro_damage_dropoff_enabled", label = "Enable Damage Dropoff" },
                { type = "bool", cvar = "pro_wind_enabled", label = "Enable Wind (Experimental)" },
                { type = "float", cvar = "pro_speed_scale", label = "Speed Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_weapon_damage_scale", label = "Damage Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_penetration_power_scale", label = "Power Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_damage_force_multiplier", label = "Damage Force Multiplier", min = 0.0, max = 50.0, decimals = 3 },
            }
        },
        {
            name = "Render",
            icon = "icon16/paintbrush.png",
            vars = {
                { type = "header", label = "Render Settings" },
                { type = "bool", cvar = "pro_render_enabled", label = "Enable Projectile Rendering", client = true },
                { type = "bool", cvar = "pro_render_wind_hud", label = "Enable Wind HUD", client = true },
                { type = "float", cvar = "pro_spawn_fade_distance", label = "Spawn Fade Distance", min = 0.0, max = 1000.0, decimals = 0 },
                { type = "float", cvar = "pro_distance_scale_start", label = "Distance Scale Start", min = 0.0, max = 10000.0, decimals = 0 },
                { type = "float", cvar = "pro_distance_scale_max", label = "Distance Scale Max", min = 1.0, max = 10.0, decimals = 2 },
                { type = "float", cvar = "pro_render_min_distance", label = "Minimum Distance", min = 0.0, max = 10000.0, decimals = 0 },
            }
        },
        {
            name = "Penetration",
            icon = "icon16/arrow_in.png",
            vars = {
                { type = "header", label = "Mechanics" },
                { type = "float", cvar = "pro_penetration_power_scale", label = "Power Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "header", label = "Costs & Taxes" },
                { type = "float", cvar = "pro_penetration_power_cost_multiplier", label = "Power Cost Multiplier", min = 0.0, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_penetration_entry_cost_multiplier", label = "Entry Cost Multiplier", min = 0.0, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_penetration_dmg_tax_per_unit", label = "Damage Tax (Per Unit)", min = 0.0, max = 10.0, decimals = 1 },
            }
        },
        {
            name = "Ricochet",
            icon = "icon16/arrow_rotate_clockwise.png",
            custom_draw = function(parent)
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                scroll:DockPadding(10, 10, 10, 10);

                local standard_vars = {
                    { type = "header", label = "Logic" },
                    { type = "bool", cvar = "pro_ricochet_enabled", label = "Enable Ricochet" },
                    { type = "float", cvar = "pro_ricochet_chance", label = "Ricochet Chance", min = 0.0, max = 1.0, decimals = 2 },
                    { type = "float", cvar = "pro_ricochet_spread", label = "Spread", min = 0.0, max = 1.0, decimals = 2 },
                    { type = "header", label = "Multipliers" },
                    { type = "float", cvar = "pro_ricochet_speed_multiplier", label = "Speed Multiplier", min = 0.0, max = 1.0, decimals = 2 },
                    { type = "float", cvar = "pro_ricochet_damage_multiplier", label = "Damage Multiplier", min = 0.0, max = 1.0, decimals = 2 },
                };

                if CreateControl then 
                    for _, var_data in ipairs(standard_vars) do
                        CreateControl(scroll, var_data);
                    end
                end

                local header = vgui.Create("DPanel", scroll);
                header:SetTall(30);
                header:Dock(TOP);
                header:DockMargin(0, 15, 0, 5);
                header.Paint = function(s, w, h)
                    draw.SimpleText("Material Chance Multipliers", "DermaDefaultBold", 0, h/2, THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER);
                    draw.RoundedBox(0, 0, h-2, w, 2, THEME.divider);
                end

                local sorted_mats = {};
                for name, val in pairs(RICOCHET_MAT_CHANCE_MULTIPLIERS) do
                    table.insert(sorted_mats, { name = name, val = val });
                end
                table.sort(sorted_mats, function(a, b) return a.name < b.name end);

                for idx, mat_data in ipairs(sorted_mats) do
                    local panel = vgui.Create("DPanel", scroll);
                    panel:SetTall(40);
                    panel:Dock(TOP);
                    panel:DockMargin(0, 0, 0, 5);
                    panel.Paint = function(s, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter)
                    end

                    local slider = vgui.Create("DNumSlider", panel);
                    slider:Dock(FILL);
                    slider:DockMargin(10, 0, 10, 0);
                    slider:SetText(mat_data.name);
                    slider:SetMin(0.0);
                    slider:SetMax(1.0);
                    slider:SetDecimals(2);
                    slider:SetValue(mat_data.val);
                    
                    slider.Label:SetTextColor(THEME.text);
                    slider.Label:SetWide(150);
                    slider.TextArea:SetTextColor(THEME.text);

                    slider.OnValueChanged = function(s, value)
                        timer.Create("pro_ric_mat_update_" .. mat_data.name, 0.25, 1, function()
                            RunConsoleCommand("pro_ricochet_surfaceprop_update", mat_data.name, tostring(math.Round(value, 2)));
                        end);
                    end
                end
            end
        },
        {
            name = "Physics",
            icon = "icon16/world.png",
            vars = {
                { type = "header", label = "Drag" },
                { type = "bool", cvar = "pro_drag_enabled", label = "Enable Drag" },
                { type = "float", cvar = "pro_drag_multiplier", label = "Drag Multiplier", min = 0.0, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_drag_water_multiplier", label = "Water Drag Multiplier", min = 1.0, max = 10.0, decimals = 1 },
                { type = "header", label = "Gravity" },
                { type = "bool", cvar = "pro_gravity_enabled", label = "Enable Gravity" },
                { type = "float", cvar = "pro_gravity_multiplier", label = "Gravity Multiplier", min = 0.0, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_gravity_water_multiplier", label = "Water Gravity Multiplier", min = 0.0, max = 200.0, decimals = 0 },
                { type = "header", label = "Wind" },
                --[[{ type = "bool", cvar = "pro_wind_enabled", label = "Enable Wind" },
                { type = "float", cvar = "pro_wind_strength", label = "Wind Strength", min = 0.0, max = 20.0, decimals = 1 },
                { type = "float", cvar = "pro_wind_strength_min_variance", label = "Wind Strength Min Variance", min = 0.0, max = 10.0, decimals = 2 },
                { type = "float", cvar = "pro_wind_strength_max_variance", label = "Wind Strength Max Variance", min = 0.0, max = 10.0, decimals = 2 },
                { type = "float", cvar = "pro_wind_gust_chance", label = "Wind Gust Chance", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_wind_gust_min_strength", label = "Wind Gust Min Strength", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_wind_gust_max_strength", label = "Wind Gust Max Strength", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_wind_gust_min_duration", label = "Wind Gust Min Duration", min = 0.0, max = 120.0, decimals = 1 },
                { type = "float", cvar = "pro_wind_gust_max_duration", label = "Wind Gust Max Duration", min = 0.0, max = 120.0, decimals = 1 },
                { type = "float", cvar = "pro_wind_change_min_duration", label = "Wind Change Min Duration", min = 0.0, max = 120.0, decimals = 1 },
                { type = "float", cvar = "pro_wind_change_max_duration", label = "Wind Change Max Duration", min = 0.0, max = 120.0, decimals = 1 },
                { type = "float", cvar = "pro_wind_change_speed", label = "Wind Change Speed", min = 0.0, max = 1.0, decimals = 2 },]]
                { type = "header", label = "Coming soon... Edit via console for now" },
            }
        },
        {
            name = "Surface Properties",
            icon = "icon16/bricks.png",
            custom_draw = function(parent)
                if not SURFACE_PROPS_PENETRATION then
                    local label = vgui.Create("DLabel", parent);
                    label:SetText("Error: SURFACE_PROPS_PENETRATION table not found.");
                    label:SetTextColor(Color(255, 100, 100));
                    label:Dock(TOP);
                    label:DockMargin(10,10,10,10);
                    return;
                end
                
                local search_panel = vgui.Create("DPanel", parent)
                search_panel:Dock(TOP)
                search_panel:SetTall(40)
                search_panel:DockMargin(0,0,0,5)
                search_panel.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter);
                    draw.RoundedBox(0, 0, h-1, w, 1, THEME.divider);
                end

                local search = vgui.Create("DTextEntry", search_panel);
                search:Dock(FILL);
                search:DockMargin(10, 8, 10, 8);
                search:SetPlaceholderText("Search surface properties...");
                search:SetFont("DermaDefault")
                search.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200));
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text);

                    if (s:GetValue() == "" and s:GetPlaceholderText()) then
                        draw.SimpleText(
                            s:GetPlaceholderText(), 
                            s:GetFont(), 
                            5,
                            h / 2,
                            THEME.text_dim,
                            TEXT_ALIGN_LEFT, 
                            TEXT_ALIGN_CENTER
                        );
                    end
                end
                
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                scroll:DockMargin(0, 0, 0, 0);
                
                local list_layout = vgui.Create("DListLayout", scroll);
                list_layout:Dock(FILL);

                local sorted_keys = {};
                for k, v in pairs(SURFACE_PROPS_PENETRATION) do
                    table.insert(sorted_keys, k);
                end
                table.sort(sorted_keys);
                
                local function populate_list(filter)
                    list_layout:Clear();
                    
                    for idx, key in ipairs(sorted_keys) do
                        if filter and filter ~= "" and not string.find(string.lower(key), string.lower(filter), 1, true) then
                            continue;
                        end
                        
                        local panel = list_layout:Add("DPanel");
                        panel:SetTall(35);
                        panel:DockPadding(10, 0, 10, 0);
                        panel:DockMargin(5, 0, 5, 2);
                        panel.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
                        end
                        
                        local label = vgui.Create("DLabel", panel);
                        label:SetText(key);
                        label:SetFont("DermaDefaultBold");
                        label:Dock(LEFT);
                        label:SetWide(180);
                        label:SetTextColor(THEME.text);
                        
                        local slider = vgui.Create("DNumSlider", panel);
                        slider:Dock(FILL);
                        slider:SetMin(0);
                        slider:SetMax(1.0);
                        slider:SetDecimals(2);
                        slider:SetValue(SURFACE_PROPS_PENETRATION[key]);
                        slider.Label:SetVisible(false);
                        slider.TextArea:SetTextColor(THEME.text);
                        
                        local function send_update()
                            net.Start("projectile_surfaceprop_update");
                            net.WriteString(key);
                            net.WriteFloat(math.Round(slider:GetValue(), 2));
                            net.SendToServer();
                        end

                        slider.Think = function(s)
                            local isInteracting = s.Slider:GetDragging() or s.TextArea:IsEditing();
                            if isInteracting then
                                s.HasChanged = true;
                            elseif s.HasChanged then
                                s.HasChanged = false;
                                send_update();
                            end
                        end

                        slider.TextArea.OnEnter = function()
                            send_update();
                            slider.HasChanged = false;
                        end
                    end
                end
                
                populate_list();
                
                search.OnChange = function(s)
                    populate_list(s:GetValue());
                end
            end
        },
        {
            name = "Weapons",
            icon = "icon16/gun.png",
            lazy_load = true,
            custom_draw = function(parent)
                if not CONFIG_TYPES or not HL2_WEAPON_CLASSES then
                    local label = vgui.Create("DLabel", parent);
                    label:SetText("Error: Weapon configuration tables (CONFIG_TYPES/HL2_WEAPON_CLASSES) not found.");
                    label:SetTextColor(Color(255, 100, 100));
                    label:Dock(TOP);
                    label:DockMargin(10,10,10,10);
                    label:SizeToContents();
                    return;
                end

                local search_panel = vgui.Create("DPanel", parent)
                search_panel:Dock(TOP)
                search_panel:SetTall(40)
                search_panel:DockMargin(0,0,0,5)
                search_panel.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter);
                    draw.RoundedBox(0, 0, h-1, w, 1, THEME.divider);
                end

                local search = vgui.Create("DTextEntry", search_panel);
                search:Dock(FILL);
                search:DockMargin(10, 8, 10, 8);
                search:SetPlaceholderText("Search Weapon Class...");
                search:SetFont("DermaDefault")
                search.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200));
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text);

                    if (s:GetValue() == "" and s:GetPlaceholderText()) then
                        draw.SimpleText(
                            s:GetPlaceholderText(), 
                            s:GetFont(), 
                            5,
                            h / 2,
                            THEME.text_dim,
                            TEXT_ALIGN_LEFT, 
                            TEXT_ALIGN_CENTER
                        );
                    end
                end
                
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                
                local list_layout = vgui.Create("DListLayout", scroll);
                list_layout:Dock(TOP);
                list_layout:DockPadding(5, 5, 5, 5);

                local weapon_list = weapons.GetList();
                local sorted_weapons = {};
                local seen = {};
                
                for idx = 1, #weapon_list do
                    local wep = weapon_list[idx];
                    if not seen[wep.ClassName] then
                        table.insert(sorted_weapons, wep.ClassName);
                        seen[wep.ClassName] = true;
                    end
                end
                for idx = 1, #HL2_WEAPON_CLASSES do
                    local class_name = HL2_WEAPON_CLASSES[idx];
                    if not seen[class_name] then
                        table.insert(sorted_weapons, class_name);
                        seen[class_name] = true;
                    end
                end
                table.sort(sorted_weapons);

                local function create_slider(parent_panel, label_text, cfg_type, class_name, default_val, min_val, max_val, decimals)
                    local panel = vgui.Create("DPanel", parent_panel);
                    panel:Dock(TOP);
                    panel:SetTall(30);
                    panel:DockMargin(0, 0, 0, 2);
                    panel.Paint = function(s, w, h) end
                    
                    local label = vgui.Create("DLabel", panel);
                    label:SetText(label_text);
                    label:Dock(LEFT);
                    label:SetWide(120);
                    label:SetTextColor(THEME.text_dim);

                    local slider = vgui.Create("DNumSlider", panel);
                    slider:Dock(FILL);
                    slider:SetMin(min_val);
                    slider:SetMax(max_val);
                    slider:SetDecimals(decimals);
                    slider.Label:SetVisible(false);
                    slider.TextArea:SetTextColor(THEME.text);
                    
                    local current_table = CONFIG_TYPES[cfg_type];
                    local current_val = current_table and current_table[class_name];

                    if current_val and type(current_val) == "number" then
                        slider:SetValue(current_val);
                    else
                        local def = current_table and current_table["default"];
                        if def and type(def) == "number" then
                            slider:SetValue(def);
                        else
                            slider:SetValue(default_val);
                        end
                    end

                    local function send_update()
                        net.Start("projectile_weapon_config_update");
                        net.WriteString(cfg_type);
                        net.WriteString(class_name);
                        net.WriteFloat(math.Round(slider:GetValue(), decimals));
                        net.SendToServer();
                    end

                    slider.Think = function(s)
                        local isInteracting = s.Slider:GetDragging() or s.TextArea:IsEditing();
                        if isInteracting then
                            s.HasChanged = true;
                        elseif s.HasChanged then
                            s.HasChanged = false;
                            send_update();
                        end
                    end

                    slider.TextArea.OnEnter = function()
                        send_update();
                        slider.HasChanged = false;
                    end
                end

                local function populate_list(filter)
                    list_layout:Clear();

                    local function create_slider_with_copy(parent_panel, label_text, cfg_type, class_name, default_val, min_val, max_val, decimals, source_dropdown)
                        local panel = vgui.Create("DPanel", parent_panel);
                        panel:Dock(TOP);
                        panel:SetTall(30);
                        panel:DockMargin(0, 0, 0, 2);
                        panel.Paint = function(s, w, h) end
                        
                        local current_table = CONFIG_TYPES[cfg_type];
                        local current_val = current_table and current_table[class_name];
                        local is_using_default = false;
                        local default_source = "";
                        
                        local actual_value;
                        if current_val and type(current_val) == "number" then
                            actual_value = current_val;
                            is_using_default = false;
                        else
                            local def = current_table and current_table["default"];
                            if def and type(def) == "number" then
                                actual_value = def;
                                is_using_default = true;
                                default_source = "global default";
                            else
                                actual_value = default_val;
                                is_using_default = true;
                                default_source = "fallback default";
                            end
                        end
                        
                        local label = vgui.Create("DLabel", panel);
                        label:SetText(label_text);
                        label:Dock(LEFT);
                        label:SetWide(120);
                        label:SetTextColor(THEME.text_dim);
                        if is_using_default then
                            label:SetTooltip(label_text .. " (using " .. default_source .. ": " .. actual_value .. ")");
                        end
                    
                        if is_using_default then
                            local indicator = vgui.Create("DPanel", panel);
                            indicator:Dock(LEFT);
                            indicator:SetWide(4);
                            indicator:DockMargin(0, 6, 4, 6);
                            indicator.Paint = function(s, w, h)
                                draw.RoundedBox(1, 0, 0, w, h, Color(255, 180, 0));
                            end
                            indicator:SetTooltip("Using " .. default_source);
                        end
                    
                        local btn_copy = vgui.Create("DButton", panel);
                        btn_copy:SetText("Copy");
                        btn_copy:Dock(RIGHT);
                        btn_copy:SetWide(40);
                        btn_copy:DockMargin(5, 2, 0, 2);
                        btn_copy:SetTextColor(THEME.text);
                        btn_copy.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.accent_hover or THEME.bg_lighter)
                        end
                        btn_copy.DoClick = function()
                            local src_wep = source_dropdown:GetValue();
                            
                            if not src_wep or src_wep == "" or src_wep == "Select weapon to copy from..." then
                                LocalPlayer():ChatPrint("Please select a Source Weapon at the top of this card first.");
                                return;
                            end
                    
                            if src_wep == class_name then
                                LocalPlayer():ChatPrint("Cannot copy from itself.");
                                return;
                            end
                    
                            RunConsoleCommand("pro_weapon_config_copy_single", cfg_type, src_wep, class_name);
                            LocalPlayer():ChatPrint("Copied " .. label_text .. " from " .. src_wep);
                        end
                        btn_copy:SetTooltip("Copy " .. label_text .. " from selected source weapon");
                    
                        local btn_reset = vgui.Create("DButton", panel);
                        btn_reset:SetText("Reset");
                        btn_reset:Dock(RIGHT);
                        btn_reset:SetWide(40);
                        btn_reset:DockMargin(5, 2, 0, 2);
                        btn_reset:SetTextColor(THEME.text);
                        btn_reset.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.accent_hover or THEME.bg_lighter)
                        end
                        btn_reset.DoClick = function()
                            RunConsoleCommand("pro_weapon_config_reset_single", cfg_type, class_name);
                            LocalPlayer():ChatPrint("Reset " .. label_text .. " to default");
                        end
                        btn_reset:SetTooltip("Reset " .. label_text .. " to default");
                    
                        local slider = vgui.Create("DNumSlider", panel);
                        slider:Dock(FILL);
                        slider:SetMin(min_val);
                        slider:SetMax(max_val);
                        slider:SetDecimals(decimals);
                        slider.Label:SetVisible(false);
                        slider.TextArea:SetTextColor(THEME.text);
                        slider:SetValue(actual_value);
                        
                        if is_using_default then
                            slider:SetTooltip("Using " .. default_source .. ": " .. actual_value);
                        end
                    
                        local function send_update()
                            net.Start("projectile_weapon_config_update");
                            net.WriteString(cfg_type);
                            net.WriteString(class_name);
                            net.WriteFloat(math.Round(slider:GetValue(), decimals));
                            net.SendToServer();
                        end
                    
                        slider.Think = function(s)
                            local isInteracting = s.Slider:GetDragging() or s.TextArea:IsEditing();
                            if isInteracting then
                                s.HasChanged = true;
                            elseif s.HasChanged then
                                s.HasChanged = false;
                                send_update();
                            end
                        end
                    
                    slider.TextArea.OnEnter = function()
                        send_update();
                        slider.HasChanged = false;
                    end

                    panel.UpdateValue = function(s)
                        local isInteracting = slider.Slider:GetDragging() or slider.TextArea:IsEditing();
                        if isInteracting then return; end

                        local current_table = CONFIG_TYPES[cfg_type];
                        local current_val = current_table and current_table[class_name];
                        
                        local new_value;
                        if current_val and type(current_val) == "number" then
                            new_value = current_val;
                        else
                            local def = current_table and current_table["default"];
                            if def and type(def) == "number" then
                                new_value = def;
                            else
                                new_value = default_val;
                            end
                        end
                        
                        slider:SetValue(new_value);
                    end
                end

                for _, class_name in ipairs(sorted_weapons) do
                        if WEAPON_BLACKLIST and WEAPON_BLACKLIST[class_name] then continue; end
                        
                        if filter and filter ~= "" and not string.find(string.lower(class_name), string.lower(filter), 1, true) then
                            continue;
                        end

                        local category = list_layout:Add("DCollapsibleCategory");
                        category:SetLabel(class_name);
                        category:SetExpanded(false);
                        category:Dock(TOP);
                        category:DockMargin(0, 0, 0, 5);
                        
                        category.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, 20, THEME.bg_lighter);
                        end
                        category.Header:SetTextColor(THEME.text);
                        category.Header:SetFont("DermaDefaultBold");

                        local content = vgui.Create("DPanel");
                        content:SetBackgroundColor(THEME.bg_dark); 
                        content.Paint = function(s, w, h)
                            draw.RoundedBoxEx(4, 0, 0, w, h, Color(0,0,0,100), false, false, true, true);
                        end
                        content:DockPadding(10, 10, 10, 10);

                        local top_bar = vgui.Create("DPanel", content);
                        top_bar:Dock(TOP);
                        top_bar:SetTall(30);
                        top_bar:DockMargin(0, 0, 0, 10);
                        top_bar.Paint = function(s,w,h) end

                        local lbl = vgui.Create("DLabel", top_bar);
                        lbl:SetText("Copy Source:");
                        lbl:Dock(LEFT);
                        lbl:SetWide(80);
                        lbl:SetTextColor(THEME.accent);

                        local combo_src = vgui.Create("DComboBox", top_bar);
                        combo_src:Dock(FILL);
                        combo_src:SetText("Select weapon to copy from...");
                        combo_src:SetTextColor(THEME.text);
                        combo_src.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter); end
                        
                        for _, other in ipairs(sorted_weapons) do
                            if other ~= class_name then combo_src:AddChoice(other) end
                        end
                        
                        create_slider_with_copy(content, "Speed", "speed", class_name, CONFIG_TYPES["speed"]["default"], 0, 10000, 0, combo_src);
                        create_slider_with_copy(content, "Damage", "damage", class_name, CONFIG_TYPES["damage"]["default"], 0, 500, 0, combo_src);
                        create_slider_with_copy(content, "Penetration Power", "penetration_power", class_name, CONFIG_TYPES["penetration_power"]["default"], 0, 50, 2, combo_src);
                        create_slider_with_copy(content, "Max Penetration Count", "penetration_count", class_name, CONFIG_TYPES["penetration_count"]["default"], 0, 50, 0, combo_src);
                        create_slider_with_copy(content, "Drag", "drag", class_name, CONFIG_TYPES["drag"]["default"], 0, 10, 3, combo_src);
                        create_slider_with_copy(content, "Drop", "drop", class_name, CONFIG_TYPES["drop"]["default"], 0, 10, 3, combo_src);
                        create_slider_with_copy(content, "Min Speed (Units/s)", "min_speed", class_name, CONFIG_TYPES["min_speed"]["default"], 0, 1000, 0, combo_src);
                        create_slider_with_copy(content, "Max Dist (Units)", "max_distance", class_name, CONFIG_TYPES["max_distance"]["default"], 0, 50000, 0, combo_src);
                        create_slider_with_copy(content, "Spread Bias", "spread_bias", class_name, CONFIG_TYPES["spread_bias"]["default"], -1.0, 1.0, 2, combo_src);
                        create_slider_with_copy(content, "Dropoff Start (Units)", "dropoff_start", class_name, CONFIG_TYPES["dropoff_start"]["default"], 0, 50000, 0, combo_src);
                        create_slider_with_copy(content, "Dropoff End (Units)", "dropoff_end", class_name, CONFIG_TYPES["dropoff_end"]["default"], 0, 50000, 0, combo_src);
                        create_slider_with_copy(content, "Dropoff Min Multiplier", "dropoff_min_multiplier", class_name, CONFIG_TYPES["dropoff_min_multiplier"]["default"], 0.0, 1.0, 2, combo_src);

                        local div = vgui.Create("DPanel", content);
                        div:SetTall(2);
                        div:Dock(TOP);
                        div:DockMargin(0, 10, 0, 10);
                        div.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, THEME.divider) end

                        local btn_copy_all = vgui.Create("DButton", content);
                        btn_copy_all:Dock(TOP);
                        btn_copy_all:SetTall(25);
                        btn_copy_all:DockMargin(0, 0, 0, 5);
                        btn_copy_all:SetText("Copy all from Source Weapon");
                        btn_copy_all:SetTextColor(THEME.text);
                        btn_copy_all.Paint = function(s, w, h)
                            local col = s:IsHovered() and Color(200, 140, 60) or Color(180, 120, 40);
                            draw.RoundedBox(4, 0, 0, w, h, col);
                        end
                        btn_copy_all.DoClick = function()
                            local src_wep = combo_src:GetValue();
                            
                            if not src_wep or src_wep == "" or src_wep == "Select weapon to copy from..." then
                                LocalPlayer():ChatPrint("Select a source weapon in the dropdown above first.");
                                return;
                            end
                            
                            RunConsoleCommand("pro_weapon_config_copy_all", src_wep, class_name);
                        end

                        local btn_reset = vgui.Create("DButton", content);
                        btn_reset:Dock(TOP);
                        btn_reset:SetTall(25);
                        btn_reset:SetText("Reset all to default");
                        btn_reset:SetTextColor(THEME.text);
                        btn_reset.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(180, 60, 60) or Color(150, 40, 40))
                        end
                        btn_reset.DoClick = function()
                            RunConsoleCommand("pro_weapon_config_reset_single_all", class_name);
                        end

                        content:SetTall(520); 
                        category:SetContents(content);
                    end
                end

                populate_list();

                search.OnChange = function(s)
                    populate_list(s:GetValue());
                end
            end
        },
        {
            name = "Networking",
            icon = "icon16/server.png",
            vars = {
                { type = "header", label = "Networking" },
                { type = "bool", cvar = "pro_net_reliable", label = "Reliable projectiles" },
                { type = "dropdown", cvar = "pro_net_send_method", label = "Projectiles send method", options = { "PVS", "PAS", "Broadcast" } },
            }
        },
        {
            name = "Configs",
            icon = "icon16/package.png",
            lazy_load = true,
            custom_draw = function(parent)
                local backup_dir = "projectiles/backup";
                file.CreateDir(backup_dir);
                
                local info_bar = vgui.Create("DPanel", parent);
                info_bar:Dock(TOP);
                info_bar:SetTall(25);
                info_bar:DockMargin(0, 0, 0, 5);
                info_bar.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter);
                    draw.RoundedBox(0, 0, h - 1, w, 1, THEME.divider);
                end
                
                local lbl_info = vgui.Create("DLabel", info_bar);
                lbl_info:SetText("Client backups saved to: garrysmod/data/projectiles/backup/  |  Server backups saved on server in same location");
                lbl_info:SetPos(10, 5);
                lbl_info:SetSize(600, 15);
                lbl_info:SetTextColor(THEME.text_dim);
                
                local top_bar = vgui.Create("DPanel", parent);
                top_bar:Dock(TOP);
                top_bar:SetTall(150);
                top_bar:DockMargin(0, 0, 0, 5);
                top_bar.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter);
                    draw.RoundedBox(0, 0, h - 1, w, 1, THEME.divider);
                end
            
                local lbl_create = vgui.Create("DLabel", top_bar);
                lbl_create:SetText("Create New Backup");
                lbl_create:SetPos(10, 10);
                lbl_create:SetSize(200, 20);
                lbl_create:SetFont("DermaDefaultBold");
                lbl_create:SetTextColor(THEME.text);
            
                local lbl_name = vgui.Create("DLabel", top_bar);
                lbl_name:SetText("Backup Name:");
                lbl_name:SetPos(10, 35);
                lbl_name:SetSize(100, 20);
                lbl_name:SetTextColor(THEME.text);
            
                local entry_name = vgui.Create("DTextEntry", top_bar);
                entry_name:SetPos(110, 35);
                entry_name:SetSize(200, 25);
                entry_name:SetPlaceholderText("Enter backup name...");
                entry_name.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text);
                    if s:GetValue() == "" then
                        draw.SimpleText(s:GetPlaceholderText(), "DermaDefault", 5, h / 2, THEME.text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER);
                    end
                end
            
                local lbl_include = vgui.Create("DLabel", top_bar);
                lbl_include:SetText("Include in backup:");
                lbl_include:SetPos(10, 70);
                lbl_include:SetSize(150, 20);
                lbl_include:SetTextColor(THEME.text);
            
                local check_surfaceprops = vgui.Create("DCheckBoxLabel", top_bar);
                check_surfaceprops:SetPos(10, 90);
                check_surfaceprops:SetText("Surface Properties");
                check_surfaceprops:SetTextColor(THEME.text);
                check_surfaceprops:SetChecked(true);
                check_surfaceprops:SizeToContents();
            
                local check_weapons = vgui.Create("DCheckBoxLabel", top_bar);
                check_weapons:SetPos(160, 90);
                check_weapons:SetText("Weapon Config");
                check_weapons:SetTextColor(THEME.text);
                check_weapons:SetChecked(true);
                check_weapons:SizeToContents();
            
                local check_cvars = vgui.Create("DCheckBoxLabel", top_bar);
                check_cvars:SetPos(280, 90);
                check_cvars:SetText("CVars");
                check_cvars:SetTextColor(THEME.text);
                check_cvars:SetChecked(true);
                check_cvars:SizeToContents();
            
                local check_ricochet = vgui.Create("DCheckBoxLabel", top_bar);
                check_ricochet:SetPos(360, 90);
                check_ricochet:SetText("Ricochet Chances");
                check_ricochet:SetTextColor(THEME.text);
                check_ricochet:SetChecked(true);
                check_ricochet:SizeToContents();
            
                local btn_select_all = vgui.Create("DButton", top_bar);
                btn_select_all:SetText("Select All");
                btn_select_all:SetPos(10, 115);
                btn_select_all:SetSize(80, 25);
                btn_select_all:SetTextColor(THEME.text);
                btn_select_all.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.divider or THEME.bg_dark);
                end
                btn_select_all.DoClick = function()
                    check_surfaceprops:SetChecked(true);
                    check_weapons:SetChecked(true);
                    check_cvars:SetChecked(true);
                    check_ricochet:SetChecked(true);
                end
            
                local btn_select_none = vgui.Create("DButton", top_bar);
                btn_select_none:SetText("Select None");
                btn_select_none:SetPos(95, 115);
                btn_select_none:SetSize(80, 25);
                btn_select_none:SetTextColor(THEME.text);
                btn_select_none.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.divider or THEME.bg_dark);
                end
                btn_select_none.DoClick = function()
                    check_surfaceprops:SetChecked(false);
                    check_weapons:SetChecked(false);
                    check_cvars:SetChecked(false);
                    check_ricochet:SetChecked(false);
                end
            
                local btn_create = vgui.Create("DButton", top_bar);
                btn_create:SetText("Create Backup");
                btn_create:SetPos(320, 35);
                btn_create:SetSize(120, 25);
                btn_create:SetTextColor(THEME.text);
                btn_create.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.accent_hover or THEME.accent);
                end
            
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                scroll:GetCanvas():DockPadding(10, 10, 10, 10);
            
                local function CreateBackupCard(scroll_panel, filename, filepath, file_time, includes_str, backup_data, is_server, RefreshCallback)
                    local display_name = string.StripExtension(filename);
                    local date_str = os.date("%Y-%m-%d %H:%M:%S", file_time);
            
                    local card = scroll_panel:Add("DPanel");
                    card:Dock(TOP);
                    card:SetTall(90);
                    card:DockMargin(0, 0, 0, 5);
                    card.Paint = function(s, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
                        if s:IsHovered() then
                            draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 5));
                        end
                    end
            
                    local location_badge = vgui.Create("DLabel", card);
                    location_badge:SetText(is_server and "SERVER" or "CLIENT");
                    location_badge:SetFont("DermaDefaultBold");
                    location_badge:SetPos(10, 10);
                    location_badge:SetSize(60, 20);
                    location_badge:SetTextColor(is_server and Color(255, 200, 100) or Color(100, 200, 255));
            
                    local title = vgui.Create("DLabel", card);
                    title:SetText(display_name);
                    title:SetFont("DermaDefaultBold");
                    title:SetPos(75, 10);
                    title:SetSize(300, 20);
                    title:SetTextColor(THEME.text);
            
                    local info = vgui.Create("DLabel", card);
                    info:SetText("Created: " .. date_str);
                    info:SetPos(10, 35);
                    info:SetSize(400, 15);
                    info:SetTextColor(THEME.text_dim);
            
                    local info2 = vgui.Create("DLabel", card);
                    info2:SetText("Includes: " .. includes_str);
                    info2:SetPos(10, 53);
                    info2:SetSize(500, 15);
                    info2:SetTextColor(THEME.text_dim);
            
                    local btn_restore = vgui.Create("DButton", card);
                    btn_restore:SetText("RESTORE");
                    btn_restore:SetSize(80, 30);
                    btn_restore:SetTextColor(THEME.text);
                    btn_restore.Paint = function(s, w, h)
                        local col = s:IsHovered() and Color(46, 139, 87) or Color(60, 179, 113);
                        draw.RoundedBox(4, 0, 0, w, h, col);
                    end
            
                    local btn_delete = vgui.Create("DButton", card);
                    btn_delete:SetText("DELETE");
                    btn_delete:SetSize(80, 30);
                    btn_delete:SetTextColor(THEME.text);
                    btn_delete.Paint = function(s, w, h)
                        local col = s:IsHovered() and Color(180, 60, 60) or Color(150, 40, 40);
                        draw.RoundedBox(4, 0, 0, w, h, col);
                    end
            
                    card.PerformLayout = function(s, w, h)
                        btn_delete:SetPos(w - 90, h / 2 - 15);
                        btn_restore:SetPos(w - 180, h / 2 - 15);
                    end
            
                    btn_restore.DoClick = function()
                        Derma_Query("Are you sure you want to restore this backup? This will overwrite your current settings.", "Confirm Restore", "Yes", function()
                            if backup_data then
                                local compressed_data = util.Compress(util.TableToJSON(backup_data));
                                local compressed_size = string.len(compressed_data);
                                local chunk_size = 65000;
                                local total_chunks = math.ceil(compressed_size / chunk_size);
                                
                                net.Start("projectiles_restore_config_start");
                                net.WriteUInt(total_chunks, 16);
                                net.WriteUInt(compressed_size, 32);
                                net.SendToServer();
                                
                                local chunk_index = 0;
                                local function SendNextChunk()
                                    chunk_index = chunk_index + 1;
                                    if chunk_index > total_chunks then
                                        chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 255, 255), "Backup '" .. display_name .. "' sent to server (" .. total_chunks .. " chunks)");
                                        return;
                                    end
                                    
                                    local start_pos = (chunk_index - 1) * chunk_size + 1;
                                    local end_pos = math.min(start_pos + chunk_size - 1, compressed_size);
                                    local chunk = string.sub(compressed_data, start_pos, end_pos);
                                    
                                    net.Start("projectiles_restore_config_chunk");
                                    net.WriteUInt(chunk_index, 16);
                                    net.WriteUInt(string.len(chunk), 32);
                                    net.WriteData(chunk, string.len(chunk));
                                    net.SendToServer();
                                    
                                    timer.Simple(0.01, SendNextChunk);
                                end
                                
                                SendNextChunk();
                            elseif is_server then
                                RunConsoleCommand("pro_config_restore_json", display_name);
                            else
                                chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 100, 100), "Failed to parse backup file!");
                            end
                        end, "No");
                    end
            
                    btn_delete.DoClick = function()
                        if is_server then
                            chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 100, 100), "Cannot delete server backups from client!");
                            return;
                        end
                        
                        Derma_Query("Are you sure you want to delete this backup? This cannot be undone.", "Confirm Delete", "Yes", function()
                            file.Delete(filepath);
                            chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 255, 255), "Backup '" .. display_name .. "' deleted!");
                            RefreshCallback();
                        end, "No");
                    end
                end
            
                local function RefreshBackupList()
                    scroll:Clear();
            
                    local header_client = vgui.Create("DPanel", scroll);
                    header_client:Dock(TOP);
                    header_client:SetTall(30);
                    header_client:DockMargin(0, 0, 0, 5);
                    header_client.Paint = function(s, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                        draw.SimpleText("CLIENT BACKUPS", "DermaDefaultBold", 10, h/2, Color(100, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER);
                    end
            
                    local files, dirs = file.Find(backup_dir .. "/*.json", "DATA");
            
                    if not files or #files == 0 then
                        local no_backups = vgui.Create("DLabel", scroll);
                        no_backups:SetText("No client backups found. Create one above!");
                        no_backups:SetTextColor(THEME.text_dim);
                        no_backups:Dock(TOP);
                        no_backups:DockMargin(10, 5, 10, 10);
                    else
                        table.sort(files, function(a, b) 
                            local time_a = file.Time(backup_dir .. "/" .. a, "DATA");
                            local time_b = file.Time(backup_dir .. "/" .. b, "DATA");
                            return time_a > time_b;
                        end);
            
                        for idx = 1, #files do
                            local filename = files[idx];
                            local filepath = backup_dir .. "/" .. filename;
                            local file_time = file.Time(filepath, "DATA");
            
                            local content = file.Read(filepath, "DATA");
                            local backup_data = content and util.JSONToTable(content);
                            local includes = "";
                            if backup_data then
                                local parts = {};
                                if backup_data.surfaceprops then table.insert(parts, "Surface Props"); end
                                if backup_data.weapon_config then table.insert(parts, "Weapons"); end
                                if backup_data.cvars then table.insert(parts, "CVars"); end
                                if backup_data.ricochet_mat_chance_multipliers then table.insert(parts, "Ricochet"); end
                                includes = #parts > 0 and table.concat(parts, ", ") or "Unknown";
                            end
            
                            CreateBackupCard(scroll, filename, filepath, file_time, includes, backup_data, false, RefreshBackupList);
                        end
                    end
            
                    local header_server = vgui.Create("DPanel", scroll);
                    header_server:Dock(TOP);
                    header_server:SetTall(30);
                    header_server:DockMargin(0, 15, 0, 5);
                    header_server.Paint = function(s, w, h)
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                        draw.SimpleText("SERVER BACKUPS", "DermaDefaultBold", 10, h/2, Color(255, 200, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER);
                    end
            
                    local loading_label = vgui.Create("DLabel", scroll);
                    loading_label:SetText("Loading server backups...");
                    loading_label:SetTextColor(THEME.text_dim);
                    loading_label:Dock(TOP);
                    loading_label:DockMargin(10, 5, 10, 10);
            
                    net.Start("projectiles_query_configs");
                    net.SendToServer();
                end
            
                net.Receive("projectiles_query_configs", function()
                    local count = net.ReadUInt(16);
                    if not IsValid(scroll) then return; end
                        
                    local children = scroll:GetCanvas():GetChildren();
                    for i = 1, #children do
                        if children[i]:GetText() == "Loading server backups..." then
                            children[i]:Remove();
                            break;
                        end
                    end
                        
                    if count == 0 then
                        local no_backups = vgui.Create("DLabel", scroll);
                        no_backups:SetText("No server backups found.");
                        no_backups:SetTextColor(THEME.text_dim);
                        no_backups:Dock(TOP);
                        no_backups:DockMargin(10, 5, 10, 10);
                        return;
                    end
                        
                    for i = 1, count do
                        local filename = net.ReadString();
                        local file_time = tonumber(net.ReadString());
                        local includes_count = net.ReadUInt(8);
                        local includes = {};
                        for j = 1, includes_count do
                            table.insert(includes, net.ReadString());
                        end
                        local includes_str = #includes > 0 and table.concat(includes, ", ") or "Unknown";
                        CreateBackupCard(scroll, filename, nil, file_time, includes_str, nil, true, RefreshBackupList);
                    end
                end);
            
                btn_create.DoClick = function()
                    local name = string.Trim(entry_name:GetValue());
                    
                    if name == "" then
                        Derma_Message("Please enter a backup name.", "Missing Name", "OK");
                        return;
                    end
            
                    name = string.gsub(name, "[^%w%s%-_]", "");
                    
                    if name == "" then
                        Derma_Message("Please enter a valid backup name (alphanumeric characters only).", "Invalid Name", "OK");
                        return;
                    end
            
                    local flags = 0;
                    if check_surfaceprops:GetChecked() then flags = bit.bor(flags, 0x1); end
                    if check_weapons:GetChecked() then flags = bit.bor(flags, 0x2); end
                    if check_cvars:GetChecked() then flags = bit.bor(flags, 0x4); end
                    if check_ricochet:GetChecked() then flags = bit.bor(flags, 0x8); end
            
                    if flags == 0 then
                        Derma_Message("Please select at least one component to backup.", "Nothing Selected", "OK");
                        return;
                    end
            
                    RunConsoleCommand("pro_config_backup_json_flags", name, tostring(flags));
                    
                    timer.Simple(0.1, function()
                        RefreshBackupList();
                        entry_name:SetValue("");
                        chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 255, 255), "Backup '" .. name .. "' created!");
                    end);
                end
            
                RefreshBackupList();
            end
        },
        {
            name = "Marketplace",
            icon = "icon16/server_compressed.png",
            lazy_load = true,
            custom_draw = function(parent)
                local marketplace_search_url = "https://projectilemod.directory/configs/search";
                local api_base = "https://projectilemod.directory/";
                local current_sort = "date";
                local current_auth_user = nil;
                
                local top_bar = vgui.Create("DPanel", parent);
                top_bar:Dock(TOP);
                top_bar:SetTall(45);
                top_bar:DockMargin(0, 0, 0, 5);
                top_bar.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter);
                    draw.RoundedBox(0, 0, h - 1, w, 1, THEME.divider);
                end
            
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                scroll:GetCanvas():DockPadding(10, 10, 10, 10);

                local btn_login = nil;

                local function UpdateLoginButton(status, user_data)
                    if not IsValid(btn_login) then return; end

                    if status == "loading" then
                        btn_login:SetText("...");
                        btn_login:SetEnabled(false);
                        btn_login.user_data = nil;
                    elseif status == "logged_in" and user_data then
                        btn_login:SetText(user_data.username or "Unknown");
                        btn_login:SetEnabled(true);
                        btn_login.user_data = user_data;
                        btn_login.is_logged_in = true;
                        btn_login:SetTooltip("Logged in as " .. (user_data.steamid or "User") .. ". Click to logout.");
                    else
                        btn_login:SetText("Login");
                        btn_login:SetEnabled(true);
                        btn_login.user_data = nil;
                        btn_login.is_logged_in = false;
                        btn_login:SetTooltip("Click to enter API Key");
                    end
                end

                local function VerifyAuthKey(key)
                    if not key or key == "" then 
                        print("[ProjectileMod] No API Key provided");
                        UpdateLoginButton("logged_out");
                        return;
                    end

                    UpdateLoginButton("loading");

                    http.Fetch(api_base .. "users/me",
                        function(body, len, headers, code)
                            if code == 200 then
                                local data = util.JSONToTable(body);
                                current_auth_user = data;
                                UpdateLoginButton("logged_in", data);
                            else
                                cookie.Delete("projectile_api_key");
                                current_auth_user = nil;
                                UpdateLoginButton("logged_out");
                                print("[ProjectileMod] Auth Check Failed: " .. body);
                                print("[ProjectileMod] Code: " .. code);
                                print("[ProjectileMod] Headers: " .. util.TableToJSON(headers));
                                print("[ProjectileMod] Body: " .. body);
                            end
                        end,
                        function(err)
                            print("[ProjectileMod] Auth Check Failed: " .. err);
                            UpdateLoginButton("logged_out");
                        end,
                        { ["Authorization"] = "Bearer " .. key }
                    );
                end
            
                local function LoadMarketplace(query)
                    scroll:Clear();
                    
                    local fetch_url = string.format("%s?limit=100&sort_by=%s&order=desc", marketplace_search_url, current_sort);
                    if query and query ~= "" then
                        fetch_url = fetch_url .. "&name=" .. string.Replace(query, " ", "%20");
                    end
                    
                    local headers = {};
                    local key = cookie.GetString("projectile_api_key");
                    if key and key ~= "" then
                        headers["Authorization"] = "Bearer " .. key;
                    end
            
                    http.Fetch(fetch_url, function(body, len, headers, code)
                        if not IsValid(scroll) then return end
                        local data = util.JSONToTable(body);
                        if not data then return; end
            
                        for idx = 1, #data do
                            local cfg = data[idx];
                            
                            local card = scroll:Add("DPanel");
                            card:Dock(TOP);
                            card:SetTall(60);
                            card:DockMargin(0, 0, 0, 5);
                            card.Paint = function(s, w, h)
                                draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
                                if s:IsHovered() then
                                    draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 5));
                                end
                            end
            
                            local title = vgui.Create("DLabel", card);
                            title:SetText(cfg.name or "Unnamed Config");
                            title:SetFont("DermaDefaultBold");
                            title:SetPos(10, 10);
                            title:SetSize(300, 20);
                            title:SetTextColor(THEME.text);
            
                            local info = vgui.Create("DLabel", card);
                            local date_str = string.sub(cfg.created_at or "", 1, 10);
                            info:SetText(string.format("By: %s  |  Rating: %s  |  Date: %s", cfg.steamid, cfg.rating or "0.0", date_str));
                            info:SetPos(10, 32);
                            info:SetSize(400, 15);
                            info:SetTextColor(THEME.text_dim);
            
                            local btn_install = vgui.Create("DButton", card);
                            btn_install:SetText("INSTALL");
                            btn_install:SetSize(80, 30);
                            btn_install:SetPos(card:GetWide() - 90, 15);
                            btn_install:SetTextColor(THEME.text);
                            btn_install.Paint = function(s, w, h)
                                local col = s:IsHovered() and THEME.accent_hover or THEME.accent;
                                draw.RoundedBox(4, 0, 0, w, h, col);
                            end
                            
                            card.PerformLayout = function(s, w, h)
                                btn_install:SetPos(w - 90, h / 2 - 15);
                            end
            
                            btn_install.DoClick = function()
                                Derma_Query("Are you sure you want to apply this configuration?", "Confirm Installation", "Yes", function()
                                    local config = cfg.config and util.JSONToTable(cfg.config) or nil;
                                    if config then
                                        projectiles_restore_config(config);
                                        chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 255, 255), "Config '" .. cfg.name .. "' applied!")
                                    else
                                        chat.AddText(THEME.accent, "[ProjectileMod] ", Color(255, 255, 255), "Config '" .. cfg.name .. "' is invalid! Please contact the developer.")
                                    end
                                end, "No")
                            end
                        end
                    end, function(err)
                        print("[Marketplace] Error: ", err);
                    end, headers);
                end
            
                local search = vgui.Create("DTextEntry", top_bar);
                search:SetSize(250, 25);
                search:SetPos(10, 10);
                search:SetPlaceholderText("Search marketplace...");
                search.OnEnter = function(s) LoadMarketplace(s:GetValue()); end
                search.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text);
                    if s:GetValue() == "" then
                        draw.SimpleText(s:GetPlaceholderText(), "DermaDefault", 5, h / 2, THEME.text_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER);
                    end
                end
            
                local sort_label = vgui.Create("DLabel", top_bar);
                sort_label:SetText("Sort By:")
                sort_label:SetPos(280, 10);
                sort_label:SetSize(50, 25);
                sort_label:SetTextColor(THEME.text_dim);
            
                local sort_combo = vgui.Create("DComboBox", top_bar);
                sort_combo:SetSize(100, 25);
                sort_combo:SetPos(335, 10);
                sort_combo:AddChoice("Newest", "date");
                sort_combo:AddChoice("Rating", "rating");
                sort_combo:AddChoice("Name", "name");
                sort_combo:ChooseOptionID(1);
                sort_combo:SetTextColor(THEME.text);
                sort_combo.OnSelect = function(s, idx, val, data)
                    current_sort = data;
                    LoadMarketplace(search:GetValue());
                end
                sort_combo.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, THEME.bg_dark);
                end
            
                local btn_refresh = vgui.Create("DButton", top_bar);
                btn_refresh:SetText("Refresh");
                btn_refresh:SetSize(80, 25);
                btn_refresh:SetPos(445, 10);
                btn_refresh:SetTextColor(THEME.text);
                btn_refresh.DoClick = function() LoadMarketplace(search:GetValue()); end
                btn_refresh.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and THEME.divider or THEME.bg_dark);
                end

                btn_login = vgui.Create("DButton", top_bar);
                btn_login:SetText("Login");
                btn_login:SetSize(100, 25);
                btn_login:SetPos(535, 10);
                btn_login:SetTextColor(THEME.text);
                btn_login.Paint = function(s, w, h)
                    local col = THEME.bg_dark;
                    if s.is_logged_in then
                        col = s:IsHovered() and Color(46, 139, 87) or Color(60, 179, 113);
                    else
                        col = s:IsHovered() and THEME.accent_hover or THEME.accent;
                    end
                    draw.RoundedBox(4, 0, 0, w, h, col)
                end
                btn_login.DoClick = function(s)
                    if s.is_logged_in then
                        Derma_Query("Do you want to logout?", "Logout", "Yes", function()
                            cookie.Delete("projectile_api_key");
                            current_auth_user = nil;
                            UpdateLoginButton("logged_out");
                        end, "Cancel")
                    else
                        local frame = vgui.Create("DFrame");
                        frame:SetSize(300, 185);
                        frame:Center();
                        frame:SetTitle("ProjectileMod Login");
                        frame:MakePopup();
                        frame.Paint = function(self, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
                            draw.RoundedBox(4, 0, 0, w, 24, THEME.bg_dark);
                        end

                        local lbl_step1 = vgui.Create("DLabel", frame);
                        lbl_step1:SetText("1. Open browser to get API Key:");
                        lbl_step1:SetPos(10, 35);
                        lbl_step1:SetSize(280, 15);
                        lbl_step1:SetTextColor(THEME.text);

                        local btn_browser = vgui.Create("DButton", frame);
                        btn_browser:SetText("Open Login Page");
                        btn_browser:SetPos(10, 55);
                        btn_browser:SetSize(280, 25);
                        btn_browser:SetTextColor(THEME.text);
                        btn_browser.Paint = function(me, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, me:IsHovered() and THEME.accent_hover or THEME.accent);
                        end
                        btn_browser.DoClick = function()
                            gui.OpenURL("https://projectilemod.directory/auth/landing");
                        end

                        local lbl_step2 = vgui.Create("DLabel", frame);
                        lbl_step2:SetText("2. Paste your API Key below:");
                        lbl_step2:SetPos(10, 90);
                        lbl_step2:SetSize(280, 15);
                        lbl_step2:SetTextColor(THEME.text);

                        local entry_key = vgui.Create("DTextEntry", frame);
                        entry_key:SetPos(10, 110);
                        entry_key:SetSize(280, 25);
                        entry_key:SetPlaceholderText("Paste key here...");

                        local btn_confirm = vgui.Create("DButton", frame);
                        btn_confirm:SetText("Confirm & Login");
                        btn_confirm:SetPos(10, 145);
                        btn_confirm:SetSize(280, 30);
                        btn_confirm:SetTextColor(THEME.text);
                        btn_confirm.Paint = function(me, w, h)
                            draw.RoundedBox(4, 0, 0, w, h, me:IsHovered() and Color(46, 139, 87) or Color(60, 179, 113));
                        end
                        btn_confirm.DoClick = function()
                            local key = string.Trim(entry_key:GetValue());
                            print("[ProjectileMod] API Key: ", key);
                            if key ~= "" then
                                cookie.Set("projectile_api_key", key);
                                VerifyAuthKey(key);
                                frame:Close();
                            else
                                Derma_Message("Please paste the API Key first.", "Missing Key", "OK");
                            end
                        end
                    end
                end

                local saved_key = cookie.GetString("projectile_api_key");
                if saved_key and saved_key ~= "" then
                    VerifyAuthKey(saved_key);
                else
                    UpdateLoginButton("logged_out");
                end
            
                LoadMarketplace();
            end
        },
        {
            name = "Debug",
            icon = "icon16/bug.png",
            vars = {
                { type = "header", label = "Visualization" },
                { type = "bool", cvar = "pro_debug_projectiles", label = "Draw Projectiles (Cheat)" },
                { type = "bool", cvar = "pro_debug_penetration", label = "Draw Penetration (Cheat)" },
                { type = "bool", cvar = "pro_debug_ricochet", label = "Draw Ricochet (Cheat)" },
                { type = "float", cvar = "pro_debug_duration", label = "Debug Draw Duration", min = 0.1, max = 10.0, decimals = 1 },
                { type = "color", cvar = "pro_debug_color", label = "Debug Color" },
            }
        },
    };

    local function OpenConfigMenu()
        local frame = vgui.Create("DFrame");
        frame:SetSize(800, 800);
        frame:Center();
        frame:SetTitle(""); 
        frame:MakePopup();
        
        frame.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, THEME.bg_dark)
            draw.RoundedBoxEx(6, 0, 0, w, 25, THEME.header_bg, true, true, false, false)
            draw.SimpleText("Projectile Configuration", "DermaDefaultBold", 10, 12, THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        local sheet = vgui.Create("DPropertySheet", frame);
        sheet:Dock(FILL);
        sheet:DockMargin(5, 5, 5, 5);

        local function RecursiveRefresh(pnl)
            if IsValid(pnl) and pnl.UpdateValue then pnl:UpdateValue(); end
            
            local children = pnl:GetChildren();
            for idx = 1, #children do
                local child = children[idx];
                if IsValid(child) then
                    RecursiveRefresh(child);
                end
            end
        end
        
        sheet.Paint = function(s, w, h)
            if (CurTime() - (s.LastUpdated or 0)) > 0.1 then
                RecursiveRefresh(s);
                s.LastUpdated = CurTime();
            end
         end

        sheet.OnActiveTabChanged = function(s, old, new)
            if not IsValid(new) then return end
            
            local panel = new:GetPanel();
            if panel and panel.DoBuild and not panel.HasBuilt then
                panel.DoBuild(panel);
                panel.HasBuilt = true;
            end

            RecursiveRefresh(panel);
        end
        
        for idx, tab_data in ipairs(menu_tabs) do
            local panel = vgui.Create("DPanel", sheet);
            panel:Dock(FILL);
            panel.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,50));
            end

            local function BuildTab(pnl)
                if tab_data.custom_draw then
                    tab_data.custom_draw(pnl);
                else
                    local scroll = vgui.Create("DScrollPanel", pnl);
                    scroll:Dock(FILL);
                    scroll:DockPadding(10, 10, 10, 10);

                    for _, var_data in ipairs(tab_data.vars) do
                        CreateControl(scroll, var_data);
                    end
                end
            end

            if tab_data.lazy_load then
                panel.DoBuild = BuildTab;
            else
                BuildTab(panel);
                panel.HasBuilt = true;
            end

            sheet:AddSheet(tab_data.name, panel, tab_data.icon);
        end
        
        for k, v in pairs(sheet:GetItems()) do
            if v.Tab then
                v.Tab.Paint = function(s, w, h)
                    if s:IsActive() then
                        draw.RoundedBox(4, 0, 0, w, h, THEME.accent);
                    else
                        draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter);
                    end
                end
                v.Tab:SetTextColor(THEME.text);
            end
        end
    end

    concommand.Add("pro_config", OpenConfigMenu);

    hook.Add("PopulateToolMenu", "ProjectilesAddToSpawnMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "Projectile Mod", "ProjectileConfig", "Configuration", "", "", function(panel)
            panel:ClearControls();
            
            panel:Help("Projectile Mod Configuration");
            panel:Help("Configure weapon ballistics, penetration, ricochet, and more.");
            
            local btn = panel:Button("Open Config Menu");
            btn.DoClick = function()
                RunConsoleCommand("pro_config");
            end
        end);
    end);
end

print("loaded projectiles config");