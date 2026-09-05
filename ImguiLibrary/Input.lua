--[[
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

return ImGuiInput