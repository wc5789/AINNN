--[[
    ANTI-AI ROBLOX UI LIBRARY — DESIGN SYSTEM SPECIFICATION v2.0
    Design Philosophy: Sharp, Architectural, Product-Grade Utility UI Framework
    
    Zero-AI Design DNA:
    - Colors: Warm Orange-Red Accent (#E05A3A), Pure Dark Background (#0A0A0A / #141414 / #1C1C1C)
    - Geometry: Level 0 Sharp (0px) & Level 1 Subtle (2px), Level 2 Soft (4px)
    - Components: Un-carded Layout, Line Toggles, Line Inputs, Rail Navigation, Structural Typography
    - Motion: Mechanical, Instant, Zero-Glow, Zero-Glassmorphism
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

--------------------------------------------------------------------------------
-- 1. DESIGN TOKENS (Strict Anti-AI System)
--------------------------------------------------------------------------------

Library.Tokens = {
    Colors = {
        BgBase          = Color3.fromRGB(10, 10, 10),    -- #0A0A0A
        BgSurface       = Color3.fromRGB(20, 20, 20),    -- #141414
        BgElevated      = Color3.fromRGB(28, 28, 28),    -- #1C1C1C
        BgInput         = Color3.fromRGB(15, 15, 15),    -- #0F0F0F

        TextPrimary     = Color3.fromRGB(232, 232, 232), -- #E8E8E8
        TextSecondary   = Color3.fromRGB(160, 160, 160), -- #A0A0A0
        TextTertiary    = Color3.fromRGB(96, 96, 96),   -- #606060
        TextInverse     = Color3.fromRGB(10, 10, 10),    -- #0A0A0A

        AccentPrimary   = Color3.fromRGB(224, 90, 58),   -- #E05A3A Warm Orange-Red
        AccentSecondary = Color3.fromRGB(217, 74, 42),   -- #D94A2A Hover/Active

        BorderSubtle    = Color3.fromRGB(40, 40, 40),    -- #282828
        BorderStrong    = Color3.fromRGB(58, 58, 58),    -- #3A3A3A

        StatusSuccess   = Color3.fromRGB(123, 203, 123), -- #7BCB7B
        StatusWarning   = Color3.fromRGB(229, 184, 90),  -- #E5B85A
        StatusError     = Color3.fromRGB(214, 90, 90)    -- #D65A5A
    },

    Typography = {
        FontMain = Enum.Font.SourceSans,
        FontBold = Enum.Font.SourceSansBold,
        FontMono = Enum.Font.Code,

        SizeH1   = 28,
        SizeH2   = 20,
        SizeH3   = 12, -- UPPERCASE Section / Sidebar Category
        SizeBody = 14,
        SizeDesc = 12,
        SizeMeta = 10, -- UPPERCASE Keycap / FPS / Tags
        SizeBtn  = 13  -- UPPERCASE Button text
    },

    Spacing = {
        Space1 = 4,   -- Icon & Text gap, tight padding
        Space2 = 8,   -- Standard inner padding
        Space3 = 12,  -- Control gap
        Space4 = 16,  -- Section padding
        Space5 = 24,  -- Window inner padding
        Space6 = 32   -- Section / Group separator
    },

    Sizing = {
        Xs = 20,
        Sm = 28,
        Md = 36,
        Lg = 44
    },

    Geometry = {
        Level0 = UDim.new(0, 0), -- Sharp: Window border, Divider, Sidebar, Keycap base
        Level1 = UDim.new(0, 2), -- Subtle: Input line, Tooltip, Menu items
        Level2 = UDim.new(0, 4), -- Soft: Button, Switches, Tabs
        Level3 = UDim.new(0, 8)  -- Rounded: Modal, Popups
    },

    Motion = {
        Mechanical = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Spatial    = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Soft       = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        Instant    = TweenInfo.new(0.05, Enum.EasingStyle.Linear)
    }
}

local function Tween(instance, tweenInfo, properties)
    if not instance then return end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

--------------------------------------------------------------------------------
-- 2. NOTIFICATION SYSTEM (Anti-AI Floating Panel)
--------------------------------------------------------------------------------

local NotifyContainer = nil

local function EnsureNotifyContainer()
    if NotifyContainer and NotifyContainer.Parent then return end

    local parent = RunService:IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    local sg = parent:FindFirstChild("AntiAiNotifyGui")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "AntiAiNotifyGui"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        sg.Parent = parent
    end

    local holder = Instance.new("Frame")
    holder.Name = "NotifyHolder"
    holder.Size = UDim2.new(0, 280, 1, -40)
    holder.Position = UDim2.new(1, -300, 0, 20)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, Library.Tokens.Spacing.Space2)
    layout.Parent = holder

    NotifyContainer = holder
end

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "SYSTEM"
    local desc = options.Description or ""
    local notifyType = options.Type or "Info" -- Success, Warning, Error, Info
    local duration = options.Duration or 3.5

    EnsureNotifyContainer()

    local typeColor = Library.Tokens.Colors.AccentPrimary
    if notifyType == "Success" then typeColor = Library.Tokens.Colors.StatusSuccess
    elseif notifyType == "Warning" then typeColor = Library.Tokens.Colors.StatusWarning
    elseif notifyType == "Error" then typeColor = Library.Tokens.Colors.StatusError end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Library.Tokens.Colors.BgElevated
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Position = UDim2.new(1, 50, 0, 0) -- Slide in start offset

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Library.Tokens.Geometry.Level1
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.Tokens.Colors.BorderSubtle
    stroke.Thickness = 1
    stroke.Parent = card

    -- Left Status Line
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 2, 1, 0)
    line.Position = UDim2.new(0, 0, 0, 0)
    line.BackgroundColor3 = typeColor
    line.BorderSizePixel = 0
    line.Parent = card

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -12, 1, 0)
    contentFrame.Position = UDim2.new(0, 10, 0, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = contentFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = string.upper(title)
    titleLbl.Font = Library.Tokens.Typography.FontBold
    titleLbl.TextSize = Library.Tokens.Typography.SizeDesc
    titleLbl.TextColor3 = Library.Tokens.Colors.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(1, 0, 0, 14)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = contentFrame

    if desc ~= "" then
        local descLbl = Instance.new("TextLabel")
        descLbl.Text = desc
        descLbl.Font = Library.Tokens.Typography.FontMain
        descLbl.TextSize = Library.Tokens.Typography.SizeDesc
        descLbl.TextColor3 = Library.Tokens.Colors.TextSecondary
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.TextWrapped = true
        descLbl.AutomaticSize = Enum.AutomaticSize.Y
        descLbl.Size = UDim2.new(1, 0, 0, 0)
        descLbl.BackgroundTransparency = 1
        descLbl.Parent = contentFrame
    end

    card.Parent = NotifyContainer

    -- Slide in motion
    Tween(card, Library.Tokens.Motion.Soft, {Position = UDim2.new(0, 0, 0, 0)})

    if duration > 0 then
        task.delay(duration, function()
            local tw = Tween(card, Library.Tokens.Motion.Soft, {Position = UDim2.new(1, 50, 0, 0)})
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
-- 3. WINDOW FRAME & CORE LAYOUT
--------------------------------------------------------------------------------

function Library.CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "FRAMEWORK"
    local windowSubtitle = config.Subtitle or "v2.0 ANTI-AI SPEC"
    local size = config.Size or UDim2.new(0, 720, 0, 480)

    local parent = RunService:IsStudio() and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "AntiAiMainGui"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 100
    sg.Parent = parent

    -- Outer Window Base (Level 0 Sharp Edge)
    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = size
    window.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    window.BackgroundColor3 = Library.Tokens.Colors.BgBase
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = sg

    local windowStroke = Instance.new("UIStroke")
    windowStroke.Color = Library.Tokens.Colors.BorderSubtle
    windowStroke.Thickness = 1
    windowStroke.Parent = window

    ----------------------------------------------------------------------------
    -- HEADER (48px Height, Merged with Sidebar L-Shape Zone)
    ----------------------------------------------------------------------------
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = Library.Tokens.Colors.BgSurface
    header.BorderSizePixel = 0
    header.Parent = window

    -- L-Shape Brand Zone (Sidebar Header Integration)
    local brandZone = Instance.new("Frame")
    brandZone.Name = "BrandZone"
    brandZone.Size = UDim2.new(0, 200, 1, 0)
    brandZone.BackgroundColor3 = Library.Tokens.Colors.BgSurface
    brandZone.BorderSizePixel = 0
    brandZone.Parent = header

    local brandPadding = Instance.new("UIPadding")
    brandPadding.PaddingLeft = UDim.new(0, 16)
    brandPadding.PaddingRight = UDim.new(0, 16)
    brandPadding.Parent = brandZone

    local brandLayout = Instance.new("UIListLayout")
    brandLayout.FillDirection = Enum.FillDirection.Horizontal
    brandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    brandLayout.Padding = UDim.new(0, 8)
    brandLayout.Parent = brandZone

    -- Accent Brand Indicator
    local brandDot = Instance.new("Frame")
    brandDot.Size = UDim2.new(0, 6, 0, 6)
    brandDot.BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
    brandDot.BorderSizePixel = 0
    brandDot.Parent = brandZone

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = string.upper(windowTitle)
    titleLbl.Font = Library.Tokens.Typography.FontBold
    titleLbl.TextSize = Library.Tokens.Typography.SizeBody
    titleLbl.TextColor3 = Library.Tokens.Colors.TextPrimary
    titleLbl.AutomaticSize = Enum.AutomaticSize.X
    titleLbl.Size = UDim2.new(0, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = brandZone

    local subLbl = Instance.new("TextLabel")
    subLbl.Text = string.upper(windowSubtitle)
    subLbl.Font = Library.Tokens.Typography.FontMain
    subLbl.TextSize = Library.Tokens.Typography.SizeMeta
    subLbl.TextColor3 = Library.Tokens.Colors.TextTertiary
    subLbl.AutomaticSize = Enum.AutomaticSize.X
    subTitleLbl = subLbl
    subLbl.Size = UDim2.new(0, 0, 1, 0)
    subLbl.BackgroundTransparency = 1
    subLbl.Parent = brandZone

    -- Header Controls (Right side)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(1, -200, 1, 0)
    controlsFrame.Position = UDim2.new(0, 200, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    local ctrlPadding = Instance.new("UIPadding")
    ctrlPadding.PaddingRight = UDim.new(0, 12)
    ctrlPadding.Parent = controlsFrame

    local ctrlLayout = Instance.new("UIListLayout")
    ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
    ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ctrlLayout.Padding = UDim.new(0, 4)
    ctrlLayout.Parent = controlsFrame

    local function CreateControlBtn(iconText, isClose)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.BackgroundTransparency = 1
        btn.Text = iconText
        btn.Font = Library.Tokens.Typography.FontBold
        btn.TextSize = 14
        btn.TextColor3 = Library.Tokens.Colors.TextTertiary
        btn.AutoButtonColor = false
        btn.Parent = controlsFrame

        btn.MouseEnter:Connect(function()
            Tween(btn, Library.Tokens.Motion.Mechanical, {
                TextColor3 = isClose and Library.Tokens.Colors.StatusError or Library.Tokens.Colors.TextPrimary
            })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, Library.Tokens.Motion.Mechanical, {
                TextColor3 = Library.Tokens.Colors.TextTertiary
            })
        end)
        return btn
    end

    local minBtn = CreateControlBtn("-", false)
    local closeBtn = CreateControlBtn("×", true)

    ----------------------------------------------------------------------------
    -- BODY (SIDEBAR RAIL & CONTENT AREA)
    ----------------------------------------------------------------------------
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, -48)
    body.Position = UDim2.new(0, 0, 0, 48)
    body.BackgroundTransparency = 1
    body.Parent = window

    -- Navigation Rail Sidebar (200px width expanded, no border, brightness contrast)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 200, 1, 0)
    sidebar.BackgroundColor3 = Library.Tokens.Colors.BgSurface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = body

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 12)
    sidebarPadding.PaddingLeft = UDim.new(0, 0)
    sidebarPadding.PaddingRight = UDim.new(0, 0)
    sidebarPadding.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 2)
    tabListLayout.Parent = sidebar

    -- Main Content Area (--bg-base)
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -200, 1, 0)
    contentContainer.Position = UDim2.new(0, 200, 0, 0)
    contentContainer.BackgroundColor3 = Library.Tokens.Colors.BgBase
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = body

    -- Window Dragging Mechanism
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

    -- Control Actions
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        body.Visible = not isMinimized
        Tween(window, Library.Tokens.Motion.Mechanical, {
            Size = isMinimized and UDim2.new(size.X.Scale, size.X.Offset, 0, 48) or size
        })
    end)

    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    ----------------------------------------------------------------------------
    -- TAB NAVIGATION RAIL SYSTEM
    ----------------------------------------------------------------------------
    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
        Gui = sg,
        MainFrame = window
    }

    function WindowObj:CreateTab(tabName)
        -- Navigation Rail Item (NO CAPSULE BACKGROUND!)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "NavRail_" .. tabName
        tabBtn.Size = UDim2.new(1, 0, 0, 36)
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = sidebar

        -- 2px Vertical Accent Indicator Line (Left Side)
        local activeLine = Instance.new("Frame")
        activeLine.Size = UDim2.new(0, 2, 0, 16)
        activeLine.Position = UDim2.new(0, 0, 0.5, -8)
        activeLine.BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
        activeLine.BorderSizePixel = 0
        activeLine.BackgroundTransparency = 1
        activeLine.Parent = tabBtn

        local label = Instance.new("TextLabel")
        label.Text = tabName
        label.Font = Library.Tokens.Typography.FontMain
        label.TextSize = Library.Tokens.Typography.SizeBody
        label.TextColor3 = Library.Tokens.Colors.TextSecondary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Size = UDim2.new(1, -24, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)
        label.BackgroundTransparency = 1
        label.Parent = tabBtn

        -- Page Canvas
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = Library.Tokens.Colors.BorderStrong
        page.Visible = false
        page.Parent = contentContainer

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop = UDim.new(0, Library.Tokens.Spacing.Space5)
        pagePad.PaddingBottom = UDim.new(0, Library.Tokens.Spacing.Space5)
        pagePad.PaddingLeft = UDim.new(0, Library.Tokens.Spacing.Space5)
        pagePad.PaddingRight = UDim.new(0, Library.Tokens.Spacing.Space5)
        pagePad.Parent = page

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, Library.Tokens.Spacing.Space6) -- 32px between sections
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
                local line = t.Button:FindFirstChild("Frame")
                local lbl = t.Button:FindFirstChild("TextLabel")
                if line then Tween(line, Library.Tokens.Motion.Instant, {BackgroundTransparency = 1}) end
                if lbl then
                    lbl.Font = Library.Tokens.Typography.FontMain
                    Tween(lbl, Library.Tokens.Motion.Instant, {TextColor3 = Library.Tokens.Colors.TextSecondary})
                end
            end

            page.Visible = true
            WindowObj.ActiveTab = TabObj
            Tween(activeLine, Library.Tokens.Motion.Mechanical, {BackgroundTransparency = 0})
            label.Font = Library.Tokens.Typography.FontBold
            Tween(label, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextPrimary})
        end

        tabBtn.MouseButton1Click:Connect(Activate)

        tabBtn.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(label, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextPrimary})
            end
        end)

        tabBtn.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(label, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextSecondary})
            end
        end)

        if #WindowObj.Tabs == 0 then
            Activate()
        end

        table.insert(WindowObj.Tabs, TabObj)

        ------------------------------------------------------------------------
        -- SECTION & UN-CARDED COMPONENT CREATOR
        ------------------------------------------------------------------------
        function TabObj:CreateSection(secTitle)
            local secGroup = Instance.new("Frame")
            secGroup.Name = "Group_" .. secTitle
            secGroup.Size = UDim2.new(1, 0, 0, 0)
            secGroup.AutomaticSize = Enum.AutomaticSize.Y
            secGroup.BackgroundTransparency = 1
            secGroup.Parent = page

            local secLayout = Instance.new("UIListLayout")
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Padding = UDim.new(0, Library.Tokens.Spacing.Space3)
            secLayout.Parent = secGroup

            if secTitle and secTitle ~= "" then
                local groupTitleLbl = Instance.new("TextLabel")
                groupTitleLbl.Text = string.upper(secTitle)
                groupTitleLbl.Font = Library.Tokens.Typography.FontBold
                groupTitleLbl.TextSize = Library.Tokens.Typography.SizeH3
                groupTitleLbl.TextColor3 = Library.Tokens.Colors.TextTertiary
                groupTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                groupTitleLbl.Size = UDim2.new(1, 0, 0, 16)
                groupTitleLbl.BackgroundTransparency = 1
                groupTitleLbl.Parent = secGroup
            end

            local SectionObj = {}

            --------------------------------------------------------------------
            -- 1. BUTTON (Primary, Secondary, Ghost, Icon)
            --------------------------------------------------------------------
            function SectionObj:CreateButton(options)
                options = options or {}
                local text = options.Text or "ACTION"
                local style = options.Style or "Secondary" -- Primary, Secondary, Ghost
                local callback = options.Callback or function() end

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, Library.Tokens.Sizing.Md)
                btn.Font = Library.Tokens.Typography.FontBold
                btn.TextSize = Library.Tokens.Typography.SizeBtn
                btn.Text = string.upper(text)
                btn.AutoButtonColor = false
                btn.Parent = secGroup

                local corner = Instance.new("UICorner")
                corner.CornerRadius = Library.Tokens.Geometry.Level2 -- 4px
                corner.Parent = btn

                local stroke = Instance.new("UIStroke")
                stroke.Thickness = 1
                stroke.Parent = btn

                if style == "Primary" then
                    btn.BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
                    btn.TextColor3 = Library.Tokens.Colors.TextInverse
                    stroke.Transparency = 1
                elseif style == "Secondary" then
                    btn.BackgroundColor3 = Library.Tokens.Colors.BgElevated
                    btn.TextColor3 = Library.Tokens.Colors.TextPrimary
                    stroke.Color = Library.Tokens.Colors.BorderSubtle
                else -- Ghost
                    btn.BackgroundTransparency = 1
                    btn.TextColor3 = Library.Tokens.Colors.TextSecondary
                    stroke.Transparency = 1
                end

                btn.MouseEnter:Connect(function()
                    if style == "Primary" then
                        Tween(btn, Library.Tokens.Motion.Mechanical, {BackgroundColor3 = Library.Tokens.Colors.AccentSecondary})
                    elseif style == "Secondary" then
                        Tween(btn, Library.Tokens.Motion.Mechanical, {BorderColor3 = Library.Tokens.Colors.BorderStrong})
                    else
                        Tween(btn, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextPrimary})
                    end
                end)

                btn.MouseLeave:Connect(function()
                    if style == "Primary" then
                        Tween(btn, Library.Tokens.Motion.Mechanical, {BackgroundColor3 = Library.Tokens.Colors.AccentPrimary})
                    elseif style == "Secondary" then
                        Tween(btn, Library.Tokens.Motion.Mechanical, {BorderColor3 = Library.Tokens.Colors.BorderSubtle})
                    else
                        Tween(btn, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextSecondary})
                    end
                end)

                -- Press feedback: Inset color tweak, NO scaling!
                btn.MouseButton1Down:Connect(function()
                    if style == "Primary" then
                        btn.BackgroundColor3 = Library.Tokens.Colors.AccentSecondary
                    else
                        btn.BackgroundColor3 = Library.Tokens.Colors.BgInput
                    end
                end)

                btn.MouseButton1Up:Connect(function()
                    if style == "Primary" then
                        btn.BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
                    else
                        btn.BackgroundColor3 = (style == "Secondary") and Library.Tokens.Colors.BgElevated or Color3.fromRGB(0,0,0)
                    end
                    callback()
                end)

                return btn
            end

            --------------------------------------------------------------------
            -- 2. LINE TOGGLE (Specification: 24x2px Track, 10px Handle Dot)
            --------------------------------------------------------------------
            function SectionObj:CreateToggle(options)
                options = options or {}
                local text = options.Text or "Toggle Control"
                local defaultState = options.Default or false
                local callback = options.Callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 24)
                row.BackgroundTransparency = 1
                row.Parent = secGroup

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Tokens.Colors.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(1, -40, 1, 0)
                label.BackgroundTransparency = 1
                label.Parent = row

                -- Track: 24px wide, 2px high line
                local track = Instance.new("TextButton")
                track.Size = UDim2.new(0, 24, 0, 2)
                track.Position = UDim2.new(1, -24, 0.5, -1)
                track.BackgroundColor3 = defaultState and Library.Tokens.Colors.AccentPrimary or Library.Tokens.Colors.BorderSubtle
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = row

                -- Handle: 10px diameter dot
                local handle = Instance.new("Frame")
                handle.Size = UDim2.new(0, 10, 0, 10)
                handle.Position = defaultState and UDim2.new(1, -5, 0.5, -5) or UDim2.new(0, -5, 0.5, -5)
                handle.BackgroundColor3 = defaultState and Library.Tokens.Colors.TextInverse or Library.Tokens.Colors.TextTertiary
                handle.BorderSizePixel = 0
                handle.Parent = track

                local hCorner = Instance.new("UICorner")
                hCorner.CornerRadius = UDim.new(1, 0)
                hCorner.Parent = handle

                local state = defaultState

                local function SetState(val)
                    state = (val ~= nil) and val or not state
                    local targetPos = state and UDim2.new(1, -5, 0.5, -5) or UDim2.new(0, -5, 0.5, -5)
                    local trackColor = state and Library.Tokens.Colors.AccentPrimary or Library.Tokens.Colors.BorderSubtle
                    local handleColor = state and Library.Tokens.Colors.TextInverse or Library.Tokens.Colors.TextTertiary

                    Tween(handle, Library.Tokens.Motion.Mechanical, {Position = targetPos, BackgroundColor3 = handleColor})
                    Tween(track, Library.Tokens.Motion.Mechanical, {BackgroundColor3 = trackColor})
                    callback(state)
                end

                track.MouseButton1Click:Connect(function() SetState() end)

                local clickDetector = Instance.new("TextButton")
                clickDetector.Size = UDim2.new(1, 0, 1, 0)
                clickDetector.BackgroundTransparency = 1
                clickDetector.Text = ""
                clickDetector.Parent = row
                clickDetector.MouseButton1Click:Connect(function() SetState() end)

                return {
                    Set = function(self, val) SetState(val) end,
                    Value = state
                }
            end

            --------------------------------------------------------------------
            -- 3. SLIDER (Specification: 2px Line Track, Value Header)
            --------------------------------------------------------------------
            function SectionObj:CreateSlider(options)
                options = options or {}
                local text = options.Text or "Slider Parameter"
                local min = options.Min or 0
                local max = options.Max or 100
                local defaultVal = options.Default or min
                local decimals = options.Decimals or 0
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, 32)
                container.BackgroundTransparency = 1
                container.Parent = secGroup

                -- Header: Label (Left) + Value (Right)
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = text
                nameLbl.Font = Library.Tokens.Typography.FontMain
                nameLbl.TextSize = Library.Tokens.Typography.SizeBody
                nameLbl.TextColor3 = Library.Tokens.Colors.TextPrimary
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Size = UDim2.new(0.7, 0, 0, 16)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Parent = container

                local valLbl = Instance.new("TextLabel")
                valLbl.Text = tostring(defaultVal)
                valLbl.Font = Library.Tokens.Typography.FontMono
                valLbl.TextSize = Library.Tokens.Typography.SizeDesc
                valLbl.TextColor3 = Library.Tokens.Colors.TextSecondary
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Size = UDim2.new(0.3, 0, 0, 16)
                valLbl.Position = UDim2.new(0.7, 0, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Parent = container

                -- Track Line: 2px High
                local track = Instance.new("TextButton")
                track.Size = UDim2.new(1, 0, 0, 2)
                track.Position = UDim2.new(0, 0, 0, 24)
                track.BackgroundColor3 = Library.Tokens.Colors.BorderSubtle
                track.Text = ""
                track.AutoButtonColor = false
                track.Parent = container

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((defaultVal - min)/(max - min), 0, 1, 0)
                fill.BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
                fill.BorderSizePixel = 0
                fill.Parent = track

                -- Thumb Dot: 12px Diameter
                local thumb = Instance.new("Frame")
                thumb.Size = UDim2.new(0, 12, 0, 12)
                thumb.Position = UDim2.new(1, -6, 0.5, -6)
                thumb.BackgroundColor3 = Library.Tokens.Colors.TextPrimary
                thumb.BorderSizePixel = 0
                thumb.Parent = fill

                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(1, 0)
                tCorner.Parent = thumb

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
                        Tween(track, Library.Tokens.Motion.Mechanical, {Size = UDim2.new(1, 0, 0, 3)})
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
                        Tween(track, Library.Tokens.Motion.Mechanical, {Size = UDim2.new(1, 0, 0, 2)})
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
            -- 4. LINE INPUT (Specification: Minimal Horizontal Line, Focus Accent)
            --------------------------------------------------------------------
            function SectionObj:CreateTextbox(options)
                options = options or {}
                local text = options.Text or "Input Field"
                local placeholder = options.Placeholder or "Type here..."
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, 42)
                container.BackgroundTransparency = 1
                container.Parent = secGroup

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Tokens.Colors.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Parent = container

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, 0, 0, 20)
                box.Position = UDim2.new(0, 0, 0, 18)
                box.BackgroundTransparency = 1
                box.PlaceholderText = placeholder
                box.PlaceholderColor3 = Library.Tokens.Colors.TextTertiary
                box.Text = ""
                box.TextColor3 = Library.Tokens.Colors.TextPrimary
                box.Font = Library.Tokens.Typography.FontMain
                box.TextSize = Library.Tokens.Typography.SizeBody
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.ClearTextOnFocus = false
                box.Parent = container

                -- Horizontal Focus Line
                local inputLine = Instance.new("Frame")
                inputLine.Size = UDim2.new(1, 0, 0, 1)
                inputLine.Position = UDim2.new(0, 0, 1, -1)
                inputLine.BackgroundColor3 = Library.Tokens.Colors.BorderSubtle
                inputLine.BorderSizePixel = 0
                inputLine.Parent = container

                box.Focused:Connect(function()
                    Tween(inputLine, Library.Tokens.Motion.Mechanical, {
                        Size = UDim2.new(1, 0, 0, 2),
                        BackgroundColor3 = Library.Tokens.Colors.AccentPrimary
                    })
                end)

                box.FocusLost:Connect(function(enterPressed)
                    Tween(inputLine, Library.Tokens.Motion.Mechanical, {
                        Size = UDim2.new(1, 0, 0, 1),
                        BackgroundColor3 = Library.Tokens.Colors.BorderSubtle
                    })
                    callback(box.Text, enterPressed)
                end)

                return box
            end

            --------------------------------------------------------------------
            -- 5. DROPDOWN (Specification: Un-carded Label + Value ›)
            --------------------------------------------------------------------
            function SectionObj:CreateDropdown(options)
                options = options or {}
                local text = options.Text or "Select Option"
                local items = options.Items or {}
                local defaultItem = options.Default or items[1]
                local callback = options.Callback or function() end

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 0, 28)
                container.BackgroundTransparency = 1
                container.ClipsDescendants = true
                container.Parent = secGroup

                local mainBtn = Instance.new("TextButton")
                mainBtn.Size = UDim2.new(1, 0, 0, 28)
                mainBtn.BackgroundTransparency = 1
                mainBtn.Text = ""
                mainBtn.Parent = container

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Tokens.Colors.TextSecondary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(0.5, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Parent = mainBtn

                local valFrame = Instance.new("Frame")
                valFrame.Size = UDim2.new(0.5, 0, 1, 0)
                valFrame.Position = UDim2.new(0.5, 0, 0, 0)
                valFrame.BackgroundTransparency = 1
                valFrame.Parent = mainBtn

                local valLayout = Instance.new("UIListLayout")
                valLayout.FillDirection = Enum.FillDirection.Horizontal
                valLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                valLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                valLayout.Padding = UDim.new(0, 4)
                valLayout.Parent = valFrame

                local valLbl = Instance.new("TextLabel")
                valLbl.Text = tostring(defaultItem or "None")
                valLbl.Font = Library.Tokens.Typography.FontMain
                valLbl.TextSize = Library.Tokens.Typography.SizeBody
                valLbl.TextColor3 = Library.Tokens.Colors.TextPrimary
                valLbl.AutomaticSize = Enum.AutomaticSize.X
                valLbl.Size = UDim2.new(0, 0, 1, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Parent = valFrame

                local arrow = Instance.new("TextLabel")
                arrow.Text = "›"
                arrow.Font = Library.Tokens.Typography.FontBold
                arrow.TextSize = 14
                arrow.TextColor3 = Library.Tokens.Colors.TextTertiary
                arrow.Size = UDim2.new(0, 10, 1, 0)
                arrow.BackgroundTransparency = 1
                arrow.Parent = valFrame

                -- Popup List Container
                local listFrame = Instance.new("Frame")
                listFrame.Size = UDim2.new(1, 0, 0, #items * 26)
                listFrame.Position = UDim2.new(0, 0, 0, 28)
                listFrame.BackgroundColor3 = Library.Tokens.Colors.BgElevated
                listFrame.BorderSizePixel = 0
                listFrame.Parent = container

                local listCorner = Instance.new("UICorner")
                listCorner.CornerRadius = Library.Tokens.Geometry.Level1
                listCorner.Parent = listFrame

                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent = listFrame

                local isOpen = false

                for _, item in ipairs(items) do
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Size = UDim2.new(1, 0, 0, 26)
                    itemBtn.BackgroundTransparency = 1
                    itemBtn.Text = "  " .. tostring(item)
                    itemBtn.TextColor3 = (item == defaultItem) and Library.Tokens.Colors.AccentPrimary or Library.Tokens.Colors.TextSecondary
                    itemBtn.Font = Library.Tokens.Typography.FontMain
                    itemBtn.TextSize = Library.Tokens.Typography.SizeDesc
                    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    itemBtn.AutoButtonColor = false
                    itemBtn.Parent = listFrame

                    itemBtn.MouseEnter:Connect(function()
                        Tween(itemBtn, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextPrimary})
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        if valLbl.Text ~= tostring(item) then
                            Tween(itemBtn, Library.Tokens.Motion.Mechanical, {TextColor3 = Library.Tokens.Colors.TextSecondary})
                        end
                    end)

                    itemBtn.MouseButton1Click:Connect(function()
                        valLbl.Text = tostring(item)
                        isOpen = false
                        Tween(container, Library.Tokens.Motion.Spatial, {Size = UDim2.new(1, 0, 0, 28)})
                        Tween(arrow, Library.Tokens.Motion.Mechanical, {Rotation = 0})
                        callback(item)
                    end)
                end

                mainBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    local targetH = isOpen and (28 + #items * 26 + 4) or 28
                    Tween(container, Library.Tokens.Motion.Spatial, {Size = UDim2.new(1, 0, 0, targetH)})
                    Tween(arrow, Library.Tokens.Motion.Mechanical, {Rotation = isOpen and 90 or 0})
                end)

                return {
                    Select = function(self, val)
                        valLbl.Text = tostring(val)
                        callback(val)
                    end
                }
            end

            --------------------------------------------------------------------
            -- 6. KEYBIND (Specification: Sharp Keycap, 20px Height)
            --------------------------------------------------------------------
            function SectionObj:CreateKeybind(options)
                options = options or {}
                local text = options.Text or "Keybind Action"
                local defaultKey = options.Default or Enum.KeyCode.E
                local callback = options.Callback or function() end

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 24)
                row.BackgroundTransparency = 1
                row.Parent = secGroup

                local label = Instance.new("TextLabel")
                label.Text = text
                label.Font = Library.Tokens.Typography.FontMain
                label.TextSize = Library.Tokens.Typography.SizeBody
                label.TextColor3 = Library.Tokens.Colors.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(1, -80, 1, 0)
                label.BackgroundTransparency = 1
                label.Parent = row

                -- Keycap (Level 0 Sharp Corner, 20px Height)
                local keycap = Instance.new("TextButton")
                keycap.Size = UDim2.new(0, 60, 0, 20)
                keycap.Position = UDim2.new(1, -60, 0.5, -10)
                keycap.BackgroundColor3 = Library.Tokens.Colors.BgElevated
                keycap.Text = string.upper(defaultKey.Name)
                keycap.Font = Library.Tokens.Typography.FontBold
                keycap.TextSize = Library.Tokens.Typography.SizeMeta
                keycap.TextColor3 = Library.Tokens.Colors.TextPrimary
                keycap.AutoButtonColor = false
                keycap.Parent = row

                local stroke = Instance.new("UIStroke")
                stroke.Color = Library.Tokens.Colors.BorderSubtle
                stroke.Thickness = 1
                stroke.Parent = keycap

                local currentKey = defaultKey
                local listening = false

                keycap.MouseButton1Click:Connect(function()
                    listening = true
                    keycap.Text = "PRESS..."
                    Tween(stroke, Library.Tokens.Motion.Mechanical, {Color = Library.Tokens.Colors.BorderStrong})
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and not gpe then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            keycap.Text = string.upper(currentKey.Name)
                            listening = false
                            Tween(stroke, Library.Tokens.Motion.Mechanical, {Color = Library.Tokens.Colors.BorderSubtle})
                            callback(currentKey)
                        end
                    end
                end)

                return keycap
            end

            return SectionObj
        end

        return TabObj
    end

    return WindowObj
end

return Library