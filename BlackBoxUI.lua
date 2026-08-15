--[[
    ================================================================================
    BLACKBOX HUB - PREMIUM ROBLOX UI LIBRARY (V2.5)
    Style: Satirical Adult Video Aesthetic / Dark Modern SaaS UI
    Palette: 80% Black (#080808) | 15% Dark Gray (#151515) | 5% Accent Gold (#FFA31A)
    ================================================================================
--]]

local Library = {
    Version = "2.5.0",
    ActiveWindow = nil,
    Flags = {},
    Unloaded = false,
    Themes = {
        BlackGold = {
            Background = Color3.fromRGB(8, 8, 8),
            SecondaryBackground = Color3.fromRGB(13, 13, 13),
            ElementBackground = Color3.fromRGB(21, 21, 21),
            ElementHover = Color3.fromRGB(30, 30, 30),
            Border = Color3.fromRGB(41, 41, 41),
            BorderBright = Color3.fromRGB(65, 65, 65),
            TextPrimary = Color3.fromRGB(245, 245, 245),
            TextSecondary = Color3.fromRGB(167, 167, 167),
            TextMuted = Color3.fromRGB(102, 102, 102),
            Accent = Color3.fromRGB(255, 163, 26),        -- #FFA31A Brand Gold
            AccentHover = Color3.fromRGB(255, 181, 42),   -- #FFB52A
            AccentBright = Color3.fromRGB(255, 209, 92),  -- #FFD15C
            AccentDark = Color3.fromRGB(180, 110, 10),
            Danger = Color3.fromRGB(231, 76, 60),
            Success = Color3.fromRGB(46, 204, 113),
            Warning = Color3.fromRGB(241, 196, 15),
            Info = Color3.fromRGB(52, 152, 219)
        }
    },
    CurrentTheme = nil,
    UIScale = 1.0,
    Connections = {},
    SearchRegistry = {}
}

Library.CurrentTheme = Library.Themes.BlackGold

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Safe GUI Container Detection
local function GetSafeParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        elseif CoreGui and pcall(function() return CoreGui.Name end) then
            return CoreGui
        elseif LocalPlayer then
            return LocalPlayer:WaitForChild("PlayerGui", 5)
        end
    end)
    if success and result then return result end
    return game:GetService("CoreGui")
end

-- Helper Utilities
local function RegisterConnection(conn)
    table.insert(Library.Connections, conn)
    return conn
end

function Library:Tween(object, time, properties, style, direction)
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(time, style, direction)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function MakeCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function MakeStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Library.CurrentTheme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function MakePadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft = UDim.new(0, left or 10),
        PaddingRight = UDim.new(0, right or 10),
        Parent = parent
    })
end

-- Dragging Implementation (Mouse + Touch Responsive)
local function EnableDragging(dragHandle, targetFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    RegisterConnection(dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            local conn;
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end))

    RegisterConnection(dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    RegisterConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Library:Tween(targetFrame, 0.08, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            })
        end
    end))
end

-- Screen Overlay GUI Setup
local ScreenGui = Create("ScreenGui", {
    Name = "BlackBox_UI_Hub",
    ResetOnSpawn = false,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = GetSafeParent()
})

-- Notification Container
local NotificationContainer = Create("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 320, 1, -40),
    Position = UDim2.new(1, -330, 0, 20),
    BackgroundTransparency = 1,
    ZIndex = 1000,
    Parent = ScreenGui
}, {
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10)
    })
})

-- Tooltip Overlay
local TooltipFrame = Create("Frame", {
    Name = "Tooltip",
    Size = UDim2.new(0, 120, 0, 28),
    BackgroundColor3 = Library.CurrentTheme.Background,
    Visible = false,
    ZIndex = 2000,
    Parent = ScreenGui
}, {
    MakeCorner(nil, 4),
    MakeStroke(nil, Library.CurrentTheme.Accent, 1),
    Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Library.CurrentTheme.TextPrimary,
        TextSize = 12,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
})

local function ShowTooltip(text, position)
    if not text or text == "" then return end
    TooltipFrame.Label.Text = text
    local bounds = TextService:GetTextSize(text, 12, Enum.Font.SourceSansBold, Vector2.new(300, 30))
    TooltipFrame.Size = UDim2.new(0, bounds.X + 16, 0, 26)
    TooltipFrame.Position = UDim2.new(0, position.X + 12, 0, position.Y + 12)
    TooltipFrame.Visible = true
end

local function HideTooltip()
    TooltipFrame.Visible = false
end

-- ==========================================
-- LIBRARY MAIN METHODS
-- ==========================================

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "NOTIFICATION"
    local desc = options.Description or ""
    local duration = options.Duration or 4
    local notifType = options.Type or "Info" -- Info, Success, Warning, Error

    local typeColors = {
        Info = Library.CurrentTheme.Info,
        Success = Library.CurrentTheme.Success,
        Warning = Library.CurrentTheme.Warning,
        Error = Library.CurrentTheme.Danger
    }
    local accentColor = typeColors[notifType] or Library.CurrentTheme.Accent

    local Card = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        Parent = NotificationContainer
    }, {
        MakeCorner(nil, 6),
        MakeStroke(nil, Library.CurrentTheme.Border, 1),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0
        }),
        Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 22),
            Position = UDim2.new(0, 14, 0, 8),
            BackgroundTransparency = 1,
            Text = title:upper(),
            TextColor3 = Library.CurrentTheme.TextPrimary,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = Library.CurrentTheme.TextSecondary,
            TextSize = 12,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        }),
        Create("Frame", {
            Name = "ProgressBar",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0
        })
    })

    -- Slide in
    Card.Position = UDim2.new(1, 100, 0, 0)
    Library:Tween(Card, 0.25, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)

    -- Progress bar shrink
    Library:Tween(Card.ProgressBar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if Card and Card.Parent then
            local tw = Library:Tween(Card, 0.2, { Position = UDim2.new(1, 100, 0, 0) })
            tw.Completed:Connect(function()
                Card:Destroy()
            end)
        end
    end)
end

function Library:Dialog(options)
    options = options or {}
    local title = options.Title or "CONFIRM ACTION"
    local content = options.Content or "Are you sure you want to proceed?"
    local buttons = options.Buttons or {
        { Name = "Cancel", Style = "Secondary", Callback = function() end },
        { Name = "Confirm", Style = "Accent", Callback = function() end }
    }

    local Overlay = Create("TextButton", {
        Name = "DialogOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 3000,
        Parent = ScreenGui
    })

    local Modal = Create("Frame", {
        Name = "DialogModal",
        Size = UDim2.new(0, 420, 0, 180),
        Position = UDim2.new(0.5, -210, 0.5, -90),
        BackgroundColor3 = Library.CurrentTheme.Background,
        Parent = Overlay
    }, {
        MakeCorner(nil, 8),
        MakeStroke(nil, Library.CurrentTheme.Accent, 1),
        MakePadding(nil, 16, 16, 18, 18),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = title:upper(),
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 16,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = content,
            TextColor3 = Library.CurrentTheme.TextSecondary,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        })
    })

    local BtnContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 1, -36),
        BackgroundTransparency = 1,
        Parent = Modal
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10)
        })
    })

    for _, btnData in ipairs(buttons) do
        local isAccent = btnData.Style == "Accent"
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = isAccent and Library.CurrentTheme.Accent or Library.CurrentTheme.ElementBackground,
            Text = btnData.Name:upper(),
            TextColor3 = isAccent and Library.CurrentTheme.Background or Library.CurrentTheme.TextPrimary,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            Parent = BtnContainer
        }, {
            MakeCorner(nil, 4),
            MakeStroke(nil, isAccent and Library.CurrentTheme.Accent or Library.CurrentTheme.Border, 1)
        })

        btn.MouseButton1Click:Connect(function()
            Overlay:Destroy()
            if btnData.Callback then btnData.Callback() end
        end)
    end
end

function Library:Loading(options)
    options = options or {}
    local title = options.Title or "LOADING ASSETS..."
    local time = options.Time or 2.5
    local callback = options.Callback

    local Overlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Library.CurrentTheme.Background,
        BackgroundTransparency = 0.1,
        ZIndex = 4000,
        Parent = ScreenGui
    })

    local SpinnerBox = Create("Frame", {
        Size = UDim2.new(0, 300, 0, 120),
        Position = UDim2.new(0.5, -150, 0.5, -60),
        BackgroundTransparency = 1,
        Parent = Overlay
    }, {
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "BLACKBOX HUB",
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 20,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
        }),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Library.CurrentTheme.TextSecondary,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        }),
        Create("Frame", {
            Name = "Track",
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 65),
            BackgroundColor3 = Library.CurrentTheme.ElementBackground,
            Parent = Overlay
        }, {
            MakeCorner(nil, 3),
            Create("Frame", {
                Name = "Bar",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Library.CurrentTheme.Accent,
                BorderSizePixel = 0
            }, { MakeCorner(nil, 3) })
        })
    })

    local bar = SpinnerBox.Track.Bar
    Library:Tween(bar, time, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

    task.delay(time + 0.2, function()
        Library:Tween(Overlay, 0.3, { BackgroundTransparency = 1 }).Completed:Connect(function()
            Overlay:Destroy()
            if callback then callback() end
        end)
    end)
end

function Library:SetWatermark(options)
    options = options or {}
    local text = options.Text or "BLACKBOX HUB | PREMIUM VIP CONTROL | v2.5"
    
    if Library.WatermarkFrame then
        Library.WatermarkFrame:Destroy()
    end

    if options.Visible == false then return end

    Library.WatermarkFrame = Create("Frame", {
        Name = "Watermark",
        Size = UDim2.new(0, 280, 0, 28),
        Position = UDim2.new(0, 15, 0, 12),
        BackgroundColor3 = Library.CurrentTheme.Background,
        ZIndex = 800,
        Parent = ScreenGui
    }, {
        MakeCorner(nil, 4),
        MakeStroke(nil, Library.CurrentTheme.Accent, 1),
        Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Library.CurrentTheme.TextPrimary,
            TextSize = 12,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
end

function Library:SetScale(scale)
    Library.UIScale = math.clamp(scale or 1.0, 0.75, 1.25)
    if Library.ActiveWindow and Library.ActiveWindow.ScaleObject then
        Library.ActiveWindow.ScaleObject.Scale = Library.UIScale
    end
end

function Library:ToggleUI()
    if Library.ActiveWindow then
        Library.ActiveWindow.MainFrame.Visible = not Library.ActiveWindow.MainFrame.Visible
    end
end

function Library:Destroy()
    Library.Unloaded = true
    for _, conn in ipairs(Library.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    for i = #Library.Connections, 1, -1 do
        Library.Connections[i] = nil
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

-- Config Management
function Library:SaveConfig(name)
    name = name or "default"
    local data = {}
    for flag, value in pairs(Library.Flags) do
        if typeof(value) == "Color3" then
            data[flag] = { R = value.R, G = value.G, B = value.B, Type = "Color3" }
        elseif typeof(value) == "EnumItem" then
            data[flag] = { Name = value.Name, Type = "Enum" }
        else
            data[flag] = value
        end
    end

    local success, err = pcall(function()
        if not isfolder("BlackBoxHub") then
            makefolder("BlackBoxHub")
        end
        writefile("BlackBoxHub/" .. name .. ".json", HttpService:JSONEncode(data))
    end)

    if success then
        Library:Notify({ Title = "CONFIG SAVED", Description = "Config '" .. name .. "' saved successfully.", Type = "Success" })
    else
        Library:Notify({ Title = "CONFIG ERROR", Description = "Failed to save config: " .. tostring(err), Type = "Error" })
    end
end

function Library:LoadConfig(name)
    name = name or "default"
    local success, result = pcall(function()
        if isfile("BlackBoxHub/" .. name .. ".json") then
            return HttpService:JSONDecode(readfile("BlackBoxHub/" .. name .. ".json"))
        end
    end)

    if success and result then
        for flag, val in pairs(result) do
            if type(val) == "table" and val.Type == "Color3" then
                val = Color3.new(val.R, val.G, val.B)
            end
            if Library.Flags[flag] ~= nil then
                Library.Flags[flag] = val
            end
        end
        Library:Notify({ Title = "CONFIG LOADED", Description = "Config '" .. name .. "' loaded successfully.", Type = "Success" })
    else
        Library:Notify({ Title = "CONFIG ERROR", Description = "Config file not found.", Type = "Warning" })
    end
end

-- ==========================================
-- WINDOW CREATION
-- ==========================================

function Library:CreateWindow(options)
    options = options or {}
    local windowTitle = options.Name or "BLACKBOX"
    local subtitle = options.Subtitle or "ADMIN CONTROL PANEL"
    local defaultKeybind = options.Keybind or Enum.KeyCode.RightControl

    -- Screen responsiveness calculation
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local isTouch = UserInputService.TouchEnabled

    local defaultWidth = isTouch and math.min(650, viewportSize.X * 0.92) or 650
    local defaultHeight = isTouch and math.min(420, viewportSize.Y * 0.82) or 420

    local MainFrame = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.fromOffset(defaultWidth, defaultHeight),
        Position = UDim2.new(0.5, -defaultWidth / 2, 0.5, -defaultHeight / 2),
        BackgroundColor3 = Library.CurrentTheme.Background,
        ClipsDescendants = false,
        Parent = ScreenGui
    }, {
        MakeCorner(nil, 8),
        MakeStroke(nil, Library.CurrentTheme.Border, 1)
    })

    local ScaleObject = Create("UIScale", { Scale = Library.UIScale, Parent = MainFrame })

    -- Window Header (Height: 48px)
    local Header = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
        Parent = MainFrame
    }, {
        MakeCorner(nil, 8),
        Create("Frame", { -- Accent Line at bottom of header
            Name = "AccentLine",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = Library.CurrentTheme.Accent,
            BorderSizePixel = 0
        })
    })

    EnableDragging(Header, MainFrame)

    -- Brand Logo Area (Black Box Video Site Aesthetic)
    local BrandContainer = Create("Frame", {
        Name = "BrandContainer",
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Parent = Header
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4)
        })
    })

    -- Logo Box 1: Black Text
    Create("TextLabel", {
        Size = UDim2.new(0, 70, 0, 24),
        BackgroundTransparency = 1,
        Text = windowTitle:upper(),
        TextColor3 = Library.CurrentTheme.TextPrimary,
        TextSize = 16,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = BrandContainer
    })

    -- Logo Box 2: Gold Accent Pill
    Create("Frame", {
        Size = UDim2.new(0, 38, 0, 22),
        BackgroundColor3 = Library.CurrentTheme.Accent,
        Parent = BrandContainer
    }, {
        MakeCorner(nil, 4),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "HUB",
            TextColor3 = Library.CurrentTheme.Background,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
        })
    })

    -- Satirical Badge ("1080P HD / VERIFIED")
    Create("Frame", {
        Size = UDim2.new(0, 50, 0, 16),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Parent = BrandContainer
    }, {
        MakeCorner(nil, 3),
        MakeStroke(nil, Library.CurrentTheme.Accent, 1),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "PRO HD",
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 9,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        })
    })

    -- Global Search Box
    local SearchBox = Create("Frame", {
        Name = "SearchBox",
        Size = UDim2.new(0, 180, 0, 28),
        Position = UDim2.new(0.5, -90, 0.5, -14),
        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
        Parent = Header
    }, {
        MakeCorner(nil, 4),
        MakeStroke(nil, Library.CurrentTheme.Border, 1),
        Create("TextBox", {
            Name = "Input",
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            PlaceholderText = "Search features...",
            PlaceholderColor3 = Library.CurrentTheme.TextMuted,
            Text = "",
            TextColor3 = Library.CurrentTheme.TextPrimary,
            TextSize = 12,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false
        })
    })

    -- Header Right Controls (FPS / Ping / Settings / Min / Close)
    local RightControls = Create("Frame", {
        Size = UDim2.new(0, 180, 1, 0),
        Position = UDim2.new(1, -185, 0, 0),
        BackgroundTransparency = 1,
        Parent = Header
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8)
        })
    })

    local StatLabel = Create("TextLabel", {
        Size = UDim2.new(0, 90, 0, 24),
        BackgroundTransparency = 1,
        Text = "FPS: -- | 0ms",
        TextColor3 = Library.CurrentTheme.TextMuted,
        TextSize = 11,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        Parent = RightControls
    })

   -- ===== FPS + Ping 计数器 (稳定通用版) =====
local frameCount = 0
local lastCheck = os.clock()
local statsService = game:GetService("Stats")

-- 安全获取 Ping（毫秒）
local function GetPing()
    local success, ping = pcall(function()
        return statsService:GetRealPhysicalPing()
    end)
    return success and ping or 0
end

-- 使用 RenderStepped 计数，每 0.4 秒更新一次 UI
RegisterConnection(RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastCheck >= 0.4 then
        local fps = math.floor(frameCount / (now - lastCheck))
        local ping = math.floor(GetPing())
        -- 确保 StatLabel 存在再更新
        if StatLabel and StatLabel.Parent then
            StatLabel.Text = string.format("FPS: %d | %dms", fps, ping)
        end
        frameCount = 0
        lastCheck = now
    end
end))

    -- Minimize Button
    local MinBtn = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
        Text = "-",
        TextColor3 = Library.CurrentTheme.TextSecondary,
        TextSize = 16,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        Parent = RightControls
    }, { MakeCorner(nil, 4) })

    -- Close Button
    local CloseBtn = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
        Text = "X",
        TextColor3 = Library.CurrentTheme.Danger,
        TextSize = 13,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        Parent = RightControls
    }, { MakeCorner(nil, 4) })

    -- Body Container
    local Body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -72),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    -- Left Navigation Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
        Parent = Body
    }, {
        MakeCorner(nil, 0),
        Create("Frame", { -- Right border line
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = Library.CurrentTheme.Border,
            BorderSizePixel = 0
        })
    })

    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, -30),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.CurrentTheme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar
    }, {
        MakePadding(nil, 8, 8, 8, 8),
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })
    })

    -- Sidebar Footer
    local SidebarFooter = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 1, -28),
        BackgroundColor3 = Library.CurrentTheme.Background,
        Parent = Sidebar
    }, {
        Create("TextLabel", {
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = "● VERIFIED VIP",
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 10,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })

    -- Content Display Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Body
    })

    -- Bottom Status Bar (Height: 24px)
    local StatusBar = Create("Frame", {
        Name = "StatusBar",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
        Parent = MainFrame
    }, {
        MakeCorner(nil, 8),
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Library.CurrentTheme.Border,
            BorderSizePixel = 0
        }),
        Create("TextLabel", {
            Name = "StatusText",
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = "● STREAM READY | Current Tab: None",
            TextColor3 = Library.CurrentTheme.TextSecondary,
            TextSize = 11,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(1, -212, 0, 0),
            BackgroundTransparency = 1,
            Text = "BLACKBOX UI ENGINE v2.5",
            TextColor3 = Library.CurrentTheme.TextMuted,
            TextSize = 10,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Right
        })
    })

    -- Toggle Hotkey Logic
    RegisterConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == defaultKeybind then
            MainFrame.Visible = not MainFrame.Visible
        end
    end))

    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        Library:Notify({ Title = "MINIMIZED", Description = "Press " .. defaultKeybind.Name .. " to reopen UI.", Type = "Info" })
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Library:Dialog({
            Title = "CLOSE BLACKBOX HUB",
            Content = "Are you sure you want to close the control panel?",
            Buttons = {
                { Name = "Cancel", Style = "Secondary" },
                { Name = "Close", Style = "Accent", Callback = function() Library:Destroy() end }
            }
        })
    end)

    local WindowObject = {
        MainFrame = MainFrame,
        ScaleObject = ScaleObject,
        Tabs = {},
        ActiveTab = nil,
        StatusLabel = StatusBar.StatusText
    }

    Library.ActiveWindow = WindowObject

    -- Global Search Functionality
    SearchBox.Input.Changed:Connect(function()
        local query = SearchBox.Input.Text:lower()
        if query == "" then
            if WindowObject.ActiveTab then
                WindowObject.ActiveTab:Select()
            end
            return
        end

        for _, item in ipairs(Library.SearchRegistry) do
            local match = item.Name:lower():find(query) ~= nil or item.Description:lower():find(query) ~= nil
            item.Frame.Visible = match
            if match then
                item.Tab:Select()
            end
        end
    end)

    -- ==========================================
    -- TAB CREATION
    -- ==========================================

    function WindowObject:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or "Tab"
        local tabIcon = tabOptions.Icon or "✦"

        local TabButton = Create("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
            BackgroundTransparency = 1,
            Text = "",
            Parent = TabContainer
        }, {
            MakeCorner(nil, 6),
            Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 3, 1, -12),
                Position = UDim2.new(0, 2, 0, 6),
                BackgroundColor3 = Library.CurrentTheme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            }, { MakeCorner(nil, 2) }),
            Create("TextLabel", {
                Name = "IconLabel",
                Size = UDim2.new(0, 24, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = tabIcon,
                TextColor3 = Library.CurrentTheme.TextSecondary,
                TextSize = 14,
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            }),
            Create("TextLabel", {
                Name = "TitleLabel",
                Size = UDim2.new(1, -42, 1, 0),
                Position = UDim2.new(0, 36, 0, 0),
                BackgroundTransparency = 1,
                Text = tabName,
                TextColor3 = Library.CurrentTheme.TextSecondary,
                TextSize = 13,
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                TextXAlignment = Enum.TextXAlignment.Left
            })
        })

        -- Tab Content Page ScrollingFrame
        local PageFrame = Create("ScrollingFrame", {
            Name = "Page_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.CurrentTheme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = ContentArea
        }, {
            MakePadding(nil, 12, 12, 14, 14),
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10)
            })
        })

        local TabObj = {
            Name = tabName,
            Button = TabButton,
            Page = PageFrame,
            Sections = {}
        }

        function TabObj:Select()
            for _, t in ipairs(WindowObject.Tabs) do
                t.Button.BackgroundTransparency = 1
                t.Button.Indicator.BackgroundTransparency = 1
                t.Button.TitleLabel.TextColor3 = Library.CurrentTheme.TextSecondary
                t.Button.IconLabel.TextColor3 = Library.CurrentTheme.TextSecondary
                t.Page.Visible = false
            end

            TabButton.BackgroundColor3 = Library.CurrentTheme.ElementBackground
            TabButton.BackgroundTransparency = 0
            TabButton.Indicator.BackgroundTransparency = 0
            TabButton.TitleLabel.TextColor3 = Library.CurrentTheme.Accent
            TabButton.IconLabel.TextColor3 = Library.CurrentTheme.Accent
            
            -- Fade in & slide animation
            PageFrame.Position = UDim2.new(0, 0, 0, 10)
            PageFrame.Visible = true
            Library:Tween(PageFrame, 0.18, { Position = UDim2.new(0, 0, 0, 0) })

            WindowObject.ActiveTab = TabObj
            WindowObject.StatusLabel.Text = "● READY | Current Tab: " .. tabName
        end

        TabButton.MouseButton1Click:Connect(function()
            TabObj:Select()
        end)

        -- Auto select first tab
        if #WindowObject.Tabs == 0 then
            TabObj:Select()
        end

        table.insert(WindowObject.Tabs, TabObj)

        -- ==========================================
        -- SECTION CREATION
        -- ==========================================

        function TabObj:CreateSection(secOptions)
            secOptions = secOptions or {}
            local secName = secOptions.Name or "Section"

            local SectionCard = Create("Frame", {
                Name = "Section_" .. secName,
                Size = UDim2.new(1, 0, 0, 36),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.CurrentTheme.ElementBackground,
                Parent = PageFrame
            }, {
                MakeCorner(nil, 6),
                MakeStroke(nil, Library.CurrentTheme.Border, 1),
                MakePadding(nil, 10, 10, 12, 12),
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8)
                }),
                Create("Frame", {
                    Name = "Header",
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1
                }, {
                    Create("Frame", {
                        Size = UDim2.new(0, 3, 0, 14),
                        Position = UDim2.new(0, 0, 0, 3),
                        BackgroundColor3 = Library.CurrentTheme.Accent,
                        BorderSizePixel = 0
                    }, { MakeCorner(nil, 2) }),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = secName:upper(),
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 12,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })
            })

            local SectionObj = { Frame = SectionCard }

            -- ==========================================
            -- CONTROLS
            -- ==========================================

            -- 1. BUTTON
            function SectionObj:CreateButton(btnOpt)
                btnOpt = btnOpt or {}
                local name = btnOpt.Name or "Button"
                local desc = btnOpt.Description or ""
                local callback = btnOpt.Callback or function() end
                local isAccent = btnOpt.Accent or false

                local BtnFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = isAccent and Library.CurrentTheme.Accent or Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, isAccent and Library.CurrentTheme.Accent or Library.CurrentTheme.Border, 1),
                    Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = BtnFrame
                    }),
                    Create("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(1, -20, 0, desc ~= "" and 18 or 38),
                        Position = UDim2.new(0, 10, 0, desc ~= "" and 3 or 0),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = isAccent and Library.CurrentTheme.Background or Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })

                if desc ~= "" then
                    Create("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 14),
                        Position = UDim2.new(0, 10, 0, 20),
                        BackgroundTransparency = 1,
                        Text = desc,
                        TextColor3 = isAccent and Color3.fromRGB(40, 30, 0) or Library.CurrentTheme.TextMuted,
                        TextSize = 11,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = BtnFrame
                    })
                end

                local btn = BtnFrame.TextButton
                btn.MouseButton1Down:Connect(function()
                    Library:Tween(BtnFrame, 0.08, { Size = UDim2.new(0.98, 0, 0, 36) })
                end)
                btn.MouseButton1Up:Connect(function()
                    Library:Tween(BtnFrame, 0.08, { Size = UDim2.new(1, 0, 0, 38) })
                end)
                btn.MouseButton1Click:Connect(function()
                    callback()
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = desc, Frame = BtnFrame, Tab = TabObj })
                return BtnFrame
            end

            -- 2. TOGGLE
            function SectionObj:CreateToggle(tglOpt)
                tglOpt = tglOpt or {}
                local name = tglOpt.Name or "Toggle"
                local desc = tglOpt.Description or ""
                local default = tglOpt.CurrentValue or false
                local flag = tglOpt.Flag or name
                local callback = tglOpt.Callback or function() end

                Library.Flags[flag] = default

                local TglFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -60, 0, desc ~= "" and 18 or 38),
                        Position = UDim2.new(0, 10, 0, desc ~= "" and 3 or 0),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "Switch",
                        Size = UDim2.new(0, 42, 0, 22),
                        Position = UDim2.new(1, -52, 0.5, -11),
                        BackgroundColor3 = default and Library.CurrentTheme.Accent or Library.CurrentTheme.Border,
                        Parent = TglFrame
                    }, {
                        MakeCorner(nil, 11),
                        Create("Frame", {
                            Name = "Thumb",
                            Size = UDim2.new(0, 16, 0, 16),
                            Position = UDim2.new(0, default and 23 or 3, 0.5, -8),
                            BackgroundColor3 = default and Library.CurrentTheme.Background or Library.CurrentTheme.TextSecondary,
                            Parent = TglFrame
                        }, { MakeCorner(nil, 8) })
                    }),
                    Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = TglFrame
                    })
                })

                if desc ~= "" then
                    Create("TextLabel", {
                        Size = UDim2.new(1, -60, 0, 14),
                        Position = UDim2.new(0, 10, 0, 20),
                        BackgroundTransparency = 1,
                        Text = desc,
                        TextColor3 = Library.CurrentTheme.TextMuted,
                        TextSize = 11,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = TglFrame
                    })
                end

                local state = default
                local function SetState(val)
                    state = val
                    Library.Flags[flag] = state
                    local switch = TglFrame.Switch
                    local thumb = switch.Thumb
                    Library:Tween(switch, 0.15, { BackgroundColor3 = state and Library.CurrentTheme.Accent or Library.CurrentTheme.Border })
                    Library:Tween(thumb, 0.15, {
                        Position = UDim2.new(0, state and 23 or 3, 0.5, -8),
                        BackgroundColor3 = state and Library.CurrentTheme.Background or Library.CurrentTheme.TextSecondary
                    })
                    callback(state)
                end

                TglFrame.TextButton.MouseButton1Click:Connect(function()
                    SetState(not state)
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = desc, Frame = TglFrame, Tab = TabObj })
                return { SetValue = SetState }
            end
----- 拉条部分
function SectionObj:CreateSlider(sldOpt)
    sldOpt = sldOpt or {}
    local name = sldOpt.Name or "Slider"
    local min = sldOpt.Min or 0
    local max = sldOpt.Max or 100
    local default = math.clamp(sldOpt.Default or min, min, max)
    local increment = sldOpt.Increment or 1
    local flag = sldOpt.Flag or name
    local callback = sldOpt.Callback or function() end

    Library.Flags[flag] = default

    -- ========================================
    -- UI 构建
    -- ========================================
    local SldFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
        Parent = SectionCard
    }, {
        MakeCorner(nil, 5),
        MakeStroke(nil, Library.CurrentTheme.Border, 1),
        Create("TextLabel", {
            Size = UDim2.new(1, -80, 0, 20),
            Position = UDim2.new(0, 10, 0, 4),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Library.CurrentTheme.TextPrimary,
            TextSize = 13,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Name = "ValueLabel",
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(1, -70, 0, 4),
            BackgroundTransparency = 1,
            Text = tostring(default),
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 12,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextXAlignment = Enum.TextXAlignment.Right
        })
    })

    -- Track
    local Track = Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -20, 0, 12),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(36, 36, 36),
        BorderSizePixel = 0,
        Parent = SldFrame
    }, {
        MakeCorner(nil, 6)
    })

    -- Fill
    local Fill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 163, 26),
        BorderSizePixel = 0,
        Parent = Track
    }, {
        MakeCorner(nil, 6)
    })

    -- Handle（视觉尺寸 44×22，hitbox 通过外层透明按钮扩大）
    local Handle = Create("Frame", {
        Name = "Handle",
        Size = UDim2.new(0, 44, 0, 22),
        BackgroundColor3 = Color3.fromRGB(24, 24, 24),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        ZIndex = 10,
        Parent = Track
    }, {
        MakeCorner(nil, 6),
        Create("UIStroke", {
            Name = "Stroke",
            Color = Color3.fromRGB(58, 58, 58),
            Thickness = 1.5,
            Transparency = 0,
        }),
        Create("UIScale", { Name = "ScaleObject", Scale = 1 }),
        Create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "‹ ›",
            TextColor3 = Color3.fromRGB(255, 163, 26),
            TextSize = 14,
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        })
    })

    -- 扩大 Hitbox（透明按钮覆盖整个 Track，触摸优先）
    local Hitbox = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = Track
    })

    -- ========================================
    -- 状态与变量
    -- ========================================
    local state = "idle"  -- idle | hover | pressed | dragging | releasing
    local isDragging = false
    local isHovering = false
    local currentValue = default
    local activeTweens = {}
    local connections = {}

    local function cancelAllTweens()
        for _, tw in ipairs(activeTweens) do
            if tw and tw.PlaybackState ~= Enum.PlaybackState.Completed then
                tw:Cancel()
            end
        end
        activeTweens = {}
    end

    local function cleanupConnections()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        connections = {}
    end

    -- ========================================
    -- 核心更新函数（实时，无动画）
    -- ========================================
    local function updateValue(val, updateCallback)
        val = math.clamp(val, min, max)
        currentValue = val
        local percent = (val - min) / (max - min)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        local trackWidth = Track.AbsoluteSize.X
        if trackWidth > 0 then
            Handle.Position = UDim2.new(0, percent * trackWidth, 0.5, 0)
        end
        Library.Flags[flag] = val
        if updateCallback ~= false then
            callback(val)
        end
    end

    -- ========================================
    -- 状态切换动画
    -- ========================================
    local function setState(newState)
        if state == newState then return end
        state = newState
        cancelAllTweens()

        local handleScaleObj = Handle:FindFirstChild("ScaleObject")
        local handleStroke = Handle:FindFirstChild("Stroke")
        local handleBg = Handle

        if state == "idle" then
            -- 回到静止
            local tw1 = Library:Tween(handleScaleObj, 0.12, { Scale = 1 })
            local tw2 = Library:Tween(Handle, 0.12, { BackgroundColor3 = Color3.fromRGB(24, 24, 24) })
            if handleStroke then
                local tw3 = Library:Tween(handleStroke, 0.12, { Color = Color3.fromRGB(58, 58, 58) })
                table.insert(activeTweens, tw3)
            end
            table.insert(activeTweens, tw1)
            table.insert(activeTweens, tw2)
        elseif state == "hover" then
            -- Hover: scale 1.03, Y -1, border 增亮
            local tw1 = Library:Tween(handleScaleObj, 0.10, { Scale = 1.03 })
            local tw2 = Library:Tween(Handle, 0.10, { BackgroundColor3 = Color3.fromRGB(34, 34, 34) })
            if handleStroke then
                local tw3 = Library:Tween(handleStroke, 0.10, { Color = Color3.fromRGB(80, 80, 80) })
                table.insert(activeTweens, tw3)
            end
            table.insert(activeTweens, tw1)
            table.insert(activeTweens, tw2)
            -- Y 偏移通过 Position 微调
            local currentPos = Handle.Position
            local twY = Library:Tween(Handle, 0.10, { Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, 0.5, -1) })
            table.insert(activeTweens, twY)
        elseif state == "pressed" then
            -- 按下压缩：1.03 → 0.98 快速，然后恢复
            local tw1 = Library:Tween(handleScaleObj, 0.07, { Scale = 0.98 })
            tw1.Completed:Connect(function()
                if state == "pressed" then
                    local tw2 = Library:Tween(handleScaleObj, 0.07, { Scale = 1.03 })
                    table.insert(activeTweens, tw2)
                end
            end)
            table.insert(activeTweens, tw1)
        elseif state == "dragging" then
            -- 拖拽开始：scale 1.06，Y +1，border 更亮
            local tw1 = Library:Tween(handleScaleObj, 0.08, { Scale = 1.06 })
            local tw2 = Library:Tween(Handle, 0.08, { BackgroundColor3 = Color3.fromRGB(38, 38, 38) })
            if handleStroke then
                local tw3 = Library:Tween(handleStroke, 0.08, { Color = Color3.fromRGB(120, 120, 120) })
                table.insert(activeTweens, tw3)
            end
            table.insert(activeTweens, tw1)
            table.insert(activeTweens, tw2)
            -- Y 偏移 +1
            local currentPos = Handle.Position
            local twY = Library:Tween(Handle, 0.08, { Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, 0.5, 1) })
            table.insert(activeTweens, twY)
        elseif state == "releasing" then
            -- 释放：从当前缩放平滑回到 idle（但 scale 实际会在 idle 中处理，此处可做过渡）
            -- 直接回到 idle，但加上一个 overshoot 抑制
            local tw1 = Library:Tween(handleScaleObj, 0.14, { Scale = 1.0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tw2 = Library:Tween(Handle, 0.14, { BackgroundColor3 = Color3.fromRGB(24, 24, 24) })
            if handleStroke then
                local tw3 = Library:Tween(handleStroke, 0.14, { Color = Color3.fromRGB(58, 58, 58) })
                table.insert(activeTweens, tw3)
            end
            table.insert(activeTweens, tw1)
            table.insert(activeTweens, tw2)
            -- Y 归零
            local currentPos = Handle.Position
            local twY = Library:Tween(Handle, 0.14, { Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, 0.5, 0) })
            table.insert(activeTweens, twY)
            -- 完成后进入 idle
            tw1.Completed:Connect(function()
                if state == "releasing" then
                    setState("idle")
                end
            end)
        end
    end

    -- ========================================
    -- 数值微动画（数字变化）
    -- ========================================
    local valueAnimTween = nil
    local function animateValueLabel(newVal)
        local label = SldFrame.ValueLabel
        label.Text = tostring(newVal)
        -- 取消旧动画
        if valueAnimTween and valueAnimTween.PlaybackState ~= Enum.PlaybackState.Completed then
            valueAnimTween:Cancel()
        end
        -- 微动画：透明度 0.6->1，Y 向下 2px 归位
        label.Transparency = 0.6
        local oldPos = label.Position
        label.Position = UDim2.new(oldPos.X.Scale, oldPos.X.Offset, oldPos.Y.Scale, oldPos.Y.Offset + 2)
        local tw = Library:Tween(label, 0.08, { Transparency = 1, Position = oldPos })
        valueAnimTween = tw
    end

    -- ========================================
    -- Snap 反馈
    -- ========================================
    local function triggerSnap()
        if increment <= 1 then return end
        local handleScaleObj = Handle:FindFirstChild("ScaleObject")
        if not handleScaleObj then return end
        cancelAllTweens()  -- 只取消现有动画，但会影响状态，我们可以只额外加一个短暂动画而不改变状态
        -- 快速缩放到 1.05 再回到当前状态目标值
        local currentScale = handleScaleObj.Scale
        local tw1 = Library:Tween(handleScaleObj, 0.06, { Scale = 1.05 })
        tw1.Completed:Connect(function()
            local targetScale = (state == "dragging" and 1.06) or (state == "hover" and 1.03) or 1.0
            if state == "idle" then targetScale = 1.0
            elseif state == "hover" then targetScale = 1.03
            elseif state == "dragging" then targetScale = 1.06
            elseif state == "pressed" then targetScale = 1.03 end
            local tw2 = Library:Tween(handleScaleObj, 0.06, { Scale = targetScale })
            table.insert(activeTweens, tw2)
        end)
        table.insert(activeTweens, tw1)
    end

    -- ========================================
    -- 数值计算与输入处理
    -- ========================================
    local function getValueFromPosition(inputPos)
        local trackX = Track.AbsolutePosition.X
        local trackWidth = Track.AbsoluteSize.X
        if trackWidth <= 0 then return nil end
        local percent = math.clamp((inputPos.X - trackX) / trackWidth, 0, 1)
        local rawVal = min + (max - min) * percent
        local steppedVal = math.floor(rawVal / increment + 0.5) * increment
        return math.clamp(steppedVal, min, max)
    end

    -- 拖动更新（实时）
    local function onDragUpdate(inputPos)
        local val = getValueFromPosition(inputPos)
        if val then
            local oldVal = currentValue
            updateValue(val, true)
            animateValueLabel(val)
            -- Snap 检测
            if increment > 1 and math.abs(val % increment) < 0.001 then
                if val ~= oldVal then  -- 跨过 snap 点
                    triggerSnap()
                end
            end
        end
    end

    -- ========================================
    -- 输入事件绑定
    -- ========================================
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- 按下
            if state == "idle" then
                setState("pressed")
                -- 短暂延迟进入 dragging（如果移动则自动切换）
            end
            isDragging = true
            -- 先更新到点击位置
            local val = getValueFromPosition(input.Position)
            if val then
                updateValue(val, true)
                animateValueLabel(val)
            end
            -- 进入 dragging 状态（覆盖 pressed）
            setState("dragging")
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                setState("releasing")
                -- 最终同步一次值
                updateValue(currentValue, false)
            end
        end
    end

    local function onInputChanged(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            onDragUpdate(input.Position)
        end
    end

    -- 绑定 Hitbox
    connections[#connections+1] = Hitbox.InputBegan:Connect(onInputBegan)
    connections[#connections+1] = Hitbox.InputEnded:Connect(onInputEnded)

    -- 全局移动和结束（确保鼠标移出窗口时释放）
    connections[#connections+1] = RegisterConnection(UserInputService.InputChanged:Connect(onInputChanged))
    connections[#connections+1] = RegisterConnection(UserInputService.InputEnded:Connect(onInputEnded))

    -- Hover 事件（仅鼠标）
    local function onMouseEnter()
        if not isDragging and state ~= "hover" and state ~= "pressed" then
            setState("hover")
        end
    end
    local function onMouseLeave()
        if not isDragging and state == "hover" then
            setState("idle")
        end
    end
    connections[#connections+1] = Handle.MouseEnter:Connect(onMouseEnter)
    connections[#connections+1] = Handle.MouseLeave:Connect(onMouseLeave)
    -- 同时让 Hitbox 也能触发 hover（扩大区域）
    connections[#connections+1] = Hitbox.MouseEnter:Connect(onMouseEnter)
    connections[#connections+1] = Hitbox.MouseLeave:Connect(onMouseLeave)

    -- 窗口尺寸变化时重新定位 Handle
    local function onSizeChange()
        if not isDragging then
            updateValue(currentValue, false)
        end
    end
    connections[#connections+1] = Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(onSizeChange)

    -- ========================================
    -- 初始化状态与位置
    -- ========================================
    updateValue(default, false)
    animateValueLabel(default)
    setState("idle")

    -- ========================================
    -- 对外 API
    -- ========================================
    local self = {
        SetValue = function(val)
            val = math.clamp(val, min, max)
            updateValue(val, true)
            animateValueLabel(val)
            if state == "idle" then
                -- 若在 idle，可触发微反馈
            end
        end
    }

    -- 清理（当 Slider 被销毁时，断开所有连接）
    local function cleanup()
        cleanupConnections()
        cancelAllTweens()
    end
    -- 利用父容器销毁事件自动清理（可选）
    SldFrame.AncestryChanged:Connect(function()
        if not SldFrame.Parent then
            cleanup()
        end
    end)

    -- 注册到全局清理（当 Library:Destroy 时也会断开）
    RegisterConnection(SldFrame.AncestryChanged:Connect(function() end)) -- dummy 占位，实际靠上面

    table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = SldFrame, Tab = TabObj })

    return self
end

            -- 4. DROPDOWN
            function SectionObj:CreateDropdown(drpOpt)
                drpOpt = drpOpt or {}
                local name = drpOpt.Name or "Dropdown"
                local options = drpOpt.Options or {}
                local default = drpOpt.CurrentOption or options[1] or ""
                local flag = drpOpt.Flag or name
                local callback = drpOpt.Callback or function() end

                Library.Flags[flag] = default

                local DrpFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 56),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    ClipsDescendants = false,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 18),
                        Position = UDim2.new(0, 10, 0, 4),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "Box",
                        Size = UDim2.new(1, -20, 0, 26),
                        Position = UDim2.new(0, 10, 0, 24),
                        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
                        Parent = DrpFrame
                    }, {
                        MakeCorner(nil, 4),
                        MakeStroke(nil, Library.CurrentTheme.Border, 1),
                        Create("TextLabel", {
                            Name = "SelectedText",
                            Size = UDim2.new(1, -24, 1, 0),
                            Position = UDim2.new(0, 8, 0, 0),
                            BackgroundTransparency = 1,
                            Text = default,
                            TextColor3 = Library.CurrentTheme.Accent,
                            TextSize = 12,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            TextXAlignment = Enum.TextXAlignment.Left
                        }),
                        Create("TextLabel", {
                            Size = UDim2.new(0, 20, 1, 0),
                            Position = UDim2.new(1, -20, 0, 0),
                            BackgroundTransparency = 1,
                            Text = "▼",
                            TextColor3 = Library.CurrentTheme.TextMuted,
                            TextSize = 10
                        }),
                        Create("TextButton", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "",
                            Parent = DrpFrame
                        })
                    })
                })

                -- Dropdown Popup Container
                local ListPop = Create("Frame", {
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 1, 2),
                    BackgroundColor3 = Library.CurrentTheme.Background,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 500,
                    Parent = DrpFrame
                }, {
                    MakeCorner(nil, 4),
                    MakeStroke(nil, Library.CurrentTheme.Accent, 1),
                    Create("ScrollingFrame", {
                        Name = "Scroll",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Library.CurrentTheme.Accent,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y
                    }, {
                        MakePadding(nil, 4, 4, 4, 4),
                        Create("UIListLayout", { Padding = UDim.new(0, 2) })
                    })
                })

                local opened = false
                local scroll = ListPop.Scroll

                local function PopulateOptions()
                    for _, child in ipairs(scroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for _, opt in ipairs(options) do
                        local item = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundColor3 = opt == Library.Flags[flag] and Library.CurrentTheme.ElementBackground or Library.CurrentTheme.Background,
                            Text = opt,
                            TextColor3 = opt == Library.Flags[flag] and Library.CurrentTheme.Accent or Library.CurrentTheme.TextSecondary,
                            TextSize = 12,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            Parent = scroll
                        }, { MakeCorner(nil, 3) })

                        item.MouseButton1Click:Connect(function()
                            Library.Flags[flag] = opt
                            DrpFrame.Box.SelectedText.Text = opt
                            opened = false
                            ListPop.Visible = false
                            ListPop.Size = UDim2.new(1, -20, 0, 0)
                            callback(opt)
                        end)
                    end
                end

                DrpFrame.Box.TextButton.MouseButton1Click:Connect(function()
                    opened = not opened
                    if opened then
                        PopulateOptions()
                        ListPop.Visible = true
                        local targetHeight = math.min(#options * 26 + 10, 130)
                        Library:Tween(ListPop, 0.15, { Size = UDim2.new(1, -20, 0, targetHeight) })
                    else
                        Library:Tween(ListPop, 0.12, { Size = UDim2.new(1, -20, 0, 0) }).Completed:Connect(function()
                            ListPop.Visible = false
                        end)
                    end
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = DrpFrame, Tab = TabObj })
                return {
                    SetOptions = function(newOpts, newDef)
                        options = newOpts
                        if newDef then
                            Library.Flags[flag] = newDef
                            DrpFrame.Box.SelectedText.Text = newDef
                        end
                    end
                }
            end

                   -- 5. TEXTBOX
            function SectionObj:CreateTextbox(txtOpt)
                txtOpt = txtOpt or {}
                local name = txtOpt.Name or "Input"
                local placeholder = txtOpt.Placeholder or "Type here..."
                local flag = txtOpt.Flag or name
                local callback = txtOpt.Callback or function() end

                local TxtFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 56),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 18),
                        Position = UDim2.new(0, 10, 0, 4),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "InputBox",
                        Size = UDim2.new(1, -20, 0, 26),
                        Position = UDim2.new(0, 10, 0, 24),
                        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
                        Parent = TxtFrame
                    }, {
                        MakeCorner(nil, 4),
                        MakeStroke(nil, Library.CurrentTheme.Border, 1),
                        Create("TextBox", {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 6, 0, 0),
                            BackgroundTransparency = 1,
                            PlaceholderText = placeholder,
                            PlaceholderColor3 = Library.CurrentTheme.TextMuted,
                            Text = "",
                            TextColor3 = Library.CurrentTheme.TextPrimary,
                            TextSize = 12,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ClearTextOnFocus = false
                        })
                    })
                })

                local input = TxtFrame.InputBox.TextBox
                local stroke = TxtFrame.InputBox.UIStroke

                input.Focused:Connect(function()
                    Library:Tween(stroke, 0.15, { Color = Library.CurrentTheme.Accent })
                end)

                input.FocusLost:Connect(function(enterPressed)
                    Library:Tween(stroke, 0.15, { Color = Library.CurrentTheme.Border })
                    Library.Flags[flag] = input.Text
                    callback(input.Text, enterPressed)
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = TxtFrame, Tab = TabObj })
                return {
                    SetText = function(str)
                        input.Text = str
                        Library.Flags[flag] = str
                    end
                }
            end

            -- 6. KEYBIND
            function SectionObj:CreateKeybind(keyOpt)
                keyOpt = keyOpt or {}
                local name = keyOpt.Name or "Keybind"
                local default = keyOpt.Default or Enum.KeyCode.E
                local flag = keyOpt.Flag or name
                local callback = keyOpt.Callback or function() end

                Library.Flags[flag] = default

                local KeyFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -120, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "BindBtn",
                        Size = UDim2.new(0, 90, 0, 24),
                        Position = UDim2.new(1, -100, 0.5, -12),
                        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
                        Parent = KeyFrame
                    }, {
                        MakeCorner(nil, 4),
                        MakeStroke(nil, Library.CurrentTheme.Border, 1),
                        Create("TextLabel", {
                            Name = "BindText",
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = default.Name,
                            TextColor3 = Library.CurrentTheme.Accent,
                            TextSize = 11,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                        }),
                        Create("TextButton", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "",
                            Parent = KeyFrame
                        })
                    })
                })

                local binding = false
                local bindLabel = KeyFrame.BindBtn.BindText

                KeyFrame.BindBtn.TextButton.MouseButton1Click:Connect(function()
                    binding = true
                    bindLabel.Text = "[ PRESS KEY ]"
                    bindLabel.TextColor3 = Library.CurrentTheme.Warning
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            binding = false
                            local key = input.KeyCode
                            Library.Flags[flag] = key
                            bindLabel.Text = key.Name
                            bindLabel.TextColor3 = Library.CurrentTheme.Accent
                            callback(key)
                        end
                    end
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = KeyFrame, Tab = TabObj })
            end

            -- 6.5 MULTI DROPDOWN
            function SectionObj:CreateMultiDropdown(multiOpt)
                multiOpt = multiOpt or {}
                local name = multiOpt.Name or "Multi Dropdown"
                local options = multiOpt.Options or {}
                local default = multiOpt.Default or {}
                local flag = multiOpt.Flag or name
                local callback = multiOpt.Callback or function() end

                local function tableFind(tbl, val)
                    for _, v in ipairs(tbl) do
                        if v == val then return true end
                    end
                    return false
                end

                local selected = {}
                for _, opt in ipairs(options) do
                    selected[opt] = tableFind(default, opt)
                end
                Library.Flags[flag] = selected

                local MultiFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 56),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    ClipsDescendants = false,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -20, 0, 18),
                        Position = UDim2.new(0, 10, 0, 4),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "Box",
                        Size = UDim2.new(1, -20, 0, 26),
                        Position = UDim2.new(0, 10, 0, 24),
                        BackgroundColor3 = Library.CurrentTheme.ElementBackground,
                        Parent = MultiFrame
                    }, {
                        MakeCorner(nil, 4),
                        MakeStroke(nil, Library.CurrentTheme.Border, 1),
                        Create("TextLabel", {
                            Name = "SelectedText",
                            Size = UDim2.new(1, -24, 1, 0),
                            Position = UDim2.new(0, 8, 0, 0),
                            BackgroundTransparency = 1,
                            Text = "Select Options...",
                            TextColor3 = Library.CurrentTheme.Accent,
                            TextSize = 12,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            TextXAlignment = Enum.TextXAlignment.Left
                        }),
                        Create("TextButton", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "",
                            Parent = MultiFrame
                        })
                    })
                })

                local ListPop = Create("Frame", {
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 1, 2),
                    BackgroundColor3 = Library.CurrentTheme.Background,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 500,
                    Parent = MultiFrame
                }, {
                    MakeCorner(nil, 4),
                    MakeStroke(nil, Library.CurrentTheme.Accent, 1),
                    Create("ScrollingFrame", {
                        Name = "Scroll",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Library.CurrentTheme.Accent,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y
                    }, {
                        MakePadding(nil, 4, 4, 4, 4),
                        Create("UIListLayout", { Padding = UDim.new(0, 2) })
                    })
                })

                local opened = false
                local scroll = ListPop.Scroll

                local function UpdateLabelText()
                    local chosen = {}
                    for opt, isSel in pairs(selected) do
                        if isSel then table.insert(chosen, opt) end
                    end
                    if #chosen == 0 then
                        MultiFrame.Box.SelectedText.Text = "None Selected"
                    else
                        MultiFrame.Box.SelectedText.Text = table.concat(chosen, ", ")
                    end
                end
                UpdateLabelText()

                local function PopulateMultiOptions()
                    for _, child in ipairs(scroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for _, opt in ipairs(options) do
                        local isSel = selected[opt] == true
                        local item = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundColor3 = isSel and Library.CurrentTheme.ElementBackground or Library.CurrentTheme.Background,
                            Text = (isSel and "[✓] " or "[  ] ") .. opt,
                            TextColor3 = isSel and Library.CurrentTheme.Accent or Library.CurrentTheme.TextSecondary,
                            TextSize = 12,
                            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                            Parent = scroll
                        }, { MakeCorner(nil, 3) })

                        item.MouseButton1Click:Connect(function()
                            selected[opt] = not selected[opt]
                            item.Text = (selected[opt] and "[✓] " or "[  ] ") .. opt
                            item.TextColor3 = selected[opt] and Library.CurrentTheme.Accent or Library.CurrentTheme.TextSecondary
                            item.BackgroundColor3 = selected[opt] and Library.CurrentTheme.ElementBackground or Library.CurrentTheme.Background
                            UpdateLabelText()
                            callback(selected)
                        end)
                    end
                end

                MultiFrame.Box.TextButton.MouseButton1Click:Connect(function()
                    opened = not opened
                    if opened then
                        PopulateMultiOptions()
                        ListPop.Visible = true
                        local targetHeight = math.min(#options * 26 + 10, 130)
                        Library:Tween(ListPop, 0.15, { Size = UDim2.new(1, -20, 0, targetHeight) })
                    else
                        Library:Tween(ListPop, 0.12, { Size = UDim2.new(1, -20, 0, 0) }).Completed:Connect(function()
                            ListPop.Visible = false
                        end)
                    end
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = MultiFrame, Tab = TabObj })
            end

            -- 6.6 COLOR PICKER
            function SectionObj:CreateColorPicker(clrOpt)
                clrOpt = clrOpt or {}
                local name = clrOpt.Name or "Color Picker"
                local default = clrOpt.Default or Color3.fromRGB(255, 163, 26)
                local flag = clrOpt.Flag or name
                local callback = clrOpt.Callback or function() end

                Library.Flags[flag] = default

                local ClrFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    Create("TextLabel", {
                        Size = UDim2.new(1, -60, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = name,
                        TextColor3 = Library.CurrentTheme.TextPrimary,
                        TextSize = 13,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("Frame", {
                        Name = "ColorBox",
                        Size = UDim2.new(0, 32, 0, 20),
                        Position = UDim2.new(1, -42, 0.5, -10),
                        BackgroundColor3 = default,
                        Parent = ClrFrame
                    }, {
                        MakeCorner(nil, 4),
                        MakeStroke(nil, Library.CurrentTheme.Border, 1),
                        Create("TextButton", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = "",
                            Parent = ClrFrame
                        })
                    })
                })

                local currentColor = default

                ClrFrame.ColorBox.TextButton.MouseButton1Click:Connect(function()
                    Library:Dialog({
                        Title = "COLOR PICKER",
                        Content = "Presets for " .. name .. ":",
                        Buttons = {
                            { Name = "Gold", Style = "Accent", Callback = function()
                                currentColor = Color3.fromRGB(255, 163, 26)
                                ClrFrame.ColorBox.BackgroundColor3 = currentColor
                                Library.Flags[flag] = currentColor
                                callback(currentColor)
                            end },
                            { Name = "Red", Style = "Secondary", Callback = function()
                                currentColor = Color3.fromRGB(231, 76, 60)
                                ClrFrame.ColorBox.BackgroundColor3 = currentColor
                                Library.Flags[flag] = currentColor
                                callback(currentColor)
                            end },
                            { Name = "Blue", Style = "Secondary", Callback = function()
                                currentColor = Color3.fromRGB(52, 152, 219)
                                ClrFrame.ColorBox.BackgroundColor3 = currentColor
                                Library.Flags[flag] = currentColor
                                callback(currentColor)
                            end },
                            { Name = "Green", Style = "Secondary", Callback = function()
                                currentColor = Color3.fromRGB(46, 204, 113)
                                ClrFrame.ColorBox.BackgroundColor3 = currentColor
                                Library.Flags[flag] = currentColor
                                callback(currentColor)
                            end }
                        }
                    })
                end)

                table.insert(Library.SearchRegistry, { Name = name, Description = "", Frame = ClrFrame, Tab = TabObj })
            end

            -- 7. LABEL & PARAGRAPH
            function SectionObj:CreateLabel(txt)
                local LblFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent = SectionCard
                }, {
                    Create("TextLabel", {
                        Name = "Text",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = txt or "Label",
                        TextColor3 = Library.CurrentTheme.TextSecondary,
                        TextSize = 12,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                })

                return {
                    SetText = function(t)
                        LblFrame.Text.Text = t
                    end
                }
            end

            function SectionObj:CreateParagraph(paraOpt)
                paraOpt = paraOpt or {}
                local title = paraOpt.Title or "Paragraph Title"
                local content = paraOpt.Content or "Paragraph content details go here."

                local ParaFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 52),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Library.CurrentTheme.SecondaryBackground,
                    Parent = SectionCard
                }, {
                    MakeCorner(nil, 5),
                    MakeStroke(nil, Library.CurrentTheme.Border, 1),
                    MakePadding(nil, 8, 8, 10, 10),
                    Create("UIListLayout", { Padding = UDim.new(0, 4) }),
                    Create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Text = title:upper(),
                        TextColor3 = Library.CurrentTheme.Accent,
                        TextSize = 12,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    Create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 24),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Text = content,
                        TextColor3 = Library.CurrentTheme.TextSecondary,
                        TextSize = 11,
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true
                    })
                })

                return ParaFrame
            end

            -- 8. DIVIDER
            function SectionObj:CreateDivider()
                return Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.CurrentTheme.Border,
                    BorderSizePixel = 0,
                    Parent = SectionCard
                })
            end

            return SectionObj
        end

        return TabObj
    end

    return WindowObject
end

return Library
