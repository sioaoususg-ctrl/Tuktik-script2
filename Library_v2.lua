--[[
	UI Library v2.2 (personal / open source) - sidebar + 2 columns
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

local C = {bg=Color3.fromRGB(13,15,21), side=Color3.fromRGB(10,12,17), sec=Color3.fromRGB(18,21,29), el=Color3.fromRGB(28,32,43), st=Color3.fromRGB(38,42,55),
	tx=Color3.fromRGB(225,228,236), sub=Color3.fromRGB(122,128,146), ac=Color3.fromRGB(60,125,255),
	green=Color3.fromRGB(46,204,113), gray=Color3.fromRGB(70,75,90),
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
	logo      = asset(81370075887698),  -- โลโก้ค่าย (ใช้ทั้งหน้า Key และ UI หลัก)
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

-- press effect: ปุ่มเข้มขึ้นเล็กน้อย + ย่อนิดหน่อย (base เป็นสี หรือฟังก์ชันคืนสี)
local function fx(b, base)
	local function B() if type(base) == "function" then return base() end return base end
	local sc = N("UIScale", {Parent = b})
	b.MouseButton1Down:Connect(function() T(b, {BackgroundColor3 = B():Lerp(Color3.new(0,0,0), .25)}); T(sc, {Scale = .98}) end)
	local function up() T(b, {BackgroundColor3 = B()}); T(sc, {Scale = 1}) end
	b.MouseButton1Up:Connect(function() task.delay(.1, up) end)
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
			local us = f:FindFirstChildWhichIsA("UIScale")
			local v = (i.Position - ds) / ((us and us.Scale > 0) and us.Scale or 1)
			f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + v.X, sp.Y.Scale, sp.Y.Offset + v.Y)
		end
	end))
	add(UIS.InputEnded:Connect(function(i) if press(i) then d = false end end))
end

local function copy(t) if setclipboard then pcall(setclipboard, t) end end

-- ย่อ UI ให้พอดีหน้าจอ (มือถือ / จอเล็ก)
local function fitScale(gui, w, h)
	local a = gui.AbsoluteSize
	if a.X < 10 or a.Y < 10 then
		local cam = workspace.CurrentCamera
		a = cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	return math.clamp(math.min((a.X - 16) / w, (a.Y - 16) / h, 1), .5, 1)
end

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

-- ═════════════════ KEY SYSTEM (flat card) ═════════════════
-- Lib.Key({Title=, Subtitle=, Logo=, Key=, Check=function(key) return bool end, Game=,
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
	local f = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(440,256), BackgroundColor3 = C.bg, Active = true, Parent = gui}, {R(10), S()})
	local fitK = fitScale(gui, 440, 256)
	local pop = N("UIScale", {Scale = fitK * .96, Parent = f})
	T(pop, {Scale = fitK}, .2)
	table.insert(kc, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		fitK = fitScale(gui, 440, 256)
		pop.Scale = fitK
	end))
	drag(f, f, kc)

	local function closeKey()
		for _, c in ipairs(kc) do c:Disconnect() end
		gui:Destroy()
	end

	-- header: โลโก้ + ชื่อ (ซ้าย) / โลโก้แมพ + ชื่อแมพ + ชื่อผู้เล่น (ขวา)
	local lg = N("Frame", {Position = UDim2.fromOffset(18,14), Size = UDim2.fromOffset(34,34), BackgroundColor3 = C.el, Parent = f}, {R(8)})
	N("ImageLabel", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = (o.Logo and o.Logo ~= "") and o.Logo or ICON.logo, Parent = lg}, {R(8)})
	L({Position = UDim2.fromOffset(62,14), Size = UDim2.new(1,-270,0,18), Text = o.Title or "Hub", Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
	L({Position = UDim2.fromOffset(62,32), Size = UDim2.new(1,-270,0,14), Text = o.Subtitle or "Key System", TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})

	N("ImageLabel", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-18,0,15), Size = UDim2.fromOffset(32,32), BackgroundColor3 = C.el, Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Parent = f}, {R(7)})
	local gl = L({AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-58,0,15), Size = UDim2.fromOffset(170,16), Text = o.Game or "Loading...", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
	L({AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-58,0,32), Size = UDim2.fromOffset(170,14), Text = "Playing as " .. lp.DisplayName, TextColor3 = C.sub, TextSize = 10, TextXAlignment = Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
	if not o.Game then
		task.spawn(function()
			local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
			if gl.Parent then gl.Text = ok and info.Name or "Unknown game" end
		end)
	end

	N("Frame", {Position = UDim2.fromOffset(0,62), Size = UDim2.new(1,0,0,1), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = f})

	-- input (ไอคอนอยู่นอก TextBox)
	local ws = S()
	local wrap = N("Frame", {Position = UDim2.fromOffset(18,78), Size = UDim2.fromOffset(404,38), BackgroundColor3 = C.sec, Parent = f}, {R(6), ws})
	local kic = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,12,.5,0), Size = UDim2.fromOffset(16,16), Image = ICON.key, ImageColor3 = C.sub, Parent = wrap})
	local box = N("TextBox", {Position = UDim2.fromOffset(40,0), Size = UDim2.new(1,-52,1,0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter Key", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Left, ClearTextOnFocus = false, ClipsDescendants = true, Parent = wrap})
	box.Focused:Connect(function() T(ws, {Color = C.ac}); T(kic, {ImageColor3 = C.ac}) end)
	box.FocusLost:Connect(function() T(ws, {Color = C.st}); T(kic, {ImageColor3 = C.sub}) end)

	local msg = L({Position = UDim2.fromOffset(20,121), Size = UDim2.fromOffset(400,16), Text = "Enter your key to continue", TextColor3 = C.sub, TextSize = 11, Parent = f})

	-- ปุ่ม แบบเรียบ (ไอคอนอยู่ซ้ายข้อความ กึ่งกลางปุ่ม)
	local function btn(x, y, w, h, text, base, tc, icon)
		local b = N("TextButton", {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h), BackgroundColor3 = type(base) == "function" and base() or base, Text = "      " .. text, TextColor3 = tc, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, Parent = f}, {R(6)})
		local tb = game:GetService("TextService"):GetTextSize(b.Text, 12, Enum.Font.GothamMedium, Vector2.new(1000, 100))
		local ico = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(.5, -tb.X/2, .5, 0), Size = UDim2.fromOffset(14,14), Image = icon, ImageColor3 = tc, Parent = b})
		fx(b, base)
		return b, ico
	end

	local ready = false
	local exitB  = btn(18, 146, 92, 36, "Exit", C.el, C.tx, ICON.exit)
	local getkey = btn(118, 146, 108, 36, "Get key", C.el, C.tx, ICON.key)
	local submit, subIc = btn(234, 146, 188, 36, "Submit", function() return ready and C.ac or C.el end, WHITE, ICON.tick)
	local dcB    = btn(18, 190, 198, 32, "Discord", C.el, C.tx, ICON.discord)
	local webB   = btn(224, 190, 198, 32, "Website", C.el, C.tx, ICON.web)

	L({Position = UDim2.fromOffset(20,232), Size = UDim2.fromOffset(400,14), Text = save and "Your key is saved, you only enter it once" or "Key is not saved (test mode)", TextColor3 = C.sub, TextSize = 10, Parent = f})

	-- Submit: จาง + กดไม่ได้ตอนยังไม่มีตัวอักษร / เข้ม + กดได้เมื่อมีตัวอักษร
	local function setReady(v, instant)
		ready = v
		local g  = {BackgroundColor3 = v and C.ac or C.el, BackgroundTransparency = v and 0 or .6, TextTransparency = v and 0 or .6}
		local gi = {ImageTransparency = v and 0 or .6}
		if instant then
			for k, x in pairs(g) do submit[k] = x end
			for k, x in pairs(gi) do subIc[k] = x end
		else
			T(submit, g); T(subIc, gi)
		end
		submit.Interactable = v
	end
	setReady(false, true)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local has = (box.Text:gsub("%s", "")) ~= ""
		if has ~= ready then setReady(has) end
	end)

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
		if busy or not ready then return end
		local k = (box.Text:gsub("%s", ""))
		busy = true
		msg.Text, msg.TextColor3 = "Checking...", C.sub
		if valid(k) then
			msg.Text, msg.TextColor3 = "Key accepted", C.green
			Lib.Notify({Title = "Key accepted", Content = "Loading interface...", Type = "success"})
			if save then pcall(writefile, file, k) end
			task.wait(.4)
			T(pop, {Scale = fitK * .96}, .15)
			task.wait(.15)
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

-- ═════════════════ MAIN UI (sidebar + 2 columns) ═════════════════
-- Lib.new({Title=, Subtitle=, Short="NL", Logo=, Size=UDim2})  หรือ Lib.new("Title")
function Lib.new(opts, logo)
	if type(opts) ~= "table" then opts = {Title = opts, Logo = logo} end
	local title = opts.Title or "Hub"

	local gui = mount()
	local lp = Players.LocalPlayer
	local conns = {}
	local function bind(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

	local SW, TOP = 140, 48
	local FULL = opts.Size or UDim2.fromOffset(580, 350)
	local MINI = UDim2.new(FULL.X.Scale, FULL.X.Offset, 0, TOP)

	local main = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = FULL, BackgroundColor3 = C.bg, Active = true, ClipsDescendants = true, Parent = gui}, {R(10), S()})
	local fit = N("UIScale", {Parent = main})
	local function refit() fit.Scale = fitScale(gui, FULL.X.Offset, FULL.Y.Offset) end
	refit()
	bind(gui:GetPropertyChangedSignal("AbsoluteSize"), refit)

	-- ═════ Sidebar ═════
	local side = N("Frame", {Size = UDim2.new(0,SW,1,0), BackgroundColor3 = C.side, BorderSizePixel = 0, Parent = main}, {R(10)})
	N("Frame", {Position = UDim2.new(0,SW-12,0,0), Size = UDim2.new(0,12,1,0), BackgroundColor3 = C.side, BorderSizePixel = 0, Parent = side}) -- ปิดมุมโค้งฝั่งขวา

	local head = N("Frame", {Size = UDim2.new(1,0,0,TOP), BackgroundTransparency = 1, Parent = side})
	local lg = N("Frame", {Position = UDim2.fromOffset(14,8), Size = UDim2.fromOffset(32,32), BackgroundColor3 = C.el, Parent = head}, {R(8)})
	N("ImageLabel", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = (opts.Logo and opts.Logo ~= "") and opts.Logo or ICON.logo, Parent = lg}, {R(8)})
	L({Position = UDim2.fromOffset(54,8), Size = UDim2.new(1,-60,0,16), Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
	L({Position = UDim2.fromOffset(54,24), Size = UDim2.new(1,-60,0,14), Text = opts.Subtitle or opts.By or "", TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})

	local tabList = N("ScrollingFrame", {Position = UDim2.fromOffset(0,TOP+2), Size = UDim2.new(1,0,1,-(TOP+2+54)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = AutoY, CanvasSize = UDim2.new(), Parent = side}, {pad(8,4,8,4), list(2)})

	-- profile
	local foot = N("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.fromScale(0,1), Size = UDim2.new(1,0,0,54), BackgroundTransparency = 1, Parent = side})
	N("ImageLabel", {Position = UDim2.fromOffset(14,12), Size = UDim2.fromOffset(30,30), BackgroundColor3 = C.el, Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150", Parent = foot}, {Round()})
	L({Position = UDim2.fromOffset(52,12), Size = UDim2.new(1,-58,0,16), Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})
	L({Position = UDim2.fromOffset(52,27), Size = UDim2.new(1,-58,0,14), Text = "@" .. lp.Name, TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})

	-- ═════ Top bar (ฝั่งขวา) ═════
	local top = N("Frame", {Position = UDim2.fromOffset(SW,0), Size = UDim2.new(1,-SW,0,TOP), BackgroundTransparency = 1, Parent = main})
	local pageTitle = L({Position = UDim2.fromOffset(16,0), Size = UDim2.new(1,-260,1,0), Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Parent = top})
	drag(top, main, conns)
	drag(head, main, conns)

	local closeB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-14,.5,0), Size = UDim2.fromOffset(24,24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = top})
	local closeIc = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(12,12), Image = ICON.close, ImageColor3 = C.sub, Parent = closeB})
	closeB.MouseEnter:Connect(function() T(closeIc, {ImageColor3 = C.red}) end)
	closeB.MouseLeave:Connect(function() T(closeIc, {ImageColor3 = C.sub}) end)
	local miniB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-42,.5,0), Size = UDim2.fromOffset(24,24), BackgroundTransparency = 1, Text = "-", TextColor3 = C.sub, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, Parent = top})
	local expIc = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(12,12), Image = ICON.expand, ImageColor3 = C.sub, Visible = false, Parent = miniB})
	miniB.MouseEnter:Connect(function() T(miniB, {TextColor3 = C.tx}); T(expIc, {ImageColor3 = C.tx}) end)
	miniB.MouseLeave:Connect(function() T(miniB, {TextColor3 = C.sub}); T(expIc, {ImageColor3 = C.sub}) end)

	local search = N("TextBox", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-74,.5,0), Size = UDim2.fromOffset(124,24), BackgroundColor3 = C.el, Text = "", PlaceholderText = "Search", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Left, ClearTextOnFocus = false, ClipsDescendants = true, Parent = top}, {R(5), pad(9,0,9,0)})

	local content = N("Frame", {Position = UDim2.fromOffset(SW,TOP), Size = UDim2.new(1,-SW,1,-TOP), BackgroundTransparency = 1, Parent = main})
	N("Frame", {Position = UDim2.new(.5,0,0,6), Size = UDim2.new(0,1,1,-14), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = content}) -- เส้นแบ่งครึ่ง 2 คอลัมน์

	-- minimize
	local mini = false
	local function setMini(v)
		mini = v
		miniB.Text = v and "" or "-"
		expIc.Visible = v
		if v then
			local tw = TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = MINI})
			tw.Completed:Connect(function()
				if mini then tabList.Visible = false; foot.Visible = false; content.Visible = false; search.Visible = false end
			end)
			tw:Play()
		else
			tabList.Visible = true; foot.Visible = true; content.Visible = true; search.Visible = true
			TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = FULL}):Play()
		end
	end
	miniB.MouseButton1Click:Connect(function() setMini(not mini) end)

	bind(UIS.InputBegan, function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end end)
	local function destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		gui:Destroy()
	end

	-- ═════ Fluent-style dialog ═════
	-- w:Dialog({Title=, Content=, Buttons = {{Name=, Primary=true, Callback=function()}, ...}})
	local dialogOpen = false
	local function dialog(o)
		if dialogOpen then return end
		dialogOpen = true
		task.spawn(function()
			if mini then setMini(false); task.wait(.3) end
			local ov = N("TextButton", {Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 100, Parent = main}, {R(10)})
			T(ov, {BackgroundTransparency = .45}, .2)
			local card = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(300,146), BackgroundColor3 = C.sec, Parent = ov}, {R(8), S()})
			local pp = N("UIScale", {Scale = .92, Parent = card})
			TS:Create(pp, TweenInfo.new(.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			L({Position = UDim2.fromOffset(18,16), Size = UDim2.fromOffset(264,20), Text = o.Title or "Dialog", Font = Enum.Font.GothamBold, TextSize = 14, Parent = card})
			L({Position = UDim2.fromOffset(18,40), Size = UDim2.fromOffset(264,46), Text = o.Content or "", TextColor3 = C.sub, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card})
			local function closeDlg()
				T(ov, {BackgroundTransparency = 1}, .15)
				T(pp, {Scale = .92}, .15)
				task.delay(.16, function()
					dialogOpen = false
					if ov.Parent then ov:Destroy() end
				end)
			end
			local btns = o.Buttons or {{Name = "OK", Primary = true}}
			local gap = 8
			local bw = (264 - gap * (#btns - 1)) / #btns
			for i, bd in ipairs(btns) do
				local base = bd.Primary and C.ac or C.el
				local bb = N("TextButton", {Position = UDim2.fromOffset(18 + (i-1) * (bw + gap), 100), Size = UDim2.fromOffset(bw,30), BackgroundColor3 = base, Text = bd.Name or "OK", TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, Parent = card}, {R(5)})
				fx(bb, base)
				bb.MouseButton1Click:Connect(function()
					closeDlg()
					if bd.Callback then bd.Callback() end
				end)
			end
		end)
	end

	closeB.MouseButton1Click:Connect(function()
		dialog({
			Title = "Close UI",
			Content = "Are you sure you want to close " .. title .. "? You will need to run the script again to reopen it.",
			Buttons = {{Name = "Close", Primary = true, Callback = destroy}, {Name = "Cancel"}},
		})
	end)

	-- ═════ Flags / Config ═════
	local Flags = {}
	local function regFlag(flag, obj) if flag then Flags[flag] = obj end end

	local W, tabs, sideOrder, curTab = {Flags = Flags}, {}, 0, nil
	function W:Destroy() destroy() end
	function W:Dialog(o) dialog(o) end
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

	-- ค้นหา: ซ่อนแถวที่ชื่อไม่ตรง และซ่อน Section ที่ไม่มีแถวเหลือ
	local function applyFilter()
		if not curTab then return end
		local q = string.lower((search.Text:gsub("^%s+", ""):gsub("%s+$", "")))
		for _, s in ipairs(curTab.secs) do s.count = 0 end
		for _, r in ipairs(curTab.rows) do
			local vis = q == "" or string.find(r.name, q, 1, true) ~= nil
			r.el.Visible = vis
			if vis then r.sec.count += 1 end
		end
		for _, s in ipairs(curTab.secs) do s.frame.Visible = q == "" or s.count > 0 end
	end
	search:GetPropertyChangedSignal("Text"):Connect(applyFilter)

	-- label + desc ในแถว
	local function labelPair(r, name, desc, ws, wo)
		if desc and desc ~= "" then
			L({Position = UDim2.fromOffset(2,3), Size = UDim2.new(ws,wo,0,16), Text = name, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
			L({Position = UDim2.fromOffset(2,19), Size = UDim2.new(ws,wo,0,14), Text = desc, TextColor3 = C.sub, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		else
			L({Position = UDim2.fromOffset(2,0), Size = UDim2.new(ws,wo,1,0), Text = name, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		end
	end

	-- Category(name): หัวข้อกลุ่มในแถบซ้าย (เช่น AIMBOT)
	function W:Category(name)
		sideOrder += 1
		L({Size = UDim2.new(1,0,0,22), Text = "  " .. string.upper(name), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.sub, LayoutOrder = sideOrder, Parent = tabList})
	end

	-- ═════ Tab ═════
	function W:Tab(name, icon)
		sideOrder += 1
		local b = N("TextButton", {Size = UDim2.new(1,0,0,30), BackgroundColor3 = C.el, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = sideOrder, Parent = tabList}, {R(6)})
		local ic, tx = nil, 10
		if icon then
			ic = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,10,.5,0), Size = UDim2.fromOffset(14,14), Image = icon, ImageColor3 = C.sub, Parent = b})
			tx = 32
		end
		local lb = L({Position = UDim2.fromOffset(tx,0), Size = UDim2.new(1,-tx-6,1,0), Text = name, TextColor3 = C.sub, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b})

		local page = N("ScrollingFrame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.st, AutomaticCanvasSize = AutoY, CanvasSize = UDim2.new(), Visible = false, Parent = content})
		local holderC = N("Frame", {Position = UDim2.fromOffset(14,2), Size = UDim2.new(1,-28,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = page},
			{N("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,14), SortOrder = Enum.SortOrder.LayoutOrder})})
		local cols = {}
		for i = 1, 2 do
			cols[i] = N("Frame", {Size = UDim2.new(.5,-7,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = i, Parent = holderC}, {list(10)})
			N("Frame", {Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, LayoutOrder = 99999, Parent = cols[i]}) -- ระยะขอบล่าง
		end

		local t = {b = b, lb = lb, ic = ic, page = page, name = name, rows = {}, secs = {}}
		table.insert(tabs, t)
		local function sel()
			curTab = t
			pageTitle.Text = name
			for _, x in ipairs(tabs) do
				local on = (x == t)
				x.page.Visible = on
				T(x.b, {BackgroundTransparency = on and 0 or 1})
				T(x.lb, {TextColor3 = on and C.tx or C.sub})
				if x.ic then T(x.ic, {ImageColor3 = on and C.ac or C.sub}) end
			end
			applyFilter()
		end
		b.MouseButton1Click:Connect(sel)
		if #tabs == 1 then sel() end

		local Tb = {}
		local secN, lastSec = 0, nil

		-- Section(name, side)  side = "Left" | "Right" | nil (สลับซ้ายขวาอัตโนมัติ)
		function Tb:Section(secName, side)
			secN += 1
			local ci = (side == "Right" and 2) or (side == "Left" and 1) or ((secN - 1) % 2 + 1)
			local sf = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, LayoutOrder = secN, Parent = cols[ci]}, {list(3)})
			local entry = {frame = sf, count = 0}
			table.insert(t.secs, entry)
			if secName and secName ~= "" then
				L({Size = UDim2.new(1,0,0,20), Text = string.upper(secName), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.sub, LayoutOrder = -2, Parent = sf})
				N("Frame", {Size = UDim2.new(1,0,0,1), BackgroundColor3 = C.st, BorderSizePixel = 0, LayoutOrder = -1, Parent = sf})
			end

			local s, ord = {}, 0
			local function add(el, nm)
				ord += 1
				el.LayoutOrder = ord
				table.insert(t.rows, {el = el, name = string.lower(nm or ""), sec = entry})
				return el
			end
			local function row(h) return N("Frame", {Size = UDim2.new(1,0,0,h), BackgroundTransparency = 1, Parent = sf}) end
			local function hasDesc(o) return o.Desc and o.Desc ~= "" end

			-- Toggle({Name, Desc, Default, Flag, Callback}) -> {Set, Get}   (สวิตช์)
			function s:Toggle(o)
				o = o or {}
				local on = o.Default == true
				local r = add(row(hasDesc(o) and 36 or 26), o.Name)
				labelPair(r, o.Name or "Toggle", o.Desc, 1, -48)
				local pill = N("Frame", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-2,.5,0), Size = UDim2.fromOffset(34,18), BackgroundColor3 = C.el, Parent = r}, {Round()})
				local ps = S(); ps.Parent = pill
				local knob = N("Frame", {AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,3,.5,0), Size = UDim2.fromOffset(12,12), BackgroundColor3 = C.sub, Parent = pill}, {Round()})
				local function render(instant)
					local g1 = {BackgroundColor3 = on and C.ac or C.el}
					local g2 = {Color = on and C.ac or C.st}
					local g3 = {Position = on and UDim2.new(0,19,.5,0) or UDim2.new(0,3,.5,0), BackgroundColor3 = on and WHITE or C.sub}
					if instant then
						for k, v in pairs(g1) do pill[k] = v end
						for k, v in pairs(g2) do ps[k] = v end
						for k, v in pairs(g3) do knob[k] = v end
					else
						T(pill, g1); T(ps, g2); T(knob, g3)
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
				N("TextButton", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", Parent = r}).MouseButton1Click:Connect(function() obj:Set(not on) end)
				regFlag(o.Flag, obj)
				return obj
			end

			-- Button({Name, Desc, Callback})
			function s:Button(o)
				o = type(o) == "table" and o or {Name = o}
				local d = hasDesc(o)
				local bt = N("TextButton", {Size = UDim2.new(1,0,0,d and 38 or 26), BackgroundColor3 = C.el, Text = d and "" or (o.Name or "Button"), TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, Parent = sf}, {R(5)})
				if d then
					L({Position = UDim2.fromOffset(0,5), Size = UDim2.new(1,0,0,16), Text = o.Name or "Button", TextSize = 12, TextXAlignment = Center, Parent = bt})
					L({Position = UDim2.fromOffset(0,20), Size = UDim2.new(1,0,0,14), Text = o.Desc, TextColor3 = C.sub, TextSize = 10, TextXAlignment = Center, Parent = bt})
				end
				add(bt, o.Name)
				fx(bt, C.el)
				bt.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
			end

			-- Slider({Name, Desc, Min, Max, Default, Increment, Suffix, Flag, Callback, OnRelease}) -> {Set, Get}
			function s:Slider(o)
				o = o or {}
				local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
				local suf = o.Suffix or ""
				local val = math.clamp(o.Default or min, min, max)
				local r = add(row(hasDesc(o) and 36 or 26), o.Name)
				labelPair(r, o.Name or "Slider", o.Desc, .44, 0)
				local tr = N("Frame", {AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(.46,0,.5,0), Size = UDim2.new(.54,-52,0,4), BackgroundColor3 = C.el, Parent = r}, {Round()})
				local fl = N("Frame", {Size = UDim2.fromScale(0,1), BackgroundColor3 = C.ac, Parent = tr}, {Round()})
				local knob = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(0,.5), Size = UDim2.fromOffset(10,10), BackgroundColor3 = WHITE, Parent = tr}, {Round()})
				local vb = N("Frame", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-2,.5,0), Size = UDim2.fromOffset(40,18), BackgroundColor3 = C.el, Parent = r}, {R(4)})
				local vl = L({Size = UDim2.fromScale(1,1), Text = "", TextSize = 10, TextColor3 = C.sub, TextXAlignment = Center, Parent = vb})
				local function render()
					local a = max > min and (val - min) / (max - min) or 0
					fl.Size = UDim2.fromScale(a, 1)
					knob.Position = UDim2.fromScale(a, .5)
					vl.Text = tostring(val) .. suf
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
					local a = math.clamp((x - tr.AbsolutePosition.X) / math.max(tr.AbsoluteSize.X, 1), 0, 1)
					local v = norm(min + (max - min) * a)
					if v ~= val then obj:Set(v) end
				end
				N("TextButton", {Position = UDim2.new(.46,-4,0,0), Size = UDim2.new(.54,-44,1,0), BackgroundTransparency = 1, Text = "", Parent = r}).InputBegan:Connect(function(i)
					if press(i) then dr = true; fromX(i.Position.X) end
				end)
				bind(UIS.InputChanged, function(i) if dr and move(i) then fromX(i.Position.X) end end)
				bind(UIS.InputEnded, function(i)
					if dr and press(i) then dr = false; if o.OnRelease then o.OnRelease(val) end end
				end)
				regFlag(o.Flag, obj)
				return obj
			end

			-- Dropdown / MultiDropdown
			local function makeDropdown(o, multi)
				o = o or {}
				local opts2 = o.Options or {}
				local box = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundTransparency = 1, Parent = sf}, {list(3)})
				add(box, o.Name)
				local hr = N("Frame", {Size = UDim2.new(1,0,0,hasDesc(o) and 36 or 26), BackgroundTransparency = 1, LayoutOrder = 0, Parent = box})
				labelPair(hr, o.Name or "Dropdown", o.Desc, 1, -124)
				local hd = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,0,.5,0), Size = UDim2.fromOffset(116,22), BackgroundColor3 = C.el, Text = "", AutoButtonColor = false, Parent = hr}, {R(4)})
				local vl = L({Position = UDim2.fromOffset(8,0), Size = UDim2.new(1,-26,1,0), Text = "", TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = hd})
				local arrow = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-7,.5,0), Size = UDim2.fromOffset(9,9), Image = ICON.arrowDown, ImageColor3 = C.sub, Parent = hd})
				fx(hd, C.el)
				local ls = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, BackgroundColor3 = C.el, Visible = false, LayoutOrder = 1, Parent = box}, {R(5), list(0), pad(0,3,0,3)})

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
				local function headText()
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
						local ob = N("TextButton", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = ls})
						local lb2 = L({Position = UDim2.fromOffset(10,0), Size = UDim2.new(1,-34,1,0), Text = key, TextSize = 11, Parent = ob})
						local tk = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(12,12), Image = ICON.tick, ImageColor3 = C.ac, ImageTransparency = 1, Parent = ob})
						table.insert(items, {ob = ob, lb = lb2, tk = tk, key = key, opt = opt})
						ob.MouseButton1Click:Connect(function()
							if multi then
								chosen[key] = (not chosen[key]) or nil -- กดซ้ำ = ยกเลิก
								paint(); headText()
								if o.Callback then o.Callback(selected()) end
							else
								cur = opt
								paint(); headText(); setOpen(false)
								if o.Callback then o.Callback(opt) end
							end
						end)
					end
					paint()
				end
				build(); headText()

				function obj:Set(v, silent)
					if multi then
						chosen = {}
						for _, x in ipairs(v or {}) do chosen[tostring(x)] = true end
					else
						cur = v
					end
					paint(); headText()
					if o.Callback and not silent then o.Callback(multi and selected() or cur) end
				end
				function obj:Get() return multi and selected() or cur end
				function obj:Refresh(newOpts)
					opts2 = newOpts or {}
					build(); headText()
				end
				hd.MouseButton1Click:Connect(function() setOpen(not ls.Visible) end)
				regFlag(o.Flag, obj)
				return obj
			end
			function s:Dropdown(o) return makeDropdown(o, false) end
			function s:MultiDropdown(o) return makeDropdown(o, true) end

			-- Textbox({Name, Desc, Default, Placeholder, Flag, Callback(text)})
			function s:Textbox(o)
				o = o or {}
				local r = add(row(hasDesc(o) and 36 or 26), o.Name)
				labelPair(r, o.Name or "Textbox", o.Desc, 1, -132)
				local tb = N("TextBox", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,0,.5,0), Size = UDim2.fromOffset(124,22), BackgroundColor3 = C.el, Text = o.Default or "", PlaceholderText = o.Placeholder or "", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Left, ClearTextOnFocus = false, ClipsDescendants = true, Parent = r}, {R(4), pad(8,0,8,0)})
				local obj = {}
				function obj:Set(v, silent) tb.Text = tostring(v or ""); if o.Callback and not silent then o.Callback(tb.Text) end end
				function obj:Get() return tb.Text end
				tb.FocusLost:Connect(function() if o.Callback then o.Callback(tb.Text) end end)
				regFlag(o.Flag, obj)
				return obj
			end

			-- Label(text) -> {Set}
			function s:Label(text)
				local lb3 = add(L({Size = UDim2.new(1,0,0,0), AutomaticSize = AutoY, Text = text, TextColor3 = C.sub, TextSize = 11, TextWrapped = true, Parent = sf}), text)
				return {Set = function(_, v) lb3.Text = v end}
			end

			lastSec = s
			return s
		end

		-- ใช้ tab:Toggle(...) ตรงๆ ได้ (ไปอยู่ใน Section ล่าสุด)
		for _, m in ipairs({"Toggle", "Button", "Slider", "Dropdown", "MultiDropdown", "Textbox", "Label"}) do
			Tb[m] = function(_, ...)
				if not lastSec then Tb:Section("") end
				return lastSec[m](lastSec, ...)
			end
		end

		return Tb
	end
	return W
end

return Lib
