-- [[ XARG UI Library - 绿AR 旗舰重置版 ]] --
-- Master: 主人专属定制 UI 框架

local XARGUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 绿AR 经典黑绿配色方案
local Theme = {
	Background = Color3.fromRGB(18, 20, 24),     -- 暗黑主背景
	Sidebar = Color3.fromRGB(12, 14, 17),        -- 侧边栏背景
	Card = Color3.fromRGB(26, 29, 36),           -- 卡片背景
	Accent = Color3.fromRGB(0, 230, 118),        -- 绿AR霓虹绿
	AccentGlow = Color3.fromRGB(0, 255, 136),    -- 高亮绿
	Text = Color3.fromRGB(240, 240, 240),        -- 主文本
	SubText = Color3.fromRGB(150, 155, 165),     -- 次要文本
	Stroke = Color3.fromRGB(40, 45, 55),         -- 默认边框
	StrokeActive = Color3.fromRGB(0, 230, 118),  -- 激活边框
}

-- 辅助函数：创建 Tween
local function Tween(object, info, properties)
	local anim = TweenService:Create(object, TweenInfo.new(info, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
	anim:Play()
	return anim
end

-- 辅助函数：平滑拖拽
local function EnableDragging(frame, dragHandle)
	local dragging, dragInput, dragStart, startPos
	dragHandle = dragHandle or frame

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- 创建主窗口
function XARGUI:CreateWindow(titleText)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "XARGUI_GreenAR"
	ScreenGui.ResetOnSpawn = false
	
	-- 兼容 CoreGui 或 LocalPlayer.PlayerGui
	pcall(function()
		ScreenGui.Parent = CoreGui
	end)
	if not ScreenGui.Parent then
		ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	-- 主框架
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 520, 0, 360)
	MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
	MainFrame.BackgroundColor3 = Theme.Background
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Theme.Stroke
	MainStroke.Thickness = 1.5
	MainStroke.Parent = MainFrame

	-- 顶部标题栏
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 40)
	TopBar.BackgroundColor3 = Theme.Sidebar
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	local TopBarCorner = Instance.new("UICorner")
	TopBarCorner.CornerRadius = UDim.new(0, 10)
	TopBarCorner.Parent = TopBar

	-- 补齐 TopBar 下方圆角遮挡
	local TopBarFix = Instance.new("Frame")
	TopBarFix.Size = UDim2.new(1, 0, 0, 10)
	TopBarFix.Position = UDim2.new(0, 0, 1, -10)
	TopBarFix.BackgroundColor3 = Theme.Sidebar
	TopBarFix.BorderSizePixel = 0
	TopBarFix.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -50, 1, 0)
	Title.Position = UDim2.new(0, 15, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = titleText or "绿AR 插件 | XARG UI"
	Title.TextColor3 = Theme.Accent
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 15
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar

	-- 启用窗口拖拽
	EnableDragging(MainFrame, TopBar)

	-- 侧边栏
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 130, 1, -40)
	Sidebar.Position = UDim2.new(0, 0, 0, 40)
	Sidebar.BackgroundColor3 = Theme.Sidebar
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame

	local SidebarLayout = Instance.new("UIListLayout")
	SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SidebarLayout.Padding = UDim.new(0, 5)
	SidebarLayout.Parent = Sidebar

	local SidebarPadding = Instance.new("UIPadding")
	SidebarPadding.PaddingTop = UDim.new(0, 10)
	SidebarPadding.PaddingLeft = UDim.new(0, 8)
	SidebarPadding.PaddingRight = UDim.new(0, 8)
	SidebarPadding.Parent = Sidebar

	-- 内容区域容器
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Size = UDim2.new(1, -140, 1, -50)
	ContentContainer.Position = UDim2.new(0, 135, 0, 45)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Parent = MainFrame

	local Window = {
		CurrentTab = nil,
		Tabs = {}
	}

	-- 极简通知系统 (Notification)
	function Window:Notify(title, desc, duration)
		duration = duration or 3
		local NotifyFrame = Instance.new("Frame")
		NotifyFrame.Size = UDim2.new(0, 220, 0, 60)
		NotifyFrame.Position = UDim2.new(1, 10, 1, -70)
		NotifyFrame.BackgroundColor3 = Theme.Card
		NotifyFrame.Parent = ScreenGui

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 8)
		Corner.Parent = NotifyFrame

		local Stroke = Instance.new("UIStroke")
		Stroke.Color = Theme.Accent
		Stroke.Thickness = 1
		Stroke.Parent = NotifyFrame

		local NTitle = Instance.new("TextLabel")
		NTitle.Size = UDim2.new(1, -10, 0, 20)
		NTitle.Position = UDim2.new(0, 10, 0, 5)
		NTitle.BackgroundTransparency = 1
		NTitle.Text = title
		NTitle.TextColor3 = Theme.Accent
		NTitle.Font = Enum.Font.GothamBold
		NTitle.TextSize = 13
		NTitle.TextXAlignment = Enum.TextXAlignment.Left
		NTitle.Parent = NotifyFrame

		local NDesc = Instance.new("TextLabel")
		NDesc.Size = UDim2.new(1, -10, 0, 30)
		NDesc.Position = UDim2.new(0, 10, 0, 25)
		NDesc.BackgroundTransparency = 1
		NDesc.Text = desc
		NDesc.TextColor3 = Theme.Text
		NDesc.Font = Enum.Font.Gotham
		NDesc.TextSize = 11
		NDesc.TextWrapped = true
		NDesc.TextXAlignment = Enum.TextXAlignment.Left
		NDesc.Parent = NotifyFrame

		Tween(NotifyFrame, 0.4, {Position = UDim2.new(1, -230, 1, -70)})
		task.delay(duration, function()
			local anim = Tween(NotifyFrame, 0.4, {Position = UDim2.new(1, 10, 1, -70)})
			anim.Completed:Connect(function() NotifyFrame:Destroy() end)
		end)
	end

	-- 创建 Tab 页签
	function Window:CreateTab(tabName)
		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(1, 0, 0, 35)
		TabBtn.BackgroundColor3 = Theme.Card
		TabBtn.BackgroundTransparency = 1
		TabBtn.Text = tabName
		TabBtn.TextColor3 = Theme.SubText
		TabBtn.Font = Enum.Font.GothamMedium
		TabBtn.TextSize = 13
		TabBtn.Parent = Sidebar

		local TabBtnCorner = Instance.new("UICorner")
		TabBtnCorner.CornerRadius = UDim.new(0, 6)
		TabBtnCorner.Parent = TabBtn

		-- 选中高亮指示条
		local Indicator = Instance.new("Frame")
		Indicator.Size = UDim2.new(0, 3, 0, 18)
		Indicator.Position = UDim2.new(0, 0, 0.5, -9)
		Indicator.BackgroundColor3 = Theme.Accent
		Indicator.BackgroundTransparency = 1
		Indicator.Parent = TabBtn

		local IndicatorCorner = Instance.new("UICorner")
		IndicatorCorner.CornerRadius = UDim.new(1, 0)
		IndicatorCorner.Parent = Indicator

		-- 页面 ScrollFrame
		local TabPage = Instance.new("ScrollingFrame")
		TabPage.Size = UDim2.new(1, 0, 1, 0)
		TabPage.BackgroundTransparency = 1
		TabPage.BorderSizePixel = 0
		TabPage.ScrollBarThickness = 2
		TabPage.ScrollBarImageColor3 = Theme.Accent
		TabPage.Visible = false
		TabPage.Parent = ContentContainer

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 10)
		PageLayout.Parent = TabPage

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingRight = UDim.new(0, 5)
		PagePadding.Parent = TabPage

		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
		end)

		local Tab = {
			Page = TabPage,
			Button = TabBtn
		}

		-- Tab 切换逻辑
		TabBtn.MouseButton1Click:Connect(function()
			if Window.CurrentTab == Tab then return end

			if Window.CurrentTab then
				Window.CurrentTab.Page.Visible = false
				Tween(Window.CurrentTab.Button, 0.2, {BackgroundTransparency = 1, TextColor3 = Theme.SubText})
				Tween(Window.CurrentTab.Button:FindFirstChild("Frame"), 0.2, {BackgroundTransparency = 1})
			end

			Window.CurrentTab = Tab
			TabPage.Visible = true
			Tween(TabBtn, 0.2, {BackgroundTransparency = 0, TextColor3 = Theme.Accent})
			Tween(Indicator, 0.2, {BackgroundTransparency = 0})
		end)

		if #Window.Tabs == 0 then
			Window.CurrentTab = Tab
			TabPage.Visible = true
			TabBtn.BackgroundTransparency = 0
			TabBtn.TextColor3 = Theme.Accent
			Indicator.BackgroundTransparency = 0
		end

		table.insert(Window.Tabs, Tab)

		-- 创建卡片分组 (Section) - 绿AR的核心精髓！
		function Tab:CreateSection(sectionName)
			local SectionFrame = Instance.new("Frame")
			SectionFrame.Size = UDim2.new(1, 0, 0, 30)
			SectionFrame.BackgroundColor3 = Theme.Card
			SectionFrame.Parent = TabPage

			local SectionCorner = Instance.new("UICorner")
			SectionCorner.CornerRadius = UDim.new(0, 8)
			SectionCorner.Parent = SectionFrame

			local SectionStroke = Instance.new("UIStroke")
			SectionStroke.Color = Theme.Stroke
			SectionStroke.Thickness = 1
			SectionStroke.Parent = SectionFrame

			local SecTitle = Instance.new("TextLabel")
			SecTitle.Size = UDim2.new(1, -20, 0, 25)
			SecTitle.Position = UDim2.new(0, 10, 0, 5)
			SecTitle.BackgroundTransparency = 1
			SecTitle.Text = sectionName
			SecTitle.TextColor3 = Theme.Accent
			SecTitle.Font = Enum.Font.GothamBold
			SecTitle.TextSize = 12
			SecTitle.TextXAlignment = Enum.TextXAlignment.Left
			SecTitle.Parent = SectionFrame

			local SecLayout = Instance.new("UIListLayout")
			SecLayout.SortOrder = Enum.SortOrder.LayoutOrder
			SecLayout.Padding = UDim.new(0, 6)
			SecLayout.Parent = SectionFrame

			local SecPadding = Instance.new("UIPadding")
			SecPadding.PaddingTop = UDim.new(0, 30)
			SecPadding.PaddingBottom = UDim.new(0, 10)
			SecPadding.PaddingLeft = UDim.new(0, 10)
			SecPadding.PaddingRight = UDim.new(0, 10)
			SecPadding.Parent = SectionFrame

			SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SecLayout.AbsoluteContentSize.Y + 40)
			end)

			local Section = {}

			-- 1. 按钮 (Button)
			function Section:CreateButton(text, callback)
				local Btn = Instance.new("TextButton")
				Btn.Size = UDim2.new(1, 0, 0, 32)
				Btn.BackgroundColor3 = Theme.Sidebar
				Btn.Text = text
				Btn.TextColor3 = Theme.Text
				Btn.Font = Enum.Font.Gotham
				Btn.TextSize = 12
				Btn.Parent = SectionFrame

				local BtnCorner = Instance.new("UICorner")
				BtnCorner.CornerRadius = UDim.new(0, 6)
				BtnCorner.Parent = Btn

				local BtnStroke = Instance.new("UIStroke")
				BtnStroke.Color = Theme.Stroke
				BtnStroke.Thickness = 1
				BtnStroke.Parent = Btn

				Btn.MouseEnter:Connect(function()
					Tween(BtnStroke, 0.2, {Color = Theme.Accent})
				end)
				Btn.MouseLeave:Connect(function()
					Tween(BtnStroke, 0.2, {Color = Theme.Stroke})
				end)

				Btn.MouseButton1Click:Connect(function()
					Tween(Btn, 0.1, {Size = UDim2.new(0.98, 0, 0, 30)}):Completed:Connect(function()
						Tween(Btn, 0.1, {Size = UDim2.new(1, 0, 0, 32)})
					end)
					if callback then callback() end
				end)
			end

			-- 2. 开关 (Toggle)
			function Section:CreateToggle(text, default, callback)
				local TglFrame = Instance.new("Frame")
				TglFrame.Size = UDim2.new(1, 0, 0, 30)
				TglFrame.BackgroundTransparency = 1
				TglFrame.Parent = SectionFrame

				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(0.7, 0, 1, 0)
				Label.BackgroundTransparency = 1
				Label.Text = text
				Label.TextColor3 = Theme.Text
				Label.Font = Enum.Font.Gotham
				Label.TextSize = 12
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = TglFrame

				local Switch = Instance.new("TextButton")
				Switch.Size = UDim2.new(0, 42, 0, 22)
				Switch.Position = UDim2.new(1, -42, 0.5, -11)
				Switch.BackgroundColor3 = default and Theme.Accent or Theme.Sidebar
				Switch.Text = ""
				Switch.Parent = TglFrame

				local SwitchCorner = Instance.new("UICorner")
				SwitchCorner.CornerRadius = UDim.new(1, 0)
				SwitchCorner.Parent = Switch

				local Knob = Instance.new("Frame")
				Knob.Size = UDim2.new(0, 16, 0, 16)
				Knob.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Knob.Parent = Switch

				local KnobCorner = Instance.new("UICorner")
				KnobCorner.CornerRadius = UDim.new(1, 0)
				KnobCorner.Parent = Knob

				local state = default or false

				Switch.MouseButton1Click:Connect(function()
					state = not state
					if state then
						Tween(Switch, 0.2, {BackgroundColor3 = Theme.Accent})
						Tween(Knob, 0.2, {Position = UDim2.new(1, -19, 0.5, -8)})
					else
						Tween(Switch, 0.2, {BackgroundColor3 = Theme.Sidebar})
						Tween(Knob, 0.2, {Position = UDim2.new(0, 3, 0.5, -8)})
					end
					if callback then callback(state) end
				end)
			end

			-- 3. 滑块 (Slider)
			function Section:CreateSlider(text, min, max, default, callback)
				local SliderFrame = Instance.new("Frame")
				SliderFrame.Size = UDim2.new(1, 0, 0, 40)
				SliderFrame.BackgroundTransparency = 1
				SliderFrame.Parent = SectionFrame

				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(0.6, 0, 0, 20)
				Label.BackgroundTransparency = 1
				Label.Text = text
				Label.TextColor3 = Theme.Text
				Label.Font = Enum.Font.Gotham
				Label.TextSize = 12
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = SliderFrame

				local ValLabel = Instance.new("TextLabel")
				ValLabel.Size = UDim2.new(0.4, 0, 0, 20)
				ValLabel.Position = UDim2.new(0.6, 0, 0, 0)
				ValLabel.BackgroundTransparency = 1
				ValLabel.Text = tostring(default or min)
				ValLabel.TextColor3 = Theme.Accent
				ValLabel.Font = Enum.Font.GothamBold
				ValLabel.TextSize = 12
				ValLabel.TextXAlignment = Enum.TextXAlignment.Right
				ValLabel.Parent = SliderFrame

				local BarBg = Instance.new("Frame")
				BarBg.Size = UDim2.new(1, 0, 0, 6)
				BarBg.Position = UDim2.new(0, 0, 1, -8)
				BarBg.BackgroundColor3 = Theme.Sidebar
				BarBg.Parent = SliderFrame

				local BarCorner = Instance.new("UICorner")
				BarCorner.CornerRadius = UDim.new(1, 0)
				BarCorner.Parent = BarBg

				local Fill = Instance.new("Frame")
				Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
				Fill.BackgroundColor3 = Theme.Accent
				Fill.Parent = BarBg

				local FillCorner = Instance.new("UICorner")
				FillCorner.CornerRadius = UDim.new(1, 0)
				FillCorner.Parent = Fill

				local dragging = false

				local function UpdateSlider(input)
					local percent = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + (max - min) * percent)
					Fill.Size = UDim2.new(percent, 0, 1, 0)
					ValLabel.Text = tostring(val)
					if callback then callback(val) end
				end

				BarBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						UpdateSlider(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						UpdateSlider(input)
					end
				end)
			end

			-- 4. 下拉框 (Dropdown)
			function Section:CreateDropdown(text, options, default, callback)
				local DropFrame = Instance.new("Frame")
				DropFrame.Size = UDim2.new(1, 0, 0, 32)
				DropFrame.BackgroundColor3 = Theme.Sidebar
				DropFrame.ClipsDescendants = true
				DropFrame.Parent = SectionFrame

				local DropCorner = Instance.new("UICorner")
				DropCorner.CornerRadius = UDim.new(0, 6)
				DropCorner.Parent = DropFrame

				local DropBtn = Instance.new("TextButton")
				DropBtn.Size = UDim2.new(1, 0, 0, 32)
				DropBtn.BackgroundTransparency = 1
				DropBtn.Text = "  " .. text .. ": " .. (default or options[1] or "")
				DropBtn.TextColor3 = Theme.Text
				DropBtn.Font = Enum.Font.Gotham
				DropBtn.TextSize = 12
				DropBtn.TextXAlignment = Enum.TextXAlignment.Left
				DropBtn.Parent = DropFrame

				local Arrow = Instance.new("TextLabel")
				Arrow.Size = UDim2.new(0, 30, 0, 32)
				Arrow.Position = UDim2.new(1, -30, 0, 0)
				Arrow.BackgroundTransparency = 1
				Arrow.Text = "▼"
				Arrow.TextColor3 = Theme.SubText
				Arrow.Font = Enum.Font.Gotham
				Arrow.TextSize = 10
				Arrow.Parent = DropFrame

				local OptionContainer = Instance.new("Frame")
				OptionContainer.Size = UDim2.new(1, 0, 0, #options * 25)
				OptionContainer.Position = UDim2.new(0, 0, 0, 32)
				OptionContainer.BackgroundTransparency = 1
				OptionContainer.Parent = DropFrame

				local OptionLayout = Instance.new("UIListLayout")
				OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
				OptionLayout.Parent = OptionContainer

				local expanded = false

				DropBtn.MouseButton1Click:Connect(function()
					expanded = not expanded
					local targetHeight = expanded and (32 + #options * 25) or 32
					Tween(DropFrame, 0.2, {Size = UDim2.new(1, 0, 0, targetHeight)})
					Arrow.Text = expanded and "▲" or "▼"
				end)

				for _, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 25)
					OptBtn.BackgroundColor3 = Theme.Card
					OptBtn.BackgroundTransparency = 0.5
					OptBtn.Text = opt
					OptBtn.TextColor3 = Theme.SubText
					OptBtn.Font = Enum.Font.Gotham
					OptBtn.TextSize = 11
					OptBtn.Parent = OptionContainer

					OptBtn.MouseButton1Click:Connect(function()
						DropBtn.Text = "  " .. text .. ": " .. opt
						expanded = false
						Tween(DropFrame, 0.2, {Size = UDim2.new(1, 0, 0, 32)})
						Arrow.Text = "▼"
						if callback then callback(opt) end
					end)
				end
			end

			return Section
		end

		return Tab
	end

	return Window
end

return XARGUI