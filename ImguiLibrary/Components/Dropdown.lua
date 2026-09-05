--[[
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

return ImGuiDropdown