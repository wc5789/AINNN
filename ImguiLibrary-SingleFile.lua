--[[
	ImGuiStyle: Theme system for the ImGui Library
	Centralizes all colors, sizes, and visual properties
]]

local ImGuiStyle = {}
ImGuiStyle.__index = ImGuiStyle

-- Default monochrome theme (ImGui-inspired)
local DefaultTheme = {
	-- Window properties
	Window = {
		BackgroundColor = Color3.fromRGB(45, 45, 48),
		TitleBarColor = Color3.fromRGB(54, 54, 57),
		BorderColor = Color3.fromRGB(65, 65, 68),
		ShadowColor = Color3.fromRGB(0, 0, 0),
		TitleTextColor = Color3.fromRGB(225, 225, 225),
		MinimizeButtonColor = Color3.fromRGB(180, 180, 180),
		MinimizeButtonHoverColor = Color3.fromRGB(220, 220, 220),
	},
	
	-- Content area
	Content = {
		BackgroundColor = Color3.fromRGB(30, 30, 30),
		DividerColor = Color3.fromRGB(55, 55, 58),
		ScrollBarColor = Color3.fromRGB(65, 65, 68),
		ScrollBarThumbColor = Color3.fromRGB(90, 90, 92),
	},
	
	-- Row properties
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
	
	-- Slider properties
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
	
	-- Toggle properties
	Toggle = {
		OffTrackColor = Color3.fromRGB(70, 70, 73),
		OffThumbColor = Color3.fromRGB(230, 230, 235),
		OnTrackColor = Color3.fromRGB(130, 130, 135),
		OnThumbColor = Color3.fromRGB(25, 25, 27),
		TrackWidth = 40,
		TrackHeight = 18,
		ThumbSize = 12,
	},
	
	-- Button properties
	Button = {
		BackgroundColor = Color3.fromRGB(55, 55, 58),
		HoverColor = Color3.fromRGB(70, 70, 73),
		PressedColor = Color3.fromRGB(45, 45, 48),
		BorderColor = Color3.fromRGB(80, 80, 83),
		TextColor = Color3.fromRGB(210, 210, 215),
		CornerRadius = 4,
	},
	
	-- Dropdown properties
	Dropdown = {
		BackgroundColor = Color3.fromRGB(38, 38, 40),
		HoverColor = Color3.fromRGB(52, 52, 55),
		SelectedColor = Color3.fromRGB(65, 65, 68),
		BorderColor = Color3.fromRGB(65, 65, 68),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(160, 160, 165),
		CornerRadius = 4,
	},
	
	-- Section properties
	Section = {
		BackgroundColor = Color3.fromRGB(42, 42, 44),
		ExpandedColor = Color3.fromRGB(48, 48, 50),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(150, 150, 155),
		CornerRadius = 4,
		ExpandDuration = 0.2,
	},
	
	-- Label properties
	Label = {
		PrimaryTextColor = Color3.fromRGB(210, 210, 215),
		SecondaryTextColor = Color3.fromRGB(145, 145, 150),
	},
	
	-- Typography
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
	
	-- Spacing (in pixels at 1x scale)
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
	
	-- Shadow
	Shadow = {
		Enabled = true,
		Color = Color3.fromRGB(0, 0, 0),
		Offset = Vector2.new(0, 4),
		Size = 12,
		Transparency = 0.4,
		PopupShadowTransparency = 0.35,
		PopupShadowSize = 16,
	},
	
	-- Animation
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
	
	-- Optional accent color (muted, for specific use cases)
	Accent = {
		Enabled = false,
		Color = Color3.fromRGB(86, 151, 232),
	},
	
	-- Responsive scaling
	Responsive = {
		MinScale = 0.7,
		MaxScale = 1.5,
		DefaultScale = 1.0,
	},
}

function ImGuiStyle.new(overrides)
	local self = setmetatable({}, ImGuiStyle)
	
	-- Deep copy default theme
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
	
	-- Apply overrides
	if overrides then
		self:ApplyOverrides(overrides)
	end
	
	return self
end

function ImGuiStyle:ApplyOverrides(overrides)
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

function ImGuiStyle:Get(category)
	return self._theme[category] or {}
end

function ImGuiStyle:GetAll()
	return self._theme
end

function ImGuiStyle:CreateDarkVariant(tint)
	-- Creates a darker/lighter variant of the theme
	local variant = ImGuiStyle.new()
	
	-- Adjust colors based on tint (-1 = darker, 1 = lighter)
	local function adjustColor(color, amount)
		return Color3.new(
			math.clamp(color.R + amount * 0.05, 0, 1),
			math.clamp(color.G + amount * 0.05, 0, 1),
			math.clamp(color.B + amount * 0.05, 0, 1)
		)
	end
	
	-- Apply tint to color categories
	local categories = {"Window", "Content", "Row", "Slider", "Toggle", "Button", "Dropdown", "Section", "Label"}
	for _, cat in ipairs(categories) do
		if variant._theme[cat] then
			for key, value in pairs(variant._theme[cat]) do
				if value and value.R and value.G and value.B then
					variant._theme[cat][key] = adjustColor(value, tint)
				end
			end
		end
	end
	
	return variant
end

return ImGuiStyle
--[[
	ImGuiLibrary Animation Module
	Wraps TweenService for smooth, consistent animations
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ImGuiAnimation = {}
ImGuiAnimation.__index = ImGuiAnimation

-- Cache of active tweens
local activeTweens = {}

function ImGuiAnimation.new(theme)
	local self = setmetatable({}, ImGuiAnimation)
	self.Theme = theme
	return self
end

-- Create and play a tween
function ImGuiAnimation:Tween(instance, properties, duration, easingStyle, easingDirection)
	easingStyle = easingStyle or self.Theme.Animation.EasingStyle
	easingDirection = easingDirection or self.Theme.Animation.OpenDirection
	duration = duration or 0.2

	-- Cancel existing tween on the same instance with same goal
	local key = tostring(instance) .. "_" .. tostring(properties)
	if activeTweens[key] then
		activeTweens[key]:Cancel()
	end

	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle,
		easingDirection,
		0,    -- repeatCount
		false, -- reverses
		0      -- delayTime
	)

	local tween = TweenService:Create(instance, tweenInfo, properties)
	activeTweens[key] = tween
	tween:Play()

	-- Cleanup when complete
	tween.Completed:Connect(function()
		activeTweens[key] = nil
	end)

	return tween
end

-- Animate window appearance
function ImGuiAnimation:WindowAppear(windowFrame, duration)
	duration = duration or self.Theme.Animation.WindowOpenDuration
	windowFrame.Visible = true

	-- Start from scaled-down, transparent state
	windowFrame.GroupTransparency = 1
	local startSize = windowFrame.Size
	windowFrame.Size = UDim2.new(
		startSize.X.Scale,
		startSize.X.Offset,
		startSize.Y.Scale,
		startSize.Y.Offset - 8
	)

	self:Tween(windowFrame, {
		GroupTransparency = 0,
		Size = startSize,
	}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Animate window disappearance
function ImGuiAnimation:WindowDisappear(windowFrame, duration, onComplete)
	duration = duration or self.Theme.Animation.WindowCloseDuration

	local targetSize = windowFrame.Size
	windowFrame.Size = UDim2.new(
		targetSize.X.Scale,
		targetSize.X.Offset,
		targetSize.Y.Scale,
		targetSize.Y.Offset - 8
	)

	local tween = self:Tween(windowFrame, {
		GroupTransparency = 1,
		Size = targetSize,
	}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if onComplete then
		tween.Completed:Connect(function()
			onComplete()
		end)
	end

	return tween
end

-- Animate minimize
function ImGuiAnimation:Minimize(contentFrame, targetVisible, duration)
	duration = duration or self.Theme.Animation.MinimizeDuration

	if targetVisible then
		-- Restore
		contentFrame.Visible = true
		contentFrame.GroupTransparency = 1
		self:Tween(contentFrame, {
			GroupTransparency = 0,
		}, duration)
	else
		-- Minimize
		self:Tween(contentFrame, {
			GroupTransparency = 1,
		}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			contentFrame.Visible = false
		end)
	end
end

-- Animate section expand/collapse
function ImGuiAnimation:SectionExpand(expandedContent, expanded, duration)
	duration = duration or self.Theme.Animation.SectionExpandDuration

	if expanded then
		expandedContent.Visible = true
		-- Calculate target size
		local uiListLayout = expandedContent:FindFirstChildOfClass("UIListLayout")
		if uiListLayout then
			local targetHeight = uiListLayout.AbsoluteContentSize.Y
			expandedContent.Size = UDim2.new(1, 0, 0, 0)
			expandedContent.GroupTransparency = 1
			
			self:Tween(expandedContent, {
				Size = UDim2.new(1, 0, 0, targetHeight),
				GroupTransparency = 0,
			}, duration)
		end
	else
		self:Tween(expandedContent, {
			Size = UDim2.new(1, 0, 0, 0),
			GroupTransparency = 1,
		}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			expandedContent.Visible = false
		end)
	end
end

-- Animate toggle
function ImGuiAnimation:Toggle(thumbFrame, onState, trackFrame, theme, duration)
	duration = duration or self.Theme.Animation.ToggleDuration
	local toggleTheme = theme:Get("Toggle")
	
	if onState then
		self:Tween(trackFrame, {
			BackgroundColor3 = toggleTheme.OnTrackColor,
		}, duration)
		self:Tween(thumbFrame, {
			BackgroundColor3 = toggleTheme.OnThumbColor,
			Position = UDim2.new(1, -toggleTheme.ThumbSize - 3, 0.5, 0),
		}, duration)
	else
		self:Tween(trackFrame, {
			BackgroundColor3 = toggleTheme.OffTrackColor,
		}, duration)
		self:Tween(thumbFrame, {
			BackgroundColor3 = toggleTheme.OffThumbColor,
			Position = UDim2.new(0, 3, 0.5, 0),
		}, duration)
	end
end

-- Animate hover state
function ImGuiAnimation:Hover(element, isHovered, hoverColor, normalColor, duration)
	duration = duration or self.Theme.Animation.HoverDuration
	
	self:Tween(element, {
		BackgroundColor3 = isHovered and hoverColor or normalColor,
	}, duration)
end

-- Animate pressed state
function ImGuiAnimation:Pressed(element, isPressed, pressedColor, normalColor, duration)
	duration = duration or self.Theme.Animation.PressedDuration
	
	self:Tween(element, {
		BackgroundColor3 = isPressed and pressedColor or normalColor,
	}, duration)
end

-- Animate dropdown open/close
function ImGuiAnimation:Dropdown(dropdownList, isOpen, duration)
	duration = duration or self.Theme.Animation.DropdownDuration
	
	if isOpen then
		dropdownList.Visible = true
		dropdownList.GroupTransparency = 1
		self:Tween(dropdownList, {
			GroupTransparency = 0,
		}, duration)
	else
		self:Tween(dropdownList, {
			GroupTransparency = 1,
		}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
			dropdownList.Visible = false
		end)
	end
end

return ImGuiAnimation--[[
	ImGuiLibrary Input Module
	Unified mouse and touch input handling
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ImGuiInput = {}
ImGuiInput.__index = ImGuiInput

function ImGuiInput.new(guiObjects)
	local self = setmetatable({}, ImGuiInput)
	self.GuiObjects = guiObjects or {}
	self.ActiveWindows = {}
	self.HoveredObject = nil
	self.ActiveDragging = nil
	
	-- Setup input connections
	self:SetupConnections()
	return self
end

function ImGuiInput:SetupConnections()
	-- Mouse input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:OnInputBegan(input)
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:OnInputEnded(input)
	end)
	
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		self:OnInputChanged(input)
	end)
	
	-- Touch input
	UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
		if gameProcessed then return end
		self:OnTouchStarted(touch)
	end)
	
	UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
		if gameProcessed then return end
		self:OnTouchEnded(touch)
	end)
	
	UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
		if gameProcessed then return end
		self:OnTouchMoved(touch)
	end)
end

function ImGuiInput:OnInputBegan(input)
	local inputType = Enum.UserInputType.MouseButton1
	
	-- Detect if mouse or touch
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		self:HandleMouseButton(input, true)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		self:HandleTouchButton(input, true)
	end
end

function ImGuiInput:OnInputEnded(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		self:HandleMouseButton(input, false)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		self:HandleTouchButton(input, false)
	end
end

function ImGuiInput:OnInputChanged(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
	   input.UserInputType == Enum.UserInputType.Touch then
		self:OnMouseMove(input)
	end
end

function ImGuiInput:OnTouchStarted(touch)
	-- Check if touch started on any draggable window
	for _, window in ipairs(self.GuiObjects) do
		if window.Draggable and window.Visible then
			local guiObj = window.MainFrame
			local absPos = guiObj.AbsolutePosition
			local absSize = guiObj.AbsoluteSize
			
			-- Touch rectangle check
			if touch.Position.X >= absPos.X and touch.Position.X <= absPos.X + absSize.X
			and touch.Position.Y >= absPos.Y and touch.Position.Y <= absPos.Y + absSize.Y then
				self.ActiveDragging = window
				self.ActiveDragging.Dragging = true
				self.ActiveDragging.LastTouchPos = touch.Position
				break
			end
		end
	end
end

function ImGuiInput:OnTouchEnded(touch)
	if self.ActiveDragging then
		self.ActiveDragging.Dragging = false
		self.ActiveDragging = nil
	end
end

function ImGuiInput:OnTouchMoved(touch)
	if self.ActiveDragging and self.ActiveDragging.Dragging then
		-- Smooth drag following finger
		local window = self.ActiveDragging
		local newX = math.clamp(touch.Position.X - window.DragOffset.X, 
			0, game.Workspace.CurrentCamera.ViewportSize.X - window.MainFrame.AbsoluteSize.X)
		local newY = math.clamp(touch.Position.Y - window.DragOffset.Y, 
			0, game.Workspace.CurrentCamera.ViewportSize.Y - window.MainFrame.AbsoluteSize.Y)
		
		window.MainFrame.Position = UDim2.new(0, newX, 0, newY)
	end
end

function ImGuiInput:HandleMouseButton(input, pressed)
	-- Get mouse position
	local mousePos = UserInputService:GetMouseLocation()
	
	-- Check hover on all windows
	self:CheckHover(input, mousePos)
	
	-- Check drag start
	if pressed and not self.ActiveDragging then
		for _, window in ipairs(self.GuiObjects) do
			if window.Draggable and window.Visible then
				local guiObj = window.MainFrame
				local absPos = guiObj.AbsolutePosition
				local absSize = guiObj.AbsoluteSize
				
				if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
				and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
					-- Click on title bar area
					local titleBarHeight = 32
					if mousePos.Y <= absPos.Y + titleBarHeight then
						window.Dragging = true
						window.DragOffset = Vector2.new(mousePos.X - absPos.X, mousePos.Y - absPos.Y)
						self.ActiveDragging = window
					end
				end
			end
		end
	elseif not pressed and self.ActiveDragging then
		self.ActiveDragging.Dragging = false
		self.ActiveDragging = nil
	end
end

function ImGuiInput:HandleTouchButton(input, pressed)
	-- Similar to mouse but with touch
	local touch = input
	local touchPos = touch.Position
	
	self:CheckHoverByPos(input, touchPos)
	
	if pressed and not self.ActiveDragging then
		for _, window in ipairs(self.GuiObjects) do
			if window.Draggable and window.Visible then
				local guiObj = window.MainFrame
				local absPos = guiObj.AbsolutePosition
				local absSize = guiObj.AbsoluteSize
				
				if touchPos.X >= absPos.X and touchPos.X <= absPos.X + absSize.X
				and touchPos.Y >= absPos.Y and touchPos.Y <= absPos.Y + absSize.Y then
					local titleBarHeight = 32
					if touchPos.Y <= absPos.Y + titleBarHeight then
						window.Dragging = true
						window.DragOffset = Vector2.new(touchPos.X - absPos.X, touchPos.Y - absPos.Y)
						self.ActiveDragging = window
					end
				end
			end
		end
	elseif not pressed and self.ActiveDragging then
		self.ActiveDragging.Dragging = false
		self.ActiveDragging = nil
	end
end

function ImGuiInput:CheckHover(input, mousePos)
	-- Find hovered object
	self.HoveredObject = nil
	
	for _, window in ipairs(self.GuiObjects) do
		if window.Visible then
			local guiObj = window.MainFrame
			local absPos = guiObj.AbsolutePosition
			local absSize = guiObj.AbsoluteSize
			
			if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
			and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
				self.HoveredObject = window
				break  -- First window hit
			end
		end
	end
	
	-- Notify all windows of hover change
	for _, window in ipairs(self.GuiObjects) do
		window.OnHoverChanged(self.HoveredObject)
	end
end

function ImGuiInput:CheckHoverByPos(pos)
	-- Find hovered object by position
	self.HoveredObject = nil
	
	for _, window in ipairs(self.GuiObjects) do
		if window.Visible then
			local guiObj = window.MainFrame
			local absPos = guiObj.AbsolutePosition
			local absSize = guiObj.AbsoluteSize
			
			if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
			and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
				self.HoveredObject = window
				break
			end
		end
	end
	
	for _, window in ipairs(self.GuiObjects) do
		window.OnHoverChanged(self.HoveredObject)
	end
end

function ImGuiInput:SetActiveWindows(windows)
	self.ActiveWindows = windows
end

function ImGuiInput:Update()
	-- Update any per-frame calculations
end

return ImGuiInput--[[
	ImGuiLibrary Window Module
	Implements a floating ImGui-style window with title bar, minimize,
	draggable behavior, ZIndex management, and content container.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ImGuiWindow = {}
ImGuiWindow.__index = ImGuiWindow

function ImGuiWindow.new(name, config, theme, animation)
	local self = setmetatable({}, ImGuiWindow)
	
	self.Name = name
	self.Theme = theme
	self.Animation = animation
	
	-- Properties from config
	self.Title = config.Title or name
	self.Icon = config.Icon or ""
	self.Position = config.Position or UDim2.new(0.5, -150, 0.5, -100)
	self.Size = config.Size or UDim2.new(0, 320, 0, 400)
	self.Visible = config.Visible ~= false
	self.Minimized = config.Minimized or false
	self.Draggable = config.Draggable ~= false
	self.ZIndex = config.ZIndex or 100
	self.Resizable = config.Resizable or false
	
	-- Content management
	self.SectionIndex = 0
	self.ComponentIndex = 0
	self.ContentContainer = nil
	self.Sections = {}
	
	-- Drag state
	self.Dragging = false
	self.DragOffset = Vector2.new(0, 0)
	self.LastUpdate = tick()
	
	-- Focus state
	self.IsFocused = false
	
	-- Callbacks
	self.OnFocusChanged = nil
	self.OnHoverChanged = function(hoveredObj) end
	
	-- Build the window structure
	self:Build()
	
	return self
end

-- Build the full window hierarchy
function ImGuiWindow:Build()
	local spacing = self.Theme:Get("Spacing")
	local shadow = self.Theme:Get("Shadow")
	local winTheme = self.Theme:Get("Window")
	
	-- Main window frame (root container)
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "ImGuiWindow"
	self.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.MainFrame.Position = self.Position
	self.MainFrame.Size = self.Size
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = self.ZIndex
	self.MainFrame.Visible = self.Visible
	
	-- Window shadow (approximation via ImageLabel)
	self.Shadow = Instance.new("ImageLabel")
	self.Shadow.Name = "Shadow"
	self.Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Shadow.Size = UDim2.new(1, shadow.Size * 2, 1, shadow.Size * 2)
	self.Shadow.BackgroundTransparency = 1
	self.Shadow.BorderSizePixel = 0
	self.Shadow.Image = "rbxassetid://105490971" -- Soft shadow texture
	self.Shadow.ImageColor3 = shadow.Color
	self.Shadow.ImageTransparency = shadow.Transparency
	self.Shadow.ZIndex = self.ZIndex - 1
	self.Shadow.Parent = self.MainFrame
	
	-- Window background (outer frame with border and shadow)
	self.Background = Instance.new("Frame")
	self.Background.Name = "Background"
	self.Background.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Background.Position = UDim2.new(0.5, shadow.Offset.X, 0.5, shadow.Offset.Y)
	self.Background.Size = UDim2.new(1, 0, 1, 0)
	self.Background.BackgroundColor3 = winTheme.BackgroundColor
	self.Background.BorderSizePixel = 0
	self.Background.ZIndex = self.ZIndex
	self.Background.Parent = self.MainFrame
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, spacing.WindowCornerRadius)
	corner.Parent = self.Background
	
	-- Border
	local border = Instance.new("UIStroke")
	border.Color = winTheme.BorderColor
	border.Thickness = spacing.WindowBorderSize
	border.Transparency = 0.5
	border.Parent = self.Background
	
	-- Title bar
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, -spacing.WindowBorderSize * 2, 0, spacing.WindowTitleBarHeight)
	self.TitleBar.Position = UDim2.new(0, spacing.WindowBorderSize, 0, spacing.WindowBorderSize)
	self.TitleBar.BackgroundColor3 = winTheme.TitleBarColor
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.ZIndex = self.ZIndex + 1
	self.TitleBar.Parent = self.Background
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, spacing.WindowCornerRadius - 2)
	titleCorner.Parent = self.TitleBar
	
	-- Title bar clip (to prevent corner bleeding)
	local titleClip = Instance.new("Frame")
	titleClip.Name = "TitleClip"
	titleClip.Size = UDim2.new(1, 0, 1, 0)
	titleClip.BackgroundTransparency = 1
	titleClip.BorderSizePixel = 0
	titleClip.ClipsDescendants = true
	titleClip.ZIndex = self.ZIndex + 1
	titleClip.Parent = self.TitleBar
	
	-- Icon
	self.IconLabel = Instance.new("ImageLabel")
	self.IconLabel.Name = "Icon"
	self.IconLabel.Size = UDim2.new(0, spacing.IconSize, 0, spacing.IconSize)
	self.IconLabel.Position = UDim2.new(0, 8, 0.5, 0)
	self.IconLabel.AnchorPoint = Vector2.new(0, 0.5)
	self.IconLabel.BackgroundTransparency = 1
	self.IconLabel.BorderSizePixel = 0
	self.IconLabel.Image = self.Icon ~= "" and self.Icon or ""
	self.IconLabel.ImageTransparency = self.Icon ~= "" and 1 or 0
	self.IconLabel.ZIndex = self.ZIndex + 2
	self.IconLabel.Parent = titleClip
	
	-- Title text
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.Size = UDim2.new(1, -40 - 20, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 32, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.BorderSizePixel = 0
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = winTheme.TitleTextColor
	self.TitleLabel.Font = self.Theme:Get("Typography").WindowTitleFont
	self.TitleLabel.TextSize = self.Theme:Get("Typography").WindowTitleSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.TitleLabel.ZIndex = self.ZIndex + 2
	self.TitleLabel.Parent = titleClip
	
	-- Minimize button
	self.MinimizeButton = Instance.new("TextButton")
	self.MinimizeButton.Name = "Minimize"
	self.MinimizeButton.Size = UDim2.new(0, spacing.MinimizeButtonSize * 2, 0, spacing.MinimizeButtonSize * 2)
	self.MinimizeButton.Position = UDim2.new(1, -spacing.MinimizeButtonSize, 0.5, 0)
	self.MinimizeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	self.MinimizeButton.BackgroundTransparency = 1
	self.MinimizeButton.BorderSizePixel = 0
	self.MinimizeButton.Text = ""
	self.MinimizeButton.ZIndex = self.ZIndex + 2
	self.MinimizeButton.Parent = titleClip
	
	local miniIcon = Instance.new("Frame")
	miniIcon.Name = "Icon"
	miniIcon.Size = UDim2.new(1, 0, 0, 2)
	miniIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	miniIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	miniIcon.BackgroundColor3 = winTheme.MinimizeButtonColor
	miniIcon.BorderSizePixel = 0
	miniIcon.ZIndex = self.ZIndex + 3
	miniIcon.Parent = self.MinimizeButton
	
	-- Connect minimize button
	self.MinimizeButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)
	
	-- Setup hover events for minimize button
	self.MinimizeButton.MouseEnter:Connect(function()
		if self.Minimized then return end
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(miniIcon, tweenInfo, {BackgroundColor3 = winTheme.MinimizeButtonHoverColor}):Play()
	end)
	
	self.MinimizeButton.MouseLeave:Connect(function()
		if self.Minimized then return end
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(miniIcon, tweenInfo, {BackgroundColor3 = winTheme.MinimizeButtonColor}):Play()
	end)
	
	-- Content container
	self.ContentContainer = Instance.new("Frame")
	self.ContentContainer.Name = "Content"
	self.ContentContainer.Size = UDim2.new(1, -spacing.WindowBorderSize * 2, 1, -spacing.WindowTitleBarHeight - spacing.WindowBorderSize * 2 - spacing.WindowPadding)
	self.ContentContainer.Position = UDim2.new(0, spacing.WindowBorderSize, 0, spacing.WindowTitleBarHeight + spacing.WindowPadding + spacing.WindowBorderSize)
	self.ContentContainer.BackgroundTransparency = 1
	self.ContentContainer.BorderSizePixel = 0
	self.ContentContainer.ClipsDescendants = true
	self.ContentContainer.ZIndex = self.ZIndex + 1
	self.ContentContainer.Parent = self.Background
	
	-- Scrolling frame for content
	self.ScrollFrame = Instance.new("ScrollingFrame")
	self.ScrollFrame.Name = "ScrollFrame"
	self.ScrollFrame.Size = self.ContentContainer.Size
	self.ScrollFrame.BackgroundTransparency = 1
	self.ScrollFrame.BorderSizePixel = 0
	self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.ScrollFrame.ScrollBarThickness = 0
	self.ScrollFrame.ZIndex = self.ZIndex + 1
	self.ScrollFrame.Parent = self.ContentContainer
	
	-- UIListLayout for sections (auto-vertical layout)
	self.ListLayout = Instance.new("UIListLayout")
	self.ListLayout.FillDirection = Enum.FillDirection.Vertical
	self.ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.ListLayout.Padding = UDim.new(0, spacing.SectionSpacing)
	self.ListLayout.SortOrder = Enum.SortOrder.Name
	self.ListLayout.ZIndex = self.ZIndex + 1
	self.ListLayout.Parent = self.ScrollFrame
	
	-- Update scroll constraints
	self.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y)
	end)
	
	-- Initial scroll setup
	self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	-- Drag handling setup
	self:SetupDragHandling()
	
	-- If minimized initially
	if self.Minimized then
		self.ContentContainer.Visible = false
		self.ContentContainer.GroupTransparency = 1
	end
end

-- Setup mouse/touch drag handling for the title bar
function ImGuiWindow:SetupDragHandling()
	if not self.Draggable then return end
	
	self.TitleBar.MouseButton1Down:Connect(function()
		self.Dragging = true
		self:FocusWindow()
		self.DragStartPos = UserInputService:GetMouseLocation()
		self.WindowStartPos = self.MainFrame.Position
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and self.Dragging then
			local mousePos = UserInputService:GetMouseLocation()
			local delta = mousePos - self.DragStartPos
			
			local newX = self.WindowStartPos.X.Offset + delta.X
			local newY = self.WindowStartPos.Y.Offset + delta.Y
			
			-- Constrain to screen
			local viewportSize = game.Workspace.CurrentCamera.ViewportSize
			local windowSize = self.MainFrame.AbsoluteSize
			
			newX = math.clamp(newX, 0, viewportSize.X - windowSize.X)
			newY = math.clamp(newY, 0, viewportSize.Y - windowSize.Y)
			
			self.MainFrame.Position = UDim2.new(self.WindowStartPos.X.Scale, newX, self.WindowStartPos.Y.Scale, newY)
		end
	end)
end

-- Focus this window (bring to front)
function ImGuiWindow:FocusWindow()
	if self.IsFocused then return end
	
	self.IsFocused = true
	
	-- Animate ZIndex up
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(self.MainFrame, tweenInfo, {ZIndex = self.ZIndex + 1000}):Play()
	self.Shadow.ZIndex = self.ZIndex + 999
	
	self.ZIndex = self.ZIndex + 1000
	
	-- Notify callback
	if self.OnFocusChanged then
		self.OnFocusChanged(self, true)
	end
end

-- Blur all other windows
function ImGuiWindow:BlurOtherWindows()
	for _, window in ipairs(self.Parent and self.Parent.Windows or {}) do
		if window ~= self and window.ZIndex then
			window.ZIndex = window.ZIndex - 1000
		end
	end
end

-- Toggle minimize state
function ImGuiWindow:ToggleMinimize()
	self.Minimized = not self.Minimized
	
	if self.Minimized then
		-- Animate content away
		self.Animation:Minimize(self.ContentContainer, false)
		
		-- Shrink window height
		local currentSize = self.Background.Size
		local targetSize = UDim2.new(
			currentSize.X.Scale,
			currentSize.X.Offset,
			0,
			(self.Theme:Get("Spacing").WindowTitleBarHeight + self.Theme:Get("Spacing").WindowBorderSize * 2)
		)
		
		local tweenInfo = TweenInfo.new(
			self.Theme:Get("Animation").MinimizeDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		TweenService:Create(self.Background, tweenInfo, {Size = targetSize}):Play()
		
		-- Rotate minimize icon
		local miniIcon = self.MinimizeButton:FindFirstChild("Icon")
		if miniIcon then
			TweenService:Create(miniIcon, tweenInfo, {Rotation = 180}):Play()
		end
	else
		-- Animate content back
		self.Animation:Minimize(self.ContentContainer, true)
		
		-- Restore window height
		local currentSize = self.Background.Size
		local targetSize = self.Size
		
		local tweenInfo = TweenInfo.new(
			self.Theme:Get("Animation").MinimizeDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		TweenService:Create(self.Background, tweenInfo, {Size = targetSize}):Play()
		
		-- Reset minimize icon
		local miniIcon = self.MinimizeButton:FindFirstChild("Icon")
		if miniIcon then
			TweenService:Create(miniIcon, tweenInfo, {Rotation = 0}):Play()
		end
	end
end

-- Set window visibility
function ImGuiWindow:SetVisible(visible)
	if self.Visible == visible then return end
	
	self.Visible = visible
	
	if visible then
		self.Animation:WindowAppear(self.MainFrame)
	else
		self.Animation:WindowDisappear(self.MainFrame, nil, function()
			self.MainFrame.Visible = false
		end)
	end
end

-- Create a new section
function ImGuiWindow:CreateSection(title, config)
	config = config or {}
	config.Title = title
	config.Theme = self.Theme
	config.Animation = self.Animation
	config.ZIndexBase = self.ZIndex + 10
	config.Parent = self.ScrollFrame
	
	local section = self.SectionClass.new(config)
	self.Sections[#self.Sections + 1] = section
	
	if self.OnSectionAdded then
		self.OnSectionAdded(section)
	end
	
	return section
end

-- Get content canvas size
function ImGuiWindow:GetContentSize()
	return self.ListLayout.AbsoluteContentSize
end

-- Destroy the window
function ImGuiWindow:Destroy()
	if self.MainFrame and self.MainFrame.Parent then
		self.MainFrame:Destroy()
	end
end

return ImGuiWindow--[[
	ImGuiLibrary WindowManager Module
	Manages multiple independent floating windows, handles ZIndex stacking,
	focus management, and responsive positioning.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ImGuiWindowManager = {}
ImGuiWindowManager.__index = ImGuiWindowManager

function ImGuiWindowManager.new(theme, animation, parent)
	local self = setmetatable({}, ImGuiWindowManager)
	
	self.Theme = theme
	self.Animation = animation
	self.Parent = parent or game:GetService("CoreGui")
	self.Windows = {}
	self.BaseZIndex = 100
	self.HighestZIndex = self.BaseZIndex
	self.LastFocusedWindow = nil
	
	-- Input handler
	local ImGuiInput = require(script.Parent.Input)
	self.Input = ImGuiInput.new(self.Windows)
	
	-- Responsive settings
	self.Scale = 1.0
	self.ResponsiveEnabled = true
	
	-- Initialize responsive update
	self:InitResponsive()
	
	return self
end

-- Initialize responsive scaling based on screen size
function ImGuiWindowManager:InitResponsive()
	-- Detect screen size and calculate scale
	local function updateScale()
		local viewport = game.Workspace.CurrentCamera.ViewportSize
		local baseWidth = 320
		local minWidth = baseWidth * self.Theme:Get("Responsive").MinScale
		
		-- Calculate scale based on viewport width
		if viewport.X < baseWidth then
			self.Scale = math.max(viewport.X / baseWidth, self.Theme:Get("Responsive").MinScale)
		else
			self.Scale = math.min(viewport.X / baseWidth * 0.5, self.Theme:Get("Responsive").MaxScale)
		end
		
		self.Scale = math.clamp(self.Scale, self.Theme:Get("Responsive").MinScale, self.Theme:Get("Responsive").MaxScale)
	end
	
	updateScale()
	
	-- Listen for viewport changes
	game.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Register a window with the manager
function ImGuiWindowManager:RegisterWindow(window)
	window.Parent = self
	window.Index = #self.Windows + 1
	window.ZIndex = self.BaseZIndex + window.Index
	window.OnFocusChanged = function(win, focused)
		if focused then
			self:FocusWindow(win)
		end
	end
	
	-- Add to list
	self.Windows[#self.Windows + 1] = window
	
	-- Parent the window frame
	if window.MainFrame then
		window.MainFrame.Parent = self.Parent
	end
	
	-- Refresh input handler
	self.Input.GuiObjects = self.Windows
	
	-- Animate appearance if visible
	if window.Visible then
		self.Animation:WindowAppear(window.MainFrame)
	end
	
	return window
end

-- Unregister and destroy a window
function ImGuiWindowManager:UnregisterWindow(window)
	local index = table.find(self.Windows, window)
	if index then
		table.remove(self.Windows, index)
		
		-- Reindex remaining windows
		for i, w in ipairs(self.Windows) do
			w.Index = i
			w.ZIndex = self.BaseZIndex + i
		end
		
		-- Destroy the window
		window:Destroy()
		
		-- Refresh input handler
		self.Input.GuiObjects = self.Windows
	end
end

-- Focus a window (bring to front)
function ImGuiWindowManager:FocusWindow(window)
	-- Blur previously focused window
	if self.LastFocusedWindow and self.LastFocusedWindow ~= window then
		self.LastFocusedWindow.IsFocused = false
	end
	
	-- Increment global ZIndex
	self.HighestZIndex = self.HighestZIndex + 1
	
	-- Set window to top
	window.ZIndex = self.HighestZIndex
	window.IsFocused = true
	self.LastFocusedWindow = window
	
	-- Update all window Z-indices (only actual window frames, not children)
	for _, w in ipairs(self.Windows) do
		if w.MainFrame then
			w.MainFrame.ZIndex = w.ZIndex
			if w.Shadow then
				w.Shadow.ZIndex = w.ZIndex - 1
			end
		end
	end
end

-- Get window by name
function ImGuiWindowManager:GetWindow(name)
	for _, window in ipairs(self.Windows) do
		if window.Name == name then
			return window
		end
	end
	return nil
end

-- Get all windows
function ImGuiWindowManager:GetAllWindows()
	return self.Windows
end

-- Set all windows visibility
function ImGuiWindowManager:SetAllVisible(visible)
	for _, window in ipairs(self.Windows) do
		window:SetVisible(visible)
	end
end

-- Hide all windows (toggle)
function ImGuiWindowManager:ToggleAll()
	local anyVisible = false
	for _, window in ipairs(self.Windows) do
		if window.Visible then
			anyVisible = true
			break
		end
	end
	
	self:SetAllVisible(not anyVisible)
end

-- Arrange windows in a grid pattern
function ImGuiWindowManager:ArrangeWindows(config)
	config = config or {}
	local padding = config.Padding or 20
	local cols = config.Columns or 2
	local startX = config.StartX or 0.1
	local startY = config.StartY or 0.1
	local direction = config.Direction or "right"
	
	local viewport = game.Workspace.CurrentCamera.ViewportSize
	local windowCount = #self.Windows
	
	if windowCount == 0 then return end
	
	local col = 0
	local row = 0
	
	for i, window in ipairs(self.Windows) do
		-- Calculate position
		local x = startX + (col * (1 / cols))
		local y = startY + (row * 0.3)
		
		-- Alternate direction
		if direction == "alternate" then
			if col % 2 == 1 then
				y = y + 0.1
			end
		end
		
		window.MainFrame.Position = UDim2.new(x, padding, y, padding)
		
		-- Update row/col
		col = col + 1
		if col >= cols then
			col = 0
			row = row + 1
		end
	end
end

-- Stack windows vertically
function ImGuiWindowManager:StackVertically(config)
	config = config or {}
	local padding = config.Padding or 20
	local startX = config.StartX or 0.5
	local startY = config.StartY or 0.1
	local spacing = config.Spacing or 20
	
	local y = startY
	
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(startX, 0, 0, y)
		y = y + window.MainFrame.AbsoluteSize.Y + spacing
	end
end

-- Stack windows horizontally
function ImGuiWindowManager:StackHorizontally(config)
	config = config or {}
	local startX = config.StartX or 0.1
	local startY = config.StartY or 0.5
	local spacing = config.Spacing or 20
	
	local x = startX
	
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(0, x, startY, 0)
		x = x + window.MainFrame.AbsoluteSize.X + spacing
	end
end

-- Center all windows
function ImGuiWindowManager:CenterAll()
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
end

-- Destroy all windows
function ImGuiWindowManager:DestroyAll()
	for _, window in ipairs(self.Windows) do
		window:Destroy()
	end
	self.Windows = {}
end

-- Update (called every frame if needed)
function ImGuiWindowManager:Update()
	-- Handle window dragging for touch
	for _, window in ipairs(self.Windows) do
		if window.Dragging and window.InputHandler then
			window.InputHandler:Update()
		end
	end
end

-- Get current scale
function ImGuiWindowManager:GetScale()
	return self.Scale
end

-- Set global scale
function ImGuiWindowManager:SetScale(scale)
	self.Scale = math.clamp(scale, 
		self.Theme:Get("Responsive").MinScale, 
		self.Theme:Get("Responsive").MaxScale)
end

return ImGuiWindowManager--[[
	ImGuiLibrary Core Init Module
	Sets up Theme, Animation, Input, WindowManager, and provides API
	Top-level: UILibrary namespace
]]

local ImGuiLibrary = {}
ImGuiLibrary.__index = ImGuiLibrary

-- Services reference
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function ImGuiLibrary.new()
	local self = setmetatable({}, ImGuiLibrary)
	
	-- Initialize theme (centralized)
	self.Theme = require(script.Parent.Parent.Theme)
	
	-- Initialize animation (wraps TweenService)
	self.Animation = require(script.Parent.Parent.Animation)
	
	-- Input handler (initialized when windows are created)
	self.InputHandler = nil
	
	-- WindowManager
	self.WindowManager = nil
	
	-- Active windows reference
	self.ActiveWindows = {}
	
	return self
end

-- Initialize or recreate WindowManager
function ImGuiLibrary:Initialize()
	if not self.WindowManager then
		self.Animation = require(script.Parent.Animation)
		self.InputHandler = require(script.Parent.Input)
		
		self.WindowManager = require(script.Parent.WindowManager)
		self.WindowManager = self.WindowManager.new(
			self.Theme,
			self.Animation,
			game:GetService("CoreGui")
		)
	end
	
	return self.WindowManager
end

-- Create a new window (main API entry)
function ImGuiLibrary:Window(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = require(script.Parent.Window).new(config.Title or "Window", config, self.Theme, self.Animation)
	
	-- Register with WindowManager
	local manager = self:Initialize()
	manager:RegisterWindow(window)
	
	-- Update input handler
	window.InputHandler = self.InputHandler
	
	-- Store reference
	self.ActiveWindows[window.Name] = window
	
	return window
end

-- Close a window by name
function ImGuiLibrary:CloseWindow(name)
	if self.ActiveWindows[name] then
		self.ActiveWindows[name]:SetVisible(false)
		self.ActiveWindows[name] = nil
	end
end

-- Close all windows
function ImGuiLibrary:CloseAllWindows()
	for name, window in pairs(self.ActiveWindows) do
		window:SetVisible(false)
	end
	self.ActiveWindows = {}
end

-- Get a window by name
function ImGuiLibrary:GetWindow(name)
	return self.ActiveWindows[name]
end

-- Toggle all windows visibility
function ImGuiLibrary:ToggleAllWindows()
	if #self.ActiveWindows == 0 then
		-- If no windows exist, create one and show
		self:Window({Title = "ImGui Library"}).MainFrame.Visible = true
		return
	end
	
	for name, window in pairs(self.ActiveWindows) do
		window:SetVisible(not window.Visible)
	end
end

-- Create a section within a window
function ImGuiLibrary:Section(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	-- Get the current active window or create default
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	return window:CreateSection(config.Title or "Section", config)
end

-- Create a button within a window
function ImGuiLibrary:Button(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	return window:CreateSection(config.Title or "Button"):AddInstance(
		require(script.Parent.Parent.Components.Button).new({
			Text = config.Text or "Button",
			OnClicked = config.OnClicked,
			Theme = self.Theme,
			Animation = self.Animation,
			ZIndexBase = config.ZIndexBase
		})
	)
end

-- Create a toggle within a window
function ImGuiLibrary:Toggle(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local toggle = require(script.Parent.Parent.Components.Toggle).new({
		Text = config.Text or "Toggle",
		Value = config.Value or false,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Toggle"):AddInstance(toggle)
end

-- Create a slider within a window
function ImGuiLibrary:Slider(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local slider = require(script.Parent.Parent.Components.Slider).new({
		Text = config.Text or "Slider",
		Min = config.Min or 0,
		Max = config.Max or 100,
		Value = config.Value or 50,
		Precision = config.Precision,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Slider"):AddInstance(slider)
end

-- Create a dropdown within a window
function ImGuiLibrary:Dropdown(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local dropdown = require(script.Parent.Parent.Components.Dropdown).new({
		Text = config.Text or "Dropdown",
		Options = config.Options or {"Option 1", "Option 2", "Option 3"},
		Value = config.Value,
		MultiSelect = config.MultiSelect or false,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Dropdown"):AddInstance(dropdown)
end

-- Get all active windows
function ImGuiLibrary:GetAllWindows()
	return self.ActiveWindows
end

-- Theme shortcuts
function ImGuiLibrary:Theme()
	return self.Theme
end

function ImGuiLibrary:Animation()
	return self.Animation
end

return ImGuiLibrary--[[
	ImGuiLibrary Button Component
	Minimalist monochrome button with hover/pressed feedback
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ImGuiButton = {}
ImGuiButton.__index = ImGuiButton

function ImGuiButton.new(config)
	local self = setmetatable({}, ImGuiButton)
	
	self.Text = config.Text or "Button"
	self.Theme = config.Theme
	self.Animation = config.Animation
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	self.Size = config.Size or UDim2.new(1, 0, 0, 32)
	self.OnClicked = config.OnClicked
	self.Disabled = config.Disabled or false
	
	-- Visual properties
	local buttonTheme = self.Theme:Get("Button")
	local spacing = self.Theme:Get("Spacing")
	local typography = self.Theme:Get("Typography")
	
	-- Main button frame
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Button"
	self.MainFrame.Size = self.Size
	self.MainFrame.BackgroundColor3 = buttonTheme.BackgroundColor
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.Parent = self.Parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, buttonTheme.CornerRadius)
	corner.Parent = self.MainFrame
	
	local border = Instance.new("UIStroke")
	border.Color = buttonTheme.BorderColor
	border.Thickness = spacing.BorderSize
	border.Transparency = 0.5
	border.Parent = self.MainFrame
	
	-- Text label
	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Size = UDim2.new(1, -12, 1, 0)
	self.TextLabel.Position = UDim2.new(0, 6, 0, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.BorderSizePixel = 0
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = buttonTheme.TextColor
	self.TextLabel.Font = typography.ButtonFont
	self.TextLabel.TextSize = typography.ButtonSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Center
	self.TextLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.TextLabel.ZIndex = self.ZIndexBase + 1
	self.TextLabel.Parent = self.MainFrame
	
	-- Hover state tracking
	self.IsHovered = false
	self.IsPressed = false
	
	-- Input handling
	self.MainFrame.MouseEnter:Connect(function()
		if self.Disabled then return end
		self.IsHovered = true
		TweenService:Create(self.MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = buttonTheme.HoverColor
		}):Play()
	end)
	
	self.MainFrame.MouseLeave:Connect(function()
		self.IsHovered = false
		self.IsPressed = false
		TweenService:Create(self.MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = buttonTheme.BackgroundColor
		}):Play()
	end)
	
	self.MainFrame.MouseButton1Down:Connect(function()
		if self.Disabled then return end
		self.IsPressed = true
		TweenService:Create(self.MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
			BackgroundColor3 = buttonTheme.PressedColor
		}):Play()
	end)
	
	self.MainFrame.MouseButton1Up:Connect(function()
		if self.Disabled then return end
		self.IsPressed = false
		TweenService:Create(self.MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = self.IsHovered and buttonTheme.HoverColor or buttonTheme.BackgroundColor
		}):Play()
		
		if self.OnClicked then
			self.OnClicked(self)
		end
	end)
	
	-- Touch support
	self.MainFrame.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self.IsPressed = true
			TweenService:Create(self.MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
				BackgroundColor3 = buttonTheme.PressedColor
			}):Play()
		end
	end)
	
	self.MainFrame.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self.IsPressed = false
			TweenService:Create(self.MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				BackgroundColor3 = self.IsHovered and buttonTheme.HoverColor or buttonTheme.BackgroundColor
			}):Play()
			
			if self.OnClicked then
				self.OnClicked(self)
			end
		end
	end)
	
	-- Disable state
	self.MainFrame.InputBegan:Connect(function(input, processed)
		if self.Disabled then
			self.MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end
	end)
	
	return self
end

-- Set disabled state
function ImGuiButton:SetDisabled(disabled)
	self.Disabled = disabled
	if disabled then
		self.MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		self.TextLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	else
		self.MainFrame.BackgroundColor3 = self.Theme:Get("Button").BackgroundColor
		self.TextLabel.TextColor3 = self.Theme:Get("Button").TextColor
	end
end

-- Set text
function ImGuiButton:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
end

-- Set button size
function ImGuiButton:SetSize(size)
	self.Size = size
	self.MainFrame.Size = size
end

-- Highlight/activate animation
function ImGuiButton:Highlight()
	local theme = self.Theme:Get("Button")
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(self.MainFrame, tweenInfo, {
		BackgroundColor3 = theme.HoverColor
	}):Play()
end

return ImGuiButton--[[
	ImGuiLibrary Toggle Component
	Minimalist switch with smooth state transition
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ImGuiToggle = {}
ImGuiToggle.__index = ImGuiToggle

function ImGuiToggle.new(config)
	local self = setmetatable({}, ImGuiToggle)
	
	self.Text = config.Text or "Toggle"
	self.Value = config.Value or false
	self.Theme = config.Theme
	self.Animation = config.Animation
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	self.Size = config.Size or UDim2.new(0, 40, 0, 18) -- default compact size
	self.OnChanged = config.OnChanged
	
	-- Visual properties
	local toggleTheme = self.Theme:Get("Toggle")
	local spacing = self.Theme:Get("Spacing")
	local typography = self.Theme:Get("Typography")
	
	-- Main container (holds label and switch)
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Toggle"
	self.MainFrame.Size = self.Size
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.Parent = self.Parent
	
	-- Label (optional, if text provided)
	if self.Text and self.Text ~= "" then
		self.Label = Instance.new("TextLabel")
		self.Label.Name = "Label"
		self.Label.Size = UDim2.new(0.5, -4, 1, 0)
		self.Label.Position = UDim2.new(0, 0, 0, 0)
		self.Label.BackgroundTransparency = 1
		self.Label.BorderSizePixel = 0
		self.Label.Text = self.Text
		self.Label.TextColor3 = toggleTheme.LabelTextColor or self.Theme:Get("Label").PrimaryTextColor
		self.Label.Font = typography.LabelFont
		self.Label.TextSize = typography.LabelSize
		self.Label.TextXAlignment = Enum.TextXAlignment.Left
		self.Label.TextYAlignment = Enum.TextYAlignment.Center
		self.Label.ZIndex = self.ZIndexBase + 1
		self.Label.Parent = self.MainFrame
		
		-- Switch will be on the right side
		self.SwitchSize = UDim2.new(0.5, -4, 1, 0)
		self.SwitchPosition = UDim2.new(0.5, 4, 0, 0)
	else
		self.Label = nil
		self.SwitchSize = UDim2.new(1, 0, 1, 0)
		self.SwitchPosition = UDim2.new(0, 0, 0, 0)
	end
	
	-- Switch container (background track)
	self.SwitchFrame = Instance.new("Frame")
	self.SwitchFrame.Name = "Switch"
	self.SwitchFrame.Size = self.SwitchSize
	self.SwitchFrame.Position = self.SwitchPosition
	self.SwitchFrame.BackgroundTransparency = 1
	self.SwitchFrame.BorderSizePixel = 0
	self.SwitchFrame.ZIndex = self.ZIndexBase + 1
	self.SwitchFrame.Parent = self.MainFrame
	
	-- Track (background)
	self.Track = Instance.new("Frame")
	self.Track.Name = "Track"
	self.Track.Size = UDim2.new(1, 0, 0, toggleTheme.TrackHeight)
	self.Track.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Track.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Track.BackgroundColor3 = self.Value and toggleTheme.OnTrackColor or toggleTheme.OffTrackColor
	self.Track.BorderSizePixel = 0
	self.Track.ZIndex = self.ZIndexBase + 2
	self.Track.Parent = self.SwitchFrame
	
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 999) -- pill shape
	trackCorner.Parent = self.Track
	
	-- Thumb (knob)
	self.Thumb = Instance.new("Frame")
	self.Thumb.Name = "Thumb"
	self.Thumb.Size = UDim2.new(0, toggleTheme.ThumbSize, 0, toggleTheme.ThumbSize)
	self.Thumb.Position = UDim2.new(self.Value and (1 - (toggleTheme.ThumbSize / toggleTheme.TrackWidth)) or 0, 0, 0.5, 0)
	self.Thumb.AnchorPoint = Vector2.new(0, 0.5)
	self.Thumb.BackgroundColor3 = self.Value and toggleTheme.OnThumbColor or toggleTheme.OffThumbColor
	self.Thumb.BorderSizePixel = 0
	self.Thumb.ZIndex = self.ZIndexBase + 3
	self.Thumb.Parent = self.SwitchFrame
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0) -- circle
	thumbCorner.Parent = self.Thumb
	
	-- State tracking
	self.IsHovered = false
	self.IsPressed = false
	
	-- Input handling
	self.SwitchFrame.MouseEnter:Connect(function()
		self.IsHovered = true
		self:UpdateHoverState()
	end)
	
	self.SwitchFrame.MouseLeave:Connect(function()
		self.IsHovered = false
		self.IsPressed = false
		self:UpdateHoverState()
	end)
	
	self.SwitchFrame.MouseButton1Down:Connect(function()
		self.IsPressed = true
		self:UpdatePressedState()
	end)
	
	self.SwitchFrame.MouseButton1Up:Connect(function()
		self.IsPressed = false
		self:UpdatePressedState()
		
		-- Toggle value
		self:SetValue(not self.Value, true)
	end)
	
	-- Touch support
	self.SwitchFrame.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self.IsPressed = true
			self:UpdatePressedState()
		end
	end)
	
	self.SwitchFrame.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self.IsPressed = false
			self:UpdatePressedState()
			
			self:SetValue(not self.Value, true)
		end
	end)
	
	-- Keyboard support (if needed)
	-- self.MainFrame.FocusLost:Connect(function(enterPressed) ... end)
	
	return self
end

-- Update hover visual feedback
function ImGuiToggle:UpdateHoverState()
	local toggleTheme = self.Theme:Get("Toggle")
	if self.IsPressed then
		-- Pressed: slightly darker track
		self.Track.BackgroundColor3 = self.Value and 
			self:DarkenColor(toggleTheme.OnTrackColor, 0.1) or 
			self:DarkenColor(toggleTheme.OffTrackColor, 0.1)
	elseif self.IsHovered then
		-- Hovered: slightly lighter track
		self.Track.BackgroundColor3 = self.Value and 
			self:LightenColor(toggleTheme.OnTrackColor, 0.05) or 
			self:LightenColor(toggleTheme.OffTrackColor, 0.05)
	else
		-- Normal
		self.Track.BackgroundColor3 = self.Value and toggleTheme.OnTrackColor or toggleTheme.OffTrackColor
	end
end

-- Update pressed visual feedback
function ImGuiToggle:UpdatePressedState()
	if self.IsPressed then
		-- When pressed, make track a bit more opaque
		self.Track.BackgroundColor3 = self.Value and 
			self:LightenColor(toggleTheme.OnTrackColor, 0.08) or 
			self:LightenColor(toggleTheme.OffTrackColor, 0.08)
	end
end

-- Lighten a color
function ImGuiToggle:LightenColor(color, amount)
	return Color3.new(
		math.min(color.R + amount, 1),
		math.min(color.G + amount, 1),
		math.min(color.B + amount, 1)
	)
end

-- Darken a color
function ImGuiToggle:DarkenColor(color, amount)
	return Color3.new(
		math.max(color.R - amount, 0),
		math.max(color.G - amount, 0),
		math.max(color.B - amount, 0)
	)
end

-- Set value programmatically
function ImGuiToggle:SetValue(value, animate)
	if self.Value == value then return end
	
	self.Value = value
	
	if animate then
		self.Animation:Toggle(self.Thumb, value, self.Track, self.Theme)
	else
		-- Instant change
		self.Track.BackgroundColor3 = value and self.Theme:Get("Toggle").OnTrackColor or self.Theme:Get("Toggle").OffTrackColor
		self.Thumb.BackgroundColor3 = value and self.Theme:Get("Toggle").OnThumbColor or self.Theme:Get("Toggle").OffThumbColor
		
		local toggleTheme = self.Theme:Get("Toggle")
		local thumbPos = value and (1 - (toggleTheme.ThumbSize / toggleTheme.TrackWidth)) or 0
		self.Thumb.Position = UDim2.new(thumbPos, 0, 0.5, 0)
	end
	
	if self.OnChanged then
		self.OnChanged(self, value)
	end
end

-- Get current value
function ImGuiToggle:GetValue()
	return self.Value
end

-- Set label text
function ImGuiToggle:SetLabel(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
end

return ImGuiToggle--[[
	ImGuiLibrary Slider Component
	Custom minimalist slider with track, thumb, and value display
	Supports continuous values, decimal precision, touch input
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ImGuiSlider = {}
ImGuiSlider.__index = ImGuiSlider

function ImGuiSlider.new(config)
	local self = setmetatable({}, ImGuiSlider)
	
	self.Text = config.Text or "Slider"
	self.Min = config.Min or 0
	self.Max = config.Max or 100
	self.Value = math.clamp(config.Value or self.Min, self.Min, self.Max)
	self.Precision = config.Precision or 0
	self.Theme = config.Theme
	self.Animation = config.Animation
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	self.Size = config.Size or UDim2.new(1, 0, 0, 40)
	self.OnChanged = config.OnChanged
	self.AllowExceed = config.AllowExceed or false
	
	-- Visual properties
	local sliderTheme = self.Theme:Get("Slider")
	local spacing = self.Theme:Get("Spacing")
	local typography = self.Theme:Get("Typography")
	
	-- Main container
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Slider"
	self.MainFrame.Size = self.Size
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.Parent = self.Parent
	
	-- Top row (label and value)
	self.TopRow = Instance.new("Frame")
	self.TopRow.Name = "TopRow"
	self.TopRow.Size = UDim2.new(1, 0, 0, 16)
	self.TopRow.BackgroundTransparency = 1
	self.TopRow.BorderSizePixel = 0
	self.TopRow.ZIndex = self.ZIndexBase + 1
	self.TopRow.Parent = self.MainFrame
	
	-- Label
	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Label"
	self.Label.Size = UDim2.new(0.7, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.BorderSizePixel = 0
	self.Label.Text = self.Text
	self.Label.TextColor3 = sliderTheme.LabelTextColor
	self.Label.Font = typography.LabelFont
	self.Label.TextSize = typography.LabelSize
	self.Label.TextXAlignment = Enum.TextXAlignment.Left
	self.Label.TextYAlignment = Enum.TextYAlignment.Center
	self.Label.ZIndex = self.ZIndexBase + 2
	self.Label.Parent = self.TopRow
	
	-- Value
	self.ValueLabel = Instance.new("TextLabel")
	self.ValueLabel.Name = "Value"
	self.ValueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	self.ValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	self.ValueLabel.BackgroundTransparency = 1
	self.ValueLabel.BorderSizePixel = 0
	self.ValueLabel.Text = self:FormatValue(self.Value)
	self.ValueLabel.TextColor3 = sliderTheme.ValueTextColor
	self.ValueLabel.Font = typography.ValueFont
	self.ValueLabel.TextSize = typography.ValueSize
	self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.ValueLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.ValueLabel.ZIndex = self.ZIndexBase + 2
	self.ValueLabel.Parent = self.TopRow
	
	-- Bottom row (slider track area)
	self.BottomRow = Instance.new("Frame")
	self.BottomRow.Name = "BottomRow"
	self.BottomRow.Size = UDim2.new(1, 0, 0, sliderTheme.ThumbSize + 8)
	self.BottomRow.Position = UDim2.new(0, 0, 0, 18)
	self.BottomRow.BackgroundTransparency = 1
	self.BottomRow.BorderSizePixel = 0
	self.BottomRow.ZIndex = self.ZIndexBase + 1
	self.BottomRow.Parent = self.MainFrame
	
	-- Track (background)
	self.Track = Instance.new("Frame")
	self.Track.Name = "Track"
	self.Track.Size = UDim2.new(1, 0, 0, sliderTheme.TrackHeight)
	self.Track.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Track.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Track.BackgroundColor3 = sliderTheme.TrackColor
	self.Track.BorderSizePixel = 0
	self.Track.ZIndex = self.ZIndexBase + 2
	self.Track.Parent = self.BottomRow
	
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, sliderTheme.TrackHeight / 2)
	trackCorner.Parent = self.Track
	
	-- Track fill (filled portion)
	self.TrackFill = Instance.new("Frame")
	self.TrackFill.Name = "TrackFill"
	self.TrackFill.Size = UDim2.new(self:GetValueRatio(), 0, 1, 0)
	self.TrackFill.BackgroundColor3 = sliderTheme.TrackFillColor
	self.TrackFill.BorderSizePixel = 0
	self.TrackFill.ZIndex = self.ZIndexBase + 3
	self.TrackFill.Parent = self.Track
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, sliderTheme.TrackHeight / 2)
	fillCorner.Parent = self.TrackFill
	
	-- Marker points
	for i = 1, sliderTheme.MarkerCount do
		local marker = Instance.new("Frame")
		marker.Name = "Marker" .. i
		marker.Size = UDim2.new(0, 2, 0, 8)
		marker.Position = UDim2.new((i - 1) / (sliderTheme.MarkerCount - 1), 0, 0.5, 0)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BackgroundColor3 = sliderTheme.MarkerColor
		marker.BorderSizePixel = 0
		marker.ZIndex = self.ZIndexBase + 4
		marker.Parent = self.Track
	end
	
	-- Thumb (knob)
	self.Thumb = Instance.new("Frame")
	self.Thumb.Name = "Thumb"
	self.Thumb.Size = UDim2.new(0, sliderTheme.ThumbSize, 0, sliderTheme.ThumbSize)
	self.Thumb.Position = UDim2.new(self:GetValueRatio(), 0, 0.5, 0)
	self.Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Thumb.BackgroundColor3 = sliderTheme.ThumbColor
	self.Thumb.BorderSizePixel = 0
	self.Thumb.ZIndex = self.ZIndexBase + 5
	self.Thumb.Parent = self.BottomRow
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0) -- circle
	thumbCorner.Parent = self.Thumb
	
	-- Touch target (invisible larger area for mobile)
	self.TouchTarget = Instance.new("Frame")
	self.TouchTarget.Name = "TouchTarget"
	self.TouchTarget.Size = UDim2.new(1, 0, 1, 16)
	self.TouchTarget.Position = UDim2.new(0, 0, 0, -8)
	self.TouchTarget.BackgroundTransparency = 1
	self.TouchTarget.BorderSizePixel = 0
	self.TouchTarget.ZIndex = self.ZIndexBase + 6
	self.TouchTarget.Parent = self.BottomRow
	
	-- State tracking
	self.Dragging = false
	self.IsHovered = false
	
	-- Input handling - mouse
	self.TouchTarget.MouseEnter:Connect(function()
		self.IsHovered = true
		self:UpdateThumbSize(true)
	end)
	
	self.TouchTarget.MouseLeave:Connect(function()
		if not self.Dragging then
			self.IsHovered = false
			self:UpdateThumbSize(false)
		end
	end)
	
	self.TouchTarget.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = true
			self:HandleInput(input)
		end
	end)
	
	-- Track also clickable
	self.Track.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self.Dragging = true
			self:HandleInput(input)
		end
	end)
	
	-- Global input tracking
	UserInputService.InputChanged:Connect(function(input, processed)
		if processed then return end
		if self.Dragging and 
		   (input.UserInputType == Enum.UserInputType.MouseMovement or 
		    input.UserInputType == Enum.UserInputType.Touch) then
			self:HandleInput(input)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			if self.Dragging then
				self.Dragging = false
				self:UpdateThumbSize(self.IsHovered)
			end
		end
	end)
	
	return self
end

-- Get ratio (0 to 1) from current value
function ImGuiSlider:GetValueRatio()
	local range = self.Max - self.Min
	if range == 0 then return 0 end
	return (self.Value - self.Min) / range
end

-- Get value from ratio (0 to 1)
function ImGuiSlider:GetValueFromRatio(ratio)
	local value = self.Min + ratio * (self.Max - self.Min)
	
	-- Apply precision
	if self.Precision > 0 then
		local mult = 10 ^ self.Precision
		value = math.floor(value * mult + 0.5) / mult
	else
		value = math.floor(value + 0.5)
	end
	
	return math.clamp(value, self.Min, self.Max)
end

-- Format value for display
function ImGuiSlider:FormatValue(value)
	if self.Precision > 0 then
		return string.format("%." .. self.Precision .. "f", value)
	else
		return tostring(math.floor(value))
	end
end

-- Update thumb visual size based on hover
function ImGuiSlider:UpdateThumbSize(enlarged)
	local sliderTheme = self.Theme:Get("Slider")
	local targetSize = enlarged and sliderTheme.ThumbSize + 2 or sliderTheme.ThumbSize
	
	TweenService:Create(self.Thumb, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, targetSize, 0, targetSize)
	}):Play()
end

-- Handle input (mouse or touch)
function ImGuiSlider:HandleInput(input)
	if not self.Dragging then return end
	
	local inputPos = input.Position or UserInputService:GetMouseLocation()
	
	-- Get track bounds
	local trackAbsPos = self.Track.AbsolutePosition
	local trackAbsSize = self.Track.AbsoluteSize
	
	-- Calculate ratio
	local relativeX = inputPos.X - trackAbsPos.X
	local ratio = math.clamp(relativeX / trackAbsSize.X, 0, 1)
	
	-- Set value
	local newValue = self:GetValueFromRatio(ratio)
	self:SetValue(newValue, true, false) -- don't call callback, will call it once at end
end

-- Set value programmatically
function ImGuiSlider:SetValue(value, animate, callCallback)
	if not value then value = self.Value end
	
	value = math.clamp(value, self.Min, self.Max)
	
	if self.Precision > 0 then
		local mult = 10 ^ self.Precision
		value = math.floor(value * mult + 0.5) / mult
	end
	
	if self.Value == value then return end
	
	self.Value = value
	
	-- Update visuals
	local ratio = self:GetValueRatio()
	
	if animate then
		TweenService:Create(self.TrackFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()
		
		TweenService:Create(self.Thumb, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			Position = UDim2.new(ratio, 0, 0.5, 0)
		}):Play()
	else
		self.TrackFill.Size = UDim2.new(ratio, 0, 1, 0)
		self.Thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
	end
	
	-- Update value label
	self.ValueLabel.Text = self:FormatValue(value)
	
	if callCallback ~= false and self.OnChanged then
		self.OnChanged(self, value)
	end
end

-- Get current value
function ImGuiSlider:GetValue()
	return self.Value
end

-- Set label text
function ImGuiSlider:SetLabel(text)
	self.Text = text
	self.Label.Text = text
end

-- Set range
function ImGuiSlider:SetRange(min, max)
	self.Min = min
	self.Max = max
	self:SetValue(self.Value, false)
end

return ImGuiSlider--[[
	ImGuiLibrary Dropdown Component
	Compact dropdown with smooth open/close animation
	Supports both selection from list and keyboard navigation
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ImGuiDropdown = {}
ImGuiDropdown.__index = ImGuiDropdown

function ImGuiDropdown.new(config)
	local self = setmetatable({}, ImGuiDropdown)
	
	self.Text = config.Text or "Dropdown"
	self.Options = config.Options or {"Option 1", "Option 2", "Option 3"}
	self.Value = config.Value or (self.Options[1] or "")
	self.Theme = config.Theme
	self.Animation = config.Animation
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	self.Size = config.Size or UDim2.new(1, 0, 0, 32)
	self.OnChanged = config.OnChanged
	self.MultiSelect = config.MultiSelect or false
	self.SelectedValues = config.SelectedValues or {self.Value}
	
	-- State
	self.IsOpen = false
	self.HoveredIndex = nil
	
	-- Visual properties
	local dropdownTheme = self.Theme:Get("Dropdown")
	local spacing = self.Theme:Get("Spacing")
	local typography = self.Theme:Get("Typography")
	
	-- Main container
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Dropdown"
	self.MainFrame.Size = self.Size
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.ClipsDescendants = false
	self.MainFrame.Parent = self.Parent
	
	-- Top row (label and selected value)
	self.TopRow = Instance.new("Frame")
	self.TopRow.Name = "TopRow"
	self.TopRow.Size = UDim2.new(1, 0, 0, 18)
	self.TopRow.BackgroundTransparency = 1
	self.TopRow.BorderSizePixel = 0
	self.TopRow.ZIndex = self.ZIndexBase + 1
	self.TopRow.Parent = self.MainFrame
	
	-- Label
	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Label"
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.BorderSizePixel = 0
	self.Label.Text = self.Text
	self.Label.TextColor3 = dropdownTheme.TextColor
	self.Label.Font = typography.LabelFont
	self.Label.TextSize = typography.LabelSize
	self.Label.TextXAlignment = Enum.TextXAlignment.Left
	self.Label.TextYAlignment = Enum.TextYAlignment.Center
	self.Label.ZIndex = self.ZIndexBase + 2
	self.Label.Parent = self.TopRow
	
	-- Button (closed dropdown)
	self.Button = Instance.new("Frame")
	self.Button.Name = "Button"
	self.Button.Size = UDim2.new(1, 0, 0, 28)
	self.Button.Position = UDim2.new(0, 0, 0, 22)
	self.Button.BackgroundColor3 = dropdownTheme.BackgroundColor
	self.Button.BorderSizePixel = 0
	self.Button.ZIndex = self.ZIndexBase + 3
	self.Button.Parent = self.MainFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, dropdownTheme.CornerRadius)
	btnCorner.Parent = self.Button
	
	local btnBorder = Instance.new("UIStroke")
	btnBorder.Color = dropdownTheme.BorderColor
	btnBorder.Thickness = spacing.BorderSize
	btnBorder.Transparency = 0.5
	btnBorder.Parent = self.Button
	
	-- Selected value text
	self.ValueLabel = Instance.new("TextLabel")
	self.ValueLabel.Name = "Value"
	self.ValueLabel.Size = UDim2.new(1, -36, 1, 0)
	self.ValueLabel.Position = UDim2.new(0, 8, 0, 0)
	self.ValueLabel.BackgroundTransparency = 1
	self.ValueLabel.BorderSizePixel = 0
	self.ValueLabel.Text = self.Value
	self.ValueLabel.TextColor3 = dropdownTheme.TextColor
	self.ValueLabel.Font = typography.LabelFont
	self.ValueLabel.TextSize = typography.LabelSize
	self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.ValueLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.ValueLabel.ZIndex = self.ZIndexBase + 4
	self.ValueLabel.Parent = self.Button
	
	-- Arrow indicator
	self.Arrow = Instance.new("Frame")
	self.Arrow.Name = "Arrow"
	self.Arrow.Size = UDim2.new(0, 8, 0, 8)
	self.Arrow.Position = UDim2.new(1, -14, 0.5, 0)
	self.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Arrow.BackgroundColor3 = dropdownTheme.IndicatorColor
	self.Arrow.BorderSizePixel = 0
	self.Arrow.ZIndex = self.ZIndexBase + 4
	self.Arrow.Parent = self.Button
	
	-- Popup (options list)
	self.Popup = Instance.new("Frame")
	self.Popup.Name = "Popup"
	self.Popup.Size = UDim2.new(1, 0, 0, 0)
	self.Popup.Position = UDim2.new(0, 0, 1, 2)
	self.Popup.BackgroundColor3 = dropdownTheme.BackgroundColor
	self.Popup.BorderSizePixel = 0
	self.Popup.ZIndex = self.ZIndexBase + 100
	self.Popup.Visible = false
	self.Popup.Parent = self.Button
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, dropdownTheme.CornerRadius)
	popupCorner.Parent = self.Popup
	
	local popupBorder = Instance.new("UIStroke")
	popupBorder.Color = dropdownTheme.BorderColor
	popupBorder.Thickness = spacing.BorderSize
	popupBorder.Transparency = 0.5
	popupBorder.Parent = self.Popup
	
	-- Shadow for popup
	self.PopupShadow = Instance.new("ImageLabel")
	self.PopupShadow.Name = "Shadow"
	self.PopupShadow.Size = UDim2.new(1, 8, 1, 8)
	self.PopupShadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	self.PopupShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	self.PopupShadow.BackgroundTransparency = 1
	self.PopupShadow.Image = "rbxassetid://105490971"
	self.PopupShadow.ImageColor3 = Color3.new(0, 0, 0)
	self.PopupShadow.ImageTransparency = 0.4
	self.PopupShadow.ZIndex = self.ZIndexBase + 99
	self.PopupShadow.Visible = false
	self.PopupShadow.Parent = self.Popup
	
	-- UIListLayout for options
	self.OptionsLayout = Instance.new("UIListLayout")
	self.OptionsLayout.FillDirection = Enum.FillDirection.Vertical
	self.OptionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.OptionsLayout.Padding = UDim.new(0, 1)
	self.OptionsLayout.SortOrder = Enum.SortOrder.Name
	self.OptionsLayout.ZIndex = self.ZIndexBase + 101
	self.OptionsLayout.Parent = self.Popup
	
	-- Build option frames
	self.OptionFrames = {}
	for i, option in ipairs(self.Options) do
		self:CreateOptionFrame(option, i)
	end
	
	-- Calculate popup height
	self.PopupHeight = #self.Options * 26 + 2
	self.Popup.ClipsDescendants = true
	
	-- State
	self.IsHovered = false
	
	-- Input handling
	self.Button.MouseEnter:Connect(function()
		self.IsHovered = true
		TweenService:Create(self.Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = dropdownTheme.HoverColor
		}):Play()
	end)
	
	self.Button.MouseLeave:Connect(function()
		self.IsHovered = false
		TweenService:Create(self.Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = dropdownTheme.BackgroundColor
		}):Play()
	end)
	
	self.Button.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self:Toggle()
		end
	end)
	
	-- Close when clicking outside
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or
		    input.UserInputType == Enum.UserInputType.Touch) and self.IsOpen then
			
			local inputPos = input.Position or UserInputService:GetMouseLocation()
			local btnPos = self.Button.AbsolutePosition
			local btnSize = self.Button.AbsoluteSize
			
			-- Check if click is within button
			local inButton = inputPos.X >= btnPos.X and inputPos.X <= btnPos.X + btnSize.X
				and inputPos.Y >= btnPos.Y and inputPos.Y <= btnPos.Y + btnSize.Y
			
			-- Check if click is within popup
			local popupPos = self.Popup.AbsolutePosition
			local popupSize = self.Popup.AbsoluteSize
			local inPopup = inputPos.X >= popupPos.X and inputPos.X <= popupPos.X + popupSize.X
				and inputPos.Y >= popupPos.Y and inputPos.Y <= popupPos.Y + popupSize.Y
			
			if not inButton and not inPopup then
				self:Close()
			end
		end
	end)
	
	-- Update dropdown text initially
	if self.MultiSelect then
		self.ValueLabel.Text = self:GetSelectedText()
	end
	
	return self
end

-- Create option frame
function ImGuiDropdown:CreateOptionFrame(option, index)
	local dropdownTheme = self.Theme:Get("Dropdown")
	local typography = self.Theme:Get("Typography")
	
	local optionFrame = Instance.new("Frame")
	optionFrame.Name = "Option" .. index
	optionFrame.Size = UDim2.new(1, -4, 0, 26)
	optionFrame.Position = UDim2.new(0, 2, 0, 0)
	optionFrame.BackgroundColor3 = dropdownTheme.BackgroundColor
	optionFrame.BorderSizePixel = 0
	optionFrame.ZIndex = self.ZIndexBase + 102
	optionFrame.Parent = self.Popup
	
	-- Text
	local optionText = Instance.new("TextLabel")
	optionText.Name = "Text"
	optionText.Size = UDim2.new(1, -16, 1, 0)
	optionText.Position = UDim2.new(0, 8, 0, 0)
	optionText.BackgroundTransparency = 1
	optionText.BorderSizePixel = 0
	optionText.Text = tostring(option)
	optionText.TextColor3 = dropdownTheme.TextColor
	optionText.Font = typography.LabelFont
	optionText.TextSize = typography.LabelSize
	optionText.TextXAlignment = Enum.TextXAlignment.Left
	optionText.TextYAlignment = Enum.TextYAlignment.Center
	optionText.ZIndex = self.ZIndexBase + 103
	optionText.Parent = optionFrame
	
	-- Check mark for selected
	local isSelected = false
	if self.MultiSelect then
		isSelected = table.find(self.SelectedValues, option) ~= nil
	else
		isSelected = self.Value == option
	end
	
	if isSelected then
		optionFrame.BackgroundColor3 = dropdownTheme.SelectedColor
		
		-- Check mark
		local check = Instance.new("Frame")
		check.Name = "Check"
		check.Size = UDim2.new(0, 6, 0, 2)
		check.Position = UDim2.new(1, -12, 0.5, 0)
		check.AnchorPoint = Vector2.new(0.5, 0.5)
		check.BackgroundColor3 = dropdownTheme.TextColor
		check.BorderSizePixel = 0
		check.ZIndex = self.ZIndexBase + 104
		check.Parent = optionFrame
	end
	
	-- Hover handling
	local indexRef = index
	optionFrame.MouseEnter:Connect(function()
		self.HoveredIndex = indexRef
		TweenService:Create(optionFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = dropdownTheme.HoverColor
		}):Play()
	end)
	
	optionFrame.MouseLeave:Connect(function()
		self.HoveredIndex = nil
		local originalColor = isSelected and dropdownTheme.SelectedColor or dropdownTheme.BackgroundColor
		TweenService:Create(optionFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
	
	-- Click handling
	optionFrame.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
		   input.UserInputType == Enum.UserInputType.Touch then
			self:SelectOption(option)
		end
	end)
	
	table.insert(self.OptionFrames, optionFrame)
end

-- Get text of selected values
function ImGuiDropdown:GetSelectedText()
	if #self.SelectedValues == 0 then
		return ""
	elseif #self.SelectedValues == 1 then
		return self.SelectedValues[1]
	elseif #self.SelectedValues <= 3 then
		return table.concat(self.SelectedValues, ", ")
	else
		return self.SelectedValues[1] .. " +" .. (#self.SelectedValues - 1)
	end
end

-- Toggle dropdown
function ImGuiDropdown:Toggle()
	if self.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

-- Open dropdown
function ImGuiDropdown:Open()
	if self.IsOpen then return end
	self.IsOpen = true
	
	self.Popup.Visible = true
	self.PopupShadow.Visible = true
	
	-- Animate popup
	TweenService:Create(self.Popup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, self.PopupHeight)
	}):Play()
	
	TweenService:Create(self.Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Rotation = 180
	}):Play()
end

-- Close dropdown
function ImGuiDropdown:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	
	TweenService:Create(self.Popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(1, 0, 0, 0)
	}):Play()
	
	TweenService:Create(self.Arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Rotation = 0
	}):Play()
	
	task.delay(0.12, function()
		self.Popup.Visible = false
		self.PopupShadow.Visible = false
	end)
end

-- Select an option
function ImGuiDropdown:SelectOption(option)
	if self.MultiSelect then
		local index = table.find(self.SelectedValues, option)
		if index then
			table.remove(self.SelectedValues, index)
		else
			table.insert(self.SelectedValues, option)
		end
		
		self.ValueLabel.Text = self:GetSelectedText()
		
		-- Rebuild options to update check marks
		self:RebuildOptions()
	else
		self.Value = option
		self.ValueLabel.Text = tostring(option)
		self:Close()
		
		-- Rebuild options to update check marks
		self:RebuildOptions()
	end
	
	if self.OnChanged then
		self.OnChanged(self, self.Value, self.SelectedValues)
	end
end

-- Rebuild option frames (for visual updates)
function ImGuiDropdown:RebuildOptions()
	for _, frame in ipairs(self.OptionFrames) do
		frame:Destroy()
	end
	self.OptionFrames = {}
	
	for i, option in ipairs(self.Options) do
		self:CreateOptionFrame(option, i)
	end
end

-- Set options
function ImGuiDropdown:SetOptions(options)
	self.Options = options
	self:RebuildOptions()
	self.PopupHeight = #self.Options * 26 + 2
end

-- Get selected value
function ImGuiDropdown:GetValue()
	return self.Value
end

-- Get selected values (for multi-select)
function ImGuiDropdown:GetSelectedValues()
	return self.SelectedValues
end

-- Set value programmatically
function ImGuiDropdown:SetValue(value)
	self.Value = value
	self.ValueLabel.Text = tostring(value)
	self:RebuildOptions()
end

return ImGuiDropdown--[[
	ImGuiLibrary Label Component
	Compact text label with optional primary/secondary styling
]]

local ImGuiLabel = {}
ImGuiLabel.__index = ImGuiLabel

function ImGuiLabel.new(config)
	local self = setmetatable({}, ImGuiLabel)
	
	self.Text = config.Text or ""
	self.Theme = config.Theme
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	
	-- Visual properties
	local labelTheme = self.Theme:Get("Label")
	local typography = self.Theme:Get("Typography")
	
	-- Main label frame
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Label"
	self.MainFrame.Size = UDim2.new(1, 0, 0, 20)
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.Parent = self.Parent
	
	-- Text label
	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Size = UDim2.new(1, 0, 1, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.BorderSizePixel = 0
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = labelTheme.PrimaryTextColor
	self.TextLabel.Font = typography.LabelFont
	self.TextLabel.TextSize = typography.LabelSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.TextLabel.ZIndex = config.ZIndexBase + 1
	self.TextLabel.Parent = self.MainFrame
	
	return self
end

-- Set primary style (default)
function ImGuiLabel:SetPrimary()
	self.TextLabel.TextColor3 = self.Theme:Get("Label").PrimaryTextColor
end

-- Set secondary style
function ImGuiLabel:SetSecondary()
	self.TextLabel.TextColor3 = self.Theme:Get("Label").SecondaryTextColor
end

-- Set text
function ImGuiLabel:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
end

-- Set font size
function ImGuiLabel:SetSize(size)
	self.TextLabel.TextSize = size
end

return ImGuiLabel--[[
	ImGuiLibrary Divider Component
	Simple horizontal or vertical divider line
]]

local ImGuiDivider = {}
ImGuiDivider.__index = ImGuiDivider

function ImGuiDivider.new(config)
	local self = setmetatable({}, ImGuiDivider)
	
	self.Theme = config.Theme
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent
	self.Orientation = config.Orientation or "horizontal"
	self.Thickness = config.Thickness or 1
	self.Size = config.Size or UDim2.new(1, 0, 0, 1)
	
	-- Visual properties
	local contentTheme = self.Theme:Get("Content")
	local spacing = self.Theme:Get("Spacing")
	
	-- If horizontal, Size should be full width, fixed thickness
	-- If vertical, Size should be fixed width, full height (relative to parent)
	local finalSize
	if self.Orientation == "horizontal" then
		finalSize = UDim2.new(1, 0, 0, self.Thickness)
	else
		finalSize = self.Size -- pass in custom size for vertical
	end
	
	-- Main divider frame
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "Divider"
	self.MainFrame.Size = finalSize
	self.MainFrame.BackgroundColor3 = contentTheme.DividerColor
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	self.MainFrame.Parent = self.Parent
	
	-- Optional: add subtle transparency
	self.MainFrame.BackgroundTransparency = 0.3
	
	return self
end

-- Set divider color
function ImGuiDivider:SetColor(color)
	self.MainFrame.BackgroundColor3 = color
end

-- Set orientation
function ImGuiDivider:SetOrientation(orientation)
	if self.Orientation == orientation then return end
	
	self.Orientation = orientation
	
	if orientation == "horizontal" then
		self.MainFrame.Size = UDim2.new(1, 0, 0, self.Thickness)
	else
		self.MainFrame.Size = UDim2.new(0, self.Thickness, 1, 0)
	end
end

return ImGuiDivider--[[
	ImGuiLibrary Section Component
	Expands/collapsible inspector-style section with smooth animation
]]

local ImGuiSection = {}
ImGuiSection.__index = ImGuiSection

function ImGuiSection.new(config)
	local self = setmetatable({}, ImGuiSection)
	
	self.Title = config.Title or "Section"
	self.Theme = config.Theme
	self.Animation = config.Animation
	self.ZIndexBase = config.ZIndexBase or 1
	self.Parent = config.Parent -- ScrollFrame
	
	-- State
	self.Expanded = config.Expanded ~= false
	self.OnExpandedChanged = config.OnExpandedChanged
	
	-- Visual properties
	local spacing = self.Theme:Get("Spacing")
	local sectionTheme = self.Theme:Get("Section")
	
	-- Main section frame
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "ImGuiSection"
	self.MainFrame.Size = UDim2.new(1, 0, 0, sectionTheme.ExpandDuration > 0 and 32 or 0)
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.ZIndex = config.ZIndexBase
	
	-- Section row container
	self.RowFrame = Instance.new("Frame")
	self.RowFrame.Name = "Row"
	self.RowFrame.Size = UDim2.new(1, 0, 0, 32)
	self.RowFrame.BackgroundTransparency = 1
	self.RowFrame.BorderSizePixel = 0
	self.RowFrame.ZIndex = config.ZIndexBase
	self.RowFrame.Parent = self.MainFrame
	
	-- Section indicator
	self.Indicator = Instance.new("Frame")
	self.Indicator.Name = "Indicator"
	self.Indicator.Size = UDim2.new(0, 8, 0, 8)
	self.Indicator.Position = UDim2.new(0, 8, 0.5, 0)
	self.Indicator.AnchorPoint = Vector2.new(0, 0.5)
	self.Indicator.BackgroundColor3 = sectionTheme.IndicatorColor
	self.Indicator.BorderSizePixel = 0
	self.Indicator.ZIndex = config.ZIndexBase + 1
	self.Indicator.Parent = self.RowFrame
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = self.Indicator
	
	-- Section text
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.Size = UDim2.new(1, -28, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 24, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.BorderSizePixel = 0
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = sectionTheme.TextColor
	self.TitleLabel.Font = self.Theme:Get("Typography").LabelFont
	self.TitleLabel.TextSize = self.Theme:Get("Typography").LabelSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
	self.TitleLabel.ZIndex = config.ZIndexBase + 1
	self.TitleLabel.Parent = self.RowFrame
	
	-- Expanded content container
	self.ContentFrame = Instance.new("Frame")
	self.ContentFrame.Name = "Content"
	self.ContentFrame.Size = UDim2.new(1, 0, 0, 0)
	self.ContentFrame.BackgroundTransparency = 1
	self.ContentFrame.BorderSizePixel = 0
	self.ContentFrame.ClipsDescendants = true
	self.ContentFrame.Visible = self.Expanded
	self.ContentFrame.ZIndex = config.ZIndexBase + 10
	self.ContentFrame.Parent = self.MainFrame
	
	-- UIListLayout for content children
	self.ContentLayout = Instance.new("UIListLayout")
	self.ContentLayout.FillDirection = Enum.FillDirection.Vertical
	self.ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.ContentLayout.Padding = UDim.new(0, 6)
	self.ContentLayout.SortOrder = Enum.SortOrder.Name
	self.ContentLayout.ZIndex = config.ZIndexBase + 11
	self.ContentLayout.Parent = self.ContentFrame
	
	-- Initial height setup
	self.RowFrame.Size = UDim2.new(1, 0, 0, 32)
	if self.Expanded then
		self.ContentFrame.Visible = true
	end
	
	-- Setup expand/collapse toggle
	self.RowFrame.MouseButton1Click:Connect(function()
		self:Toggle()
	end)
	
	-- If expanded initially, calculate height
	if self.Expanded then
		self:Expand()
	end
	
	return self
end

-- Toggle expand/collapse
function ImGuiSection:Toggle()
	self.Expanded = not self.Expanded
	
	if self.Expanded then
		self:Expand()
	else
		self:Collapse()
	end
	
	if self.OnExpandedChanged then
		self.OnExpandedChanged(self.Expanded)
	end
end

-- Expand section
function ImGuiSection:Expand()
	self.ContentFrame.Visible = true
	
	-- Calculate target height based on children
	local totalHeight = 0
	
	-- Add content layout spacing
	for _, child in ipairs(self.ContentLayout:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then continue end
		
		local childSize = child.AbsoluteSize
		local padding = child.AbsolutePosition.Y > 0 and 6 or 0 -- approximate padding
		totalHeight = totalHeight + childSize.Y + 6
	end
	
	-- Ensure minimum height
	if totalHeight == 0 then
		totalHeight = 32 -- placeholder minimum
	end
	
	-- Animate height expansion
	local tweenInfo = TweenInfo.new(
		self.Animation:Get("SectionExpandDuration") or 0.2,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	TweenService:Create(self.ContentFrame, tweenInfo, {
		Size = UDim2.new(1, 0, 0, totalHeight),
		BackgroundTransparency = 0,
	}):Play()
	
	-- Animate indicator
	local tweenInfo2 = TweenInfo.new(
		self.Animation:Get("SectionExpandDuration") or 0.2,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	-- Rotate indicator if it's an arrow
	if self.Indicator:IsA("Frame") then
		local arrow = Instance.new("Frame")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0.5, 0, 0.5, 0)
		arrow.BackgroundColor3 = Color3.new(1, 1, 1)
		arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Parent = self.Indicator
	end
	
	-- Could add rotation animation here
end

-- Collapse section
function ImGuiSection:Collapse()
	-- Animate height collapse
	local tweenInfo = TweenInfo.new(
		self.Animation:Get("SectionExpandDuration") or 0.2,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	
	TweenService:Create(self.ContentFrame, tweenInfo, {
		Size = UDim2.new(1, 0, 0, 0),
	}):Play()
	
	-- Hide after animation
	game:GetService("RunService").RenderStepped:Wait()
	self.ContentFrame.Visible = false
end

-- Add a control to the expanded content
function ImGuiSection:AddInstance(instance)
	instance.Parent = self.ContentFrame
	
	-- Update layout
	self.ContentLayout:Kill()
	self.ContentLayout:Destroy()
	
	self.ContentLayout = Instance.new("UIListLayout")
	self.ContentLayout.FillDirection = Enum.FillDirection.Vertical
	self.ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self.ContentLayout.Padding = UDim.new(0, 6)
	self.ContentLayout.SortOrder = Enum.SortOrder.Name
	self.ContentLayout.ZIndex = 11
	self.ContentLayout.Parent = self.ContentFrame
	
	-- Recalculate and animate
	task.spawn(function()
		local totalHeight = 0
		for _, child in ipairs(self.ContentLayout:GetChildren()) do
			if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then continue end
			totalHeight = totalHeight + child.AbsoluteSize.Y + 6
		end
		
		if totalHeight == 0 then totalHeight = 32 end
		
		self.ContentFrame.Size = UDim2.new(1, 0, 0, totalHeight)
	end)
end

-- Get expand state
function ImGuiSection:IsExpanded()
	return self.Expanded
end

-- Get the main frame
function ImGuiSection:GetMainFrame()
	return self.MainFrame
end

return ImGuiSection