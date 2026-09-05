--[[
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