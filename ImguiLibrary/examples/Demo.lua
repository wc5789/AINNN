--[[
	ImGuiLibrary Demo Script
	Usage: Run from Roblox Studio or via command bar
	Demonstrates all components and features
]]

-- Load the library (adjust path as needed for your setup)
local ImGuiLibrary = require(script.ImGuiLibrary)

-- Initialize library
local UILibrary = ImGuiLibrary.new()

-- Create main window with Fluent-style chaining
local mainWindow = UILibrary:Window({
	Title = "Configuration Panel",
	Icon = "", -- Optional: set to a Roblox asset ID
	Position = UDim2.new(0.1, 0, 0.2, 0),
	Size = UDim2.new(0, 320, 0, 450),
	Visible = true,
	Minimized = false,
	Draggable = true,
	ZIndex = 100,
})

-- Create a section in the window
local section1 = mainWindow:CreateSection("General Settings")

-- Add label to section
section1:AddInstance(require(UILibrary.Components.Label).new({
	Text = "Volume & Display Controls",
	Theme = UILibrary.Theme,
	ZIndexBase = 100,
	Parent = section1.ContentFrame,
}))

-- Add slider to section
section1:AddInstance(require(UILibrary.Components.Slider).new({
	Text = "Music Volume",
	Min = 0,
	Max = 100,
	Value = 75,
	Precision = 0,
	OnChanged = function(slider, value)
		print("Music Volume:", value)
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section1.ContentFrame,
}))

-- Add toggle to section
section1:AddInstance(require(UILibrary.Components.Toggle).new({
	Text = "Fullscreen",
	Value = false,
	OnChanged = function(toggle, value)
		print("Fullscreen:", value)
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section1.ContentFrame,
}))

-- Add second toggle
section1:AddInstance(require(UILibrary.Components.Toggle).new({
	Text = "VSync",
	Value = true,
	OnChanged = function(toggle, value)
		print("VSync:", value)
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section1.ContentFrame,
}))

-- Create second section
local section2 = mainWindow:CreateSection("Graphics Settings")

-- Add dropdown
section2:AddInstance(require(UILibrary.Components.Dropdown).new({
	Text = "Quality Level",
	Options = {"Low", "Medium", "High", "Ultra"},
	Value = "Medium",
	OnChanged = function(dropdown, value)
		print("Quality:", value)
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section2.ContentFrame,
}))

-- Add another dropdown
section2:AddInstance(require(UILibrary.Components.Dropdown).new({
	Text = "Resolution",
	Options = {"1920x1080", "1600x900", "1280x720", "800x600"},
	Value = "1920x1080",
	OnChanged = function(dropdown, value)
		print("Resolution:", value)
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section2.ContentFrame,
}))

-- Add button
section2:AddInstance(require(UILibrary.Components.Button).new({
	Text = "Apply Settings",
	OnClicked = function(button)
		print("Settings applied!")
	end,
	Theme = UILibrary.Theme,
	Animation = UILibrary.Animation,
	ZIndexBase = 100,
	Parent = section2.ContentFrame,
}))

-- Add divider
section2:AddInstance(require(UILibrary.Components.Divider).new({
	Orientation = "horizontal",
	Thickness = 1,
	Theme = UILibrary.Theme,
	ZIndexBase = 100,
	Parent = section2.ContentFrame,
}))

-- Create second window (demonstrates multi-window)
local settingsWindow = UILibrary:Window({
	Title = "Info Panel",
	Icon = "",
	Position = UDim2.new(0.7, 0, 0.2, 0),
	Size = UDim2.new(0, 300, 0, 350),
	Visible = true,
	Draggable = true,
	ZIndex = 100,
})

-- Info section
local infoSection = settingsWindow:CreateSection("About")

infoSection:AddInstance(require(UILibrary.Components.Label).new({
	Text = "ImGuiLibrary v1.0",
	Theme = UILibrary.Theme,
	ZIndexBase = 100,
	Parent = infoSection.ContentFrame,
}))

infoSection:AddInstance(require(UILibrary.Components.Label).new({
	Text = "A Roblox UI library inspired by ImGui",
	Theme = UILibrary.Theme,
	ZIndexBase = 100,
	Parent = infoSection.ContentFrame,
}))

-- API quick reference
-- UILibrary:Window({Title = "Window", Position = ..., Size = ...})
-- window:CreateSection("Section Title")
-- section:AddInstance(button/toggle/slider/dropdown/label/divider)

print("ImGuiLibrary Demo Loaded Successfully!")