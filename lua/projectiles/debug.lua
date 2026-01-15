AddCSLuaFile();

local projectiles = projectiles;
local projectile_store = projectile_store;
local broadcast_projectile = broadcast_projectile;
local get_weapon_speed = get_weapon_speed;
local get_weapon_damage = get_weapon_damage;
local get_weapon_drag = get_weapon_drag;
local get_weapon_penetration_power = get_weapon_penetration_power;
local get_weapon_penetration_count = get_weapon_penetration_count;
local get_weapon_mass = get_weapon_mass;
local get_weapon_drop = get_weapon_drop;
local get_weapon_min_speed = get_weapon_min_speed;
local get_weapon_max_distance = get_weapon_max_distance;
local get_weapon_tracer_colors = get_weapon_tracer_colors;
local get_weapon_tracer_flags = get_weapon_tracer_flags;
local get_weapon_dropoff_start = get_weapon_dropoff_start;
local get_weapon_dropoff_end = get_weapon_dropoff_end;
local get_weapon_dropoff_min_multiplier = get_weapon_dropoff_min_multiplier;
local get_current_wind_seed = get_current_wind_seed;
local IsValid = IsValid;
local vector = Vector;
local angle = Angle;
local color = Color;
local cur_time = CurTime;
local sys_time = SysTime;
local next = next;
local tonumber = tonumber;
local tostring = tostring;
local string_format = string.format;
local NULL = NULL;

local math_sin = math.sin;
local math_cos = math.cos;
local math_rad = math.rad;
local math_random = math.random;

local engine_tick_interval = engine.TickInterval;

local player_meta = FindMetaTable("Player");
local is_superadmin = player_meta.IsSuperAdmin;
local chat_print = player_meta.ChatPrint;
local get_ping = player_meta.Ping;
local get_active_weapon = player_meta.GetActiveWeapon;

local entity_meta = FindMetaTable("Entity");
local get_class = entity_meta.GetClass;
local is_valid = entity_meta.IsValid;
local eye_pos = entity_meta.EyePos;
local eye_angles = entity_meta.EyeAngles;

local angle_meta = FindMetaTable("Angle");
local angle_forward = angle_meta.Forward;
local angle_right = angle_meta.Right;
local angle_up = angle_meta.Up;

local vector_meta = FindMetaTable("Vector");
local get_normalized = vector_meta.GetNormalized;

local timer_create = timer.Create;
local timer_remove = timer.Remove;

if SERVER then
	
	local stress_test_data = {
		active = false,
		start_time = 0.0,
		total_spawned = 0,
		last_report_time = 0.0,
	};
	
	local function get_total_active_projectiles()
		local total = 0;
		
		for shooter, store in next, projectile_store do
			if store and store.active_projectiles then
				total = total + #store.active_projectiles;
			end
		end
		
		return total;
	end
	
	local function spawn_projectile_pattern(ply, pos, pattern, count, spread_radius)
		local weapon = get_active_weapon(ply);
		if not is_valid(weapon) then
			weapon = ply;
		end
		
		local weapon_class = get_class(weapon);
		local speed = get_weapon_speed(weapon, weapon_class, 25, "");
		local damage = get_weapon_damage(weapon, weapon_class, 25);
		local drag = get_weapon_drag(weapon, weapon_class);
		local penetration_power = get_weapon_penetration_power(weapon, weapon_class);
		local penetration_count = get_weapon_penetration_count(weapon, weapon_class);
		local mass = get_weapon_mass(weapon, weapon_class);
		local drop = get_weapon_drop(weapon, weapon_class);
		local min_speed = get_weapon_min_speed(weapon, weapon_class);
		local max_distance = get_weapon_max_distance(weapon, weapon_class);
		local tracer_colors = get_weapon_tracer_colors(weapon, weapon_class);
		local tracer_flags = get_weapon_tracer_flags(weapon, weapon_class);
		local dropoff_start = get_weapon_dropoff_start(weapon, weapon_class);
		local dropoff_end = get_weapon_dropoff_end(weapon, weapon_class);
		local dropoff_min_multiplier = get_weapon_dropoff_min_multiplier(weapon, weapon_class);
		
		speed = speed * projectiles["pro_speed_scale"];
		damage = damage * projectiles["pro_weapon_damage_scale"];
		penetration_power = penetration_power * projectiles["pro_penetration_power_scale"];
		
		local eye_ang = eye_angles(ply);
		local aim_dir = angle_forward(eye_ang);
		local right = angle_right(eye_ang);
		local up = angle_up(eye_ang);
		
		local dir;
		
		for idx = 1, count do
			if pattern == "radial" then
				local angle_step = 360 / count;
				local ang = math_rad(angle_step * idx);
				dir = vector(math_cos(ang), math_sin(ang), 0);
				dir = get_normalized(dir);
			elseif pattern == "sphere" then
				local phi = math_rad(math_random(0, 360));
				local theta = math_rad(math_random(0, 180));
				dir = vector(
					math_sin(theta) * math_cos(phi),
					math_sin(theta) * math_sin(phi),
					math_cos(theta)
				);
				dir = get_normalized(dir);
			elseif pattern == "cone" then
				local spread_angle = math_rad(math_random(0, 360));
				local spread_dist = math_random(0, spread_radius);
				local spread_x = math_cos(spread_angle) * spread_dist;
				local spread_y = math_sin(spread_angle) * spread_dist;
				dir = aim_dir + right * spread_x + up * spread_y;
				dir = get_normalized(dir);
			else
				dir = aim_dir;
			end
			
			broadcast_projectile(
				ply,
				weapon,
				pos,
				dir,
				speed,
				damage,
				drag,
				penetration_power,
				penetration_count,
				mass,
				drop,
				min_speed,
				max_distance,
				tracer_colors,
				tracer_flags,
				false,
				dropoff_start,
				dropoff_end,
				dropoff_min_multiplier,
				"",
				false,
				idx,
				true
			);
		end
		
		stress_test_data.total_spawned = stress_test_data.total_spawned + count;
	end
	
	concommand.Add("pro_stress_test", function(ply, cmd, args)
		if is_valid(ply) and not is_superadmin(ply) then
			chat_print(ply, "You must be a superadmin to use this command.");
			
			return;
		end
		
		local count = tonumber(args[1]) or 100;
		local pattern = args[2] or "sphere";
		local interval = tonumber(args[3]) or 0;
		local spread = tonumber(args[4]) or 0.1;
		
		if count > 10000 then
			if is_valid(ply) then
				chat_print(ply, "Count limited to 10000 for safety.");
			end
			
			count = 10000;
		end
		
		local spawn_pos = is_valid(ply) and eye_pos(ply) or vector(0, 0, 100);
		
		stress_test_data.active = true;
		stress_test_data.start_time = sys_time();
		stress_test_data.total_spawned = 0;
		stress_test_data.last_report_time = cur_time();
		
		if interval > 0 then
			local spawned = 0;
			local batch_size = 10;
			
			if is_valid(ply) then
				chat_print(ply, string_format("[Stress Test] Spawning %d projectiles over %.1fs (%s pattern)", count, interval, pattern));
			end
			
			print(string_format("[Stress Test] Spawning %d projectiles over %.1fs (%s pattern)", count, interval, pattern));
			
			timer_create("pro_stress_spawn", interval / (count / batch_size), count / batch_size, function()
				if not is_valid(ply) then
					timer_remove("pro_stress_spawn");
					
					return;
				end
				
				spawn_projectile_pattern(ply, eye_pos(ply), pattern, batch_size, spread);
				spawned = spawned + batch_size;
				
				if spawned >= count then
					timer_remove("pro_stress_spawn");
					
					if is_valid(ply) then
						chat_print(ply, string_format("[Stress Test] Completed spawning %d projectiles", spawned));
					end
					
					print(string_format("[Stress Test] Completed spawning %d projectiles", spawned));
				end
			end);
		else
			spawn_projectile_pattern(ply, spawn_pos, pattern, count, spread);
			
			if is_valid(ply) then
				chat_print(ply, string_format("[Stress Test] Spawned %d projectiles instantly (%s pattern)", count, pattern));
			end
			
			print(string_format("[Stress Test] Spawned %d projectiles instantly (%s pattern)", count, pattern));
		end
	end, nil, "Spawn projectiles for stress testing. Usage: pro_stress_test <count> <pattern> <interval> <spread>\nPatterns: radial, sphere, cone, forward\nInterval: seconds to spawn over (0 = instant)\nSpread: cone spread radius (0.0-1.0)");
	
	concommand.Add("pro_stress_clear", function(ply, cmd, args)
		if is_valid(ply) and not is_superadmin(ply) then
			chat_print(ply, "You must be a superadmin to use this command.");
			
			return;
		end
		
		local cleared = 0;
		
		for shooter, store in next, projectile_store do
			if store and store.active_projectiles then
				cleared = cleared + #store.active_projectiles;
				store.active_projectiles = {};
			end
		end
		
		stress_test_data.active = false;
		
		if is_valid(ply) then
			chat_print(ply, string_format("[Stress Test] Cleared %d active projectiles", cleared));
		end
		
		print(string_format("[Stress Test] Cleared %d active projectiles", cleared));
	end, nil, "Clear all active projectiles");
	
	concommand.Add("pro_stress_stats", function(ply, cmd, args)
		if is_valid(ply) and not is_superadmin(ply) then
			chat_print(ply, "You must be a superadmin to use this command.");
			
			return;
		end
		
		local active = get_total_active_projectiles();
		local runtime = stress_test_data.active and (sys_time() - stress_test_data.start_time) or 0.0;
		local avg_spawn_rate = runtime > 0.0 and (stress_test_data.total_spawned / runtime) or 0.0;
		
		local tick_rate = 1.0 / engine_tick_interval();
		
		local msg = string_format(
			"[Stress Test Stats]\n" ..
			"Active Projectiles: %d\n" ..
			"Total Spawned: %d\n" ..
			"Runtime: %.2fs\n" ..
			"Avg Spawn Rate: %.1f/s\n" ..
			"Server Tickrate: %.1f",
			active,
			stress_test_data.total_spawned,
			runtime,
			avg_spawn_rate,
			tick_rate
		);
		
		if is_valid(ply) then
			chat_print(ply, msg);
		end
		
		print(msg);
	end, nil, "Show stress test statistics");
	
	hook.Add("Tick", "pro_stress_monitor", function()
		if not stress_test_data.active then return; end
		
		local now = cur_time();
		if now - stress_test_data.last_report_time >= 5.0 then
			stress_test_data.last_report_time = now;
			
			local active = get_total_active_projectiles();
			local runtime = sys_time() - stress_test_data.start_time;
			
			print(string_format("[Stress Test] Active: %d | Spawned: %d | Runtime: %.1fs", 
				active, stress_test_data.total_spawned, runtime));
		end
	end);
end

if CLIENT then
	local draw_simple_text = draw.SimpleText;
	local color_white = color_white;
	local scrw = ScrW;
	local scrh = ScrH;
	local frame_time = FrameTime;
	local local_player = LocalPlayer;
	local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT;
	
	local convar_meta = FindMetaTable("ConVar");
	local get_bool = convar_meta.GetBool;
	
	local cv_debug_hud = CreateClientConVar("pro_debug_hud", "0", true, false, "Show projectile debug HUD");
	
	local function get_total_active_projectiles()
		local total = 0;
		
		for shooter, store in next, projectile_store do
			if store and store.active_projectiles then
				total = total + #store.active_projectiles;
			end
		end
		
		return total;
	end
	
	hook.Add("HUDPaint", "pro_debug_hud", function()
		if not get_bool(cv_debug_hud) then return; end
		
		local x = scrw() - 250;
		local y = 50;
		
		draw_simple_text("ProjectileMod Debug", "DermaDefaultBold", x, y, color_white, TEXT_ALIGN_LEFT);
		y = y + 20;
		
		local active = get_total_active_projectiles();
		draw_simple_text(string_format("Active Projectiles: %d", active), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT);
		y = y + 15;
		
		local fps = 1.0 / frame_time();
		draw_simple_text(string_format("Client FPS: %.1f", fps), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT);
		y = y + 15;
		
		local ping = get_ping(local_player());
		draw_simple_text(string_format("Ping: %dms", ping), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT);
		y = y + 15;
		
		local wind_seed = get_current_wind_seed();
		draw_simple_text(string_format("Wind Seed: %d", wind_seed), "DermaDefault", x, y, color_white, TEXT_ALIGN_LEFT);
	end);
end

print("loaded projectiles debug");
