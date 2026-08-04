-- [[ XARG UI Library ]] --
local XARGUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- 配色方案
local Colors = {
	Background = Color3.fromRGB(30, 30, 30),
	Sidebar = Color3.fromRGB(20, 20, 20),
	Accent = Color3.fromRGB(46, 204, 113), -- 绿色
	Text = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(100, 100, 100)
}

-- 创建主窗口
function XARGUI:CreateWindow(title)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "XARGUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 450, 0, 700)
	MainFrame.Position = UDim2.new(0.5, -225, 0.5, -350)
	MainFrame.BackgroundColor3 = Colors.Background
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.Parent = ScreenGui
	
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 12)
	MainCorner.Parent = MainFrame

	-- 侧边栏
	local Sidebar = Instance.new("Frame")
	Sidebar.Size = UDim2.new(0, 60, 0, 700)
	Sidebar.BackgroundColor3 = Colors.Sidebar
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame
	
	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 12)
	SidebarCorner.Parent = Sidebar
	
	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 10)
	UIListLayout.Parent = Sidebar

	local Window = {
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		Sidebar = Sidebar,
		CurrentTab = nil,
		Tabs = {}
	}

	function Window:CreateTab(name, icon)
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, 0, 0, 50)
		TabButton.BackgroundTransparency = 1
		TabButton.Text = name:sub(1, 1) or "?"
		TabButton.TextColor3 = Colors.Gray
		TabButton.Font = Enum.Font.GothamBold
		TabButton.TextSize = 20
		TabButton.Parent = Sidebar

		local TabContainer = Instance.new("ScrollingFrame")
		TabContainer.Size = UDim2.new(1, -70, 1, -20)
		TabContainer.Position = UDim2.new(0, 70, 0, 10)
		TabContainer.BackgroundTransparency = 1
		TabContainer.BorderSizePixel = 0
		TabContainer.ScrollBarThickness = 0
		TabContainer.Visible = false
		TabContainer.Parent = MainFrame
		
		local TabLayout = Instance.new("UIListLayout")
		TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		TabLayout.Padding = UDim.new(0, 15)
		TabLayout.Parent = TabContainer
		
		local Padding = Instance.new("UIPadding")
		Padding.PaddingTop = UDim.new(0, 20)
		Padding.PaddingLeft = UDim.new(0, 20)
		Padding.PaddingRight = UDim.new(0, 20)
		Padding.Parent = TabContainer

		local Tab = {
			Container = TabContainer,
			Button = TabButton
		}

		TabButton.MouseButton1Click:Connect(function()
			if Window.CurrentTab then
				Window.CurrentTab.Container.Visible = false
				Window.CurrentTab.Button.TextColor3 = Colors.Gray
			end
			Window.CurrentTab = Tab
			TabContainer.Visible = true
			TabButton.TextColor3 = Colors.Accent
		end)

		-- 默认显示第一个 Tab
		if #Window.Tabs == 0 then
			TabContainer.Visible = true
			TabButton.TextColor3 = Colors.Accent
			Window.CurrentTab = Tab
		end
		table.insert(Window.Tabs, Tab)

		-- 1. 创建普通 Toggle (iOS 滑动开关)
		function Tab:CreateToggle(config)
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
			ToggleFrame.BackgroundTransparency = 1
			ToggleFrame.Parent = TabContainer

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0, 250, 1, 0)
			Label.Position = UDim2.new(0, 0, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = config.Text or "Toggle"
			Label.TextColor3 = Color3.fromRGB(220, 220, 220)
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = ToggleFrame

			local SwitchBg = Instance.new("Frame")
			SwitchBg.Size = UDim2.new(0, 50, 0, 28)
			SwitchBg.Position = UDim2.new(1, 0, 0.5, -14)
			SwitchBg.BackgroundColor3 = Colors.Gray
			SwitchBg.Parent = ToggleFrame
			
			local SwitchCorner = Instance.new("UICorner")
			SwitchCorner.CornerRadius = UDim.new(1, 0)
			SwitchCorner.Parent = SwitchBg

			local SwitchKnob = Instance.new("Frame")
			SwitchKnob.Size = UDim2.new(0, 22, 0, 22)
			SwitchKnob.Position = UDim2.new(0, 3, 0.5, -11)
			SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SwitchKnob.Parent = SwitchBg
			
			local KnobCorner = Instance.new("UICorner")
			KnobCorner.CornerRadius = UDim.new(1, 0)
			KnobCorner.Parent = SwitchKnob

			local State = config.Default or false
			if State then
				SwitchBg.BackgroundColor3 = Colors.Accent
				SwitchKnob.Position = UDim2.new(1, -25, 0.5, -11)
			end

			local ToggleObj = {Value = State}
			SwitchBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					State = not State
					ToggleObj.Value = State
					if State then
						TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent}):Play()
						TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -25, 0.5, -11)}):Play()
					else
						TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Gray}):Play()
						TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -11)}):Play()
					end
					if config.Callback then config.Callback(State) end
				end
			end)
			return ToggleObj
		end

		-- 2. 创建正方形 Toggle (复选框)
		function Tab:CreateCheckbox(config)
			local CheckFrame = Instance.new("Frame")
			CheckFrame.Size = UDim2.new(1, 0, 0, 40)
			CheckFrame.BackgroundTransparency = 1
			CheckFrame.Parent = TabContainer

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0, 250, 1, 0)
			Label.Position = UDim2.new(0, 0, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = config.Text or "Checkbox"
			Label.TextColor3 = Color3.fromRGB(220, 220, 220)
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = CheckFrame

			local Box = Instance.new("Frame")
			Box.Size = UDim2.new(0, 20, 0, 20)
			Box.Position = UDim2.new(1, 0, 0.5, -10)
			Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			Box.BorderColor3 = Colors.Gray
			Box.Parent = CheckFrame
			
			local BoxCorner = Instance.new("UICorner")
			BoxCorner.CornerRadius = UDim.new(0, 4)
			BoxCorner.Parent = Box

			local State = config.Default or false
			if State then
				Box.BackgroundColor3 = Colors.Accent
				Box.BorderColor3 = Colors.Accent
			end

			local CheckObj = {Value = State}
			Box.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					State = not State
					CheckObj.Value = State
					if State then
						TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent, BorderColor3 = Colors.Accent}):Play()
					else
						TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40), BorderColor3 = Colors.Gray}):Play()
					end
					if config.Callback then config.Callback(State) end
				end
			end)
			return CheckObj
		end

		-- 3. 创建圆形 Toggle (单选按钮组)
		function Tab:CreateRadioGroup(config)
			local GroupFrame = Instance.new("Frame")
			GroupFrame.Size = UDim2.new(1, 0, 0, 40 + (#config.Options * 25))
			GroupFrame.BackgroundTransparency = 1
			GroupFrame.Parent = TabContainer

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, 0, 0, 25)
			Label.Position = UDim2.new(0, 0, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = config.Text or "Radio Group"
			Label.TextColor3 = Color3.fromRGB(180, 180, 180)
			Label.Font = Enum.Font.GothamBold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = GroupFrame
			
			local GroupLayout = Instance.new("UIListLayout")
			GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
			GroupLayout.Padding = UDim.new(0, 8)
			GroupLayout.Parent = GroupFrame

			local RadioGroup = {Options = {}}
			local SelectedValue = config.Default or config.Options[1] or ""

			for i, optionText in ipairs(config.Options) do
				local OptionFrame = Instance.new("Frame")
				OptionFrame.Size = UDim2.new(1, 0, 0, 20)
				OptionFrame.BackgroundTransparency = 1
				OptionFrame.Parent = GroupFrame

				local RadioBtn = Instance.new("Frame")
				RadioBtn.Size = UDim2.new(0, 18, 0, 18)
				RadioBtn.Position = UDim2.new(1, 0, 0, 0)
				RadioBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				RadioBtn.BorderSizePixel = 0
				RadioBtn.Parent = OptionFrame
				
				local RadioCorner = Instance.new("UICorner")
				RadioCorner.CornerRadius = UDim.new(1, 0)
				RadioCorner.Parent = RadioBtn

				local InnerDot = Instance.new("Frame")
				InnerDot.Size = UDim2.new(0, 8, 0, 8)
				InnerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
				InnerDot.BackgroundColor3 = Colors.Accent
				InnerDot.BorderSizePixel = 0
				
				local DotCorner = Instance.new("UICorner")
				DotCorner.CornerRadius = UDim.new(1, 0)
				DotCorner.Parent = InnerDot

				local OptionLabel = Instance.new("TextLabel")
				OptionLabel.Size = UDim2.new(1, -30, 1, 0)
				OptionLabel.Position = UDim2.new(0, 0, 0, 0)
				OptionLabel.BackgroundTransparency = 1
				OptionLabel.Text = optionText
				OptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				OptionLabel.Font = Enum.Font.Gotham
				OptionLabel.TextSize = 13
				OptionLabel.TextXAlignment = Enum.TextXAlignment.Right
				OptionLabel.Parent = OptionFrame

				local isSelected = (optionText == SelectedValue)
				if isSelected then
					InnerDot.Parent = RadioBtn
				else
					InnerDot.Parent = nil
				end

				RadioBtn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						SelectedValue = optionText
						RadioGroup.Value = SelectedValue
						for _, otherBtn in pairs(RadioGroup.Options) do
							if otherBtn ~= RadioBtn then
								local oldDot = otherBtn:FindFirstChild("InnerDot")
								if oldDot then oldDot.Parent = nil end
							end
						end
						InnerDot.Parent = RadioBtn
						
						if config.Callback then config.Callback(SelectedValue) end
					end
				end)
				table.insert(RadioGroup.Options, RadioBtn)
			end
			return RadioGroup
		end

		-- 4. 创建拉条 (滑块)
		function Tab:CreateSlider(config)
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Size = UDim2.new(1, 0, 0, 45)
			SliderFrame.BackgroundTransparency = 1
			SliderFrame.Parent = TabContainer

			local TopInfo = Instance.new("Frame")
			TopInfo.Size = UDim2.new(1, 0, 0, 20)
			TopInfo.BackgroundTransparency = 1
			TopInfo.Parent = SliderFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0, 250, 1, 0)
			Label.BackgroundTransparency = 1
			Label.Text = config.Text or "Slider"
			Label.TextColor3 = Color3.fromRGB(220, 220, 220)
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = TopInfo

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Size = UDim2.new(0, 50, 1, 0)
			ValueLabel.Position = UDim2.new(1, -50, 0, 0)
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Text = tostring(config.Default or 0)
			ValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			ValueLabel.Font = Enum.Font.Gotham
			ValueLabel.TextSize = 13
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.Parent = TopInfo

			local SliderBg = Instance.new("Frame")
			SliderBg.Size = UDim2.new(1, 0, 0, 6)
			SliderBg.Position = UDim2.new(0, 0, 1, -6)
			SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			SliderBg.Parent = SliderFrame
			
			local BgCorner = Instance.new("UICorner")
			BgCorner.CornerRadius = UDim.new(1, 0)
			BgCorner.Parent = SliderBg

			local FillBar = Instance.new("Frame")
			FillBar.Size = UDim2.new(0, 0, 1, 0)
			FillBar.BackgroundColor3 = Colors.Accent
			FillBar.Parent = SliderBg
			
			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = FillBar

			local DragBtn = Instance.new("Frame")
			DragBtn.Size = UDim2.new(0, 16, 0, 16)
			DragBtn.Position = UDim2.new(0, 0, 0.5, -8)
			DragBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DragBtn.Parent = SliderFrame
			
			local BtnCorner = Instance.new("UICorner")
			BtnCorner.CornerRadius = UDim.new(1, 0)
			BtnCorner.Parent = DragBtn

			local Min = config.Min or 0
			local Max = config.Max or 100
			local Value = config.Default or Min

			local SliderObj = {Value = Value}
			local dragging = false

			local function UpdateSlider(input)
				local X = math.clamp(input.Position.X - SliderBg.AbsolutePosition.X, 0, SliderBg.AbsoluteSize.X)
				local percent = X / SliderBg.AbsoluteSize.X
				Value = math.floor(((Max - Min) * percent) + Min)
				
				FillBar.Size = UDim2.new(percent, 0, 1, 0)
				DragBtn.Position = UDim2.new(percent, -8, 0.5, -8)
				ValueLabel.Text = tostring(Value)
				SliderObj.Value = Value
				if config.Callback then config.Callback(Value) end
			end

			-- 默认初始化一次
			local initPercent = (Value - Min) / (Max - Min)
			FillBar.Size = UDim2.new(initPercent, 0, 1, 0)
			DragBtn.Position = UDim2.new(initPercent, -8, 0.5, -8)

			DragBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
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

			SliderBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					UpdateSlider(input)
				end
			end)

			return SliderObj
		end

		return Tab
	end

	return Window
end

return XARGUI