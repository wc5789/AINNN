--[[
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

return ImGuiWindow