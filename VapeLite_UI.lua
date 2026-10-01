-- VapeLiteUI | Roblox UI Library

--[[
    VapeLiteUI - A compact, dark-themed Roblox UI library inspired by the
    Vape Lite client menu.

    Highlights:
      * PC and Mobile support (mouse + touch input)
      * Draggable, resizable, minimizable floating window
      * Sidebar tabs + live element search
      * Collapsible sections
      * Tabs, Sections, and a full set of controls:
        Button, Toggle, Slider, Dropdown, MultiDropdown,
        Keybind (Toggle/Hold), TextBox, ColorPicker, Label,
        Paragraph, Divider, Progress
      * Tooltips via the Description field on any element
      * Confirm-mode buttons for destructive actions
      * Stacking typed notifications in the top-right corner
      * Optional draggable watermark
      * Optional config saving (requires exploit file API)
      * Compact icon slots using configurable text glyphs (no external image dependency)
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
    -- Deliberately restrained: Vape's visual language is dark, flat and compact.
    Background    = Color3.fromRGB(15, 15, 17),
    Surface       = Color3.fromRGB(18, 18, 21),
    SurfaceAlt    = Color3.fromRGB(20, 20, 23),
    SurfaceHover  = Color3.fromRGB(34, 34, 39),
    SurfacePress  = Color3.fromRGB(42, 42, 48),
    Accent        = Color3.fromRGB(48, 125, 235),
    AccentDim     = Color3.fromRGB(31, 86, 164),
    Border        = Color3.fromRGB(28, 28, 32),
    Text          = Color3.fromRGB(232, 232, 235),
    TextDim       = Color3.fromRGB(136, 136, 143),
    TextMuted     = Color3.fromRGB(96, 96, 104),
    Track         = Color3.fromRGB(55, 55, 61),
    Knob          = Color3.fromRGB(242, 242, 246),
    Row           = Color3.fromRGB(34, 34, 38),
    RowHover      = Color3.fromRGB(39, 39, 44),
    Input         = Color3.fromRGB(22, 22, 25),
    Danger        = Color3.fromRGB(225, 80, 92),
    Success       = Color3.fromRGB(70, 205, 125),
    Warning       = Color3.fromRGB(235, 178, 75),
    Info          = Color3.fromRGB(35, 125, 245),
    Font          = Enum.Font.Gotham,
    FontMedium    = Enum.Font.GothamMedium,
    FontSemi      = Enum.Font.GothamSemibold,
    Radius        = 2,
    RadiusSmall   = 1,
    RowHeight     = 40,
    IconSize      = 40,
}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local Connections = {}

--- Connect a signal and track it for cleanup.
--- @param signal RBXScriptSignal
--- @param callback function
--- @return RBXScriptConnection
local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    Connections[#Connections + 1] = connection
    return connection
end

-- ============================================================
-- UTILITIES
-- ============================================================
--- Instance.new with a property table.
--- @param class string
--- @param props table|nil
--- @return Instance
local function Create(class, props)
    local instance = Instance.new(class)
    if props then
        for key, value in next, props do
            instance[key] = value
        end
    end
    return instance
end

--- Tween shorthand. Defaults to Quad/Out.
--- @param object Instance
--- @param duration number
--- @param props table
--- @param style Enum.EasingStyle|nil
--- @param direction Enum.EasingDirection|nil
--- @return Tween
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

--- Add a UICorner to a parent.
local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or Theme.RadiusSmall),
        Parent = parent,
    })
end

--- Add a UIStroke to a parent.
local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

--- Add UIPadding to a parent.
local function Padding(parent, t, r, b, l)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft   = UDim.new(0, l or r or t or 0),
        Parent = parent,
    })
end

--- Trim whitespace from both ends of a string.
local function Trim(text)
    return string.match(text or "", "^%s*(.-)%s*$")
end

--- Current viewport size with a sane fallback.
local function GetViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

--- Make a frame draggable by a handle, clamped to the viewport.
--- @param handle GuiObject
--- @param target GuiObject
local function AddDragging(handle, target, registrar)
    local bind = registrar or Connect
    local dragging = false
    local dragInput, dragStart, startPos

    bind(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            bind(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    bind(handle.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    bind(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local viewport = GetViewport()
            local baseX = startPos.X.Offset + delta.X
            local baseY = startPos.Y.Offset + delta.Y
            local absoluteX = viewport.X * startPos.X.Scale + baseX
            local absoluteY = viewport.Y * startPos.Y.Scale + baseY
            local minX = target.AnchorPoint.X * target.AbsoluteSize.X
            local minY = target.AnchorPoint.Y * target.AbsoluteSize.Y
            local maxX = viewport.X - (1 - target.AnchorPoint.X) * target.AbsoluteSize.X
            local maxY = viewport.Y - (1 - target.AnchorPoint.Y) * target.AbsoluteSize.Y
            absoluteX = math.clamp(absoluteX, minX, math.max(minX, maxX))
            absoluteY = math.clamp(absoluteY, minY, math.max(minY, maxY))
            target.Position = UDim2.new(0, absoluteX, 0, absoluteY)
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

--- Invoke a user callback without breaking the UI.
local function SafeCall(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[VapeLiteUI] Callback error: " .. tostring(err))
    end
end

--- Attach a hover tooltip to a row. Shown above the row after a short delay.
--- @param hostRow GuiObject
--- @param text string|nil
local function AttachTooltip(hostRow, text)
    if not text or text == "" then return end
    local tip = Create("TextLabel", {
        Name = "Tooltip",
        Parent = hostRow,
        BackgroundColor3 = Theme.SurfaceHover,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, -26),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Theme.Font,
        Text = "  " .. tostring(text) .. "  ",
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        ZIndex = 90,
    })
    Corner(tip, Theme.RadiusSmall)
    Stroke(tip, Theme.Border, 1)

    local token = 0
    Connect(hostRow.MouseEnter, function()
        token = token + 1
        local myToken = token
        task.delay(0.5, function()
            if myToken == token and hostRow.Visible then
                tip.Visible = true
            end
        end)
    end)
    Connect(hostRow.MouseLeave, function()
        token = token + 1
        tip.Visible = false
    end)
end

-- ============================================================
-- LIBRARY
-- ============================================================
local VapeLiteUI = {}
VapeLiteUI.__index = VapeLiteUI
VapeLiteUI.Version      = "3.1.0"
VapeLiteUI.Theme        = Theme
VapeLiteUI._elements    = {}
VapeLiteUI._windows     = {}
VapeLiteUI._search      = {}
VapeLiteUI._activeNotifs = {}
VapeLiteUI._gui         = nil
VapeLiteUI._watermark   = nil
VapeLiteUI._watermarkConnections = {}

-- ============================================================
-- CREATE WINDOW
-- ============================================================
--- Create the main Vape Lite window.
--- @param config table|nil { Title, Size, ToggleKey, MinSize, ConfigSaving, ConfigFolder, ConfigName, AutoLoadConfig, Footer }
--- @return table window
function VapeLiteUI:CreateWindow(config)
    config = config or {}

    local title       = config.Title or "VapeLite"
    local requestedSize = config.Size or UDim2.new(0, 680, 0, 430)
    local toggleKey   = config.ToggleKey or Enum.KeyCode.RightControl
    local touchDevice = UserInputService.TouchEnabled
    local viewportNow = GetViewport()
    local mobileMode  = touchDevice and viewportNow.X <= 900
    local defaultMin  = mobileMode and Vector2.new(300, 250) or Vector2.new(460, 300)
    local minSize     = config.MinSize or defaultMin
    local canSaveCfg  = config.ConfigSaving and type(writefile) == "function" and type(readfile) == "function"
    local cfgFolder   = config.ConfigFolder or "VapeLiteUI"

    -- Create the window object before any UI controls register callbacks.
    -- Lua local scope does not include declarations that appear later in the function.
    local window = {}
    window.Tabs = {}
    window._connections = {}
    window._animationToken = 0
    window._destroyed = false

    local function WindowConnect(signal, callback)
        local connection = signal:Connect(callback)
        window._connections[#window._connections + 1] = connection
        return connection
    end

    local function DisconnectWindowConnections()
        for i = #window._connections, 1, -1 do
            pcall(function() window._connections[i]:Disconnect() end)
            window._connections[i] = nil
        end
    end
    local cfgName     = config.ConfigName or "default"
    local autoLoad    = config.AutoLoadConfig and canSaveCfg
    local showFooter  = config.Footer ~= false and not mobileMode

    local requestedWidth  = requestedSize.X.Offset
    local requestedHeight = requestedSize.Y.Offset
    local width  = mobileMode
        and math.min(requestedWidth, math.max(300, viewportNow.X - 10))
        or math.min(requestedWidth, math.max(460, viewportNow.X - 32))
    local height = mobileMode
        and math.min(requestedHeight, math.max(260, viewportNow.Y - 28))
        or math.min(requestedHeight, math.max(300, viewportNow.Y - 32))
    local footerH = showFooter and 26 or 0
    -- Reference proportions: a narrow navigation rail and a dense module list.
    local topBarH = mobileMode and 30 or 32
    local sidebarW = mobileMode
        and math.clamp(math.floor(viewportNow.X * 0.25), 78, 96)
        or math.clamp(math.floor(viewportNow.X * 0.215), 116, 136)

    local gui = Create("ScreenGui", {
        Name = "VapeLiteUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    ProtectGui(gui)
    gui.Parent = GetGuiParent()
    self._gui = gui

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
        Size = UDim2.new(0, width, 0, height),
        BackgroundTransparency = 0,
    })
    Corner(main, Theme.Radius)
    Stroke(main, Theme.Border, 1, 0.25)

    -- ---- TOP BAR ----
    local topBar = Create("Frame", {
        Name = "TopBar",
        Parent = main,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, topBarH),
    })
    Corner(topBar, Theme.Radius)

    Create("Frame", {
        Name = "TopBarMask",
        Parent = topBar,
        BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
    })

    local dragArea = Create("Frame", {
        Name = "DragArea",
        Parent = topBar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -72, 1, 0),
        ZIndex = 1,
    })

    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.FontSemi,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    })

    -- Minimize button
    local minBtn = Create("TextButton", {
        Name = "Minimize",
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -64, 0, 0),
        Size = UDim2.new(0, 32, 0, topBarH),
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
    WindowConnect(minBtn.MouseEnter, function()
        Tween(minLine, 0.1, { BackgroundColor3 = Theme.Text })
    end)
    WindowConnect(minBtn.MouseLeave, function()
        Tween(minLine, 0.1, { BackgroundColor3 = Theme.TextDim })
    end)

    -- Close button
    local closeBtn = Create("TextButton", {
        Name = "Close",
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -32, 0, 0),
        Size = UDim2.new(0, 32, 0, topBarH),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
    })
    local closeLines = {}
    for i = 1, 2 do
        closeLines[i] = Create("Frame", {
            Parent = closeBtn,
            BackgroundColor3 = Theme.TextDim,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 9, 0, 1),
            Rotation = i == 1 and 45 or -45,
        })
    end
    WindowConnect(closeBtn.MouseEnter, function()
        Tween(closeLines[1], 0.1, { BackgroundColor3 = Theme.Danger })
        Tween(closeLines[2], 0.1, { BackgroundColor3 = Theme.Danger })
    end)
    WindowConnect(closeBtn.MouseLeave, function()
        Tween(closeLines[1], 0.1, { BackgroundColor3 = Theme.TextDim })
        Tween(closeLines[2], 0.1, { BackgroundColor3 = Theme.TextDim })
    end)

    -- ---- SIDEBAR ----
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = main,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, topBarH),
        Size = UDim2.new(0, sidebarW, 1, -(topBarH + footerH)),
    })

    -- Search box
    local searchHolder = Create("Frame", {
        Name = "SearchHolder",
        Parent = sidebar,
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 7),
        Size = UDim2.new(1, -16, 0, mobileMode and 25 or 24),
    })
    Corner(searchHolder, Theme.RadiusSmall)
    Stroke(searchHolder, Theme.Border, 1, 0.65)

    local searchBox = Create("TextBox", {
        Parent = searchHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Theme.Font,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.TextMuted,
        TextColor3 = Theme.Text,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })

    local sidebarContent = Create("Frame", {
        Name = "Content",
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, mobileMode and 39 or 38),
        Size = UDim2.new(1, 0, 1, -(mobileMode and 39 or 38)),
    })
    Create("UIListLayout", {
        Parent = sidebarContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    Padding(sidebarContent, 8, 0, 8, 0)

    -- Separator between sidebar and content
    local separator = Create("Frame", {
        Name = "Separator",
        Parent = main,
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, sidebarW, 0, topBarH),
        Size = UDim2.new(0, 1, 1, -(topBarH + footerH)),
    })

    -- ---- CONTENT AREA ----
    local contentHolder = Create("Frame", {
        Name = "ContentHolder",
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarW + 1, 0, topBarH),
        Size = UDim2.new(1, -(sidebarW + 1), 1, -(topBarH + footerH)),
    })

    -- ---- FOOTER ----
    local statusLabel
    if showFooter then
        local footer = Create("Frame", {
            Name = "Footer",
            Parent = main,
            BackgroundColor3 = Theme.SurfaceAlt,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, footerH),
        })
        Create("Frame", {
            Parent = footer,
            BackgroundColor3 = Theme.SurfaceAlt,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 8),
        })
        statusLabel = Create("TextLabel", {
            Parent = footer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 0),
            Size = UDim2.new(0.6, 0, 1, 0),
            Font = Theme.Font,
            Text = "Ready",
            TextColor3 = Theme.TextMuted,
            TextSize = mobileMode and 11 or 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        Create("TextLabel", {
            Parent = footer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.6, 0, 0, 0),
            Size = UDim2.new(0.4, -14, 1, 0),
            Font = Theme.Font,
            Text = "v" .. VapeLiteUI.Version,
            TextColor3 = Theme.TextMuted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
    end

    -- ---- RESIZE GRIP ----
    local resizeGrip = Create("TextButton", {
        Name = "ResizeGrip",
        Parent = main,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Text = "",
        ZIndex = 6,
        Visible = not mobileMode,
    })
    local gripLines = {}
    for i = 1, 3 do
        gripLines[i] = Create("Frame", {
            Parent = resizeGrip,
            BackgroundColor3 = Theme.TextMuted,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -2 - (i - 1) * 4, 1, -2 - (i - 1) * 4),
            Size = UDim2.new(0, 7, 0, 1),
            Rotation = -45,
            ZIndex = 6,
        })
    end

    -- ================================================
    -- WINDOW OBJECT
    -- ================================================
    window._gui = gui
    window._main = main
    window._title = title
    window._size = UDim2.new(0, width, 0, height)
    window._toggleKey = toggleKey
    window._minimized = false
    window._visible = true
    window._configSaving = canSaveCfg
    window._configFolder = cfgFolder
    window._mobileMode = mobileMode
    window._transitioning = false
    window._destroyed = false
    -- Smooth window transition: scale + veil instead of fading only the background.
    local uiScale = Create("UIScale", { Parent = main, Scale = 0.96 })
    local transition = Create("Frame", {
        Name = "Transition",
        Parent = main,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100,
    })
    local transitionCorner = Corner(transition, Theme.Radius)
    Tween(uiScale, 0.26, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Tween(main, 0.26, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Tween(transition, 0.20, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    task.delay(0.22, function()
        if transition and transition.Parent then transition.Visible = false end
    end)

    AddDragging(dragArea, main, WindowConnect)

    -- ---- Resizing ----
    local resizing = false
    local resizeStart, sizeStart
    WindowConnect(resizeGrip.InputBegan, function(input)
        if window._minimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            sizeStart = main.AbsoluteSize
            WindowConnect(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)
    WindowConnect(UserInputService.InputChanged, function(input)
        if resizing
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local vp = GetViewport()
            local newW = math.clamp(sizeStart.X + delta.X, minSize.X, math.max(minSize.X, vp.X - 32))
            local newH = math.clamp(sizeStart.Y + delta.Y, minSize.Y, math.max(minSize.Y, vp.Y - 40))
            main.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    WindowConnect(resizeGrip.MouseEnter, function()
        for _, line in ipairs(gripLines) do
            Tween(line, 0.1, { BackgroundColor3 = Theme.Text })
        end
    end)
    WindowConnect(resizeGrip.MouseLeave, function()
        for _, line in ipairs(gripLines) do
            Tween(line, 0.1, { BackgroundColor3 = Theme.TextMuted })
        end
    end)

    -- Keep the window inside the viewport after rotation / resolution changes.
    local function reflowViewport()
        local vp = GetViewport()
        local maxW = mobileMode and math.max(300, vp.X - 16) or math.max(460, vp.X - 32)
        local maxH = mobileMode and math.max(250, vp.Y - 28) or math.max(300, vp.Y - 40)
        local current = main.AbsoluteSize
        local targetW = math.min(current.X, maxW)
        local targetH = math.min(current.Y, maxH)
        main.Size = UDim2.new(0, math.clamp(targetW, math.min(minSize.X, maxW), maxW), 0, math.clamp(targetH, math.min(minSize.Y, maxH), maxH))
        main.Position = UDim2.new(0, math.max(8, math.floor((vp.X - main.AbsoluteSize.X) / 2)), 0, math.max(8, math.floor((vp.Y - main.AbsoluteSize.Y) / 2)))
    end
    if workspace.CurrentCamera then
        WindowConnect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), reflowViewport)
    end

    -- ---- Minimize ----
    local function setMinimized(state)
        window._minimized = state
        if state then
            Tween(main, 0.18, { Size = UDim2.new(0, mobileMode and 112 or 124, 0, 28) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            sidebar.Visible = false
            contentHolder.Visible = false
            separator.Visible = false
            resizeGrip.Visible = false
            topBar.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.Text = "Menu"
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
            titleLabel.Size = UDim2.new(1, 0, 1, 0)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Center
            minBtn.Visible = false
            closeBtn.Visible = false
            if showFooter then
                main.Footer.Visible = false
            end
        else
            Tween(main, 0.22, { Size = window._size }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            sidebar.Visible = true
            contentHolder.Visible = true
            separator.Visible = true
            resizeGrip.Visible = true
            topBar.Size = UDim2.new(1, 0, 0, topBarH)
            titleLabel.Text = window._title
            titleLabel.Position = UDim2.new(0, 14, 0, 0)
            titleLabel.Size = UDim2.new(1, -60, 1, 0)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            minBtn.Visible = true
            closeBtn.Visible = true
            if showFooter then
                main.Footer.Visible = true
            end
        end
    end
    window._setMinimized = setMinimized

    WindowConnect(minBtn.MouseButton1Click, function()
        setMinimized(true)
    end)

    -- Restore on quick tap of the minimized bar (ignore drags)
    WindowConnect(topBar.InputBegan, function(input)
        if not window._minimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local startPos = input.Position
            local moved = false
            local changedConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement
                    or moveInput.UserInputType == Enum.UserInputType.Touch then
                    if (moveInput.Position - startPos).Magnitude > 4 then
                        moved = true
                    end
                end
            end)
            local endedConn
            endedConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1
                    or endInput.UserInputType == Enum.UserInputType.Touch then
                    changedConn:Disconnect()
                    endedConn:Disconnect()
                    if not moved then
                        setMinimized(false)
                    end
                end
            end)
        end
    end)

    -- ---- Close (hide) ----
    WindowConnect(closeBtn.MouseButton1Click, function()
        window:Hide()
    end)

    -- ---- Toggle key ----
    WindowConnect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == window._toggleKey then
            if window._visible then
                window:Hide()
            else
                window:Show()
            end
        end
    end)

    -- ---- Element search ----
    local searching = false
    local searchToken = 0
    local function applySearch(rawQuery)
        local query = string.lower(Trim(rawQuery))
        if query == "" then
            if searching then
                searching = false
                for _, entry in ipairs(VapeLiteUI._search) do
                    if entry.window == window then
                        entry.row.Visible = true
                    end
                end
                for _, tab in ipairs(window.Tabs) do
                    for _, sec in ipairs(tab.Sections) do
                        sec._setCollapsed(sec._userCollapsed)
                    end
                end
            end
            return
        end
        if not searching then
            searching = true
            for _, tab in ipairs(window.Tabs) do
                for _, sec in ipairs(tab.Sections) do
                    sec._setCollapsed(false)
                end
            end
        end
        local bestTab, bestCount = nil, 0
        for _, tab in ipairs(window.Tabs) do
            local count = 0
            for _, entry in ipairs(VapeLiteUI._search) do
                if entry.window == window and entry.tab == tab then
                    local match = string.find(entry.text, query, 1, true) ~= nil
                    if entry.row.Visible ~= match then
                        entry.row.Visible = match
                    end
                    if match then
                        count = count + 1
                    end
                end
            end
            if count > bestCount then
                bestTab, bestCount = tab, count
            end
        end
        if bestTab and bestCount > 0 and not bestTab._scroll.Visible then
            bestTab._select()
        end
    end
    WindowConnect(searchBox:GetPropertyChangedSignal("Text"), function()
        searchToken = searchToken + 1
        local myToken = searchToken
        task.delay(0.05, function()
            if myToken == searchToken then
                applySearch(searchBox.Text)
            end
        end)
    end)

    -- ================================================
    -- WINDOW METHODS
    -- ================================================
    local function setExternalVisibility(visible, instant)
        local wm = VapeLiteUI._watermark
        if wm and wm.frame and wm.frame.Parent then
            if visible then
                wm.frame.Visible = true
                if instant then
                    wm.frame.BackgroundTransparency = 0.15
                    if wm.label then wm.label.TextTransparency = 0 end
                    if wm.dot then wm.dot.BackgroundTransparency = 0 end
                else
                    wm.frame.BackgroundTransparency = 1
                    if wm.label then wm.label.TextTransparency = 1 end
                    if wm.dot then wm.dot.BackgroundTransparency = 1 end
                    Tween(wm.frame, 0.20, {BackgroundTransparency = 0.15}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    if wm.label then Tween(wm.label, 0.20, {TextTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) end
                    if wm.dot then Tween(wm.dot, 0.20, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) end
                end
            else
                if instant then
                    wm.frame.Visible = false
                else
                    Tween(wm.frame, 0.18, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
                    if wm.label then Tween(wm.label, 0.18, {TextTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
                    if wm.dot then Tween(wm.dot, 0.18, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
                    task.delay(0.19, function()
                        if wm.frame and wm.frame.Parent and not window._visible then
                            wm.frame.Visible = false
                        end
                    end)
                end
            end
        end
        for _, notif in ipairs(VapeLiteUI._activeNotifs) do
            if notif and notif.frame and notif.frame.Parent then
                if visible then
                    notif.frame.Visible = true
                else
                    notif.frame.Visible = false
                end
            end
        end
    end

    --- Hide the window with an interruptible scale-down + veil transition.
    function window:Hide()
        if window._destroyed then return end
        if not window._visible and not window._transitioning then return end
        window._animationToken += 1
        local token = window._animationToken
        window._transitioning = true
        window._visible = false
        main.Visible = true
        transition.Visible = true
        transition.BackgroundTransparency = 1
        setExternalVisibility(false, false)
        Tween(transition, 0.22, {BackgroundTransparency = 0.16}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(uiScale, 0.24, {Scale = 0.90}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(main, 0.20, {BackgroundTransparency = 0.06}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.24, function()
            if window._destroyed or token ~= window._animationToken then return end
            if not window._visible then
                main.Visible = false
                transition.Visible = false
                window._transitioning = false
            end
        end)
    end

    --- Show the window with an interruptible scale-up + fade-in transition.
    function window:Show()
        if window._destroyed then return end
        if window._visible and not window._transitioning then return end
        window._animationToken += 1
        local token = window._animationToken
        window._transitioning = true
        window._visible = true
        main.Visible = true
        transition.Visible = true
        transition.BackgroundTransparency = 0.16
        uiScale.Scale = 0.90
        main.BackgroundTransparency = 0.06
        setExternalVisibility(true, false)
        Tween(uiScale, 0.25, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Tween(transition, 0.22, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Tween(main, 0.25, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        task.delay(0.26, function()
            if window._destroyed or token ~= window._animationToken then return end
            if window._visible then
                transition.Visible = false
                window._transitioning = false
            end
        end)
    end

    --- Toggle visibility.
    function window:Toggle()
        if window._visible then
            window:Hide()
        else
            window:Show()
        end
    end

    --- Set window visibility explicitly.
    function window:SetVisible(state)
        if state then
            self:Show()
        else
            self:Hide()
        end
    end

    --- Change the toggle keybind.
    --- @param key Enum.KeyCode
    function window:SetToggleKey(key)
        window._toggleKey = key
    end

    --- Change the window title.
    --- @param newTitle string
    function window:SetTitle(newTitle)
        window._title = newTitle
        if not window._minimized then
            titleLabel.Text = newTitle
        end
    end

    --- Minimize the window into the small "Menu" bar.
    function window:Minimize()
        setMinimized(true)
    end

    --- Restore from the minimized state.
    function window:Restore()
        setMinimized(false)
    end

    --- Update the footer status text.
    --- @param text string
    function window:SetStatus(text)
        if statusLabel then
            statusLabel.Text = tostring(text)
        end
    end

    -- ================================================
    -- CREATE TAB
    -- ================================================
    --- Create a sidebar tab with its own scrollable content page.
    --- @param name string
    --- @return table tab
    function window:CreateTab(name, iconText)
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
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, mobileMode and 34 or 31),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = tab._index,
        })
        Corner(tabBtn, Theme.RadiusSmall)

        local tabIcon = Create("TextLabel", {
            Name = "Icon",
            Parent = tabBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 7, 0, 0),
            Size = UDim2.new(0, 22, 1, 0),
            Font = Theme.FontMedium,
            Text = tostring(iconText or "•"),
            TextColor3 = Theme.TextMuted,
            TextSize = mobileMode and 13 or 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        })

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
            Position = UDim2.new(0, mobileMode and 31 or 32, 0, 0),
            Size = UDim2.new(1, -(mobileMode and 37 or 40), 1, 0),
            Font = Theme.Font,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = mobileMode and 10 or 11,
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
            ScrollBarThickness = mobileMode and 4 or 2,
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
            Padding = UDim.new(0, 10),
        })

        tab._scroll = scroll
        tab._btn = tabBtn
        tab._indicator = indicator
        tab._label = tabLabel
        tab._icon = tabIcon

        -- ---- Tab switching ----
        local function selectTab()
            for _, otherTab in ipairs(window.Tabs) do
                otherTab._scroll.Visible = false
                otherTab._label.TextColor3 = Theme.TextDim
                otherTab._icon.TextColor3 = Theme.TextMuted
                otherTab._btn.BackgroundTransparency = 1
                Tween(otherTab._indicator, 0.15, { Size = UDim2.new(0, 3, 0, 0) })
            end

            scroll.Visible = true
            tabLabel.TextColor3 = Theme.Text
            tabIcon.TextColor3 = Theme.Text
            tabBtn.BackgroundTransparency = 1
            tabBtn.BackgroundColor3 = Theme.SurfaceHover
            Tween(indicator, 0.15, { Size = UDim2.new(0, 3, 0, 20) })

        end
        tab._select = selectTab

        WindowConnect(tabBtn.MouseEnter, function()
            if not scroll.Visible then
                tabBtn.BackgroundTransparency = 0.5
                tabBtn.BackgroundColor3 = Theme.SurfaceHover
            end
        end)
        WindowConnect(tabBtn.MouseLeave, function()
            if not scroll.Visible then
                tabBtn.BackgroundTransparency = 1
            end
        end)
        WindowConnect(tabBtn.MouseButton1Click, selectTab)

        if tab._index == 1 then
            task.defer(selectTab)
        end

        -- ================================================
        -- CREATE SECTION
        -- ================================================
        --- Create a collapsible section inside this tab.
        --- @param sectionName string
        --- @param options table|nil { HideHeader }
        --- @return table section
        function tab:CreateSection(sectionName, options)
            options = options or {}
            local section = {}
            section.Name = sectionName
            section.Elements = {}
            section._tab = tab
            section._window = window
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
                Padding = UDim.new(0, 3),
            })

            -- Collapsible header
            local headerBtn = Create("TextButton", {
                Name = "Header",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 1,
            })
            local headerLabel = Create("TextLabel", {
                Parent = headerBtn,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, -18, 1, 0),
                Font = Theme.FontSemi,
                Text = sectionName,
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local headerArrow = Create("TextLabel", {
                Parent = headerBtn,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                Font = Theme.FontSemi,
                Text = "v",
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            headerBtn.Visible = not options.HideHeader

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
            section._userCollapsed = false

            local collapsed = false
            local function setCollapsed(state)
                collapsed = state
                section._userCollapsed = state
                holder.Visible = not state
                headerArrow.Text = state and ">" or "v"
                headerLabel.TextColor3 = state and Theme.TextDim or Theme.TextMuted
            end
            section._setCollapsed = setCollapsed

            WindowConnect(headerBtn.MouseEnter, function()
                headerLabel.TextColor3 = Theme.TextDim
            end)
            WindowConnect(headerBtn.MouseLeave, function()
                headerLabel.TextColor3 = collapsed and Theme.TextDim or Theme.TextMuted
            end)
            WindowConnect(headerBtn.MouseButton1Click, function()
                setCollapsed(not collapsed)
            end)

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
                table.insert(VapeLiteUI._elements, api)
                return api
            end

            local function registerSearch(row, name)
                if not name or name == "" then return end
                table.insert(VapeLiteUI._search, {
                    row = row,
                    text = string.lower(tostring(name)),
                    tab = tab,
                    section = section,
                    window = window,
                })
            end

            local function resolveFlag(cfg, kind)
                return cfg.Flag
                    or (tab.Name .. "/" .. sectionName .. "/" .. (cfg.Name or kind) .. "_" .. tostring(#section.Elements + 1))
            end

            local function pushElement(api)
                section.Elements[#section.Elements + 1] = api
                return api
            end

            -- ========================================
            -- BUTTON
            -- ========================================
            --- Create a button. Set Confirm = true to require a second click.
            --- @param cfg table { Name, Callback, Confirm, Description }
            --- @return table api
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

                AttachTooltip(row, cfg.Description)

                local baseText = cfg.Name or "Button"
                local armed = false
                local armToken = 0

                WindowConnect(btn.MouseEnter, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                end)
                WindowConnect(btn.MouseLeave, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                    if armed then
                        armed = false
                        label.Text = baseText
                        label.TextColor3 = Theme.Text
                    end
                end)
                WindowConnect(btn.MouseButton1Click, function()
                    if cfg.Confirm then
                        if not armed then
                            armed = true
                            label.Text = "Confirm?"
                            label.TextColor3 = Theme.Warning
                            armToken = armToken + 1
                            local myToken = armToken
                            task.delay(2, function()
                                if myToken == armToken and armed then
                                    armed = false
                                    label.Text = baseText
                                    label.TextColor3 = Theme.Text
                                end
                            end)
                            return
                        end
                        armed = false
                        label.Text = baseText
                        label.TextColor3 = Theme.Text
                    end
                    Tween(row, 0.06, { BackgroundColor3 = Theme.SurfacePress })
                    task.delay(0.08, function()
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end)
                    task.spawn(SafeCall, cfg.Callback)
                end)

                local api = {
                    Instance = btn,
                    Value = nil,
                    Set = function(_, text)
                        baseText = tostring(text)
                        label.Text = baseText
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Button"), api)
            end

            -- ========================================
            -- LABEL
            -- ========================================
            --- Create a static label row.
            --- @param cfg table { Name }
            --- @return table api
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
                    TextColor3 = cfg.Color or Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local api = {
                    Instance = label,
                    Value = cfg.Name,
                    Set = function(_, text)
                        label.Text = text
                        api.Value = text
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Label"), api)
            end

            -- ========================================
            -- PARAGRAPH
            -- ========================================
            --- Create a two-line title + body text block.
            --- @param cfg table { Title, Body, Color }
            --- @return table api
            function section:CreateParagraph(cfg)
                cfg = cfg or {}
                local row = Create("Frame", {
                    Parent = holder,
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = nextOrder(),
                })
                Corner(row, Theme.RadiusSmall)
                Create("UIListLayout", {
                    Parent = row,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 3),
                })
                Padding(row, 7, 10, 7, 10)

                local titleLabelP = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Theme.FontSemi,
                    Text = cfg.Title or "Paragraph",
                    TextColor3 = cfg.Color or Theme.Text,
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 1,
                })
                local bodyLabelP = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Theme.Font,
                    Text = cfg.Body or "",
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 2,
                })

                local api = {
                    Instance = row,
                    Value = cfg.Body or "",
                    Set = function(_, body, newTitle)
                        bodyLabelP.Text = tostring(body)
                        api.Value = tostring(body)
                        if newTitle then
                            titleLabelP.Text = tostring(newTitle)
                        end
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Title)
                return registerElement(resolveFlag(cfg, "Paragraph"), api)
            end

            -- ========================================
            -- DIVIDER
            -- ========================================
            --- Create a horizontal divider, optionally with centered text.
            --- @param cfg table|nil { Text }
            --- @return table api
            function section:CreateDivider(cfg)
                cfg = cfg or {}
                local row = Create("Frame", {
                    Parent = holder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 9),
                    LayoutOrder = nextOrder(),
                })
                Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                })
                if cfg.Text and cfg.Text ~= "" then
                    Create("TextLabel", {
                        Parent = row,
                        BackgroundColor3 = Theme.Background,
                        BorderSizePixel = 0,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 90, 1, 0),
                        Font = Theme.FontSemi,
                        Text = string.upper(cfg.Text),
                        TextColor3 = Theme.TextMuted,
                        TextSize = 10,
                        BackgroundTransparency = 0,
                    })
                end
                return { Instance = row }
            end

            -- ========================================
            -- TOGGLE
            -- ========================================
            --- Create a toggle switch.
            --- @param cfg table { Name, Default, Callback, Description, Flag }
            --- @return table api
            function section:CreateToggle(cfg)
                cfg = cfg or {}
                local state = cfg.Default and true or false

                -- Module row layout follows Vape's compact hierarchy:
                -- icon block | module name | optional summary | toggle | kebab.
                local row = makeRow(Theme.RowHeight)
                row.ClipsDescendants = true

                local btn = Create("TextButton", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    AutoButtonColor = false,
                })

                local iconHolder = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.SurfaceAlt,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, Theme.IconSize, 1, 0),
                })
                local icon = Create("TextLabel", {
                    Parent = iconHolder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Theme.FontMedium,
                    Text = tostring(cfg.Icon or "•"),
                    TextColor3 = Theme.TextDim,
                    TextSize = 17,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })

                local nameWidth = mobileMode and 82 or 108
                local summaryX = Theme.IconSize + 14 + nameWidth

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, Theme.IconSize + 12, 0, 0),
                    Size = UDim2.new(0, nameWidth, 1, 0),
                    Font = Theme.FontMedium,
                    Text = cfg.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = mobileMode and 11 or 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })

                local summary = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, summaryX, 0, 0),
                    Size = UDim2.new(1, -summaryX - 64, 1, 0),
                    Font = Theme.Font,
                    Text = tostring(cfg.Summary or cfg.Description or ""),
                    TextColor3 = Theme.TextDim,
                    TextSize = mobileMode and 9 or 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })

                local track = Create("Frame", {
                    Parent = btn,
                    BackgroundColor3 = Theme.Track,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -11, 0.5, 0),
                    Size = UDim2.new(0, 34, 0, 18),
                    ZIndex = 2,
                })
                Corner(track, 9)
                local knob = Create("Frame", {
                    Parent = track,
                    BackgroundColor3 = Theme.Knob,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    ZIndex = 3,
                })
                Corner(knob, 6)

                AttachTooltip(row, cfg.Description)

                local function applyState(animated)
                    local duration = animated and 0.12 or 0
                    if state then
                        Tween(track, duration, { BackgroundColor3 = Theme.Accent })
                        Tween(knob, duration, { Position = UDim2.new(1, -15, 0.5, 0) })
                        Tween(iconHolder, duration, { BackgroundColor3 = Theme.Accent })
                        Tween(icon, duration, { TextColor3 = Theme.Text })
                    else
                        Tween(track, duration, { BackgroundColor3 = Theme.Track })
                        Tween(knob, duration, { Position = UDim2.new(0, 3, 0.5, 0) })
                        Tween(iconHolder, duration, { BackgroundColor3 = Theme.SurfaceAlt })
                        Tween(icon, duration, { TextColor3 = Theme.TextMuted })
                    end
                end
                applyState(false)

                WindowConnect(btn.MouseEnter, function()
                    Tween(row, 0.08, { BackgroundColor3 = Theme.RowHover })
                    Tween(iconHolder, 0.08, { BackgroundColor3 = Theme.SurfaceHover })
                end)
                WindowConnect(btn.MouseLeave, function()
                    Tween(row, 0.08, { BackgroundColor3 = Theme.Row })
                    Tween(iconHolder, 0.08, { BackgroundColor3 = Theme.SurfaceAlt })
                end)
                WindowConnect(btn.MouseButton1Click, function()
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
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Toggle"), api)
            end

            -- ========================================
            -- SLIDER
            -- ========================================
            --- Create a value slider. Supports Decimals for fractional steps.
            --- @param cfg table { Name, Min, Max, Default, Decimals, Suffix, Callback, Description, Flag }
            --- @return table api
            function section:CreateSlider(cfg)
                cfg = cfg or {}
                local min  = cfg.Min or 0
                local max  = cfg.Max or 100
                local decimals = cfg.Decimals or 0
                local val  = math.clamp(cfg.Default or min, min, max)
                local suffix = cfg.Suffix or ""
                local dragging = false

                local row = makeRow(mobileMode and 58 or 54)

                local label = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 4),
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

                AttachTooltip(row, cfg.Description)

                local function roundValue(x)
                    if decimals <= 0 then
                        return math.floor(x + 0.5)
                    end
                    local mult = 10 ^ decimals
                    return math.floor(x * mult + 0.5) / mult
                end

                local function setVisual(alpha)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    if decimals > 0 then
                        valueLabel.Text = string.format("%." .. decimals .. "f", val) .. suffix
                    else
                        valueLabel.Text = tostring(val) .. suffix
                    end
                end

                local function setValue(newVal, fire)
                    local clamped = math.clamp(roundValue(newVal), min, max)
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

                WindowConnect(row.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        updateFromInput(input)
                    end
                end)
                WindowConnect(UserInputService.InputChanged, function(input)
                    if dragging
                        and (input.UserInputType == Enum.UserInputType.MouseMovement
                            or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromInput(input)
                    end
                end)
                WindowConnect(UserInputService.InputEnded, function(input)
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
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Slider"), api)
            end

            -- ========================================
            -- DROPDOWN
            -- ========================================
            --- Create a single-select dropdown.
            --- @param cfg table { Name, Options, Default, Callback, Description, Flag }
            --- @return table api
            function section:CreateDropdown(cfg)
                cfg = cfg or {}
                local options = cfg.Options or {}
                local selected = cfg.Default or options[1]
                local expanded = false
                local collapsedH = Theme.RowHeight
                local itemH = mobileMode and 30 or 24
                local visibleCount = math.max(1, math.min(#options, 4))
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
                    ScrollBarThickness = mobileMode and 4 or 2,
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

                local function buildItem(i, option)
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
                    Create("TextLabel", {
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
                    WindowConnect(item.MouseEnter, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceHover })
                    end)
                    WindowConnect(item.MouseLeave, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceAlt })
                    end)
                    WindowConnect(item.MouseButton1Click, function()
                        selected = option
                        valueLabel.Text = tostring(option)
                        collapse()
                        task.spawn(SafeCall, cfg.Callback, option)
                    end)
                    itemApis[i] = { option = option, instance = item }
                end

                for i, option in ipairs(options) do
                    buildItem(i, option)
                end

                WindowConnect(btn.MouseEnter, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end
                end)
                WindowConnect(btn.MouseLeave, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.Row })
                    end
                end)
                WindowConnect(btn.MouseButton1Click, function()
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
                    Refresh = function(self, newOptions, keepSelection)
                        options = newOptions or {}
                        self.Options = options
                        for _, child in ipairs(listFrame:GetChildren()) do
                            if child:IsA("GuiButton") then
                                child:Destroy()
                            end
                        end
                        table.clear(itemApis)
                        for i, option in ipairs(options) do
                            buildItem(i, option)
                        end
                        if not keepSelection then
                            selected = options[1]
                            valueLabel.Text = tostring(selected or "None")
                        end
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Dropdown"), api)
            end

            -- ========================================
            -- MULTI DROPDOWN
            -- ========================================
            --- Create a multi-select dropdown. Value is an array of options.
            --- @param cfg table { Name, Options, Default, Callback, Description, Flag }
            --- @return table api
            function section:CreateMultiDropdown(cfg)
                cfg = cfg or {}
                local options = cfg.Options or {}
                local selectedSet = {}
                if cfg.Default then
                    for _, v in ipairs(cfg.Default) do
                        selectedSet[v] = true
                    end
                end
                local expanded = false
                local collapsedH = Theme.RowHeight
                local itemH = mobileMode and 30 or 24
                local visibleCount = math.max(1, math.min(#options, 4))
                local listH = visibleCount * (itemH + 2) + 6

                local function snapshot()
                    local arr = {}
                    for _, option in ipairs(options) do
                        if selectedSet[option] then
                            arr[#arr + 1] = option
                        end
                    end
                    return arr
                end

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
                    Text = cfg.Name or "Multi Dropdown",
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
                    Text = "",
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

                local function refreshSummary()
                    local count = 0
                    for _ in pairs(selectedSet) do
                        count = count + 1
                    end
                    if count == 0 then
                        valueLabel.Text = "None"
                    elseif count == 1 then
                        valueLabel.Text = tostring(snapshot()[1])
                    else
                        valueLabel.Text = tostring(count) .. " selected"
                    end
                end
                refreshSummary()

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

                    local checkBox = Create("Frame", {
                        Parent = item,
                        BackgroundColor3 = selectedSet[option] and Theme.Accent or Theme.Track,
                        BorderSizePixel = 0,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 8, 0.5, 0),
                        Size = UDim2.new(0, 12, 0, 12),
                    })
                    Corner(checkBox, 3)

                    Create("TextLabel", {
                        Parent = item,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 26, 0, 0),
                        Size = UDim2.new(1, -34, 1, 0),
                        Font = Theme.Font,
                        Text = tostring(option),
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })

                    WindowConnect(item.MouseEnter, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceHover })
                    end)
                    WindowConnect(item.MouseLeave, function()
                        Tween(item, 0.1, { BackgroundColor3 = Theme.SurfaceAlt })
                    end)
                    WindowConnect(item.MouseButton1Click, function()
                        selectedSet[option] = not selectedSet[option] or nil
                        Tween(checkBox, 0.12, {
                            BackgroundColor3 = selectedSet[option] and Theme.Accent or Theme.Track,
                        })
                        refreshSummary()
                        task.spawn(SafeCall, cfg.Callback, snapshot())
                    end)
                end

                WindowConnect(btn.MouseEnter, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end
                end)
                WindowConnect(btn.MouseLeave, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.Row })
                    end
                end)
                WindowConnect(btn.MouseButton1Click, function()
                    if expanded then
                        collapse()
                    else
                        expand()
                    end
                end)

                local api = {
                    Instance = row,
                    Value = snapshot(),
                    Options = options,
                    Set = function(self, values, silent)
                        table.clear(selectedSet)
                        for _, v in ipairs(values or {}) do
                            selectedSet[v] = true
                        end
                        self.Value = snapshot()
                        refreshSummary()
                        if not silent then
                            task.spawn(SafeCall, cfg.Callback, snapshot())
                        end
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "MultiDropdown"), api)
            end

            -- ========================================
            -- KEYBIND
            -- ========================================
            --- Create a keybind. Mode = "Toggle" (default) or "Hold".
            --- Hold mode fires Callback(true) on press and Callback(false) on release.
            --- @param cfg table { Name, Default, Mode, Callback, Description, Flag }
            --- @return table api
            function section:CreateKeybind(cfg)
                cfg = cfg or {}
                local currentKey = cfg.Default
                local mode = cfg.Mode or "Toggle"
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

                AttachTooltip(row, cfg.Description or ("Mode: " .. mode))

                local function stopCapture()
                    capturing = false
                    keyLabel.TextColor3 = Theme.TextDim
                    if not currentKey then
                        keyLabel.Text = "None"
                    end
                end

                local captureConn
                WindowConnect(btn.MouseButton1Click, function()
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
                            or ut == Enum.UserInputType.MouseButton3
                            or ut == Enum.UserInputType.MouseMovement
                            or ut == Enum.UserInputType.MouseWheel then
                            return
                        end

                        if input.KeyCode == Enum.KeyCode.Escape then
                            -- Cancel capture, keep old binding
                        elseif input.KeyCode == Enum.KeyCode.Backspace
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

                WindowConnect(UserInputService.InputBegan, function(input, processed)
                    if processed then return end
                    if capturing then return end
                    if currentKey and input.KeyCode == currentKey then
                        if mode == "Hold" then
                            task.spawn(SafeCall, cfg.Callback, true)
                        else
                            task.spawn(SafeCall, cfg.Callback, currentKey)
                        end
                    end
                end)
                WindowConnect(UserInputService.InputEnded, function(input)
                    if capturing then return end
                    if mode == "Hold" and currentKey and input.KeyCode == currentKey then
                        task.spawn(SafeCall, cfg.Callback, false)
                    end
                end)

                WindowConnect(btn.MouseEnter, function()
                    Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                end)
                WindowConnect(btn.MouseLeave, function()
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
                    SetMode = function(_, newMode)
                        if newMode == "Toggle" or newMode == "Hold" then
                            mode = newMode
                        end
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Keybind"), api)
            end

            -- ========================================
            -- TEXTBOX
            -- ========================================
            --- Create a text input row.
            --- @param cfg table { Name, Default, Placeholder, ClearOnSubmit, Numeric, Callback, Description, Flag }
            --- @return table api
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
                    Size = UDim2.new(0, mobileMode and 96 or 120, 0, 24),
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

                AttachTooltip(row, cfg.Description)

                local api

                WindowConnect(textbox.Focused, function()
                    Tween(inputFrame, 0.12, { BackgroundColor3 = Theme.SurfaceHover })
                end)
                WindowConnect(textbox.FocusLost, function(enterPressed)
                    Tween(inputFrame, 0.12, { BackgroundColor3 = Theme.Input })
                    if enterPressed or cfg.FireOnUnfocus then
                        local text = textbox.Text
                        if cfg.Numeric then
                            local num = tonumber(text)
                            if num then
                                text = num
                            else
                                textbox.Text = tostring(api.Value)
                                return
                            end
                        end
                        task.spawn(SafeCall, cfg.Callback, text)
                        if cfg.ClearOnSubmit then
                            textbox.Text = ""
                            api.Value = ""
                        end
                    end
                end)

                api = {
                    Instance = textbox,
                    Value = cfg.Default or "",
                    Set = function(self, value)
                        textbox.Text = tostring(value)
                        self.Value = tostring(value)
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Textbox"), api)
            end

            -- ========================================
            -- COLOR PICKER
            -- ========================================
            --- Create a color picker with an expandable HSV editor.
            --- @param cfg table { Name, Default, Callback, Description, Flag }
            --- @return table api
            function section:CreateColorPicker(cfg)
                cfg = cfg or {}
                local h, s, v = 0.62, 0.55, 0.95
                if cfg.Default and typeof(cfg.Default) == "Color3" then
                    h, s, v = Color3.toHSV(cfg.Default)
                end

                local collapsedH = Theme.RowHeight
                local expandedH = mobileMode and 184 or 192
                local expanded = false
                local svDragging = false
                local hueDragging = false

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
                    ZIndex = 2,
                })
                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Theme.Font,
                    Text = cfg.Name or "Color",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                })
                local swatch = Create("Frame", {
                    Parent = btn,
                    BackgroundColor3 = Color3.fromHSV(h, s, v),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, mobileMode and 30 or 26, 0, 18),
                    ZIndex = 2,
                })
                Corner(swatch, Theme.RadiusSmall)
                Stroke(swatch, Theme.Border, 1)

                AttachTooltip(row, cfg.Description)

                -- SV square
                local svFrame = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, collapsedH + 6),
                    Size = UDim2.new(1, -16, 0, 100),
                    ZIndex = 2,
                })
                Corner(svFrame, Theme.RadiusSmall)

                local whiteOverlay = Create("Frame", {
                    Parent = svFrame,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                })
                Create("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                    Parent = whiteOverlay,
                })

                local blackOverlay = Create("Frame", {
                    Parent = svFrame,
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                })
                Create("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                    Parent = blackOverlay,
                })

                local svKnob = Create("Frame", {
                    Parent = svFrame,
                    BackgroundColor3 = Theme.Knob,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(s, 0, 1 - v, 0),
                    Size = UDim2.new(0, 10, 0, 10),
                    ZIndex = 4,
                })
                Corner(svKnob, 5)
                Stroke(svKnob, Theme.Border, 1)

                -- Hue bar
                local hueBar = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, collapsedH + 112),
                    Size = UDim2.new(1, -16, 0, 10),
                    ZIndex = 2,
                })
                Corner(hueBar, 5)
                local hueKeys = {}
                for i = 0, 12 do
                    hueKeys[i + 1] = ColorSequenceKeypoint.new(i / 12, Color3.fromHSV(i / 12, 1, 1))
                end
                Create("UIGradient", {
                    Color = ColorSequence.new(hueKeys),
                    Parent = hueBar,
                })
                local hueKnob = Create("Frame", {
                    Parent = hueBar,
                    BackgroundColor3 = Theme.Knob,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(h, 0, 0.5, 0),
                    Size = UDim2.new(0, 6, 0, 14),
                    ZIndex = 4,
                })
                Corner(hueKnob, 3)
                Stroke(hueKnob, Theme.Border, 1)

                -- RGB input row
                local rgbHolder = Create("Frame", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 8, 0, collapsedH + 128),
                    Size = UDim2.new(1, -16, 0, 22),
                    ZIndex = 2,
                })
                Create("UIListLayout", {
                    Parent = rgbHolder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                })

                local updateVisuals

                local rgbBoxes = {}
                for i = 1, 3 do
                    local boxHolder = Create("Frame", {
                        Parent = rgbHolder,
                        BackgroundColor3 = Theme.Input,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1 / 3, -4, 1, 0),
                        LayoutOrder = i,
                        ZIndex = 2,
                    })
                    Corner(boxHolder, Theme.RadiusSmall)
                    Stroke(boxHolder, Theme.Border, 1, 0.4)
                    local box = Create("TextBox", {
                        Parent = boxHolder,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 6, 0, 0),
                        Size = UDim2.new(1, -12, 1, 0),
                        Font = Theme.Font,
                        Text = "255",
                        PlaceholderText = "...",
                        PlaceholderColor3 = Theme.TextMuted,
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ClearTextOnFocus = false,
                        ZIndex = 2,
                    })
                    rgbBoxes[i] = box
                    WindowConnect(box.FocusLost, function()
                        local r = math.clamp(tonumber(rgbBoxes[1].Text) or 0, 0, 255)
                        local g = math.clamp(tonumber(rgbBoxes[2].Text) or 0, 0, 255)
                        local b = math.clamp(tonumber(rgbBoxes[3].Text) or 0, 0, 255)
                        h, s, v = Color3.toHSV(Color3.fromRGB(r, g, b))
                        updateVisuals(false)
                        task.spawn(SafeCall, cfg.Callback, Color3.fromHSV(h, s, v))
                    end)
                end

                local function collapse()
                    expanded = false
                    Tween(row, 0.15, { Size = UDim2.new(1, 0, 0, collapsedH) })
                end
                local function expand()
                    expanded = true
                    Tween(row, 0.15, { Size = UDim2.new(1, 0, 0, expandedH) })
                end

                local api = {
                    Instance = row,
                    Value = Color3.fromHSV(h, s, v),
                    Set = function(self, color, silent)
                        if typeof(color) == "Color3" then
                            local changed = color ~= self.Value
                            h, s, v = Color3.toHSV(color)
                            updateVisuals(false)
                            if changed and not silent then
                                task.spawn(SafeCall, cfg.Callback, self.Value)
                            end
                        end
                    end,
                }

                updateVisuals = function(fromText)
                    local color = Color3.fromHSV(h, s, v)
                    svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
                    swatch.BackgroundColor3 = color
                    if not fromText then
                        rgbBoxes[1].Text = tostring(math.floor(color.R * 255 + 0.5))
                        rgbBoxes[2].Text = tostring(math.floor(color.G * 255 + 0.5))
                        rgbBoxes[3].Text = tostring(math.floor(color.B * 255 + 0.5))
                    end
                    api.Value = color
                end

                local function svFromInput(input)
                    local relX = math.clamp(
                        (input.Position.X - svFrame.AbsolutePosition.X) / math.max(svFrame.AbsoluteSize.X, 1), 0, 1)
                    local relY = math.clamp(
                        (input.Position.Y - svFrame.AbsolutePosition.Y) / math.max(svFrame.AbsoluteSize.Y, 1), 0, 1)
                    s = relX
                    v = 1 - relY
                    updateVisuals(false)
                    task.spawn(SafeCall, cfg.Callback, api.Value)
                end

                for _, layer in ipairs({ svFrame, whiteOverlay, blackOverlay }) do
                    WindowConnect(layer.InputBegan, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                            svDragging = true
                            svFromInput(input)
                        end
                    end)
                end
                WindowConnect(hueBar.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        local alpha = math.clamp(
                            (input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
                        h = alpha
                        updateVisuals(false)
                        task.spawn(SafeCall, cfg.Callback, api.Value)
                    end
                end)
                WindowConnect(UserInputService.InputChanged, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement
                        and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if svDragging then
                        svFromInput(input)
                    elseif hueDragging then
                        local alpha = math.clamp(
                            (input.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
                        if alpha ~= h then
                            h = alpha
                            updateVisuals(false)
                            task.spawn(SafeCall, cfg.Callback, api.Value)
                        end
                    end
                end)
                WindowConnect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = false
                        hueDragging = false
                    end
                end)

                WindowConnect(btn.MouseEnter, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.RowHover })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.RowHover })
                    end
                end)
                WindowConnect(btn.MouseLeave, function()
                    if not expanded then
                        Tween(row, 0.1, { BackgroundColor3 = Theme.Row })
                        Tween(btn, 0.1, { BackgroundColor3 = Theme.Row })
                    end
                end)
                WindowConnect(btn.MouseButton1Click, function()
                    if expanded then
                        collapse()
                    else
                        expand()
                    end
                end)

                updateVisuals(false)

                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "ColorPicker"), api)
            end

            -- ========================================
            -- PROGRESS
            -- ========================================
            --- Create a progress bar row.
            --- @param cfg table { Name, Min, Max, Default, Suffix }
            --- @return table api
            function section:CreateProgress(cfg)
                cfg = cfg or {}
                local min = cfg.Min or 0
                local max = cfg.Max or 100
                local val = math.clamp(cfg.Default or cfg.Value or min, min, max)
                local suffix = cfg.Suffix or "%"

                local row = makeRow(40)

                local label = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(0.6, 0, 0, 16),
                    Font = Theme.Font,
                    Text = cfg.Name or "Progress",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                local valueLabel = Create("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.6, 0, 0, 4),
                    Size = UDim2.new(0.4, -10, 0, 16),
                    Font = Theme.FontMedium,
                    Text = "",
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                local track = Create("Frame", {
                    Parent = row,
                    BackgroundColor3 = Theme.Track,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 10, 0, 26),
                    Size = UDim2.new(1, -20, 0, 4),
                })
                Corner(track, 2)
                local fill = Create("Frame", {
                    Parent = track,
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((val - min) / math.max(max - min, 1e-6), 0, 1, 0),
                })
                Corner(fill, 2)

                local function refresh()
                    local alpha = (val - min) / math.max(max - min, 1e-6)
                    Tween(fill, 0.15, { Size = UDim2.new(alpha, 0, 1, 0) })
                    valueLabel.Text = tostring(math.floor(alpha * 100 + 0.5)) .. suffix
                end
                refresh()

                local api = {
                    Instance = row,
                    Value = val,
                    Set = function(self, value)
                        val = math.clamp(value, min, max)
                        self.Value = val
                        refresh()
                    end,
                    SetRange = function(_, newMin, newMax)
                        min = newMin or min
                        max = newMax or max
                        val = math.clamp(val, min, max)
                        refresh()
                    end,
                }
                pushElement(api)
                registerSearch(row, cfg.Name)
                return registerElement(resolveFlag(cfg, "Progress"), api)
            end

            return section
        end

        return tab
    end

    -- ================================================
    -- WINDOW: Config
    -- ================================================
    --- Save all element values to a JSON config file.
    --- @param name string
    function window:SaveConfig(name)
        if not window._configSaving then
            warn("[VapeLiteUI] Config saving is not available in this environment.")
            return
        end
        local data = {}
        for _, element in ipairs(VapeLiteUI._elements) do
            local value = element.Value
            local t = typeof(value)
            if t == "boolean" or t == "number" or t == "string" then
                data[element._id] = { type = t, value = value }
            elseif t == "EnumItem" then
                data[element._id] = {
                    type = "EnumItem",
                    value = value.Name,
                    enum = string.match(tostring(value.EnumType), "^Enum%.(%w+)$"),
                }
            elseif t == "Color3" then
                data[element._id] = {
                    type = "Color3",
                    value = string.format("%d,%d,%d",
                        math.floor(value.R * 255 + 0.5),
                        math.floor(value.G * 255 + 0.5),
                        math.floor(value.B * 255 + 0.5)),
                }
            elseif t == "table" then
                local okEncoded, encoded = pcall(function()
                    return HttpService:JSONEncode(value)
                end)
                if okEncoded then
                    data[element._id] = { type = "table", value = encoded }
                end
            end
        end
        local path = window._configFolder .. "/" .. name .. ".json"
        local ok, err = pcall(function()
            if type(makefolder) == "function" then
                pcall(makefolder, window._configFolder)
            end
            writefile(path, HttpService:JSONEncode(data))
        end)
        if ok then
            window:SetStatus("Config saved: " .. name)
        else
            warn("[VapeLiteUI] SaveConfig failed: " .. tostring(err))
        end
    end

    --- Load element values from a JSON config file.
    --- @param name string
    function window:LoadConfig(name)
        if not window._configSaving then
            warn("[VapeLiteUI] Config loading is not available in this environment.")
            return
        end
        local path = window._configFolder .. "/" .. name .. ".json"
        local ok, contents = pcall(readfile, path)
        if not ok or not contents then
            warn("[VapeLiteUI] LoadConfig failed: file not found (" .. path .. ")")
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
        for _, element in ipairs(VapeLiteUI._elements) do
            local saved = decoded[element._id]
            if saved and element.Set then
                if saved.type == "EnumItem" and saved.enum then
                    local enumOk, enumItem = pcall(function()
                        return Enum[saved.enum][saved.value]
                    end)
                    if enumOk and enumItem then
                        element:Set(enumItem, true)
                    end
                elseif saved.type == "Color3" then
                    local r, g, b = string.match(saved.value, "(%d+),(%d+),(%d+)")
                    if r then
                        element:Set(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)), true)
                    end
                elseif saved.type == "table" then
                    local arrOk, arr = pcall(function()
                        return HttpService:JSONDecode(saved.value)
                    end)
                    if arrOk and arr then
                        element:Set(arr, true)
                    end
                else
                    element:Set(saved.value, true)
                end
            end
        end
        window:SetStatus("Config loaded: " .. name)
    end

    -- Auto-load config
    if autoLoad and type(isfile) == "function" then
        local path = cfgFolder .. "/" .. cfgName .. ".json"
        local ok, exists = pcall(isfile, path)
        if ok and exists then
            task.defer(function()
                window:LoadConfig(cfgName)
            end)
        end
    end

    -- ================================================
    -- WINDOW: Destroy
    -- ================================================
    --- Destroy this window and release its connections.
    function window:Destroy()
        if window._destroyed then return end
        window._destroyed = true
        window._animationToken += 1
        DisconnectWindowConnections()
        if gui then
            gui:Destroy()
        end
        for i = #VapeLiteUI._windows, 1, -1 do
            if VapeLiteUI._windows[i] == window then
                table.remove(VapeLiteUI._windows, i)
            end
        end
        for i = #VapeLiteUI._search, 1, -1 do
            if VapeLiteUI._search[i].window == window then
                table.remove(VapeLiteUI._search, i)
            end
        end
    end

    table.insert(VapeLiteUI._windows, window)
    return window
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local function RelayoutNotifications()
    for index, notif in ipairs(VapeLiteUI._activeNotifs) do
        Tween(notif.frame, 0.2, {
            Position = UDim2.new(1, -16, 0, 16 + (index - 1) * 78),
        })
    end
end

--- Display a notification in the top-right corner.
--- @param title string
--- @param content string
--- @param duration number|nil  seconds before auto-dismiss (default 4, 0 = sticky)
--- @param notifyType string|nil "Info" | "Success" | "Warning" | "Error"
function VapeLiteUI:Notify(title, content, duration, notifyType)
    if not self._gui or not self._gui.Parent then
        warn("[VapeLiteUI] No active window to host the notification.")
        return
    end
    duration = duration or 4

    local typeColors = {
        Info    = Theme.Info,
        Success = Theme.Success,
        Warning = Theme.Warning,
        Error   = Theme.Danger,
    }
    local accentColor = typeColors[notifyType] or Theme.Accent

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

    local accentBar = Create("Frame", {
        Parent = holder,
        BackgroundColor3 = accentColor,
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

    local dismissed = false
    local dismissConnection
    local function dismiss()
        if dismissed then return end
        dismissed = true
        if dismissConnection then
            pcall(function() dismissConnection:Disconnect() end)
            dismissConnection = nil
        end
        Tween(holder, 0.18, { BackgroundTransparency = 1 })
        Tween(accentBar, 0.18, { BackgroundTransparency = 1 })
        Tween(titleLabel, 0.18, { TextTransparency = 1 })
        Tween(bodyLabel, 0.18, { TextTransparency = 1 })
        task.delay(0.2, function()
            if holder and holder.Parent then
                holder:Destroy()
            end
            for i = #VapeLiteUI._activeNotifs, 1, -1 do
                if VapeLiteUI._activeNotifs[i] == entry then
                    table.remove(VapeLiteUI._activeNotifs, i)
                end
            end
            RelayoutNotifications()
        end)
    end

    dismissConnection = Connect(holder.InputBegan, function(input)
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
-- WATERMARK
-- ============================================================
--- Create or update the draggable top-center watermark.
--- @param text string
function VapeLiteUI:SetWatermark(text)
    if not self._gui or not self._gui.Parent then
        warn("[VapeLiteUI] No active window to host the watermark.")
        return
    end
    if not self._watermark then
        local frame = Create("Frame", {
            Name = "Watermark",
            Parent = self._gui,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 8),
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
        })
        Corner(frame, Theme.RadiusSmall)
        Stroke(frame, Theme.Border, 1)
        Padding(frame, 0, 10, 0, 10)

        local accentDot = Create("Frame", {
            Parent = frame,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6),
        })
        Corner(accentDot, 3)

        local label = Create("TextLabel", {
            Parent = frame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Theme.FontSemi,
            Text = "",
            TextColor3 = Theme.Text,
            TextSize = 12,
        })

        self._watermark = { frame = frame, label = label, dot = accentDot }
        local function watermarkConnect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(self._watermarkConnections, connection)
            return connection
        end
        AddDragging(frame, frame, watermarkConnect)
    end
    self._watermark.label.Text = tostring(text)
end

--- Remove the watermark.
function VapeLiteUI:RemoveWatermark()
    for i = #self._watermarkConnections, 1, -1 do
        pcall(function() self._watermarkConnections[i]:Disconnect() end)
        self._watermarkConnections[i] = nil
    end
    if self._watermark then
        self._watermark.frame:Destroy()
        self._watermark = nil
    end
end

-- ============================================================
-- THEME OVERRIDE
-- ============================================================
--- Merge custom colors into the theme table.
--- @param patches table
function VapeLiteUI:SetTheme(patches)
    for key, value in pairs(patches or {}) do
        Theme[key] = value
    end
end

-- ============================================================
-- LIBRARY: DESTROY
-- ============================================================
--- Fully destroy the library, disconnect all connections and remove the GUI.
function VapeLiteUI:Destroy()
    for i = #self._windows, 1, -1 do
        local window = self._windows[i]
        pcall(function() window:Destroy() end)
    end
    pcall(function() self:RemoveWatermark() end)
    table.clear(self._windows)
    table.clear(self._elements)
    table.clear(self._search)
    table.clear(self._activeNotifs)

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    self._gui = nil
    self._watermark = nil
end

--- Set the toggle keybind on every window.
--- @param key Enum.KeyCode
function VapeLiteUI:SetToggleKey(key)
    for _, window in ipairs(self._windows) do
        window:SetToggleKey(key)
    end
end

--- Whether the client is a touch-only device.
--- @return boolean
function VapeLiteUI:IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

return VapeLiteUI
