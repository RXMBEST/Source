local INTRO_TEXT = "亗 『 R X M H U B 』 🄾🄽 🅃🄾🄿 亗"
local INTRO_SOUND = "rbxassetid://86045706626808"
local INTRO_PROFILE = "rbxassetid://17297011003"
local INTRO_IMAGE_WAIT = 6
local function svc(name)
	local service = game:GetService(name)
	if cloneref then
		return cloneref(service)
	end
	return service
end
local Players = svc("Players")
local TweenService = svc("TweenService")
local UserInputService = svc("UserInputService")
local RunService = svc("RunService")
local CoreGui = svc("CoreGui")
local HttpService = svc("HttpService")
local ContentProvider = svc("ContentProvider")
local LocalPlayer = Players.LocalPlayer
local ES, ED = Enum.EasingStyle, Enum.EasingDirection
local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
pcall(function()
	if getgenv and getgenv().RXMHUBGUI then
		getgenv().RXMHUBGUI.Destroy()
	end
end)
pcall(function()
	local old = CoreGui:FindFirstChild("RXMHUB")
	if old then
		old:Destroy()
	end
end)
local function mountGui(gui)
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end
	local parents = {}
	if gethui then
		table.insert(parents, gethui)
	end
	table.insert(parents, function()
		return CoreGui
	end)
	table.insert(parents, function()
		return LocalPlayer:WaitForChild("PlayerGui")
	end)
	for _, getParent in ipairs(parents) do
		if pcall(function()
			gui.Parent = getParent()
		end) and gui.Parent ~= nil then
			return true
		end
	end
	return false
end
local function LoadProfileImage(maxWait, onLate)
	local id = string.match(INTRO_PROFILE, "%d+")
	if not id then return nil, false end
	local won, timedOut = false, false
	local result
	local bestGuess = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
	local probeGui = Instance.new("ScreenGui")
	probeGui.Name = "RizzXD_ProfileProbe"
	probeGui.ResetOnSpawn = false
	probeGui.DisplayOrder = -1
	if not mountGui(probeGui) then
		return bestGuess, false
	end
	local function present()
		return probeGui.Parent ~= nil
	end
	local function resolve(url)
		if won then return end
		won = true
		result = url
		if timedOut and onLate then
			pcall(onLate, url)
		end
	end
	local function attempt(url, timeout)
		if won or not present() or type(url) ~= "string" or url == "" then return end
		task.spawn(function()
			local probe = Instance.new("ImageLabel")
			probe.Size = UDim2.fromOffset(4, 4)
			probe.BackgroundTransparency = 1
			probe.Image = url
			probe.ImageTransparency = 0.99
			probe.Parent = probeGui
			pcall(function()
				ContentProvider:PreloadAsync({probe})
			end)
			local t0 = os.clock()
			while not won and present() and os.clock() - t0 < (timeout or 5) do
				local ok, v = pcall(function()
					return probe.IsLoaded
				end)
				if ok and v == true then
					resolve(url)
					break
				end
				task.wait(0.1)
			end
			pcall(function()
				probe:Destroy()
			end)
		end)
	end
	local function idFrom(text)
		if type(text) ~= "string" then return nil end
		return string.match(text, "(%d%d%d+)")
	end
	local function attemptImageId(imageId)
		if not imageId then return end
		bestGuess = "rbxassetid://" .. imageId
		attempt("rbxassetid://" .. imageId, 5)
		attempt("http://www.roblox.com/asset/?id=" .. imageId, 5)
	end
	attempt("rbxassetid://" .. id, 5)
	attempt("http://www.roblox.com/asset/?id=" .. id, 5)
	attempt("rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420", 5)
	task.spawn(function()
		local okObj, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. id)
		end)
		if not (okObj and type(objs) == "table") then return end
		for _, obj in ipairs(objs) do
			local tex
			pcall(function()
				if obj:IsA("Decal") or obj:IsA("Texture") then
					tex = obj.Texture
				elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					tex = obj.Image
				else
					local d = obj:FindFirstChildWhichIsA("Decal", true) or obj:FindFirstChildWhichIsA("Texture", true)
					tex = d and d.Texture
				end
			end)
			pcall(function()
				obj:Destroy()
			end)
			if tex and tex ~= "" then
				attempt(tex, 5)
				attemptImageId(idFrom(tex))
			end
		end
	end)
	local makeAsset = getcustomasset or getsynasset
	local function fetch(url)
		if not requestFunc then return nil end
		local ok, res = pcall(requestFunc, {Url = url, Method = "GET"})
		if ok and type(res) == "table" and type(res.Body) == "string" and res.Body ~= "" then
			if res.StatusCode == nil or res.StatusCode == 200 then
				return res.Body
			end
		end
		return nil
	end
	local function isImage(bytes)
		if type(bytes) ~= "string" or #bytes < 100 then return false end
		return string.sub(bytes, 2, 4) == "PNG" or (string.byte(bytes, 1) == 255 and string.byte(bytes, 2) == 216)
	end
	local function useBytes(bytes)
		if not (makeAsset and writefile and isImage(bytes)) then return end
		local file = "RizzXD_profile" .. (string.sub(bytes, 2, 4) == "PNG" and ".png" or ".jpg")
		if not pcall(writefile, file, bytes) then return end
		local ok, asset = pcall(makeAsset, file)
		if ok and type(asset) == "string" then
			attempt(asset, 5)
		end
	end
	local function download(assetId)
		local meta = fetch("https://assetdelivery.roblox.com/v1/assetId/" .. assetId)
		if meta then
			local okJson, data = pcall(function()
				return HttpService:JSONDecode(meta)
			end)
			if okJson and type(data) == "table" and type(data.location) == "string" then
				local body = fetch(data.location)
				if body then return body end
			end
		end
		return fetch("https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId)
	end
	if requestFunc then
		task.spawn(function()
			local body = download(id)
			if not body then return end
			if isImage(body) then
				useBytes(body)
			elseif string.find(body, "<roblox", 1, true) then
				local imageId = string.match(body, "<url>[^<]-id=(%d+)") or string.match(body, "rbxassetid://(%d+)")
				if imageId then
					attemptImageId(imageId)
					useBytes(download(imageId))
				end
			end
		end)
		task.spawn(function()
			local meta = fetch("https://thumbnails.roblox.com/v1/assets?assetIds=" .. id .. "&size=420x420&format=Png")
			if not meta then return end
			local okJson, data = pcall(function()
				return HttpService:JSONDecode(meta)
			end)
			local imageUrl = okJson and type(data) == "table" and type(data.data) == "table" and data.data[1] and data.data[1].imageUrl
			if type(imageUrl) == "string" then
				useBytes(fetch(imageUrl))
			end
		end)
	end
	local t0 = os.clock()
	while not won and os.clock() - t0 < (maxWait or 6) do
		task.wait(0.05)
	end
	if won then
		task.delay(2, function()
			pcall(function()
				probeGui:Destroy()
			end)
		end)
		return result, true
	end
	timedOut = true
	task.delay(12, function()
		pcall(function()
			probeGui:Destroy()
		end)
	end)
	return bestGuess, false
end
local function PlayScreenIntro(onComplete)
	local finished = false
	local function complete()
		if finished then return end
		finished = true
		if onComplete then
			task.spawn(onComplete)
		end
	end
	local profileHook = {}
	local okLoad, profileUrl, profileLoaded = pcall(LoadProfileImage, INTRO_IMAGE_WAIT, function(url)
		if profileHook.show then
			profileHook.show(url)
		end
	end)
	if not okLoad then
		profileUrl, profileLoaded = nil, false
	end
	local IntroGui = Instance.new("ScreenGui")
	IntroGui.Name = "RizzXD_ScreenIntro"
	IntroGui.IgnoreGuiInset = true
	pcall(function()
		IntroGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	IntroGui.ResetOnSpawn = false
	IntroGui.DisplayOrder = 999999
	IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, IntroGui)
	end
	local mounted = false
	if gethui then
		mounted = pcall(function()
			IntroGui.Parent = gethui()
		end) and IntroGui.Parent ~= nil
	end
	if not mounted then
		mounted = pcall(function()
			IntroGui.Parent = CoreGui
		end) and IntroGui.Parent ~= nil
	end
	if not mounted then
		mounted = pcall(function()
			IntroGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end) and IntroGui.Parent ~= nil
	end
	if not mounted then
		complete()
		return
	end
	local conn
	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		pcall(function()
			IntroGui:Destroy()
		end)
		complete()
	end
	task.delay(14, function()
		if IntroGui.Parent then
			cleanup()
		end
	end)
	local built = pcall(function()
		local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
		local compact = UserInputService.TouchEnabled or viewport.X < 700
		local rng = Random.new()
		local RED = Color3.fromRGB(235, 235, 235)
		local DEEP = Color3.fromRGB(110, 110, 110)
		local PALE = Color3.fromRGB(200, 200, 200)
		local WHITE = Color3.new(1, 1, 1)
		local GLOW = "rbxassetid://5028857484"
		local function make(class, props, parent)
			local inst = Instance.new(class)
			for key, value in pairs(props) do
				inst[key] = value
			end
			inst.Parent = parent
			return inst
		end
		local function tw(inst, time, props, style, dir)
			local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
			tween:Play()
			return tween
		end
		local function kp(t, v)
			return NumberSequenceKeypoint.new(t, v)
		end
		local function ck(t, c)
			return ColorSequenceKeypoint.new(t, c)
		end
		local function circle(inst)
			make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, inst)
		end
		local Stage = make("CanvasGroup", {
			Name = "Stage",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			GroupTransparency = 1,
		}, IntroGui)
		local stageScale = make("UIScale", {Scale = 1}, Stage)
		tw(Stage, 0.55, {GroupTransparency = 0}, Enum.EasingStyle.Sine)
		local IntroSound = make("Sound", {SoundId = INTRO_SOUND, Volume = 2}, IntroGui)
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({IntroSound})
			end)
			pcall(function()
				IntroSound:Play()
			end)
		end)
		local fogCfg = {
			{size = 980, color = RED, base = 0.74, sx = 0.38, sy = 0.31, ax = 0.20, ay = 0.14, ph = 0},
			{size = 760, color = DEEP, base = 0.62, sx = 0.27, sy = 0.44, ax = 0.26, ay = 0.18, ph = 2.1},
			{size = 640, color = RED, base = 0.84, sx = 0.52, sy = 0.36, ax = 0.30, ay = 0.12, ph = 4.2},
		}
		for _, cfg in ipairs(fogCfg) do
			cfg.img = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(cfg.size, cfg.size),
				BackgroundTransparency = 1,
				Image = GLOW,
				ImageColor3 = cfg.color,
				ImageTransparency = cfg.base,
				ZIndex = 1,
			}, Stage)
		end
		local streaks = {}
		for i = 1, compact and 4 or 6 do
			local frame = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(rng:NextInteger(2, 4), math.floor(viewport.Y * 1.7)),
				Rotation = 18,
				BackgroundColor3 = i % 2 == 0 and RED or DEEP,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, Stage)
			make("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.55), kp(1, 1)}),
			}, frame)
			streaks[i] = {frame = frame, speed = rng:NextNumber(0.05, 0.12), phase = rng:NextNumber(0, 1)}
		end
		local beamHalo = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1, 0, 0, 130),
			BackgroundColor3 = RED,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, Stage)
		make("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.88), kp(1, 1)}),
		}, beamHalo)
		local beam = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = RED,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, Stage)
		make("UIGradient", {
			Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.2), kp(1, 1)}),
		}, beam)
		local particles = {}
		local function resetParticle(p, initial)
			p.x = rng:NextNumber(0.02, 0.98)
			p.y = initial and rng:NextNumber(0.05, 1.05) or rng:NextNumber(1.04, 1.2)
			p.vy = rng:NextNumber(0.06, 0.2)
			p.amp = rng:NextNumber(0.004, 0.022)
			p.freq = rng:NextNumber(0.8, 2.4)
			p.phase = rng:NextNumber(0, 6.28)
			p.alpha = rng:NextNumber(0.55, 0.95)
			local s = rng:NextInteger(2, 5)
			p.frame.Size = UDim2.fromOffset(s, s)
			p.frame.BackgroundColor3 = RED:Lerp(PALE, rng:NextNumber(0, 0.5))
		end
		for i = 1, compact and 28 or 46 do
			local frame = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = RED,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, Stage)
			circle(frame)
			local glow = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(5, 5),
				BackgroundTransparency = 1,
				Image = GLOW,
				ImageColor3 = RED,
				ImageTransparency = 1,
			}, frame)
			local p = {frame = frame, glow = glow}
			resetParticle(p, true)
			particles[i] = p
		end
		local function edge(anchor, pos, size, rot)
			local f = make("Frame", {
				AnchorPoint = anchor,
				Position = pos,
				Size = size,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
				ZIndex = 5,
			}, Stage)
			make("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({kp(0, 0), kp(1, 1)})}, f)
		end
		edge(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.3), 90)
		edge(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.3), -90)
		edge(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.22, 1), 0)
		edge(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.22, 1), 180)
		local brackets = {}
		local function bracket(ax, ay)
			local m, len, th = 18, 34, 2
			for k = 1, 2 do
				local f = make("Frame", {
					AnchorPoint = Vector2.new(ax, ay),
					Position = UDim2.new(ax, ax == 0 and m or -m, ay, ay == 0 and m or -m),
					Size = k == 1 and UDim2.fromOffset(len, th) or UDim2.fromOffset(th, len),
					BackgroundColor3 = RED,
					BorderSizePixel = 0,
					ZIndex = 10,
				}, Stage)
				table.insert(brackets, f)
			end
		end
		bracket(0, 0)
		bracket(1, 0)
		bracket(0, 1)
		bracket(1, 1)
		local E = compact and 112 or 180
		local EY = 0.36
		local Emblem = make("Frame", {
			Name = "Emblem",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, EY, 0),
			Size = UDim2.fromOffset(E, E),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, Stage)
		local emblemScale = make("UIScale", {Scale = 0.3}, Emblem)
		tw(emblemScale, 0.95, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local coreGlow = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(E * 2.2, E * 2.2),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = RED,
			ImageTransparency = 0.55,
			ZIndex = 1,
		}, Emblem)
		local ticks = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(E * 1.24, E * 1.24),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, Emblem)
		for i = 0, 23 do
			local a = math.rad(i * 15)
			local major = i % 6 == 0
			make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)),
				Size = UDim2.fromOffset(major and 3 or 2, major and 12 or 7),
				Rotation = i * 15 + 90,
				BackgroundColor3 = RED,
				BackgroundTransparency = major and 0.1 or 0.55,
				BorderSizePixel = 0,
			}, ticks)
		end
		local function ring(size, thickness, trans, colors)
			local f = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1,
				ZIndex = 3,
			}, Emblem)
			circle(f)
			local stroke = make("UIStroke", {
				Thickness = thickness,
				Color = WHITE,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, f)
			local grad = make("UIGradient", {Color = colors, Transparency = trans}, stroke)
			return f, stroke, grad
		end
		local _, _, outerGrad = ring(E, 3,
			NumberSequence.new({kp(0, 1), kp(0.12, 0.1), kp(0.42, 0), kp(0.58, 1), kp(1, 1)}),
			ColorSequence.new({ck(0, RED), ck(0.5, PALE), ck(1, DEEP)}))
		local _, _, midGrad = ring(E * 0.8, 2,
			NumberSequence.new({kp(0, 1), kp(0.1, 0.15), kp(0.22, 1), kp(0.4, 1), kp(0.5, 0.15), kp(0.62, 1), kp(0.8, 1), kp(0.9, 0.25), kp(1, 1)}),
			ColorSequence.new({ck(0, DEEP), ck(0.5, RED), ck(1, DEEP)}))
		local _, innerStroke = ring(E * 0.6, 1.5,
			NumberSequence.new({kp(0, 0), kp(1, 0)}),
			ColorSequence.new({ck(0, RED), ck(1, RED)}))
		local core = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(E * 0.5, E * 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BorderSizePixel = 0,
			ZIndex = 4,
		}, Emblem)
		circle(core)
		make("UIStroke", {
			Color = RED,
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, core)
		local coreScale = make("UIScale", {Scale = 1}, core)
		local profileLetter = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "R",
			Font = Enum.Font.GothamBlack,
			TextSize = math.floor(E * 0.26),
			TextColor3 = WHITE,
			ZIndex = 4,
		}, core)
		local profileImage = make("ImageLabel", {
			Name = "Profile",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = "",
			ImageTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 5,
		}, core)
		circle(profileImage)
		local function showProfile(url, instant)
			if not profileImage.Parent then return end
			profileImage.Image = url
			profileLetter.Visible = false
			if instant then
				profileImage.ImageTransparency = 0
			else
				tw(profileImage, 0.45, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
			end
		end
		if profileUrl and profileLoaded then
			showProfile(profileUrl, true)
		elseif profileUrl then
			profileImage.Image = profileUrl
			tw(profileImage, 0.45, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
			profileHook.show = function(url)
				showProfile(url, false)
			end
		end
		local orbits = {}
		for i = 1, 3 do
			local frame = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = i == 1 and WHITE or RED,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, Emblem)
			circle(frame)
			make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(6, 6),
				BackgroundTransparency = 1,
				Image = GLOW,
				ImageColor3 = RED,
				ImageTransparency = 0.35,
			}, frame)
			orbits[i] = {frame = frame, speed = 1.3 + i * 0.55, phase = i * 2.09}
		end
		local function shockwave(fromSize, toSize, life, thick)
			local f = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(fromSize, fromSize),
				BackgroundTransparency = 1,
				ZIndex = 4,
			}, Emblem)
			circle(f)
			local st = make("UIStroke", {
				Color = RED,
				Thickness = thick or 3,
				Transparency = 0.15,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, f)
			tw(f, life, {Size = UDim2.fromOffset(toSize, toSize)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tw(st, life, {Transparency = 1, Thickness = 0.5}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(life + 0.1, function()
				f:Destroy()
			end)
		end
		local titleOff = E / 2 + (compact and 34 or 48)
		local titleHolder = make("Frame", {
			Name = "Title",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, EY, titleOff),
			Size = UDim2.new(0.94, 0, 0, 48),
			BackgroundTransparency = 1,
			ZIndex = 7,
		}, Stage)
		local function titleLabel(color, z)
			local label = make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				Font = Enum.Font.GothamBlack,
				TextScaled = true,
				TextColor3 = color,
				ZIndex = z,
			}, titleHolder)
			make("UITextSizeConstraint", {MaxTextSize = compact and 18 or 26, MinTextSize = 8}, label)
			return label
		end
		local ghostA = titleLabel(RED, 6)
		local ghostB = titleLabel(PALE, 6)
		local titleMain = titleLabel(WHITE, 7)
		ghostA.TextTransparency = 1
		ghostB.TextTransparency = 1
		make("UIStroke", {
			Color = Color3.fromRGB(10, 10, 10),
			Thickness = 2.5,
			Transparency = 0.1,
		}, titleMain)
		local titleGrad = make("UIGradient", {
			Color = ColorSequence.new({ck(0, Color3.fromRGB(200, 200, 200)), ck(0.5, WHITE), ck(1, Color3.fromRGB(120, 120, 120))}),
		}, titleMain)
		local subtitle = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, EY, titleOff + (compact and 28 or 36)),
			Size = UDim2.new(0.94, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "R X M   H U B   ·   C R I M S O N   N O I R",
			Font = Enum.Font.GothamMedium,
			TextSize = compact and 9 or 11,
			TextColor3 = Color3.fromRGB(190, 190, 190),
			TextTransparency = 1,
			ZIndex = 7,
		}, Stage)
		local barW = math.clamp(viewport.X * 0.6, 240, 460)
		local bar = make("Frame", {
			Name = "Bar",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, compact and 0.93 or 0.9, 0),
			Size = UDim2.fromOffset(barW, 44),
			BackgroundTransparency = 1,
			ZIndex = 8,
		}, Stage)
		local statusLabel = make("TextLabel", {
			Size = UDim2.new(0.75, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "Initializing core",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 8,
		}, bar)
		local percent = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0.25, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "0%",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = WHITE,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 8,
		}, bar)
		local track = make("Frame", {
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
			ZIndex = 8,
		}, bar)
		circle(track)
		make("UIStroke", {
			Color = RED,
			Thickness = 1,
			Transparency = 0.6,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, track)
		local barGlow = make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -7, 0.5, 0),
			Size = UDim2.new(0, 14, 0, 34),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = RED,
			ImageTransparency = 0.55,
			ZIndex = 8,
		}, track)
		local fill = make("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 9,
		}, track)
		circle(fill)
		make("UIGradient", {
			Color = ColorSequence.new({ck(0, DEEP), ck(0.7, RED), ck(1, Color3.fromRGB(220, 220, 220))}),
		}, fill)
		local sweep = make("Frame", {
			Size = UDim2.fromScale(0.3, 1),
			Position = UDim2.fromScale(-0.4, 0),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, fill)
		make("UIGradient", {
			Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.35), kp(1, 1)}),
		}, sweep)
		local head = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(46, 46),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = RED,
			ImageTransparency = 0.3,
			ZIndex = 11,
		}, track)
		local STATUS = {
			{0, "Initializing core"},
			{0.16, "Loading modules"},
			{0.4, "Fetching tech list"},
			{0.64, "Applying Monochrome theme"},
			{0.88, "Finalizing"},
		}
		local flash = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(235, 235, 235),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 30,
		}, Stage)
		local t = 0
		local BAR_START, BAR_END = 0.35, 5.0
		local TYPE_START, TYPE_RATE = 0.7, 0.055
		local len = utf8.len(INTRO_TEXT) or #INTRO_TEXT
		local lastShown, statusIdx = -1, 0
		local glitchUntil, nextGlitch, nextWave = 0, 2.6, 0.9
		local subShown, exiting, faded = false, false, false
		local exitAt = 0
		local function step(dt)
			t = t + dt
			for _, cfg in ipairs(fogCfg) do
				cfg.img.Position = UDim2.fromScale(0.5 + cfg.ax * math.sin(t * cfg.sx + cfg.ph), 0.5 + cfg.ay * math.cos(t * cfg.sy + cfg.ph))
				cfg.img.ImageTransparency = cfg.base + 0.06 * math.sin(t * 1.3 + cfg.ph)
			end
			for _, s in ipairs(streaks) do
				s.frame.Position = UDim2.fromScale(((t * s.speed + s.phase) % 1) * 1.5 - 0.25, 0.5)
			end
			local by = ((t * 0.2) % 1.25) - 0.12
			beam.Position = UDim2.fromScale(0.5, by)
			beamHalo.Position = UDim2.fromScale(0.5, by)
			for _, p in ipairs(particles) do
				p.y = p.y - p.vy * dt
				if p.y < -0.06 then
					resetParticle(p, false)
				end
				p.frame.Position = UDim2.fromScale(p.x + math.sin(t * p.freq + p.phase) * p.amp, p.y)
				local vis = math.clamp(math.min((1.04 - p.y) / 0.1, (p.y + 0.02) / 0.3), 0, 1)
				p.frame.BackgroundTransparency = 1 - vis * p.alpha
				p.glow.ImageTransparency = 1 - vis * 0.5
			end
			local ba = 0.25 + 0.2 * math.sin(t * 2.4)
			for _, f in ipairs(brackets) do
				f.BackgroundTransparency = ba
			end
			outerGrad.Rotation = (t * 150) % 360
			midGrad.Rotation = 360 - (t * 95) % 360
			ticks.Rotation = (t * 14) % 360
			profileImage.Rotation = (t * 90) % 360
			local pulse = 0.5 + 0.5 * math.sin(t * 3.2)
			coreScale.Scale = 1 + 0.07 * pulse
			coreGlow.ImageTransparency = 0.55 - 0.18 * pulse
			local gs = E * (2.2 + 0.25 * pulse)
			coreGlow.Size = UDim2.fromOffset(gs, gs)
			innerStroke.Transparency = 0.45 + 0.3 * pulse
			for _, o in ipairs(orbits) do
				local a = t * o.speed + o.phase
				o.frame.Position = UDim2.new(0.5, math.cos(a) * E * 0.41, 0.5, math.sin(a) * E * 0.41)
			end
			if t >= nextWave and not exiting then
				nextWave = t + 1.5
				shockwave(E * 0.55, E * 2.6, 1.35, 3)
			end
			local shown = math.clamp(math.floor((t - TYPE_START) / TYPE_RATE), 0, len)
			if shown ~= lastShown then
				lastShown = shown
				local txt = INTRO_TEXT
				if shown < len then
					local off = utf8.offset(INTRO_TEXT, shown + 1)
					if off then
						txt = string.sub(INTRO_TEXT, 1, off - 1)
					end
				end
				titleMain.Text = txt
				ghostA.Text = txt
				ghostB.Text = txt
			end
			titleGrad.Rotation = (titleGrad.Rotation + dt * 200) % 360
			if t >= nextGlitch and shown >= len then
				glitchUntil = t + 0.16
				nextGlitch = t + rng:NextNumber(1.1, 2.4)
			end
			if t < glitchUntil then
				local j = rng:NextInteger(3, 7)
				ghostA.Position = UDim2.new(0.5, -j, 0.5, rng:NextInteger(-2, 2))
				ghostB.Position = UDim2.new(0.5, j, 0.5, rng:NextInteger(-2, 2))
				ghostA.TextTransparency = 0.3
				ghostB.TextTransparency = 0.5
				titleMain.Position = UDim2.new(0.5, rng:NextInteger(-2, 2), 0.5, 0)
			else
				ghostA.TextTransparency = 1
				ghostB.TextTransparency = 1
				titleMain.Position = UDim2.fromScale(0.5, 0.5)
			end
			if not subShown and t > 2.0 then
				subShown = true
				tw(subtitle, 0.8, {TextTransparency = 0.15}, Enum.EasingStyle.Quad)
			end
			local u = math.clamp((t - BAR_START) / (BAR_END - BAR_START), 0, 1)
			local p = u * u * (3 - 2 * u)
			fill.Size = UDim2.fromScale(p, 1)
			head.Position = UDim2.new(p, 0, 0.5, 0)
			head.ImageTransparency = 0.25 + 0.15 * math.sin(t * 11)
			barGlow.Size = UDim2.new(p, 14, 0, 34)
			sweep.Position = UDim2.fromScale((t * 0.9) % 1.6 - 0.4, 0)
			if not exiting then
				percent.Text = math.floor(p * 100 + 0.5) .. "%"
				local idx = 1
				for i, s in ipairs(STATUS) do
					if p >= s[1] then
						idx = i
					end
				end
				if idx ~= statusIdx then
					statusIdx = idx
					statusLabel.Text = STATUS[idx][2]
				end
			end
			if not exiting and u >= 1 then
				exiting, exitAt = true, t
				percent.Text = "100%"
				statusLabel.Text = "Ready"
				local f1 = tw(flash, 0.12, {BackgroundTransparency = 0.45}, Enum.EasingStyle.Quad)
				f1.Completed:Connect(function()
					tw(flash, 0.6, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
				end)
				tw(emblemScale, 0.4, {Scale = 1.2}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				shockwave(E * 0.6, E * 8, 0.95, 6)
			end
			if exiting then
				local e = t - exitAt
				if not faded and e >= 0.5 then
					faded = true
					tw(stageScale, 0.95, {Scale = 1.25}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
					tw(Stage, 0.95, {GroupTransparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					tw(IntroSound, 0.95, {Volume = 0}, Enum.EasingStyle.Linear)
					complete()
				end
				if e >= 1.55 then
					cleanup()
				end
			end
		end
		local fails = 0
		conn = RunService.Heartbeat:Connect(function(rawDt)
			local ok = pcall(step, math.min(rawDt, 0.05))
			if not ok then
				fails = fails + 1
				if fails >= 3 then
					cleanup()
				end
			end
		end)
	end)
	if not built then
		cleanup()
	end
end
local function Main()
	local alive = true
	local connections = {}
	local accent = Color3.fromRGB(235, 235, 235)
	local tintColor = accent
	local accentBinds = {}
	local T = {
		black = Color3.new(0, 0, 0),
		card = Color3.fromRGB(18, 18, 18),
		cardHover = Color3.fromRGB(34, 34, 34),
		stroke = Color3.fromRGB(60, 60, 60),
		track = Color3.fromRGB(44, 44, 44),
		off = Color3.fromRGB(64, 64, 64),
		text = Color3.fromRGB(245, 245, 245),
		muted = Color3.fromRGB(160, 160, 160),
		input = Color3.fromRGB(12, 12, 12),
		dark = Color3.fromRGB(22, 22, 22),
		btn = Color3.fromRGB(32, 32, 32),
	}
	local state = "idle"
	local hidden = false
	local hover = false
	local UI_SCALE = 0.9
	local noticeW = 300
	local currentItem, noticeStart = nil, 0
	local queue, notifying = {}, false
	local glowKick, ringP, toastSeq = 0, 1, 0
	local pulses = {}
	local fx = {border = true, glow = true, neon = true, shimmer = true, embers = true, aurora = true, squash = true}
	local borderSpeed = 70
	local bounceAmt, curProfile = 1, nil
	local hTok, morphTok = 0, 0
	local swiped = false
	local setState, notify, setHidden
	local function connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(connections, c)
		return c
	end
	local function new(class, props)
		local inst = Instance.new(class)
		local parent
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				inst[key] = value
			end
		end
		inst.Parent = parent
		return inst
	end
	local function corner(inst, radius)
		return new("UICorner", {CornerRadius = UDim.new(0, radius), Parent = inst})
	end
	local function round(inst)
		return new("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = inst})
	end
	local function tween(inst, time, props, style, direction, delay)
		local info = TweenInfo.new(time, style or ES.Exponential, direction or ED.Out, 0, false, delay or 0)
		local t = TweenService:Create(inst, info, props)
		t:Play()
		return t
	end
	local function bindAccent(fn)
		table.insert(accentBinds, fn)
		fn(accent)
	end
	local function setAccent(color)
		accent = color
		for _, fn in ipairs(accentBinds) do
			pcall(fn, color)
		end
	end
	local function lerpColor(a, b, t)
		return a:Lerp(b, t)
	end
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	local function isMove(input)
		return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
	end
	local function newSpring(value, k, ratio)
		return {x = value, v = 0, t = value, k = k, d = 2 * ratio * math.sqrt(k)}
	end
	local function tuneSpring(s, k, ratio)
		s.k = k
		local r = math.clamp(1 - (1 - ratio) * bounceAmt, 0.25, 1)
		s.d = 2 * r * math.sqrt(k)
	end
	local function stepSpring(s, dt)
		local n = math.max(1, math.ceil(dt * 120))
		local h = dt / n
		for _ = 1, n do
			s.v = s.v + (s.k * (s.t - s.x) - s.d * s.v) * h
			s.x = s.x + s.v * h
		end
	end
	local function kindColor(kind)
		return accent
	end
	local gui = new("ScreenGui", {
		Name = "RXMHUB",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		IgnoreGuiInset = true,
	})
	do
		if syn and syn.protect_gui then
			pcall(syn.protect_gui, gui)
		end
		local mounted = false
		if gethui then
			mounted = pcall(function()
				gui.Parent = gethui()
			end) and gui.Parent ~= nil
		end
		if not mounted then
			mounted = pcall(function()
				gui.Parent = CoreGui
			end) and gui.Parent ~= nil
		end
		if not mounted then
			gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end
	end
	local isTouch = UserInputService.TouchEnabled
	local clickEnabled = true
	local playClick
	do
		local CLICK_IDS = {
			"rbxasset://sounds/button.mp3",
			"rbxasset://sounds/switch.mp3",
			"rbxasset://sounds/clickfast.mp3",
			"rbxasset://sounds/SWITCH3.mp3",
			"rbxasset://sounds/button.wav",
			"rbxasset://sounds/switch.wav",
			"rbxasset://sounds/clickfast.wav",
		}
		local clickVolume = 0.7
		local clickPool, clickNext = {}, 0
		for i = 1, 4 do
			clickPool[i] = new("Sound", {
				Name = "Click" .. i,
				SoundId = CLICK_IDS[1],
				Volume = clickVolume,
				Parent = gui,
			})
		end
		playClick = function(speed, volume)
			if not clickEnabled or not alive then return end
			clickNext = clickNext % #clickPool + 1
			local snd = clickPool[clickNext]
			snd.PlaybackSpeed = (speed or 1) * (0.96 + math.random() * 0.08)
			snd.Volume = clickVolume * (volume or 1)
			snd.TimePosition = 0
			snd:Play()
		end
		task.spawn(function()
			local probe = clickPool[1]
			for _, id in ipairs(CLICK_IDS) do
				probe.SoundId = id
				local loaded = false
				pcall(function()
					ContentProvider:PreloadAsync({probe}, function(_, status)
						if status == Enum.AssetFetchStatus.Success then
							loaded = true
						end
					end)
				end)
				if not alive then return end
				if loaded or (probe.IsLoaded and probe.TimeLength > 0) then
					for _, snd in ipairs(clickPool) do
						snd.SoundId = id
					end
					return
				end
			end
		end)
	end
	local function viewportSize()
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	local viewport = viewportSize()
	local IDLE_W, IDLE_H = 142, 36
	local NOTIFY_H = 64
	local PAD_Y = 8
	local PANEL_R = 30
	local HEADER_H, TABBAR_H = 46, 34
	local PAGE_TOP = HEADER_H + TABBAR_H + 8
	local W, H = 450, 360
	if isTouch or viewport.X < 700 then
		W = math.clamp(viewport.X - 24, 290, 410)
		H = math.clamp(viewport.Y - 70, 236, 320)
	end
	local BOUNCE_DEFAULT = 45
	local function ratioFromBounce(b)
		return 1 - (b / 100) * 0.62
	end
	local R0 = ratioFromBounce(BOUNCE_DEFAULT)
	local sp = {
		w = newSpring(IDLE_W, 190, R0),
		h = newSpring(IDLE_H, 210, R0),
		r = newSpring(IDLE_H / 2, 220, R0),
		ox = newSpring(0, 150, 0.85),
		oy = newSpring(0, 150, 0.85),
		press = newSpring(1, 380, 0.5),
		show = newSpring(1, 170, 0.72),
		hy = newSpring(0, 170, 0.76),
	}
	local PROFILES = {
		open = {w = {175, 0.64}, h = {150, 0.66}, r = {210, 0.72}},
		close = {w = {250, 0.82}, h = {270, 0.86}, r = {270, 0.86}},
		pop = {w = {235, 0.58}, h = {265, 0.62}, r = {270, 0.70}},
		settle = {w = {260, 0.80}, h = {280, 0.84}, r = {280, 0.86}},
		swap = {w = {225, 0.70}, h = {245, 0.74}, r = {260, 0.80}},
		minimize = {w = {230, 0.80}, h = {250, 0.84}, r = {250, 0.88}},
	}
	local function applyProfile(p)
		curProfile = p
		tuneSpring(sp.w, p.w[1], p.w[2])
		tuneSpring(sp.h, p.h[1], p.h[2])
		tuneSpring(sp.r, p.r[1], p.r[2])
	end
	local backdrop = new("TextButton", {
		Name = "Backdrop",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Visible = false,
		Parent = gui,
	})
	local shell = new("Frame", {
		Name = "Island",
		ZIndex = 5,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, PAD_Y),
		Size = UDim2.fromOffset(IDLE_W, IDLE_H),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local shellScale = new("UIScale", {Scale = 0.001, Parent = shell})
	local glows
	do
		local function haloLayers(name, count, spread, drop, color, total)
			local weights, sum = {}, 0
			for i = 1, count do
				local k = (i - 0.5) / count
				weights[i] = 6 * k * (1 - k)
				sum = sum + weights[i]
			end
			local list = {}
			for i = 1, count do
				local k = i / count
				local grow = spread * k
				local frame = new("Frame", {
					Name = name .. i,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, drop * k),
					Size = UDim2.new(1, grow, 1, grow),
					BackgroundColor3 = color,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 1,
					Parent = shell,
				})
				list[i] = {
					frame = frame,
					corner = corner(frame, 20),
					off = grow,
					alpha = 1 - (1 - total) ^ (weights[i] / sum),
				}
			end
			return list
		end
		glows = haloLayers("Glow", 12, 54, 0, accent, 0.3)
	end
	bindAccent(function(color)
		for _, glow in ipairs(glows) do
			glow.frame.BackgroundColor3 = color
		end
	end)
	local island = new("CanvasGroup", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.black,
		BorderSizePixel = 0,
		ZIndex = 2,
		Active = true,
		Parent = shell,
	})
	local islandCorner = corner(island, IDLE_H / 2)
	local borderFrame = new("Frame", {
		Name = "Border",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = shell,
	})
	local borderCorner = corner(borderFrame, IDLE_H / 2)
	local border = new("UIStroke", {
		Thickness = 1.5,
		Color = Color3.new(1, 1, 1),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0.6,
		Parent = borderFrame,
	})
	local borderGradient = new("UIGradient", {Parent = border})
	local paintedTint = tintColor
	local function paintBorder(color)
		paintedTint = color
		borderGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.3, T.dark),
			ColorSequenceKeypoint.new(0.7, T.dark),
			ColorSequenceKeypoint.new(1, color),
		})
	end
	paintBorder(tintColor)
	local function ringFlash()
		if not alive then return end
		for i = 1, 2 do
			task.delay((i - 1) * 0.11, function()
				if not alive then return end
				local frame = new("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ZIndex = 1,
					Parent = shell,
				})
				local c = corner(frame, math.clamp(sp.r.x, 2, math.max(sp.h.x, 8) / 2))
				table.insert(pulses, {corner = c})
				local stroke = new("UIStroke", {
					Color = tintColor,
					Thickness = 1,
					Transparency = i == 1 and 0.1 or 0.45,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = frame,
				})
				tween(stroke, 0.95, {Thickness = i == 1 and 11 or 18, Transparency = 1}, ES.Quint, ED.Out)
				task.delay(1, function()
					frame:Destroy()
				end)
			end)
		end
	end
	local PANEL_DROP = math.floor(IDLE_H * UI_SCALE + 8)
	local panelPos = {x = 0, y = PANEL_DROP}
	local function panelLimits()
		local vp = viewportSize()
		local maxX = math.max(0, vp.X / 2 - W * UI_SCALE / 2 - 4)
		local minY = 4 - PAD_Y
		local maxY = math.max(minY, vp.Y - 4 - PAD_Y - H * UI_SCALE)
		return maxX, minY, maxY
	end
	local groups = {}
	local function makeGroup(name, w, h)
		local frame = new("CanvasGroup", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, h / 2),
			Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 3,
			Parent = island,
		})
		local scale = new("UIScale", {Scale = 0.82, Parent = frame})
		local entry = {frame = frame, scale = scale, tok = 0, a = newSpring(0, 300, 1), s = newSpring(0.82, 300, 0.6)}
		table.insert(groups, entry)
		return entry
	end
	local function fadeGroup(entry, on, delay, dur)
		entry.tok = entry.tok + 1
		local tok = entry.tok
		local function apply()
			if entry.tok ~= tok or not alive then return end
			if on then
				local k = (4.74 / (dur or 0.3)) ^ 2
				entry.frame.Visible = true
				entry.a.k, entry.a.d = k, 2 * math.sqrt(k)
				entry.a.t = 1
				entry.s.k, entry.s.d = 320, 2 * 0.56 * math.sqrt(320)
				entry.s.t = 1
			else
				local k = (4.74 / (dur or 0.12)) ^ 2
				entry.a.k, entry.a.d = k, 2 * math.sqrt(k)
				entry.a.t = 0
				entry.s.k, entry.s.d = 520, 2 * math.sqrt(520)
				entry.s.t = 0.88
			end
		end
		if (delay or 0) > 0 then
			task.delay(delay, apply)
		else
			apply()
		end
	end
	local idleG = makeGroup("Idle", IDLE_W, IDLE_H)
	local notifyG = makeGroup("Notify", noticeW, NOTIFY_H)
	local expG = makeGroup("Panel", W, H)
	new("UICorner", {CornerRadius = UDim.new(0, PANEL_R), Parent = expG.frame})
	local panel = expG.frame
	local idleHalo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = idleG.frame,
	})
	round(idleHalo)
	local idleDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = idleG.frame,
	})
	round(idleDot)
	local idleLabel = new("TextLabel", {
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -66, 1, 0),
		BackgroundTransparency = 1,
		Text = "RXM HUB",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = idleG.frame,
	})
	new("UITextSizeConstraint", {MaxTextSize = 12, MinTextSize = 8, Parent = idleLabel})
	local idleGradient = new("UIGradient", {Offset = Vector2.new(-1, 0), Parent = idleLabel})
	local barBox = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(19, 14),
		BackgroundTransparency = 1,
		Parent = idleG.frame,
	})
	local idleBars = {}
	for i = 1, 4 do
		local bar = new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, (i - 1) * 5, 1, 0),
			Size = UDim2.fromOffset(3, 4),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Parent = barBox,
		})
		round(bar)
		idleBars[i] = bar
	end
	bindAccent(function(color)
		idleHalo.BackgroundColor3 = color
		idleDot.BackgroundColor3 = color
		for _, bar in ipairs(idleBars) do
			bar.BackgroundColor3 = color
		end
		local base = lerpColor(color, Color3.new(1, 1, 1), 0.55)
		idleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, base),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, base),
		})
	end)
	local idleRest = {dot = idleDot.Position, halo = idleHalo.Position, bars = barBox.Position}
	local idleTok = 0
	local function idleIntro(delay)
		idleTok = idleTok + 1
		local tok = idleTok
		idleDot.Position = idleRest.dot + UDim2.fromOffset(12, 0)
		idleHalo.Position = idleRest.halo + UDim2.fromOffset(12, 0)
		barBox.Position = idleRest.bars + UDim2.fromOffset(-12, 0)
		idleLabel.TextTransparency = 1
		task.delay(delay or 0, function()
			if tok ~= idleTok or not alive then return end
			tween(idleDot, 0.55, {Position = idleRest.dot}, ES.Back, ED.Out)
			tween(idleHalo, 0.55, {Position = idleRest.halo}, ES.Back, ED.Out)
			tween(barBox, 0.55, {Position = idleRest.bars}, ES.Back, ED.Out)
			tween(idleLabel, 0.4, {TextTransparency = 0}, ES.Quad, ED.Out, 0.04)
		end)
	end
	local function idleOutro()
		idleTok = idleTok + 1
		tween(idleDot, 0.16, {Position = idleRest.dot + UDim2.fromOffset(10, 0)}, ES.Quad, ED.In)
		tween(idleHalo, 0.16, {Position = idleRest.halo + UDim2.fromOffset(10, 0)}, ES.Quad, ED.In)
		tween(barBox, 0.16, {Position = idleRest.bars + UDim2.fromOffset(-10, 0)}, ES.Quad, ED.In)
		tween(idleLabel, 0.12, {TextTransparency = 1}, ES.Quad, ED.In)
	end
	local function buildRing(parent, diameter, thickness)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 12 + diameter / 2, 0.5, 0),
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		local t = thickness
		local track = new("Frame", {
			Position = UDim2.fromOffset(t, t),
			Size = UDim2.new(1, -2 * t, 1, -2 * t),
			BackgroundTransparency = 1,
			Parent = ring,
		})
		round(track)
		new("UIStroke", {
			Thickness = t,
			Color = Color3.new(1, 1, 1),
			Transparency = 0.86,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = track,
		})
		local seq = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.501, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		local strokes, grads = {}, {}
		for i = 1, 2 do
			local right = i == 1
			local clip = new("Frame", {
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = right and UDim2.fromScale(0.5, 0) or UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(0.5, 1),
				Parent = ring,
			})
			local circle = new("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(right and -1 or 0, t, 0, t),
				Size = UDim2.new(2, -2 * t, 1, -2 * t),
				Parent = clip,
			})
			round(circle)
			strokes[i] = new("UIStroke", {
				Thickness = t,
				Color = accent,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = circle,
			})
			grads[i] = new("UIGradient", {
				Transparency = seq,
				Rotation = right and 0 or 180,
				Parent = strokes[i],
			})
		end
		local obj = {frame = ring}
		function obj.Set(p)
			p = math.clamp(p, 0, 1)
			grads[1].Rotation = math.clamp(p * 360, 0, 180)
			grads[2].Rotation = math.clamp(p * 360, 180, 360)
		end
		function obj.SetColor(color)
			strokes[1].Color = color
			strokes[2].Color = color
		end
		return obj
	end
	local function buildNotice(parent, h, bind)
		local n = {kind = "info"}
		local iconD = math.floor(h * 0.5)
		local ringD = iconD + 10
		n.ring = buildRing(parent, ringD, 2.5)
		local icon = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconD, iconD),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Parent = n.ring.frame,
		})
		round(icon)
		local textX = 12 + ringD + 12
		local title = new("TextLabel", {
			Position = UDim2.new(0, textX, 0.5, -17),
			Size = UDim2.new(1, -(textX + 16), 0, 17),
			BackgroundTransparency = 1,
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = parent,
		})
		local message = new("TextLabel", {
			Position = UDim2.new(0, textX, 0.5, 1),
			Size = UDim2.new(1, -(textX + 16), 0, 16),
			BackgroundTransparency = 1,
			Text = "",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = T.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = parent,
		})
		local function glyph(kind, color)
			for _, child in ipairs(icon:GetChildren()) do
				if not child:IsA("UICorner") then
					child:Destroy()
				end
			end
			local function bar(x, y, bw, bh, rot)
				local b = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(x, y),
					Size = UDim2.fromScale(bw, bh),
					Rotation = rot,
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Parent = icon,
				})
				round(b)
			end
			if kind == "success" then
				bar(0.35, 0.58, 0.11, 0.27, -45)
				bar(0.60, 0.51, 0.11, 0.47, 45)
			elseif kind == "error" then
				bar(0.5, 0.5, 0.11, 0.5, 45)
				bar(0.5, 0.5, 0.11, 0.5, -45)
			else
				new("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = kind == "warn" and "!" or "i",
					Font = Enum.Font.GothamBold,
					TextSize = math.floor(iconD * 0.62),
					TextColor3 = color,
					Parent = icon,
				})
			end
		end
		function n:Recolor()
			local color = kindColor(n.kind)
			icon.BackgroundColor3 = color
			glyph(n.kind, color)
			n.ring.SetColor(color)
		end
		function n:Set(kind, heading, text)
			n.kind = kind or "info"
			title.Text = tostring(heading or "")
			message.Text = tostring(text or "")
			n:Recolor()
		end
		local ringScale = new("UIScale", {Scale = 1, Parent = n.ring.frame})
		local titleRest, messageRest = title.Position, message.Position
		local introTok, swapTok = 0, 0
		function n:Intro(delay)
			introTok = introTok + 1
			local tok = introTok
			ringScale.Scale = 0.35
			title.TextTransparency = 1
			message.TextTransparency = 1
			title.Position = titleRest + UDim2.fromOffset(16, 0)
			message.Position = messageRest + UDim2.fromOffset(22, 0)
			task.delay(delay or 0, function()
				if tok ~= introTok then return end
				tween(ringScale, 0.6, {Scale = 1}, ES.Back, ED.Out)
				tween(title, 0.5, {TextTransparency = 0, Position = titleRest}, ES.Quint, ED.Out, 0.04)
				tween(message, 0.5, {TextTransparency = 0, Position = messageRest}, ES.Quint, ED.Out, 0.09)
			end)
		end
		function n:Swap(kind, heading, text)
			swapTok = swapTok + 1
			local tok = swapTok
			heading, text = tostring(heading or ""), tostring(text or "")
			local kindChanged = (kind or "info") ~= n.kind
			if not kindChanged and heading == title.Text and text == message.Text then return end
			tween(title, 0.12, {TextTransparency = 1, Position = titleRest + UDim2.fromOffset(0, -5)}, ES.Quad, ED.In)
			tween(message, 0.12, {TextTransparency = 1, Position = messageRest + UDim2.fromOffset(0, -5)}, ES.Quad, ED.In)
			task.delay(0.13, function()
				if tok ~= swapTok or not alive then return end
				n:Set(kind, heading, text)
				title.Position = titleRest + UDim2.fromOffset(0, 6)
				message.Position = messageRest + UDim2.fromOffset(0, 6)
				tween(title, 0.35, {TextTransparency = 0, Position = titleRest}, ES.Quint, ED.Out)
				tween(message, 0.35, {TextTransparency = 0, Position = messageRest}, ES.Quint, ED.Out, 0.04)
				if kindChanged then
					ringScale.Scale = 0.6
					tween(ringScale, 0.55, {Scale = 1}, ES.Back, ED.Out)
				end
			end)
		end
		if bind then
			bindAccent(function()
				n:Recolor()
			end)
		end
		n:Recolor()
		return n
	end
	local notice = buildNotice(notifyG.frame, NOTIFY_H, true)
	local TOAST = {
		w = math.min(300, viewport.X - 28),
		h = 58,
		gap = 8,
		edgeX = 14,
		edgeY = isTouch and 108 or 16,
		max = 4,
	}
	local toastHolder = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -TOAST.edgeX, 1, -TOAST.edgeY),
		Size = UDim2.new(0, TOAST.w, 1, -(TOAST.edgeY + 12)),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, TOAST.gap),
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastHolder,
	})
	local function floatToast(item)
		if not alive then return end
		local TW, TH = TOAST.w, TOAST.h
		local existing = {}
		for _, child in ipairs(toastHolder:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(existing, child)
			end
		end
		if #existing >= TOAST.max then
			existing[1]:Destroy()
		end
		toastSeq = toastSeq + 1
		local slot = new("Frame", {
			Size = UDim2.fromOffset(TW, TH),
			BackgroundTransparency = 1,
			LayoutOrder = toastSeq,
			Parent = toastHolder,
		})
		local pill = new("CanvasGroup", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, TW + 40, 0, 0),
			Size = UDim2.fromOffset(TW, TH),
			BackgroundColor3 = T.black,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			Parent = slot,
		})
		corner(pill, 18)
		local stroke = new("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 1.4,
			Transparency = 0.2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = pill,
		})
		local sgrad = new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, kindColor(item.kind)),
				ColorSequenceKeypoint.new(0.3, T.dark),
				ColorSequenceKeypoint.new(0.7, T.dark),
				ColorSequenceKeypoint.new(1, kindColor(item.kind)),
			}),
			Parent = stroke,
		})
		local sc = new("UIScale", {Scale = 0.9, Parent = pill})
		local n = buildNotice(pill, TH, false)
		n:Set(item.kind, item.heading, item.message)
		n:Intro(0.12)
		item.ui = {n = n}
		tween(pill, 0.6, {Position = UDim2.new(1, 0, 0, 0)}, ES.Back, ED.Out)
		tween(pill, 0.3, {GroupTransparency = 0}, ES.Quad, ED.Out)
		tween(sc, 0.6, {Scale = 1}, ES.Back, ED.Out)
		local dismissed = false
		local function dismiss()
			if dismissed then return end
			dismissed = true
			if not slot.Parent then return end
			tween(pill, 0.38, {Position = UDim2.new(1, TW + 40, 0, 0), GroupTransparency = 1}, ES.Quart, ED.In)
			tween(sc, 0.38, {Scale = 0.92}, ES.Quad, ED.In)
			task.delay(0.36, function()
				if slot.Parent then
					tween(slot, 0.25, {Size = UDim2.fromOffset(TW, 0)})
					task.delay(0.28, function()
						slot:Destroy()
					end)
				end
			end)
		end
		local hit = new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 20,
			Parent = pill,
		})
		local pressing, moved, startX, dragX = false, false, 0, 0
		local moveConn, endConn
		local function stopTrack()
			if moveConn then
				moveConn:Disconnect()
				moveConn = nil
			end
			if endConn then
				endConn:Disconnect()
				endConn = nil
			end
		end
		slot.Destroying:Connect(stopTrack)
		hit.InputBegan:Connect(function(input)
			if not isPress(input) or dismissed then return end
			pressing, moved, startX, dragX = true, false, input.Position.X, 0
			stopTrack()
			moveConn = UserInputService.InputChanged:Connect(function(changed)
				if pressing and isMove(changed) and not dismissed then
					local dx = changed.Position.X - startX
					if dx > 6 or moved then
						moved = true
						dragX = math.max(dx, -6)
						pill.Position = UDim2.new(1, dragX, 0, 0)
					end
				end
			end)
			endConn = UserInputService.InputEnded:Connect(function(ended)
				if pressing and isPress(ended) then
					pressing = false
					stopTrack()
					if dismissed then return end
					if not moved or dragX > 70 then
						dismiss()
					else
						tween(pill, 0.35, {Position = UDim2.new(1, 0, 0, 0)}, ES.Back, ED.Out)
					end
				end
			end)
		end)
		local duration = item.duration or 3.5
		task.spawn(function()
			local t0 = os.clock()
			local ringValue = item.live and 0 or 1
			while alive and slot.Parent and not dismissed do
				local dt = task.wait()
				local now = os.clock()
				sgrad.Rotation = (sgrad.Rotation + dt * 80) % 360
				if item.live then
					local target = item.progress or (0.15 + 0.1 * math.sin(now * 3))
					ringValue = ringValue + (target - ringValue) * math.min(1, dt * 8)
					if (item.finishAt and now >= item.finishAt) or now - t0 > 90 then
						break
					end
				else
					ringValue = 1 - math.clamp((now - t0) / duration, 0, 1)
					if now - t0 >= duration then
						break
					end
				end
				n.ring.Set(ringValue)
			end
			dismiss()
		end)
	end
	local auroraBlobs = {}
	for i, cfg in ipairs({{250, 0.2, 0.9}, {210, 0.85, 0.2}}) do
		local holder = new("Frame", {
			Position = UDim2.fromScale(cfg[2], cfg[3]),
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			ZIndex = 1,
			Parent = panel,
		})
		for j = 1, 3 do
			local size = cfg[1] * (1.1 - (j - 1) * 0.32)
			local layer = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.955,
				BorderSizePixel = 0,
				Parent = holder,
			})
			round(layer)
			table.insert(auroraBlobs, {frame = layer, holder = holder, idx = i})
		end
	end
	bindAccent(function(color)
		for _, blob in ipairs(auroraBlobs) do
			blob.frame.BackgroundColor3 = color
		end
	end)
	local header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = panel,
	})
	local logoHalo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 28, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = header,
	})
	round(logoHalo)
	local logoDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 28, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = header,
	})
	round(logoDot)
	local title = new("TextLabel", {
		Position = UDim2.new(0, 48, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "RXM HUB",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = header,
	})
	local titleGradient = new("UIGradient", {Offset = Vector2.new(-1, 0), Parent = title})
	bindAccent(function(color)
		logoHalo.BackgroundColor3 = color
		logoDot.BackgroundColor3 = color
		local base = lerpColor(color, Color3.new(1, 1, 1), 0.55)
		titleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, base),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, base),
		})
	end)
	local tabBar = new("Frame", {
		Name = "Tabs",
		Position = UDim2.new(0, 12, 0, HEADER_H),
		Size = UDim2.new(1, -24, 0, TABBAR_H),
		BackgroundColor3 = T.input,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = panel,
	})
	round(tabBar)
	new("UIStroke", {
		Color = T.stroke,
		Thickness = 1,
		Transparency = 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = tabBar,
	})
	local highlight = new("Frame", {
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = tabBar,
	})
	round(highlight)
	local highlightStroke = new("UIStroke", {
		Color = accent,
		Thickness = 1,
		Transparency = 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = highlight,
	})
	bindAccent(function(color)
		highlight.BackgroundColor3 = color
		highlightStroke.Color = color
	end)
	new("Frame", {
		Position = UDim2.new(0, 14, 0, PAGE_TOP - 5),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = T.stroke,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = panel,
	})
	local neonLine = new("Frame", {
		Position = UDim2.new(0, 14, 0, PAGE_TOP - 6),
		Size = UDim2.new(1, -28, 0, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = panel,
	})
	local neonGradient = new("UIGradient", {
		Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 0.6),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.65, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = neonLine,
	})
	bindAccent(function(color)
		neonGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, lerpColor(color, Color3.new(1, 1, 1), 0.65)),
			ColorSequenceKeypoint.new(1, color),
		})
	end)
	local pageHost = new("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 12, 0, PAGE_TOP),
		Size = UDim2.new(1, -24, 1, -(PAGE_TOP + 12)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = panel,
	})
	local chromeRest = {header = header.Position, tabs = tabBar.Position, pages = pageHost.Position}
	local function revealChrome(delay)
		header.Position = chromeRest.header + UDim2.fromOffset(0, -10)
		tabBar.Position = chromeRest.tabs + UDim2.fromOffset(0, -8)
		pageHost.Position = chromeRest.pages + UDim2.fromOffset(0, 10)
		tween(header, 0.65, {Position = chromeRest.header}, ES.Quint, ED.Out, delay)
		tween(tabBar, 0.65, {Position = chromeRest.tabs}, ES.Quint, ED.Out, delay + 0.04)
		tween(pageHost, 0.65, {Position = chromeRest.pages}, ES.Quint, ED.Out, delay + 0.08)
	end
	local function hideChrome()
		tween(header, 0.22, {Position = chromeRest.header + UDim2.fromOffset(0, -6)}, ES.Quad, ED.In)
		tween(tabBar, 0.22, {Position = chromeRest.tabs + UDim2.fromOffset(0, -4)}, ES.Quad, ED.In)
		tween(pageHost, 0.22, {Position = chromeRest.pages + UDim2.fromOffset(0, 6)}, ES.Quad, ED.In)
	end
	local fadeBottom = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = T.black,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = pageHost,
	})
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = fadeBottom,
	})
	local embers = new("Frame", {
		Name = "Embers",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 6,
		Parent = panel,
	})
	do
		local haze = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = embers,
		})
		local hazeGradient = new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.7, 1),
				NumberSequenceKeypoint.new(1, 0.86),
			}),
			Parent = haze,
		})
		bindAccent(function(color)
			hazeGradient.Color = ColorSequence.new(color)
		end)
		local function spawnSpark()
			if not embers.Parent then return end
			local size = math.random(2, 4)
			local x = math.random()
			local drift = (math.random() - 0.5) * 0.14
			local travel = 0.4 + math.random() * 0.5
			local life = 3 + math.random() * 3
			local spark = new("Frame", {
				BackgroundColor3 = lerpColor(accent, Color3.new(1, 0.85, 0.6), math.random() * 0.6),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				Position = UDim2.new(x, 0, 1.02, 0),
				Parent = embers,
			})
			round(spark)
			tween(spark, life, {Position = UDim2.new(x + drift, 0, 1.02 - travel, 0)}, ES.Sine, ED.Out)
			tween(spark, 0.6, {BackgroundTransparency = 0.3}, ES.Quad, ED.Out)
			task.delay(life * 0.55, function()
				if spark.Parent then
					tween(spark, life * 0.45, {BackgroundTransparency = 1}, ES.Linear, ED.In)
				end
			end)
			task.delay(life + 0.1, function()
				spark:Destroy()
			end)
		end
		for _ = 1, isTouch and 5 or 9 do
			task.spawn(function()
				task.wait(math.random() * 4)
				while alive do
					if fx.embers and state == "expanded" then
						spawnSpark()
						task.wait(2.5 + math.random() * 3.5)
					else
						task.wait(0.6)
					end
				end
			end)
		end
	end
	local function applyFX()
		neonLine.BackgroundTransparency = fx.neon and 0 or 1
		titleGradient.Enabled = fx.shimmer
		embers.Visible = fx.embers
		for _, blob in ipairs(auroraBlobs) do
			blob.frame.Visible = fx.aurora
		end
	end
	local Tab = {}
	Tab.__index = Tab
	local tabs = {}
	local currentTab = nil
	local hlToken = 0
	local function moveHighlight(index, instant)
		local n = math.max(#tabs, 1)
		local toX = (index - 1) / n
		local restSize = UDim2.new(1 / n, -6, 1, -6)
		if instant then
			highlight.Position = UDim2.new(toX, 3, 0, 3)
			highlight.Size = restSize
			return
		end
		hlToken = hlToken + 1
		local token = hlToken
		local fromX = highlight.Position.X.Scale
		local dist = math.abs(toX - fromX)
		tween(highlight, 0.16, {
			Position = UDim2.new(math.min(fromX, toX), 3, 0, 3),
			Size = UDim2.new(1 / n + dist, -6, 1, -6),
		}, ES.Quad, ED.Out)
		task.delay(0.15, function()
			if token ~= hlToken or not alive then return end
			tween(highlight, 0.45, {Position = UDim2.new(toX, 3, 0, 3), Size = restSize}, ES.Back, ED.Out)
		end)
	end
	local function layoutTabs()
		local n = #tabs
		for i, tab in ipairs(tabs) do
			tab.button.Position = UDim2.new((i - 1) / n, 0, 0, 0)
			tab.button.Size = UDim2.new(1 / n, 0, 1, 0)
		end
		if currentTab then
			moveHighlight(currentTab.index, true)
		end
	end
	local SLIDE_T = 0.42
	local function slideOut(tab, dir)
		tab.slideTok = tab.slideTok + 1
		local tok = tab.slideTok
		tab.page.ZIndex = 2
		tween(tab.page, SLIDE_T, {Position = UDim2.fromScale(-dir, 0)}, ES.Quint, ED.Out)
		task.delay(SLIDE_T + 0.04, function()
			if tab.slideTok == tok and alive and currentTab ~= tab then
				tab.page.Visible = false
				tab.page.Position = UDim2.new()
			end
		end)
	end
	local function slideIn(tab, dir)
		tab.slideTok = tab.slideTok + 1
		tab.page.ZIndex = 3
		if dir == 0 then
			tab.page.Position = UDim2.new()
			tab.page.Visible = true
			return
		end
		if not tab.page.Visible then
			tab.page.Position = UDim2.fromScale(dir, 0)
			tab.page.Visible = true
		end
		tween(tab.page, SLIDE_T, {Position = UDim2.new()}, ES.Quint, ED.Out)
		for i, entry in ipairs(tab.cards) do
			task.delay(0.1 + math.min(i, 10) * 0.04, entry.sweep)
		end
	end
	local function selectTab(tab)
		if currentTab == tab then return end
		local old = currentTab
		currentTab = tab
		local dir = 0
		if old then
			dir = tab.index > old.index and 1 or -1
			tween(old.button, 0.3, {TextColor3 = T.muted})
			slideOut(old, dir)
		end
		tween(tab.button, 0.3, {TextColor3 = T.text})
		moveHighlight(tab.index)
		slideIn(tab, dir)
	end
	local function addTab(name)
		local tab = setmetatable({Name = name, cards = {}, n = 0, index = #tabs + 1, slideTok = 0}, Tab)
		local button = new("TextButton", {
			Name = name,
			BackgroundTransparency = 1,
			Text = name,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = T.muted,
			AutoButtonColor = false,
			ZIndex = 4,
			Parent = tabBar,
		})
		local page = new("Frame", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = pageHost,
		})
		local scroll = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = page,
		})
		new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 26),
			Parent = scroll,
		})
		bindAccent(function(color)
			scroll.ScrollBarImageColor3 = color
		end)
		button.MouseEnter:Connect(function()
			if currentTab ~= tab then
				tween(button, 0.25, {TextColor3 = T.text})
			end
		end)
		button.MouseLeave:Connect(function()
			if currentTab ~= tab then
				tween(button, 0.35, {TextColor3 = T.muted})
			end
		end)
		button.MouseButton1Click:Connect(function()
			playClick(1.05, 0.8)
			selectTab(tab)
		end)
		tab.button, tab.page, tab.scroll = button, page, scroll
		table.insert(tabs, tab)
		layoutTabs()
		return tab
	end
	local function fire(callback, ...)
		if not callback then return end
		local ok, err = pcall(callback, ...)
		if not ok then
			notify("Callback error", tostring(err), 5, "error")
		end
	end
	local function baseCard(tab, height, name, silent)
		local c = {}
		tab.n = tab.n + 1
		local slot = new("Frame", {
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			LayoutOrder = tab.n,
			Parent = tab.scroll,
		})
		local card = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.card,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Parent = slot,
		})
		corner(card, 12)
		local strokeObj = new("UIStroke", {
			Color = T.stroke,
			Thickness = 1,
			Transparency = 0.2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = card,
		})
		c.slot, c.card, c.stroke = slot, card, strokeObj
		if tab.capture then
			table.insert(tab.capture, {slot = slot, frame = card})
		end
		c.title = new("TextLabel", {
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -110, 0, math.min(height, 40)),
			BackgroundTransparency = 1,
			Text = name or "",
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = card,
		})
		c.hit = new("TextButton", {
			Name = "Hit",
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
			Parent = card,
		})
		local overlay = new("Frame", {
			Name = "FX",
			BackgroundColor3 = accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true,
			ZIndex = 5,
			Parent = card,
		})
		corner(overlay, 12)
		local sweepFrame = new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.26, 0, 2, 0),
			Position = UDim2.fromScale(-0.3, 0.5),
			Rotation = 18,
			ZIndex = 5,
			Parent = overlay,
		})
		local sweepGradient = new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.8),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = sweepFrame,
		})
		bindAccent(function(color)
			overlay.BackgroundColor3 = color
			sweepGradient.Color = ColorSequence.new(color)
		end)
		local sweeping = false
		function c.sweep()
			if sweeping or not sweepFrame.Parent then return end
			sweeping = true
			sweepFrame.Position = UDim2.fromScale(-0.3, 0.5)
			tween(sweepFrame, 0.8, {Position = UDim2.fromScale(1.3, 0.5)}, ES.Quad, ED.InOut)
			task.delay(0.85, function()
				sweeping = false
			end)
		end
		function c.flash()
			overlay.BackgroundTransparency = 0.82
			tween(overlay, 0.5, {BackgroundTransparency = 1}, ES.Quad, ED.Out)
		end
		function c.ripple(px)
			local s = math.max(shellScale.Scale, 0.01)
			local relX = (px - card.AbsolutePosition.X) / s
			local circle = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(relX, card.AbsoluteSize.Y / s / 2),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Parent = overlay,
			})
			round(circle)
			local big = card.AbsoluteSize.X / s * 2.2
			tween(circle, 0.65, {Size = UDim2.fromOffset(big, big), BackgroundTransparency = 1}, ES.Quart, ED.Out)
			task.delay(0.7, function()
				circle:Destroy()
			end)
		end
		c.hit.MouseEnter:Connect(function()
			tween(card, 0.3, {BackgroundColor3 = T.cardHover})
			tween(strokeObj, 0.3, {Color = accent, Transparency = 0.35})
			c.sweep()
		end)
		c.hit.MouseLeave:Connect(function()
			tween(card, 0.45, {BackgroundColor3 = T.card})
			tween(strokeObj, 0.45, {Color = T.stroke, Transparency = 0.2})
		end)
		c.hit.InputBegan:Connect(function(input)
			if isPress(input) then
				c.ripple(input.Position.X)
			end
		end)
		if not silent then
			c.hit.MouseButton1Click:Connect(function()
				playClick()
			end)
		end
		table.insert(tab.cards, {frame = card, rest = UDim2.new(), sweep = c.sweep})
		return c
	end
	local solidButtons = setmetatable({}, {__mode = "k"})
	bindAccent(function(color)
		for b in pairs(solidButtons) do
			if b.Parent then
				b.BackgroundColor3 = color
			end
		end
	end)
	local function smallButton(parent, text, width, solid)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(width, 28),
			BackgroundColor3 = solid and accent or T.btn,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = solid and Color3.new(1, 1, 1) or T.muted,
			AutoButtonColor = false,
			ZIndex = 6,
			Parent = parent,
		})
		corner(b, 8)
		if solid then
			solidButtons[b] = true
		else
			new("UIStroke", {
				Color = T.stroke,
				Thickness = 1,
				Transparency = 0.3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = b,
			})
		end
		local press = new("UIScale", {Scale = 1, Parent = b})
		b.InputBegan:Connect(function(input)
			if isPress(input) then
				tween(press, 0.09, {Scale = 0.9}, ES.Quad, ED.Out)
			end
		end)
		b.InputEnded:Connect(function(input)
			if isPress(input) then
				tween(press, 0.4, {Scale = 1}, ES.Back, ED.Out)
			end
		end)
		b.MouseLeave:Connect(function()
			tween(press, 0.3, {Scale = 1}, ES.Back, ED.Out)
		end)
		return b
	end
	function Tab:Section(text)
		self.n = self.n + 1
		local slot = new("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			LayoutOrder = self.n,
			Parent = self.scroll,
		})
		local rest = UDim2.fromOffset(4, 4)
		local label = new("TextLabel", {
			Position = rest,
			Size = UDim2.new(1, -8, 1, -4),
			BackgroundTransparency = 1,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = slot,
		})
		bindAccent(function(color)
			label.TextColor3 = color
		end)
		table.insert(self.cards, {frame = label, rest = rest, sweep = function() end})
	end
	function Tab:Label(text)
		local c = baseCard(self, 34, "", true)
		c.title.Size = UDim2.new(1, -28, 1, 0)
		c.title.Text = text
		c.title.TextColor3 = T.muted
		c.title.Font = Enum.Font.Gotham
		c.title.TextSize = 12
		local object = {}
		function object:Set(newText)
			c.title.Text = newText
		end
		return object
	end
	function Tab:Button(opts)
		local c = baseCard(self, 40, opts.Name)
		local arrow = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Text = ">",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = accent,
			ZIndex = 2,
			Parent = c.card,
		})
		bindAccent(function(color)
			arrow.TextColor3 = color
		end)
		c.hit.MouseButton1Click:Connect(function()
			tween(arrow, 0.12, {Position = UDim2.new(1, -7, 0.5, 0)})
			task.delay(0.12, function()
				tween(arrow, 0.45, {Position = UDim2.new(1, -14, 0.5, 0)}, ES.Back, ED.Out)
			end)
			fire(opts.Callback)
		end)
	end
	function Tab:Foldout(opts)
		local c = baseCard(self, 40, opts.Name)
		local arrow = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text = "↓",
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = accent,
			ZIndex = 2,
			Parent = c.card,
		})
		bindAccent(function(color)
			arrow.TextColor3 = color
		end)
		local group = {}
		self.capture = group
		fire(opts.Build, self)
		self.capture = nil
		local open = opts.Open and true or false
		local function apply(animate)
			arrow.Text = open and "↑" or "↓"
			for i, entry in ipairs(group) do
				entry.slot.Visible = open
				if open and animate then
					entry.frame.Position = UDim2.fromOffset(0, -10)
					tween(entry.frame, 0.4, {Position = UDim2.new()}, ES.Quint, ED.Out, i * 0.03)
				end
			end
		end
		apply(false)
		c.hit.MouseButton1Click:Connect(function()
			open = not open
			apply(true)
		end)
		local object = {}
		function object:Set(value)
			open = value and true or false
			apply(true)
		end
		function object:Get()
			return open
		end
		return object
	end
	function Tab:Toggle(opts)
		local c = baseCard(self, 40, opts.Name)
		local on = opts.Default and true or false
		local track = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(44, 26),
			BackgroundColor3 = T.off,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = c.card,
		})
		round(track)
		local knob = new("Frame", {
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track,
		})
		round(knob)
		local function render(duration, pressed)
			local kw = pressed and 28 or 22
			local kx = on and (44 - 2 - kw) or 2
			tween(track, duration, {BackgroundColor3 = on and accent or T.off})
			tween(knob, duration, {Size = UDim2.fromOffset(kw, 22), Position = UDim2.fromOffset(kx, 2)}, ES.Back, ED.Out)
		end
		render(0, false)
		bindAccent(function()
			if on then
				track.BackgroundColor3 = accent
			end
		end)
		local object = {}
		function object:Set(value, silent)
			on = value and true or false
			render(0.3, false)
			if not silent then
				fire(opts.Callback, on)
			end
		end
		function object:Get()
			return on
		end
		c.hit.MouseButton1Down:Connect(function()
			render(0.15, true)
		end)
		c.hit.MouseLeave:Connect(function()
			render(0.25, false)
		end)
		c.hit.MouseButton1Click:Connect(function()
			object:Set(not on)
		end)
		return object
	end
	function Tab:Slider(opts)
		local min, max = opts.Min or 0, opts.Max or 100
		local step = opts.Step or 1
		local suffix = opts.Suffix or ""
		local c = baseCard(self, 58, opts.Name, true)
		c.title.Size = UDim2.new(1, -100, 0, 32)
		c.hit.Position = UDim2.new(0, 0, 0, 28)
		c.hit.Size = UDim2.new(1, 0, 1, -28)
		local valueLabel = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 5),
			Size = UDim2.fromOffset(78, 24),
			BackgroundColor3 = T.input,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = accent,
			PlaceholderText = "0",
			PlaceholderColor3 = T.muted,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 6,
			Parent = c.card,
		})
		corner(valueLabel, 8)
		local valueStroke = new("UIStroke", {
			Color = T.stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = valueLabel,
		})
		local track = new("Frame", {
			Position = UDim2.new(0, 14, 1, -20),
			Size = UDim2.new(1, -28, 0, 6),
			BackgroundColor3 = T.track,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = c.card,
		})
		round(track)
		local fill = new("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		})
		round(fill)
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = fill,
		})
		round(knob)
		local knobStroke = new("UIStroke", {
			Color = accent,
			Thickness = 3,
			Transparency = 0.6,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = knob,
		})
		bindAccent(function(color)
			fill.BackgroundColor3 = color
			valueLabel.TextColor3 = color
			knobStroke.Color = color
		end)
		local value
		local function setValue(v, silent)
			v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
			v = tonumber(string.format("%.4f", v))
			local changed = v ~= value
			value = v
			tween(fill, 0.1, {Size = UDim2.fromScale((v - min) / (max - min), 1)}, ES.Quad, ED.Out)
			valueLabel.Text = string.format("%g", v) .. suffix
			if changed and not silent then
				fire(opts.Callback, v)
			end
		end
		setValue(opts.Default or min, true)
		local function setTyped(v)
			v = math.max(min, v)
			v = tonumber(string.format("%.4f", v))
			local changed = v ~= value
			value = v
			tween(fill, 0.1, {Size = UDim2.fromScale(math.clamp((v - min) / (max - min), 0, 1), 1)}, ES.Quad, ED.Out)
			valueLabel.Text = string.format("%g", v) .. suffix
			if changed then
				fire(opts.Callback, v)
			end
		end
		valueLabel.Focused:Connect(function()
			playClick(1.05, 0.7)
			tween(valueStroke, 0.25, {Color = accent})
			valueLabel.Text = string.format("%g", value)
		end)
		valueLabel.FocusLost:Connect(function()
			tween(valueStroke, 0.35, {Color = T.stroke})
			local cleaned = string.gsub(valueLabel.Text, ",", ".")
			cleaned = string.gsub(cleaned, "[^%d%.%-]", "")
			local number = tonumber(cleaned)
			if number and number == number and math.abs(number) < 1e6 then
				setTyped(number)
			else
				valueLabel.Text = string.format("%g", value) .. suffix
			end
		end)
		local dragging = false
		local function updateFromX(x)
			local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			setValue(min + (max - min) * a)
		end
		local dragInput = nil
		local pending = nil
		local TOUCH = Enum.UserInputType.Touch
		local function startDrag(input)
			dragging = true
			dragInput = input
			pending = nil
			self.scroll.ScrollingEnabled = false
			tween(knob, 0.2, {Size = UDim2.fromOffset(19, 19)}, ES.Back, ED.Out)
			tween(knobStroke, 0.2, {Thickness = 6, Transparency = 0.7})
			updateFromX(input.Position.X)
		end
		local function endDrag()
			dragging = false
			dragInput = nil
			self.scroll.ScrollingEnabled = true
			tween(knob, 0.3, {Size = UDim2.fromOffset(14, 14)}, ES.Back, ED.Out)
			tween(knobStroke, 0.3, {Thickness = 3, Transparency = 0.6})
		end
		c.hit.InputBegan:Connect(function(input)
			if not isPress(input) then return end
			if input.UserInputType == TOUCH then
				pending = {
					input = input,
					x = input.Position.X,
					y = input.Position.Y,
					scrollY = self.scroll.CanvasPosition.Y,
				}
			else
				playClick(1.1, 0.6)
				startDrag(input)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging then
				if isMove(input) and (input.UserInputType ~= TOUCH or input == dragInput) then
					updateFromX(input.Position.X)
				end
			elseif pending and input == pending.input then
				local dx = math.abs(input.Position.X - pending.x)
				local dy = math.abs(input.Position.Y - pending.y)
				if dx >= 8 and dx > dy then
					playClick(1.1, 0.6)
					startDrag(input)
				elseif dy >= 8 then
					pending = nil
				end
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if dragging then
				if isPress(input) and (input.UserInputType ~= TOUCH or input == dragInput) then
					endDrag()
				end
			elseif pending and input == pending.input then
				local still = math.abs(input.Position.X - pending.x) < 8 and math.abs(input.Position.Y - pending.y) < 8
				if still and self.scroll.CanvasPosition.Y == pending.scrollY then
					playClick(1.1, 0.6)
					updateFromX(input.Position.X)
				end
				pending = nil
			end
		end)
		local object = {}
		function object:Set(v)
			setValue(v)
		end
		function object:Get()
			return value
		end
		return object
	end
	function Tab:Dropdown(opts)
		local options = opts.Options or {}
		local rowH, headH = 30, 40
		local c = baseCard(self, headH, opts.Name)
		c.card.ClipsDescendants = true
		c.hit.Size = UDim2.new(1, 0, 0, headH)
		c.title.Size = UDim2.new(1, -170, 0, headH)
		local current = opts.Default or options[1]
		local valueLabel = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -34, 0, 0),
			Size = UDim2.new(0, 130, 0, headH),
			BackgroundTransparency = 1,
			Text = tostring(current),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = T.muted,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 2,
			Parent = c.card,
		})
		local arrow = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Text = ">",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = accent,
			ZIndex = 2,
			Parent = c.card,
		})
		local list = new("Frame", {
			Position = UDim2.new(0, 8, 0, headH),
			Size = UDim2.new(1, -16, 0, #options * rowH),
			BackgroundTransparency = 1,
			Parent = c.card,
		})
		new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
		local buttons = {}
		local function refresh()
			for option, button in pairs(buttons) do
				tween(button, 0.2, {TextColor3 = option == current and accent or T.muted})
			end
		end
		bindAccent(function(color)
			arrow.TextColor3 = color
			for option, button in pairs(buttons) do
				if option == current then
					button.TextColor3 = color
				end
				button.BackgroundColor3 = color
			end
		end)
		local open = false
		local function setOpen(value)
			open = value
			tween(c.slot, 0.4, {Size = UDim2.new(1, 0, 0, value and (headH + #options * rowH + 8) or headH)}, ES.Quint, ED.Out)
			tween(arrow, 0.35, {Rotation = value and 90 or 0}, ES.Back, ED.Out)
		end
		for index, option in ipairs(options) do
			local button = new("TextButton", {
				Size = UDim2.new(1, 0, 0, rowH),
				BackgroundColor3 = accent,
				BackgroundTransparency = 1,
				Text = "   " .. tostring(option),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = option == current and accent or T.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				LayoutOrder = index,
				ZIndex = 6,
				Parent = list,
			})
			corner(button, 8)
			buttons[option] = button
			button.MouseEnter:Connect(function()
				tween(button, 0.2, {BackgroundTransparency = 0.82})
			end)
			button.MouseLeave:Connect(function()
				tween(button, 0.3, {BackgroundTransparency = 1})
			end)
			button.MouseButton1Click:Connect(function()
				playClick(1.1, 0.8)
				current = option
				valueLabel.Text = tostring(option)
				refresh()
				fire(opts.Callback, option)
				setOpen(false)
			end)
		end
		c.hit.MouseButton1Click:Connect(function()
			setOpen(not open)
		end)
		local object = {}
		function object:Get()
			return current
		end
		function object:Set(option)
			if buttons[option] then
				current = option
				valueLabel.Text = tostring(option)
				refresh()
				fire(opts.Callback, option)
			end
		end
		return object
	end
	function Tab:Input(opts)
		local c = baseCard(self, 40, opts.Name, true)
		c.title.Size = UDim2.new(1, -180, 1, 0)
		local box = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(150, 28),
			BackgroundColor3 = T.input,
			Text = opts.Default or "",
			PlaceholderText = opts.Placeholder or "...",
			PlaceholderColor3 = T.muted,
			TextColor3 = T.text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			ClearTextOnFocus = false,
			ZIndex = 6,
			Parent = c.card,
		})
		corner(box, 8)
		local boxStroke = new("UIStroke", {
			Color = T.stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = box,
		})
		box.Focused:Connect(function()
			playClick(1.05, 0.7)
			tween(boxStroke, 0.25, {Color = accent})
		end)
		box.FocusLost:Connect(function()
			tween(boxStroke, 0.35, {Color = T.stroke})
			fire(opts.Callback, box.Text)
		end)
		local object = {}
		function object:Get()
			return box.Text
		end
		function object:Set(text)
			box.Text = tostring(text)
		end
		return object
	end
	function Tab:Keybind(opts)
		local NONE = Enum.KeyCode.Unknown
		local key = opts.Default or Enum.KeyCode.F
		local listening = false
		local function label()
			return key == NONE and "None" or key.Name
		end
		local c = baseCard(self, 40, opts.Name)
		local button = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(104, 28),
			BackgroundColor3 = T.input,
			Text = label(),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = accent,
			AutoButtonColor = false,
			ZIndex = 6,
			Parent = c.card,
		})
		corner(button, 8)
		local buttonStroke = new("UIStroke", {
			Color = T.stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = button,
		})
		bindAccent(function(color)
			button.TextColor3 = color
		end)
		button.MouseButton1Click:Connect(function()
			playClick(1.05, 0.8)
			listening = true
			button.Text = "..."
			tween(buttonStroke, 0.25, {Color = accent})
		end)
		connect(UserInputService.InputBegan, function(input, processed)
			if listening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					local cancelled = input.KeyCode == Enum.KeyCode.Escape
					if input.KeyCode == Enum.KeyCode.Backspace then
						key = NONE
					elseif not cancelled then
						key = input.KeyCode
					end
					listening = false
					button.Text = label()
					tween(buttonStroke, 0.35, {Color = T.stroke})
					if not cancelled then
						fire(opts.Changed, key)
					end
				end
			elseif not processed and key ~= NONE and input.KeyCode == key then
				c.flash()
				fire(opts.Callback, key)
			end
		end)
		local object = {}
		function object:Get()
			return key
		end
		function object:Set(newKey, silent)
			key = newKey or NONE
			button.Text = label()
			if not silent then
				fire(opts.Changed, key)
			end
		end
		return object
	end
	local tabTech = addTab("Combat")
	local ExtraTabs = {Macro = addTab("Macro"), Visuals = addTab("Visuals"), Rage = addTab("Rage")}
	local tabMisc = addTab("Misc")
	local tabSettings = addTab("Settings")
	local function buildCombat(tab)
		-- =========================================
		-- COMBAT: SLIDE M1
		-- (dibungkus do...end supaya tidak menambah jumlah local di Main)
		-- =========================================
		do
			local slideM1Enabled = false
			local slideAnimConnection = nil
			local slideCharConnection = nil

			local slideTargetIDs = {
				["10480796021"] = true,
				["10480793962"] = true,
			}

			local function stopSlideAnim()
				if slideAnimConnection then
					slideAnimConnection:Disconnect()
					slideAnimConnection = nil
				end
			end

			local function stopSlideM1()
				slideM1Enabled = false
				stopSlideAnim()
				if slideCharConnection then
					slideCharConnection:Disconnect()
					slideCharConnection = nil
				end
			end

			local function setupSlideM1(character)
				stopSlideAnim()

				local humanoid = character:WaitForChild("Humanoid", 5)
				local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
				local remote = character:FindFirstChild("Communicate")

				if not humanoid or not animator or not remote then
					return
				end

				local lastTrigger = 0

				slideAnimConnection = animator.AnimationPlayed:Connect(function(track)
					if not slideM1Enabled then
						return
					end

					local animation = track.Animation
					local id = animation and animation.AnimationId:match("%d+")

					if id and slideTargetIDs[id] and os.clock() - lastTrigger >= 1.5 then
						lastTrigger = os.clock()

						pcall(function()
							remote:FireServer({
								Mobile = true,
								Goal = "LeftClick"
							})

							remote:FireServer({
								Goal = "LeftClickRelease",
								Mobile = true
							})
						end)
					end
				end)
			end

			-- Dipanggil saat "Destroy GUI": matikan Slide M1
			table.insert(connections, {
				Disconnect = function()
					pcall(stopSlideM1)
				end,
			})

			tab:Section("Local")

			tab:Toggle({
				Name = "Slide M1",
				Default = false,
				Callback = function(state)
					if not state then
						stopSlideM1()
						return
					end

					slideM1Enabled = true

					if LocalPlayer.Character then
						setupSlideM1(LocalPlayer.Character)
					end

					if slideCharConnection then
						slideCharConnection:Disconnect()
					end

					slideCharConnection = LocalPlayer.CharacterAdded:Connect(function(character)
						task.wait(1)

						if slideM1Enabled then
							setupSlideM1(character)
						end
					end)
				end
			})
		end
	end
	buildCombat(tabTech)

	-- Services untuk fitur Anti Lag.
	local WorkspaceService = svc("Workspace")
	local LightingService = svc("Lighting")
	local ReplicatedStorageService = svc("ReplicatedStorage")

	ExtraTabs.Visuals:Section("Anti Lag")
	-- TSB VISUAL PACK — AI TRAP EDITION (diambil dari RXM_HUB_lua__1_; dibungkus do...end supaya tidak menambah local di Main)
	do
		local visualPackEnabled = false
		local visualPackConnections = {}
		local visualSkyIds = {
			Bk = 92959017845968, Ft = 129304841254693, Lf = 129249062260004,
			Rt = 117319232583147, Up = 121193772599100, Dn = 115022734343595,
		}
		local visualOldLighting, visualOldSky, visualOldAtmosphere, visualOldClouds
		local visualOldEffects = {}
		local visualOldHeroEffects = {}
		local visualApplying = false
		local visualTerrain = WorkspaceService:FindFirstChildOfClass("Terrain")

		local function disconnectVisualPack()
			for _, connection in ipairs(visualPackConnections) do pcall(function() connection:Disconnect() end) end
			table.clear(visualPackConnections)
		end

		local function visualSafeConnect(signal, callback)
			local ok, connection = pcall(function() return signal:Connect(callback) end)
			if ok and connection then table.insert(visualPackConnections, connection) end
		end

		local function applyHeroHunterEffect(object)
			if not object or not (object:IsA("Trail") or object:IsA("ParticleEmitter")) then return end
			if not visualOldHeroEffects[object] then
				visualOldHeroEffects[object] = {Color = object.Color, Texture = object:IsA("Trail") and object.Texture or nil, LightEmission = object.LightEmission}
			end
			pcall(function()
				object.Color = ColorSequence.new(Color3.fromRGB(0, 85, 190))
				if object:IsA("Trail") then object.Texture = "" end
				object.LightEmission = object:IsA("Trail") and 0.8 or 0.75
			end)
		end

		local function applyVisualPack()
			if not visualPackEnabled or visualApplying then return end
			visualApplying = true
			pcall(function()
				LightingService.ClockTime = 12
				LightingService.GlobalShadows = false
				LightingService.Brightness = 0.8
				LightingService.ExposureCompensation = -0.2
				LightingService.FogStart, LightingService.FogEnd = 9e9, 9e9
				local sky = LightingService:FindFirstChildOfClass("Sky")
				if not sky then sky = Instance.new("Sky"); sky.Name = "RXM_TSB_VisualSky"; sky.Parent = LightingService end
				for key, assetId in pairs(visualSkyIds) do sky["Skybox" .. key] = "rbxassetid://" .. tostring(assetId) end
				sky.SunAngularSize, sky.SunTextureId, sky.MoonAngularSize, sky.MoonTextureId = 0, "", 0, ""
				for _, effect in ipairs(LightingService:GetChildren()) do
					if effect:IsA("Atmosphere") then
						if visualOldAtmosphere and not visualOldAtmosphere[effect] then visualOldAtmosphere[effect] = {Density = effect.Density, Haze = effect.Haze, Glare = effect.Glare} end
						effect.Density, effect.Haze, effect.Glare = 0, 0, 0
					elseif effect:IsA("PostEffect") or effect:IsA("SunRaysEffect") then
						if visualOldEffects and visualOldEffects[effect] == nil then visualOldEffects[effect] = effect.Enabled end
						effect.Enabled = false
					end
				end
				if visualTerrain then
					for _, cloud in ipairs(visualTerrain:GetChildren()) do
						if cloud:IsA("Clouds") then
							if visualOldClouds and visualOldClouds[cloud] == nil then visualOldClouds[cloud] = cloud.Enabled end
							cloud.Enabled = false
						end
					end
				end
				local function hookCharacter(character)
					for _, object in ipairs(character:GetDescendants()) do
						if object:IsA("Trail") or object:IsA("ParticleEmitter") then applyHeroHunterEffect(object) end
					end
					-- daftar karakter yang sudah di-hook disimpan di visualPackConnections.hooked
					-- (otomatis terhapus saat Visual Pack dimatikan; tidak menambah local di Main)
					local hooked = visualPackConnections.hooked
					if not hooked then hooked = setmetatable({}, {__mode = "k"}); visualPackConnections.hooked = hooked end
					if hooked[character] then return end
					hooked[character] = true
					visualSafeConnect(character.DescendantAdded, function(object)
						if visualPackEnabled and (object:IsA("Trail") or object:IsA("ParticleEmitter")) then applyHeroHunterEffect(object) end
					end)
				end
				if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
			end)
			visualApplying = false
		end

		local function enableVisualPack(enabled)
			if visualPackEnabled == enabled then return end
			visualPackEnabled = enabled
			if enabled then
				visualOldLighting = {ClockTime = LightingService.ClockTime, Brightness = LightingService.Brightness, ExposureCompensation = LightingService.ExposureCompensation, GlobalShadows = LightingService.GlobalShadows, FogStart = LightingService.FogStart, FogEnd = LightingService.FogEnd}
				local oldSky = LightingService:FindFirstChildOfClass("Sky")
				visualOldSky = oldSky and oldSky:Clone() or nil
				visualOldAtmosphere, visualOldEffects, visualOldHeroEffects = {}, {}, {}
				for _, object in ipairs(LightingService:GetChildren()) do
					if object:IsA("Atmosphere") then visualOldAtmosphere[object] = {Density=object.Density, Haze=object.Haze, Glare=object.Glare}
					elseif object:IsA("PostEffect") or object:IsA("SunRaysEffect") then visualOldEffects[object] = object.Enabled end
				end
				visualOldClouds = {}
				if visualTerrain then for _, cloud in ipairs(visualTerrain:GetChildren()) do if cloud:IsA("Clouds") then visualOldClouds[cloud] = cloud.Enabled end end end
				applyVisualPack()
				visualSafeConnect(LocalPlayer.CharacterAdded, function(character)
					-- Mati / reset / respawn: pasang ulang langsung (detik 0), lalu ulangi di ~0.6s, ~1.5s, ~3s
					-- supaya tidak kalah dengan game yang me-reset Lighting / efek sesudah karakter spawn.
					for _, delay in ipairs({0, 0.6, 0.9, 1.5}) do
						if delay > 0 then task.wait(delay) end
						if not visualPackEnabled or LocalPlayer.Character ~= character then return end
						applyVisualPack()
					end
				end)
				visualSafeConnect(LightingService.ChildAdded, function(child)
					if not visualPackEnabled then return end
					if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") or child:IsA("SunRaysEffect") then task.defer(applyVisualPack) end
				end)
				if visualTerrain then visualSafeConnect(visualTerrain.ChildAdded, function(child) if visualPackEnabled and child:IsA("Clouds") then child.Enabled = false end end) end
			else
				disconnectVisualPack()
				pcall(function()
					if visualOldLighting then for key, value in pairs(visualOldLighting) do LightingService[key] = value end end
					local currentSky = LightingService:FindFirstChildOfClass("Sky"); if currentSky then currentSky:Destroy() end
					if visualOldSky then visualOldSky:Clone().Parent = LightingService end
					for object, values in pairs(visualOldAtmosphere or {}) do if object and object.Parent then for key, value in pairs(values) do object[key] = value end end end
					for object, wasEnabled in pairs(visualOldEffects or {}) do if object and object.Parent then object.Enabled = wasEnabled end end
					for cloud, wasEnabled in pairs(visualOldClouds or {}) do if cloud and cloud.Parent then cloud.Enabled = wasEnabled end end
					for object, values in pairs(visualOldHeroEffects or {}) do if object and object.Parent then pcall(function() object.Color = values.Color; if object:IsA("Trail") then object.Texture = values.Texture end; object.LightEmission = values.LightEmission end) end end
				end)
				visualOldLighting, visualOldSky, visualOldAtmosphere, visualOldClouds, visualOldEffects, visualOldHeroEffects = nil, nil, nil, nil, {}, {}
			end
		end
		ExtraTabs.Visuals:Toggle({Name = "TSB VISUAL PACK (AI TRAP / NO SUN)", Default = false, Callback = enableVisualPack})
	end

	local performanceEnabled = false
	local ultraPreferenceEnabled = false
	local superAntiLagEnabled = false
	local miscPersistentConnections = {}
	local maxPerformanceStepConnection
	local ultraPreferenceConnection
	local superAntiLagConnections = {}
	local superSavedEnabled = {}
	local superSavedCastShadow = {}
	local superOldGlobalShadows
	local effectClasses = {
		ParticleEmitter = true, Trail = true, Beam = true,
		Fire = true, Smoke = true, Sparkles = true,
	}

	local function keepMiscConnection(signal, callback, bucket)
		local connection = signal:Connect(callback)
		table.insert(bucket or miscPersistentConnections, connection)
		return connection
	end
	local function disconnectMiscList(list)
		for i = #list, 1, -1 do
			local connection = list[i]
			pcall(function() if connection then connection:Disconnect() end end)
			list[i] = nil
		end
	end
	local function removeNamedChildren(root, token)
		if not root then return end
		for _, child in ipairs(root:GetChildren()) do
			if string.find(string.lower(child.Name), string.lower(token), 1, true) then
				pcall(function() child:Destroy() end)
			else
				removeNamedChildren(child, token)
			end
		end
	end
	local function removeNamedNewChild(root, token)
		keepMiscConnection(root.ChildAdded, function(child)
			if performanceEnabled and string.find(string.lower(child.Name), string.lower(token), 1, true) then
				pcall(function() child:Destroy() end)
			end
		end)
	end
	-- Keep the original script's automatic cleanup for newly added Effect/MeshPart objects.
	removeNamedNewChild(WorkspaceService, "Effect")
	removeNamedNewChild(ReplicatedStorageService, "Effect")
	removeNamedNewChild(WorkspaceService, "MeshPart")
	removeNamedNewChild(ReplicatedStorageService, "MeshPart")

	ExtraTabs.Visuals:Toggle({Name = "MAX PERFORMANCE", Default = false, Callback = function(enabled)
		local ok, err = pcall(function()
			performanceEnabled = enabled
			if enabled then
				removeNamedChildren(WorkspaceService, "Effect")
				removeNamedChildren(ReplicatedStorageService, "Effect")
				removeNamedChildren(WorkspaceService, "MeshPart")
				removeNamedChildren(ReplicatedStorageService, "MeshPart")
				if maxPerformanceStepConnection then maxPerformanceStepConnection:Disconnect(); maxPerformanceStepConnection = nil end
				maxPerformanceStepConnection = RunService.Stepped:Connect(function()
					if not performanceEnabled then return end
					pcall(function()
						local thrown = WorkspaceService:FindFirstChild("Thrown")
						if thrown then
							for _, object in ipairs(thrown:GetChildren()) do
								if object and object.Parent and object.Name ~= "Dragon" and object.Name ~= "Aurora" and object.Name ~= "starterdeb" then object:Destroy() end
							end
						end
					end)
				end)
				LightingService.GlobalShadows = false
				if type(setfpscap) == "function" then pcall(function() setfpscap(144) end) end
			else
				if maxPerformanceStepConnection then maxPerformanceStepConnection:Disconnect(); maxPerformanceStepConnection = nil end
				LightingService.GlobalShadows = superAntiLagEnabled and false or true
			end
		end)
		if not ok then warn("[RXM HUB] MAX PERFORMANCE error: " .. tostring(err)) end
	end})

	local ultraKeepParticleNames = {
		"Shockwave2", "Shockwave", "PunchingWind", "landRays", "ohye",
		"DragWind", "Maybe", "ItsWindTime", "STuff", "Land", "Wind2",
		"Combine", "pls", "omggg", "MainWave", "TParticles2", "Lightning",
		"BROO3", "BROO2", "BROO5", "Impact", "TBottom", "Skull", "BROO",
	}
	local function isUltraKeepParticle(name)
		for _, keptName in ipairs(ultraKeepParticleNames) do
			if name == keptName then return true end
		end
		return false
	end
	local function removeUltraPreferenceResources()
		local resources = ReplicatedStorageService:FindFirstChild("Resources")
		if not resources then return end
		local legacyReplication = resources:FindFirstChild("LegacyReplication")
		if legacyReplication then
			local hunterUlt = legacyReplication:FindFirstChild("HunterUlt")
			local attachment = hunterUlt and hunterUlt:FindFirstChild("Attachment1")
			if attachment then
				for _, name in ipairs({"6", "4-4", "4-3", "4-2", "4"}) do
					local object = attachment:FindFirstChild(name)
					if object then object:Destroy() end
				end
			end
			for _, name in ipairs({"UpSmoke2", "UpSmoke", "TreeFire", "Trans", "SmokeOne", "Smoke", "Leaves", "ImpactGlow", "Effect", "BackSmoke", "Push"}) do
				local object = legacyReplication:FindFirstChild(name)
				if object then object:Destroy() end
			end
		end
		for _, name in ipairs({
			"HeadFirst", "FlyingKicks", "WhirlwindDrop", "VanishingKick", "FlashFinisher", "PurpleAura", "PurpleM1",
			"le phone", "eject (2)", "Windy", "WindPurp", "Splash", "Slam", "Rocks", "Rock", "PhonePhysicsTest",
			"NewSlash", "Mah", "Katana", "FirstHit", "FinalEffects", "FSExpl", "EmergeSword", "CyborgArms",
			"Clone_Rig", "CloneRigEm", "CloneRig", "BatBarrageEffects", "AuraHolder", "AtomicFX", "Afterimage",
			"AcidExplosion", "QuickSlash", "MonsterSmash", "MonsterMoveTest", "MonsterAwaken", "FiveSeasonsFX",
			"FinisherEmerge", "FirstUltimateMoveMech", "FirstMonsterVFX", "DogVariant", "DeadlySliceVfx",
			"Consecutive Punches Finisher", "Slap", "SecM1", "Fast", "Fang", "EsperAwakening", "EffectsMech",
			"DragonUppercut", "DownSlam", "DoomFinish", "CrushingPushFinisher", "DashMechVfx", "Bossfight", "allvfx",
			"AtomicSlash", "CrushingPull", "GreenLights", "GreenTornado", "HeadFirstFinisher", "Collat", "Chain", "Cannon",
			"StoicBomb", "Meteor", "MechVfx", "CrabSlash", "CrabBeam", "Brother", "Blackholevfx", "BarrageFinisher",
		}) do
			local object = resources:FindFirstChild(name)
			if object then object:Destroy() end
		end
	end
	local function removeUltraParticles(root)
		if not root then return end
		local resources = ReplicatedStorageService:FindFirstChild("Resources")
		local smoke = resources and resources:FindFirstChild("Smoke")
		for _, object in ipairs(root:GetDescendants()) do
			if object:IsA("ParticleEmitter") and not isUltraKeepParticle(object.Name) and not (smoke and object:IsDescendantOf(smoke)) then
				pcall(function() object:Destroy() end)
			end
		end
	end
	ExtraTabs.Visuals:Toggle({Name = "ULTRA MAX PREFERENCE", Default = false, Callback = function(enabled)
		ultraPreferenceEnabled = enabled
		if enabled then
			removeUltraPreferenceResources()
			removeUltraParticles(WorkspaceService)
			if ultraPreferenceConnection then ultraPreferenceConnection:Disconnect() end
			ultraPreferenceConnection = game.DescendantAdded:Connect(function(object)
				if ultraPreferenceEnabled and object:IsA("ParticleEmitter") and not isUltraKeepParticle(object.Name) then
					local resources = ReplicatedStorageService:FindFirstChild("Resources")
					local smoke = resources and resources:FindFirstChild("Smoke")
					if not (smoke and object:IsDescendantOf(smoke)) then pcall(function() object:Destroy() end) end
				end
			end)
		else
			if ultraPreferenceConnection then ultraPreferenceConnection:Disconnect(); ultraPreferenceConnection = nil end
		end
	end})

	local function applySuperAntiLagObject(object)
		if not superAntiLagEnabled or not object then return end
		pcall(function()
			if effectClasses[object.ClassName] and superSavedEnabled[object] == nil then
				superSavedEnabled[object] = object.Enabled
				object.Enabled = false
			end
			if object:IsA("BasePart") and superSavedCastShadow[object] == nil then
				superSavedCastShadow[object] = object.CastShadow
				object.CastShadow = false
			end
		end)
	end
	local function scanSuperAntiLag(root)
		if root then for _, object in ipairs(root:GetDescendants()) do applySuperAntiLagObject(object) end end
	end
	local function setSuperAntiLag(enabled)
		if superAntiLagEnabled == enabled then return end
		superAntiLagEnabled = enabled
		if enabled then
			superSavedEnabled, superSavedCastShadow = {}, {}
			superOldGlobalShadows = LightingService.GlobalShadows
			LightingService.GlobalShadows = false
			scanSuperAntiLag(WorkspaceService)
			scanSuperAntiLag(LocalPlayer.Character)
			scanSuperAntiLag(LocalPlayer:FindFirstChild("Backpack"))
			table.insert(superAntiLagConnections, WorkspaceService.DescendantAdded:Connect(applySuperAntiLagObject))
			local backpack = LocalPlayer:FindFirstChild("Backpack")
			if backpack then table.insert(superAntiLagConnections, backpack.DescendantAdded:Connect(applySuperAntiLagObject)) end
			table.insert(superAntiLagConnections, LocalPlayer.CharacterAdded:Connect(function(character)
				task.defer(function() if superAntiLagEnabled then scanSuperAntiLag(character) end end)
			end))
		else
			disconnectMiscList(superAntiLagConnections)
			for object, wasEnabled in pairs(superSavedEnabled) do
				if object and object.Parent then pcall(function() object.Enabled = wasEnabled end) end
			end
			for object, hadCastShadow in pairs(superSavedCastShadow) do
				if object and object.Parent then pcall(function() object.CastShadow = hadCastShadow end) end
			end
			if superOldGlobalShadows ~= nil then
				LightingService.GlobalShadows = performanceEnabled and false or superOldGlobalShadows
			end
			superSavedEnabled, superSavedCastShadow, superOldGlobalShadows = {}, {}, nil
		end
	end
	ExtraTabs.Visuals:Toggle({Name = "ANTI LAG (SUPER MAX)", Default = false, Callback = setSuperAntiLag})

	local function cleanupMiscAntiLag()
		performanceEnabled = false
		ultraPreferenceEnabled = false
		if maxPerformanceStepConnection then pcall(function() maxPerformanceStepConnection:Disconnect() end); maxPerformanceStepConnection = nil end
		if ultraPreferenceConnection then pcall(function() ultraPreferenceConnection:Disconnect() end); ultraPreferenceConnection = nil end
		disconnectMiscList(miscPersistentConnections)
		if superAntiLagEnabled then setSuperAntiLag(false) end
		disconnectMiscList(superAntiLagConnections)
	end
	tabSettings:Section("Island")
	tabSettings:Keybind({Name = "Open / close panel", Default = Enum.KeyCode.K, Callback = function()
		if hidden then
			setHidden(false)
		end
		setState(state == "expanded" and "idle" or "expanded")
	end})
	tabSettings:Keybind({Name = "Hide island", Default = Enum.KeyCode.RightControl, Callback = function()
		setHidden(not hidden)
	end})
	tabSettings:Toggle({Name = "Click sound", Default = true, Callback = function(v)
		clickEnabled = v
		if v then
			playClick()
		end
	end})
	tabSettings:Button({Name = "Reset position", Callback = function()
		panelPos.x, panelPos.y = 0, PANEL_DROP
		if state == "expanded" then
			local maxX, minY, maxY = panelLimits()
			sp.ox.t = math.clamp(panelPos.x, -maxX, maxX)
			sp.oy.t = math.clamp(panelPos.y, minY, maxY)
		end
	end})
	local function destroy()
		if not alive then return end
		alive = false
		if cleanupMiscAntiLag then pcall(cleanupMiscAntiLag) end
		for _, c in ipairs(connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		pcall(function()
			gui:Destroy()
		end)
	end
	local closing = false
	local function closeGui()
		if closing or not alive then return end
		closing = true
		setHidden(true)
		task.spawn(function()
			local t0 = os.clock()
			while alive and os.clock() - t0 < 2 do
				if os.clock() - t0 > 0.45 and sp.show.x < 0.04 then
					break
				end
				task.wait()
			end
			task.wait(0.05)
			destroy()
		end)
	end
	tabSettings:Button({Name = "Destroy GUI", Callback = closeGui})
	-- =========================================
	-- RAW HUB (@zaintry): seluruh fiturnya dimuat ke GUI RXM HUB lewat penghubung (shim)
	-- (dibungkus do...end + function supaya tidak menambah jumlah local di Main)
	-- =========================================
	do
		local function setupRawHub()
			local Shim = {pages = {}, flags = {}, flushed = false, panicRan = false}
			local NONE = Enum.KeyCode.Unknown
			local PAGE_TAB = {
				Combat = tabTech,
				Macro = ExtraTabs.Macro,
				Visuals = ExtraTabs.Visuals,
				Visual = ExtraTabs.Visuals,
				Rage = ExtraTabs.Rage,
				Misc = tabMisc,
				Notifications = tabMisc,
			}
			local PAGE_RANK = {Combat = 1, Macro = 2, Visuals = 3, Visual = 3, Rage = 4, Misc = 5, Notifications = 6}

			local function colorToRGB(c)
				if typeof(c) ~= "Color3" then
					return 255, 255, 255
				end
				return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
			end
			local function keyFrom(v)
				if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
					return v
				end
				if type(v) == "string" and v ~= "" then
					local ok, key = pcall(function()
						return Enum.KeyCode[v]
					end)
					if ok and key then
						return key
					end
				end
				return NONE
			end

			-- objek balik elemen (dipakai raw untuk :set / :get / .current)
			local function newProxy(kind, opts)
				local p = {kind = kind, opts = opts}
				function p:set(v)
					if self.setv then
						self.setv(v)
					else
						self.pending = v
					end
				end
				function p:get()
					if self.getv then
						return self.getv()
					end
					if self.pending ~= nil then
						return self.pending
					end
					return opts.def
				end
				p.Set, p.Get = p.set, p.get
				return p
			end

			local function notifyUser(heading, message, kind)
				pcall(function()
					notify(heading, message, 3.5, kind or "info")
				end)
			end

			-- bikin elemen RXM sungguhan dari definisi gaya KittyWare
			local function build(tab, it)
				local p, o, kind = it.proxy, it.opts, it.kind
				local name = tostring(o.name or "")
				if kind == "toggle" then
					local real = tab:Toggle({Name = name, Default = o.def and true or false, Callback = o.callback})
					p.getv = function()
						return real:Get()
					end
					p.setv = function(v)
						real:Set(v and true or false)
					end
					p.dump, p.restore = p.getv, p.setv
				elseif kind == "slider" then
					local step = 1
					if type(o.rounding) == "number" then
						step = 10 ^ -o.rounding
					elseif o.rounding == false then
						step = 0.01
					end
					local real = tab:Slider({
						Name = name,
						Min = o.min or 0,
						Max = o.max or 100,
						Step = step,
						Suffix = o.measurement,
						Default = o.def,
						Callback = o.callback,
					})
					p.getv = function()
						return real:Get()
					end
					p.setv = function(v)
						real:Set(tonumber(v) or 0)
					end
					p.dump, p.restore = p.getv, p.setv
				elseif kind == "dropdown" then
					local real = tab:Dropdown({Name = name, Options = o.options or {}, Default = o.def, Callback = o.callback})
					p.getv = function()
						return real:Get()
					end
					p.setv = function(v)
						real:Set(v)
					end
					p.dump, p.restore = p.getv, p.setv
				elseif kind == "textbox" then
					local real = tab:Input({
						Name = name,
						Default = tostring(o.def == nil and "" or o.def),
						Placeholder = o.placeholder,
						Callback = o.callback,
					})
					p.getv = function()
						return real:Get()
					end
					p.setv = function(v)
						real:Set(v)
						if o.callback then
							pcall(o.callback, tostring(v))
						end
					end
					p.dump, p.restore = p.getv, p.setv
				elseif kind == "keybind" then
					local def = keyFrom(o.def)
					p.current = def ~= NONE and {"KeyCode", def.Name} or nil
					local real = tab:Keybind({
						Name = name,
						Default = def,
						Callback = o.callback,
						Changed = function(key)
							p.current = key ~= NONE and {"KeyCode", key.Name} or nil
							if o.changeCallback then
								pcall(o.changeCallback, key)
							end
						end,
					})
					p.getv = function()
						return real:Get()
					end
					p.setv = function(v)
						real:Set(keyFrom(v))
					end
					p.dump = function()
						local key = real:Get()
						return key == NONE and "" or key.Name
					end
					p.restore = p.setv
				elseif kind == "colorpicker" then
					local r, g, b = colorToRGB(o.def)
					local batching = false
					local sr, sg, sb
					local function emit()
						if o.callback and not batching then
							pcall(o.callback, Color3.fromRGB(r, g, b))
						end
					end
					tab:Foldout({
						Name = name,
						Build = function(t)
							sr = t:Slider({Name = "Red", Min = 0, Max = 255, Step = 1, Default = r, Callback = function(v)
								r = v
								emit()
							end})
							sg = t:Slider({Name = "Green", Min = 0, Max = 255, Step = 1, Default = g, Callback = function(v)
								g = v
								emit()
							end})
							sb = t:Slider({Name = "Blue", Min = 0, Max = 255, Step = 1, Default = b, Callback = function(v)
								b = v
								emit()
							end})
						end,
					})
					p.getv = function()
						return Color3.fromRGB(r, g, b)
					end
					p.setv = function(c)
						local nr, ng, nb = colorToRGB(c)
						batching = true
						sr:Set(nr)
						sg:Set(ng)
						sb:Set(nb)
						batching = false
						r, g, b = nr, ng, nb
						emit()
					end
					p.dump = function()
						return {r, g, b}
					end
					p.restore = function(v)
						if type(v) == "table" then
							p.setv(Color3.fromRGB(v[1] or 255, v[2] or 255, v[3] or 255))
						end
					end
				elseif kind == "button" then
					local callback = o.callback
					if name == "Panic" then
						callback = function()
							Shim.firePanic()
						end
					end
					tab:Button({Name = name, Callback = callback})
				elseif kind == "config" then
					local folder = "RXM_HUB/configs"
					local function ensureFolder()
						pcall(function()
							if makefolder and isfolder then
								if not isfolder("RXM_HUB") then
									makefolder("RXM_HUB")
								end
								if not isfolder(folder) then
									makefolder(folder)
								end
							end
						end)
					end
					local box = tab:Input({Name = "Config name", Default = "default", Placeholder = "name"})
					local function cfgPath()
						local text = tostring(box:Get() or ""):gsub("[^%w_%-]", "")
						if text == "" then
							text = "default"
						end
						return folder .. "/" .. text .. ".json", text
					end
					tab:Button({Name = "Save config", Callback = function()
						if type(writefile) ~= "function" then
							notifyUser("Config", "executor tidak mendukung writefile", "error")
							return
						end
						ensureFolder()
						local data = {}
						for pointer, proxy in pairs(Shim.flags) do
							if proxy.dump then
								local ok, value = pcall(proxy.dump)
								if ok and value ~= nil then
									data[pointer] = value
								end
							end
						end
						local path, label = cfgPath()
						local ok, err = pcall(function()
							writefile(path, HttpService:JSONEncode(data))
						end)
						notifyUser("Config", ok and ("saved: " .. label) or tostring(err), ok and "info" or "error")
					end})
					tab:Button({Name = "Load config", Callback = function()
						if type(readfile) ~= "function" or type(isfile) ~= "function" then
							notifyUser("Config", "executor tidak mendukung readfile", "error")
							return
						end
						local path, label = cfgPath()
						if not isfile(path) then
							notifyUser("Config", "tidak ada config: " .. label, "error")
							return
						end
						local ok, data = pcall(function()
							return HttpService:JSONDecode(readfile(path))
						end)
						if not ok or type(data) ~= "table" then
							notifyUser("Config", "file config rusak", "error")
							return
						end
						for pointer, value in pairs(data) do
							local proxy = Shim.flags[pointer]
							if proxy and proxy.restore then
								pcall(proxy.restore, value)
							end
						end
						notifyUser("Config", "loaded: " .. label, "info")
					end})
				end
				if p and p.pending ~= nil and p.setv then
					local pending = p.pending
					p.pending = nil
					pcall(p.setv, pending)
				end
			end

			function Shim.flush()
				if Shim.flushed then
					return
				end
				Shim.flushed = true
				task.spawn(function()
					local ordered = {}
					for i, page in ipairs(Shim.pages) do
						ordered[#ordered + 1] = {page = page, rank = PAGE_RANK[page.name] or 99, index = i}
					end
					table.sort(ordered, function(a, b)
						if a.rank ~= b.rank then
							return a.rank < b.rank
						end
						return a.index < b.index
					end)
					local n = 0
					for _, entry in ipairs(ordered) do
						local page = entry.page
						for _, sec in ipairs(page.sections) do
							if #sec.items > 0 then
								if not sec.headed then
									sec.headed = true
									pcall(function()
										page.tab:Section(sec.name)
									end)
								end
								for _, it in ipairs(sec.items) do
									if not alive then
										return
									end
									pcall(build, page.tab, it)
									n = n + 1
									if n % 8 == 0 then
										task.wait()
									end
								end
								sec.items = {}
							end
						end
					end
				end)
			end

			-- tombol Panic milik raw + hook saat "Destroy GUI" RXM ditekan
			function Shim.firePanic()
				if Shim.panicRan then
					return
				end
				Shim.panicRan = true
				if Shim.panicFn then
					pcall(Shim.panicFn)
				end
			end
			table.insert(connections, {
				Disconnect = function()
					Shim.firePanic()
				end,
			})

			-- "window" gaya KittyWare
			local Window = {}
			function Window:optimizemobile() end
			function Window:togglemobilebutton() end
			function Window:setkey() end
			function Window:destroy()
				pcall(closeGui)
			end
			function Window:page(po)
				local page = {name = tostring(po and po.name or ""), sections = {}}
				page.tab = PAGE_TAB[page.name] or tabMisc
				table.insert(Shim.pages, page)
				function page:openpage()
					Shim.flush()
				end
				function page:section(so)
					local sec = {name = tostring(so and so.name or ""), items = {}, headed = false}
					table.insert(page.sections, sec)
					local S = {}
					local function add(kind, opts)
						opts = opts or {}
						local proxy = newProxy(kind, opts)
						-- "GUI Keybind" milik raw diganti keybind panel bawaan RXM (tab Settings)
						if kind == "keybind" and tostring(opts.name) == "GUI Keybind" then
							return proxy
						end
						if kind == "button" and tostring(opts.name) == "Panic" then
							Shim.panicFn = opts.callback
						end
						if opts.pointer and kind ~= "button" then
							Shim.flags[opts.pointer] = proxy
						end
						local it = {kind = kind, opts = opts, proxy = proxy}
						if Shim.flushed then
							if not sec.headed then
								sec.headed = true
								pcall(function()
									page.tab:Section(sec.name)
								end)
							end
							pcall(build, page.tab, it)
						else
							table.insert(sec.items, it)
						end
						return proxy
					end
					function S:toggle(opts) return add("toggle", opts) end
					function S:slider(opts) return add("slider", opts) end
					function S:dropdown(opts) return add("dropdown", opts) end
					function S:keybind(opts) return add("keybind", opts) end
					function S:colorpicker(opts) return add("colorpicker", opts) end
					function S:textbox(opts) return add("textbox", opts) end
					function S:button(opts) return add("button", opts) end
					function S:configloader(opts) return add("config", opts) end
					return S
				end
				return page
			end

			Shim.lib = {}
			function Shim.lib:new()
				return Window
			end
			Shim.notifier = {
				Notify = function(o)
					o = type(o) == "table" and o or {}
					pcall(function()
						notify(tostring(o.Title or "RXM HUB"), tostring(o.Description or ""), tonumber(o.Duration) or 4, "info")
					end)
				end,
				Destroy = function() end,
			}
			return Shim
		end
		local Shim = setupRawHub()
		task.spawn(function(...)
			--[[
				BY - @zaintry
				SERVER- https://discord.gg/gYkxmvJhQM
				The hub loads KittyWare from kittyware/lib.lua, lib.lua, or
				https://raw.githubusercontent.com/0mam0ri/KittyWare/refs/heads/main/lib.lua
	
			]]

			(function(RXM_KITTY, RXM_NOTIFY, ...)
				if not bit32 then
					local _f = function(x, y, c)
						local p, r = 0x1, 0x0
						x, y = math.floor((x % (2 ^ 32) + 2 ^ 32) % (2 ^ 32)), math.floor((y % (2 ^ 32) + 2 ^ 32) % (2 ^ 32))
						while x > 0x0 or y > 0x0 do
							local a, b = x % 0x2, y % 0x2
							if
								(c == 0x1 and a ~= b)
								or (c == 0x2 and a == 0x1 and b == 0x1)
								or (c == 0x3 and (a == 0x1 or b == 0x1))
							then
								r = r + p
							end
							x = math.floor((x - a) / 0x2)
							y = math.floor((y - b) / 0x2)
							p = p * 0x2
						end
						return r % (2 ^ 32)
					end
					bit32 = {
						bxor = function(x, y)
							return _f(x, y, 0x1)
						end,
						band = function(x, y)
							return _f(x, y, 0x2)
						end,
						bor = function(x, y)
							return _f(x, y, 0x3)
						end,
						rshift = function(x, s)
							return math.floor(((x % (2 ^ 32) + 2 ^ 32) % (2 ^ 32)) / (0x2 ^ s))
						end,
						lshift = function(x, s)
							return (((x % (2 ^ 32) + 2 ^ 32) % (2 ^ 32)) * (0x2 ^ s)) % (2 ^ 32)
						end,
					}
				end
				local _l9DmZ = 0x3f55
				_l9DmZ = bit32.bxor(_l9DmZ, 0x3c68)
				if type(tostring) == "function" and type(type) == "function" and type(pcall) == "function" then
					local _f1, _f2, _f3, _f4 = type(type), type(pcall), type(tostring), type(math.floor)
					local _r1 = (string.byte(_f1, 1) * 31 + string.byte(_f2, 2) * 7 + string.len(_f3) * 13) % 65536
					local _r2 = (string.byte(_f4, 3) * 17 + math.floor(math.abs(-42.7)) * 23) % 65536
					local _r3 = (select and type(select) == "function") and (select("#", 1, 2, 3, 4, 5) * 101) or 505
					local _rt = (_r1 + _r2 + _r3) % 65536
					_l9DmZ = bit32.bxor(_l9DmZ, _rt)
				end
				_l9DmZ = bit32.bxor(_l9DmZ, 0x5d64)
				local _roblox = {
					workspace = workspace,
					game = game,
					script = script,
					task = task,
					Instance = Instance,
					Enum = Enum,
					Vector3 = Vector3,
					Vector2 = Vector2,
					CFrame = CFrame,
					Color3 = Color3,
					UDim = UDim,
					UDim2 = UDim2,
					BrickColor = BrickColor,
					TweenInfo = TweenInfo,
					RaycastParams = RaycastParams,
					Drawing = Drawing,
					tick = tick,
					time = time,
					typeof = typeof,
					math = math,
					table = table,
					string = string,
					pairs = pairs,
					ipairs = ipairs,
					next = next,
					pcall = pcall,
					tostring = tostring,
					tonumber = tonumber,
					select = select,
					unpack = unpack or table.unpack,
				}
				local _genv = (getgenv and getgenv()) or {}
				local _fenv = (getfenv and getfenv()) or _G or {}
				local EnvAccess = setmetatable({}, {
					__index = function(t, k)
						local v = _roblox[k]
						if v ~= nil then
							return v
						end
						v = _genv[k]
						if v ~= nil then
							return v
						end
						v = _fenv[k]
						if v ~= nil then
							return v
						end
						return _G[k]
					end,
				})
				local HubUI = {}
				if not game:IsLoaded() then
					if 65535 == 0xffff then
						game["Loaded"]:Wait()
					else
						(function()
							return (bit32 and 47872 or 0x6bbb)
						end)()
					end
				end
				local Services = EnvAccess["setmetatable"]({}, {
					["__index"] = function(_PIUsH, _uxgSI)
						return game:GetService(_uxgSI)
					end,
				})
				local VirtualInputManager = Services["VirtualInputManager"]
				local UserInputService = Services["UserInputService"]
				local RunService = Services["RunService"]
				local Lighting = Services["Lighting"]
				local PlayersService = Services["Players"]
				local PingStat = Services["Stats"]["Network"]["ServerStatsItem"]["Data Ping"]
				local HubLocalPlayer = PlayersService["LocalPlayer"]
				local PlayerGui = HubLocalPlayer["PlayerGui"]
				local HubMouse = HubLocalPlayer:GetMouse()
				local KittyWareLib = RXM_KITTY
				local NotifyLib = RXM_NOTIFY
				local _cpTDH = "1.1.0"
				local _DTbHC = "discord.gg/gYkxmvJhQM"
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					if EnvAccess["makefolder"] and EnvAccess["isfolder"] and not EnvAccess["isfolder"]("KittyWare") then
						if 65535 == 0xffff then
							EnvAccess["makefolder"]("KittyWare")
						else
							(function()
								return (bit32 and 8165 or 0x5d1f)
							end)()
						end
					end
				else
					(function()
						return (bit32 and 41130 or 0xc1a0)
					end)()
				end
				local _f5mDQ = {
					["Map"] = workspace:FindFirstChild("Map")
						or workspace:WaitForChild("Map", ((25 + 25) / 0x3e8))
						or Instance["new"]("Folder"),
					["Live"] = workspace:FindFirstChild("Live")
						or workspace:WaitForChild("Live", ((0 + 0x2 * 25) / 0x3e8))
						or Instance["new"]("Folder"),
					["Thrown"] = workspace:FindFirstChild("Thrown")
						or workspace:WaitForChild("Thrown", ((0x2 * 25 - 0) / 0x3e8))
						or Instance["new"]("Folder"),
					["Terrain"] = workspace:FindFirstChild("Terrain")
						or workspace:WaitForChild("Terrain", (50 / 0x3e8))
						or workspace["Terrain"],
					["Cutscenes"] = workspace:FindFirstChild("Cutscenes")
						or workspace:WaitForChild("Cutscenes", ((0x2 * 25 - 0) / 0x3e8))
						or Instance["new"]("Folder"),
				}
				local _AuGxA = workspace["CurrentCamera"]
				workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
					if workspace["CurrentCamera"] then
						_AuGxA = workspace["CurrentCamera"]
					end
				end)
				local _Z4x1B = workspace["FallenPartsDestroyHeight"]
				local _uMouq
				local _LMfeK
				do
					local _g0ECr, _F35TD, _aTgR2, _B2zB1, _B2zB1
					_B2zB1 = 0x2fe05
					if 0 == 0x0 then
						while _B2zB1 do
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								if bit32.bxor(_B2zB1, 0x4c5da) == 0x0 then
									_LMfeK = {
										["GlobalShadows"] = Lighting["GlobalShadows"],
										["ClockTime"] = Lighting["ClockTime"],
										["FieldOfView"] = _AuGxA["FieldOfView"],
										["Saturation"] = _uMouq["Saturation"],
										["createdCC"] = _F35TD,
										["originalCCName"] = _aTgR2,
									}
									_B2zB1 = nil
								elseif _B2zB1 - 0x7ff55 == 0x0 then
									_uMouq = _g0ECr or Instance["new"]("ColorCorrectionEffect", Lighting)
									_B2zB1 = bit32.bxor(bit32.bxor(_B2zB1, 0x1b80), 0x564cc)
								elseif _B2zB1 == 0xd93c8 then
									(function()
										return ((0x469a % 0x2 == 0x0) and (bit32 and 9037 or 0x0) or (bit32 and 55299 or 0x0))
									end)()
									_B2zB1 = bit32.bxor(_B2zB1 + 0x7b6, 0xc9a1c)
								elseif _B2zB1 - 0x28019 == 0x0 then
									_F35TD = _g0ECr == ({})[1]
									if 16 == 0x10 then
										_B2zB1 = bit32.bxor(bit32.bxor(_B2zB1, 0x749c), 0x94a7a)
									else
										(function()
											return (bit32 and 63831 or 0xbcf4)
										end)()
									end
								elseif _B2zB1 - 0x10162 == 0x0 then
									if 129 == 0x81 then
										(function()
											return (bit32 and 63542 or 0x91f8)
										end)()
									else
										(function()
											return (bit32 and 41309 or 0xa111)
										end)()
									end
									_B2zB1 = bit32.bxor(_B2zB1 + 0x713d, 0xce157)
								elseif _B2zB1 - 0xbbeff == 0x0 then
									_aTgR2 = _uMouq["Name"]
									_B2zB1 = bit32.bxor(_B2zB1 + 0x5ab2, 0x483f9)
								elseif bit32.bxor(_B2zB1, 0x89a48) == 0x0 then
									_uMouq["Name"] = "ColorCorrection"
									_B2zB1 = bit32.bxor(_B2zB1 + 0x8e1c, 0xdedbe)
								elseif _B2zB1 - 0x2fe05 == 0x0 then
									if 1 == 0x1 then
										_g0ECr = Lighting:FindFirstChild("ColorCorrection")
									else
										(function()
											return (bit32 and 2048340879 or 0x2719)
										end)()
									end
									_B2zB1 = bit32.bxor(bit32.bxor(_B2zB1, 0x1ffa), 0x51eaa)
								end
							else
								(function()
									return (bit32 and (51542 * 0x3d % 0x10000) or 0xcb00)
								end)()
							end
						end
					else
						(function()
							return ((0xb15e % 0x2 == 0x0) and (bit32 and 22703 or 0x0) or (bit32 and 40220 or 0x0))
						end)()
					end
				end
				local _rJ2QD = {}
				local _M5vLN = {}
				local _lbsvM = {}
				local _Glgei = {}
				local _XNd6n = {}
				local _sDkXo = EnvAccess["setmetatable"]({}, { ["__mode"] = "k" })
				local _R5B57 = false
				local _meXJ9 = false
				local _ElMhN
				local _XXmEh = {
					["HeadTransparency"] = 0,
					["FaceTransparency"] = 0,
					["AutoRotate"] = true,
					["JumpPower"] = (25 + 25),
				}
				local _yJXM8 = false
				local _RWZpc = {}
				local _keMEq = {
					["Garou"] = {
						["WaterTrail"] = true,
						["WaterTrailEnd"] = true,
						["AirTrail"] = true,
						["Trail1"] = true,
						["Spinparticle"] = true,
						["Spinparticle2"] = true,
						["1"] = true,
						["2"] = true,
						["3"] = true,
						["4"] = true,
						["5"] = true,
						["6"] = true,
						["7"] = true,
						["8"] = true,
						["9"] = true,
						["10"] = true,
						["1-1"] = true,
						["1-2"] = true,
						["1-3"] = true,
						["2-1"] = true,
						["2-2"] = true,
						["2-3"] = true,
						["3-1"] = true,
						["3-2"] = true,
						["3-3"] = true,
						["4-1"] = true,
						["4-2"] = true,
						["4-3"] = true,
						["4-4"] = true,
						["5-1"] = true,
						["5-2"] = true,
						["6-1"] = true,
						["7-1"] = true,
						["8-1"] = true,
						["9-1"] = true,
						["9-2"] = true,
						["Line"] = true,
						["Real"] = true,
						["Real2"] = true,
						["ParticleEmitter"] = true,
						["big"] = true,
						["Big"] = true,
						["Was"] = true,
						["Blue"] = true,
						["Hit"] = true,
						["HitEffect"] = true,
						["Splash"] = true,
						["Impact"] = true,
						["Flash"] = true,
						["Sparks"] = true,
					},
					["Red Garou"] = {
						["WaterTrail"] = true,
						["WaterTrailEnd"] = true,
						["AirTrail"] = true,
						["Trail1"] = true,
						["Spinparticle"] = true,
						["Spinparticle2"] = true,
						["Line"] = true,
						["Real"] = true,
						["ParticleEmitter"] = true,
						["big"] = true,
						["Big"] = true,
						["Red"] = true,
						["Splash"] = true,
						["Impact"] = true,
						["Flash"] = true,
						["Sparks"] = true,
						["Hit"] = true,
					},
					["Saitama"] = {
						["AirTrail"] = true,
						["Trail"] = true,
						["ParticleEmitter"] = true,
						["Shockwave"] = true,
						["Punch"] = true,
						["Hit"] = true,
						["HitEffect"] = true,
						["Impact"] = true,
						["Flash"] = true,
						["Wind"] = true,
						["Sparks"] = true,
						["Line"] = true,
						["Dust"] = true,
						["Crater"] = true,
					},
					["Genos"] = {
						["Fire"] = true,
						["Flame"] = true,
						["Sparks"] = true,
						["Spark"] = true,
						["Ignition"] = true,
						["Heat"] = true,
						["Burst"] = true,
						["Explosion"] = true,
						["Smoke"] = true,
						["Glow"] = true,
						["Trail"] = true,
						["ParticleEmitter"] = true,
						["Beam"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Thruster"] = true,
						["Core"] = true,
						["Jet"] = true,
						["Energy"] = true,
						["Burn"] = true,
					},
					["Sonic"] = {
						["Trail"] = true,
						["SonicTrail"] = true,
						["Purple"] = true,
						["Slash"] = true,
						["Slice"] = true,
						["Speed"] = true,
						["Flash"] = true,
						["Wind"] = true,
						["ParticleEmitter"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Sparks"] = true,
						["Line"] = true,
						["Spin"] = true,
						["AirTrail"] = true,
					},
					["Metal Bat"] = {
						["Trail"] = true,
						["BatTrail"] = true,
						["Swing"] = true,
						["SwingTrail"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Smash"] = true,
						["Slam"] = true,
						["Sparks"] = true,
						["ParticleEmitter"] = true,
						["RedTrail"] = true,
						["Bash"] = true,
						["Line"] = true,
						["Flash"] = true,
					},
					["Samurai"] = {
						["Trail"] = true,
						["Slash"] = true,
						["SlashTrail"] = true,
						["SwordTrail"] = true,
						["Slice"] = true,
						["Cut"] = true,
						["Blade"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Flash"] = true,
						["Sparks"] = true,
						["ParticleEmitter"] = true,
						["Line"] = true,
					},
					["Tatsumaki"] = {
						["Esper"] = true,
						["Psychic"] = true,
						["Aura"] = true,
						["Wave"] = true,
						["Green"] = true,
						["Glow"] = true,
						["Trail"] = true,
						["Beam"] = true,
						["ParticleEmitter"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Sparks"] = true,
						["Pebble"] = true,
						["Rock"] = true,
						["Crush"] = true,
					},
					["Siryu"] = {
						["Dragon"] = true,
						["Fang"] = true,
						["Void"] = true,
						["Tiger"] = true,
						["Purple"] = true,
						["Trail"] = true,
						["ParticleEmitter"] = true,
						["Hit"] = true,
						["Impact"] = true,
						["Flash"] = true,
						["Sparks"] = true,
						["Spin"] = true,
						["Kick"] = true,
						["Wave"] = true,
					},
				}
				local _DQit6 = {
					["BodySmoke"] = true,
					["BodySmokez"] = true,
					["SmokeUpTwo"] = true,
					["SmokeUp"] = true,
					["UpSmoke"] = true,
					["SmokeBack"] = true,
					["GroundSmoke"] = true,
					["UpSmoke2"] = true,
					["SmokeOne"] = true,
					["Push"] = true,
					["SmokeDown"] = true,
					["Dust"] = true,
					["Smoke"] = true,
					["Smoke3"] = true,
					["SmokeyUp"] = true,
					["Smokey"] = true,
				}
				local function _eOZ2hq(_xiR3f)
					local _Q6CZS8d5 = {}
					for _jASTFFL, _KVxGyi in ipairs(_xiR3f) do
						_Q6CZS8d5[_KVxGyi] = true
					end
					return _Q6CZS8d5
				end
				local _dcE27 = {
					["ignoreEnemy"] = _eOZ2hq({ "DoingEmote", "CancelEmote", "CancelEmote2", "BeingLaunched", "Freeze" }),
					["ignoreLocal"] = _eOZ2hq({
						"Counter",
						"HunterCounter",
						"DoingEmote",
						"CancelEmote",
						"CancelEmote2",
						"BeingLaunched",
						"Ragdoll",
						"Freeze",
						"BarrageBind",
					}),
					["ignoreM1"] = _eOZ2hq({
						"Counter",
						"AbsoluteImmortal",
						"AtomicCounter",
						"HunterCounter",
						"UpFrames",
						"Ragdoll",
						"ForceField",
						"CanBringUp",
					}),
					["interruptMoves"] = _eOZ2hq({
						"Shove",
						"Normal Punch",
						"Uppercut",
						"Flowing Water",
						"Lethal Whirlwind Stream",
						"Hunter's Grasp",
						"Doom Dive",
						"Crowd Buster",
						"Hammer Heel",
						"Binding Cloth",
						"Jet Dive",
						"Blitz Shot",
						"Ignition Burst",
						"Flash Strike",
						"Scatter",
						"Explosive Shuriken",
						"Homerun",
						"Beatdown",
						"Four Ball",
						"Quick Slice",
						"Atmos Cleave",
						"Pinpoint Cut",
						"Crushing Pull",
						"Windstorm Fury",
						"Stone Coffin",
						"Expulsive Push",
						"GoPush",
						"Vanishing Kick",
						"Whirlwind Drop",
						"Head First",
						"Weboom",
						"Plasma Cannon",
						"Trinity Tear",
						"Twin Burst",
						"TornadoBind",
					}),
					["barrageMoves"] = _eOZ2hq({ "Consecutive Punches", "Machine Gun Blows", "Bullet Barrage" }),
					["cape"] = _eOZ2hq({
						"Custom Cape",
						"Guild Cape",
						"Slinky",
						"Ruler Cape",
						"Webbed Cape",
						"Warden Cape",
						"Desert Cape",
						"Divine Wheel",
						"Spiky Cape",
						"Fur Cape",
						"Blood Scarf",
						"Torn Headband",
						"Headband",
						"Bandage Wrap",
						"Waist Sash",
						"Leg Iron",
						"Leg Iron",
						"Worn Cape",
						"Tattered Cape",
						"Torn Cape",
						"White Cape",
						"Conqueror Cape",
						"Jagged Cape",
						"Royal Cape",
						"White Scarf",
						"Short Sash",
						"Red Gloves",
						"SpiralHolder",
						"Long Sash",
						"Bandages",
						"Purple Scarf",
					}),
					["aura"] = _eOZ2hq({
						"Gold Aura",
						"Midnight Aura",
						"Shadow Aura",
						"Burning Aura",
						"Crimson Aura",
						"Graceful Aura",
						"Glitch Aura",
						"Colorful Aura",
						"Error Aura",
						"Stench Aura",
						"Dark Aura",
						"Lighting Aura",
						"Ki Aura",
					}),
					["ultbarPending"] = false,
					["boostUntil"] = 0,
					["serverNoDash"] = workspace:GetAttribute("NoDashCooldown"),
					["serverEffect"] = workspace:GetAttribute("EffectAffects"),
					["spoofingDash"] = false,
				}
				local _wZKifJPa = {
					["Bald"] = "Saitama",
					["Hunter"] = "Garou",
					["Monster"] = "Red Garou",
					["Cyborg"] = "Genos",
					["Ninja"] = "Sonic",
					["Batter"] = "Metal Bat",
					["Blade"] = "Samurai",
					["Esper"] = "Tatsumaki",
					["Purple"] = "Siryu",
					["Tech"] = "Emperor",
					["KJ"] = "KJ",
					["Zombie"] = "Zombieman",
				}
				local _lH0uIxY = {
					["headless"] = false,
					["stretch"] = false,
					["lockon"] = false,
					["antifling"] = false,
					["getping"] = false,
					["hitbox"] = false,
					["korblox"] = false,
				}
				local _KjGi0a = {
					["conn"] = ({})[1],
					["startTime"] = 0,
					["duration"] = (500 / 0x3e8),
					["strength"] = 50,
					["smoothness"] = ((0x2 * 325 - 0) / 0x3e8),
					["targetOverride"] = ({})[1],
				}
				local _r6zpd
				local _YxtF_bco = ""
				local _FPbWqU0 = false
				local _ecSEyI, _LZYNd, _sC0i4
				local _Z0Hry
				local _y4IB9
				local _fx2la
				local _MJSFe, _tew4S, _SXQgY
				local _zE8Ni
				local _gQE1u
				local _N82Le
				local _mzv8k
				local _TLppj = HubLocalPlayer:GetAttribute("S_AutoUnequip")
				local _vjMDS = {}
				local _i3Z2l
				local _NSKGP = Enum["KeyCode"]["Space"]
				local _kK9mB = Enum["KeyCode"]["Q"]
				local _X1lLf = Enum["KeyCode"]["W"]
				local _u6GG1 = Enum["KeyCode"]["S"]
				local _ZgU0U = Enum["KeyCode"]["D"]
				local _MJJxA = Enum["KeyCode"]["A"]
				local _j089A = {
					["frontDash"] = "10479335397",
					["rsideDash"] = "10480793962",
					["lsideDash"] = "10480796021",
					["uppercut"] = "10503381238",
					["euppercut"] = "13379003796",
					["backDash"] = "10491993682",
				}
				local _Ws0Y9 = {
					["holdM1"] = { ["Goal"] = "LeftClick" },
					["releaseM1"] = { ["Goal"] = "LeftClickRelease" },
					["backDash"] = { ["Dash"] = Enum["KeyCode"]["S"], ["Key"] = Enum["KeyCode"]["Q"], ["Goal"] = "KeyPress" },
					["frontDash"] = { ["Dash"] = Enum["KeyCode"]["W"], ["Key"] = Enum["KeyCode"]["Q"], ["Goal"] = "KeyPress" },
					["holdBlock"] = { ["Goal"] = "KeyPress", ["Key"] = Enum["KeyCode"]["F"] },
					["releaseBlock"] = { ["Goal"] = "KeyRelease", ["Key"] = Enum["KeyCode"]["F"] },
				}
				local _vrfgk = {
					["FarDash"] = (14 + 14),
					["NearDash"] = 22,
					["Barrage"] = 18,
					["MovingM1"] = (15 + 0x2 * 0),
					["M1"] = (1 + 0x2 * 4),
				}
				local HubSettings = {
					["Autoblock"] = {
						["Enabled"] = false,
						["DashPredict"] = false,
						["AutoM1"] = false,
						["AutoCounter"] = false,
						["RotateChar"] = true,
						["RotateCam"] = false,
						["CharEasing"] = 0,
						["CamEasing"] = 0,
						["FOV"] = (0 + 0x2 * 180),
					},
					["AutoTech"] = {
						["Enabled"] = false,
						["Tech"] = "",
						["Method"] = "Perform Always",
						["PerformOnce"] = false,
						["Loopv2"] = {
							["Precision"] = (250 / 0x3e8),
							["SecondFlick"] = (40 / 0x3e8),
							["Jump"] = true,
							["FirstFlickAngle"] = 0,
							["RotateCam"] = false,
						},
						["Customdash"] = {
							["StartFlickAngle"] = 0,
							["SecondFlickAngle"] = 0,
							["SecondFlickDelay"] = 0,
							["ThirdFlickAngle"] = 0,
							["ThirdFlickDelay"] = 0,
							["Jump"] = true,
							["RotateCam"] = false,
							["LockOn"] = false,
							["LockOnAfter"] = "",
							["LockOnPrecision"] = (1 + 0),
							["LockOnDelay"] = 0,
						},
						["Customdashv2"] = {
							["StartFlickAngle"] = 0,
							["SecondFlickAngle"] = 0,
							["SecondFlickDelay"] = 0,
							["SecondFlickDuration"] = 0,
							["ThirdFlickAngle"] = 0,
							["ThirdFlickDelay"] = 0,
							["ThirdFlickDuration"] = 0,
							["Jump"] = true,
							["RotateCam"] = false,
							["LockOn"] = false,
							["LockOnAfter"] = "",
							["LockOnPrecision"] = 1,
							["LockOnDelay"] = 0,
						},
						["LockonPrecision"] = 1,
						["SupaMethod"] = "RenderStepped",
						["LoopDashLooksUp"] = false,
						["TargetPart"] = "HumanoidRootPart",
					},
					["AutoLethal"] = {
						["Enabled"] = false,
						["HitAnim"] = "12296113986",
						["FirstFlickAngle"] = 0,
						["SecondFlick"] = ((0x2 * 20 - 0) / 0x3e8),
						["Precision"] = (350 / 0x3e8),
						["Jump"] = true,
						["RotateCam"] = false,
						["Highlight"] = true,
						["HighlightColor"] = Color3["fromRGB"](255, 60, (0 + 0x2 * 30)),
					},
					["Misc"] = {
						["FriendCheck"] = false,
						["NoDashEndLag"] = false,
						["StretchEnabled"] = false,
						["StretchValue"] = 1,
						["LockOnEnabled"] = false,
						["LockOnPrecision"] = 1,
						["TDSEnabled"] = false,
						["Magnet"] = {
							["Enabled"] = false,
							["Keybind"] = ({})[1],
							["TechTrigger"] = "Disabled",
							["TechDelay"] = 0,
							["Duration"] = (500 / 0x3e8),
							["Height"] = 2,
							["Strength"] = 50,
							["Smoothness"] = ((0 + 0x2 * 325) / 0x3e8),
							["MaxDistance"] = (0 + 0x2 * 50),
							["DashCancel"] = true,
						},
					},
					["PingSpoof"] = {
						["Enabled"] = false,
						["Ping"] = (0 + 0x2 * 15),
						["Jitter"] = 3,
						["Interval"] = (1 + 0),
					},
					["DeviceSpoof"] = { ["Enabled"] = false, ["Device"] = "Console", ["Icon"] = "", ["TapClicks"] = false },
					["Visuals"] = {
						["NoSmoke"] = false,
						["NoRings"] = false,
						["NoNewLight"] = false,
						["NoCapes"] = false,
						["NoShadows"] = false,
						["NoAuras"] = false,
						["NoGarouC"] = false,
						["Headless"] = false,
						["FOV"] = 70,
						["Korblox"] = false,
						["MotionBlur"] = { ["Enabled"] = false, ["Intensity"] = 10 },
						["SelfChams"] = {
							["Enabled"] = false,
							["Color"] = Color3["fromRGB"]((0x2 * 71 - 0), 187, 255),
							["Material"] = "ForceField",
							["FillTransparency"] = ((0 + 0x2 * 250) / 0x3e8),
							["OutlineTransparency"] = 0,
						},
						["Atmosphere"] = {
							["Enabled"] = false,
							["Color"] = Color3["fromRGB"](142, 187, (255 + 0)),
							["Decay"] = Color3["fromRGB"]((0 + 0x2 * 46), (30 + 30), 13),
							["Density"] = ((0 + 0x2 * 175) / 0x3e8),
							["Haze"] = 0,
							["Glare"] = 0,
						},
						["Sky"] = {
							["Enabled"] = false,
							["Preset"] = "Night",
							["Stars"] = (1500 + 1500),
							["SkyboxId"] = "",
						},
						["EffectsColor"] = {
							["Enabled"] = false,
							["Color"] = Color3["fromRGB"](142, (95 + 92), (255 + 0)),
						},
						["CustomUltbar"] = {
							["UltbarText"] = { ["Enabled"] = false, ["Text"] = "KITTYWARE" },
							["UltbarColor"] = {
								["Enabled"] = false,
								["Color"] = Color3["fromRGB"]((0 + 0x2 * 71), 187, 255),
							},
						},
						["ESP"] = {
							["Enabled"] = false,
							["Boxes"] = false,
							["BoxColor"] = Color3["fromRGB"](142, (0x2 * 95 - 3), 255),
							["BoxUseESPColor"] = true,
							["BoxThickness"] = (1 + 0x2 * 0),
							["BoxFilled"] = false,
							["DeathCounterColor"] = Color3["new"](((0x2 * 231 - 7) / 0x3e8), (137 / 0x3e8), (141 / 0x3e8)),
							["NeutralColor"] = Color3["new"]((365 / 0x3e8), ((0x2 * 283 - 1) / 0x3e8), 1),
							["FriendColor"] = Color3["new"](((294 + 294) / 0x3e8), 1, (275 / 0x3e8)),
							["EnemyColor"] = Color3["new"]((635 / 0x3e8), ((0x2 * 200 - 0) / 0x3e8), (114 / 0x3e8)),
							["UltColor"] = Color3["new"](((319 + 316) / 0x3e8), ((288 + 288) / 0x3e8), (114 / 0x3e8)),
							["SaitamaUltColor"] = Color3["new"]((980 / 0x3e8), 1, ((0 + 0x2 * 339) / 0x3e8)),
							["NoBillboards"] = false,
							["Highlight"] = true,
							["OutlineTransparency"] = ((0 + 0x2 * 350) / 0x3e8),
							["DeathCounterESP"] = false,
							["SaitamaUltESP"] = false,
						},
					},
					["Macro"] = {
						["m1ResetEnabled"] = false,
						["EmoteDash"] = {
							["Enabled"] = false,
							["Delay"] = (50 / 0x3e8),
							["Type"] = "Straight",
						},
						["BackDashCancel1"] = { ["Enabled"] = false },
						["BackDashCancel2"] = { ["Enabled"] = false },
						["BackDashCancel3"] = { ["Enabled"] = false },
						["BackDashCancel4"] = { ["Enabled"] = false },
						["TechHelper"] = { ["Enabled"] = false, ["Tech"] = "" },
						["ExtraTechHelper"] = { ["Enabled"] = false, ["Tech"] = "Instant Lethal Shift Lock" },
					},
					["Rage"] = {
						["NoStun"] = false,
						["NoSlow"] = false,
						["NoFatigue"] = false,
						["AlwaysJump"] = false,
						["NoSideDashCooldown"] = false,
						["Fling"] = { ["Target"] = "", ["LoopFling"] = false },
						["CustomFrontDash"] = {
							["Enabled"] = false,
							["OnlyOnKeybind"] = false,
							["Distance"] = (1 + 0),
						},
						["CustomSideDash"] = {
							["Enabled"] = false,
							["OnlyOnKeybind"] = false,
							["Distance"] = 1,
							["Side"] = "",
							["RemoveInertia"] = false,
							["RMIDelay"] = ((0 + 0x2 * 35) / 0x3e8),
							["Jump"] = false,
						},
					},
					["Notifications"] = {
						["GlobalEnabled"] = true,
						["UltEnabled"] = true,
						["DeathCounterEnabled"] = true,
						["AutoTechEnabled"] = true,
						["FlingEnabled"] = true,
					},
				}
				local _lNGCT = {
					["Ult"] = "UltEnabled",
					["Death Counter"] = "DeathCounterEnabled",
					["Auto Tech"] = "AutoTechEnabled",
					["Fling"] = "FlingEnabled",
				}
				local function _OS0SJ(_j3AeP)
					local _wjnQ4, _ZAZ9Z, _mRMKU, _H25i7, _k7GNj, _CTwSL, _CTwSL
					if 129 == 0x81 then
						_CTwSL = 0x964ec
					else
						(function()
							return (bit32 and (58215 * 0x3d % 0x10000) or 0xe056)
						end)()
					end
					while _CTwSL do
						if bit32.bxor(_CTwSL, 0x38c44) == 0x0 then
							if 0 == 0x0 then
								(function()
									return (bit32 and 64607 or 0xcc7e)
								end)()
							else
								(function()
									return (bit32 and 196409184 or 0xb951)
								end)()
							end
							_CTwSL = bit32.bxor(bit32.bxor(_CTwSL, 0xc43), 0xf047f)
						elseif _CTwSL - 0x551c9 == 0x0 then
							_ZAZ9Z = _j3AeP["Title"]
							_CTwSL = bit32.bxor(_CTwSL + 0x3ef9, 0xdd760)
						elseif _CTwSL == 0xbd6a then
							if 16 == 0x10 then
								_k7GNj = _j3AeP["Duration"] or (3 + 2)
							else
								(function()
									return (bit32 and 64050 or 0xa5fa)
								end)()
							end
							_CTwSL = bit32.bxor(bit32.bxor(_CTwSL, 0x2de5), 0xaf7f5)
						elseif _CTwSL == 0x31be5 then
							if 129 == 0x81 then
								if
									not HubSettings["Notifications"]["GlobalEnabled"]
									or (_wjnQ4 and not HubSettings["Notifications"][_wjnQ4])
								then
									return
								end
							else
								(function()
									return (bit32 and 3388 or 0xf1c)
								end)()
							end
							_CTwSL = bit32.bxor(_CTwSL + 0x3186, 0x61ca2)
						elseif bit32.bxor(_CTwSL, 0xcc5b4) == 0x0 then
							_H25i7 = _j3AeP["Image"]
							_CTwSL = bit32.bxor(_CTwSL + 0x8ee7, 0xde9f1)
						elseif _CTwSL - 0x847a2 == 0x0 then
							_mRMKU = _j3AeP["Description"]
							if 0 == 0x0 then
								_CTwSL = bit32.bxor(bit32.bxor(_CTwSL, 0x5232), 0x4d024)
							else
								(function()
									return ((0xcc05 % 0x2 == 0x0) and (bit32 and 26114 or 0x0) or (bit32 and 45553 or 0x0))
								end)()
							end
						elseif _CTwSL == 0xa677a then
							NotifyLib["Notify"]({
								["Title"] = _ZAZ9Z,
								["Description"] = _mRMKU,
								["Image"] = _H25i7,
								["Duration"] = _k7GNj,
							})
							_CTwSL = nil
						elseif _CTwSL == 0xc8478 then
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								(function()
									return (bit32 and 59255 or 0xaf46)
								end)()
							else
								(function()
									return (bit32 and 35468 or 0x120c)
								end)()
							end
							if 0 == 0x0 then
								_CTwSL = bit32.bxor(bit32.bxor(_CTwSL, 0xa50e), 0x71c65)
							else
								(function()
									return ((0xbfb0 % 0x2 == 0x0) and (bit32 and 24536 or 0x0) or (bit32 and 8564 or 0x0))
								end)()
							end
						elseif bit32.bxor(_CTwSL, 0x964ec) == 0x0 then
							_wjnQ4 = _lNGCT[_j3AeP["Source"]]
							_CTwSL = bit32.bxor(_CTwSL + 0xae3f, 0x908ce)
						elseif bit32.bxor(_CTwSL, 0xb3d13) == 0x0 then
							(function()
								return (bit32 and 43933 or 0xb565)
							end)()
							_CTwSL = bit32.bxor(bit32.bxor(_CTwSL, 0x22a9), 0x893fe)
						end
					end
				end
				local function _xQp2C(_aLjhy)
					if 65535 == 0xffff then
						if _aLjhy then
							task["cancel"](_aLjhy)
							if 65535 == 0xffff then
								_aLjhy = ({})[1]
							else
								(function()
									return ((0x3a7a % 0x2 == 0x0) and (bit32 and 7485 or 0x0) or (bit32 and 62699 or 0x0))
								end)()
							end
						end
					else
						(function()
							return (bit32 and 17812 or 0xccb4)
						end)()
					end
				end
				local function _vA5WJ(_Ijh47)
					if _Ijh47 then
						_Ijh47:Disconnect()
						_Glgei[_Ijh47] = ({})[1]
						_Ijh47 = ({})[1]
					end
				end
				local function _l3G1i(_yMT0M, _TBHkm)
					local _wk3L5 = _yMT0M:Connect(function(...)
						if _R5B57 then
							return
						end
						return _TBHkm(...)
					end)
					_Glgei[_wk3L5] = true
					return _wk3L5
				end
				local function _J4f_N(_mZM3s)
					if _mZM3s then
						for _HOoHI, _UlJS5 in ipairs(_mZM3s) do
							_vA5WJ(_UlJS5)
						end
						table["clear"](_mZM3s)
					end
				end
				local function _yN_t5(_JIm6E, _gouwvTcD, _HoL6e09, _WOk9NU)
					local _xVJJ6 = _l3G1i(_gouwvTcD[_HoL6e09], _WOk9NU)
					if _JIm6E then
						table["insert"](_JIm6E, _xVJJ6)
					end
					return _xVJJ6
				end
				local function _UbxYIsuM(_Vl9aYKy, _qOEFkj)
					local _fWiSA, _G6iEM, _G6iEM
					if 0 == 0x0 then
						_G6iEM = 0x1f40d
					else
						(function()
							return (bit32 and 25301 or 0x73d7)
						end)()
					end
					while _G6iEM do
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							if _G6iEM - 0xaa690 == 0x0 then
								return _fWiSA[_qOEFkj]["value"]
							elseif _G6iEM - 0xeb4c7 == 0x0 then
								(function()
									return (bit32 and 57343 or 0x928d)
								end)()
								_G6iEM = bit32.bxor(_G6iEM + 0x50b1, 0xdb324)
							elseif _G6iEM - 0x3bd8d == 0x0 then
								if not _fWiSA then
									if 1 == 0x1 then
										_fWiSA = {}
									else
										(function()
											return (bit32 and 55396 or 0xdc4f)
										end)()
									end
									_sDkXo[_Vl9aYKy] = _fWiSA
								end
								if 129 == 0x81 then
									_G6iEM = bit32.bxor(bit32.bxor(_G6iEM, 0x949d), 0x423c4)
								else
									(function()
										return (bit32 and 1217054786 or 0x5901)
									end)()
								end
							elseif _G6iEM - 0x1f40d == 0x0 then
								if 0 == 0x0 then
									_fWiSA = _sDkXo[_Vl9aYKy]
								else
									(function()
										return ((0x466e % 0x2 == 0x0) and (bit32 and 9015 or 0x0) or (bit32 and 5804 or 0x0))
									end)()
								end
								_G6iEM = bit32.bxor(bit32.bxor(_G6iEM, 0x6d28), 0x224a8)
							elseif _G6iEM == 0xcbe3a then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									(function()
										return (bit32 and 1543698225 or 0x32ea)
									end)()
								else
									(function()
										return (bit32 and 20058 or 0x5d52)
									end)()
								end
								_G6iEM = bit32.bxor(bit32.bxor(_G6iEM, 0x7de), 0x20d23)
							elseif _G6iEM == 0x70ad4 then
								if _fWiSA[_qOEFkj] == ({})[1] then
									if 1 == 0x1 then
										_fWiSA[_qOEFkj] = { ["value"] = _Vl9aYKy[_qOEFkj] }
									else
										(function()
											return (bit32 and 432191909 or 0xb2c4)
										end)()
									end
								end
								if 1 == 0x1 then
									_G6iEM = bit32.bxor(_G6iEM + 0xb0db, 0xd1d3f)
								else
									(function()
										return (bit32 and 995 or 0x2003)
									end)()
								end
							elseif _G6iEM - 0x2b65c == 0x0 then
								if 129 == 0x81 then
									(function()
										return (bit32 and 10699 or 0x3429)
									end)()
								else
									(function()
										return (bit32 and 902241663 or 0x2359)
									end)()
								end
								if 1 == 0x1 then
									_G6iEM = bit32.bxor(bit32.bxor(_G6iEM, 0xa846), 0xea020)
								else
									(function()
										return (bit32 and (37147 * 0x3d % 0x10000) or 0x823e)
									end)()
								end
							end
						else
							(function()
								return (bit32 and 54749 or 0x81d5)
							end)()
						end
					end
				end
				local function _IeaiYt2E(_hCkNxTU, _SP1Yvr, _r9nTw)
					_UbxYIsuM(_hCkNxTU, _SP1Yvr)
					_hCkNxTU[_SP1Yvr] = _r9nTw
				end
				local function _Upc_G()
					for _JH0vd, _e4Cri in pairs(_sDkXo) do
						for _TbBLC, _wqz9N in pairs(_e4Cri) do
							pcall(function()
								_JH0vd[_TbBLC] = _wqz9N["value"]
							end)
						end
					end
					table["clear"](_sDkXo)
				end
				local function _VrEaM(_G5mQk)
					local _fZ3j5 = math["random"](2, (0x2 * 3 - 0)) / 1000
					task["wait"]((_G5mQk or 0) + _fZ3j5)
				end
				local function _IDvSS(_xq53R)
					VirtualInputManager:SendKeyEvent(true, _xq53R, false, game)
				end
				local function _S4jah(_HYtYZ)
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						VirtualInputManager:SendKeyEvent(false, _HYtYZ, false, game)
					else
						(function()
							return (bit32 and 11708 or 0xf598)
						end)()
					end
				end
				local function _kvld1(_Jd11Q)
					_IDvSS(_Jd11Q)
					_VrEaM()
					_S4jah(_Jd11Q)
				end
				local function _u3Jke(_TLC65)
					local _olb0C, _olb0C
					if 0 == 0x0 then
						_olb0C = 0xd61e1
					else
						(function()
							return (bit32 and 58384 or 0x7810)
						end)()
					end
					if 0 == 0x0 then
						while _olb0C do
							if bit32.bxor(_olb0C, 0xd61e1) == 0x0 then
								_IDvSS(_TLC65)
								_olb0C = bit32.bxor(_olb0C + 0x662c, 0x5fac0)
							elseif _olb0C - 0x9bb00 == 0x0 then
								(function()
									return ((0x1f9c % 0x2 == 0x0) and (bit32 and 4046 or 0x0) or (bit32 and 5757 or 0x0))
								end)()
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_olb0C = bit32.bxor(_olb0C + 0x4479, 0x36769)
								else
									(function()
										return ((0x2ab3 % 0x2 == 0x0) and (bit32 and 5465 or 0x0) or (bit32 and 25704 or 0x0))
									end)()
								end
							elseif _olb0C - 0xa9810 == 0x0 then
								(function()
									return (bit32 and (42345 * 0x3d % 0x10000) or 0xb34a)
								end)()
								_olb0C = bit32.bxor(_olb0C + 0x910f, 0x2921f)
							elseif _olb0C - 0xda53f == 0x0 then
								if not _TLppj then
									local _wtxn4, _lcPtH, _JyzKr, _bgVgX, _bgVgX
									_bgVgX = 0x78282
									while _bgVgX do
										if bit32.bxor(_bgVgX, 0x6e909) == 0x0 then
											if 16 == 0x10 then
												(function()
													return (bit32 and (53959 * 0x3d % 0x10000) or 0x8294)
												end)()
											else
												(function()
													return (bit32 and 8678 or 0x8821)
												end)()
											end
											if 0 == 0x0 then
												_bgVgX = bit32.bxor(bit32.bxor(_bgVgX, 0xb137), 0x4ee91)
											else
												(function()
													return (bit32 and 9404 or 0x824)
												end)()
											end
										elseif _bgVgX - 0xc183d == 0x0 then
											VirtualInputManager:SendMouseButtonEvent(_lcPtH, _JyzKr, 0, false, game, 0)
											_bgVgX = nil
										elseif _bgVgX == 0x85e4c then
											_VrEaM()
											if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
												_bgVgX = bit32.bxor(_bgVgX + 0x676e, 0x4dd87)
											else
												(function()
													return (bit32 and 1566811629 or 0xe3cf)
												end)()
											end
										elseif bit32.bxor(_bgVgX, 0x78282) == 0x0 then
											_VrEaM()
											_bgVgX = bit32.bxor(bit32.bxor(_bgVgX, 0x3734), 0x19369)
										elseif _bgVgX == 0x8b1be then
											if 16 == 0x10 then
												VirtualInputManager:SendMouseButtonEvent(_lcPtH, _JyzKr, 0, true, game, 0)
											else
												(function()
													return (bit32 and 17 or 0x2500)
												end)()
											end
											_bgVgX = bit32.bxor(_bgVgX + 0x9454, 0x1185e)
										elseif _bgVgX - 0x2b6af == 0x0 then
											if 0 == 0x0 then
												(function()
													return (bit32 and 52925 or 0xf3c)
												end)()
											else
												(function()
													return (bit32 and 35214 or 0x8d89)
												end)()
											end
											_bgVgX = bit32.bxor(bit32.bxor(_bgVgX, 0x7406), 0x42ba0)
										elseif _bgVgX - 0x626df == 0x0 then
											if 65535 == 0xffff then
												_wtxn4 = _AuGxA["ViewportSize"]
											else
												(function()
													return (bit32 and 496104590 or 0x94e4)
												end)()
											end
											if 0 == 0x0 then
												_bgVgX = bit32.bxor(_bgVgX + 0x6837, 0xd30d3)
											else
												(function()
													return (bit32 and (8776 * 0x3d % 0x10000) or 0x23b5)
												end)()
											end
										elseif _bgVgX == 0xbbfc5 then
											_lcPtH, _JyzKr =
												math["floor"](_wtxn4["X"] / 2), math["floor"](_wtxn4["Y"] / (0x2 * 1 - 0))
											if 0 == 0x0 then
												_bgVgX = bit32.bxor(_bgVgX + 0x5d78, 0x4ac83)
											else
												(function()
													return (bit32 and 23912 or 0xcd5d)
												end)()
											end
										end
									end
								end
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_olb0C = nil
								else
									(function()
										return (bit32 and 41891 or 0x8183)
									end)()
								end
							elseif _olb0C == 0x832cd then
								_VrEaM((10 / 0x3e8))
								_olb0C = bit32.bxor(_olb0C + 0x46bb, 0xb95c0)
							elseif _olb0C == 0x3ec48 then
								_S4jah(_TLC65)
								if 0 == 0x0 then
									_olb0C = bit32.bxor(_olb0C + 0x1357, 0xe5aa0)
								else
									(function()
										return (bit32 and 624803609 or 0x3452)
									end)()
								end
							end
						end
					else
						(function()
							return (bit32 and 31730 or 0x207b)
						end)()
					end
				end
				local function _wQo4g()
					local _XdMsy, _uXYDT, _lKoRm, _o1NOl, _NfZkW, _a_wrZ, _hSgF1, _hSgF1
					_hSgF1 = 0x64136
					if 0 == 0x0 then
						while _hSgF1 do
							if 16 == 0x10 then
								if bit32.bxor(_hSgF1, 0x64136) == 0x0 then
									if 129 == 0x81 then
										_XdMsy = PlayerGui:FindFirstChild("Bar")
									else
										(function()
											return ((0xacd0 % 0x2 == 0x0) and (bit32 and 22120 or 0x0) or (bit32 and 31268 or 0x0))
										end)()
									end
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x7273), 0x8ae1)
									else
										(function()
											return (bit32 and (61724 * 0x3d % 0x10000) or 0xf847)
										end)()
									end
								elseif _hSgF1 == 0x6b9a4 then
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										_uXYDT = _XdMsy and _XdMsy:FindFirstChild("MagicHealth")
									else
										(function()
											return (bit32 and 742373952 or 0x14cc)
										end)()
									end
									_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x6cbe), 0xd4e99)
								elseif _hSgF1 - 0xbac99 == 0x0 then
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										(function()
											return (bit32 and (65224 * 0x3d % 0x10000) or 0xe396)
										end)()
									else
										(function()
											return (bit32 and 26874 or 0xfc73)
										end)()
									end
									if 0 == 0x0 then
										_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x86d6), 0x3d6c4)
									else
										(function()
											return (bit32 and 75919865 or 0x9992)
										end)()
									end
								elseif _hSgF1 - 0xed56b == 0x0 then
									return _a_wrZ ~= ({})[1] and _a_wrZ["Size"]["Y"]["Scale"] > (10 / 0x3e8)
								elseif _hSgF1 == 0x774c0 then
									if 1 == 0x1 then
										_a_wrZ = _NfZkW and _NfZkW:FindFirstChild("Fill")
									else
										(function()
											return (bit32 and 56744 or 0xc9a9)
										end)()
									end
									if 1 == 0x1 then
										_hSgF1 = bit32.bxor(_hSgF1 + 0x2612, 0x94fb9)
									else
										(function()
											return (bit32 and 2985 or 0x8569)
										end)()
									end
								elseif _hSgF1 == 0xb9b83 then
									_lKoRm = _uXYDT and _uXYDT:FindFirstChild("cdholder")
									_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x1858), 0x5284e)
								elseif bit32.bxor(_hSgF1, 0xeab95) == 0x0 then
									_o1NOl = _lKoRm and _lKoRm:FindFirstChild("forward", true)
									_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x3961), 0x979d7)
								elseif _hSgF1 - 0x8fc8b == 0x0 then
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										(function()
											return (bit32 and 24565 or 0x1e11)
										end)()
									else
										(function()
											return (bit32 and 38106 or 0xcddf)
										end)()
									end
									_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x28ab), 0xff2a5)
								elseif _hSgF1 - 0x7eb23 == 0x0 then
									if 129 == 0x81 then
										_NfZkW = _o1NOl and _o1NOl:FindFirstChild("template")
									else
										(function()
											return (bit32 and 29466 or 0x5973)
										end)()
									end
									_hSgF1 = bit32.bxor(_hSgF1 + 0xb088, 0xfef6b)
								elseif _hSgF1 == 0x72685 then
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										(function()
											return ((0x2515 % 0x2 == 0x0) and (bit32 and 4746 or 0x0) or (bit32 and 903 or 0x0))
										end)()
									else
										(function()
											return (bit32 and (11232 * 0x3d % 0x10000) or 0x28ca)
										end)()
									end
									if 0 == 0x0 then
										_hSgF1 = bit32.bxor(bit32.bxor(_hSgF1, 0x71d5), 0xcfbc9)
									else
										(function()
											return ((0x7681 % 0x2 == 0x0) and (bit32 and 15168 or 0x0) or (bit32 and 16021 or 0x0))
										end)()
									end
								end
							else
								(function()
									return (bit32 and 459431161 or 0x23e5)
								end)()
							end
						end
					else
						(function()
							return (bit32 and (6790 * 0x3d % 0x10000) or 0x1861)
						end)()
					end
				end
				_dcE27["frontDashAt"] = 0
				local function _zk6rn(_MCg8k)
					local _iJgJ4, _iJgJ4
					_iJgJ4 = 0xb481c
					while _iJgJ4 do
						if 16 == 0x10 then
							if bit32.bxor(_iJgJ4, 0x708d8) == 0x0 then
								workspace:SetAttribute("NoDashCooldown", (_MCg8k and { true } or { _dcE27["serverNoDash"] })[1])
								if 0 == 0x0 then
									_iJgJ4 = bit32.bxor(bit32.bxor(_iJgJ4, 0x42c), 0xce37b)
								else
									(function()
										return (bit32 and 53875 or 0x16d3)
									end)()
								end
							elseif _iJgJ4 == 0x68157 then
								_dcE27["spoofingDash"] = true
								if 65535 == 0xffff then
									_iJgJ4 = bit32.bxor(bit32.bxor(_iJgJ4, 0x60d3), 0x1e95c)
								else
									(function()
										return (bit32 and 17243 or 0x485b)
									end)()
								end
							elseif _iJgJ4 == 0x18a27 then
								if 129 == 0x81 then
									(function()
										return ((0x6b79 % 0x2 == 0x0) and (bit32 and 13756 or 0x0) or (bit32 and 46517 or 0x0))
									end)()
								else
									(function()
										return (bit32 and 17624 or 0x2844)
									end)()
								end
								_iJgJ4 = bit32.bxor(_iJgJ4 + 0x906d, 0x544ff)
							elseif _iJgJ4 - 0xb481c == 0x0 then
								if 129 == 0x81 then
									if
										workspace:GetAttribute("NoDashCooldown")
											== (_MCg8k and { true } or { _dcE27["serverNoDash"] })[1]
										and workspace:GetAttribute("EffectAffects")
											== (_MCg8k and { (1 + 0) } or {
												_dcE27["serverEffect"],
											})[1]
									then
										return
									end
								else
									(function()
										return (bit32 and (7772 * 0x3d % 0x10000) or 0x22b3)
									end)()
								end
								_iJgJ4 = bit32.bxor(bit32.bxor(_iJgJ4, 0x3a51), 0xdf31a)
							elseif _iJgJ4 - 0x7e179 == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									(function()
										return (bit32 and 27315 or 0x6ebf)
									end)()
								else
									(function()
										return (bit32 and (34107 * 0x3d % 0x10000) or 0x87e8)
									end)()
								end
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_iJgJ4 = bit32.bxor(bit32.bxor(_iJgJ4, 0xbbf), 0x660e1)
								else
									(function()
										return (bit32 and 5892 or 0x7c17)
									end)()
								end
							elseif _iJgJ4 - 0x75e6b == 0x0 then
								if 65535 == 0xffff then
									(function()
										return (bit32 and (33868 * 0x3d % 0x10000) or 0x851c)
									end)()
								else
									(function()
										return (bit32 and 47119 or 0x281f)
									end)()
								end
								_iJgJ4 = bit32.bxor(_iJgJ4 + 0x796e, 0xe0462)
							elseif bit32.bxor(_iJgJ4, 0xbef8f) == 0x0 then
								workspace:SetAttribute("EffectAffects", (_MCg8k and { (1 + 0) } or { _dcE27["serverEffect"] })[1])
								if 16 == 0x10 then
									_iJgJ4 = bit32.bxor(bit32.bxor(_iJgJ4, 0x686a), 0x7cbb9)
								else
									(function()
										return ((0xd7ed % 0x2 == 0x0) and (bit32 and 27638 or 0x0) or (bit32 and 15713 or 0x0))
									end)()
								end
							elseif _iJgJ4 == 0xc4c5c then
								if 1 == 0x1 then
									_dcE27["spoofingDash"] = false
								else
									(function()
										return (bit32 and 36505 or 0x568e)
									end)()
								end
								if 129 == 0x81 then
									_iJgJ4 = nil
								else
									(function()
										return (bit32 and 15269 or 0xa73b)
									end)()
								end
							elseif _iJgJ4 == 0x9d3bb then
								(function()
									return (bit32 and 2092427557 or 0x8eb0)
								end)()
								if 129 == 0x81 then
									_iJgJ4 = bit32.bxor(_iJgJ4 + 0xc08c, 0xd753e)
								else
									(function()
										return ((0x7fbf % 0x2 == 0x0) and (bit32 and 16351 or 0x0) or (bit32 and 16495 or 0x0))
									end)()
								end
							end
						else
							(function()
								return (bit32 and 65379 or 0x2705)
							end)()
						end
					end
				end
				_l3G1i(workspace:GetAttributeChangedSignal("NoDashCooldown"), function()
					if not _dcE27["spoofingDash"] then
						_dcE27["serverNoDash"] = workspace:GetAttribute("NoDashCooldown")
					end
				end)
				if 129 == 0x81 then
					_l3G1i(workspace:GetAttributeChangedSignal("EffectAffects"), function()
						if not _dcE27["spoofingDash"] then
							_dcE27["serverEffect"] = workspace:GetAttribute("EffectAffects")
						end
					end)
				else
					(function()
						return (bit32 and 6054 or 0x1743)
					end)()
				end
				local function _lsV0R()
					if _Z0Hry and _Z0Hry:FindFirstChild("DashReset3rd") then
						return true
					end
					if not _dcE27["serverNoDash"] then
						return false
					end
					return _dcE27["serverEffect"] == 1 or workspace:GetAttribute("VIPServerOwner") == HubLocalPlayer["Name"]
				end
				local function _Om_zX()
					if 16 == 0x10 then
						if _lsV0R() then
							return true
						end
					else
						(function()
							return (bit32 and 15846 or 0x76ca)
						end)()
					end
					return not _ecSEyI or (tick() - _dcE27["frontDashAt"] >= (500 / 0x3e8) and not _wQo4g())
				end
				local function _XjK2G()
					local _AOY0t, _rTfy7, _rTfy7
					if 0 == 0x0 then
						_rTfy7 = 0xded6a
					else
						(function()
							return (bit32 and 984131436 or 0x9d3b)
						end)()
					end
					while _rTfy7 do
						if 129 == 0x81 then
							if _rTfy7 == 0xd7f94 then
								if not _lsV0R() then
									_ecSEyI = true
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										task["delay"](5, function()
											_ecSEyI = false
										end)
									else
										(function()
											return (bit32 and 2525 or 0xbf09)
										end)()
									end
								end
								_rTfy7 = bit32.bxor(_rTfy7 + 0x3385, 0x5442f)
							elseif _rTfy7 == 0xad5d6 then
								if 1 == 0x1 then
									_dcE27["frontDashAt"] = tick()
								else
									(function()
										return (bit32 and 27884 or 0xcf6c)
									end)()
								end
								_rTfy7 = bit32.bxor(_rTfy7 + 0x1368, 0x796aa)
							elseif _rTfy7 == 0xe854b then
								if not _AOY0t then
									return
								end
								_rTfy7 = bit32.bxor(_rTfy7 + 0x52ea, 0x3c34)
							elseif _rTfy7 - 0x8f736 == 0x0 then
								return true
							elseif _rTfy7 - 0x58a6b == 0x0 then
								(function()
									return (bit32 and (33120 * 0x3d % 0x10000) or 0x8225)
								end)()
								_rTfy7 = bit32.bxor(_rTfy7 + 0x7b36, 0x3c9cb)
							elseif bit32.bxor(_rTfy7, 0x5cc6a) == 0x0 then
								if 129 == 0x81 then
									(function()
										return ((0x46f % 0x2 == 0x0) and (bit32 and 567 or 0x0) or (bit32 and 3213 or 0x0))
									end)()
								else
									(function()
										return (bit32 and 55486 or 0xd8e1)
									end)()
								end
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_rTfy7 = bit32.bxor(bit32.bxor(_rTfy7, 0xace9), 0x115d5)
								else
									(function()
										return (bit32 and (61714 * 0x3d % 0x10000) or 0xfbd2)
									end)()
								end
							elseif _rTfy7 - 0x2b2d7 == 0x0 then
								_AOY0t = _tew4S()
								_rTfy7 = bit32.bxor(bit32.bxor(_rTfy7, 0x70d2), 0xc474e)
							elseif _rTfy7 - 0xded6a == 0x0 then
								if not _Om_zX() then
									return
								end
								_rTfy7 = bit32.bxor(bit32.bxor(_rTfy7, 0x3179), 0xf6ec4)
							elseif _rTfy7 - 0x61ecd == 0x0 then
								if 1 == 0x1 then
									(function()
										return (bit32 and 35778 or 0xcdb4)
									end)()
								else
									(function()
										return (bit32 and 422561324 or 0x988c)
									end)()
								end
								_rTfy7 = bit32.bxor(_rTfy7 + 0xabcb, 0x340f3)
							elseif _rTfy7 - 0xee401 == 0x0 then
								_AOY0t:FireServer(_Ws0Y9["frontDash"])
								_rTfy7 = bit32.bxor(bit32.bxor(_rTfy7, 0xa894), 0x49943)
							elseif _rTfy7 == 0x47556 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									(function()
										return (bit32 and (15032 * 0x3d % 0x10000) or 0x3f78)
									end)()
								else
									(function()
										return (bit32 and 6570 or 0xcf8a)
									end)()
								end
								_rTfy7 = bit32.bxor(_rTfy7 + 0x872f, 0x2e248)
							end
						else
							(function()
								return (bit32 and 7157 or 0xb41b)
							end)()
						end
					end
				end
				local function _ZGKm8(_mYAHa)
					if not _zE8Ni then
						return
					end
					for _Lipbf, _Y1ASW in ipairs(_zE8Ni:GetPlayingAnimationTracks()) do
						if 0 == 0x0 then
							if
								_Y1ASW["Animation"]
								and _Y1ASW["Animation"]["AnimationId"] == "rbxassetid://" .. tostring(_mYAHa)
							then
								_Y1ASW:Stop()
							end
						else
							(function()
								return (bit32 and 49146 or 0x3b82)
							end)()
						end
					end
				end
				local function _xFaaK(_aLwZR, _jjZjS)
					local _M_J_a, _lsqPd, _QoAYy, _QoAYy
					_QoAYy = 0xa4c5e
					while _QoAYy do
						if 1 == 0x1 then
							if bit32.bxor(_QoAYy, 0x9b8d7) == 0x0 then
								if 65535 == 0xffff then
									_lsqPd = tostring(_aLwZR)
								else
									(function()
										return (bit32 and 5247 or 0x9569)
									end)()
								end
								_QoAYy = bit32.bxor(bit32.bxor(_QoAYy, 0xbd3d), 0x7408a)
							elseif _QoAYy == 0xa4c5e then
								if not _jjZjS then
									_M_J_a = _zE8Ni
								else
									if 0 == 0x0 then
										_M_J_a = _jjZjS:FindFirstChildOfClass("Animator") or _jjZjS:FindFirstChild("Animator")
									else
										(function()
											return (bit32 and 802220386 or 0x6d1a)
										end)()
									end
								end
								_QoAYy = bit32.bxor(bit32.bxor(_QoAYy, 0x2e73), 0x9d729)
							elseif bit32.bxor(_QoAYy, 0xa1922) == 0x0 then
								(function()
									return (bit32 and 229795212 or 0x9757)
								end)()
								_QoAYy = bit32.bxor(bit32.bxor(_QoAYy, 0x967b), 0xe0b6)
							elseif _QoAYy - 0x667a4 == 0x0 then
								(function()
									return (bit32 and (18645 * 0x3d % 0x10000) or 0x4815)
								end)()
								_QoAYy = bit32.bxor(_QoAYy + 0xa6af, 0xd1771)
							elseif _QoAYy == 0xa6fef then
								(function()
									return (bit32 and 1900457896 or 0x61c2)
								end)()
								if 1 == 0x1 then
									_QoAYy = bit32.bxor(bit32.bxor(_QoAYy, 0x8972), 0xc8139)
								else
									(function()
										return (bit32 and (47560 * 0x3d % 0x10000) or 0x9e92)
									end)()
								end
							elseif _QoAYy - 0xe4560 == 0x0 then
								for _yKfvP, _XwGo_ in ipairs(_M_J_a:GetPlayingAnimationTracks()) do
									local _k3VVm = _XwGo_["Animation"]
									if
										_k3VVm
										and _k3VVm["AnimationId"]
										and string["find"](_k3VVm["AnimationId"], _lsqPd, (1 + 0x2 * 0), true)
									then
										return true
									end
								end
								_QoAYy = bit32.bxor(_QoAYy + 0x1fc5, 0x73790)
							elseif bit32.bxor(_QoAYy, 0x3b504) == 0x0 then
								if not _M_J_a then
									return false
								end
								_QoAYy = bit32.bxor(_QoAYy + 0xb9f1, 0xdd622)
							elseif bit32.bxor(_QoAYy, 0x952b5) == 0x0 then
								return false
							end
						else
							(function()
								return (bit32 and 1642786244 or 0xb721)
							end)()
						end
					end
				end
				local function _JrRW2(_mz4aKkaE, _vrzr7Kh)
					if not _mz4aKkaE or not _mz4aKkaE["Name"] then
						return false
					end
					if _RWZpc[_mz4aKkaE["Name"]] == "Friend" then
						if _vrzr7Kh then
							if 1 == 0x1 then
								if HubSettings["Misc"]["FriendCheck"] then
									return true
								else
									return false
								end
							else
								(function()
									return (bit32 and 2879 or 0x1ff8)
								end)()
							end
						else
							return true
						end
					else
						return false
					end
				end
				local function _YWFA4n(_xaeMm)
					if not _RWZpc[_xaeMm["Name"]] then
						_RWZpc[_xaeMm["Name"]] = "Neutral"
					end
					local _KVsoZ0kz, _ksUWjn = pcall(function()
						return _xaeMm:IsFriendsWithAsync(HubLocalPlayer["UserId"])
					end)
					if _KVsoZ0kz and _ksUWjn then
						_RWZpc[_xaeMm["Name"]] = "Friend"
					end
				end
				local function _v7Dwg8E(_eVgfUI, _DBWw2, _sYBrbRXB)
					_AuGxA["CFrame"] = CFrame["new"](_eVgfUI) * CFrame["Angles"](0, _DBWw2, 0) * CFrame["Angles"](_sYBrbRXB, 0, 0)
				end
				local function _RnQ1A5M(_qInq7MUP, _fwEVN, _Ea8sVU, _to77V, _SE4N6, _r_DxI)
					if (not _Ea8sVU and not _to77V) and not _qInq7MUP then
						_Ea8sVU = true
					end
					local _g97xt = _Ea8sVU or _to77V
					local _FG_MQ = not _Ea8sVU or _to77V
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if _g97xt and not (_fx2la and _y4IB9) then
							return
						end
					else
						(function()
							return (bit32 and 53998 or 0xc124)
						end)()
					end
					_r_DxI = _r_DxI or (1 + 0x2 * 0)
					local _er2eU = _AuGxA["CFrame"]
					local _T71EJ = _er2eU["Position"]
					local _slybh = _T71EJ
					if UserInputService["MouseBehavior"] == Enum["MouseBehavior"]["LockCenter"] then
						_slybh = _slybh - _er2eU["RightVector"] * ((875 + 875) / 0x3e8)
					end
					local _hBoOZ = math["asin"](_er2eU["LookVector"]["Y"])
					local _GZBmd
					local _ffQog
					if 0 == 0x0 then
						if _fwEVN then
							local _UN0va
							if 16 == 0x10 then
								if _g97xt then
									_UN0va = (_fwEVN - _fx2la["Position"])["Unit"]
									_ffQog =
										math["atan2"](-_fx2la["CFrame"]["LookVector"]["X"], -_fx2la["CFrame"]["LookVector"]["Z"])
								else
									_UN0va = (_fwEVN - _slybh)["Unit"]
									if 16 == 0x10 then
										_ffQog = math["atan2"](-_er2eU["LookVector"]["X"], -_er2eU["LookVector"]["Z"])
									else
										(function()
											return (bit32 and 52822 or 0xeb96)
										end)()
									end
								end
							else
								(function()
									return (bit32 and 1196004306 or 0x9d58)
								end)()
							end
							_GZBmd = math["atan2"](-_UN0va["X"], -_UN0va["Z"])
						else
							local _twjOb = _g97xt and _fx2la["CFrame"]["LookVector"] or _er2eU["LookVector"]
							_ffQog = math["atan2"](-_twjOb["X"], -_twjOb["Z"])
							_GZBmd = _ffQog + math["rad"](_qInq7MUP)
						end
					else
						(function()
							return (bit32 and (18692 * 0x3d % 0x10000) or 0x53c7)
						end)()
					end
					local _Sb40N = math["atan2"](math["sin"](_GZBmd - _ffQog), math["cos"](_GZBmd - _ffQog))
					local _Hg8uG = _ffQog + _Sb40N * _r_DxI
					if 0 == 0x0 then
						if _g97xt then
							_y4IB9["AutoRotate"] = false
							_fx2la["CFrame"] = CFrame["new"](_fx2la["Position"]) * CFrame["Angles"](0, _Hg8uG, 0)
							if not _FG_MQ then
								return
							end
						end
					else
						(function()
							return (bit32 and 37605 or 0x4792)
						end)()
					end
					_v7Dwg8E(_T71EJ, _Hg8uG, _hBoOZ)
				end
				local function _gMeqn(_VvPRR, _ucV8j, _TSxd0)
					local _IzF4d, _hJJZz, _GcDR2, _BRX45, _hc1gT, _CzaER, _HJQMv, _aqk8FSHV, _aqk8FSHV
					_aqk8FSHV = 0x69fcd
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						while _aqk8FSHV do
							if _aqk8FSHV - 0xd0673 == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_CzaER = _hc1gT + _IzF4d
								else
									(function()
										return (bit32 and 362209658 or 0x5938)
									end)()
								end
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0x3269), 0xdbeb8)
							elseif _aqk8FSHV == 0xbf70b then
								_BRX45 = _GcDR2["LookVector"]
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0xa905), 0xa2897)
							elseif _aqk8FSHV - 0xedd37 == 0x0 then
								if 16 == 0x10 then
									(function()
										return ((0x6121 % 0x2 == 0x0) and (bit32 and 12432 or 0x0) or (bit32 and 47994 or 0x0))
									end)()
								else
									(function()
										return (bit32 and 973858812 or 0x2acc)
									end)()
								end
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_aqk8FSHV = bit32.bxor(_aqk8FSHV + 0x931d, 0x3ce7b)
								else
									(function()
										return ((0x37b5 % 0x2 == 0x0) and (bit32 and 7130 or 0x0) or (bit32 and 60384 or 0x0))
									end)()
								end
							elseif _aqk8FSHV == 0xcbe2f then
								(function()
									return (bit32 and 5659 or 0x962b)
								end)()
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0xa71c), 0x2c404)
							elseif _aqk8FSHV == 0x1f0ed then
								if 16 == 0x10 then
									RunService:BindToRenderStep(
										_HJQMv,
										Enum["RenderPriority"]["Camera"]["Value"] + (1 + 0x2 * 0),
										function()
											local _sJFe_, _N6sTT, _SsaC7, _DYmAt, _YBTX7, _dfzaP, _y43bf, _j5e1y, _ZRRaY, _ZRRaY
											_ZRRaY = 0x8ee1
											while _ZRRaY do
												if _ZRRaY == 0x5362b then
													_dfzaP = _DYmAt["LookVector"]
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0xbe86), 0xc3759)
												elseif _ZRRaY == 0xb3e9f then
													_j5e1y = _hc1gT + (_CzaER - _hc1gT) * _SsaC7
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0x1ca4), 0xa8a8e)
												elseif _ZRRaY == 0x594e6 then
													_YBTX7 = _DYmAt["Position"]
													_ZRRaY = bit32.bxor(_ZRRaY + 0x81ca, 0x3209b)
												elseif _ZRRaY == 0xc8224 then
													_SsaC7 = _N6sTT * _N6sTT * (3 - (1 + 1) * _N6sTT)
													_ZRRaY = bit32.bxor(_ZRRaY + 0x1cd6, 0x6b7f9)
												elseif _ZRRaY == 0xa2903 then
													_DYmAt = _AuGxA["CFrame"]
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0x42e9), 0xfff0c)
												elseif _ZRRaY - 0x8ee1 == 0x0 then
													_sJFe_ = tick() - _hJJZz
													_ZRRaY = bit32.bxor(_ZRRaY + 0x8169, 0xdff6c)
												elseif _ZRRaY == 0x6a540 then
													(function()
														return (bit32 and (56009 * 0x3d % 0x10000) or 0xe1df)
													end)()
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0x53f), 0x2aee2)
												elseif _ZRRaY == 0x40edc then
													if _N6sTT >= (1 + 0) then
														RunService:UnbindFromRenderStep(_HJQMv)
														_XNd6n[_HJQMv] = ({})[1]
													end
													_ZRRaY = nil
												elseif _ZRRaY - 0x2bf22 == 0x0 then
													(function()
														return (bit32 and 19879 or 0x4bd1)
													end)()
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0xb837), 0x4a255)
												elseif _ZRRaY - 0x9bff4 == 0x0 then
													_y43bf = math["asin"](_dfzaP["Y"])
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0xb996), 0x238fd)
												elseif bit32.bxor(_ZRRaY, 0xcef26) == 0x0 then
													_N6sTT = math["clamp"](_sJFe_ / _ucV8j, 0, 1)
													_ZRRaY = bit32.bxor(_ZRRaY + 0x1701, 0x18403)
												elseif bit32.bxor(_ZRRaY, 0x40e9d) == 0x0 then
													(function()
														return (bit32 and 13346 or 0x2734)
													end)()
													_ZRRaY = bit32.bxor(bit32.bxor(_ZRRaY, 0x6dcc), 0x6dc73)
												elseif _ZRRaY == 0x1a8b5 then
													if _TSxd0 then
														_y4IB9["AutoRotate"] = false
														_fx2la["CFrame"] = CFrame["new"](_fx2la["Position"])
															* CFrame["Angles"](0, _j5e1y, 0)
													else
														_v7Dwg8E(_YBTX7, _j5e1y, _y43bf)
													end
													_ZRRaY = bit32.bxor(_ZRRaY + 0x95d5, 0x63056)
												end
											end
										end
									)
								else
									(function()
										return (bit32 and 65311 or 0x9396)
									end)()
								end
								if 1 == 0x1 then
									_aqk8FSHV = nil
								else
									(function()
										return (bit32 and (49846 * 0x3d % 0x10000) or 0xc8e4)
									end)()
								end
							elseif _aqk8FSHV == 0xb5289 then
								_XNd6n[_HJQMv] = true
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0x1af1), 0xab895)
							elseif bit32.bxor(_aqk8FSHV, 0x69fcd) == 0x0 then
								if _TSxd0 and not (_fx2la and _y4IB9) then
									return
								end
								_aqk8FSHV = bit32.bxor(_aqk8FSHV + 0x2faf, 0x5a432)
							elseif _aqk8FSHV - 0x9cf20 == 0x0 then
								if 65535 == 0xffff then
									_GcDR2 = _TSxd0 and _fx2la["CFrame"] or _AuGxA["CFrame"]
								else
									(function()
										return (bit32 and (8319 * 0x3d % 0x10000) or 0x770f)
									end)()
								end
								if 0 == 0x0 then
									_aqk8FSHV = bit32.bxor(_aqk8FSHV + 0xbb48, 0x17d63)
								else
									(function()
										return (bit32 and (22940 * 0x3d % 0x10000) or 0x5b85)
									end)()
								end
							elseif bit32.bxor(_aqk8FSHV, 0x36b4e) == 0x0 then
								_ucV8j = math["max"](tonumber(_ucV8j) or 0, 1 / 240)
								if 0 == 0x0 then
									_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0x827c), 0x1214c)
								else
									(function()
										return (bit32 and 14556 or 0x98ff)
									end)()
								end
							elseif _aqk8FSHV - 0x17699 == 0x0 then
								_hc1gT = math["atan2"](-_BRX45["X"], -_BRX45["Z"])
								_aqk8FSHV = bit32.bxor(_aqk8FSHV + 0x696c, 0xce676)
							elseif _aqk8FSHV == 0x2c87e then
								_IzF4d = math["rad"](_VvPRR)
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0x20fc), 0x39839)
							elseif bit32.bxor(_aqk8FSHV, 0x170bb) == 0x0 then
								_hJJZz = tick()
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0xb5ef), 0x80a74)
							elseif _aqk8FSHV == 0x8aa2 then
								if 65535 == 0xffff then
									_HJQMv = "KittyWareSmoothRotateCamera" .. tostring(tick())
								else
									(function()
										return (bit32 and 13745 or 0x8135)
									end)()
								end
								_aqk8FSHV = bit32.bxor(bit32.bxor(_aqk8FSHV, 0x9c4c), 0xb4467)
							end
						end
					else
						(function()
							return ((0x82e6 % 0x2 == 0x0) and (bit32 and 16755 or 0x0) or (bit32 and 62809 or 0x0))
						end)()
					end
				end
				local function _oIwtD(_JmENB, _umBhB)
					local _z1hub, _UDjDI, _FEYxn, _atCUT, _snFqFw3I, _snFqFw3I
					_snFqFw3I = 0x31177
					while _snFqFw3I do
						if 65535 == 0xffff then
							if _snFqFw3I == 0xf11f6 then
								_z1hub = tick()
								_snFqFw3I = bit32.bxor(bit32.bxor(_snFqFw3I, 0x2ffd), 0xd23f6)
							elseif bit32.bxor(_snFqFw3I, 0x69cc0) == 0x0 then
								_XNd6n[_atCUT] = true
								_snFqFw3I = bit32.bxor(_snFqFw3I + 0xad04, 0xe90d2)
							elseif bit32.bxor(_snFqFw3I, 0x97dda) == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									(function()
										return (bit32 and 21459 or 0x7347)
									end)()
								else
									(function()
										return (bit32 and 42032 or 0x3079)
									end)()
								end
								_snFqFw3I = bit32.bxor(_snFqFw3I + 0x6b93, 0x4013c)
							elseif _snFqFw3I == 0x3624f then
								if 129 == 0x81 then
									if _umBhB <= 0 then
										_umBhB = ((40 + 40) / 0x3e8)
									end
								else
									(function()
										return (bit32 and (24898 * 0x3d % 0x10000) or 0x7056)
									end)()
								end
								_snFqFw3I = bit32.bxor(_snFqFw3I + 0xbeaf, 0xb3108)
							elseif _snFqFw3I == 0x31177 then
								if not _AuGxA or not _JmENB then
									return
								end
								if 0 == 0x0 then
									_snFqFw3I = bit32.bxor(bit32.bxor(_snFqFw3I, 0x3d11), 0x7419c)
								else
									(function()
										return (bit32 and (46977 * 0x3d % 0x10000) or 0x9285)
									end)()
								end
							elseif bit32.bxor(_snFqFw3I, 0x9d916) == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									RunService:BindToRenderStep(
										_atCUT,
										Enum["RenderPriority"]["Camera"]["Value"] + (0x2 * 1 - 1),
										function()
											local _f7nB1, _QW2yY, _lLgcC, _qoChn, _b07wb6f, _wgbDhbsh, _BFfk8, _WScTox, _HTriEnK, _MlaAOylK, _hyiVz, _jNkcGR_, _jNkcGR_
											_jNkcGR_ = 0x246fc
											while _jNkcGR_ do
												if _jNkcGR_ - 0x3b3f1 == 0x0 then
													_v7Dwg8E(_b07wb6f, _MlaAOylK, _hyiVz)
													_jNkcGR_ = bit32.bxor(bit32.bxor(_jNkcGR_, 0x28b1), 0x5d67e)
												elseif _jNkcGR_ == 0x8307e then
													_qoChn = _AuGxA["CFrame"]
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x5ae2, 0xd0b42)
												elseif _jNkcGR_ - 0x77bb6 == 0x0 then
													_hyiVz = math["asin"](_qoChn["LookVector"]["Y"])
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0xb28f, 0xb9db4)
												elseif _jNkcGR_ == 0xa47cf then
													_lLgcC = _QW2yY * _QW2yY * (3 - 2 * _QW2yY)
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x7481, 0x28c2e)
												elseif _jNkcGR_ == 0x58022 then
													_b07wb6f = _qoChn["Position"]
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x7ba4, 0x43b8f)
												elseif _jNkcGR_ - 0x13080 == 0x0 then
													_BFfk8 = (_JmENB - _wgbDhbsh)["Unit"]
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x12ff, 0x792c5)
												elseif bit32.bxor(_jNkcGR_, 0x75e4e) == 0x0 then
													(function()
														return (bit32 and 1690451542 or 0x7139)
													end)()
													_jNkcGR_ = bit32.bxor(bit32.bxor(_jNkcGR_, 0xaf59), 0xb1593)
												elseif _jNkcGR_ - 0x64d3e == 0x0 then
													if _QW2yY >= 1 then
														RunService:UnbindFromRenderStep(_atCUT)
														_XNd6n[_atCUT] = ({})[1]
													end
													_jNkcGR_ = nil
												elseif bit32.bxor(_jNkcGR_, 0x1dfa7) == 0x0 then
													_HTriEnK =
														math["atan2"](math["sin"](_WScTox - _FEYxn), math["cos"](_WScTox - _FEYxn))
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x66d0, 0xc2bba)
												elseif _jNkcGR_ == 0x71226 then
													_QW2yY = math["clamp"](_f7nB1 / _umBhB, 0, 1)
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x3503, 0xd00e6)
												elseif bit32.bxor(_jNkcGR_, 0x246fc) == 0x0 then
													_f7nB1 = tick() - _z1hub
													_jNkcGR_ = bit32.bxor(bit32.bxor(_jNkcGR_, 0x6c95), 0x5384f)
												elseif _jNkcGR_ - 0x1e87d == 0x0 then
													if UserInputService["MouseBehavior"] == Enum["MouseBehavior"]["LockCenter"] then
														_wgbDhbsh = _wgbDhbsh - _qoChn["RightVector"] * ((875 + 875) / 0x3e8)
													end
													_jNkcGR_ = bit32.bxor(bit32.bxor(_jNkcGR_, 0x15d4), 0xcd29)
												elseif _jNkcGR_ == 0xe6dcd then
													_MlaAOylK = _FEYxn + _HTriEnK * _lLgcC
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x4890, 0x9cdeb)
												elseif _jNkcGR_ - 0xce484 == 0x0 then
													(function()
														return (bit32 and (47502 * 0x3d % 0x10000) or 0xa0ee)
													end)()
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x1932, 0xba3f8)
												elseif _jNkcGR_ == 0x1c049 then
													_wgbDhbsh = _b07wb6f
													_jNkcGR_ = bit32.bxor(bit32.bxor(_jNkcGR_, 0x2169), 0x95d)
												elseif _jNkcGR_ == 0x6d1ba then
													_WScTox = math["atan2"](-_BFfk8["X"], -_BFfk8["Z"])
													_jNkcGR_ = bit32.bxor(_jNkcGR_ + 0x7347, 0x69aa6)
												end
											end
										end
									)
								else
									(function()
										return (bit32 and (65287 * 0x3d % 0x10000) or 0xfcad)
									end)()
								end
								_snFqFw3I = nil
							elseif _snFqFw3I == 0xde851 then
								if 0 == 0x0 then
									(function()
										return (bit32 and 26098 or 0x56d2)
									end)()
								else
									(function()
										return (bit32 and (586 * 0x3d % 0x10000) or 0xe97)
									end)()
								end
								if 65535 == 0xffff then
									_snFqFw3I = bit32.bxor(_snFqFw3I + 0x6de5, 0x72bec)
								else
									(function()
										return (bit32 and (62919 * 0x3d % 0x10000) or 0xf58a)
									end)()
								end
							elseif _snFqFw3I == 0x46dfa then
								_umBhB = _umBhB or 0
								_snFqFw3I = bit32.bxor(_snFqFw3I + 0x86ea, 0x796ab)
							elseif bit32.bxor(_snFqFw3I, 0x8a874) == 0x0 then
								_atCUT = "KittyWareSmoothRotateCamToPos"
									.. tostring(tick())
									.. tostring(math["random"](1000, (5007 + 4992)))
								_snFqFw3I = bit32.bxor(bit32.bxor(_snFqFw3I, 0x5b19), 0xe6fad)
							elseif _snFqFw3I - 0x98cd2 == 0x0 then
								_FEYxn = math["atan2"](-_UDjDI["X"], -_UDjDI["Z"])
								_snFqFw3I = bit32.bxor(bit32.bxor(_snFqFw3I, 0xa21a), 0x186bc)
							elseif bit32.bxor(_snFqFw3I, 0x21dfd) == 0x0 then
								if 16 == 0x10 then
									_UDjDI = _AuGxA["CFrame"]["LookVector"]
								else
									(function()
										return (bit32 and 41659 or 0xccb1)
									end)()
								end
								_snFqFw3I = bit32.bxor(bit32.bxor(_snFqFw3I, 0x94a5), 0xb058a)
							end
						else
							(function()
								return (bit32 and 11537 or 0x702d)
							end)()
						end
					end
				end
				local function _izwxu0(_dYse15H)
					for _Ie20V3hQ = #_vjMDS, 2, -1 do
						local _WpiGcsmp = _vjMDS[_Ie20V3hQ]
						local _DDdVL = _vjMDS[_Ie20V3hQ - 1]
						if _DDdVL["time"] <= _dYse15H and _WpiGcsmp["time"] >= _dYse15H then
							local _wKUwjg = (_dYse15H - _DDdVL["time"]) / (_WpiGcsmp["time"] - _DDdVL["time"])
							return _DDdVL["cf"]:Lerp(_WpiGcsmp["cf"], _wKUwjg)
						end
					end
					return _vjMDS[1] and _vjMDS[(1 + 0x2 * 0)]["cf"]
				end
				local function _N4Idm(_qysva)
					local _nNcCa, _A1RpD = pcall(function()
						return PlayersService:GetUserThumbnailAsync(
							_qysva["UserId"],
							Enum["ThumbnailType"]["HeadShot"],
							Enum["ThumbnailSize"]["Size420x420"]
						)
					end)
					return _nNcCa and _A1RpD or ""
				end
				local function _hXRHJ(_atsG3)
					local _HGlcK, _U8Kks, _R2Swf, _U8KFA7, _U8KFA7
					_U8KFA7 = 0xab70f
					while _U8KFA7 do
						if 65535 == 0xffff then
							if _U8KFA7 == 0x67127 then
								_U8Kks = math["floor"](_atsG3["G"] * 255)
								_U8KFA7 = bit32.bxor(_U8KFA7 + 0x8baa, 0xb6e7d)
							elseif bit32.bxor(_U8KFA7, 0xce131) == 0x0 then
								(function()
									return (bit32 and 57209 or 0x99f1)
								end)()
								_U8KFA7 = bit32.bxor(_U8KFA7 + 0x3890, 0xfd282)
							elseif _U8KFA7 - 0xd92ac == 0x0 then
								if 65535 == 0xffff then
									_R2Swf = math["floor"](_atsG3["B"] * 255)
								else
									(function()
										return (bit32 and (36463 * 0x3d % 0x10000) or 0xa039)
									end)()
								end
								if 0 == 0x0 then
									_U8KFA7 = bit32.bxor(bit32.bxor(_U8KFA7, 0xbe3b), 0x8b46)
								else
									(function()
										return (bit32 and 55277 or 0xade7)
									end)()
								end
							elseif _U8KFA7 == 0x2cb43 then
								if 65535 == 0xffff then
									(function()
										return (bit32 and 770041230 or 0xe881)
									end)()
								else
									(function()
										return (bit32 and (2677 * 0x3d % 0x10000) or 0xb9e)
									end)()
								end
								_U8KFA7 = bit32.bxor(bit32.bxor(_U8KFA7, 0x8c0), 0xe22b2)
							elseif _U8KFA7 == 0xda7d1 then
								return string["format"]("#%02X%02X%02X", _HGlcK, _U8Kks, _R2Swf)
							elseif _U8KFA7 == 0xab70f then
								_HGlcK = math["floor"](_atsG3["R"] * 255)
								_U8KFA7 = bit32.bxor(bit32.bxor(_U8KFA7, 0x1a11), 0xcdc39)
							end
						else
							(function()
								return (bit32 and 52906 or 0x6e0)
							end)()
						end
					end
				end
				local function _uL54o(_LnLfb, _E7BmZ)
					if 129 == 0x81 then
						if not _LnLfb or not _E7BmZ then
							return false
						end
					else
						(function()
							return (bit32 and 37504 or 0x12e2)
						end)()
					end
					for _lVlTc, _ys134 in ipairs(_LnLfb:GetChildren()) do
						if _E7BmZ[_ys134["Name"]] or table["find"](_E7BmZ, _ys134["Name"]) then
							return false
						end
					end
					return true
				end
				local function _fgMSe(_YbPNa, _pN7KD, _Slwqm)
					local _VSVPy, _VSVPy
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_VSVPy = 0x5921c
					else
						(function()
							return ((0x402a % 0x2 == 0x0) and (bit32 and 8213 or 0x0) or (bit32 and 17488 or 0x0))
						end)()
					end
					if 1 == 0x1 then
						while _VSVPy do
							if _VSVPy == 0x23d2e then
								if 0 == 0x0 then
									_fx2la["CFrame"] = CFrame["new"](_YbPNa["Position"]) * _pN7KD * _Slwqm
								else
									(function()
										return (bit32 and 44749 or 0xce84)
									end)()
								end
								_VSVPy = bit32.bxor(_VSVPy + 0xb866, 0x811e)
							elseif _VSVPy - 0x2748a == 0x0 then
								if 16 == 0x10 then
									_Z0Hry:SetPrimaryPartCFrame(CFrame["new"](_YbPNa["Position"]) * _pN7KD * _Slwqm)
								else
									(function()
										return (bit32 and 46633 or 0xb629)
									end)()
								end
								if 129 == 0x81 then
									_VSVPy = bit32.bxor(_VSVPy + 0xb579, 0xfc70c)
								else
									(function()
										return (bit32 and (42398 * 0x3d % 0x10000) or 0xa37d)
									end)()
								end
							elseif _VSVPy - 0x5921c == 0x0 then
								if not (_Z0Hry and _Z0Hry["PrimaryPart"] and _fx2la) then
									return
								end
								_VSVPy = bit32.bxor(bit32.bxor(_VSVPy, 0x4ff1), 0x7e0c3)
							elseif _VSVPy == 0x846c8 then
								(function()
									return (bit32 and 50133 or 0xd180)
								end)()
								if 0 == 0x0 then
									_VSVPy = bit32.bxor(_VSVPy + 0x2bb4, 0xa917c)
								else
									(function()
										return ((0xbcc4 % 0x2 == 0x0) and (bit32 and 24162 or 0x0) or (bit32 and 10703 or 0x0))
									end)()
								end
							elseif _VSVPy - 0x2e300 == 0x0 then
								(function()
									return (bit32 and 40393707 or 0x73df)
								end)()
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_VSVPy = bit32.bxor(bit32.bxor(_VSVPy, 0x803), 0x15750)
								else
									(function()
										return (bit32 and 27504 or 0x6964)
									end)()
								end
							elseif _VSVPy == 0xace00 then
								if 65535 == 0xffff then
									_fx2la["RotVelocity"] = Vector3["new"](9e8, 9e8, 9e8)
								else
									(function()
										return (bit32 and (11869 * 0x3d % 0x10000) or 0x161e)
									end)()
								end
								if 1 == 0x1 then
									_VSVPy = nil
								else
									(function()
										return (bit32 and 43564 or 0xc8aa)
									end)()
								end
							elseif _VSVPy == 0x3bc53 then
								if 0 == 0x0 then
									(function()
										return (bit32 and 47043 or 0x8513)
									end)()
								else
									(function()
										return (bit32 and 24187 or 0x223e)
									end)()
								end
								if 129 == 0x81 then
									_VSVPy = bit32.bxor(bit32.bxor(_VSVPy, 0x37f2), 0x761a2)
								else
									(function()
										return (bit32 and 41925 or 0x3a3)
									end)()
								end
							elseif bit32.bxor(_VSVPy, 0xced0f) == 0x0 then
								_fx2la["Velocity"] = Vector3["new"](9e7, 9e7 * (0x2 * 5 - 0), 9e7)
								_VSVPy = bit32.bxor(_VSVPy + 0x9b47, 0x74656)
							elseif bit32.bxor(_VSVPy, 0x4ea03) == 0x0 then
								(function()
									return (bit32 and 60615 or 0x2cc3)
								end)()
								if 16 == 0x10 then
									_VSVPy = bit32.bxor(_VSVPy + 0xa8ec, 0xdd427)
								else
									(function()
										return (bit32 and 34786 or 0x8fae)
									end)()
								end
							end
						end
					else
						(function()
							return (bit32 and 37480 or 0xae92)
						end)()
					end
				end
				local function _P4NlG(_cHiKV)
					local _JwPQo = _cHiKV and _cHiKV:FindFirstChild("HumanoidRootPart")
					local _Cqx7Q = _cHiKV and _cHiKV:FindFirstChild("Humanoid")
					if 129 == 0x81 then
						if not (_JwPQo and _Cqx7Q and _fx2la and _Z0Hry) then
							return
						end
					else
						(function()
							return (bit32 and 32130 or 0x59a3)
						end)()
					end
					if 129 == 0x81 then
						_yJXM8 = true
					else
						(function()
							return (bit32 and 10686 or 0xbbce)
						end)()
					end
					local _jZ0QM = Instance["new"]("BodyVelocity")
					if 0 == 0x0 then
						_jZ0QM["Parent"] = _fx2la
					else
						(function()
							return (bit32 and 14365 or 0xcc38)
						end)()
					end
					_jZ0QM["Velocity"] = Vector3["new"](0, 0, 0)
					_jZ0QM["MaxForce"] = Vector3["new"](9e9, 9e9, 9e9)
					local _AY5GD = tick()
					local _DDwwd = 0
					local _avN9S = 0
					local _JtdGl = _fx2la["CFrame"]
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_UbxYIsuM(_fx2la, "CFrame")
					else
						(function()
							return (bit32 and 834964375 or 0xaa3c)
						end)()
					end
					for _QK_ZQ, _jWDW1 in pairs(_Z0Hry:GetChildren()) do
						if _jWDW1:IsA("BasePart") then
							_UbxYIsuM(_jWDW1, "Velocity")
							_UbxYIsuM(_jWDW1, "RotVelocity")
						end
					end
					workspace["FallenPartsDestroyHeight"] = 0 / 0
					if 0 == 0x0 then
						repeat
							local _GdUbO, _GdUbO
							_GdUbO = 0x21b93
							while _GdUbO do
								if 129 == 0x81 then
									if _GdUbO == 0x93f82 then
										if _JwPQo["Velocity"]["Magnitude"] < (0 + 0x2 * 25) then
											if 0 == 0x0 then
												_DDwwd = _DDwwd + 100
											else
												(function()
													return (bit32 and 43118 or 0xa2a8)
												end)()
											end
											if 129 == 0x81 then
												if _avN9S == (0x2 * 1 - 1) then
													_fgMSe(
														_JwPQo,
														CFrame["new"](0, ((0x2 * 750 - 0) / 0x3e8), 0)
															+ _Cqx7Q["MoveDirection"]
																* _JwPQo["Velocity"]["Magnitude"]
																/ (1250 / 0x3e8),
														CFrame["Angles"](math["rad"](_DDwwd), 0, 0)
													)
													_fgMSe(
														_JwPQo,
														CFrame["new"](0, (1500 / 0x3e8), 0) + _Cqx7Q["MoveDirection"],
														CFrame["Angles"](math["rad"](_DDwwd), 0, 0)
													)
												else
													_fgMSe(
														_JwPQo,
														CFrame["new"](0, -((0 + 0x2 * 750) / 0x3e8), 0)
															+ _Cqx7Q["MoveDirection"]
																* _JwPQo["Velocity"]["Magnitude"]
																/ (1250 / 0x3e8),
														CFrame["Angles"](math["rad"](_DDwwd), 0, 0)
													)
													_fgMSe(
														_JwPQo,
														CFrame["new"](0, -((0 + 0x2 * 750) / 0x3e8), 0) + _Cqx7Q["MoveDirection"],
														CFrame["Angles"](math["rad"](_DDwwd), 0, 0)
													)
												end
											else
												(function()
													return (bit32 and 42899 or 0xb4a7)
												end)()
											end
										else
											if _avN9S == (1 + 0) then
												_fgMSe(
													_JwPQo,
													CFrame["new"](0, (1500 / 0x3e8), _Cqx7Q["WalkSpeed"]),
													CFrame["Angles"](math["rad"](90), 0, 0)
												)
												if 1 == 0x1 then
													_fgMSe(
														_JwPQo,
														CFrame["new"](0, -(1500 / 0x3e8), 0),
														CFrame["Angles"](math["rad"](90), 0, 0)
													)
												else
													(function()
														return (bit32 and 156251946 or 0xf15b)
													end)()
												end
											else
												_fgMSe(
													_JwPQo,
													CFrame["new"](0, -(1500 / 0x3e8), -_Cqx7Q["WalkSpeed"]),
													CFrame["Angles"](0, 0, 0)
												)
												if 0 == 0x0 then
													_fgMSe(_JwPQo, CFrame["new"](0, -(1500 / 0x3e8), 0), CFrame["Angles"](0, 0, 0))
												else
													(function()
														return (bit32 and 6957 or 0x8e1b)
													end)()
												end
											end
										end
										if 0 == 0x0 then
											_GdUbO = bit32.bxor(_GdUbO + 0xb905, 0x89ef3)
										else
											(function()
												return (bit32 and 17785 or 0x7ce1)
											end)()
										end
									elseif bit32.bxor(_GdUbO, 0x16674) == 0x0 then
										task["wait"]()
										_GdUbO = nil
									elseif _GdUbO == 0x93384 then
										if 1 == 0x1 then
											(function()
												return (bit32 and 43117 or 0x2a)
											end)()
										else
											(function()
												return (bit32 and (8486 * 0x3d % 0x10000) or 0x605)
											end)()
										end
										if 129 == 0x81 then
											_GdUbO = bit32.bxor(bit32.bxor(_GdUbO, 0xb47a), 0xeb43b)
										else
											(function()
												return (bit32 and 47524 or 0x9db9)
											end)()
										end
									elseif bit32.bxor(_GdUbO, 0x21b93) == 0x0 then
										_avN9S = _avN9S + (1 + 0x2 * 0)
										_GdUbO = bit32.bxor(bit32.bxor(_GdUbO, 0xbd68), 0x7b26a)
									elseif bit32.bxor(_GdUbO, 0x733c5) == 0x0 then
										(function()
											return (bit32 and 11938 or 0x2f2e)
										end)()
										if 16 == 0x10 then
											_GdUbO = bit32.bxor(bit32.bxor(_GdUbO, 0x9a8b), 0xe9aca)
										else
											(function()
												return (bit32 and 16383 or 0x76ac)
											end)()
										end
									elseif _GdUbO == 0x51491 then
										if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
											if _avN9S > (1 + 0x2 * 0) then
												_avN9S = 0
											end
										else
											(function()
												return (
													(0xba35 % 0x2 == 0x0) and (bit32 and 23834 or 0x0)
													or (bit32 and 6869 or 0x0)
												)
											end)()
										end
										if 0 == 0x0 then
											_GdUbO = bit32.bxor(_GdUbO + 0xb24d, 0xcf95c)
										else
											(function()
												return (bit32 and 3565 or 0xf60d)
											end)()
										end
									end
								else
									(function()
										return (bit32 and 983275384 or 0xf724)
									end)()
								end
							end
						until _R5B57 or _AY5GD + (3 + 0x2 * 0) < tick()
					else
						(function()
							return (bit32 and 60391 or 0x3e62)
						end)()
					end
					_jZ0QM:Destroy()
					local _TF4nF = tick() + (3 + 0)
					repeat
						local _jdOQV, _jdOQV
						_jdOQV = 0x8ea1c
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							while _jdOQV do
								if bit32.bxor(_jdOQV, 0x8ea1c) == 0x0 then
									_fx2la["CFrame"] = _JtdGl * CFrame["new"](0, (500 / 0x3e8), 0)
									_jdOQV = bit32.bxor(_jdOQV + 0x90f9, 0x39abc)
								elseif _jdOQV == 0x9d96 then
									(function()
										return (bit32 and 56311 or 0xd33a)
									end)()
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										_jdOQV = bit32.bxor(_jdOQV + 0x1c11, 0x39a84)
									else
										(function()
											return (bit32 and 62326 or 0x66f6)
										end)()
									end
								elseif bit32.bxor(_jdOQV, 0x97086) == 0x0 then
									(function()
										return (bit32 and (27198 * 0x3d % 0x10000) or 0x6b75)
									end)()
									if 65535 == 0xffff then
										_jdOQV = bit32.bxor(_jdOQV + 0x61c7, 0x94fdb)
									else
										(function()
											return (bit32 and (14439 * 0x3d % 0x10000) or 0x3c0f)
										end)()
									end
								elseif _jdOQV - 0xe7fea == 0x0 then
									if 0 == 0x0 then
										task["wait"]()
									else
										(function()
											return (bit32 and (62017 * 0x3d % 0x10000) or 0x82dc)
										end)()
									end
									_jdOQV = nil
								elseif bit32.bxor(_jdOQV, 0x96e00) == 0x0 then
									(function()
										return ((0xa2b9 % 0x2 == 0x0) and (bit32 and 20828 or 0x0) or (bit32 and 338 or 0x0))
									end)()
									_jdOQV = bit32.bxor(_jdOQV + 0x4b40, 0xc9c6)
								elseif bit32.bxor(_jdOQV, 0x32323) == 0x0 then
									(function()
										return (bit32 and 34325 or 0x6f86)
									end)()
									if 0 == 0x0 then
										_jdOQV = bit32.bxor(bit32.bxor(_jdOQV, 0xa1cd), 0xaecee)
									else
										(function()
											return (bit32 and (33496 * 0x3d % 0x10000) or 0x9872)
										end)()
									end
								elseif _jdOQV == 0xae1a9 then
									if 129 == 0x81 then
										_Z0Hry:SetPrimaryPartCFrame(_JtdGl * CFrame["new"](0, (500 / 0x3e8), 0))
									else
										(function()
											return ((0xe692 % 0x2 == 0x0) and (bit32 and 29513 or 0x0) or (bit32 and 27008 or 0x0))
										end)()
									end
									if 0 == 0x0 then
										_jdOQV = bit32.bxor(_jdOQV + 0x2006, 0x65cf)
									else
										(function()
											return (bit32 and 1110690325 or 0x8d0a)
										end)()
									end
								elseif _jdOQV - 0xb6460 == 0x0 then
									for _oibZs, _xoBbm in pairs(_Z0Hry:GetChildren()) do
										if _xoBbm:IsA("BasePart") then
											if 0 == 0x0 then
												_UbxYIsuM(_xoBbm, "Velocity")
											else
												(function()
													return (bit32 and (64606 * 0x3d % 0x10000) or 0xe00e)
												end)()
											end
											_UbxYIsuM(_xoBbm, "RotVelocity")
											_xoBbm["Velocity"], _xoBbm["RotVelocity"] = Vector3["new"](), Vector3["new"]()
										end
									end
									if 1 == 0x1 then
										_jdOQV = bit32.bxor(_jdOQV + 0x2a51, 0x5f15b)
									else
										(function()
											return (bit32 and 65079 or 0x2cfe)
										end)()
									end
								end
							end
						else
							(function()
								return (bit32 and (45715 * 0x3d % 0x10000) or 0xb8b9)
							end)()
						end
					until (_fx2la["Position"] - _JtdGl["Position"])["Magnitude"] < (13 + 12)
						or tick() > _TF4nF
						or not _Z0Hry["Parent"]
					if 0 == 0x0 then
						workspace["FallenPartsDestroyHeight"] = _Z4x1B
					else
						(function()
							return (bit32 and 62642 or 0xc2f0)
						end)()
					end
					if not _R5B57 then
						for _inRrP, _zMSWx in pairs(_Z0Hry:GetChildren()) do
							local _Epdkj = _sDkXo[_zMSWx]
							if _Epdkj then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_Epdkj["CFrame"], _Epdkj["Velocity"], _Epdkj["RotVelocity"] = ({})[1], ({})[1], ({})[1]
								else
									(function()
										return ((0x99b8 % 0x2 == 0x0) and (bit32 and 19676 or 0x0) or (bit32 and 38601 or 0x0))
									end)()
								end
							end
						end
					end
					_yJXM8 = false
				end
				local function _t6uaX(_OgGPD, _PHRBh)
					local _cJ2_o, _cJ2_o
					_cJ2_o = 0x502a
					if 129 == 0x81 then
						while _cJ2_o do
							if 16 == 0x10 then
								if _cJ2_o - 0x47beb == 0x0 then
									_fx2la["AssemblyLinearVelocity"] = Vector3["new"](
										_fx2la["AssemblyLinearVelocity"]["X"] * _OgGPD,
										_fx2la["AssemblyLinearVelocity"]["Y"],
										_fx2la["AssemblyLinearVelocity"]["Z"] * _OgGPD
									)
									_cJ2_o = nil
								elseif _cJ2_o - 0x58d12 == 0x0 then
									_dcE27["boostUntil"] = tick() + (1 + 0)
									_cJ2_o = bit32.bxor(bit32.bxor(_cJ2_o, 0x6939), 0x19fc0)
								elseif _cJ2_o - 0xc6923 == 0x0 then
									if _xFaaK(_j089A["backDash"], _y4IB9) then
										return
									end
									_cJ2_o = bit32.bxor(_cJ2_o + 0x1401, 0x9f036)
								elseif _cJ2_o - 0x3d5a4 == 0x0 then
									if 129 == 0x81 then
										if not (_fx2la and _y4IB9) then
											return
										end
									else
										(function()
											return (bit32 and 16108 or 0x39e8)
										end)()
									end
									_cJ2_o = bit32.bxor(_cJ2_o + 0x8698, 0x8351f)
								elseif bit32.bxor(_cJ2_o, 0x553a9) == 0x0 then
									(function()
										return ((0xe00b % 0x2 == 0x0) and (bit32 and 28677 or 0x0) or (bit32 and 57102 or 0x0))
									end)()
									_cJ2_o = bit32.bxor(bit32.bxor(_cJ2_o, 0xc5ff), 0xd0aa7)
								elseif _cJ2_o - 0x502a == 0x0 then
									task["wait"](_PHRBh)
									_cJ2_o = bit32.bxor(bit32.bxor(_cJ2_o, 0xbf3d), 0x33ab3)
								elseif bit32.bxor(_cJ2_o, 0x89cf1) == 0x0 then
									(function()
										return (bit32 and 0 or 0x141)
									end)()
									_cJ2_o = bit32.bxor(_cJ2_o + 0xbe8d, 0xc08d7)
								end
							else
								(function()
									return (bit32 and 15660 or 0x3bba)
								end)()
							end
						end
					else
						(function()
							return ((0x657 % 0x2 == 0x0) and (bit32 and 811 or 0x0) or (bit32 and 1040 or 0x0))
						end)()
					end
				end
				local function _kk1_Z(_ZZ3yn)
					local _elHIb, _vOGb3, _gDCfh, _dc_DC, _dc_DC
					if 129 == 0x81 then
						_dc_DC = 0x83fe9
					else
						(function()
							return (bit32 and 1617473109 or 0x9fdf)
						end)()
					end
					while _dc_DC do
						if _dc_DC == 0x2b68c then
							(function()
								return (bit32 and 20503 or 0x4486)
							end)()
							_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x7aab), 0x9c2f9)
						elseif bit32.bxor(_dc_DC, 0x83fe9) == 0x0 then
							if not (_fx2la and _ZZ3yn) then
								return false
							end
							if 1 == 0x1 then
								_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x1377), 0x3ec09)
							else
								(function()
									return (bit32 and 46554 or 0x3190)
								end)()
							end
						elseif bit32.bxor(_dc_DC, 0xbc097) == 0x0 then
							_elHIb = _fx2la["Position"]
							if 129 == 0x81 then
								_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x3b2f), 0x4bb38)
							else
								(function()
									return (bit32 and 15331 or 0x2a67)
								end)()
							end
						elseif bit32.bxor(_dc_DC, 0xb0ede) == 0x0 then
							if 129 == 0x81 then
								(function()
									return ((0xc615 % 0x2 == 0x0) and (bit32 and 25354 or 0x0) or (bit32 and 13325 or 0x0))
								end)()
							else
								(function()
									return ((0x85ca % 0x2 == 0x0) and (bit32 and 17125 or 0x0) or (bit32 and 40881 or 0x0))
								end)()
							end
							if 1 == 0x1 then
								_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x7b32), 0x30635)
							else
								(function()
									return (bit32 and (5270 * 0x3d % 0x10000) or 0x14f4)
								end)()
							end
						elseif _dc_DC == 0xf4080 then
							_vOGb3 = _ZZ3yn["Position"]
							if 129 == 0x81 then
								_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x207b), 0x17b38)
							else
								(function()
									return (bit32 and 10642 or 0xf92)
								end)()
							end
						elseif _dc_DC - 0x179e5 == 0x0 then
							return false
						elseif bit32.bxor(_dc_DC, 0x88ec7) == 0x0 then
							if _gDCfh <= ((0x2 * 100 - 0) / 0x3e8) and _elHIb["Y"] < _vOGb3["Y"] then
								return true
							end
							_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0xbb1), 0x9fc93)
						elseif bit32.bxor(_dc_DC, 0x873d9) == 0x0 then
							if 0 == 0x0 then
								(function()
									return (bit32 and 1623174254 or 0xe602)
								end)()
							else
								(function()
									return (bit32 and (8615 * 0x3d % 0x10000) or 0x2ef6)
								end)()
							end
							if 129 == 0x81 then
								_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0xe80), 0x23363)
							else
								(function()
									return (bit32 and 40220 or 0xce9d)
								end)()
							end
						elseif _dc_DC == 0xa4e3a then
							(function()
								return (bit32 and (42792 * 0x3d % 0x10000) or 0xa6e7)
							end)()
							_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x3ddf), 0x8c569)
						elseif _dc_DC == 0xe1bc3 then
							if 1 == 0x1 then
								_gDCfh = (Vector3["new"](_elHIb["X"], 0, _elHIb["Z"]) - Vector3["new"](_vOGb3["X"], 0, _vOGb3["Z"]))["Magnitude"]
							else
								(function()
									return (bit32 and 46321 or 0xa534)
								end)()
							end
							_dc_DC = bit32.bxor(bit32.bxor(_dc_DC, 0x966f), 0x6036b)
						end
					end
				end
				local function _p44Zr(_KePja)
					if 0 == 0x0 then
						_KePja = _KePja or 1
					else
						(function()
							return ((0xe4e9 % 0x2 == 0x0) and (bit32 and 29300 or 0x0) or (bit32 and 65471 or 0x0))
						end)()
					end
					return PingStat:GetValue() / _KePja
				end
				local function _reriI(_MzsjXMUj)
					local _VsdNr = _MzsjXMUj + (_p44Zr() - (25 + 25)) * -(0 / 0x3e8)
					return { _VsdNr, _MzsjXMUj - _VsdNr }
				end
				local function _GrWcDJ(_XbKvQWF)
					local _cEubcdhH, _RLuEg, _OyOHrn, _NkzCSxA, _sxJBdGwo, _Ow03q, _Ow03q
					_Ow03q = 0x3eaeb
					while _Ow03q do
						if _Ow03q - 0x1fb36 == 0x0 then
							if 0 == 0x0 then
								_OyOHrn = _cEubcdhH:Dot(_RLuEg)
							else
								(function()
									return (bit32 and (22541 * 0x3d % 0x10000) or 0x5224)
								end)()
							end
							_Ow03q = bit32.bxor(_Ow03q + 0xed2, 0xe4560)
						elseif _Ow03q - 0x4d224 == 0x0 then
							_RLuEg = _RLuEg["Unit"]
							_Ow03q = bit32.bxor(_Ow03q + 0x5257, 0x4df4d)
						elseif _Ow03q - 0xa96a9 == 0x0 then
							return _sxJBdGwo
						elseif _Ow03q == 0xc4f68 then
							_OyOHrn = math["clamp"](_OyOHrn, -(1 + 0), (0x2 * 1 - 1))
							_Ow03q = bit32.bxor(_Ow03q + 0x145d, 0x40969)
						elseif _Ow03q == 0xeecd2 then
							(function()
								return (bit32 and 46532 or 0x3eb5)
							end)()
							if 0 == 0x0 then
								_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0xab64), 0xdb9d3)
							else
								(function()
									return (bit32 and 1876 or 0x5c07)
								end)()
							end
						elseif _Ow03q - 0xc1a79 == 0x0 then
							(function()
								return (bit32 and 1287387857 or 0xf939)
							end)()
							_Ow03q = bit32.bxor(_Ow03q + 0x787a, 0x27e21)
						elseif _Ow03q == 0xf2fc4 then
							_cEubcdhH = _fx2la["CFrame"]["LookVector"]
							if 0 == 0x0 then
								_Ow03q = bit32.bxor(_Ow03q + 0x2091, 0x20d3d)
							else
								(function()
									return ((0xc8ea % 0x2 == 0x0) and (bit32 and 25717 or 0x0) or (bit32 and 59476 or 0x0))
								end)()
							end
						elseif _Ow03q == 0x86aac then
							if 129 == 0x81 then
								_NkzCSxA = math["acos"](_OyOHrn)
							else
								(function()
									return (bit32 and (38313 * 0x3d % 0x10000) or 0x971d)
								end)()
							end
							_Ow03q = bit32.bxor(_Ow03q + 0x8f8f, 0x9bbe6)
						elseif bit32.bxor(_Ow03q, 0x3fe65) == 0x0 then
							(function()
								return (bit32 and 1555 or 0x1b06)
							end)()
							if 65535 == 0xffff then
								_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0x8d99), 0x32675)
							else
								(function()
									return (bit32 and 53296 or 0x31d0)
								end)()
							end
						elseif bit32.bxor(_Ow03q, 0x64795) == 0x0 then
							if 1 == 0x1 then
								_RLuEg = Vector3["new"](_RLuEg["X"], 0, _RLuEg["Z"])
							else
								(function()
									return (bit32 and 63862 or 0xe972)
								end)()
							end
							_Ow03q = bit32.bxor(_Ow03q + 0xa83, 0xac66c)
						elseif bit32.bxor(_Ow03q, 0x141dd) == 0x0 then
							_sxJBdGwo = math["deg"](_NkzCSxA)
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0x3a4d), 0xbed39)
							else
								(function()
									return (bit32 and 1526517584 or 0x9454)
								end)()
							end
						elseif _Ow03q - 0x5589 == 0x0 then
							(function()
								return (bit32 and 36330 or 0x8d8c)
							end)()
							if 0 == 0x0 then
								_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0x7a4d), 0xc35bd)
							else
								(function()
									return (bit32 and 39768 or 0x709b)
								end)()
							end
						elseif _Ow03q - 0xd5d68 == 0x0 then
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_cEubcdhH = Vector3["new"](_cEubcdhH["X"], 0, _cEubcdhH["Z"])["Unit"]
							else
								(function()
									return (bit32 and 47282 or 0x66b2)
								end)()
							end
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0xb92d), 0xe6607)
							else
								(function()
									return (bit32 and 1877070878 or 0x9efd)
								end)()
							end
						elseif bit32.bxor(_Ow03q, 0xc9474) == 0x0 then
							if _RLuEg["Magnitude"] == 0 then
								return 0
							end
							_Ow03q = bit32.bxor(_Ow03q + 0x226f, 0x864c7)
						elseif _Ow03q - 0x3eaeb == 0x0 then
							if not _fx2la or not _XbKvQWF then
								return ({})[1]
							end
							if 65535 == 0xffff then
								_Ow03q = bit32.bxor(_Ow03q + 0x3fd7, 0xb0506)
							else
								(function()
									return (bit32 and (9280 * 0x3d % 0x10000) or 0x24fd)
								end)()
							end
						elseif _Ow03q - 0x38242 == 0x0 then
							_RLuEg = _XbKvQWF["Position"] - _fx2la["Position"]
							_Ow03q = bit32.bxor(bit32.bxor(_Ow03q, 0xb916), 0x57cc1)
						end
					end
				end
				local function _DSJg_(_ytNUhc, _h_T7iwz)
					local _wc389xzH, _nNJV4, _ryeRe, _ryeRe
					_ryeRe = 0x43e16
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						while _ryeRe do
							if _ryeRe == 0x43e16 then
								if not _h_T7iwz or _h_T7iwz >= (0x2 * 175 - 0) then
									return true
								end
								_ryeRe = bit32.bxor(_ryeRe + 0x8412, 0xf0ef3)
							elseif _ryeRe == 0xf702 then
								(function()
									return (bit32 and 25727 or 0x8e64)
								end)()
								if 129 == 0x81 then
									_ryeRe = bit32.bxor(bit32.bxor(_ryeRe, 0x7c42), 0xcf49e)
								else
									(function()
										return (bit32 and 40558 or 0x3c58)
									end)()
								end
							elseif bit32.bxor(_ryeRe, 0xc718a) == 0x0 then
								if _wc389xzH == ({})[1] then
									return false
								end
								_ryeRe = bit32.bxor(_ryeRe + 0x9985, 0xeaf9c)
							elseif _ryeRe == 0x6394 then
								return _wc389xzH <= _nNJV4
							elseif bit32.bxor(_ryeRe, 0xc7fde) == 0x0 then
								(function()
									return (bit32 and 65260 or 0xde57)
								end)()
								_ryeRe = bit32.bxor(_ryeRe + 0x43ec, 0xc34c8)
							elseif bit32.bxor(_ryeRe, 0xbccdb) == 0x0 then
								_wc389xzH = _GrWcDJ(_ytNUhc)
								if 16 == 0x10 then
									_ryeRe = bit32.bxor(_ryeRe + 0x919c, 0x2ffd)
								else
									(function()
										return (bit32 and 10141 or 0x33ab)
									end)()
								end
							elseif _ryeRe - 0x3a493 == 0x0 then
								_nNJV4 = _h_T7iwz / 2
								_ryeRe = bit32.bxor(_ryeRe + 0x2722, 0x3a821)
							end
						end
					else
						(function()
							return ((0x5c6f % 0x2 == 0x0) and (bit32 and 11831 or 0x0) or (bit32 and 32003 or 0x0))
						end)()
					end
				end
				local function _SCYz7(_kINPp, _Rebsb)
					if _Rebsb:FindFirstChild("Counter") then
						return HubSettings["Visuals"]["ESP"]["DeathCounterColor"]
					elseif _Rebsb:GetAttribute("Ulted") then
						if 1 == 0x1 then
							if _Rebsb:GetAttribute("Character") == "Bald" then
								return HubSettings["Visuals"]["ESP"]["SaitamaUltColor"]
							end
						else
							(function()
								return ((0xea04 % 0x2 == 0x0) and (bit32 and 29954 or 0x0) or (bit32 and 53019 or 0x0))
							end)()
						end
						return HubSettings["Visuals"]["ESP"]["UltColor"]
					elseif _JrRW2(_kINPp, false) then
						return HubSettings["Visuals"]["ESP"]["FriendColor"]
					elseif _kINPp and _RWZpc[_kINPp["Name"]] == "Enemy" then
						return HubSettings["Visuals"]["ESP"]["EnemyColor"]
					end
					return HubSettings["Visuals"]["ESP"]["NeutralColor"]
				end
				local function _G_mVA(_XEzdh)
					local _EPrtH, _Bkair, _wYKZ7, _wYKZ7
					_wYKZ7 = 0x21445
					if 65535 == 0xffff then
						while _wYKZ7 do
							if 1 == 0x1 then
								if _wYKZ7 == 0x955a4 then
									if not _Bkair then
										return ({})[1]
									end
									_wYKZ7 = bit32.bxor(bit32.bxor(_wYKZ7, 0x6cdb), 0xa8d77)
								elseif _wYKZ7 - 0x634bd == 0x0 then
									_EPrtH = PlayerGui:FindFirstChild("Hotbar")
										or (
											not _XEzdh
											and PlayerGui["WaitForChild"]
											and PlayerGui:WaitForChild("Hotbar", (50 / 0x3e8))
										)
									if 16 == 0x10 then
										_wYKZ7 = bit32.bxor(_wYKZ7 + 0xbcf, 0x431f2)
									else
										(function()
											return (bit32 and 392 or 0x4801)
										end)()
									end
								elseif _wYKZ7 == 0x8724a then
									if 0 == 0x0 then
										(function()
											return (bit32 and 3021 or 0xbd7)
										end)()
									else
										(function()
											return (bit32 and 1499551946 or 0x7353)
										end)()
									end
									_wYKZ7 = bit32.bxor(bit32.bxor(_wYKZ7, 0x6404), 0xe0da4)
								elseif _wYKZ7 - 0x21445 == 0x0 then
									if not PlayerGui then
										return ({})[1]
									end
									if 0 == 0x0 then
										_wYKZ7 = bit32.bxor(bit32.bxor(_wYKZ7, 0x52ef), 0x47217)
									else
										(function()
											return ((0x7559 % 0x2 == 0x0) and (bit32 and 15020 or 0x0) or (bit32 and 27626 or 0x0))
										end)()
									end
								elseif _wYKZ7 - 0x8d890 == 0x0 then
									if 16 == 0x10 then
										_Bkair = _EPrtH:FindFirstChild("Backpack")
											or (
												not _XEzdh
												and _EPrtH["WaitForChild"]
												and _EPrtH:WaitForChild("Backpack", (50 / 0x3e8))
											)
									else
										(function()
											return (bit32 and 16099 or 0x36e3)
										end)()
									end
									if 0 == 0x0 then
										_wYKZ7 = bit32.bxor(_wYKZ7 + 0x8ed8, 0x32cc)
									else
										(function()
											return (bit32 and 33799 or 0x6784)
										end)()
									end
								elseif _wYKZ7 == 0x2717e then
									if 0 == 0x0 then
										if not _EPrtH then
											return ({})[1]
										end
									else
										(function()
											return ((0xaa3b % 0x2 == 0x0) and (bit32 and 21789 or 0x0) or (bit32 and 55698 or 0x0))
										end)()
									end
									_wYKZ7 = bit32.bxor(_wYKZ7 + 0x75fb, 0xa3fe9)
								elseif _wYKZ7 - 0x61bea == 0x0 then
									(function()
										return (bit32 and 29659 or 0x3e1b)
									end)()
									_wYKZ7 = bit32.bxor(bit32.bxor(_wYKZ7, 0x2745), 0xe4ee5)
								elseif _wYKZ7 - 0x3b408 == 0x0 then
									return _Bkair:FindFirstChild("Hotbar")
										or (not _XEzdh and _Bkair["WaitForChild"] and _Bkair:WaitForChild("Hotbar", (50 / 0x3e8)))
								end
							else
								(function()
									return (bit32 and (27092 * 0x3d % 0x10000) or 0x6b4f)
								end)()
							end
						end
					else
						(function()
							return (bit32 and 1905029375 or 0x9f49)
						end)()
					end
				end
				local function _KCt41()
					local _rLEQ4, _opUYh, _Vd3VT, _eNyEw, _bGDnA, _Iu8_u, _H71NM, _H71NM
					_H71NM = 0xa1001
					if 0 == 0x0 then
						while _H71NM do
							if _H71NM - 0x2a859 == 0x0 then
								_eNyEw = _opUYh:WaitForChild("TextLabel", (50 / 0x3e8))
								_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x36dd), 0x51857)
							elseif _H71NM == 0x37af1 then
								if 0 == 0x0 then
									if HubSettings["Visuals"]["CustomUltbar"]["UltbarText"]["Enabled"] then
										_IeaiYt2E(_eNyEw, "Text", HubSettings["Visuals"]["CustomUltbar"]["UltbarText"]["Text"])
									else
										_IeaiYt2E(_eNyEw, "Text", _Z0Hry:GetAttribute("UltimateName") or "Other")
									end
								else
									(function()
										return (bit32 and 3693 or 0x30e)
									end)()
								end
								_H71NM = bit32.bxor(_H71NM + 0x4ae8, 0x4ba96)
							elseif _H71NM - 0x9c06e == 0x0 then
								(function()
									return (bit32 and 16358 or 0x386c)
								end)()
								if 0 == 0x0 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x2741), 0x21f19)
								else
									(function()
										return (bit32 and 9589 or 0x2c25)
									end)()
								end
							elseif _H71NM - 0x9f32a == 0x0 then
								_J4f_N(_rJ2QD)
								if 129 == 0x81 then
									_H71NM = bit32.bxor(_H71NM + 0x8b31, 0x65d0e)
								else
									(function()
										return (bit32 and 53602 or 0xa432)
									end)()
								end
							elseif _H71NM - 0x8c4bf == 0x0 then
								_opUYh = _rLEQ4:FindFirstChild("MagicHealth")
									or (_rLEQ4["WaitForChild"] and _rLEQ4:WaitForChild("MagicHealth", (50 / 0x3e8)))
								if 129 == 0x81 then
									_H71NM = bit32.bxor(_H71NM + 0x2b6d, 0x978c8)
								else
									(function()
										return (bit32 and 9182 or 0x3c23)
									end)()
								end
							elseif bit32.bxor(_H71NM, 0x641e9) == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									(function()
										return (bit32 and 8773 or 0x6a22)
									end)()
								else
									(function()
										return (bit32 and 29915 or 0x94ab)
									end)()
								end
								if 0 == 0x0 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x22aa), 0xf72f3)
								else
									(function()
										return ((0xeb0d % 0x2 == 0x0) and (bit32 and 30086 or 0x0) or (bit32 and 17142 or 0x0))
									end)()
								end
							elseif _H71NM - 0xa1001 == 0x0 then
								if 0 == 0x0 then
									_rLEQ4 = PlayerGui:FindFirstChild("Bar")
										or (PlayerGui["WaitForChild"] and PlayerGui:WaitForChild("Bar", ((0x2 * 25 - 0) / 0x3e8)))
								else
									(function()
										return (bit32 and 34223 or 0x87a7)
									end)()
								end
								if 129 == 0x81 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x2dbe), 0xe1736)
								else
									(function()
										return (bit32 and (24391 * 0x3d % 0x10000) or 0x4378)
									end)()
								end
							elseif bit32.bxor(_H71NM, 0x11e1d) == 0x0 then
								if 0 == 0x0 then
									_Vd3VT = _opUYh
										:WaitForChild("Health", (50 / 0x3e8))
										:WaitForChild("Bar", ((0 + 0x2 * 25) / 0x3e8))
										:WaitForChild("Bar", ((25 + 25) / 0x3e8))
								else
									(function()
										return (bit32 and 44454 or 0xad82)
									end)()
								end
								if 16 == 0x10 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x7cf1), 0x3cab5)
								else
									(function()
										return (bit32 and 765 or 0x250)
									end)()
								end
							elseif _H71NM - 0x188e4 == 0x0 then
								if 16 == 0x10 then
									if not _opUYh then
										return
									end
								else
									(function()
										return ((0x238c % 0x2 == 0x0) and (bit32 and 4550 or 0x0) or (bit32 and 61785 or 0x0))
									end)()
								end
								_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x71c5), 0xe73c)
							elseif _H71NM == 0x786d3 then
								_bGDnA = _opUYh:WaitForChild("cdholder", ((25 + 25) / 0x3e8))
								if 16 == 0x10 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0xa696), 0x1fbe5)
								else
									(function()
										return ((0x5744 % 0x2 == 0x0) and (bit32 and 11170 or 0x0) or (bit32 and 46651 or 0x0))
									end)()
								end
							elseif _H71NM == 0xa4889 then
								if _Iu8_u then
									if 16 == 0x10 then
										for _vyULz = 1, 4 do
											local _M0lkk = _Iu8_u:FindFirstChild(tostring(_vyULz))
												or (_Iu8_u["WaitForChild"] and _Iu8_u:WaitForChild(tostring(_vyULz), (100 / 0x3e8)))
											local _tCAt2 = _M0lkk
												and (
													_M0lkk:FindFirstChild("Base")
													or (_M0lkk["WaitForChild"] and _M0lkk:WaitForChild("Base", (100 / 0x3e8)))
												)
											if _tCAt2 then
												local _zfcIs = _l3G1i(_tCAt2["ChildAdded"], function(_ivDNC)
													if _ivDNC["Name"] == "Cooldown" then
														if HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Enabled"] then
															_IeaiYt2E(
																_ivDNC,
																"BackgroundColor3",
																HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Color"]
															)
														else
															_IeaiYt2E(
																_ivDNC,
																"BackgroundColor3",
																Color3["fromRGB"]((255 + 0x2 * 0), (0x2 * 47 - 7), 87)
															)
														end
													end
												end)
												if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
													table["insert"](_rJ2QD, _zfcIs)
												else
													(function()
														return (
															(0x3aa4 % 0x2 == 0x0) and (bit32 and 7506 or 0x0)
															or (bit32 and 10632 or 0x0)
														)
													end)()
												end
											end
										end
									else
										(function()
											return (bit32 and 53961 or 0xb2c8)
										end)()
									end
								end
								_H71NM = bit32.bxor(_H71NM + 0x342f, 0x90649)
							elseif _H71NM - 0xbf836 == 0x0 then
								(function()
									return (bit32 and 26526 or 0x6c67)
								end)()
								if 1 == 0x1 then
									_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x7527), 0xdccf8)
								else
									(function()
										return (bit32 and 489196573 or 0x5fa7)
									end)()
								end
							elseif _H71NM == 0x6dba0 then
								_Iu8_u = _G_mVA()
								_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x2324), 0xf0bae)
							elseif _H71NM - 0xc2355 == 0x0 then
								_l3G1i(_bGDnA["ChildAdded"], function(_ZvzU8)
									if
										_ZvzU8["Name"] == "forward"
										or _ZvzU8["Name"] == "side"
										or _ZvzU8["Name"] == "evasive"
										or _ZvzU8["Name"] == "burst"
									then
										local _OAVDH =
											_ZvzU8:WaitForChild("template", (50 / 0x3e8)):WaitForChild("Fill", (50 / 0x3e8))
										if HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Enabled"] then
											_IeaiYt2E(
												_OAVDH,
												"BackgroundColor3",
												HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Color"]
											)
										else
											_IeaiYt2E(_OAVDH, "BackgroundColor3", Color3["fromRGB"](255, (0 + 0x2 * 39), 78))
										end
									end
								end)
								_H71NM = bit32.bxor(_H71NM + 0x3db3, 0x62981)
							elseif _H71NM == 0x77f4f then
								if HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Enabled"] then
									if 0 == 0x0 then
										_IeaiYt2E(
											_Vd3VT,
											"ImageColor3",
											HubSettings["Visuals"]["CustomUltbar"]["UltbarColor"]["Color"]
										)
									else
										(function()
											return (bit32 and 20125 or 0xb9e)
										end)()
									end
								else
									if 1 == 0x1 then
										_IeaiYt2E(_Vd3VT, "ImageColor3", Color3["fromRGB"]((255 + 0x2 * 0), 87, 87))
									else
										(function()
											return ((0xeb3c % 0x2 == 0x0) and (bit32 and 30110 or 0x0) or (bit32 and 31301 or 0x0))
										end)()
									end
								end
								if 1 == 0x1 then
									_H71NM = nil
								else
									(function()
										return (bit32 and 61417 or 0xea7c)
									end)()
								end
							elseif _H71NM == 0x911b0 then
								(function()
									return (bit32 and 26668 or 0xee1c)
								end)()
								_H71NM = bit32.bxor(bit32.bxor(_H71NM, 0x7658), 0xa786)
							elseif _H71NM - 0x42a89 == 0x0 then
								if 16 == 0x10 then
									if not _rLEQ4 then
										return
									end
								else
									(function()
										return (bit32 and 59717 or 0x91e9)
									end)()
								end
								_H71NM = bit32.bxor(_H71NM + 0x39ec, 0xca0ca)
							end
						end
					else
						(function()
							return (bit32 and 430051779 or 0xf40d)
						end)()
					end
				end
				local _gcElC = { ["entries"] = {}, ["gui"] = ({})[1], ["conn"] = ({})[1] }
				if 0 == 0x0 then
					_gcElC["getGui"] = function()
						local _TlRhI, _KFdXC, _KFGqw, _KFGqw
						_KFGqw = 0x35b20
						while _KFGqw do
							if _KFGqw - 0x35b20 == 0x0 then
								if _gcElC["gui"] and _gcElC["gui"]["Parent"] then
									return _gcElC["gui"]
								end
								_KFGqw = bit32.bxor(_KFGqw + 0x62e5, 0x5cf8c)
							elseif _KFGqw == 0x93d2a then
								(function()
									return (bit32 and (13889 * 0x3d % 0x10000) or 0x3579)
								end)()
								_KFGqw = bit32.bxor(bit32.bxor(_KFGqw, 0x4139), 0x7ac3e)
							elseif bit32.bxor(_KFGqw, 0x2a1b3) == 0x0 then
								(function()
									return (bit32 and 24589 or 0x7b60)
								end)()
								_KFGqw = bit32.bxor(_KFGqw + 0x27c6, 0x6eb46)
							elseif bit32.bxor(_KFGqw, 0xc6ff) == 0x0 then
								_KFdXC = pcall(function()
									_TlRhI["Parent"] = (EnvAccess["gethui"] and EnvAccess["gethui"]()) or game:GetService("CoreGui")
								end)
								_KFGqw = bit32.bxor(_KFGqw + 0x99f8, 0x67a5d)
							elseif _KFGqw - 0x71aaa == 0x0 then
								if not _KFdXC or not _TlRhI["Parent"] then
									_TlRhI["Parent"] = PlayerGui
								end
								_KFGqw = bit32.bxor(_KFGqw + 0x8bc9, 0x3037c)
							elseif _KFGqw - 0x67189 == 0x0 then
								_TlRhI = Instance["new"]("ScreenGui")
								_KFGqw = bit32.bxor(_KFGqw + 0x3fd5, 0x7f59e)
							elseif bit32.bxor(_KFGqw, 0xed02d) == 0x0 then
								(function()
									return (bit32 and (9830 * 0x3d % 0x10000) or 0x101c)
								end)()
								_KFGqw = bit32.bxor(bit32.bxor(_KFGqw, 0xb194), 0xcc00a)
							elseif bit32.bxor(_KFGqw, 0x4a50f) == 0x0 then
								_gcElC["gui"] = _TlRhI
								_KFGqw = bit32.bxor(_KFGqw + 0xa2e3, 0x32e77)
							elseif _KFGqw == 0x144c0 then
								_TlRhI["Name"] = "KittyBoxes"
								_KFGqw = bit32.bxor(bit32.bxor(_KFGqw, 0x4827), 0x59ee7)
							elseif bit32.bxor(_KFGqw, 0x83f65) == 0x0 then
								_TlRhI["IgnoreGuiInset"] = true
								_KFGqw = bit32.bxor(bit32.bxor(_KFGqw, 0x6ee0), 0x22d3a)
							elseif _KFGqw - 0x4223f == 0x0 then
								(function()
									return (bit32 and 45240 or 0xf8b5)
								end)()
								_KFGqw = bit32.bxor(_KFGqw + 0x5760, 0xd44b5)
							elseif bit32.bxor(_KFGqw, 0xa7cbf) == 0x0 then
								_TlRhI["DisplayOrder"] = 10
								_KFGqw = bit32.bxor(bit32.bxor(_KFGqw, 0x41f0), 0xafbb0)
							elseif _KFGqw - 0x49200 == 0x0 then
								_TlRhI["ResetOnSpawn"] = false
								_KFGqw = bit32.bxor(_KFGqw + 0xb52, 0xca237)
							elseif _KFGqw - 0x66985 == 0x0 then
								return _TlRhI
							end
						end
					end
				else
					(function()
						return (bit32 and (34215 * 0x3d % 0x10000) or 0x85b1)
					end)()
				end
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					_gcElC["bounds"] = function(_d9k6S, _grRPL, _zEYJx)
						local _q7qeh, _tdlrX, _MmEEE, _vo9Ju, _Gff8H, _ZiWeV, _N2pSt, _aMaqO, _abuUFeVu, _fwJeEv6, _sVRdQJeO, _lSzXe, _yah1udeS, _ACJXw, _ACJXw
						_ACJXw = 0xe1152
						while _ACJXw do
							if _ACJXw == 0xeb30d then
								(function()
									return (bit32 and 3036 or 0x29df)
								end)()
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0xac8a), 0x63306)
							elseif bit32.bxor(_ACJXw, 0xe1152) == 0x0 then
								_q7qeh = _zEYJx["CFrame"]
								_ACJXw = bit32.bxor(_ACJXw + 0xb04b, 0x69155)
							elseif _ACJXw == 0x850c8 then
								_tdlrX, _MmEEE, _vo9Ju = math["huge"], math["huge"], math["huge"]
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0x5f98), 0xf7a84)
							elseif _ACJXw == 0xdebfe then
								(function()
									return (bit32 and 31728 or 0x697b)
								end)()
								_ACJXw = bit32.bxor(_ACJXw + 0x1afc, 0xdec16)
							elseif _ACJXw - 0x775d4 == 0x0 then
								_Gff8H, _ZiWeV, _N2pSt = -math["huge"], -math["huge"], -math["huge"]
								_ACJXw = bit32.bxor(_ACJXw + 0xb41e, 0x9f811)
							elseif _ACJXw == 0x3eaec then
								(function()
									return (bit32 and 12230 or 0x279b)
								end)()
								_ACJXw = bit32.bxor(_ACJXw + 0xaa93, 0xa2672)
							elseif bit32.bxor(_ACJXw, 0x49f40) == 0x0 then
								_abuUFeVu, _fwJeEv6, _sVRdQJeO, _lSzXe = math["huge"], math["huge"], -math["huge"], -math["huge"]
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0x5a5c), 0x7eb8b)
							elseif _ACJXw - 0x82c81 == 0x0 then
								(function()
									return (bit32 and 11638 or 0x71cb)
								end)()
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0x722b), 0x5b554)
							elseif bit32.bxor(_ACJXw, 0x1ab84) == 0x0 then
								return math["floor"](_abuUFeVu + ((0 + 0x2 * 250) / 0x3e8)),
									math["floor"](_fwJeEv6 + ((250 + 250) / 0x3e8)),
									math["floor"](_sVRdQJeO - _abuUFeVu + (500 / 0x3e8)),
									math["floor"](_lSzXe - _fwJeEv6 + (500 / 0x3e8))
							elseif _ACJXw - 0x32e97 == 0x0 then
								_yah1udeS = false
								_ACJXw = bit32.bxor(_ACJXw + 0x4c8f, 0x28a5)
							elseif _ACJXw == 0x1793f then
								for _fwa6a, _Yk1jk in ipairs(_d9k6S:GetChildren()) do
									if _Yk1jk:IsA("BasePart") and _Yk1jk["Name"] ~= "HumanoidRootPart" then
										local _l7EqW, _yNOi1, _jNIPf, _wlYra, _J486h, _WOna7, _Hx9En, _UW76pP, _hcT9D, _W8a5x, _W8a5x
										_W8a5x = 0xf3f2b
										while _W8a5x do
											if _W8a5x == 0xb47ef then
												if _WOna7["X"] - _Hx9En < _tdlrX then
													_tdlrX = _WOna7["X"] - _Hx9En
												end
												_W8a5x = bit32.bxor(_W8a5x + 0x8f3c, 0x1c55f)
											elseif bit32.bxor(_W8a5x, 0xb045a) == 0x0 then
												_Hx9En = _aMaqO(_jNIPf["X"]) * _yNOi1["X"]
													+ _aMaqO(_wlYra["X"]) * _yNOi1["Y"]
													+ _aMaqO(_J486h["X"]) * _yNOi1["Z"]
												_W8a5x = bit32.bxor(_W8a5x + 0xa597, 0x24b40)
											elseif _W8a5x == 0x6bee3 then
												(function()
													return (bit32 and (51121 * 0x3d % 0x10000) or 0xc6df)
												end)()
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x7cf8), 0x59d30)
											elseif _W8a5x - 0x9e2b1 == 0x0 then
												_UW76pP = _aMaqO(_jNIPf["Y"]) * _yNOi1["X"]
													+ _aMaqO(_wlYra["Y"]) * _yNOi1["Y"]
													+ _aMaqO(_J486h["Y"]) * _yNOi1["Z"]
												_W8a5x = bit32.bxor(_W8a5x + 0x4908, 0x8180d)
											elseif bit32.bxor(_W8a5x, 0x5d965) == 0x0 then
												(function()
													return (bit32 and 797589306 or 0xbefc)
												end)()
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x3d1b), 0x35a9d)
											elseif _W8a5x - 0x4d629 == 0x0 then
												_jNIPf, _wlYra, _J486h, _WOna7 =
													_l7EqW["XVector"], _l7EqW["YVector"], _l7EqW["ZVector"], _l7EqW["Position"]
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x4b8c), 0xf99ff)
											elseif _W8a5x - 0x3f3c2 == 0x0 then
												if _WOna7["X"] + _Hx9En > _Gff8H then
													_Gff8H = _WOna7["X"] + _Hx9En
												end
												_W8a5x = bit32.bxor(_W8a5x + 0x6222, 0x5d356)
											elseif _W8a5x == 0x71e33 then
												if _WOna7["Z"] - _hcT9D < _vo9Ju then
													_vo9Ju = _WOna7["Z"] - _hcT9D
												end
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x1090), 0x4fd61)
											elseif _W8a5x - 0x186b2 == 0x0 then
												if _WOna7["Y"] + _UW76pP > _ZiWeV then
													_ZiWeV = _WOna7["Y"] + _UW76pP
												end
												_W8a5x = bit32.bxor(_W8a5x + 0x7444, 0x7ab88)
											elseif bit32.bxor(_W8a5x, 0x6517e) == 0x0 then
												if _WOna7["Z"] + _hcT9D > _N2pSt then
													_N2pSt = _WOna7["Z"] + _hcT9D
												end
												_W8a5x = nil
											elseif _W8a5x == 0x233b4 then
												_hcT9D = _aMaqO(_jNIPf["Z"]) * _yNOi1["X"]
													+ _aMaqO(_wlYra["Z"]) * _yNOi1["Y"]
													+ _aMaqO(_J486h["Z"]) * _yNOi1["Z"]
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x28d6), 0x95c8d)
											elseif bit32.bxor(_W8a5x, 0xae7db) == 0x0 then
												(function()
													return (bit32 and 22309 or 0xf0a4)
												end)()
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x90ba), 0xfae04)
											elseif _W8a5x - 0xa1274 == 0x0 then
												if _WOna7["Y"] - _UW76pP < _MmEEE then
													_MmEEE = _WOna7["Y"] - _UW76pP
												end
												_W8a5x = bit32.bxor(_W8a5x + 0xa238, 0xdaa9f)
											elseif _W8a5x == 0xf3f2b then
												_l7EqW, _yNOi1 =
													_q7qeh:ToObjectSpace(_Yk1jk["CFrame"]), _Yk1jk["Size"] / (0x2 * 1 - 0)
												_W8a5x = bit32.bxor(bit32.bxor(_W8a5x, 0x9c04), 0xb7506)
											elseif _W8a5x == 0x35f2b then
												(function()
													return (bit32 and 32601 or 0x3961)
												end)()
												_W8a5x = bit32.bxor(_W8a5x + 0x9ba2, 0x91d16)
											end
										end
									end
								end
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0x4cc8), 0x9fb0d)
							elseif _ACJXw - 0x35383 == 0x0 then
								for _xzl6M6T = 0, 7 do
									local _EwITr2 = Vector3["new"](
										_xzl6M6T % 2 == 0 and _tdlrX or _Gff8H,
										_xzl6M6T % 4 < 2 and _MmEEE or _ZiWeV,
										_xzl6M6T < 4 and _vo9Ju or _N2pSt
									)
									local _rR9ON = _grRPL:WorldToViewportPoint(_q7qeh:PointToWorldSpace(_EwITr2))
									if _rR9ON["Z"] > 0 then
										local _nxW4Y, _nxW4Y
										_nxW4Y = 0xc7174
										while _nxW4Y do
											if _nxW4Y == 0x2f6c7 then
												(function()
													return (bit32 and 1753216952 or 0x20dc)
												end)()
												_nxW4Y = bit32.bxor(_nxW4Y + 0x66cf, 0x51cdd)
											elseif _nxW4Y - 0x6414b == 0x0 then
												(function()
													return (bit32 and 23283 or 0x9266)
												end)()
												_nxW4Y = bit32.bxor(bit32.bxor(_nxW4Y, 0x87dc), 0x43050)
											elseif _nxW4Y - 0x4c18d == 0x0 then
												if _rR9ON["Y"] < _fwJeEv6 then
													_fwJeEv6 = _rR9ON["Y"]
												end
												_nxW4Y = bit32.bxor(_nxW4Y + 0xbc65, 0x7b857)
											elseif _nxW4Y == 0x33e29 then
												if _rR9ON["X"] < _abuUFeVu then
													_abuUFeVu = _rR9ON["X"]
												end
												_nxW4Y = bit32.bxor(bit32.bxor(_nxW4Y, 0x9ca0), 0x76304)
											elseif _nxW4Y - 0xc7174 == 0x0 then
												_yah1udeS = true
												_nxW4Y = bit32.bxor(_nxW4Y + 0x97e6, 0xe3773)
											elseif _nxW4Y == 0xa0e0c then
												if _rR9ON["Y"] > _lSzXe then
													_lSzXe = _rR9ON["Y"]
												end
												_nxW4Y = nil
											elseif _nxW4Y - 0x2c5a5 == 0x0 then
												if _rR9ON["X"] > _sVRdQJeO then
													_sVRdQJeO = _rR9ON["X"]
												end
												_nxW4Y = bit32.bxor(_nxW4Y + 0x9488, 0x95421)
											end
										end
									end
								end
								_ACJXw = bit32.bxor(_ACJXw + 0x21df, 0x99ce3)
							elseif _ACJXw - 0x1d1e3 == 0x0 then
								_aMaqO = math["abs"]
								_ACJXw = bit32.bxor(_ACJXw + 0x8b1f, 0x3243d)
							elseif bit32.bxor(_ACJXw, 0x8cefa) == 0x0 then
								if _tdlrX == math["huge"] then
									return ({})[1]
								end
								_ACJXw = bit32.bxor(bit32.bxor(_ACJXw, 0xa3b1), 0xcf20b)
							elseif _ACJXw == 0xae981 then
								if not _yah1udeS then
									return ({})[1]
								end
								_ACJXw = bit32.bxor(_ACJXw + 0x1c03, 0xaae00)
							end
						end
					end
				else
					(function()
						return ((0xae3e % 0x2 == 0x0) and (bit32 and 22303 or 0x0) or (bit32 and 59868 or 0x0))
					end)()
				end
				_gcElC["ringLines"] = function(_e_Ig9KYc, _tauTR7j)
					local _gvlHNr = {}
					for _TQDHO = 1, 4 do
						local _G6oE8, _BIr7S, _BIr7S
						_BIr7S = 0xb6198
						while _BIr7S do
							if _BIr7S - 0x182bd == 0x0 then
								_G6oE8["BackgroundColor3"] = _tauTR7j
								_BIr7S = bit32.bxor(bit32.bxor(_BIr7S, 0xa114), 0x37cc9)
							elseif _BIr7S == 0x6e591 then
								_G6oE8["BorderSizePixel"] = 0
								_BIr7S = bit32.bxor(bit32.bxor(_BIr7S, 0x9a5f), 0x7fd73)
							elseif _BIr7S == 0xb6198 then
								_G6oE8 = Instance["new"]("Frame")
								_BIr7S = bit32.bxor(bit32.bxor(_BIr7S, 0x5cd), 0xd81c4)
							elseif bit32.bxor(_BIr7S, 0x91ad2) == 0x0 then
								(function()
									return (bit32 and 462 or 0x50ec)
								end)()
								_BIr7S = bit32.bxor(bit32.bxor(_BIr7S, 0xb7d9), 0x56208)
							elseif _BIr7S == 0x4d9c2 then
								_gvlHNr[_TQDHO] = _G6oE8
								_BIr7S = nil
							elseif bit32.bxor(_BIr7S, 0x25f60) == 0x0 then
								_G6oE8["Parent"] = _e_Ig9KYc
								_BIr7S = bit32.bxor(_BIr7S + 0xbd83, 0x7c521)
							elseif _BIr7S == 0x6122b then
								(function()
									return (bit32 and 176737593 or 0x93a1)
								end)()
								_BIr7S = bit32.bxor(_BIr7S + 0xb4e4, 0xfdddd)
							elseif _BIr7S == 0xccf03 then
								(function()
									return (bit32 and 804651735 or 0xa99d)
								end)()
								_BIr7S = bit32.bxor(_BIr7S + 0x2e97, 0xaefb1)
							end
						end
					end
					return _gvlHNr
				end
				_gcElC["placeRing"] = function(_VjNkx, _ISiUp, _vEWQk, _CHzgX, _xkq0a)
					local _OCJ8I, _OCJ8I
					_OCJ8I = 0x6b551
					while _OCJ8I do
						if bit32.bxor(_OCJ8I, 0xa797b) == 0x0 then
							_VjNkx[(3 + 0x2 * 0)]["Size"] =
								UDim2["fromOffset"](_vEWQk, _xkq0a - 2 * _ISiUp - (0 + 0x2 * 1) * _vEWQk)
							_OCJ8I = bit32.bxor(bit32.bxor(_OCJ8I, 0xa00), 0xd0f09)
						elseif bit32.bxor(_OCJ8I, 0xb94bd) == 0x0 then
							_VjNkx[(3 + 0)]["Position"] = UDim2["fromOffset"](_ISiUp, _ISiUp + _vEWQk)
							_OCJ8I = bit32.bxor(_OCJ8I + 0x88a8, 0x6641e)
						elseif _OCJ8I - 0x82af4 == 0x0 then
							_VjNkx[2]["Position"] = UDim2["fromOffset"](_ISiUp, _xkq0a - _ISiUp - _vEWQk)
							_OCJ8I = bit32.bxor(bit32.bxor(_OCJ8I, 0x6909), 0x37d43)
						elseif _OCJ8I - 0xedfa9 == 0x0 then
							_VjNkx[(0x2 * 1 - 1)]["Size"] = UDim2["fromOffset"](_CHzgX - (1 + 1) * _ISiUp, _vEWQk)
							_OCJ8I = bit32.bxor(_OCJ8I + 0x7205, 0x77b5a)
						elseif _OCJ8I == 0x9284d then
							(function()
								return (bit32 and 40728 or 0xbf9f)
							end)()
							_OCJ8I = bit32.bxor(_OCJ8I + 0x32bc, 0xcd9f)
						elseif _OCJ8I == 0x6b551 then
							_VjNkx[(0x2 * 1 - 1)]["Position"] = UDim2["fromOffset"](_ISiUp, _ISiUp)
							_OCJ8I = bit32.bxor(_OCJ8I + 0x9f5b, 0x98b05)
						elseif bit32.bxor(_OCJ8I, 0x792ac) == 0x0 then
							(function()
								return (bit32 and (63130 * 0x3d % 0x10000) or 0xf6c8)
							end)()
							_OCJ8I = bit32.bxor(bit32.bxor(_OCJ8I, 0x14f5), 0xeae14)
						elseif bit32.bxor(_OCJ8I, 0xb3ebe) == 0x0 then
							_VjNkx[2]["Size"] = UDim2["fromOffset"](_CHzgX - 2 * _ISiUp, _vEWQk)
							_OCJ8I = bit32.bxor(_OCJ8I + 0x2ab7, 0xfdc8)
						elseif _OCJ8I - 0x77c72 == 0x0 then
							_VjNkx[(0 + 0x2 * 2)]["Position"] = UDim2["fromOffset"](_CHzgX - _ISiUp - _vEWQk, _ISiUp + _vEWQk)
							_OCJ8I = bit32.bxor(bit32.bxor(_OCJ8I, 0x3e61), 0x46473)
						elseif _OCJ8I == 0x99696 then
							(function()
								return (bit32 and 63474 or 0x8beb)
							end)()
							_OCJ8I = bit32.bxor(_OCJ8I + 0xae4e, 0xdd648)
						elseif _OCJ8I == 0x32660 then
							_VjNkx[4]["Size"] = UDim2["fromOffset"](_vEWQk, _xkq0a - 2 * _ISiUp - (1 + 1) * _vEWQk)
							_OCJ8I = nil
						end
					end
				end
				_gcElC["layout"] = function(_k5FsR, _q5lju, _fZbiN, _YIcQB, _he5Vv)
					local _S4W_p, _HXyfH, _Uv6OJ, _JbQNn, _u3vkF, _vk8n6d8, _vk8n6d8
					_vk8n6d8 = 0x76e6d
					while _vk8n6d8 do
						if _vk8n6d8 - 0x3efdf == 0x0 then
							(function()
								return (bit32 and 294427138 or 0xf808)
							end)()
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x7833), 0x47295)
						elseif bit32.bxor(_vk8n6d8, 0xee1a2) == 0x0 then
							_gcElC["placeRing"](_k5FsR["main"], 1, _HXyfH, _JbQNn, _u3vkF)
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0xb215), 0xbee7f)
						elseif bit32.bxor(_vk8n6d8, 0x66f97) == 0x0 then
							_JbQNn, _u3vkF = _YIcQB + (0x2 * 1 - 0) * _Uv6OJ, _he5Vv + (1 + 1) * _Uv6OJ
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x510c), 0xbdb6e)
						elseif bit32.bxor(_vk8n6d8, 0x6365a) == 0x0 then
							_k5FsR["fill"]["Size"] = UDim2["fromOffset"](_YIcQB, _he5Vv)
							_vk8n6d8 = nil
						elseif bit32.bxor(_vk8n6d8, 0xde5f5) == 0x0 then
							_k5FsR["root"]["Position"] = UDim2["fromOffset"](_q5lju - _Uv6OJ, _fZbiN - _Uv6OJ)
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x15cb), 0xf26d7)
						elseif _vk8n6d8 - 0x5fdb2 == 0x0 then
							_k5FsR["fill"]["Position"] = UDim2["fromOffset"](_Uv6OJ, _Uv6OJ)
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x2c7e), 0x3e796)
						elseif _vk8n6d8 - 0xccc49 == 0x0 then
							_Uv6OJ = _HXyfH + (0 + 0x2 * 1)
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x4be8), 0xae836)
						elseif _vk8n6d8 == 0x8fe26 then
							_HXyfH = _k5FsR["thick"]
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0xab33), 0x4995c)
						elseif bit32.bxor(_vk8n6d8, 0xf723) == 0x0 then
							if _k5FsR["key"] == _S4W_p then
								return
							end
							_vk8n6d8 = bit32.bxor(_vk8n6d8 + 0xa5db, 0xd0739)
						elseif _vk8n6d8 == 0x2d6e9 then
							_k5FsR["root"]["Size"] = UDim2["fromOffset"](_JbQNn, _u3vkF)
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0xaae1), 0x3cb9b)
						elseif _vk8n6d8 == 0x5bdc8 then
							_gcElC["placeRing"](_k5FsR["inner"], 1 + _HXyfH, (0x2 * 1 - 1), _JbQNn, _u3vkF)
							_vk8n6d8 = bit32.bxor(_vk8n6d8 + 0x199b, 0x2ad1)
						elseif bit32.bxor(_vk8n6d8, 0x1b793) == 0x0 then
							_gcElC["placeRing"](_k5FsR["outer"], 0, (1 + 0), _JbQNn, _u3vkF)
							_vk8n6d8 = bit32.bxor(_vk8n6d8 + 0x69bf, 0xcc0f0)
						elseif bit32.bxor(_vk8n6d8, 0x7e579) == 0x0 then
							(function()
								return (bit32 and 3418 or 0x8556)
							end)()
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x6688), 0x46c2e)
						elseif _vk8n6d8 - 0xc9bc7 == 0x0 then
							_k5FsR["key"] = _S4W_p
							_vk8n6d8 = bit32.bxor(bit32.bxor(_vk8n6d8, 0x291a), 0x44cfb)
						elseif bit32.bxor(_vk8n6d8, 0x76e6d) == 0x0 then
							_S4W_p = _q5lju .. "|" .. _fZbiN .. "|" .. _YIcQB .. "|" .. _he5Vv .. "|" .. _k5FsR["thick"]
							_vk8n6d8 = bit32.bxor(_vk8n6d8 + 0xa1d0, 0x8e71e)
						end
					end
				end
				if 65535 == 0xffff then
					_gcElC["step"] = function()
						local _jtZcU, _wiEtA, _lct7a, _W2grW, _fFgSi, _r8u4_, _r8u4_
						_r8u4_ = 0x7754d
						while _r8u4_ do
							if _r8u4_ - 0x3174 == 0x0 then
								_lct7a = _jtZcU["ViewportSize"]
								_r8u4_ = bit32.bxor(bit32.bxor(_r8u4_, 0xc66a), 0x96a6d)
							elseif bit32.bxor(_r8u4_, 0x81c6c) == 0x0 then
								_wiEtA = _jtZcU["CFrame"]["Position"]
								_r8u4_ = bit32.bxor(bit32.bxor(_r8u4_, 0x1e19), 0x83301)
							elseif bit32.bxor(_r8u4_, 0xad478) == 0x0 then
								(function()
									return (bit32 and 1019443581 or 0x4787)
								end)()
								_r8u4_ = bit32.bxor(_r8u4_ + 0x2d2c, 0x61e48)
							elseif _r8u4_ == 0x62542 then
								for _YFjN3, _j3_CA in pairs(_gcElC["entries"]) do
									local _eA1qe = _YFjN3["Parent"] and _YFjN3:FindFirstChild("HumanoidRootPart")
									local _pSAwZ = _eA1qe and _YFjN3:FindFirstChildOfClass("Humanoid")
									if not _eA1qe then
										pcall(function()
											_j3_CA["root"]:Destroy()
										end)
										_gcElC["entries"][_YFjN3] = ({})[1]
									elseif _pSAwZ and _pSAwZ["Health"] <= 0 then
										_j3_CA["root"]["Visible"] = false
									else
										local _w9N93, _nCT0H, _CNQM7, _NTnVq, _IbjxSQ4H, _IbjxSQ4H
										_IbjxSQ4H = 0x66386
										while _IbjxSQ4H do
											if bit32.bxor(_IbjxSQ4H, 0x66386) == 0x0 then
												_w9N93 = _eA1qe["Position"]
												_IbjxSQ4H = bit32.bxor(_IbjxSQ4H + 0xacc7, 0x51767)
											elseif _IbjxSQ4H - 0x19bc2 == 0x0 then
												_CNQM7 = _w9N93["Y"] - _wiEtA["Y"]
												_IbjxSQ4H = bit32.bxor(_IbjxSQ4H + 0xb49c, 0x37439)
											elseif _IbjxSQ4H == 0x12467 then
												_NTnVq = _w9N93["Z"] - _wiEtA["Z"]
												_IbjxSQ4H = bit32.bxor(_IbjxSQ4H + 0x50f2, 0x965e7)
											elseif _IbjxSQ4H - 0x366d8 == 0x0 then
												(function()
													return (
														(0x8f53 % 0x2 == 0x0) and (bit32 and 18345 or 0x0)
														or (bit32 and 5578 or 0x0)
													)
												end)()
												_IbjxSQ4H = bit32.bxor(_IbjxSQ4H + 0xa7ad, 0xb31f5)
											elseif bit32.bxor(_IbjxSQ4H, 0x810be) == 0x0 then
												if (_nCT0H * _nCT0H + _CNQM7 * _CNQM7 + _NTnVq * _NTnVq) > (0x2 * 20000 - 0) then
													_j3_CA["root"]["Visible"] = false
												else
													local _AlG7u = _jtZcU:WorldToViewportPoint(_w9N93)
													if
														_AlG7u["Z"] <= 0
														or _AlG7u["X"] < -80
														or _AlG7u["X"] > _W2grW
														or _AlG7u["Y"] < -80
														or _AlG7u["Y"] > _fFgSi
													then
														_j3_CA["root"]["Visible"] = false
													else
														local _LITSi, _aOgvw, _lrX3d, _Yy8tF =
															_gcElC["bounds"](_YFjN3, _jtZcU, _eA1qe)
														if _LITSi and _lrX3d >= 4 and _Yy8tF >= (0x2 * 2 - 0) then
															_gcElC["layout"](_j3_CA, _LITSi, _aOgvw, _lrX3d, _Yy8tF)
															_j3_CA["root"]["Visible"] = true
														else
															_j3_CA["root"]["Visible"] = false
														end
													end
												end
												_IbjxSQ4H = nil
											elseif _IbjxSQ4H - 0x2072a == 0x0 then
												_nCT0H = _w9N93["X"] - _wiEtA["X"]
												_IbjxSQ4H = bit32.bxor(bit32.bxor(_IbjxSQ4H, 0x8b72), 0x3179a)
											elseif _IbjxSQ4H == 0xf3f70 then
												(function()
													return (bit32 and 36891 or 0x9a7b)
												end)()
												_IbjxSQ4H = bit32.bxor(_IbjxSQ4H + 0x894a, 0xcae62)
											end
										end
									end
								end
								_r8u4_ = nil
							elseif _r8u4_ == 0x7754d then
								_jtZcU = workspace["CurrentCamera"]
								_r8u4_ = bit32.bxor(_r8u4_ + 0x8e05, 0x1459f)
							elseif bit32.bxor(_r8u4_, 0xd1fec) == 0x0 then
								(function()
									return (bit32 and 17311 or 0x579e)
								end)()
								_r8u4_ = bit32.bxor(_r8u4_ + 0x5b17, 0x7af7b)
							elseif _r8u4_ - 0x99d73 == 0x0 then
								_W2grW, _fFgSi = _lct7a["X"] + (40 + 40), _lct7a["Y"] + 80
								_r8u4_ = bit32.bxor(bit32.bxor(_r8u4_, 0x6e87), 0xfd6b6)
							elseif bit32.bxor(_r8u4_, 0x946cd) == 0x0 then
								if not _jtZcU then
									return
								end
								_r8u4_ = bit32.bxor(bit32.bxor(_r8u4_, 0xc2eb), 0x1984a)
							end
						end
					end
				else
					(function()
						return ((0xd4cc % 0x2 == 0x0) and (bit32 and 27238 or 0x0) or (bit32 and 39167 or 0x0))
					end)()
				end
				_gcElC["set"] = function(_jHiIm, _yPInB)
					local _p3Pho, _NCpOy, _NCpOy
					_NCpOy = 0xc0c54
					while _NCpOy do
						if _NCpOy - 0x457ea == 0x0 then
							(function()
								return (bit32 and 666536144 or 0x4a80)
							end)()
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0xa214), 0x8cfeb)
						elseif _NCpOy - 0x44e54 == 0x0 then
							if not _gcElC["conn"] then
								_gcElC["conn"] = _l3G1i(RunService["RenderStepped"], _gcElC["step"])
							end
							_NCpOy = nil
						elseif _NCpOy - 0x875d8 == 0x0 then
							_p3Pho["fill"]["BackgroundColor3"] = _yPInB
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0x44d7), 0x55c21)
						elseif _NCpOy == 0xee774 then
							if not _p3Pho then
								local _wnRk3, _HGJTD, _zuW8R, _eeP_5M, _eeP_5M
								_eeP_5M = 0xad6b0
								while _eeP_5M do
									if _eeP_5M - 0x8efae == 0x0 then
										_wnRk3["BorderSizePixel"] = 0
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x2692), 0x1b702)
									elseif _eeP_5M - 0x97e3e == 0x0 then
										_wnRk3["Visible"] = false
										_eeP_5M = bit32.bxor(_eeP_5M + 0x4a1a, 0x5026d)
									elseif _eeP_5M - 0xb0cc1 == 0x0 then
										_gcElC["entries"][_jHiIm] = _p3Pho
										_eeP_5M = nil
									elseif bit32.bxor(_eeP_5M, 0x8930a) == 0x0 then
										_zuW8R = Color3["new"](0, 0, 0)
										_eeP_5M = bit32.bxor(_eeP_5M + 0x6491, 0xbf2f5)
									elseif bit32.bxor(_eeP_5M, 0x24892) == 0x0 then
										_HGJTD["Parent"] = _wnRk3
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x464), 0xadffc)
									elseif bit32.bxor(_eeP_5M, 0xa7830) == 0x0 then
										(function()
											return (bit32 and 22692 or 0x8a58)
										end)()
										_eeP_5M = bit32.bxor(_eeP_5M + 0xa1b1, 0xe6c0)
									elseif bit32.bxor(_eeP_5M, 0x9442e) == 0x0 then
										_wnRk3["BackgroundTransparency"] = (0x2 * 1 - 1)
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x8c28), 0x127a8)
									elseif _eeP_5M == 0x6397c then
										_wnRk3["Parent"] = _gcElC["getGui"]()
										_eeP_5M = bit32.bxor(_eeP_5M + 0x44e6, 0xd72a3)
									elseif _eeP_5M - 0xd560e == 0x0 then
										(function()
											return (bit32 and (56128 * 0x3d % 0x10000) or 0xef6b)
										end)()
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x14e1), 0x73adf)
									elseif _eeP_5M - 0xcca35 == 0x0 then
										_HGJTD = Instance["new"]("Frame")
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0xb466), 0xa3984)
									elseif _eeP_5M == 0xad6b0 then
										_wnRk3 = Instance["new"]("Frame")
										_eeP_5M = bit32.bxor(_eeP_5M + 0x2d88, 0x24016)
									elseif _eeP_5M - 0x3056e == 0x0 then
										_p3Pho = {
											["root"] = _wnRk3,
											["fill"] = _HGJTD,
											["outer"] = _gcElC["ringLines"](_wnRk3, _zuW8R),
											["main"] = _gcElC["ringLines"](_wnRk3, _yPInB),
											["inner"] = _gcElC["ringLines"](_wnRk3, _zuW8R),
										}
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x8391), 0x5bf83)
									elseif _eeP_5M == 0xbff21 then
										(function()
											return (bit32 and 1802380341 or 0x2319)
										end)()
										_eeP_5M = bit32.bxor(_eeP_5M + 0xaf3e, 0x1f851)
									elseif _eeP_5M == 0x647d7 then
										_HGJTD["BorderSizePixel"] = 0
										_eeP_5M = bit32.bxor(bit32.bxor(_eeP_5M, 0x940a), 0x49b4f)
									end
								end
							end
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0x143c), 0x47e1e)
						elseif _NCpOy == 0xd6d2e then
							_p3Pho["fill"]["BackgroundTransparency"] = HubSettings["Visuals"]["ESP"]["BoxFilled"] and (850 / 0x3e8)
								or (0x2 * 1 - 1)
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0xc3bd), 0x9e0c7)
						elseif _NCpOy == 0xc3a15 then
							(function()
								return (bit32 and 60703 or 0xed1e)
							end)()
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0x4432), 0x829cd)
						elseif bit32.bxor(_NCpOy, 0x1a8f8) == 0x0 then
							_p3Pho["key"] = ({})[1]
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0xf3f), 0x2d1a1)
						elseif _NCpOy == 0xa8d56 then
							_p3Pho["thick"] = math["clamp"](
								math["floor"](
									(HubSettings["Visuals"]["ESP"]["BoxThickness"] or (0x2 * 1 - 1)) + ((250 + 250) / 0x3e8)
								),
								1,
								6
							)
							_NCpOy = bit32.bxor(_NCpOy + 0x9e73, 0xa8331)
						elseif bit32.bxor(_NCpOy, 0xc0c54) == 0x0 then
							_p3Pho = _gcElC["entries"][_jHiIm]
							_NCpOy = bit32.bxor(bit32.bxor(_NCpOy, 0xc033), 0x22b13)
						elseif bit32.bxor(_NCpOy, 0x37666) == 0x0 then
							for _M2biu, _VFKzk in ipairs(_p3Pho["main"]) do
								_VFKzk["BackgroundColor3"] = _yPInB
							end
							_NCpOy = bit32.bxor(_NCpOy + 0xbee8, 0xc4096)
						end
					end
				end
				_gcElC["remove"] = function(_ORjSI)
					local _XQQfg = _gcElC["entries"][_ORjSI]
					if _XQQfg then
						_XQQfg["root"]:Destroy()
						_gcElC["entries"][_ORjSI] = ({})[1]
					end
					if _gcElC["conn"] and not next(_gcElC["entries"]) then
						_vA5WJ(_gcElC["conn"])
						_gcElC["conn"] = ({})[1]
					end
				end
				if 129 == 0x81 then
					_gcElC["destroy"] = function()
						for _kiNZD in pairs(_gcElC["entries"]) do
							_gcElC["remove"](_kiNZD)
						end
						if _gcElC["gui"] then
							_gcElC["gui"]:Destroy()
							_gcElC["gui"] = ({})[1]
						end
					end
				else
					(function()
						return (bit32 and 44412 or 0xa9fe)
					end)()
				end
				local function _Z9TMp(_mQ1knaV8, _vTJB91o, _IfjmMY)
					if
						HubSettings["Visuals"]["ESP"]["Enabled"]
						or (
							(HubSettings["Visuals"]["ESP"]["DeathCounterESP"] or HubSettings["Visuals"]["ESP"]["SaitamaUltESP"])
							and _IfjmMY
						)
					then
						local _x_jvv = _vTJB91o:FindFirstChild("Head")
						local _KRAs_zBe = _vTJB91o:FindFirstChild("ESP")
						local _hWeW72s = _SCYz7(_mQ1knaV8, _vTJB91o)
						local _oRszEZ = _vTJB91o:FindFirstChild("Highlight")
						if _oRszEZ then
							task["defer"](_oRszEZ["Destroy"], _oRszEZ)
						end
						if HubSettings["Visuals"]["ESP"]["Highlight"] ~= false then
							local _vQCq3, _vQCq3
							_vQCq3 = 0xcc374
							if 0 == 0x0 then
								while _vQCq3 do
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										if _vQCq3 - 0xcc374 == 0x0 then
											if 0 == 0x0 then
												if not _KRAs_zBe then
													_KRAs_zBe = Instance["new"]("Highlight")
												end
											else
												(function()
													return (bit32 and (62125 * 0x3d % 0x10000) or 0xf817)
												end)()
											end
											if 0 == 0x0 then
												_vQCq3 = bit32.bxor(bit32.bxor(_vQCq3, 0xbcac), 0xf3b0c)
											else
												(function()
													return (bit32 and 58596 or 0x1ae4)
												end)()
											end
										elseif _vQCq3 == 0xb9767 then
											_KRAs_zBe["FillTransparency"] = HubSettings["Visuals"]["ESP"]["OutlineTransparency"]
											_vQCq3 = bit32.bxor(_vQCq3 + 0x607a, 0x31af8)
										elseif _vQCq3 == 0x45700 then
											if 1 == 0x1 then
												_KRAs_zBe["OutlineTransparency"] = (1 + 0x2 * 0)
											else
												(function()
													return (bit32 and 57127 or 0xab56)
												end)()
											end
											if 0 == 0x0 then
												_vQCq3 = bit32.bxor(bit32.bxor(_vQCq3, 0x86a6), 0x6e354)
											else
												(function()
													return (bit32 and 50203 or 0x40c4)
												end)()
											end
										elseif bit32.bxor(_vQCq3, 0x8ed19) == 0x0 then
											_KRAs_zBe["FillColor"] = _hWeW72s
											_vQCq3 = bit32.bxor(bit32.bxor(_vQCq3, 0xb95e), 0xc0347)
										elseif _vQCq3 - 0x254e4 == 0x0 then
											(function()
												return (bit32 and (17022 * 0x3d % 0x10000) or 0x41b0)
											end)()
											_vQCq3 = bit32.bxor(bit32.bxor(_vQCq3, 0x9146), 0x88c87)
										elseif _vQCq3 == 0x6c18 then
											(function()
												return (bit32 and 36598 or 0xfeae)
											end)()
											_vQCq3 = bit32.bxor(_vQCq3 + 0x98e, 0x22142)
										elseif _vQCq3 == 0x232f2 then
											_KRAs_zBe["Parent"] = _vTJB91o
											if 1 == 0x1 then
												_vQCq3 = nil
											else
												(function()
													return (bit32 and 471921121 or 0x5fd8)
												end)()
											end
										elseif _vQCq3 == 0xa4925 then
											(function()
												return (bit32 and 8618 or 0x650a)
											end)()
											_vQCq3 = bit32.bxor(_vQCq3 + 0x2c0c, 0xa1929)
										elseif _vQCq3 == 0x344d4 then
											_KRAs_zBe["Name"] = "ESP"
											if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
												_vQCq3 = bit32.bxor(_vQCq3 + 0x4dea, 0x805d9)
											else
												(function()
													return (bit32 and 11868 or 0xd92e)
												end)()
											end
										end
									else
										(function()
											return (bit32 and 20805 or 0x9905)
										end)()
									end
								end
							else
								(function()
									return ((0x57e5 % 0x2 == 0x0) and (bit32 and 11250 or 0x0) or (bit32 and 34480 or 0x0))
								end)()
							end
						elseif _KRAs_zBe then
							_KRAs_zBe:Destroy()
						end
						local _faFnu = _vTJB91o:FindFirstChild("KittyBoxESP")
						if _faFnu then
							_faFnu:Destroy()
						end
						if HubSettings["Visuals"]["ESP"]["Boxes"] then
							_gcElC["set"](
								_vTJB91o,
								HubSettings["Visuals"]["ESP"]["BoxUseESPColor"] and _hWeW72s
									or HubSettings["Visuals"]["ESP"]["BoxColor"]
							)
						else
							_gcElC["remove"](_vTJB91o)
						end
						if not _x_jvv or HubSettings["Visuals"]["ESP"]["NoBillboards"] then
							return
						end
						local _SSbOv8Ct = _x_jvv:FindFirstChild("CheatGui") or Instance["new"]("BillboardGui", _x_jvv)
						local _dtbgzyc = _SSbOv8Ct:FindFirstChild("TextLabel") or Instance["new"]("TextLabel", _SSbOv8Ct)
						if 16 == 0x10 then
							_SSbOv8Ct["Name"] = "CheatGui"
						else
							(function()
								return ((0xe2ca % 0x2 == 0x0) and (bit32 and 29029 or 0x0) or (bit32 and 39702 or 0x0))
							end)()
						end
						_SSbOv8Ct["Size"] = UDim2["fromScale"]((0 + 0x2 * 5), 2)
						if 129 == 0x81 then
							_SSbOv8Ct["StudsOffset"] = Vector3["new"](0, (2 + 2), 0)
						else
							(function()
								return (bit32 and (55476 * 0x3d % 0x10000) or 0x8507)
							end)()
						end
						_dtbgzyc["Size"] = UDim2["fromScale"](1, (1 + 0x2 * 0))
						if 16 == 0x10 then
							_dtbgzyc["TextScaled"] = true
						else
							(function()
								return ((0xacd % 0x2 == 0x0) and (bit32 and 1382 or 0x0) or (bit32 and 59705 or 0x0))
							end)()
						end
						if 1 == 0x1 then
							_dtbgzyc["Font"] = Enum["Font"]["RobotoMono"]
						else
							(function()
								return (bit32 and 31830 or 0xf87d)
							end)()
						end
						_dtbgzyc["TextColor3"] = _hWeW72s
						_dtbgzyc["BackgroundTransparency"] = (0x2 * 1 - 1)
						local _QQTLhs = _wZKifJPa[_vTJB91o:GetAttribute("Character")] or "Other"
						local _HbdhV = (_mQ1knaV8 and _mQ1knaV8:GetAttribute("Ultimate")) or 0
						_dtbgzyc["Text"] = _QQTLhs
							.. " "
							.. math["floor"](_HbdhV)
							.. "% Ult \n"
							.. (_mQ1knaV8 and _mQ1knaV8["Name"] or _vTJB91o["Name"])
					end
				end
				local function _O3IOB(_F16FS, _sy2Ol, _DL55Q)
					local _q2iHF, _h2JWx, _Uzo7T, _wlyg6, _wlyg6
					_wlyg6 = 0xdcc61
					while _wlyg6 do
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							if bit32.bxor(_wlyg6, 0xd6b28) == 0x0 then
								(function()
									return (bit32 and (2109 * 0x3d % 0x10000) or 0x22a8)
								end)()
								if 0 == 0x0 then
									_wlyg6 = bit32.bxor(bit32.bxor(_wlyg6, 0x72d0), 0x64cd6)
								else
									(function()
										return (bit32 and 40812 or 0x88ed)
									end)()
								end
							elseif bit32.bxor(_wlyg6, 0xb16bc) == 0x0 then
								if 65535 == 0xffff then
									if not _DL55Q then
										_gcElC["remove"](_F16FS)
									end
								else
									(function()
										return (bit32 and (11801 * 0x3d % 0x10000) or 0x213f)
									end)()
								end
								_wlyg6 = bit32.bxor(bit32.bxor(_wlyg6, 0x54ae), 0x6b9eb)
							elseif _wlyg6 == 0x8ee90 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									if _Uzo7T and not _DL55Q then
										_Uzo7T:Destroy()
									end
								else
									(function()
										return (bit32 and 32509 or 0xf71d)
									end)()
								end
								_wlyg6 = bit32.bxor(_wlyg6 + 0x21ac, 0x20680)
							elseif _wlyg6 - 0x2ec3c == 0x0 then
								if _q2iHF and not _DL55Q then
									_q2iHF:Destroy()
								end
								_wlyg6 = bit32.bxor(_wlyg6 + 0x66d3, 0xbbd9f)
							elseif bit32.bxor(_wlyg6, 0x7dab5) == 0x0 then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_Uzo7T = _F16FS:FindFirstChild("KittyBoxESP")
								else
									(function()
										return (bit32 and 49899 or 0xa1eb)
									end)()
								end
								if 65535 == 0xffff then
									_wlyg6 = bit32.bxor(bit32.bxor(_wlyg6, 0x8daf), 0x5bb26)
								else
									(function()
										return (bit32 and (8794 * 0x3d % 0x10000) or 0x2324)
									end)()
								end
							elseif _wlyg6 - 0x75866 == 0x0 then
								_h2JWx = _F16FS:FindFirstChild("Head")
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_wlyg6 = bit32.bxor(_wlyg6 + 0x8b88, 0x395b)
								else
									(function()
										return (bit32 and 55918 or 0x5b6f)
									end)()
								end
							elseif bit32.bxor(_wlyg6, 0xdcc61) == 0x0 then
								if 65535 == 0xffff then
									_q2iHF = _F16FS:FindFirstChild("ESP")
								else
									(function()
										return (bit32 and 28250 or 0xbc6e)
									end)()
								end
								if 16 == 0x10 then
									_wlyg6 = bit32.bxor(bit32.bxor(_wlyg6, 0x2902), 0xabd05)
								else
									(function()
										return (bit32 and 60037 or 0x94ea)
									end)()
								end
							elseif _wlyg6 == 0xb552e then
								(function()
									return (bit32 and (63834 * 0x3d % 0x10000) or 0xbc0d)
								end)()
								_wlyg6 = bit32.bxor(_wlyg6 + 0x8dd1, 0xd9696)
							elseif _wlyg6 - 0x67469 == 0x0 then
								if 0 == 0x0 then
									(function()
										return (bit32 and (3206 * 0x3d % 0x10000) or 0xd74)
									end)()
								else
									(function()
										return ((0x6a0c % 0x2 == 0x0) and (bit32 and 13574 or 0x0) or (bit32 and 9193 or 0x0))
									end)()
								end
								_wlyg6 = bit32.bxor(_wlyg6 + 0xb727, 0xa40b8)
							elseif _wlyg6 - 0xdfbf9 == 0x0 then
								if _h2JWx then
									local _fKFUS = _h2JWx:FindFirstChild("CheatGui")
									if _fKFUS then
										if 0 == 0x0 then
											_fKFUS:Destroy()
										else
											(function()
												return (bit32 and 21497 or 0xb953)
											end)()
										end
									end
								end
								_wlyg6 = nil
							end
						else
							(function()
								return ((0x9a63 % 0x2 == 0x0) and (bit32 and 19761 or 0x0) or (bit32 and 61931 or 0x0))
							end)()
						end
					end
				end
				local function _S1SQ1(_J3i47, _QYxjO)
					for _HJ7zL, _u0UX9 in pairs(PlayersService:GetChildren()) do
						if _u0UX9 ~= HubLocalPlayer then
							local _EOodm = _u0UX9["Character"]
							if _EOodm then
								if _J3i47 then
									_O3IOB(_EOodm, _u0UX9, _QYxjO)
								else
									if 129 == 0x81 then
										_Z9TMp(_u0UX9, _EOodm)
									else
										(function()
											return (bit32 and 346723516 or 0xafc9)
										end)()
									end
								end
							end
						end
					end
				end
				local function _tTg1H()
					if 129 == 0x81 then
						for _iZ2Lm, _rT9kb in ipairs(PlayersService:GetPlayers()) do
							local _gBstv = _rT9kb ~= HubLocalPlayer and _rT9kb["Character"]
							if _gBstv then
								_O3IOB(_gBstv, _rT9kb, false)
								local _VUMHu = _gBstv:FindFirstChild("Counter") ~= ({})[1]
									or (_gBstv:GetAttribute("Ulted") and _gBstv:GetAttribute("Character") == "Bald")
								if 0 == 0x0 then
									_Z9TMp(_rT9kb, _gBstv, _VUMHu)
								else
									(function()
										return (bit32 and 62255 or 0xd312)
									end)()
								end
							end
						end
					else
						(function()
							return (bit32 and (41940 * 0x3d % 0x10000) or 0xbd75)
						end)()
					end
				end
				local _eoVGv = {
					["saved"] = {},
					["removed"] = {},
					["conns"] = {},
					["heart"] = ({})[1],
					["quality"] = ({})[1],
					["gen"] = 0,
					["roots"] = ({})[1],
					["rootIndex"] = 0,
					["list"] = ({})[1],
					["listIndex"] = 0,
					["queue"] = {},
					["qHead"] = 1,
					["qTail"] = 0,
					["budget"] = (2 / 0x3e8),
				}
				local _TSIcS = {
					[Enum["Material"]["Neon"]] = true,
					[Enum["Material"]["Glass"]] = true,
					[Enum["Material"]["ForceField"]] = true,
					[Enum["Material"]["Air"]] = true,
					[Enum["Material"]["Water"]] = true,
				}
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					_eoVGv["setProp"] = function(_IYC_m, _xJZN7, _qkxCW)
						_IYC_m[_xJZN7] = _qkxCW
					end
				else
					(function()
						return ((0xeb3e % 0x2 == 0x0) and (bit32 and 30111 or 0x0) or (bit32 and 4183 or 0x0))
					end)()
				end
				if 129 == 0x81 then
					_eoVGv["save"] = function(_B3mei, _MQ6GX)
						local _DjboQ = _eoVGv["saved"][_B3mei]
						if not _DjboQ then
							_DjboQ = {}
							_eoVGv["saved"][_B3mei] = _DjboQ
						end
						if _DjboQ[_MQ6GX] == ({})[1] then
							_DjboQ[_MQ6GX] = _B3mei[_MQ6GX]
						end
					end
				else
					(function()
						return (bit32 and (26762 * 0x3d % 0x10000) or 0x6b7f)
					end)()
				end
				_eoVGv["interesting"] = function(_OW2eK)
					return _OW2eK:IsA("BasePart")
						or _OW2eK:IsA("SurfaceAppearance")
						or _OW2eK:IsA("Decal")
						or _OW2eK:IsA("SpecialMesh")
				end
				if 65535 == 0xffff then
					_eoVGv["onCharacter"] = function(_ZQuoY)
						local _Q4lZ2, _lPwb_, _lPwb_
						_lPwb_ = 0x83e75
						while _lPwb_ do
							if _lPwb_ - 0x83e75 == 0x0 then
								if _ZQuoY:IsA("Accessory") or _ZQuoY:FindFirstAncestorOfClass("Accessory") then
									return true
								end
								_lPwb_ = bit32.bxor(_lPwb_ + 0x10fb, 0x1875f)
							elseif _lPwb_ - 0xec1b6 == 0x0 then
								return false
							elseif bit32.bxor(_lPwb_, 0x9c82f) == 0x0 then
								_Q4lZ2 = _ZQuoY:FindFirstAncestorWhichIsA("Model")
								_lPwb_ = bit32.bxor(_lPwb_ + 0x80c9, 0xc437)
							elseif bit32.bxor(_lPwb_, 0xa8ccf) == 0x0 then
								while _Q4lZ2 do
									if _Q4lZ2:FindFirstChildOfClass("Humanoid") then
										return true
									end
									_Q4lZ2 = _Q4lZ2:FindFirstAncestorWhichIsA("Model")
								end
								_lPwb_ = bit32.bxor(bit32.bxor(_lPwb_, 0x11b9), 0x45cc0)
							elseif _lPwb_ - 0x7817d == 0x0 then
								(function()
									return (bit32 and 14661 or 0xc239)
								end)()
								_lPwb_ = bit32.bxor(bit32.bxor(_lPwb_, 0x5d18), 0xb9c27)
							elseif bit32.bxor(_lPwb_, 0xc4042) == 0x0 then
								(function()
									return (bit32 and 59381 or 0x76fd)
								end)()
								_lPwb_ = bit32.bxor(_lPwb_ + 0x24f6, 0xbe445)
							end
						end
					end
				else
					(function()
						return ((0x40ab % 0x2 == 0x0) and (bit32 and 8277 or 0x0) or (bit32 and 21768 or 0x0))
					end)()
				end
				_eoVGv["fixCharacters"] = function()
					for _b1L5D, _mVK4R in pairs(_eoVGv["saved"]) do
						if _b1L5D["Parent"] and _eoVGv["onCharacter"](_b1L5D) then
							for _dYDJ6, _ofwlj in pairs(_mVK4R) do
								pcall(_eoVGv["setProp"], _b1L5D, _dYDJ6, _ofwlj)
							end
							_eoVGv["saved"][_b1L5D] = ({})[1]
						end
					end
					for _z00fL, _qvVjP in pairs(_eoVGv["removed"]) do
						if _qvVjP and _qvVjP["Parent"] and _eoVGv["onCharacter"](_qvVjP) then
							pcall(_eoVGv["setProp"], _z00fL, "Parent", _qvVjP)
							_eoVGv["removed"][_z00fL] = ({})[1]
						end
					end
				end
				if 16 == 0x10 then
					_eoVGv["flatten"] = function(_BZ4J4)
						if _eoVGv["onCharacter"](_BZ4J4) then
							return
						end
						if _BZ4J4:IsA("BasePart") then
							if _BZ4J4["Material"] ~= Enum["Material"]["SmoothPlastic"] and not _TSIcS[_BZ4J4["Material"]] then
								_eoVGv["save"](_BZ4J4, "Material")
								_BZ4J4["Material"] = Enum["Material"]["SmoothPlastic"]
							end
							if _BZ4J4:IsA("MeshPart") and _BZ4J4["TextureID"] ~= "" then
								_eoVGv["save"](_BZ4J4, "TextureID")
								_BZ4J4["TextureID"] = ""
							end
						elseif _BZ4J4:IsA("SurfaceAppearance") then
							if _eoVGv["removed"][_BZ4J4] == ({})[1] then
								_eoVGv["removed"][_BZ4J4] = _BZ4J4["Parent"]
								_BZ4J4["Parent"] = ({})[1]
							end
						elseif _BZ4J4:IsA("Decal") then
							if _BZ4J4["Transparency"] < 1 then
								_eoVGv["save"](_BZ4J4, "Transparency")
								_BZ4J4["Transparency"] = (0x2 * 1 - 1)
							end
						elseif _BZ4J4:IsA("SpecialMesh") and _BZ4J4["TextureId"] ~= "" then
							_eoVGv["save"](_BZ4J4, "TextureId")
							_BZ4J4["TextureId"] = ""
						end
					end
				else
					(function()
						return (bit32 and 15182 or 0x355c)
					end)()
				end
				_eoVGv["scopeRoots"] = function()
					local _M5_tm = {}
					for _XZqmo, _OVhkZ in ipairs(workspace:GetChildren()) do
						if
							_OVhkZ ~= _f5mDQ["Live"]
							and _OVhkZ ~= _f5mDQ["Thrown"]
							and _OVhkZ ~= _f5mDQ["Terrain"]
							and _OVhkZ ~= workspace["CurrentCamera"]
						then
							_M5_tm[#_M5_tm + (0x2 * 1 - 1)] = _OVhkZ
						end
					end
					return _M5_tm
				end
				_eoVGv["enqueue"] = function(_Z0uRz)
					if _eoVGv["interesting"](_Z0uRz) then
						_eoVGv["qTail"] = _eoVGv["qTail"] + 1
						_eoVGv["queue"][_eoVGv["qTail"]] = _Z0uRz
					end
				end
				_eoVGv["watch"] = function(_kfJlg)
					_eoVGv["conns"][#_eoVGv["conns"] + 1] = _l3G1i(_kfJlg["DescendantAdded"], _eoVGv["enqueue"])
				end
				_eoVGv["nextObject"] = function()
					if _eoVGv["qHead"] <= _eoVGv["qTail"] then
						local _bAzz2 = _eoVGv["queue"][_eoVGv["qHead"]]
						_eoVGv["queue"][_eoVGv["qHead"]] = ({})[1]
						_eoVGv["qHead"] = _eoVGv["qHead"] + (1 + 0)
						return _bAzz2
					end
					_eoVGv["qHead"], _eoVGv["qTail"] = (1 + 0), 0
					while _eoVGv["roots"] do
						local _mWIs8 = _eoVGv["list"]
						if _mWIs8 then
							local _x1tX9 = _eoVGv["listIndex"] + (1 + 0)
							local _NS7mW = _mWIs8[_x1tX9]
							if _NS7mW then
								_eoVGv["listIndex"] = _x1tX9
								return _NS7mW
							end
							_eoVGv["list"] = ({})[1]
						end
						local _i5la_lk3 = _eoVGv["roots"][_eoVGv["rootIndex"] + 1]
						if not _i5la_lk3 then
							return ({})[1]
						end
						_eoVGv["rootIndex"] = _eoVGv["rootIndex"] + 1
						if _i5la_lk3["Parent"] then
							_eoVGv["list"], _eoVGv["listIndex"] = _i5la_lk3:GetDescendants(), 0
							return _i5la_lk3
						end
					end
					return ({})[1]
				end
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					_eoVGv["step"] = function()
						local _Dhs3vad = EnvAccess["os"]["clock"]()
						repeat
							for _E7OmmT = 1, 20 do
								local _ZmEzc = _eoVGv["nextObject"]()
								if not _ZmEzc then
									return
								end
								if _ZmEzc["Parent"] then
									pcall(_eoVGv["flatten"], _ZmEzc)
								end
							end
						until EnvAccess["os"]["clock"]() - _Dhs3vad > _eoVGv["budget"]
					end
				else
					(function()
						return (bit32 and 13483 or 0x36ee)
					end)()
				end
				if 0 == 0x0 then
					_eoVGv["disconnect"] = function()
						for _uwnGWzzi, _jaBtaeX in ipairs(_eoVGv["conns"]) do
							_vA5WJ(_jaBtaeX)
						end
						table["clear"](_eoVGv["conns"])
						if _eoVGv["heart"] then
							_vA5WJ(_eoVGv["heart"])
							_eoVGv["heart"] = ({})[1]
						end
					end
				else
					(function()
						return (bit32 and (49260 * 0x3d % 0x10000) or 0xb6e1)
					end)()
				end
				if 0 == 0x0 then
					_eoVGv["apply"] = function()
						_eoVGv["gen"] = _eoVGv["gen"] + 1
						_eoVGv["disconnect"]()
						_eoVGv["fixCharacters"]()
						_eoVGv["roots"], _eoVGv["rootIndex"], _eoVGv["list"], _eoVGv["listIndex"] =
							_eoVGv["scopeRoots"](), 0, ({})[1], 0
						table["clear"](_eoVGv["queue"])
						_eoVGv["qHead"], _eoVGv["qTail"] = 1, 0
						for _wrwleq, _bEMbS in ipairs(_eoVGv["roots"]) do
							_eoVGv["watch"](_bEMbS)
						end
						_eoVGv["conns"][#_eoVGv["conns"] + (0x2 * 1 - 1)] = _l3G1i(workspace["ChildAdded"], function(_GRGnxhd8)
							if
								_GRGnxhd8 ~= _f5mDQ["Live"]
								and _GRGnxhd8 ~= _f5mDQ["Thrown"]
								and _GRGnxhd8 ~= _f5mDQ["Terrain"]
								and _GRGnxhd8 ~= workspace["CurrentCamera"]
							then
								_eoVGv["roots"][#_eoVGv["roots"] + (1 + 0)] = _GRGnxhd8
								_eoVGv["watch"](_GRGnxhd8)
							end
						end)
						_eoVGv["heart"] = _l3G1i(RunService["Heartbeat"], _eoVGv["step"])
						pcall(function()
							local _FHm8agO = EnvAccess["settings"]()["Rendering"]
							if _eoVGv["quality"] == ({})[1] then
								_eoVGv["quality"] = _FHm8agO["QualityLevel"]
							end
							_FHm8agO["QualityLevel"] = Enum["QualityLevel"]["Level01"]
						end)
					end
				else
					(function()
						return (bit32 and 50681 or 0x62c5)
					end)()
				end
				_eoVGv["restore"] = function(_kT4OdR7V)
					_eoVGv["gen"] = _eoVGv["gen"] + (1 + 0)
					local _Pgo9a = _eoVGv["gen"]
					_eoVGv["disconnect"]()
					_eoVGv["roots"], _eoVGv["list"] = ({})[1], ({})[1]
					table["clear"](_eoVGv["queue"])
					_eoVGv["qHead"], _eoVGv["qTail"] = 1, 0
					local function _aKxqPdSj()
						local _FTdGp, _kf4gi = EnvAccess["os"]["clock"](), 0
						local function _jncD6()
							_kf4gi = _kf4gi + (1 + 0)
							if
								not _kT4OdR7V
								and _kf4gi % (13 + 12) == 0
								and EnvAccess["os"]["clock"]() - _FTdGp > _eoVGv["budget"]
							then
								RunService["Heartbeat"]:Wait()
								if _eoVGv["gen"] ~= _Pgo9a then
									return false
								end
								_FTdGp = EnvAccess["os"]["clock"]()
							end
							return true
						end
						for _ObWIq, _t2Cjx in next, _eoVGv["saved"] do
							_eoVGv["saved"][_ObWIq] = ({})[1]
							if _ObWIq["Parent"] then
								for _Eg6Ge, _j7ikc in pairs(_t2Cjx) do
									pcall(_eoVGv["setProp"], _ObWIq, _Eg6Ge, _j7ikc)
								end
							end
							if not _jncD6() then
								return
							end
						end
						for _OVzoC, _N9uXV in next, _eoVGv["removed"] do
							_eoVGv["removed"][_OVzoC] = ({})[1]
							if _N9uXV and _N9uXV["Parent"] then
								pcall(_eoVGv["setProp"], _OVzoC, "Parent", _N9uXV)
							end
							if not _jncD6() then
								return
							end
						end
						if _eoVGv["quality"] ~= ({})[1] then
							pcall(function()
								EnvAccess["settings"]()["Rendering"]["QualityLevel"] = _eoVGv["quality"]
							end)
							_eoVGv["quality"] = ({})[1]
						end
					end
					if _kT4OdR7V then
						_aKxqPdSj()
					else
						task["spawn"](_aKxqPdSj)
					end
				end
				local function _sLGb1(_XBTS0, _CperF)
					if 1 == 0x1 then
						if _CperF then
							_eoVGv["apply"]()
						elseif _XBTS0 == false then
							_eoVGv["restore"]()
						end
					else
						(function()
							return (bit32 and 61179 or 0x47d6)
						end)()
					end
				end
				local _NSADL = { ["highlight"] = ({})[1], ["headMask"] = ({})[1], ["mats"] = {} }
				local function _sGRHo()
					for _Xkmy_, _WPmPE in pairs(_NSADL["mats"]) do
						if _Xkmy_ and _Xkmy_["Parent"] then
							pcall(function()
								_Xkmy_["Material"] = _WPmPE[1]
								_Xkmy_["Color"] = _WPmPE[2]
								_Xkmy_["CustomPhysicalProperties"] = _WPmPE[(3 + 0x2 * 0)]
							end)
						end
					end
					table["clear"](_NSADL["mats"])
				end
				local function _BZad1()
					local _gmYrb = _Z0Hry or HubLocalPlayer["Character"]
					if 65535 == 0xffff then
						if not (HubSettings["Visuals"]["SelfChams"]["Enabled"] and _gmYrb and _gmYrb["Parent"]) then
							if _NSADL["highlight"] then
								pcall(function()
									_NSADL["highlight"]:Destroy()
								end)
								_NSADL["highlight"] = ({})[1]
							end
							if 16 == 0x10 then
								if _NSADL["headMask"] then
									pcall(function()
										_NSADL["headMask"]:Destroy()
									end)
									_NSADL["headMask"] = ({})[1]
								end
							else
								(function()
									return (bit32 and 5074 or 0x1113)
								end)()
							end
							_sGRHo()
							return
						end
					else
						(function()
							return (bit32 and 46875 or 0xb729)
						end)()
					end
					local _qCIi9 = HubSettings["Visuals"]["SelfChams"]["Color"]
					if not (_NSADL["highlight"] and _NSADL["highlight"]["Parent"] == _gmYrb) then
						if _NSADL["highlight"] then
							pcall(function()
								_NSADL["highlight"]:Destroy()
							end)
						end
						local _XYh5p = _gmYrb:FindFirstChild("KittySelfChams")
						if _XYh5p and _XYh5p:IsA("Highlight") then
							_NSADL["highlight"] = _XYh5p
						else
							_NSADL["highlight"] = Instance["new"]("Highlight")
							_NSADL["highlight"]["Name"] = "KittySelfChams"
							if 0 == 0x0 then
								_NSADL["highlight"]["Adornee"] = _gmYrb
							else
								(function()
									return (bit32 and 24069118 or 0x4dbf)
								end)()
							end
							_NSADL["highlight"]["Parent"] = _gmYrb
						end
					end
					if 0 == 0x0 then
						_NSADL["highlight"]["FillColor"] = _qCIi9
					else
						(function()
							return (bit32 and 2051200254 or 0x4b8d)
						end)()
					end
					_NSADL["highlight"]["OutlineColor"] = _qCIi9
					_NSADL["highlight"]["FillTransparency"] = HubSettings["Visuals"]["SelfChams"]["FillTransparency"]
					_NSADL["highlight"]["OutlineTransparency"] = HubSettings["Visuals"]["SelfChams"]["OutlineTransparency"]
					_NSADL["highlight"]["DepthMode"] = Enum["HighlightDepthMode"]["AlwaysOnTop"]
					local _Al1_x = _gQE1u or _gmYrb:FindFirstChild("Head")
					if HubSettings["Visuals"]["Headless"] and _Al1_x and _Al1_x["Parent"] == _gmYrb then
						if 0 == 0x0 then
							if not (_NSADL["headMask"] and _NSADL["headMask"]["Parent"] == _Al1_x) then
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									if _NSADL["headMask"] then
										if 0 == 0x0 then
											pcall(function()
												_NSADL["headMask"]:Destroy()
											end)
										else
											(function()
												return (
													(0xbe83 % 0x2 == 0x0) and (bit32 and 24385 or 0x0)
													or (bit32 and 55040 or 0x0)
												)
											end)()
										end
									end
								else
									(function()
										return (bit32 and 29599 or 0xf8fc)
									end)()
								end
								local _BOX7A = _Al1_x:FindFirstChild("KittySelfChamsHeadMask")
								if _BOX7A and _BOX7A:IsA("Highlight") then
									_NSADL["headMask"] = _BOX7A
								else
									_NSADL["headMask"] = Instance["new"]("Highlight")
									_NSADL["headMask"]["Name"] = "KittySelfChamsHeadMask"
									if 129 == 0x81 then
										_NSADL["headMask"]["Adornee"] = _Al1_x
									else
										(function()
											return (bit32 and (58915 * 0x3d % 0x10000) or 0xe7cd)
										end)()
									end
									_NSADL["headMask"]["Parent"] = _Al1_x
								end
							end
						else
							(function()
								return (bit32 and (14604 * 0x3d % 0x10000) or 0x65bb)
							end)()
						end
						_NSADL["headMask"]["FillTransparency"] = 1
						_NSADL["headMask"]["OutlineTransparency"] = (0x2 * 1 - 1)
						if 0 == 0x0 then
							_NSADL["headMask"]["DepthMode"] = Enum["HighlightDepthMode"]["AlwaysOnTop"]
						else
							(function()
								return (bit32 and 50320 or 0x59c4)
							end)()
						end
					else
						if _NSADL["headMask"] then
							pcall(function()
								_NSADL["headMask"]:Destroy()
							end)
							_NSADL["headMask"] = ({})[1]
						end
					end
					local _S6cOl = HubSettings["Visuals"]["SelfChams"]["Material"]
					if _S6cOl and _S6cOl ~= "None" then
						local _lsTQT = Enum["Material"][_S6cOl] or Enum["Material"]["ForceField"]
						for _cmUMF, _vNYEl in ipairs(_gmYrb:GetDescendants()) do
							if
								_vNYEl:IsA("BasePart")
								and _vNYEl["Name"] ~= "HumanoidRootPart"
								and not _vNYEl:FindFirstAncestorWhichIsA("Tool")
							then
								if not _NSADL["mats"][_vNYEl] then
									if 65535 == 0xffff then
										_NSADL["mats"][_vNYEl] =
											{ _vNYEl["Material"], _vNYEl["Color"], _vNYEl["CustomPhysicalProperties"] }
									else
										(function()
											return (bit32 and (20681 * 0x3d % 0x10000) or 0x5252)
										end)()
									end
									_vNYEl["CustomPhysicalProperties"] = _vNYEl["CurrentPhysicalProperties"]
								end
								if _vNYEl["Material"] ~= _lsTQT then
									_vNYEl["Material"] = _lsTQT
								end
								_vNYEl["Color"] = _qCIi9
							end
						end
					else
						_sGRHo()
					end
				end
				local function _S1n8e(_ljKIj)
					local _oQwzM = _Z0Hry or HubLocalPlayer["Character"]
					if not _oQwzM then
						return
					end
					local _H8a_S = _oQwzM:FindFirstChild("Right Leg")
					local _eupSm = _oQwzM:FindFirstChildOfClass("Humanoid")
					if not _H8a_S then
						return
					end
					if 0 == 0x0 then
						if _ljKIj then
							if 0 == 0x0 then
								for _RZFaO, _oMFBZ in ipairs(_oQwzM:GetChildren()) do
									if
										_oMFBZ:IsA("CharacterMesh")
										and (
											_oMFBZ["Name"] == "KittyKorbloxCM"
											or _oMFBZ["BodyPart"] == Enum["BodyPart"]["RightLeg"]
										)
									then
										pcall(function()
											_oMFBZ:Destroy()
										end)
									end
								end
							else
								(function()
									return (bit32 and 57723 or 0x22e1)
								end)()
							end
							if _eupSm then
								pcall(function()
									local _Hkgtd = _eupSm:GetAppliedDescription()
									if _Hkgtd then
										_Hkgtd["RightLeg"] = 139607718
										_eupSm:ApplyDescription(_Hkgtd)
									end
								end)
							end
							local _KBwd6 = false
							pcall(function()
								local _dyqF1 = game:GetObjects("rbxassetid://139607718")
								if _dyqF1 and #_dyqF1 > 0 then
									for _Ah8iP, _n_Kwe in ipairs(_dyqF1) do
										if _n_Kwe:IsA("CharacterMesh") and _n_Kwe["BodyPart"] == Enum["BodyPart"]["RightLeg"] then
											_n_Kwe["Name"] = "KittyKorbloxCM"
											_n_Kwe["Parent"] = _oQwzM
											_KBwd6 = true
										else
											for _K0t9W, _dLkZs in ipairs(_n_Kwe:GetDescendants()) do
												if
													_dLkZs:IsA("CharacterMesh")
													and _dLkZs["BodyPart"] == Enum["BodyPart"]["RightLeg"]
												then
													_dLkZs["Name"] = "KittyKorbloxCM"
													_dLkZs["Parent"] = _oQwzM
													_KBwd6 = true
												end
											end
										end
									end
								end
							end)
							if _H8a_S then
								if not _KBwd6 then
									local _ga5DU = Instance["new"]("CharacterMesh")
									_ga5DU["Name"] = "KittyKorbloxCM"
									_ga5DU["MeshId"] = 101851696
									if 1 == 0x1 then
										_ga5DU["OverlayTextureId"] = 101851254
									else
										(function()
											return (bit32 and (37185 * 0x3d % 0x10000) or 0xfc12)
										end)()
									end
									_ga5DU["BaseTextureId"] = 101851254
									_ga5DU["BodyPart"] = Enum["BodyPart"]["RightLeg"]
									if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
										_ga5DU["Parent"] = _oQwzM
									else
										(function()
											return (bit32 and (38322 * 0x3d % 0x10000) or 0x937d)
										end)()
									end
								end
								local _zNIqW = _H8a_S:FindFirstChild("KittyKorbloxSM") or Instance["new"]("SpecialMesh")
								_zNIqW["Name"] = "KittyKorbloxSM"
								if 16 == 0x10 then
									_zNIqW["MeshType"] = Enum["MeshType"]["FileMesh"]
								else
									(function()
										return ((0x3aac % 0x2 == 0x0) and (bit32 and 7510 or 0x0) or (bit32 and 21820 or 0x0))
									end)()
								end
								_zNIqW["MeshId"] = "rbxassetid://101851696"
								_zNIqW["TextureId"] = "rbxassetid://101851254"
								if 1 == 0x1 then
									_zNIqW["Scale"] = Vector3["new"]((1 + 0x2 * 0), 1, 1)
								else
									(function()
										return (bit32 and 452445938 or 0xd2ed)
									end)()
								end
								_zNIqW["Offset"] = Vector3["new"](0, 0, 0)
								_zNIqW["Parent"] = _H8a_S
								_IeaiYt2E(_H8a_S, "Transparency", 0)
								local _WwRku = Color3["fromRGB"]((3 + 0x2 * 12), 42, (1 + 0x2 * 26))
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_IeaiYt2E(_H8a_S, "Color", _WwRku)
								else
									(function()
										return (bit32 and (13280 * 0x3d % 0x10000) or 0x33d5)
									end)()
								end
								local _pkakj = _oQwzM:FindFirstChildOfClass("BodyColors")
								if _pkakj then
									if 16 == 0x10 then
										_IeaiYt2E(_pkakj, "RightLegColor3", _WwRku)
									else
										(function()
											return (bit32 and (22605 * 0x3d % 0x10000) or 0x578c)
										end)()
									end
								end
								_vA5WJ(_lH0uIxY["korblox"])
								_lH0uIxY["korblox"] = _l3G1i(_H8a_S:GetPropertyChangedSignal("Color"), function()
									if HubSettings["Visuals"]["Korblox"] and _H8a_S["Color"] ~= _WwRku then
										_H8a_S["Color"] = _WwRku
									end
								end)
							end
						else
							_vA5WJ(_lH0uIxY["korblox"])
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_lH0uIxY["korblox"] = ({})[1]
							else
								(function()
									return ((0x284e % 0x2 == 0x0) and (bit32 and 5159 or 0x0) or (bit32 and 62186 or 0x0))
								end)()
							end
							if _H8a_S then
								_H8a_S["Color"] = _UbxYIsuM(_H8a_S, "Color")
							end
							local _gqcJm = _oQwzM:FindFirstChildOfClass("BodyColors")
							if 65535 == 0xffff then
								if _gqcJm then
									_gqcJm["RightLegColor3"] = _UbxYIsuM(_gqcJm, "RightLegColor3")
								end
							else
								(function()
									return (bit32 and 32487 or 0x9145)
								end)()
							end
							if 0 == 0x0 then
								for _z87uz9J, _WP3Sgybg in ipairs(_oQwzM:GetChildren()) do
									if
										_WP3Sgybg:IsA("CharacterMesh")
										and (
											_WP3Sgybg["Name"] == "KittyKorbloxCM"
											or _WP3Sgybg["BodyPart"] == Enum["BodyPart"]["RightLeg"]
										)
									then
										pcall(function()
											_WP3Sgybg:Destroy()
										end)
									end
								end
							else
								(function()
									return (bit32 and (30379 * 0x3d % 0x10000) or 0x72a1)
								end)()
							end
							if 0 == 0x0 then
								if _H8a_S then
									local _VbZTs = _H8a_S:FindFirstChild("KittyKorbloxSM")
									if _VbZTs then
										pcall(function()
											_VbZTs:Destroy()
										end)
									end
									if 129 == 0x81 then
										_H8a_S["Transparency"] = 0
									else
										(function()
											return (bit32 and 31600 or 0xafec)
										end)()
									end
								end
							else
								(function()
									return (bit32 and 60159 or 0xee5a)
								end)()
							end
							if _eupSm then
								pcall(function()
									local _sVij5Y = _eupSm:GetAppliedDescription()
									if _sVij5Y then
										_sVij5Y["RightLeg"] = 0
										_eupSm:ApplyDescription(_sVij5Y)
									end
								end)
							end
						end
					else
						(function()
							return (bit32 and 1353654681 or 0x8239)
						end)()
					end
				end
				local _LMAzx6P = {
					["exists"] = false,
					["Density"] = ((0x2 * 150 - 0) / 0x3e8),
					["Offset"] = 0,
					["Color"] = Color3["fromRGB"]((103 + 96), 170, (0x2 * 55 - 3)),
					["Decay"] = Color3["fromRGB"](92, 60, 13),
					["Glare"] = 0,
					["Haze"] = 0,
				}
				local _zuSl39H = {
					["blur"] = ({})[1],
					["conn"] = ({})[1],
					["lastCFrame"] = ({})[1],
					["currentBlur"] = 0,
				}
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					_zuSl39H["getBlur"] = function()
						if _zuSl39H["blur"] and _zuSl39H["blur"]["Parent"] then
							return _zuSl39H["blur"]
						end
						local _UCcymD3v = Lighting:FindFirstChild("KittyMotionBlur")
						if not _UCcymD3v or not _UCcymD3v:IsA("BlurEffect") then
							_UCcymD3v = Instance["new"]("BlurEffect")
							_UCcymD3v["Name"] = "KittyMotionBlur"
						end
						_UCcymD3v["Size"] = 0
						_UCcymD3v["Parent"] = Lighting
						_zuSl39H["blur"] = _UCcymD3v
						return _UCcymD3v
					end
				else
					(function()
						return ((0x458a % 0x2 == 0x0) and (bit32 and 8901 or 0x0) or (bit32 and 22783 or 0x0))
					end)()
				end
				if 1 == 0x1 then
					_zuSl39H["step"] = function(_HuFAX)
						local _GEnMnf = workspace["CurrentCamera"]
						if not _GEnMnf then
							return
						end
						local _pZjwKwu = _GEnMnf["CFrame"]
						if not _zuSl39H["lastCFrame"] then
							_zuSl39H["lastCFrame"] = _pZjwKwu
							return
						end
						local _Ufi2yqNl = _zuSl39H["lastCFrame"]
						local _bBxok = math["clamp"](_Ufi2yqNl["LookVector"]:Dot(_pZjwKwu["LookVector"]), -1, (1 + 0))
						local _GnS5ed = math["acos"](_bBxok)
						local _payrV = _HuFAX > 0 and (_GnS5ed / _HuFAX) or 0
						local _UR3GY = (_pZjwKwu["Position"] - _Ufi2yqNl["Position"])["Magnitude"]
						local _Pg_L4 = _HuFAX > 0 and (_UR3GY / _HuFAX) or 0
						local _ur1pw = (HubSettings["Visuals"]["MotionBlur"] and HubSettings["Visuals"]["MotionBlur"]["Intensity"])
							or (0 + 0x2 * 5)
						local _dI0r0 = math["clamp"](_ur1pw, (0x2 * 1 - 1), (0 + 0x2 * 15))
						local _oYy6S = _payrV * (1500 / 0x3e8) * (_ur1pw / (0x2 * 5 - 0))
						local _PwdCh = math["max"](0, (_Pg_L4 - (0 + 0x2 * 10)) * ((0x2 * 20 - 0) / 0x3e8))
						local _uIuIE = math["clamp"](_oYy6S + _PwdCh, 0, _dI0r0)
						local _xPd4k = math["clamp"](_HuFAX * (15 + 0), 0, (1 + 0x2 * 0))
						_zuSl39H["currentBlur"] = _zuSl39H["currentBlur"] + (_uIuIE - _zuSl39H["currentBlur"]) * _xPd4k
						if _zuSl39H["currentBlur"] < ((0 + 0x2 * 25) / 0x3e8) then
							_zuSl39H["currentBlur"] = 0
						end
						local _csYCH = _zuSl39H["getBlur"]()
						_csYCH["Size"] = _zuSl39H["currentBlur"]
						_zuSl39H["lastCFrame"] = _pZjwKwu
					end
				else
					(function()
						return (bit32 and 60354 or 0x8892)
					end)()
				end
				if 0 == 0x0 then
					_zuSl39H["set"] = function(_D3QP_)
						_vA5WJ(_zuSl39H["conn"])
						_zuSl39H["conn"] = ({})[1]
						_zuSl39H["lastCFrame"] = ({})[1]
						_zuSl39H["currentBlur"] = 0
						if _D3QP_ then
							local _OB36N = _zuSl39H["getBlur"]()
							_OB36N["Size"] = 0
							_zuSl39H["conn"] = _l3G1i(RunService["RenderStepped"], _zuSl39H["step"])
						else
							if _zuSl39H["blur"] then
								pcall(function()
									_zuSl39H["blur"]:Destroy()
								end)
								_zuSl39H["blur"] = ({})[1]
							end
							local _xz4i7 = Lighting:FindFirstChild("KittyMotionBlur")
							if _xz4i7 then
								pcall(function()
									_xz4i7:Destroy()
								end)
							end
						end
					end
				else
					(function()
						return (bit32 and 1501050037 or 0x829d)
					end)()
				end
				local function _cny6G(_XtHra)
					local _CisN0 = Lighting:FindFirstChildOfClass("Atmosphere")
					if _XtHra then
						if not _CisN0 then
							_CisN0 = Instance["new"]("Atmosphere")
							if 65535 == 0xffff then
								_CisN0["Name"] = "KittyAtmosphere"
							else
								(function()
									return (bit32 and 36587 or 0xda01)
								end)()
							end
							_CisN0["Parent"] = Lighting
						elseif not _LMAzx6P["exists"] then
							if 0 == 0x0 then
								_LMAzx6P["exists"] = true
							else
								(function()
									return (bit32 and 22367 or 0x9169)
								end)()
							end
							_LMAzx6P["Density"] = _CisN0["Density"]
							if 16 == 0x10 then
								_LMAzx6P["Offset"] = _CisN0["Offset"]
							else
								(function()
									return (bit32 and 38419 or 0xf2d8)
								end)()
							end
							_LMAzx6P["Color"] = _CisN0["Color"]
							_LMAzx6P["Decay"] = _CisN0["Decay"]
							if 1 == 0x1 then
								_LMAzx6P["Glare"] = _CisN0["Glare"]
							else
								(function()
									return ((0xabf2 % 0x2 == 0x0) and (bit32 and 22009 or 0x0) or (bit32 and 64443 or 0x0))
								end)()
							end
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_LMAzx6P["Haze"] = _CisN0["Haze"]
							else
								(function()
									return (bit32 and 1481788867 or 0x245d)
								end)()
							end
						end
						if 65535 == 0xffff then
							_CisN0["Density"] = HubSettings["Visuals"]["Atmosphere"]["Density"]
						else
							(function()
								return ((0x3325 % 0x2 == 0x0) and (bit32 and 6546 or 0x0) or (bit32 and 62115 or 0x0))
							end)()
						end
						_CisN0["Color"] = HubSettings["Visuals"]["Atmosphere"]["Color"]
						if 65535 == 0xffff then
							_CisN0["Decay"] = HubSettings["Visuals"]["Atmosphere"]["Decay"]
						else
							(function()
								return (bit32 and 808212750 or 0xd1af)
							end)()
						end
						_CisN0["Glare"] = HubSettings["Visuals"]["Atmosphere"]["Glare"]
						_CisN0["Haze"] = HubSettings["Visuals"]["Atmosphere"]["Haze"]
					else
						if _CisN0 then
							if _LMAzx6P["exists"] then
								_CisN0["Density"] = _LMAzx6P["Density"]
								_CisN0["Offset"] = _LMAzx6P["Offset"]
								if 129 == 0x81 then
									_CisN0["Color"] = _LMAzx6P["Color"]
								else
									(function()
										return (bit32 and (10273 * 0x3d % 0x10000) or 0x4b3a)
									end)()
								end
								_CisN0["Decay"] = _LMAzx6P["Decay"]
								_CisN0["Glare"] = _LMAzx6P["Glare"]
								_CisN0["Haze"] = _LMAzx6P["Haze"]
							elseif _CisN0["Name"] == "KittyAtmosphere" then
								pcall(function()
									_CisN0:Destroy()
								end)
							end
						end
					end
				end
				local _liq5P = { ["touched"] = {}, ["created"] = {} }
				_liq5P["presets"] = {
					["Clear Day"] = {
						["clock"] = 13,
						["bright"] = 3,
						["amb"] = Color3["fromRGB"](110, (0x2 * 55 - 0), (0 + 0x2 * 55)),
						["out"] = Color3["fromRGB"]((64 + 64), 128, 128),
						["atmos"] = {
							((0x2 * 125 - 0) / 0x3e8),
							Color3["fromRGB"](199, (103 + 96), 199),
							Color3["fromRGB"](106, 112, (1 + 0x2 * 62)),
							0,
							0,
						},
						["stars"] = 3000,
					},
					["Sunrise"] = {
						["clock"] = (6400 / 0x3e8),
						["bright"] = 2,
						["amb"] = Color3["fromRGB"]((55 + 55), 90, 80),
						["out"] = Color3["fromRGB"](150, (0x2 * 60 - 0), 100),
						["atmos"] = {
							((175 + 175) / 0x3e8),
							Color3["fromRGB"](255, 190, 150),
							Color3["fromRGB"](255, (0x2 * 65 - 0), 90),
							(400 / 0x3e8),
							(1200 / 0x3e8),
						},
						["stars"] = 1000,
						["tint"] = Color3["fromRGB"](255, 245, (3 + 0x2 * 116)),
					},
					["Sunset"] = {
						["clock"] = ((0x2 * 8900 - 0) / 0x3e8),
						["bright"] = 2,
						["amb"] = Color3["fromRGB"](120, 85, 70),
						["out"] = Color3["fromRGB"](160, (55 + 55), (0 + 0x2 * 45)),
						["atmos"] = {
							((0x2 * 175 - 0) / 0x3e8),
							Color3["fromRGB"](255, (0x2 * 85 - 0), (60 + 60)),
							Color3["fromRGB"](200, 90, 60),
							(600 / 0x3e8),
							((0 + 0x2 * 800) / 0x3e8),
						},
						["stars"] = (0 + 0x2 * 500),
						["tint"] = Color3["fromRGB"](255, 240, (0x2 * 113 - 1)),
					},
					["Night"] = {
						["clock"] = 0,
						["bright"] = 1,
						["amb"] = Color3["fromRGB"](40, (23 + 22), (0x2 * 35 - 0)),
						["out"] = Color3["fromRGB"]((30 + 30), 65, (0 + 0x2 * 50)),
						["atmos"] = {
							((125 + 125) / 0x3e8),
							Color3["fromRGB"]((0x2 * 35 - 0), 80, (0 + 0x2 * 65)),
							Color3["fromRGB"]((0 + 0x2 * 10), 25, (0 + 0x2 * 25)),
							0,
							((0 + 0x2 * 250) / 0x3e8),
						},
						["stars"] = 5000,
					},
					["Purple Night"] = {
						["clock"] = (15 + 8),
						["bright"] = (1 + 0x2 * 0),
						["amb"] = Color3["fromRGB"](70, (25 + 25), 110),
						["out"] = Color3["fromRGB"]((0 + 0x2 * 50), 70, (75 + 75)),
						["atmos"] = {
							((0x2 * 150 - 0) / 0x3e8),
							Color3["fromRGB"](150, 110, 255),
							Color3["fromRGB"]((0x2 * 30 - 0), (15 + 15), (0 + 0x2 * 60)),
							((150 + 150) / 0x3e8),
							((400 + 400) / 0x3e8),
						},
						["stars"] = 4000,
						["tint"] = Color3["fromRGB"](240, 225, (255 + 0)),
					},
					["Blood Moon"] = {
						["clock"] = (500 / 0x3e8),
						["bright"] = 1,
						["amb"] = Color3["fromRGB"]((45 + 45), 30, 30),
						["out"] = Color3["fromRGB"](130, (0x2 * 20 - 0), 40),
						["atmos"] = {
							(350 / 0x3e8),
							Color3["fromRGB"]((0x2 * 90 - 0), (0x2 * 20 - 0), (0 + 0x2 * 20)),
							Color3["fromRGB"]((45 + 45), (5 + 5), 10),
							(200 / 0x3e8),
							(1 + 0x2 * 0),
						},
						["stars"] = (0x2 * 750 - 0),
						["tint"] = Color3["fromRGB"]((255 + 0), 200, 200),
					},
					["Aurora"] = {
						["clock"] = (0 + 0x2 * 11),
						["bright"] = ((0x2 * 600 - 0) / 0x3e8),
						["amb"] = Color3["fromRGB"]((20 + 20), 80, 80),
						["out"] = Color3["fromRGB"](60, (0x2 * 60 - 0), 110),
						["atmos"] = {
							(300 / 0x3e8),
							Color3["fromRGB"](90, 255, 200),
							Color3["fromRGB"]((0 + 0x2 * 20), 90, 160),
							((0 + 0x2 * 200) / 0x3e8),
							((0x2 * 400 - 0) / 0x3e8),
						},
						["stars"] = 5000,
						["tint"] = Color3["fromRGB"]((113 + 112), (255 + 0), (1 + 0x2 * 122)),
					},
					["Foggy"] = {
						["clock"] = 9,
						["bright"] = (1500 / 0x3e8),
						["amb"] = Color3["fromRGB"](120, 120, (1 + 0x2 * 62)),
						["out"] = Color3["fromRGB"](140, (0 + 0x2 * 70), 145),
						["atmos"] = {
							(600 / 0x3e8),
							Color3["fromRGB"]((0x2 * 100 - 0), (0x2 * 100 - 0), (1 + 0x2 * 102)),
							Color3["fromRGB"]((0 + 0x2 * 80), 160, (85 + 85)),
							0,
							(3 + 0),
						},
						["stars"] = 0,
					},
				}
				_liq5P["order"] =
					{ "Clear Day", "Sunrise", "Sunset", "Night", "Purple Night", "Blood Moon", "Aurora", "Foggy", "Custom Skybox" }
				_liq5P["locking"] = false
				_liq5P["set"] = function(_QFgvu, _XcSkn, _C23ux)
					if not _QFgvu then
						return
					end
					local _lXqWY = _liq5P["touched"][_QFgvu]
					if not _lXqWY then
						_lXqWY = {}
						_liq5P["touched"][_QFgvu] = _lXqWY
					end
					if _lXqWY[_XcSkn] == ({})[1] then
						pcall(function()
							_lXqWY[_XcSkn] = _QFgvu[_XcSkn]
						end)
					end
					pcall(function()
						_QFgvu[_XcSkn] = _C23ux
					end)
				end
				_liq5P["restore"] = function()
					for _kypWA, _LHoJo in pairs(_liq5P["touched"]) do
						for _GkyaU, _s3IEw in pairs(_LHoJo) do
							pcall(function()
								_kypWA[_GkyaU] = _s3IEw
							end)
						end
					end
					table["clear"](_liq5P["touched"])
					for _L3aVK, _mDk7i in ipairs(_liq5P["created"]) do
						pcall(function()
							_mDk7i:Destroy()
						end)
					end
					table["clear"](_liq5P["created"])
				end
				_liq5P["child"] = function(_llFKk, _Ex8dl)
					local _XqtNO = Lighting:FindFirstChild(_Ex8dl) or Lighting:FindFirstChildOfClass(_llFKk)
					if not _XqtNO then
						_XqtNO = Instance["new"](_llFKk)
						_XqtNO["Name"] = _Ex8dl
						_XqtNO["Parent"] = Lighting
						table["insert"](_liq5P["created"], _XqtNO)
					end
					return _XqtNO
				end
				_liq5P["apply"] = function(_Swcu8)
					if not _Swcu8 then
						_liq5P["restore"]()
					end
					local _l5Lqk = HubSettings["Visuals"]["Sky"]
					if not _l5Lqk["Enabled"] then
						return
					end
					local _EsoH2 = _liq5P["child"]("Sky", "KittySky")
					_liq5P["set"](_EsoH2, "StarCount", _l5Lqk["Stars"])
					_liq5P["set"](_EsoH2, "CelestialBodiesShown", true)
					local _XH2_t = _liq5P["presets"][_l5Lqk["Preset"]]
					if _XH2_t then
						_liq5P["set"](Lighting, "ClockTime", _XH2_t["clock"])
						_liq5P["set"](Lighting, "Brightness", _XH2_t["bright"])
						_liq5P["set"](Lighting, "Ambient", _XH2_t["amb"])
						_liq5P["set"](Lighting, "OutdoorAmbient", _XH2_t["out"])
						local _enyA4 = _liq5P["child"]("Atmosphere", "KittySkyAtmosphere")
						_liq5P["set"](_enyA4, "Density", _XH2_t["atmos"][1])
						_liq5P["set"](_enyA4, "Color", _XH2_t["atmos"][2])
						_liq5P["set"](_enyA4, "Decay", _XH2_t["atmos"][(3 + 0)])
						_liq5P["set"](_enyA4, "Glare", _XH2_t["atmos"][(2 + 2)])
						_liq5P["set"](_enyA4, "Haze", _XH2_t["atmos"][(0x2 * 3 - 1)])
						if not _uMouq or not _uMouq["Parent"] then
							_uMouq = Lighting:FindFirstChild("ColorCorrection")
								or Instance["new"]("ColorCorrectionEffect", Lighting)
						end
						_liq5P["set"](_uMouq, "TintColor", _XH2_t["tint"] or Color3["new"](1, 1, 1))
					elseif _l5Lqk["Preset"] == "Custom Skybox" then
						local _xzlr7 = tostring(_l5Lqk["SkyboxId"]):match("%d+")
						if _xzlr7 then
							for _QAqUU, _DAwv3 in ipairs({ "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }) do
								_liq5P["set"](_EsoH2, _DAwv3, "rbxassetid://" .. _xzlr7)
							end
						end
					end
				end
				local _e71S9 = {}
				_e71S9["part"] = function(_xiUK7)
					local _wtMka = HubSettings["AutoTech"]["TargetPart"]
					local _P6Wmd = _xiUK7 and _xiUK7["Parent"]
					if _P6Wmd and (_wtMka == "Head" or _wtMka == "Torso") then
						local _qBWv4 = _P6Wmd:FindFirstChild(_wtMka) or (_wtMka == "Torso" and _P6Wmd:FindFirstChild("UpperTorso"))
						if _qBWv4 then
							return _qBWv4
						end
					end
					return _xiUK7
				end
				_e71S9["pos"] = function(_dpk6v)
					local _wKtC5 = _e71S9["part"](_dpk6v)
					return _wKtC5 and _wKtC5["Position"] or Vector3["zero"]
				end
				local function _PmMg3(_WG0jYGC_, _prUL0, _IdOVnO, _btwedRR, _WpfDds2D)
					local _pIlr_
					_pIlr_ = RunService[_WG0jYGC_]:Connect(function()
						if
							not _IdOVnO
							or _IdOVnO:FindFirstChild("BeingLaunched")
							or not _IdOVnO:FindFirstChild("Ragdoll")
							or _btwedRR["Health"] <= 0
							or _y4IB9["Health"] <= 0
							or not _xFaaK(_j089A["frontDash"])
						then
							_mzv8k = false
							_vA5WJ(_pIlr_)
							return
						end
						_WpfDds2D()
					end)
					task["wait"](_prUL0)
					if 129 == 0x81 then
						_vA5WJ(_pIlr_)
					else
						(function()
							return (bit32 and 25105 or 0xb270)
						end)()
					end
					_mzv8k = false
				end
				local function _suUadl(_tA1yg8R)
					_mzv8k = true
					_XjK2G()
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						task["wait"](_p44Zr(1000) + ((0 + 0x2 * 25) / 0x3e8) + (_tA1yg8R or 0))
					else
						(function()
							return (bit32 and 60100508 or 0xfc2f)
						end)()
					end
				end
				local function _SrHidRlg(_zcygD, _H3u0O, _ulpybJ)
					local _ZCc4leT
					_suUadl()
					if 0 == 0x0 then
						_RnQ1A5M((0 + 0x2 * 45), ({})[1], true)
					else
						(function()
							return (bit32 and 21958 or 0xb455)
						end)()
					end
					if 1 == 0x1 then
						_gMeqn(270, (300 / 0x3e8), true)
					else
						(function()
							return (bit32 and 63899 or 0xb112)
						end)()
					end
					task["wait"](((0 + 0x2 * 150) / 0x3e8))
					if 0 == 0x0 then
						_PmMg3("Heartbeat", ((200 + 200) / 0x3e8), _zcygD, _ulpybJ, function()
							if _ZCc4leT or _kk1_Z(_e71S9["part"](_H3u0O)) then
								if not _ZCc4leT then
									if HubSettings["AutoTech"]["LoopDashLooksUp"] then
										_ZCc4leT = CFrame["lookAt"](
											_fx2la["Position"],
											Vector3["new"](
												_fx2la["Position"]["X"] + (1500 / 0x3e8),
												_fx2la["Position"]["Y"] + ((0 + 0x2 * 750) / 0x3e8),
												_fx2la["Position"]["Z"]
											)
										)
									else
										_ZCc4leT = _fx2la["CFrame"]
									end
								end
								_Z0Hry:PivotTo(_ZCc4leT)
							else
								_RnQ1A5M(({})[1], _e71S9["pos"](_H3u0O), true)
							end
						end)
					else
						(function()
							return (bit32 and 48591 or 0xf5df)
						end)()
					end
				end
				local function _Q3OwZ(_DLDcJ, _aH8Po, _l8MHn)
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if not (_fx2la and _y4IB9) then
							return
						end
					else
						(function()
							return (bit32 and 47327 or 0xb489)
						end)()
					end
					local _YFRRM = { ({})[1], false, HubSettings["AutoTech"]["Customdash"]["RotateCam"] }
					local _vAazx = {
						({})[1],
						_e71S9["pos"](_aH8Po),
						false,
						_YFRRM[3],
						HubSettings["AutoTech"]["Customdash"]["LockOnPrecision"],
					}
					if HubSettings["AutoTech"]["Customdash"]["Jump"] then
						_fx2la["AssemblyLinearVelocity"] =
							Vector3["new"](_fx2la["AssemblyLinearVelocity"]["X"], (25 + 25), _fx2la["AssemblyLinearVelocity"]["Z"])
					end
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_mzv8k = true
					else
						(function()
							return (bit32 and 17098 or 0xa342)
						end)()
					end
					_RnQ1A5M(HubSettings["AutoTech"]["Customdash"]["StartFlickAngle"], EnvAccess["unpack"](_YFRRM))
					_suUadl(HubSettings["AutoTech"]["Customdash"]["SecondFlickDelay"])
					if 129 == 0x81 then
						_RnQ1A5M(HubSettings["AutoTech"]["Customdash"]["SecondFlickAngle"], EnvAccess["unpack"](_YFRRM))
					else
						(function()
							return (bit32 and (64626 * 0x3d % 0x10000) or 0xf9ea)
						end)()
					end
					if 129 == 0x81 then
						if
							HubSettings["AutoTech"]["Customdash"]["LockOn"]
							and HubSettings["AutoTech"]["Customdash"]["LockOnAfter"] == "Second Flick"
						then
							task["wait"](HubSettings["AutoTech"]["Customdash"]["LockOnDelay"])
							_PmMg3("Heartbeat", ((0 + 0x2 * 200) / 0x3e8), _DLDcJ, _l8MHn, function()
								_RnQ1A5M(EnvAccess["unpack"](_vAazx))
							end)
						else
							task["wait"](HubSettings["AutoTech"]["Customdash"]["ThirdFlickDelay"])
							_RnQ1A5M(HubSettings["AutoTech"]["Customdash"]["ThirdFlickAngle"], EnvAccess["unpack"](_YFRRM))
							if 0 == 0x0 then
								if
									HubSettings["AutoTech"]["Customdash"]["LockOn"]
									and HubSettings["AutoTech"]["Customdash"]["LockOnAfter"] == "Third Flick"
								then
									task["wait"](HubSettings["AutoTech"]["Customdash"]["LockOnDelay"])
									_PmMg3("Heartbeat", (400 / 0x3e8), _DLDcJ, _l8MHn, function()
										_RnQ1A5M(EnvAccess["unpack"](_vAazx))
									end)
								end
							else
								(function()
									return ((0x7252 % 0x2 == 0x0) and (bit32 and 14633 or 0x0) or (bit32 and 33595 or 0x0))
								end)()
							end
						end
					else
						(function()
							return ((0xcb1a % 0x2 == 0x0) and (bit32 and 25997 or 0x0) or (bit32 and 49665 or 0x0))
						end)()
					end
					_mzv8k = false
					_y4IB9["AutoRotate"] = _XXmEh["AutoRotate"]
				end
				local function _ijYak(_hwqr3, _EgR4S, _rZ2nA)
					if not (_fx2la and _y4IB9) then
						return
					end
					local _uw8yF = {
						({})[1],
						_e71S9["pos"](_EgR4S),
						false,
						HubSettings["AutoTech"]["Customdashv2"]["RotateCam"],
						HubSettings["AutoTech"]["Customdashv2"]["LockOnPrecision"],
					}
					if HubSettings["AutoTech"]["Customdashv2"]["Jump"] then
						_fx2la["AssemblyLinearVelocity"] =
							Vector3["new"](_fx2la["AssemblyLinearVelocity"]["X"], 50, _fx2la["AssemblyLinearVelocity"]["Z"])
					end
					if 129 == 0x81 then
						_mzv8k = true
					else
						(function()
							return (bit32 and 49403 or 0x39c0)
						end)()
					end
					_RnQ1A5M(
						HubSettings["AutoTech"]["Customdashv2"]["StartFlickAngle"],
						({})[1],
						true,
						HubSettings["AutoTech"]["Customdashv2"]["RotateCam"]
					)
					_suUadl(HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDelay"])
					_gMeqn(
						HubSettings["AutoTech"]["Customdashv2"]["SecondFlickAngle"],
						HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDuration"],
						not HubSettings["AutoTech"]["Customdashv2"]["RotateCam"]
					)
					if 0 == 0x0 then
						if
							HubSettings["AutoTech"]["Customdashv2"]["LockOn"]
							and HubSettings["AutoTech"]["Customdashv2"]["LockOnAfter"] == "Second Flick"
						then
							if 0 == 0x0 then
								task["wait"](HubSettings["AutoTech"]["Customdashv2"]["LockOnDelay"])
							else
								(function()
									return ((0x3cb6 % 0x2 == 0x0) and (bit32 and 7771 or 0x0) or (bit32 and 47829 or 0x0))
								end)()
							end
							_PmMg3("Heartbeat", (400 / 0x3e8), _hwqr3, _rZ2nA, function()
								_RnQ1A5M(EnvAccess["unpack"](_uw8yF))
							end)
						else
							task["wait"](HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDelay"])
							_gMeqn(
								HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickAngle"],
								HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDuration"],
								not HubSettings["AutoTech"]["Customdashv2"]["RotateCam"]
							)
							if
								HubSettings["AutoTech"]["Customdashv2"]["LockOn"]
								and HubSettings["AutoTech"]["Customdashv2"]["LockOnAfter"] == "Third Flick"
							then
								task["wait"](HubSettings["AutoTech"]["Customdashv2"]["LockOnDelay"])
								_PmMg3("Heartbeat", (400 / 0x3e8), _hwqr3, _rZ2nA, function()
									_RnQ1A5M(EnvAccess["unpack"](_uw8yF))
								end)
							end
						end
					else
						(function()
							return (bit32 and 36711 or 0x738f)
						end)()
					end
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if not _R5B57 then
							_mzv8k = false
							_y4IB9["AutoRotate"] = _XXmEh["AutoRotate"]
						end
					else
						(function()
							return (bit32 and 635641066 or 0xb9b4)
						end)()
					end
				end
				local function _ZlTUv(_M55OE, _D_EDy, _qpoME)
					if 16 == 0x10 then
						if HubSettings["AutoTech"]["Loopv2"]["Jump"] then
							_fx2la["AssemblyLinearVelocity"] =
								Vector3["new"](_fx2la["AssemblyLinearVelocity"]["X"], 50, _fx2la["AssemblyLinearVelocity"]["Z"])
						end
					else
						(function()
							return (bit32 and (55620 * 0x3d % 0x10000) or 0xd90a)
						end)()
					end
					_mzv8k = true
					if 16 == 0x10 then
						_RnQ1A5M(
							HubSettings["AutoTech"]["Loopv2"]["FirstFlickAngle"],
							({})[1],
							true,
							HubSettings["AutoTech"]["Loopv2"]["RotateCam"]
						)
					else
						(function()
							return (bit32 and 56007 or 0xeda)
						end)()
					end
					_suUadl(HubSettings["AutoTech"]["Loopv2"]["SecondFlick"])
					_PmMg3("Heartbeat", ((0x2 * 200 - 0) / 0x3e8), _M55OE, _qpoME, function()
						_RnQ1A5M(
							({})[1],
							_e71S9["pos"](_D_EDy),
							true,
							HubSettings["AutoTech"]["Loopv2"]["RotateCam"],
							({})[1],
							HubSettings["AutoTech"]["Loopv2"]["Precision"]
						)
					end)
					_mzv8k = false
					_y4IB9["AutoRotate"] = _XXmEh["AutoRotate"]
				end
				local function _VBJJ9(_YfQ8U, _Lw3JZ, _iBZPy)
					_suUadl()
					_PmMg3("Heartbeat", ((0x2 * 350 - 0) / 0x3e8), _YfQ8U, _iBZPy, function()
						_RnQ1A5M(({})[1], _e71S9["pos"](_Lw3JZ), true, false, HubSettings["AutoTech"]["LockonPrecision"])
					end)
				end
				local function _hkJ5P(_UQKak, _r4idu, _ezZjK)
					_suUadl()
					if 0 == 0x0 then
						_PmMg3("Heartbeat", (400 / 0x3e8), _UQKak, _ezZjK, function()
							local _HXyed = _e71S9["pos"](_r4idu)
							local _kd_Sf = _HXyed - Vector3["new"](0, (0x2 * 3 - 3), 2)
							local _xinWO = CFrame["new"](_kd_Sf, _HXyed)
							_Z0Hry:PivotTo(_xinWO)
						end)
					else
						(function()
							return (bit32 and 5327 or 0x16e5)
						end)()
					end
				end
				local function _GZ1a7(_b7Suz, _oqVmt, _mBh_7)
					_suUadl(math.clamp(_p44Zr(1000) * 0.5, 0, 0.15))
					local _xE61o = _oqVmt["CFrame"]:PointToObjectSpace(_fx2la["Position"])
					_PmMg3(HubSettings["AutoTech"]["SupaMethod"], ((0 + 0x2 * 150) / 0x3e8), _b7Suz, _mBh_7, function()
						local _U_fen = _e71S9["pos"](_oqVmt)
						local _bvQMW = _oqVmt["CFrame"]:PointToWorldSpace(_xE61o)
						_Z0Hry:PivotTo(
							CFrame["lookAt"](
								_bvQMW,
								Vector3["new"](_U_fen["X"], _bvQMW["Y"] + (1500 / 0x3e8), _U_fen["Z"]),
								Vector3["new"](0, (1 + 0x2 * 0), 0)
							)
						)
					end)
				end
				local _q46lU = { ["busy"] = false, ["armedUntil"] = 0, ["highlight"] = ({})[1] }
				if 0 == 0x0 then
					_q46lU["getTarget"] = function(_R3eS1)
						local _Ia0J6, _TTP74 = ({})[1], _R3eS1
						for _ywPqv, _JqqbM in ipairs(_f5mDQ["Live"]:GetChildren()) do
							if
								_JqqbM ~= _Z0Hry
								and _JqqbM:IsA("Model")
								and not _JrRW2(PlayersService:GetPlayerFromCharacter(_JqqbM), true)
							then
								local _MI4Qi = _JqqbM:FindFirstChild("HumanoidRootPart")
								local _nhPx3 = _JqqbM:FindFirstChildOfClass("Humanoid")
								if _MI4Qi and _nhPx3 and _nhPx3["Health"] > 0 then
									local _C4L9T = (_MI4Qi["Position"] - _fx2la["Position"])["Magnitude"]
									if _C4L9T < _TTP74 then
										_Ia0J6, _TTP74 = _JqqbM, _C4L9T
									end
								end
							end
						end
						return _Ia0J6
					end
				else
					(function()
						return ((0xabed % 0x2 == 0x0) and (bit32 and 22006 or 0x0) or (bit32 and 62243 or 0x0))
					end)()
				end
				_q46lU["setHighlight"] = function(_xccyh)
					if _q46lU["highlight"] then
						_q46lU["highlight"]:Destroy()
						_q46lU["highlight"] = ({})[1]
					end
					if not (_xccyh and HubSettings["AutoLethal"]["Highlight"]) then
						return
					end
					local _UXktE = Instance["new"]("Highlight")
					_UXktE["Name"] = "KWLethalTarget"
					_UXktE["FillColor"] = HubSettings["AutoLethal"]["HighlightColor"]
					_UXktE["OutlineColor"] = HubSettings["AutoLethal"]["HighlightColor"]
					_UXktE["FillTransparency"] = (500 / 0x3e8)
					_UXktE["OutlineTransparency"] = 0
					_UXktE["DepthMode"] = Enum["HighlightDepthMode"]["AlwaysOnTop"]
					_UXktE["Adornee"] = _xccyh
					_UXktE["Parent"] = _xccyh
					_q46lU["highlight"] = _UXktE
				end
				local function _fFkGm(_qXVklc)
					if not _qXVklc then
						return
					end
					local _BBlLc = _qXVklc["AssemblyLinearVelocity"]
					if 16 == 0x10 then
						_qXVklc["AssemblyLinearVelocity"] = Vector3["new"](_BBlLc["X"], (0 + 0x2 * 25), _BBlLc["Z"])
					else
						(function()
							return (bit32 and 6659 or 0x31a)
						end)()
					end
				end
				if 129 == 0x81 then
					_q46lU["jump"] = function()
						local _Ysjrtm4e = _fx2la
						if not _Ysjrtm4e then
							return
						end
						_fFkGm(_Ysjrtm4e)
						local _TSqan2N = 0
						local _ijM4VXTw
						_ijM4VXTw = RunService["Heartbeat"]:Connect(function()
							_TSqan2N = _TSqan2N + (1 + 0)
							if _TSqan2N > 3 or not _Ysjrtm4e["Parent"] then
								_ijM4VXTw:Disconnect()
								return
							end
							if _Ysjrtm4e["AssemblyLinearVelocity"]["Y"] < (3 + 0x2 * 16) then
								_fFkGm(_Ysjrtm4e)
							end
						end)
					end
				else
					(function()
						return ((0x3edf % 0x2 == 0x0) and (bit32 and 8047 or 0x0) or (bit32 and 43643 or 0x0))
					end)()
				end
				_q46lU["run"] = function(_Jqs3Z)
					local _M6A_1r0Z = HubSettings["AutoLethal"]
					local _dghr31A = _Jqs3Z:FindFirstChild("HumanoidRootPart")
					local _yGKzvt = _Jqs3Z:FindFirstChildOfClass("Humanoid")
					if not (_dghr31A and _yGKzvt) then
						return
					end
					_q46lU["setHighlight"](_Jqs3Z)
					local _nPjQk = tick()
					repeat
						RunService["Heartbeat"]:Wait()
					until not (_Z0Hry and _Z0Hry:FindFirstChildOfClass("ForceField"))
						or tick() - _nPjQk >= ((0x2 * 1250 - 0) / 0x3e8)
					task["wait"]((100 / 0x3e8))
					if not _y4IB9 or _y4IB9["Health"] <= 0 or _yGKzvt["Health"] <= 0 then
						return
					end
					if _M6A_1r0Z["Jump"] then
						_q46lU["jump"]()
					end
					_mzv8k = true
					_RnQ1A5M(_M6A_1r0Z["FirstFlickAngle"], ({})[1], true, _M6A_1r0Z["RotateCam"])
					local _wJtcAH = _tew4S()
					if _wJtcAH then
						_wJtcAH:FireServer(_Ws0Y9["frontDash"])
					end
					_dcE27["frontDashAt"] = tick()
					_ecSEyI = true
					task["delay"]((0x2 * 3 - 1), function()
						_ecSEyI = false
					end)
					task["wait"](_p44Zr(1000) + ((25 + 25) / 0x3e8) + _M6A_1r0Z["SecondFlick"])
					local _V6F0ttU = tick()
					local _Gjjw242g
					_Gjjw242g = RunService["Heartbeat"]:Connect(function()
						local _zjlcE = tick() - _V6F0ttU
						if
							_zjlcE > (400 / 0x3e8)
							or (_zjlcE > ((0 + 0x2 * 100) / 0x3e8) and not _xFaaK(_j089A["frontDash"]))
							or not _dghr31A["Parent"]
							or _yGKzvt["Health"] <= 0
							or _y4IB9["Health"] <= 0
						then
							_Gjjw242g:Disconnect()
							return
						end
						_RnQ1A5M(({})[1], _e71S9["pos"](_dghr31A), true, _M6A_1r0Z["RotateCam"], _M6A_1r0Z["Precision"])
					end)
					task["wait"]((400 / 0x3e8))
					if _Gjjw242g["Connected"] then
						_Gjjw242g:Disconnect()
					end
				end
				_q46lU["trigger"] = function(_chbg2)
					if _q46lU["busy"] then
						return
					end
					_q46lU["busy"] = true
					local _RL2_W, _VT49w = pcall(_q46lU["run"], _chbg2)
					if not _RL2_W then
						EnvAccess["warn"]("[KittyWare] Auto Lethal error: " .. tostring(_VT49w))
					end
					_mzv8k = false
					if _y4IB9 then
						_y4IB9["AutoRotate"] = _XXmEh["AutoRotate"]
					end
					_q46lU["setHighlight"](({})[1])
					task["wait"]((300 / 0x3e8))
					_q46lU["busy"] = false
				end
				_q46lU["onAnim"] = function(_Inde5)
					if _R5B57 then
						return
					end
					local _j9H9P = HubSettings["AutoLethal"]
					local _aQifz = _Inde5["Animation"] and _Inde5["Animation"]["AnimationId"]:match("%d+")
					if _aQifz ~= _j9H9P["HitAnim"] or _q46lU["busy"] then
						return
					end
					if not (_j9H9P["Enabled"] or tick() < _q46lU["armedUntil"]) then
						return
					end
					_q46lU["armedUntil"] = 0
					local _RdJuE = _q46lU["getTarget"]((0x2 * 10 - 0))
					if _RdJuE then
						task["spawn"](_q46lU["trigger"], _RdJuE)
					end
				end
				_q46lU["elapsed"] = function()
					if not _zE8Ni then
						return ({})[1]
					end
					for _oX8aD, _vWYUX in ipairs(_zE8Ni:GetPlayingAnimationTracks()) do
						local _ibJXz = _vWYUX["Animation"] and _vWYUX["Animation"]["AnimationId"]:match("%d+")
						if _ibJXz == HubSettings["AutoLethal"]["HitAnim"] then
							return _vWYUX["TimePosition"]
						end
					end
					return ({})[1]
				end
				if 129 == 0x81 then
					_q46lU["fire"] = function()
						_q46lU["armedUntil"] = tick() + 3
						_u3Jke(Enum["KeyCode"]["Two"])
					end
				else
					(function()
						return (bit32 and 60018 or 0x68fc)
					end)()
				end
				local _J7mp6 = {}
				if 65535 == 0xffff then
					_J7mp6["set"] = function(_wNqfv)
						local _rS77O = _Z0Hry and _Z0Hry:FindFirstChild("Head")
						if not _rS77O then
							return
						end
						if _rS77O["Transparency"] ~= _wNqfv then
							_IeaiYt2E(_rS77O, "Transparency", _wNqfv)
						end
						local _ONC9Q = _rS77O:FindFirstChild("face")
						if _ONC9Q and _ONC9Q["Transparency"] ~= _wNqfv then
							_IeaiYt2E(_ONC9Q, "Transparency", _wNqfv)
						end
					end
				else
					(function()
						return (bit32 and 28205 or 0x6e45)
					end)()
				end
				_J7mp6["start"] = function()
					if _lH0uIxY["headless"] then
						return
					end
					_lH0uIxY["headless"] = _l3G1i(RunService["RenderStepped"], function()
						_J7mp6["set"](1)
					end)
				end
				_J7mp6["stop"] = function()
					if _lH0uIxY["headless"] then
						_vA5WJ(_lH0uIxY["headless"])
						_lH0uIxY["headless"] = ({})[1]
					end
				end
				local _FUndW
				local function _IxbzG(_jP5Av, _WrWCM, _RHCrj, _EYp3y)
					if not (_jP5Av and _jP5Av:IsA("Model") and _jP5Av ~= _Z0Hry and _jP5Av["Parent"]) then
						return _RHCrj, _EYp3y
					end
					local _f6ySU = _jP5Av:FindFirstChild("HumanoidRootPart")
					local _isEcy = _jP5Av:FindFirstChildOfClass("Humanoid")
					if not (_f6ySU and _isEcy and _isEcy["Health"] > 0) then
						return _RHCrj, _EYp3y
					end
					local _Xb4I8 = PlayersService:GetPlayerFromCharacter(_jP5Av)
					if _Xb4I8 and HubSettings["Misc"]["FriendCheck"] and _JrRW2(_Xb4I8, false) then
						return _RHCrj, _EYp3y
					end
					local _AvwdD = (_WrWCM - _f6ySU["Position"])["Magnitude"]
					if _AvwdD < _EYp3y then
						return _jP5Av, _AvwdD
					end
					return _RHCrj, _EYp3y
				end
				local function _F7i6M(_S2VSW)
					_S2VSW = _S2VSW or (8 + 8)
					if not (_Z0Hry and _fx2la) then
						return ({})[1]
					end
					local _rtVk4 = _fx2la["Position"]
					local _EKbuK = _Z0Hry:GetAttribute("LastM1Hitted")
					local _x0LUh = EnvAccess["type"](_EKbuK) == "string" and _EKbuK:match("^(.-);;")
					local _aSpa5 = ({})[1]
					local _jQ5QH = _S2VSW
					local _sG1wu = { _f5mDQ["Live"], workspace, _f5mDQ["Map"] }
					for _RPNkj, _e6AGz in ipairs(workspace:GetChildren()) do
						if
							(_e6AGz:IsA("Folder") or _e6AGz:IsA("Model"))
							and _e6AGz ~= _Z0Hry
							and _e6AGz ~= _f5mDQ["Live"]
							and _e6AGz ~= _f5mDQ["Map"]
						then
							local _YSidA = _e6AGz["Name"]:lower()
							if 1 == 0x1 then
								if
									_YSidA:find("dummy")
									or _YSidA:find("npc")
									or _YSidA:find("bot")
									or _YSidA:find("live")
									or _YSidA:find("character")
								then
									if 0 == 0x0 then
										table["insert"](_sG1wu, _e6AGz)
									else
										(function()
											return (bit32 and 77649574 or 0x7e42)
										end)()
									end
								end
							else
								(function()
									return (bit32 and 1464804634 or 0xa1d0)
								end)()
							end
						end
					end
					if 16 == 0x10 then
						if _x0LUh then
							for _jafmP, _KvpjG in ipairs(_sG1wu) do
								if _KvpjG then
									for _Ra5fU, _c5asy in ipairs(_KvpjG:GetChildren()) do
										if _c5asy["Name"] == _x0LUh then
											_aSpa5, _jQ5QH = _IxbzG(_c5asy, _rtVk4, _aSpa5, _jQ5QH)
										end
									end
								end
							end
							if _aSpa5 then
								return _aSpa5
							end
						end
					else
						(function()
							return (bit32 and 347579568 or 0x8c03)
						end)()
					end
					for _DBY3i, _yIO6a in ipairs(_sG1wu) do
						if 1 == 0x1 then
							if _yIO6a then
								if 16 == 0x10 then
									for _JPFZq, _kfMko in ipairs(_yIO6a:GetChildren()) do
										_aSpa5, _jQ5QH = _IxbzG(_kfMko, _rtVk4, _aSpa5, _jQ5QH)
									end
								else
									(function()
										return (bit32 and 57325 or 0xdfe8)
									end)()
								end
							end
						else
							(function()
								return ((0x72aa % 0x2 == 0x0) and (bit32 and 14677 or 0x0) or (bit32 and 30005 or 0x0))
							end)()
						end
					end
					for _vX0pQ, _C7KmU in ipairs(PlayersService:GetPlayers()) do
						if _C7KmU ~= HubLocalPlayer and _C7KmU["Character"] then
							_aSpa5, _jQ5QH = _IxbzG(_C7KmU["Character"], _rtVk4, _aSpa5, _jQ5QH)
						end
					end
					return _aSpa5
				end
				local function _dXK4f()
					if _LZYNd then
						pcall(_LZYNd)
					end
					_FPbWqU0 = false
					_mzv8k = false
					_ecSEyI = false
					_KjGi0a["stop"]()
					table["clear"](_vjMDS)
					if 0 == 0x0 then
						if _NSADL["highlight"] then
							pcall(function()
								_NSADL["highlight"]:Destroy()
							end)
							_NSADL["highlight"] = ({})[1]
						end
					else
						(function()
							return (bit32 and 65343 or 0xf8ff)
						end)()
					end
					if 0 == 0x0 then
						if _NSADL["headMask"] then
							if 1 == 0x1 then
								pcall(function()
									_NSADL["headMask"]:Destroy()
								end)
							else
								(function()
									return (bit32 and 38655 or 0x3cf6)
								end)()
							end
							_NSADL["headMask"] = ({})[1]
						end
					else
						(function()
							return (bit32 and (7788 * 0x3d % 0x10000) or 0x1f90)
						end)()
					end
					table["clear"](_NSADL["mats"])
					if _q46lU and _q46lU["setHighlight"] then
						_q46lU["setHighlight"](({})[1])
						_q46lU["busy"] = false
					end
					if 0 == 0x0 then
						if HubSettings["Visuals"]["Sky"]["Enabled"] then
							task["spawn"](function()
								_liq5P["apply"](true)
								task["wait"]((250 / 0x3e8))
								if HubSettings["Visuals"]["Sky"]["Enabled"] then
									_liq5P["apply"](true)
								end
							end)
						end
					else
						(function()
							return (bit32 and 209541183 or 0x14dd)
						end)()
					end
					if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
						if 1 == 0x1 then
							task["spawn"](function()
								_cny6G(true)
								task["wait"](((125 + 125) / 0x3e8))
								if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
									_cny6G(true)
								end
							end)
						else
							(function()
								return (bit32 and 28172 or 0x566e)
							end)()
						end
					end
				end
				local function _oP95qX7E(_jzGzHNO)
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if not _jzGzHNO then
							return
						end
					else
						(function()
							return ((0x985b % 0x2 == 0x0) and (bit32 and 19501 or 0x0) or (bit32 and 26338 or 0x0))
						end)()
					end
					_Z0Hry = _jzGzHNO
					if 129 == 0x81 then
						_FPbWqU0 = false
					else
						(function()
							return (bit32 and 60813 or 0x2c8d)
						end)()
					end
					_mzv8k = false
					_ecSEyI = false
					_KjGi0a["stop"]()
					table["clear"](_vjMDS)
					if _NSADL["highlight"] then
						pcall(function()
							_NSADL["highlight"]:Destroy()
						end)
						_NSADL["highlight"] = ({})[1]
					end
					if _NSADL["headMask"] then
						if 1 == 0x1 then
							pcall(function()
								_NSADL["headMask"]:Destroy()
							end)
						else
							(function()
								return (bit32 and 15166 or 0x313f)
							end)()
						end
						_NSADL["headMask"] = ({})[1]
					end
					table["clear"](_NSADL["mats"])
					_y4IB9 = _jzGzHNO:WaitForChild("Humanoid", 3) or _jzGzHNO:FindFirstChildOfClass("Humanoid")
					_fx2la = _jzGzHNO:WaitForChild("HumanoidRootPart", 3) or (_y4IB9 and _y4IB9["RootPart"])
					_gQE1u = _jzGzHNO:WaitForChild("Head", (3 + 0)) or _jzGzHNO:FindFirstChild("Head")
					_MJSFe = _jzGzHNO:FindFirstChild("Communicate") or _jzGzHNO:WaitForChild("Communicate", (1500 / 0x3e8))
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if _y4IB9 then
							_zE8Ni = _y4IB9:FindFirstChildOfClass("Animator")
								or _y4IB9:WaitForChild("Animator", ((750 + 750) / 0x3e8))
							if not _zE8Ni and _y4IB9["Parent"] then
								pcall(function()
									_zE8Ni = Instance["new"]("Animator")
									_zE8Ni["Parent"] = _y4IB9
								end)
							end
						end
					else
						(function()
							return (bit32 and 58910 or 0x5de6)
						end)()
					end
					_N82Le = _gQE1u and (_gQE1u:FindFirstChild("face") or _gQE1u:WaitForChild("face", ((0 + 0x2 * 250) / 0x3e8)))
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_YxtF_bco = _wZKifJPa[_jzGzHNO:GetAttribute("Character")] or "Other"
					else
						(function()
							return (bit32 and (53733 * 0x3d % 0x10000) or 0xf7ff)
						end)()
					end
					_l3G1i(_jzGzHNO:GetAttributeChangedSignal("Character"), function()
						_YxtF_bco = _wZKifJPa[_jzGzHNO:GetAttribute("Character")] or "Other"
					end)
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						pcall(function()
							_IeaiYt2E(workspace["CurrentCamera"], "FieldOfView", HubSettings["Visuals"]["FOV"])
						end)
					else
						(function()
							return (bit32 and 30892 or 0xbb64)
						end)()
					end
					_XXmEh = {
						["HeadTransparency"] = _gQE1u and _gQE1u["Transparency"] or 0,
						["FaceTransparency"] = _N82Le and _N82Le["Transparency"] or 0,
						["AutoRotate"] = _y4IB9 and _y4IB9["AutoRotate"] or true,
						["JumpPower"] = _y4IB9 and _y4IB9["JumpPower"] or (0x2 * 25 - 0),
					}
					_ElMhN = ({})[1]
					pcall(function()
						if _y4IB9 then
							_ElMhN = _y4IB9:GetAppliedDescription()
						end
					end)
					if 0 == 0x0 then
						if _zE8Ni then
							_l3G1i(_zE8Ni["AnimationPlayed"], _q46lU["onAnim"])
							_l3G1i(_zE8Ni["AnimationPlayed"], function(_KUomvn)
								local _ViZxv = _KUomvn["Animation"]
								if
									_ViZxv
									and (
										_ViZxv["AnimationId"]:find(_j089A["uppercut"])
										or _ViZxv["AnimationId"]:find(_j089A["euppercut"])
									)
								then
									if not HubSettings["AutoTech"]["Enabled"] then
										return
									end
									if not (_Z0Hry and _fx2la and _y4IB9 and _y4IB9["Health"] > 0) then
										return
									end
									local _cNwEk3oQ = _F7i6M(16)
									if not _cNwEk3oQ or _cNwEk3oQ == _Z0Hry then
										return
									end
									local _nZNHzTz = PlayersService:GetPlayerFromCharacter(_cNwEk3oQ)
									local _m3g8as = _cNwEk3oQ:FindFirstChild("HumanoidRootPart")
									local _r7IKc = _cNwEk3oQ:FindFirstChildOfClass("Humanoid")
									if not _m3g8as or not _r7IKc or _r7IKc["Health"] <= 0 then
										return
									end
									if _nZNHzTz and HubSettings["Misc"]["FriendCheck"] and _JrRW2(_nZNHzTz, false) then
										return
									end
									local _gqaLSXNz = (_nZNHzTz == ({})[1])
										or (_cNwEk3oQ["Name"]:lower():find("dummy") ~= ({})[1])
										or (_cNwEk3oQ["Name"]:lower():find("npc") ~= ({})[1])
									local _FOk6nm_ = _nZNHzTz and _JrRW2(_nZNHzTz, false)
									local _yQoVr3 = _r7IKc["Health"]
									local _nHuXh = _m3g8as["Position"]["Y"]
									local _MZuG3 = _Z0Hry:GetAttribute("LastM1Hitted")
									local _B58iB = (_YxtF_bco == "Metal Bat" or _YxtF_bco == "Batter") and ((0 + 0x2 * 270) / 0x3e8)
										or ((0x2 * 190 - 0) / 0x3e8)
									task["wait"](math["max"]((50 / 0x3e8), _B58iB - _p44Zr(1000)))
									if
										not (
											_cNwEk3oQ["Parent"]
											and _r7IKc["Health"] > 0
											and _m3g8as["Parent"]
											and _y4IB9
											and _y4IB9["Health"] > 0
											and _fx2la
										)
									then
										return
									end
									local _GaoB5 = false
									local _fwXR5 = tick() + (220 / 0x3e8)
									while tick() < _fwXR5 and _cNwEk3oQ["Parent"] and _r7IKc["Health"] > 0 and _m3g8as["Parent"] do
										local _UCzKw = (_cNwEk3oQ:GetAttribute("Blocking") == true)
											or (_cNwEk3oQ:FindFirstChild("Blocking") ~= ({})[1])
											or (_cNwEk3oQ:FindFirstChild("Block") ~= ({})[1])
											or (_cNwEk3oQ:FindFirstChild("BlockShield") ~= ({})[1])
										if _UCzKw and not _gqaLSXNz then
											return
										end
										local _NSZMp = _Z0Hry:GetAttribute("LastM1Hitted")
										local _mPuo1 = _r7IKc["Health"] < _yQoVr3
										local _bVOE_ = (_m3g8as["AssemblyLinearVelocity"]["Y"] > 6)
											or (_m3g8as["Position"]["Y"] > _nHuXh + (600 / 0x3e8))
											or (_cNwEk3oQ:FindFirstChild("BeingLaunched") ~= ({})[1])
											or (_cNwEk3oQ:GetAttribute("BeingLaunched") ~= ({})[1])
											or (_cNwEk3oQ:FindFirstChild("Ragdoll") ~= ({})[1])
											or (_cNwEk3oQ:GetAttribute("Ragdoll") ~= ({})[1])
											or (_cNwEk3oQ:FindFirstChild("KnockedDown") ~= ({})[1])
										local _bbTCA = (_NSZMp ~= _MZuG3)
										local _G18fC = (_gqaLSXNz or (_FOk6nm_ and not HubSettings["Misc"]["FriendCheck"]))
											and (_fx2la["Position"] - _m3g8as["Position"])["Magnitude"] <= (0x2 * 6 - 0)
										if _mPuo1 or _bVOE_ or _bbTCA or _G18fC then
											_GaoB5 = true
											break
										end
										RunService["Heartbeat"]:Wait()
									end
									if not _GaoB5 and (_gqaLSXNz or (_FOk6nm_ and not HubSettings["Misc"]["FriendCheck"])) then
										local _BEt1Q = (_fx2la["Position"] - _m3g8as["Position"])["Magnitude"]
										if _BEt1Q <= 13 then
											_GaoB5 = true
										end
									end
									if not _GaoB5 then
										return
									end
									local _kikKg = (_fx2la["Position"] - _m3g8as["Position"])["Magnitude"]
									if _kikKg > 15 then
										return
									end
									if
										_Om_zX()
										and (
											HubSettings["AutoTech"]["Method"] == "Perform Always"
											or (
												HubSettings["AutoTech"]["Method"] == "Perform Once"
												and HubSettings["AutoTech"]["PerformOnce"]
											)
										)
									then
										local _PFujJ = HubSettings["AutoTech"]["Tech"]
										if _PFujJ ~= "" and HubSettings["AutoTech"]["Method"] == "Perform Once" then
											_xQp2C(_i3Z2l)
											HubSettings["AutoTech"]["PerformOnce"] = false
										end
										if _FUndW then
											_FUndW(_PFujJ, _m3g8as)
										end
										local _K2QaX, _Fo_fd = pcall(function()
											if _PFujJ == "Supa" then
												_GZ1a7(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Lock On Dash" then
												_VBJJ9(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Loop Dash" then
												_SrHidRlg(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Kiba" then
												_hkJ5P(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Loop Dash v2" then
												_ZlTUv(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Custom Dash" then
												_Q3OwZ(_cNwEk3oQ, _m3g8as, _r7IKc)
											elseif _PFujJ == "Custom Dash v2" then
												_ijYak(_cNwEk3oQ, _m3g8as, _r7IKc)
											end
										end)
										if not _K2QaX then
											EnvAccess["warn"]("[KittyWare] auto tech: " .. tostring(_Fo_fd))
											_mzv8k = false
										end
									end
								end
							end)
						end
					else
						(function()
							return (bit32 and 1548 or 0x1d48)
						end)()
					end
					if 0 == 0x0 then
						if _y4IB9 then
							_l3G1i(_y4IB9:GetPropertyChangedSignal("JumpPower"), function()
								if
									(
										HubSettings["Rage"]["NoFatigue"]
										and not _Z0Hry:FindFirstChild("NoJump")
										and _uL54o(_Z0Hry, _dcE27["ignoreLocal"])
									) or HubSettings["Rage"]["AlwaysJump"]
								then
									_IeaiYt2E(_y4IB9, "JumpPower", 50)
								end
							end)
							_l3G1i(_y4IB9:GetPropertyChangedSignal("AutoRotate"), function()
								if _mzv8k then
									_y4IB9["AutoRotate"] = false
								end
							end)
							if 129 == 0x81 then
								_l3G1i(_y4IB9["Died"], _dXK4f)
							else
								(function()
									return ((0xec61 % 0x2 == 0x0) and (bit32 and 30256 or 0x0) or (bit32 and 21198 or 0x0))
								end)()
							end
						end
					else
						(function()
							return (bit32 and 1774832265 or 0x6391)
						end)()
					end
					task["spawn"](function()
						local _kL0Fy, _f8Lwt = pcall(_KCt41)
						if not _kL0Fy then
							EnvAccess["warn"]("[KittyWare] setupGui: " .. tostring(_f8Lwt))
						end
					end)
					if HubSettings["Visuals"]["Headless"] then
						_J7mp6["set"](1)
						_J7mp6["start"]()
					end
					if HubSettings["Visuals"]["Korblox"] then
						task["defer"](function()
							_S1n8e(true)
						end)
					end
					if 16 == 0x10 then
						if HubSettings["Visuals"]["SelfChams"]["Enabled"] then
							task["spawn"](function()
								_BZad1()
								task["wait"](((0 + 0x2 * 100) / 0x3e8))
								if HubSettings["Visuals"]["SelfChams"]["Enabled"] and _Z0Hry == _jzGzHNO then
									_BZad1()
								end
								task["wait"]((500 / 0x3e8))
								if HubSettings["Visuals"]["SelfChams"]["Enabled"] and _Z0Hry == _jzGzHNO then
									_BZad1()
								end
							end)
						end
					else
						(function()
							return (bit32 and 31609 or 0x3eb9)
						end)()
					end
					_l3G1i(_jzGzHNO["DescendantAdded"], function(_KipWT)
						if HubSettings["Visuals"]["SelfChams"]["Enabled"] and _KipWT:IsA("BasePart") then
							task["defer"](_BZad1)
						end
					end)
					if HubSettings["Rage"]["NoSideDashCooldown"] and _Z0Hry then
						_Z0Hry:SetAttribute("CustomSideDashCooldown", 0)
						_zk6rn(true)
					end
					if HubSettings["Visuals"]["Sky"]["Enabled"] then
						if 65535 == 0xffff then
							task["spawn"](function()
								_liq5P["apply"](true)
								task["wait"]((300 / 0x3e8))
								if HubSettings["Visuals"]["Sky"]["Enabled"] and _Z0Hry == _jzGzHNO then
									_liq5P["apply"](true)
								end
							end)
						else
							(function()
								return (bit32 and 61845 or 0xeaf1)
							end)()
						end
					end
					if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							task["spawn"](function()
								_cny6G(true)
								task["wait"](((150 + 150) / 0x3e8))
								if HubSettings["Visuals"]["Atmosphere"]["Enabled"] and _Z0Hry == _jzGzHNO then
									_cny6G(true)
								end
							end)
						else
							(function()
								return (bit32 and 1849308789 or 0x65fe)
							end)()
						end
					end
					if _SXQgY then
						_l3G1i(_jzGzHNO["DescendantAdded"], _SXQgY)
						if HubSettings["Visuals"]["EffectsColor"]["Enabled"] then
							for _tUAAE, _ogeTU in ipairs(_jzGzHNO:GetDescendants()) do
								if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
									_SXQgY(_ogeTU)
								else
									(function()
										return (bit32 and 62713 or 0xf9e8)
									end)()
								end
							end
						end
					end
				end
				local function _TPf7n()
					local _OnAot = HubLocalPlayer:FindFirstChild("Backpack")
					local _Jyojy = _Z0Hry or HubLocalPlayer["Character"]
					return (_OnAot and (_OnAot:FindFirstChild("Prey's Peril") or _OnAot:FindFirstChild("Split Second Counter")))
						or (_Jyojy and (_Jyojy:FindFirstChild("Prey's Peril") or _Jyojy:FindFirstChild("Split Second Counter")))
				end
				_tew4S = function()
					if _MJSFe and _MJSFe["Parent"] then
						return _MJSFe
					end
					if _Z0Hry then
						_MJSFe = _Z0Hry:FindFirstChild("Communicate") or _Z0Hry:WaitForChild("Communicate", (1 + 1))
					end
					return _MJSFe
				end
				local function _IVaO5(_Zk2gb, _uH_IA, _zSClb)
					_zSClb = _zSClb or 0
					if 0 == 0x0 then
						if not (_Zk2gb and _uH_IA and _fx2la and _y4IB9) then
							return
						end
					else
						(function()
							return (bit32 and 38886 or 0x95a6)
						end)()
					end
					if _mzv8k or _uH_IA["Health"] <= 0 or _y4IB9["Health"] <= 0 then
						return
					end
					local _EeYgo
					_EeYgo = RunService["Heartbeat"]:Connect(function(_ZB_1X)
						if
							not (
								_Zk2gb
								and _Zk2gb["Parent"]
								and _fx2la
								and _fx2la["Parent"]
								and _uH_IA["Health"] > 0
								and _y4IB9["Health"] > 0
							)
						then
							_vA5WJ(_EeYgo)
						elseif _uL54o(_fx2la["Parent"], _dcE27["ignoreLocal"]) then
							_y4IB9["AutoRotate"] = false
							local _eYSE7 = _fx2la["CFrame"]
							local _vRhJq = Vector3["new"](_Zk2gb["Position"]["X"], _eYSE7["Position"]["Y"], _Zk2gb["Position"]["Z"])
							local _QtSns = CFrame["new"](_eYSE7["Position"], _vRhJq)
							if _zSClb <= 0 then
								_fx2la["CFrame"] = _QtSns
							else
								local _V7wTG = math["clamp"](_ZB_1X / _zSClb, 0, 1)
								_fx2la["CFrame"] = _eYSE7:Lerp(_QtSns, _V7wTG)
							end
						end
					end)
					if 65535 == 0xffff then
						table["insert"](_rJ2QD, _EeYgo)
					else
						(function()
							return (bit32 and (43104 * 0x3d % 0x10000) or 0xa96f)
						end)()
					end
					return _EeYgo
				end
				_sC0i4 = function()
					local _qWheU = _tew4S()
					if not _FPbWqU0 then
						_FPbWqU0 = true
						if _y4IB9 then
							_y4IB9["AutoRotate"] = false
						end
						if _qWheU then
							_qWheU:FireServer(_Ws0Y9["holdBlock"])
						end
					end
				end
				_LZYNd = function()
					local _vzWfF = _tew4S()
					if _FPbWqU0 then
						_FPbWqU0 = false
						if _vzWfF then
							_vzWfF:FireServer(_Ws0Y9["releaseBlock"])
						end
						if _y4IB9 and not _mzv8k then
							_y4IB9["AutoRotate"] = true
						end
					end
				end
				local function _AcA1U(_VQZAy, _meAhg, _rSac4)
					if _Z0Hry and _Z0Hry:FindFirstChild("Counter") then
						return
					end
					_VQZAy = _VQZAy or (250 / 0x3e8)
					if 0 == 0x0 then
						_sC0i4()
					else
						(function()
							return (bit32 and 14779 or 0x2113)
						end)()
					end
					local _MvkDk
					if HubSettings["Autoblock"]["RotateChar"] and _meAhg and _rSac4 then
						_MvkDk = _IVaO5(_meAhg, _rSac4, HubSettings["Autoblock"]["CharEasing"])
					end
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if HubSettings["Autoblock"]["RotateCam"] and _meAhg then
							_oIwtD(_meAhg["Position"], HubSettings["Autoblock"]["CamEasing"])
						end
					else
						(function()
							return (bit32 and 65142 or 0x7b76)
						end)()
					end
					if 129 == 0x81 then
						task["wait"](_VQZAy)
					else
						(function()
							return (bit32 and 13904 or 0x8d36)
						end)()
					end
					_vA5WJ(_MvkDk)
					_LZYNd()
				end
				local function _SVwyf()
					local _lJc6o = _tew4S()
					if 129 == 0x81 then
						if not _lJc6o then
							return
						end
					else
						(function()
							return (bit32 and 46059 or 0x1eb3)
						end)()
					end
					local _sE2np = UserInputService["TouchEnabled"] and not UserInputService["KeyboardEnabled"]
					local _HI5FC
					if 16 == 0x10 then
						if HubSettings["DeviceSpoof"]["Enabled"] then
							_HI5FC = (
								HubSettings["DeviceSpoof"]["Device"] == "Mobile"
								or HubSettings["DeviceSpoof"]["Device"] == "Console"
							)
						else
							_HI5FC = _sE2np
						end
					else
						(function()
							return (bit32 and (41939 * 0x3d % 0x10000) or 0xa2cd)
						end)()
					end
					_VrEaM()
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_lJc6o:FireServer({ ["Goal"] = "LeftClick", ["Mobile"] = _HI5FC or ({})[1] })
					else
						(function()
							return (bit32 and 14709 or 0xbd55)
						end)()
					end
					_VrEaM()
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_lJc6o:FireServer({ ["Goal"] = "LeftClickRelease", ["Mobile"] = _HI5FC or ({})[1] })
					else
						(function()
							return (bit32 and 56569 or 0xbfe0)
						end)()
					end
					_VrEaM()
				end
				local function _epkf_()
					if 0 == 0x0 then
						_IDvSS(_NSKGP)
					else
						(function()
							return (bit32 and 850878543 or 0x3781)
						end)()
					end
					_VrEaM(((5 + 5) / 0x3e8))
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						_SVwyf()
					else
						(function()
							return (bit32 and (24530 * 0x3d % 0x10000) or 0x5b99)
						end)()
					end
					if 0 == 0x0 then
						_S4jah(_NSKGP)
					else
						(function()
							return (bit32 and (43652 * 0x3d % 0x10000) or 0xb26d)
						end)()
					end
				end
				local function _hZzeE(_oj56FM0w, _HnNltqc, _OV29Qz)
					if
						_oj56FM0w["Parent"]
						and _uL54o(_oj56FM0w["Parent"], _dcE27["ignoreM1"])
						and not (_Z0Hry and _Z0Hry:FindFirstChild("CanBringUp"))
					then
						local _hIWSw
						if HubSettings["Autoblock"]["RotateChar"] and _oj56FM0w and _HnNltqc then
							if 16 == 0x10 then
								_hIWSw = _IVaO5(_oj56FM0w, _HnNltqc, HubSettings["Autoblock"]["CharEasing"])
							else
								(function()
									return ((0xc74e % 0x2 == 0x0) and (bit32 and 25511 or 0x0) or (bit32 and 27502 or 0x0))
								end)()
							end
						end
						if HubSettings["Autoblock"]["RotateCam"] and _oj56FM0w then
							if 1 == 0x1 then
								_oIwtD(_oj56FM0w["Position"], HubSettings["Autoblock"]["CamEasing"])
							else
								(function()
									return (bit32 and 21554 or 0xd454)
								end)()
							end
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							_SVwyf()
						else
							(function()
								return (bit32 and 40229 or 0xd6af)
							end)()
						end
						if 0 == 0x0 then
							task["wait"](((0x2 * 50 - 0) / 0x3e8))
						else
							(function()
								return (bit32 and 25420 or 0x1b63)
							end)()
						end
						_vA5WJ(_hIWSw)
					end
				end
				local function _ACBZ15Q3(_DCG1hsz)
					if not _DCG1hsz or not _fx2la then
						return false
					end
					local _aZCGze = _DCG1hsz["AssemblyLinearVelocity"]
					if _aZCGze["Magnitude"] >= ((0x2 * 250 - 0) / 0x3e8) then
						local _X1IU7 = (_fx2la["Position"] - _DCG1hsz["Position"])["Unit"]
						local _Q8tlbUaP = _aZCGze["Unit"]
						local _xpLOYaB = _Q8tlbUaP:Dot(_X1IU7)
						if 16 == 0x10 then
							if _xpLOYaB > ((0 + 0x2 * 50) / 0x3e8) then
								return true
							end
						else
							(function()
								return (bit32 and 31418 or 0xe97a)
							end)()
						end
					end
					local _eh2Im8 = _DCG1hsz["CFrame"]["LookVector"]
					local _LIRPH = (_fx2la["Position"] - _DCG1hsz["Position"])["Unit"]
					if _eh2Im8:Dot(_LIRPH) > ((75 + 75) / 0x3e8) then
						return true
					end
					return false
				end
				local function _EEXaAvdE(_BzpgT, _e3LLl, _bivEl)
					if 0 == 0x0 then
						if not _fx2la or not _BzpgT then
							return
						end
					else
						(function()
							return (bit32 and (22530 * 0x3d % 0x10000) or 0x5c40)
						end)()
					end
					local _IUvE7 = _fx2la["Position"]
					local _p12NO = _BzpgT["Position"]
					local _imVYf = (_IUvE7 - _p12NO)["Magnitude"]
					if 16 == 0x10 then
						_AcA1U(_reriI(((125 + 125) / 0x3e8))[1], _BzpgT, _e3LLl)
					else
						(function()
							return (bit32 and 8866 or 0x3287)
						end)()
					end
					if 129 == 0x81 then
						if
							(
								not HubSettings["Autoblock"]["AutoM1"]
								or ((_imVYf > _vrfgk["M1"]) and not (_imVYf <= _vrfgk["MovingM1"] and _ACBZ15Q3(_BzpgT)))
							) and not _bivEl
						then
							return
						end
					else
						(function()
							return (bit32 and 717685251 or 0xfa41)
						end)()
					end
					_hZzeE(_BzpgT, _e3LLl)
				end
				local function _PO5cu(_ICmbP, _FxMZj, _igMqR, _TrAk2)
					if not (_ICmbP and _FxMZj and _fx2la) then
						return
					end
					local _MdDiN = _IVaO5(_ICmbP, _FxMZj, HubSettings["Autoblock"]["CharEasing"])
					local _tZaOi
					local _pGvOW = tick()
					_tZaOi = RunService["Heartbeat"]:Connect(function()
						_sC0i4()
						local _U47hf = tick() - _pGvOW
						local _L0Fy6 = math["clamp"](_U47hf / (100 / 0x3e8), 0, 1)
						if
							(_igMqR and _igMqR:FindFirstChild("NoBlock"))
							or (_fx2la["Position"] - _ICmbP["Position"])["Magnitude"] >= (_vrfgk["Barrage"] + (3 + 2))
						then
							_vA5WJ(_MdDiN)
							_vA5WJ(_tZaOi)
							_LZYNd()
							if
								HubSettings["Autoblock"]["AutoM1"]
								and (_fx2la["Position"] - _ICmbP["Position"])["Magnitude"] <= _vrfgk["M1"]
							then
								_hZzeE(_ICmbP, _FxMZj)
							end
							return
						end
						if _L0Fy6 >= 1 and not (_igMqR and _igMqR:FindFirstChild("Slowed")) then
							_vA5WJ(_MdDiN)
							_vA5WJ(_tZaOi)
							_LZYNd()
						end
					end)
				end
				local function _uoURw(_dbV4_, _YrV1M, _Pjka4)
					local _uWPWO = _TPf7n()
					if not HubSettings["Autoblock"]["AutoCounter"] or not _uWPWO or _Pjka4 then
						return true
					end
					local _tRHue = _G_mVA()
					if 16 == 0x10 then
						if _tRHue then
							local _YdS4U = _tRHue:FindFirstChild("4") or _tRHue:FindFirstChild((2 + 2))
							local _tCvsb = _YdS4U and _YdS4U:FindFirstChild("Base")
							if _tCvsb and _tCvsb:FindFirstChild("Cooldown") then
								return true
							end
						end
					else
						(function()
							return (bit32 and 6372 or 0x8b2c)
						end)()
					end
					local _yu80O = _tew4S()
					if _yu80O and _uWPWO then
						if 0 == 0x0 then
							_yu80O:FireServer({
								["IsAutoActivate"] = true,
								["Goal"] = "Console Move",
								["Tool"] = _uWPWO,
								["ToolName"] = _uWPWO["Name"],
							})
						else
							(function()
								return (bit32 and (33161 * 0x3d % 0x10000) or 0x8232)
							end)()
						end
						return false
					end
					return true
				end
				local function _P_h6H(_UxGEJ, _dkeGg, _y_W2U)
					if not (_UxGEJ and _dkeGg and _y_W2U) then
						return
					end
					_Z9TMp(_UxGEJ, _dkeGg, true)
					if 1 == 0x1 then
						_OS0SJ({
							["Title"] = "RXM HUB",
							["Description"] = string["format"](
								'%s used <font color="%s">Death Counter!</font>',
								_UxGEJ["DisplayName"],
								_hXRHJ(HubSettings["Visuals"]["ESP"]["DeathCounterColor"])
							),
							["Image"] = _N4Idm(_UxGEJ),
							["Source"] = "Death Counter",
						})
					else
						(function()
							return ((0x27a8 % 0x2 == 0x0) and (bit32 and 5076 or 0x0) or (bit32 and 40403 or 0x0))
						end)()
					end
					local _Lym94
					if 129 == 0x81 then
						_Lym94 = _l3G1i(_y_W2U["AncestryChanged"], function(_gaaZQ, _pvDtO)
							if not _pvDtO then
								if
									(
										HubSettings["Visuals"]["ESP"]["DeathCounterESP"]
										or HubSettings["Visuals"]["ESP"]["SaitamaUltESP"]
									) and not HubSettings["Visuals"]["ESP"]["Enabled"]
								then
									_O3IOB(_dkeGg, _UxGEJ, false)
								else
									_Z9TMp(_UxGEJ, _dkeGg, true)
								end
								_vA5WJ(_Lym94)
							end
						end)
					else
						(function()
							return (bit32 and (61012 * 0x3d % 0x10000) or 0xc03e)
						end)()
					end
				end
				_dcE27["effectObjects"] = EnvAccess["setmetatable"]({}, { ["__mode"] = "k" })
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					_SXQgY = function(_uPY8L)
						local _Lhgzn = _uPY8L["Name"]
						if
							(_uPY8L:IsA("PointLight") or _uPY8L:IsA("SpotLight") or _uPY8L:IsA("SurfaceLight"))
							and HubSettings["Visuals"]["NoNewLight"]
						then
							_IeaiYt2E(_uPY8L, "Enabled", false)
						elseif
							(_DQit6[_Lhgzn] and HubSettings["Visuals"]["NoSmoke"])
							or (_Lhgzn == "Clone_Rig" and HubSettings["Visuals"]["NoGarouC"])
							or ((_dcE27["aura"][_Lhgzn] or _Lhgzn == "CosmeticAuras") and HubSettings["Visuals"]["NoAuras"])
							or (_dcE27["cape"][_Lhgzn] and HubSettings["Visuals"]["NoCapes"])
							or (_Lhgzn == "Ring" and HubSettings["Visuals"]["NoRings"])
						then
							task["defer"](_uPY8L["Destroy"], _uPY8L)
						elseif
							HubSettings["Visuals"]["EffectsColor"]["Enabled"]
							and (_uPY8L:IsA("ParticleEmitter") or _uPY8L:IsA("Trail") or _uPY8L:IsA("Beam"))
						then
							local _QUwWc = false
							if (_Z0Hry and _uPY8L:IsDescendantOf(_Z0Hry)) or _uPY8L:FindFirstAncestor(HubLocalPlayer["Name"]) then
								_QUwWc = true
							else
								local _ldveg = _keMEq[_YxtF_bco]
								if _ldveg and _ldveg[_Lhgzn] then
									_QUwWc = true
								else
									local _GoKsH = (_uPY8L:IsA("BasePart") and _uPY8L)
										or _uPY8L:FindFirstAncestorOfClass("BasePart")
									if _GoKsH and _fx2la then
										local _HAQsA = (_GoKsH["Position"] - _fx2la["Position"])["Magnitude"]
										if _HAQsA <= (1 + 0x2 * 12) then
											local _ccj_e = _Lhgzn:lower()
											if
												tonumber(_Lhgzn)
												or _Lhgzn:match("^%d+[%-_]%d+")
												or _ccj_e:find("trail", (0x2 * 1 - 1), true)
												or _ccj_e:find("spin", (1 + 0), true)
												or _ccj_e:find("particle", 1, true)
												or _ccj_e:find("water", 1, true)
												or _ccj_e:find("hit", 1, true)
												or _ccj_e:find("slash", (1 + 0x2 * 0), true)
												or _ccj_e:find("swing", 1, true)
												or _ccj_e:find("punch", 1, true)
												or _ccj_e:find("impact", (1 + 0x2 * 0), true)
												or _ccj_e:find("flash", 1, true)
												or _ccj_e:find("line", (1 + 0), true)
												or _ccj_e:find("real", (0x2 * 1 - 1), true)
												or _ccj_e:find("air", 1, true)
												or _ccj_e:find("blue", 1, true)
												or _ccj_e:find("big", (1 + 0x2 * 0), true)
												or _ccj_e:find("spark", (1 + 0x2 * 0), true)
												or _ccj_e:find("splash", 1, true)
											then
												_QUwWc = true
											end
										end
									end
								end
							end
							if _QUwWc then
								_IeaiYt2E(
									_uPY8L,
									"Color",
									EnvAccess["ColorSequence"]["new"](HubSettings["Visuals"]["EffectsColor"]["Color"])
								)
								_dcE27["effectObjects"][_uPY8L] = true
							end
						end
					end
				else
					(function()
						return (bit32 and 45012 or 0xcf36)
					end)()
				end
				local function _ltM9g()
					if not HubSettings["Visuals"]["EffectsColor"]["Enabled"] then
						return
					end
					local _qRoy3 = EnvAccess["ColorSequence"]["new"](HubSettings["Visuals"]["EffectsColor"]["Color"])
					for _HjpLI in pairs(_dcE27["effectObjects"]) do
						if _HjpLI["Parent"] then
							if 129 == 0x81 then
								_IeaiYt2E(_HjpLI, "Color", _qRoy3)
							else
								(function()
									return (bit32 and 30540 or 0xfc8)
								end)()
							end
						else
							if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
								_dcE27["effectObjects"][_HjpLI] = ({})[1]
							else
								(function()
									return (bit32 and 7399 or 0xd21c)
								end)()
							end
						end
					end
				end
				local function _YQB6C(_he55q)
					if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
						if _he55q then
							if 129 == 0x81 then
								if _Z0Hry then
									for _C3KPw, _EAEfrgSs in pairs(_Z0Hry:GetDescendants()) do
										_SXQgY(_EAEfrgSs)
									end
								end
							else
								(function()
									return ((0xe58 % 0x2 == 0x0) and (bit32 and 1836 or 0x0) or (bit32 and 50269 or 0x0))
								end)()
							end
							for _X9iSzZU, _icYta6 in pairs(PlayersService:GetPlayers()) do
								local _xlsTe = _icYta6["Character"]
								if _xlsTe and _xlsTe ~= _Z0Hry then
									if 129 == 0x81 then
										for _Qhm_80, _TjYWBtQ in pairs(_xlsTe:GetDescendants()) do
											if 1 == 0x1 then
												_SXQgY(_TjYWBtQ)
											else
												(function()
													return (
														(0x8f52 % 0x2 == 0x0) and (bit32 and 18345 or 0x0)
														or (bit32 and 26654 or 0x0)
													)
												end)()
											end
										end
									else
										(function()
											return ((0x41be % 0x2 == 0x0) and (bit32 and 8415 or 0x0) or (bit32 and 63574 or 0x0))
										end)()
									end
								end
							end
							if _f5mDQ["Thrown"] then
								for _eQGwNW7B, _DuajJ in pairs(_f5mDQ["Thrown"]:GetDescendants()) do
									_SXQgY(_DuajJ)
								end
							end
						end
					else
						(function()
							return (bit32 and 55582 or 0x30d9)
						end)()
					end
				end
				if 65535 == 0xffff then
					HubUI[(1 + 0)] = function(_h74ciGr)
						if not _h74ciGr then
							return
						end
						if EnvAccess["isrbxactive"] and not EnvAccess["isrbxactive"]() then
							return
						end
						local _Kl7n343j = _h74ciGr["Name"]
						local _H66cx = _h74ciGr:FindFirstAncestorWhichIsA("Model")
						if not _H66cx and _h74ciGr["Parent"] then
							_H66cx = _h74ciGr["Parent"]:FindFirstAncestorWhichIsA("Model")
						end
						if not _H66cx then
							return
						end
						local _olfMgh = PlayersService:FindFirstChild(_H66cx["Name"])
						local _lW44C46 = (_H66cx == _Z0Hry) or (_olfMgh and _olfMgh == HubLocalPlayer)
						_SXQgY(_h74ciGr)
						if not _lW44C46 and _H66cx then
							local _aLAKT = _H66cx:FindFirstChild("HumanoidRootPart")
							local _HPpYB = _H66cx:FindFirstChildOfClass("Humanoid") or _H66cx:FindFirstChild("Humanoid")
							if
								not _HPpYB
								or not _aLAKT
								or not _fx2la
								or not _y4IB9
								or _y4IB9["Health"] <= 0
								or _HPpYB["Health"] <= 0
							then
								return
							end
							if _Kl7n343j == "Counter" and _olfMgh then
								_P_h6H(_olfMgh, _H66cx, _h74ciGr)
							elseif
								HubSettings["Autoblock"]["Enabled"]
								and not (HubSettings["Misc"]["FriendCheck"] and _olfMgh and _JrRW2(_olfMgh, false))
							then
								local _sALuX = (_fx2la["Position"] - _aLAKT["Position"])["Magnitude"]
								local _Zn9a4 = (_Kl7n343j == "M1ing")
								local _OhUdu = _dcE27["interruptMoves"][_Kl7n343j]
								local _L8el_ = _dcE27["barrageMoves"][_Kl7n343j]
								local _skHSk = HubSettings["Autoblock"]["DashPredict"] and _sALuX <= _vrfgk["FarDash"]
								if not (_Zn9a4 or _OhUdu or _L8el_ or _skHSk) then
									return
								end
								local _pIfT9 = (_Kl7n343j == "dodgevelocity" or _Kl7n343j == "InDash" or _Kl7n343j == "SideDash")
								local _Sqgmy = _sALuX <= _vrfgk["M1"]
								local _zCIA_ = _sALuX <= _vrfgk["MovingM1"] and _ACBZ15Q3(_aLAKT)
								local _wxUps = _skHSk
									and (_pIfT9 or _xFaaK(_j089A["lsideDash"], _HPpYB) or _xFaaK(_j089A["rsideDash"], _HPpYB))
								local _dlhUB = false
								if _Zn9a4 then
									_dlhUB = _Sqgmy or _zCIA_ or _wxUps
								elseif _L8el_ then
									_dlhUB = _sALuX <= _vrfgk["Barrage"]
								elseif _OhUdu then
									_dlhUB = _sALuX <= _vrfgk["MovingM1"]
								elseif _wxUps then
									_dlhUB = true
								else
									_dlhUB = _Sqgmy or _zCIA_ or _wxUps
								end
								if _dlhUB then
									if _uL54o(_Z0Hry, _dcE27["ignoreLocal"]) and _uL54o(_H66cx, _dcE27["ignoreEnemy"]) then
										if _Zn9a4 or _OhUdu or _L8el_ or _wxUps then
											local _Sac2K = _uoURw(_aLAKT, _HPpYB, _zCIA_)
											if _Sac2K then
												if _Zn9a4 then
													_EEXaAvdE(_aLAKT, _HPpYB, _wxUps)
												elseif _OhUdu then
													_hZzeE(_aLAKT, _HPpYB)
												elseif _L8el_ then
													_PO5cu(_aLAKT, _HPpYB, _H66cx, _wxUps)
												elseif _wxUps then
													_AcA1U((350 / 0x3e8), _aLAKT, _HPpYB)
												end
											end
										end
									end
								end
							end
						elseif _lW44C46 then
							if
								(_Kl7n343j == "Freeze" and HubSettings["Rage"]["NoStun"])
								or (_Kl7n343j == "Slowed" and HubSettings["Rage"]["NoSlow"])
							then
								task["defer"](_h74ciGr["Destroy"], _h74ciGr)
							elseif
								HubSettings["Rage"]["NoSideDashCooldown"]
								and (
									_Kl7n343j == "UsedDash"
									or _Kl7n343j == "InDash"
									or _Kl7n343j == "DashCooldown"
									or _Kl7n343j == "SideDashCooldown"
								)
							then
								task["defer"](_h74ciGr["Destroy"], _h74ciGr)
							elseif
								_Kl7n343j == "moveme"
								and HubSettings["Rage"]["CustomFrontDash"]["Enabled"]
								and not HubSettings["Rage"]["CustomFrontDash"]["OnlyOnKeybind"]
								and HubSettings["Rage"]["CustomFrontDash"]["Distance"] > 1
							then
								_t6uaX(
									_reriI(HubSettings["Rage"]["CustomFrontDash"]["Distance"])[(1 + 0x2 * 0)],
									((0x2 * 25 - 0) / 0x3e8)
								)
							elseif
								_Kl7n343j == "dodgevelocity"
								and HubSettings["Rage"]["CustomSideDash"]["Distance"] > 1
								and HubSettings["Rage"]["CustomSideDash"]["Enabled"]
								and not HubSettings["Rage"]["CustomSideDash"]["OnlyOnKeybind"]
							then
								_t6uaX(_reriI(HubSettings["Rage"]["CustomSideDash"]["Distance"])[1], ((0x2 * 25 - 0) / 0x3e8))
							end
						end
					end
				else
					(function()
						return ((0xedc6 % 0x2 == 0x0) and (bit32 and 30435 or 0x0) or (bit32 and 9328 or 0x0))
					end)()
				end
				HubUI[(1 + 1)] = function(_wZRJQ, _hmAns, _WspM1)
					if _wZRJQ == "Ulted" then
						if _hmAns:GetAttribute(_wZRJQ) then
							local _DHy3o = _hmAns:GetAttribute("Character")
							_OS0SJ({
								["Title"] = "RXM HUB",
								["Description"] = string["format"](
									'%s used <font color="%s">%s Ult!</font>',
									_WspM1["DisplayName"],
									_hXRHJ(_SCYz7(_WspM1, _hmAns)),
									_wZKifJPa[_DHy3o] or tostring(_DHy3o or "")
								),
								["Image"] = _N4Idm(_WspM1),
								["Source"] = "Ult",
							})
							if _DHy3o == "Bald" then
								_Z9TMp(_WspM1, _hmAns, true)
							else
								_Z9TMp(_WspM1, _hmAns)
							end
						elseif not HubSettings["Visuals"]["ESP"]["Enabled"] and not _hmAns:FindFirstChild("Counter") then
							_O3IOB(_hmAns, _WspM1, false)
						else
							_Z9TMp(_WspM1, _hmAns)
						end
					end
				end
				HubUI[(3 + 0)] = function(_iBgCk)
					_J4f_N(_M5vLN[_iBgCk])
					_J4f_N(_lbsvM[_iBgCk])
					_M5vLN[_iBgCk] = {}
					_lbsvM[_iBgCk] = {}
					local _d9naL = _iBgCk["Character"]
					if not _d9naL then
						_d9naL = _f5mDQ["Live"]:FindFirstChild(_iBgCk["Name"])
					end
					_yN_t5(_M5vLN[_iBgCk], _iBgCk, "CharacterAdded", function(_ERCy9)
						_yN_t5(_lbsvM[_iBgCk], _ERCy9, "DescendantAdded", HubUI[(1 + 0)])
						if _iBgCk == HubLocalPlayer then
							return
						end
						_Z9TMp(_iBgCk, _ERCy9)
						_yN_t5(_lbsvM[_iBgCk], _ERCy9, "AttributeChanged", function(_FWVpz)
							HubUI[(1 + 1)](_FWVpz, _ERCy9, _iBgCk)
						end)
					end)
					if _iBgCk ~= HubLocalPlayer then
						_yN_t5(_M5vLN[_iBgCk], _iBgCk, "AttributeChanged", function(_SocAd)
							local _XXSU_ = _iBgCk["Character"]
							if _SocAd == "Ultimate" and _XXSU_ then
								_Z9TMp(_iBgCk, _XXSU_)
							end
						end)
						if not _RWZpc[_iBgCk["Name"]] then
							_RWZpc[_iBgCk["Name"]] = "Neutral"
						end
						task["spawn"](_YWFA4n, _iBgCk)
						if _d9naL then
							_Z9TMp(_iBgCk, _d9naL)
							_yN_t5(_lbsvM[_iBgCk], _d9naL, "DescendantAdded", HubUI[1])
							_yN_t5(_lbsvM[_iBgCk], _d9naL, "AttributeChanged", function(_kQZhn)
								HubUI[2](_kQZhn, _d9naL, _iBgCk)
							end)
						end
					elseif _d9naL then
						_yN_t5(_lbsvM[_iBgCk], _d9naL, "DescendantAdded", HubUI[1])
					end
					_yN_t5(_M5vLN[_iBgCk], _iBgCk, "CharacterRemoving", function(_xh7ey)
						if _lbsvM[_iBgCk] then
							_J4f_N(_lbsvM[_iBgCk])
						end
					end)
				end
				HubUI[4] = function(_beDfr, _oMugN)
					if not _beDfr then
						return
					end
					local _BvhF6 = HubSettings
					for _Oe5lM in string["gmatch"](_beDfr, "[^%.]+") do
						if _BvhF6[_Oe5lM] == ({})[1] then
							return
						end
						if _Oe5lM ~= _beDfr:match("[^%.]+$") then
							_BvhF6 = _BvhF6[_Oe5lM]
						else
							_BvhF6[_Oe5lM] = _oMugN
						end
					end
				end
				HubUI[(0x2 * 3 - 1)] = function(_gBdST, _FUqSa, _SDd9E)
					HubUI[(2 + 2)](_gBdST, _SDd9E)
					if _FUqSa == "ESP" or _FUqSa == "NoBillboards" or _FUqSa == "BoxesESP" or _FUqSa == "HighlightESP" then
						_tTg1H()
					elseif _FUqSa == "Custom Ultbar Color" or _FUqSa == "Custom Ultbar Text" then
						task["spawn"](pcall, _KCt41)
					elseif _FUqSa == "NoGShadows" then
						local _XgzmT = _UbxYIsuM(Lighting, "GlobalShadows")
						Lighting["GlobalShadows"] = not _SDd9E and _XgzmT
					elseif _FUqSa == "Headless" then
						if _SDd9E then
							_J7mp6["set"](1)
							_J7mp6["start"]()
						else
							_J7mp6["stop"]()
							_J7mp6["set"](0)
						end
						if HubSettings["Visuals"]["SelfChams"]["Enabled"] then
							_BZad1()
						end
					elseif _FUqSa == "Korblox" then
						_S1n8e(_SDd9E)
					elseif _FUqSa == "SelfChams" then
						_BZad1()
					elseif _FUqSa == "Atmosphere" then
						_cny6G(_SDd9E)
					elseif _FUqSa == "MotionBlur" then
						_zuSl39H["set"](_SDd9E)
					else
						_YQB6C(_SDd9E)
					end
				end
				HubUI[(0 + 0x2 * 3)] = function(_xxguB)
					_u3Jke(_xxguB)
					_VrEaM()
					_IDvSS(_u6GG1)
					_kvld1(_kK9mB)
					_VrEaM((100 / 0x3e8))
					_S4jah(_u6GG1)
				end
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					do
						HubUI[9] = KittyWareLib:new({
							["name"] = "KittyWare " .. _cpTDH,
							["accent"] = Color3["fromRGB"](142, (3 + 0x2 * 92), (0x2 * 255 - 255)),
							["textsize"] = 13,
							["discord"] = _DTbHC,
						})
						if 0 == 0x0 then
							HubUI[10] = {
								["Combat"] = HubUI[9]:page({
									["name"] = "Combat",
									["pointer"] = "Combat Tab",
								}),
								["Macro"] = HubUI[(5 + 4)]:page({
									["name"] = "Macro",
									["pointer"] = "Macro Tab",
								}),
								["Visual"] = HubUI[(0x2 * 5 - 1)]:page({
									["name"] = "Visuals",
									["pointer"] = "Visual Tab",
								}),
								["Rage"] = HubUI[9]:page({
									["name"] = "Rage",
									["pointer"] = "Rage Tab",
								}),
								["Notifications"] = HubUI[9]:page({
									["name"] = "Notifications",
									["pointer"] = "Notification Tab",
								}),
								["Misc"] = HubUI[9]:page({
									["name"] = "Misc",
									["pointer"] = "Misc Tab",
								}),
							}
						else
							(function()
								return (bit32 and 679299718 or 0xeee5)
							end)()
						end
						if 16 == 0x10 then
							HubUI[11] = {
								["AutoBlock"] = HubUI[(0x2 * 5 - 0)]["Combat"]:section({
									["name"] = "Auto Block",
									["side"] = "left",
									["size"] = 253,
									["pointer"] = "Auto Block Section",
								}),
								["MiscCombat"] = HubUI[10]["Combat"]:section({
									["name"] = "Misc",
									["side"] = "left",
									["size"] = (1 + 0x2 * 162),
									["pointer"] = "Misc Combat Section",
								}),
								["AutoTech"] = HubUI[(0x2 * 5 - 0)]["Combat"]:section({
									["name"] = "Auto Tech",
									["side"] = "right",
									["size"] = (1 + 0x2 * 94),
									["pointer"] = "Auto Tech Section",
								}),
								["TechSettings"] = HubUI[10]["Combat"]:section({
									["name"] = "Auto Tech Settings",
									["side"] = "right",
									["size"] = (3 + 0x2 * 116),
									["pointer"] = "Loop Dash v2 Section",
								}),
								["CustomDash"] = HubUI[10]["Combat"]:section({
									["name"] = "Custom Dash",
									["side"] = "right",
									["size"] = 350,
									["pointer"] = "Custom Dash Section",
								}),
								["CustomDashv2"] = HubUI[10]["Combat"]:section({
									["name"] = "Custom Dash v2",
									["side"] = "right",
									["size"] = 415,
									["pointer"] = "Custom Dash v2 Section",
								}),
								["TrueDownSlam"] = HubUI[(0 + 0x2 * 5)]["Combat"]:section({
									["name"] = "True DownSlam",
									["side"] = "left",
									["size"] = (35 + 35),
									["pointer"] = "TDS Section",
								}),
								["LethalMain"] = HubUI[10]["Combat"]:section({
									["name"] = "Auto Lethal",
									["side"] = "left",
									["size"] = (1 + 0x2 * 54),
									["pointer"] = "Auto Lethal Section",
								}),
								["LethalTiming"] = HubUI[(0 + 0x2 * 5)]["Combat"]:section({
									["name"] = "Lethal Settings",
									["side"] = "left",
									["size"] = 163,
									["pointer"] = "Auto Lethal Settings Section",
								}),
								["TrueM1Reset"] = HubUI[10]["Macro"]:section({
									["name"] = "True M1 Reset",
									["side"] = "left",
									["size"] = (1 + 0x2 * 34),
									["pointer"] = "m1 Reset Section",
								}),
								["EmoteDash"] = HubUI[10]["Macro"]:section({
									["name"] = "Emote Dash",
									["side"] = "left",
									["size"] = (1 + 0x2 * 74),
									["pointer"] = "EmoteDash Section",
								}),
								["BackdashCancel"] = HubUI[10]["Macro"]:section({
									["name"] = "Backdash Cancel",
									["side"] = "left",
									["size"] = 195,
									["pointer"] = "Backdash Section",
								}),
								["Tech"] = HubUI[(0 + 0x2 * 5)]["Macro"]:section({
									["name"] = "Tech Helper",
									["side"] = "right",
									["size"] = 191,
									["pointer"] = "Tech Section",
								}),
								["VisualMain"] = HubUI[10]["Visual"]:section({
									["name"] = "Clean Look",
									["side"] = "left",
									["size"] = (165 + 165),
									["pointer"] = "Visuals Main Section",
								}),
								["VisualColor"] = HubUI[(0 + 0x2 * 5)]["Visual"]:section({
									["name"] = "Custom Effects",
									["side"] = "left",
									["size"] = (3 + 0x2 * 32),
									["pointer"] = "Visuals Color Section",
								}),
								["VisualESP"] = HubUI[(5 + 5)]["Visual"]:section({
									["name"] = "ESP",
									["side"] = "right",
									["size"] = 413,
									["pointer"] = "Visuals ESP Section",
								}),
								["VisualChar"] = HubUI[(0 + 0x2 * 5)]["Visual"]:section({
									["name"] = "Character & Self Chams",
									["side"] = "left",
									["size"] = (0 + 0x2 * 105),
									["pointer"] = "Visuals Character Section",
								}),
								["VisualAtmosphere"] = HubUI[10]["Visual"]:section({
									["name"] = "Custom Atmosphere",
									["side"] = "right",
									["size"] = (7 + 0x2 * 88),
									["pointer"] = "Visuals Atmosphere Section",
								}),
								["VisualSky"] = HubUI[(0 + 0x2 * 5)]["Visual"]:section({
									["name"] = "Custom Sky",
									["side"] = "left",
									["size"] = (0x2 * 79 - 1),
									["pointer"] = "Visuals Sky Section",
								}),
								["Rage"] = HubUI[(5 + 5)]["Rage"]:section({
									["name"] = "Toggles",
									["side"] = "right",
									["size"] = (55 + 52),
									["pointer"] = "Rage Section",
								}),
								["Fling"] = HubUI[(5 + 5)]["Rage"]:section({
									["name"] = "Fling",
									["side"] = "right",
									["size"] = (0x2 * 66 - 0),
									["pointer"] = "Fling Section",
								}),
								["Front"] = HubUI[(5 + 5)]["Rage"]:section({
									["name"] = "Front Dash",
									["side"] = "left",
									["size"] = 120,
									["pointer"] = "Front Dash Section",
								}),
								["Side"] = HubUI[10]["Rage"]:section({
									["name"] = "Side Dash",
									["side"] = "left",
									["size"] = (133 + 132),
									["pointer"] = "Side Dash Section",
								}),
								["Notifs"] = HubUI[(0 + 0x2 * 5)]["Notifications"]:section({
									["name"] = "Main",
									["side"] = "left",
									["size"] = 127,
									["pointer"] = "Notifications Section",
								}),
								["Misc"] = HubUI[(0 + 0x2 * 5)]["Misc"]:section({
									["name"] = "Misc",
									["side"] = "left",
									["size"] = (0x2 * 161 - 0),
									["pointer"] = "Misc Section",
								}),
								["Config"] = HubUI[10]["Misc"]:section({
									["name"] = "Config",
									["side"] = "right",
									["size"] = 254,
									["pointer"] = "Config Section",
								}),
								["PingSpoof"] = HubUI[10]["Misc"]:section({
									["name"] = "Ping Spoofer",
									["side"] = "right",
									["size"] = 143,
									["pointer"] = "Ping Spoofer Section",
								}),
								["DeviceSpoof"] = HubUI[10]["Misc"]:section({
									["name"] = "Device Spoofer",
									["side"] = "right",
									["size"] = 147,
									["pointer"] = "Device Spoofer Section",
								}),
							}
						else
							(function()
								return (bit32 and 36074 or 0xdcec)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["Config"]:configloader({
							["folder"] = "KittyWare",
						})
						HubUI[12] = { ["icon"] = ({})[1], ["folder"] = "KittyWare/icons", ["watching"] = false }
						HubUI[12]["custom"] = function()
							return HubSettings["DeviceSpoof"]["Enabled"]
								and HubSettings["DeviceSpoof"]["Device"] == "Custom Icon"
								and HubUI[(0x2 * 6 - 0)]["icon"] ~= ({})[1]
						end
						HubUI[12]["real"] = function()
							return UserInputService["TouchEnabled"], UserInputService["GamepadEnabled"]
						end
						HubUI[(0 + 0x2 * 6)]["flags"] = function()
							local _gtUwz7qb = HubSettings["DeviceSpoof"]["Device"]
							if _gtUwz7qb == "Custom Icon" then
								return HubUI[12]["real"]()
							end
							return _gtUwz7qb == "Mobile", _gtUwz7qb == "Console"
						end
						HubUI[12]["shown"] = function()
							if HubLocalPlayer:GetAttribute("Console") then
								return "Console"
							end
							if HubLocalPlayer:GetAttribute("Mobile") then
								return "Mobile"
							end
							return "PC"
						end
						HubUI[(0 + 0x2 * 6)]["send"] = function(_tLrQq, _SjtwfD)
							local _XIWc9ET = _MJSFe
							if not (_XIWc9ET and _XIWc9ET["Parent"]) then
								return
							end
							pcall(function()
								_XIWc9ET:FireServer({ ["Goal"] = "Platform", ["mobile"] = _tLrQq })
							end)
							pcall(function()
								_XIWc9ET:FireServer({ ["Goal"] = "Platform", ["console"] = _SjtwfD })
							end)
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(0 + 0x2 * 6)]["apply"] = function()
								local _k5DLz5Gq, _yhMNeNZe = HubUI[(0x2 * 6 - 0)]["flags"]()
								HubUI[12]["send"](_k5DLz5Gq, _yhMNeNZe)
								local _JpjHE = HubSettings["DeviceSpoof"]["Device"]
								if _JpjHE == "Custom Icon" then
									return
								end
								task["delay"](((0 + 0x2 * 350) / 0x3e8), function()
									if
										_R5B57
										or not HubSettings["DeviceSpoof"]["Enabled"]
										or HubSettings["DeviceSpoof"]["Device"] ~= _JpjHE
									then
										return
									end
									if HubUI[12]["shown"]() == _JpjHE then
										return
									end
									local _kwkuyl = _MJSFe
									if _kwkuyl and _kwkuyl["Parent"] then
										for _NSiC3pL, _yGDPnDGR in ipairs({ " Platform ", "SetPlatform" }) do
											pcall(function()
												_kwkuyl:FireServer({ ["Goal"] = _yGDPnDGR, ["mobile"] = _k5DLz5Gq })
											end)
										end
									end
									task["wait"]((700 / 0x3e8))
									if
										_R5B57
										or not HubSettings["DeviceSpoof"]["Enabled"]
										or HubSettings["DeviceSpoof"]["Device"] ~= _JpjHE
									then
										return
									end
									if HubUI[(6 + 6)]["shown"]() ~= _JpjHE then
										_OS0SJ({
											["Title"] = "RXM HUB",
											["Description"] = "the server kept your old device ("
												.. HubUI[(0 + 0x2 * 6)]["shown"]()
												.. "). it probably only lets it change once per join, rejoin and pick the device before turning this on",
										})
									end
								end)
							end
						else
							(function()
								return (bit32 and 6978 or 0xf51b)
							end)()
						end
						HubUI[12]["restore"] = function()
							HubUI[(0x2 * 6 - 0)]["send"](HubUI[12]["real"]())
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[12]["resolveIcon"] = function(_nxfO0)
								_nxfO0 = tostring(_nxfO0 or ""):match("^%s*(.-)%s*$")
								if _nxfO0 == "" then
									return ({})[1]
								end
								if _nxfO0:match("^%d+$") then
									return "rbxassetid://" .. _nxfO0
								end
								if _nxfO0:match("^rbxassetid://") or _nxfO0:match("^rbxasset://") then
									return _nxfO0
								end
								if
									not (
										EnvAccess["getcustomasset"]
										and EnvAccess["isfile"]
										and EnvAccess["writefile"]
										and EnvAccess["readfile"]
									)
								then
									return ({})[1]
								end
								if
									EnvAccess["makefolder"]
									and EnvAccess["isfolder"]
									and not EnvAccess["isfolder"](HubUI[12]["folder"])
								then
									pcall(EnvAccess["makefolder"], "KittyWare")
									pcall(EnvAccess["makefolder"], HubUI[12]["folder"])
								end
								local _gVtHCp
								if _nxfO0:match("^https?://") then
									_gVtHCp = HubUI[(6 + 6)]["folder"] .. "/" .. _nxfO0:gsub("[^%w]", ""):sub(-40) .. ".png"
									if not EnvAccess["isfile"](_gVtHCp) then
										local _ViXGeCA = pcall(function()
											EnvAccess["writefile"](_gVtHCp, game:HttpGet(_nxfO0))
										end)
										if not _ViXGeCA then
											return ({})[1]
										end
									end
								else
									_gVtHCp = HubUI[(6 + 6)]["folder"] .. "/" .. _nxfO0
									if not EnvAccess["isfile"](_gVtHCp) then
										return ({})[1]
									end
								end
								local _GlDEJ, _vUryq = pcall(EnvAccess["getcustomasset"], _gVtHCp)
								return _GlDEJ and _vUryq or ({})[1]
							end
						else
							(function()
								return (bit32 and 28071 or 0x85b1)
							end)()
						end
						HubUI[(0 + 0x2 * 6)]["isMine"] = function(_chlf5)
							local _RMww3 = _chlf5:FindFirstChild("PlayerHeader", true)
							if not _RMww3 then
								return false
							end
							local _CKtTh = _RMww3:FindFirstChild("DisplayName", true)
							if
								_CKtTh
								and _CKtTh:IsA("TextLabel")
								and _CKtTh["Text"]:sub((1 + 0), #HubLocalPlayer["DisplayName"]) == HubLocalPlayer["DisplayName"]
							then
								return true
							end
							local _rvjjb = _RMww3:FindFirstChild("AvatarImage", true)
							return _rvjjb ~= ({})[1]
								and (_rvjjb:IsA("ImageLabel") or _rvjjb:IsA("ImageButton"))
								and tostring(_rvjjb["Image"]):find(tostring(HubLocalPlayer["UserId"]), 1, true) ~= ({})[1]
						end
						HubUI[(1 + 0x2 * 6)] = function(_Z9aQt)
							if HubUI[(0x2 * 6 - 0)]["custom"]() and _Z9aQt["Image"] ~= HubUI[(6 + 6)]["icon"] then
								_Z9aQt["Image"] = HubUI[12]["icon"]
							end
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[12]["paint"] = function(_yc44w)
								if not HubUI[12]["custom"]() then
									return
								end
								local _n7a77 = _yc44w:FindFirstChild("DeviceIcon", true)
								if not (_n7a77 and _n7a77:IsA("ImageLabel") and HubUI[12]["isMine"](_yc44w)) then
									return
								end
								HubUI[(0x2 * 7 - 1)](_n7a77)
								_l3G1i(_n7a77:GetPropertyChangedSignal("Image"), function()
									HubUI[(1 + 0x2 * 6)](_n7a77)
								end)
							end
						else
							(function()
								return (bit32 and 58270 or 0xab9e)
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(6 + 6)]["repaint"] = function()
								for _gQcxd, _VK2Dy in ipairs(PlayerGui:GetDescendants()) do
									if _VK2Dy["Name"] == "ActiveDropdown" then
										HubUI[(6 + 6)]["paint"](_VK2Dy)
									end
								end
							end
						else
							(function()
								return (bit32 and 31504 or 0xb67b)
							end)()
						end
						HubUI[(6 + 6)]["watch"] = function(_GzDh4)
							if _GzDh4 and not HubUI[(0x2 * 6 - 0)]["watching"] then
								HubUI[12]["watching"] = _l3G1i(PlayerGui["DescendantAdded"], function(_vtThH)
									if _vtThH["Name"] == "ActiveDropdown" then
										task["defer"](HubUI[12]["paint"], _vtThH)
									end
								end)
							elseif not _GzDh4 and HubUI[12]["watching"] then
								_vA5WJ(HubUI[12]["watching"])
								HubUI[12]["watching"] = false
							end
						end
						if 129 == 0x81 then
							HubUI[(0 + 0x2 * 6)]["setIcon"] = function(_cD5Pn)
								task["spawn"](function()
									HubUI[12]["icon"] = HubUI[(0x2 * 6 - 0)]["resolveIcon"](_cD5Pn)
									if _cD5Pn ~= "" and not HubUI[(6 + 6)]["icon"] then
										_OS0SJ({
											["Title"] = "RXM HUB",
											["Description"] = "couldn't load that icon (asset id, https link to a png, or a file in KittyWare/icons)",
										})
									end
									if HubUI[12]["custom"]() then
										HubUI[(0x2 * 6 - 0)]["repaint"]()
									end
								end)
							end
						else
							(function()
								return ((0x1e50 % 0x2 == 0x0) and (bit32 and 3880 or 0x0) or (bit32 and 12279 or 0x0))
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(0x2 * 7 - 0)] = { ["hooked"] = false, ["thread"] = false }
						else
							(function()
								return (bit32 and (36036 * 0x3d % 0x10000) or 0x8e6f)
							end)()
						end
						HubUI[(7 + 7)]["value"] = function()
							local _Cauj5 = HubSettings["PingSpoof"]
							return math["clamp"](
								_Cauj5["Ping"] + math["random"](-_Cauj5["Jitter"], _Cauj5["Jitter"]),
								0,
								(0 + 0x2 * 2500)
							)
						end
						HubUI[15] =
							{ ["m1Down"] = false, ["gamepadDown"] = false, ["activeTouches"] = {}, ["punchBtnHeld"] = false }
						_l3G1i(UserInputService["InputBegan"], function(_kOlNH)
							local _ZHam6 = _kOlNH["UserInputType"]
							if _ZHam6 == Enum["UserInputType"]["MouseButton1"] then
								HubUI[(15 + 0x2 * 0)]["m1Down"] = true
							elseif _ZHam6 == Enum["UserInputType"]["Touch"] then
								HubUI[(15 + 0x2 * 0)]["activeTouches"][_kOlNH] = true
							elseif
								_kOlNH["KeyCode"] == Enum["KeyCode"]["ButtonR2"]
								or _kOlNH["KeyCode"] == Enum["KeyCode"]["ButtonB"]
								or _kOlNH["KeyCode"] == Enum["KeyCode"]["ButtonX"]
							then
								HubUI[(15 + 0x2 * 0)]["gamepadDown"] = true
							end
						end)
						_l3G1i(UserInputService["InputEnded"], function(_Kxz3A)
							local _ny8fo = _Kxz3A["UserInputType"]
							if _ny8fo == Enum["UserInputType"]["MouseButton1"] then
								HubUI[(15 + 0)]["m1Down"] = false
							elseif _ny8fo == Enum["UserInputType"]["Touch"] then
								HubUI[(0x2 * 15 - 15)]["activeTouches"][_Kxz3A] = ({})[1]
							elseif
								_Kxz3A["KeyCode"] == Enum["KeyCode"]["ButtonR2"]
								or _Kxz3A["KeyCode"] == Enum["KeyCode"]["ButtonB"]
								or _Kxz3A["KeyCode"] == Enum["KeyCode"]["ButtonX"]
							then
								HubUI[(0x2 * 15 - 15)]["gamepadDown"] = false
							end
						end)
						_l3G1i(UserInputService["TouchStarted"], function(_gCaag)
							HubUI[(0x2 * 15 - 15)]["activeTouches"][_gCaag] = true
						end)
						_l3G1i(UserInputService["TouchEnded"], function(_bUio7)
							HubUI[15]["activeTouches"][_bUio7] = ({})[1]
						end)
						HubUI[(0 + 0x2 * 4)] = function()
							if
								HubUI[(15 + 0x2 * 0)]["m1Down"]
								or HubUI[(0x2 * 15 - 15)]["gamepadDown"]
								or next(HubUI[(15 + 0x2 * 0)]["activeTouches"]) ~= ({})[1]
								or HubUI[15]["punchBtnHeld"]
							then
								return true
							end
							local _nfa72, _Ak3Jf = pcall(function()
								return UserInputService:IsMouseButtonPressed(Enum["UserInputType"]["MouseButton1"])
							end)
							if _nfa72 and _Ak3Jf then
								return true
							end
							local _JJISI, _i7S7H = pcall(function()
								return UserInputService:GetTouches()
							end)
							if _JJISI and #_i7S7H > 0 then
								return true
							end
							for _rWtHK, _EubOe in ipairs({
								Enum["KeyCode"]["ButtonR2"],
								Enum["KeyCode"]["ButtonB"],
								Enum["KeyCode"]["ButtonX"],
							}) do
								local _NdA8s, _auNTp = pcall(function()
									return UserInputService:IsGamepadButtonDown(Enum["UserInputType"]["Gamepad1"], _EubOe)
								end)
								if _NdA8s and _auNTp then
									return true
								end
							end
							local _e5GmO, _nY5se = pcall(function()
								for _jzdFj, _wiqfB in ipairs(PlayerGui:GetChildren()) do
									local _RLD7J = _wiqfB:FindFirstChild("PunchButton", true)
									if _RLD7J and _RLD7J:IsA("ImageButton") and tostring(_RLD7J["Image"]):find("12253807149") then
										return true
									end
								end
								return false
							end)
							if _e5GmO and _nY5se then
								return true
							end
							return false
						end
						HubUI[14]["install"] = function()
							if HubUI[(0 + 0x2 * 7)]["hooked"] then
								return true
							end
							if
								not (
									EnvAccess["hookmetamethod"]
									and EnvAccess["newcclosure"]
									and EnvAccess["getnamecallmethod"]
									and EnvAccess["checkcaller"]
								)
							then
								return false
							end
							HubUI[14]["hooked"] = true
							local _Av3hB
							_Av3hB = EnvAccess["hookmetamethod"](
								game,
								"__namecall",
								EnvAccess["newcclosure"](function(_JbC3W, ...)
									if
										not (HubSettings["PingSpoof"]["Enabled"] or HubSettings["DeviceSpoof"]["Enabled"]) or _R5B57
									then
										return _Av3hB(_JbC3W, ...)
									end
									if EnvAccess["checkcaller"]() then
										return _Av3hB(_JbC3W, ...)
									end
									if EnvAccess["getnamecallmethod"]() ~= "FireServer" then
										return _Av3hB(_JbC3W, ...)
									end
									if
										typeof(_JbC3W) ~= "Instance"
										or _JbC3W["ClassName"] ~= "RemoteEvent"
										or _JbC3W["Name"] ~= "Communicate"
									then
										return _Av3hB(_JbC3W, ...)
									end
									local _WspHX = ...
									if EnvAccess["type"](_WspHX) ~= "table" then
										return _Av3hB(_JbC3W, ...)
									end
									local _rV73K = _WspHX["Goal"]
									local _Eq_ZF
									if _rV73K == "ReportPing" and HubSettings["PingSpoof"]["Enabled"] then
										_Eq_ZF = table["clone"](_WspHX)
										_Eq_ZF["ms"] = HubUI[14]["value"]()
									elseif
										HubSettings["DeviceSpoof"]["Enabled"]
										and (_rV73K == "Platform" or _rV73K == " Platform " or _rV73K == "SetPlatform")
									then
										local _NCLQ1, _amAq0 = HubUI[12]["flags"]()
										_Eq_ZF = table["clone"](_WspHX)
										if _Eq_ZF["mobile"] ~= ({})[1] then
											_Eq_ZF["mobile"] = _NCLQ1
										end
										if _Eq_ZF["console"] ~= ({})[1] then
											_Eq_ZF["console"] = _amAq0
										end
									elseif
										HubSettings["DeviceSpoof"]["Enabled"]
										and HubSettings["DeviceSpoof"]["Device"] ~= "Custom Icon"
										and (_rV73K == "LeftClick" or _rV73K == "LeftClickRelease")
									then
										local _jl9eX, _wOuhB = HubUI[(0 + 0x2 * 6)]["flags"]()
										local _R9wJS = _jl9eX or _wOuhB
										local _eI01z9jw = (
											UserInputService["TouchEnabled"] and not UserInputService["KeyboardEnabled"]
										)
										if _eI01z9jw then
											if _WspHX["Mobile"] ~= true then
												return
											end
											_Eq_ZF = table["clone"](_WspHX)
											if not _R9wJS then
												_Eq_ZF["Mobile"] = ({})[1]
											else
												_Eq_ZF["Mobile"] = true
											end
										elseif _R9wJS then
											_Eq_ZF = table["clone"](_WspHX)
											_Eq_ZF["Mobile"] = true
											if _rV73K == "LeftClick" and HubSettings["DeviceSpoof"]["TapClicks"] then
												task["delay"]((60 / 0x3e8), function()
													if not HubSettings["DeviceSpoof"]["TapClicks"] then
														return
													end
													if HubUI[(0 + 0x2 * 4)]() then
														return
													end
													pcall(function()
														_JbC3W:FireServer({ ["Goal"] = "LeftClickRelease", ["Mobile"] = true })
													end)
												end)
											end
										end
									end
									if _Eq_ZF then
										local _nXUHgYm, _AlgJtUCD = { ... }, select("#", ...)
										_nXUHgYm[1] = _Eq_ZF
										return _Av3hB(_JbC3W, table["unpack"](_nXUHgYm, 1, _AlgJtUCD))
									end
									return _Av3hB(_JbC3W, ...)
								end)
							)
							return true
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[14]["loop"] = function()
								if HubUI[(7 + 7)]["thread"] then
									return
								end
								HubUI[(0 + 0x2 * 7)]["thread"] = task["spawn"](function()
									while HubSettings["PingSpoof"]["Enabled"] and not _R5B57 do
										local _JENLv = _MJSFe
										if _JENLv and _JENLv["Parent"] then
											pcall(function()
												_JENLv:FireServer({
													["Goal"] = "ReportPing",
													["ms"] = HubUI[(0 + 0x2 * 7)]["value"](),
												})
											end)
										end
										task["wait"](HubSettings["PingSpoof"]["Interval"])
									end
									HubUI[(7 + 7)]["thread"] = false
								end)
							end
						else
							(function()
								return ((0xa12f % 0x2 == 0x0) and (bit32 and 20631 or 0x0) or (bit32 and 22978 or 0x0))
							end)()
						end
						if 0 == 0x0 then
							HubUI[11]["LethalMain"]:toggle({
								["name"] = "Enabled",
								["def"] = false,
								["pointer"] = "Auto Lethal Enabled",
								["callback"] = function(_Wlh1eY)
									HubSettings["AutoLethal"]["Enabled"] = _Wlh1eY
								end,
							})
						else
							(function()
								return (bit32 and 48178 or 0xba23)
							end)()
						end
						HubUI[11]["LethalMain"]:keybind({
							["name"] = "Instant Lethal KeyBind",
							["def"] = ({})[1],
							["pointer"] = "Auto Lethal KeyBind",
							["callback"] = function(_Vrxy7uV)
								_q46lU["fire"]()
							end,
						})
						HubUI[11]["LethalMain"]:toggle({
							["name"] = "Highlight Target",
							["def"] = true,
							["pointer"] = "Auto Lethal Highlight",
							["callback"] = function(_wXpWoV)
								HubSettings["AutoLethal"]["Highlight"] = _wXpWoV
							end,
						})
						if 65535 == 0xffff then
							HubUI[11]["LethalMain"]:colorpicker({
								["name"] = "Highlight Color",
								["cpname"] = "",
								["def"] = HubSettings["AutoLethal"]["HighlightColor"],
								["pointer"] = "Auto Lethal Highlight Color",
								["callback"] = function(_n3MpS)
									HubSettings["AutoLethal"]["HighlightColor"] = _n3MpS
								end,
							})
						else
							(function()
								return ((0x370d % 0x2 == 0x0) and (bit32 and 7046 or 0x0) or (bit32 and 29505 or 0x0))
							end)()
						end
						HubUI[11]["LethalTiming"]:slider({
							["name"] = "Lethal Precision",
							["def"] = (19 + 16),
							["max"] = (0x2 * 50 - 0),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Auto Lethal Precision",
							["callback"] = function(_aK8RUu)
								HubSettings["AutoLethal"]["Precision"] = _aK8RUu / (0 + 0x2 * 50)
							end,
						})
						HubUI[11]["LethalTiming"]:slider({
							["name"] = "Lethal First Flick Angle",
							["def"] = 0,
							["max"] = (180 + 180),
							["min"] = -(0 + 0x2 * 180),
							["rounding"] = true,
							["pointer"] = "Auto Lethal First Flick",
							["callback"] = function(_QCajli)
								HubSettings["AutoLethal"]["FirstFlickAngle"] = _QCajli
							end,
						})
						HubUI[11]["LethalTiming"]:slider({
							["name"] = "Lethal Second Flick Delay",
							["def"] = 4,
							["max"] = 20,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Auto Lethal Second Flick",
							["callback"] = function(_FxT9_9a)
								HubSettings["AutoLethal"]["SecondFlick"] = _FxT9_9a / (0 + 0x2 * 50)
							end,
						})
						if 1 == 0x1 then
							HubUI[11]["LethalTiming"]:toggle({
								["name"] = "Lethal Jump",
								["def"] = true,
								["pointer"] = "Auto Lethal Jump",
								["callback"] = function(_upr69IKk)
									HubSettings["AutoLethal"]["Jump"] = _upr69IKk
								end,
							})
						else
							(function()
								return (bit32 and 33456 or 0x9282)
							end)()
						end
						HubUI[11]["LethalTiming"]:toggle({
							["name"] = "Lethal Rotate Camera",
							["def"] = false,
							["pointer"] = "Auto Lethal Rotate Camera",
							["tooltip"] = "turns the camera with you during the lethal flicks, not just your character",
							["callback"] = function(_XUPbW)
								HubSettings["AutoLethal"]["RotateCam"] = _XUPbW
							end,
						})
						HubUI[11]["PingSpoof"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Ping Spoofer Enabled",
							["tooltip"] = "changes the ping other players see on your profile card / leaderboard. updates on the game's next ping report (within 5s)",
							["callback"] = function(_M3RCm)
								if _M3RCm and not HubUI[(0 + 0x2 * 7)]["install"]() then
									HubSettings["PingSpoof"]["Enabled"] = false
									_OS0SJ({
										["Title"] = "RXM HUB",
										["Description"] = "your executor has no hookmetamethod, ping spoofer can't run",
									})
									return
								end
								HubSettings["PingSpoof"]["Enabled"] = _M3RCm
								if _M3RCm then
									HubUI[14]["loop"]()
								end
							end,
						})
						HubUI[11]["PingSpoof"]:slider({
							["name"] = "Ping",
							["def"] = HubSettings["PingSpoof"]["Ping"],
							["max"] = (0x2 * 2500 - 0),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Ping Spoofer Ping",
							["tooltip"] = "the ping (ms) that gets reported",
							["callback"] = function(_B4_yB)
								HubSettings["PingSpoof"]["Ping"] = _B4_yB
							end,
						})
						HubUI[(3 + 0x2 * 4)]["PingSpoof"]:slider({
							["name"] = "Jitter",
							["def"] = HubSettings["PingSpoof"]["Jitter"],
							["max"] = 50,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Ping Spoofer Jitter",
							["tooltip"] = "random +/- ms on every report so it doesn't sit on one number",
							["callback"] = function(_qR51K)
								HubSettings["PingSpoof"]["Jitter"] = _qR51K
							end,
						})
						HubUI[11]["PingSpoof"]:slider({
							["name"] = "Report Rate (x0.1s)",
							["def"] = math["floor"](HubSettings["PingSpoof"]["Interval"] * (0 + 0x2 * 5)),
							["max"] = 50,
							["min"] = 2,
							["rounding"] = true,
							["pointer"] = "Ping Spoofer Rate",
							["tooltip"] = "how often the fake ping is sent. 10 = every 1s, 2 = every 0.2s (the game itself only reports every 5s)",
							["callback"] = function(_fxxfw)
								HubSettings["PingSpoof"]["Interval"] = _fxxfw / 10
							end,
						})
						HubUI[11]["DeviceSpoof"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Device Spoofer Enabled",
							["tooltip"] = "changes the device icon other players see on your profile card / leaderboard",
							["callback"] = function(_UCEG_)
								if _UCEG_ and not HubUI[14]["install"]() then
									HubSettings["DeviceSpoof"]["Enabled"] = false
									_OS0SJ({
										["Title"] = "RXM HUB",
										["Description"] = "your executor has no hookmetamethod, device spoofer can't run",
									})
									return
								end
								HubSettings["DeviceSpoof"]["Enabled"] = _UCEG_
								HubUI[12]["watch"](_UCEG_ and HubSettings["DeviceSpoof"]["Device"] == "Custom Icon")
								if _UCEG_ then
									HubUI[(0x2 * 6 - 0)]["apply"]()
									HubUI[(0 + 0x2 * 6)]["repaint"]()
								else
									HubUI[(6 + 6)]["restore"]()
								end
							end,
						})
						HubUI[(7 + 4)]["DeviceSpoof"]:toggle({
							["name"] = "Tap Clicks",
							["def"] = HubSettings["DeviceSpoof"]["TapClicks"],
							["pointer"] = "Device Spoofer Tap Clicks",
							["tooltip"] = "for mobile / console: sends the click release right after each click so it doesnt keep auto hitting. turn it off if you want clicks held like normal",
							["callback"] = function(_JrWeP)
								HubSettings["DeviceSpoof"]["TapClicks"] = _JrWeP
							end,
						})
						HubUI[11]["DeviceSpoof"]:dropdown({
							["name"] = "Device",
							["def"] = HubSettings["DeviceSpoof"]["Device"],
							["max"] = 4,
							["options"] = { "PC", "Mobile", "Console", "Custom Icon" },
							["pointer"] = "Device Spoofer Device",
							["callback"] = function(_mPxvd)
								HubSettings["DeviceSpoof"]["Device"] = _mPxvd
								if HubSettings["DeviceSpoof"]["Enabled"] then
									HubUI[12]["watch"](_mPxvd == "Custom Icon")
									HubUI[12]["apply"]()
									HubUI[12]["repaint"]()
								end
							end,
						})
						HubUI[11]["DeviceSpoof"]:textbox({
							["name"] = "Custom Icon",
							["def"] = "",
							["placeholder"] = "id, https link or file",
							["pointer"] = "Device Spoofer Icon",
							["tooltip"] = "used when Device is Custom Icon. asset id (123456), a direct https link to a png (downloaded once), or a file you put in workspace/KittyWare/icons. only YOU see it, other players' screens draw the real icon",
							["callback"] = function(_bWGoo)
								HubSettings["DeviceSpoof"]["Icon"] = _bWGoo
								HubUI[(6 + 6)]["setIcon"](_bWGoo)
							end,
						})
						if 16 == 0x10 then
							HubUI[16] = (
								HubUI[(5 + 4)]
								and HubUI[(0x2 * 5 - 1)]["isMobile"] ~= ({})[1]
								and HubUI[(0x2 * 5 - 1)]["isMobile"]
							)
								or (UserInputService["TouchEnabled"] and not UserInputService["KeyboardEnabled"])
								or (_AuGxA["ViewportSize"]["X"] < (0x2 * 450 - 0) and UserInputService["TouchEnabled"])
						else
							(function()
								return (bit32 and (13400 * 0x3d % 0x10000) or 0x3f8e)
							end)()
						end
						HubUI[(7 + 0x2 * 0)] = function()
							if HubUI[9] and HubUI[9]["optimizemobile"] then
								HubUI[9]:optimizemobile(true)
							end
						end
						if 129 == 0x81 then
							HubUI[17] = function(_us_RA)
								if HubUI[9] and HubUI[9]["togglemobilebutton"] then
									HubUI[9]:togglemobilebutton(_us_RA)
								end
							end
						else
							(function()
								return (bit32 and 57199 or 0x8e4f)
							end)()
						end
						if HubUI[16] then
							if 65535 == 0xffff then
								task["defer"](function()
									HubUI[(0x2 * 7 - 7)]()
									HubUI[(9 + 8)](true)
								end)
							else
								(function()
									return (bit32 and 45815 or 0xc2af)
								end)()
							end
						end
						HubUI[(7 + 4)]["AutoBlockToggle"] = HubUI[11]["AutoBlock"]:toggle({
							["name"] = "Enabled",
							["def"] = HubSettings["Autoblock"]["Enabled"],
							["pointer"] = "Auto Block Toggle",
							["callback"] = function(_jyYHl)
								HubSettings["Autoblock"]["Enabled"] = _jyYHl
							end,
						})
						if 16 == 0x10 then
							HubUI[11]["AutoBlockHold"] = false
						else
							(function()
								return (bit32 and 17432 or 0xd41f)
							end)()
						end
						HubUI[11]["AutoBlockKey"] = HubUI[(7 + 4)]["AutoBlock"]:keybind({
							["name"] = "Auto Block Keybind",
							["def"] = ({})[1],
							["pointer"] = "Auto Block Keybind",
							["callback"] = function(_MWnfr)
								if _R5B57 then
									return
								end
								local _BMbef
								if HubUI[11]["AutoBlockHold"] then
									_BMbef = true
								else
									_BMbef = not HubSettings["Autoblock"]["Enabled"]
								end
								HubUI[(3 + 0x2 * 4)]["AutoBlockToggle"]:set(_BMbef)
								if not HubUI[11]["AutoBlockHold"] then
									_OS0SJ({
										["Title"] = "RXM HUB",
										["Description"] = "Auto Block " .. (_BMbef and "on" or "off"),
										["Source"] = "Auto Block",
									})
								end
							end,
						})
						if 0 == 0x0 then
							HubUI[(0x2 * 7 - 3)]["AutoBlock"]:toggle({
								["name"] = "Keybind: Hold",
								["def"] = false,
								["pointer"] = "Auto Block Keybind Hold",
								["tooltip"] = "off = the keybind turns auto block on / off. on = auto block is only on while you hold the key",
								["callback"] = function(_qVcx6)
									HubUI[(3 + 0x2 * 4)]["AutoBlockHold"] = _qVcx6
								end,
							})
						else
							(function()
								return (bit32 and 26470 or 0xe867)
							end)()
						end
						_l3G1i(UserInputService["InputEnded"], function(_fnSEV)
							if not HubUI[11]["AutoBlockHold"] or not HubSettings["Autoblock"]["Enabled"] then
								return
							end
							local _U7L11 = HubUI[(7 + 4)]["AutoBlockKey"]["current"]
							if not _U7L11 then
								return
							end
							if
								(_U7L11[1] == "KeyCode" and _fnSEV["KeyCode"]["Name"] == _U7L11[(1 + 1)])
								or (
									_U7L11[(0x2 * 1 - 1)] == "UserInputType"
									and _fnSEV["UserInputType"]["Name"] == _U7L11[(0 + 0x2 * 1)]
								)
							then
								HubUI[(7 + 4)]["AutoBlockToggle"]:set(false)
							end
						end)
						if 129 == 0x81 then
							HubUI[(0x2 * 7 - 3)]["AutoBlock"]:toggle({
								["name"] = "Auto m1 Punish",
								["def"] = HubSettings["Autoblock"]["AutoM1"],
								["pointer"] = "AutoM1",
								["callback"] = function(_Jpv8P)
									HubSettings["Autoblock"]["AutoM1"] = _Jpv8P
								end,
							})
						else
							(function()
								return (bit32 and 56190 or 0xdf66)
							end)()
						end
						HubUI[11]["AutoBlock"]:toggle({
							["name"] = "Auto Counter",
							["def"] = HubSettings["Autoblock"]["AutoCounter"],
							["pointer"] = "Autocounter",
							["callback"] = function(_m6yW6)
								HubSettings["Autoblock"]["AutoCounter"] = _m6yW6
							end,
						})
						if 0 == 0x0 then
							HubUI[11]["AutoBlock"]:toggle({
								["name"] = "Dash Prediction",
								["def"] = HubSettings["Autoblock"]["DashPredict"],
								["pointer"] = "Dash Prediction Enabled",
								["tooltip"] = "Makes autoblock respond to side dashes",
								["callback"] = function(_bZJR0)
									HubSettings["Autoblock"]["DashPredict"] = _bZJR0
								end,
							})
						else
							(function()
								return (bit32 and (22009 * 0x3d % 0x10000) or 0x66fc)
							end)()
						end
						if 16 == 0x10 then
							HubUI[11]["AutoBlock"]:toggle({
								["name"] = "Rotate Character",
								["def"] = HubSettings["Autoblock"]["RotateChar"],
								["pointer"] = "Character Easing Toggle",
								["callback"] = function(_QjWDA)
									HubSettings["Autoblock"]["RotateChar"] = _QjWDA
								end,
							})
						else
							(function()
								return (bit32 and 51551 or 0x23c6)
							end)()
						end
						HubUI[11]["AutoBlock"]:toggle({
							["name"] = "Rotate Camera",
							["def"] = HubSettings["Autoblock"]["RotateCam"],
							["pointer"] = "Cam Easing Toggle",
							["callback"] = function(_FCY9A)
								HubSettings["Autoblock"]["RotateCam"] = _FCY9A
							end,
						})
						if 0 == 0x0 then
							HubUI[(0x2 * 7 - 3)]["AutoBlock"]:slider({
								["name"] = "Camera Easing",
								["def"] = 0,
								["max"] = 100,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Cam Easing",
								["callback"] = function(_CMqsl)
									HubSettings["Autoblock"]["CamEasing"] = _CMqsl / 1000
								end,
							})
						else
							(function()
								return (bit32 and 4940 or 0x1b5c)
							end)()
						end
						HubUI[(0x2 * 7 - 3)]["AutoBlock"]:slider({
							["name"] = "Character Easing",
							["def"] = (50 + 50),
							["max"] = 100,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Char Easing",
							["callback"] = function(_Nx6JP)
								HubSettings["Autoblock"]["CharEasing"] = _Nx6JP / (0 + 0x2 * 500)
							end,
						})
						if 0 == 0x0 then
							HubUI[11]["MiscCombat"]:toggle({
								["name"] = "Friend Check",
								["def"] = HubSettings["Misc"]["FriendCheck"],
								["pointer"] = "Friend Check",
								["callback"] = function(_YkNAw)
									HubSettings["Misc"]["FriendCheck"] = _YkNAw
								end,
							})
						else
							(function()
								return (bit32 and (9507 * 0x3d % 0x10000) or 0x2912)
							end)()
						end
						HubUI[11]["MiscCombat"]:toggle({
							["name"] = "No Dash Endlag",
							["def"] = HubSettings["Misc"]["NoDashEndLag"],
							["pointer"] = "No Dash Endlag",
							["tooltip"] = "Disables the eng lag on end of the dash that doesn't let you to dash again",
							["callback"] = function(_v_aX_)
								HubSettings["Misc"]["NoDashEndLag"] = _v_aX_
							end,
						})
						_KjGi0a["stop"] = function()
							if _KjGi0a["conn"] then
								_vA5WJ(_KjGi0a["conn"])
								_KjGi0a["conn"] = ({})[1]
							end
						end
						_KjGi0a["getTarget"] = function()
							local _G41b6 = ({})[1]
							local _Rsthx = HubSettings["Misc"]["Magnet"]["MaxDistance"] or (0x2 * 50 - 0)
							if not (_Z0Hry and _fx2la) then
								return ({})[1]
							end
							local _Nhsov = _fx2la["Position"]
							if _f5mDQ and _f5mDQ["Live"] then
								for _i7IOu, _DWt9E in ipairs(_f5mDQ["Live"]:GetChildren()) do
									if _DWt9E ~= _Z0Hry and _DWt9E:IsA("Model") then
										local _M1L16 = PlayersService:GetPlayerFromCharacter(_DWt9E)
										if not _JrRW2(_M1L16, true) then
											local _hDQ7L = _DWt9E:FindFirstChild("HumanoidRootPart")
											local _CtmWK = _DWt9E:FindFirstChildOfClass("Humanoid")
											if _hDQ7L and _CtmWK and _CtmWK["Health"] > 0 then
												local _Xh6pl = (_Nhsov - _hDQ7L["Position"])["Magnitude"]
												if _Xh6pl < _Rsthx and _Xh6pl > (100 / 0x3e8) then
													_Rsthx = _Xh6pl
													_G41b6 = _hDQ7L
												end
											end
										end
									end
								end
							end
							if not _G41b6 then
								for _sWYy7, _NKHuy in ipairs(PlayersService:GetPlayers()) do
									if _NKHuy ~= HubLocalPlayer and _NKHuy["Character"] and _NKHuy["Character"] ~= _Z0Hry then
										if not _JrRW2(_NKHuy, true) then
											local _iARSC = _NKHuy["Character"]
											local _PbMqV = _iARSC:FindFirstChild("HumanoidRootPart")
											local _kyNpd = _iARSC:FindFirstChildOfClass("Humanoid")
											if _PbMqV and _kyNpd and _kyNpd["Health"] > 0 then
												local _FJn4q = (_Nhsov - _PbMqV["Position"])["Magnitude"]
												if _FJn4q < _Rsthx and _FJn4q > (100 / 0x3e8) then
													_Rsthx = _FJn4q
													_G41b6 = _PbMqV
												end
											end
										end
									end
								end
							end
							return _G41b6
						end
						_KjGi0a["onStep"] = function()
							if not HubSettings["Misc"]["Magnet"]["Enabled"] or _R5B57 then
								_KjGi0a["stop"]()
								return
							end
							if not (_Z0Hry and _fx2la and _y4IB9 and _y4IB9["Health"] > 0) then
								_KjGi0a["stop"]()
								return
							end
							local _aU_Kn = tick() - _KjGi0a["startTime"]
							if _aU_Kn >= _KjGi0a["duration"] then
								_KjGi0a["stop"]()
								return
							end
							local _v5qpL = (
								_KjGi0a["targetOverride"]
								and _KjGi0a["targetOverride"]["Parent"]
								and _KjGi0a["targetOverride"]
							) or _KjGi0a["getTarget"]()
							if not _v5qpL then
								return
							end
							local _QrLPs = _fx2la["Position"]
							local _Zjbcm = Vector3["new"](_v5qpL["Position"]["X"], _QrLPs["Y"], _v5qpL["Position"]["Z"])
							local _uAi658 = (_Zjbcm - _QrLPs)
							local _PJlwRBT = _uAi658["Magnitude"]
							if _PJlwRBT > 1 then
								_uAi658 = _uAi658["Unit"]
								local _k2f_AHiI = _uAi658 * _KjGi0a["strength"]
								local _Fg9HV = _fx2la["AssemblyLinearVelocity"]
								local _at_zrT = _Fg9HV:Lerp(_k2f_AHiI, _KjGi0a["smoothness"])
								_fx2la["AssemblyLinearVelocity"] = Vector3["new"](
									_at_zrT["X"] * ((0x2 * 425 - 0) / 0x3e8),
									_Fg9HV["Y"],
									_at_zrT["Z"] * ((0 + 0x2 * 425) / 0x3e8)
								)
							end
						end
						if 65535 == 0xffff then
							_KjGi0a["startPull"] = function(_HZGJEc5)
								_KjGi0a["stop"]()
								_KjGi0a["startTime"] = tick()
								_KjGi0a["duration"] = HubSettings["Misc"]["Magnet"]["Duration"] or ((250 + 250) / 0x3e8)
								_KjGi0a["strength"] = HubSettings["Misc"]["Magnet"]["Strength"] or 50
								_KjGi0a["smoothness"] = HubSettings["Misc"]["Magnet"]["Smoothness"] or (650 / 0x3e8)
								_KjGi0a["targetOverride"] = _HZGJEc5
								_KjGi0a["onStep"]()
								_KjGi0a["conn"] = _l3G1i(RunService["Heartbeat"], _KjGi0a["onStep"])
							end
						else
							(function()
								return ((0xc7dc % 0x2 == 0x0) and (bit32 and 25582 or 0x0) or (bit32 and 58227 or 0x0))
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							_KjGi0a["execute"] = function(_YbCrBK)
								if not HubSettings["Misc"]["Magnet"]["Enabled"] then
									return
								end
								local _DoIR7 = _Z0Hry or HubLocalPlayer["Character"]
								if not _DoIR7 then
									return
								end
								local _iOwuZQ70 = _y4IB9 or _DoIR7:FindFirstChildOfClass("Humanoid")
								local _NB0VKPa = _fx2la or _DoIR7:FindFirstChild("HumanoidRootPart")
								if not (_iOwuZQ70 and _NB0VKPa and _iOwuZQ70["Health"] > 0 and _DoIR7["Parent"]) then
									return
								end
								if HubSettings["Misc"]["Magnet"]["DashCancel"] then
									for _skuSTt, _X8nIm in ipairs(_Z0Hry:GetChildren()) do
										if _X8nIm:IsA("BodyVelocity") or _X8nIm:IsA("LinearVelocity") then
											_X8nIm:Destroy()
										end
									end
									for _OfQ5KpEY, _toqAw in ipairs(_fx2la:GetChildren()) do
										if _toqAw:IsA("BodyVelocity") or _toqAw:IsA("LinearVelocity") then
											_toqAw:Destroy()
										end
									end
									local _YKNHY = _fx2la["AssemblyLinearVelocity"]
									_fx2la["AssemblyLinearVelocity"] = Vector3["new"](0, _YKNHY["Y"], 0)
								end
								local _CPqxT = (_YbCrBK and _YbCrBK["Parent"] and _YbCrBK) or _KjGi0a["getTarget"]()
								if _CPqxT then
									local _jndhg = HubSettings["Misc"]["Magnet"]["Height"] or 2
									local _MlDSK = _CPqxT["Position"] + Vector3["new"](0, _jndhg, 0)
									_fx2la["CFrame"] = CFrame["new"](_MlDSK["X"], _MlDSK["Y"], _MlDSK["Z"])
									_KjGi0a["startPull"](_CPqxT)
								end
							end
						else
							(function()
								return (bit32 and 978275879 or 0x3f6)
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							_FUndW = function(_hZhtR, _KIUwT)
								if not HubSettings["Misc"]["Magnet"]["Enabled"] then
									return
								end
								local _rwLM_ = HubSettings["Misc"]["Magnet"]["TechTrigger"]
								if not _rwLM_ or _rwLM_ == "Disabled" or _rwLM_ == "None" then
									return
								end
								local _U42Pi = false
								if _rwLM_ == "All 3" or _rwLM_ == "All" then
									_U42Pi = (_hZhtR == "Loop Dash v2" or _hZhtR == "Custom Dash" or _hZhtR == "Custom Dash v2")
								else
									_U42Pi = (_hZhtR == _rwLM_)
								end
								if _U42Pi then
									task["spawn"](function()
										local _BxW5v = HubSettings["Misc"]["Magnet"]["TechDelay"] or 0
										if _BxW5v > 0 then
											task["wait"](_BxW5v / 1000)
										end
										_KjGi0a["execute"](_KIUwT)
									end)
								end
							end
						else
							(function()
								return (bit32 and 23781 or 0x7967)
							end)()
						end
						HubUI[11]["MiscCombat"]:toggle({
							["name"] = "Auto Magnet",
							["def"] = HubSettings["Misc"]["Magnet"]["Enabled"],
							["pointer"] = "Magnet Enabled",
							["tooltip"] = "Teleports above closest target and pulls towards them",
							["callback"] = function(_eBDUW)
								HubSettings["Misc"]["Magnet"]["Enabled"] = _eBDUW
								if not _eBDUW then
									_KjGi0a["stop"]()
								end
							end,
						})
						HubUI[(0x2 * 7 - 3)]["MiscCombat"]:keybind({
							["name"] = "Magnet Keybind",
							["def"] = ({})[1],
							["pointer"] = "Magnet Keybind",
							["tooltip"] = "Press to activate teleport and magnet pull",
							["callback"] = function(_L010k)
								_KjGi0a["execute"]()
							end,
						})
						HubUI[(0x2 * 7 - 3)]["MiscCombat"]:dropdown({
							["name"] = "Tech Trigger",
							["def"] = HubSettings["Misc"]["Magnet"]["TechTrigger"],
							["max"] = 5,
							["options"] = { "Disabled", "Loop Dash v2", "Custom Dash", "Custom Dash v2", "All 3" },
							["pointer"] = "Magnet Tech Trigger",
							["tooltip"] = "Automatically triggers magnet after selected uppercut tech",
							["callback"] = function(_AUGzw)
								HubSettings["Misc"]["Magnet"]["TechTrigger"] = _AUGzw
							end,
						})
						HubUI[(3 + 0x2 * 4)]["MiscCombat"]:slider({
							["name"] = "Tech Delay",
							["def"] = HubSettings["Misc"]["Magnet"]["TechDelay"],
							["max"] = (0x2 * 250 - 0),
							["min"] = 0,
							["rounding"] = true,
							["measurement"] = "ms",
							["pointer"] = "Magnet Tech Delay",
							["tooltip"] = "Delay before magnet activates after uppercut hit (0ms = instant on hit)",
							["callback"] = function(_hv01I)
								HubSettings["Misc"]["Magnet"]["TechDelay"] = _hv01I
							end,
						})
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[11]["MiscCombat"]:slider({
								["name"] = "Pull Duration",
								["def"] = math["floor"](HubSettings["Misc"]["Magnet"]["Duration"] * (0 + 0x2 * 500)),
								["max"] = 2000,
								["min"] = 100,
								["rounding"] = true,
								["measurement"] = "ms",
								["pointer"] = "Magnet Duration",
								["tooltip"] = "Duration of the magnet pull (100ms - 2000ms)",
								["callback"] = function(_Kf__L)
									HubSettings["Misc"]["Magnet"]["Duration"] = _Kf__L / 1000
								end,
							})
						else
							(function()
								return (bit32 and 64096 or 0xb260)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["MiscCombat"]:slider({
							["name"] = "TP Height",
							["def"] = HubSettings["Misc"]["Magnet"]["Height"],
							["max"] = 15,
							["min"] = 0,
							["rounding"] = true,
							["measurement"] = " studs",
							["pointer"] = "Magnet Height",
							["tooltip"] = "Height in studs above target to teleport",
							["callback"] = function(_rmFhb)
								HubSettings["Misc"]["Magnet"]["Height"] = _rmFhb
							end,
						})
						HubUI[(7 + 4)]["MiscCombat"]:slider({
							["name"] = "Pull Strength",
							["def"] = HubSettings["Misc"]["Magnet"]["Strength"],
							["max"] = 150,
							["min"] = (0 + 0x2 * 5),
							["rounding"] = true,
							["pointer"] = "Magnet Strength",
							["tooltip"] = "Strength and velocity of the magnet pull",
							["callback"] = function(_UBMYH)
								HubSettings["Misc"]["Magnet"]["Strength"] = _UBMYH
							end,
						})
						HubUI[(0x2 * 7 - 3)]["MiscCombat"]:slider({
							["name"] = "Max Distance",
							["def"] = HubSettings["Misc"]["Magnet"]["MaxDistance"],
							["max"] = (0x2 * 150 - 0),
							["min"] = (0x2 * 5 - 0),
							["rounding"] = true,
							["measurement"] = " studs",
							["pointer"] = "Magnet Distance",
							["tooltip"] = "Maximum distance to detect targets",
							["callback"] = function(_B1_zz)
								HubSettings["Misc"]["Magnet"]["MaxDistance"] = _B1_zz
							end,
						})
						HubUI[11]["MiscCombat"]:toggle({
							["name"] = "Dash Cancel",
							["def"] = HubSettings["Misc"]["Magnet"]["DashCancel"],
							["pointer"] = "Magnet Dash Cancel",
							["tooltip"] = "Cancels active dash velocity when activating magnet",
							["callback"] = function(_S2sFP)
								HubSettings["Misc"]["Magnet"]["DashCancel"] = _S2sFP
							end,
						})
						HubUI[(0x2 * 7 - 3)]["TrueDownSlam"]:toggle({
							["name"] = "Enabled",
							["def"] = HubSettings["Misc"]["TDSEnabled"],
							["pointer"] = "TDS Enabled",
							["callback"] = function(_zdk_s)
								HubSettings["Misc"]["TDSEnabled"] = _zdk_s
							end,
						})
						HubUI[11]["TrueDownSlam"]:keybind({
							["name"] = "True Down Slam Jump",
							["def"] = ({})[1],
							["pointer"] = "TDS KeyBind",
							["callback"] = function(_cizPv)
								if not HubSettings["Misc"]["TDSEnabled"] then
									return
								end
								local _JGVcB = _Z0Hry or HubLocalPlayer["Character"]
								if not _JGVcB then
									return
								end
								local _KXfwV = _y4IB9 or _JGVcB:FindFirstChildOfClass("Humanoid")
								local _dkUvb = _fx2la or _JGVcB:FindFirstChild("HumanoidRootPart")
								if not (_KXfwV and _dkUvb and _KXfwV["Health"] > 0 and _JGVcB["Parent"]) then
									return
								end
								local _oQeYG = _JGVcB:FindFirstChild("NoJump")
								if _oQeYG then
									task["defer"](_oQeYG["Destroy"], _oQeYG)
								end
								_KXfwV:ChangeState(Enum["HumanoidStateType"]["Jumping"])
								task["wait"](((5 + 5) / 0x3e8))
								if _dkUvb and _dkUvb["Parent"] then
									_dkUvb["Velocity"] = Vector3["new"](_dkUvb["Velocity"]["X"], 35, _dkUvb["Velocity"]["Z"])
								end
								_SVwyf()
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["AutoTech"]:toggle({
								["name"] = "Enabled",
								["def"] = HubSettings["AutoTech"]["Enabled"],
								["pointer"] = "Auto Tech Toggle",
								["callback"] = function(_HeQlv)
									HubSettings["AutoTech"]["Enabled"] = _HeQlv
								end,
							})
						else
							(function()
								return (bit32 and (37499 * 0x3d % 0x10000) or 0x976a)
							end)()
						end
						HubUI[(7 + 4)]["AutoTech"]:dropdown({
							["name"] = "Auto Tech Variant",
							["def"] = HubSettings["AutoTech"]["Tech"],
							["max"] = 7,
							["options"] = {
								"Kiba",
								"Supa",
								"Lock On Dash",
								"Loop Dash",
								"Loop Dash v2",
								"Custom Dash",
								"Custom Dash v2",
							},
							["pointer"] = "Auto Tech Variant",
							["callback"] = function(_euHg6)
								HubSettings["AutoTech"]["Tech"] = _euHg6
							end,
						})
						HubUI[(7 + 4)]["AutoTech"]:dropdown({
							["name"] = "Auto Tech Method",
							["def"] = HubSettings["AutoTech"]["Method"],
							["max"] = (1 + 1),
							["options"] = { "Perform Always", "Perform Once" },
							["pointer"] = "Auto Tech Method",
							["callback"] = function(_xHeVk)
								HubSettings["AutoTech"]["Method"] = _xHeVk
							end,
						})
						HubUI[11]["AutoTech"]:dropdown({
							["name"] = "Target Part",
							["def"] = HubSettings["AutoTech"]["TargetPart"],
							["max"] = 3,
							["options"] = { "HumanoidRootPart", "Torso", "Head" },
							["pointer"] = "Auto Tech Target Part",
							["tooltip"] = "What auto tech, custom dash, auto lethal and lock on aim at",
							["callback"] = function(_UXilF)
								HubSettings["AutoTech"]["TargetPart"] = _UXilF
							end,
						})
						HubUI[(7 + 4)]["AutoTech"]:keybind({
							["name"] = "Single Perform Keybind",
							["def"] = HubSettings["AutoTech"]["PerformOnce"],
							["pointer"] = "Single Perform Keybind",
							["callback"] = function(_nlIDY)
								_xQp2C(_i3Z2l)
								HubSettings["AutoTech"]["PerformOnce"] = true
								_OS0SJ({
									["Title"] = "RXM HUB",
									["Description"] = "Auto Tech will perform once on the next opportunity.",
									["Image"] = _N4Idm(HubLocalPlayer),
									["Source"] = "Auto Tech",
								})
								_i3Z2l = task["delay"]((0x2 * 3 - 1), function()
									HubSettings["AutoTech"]["PerformOnce"] = false
									_OS0SJ({
										["Title"] = "RXM HUB",
										["Description"] = "Auto Tech turned off.",
										["Image"] = _N4Idm(HubLocalPlayer),
										["Source"] = "Auto Tech",
									})
								end)
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["TechSettings"]:slider({
								["name"] = "Loop v2 Precision",
								["def"] = (3 + 0x2 * 16),
								["max"] = (0 + 0x2 * 50),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Precision",
								["callback"] = function(_KBPFi)
									HubSettings["AutoTech"]["Loopv2"]["Precision"] = _KBPFi / (0 + 0x2 * 50)
								end,
							})
						else
							(function()
								return (bit32 and 11839 or 0x1e2e)
							end)()
						end
						HubUI[11]["TechSettings"]:slider({
							["name"] = "Loop v2 First Flick Angle",
							["def"] = 0,
							["max"] = (0 + 0x2 * 180),
							["min"] = -360,
							["rounding"] = true,
							["pointer"] = "1 Flick Delay",
							["callback"] = function(_pNM3A)
								HubSettings["AutoTech"]["Loopv2"]["FirstFlickAngle"] = _pNM3A
							end,
						})
						if 65535 == 0xffff then
							HubUI[11]["TechSettings"]:slider({
								["name"] = "Loop v2 Second Flick Delay",
								["def"] = 5,
								["max"] = (0x2 * 25 - 0),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Flick Delay",
								["callback"] = function(_MjXPU)
									HubSettings["AutoTech"]["Loopv2"]["SecondFlick"] = _MjXPU / (0 + 0x2 * 50)
								end,
							})
						else
							(function()
								return (bit32 and 57729 or 0xa0e1)
							end)()
						end
						HubUI[(0x2 * 7 - 3)]["TechSettings"]:toggle({
							["name"] = "Loop v2 Jump",
							["def"] = HubSettings["AutoTech"]["Loopv2"]["Jump"],
							["pointer"] = "Loop Jump",
							["callback"] = function(_f93Ka)
								HubSettings["AutoTech"]["Loopv2"]["Jump"] = _f93Ka
							end,
						})
						HubUI[11]["TechSettings"]:toggle({
							["name"] = "Loop v2 Rotate Camera",
							["def"] = HubSettings["AutoTech"]["Loopv2"]["RotateCam"],
							["pointer"] = "Loop Rotate Camera",
							["callback"] = function(_zKs9F)
								HubSettings["AutoTech"]["Loopv2"]["RotateCam"] = _zKs9F
							end,
						})
						if 1 == 0x1 then
							HubUI[(0x2 * 7 - 3)]["TechSettings"]:slider({
								["name"] = "Lockon Dash Precision",
								["def"] = (50 + 50),
								["max"] = (50 + 50),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Lockon Precision",
								["callback"] = function(_UnJM0)
									HubSettings["AutoTech"]["LockonPrecision"] = _UnJM0 / 1000
								end,
							})
						else
							(function()
								return (bit32 and (45146 * 0x3d % 0x10000) or 0x9e90)
							end)()
						end
						if 65535 == 0xffff then
							HubUI[(0x2 * 7 - 3)]["TechSettings"]:toggle({
								["name"] = "Supa Uses Heartbeat",
								["def"] = false,
								["pointer"] = "Supa Method",
								["tooltip"] = "Uses more smooth method for Supa",
								["callback"] = function(_ti6sc)
									if _ti6sc then
										HubSettings["AutoTech"]["SupaMethod"] = "Heartbeat"
									else
										HubSettings["AutoTech"]["SupaMethod"] = "RenderStepped"
									end
								end,
							})
						else
							(function()
								return ((0x7403 % 0x2 == 0x0) and (bit32 and 14849 or 0x0) or (bit32 and 42896 or 0x0))
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["TechSettings"]:toggle({
							["name"] = "Loop Dash Looks Up",
							["def"] = false,
							["pointer"] = "Loop Dash Looks Up",
							["tooltip"] = "Makes the loop dash look up so it lands 95% of the time, looks unlegit",
							["callback"] = function(_C4xvz)
								HubSettings["AutoTech"]["LoopDashLooksUp"] = _C4xvz
							end,
						})
						HubUI[11]["CustomDash"]:toggle({
							["name"] = "Jump",
							["def"] = HubSettings["AutoTech"]["Customdash"]["Jump"],
							["pointer"] = "Custom Dash Jump",
							["callback"] = function(_T6wpH)
								HubSettings["AutoTech"]["Customdash"]["Jump"] = _T6wpH
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["CustomDash"]:toggle({
								["name"] = "Rotate Camera",
								["def"] = HubSettings["AutoTech"]["Customdash"]["RotateCam"],
								["pointer"] = "Custom Dash Rotate Camera",
								["callback"] = function(_oJlN4)
									HubSettings["AutoTech"]["Customdash"]["RotateCam"] = _oJlN4
								end,
							})
						else
							(function()
								return (bit32 and (44749 * 0x3d % 0x10000) or 0xafaf)
							end)()
						end
						if 129 == 0x81 then
							HubUI[(7 + 4)]["CustomDash"]:slider({
								["name"] = "First Flick Angle",
								["def"] = 0,
								["max"] = (0 + 0x2 * 180),
								["min"] = -360,
								["rounding"] = true,
								["pointer"] = "Custom Dash First Flick Angle",
								["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
								["callback"] = function(_NMrLC)
									HubSettings["AutoTech"]["Customdash"]["StartFlickAngle"] = _NMrLC
									HubSettings["AutoTech"]["Customdash"]["FirstFlickAngle"] = _NMrLC
								end,
							})
						else
							(function()
								return (bit32 and 48497 or 0x6539)
							end)()
						end
						HubUI[(7 + 4)]["CustomDash"]:slider({
							["name"] = "Second Flick Delay",
							["def"] = 5,
							["max"] = (25 + 25),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash Second Flick Delay",
							["tooltip"] = "Delay for second flick. Drag or click box to type",
							["callback"] = function(_iXKjQ)
								HubSettings["AutoTech"]["Customdash"]["SecondFlickDelay"] = _iXKjQ / 100
							end,
						})
						HubUI[11]["CustomDash"]:slider({
							["name"] = "Second Flick Angle",
							["def"] = 0,
							["max"] = 360,
							["min"] = -(0 + 0x2 * 180),
							["rounding"] = true,
							["pointer"] = "Custom Dash Second Flick Angle",
							["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
							["callback"] = function(_zcIKW)
								HubSettings["AutoTech"]["Customdash"]["SecondFlickAngle"] = _zcIKW
							end,
						})
						HubUI[11]["CustomDash"]:slider({
							["name"] = "Third Flick Delay",
							["def"] = (1 + 0x2 * 2),
							["max"] = 50,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash Third Flick Delay",
							["tooltip"] = "Delay for third flick. Drag or click box to type",
							["callback"] = function(_UvSag)
								HubSettings["AutoTech"]["Customdash"]["ThirdFlickDelay"] = _UvSag / (0 + 0x2 * 50)
							end,
						})
						HubUI[(0x2 * 7 - 3)]["CustomDash"]:slider({
							["name"] = "Third Flick Angle",
							["def"] = 0,
							["max"] = 360,
							["min"] = -360,
							["rounding"] = true,
							["pointer"] = "Custom Dash Third Flick Angle",
							["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
							["callback"] = function(_FwDT0)
								HubSettings["AutoTech"]["Customdash"]["ThirdFlickAngle"] = _FwDT0
							end,
						})
						if 1 == 0x1 then
							HubUI[(0x2 * 7 - 3)]["CustomDash"]:toggle({
								["name"] = "Lock On",
								["def"] = HubSettings["AutoTech"]["Customdash"]["LockOn"],
								["pointer"] = "Custom Dash Lock On",
								["callback"] = function(_aiHmt4Ay)
									HubSettings["AutoTech"]["Customdash"]["LockOn"] = _aiHmt4Ay
								end,
							})
						else
							(function()
								return ((0xc62e % 0x2 == 0x0) and (bit32 and 25367 or 0x0) or (bit32 and 54628 or 0x0))
							end)()
						end
						if 1 == 0x1 then
							HubUI[11]["CustomDash"]:dropdown({
								["name"] = "Lock On After",
								["def"] = HubSettings["AutoTech"]["Customdash"]["LockOnAfter"],
								["max"] = (0 + 0x2 * 1),
								["options"] = { "Second Flick", "Third Flick" },
								["pointer"] = "Custom Dash Lock On After",
								["callback"] = function(_rlX4Dlt)
									HubSettings["AutoTech"]["Customdash"]["LockOnAfter"] = _rlX4Dlt
								end,
							})
						else
							(function()
								return (bit32 and 1549476576 or 0x60cc)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["CustomDash"]:slider({
							["name"] = "Lock On Precision",
							["def"] = (0x2 * 50 - 0),
							["max"] = (50 + 50),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash Lock On Precision",
							["callback"] = function(_MBUHE8)
								HubSettings["AutoTech"]["Customdash"]["LockOnPrecision"] = _MBUHE8 / (0 + 0x2 * 500)
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["CustomDash"]:slider({
								["name"] = "Lock On Delay",
								["def"] = 0,
								["max"] = 10,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Custom Dash Lock On Delay",
								["callback"] = function(_lDAgq)
									HubSettings["AutoTech"]["Customdash"]["LockOnDelay"] = _lDAgq / (0x2 * 50 - 0)
								end,
							})
						else
							(function()
								return (bit32 and 46087 or 0xa416)
							end)()
						end
						if 65535 == 0xffff then
							HubUI[(3 + 0x2 * 4)]["CustomDashv2"]:toggle({
								["name"] = "Jump",
								["def"] = HubSettings["AutoTech"]["Customdashv2"]["Jump"],
								["pointer"] = "Custom Dash v2 Jump",
								["callback"] = function(_GpPoGMpP)
									HubSettings["AutoTech"]["Customdashv2"]["Jump"] = _GpPoGMpP
								end,
							})
						else
							(function()
								return (bit32 and 52367 or 0xecef)
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(3 + 0x2 * 4)]["CustomDashv2"]:toggle({
								["name"] = "Rotate Camera",
								["def"] = HubSettings["AutoTech"]["Customdashv2"]["RotateCam"],
								["pointer"] = "Custom Dash v2 Rotate Camera",
								["callback"] = function(_L3ppu7L)
									HubSettings["AutoTech"]["Customdashv2"]["RotateCam"] = _L3ppu7L
								end,
							})
						else
							(function()
								return (bit32 and 2887 or 0xbf1)
							end)()
						end
						HubUI[11]["CustomDashv2"]:slider({
							["name"] = "First Flick Angle",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["StartFlickAngle"],
							["max"] = 360,
							["min"] = -(0 + 0x2 * 180),
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 First Flick Angle",
							["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
							["callback"] = function(_gfTOOU)
								HubSettings["AutoTech"]["Customdashv2"]["StartFlickAngle"] = _gfTOOU
							end,
						})
						HubUI[(0x2 * 7 - 3)]["CustomDashv2"]:slider({
							["name"] = "Second Flick Delay",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDelay"],
							["max"] = 50,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Second Flick Delay",
							["tooltip"] = "Delay for second flick. Drag or click box to type",
							["callback"] = function(_vY0MW)
								HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDelay"] = _vY0MW / 100
							end,
						})
						if 0 == 0x0 then
							HubUI[(3 + 0x2 * 4)]["CustomDashv2"]:slider({
								["name"] = "Second Flick Duration",
								["def"] = HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDuration"],
								["max"] = (0 + 0x2 * 50),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Custom Dash v2 Second Flick Duration",
								["tooltip"] = "Duration to turn camera. Drag or click box to type",
								["callback"] = function(_aLsLJtOM)
									HubSettings["AutoTech"]["Customdashv2"]["SecondFlickDuration"] = _aLsLJtOM / 100
								end,
							})
						else
							(function()
								return (bit32 and 46810 or 0xed7d)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["CustomDashv2"]:slider({
							["name"] = "Second Flick Angle",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["SecondFlickAngle"],
							["max"] = (0x2 * 180 - 0),
							["min"] = -(180 + 180),
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Second Flick Angle",
							["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
							["callback"] = function(_JSCiJm9)
								HubSettings["AutoTech"]["Customdashv2"]["SecondFlickAngle"] = _JSCiJm9
							end,
						})
						HubUI[11]["CustomDashv2"]:slider({
							["name"] = "Third Flick Delay",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDelay"],
							["max"] = (0x2 * 25 - 0),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Third Flick Delay",
							["tooltip"] = "Delay for third flick. Drag or click box to type",
							["callback"] = function(_o9EbCm)
								HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDelay"] = _o9EbCm / (50 + 50)
							end,
						})
						HubUI[11]["CustomDashv2"]:slider({
							["name"] = "Third Flick Duration",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDuration"],
							["max"] = 100,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Third Flick Duration",
							["tooltip"] = "Duration to turn camera. Drag or click box to type",
							["callback"] = function(_Du5iu)
								HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickDuration"] = _Du5iu / (0x2 * 50 - 0)
							end,
						})
						HubUI[11]["CustomDashv2"]:slider({
							["name"] = "Third Flick Angle",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickAngle"],
							["max"] = (180 + 180),
							["min"] = -360,
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Third Flick Angle",
							["tooltip"] = "Angle in degrees (-360 to 360). Drag or click box to type",
							["callback"] = function(_iI_b3Gru)
								HubSettings["AutoTech"]["Customdashv2"]["ThirdFlickAngle"] = _iI_b3Gru
							end,
						})
						HubUI[11]["CustomDashv2"]:toggle({
							["name"] = "Lock On",
							["def"] = HubSettings["AutoTech"]["Customdashv2"]["LockOn"],
							["pointer"] = "Custom Dash v2 Lock On",
							["callback"] = function(_Ruwas)
								HubSettings["AutoTech"]["Customdashv2"]["LockOn"] = _Ruwas
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["CustomDashv2"]:dropdown({
								["name"] = "Lock On After",
								["def"] = HubSettings["AutoTech"]["Customdashv2"]["LockOnAfter"],
								["max"] = 2,
								["options"] = { "Second Flick", "Third Flick" },
								["pointer"] = "Custom Dash v2 Lock On After",
								["callback"] = function(_wekSV)
									HubSettings["AutoTech"]["Customdashv2"]["LockOnAfter"] = _wekSV
								end,
							})
						else
							(function()
								return ((0xbdb1 % 0x2 == 0x0) and (bit32 and 24280 or 0x0) or (bit32 and 43258 or 0x0))
							end)()
						end
						HubUI[11]["CustomDashv2"]:slider({
							["name"] = "Lock On Precision",
							["def"] = 100,
							["max"] = 100,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Custom Dash v2 Lock On Precision",
							["tooltip"] = "Lock on precision percentage. Drag or click box to type",
							["callback"] = function(_Xn9WO)
								HubSettings["AutoTech"]["Customdashv2"]["LockOnPrecision"] = _Xn9WO / 1000
							end,
						})
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(0x2 * 7 - 3)]["CustomDashv2"]:slider({
								["name"] = "Lock On Delay",
								["def"] = 0,
								["max"] = (0x2 * 5 - 0),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Custom Dash v2 Lock On Delay",
								["tooltip"] = "Lock on delay. Drag or click box to type",
								["callback"] = function(_Cvb1p)
									HubSettings["AutoTech"]["Customdashv2"]["LockOnDelay"] = _Cvb1p / (0 + 0x2 * 50)
								end,
							})
						else
							(function()
								return (bit32 and 20103 or 0x4e97)
							end)()
						end
						if 129 == 0x81 then
							HubUI[(7 + 4)]["Tech"]:toggle({
								["name"] = "Enabled",
								["def"] = HubSettings["Macro"]["TechHelper"]["Enabled"],
								["pointer"] = "Tech Helper Toggle",
								["callback"] = function(_lB1CK)
									HubSettings["Macro"]["TechHelper"]["Enabled"] = _lB1CK
								end,
							})
						else
							(function()
								return (bit32 and 59740 or 0x695c)
							end)()
						end
						HubUI[11]["Tech"]:dropdown({
							["name"] = "Tech Helper Variant",
							["def"] = HubSettings["Macro"]["TechHelper"]["Tech"],
							["max"] = (1 + 0x2 * 2),
							["options"] = { "Humbled Twisted", "Loop Dash", "Instant Lee", "Oreo Tech", "Lix Tech" },
							["pointer"] = "Tech Helper Variant",
							["callback"] = function(_csfbB)
								HubSettings["Macro"]["TechHelper"]["Tech"] = _csfbB
							end,
						})
						HubUI[(3 + 0x2 * 4)]["Tech"]:keybind({
							["name"] = "Tech Helper KeyBind",
							["def"] = ({})[1],
							["pointer"] = "Tech Helper KeyBind",
							["tooltip"] = "Press on third m1",
							["callback"] = function(_D3yqi)
								if
									not HubSettings["Macro"]["TechHelper"]["Enabled"]
									or HubSettings["Macro"]["TechHelper"]["Tech"] == ""
								then
									return
								end
								local _idNMS = _reriI((360 / 0x3e8))
								if HubSettings["Macro"]["TechHelper"]["Tech"] == "Humbled Twisted" then
									_SVwyf()
									task["wait"](_idNMS[1] - ((25 + 25) / 0x3e8))
									_XjK2G()
									task["wait"](((0x2 * 39 - 3) / 0x3e8) - _idNMS[(1 + 1)])
									_gMeqn(-90, ((0 + 0x2 * 50) / 0x3e8))
									task["wait"](((50 + 50) / 0x3e8))
									_gMeqn(180, (100 / 0x3e8))
									task["wait"](((0x2 * 63 - 1) / 0x3e8))
									_gMeqn(-90, (100 / 0x3e8))
								elseif HubSettings["Macro"]["TechHelper"]["Tech"] == "Loop Dash" then
									_epkf_()
									task["wait"](_idNMS[(1 + 0)])
									_XjK2G()
									_RnQ1A5M(45)
									_gMeqn(340, ((200 + 200) / 0x3e8) - _idNMS[(1 + 1)])
								elseif HubSettings["Macro"]["TechHelper"]["Tech"] == "Instant Lee" then
									_SVwyf()
									task["wait"](_idNMS[(1 + 0)] - (50 / 0x3e8))
									_XjK2G()
									task["wait"](_idNMS[2])
									_RnQ1A5M((1 + 0x2 * 72))
									task["wait"]((75 / 0x3e8) + _idNMS[(1 + 1)])
									_gMeqn(-175, ((0x2 * 50 - 0) / 0x3e8))
								elseif HubSettings["Macro"]["TechHelper"]["Tech"] == "Oreo Tech" then
									_epkf_()
									task["wait"](_idNMS[(1 + 0)])
									_RnQ1A5M((0x2 * 90 - 0))
									_XjK2G()
									task["wait"]((180 / 0x3e8) + _idNMS[(0x2 * 1 - 0)])
									_RnQ1A5M(180)
								elseif HubSettings["Macro"]["TechHelper"]["Tech"] == "Lix Tech" then
									_epkf_()
									task["wait"](_idNMS[(0x2 * 1 - 1)])
									_XjK2G()
									task["wait"](((80 + 80) / 0x3e8) + _idNMS[(0x2 * 1 - 0)])
									_RnQ1A5M((0x2 * 90 - 0))
								end
							end,
						})
						if 16 == 0x10 then
							HubUI[(0x2 * 7 - 3)]["Tech"]:toggle({
								["name"] = "Enabled",
								["def"] = HubSettings["Macro"]["ExtraTechHelper"]["Enabled"],
								["pointer"] = "Extra Tech Toggle",
								["callback"] = function(_Q8KaK)
									HubSettings["Macro"]["ExtraTechHelper"]["Enabled"] = _Q8KaK
								end,
							})
						else
							(function()
								return (bit32 and 58875 or 0x555c)
							end)()
						end
						HubUI[(7 + 4)]["Tech"]:keybind({
							["name"] = "Extra Tech Helper",
							["def"] = ({})[1],
							["pointer"] = "Extra Tech Helper",
							["tooltip"] = "For Instant Lethal Press Keybind when you want to press second move, for materia tech switch to saitama and after landing 3m1s come closer to enemy and press keybind with a bit delay",
							["callback"] = function(_xWcIv)
								if
									not HubSettings["Macro"]["ExtraTechHelper"]["Enabled"]
									or HubSettings["Macro"]["ExtraTechHelper"]["Tech"] == ""
								then
									return
								end
								local _WL9Xh = ({})[1]
								local _rzhk7 = _Z0Hry and _Z0Hry:GetAttribute("LastM1Hitted")
								if _rzhk7 then
									local _YqQ7X = _rzhk7:match("^(.-);;")
									if _YqQ7X then
										_WL9Xh = _f5mDQ["Live"]:FindFirstChild(_YqQ7X)
									end
								end
								if not _WL9Xh then
									_WL9Xh = _q46lU["getTarget"]((19 + 16))
								end
								if HubSettings["Macro"]["ExtraTechHelper"]["Tech"] == "Instant Lethal Shift Lock" then
									local _Flv7h = _reriI(((1100 + 1100) / 0x3e8))
									local _eESHJ = _q46lU["elapsed"]()
									if _eESHJ then
										task["wait"](math["max"](0, _Flv7h[(0x2 * 1 - 1)] - _eESHJ))
									else
										_u3Jke(Enum["KeyCode"]["Two"])
										task["wait"](_Flv7h[(1 + 0)])
									end
									_IDvSS(_NSKGP)
									_XjK2G()
									task["wait"]((180 / 0x3e8) + _Flv7h[(0x2 * 1 - 0)])
									_RnQ1A5M(180)
									_S4jah(_NSKGP)
								elseif HubSettings["Macro"]["ExtraTechHelper"]["Tech"] == "Instant Lethal Loop Dash" then
									local _Lw8tl = _reriI((2200 / 0x3e8))
									local _shNHy = _q46lU["elapsed"]()
									if _shNHy then
										task["wait"](math["max"](0, _Lw8tl[1] - _shNHy))
									else
										_u3Jke(Enum["KeyCode"]["Two"])
										task["wait"](_Lw8tl[(1 + 0)])
									end
									_IDvSS(_NSKGP)
									_XjK2G()
									task["wait"](((25 + 25) / 0x3e8) - _Lw8tl[(0x2 * 1 - 0)])
									_RnQ1A5M((0x2 * 23 - 1))
									_gMeqn(275, (250 / 0x3e8))
									_S4jah(_NSKGP)
								elseif HubSettings["Macro"]["ExtraTechHelper"]["Tech"] == "Materia Tech" then
									if not _WL9Xh then
										return
									end
									local _ZwdBh = _WL9Xh:FindFirstChild("HumanoidRootPart")
									if not _ZwdBh then
										return
									end
									local _KZraQ = RunService["Heartbeat"]:Connect(function()
										_RnQ1A5M(({})[1], _e71S9["pos"](_ZwdBh))
									end)
									_u3Jke(Enum["KeyCode"]["Three"])
									task["wait"](((0 + 0x2 * 320) / 0x3e8))
									_IDvSS(_ZgU0U)
									task["wait"]((5 / 0x3e8))
									_vA5WJ(_KZraQ)
									_RnQ1A5M(90)
									_kvld1(_kK9mB)
									_S4jah(_ZgU0U)
									_SVwyf()
								end
							end,
						})
						HubUI[(0x2 * 7 - 3)]["Tech"]:dropdown({
							["name"] = "Extra Tech Variant",
							["def"] = HubSettings["Macro"]["ExtraTechHelper"]["Tech"] ~= ""
									and HubSettings["Macro"]["ExtraTechHelper"]["Tech"]
								or "Instant Lethal Shift Lock",
							["max"] = 3,
							["options"] = { "Instant Lethal Shift Lock", "Instant Lethal Loop Dash", "Materia Tech" },
							["pointer"] = "Extra Tech Helper Variant",
							["callback"] = function(_ravIc)
								HubSettings["Macro"]["ExtraTechHelper"]["Tech"] = _ravIc
							end,
						})
						HubUI[(0x2 * 7 - 3)]["TrueM1Reset"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "True M1 Reset Toggle",
							["callback"] = function(_Ya3qM)
								HubSettings["Macro"]["m1ResetEnabled"] = _Ya3qM
							end,
						})
						if 0 == 0x0 then
							HubUI[(7 + 4)]["TrueM1Reset"]:keybind({
								["name"] = "M1 Reset KeyBind",
								["def"] = ({})[1],
								["pointer"] = "M1 Reset Keybind",
								["tooltip"] = "Press a keybind when you have side dash and front dash after second m1.",
								["callback"] = function(_FCGDP)
									if not HubSettings["Macro"]["m1ResetEnabled"] then
										return
									end
									local _eIGeC = _reriI((280 / 0x3e8))[(1 + 0x2 * 0)]
									_SVwyf()
									task["wait"](_eIGeC)
									_RnQ1A5M(-90)
									_IDvSS(_ZgU0U)
									_kvld1(_kK9mB)
									task["wait"](_eIGeC)
									_S4jah(_ZgU0U)
									_RnQ1A5M(90)
									_XjK2G()
								end,
							})
						else
							(function()
								return (bit32 and 33914 or 0xab39)
							end)()
						end
						if 16 == 0x10 then
							HubUI[11]["EmoteDash"]:toggle({
								["name"] = "Enabled",
								["def"] = false,
								["pointer"] = "Emote Dash Toggle",
								["callback"] = function(_lfiSU)
									HubSettings["Macro"]["EmoteDash"]["Enabled"] = _lfiSU
								end,
							})
						else
							(function()
								return (bit32 and 1240304997 or 0x5528)
							end)()
						end
						HubUI[11]["EmoteDash"]:keybind({
							["name"] = "Emote Dash KeyBind",
							["def"] = ({})[1],
							["pointer"] = "Emote Dash KeyBind",
							["callback"] = function(_QjoYR)
								if
									not HubSettings["Macro"]["EmoteDash"]["Enabled"]
									or not (_y4IB9 and _fx2la and _y4IB9["Health"] > 0)
								then
									return
								end
								_S4jah(_X1lLf)
								_S4jah(_u6GG1)
								if HubSettings["Macro"]["EmoteDash"]["Type"] == "Straight" then
									_RnQ1A5M((0 + 0x2 * 45))
								end
								if
									HubSettings["Macro"]["EmoteDash"]["Type"] == "Straight"
									or HubSettings["Macro"]["EmoteDash"]["Type"] == "Right"
								then
									_IDvSS(_ZgU0U)
								elseif HubSettings["Macro"]["EmoteDash"]["Type"] == "Left" then
									_IDvSS(_MJJxA)
								end
								_y4IB9:ChangeState(Enum["HumanoidStateType"]["Jumping"])
								task["wait"](((0x2 * 3 - 1) / 0x3e8))
								_kvld1(_kK9mB)
								task["wait"](HubSettings["Macro"]["EmoteDash"]["Delay"])
								local _jZNsN = _fx2la:FindFirstChild("dodgevelocity")
								if _jZNsN then
									_jZNsN:Destroy()
									_ZGKm8(_j089A["rsideDash"])
									_ZGKm8(_j089A["lsideDash"])
								end
								_S4jah(_ZgU0U)
								_S4jah(_MJJxA)
								if HubSettings["Macro"]["EmoteDash"]["Type"] == "Straight" then
									_RnQ1A5M(-90)
								end
							end,
						})
						if 1 == 0x1 then
							HubUI[(0x2 * 7 - 3)]["EmoteDash"]:textbox({
								["name"] = "Emote Dash Delay",
								["def"] = HubSettings["Macro"]["EmoteDash"]["Delay"],
								["placeholder"] = "",
								["pointer"] = "Emote Dash Delay",
								["callback"] = function(_KmjuE)
									HubSettings["Macro"]["EmoteDash"]["Delay"] =
										math["clamp"](tonumber(_KmjuE) or (50 / 0x3e8), 0, 1)
								end,
							})
						else
							(function()
								return ((0x9df2 % 0x2 == 0x0) and (bit32 and 20217 or 0x0) or (bit32 and 61680 or 0x0))
							end)()
						end
						HubUI[(7 + 4)]["EmoteDash"]:dropdown({
							["name"] = "Emote Dash Type",
							["def"] = HubSettings["Macro"]["EmoteDash"]["Type"],
							["max"] = 3,
							["options"] = { "Right", "Left", "Straight" },
							["pointer"] = "Emote Dash Type",
							["callback"] = function(_ddGJT)
								HubSettings["Macro"]["EmoteDash"]["Type"] = _ddGJT
							end,
						})
						HubUI[(0x2 * 7 - 3)]["BackdashCancel"]:keybind({
							["name"] = "Backdash Cancel 1",
							["def"] = ({})[1],
							["pointer"] = "Backdash Cancel 1 Keybind",
							["callback"] = function(_wq9Pz)
								if not HubSettings["Macro"]["BackDashCancel1"]["Enabled"] then
									return
								end
								HubUI[6](Enum["KeyCode"]["One"])
							end,
						})
						HubUI[(7 + 4)]["BackdashCancel"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Backdash Cancel 1 Enabled",
							["callback"] = function(_PytPX)
								HubSettings["Macro"]["BackDashCancel1"]["Enabled"] = _PytPX
							end,
						})
						if 16 == 0x10 then
							HubUI[(0x2 * 7 - 3)]["BackdashCancel"]:keybind({
								["name"] = "Backdash Cancel 2",
								["def"] = ({})[1],
								["pointer"] = "Backdash Cancel 2 Keybind",
								["callback"] = function(_e2U07)
									if not HubSettings["Macro"]["BackDashCancel2"]["Enabled"] then
										return
									end
									HubUI[6](Enum["KeyCode"]["Two"])
								end,
							})
						else
							(function()
								return ((0xf368 % 0x2 == 0x0) and (bit32 and 31156 or 0x0) or (bit32 and 44778 or 0x0))
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["BackdashCancel"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Backdash Cancel 2 Enabled",
							["callback"] = function(_xz8E7)
								HubSettings["Macro"]["BackDashCancel2"]["Enabled"] = _xz8E7
							end,
						})
						HubUI[11]["BackdashCancel"]:keybind({
							["name"] = "Backdash Cancel 3",
							["def"] = ({})[1],
							["pointer"] = "Backdash Cancel 3 Keybind",
							["callback"] = function(_QXHy7)
								if not HubSettings["Macro"]["BackDashCancel3"]["Enabled"] then
									return
								end
								HubUI[(0x2 * 3 - 0)](Enum["KeyCode"]["Three"])
							end,
						})
						HubUI[(7 + 4)]["BackdashCancel"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Backdash Cancel 3 Enabled",
							["callback"] = function(_jc5oz)
								HubSettings["Macro"]["BackDashCancel3"]["Enabled"] = _jc5oz
							end,
						})
						if 65535 == 0xffff then
							HubUI[11]["BackdashCancel"]:keybind({
								["name"] = "Backdash Cancel 4",
								["def"] = ({})[1],
								["pointer"] = "Backdash Cancel 4 Keybind",
								["callback"] = function(_KVjCj)
									if not HubSettings["Macro"]["BackDashCancel4"]["Enabled"] then
										return
									end
									HubUI[6](Enum["KeyCode"]["Four"])
								end,
							})
						else
							(function()
								return ((0xdf2d % 0x2 == 0x0) and (bit32 and 28566 or 0x0) or (bit32 and 5872 or 0x0))
							end)()
						end
						HubUI[11]["BackdashCancel"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Backdash Cancel 4 Enabled",
							["callback"] = function(_dGt8d)
								HubSettings["Macro"]["BackDashCancel4"]["Enabled"] = _dGt8d
							end,
						})
						if 16 == 0x10 then
							HubUI[11]["VisualMain"]:toggle({
								["name"] = "No Textures (Low GFX)",
								["def"] = false,
								["pointer"] = "No Textures",
								["tooltip"] = "flattens part materials (planks, wood, brick...), mesh textures, surface appearances and decals across the map, and drops the render quality to the lowest level. turn it off to put everything back",
								["callback"] = function(_wSvGO)
									_meXJ9 = _wSvGO
									_sLGb1(false, _wSvGO)
								end,
							})
						else
							(function()
								return (bit32 and 44450 or 0xd0ad)
							end)()
						end
						HubUI[(0x2 * 7 - 3)]["VisualMain"]:button({
							["name"] = "Update No Textures List",
							["callback"] = function()
								_sLGb1(true, _meXJ9)
							end,
						})
						HubUI[11]["VisualMain"]:toggle({
							["name"] = "No Shadows",
							["def"] = false,
							["pointer"] = "No Shadows",
							["callback"] = function(_bkCAR)
								HubUI[5]("Visuals.NoShadows", "NoGShadows", _bkCAR)
							end,
						})
						HubUI[(3 + 0x2 * 4)]["VisualMain"]:toggle({
							["name"] = "No Smoke",
							["def"] = false,
							["pointer"] = "No Smoke",
							["callback"] = function(_CnA4S)
								HubUI[(3 + 2)]("Visuals.NoSmoke", "No Smoke", _CnA4S)
							end,
						})
						if 16 == 0x10 then
							HubUI[(7 + 4)]["VisualMain"]:toggle({
								["name"] = "No Rings",
								["def"] = false,
								["pointer"] = "No Rings",
								["callback"] = function(_VyfN4)
									HubUI[5]("Visuals.NoRings", "No Rings", _VyfN4)
								end,
							})
						else
							(function()
								return (bit32 and 10011 or 0x4509)
							end)()
						end
						HubUI[(7 + 4)]["VisualMain"]:toggle({
							["name"] = "No Capes",
							["def"] = false,
							["pointer"] = "No Capes",
							["callback"] = function(_tdPci)
								HubUI[(3 + 2)]("Visuals.NoCapes", "No Capes", _tdPci)
							end,
						})
						HubUI[(3 + 0x2 * 4)]["VisualMain"]:toggle({
							["name"] = "No Auras",
							["def"] = false,
							["pointer"] = "No Auras",
							["callback"] = function(_GvETB)
								HubUI[5]("Visuals.NoAuras", "No Auras", _GvETB)
							end,
						})
						if 16 == 0x10 then
							HubUI[(7 + 4)]["VisualMain"]:toggle({
								["name"] = "No Garou After Images",
								["def"] = false,
								["pointer"] = "No Garou After Images",
								["callback"] = function(_bFyfE)
									HubUI[(3 + 2)]("Visuals.NoGarouC", "No Garou Clones", _bFyfE)
								end,
							})
						else
							(function()
								return ((0xef2e % 0x2 == 0x0) and (bit32 and 30615 or 0x0) or (bit32 and 2427 or 0x0))
							end)()
						end
						HubUI[(7 + 4)]["VisualMain"]:toggle({
							["name"] = "No New Light",
							["def"] = false,
							["pointer"] = "No New Light",
							["callback"] = function(_sI12H)
								HubUI[(0x2 * 3 - 1)]("Visuals.NoNewLight", "No New Light", _sI12H)
							end,
						})
						HubUI[11]["VisualMain"]:slider({
							["name"] = "Saturation",
							["def"] = 0,
							["max"] = (0 + 0x2 * 100),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Saturation",
							["callback"] = function(_FZOqb)
								_IeaiYt2E(_uMouq, "Saturation", _FZOqb / 100)
							end,
						})
						HubUI[11]["VisualMain"]:slider({
							["name"] = "FOV",
							["def"] = 70,
							["max"] = 120,
							["min"] = (0x2 * 1 - 1),
							["rounding"] = true,
							["pointer"] = "FOV",
							["callback"] = function(_i6cRcg7g)
								HubSettings["Visuals"]["FOV"] = _i6cRcg7g
								_IeaiYt2E(_AuGxA, "FieldOfView", _i6cRcg7g)
							end,
						})
						HubUI[(0x2 * 7 - 3)]["VisualMain"]:toggle({
							["name"] = "Motion Blur",
							["def"] = false,
							["pointer"] = "Motion Blur Toggle",
							["tooltip"] = "Adds smooth dynamic motion blur when rotating camera or moving fast",
							["callback"] = function(_Di5smvU)
								HubUI[(0x2 * 3 - 1)]("Visuals.MotionBlur.Enabled", "MotionBlur", _Di5smvU)
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["VisualMain"]:slider({
								["name"] = "Motion Blur Intensity",
								["def"] = (0 + 0x2 * 5),
								["max"] = (15 + 15),
								["min"] = (1 + 0),
								["rounding"] = true,
								["pointer"] = "Motion Blur Intensity",
								["tooltip"] = "Intensity of motion blur during camera rotation",
								["callback"] = function(_QFDnQ3)
									HubSettings["Visuals"]["MotionBlur"]["Intensity"] = _QFDnQ3
								end,
							})
						else
							(function()
								return ((0x6c7a % 0x2 == 0x0) and (bit32 and 13885 or 0x0) or (bit32 and 50766 or 0x0))
							end)()
						end
						HubUI[(7 + 4)]["VisualESP"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "ESP Toggle",
							["callback"] = function(_tMi6v)
								HubUI[5]("Visuals.ESP.Enabled", "ESP", _tMi6v)
							end,
						})
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[11]["VisualESP"]:toggle({
								["name"] = "Highlight",
								["def"] = true,
								["pointer"] = "ESP Highlight Toggle",
								["tooltip"] = "the colored fill over the player. turn it off for boxes / text only",
								["callback"] = function(_G5yGendB)
									HubUI[5]("Visuals.ESP.Highlight", "HighlightESP", _G5yGendB)
								end,
							})
						else
							(function()
								return ((0x8ab6 % 0x2 == 0x0) and (bit32 and 17755 or 0x0) or (bit32 and 32181 or 0x0))
							end)()
						end
						HubUI[(0x2 * 7 - 3)]["VisualESP"]:toggle({
							["name"] = "Boxes ESP",
							["def"] = false,
							["pointer"] = "Boxes ESP Toggle",
							["callback"] = function(_nxYm74O)
								HubSettings["Visuals"]["ESP"]["Boxes"] = _nxYm74O
								HubUI[(0x2 * 3 - 1)]("Visuals.ESP.Boxes", "BoxesESP", _nxYm74O)
							end,
						})
						HubUI[(7 + 4)]["VisualESP"]:toggle({
							["name"] = "Box Team/Enemy Color",
							["def"] = true,
							["pointer"] = "Box Team Color Toggle",
							["callback"] = function(_QHPIuRCp)
								HubSettings["Visuals"]["ESP"]["BoxUseESPColor"] = _QHPIuRCp
								_S1SQ1(false, false)
							end,
						})
						HubUI[(0x2 * 7 - 3)]["VisualESP"]:colorpicker({
							["name"] = "Box Custom Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["ESP"]["BoxColor"],
							["pointer"] = "Box Custom Color",
							["callback"] = function(_X06lR)
								HubSettings["Visuals"]["ESP"]["BoxColor"] = _X06lR
								_S1SQ1(false, false)
							end,
						})
						HubUI[11]["VisualESP"]:slider({
							["name"] = "Box Thickness",
							["def"] = (0x2 * 1 - 1),
							["max"] = 6,
							["min"] = 1,
							["rounding"] = true,
							["pointer"] = "Box Line Thickness",
							["tooltip"] = "line width of the 2D box in pixels",
							["callback"] = function(_uimkw6)
								HubSettings["Visuals"]["ESP"]["BoxThickness"] = _uimkw6
								_S1SQ1(false, false)
							end,
						})
						if 129 == 0x81 then
							HubUI[(3 + 0x2 * 4)]["VisualESP"]:toggle({
								["name"] = "Box Filled",
								["def"] = false,
								["pointer"] = "Box Filled Toggle",
								["callback"] = function(_Z6_2JzF)
									HubSettings["Visuals"]["ESP"]["BoxFilled"] = _Z6_2JzF
									_S1SQ1(false, false)
								end,
							})
						else
							(function()
								return (bit32 and 13165 or 0x2933)
							end)()
						end
						if 65535 == 0xffff then
							HubUI[(7 + 4)]["VisualESP"]:colorpicker({
								["name"] = "Friend Color",
								["cpname"] = "",
								["def"] = HubSettings["Visuals"]["ESP"]["FriendColor"],
								["pointer"] = "Friend Color",
								["callback"] = function(_MJTnf0Tc)
									HubSettings["Visuals"]["ESP"]["FriendColor"] = _MJTnf0Tc
									_S1SQ1(false, false)
								end,
							})
						else
							(function()
								return (bit32 and 51678 or 0xdfc9)
							end)()
						end
						HubUI[11]["VisualESP"]:colorpicker({
							["name"] = "Enemy Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["ESP"]["EnemyColor"],
							["pointer"] = "Enemy Color",
							["callback"] = function(_vxLzg)
								HubSettings["Visuals"]["ESP"]["EnemyColor"] = _vxLzg
								_S1SQ1(false, false)
							end,
						})
						HubUI[11]["VisualESP"]:colorpicker({
							["name"] = "Neutral Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["ESP"]["NeutralColor"],
							["pointer"] = "Neutral Color",
							["callback"] = function(_iR7W3Lu9)
								HubSettings["Visuals"]["ESP"]["NeutralColor"] = _iR7W3Lu9
								_S1SQ1(false, false)
							end,
						})
						if 0 == 0x0 then
							HubUI[11]["VisualESP"]:colorpicker({
								["name"] = "Ultimate Color",
								["cpname"] = "",
								["def"] = HubSettings["Visuals"]["ESP"]["UltColor"],
								["pointer"] = "Ultimate Color",
								["callback"] = function(_N4f6naG)
									HubSettings["Visuals"]["ESP"]["UltColor"] = _N4f6naG
									_S1SQ1(false, false)
								end,
							})
						else
							(function()
								return ((0xb2ae % 0x2 == 0x0) and (bit32 and 22871 or 0x0) or (bit32 and 19171 or 0x0))
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["VisualESP"]:colorpicker({
							["name"] = "Saitama Ultimate Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["ESP"]["SaitamaUltColor"],
							["pointer"] = "Saitama Ultimate Color",
							["callback"] = function(_k9VTr)
								HubSettings["Visuals"]["ESP"]["SaitamaUltColor"] = _k9VTr
								_S1SQ1(false, false)
							end,
						})
						HubUI[11]["VisualESP"]:colorpicker({
							["name"] = "Death Counter Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["ESP"]["DeathCounterColor"],
							["pointer"] = "Death Counter Color",
							["callback"] = function(_XSbmH)
								HubSettings["Visuals"]["ESP"]["DeathCounterColor"] = _XSbmH
								_S1SQ1(false, false)
							end,
						})
						HubUI[11]["VisualESP"]:slider({
							["name"] = "Outline Transparency",
							["def"] = 70,
							["max"] = 100,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Outline Transparency",
							["callback"] = function(_uNvrJ)
								HubSettings["Visuals"]["ESP"]["OutlineTransparency"] = _uNvrJ / (0 + 0x2 * 50)
								_S1SQ1(false, false)
							end,
						})
						if 1 == 0x1 then
							HubUI[11]["VisualESP"]:toggle({
								["name"] = "Death Counter ESP",
								["def"] = false,
								["pointer"] = "Death Counter Without ESP",
								["callback"] = function(_NnQLW)
									HubSettings["Visuals"]["ESP"]["DeathCounterESP"] = _NnQLW
								end,
							})
						else
							(function()
								return (bit32 and 60415 or 0x51ba)
							end)()
						end
						HubUI[(7 + 4)]["VisualESP"]:toggle({
							["name"] = "Saitama Ult ESP",
							["def"] = false,
							["pointer"] = "Saitama Ult Without ESP",
							["callback"] = function(_AVhW7)
								HubSettings["Visuals"]["ESP"]["SaitamaUltESP"] = _AVhW7
							end,
						})
						HubUI[11]["VisualESP"]:toggle({
							["name"] = "Name & Ult Text",
							["def"] = true,
							["pointer"] = "ESP Text Toggle",
							["tooltip"] = "the big text above players (character, ult % and name). its own option, works with or without the highlight and boxes",
							["callback"] = function(_XQrY0)
								HubUI[(3 + 2)]("Visuals.ESP.NoBillboards", "NoBillboards", not _XQrY0)
							end,
						})
						HubUI[11]["VisualESP"]:keybind({
							["name"] = "Add Friend/Enemy Keybind",
							["def"] = ({})[1],
							["pointer"] = "Add Friend Keybind",
							["callback"] = function(_KzDcO)
								local _pooRm = HubMouse["Target"]
								if not _pooRm then
									return
								end
								local _M8NO5 = _pooRm:FindFirstAncestorOfClass("Model")
								if not _M8NO5 or not _M8NO5:FindFirstChildOfClass("Humanoid") then
									return
								end
								local _zR0Wy = PlayersService:FindFirstChild(_M8NO5["Name"])
								if not _zR0Wy then
									return
								end
								if not _RWZpc[_zR0Wy["Name"]] then
									_RWZpc[_zR0Wy["Name"]] = "Neutral"
								end
								if _RWZpc[_zR0Wy["Name"]] == "Friend" then
									_RWZpc[_zR0Wy["Name"]] = "Neutral"
								elseif _RWZpc[_zR0Wy["Name"]] == "Neutral" then
									_RWZpc[_zR0Wy["Name"]] = "Enemy"
								elseif _RWZpc[_zR0Wy["Name"]] == "Enemy" then
									_RWZpc[_zR0Wy["Name"]] = "Friend"
								end
								_Z9TMp(_zR0Wy, _M8NO5)
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["VisualColor"]:toggle({
								["name"] = "Enabled",
								["def"] = false,
								["pointer"] = "Custom Effects Toggle",
								["callback"] = function(_LKaAt)
									HubUI[(3 + 2)]("Visuals.EffectsColor.Enabled", "Custom Effects Color", _LKaAt)
								end,
							})
						else
							(function()
								return (bit32 and 59901 or 0x89ed)
							end)()
						end
						HubUI[11]["VisualColor"]:colorpicker({
							["name"] = "Effects Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["EffectsColor"]["Color"],
							["pointer"] = "Custom Effects Color",
							["callback"] = function(_ob08w)
								HubSettings["Visuals"]["EffectsColor"]["Color"] = _ob08w
								_ltM9g()
							end,
						})
						HubUI[11]["VisualChar"]:toggle({
							["name"] = "Headless",
							["def"] = false,
							["pointer"] = "Headless Toggle",
							["callback"] = function(_BfTOI)
								HubUI[(3 + 2)]("Visuals.Headless", "Headless", _BfTOI)
							end,
						})
						HubUI[11]["VisualChar"]:toggle({
							["name"] = "Korblox",
							["def"] = false,
							["pointer"] = "Korblox Toggle",
							["callback"] = function(_mqux9)
								HubUI[(0x2 * 3 - 1)]("Visuals.Korblox", "Korblox", _mqux9)
							end,
						})
						if 65535 == 0xffff then
							HubUI[(7 + 4)]["VisualChar"]:toggle({
								["name"] = "Self Chams",
								["def"] = false,
								["pointer"] = "Self Chams Toggle",
								["callback"] = function(_LIWP3)
									HubUI[5]("Visuals.SelfChams.Enabled", "SelfChams", _LIWP3)
								end,
							})
						else
							(function()
								return (bit32 and (53652 * 0x3d % 0x10000) or 0xd9bc)
							end)()
						end
						if 16 == 0x10 then
							HubUI[(0x2 * 7 - 3)]["VisualChar"]:colorpicker({
								["name"] = "Chams Color",
								["cpname"] = "",
								["def"] = HubSettings["Visuals"]["SelfChams"]["Color"],
								["pointer"] = "Chams Color",
								["callback"] = function(_oZEdv)
									HubSettings["Visuals"]["SelfChams"]["Color"] = _oZEdv
									_BZad1()
								end,
							})
						else
							(function()
								return (bit32 and (20482 * 0x3d % 0x10000) or 0x52a4)
							end)()
						end
						HubUI[(7 + 4)]["VisualChar"]:dropdown({
							["name"] = "Chams Material",
							["def"] = "ForceField",
							["max"] = 3,
							["options"] = {
								"None",
								"ForceField",
								"Neon",
								"Glass",
								"SmoothPlastic",
								"Plastic",
								"Foil",
								"DiamondPlate",
							},
							["pointer"] = "Chams Material",
							["callback"] = function(_d5T0_)
								HubSettings["Visuals"]["SelfChams"]["Material"] = _d5T0_
								_BZad1()
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["VisualChar"]:slider({
								["name"] = "Fill Transparency",
								["def"] = 50,
								["max"] = 100,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Chams Fill Transp",
								["callback"] = function(_yrfik)
									HubSettings["Visuals"]["SelfChams"]["FillTransparency"] = _yrfik / 100
									_BZad1()
								end,
							})
						else
							(function()
								return (bit32 and 56772 or 0x98c)
							end)()
						end
						if 129 == 0x81 then
							HubUI[(0x2 * 7 - 3)]["VisualChar"]:slider({
								["name"] = "Outline Transparency",
								["def"] = 0,
								["max"] = 100,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Chams Outline Transp",
								["callback"] = function(_JJ3Hz)
									HubSettings["Visuals"]["SelfChams"]["OutlineTransparency"] = _JJ3Hz / 100
									_BZad1()
								end,
							})
						else
							(function()
								return (bit32 and 2069605372 or 0xde5d)
							end)()
						end
						HubUI[11]["VisualSky"]:toggle({
							["name"] = "Enabled",
							["def"] = false,
							["pointer"] = "Custom Sky Toggle",
							["callback"] = function(_UfKPT)
								HubSettings["Visuals"]["Sky"]["Enabled"] = _UfKPT
								_liq5P["apply"]()
							end,
						})
						HubUI[(3 + 0x2 * 4)]["VisualSky"]:dropdown({
							["name"] = "Sky Preset",
							["def"] = HubSettings["Visuals"]["Sky"]["Preset"],
							["max"] = 4,
							["options"] = _liq5P["order"],
							["pointer"] = "Custom Sky Preset",
							["callback"] = function(_voVCe)
								HubSettings["Visuals"]["Sky"]["Preset"] = _voVCe
								if HubSettings["Visuals"]["Sky"]["Enabled"] then
									_liq5P["apply"]()
								end
							end,
						})
						if 0 == 0x0 then
							HubUI[(0x2 * 7 - 3)]["VisualSky"]:slider({
								["name"] = "Stars",
								["def"] = HubSettings["Visuals"]["Sky"]["Stars"],
								["max"] = 5000,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Custom Sky Stars",
								["callback"] = function(_KU58i)
									HubSettings["Visuals"]["Sky"]["Stars"] = _KU58i
									if HubSettings["Visuals"]["Sky"]["Enabled"] then
										_liq5P["apply"]()
									end
								end,
							})
						else
							(function()
								return (bit32 and (42660 * 0x3d % 0x10000) or 0x9aa9)
							end)()
						end
						if 16 == 0x10 then
							HubUI[(3 + 0x2 * 4)]["VisualSky"]:textbox({
								["name"] = "Skybox Image ID",
								["def"] = "",
								["placeholder"] = "image id",
								["pointer"] = "Custom Sky Image",
								["tooltip"] = "Used by the Custom Skybox preset. Put an image asset id (not a decal id), it goes on all six sides",
								["callback"] = function(_laddB)
									HubSettings["Visuals"]["Sky"]["SkyboxId"] = _laddB
									if
										HubSettings["Visuals"]["Sky"]["Enabled"]
										and HubSettings["Visuals"]["Sky"]["Preset"] == "Custom Skybox"
									then
										_liq5P["apply"]()
									end
								end,
							})
						else
							(function()
								return (bit32 and 335303621 or 0x225)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["VisualAtmosphere"]:toggle({
							["name"] = "Custom Atmosphere",
							["def"] = false,
							["pointer"] = "Atmosphere Toggle",
							["callback"] = function(_IsVTy)
								HubUI[(3 + 2)]("Visuals.Atmosphere.Enabled", "Atmosphere", _IsVTy)
							end,
						})
						if 0 == 0x0 then
							HubUI[(7 + 4)]["VisualAtmosphere"]:colorpicker({
								["name"] = "Atmosphere Color",
								["cpname"] = "",
								["def"] = HubSettings["Visuals"]["Atmosphere"]["Color"],
								["pointer"] = "Atmosphere Color",
								["callback"] = function(_TJ_a5)
									HubSettings["Visuals"]["Atmosphere"]["Color"] = _TJ_a5
									if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
										_cny6G(true)
									end
								end,
							})
						else
							(function()
								return (bit32 and 1620956918 or 0x4d0c)
							end)()
						end
						HubUI[(7 + 4)]["VisualAtmosphere"]:colorpicker({
							["name"] = "Decay Color",
							["cpname"] = "",
							["def"] = HubSettings["Visuals"]["Atmosphere"]["Decay"],
							["pointer"] = "Atmosphere Decay Color",
							["callback"] = function(_KRSeh)
								HubSettings["Visuals"]["Atmosphere"]["Decay"] = _KRSeh
								if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
									_cny6G(true)
								end
							end,
						})
						HubUI[(0x2 * 7 - 3)]["VisualAtmosphere"]:slider({
							["name"] = "Density",
							["def"] = (19 + 16),
							["max"] = 100,
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Atmosphere Density",
							["callback"] = function(_Vo2Uc)
								HubSettings["Visuals"]["Atmosphere"]["Density"] = _Vo2Uc / (50 + 50)
								if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
									_cny6G(true)
								end
							end,
						})
						if 65535 == 0xffff then
							HubUI[11]["VisualAtmosphere"]:slider({
								["name"] = "Haze",
								["def"] = 0,
								["max"] = (0x2 * 50 - 0),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Atmosphere Haze",
								["callback"] = function(_sWUhy)
									HubSettings["Visuals"]["Atmosphere"]["Haze"] = _sWUhy / 10
									if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
										_cny6G(true)
									end
								end,
							})
						else
							(function()
								return (bit32 and 40790 or 0x595c)
							end)()
						end
						HubUI[(3 + 0x2 * 4)]["VisualAtmosphere"]:slider({
							["name"] = "Glare",
							["def"] = 0,
							["max"] = (50 + 50),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "Atmosphere Glare",
							["callback"] = function(_TEs5l)
								HubSettings["Visuals"]["Atmosphere"]["Glare"] = _TEs5l / 100
								if HubSettings["Visuals"]["Atmosphere"]["Enabled"] then
									_cny6G(true)
								end
							end,
						})
						HubUI[11]["Rage"]:toggle({
							["name"] = "No Stun",
							["def"] = false,
							["pointer"] = "No Stun",
							["callback"] = function(_itimm)
								HubSettings["Rage"]["NoStun"] = _itimm
							end,
						})
						if 1 == 0x1 then
							HubUI[11]["Rage"]:toggle({
								["name"] = "No Slow",
								["def"] = false,
								["pointer"] = "No Slow",
								["callback"] = function(_Jb4_u)
									HubSettings["Rage"]["NoSlow"] = _Jb4_u
								end,
							})
						else
							(function()
								return (bit32 and 752218550 or 0xd6d8)
							end)()
						end
						HubUI[11]["Rage"]:toggle({
							["name"] = "No Fatigue",
							["def"] = false,
							["pointer"] = "No Fatigue",
							["callback"] = function(_UGB7v)
								HubSettings["Rage"]["NoFatigue"] = _UGB7v
							end,
						})
						if 16 == 0x10 then
							HubUI[(3 + 0x2 * 4)]["Rage"]:toggle({
								["name"] = "No No Jump",
								["def"] = false,
								["pointer"] = "No No Jump",
								["callback"] = function(_fgUtj)
									HubSettings["Rage"]["AlwaysJump"] = _fgUtj
								end,
							})
						else
							(function()
								return (bit32 and 38163 or 0xbc95)
							end)()
						end
						HubUI[11]["Fling"]:textbox({
							["name"] = "Fling Target",
							["def"] = "",
							["placeholder"] = "",
							["pointer"] = "Fling Target",
							["callback"] = function(_K15PT)
								HubSettings["Rage"]["Fling"]["Target"] = _K15PT
							end,
						})
						HubUI[11]["Fling"]:toggle({
							["name"] = "Loop Fling",
							["def"] = false,
							["pointer"] = "Loop Fling",
							["callback"] = function(_VSj2G)
								HubSettings["Rage"]["Fling"]["LoopFling"] = _VSj2G
							end,
						})
						HubUI[(3 + 0x2 * 4)]["Fling"]:button({
							["name"] = "Fling",
							["callback"] = function()
								repeat
									local _sE20E
									for _T8XAM, _i0UHe in pairs(PlayersService:GetPlayers()) do
										if
											_i0UHe["Name"] == HubSettings["Rage"]["Fling"]["Target"]
											or _i0UHe["DisplayName"] == HubSettings["Rage"]["Fling"]["Target"]
										then
											_sE20E = _i0UHe
										end
									end
									if _sE20E then
										local _VrnrD = _sE20E["Character"]
										if _VrnrD then
											_P4NlG(_VrnrD)
										end
									else
										_OS0SJ({
											["Title"] = "RXM HUB",
											["Description"] = "Fling target isn't on the server",
											["Source"] = "Fling",
										})
										break
									end
									task["wait"](3)
								until not HubSettings["Rage"]["Fling"]["LoopFling"]
							end,
						})
						HubUI[11]["Fling"]:toggle({
							["name"] = "Anti Fling",
							["def"] = false,
							["pointer"] = "Anti Fling",
							["callback"] = function(_sHORd)
								_vA5WJ(_lH0uIxY["antifling"])
								_lH0uIxY["antifling"] = ({})[1]
								if _sHORd then
									local _D0lYS = ({})[1]
									_lH0uIxY["antifling"] = _l3G1i(RunService["Heartbeat"], function()
										local _fQ9_vfz = _fx2la
										if not (_fQ9_vfz and _fQ9_vfz["Parent"]) then
											return
										end
										local _scUBtjZo = tick() < _dcE27["boostUntil"]
											or _fQ9_vfz:FindFirstChild("moveme")
											or _fQ9_vfz:FindFirstChild("dodgevelocity")
										if
											(not _scUBtjZo and _fQ9_vfz["AssemblyLinearVelocity"]["Magnitude"] > (125 + 125))
											or _fQ9_vfz["AssemblyAngularVelocity"]["Magnitude"] > (125 + 125)
										then
											_fQ9_vfz["AssemblyAngularVelocity"] = Vector3["zero"]
											_fQ9_vfz["AssemblyLinearVelocity"] = Vector3["zero"]
											if _D0lYS then
												_fQ9_vfz["CFrame"] = _D0lYS
											end
										elseif
											_fQ9_vfz["AssemblyLinearVelocity"]["Magnitude"] < 50
											and _fQ9_vfz["AssemblyAngularVelocity"]["Magnitude"] < 50
										then
											_D0lYS = _fQ9_vfz["CFrame"]
										end
									end)
								end
							end,
						})
						HubUI[18] = function()
							if _R5B57 then
								return
							end
							_R5B57 = true
							pcall(function()
								if HubUI[(0x2 * 5 - 1)] then
									if HubUI[(5 + 4)]["screen"] then
										HubUI[9]["screen"]["Enabled"] = false
										pcall(function()
											HubUI[9]["screen"]:Destroy()
										end)
									end
									if HubUI[(0x2 * 5 - 1)]["destroy"] then
										pcall(function()
											HubUI[(0x2 * 5 - 1)]:destroy()
										end)
									elseif HubUI[9]["connections"] then
										for _i9VGUD, _rBepenA in ipairs(HubUI[(5 + 4)]["connections"]) do
											pcall(function()
												_rBepenA:Disconnect()
											end)
										end
									end
								end
								if NotifyLib and NotifyLib["Destroy"] then
									pcall(NotifyLib["Destroy"])
								end
							end)
							for _ULJ9trjf in pairs(_Glgei) do
								_ULJ9trjf:Disconnect()
							end
							table["clear"](_Glgei)
							_Glgei = {}
							for _ttxs3 in pairs(_XNd6n) do
								RunService:UnbindFromRenderStep(_ttxs3)
							end
							table["clear"](_XNd6n)
							_XNd6n = {}
							_xQp2C(_i3Z2l)
							_i3Z2l = ({})[1]
							_q46lU["armedUntil"] = 0
							_q46lU["busy"] = false
							_mzv8k = false
							HubSettings["Misc"]["StretchEnabled"] = false
							HubSettings["Misc"]["LockOnEnabled"] = false
							if HubSettings["Misc"]["Magnet"] then
								HubSettings["Misc"]["Magnet"]["Enabled"] = false
							end
							_KjGi0a["stop"]()
							if HubSettings["Rage"]["NoSideDashCooldown"] then
								HubSettings["Rage"]["NoSideDashCooldown"] = false
								_zk6rn(false)
								if _Z0Hry then
									_Z0Hry:SetAttribute("CustomSideDashCooldown", ({})[1])
								end
							end
							HubSettings["Rage"]["Fling"]["LoopFling"] = false
							HubSettings["AutoTech"]["Enabled"] = false
							HubSettings["AutoLethal"]["Enabled"] = false
							HubSettings["PingSpoof"]["Enabled"] = false
							if HubSettings["DeviceSpoof"]["Enabled"] then
								HubSettings["DeviceSpoof"]["Enabled"] = false
								pcall(HubUI[(0 + 0x2 * 6)]["restore"])
							end
							HubSettings["Autoblock"]["Enabled"] = false
							HubSettings["Visuals"]["SelfChams"]["Enabled"] = false
							HubSettings["Visuals"]["Atmosphere"]["Enabled"] = false
							HubSettings["Visuals"]["Sky"]["Enabled"] = false
							HubSettings["Visuals"]["MotionBlur"]["Enabled"] = false
							_LZYNd()
							_J4f_N(_rJ2QD)
							for _ud_D3u, _VoR4oa5 in pairs(_M5vLN) do
								_J4f_N(_VoR4oa5)
							end
							for _IGYj20kY, _X7LAK in pairs(_lbsvM) do
								_J4f_N(_X7LAK)
							end
							table["clear"](_rJ2QD)
							table["clear"](_M5vLN)
							table["clear"](_lbsvM)
							if _r6zpd then
								pcall(function()
									_r6zpd:Destroy()
								end)
								_r6zpd = ({})[1]
							end
							if _q46lU["highlight"] then
								pcall(function()
									_q46lU["highlight"]:Destroy()
								end)
								_q46lU["highlight"] = ({})[1]
							end
							pcall(_S1SQ1, true)
							pcall(_gcElC["destroy"])
							pcall(_BZad1)
							pcall(_cny6G, false)
							pcall(_liq5P["restore"])
							pcall(_zuSl39H["set"], false)
							task["spawn"](pcall, _eoVGv["restore"], true)
							local _ud6LqH = _Z0Hry
							if _ud6LqH then
								for _lKQhWTf, _IBNpU in ipairs(_ud6LqH:GetChildren()) do
									if _IBNpU["Name"] == "KittyKorbloxCM" then
										pcall(function()
											_IBNpU:Destroy()
										end)
									end
								end
								local _jU1a8 = _ud6LqH:FindFirstChild("Right Leg")
								local _WaOzK = _jU1a8 and _jU1a8:FindFirstChild("KittyKorbloxSM")
								if _WaOzK then
									pcall(function()
										_WaOzK:Destroy()
									end)
								end
							end
							if HubSettings["Visuals"]["Korblox"] and _y4IB9 and _ElMhN then
								local _JkBS2, _wRynk = _y4IB9, _ElMhN
								task["spawn"](function()
									pcall(function()
										_JkBS2:ApplyDescription(_wRynk)
									end)
								end)
							end
							if _y4IB9 and _XXmEh then
								pcall(function()
									_y4IB9["AutoRotate"] = _XXmEh["AutoRotate"]
									_y4IB9["JumpPower"] = _XXmEh["JumpPower"]
								end)
							end
							if _gQE1u and _XXmEh and _XXmEh["HeadTransparency"] ~= ({})[1] then
								pcall(function()
									_gQE1u["Transparency"] = _XXmEh["HeadTransparency"]
								end)
							end
							if _N82Le and _XXmEh and _XXmEh["FaceTransparency"] ~= ({})[1] then
								pcall(function()
									_N82Le["Transparency"] = _XXmEh["FaceTransparency"]
								end)
							end
							_Upc_G()
							pcall(function()
								Lighting["GlobalShadows"] = _LMfeK["GlobalShadows"]
							end)
							pcall(function()
								Lighting["ClockTime"] = _LMfeK["ClockTime"]
							end)
							if _LMfeK["createdCC"] then
								pcall(function()
									_uMouq:Destroy()
								end)
							else
								pcall(function()
									_uMouq["Saturation"] = _LMfeK["Saturation"]
								end)
								pcall(function()
									_uMouq["Name"] = _LMfeK["originalCCName"]
								end)
							end
							pcall(function()
								_AuGxA["FieldOfView"] = _LMfeK["FieldOfView"]
							end)
							pcall(function()
								workspace["FallenPartsDestroyHeight"] = _Z4x1B
							end)
							for _XDqzv, _uJD2B in ipairs({
								_X1lLf,
								_MJJxA,
								_u6GG1,
								_ZgU0U,
								_kK9mB,
								_NSKGP,
								Enum["KeyCode"]["One"],
								Enum["KeyCode"]["Two"],
								Enum["KeyCode"]["Three"],
								Enum["KeyCode"]["Four"],
							}) do
								pcall(_S4jah, _uJD2B)
							end
						end
						if 1 == 0x1 then
							HubUI[(3 + 0x2 * 4)]["Front"]:toggle({
								["name"] = "Enabled",
								["def"] = false,
								["pointer"] = "Custom Front Dash Enabled",
								["callback"] = function(_llaZv)
									HubSettings["Rage"]["CustomFrontDash"]["Enabled"] = _llaZv
								end,
							})
						else
							(function()
								return (bit32 and 1304158077 or 0x672e)
							end)()
						end
						HubUI[(7 + 4)]["Front"]:toggle({
							["name"] = "Only On Keybind",
							["def"] = false,
							["pointer"] = "Custom front only on kebab",
							["callback"] = function(_I4Ony)
								HubSettings["Rage"]["CustomFrontDash"]["OnlyOnKeybind"] = _I4Ony
							end,
						})
						if 1 == 0x1 then
							HubUI[11]["Front"]:slider({
								["name"] = "Front Dash Distance",
								["def"] = (5 + 5),
								["max"] = 100,
								["min"] = (1 + 0),
								["rounding"] = true,
								["pointer"] = "Front Dash Distance",
								["callback"] = function(_XJACk)
									HubSettings["Rage"]["CustomFrontDash"]["Distance"] = _XJACk / (0 + 0x2 * 5)
								end,
							})
						else
							(function()
								return (bit32 and 53815 or 0xfdd2)
							end)()
						end
						HubUI[11]["Front"]:keybind({
							["name"] = "Keybind",
							["def"] = ({})[1],
							["pointer"] = "front keybind",
							["callback"] = function(_KsR2S)
								if not HubSettings["Rage"]["CustomFrontDash"]["Enabled"] then
									return
								end
								if _XjK2G() then
									_t6uaX(_reriI(HubSettings["Rage"]["CustomFrontDash"]["Distance"])[1], (50 / 0x3e8))
								end
							end,
						})
						HubUI[(3 + 0x2 * 4)]["Side"]:toggle({
							["name"] = "No Side Dash Cooldown",
							["def"] = HubSettings["Rage"]["NoSideDashCooldown"],
							["pointer"] = "No Side Dash Cooldown",
							["tooltip"] = "Removes cooldown between side dashes so you can dash continuously",
							["callback"] = function(_l3Y60)
								HubSettings["Rage"]["NoSideDashCooldown"] = _l3Y60
								if _l3Y60 then
									pcall(function()
										if _Z0Hry then
											_Z0Hry:SetAttribute("CustomSideDashCooldown", 0)
										end
									end)
									_zk6rn(true)
								else
									pcall(function()
										if _Z0Hry then
											_Z0Hry:SetAttribute("CustomSideDashCooldown", ({})[1])
											_Z0Hry:SetAttribute("AfterimageDash", ({})[1])
										end
									end)
									_zk6rn(false)
								end
							end,
						})
						if 129 == 0x81 then
							HubUI[11]["Side"]:toggle({
								["name"] = "Enabled",
								["def"] = false,
								["pointer"] = "Custom Side Dash Enabled",
								["callback"] = function(_YjLuP)
									HubSettings["Rage"]["CustomSideDash"]["Enabled"] = _YjLuP
								end,
							})
						else
							(function()
								return (bit32 and 9443 or 0x4496)
							end)()
						end
						HubUI[(0x2 * 7 - 3)]["Side"]:toggle({
							["name"] = "Only On Keybind",
							["def"] = false,
							["pointer"] = "Side only on keybind",
							["callback"] = function(_zKdh6)
								HubSettings["Rage"]["CustomSideDash"]["OnlyOnKeybind"] = _zKdh6
							end,
						})
						HubUI[11]["Side"]:slider({
							["name"] = "Side Dash Distance",
							["def"] = 10,
							["max"] = (0 + 0x2 * 50),
							["min"] = (1 + 0),
							["rounding"] = true,
							["pointer"] = "Side Dash Distance",
							["callback"] = function(_WGMG0)
								HubSettings["Rage"]["CustomSideDash"]["Distance"] = _WGMG0 / (0x2 * 5 - 0)
							end,
						})
						HubUI[11]["Side"]:dropdown({
							["name"] = "Dash Side",
							["def"] = HubSettings["Rage"]["CustomSideDash"]["Side"],
							["max"] = 3,
							["options"] = { "Right", "Left", "Straight" },
							["pointer"] = "CustomSideDashType",
							["callback"] = function(_N2nf4)
								HubSettings["Rage"]["CustomSideDash"]["Side"] = _N2nf4
							end,
						})
						HubUI[11]["Side"]:keybind({
							["name"] = "Keybind",
							["def"] = ({})[1],
							["pointer"] = "Side keybind",
							["callback"] = function(_w4QK1)
								if
									not HubSettings["Rage"]["CustomSideDash"]["Enabled"]
									or not (_y4IB9 and _fx2la and _y4IB9["Health"] > 0)
								then
									return
								end
								_S4jah(_X1lLf)
								_S4jah(_u6GG1)
								if HubSettings["Rage"]["CustomSideDash"]["Side"] == "Straight" then
									_RnQ1A5M(90)
								end
								if
									HubSettings["Rage"]["CustomSideDash"]["Side"] == "Straight"
									or HubSettings["Rage"]["CustomSideDash"]["Side"] == "Right"
								then
									_IDvSS(_ZgU0U)
								elseif HubSettings["Rage"]["CustomSideDash"]["Side"] == "Left" then
									_IDvSS(_MJJxA)
								end
								if HubSettings["Rage"]["CustomSideDash"]["Jump"] then
									_IDvSS(_NSKGP)
								end
								task["wait"](((1 + 0x2 * 2) / 0x3e8))
								_kvld1(_kK9mB)
								if HubSettings["Rage"]["CustomSideDash"]["RemoveInertia"] then
									task["wait"](HubSettings["Rage"]["CustomSideDash"]["RMIDelay"])
									local _XbXO4 = _fx2la:FindFirstChild("dodgevelocity")
									if HubSettings["Rage"]["CustomSideDash"]["RemoveInertia"] and _XbXO4 then
										_XbXO4:Destroy()
										_ZGKm8(_j089A["rsideDash"])
										_ZGKm8(_j089A["lsideDash"])
									end
								end
								_S4jah(_NSKGP)
								_S4jah(_ZgU0U)
								_S4jah(_MJJxA)
								if HubSettings["Rage"]["CustomSideDash"]["Side"] == "Straight" then
									_RnQ1A5M(-90)
								end
								_t6uaX(HubSettings["Rage"]["CustomSideDash"]["Distance"], ((25 + 25) / 0x3e8))
							end,
						})
						HubUI[(7 + 4)]["Side"]:toggle({
							["name"] = "Jump",
							["def"] = false,
							["pointer"] = "SDJ",
							["callback"] = function(_KVKWP)
								HubSettings["Rage"]["CustomSideDash"]["Jump"] = _KVKWP
							end,
						})
						HubUI[11]["Side"]:toggle({
							["name"] = "Remove Inertia",
							["def"] = false,
							["pointer"] = "Remove Ineria",
							["callback"] = function(_ku2oA)
								HubSettings["Rage"]["CustomSideDash"]["RemoveInertia"] = _ku2oA
							end,
						})
						HubUI[(7 + 4)]["Side"]:slider({
							["name"] = "RM Inertia Delay",
							["def"] = (35 + 35),
							["max"] = 100,
							["min"] = 1,
							["rounding"] = true,
							["pointer"] = "RMID",
							["callback"] = function(_Z1gAV)
								HubSettings["Rage"]["CustomSideDash"]["RMIDelay"] = _Z1gAV / 1000
							end,
						})
						HubUI[11]["Misc"]:toggle({
							["name"] = "Display Hitbox",
							["def"] = false,
							["pointer"] = "Display Hitbox",
							["callback"] = function(_yeg6a)
								if _r6zpd then
									pcall(function()
										_r6zpd:Destroy()
									end)
									_r6zpd = ({})[1]
								end
								_vA5WJ(_lH0uIxY["getping"])
								_vA5WJ(_lH0uIxY["hitbox"])
								_lH0uIxY["getping"], _lH0uIxY["hitbox"] = ({})[1], ({})[1]
								if _yeg6a then
									_r6zpd = Instance["new"]("Part")
									_r6zpd["Size"] = Vector3["new"]((0x2 * 1 - 0), 2, 1)
									_r6zpd["Color"] = Color3["new"]((1 + 0), 0, 0)
									_r6zpd["Transparency"] = (500 / 0x3e8)
									_r6zpd["Anchored"] = true
									_r6zpd["CanCollide"] = false
									_r6zpd["CanQuery"] = false
									_r6zpd["CanTouch"] = false
									_r6zpd["Name"] = "PingGhost"
									_r6zpd["Parent"] = workspace
									_lH0uIxY["getping"] = _l3G1i(RunService["Heartbeat"], function(_LqBdY)
										local _wHwsW = tick()
										if not (_fx2la and _fx2la["Parent"]) then
											return
										end
										table["insert"](_vjMDS, { ["time"] = _wHwsW, ["cf"] = _fx2la["CFrame"] })
										while _vjMDS[1] and _wHwsW - _vjMDS[(1 + 0)]["time"] > (1 + 1) do
											table["remove"](_vjMDS, 1)
										end
									end)
									_lH0uIxY["hitbox"] = _l3G1i(RunService["RenderStepped"], function()
										local _XxM8d = tick() - _p44Zr((0x2 * 500 - 0))
										local _y5TZl = _izwxu0(_XxM8d)
										if _y5TZl and _r6zpd then
											_r6zpd["CFrame"] = _y5TZl
										end
									end)
								end
							end,
						})
						HubUI[(3 + 0x2 * 4)]["Misc"]:button({
							["name"] = "Rejoin",
							["callback"] = function()
								if #PlayersService:GetPlayers() <= (1 + 0x2 * 0) then
									Services["TeleportService"]:Teleport(game["PlaceId"], HubLocalPlayer)
								else
									Services["TeleportService"]:TeleportToPlaceInstance(
										game["PlaceId"],
										game["JobId"],
										HubLocalPlayer
									)
								end
							end,
						})
						if 129 == 0x81 then
							HubUI[(3 + 0x2 * 4)]["Misc"]:button({
								["name"] = "Copy Discord Invite",
								["callback"] = function()
									local _JDiR8 = EnvAccess["setclipboard"]
										or EnvAccess["toclipboard"]
										or (EnvAccess["Clipboard"] and EnvAccess["Clipboard"]["set"])
									if _JDiR8 then
										pcall(_JDiR8, _DTbHC)
										_OS0SJ({ ["Title"] = "RXM HUB", ["Description"] = "copied " .. _DTbHC })
									else
										_OS0SJ({
											["Title"] = "RXM HUB",
											["Description"] = "your executor can't copy, the invite is " .. _DTbHC,
										})
									end
								end,
							})
						else
							(function()
								return (bit32 and (46900 * 0x3d % 0x10000) or 0x954e)
							end)()
						end
						if 0 == 0x0 then
							HubUI[11]["Misc"]:button({
								["name"] = "Panic",
								["tooltip"] = "Shuts down the script immediately",
								["callback"] = HubUI[(0x2 * 9 - 0)],
							})
						else
							(function()
								return (bit32 and 51363 or 0xc6a4)
							end)()
						end
						if 1 == 0x1 then
							HubUI[(3 + 0x2 * 4)]["Misc"]:keybind({
								["name"] = "GUI Keybind",
								["def"] = Enum["KeyCode"]["RightShift"],
								["allowed"] = 0,
								["pointer"] = "GUI Keybind",
								["changeCallback"] = function(_kU_x0)
									HubUI[9]:setkey(_kU_x0)
									HubUI[9]["key"] = _kU_x0
								end,
							})
						else
							(function()
								return ((0x9f2d % 0x2 == 0x0) and (bit32 and 20374 or 0x0) or (bit32 and 15742 or 0x0))
							end)()
						end
						HubUI[(7 + 4)]["Misc"]:toggle({
							["name"] = "Screen Strench Enabled",
							["def"] = false,
							["pointer"] = "Stretch Screen Toggle",
							["callback"] = function(_v9iG6)
								HubSettings["Misc"]["StretchEnabled"] = _v9iG6
								_vA5WJ(_lH0uIxY["stretch"])
								_lH0uIxY["stretch"] = ({})[1]
								if _v9iG6 then
									_lH0uIxY["stretch"] = _l3G1i(RunService["RenderStepped"], function()
										_AuGxA["CFrame"] = (
											_AuGxA["CFrame"]
											* CFrame["new"](
												0,
												0,
												0,
												(0x2 * 1 - 1),
												0,
												0,
												0,
												HubSettings["Misc"]["StretchValue"],
												0,
												0,
												0,
												1
											)
										)
									end)
								end
							end,
						})
						if 0 == 0x0 then
							HubUI[11]["Misc"]:slider({
								["name"] = "Screen Stretch Value",
								["def"] = (0 + 0x2 * 50),
								["max"] = (0x2 * 60 - 0),
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "Stretch Screen Value",
								["callback"] = function(_KDURS)
									HubSettings["Misc"]["StretchValue"] = _KDURS / (50 + 50)
								end,
							})
						else
							(function()
								return (bit32 and 63109 or 0x5df6)
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(0x2 * 7 - 3)]["Misc"]:slider({
								["name"] = "Day Time",
								["def"] = math["floor"](Lighting["ClockTime"]),
								["max"] = 24,
								["min"] = 0,
								["rounding"] = true,
								["pointer"] = "CycleTime",
								["tooltip"] = "Time of day (0-24). Drag or click box to type",
								["callback"] = function(_l4rjf)
									_IeaiYt2E(Lighting, "ClockTime", _l4rjf)
								end,
							})
						else
							(function()
								return (bit32 and (39438 * 0x3d % 0x10000) or 0x9f5c)
							end)()
						end
						HubUI[(7 + 4)]["Misc"]:toggle({
							["name"] = "Lock On Enabled",
							["def"] = false,
							["pointer"] = "Lock On Enabled",
							["callback"] = function(_wlfHx)
								HubSettings["Misc"]["LockOnEnabled"] = _wlfHx
								_vA5WJ(_lH0uIxY["lockon"])
								_lH0uIxY["lockon"] = ({})[1]
							end,
						})
						HubUI[(0x2 * 7 - 3)]["Misc"]:slider({
							["name"] = "Lock On Precision",
							["def"] = (50 + 50),
							["max"] = (0x2 * 50 - 0),
							["min"] = 0,
							["rounding"] = true,
							["pointer"] = "lockonprec",
							["callback"] = function(_XI_rk)
								HubSettings["Misc"]["LockOnPrecision"] = _XI_rk / 100
							end,
						})
						HubUI[(0x2 * 7 - 3)]["Misc"]:keybind({
							["name"] = "Lock On Keybind",
							["def"] = ({})[1],
							["pointer"] = "Lock On Keybind",
							["callback"] = function(_yqbcb)
								if not HubSettings["Misc"]["LockOnEnabled"] then
									return
								end
								if _lH0uIxY["lockon"] then
									_lH0uIxY["lockon"]:Disconnect()
									_lH0uIxY["lockon"] = ({})[1]
								else
									local _J5kZQ = ({})[1]
									local _wdPkn = ({})[1]
									local _HVms6 = 100
									for _iLkSj, _Jh3WF in pairs(PlayersService:GetPlayers()) do
										local _Ucfsf = _Jh3WF["Character"]
										if _Jh3WF ~= HubLocalPlayer and _Ucfsf then
											local _vH7cW = _Ucfsf:FindFirstChild("HumanoidRootPart")
											local _Kcvo4 = _Ucfsf:FindFirstChild("Humanoid")
											if _vH7cW and _Kcvo4 and _Kcvo4["Health"] > 0 then
												local _Vij_L, _wLk4K = _AuGxA:WorldToViewportPoint(_vH7cW["Position"])
												if _wLk4K then
													local _Htk9x = Vector2["new"](HubMouse["X"], HubMouse["Y"])
													local _id5g5 = Vector2["new"](_Vij_L["X"], _Vij_L["Y"])
													local _JQlyq = (_Htk9x - _id5g5)["Magnitude"]
													if _JQlyq < _HVms6 then
														_HVms6 = _JQlyq
														_J5kZQ = _vH7cW
														_wdPkn = _Kcvo4
													end
												end
											end
										end
									end
									if not _J5kZQ or not _wdPkn then
										return
									end
									_lH0uIxY["lockon"] = _l3G1i(RunService["Heartbeat"], function()
										if not _J5kZQ["Parent"] or _wdPkn["Health"] <= 0 then
											_lH0uIxY["lockon"]:Disconnect()
											_lH0uIxY["lockon"] = ({})[1]
											return
										end
										_RnQ1A5M(
											({})[1],
											_e71S9["pos"](_J5kZQ),
											false,
											false,
											HubSettings["Misc"]["LockOnPrecision"]
										)
									end)
								end
							end,
						})
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(0x2 * 7 - 3)]["Misc"]:toggle({
								["name"] = "Mobile KW Button",
								["def"] = HubUI[16],
								["pointer"] = "Mobile KW Button Toggle",
								["callback"] = function(_UINvpd)
									HubUI[(9 + 8)](_UINvpd)
								end,
							})
						else
							(function()
								return (bit32 and 2143653870 or 0xf0d0)
							end)()
						end
						HubUI[(7 + 4)]["Notifs"]:toggle({
							["name"] = "Global Enabled",
							["def"] = true,
							["pointer"] = "Notifications Toggle",
							["callback"] = function(_HPWtdWB)
								HubSettings["Notifications"]["GlobalEnabled"] = _HPWtdWB
							end,
						})
						if 16 == 0x10 then
							HubUI[(7 + 4)]["Notifs"]:toggle({
								["name"] = "Ult Notifications",
								["def"] = true,
								["pointer"] = "Ult Notifications Toggle",
								["callback"] = function(_ibKhmC)
									HubSettings["Notifications"]["UltEnabled"] = _ibKhmC
								end,
							})
						else
							(function()
								return (bit32 and (13286 * 0x3d % 0x10000) or 0x30a4)
							end)()
						end
						if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
							HubUI[(3 + 0x2 * 4)]["Notifs"]:toggle({
								["name"] = "Death Counter Notifications",
								["def"] = true,
								["pointer"] = "Death Counter Notifications Toggle",
								["callback"] = function(_t3_Qv)
									HubSettings["Notifications"]["DeathCounterEnabled"] = _t3_Qv
								end,
							})
						else
							(function()
								return (bit32 and 542254192 or 0xe5e8)
							end)()
						end
						HubUI[11]["Notifs"]:toggle({
							["name"] = "Auto Tech Notifications",
							["def"] = true,
							["pointer"] = "Auto Tech Notifications Toggle",
							["callback"] = function(_Z445r)
								HubSettings["Notifications"]["AutoTechEnabled"] = _Z445r
							end,
						})
						if 16 == 0x10 then
							HubUI[11]["Notifs"]:toggle({
								["name"] = "Fling Notifications",
								["def"] = true,
								["pointer"] = "Fling Notifications Toggle",
								["callback"] = function(_GNcYSSx5)
									HubSettings["Notifications"]["FlingEnabled"] = _GNcYSSx5
								end,
							})
						else
							(function()
								return (bit32 and 53065 or 0xc70d)
							end)()
						end
						HubUI[(5 + 5)]["Combat"]:openpage()
					end
				else
					(function()
						return (bit32 and 1745726497 or 0x8520)
					end)()
				end
				for _Bs1cEVQ, _cRFQmOKp in pairs(PlayersService:GetPlayers()) do
					HubUI[3](_cRFQmOKp)
				end
				_l3G1i(PlayersService["PlayerAdded"], HubUI[(3 + 0x2 * 0)])
				if 16 == 0x10 then
					_l3G1i(PlayersService["PlayerRemoving"], function(_H4H9K)
						_J4f_N(_lbsvM[_H4H9K])
						_J4f_N(_M5vLN[_H4H9K])
						_lbsvM[_H4H9K] = ({})[1]
						_M5vLN[_H4H9K] = ({})[1]
						_RWZpc[_H4H9K["Name"]] = ({})[1]
					end)
				else
					(function()
						return (bit32 and 32736 or 0x58f0)
					end)()
				end
				_sLGb1(true)
				if (0x7f * 0x2 + 0x1) % 0x100 == 0xff then
					if HubLocalPlayer["Character"] then
						task["spawn"](pcall, _oP95qX7E, HubLocalPlayer["Character"])
					end
				else
					(function()
						return (bit32 and 58566 or 0x73e4)
					end)()
				end
				_l3G1i(HubLocalPlayer["CharacterAdded"], function(_CsHCpB)
					task["spawn"](pcall, _oP95qX7E, _CsHCpB)
				end)
				_l3G1i(HubLocalPlayer["CharacterRemoving"], function(_RSNI01_)
					pcall(_dXK4f)
				end)
				if _f5mDQ["Thrown"] and _f5mDQ["Thrown"]["DescendantAdded"] then
					_l3G1i(_f5mDQ["Thrown"]["DescendantAdded"], _SXQgY)
				end
				if 16 == 0x10 then
					_l3G1i(_f5mDQ["Terrain"]["DescendantAdded"], _SXQgY)
				else
					(function()
						return (bit32 and 51613 or 0x8995)
					end)()
				end
				if 0 == 0x0 then
					_l3G1i(Lighting:GetPropertyChangedSignal("GlobalShadows"), function()
						if HubSettings["Visuals"]["NoShadows"] and Lighting["GlobalShadows"] then
							Lighting["GlobalShadows"] = false
						end
					end)
				else
					(function()
						return (bit32 and 55597 or 0x397c)
					end)()
				end
				if 16 == 0x10 then
					_l3G1i(Lighting:GetPropertyChangedSignal("ClockTime"), function()
						if _liq5P["locking"] or not HubSettings["Visuals"]["Sky"]["Enabled"] then
							return
						end
						local _wFNTdn6K = _liq5P["presets"][HubSettings["Visuals"]["Sky"]["Preset"]]
						if _wFNTdn6K and math["abs"](Lighting["ClockTime"] - _wFNTdn6K["clock"]) > ((0 + 0x2 * 25) / 0x3e8) then
							_liq5P["locking"] = true
							Lighting["ClockTime"] = _wFNTdn6K["clock"]
							_liq5P["locking"] = false
						end
					end)
				else
					(function()
						return (bit32 and 4995 or 0x5613)
					end)()
				end
				if 1 == 0x1 then
					_l3G1i(Lighting["ChildAdded"], function(_rgCd5)
						if HubSettings["Visuals"]["Sky"]["Enabled"] and (_rgCd5:IsA("Sky") or _rgCd5:IsA("Atmosphere")) then
							if _rgCd5["Name"] ~= "KittySky" and _rgCd5["Name"] ~= "KittySkyAtmosphere" then
								task["defer"](function()
									if HubSettings["Visuals"]["Sky"]["Enabled"] then
										_liq5P["apply"](true)
									end
								end)
							end
						end
					end)
				else
					(function()
						return ((0x71ce % 0x2 == 0x0) and (bit32 and 14567 or 0x0) or (bit32 and 63481 or 0x0))
					end)()
				end
				if 0 == 0x0 then
					_l3G1i(HubLocalPlayer:GetAttributeChangedSignal("S_AutoUnequip"), function()
						_TLppj = HubLocalPlayer:GetAttribute("S_AutoUnequip")
					end)
				else
					(function()
						return (bit32 and 30430 or 0x7236)
					end)()
				end
				_l3G1i(UserInputService["InputBegan"], function(_W6Rz6, _ZSpdp)
					if _ZSpdp then
						return
					end
					if _W6Rz6["KeyCode"] == _kK9mB and _Z0Hry then
						if
							not UserInputService:IsKeyDown(_ZgU0U)
							and not UserInputService:IsKeyDown(_MJJxA)
							and HubSettings["Misc"]["NoDashEndLag"]
							and not UserInputService:IsKeyDown(_u6GG1)
							and _Z0Hry:FindFirstChild("UsedDash")
						then
							_XjK2G()
						elseif
							HubSettings["Rage"]["NoSideDashCooldown"]
							and (UserInputService:IsKeyDown(_ZgU0U) or UserInputService:IsKeyDown(_MJJxA))
							and _Z0Hry
						then
							local _UkHN6 = _Z0Hry:FindFirstChild("InDash")
							if _UkHN6 then
								_UkHN6:Destroy()
							end
							local _z9qBF = _Z0Hry:FindFirstChild("UsedDash")
							if _z9qBF then
								_z9qBF:Destroy()
							end
						end
					end
				end)
				if 16 == 0x10 then
					_l3G1i(RunService["Heartbeat"], function()
						if _y4IB9 and _mzv8k then
							_y4IB9["AutoRotate"] = false
						end
						if HubSettings["Rage"]["NoSideDashCooldown"] and _Z0Hry then
							if _Z0Hry:GetAttribute("CustomSideDashCooldown") ~= 0 then
								pcall(_Z0Hry["SetAttribute"], _Z0Hry, "CustomSideDashCooldown", 0)
							end
							local _Oa1Gj = _Z0Hry:FindFirstChild("InDash")
							if _Oa1Gj then
								pcall(_Oa1Gj["Destroy"], _Oa1Gj)
							end
							local _JV2UQ = _Z0Hry:FindFirstChild("UsedDash")
							if _JV2UQ then
								pcall(_JV2UQ["Destroy"], _JV2UQ)
							end
							_zk6rn(true)
						end
					end)
				else
					(function()
						return (bit32 and 18555 or 0x4abb)
					end)()
				end
				if UserInputService["TouchEnabled"] and not UserInputService["KeyboardEnabled"] then
					HubUI[(7 + 0x2 * 0)]()
				end
			end)(Shim.lib, Shim.notifier)
			Shim.flush()
		end)
	end

	do
		local t = 0
		local borderTr, glowI = 0.6, 0.45
		local lastR, glowColor = -1, accent
		connect(RunService.Heartbeat, function(rawDt)
			if not alive then return end
			local dt = math.min(rawDt, 0.05)
			t = t + dt
			for _, s in pairs(sp) do
				stepSpring(s, dt)
			end
			for _, g in ipairs(groups) do
				stepSpring(g.a, dt)
				stepSpring(g.s, dt)
				local a = math.clamp(g.a.x, 0, 1)
				g.frame.GroupTransparency = 1 - a
				g.scale.Scale = math.max(g.s.x, 0.05)
				if g.a.t == 0 and a < 0.012 and g.frame.Visible then
					g.frame.Visible = false
				end
			end
			local squash, stretch = 0, 0
			if fx.squash then
				squash = math.clamp(sp.w.v / 1100, -1, 1) * 3.4
				stretch = math.clamp(sp.h.v / 1300, -1, 1) * 2.6
			end
			local w = math.max(sp.w.x - stretch, 40)
			local h = math.max(sp.h.x - squash, 14)
			local r = math.clamp(sp.r.x, 2, h / 2)
			shell.Size = UDim2.fromOffset(w, h)
			shell.Position = UDim2.new(0.5, sp.ox.x, 0, PAD_Y + sp.oy.x + sp.hy.x)
			shellScale.Scale = UI_SCALE * math.max(sp.press.x, 0.2) * math.max(sp.show.x, 0.001)
			islandCorner.CornerRadius = UDim.new(0, r)
			borderCorner.CornerRadius = UDim.new(0, r)
			if math.abs(r - lastR) > 0.02 then
				lastR = r
				for _, glow in ipairs(glows) do
					glow.corner.CornerRadius = UDim.new(0, r + glow.off / 2)
				end
			end
			for i = #pulses, 1, -1 do
				local pulse = pulses[i]
				if pulse.corner.Parent then
					pulse.corner.CornerRadius = UDim.new(0, r)
				else
					table.remove(pulses, i)
				end
			end
			if hidden and sp.show.x < 0.02 then
				shell.Visible = false
			end
			local targetBorder = state == "expanded" and 0.12 or (state == "notify" and 0.28 or 0.6)
			borderTr = borderTr + (targetBorder - borderTr) * math.min(1, dt * 8)
			border.Transparency = fx.border and borderTr or 1
			if fx.border then
				borderGradient.Rotation = (borderGradient.Rotation + dt * borderSpeed) % 360
			end
			local speed = math.abs(sp.w.v) + math.abs(sp.h.v) * 2
			local targetGlow = (state == "expanded" and 0.75 or (state == "notify" and 1 or 0.45))
				+ math.min(speed / 1400, 0.5) + glowKick
			glowKick = math.max(0, glowKick - dt * 1.3)
			glowI = glowI + (targetGlow - glowI) * math.min(1, dt * 10)
			local breathe = 0.9 + 0.1 * math.sin(t * 2.2)
			for _, glow in ipairs(glows) do
				local tr = 1
				if fx.glow then
					tr = 1 - math.clamp(glow.alpha * glowI * breathe, 0, 0.9)
				end
				if math.abs(glow.frame.BackgroundTransparency - tr) > 0.002 then
					glow.frame.BackgroundTransparency = tr
				end
			end
			local tintTarget = accent
			if state == "notify" and currentItem then
				tintTarget = kindColor(currentItem.kind)
			end
			tintColor = tintColor:Lerp(tintTarget, math.min(1, dt * 7))
			if tintColor ~= glowColor then
				glowColor = tintColor
				for _, glow in ipairs(glows) do
					glow.frame.BackgroundColor3 = tintColor
				end
			end
			local drift = math.abs(tintColor.R - paintedTint.R) + math.abs(tintColor.G - paintedTint.G) + math.abs(tintColor.B - paintedTint.B)
			if drift > 0.006 then
				paintBorder(tintColor)
			end
			if idleG.frame.Visible then
				local ph = (t * 0.9) % 1
				idleHalo.Size = UDim2.fromOffset(8 + 14 * ph, 8 + 14 * ph)
				idleHalo.BackgroundTransparency = 0.45 + 0.55 * ph
				for i, bar in ipairs(idleBars) do
					local amp = 0.5 + 0.5 * math.sin(t * (4.2 + i * 1.6) + i * 1.9)
					bar.Size = UDim2.fromOffset(3, 3 + 11 * amp)
				end
				local p = (t % 3.4) / 2.4
				idleGradient.Offset = Vector2.new(-1 + 2 * math.min(p, 1), 0)
			end
			if state == "notify" and currentItem then
				local item = currentItem
				if item.live then
					local target = item.progress or (0.15 + 0.1 * math.sin(t * 3))
					ringP = ringP + (target - ringP) * math.min(1, dt * 8)
				else
					ringP = 1 - math.clamp((os.clock() - noticeStart) / item.duration, 0, 1)
				end
				notice.ring.Set(ringP)
			end
			if expG.frame.Visible then
				if fx.neon then
					local p = (t * 0.45) % 1.4
					neonGradient.Offset = Vector2.new(-1 + 2 * math.min(p, 1), 0)
				end
				if fx.shimmer then
					local p = (t % 3.4) / 2.4
					titleGradient.Offset = Vector2.new(-1 + 2 * math.min(p, 1), 0)
				end
				local ph = (t * 0.8) % 1
				logoHalo.Size = UDim2.fromOffset(10 + 16 * ph, 10 + 16 * ph)
				logoHalo.BackgroundTransparency = 0.5 + 0.5 * ph
				if fx.aurora then
					for _, blob in ipairs(auroraBlobs) do
						local holder = blob.holder
						if blob.idx == 1 then
							holder.Position = UDim2.fromScale(0.22 + 0.14 * math.sin(t * 0.35), 0.88 + 0.08 * math.cos(t * 0.3))
						else
							holder.Position = UDim2.fromScale(0.82 + 0.1 * math.cos(t * 0.28), 0.3 + 0.12 * math.sin(t * 0.4))
						end
					end
				end
			end
		end)
	end
	local api = {}
	api.Destroy = destroy
	api.Notify = function(heading, message, duration, kind)
		notify(heading, message, duration, kind)
	end
	api.Live = function(heading, message, kind)
		local item = {heading = tostring(heading or ""), message = tostring(message or ""), kind = kind or "info", live = true}
		local handle = {}
		function handle:Update(newHeading, newMessage, newKind, progress)
			if newHeading then item.heading = tostring(newHeading) end
			if newMessage then item.message = tostring(newMessage) end
			if newKind then item.kind = newKind end
			if progress ~= nil then item.progress = progress end
			if item.ui and alive then
				item.ui.n:Swap(item.kind, item.heading, item.message)
			end
		end
		function handle:Finish(newHeading, newMessage, newKind, hold)
			handle:Update(newHeading, newMessage, newKind, 1)
			item.finishAt = os.clock() + (hold or 1.6)
		end
		if hidden or not alive then return handle end
		floatToast(item)
		return handle
	end
	api.Expand = function()
		setHidden(false)
		setState("expanded")
	end
	api.Collapse = function()
		setState("idle")
	end
	api.Hide = function()
		setHidden(true)
	end
	api.Show = function()
		setHidden(false)
	end
	if getgenv then
		getgenv().RXMHUBGUI = api
	end
	applyFX()
	selectTab(tabTech)
	local function applyTargets(profile, delayH)
		local tw, th, tr
		if state == "idle" then
			local gh = IDLE_H + (hover and 4 or 0)
			tw, th, tr = IDLE_W + (hover and 16 or 0), gh, gh / 2
		elseif state == "notify" then
			tw, th, tr = noticeW, NOTIFY_H, NOTIFY_H / 2
		else
			tw, th, tr = W, H, PANEL_R
		end
		if profile then
			applyProfile(profile)
		end
		sp.w.t, sp.r.t = tw, tr
		hTok = hTok + 1
		local tok = hTok
		if delayH and delayH > 0 then
			task.delay(delayH, function()
				if tok == hTok and alive then
					sp.h.t = th
				end
			end)
		else
			sp.h.t = th
		end
	end
	local function scheduleTargets(profile, delay, delayH)
		morphTok = morphTok + 1
		local tok = morphTok
		if delay > 0 then
			task.delay(delay, function()
				if tok == morphTok and alive then
					applyTargets(profile, delayH)
				end
			end)
		else
			applyTargets(profile, delayH)
		end
	end
	local pillHit = new("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = island,
	})
	local runNotifier
	setState = function(newState)
		if not alive or state == newState then return end
		local prev = state
		state = newState
		hover = false
		pillHit.Visible = newState ~= "expanded"
		backdrop.Visible = newState == "expanded"
		if newState == "expanded" then
			currentItem = nil
			if prev == "idle" then
				idleOutro()
			end
			scheduleTargets(PROFILES.open, 0, 0.05)
			do
				local maxX, minY, maxY = panelLimits()
				sp.ox.t = math.clamp(panelPos.x, -maxX, maxX)
				sp.oy.t = math.clamp(panelPos.y, minY, maxY)
			end
			sp.w.v = sp.w.v + 220
			sp.h.v = sp.h.v + 100
			fadeGroup(idleG, false, 0, 0.1)
			fadeGroup(notifyG, false, 0, 0.1)
			fadeGroup(expG, true, 0.13, 0.4)
			revealChrome(0.13)
			if currentTab then
				revealTab(currentTab, 0.2, 0)
			end
			for _, item in ipairs(queue) do
				floatToast(item)
			end
			queue = {}
			ringFlash()
		elseif newState == "notify" then
			if prev == "idle" then
				idleOutro()
			end
			scheduleTargets(PROFILES.pop, 0, 0)
			fadeGroup(idleG, false, 0, 0.1)
			fadeGroup(expG, false, 0, 0.1)
			fadeGroup(notifyG, true, 0.07, 0.3)
		else
			if prev == "expanded" then
				scheduleTargets(PROFILES.minimize, 0, 0)
				sp.ox.t, sp.oy.t = 0, 0
				sp.w.v = sp.w.v - 60
				hideChrome()
				fadeGroup(notifyG, false, 0, 0.1)
				fadeGroup(expG, false, 0, 0.2)
				fadeGroup(idleG, true, 0.2, 0.32)
				idleIntro(0.2)
			else
				scheduleTargets(PROFILES.settle, 0.03, 0)
				sp.w.v = sp.w.v - 160
				fadeGroup(notifyG, false, 0, 0.1)
				fadeGroup(expG, false, 0, 0.1)
				fadeGroup(idleG, true, 0.16, 0.32)
				idleIntro(0.16)
			end
			task.delay(0.5, function()
				if runNotifier then
					runNotifier()
				end
			end)
		end
	end
	notify = function(heading, message, duration, kind)
		if not alive or hidden then return end
		floatToast({
			heading = tostring(heading or ""),
			message = tostring(message or ""),
			duration = duration or 3.5,
			kind = kind or "info",
		})
	end
	local hideTok = 0
	setHidden = function(on)
		if not alive then return end
		hidden = on and true or false
		hideTok = hideTok + 1
		local tok = hideTok
		if hidden then
			local wasPanel = state == "expanded"
			setState("idle")
			task.delay(wasPanel and 0.34 or 0, function()
				if tok ~= hideTok or not alive then return end
				sp.show.k, sp.show.d = 220, 2 * math.sqrt(220)
				sp.hy.k, sp.hy.d = 220, 2 * math.sqrt(220)
				sp.show.t = 0
				sp.hy.t = -(IDLE_H + PAD_Y + 10)
			end)
		else
			shell.Visible = true
			sp.show.k, sp.show.d = 170, 2 * 0.72 * math.sqrt(170)
			sp.hy.k, sp.hy.d = 170, 2 * 0.76 * math.sqrt(170)
			sp.show.t = 1
			sp.hy.t = 0
			sp.w.v = sp.w.v + 140
			sp.h.v = sp.h.v + 80
			ringFlash()
		end
	end
	pillHit.MouseEnter:Connect(function()
		hover = true
		applyTargets()
	end)
	pillHit.MouseLeave:Connect(function()
		hover = false
		sp.press.t = 1
		applyTargets()
	end)
	pillHit.MouseButton1Click:Connect(function()
		if swiped or hidden then return end
		playClick()
		setState("expanded")
	end)
	backdrop.MouseButton1Click:Connect(function()
		if state == "expanded" then
			playClick()
			setState("idle")
		end
	end)
	do
		local dragging, dragStart, startOx, startOy = false, nil, 0, 0
		header.InputBegan:Connect(function(input)
			if isPress(input) and state == "expanded" then
				dragging = true
				dragStart = input.Position
				startOx, startOy = sp.ox.t, sp.oy.t
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and isMove(input) then
				local delta = input.Position - dragStart
				local maxX, minY, maxY = panelLimits()
				sp.ox.t = math.clamp(startOx + delta.X, -maxX, maxX)
				sp.oy.t = math.clamp(startOy + delta.Y, minY, maxY)
				panelPos.x, panelPos.y = sp.ox.t, sp.oy.t
			end
		end)
	end
	applyTargets()
	selectTab(tabTech)
	applyProfile(PROFILES.pop)
	sp.w.x, sp.h.x, sp.r.x = 24, 24, 12
	sp.w.v, sp.h.v = 140, 90
	sp.show.x = 0.5
	sp.hy.x = -34
	fadeGroup(idleG, true, 0.28, 0.4)
	idleIntro(0.3)
	ringFlash()
end
local introOk = pcall(PlayScreenIntro, Main)
if not introOk then
	Main()
end
