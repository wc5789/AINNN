--[[
	Bo UI Library v3
	轻量级 Roblox UI 库（基于 Bozo Hub 原始布局重构）
	
	v3 更新:
	· [修复] 补回丢失的 WindowClass:CreateTab
	· [修复] UIGradient.Offset 必须为 Vector2
	· [新增] 入场动画：从中心弹出（Quint 缓动）
	· [重做] 退场动画：克隆原窗口本体，撕成两半向左右滑走
	· [重做] 灵动岛：屏幕顶部居中、iOS 磨砂玻璃质感、流光、状态消息
	· [新增] TabClass:CreateToggle 开关组件
	
	用法:
	local Bo = loadstring(readfile("BoLibrary.lua"))()
	local Window = Bo:CreateWindow({ Title = "BOZO HUB" })
	local Tab = Window:CreateTab({ Name = "Main" })
	Tab:CreateButton({ Name = "Click", Callback = function() end })
]]

local Bo = {}
Bo.__index = Bo

--// 服务
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

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
-- 实例工厂
local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

-- 自动纵向排列
local function AddListLayout(parent)
	Create("UIListLayout", {
		Name = "Layout",
		Parent = parent,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Bo.Theme.Padding),
	})
end

--[[
	流光引擎（RenderStepped 逐帧驱动，永不卡死）
	注意：UIGradient.Offset 是 Vector2 类型！
	X: -1 -> 1 线性扫描，形成光带从左到右流动
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
		Offset = Vector2.new(-1, 0),
	})

	local speed = config.Speed or 2   -- 扫过一次的秒数
	local pause = config.Pause or 0   -- 扫完后的停顿秒数
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
			gradient.Offset = Vector2.new(-1 + (clock / speed) * 2, 0)
		else
			gradient.Offset = Vector2.new(1, 0)
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
--  iOS 磨砂玻璃质感
--  半透明深色底 + 白色微光描边 + 圆角胶囊
--========================================================
local function ApplyFrost(inst, config)
	config = config or {}
	Create("UICorner", {
		Parent = inst,
		CornerRadius = UDim.new(0, config.Radius or 17),
	})
	Create("UIStroke", {
		Parent = inst,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.82,
	})
end

--========================================================
--  灵动岛（屏幕顶部居中 / 磨砂玻璃 / 流光 / 状态消息 / 可拖动）
--========================================================
local function BuildIsland(window)
	local gui = Create("ScreenGui", {
		Name = "Bo_Island",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 999,
	})
	pcall(function()
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end)

	-- holder 负责定位与按压缩放动画
	local holder = Create("Frame", {
		Name = "Holder",
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8), -- 屏幕顶部居中
		Size = UDim2.new(0, 120, 0, 34),
	})

	-- 胶囊主体：半透明黑底模拟磨砂玻璃
	local pill = Create("TextButton", {
		Name = "Pill",
		Parent = holder,
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
	})
	ApplyFrost(pill)

	-- 流光扫过胶囊背景
	Bo.CreateFlowGradient(pill, {
		ColorA = Color3.fromRGB(40, 40, 40),
		ColorB = Bo.Theme.Accent,
		ColorC = Color3.fromRGB(40, 40, 40),
		Speed = 2.5,
		Pause = 2,
	})

	-- 左侧状态指示点
	local dot = Create("Frame", {
		Name = "Dot",
		Parent = pill,
		BackgroundColor3 = Bo.Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0.5, -4),
		Size = UDim2.new(0, 8, 0, 8),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = dot })

	-- 状态消息文字
	local label = Create("TextLabel", {
		Name = "Status",
		Parent = pill,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 26, 0, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Font = Bo.Theme.FontBold,
		Text = "Bo",
		TextColor3 = Bo.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	--------------------------------------------------------
	-- 状态消息系统：Notify("xxx") 显示操作反馈
	--------------------------------------------------------
	local msgToken = 0
	function window.Notify(text, holdTime)
		msgToken += 1
		local myToken = msgToken
		label.Text = tostring(text)

		-- 消息出现时轻微拉宽提示
		TweenService:Create(holder,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, math.max(120, #tostring(text) * 7 + 50), 0, 34) }):Play()

		task.delay(holdTime or 2, function()
			if myToken == msgToken then
				label.Text = "Bo"
				TweenService:Create(holder,
					TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Size = UDim2.new(0, 120, 0, 34) }):Play()
			end
		end)
	end

	--------------------------------------------------------
	-- 拖动 + 点击判定
	--------------------------------------------------------
	local pressed, moved = false, false
	local pressStart, startPos

	pill.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			moved = false
			pressStart = input.Position
			startPos = holder.Position

			TweenService:Create(holder,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 140, 0, 40) }):Play()

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					pressed = false
					TweenService:Create(holder,
						TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Size = UDim2.new(0, 120, 0, 34) }):Play()
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

	window.Island = { GUI = gui, Holder = holder, Pill = pill, Label = label }
end

--========================================================
--  Tab 对象
--========================================================
local TabClass = {}
TabClass.__index = TabClass

function TabClass:CreateButton(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window

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
		flash.BackgroundTransparency = 0.85 -- 低透明度柔光起步
		TweenService:Create(flash,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()

		-- 灵动岛显示操作消息
		if window and window.Notify then
			window.Notify("已执行: " .. (config.Name or "?"))
		end

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

-- 开关组件
function TabClass:CreateToggle(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window
	local state = config.Default or false

	local btn = Create("TextButton", {
		Name = config.Name or "Toggle",
		Parent = self.Scroll,
		BackgroundColor3 = theme.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight),
		AutoButtonColor = false,
		Font = theme.Font,
		Text = "",
	})

	Create("TextLabel", {
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Font = theme.Font,
		Text = config.Name or "Toggle",
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- iOS 风格开关胶囊
	local track = Create("Frame", {
		Name = "Track",
		Parent = btn,
		BackgroundColor3 = state and theme.Accent or Color3.fromRGB(60, 60, 60),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })

	local knob = Create("Frame", {
		Name = "Knob",
		Parent = track,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		Size = UDim2.new(0, 18, 0, 18),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = knob })

	local api = {}
	api.Set = function(v, silent)
		state = v
		track.BackgroundColor3 = state and theme.Accent or Color3.fromRGB(60, 60, 60)
		TweenService:Create(knob,
			TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		}):Play()
		if not silent then
			if window and window.Notify then
				window.Notify((config.Name or "Toggle") .. ": " .. (state and "ON" or "OFF"))
			end
			if typeof(config.Callback) == "function" then
				task.spawn(config.Callback, state)
			end
		end
	end
	api.Get = function() return state end

	btn.MouseButton1Click:Connect(function()
		api.Set(not state)
	end)

	return api
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

-- ★ v3 补回的关键方法（v2 重构时意外丢失）
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
	page.Visible = (#self.Tabs == 0)

	local tabObj = setmetatable({
		Name = config.Name or "Tab",
		Button = tabBtn,
		Scroll = page,
		Window = self,
	}, TabClass)

	table.insert(self.Tabs, tabObj)

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tabObj)
		if self.Notify then
			self.Notify("切换到: " .. tabObj.Name)
		end
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

-- 入场动画：从中心弹出
function WindowClass:_PlayEnterAnimation()
	local main = self.Main
	main.Size = UDim2.new(0, 0, 0, 0)
	main.Position = UDim2.new(
		self._savedPos.X.Scale, self._savedPos.X.Offset + self._savedSize.X.Offset / 2,
		self._savedPos.Y.Scale, self._savedPos.Y.Offset + self._savedSize.Y.Offset / 2
	)
	TweenService:Create(main,
		TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = self._savedSize, Position = self._savedPos }):Play()
end

-- 退场动画：克隆原窗口本体，用裁剪容器撕成两半滑走
function WindowClass:_PlayExitAnimation(callback)
	local main = self.Main
	if not main.Visible then
		if callback then callback() end
		return
	end

	local size = main.AbsoluteSize
	local pos = main.AbsolutePosition
	local halfW = size.X / 2

	-- 左裁剪容器 + 完整窗口克隆（露出左半）
	local leftWrap = Create("Frame", {
		Parent = self.GUI,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(math.floor(halfW), size.Y),
		ClipsDescendants = true,
		ZIndex = 100,
	})
	local leftClone = main:Clone()
	leftClone.Name = "Exit_Left"
	leftClone.Parent = leftWrap
	leftClone.Position = UDim2.fromOffset(0, 0)

	-- 右裁剪容器 + 完整窗口克隆（露出右半）
	local rightWrap = Create("Frame", {
		Parent = self.GUI,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(pos.X + math.ceil(halfW), pos.Y),
		Size = UDim2.fromOffset(math.ceil(halfW), size.Y),
		ClipsDescendants = true,
		ZIndex = 100,
	})
	local rightClone = main:Clone()
	rightClone.Name = "Exit_Right"
	rightClone.Parent = rightWrap
	rightClone.Position = UDim2.fromOffset(-math.floor(halfW), 0)

	main.Visible = false

	-- 两半分别加速滑出屏幕
	local dur = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	TweenService:Create(leftWrap, dur, { Position = leftWrap.Position - UDim2.fromOffset(size.X, 0) }):Play()
	local tw = TweenService:Create(rightWrap, dur, { Position = rightWrap.Position + UDim2.fromOffset(size.X, 0) })
	tw:Play()
	tw.Completed:Once(function()
		leftWrap:Destroy()
		rightWrap:Destroy()
		if callback then callback() end
	end)
end

function WindowClass:Show()
	if self.IsOpen then return end
	self.IsOpen = true
	self.Main.Visible = true
	self:_PlayEnterAnimation()
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

	local savedPos  = config.Position or UDim2.new(0.22, 0, 0.18, 0)
	local savedSize = config.Size or UDim2.new(0, 581, 0, 333)

	local main = Create("Frame", {
		Name = "Main",
		Parent = gui,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = savedPos,
		Size = savedSize,
	})

	MakeDraggable(main)

	-- 细描边 + 流动描边光
	Create("UIStroke", {
		Name = "MainStroke",
		Parent = main,
		Color = theme.Accent,
		Thickness = 3,
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

	local tabButtons = Create("Frame", {
		Name = "TabButtons",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 117, 0, 291),
	})
	AddListLayout(tabButtons)

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
		_savedPos = savedPos,
		_savedSize = savedSize,
	}, WindowClass)

	BuildIsland(window)

	-- 首次入场动画
	window:_PlayEnterAnimation()

	return window
end

return Bo