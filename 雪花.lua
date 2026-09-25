--[[
================================================================================
    Snow UI Library  |  雪花 UI 库
    Version : 1.0.0
    License : MIT
================================================================================
]]

--================================================================================
-- [01] 服务引用
--================================================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer

--================================================================================
-- [02] 常量定义
--================================================================================

local LIBRARY_NAME    = "Snow"
local LIBRARY_VERSION = "1.0.0"

local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local ROW_HEIGHT      = 36
local WINDOW_RADIUS   = 10
local ELEMENT_RADIUS  = 6

local ANIM_FAST   = 0.12
local ANIM_NORMAL = 0.18
local ANIM_SLOW   = 0.28

-- 设备类型检测
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--================================================================================
-- [03] 工具函数
--================================================================================

local function Create(className, properties)
	local instance = Instance.new(className)
	local parent = nil
	for property, value in pairs(properties or {}) do
		if property == "Parent" then
			parent = value
		else
			instance[property] = value
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function AddCorner(instance, radius)
	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius or ELEMENT_RADIUS),
		Parent = instance,
	})
end

local function AddStroke(instance, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})
end

local function Tween(instance, properties, duration, style, direction)
	local info = TweenInfo.new(
		duration or ANIM_NORMAL,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	)
	local tweenObject = TweenService:Create(instance, info, properties)
	tweenObject:Play()
	return tweenObject
end

local function Round(value, decimals)
	local multiplier = 10 ^ (decimals or 0)
	return math.floor(value * multiplier + 0.5) / multiplier
end

local function GetGuiParent()
	if typeof(gethui) == "function" then
		local success, result = pcall(gethui)
		if success and result then
			return result
		end
	end
	if LOCAL_PLAYER then
		local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end
	return CoreGui
end

local function GetViewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(800, 600)
end

-- 判断输入类型是否可用于交互（鼠标或触摸）
local function IsInteractiveInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMovementInput(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

--================================================================================
-- [04] 主题系统
--================================================================================

local Snow = {}
Snow.Name    = LIBRARY_NAME
Snow.Version = LIBRARY_VERSION
Snow.__index = Snow

Snow.Themes = {
	Dark = {
		Background    = Color3.fromRGB(16, 18, 24),
		Surface       = Color3.fromRGB(23, 26, 34),
		SurfaceAlt    = Color3.fromRGB(32, 36, 46),
		SurfaceHover  = Color3.fromRGB(40, 45, 58),
		Border        = Color3.fromRGB(48, 54, 68),

		Accent        = Color3.fromRGB(110, 175, 255),
		AccentHover   = Color3.fromRGB(140, 195, 255),
		AccentPressed = Color3.fromRGB(80, 140, 220),

		Text          = Color3.fromRGB(232, 238, 248),
		TextMuted     = Color3.fromRGB(138, 148, 168),
		TextDisabled  = Color3.fromRGB(88, 96, 114),

		Danger        = Color3.fromRGB(232, 88, 98),
		Success       = Color3.fromRGB(104, 216, 156),
		Warning       = Color3.fromRGB(240, 188, 96),
	},
	Light = {
		Background    = Color3.fromRGB(240, 243, 249),
		Surface       = Color3.fromRGB(255, 255, 255),
		SurfaceAlt    = Color3.fromRGB(244, 247, 252),
		SurfaceHover  = Color3.fromRGB(230, 236, 246),
		Border        = Color3.fromRGB(212, 219, 233),

		Accent        = Color3.fromRGB(56, 126, 226),
		AccentHover   = Color3.fromRGB(80, 148, 240),
		AccentPressed = Color3.fromRGB(38, 100, 190),

		Text          = Color3.fromRGB(24, 28, 38),
		TextMuted     = Color3.fromRGB(108, 118, 138),
		TextDisabled  = Color3.fromRGB(168, 176, 190),

		Danger        = Color3.fromRGB(214, 62, 74),
		Success       = Color3.fromRGB(38, 170, 110),
		Warning       = Color3.fromRGB(214, 152, 40),
	},
}

--================================================================================
-- [05] 通知系统
--================================================================================

local NotificationModule = {
	Gui = nil,
	Container = nil,
	Active = {},
}

function NotificationModule:Init()
	if self.Gui and self.Gui.Parent then
		return
	end

	self.Gui = Create("ScreenGui", {
		Name = "SnowNotifications",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
	})
	self.Gui.Parent = GetGuiParent()

	-- 手机端收窄
	local viewport = GetViewportSize()
	local width = math.min(300, viewport.X - 40)

	self.Container = Create("Frame", {
		Name = "Container",
		Parent = self.Gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, width, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	Create("UIListLayout", {
		Parent = self.Container,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function NotificationModule:Push(config)
	self:Init()

	local theme = Snow.Themes.Dark
	local title = config.Title or "通知"
	local content = config.Content or ""
	local duration = config.Duration or 4
	local accent = config.Accent or theme.Accent

	local card = Create("Frame", {
		Parent = self.Container,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	AddCorner(card, 8)

	local stroke = AddStroke(card, theme.Border, 1, 1)

	local accentBar = Create("Frame", {
		Parent = card,
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundTransparency = 1,
	})
	AddCorner(accentBar, 2)

	local titleLabel = Create("TextLabel", {
		Parent = card,
		BackgroundTransparency = 1,
		Text = title,
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -28, 0, 18),
		TextTransparency = 1,
	})

	local contentLabel = Create("TextLabel", {
		Parent = card,
		BackgroundTransparency = 1,
		Text = content,
		Font = FONT,
		TextSize = 12,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.new(0, 16, 0, 30),
		Size = UDim2.new(1, -28, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextTransparency = 1,
	})

	Create("UIPadding", {
		Parent = card,
		PaddingBottom = UDim.new(0, 12),
	})

	Tween(card, { BackgroundTransparency = 0 }, ANIM_NORMAL)
	Tween(accentBar, { BackgroundTransparency = 0 }, ANIM_NORMAL)
	Tween(stroke, { Transparency = 0 }, ANIM_NORMAL)
	Tween(titleLabel, { TextTransparency = 0 }, ANIM_NORMAL)
	Tween(contentLabel, { TextTransparency = 0 }, ANIM_NORMAL)

	table.insert(self.Active, card)

	task.delay(duration, function()
		if not card.Parent then
			return
		end
		Tween(card, { BackgroundTransparency = 1 }, ANIM_SLOW)
		Tween(accentBar, { BackgroundTransparency = 1 }, ANIM_SLOW)
		Tween(stroke, { Transparency = 1 }, ANIM_SLOW)
		Tween(titleLabel, { TextTransparency = 1 }, ANIM_SLOW)
		Tween(contentLabel, { TextTransparency = 1 }, ANIM_SLOW)
		task.wait(ANIM_SLOW + 0.05)
		card:Destroy()
	end)

	return card
end

--================================================================================
-- [05.5] 类前向声明（必须在 Window 之前）
--================================================================================

local Tab = {}
local Section = {}

--================================================================================
-- [06] Window 类
--================================================================================

local Window = {}
Window.__index = Window

function Window.new(library, config)
	config = config or {}

	local themeName = config.Theme or "Dark"
	local theme = library.Themes[themeName] or library.Themes.Dark

	local self = setmetatable({
		Library      = library,
		Title        = config.Title or "Snow",
		Subtitle     = config.Subtitle or ("v" .. LIBRARY_VERSION),
		ThemeName    = themeName,
		Theme        = theme,

		Size         = config.Size,
		ToggleKey    = config.ToggleKey or Enum.KeyCode.RightShift,
		CloseCallback = config.CloseCallback,

		Tabs         = {},
		Flags        = {},
		ActiveTab    = nil,

		_connections = {},
		_dragging    = false,
		_minimized   = false,
		_destroyed   = false,
		_isMobile    = IS_MOBILE,
	}, Window)

	self:_calculateSize()
	self:_buildGui()
	self:_bindDragging()
	self:_bindToggleKey()

	return self
end

-- 根据屏幕自动计算窗口尺寸（移动端适配关键）
function Window:_calculateSize()
	local viewport = GetViewportSize()

	if self.Size then
		-- 用户指定了尺寸，但仍要保证不溢出屏幕
		local sizeX = math.min(self.Size.X.Offset, viewport.X - 20)
		local sizeY = math.min(self.Size.Y.Offset, viewport.Y - 20)
		self._finalSize = UDim2.fromOffset(sizeX, sizeY)
		return
	end

	if self._isMobile then
		-- 移动端：占屏幕 92% 宽、72% 高
		local width  = math.clamp(viewport.X * 0.92, 260, 560)
		local height = math.clamp(viewport.Y * 0.72, 340, 520)
		self._finalSize = UDim2.fromOffset(width, height)
	else
		-- PC：根据屏幕大小自适应
		local width  = math.clamp(viewport.X * 0.42, 520, 720)
		local height = math.clamp(viewport.Y * 0.62, 380, 520)
		self._finalSize = UDim2.fromOffset(width, height)
	end
end

function Window:_buildGui()
	local theme = self.Theme

	self.ScreenGui = Create("ScreenGui", {
		Name = "SnowUI_" .. LIBRARY_VERSION,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	self.ScreenGui.Parent = GetGuiParent()

	-- // 主窗口
	self.Root = Create("Frame", {
		Name = "Window",
		Parent = self.ScreenGui,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = self._finalSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Active = true,
	})

	AddCorner(self.Root, WINDOW_RADIUS)
	AddStroke(self.Root, theme.Border, 1)

	-- 移动端标题栏稍高，方便手指触摸
	local titleBarHeight = self._isMobile and 52 or 46
	local sidebarWidth   = self._isMobile and 110 or 150

	-- // 标题栏
	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Parent = self.Root,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, titleBarHeight),
		Position = UDim2.new(0, 0, 0, 0),
		Active = true,
	})
	self.TitleBar = titleBar

	Create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Text = self.Title,
		Font = FONT_BOLD,
		TextSize = self._isMobile and 16 or 15,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, self._isMobile and 8 or 7),
		Size = UDim2.new(1, -120, 0, 18),
	})

	Create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Text = self.Subtitle,
		Font = FONT,
		TextSize = 11,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, self._isMobile and 28 or 25),
		Size = UDim2.new(1, -120, 0, 14),
	})

	-- // 窗口按钮
	local btnSize = self._isMobile and 32 or 26

	local function makeWindowButton(symbol, offsetX, hoverColor, callback)
		local button = Create("TextButton", {
			Parent = titleBar,
			BackgroundColor3 = theme.SurfaceAlt,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = symbol,
			Font = FONT_BOLD,
			TextSize = 13,
			TextColor3 = theme.TextMuted,
			AutoButtonColor = false,
			Size = UDim2.new(0, btnSize, 0, btnSize),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
		})
		AddCorner(button, 6)

		button.MouseEnter:Connect(function()
			Tween(button, {
				BackgroundTransparency = 0,
				BackgroundColor3 = hoverColor,
				TextColor3 = Color3.new(1, 1, 1),
			}, ANIM_FAST)
		end)

		button.MouseLeave:Connect(function()
			Tween(button, {
				BackgroundTransparency = 1,
				TextColor3 = theme.TextMuted,
			}, ANIM_FAST)
		end)

		button.MouseButton1Click:Connect(function()
			callback()
		end)

		return button
	end

	makeWindowButton("✕", -14, theme.Danger, function()
		self:Destroy()
		if self.CloseCallback then
			task.spawn(self.CloseCallback)
		end
	end)

	makeWindowButton("－", -(btnSize + 8), theme.SurfaceHover, function()
		self:Toggle()
	end)

	-- // 侧边栏
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = self.Root,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(0, sidebarWidth, 1, -titleBarHeight),
		Position = UDim2.new(0, 0, 0, titleBarHeight),
	})
	self.Sidebar = sidebar

	self.TabList = Create("ScrollingFrame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 1, -16),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
	})

	Create("UIListLayout", {
		Parent = self.TabList,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create("UIPadding", {
		Parent = self.TabList,
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	-- // 内容区
	self.Content = Create("Frame", {
		Name = "Content",
		Parent = self.Root,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -sidebarWidth, 1, -titleBarHeight),
		Position = UDim2.new(0, sidebarWidth, 0, titleBarHeight),
	})

	-- // 浮动雪花按钮（用于恢复窗口）
	self.FloatButton = Create("TextButton", {
		Parent = self.ScreenGui,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Text = "❄",
		Font = FONT_BOLD,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Size = UDim2.new(0, 52, 0, 52),
		Position = UDim2.new(0, 20, 0.5, -26),
		Visible = false,
	})
	AddCorner(self.FloatButton, 26)

	self.FloatButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	self.FloatButton.MouseEnter:Connect(function()
		Tween(self.FloatButton, { BackgroundColor3 = theme.AccentHover }, ANIM_FAST)
	end)
	self.FloatButton.MouseLeave:Connect(function()
		Tween(self.FloatButton, { BackgroundColor3 = theme.Accent }, ANIM_FAST)
	end)
end

-- 拖拽：鼠标 + 触摸 双兼容（重写版）
function Window:_bindDragging()
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil

	local function updateDrag(input)
		local delta = input.Position - dragStart

		-- 边界限制：不能完全拖出屏幕
		local viewport = GetViewportSize()
		local windowSize = self.Root.AbsoluteSize

		local newX = startPosition.X.Offset + delta.X
		local newY = startPosition.Y.Offset + delta.Y

		local minX = -(windowSize.X / 2) + 40
		local maxX = viewport.X - (windowSize.X / 2) - 40
		local minY = -(windowSize.Y / 2) + 20
		local maxY = viewport.Y - (windowSize.Y / 2) - 20

		newX = math.clamp(newX, minX, maxX)
		newY = math.clamp(newY, minY, maxY)

		self.Root.Position = UDim2.new(
			startPosition.X.Scale, newX,
			startPosition.Y.Scale, newY
		)
	end

	self.TitleBar.InputBegan:Connect(function(input)
		if not IsInteractiveInput(input) then
			return
		end

		dragging = true
		dragInput = input
		dragStart = input.Position
		startPosition = self.Root.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
			end
		end)
	end)

	self.TitleBar.InputChanged:Connect(function(input)
		if IsMovementInput(input) then
			dragInput = input
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if not IsMovementInput(input) then return end
		if input ~= dragInput then return end
		updateDrag(input)
	end))
end

function Window:_bindToggleKey()
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if self.ToggleKey and input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))
end

function Window:Toggle()
	if self._destroyed then return end
	self._minimized = not self._minimized
	self.Root.Visible = not self._minimized
	self.FloatButton.Visible = self._minimized
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, connection in ipairs(self._connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self._connections = {}

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

function Window:CreateTab(config)
	config = type(config) == "string" and { Name = config } or (config or {})

	local theme = self.Theme
	local name = config.Name or "Tab"

	local tab = setmetatable({
		Name    = name,
		Window  = self,
		Library = self.Library,
		Theme   = theme,
		Pages   = {},
	}, Tab)

	local button = Create("TextButton", {
		Parent = self.TabList,
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, self._isMobile and 36 or 32),
		LayoutOrder = #self.Tabs + 1,
	})
	AddCorner(button, ELEMENT_RADIUS)

	local indicator = Create("Frame", {
		Parent = button,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	AddCorner(indicator, 2)

	local label = Create("TextLabel", {
		Parent = button,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = self._isMobile and 14 or 13,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -18, 1, 0),
	})

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, {
				BackgroundTransparency = 0,
				BackgroundColor3 = theme.SurfaceAlt,
			}, ANIM_FAST)
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(button, { BackgroundTransparency = 1 }, ANIM_FAST)
		end
	end)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	local page = Create("ScrollingFrame", {
		Parent = self.Content,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Border,
		ScrollBarImageTransparency = 0.3,
		Visible = false,
		BorderSizePixel = 0,
	})

	Create("UIListLayout", {
		Parent = page,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create("UIPadding", {
		Parent = page,
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	})

	tab.Button    = button
	tab.Indicator = indicator
	tab.Label     = label
	tab.Page      = page

	table.insert(self.Tabs, tab)

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	if not tab or self.ActiveTab == tab then return end

	local theme = self.Theme

	if self.ActiveTab then
		local old = self.ActiveTab
		Tween(old.Button, { BackgroundTransparency = 1 }, ANIM_FAST)
		Tween(old.Label, { TextColor3 = theme.TextMuted }, ANIM_FAST)
		Tween(old.Indicator, { Size = UDim2.new(0, 3, 0, 0) }, ANIM_NORMAL)
		old.Page.Visible = false
	end

	self.ActiveTab = tab

	Tween(tab.Button, {
		BackgroundTransparency = 0,
		BackgroundColor3 = theme.SurfaceAlt,
	}, ANIM_FAST)
	Tween(tab.Label, { TextColor3 = theme.Text }, ANIM_FAST)
	Tween(tab.Indicator, { Size = UDim2.new(0, 3, 0, 18) }, ANIM_NORMAL)

	tab.Page.Visible = true
end

function Window:GetFlag(flag)
	return self.Flags[flag]
end

function Window:SetFlag(flag, value)
	self.Flags[flag] = value
end

--================================================================================
-- [07] Tab 类
--================================================================================

Tab.__index = Tab

function Tab:CreateSection(name)
	name = name or "Section"

	local theme = self.Theme

	local section = setmetatable({
		Name    = name,
		Tab     = self,
		Window  = self.Window,
		Library = self.Library,
		Theme   = theme,
		_order  = 0,
	}, Section)

	local container = Create("Frame", {
		Parent = self.Page,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 0,
	})

	Create("UIListLayout", {
		Parent = container,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local header = Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Text = string.upper(name),
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 0,
	})

	local body = Create("Frame", {
		Parent = container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})

	Create("UIListLayout", {
		Parent = body,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	section.Container = container
	section.Header    = header
	section.Body      = body

	return section
end

--================================================================================
-- [08] Section 类
--================================================================================

Section.__index = Section

function Section:_nextOrder()
	self._order = self._order + 1
	return self._order
end

function Section:_createRow(height, order)
	return Create("Frame", {
		Parent = self.Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or ROW_HEIGHT),
		LayoutOrder = order or self:_nextOrder(),
	})
end

-- 按钮
function Section:CreateButton(config)
	config = config or {}
	local theme = self.Theme
	local text = config.Name or "Button"

	local button = Create("TextButton", {
		Parent = self.Body,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Text = text,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = self:_nextOrder(),
		Active = true,
	})
	AddCorner(button, ELEMENT_RADIUS)

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)
	button.MouseButton1Down:Connect(function()
		Tween(button, { BackgroundColor3 = theme.AccentPressed }, ANIM_FAST)
	end)
	button.MouseButton1Up:Connect(function()
		Tween(button, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	button.MouseButton1Click:Connect(function()
		if config.Callback then
			task.spawn(config.Callback)
		end
	end)

	local api = {}
	function api:SetText(value) button.Text = tostring(value) end
	function api:SetEnabled(state)
		button.Active = state and true or false
		button.TextColor3 = state and theme.Text or theme.TextDisabled
	end
	api.Instance = button
	return api
end

-- 开关
function Section:CreateToggle(config)
	config = config or {}
	local theme = self.Theme
	local window = self.Window
	local name = config.Name or "Toggle"
	local flag = config.Flag
	local value = config.Default and true or false

	local row = self:_createRow(ROW_HEIGHT)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -60, 1, 0),
		ZIndex = 2,
	})

	local switch = Create("Frame", {
		Parent = row,
		BackgroundColor3 = value and theme.Accent or theme.SurfaceAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 40, 0, 22),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = 2,
	})
	AddCorner(switch, 11)

	local knob = Create("Frame", {
		Parent = switch,
		BackgroundColor3 = value and Color3.new(1, 1, 1) or theme.TextDisabled,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 16, 0, 16),
		Position = value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	AddCorner(knob, 8)

	local hitbox = Create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 3,
		Active = true,
	})

	local function setValue(newValue, fireCallback)
		newValue = newValue and true or false
		value = newValue

		Tween(switch, {
			BackgroundColor3 = value and theme.Accent or theme.SurfaceAlt,
		}, ANIM_NORMAL)
		Tween(knob, {
			Position = value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = value and Color3.new(1, 1, 1) or theme.TextDisabled,
		}, ANIM_NORMAL, Enum.EasingStyle.Back)

		if flag then window.Flags[flag] = value end
		if fireCallback and config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	hitbox.MouseButton1Click:Connect(function()
		setValue(not value, true)
	end)
	hitbox.MouseEnter:Connect(function()
		if not value then
			Tween(switch, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
		end
	end)
	hitbox.MouseLeave:Connect(function()
		if not value then
			Tween(switch, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
		end
	end)

	if flag then window.Flags[flag] = value end

	local api = {}
	function api:Set(v, fire) setValue(v, fire) end
	function api:Get() return value end
	api.Instance = row
	return api
end

-- 滑块
function Section:CreateSlider(config)
	config = config or {}
	local theme = self.Theme
	local window = self.Window

	local name     = config.Name or "Slider"
	local flag     = config.Flag
	local min      = config.Min or 0
	local max      = config.Max or 100
	local decimals = config.Decimals or 0
	local suffix   = config.Suffix or ""
	local prefix   = config.Prefix or ""

	if max <= min then max = min + 1 end

	local value = math.clamp(config.Default or min, min, max)

	local row = self:_createRow(48)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -80, 0, 18),
	})

	local valueLabel = Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = prefix .. tostring(Round(value, decimals)) .. suffix,
		Font = FONT,
		TextSize = 13,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -80, 0, 0),
		Size = UDim2.new(0, 80, 0, 18),
	})

	-- 加大触摸热区高度
	local trackArea = Create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.new(0, 0, 0, 24),
		Size = UDim2.new(1, 0, 0, 20),
		Active = true,
	})

	local track = Create("Frame", {
		Parent = trackArea,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, 6),
	})
	AddCorner(track, 3)

	local fill = Create("Frame", {
		Parent = track,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
	})
	AddCorner(fill, 3)

	local dragging = false

	local function updateFromX(x)
		local relative = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		relative = math.clamp(relative, 0, 1)

		local newValue = Round(min + (max - min) * relative, decimals)
		newValue = math.clamp(newValue, min, max)

		if newValue == value then return end
		value = newValue

		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLabel.Text = prefix .. tostring(Round(value, decimals)) .. suffix

		if flag then window.Flags[flag] = value end
		if config.Callback then task.spawn(config.Callback, value) end
	end

	local function setValue(newValue, fireCallback)
		newValue = Round(math.clamp(newValue, min, max), decimals)
		value = newValue

		local alpha = (value - min) / (max - min)
		Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, ANIM_FAST)
		valueLabel.Text = prefix .. tostring(Round(value, decimals)) .. suffix

		if flag then window.Flags[flag] = value end
		if fireCallback and config.Callback then task.spawn(config.Callback, value) end
	end

	trackArea.InputBegan:Connect(function(input)
		if not IsInteractiveInput(input) then return end

		dragging = true
		updateFromX(input.Position.X)

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	trackArea.InputChanged:Connect(function(input)
		if dragging and IsMovementInput(input) then
			updateFromX(input.Position.X)
		end
	end)

	trackArea.MouseEnter:Connect(function()
		Tween(track, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	trackArea.MouseLeave:Connect(function()
		Tween(track, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)

	local initialAlpha = (value - min) / (max - min)
	fill.Size = UDim2.new(initialAlpha, 0, 1, 0)

	if flag then window.Flags[flag] = value end

	local api = {}
	function api:Set(v, fire) setValue(v, fire) end
	function api:Get() return value end
	api.Instance = row
	return api
end

-- 输入框
function Section:CreateInput(config)
	config = config or {}
	local theme = self.Theme
	local window = self.Window

	local name = config.Name or "Input"
	local placeholder = config.Placeholder or "请输入..."
	local flag = config.Flag
	local default = config.Default or ""

	local row = self:_createRow(ROW_HEIGHT)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -160, 1, 0),
	})

	local box = Create("TextBox", {
		Parent = row,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Text = default,
		PlaceholderText = placeholder,
		PlaceholderColor3 = theme.TextDisabled,
		Font = FONT,
		TextSize = 13,
		TextColor3 = theme.Text,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 150, 0, 28),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Active = true,
	})
	AddCorner(box, ELEMENT_RADIUS)

	Create("UIPadding", {
		Parent = box,
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local stroke = AddStroke(box, theme.Border, 1)

	box.Focused:Connect(function()
		Tween(stroke, { Color = theme.Accent }, ANIM_FAST)
		Tween(box, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	box.FocusLost:Connect(function(enterPressed)
		Tween(stroke, { Color = theme.Border }, ANIM_FAST)
		Tween(box, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)

		if flag then window.Flags[flag] = box.Text end
		if config.Callback then task.spawn(config.Callback, box.Text, enterPressed) end
	end)

	if flag then window.Flags[flag] = default end

	local api = {}
	function api:Set(v) box.Text = tostring(v); if flag then window.Flags[flag] = box.Text end end
	function api:Get() return box.Text end
	api.Instance = box
	return api
end

-- 下拉框
function Section:CreateDropdown(config)
	config = config or {}
	local theme = self.Theme
	local window = self.Window

	local name = config.Name or "Dropdown"
	local options = config.Options or {}
	local flag = config.Flag

	local current = config.Default
	if current == nil and #options > 0 then current = options[1] end

	local row = Create("Frame", {
		Parent = self.Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = self:_nextOrder(),
	})

	local header = Create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		Active = true,
	})

	Create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -160, 1, 0),
	})

	local valueBox = Create("Frame", {
		Parent = header,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 150, 0, 28),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	AddCorner(valueBox, ELEMENT_RADIUS)

	local valueLabel = Create("TextLabel", {
		Parent = valueBox,
		BackgroundTransparency = 1,
		Text = current and tostring(current) or "选择...",
		Font = FONT,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -34, 1, 0),
	})

	local arrow = Create("TextLabel", {
		Parent = valueBox,
		BackgroundTransparency = 1,
		Text = "▼",
		Font = FONT,
		TextSize = 10,
		TextColor3 = theme.TextMuted,
		Position = UDim2.new(1, -24, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
	})

	local list = Create("ScrollingFrame", {
		Parent = row,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, ROW_HEIGHT + 4),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Border,
		ScrollBarImageTransparency = 0.3,
		ZIndex = 5,
	})
	AddCorner(list, ELEMENT_RADIUS)

	Create("UIListLayout", {
		Parent = list,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create("UIPadding", {
		Parent = list,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})

	local open = false
	local optionButtons = {}

	local function closeList()
		open = false
		list.Visible = false
		list.Size = UDim2.new(1, 0, 0, 0)
		row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
		arrow.Text = "▼"
	end

	local function selectOption(option)
		current = option
		valueLabel.Text = tostring(option)
		if flag then window.Flags[flag] = option end
		if config.Callback then task.spawn(config.Callback, option) end
		closeList()
	end

	local function buildOption(option, index)
		local optionButton = Create("TextButton", {
			Parent = list,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = tostring(option),
			Font = FONT,
			TextSize = 13,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = index,
			Active = true,
		})
		AddCorner(optionButton, 4)

		Create("UIPadding", {
			Parent = optionButton,
			PaddingLeft = UDim.new(0, 8),
		})

		optionButton.MouseEnter:Connect(function()
			Tween(optionButton, {
				BackgroundTransparency = 0,
				BackgroundColor3 = theme.SurfaceAlt,
			}, ANIM_FAST)
		end)
		optionButton.MouseLeave:Connect(function()
			Tween(optionButton, { BackgroundTransparency = 1 }, ANIM_FAST)
		end)
		optionButton.MouseButton1Click:Connect(function()
			selectOption(option)
		end)

		return optionButton
	end

	for index, option in ipairs(options) do
		optionButtons[index] = buildOption(option, index)
	end

	local function toggleList()
		open = not open
		if open then
			local listHeight = math.min(#options * 30 + 8, 180)
			list.Visible = true
			list.Size = UDim2.new(1, 0, 0, listHeight)
			row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + listHeight + 6)
			arrow.Text = "▲"
		else
			closeList()
		end
	end

	header.MouseButton1Click:Connect(toggleList)
	header.MouseEnter:Connect(function()
		Tween(valueBox, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	header.MouseLeave:Connect(function()
		Tween(valueBox, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)

	if flag then window.Flags[flag] = current end

	local api = {}
	function api:Set(option)
		if table.find(options, option) then
			current = option
			valueLabel.Text = tostring(option)
			if flag then window.Flags[flag] = option end
		end
	end
	function api:Get() return current end
	function api:Refresh(newOptions)
		options = newOptions or {}
		for _, button in ipairs(optionButtons) do
			button:Destroy()
		end
		optionButtons = {}
		for index, option in ipairs(options) do
			optionButtons[index] = buildOption(option, index)
		end
	end
	api.Instance = row
	return api
end

-- 按键绑定
function Section:CreateKeybind(config)
	config = config or {}
	local theme = self.Theme
	local window = self.Window

	local name = config.Name or "Keybind"
	local flag = config.Flag
	local current = config.Default or Enum.KeyCode.E

	local row = self:_createRow(ROW_HEIGHT)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -120, 1, 0),
	})

	local keyButton = Create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Text = current and current.Name or "None",
		Font = FONT,
		TextSize = 12,
		TextColor3 = theme.Text,
		AutoButtonColor = false,
		Size = UDim2.new(0, 100, 0, 28),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Active = true,
	})
	AddCorner(keyButton, ELEMENT_RADIUS)

	local listening = false

	keyButton.MouseEnter:Connect(function()
		Tween(keyButton, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)
	keyButton.MouseLeave:Connect(function()
		Tween(keyButton, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)
	keyButton.MouseButton1Click:Connect(function()
		listening = true
		keyButton.Text = "..."
		keyButton.TextColor3 = theme.Accent
	end)

	table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		if listening then
			if input.KeyCode == Enum.KeyCode.Escape then
				-- 取消
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				current = nil
			else
				current = input.KeyCode
			end

			listening = false
			keyButton.Text = current and current.Name or "None"
			keyButton.TextColor3 = theme.Text

			if flag then window.Flags[flag] = current end
			if config.ChangedCallback then task.spawn(config.ChangedCallback, current) end
			return
		end

		if processed then return end

		if current and input.KeyCode == current then
			if config.Callback then task.spawn(config.Callback, current) end
		end
	end))

	if flag then window.Flags[flag] = current end

	local api = {}
	function api:Set(keyCode)
		current = keyCode
		keyButton.Text = keyCode and keyCode.Name or "None"
		if flag then window.Flags[flag] = current end
	end
	function api:Get() return current end
	api.Instance = keyButton
	return api
end

-- 文本标签
function Section:CreateLabel(text, config)
	config = config or {}
	local theme = self.Theme

	local label = Create("TextLabel", {
		Parent = self.Body,
		BackgroundTransparency = 1,
		Text = tostring(text or ""),
		Font = FONT,
		TextSize = config.Size or 13,
		TextColor3 = config.Color or theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = config.Wrapped or false,
		Size = UDim2.new(1, 0, 0, config.Height or 18),
		LayoutOrder = self:_nextOrder(),
	})

	if config.Wrapped then
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.new(1, 0, 0, 0)
	end

	local api = {}
	function api:SetText(value) label.Text = tostring(value) end
	function api:SetColor(color) label.TextColor3 = color end
	api.Instance = label
	return api
end

-- 段落
function Section:CreateParagraph(config)
	config = config or {}
	local theme = self.Theme

	local title = config.Title or "标题"
	local content = config.Text or ""

	local container = Create("Frame", {
		Parent = self.Body,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_nextOrder(),
	})
	AddCorner(container, ELEMENT_RADIUS)

	Create("UIPadding", {
		Parent = container,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	})

	Create("UIListLayout", {
		Parent = container,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleLabel = Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Text = title,
		Font = FONT_BOLD,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
	})

	local contentLabel = Create("TextLabel", {
		Parent = container,
		BackgroundTransparency = 1,
		Text = content,
		Font = FONT,
		TextSize = 12,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	local api = {}
	function api:SetTitle(value) titleLabel.Text = tostring(value) end
	function api:SetText(value) contentLabel.Text = tostring(value) end
	api.Instance = container
	return api
end

-- 分割线
function Section:CreateDivider()
	local theme = self.Theme
	local divider = Create("Frame", {
		Parent = self.Body,
		BackgroundColor3 = theme.Border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = self:_nextOrder(),
	})
	local api = {}
	api.Instance = divider
	return api
end

--================================================================================
-- [09] 库入口
--================================================================================

function Snow:CreateWindow(config)
	return Window.new(self, config)
end

function Snow:Notify(config)
	return NotificationModule:Push(config or {})
end

function Snow:GetTheme(name)
	return self.Themes[name]
end

function Snow:RegisterTheme(name, themeTable)
	assert(type(name) == "string", "主题名称必须是字符串")
	assert(type(themeTable) == "table", "主题内容必须是 table")
	self.Themes[name] = themeTable
	return true
end

function Snow:IsMobile()
	return IS_MOBILE
end

return Snow