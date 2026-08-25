--[[
	Bo UI Library v4
	轻量级 Roblox UI 库（基于 Bozo Hub 原始布局重构）
	
	v4 更新:
	· Button 改为返回 API（Set/Get/Click），与 Toggle 风格一致
	· 灵动岛流光加猛（更宽光带+更快速度）+ 描边流光
	· 窗口描边厚度 2px，与标题栏分隔线统一
	· 标题字体黑白流光
	· Bo.SetAccent(color) 全局换色：窗口描边/分隔线/标题/灵动岛/组件同步换色
	· 拖动位置记忆：下次 Show 原地生成
	· 入场动画：随机四面八方滑入
	· Tab 支持 Icon + 滑动指示器 + 切换动画 + 流光
	· 全组件层次感底板（外底板/内面板/悬浮层三层）
	· 新增 CreateSlider / CreateDropdown / CreateInput
	
	用法:
	local Bo = loadstring(readfile("BoLibrary.lua"))()
	local Window = Bo:CreateWindow({ Title = "BOZO HUB" })
	local Tab = Window:CreateTab({ Name = "Main", Icon = "🏠" })
	Tab:CreateButton({ Name = "Click", Callback = function() end })
	Tab:CreateToggle({ Name = "Switch", Default = true, Callback = function(v) end })
	Tab:CreateSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
	Tab:CreateDropdown({ Name = "Mode", Options = {"A","B"}, Callback = function(opt) end })
	Tab:CreateInput({ Name = "Name", Placeholder = "输入...", Callback = function(txt) end })
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
	Background    = Color3.fromRGB(25, 25, 25),   -- 最底层
	BackgroundAlt = Color3.fromRGB(20, 20, 20),   -- 页面层
	ElementBase   = Color3.fromRGB(32, 32, 32),   -- 组件外底板
	ElementPanel  = Color3.fromRGB(28, 28, 28),   -- 组件内面板
	ElementHover  = Color3.fromRGB(40, 40, 40),
	Accent        = Color3.fromRGB(85, 255, 127),
	Text          = Color3.fromRGB(255, 255, 255),
	TextDim       = Color3.fromRGB(170, 170, 170),
	Font          = Enum.Font.Gotham,
	FontBold      = Enum.Font.GothamBold,
	Padding       = 5,
	ButtonHeight  = 36,
	StrokeWidth   = 2, -- 描边厚度（窗口=分隔线=灵动岛）
}

--// 换色监听器（所有流光实例注册进来，SetAccent 时统一更新）
local accentWatchers = {}
local function watchAccent(inst, prop, makeColor)
	table.insert(accentWatchers, { inst = inst, prop = prop, makeColor = makeColor })
end

function Bo.SetAccent(color)
	Bo.Theme.Accent = color
	for _, w in ipairs(accentWatchers) do
		if w.inst.Parent then
			w.inst[w.prop] = w.makeColor(color)
		end
	end
end

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

-- 层次感组件底板：深色外底板 + 微圆角，内部再放内容形成立体层次
local function BuildLayeredCard(tab, height)
	local theme = Bo.Theme

	-- 显式递增排序，保证 UIListLayout 顺序稳定 & 下拉列表可插队
	tab._order = (tab._order or 0) + 1

	local card = Create("Frame", { -- 外底板（第一层）
		Name = "Card",
		Parent = tab.Scroll,
		BackgroundColor3 = theme.ElementBase,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -theme.Padding * 2, 0, height),
		LayoutOrder = tab._order,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })

	local panel = Create("Frame", { -- 内面板（第二层，固定高度不随卡片拉伸）
		Name = "Panel",
		Parent = card,
		BackgroundColor3 = theme.ElementPanel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 3, 0, 3),
		Size = UDim2.new(1, -6, 0, height - 6),
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = panel })

	return card, panel
end

--[[
	流光引擎（RenderStepped 逐帧驱动）
	UIGradient.Offset 是 Vector2！X: -1 -> 1 扫描
]]
function Bo.CreateFlowGradient(inst, config)
	config = config or {}

	local gradient = Create("UIGradient", {
		Name = "FlowGradient",
		Parent = inst,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, config.ColorA or Color3.fromRGB(60, 60, 60)),
			ColorSequenceKeypoint.new(0.45, config.ColorB or Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.55, config.ColorB or Color3.fromRGB(255, 255, 255)), -- 光带更宽更明显
			ColorSequenceKeypoint.new(1.00, config.ColorC or Color3.fromRGB(60, 60, 60)),
		}),
		Offset = Vector2.new(-1, 0),
	})

	local speed = config.Speed or 1.5 -- 默认更快
	local pause = config.Pause or 0.4
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
--  拖动支持（带位置记忆）
--========================================================
local function MakeDraggable(frame, onDrop)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

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
					if onDrop then onDrop(frame.Position) end -- 松手时记录位置
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
			local delta = input.Position - dragStart
			TweenService:Create(frame, TweenInfo.new(0.1), {
				Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				),
			}):Play()
		end
	end)
end

--========================================================
--  iOS 磨砂玻璃质感
--========================================================
local function ApplyFrost(inst, config)
	config = config or {}
	Create("UICorner", {
		Parent = inst,
		CornerRadius = UDim.new(0, config.Radius or 17),
	})
	local stroke = Create("UIStroke", {
		Parent = inst,
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1,
		Transparency = 0.82,
	})
	return stroke
end

--========================================================
--  灵动岛（顶部居中 / 磨砂 / 强流光 / 描边流光 / 状态消息 / 可拖）
--========================================================
local function BuildIsland(window)
	local theme = Bo.Theme

	local gui = Create("ScreenGui", {
		Name = "Bo_Island",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 999,
	})
	pcall(function()
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end)

	local holder = Create("Frame", {
		Name = "Holder",
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0, 120, 0, 34),
	})

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

	-- ★ 描边流光：独立渐变驱动器作用于 UIStroke（不受背景渐变干扰）
	local islandStroke = Create("UIStroke", {
		Name = "IslandStroke",
		Parent = pill,
		Color = theme.Accent,
		Thickness = theme.StrokeWidth,
		Transparency = 0.2,
	})
	ApplyFrost(pill)

	-- 背景强流光：宽光带 + 快速扫描，非常明显
	Bo.CreateFlowGradient(pill, {
		ColorA = Color3.fromRGB(30, 30, 30),
		ColorB = theme.Accent,
		ColorC = Color3.fromRGB(30, 30, 30),
		Speed = 1.5,
		Pause = 0.3,
	})

	-- 描边流光：暗→亮→暗扫过边框
	do
		local g = Create("UIGradient", {
			Parent = islandStroke,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(20, 60, 35)),
				ColorSequenceKeypoint.new(0.50, theme.Accent),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 60, 35)),
			}),
			Offset = Vector2.new(-1, 0),
		})
		watchAccent(islandStroke, "Color", function(c) return c end)
		task.spawn(function()
			local clock = 0
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not islandStroke.Parent then conn:Disconnect() return end
				clock += dt
				if clock >= 2 then clock -= 2 end
				g.Offset = Vector2.new(-1 + (clock / 2) * 2, 0)
			end)
		end)
	end

	local dot = Create("Frame", {
		Name = "Dot",
		Parent = pill,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0.5, -4),
		Size = UDim2.new(0, 8, 0, 8),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = dot })
	watchAccent(dot, "BackgroundColor3", function(c) return c end)

	local label = Create("TextLabel", {
		Name = "Status",
		Parent = pill,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 26, 0, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Font = theme.FontBold,
		Text = "Bo",
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	-- 状态消息系统
	local msgToken = 0
	function window.Notify(text, holdTime)
		msgToken += 1
		local myToken = msgToken
		label.Text = tostring(text)
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

	-- 拖动 + 点击判定
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

-- 层次感按钮（卡片式）
function TabClass:CreateButton(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window

	local card, panel = BuildLayeredCard(self, theme.ButtonHeight)

	local btn = Create("TextButton", {
		Name = config.Name or "Button",
		Parent = panel,
		BackgroundColor3 = theme.ElementPanel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		AutoButtonColor = false,
		Font = theme.Font,
		Text = (config.Icon and (config.Icon .. "  ") or "") .. (config.Name or "Button"),
		TextColor3 = theme.Text,
		TextSize = 14,
	})
	btn.ZIndex = 3

	local flash = Create("Frame", {
		Name = "Flash",
		Parent = panel,
		BackgroundColor3 = theme.Text,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
	})

	btn.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = theme.ElementHover }):Play()
		TweenService:Create(panel, TweenInfo.new(0.12), { BackgroundColor3 = theme.ElementHover }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = theme.ElementBase }):Play()
		TweenService:Create(panel, TweenInfo.new(0.12), { BackgroundColor3 = theme.ElementPanel }):Play()
	end)

	local api = {}
	api.Set = function(text)
		btn.Text = text
	end
	api.Get = function() return btn.Text end
	api.Click = function()
		flash.BackgroundTransparency = 0.85
		TweenService:Create(flash,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
		if window and window.Notify then
			window.Notify("已执行: " .. (config.Name or "?"))
		end
		if typeof(config.Callback) == "function" then
			task.spawn(config.Callback)
		end
	end

	btn.MouseButton1Click:Connect(api.Click)

	return api
end

function TabClass:CreateLabel(config)
	config = config or {}
	local theme = Bo.Theme

	local card, _ = BuildLayeredCard(self, theme.ButtonHeight)
	card.BackgroundTransparency = 0.5 -- 标签用更弱的层次

	return Create("TextLabel", {
		Name = config.Name or "Label",
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = theme.Font,
		Text = config.Text or config.Name or "Label",
		TextColor3 = theme.TextDim,
		TextSize = 14,
	})
end

function TabClass:CreateToggle(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window
	local state = config.Default or false

	local card, panel = BuildLayeredCard(self, theme.ButtonHeight)

	local hit = Create("TextButton", {
		Name = "Hit",
		Parent = panel,
		BackgroundColor3 = theme.ElementPanel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		AutoButtonColor = false,
		Font = theme.Font,
		Text = "",
	})

	Create("TextLabel", {
		Parent = hit,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Font = theme.Font,
		Text = (config.Icon and (config.Icon .. "  ") or "") .. (config.Name or "Toggle"),
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local track = Create("Frame", {
		Name = "Track",
		Parent = hit,
		BackgroundColor3 = state and theme.Accent or Color3.fromRGB(55, 55, 55),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })
	watchAccent(track, "BackgroundColor3", function(c)
		return state and c or Color3.fromRGB(55, 55, 55)
	end)

	-- 开关 ON 时轨道有流光
	local trackGradient
	local function updateTrackGlow()
		if state and not trackGradient then
			trackGradient = Bo.CreateFlowGradient(track, {
				ColorA = Color3.fromRGB(30, 80, 50),
				ColorB = theme.Accent,
				ColorC = Color3.fromRGB(30, 80, 50),
				Speed = 1.5,
				Pause = 0.5,
			})
		elseif not state and trackGradient then
			trackGradient:Destroy()
			trackGradient = nil
		end
	end
	updateTrackGlow()

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
	function api.Set(v, silent)
		state = v
		updateTrackGlow()
		track.BackgroundColor3 = state and theme.Accent or Color3.fromRGB(55, 55, 55)
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
	function api.Get() return state end

	hit.MouseButton1Click:Connect(function()
		api.Set(not state)
	end)

	return api
end

-- 拉条（滑块）
function TabClass:CreateSlider(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window

	local min, max = config.Min or 0, config.Max or 100
	local value = math.clamp(config.Default or min, min, max)

	local card, panel = BuildLayeredCard(self, theme.ButtonHeight + 14)

	Create("TextLabel", {
		Parent = panel,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -20, 0, 16),
		Font = theme.Font,
		Text = (config.Icon and (config.Icon .. "  ") or "") .. (config.Name or "Slider") .. ": " .. value,
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Name = "Title",
	})
	local titleLabel = panel:FindFirstChild("Title")

	local bar = Create("TextButton", { -- 滑轨（可点击跳转）
		Name = "Bar",
		Parent = panel,
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		Text = "",
		AutoButtonColor = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bar })

	local fill = Create("Frame", { -- 已填充部分
		Name = "Fill",
		Parent = bar,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
	watchAccent(fill, "BackgroundColor3", function(c) return c end)

	local knob = Create("Frame", { -- 滑块圆点
		Name = "Knob",
		Parent = bar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		ZIndex = 2,
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = knob })

	local api = {}
	local setting = false

	local function setValueFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		titleLabel.Text = (config.Icon and (config.Icon .. "  ") or "") .. (config.Name or "Slider") .. ": " .. value
		if not setting and typeof(config.Callback) == "function" then
			task.spawn(config.Callback, value)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			setting = true
			setValueFromX(input.Position.X)
			knob.Size = UDim2.new(0, 17, 0, 17) -- 按压微放大
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if setting and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setValueFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if setting then
				setting = false
				knob.Size = UDim2.new(0, 14, 0, 14)
				if window and window.Notify then
					window.Notify((config.Name or "Slider") .. ": " .. value)
				end
				if typeof(config.Callback) == "function" then
					task.spawn(config.Callback, value)
				end
			end
		end
	end)

	function api.Set(v, silent)
		value = math.clamp(math.floor(v + 0.5), min, max)
		local rel = (value - min) / (max - min)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		titleLabel.Text = (config.Icon and (config.Icon .. "  ") or "") .. (config.Name or "Slider") .. ": " .. value
		if not silent and typeof(config.Callback) == "function" then
			task.spawn(config.Callback, value)
		end
	end
	function api.Get() return value end

	return api
end

-- 选择菜单（下拉）
function TabClass:CreateDropdown(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window

	local options = config.Options or { "Option A", "Option B" }
	local selected = config.Default or options[1]
	local open = false

	local card, panel = BuildLayeredCard(self, theme.ButtonHeight)

	local btn = Create("TextButton", {
		Name = "Main",
		Parent = panel,
		BackgroundColor3 = theme.ElementPanel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		AutoButtonColor = false,
		Font = theme.Font,
		Text = "",
	})

	Create("TextLabel", {
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.65, 0, 1, 0),
		Font = theme.Font,
		Text = (config.Icon and (config.Icon .. "  ") or "") .. selected,
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Name = "Value",
	})
	local valueLabel = btn:FindFirstChild("Value")

	local arrow = Create("TextLabel", {
		Parent = btn,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Font = theme.FontBold,
		Text = "▼",
		TextColor3 = theme.TextDim,
		TextSize = 12,
		Rotation = 180,
	})

	-- 下拉选项容器：内嵌展开式（卡片本体向下生长）
	local listWrap = Create("Frame", {
		Name = "DropdownList",
		Parent = panel,
		BackgroundColor3 = theme.ElementBase,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 0, 0, height - 3),
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		ZIndex = 20,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listWrap })

	local listInner = Create("Frame", {
		Parent = listWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 3, 0, 3),
		Size = UDim2.new(1, -6, 1, -6),
	})
	AddListLayout(listInner)

	for i, opt in ipairs(options) do
		local optBtn = Create("TextButton", {
			Name = opt,
			Parent = listInner,
			BackgroundColor3 = theme.ElementPanel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28),
			AutoButtonColor = false,
			Font = theme.Font,
			Text = "  " .. opt,
			TextColor3 = theme.TextDim,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
			LayoutOrder = i,
		})
		optBtn.MouseEnter:Connect(function()
			optBtn.BackgroundTransparency = 0.4
			optBtn.BackgroundColor3 = theme.ElementHover
		end)
		optBtn.MouseLeave:Connect(function()
			optBtn.BackgroundTransparency = 1
		end)
		optBtn.MouseButton1Click:Connect(function()
			selected = opt
			valueLabel.Text = (config.Icon and (config.Icon .. "  ") or "") .. opt
			api.SetOpen(false)
			if window and window.Notify then
				window.Notify((config.Name or "Menu") .. ": " .. opt)
			end
			if typeof(config.Callback) == "function" then
				task.spawn(config.Callback, opt)
			end
		end)
	end

	local api = {}
	function api.SetOpen(v)
		open = v
		local targetH = v and (#options * 31 + 8) or 0
		TweenService:Create(listWrap,
			TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.new(1, 0, 0, targetH) }):Play()
		-- 卡片同步长高容纳选项
		TweenService:Create(card,
			TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = v and UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight + targetH) or UDim2.new(1, -theme.Padding * 2, 0, theme.ButtonHeight) }):Play()
		TweenService:Create(arrow, TweenInfo.new(0.22), { Rotation = v and 0 or 180 }):Play()
	end

	btn.MouseButton1Click:Connect(function()
		api.SetOpen(not open)
	end)

	function api.Set(opt, silent)
		if table.find(options, opt) then
			selected = opt
			valueLabel.Text = (config.Icon and (config.Icon .. "  ") or "") .. opt
			if not silent and typeof(config.Callback) == "function" then
				task.spawn(config.Callback, opt)
			end
		end
	end
	function api.Get() return selected end

	return api
end

-- 文本输入框
function TabClass:CreateInput(config)
	config = config or {}
	local theme = Bo.Theme
	local window = self.Window

	local card, panel = BuildLayeredCard(self, theme.ButtonHeight)

	local box = Create("TextBox", {
		Name = "Input",
		Parent = panel,
		BackgroundColor3 = theme.ElementPanel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = theme.Font,
		PlaceholderText = config.Placeholder or "输入...",
		PlaceholderColor3 = Color3.fromRGB(110, 110, 110),
		Text = config.Default or "",
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	-- 聚焦时卡片高亮描边
	local focusStroke
	box.Focused:Connect(function()
		focusStroke = Create("UIStroke", {
			Parent = card,
			Color = theme.Accent,
			Thickness = 1.5,
			Transparency = 0.3,
		})
	end)
	box.FocusLost:Connect(function(enterPressed)
		if focusStroke then focusStroke:Destroy() focusStroke = nil end
		if enterPressed and window and window.Notify then
			window.Notify((config.Name or "输入") .. ": " .. box.Text)
		end
		if typeof(config.Callback) == "function" then
			task.spawn(config.Callback, box.Text, enterPressed)
		end
	end)

	local api = {}
	function api.Set(text, silent)
		box.Text = tostring(text)
		if not silent and typeof(config.Callback) == "function" then
			task.spawn(config.Callback, box.Text, false)
		end
	end
	function api.Get() return box.Text end

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

function WindowClass:CreateTab(config)
	config = config or {}

	local tabBtn = Create("TextButton", {
		Name = config.Name or "Tab",
		Parent = self.TabButtons,
		BackgroundColor3 = self.Theme.BackgroundAlt,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 117, 0, 34),
		Font = self.Theme.FontBold,
		Text = (config.Icon and (config.Icon .. " ") or "") .. (config.Name or "Tab"),
		TextColor3 = self.Theme.TextDim,
		TextSize = 14,
		LayoutOrder = #self.Tabs + 1,
	})
	tabBtn.AutoButtonColor = false

	local page = BuildScrollPage(self.TabsContainer)
	page.Visible = (#self.Tabs == 0)

	local tabObj = setmetatable({
		Name = config.Name or "Tab",
		Button = tabBtn,
		Scroll = page,
		Window = self,
	}, TabClass)

	table.insert(self.Tabs, tabObj)

	-- 统一在这里连接点击事件
	tabBtn.MouseButton1Click:Connect(function()
		if self.ActiveTab ~= tabObj then
			self:SelectTab(tabObj)
		end
	end)

	-- 第一个 tab 自动选中并放置指示器
	if #self.Tabs == 1 then
		self:SelectTab(tabObj, true)
	end

	return tabObj
end

-- 切换标签：滑动指示器 + 页面滑入动画 + tab 流光高亮
function WindowClass:SelectTab(target, instant)
	local theme = Bo.Theme
	local oldPage = self.ActiveTab and self.ActiveTab.Scroll or nil

	self.ActiveTab = target

	for _, tab in ipairs(self.Tabs) do
		local active = (tab == target)
		tab.Button.BackgroundTransparency = active and 0 or 1
		tab.Button.TextColor3 = active and theme.Text or theme.TextDim
	end

	-- 滑动指示器移动到目标按钮（按索引计算，UIListLayout 不写回 Position）
	local idx = 1
	for i, tab in ipairs(self.Tabs) do
		if tab == target then
			idx = i
			break
		end
	end
	TweenService:Create(self.Indicator,
		TweenInfo.new(instant and 0 or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 0, 42 + (idx - 1) * 39) }):Play()

	-- 页面切换动画：新页从右侧滑入
	if instant then
		target.Scroll.Visible = true
	elseif oldPage and oldPage ~= target.Scroll then
		oldPage.Visible = false
		target.Scroll.Visible = true
		local slideIn = Create("UIPadding", {
			Parent = target.Scroll,
			PaddingLeft = UDim.new(0, 40),
		})
		TweenService:Create(slideIn, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ PaddingLeft = UDim.new(0, 0) }):Play()
		task.delay(0.26, function()
			slideIn:Destroy()
		end)

		if self.Notify then
			self.Notify("切换到: " .. target.Name)
		end
	end
end

-- 入场动画：随机四面八方滑入到记忆位置
function WindowClass:_PlayEnterAnimation()
	local main = self.Main
	local savedPos, savedSize = self._savedPos, self._savedSize

	local directions = {
		UDim2.new(savedPos.X.Scale, savedPos.X.Offset, -1.2, 0),                          -- 上
		UDim2.new(savedPos.X.Scale, savedPos.X.Offset, 1.2, 0),                           -- 下
		UDim2.new(-1.0, 0, savedPos.Y.Scale, savedPos.Y.Offset),                          -- 左
		UDim2.new(1.05, 0, savedPos.Y.Scale, savedPos.Y.Offset),                          -- 右
	}
	local start = directions[math.random(1, #directions)]

	main.Size = savedSize
	main.Position = start

	TweenService:Create(main,
		TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = savedPos }):Play()
end

-- 退场动画：克隆原窗口本体，裁剪成两半滑走
function WindowClass:_PlayExitAnimation(callback)
	local main = self.Main
	if not main.Visible then
		if callback then callback() end
		return
	end

	local size = main.AbsoluteSize
	local pos = main.AbsolutePosition
	local halfW = size.X / 2

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
	self:_PlayEnterAnimation() -- 从随机方向滑入到 _savedPos（拖动后的位置）
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
	math.randomseed(os.clock())
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

	-- 拖动 + 松手时保存位置（实现位置记忆）
	MakeDraggable(main, function(newPos)
		window._savedPos = newPos
	end)

	-- ★ 描边流光：独立渐变驱动器直接挂在 UIStroke 上
	local mainStroke = Create("UIStroke", {
		Name = "MainStroke",
		Parent = main,
		Color = theme.Accent,
		Thickness = theme.StrokeWidth, -- 2px，与分隔线一致
		Transparency = 0.25,
	})
	do
		local strokeGrad = Create("UIGradient", {
			Parent = mainStroke,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(15, 50, 30)),
				ColorSequenceKeypoint.new(0.50, theme.Accent),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(15, 50, 30)),
			}),
			Offset = Vector2.new(-1, 0),
		})
		task.spawn(function()
			local clock = 0
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not mainStroke.Parent then conn:Disconnect() return end
				clock += dt
				if clock >= 3 then clock -= 3 end
				strokeGrad.Offset = Vector2.new(-1 + (clock / 3) * 2, 0)
			end)
		end)
		-- 换色支持
		watchAccent(mainStroke, "Color", function(c) return c end)
		mainStroke:GetPropertyChangedSignal("Color"):Connect(function()
			strokeGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(15, 50, 30)),
				ColorSequenceKeypoint.new(0.50, mainStroke.Color),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(15, 50, 30)),
			})
		end)
	end

	-- 标题栏分隔线流光（基准样式）
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
	watchAccent(titleBar, "BackgroundColor3", function(c) return c end)

	-- 标题：黑白流光字体
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
	do
		local g = Create("UIGradient", {
			Parent = title,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(120, 120, 120)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(120, 120, 120)),
			}),
			Offset = Vector2.new(-1, 0),
		})
		task.spawn(function()
			local clock = 0
			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not title.Parent then conn:Disconnect() return end
				clock += dt
				if clock >= 2.5 then clock -= 2.5 end
				g.Offset = Vector2.new(-1 + (clock / 2.5) * 2, 0)
			end)
		end)
	end

	local tabButtons = Create("Frame", {
		Name = "TabButtons",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 117, 0, 291),
	})
	AddListLayout(tabButtons)

	-- Tab 滑动指示器（流光条）
	local indicator = Create("Frame", {
		Name = "Indicator",
		Parent = main,
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 3, 0, 34),
		ZIndex = 5,
	})
	Bo.CreateFlowGradient(indicator, {
		ColorA = Color3.fromRGB(25, 80, 45),
		ColorB = Color3.fromRGB(255, 255, 255),
		ColorC = Color3.fromRGB(25, 80, 45),
		Speed = 1.5,
	})
	watchAccent(indicator, "BackgroundColor3", function(c) return c end)

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
		Indicator = indicator,
		TabButtons = tabButtons,
		TabsContainer = tabsContainer,
		Tabs = {},
		Theme = theme,
		IsOpen = true,
		ActiveTab = nil,
		_savedPos = savedPos,
		_savedSize = savedSize,
	}, WindowClass)

	BuildIsland(window)

	-- 首次入场：随机方向滑入
	window:_PlayEnterAnimation()

	return window
end

return Bo