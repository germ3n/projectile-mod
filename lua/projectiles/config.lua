AddCSLuaFile();

if SERVER then
    util.AddNetworkString("projectile_update_cvar");

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
    
    local THEME = {
        bg_dark = Color(30, 30, 35, 250),
        bg_lighter = Color(40, 40, 45, 255),
        header_bg = Color(20, 20, 25, 255),
        accent = Color(70, 130, 180), -- Steel Blue
        accent_hover = Color(90, 150, 200),
        text = Color(230, 230, 230),
        text_dim = Color(150, 150, 150),
        divider = Color(60, 60, 65)
    }

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
                { type = "float", cvar = "pro_speed_scale", label = "Speed Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_weapon_damage_scale", label = "Damage Scale", min = 0.1, max = 5.0, decimals = 2 },
                { type = "float", cvar = "pro_penetration_power_scale", label = "Power Scale", min = 0.1, max = 5.0, decimals = 2 },
            }
        },
        {
            name = "Render",
            icon = "icon16/paintbrush.png",
            vars = {
                { type = "header", label = "Render Settings" },
                { type = "bool", cvar = "pro_render_enabled", label = "Enable Projectile Rendering" },
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
            vars = {
                { type = "header", label = "Logic" },
                { type = "bool", cvar = "pro_ricochet_enabled", label = "Enable Ricochet" },
                { type = "float", cvar = "pro_ricochet_chance", label = "Ricochet Chance", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_ricochet_spread", label = "Spread", min = 0.0, max = 1.0, decimals = 2 },
                { type = "header", label = "Multipliers" },
                { type = "float", cvar = "pro_ricochet_speed_multiplier", label = "Speed Multiplier", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_ricochet_damage_multiplier", label = "Damage Multiplier", min = 0.0, max = 1.0, decimals = 2 },
                { type = "float", cvar = "pro_ricochet_distance_multiplier", label = "Distance Multiplier", min = 0.1, max = 5.0, decimals = 1 },
            }
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
            }
        },
        {
            name = "Materials",
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
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter)
                    draw.RoundedBox(0, 0, h-1, w, 1, THEME.divider)
                end

                local search = vgui.Create("DTextEntry", search_panel);
                search:Dock(FILL);
                search:DockMargin(10, 8, 10, 8);
                search:SetPlaceholderText("Search surface properties...");
                search:SetFont("DermaDefault")
                search.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200))
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
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
                            draw.RoundedBox(4, 0, 0, w, h, THEME.bg_lighter)
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
                        slider.Label:SetVisible(false) 
                        slider.TextArea:SetTextColor(THEME.text)
                        
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
                    draw.RoundedBox(0, 0, 0, w, h, THEME.bg_lighter)
                    draw.RoundedBox(0, 0, h-1, w, 1, THEME.divider)
                end

                local search = vgui.Create("DTextEntry", search_panel);
                search:Dock(FILL);
                search:DockMargin(10, 8, 10, 8);
                search:SetPlaceholderText("Search Weapon Class...");
                search:SetFont("DermaDefault")
                search.Paint = function(s, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 200))
                    s:DrawTextEntryText(THEME.text, THEME.accent, THEME.text)
                end
                
                local scroll = vgui.Create("DScrollPanel", parent);
                scroll:Dock(FILL);
                
                local list_layout = vgui.Create("DListLayout", scroll);
                list_layout:Dock(FILL);
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

                local function create_slider(parent_panel, label_text, cfg_type, class_name, default_val, max_val, decimals)
                    local panel = vgui.Create("DPanel", parent_panel);
                    panel:Dock(TOP);
                    panel:SetTall(30);
                    panel:DockMargin(0, 0, 0, 2);
                    panel.Paint = function(s, w, h) end
                    
                    local label = vgui.Create("DLabel", panel);
                    label:SetText(label_text);
                    label:Dock(LEFT);
                    label:SetWide(100);
                    label:SetTextColor(THEME.text_dim);

                    local slider = vgui.Create("DNumSlider", panel);
                    slider:Dock(FILL);
                    slider:SetMin(0);
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
                        net.Start("projectile_config_update");
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

                    for _, class_name in ipairs(sorted_weapons) do
                        if WEAPON_BLACKLIST and WEAPON_BLACKLIST[class_name] then continue end
                        
                        if filter and filter ~= "" and not string.find(string.lower(class_name), string.lower(filter), 1, true) then
                            continue;
                        end

                        local category = list_layout:Add("DCollapsibleCategory");
                        category:SetLabel(class_name);
                        category:SetExpanded(false);
                        category:Dock(TOP);
                        category:DockMargin(0, 0, 0, 5);
                        
                        category.Paint = function(s, w, h)
                            draw.RoundedBox(4, 0, 0, w, 20, THEME.bg_lighter)
                        end
                        category.Header:SetTextColor(THEME.text)
                        category.Header:SetFont("DermaDefaultBold")

                        local content = vgui.Create("DPanel");
                        content:SetBackgroundColor(THEME.bg_dark); 
                        content.Paint = function(s, w, h)
                            draw.RoundedBoxEx(4, 0, 0, w, h, Color(0,0,0,100), false, false, true, true)
                        end
                        
                        content:DockPadding(10, 10, 10, 10);
                        
                        create_slider(content, "Speed", "speed", class_name, 2000, 10000, 0);
                        create_slider(content, "Damage", "damage", class_name, 10, 500, 0);
                        create_slider(content, "Pen Power", "penetration_power", class_name, 2.5, 50, 2);
                        create_slider(content, "Pen Count", "penetration_count", class_name, 10, 50, 0);
                        create_slider(content, "Drag", "drag", class_name, 0, 10, 3);
                        create_slider(content, "Drop", "drop", class_name, 0, 5, 3);
                        create_slider(content, "Min Speed (Units/s)", "min_speed", class_name, 0, 500, 0);
                        create_slider(content, "Max Dist (Units)", "max_distance", class_name, 500, 50000, 0);

                        content:SetTall(290); 
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
                
                timer.Create("projectile_update_cvar_timer_" .. data.cvar, 0.2, 1, function()
                    net.Start("projectile_update_cvar");
                    net.WriteString(data.cvar);
                    net.WriteString(tostring(value));
                    net.SendToServer();
                end);
            end

            slider.UpdateValue = function(s)
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
                timer.Create("projectile_update_cvar_timer_" .. data.cvar, 0.2, 1, function()
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
        end
    end

    local function OpenConfigMenu()
        local frame = vgui.Create("DFrame");
        frame:SetSize(650, 650);
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
        
        sheet.Paint = function(s, w, h) end

        local function RecursiveRefresh(pnl)
            print("RecursiveRefresh", pnl);
            if IsValid(pnl) and pnl.UpdateValue then pnl:UpdateValue(); end
            
            local children = pnl:GetChildren();
            for idx = 1, #children do
                local child = children[idx];
                if IsValid(child) then
                    RecursiveRefresh(child);
                end
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
end

print("loaded projectiles config");