--[[
	ImGuiLibrary Core Init Module
	Sets up Theme, Animation, Input, WindowManager, and provides API
	Top-level: UILibrary namespace
]]

local ImGuiLibrary = {}
ImGuiLibrary.__index = ImGuiLibrary

-- Services reference
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function ImGuiLibrary.new()
	local self = setmetatable({}, ImGuiLibrary)
	
	-- Initialize theme (centralized)
	self.Theme = require(script.Parent.Parent.Theme)
	
	-- Initialize animation (wraps TweenService)
	self.Animation = require(script.Parent.Parent.Animation)
	
	-- Input handler (initialized when windows are created)
	self.InputHandler = nil
	
	-- WindowManager
	self.WindowManager = nil
	
	-- Active windows reference
	self.ActiveWindows = {}
	
	return self
end

-- Initialize or recreate WindowManager
function ImGuiLibrary:Initialize()
	if not self.WindowManager then
		self.Animation = require(script.Parent.Animation)
		self.InputHandler = require(script.Parent.Input)
		
		self.WindowManager = require(script.Parent.WindowManager)
		self.WindowManager = self.WindowManager.new(
			self.Theme,
			self.Animation,
			game:GetService("CoreGui")
		)
	end
	
	return self.WindowManager
end

-- Create a new window (main API entry)
function ImGuiLibrary:Window(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = require(script.Parent.Window).new(config.Title or "Window", config, self.Theme, self.Animation)
	
	-- Register with WindowManager
	local manager = self:Initialize()
	manager:RegisterWindow(window)
	
	-- Update input handler
	window.InputHandler = self.InputHandler
	
	-- Store reference
	self.ActiveWindows[window.Name] = window
	
	return window
end

-- Close a window by name
function ImGuiLibrary:CloseWindow(name)
	if self.ActiveWindows[name] then
		self.ActiveWindows[name]:SetVisible(false)
		self.ActiveWindows[name] = nil
	end
end

-- Close all windows
function ImGuiLibrary:CloseAllWindows()
	for name, window in pairs(self.ActiveWindows) do
		window:SetVisible(false)
	end
	self.ActiveWindows = {}
end

-- Get a window by name
function ImGuiLibrary:GetWindow(name)
	return self.ActiveWindows[name]
end

-- Toggle all windows visibility
function ImGuiLibrary:ToggleAllWindows()
	if #self.ActiveWindows == 0 then
		-- If no windows exist, create one and show
		self:Window({Title = "ImGui Library"}).MainFrame.Visible = true
		return
	end
	
	for name, window in pairs(self.ActiveWindows) do
		window:SetVisible(not window.Visible)
	end
end

-- Create a section within a window
function ImGuiLibrary:Section(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	-- Get the current active window or create default
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	return window:CreateSection(config.Title or "Section", config)
end

-- Create a button within a window
function ImGuiLibrary:Button(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	return window:CreateSection(config.Title or "Button"):AddInstance(
		require(script.Parent.Parent.Components.Button).new({
			Text = config.Text or "Button",
			OnClicked = config.OnClicked,
			Theme = self.Theme,
			Animation = self.Animation,
			ZIndexBase = config.ZIndexBase
		})
	)
end

-- Create a toggle within a window
function ImGuiLibrary:Toggle(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local toggle = require(script.Parent.Parent.Components.Toggle).new({
		Text = config.Text or "Toggle",
		Value = config.Value or false,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Toggle"):AddInstance(toggle)
end

-- Create a slider within a window
function ImGuiLibrary:Slider(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local slider = require(script.Parent.Parent.Components.Slider).new({
		Text = config.Text or "Slider",
		Min = config.Min or 0,
		Max = config.Max or 100,
		Value = config.Value or 50,
		Precision = config.Precision,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Slider"):AddInstance(slider)
end

-- Create a dropdown within a window
function ImGuiLibrary:Dropdown(config)
	config = config or {}
	config.Theme = self.Theme
	config.Animation = self.Animation
	
	local window = self.ActiveWindows[1]
	if not window then
		window = self:Window({Title = "ImGui Library"})
	end
	
	local dropdown = require(script.Parent.Parent.Components.Dropdown).new({
		Text = config.Text or "Dropdown",
		Options = config.Options or {"Option 1", "Option 2", "Option 3"},
		Value = config.Value,
		MultiSelect = config.MultiSelect or false,
		OnChanged = config.OnChanged,
		Theme = self.Theme,
		Animation = self.Animation,
		ZIndexBase = config.ZIndexBase
	})
	
	return window:CreateSection(config.Title or "Dropdown"):AddInstance(dropdown)
end

-- Get all active windows
function ImGuiLibrary:GetAllWindows()
	return self.ActiveWindows
end

-- Theme shortcuts
function ImGuiLibrary:Theme()
	return self.Theme
end

function ImGuiLibrary:Animation()
	return self.Animation
end

return ImGuiLibrary