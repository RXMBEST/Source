local INTRO_TEXT = "亗 『 R X M H U B 』 🄾🄽 🅃🄾🄿 亗"
local INTRO_SOUND = "rbxassetid://86045706626808"
local INTRO_PROFILE = "rbxassetid://72115097738718"
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
		local RED = Color3.fromRGB(255, 25, 50)
		local DEEP = Color3.fromRGB(150, 0, 18)
		local PALE = Color3.fromRGB(255, 205, 210)
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
			BackgroundColor3 = Color3.fromRGB(4, 0, 2),
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
			BackgroundColor3 = Color3.fromRGB(12, 2, 4),
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
			Color = Color3.fromRGB(10, 0, 5),
			Thickness = 2.5,
			Transparency = 0.1,
		}, titleMain)
		local titleGrad = make("UIGradient", {
			Color = ColorSequence.new({ck(0, Color3.fromRGB(255, 20, 40)), ck(0.5, WHITE), ck(1, Color3.fromRGB(180, 0, 20))}),
		}, titleMain)
		local subtitle = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, EY, titleOff + (compact and 28 or 36)),
			Size = UDim2.new(0.94, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "R X M   H U B   ·   C R I M S O N   N O I R",
			Font = Enum.Font.GothamMedium,
			TextSize = compact and 9 or 11,
			TextColor3 = Color3.fromRGB(215, 90, 100),
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
			TextColor3 = Color3.fromRGB(205, 150, 154),
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
			BackgroundColor3 = Color3.fromRGB(28, 8, 12),
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
			Color = ColorSequence.new({ck(0, DEEP), ck(0.7, RED), ck(1, Color3.fromRGB(255, 130, 140))}),
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
			{0.64, "Applying Crimson Noir theme"},
			{0.88, "Finalizing"},
		}
		local flash = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 70, 90),
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
	local accent = Color3.fromRGB(255, 35, 60)
	local tintColor = accent
	local accentBinds = {}
	local T = {
		black = Color3.new(0, 0, 0),
		card = Color3.fromRGB(20, 13, 14),
		cardHover = Color3.fromRGB(36, 19, 21),
		stroke = Color3.fromRGB(62, 24, 28),
		track = Color3.fromRGB(46, 28, 30),
		off = Color3.fromRGB(64, 46, 48),
		text = Color3.fromRGB(246, 237, 237),
		muted = Color3.fromRGB(160, 134, 136),
		input = Color3.fromRGB(13, 9, 10),
		dark = Color3.fromRGB(24, 6, 8),
		btn = Color3.fromRGB(34, 21, 23),
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
		box.FocusLost:Connect(function(enterPressed)
			tween(boxStroke, 0.35, {Color = T.stroke})
			if enterPressed then
				fire(opts.Callback, box.Text)
			end
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
		local key = opts.Default or Enum.KeyCode.F
		local listening = false
		local c = baseCard(self, 40, opts.Name)
		local button = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(104, 28),
			BackgroundColor3 = T.input,
			Text = key.Name,
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
					if input.KeyCode ~= Enum.KeyCode.Escape then
						key = input.KeyCode
					end
					listening = false
					button.Text = key.Name
					tween(buttonStroke, 0.35, {Color = T.stroke})
				end
			elseif not processed and input.KeyCode == key then
				c.flash()
				fire(opts.Callback, key)
			end
		end)
		local object = {}
		function object:Get()
			return key
		end
		return object
	end
	local tabTech = addTab("Tech")
	local tabMisc = addTab("Misc")
	local tabSettings = addTab("Settings")
	local function buildTech(tab)
		local techs = {
			{
				name = "Custom Tech",
				kind = "custom",
				anim = "rbxassetid://10503381238",
				enabled = false,
				delay = 0.299,
				jump = 40.2,
				accuracy = -12,
				mode = "V1",
				cancelDelay = 0.4,
				cancelEnabled = true,
				noclip = false,
				range = 8.7,
			},
			{
				name = "Lethal Dash",
				kind = "lethal",
				anim = "rbxassetid://12296113986",
				enabled = false,
				delay = 1.65,
				jump = 60,
				accuracy = -12,
				cancelDelay = 0.4,
				cancelEnabled = true,
				noclip = false,
				range = 10,
			},
			{
				name = "King Tech",
				kind = "king",
				anim = "rbxassetid://10503381238",
				enabled = false,
				delay = 0.3,
				jump = 0,
				flick = 0.2,
				accuracy = 0,
				cancelDelay = 0,
				cancelEnabled = false,
				range = 6,
				cancelSwitch = false,
				accuracyBox = false,
				jumpBox = false,
				flickBox = true,
			},
			{
				name = "Supa Tech",
				anim = "rbxassetid://10503381238",
				enabled = false,
				delay = 0.299,
				jump = 36.99,
				accuracy = 0,
				cancelDelay = -1,
				cancelEnabled = true,
				range = 8.3,
				cancelSwitch = false,
				accuracyBox = false,
			},
			{
				name = "Instant Twisted",
				kind = "twisted",
				anim = "rbxassetid://13294471966",
				enabled = false,
				delay = 0.22,
				dashDuration = 0.6,
				noclip = true,
				tweenDist = 6,
				tweenSpeed = 1,
				range = 10,
				angle1 = 0,
				angle2 = 85,
				angle3 = 179,
				angle4 = 70,
				twistDelay = 0.08,
			},
		}
		local busy = false
		local activeTech = nil
		local function sendDashInput()
			local character = LocalPlayer.Character
			local communicate = character and character:FindFirstChild("Communicate")
			if communicate then
				communicate:FireServer({
					Dash = Enum.KeyCode.W,
					Key = Enum.KeyCode.Q,
					Goal = "KeyPress",
				})
			end
		end
		local function resetCharacterState()
			local character = LocalPlayer.Character
			if not character then return end
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
				humanoid.PlatformStand = false
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, tech in ipairs(techs) do
					local bav = root:FindFirstChild("RIzX" .. tech.name .. "BAV")
					if bav then
						bav:Destroy()
					end
				end
			end
		end
		local function stopMovement()
			resetCharacterState()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, child in ipairs(root:GetChildren()) do
					if child:IsA("BodyVelocity") or child:IsA("LinearVelocity") or child:IsA("Attachment") or child:IsA("BodyAngularVelocity") then
						child:Destroy()
					end
				end
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
		local function findNearestTarget(range)
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return nil end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {character}
			local best, bestDistance = nil, range
			for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, range, params)) do
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model ~= character and model:FindFirstChild("Humanoid") then
					local body = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
					if body then
						local distance = (root.Position - body.Position).Magnitude
						if distance < bestDistance then
							bestDistance = distance
							best = body
						end
					end
				end
			end
			return best
		end
		local function finish()
			busy = false
			activeTech = nil
		end
		local function activate(tech)
			if not alive or not tech.enabled or busy then return end
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChild("Humanoid")
			if not root or not humanoid then return end
			local target = findNearestTarget(tech.range)
			if not target then
				resetCharacterState()
				return
			end
			busy = true
			activeTech = tech
			task.wait(math.max(0, tech.delay))
			if not alive or not tech.enabled or not target.Parent or not root.Parent then
				finish()
				resetCharacterState()
				return
			end
			local direction = (target.Position - root.Position).Unit
			local side = Vector3.new(-direction.Z, 0, direction.X)
			humanoid.AutoRotate = false
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, tech.jump, root.AssemblyLinearVelocity.Z)
			task.wait(0)
			sendDashInput()
			local started = os.clock()
			local customSavedCollision = {}
			local function applyCustomNoclip()
				if tech.kind ~= "custom" or not tech.noclip then return end
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						customSavedCollision[part] = part.CanCollide
						part.CanCollide = false
					end
				end
			end
			local function restoreCustomNoclip()
				for part, original in pairs(customSavedCollision) do
					if part and part.Parent then pcall(function() part.CanCollide = original end) end
				end
				table.clear(customSavedCollision)
			end
			applyCustomNoclip()
			local bavName = "RIzX" .. tech.name .. "BAV"
			local bav = root:FindFirstChild(bavName) or Instance.new("BodyAngularVelocity")
			bav.Name = bavName
			bav.MaxTorque = Vector3.new(0, math.huge, 0)
			bav.P = 100000
			bav.AngularVelocity = Vector3.zero
			bav.Parent = root
			local conn
			local function stop()
				if bav then
					bav:Destroy()
				end
				restoreCustomNoclip()
				stopMovement()
				finish()
				if conn then
					conn:Disconnect()
				end
			end
			conn = RunService.Heartbeat:Connect(function()
				if not alive or not target.Parent or not root.Parent then
					stop()
					return
				end
				humanoid.AutoRotate = false
				local elapsed = os.clock() - started
				local targetPos = target.Position
				local selfPos = root.Position
				local angle = elapsed / 0.45 * (math.pi / 1.5)
				local progress = math.clamp(elapsed / 0.45, 0, 1)
				local aim = targetPos + (side * math.cos(angle) + direction * math.sin(angle)) * (tech.accuracy * (1 - progress))
				local look = CFrame.lookAt(selfPos, Vector3.new(aim.X, selfPos.Y, aim.Z))
				local _, yaw, _ = (root.CFrame:Inverse() * look):ToEulerAnglesXYZ()
				if bav and bav.Parent then
					bav.AngularVelocity = Vector3.new(0, yaw * 30, 0)
				end
				local flat = (Vector2.new(selfPos.X, selfPos.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
				if tech.cancelEnabled and tech.cancelDelay < elapsed and flat < 2.2 or 1.5 < elapsed or not tech.enabled then
					stop()
				end
			end)
		end
		local LOCK_ANIM = "10479335397"
		local techLockUntil = 0
		local techBusy = {}
		local nearHighlight = nil
		local cameraLockConn = nil
		local stickConn = nil
		local stickToken = 0
		local kingTweening = false
		local function nearestPlayer()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return nil, nil end
			local bestChar, bestRoot, bestDistance = nil, nil, math.huge
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local otherChar = player.Character
					local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
					local otherHum = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
					if otherRoot and otherHum and otherHum.Health > 0 then
						local distance = (otherRoot.Position - root.Position).Magnitude
						if distance < bestDistance then
							bestChar, bestRoot, bestDistance = otherChar, otherRoot, distance
						end
					end
				end
			end
			return bestChar, bestRoot
		end
		local function nearestLiveHead()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return nil end
			local live = workspace:FindFirstChild("Live")
			local models
			if live then
				models = live:GetChildren()
			else
				models = {}
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character then
						table.insert(models, player.Character)
					end
				end
			end
			local best, bestDistance = nil, math.huge
			for _, model in ipairs(models) do
				if model ~= character then
					local head = model:FindFirstChild("Head")
					local hum = model:FindFirstChildOfClass("Humanoid")
					if head and hum and hum.Health > 0 then
						local distance = (head.Position - root.Position).Magnitude
						if distance < bestDistance then
							best, bestDistance = head, distance
						end
					end
				end
			end
			return best
		end
		local function setHighlight(character)
			if nearHighlight then
				pcall(function()
					nearHighlight:Destroy()
				end)
				nearHighlight = nil
			end
			if character then
				local ok, highlight = pcall(function()
					local h = Instance.new("Highlight")
					h.Name = "NearestPlayerHighlight"
					h.FillColor = Color3.fromRGB(0, 255, 255)
					h.OutlineColor = Color3.fromRGB(255, 255, 255)
					h.FillTransparency = 0.5
					h.OutlineTransparency = 0
					h.Adornee = character
					h.Parent = workspace
					return h
				end)
				if ok then
					nearHighlight = highlight
				end
			end
		end
		local function jumpUp(power)
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, power, v.Z)
		end
		local function climbToTarget()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local _, targetRoot = nearestPlayer()
			if not root or not targetRoot then return end
			local rise = targetRoot.Position.Y + 1 - root.Position.Y
			if rise <= 0 then return end
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, math.sqrt(2 * workspace.Gravity * rise), v.Z)
		end
		local function flipCamera()
			local camera = workspace.CurrentCamera
			if not camera then return end
			local cf = camera.CFrame
			local look = cf.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude < 0.001 then return end
			local back = -flat.Unit
			local c = math.cos(math.asin(math.clamp(look.Y, -1, 1)))
			camera.CFrame = CFrame.lookAt(cf.Position, cf.Position + Vector3.new(back.X * c, look.Y, back.Z * c), Vector3.yAxis)
		end
		local function setCameraLock(on)
			if cameraLockConn then
				cameraLockConn:Disconnect()
				cameraLockConn = nil
			end
			if on then
				cameraLockConn = RunService.RenderStepped:Connect(function()
					local camera = workspace.CurrentCamera
					local _, targetRoot = nearestPlayer()
					if not camera or not targetRoot then return end
					camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetRoot.Position)
				end)
			end
		end
		local function stickBehindTarget(seconds)
			stickToken = stickToken + 1
			local myToken = stickToken
			if stickConn then
				stickConn:Disconnect()
				stickConn = nil
			end
			stickConn = RunService.RenderStepped:Connect(function()
				if stickToken ~= myToken then return end
				local character = LocalPlayer.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local _, targetRoot = nearestPlayer()
				local camera = workspace.CurrentCamera
				if not root or not targetRoot or not camera then return end
				local look = camera.CFrame.LookVector
				local facing = CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
				root.CFrame = CFrame.new(targetRoot.Position + facing.LookVector * -1) * facing * CFrame.Angles(math.rad(20), 0, 0)
			end)
			task.delay(math.max(0, seconds), function()
				if stickToken == myToken and stickConn then
					stickConn:Disconnect()
					stickConn = nil
				end
			end)
		end
		local function autoPosition()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local _, targetRoot = nearestPlayer()
			if not root or not targetRoot then return end
			local p = targetRoot.Position + -root.CFrame.LookVector * 5
			root.CFrame = CFrame.new(p.X, root.Position.Y, p.Z)
		end
		local function kingTween()
			if kingTweening then return end
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local head = nearestLiveHead()
			if not root or not head then return end
			kingTweening = true
			pcall(function()
				local tween = TweenService:Create(root, TweenInfo.new(0.2, ES.Quad, ED.Out), {
					CFrame = CFrame.new(head.Position + Vector3.new(0, 3, 0)),
				})
				tween:Play()
				tween.Completed:Wait()
				local total = 0
				while total < 0.1 do
					total = total + RunService.Heartbeat:Wait()
					if not alive or not root.Parent or not head.Parent then break end
					root.AssemblyLinearVelocity = Vector3.zero
					root.CFrame = CFrame.new(head.Position + Vector3.new(0, 3, 0))
				end
			end)
			kingTweening = false
		end
		local function runGuarded(tech, steps)
			if not alive or not tech.enabled or techBusy[tech.kind] or os.clock() < techLockUntil then return end
			techBusy[tech.kind] = true
			pcall(steps)
			pcall(setCameraLock, false)
			pcall(setHighlight, nil)
			techBusy[tech.kind] = false
		end
		local Stats = svc("Stats")
		local Debris = svc("Debris")
		local noclipOwners = {Lethal = false, Twisted = false}
		local savedCollision = {}
		local function restoreCollision()
			for part, original in pairs(savedCollision) do
				if part and part.Parent then
					pcall(function()
						part.CanCollide = original
					end)
				end
				savedCollision[part] = nil
			end
		end
		connect(RunService.Stepped, function()
			if not alive then return end
			local character = LocalPlayer.Character
			if (noclipOwners.Lethal or noclipOwners.Twisted) and character then
				for _, item in ipairs(character:GetDescendants()) do
					if item:IsA("BasePart") then
						if savedCollision[item] == nil then
							savedCollision[item] = item.CanCollide
						end
						item.CanCollide = false
					end
				end
			else
				restoreCollision()
			end
		end)
		local lethalToken = 0
		local lethalCleanup = nil
		local function stopLethal()
			lethalToken = lethalToken + 1
			noclipOwners.Lethal = false
			if lethalCleanup then
				local fn = lethalCleanup
				lethalCleanup = nil
				pcall(fn, false)
			end
		end
		local function findLethalTarget(character, root, maxRange)
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {character}
			local ok, parts = pcall(function()
				return workspace:GetPartBoundsInRadius(root.Position, maxRange, params)
			end)
			if not ok then return nil end
			local target, bestDistance = nil, maxRange
			for _, part in ipairs(parts) do
				local model = part:FindFirstAncestorOfClass("Model")
				local hum = model and model:FindFirstChildOfClass("Humanoid")
				if model and model ~= character and hum and hum.Health > 0 then
					local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
					if torso then
						local distance = (root.Position - torso.Position).Magnitude
						if distance < bestDistance then
							target, bestDistance = torso, distance
						end
					end
				end
			end
			return target
		end
		local function activateLethal(tech)
			if not alive or not tech.enabled or os.clock() < techLockUntil then return end
			stopLethal()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then return end
			local target = findLethalTarget(character, root, tech.range)
			if not target then return end
			local sessionToken = lethalToken
			task.wait(math.max(0, tech.delay))
			if not alive or sessionToken ~= lethalToken or not tech.enabled or character ~= LocalPlayer.Character then return end
			if not target.Parent or not root.Parent then return end
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, tech.jump, root.AssemblyLinearVelocity.Z)
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Name = "RIzXLethalBV"
			bodyVelocity.Velocity = Vector3.new(0, tech.jump, 0)
			bodyVelocity.MaxForce = Vector3.new(0, 1e8, 0)
			bodyVelocity.P = 1500
			bodyVelocity.Parent = root
			Debris:AddItem(bodyVelocity, 0.1)
			noclipOwners.Lethal = tech.noclip == true
			sendDashInput()
			local startTime = os.clock()
			local flipped = false
			local offset = target.Position - root.Position
			if offset.Magnitude < 0.01 then
				offset = root.CFrame.LookVector
			end
			local forward = offset.Unit
			local side = Vector3.new(-forward.Z, 0, forward.X)
			local angular = nil
			angular = Instance.new("BodyAngularVelocity")
			angular.Name = "RIzXLethalBAV"
			angular.MaxTorque = Vector3.new(0, 1000000, 0)
			angular.P = 15000
			angular.Parent = root
			local connection
			local function finishSession(forceStop)
				if connection then
					connection:Disconnect()
					connection = nil
				end
				if angular and angular.Parent then angular:Destroy() end
				angular = nil
				if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
				noclipOwners.Lethal = false
				if humanoid and humanoid.Parent then humanoid.AutoRotate = true end
				if forceStop then
					pcall(function()
						root.AssemblyLinearVelocity = Vector3.zero
					end)
				end
			end
			lethalCleanup = finishSession
			connection = RunService.Heartbeat:Connect(function()
				if not alive or sessionToken ~= lethalToken or not tech.enabled or not root.Parent or not target.Parent then
					if lethalCleanup == finishSession then lethalCleanup = nil end
					finishSession(false)
					return
				end
				local elapsed = os.clock() - startTime
				humanoid.AutoRotate = false
				local mode = tech.kind == "custom" and tech.mode or "V1"
				if mode == "V1" then
					local angle = (elapsed / 0.45) * (math.pi / 1.5)
					local radius = tech.accuracy * (1 - math.clamp(elapsed / 0.45, 0, 1))
					local targetLook = target.Position + (side * math.cos(angle) + forward * math.sin(angle)) * radius
					local lookCF = CFrame.lookAt(root.Position, Vector3.new(targetLook.X, root.Position.Y, targetLook.Z))
					local relative = root.CFrame:Inverse() * lookCF
					local _, y, _ = relative:ToEulerAnglesXYZ()
					if angular and angular.Parent then
						angular.AngularVelocity = Vector3.new(0, y * 30, 0)
					end
				elseif elapsed >= tech.accuracy and not flipped then
					root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
					flipped = true
				end
				local distanceXZ = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(target.Position.X, target.Position.Z)).Magnitude
				if tech.cancelEnabled and elapsed > tech.cancelDelay and distanceXZ < 2.2 then
					if lethalCleanup == finishSession then lethalCleanup = nil end
					finishSession(true)
					return
				end
				if elapsed > 1.5 then
					if lethalCleanup == finishSession then lethalCleanup = nil end
					finishSession(false)
				end
			end)
		end
		local twistedToken = 0
		local twistedTween = nil
		local twistedHumanoid = nil
		local function cancelTwistedTween()
			if twistedTween then
				pcall(function()
					twistedTween:Cancel()
				end)
				twistedTween = nil
			end
		end
		local function stopTwisted()
			twistedToken = twistedToken + 1
			cancelTwistedTween()
			noclipOwners.Twisted = false
			if twistedHumanoid and twistedHumanoid.Parent then
				twistedHumanoid.AutoRotate = true
			end
			twistedHumanoid = nil
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, object in ipairs(root:GetChildren()) do
					if object.Name == "RIzXTwistAttachment" or object.Name == "RIzXTwistAlign" then
						pcall(function()
							object:Destroy()
						end)
					end
				end
			end
		end
		local function getClosestPredictedPosition(maxRange)
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then return nil end
			local bestPosition, bestDistance = nil, maxRange
			local pingSeconds = 0
			pcall(function()
				pingSeconds = math.clamp(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000, 0, 0.2)
			end)
			for _, targetPlayer in ipairs(Players:GetPlayers()) do
				if targetPlayer ~= LocalPlayer and targetPlayer.Character then
					local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
					local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
					if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
						local distance = (root.Position - targetRoot.Position).Magnitude
						if distance < bestDistance then
							bestDistance = distance
							local velocity = targetRoot.AssemblyLinearVelocity
							bestPosition = targetRoot.Position + Vector3.new(velocity.X, 0, velocity.Z) * pingSeconds
						end
					end
				end
			end
			return bestPosition
		end
		local function applyTwist(tech, root, humanoid, token)
			if not alive or not root or not root.Parent or not humanoid or not humanoid.Parent then return end
			local attachment = Instance.new("Attachment")
			attachment.Name = "RIzXTwistAttachment"
			attachment.Parent = root
			local align = Instance.new("AlignOrientation")
			align.Name = "RIzXTwistAlign"
			align.Mode = Enum.OrientationAlignmentMode.OneAttachment
			align.Attachment0 = attachment
			align.RigidityEnabled = false
			align.MaxTorque = 1000000
			align.Responsiveness = 60
			align.Parent = root
			local forceOff = RunService.Heartbeat:Connect(function()
				if humanoid and humanoid.Parent then humanoid.AutoRotate = false end
			end)
			local function setAngle(angle)
				if align and align.Parent and root and root.Parent then
					align.CFrame = root.CFrame * CFrame.Angles(0, math.rad(angle), 0)
				end
			end
			local function stillValid()
				return alive and token == twistedToken
			end
			local ok, err = pcall(function()
				setAngle(-tech.angle1)
				task.wait(tech.twistDelay)
				if not stillValid() then return end
				setAngle(tech.angle2)
				task.wait(tech.twistDelay)
				if not stillValid() then return end
				setAngle(-tech.angle3)
				task.wait(tech.twistDelay)
				if not stillValid() then return end
				setAngle(tech.angle4)
				task.wait(math.max(tech.dashDuration - tech.twistDelay * 3, 0))
			end)
			forceOff:Disconnect()
			if align and align.Parent then align:Destroy() end
			if attachment and attachment.Parent then attachment:Destroy() end
			if humanoid and humanoid.Parent then humanoid.AutoRotate = true end
			if not ok then
				warn("[RXM] Twist cleanup: " .. tostring(err))
			end
		end
		local function activateTwisted(tech)
			if not alive or not tech.enabled or os.clock() < techLockUntil then return end
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then return end
			stopTwisted()
			local token = twistedToken
			twistedHumanoid = humanoid
			local targetPosition = getClosestPredictedPosition(tech.range)
			if targetPosition then
				humanoid.AutoRotate = false
				root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z))
			end
			if tech.tweenDist > 0 then
				twistedTween = TweenService:Create(root, TweenInfo.new(math.max(tech.tweenSpeed, 0.05), ES.Cubic, ED.Out), {
					CFrame = root.CFrame * CFrame.new(0, 0, tech.tweenDist),
				})
				twistedTween:Play()
			end
			noclipOwners.Twisted = tech.noclip == true
			task.wait(tech.delay)
			if not alive or token ~= twistedToken or not tech.enabled or character ~= LocalPlayer.Character then
				if token == twistedToken then
					stopTwisted()
				end
				return
			end
			cancelTwistedTween()
			sendDashInput()
			applyTwist(tech, root, humanoid, token)
			if token ~= twistedToken then return end
			task.wait(tech.dashDuration)
			if token == twistedToken then
				noclipOwners.Twisted = false
				twistedHumanoid = nil
			end
		end
		local stoppers = {custom = stopLethal, lethal = stopLethal, twisted = stopTwisted}
		table.insert(connections, {
			Disconnect = function()
				pcall(stopLethal)
				pcall(stopTwisted)
				noclipOwners.Lethal = false
				noclipOwners.Twisted = false
				restoreCollision()
			end,
		})
		local function activateKing(tech)
			runGuarded(tech, function()
				task.spawn(kingTween)
				task.wait(math.max(0, tech.delay))
				if not alive or not tech.enabled then return end
				sendDashInput()
				setHighlight((nearestPlayer()))
				task.wait(math.max(0, tech.flick))
				if not alive then return end
				climbToTarget()
				flipCamera()
				task.wait(0.2)
			end)
		end
		local handlers = {custom = activateLethal, lethal = activateLethal, twisted = activateTwisted, king = activateKing}
		local function hookCharacter(character)
			if not alive then return end
			local humanoid = character:WaitForChild("Humanoid", 5)
			if not humanoid or not alive then return end
			stopLethal()
			stopTwisted()
			restoreCollision()
			connect(humanoid.AnimationPlayed, function(track)
				if not alive then return end
				local animation = track.Animation
				local id = animation and animation.AnimationId
				if type(id) == "string" and string.find(id, LOCK_ANIM, 1, true) then
					techLockUntil = os.clock() + 5
				end
				for _, tech in ipairs(techs) do
					if tech.enabled and id == tech.anim then
						task.spawn(handlers[tech.kind] or activate, tech)
						break
					end
				end
			end)
		end
		if LocalPlayer.Character then
			task.spawn(hookCharacter, LocalPlayer.Character)
		end
		connect(LocalPlayer.CharacterAdded, hookCharacter)
		local RANGES = {
			King = {delay = {0, 1.5, 0.01}, flick = {0, 1, 0.01}},
			Supa = {delay = {0, 1.5, 0.001}, jump = {0, 120, 0.001}},
		}
		local function addSlider(tech, field, label, fallback)
			local range = (RANGES[tech.name] and RANGES[tech.name][field]) or fallback
			return tab:Slider({
				Name = label,
				Min = range[1],
				Max = range[2],
				Step = range[3],
				Default = tech[field],
				Callback = function(value)
					tech[field] = value
				end,
			})
		end
		for _, tech in ipairs(techs) do
			tab:Section(tech.name)
			tab:Toggle({Name = tech.name, Default = tech.enabled, Callback = function(value)
				tech.enabled = value
				if not value and activeTech == tech then
					stopMovement()
				end
				if not value and stoppers[tech.kind] then
					stoppers[tech.kind]()
				end
			end})
			tab:Foldout({
				Name = tech.name .. " config",
				Build = function()
					if tech.kind == "custom" then
						tab:Dropdown({Name = "Custom Tech Mode", Options = {"V1", "V2"}, Default = tech.mode, Callback = function(value)
							tech.mode = value
							if value == "V2" and tech.accuracy == 15 then tech.accuracy = 0.25 end
							if value == "V1" and tech.accuracy == 0.25 then tech.accuracy = 15 end
						end})
						addSlider(tech, "delay", "Activation delay (s)", {0, 5, 0.01})
						addSlider(tech, "jump", "Jump power", {0, 200, 1})
						addSlider(tech, "accuracy", "Accuracy", {0, 30, 0.05})
						addSlider(tech, "cancelDelay", "Cancel delay (s)", {0, 3, 0.01})
						addSlider(tech, "range", "Target range", {1, 50, 1})
						tab:Toggle({Name = "Auto cancel", Default = tech.cancelEnabled, Callback = function(value)
							tech.cancelEnabled = value
						end})
						tab:Toggle({Name = "Noclip (karakter sendiri)", Default = tech.noclip, Callback = function(value)
							tech.noclip = value
						end})
						return
					end
					if tech.kind == "lethal" then
						addSlider(tech, "delay", "Activation delay (s)", {0, 5, 0.01})
						addSlider(tech, "jump", "Vertical velocity", {0, 200, 1})
						tech.accuracySlider = addSlider(tech, "accuracy", "Accuracy / flip timing", {0.05, 30, 0.05})
						addSlider(tech, "cancelDelay", "Cancel delay (s)", {0, 3, 0.01})
						addSlider(tech, "range", "Target range", {1, 50, 1})
						tab:Toggle({Name = "Auto cancel", Default = tech.cancelEnabled, Callback = function(value)
							tech.cancelEnabled = value
						end})
						tab:Toggle({Name = "Noclip (karakter sendiri)", Default = tech.noclip, Callback = function(value)
							tech.noclip = value
						end})
						return
					end
					if tech.kind == "twisted" then
						addSlider(tech, "dashDuration", "Dash duration (s)", {0.1, 5, 0.05})
						addSlider(tech, "delay", "Dash delay (s)", {0, 5, 0.01})
						addSlider(tech, "tweenDist", "Tween-back distance", {0, 20, 0.1})
						addSlider(tech, "tweenSpeed", "Tween speed", {0.05, 5, 0.05})
						addSlider(tech, "angle1", "Twist angle 1", {0, 360, 1})
						addSlider(tech, "angle2", "Twist angle 2", {0, 360, 1})
						addSlider(tech, "angle3", "Twist angle 3", {0, 360, 1})
						addSlider(tech, "angle4", "Twist angle 4", {0, 360, 1})
						addSlider(tech, "twistDelay", "Twist interval (s)", {0.01, 0.5, 0.01})
						addSlider(tech, "range", "Aim range", {1, 100, 1})
						tab:Toggle({Name = "Noclip (karakter sendiri)", Default = tech.noclip, Callback = function(value)
							tech.noclip = value
						end})
						return
					end
					addSlider(tech, "delay", "Delay (s)", {0, 3, 0.01})
					if tech.jumpBox ~= false then
						addSlider(tech, "jump", "Jump power", {0, 100, 0.5})
					end
					if tech.flickBox then
						addSlider(tech, "flick", "Flick delay (s)", {0, 1, 0.01})
					end
					if tech.endBox then
						addSlider(tech, "endDelay", "End delay (s)", {0, 1, 0.01})
					end
					if tech.accuracyBox then
						addSlider(tech, "accuracy", "Accuracy", {-40, 40, 0.01})
					end
					if tech.autoPosToggle then
						tab:Toggle({Name = "Auto position", Default = tech.autoPos, Callback = function(value)
							tech.autoPos = value
						end})
					end
					if tech.cancelSwitch then
						tab:Toggle({Name = "Auto cancel", Default = tech.cancelEnabled, Callback = function(value)
							tech.cancelEnabled = value
						end})
					end
				end,
			})
		end
	end
	buildTech(tabTech)
	tabMisc:Section("Anti Lag")
	local WorkspaceService = svc("Workspace")
	local LightingService = svc("Lighting")
	local particleSaved = setmetatable({}, {__mode = "k"})
	local shadowSaved = setmetatable({}, {__mode = "k"})
	local particleConnection
	local function isParticleEffect(obj)
		return obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")
	end
	local function setParticlesLow(obj, enabled)
		if not isParticleEffect(obj) then return end
		if enabled then
			if particleSaved[obj] == nil then particleSaved[obj] = obj.Enabled end
			obj.Enabled = false
		elseif particleSaved[obj] ~= nil then
			pcall(function() obj.Enabled = particleSaved[obj] end)
			particleSaved[obj] = nil
		end
	end
	tabMisc:Toggle({Name = "Disable particles / effects", Default = false, Callback = function(enabled)
		if enabled then
			for _, obj in ipairs(WorkspaceService:GetDescendants()) do pcall(setParticlesLow, obj, true) end
			if particleConnection then particleConnection:Disconnect() end
			particleConnection = WorkspaceService.DescendantAdded:Connect(function(obj)
				if enabled then task.defer(function() pcall(setParticlesLow, obj, true) end) end
			end)
		else
			if particleConnection then particleConnection:Disconnect(); particleConnection = nil end
			for obj, value in pairs(particleSaved) do
				pcall(function() if obj.Parent then obj.Enabled = value end end)
				particleSaved[obj] = nil
			end
		end
	end})
	tabMisc:Toggle({Name = "Disable shadows", Default = false, Callback = function(enabled)
		if enabled then
			if shadowSaved.global == nil then shadowSaved.global = LightingService.GlobalShadows end
			LightingService.GlobalShadows = false
			for _, obj in ipairs(WorkspaceService:GetDescendants()) do
				if obj:IsA("BasePart") then
					if shadowSaved[obj] == nil then shadowSaved[obj] = obj.CastShadow end
					obj.CastShadow = false
				end
			end
		else
			if shadowSaved.global ~= nil then LightingService.GlobalShadows = shadowSaved.global; shadowSaved.global = nil end
			for obj, value in pairs(shadowSaved) do
				if typeof(obj) == "Instance" then pcall(function() if obj.Parent then obj.CastShadow = value end end); shadowSaved[obj] = nil end
			end
		end
	end})
	tabMisc:Toggle({Name = "Hide textures / decals", Default = false, Callback = function(enabled)
		for _, obj in ipairs(WorkspaceService:GetDescendants()) do
			if obj:IsA("Decal") or obj:IsA("Texture") then
				if enabled then
					if particleSaved[obj] == nil then particleSaved[obj] = obj.Transparency end
					obj.Transparency = 1
				elseif particleSaved[obj] ~= nil then
					pcall(function() obj.Transparency = particleSaved[obj] end)
					particleSaved[obj] = nil
				end
			end
		end
	end})
	tabMisc:Button({Name = "Low graphics (3D rendering)", Callback = function()
		pcall(function() RunService:Set3dRenderingEnabled(false) end)
		tabMisc:Label("3D rendering dimatikan. Jalankan ulang game untuk memulihkannya.")
	end})
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

do
local runService = game:GetService("RunService")
local workspaceService = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
if type(_G.RXMCustomTechCleanup) == "function" then
    pcall(_G.RXMCustomTechCleanup)
end
pcall(function()
    local coreGui = game:GetService("CoreGui")
    local oldTechGui = coreGui:FindFirstChild("SkidwareUI")
    if oldTechGui then oldTechGui:Destroy() end
end)
local oldGui = playerGui:FindFirstChild("CleanerGUI")
if oldGui then
    oldGui:Destroy()
end
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end
local function makeButton(parent, text, color, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9, 0, 0, 40)
    button.Position = position
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Text = text
    button.Parent = parent
    addCorner(button, 8)
    return button
end
local cleanerGUI = Instance.new("ScreenGui")
cleanerGUI.Name = "CleanerGUI"
cleanerGUI.ResetOnSpawn = false
cleanerGUI.Parent = playerGui
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 330, 0, 420)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
frame.Parent = cleanerGUI
addCorner(frame, 12)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -25, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleLabel.Text = "RXM HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = frame
addCorner(titleLabel, 8)
local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(1, 0, 0, 20)
creditLabel.Position = UDim2.new(0, 0, 0, 25)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "by Marian KING"
creditLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
creditLabel.TextScaled = true
creditLabel.Font = Enum.Font.SourceSansBold
creditLabel.Parent = frame
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -25, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Parent = frame
addCorner(closeButton, 8)
closeButton.MouseButton1Click:Connect(function()
    if type(_G.RXMCustomTechCleanup) == "function" then
        pcall(_G.RXMCustomTechCleanup)
    end
    cleanerGUI:Destroy()
end)
local TAB_ACTIVE = Color3.fromRGB(150, 0, 0)
local TAB_INACTIVE = Color3.fromRGB(60, 60, 60)
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(0.9, 0, 0, 26)
tabBar.Position = UDim2.new(0.05, 0, 0, 50)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame
local function makeTab(text, position)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0.31, 0, 1, 0)
    tab.Position = position
    tab.BackgroundColor3 = TAB_INACTIVE
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.TextScaled = true
    tab.Font = Enum.Font.SourceSansBold
    tab.Text = text
    tab.Parent = tabBar
    addCorner(tab, 8)
    return tab
end
local function makePage()
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, -82)
    page.Position = UDim2.new(0, 0, 0, 82)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = frame
    return page
end
local tabs = {
    Cleaner = makeTab("Cleaner", UDim2.new(0, 0, 0, 0)),
    Misc = makeTab("Misc", UDim2.new(0.345, 0, 0, 0)),
    ["Custom Tech"] = makeTab("Custom Tech", UDim2.new(0.69, 0, 0, 0)),
}
local pages = {
    Cleaner = makePage(),
    Misc = makePage(),
    ["Custom Tech"] = makePage(),
}
local function selectTab(name)
    for tabName, page in pairs(pages) do
        local selected = (tabName == name)
        page.Visible = selected
        tabs[tabName].BackgroundColor3 = selected and TAB_ACTIVE or TAB_INACTIVE
    end
end
for tabName, tab in pairs(tabs) do
    tab.MouseButton1Click:Connect(function()
        selectTab(tabName)
    end)
end
local cleanerPage = pages.Cleaner
local maxPerformanceOn = false
local thrownConnection = nil
local maxPerformanceButton = makeButton(
    cleanerPage,
    "MAX PERFORMANCE: OFF",
    Color3.fromRGB(150, 0, 0),
    UDim2.new(0.05, 0, 0, 0)
)
local function destroyByName(parent, pattern)
    for _, child in ipairs(parent:GetChildren()) do
        if string.find(string.lower(child.Name), string.lower(pattern)) then
            child:Destroy()
        else
            destroyByName(child, pattern)
        end
    end
end
local function watchChildAdded(parent, pattern)
    parent.ChildAdded:Connect(function(child)
        if maxPerformanceOn and string.find(string.lower(child.Name), string.lower(pattern)) then
            child:Destroy()
        end
    end)
end
watchChildAdded(workspaceService, "Effect")
watchChildAdded(replicatedStorage, "Effect")
watchChildAdded(workspaceService, "MeshPart")
watchChildAdded(replicatedStorage, "MeshPart")
local THROWN_KEEP = {
    Dragon = true,
    Aurora = true,
    starterdeb = true,
}
local function startThrownCleaner()
    if thrownConnection then
        return
    end
    thrownConnection = runService.Stepped:Connect(function()
        local thrown = workspaceService:FindFirstChild("Thrown")
        if thrown then
            for _, obj in ipairs(thrown:GetChildren()) do
                if obj and obj.Parent and not THROWN_KEEP[obj.Name] then
                    obj:Destroy()
                end
            end
        end
    end)
end
local function stopThrownCleaner()
    if thrownConnection then
        thrownConnection:Disconnect()
        thrownConnection = nil
    end
end
maxPerformanceButton.MouseButton1Click:Connect(function()
    maxPerformanceOn = not maxPerformanceOn
    if maxPerformanceOn then
        maxPerformanceButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        maxPerformanceButton.Text = "MAX PERFORMANCE: ON"
        destroyByName(workspaceService, "Effect")
        destroyByName(replicatedStorage, "Effect")
        destroyByName(workspaceService, "MeshPart")
        destroyByName(replicatedStorage, "MeshPart")
        startThrownCleaner()
        lighting.GlobalShadows = false
        if setfpscap then
            setfpscap(144)
        end
    else
        maxPerformanceButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        maxPerformanceButton.Text = "MAX PERFORMANCE: OFF"
        stopThrownCleaner()
        lighting.GlobalShadows = true
    end
end)
local ultraOn = false
local ultraConnection = nil
local ultraButton = makeButton(
    cleanerPage,
    "ULTRA MAX PREFERENCE: OFF",
    Color3.fromRGB(200, 50, 50),
    UDim2.new(0.05, 0, 0, 48)
)
local PARTICLE_KEEP_LIST = {
    "Shockwave2", "Shockwave", "PunchingWind", "landRays", "ohye", "DragWind",
    "Maybe", "ItsWindTime", "STuff", "Land", "Wind2", "Combine", "pls", "omggg",
    "MainWave", "TParticles2", "Lightning", "BROO3", "BROO2", "BROO5", "Impact",
    "TBottom", "Skull", "BROO",
}
local particleKeep = {}
for _, name in ipairs(PARTICLE_KEEP_LIST) do
    particleKeep[name] = true
end
local HUNTER_ULT_ATTACHMENTS = { "6", "4-4", "4-3", "4-2", "4" }
local LEGACY_EFFECTS = {
    "UpSmoke2", "UpSmoke", "TreeFire", "Trans", "SmokeOne", "Smoke", "Leaves",
    "ImpactGlow", "Effect", "BackSmoke", "Push",
}
local RESOURCE_EFFECTS = {
    "HeadFirst", "FlyingKicks", "WhirlwindDrop", "VanishingKick", "FlashFinisher",
    "PurpleAura", "PurpleM1", "le phone", "eject (2)", "Windy", "WindPurp", "Splash",
    "Slam", "Rocks", "Rock", "PhonePhysicsTest", "NewSlash", "Mah", "Katana",
    "FirstHit", "FinalEffects", "FSExpl", "EmergeSword", "CyborgArms", "Clone_Rig",
    "CloneRigEm", "CloneRig", "BatBarrageEffects", "AuraHolder", "AtomicFX",
    "Afterimage", "AcidExplosion", "QuickSlash", "MonsterSmash", "MonsterMoveTest",
    "MonsterAwaken", "FiveSeasonsFX", "FinisherEmerge", "FirstUltimateMoveMech",
    "FirstMonsterVFX", "DogVariant", "DeadlySliceVfx", "Consecutive Punches Finisher",
    "Slap", "SecM1", "Fast", "Fang", "EsperAwakening", "EffectsMech", "DragonUppercut",
    "DownSlam", "DoomFinish", "CrushingPushFinisher", "DashMechVfx", "Bossfight",
    "allvfx", "AtomicSlash", "CrushingPull", "GreenLights", "GreenTornado",
    "HeadFirstFinisher", "Collat", "Chain", "Cannon", "StoicBomb", "Meteor", "MechVfx",
    "CrabSlash", "CrabBeam", "Brother", "Blackholevfx", "BarrageFinisher",
}
local function destroyNamed(parent, names)
    for _, name in ipairs(names) do
        local obj = parent:FindFirstChild(name)
        if obj then
            obj:Destroy()
        end
    end
end
local function cleanResources()
    local resources = replicatedStorage:FindFirstChild("Resources")
    if not resources then
        return
    end
    local legacy = resources:FindFirstChild("LegacyReplication")
    if legacy then
        local hunterUlt = legacy:FindFirstChild("HunterUlt")
        local attachment1 = hunterUlt and hunterUlt:FindFirstChild("Attachment1")
        if attachment1 then
            destroyNamed(attachment1, HUNTER_ULT_ATTACHMENTS)
        end
        destroyNamed(legacy, LEGACY_EFFECTS)
    end
    destroyNamed(resources, RESOURCE_EFFECTS)
end
local function getSmokeFolder()
    local resources = replicatedStorage:FindFirstChild("Resources")
    return resources and resources:FindFirstChild("Smoke")
end
local function shouldRemoveEmitter(inst, smoke)
    return inst:IsA("ParticleEmitter")
        and not particleKeep[inst.Name]
        and not (smoke and inst:IsDescendantOf(smoke))
end
local function removeEmitters(root, smoke)
    for _, inst in ipairs(root:GetDescendants()) do
        if shouldRemoveEmitter(inst, smoke) then
            inst:Destroy()
        end
    end
end
local function showNotice(text)
    task.spawn(function()
        local notice = Instance.new("TextLabel")
        notice.Size = UDim2.new(0, 200, 0, 50)
        notice.Position = UDim2.new(0.5, -100, 0.5, -25)
        notice.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        notice.TextColor3 = Color3.fromRGB(255, 255, 255)
        notice.TextScaled = true
        notice.Text = text
        notice.Font = Enum.Font.SourceSansBold
        notice.Parent = cleanerGUI
        addCorner(notice, 12)
        task.wait(2)
        notice:Destroy()
    end)
end
ultraButton.MouseButton1Click:Connect(function()
    ultraOn = not ultraOn
    if ultraOn then
        ultraButton.Text = "ULTRA MAX PREFERENCE: ON"
        ultraButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        local smoke = getSmokeFolder()
        cleanResources()
        removeEmitters(workspaceService, smoke)
        showNotice("✅ Successfully completed!")
        ultraConnection = game.DescendantAdded:Connect(function(descendant)
            if shouldRemoveEmitter(descendant, smoke) then
                descendant:Destroy()
            end
        end)
    else
        ultraButton.Text = "ULTRA MAX PREFERENCE: OFF"
        ultraButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        if ultraConnection then
            ultraConnection:Disconnect()
            ultraConnection = nil
        end
    end
end)
local superMaxButton = makeButton(
    cleanerPage,
    "SUPER MAX",
    Color3.fromRGB(100, 0, 200),
    UDim2.new(0.05, 0, 0, 96)
)
local superMaxActive = false
local SUPER_CLASSES = { "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Explosion" }
local function disableEffect(inst)
    if table.find(SUPER_CLASSES, inst.ClassName) then
        pcall(function()
            if inst:IsA("Explosion") then
                inst:Destroy()
            else
                inst.Enabled = false
            end
        end)
    end
end
local function disableEffectsIn(root)
    for _, inst in ipairs(root:GetDescendants()) do
        disableEffect(inst)
    end
end
superMaxButton.MouseButton1Click:Connect(function()
    if superMaxActive then
        return
    end
    superMaxActive = true
    superMaxButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    superMaxButton.Text = "SUPER MAX ACTIVATED"
    disableEffectsIn(workspaceService)
    if localPlayer.Character then
        disableEffectsIn(localPlayer.Character)
    end
    local backpack = localPlayer:FindFirstChild("Backpack")
    if backpack then
        disableEffectsIn(backpack)
    end
    workspaceService.DescendantAdded:Connect(disableEffect)
    localPlayer.CharacterAdded:Connect(function(character)
        disableEffectsIn(character)
        character.DescendantAdded:Connect(disableEffect)
    end)
    print("✅ OMG: Effect disabling logic has been activated!")
end)
local miscPage = pages.Misc
local switchRow = Instance.new("Frame")
switchRow.Size = UDim2.new(0.9, 0, 0, 44)
switchRow.Position = UDim2.new(0.05, 0, 0, 0)
switchRow.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
switchRow.Parent = miscPage
addCorner(switchRow, 8)
local switchLabel = Instance.new("TextLabel")
switchLabel.Size = UDim2.new(0.6, 0, 1, -16)
switchLabel.Position = UDim2.new(0, 10, 0, 8)
switchLabel.BackgroundTransparency = 1
switchLabel.Text = "Anti Lag: OFF"
switchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
switchLabel.TextScaled = true
switchLabel.TextXAlignment = Enum.TextXAlignment.Left
switchLabel.Font = Enum.Font.SourceSansBold
switchLabel.Parent = switchRow
local SWITCH_OFF_COLOR = Color3.fromRGB(150, 0, 0)
local SWITCH_ON_COLOR = Color3.fromRGB(0, 150, 0)
local KNOB_OFF_POS = UDim2.new(0, 3, 0.5, -9)
local KNOB_ON_POS = UDim2.new(1, -21, 0.5, -9)
local switchTrack = Instance.new("TextButton")
switchTrack.Size = UDim2.new(0, 50, 0, 24)
switchTrack.Position = UDim2.new(1, -60, 0.5, -12)
switchTrack.BackgroundColor3 = SWITCH_OFF_COLOR
switchTrack.Text = ""
switchTrack.AutoButtonColor = false
switchTrack.Parent = switchRow
addCorner(switchTrack, 12)
local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 18, 0, 18)
switchKnob.Position = KNOB_OFF_POS
switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
switchKnob.Parent = switchTrack
addCorner(switchKnob, 9)
local switchHint = Instance.new("TextLabel")
switchHint.Size = UDim2.new(0.9, 0, 0, 56)
switchHint.Position = UDim2.new(0.05, 0, 0, 52)
switchHint.BackgroundTransparency = 1
switchHint.Text = "Lowers graphics quality, shadows, textures and effects to reduce lag. Turn it off to restore everything."
switchHint.TextColor3 = Color3.fromRGB(180, 180, 180)
switchHint.TextSize = 13
switchHint.TextWrapped = true
switchHint.TextXAlignment = Enum.TextXAlignment.Left
switchHint.TextYAlignment = Enum.TextYAlignment.Top
switchHint.Parent = miscPage
local function setSwitchVisual(on)
    switchLabel.Text = on and "Anti Lag: ON" or "Anti Lag: OFF"
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tweenService:Create(switchKnob, info, { Position = on and KNOB_ON_POS or KNOB_OFF_POS }):Play()
    tweenService:Create(switchTrack, info, { BackgroundColor3 = on and SWITCH_ON_COLOR or SWITCH_OFF_COLOR }):Play()
end
local antiLagOn = false
local antiLagToken = 0
local antiLagConnections = {}
local savedProps = setmetatable({}, { __mode = "k" })
local savedGlobalShadows = nil
local savedQuality = nil
local savedTerrain = nil
local function isCharacterDescendant(inst)
    local model = inst:FindFirstAncestorOfClass("Model")
    return model ~= nil and players:GetPlayerFromCharacter(model) ~= nil
end
local function applyAntiLag(inst)
    if savedProps[inst] then
        return
    end
    pcall(function()
        if inst:IsA("BasePart") then
            if inst:IsA("Terrain") or isCharacterDescendant(inst) then
                return
            end
            savedProps[inst] = {
                Material = inst.Material,
                Reflectance = inst.Reflectance,
                CastShadow = inst.CastShadow,
            }
            inst.Material = Enum.Material.SmoothPlastic
            inst.Reflectance = 0
            inst.CastShadow = false
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            if isCharacterDescendant(inst) then
                return
            end
            savedProps[inst] = { Transparency = inst.Transparency }
            inst.Transparency = 1
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
            or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles")
            or inst:IsA("PostEffect") then
            savedProps[inst] = { Enabled = inst.Enabled }
            inst.Enabled = false
        end
    end)
end
local function enableAntiLag()
    antiLagToken = antiLagToken + 1
    local token = antiLagToken
    if savedGlobalShadows == nil then
        savedGlobalShadows = lighting.GlobalShadows
    end
    lighting.GlobalShadows = false
    pcall(function()
        if savedQuality == nil then
            savedQuality = settings().Rendering.QualityLevel
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    local terrain = workspaceService:FindFirstChildOfClass("Terrain")
    if terrain and not savedTerrain then
        pcall(function()
            savedTerrain = {
                terrain = terrain,
                WaterWaveSize = terrain.WaterWaveSize,
                WaterWaveSpeed = terrain.WaterWaveSpeed,
                WaterReflectance = terrain.WaterReflectance,
                WaterTransparency = terrain.WaterTransparency,
            }
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end)
    end
    table.insert(antiLagConnections, workspaceService.DescendantAdded:Connect(applyAntiLag))
    table.insert(antiLagConnections, lighting.DescendantAdded:Connect(applyAntiLag))
    task.spawn(function()
        local count = 0
        for _, root in ipairs({ lighting, workspaceService }) do
            for _, inst in ipairs(root:GetDescendants()) do
                if token ~= antiLagToken then
                    return
                end
                applyAntiLag(inst)
                count = count + 1
                if count % 400 == 0 then
                    task.wait()
                end
            end
        end
    end)
end
local function disableAntiLag()
    antiLagToken = antiLagToken + 1
    local token = antiLagToken
    for _, connection in ipairs(antiLagConnections) do
        connection:Disconnect()
    end
    antiLagConnections = {}
    if savedGlobalShadows ~= nil then
        lighting.GlobalShadows = savedGlobalShadows
        savedGlobalShadows = nil
    end
    if savedQuality ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = savedQuality
        end)
        savedQuality = nil
    end
    if savedTerrain then
        local data = savedTerrain
        savedTerrain = nil
        pcall(function()
            data.terrain.WaterWaveSize = data.WaterWaveSize
            data.terrain.WaterWaveSpeed = data.WaterWaveSpeed
            data.terrain.WaterReflectance = data.WaterReflectance
            data.terrain.WaterTransparency = data.WaterTransparency
        end)
    end
    task.spawn(function()
        local count = 0
        for inst, props in pairs(savedProps) do
            if token ~= antiLagToken then
                return
            end
            if inst.Parent then
                for prop, value in pairs(props) do
                    pcall(function()
                        inst[prop] = value
                    end)
                end
            end
            savedProps[inst] = nil
            count = count + 1
            if count % 400 == 0 then
                task.wait()
            end
        end
    end)
end
switchTrack.MouseButton1Click:Connect(function()
    antiLagOn = not antiLagOn
    setSwitchVisual(antiLagOn)
    if antiLagOn then
        enableAntiLag()
    else
        disableAntiLag()
    end
end)
local UserInputService = game:GetService("UserInputService")
local customTechPage = pages["Custom Tech"]
local TechConfig = {
    Enabled = true,
    LethalEnabled = true,
    LethalAnim = "rbxassetid://10503381238",
    LethalDelay = 0.232,
    LethalJump = 55,
    LethalAccuracy = 15,
    LethalCancelDelay = 0.4,
    LethalMode = "V1",
    CancelEnabled = true,
    CooldownActive = true,
    NoClipEnabled = true,
    DashRange = 8,
    TouchMode = false,
    Platform = "PC",
    Keybind = "E",
    CooldownAnims = {
        ["10491993682"] = true,
        ["10479335397"] = true,
        ["13380255751"] = true,
    },
}
local techScriptId = math.random(1, 1000000)
_G.RXMCustomTechId = techScriptId
local function isTechCurrent()
    return _G.RXMCustomTechId == techScriptId
end
local isTechNoclipping = false
local isTechCooldown = false
local isTechExecuting = false
local techCooldownBar
local techCooldownFill
local techConnections = {}
local savedTechCollisions = setmetatable({}, { __mode = "k" })
local function getTechId(value)
    return tostring(value or ""):match("%d+")
end
local function normalizeTechAnimationId(value)
    value = tostring(value or "")
    local id = getTechId(value)
    if not id then
        return value
    end
    return "rbxassetid://" .. id
end
local function clipTech()
    isTechNoclipping = false
    for part, oldCanCollide in pairs(savedTechCollisions) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = oldCanCollide
            end)
        end
        savedTechCollisions[part] = nil
    end
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = true
    end
end
local function forceCancelTech()
    clipTech()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, object in ipairs(root:GetChildren()) do
            if object:IsA("BodyVelocity") or object:IsA("LinearVelocity")
                or object:IsA("Attachment") or object:IsA("BodyAngularVelocity") then
                object:Destroy()
            end
        end
        root.AssemblyLinearVelocity = Vector3.zero
    end
end
local function startTechCooldown(duration)
    if not isTechCurrent() or isTechCooldown or not TechConfig.CooldownActive then
        return
    end
    isTechCooldown = true
    if techCooldownBar and techCooldownFill then
        techCooldownBar.Visible = true
        techCooldownFill.Size = UDim2.new(1, 0, 1, 0)
        tweenService:Create(
            techCooldownFill,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { Size = UDim2.new(0, 0, 1, 0) }
        ):Play()
    end
    task.delay(duration, function()
        isTechCooldown = false
        if techCooldownBar and techCooldownBar.Parent then
            techCooldownBar.Visible = false
        end
    end)
end
local function fireTechDash()
    local character = localPlayer.Character
    local communicate = character and character:FindFirstChild("Communicate")
    if communicate then
        pcall(function()
            communicate:FireServer({
                Dash = Enum.KeyCode.W,
                Key = Enum.KeyCode.Q,
                Goal = "KeyPress",
            })
        end)
    end
end
local function getTechTorsoTarget()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    local targetPart
    local closestDistance = math.max(0, tonumber(TechConfig.DashRange) or 8)
    for _, part in ipairs(workspaceService:GetPartBoundsInRadius(root.Position, closestDistance, params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character and model:FindFirstChildOfClass("Humanoid") then
            local torso = model:FindFirstChild("Torso")
                or model:FindFirstChild("UpperTorso")
                or model:FindFirstChild("HumanoidRootPart")
            if torso then
                local distance = (root.Position - torso.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    targetPart = torso
                end
            end
        end
    end
    return targetPart
end
local function executeTechLethal()
    if not isTechCurrent() or isTechExecuting or isTechCooldown then
        return
    end
    if not TechConfig.Enabled or not TechConfig.LethalEnabled then
        return
    end
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return
    end
    local target = getTechTorsoTarget()
    if not target then
        clipTech()
        return
    end
    isTechExecuting = true
    if not TechConfig.TouchMode then
        task.wait(math.max(0, tonumber(TechConfig.LethalDelay) or 0))
    end
    if not isTechCurrent() or not root.Parent or not target.Parent then
        isTechExecuting = false
        clipTech()
        return
    end
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        tonumber(TechConfig.LethalJump) or 55,
        root.AssemblyLinearVelocity.Z
    )
    isTechNoclipping = true
    fireTechDash()
    local startTime = tick()
    local flipped = false
    local direction = target.Position - root.Position
    if direction.Magnitude < 0.001 then
        direction = root.CFrame.LookVector
    else
        direction = direction.Unit
    end
    local sideVector = Vector3.new(-direction.Z, 0, direction.X)
    local angularVelocity
    if TechConfig.LethalMode == "V1" then
        angularVelocity = Instance.new("BodyAngularVelocity")
        angularVelocity.MaxTorque = Vector3.new(0, 1000000, 0)
        angularVelocity.P = 15000
        angularVelocity.Parent = root
    end
    local connection
    connection = runService.Heartbeat:Connect(function()
        if not isTechCurrent() or not target or not target.Parent or not root or not root.Parent then
            if angularVelocity then angularVelocity:Destroy() end
            clipTech()
            isTechExecuting = false
            if connection then connection:Disconnect() end
            return
        end
        local elapsed = tick() - startTime
        local targetPosition = target.Position
        local rootPosition = root.Position
        humanoid.AutoRotate = false
        if TechConfig.LethalMode == "V1" then
            local angle = (elapsed / 0.45) * (math.pi / 1.5)
            local radius = (tonumber(TechConfig.LethalAccuracy) or 15)
                * (1 - math.clamp(elapsed / 0.45, 0, 1))
            local lookPosition = targetPosition
                + (sideVector * math.cos(angle) + direction * math.sin(angle)) * radius
            local lookCFrame = CFrame.lookAt(
                rootPosition,
                Vector3.new(lookPosition.X, rootPosition.Y, lookPosition.Z)
            )
            local relativeCFrame = root.CFrame:Inverse() * lookCFrame
            local _, yaw, _ = relativeCFrame:ToEulerAnglesXYZ()
            if angularVelocity and angularVelocity.Parent then
                angularVelocity.AngularVelocity = Vector3.new(0, yaw * 30, 0)
            end
        elseif TechConfig.LethalMode == "V2" then
            if elapsed >= (tonumber(TechConfig.LethalAccuracy) or 0.25) and not flipped then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
                flipped = true
            end
        end
        local distanceXZ = (Vector2.new(rootPosition.X, rootPosition.Z)
            - Vector2.new(targetPosition.X, targetPosition.Z)).Magnitude
        if TechConfig.CancelEnabled
            and elapsed > (tonumber(TechConfig.LethalCancelDelay) or 0.4)
            and distanceXZ < 2.2 then
            if angularVelocity then angularVelocity:Destroy() end
            forceCancelTech()
            isTechExecuting = false
            connection:Disconnect()
            return
        end
        if not TechConfig.Enabled or elapsed > 1.5 then
            if angularVelocity then angularVelocity:Destroy() end
            clipTech()
            isTechExecuting = false
            connection:Disconnect()
        end
    end)
end
local techScroll = Instance.new("ScrollingFrame")
techScroll.Name = "CustomTechSettings"
techScroll.Size = UDim2.new(1, 0, 1, 0)
techScroll.Position = UDim2.new(0, 0, 0, 0)
techScroll.BackgroundTransparency = 1
techScroll.BorderSizePixel = 0
techScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
techScroll.ScrollBarThickness = 3
techScroll.ScrollingDirection = Enum.ScrollingDirection.Y
techScroll.Parent = customTechPage
local techLayout = Instance.new("UIListLayout")
techLayout.Padding = UDim.new(0, 6)
techLayout.SortOrder = Enum.SortOrder.LayoutOrder
techLayout.Parent = techScroll
techLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    techScroll.CanvasSize = UDim2.new(0, 0, 0, techLayout.AbsoluteContentSize.Y + 8)
end)
local function createTechToggle(labelText, configKey, onChanged)
    local button = Instance.new("TextButton")
    button.Name = configKey .. "Toggle"
    button.Size = UDim2.new(1, -8, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(245, 245, 245)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = techScroll
    addCorner(button, 6)
    local function refresh()
        button.Text = "  " .. labelText .. ": " .. (TechConfig[configKey] and "ON" or "OFF")
        button.BackgroundColor3 = TechConfig[configKey]
            and Color3.fromRGB(35, 90, 50) or Color3.fromRGB(35, 35, 35)
    end
    button.MouseButton1Click:Connect(function()
        TechConfig[configKey] = not TechConfig[configKey]
        refresh()
        if onChanged then onChanged(TechConfig[configKey]) end
    end)
    refresh()
    return button
end
local function createTechInput(labelText, configKey, options)
    options = options or {}
    local row = Instance.new("Frame")
    row.Name = configKey .. "Row"
    row.Size = UDim2.new(1, -8, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = techScroll
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.48, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(205, 205, 205)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = row
    local input = Instance.new("TextBox")
    input.Name = "Value"
    input.Size = UDim2.new(0.5, 0, 1, 0)
    input.Position = UDim2.new(0.5, 0, 0, 0)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = false
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 11
    input.Text = tostring(TechConfig[configKey])
    input.Parent = row
    addCorner(input, 5)
    input.FocusLost:Connect(function()
        local text = input.Text
        if options.animationId then
            TechConfig[configKey] = normalizeTechAnimationId(text)
        elseif options.number then
            local number = tonumber(text)
            if number then
                TechConfig[configKey] = number
            end
        else
            TechConfig[configKey] = text
        end
        input.Text = tostring(TechConfig[configKey])
        if options.onChanged then options.onChanged(TechConfig[configKey]) end
    end)
    return row, label, input
end
local statusToggle = createTechToggle("Tech Status", "Enabled")
local lethalToggle = createTechToggle("Lethal", "LethalEnabled")
local modeButton = Instance.new("TextButton")
modeButton.Name = "LethalModeToggle"
modeButton.Size = UDim2.new(1, -8, 0, 34)
modeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
modeButton.BorderSizePixel = 0
modeButton.TextColor3 = Color3.fromRGB(245, 245, 245)
modeButton.Font = Enum.Font.GothamSemibold
modeButton.TextSize = 12
modeButton.TextXAlignment = Enum.TextXAlignment.Left
modeButton.Parent = techScroll
addCorner(modeButton, 6)
local function refreshTechMode()
    modeButton.Text = "  Lethal Mode: " .. TechConfig.LethalMode .. "  (tap to switch)"
    local accuracyLabel = techScroll:FindFirstChild("LethalAccuracyRow")
    local label = accuracyLabel and accuracyLabel:FindFirstChild("Label")
    if label then
        label.Text = TechConfig.LethalMode == "V2" and "Flip Delay" or "Accuracy / Flip"
    end
end
modeButton.MouseButton1Click:Connect(function()
    if TechConfig.LethalMode == "V1" then
        TechConfig.LethalMode = "V2"
        TechConfig.LethalAccuracy = 0.25
    else
        TechConfig.LethalMode = "V1"
        TechConfig.LethalAccuracy = 15
    end
    refreshTechMode()
    local accuracyRow = techScroll:FindFirstChild("LethalAccuracyRow")
    local input = accuracyRow and accuracyRow:FindFirstChild("Value")
    if input then input.Text = tostring(TechConfig.LethalAccuracy) end
end)
createTechInput("Lethal Animation ID", "LethalAnim", { animationId = true })
createTechInput("Delay", "LethalDelay", { number = true })
createTechInput("Jump Power", "LethalJump", { number = true })
local accuracyRow = createTechInput("Accuracy / Flip", "LethalAccuracy", { number = true })
createTechInput("Dash Range", "DashRange", { number = true })
createTechInput("Cancel Delay", "LethalCancelDelay", { number = true })
createTechInput("Keybind", "Keybind")
createTechToggle("Cancel System", "CancelEnabled")
createTechToggle("Cooldown System", "CooldownActive")
createTechToggle("NoClip", "NoClipEnabled")
createTechToggle("Touch Mode", "TouchMode", function(enabled)
    if _G.RXMCustomTechMobileTrigger then
        _G.RXMCustomTechMobileTrigger.Visible = enabled and TechConfig.Platform == "Mobile"
    end
end)
local platformButton = Instance.new("TextButton")
platformButton.Name = "PlatformToggle"
platformButton.Size = UDim2.new(1, -8, 0, 34)
platformButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
platformButton.BorderSizePixel = 0
platformButton.TextColor3 = Color3.fromRGB(245, 245, 245)
platformButton.Font = Enum.Font.GothamSemibold
platformButton.TextSize = 12
platformButton.TextXAlignment = Enum.TextXAlignment.Left
platformButton.Parent = techScroll
addCorner(platformButton, 6)
local function refreshTechPlatform()
    platformButton.Text = "  Platform: " .. TechConfig.Platform .. "  (tap to switch)"
end
platformButton.MouseButton1Click:Connect(function()
    TechConfig.Platform = TechConfig.Platform == "PC" and "Mobile" or "PC"
    refreshTechPlatform()
    if _G.RXMCustomTechMobileTrigger then
        _G.RXMCustomTechMobileTrigger.Visible = TechConfig.TouchMode and TechConfig.Platform == "Mobile"
    end
end)
refreshTechPlatform()
local cooldownListRow = Instance.new("Frame")
cooldownListRow.Name = "CooldownAnimsRow"
cooldownListRow.Size = UDim2.new(1, -8, 0, 48)
cooldownListRow.BackgroundTransparency = 1
cooldownListRow.Parent = techScroll
local cooldownListLabel = Instance.new("TextLabel")
cooldownListLabel.Size = UDim2.new(0.48, 0, 1, 0)
cooldownListLabel.BackgroundTransparency = 1
cooldownListLabel.Text = "Cooldown Animation IDs"
cooldownListLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
cooldownListLabel.Font = Enum.Font.Gotham
cooldownListLabel.TextSize = 11
cooldownListLabel.TextWrapped = true
cooldownListLabel.TextXAlignment = Enum.TextXAlignment.Left
cooldownListLabel.Parent = cooldownListRow
local cooldownListInput = Instance.new("TextBox")
cooldownListInput.Size = UDim2.new(0.5, 0, 1, 0)
cooldownListInput.Position = UDim2.new(0.5, 0, 0, 0)
cooldownListInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
cooldownListInput.BorderSizePixel = 0
cooldownListInput.ClearTextOnFocus = false
cooldownListInput.TextColor3 = Color3.fromRGB(255, 255, 255)
cooldownListInput.Font = Enum.Font.Gotham
cooldownListInput.TextSize = 10
cooldownListInput.TextWrapped = true
cooldownListInput.Text = "10491993682, 10479335397, 13380255751"
cooldownListInput.Parent = cooldownListRow
addCorner(cooldownListInput, 5)
cooldownListInput.FocusLost:Connect(function()
    local newAnimations = {}
    for id in string.gmatch(cooldownListInput.Text, "%d+") do
        newAnimations[id] = true
    end
    TechConfig.CooldownAnims = newAnimations
    local ids = {}
    for id in pairs(newAnimations) do table.insert(ids, id) end
    table.sort(ids)
    cooldownListInput.Text = table.concat(ids, ", ")
end)
refreshTechMode()
techCooldownBar = Instance.new("Frame")
techCooldownBar.Name = "TechCooldownBar"
techCooldownBar.Size = UDim2.new(1, 0, 0, 3)
techCooldownBar.Position = UDim2.new(0, 0, 1, -3)
techCooldownBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
techCooldownBar.BackgroundTransparency = 0.35
techCooldownBar.BorderSizePixel = 0
techCooldownBar.Visible = false
techCooldownBar.ZIndex = 10
techCooldownBar.Parent = frame
techCooldownFill = Instance.new("Frame")
techCooldownFill.Name = "Fill"
techCooldownFill.Size = UDim2.new(1, 0, 1, 0)
techCooldownFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
techCooldownFill.BorderSizePixel = 0
techCooldownFill.ZIndex = 11
techCooldownFill.Parent = techCooldownBar
local mobileTrigger = Instance.new("TextButton")
mobileTrigger.Name = "CustomTechMobileTrigger"
mobileTrigger.Size = UDim2.new(0, 56, 0, 56)
mobileTrigger.Position = UDim2.new(0.7, 0, 0.5, 0)
mobileTrigger.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mobileTrigger.Text = "TECH"
mobileTrigger.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileTrigger.Font = Enum.Font.GothamBold
mobileTrigger.TextSize = 11
mobileTrigger.Visible = TechConfig.TouchMode and TechConfig.Platform == "Mobile"
mobileTrigger.Draggable = true
mobileTrigger.Active = true
mobileTrigger.Parent = cleanerGUI
addCorner(mobileTrigger, 28)
local mobileTriggerStroke = Instance.new("UIStroke")
mobileTriggerStroke.Color = Color3.fromRGB(60, 60, 60)
mobileTriggerStroke.Parent = mobileTrigger
_G.RXMCustomTechMobileTrigger = mobileTrigger
mobileTrigger.MouseButton1Click:Connect(executeTechLethal)
table.insert(techConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isTechCurrent() or gameProcessed or not TechConfig.Enabled then return end
    if TechConfig.TouchMode and TechConfig.Platform == "PC" then
        local keyName = tostring(TechConfig.Keybind):upper()
        local keyCode = Enum.KeyCode[keyName]
        if keyCode and input.KeyCode == keyCode then
            executeTechLethal()
        end
    end
end))
local function setupTechCharacter(character)
    if not isTechCurrent() then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    table.insert(techConnections, humanoid.AnimationPlayed:Connect(function(track)
        if not isTechCurrent() then return end
        local animation = track and track.Animation
        if not animation then return end
        local animationId = getTechId(animation.AnimationId)
        if TechConfig.CooldownActive and animationId and TechConfig.CooldownAnims[animationId] then
            startTechCooldown(5)
        end
        if TechConfig.TouchMode or not TechConfig.Enabled or not TechConfig.LethalEnabled then return end
        if normalizeTechAnimationId(animation.AnimationId) == normalizeTechAnimationId(TechConfig.LethalAnim) then
            executeTechLethal()
        end
    end))
end
if localPlayer.Character then
    task.spawn(setupTechCharacter, localPlayer.Character)
end
table.insert(techConnections, localPlayer.CharacterAdded:Connect(setupTechCharacter))
table.insert(techConnections, runService.Stepped:Connect(function()
    if not isTechCurrent() then return end
    local character = localPlayer.Character
    if not character then return end
    if isTechNoclipping and TechConfig.NoClipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if savedTechCollisions[part] == nil then
                    savedTechCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    elseif next(savedTechCollisions) ~= nil then
        clipTech()
    end
end))
local function refreshTechMobileTrigger()
    mobileTrigger.Visible = TechConfig.TouchMode and TechConfig.Platform == "Mobile"
end
refreshTechMobileTrigger()
_G.RXMCustomTechCleanup = function()
    TechConfig.Enabled = false
    forceCancelTech()
    _G.RXMCustomTechId = nil
    _G.RXMCustomTechMobileTrigger = nil
    for _, connection in ipairs(techConnections) do
        pcall(function() connection:Disconnect() end)
    end
    for index in pairs(techConnections) do
        techConnections[index] = nil
    end
    if mobileTrigger and mobileTrigger.Parent then
        mobileTrigger:Destroy()
    end
    if techCooldownBar and techCooldownBar.Parent then
        techCooldownBar.Visible = false
    end
end
selectTab("Cleaner")
end
