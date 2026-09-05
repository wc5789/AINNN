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

return ImGuiAnimation