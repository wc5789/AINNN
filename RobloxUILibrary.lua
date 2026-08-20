--[[
    Modern Premium Utility Interface — Roblox UI Library
    Specification compliant with Component-Level Visual Design Standard.
    Design Style: Modern Premium Utility Interface (Professional, Quiet, Stable, High Density)
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

--------------------------------------------------------------------------------
-- 1. DESIGN TOKENS & SYSTEM DEFINITIONS
--------------------------------------------------------------------------------

Library.Tokens = {
    Spacing = {
        Xs = 4,
        Sm = 6,
        Md = 8,
        Lg = 12,
        Xl = 16,
        Xxl = 24,
        Section = 20,
        WindowPadding = 16,
    },
    Height = {
        Small = 32,
        Normal = 36,
        Mobile = 44,
        Large = 48,
    },
    Radius = {
        Small = UDim.new(0, 6),
        Normal = UDim.new(0, 8),
        Large = UDim.new(0, 10),
        Popup = UDim.new(0, 10),
        Window = UDim.new(0, 12),
    },
    Typography = {
        FontMain = Enum.Font.SourceSans,
        FontBold = Enum.Font.SourceSansBold,
        FontMono = Enum.Font.Code,
        SizeTitle = 16,
        SizeSubtitle = 12,
        SizeBody = 14,
        SizeCaption = 12,
        SizeSmall = 11,
    },
    Animation = {
        Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Slow = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        ReducedMotion = TweenInfo.new(0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    }
}

Library.Theme = {
    -- Surfaces (Low contrast hierarchy)
    RootBg = Color3.fromRGB(15, 16, 18),
    WindowSurface = Color3.fromRGB(20, 22, 26),
    SidebarSurface = Color3.fromRGB(24, 26, 31),
    ContentSurface = Color3.fromRGB(28, 31, 38),
    ElevatedSurface = Color3.fromRGB(35, 39, 48),
    PopupSurface = Color3.fromRGB(42, 47, 58),
    OverlaySurface = Color3.fromRGB(10, 11, 13),

    -- Borders (Subtle, low contrast)
    BorderSubtle = Color3.fromRGB(45, 50, 60),
    BorderBright = Color3.fromRGB(70, 78, 95),
    BorderAccent = Color3.fromRGB(0, 122, 255),

    -- Typography
    TextPrimary = Color3.fromRGB(240, 243, 248),
    TextSecondary = Color3.fromRGB(160, 168, 182),
    TextMuted = Color3.fromRGB(100, 110, 128),
    TextDisabled = Color3.fromRGB(70, 75, 88),

    -- Accent
    Accent = Color3.fromRGB(0, 122, 255),
    AccentHover = Color3.fromRGB(30, 140, 255),
    AccentPressed = Color3.fromRGB(0, 100, 220),

    -- Status Colors
    Success = Color3.fromRGB(40, 195, 110),
    Warning = Color3.fromRGB(245, 166, 35),
    Error = Color3.fromRGB(235, 75, 75),
    Info = Color3.fromRGB(0, 122, 255)
}

Library.ReducedMotion = "Full" -- "Full", "Reduced", "Off"

local function GetTweenInfo(speedType)
    if Library.ReducedMotion == "Off" then
        return Library.Tokens.Animation.ReducedMotion
    end
    return Library.Tokens.Animation[speedType or "Normal"]
end

local function Tween(instance, tweenInfo, properties)
    if not instance then return end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

--------------------------------------------------------------------------------
-- 2. NOTIFICATION SYSTEM
--------------------------------------------------------------------------------

local NotificationContainer = nil

local function EnsureNotificationContainer()
    if NotificationContainer and NotificationContainer.Parent then return end
    
    local parent = RunService:IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    local sg = parent:FindFirstChild("UtilityLibNotifications")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "UtilityLibNotifications"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 999
        sg.Parent = parent
    end

    local container = Instance.new("Frame")
    container.Name = "NotifyHolder"
    container.Size = UDim2.new(0, 320, 1, -32)
    container.Position = UDim2.new(1, -336, 0, 16)
    container.BackgroundTransparency = 1
    container.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container

    NotificationContainer = container
end

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local desc = options.Description or ""
    local duration = options.Duration or 4
    local notifyType = options.Type or "Info" -- Info, Success, Warning, Error

    EnsureNotificationContainer()

    local typeColor = Library.Theme.Info
    if notifyType == "Success" then typeColor = Library.Theme.Success
    elseif notifyType == "Warning" then typeColor = Library.Theme.Warning
    elseif notifyType == "Error" then typeColor = Library.Theme.Error end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Library.Theme.ElevatedSurface
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.BackgroundTransparency = 1

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Library.Tokens.Radius.Normal
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.Theme.BorderSubtle
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = card

    -- Indicator bar / Dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 0, 0, 6)
    dot.BackgroundColor3 = typeColor
    dot.BorderSizePixel = 0
    dot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -16, 1, 0)
    contentFrame.Position = UDim2.new(0, 16, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = card

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = contentFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = title
    titleLbl.Font = Library.Tokens.Typography.FontBold
    titleLbl.TextSize = Library.Tokens.Typography.SizeBody
    titleLbl.TextColor3 = Library.Theme.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, 0, 0, 16)
    titleLbl.Parent = contentFrame

    if desc ~= "" then
        local descLbl = Instance.new("TextLabel")
        descLbl.Text = desc
        descLbl.Font = Library.Tokens.Typography.FontMain
        descLbl.TextSize = Library.Tokens.Typography.SizeCaption
        descLbl.TextColor3 = Library.Theme.TextSecondary
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.TextWrapped = true
        descLbl.BackgroundTransparency = 1
        descLbl.Size = UDim2.new(1, 0, 0, 0)
        descLbl.AutomaticSize = Enum.AutomaticSize.Y
        descLbl.Parent = contentFrame
    end

    -- Progress Bar
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = typeColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = card

    card.Parent = NotificationContainer

    -- Animation In
    Tween(card, GetTweenInfo("Normal"), {BackgroundTransparency = 0})
    Tween(stroke, GetTweenInfo("Normal"), {Transparency = 0})

    if duration > 0 then
        Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
        task.delay(duration, function()
            local tw = Tween(card, GetTweenInfo("Normal"), {BackgroundTransparency = 1})
            Tween(stroke, GetTweenInfo("Normal"), {Transparency = 1})
            if tw then
                tw.Completed:Connect(function()
                    card:Destroy()
                end)
            else
                card:Destroy()
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- 3. WINDOW & CORE INTERFACE
--------------------------------------------------------------------------------

function Library.CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Utility Interface"
    local windowSubtitle = config.Subtitle or "Modern Premium Library"
    local size = config.Size or UDim2.new(0, 720, 0, 480)

    local parent = RunService:IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "UtilityLibMainGUI"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 100
    sg.Parent = parent

    -- Window Root Container
    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = size
    window.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    window.BackgroundColor3 = Library.Theme.WindowSurface
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = sg

    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = Library.Tokens.Radius.Window
    windowCorner.Parent = window

    local windowStroke = Instance.new("UIStroke")
    windowStroke.Color = Library.Theme.BorderSubtle
    windowStroke.Thickness = 1
    windowStroke.Parent = window

    ----------------------------------------------------------------------------
    -- HEADER
    ----------------------------------------------------------------------------
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Library.Theme.WindowSurface
    header.BorderSizePixel = 0
    header.Parent = window

    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 16)
    headerPadding.PaddingRight = UDim.new(0, 12)
    headerPadding.Parent = header

    -- Left Info
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(0, 300, 1, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = header

    local titleLayout = Instance.new("UIListLayout")
    titleLayout.FillDirection = Enum.FillDirection.Horizontal
    titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleLayout.Padding = UDim.new(0, 8)
    titleLayout.Parent = titleFrame

    local mainTitle = Instance.new("TextLabel")
    mainTitle.Text = windowTitle
    mainTitle.Font = Library.Tokens.Typography.FontBold
    mainTitle.TextSize = Library.Tokens.Typography.SizeTitle
    mainTitle.TextColor3 = Library.Theme.TextPrimary
    mainTitle.AutomaticSize = Enum.AutomaticSize.X
    mainTitle.Size = UDim2.new(0, 0, 1, 0)
    mainTitle.BackgroundTransparency = 1
    mainTitle.Parent = titleFrame

    local subTitle = Instance.new("TextLabel")
    subTitle.Text = windowSubtitle
    subTitle.Font = Library.Tokens.Typography.FontMain
    subTitle.TextSize = Library.Tokens.Typography.SizeSubtitle
    subTitle.TextColor3 = Library.Theme.TextMuted
    subTitle.AutomaticSize = Enum.AutomaticSize.X
    subTitle.Size = UDim2.new(0, 0, 1, 0)
    subTitle.BackgroundTransparency = 1
    subTitle.Parent = titleFrame

    -- Controls (Right)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 100, 1, 0)
    controlsFrame.Position = UDim2.new(1, -100, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlsLayout.Padding = UDim.new(0, 4)
    controlsLayout.Parent = controlsFrame

    local function CreateHeaderBtn(iconText, isClose)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.BackgroundColor3 = Library.Theme.ElevatedSurface
        btn.BackgroundTransparency = 1
        btn.Text = iconText
        btn.Font = Library.Tokens.Typography.FontBold
        btn.TextSize = 14
        btn.TextColor3 = Library.Theme.TextSecondary
        btn.AutoButtonColor = false
        btn.Parent = controlsFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Library.Tokens.Radius.Small
        corner.Parent = btn

        btn.MouseEnter:Connect(function()
            Tween(btn, GetTweenInfo("Fast"), {
                BackgroundTransparency = 0,
                TextColor3 = isClose and Library.Theme.Error or Library.Theme.TextPrimary
            })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, GetTweenInfo("Fast"), {
                BackgroundTransparency = 1,
                TextColor3 = Library.Theme.TextSecondary
            })
        end)
        return btn
    end

    local minBtn = CreateHeaderBtn("-", false)
    local closeBtn = CreateHeaderBtn("×", true)

    -- Header Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 42)
    divider.BackgroundColor3 = Library.Theme.BorderSubtle
    divider.BorderSizePixel = 0
    divider.Parent = window

    ----------------------------------------------------------------------------
    -- BODY (SIDEBAR & CONTENT)
    ----------------------------------------------------------------------------
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, -43)
    body.Position = UDim2.new(0, 0, 0, 43)
    body.BackgroundTransparency = 1
    body.Parent = window

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 180, 1, 0)
    sidebar.BackgroundColor3 = Library.Theme.SidebarSurface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = body

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 8)
    sidebarPadding.PaddingRight = UDim.new(0, 8)
    sidebarPadding.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 4)
    tabListLayout.Parent = sidebar

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -181, 1, 0)
    contentContainer.Position = UDim2.new(0, 181, 0, 0)
    contentContainer.BackgroundColor3 = Library.Theme.ContentSurface
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = body

    -- Window Dragging Functionality
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Window Minimize / Close
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        Tween(body, GetTweenInfo("Normal"), {Visible = not isMinimized})
        Tween(window, GetTweenInfo("Normal"), {Size = isMinimized and UDim2.new(size.X.Scale, size.X.Offset, 0, 43) or size})
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Tween(window, GetTweenInfo("Fast"), {Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0), BackgroundTransparency = 1})
        task.delay(0.15, function()
            sg:Destroy()
        end)
    end)

    ----------------------------------------------------------------------------
    -- TAB SYSTEM
    ----------------------------------------------------------------------------
    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
        Gui = sg,
        MainFrame = window
    }

    function WindowObj:CreateTab(tabName)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)
        tabBtn.BackgroundColor3 = Library.Theme.ElevatedSurface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = sidebar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = Library.Tokens.Radius.Small
        tabCorner.Parent = tabBtn

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 16)
        indicator.Position = UDim2.new(0, 4, 0.5, -8)
        indicator.BackgroundColor3 = Library.Theme.Accent
        indicator.BackgroundTransparency = 1
        indicator.BorderSizePixel = 0
        indicator.Parent = tabBtn

        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(1, 0)
        indicatorCorner.Parent = indicator

        local label = Instance.new("TextLabel")
        label.Text = tabName
        label.Font = Library.Tokens.Typography.FontMain
        label.TextSize = Library.Tokens.Typography.SizeBody
        label.TextColor3 = Library.Theme.TextSecondary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.BackgroundTransparency = 1
        label.Parent = tabBtn

        -- Scrollable Page Area
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Library.Theme.BorderBright
        page.Visible = false
        page.Parent = contentContainer

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, Library.Tokens.Spacing.WindowPadding)
        pagePadding.PaddingBottom = UDim.new(0, Library.Tokens.Spacing.WindowPadding)
        pagePadding.PaddingLeft = UDim.new(0, Library.Tokens.Spacing.WindowPadding)
        pagePadding.PaddingRight = UDim.new(0, Library.Tokens.Spacing.WindowPadding)
        pagePadding.Parent = page

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, Library.Tokens.Spacing.Section)
        pageLayout.Parent = page

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 32)
        end)

        local TabObj = {
            Page = page,
            Button = tabBtn
        }

        local function Activate()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, GetTweenInfo("Fast"), {BackgroundTransparency = 1})
                local ind = t.Button:FindFirstChild("Frame")
                local lbl = t.Button:FindFirstChild("TextLabel")
                if ind then Tween(ind, GetTweenInfo("Fast"), {BackgroundTransparency = 1}) end
                if lbl then Tween(lbl, GetTweenInfo("Fast"), {TextColor3 = Library.Theme.TextSecondary}) end
            end
            page.Visible = true
            WindowObj.ActiveTab = TabObj
            Tween(tabBtn, GetTweenInfo("Fast"), {BackgroundTransparency = 0})
            Tween(indicator, GetTweenInfo("Fast"), {BackgroundTransparency = 0})
            Tween(label, GetTweenInfo("Fast"), {TextColor3 = Library.Theme.TextPrimary})
        end

        tabBtn.MouseButton1Click:Connect(Activate)

        tabBtn.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, GetTweenInfo("Fast"), {BackgroundTransparency = 0.5})
                Tween(label, GetTweenInfo("Fast"), {TextColor3 = Library.Theme.TextPrimary})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, GetTweenInfo("Fast"), {BackgroundTransparency = 1})
                Tween(label, GetTweenInfo("Fast"), {TextColor3 = Library.Theme.TextSecondary})
            end
        end)

        if #WindowObj.Tabs == 0 then
            Activate()
        end

        table.insert(WindowObj.Tabs, TabObj)

        ------------------------------------------------------------------------
        -- SECTION & COMPONENT CREATORS
        ------------------------------------------------------------------------
        function TabObj:CreateSection(secTitle, secDesc)
            local secFrame = Instance.new("Frame")
            secFrame.Name = "Section_" .. secTitle
            secFrame.Size = UDim2.new(1, 0, 0, 0)
            secFrame.AutomaticSize = Enum.AutomaticSize.Y
            secFrame.BackgroundTransparency = 1
            secFrame.Parent = page

            local secLayout = Instance.new("UIListLayout")
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Padding = UDim.new(0, Library.Tokens.Spacing.Md)
            secLayout.Parent = secFrame

            if secTitle and secTitle ~= "" then
                local headerFrame = Instance.new("Frame")
                headerFrame.Size = UDim2.new(1, 0, 0, 0)
                headerFrame.AutomaticSize = Enum.AutomaticSize.Y
                headerFrame.BackgroundTransparency = 1
                headerFrame.Parent = secFrame

                local hLayout = Instance.new("UIListLayout")
                hLayout.SortOrder = Enum.SortOrder.LayoutOrder
                hLayout.Padding = UDim.new(0, 2)
                hLayout.Parent = headerFrame

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Text = secTitle
                titleLbl.Font = Library.Tokens.Typography.FontBold
                titleLbl.TextSize = Library.Tokens.Typography.SizeBody
                titleLbl.TextColor3 = Library.Theme.TextPrimary
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.Size = UDim2.new(1, 0, 0, 16)
                titleLbl.BackgroundTransparency = 1
                titleLbl.Parent = headerFrame

                if secDesc and secDesc ~= "" then
                    local descLbl = Instance.new("TextLabel")
                    descLbl.Text = secDesc
                    descLbl.Font = Library.Tokens.Typography.FontMain
                    descLbl.TextSize = Library.Tokens.Typography.SizeCaption
                    descLbl.TextColor3 = Library.Theme.TextMuted
                    descLbl.TextXAlignment = Enum.TextXAlignment.Left
                    descLbl.Size = UDim2.new(1, 0, 0, 14)
                    descLbl.BackgroundTransparency = 1
                    descLbl.Parent = headerFrame
                end
            end

            local SectionObj = {}

            --------------------------------------------------------------------
            -- 1. BUTTONS (Primary, Secondary, Ghost)
            --------------------------------------------------------------------
            function SectionObj:CreateButton(options)
                options = options or {}
                local text = options.Text or "Button"
                local style = options.Style or "Secondary" -- Primary, Secondary, Ghost
                local callback = options.Callback or function() end

                local btnFrame = Instance.new("Frame")
                btnFrame.Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)
                btnFrame.BackgroundTransparency = 1
                btnFrame.Parent = secFrame

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.Text = text
                btn.Font = Library.Tokens.Typography.FontMain
                btn.TextSize = Library.Tokens.Typography.SizeBody
                btn.AutoButtonColor = false
                btn.Parent = btnFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = Library.Tokens.Radius.Normal
                corner.Parent = btn

                local stroke = Instance.new("UIStroke")
                stroke.Thickness = 1
                stroke.Parent = btn

                if style == "Primary" then
                    btn.BackgroundColor3 = Library.Theme.Accent
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    stroke.Color = Library.Theme.AccentHover
                elseif style == "Secondary" then
                    btn.BackgroundColor3 = Library.Theme.ElevatedSurface
                    btn.TextColor3 = Library.Theme.TextPrimary
                    stroke.Color = Library.Theme.BorderSubtle
                else -- Ghost
                    btn.BackgroundColor3 = Library.Theme.ElevatedSurface
                    btn.BackgroundTransparency = 1
                    btn.TextColor3 = Library.Theme.TextSecondary
                    stroke.Transparency = 1
                end

                btn.MouseEnter:Connect(function()
                    if style == "Primary" then
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.AccentHover})
                    elseif style == "Secondary" then
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.PopupSurface})
                    else
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundTransparency = 0, TextColor3 = Library.Theme.TextPrimary})
                    end
                end)

                btn.MouseLeave:Connect(function()
                    if style == "Primary" then
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.Accent})
                    elseif style == "Secondary" then
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.ElevatedSurface})
                    else
                        Tween(btn, GetTweenInfo("Fast"), {BackgroundTransparency = 1, TextColor3 = Library.Theme.TextSecondary})
                    end
                end)

                btn.MouseButton1Down:Connect(function()
                    Tween(btn, GetTweenInfo("Fast"), {Size = UDim2.new(0.98, 0, 0.94, 0), Position = UDim2.new(0.01, 0, 0.03, 0)})
                end)

                btn.MouseButton1Up:Connect(function()
                    Tween(btn, GetTweenInfo("Fast"), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
                    callback()
                end)

                return btn
            end

            --------------------------------------------------------------------
            -- 2. TOGGLE
            --------------------------------------------------------------------
            function SectionObj:CreateToggle(options)
                options = options or {}
                local text = options.Text or "Toggle Option"
                local desc = options.Description or ""
                local defaultState = options.Default or false
                local callback = options.Callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, desc ~= "" and 42 or Library.Tokens.Height.Normal)
                row.BackgroundColor3 = Library.Theme.ElevatedSurface
                row.BackgroundTransparency = 0.5
                row.Parent = secFrame

                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = Library.Tokens.Radius.Normal
                rowCorner.Parent = row

                local rowPadding = Instance.new("UIPadding")
                rowPadding.PaddingLeft = UDim.new(0, 12)
                rowPadding.PaddingRight = UDim.new(0, 12)
                rowPadding.Parent = row

                -- Text Info
                local infoFrame = Instance.new("Frame")
                infoFrame.Size = UDim2.new(1, -50, 1, 0)
                infoFrame.BackgroundTransparency = 1
                infoFrame.Parent = row

                local infoLayout = Instance.new("UIListLayout")
                infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                infoLayout.Padding = UDim.new(0, 2)
                infoLayout.Parent = infoFrame

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = text
                nameLbl.Font = Library.Tokens.Typography.FontMain
                nameLbl.TextSize = Library.Tokens.Typography.SizeBody
                nameLbl.TextColor3 = Library.Theme.TextPrimary
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Size = UDim2.new(1, 0, 0, 16)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Parent = infoFrame

                if desc ~= "" then
                    local descLbl = Instance.new("TextLabel")
                    descLbl.Text = desc
                    descLbl.Font = Library.Tokens.Typography.FontMain
                    descLbl.TextSize = Library.Tokens.Typography.SizeCaption
                    descLbl.TextColor3 = Library.Theme.TextMuted
                    descLbl.TextXAlignment = Enum.TextXAlignment.Left
                    descLbl.Size = UDim2.new(1, 0, 0, 14)
                    descLbl.BackgroundTransparency = 1
                    descLbl.Parent = infoFrame
                end

                -- Track
                local track = Instance.new("TextButton")
                track.Size = UDim2.new(0, 36, 0, 20)
                track.Position = UDim2.new(1, -36, 0.5, -10)
                track.BackgroundColor3 = defaultState and Library.Theme.Accent or Library.Theme.BorderSubtle
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = row

                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = track

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 16, 0, 16)
                thumb.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                thumb.BorderSizePixel = 0
                thumb.Parent = track

                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(1, 0)
                thumbCorner.Parent = thumb

                local state = defaultState

                local function ToggleState(val)
                    state = (val ~= nil) and val or not state
                    local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    local targetColor = state and Library.Theme.Accent or Library.Theme.BorderSubtle

                    Tween(thumb, GetTweenInfo("Fast"), {Position = targetPos})
                    Tween(track, GetTweenInfo("Fast"), {BackgroundColor3 = targetColor})
                    callback(state)
                end

                track.MouseButton1Click:Connect(function()
                    ToggleState()
                end)

                return {
                    Set = function(self, val) ToggleState(val) end,
                    Value = state
                }
            end

            --------------------------------------------------------------------
            -- 3. SLIDER
            --------------------------------------------------------------------
            function SectionObj:CreateSlider(options)
                options = options or {}
                local text = options.Text or "Slider"
                local min = options.Min or 0
                local max = options.Max or 100
                local defaultVal = options.Default or min
                local decimals = options.Decimals or 0
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, 48)
                container.BackgroundColor3 = Library.Theme.ElevatedSurface
                container.BackgroundTransparency = 0.5
                container.Parent = secFrame

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = Library.Tokens.Radius.Normal
                cCorner.Parent = container

                local cPadding = Instance.new("UIPadding")
                cPadding.PaddingLeft = UDim.new(0, 12)
                cPadding.PaddingRight = UDim.new(0, 12)
                cPadding.PaddingTop = UDim.new(0, 8)
                cPadding.Parent = container

                -- Header Info
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = text
                nameLbl.Font = Library.Tokens.Typography.FontMain
                nameLbl.TextSize = Library.Tokens.Typography.SizeBody
                nameLbl.TextColor3 = Library.Theme.TextPrimary
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Size = UDim2.new(0.7, 0, 0, 16)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Parent = container

                local valLbl = Instance.new("TextLabel")
                valLbl.Text = tostring(defaultVal)
                valLbl.Font = Library.Tokens.Typography.FontMono
                valLbl.TextSize = Library.Tokens.Typography.SizeCaption
                valLbl.TextColor3 = Library.Theme.TextSecondary
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Size = UDim2.new(0.3, 0, 0, 16)
                valLbl.Position = UDim2.new(0.7, 0, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Parent = container

                -- Track Bar
                local track = Instance.new("TextButton")
                track.Size = UDim2.new(1, 0, 0, 4)
                track.Position = UDim2.new(0, 0, 0, 28)
                track.BackgroundColor3 = Library.Theme.BorderSubtle
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = container

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(1, 0)
                tCorner.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((defaultVal - min)/(max - min), 0, 1, 0)
                fill.BackgroundColor3 = Library.Theme.Accent
                fill.BorderSizePixel = 0
                fill.Parent = track

                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(1, 0)
                fCorner.Parent = fill

                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 12, 0, 12)
                thumb.Position = UDim2.new(1, -6, 0.5, -6)
                thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                thumb.BorderSizePixel = 0
                thumb.Parent = fill

                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(1, 0)
                thumbCorner.Parent = thumb

                local isDragging = false

                local function UpdateValue(inputPos)
                    local percent = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local rawVal = min + (max - min) * percent
                    local factor = 10 ^ decimals
                    local val = math.floor(rawVal * factor + 0.5) / factor

                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    valLbl.Text = tostring(val)
                    callback(val)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        UpdateValue(input.Position)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateValue(input.Position)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)

                return {
                    Set = function(self, v)
                        local percent = math.clamp((v - min)/(max - min), 0, 1)
                        fill.Size = UDim2.new(percent, 0, 1, 0)
                        valLbl.Text = tostring(v)
                        callback(v)
                    end
                }
            end

            --------------------------------------------------------------------
            -- 4. TEXTBOX
            --------------------------------------------------------------------
            function SectionObj:CreateTextbox(options)
                options = options or {}
                local text = options.Text or "Input Text"
                local placeholder = options.Placeholder or "Type here..."
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)
                container.BackgroundColor3 = Library.Theme.ElevatedSurface
                container.BackgroundTransparency = 0.5
                container.Parent = secFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = Library.Tokens.Radius.Normal
                corner.Parent = container

                local stroke = Instance.new("UIStroke")
                stroke.Color = Library.Theme.BorderSubtle
                stroke.Thickness = 1
                stroke.Parent = container

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Theme.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(0.4, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.BackgroundTransparency = 1
                label.Parent = container

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.6, -12, 1, -8)
                box.Position = UDim2.new(0.4, 0, 0, 4)
                box.BackgroundColor3 = Library.Theme.ContentSurface
                box.PlaceholderText = placeholder
                box.PlaceholderColor3 = Library.Theme.TextMuted
                box.Text = ""
                box.TextColor3 = Library.Theme.TextPrimary
                box.Font = Library.Tokens.Typography.FontMain
                box.TextSize = Library.Tokens.Typography.SizeBody
                box.ClearTextOnFocus = false
                box.Parent = container

                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = Library.Tokens.Radius.Small
                boxCorner.Parent = box

                box.Focused:Connect(function()
                    Tween(stroke, GetTweenInfo("Fast"), {Color = Library.Theme.Accent})
                end)

                box.FocusLost:Connect(function(enterPressed)
                    Tween(stroke, GetTweenInfo("Fast"), {Color = Library.Theme.BorderSubtle})
                    callback(box.Text, enterPressed)
                end)

                return box
            end

            --------------------------------------------------------------------
            -- 5. DROPDOWN
            --------------------------------------------------------------------
            function SectionObj:CreateDropdown(options)
                options = options or {}
                local text = options.Text or "Select Option"
                local items = options.Items or {}
                local defaultItem = options.Default or items[1]
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)
                container.BackgroundColor3 = Library.Theme.ElevatedSurface
                container.BackgroundTransparency = 0.5
                container.ClipsDescendants = true
                container.Parent = secFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = Library.Tokens.Radius.Normal
                corner.Parent = container

                local mainBtn = Instance.new("TextButton")
                mainBtn.Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)
                mainBtn.BackgroundTransparency = 1
                mainBtn.Text = ""
                mainBtn.Parent = container

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Theme.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Size = UDim2.new(0.5, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Parent = mainBtn

                local selectedLbl = Instance.new("TextLabel")
                selectedLbl.Text = tostring(defaultItem or "None")
                selectedLbl.Font = Library.Tokens.Typography.FontMain
                selectedLbl.TextSize = Library.Tokens.Typography.SizeBody
                selectedLbl.TextColor3 = Library.Theme.Accent
                selectedLbl.TextXAlignment = Enum.TextXAlignment.Right
                selectedLbl.Position = UDim2.new(0.5, 0, 0, 0)
                selectedLbl.Size = UDim2.new(0.5, -28, 1, 0)
                selectedLbl.BackgroundTransparency = 1
                selectedLbl.Parent = mainBtn

                local arrow = Instance.new("TextLabel")
                arrow.Text = "▾"
                arrow.Font = Library.Tokens.Typography.FontBold
                arrow.TextSize = 12
                arrow.TextColor3 = Library.Theme.TextSecondary
                arrow.Position = UDim2.new(1, -20, 0, 0)
                arrow.Size = UDim2.new(0, 12, 1, 0)
                arrow.BackgroundTransparency = 1
                arrow.Parent = mainBtn

                local listFrame = Instance.new("Frame")
                listFrame.Size = UDim2.new(1, -16, 0, #items * 30)
                listFrame.Position = UDim2.new(0, 8, 0, Library.Tokens.Height.Normal + 4)
                listFrame.BackgroundTransparency = 1
                listFrame.Parent = container

                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0, 2)
                listLayout.Parent = listFrame

                local isOpen = false

                for _, item in ipairs(items) do
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Size = UDim2.new(1, 0, 0, 28)
                    itemBtn.BackgroundColor3 = Library.Theme.ContentSurface
                    itemBtn.Text = tostring(item)
                    itemBtn.TextColor3 = Library.Theme.TextSecondary
                    itemBtn.Font = Library.Tokens.Typography.FontMain
                    itemBtn.TextSize = Library.Tokens.Typography.SizeCaption
                    itemBtn.AutoButtonColor = false
                    itemBtn.Parent = listFrame

                    local itemCorner = Instance.new("UICorner")
                    itemCorner.CornerRadius = Library.Tokens.Radius.Small
                    itemCorner.Parent = itemBtn

                    itemBtn.MouseEnter:Connect(function()
                        Tween(itemBtn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.PopupSurface, TextColor3 = Library.Theme.TextPrimary})
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        Tween(itemBtn, GetTweenInfo("Fast"), {BackgroundColor3 = Library.Theme.ContentSurface, TextColor3 = Library.Theme.TextSecondary})
                    end)

                    itemBtn.MouseButton1Click:Connect(function()
                        selectedLbl.Text = tostring(item)
                        isOpen = false
                        Tween(container, GetTweenInfo("Normal"), {Size = UDim2.new(1, 0, 0, Library.Tokens.Height.Normal)})
                        Tween(arrow, GetTweenInfo("Fast"), {Rotation = 0})
                        callback(item)
                    end)
                end

                mainBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    local targetHeight = isOpen and (Library.Tokens.Height.Normal + #items * 30 + 12) or Library.Tokens.Height.Normal
                    Tween(container, GetTweenInfo("Normal"), {Size = UDim2.new(1, 0, 0, targetHeight)})
                    Tween(arrow, GetTweenInfo("Fast"), {Rotation = isOpen and 180 or 0})
                end)

                return {
                    Select = function(self, val)
                        selectedLbl.Text = tostring(val)
                        callback(val)
                    end
                }
            end

            return SectionObj
        end

        return TabObj
    end

    return WindowObj
end

return Library
