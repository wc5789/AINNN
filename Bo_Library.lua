local Bo = {}
Bo.__index = Bo

--// 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// 主题配置（关键 UI 属性）
Bo.Theme = {
	Background    = Color3.fromRGB(25, 25, 25),
	BackgroundAlt = Color3.fromRGB(20, 20, 20),
	Element       = Color3.fromRGB(25, 25, 25),
	Accent        = Color3.fromRGB(85, 255, 127),
	Text          = Color3.fromRGB(255, 255, 255),
	Font          = Enum.Font.Gotham,
	FontBold      = Enum.Font.GothamBold,
	Padding       = 5,
	ButtonHeight  = 34,
}

--// 工具函数
local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function AddListLayout(parent)
	Create("UIListLayout", {
		Name = "Layout",
		Parent = parent,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Bo.Theme.Padding),
	})
end

--// 拖动支持（保留自原版）
local function MakeDraggable(frame)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(frame, TweenInfo.new(0.25), { Position = pos }):Play()
	end

	frame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch)
			and UserInputService:GetFocusedTextBox() == nil then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

--========================================================
--  Tab（标签页对象）
--========================================================
local TabClass = {}
TabClass.__index = TabClass

function TabClass:CreateButton(config)
	config = config or {}
	local theme = Bo.Theme

	local btn = Create("TextButton", {
		Name = config.Name or "Button",
		Parent = self.Scroll,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight),
		AutoButtonColor = true,
		Font = theme.Font,
		Text = config.Name or "Button",
		TextColor3 = theme.Text,
		TextSize = 14,
	})

	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = theme.Accent }):Play()
		task.wait(0.15)
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = theme.Element }):Play()
		if typeof(config.Callback) == "function" then
			task.spawn(config.Callback)
		end
	end)

	return btn
end

function TabClass:CreateLabel(config)
	config = config or {}
	local theme = Bo.Theme

	local label = Create("TextLabel", {
		Name = config.Name or "Label",
		Parent = self.Scroll,
		BackgroundColor3 = theme.Element,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight),
		Font = theme.Font,
		Text = config.Text or config.Name or "Label",
		TextColor3 = theme.Text,
		TextSize = 14,
	})
	return label
end

--========================================================
--  Window（窗口对象）
--========================================================
local WindowClass = {}
WindowClass.__index = WindowClass

-- 内部：构建一个可滚动的标签内容区
local function BuildScrollPage(parent)
	local scroll = Create("ScrollingFrame", {
		Parent = parent,
		Active = true,
		BackgroundColor3 = Bo.Theme.BackgroundAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollingEnabled = true,
		Visible = false,
		BottomImage = "",
		TopImage = "",
	})
	AddListLayout(scroll)
	Create("UIPadding", {
		Parent = scroll,
		PaddingBottom = UDim.new(0, Bo.Theme.Padding),
		PaddingLeft = UDim.new(0, Bo.Theme.Padding),
		PaddingRight = UDim.new(0, Bo.Theme.Padding),
		PaddingTop = UDim.new(0, Bo.Theme.Padding),
	})

	-- 自动更新 CanvasSize 以适应内容
	local layout = scroll:FindFirstChildOfClass("UIListLayout")
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + Bo.Theme.Padding * 2)
	end)

	return scroll
end

function WindowClass:CreateTab(config)
	config = config or {}

	local tabBtn = Create("TextButton", {
		Name = config.Name or "Tab",
		Parent = self.TabButtons,
		BackgroundColor3 = self.Theme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 117, 0, 29),
		Font = self.Theme.FontBold,
		Text = config.Name or "Tab",
		TextColor3 = self.Theme.Text,
		TextSize = 14,
		LayoutOrder = #self.Tabs + 1,
	})

	local page = BuildScrollPage(self.TabsContainer)
	page.Visible = (#self.Tabs == 0) -- 第一个标签默认显示

	local tabObj = setmetatable({
		Name = config.Name or "Tab",
		Button = tabBtn,
		Scroll = page,
	}, TabClass)

	table.insert(self.Tabs, tabObj)

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tabObj)
	end)

	return tabObj
end

function WindowClass:SelectTab(target)
	for _, tab in ipairs(self.Tabs) do
		local active = (tab == target)
		tab.Scroll.Visible = active
		tab.Button.BackgroundTransparency = active and 0 or 1
		tab.Button.BackgroundColor3 = active and self.Theme.BackgroundAlt or self.Theme.Background
	end
end

--========================================================
--  Bo 入口
--========================================================
function Bo:CreateWindow(config)
	config = config or {}
	local theme = Bo.Theme

	-- 主 ScreenGui
	local gui = Create("ScreenGui", {
		Name = config.Name or "Bo_UI",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})

	local function mount(parent)
		gui.Parent = parent or game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	mount(config.Parent)

	-- 若在非游戏环境（Studio 命令行等）下找不到 PlayerGui，尝试 CoreGui
	if not gui.Parent then
		pcall(function() mount(game:GetService("CoreGui")) end)
	end

	-- 主框架
	local main = Create("Frame", {
		Name = "Main",
		Parent = gui,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = config.Position or UDim2.new(0.22, 0, 0.18, 0),
		Size = config.Size or UDim2.new(0, 581, 0, 333),
	})

	MakeDraggable(main)

	-- 标题栏
	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Parent = main,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, 40),
	})

	local title = Create("TextLabel", {
		Name = "Title",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, 136, 0, 40),
		Font = theme.FontBold,
		Text = config.Title or "Bo Hub",
		TextColor3 = theme.Text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- 左侧标签按钮列
	local tabButtons = Create("Frame", {
		Name = "TabButtons",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 117, 0, 291),
	})
	AddListLayout(tabButtons)

	-- 右侧标签内容容器
	local tabsContainer = Create("Frame", {
		Name = "TabsContainer",
		Parent = main,
		BackgroundColor3 = theme.BackgroundAlt,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 117, 0, 42),
		Size = UDim2.new(0, 464, 0, 291),
	})

	local window = setmetatable({
		GUI = gui,
		Main = main,
		Title = title,
		TabButtons = tabButtons,
		TabsContainer = tabsContainer,
		Tabs = {},
		Theme = theme,
	}, WindowClass)

	-- 关闭/显示切换（可选）
	function window:Toggle(visible)
		main.Visible = (visible ~= nil) and visible or not main.Visible
	end
	function window:Destroy()
		gui:Destroy()
	end

	return window
end

return Bo
