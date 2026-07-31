local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local OrionLib = {
	Flags = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(15, 17, 23),
			Second = Color3.fromRGB(24, 28, 38),
			Stroke = Color3.fromRGB(255, 255, 255),
			Divider = Color3.fromRGB(40, 45, 60),
			Text = Color3.fromRGB(240, 243, 250),
			SubText = Color3.fromRGB(135, 142, 165),
			Accent = Color3.fromRGB(99, 102, 241),
			ElementBG = Color3.fromRGB(28, 33, 45),
			ElementHover = Color3.fromRGB(36, 42, 58)
		}
	},
	SelectedTheme = "Default",
	Folder = "OrionConfig",
	SaveEnabled = false,
	SelectedTab = nil,
	TabCount = 0,
	Connections = {}
}

-- [ 背景毛玻璃 Blur 管理 ]
local BlurEffect = Lighting:FindFirstChild("Orion_FrostedBlur") or Instance.new("BlurEffect")
BlurEffect.Name = "Orion_FrostedBlur"
BlurEffect.Size = 0
BlurEffect.Parent = Lighting

local function SetBlur(enabled)
	TweenService:Create(BlurEffect, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = enabled and 16 or 0
	}):Play()
end

-- [ 动画 Utility ]
local function QuickTween(inst, properties, duration, style, dir)
	duration = duration or 0.2
	style = style or Enum.EasingStyle.Cubic
	dir = dir or Enum.EasingDirection.Out
	local tween = TweenService:Create(inst, TweenInfo.new(duration, style, dir), properties)
	tween:Play()
	return tween
end

-- [ ScreenGui 挂载与兼容 ]
local OrionGui = Instance.new("ScreenGui")
OrionGui.Name = "Orion_Modernized"
if syn and syn.protect_gui then
	syn.protect_gui(OrionGui)
	OrionGui.Parent = game:GetService("CoreGui")
elseif gethui then
	OrionGui.Parent = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
	OrionGui.Parent = game:GetService("CoreGui")
else
	OrionGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- [ 窗口平滑拖拽 ]
local function MakeDraggable(topbar, frame)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		}):Play()
	end

	topbar.InputBegan:Connect(function(input)
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

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- [ 配置文件保存逻辑 ]
local function SaveConfig()
	if not OrionLib.SaveEnabled then return end
	if not isfolder or not writefile then return end
	if not isfolder(OrionLib.Folder) then makefolder(OrionLib.Folder) end

	local data = {}
	for flag, obj in pairs(OrionLib.Flags) do
		if type(obj) == "table" and obj.Value ~= nil then
			data[flag] = obj.Value
		else
			data[flag] = obj
		end
	end

	pcall(function()
		writefile(OrionLib.Folder .. "/" .. game.GameId .. ".json", HttpService:JSONEncode(data))
	end)
end

-- [ 创建主窗口 ]
function OrionLib:MakeWindow(Settings)
	Settings = Settings or {}
	local WindowTitle = Settings.Name or "Orion UI Library"
	local ConfigFolder = Settings.ConfigFolder or "OrionConfig"
	OrionLib.SaveEnabled = Settings.SaveConfig or false
	OrionLib.Folder = ConfigFolder

	local Theme = OrionLib.Themes[OrionLib.SelectedTheme]

	-- 主窗口容器（更紧凑精致的 510x320 尺寸）
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 510, 0, 320)
	MainFrame.Position = UDim2.new(0.5, -255, 0.5, -160)
	MainFrame.BackgroundColor3 = Theme.Main
	MainFrame.BackgroundTransparency = 0.25 -- 玻璃半透明效果
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = OrionGui

	-- 入场动画 (Pop-In)
	MainFrame.Position = UDim2.new(0.5, -255, 0.5, -145)
	MainFrame.BackgroundTransparency = 1
	QuickTween(MainFrame, {Position = UDim2.new(0.5, -255, 0.5, -160), BackgroundTransparency = 0.25}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	SetBlur(true)

	-- 柔和圆角与玻璃边框
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 8)
	MainCorner.Parent = MainFrame

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Theme.Stroke
	MainStroke.Transparency = 0.88
	MainStroke.Thickness = 1
	MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MainStroke.Parent = MainFrame

	local MainGradient = Instance.new("UIGradient")
	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 25, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 20))
	})
	MainGradient.Rotation = 45
	MainGradient.Parent = MainFrame

	-- Topbar 顶栏 (高度 32px)
	local Topbar = Instance.new("Frame")
	Topbar.Name = "Topbar"
	Topbar.Size = UDim2.new(1, 0, 0, 32)
	Topbar.BackgroundTransparency = 1
	Topbar.Parent = MainFrame

	MakeDraggable(Topbar, MainFrame)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, -80, 1, 0)
	TitleLabel.Position = UDim2.new(0, 12, 0, 0)
	TitleLabel.Text = WindowTitle
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextSize = 12
	TitleLabel.TextColor3 = Theme.Text
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Parent = Topbar

	-- 右上角控制按钮
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 20, 0, 20)
	CloseBtn.Position = UDim2.new(1, -28, 0.5, -10)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	CloseBtn.BackgroundTransparency = 0.85
	CloseBtn.Text = "✕"
	CloseBtn.TextColor3 = Color3.fromRGB(239, 68, 68)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 10
	CloseBtn.AutoButtonColor = false
	CloseBtn.Parent = Topbar

	local CloseCorner = Instance.new("UICorner")
	CloseCorner.CornerRadius = UDim.new(1, 0)
	CloseCorner.Parent = CloseBtn

	CloseBtn.MouseEnter:Connect(function()
		QuickTween(CloseBtn, {BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
	end)
	CloseBtn.MouseLeave:Connect(function()
		QuickTween(CloseBtn, {BackgroundTransparency = 0.85, TextColor3 = Color3.fromRGB(239, 68, 68)}, 0.15)
	end)
	CloseBtn.MouseButton1Click:Connect(function()
		SetBlur(false)
		QuickTween(MainFrame, {Position = UDim2.new(0.5, -255, 0.5, -140), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
		task.wait(0.25)
		OrionGui:Destroy()
	end)

	-- 分割线
	local TopDivider = Instance.new("Frame")
	TopDivider.Size = UDim2.new(1, -20, 0, 1)
	TopDivider.Position = UDim2.new(0, 10, 0, 32)
	TopDivider.BackgroundColor3 = Theme.Divider
	TopDivider.BorderSizePixel = 0
	TopDivider.Parent = MainFrame

	-- 侧边栏 Sidebar (宽度 125px)
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 125, 1, -38)
	Sidebar.Position = UDim2.new(0, 6, 0, 36)
	Sidebar.BackgroundTransparency = 1
	Sidebar.Parent = MainFrame

	local TabList = Instance.new("UIListLayout")
	TabList.SortOrder = Enum.SortOrder.LayoutOrder
	TabList.Padding = UDim.new(0, 3)
	TabList.Parent = Sidebar

	local SidebarPadding = Instance.new("UIPadding")
	SidebarPadding.PaddingLeft = UDim.new(0, 4)
	SidebarPadding.PaddingRight = UDim.new(0, 4)
	SidebarPadding.PaddingTop = UDim.new(0, 4)
	SidebarPadding.Parent = Sidebar

	-- 内容面板 ContainerHolder
	local ContainerHolder = Instance.new("Frame")
	ContainerHolder.Name = "ContainerHolder"
	ContainerHolder.Size = UDim2.new(1, -140, 1, -40)
	ContainerHolder.Position = UDim2.new(0, 134, 0, 36)
	ContainerHolder.BackgroundTransparency = 1
	ContainerHolder.ClipsDescendants = true
	ContainerHolder.Parent = MainFrame

	local Window = {}

	-- [ 创建 Tab 面板 ]
	function Window:MakeTab(TabSettings)
		TabSettings = TabSettings or {}
		local TabName = TabSettings.Name or "Tab"

		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = TabName .. "_Tab"
		TabBtn.Size = UDim2.new(1, 0, 0, 26)
		TabBtn.BackgroundColor3 = Theme.Second
		TabBtn.BackgroundTransparency = 1
		TabBtn.Text = ""
		TabBtn.AutoButtonColor = false
		TabBtn.Parent = Sidebar

		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 5)
		TabCorner.Parent = TabBtn

		local TabTitle = Instance.new("TextLabel")
		TabTitle.Size = UDim2.new(1, -10, 1, 0)
		TabTitle.Position = UDim2.new(0, 8, 0, 0)
		TabTitle.Text = TabName
		TabTitle.Font = Enum.Font.GothamMedium
		TabTitle.TextSize = 11
		TabTitle.TextColor3 = Theme.SubText
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left
		TabTitle.BackgroundTransparency = 1
		TabTitle.Parent = TabBtn

		local ActiveIndicator = Instance.new("Frame")
		ActiveIndicator.Size = UDim2.new(0, 3, 0, 12)
		ActiveIndicator.Position = UDim2.new(0, 2, 0.5, -6)
		ActiveIndicator.BackgroundColor3 = Theme.Accent
		ActiveIndicator.BackgroundTransparency = 1
		ActiveIndicator.Parent = TabBtn

		local IndicatorCorner = Instance.new("UICorner")
		IndicatorCorner.CornerRadius = UDim.new(1, 0)
		IndicatorCorner.Parent = ActiveIndicator

		local Container = Instance.new("ScrollingFrame")
		Container.Name = TabName .. "_Container"
		Container.Size = UDim2.new(1, 0, 1, 0)
		Container.Position = UDim2.new(0, 0, 0, 0)
		Container.BackgroundTransparency = 1
		Container.Visible = false
		Container.ScrollBarThickness = 2
		Container.ScrollBarImageColor3 = Theme.Accent
		Container.CanvasSize = UDim2.new(0, 0, 0, 0)
		Container.Parent = ContainerHolder

		local ContainerList = Instance.new("UIListLayout")
		ContainerList.SortOrder = Enum.SortOrder.LayoutOrder
		ContainerList.Padding = UDim.new(0, 5)
		ContainerList.Parent = Container

		local ContainerPadding = Instance.new("UIPadding")
		ContainerPadding.PaddingLeft = UDim.new(0, 2)
		ContainerPadding.PaddingRight = UDim.new(0, 8)
		ContainerPadding.PaddingTop = UDim.new(0, 2)
		ContainerPadding.PaddingBottom = UDim.new(0, 6)
		ContainerPadding.Parent = Container

		ContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Container.CanvasSize = UDim2.new(0, 0, 0, ContainerList.AbsoluteContentSize.Y + 12)
		end)

		local function SelectTab()
			for _, child in pairs(Sidebar:GetChildren()) do
				if child:IsA("TextButton") then
					QuickTween(child, {BackgroundTransparency = 1}, 0.2)
					local lbl = child:FindFirstChildOfClass("TextLabel")
					if lbl then QuickTween(lbl, {TextColor3 = Theme.SubText}, 0.2) end
					local ind = child:FindFirstChild("Frame")
					if ind then QuickTween(ind, {BackgroundTransparency = 1}, 0.2) end
				end
			end
			for _, child in pairs(ContainerHolder:GetChildren()) do
				if child:IsA("ScrollingFrame") then
					child.Visible = false
				end
			end

			QuickTween(TabBtn, {BackgroundTransparency = 0.5}, 0.2)
			QuickTween(TabTitle, {TextColor3 = Theme.Text}, 0.2)
			QuickTween(ActiveIndicator, {BackgroundTransparency = 0}, 0.2)

			Container.Position = UDim2.new(0, 0, 0, 6)
			Container.Visible = true
			QuickTween(Container, {Position = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			OrionLib.SelectedTab = Container
		end

		TabBtn.MouseButton1Click:Connect(SelectTab)

		if OrionLib.TabCount == 0 then
			SelectTab()
		end
		OrionLib.TabCount = OrionLib.TabCount + 1

		local Tab = {}

		-- [ 控件：AddSection ]
		function Tab:AddSection(SectionSettings)
			SectionSettings = SectionSettings or {}
			local Name = type(SectionSettings) == "string" and SectionSettings or SectionSettings.Name or "Section"

			local SectionFrame = Instance.new("Frame")
			SectionFrame.Size = UDim2.new(1, 0, 0, 18)
			SectionFrame.BackgroundTransparency = 1
			SectionFrame.Parent = Container

			local SectionLabel = Instance.new("TextLabel")
			SectionLabel.Size = UDim2.new(1, 0, 1, 0)
			SectionLabel.Position = UDim2.new(0, 2, 0, 0)
			SectionLabel.Text = string.upper(Name)
			SectionLabel.Font = Enum.Font.GothamBold
			SectionLabel.TextSize = 10
			SectionLabel.TextColor3 = Theme.Accent
			SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
			SectionLabel.BackgroundTransparency = 1
			SectionLabel.Parent = SectionFrame
		end

		-- [ 控件：AddButton ]
		function Tab:AddButton(BtnSettings)
			BtnSettings = BtnSettings or {}
			local Name = BtnSettings.Name or "Button"
			local Callback = BtnSettings.Callback or function() end

			local ButtonFrame = Instance.new("Frame")
			ButtonFrame.Size = UDim2.new(1, 0, 0, 28)
			ButtonFrame.BackgroundColor3 = Theme.ElementBG
			ButtonFrame.BackgroundTransparency = 0.4
			ButtonFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = ButtonFrame

			local Stroke = Instance.new("UIStroke")
			Stroke.Color = Theme.Stroke
			Stroke.Transparency = 0.92
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			Stroke.Parent = ButtonFrame

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 1, 0)
			Btn.Text = Name
			Btn.Font = Enum.Font.GothamMedium
			Btn.TextSize = 11
			Btn.TextColor3 = Theme.Text
			Btn.BackgroundTransparency = 1
			Btn.AutoButtonColor = false
			Btn.Parent = ButtonFrame

			Btn.MouseEnter:Connect(function()
				QuickTween(ButtonFrame, {BackgroundColor3 = Theme.ElementHover, BackgroundTransparency = 0.2}, 0.15)
				QuickTween(Stroke, {Transparency = 0.75}, 0.15)
			end)
			Btn.MouseLeave:Connect(function()
				QuickTween(ButtonFrame, {BackgroundColor3 = Theme.ElementBG, BackgroundTransparency = 0.4}, 0.15)
				QuickTween(Stroke, {Transparency = 0.92}, 0.15)
			end)
			Btn.MouseButton1Down:Connect(function()
				QuickTween(ButtonFrame, {Size = UDim2.new(1, -2, 0, 26)}, 0.08)
			end)
			Btn.MouseButton1Up:Connect(function()
				QuickTween(ButtonFrame, {Size = UDim2.new(1, 0, 0, 28)}, 0.12, Enum.EasingStyle.Back)
				Callback()
			end)

			return {
				Set = function(self, text) Btn.Text = text end
			}
		end

		-- [ 控件：AddToggle ]
		function Tab:AddToggle(ToggleSettings)
			ToggleSettings = ToggleSettings or {}
			local Name = ToggleSettings.Name or "Toggle"
			local Default = ToggleSettings.Default or false
			local Callback = ToggleSettings.Callback or function() end
			local Flag = ToggleSettings.Flag or Name

			local Toggled = Default

			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Size = UDim2.new(1, 0, 0, 28)
			ToggleFrame.BackgroundColor3 = Theme.ElementBG
			ToggleFrame.BackgroundTransparency = 0.4
			ToggleFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = ToggleFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -45, 1, 0)
			Label.Position = UDim2.new(0, 8, 0, 0)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = ToggleFrame

			local SwitchTrack = Instance.new("Frame")
			SwitchTrack.Size = UDim2.new(0, 30, 0, 15)
			SwitchTrack.Position = UDim2.new(1, -36, 0.5, -7.5)
			SwitchTrack.BackgroundColor3 = Toggled and Theme.Accent or Color3.fromRGB(45, 50, 65)
			SwitchTrack.Parent = ToggleFrame

			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(1, 0)
			TrackCorner.Parent = SwitchTrack

			local SwitchKnob = Instance.new("Frame")
			SwitchKnob.Size = UDim2.new(0, 11, 0, 11)
			SwitchKnob.Position = Toggled and UDim2.new(1, -13, 0.5, -5.5) or UDim2.new(0, 2, 0.5, -5.5)
			SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SwitchKnob.Parent = SwitchTrack

			local KnobCorner = Instance.new("UICorner")
			KnobCorner.CornerRadius = UDim.new(1, 0)
			KnobCorner.Parent = SwitchKnob

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 1, 0)
			Btn.Text = ""
			Btn.BackgroundTransparency = 1
			Btn.Parent = ToggleFrame

			local function SetState(val)
				Toggled = val
				OrionLib.Flags[Flag] = Toggled
				if Toggled then
					QuickTween(SwitchTrack, {BackgroundColor3 = Theme.Accent}, 0.2)
					QuickTween(SwitchKnob, {Position = UDim2.new(1, -13, 0.5, -5.5)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				else
					QuickTween(SwitchTrack, {BackgroundColor3 = Color3.fromRGB(45, 50, 65)}, 0.2)
					QuickTween(SwitchKnob, {Position = UDim2.new(0, 2, 0.5, -5.5)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
				SaveConfig()
				Callback(Toggled)
			end

			Btn.MouseButton1Click:Connect(function()
				SetState(not Toggled)
			end)

			OrionLib.Flags[Flag] = Toggled

			return {
				Set = function(self, val) SetState(val) end
			}
		end

		-- [ 控件：AddSlider ]
		function Tab:AddSlider(SliderSettings)
			SliderSettings = SliderSettings or {}
			local Name = SliderSettings.Name or "Slider"
			local Min = SliderSettings.Min or 0
			local Max = SliderSettings.Max or 100
			local Default = SliderSettings.Default or Min
			local Increment = SliderSettings.Increment or 1
			local ValueName = SliderSettings.ValueName or ""
			local Callback = SliderSettings.Callback or function() end
			local Flag = SliderSettings.Flag or Name

			local SliderFrame = Instance.new("Frame")
			SliderFrame.Size = UDim2.new(1, 0, 0, 38)
			SliderFrame.BackgroundColor3 = Theme.ElementBG
			SliderFrame.BackgroundTransparency = 0.4
			SliderFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = SliderFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.6, 0, 0, 18)
			Label.Position = UDim2.new(0, 8, 0, 2)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = SliderFrame

			local ValLabel = Instance.new("TextLabel")
			ValLabel.Size = UDim2.new(0.35, 0, 0, 18)
			ValLabel.Position = UDim2.new(0.65, -8, 0, 2)
			ValLabel.Text = tostring(Default) .. " " .. ValueName
			ValLabel.Font = Enum.Font.Gotham
			ValLabel.TextSize = 10
			ValLabel.TextColor3 = Theme.SubText
			ValLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValLabel.BackgroundTransparency = 1
			ValLabel.Parent = SliderFrame

			local SliderBar = Instance.new("Frame")
			SliderBar.Size = UDim2.new(1, -16, 0, 4)
			SliderBar.Position = UDim2.new(0, 8, 0, 24)
			SliderBar.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
			SliderBar.Parent = SliderFrame

			local BarCorner = Instance.new("UICorner")
			BarCorner.CornerRadius = UDim.new(1, 0)
			BarCorner.Parent = SliderBar

			local SliderFill = Instance.new("Frame")
			SliderFill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
			SliderFill.BackgroundColor3 = Theme.Accent
			SliderFill.Parent = SliderBar

			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = SliderFill

			local Sliding = false

			local function UpdateSlider(input)
				local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
				local rawVal = Min + (Max - Min) * pos
				local val = math.floor(rawVal / Increment + 0.5) * Increment
				val = math.clamp(val, Min, Max)

				SliderFill.Size = UDim2.new((val - Min) / (Max - Min), 0, 1, 0)
				ValLabel.Text = tostring(val) .. " " .. ValueName
				OrionLib.Flags[Flag] = val
				SaveConfig()
				Callback(val)
			end

			SliderBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Sliding = true
					UpdateSlider(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if Sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(input)
				end
			end)

			return {
				Set = function(self, val)
					val = math.clamp(val, Min, Max)
					SliderFill.Size = UDim2.new((val - Min) / (Max - Min), 0, 1, 0)
					ValLabel.Text = tostring(val) .. " " .. ValueName
					OrionLib.Flags[Flag] = val
					Callback(val)
				end
			}
		end

		-- [ 控件：AddDropdown ]
		function Tab:AddDropdown(DropdownSettings)
			DropdownSettings = DropdownSettings or {}
			local Name = DropdownSettings.Name or "Dropdown"
			local Options = DropdownSettings.Options or {}
			local Default = DropdownSettings.Default or Options[1] or ""
			local Callback = DropdownSettings.Callback or function() end
			local Flag = DropdownSettings.Flag or Name

			local Expanded = false

			local DropdownFrame = Instance.new("Frame")
			DropdownFrame.Size = UDim2.new(1, 0, 0, 28)
			DropdownFrame.BackgroundColor3 = Theme.ElementBG
			DropdownFrame.BackgroundTransparency = 0.4
			DropdownFrame.ClipsDescendants = true
			DropdownFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = DropdownFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.5, 0, 0, 28)
			Label.Position = UDim2.new(0, 8, 0, 0)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = DropdownFrame

			local SelectedText = Instance.new("TextLabel")
			SelectedText.Size = UDim2.new(0.45, 0, 0, 28)
			SelectedText.Position = UDim2.new(0.55, -10, 0, 0)
			SelectedText.Text = tostring(Default) .. "  ▼"
			SelectedText.Font = Enum.Font.Gotham
			SelectedText.TextSize = 10
			SelectedText.TextColor3 = Theme.SubText
			SelectedText.TextXAlignment = Enum.TextXAlignment.Right
			SelectedText.BackgroundTransparency = 1
			SelectedText.Parent = DropdownFrame

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 28)
			Btn.Text = ""
			Btn.BackgroundTransparency = 1
			Btn.Parent = DropdownFrame

			local OptionHolder = Instance.new("Frame")
			OptionHolder.Size = UDim2.new(1, -12, 0, 0)
			OptionHolder.Position = UDim2.new(0, 6, 0, 30)
			OptionHolder.BackgroundTransparency = 1
			OptionHolder.Parent = DropdownFrame

			local OptionList = Instance.new("UIListLayout")
			OptionList.SortOrder = Enum.SortOrder.LayoutOrder
			OptionList.Padding = UDim.new(0, 3)
			OptionList.Parent = OptionHolder

			local function RebuildOptions(opts)
				for _, c in pairs(OptionHolder:GetChildren()) do
					if c:IsA("TextButton") then c:Destroy() end
				end
				for _, opt in ipairs(opts) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 22)
					OptBtn.BackgroundColor3 = Theme.Second
					OptBtn.Text = tostring(opt)
					OptBtn.Font = Enum.Font.Gotham
					OptBtn.TextSize = 10
					OptBtn.TextColor3 = Theme.SubText
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionHolder

					local OptCorner = Instance.new("UICorner")
					OptCorner.CornerRadius = UDim.new(0, 4)
					OptCorner.Parent = OptBtn

					OptBtn.MouseButton1Click:Connect(function()
						SelectedText.Text = tostring(opt) .. "  ▼"
						OrionLib.Flags[Flag] = opt
						SaveConfig()
						Callback(opt)
						Expanded = false
						QuickTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 28)}, 0.2)
					end)
				end
			end

			RebuildOptions(Options)

			Btn.MouseButton1Click:Connect(function()
				Expanded = not Expanded
				if Expanded then
					local targetH = 34 + (#Options * 25)
					QuickTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, math.min(targetH, 150))}, 0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				else
					QuickTween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 28)}, 0.2)
				end
			end)

			return {
				Refresh = function(self, newOpts, newDef)
					Options = newOpts or {}
					RebuildOptions(Options)
					if newDef then
						SelectedText.Text = tostring(newDef) .. "  ▼"
						OrionLib.Flags[Flag] = newDef
						Callback(newDef)
					end
				end,
				Set = function(self, opt)
					SelectedText.Text = tostring(opt) .. "  ▼"
					OrionLib.Flags[Flag] = opt
					Callback(opt)
				end
			}
		end

		-- [ 控件：AddBind ]
		function Tab:AddBind(BindSettings)
			BindSettings = BindSettings or {}
			local Name = BindSettings.Name or "Keybind"
			local Default = BindSettings.Default or Enum.KeyCode.E
			local Callback = BindSettings.Callback or function() end
			local Flag = BindSettings.Flag or Name

			local CurrentBind = Default
			local Binding = false

			local BindFrame = Instance.new("Frame")
			BindFrame.Size = UDim2.new(1, 0, 0, 28)
			BindFrame.BackgroundColor3 = Theme.ElementBG
			BindFrame.BackgroundTransparency = 0.4
			BindFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = BindFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.6, 0, 1, 0)
			Label.Position = UDim2.new(0, 8, 0, 0)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = BindFrame

			local BindBtn = Instance.new("TextButton")
			BindBtn.Size = UDim2.new(0, 60, 0, 20)
			BindBtn.Position = UDim2.new(1, -68, 0.5, -10)
			BindBtn.BackgroundColor3 = Theme.Second
			BindBtn.Text = CurrentBind.Name or "None"
			BindBtn.Font = Enum.Font.Gotham
			BindBtn.TextSize = 10
			BindBtn.TextColor3 = Theme.SubText
			BindBtn.AutoButtonColor = false
			BindBtn.Parent = BindFrame

			local BtnCorner = Instance.new("UICorner")
			BtnCorner.CornerRadius = UDim.new(0, 4)
			BtnCorner.Parent = BindBtn

			BindBtn.MouseButton1Click:Connect(function()
				Binding = true
				BindBtn.Text = "..."
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe then return end
				if Binding then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						CurrentBind = input.KeyCode
						BindBtn.Text = CurrentBind.Name
						Binding = false
						OrionLib.Flags[Flag] = CurrentBind
						SaveConfig()
					end
				elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CurrentBind then
					Callback()
				end
			end)

			return {
				Set = function(self, key)
					CurrentBind = key
					BindBtn.Text = CurrentBind.Name
					OrionLib.Flags[Flag] = CurrentBind
				end
			}
		end

		-- [ 控件：AddColorpicker ]
		function Tab:AddColorpicker(ColorSettings)
			ColorSettings = ColorSettings or {}
			local Name = ColorSettings.Name or "Colorpicker"
			local Default = ColorSettings.Default or Color3.fromRGB(255, 255, 255)
			local Callback = ColorSettings.Callback or function() end
			local Flag = ColorSettings.Flag or Name

			local ColorFrame = Instance.new("Frame")
			ColorFrame.Size = UDim2.new(1, 0, 0, 28)
			ColorFrame.BackgroundColor3 = Theme.ElementBG
			ColorFrame.BackgroundTransparency = 0.4
			ColorFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = ColorFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.6, 0, 1, 0)
			Label.Position = UDim2.new(0, 8, 0, 0)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = ColorFrame

			local Preview = Instance.new("Frame")
			Preview.Size = UDim2.new(0, 24, 0, 16)
			Preview.Position = UDim2.new(1, -32, 0.5, -8)
			Preview.BackgroundColor3 = Default
			Preview.Parent = ColorFrame

			local PreviewCorner = Instance.new("UICorner")
			PreviewCorner.CornerRadius = UDim.new(0, 4)
			PreviewCorner.Parent = Preview

			OrionLib.Flags[Flag] = Default
			Callback(Default)

			return {
				Set = function(self, color)
					Preview.BackgroundColor3 = color
					OrionLib.Flags[Flag] = color
					Callback(color)
				end
			}
		end

		-- [ 控件：AddTextbox ]
		function Tab:AddTextbox(BoxSettings)
			BoxSettings = BoxSettings or {}
			local Name = BoxSettings.Name or "Textbox"
			local Default = BoxSettings.Default or ""
			local TextDisappear = BoxSettings.TextDisappear or false
			local Callback = BoxSettings.Callback or function() end

			local BoxFrame = Instance.new("Frame")
			BoxFrame.Size = UDim2.new(1, 0, 0, 30)
			BoxFrame.BackgroundColor3 = Theme.ElementBG
			BoxFrame.BackgroundTransparency = 0.4
			BoxFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = BoxFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.5, 0, 1, 0)
			Label.Position = UDim2.new(0, 8, 0, 0)
			Label.Text = Name
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = BoxFrame

			local InputBox = Instance.new("TextBox")
			InputBox.Size = UDim2.new(0.45, 0, 0, 20)
			InputBox.Position = UDim2.new(0.53, 0, 0.5, -10)
			InputBox.BackgroundColor3 = Theme.Second
			InputBox.Text = Default
			InputBox.Font = Enum.Font.Gotham
			InputBox.TextSize = 10
			InputBox.TextColor3 = Theme.Text
			InputBox.Parent = BoxFrame

			local BoxCorner = Instance.new("UICorner")
			BoxCorner.CornerRadius = UDim.new(0, 4)
			BoxCorner.Parent = InputBox

			InputBox.FocusLost:Connect(function()
				Callback(InputBox.Text)
				if TextDisappear then InputBox.Text = "" end
			end)

			return {
				Set = function(self, text)
					InputBox.Text = text
					Callback(text)
				end
			}
		end

		-- [ 控件：AddLabel ]
		function Tab:AddLabel(Text)
			local LabelFrame = Instance.new("Frame")
			LabelFrame.Size = UDim2.new(1, 0, 0, 20)
			LabelFrame.BackgroundTransparency = 1
			LabelFrame.Parent = Container

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -8, 1, 0)
			Label.Position = UDim2.new(0, 4, 0, 0)
			Label.Text = Text
			Label.Font = Enum.Font.GothamMedium
			Label.TextSize = 11
			Label.TextColor3 = Theme.SubText
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.BackgroundTransparency = 1
			Label.Parent = LabelFrame

			return {
				Set = function(self, newText) Label.Text = newText end
			}
		end

		-- [ 控件：AddParagraph ]
		function Tab:AddParagraph(Title, Content)
			Title = Title or "Paragraph"
			Content = Content or ""

			local ParaFrame = Instance.new("Frame")
			ParaFrame.Size = UDim2.new(1, 0, 0, 45)
			ParaFrame.BackgroundColor3 = Theme.ElementBG
			ParaFrame.BackgroundTransparency = 0.5
			ParaFrame.Parent = Container

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 5)
			Corner.Parent = ParaFrame

			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, -12, 0, 18)
			TitleLabel.Position = UDim2.new(0, 6, 0, 2)
			TitleLabel.Text = Title
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.TextSize = 11
			TitleLabel.TextColor3 = Theme.Text
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Parent = ParaFrame

			local ContentLabel = Instance.new("TextLabel")
			ContentLabel.Size = UDim2.new(1, -12, 0, 22)
			ContentLabel.Position = UDim2.new(0, 6, 0, 20)
			ContentLabel.Text = Content
			ContentLabel.Font = Enum.Font.Gotham
			ContentLabel.TextSize = 10
			ContentLabel.TextColor3 = Theme.SubText
			ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
			ContentLabel.TextWrapped = true
			ContentLabel.BackgroundTransparency = 1
			ContentLabel.Parent = ParaFrame

			return {
				Set = function(self, newTitle, newContent)
					TitleLabel.Text = newTitle
					ContentLabel.Text = newContent
				end
			}
		end

		return Tab
	end

	return Window
end

-- [ 浮动通知 OrionLib:MakeNotification ]
function OrionLib:MakeNotification(NotifSettings)
	NotifSettings = NotifSettings or {}
	local Title = NotifSettings.Name or "Notification"
	local Content = NotifSettings.Content or ""
	local Time = NotifSettings.Time or 3

	local Theme = OrionLib.Themes[OrionLib.SelectedTheme]

	local NotifFrame = Instance.new("Frame")
	NotifFrame.Size = UDim2.new(0, 210, 0, 48)
	NotifFrame.Position = UDim2.new(1, 10, 1, -65)
	NotifFrame.BackgroundColor3 = Theme.Main
	NotifFrame.BackgroundTransparency = 0.2
	NotifFrame.Parent = OrionGui

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = NotifFrame

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Theme.Accent
	Stroke.Transparency = 0.6
	Stroke.Parent = NotifFrame

	local NotifTitle = Instance.new("TextLabel")
	NotifTitle.Size = UDim2.new(1, -16, 0, 18)
	NotifTitle.Position = UDim2.new(0, 8, 0, 4)
	NotifTitle.Text = Title
	NotifTitle.Font = Enum.Font.GothamBold
	NotifTitle.TextSize = 11
	NotifTitle.TextColor3 = Theme.Text
	NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
	NotifTitle.BackgroundTransparency = 1
	NotifTitle.Parent = NotifFrame

	local NotifContent = Instance.new("TextLabel")
	NotifContent.Size = UDim2.new(1, -16, 0, 20)
	NotifContent.Position = UDim2.new(0, 8, 0, 22)
	NotifContent.Text = Content
	NotifContent.Font = Enum.Font.Gotham
	NotifContent.TextSize = 10
	NotifContent.TextColor3 = Theme.SubText
	NotifContent.TextXAlignment = Enum.TextXAlignment.Left
	NotifContent.BackgroundTransparency = 1
	NotifContent.Parent = NotifFrame

	QuickTween(NotifFrame, {Position = UDim2.new(1, -220, 1, -65)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(Time, function()
		QuickTween(NotifFrame, {Position = UDim2.new(1, 10, 1, -65)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.3)
		NotifFrame:Destroy()
	end)
end

function OrionLib:Init() end

function OrionLib:Destroy()
	SetBlur(false)
	OrionGui:Destroy()
end

return OrionLib
