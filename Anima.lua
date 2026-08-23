--[[
    AnimeUI Library
    Lightweight Japanese Anime / 二次元 Style UI Library for Roblox
    
    Design Goals:
    - Clean, elegant, soft, minimal anime game menu aesthetic
    - High quality Tween animations
    - Consistent visual language across all components
    - Full PC + Mobile support
    - Modular & easily extensible
]]

local AnimeUI = {}
AnimeUI.__index = AnimeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================
-- THEME SYSTEM
--========================================================

local Themes = {
    ["Purple Anime"] = {
        Primary     = Color3.fromHex("C8A2FF"),
        Secondary   = Color3.fromHex("A98BE8"),
        Accent      = Color3.fromHex("FF9FCB"),
        Background  = Color3.fromHex("15141B"),
        Panel       = Color3.fromHex("1D1B24"),
        Element     = Color3.fromHex("25222E"),
        ElementHover= Color3.fromHex("2E2A38"),
        Text        = Color3.fromHex("F5F2FA"),
        SubText     = Color3.fromHex("AAA5B5"),
        Border      = Color3.fromHex("393342"),
        Success     = Color3.fromHex("A8E6CF"),
        Warning     = Color3.fromHex("FFD3B6"),
        Error       = Color3.fromHex("FFAAA5"),
    },
    ["Sakura"] = {
        Primary     = Color3.fromHex("FFB7C5"),
        Secondary   = Color3.fromHex("FF9EB5"),
        Accent      = Color3.fromHex("FF8FAB"),
        Background  = Color3.fromHex("1A1518"),
        Panel       = Color3.fromHex("231C20"),
        Element     = Color3.fromHex("2C2429"),
        ElementHover= Color3.fromHex("362C32"),
        Text        = Color3.fromHex("FFF0F3"),
        SubText     = Color3.fromHex("C9B0B8"),
        Border      = Color3.fromHex("3D3338"),
        Success     = Color3.fromHex("B5EAD7"),
        Warning     = Color3.fromHex("FFDAC1"),
        Error       = Color3.fromHex("FF9AA2"),
    },
    ["Dark Anime"] = {
        Primary     = Color3.fromHex("9B8CFF"),
        Secondary   = Color3.fromHex("7B6FE0"),
        Accent      = Color3.fromHex("C4B5FD"),
        Background  = Color3.fromHex("0F0E14"),
        Panel       = Color3.fromHex("17161D"),
        Element     = Color3.fromHex("1F1E26"),
        ElementHover= Color3.fromHex("292830"),
        Text        = Color3.fromHex("EDE9FE"),
        SubText     = Color3.fromHex("A1A1AA"),
        Border      = Color3.fromHex("2E2D36"),
        Success     = Color3.fromHex("86EFAC"),
        Warning     = Color3.fromHex("FCD34D"),
        Error       = Color3.fromHex("FCA5A5"),
    }
}

--========================================================
-- UTILITY
--========================================================

local Utility = {}

function Utility:Tween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, style, direction),
        properties
    )
    tween:Play()
    return tween
end

function Utility:Create(className, properties, children)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

function Utility:Ripple(button, color)
    local ripple = Utility:Create("Frame", {
        Name = "Ripple",
        BackgroundColor3 = color or Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = button.ZIndex + 1,
        Parent = button
    })
    
    local corner = Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
    
    Utility:Tween(ripple, {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1
    }, 0.35)
    
    task.delay(0.4, function()
        ripple:Destroy()
    end)
end

function Utility:AddConnection(connections, connection)
    table.insert(connections, connection)
    return connection
end

function Utility:DisconnectAll(connections)
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)
end

function Utility:IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

--========================================================
-- NOTIFICATION SYSTEM
--========================================================

local NotificationContainer = nil

local function EnsureNotificationContainer()
    if NotificationContainer and NotificationContainer.Parent then
        return NotificationContainer
    end
    
    local screenGui = Utility:Create("ScreenGui", {
        Name = "AnimeUI_Notifications",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = PlayerGui
    })
    
    NotificationContainer = Utility:Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(1, -340, 0, 20),
        AnchorPoint = Vector2.new(0, 0),
        Parent = screenGui
    })
    
    Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = NotificationContainer
    })
    
    return NotificationContainer
end

function AnimeUI:Notify(options)
    options = options or {}
    local title = options.Title or "Anime UI"
    local content = options.Content or ""
    local duration = options.Duration or 3
    local theme = Themes[options.Theme or "Purple Anime"] or Themes["Purple Anime"]
    
    local container = EnsureNotificationContainer()
    
    local notif = Utility:Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = container
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = notif
    })
    
    Utility:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Transparency = 0.4,
        Parent = notif
    })
    
    -- Accent line on left
    local accent = Utility:Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = notif
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 2),
        Parent = accent
    })
    
    local titleLabel = Utility:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 22),
        Position = UDim2.new(0, 16, 0, 10),
        Font = Enum.Font.GothamMedium,
        Text = "✦  " .. title,
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    local contentLabel = Utility:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 16, 0, 34),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif
    })
    
    -- Calculate height
    local textBounds = contentLabel.TextBounds
    local height = 50 + math.max(textBounds.Y, 16)
    contentLabel.Size = UDim2.new(1, -24, 0, textBounds.Y + 4)
    
    notif.Size = UDim2.new(1, 0, 0, height)
    
    -- Animate in
    notif.Position = UDim2.new(1, 40, 0, 0)
    notif.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    contentLabel.TextTransparency = 1
    accent.BackgroundTransparency = 1
    
    Utility:Tween(notif, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.05
    }, 0.32)
    
    Utility:Tween(titleLabel, {TextTransparency = 0}, 0.28)
    Utility:Tween(contentLabel, {TextTransparency = 0}, 0.28)
    Utility:Tween(accent, {BackgroundTransparency = 0}, 0.28)
    
    -- Auto dismiss
    task.delay(duration, function()
        if not notif or not notif.Parent then return end
        
        Utility:Tween(notif, {
            Position = UDim2.new(1, 40, 0, 0),
            BackgroundTransparency = 1
        }, 0.28)
        
        Utility:Tween(titleLabel, {TextTransparency = 1}, 0.22)
        Utility:Tween(contentLabel, {TextTransparency = 1}, 0.22)
        Utility:Tween(accent, {BackgroundTransparency = 1}, 0.22)
        
        task.delay(0.35, function()
            notif:Destroy()
        end)
    end)
end

--========================================================
-- MAIN LIBRARY
--========================================================

function AnimeUI:CreateWindow(options)
    options = options or {}
    
    local themeName = options.Theme or "Purple Anime"
    local theme = Themes[themeName] or Themes["Purple Anime"]
    
    local windowData = {
        Title = options.Title or "Anime UI",
        Subtitle = options.Subtitle or "アニメ UI",
        Theme = theme,
        ThemeName = themeName,
        Tabs = {},
        CurrentTab = nil,
        Connections = {},
        Minimized = false,
        Closed = false
    }
    
    -- ScreenGui
    local screenGui = Utility:Create("ScreenGui", {
        Name = "AnimeUI_" .. tostring(math.random(10000, 99999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = PlayerGui
    })
    
    -- UIScale for responsive design
    local uiScale = Utility:Create("UIScale", {
        Scale = 1,
        Parent = screenGui
    })
    
    local function UpdateScale()
        local viewport = workspace.CurrentCamera.ViewportSize
        local scale = 1
        
        if viewport.X < 700 then
            scale = 0.85
        elseif viewport.X < 900 then
            scale = 0.92
        end
        
        if Utility:IsMobile() then
            scale = math.clamp(scale * 0.95, 0.75, 0.95)
        end
        
        uiScale.Scale = scale
    end
    
    UpdateScale()
    Utility:AddConnection(windowData.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale))
    
    -- Main Window Frame
    local mainFrame = Utility:Create("Frame", {
        Name = "MainWindow",
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(560, 380),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        Parent = screenGui
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = mainFrame
    })
    
    Utility:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1.2,
        Transparency = 0.35,
        Parent = mainFrame
    })
    
    -- Soft shadow (using UIStroke simulation via outer frame if needed, but keep light)
    local shadow = Utility:Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993", -- soft shadow asset, fallback transparent
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 0,
        Parent = mainFrame
    })
    
    -- Header
    local header = Utility:Create("Frame", {
        Name = "Header",
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = mainFrame
    })
    
    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = header
    })
    
    -- Fix bottom corners of header
    local headerFix = Utility:Create("Frame", {
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, -16),
        Parent = header
    })
    
    local titleLabel = Utility:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "✦  " .. windowData.Title,
        TextColor3 = theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    local subtitleLabel = Utility:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, 140, 0, 0),
        Font = Enum.Font.Gotham,
        Text = windowData.Subtitle,
        TextColor3 = theme.SubText,
        TextSize = 11,
        TextTransparency = 0.4,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Window Controls
    local controls = Utility:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        Parent = header
    })
    
    local function CreateControlButton(text, offset, callback)
        local btn = Utility:Create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(0, offset, 0.5, -12),
            Font = Enum.Font.GothamMedium,
            Text = text,
            TextColor3 = theme.SubText,
            TextSize = 14,
            AutoButtonColor = false,
            Parent = controls
        })
        
        btn.MouseEnter:Connect(function()
            Utility:Tween(btn, {TextColor3 = theme.Text}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            Utility:Tween(btn, {TextColor3 = theme.SubText}, 0.12)
        end)
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    CreateControlButton("—", 0, function()
        windowData.Minimized = not windowData.Minimized
        if windowData.Minimized then
            Utility:Tween(mainFrame, {Size = UDim2.fromOffset(560, 42)}, 0.25)
        else
            Utility:Tween(mainFrame, {Size = UDim2.fromOffset(560, 380)}, 0.25)
        end
    end)
    
    CreateControlButton("□", 28, function()
        -- Placeholder for maximize (optional)
    end)
    
    CreateControlButton("×", 56, function()
        windowData.Closed = true
        Utility:Tween(mainFrame, {
            Size = UDim2.fromOffset(560, 0),
            BackgroundTransparency = 1
        }, 0.22)
        task.delay(0.25, function()
            Utility:DisconnectAll(windowData.Connections)
            screenGui:Destroy()
        end)
    end)
    
    -- Dragging (Header only)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                UpdateDrag(input)
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateDrag(input)
        end
    end)
    
    -- Body
    local body = Utility:Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        Parent = mainFrame
    })
    
    -- Left Sidebar (Tabs)
    local sidebar = Utility:Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 140, 1, 0),
        Parent = body
    })
    
    Utility:Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = sidebar
    })
    
    local tabList = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar
    })
    
    -- Content Area
    local contentArea = Utility:Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 150, 0, 0),
        ClipsDescendants = true,
        Parent = body
    })
    
    local contentScroll = Utility:Create("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Primary,
        ScrollBarImageTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = contentArea
    })
    
    local contentLayout = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = contentScroll
    })
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Window Open Animation
    mainFrame.Size = UDim2.fromOffset(540, 360)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Position = UDim2.new(0.5, 0, 0.52, 0)
    
    Utility:Tween(mainFrame, {
        Size = UDim2.fromOffset(560, 380),
        BackgroundTransparency = 0.08,
        Position = UDim2.fromScale(0.5, 0.5)
    }, 0.28, Enum.EasingStyle.Quint)
    
    --========================================================
    -- TAB SYSTEM
    --========================================================
    
    function windowData:AddTab(tabOptions)
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or "Tab"
        
        local tabData = {
            Name = tabName,
            Sections = {},
            Container = nil,
            Button = nil,
            Active = false
        }
        
        -- Tab Button
        local tabBtn = Utility:Create("TextButton", {
            Name = tabName,
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.Gotham,
            Text = "",
            AutoButtonColor = false,
            Parent = sidebar
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = tabBtn
        })
        
        local indicator = Utility:Create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundTransparency = 1,
            Parent = tabBtn
        })
        
        Utility:Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = indicator
        })
        
        local tabText = Utility:Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            Font = Enum.Font.Gotham,
            Text = "○  " .. tabName,
            TextColor3 = theme.SubText,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabBtn
        })
        
        tabData.Button = tabBtn
        tabData.Indicator = indicator
        tabData.Text = tabText
        
        -- Tab Content Container
        local tabContainer = Utility:Create("Frame", {
            Name = tabName .. "_Content",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = contentScroll
        })
        
        local tabLayout = Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabContainer
        })
        
        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContainer.Size = UDim2.new(1, 0, 0, tabLayout.AbsoluteContentSize.Y)
        end)
        
        tabData.Container = tabContainer
        
        local function ActivateTab()
            if windowData.CurrentTab == tabData then return end
            
            -- Deactivate previous
            if windowData.CurrentTab then
                local prev = windowData.CurrentTab
                prev.Active = false
                Utility:Tween(prev.Button, {BackgroundTransparency = 1}, 0.18)
                Utility:Tween(prev.Indicator, {BackgroundTransparency = 1}, 0.15)
                Utility:Tween(prev.Text, {TextColor3 = theme.SubText}, 0.15)
                prev.Text.Text = "○  " .. prev.Name
                
                -- Fade out
                Utility:Tween(prev.Container, {Position = UDim2.new(-0.05, 0, 0, 0)}, 0.18)
                task.delay(0.12, function()
                    prev.Container.Visible = false
                end)
            end
            
            -- Activate new
            tabData.Active = true
            windowData.CurrentTab = tabData
            
            Utility:Tween(tabBtn, {BackgroundTransparency = 0.4}, 0.18)
            Utility:Tween(indicator, {BackgroundTransparency = 0}, 0.18)
            Utility:Tween(tabText, {TextColor3 = theme.Text}, 0.15)
            tabText.Text = "●  " .. tabName
            
            tabContainer.Visible = true
            tabContainer.Position = UDim2.new(0.05, 0, 0, 0)
            Utility:Tween(tabContainer, {Position = UDim2.new(0, 0, 0, 0)}, 0.2)
        end
        
        tabBtn.MouseButton1Click:Connect(ActivateTab)
        tabBtn.TouchTap:Connect(ActivateTab) -- Mobile
        
        tabBtn.MouseEnter:Connect(function()
            if not tabData.Active then
                Utility:Tween(tabBtn, {BackgroundTransparency = 0.7}, 0.12)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not tabData.Active then
                Utility:Tween(tabBtn, {BackgroundTransparency = 1}, 0.12)
            end
        end)
        
        -- First tab auto activate
        if #windowData.Tabs == 0 then
            task.defer(ActivateTab)
        end
        
        table.insert(windowData.Tabs, tabData)
        
        --========================================================
        -- SECTION
        --========================================================
        
        function tabData:AddSection(sectionOptions)
            sectionOptions = sectionOptions or {}
            local sectionName = sectionOptions.Name or "Section"
            
            local sectionFrame = Utility:Create("Frame", {
                Name = sectionName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 0, 0),
                Parent = tabContainer
            })
            
            local sectionLayout = Utility:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = sectionFrame
            })
            
            -- Section Header
            local headerFrame = Utility:Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                Parent = sectionFrame
            })
            
            Utility:Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = "✦  " .. string.upper(sectionName),
                TextColor3 = theme.Primary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerFrame
            })
            
            -- Content box
            local contentBox = Utility:Create("Frame", {
                Name = "Content",
                BackgroundColor3 = theme.Element,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = sectionFrame
            })
            
            Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 10),
                Parent = contentBox
            })
            
            Utility:Create("UIStroke", {
                Color = theme.Border,
                Thickness = 1,
                Transparency = 0.55,
                Parent = contentBox
            })
            
            Utility:Create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = contentBox
            })
            
            local boxLayout = Utility:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = contentBox
            })
            
            boxLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                contentBox.Size = UDim2.new(1, 0, 0, boxLayout.AbsoluteContentSize.Y + 20)
                sectionFrame.Size = UDim2.new(1, -8, 0, sectionLayout.AbsoluteContentSize.Y)
            end)
            
            local sectionData = {
                Frame = sectionFrame,
                Content = contentBox
            }
            
            --========================================================
            -- COMPONENTS
            --========================================================
            
            -- Label
            function sectionData:AddLabel(labelOptions)
                labelOptions = labelOptions or {}
                local text = labelOptions.Text or "Label"
                
                local label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = theme.SubText,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = contentBox
                })
                
                return label
            end
            
            -- Divider
            function sectionData:AddDivider()
                local divider = Utility:Create("Frame", {
                    BackgroundColor3 = theme.Border,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = contentBox
                })
                return divider
            end
            
            -- Button
            function sectionData:AddButton(btnOptions)
                btnOptions = btnOptions or {}
                local name = btnOptions.Name or "Button"
                local callback = btnOptions.Callback or function() end
                
                local btn = Utility:Create("TextButton", {
                    Name = name,
                    BackgroundColor3 = theme.Element,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.Gotham,
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true,
                    Parent = contentBox
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = btn
                })
                
                Utility:Create("UIStroke", {
                    Color = theme.Border,
                    Thickness = 1,
                    Transparency = 0.5,
                    Parent = btn
                })
                
                local btnText = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = name .. "  ›",
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btn
                })
                
                local function OnHover()
                    Utility:Tween(btn, {BackgroundColor3 = theme.ElementHover}, 0.15)
                end
                local function OnLeave()
                    Utility:Tween(btn, {BackgroundColor3 = theme.Element}, 0.15)
                end
                
                btn.MouseEnter:Connect(OnHover)
                btn.MouseLeave:Connect(OnLeave)
                
                btn.MouseButton1Down:Connect(function()
                    Utility:Tween(btn, {Size = UDim2.new(1, -4, 0, 32)}, 0.08)
                end)
                
                btn.MouseButton1Up:Connect(function()
                    Utility:Tween(btn, {Size = UDim2.new(1, 0, 0, 34)}, 0.12)
                end)
                
                local function OnClick()
                    Utility:Ripple(btn, theme.Accent)
                    task.spawn(callback)
                end
                
                btn.MouseButton1Click:Connect(OnClick)
                btn.TouchTap:Connect(OnClick)
                
                return btn
            end
            
            -- Toggle
            function sectionData:AddToggle(toggleOptions)
                toggleOptions = toggleOptions or {}
                local name = toggleOptions.Name or "Toggle"
                local default = toggleOptions.Default or false
                local callback = toggleOptions.Callback or function() end
                
                local state = default
                
                local toggleFrame = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = contentBox
                })
                
                local label = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleFrame
                })
                
                local track = Utility:Create("Frame", {
                    BackgroundColor3 = state and theme.Accent or theme.Border,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(40, 20),
                    Position = UDim2.new(1, -40, 0.5, -10),
                    Parent = toggleFrame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = track
                })
                
                local thumb = Utility:Create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(16, 16),
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    Parent = track
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = thumb
                })
                
                -- Soft glow when on
                local glow = Utility:Create("UIStroke", {
                    Color = theme.Accent,
                    Thickness = 0,
                    Transparency = 1,
                    Parent = track
                })
                
                local function SetState(value, animate)
                    state = value
                    local duration = animate and 0.18 or 0
                    
                    Utility:Tween(track, {
                        BackgroundColor3 = state and theme.Accent or theme.Border
                    }, duration)
                    
                    Utility:Tween(thumb, {
                        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    }, duration, Enum.EasingStyle.Quint)
                    
                    Utility:Tween(glow, {
                        Thickness = state and 2 or 0,
                        Transparency = state and 0.6 or 1
                    }, duration)
                    
                    task.spawn(callback, state)
                end
                
                local clickArea = Utility:Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = toggleFrame
                })
                
                clickArea.MouseButton1Click:Connect(function()
                    SetState(not state, true)
                end)
                clickArea.TouchTap:Connect(function()
                    SetState(not state, true)
                end)
                
                -- Init
                SetState(default, false)
                
                return {
                    Set = function(_, value)
                        SetState(value, true)
                    end,
                    Get = function()
                        return state
                    end
                }
            end
            
            -- Slider
            function sectionData:AddSlider(sliderOptions)
                sliderOptions = sliderOptions or {}
                local name = sliderOptions.Name or "Slider"
                local min = sliderOptions.Min or 0
                local max = sliderOptions.Max or 100
                local default = sliderOptions.Default or min
                local callback = sliderOptions.Callback or function() end
                
                local value = math.clamp(default, min, max)
                
                local sliderFrame = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 46),
                    Parent = contentBox
                })
                
                local topRow = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Parent = sliderFrame
                })
                
                Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.7, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = topRow
                })
                
                local valueLabel = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.3, 0, 1, 0),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(value),
                    TextColor3 = theme.Primary,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = topRow
                })
                
                local track = Utility:Create("Frame", {
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 28),
                    Parent = sliderFrame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = track
                })
                
                local fill = Utility:Create("Frame", {
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    Parent = track
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = fill
                })
                
                local thumb = Utility:Create("Frame", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
                    ZIndex = 2,
                    Parent = track
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = thumb
                })
                
                Utility:Create("UIStroke", {
                    Color = theme.Accent,
                    Thickness = 1.5,
                    Transparency = 0.3,
                    Parent = thumb
                })
                
                local sliding = false
                
                local function UpdateSlider(inputPos)
                    local rel = math.clamp((inputPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * rel + 0.5)
                    
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    thumb.Position = UDim2.new(rel, -7, 0.5, -7)
                    valueLabel.Text = tostring(value)
                    
                    task.spawn(callback, value)
                end
                
                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        Utility:Tween(thumb, {Size = UDim2.fromOffset(16, 16)}, 0.1)
                        UpdateSlider(input.Position.X)
                    end
                end)
                
                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                        Utility:Tween(thumb, {Size = UDim2.fromOffset(14, 14)}, 0.12)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input.Position.X)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                        Utility:Tween(thumb, {Size = UDim2.fromOffset(14, 14)}, 0.12)
                    end
                end)
                
                return {
                    Set = function(_, newValue)
                        value = math.clamp(newValue, min, max)
                        local rel = (value - min) / (max - min)
                        fill.Size = UDim2.new(rel, 0, 1, 0)
                        thumb.Position = UDim2.new(rel, -7, 0.5, -7)
                        valueLabel.Text = tostring(value)
                        task.spawn(callback, value)
                    end,
                    Get = function()
                        return value
                    end
                }
            end
            
            -- Dropdown
            function sectionData:AddDropdown(dropOptions)
                dropOptions = dropOptions or {}
                local name = dropOptions.Name or "Dropdown"
                local items = dropOptions.Items or {"Option 1"}
                local default = dropOptions.Default or items[1]
                local callback = dropOptions.Callback or function() end
                
                local selected = default
                local open = false
                
                local dropFrame = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    ClipsDescendants = false,
                    ZIndex = 5,
                    Parent = contentBox
                })
                
                local mainBtn = Utility:Create("TextButton", {
                    BackgroundColor3 = theme.Element,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 6,
                    Parent = dropFrame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = mainBtn
                })
                
                Utility:Create("UIStroke", {
                    Color = theme.Border,
                    Thickness = 1,
                    Transparency = 0.5,
                    Parent = mainBtn
                })
                
                local mainText = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -36, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = name .. "  ·  " .. selected,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = mainBtn
                })
                
                local arrow = Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(20, 20),
                    Position = UDim2.new(1, -28, 0.5, -10),
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    ZIndex = 7,
                    Parent = mainBtn
                })
                
                local listFrame = Utility:Create("Frame", {
                    BackgroundColor3 = theme.Panel,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 38),
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 10,
                    Parent = dropFrame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = listFrame
                })
                
                Utility:Create("UIStroke", {
                    Color = theme.Border,
                    Thickness = 1,
                    Transparency = 0.4,
                    Parent = listFrame
                })
                
                local listLayout = Utility:Create("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = listFrame
                })
                
                Utility:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    Parent = listFrame
                })
                
                local function ToggleDropdown()
                    open = not open
                    
                    if open then
                        listFrame.Visible = true
                        local height = #items * 28 + 14
                        Utility:Tween(listFrame, {Size = UDim2.new(1, 0, 0, height)}, 0.18)
                        Utility:Tween(arrow, {Rotation = 180}, 0.18)
                        dropFrame.Size = UDim2.new(1, 0, 0, 34 + height + 6)
                    else
                        Utility:Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.16)
                        Utility:Tween(arrow, {Rotation = 0}, 0.16)
                        task.delay(0.17, function()
                            listFrame.Visible = false
                        end)
                        dropFrame.Size = UDim2.new(1, 0, 0, 34)
                    end
                end
                
                for _, item in ipairs(items) do
                    local itemBtn = Utility:Create("TextButton", {
                        BackgroundColor3 = theme.Element,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 26),
                        Font = Enum.Font.Gotham,
                        Text = "  " .. item,
                        TextColor3 = theme.SubText,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        ZIndex = 11,
                        Parent = listFrame
                    })
                    
                    Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, 6),
                        Parent = itemBtn
                    })
                    
                    itemBtn.MouseEnter:Connect(function()
                        Utility:Tween(itemBtn, {
                            BackgroundTransparency = 0.4,
                            TextColor3 = theme.Text
                        }, 0.12)
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        Utility:Tween(itemBtn, {
                            BackgroundTransparency = 1,
                            TextColor3 = theme.SubText
                        }, 0.12)
                    end)
                    
                    itemBtn.MouseButton1Click:Connect(function()
                        selected = item
                        mainText.Text = name .. "  ·  " .. selected
                        ToggleDropdown()
                        task.spawn(callback, selected)
                    end)
                end
                
                mainBtn.MouseButton1Click:Connect(ToggleDropdown)
                mainBtn.TouchTap:Connect(ToggleDropdown)
                
                return {
                    Set = function(_, value)
                        if table.find(items, value) then
                            selected = value
                            mainText.Text = name .. "  ·  " .. selected
                            task.spawn(callback, selected)
                        end
                    end,
                    Get = function()
                        return selected
                    end
                }
            end
            
            -- Textbox
            function sectionData:AddTextbox(boxOptions)
                boxOptions = boxOptions or {}
                local name = boxOptions.Name or "Textbox"
                local placeholder = boxOptions.Placeholder or "Enter text..."
                local default = boxOptions.Default or ""
                local callback = boxOptions.Callback or function() end
                
                local boxFrame = Utility:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 54),
                    Parent = contentBox
                })
                
                Utility:Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = boxFrame
                })
                
                local input = Utility:Create("TextBox", {
                    BackgroundColor3 = theme.Element,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0, 0, 0, 22),
                    Font = Enum.Font.Gotham,
                    Text = default,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = theme.SubText,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = boxFrame
                })
                
                Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = input
                })
                
                local stroke = Utility:Create("UIStroke", {
                    Color = theme.Border,
                    Thickness = 1,
                    Transparency = 0.5,
                    Parent = input
                })
                
                Utility:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    Parent = input
                })
                
                input.Focused:Connect(function()
                    Utility:Tween(stroke, {
                        Color = theme.Accent,
                        Transparency = 0.2
                    }, 0.15)
                end)
                
                input.FocusLost:Connect(function(enter)
                    Utility:Tween(stroke, {
                        Color = theme.Border,
                        Transparency = 0.5
                    }, 0.15)
                    task.spawn(callback, input.Text)
                end)
                
                return {
                    Set = function(_, text)
                        input.Text = text
                    end,
                    Get = function()
                        return input.Text
                    end
                }
            end
            
            return sectionData
        end
        
        return tabData
    end
    
    -- Theme switcher helper
    function windowData:SetTheme(newThemeName)
        if Themes[newThemeName] then
            windowData.Theme = Themes[newThemeName]
            windowData.ThemeName = newThemeName
            -- Note: Full live theme reload would require recoloring all elements.
            -- For simplicity, theme is applied at creation time.
            -- Users can recreate the window for full theme change.
        end
    end
    
    return windowData
end

return AnimeUI