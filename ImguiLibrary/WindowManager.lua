--[[
	ImGuiLibrary WindowManager Module
	Manages multiple independent floating windows, handles ZIndex stacking,
	focus management, and responsive positioning.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ImGuiWindowManager = {}
ImGuiWindowManager.__index = ImGuiWindowManager

function ImGuiWindowManager.new(theme, animation, parent)
	local self = setmetatable({}, ImGuiWindowManager)
	
	self.Theme = theme
	self.Animation = animation
	self.Parent = parent or game:GetService("CoreGui")
	self.Windows = {}
	self.BaseZIndex = 100
	self.HighestZIndex = self.BaseZIndex
	self.LastFocusedWindow = nil
	
	-- Input handler
	local ImGuiInput = require(script.Parent.Input)
	self.Input = ImGuiInput.new(self.Windows)
	
	-- Responsive settings
	self.Scale = 1.0
	self.ResponsiveEnabled = true
	
	-- Initialize responsive update
	self:InitResponsive()
	
	return self
end

-- Initialize responsive scaling based on screen size
function ImGuiWindowManager:InitResponsive()
	-- Detect screen size and calculate scale
	local function updateScale()
		local viewport = game.Workspace.CurrentCamera.ViewportSize
		local baseWidth = 320
		local minWidth = baseWidth * self.Theme:Get("Responsive").MinScale
		
		-- Calculate scale based on viewport width
		if viewport.X < baseWidth then
			self.Scale = math.max(viewport.X / baseWidth, self.Theme:Get("Responsive").MinScale)
		else
			self.Scale = math.min(viewport.X / baseWidth * 0.5, self.Theme:Get("Responsive").MaxScale)
		end
		
		self.Scale = math.clamp(self.Scale, self.Theme:Get("Responsive").MinScale, self.Theme:Get("Responsive").MaxScale)
	end
	
	updateScale()
	
	-- Listen for viewport changes
	game.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Register a window with the manager
function ImGuiWindowManager:RegisterWindow(window)
	window.Parent = self
	window.Index = #self.Windows + 1
	window.ZIndex = self.BaseZIndex + window.Index
	window.OnFocusChanged = function(win, focused)
		if focused then
			self:FocusWindow(win)
		end
	end
	
	-- Add to list
	self.Windows[#self.Windows + 1] = window
	
	-- Parent the window frame
	if window.MainFrame then
		window.MainFrame.Parent = self.Parent
	end
	
	-- Refresh input handler
	self.Input.GuiObjects = self.Windows
	
	-- Animate appearance if visible
	if window.Visible then
		self.Animation:WindowAppear(window.MainFrame)
	end
	
	return window
end

-- Unregister and destroy a window
function ImGuiWindowManager:UnregisterWindow(window)
	local index = table.find(self.Windows, window)
	if index then
		table.remove(self.Windows, index)
		
		-- Reindex remaining windows
		for i, w in ipairs(self.Windows) do
			w.Index = i
			w.ZIndex = self.BaseZIndex + i
		end
		
		-- Destroy the window
		window:Destroy()
		
		-- Refresh input handler
		self.Input.GuiObjects = self.Windows
	end
end

-- Focus a window (bring to front)
function ImGuiWindowManager:FocusWindow(window)
	-- Blur previously focused window
	if self.LastFocusedWindow and self.LastFocusedWindow ~= window then
		self.LastFocusedWindow.IsFocused = false
	end
	
	-- Increment global ZIndex
	self.HighestZIndex = self.HighestZIndex + 1
	
	-- Set window to top
	window.ZIndex = self.HighestZIndex
	window.IsFocused = true
	self.LastFocusedWindow = window
	
	-- Update all window Z-indices (only actual window frames, not children)
	for _, w in ipairs(self.Windows) do
		if w.MainFrame then
			w.MainFrame.ZIndex = w.ZIndex
			if w.Shadow then
				w.Shadow.ZIndex = w.ZIndex - 1
			end
		end
	end
end

-- Get window by name
function ImGuiWindowManager:GetWindow(name)
	for _, window in ipairs(self.Windows) do
		if window.Name == name then
			return window
		end
	end
	return nil
end

-- Get all windows
function ImGuiWindowManager:GetAllWindows()
	return self.Windows
end

-- Set all windows visibility
function ImGuiWindowManager:SetAllVisible(visible)
	for _, window in ipairs(self.Windows) do
		window:SetVisible(visible)
	end
end

-- Hide all windows (toggle)
function ImGuiWindowManager:ToggleAll()
	local anyVisible = false
	for _, window in ipairs(self.Windows) do
		if window.Visible then
			anyVisible = true
			break
		end
	end
	
	self:SetAllVisible(not anyVisible)
end

-- Arrange windows in a grid pattern
function ImGuiWindowManager:ArrangeWindows(config)
	config = config or {}
	local padding = config.Padding or 20
	local cols = config.Columns or 2
	local startX = config.StartX or 0.1
	local startY = config.StartY or 0.1
	local direction = config.Direction or "right"
	
	local viewport = game.Workspace.CurrentCamera.ViewportSize
	local windowCount = #self.Windows
	
	if windowCount == 0 then return end
	
	local col = 0
	local row = 0
	
	for i, window in ipairs(self.Windows) do
		-- Calculate position
		local x = startX + (col * (1 / cols))
		local y = startY + (row * 0.3)
		
		-- Alternate direction
		if direction == "alternate" then
			if col % 2 == 1 then
				y = y + 0.1
			end
		end
		
		window.MainFrame.Position = UDim2.new(x, padding, y, padding)
		
		-- Update row/col
		col = col + 1
		if col >= cols then
			col = 0
			row = row + 1
		end
	end
end

-- Stack windows vertically
function ImGuiWindowManager:StackVertically(config)
	config = config or {}
	local padding = config.Padding or 20
	local startX = config.StartX or 0.5
	local startY = config.StartY or 0.1
	local spacing = config.Spacing or 20
	
	local y = startY
	
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(startX, 0, 0, y)
		y = y + window.MainFrame.AbsoluteSize.Y + spacing
	end
end

-- Stack windows horizontally
function ImGuiWindowManager:StackHorizontally(config)
	config = config or {}
	local startX = config.StartX or 0.1
	local startY = config.StartY or 0.5
	local spacing = config.Spacing or 20
	
	local x = startX
	
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(0, x, startY, 0)
		x = x + window.MainFrame.AbsoluteSize.X + spacing
	end
end

-- Center all windows
function ImGuiWindowManager:CenterAll()
	for _, window in ipairs(self.Windows) do
		window.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
end

-- Destroy all windows
function ImGuiWindowManager:DestroyAll()
	for _, window in ipairs(self.Windows) do
		window:Destroy()
	end
	self.Windows = {}
end

-- Update (called every frame if needed)
function ImGuiWindowManager:Update()
	-- Handle window dragging for touch
	for _, window in ipairs(self.Windows) do
		if window.Dragging and window.InputHandler then
			window.InputHandler:Update()
		end
	end
end

-- Get current scale
function ImGuiWindowManager:GetScale()
	return self.Scale
end

-- Set global scale
function ImGuiWindowManager:SetScale(scale)
	self.Scale = math.clamp(scale, 
		self.Theme:Get("Responsive").MinScale, 
		self.Theme:Get("Responsive").MaxScale)
end

return ImGuiWindowManager