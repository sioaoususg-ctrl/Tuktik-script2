--[[
	UI Library v2.1 (personal / open source) - sidebar style
	License: MIT

	local Lib = loadstring(game:HttpGet("RAW_URL/Library_v2.lua"))()
	local w   = Lib.new({Title = "My Hub", By = "by me"})
	local tab = w:Tab("Farm", Lib.Icons.home)
	tab:Section("Farm")
	tab:Toggle({Name = "Auto Farm", Desc = "คำอธิบาย", Default = false, Flag = "farm", Callback = function(v) end})
]]

local UIS, TS = game:GetService("UserInputService"), game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local C = {bg=Color3.fromRGB(16,17,22), sec=Color3.fromRGB(24,25,33), el=Color3.fromRGB(34,36,47), st=Color3.fromRGB(46,48,62),
	tx=Color3.fromRGB(236,238,245), sub=Color3.fromRGB(140,145,166), ac=Color3.fromRGB(86,120,255),
	green=Color3.fromRGB(46,204,113), gray=Color3.fromRGB(95,97,110),
	red=Color3.fromRGB(235,87,87), orange=Color3.fromRGB(230,170,90)}
local Left, Right, Center = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center
local AutoY = Enum.AutomaticSize.Y
local WHITE = Color3.new(1,1,1)

-- ═════════ ICONS ═════════
local USE_THUMB = true
local function asset(id)
	if USE_THUMB then return "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150" end
	return "rbxassetid://" .. id
end
local ICON = {
	discord   = asset(7948857513),
	web       = asset(11395780614),
	home      = asset(279461711),
	key       = asset(10871266127),
	tick      = asset(14203226683),
	arrowUp   = asset(112965684250711),
	arrowDown = asset(84586195270945),
	close     = asset(10152135074),
	clip      = asset(12804017070),
	expand    = asset(130953299674533), -- ไอคอนขยาย (ใหม่)
	settings  = asset(7059346386),
	exit      = asset(9405925538),      -- ปุ่ม Exit หน้า Key
}

-- ═════════ HELPERS ═════════
local function N(c, p, ch)
	local i = Instance.new(c)
	for k, v in pairs(p or {}) do if k ~= "Parent" then i[k] = v end end
	for _, x in ipairs(ch or {}) do x.Parent = i end
	i.Parent = p and p.Parent
	return i
end
local function R(r) return N("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function Round() return N("UICorner", {CornerRadius = UDim.new(1, 0)}) end
local function S() return N("UIStroke", {Color = C.st, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function T(i, p, d) TS:Create(i, TweenInfo.new(d or .15), p):Play() end
local function L(p)
	p.BackgroundTransparency = 1
	p.TextColor3 = p.TextColor3 or C.tx
	p.Font = p.Font or Enum.Font.GothamMedium
	p.TextSize = p.TextSize or 13
	p.TextXAlignment = p.TextXAlignment or Left
	return N("TextLabel", p)
end
local function Ic(p)
	p.BackgroundTransparency = 1
	p.ScaleType = Enum.ScaleType.Fit
	return N("ImageLabel", p)
end
local function press(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function move(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function pad(l, t, r, b) return N("UIPadding", {PaddingLeft = UDim.new(0,l), PaddingTop = UDim.new(0,t), PaddingRight = UDim.new(0,r), PaddingBottom = UDim.new(0,b)}) end
local function list(p) return N("UIListLayout", {Padding = UDim.new(0, p or 6), SortOrder = Enum.SortOrder.LayoutOrder}) end

-- press effect (base เป็นสี หรือฟังก์ชันที่คืนสีปัจจุบัน)
local function fx(b, base)
	local function B() if type(base) == "function" then return base() end return base end
	local sc = N("UIScale", {Parent = b})
	b.MouseButton1Down:Connect(function() T(b, {BackgroundColor3 = C.gray}); T(sc, {Scale = .97}) end)
	local function up() T(b, {BackgroundColor3 = B()}); T(sc, {Scale = 1}) end
	b.MouseButton1Up:Connect(function() task.delay(.12, up) end)
	b.MouseLeave:Connect(up)
end

local function mount()
	local g = N("ScreenGui", {Name = "UI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not g.Parent then g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	return g
end

-- drag: เก็บ connection ลง conns เพื่อ disconnect ตอนปิด UI
local function drag(h, f, conns)
	local d, ds, sp
	local function add(c) if conns then table.insert(conns, c) end end
	h.InputBegan:Connect(function(i) if press(i) then d, ds, sp = true, i.Position, f.Position end end)
	add(UIS.InputChanged:Connect(function(i)
		if d and move(i) then
			local v = i.Position - ds
			f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + v.X, sp.Y.Scale, sp.Y.Offset + v.Y)
		end
	end))
	add(UIS.InputEnded:Connect(function(i) if press(i) then d = false end end))
end

local function copy(t) if setclipboard then pcall(setclipboard, t) end end

local Lib = {Icons = ICON, Colors = C, NotifyDuration = 4}

-- ═════════════════ NOTIFY (modern / compact) ═════════════════
-- Lib.Notify({Title=, Content=, Type="info"|"success"|"warn"|"error", Duration=})
-- - ขนาดการ์ดปรับตามข้อความ, มีปุ่ม X ปิด
-- - แสดงสูงสุด 4 อัน (อันเก่าสุดหายก่อน), ข้อความซ้ำจะไม่ซ้อนกัน
local NOTIF = {
	info    = {C.ac,     "i"},
	success = {C.green,  nil, "tick"},
	warn    = {C.orange, "!"},
	error   = {C.red,    nil, "close"},
}
local MAX_NOTIFY = 4
local notifGui, notifHolder, nCount, activeN = nil, nil, 0, {}

local function holder()
	if notifHolder and notifHolder.Parent then return notifHolder end
	notifGui = mount()
	notifGui.Name = "UINotify"
	notifGui.DisplayOrder = 1000
	notifHolder = N("Frame", {
		AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-16,1,-16),
		Size = UDim2.new(0,270,1,-32), BackgroundTransparency = 1, Parent = notifGui,
	}, {N("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom})})
	return notifHolder
end

function Lib.Notify(o)
	if type(o) == "string" then o = {Content = o} end
	local info = NOTIF[o.Type] or NOTIF.info
	local col = info[1]
	local dur = o.Duration or Lib.NotifyDuration
	local key = (o.Title or "") .. "|" .. (o.Content or "")

	-- กันรก: ลบอันซ้ำ และจำกัดจำนวน
	for i = #activeN, 1, -1 do if activeN[i].key == key then activeN[i].kill() end end
	while #activeN >= MAX_NOTIFY do activeN[1].kill() end
	nCount += 1

	local slot = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = nCount, Parent = holder()})
	local card = N("Frame", {Position = UDim2.new(1.2,0,0,0), Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundColor3 = C.sec, ClipsDescendants = true, Parent = slot}, {R(8), S()})

	-- แถบสีด้านซ้าย
	N("Frame", {Size = UDim2.new(0,3,1,0), BackgroundColor3 = col, BorderSizePixel = 0, Parent = card})

	-- ไอคอน
	local circ = N("Frame", {Position = UDim2.fromOffset(14,10), Size = UDim2.fromOffset(22,22), BackgroundColor3 = col, BackgroundTransparency = .82, Parent = card}, {Round()})
	if info[3] then
		Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(12,12), Image = ICON[info[3]], ImageColor3 = col, Parent = circ})
	else
		L({Size = UDim2.fromScale(1,1), Text = info[2], Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = col, TextXAlignment = Center, Parent = circ})
	end

	-- ข้อความ
	local tx = N("Frame", {Position = UDim2.fromOffset(44,0), Size = UDim2.new(1,-76,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = card}, {pad(0,10,0,12), list(2)})
	L({Size = UDim2.new(1,0,0,16), Text = o.Title or "Notification", Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, Parent = tx})
	if o.Content and o.Content ~= "" then
		L({Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, Text = o.Content, TextColor3 = C.sub, TextSize = 12, TextWrapped = true, LayoutOrder = 2, Parent = tx})
	end

	-- หลอดเวลา (บางๆ ด้านล่าง)
	local track = N("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.fromScale(0,1), Size = UDim2.new(1,0,0,2), BackgroundColor3 = C.el, BorderSizePixel = 0, Parent = card})
	local fill = N("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = col, BorderSizePixel = 0, Parent = track})

	local dead = false
	local entry = {key = key}
	local function remove(instant)
		if dead then return end
		dead = true
		for i, e in ipairs(activeN) do if e == entry then table.remove(activeN, i) break end end
		if instant then slot:Destroy() return end
		TS:Create(card, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.2,0,0,0)}):Play()
		task.wait(.25)
		local h = slot.AbsoluteSize.Y
		slot.AutomaticSize = Enum.AutomaticSize.None
		slot.Size = UDim2.new(1,0,0,h)
		local t = TS:Create(slot, TweenInfo.new(.18), {Size = UDim2.new(1,0,0,0)})
		t:Play(); t.Completed:Wait()
		slot:Destroy()
	end
	entry.kill = function() remove(true) end
	table.insert(activeN, entry)

	-- ปุ่ม X ปิด
	local xb = N("TextButton", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-8,0,8), Size = UDim2.fromOffset(20,20), BackgroundColor3 = C.el, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = card}, {Round()})
	local xi = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(10,10), Image = ICON.close, ImageColor3 = C.sub, Parent = xb})
	xb.MouseEnter:Connect(function() T(xb, {BackgroundTransparency = 0}); T(xi, {ImageColor3 = C.tx}) end)
	xb.MouseLeave:Connect(function() T(xb, {BackgroundTransparency = 1}); T(xi, {ImageColor3 = C.sub}) end)
	xb.MouseButton1Click:Connect(function() task.spawn(remove) end)

	TS:Create(card, TweenInfo.new(.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
	TS:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0,0,1,0)}):Play()
	task.delay(dur, function() remove() end)
	return function() task.spawn(remove) end
end

-- ═════════════════ KEY SYSTEM (card style) ═════════════════
-- Lib.Key({Title=, Subtitle=, Logo=, Key=, Check=function(key) return bool end,
--          Link=, Discord=, Website=, Save=true/false, File=, OnExit=function()}, onSuccess)
function Lib.Key(o, onOk)
	local file = o.File or "uilib_key.txt"
	local save = o.Save ~= false
	local function valid(k)
		if o.Check then
			local ok, res = pcall(o.Check, k)
			return ok and res == true
		end
		return k == o.Key
	end

	if save then
		local okr, saved = pcall(readfile, file)
		if okr and valid(saved) then return onOk() end
	else
		pcall(function() delfile(file) end)
	end

	local kc = {}
	local gui = mount()
	local lp = Players.LocalPlayer
	local f = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(460,292), BackgroundColor3 = WHITE, Active = true, Parent = gui},
		{R(16), S(), N("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(25,27,40), Color3.fromRGB(13,14,19)), Rotation = 90})})
	local pop = N("UIScale", {Scale = .9, Parent = f})
	TS:Create(pop, TweenInfo.new(.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	drag(f, f, kc)

	local function closeKey()
		for _, c in ipairs(kc) do c:Disconnect() end
		gui:Destroy()
	end

	-- ═════ header: โลโก้ + ชื่อ (ซ้าย) / โลโก้แมพ + ชื่อแมพ + ชื่อผู้เล่น (ขวา) ═════
	local lg = N("Frame", {Position = UDim2.fromOffset(20,18), Size = UDim2.fromOffset(40,40), BackgroundColor3 = C.ac, BackgroundTransparency = .8, Parent = f}, {R(11)})
	local lgs = S(); lgs.Color = C.ac; lgs.Transparency = .55; lgs.Parent = lg
	if o.Logo and o.Logo ~= "" then
		Ic({Size = UDim2.fromScale(1,1), Image = o.Logo, Parent = lg})
	else
		Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(20,20), Image = ICON.key, ImageColor3 = C.ac, Parent = lg})
	end
	L({Position = UDim2.fromOffset(70,18), Size = UDim2.new(1,-270,0,22), Text = o.Title or "Hub", Font = Enum.Font.GothamBold, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
	L({Position = UDim2.fromOffset(70,41), Size = UDim2.new(1,-270,0,16), Text = o.Subtitle or "Key System", TextColor3 = C.sub, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})

	local chip = N("Frame", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-20,0,18), Size = UDim2.fromOffset(172,40), BackgroundColor3 = C.sec, Parent = f}, {R(10), S()})
	N("ImageLabel", {Position = UDim2.fromOffset(6,6), Size = UDim2.fromOffset(28,28), BackgroundColor3 = C.el, Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Parent = chip}, {R(7)})
	local gl = L({Position = UDim2.fromOffset(42,4), Size = UDim2.new(1,-48,0,16), Text = o.Game or "Loading...", Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = chip})
	L({Position = UDim2.fromOffset(42,20), Size = UDim2.new(1,-48,0,14), Text = "Playing as " .. lp.DisplayName, TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = chip})
	if not o.Game then
		task.spawn(function()
			local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
			if gl.Parent then gl.Text = ok and info.Name or "Unknown game" end
		end)
	end

	N("Frame", {Position = UDim2.fromOffset(20,70), Size = UDim2.fromOffset(420,1), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = f})

	-- ═════ input: ไอคอนอยู่นอก TextBox (ไม่โดน padding ดันทับข้อความ) ═════
	local ws = S()
	local wrap = N("Frame", {Position = UDim2.fromOffset(20,84), Size = UDim2.fromOffset(420,44), BackgroundColor3 = C.sec, Parent = f}, {R(10), ws})
	local kic = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,14,.5,0), Size = UDim2.fromOffset(16,16), Image = ICON.key, ImageColor3 = C.sub, Parent = wrap})
	local box = N("TextBox", {Position = UDim2.fromOffset(44,0), Size = UDim2.new(1,-58,1,0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter Key", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Left, ClearTextOnFocus = false, ClipsDescendants = true, Parent = wrap})
	box.Focused:Connect(function() T(ws, {Color = C.ac}); T(kic, {ImageColor3 = C.ac}) end)
	box.FocusLost:Connect(function() T(ws, {Color = C.st}); T(kic, {ImageColor3 = C.sub}) end)

	local msg = L({Position = UDim2.fromOffset(22,134), Size = UDim2.fromOffset(416,16), Text = "Enter your key to continue", TextColor3 = C.sub, TextSize = 11, Parent = f})

	-- ═════ ปุ่ม (ไอคอนอยู่ซ้ายข้อความ กึ่งกลางปุ่ม) ═════
	local function btn(x, y, w, h, text, base, tc, icon)
		local b = N("TextButton", {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h), BackgroundColor3 = type(base) == "function" and base() or base, Text = "      " .. text, TextColor3 = tc, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, Parent = f}, {R(10), S()})
		local tb = game:GetService("TextService"):GetTextSize(b.Text, 13, Enum.Font.GothamBold, Vector2.new(1000, 100))
		local ico = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(.5, -tb.X/2, .5, 0), Size = UDim2.fromOffset(16,16), Image = icon, ImageColor3 = tc, Parent = b})
		fx(b, base)
		return b, ico
	end

	local ready = false
	local exitB  = btn(20, 158, 104, 42, "Exit", C.sec, C.tx, ICON.exit)
	local getkey = btn(132, 158, 128, 42, "Get key", C.sec, C.tx, ICON.key)
	local submit, subIc = btn(268, 158, 172, 42, "Submit", function() return ready and C.ac or C.el end, C.sub, ICON.tick)
	local dcB    = btn(20, 208, 206, 38, "Discord", C.sec, C.tx, ICON.discord)
	local webB   = btn(234, 208, 206, 38, "Website", C.sec, C.tx, ICON.web)

	L({Position = UDim2.fromOffset(22,262), Size = UDim2.fromOffset(416,16), Text = save and "Your key is saved, you only enter it once" or "Key is not saved (test mode)", TextColor3 = C.sub, TextSize = 11, Parent = f})

	-- Submit: เทาตอนยังไม่กรอก / สีหลักตอนมีข้อความ
	local function refresh()
		ready = (box.Text:gsub("%s", "")) ~= ""
		T(submit, {BackgroundColor3 = ready and C.ac or C.el, TextColor3 = ready and WHITE or C.sub})
		T(subIc, {ImageColor3 = ready and WHITE or C.sub})
	end
	box:GetPropertyChangedSignal("Text"):Connect(refresh)

	exitB.MouseButton1Click:Connect(function()
		closeKey()
		if o.OnExit then o.OnExit() end
	end)

	getkey.MouseButton1Click:Connect(function()
		if o.Link and o.Link ~= "" then
			copy(o.Link)
			msg.Text, msg.TextColor3 = "Key link copied to clipboard", C.ac
			Lib.Notify({Title = "Get key", Content = "Key link copied to clipboard", Type = "success", Duration = 2.5})
		else
			Lib.Notify({Title = "Get key", Content = "No key link has been set", Type = "warn", Duration = 2.5})
		end
	end)
	dcB.MouseButton1Click:Connect(function()
		copy(o.Discord or "dsc.gg/yourserver")
		Lib.Notify({Title = "Discord", Content = "Invite link copied", Type = "success", Duration = 2.5})
	end)
	webB.MouseButton1Click:Connect(function()
		copy(o.Website or "yoursite.com")
		Lib.Notify({Title = "Website", Content = "Link copied", Type = "success", Duration = 2.5})
	end)

	local busy = false
	local function submitKey()
		if busy then return end
		local k = (box.Text:gsub("%s", ""))
		if k == "" then
			msg.Text, msg.TextColor3 = "Please enter your key", C.orange
			return
		end
		busy = true
		msg.Text, msg.TextColor3 = "Checking...", C.sub
		if valid(k) then
			msg.Text, msg.TextColor3 = "Key accepted", C.green
			Lib.Notify({Title = "Key accepted", Content = "Loading interface...", Type = "success"})
			if save then pcall(writefile, file, k) end
			task.wait(.4)
			TS:Create(pop, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = .9}):Play()
			task.wait(.2)
			closeKey()
			onOk()
		else
			msg.Text, msg.TextColor3 = "Wrong key, try again", C.red
			Lib.Notify({Title = "Invalid key", Content = "The key you entered is wrong", Type = "error"})
			busy = false
		end
	end
	submit.MouseButton1Click:Connect(submitKey)
	box.FocusLost:Connect(function(enter) if enter then submitKey() end end)
end

-- ═════════════════ MAIN UI (v2 sidebar) ═════════════════
-- Lib.new({Title=, By=, Logo=, Size=UDim2})  หรือ Lib.new("Title")
function Lib.new(opts, logo)
	if type(opts) ~= "table" then opts = {Title = opts, Logo = logo} end
	local title = opts.Title or "Hub"

	local gui = mount()
	local lp = Players.LocalPlayer
	local conns = {}
	local function bind(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

	local TOP, SW = 38, 132
	local FULL = opts.Size or UDim2.fromOffset(580, 340)
	local MINI = UDim2.new(FULL.X.Scale, FULL.X.Offset, 0, TOP)

	local main = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = FULL, BackgroundColor3 = C.bg, Active = true, ClipsDescendants = true, Parent = gui}, {R(10), S()})
	local top = N("Frame", {Size = UDim2.new(1,0,0,TOP), BackgroundTransparency = 1, Parent = main})
	N("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.fromScale(0,1), Size = UDim2.new(1,0,0,1), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = top})
	drag(top, main, conns)

	-- title row: [logo] Title  by xxx
	local row = N("Frame", {Position = UDim2.fromOffset(12,0), Size = UDim2.new(1,-100,1,0), BackgroundTransparency = 1, Parent = top},
		{N("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})})
	if opts.Logo and opts.Logo ~= "" then
		Ic({Size = UDim2.fromOffset(22,22), Image = opts.Logo, LayoutOrder = 0, Parent = row})
	end
	L({Size = UDim2.new(0,0,0,20), AutomaticSize = Enum.AutomaticSize.X, Text = title, Font = Enum.Font.GothamBold, LayoutOrder = 1, Parent = row})
	if opts.By then
		L({Size = UDim2.new(0,0,0,20), AutomaticSize = Enum.AutomaticSize.X, Text = opts.By, TextColor3 = C.sub, TextSize = 10, LayoutOrder = 2, Parent = row})
	end

	-- ปุ่มปิด / ย่อ (วงกลม)  ย่อ=ซ้าย  ปิด=ขวา
	local closeB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(24,24), BackgroundColor3 = C.el, Text = "", AutoButtonColor = false, Parent = top}, {Round(), S()})
	Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(11,11), Image = ICON.close, ImageColor3 = C.tx, Parent = closeB})
	fx(closeB, C.el)
	local miniB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-40,.5,0), Size = UDim2.fromOffset(24,24), BackgroundColor3 = C.el, Text = "-", TextColor3 = C.tx, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, Parent = top}, {Round(), S()})
	local expIc = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(12,12), Image = ICON.expand, ImageColor3 = C.tx, Visible = false, Parent = miniB})
	fx(miniB, C.el)

	-- body = sidebar + content
	local body = N("Frame", {Position = UDim2.fromOffset(0,TOP), Size = UDim2.new(1,0,1,-TOP), BackgroundTransparency = 1, Parent = main})
	N("Frame", {Position = UDim2.fromOffset(SW,0), Size = UDim2.new(0,1,1,0), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = body})
	local tabList = N("ScrollingFrame", {Size = UDim2.new(0,SW,1,-54), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = AutoY, CanvasSize = UDim2.new(), Parent = body}, {pad(8,8,8,4), list(2)})
	local content = N("Frame", {Position = UDim2.fromOffset(SW+1,0), Size = UDim2.new(1,-(SW+1),1,0), BackgroundTransparency = 1, Parent = body})

	-- profile (รูปวงกลม + ชื่อเล่น + ชื่อจริง)
	local foot = N("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,8,1,-8), Size = UDim2.fromOffset(SW-16,38), BackgroundColor3 = C.sec, Parent = body}, {R(8), S()})
	local av = N("ImageLabel", {Position = UDim2.fromOffset(5,6), Size = UDim2.fromOffset(26,26), BackgroundColor3 = C.el, Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150", Parent = foot}, {Round()})
	local ring = S(); ring.Color = C.ac; ring.Thickness = 1.5; ring.Parent = av
	L({Position = UDim2.fromOffset(37,4), Size = UDim2.new(1,-41,0,16), Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})
	L({Position = UDim2.fromOffset(37,19), Size = UDim2.new(1,-41,0,14), Text = "@" .. lp.Name, TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})

	-- minimize
	local mini = false
	local function setMini(v)
		mini = v
		miniB.Text = v and "" or "-"
		expIc.Visible = v
		if v then
			local tw = TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = MINI})
			tw.Completed:Connect(function() if mini then body.Visible = false end end)
			tw:Play()
		else
			body.Visible = true
			TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = FULL}):Play()
		end
	end
	miniB.MouseButton1Click:Connect(function() setMini(not mini) end)

	bind(UIS.InputBegan, function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end end)
	local function destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		gui:Destroy()
	end
	closeB.MouseButton1Click:Connect(destroy)

	-- ═════ Flags / Config ═════
	local Flags = {}
	local function reg(flag, obj) if flag then Flags[flag] = obj end end

	local W, tabs = {Flags = Flags}, {}
	function W:Destroy() destroy() end
	function W:Notify(o) return Lib.Notify(o) end
	function W:SaveConfig(name)
		local data = {}
		for k, o in pairs(Flags) do data[k] = o:Get() end
		pcall(function() if makefolder and not isfolder("UILib") then makefolder("UILib") end end)
		return (pcall(function() writefile("UILib/" .. name .. ".json", HttpService:JSONEncode(data)) end))
	end
	function W:LoadConfig(name)
		local ok, raw = pcall(readfile, "UILib/" .. name .. ".json")
		if not ok then return false end
		local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok2 then return false end
		for k, v in pairs(data) do
			if Flags[k] then pcall(function() Flags[k]:Set(v) end) end
		end
		return true
	end

	-- ═════ Card: การ์ดรายการ (ชื่อ + คำอธิบาย) ═════
	local function Card(parent, name, desc, o)
		o = o or {}
		local props = {Size = UDim2.new(1,0,0,36), AutomaticSize = AutoY, BackgroundColor3 = C.sec, Parent = parent}
		if o.click then props.Text = ""; props.AutoButtonColor = false end
		local c = N(o.click and "TextButton" or "Frame", props, {R(6), S()})
		local t = N("Frame", {Size = o.full and UDim2.new(1,0,0,0) or UDim2.new(1,-(o.rw or 70),0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = c},
			{list(2), pad(10, 8, o.full and 10 or 0, 8)})
		L({Size = UDim2.new(1, o.full and -(o.tw or 60) or 0, 0, 16), Text = name or "", Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, Parent = t})
		if desc and desc ~= "" then
			L({Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, Text = desc, TextColor3 = C.sub, TextSize = 11, TextWrapped = true, LayoutOrder = 2, Parent = t})
		end
		if o.click then fx(c, C.sec) end
		return c, t
	end

	-- ═════ Tab ═════
	function W:Tab(name, icon)
		local b = N("TextButton", {Size = UDim2.new(1,0,0,30), BackgroundColor3 = C.el, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = #tabs + 1, Parent = tabList}, {R(6)})
		local ic, tx = nil, 10
		if icon then
			ic = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,8,.5,0), Size = UDim2.fromOffset(14,14), Image = icon, ImageColor3 = C.sub, Parent = b})
			tx = 30
		end
		local lb = L({Position = UDim2.fromOffset(tx,0), Size = UDim2.new(1,-tx-6,1,0), Text = name, TextColor3 = C.sub, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b})

		local page = N("ScrollingFrame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.st, AutomaticCanvasSize = AutoY, CanvasSize = UDim2.new(), Visible = false, Parent = content}, {pad(10,8,10,10), list(6)})

		local t = {b = b, lb = lb, ic = ic, page = page}
		table.insert(tabs, t)
		local function sel()
			for _, x in ipairs(tabs) do
				local on = (x == t)
				x.page.Visible = on
				T(x.b, {BackgroundTransparency = on and 0 or 1})
				T(x.lb, {TextColor3 = on and C.tx or C.sub})
				if x.ic then T(x.ic, {ImageColor3 = on and C.tx or C.sub}) end
			end
		end
		b.MouseButton1Click:Connect(sel)
		if #tabs == 1 then sel() end

		local order = 0
		local function add(el) order += 1; el.LayoutOrder = order; return el end

		local Tb = {}

		-- Section(name) : หัวข้อ
		function Tb:Section(text)
			add(L({Size = UDim2.new(1,0,0,24), Text = text, Font = Enum.Font.GothamBold, TextSize = 15, Parent = page}))
		end

		-- Label(text) : ข้อความธรรมดา  -> {Set}
		function Tb:Label(text)
			local lb2 = add(L({Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, Text = text, TextColor3 = C.sub, TextSize = 12, TextWrapped = true, Parent = page}))
			return {Set = function(_, v) lb2.Text = v end}
		end

		-- Toggle({Name, Desc, Default, Flag, Callback})  -> {Set, Get}
		function Tb:Toggle(o)
			o = o or {}
			local on = o.Default == true
			local c = Card(page, o.Name or "Toggle", o.Desc, {click = true})
			add(c)
			local pill = N("Frame", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(36,18), BackgroundColor3 = C.el, Parent = c}, {Round()})
			local ps = S(); ps.Parent = pill
			local knob = N("Frame", {AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,3,.5,0), Size = UDim2.fromOffset(12,12), BackgroundColor3 = C.sub, Parent = pill}, {Round()})
			local function render(instant)
				local g1 = {BackgroundColor3 = on and C.ac or C.el}
				local g2 = {Position = on and UDim2.new(0,21,.5,0) or UDim2.new(0,3,.5,0), BackgroundColor3 = on and WHITE or C.sub}
				local g3 = {Color = on and C.ac or C.st}
				if instant then
					for k, v in pairs(g1) do pill[k] = v end
					for k, v in pairs(g2) do knob[k] = v end
					for k, v in pairs(g3) do ps[k] = v end
				else
					T(pill, g1); T(knob, g2); T(ps, g3)
				end
			end
			render(true)
			local obj = {}
			function obj:Set(v, silent)
				on = v and true or false
				render()
				if o.Callback and not silent then o.Callback(on) end
			end
			function obj:Get() return on end
			c.MouseButton1Click:Connect(function() obj:Set(not on) end)
			reg(o.Flag, obj)
			return obj
		end

		-- Button({Name, Desc, Callback})
		function Tb:Button(o)
			o = o or {}
			local c = Card(page, o.Name or "Button", o.Desc, {click = true})
			add(c)
			Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-12,.5,0), Size = UDim2.fromOffset(16,16), Image = ICON.clip, ImageColor3 = C.sub, Parent = c})
			c.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
		end

		-- Slider({Name, Desc, Min, Max, Default, Increment, Flag, Callback, OnRelease}) -> {Set, Get}
		function Tb:Slider(o)
			o = o or {}
			local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
			local val = math.clamp(o.Default or min, min, max)
			local c, t2 = Card(page, o.Name or "Slider", o.Desc, {full = true, tw = 60})
			add(c)
			local vl = L({AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-10,0,8), Size = UDim2.fromOffset(56,16), Text = tostring(val), TextColor3 = C.sub, TextXAlignment = Right, Parent = c})
			local hold = N("Frame", {Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1, LayoutOrder = 3, Parent = t2})
			local sb = N("Frame", {AnchorPoint = Vector2.new(0,.5), Position = UDim2.fromScale(0,.5), Size = UDim2.new(1,0,0,6), BackgroundColor3 = C.el, Parent = hold}, {R(3)})
			local fl = N("Frame", {Size = UDim2.fromScale(0,1), BackgroundColor3 = C.ac, Parent = sb}, {R(3)})
			local function render()
				local a = max > min and (val - min) / (max - min) or 0
				fl.Size = UDim2.fromScale(a, 1)
				vl.Text = tostring(val)
			end
			render()
			local function norm(v)
				v = math.clamp(math.floor(v / inc + .5) * inc, min, max)
				return math.floor(v * 10000 + .5) / 10000
			end
			local obj = {}
			function obj:Set(v, silent)
				val = norm(tonumber(v) or min)
				render()
				if o.Callback and not silent then o.Callback(val) end
			end
			function obj:Get() return val end
			local dr = false
			local function fromX(x)
				local a = math.clamp((x - sb.AbsolutePosition.X) / math.max(sb.AbsoluteSize.X, 1), 0, 1)
				local v = norm(min + (max - min) * a)
				if v ~= val then obj:Set(v) end
			end
			N("TextButton", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", Parent = hold}).InputBegan:Connect(function(i)
				if press(i) then dr = true; fromX(i.Position.X) end
			end)
			bind(UIS.InputChanged, function(i) if dr and move(i) then fromX(i.Position.X) end end)
			bind(UIS.InputEnded, function(i)
				if dr and press(i) then dr = false; if o.OnRelease then o.OnRelease(val) end end
			end)
			reg(o.Flag, obj)
			return obj
		end

		-- Dropdown / MultiDropdown
		local function makeDropdown(o, multi)
			o = o or {}
			local opts2 = o.Options or {}
			local box = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = page}, {list(4)})
			add(box)
			local hd = Card(box, o.Name or "Dropdown", o.Desc, {click = true, rw = 150})
			hd.LayoutOrder = 0
			local vl = L({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-30,.5,0), Size = UDim2.fromOffset(110,16), Text = "", TextColor3 = C.sub, TextSize = 11, TextXAlignment = Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = hd})
			local arrow = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(12,12), Image = ICON.arrowDown, ImageColor3 = C.sub, Parent = hd})
			local ls = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundColor3 = C.sec, Visible = false, LayoutOrder = 1, Parent = box}, {R(6), S(), list(0), pad(0,2,0,2)})

			local chosen, cur = {}, o.Default
			if multi then for _, v in ipairs(o.Default or {}) do chosen[tostring(v)] = true end end

			local function selected()
				local out = {}
				for _, v in ipairs(opts2) do if chosen[tostring(v)] then table.insert(out, v) end end
				return out
			end
			local items = {}
			local function paint()
				for _, it in ipairs(items) do
					local on = multi and chosen[it.key] or (not multi and cur == it.opt)
					it.lb.TextColor3 = on and C.tx or C.sub
					it.tk.ImageTransparency = on and 0 or 1
				end
			end
			local function head()
				if multi then
					local names = {}
					for _, v in ipairs(selected()) do table.insert(names, tostring(v)) end
					vl.Text = #names == 0 and "None" or table.concat(names, ", ")
				else
					vl.Text = cur == nil and "None" or tostring(cur)
				end
			end
			local function setOpen(v)
				ls.Visible = v
				arrow.Image = v and ICON.arrowUp or ICON.arrowDown
			end
			local obj = {}
			local function build()
				for _, it in ipairs(items) do it.ob:Destroy() end
				items = {}
				for i, opt in ipairs(opts2) do
					local key = tostring(opt)
					local ob = N("TextButton", {Size = UDim2.new(1,0,0,26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = ls})
					local lb2 = L({Position = UDim2.fromOffset(12,0), Size = UDim2.new(1,-40,1,0), Text = key, TextSize = 12, Parent = ob})
					local tk = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-12,.5,0), Size = UDim2.fromOffset(14,14), Image = ICON.tick, ImageColor3 = C.ac, ImageTransparency = 1, Parent = ob})
					table.insert(items, {ob = ob, lb = lb2, tk = tk, key = key, opt = opt})
					ob.MouseButton1Click:Connect(function()
						if multi then
							chosen[key] = (not chosen[key]) or nil -- กดซ้ำ = ยกเลิก
							paint(); head()
							if o.Callback then o.Callback(selected()) end
						else
							cur = opt
							paint(); head(); setOpen(false)
							if o.Callback then o.Callback(opt) end
						end
					end)
				end
				paint()
			end
			build(); head()

			function obj:Set(v, silent)
				if multi then
					chosen = {}
					for _, x in ipairs(v or {}) do chosen[tostring(x)] = true end
				else
					cur = v
				end
				paint(); head()
				if o.Callback and not silent then o.Callback(multi and selected() or cur) end
			end
			function obj:Get() return multi and selected() or cur end
			function obj:Refresh(newOpts)
				opts2 = newOpts or {}
				build(); head()
			end
			hd.MouseButton1Click:Connect(function() setOpen(not ls.Visible) end)
			reg(o.Flag, obj)
			return obj
		end

		-- Dropdown({Name, Desc, Options, Default, Flag, Callback(value)})
		function Tb:Dropdown(o) return makeDropdown(o, false) end
		-- MultiDropdown({Name, Desc, Options, Default = {..}, Flag, Callback({values})})
		function Tb:MultiDropdown(o) return makeDropdown(o, true) end

		-- Textbox({Name, Desc, Default, Placeholder, Flag, Callback(text)})
		function Tb:Textbox(o)
			o = o or {}
			local c = Card(page, o.Name or "Textbox", o.Desc, {rw = 150})
			add(c)
			local tb = N("TextBox", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(130,24), BackgroundColor3 = C.el, Text = o.Default or "", PlaceholderText = o.Placeholder or "", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 12, ClearTextOnFocus = false, Parent = c}, {R(6), S(), pad(8,0,8,0)})
			local obj = {}
			function obj:Set(v, silent) tb.Text = tostring(v or ""); if o.Callback and not silent then o.Callback(tb.Text) end end
			function obj:Get() return tb.Text end
			tb.FocusLost:Connect(function() if o.Callback then o.Callback(tb.Text) end end)
			reg(o.Flag, obj)
			return obj
		end

		return Tb
	end
	return W
end

return Lib
