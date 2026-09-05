--[[
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

return ImGuiDivider