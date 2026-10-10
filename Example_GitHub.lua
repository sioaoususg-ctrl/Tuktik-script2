local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sioaoususg-ctrl/Tuktik-script2/refs/heads/main/Library_v2.lua"))()

Lib.Key({
	Title   = "Tuktik Hub",
	Key     = "DEMO-KEY-1234",
	Link    = "https://example.com/getkey",
	Discord = "dsc.gg/yourserver",
	Website = "yoursite.com",
	Save    = false, -- ทดสอบ = false / ใช้จริง = true
}, function()
	local w = Lib.new({Title = "Tuktik Hub", By = "by tuktik"})
	local I = Lib.Icons

	-- ═════ Farm ═════
	local farm = w:Tab("Farm", I.home)

	farm:Section("Farm")
	farm:Toggle({
		Name = "Auto Farm Level", Desc = "Automatically farms the nearest quest enemies",
		Default = false, Flag = "autofarm",
		Callback = function(on)
			Lib.Notify({Title = "Auto Farm", Content = on and "Enabled" or "Disabled", Type = on and "success" or "warn"})
		end,
	})
	farm:Toggle({
		Name = "Auto Collect", Desc = "Collects nearby drops",
		Default = true, Flag = "autocollect",
		Callback = function(on) Lib.Notify({Title = "Auto Collect", Content = on and "ON" or "OFF"}) end,
	})
	farm:Slider({
		Name = "Tween Speed", Desc = "Higher = faster but riskier",
		Min = 50, Max = 500, Default = 350, Increment = 10, Flag = "speed",
		OnRelease = function(v) Lib.Notify({Title = "Slider", Content = "Tween Speed = " .. v}) end,
	})
	farm:Dropdown({
		Name = "Mode", Options = {"Near", "Far", "Random"}, Default = "Near", Flag = "mode",
		Callback = function(v) Lib.Notify({Title = "Dropdown", Content = "Mode = " .. v}) end,
	})
	farm:MultiDropdown({
		Name = "Targets", Desc = "Pick as many as you like",
		Options = {"Red", "Green", "Blue", "Yellow"}, Default = {"Red"}, Flag = "targets",
		Callback = function(list)
			Lib.Notify({Title = "Targets", Content = #list == 0 and "None" or table.concat(list, ", ")})
		end,
	})
	farm:Button({
		Name = "Stop All Tween", Desc = "Cancels every running tween",
		Callback = function() Lib.Notify({Title = "Button", Content = "Stopped", Type = "success"}) end,
	})

	-- ═════ Notify ═════
	local nt = w:Tab("Notify", I.discord)
	nt:Section("Notify Test")
	nt:Button({Name = "Info",    Callback = function() Lib.Notify({Title = "Info",    Content = "Info message",   Type = "info"}) end})
	nt:Button({Name = "Success", Callback = function() Lib.Notify({Title = "Success", Content = "It worked",      Type = "success"}) end})
	nt:Button({Name = "Warning", Callback = function() Lib.Notify({Title = "Warning", Content = "Be careful",     Type = "warn"}) end})
	nt:Button({Name = "Error",   Callback = function() Lib.Notify({Title = "Error",   Content = "Something broke", Type = "error"}) end})

	-- ═════ Settings ═════
	local set = w:Tab("Settings", I.settings)
	set:Section("Interface")
	set:Slider({
		Name = "Notify duration (s)", Min = 1, Max = 10, Default = Lib.NotifyDuration,
		Callback = function(v) Lib.NotifyDuration = v end,
	})

	set:Section("Config")
	set:Button({Name = "Save config", Desc = "Saves every control that has a Flag", Callback = function()
		local ok = w:SaveConfig("default")
		Lib.Notify({Title = "Config", Content = ok and "Saved" or "Save failed", Type = ok and "success" or "error"})
	end})
	set:Button({Name = "Load config", Callback = function()
		local ok = w:LoadConfig("default")
		Lib.Notify({Title = "Config", Content = ok and "Loaded" or "No config found", Type = ok and "success" or "warn"})
	end})
	set:Button({Name = "Destroy UI", Callback = function() w:Destroy() end})

	Lib.Notify({Title = "Loaded", Content = "Welcome " .. game.Players.LocalPlayer.DisplayName, Type = "success"})
end)
