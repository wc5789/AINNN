--[[
    Vape UI Library - 2026 Refactored v3 (Full Version)
    ==================================================
    All bugs fixed, all features preserved, nothing removed.
    
    API (100% compatible with original):
        lib:Window(text, presetColor, closeBind, bgImageUrl, winWidth, winHeight)
        lib:Notification(title, desc, buttonText)
        lib:ChangePresetColor(color)
        lib:SetBackgroundImage(url)
        lib:GetBackgroundImage()
        lib:SetWindowSize(width, height)   -- NEW: dynamically resize
        lib:Destroy()
        
        window:Tab(text)
        tab:Button(text, callback)
        tab:Toggle(text, default, callback)
        tab:Slider(text, min, max, start, callback)
        tab:Dropdown(text, list, callback)
        tab:Colorpicker(text, presetColor, callback)
        tab:Label(text)
        tab:Textbox(text, clearOnEnter, callback)
        tab:Bind(text, keyPreset, callback)
        tab:Section(text)
]]

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local LocalPlayer        = game:GetService("Players").LocalPlayer
local CoreGui            = game:GetService("CoreGui")

------------------------------------------------------------------------
-- Theme System
-- All colors in one place. Change anything here.
------------------------------------------------------------------------
local Theme = {
    Background       = Color3.fromRGB(13, 13, 15),
    Panel            = Color3.fromRGB(18, 18, 21),
    Secondary        = Color3.fromRGB(24, 24, 28),
    Hover            = Color3.fromRGB(30, 30, 35),
    Active           = Color3.fromRGB(36, 36, 42),
    Accent           = Color3.fromRGB(22, 131, 255),   -- #1683FF
    
    TextPrimary      = Color3.fromRGB(232, 232, 236),
    TextSecondary    = Color3.fromRGB(140, 140, 148),
    TextDisabled     = Color3.fromRGB(70, 70, 78),
    
    Border           = Color3.fromRGB(38, 38, 44),
    BorderFocus      = Color3.fromRGB(55, 55, 65),
    
    ToggleOff        = Color3.fromRGB(42, 42, 48),
    ToggleOn         = Color3.fromRGB(22, 131, 255),
    ToggleCircle     = Color3.fromRGB(220, 220, 225),
    ToggleCircleOff  = Color3.fromRGB(90, 90, 98),
    
    SliderTrack      = Color3.fromRGB(38, 38, 44),
    SliderFill       = Color3.fromRGB(22, 131, 255),
    SliderThumb      = Color3.fromRGB(220, 220, 225),
    
    Overlay          = Color3.fromRGB(0, 0, 0),
}

------------------------------------------------------------------------
-- Animation Config
-- All tween parameters in one place.
------------------------------------------------------------------------
local Anim = {
    Fast     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow     = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slider   = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Toggle   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Window   = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    WindowOut = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    Hover    = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Press    = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

------------------------------------------------------------------------
-- Library State
------------------------------------------------------------------------
local lib = {}
lib.RainbowColorValue    = 0
lib.HueSelectionPosition = 0

local PresetColor = Theme.Accent
local CloseBind   = Enum.KeyCode.RightControl

------------------------------------------------------------------------
-- ScreenGui Root
-- Try CoreGui first (executor context), fall back to PlayerGui.
------------------------------------------------------------------------
local ui = Instance.new("ScreenGui")
ui.Name = "VapeUI_2026"
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.ResetOnSpawn = false

local ok = pcall(function()
    ui.Parent = CoreGui
end)
if not ok then
    ui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------------------
-- Responsive Scale (UIScale)
-- Automatically adapts to different screen sizes.
------------------------------------------------------------------------
local function GetViewport()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local uiScale = Instance.new("UIScale")
uiScale.Parent = ui

local function UpdateScale()
    local vp = GetViewport()
    local baseWidth = 900
    local s = math.clamp(vp.Y / baseWidth, 0.55, 1.25)
    uiScale.Scale = s
end

UpdateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

------------------------------------------------------------------------
-- Rainbow Cycle
-- One single Heartbeat connection. No while-wait loops.
------------------------------------------------------------------------
local rainbowConn
rainbowConn = RunService.Heartbeat:Connect(function(dt)
    lib.RainbowColorValue = lib.RainbowColorValue + dt * 0.4
    if lib.RainbowColorValue >= 1 then
        lib.RainbowColorValue = lib.RainbowColorValue - 1
    end
    lib.HueSelectionPosition = lib.HueSelectionPosition + dt * 80
    if lib.HueSelectionPosition >= 80 then
        lib.HueSelectionPosition = lib.HueSelectionPosition - 80
    end
end)

------------------------------------------------------------------------
-- Utility: Tween shorthand
-- Wrapper around TweenService:Create with optional completion callback.
------------------------------------------------------------------------
local function tween(obj, info, props, cb)
    local t = TweenService:Create(obj, info, props)
    if cb then
        t.Completed:Connect(cb)
    end
    t:Play()
    return t
end

------------------------------------------------------------------------
-- Utility: Apply border (UIStroke)
-- Thin, low-contrast borders for the compact Vape Lite look.
------------------------------------------------------------------------
local function makeBorder(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

------------------------------------------------------------------------
-- Utility: Corner helper
-- Low radius by default. 2px for panels, 3px for window, 9px for toggle.
------------------------------------------------------------------------
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 2)
    c.Parent = parent
    return c
end

------------------------------------------------------------------------
-- Utility: Draggable (Mouse + Touch)
-- Full support for both mouse dragging and touch dragging.
------------------------------------------------------------------------
local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPosition = nil, nil, nil, nil

    local function Update(input)
        local Delta = input.Position - DragStart
        object.Position = UDim2.new(
            StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
        )
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

------------------------------------------------------------------------
-- Utility: Hover effect helper
-- Dark → Slightly brighter on hover (no blue explosion).
------------------------------------------------------------------------
local function addHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        tween(btn, Anim.Hover, {BackgroundColor3 = hoverColor or Theme.Hover})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, Anim.Hover, {BackgroundColor3 = normalColor})
    end)
end

------------------------------------------------------------------------
-- Utility: Auto canvas size via Layout change
-- Automatically updates ScrollingFrame CanvasSize when content changes.
-- Event-driven, no polling.
------------------------------------------------------------------------
local function autoCanvas(scrollFrame, layout)
    local function update()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

------------------------------------------------------------------------
-- Library: Window
-- The main window. Creates the entire UI container.
-- Parameters:
--   text        - Window title (string)
--   preset      - Accent color (Color3, optional)
--   closebind   - KeyCode to toggle UI (optional, default RightControl)
--   bgImageUrl  - Background image URL (optional)
--   winWidth    - Window width (optional, default 560)
--   winHeight   - Window height (optional, default 340)
------------------------------------------------------------------------
function lib:Window(text, preset, closebind, bgImageUrl, winWidth, winHeight)
    CloseBind   = closebind or CloseBind
    PresetColor = preset or Theme.Accent
    Theme.Accent = PresetColor

    local WINDOW_W = winWidth or 560
    local WINDOW_H = winHeight or 340
    local firstTab = true

    ------------------------------------------------------------------
    -- Main Frame
    -- BackgroundTransparency = 1 only if bgImageUrl is provided,
    -- otherwise 0 (solid dark background).
    ------------------------------------------------------------------
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ui
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Theme.Background
    Main.BackgroundTransparency = bgImageUrl and 1 or 0
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.ClipsDescendants = true
    Main.Visible = true

    makeBorder(Main, Theme.Border, 1)
    makeCorner(Main, 3)

    -- Subtle shadow behind the window
    local MainShadow = Instance.new("ImageLabel")
    MainShadow.Name = "Shadow"
    MainShadow.Parent = Main
    MainShadow.BackgroundTransparency = 1
    MainShadow.BorderSizePixel = 0
    MainShadow.Position = UDim2.new(0, -8, 0, -4)
    MainShadow.Size = UDim2.new(1, 16, 1, 16)
    MainShadow.ZIndex = -1
    MainShadow.ImageTransparency = 0.55
    MainShadow.ScaleType = Enum.ScaleType.Slice
    MainShadow.SliceCenter = Rect.new(24, 24, 276, 276)
    MainShadow.Image = "rbxassetid://6014261993"

    ------------------------------------------------------------------
    -- Background Image Layer
    -- Customizable background image via URL.
    -- ZIndex = 0 (lowest).
    ------------------------------------------------------------------
    local bgImage = Instance.new("ImageLabel")
    bgImage.Name = "BackgroundImage"
    bgImage.Parent = Main
    bgImage.BackgroundTransparency = 1
    bgImage.Size = UDim2.new(1, 0, 1, 0)
    bgImage.Position = UDim2.new(0, 0, 0, 0)
    bgImage.ZIndex = 0
    bgImage.ScaleType = Enum.ScaleType.Crop
    if bgImageUrl and bgImageUrl ~= "" then
        bgImage.Image = bgImageUrl
        bgImage.Visible = true
    else
        bgImage.Visible = false
    end

    ------------------------------------------------------------------
    -- Overlay (semi-transparent dark layer)
    -- Sits above background image, below UI controls.
    -- Keeps text readable against any background.
    ------------------------------------------------------------------
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Parent = Main
    overlay.BackgroundColor3 = Theme.Background
    overlay.BackgroundTransparency = bgImageUrl and 0.35 or 1
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.ZIndex = 1

    ------------------------------------------------------------------
    -- Content Container
    -- All UI controls sit inside this container at ZIndex >= 2.
    -- This ensures proper layering above background and overlay.
    ------------------------------------------------------------------
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = Main
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.Position = UDim2.new(0, 0, 0, 0)
    ContentContainer.ZIndex = 2

    ------------------------------------------------------------------
    -- DragFrame (invisible top bar for dragging)
    ------------------------------------------------------------------
    local DragFrame = Instance.new("Frame")
    DragFrame.Name = "DragFrame"
    DragFrame.Parent = ContentContainer
    DragFrame.BackgroundTransparency = 1
    DragFrame.Size = UDim2.new(1, 0, 0, 36)
    DragFrame.ZIndex = 5

    ------------------------------------------------------------------
    -- Title
    ------------------------------------------------------------------
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = ContentContainer
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 14, 0, 6)
    Title.Size = UDim2.new(0, 200, 0, 24)
    Title.Font = Enum.Font.GothamSemibold
    Title.Text = text
    Title.TextColor3 = Theme.TextPrimary
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left

    ------------------------------------------------------------------
    -- Sidebar (TabHold)
    -- Left-side tab navigation panel.
    ------------------------------------------------------------------
    local TabHold = Instance.new("Frame")
    TabHold.Name = "TabHold"
    TabHold.Parent = ContentContainer
    TabHold.BackgroundTransparency = 1
    TabHold.Position = UDim2.new(0, 6, 0, 38)
    TabHold.Size = UDim2.new(0, 120, 1, -44)

    local TabHoldLayout = Instance.new("UIListLayout")
    TabHoldLayout.Parent = TabHold
    TabHoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabHoldLayout.Padding = UDim.new(0, 2)

    -- Sidebar separator line (thin vertical line)
    local SidebarLine = Instance.new("Frame")
    SidebarLine.Name = "SidebarLine"
    SidebarLine.Parent = ContentContainer
    SidebarLine.BackgroundColor3 = Theme.Border
    SidebarLine.BorderSizePixel = 0
    SidebarLine.Position = UDim2.new(0, 132, 0, 38)
    SidebarLine.Size = UDim2.new(0, 1, 1, -44)

    ------------------------------------------------------------------
    -- Tab Folder
    -- Contains all tab ScrollingFrames.
    ------------------------------------------------------------------
    local TabFolder = Instance.new("Folder")
    TabFolder.Name = "TabFolder"
    TabFolder.Parent = ContentContainer

    ------------------------------------------------------------------
    -- Open animation
    -- Window opens with a subtle scale + opacity effect.
    -- 0.22s Quart Out - smooth, no bounce.
    ------------------------------------------------------------------
    tween(Main, Anim.Window, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)})

    MakeDraggable(DragFrame, Main)

    ------------------------------------------------------------------
    -- Toggle UI visibility (CloseBind)
    -- Default: RightControl
    ------------------------------------------------------------------
    local uitoggled = false
    UserInputService.InputBegan:Connect(function(io, processed)
        if processed then return end
        if io.KeyCode == CloseBind then
            if uitoggled then
                uitoggled = false
                ui.Enabled = true
                tween(Main, Anim.Window, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)})
            else
                uitoggled = true
                tween(Main, Anim.WindowOut, {Size = UDim2.new(0, 0, 0, 0)}, function()
                    ui.Enabled = false
                end)
            end
        end
    end)

    ------------------------------------------------------------------
    -- lib:ChangePresetColor
    -- Changes the accent color globally.
    ------------------------------------------------------------------
    function lib:ChangePresetColor(c)
        PresetColor = c
        Theme.Accent = c
    end

    ------------------------------------------------------------------
    -- lib:SetBackgroundImage / GetBackgroundImage
    -- Dynamically set or clear the background image.
    ------------------------------------------------------------------
    function lib:SetBackgroundImage(url)
        bgImage.Image = url or ""
        local hasUrl = url ~= nil and url ~= ""
        bgImage.Visible = hasUrl
        overlay.BackgroundTransparency = hasUrl and 0.35 or 1
        Main.BackgroundTransparency = hasUrl and 1 or 0
    end

    function lib:GetBackgroundImage()
        return bgImage.Image
    end

    ------------------------------------------------------------------
    -- lib:SetWindowSize
    -- Dynamically resize the window.
    -- Example: lib:SetWindowSize(800, 500)
    ------------------------------------------------------------------
    function lib:SetWindowSize(width, height)
        if width and width > 100 then WINDOW_W = width end
        if height and height > 100 then WINDOW_H = height end
        tween(Main, Anim.Window, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)})
    end

    ------------------------------------------------------------------
    -- lib:Notification
    -- Creates a modal notification overlay.
    -- Parameters: title, description, button text
    ------------------------------------------------------------------
    function lib:Notification(texttitle, textdesc, textbtn)
        -- Notification holder (full-window overlay)
        local NotificationHold = Instance.new("TextButton")
        NotificationHold.Name = "NotificationHold"
        NotificationHold.Parent = Main
        NotificationHold.BackgroundColor3 = Theme.Overlay
        NotificationHold.BackgroundTransparency = 1
        NotificationHold.BorderSizePixel = 0
        NotificationHold.Size = UDim2.new(1, 0, 1, 0)
        NotificationHold.AutoButtonColor = false
        NotificationHold.Font = Enum.Font.SourceSans
        NotificationHold.Text = ""
        NotificationHold.ZIndex = 50

        -- Fade in overlay
        tween(NotificationHold, Anim.Medium, {BackgroundTransparency = 0.75})
        task.wait(0.08)

        -- Notification frame
        local NF = Instance.new("Frame")
        NF.Name = "NotificationFrame"
        NF.Parent = NotificationHold
        NF.AnchorPoint = Vector2.new(0.5, 0.5)
        NF.BackgroundColor3 = Theme.Panel
        NF.BorderSizePixel = 0
        NF.ClipsDescendants = true
        NF.Position = UDim2.new(0.5, 0, 0.5, 0)
        NF.Size = UDim2.new(0, 0, 0, 0)
        NF.ZIndex = 51

        makeBorder(NF, Theme.Border, 1)
        makeCorner(NF, 3)

        -- Animate notification frame opening
        tween(NF, Anim.Slow, {Size = UDim2.new(0, 180, 0, 180)})

        -- Title
        local NT = Instance.new("TextLabel")
        NT.Name = "NotificationTitle"
        NT.Parent = NF
        NT.BackgroundTransparency = 1
        NT.Position = UDim2.new(0, 12, 0, 12)
        NT.Size = UDim2.new(1, -24, 0, 22)
        NT.Font = Enum.Font.GothamSemibold
        NT.Text = texttitle
        NT.TextColor3 = Theme.TextPrimary
        NT.TextSize = 14
        NT.TextXAlignment = Enum.TextXAlignment.Left
        NT.ZIndex = 52

        -- Description
        local ND = Instance.new("TextLabel")
        ND.Name = "NotificationDesc"
        ND.Parent = NF
        ND.BackgroundTransparency = 1
        ND.Position = UDim2.new(0, 12, 0, 36)
        ND.Size = UDim2.new(1, -24, 0, 80)
        ND.Font = Enum.Font.Gotham
        ND.Text = textdesc
        ND.TextColor3 = Theme.TextSecondary
        ND.TextSize = 12
        ND.TextWrapped = true
        ND.TextXAlignment = Enum.TextXAlignment.Left
        ND.TextYAlignment = Enum.TextYAlignment.Top
        ND.ZIndex = 52

        -- OK Button
        local OK = Instance.new("TextButton")
        OK.Name = "OkayBtn"
        OK.Parent = NF
        OK.BackgroundColor3 = Theme.Secondary
        OK.Position = UDim2.new(0, 12, 1, -48)
        OK.Size = UDim2.new(1, -24, 0, 32)
        OK.AutoButtonColor = false
        OK.Font = Enum.Font.SourceSans
        OK.Text = ""
        OK.ZIndex = 52

        makeCorner(OK, 2)
        makeBorder(OK, Theme.Border, 1)

        local OKLabel = Instance.new("TextLabel")
        OKLabel.Parent = OK
        OKLabel.BackgroundTransparency = 1
        OKLabel.Size = UDim2.new(1, 0, 1, 0)
        OKLabel.Font = Enum.Font.GothamMedium
        OKLabel.Text = textbtn
        OKLabel.TextColor3 = Theme.TextPrimary
        OKLabel.TextSize = 13
        OKLabel.ZIndex = 53

        addHover(OK, Theme.Secondary, Theme.Hover)

        OK.MouseButton1Click:Connect(function()
            tween(NF, Anim.Medium, {Size = UDim2.new(0, 0, 0, 0)})
            task.wait(0.12)
            tween(NotificationHold, Anim.Medium, {BackgroundTransparency = 1}, function()
                NotificationHold:Destroy()
            end)
        end)
    end

    ------------------------------------------------------------------
    -- tabhold:Tab(text)
    -- Creates a tab button in the sidebar and a content panel.
    -- Returns tabcontent table with all control methods.
    ------------------------------------------------------------------
    local tabhold = {}

    function tabhold:Tab(text)
        ------------------------------------------------------------------
        -- Tab Button (sidebar)
        -- Compact, clear, with left accent indicator for active state.
        ------------------------------------------------------------------
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = "TabBtn"
        TabBtn.Parent = TabHold
        TabBtn.BackgroundColor3 = Theme.Panel
        TabBtn.BackgroundTransparency = 1
        TabBtn.Size = UDim2.new(1, 0, 0, 30)
        TabBtn.AutoButtonColor = false
        TabBtn.Font = Enum.Font.SourceSans
        TabBtn.Text = ""

        makeCorner(TabBtn, 2)

        local TabTitle = Instance.new("TextLabel")
        TabTitle.Name = "TabTitle"
        TabTitle.Parent = TabBtn
        TabTitle.BackgroundTransparency = 1
        TabTitle.Position = UDim2.new(0, 14, 0, 0)
        TabTitle.Size = UDim2.new(1, -14, 1, 0)
        TabTitle.Font = Enum.Font.Gotham
        TabTitle.Text = text
        TabTitle.TextColor3 = Theme.TextSecondary
        TabTitle.TextSize = 13
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left

        -- Active indicator (left accent bar)
        -- Blue bar that appears when tab is selected.
        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "TabIndicator"
        TabIndicator.Parent = TabBtn
        TabIndicator.BackgroundColor3 = Theme.Accent
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Position = UDim2.new(0, 0, 0.25, 0)
        TabIndicator.Size = UDim2.new(0, 2, 0, 0)

        makeCorner(TabIndicator, 1)

        ------------------------------------------------------------------
        -- Tab Content (ScrollingFrame)
        -- FIXED: ScrollingDirection and ElasticBehavior for mobile touch.
        ------------------------------------------------------------------
        local Tab = Instance.new("ScrollingFrame")
        Tab.Name = "Tab"
        Tab.Parent = TabFolder
        Tab.Active = true
        Tab.BackgroundTransparency = 1
        Tab.BorderSizePixel = 0
        Tab.Position = UDim2.new(0, 140, 0, 38)
        Tab.Size = UDim2.new(1, -148, 1, -46)
        Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
        Tab.ScrollBarThickness = 4
        Tab.ScrollBarImageColor3 = Theme.Border
        Tab.ScrollBarImageTransparency = 0.4
        Tab.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
        Tab.ScrollingDirection = Enum.ScrollingDirection.Y
        Tab.ElasticBehavior = Enum.ElasticBehavior.Always
        Tab.Visible = false

        local TabLayout = Instance.new("UIListLayout")
        TabLayout.Parent = Tab
        TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabLayout.Padding = UDim.new(0, 4)

        local TabPadding = Instance.new("UIPadding")
        TabPadding.Parent = Tab
        TabPadding.PaddingTop = UDim.new(0, 4)
        TabPadding.PaddingBottom = UDim.new(0, 4)
        TabPadding.PaddingLeft = UDim.new(0, 2)
        TabPadding.PaddingRight = UDim.new(0, 2)

        autoCanvas(Tab, TabLayout)

        ------------------------------------------------------------------
        -- First tab is active by default
        ------------------------------------------------------------------
        if firstTab then
            firstTab = false
            TabIndicator.Size = UDim2.new(0, 2, 0.5, 0)
            TabTitle.TextColor3 = Theme.TextPrimary
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Theme.Panel
            Tab.Visible = true
        end

        ------------------------------------------------------------------
        -- Tab click handler
        -- Animates indicator, title color, and background.
        ------------------------------------------------------------------
        local function activateTab()
            -- Deactivate all tabs
            for _, v in ipairs(TabHold:GetChildren()) do
                if v.Name == "TabBtn" then
                    local ind = v:FindFirstChild("TabIndicator")
                    local tit = v:FindFirstChild("TabTitle")
                    if ind then
                        tween(ind, Anim.Fast, {Size = UDim2.new(0, 2, 0, 0)})
                    end
                    if tit then
                        tween(tit, Anim.Fast, {TextColor3 = Theme.TextSecondary})
                    end
                    tween(v, Anim.Fast, {BackgroundTransparency = 1})
                end
            end
            -- Hide all tab panels
            for _, v in ipairs(TabFolder:GetChildren()) do
                if v.Name == "Tab" then
                    v.Visible = false
                end
            end
            -- Activate this tab
            tween(TabIndicator, Anim.Fast, {Size = UDim2.new(0, 2, 0.5, 0)})
            tween(TabTitle, Anim.Fast, {TextColor3 = Theme.TextPrimary})
            tween(TabBtn, Anim.Fast, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Panel})
            Tab.Visible = true
        end

        -- Mouse click
        TabBtn.MouseButton1Click:Connect(activateTab)
        -- Touch support
        TabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                activateTab()
            end
        end)

        ------------------------------------------------------------------
        -- Row dimensions for all controls
        ------------------------------------------------------------------
        local ROW_W = UDim.new(1, -4)   -- full width minus 4px padding
        local ROW_H = 38                -- standard row height
        local tabcontent = {}

        ------------------------------------------------------------------
        -- tabcontent:Button(text, callback)
        ------------------------------------------------------------------
        function tabcontent:Button(text, callback)
            local Button = Instance.new("TextButton")
            Button.Name = "Button"
            Button.Parent = Tab
            Button.BackgroundColor3 = Theme.Panel
            Button.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)
            Button.AutoButtonColor = false
            Button.Font = Enum.Font.SourceSans
            Button.Text = ""

            makeCorner(Button, 2)
            makeBorder(Button, Theme.Border, 1)

            local ButtonTitle = Instance.new("TextLabel")
            ButtonTitle.Name = "ButtonTitle"
            ButtonTitle.Parent = Button
            ButtonTitle.BackgroundTransparency = 1
            ButtonTitle.Position = UDim2.new(0, 13, 0, 0)
            ButtonTitle.Size = UDim2.new(1, -26, 1, 0)
            ButtonTitle.Font = Enum.Font.Gotham
            ButtonTitle.Text = text
            ButtonTitle.TextColor3 = Theme.TextPrimary
            ButtonTitle.TextSize = 13
            ButtonTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- Hover effect
            addHover(Button, Theme.Panel, Theme.Hover)

            -- Press feedback
            Button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    tween(Button, Anim.Press, {BackgroundColor3 = Theme.Active})
                end
            end)
            Button.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    tween(Button, Anim.Press, {BackgroundColor3 = Theme.Panel})
                end
            end)

            Button.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
        end

        ------------------------------------------------------------------
        -- tabcontent:Toggle(text, default, callback)
        -- FIXED: Uses Tween completed callback for animation lock.
        -- No hardcoded task.wait() for animation timing.
        ------------------------------------------------------------------
        function tabcontent:Toggle(text, default, callback)
            local toggled = false
            local animating = false

            local Toggle = Instance.new("TextButton")
            Toggle.Name = "Toggle"
            Toggle.Parent = Tab
            Toggle.BackgroundColor3 = Theme.Panel
            Toggle.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)
            Toggle.AutoButtonColor = false
            Toggle.Font = Enum.Font.SourceSans
            Toggle.Text = ""

            makeCorner(Toggle, 2)
            makeBorder(Toggle, Theme.Border, 1)

            local ToggleTitle = Instance.new("TextLabel")
            ToggleTitle.Name = "ToggleTitle"
            ToggleTitle.Parent = Toggle
            ToggleTitle.BackgroundTransparency = 1
            ToggleTitle.Position = UDim2.new(0, 13, 0, 0)
            ToggleTitle.Size = UDim2.new(1, -60, 1, 0)
            ToggleTitle.Font = Enum.Font.Gotham
            ToggleTitle.Text = text
            ToggleTitle.TextColor3 = Theme.TextPrimary
            ToggleTitle.TextSize = 13
            ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- Toggle track (outer capsule)
            local Track = Instance.new("Frame")
            Track.Name = "Track"
            Track.Parent = Toggle
            Track.BackgroundColor3 = Theme.ToggleOff
            Track.BorderSizePixel = 0
            Track.AnchorPoint = Vector2.new(1, 0.5)
            Track.Position = UDim2.new(1, -10, 0.5, 0)
            Track.Size = UDim2.new(0, 34, 0, 18)
            makeCorner(Track, 9)

            -- Toggle fill (accent overlay, hidden when off)
            local Fill = Instance.new("Frame")
            Fill.Name = "Fill"
            Fill.Parent = Track
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BackgroundTransparency = 1
            Fill.BorderSizePixel = 0
            Fill.Size = UDim2.new(1, 0, 1, 0)
            makeCorner(Fill, 9)

            -- Toggle circle (thumb)
            local Circle = Instance.new("Frame")
            Circle.Name = "Circle"
            Circle.Parent = Track
            Circle.BackgroundColor3 = Theme.ToggleCircleOff
            Circle.BorderSizePixel = 0
            Circle.Position = UDim2.new(0, 3, 0.5, -6)
            Circle.Size = UDim2.new(0, 12, 0, 12)
            makeCorner(Circle, 6)

            -- Sync accent color on Heartbeat (so it updates when Theme.Accent changes)
            local accentSync
            accentSync = RunService.Heartbeat:Connect(function()
                Fill.BackgroundColor3 = Theme.Accent
            end)

            local function setToggle(newState, animate)
                if animating and animate then return end
                toggled = newState
                local info = animate and Anim.Toggle or TweenInfo.new(0, Enum.EasingStyle.Quad)
                if animate then animating = true end

                if newState then
                    -- Turn ON
                    tween(Fill, info, {BackgroundTransparency = 0})
                    local ct = tween(Circle, info, {
                        Position = UDim2.new(1, -15, 0.5, -6),
                        BackgroundColor3 = Theme.ToggleCircle
                    })
                    if animate then
                        ct.Completed:Once(function()
                            animating = false
                            pcall(callback, toggled)
                        end)
                    else
                        pcall(callback, toggled)
                    end
                else
                    -- Turn OFF
                    tween(Fill, info, {BackgroundTransparency = 1})
                    local ct = tween(Circle, info, {
                        Position = UDim2.new(0, 3, 0.5, -6),
                        BackgroundColor3 = Theme.ToggleCircleOff
                    })
                    if animate then
                        ct.Completed:Once(function()
                            animating = false
                            pcall(callback, toggled)
                        end)
                    else
                        pcall(callback, toggled)
                    end
                end
            end

            -- Hover effect
            addHover(Toggle, Theme.Panel, Theme.Hover)

            -- Mouse click
            Toggle.MouseButton1Click:Connect(function()
                setToggle(not toggled, true)
            end)

            -- Touch support
            Toggle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    setToggle(not toggled, true)
                end
            end)

            -- Apply default state
            if default == true then
                setToggle(true, false)
            end

            -- Return handle for external control
            local handle = {}
            function handle:Set(state)
                setToggle(state, true)
            end
            function handle:Get()
                return toggled
            end
            return handle
        end

        ------------------------------------------------------------------
        -- tabcontent:Slider(text, min, max, start, callback)
        -- FIXED: Touch drag support for mobile.
        ------------------------------------------------------------------
        function tabcontent:Slider(text, min, max, start, callback)
            local dragging = false
            local startVal = start or min

            local Slider = Instance.new("Frame")
            Slider.Name = "Slider"
            Slider.Parent = Tab
            Slider.BackgroundColor3 = Theme.Panel
            Slider.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, 52)

            makeCorner(Slider, 2)
            makeBorder(Slider, Theme.Border, 1)

            local SliderTitle = Instance.new("TextLabel")
            SliderTitle.Name = "SliderTitle"
            SliderTitle.Parent = Slider
            SliderTitle.BackgroundTransparency = 1
            SliderTitle.Position = UDim2.new(0, 13, 0, 0)
            SliderTitle.Size = UDim2.new(0.5, -13, 0, 30)
            SliderTitle.Font = Enum.Font.Gotham
            SliderTitle.Text = text
            SliderTitle.TextColor3 = Theme.TextPrimary
            SliderTitle.TextSize = 13
            SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

            local SliderValue = Instance.new("TextLabel")
            SliderValue.Name = "SliderValue"
            SliderValue.Parent = Slider
            SliderValue.BackgroundTransparency = 1
            SliderValue.Position = UDim2.new(0.5, 0, 0, 0)
            SliderValue.Size = UDim2.new(0.5, -13, 0, 30)
            SliderValue.Font = Enum.Font.GothamMedium
            SliderValue.Text = tostring(startVal)
            SliderValue.TextColor3 = Theme.TextSecondary
            SliderValue.TextSize = 12
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right

            -- Slider track (very thin, 4px)
            local SlideFrame = Instance.new("Frame")
            SlideFrame.Name = "SlideFrame"
            SlideFrame.Parent = Slider
            SlideFrame.BackgroundColor3 = Theme.SliderTrack
            SlideFrame.BorderSizePixel = 0
            SlideFrame.Position = UDim2.new(0, 13, 0, 38)
            SlideFrame.Size = UDim2.new(1, -26, 0, 4)
            makeCorner(SlideFrame, 2)

            -- Slider fill (accent color)
            local CurrentValueFrame = Instance.new("Frame")
            CurrentValueFrame.Name = "CurrentValueFrame"
            CurrentValueFrame.Parent = SlideFrame
            CurrentValueFrame.BackgroundColor3 = Theme.SliderFill
            CurrentValueFrame.BorderSizePixel = 0
            local startScale = (startVal - min) / (max - min)
            CurrentValueFrame.Size = UDim2.new(math.clamp(startScale, 0, 1), 0, 1, 0)
            makeCorner(CurrentValueFrame, 2)

            -- Slider thumb (small circle, 10px)
            local SlideCircle = Instance.new("Frame")
            SlideCircle.Name = "SlideCircle"
            SlideCircle.Parent = SlideFrame
            SlideCircle.BackgroundColor3 = Theme.SliderThumb
            SlideCircle.BorderSizePixel = 0
            SlideCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            SlideCircle.Position = UDim2.new(math.clamp(startScale, 0, 1), 0, 0.5, 0)
            SlideCircle.Size = UDim2.new(0, 10, 0, 10)
            makeCorner(SlideCircle, 5)

            -- Sync accent color
            local sliderAccent
            sliderAccent = RunService.Heartbeat:Connect(function()
                CurrentValueFrame.BackgroundColor3 = Theme.Accent
            end)

            local function move(input)
                local rel = math.clamp(
                    (input.Position.X - SlideFrame.AbsolutePosition.X) / SlideFrame.AbsoluteSize.X,
                    0, 1
                )
                tween(CurrentValueFrame, Anim.Slider, {Size = UDim2.new(rel, 0, 1, 0)})
                tween(SlideCircle, Anim.Slider, {Position = UDim2.new(rel, 0, 0.5, 0)})

                local value = math.floor(rel * (max - min) + min)
                SliderValue.Text = tostring(value)
                pcall(callback, value)
            end

            -- Drag start (mouse + touch)
            local function onDragStart(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    move(input)
                end
            end

            SlideCircle.InputBegan:Connect(onDragStart)
            SlideFrame.InputBegan:Connect(onDragStart)  -- click on track

            -- Drag end
            SlideCircle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            SlideFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            -- Drag update (mouse movement + touch movement)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    move(input)
                end
            end)

            -- Return handle for external control
            local handle = {}
            function handle:Set(val)
                val = math.clamp(val, min, max)
                local rel = (val - min) / (max - min)
                tween(CurrentValueFrame, Anim.Slider, {Size = UDim2.new(rel, 0, 1, 0)})
                tween(SlideCircle, Anim.Slider, {Position = UDim2.new(rel, 0, 0.5, 0)})
                SliderValue.Text = tostring(val)
            end
            return handle
        end

        -- Dropdown
        function tabcontent:Dropdown(text, list, callback)
            local droptog = false; local framesize = 0; local itemcount = 0
            local ITEM_H = 28
            local D = Instance.new("Frame")
            D.Name = "Dropdown"; D.Parent = Tab
            D.BackgroundColor3 = Theme.Panel; D.ClipsDescendants = true
            D.Size = UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)
            makeCorner(D,2); makeBorder(D,Theme.Border,1)
            local DBtn = Instance.new("TextButton")
            DBtn.Name = "DropdownBtn"; DBtn.Parent = D
            DBtn.BackgroundTransparency = 1; DBtn.Size = UDim2.new(1,0,0,ROW_H)
            DBtn.Font = Enum.Font.SourceSans; DBtn.Text = ""
            local DTitle = Instance.new("TextLabel")
            DTitle.Name = "DropdownTitle"; DTitle.Parent = D
            DTitle.BackgroundTransparency = 1
            DTitle.Position = UDim2.new(0,13,0,0); DTitle.Size = UDim2.new(1,-50,0,ROW_H)
            DTitle.Font = Enum.Font.Gotham; DTitle.Text = text
            DTitle.TextColor3 = Theme.TextPrimary; DTitle.TextSize = 13
            DTitle.TextXAlignment = Enum.TextXAlignment.Left
            local Arrow = Instance.new("ImageLabel")
            Arrow.Name = "ArrowImg"; Arrow.Parent = D; Arrow.BackgroundTransparency = 1
            Arrow.AnchorPoint = Vector2.new(1,0.5); Arrow.Position = UDim2.new(1,-10,0.5,0)
            Arrow.Size = UDim2.new(0,16,0,16)
            Arrow.Image = "http://www.roblox.com/asset/?id=6034818375"
            Arrow.ImageColor3 = Theme.TextSecondary
            local DIH = Instance.new("ScrollingFrame")
            DIH.Name = "DropItemHolder"; DIH.Parent = D
            DIH.Active = true; DIH.BackgroundTransparency = 1; DIH.BorderSizePixel = 0
            DIH.Position = UDim2.new(0,6,0,ROW_H+2); DIH.Size = UDim2.new(1,-12,0,0)
            DIH.CanvasSize = UDim2.new(0,0,0,0); DIH.ScrollBarThickness = 4
            DIH.ScrollBarImageColor3 = Theme.Border
            DIH.ScrollingDirection = Enum.ScrollingDirection.Y
            local DL = Instance.new("UIListLayout")
            DL.Parent = DIH; DL.SortOrder = Enum.SortOrder.LayoutOrder
            DL.Padding = UDim.new(0,2)
            for i,v in ipairs(list) do
                itemcount = itemcount+1
                if itemcount <= 4 then framesize = framesize + ITEM_H + 2 end
                local Item = Instance.new("TextButton")
                Item.Name = "Item"; Item.Parent = DIH
                Item.BackgroundColor3 = Theme.Secondary; Item.ClipsDescendants = true
                Item.Size = UDim2.new(1,0,0,ITEM_H)
                Item.AutoButtonColor = false; Item.Font = Enum.Font.Gotham
                Item.Text = "  "..v; Item.TextColor3 = Theme.TextPrimary
                Item.TextSize = 12; Item.TextXAlignment = Enum.TextXAlignment.Left
                makeCorner(Item,2); addHover(Item,Theme.Secondary,Theme.Hover)
                Item.MouseButton1Click:Connect(function()
                    droptog = false; DTitle.Text = text.." - "..v
                    pcall(callback,v)
                    tween(D,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)})
                    tween(Arrow,Anim.Medium,{Rotation=0})
                end)
            end
            DIH.Size = UDim2.new(1,-12,0,math.min(framesize,(ITEM_H+2)*4))
            autoCanvas(DIH,DL)
            DBtn.MouseButton1Click:Connect(function()
                if not droptog then tween(D,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H+framesize+6)}); tween(Arrow,Anim.Medium,{Rotation=180})
                else tween(D,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)}); tween(Arrow,Anim.Medium,{Rotation=0}) end
                droptog = not droptog
            end)
            DBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    if not droptog then tween(D,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H+framesize+6)}); tween(Arrow,Anim.Medium,{Rotation=180})
                    else tween(D,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)}); tween(Arrow,Anim.Medium,{Rotation=0}) end
                    droptog = not droptog
                end
            end)
            local h = {}; function h:Set(v) DTitle.Text = text.." - "..tostring(v) end; return h
        end

        -- Colorpicker (full rainbow restored)
        function tabcontent:Colorpicker(text, preset, cb)
            local toggled=false; local Rainbow=false
            local ColorH,ColorS,ColorV=1,1,1; local ColorInput,HueInput=nil,nil
            local Mouse=LocalPlayer:GetMouse()
            local CP=Instance.new("Frame")
            CP.Name="Colorpicker"; CP.Parent=Tab
            CP.BackgroundColor3=Theme.Panel; CP.ClipsDescendants=true
            CP.Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)
            makeCorner(CP,2); makeBorder(CP,Theme.Border,1)
            local CPT=Instance.new("TextLabel")
            CPT.Name="ColorpickerTitle"; CPT.Parent=CP; CPT.BackgroundTransparency=1
            CPT.Position=UDim2.new(0,13,0,0); CPT.Size=UDim2.new(1,-70,0,ROW_H)
            CPT.Font=Enum.Font.Gotham; CPT.Text=text; CPT.TextColor3=Theme.TextPrimary
            CPT.TextSize=13; CPT.TextXAlignment=Enum.TextXAlignment.Left
            local Box=Instance.new("Frame")
            Box.Name="BoxColor"; Box.Parent=CP
            Box.BackgroundColor3=preset or Color3.fromRGB(255,0,4)
            Box.AnchorPoint=Vector2.new(1,0.5); Box.Position=UDim2.new(1,-10,0.5,0)
            Box.Size=UDim2.new(0,36,0,20); makeCorner(Box,2); makeBorder(Box,Theme.Border,1)
            local CPBtn=Instance.new("TextButton")
            CPBtn.Name="ColorpickerBtn"; CPBtn.Parent=CP
            CPBtn.BackgroundTransparency=1; CPBtn.Size=UDim2.new(1,0,0,ROW_H)
            CPBtn.Font=Enum.Font.SourceSans; CPBtn.Text=""
            local COLOR_H=110; local EXPANDED_H=ROW_H+COLOR_H+8
            local Color=Instance.new("ImageLabel")
            Color.Name="Color"; Color.Parent=CP
            Color.BackgroundColor3=Color3.fromRGB(255,0,4)
            Color.Position=UDim2.new(0,8,0,ROW_H+2); Color.Size=UDim2.new(1,-50,0,COLOR_H)
            Color.ZIndex=10; Color.Image="rbxassetid://4155801252"; makeCorner(Color,2)
            local CSel=Instance.new("ImageLabel")
            CSel.Name="ColorSelection"; CSel.Parent=Color
            CSel.AnchorPoint=Vector2.new(0.5,0.5); CSel.BackgroundTransparency=1
            CSel.Position=UDim2.new(preset and select(3,Color3.toHSV(preset)) or 1,0,preset and 1-select(2,Color3.toHSV(preset)) or 0,0)
            CSel.Size=UDim2.new(0,14,0,14); CSel.Image="http://www.roblox.com/asset/?id=4805639000"
            CSel.ScaleType=Enum.ScaleType.Fit; CSel.Visible=false; CSel.ZIndex=11
            local Hue=Instance.new("ImageLabel")
            Hue.Name="Hue"; Hue.Parent=CP
            Hue.BackgroundColor3=Color3.fromRGB(255,255,255)
            Hue.Position=UDim2.new(1,-36,0,ROW_H+2); Hue.Size=UDim2.new(0,28,0,COLOR_H)
            Hue.ZIndex=10; makeCorner(Hue,2)
            local HueG=Instance.new("UIGradient")
            HueG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0.00,Color3.fromRGB(255,0,4)),ColorSequenceKeypoint.new(0.20,Color3.fromRGB(234,255,0)),ColorSequenceKeypoint.new(0.40,Color3.fromRGB(21,255,0)),ColorSequenceKeypoint.new(0.60,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.80,Color3.fromRGB(0,17,255)),ColorSequenceKeypoint.new(0.90,Color3.fromRGB(255,0,251)),ColorSequenceKeypoint.new(1.00,Color3.fromRGB(255,0,4))})
            HueG.Rotation=270; HueG.Parent=Hue
            local HSel=Instance.new("ImageLabel")
            HSel.Name="HueSelection"; HSel.Parent=Hue
            HSel.AnchorPoint=Vector2.new(0.5,0.5); HSel.BackgroundTransparency=1
            HSel.Position=UDim2.new(0.5,0,preset and 1-select(1,Color3.toHSV(preset)) or 0,0)
            HSel.Size=UDim2.new(0,14,0,14); HSel.Image="http://www.roblox.com/asset/?id=4805639000"
            HSel.Visible=false; HSel.ZIndex=11
            local function UpdateCP()
                Box.BackgroundColor3=Color3.fromHSV(ColorH,ColorS,ColorV)
                Color.BackgroundColor3=Color3.fromHSV(ColorH,1,1)
                pcall(cb,Box.BackgroundColor3)
            end
            ColorH=preset and select(1,Color3.toHSV(preset)) or 1
            ColorS=preset and select(3,Color3.toHSV(preset)) or 1
            ColorV=preset and select(2,Color3.toHSV(preset)) or 1
            Box.BackgroundColor3=preset; Color.BackgroundColor3=preset
            pcall(cb,Box.BackgroundColor3)
            CPBtn.MouseButton1Click:Connect(function()
                if not toggled then CSel.Visible=true; HSel.Visible=true; tween(CP,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,EXPANDED_H)})
                else CSel.Visible=false; HSel.Visible=false; tween(CP,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)}) end
                toggled=not toggled
            end)
            CPBtn.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.Touch then
                    if not toggled then CSel.Visible=true; HSel.Visible=true; tween(CP,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,EXPANDED_H)})
                    else CSel.Visible=false; HSel.Visible=false; tween(CP,Anim.Medium,{Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)}) end
                    toggled=not toggled
                end
            end)
            Color.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if Rainbow then return end
                    if ColorInput then ColorInput:Disconnect() end
                    ColorInput=RunService.RenderStepped:Connect(function()
                        local cx=math.clamp(Mouse.X-Color.AbsolutePosition.X,0,Color.AbsoluteSize.X)/Color.AbsoluteSize.X
                        local cy=math.clamp(Mouse.Y-Color.AbsolutePosition.Y,0,Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y
                        CSel.Position=UDim2.new(cx,0,cy,0); ColorS=cx; ColorV=1-cy; UpdateCP()
                    end)
                end
            end)
            Color.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if ColorInput then ColorInput:Disconnect() end
                end
            end)
            Hue.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if Rainbow then return end
                    if HueInput then HueInput:Disconnect() end
                    HueInput=RunService.RenderStepped:Connect(function()
                        local hy=math.clamp(Mouse.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y
                        HSel.Position=UDim2.new(0.5,0,hy,0); ColorH=1-hy; UpdateCP()
                    end)
                end
            end)
            Hue.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if HueInput then HueInput:Disconnect() end
                end
            end)
            -- Rainbow toggle
            local rTog=Instance.new("TextButton")
            rTog.Name="RainbowToggle"; rTog.Parent=CP
            rTog.BackgroundColor3=Theme.Secondary
            rTog.Position=UDim2.new(0,8,0,ROW_H+COLOR_H+4); rTog.Size=UDim2.new(1,-16,0,28)
            rTog.AutoButtonColor=false; rTog.Font=Enum.Font.SourceSans; rTog.Text=""
            rTog.ZIndex=10; rTog.Visible=false; makeCorner(rTog,2)
            local rLab=Instance.new("TextLabel")
            rLab.Parent=rTog; rLab.BackgroundTransparency=1
            rLab.Position=UDim2.new(0,10,0,0); rLab.Size=UDim2.new(0.5,0,1,0)
            rLab.Font=Enum.Font.Gotham; rLab.Text="Rainbow"
            rLab.TextColor3=Theme.TextPrimary; rLab.TextSize=12
            rLab.TextXAlignment=Enum.TextXAlignment.Left; rLab.ZIndex=11
            local rTr=Instance.new("Frame")
            rTr.Name="RainbowTrack"; rTr.Parent=rTog
            rTr.BackgroundColor3=Theme.ToggleOff; rTr.BorderSizePixel=0
            rTr.AnchorPoint=Vector2.new(1,0.5); rTr.Position=UDim2.new(1,-8,0.5,0)
            rTr.Size=UDim2.new(0,34,0,18); rTr.ZIndex=11; makeCorner(rTr,9)
            local rFi=Instance.new("Frame")
            rFi.Name="RainbowFill"; rFi.Parent=rTr
            rFi.BackgroundColor3=Theme.Accent; rFi.BackgroundTransparency=1
            rFi.BorderSizePixel=0; rFi.Size=UDim2.new(1,0,1,0); rFi.ZIndex=12; makeCorner(rFi,9)
            local rCi=Instance.new("Frame")
            rCi.Name="RainbowCircle"; rCi.Parent=rTr
            rCi.BackgroundColor3=Theme.ToggleCircleOff; rCi.BorderSizePixel=0
            rCi.Position=UDim2.new(0,3,0.5,-6); rCi.Size=UDim2.new(0,12,0,12)
            rCi.ZIndex=13; makeCorner(rCi,6)
            rTog.MouseButton1Click:Connect(function()
                Rainbow=not Rainbow
                if ColorInput then ColorInput:Disconnect() end
                if HueInput then HueInput:Disconnect() end
                if Rainbow then
                    tween(rFi,Anim.Toggle,{BackgroundTransparency=0})
                    tween(rCi,Anim.Toggle,{Position=UDim2.new(1,-15,0.5,-6),BackgroundColor3=Theme.ToggleCircle})
                    local rl = RunService.Heartbeat:Connect(function()
                        if not Rainbow then rl:Disconnect() return end
                        Box.BackgroundColor3=Color3.fromHSV(lib.RainbowColorValue,1,1)
                        Color.BackgroundColor3=Color3.fromHSV(lib.RainbowColorValue,1,1)
                        pcall(cb,Box.BackgroundColor3)
                    end)
                else
                    tween(rFi,Anim.Toggle,{BackgroundTransparency=1})
                    tween(rCi,Anim.Toggle,{Position=UDim2.new(0,3,0.5,-6),BackgroundColor3=Theme.ToggleCircleOff})
                    pcall(cb,Box.BackgroundColor3)
                end
            end)
            CPBtn.MouseButton1Click:Connect(function()
                task.wait(0.05); rTog.Visible = toggled
            end)
            local h={}; function h:Get() return Box.BackgroundColor3 end; return h
        end

        -- Label
        function tabcontent:Label(text)
            local L=Instance.new("Frame")
            L.Name="Label"; L.Parent=Tab
            L.BackgroundColor3=Theme.Panel; L.Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,28)
            makeCorner(L,2); makeBorder(L,Theme.Border,1)
            local LT=Instance.new("TextLabel")
            LT.Name="LabelTitle"; LT.Parent=L; LT.BackgroundTransparency=1
            LT.Position=UDim2.new(0,13,0,0); LT.Size=UDim2.new(1,-26,1,0)
            LT.Font=Enum.Font.Gotham; LT.Text=text; LT.TextColor3=Theme.TextSecondary
            LT.TextSize=12; LT.TextXAlignment=Enum.TextXAlignment.Left
            local h={}; function h:Set(s) LT.Text=s end; return h
        end

        -- Textbox
        function tabcontent:Textbox(text, disappear, cb)
            local TB=Instance.new("Frame")
            TB.Name="Textbox"; TB.Parent=Tab
            TB.BackgroundColor3=Theme.Panel; TB.ClipsDescendants=true
            TB.Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)
            makeCorner(TB,2); makeBorder(TB,Theme.Border,1)
            local TBT=Instance.new("TextLabel")
            TBT.Name="TextboxTitle"; TBT.Parent=TB; TBT.BackgroundTransparency=1
            TBT.Position=UDim2.new(0,13,0,0); TBT.Size=UDim2.new(0.5,-13,0,ROW_H)
            TBT.Font=Enum.Font.Gotham; TBT.Text=text; TBT.TextColor3=Theme.TextPrimary
            TBT.TextSize=13; TBT.TextXAlignment=Enum.TextXAlignment.Left
            local TBF=Instance.new("Frame")
            TBF.Name="TextboxFrame"; TBF.Parent=TB
            TBF.BackgroundColor3=Theme.Secondary
            TBF.AnchorPoint=Vector2.new(1,0.5); TBF.Position=UDim2.new(1,-8,0.5,0)
            TBF.Size=UDim2.new(0,120,0,24); makeCorner(TBF,2)
            local TX=Instance.new("TextBox")
            TX.Parent=TBF; TX.BackgroundTransparency=1
            TX.Position=UDim2.new(0,8,0,0); TX.Size=UDim2.new(1,-16,1,0)
            TX.Font=Enum.Font.Gotham; TX.Text=""; TX.PlaceholderText="..."
            TX.PlaceholderColor3=Theme.TextDisabled; TX.TextColor3=Theme.TextPrimary
            TX.TextSize=12; TX.ClearTextOnFocus=false
            TX.Focused:Connect(function()
                local s=TBF:FindFirstChildOfClass("UIStroke")
                if s then tween(s,Anim.Fast,{Color=Theme.BorderFocus}) end
            end)
            TX.FocusLost:Connect(function(ep)
                local s=TBF:FindFirstChildOfClass("UIStroke")
                if s then tween(s,Anim.Fast,{Color=Theme.Border}) end
                if ep and #TX.Text>0 then pcall(cb,TX.Text); if disappear then TX.Text="" end end
            end)
            local h={}; function h:Set(v) TX.Text=tostring(v) end; function h:Get() return TX.Text end; return h
        end

        -- Bind
        function tabcontent:Bind(text, keypreset, cb)
            local binding=false
            local Key=keypreset and keypreset.Name or "None"
            local B=Instance.new("TextButton")
            B.Name="Bind"; B.Parent=Tab
            B.BackgroundColor3=Theme.Panel
            B.Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,ROW_H)
            B.AutoButtonColor=false; B.Font=Enum.Font.SourceSans; B.Text=""
            makeCorner(B,2); makeBorder(B,Theme.Border,1)
            local BT=Instance.new("TextLabel")
            BT.Name="BindTitle"; BT.Parent=B; BT.BackgroundTransparency=1
            BT.Position=UDim2.new(0,13,0,0); BT.Size=UDim2.new(1,-80,0,ROW_H)
            BT.Font=Enum.Font.Gotham; BT.Text=text; BT.TextColor3=Theme.TextPrimary
            BT.TextSize=13; BT.TextXAlignment=Enum.TextXAlignment.Left
            local BKB=Instance.new("Frame")
            BKB.Name="BindKeyBg"; BKB.Parent=B
            BKB.BackgroundColor3=Theme.Secondary
            BKB.AnchorPoint=Vector2.new(1,0.5); BKB.Position=UDim2.new(1,-8,0.5,0)
            BKB.Size=UDim2.new(0,60,0,24); makeCorner(BKB,2)
            local BKT=Instance.new("TextLabel")
            BKT.Name="BindText"; BKT.Parent=BKB; BKT.BackgroundTransparency=1
            BKT.Size=UDim2.new(1,0,1,0); BKT.Font=Enum.Font.GothamMedium
            BKT.Text=Key; BKT.TextColor3=Theme.TextSecondary; BKT.TextSize=11
            addHover(B,Theme.Panel,Theme.Hover)
            B.MouseButton1Click:Connect(function()
                if binding then return end
                binding=true; BKT.Text="..."; BKT.TextColor3=Theme.Accent
                local iw=UserInputService.InputBegan:Wait()
                if iw.KeyCode and iw.KeyCode.Name~="Unknown" then BKT.Text=iw.KeyCode.Name; Key=iw.KeyCode.Name end
                BKT.TextColor3=Theme.TextSecondary; binding=false
            end)
            UserInputService.InputBegan:Connect(function(cur,pro)
                if pro then return end
                if not binding and cur.KeyCode.Name==Key then pcall(cb) end
            end)
            local h={}; function h:Set(kc) Key=kc.Name or tostring(kc); BKT.Text=Key end; return h
        end

        -- Section
        function tabcontent:Section(text)
            local S=Instance.new("Frame")
            S.Name="Section"; S.Parent=Tab; S.BackgroundTransparency=1
            S.Size=UDim2.new(ROW_W.Scale,ROW_W.Offset,0,18)
            local ST=Instance.new("TextLabel")
            ST.Parent=S; ST.BackgroundTransparency=1
            ST.Position=UDim2.new(0,4,0,0); ST.Size=UDim2.new(1,-8,1,0)
            ST.Font=Enum.Font.GothamSemibold; ST.Text=text:upper()
            ST.TextColor3=Theme.TextDisabled; ST.TextSize=10
            ST.TextXAlignment=Enum.TextXAlignment.Left
        end

        return tabcontent
    end
    return tabhold
end

function lib:Destroy()
    if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
    if ui then ui:Destroy() end
end

return lib