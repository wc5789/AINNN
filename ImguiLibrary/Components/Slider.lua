--[[
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

return ImGuiSlider