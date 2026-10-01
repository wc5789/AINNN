-- VapeLiteUI | Roblox UI Library

--[[
    VapeLiteUI - A compact, dark-themed Roblox UI library inspired by the
    Vape Lite client menu.

    Highlights:
      * PC and Mobile support (mouse + touch input)
      * Draggable, minimizable floating window
      * Tabs, Sections, and a full set of controls
      * Stacking notifications in the top-right corner
      * Optional config saving (requires exploit file API)
      * No images, no emoji, text-only UI
]]

-- ============================================================
-- SERVICES
-- ============================================================
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background    = Color3.fromRGB(22, 22, 26),
    Surface       = Color3.fromRGB(30, 30, 35),
    SurfaceAlt    = Color3.fromRGB(26, 26, 30),
    SurfaceHover  = Color3.fromRGB(36, 36, 42),
    SurfacePress  = Color3.fromRGB(42, 42, 50),
    Accent        = Color3.fromRGB(120, 140, 255),
    AccentDim     = Color3.fromRGB(72, 84, 153),
    Border        = Color3.fromRGB(48, 48, 56),
    Text          = Color3.fromRGB(230, 230, 235),
    TextDim       = Color3.fromRGB(140, 140, 150),
    TextMuted     = Color3.fromRGB(90, 90, 100),
    Track         = Color3.fromRGB(58, 58, 66),
    Knob          = Color3.fromRGB(235, 235, 240),
    Row           = Color3.fromRGB(28, 28, 33),
    RowHover      = Color3.fromRGB(36, 36, 42),
    Input         = Color3.fromRGB(20, 20, 24),
    Danger        = Color3.fromRGB(220, 85, 85),
    Font          = Enum.Font.Gotham,
    FontMedium    = Enum.Font.GothamMedium,
    FontSemi      = Enum.Font.GothamSemibold,
    Radius        = 8,
    RadiusSmall   = 4,
    RowHeight     = 26,
}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local Connections = {}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    Connections[#Connections + 1] = connection
    return connection
end

-- ============================================================
-- UTILITIES
-- ============================================================
local function Create(class, props)
    local instance = Instance.new(class)
    if props then
        for key, value in next, props do
            instance[key] = value
        end
    end
    return instance
end

local function Tween(object, duration, props, style, direction)
    local info = TweenInfo.new(
        duration or 0.15,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, props)
    tween:Play()
    return tween
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or Theme.RadiusSmall),
        Parent = parent,
    })
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function Padding(parent, t, r, b, l)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft   = UDim.new(0, l or r or t or 0),
        Parent = parent,
    })
end

local function GetViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

--- Make a frame draggable by a handle, clamped to the viewport.
local function AddDragging(handle, target)
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local viewport = GetViewport()
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, viewport.X - target.AbsoluteSize.X))
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - target.AbsoluteSize.Y))
            target.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

--- Resolve the best available GUI parent (gethui -> CoreGui).
local function GetGuiParent()
    local ok, result = pcall(function()
        if gethui then
            return gethui()
        end
        return nil
    end)
    if ok and result then
        return result
    end
    return CoreGui
end

--- Protect the GUI from script-watchers when an exploit API is available.
local function ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)
end

local function SafeCall(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[VapeLiteUI] Callback error: " .. tostring(err))
    end
end

-- ============================================================
-- LIBRARY
-- ============================================================
local Library = {}
Library.__index = Library
Library.Version  = "1.0.0"
Library.Theme    = Theme
Library._elements = {}
Library._windows  = {}
Library._notifications = {}
Library._activeNotifs  = {}

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function Library:CreateWindow(config)
    config = config or {}

    local title       = config.Title or "VapeLite"
    local size        = config.Size or UDim2.new(0, 520, 0, 360)
    local toggleKey   = config.ToggleKey or Enum.KeyCode.RightControl
    local canSaveCfg  = config.ConfigSaving and type(writefile) == "function"

    local width  = size.X.Offset
    local height = size.Y.Offset

    local gui = Create("ScreenGui", {
        Name = "VapeLiteUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    ProtectGui(gui)
    gui.Parent = GetGuiParent()

    -- ---- MAIN CONTAINER ----
    local viewport = GetViewport()
    local startX = math.floor((viewport.X - width) / 2)
    local startY = math.floor((viewport.Y - height) / 2)

    local main = Create("Frame", {
        Name = "Main",
        Parent = gui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(0, startX, 0, startY),
        Size = UDim2.new(0, math.floor(width * 0.95), 0, math.floor(height * 0.95)),
        BackgroundTransparency = 0.05,
    })
    Corner(main, Theme.Radius)
    Stroke(main, Theme.Border, 1)

    -- ---- TOP BAR ----
    local topBar = Create("Frame", {
        Name = "TopBar",
        Parent = main,
        BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
    })
    Corner(topBar, Theme.Radius)

    local topBarMask = Create("Frame", {
        Name = "TopBarMask",
        Parent = topBar,
        BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
    })

    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.FontSemi,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    })

    -- Minimize button
    local minBtn = Create("TextButton", {
        Name = "Minimize",
        Parent = topBar,
        BackgroundColor3 = Theme.SurfaceAlt,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -56, 0, 0),
        Size = UDim2.new(0, 28, 0, 36),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })

    local minLine = Create("Frame", {
        Name = "Line",
        Parent = minBtn,
        BackgroundColor3 = Theme.TextDim,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 1),
    })

    Connect(minBtn.MouseEnter, function()
        Tween(minLine, 0.1, { BackgroundColor3 = Theme.Text })
    end)
    Connect(minBtn.MouseLeave, function()
        Tween(minLine, 0.1, { BackgroundColor3 = Theme.TextDim })
    end)

    -- Close button
    local closeBtn = Create("TextButton", {
        Name = "Close",
        Parent = topBar,
        BackgroundColor3 = Theme.SurfaceAlt,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0, 0),
        Size = UDim2.new(0, 28, 0, 36),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })

    local closeLine1 = Create("Frame", {
        Parent = closeBtn,
        BackgroundColor3 = Theme.TextDim,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 9, 0, 1),
        Rotation = 45,
    })
    local closeLine2 = Create("Frame", {
        Parent = closeBtn,
        BackgroundColor3 = Theme.TextDim,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 9, 0, 1),
        Rotation = -45,
    })

    Connect(closeBtn.MouseEnter, function()
        Tween(closeLine1, 0.1, { BackgroundColor3 = Theme.Danger })
        Tween(closeLine2, 0.1, { BackgroundColor3 = Theme.Danger })
    end)
    Connect(closeBtn.MouseLeave, function()
        Tween(closeLine1, 0.1, { BackgroundColor3 = Theme.TextDim })
        Tween(closeLine2, 0.1, { BackgroundColor3 = Theme.TextDim })
    end)

    -- ---- SIDEBAR ----
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = main,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(0, 130, 1, -36),
    })

    local sidebarContent = Create("Frame", {
        Name = "Content",
        Parent = sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })

    Create("UIListLayout", {
        Parent = sidebarContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    Padding(sidebarContent, 8, 0, 8, 0)

    -- Separator line between sidebar and content
    local separator = Create("Frame", {
        Name = "Separator",
        Parent = main,
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 130, 0, 36),
        Size = UDim2.new(0, 1, 1, -36),
    })

    -- ---- CONTENT AREA ----
    local contentHolder = Create("Frame", {
        Name = "ContentHolder",
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 131, 0, 36),
        Size = UDim2.new(1, -131, 1, -36),
    })

    -- ================================================
    -- WINDOW OBJECT
    -- ================================================
    local window = {}
    window.Tabs = {}
    window._gui = gui
    window._main = main
    window._title = title
    window._size = UDim2.new(0, width, 0, height)
    window._toggleKey = toggleKey
    window._minimized = false
    window._visible = true
    window._configSaving = canSaveCfg

    -- Animations
    Tween(main, 0.15, {
        Size = UDim2.new(0, width, 0, height),
    }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    AddDragging(topBar, main)

    -- ---- Minimize Toggle ----
    local function setMinimized(state)
        window._minimized = state
        if state then
            window._preMinSize = main.Size
            window._preMinPos  = main.Position
            Tween(main, 0.15, { Size = UDim2.new(0, 120, 0, 28) })
            sidebar.Visible = false
            contentHolder.Visible = false
            separator.Visible = false
            topBarMask.Visible = false
            topBar.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.Text = "Menu"
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
            titleLabel.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Center
            minBtn.Visible = false
            closeBtn.Visible = false
        else
            Tween(main, 0.15, { Size = window._size })
            sidebar.Visible = true
            contentHolder.Visible = true
            separator.Visible = true
            topBarMask.Visible = true
            topBar.Size = UDim2.new(1, 0, 0, 36)
            titleLabel.Text = window._title
            titleLabel.Position = UDim2.new(0, 14, 0, 0)
            titleLabel.Size = UDim2.new(1, -60, 1, 0)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            minBtn.Visible = true
            closeBtn.Visible = true
        end
    end

    Connect(minBtn.MouseButton1Click, function()
        setMinimized(true)
    end)
    Connect(topBar.InputBegan, function(input)
        if window._minimized
            and (input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch) then
            -- Detect click (not drag): restore on quick tap
            local startPos = input.Position
            local moved = false
            local conn
            conn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement
                    or moveInput.UserInputType == Enum.UserInputType.Touch then
                    if (moveInput.Position - startPos).Magnitude > 4 then
                        moved = true
                    end
                end
            end)
            task.delay(0.05, function()
                if not moved then
                    setMinimized(false)
                end
            end)
            UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1
                    or endInput.UserInputType == Enum.UserInputType.Touch then
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    -- ---- Close (hide) ----
    Connect(closeBtn.MouseButton1Click, function()
        window:Hide()
    end)

    -- ---- Toggle key ----
    Connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == window._toggleKey then
            if window._visible then
                window:Hide()
            else
                window:Show()
            end
        end
    end)

    -- ================================================
    -- WINDOW METHODS
    -- ================================================
    function window:Hide()
        window._visible = false
        Tween(main, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, descendant in ipairs(main:GetDescendants()) do
            if descendant:IsA("GuiObject") and descendant.BackgroundTransparency < 1 then
                descendant.BackgroundTransparency = 1
            end
        end
        task.delay(0.2, function()
            main.Visible = false
        end)
    end

    function window:Show()
        window._visible = true
        main.Visible = true
        Tween(main, 0.2, { BackgroundTransparency = 0.05 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        sidebar.BackgroundTransparency = 0
        topBar.BackgroundTransparency = 0
        topBarMask.BackgroundTransparency = 0
    end

    function window:SetToggleKey(key)
        window._toggleKey = key
    end

    function window:SetTitle(newTitle)
        window._title = newTitle
        if not window._minimized then
            titleLabel.Text = newTitle
        end
    end

    function window:Minimize()
        setMinimized(true)
    end

    function window:Restore()
        setMinimized(false)
    end

    -- ================================================
    -- CREATE TAB
    -- ================================================
    function window:CreateTab(name)
        local tab = {}
        tab.Name = name
        tab.Sections = {}
        tab._window = window
        tab._order = 0
        tab._index = #window.Tabs + 1

        table.insert(window.Tabs, tab)

        -- ---- Sidebar tab button ----
        local tabBtn = Create("TextButton", {
            Name = name .. "Tab",
            Parent = sidebarContent,
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 28),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = tab._index,
        })
        Corner(tabBtn, Theme.RadiusSmall)

        local indicator = Create("Frame", {
            Name = "Indicator",
            Parent = tabBtn,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 3, 0, 0),
        })
        Corner(indicator, 2)

        local tabLabel = Create("TextLabel", {
            Name = "Label",
            Parent = tabBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(1, -14, 1, 0),
            Font = Theme.Font,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        -- ---- Content scroll frame ----
        local scroll = Create("ScrollingFrame", {
            Name = name .. "Content",
            Parent = contentHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Border,
            ScrollBarImageTransparency = 0.3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            Visible = false,
            ClipsDescendants = true,
        })
        Padding(scroll, 10, 10, 10, 10)
        Create("UIListLayout", {
            Parent = scroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 14),
        })

        tab._scroll = scroll
        tab._btn = tabBtn
        tab._indicator = indicator
        tab._label = tabLabel

        -- ---- Tab switching ----
        local function selectTab()
            for _, otherTab in ipairs(window.Tabs) do
                otherTab._scroll.Visible = false
                otherTab._label.TextColor3 = Theme.TextDim
                otherTab._btn.BackgroundTransparency = 1
                Tween(otherTab._indicator, 0.15, { Size = UDim2.new(0, 3, 0, 0) })
            end

            scroll.Visible = true
            tabLabel.TextColor3 = Theme.Text
            tabBtn.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = Theme.SurfaceHover
            Tween(indicator, 0.15, { Size = UDim2.new(0, 3, 0, 16) })

            -- Content fade-in via transparency ping (visual polish)
            local fade = Create("Frame", {
                Parent = scroll,
                BackgroundColor3 = Theme.Background,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 50,
            })
            Tween(fade, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(0.15, function()
                fade:Destroy()
            end)
        end

        Connect(tabBtn.MouseEnter, function()
            if not scroll.Visible then
                tabBtn.BackgroundTransparency = 0.5
                tabBtn.BackgroundColor3 = Theme.SurfaceHover
            end
        end)
        Connect(tabBtn.MouseLeave, function()
            if not scroll.Visible then
                tabBtn.BackgroundTransparency = 1
            end
        end)
        Connect(tabBtn.MouseButton1Click, selectTab)

        -- Auto-select first tab
        if tab._index == 1 then
            task.defer(selectTab)
        end

        -- ================================================
        -- TAB METHODS
        -- ================================================
        function tab:CreateSection(sectionName)
            local section = {}
            section.Name = sectionName
            section.Elements = {}
            section._tab = tab
            section._order = 0
            section._index = #tab.Sections + 1

            table.insert(tab.Sections, section)

            local sectionFrame = Create("Frame", {
                Name = sectionName .. "Section",
                Parent = scroll,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = section._index,
            })
            Create("UIListLayout", {
                Parent = sectionFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            })

            local header = Create("TextLabel", {
                Name = "Header",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Theme.FontSemi,
                Text = string.upper(sectionName),
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
            })

            local holder = Create("Frame", {
                Name = "Holder",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 2,
            })
            Create("UIListLayout", {
                Parent = holder,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            })

            section._frame = sectionFrame
            section._holder = holder

            local function nextOrder()
                section._order = section._order + 1
                return section._order
            end

            local function makeRow(height)
                local row = Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, height),
                    LayoutOrder = nextOrder(),
                })
                Corner(row, Theme.RadiusSmall)
                return row
            end

            local function registerElement(id, api)
                api._id = sectionName .. "/" .. id
                table.insert(Library._elements, api)
                return api
            end

            -- ========================================
            -- SECTION: BUTTON
            -- ========================================
            function section:CreateButton(cfg)
                cfg = cfg or {}
                local row = makeRow(Theme.RowHeight)

                local btn = Create("TextButton", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    AutoButtonColor = false,
                })

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Theme.FontMedium,
                    Text = cfg.Name or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                })

                Connect(btn.MouseEnter, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                end)
                Connect(btn.MouseLeave, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                end)
                Connect(btn.MouseButton1Click, function()
                    Tween(row, 0.06, { BackgroundColor3 = Theme.SurfacePress })
                    task.delay(0.08, function()
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end)
                    task.spawn(SafeCall, cfg.Callback)
                end)

                local api = {
                    Instance = btn,
                    Value = nil,
                    Set = function() end,
                }
                return registerElement((cfg.Name or "Button") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: LABEL
            -- ========================================
            function section:CreateLabel(cfg)
                cfg = cfg or {}
                local row = makeRow(Theme.RowHeight)

                local label = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Label",
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local api = {
                    Instance = label,
                    Value = cfg.Name,
                    Set = function(_, text)
                        label.Text = text
                    end,
                }
                return registerElement((cfg.Name or "Label") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: DIVIDER
            -- ========================================
            function section:CreateDivider(cfg)
                cfg = cfg or {}
                local row = Create("Frame", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 9),
                    LayoutOrder = nextOrder(),
                })

                local line = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                if cfg.Text and cfg.Text ~= "" then
                    local text = Create("TextLabel", {
                        Parent = row,
                        BackgroundColor3 = Theme.Background,
                        BorderSizePixel = 0,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 80, 1, 0),
                        Font = Theme.FontSemi,
                        Text = string.upper(cfg.Text),
                        TextColor3 = Theme.TextMuted,
                        TextSize = 10,
                    })
                    text.BackgroundTransparency = 1
                end

                return { Instance = row }
            end

            -- ========================================
            -- SECTION: TOGGLE
            -- ========================================
            function section:CreateToggle(cfg)
                cfg = cfg or {}
                local state = cfg.Default and true or false

                local row = makeRow(Theme.RowHeight)

                local btn = Create("TextButton", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    AutoButtonColor = false,
                })

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                -- Track
                local track = Create("Frame", {
                    Parent = btn,
                    BackgroundColor3 = Theme.Track,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 32, 0, 16),
                    ZIndex = 2,
                })
                Corner(track, 8)

                -- Knob
                local knob = Create("Frame", {
                    Parent = track,
                    BackgroundColor3 = Theme.Knob,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    ZIndex = 3,
                })
                Corner(knob, 6)

                local function applyState(animated)
                    local duration = animated and 0.15 or 0
                    if state then
                        Tween(track, duration, { BackgroundColor3 = Theme.Accent })
                        Tween(knob, duration, { Position = UDim2.new(1, -14, 0.5, 0) })
                    else
                        Tween(track, duration, { BackgroundColor3 = Theme.Track })
                        Tween(knob, duration, { Position = UDim2.new(0, 2, 0.5, 0) })
                    end
                end

                applyState(false)

                Connect(btn.MouseEnter, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                end)
                Connect(btn.MouseLeave, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                end)
                Connect(btn.MouseButton1Click, function()
                    state = not state
                    applyState(true)
                    task.spawn(SafeCall, cfg.Callback, state)
                end)

                local api = {
                    Instance = btn,
                    Value = state,
                    Set = function(self, value, silent)
                        local changed = state ~= (value and true or false)
                        state = value and true or false
                        self.Value = state
                        applyState(true)
                        if changed and not silent then
                            task.spawn(SafeCall, cfg.Callback, state)
                        end
                    end,
                    Toggle = function(self)
                        self:Set(not state)
                    end,
                }
                return registerElement((cfg.Name or "Toggle") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: SLIDER
            -- ========================================
            function section:CreateSlider(cfg)
                cfg = cfg or {}
                local min  = cfg.Min or 0
                local max  = cfg.Max or 100
                local val  = math.clamp(cfg.Default or min, min, max)
                local suffix = cfg.Suffix or ""
                local dragging = false

                local row = makeRow(46)

                local label = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 2),
                    Size = UDim2.new(0.6, 0, 0, 22),
                    Font = Theme.Font,
                    Text = cfg.Name or "Slider",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local valueLabel = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.6, 0, 0, 2),
                    Size = UDim2.new(0.4, -10, 0, 22),
                    Font = Theme.FontMedium,
                    Text = tostring(val) .. suffix,
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })

                local track = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.Track,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 30),
                    Size = UDim2.new(1, -20, 0, 4),
                })
                Corner(track, 2)

                local fill = Create("Frame", {
                    Parent = track,
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
                })
                Corner(fill, 2)

                local knob = Create("Frame", {
                    Parent = track,
                    BackgroundColor3 = Theme.Knob,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.new(0, 10, 0, 10),
                    ZIndex = 2,
                })
                Corner(knob, 5)

                local function setVisual(alpha)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    valueLabel.Text = tostring(val) .. suffix
                end

                local function setValue(newVal, fire)
                    local clamped = math.clamp(math.floor(newVal + 0.5), min, max)
                    local changed = clamped ~= val
                    val = clamped
                    setVisual((val - min) / (max - min))
                    if changed and fire then
                        task.spawn(SafeCall, cfg.Callback, val)
                    end
                end

                local function updateFromInput(input)
                    local alpha = math.clamp(
                        (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
                        0, 1
                    )
                    setValue(min + (max - min) * alpha, true)
                end

                Connect(row.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        updateFromInput(input)
                    end
                end)
                Connect(UserInputService.InputChanged, function(input)
                    if dragging then
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                            or input.UserInputType == Enum.UserInputType.Touch then
                            updateFromInput(input)
                        end
                    end
                end)
                Connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                local api = {
                    Instance = row,
                    Value = val,
                    Set = function(self, value, silent)
                        setValue(value, not silent)
                        self.Value = val
                    end,
                }
                return registerElement((cfg.Name or "Slider") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: DROPDOWN
            -- ========================================
            function section:CreateDropdown(cfg)
                cfg = cfg or {}
                local options = cfg.Options or {}
                local selected = cfg.Default or options[1]
                local expanded = false
                local collapsedH = 28
                local itemH = 24
                local visibleCount = math.min(#options, 4)
                local listH = visibleCount * (itemH + 2) + 6

                local row = Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    Size = UDim2.new(1, 0, 0, collapsedH),
                    LayoutOrder = nextOrder(),
                })
                Corner(row, Theme.RadiusSmall)

                local btn = Create("TextButton", {
                    Parent = row,
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, collapsedH),
                    Text = "",
                    AutoButtonColor = false,
                })

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Dropdown",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local valueLabel = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.55, 0, 0, 0),
                    Size = UDim2.new(0.45, -26, 1, 0),
                    Font = Theme.FontMedium,
                    Text = tostring(selected),
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })

                local arrow = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 12, 1, 0),
                    Font = Theme.FontSemi,
                    Text = "v",
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })

                local listFrame = Create("ScrollingFrame", {
                    Parent = row,
                    BackgroundColor3 = Theme.SurfaceAlt,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 4, 0, collapsedH + 2),
                    Size = UDim2.new(1, -8, 0, listH),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Theme.Border,
                    ScrollBarImageTransparency = 0.4,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ElasticBehavior = Enum.ElasticBehavior.Never,
                    Visible = false,
                })
                Corner(listFrame, Theme.RadiusSmall)
                Padding(listFrame, 3)
                Create("UIListLayout", {
                    Parent = listFrame,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                })

                local itemApis = {}

                local function collapse()
                    expanded = false
                    listFrame.Visible = false
                    Tween(row, 0.15, { Size = UDim2.new(1, 0, 0, collapsedH) })
                    Tween(arrow, 0.15, { Rotation = 0 })
                end

                local function expand()
                    expanded = true
                    listFrame.Visible = true
                    Tween(row, 0.15, { Size = UDim2.new(1, 0, 0, collapsedH + listH + 4) })
                    Tween(arrow, 0.15, { Rotation = 180 })
                end

                for i, option in ipairs(options) do
                    local item = Create("TextButton", {
                        Parent = listFrame,
                        BackgroundColor3 = Theme.SurfaceAlt,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, itemH),
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = i,
                    })
                    Corner(item, Theme.RadiusSmall)

                    local itemLabel = Create("TextLabel", {
                        Parent = item,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 8, 0, 0),
                        Size = UDim2.new(1, -16, 1, 0),
                        Font = Theme.Font,
                        Text = tostring(option),
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    Connect(item.MouseEnter, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceHover })
                    end)
                    Connect(item.MouseLeave, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceAlt })
                    end)
                    Connect(item.MouseButton1Click, function()
                        selected = option
                        valueLabel.Text = tostring(option)
                        collapse()
                        task.spawn(SafeCall, cfg.Callback, option)
                    end)

                    itemApis[i] = { option = option, instance = item }
                end

                Connect(btn.MouseEnter, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end
                end)
                Connect(btn.MouseLeave, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.Row })
                    end
                end)
                Connect(btn.MouseButton1Click, function()
                    if expanded then
                        collapse()
                    else
                        expand()
                    end
                end)

                local api = {
                    Instance = row,
                    Value = selected,
                    Options = options,
                    Set = function(self, value, silent)
                        for _, item in ipairs(itemApis) do
                            if item.option == value then
                                selected = value
                                self.Value = value
                                valueLabel.Text = tostring(value)
                                if not silent then
                                    task.spawn(SafeCall, cfg.Callback, value)
                                end
                                return
                            end
                        end
                    end,
                }
                return registerElement((cfg.Name or "Dropdown") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: KEYBIND
            -- ========================================
            function section:CreateKeybind(cfg)
                cfg = cfg or {}
                local currentKey = cfg.Default
                local capturing = false

                local row = makeRow(Theme.RowHeight)

                local btn = Create("TextButton", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    AutoButtonColor = false,
                })

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Keybind",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local keyLabel = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.6, 0, 0, 0),
                    Size = UDim2.new(0.4, -10, 1, 0),
                    Font = Theme.FontMedium,
                    Text = currentKey and currentKey.Name or "None",
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })

                local function stopCapture()
                    capturing = false
                    keyLabel.TextColor3 = Theme.TextDim
                    if not currentKey then
                        keyLabel.Text = "None"
                    end
                end

                local captureConn
                Connect(btn.MouseButton1Click, function()
                    if capturing then
                        capturing = false
                        if captureConn then captureConn:Disconnect() end
                        keyLabel.TextColor3 = Theme.TextDim
                        keyLabel.Text = currentKey and currentKey.Name or "None"
                        return
                    end

                    capturing = true
                    keyLabel.Text = "..."
                    keyLabel.TextColor3 = Theme.Accent

                    captureConn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        local ut = input.UserInputType
                        if ut == Enum.UserInputType.MouseButton1
                            or ut == Enum.UserInputType.MouseButton2
                            or ut == Enum.UserInputType.MouseMovement
                            or ut == Enum.UserInputType.MouseWheel then
                            return
                        end

                        if input.KeyCode == Enum.KeyCode.Backspace
                            or input.KeyCode == Enum.KeyCode.Delete then
                            currentKey = nil
                            keyLabel.Text = "None"
                        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentKey = input.KeyCode
                            keyLabel.Text = input.KeyCode.Name
                        end

                        stopCapture()
                        if captureConn then captureConn:Disconnect() end
                        task.spawn(SafeCall, cfg.Callback, currentKey)
                    end)
                end)

                -- Global key trigger
                Connect(UserInputService.InputBegan, function(input, processed)
                    if processed then return end
                    if capturing then return end
                    if currentKey and input.KeyCode == currentKey then
                        task.spawn(SafeCall, cfg.Callback, currentKey)
                    end
                end)

                Connect(btn.MouseEnter, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                end)
                Connect(btn.MouseLeave, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                end)

                local api = {
                    Instance = row,
                    Value = currentKey,
                    Set = function(self, key)
                        currentKey = key
                        self.Value = key
                        keyLabel.Text = key and key.Name or "None"
                    end,
                }
                return registerElement((cfg.Name or "Keybind") .. "_" .. tostring(#section.Elements + 1), api)
            end

            -- ========================================
            -- SECTION: TEXTBOX
            -- ========================================
            function section:CreateTextbox(cfg)
                cfg = cfg or {}
                local row = makeRow(Theme.RowHeight + 6)

                local label = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Text",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local inputFrame = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.Input,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 120, 0, 22),
                })
                Corner(inputFrame, Theme.RadiusSmall)
                Stroke(inputFrame, Theme.Border, 1, 0.4)

                local textbox = Create("TextBox", {
                    Parent = inputFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 6, 0, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Default or "",
                    PlaceholderText = cfg.Placeholder or "...",
                    PlaceholderColor3 = Theme.TextMuted,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                })

                Connect(textbox.Focused, function()
                    Tween(inputFrame, 0.12, { BackgroundColor3 = Theme.SurfaceHover })
                end)
                Connect(textbox.FocusLost, function(enterPressed)
                    Tween(inputFrame, 0.12, { BackgroundColor3 = Theme.Input })
                    if enterPressed then
                        task.spawn(SafeCall, cfg.Callback, textbox.Text)
                        if cfg.ClearOnSubmit then
                            textbox.Text = ""
                        end
                    end
                end)

                local api = {
                    Instance = textbox,
                    Value = cfg.Default or "",
                    Set = function(self, value)
                        textbox.Text = tostring(value)
                        self.Value = tostring(value)
                    end,
                }
                return registerElement((cfg.Name or "Textbox") .. "_" .. tostring(#section.Elements + 1), api)
            end

            return section
        end

        return tab
    end

    -- ================================================
    -- WINDOW: Config
    -- ================================================
    function window:SaveConfig(name)
        if not window._configSaving then
            warn("[VapeLiteUI] Config saving is not available in this environment.")
            return
        end
        local data = {}
        for _, element in ipairs(Library._elements) do
            local value = element.Value
            local t = typeof(value)
            if t == "boolean" or t == "number" or t == "string" then
                data[element._id] = { type = t, value = value }
            elseif t == "EnumItem" then
                data[element._id] = { type = "EnumItem", value = value.Name, enum = tostring(value.EnumType) }
            end
        end
        local ok, err = pcall(function()
            writefile("VapeLiteUI_" .. name .. ".json", HttpService:JSONEncode(data))
        end)
        if not ok then
            warn("[VapeLiteUI] SaveConfig failed: " .. tostring(err))
        end
    end

    function window:LoadConfig(name)
        if not window._configSaving then
            warn("[VapeLiteUI] Config loading is not available in this environment.")
            return
        end
        local ok, contents = pcall(readfile, "VapeLiteUI_" .. name .. ".json")
        if not ok or not contents then
            warn("[VapeLiteUI] LoadConfig failed: file not found.")
            return
        end
        local decoded
        local decodeOk = pcall(function()
            decoded = HttpService:JSONDecode(contents)
        end)
        if not decodeOk or not decoded then
            warn("[VapeLiteUI] LoadConfig failed: invalid JSON.")
            return
        end
        for _, element in ipairs(Library._elements) do
            local saved = decoded[element._id]
            if saved and element.Set then
                if saved.type == "EnumItem" then
                    local enumOk, enumItem = pcall(function()
                        return Enum[saved.enum][saved.value]
                    end)
                    if enumOk then
                        element:Set(enumItem, true)
                    end
                else
                    element:Set(saved.value, true)
                end
            end
        end
    end

    -- ================================================
    -- WINDOW: Destroy
    -- ================================================
    function window:Destroy()
        for _, conn in ipairs(Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(Connections)
        if gui then
            gui:Destroy()
        end
        for i = #Library._windows, 1, -1 do
            if Library._windows[i] == window then
                table.remove(Library._windows, i)
            end
        end
    end

    table.insert(Library._windows, window)
    return window
end

-- ============================================================
-- LIBRARY: NOTIFICATIONS
-- ============================================================
local function RelayoutNotifications()
    for index, notif in ipairs(Library._activeNotifs) do
        Tween(notif.frame, 0.2, {
            Position = UDim2.new(1, -16, 0, 16 + (index - 1) * 78),
        })
    end
end

--- Display a notification in the top-right corner.
--- @param title string
--- @param content string
--- @param duration number|nil  seconds before auto-dismiss (default 4)
function Library:Notify(title, content, duration)
    if not self._gui or not self._gui.Parent then
        warn("[VapeLiteUI] No active window to host the notification.")
        return
    end
    duration = duration or 4

    -- Cap to 4 visible notifications
    while #self._activeNotifs >= 4 do
        local oldest = table.remove(self._activeNotifs, 1)
        if oldest and oldest.frame and oldest.frame.Parent then
            oldest.frame:Destroy()
        end
    end

    local holder = Create("Frame", {
        Name = "Notification",
        Parent = self._gui,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, -80),
        Size = UDim2.new(0, 260, 0, 70),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.05,
    })
    Corner(holder, Theme.Radius)
    Stroke(holder, Theme.Border, 1)

    -- Accent bar
    local accentBar = Create("Frame", {
        Parent = holder,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 1, -12),
    })
    Corner(accentBar, 2)

    local titleLabel = Create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -20, 0, 16),
        Font = Theme.FontSemi,
        Text = tostring(title or "Notification"),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local bodyLabel = Create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -20, 0, 38),
        Font = Theme.Font,
        Text = tostring(content or ""),
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    })

    local entry = { frame = holder, title = titleLabel, body = bodyLabel }
    table.insert(self._activeNotifs, entry)
    RelayoutNotifications()

    -- Dismiss logic
    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        Tween(holder, 0.18, { BackgroundTransparency = 1 })
        Tween(accentBar, 0.18, { BackgroundTransparency = 1 })
        Tween(titleLabel, 0.18, { TextTransparency = 1 })
        Tween(bodyLabel, 0.18, { TextTransparency = 1 })
        task.delay(0.2, function()
            if holder and holder.Parent then
                holder:Destroy()
            end
            for i = #Library._activeNotifs, 1, -1 do
                if Library._activeNotifs[i] == entry then
                    table.remove(Library._activeNotifs, i)
                end
            end
            RelayoutNotifications()
        end)
    end

    Connect(holder.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    if duration > 0 then
        task.delay(duration, dismiss)
    end

    return entry
end

-- ============================================================
-- LIBRARY: DESTROY
-- ============================================================
--- Fully destroy the library, disconnect all connections and remove the GUI.
function Library:Destroy()
    for _, window in ipairs(self._windows) do
        pcall(function() window:Destroy() end)
    end
    table.clear(self._windows)
    table.clear(self._elements)
    table.clear(self._activeNotifs)

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
end

-- ============================================================
-- LIBRARY: SetToggleKey (global default)
-- ============================================================
function Library:SetToggleKey(key)
    for _, window in ipairs(self._windows) do
        window:SetToggleKey(key)
    end
end

-- ============================================================
-- LIBRARY: IsMobile helper
-- ============================================================
function Library:IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end


return Library