--[[
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

return ImGuiLabel