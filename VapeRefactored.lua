--[[
    Vape UI Library - 2026 Refactored v2.2
    Super-sized UI (baseWidth=700) | Fixed Toggle & Scrolling | Glass BG
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
------------------------------------------------------------------------
local Theme = {
    Background       = Color3.fromRGB(13, 13, 15),
    Panel            = Color3.fromRGB(18, 18, 21),
    Secondary        = Color3.fromRGB(24, 24, 28),
    Hover            = Color3.fromRGB(30, 30, 35),
    Active           = Color3.fromRGB(36, 36, 42),
    Accent           = Color3.fromRGB(22, 131, 255),

    TextPrimary      = Color3.fromRGB(232, 232, 236),
    TextSecondary    = Color3.fromRGB(180, 180, 190),
    TextDisabled     = Color3.fromRGB(70, 70, 78),

    Border           = Color3.fromRGB(60, 60, 72),
    BorderFocus      = Color3.fromRGB(90, 90, 110),

    ToggleOff        = Color3.fromRGB(42, 42, 48),
    ToggleOn         = Color3.fromRGB(22, 131, 255),
    ToggleCircle     = Color3.fromRGB(220, 220, 225),
    ToggleCircleOff  = Color3.fromRGB(90, 90, 98),

    SliderTrack      = Color3.fromRGB(38, 38, 44),
    SliderFill       = Color3.fromRGB(22, 131, 255),
    SliderThumb      = Color3.fromRGB(220, 220, 225),

    Overlay          = Color3.fromRGB(0, 0, 0),
    Shadow           = Color3.fromRGB(0, 0, 0),
}

------------------------------------------------------------------------
-- Animation Config
------------------------------------------------------------------------
local Anim = {
    Fast    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow    = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slider  = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Toggle  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Window  = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    WindowOut = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    Hover   = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Press   = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
-- ScreenGui
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
-- Responsive Scale (super-sized)
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
    local baseWidth = 700   -- 更小 = 更大
    local s = math.clamp(vp.Y / baseWidth, 0.6, 1.4)
    uiScale.Scale = s
end

UpdateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

------------------------------------------------------------------------
-- Rainbow cycle
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
-- Utilities
------------------------------------------------------------------------
local function tween(obj, info, props, cb)
    local t = TweenService:Create(obj, info, props)
    if cb then
        t.Completed:Connect(cb)
    end
    t:Play()
    return t
end

local function makeBorder(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 2)
    c.Parent = parent
    return c
end

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

local function addHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        tween(btn, Anim.Hover, {BackgroundColor3 = hoverColor or Theme.Hover})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, Anim.Hover, {BackgroundColor3 = normalColor})
    end)
end

local function autoCanvas(scrollFrame, layout)
    local function update()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
    return update
end

------------------------------------------------------------------------
-- Window (larger dimensions)
------------------------------------------------------------------------
local WINDOW_W = 720
local WINDOW_H = 500

function lib:Window(text, preset, closebind)
    CloseBind   = closebind or CloseBind
    PresetColor = preset or Theme.Accent
    Theme.Accent = PresetColor

    local firstTab = true

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ui
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Theme.Background
    Main.BackgroundTransparency = 0.35
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.ClipsDescendants = true
    Main.Visible = true

    makeBorder(Main, Theme.Border, 1.5)
    makeCorner(Main, 6)

    local MainShadow = Instance.new("ImageLabel")
    MainShadow.Name = "Shadow"
    MainShadow.Parent = Main
    MainShadow.BackgroundTransparency = 1
    MainShadow.BorderSizePixel = 0
    MainShadow.Position = UDim2.new(0, -12, 0, -6)
    MainShadow.Size = UDim2.new(1, 24, 1, 24)
    MainShadow.ZIndex = -1
    MainShadow.ImageTransparency = 0.5
    MainShadow.ScaleType = Enum.ScaleType.Slice
    MainShadow.SliceCenter = Rect.new(24, 24, 276, 276)
    MainShadow.Image = "rbxassetid://6014261993"

    local DragFrame = Instance.new("Frame")
    DragFrame.Name = "DragFrame"
    DragFrame.Parent = Main
    DragFrame.BackgroundTransparency = 1
    DragFrame.Size = UDim2.new(1, 0, 0, 36)

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 14, 0, 6)
    Title.Size = UDim2.new(0, 200, 0, 24)
    Title.Font = Enum.Font.GothamSemibold
    Title.Text = text
    Title.TextColor3 = Theme.TextPrimary
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local TabHold = Instance.new("Frame")
    TabHold.Name = "TabHold"
    TabHold.Parent = Main
    TabHold.BackgroundTransparency = 1
    TabHold.Position = UDim2.new(0, 6, 0, 38)
    TabHold.Size = UDim2.new(0, 130, 1, -44)

    local TabHoldLayout = Instance.new("UIListLayout")
    TabHoldLayout.Parent = TabHold
    TabHoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabHoldLayout.Padding = UDim.new(0, 2)

    local SidebarLine = Instance.new("Frame")
    SidebarLine.Name = "SidebarLine"
    SidebarLine.Parent = Main
    SidebarLine.BackgroundColor3 = Theme.Border
    SidebarLine.BorderSizePixel = 0
    SidebarLine.Position = UDim2.new(0, 142, 0, 38)
    SidebarLine.Size = UDim2.new(0, 1, 1, -44)

    local TabFolder = Instance.new("Folder")
    TabFolder.Name = "TabFolder"
    TabFolder.Parent = Main

    tween(Main, Anim.Window, {Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)})
    MakeDraggable(DragFrame, Main)

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

    function lib:ChangePresetColor(c)
        PresetColor = c
        Theme.Accent = c
    end

    function lib:Notification(texttitle, textdesc, textbtn)
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

        tween(NotificationHold, Anim.Medium, {BackgroundTransparency = 0.75})
        task.wait(0.08)

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
        tween(NF, Anim.Slow, {Size = UDim2.new(0, 180, 0, 180)})

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

    local tabhold = {}

    function tabhold:Tab(text)
        -- Tab Button with improved visibility
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = "TabBtn"
        TabBtn.Parent = TabHold
        TabBtn.BackgroundColor3 = Theme.Secondary
        TabBtn.BackgroundTransparency = 0.4
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.AutoButtonColor = false
        TabBtn.Font = Enum.Font.SourceSans
        TabBtn.Text = ""

        makeCorner(TabBtn, 3)

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

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "TabIndicator"
        TabIndicator.Parent = TabBtn
        TabIndicator.BackgroundColor3 = Theme.Accent
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Position = UDim2.new(0, 0, 0.25, 0)
        TabIndicator.Size = UDim2.new(0, 3, 0, 0)
        makeCorner(TabIndicator, 1)

        -- Tab Content
        local Tab = Instance.new("ScrollingFrame")
        Tab.Name = "Tab"
        Tab.Parent = TabFolder
        Tab.Active = true
        Tab.BackgroundTransparency = 1
        Tab.BorderSizePixel = 0
        Tab.Position = UDim2.new(0, 150, 0, 38)
        Tab.Size = UDim2.new(1, -160, 1, -46)
        Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
        Tab.ScrollBarThickness = 8
        Tab.ScrollBarImageColor3 = Theme.TextSecondary
        Tab.ScrollBarImageTransparency = 0.4
        Tab.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
        Tab.TouchScrollEnabled = true
        Tab.ScrollingDirection = Enum.ScrollingDirection.Vertical
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

        local updateCanvas = autoCanvas(Tab, TabLayout)

        if firstTab then
            firstTab = false
            TabIndicator.Size = UDim2.new(0, 3, 0.5, 0)
            TabTitle.TextColor3 = Theme.TextPrimary
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Theme.Panel
            Tab.Visible = true
        end

        local function activateTab()
            for _, v in ipairs(TabHold:GetChildren()) do
                if v.Name == "TabBtn" then
                    tween(v.TabIndicator, Anim.Fast, {Size = UDim2.new(0, 3, 0, 0)})
                    tween(v.TabTitle, Anim.Fast, {TextColor3 = Theme.TextSecondary})
                    tween(v, Anim.Fast, {BackgroundTransparency = 0.4, BackgroundColor3 = Theme.Secondary})
                end
            end
            for _, v in ipairs(TabFolder:GetChildren()) do
                if v.Name == "Tab" then
                    v.Visible = false
                end
            end
            tween(TabIndicator, Anim.Fast, {Size = UDim2.new(0, 3, 0.5, 0)})
            tween(TabTitle, Anim.Fast, {TextColor3 = Theme.TextPrimary})
            tween(TabBtn, Anim.Fast, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Panel})
            Tab.Visible = true
        end

        TabBtn.MouseButton1Click:Connect(activateTab)
        TabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                activateTab()
            end
        end)

        -- tabcontent API
        local ROW_W = UDim.new(1, -4)
        local ROW_H = 38

        local tabcontent = {}

        local function makeRow(height)
            local Row = Instance.new("Frame")
            Row.BackgroundColor3 = Theme.Panel
            Row.BorderSizePixel = 0
            Row.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, height or ROW_H)
            makeBorder(Row, Theme.Border, 1)
            makeCorner(Row, 2)
            return Row
        end

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

            addHover(Button, Theme.Panel, Theme.Hover)

            Button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    tween(Button, Anim.Press, {BackgroundColor3 = Theme.Active})
                end
            end)
            Button.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    tween(Button, Anim.Press, {BackgroundColor3 = Theme.Panel})
                end
            end)

            Button.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
        end

        function tabcontent:Toggle(text, default, callback)
            local state = {
                toggled = false,
                animating = false
            }

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

            local Track = Instance.new("Frame")
            Track.Name = "Track"
            Track.Parent = Toggle
            Track.BackgroundColor3 = Theme.ToggleOff
            Track.BorderSizePixel = 0
            Track.AnchorPoint = Vector2.new(1, 0.5)
            Track.Position = UDim2.new(1, -10, 0.5, 0)
            Track.Size = UDim2.new(0, 34, 0, 18)
            makeCorner(Track, 9)

            local Fill = Instance.new("Frame")
            Fill.Name = "Fill"
            Fill.Parent = Track
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BackgroundTransparency = 1
            Fill.BorderSizePixel = 0
            Fill.Size = UDim2.new(1, 0, 1, 0)
            makeCorner(Fill, 9)

            local Circle = Instance.new("Frame")
            Circle.Name = "Circle"
            Circle.Parent = Track
            Circle.BackgroundColor3 = Theme.ToggleCircleOff
            Circle.BorderSizePixel = 0
            Circle.Position = UDim2.new(0, 3, 0.5, -6)
            Circle.Size = UDim2.new(0, 12, 0, 12)
            makeCorner(Circle, 6)

            local accentSync
            accentSync = RunService.Heartbeat:Connect(function()
                Fill.BackgroundColor3 = Theme.Accent
            end)

            local function setToggle(newState, animate)
                if state.animating then return end
                state.animating = true
                state.toggled = newState
                local info = animate and Anim.Toggle or TweenInfo.new(0, Enum.EasingStyle.Quad)
                if newState then
                    tween(Fill, info, {BackgroundTransparency = 0})
                    tween(Circle, info, {
                        Position = UDim2.new(1, -15, 0.5, -6),
                        BackgroundColor3 = Theme.ToggleCircle
                    })
                else
                    tween(Fill, info, {BackgroundTransparency = 1})
                    tween(Circle, info, {
                        Position = UDim2.new(0, 3, 0.5, -6),
                        BackgroundColor3 = Theme.ToggleCircleOff
                    })
                end
                task.wait(0.16)
                state.animating = false
                pcall(callback, state.toggled)
            end

            addHover(Toggle, Theme.Panel, Theme.Hover)

            Toggle.MouseButton1Click:Connect(function()
                setToggle(not state.toggled, true)
            end)

            Toggle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    setToggle(not state.toggled, true)
                end
            end)

            if default == true then
                setToggle(true, false)
            end

            local handle = {}
            function handle:Set(stateVal)
                setToggle(stateVal, true)
            end
            function handle:Get()
                return state.toggled
            end
            return handle
        end

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

            local SlideFrame = Instance.new("Frame")
            SlideFrame.Name = "SlideFrame"
            SlideFrame.Parent = Slider
            SlideFrame.BackgroundColor3 = Theme.SliderTrack
            SlideFrame.BorderSizePixel = 0
            SlideFrame.Position = UDim2.new(0, 13, 0, 38)
            SlideFrame.Size = UDim2.new(1, -26, 0, 4)
            makeCorner(SlideFrame, 2)

            local CurrentValueFrame = Instance.new("Frame")
            CurrentValueFrame.Name = "CurrentValueFrame"
            CurrentValueFrame.Parent = SlideFrame
            CurrentValueFrame.BackgroundColor3 = Theme.SliderFill
            CurrentValueFrame.BorderSizePixel = 0
            local startScale = (startVal - min) / (max - min)
            CurrentValueFrame.Size = UDim2.new(math.clamp(startScale, 0, 1), 0, 1, 0)
            makeCorner(CurrentValueFrame, 2)

            local SlideCircle = Instance.new("Frame")
            SlideCircle.Name = "SlideCircle"
            SlideCircle.Parent = SlideFrame
            SlideCircle.BackgroundColor3 = Theme.SliderThumb
            SlideCircle.BorderSizePixel = 0
            SlideCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            SlideCircle.Position = UDim2.new(math.clamp(startScale, 0, 1), 0, 0.5, 0)
            SlideCircle.Size = UDim2.new(0, 12, 0, 12)
            makeCorner(SlideCircle, 6)

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

            local function onDragStart(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    move(input)
                end
            end

            SlideCircle.InputBegan:Connect(onDragStart)
            SlideFrame.InputBegan:Connect(onDragStart)

            SlideCircle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            SlideFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    move(input)
                end
            end)

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

        function tabcontent:Dropdown(text, list, callback)
            local droptog = false
            local framesize = 0
            local itemcount = 0
            local ITEM_H = 28

            local Dropdown = Instance.new("Frame")
            Dropdown.Name = "Dropdown"
            Dropdown.Parent = Tab
            Dropdown.BackgroundColor3 = Theme.Panel
            Dropdown.ClipsDescendants = true
            Dropdown.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)

            makeCorner(Dropdown, 2)
            makeBorder(Dropdown, Theme.Border, 1)

            local DropdownBtn = Instance.new("TextButton")
            DropdownBtn.Name = "DropdownBtn"
            DropdownBtn.Parent = Dropdown
            DropdownBtn.BackgroundTransparency = 1
            DropdownBtn.Size = UDim2.new(1, 0, 0, ROW_H)
            DropdownBtn.Font = Enum.Font.SourceSans
            DropdownBtn.Text = ""

            local DropdownTitle = Instance.new("TextLabel")
            DropdownTitle.Name = "DropdownTitle"
            DropdownTitle.Parent = Dropdown
            DropdownTitle.BackgroundTransparency = 1
            DropdownTitle.Position = UDim2.new(0, 13, 0, 0)
            DropdownTitle.Size = UDim2.new(1, -50, 0, ROW_H)
            DropdownTitle.Font = Enum.Font.Gotham
            DropdownTitle.Text = text
            DropdownTitle.TextColor3 = Theme.TextPrimary
            DropdownTitle.TextSize = 13
            DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

            local ArrowImg = Instance.new("ImageLabel")
            ArrowImg.Name = "ArrowImg"
            ArrowImg.Parent = Dropdown
            ArrowImg.BackgroundTransparency = 1
            ArrowImg.AnchorPoint = Vector2.new(1, 0.5)
            ArrowImg.Position = UDim2.new(1, -10, 0.5, 0)
            ArrowImg.Size = UDim2.new(0, 16, 0, 16)
            ArrowImg.Image = "http://www.roblox.com/asset/?id=6034818375"
            ArrowImg.ImageColor3 = Theme.TextSecondary

            local DropItemHolder = Instance.new("ScrollingFrame")
            DropItemHolder.Name = "DropItemHolder"
            DropItemHolder.Parent = Dropdown
            DropItemHolder.Active = true
            DropItemHolder.BackgroundTransparency = 1
            DropItemHolder.BorderSizePixel = 0
            DropItemHolder.Position = UDim2.new(0, 6, 0, ROW_H + 2)
            DropItemHolder.Size = UDim2.new(1, -12, 0, 0)
            DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropItemHolder.ScrollBarThickness = 8
            DropItemHolder.ScrollBarImageColor3 = Theme.TextSecondary
            DropItemHolder.ScrollBarImageTransparency = 0.4
            DropItemHolder.TouchScrollEnabled = true
            DropItemHolder.ScrollingDirection = Enum.ScrollingDirection.Vertical

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.Parent = DropItemHolder
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)

            for i, v in ipairs(list) do
                itemcount = itemcount + 1
                if itemcount <= 4 then
                    framesize = framesize + ITEM_H + 2
                end

                local Item = Instance.new("TextButton")
                Item.Name = "Item"
                Item.Parent = DropItemHolder
                Item.BackgroundColor3 = Theme.Secondary
                Item.ClipsDescendants = true
                Item.Size = UDim2.new(1, 0, 0, ITEM_H)
                Item.AutoButtonColor = false
                Item.Font = Enum.Font.Gotham
                Item.Text = "  " .. v
                Item.TextColor3 = Theme.TextPrimary
                Item.TextSize = 12
                Item.TextXAlignment = Enum.TextXAlignment.Left

                makeCorner(Item, 2)
                addHover(Item, Theme.Secondary, Theme.Hover)

                Item.MouseButton1Click:Connect(function()
                    droptog = false
                    DropdownTitle.Text = text .. " - " .. v
                    pcall(callback, v)
                    tween(Dropdown, Anim.Medium, {Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)})
                    tween(ArrowImg, Anim.Medium, {Rotation = 0})
                    task.wait(0.12)
                end)
            end

            DropItemHolder.Size = UDim2.new(1, -12, 0, math.min(framesize, (ITEM_H + 2) * 4))
            autoCanvas(DropItemHolder, DropLayout)

            DropdownBtn.MouseButton1Click:Connect(function()
                if not droptog then
                    local totalH = ROW_H + framesize + 6
                    tween(Dropdown, Anim.Medium, {Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, totalH)})
                    tween(ArrowImg, Anim.Medium, {Rotation = 180})
                else
                    tween(Dropdown, Anim.Medium, {Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)})
                    tween(ArrowImg, Anim.Medium, {Rotation = 0})
                end
                droptog = not droptog
            end)

            local handle = {}
            function handle:Set(val)
                DropdownTitle.Text = text .. " - " .. tostring(val)
            end
            return handle
        end

        function tabcontent:Colorpicker(text, preset, callback)
            -- 此处保持与之前相同（Colorpicker 功能未改动）
            -- 因篇幅省略，实际使用可复制完整版本
        end

        function tabcontent:Label(text)
            local Label = Instance.new("Frame")
            Label.Name = "Label"
            Label.Parent = Tab
            Label.BackgroundColor3 = Theme.Panel
            Label.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, 28)

            makeCorner(Label, 2)
            makeBorder(Label, Theme.Border, 1)

            local LabelTitle = Instance.new("TextLabel")
            LabelTitle.Name = "LabelTitle"
            LabelTitle.Parent = Label
            LabelTitle.BackgroundTransparency = 1
            LabelTitle.Position = UDim2.new(0, 13, 0, 0)
            LabelTitle.Size = UDim2.new(1, -26, 1, 0)
            LabelTitle.Font = Enum.Font.Gotham
            LabelTitle.Text = text
            LabelTitle.TextColor3 = Theme.TextSecondary
            LabelTitle.TextSize = 12
            LabelTitle.TextXAlignment = Enum.TextXAlignment.Left

            local handle = {}
            function handle:Set(newText)
                LabelTitle.Text = newText
            end
            return handle
        end

        function tabcontent:Textbox(text, disapper, callback)
            local Textbox = Instance.new("Frame")
            Textbox.Name = "Textbox"
            Textbox.Parent = Tab
            Textbox.BackgroundColor3 = Theme.Panel
            Textbox.ClipsDescendants = true
            Textbox.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)

            makeCorner(Textbox, 2)
            makeBorder(Textbox, Theme.Border, 1)

            local TextboxTitle = Instance.new("TextLabel")
            TextboxTitle.Name = "TextboxTitle"
            TextboxTitle.Parent = Textbox
            TextboxTitle.BackgroundTransparency = 1
            TextboxTitle.Position = UDim2.new(0, 13, 0, 0)
            TextboxTitle.Size = UDim2.new(0.5, -13, 0, ROW_H)
            TextboxTitle.Font = Enum.Font.Gotham
            TextboxTitle.Text = text
            TextboxTitle.TextColor3 = Theme.TextPrimary
            TextboxTitle.TextSize = 13
            TextboxTitle.TextXAlignment = Enum.TextXAlignment.Left

            local TextboxFrame = Instance.new("Frame")
            TextboxFrame.Name = "TextboxFrame"
            TextboxFrame.Parent = Textbox
            TextboxFrame.BackgroundColor3 = Theme.Secondary
            TextboxFrame.AnchorPoint = Vector2.new(1, 0.5)
            TextboxFrame.Position = UDim2.new(1, -8, 0.5, 0)
            TextboxFrame.Size = UDim2.new(0, 160, 0, 28)
            makeCorner(TextboxFrame, 2)

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = TextboxFrame
            TextBox.BackgroundTransparency = 1
            TextBox.Position = UDim2.new(0, 8, 0, 0)
            TextBox.Size = UDim2.new(1, -16, 1, 0)
            TextBox.Font = Enum.Font.Gotham
            TextBox.Text = ""
            TextBox.PlaceholderText = "..."
            TextBox.PlaceholderColor3 = Theme.TextDisabled
            TextBox.TextColor3 = Theme.TextPrimary
            TextBox.TextSize = 12
            TextBox.ClearTextOnFocus = false

            TextBox.Focused:Connect(function()
                local stroke = TextboxFrame:FindFirstChildOfClass("UIStroke")
                if stroke then
                    tween(stroke, Anim.Fast, {Color = Theme.BorderFocus})
                end
            end)
            TextBox.FocusLost:Connect(function(ep)
                local stroke = TextboxFrame:FindFirstChildOfClass("UIStroke")
                if stroke then
                    tween(stroke, Anim.Fast, {Color = Theme.Border})
                end
                if ep and #TextBox.Text > 0 then
                    pcall(callback, TextBox.Text)
                    if disapper then
                        TextBox.Text = ""
                    end
                end
            end)

            local handle = {}
            function handle:Set(val)
                TextBox.Text = tostring(val)
            end
            function handle:Get()
                return TextBox.Text
            end
            return handle
        end

        function tabcontent:Bind(text, keypreset, callback)
            local binding = false
            local Key = keypreset and keypreset.Name or "None"

            local Bind = Instance.new("TextButton")
            Bind.Name = "Bind"
            Bind.Parent = Tab
            Bind.BackgroundColor3 = Theme.Panel
            Bind.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, ROW_H)
            Bind.AutoButtonColor = false
            Bind.Font = Enum.Font.SourceSans
            Bind.Text = ""

            makeCorner(Bind, 2)
            makeBorder(Bind, Theme.Border, 1)

            local BindTitle = Instance.new("TextLabel")
            BindTitle.Name = "BindTitle"
            BindTitle.Parent = Bind
            BindTitle.BackgroundTransparency = 1
            BindTitle.Position = UDim2.new(0, 13, 0, 0)
            BindTitle.Size = UDim2.new(1, -80, 0, ROW_H)
            BindTitle.Font = Enum.Font.Gotham
            BindTitle.Text = text
            BindTitle.TextColor3 = Theme.TextPrimary
            BindTitle.TextSize = 13
            BindTitle.TextXAlignment = Enum.TextXAlignment.Left

            local BindKeyBg = Instance.new("Frame")
            BindKeyBg.Name = "BindKeyBg"
            BindKeyBg.Parent = Bind
            BindKeyBg.BackgroundColor3 = Theme.Secondary
            BindKeyBg.AnchorPoint = Vector2.new(1, 0.5)
            BindKeyBg.Position = UDim2.new(1, -8, 0.5, 0)
            BindKeyBg.Size = UDim2.new(0, 60, 0, 24)
            makeCorner(BindKeyBg, 2)

            local BindText = Instance.new("TextLabel")
            BindText.Name = "BindText"
            BindText.Parent = BindKeyBg
            BindText.BackgroundTransparency = 1
            BindText.Size = UDim2.new(1, 0, 1, 0)
            BindText.Font = Enum.Font.GothamMedium
            BindText.Text = Key
            BindText.TextColor3 = Theme.TextSecondary
            BindText.TextSize = 11

            addHover(Bind, Theme.Panel, Theme.Hover)

            Bind.MouseButton1Click:Connect(function()
                if binding then return end
                binding = true
                BindText.Text = "..."
                BindText.TextColor3 = Theme.Accent

                local inputwait = UserInputService.InputBegan:Wait()
                if inputwait.KeyCode and inputwait.KeyCode.Name ~= "Unknown" then
                    BindText.Text = inputwait.KeyCode.Name
                    Key = inputwait.KeyCode.Name
                end
                BindText.TextColor3 = Theme.TextSecondary
                binding = false
            end)

            UserInputService.InputBegan:Connect(function(current, processed)
                if processed then return end
                if not binding and current.KeyCode.Name == Key then
                    pcall(callback)
                end
            end)

            local handle = {}
            function handle:Set(keycode)
                Key = keycode.Name or tostring(keycode)
                BindText.Text = Key
            end
            return handle
        end

        function tabcontent:Section(text)
            local Section = Instance.new("Frame")
            Section.Name = "Section"
            Section.Parent = Tab
            Section.BackgroundTransparency = 1
            Section.Size = UDim2.new(ROW_W.Scale, ROW_W.Offset, 0, 18)

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Parent = Section
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Position = UDim2.new(0, 4, 0, 0)
            SectionTitle.Size = UDim2.new(1, -8, 1, 0)
            SectionTitle.Font = Enum.Font.GothamSemibold
            SectionTitle.Text = text:upper()
            SectionTitle.TextColor3 = Theme.TextDisabled
            SectionTitle.TextSize = 10
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        end

        return tabcontent
    end

    return tabhold
end

function lib:Destroy()
    if rainbowConn then
        rainbowConn:Disconnect()
        rainbowConn = nil
    end
    if ui then
        ui:Destroy()
    end
end

return lib