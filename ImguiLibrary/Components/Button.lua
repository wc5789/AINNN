--[[
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

return ImGuiButton