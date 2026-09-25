--[[
================================================================================
    ███████╗███╗   ██╗ ██████╗ ██╗    ██╗
    ██╔════╝████╗  ██║██╔═══██╗██║    ██║
    ███████╗██╔██╗ ██║██║   ██║██║ █╗ ██║
    ╚════██║██║╚██╗██║██║   ██║██║███╗██║
    ███████║██║ ╚████║╚██████╔╝╚███╔███╔╝
    ╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝

    Snow UI Library  |  雪花 UI 库
    --------------------------------------------------------------------------
    Version : 1.0.0
    Author  : Snow Development
    License : MIT
    --------------------------------------------------------------------------
    这是一个面向生产环境的 Roblox UI 库，提供完整的主题、动画、
    输入处理与组件体系。v1.0 版本包含最基础的核心控件集合。
================================================================================
]]

--================================================================================
-- [01] 服务引用
--================================================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LOCAL_PLAYER = Players.LocalPlayer

--================================================================================
-- [02] 常量定义
--================================================================================

local LIBRARY_NAME   = "Snow"
local LIBRARY_VERSION = "1.0.0"

local FONT       = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold

local ROW_HEIGHT   = 36
local WINDOW_RADIUS = 10
local ELEMENT_RADIUS = 6

local ANIM_FAST   = 0.12
local ANIM_NORMAL = 0.18
local ANIM_SLOW   = 0.28

--================================================================================
-- [03] 工具函数
--================================================================================

--- 创建一个 Instance 并批量赋值属性
-- @param className string
-- @param properties table?
-- @return Instance
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

--- 为实例添加 UICorner
local function AddCorner(instance, radius)
	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius or ELEMENT_RADIUS),
		Parent = instance,
	})
end

--- 为实例添加 UIStroke
local function AddStroke(instance, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})
end

--- 执行补间动画
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

--- 数值四舍五入
local function Round(value, decimals)
	local multiplier = 10 ^ (decimals or 0)
	return math.floor(value * multiplier + 0.5) / multiplier
end

--- 获取一个安全的 GUI 父容器
local function GetGuiParent()
	-- 优先使用执行器提供的 gethui（若存在）
	if typeof(gethui) == "function" then
		local success, result = pcall(gethui)
		if success and result then
			return result
		end
	end

	-- 其次使用 PlayerGui
	if LOCAL_PLAYER then
		local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end

	-- 兜底
	return CoreGui
end

--- 限制窗口位置，避免拖出屏幕
local function ClampToViewport(position, viewportSize, objectSize)
	local x = math.clamp(position.X.Offset, -objectSize.X + 80, viewportSize.X - 80)
	local y = math.clamp(position.Y.Offset, 0, viewportSize.Y - 40)
	return UDim2.new(position.X.Scale, x, position.Y.Scale, y)
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

--- 初始化通知容器
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

	self.Container = Create("Frame", {
		Name = "Container",
		Parent = self.Gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.new(0, 300, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	Create("UIListLayout", {
		Parent = self.Container,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

--- 推送一条通知
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

	-- 左侧强调条
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

	-- 淡入
	Tween(card, { BackgroundTransparency = 0 }, ANIM_NORMAL)
	Tween(accentBar, { BackgroundTransparency = 0 }, ANIM_NORMAL)
	Tween(stroke, { Transparency = 0 }, ANIM_NORMAL)
	Tween(titleLabel, { TextTransparency = 0 }, ANIM_NORMAL)
	Tween(contentLabel, { TextTransparency = 0 }, ANIM_NORMAL)

	table.insert(self.Active, card)

	-- 自动移除
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
-- [06] Window 类
--================================================================================

local Window = {}
Window.__index = Window

--- 创建一个新窗口（由 Snow:CreateWindow 调用）
function Window.new(library, config)
	config = config or {}

	local themeName = config.Theme or "Dark"
	local theme = library.Themes[themeName] or library.Themes.Dark

	local self = setmetatable({
		Library     = library,
		Title       = config.Title or "Snow",
		Subtitle    = config.Subtitle or ("v" .. LIBRARY_VERSION),
		ThemeName   = themeName,
		Theme       = theme,

		Size        = config.Size or UDim2.fromOffset(620, 430),
		ToggleKey   = config.ToggleKey or Enum.KeyCode.RightShift,
		CloseCallback = config.CloseCallback,

		Tabs        = {},
		Flags       = {},
		ActiveTab   = nil,

		_connections = {},
		_dragging    = false,
		_minimized   = false,
		_destroyed   = false,
	}, Window)

	self:_buildGui()
	self:_bindWindowControls()
	self:_bindDragging()
	self:_bindToggleKey()

	return self
end

--- 构建整个窗口 UI
function Window:_buildGui()
	local theme = self.Theme

	-- // ScreenGui
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
		Size = self.Size,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
	})

	AddCorner(self.Root, WINDOW_RADIUS)
	AddStroke(self.Root, theme.Border, 1)

	-- // 标题栏
	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Parent = self.Root,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.new(0, 0, 0, 0),
	})
	self.TitleBar = titleBar

	Create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Text = self.Title,
		Font = FONT_BOLD,
		TextSize = 15,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 7),
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
		Position = UDim2.new(0, 16, 0, 25),
		Size = UDim2.new(1, -120, 0, 14),
	})

	-- // 窗口按钮（关闭 / 最小化）
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
			Size = UDim2.new(0, 26, 0, 26),
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

	makeWindowButton("－", -46, theme.SurfaceHover, function()
		self:Toggle()
	end)

	-- // 侧边栏
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = self.Root,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 150, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
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
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	-- // 内容区
	self.Content = Create("Frame", {
		Name = "Content",
		Parent = self.Root,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -150, 1, -46),
		Position = UDim2.new(0, 150, 0, 46),
	})
end

--- 绑定窗口控制相关逻辑
function Window:_bindWindowControls()
	-- 预留：缩放、贴边等高级功能
end

--- 绑定标题栏拖拽
function Window:_bindDragging()
	local dragging = false
	local dragStart = nil
	local startPosition = nil

	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = self.Root.Position

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if connection then
					connection:Disconnect()
				end
			end
		end)
	end

	self.TitleBar.InputBegan:Connect(beginDrag)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart
		self.Root.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end))
end

--- 绑定快捷键显示/隐藏
function Window:_bindToggleKey()
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if self.ToggleKey and input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))
end

--- 显示 / 隐藏窗口
function Window:Toggle()
	if self._destroyed then
		return
	end

	self._minimized = not self._minimized
	self.Root.Visible = not self._minimized
end

--- 销毁窗口
function Window:Destroy()
	if self._destroyed then
		return
	end

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

--- 创建一个标签页
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

	-- // 标签按钮
	local button = Create("TextButton", {
		Parent = self.TabList,
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 32),
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
		TextSize = 13,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
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

	-- // 页面容器
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

	-- 第一个标签页自动选中
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

--- 选中指定标签页
function Window:SelectTab(tab)
	if not tab or self.ActiveTab == tab then
		return
	end

	local theme = self.Theme

	-- 取消旧标签
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

--- 读取 Flag 值
function Window:GetFlag(flag)
	return self.Flags[flag]
end

--- 设置 Flag 值（不会触发回调）
function Window:SetFlag(flag, value)
	self.Flags[flag] = value
end

--================================================================================
-- [07] Tab 类
--================================================================================

local Tab = {}
Tab.__index = Tab

--- 在标签页内创建一个分组
function Tab:CreateSection(name)
	name = name or "Section"

	local theme = self.Theme

	local section = setmetatable({
		Name    = name,
		Tab     = self,
		Window  = self.Window,
		Library = self.Library,
		Theme   = theme,
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
	section.Header = header
	section.Body = body
	section._order = 0

	return section
end

--================================================================================
-- [08] Section 类
--================================================================================

local Section = {}
Section.__index = Section

--- 内部：生成下一个 LayoutOrder
function Section:_nextOrder()
	self._order = self._order + 1
	return self._order
end

--- 内部：创建一个行容器
function Section:_createRow(height, order)
	return Create("Frame", {
		Parent = self.Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or ROW_HEIGHT),
		LayoutOrder = order or self:_nextOrder(),
	})
end

--------------------------------------------------------------------------------
-- 按钮
--------------------------------------------------------------------------------

function Section:CreateButton(config)
	config = config or {}

	local theme = self.Theme
	local window = self.Window

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

	function api:SetText(value)
		button.Text = tostring(value)
	end

	function api:SetEnabled(state)
		button.Active = state and true or false
		button.TextColor3 = state and theme.Text or theme.TextDisabled
	end

	api.Instance = button

	return api
end

--------------------------------------------------------------------------------
-- 开关
--------------------------------------------------------------------------------

function Section:CreateToggle(config)
	config = config or {}

	local theme = self.Theme
	local window = self.Window

	local name = config.Name or "Toggle"
	local flag = config.Flag
	local value = config.Default and true or false

	local row = self:_createRow(ROW_HEIGHT)

	local label = Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -60, 1, 0),
		ZIndex = 2,
	})

	-- 开关底座
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

	-- 滑块
	local knob = Create("Frame", {
		Parent = switch,
		BackgroundColor3 = value and Color3.new(1, 1, 1) or theme.TextDisabled,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 16, 0, 16),
		Position = value and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	AddCorner(knob, 8)

	-- 点击热区（覆盖整行）
	local hitbox = Create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 3,
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

		if flag then
			window.Flags[flag] = value
		end

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

	-- 初始化 Flag
	if flag then
		window.Flags[flag] = value
	end

	local api = {}

	function api:Set(value, fireCallback)
		setValue(value, fireCallback)
	end

	function api:Get()
		return value
	end

	api.Instance = row

	return api
end

--------------------------------------------------------------------------------
-- 滑块
--------------------------------------------------------------------------------

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

	if max <= min then
		max = min + 1
	end

	local value = config.Default or min
	value = math.clamp(value, min, max)

	local row = self:_createRow(46)

	local label = Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
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

	-- 交互区域（比视觉轨道更高，方便点击）
	local trackArea = Create("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 14),
	})

	-- 视觉轨道
	local track = Create("Frame", {
		Parent = trackArea,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, 6),
	})
	AddCorner(track, 3)

	-- 填充
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

		local newValue = min + (max - min) * relative
		newValue = Round(newValue, decimals)
		newValue = math.clamp(newValue, min, max)

		if newValue == value then
			return
		end

		value = newValue

		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLabel.Text = prefix .. tostring(Round(value, decimals)) .. suffix

		if flag then
			window.Flags[flag] = value
		end

		if config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	local function setValue(newValue, fireCallback)
		newValue = math.clamp(newValue, min, max)
		newValue = Round(newValue, decimals)

		value = newValue

		local alpha = (value - min) / (max - min)
		Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, ANIM_FAST)
		valueLabel.Text = prefix .. tostring(Round(value, decimals)) .. suffix

		if flag then
			window.Flags[flag] = value
		end

		if fireCallback and config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	trackArea.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		updateFromX(input.Position.X)

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if connection then
					connection:Disconnect()
				end
			end
		end)
	end)

	table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))

	trackArea.MouseEnter:Connect(function()
		Tween(track, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)

	trackArea.MouseLeave:Connect(function()
		Tween(track, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)

	-- 初始化显示
	local initialAlpha = (value - min) / (max - min)
	fill.Size = UDim2.new(initialAlpha, 0, 1, 0)

	if flag then
		window.Flags[flag] = value
	end

	local api = {}

	function api:Set(newValue, fireCallback)
		setValue(newValue, fireCallback)
	end

	function api:Get()
		return value
	end

	api.Instance = row

	return api
end

--------------------------------------------------------------------------------
-- 输入框
--------------------------------------------------------------------------------

function Section:CreateInput(config)
	config = config or {}

	local theme = self.Theme
	local window = self.Window

	local name        = config.Name or "Input"
	local placeholder = config.Placeholder or "请输入..."
	local flag        = config.Flag
	local default     = config.Default or ""

	local row = self:_createRow(ROW_HEIGHT)

	Create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
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

		if flag then
			window.Flags[flag] = box.Text
		end

		if config.Callback then
			task.spawn(config.Callback, box.Text, enterPressed)
		end
	end)

	if flag then
		window.Flags[flag] = default
	end

	local api = {}

	function api:Set(value)
		box.Text = tostring(value)
		if flag then
			window.Flags[flag] = box.Text
		end
	end

	function api:Get()
		return box.Text
	end

	api.Instance = box

	return api
end

--------------------------------------------------------------------------------
-- 下拉框
--------------------------------------------------------------------------------

function Section:CreateDropdown(config)
	config = config or {}

	local theme = self.Theme
	local window = self.Window

	local name    = config.Name or "Dropdown"
	local options = config.Options or {}
	local flag    = config.Flag

	local current = config.Default
	if current == nil and #options > 0 then
		current = options[1]
	end

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
	})

	Create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Text = name,
		Font = FONT,
		TextSize = 14,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
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

	for index, option in ipairs(options) do
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
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = index,
		})
		AddCorner(optionButton, 4)

		Create("UIPadding", {
			Parent = optionButton,
			PaddingLeft = UDim.new(0, 8),
		})

		optionButton.MouseEnter:Connect(function()
			Tween(optionButton, { BackgroundTransparency = 0, BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
		end)

		optionButton.MouseLeave:Connect(function()
			Tween(optionButton, { BackgroundTransparency = 1 }, ANIM_FAST)
		end)

		optionButton.MouseButton1Click:Connect(function()
			current = option
			valueLabel.Text = tostring(option)

			if flag then
				window.Flags[flag] = option
			end

			if config.Callback then
				task.spawn(config.Callback, option)
			end

			-- 关闭列表
			open = false
			list.Visible = false
			list.Size = UDim2.new(1, 0, 0, 0)
			row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
			arrow.Text = "▼"
		end)

		optionButtons[index] = optionButton
	end

	local function toggleList()
		open = not open

		if open then
			local listHeight = math.min(#options * 28 + 8, 180)
			list.Visible = true
			list.Size = UDim2.new(1, 0, 0, listHeight)
			row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + listHeight + 6)
			arrow.Text = "▲"
		else
			list.Visible = false
			list.Size = UDim2.new(1, 0, 0, 0)
			row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
			arrow.Text = "▼"
		end
	end

	header.MouseButton1Click:Connect(toggleList)

	header.MouseEnter:Connect(function()
		Tween(valueBox, { BackgroundColor3 = theme.SurfaceHover }, ANIM_FAST)
	end)

	header.MouseLeave:Connect(function()
		Tween(valueBox, { BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
	end)

	if flag then
		window.Flags[flag] = current
	end

	local api = {}

	function api:Set(option)
		if table.find(options, option) then
			current = option
			valueLabel.Text = tostring(option)
			if flag then
				window.Flags[flag] = option
			end
		end
	end

	function api:Get()
		return current
	end

	function api:Refresh(newOptions)
		options = newOptions or {}

		for _, button in ipairs(optionButtons) do
			button:Destroy()
		end
		optionButtons = {}

		for index, option in ipairs(options) do
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
				Size = UDim2.new(1, 0, 0, 26),
				LayoutOrder = index,
			})
			AddCorner(optionButton, 4)

			Create("UIPadding", {
				Parent = optionButton,
				PaddingLeft = UDim.new(0, 8),
			})

			optionButton.MouseEnter:Connect(function()
				Tween(optionButton, { BackgroundTransparency = 0, BackgroundColor3 = theme.SurfaceAlt }, ANIM_FAST)
			end)

			optionButton.MouseLeave:Connect(function()
				Tween(optionButton, { BackgroundTransparency = 1 }, ANIM_FAST)
			end)

			optionButton.MouseButton1Click:Connect(function()
				current = option
				valueLabel.Text = tostring(option)

				if flag then
					window.Flags[flag] = option
				end

				if config.Callback then
					task.spawn(config.Callback, option)
				end

				open = false
				list.Visible = false
				list.Size = UDim2.new(1, 0, 0, 0)
				row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
				arrow.Text = "▼"
			end)

			optionButtons[index] = optionButton
		end
	end

	api.Instance = row

	return api
end

--------------------------------------------------------------------------------
-- 按键绑定
--------------------------------------------------------------------------------

function Section:CreateKeybind(config)
	config = config or {}

	local theme = self.Theme
	local window = self.Window

	local name    = config.Name or "Keybind"
	local flag    = config.Flag
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
		Size = UDim2.new(1, -120, 1, 0),
	})

	local keyButton = Create("TextButton", {
		Parent = row,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Text = current.Name,
		Font = FONT,
		TextSize = 12,
		TextColor3 = theme.Text,
		AutoButtonColor = false,
		Size = UDim2.new(0, 100, 0, 28),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
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
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		-- 监听模式
		if listening then
			if input.KeyCode == Enum.KeyCode.Escape then
				-- 取消绑定，保留原按键
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				current = nil
			else
				current = input.KeyCode
			end

			listening = false
			keyButton.Text = current and current.Name or "None"
			keyButton.TextColor3 = theme.Text

			if flag then
				window.Flags[flag] = current
			end

			if config.ChangedCallback then
				task.spawn(config.ChangedCallback, current)
			end

			return
		end

		-- 触发模式
		if processed then
			return
		end

		if current and input.KeyCode == current then
			if config.Callback then
				task.spawn(config.Callback, current)
			end
		end
	end))

	if flag then
		window.Flags[flag] = current
	end

	local api = {}

	function api:Set(keyCode)
		current = keyCode
		keyButton.Text = keyCode and keyCode.Name or "None"

		if flag then
			window.Flags[flag] = current
		end
	end

	function api:Get()
		return current
	end

	api.Instance = keyButton

	return api
end

--------------------------------------------------------------------------------
-- 文本标签
--------------------------------------------------------------------------------

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

	function api:SetText(value)
		label.Text = tostring(value)
	end

	function api:SetColor(color)
		label.TextColor3 = color
	end

	api.Instance = label

	return api
end

--------------------------------------------------------------------------------
-- 段落
--------------------------------------------------------------------------------

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

	function api:SetTitle(value)
		titleLabel.Text = tostring(value)
	end

	function api:SetText(value)
		contentLabel.Text = tostring(value)
	end

	api.Instance = container

	return api
end

--------------------------------------------------------------------------------
-- 分割线
--------------------------------------------------------------------------------

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
-- [09] 库入口方法
--================================================================================

--- 创建窗口
function Snow:CreateWindow(config)
	return Window.new(self, config)
end

--- 发送通知
function Snow:Notify(config)
	return NotificationModule:Push(config or {})
end

--- 获取指定主题
function Snow:GetTheme(name)
	return self.Themes[name]
end

--- 注册自定义主题
function Snow:RegisterTheme(name, themeTable)
	assert(type(name) == "string", "主题名称必须是字符串")
	assert(type(themeTable) == "table", "主题内容必须是 table")

	self.Themes[name] = themeTable
	return true
end

--================================================================================
-- [10] 返回
--================================================================================

return Snow