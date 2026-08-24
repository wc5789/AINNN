
local Bo = {}
Bo.__index = Bo

--// 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// 主题配置
Bo.Theme = {
	Background    = Color3.fromRGB(25, 25, 25),
	BackgroundAlt = Color3.fromRGB(20, 20, 20),
	Element       = Color3.fromRGB(25, 25, 25),
	ElementHover  = Color3.fromRGB(35, 35, 35),
	Accent        = Color3.fromRGB(85, 255, 127),
	Text          = Color3.fromRGB(255, 255, 255),
	Font          = Enum.Font.Gotham,
	FontBold      = Enum.Font.GothamBold,
	Padding       = 5,
	ButtonHeight  = 34,
}

--========================================================
--  工具函数
--========================================================
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

--[[
	流动渐变驱动器（核心修复点）
	旧版用 Tween.Completed:Wait() 循环，Completed 在某些情况不触发导致动画卡死；
	新版改用 RenderStepped 逐帧累加时间，数学上绝对连续，永不卡死。
]]
function Bo.CreateFlowGradient(inst, config)
	config = config or {}

	local gradient = Create("UIGradient", {
		Name = "FlowGradient",
		Parent = inst,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, config.ColorA or Color3.fromRGB(60, 60, 60)),
			ColorSequenceKeypoint.new(0.50, config.ColorB or Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1.00, config.ColorC or Color3.fromRGB(60, 60, 60)),
		}),
		Offset = -1,
	})

	local speed = config.Speed or 2     -- 扫过一次的秒数
	local pause = config.Pause or 0     -- 每次扫完后停顿秒数
	local loop  = config.Loop ~= false
	local clock = 0
	local conn

	conn = RunService.RenderStepped:Connect(function(dt)
		if not inst.Parent then
			conn:Disconnect()
			return
		end
		clock += dt
		local cycle = speed + pause
		if clock >= cycle then
			if loop then
				clock -= cycle
			else
				conn:Disconnect()
				return
			end
		end
		if clock <= speed then
			gradient.Offset = -1 + (clock / speed) * 2 -- -1 -> 1 线性扫描
		else
			gradient.Offset = 1                        -- 停顿期停在右侧外
		end
	end)

	return gradient, conn
end

--========================================================
--  拖动支持（鼠标 + 触摸通用）
--========================================================
local function MakeDraggable(frame)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

	local function update(input)
		local delta = input.Position - dragStart
		TweenService:Create(frame, TweenInfo.new(0.1), {
			Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			),
		}):Play()
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
--  灵动岛悬浮球（内置开关）
--  可拖动 / 按压放大松手回弹 / 点按切换窗口显隐
--========================================================
local function BuildIsland(window)
	local gui = Create("ScreenGui", {
		Name = "Bo_Island",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})
	pcall(function()
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end)

	-- holder 负责缩放动画，pill 负责点击/拖动
	local holder = Create("Frame", {
		Name = "Holder",
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.08, 0, 0.5, 0),
		Size = UDim2.new(0, 46, 0, 46),
	})

	local pill = Create("TextButton", {
		Name = "Pill",
		Parent = holder,
		BackgroundColor3 = Bo.Theme.Background,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })

	-- 描边 + 流光（作用于背景，产生呼吸微光）
	Create("UIStroke", {
		Name = "IslandStroke",
		Parent = pill,
		Color = Bo.Theme.Accent,
		Thickness = 1.5,
		Transparency = 0.35,
	})
	Bo.CreateFlowGradient(pill, {
		ColorA = Color3.fromRGB(30, 90, 50),
		ColorB = Bo.Theme.Accent,
		ColorC = Color3.fromRGB(30, 90, 50),
		Speed = 2.5,
		Pause = 1,
	})

	local label = Create("TextLabel", {
		Name = "Label",
		Parent = pill,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Bo.Theme.FontBold,
		Text = "Bo",
		TextColor3 = Bo.Theme.Text,
		TextSize = 16,
	})

	-- 状态机：区分"拖动"与"点击"
	local pressed, moved = false, false
	local pressStart, startPos

	pill.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			moved = false
			pressStart = input.Position
			startPos = holder.Position

			-- 灵动岛按压缩放手感
			TweenService:Create(holder,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 58, 0, 58) }):Play()

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					pressed = false
					-- Back 缓动回弹，Q弹高级
					TweenService:Create(holder,
						TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Size = UDim2.new(0, 46, 0, 46) }):Play()
					if not moved then
						window:Toggle()
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if pressed and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - pressStart
			if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then
				moved = true
			end
			holder.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	window.Island = { GUI = gui, Holder = holder, Pill = pill }
end

--========================================================
--  Tab 对象
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
		AutoButtonColor = false,
		Font = theme.Font,
		Text = config.Name or "Button",
		TextColor3 = theme.Text,
		TextSize = 14,
	})
	btn.ZIndex = 2

	-- 半透明柔光层（点击反馈）
	local flash = Create("Frame", {
		Name = "Flash",
		Parent = btn,
		BackgroundColor3 = theme.Text,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
	})

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = theme.ElementHover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = theme.Element }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		flash.BackgroundTransparency = 0.85 -- 低透明度起步，柔和不刺眼
		TweenService:Create(flash,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
		if typeof(config.Callback) == "function" then
			task.spawn(config.Callback)
		end
	end)

	return btn
end

function TabClass:CreateLabel(config)
	config = config or {}
	local theme = Bo.Theme

	return Create("TextLabel", {
		Name = config.Name or "Label",
		Parent = self.Scroll,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight),
		Font = theme.Font,
		Text = config.Text or config.Name or "Label",
		TextColor3 = theme.Text,
		TextSize = 14,
	})
end

--========================================================
--  Window 对象
--========================================================
local WindowClass = {}
WindowClass.__index = WindowClass

local function BuildScrollPage(parent)
	local scroll = Create("ScrollingFrame", {
		Parent = parent,
		Active = true,
		BackgroundColor3 = Bo.Theme.BackgroundAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
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

	local layout = scroll:FindFirstChildOfClass("UIListLayout")
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + Bo.Theme.Padding * 2)
	end)

	return scroll
end

function WindowClass:SelectTab(target)
	for _, tab in ipairs(self.Tabs) do
		local active = (tab == target)
		tab.Scroll.Visible = active
		tab.Button.BackgroundTransparency = active and 0 or 1
		tab.Button.BackgroundColor3 = active and self.Theme.BackgroundAlt or self.Theme.Background
	end
end

-- 退场动画：窗口分裂两半，左半向左滑走 / 右半向右滑走
function WindowClass:_PlayExitAnimation(callback)
	local main = self.Main
	if not main.Visible then
		if callback then callback() end
		return
	end

	local size = main.AbsoluteSize
	local pos = main.AbsolutePosition

	local left = Create("Frame", {
		Parent = self.GUI,
		BackgroundColor3 = main.BackgroundColor3,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(math.floor(size.X / 2), size.Y),
		ZIndex = 50,
	})
	local right = Create("Frame", {
		Parent = self.GUI,
		BackgroundColor3 = main.BackgroundColor3,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(pos.X + size.X - math.ceil(size.X / 2), pos.Y),
		Size = UDim2.fromOffset(math.ceil(size.X / 2), size.Y),
		ZIndex = 50,
	})

	main.Visible = false

	local dur = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	TweenService:Create(left, dur, { Position = left.Position - UDim2.fromOffset(size.X, 0) }):Play()
	local tw = TweenService:Create(right, dur, { Position = right.Position + UDim2.fromOffset(size.X, 0) })
	tw:Play()
	tw.Completed:Once(function()
		left:Destroy()
		right:Destroy()
		if callback then callback() end
	end)
end

function WindowClass:Show()
	self.Main.Visible = true
	self.IsOpen = true
end

function WindowClass:Hide(callback)
	if not self.IsOpen then return end
	self.IsOpen = false
	self:_PlayExitAnimation(callback)
end

function WindowClass:Toggle()
	if self.IsOpen then
		self:Hide()
	else
		self:Show()
	end
end

function WindowClass:Destroy()
	if self.Island and self.Island.GUI then
		self.Island.GUI:Destroy()
	end
	self.GUI:Destroy()
end

--========================================================
--  Bo 入口
--========================================================
function Bo:CreateWindow(config)
	config = config or {}
	local theme = Bo.Theme

	local gui = Create("ScreenGui", {
		Name = config.Name or "Bo_UI",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})
	gui.Parent = config.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")

	-- 主框架（入场直接切入）
	local main = Create("Frame", {
		Name = "Main",
		Parent = gui,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = config.Position or UDim2.new(0.22, 0, 0.18, 0),
		Size = config.Size or UDim2.new(0, 581, 0, 333),
	})

	MakeDraggable(main)

	-- 细描边 + 流动描边光（UIGradient 会同时作用于 UIStroke，形成流动描边光）
	Create("UIStroke", {
		Name = "MainStroke",
		Parent = main,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.4,
	})
	Bo.CreateFlowGradient(main, {
		ColorA = Color3.fromRGB(20, 70, 40),
		ColorB = theme.Accent,
		ColorC = Color3.fromRGB(20, 70, 40),
		Speed = 3,
		Pause = 1.2,
	})

	-- 标题栏分隔线流光
	local titleBar = Create("Frame", {
		Name = "TitleBar",
		Parent = main,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 0, 2),
	})
	Bo.CreateFlowGradient(titleBar, {
		ColorA = Color3.fromRGB(25, 80, 45),
		ColorB = Color3.fromRGB(255, 255, 255),
		ColorC = Color3.fromRGB(25, 80, 45),
		Speed = 2,
	})

	-- 标题
	local title = Create("TextLabel", {
		Name = "Title",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, 200, 0, 40),
		Font = theme.FontBold,
		Text = config.Title or "Bo Hub",
		TextColor3 = theme.Text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- 左侧标签列
	local tabButtons = Create("Frame", {
		Name = "TabButtons",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 117, 0, 291),
	})
	AddListLayout(tabButtons)

	-- 右侧内容容器
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
		TitleBar = titleBar,
		TabButtons = tabButtons,
		TabsContainer = tabsContainer,
		Tabs = {},
		Theme = theme,
		IsOpen = true,
	}, WindowClass)

	-- 灵动岛悬浮球（写死内置）
	BuildIsland(window)

	return window
end

return Bo