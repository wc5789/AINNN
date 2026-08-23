--[[
	AnimeUI — Japanese / Anime style Roblox UI Library
	====================================================
	Clean · Soft · Minimal · Elegant · Mobile-friendly

	Usage:
		local Library = loadstring(game:HttpGet(".../AnimeUI.lua"))()
		-- or: local Library = require(path.to.AnimeUI)

		local Window = Library:CreateWindow({
			Title = "Anime UI",
			Subtitle = "Japanese Style Interface",
			Size = UDim2.fromOffset(560, 380),
			Theme = "Purple Anime", -- Purple Anime | Sakura | Dark Anime
		})

		local Tab = Window:AddTab({ Name = "General" })
		local Section = Tab:AddSection({ Name = "Basic" })

		Section:AddButton({ Name = "Test Button", Callback = function() end })
		Section:AddToggle({ Name = "Enable Feature", Default = false, Callback = function(v) end })
		Section:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
		Section:AddDropdown({ Name = "Mode", Options = {"Default","Anime"}, Default = "Default", Callback = function(v) end })
		Section:AddTextbox({ Name = "Username", Placeholder = "Enter text...", Callback = function(v) end })
		Section:AddLabel({ Text = "Some info text" })
		Section:AddDivider()

		Library:Notify({ Title = "Anime UI", Content = "Setting saved.", Duration = 3 })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

--==========================================================================
-- Theme
--==========================================================================

local THEMES = {
	["Purple Anime"] = {
		Primary    = Color3.fromHex("C8A2FF"),
		Secondary  = Color3.fromHex("A98BE8"),
		Accent     = Color3.fromHex("FF9FCB"),
		Background = Color3.fromHex("15141B"),
		Panel      = Color3.fromHex("1D1B24"),
		Element    = Color3.fromHex("25222E"),
		Text       = Color3.fromHex("F5F2FA"),
		SubText    = Color3.fromHex("AAA5B5"),
		Border     = Color3.fromHex("393342"),
	},
	["Sakura"] = {
		Primary    = Color3.fromHex("FFB7C9"),
		Secondary  = Color3.fromHex("F49AC1"),
		Accent     = Color3.fromHex("FFE3EC"),
		Background = Color3.fromHex("1A1418"),
		Panel      = Color3.fromHex("241C21"),
		Element    = Color3.fromHex("2E2429"),
		Text       = Color3.fromHex("FBF4F6"),
		SubText    = Color3.fromHex("BBA6AE"),
		Border     = Color3.fromHex("45333C"),
	},
	["Dark Anime"] = {
		Primary    = Color3.fromHex("8FA8E8"),
		Secondary  = Color3.fromHex("6F88CC"),
		Accent     = Color3.fromHex("9FD4E8"),
		Background = Color3.fromHex("121318"),
		Panel      = Color3.fromHex("191B22"),
		Element    = Color3.fromHex("22242D"),
		Text       = Color3.fromHex("F2F4FA"),
		SubText    = Color3.fromHex("A2A6B5"),
		Border     = Color3.fromHex("33363F"),
	},
}

local Theme = { Current = THEMES["Purple Anime"] }

function Theme:Apply(themeName)
	self.Current = THEMES[themeName] or THEMES["Purple Anime"]
	return self.Current
end

--==========================================================================
-- Utility
--==========================================================================

local Util = {}

function Util.Create(className, props, children)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if children then
		if typeof(children) == "Instance" then
			inst.Parent = children
		else
			for _, child in ipairs(children) do
				child.Parent = inst
			end
		end
	end
	return inst
end

function Util.Corner(radius)
	return Util.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Util.Stroke(color, thickness, transparency)
	return Util.Create("UIStroke", {
		Color = color or Theme.Current.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Util.Gradient(colorTop, colorBottom)
	return Util.Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colorTop),
			ColorSequenceKeypoint.new(1, colorBottom),
		}),
	})
end

function Util.FadeGradient()
	-- horizontal fade-out gradient for divider lines
	return Util.Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
	})
end

function Util.Pad(px)
	return Util.Create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

function Util.Brighten(color, factor)
	return Color3.new(
		math.clamp(color.R * factor, 0, 1),
		math.clamp(color.G * factor, 0, 1),
		math.clamp(color.B * factor, 0, 1)
	)
end

-- Safe root parent: CoreGui when permitted, otherwise PlayerGui
local RootParent
do
	local ok = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = CoreGui
		probe:Destroy()
	end)
	if ok then
		RootParent = CoreGui
	else
		RootParent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

--==========================================================================
-- Connection Manager (auto cleanup on destroy)
--==========================================================================

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
	return setmetatable({ _list = {} }, ConnectionManager)
end

function ConnectionManager:Connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(self._list, conn)
	return conn
end

function ConnectionManager:Track(conn)
	table.insert(self._list, conn)
	return conn
end

function ConnectionManager:Destroy()
	for _, conn in ipairs(self._list) do
		pcall(function() conn:Disconnect() end)
	end
	self._list = {}
end

--==========================================================================
-- Animation Manager (single source of truth for tween presets)
--==========================================================================

local AnimationManager = {}

-- { duration, easingStyle, easingDirection }
AnimationManager.Tweens = {
	Hover         = { 0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out },
	Press         = { 0.08, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out },
	Release       = { 0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out },
	Toggle        = { 0.18, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out },
	Dropdown      = { 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
	TabTransition = { 0.20, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out },
	Indicator     = { 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out },
	WindowOpen    = { 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out },
	Focus         = { 0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out },
	Notify        = { 0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out },
	NotifyOut     = { 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In  },
	ThumbScale    = { 0.15, Enum.EasingStyle.Back,  Enum.EasingDirection.Out },
}

function AnimationManager:Tween(object, presetName, goal)
	local t = self.Tweens[presetName]
	if not t then
		warn("[AnimeUI] unknown tween preset:", presetName)
		return nil
	end
	local tw = TweenService:Create(object, TweenInfo.new(t[1], t[2], t[3]), goal)
	tw:Play()
	return tw
end

--==========================================================================
-- Library root
--==========================================================================

local Library = {}
Library.Theme = THEMES

--==========================================================================
-- Notification System
--==========================================================================

local NotifyHolder
local Notifications = {}
local NOTIFY_W, NOTIFY_H, NOTIFY_GAP = 250, 64, 10

local function ensureNotifyHolder()
	if NotifyHolder and NotifyHolder.Parent then
		return NotifyHolder
	end
	NotifyHolder = Util.Create("ScreenGui", {
		Name = "AnimeUI_Notifications",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})
	NotifyHolder.Parent = RootParent
	pcall(function() NotifyHolder.Parent = CoreGui end)

	local scale = Util.Create("UIScale", { Scale = 1 })
	scale.Parent = NotifyHolder
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if vp.Y <= 500 then
		scale.Scale = 0.85
	end
	return NotifyHolder
end

function Library:Notify(options)
	options = options or {}
	local theme = Theme.Current
	local holder = ensureNotifyHolder()

	local title = tostring(options.Title or "Anime UI")
	local content = tostring(options.Content or "")
	local duration = tonumber(options.Duration) or 3

	local frame = Util.Create("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(NOTIFY_W, NOTIFY_H),
		Position = UDim2.new(1, NOTIFY_W + 60, 1, -40),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	frame.Parent = holder
	Util.Corner(10).Parent = frame
	local stroke = Util.Stroke(theme.Border, 1, 0.85)
	stroke.Parent = frame
	Util.Gradient(theme.Panel, theme.Background).Parent = frame

	local bar = Util.Create("Frame", { -- left accent bar
		Name = "AccentBar",
		Size = UDim2.new(0, 3, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	bar.Parent = frame
	Util.Corner(2).Parent = bar

	Util.Create("TextLabel", {
		Name = "Title",
		Text = "✦ " .. title,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.Primary,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 9),
		Size = UDim2.new(1, -34, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		Parent = frame,
	})

	Util.Create("TextLabel", {
		Name = "Content",
		Text = content,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 28),
		Size = UDim2.new(1, -34, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
		Parent = frame,
	})

	table.insert(Notifications, frame)

	-- stack from bottom-right upward; newest tweens in, others reflow smoothly
	local function relayout(animateNew)
		local y = -40
		for i = #Notifications, 1, -1 do
			local n = Notifications[i]
			if not n.Parent then
				table.remove(Notifications, i)
			else
				local target = UDim2.new(1, 20, 1, y)
				if animateNew and n == frame then
					AnimationManager:Tween(n, "Notify", { Position = target, BackgroundTransparency = 0.05 })
					AnimationManager:Tween(stroke, "Notify", { Transparency = 0.2 })
				else
					AnimationManager:Tween(n, "Notify", { Position = target })
				end
				y = y - (NOTIFY_H + NOTIFY_GAP)
			end
		end
	end

	task.defer(function()
		relayout(true)
	end)

	task.delay(duration, function()
		if not frame.Parent then return end
		AnimationManager:Tween(frame, "NotifyOut", {
			Position = UDim2.new(1, NOTIFY_W + 60, 1, -40),
			BackgroundTransparency = 0.5,
		})
		AnimationManager:Tween(stroke, "NotifyOut", { Transparency = 1 })
		AnimationManager:Tween(bar, "NotifyOut", { BackgroundTransparency = 1 })
		task.delay(0.26, function()
			local idx = table.find(Notifications, frame)
			if idx then table.remove(Notifications, idx) end
			frame:Destroy()
			relayout(false)
		end)
	end)
end

--==========================================================================
-- Class declarations (order matters for upvalues)
--==========================================================================

local Window  = {}
Window.__index = Window
local Tab     = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

Library.Window = Window
Library.Tab = Tab
Library.Section = Section

-- shared row factory: one consistent visual language for all controls
local function makeRow(parent, height)
	local row = Util.Create("TextButton", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height or 34),
		BackgroundColor3 = Theme.Current.Element,
		BackgroundTransparency = 0.35,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	})
	row.Parent = parent
	Util.Corner(8).Parent = row
	return row
end

--==========================================================================
-- Window
--==========================================================================

function Library:CreateWindow(options)
	options = options or {}

	Theme:Apply(options.Theme or "Purple Anime")
	local theme = Theme.Current

	local screenGui = Util.Create("ScreenGui", {
		Name = "AnimeUI_" .. tostring(math.random(10000, 99999)),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 9999,
		IgnoreGuiInset = true,
	})
	screenGui.Parent = RootParent
	pcall(function() screenGui.Parent = CoreGui end)

	local self = setmetatable({}, Window)
	self.Gui = screenGui
	self.Connections = ConnectionManager.new()
	self.Tabs = {}
	self._destroyed = false

	local winW = options.Size and options.Size.X.Offset or 560
	local winH = options.Size and options.Size.Y.Offset or 380
	self._winW, self._winH = winW, winH

	-- UIScale: PC normal, mobile compact, tiny screens compressed
	local uiScale = Util.Create("UIScale", { Scale = 1 })
	uiScale.Parent = screenGui
	self.UIScale = uiScale

	local function updateScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s
		if vp.Y <= 500 then
			s = 0.78
		elseif vp.Y < 700 then
			s = 0.9
		else
			s = math.clamp(vp.Y / 900, 0.95, 1)
		end
		s = math.min(s, (vp.X * 0.94) / winW, (vp.Y * 0.88) / winH)
		if not self._compact then
			uiScale.Scale = math.max(s, 0.5)
		end
	end
	updateScale()
	if workspace.CurrentCamera then
		self.Connections:Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
	end

	------------------------------------------------------------------
	-- Container (drag target + open animation)
	------------------------------------------------------------------
	local container = Util.Create("Frame", {
		Name = "Container",
		Size = UDim2.fromOffset(winW, winH),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	self.Container = container

	------------------------------------------------------------------
	-- Body
	------------------------------------------------------------------
	local body = Util.Create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = container,
	})
	Util.Corner(10).Parent = body
	local bodyStroke = Util.Stroke(theme.Border, 1, 0.25)
	bodyStroke.Parent = body
	Util.Gradient(Util.Brighten(theme.Background, 1.35), theme.Background).Parent = body

	-- anime top highlight: thin line glowing softly at its center
	local highlightLine = Util.Create("Frame", {
		Name = "TopHighlight",
		Size = UDim2.new(1, -28, 0, 1),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundColor3 = theme.Primary,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = body,
	})
	Util.Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, highlightLine)

	------------------------------------------------------------------
	-- Sidebar
	------------------------------------------------------------------
	local sidebarWidth = 148
	local sidebar = Util.Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = body,
	})
	Util.Corner(10).Parent = sidebar
	-- square off sidebar top (tucked under the header)
	Util.Create("Frame", {
		Name = "TopFix",
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar,
	})
	-- right edge line
	Util.Create("Frame", {
		Name = "Edge",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = sidebar,
	})

	local tabList = Util.Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 1, -24),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = theme.Primary,
		ScrollBarImageTransparency = 0.5,
		ZIndex = 3,
		Parent = sidebar,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabList)
	Util.Pad(10).Parent = tabList

	-- sliding accent indicator
	local indicator = Util.Create("Frame", {
		Name = "TabIndicator",
		Size = UDim2.new(0, 3, 0, 20),
		Position = UDim2.new(0, 5, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = sidebar,
	})
	Util.Corner(2).Parent = indicator

	------------------------------------------------------------------
	-- Page holder
	------------------------------------------------------------------
	local pageHolder = Util.Create("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -(sidebarWidth + 1), 1, 0),
		Position = UDim2.new(0, sidebarWidth + 1, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 2,
		Parent = body,
	})

	------------------------------------------------------------------
	-- Header (draggable, on top)
	------------------------------------------------------------------
	local headerHeight = 38
	local header = Util.Create("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, headerHeight),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.15,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = body,
	})
	Util.Corner(10).Parent = header
	-- square off header bottom corners
	Util.Create("Frame", {
		Name = "BottomFix",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -16),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = header,
	})
	-- header divider line
	Util.Create("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 1, -1),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = header,
	})

	-- ✦ sparkle icon
	Util.Create("TextLabel", {
		Name = "Icon",
		Text = "✦",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		ZIndex = 12,
		Parent = header,
	})

	Util.Create("TextLabel", {
		Name = "Title",
		Text = options.Title or "Anime UI",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = header,
	})

	-- faint japanese decoration
	Util.Create("TextLabel", {
		Name = "JPDecor",
		Text = "アニメ UI",
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = theme.Secondary,
		TextTransparency = 0.55,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -60, 0, 0),
		Size = UDim2.new(0.4, 60, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 12,
		Parent = header,
	})

	self.Connections:Connect(header.MouseEnter, function()
		AnimationManager:Tween(highlightLine, "Hover", { BackgroundTransparency = 0.4 })
	end)
	self.Connections:Connect(header.MouseLeave, function()
		AnimationManager:Tween(highlightLine, "Hover", { BackgroundTransparency = 0.7 })
	end)

	------------------------------------------------------------------
	-- Window buttons: minimize / compact / close
	------------------------------------------------------------------
	local function makeWinBtn(xOffset, symbol, callback)
		local btn = Util.Create("TextButton", {
			Name = "WinBtn_" .. symbol,
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.Element,
			BackgroundTransparency = 0.4,
			Text = symbol,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = theme.SubText,
			BorderSizePixel = 0,
			ZIndex = 12,
		})
		btn.Parent = header
		Util.Corner(7).Parent = btn
		btn.MouseEnter:Connect(function()
			AnimationManager:Tween(btn, "Hover", { BackgroundTransparency = 0.05, TextColor3 = theme.Text })
		end)
		btn.MouseLeave:Connect(function()
			AnimationManager:Tween(btn, "Hover", { BackgroundTransparency = 0.4, TextColor3 = theme.SubText })
		end)
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	-- minimize (collapse to header bar)
	makeWinBtn(-92, "—", function()
		self._collapsed = not self._collapsed
		local targetH = self._collapsed and (headerHeight + 4) or winH
		AnimationManager:Tween(container, "Dropdown", { Size = UDim2.fromOffset(winW, targetH) })
	end)

	-- compact mode (scales everything down — mobile friendly)
	makeWinBtn(-58, "□", function()
		self._compact = not self._compact
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local target = self._compact and 0.8 or math.clamp(vp.Y / 900, 0.95, 1)
		target = math.min(target, (vp.X * 0.94) / winW, (vp.Y * 0.88) / winH)
		AnimationManager:Tween(uiScale, "Dropdown", { Scale = math.max(target, 0.5) })
	end)

	-- close
	makeWinBtn(-24, "×", function()
		self:Destroy()
	end)

	------------------------------------------------------------------
	-- Dragging: header only · mouse + touch · scale-aware
	------------------------------------------------------------------
	do
		local dragging, dragStart, startPos = false, nil, nil

		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = container.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		self.Connections:Connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local s = math.max(uiScale.Scale, 0.01)
				local delta = (input.Position - dragStart) / s
				container.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	------------------------------------------------------------------
	-- Open animation: fade in + grow + rise (no bounce)
	------------------------------------------------------------------
	body.BackgroundTransparency = 1
	bodyStroke.Transparency = 1
	container.Size = UDim2.fromOffset(winW * 0.96, winH * 0.96)
	task.defer(function()
		AnimationManager:Tween(body, "WindowOpen", { BackgroundTransparency = 0.04 })
		AnimationManager:Tween(bodyStroke, "WindowOpen", { Transparency = 0.25 })
		AnimationManager:Tween(container, "WindowOpen", {
			Size = UDim2.fromOffset(winW, winH),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		})
	end)

	------------------------------------------------------------------
	-- Expose + cleanup wiring
	------------------------------------------------------------------
	self.Body = body
	self.Header = header
	self.Sidebar = sidebar
	self.TabList = tabList
	self.Indicator = indicator
	self.PageHolder = pageHolder
	self._headerHeight = headerHeight

	self.Connections:Connect(screenGui.Destroying, function()
		self:_cleanup()
	end)

	return self
end

function Window:_cleanup()
	if self._destroyed then return end
	self._destroyed = true
	for _, tab in ipairs(self.Tabs) do
		if tab.Connections then tab.Connections:Destroy() end
	end
	self.Connections:Destroy()
end

function Window:Destroy()
	local gui = self.Gui
	self:_cleanup()
	if gui then gui:Destroy() end
end

--==========================================================================
-- Tabs
--==========================================================================

function Window:AddTab(options)
	options = options or {}
	local theme = Theme.Current
	local name = options.Name or ("Tab" .. tostring(#self.Tabs + 1))
	local order = #self.Tabs + 1

	-- page = CanvasGroup (enables GroupTransparency cross-fade) + ScrollingFrame
	local page = Util.Create("CanvasGroup", {
		Name = name .. "_Page",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = self.PageHolder,
	})

	local scroll = Util.Create("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Primary,
		ScrollBarImageTransparency = 0.55,
		ZIndex = 2,
		Parent = page,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)
	Util.Pad(4).Parent = scroll

	-- tab button (○ / ● style)
	local btn = Util.Create("TextButton", {
		Name = name .. "_Tab",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = theme.Element,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 4,
		Parent = self.TabList,
	})
	Util.Corner(7).Parent = btn

	local dot = Util.Create("TextLabel", {
		Name = "Dot",
		Text = "○",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 14, 1, 0),
		ZIndex = 5,
		Parent = btn,
	})
	local label = Util.Create("TextLabel", {
		Name = "Label",
		Text = name,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 26, 0, 0),
		Size = UDim2.new(1, -34, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = btn,
	})

	local tab = setmetatable({
		Window = self,
		Name = name,
		Page = page,
		Scroll = scroll,
		Button = btn,
		Dot = dot,
		Label = label,
		Order = order,
		Sections = {},
		Connections = ConnectionManager.new(),
	}, Tab)

	tab.Connections:Connect(btn.MouseEnter, function()
		if self.SelectedTab ~= tab then
			AnimationManager:Tween(label, "Hover", { TextColor3 = theme.Text })
			AnimationManager:Tween(dot, "Hover", { TextColor3 = theme.Secondary })
		end
	end)
	tab.Connections:Connect(btn.MouseLeave, function()
		if self.SelectedTab ~= tab then
			AnimationManager:Tween(label, "Hover", { TextColor3 = theme.SubText })
			AnimationManager:Tween(dot, "Hover", { TextColor3 = theme.SubText })
		end
	end)
	tab.Connections:Connect(btn.MouseButton1Click, function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if not self._autoSelected then
		self._autoSelected = true
		task.defer(function()
			if not self._destroyed then
				self:SelectTab(tab)
			end
		end)
	end

	return tab
end

function Window:SelectTab(targetTab)
	if self._destroyed or self.SelectedTab == targetTab then return end
	local theme = Theme.Current
	local previous = self.SelectedTab
	self.SelectedTab = targetTab

	-- restyle tabs (Text is not tweenable → assign directly)
	for _, tab in ipairs(self.Tabs) do
		local selected = (tab == targetTab)
		tab.Dot.Text = selected and "●" or "○"
		AnimationManager:Tween(tab.Button, "TabTransition", {
			BackgroundTransparency = selected and 0.25 or 1,
		})
		AnimationManager:Tween(tab.Dot, "TabTransition", {
			TextColor3 = selected and theme.Primary or theme.SubText,
		})
		AnimationManager:Tween(tab.Label, "TabTransition", {
			TextColor3 = selected and theme.Text or theme.SubText,
		})
	end

	-- slide the accent indicator (scale-aware)
	do
		local s = math.max(self.UIScale.Scale, 0.01)
		local relY = (targetTab.Button.AbsolutePosition.Y - self.TabList.AbsolutePosition.Y) / s
		local btnH = targetTab.Button.Size.Y.Offset
		local scrollY = self.TabList.CanvasPosition.Y
		AnimationManager:Tween(self.Indicator, "Indicator", {
			Position = UDim2.new(0, 5, 0, relY + scrollY + (btnH - 20) / 2),
		})
	end

	-- page cross-fade with slight horizontal shift
	if previous and previous.Page and previous.Page.Visible then
		local oldPage = previous.Page
		AnimationManager:Tween(oldPage, "TabTransition", {
			GroupTransparency = 1,
			Position = UDim2.new(0, -6, 0, 8),
		})
		task.delay(0.2, function()
			oldPage.Visible = false
			oldPage.Position = UDim2.new(0, 8, 0, 8)
			oldPage.GroupTransparency = 0
		end)
	end

	local page = targetTab.Page
	page.Visible = true
	page.GroupTransparency = 1
	page.Position = UDim2.new(0, 22, 0, 8)
	task.defer(function()
		AnimationManager:Tween(page, "TabTransition", {
			GroupTransparency = 0,
			Position = UDim2.new(0, 8, 0, 8),
		})
	end)
end

--==========================================================================
-- Sections
--==========================================================================

function Tab:AddSection(options)
	options = options or {}
	local theme = Theme.Current
	local base = (#self.Sections + 1) * 10

	local section = setmetatable({
		Tab = self,
		Order = base,
		Connections = ConnectionManager.new(),
	}, Section)

	-- section title: "✦ NAME"
	local title = Util.Create("TextLabel", {
		Name = "SectionTitle",
		Text = "✦ " .. string.upper(options.Name or "SECTION"),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = base,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = self.Scroll,
	})

	-- thin fading divider under the title
	local divider = Util.Create("Frame", {
		Name = "SectionDivider",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = base + 1,
		ZIndex = 2,
	})
	divider.Parent = self.Scroll
	Util.FadeGradient().Parent = divider

	-- content frame (auto height via AutomaticSize)
	local content = Util.Create("Frame", {
		Name = "SectionContent",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = base + 2,
		ZIndex = 2,
		Parent = self.Scroll,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)

	section.Content = content
	table.insert(self.Sections, section)
	return section
end

--==========================================================================
-- Button
--==========================================================================

function Section:AddButton(options)
	options = options or {}
	local theme = Theme.Current

	local btn = Util.Create("TextButton", {
		Name = "Button_" .. (options.Name or ""),
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = theme.Element,
		BackgroundTransparency = 0.25,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Content,
	})
	Util.Corner(8).Parent = btn
	Util.Stroke(theme.Border, 1, 0.35).Parent = btn

	local label = Util.Create("TextLabel", {
		Name = "Label",
		Text = options.Name or "Button",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = btn,
	})
	local arrow = Util.Create("TextLabel", {
		Name = "Arrow",
		Text = "›",
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
		Parent = btn,
	})

	-- accent flash on press (subtle, no big ripple)
	local flash = Util.Create("Frame", {
		Name = "Flash",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = btn,
	})
	Util.Corner(8).Parent = flash

	btn.MouseEnter:Connect(function()
		AnimationManager:Tween(btn, "Hover", {
			BackgroundColor3 = Util.Brighten(theme.Element, 1.35),
			BackgroundTransparency = 0.05,
		})
		AnimationManager:Tween(arrow, "Hover", {
			TextColor3 = theme.Primary,
			Position = UDim2.new(1, -23, 0, 0),
		})
	end)
	btn.MouseLeave:Connect(function()
		AnimationManager:Tween(btn, "Release", { BackgroundColor3 = theme.Element, BackgroundTransparency = 0.25 })
		AnimationManager:Tween(arrow, "Release", { TextColor3 = theme.SubText, Position = UDim2.new(1, -26, 0, 0) })
	end)

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			AnimationManager:Tween(flash, "Press", { BackgroundTransparency = 0.85 })
			AnimationManager:Tween(label, "Press", { Size = UDim2.new(1, -38, 0.96, 0) })
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			AnimationManager:Tween(flash, "Release", { BackgroundTransparency = 1 })
			AnimationManager:Tween(label, "Release", { Size = UDim2.new(1, -36, 1, 0) })
		end
	end)
	btn.MouseButton1Click:Connect(function()
		if options.Callback then task.spawn(options.Callback) end
	end)

	return {
		Set = function(_, text) label.Text = tostring(text) end,
		Destroy = function() btn:Destroy() end,
	}
end

--==========================================================================
-- Toggle
--==========================================================================

function Section:AddToggle(options)
	options = options or {}
	local theme = Theme.Current
	local state = options.Default == true

	local row = makeRow(self.Content, 34)

	local label = Util.Create("TextLabel", {
		Name = "Label",
		Text = options.Name or "Toggle",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = row,
	})

	-- switch track + thumb
	local trackW, trackH = 38, 20
	local thumbSize = trackH - 6
	local track = Util.Create("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(trackW, trackH),
		Position = UDim2.new(1, -12 - trackW, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Border,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = row,
	})
	Util.Corner(trackH / 2).Parent = track
	local glow = Util.Stroke(theme.Primary, 1, 1)
	glow.Parent = track

	local thumb = Util.Create("Frame", {
		Name = "Thumb",
		Size = UDim2.fromOffset(thumbSize, thumbSize),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.SubText,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = track,
	})
	Util.Corner(thumbSize / 2).Parent = thumb

	local function render(instant)
		local trackColor = state and theme.Primary or theme.Border
		local thumbColor = state and theme.Text or theme.SubText
		local thumbPos = state
			and UDim2.new(1, -(3 + thumbSize), 0.5, 0)
			or UDim2.new(0, 3, 0.5, 0)
		local glowTrans = state and 0.55 or 1
		if instant then
			track.BackgroundColor3 = trackColor
			thumb.Position = thumbPos
			thumb.BackgroundColor3 = thumbColor
			glow.Transparency = glowTrans
		else
			AnimationManager:Tween(track, "Toggle", { BackgroundColor3 = trackColor })
			AnimationManager:Tween(thumb, "Toggle", { Position = thumbPos, BackgroundColor3 = thumbColor })
			AnimationManager:Tween(glow, "Toggle", { Transparency = glowTrans })
		end
	end
	render(true)

	local function setState(v)
		if state == v then return end
		state = v
		render(false)
		if options.Callback then task.spawn(options.Callback, v) end
	end

	-- whole row is the click target (large hit area for mobile)
	row.MouseButton1Click:Connect(function()
		setState(not state)
	end)
	row.MouseEnter:Connect(function()
		AnimationManager:Tween(row, "Hover", { BackgroundTransparency = 0.1 })
	end)
	row.MouseLeave:Connect(function()
		AnimationManager:Tween(row, "Release", { BackgroundTransparency = 0.35 })
	end)

	return {
		Set = function(_, v) setState(v == true) end,
		Get = function() return state end,
		Destroy = function() row:Destroy() end,
	}
end

--==========================================================================
-- Slider
--==========================================================================

function Section:AddSlider(options)
	options = options or {}
	local theme = Theme.Current
	local minV = tonumber(options.Min) or 0
	local maxV = tonumber(options.Max) or 100
	if maxV <= minV then maxV = minV + 1 end
	local value = math.clamp(tonumber(options.Default) or minV, minV, maxV)
	local suffix = options.Suffix or ""
	local precision = tonumber(options.Precision) or (maxV <= 1 and 2 or 0)

	local row = makeRow(self.Content, 52)
	row.BackgroundTransparency = 0.55

	local label = Util.Create("TextLabel", {
		Name = "Label",
		Text = options.Name or "Slider",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -76, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = row,
	})

	local valueLabel = Util.Create("TextLabel", {
		Name = "Value",
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = theme.Primary,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -64, 0, 8),
		Size = UDim2.new(0, 52, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
		Parent = row,
	})

	local hitArea = Util.Create("TextButton", {
		Name = "HitArea",
		Text = "",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 30),
		Size = UDim2.new(1, -24, 0, 16),
		ZIndex = 5,
		Parent = row,
	})

	local trackH = 5
	local trackBase = Util.Create("Frame", {
		Name = "TrackBase",
		Size = UDim2.new(1, 0, 0, trackH),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = hitArea,
	})
	Util.Corner(trackH / 2).Parent = trackBase

	local fill = Util.Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = trackBase,
	})
	Util.Corner(trackH / 2).Parent = fill

	local thumbSize = 13
	local thumb = Util.Create("Frame", {
		Name = "Thumb",
		Size = UDim2.fromOffset(thumbSize, thumbSize),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		ZIndex = 7,
		Parent = hitArea,
	})
	Util.Corner(thumbSize / 2).Parent = thumb
	local thumbRing = Util.Stroke(theme.Primary, 1.5, 0.35)
	thumbRing.Parent = thumb

	local function fmt(v)
		if precision > 0 then
			return string.format("%." .. precision .. "f", v) .. suffix
		end
		return tostring(math.floor(v + 0.5)) .. suffix
	end

	local function setValue(v, fire)
		v = math.clamp(v, minV, maxV)
		value = v
		local alpha = (v - minV) / (maxV - minV)
		fill.Size = UDim2.fromScale(alpha, 1)
		thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = fmt(v)
		if fire ~= false and options.Callback then
			task.spawn(options.Callback, v)
		end
	end
	setValue(value, false)

	local dragging = false
	local function inputToValue(input)
		local rel = (input.Position.X - trackBase.AbsolutePosition.X)
			/ math.max(trackBase.AbsoluteSize.X, 1)
		setValue(minV + math.clamp(rel, 0, 1) * (maxV - minV))
	end

	hitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			inputToValue(input)
			AnimationManager:Tween(thumb, "ThumbScale", {
				Size = UDim2.fromOffset(thumbSize + 4, thumbSize + 4),
			})
			AnimationManager:Tween(thumbRing, "Focus", { Transparency = 0.1 })
		end
	end)

	local function onGlobalInputChanged(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			inputToValue(input)
		end
	end

	local function onGlobalInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				AnimationManager:Tween(thumb, "ThumbScale", {
					Size = UDim2.fromOffset(thumbSize, thumbSize),
				})
				AnimationManager:Tween(thumbRing, "Focus", { Transparency = 0.35 })
			end
		end
	end

	self.Connections:Track(UserInputService.InputChanged:Connect(onGlobalInputChanged))
	self.Connections:Track(UserInputService.InputEnded:Connect(onGlobalInputEnded))

	hitArea.MouseEnter:Connect(function()
		if not dragging then
			AnimationManager:Tween(thumbRing, "Focus", { Thickness = 2.5 })
		end
	end)
	hitArea.MouseLeave:Connect(function()
		if not dragging then
			AnimationManager:Tween(thumbRing, "Focus", { Thickness = 1.5 })
		end
	end)

	return {
		Set = function(_, v) setValue(tonumber(v) or value, true) end,
		Get = function() return value end,
		Destroy = function() row:Destroy() end,
	}
end

--==========================================================================
-- Dropdown
--==========================================================================

function Section:AddDropdown(options)
	options = options or {}
	local theme = Theme.Current
	local optionList = options.Options or {}
	local selected = options.Default or (optionList[1] or "")

	local container = Util.Create("Frame", {
		Name = "Dropdown",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		ClipsDescendants = false,
		ZIndex = 10,
		Parent = self.Content,
	})

	local row = Util.Create("TextButton", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = theme.Element,
		BackgroundTransparency = 0.35,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = container,
	})
	Util.Corner(8).Parent = row
	local stroke = Util.Stroke(theme.Border, 1, 0.35)
	stroke.Parent = row

	Util.Create("TextLabel", {
		Name = "Name",
		Text = options.Name or "Dropdown",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.45, -12, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = row,
	})

	local arrow = Util.Create("TextLabel", {
		Name = "Arrow",
		Text = "▼",
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 16, 1, 0),
		ZIndex = 12,
		Parent = row,
	})

	local valueLabel = Util.Create("TextLabel", {
		Name = "Value",
		Text = tostring(selected),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.Primary,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.45, 0, 0, 0),
		Size = UDim2.new(0.55, -46, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
		Parent = row,
	})

	-- floating list: parented to the tab's page CanvasGroup so it can
	-- overlay neighbouring rows; high ZIndex keeps it above everything
	local listOpen = false
	local itemH, gap, pad = 28, 4, 6
	local maxVisible = 4
	local listHeight = math.min(#optionList, maxVisible) * (itemH + gap) - gap + pad * 2

	local page = self.Tab.Page
	local list = Util.Create("ScrollingFrame", {
		Name = "DropdownList",
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, #optionList * (itemH + gap) - gap + pad * 2),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = theme.Primary,
		ScrollBarImageTransparency = 0.4,
		Visible = false,
		ZIndex = 30,
		Parent = page,
	})
	Util.Corner(8).Parent = list
	Util.Stroke(theme.Border, 1, 0.2).Parent = list
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	Util.Pad(pad).Parent = list

	local items = {}
	local setOpen -- forward declaration

	local function refreshItems()
		for i = #optionList + 1, #items do
			items[i]:Destroy()
			items[i] = nil
		end
		for i, optText in ipairs(optionList) do
			local item = items[i]
			if not item then
				item = Util.Create("TextButton", {
					Name = "Item_" .. tostring(optText),
					Size = UDim2.new(1, 0, 0, itemH),
					BackgroundColor3 = theme.Element,
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					LayoutOrder = i,
					ZIndex = 31,
					Parent = list,
				})
				Util.Corner(6).Parent = item
				item.Label = Util.Create("TextLabel", {
					Name = "Label",
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextColor3 = theme.SubText,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 32,
					Parent = item,
				})
				items[i] = item
				item.MouseEnter:Connect(function()
					AnimationManager:Tween(item, "Hover", { BackgroundTransparency = 0.35 })
				end)
				item.MouseLeave:Connect(function()
					AnimationManager:Tween(item, "Hover", { BackgroundTransparency = (optText == selected) and 0.5 or 1 })
				end)
				item.MouseButton1Click:Connect(function()
					selected = optText
					valueLabel.Text = tostring(selected)
					refreshItems()
					setOpen(false)
					if options.Callback then task.spawn(options.Callback, selected) end
				end)
			end
			item.Label.Text = tostring(optText)
			item.Label.TextColor3 = (optText == selected) and theme.Primary or theme.SubText
			item.BackgroundTransparency = (optText == selected) and 0.5 or 1
		end
	end

	function setOpen(open)
		if listOpen == open then return end
		listOpen = open
		if open then
			refreshItems()
			-- position relative to the page (UIScale-aware)
			local s = math.max(self.Tab.Window.UIScale.Scale, 0.01)
			local x = (row.AbsolutePosition.X - page.AbsolutePosition.X) / s
			local yTop = (row.AbsolutePosition.Y - page.AbsolutePosition.Y) / s
			local y = yTop + row.AbsoluteSize.Y / s + 6
			-- flip upward when there is not enough room below
			if (row.AbsolutePosition.Y + row.AbsoluteSize.Y + 6 + listHeight * s)
				> page.AbsolutePosition.Y + page.AbsoluteSize.Y then
				y = yTop - listHeight - 6
			end
			list.Position = UDim2.fromOffset(x, y)
			list.Size = UDim2.new(0, row.AbsoluteSize.X / s, 0, 0)
			list.Visible = true
			list.CanvasPosition = Vector2.new(0, 0)
			AnimationManager:Tween(list, "Dropdown", { Size = UDim2.new(0, row.AbsoluteSize.X / s, 0, listHeight) })
			AnimationManager:Tween(arrow, "Dropdown", { Rotation = 180, TextColor3 = theme.Primary })
			AnimationManager:Tween(stroke, "Focus", { Color = theme.Primary, Transparency = 0.1 })
		else
			AnimationManager:Tween(list, "Dropdown", { Size = UDim2.new(0, list.Size.X.Offset, 0, 0) })
			AnimationManager:Tween(arrow, "Dropdown", { Rotation = 0, TextColor3 = theme.SubText })
			AnimationManager:Tween(stroke, "Focus", { Color = theme.Border, Transparency = 0.35 })
			task.delay(0.2, function()
				if not listOpen then list.Visible = false end
			end)
		end
	end

	row.MouseButton1Click:Connect(function() setOpen(not listOpen) end)
	row.MouseEnter:Connect(function()
		AnimationManager:Tween(row, "Hover", { BackgroundTransparency = 0.15 })
	end)
	row.MouseLeave:Connect(function()
		AnimationManager:Tween(row, "Release", { BackgroundTransparency = 0.35 })
	end)

	-- click outside closes the list
	self.Connections:Track(UserInputService.InputBegan:Connect(function(input)
		if not listOpen then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local lt, ls = list.AbsolutePosition, list.AbsoluteSize
			local rt, rs = row.AbsolutePosition, row.AbsoluteSize
			local inList = p.X >= lt.X and p.X <= lt.X + ls.X and p.Y >= lt.Y and p.Y <= lt.Y + ls.Y
			local inRow = p.X >= rt.X and p.X <= rt.X + rs.X and p.Y >= rt.Y and p.Y <= rt.Y + rs.Y
			if not inList and not inRow then
				setOpen(false)
			end
		end
	end))

	return {
		Set = function(_, v)
			selected = v
			valueLabel.Text = tostring(v)
			refreshItems()
		end,
		Get = function() return selected end,
		Refresh = function(_, newOptions)
			optionList = newOptions or optionList
			list.CanvasSize = UDim2.new(0, 0, 0, #optionList * (itemH + gap) - gap + pad * 2)
			refreshItems()
		end,
	}
end

--==========================================================================
-- Textbox
--==========================================================================

function Section:AddTextbox(options)
	options = options or {}
	local theme = Theme.Current
	local placeholder = options.Placeholder or "Enter text..."

	local container = Util.Create("Frame", {
		Name = "Textbox",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 54),
		ZIndex = 3,
		Parent = self.Content,
	})

	Util.Create("TextLabel", {
		Name = "Name",
		Text = options.Name or "Textbox",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 0),
		Size = UDim2.new(1, -4, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = container,
	})

	local boxBg = Util.Create("Frame", {
		Name = "BoxBg",
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = container,
	})
	Util.Corner(8).Parent = boxBg
	local stroke = Util.Stroke(theme.Border, 1, 0.3)
	stroke.Parent = boxBg

	local textbox = Util.Create("TextBox", {
		Name = "Input",
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = theme.SubText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = options.ClearTextOnFocus == true,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		ZIndex = 5,
		Parent = boxBg,
	})

	textbox.Focused:Connect(function()
		AnimationManager:Tween(stroke, "Focus", { Color = theme.Primary, Transparency = 0 })
		AnimationManager:Tween(boxBg, "Focus", {
			BackgroundTransparency = 0,
			BackgroundColor3 = Util.Brighten(theme.Background, 1.3),
		})
	end)

	textbox.FocusLost:Connect(function()
		AnimationManager:Tween(stroke, "Focus", { Color = theme.Border, Transparency = 0.3 })
		AnimationManager:Tween(boxBg, "Focus", {
			BackgroundTransparency = 0.15,
			BackgroundColor3 = theme.Background,
		})
		if options.Callback then task.spawn(options.Callback, textbox.Text) end
	end)

	return {
		Set = function(_, text) textbox.Text = tostring(text) end,
		Get = function() return textbox.Text end,
		Focus = function() textbox:CaptureFocus() end,
	}
end

--==========================================================================
-- Label & Divider
--==========================================================================

function Section:AddLabel(options)
	options = options or {}
	local theme = Theme.Current

	local label = Util.Create("TextLabel", {
		Name = "Label",
		Text = options.Text or options.Name or "Label",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = theme.SubText,
		BackgroundTransparency = 1,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = self.Content,
	})

	return {
		Set = function(_, text) label.Text = tostring(text) end,
		Destroy = function() label:Destroy() end,
	}
end

function Section:AddDivider()
	local divider = Util.Create("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Current.Border,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Content,
	})
	Util.FadeGradient().Parent = divider
	return divider
end

return Library