--[[
	ImguiLibrary v1.0 - 单文件完整版
	用法: loadstring(game:HttpGet("URL"))()
	或者直接复制粘贴到 Roblox Studio
	
	作者: AI Assistant
	GitHub: wc5789/AINNN
]]

-- 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ============================================================
-- 主题系统
-- ============================================================
local ImGuiStyle = {}
ImGuiStyle.__index = ImGuiStyle

local DefaultTheme = {
	Window = {
		BackgroundColor = Color3.fromRGB(45, 45, 48),
		TitleBarColor = Color3.fromRGB(54, 54, 57),
		BorderColor = Color3.fromRGB(65, 65, 68),
		ShadowColor = Color3.fromRGB(0, 0, 0),
		TitleTextColor = Color3.fromRGB(225, 225, 225),
		MinimizeButtonColor = Color3.fromRGB(180, 180, 180),
		MinimizeButtonHoverColor = Color3.fromRGB(220, 220, 220),
	},
	Content = {
		BackgroundColor = Color3.fromRGB(30, 30, 30),
		DividerColor = Color3.fromRGB(55, 55, 58),
		ScrollBarColor = Color3.fromRGB(65, 65, 68),
		ScrollBarThumbColor = Color3.fromRGB(90, 90, 92),
	},
	Row = {
		BackgroundColor = Color3.fromRGB(38, 38, 40),
		HoverColor = Color3.fromRGB(52, 52, 55),
		PressedColor = Color3.fromRGB(32, 32, 34),
		SelectedColor = Color3.fromRGB(200, 200, 205),
		TextColor = Color3.fromRGB(210, 210, 215),
		SelectedTextColor = Color3.fromRGB(25, 25, 27),
		SecondaryTextColor = Color3.fromRGB(145, 145, 150),
		ActionIndicatorColor = Color3.fromRGB(130, 130, 135),
	},
	Slider = {
		TrackColor = Color3.fromRGB(70, 70, 73),
		TrackFillColor = Color3.fromRGB(160, 160, 165),
		ThumbColor = Color3.fromRGB(230, 230, 235),
		ThumbSize = 14,
		TrackHeight = 4,
		MarkerColor = Color3.fromRGB(100, 100, 103),
		MarkerCount = 5,
		LabelTextColor = Color3.fromRGB(195, 195, 200),
		ValueTextColor = Color3.fromRGB(210, 210, 215),
	},
	Toggle = {
		OffTrackColor = Color3.fromRGB(70, 70, 73),
		OffThumbColor = Color3.fromRGB(230, 230, 235),
		OnTrackColor = Color3.fromRGB(130, 130, 135),
		OnThumbColor = Color3.fromRGB(25, 25, 27),
		TrackWidth = 40,
		TrackHeight = 18,
		ThumbSize = 12,
	},
	Button = {
		BackgroundColor = Color3.fromRGB(55, 55, 58),
		HoverColor = Color3.fromRGB(70, 70, 73),
		PressedColor = Color3.fromRGB(45, 45, 48),
		BorderColor = Color3.fromRGB(80, 80, 83),
		TextColor = Color3.fromRGB(210, 210, 215),
		CornerRadius = 4,
	},
	Dropdown = {
		BackgroundColor = Color3.fromRGB(38, 38, 40),
		HoverColor = Color3.fromRGB(52, 52, 55),
		SelectedColor = Color3.fromRGB(65, 65, 68),
		BorderColor = Color3.fromRGB(65, 65, 68),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(160, 160, 165),
		CornerRadius = 4,
	},
	Section = {
		BackgroundColor = Color3.fromRGB(42, 42, 44),
		ExpandedColor = Color3.fromRGB(48, 48, 50),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(150, 150, 155),
		CornerRadius = 4,
		ExpandDuration = 0.2,
	},
	Label = {
		PrimaryTextColor = Color3.fromRGB(210, 210, 215),
		SecondaryTextColor = Color3.fromRGB(145, 145, 150),
	},
	Typography = {
		WindowTitleSize = 14,
		WindowTitleFont = Enum.Font.GothamMedium,
		LabelSize = 13,
		LabelFont = Enum.Font.Gotham,
		SecondaryLabelSize = 11,
		SecondaryLabelFont = Enum.Font.Gotham,
		ValueSize = 12,
		ValueFont = Enum.Font.Gotham,
		ButtonSize = 13,
		ButtonFont = Enum.Font.GothamMedium,
	},
	Spacing = {
		WindowPadding = 12,
		WindowTitleBarHeight = 32,
		WindowCornerRadius = 6,
		WindowBorderSize = 1,
		RowHeight = 32,
		RowPadding = 10,
		RowSpacing = 2,
		ComponentSpacing = 8,
		SectionSpacing = 6,
		IconSize = 16,
		MinimizeButtonSize = 12,
		ActionIndicatorSize = 16,
		DropdownArrowSize = 10,
		BorderSize = 1,
	},
	Shadow = {
		Enabled = true,
		Color = Color3.fromRGB(0, 0, 0),
		Offset = Vector2.new(0, 4),
		Size = 12,
		Transparency = 0.4,
		PopupShadowTransparency = 0.35,
		PopupShadowSize = 16,
	},
	Animation = {
		WindowOpenDuration = 0.25,
		WindowCloseDuration = 0.2,
		MinimizeDuration = 0.15,
		HoverDuration = 0.1,
		PressedDuration = 0.08,
		ToggleDuration = 0.15,
		SectionExpandDuration = 0.2,
		DropdownDuration = 0.15,
		EasingStyle = Enum.EasingStyle.Quad,
		OpenDirection = Enum.EasingDirection.Out,
		CloseDirection = Enum.EasingDirection.In,
	},
	Accent = {
		Enabled = false,
		Color = Color3.fromRGB(86, 151, 232),
	},
	Responsive = {
		MinScale = 0.7,
		MaxScale = 1.5,
		DefaultScale = 1.0,
	},
}

function ImGuiStyle.new(overrides)
	local self = setmetatable({}, ImGuiStyle)
	self._theme = {}
	for category, props in pairs(DefaultTheme) do
		self._theme[category] = {}
		if type(props) == "table" then
			for key, value in pairs(props) do
				if type(value) == "table" then
					self._theme[category][key] = {}
					for k, v in pairs(value) do
						self._theme[category][key][k] = v
					end
				else
					self._theme[category][key] = value
				end
			end
		else
			self._theme[category] = props
		end
	end
	if overrides then
		for category, props in pairs(overrides) do
			if self._theme[category] then
				for key, value in pairs(props) do
					self._theme[category][key] = value
				end
			else
				self._theme[category] = props
			end
		end
	end
	return self
end

function ImGuiStyle:Get(category)
	return self._theme[category] or {}
end

function ImGuiStyle:GetAll()
	return self._theme
end

-- ============================================================
-- 动画系统
-- ============================================================
local ImGuiAnimation = {}
ImGuiAnimation.__index = ImGuiAnimation

function ImGuiAnimation.new(theme)
	local self = setmetatable({}, ImGuiAnimation)
	self.Theme = theme
	self._activeTweens = {}
	return self
end

function ImGuiAnimation:Tween(instance, properties, duration, easingStyle, easingDirection)
	easingStyle = easingStyle or self.Theme.Animation.EasingStyle
	easingDirection = easingDirection or self.Theme.Animation.OpenDirection
	duration = duration or 0.2
	local key = tostring(instance) .. "_" .. tostring(properties)
	if self._activeTweens[key] then
		self._activeTweens[key]:Cancel()
	end
	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection, 0, false, 0)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	self._activeTweens[key] = tween
	tween:Play()
	tween.Completed:Connect(function()
		self._activeTweens[key] = nil
	end)
	return tween
end

function ImGuiAnimation:WindowAppear(windowFrame, duration)
	duration = duration or self.Theme.Animation.WindowOpenDuration
	windowFrame.Visible = true
	windowFrame.GroupTransparency = 1
	local startSize = windowFrame.Size
	windowFrame.Size = UDim2.new(startSize.X.Scale, startSize.X.Offset, startSize.Y.Scale, startSize.Y.Offset - 8)
	self:Tween(windowFrame, {GroupTransparency = 0, Size = startSize}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function ImGuiAnimation:WindowDisappear(windowFrame, duration, onComplete)
	duration = duration or self.Theme.Animation.WindowCloseDuration
	local targetSize = windowFrame.Size
	windowFrame.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, targetSize.Y.Scale, targetSize.Y.Offset - 8)
	local tween = self:Tween(windowFrame, {GroupTransparency = 1, Size = targetSize}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if onComplete then
		tween.Completed:Connect(function()
			onComplete()
		end)
	end
	return tween
end

function ImGuiAnimation:Minimize(contentFrame, targetVisible, duration)
	duration = duration or self.Theme.Animation.MinimizeDuration
	if targetVisible then
		contentFrame.Visible = true
		contentFrame.GroupTransparency = 1
		self:Tween(contentFrame, {GroupTransparency = 0}, duration)
	else
		self:Tween(contentFrame, {GroupTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			contentFrame.Visible = false
		end)
	end
end

function ImGuiAnimation:SectionExpand(expandedContent, expanded, duration)
	duration = duration or self.Theme.Animation.SectionExpandDuration
	if expanded then
		expandedContent.Visible = true
		local uiListLayout = expandedContent:FindFirstChildOfClass("UIListLayout")
		if uiListLayout then
			local targetHeight = uiListLayout.AbsoluteContentSize.Y
			expandedContent.Size = UDim2.new(1, 0, 0, 0)
			expandedContent.GroupTransparency = 1
			self:Tween(expandedContent, {Size = UDim2.new(1, 0, 0, targetHeight), GroupTransparency = 0}, duration)
		end
	else
		self:Tween(expandedContent, {Size = UDim2.new(1, 0, 0, 0), GroupTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			expandedContent.Visible = false
		end)
	end
end

function ImGuiAnimation:Toggle(thumbFrame, onState, trackFrame, theme, duration)
	duration = duration or self.Theme.Animation.ToggleDuration
	local toggleTheme = theme:Get("Toggle")
	if onState then
		self:Tween(trackFrame, {BackgroundColor3 = toggleTheme.OnTrackColor}, duration)
		self:Tween(thumbFrame, {BackgroundColor3 = toggleTheme.OnThumbColor, Position = UDim2.new(1, -toggleTheme.ThumbSize - 3, 0.5, 0)}, duration)
	else
		self:Tween(trackFrame, {BackgroundColor3 = toggleTheme.OffTrackColor}, duration)
		self:Tween(thumbFrame, {BackgroundColor3 = toggleTheme.OffThumbColor, Position = UDim2.new(0, 3, 0.5, 0)}, duration)
	end
end

function ImGuiAnimation:Hover(element, isHovered, hoverColor, normalColor, duration)
	duration = duration or self.Theme.Animation.HoverDuration
	self:Tween(element, {BackgroundColor3 = isHovered and hoverColor or normalColor}, duration)
end

function ImGuiAnimation:Dropdown(dropdownList, isOpen, duration)
	duration = duration or self.Theme.Animation.DropdownDuration
	if isOpen then
		dropdownList.Visible = true
		dropdownList.GroupTransparency = 1
		self:Tween(dropdownList, {GroupTransparency = 0}, duration)
	else
		self:Tween(dropdownList, {GroupTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			dropdownList.Visible = false
		end)
	end
end

-- ============================================================
-- 组件工厂
-- ============================================================
local Components = {}

-- 按钮组件
function Components.Button(config)
	local parent = config.Parent
	local theme = config.Theme
	local animation = config.Animation
	local zIndex = config.ZIndexBase or 1
	local text = config.Text or "Button"
	local onClicked = config.OnClicked
	local disabled = config.Disabled or false
	
	local spacing = theme:Get("Spacing")
	local buttonTheme = theme:Get("Button")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Button"
	mainFrame.Size = UDim2.new(1, 0, 0, 32)
	mainFrame.BackgroundColor3 = buttonTheme.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, buttonTheme.CornerRadius)
	corner.Parent = mainFrame
	
	local border = Instance.new("UIStroke")
	border.Color = buttonTheme.BorderColor
	border.Thickness = spacing.BorderSize
	border.Transparency = 0.5
	border.Parent = mainFrame
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, -12, 1, 0)
	textLabel.Position = UDim2.new(0, 6, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Text = text
	textLabel.TextColor3 = buttonTheme.TextColor
	textLabel.Font = typography.ButtonFont
	textLabel.TextSize = typography.ButtonSize
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.ZIndex = zIndex + 1
	textLabel.Parent = mainFrame
	
	local isHovered = false
	
	mainFrame.MouseEnter:Connect(function()
		if disabled then return end
		isHovered = true
		TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = buttonTheme.HoverColor}):Play()
	end)
	
	mainFrame.MouseLeave:Connect(function()
		isHovered = false
		TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = buttonTheme.BackgroundColor}):Play()
	end)
	
	mainFrame.MouseButton1Up:Connect(function()
		if disabled then return end
		TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = buttonTheme.BackgroundColor}):Play()
		if onClicked then onClicked() end
	end)
	
	mainFrame.MouseButton1Down:Connect(function()
		if disabled then return end
		TweenService:Create(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {BackgroundColor3 = buttonTheme.PressedColor}):Play()
	end)
	
	return {
		MainFrame = mainFrame,
		SetDisabled = function(self, d)
			disabled = d
			if d then
				mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				textLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
			else
				mainFrame.BackgroundColor3 = buttonTheme.BackgroundColor
				textLabel.TextColor3 = buttonTheme.TextColor
			end
		end,
		SetText = function(self, t)
			text = t
			textLabel.Text = t
		end,
	}
end

-- 开关组件
function Components.Toggle(config)
	local parent = config.Parent
	local theme = config.Theme
	local animation = config.Animation
	local zIndex = config.ZIndexBase or 1
	local text = config.Text or "Toggle"
	local value = config.Value or false
	local onChanged = config.OnChanged
	
	local toggleTheme = theme:Get("Toggle")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Toggle"
	mainFrame.Size = UDim2.new(1, 0, 0, 32)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.5, -4, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = theme:Get("Label").PrimaryTextColor
	label.Font = typography.LabelFont
	label.TextSize = typography.LabelSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = zIndex + 1
	label.Parent = mainFrame
	
	local switchFrame = Instance.new("Frame")
	switchFrame.Name = "Switch"
	switchFrame.Size = UDim2.new(0.5, -4, 1, 0)
	switchFrame.Position = UDim2.new(0.5, 4, 0, 0)
	switchFrame.BackgroundTransparency = 1
	switchFrame.BorderSizePixel = 0
	switchFrame.ZIndex = zIndex + 1
	switchFrame.Parent = mainFrame
	
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, toggleTheme.TrackHeight)
	track.Position = UDim2.new(0.5, 0, 0.5, 0)
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.BackgroundColor3 = value and toggleTheme.OnTrackColor or toggleTheme.OffTrackColor
	track.BorderSizePixel = 0
	track.ZIndex = zIndex + 2
	track.Parent = switchFrame
	
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 999)
	trackCorner.Parent = track
	
	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.new(0, toggleTheme.ThumbSize, 0, toggleTheme.ThumbSize)
	thumb.Position = UDim2.new(value and (1 - (toggleTheme.ThumbSize / toggleTheme.TrackWidth)) or 0, 0, 0.5, 0)
	thumb.AnchorPoint = Vector2.new(0, 0.5)
	thumb.BackgroundColor3 = value and toggleTheme.OnThumbColor or toggleTheme.OffThumbColor
	thumb.BorderSizePixel = 0
	thumb.ZIndex = zIndex + 3
	thumb.Parent = switchFrame
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	
	switchFrame.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			value = not value
			animation:Toggle(thumb, value, track, theme)
			if onChanged then onChanged(value) end
		end
	end)
	
	return {
		MainFrame = mainFrame,
		GetValue = function(self) return value end,
		SetValue = function(self, v, animate)
			if value == v then return end
			value = v
			if animate ~= false and onChanged then onChanged(v) end
			if not animate then
				track.BackgroundColor3 = value and toggleTheme.OnTrackColor or toggleTheme.OffTrackColor
				thumb.BackgroundColor3 = value and toggleTheme.OnThumbColor or toggleTheme.OffThumbColor
				local thumbPos = value and (1 - (toggleTheme.ThumbSize / toggleTheme.TrackWidth)) or 0
				thumb.Position = UDim2.new(thumbPos, 0, 0.5, 0)
			end
		end,
	}
end

-- 滑动条组件
function Components.Slider(config)
	local parent = config.Parent
	local theme = config.Theme
	local animation = config.Animation
	local zIndex = config.ZIndexBase or 1
	local text = config.Text or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local currentValue = math.clamp(config.Value or min, min, max)
	local precision = config.Precision or 0
	local onChanged = config.OnChanged
	
	local sliderTheme = theme:Get("Slider")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Slider"
	mainFrame.Size = UDim2.new(1, 0, 0, 40)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.Size = UDim2.new(1, 0, 0, 16)
	topRow.BackgroundTransparency = 1
	topRow.BorderSizePixel = 0
	topRow.ZIndex = zIndex + 1
	topRow.Parent = mainFrame
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = sliderTheme.LabelTextColor
	label.Font = typography.LabelFont
	label.TextSize = typography.LabelSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = zIndex + 2
	label.Parent = topRow
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.BorderSizePixel = 0
	valueLabel.Text = string.format("%." .. precision .. "f", currentValue)
	valueLabel.TextColor3 = sliderTheme.ValueTextColor
	valueLabel.Font = typography.ValueFont
	valueLabel.TextSize = typography.ValueSize
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.ZIndex = zIndex + 2
	valueLabel.Parent = topRow
	
	local bottomRow = Instance.new("Frame")
	bottomRow.Name = "BottomRow"
	bottomRow.Size = UDim2.new(1, 0, 0, sliderTheme.ThumbSize + 8)
	bottomRow.Position = UDim2.new(0, 0, 0, 18)
	bottomRow.BackgroundTransparency = 1
	bottomRow.BorderSizePixel = 0
	bottomRow.ZIndex = zIndex + 1
	bottomRow.Parent = mainFrame
	
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, sliderTheme.TrackHeight)
	track.Position = UDim2.new(0.5, 0, 0.5, 0)
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.BackgroundColor3 = sliderTheme.TrackColor
	track.BorderSizePixel = 0
	track.ZIndex = zIndex + 2
	track.Parent = bottomRow
	
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, sliderTheme.TrackHeight / 2)
	trackCorner.Parent = track
	
	local trackFill = Instance.new("Frame")
	trackFill.Name = "TrackFill"
	trackFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
	trackFill.BackgroundColor3 = sliderTheme.TrackFillColor
	trackFill.BorderSizePixel = 0
	trackFill.ZIndex = zIndex + 3
	trackFill.Parent = track
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, sliderTheme.TrackHeight / 2)
	fillCorner.Parent = trackFill
	
	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.new(0, sliderTheme.ThumbSize, 0, sliderTheme.ThumbSize)
	thumb.Position = UDim2.new((currentValue - min) / (max - min), 0, 0.5, 0)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.BackgroundColor3 = sliderTheme.ThumbColor
	thumb.BorderSizePixel = 0
	thumb.ZIndex = zIndex + 5
	thumb.Parent = bottomRow
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	
	local touchTarget = Instance.new("Frame")
	touchTarget.Name = "TouchTarget"
	touchTarget.Size = UDim2.new(1, 0, 1, 16)
	touchTarget.Position = UDim2.new(0, 0, 0, -8)
	touchTarget.BackgroundTransparency = 1
	touchTarget.BorderSizePixel = 0
	touchTarget.ZIndex = zIndex + 6
	touchTarget.Parent = bottomRow
	
	local dragging = false
	
	local function updateValue(inputPos)
		local trackAbsPos = track.AbsolutePosition
		local trackAbsSize = track.AbsoluteSize
		local ratio = math.clamp((inputPos.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
		local newValue = min + ratio * (max - min)
		if precision > 0 then
			local mult = 10 ^ precision
			newValue = math.floor(newValue * mult + 0.5) / mult
		else
			newValue = math.floor(newValue + 0.5)
		end
		newValue = math.clamp(newValue, min, max)
		currentValue = newValue
		local newRatio = (currentValue - min) / (max - min)
		TweenService:Create(trackFill, TweenInfo.new(0.1), {Size = UDim2.new(newRatio, 0, 1, 0)}):Play()
		TweenService:Create(thumb, TweenInfo.new(0.1), {Position = UDim2.new(newRatio, 0, 0.5, 0)}):Play()
		valueLabel.Text = string.format("%." .. precision .. "f", currentValue)
		if onChanged then onChanged(currentValue) end
	end
	
	touchTarget.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateValue(input.Position)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input, processed)
		if processed then return end
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateValue(input.Position)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	return {
		MainFrame = mainFrame,
		GetValue = function(self) return currentValue end,
		SetValue = function(self, v, animate)
			v = math.clamp(v, min, max)
			if precision > 0 then
				local mult = 10 ^ precision
				v = math.floor(v * mult + 0.5) / mult
			else
				v = math.floor(v + 0.5)
			end
			currentValue = v
			local ratio = (currentValue - min) / (max - min)
			if not animate then
				trackFill.Size = UDim2.new(ratio, 0, 1, 0)
				thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
			end
			valueLabel.Text = string.format("%." .. precision .. "f", currentValue)
			if onChanged then onChanged(currentValue) end
		end,
	}
end

-- 下拉框组件
function Components.Dropdown(config)
	local parent = config.Parent
	local theme = config.Theme
	local animation = config.Animation
	local zIndex = config.ZIndexBase or 1
	local text = config.Text or "Dropdown"
	local options = config.Options or {"Option 1", "Option 2", "Option 3"}
	local value = config.Value or options[1] or ""
	local onChanged = config.OnChanged
	
	local dropdownTheme = theme:Get("Dropdown")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Dropdown"
	mainFrame.Size = UDim2.new(1, 0, 0, 50)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.Size = UDim2.new(1, 0, 0, 18)
	topRow.BackgroundTransparency = 1
	topRow.BorderSizePixel = 0
	topRow.ZIndex = zIndex + 1
	topRow.Parent = mainFrame
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = dropdownTheme.TextColor
	label.Font = typography.LabelFont
	label.TextSize = typography.LabelSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = zIndex + 2
	label.Parent = topRow
	
	local button = Instance.new("Frame")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 0, 28)
	button.Position = UDim2.new(0, 0, 0, 22)
	button.BackgroundColor3 = dropdownTheme.BackgroundColor
	button.BorderSizePixel = 0
	button.ZIndex = zIndex + 3
	button.Parent = mainFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, dropdownTheme.CornerRadius)
	btnCorner.Parent = button
	
	local btnBorder = Instance.new("UIStroke")
	btnBorder.Color = dropdownTheme.BorderColor
	btnBorder.Thickness = 1
	btnBorder.Transparency = 0.5
	btnBorder.Parent = button
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, -36, 1, 0)
	valueLabel.Position = UDim2.new(0, 8, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.BorderSizePixel = 0
	valueLabel.Text = value
	valueLabel.TextColor3 = dropdownTheme.TextColor
	valueLabel.Font = typography.LabelFont
	valueLabel.TextSize = typography.LabelSize
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.TextYAlignment = Enum.TextYAlignment.Center
	valueLabel.ZIndex = zIndex + 4
	valueLabel.Parent = button
	
	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(0, 8, 0, 8)
	arrow.Position = UDim2.new(1, -14, 0.5, 0)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.BackgroundColor3 = dropdownTheme.IndicatorColor
	arrow.BorderSizePixel = 0
	arrow.ZIndex = zIndex + 4
	arrow.Parent = button
	
	local popup = Instance.new("Frame")
	popup.Name = "Popup"
	popup.Size = UDim2.new(1, 0, 0, 0)
	popup.Position = UDim2.new(0, 0, 1, 2)
	popup.BackgroundColor3 = dropdownTheme.BackgroundColor
	popup.BorderSizePixel = 0
	popup.ZIndex = zIndex + 100
	popup.Visible = false
	popup.Parent = button
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, dropdownTheme.CornerRadius)
	popupCorner.Parent = popup
	
	local popupLayout = Instance.new("UIListLayout")
	popupLayout.FillDirection = Enum.FillDirection.Vertical
	popupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	popupLayout.Padding = UDim.new(0, 1)
	popupLayout.SortOrder = Enum.SortOrder.Name
	popupLayout.ZIndex = zIndex + 101
	popupLayout.Parent = popup
	
	local isOpen = false
	local popupHeight = #options * 26 + 2
	
	-- 创建选项
	local optionFrames = {}
	for i, opt in ipairs(options) do
		local optFrame = Instance.new("Frame")
		optFrame.Name = "Option" .. i
		optFrame.Size = UDim2.new(1, -4, 0, 26)
		optFrame.BackgroundColor3 = dropdownTheme.BackgroundColor
		optFrame.BorderSizePixel = 0
		optFrame.ZIndex = zIndex + 102
		optFrame.Parent = popup
		
		local optText = Instance.new("TextLabel")
		optText.Size = UDim2.new(1, -16, 1, 0)
		optText.Position = UDim2.new(0, 8, 0, 0)
		optText.BackgroundTransparency = 1
		optText.Text = opt
		optText.TextColor3 = dropdownTheme.TextColor
		optText.Font = typography.LabelFont
		optText.TextSize = typography.LabelSize
		optText.TextXAlignment = Enum.TextXAlignment.Left
		optText.TextYAlignment = Enum.TextYAlignment.Center
		optText.ZIndex = zIndex + 103
		optText.Parent = optFrame
		
		if opt == value then
			optFrame.BackgroundColor3 = dropdownTheme.SelectedColor
		end
		
		optFrame.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				value = opt
				valueLabel.Text = opt
				isOpen = false
				TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play()
				TweenService:Create(arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Rotation = 0}):Play()
				-- 更新选中状态
				for j, f in ipairs(optionFrames) do
					f.BackgroundColor3 = dropdownTheme.BackgroundColor
				end
				optFrame.BackgroundColor3 = dropdownTheme.SelectedColor
				if onChanged then onChanged(value) end
			end
		end)
		
		optFrame.MouseEnter:Connect(function()
			TweenService:Create(optFrame, TweenInfo.new(0.1), {BackgroundColor3 = dropdownTheme.HoverColor}):Play()
		end)
		optFrame.MouseLeave:Connect(function()
			if opt ~= value then
				TweenService:Create(optFrame, TweenInfo.new(0.1), {BackgroundColor3 = dropdownTheme.BackgroundColor}):Play()
			end
		end)
		
		optionFrames[i] = optFrame
	end
	
	button.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isOpen = not isOpen
			if isOpen then
				popup.Visible = true
				TweenService:Create(popup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, popupHeight)}):Play()
				TweenService:Create(arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 180}):Play()
			else
				TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play()
				TweenService:Create(arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Rotation = 0}):Play()
			end
		end
	end)
	
	return {
		MainFrame = mainFrame,
		GetValue = function(self) return value end,
		SetValue = function(self, v)
			value = v
			valueLabel.Text = v
			for i, opt in ipairs(options) do
				optionFrames[i].BackgroundColor3 = (opt == v) and dropdownTheme.SelectedColor or dropdownTheme.BackgroundColor
			end
		end,
	}
end

-- 标签组件
function Components.Label(config)
	local parent = config.Parent
	local theme = config.Theme
	local zIndex = config.ZIndexBase or 1
	local text = config.Text or ""
	
	local labelTheme = theme:Get("Label")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Label"
	mainFrame.Size = UDim2.new(1, 0, 0, 20)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Text = text
	textLabel.TextColor3 = labelTheme.PrimaryTextColor
	textLabel.Font = typography.LabelFont
	textLabel.TextSize = typography.LabelSize
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.ZIndex = zIndex + 1
	textLabel.Parent = mainFrame
	
	return {
		MainFrame = mainFrame,
		SetText = function(self, t)
			text = t
			textLabel.Text = t
		end,
		SetSecondary = function(self)
			textLabel.TextColor3 = labelTheme.SecondaryTextColor
		end,
		SetPrimary = function(self)
			textLabel.TextColor3 = labelTheme.PrimaryTextColor
		end,
	}
end

-- 分隔线组件
function Components.Divider(config)
	local parent = config.Parent
	local theme = config.Theme
	local zIndex = config.ZIndexBase or 1
	local thickness = config.Thickness or 1
	
	local contentTheme = theme:Get("Content")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Divider"
	mainFrame.Size = UDim2.new(1, 0, 0, thickness)
	mainFrame.BackgroundColor3 = contentTheme.DividerColor
	mainFrame.BackgroundTransparency = 0.3
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	return {
		MainFrame = mainFrame,
	}
end

-- 区块组件
function Components.Section(config)
	local parent = config.Parent
	local theme = config.Theme
	local animation = config.Animation
	local zIndex = config.ZIndexBase or 1
	local title = config.Title or "Section"
	
	local sectionTheme = theme:Get("Section")
	local typography = theme:Get("Typography")
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Section"
	mainFrame.Size = UDim2.new(1, 0, 0, 32)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = zIndex
	mainFrame.Parent = parent
	
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = "Row"
	rowFrame.Size = UDim2.new(1, 0, 0, 32)
	rowFrame.BackgroundTransparency = 1
	rowFrame.BorderSizePixel = 0
	rowFrame.ZIndex = zIndex
	rowFrame.Parent = mainFrame
	
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 8, 0, 8)
	indicator.Position = UDim2.new(0, 8, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = sectionTheme.IndicatorColor
	indicator.BorderSizePixel = 0
	indicator.ZIndex = zIndex + 1
	indicator.Parent = rowFrame
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -28, 1, 0)
	titleLabel.Position = UDim2.new(0, 24, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = title
	titleLabel.TextColor3 = sectionTheme.TextColor
	titleLabel.Font = typography.LabelFont
	titleLabel.TextSize = typography.LabelSize
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.ZIndex = zIndex + 1
	titleLabel.Parent = rowFrame
	
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 0, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ClipsDescendants = true
	contentFrame.Visible = false
	contentFrame.ZIndex = zIndex + 10
	contentFrame.Parent = mainFrame
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.SortOrder = Enum.SortOrder.Name
	contentLayout.ZIndex = zIndex + 11
	contentLayout.Parent = contentFrame
	
	local expanded = config.Expanded ~= false
	local onExpandedChanged = config.OnExpandedChanged
	
	local function updateHeight()
		local totalHeight = 0
		for _, child in ipairs(contentLayout:GetChildren()) do
			if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then continue end
			totalHeight = totalHeight + child.AbsoluteSize.Y + 6
		end
		if totalHeight == 0 then totalHeight = 32 end
		return totalHeight
	end
	
	rowFrame.MouseButton1Click:Connect(function()
		expanded = not expanded
		if expanded then
			contentFrame.Visible = true
			local h = updateHeight()
			TweenService:Create(contentFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, h)}):Play()
		else
			TweenService:Create(contentFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play()
			task.delay(0.2, function()
				if not expanded then contentFrame.Visible = false end
			end)
		end
		if onExpandedChanged then onExpandedChanged(expanded) end
	end)
	
	if expanded then
		contentFrame.Visible = true
	end
	
	return {
		MainFrame = mainFrame,
		ContentFrame = contentFrame,
		AddInstance = function(self, instance)
			instance.Parent = contentFrame
			-- 更新内容高度
			contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if expanded then
					local h = updateHeight()
					contentFrame.Size = UDim2.new(1, 0, 0, h)
				end
			end)
		end,
	}
end

-- ============================================================
-- 窗口组件
-- ============================================================
local ImGuiWindow = {}
ImGuiWindow.__index = ImGuiWindow

function ImGuiWindow.new(name, config, theme, animation)
	local self = setmetatable({}, ImGuiWindow)
	self.Name = name
	self.Theme = theme
	self.Animation = animation
	self.Title = config.Title or name
	self.Position = config.Position or UDim2.new(0.5, -150, 0.5, -100)
	self.WindowSize = config.Size or UDim2.new(0, 320, 0, 400)
	self.Visible = config.Visible ~= false
	self.Minimized = config.Minimized or false
	self.Draggable = config.Draggable ~= false
	self.ZIndex = config.ZIndex or 100
	self.Sections = {}
	self:Build()
	return self
end

function ImGuiWindow:Build()
	local spacing = self.Theme:Get("Spacing")
	local shadow = self.Theme:Get("Shadow")
	local winTheme = self.Theme:Get("Window")
	
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "ImGuiWindow"
	self.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.MainFrame.Position = self.Position
	self.MainFrame.Size = self.WindowSize
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = self.ZIndex
	self.MainFrame.Visible = self.Visible
	
	self.Background = Instance.new("Frame")
	self.Background.Name = "Background"
	self.Background.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Background.Position = UDim2.new(0.5, shadow.Offset.X, 0.5, shadow.Offset.Y)
	self.Background.Size = UDim2.new(1, 0, 1, 0)
	self.Background.BackgroundColor3 = winTheme.BackgroundColor
	self.Background.BorderSizePixel = 0
	self.Background.ZIndex = self.ZIndex
	self.Background.Parent = self.MainFrame
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, spacing.WindowCornerRadius)
	bgCorner.Parent = self.Background
	
	local bgBorder = Instance.new("UIStroke")
	bgBorder.Color = winTheme.BorderColor
	bgBorder.Thickness = spacing.WindowBorderSize
	bgBorder.Transparency = 0.5
	bgBorder.Parent = self.Background
	
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, -spacing.WindowBorderSize * 2, 0, spacing.WindowTitleBarHeight)
	self.TitleBar.Position = UDim2.new(0, spacing.WindowBorderSize, 0, spacing.WindowBorderSize)
	self.TitleBar.BackgroundColor3 = winTheme.TitleBarColor
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.ZIndex = self.ZIndex + 1
	self.TitleBar.Parent = self.Background
	
	local titleClip = Instance.new("Frame")
	titleClip.Size = UDim2.new(1, 0, 1, 0)
	titleClip.BackgroundTransparency = 1
	titleClip.ClipsDescendants = true
	titleClip.ZIndex = self.ZIndex + 1
	titleClip.Parent = self.TitleBar
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = winTheme.TitleTextColor
	titleLabel.Font = self.Theme:Get("Typography").WindowTitleFont
	titleLabel.TextSize = self.Theme:Get("Typography").WindowTitleSize
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.ZIndex = self.ZIndex + 2
	titleLabel.Parent = titleClip
	
	local miniBtn = Instance.new("TextButton")
	miniBtn.Size = UDim2.new(0, 24, 0, 24)
	miniBtn.Position = UDim2.new(1, -20, 0.5, 0)
	miniBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	miniBtn.BackgroundTransparency = 1
	miniBtn.Text = ""
	miniBtn.ZIndex = self.ZIndex + 2
	miniBtn.Parent = titleClip
	
	local miniIcon = Instance.new("Frame")
	miniIcon.Size = UDim2.new(1, 0, 0, 2)
	miniIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	miniIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	miniIcon.BackgroundColor3 = winTheme.MinimizeButtonColor
	miniIcon.BorderSizePixel = 0
	miniIcon.ZIndex = self.ZIndex + 3
	miniIcon.Parent = miniBtn
	
	miniBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)
	
	self.ContentContainer = Instance.new("Frame")
	self.ContentContainer.Name = "Content"
	self.ContentContainer.Size = UDim2.new(1, -spacing.WindowBorderSize * 2, 1, -spacing.WindowTitleBarHeight - spacing.WindowBorderSize * 2 - spacing.WindowPadding)
	self.ContentContainer.Position = UDim2.new(0, spacing.WindowBorderSize, 0, spacing.WindowTitleBarHeight + spacing.WindowPadding + spacing.WindowBorderSize)
	self.ContentContainer.BackgroundTransparency = 1
	self.ContentContainer.BorderSizePixel = 0
	self.ContentContainer.ClipsDescendants = true
	self.ContentContainer.ZIndex = self.ZIndex + 1
	self.ContentContainer.Parent = self.Background
	
	self.ScrollFrame = Instance.new("ScrollingFrame")
	self.ScrollFrame.Name = "ScrollFrame"
	self.ScrollFrame.Size = self.ContentContainer.Size
	self.ScrollFrame.BackgroundTransparency = 1
	self.ScrollFrame.BorderSizePixel = 0
	self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.ScrollFrame.ScrollBarThickness = 0
	self.ScrollFrame.ZIndex = self.ZIndex + 1
	self.ScrollFrame.Parent = self.ContentContainer
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLayout.Padding = UDim.new(0, spacing.SectionSpacing)
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.ZIndex = self.ZIndex + 1
	listLayout.Parent = self.ScrollFrame
	
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)
	
	-- 拖拽
	if self.Draggable then
		local dragging = false
		local dragStart = nil
		local startPos = nil
		
		self.TitleBar.MouseButton1Down:Connect(function()
			dragging = true
			dragStart = UserInputService:GetMouseLocation()
			startPos = self.MainFrame.Position
		end)
		
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mousePos = UserInputService:GetMouseLocation()
				local delta = mousePos - dragStart
				local newX = startPos.X.Offset + delta.X
				local newY = startPos.Y.Offset + delta.Y
				local viewport = workspace.CurrentCamera.ViewportSize
				local winSize = self.MainFrame.AbsoluteSize
				newX = math.clamp(newX, 0, viewport.X - winSize.X)
				newY = math.clamp(newY, 0, viewport.Y - winSize.Y)
				self.MainFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
			end
		end)
	end
	
	if self.Minimized then
		self.ContentContainer.Visible = false
	end
end

function ImGuiWindow:ToggleMinimize()
	self.Minimized = not self.Minimized
	if self.Minimized then
		self.Animation:Minimize(self.ContentContainer, false)
		local currentSize = self.Background.Size
		local targetSize = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 0, self.Theme:Get("Spacing").WindowTitleBarHeight + self.Theme:Get("Spacing").WindowBorderSize * 2)
		TweenService:Create(self.Background, TweenInfo.new(0.15), {Size = targetSize}):Play()
	else
		self.Animation:Minimize(self.ContentContainer, true)
		TweenService:Create(self.Background, TweenInfo.new(0.15), {Size = self.WindowSize}):Play()
	end
end

function ImGuiWindow:SetVisible(visible)
	if self.Visible == visible then return end
	self.Visible = visible
	if visible then
		self.Animation:WindowAppear(self.MainFrame)
	else
		self.Animation:WindowDisappear(self.MainFrame)
	end
end

function ImGuiWindow:CreateSection(title, config)
	config = config or {}
	config.Title = title
	config.Theme = self.Theme
	config.Animation = self.Animation
	config.ZIndexBase = self.ZIndex + 10
	config.Parent = self.ScrollFrame
	
	local section = Components.Section(config)
	section.MainFrame.Parent = self.ScrollFrame
	table.insert(self.Sections, section)
	return section
end

function ImGuiWindow:Destroy()
	if self.MainFrame and self.MainFrame.Parent then
		self.MainFrame:Destroy()
	end
end

-- ============================================================
-- 窗口管理器
-- ============================================================
local WindowManager = {}
WindowManager.__index = WindowManager

function WindowManager.new(theme, animation, parent)
	local self = setmetatable({}, WindowManager)
	self.Theme = theme
	self.Animation = animation
	self.Parent = parent or game:GetService("CoreGui")
	self.Windows = {}
	self.BaseZIndex = 100
	return self
end

function WindowManager:RegisterWindow(window)
	window.Parent = self
	window.Index = #self.Windows + 1
	window.ZIndex = self.BaseZIndex + window.Index
	if window.MainFrame then
		window.MainFrame.Parent = self.Parent
	end
	table.insert(self.Windows, window)
	return window
end

function WindowManager:GetWindow(name)
	for _, w in ipairs(self.Windows) do
		if w.Name == name then return w end
	end
	return nil
end

function WindowManager:DestroyAll()
	for _, w in ipairs(self.Windows) do
		w:Destroy()
	end
	self.Windows = {}
end

-- ============================================================
-- 主库
-- ============================================================
local ImGuiLibrary = {}
ImGuiLibrary.__index = ImGuiLibrary

function ImGuiLibrary.new()
	local self = setmetatable({}, ImGuiLibrary)
	self.Theme = ImGuiStyle.new()
	self.Animation = ImGuiAnimation.new(self.Theme)
	self.WindowManager = WindowManager.new(self.Theme, self.Animation, game:GetService("CoreGui"))
	self.Components = Components
	return self
end

function ImGuiLibrary:Window(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	local window = ImGuiWindow.new(config.Title or "Window", config, self.Theme, self.Animation)
	self.WindowManager:RegisterWindow(window)
	return window
end

function ImGuiLibrary:GetWindow(name)
	return self.WindowManager:GetWindow(name)
end

function ImGuiLibrary:DestroyAll()
	self.WindowManager:DestroyAll()
end

-- 返回库
return ImGuiLibrary