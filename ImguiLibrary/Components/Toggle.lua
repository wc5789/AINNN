--[[
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

return ImGuiToggle