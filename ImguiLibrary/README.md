# ImGuiLibrary for Roblox
A sophisticated ImGui-inspired UI library for Roblox games and apps.

## Overview

ImGuiLibrary provides a clean, monochrome, desktop-style configuration interface that runs as an in-game overlay. Inspired by Dear ImGui, it offers a highly functional, information-dense UI system optimized for Roblox mobile devices.

## Features

- **Floating Windows**: Independent, draggable windows with smooth animations
- **ImGui-Style Design**: Dark charcoal surfaces, light gray selections, subtle shadows
- **Responsive Layout**: Adapts to different screen sizes and aspect ratios
- **Touch-First Input**: Full mouse and touch support
- **Compact Components**: High information density with minimal decoration

## Installation

1. Copy the `ImGuiLibrary` folder to `ReplicatedStorage` or `StarterPlayerScripts`
2. Require the module: `local UILibrary = require(ReplicatedStorage.ImGuiLibrary).new()`

## Quick Start

```lua
local UILibrary = require(ReplicatedStorage.ImGuiLibrary).new()

-- Create a window
local window = UILibrary:Window({
    Title = "Settings",
    Position = UDim2.new(0.5, -160, 0.5, -100),
    Size = UDim2.new(0, 320, 0, 400),
})

-- Create sections
local section = window:CreateSection("General")

-- Add components
section:AddInstance(UILibrary.Components.Slider.new({
    Text = "Volume",
    Min = 0,
    Max = 100,
    Value = 50,
    OnChanged = function(slider, value)
        print("Volume:", value)
    end,
}))

section:AddInstance(UILibrary.Components.Toggle.new({
    Text = "Sound",
    Value = true,
    OnChanged = function(toggle, value)
        print("Sound:", value)
    end,
}))
```

## API Reference

### `UILibrary.new()`

Creates a new ImGuiLibrary instance.

### `UILibrary:Window(config)`

Creates a new floating window.

**Config:**
- `Title` (string): Window title
- `Icon` (string): Icon asset ID (optional)
- `Position` (UDim2): Window position
- `Size` (UDim2): Window size
- `Visible` (boolean): Initial visibility
- `Minimized` (boolean): Initial minimized state
- `Draggable` (boolean): Enable window dragging
- `ZIndex` (number): Base ZIndex

### `window:CreateSection(title)`

Creates an expandable section within the window.

### Available Components

#### `ImGuiLibrary.Components.Slider`

```lua
Slider.new({
    Text = "Label",
    Min = 0,
    Max = 100,
    Value = 50,
    Precision = 0,  -- Decimal places
    OnChanged = function(slider, value) end
})
```

#### `ImGuiLibrary.Components.Toggle`

```lua
Toggle.new({
    Text = "Label",
    Value = false,
    OnChanged = function(toggle, value) end
})
```

#### `ImGuiLibrary.Components.Dropdown`

```lua
Dropdown.new({
    Text = "Label",
    Options = {"Option 1", "Option 2"},
    Value = "Option 1",
    MultiSelect = false,
    OnChanged = function(dropdown, value) end
})
```

#### `ImGuiLibrary.Components.Button`

```lua
Button.new({
    Text = "Click Me",
    OnClicked = function(button) end
})
```

#### `ImGuiLibrary.Components.Label`

```lua
Label.new({
    Text = "Label text",
    -- Use SetPrimary() or SetSecondary() for styling
})
```

#### `ImGuiLibrary.Components.Divider`

```lua
Divider.new({
    Orientation = "horizontal",
    Thickness = 1
})
```

## Theme System

All colors are centralized in the Theme module:

```lua
UILibrary.Theme:Get("Window")      -- Window colors
UILibrary.Theme:Get("Slider")      -- Slider colors
UILibrary.Theme:Get("Toggle")      -- Toggle colors
UILibrary.Theme:Get("Button")      -- Button colors
UILibrary.Theme:Get("Dropdown")    -- Dropdown colors
UILibrary.Theme:Get("Section")     -- Section colors
UILibrary.Theme:Get("Row")         -- Row colors
UILibrary.Theme:Get("Content")     -- Content area colors
```

## Window Management

```lua
-- Arrange windows
UILibrary.WindowManager:ArrangeWindows({Columns = 2})
UILibrary.WindowManager:StackVertically()
UILibrary.WindowManager:StackHorizontally()
UILibrary.WindowManager:CenterAll()

-- Hide/Show
UILibrary:ToggleAllWindows()
```

## File Structure

```
ImGuiLibrary/
├── init.lua           -- Main entry point
├── Theme.lua          -- Theme system
├── Animation.lua      -- Tween animations
├── Input.lua          -- Mouse/Touch input handling
├── WindowManager.lua  -- Window management
├── Window.lua         -- Window component
├── Components/
│   ├── Slider.lua
│   ├── Toggle.lua
│   ├── Dropdown.lua
│   ├── Button.lua
│   ├── Label.lua
│   └── Divider.lua
└── examples/
    └── Demo.lua       -- Example usage
```

## Design Principles

1. **Compact Floating Windows**: Designed for minimal screen footprint
2. **Dark Monochrome Surfaces**: Charcoal (#2D2D30) to near-black (#1E1E1E)
3. **High Contrast Selections**: Light gray on dark backgrounds
4. **ImGui Proportions**: Sharp corners, moderate rounding, subtle shadows
5. **Mobile-First**: Large touch targets, smooth dragging
6. **Responsive**: Scales across all Roblox devices

## Requirements

- Roblox Studio (for development)
- Roblox Player compatible (mobile, tablet, PC)
- TweenService enabled
- UserInputService enabled

## License

Free for use in Roblox games and projects.