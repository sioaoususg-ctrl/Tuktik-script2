local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sioaoususg-ctrl/Tuktik-script2/refs/heads/main/Library_v2.lua"))()

Lib.Key({
	Title    = "Tuktik Hub",
	Subtitle = "Example Key System.",
	Key      = "DEMO-KEY-1234",
	-- ถ้าอยากเช็กคีย์ผ่านเซิร์ฟเวอร์ ใช้ Check แทน Key:
	-- Check = function(key) return game:HttpGet("https://your-api/check?key=" .. key) == "valid" end,
	Link     = "https://example.com/getkey",
	Discord  = "dsc.gg/yourserver",
	Website  = "yoursite.com",
	Save     = false, -- ทดสอบ = false / ใช้จริง = true
}, function()
	local w = Lib.new({Title = "Tuktik Hub", Subtitle = "Blox Fruits", Short = "TK"})
	local I = Lib.Icons

	-- ═════ แถบซ้าย: Category + Tab ═════
	w:Category("Main")
	local farm = w:Tab("Farm", I.home)

	-- Section(ชื่อ, ฝั่ง)  ฝั่ง = "Left" / "Right" (ไม่ใส่ = สลับซ้ายขวาอัตโนมัติ)
	local main = farm:Section("Main", "Left")
	main:Toggle({
		Name = "Auto Farm Level", Default = false, Flag = "autofarm",
		Callback = function(on)
			Lib.Notify({Title = "Auto Farm", Content = on and "Enabled" or "Disabled", Type = on and "success" or "warn"})
		end,
	})
	main:Toggle({
		Name = "Auto Collect", Desc = "Collects nearby drops", Default = true, Flag = "autocollect",
		Callback = function(on) Lib.Notify({Title = "Auto Collect", Content = on and "ON" or "OFF"}) end,
	})
	main:Slider({
		Name = "Tween Speed", Min = 50, Max = 500, Default = 350, Increment = 10, Flag = "speed",
		OnRelease = function(v) Lib.Notify({Title = "Slider", Content = "Tween Speed = " .. v}) end,
	})
	main:Slider({
		Name = "Field of View", Min = 0, Max = 100, Default = 100, Suffix = "%", Flag = "fov",
	})

	local sel = farm:Section("Selection", "Left")
	sel:Dropdown({
		Name = "Mode", Options = {"Near", "Far", "Random"}, Default = "Near", Flag = "mode",
		Callback = function(v) Lib.Notify({Title = "Dropdown", Content = "Mode = " .. v}) end,
	})
	sel:MultiDropdown({
		Name = "Targets", Options = {"Red", "Green", "Blue", "Yellow"}, Default = {"Red"}, Flag = "targets",
		Callback = function(list)
			Lib.Notify({Title = "Targets", Content = #list == 0 and "None" or table.concat(list, ", ")})
		end,
	})

	local other = farm:Section("Other", "Right")
	other:Toggle({Name = "Auto Stats", Flag = "autostats"})
	other:Toggle({Name = "Anti AFK", Default = true, Flag = "antiafk"})
	other:Textbox({Name = "Webhook", Placeholder = "paste url", Flag = "webhook"})
	other:Button({
		Name = "Stop All Tween", Desc = "Cancels every running tween",
		Callback = function() Lib.Notify({Title = "Button", Content = "Stopped", Type = "success"}) end,
	})

	-- ═════ Notify test ═════
	local nt = w:Tab("Notify", I.discord)
	local n1 = nt:Section("Notify Test", "Left")
	n1:Button({Name = "Info",    Callback = function() Lib.Notify({Title = "Info",    Content = "Info message",   Type = "info"}) end})
	n1:Button({Name = "Success", Callback = function() Lib.Notify({Title = "Success", Content = "It worked",      Type = "success"}) end})
	n1:Button({Name = "Warning", Callback = function() Lib.Notify({Title = "Warning", Content = "Be careful",     Type = "warn"}) end})
	n1:Button({Name = "Error",   Callback = function() Lib.Notify({Title = "Error",   Content = "Something broke", Type = "error"}) end})
	local n2 = nt:Section("Limit", "Right")
	n2:Button({Name = "Spam x6", Desc = "Shows at most 4 at once", Callback = function()
		for i = 1, 6 do Lib.Notify({Title = "Notify " .. i, Content = "Older ones disappear first", Duration = 5}) end
	end})

	-- ═════ Settings ═════
	w:Category("Misc")
	local set = w:Tab("Settings", I.settings)
	local ui = set:Section("Interface", "Left")
	ui:Slider({
		Name = "Notify duration", Min = 1, Max = 10, Default = Lib.NotifyDuration, Suffix = "s",
		Callback = function(v) Lib.NotifyDuration = v end,
	})
	ui:Button({Name = "Destroy UI", Callback = function() w:Destroy() end})

	local cfg = set:Section("Config", "Right")
	cfg:Button({Name = "Save config", Desc = "Saves every control that has a Flag", Callback = function()
		local ok = w:SaveConfig("default")
		Lib.Notify({Title = "Config", Content = ok and "Saved" or "Save failed", Type = ok and "success" or "error"})
	end})
	cfg:Button({Name = "Load config", Callback = function()
		local ok = w:LoadConfig("default")
		Lib.Notify({Title = "Config", Content = ok and "Loaded" or "No config found", Type = ok and "success" or "warn"})
	end})

	Lib.Notify({Title = "Loaded", Content = "Welcome " .. game.Players.LocalPlayer.DisplayName, Type = "success"})
end)
