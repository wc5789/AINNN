--[[
    MD3UI v1.5.5
    Material Design 3 UI Library for Roblox

    用法:
        local MD3 = loadstring(game:HttpGet(URL))()
        local ui = MD3.new({ Theme = "Dark", Parent = PlayerGui })
        local win = ui:CreateWindow({ Title = "Demo" })
        local tab = win:AddTab({ Title = "基础" })
        ui:Button({ Parent = tab.Content, Text = "Hi" })
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local MD3 = {}
MD3.__index = MD3
MD3.Version = "1.5.5"

--==================================================================
-- 1. 设计 Token
--==================================================================
local function hex(s) return Color3.fromHex(s) end

MD3.Theme = {
    Dark = {
        Primary = hex("#D0BCFF"), OnPrimary = hex("#381E72"),
        PrimaryContainer = hex("#4F378B"), OnPrimaryContainer = hex("#EADDFF"),
        Secondary = hex("#CCC2DC"), OnSecondary = hex("#332D41"),
        SecondaryContainer = hex("#4A4458"), OnSecondaryContainer = hex("#E8DEF8"),
        Tertiary = hex("#EFB8C8"), OnTertiary = hex("#492532"),
        TertiaryContainer = hex("#633B48"), OnTertiaryContainer = hex("#FFD8E4"),
        Error = hex("#F2B8B5"), OnError = hex("#601410"),
        ErrorContainer = hex("#8C1D18"), OnErrorContainer = hex("#F9DEDC"),
        Background = hex("#141218"), OnBackground = hex("#E6E1E5"),
        Surface = hex("#141218"), OnSurface = hex("#E6E1E5"),
        SurfaceVariant = hex("#49454F"), OnSurfaceVariant = hex("#CAC4D0"),
        SurfaceContainerLowest  = hex("#0F0D13"),
        SurfaceContainerLow     = hex("#1D1B20"),
        SurfaceContainer        = hex("#211F26"),
        SurfaceContainerHigh    = hex("#2B2930"),
        SurfaceContainerHighest = hex("#36343B"),
        Outline = hex("#938F99"), OutlineVariant = hex("#49454F"),
        InverseSurface = hex("#E6E1E5"), InverseOnSurface = hex("#322F35"),
        InversePrimary = hex("#6750A4"),
    },
    Light = {
        Primary = hex("#6750A4"), OnPrimary = hex("#FFFFFF"),
        PrimaryContainer = hex("#EADDFF"), OnPrimaryContainer = hex("#21005D"),
        Secondary = hex("#625B71"), OnSecondary = hex("#FFFFFF"),
        SecondaryContainer = hex("#E8DEF8"), OnSecondaryContainer = hex("#1D192B"),
        Tertiary = hex("#7D5260"), OnTertiary = hex("#FFFFFF"),
        TertiaryContainer = hex("#FFD8E4"), OnTertiaryContainer = hex("#31111D"),
        Error = hex("#B3261E"), OnError = hex("#FFFFFF"),
        ErrorContainer = hex("#F9DEDC"), OnErrorContainer = hex("#410E0B"),
        Background = hex("#FEF7FF"), OnBackground = hex("#1D1B20"),
        Surface = hex("#FEF7FF"), OnSurface = hex("#1D1B20"),
        SurfaceVariant = hex("#E7E0EC"), OnSurfaceVariant = hex("#49454F"),
        SurfaceContainerLowest  = hex("#FFFFFF"),
        SurfaceContainerLow     = hex("#F7F2FA"),
        SurfaceContainer        = hex("#F3EDF7"),
        SurfaceContainerHigh    = hex("#ECE6F0"),
        SurfaceContainerHighest = hex("#E6E0E9"),
        Outline = hex("#79747E"), OutlineVariant = hex("#CAC4D0"),
        InverseSurface = hex("#322F35"), InverseOnSurface = hex("#F5EFF7"),
        InversePrimary = hex("#D0BCFF"),
    },
}

-- 排版 (MD3 Type Scale)
local Typo = {
    DisplayLarge   = { size = 57, weight = "Regular" },
    DisplayMedium  = { size = 45, weight = "Regular" },
    DisplaySmall   = { size = 36, weight = "Regular" },
    HeadlineLarge  = { size = 32, weight = "Regular" },
    HeadlineMedium = { size = 28, weight = "Regular" },
    HeadlineSmall  = { size = 24, weight = "Regular" },
    TitleLarge     = { size = 22, weight = "Regular" },
    TitleMedium    = { size = 16, weight = "Medium"  },
    TitleSmall     = { size = 14, weight = "Medium"  },
    BodyLarge      = { size = 16, weight = "Regular" },
    BodyMedium     = { size = 14, weight = "Regular" },
    BodySmall      = { size = 12, weight = "Regular" },
    LabelLarge     = { size = 14, weight = "Medium"  },
    LabelMedium    = { size = 12, weight = "Medium"  },
    LabelSmall     = { size = 11, weight = "Medium"  },
}

-- 间距
local Space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }

-- 动画时长 (MD3 四级)
local Dur = {
    micro  = 0.08,
    short  = 0.15,
    medium = 0.25,
    long   = 0.40,
}

-- 动画曲线 (MD3 近似映射)
local Curve = {
    emphasized      = { style = Enum.EasingStyle.Quint,  dir = Enum.EasingDirection.Out },
    emphasizedDecel = { style = Enum.EasingStyle.Quart,  dir = Enum.EasingDirection.Out },
    emphasizedAccel = { style = Enum.EasingStyle.Quart,  dir = Enum.EasingDirection.In  },
    standard        = { style = Enum.EasingStyle.Quad,   dir = Enum.EasingDirection.InOut },
    standardDecel   = { style = Enum.EasingStyle.Cubic,  dir = Enum.EasingDirection.Out },
    standardAccel   = { style = Enum.EasingStyle.Cubic,  dir = Enum.EasingDirection.In  },
    spring          = { style = Enum.EasingStyle.Back,   dir = Enum.EasingDirection.Out },
    linear          = { style = Enum.EasingStyle.Linear, dir = Enum.EasingDirection.Out },
}

-- 状态层不透明度
local StateOpacity = {
    Hover   = 0.92,
    Focus   = 0.90,
    Pressed = 0.90,
    Dragged = 0.84,
}

-- 阴影 (Elevation)
local Elevation = {
    Level1 = { blur = 6,  offset = 2, spread = 0, transparency = 0.85 },
    Level2 = { blur = 8,  offset = 3, spread = 0, transparency = 0.82 },
    Level3 = { blur = 12, offset = 4, spread = 0, transparency = 0.78 },
    Level4 = { blur = 16, offset = 5, spread = 0, transparency = 0.75 },
    Level5 = { blur = 20, offset = 6, spread = 0, transparency = 0.72 },
}

--==================================================================
-- 2. 工具
--==================================================================

local function create(className, props)
    local inst = Instance.new(className)
    if props then
        local parent = props.Parent
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        inst.Parent = parent
    end
    return inst
end

local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = (typeof(radius) == "number") and UDim.new(0, radius) or radius
    c.Parent = inst
    return c
end

local function addPadding(inst, top, right, bottom, left)
    if typeof(top) == "UDim" and right == nil then
        right, bottom, left = top, top, top
    end
    local p = Instance.new("UIPadding")
    p.PaddingTop    = top    or UDim.new(0, 0)
    p.PaddingRight  = right  or UDim.new(0, 0)
    p.PaddingBottom = bottom or UDim.new(0, 0)
    p.PaddingLeft   = left   or UDim.new(0, 0)
    p.Parent = inst
    return p
end

local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1, 1, 1)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function addList(inst, opts)
    opts = opts or {}
    local l = Instance.new("UIListLayout")
    l.FillDirection       = opts.FillDirection       or Enum.FillDirection.Vertical
    l.SortOrder           = opts.SortOrder           or Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = opts.HorizontalAlignment or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = opts.VerticalAlignment   or Enum.VerticalAlignment.Top
    l.Padding             = opts.Padding             or UDim.new(0, 0)
    l.Parent = inst
    return l
end

local function tween(inst, props, duration, curveName)
    local c = Curve[curveName or "emphasized"]
    local info = TweenInfo.new(
        duration or Dur.short,
        c.style,
        c.dir
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function applyFont(label, styleName)
    local t = Typo[styleName]
    if not t then return end
    label.TextSize = t.size
    if t.weight == "Medium" then
        label.Font = Enum.Font.GothamMedium
    elseif t.weight == "Bold" then
        label.Font = Enum.Font.GothamBold
    else
        label.Font = Enum.Font.Gotham
    end
end

local function resolveSize(w, h, default)
    if w == nil then return default or UDim2.new(1, 0, 0, h or 32) end
    if typeof(w) == "number" then return UDim2.new(0, w, 0, h or 32) end
    return w
end

local function addStateLayer(parent, color, radius)
    local layer = create("Frame", {
        Name = "StateLayer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = (parent.ZIndex or 1) + 1,
        Parent = parent,
    })
    addCorner(layer, radius or 0)
    return layer
end

local function addShadow(inst, level)
    local e = Elevation["Level" .. tostring(level)]
    if not e then return nil end
    local shadow = Instance.new("UIShadow")
    shadow.BlurRadius = UDim.new(0, e.blur)
    shadow.Offset = UDim2.new(0, 0, 0, e.offset)
    shadow.Spread = UDim.new(0, e.spread, 0, e.spread)
    shadow.Transparency = e.transparency
    shadow.Color = Color3.new(0, 0, 0)
    shadow.Parent = inst
    return shadow
end

local function playRipple(parent, relX, relY, color)
    if not parent or not parent.Parent then return end
    local maxDim = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    if maxDim <= 4 then return end

    local ripple = create("Frame", {
        Name = "MD3_Ripple",
        BackgroundColor3 = color or Color3.new(1, 1, 1),
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, relX, 0, relY),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = (parent.ZIndex or 1) + 3,
        Parent = parent,
    })
    addCorner(ripple, UDim.new(0.5, 0))

    local target = maxDim * 2.2
    local t = TweenService:Create(
        ripple,
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, target, 0, target), BackgroundTransparency = 1 }
    )
    t:Play()
    t.Completed:Connect(function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

--==================================================================
-- 3. 组件工厂
--==================================================================

local function newComponent(window, root)
    local comp = {
        Root = root,
        Window = window,
        _connections = {},
        _destroyed = false,
        _themeFn = nil,
    }

    function comp:Connect(signal, fn)
        if self._destroyed then return nil end
        local conn = signal:Connect(fn)
        table.insert(self._connections, conn)
        return conn
    end

    function comp:SetThemeFn(fn)
        self._themeFn = fn
        if not self._destroyed then fn() end
    end

    function comp:RefreshTheme()
        if self._themeFn and not self._destroyed then self._themeFn() end
    end

    function comp:Destroy()
        if self._destroyed then return end
        self._destroyed = true

        for _, conn in ipairs(self._connections) do
            if typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end
        self._connections = {}

        if not window._destroying then
            local idx = table.find(window._components, self)
            if idx then table.remove(window._components, idx) end
        end

        if self.Root and self.Root.Parent then self.Root:Destroy() end
    end

    table.insert(window._components, comp)
    return comp
end

--==================================================================
-- 4. Window 入口
--==================================================================

function MD3.new(props)
    props = props or {}
    local self = setmetatable({}, MD3)

    self._themeName     = props.Theme or "Dark"
    self._theme         = MD3.Theme[self._themeName] or MD3.Theme.Dark
    self._components    = {}
    self._destroying    = false
    self._radioGroups   = {}
    self._segGroups     = {}
    self._layoutCounter = 0

    local parent = props.Parent
    if not parent then
        local ok, pg = pcall(function()
            return Players.LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
        parent = (ok and pg) or game:GetService("CoreGui")
    end
    self._defaultParent = parent

    self.ScreenGui = create("ScreenGui", {
        Name = props.Name or "MD3UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = props.DisplayOrder or 1,
        Parent = parent,
    })

    return self
end

function MD3:_nextOrder()
    self._layoutCounter = self._layoutCounter + 1
    return self._layoutCounter
end

function MD3:Color(role)
    return self._theme[role] or Color3.new(1, 1, 1)
end

function MD3:GetThemeName() return self._themeName end

function MD3:SetTheme(name)
    if not MD3.Theme[name] then
        warn("[MD3UI] 未知主题: " .. tostring(name))
        return
    end
    self._themeName = name
    self._theme = MD3.Theme[name]
    self:RefreshTheme()
end

function MD3:RefreshTheme()
    for _, comp in ipairs(self._components) do
        if not comp._destroyed then comp:RefreshTheme() end
    end
end

function MD3:Destroy()
    self._destroying = true
    local copy = table.clone(self._components)
    for _, comp in ipairs(copy) do
        if not comp._destroyed then comp:Destroy() end
    end
    self._components = {}
    if self.ScreenGui then self.ScreenGui:Destroy() end
    self._destroying = false
end

--==================================================================
-- 5. 组件
--==================================================================

--------------------------------------------------------------------
-- 5.1 Button
--------------------------------------------------------------------
function MD3:Button(props)
    props = props or {}
    local variant  = props.Variant or "Filled"
    local height   = props.Height or 40
    local disabled = props.Disabled == true

    local btn = create("TextButton", {
        Name = "MD3_Button",
        Text = "",
        Size = resolveSize(props.Width, height, UDim2.new(1, 0, 0, height)),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        TextTransparency = 1,
        ClipsDescendants = true,
        Active = not disabled,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(btn, height / 2)

    local label = create("TextLabel", {
        Text = props.Text or "Button",
        Size = UDim2.new(1, -Space.xl * 2, 1, 0),
        Position = UDim2.new(0, Space.xl, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn,
    })
    applyFont(label, "LabelLarge")

    local stroke
    if variant == "Outlined" then
        stroke = addStroke(btn, Color3.new(1, 1, 1), 1)
    end

    if variant == "Elevated" then
        addShadow(btn, 1)
    end

    local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), height / 2)
    local comp = newComponent(self, btn)
    local isHovering = false

    local function apply()
        local bgRole, fgRole
        if variant == "Filled" then
            bgRole, fgRole = "Primary", "OnPrimary"
        elseif variant == "Tonal" then
            bgRole, fgRole = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Elevated" then
            bgRole, fgRole = "SurfaceContainerLow", "Primary"
        elseif variant == "Outlined" then
            fgRole = "Primary"
        else
            fgRole = "Primary"
        end

        if bgRole then
            btn.BackgroundColor3 = self:Color(bgRole)
            btn.BackgroundTransparency = disabled and 0.62 or 0
        else
            btn.BackgroundColor3 = self:Color("Surface")
            btn.BackgroundTransparency = 1
        end

        label.TextColor3 = self:Color(fgRole)
        label.TextTransparency = disabled and 0.62 or 0
        stateLayer.BackgroundColor3 = self:Color(fgRole)

        if stroke then
            stroke.Color = self:Color("Outline")
            stroke.Transparency = disabled and 0.62 or 0
        end
    end

    comp:SetThemeFn(apply)

    comp:Connect(btn.MouseEnter, function()
        if disabled then return end
        isHovering = true
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseLeave, function()
        if disabled then return end
        isHovering = false
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseButton1Down, function()
        if disabled then return end
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Pressed }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseButton1Up, function()
        if disabled then return end
        tween(stateLayer, {
            BackgroundTransparency = isHovering and StateOpacity.Hover or 1
        }, Dur.micro, "standard")
    end)

    comp:Connect(btn.InputBegan, function(input)
        if disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - btn.AbsolutePosition.X
            local relY = input.Position.Y - btn.AbsolutePosition.Y
            playRipple(btn, relX, relY, label.TextColor3)
        end
    end)

    if props.OnClick then
        comp:Connect(btn.MouseButton1Click, function()
            if disabled then return end
            props.OnClick()
        end)
    end

    function comp:SetText(t) label.Text = t end
    function comp:SetEnabled(v)
        disabled = not v
        btn.Active = v
        apply()
    end

    return comp
end

--------------------------------------------------------------------
-- 5.2 IconButton
--------------------------------------------------------------------
function MD3:IconButton(props)
    props = props or {}
    local size    = props.Size or 40
    local variant = props.Variant or "Standard"

    local btn = create("TextButton", {
        Name = "MD3_IconButton",
        Text = "",
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(btn, size / 2)

    local img = create("ImageLabel", {
        Image = props.Icon or "rbxassetid://0",
        Size = UDim2.new(0, size * 0.55, 0, size * 0.55),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.new(1, 1, 1),
        Parent = btn,
    })

    local stroke
    if variant == "Outlined" then
        stroke = addStroke(btn, Color3.new(1, 1, 1), 1)
    end

    local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), size / 2)
    local comp = newComponent(self, btn)

    local function apply()
        local bg, fg
        if variant == "Filled" then
            bg, fg = "Primary", "OnPrimary"
        elseif variant == "Tonal" then
            bg, fg = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Outlined" then
            bg, fg = nil, "OnSurfaceVariant"
            if stroke then
                stroke.Color = self:Color("Outline")
                stroke.Transparency = 0
            end
        else
            bg, fg = nil, "OnSurfaceVariant"
        end

        if bg then
            btn.BackgroundColor3 = self:Color(bg)
            btn.BackgroundTransparency = 0
        else
            btn.BackgroundColor3 = self:Color("Surface")
            btn.BackgroundTransparency = 1
        end
        img.ImageColor3 = self:Color(fg)
        stateLayer.BackgroundColor3 = self:Color(fg)
    end

    comp:SetThemeFn(apply)

    comp:Connect(btn.MouseEnter, function()
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseLeave, function()
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(btn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - btn.AbsolutePosition.X
            local relY = input.Position.Y - btn.AbsolutePosition.Y
            playRipple(btn, relX, relY, img.ImageColor3)
        end
    end)

    if props.OnClick then
        comp:Connect(btn.MouseButton1Click, props.OnClick)
    end

    function comp:SetIcon(id) img.Image = id end
    return comp
end

--------------------------------------------------------------------
-- 5.3 FAB (16dp 圆角)
--------------------------------------------------------------------
function MD3:FAB(props)
    props = props or {}
    local size    = props.Size or 56
    local variant = props.Variant or "Primary"

    local btn = create("TextButton", {
        Name = "MD3_FAB",
        Text = "",
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(btn, 16)

    local img = create("ImageLabel", {
        Image = props.Icon or "rbxassetid://0",
        Size = UDim2.new(0, size * 0.5, 0, size * 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = btn,
    })

    addShadow(btn, 3)
    local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), 16)
    local comp = newComponent(self, btn)

    comp:SetThemeFn(function()
        local bg, fg
        if variant == "Primary" then
            bg, fg = "PrimaryContainer", "OnPrimaryContainer"
        elseif variant == "Secondary" then
            bg, fg = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Tertiary" then
            bg, fg = "TertiaryContainer", "OnTertiaryContainer"
        else
            bg, fg = "SurfaceContainerHigh", "Primary"
        end
        btn.BackgroundColor3 = self:Color(bg)
        img.ImageColor3 = self:Color(fg)
        stateLayer.BackgroundColor3 = self:Color(fg)
    end)

    comp:Connect(btn.MouseEnter, function()
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseLeave, function()
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(btn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - btn.AbsolutePosition.X
            local relY = input.Position.Y - btn.AbsolutePosition.Y
            playRipple(btn, relX, relY, img.ImageColor3)
        end
    end)

    if props.OnClick then
        comp:Connect(btn.MouseButton1Click, props.OnClick)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.4 ExtendedFAB (新增)
--------------------------------------------------------------------
function MD3:ExtendedFAB(props)
    props = props or {}
    local variant = props.Variant or "Primary"
    local height  = props.Height or 56
    local width   = props.Width  or 140

    local btn = create("TextButton", {
        Name = "MD3_ExtendedFAB",
        Text = "",
        Size = UDim2.new(0, width, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(btn, 16)
    addShadow(btn, 3)

    local img = create("ImageLabel", {
        Name = "Icon",
        Image = props.Icon or "rbxassetid://0",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, Space.lg, 0.5, -12),
        BackgroundTransparency = 1,
        Parent = btn,
    })

    local label = create("TextLabel", {
        Name = "Label",
        Text = props.Text or "Extended",
        Size = UDim2.new(1, -Space.lg - 24 - Space.sm, 1, 0),
        Position = UDim2.new(0, Space.lg + 24 + Space.sm, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn,
    })
    applyFont(label, "LabelLarge")

    local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), 16)
    local comp = newComponent(self, btn)

    comp:SetThemeFn(function()
        local bg, fg
        if variant == "Primary" then
            bg, fg = "PrimaryContainer", "OnPrimaryContainer"
        elseif variant == "Secondary" then
            bg, fg = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Tertiary" then
            bg, fg = "TertiaryContainer", "OnTertiaryContainer"
        else
            bg, fg = "SurfaceContainerHigh", "Primary"
        end
        btn.BackgroundColor3 = self:Color(bg)
        img.ImageColor3 = self:Color(fg)
        label.TextColor3 = self:Color(fg)
        stateLayer.BackgroundColor3 = self:Color(fg)
    end)

    comp:Connect(btn.MouseEnter, function()
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(btn.MouseLeave, function()
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(btn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - btn.AbsolutePosition.X
            local relY = input.Position.Y - btn.AbsolutePosition.Y
            playRipple(btn, relX, relY, label.TextColor3)
        end
    end)

    if props.OnClick then
        comp:Connect(btn.MouseButton1Click, props.OnClick)
    end

    function comp:SetText(t) label.Text = t end
    function comp:SetIcon(id) img.Image = id end

    return comp
end

--------------------------------------------------------------------
-- 5.5 Switch
--------------------------------------------------------------------
function MD3:Switch(props)
    props = props or {}
    local state = props.Default == true

    local container = create("TextButton", {
        Name = "MD3_Switch",
        Text = "",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Switch",
        Size = UDim2.new(1, -72, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })
    applyFont(label, "BodyLarge")

    local track = create("Frame", {
        Size = UDim2.new(0, 52, 0, 32),
        Position = UDim2.new(1, -52, 0.5, -16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(track, UDim.new(0.5, 0))

    local trackStroke = addStroke(track, Color3.new(1, 1, 1), 2)

    local thumb = create("Frame", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(thumb, UDim.new(0.5, 0))

    local comp = newComponent(self, container)

    local function apply(animate)
        local on = state
        local trackColor       = on and self:Color("Primary") or self:Color("SurfaceContainerHighest")
        local thumbColor       = on and self:Color("OnPrimary") or self:Color("Outline")
        local trackStrokeColor = self:Color("Outline")
        local trackStrokeTrans = on and 1 or 0

        local goalSize, goalPos
        if on then
            goalSize = UDim2.new(0, 28, 0, 28)
            goalPos  = UDim2.new(0, 20, 0.5, -14)
        else
            goalSize = UDim2.new(0, 24, 0, 24)
            goalPos  = UDim2.new(0, 4, 0.5, -12)
        end

        if animate then
            tween(track, { BackgroundColor3 = trackColor }, Dur.short, "standard")
            tween(trackStroke, { Transparency = trackStrokeTrans }, Dur.short, "standard")
            tween(thumb, {
                Position = goalPos, Size = goalSize,
                BackgroundColor3 = thumbColor,
            }, Dur.short, "spring")
        else
            track.BackgroundColor3 = trackColor
            trackStroke.Transparency = trackStrokeTrans
            thumb.Position = goalPos
            thumb.Size = goalSize
            thumb.BackgroundColor3 = thumbColor
        end

        trackStroke.Color = trackStrokeColor
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(function() apply(false) end)

    comp:Connect(container.MouseButton1Click, function()
        state = not state
        apply(true)
        if props.OnChanged then props.OnChanged(state) end
    end)

    function comp:Get() return state end
    function comp:Set(v, silent)
        state = v and true or false
        apply(true)
        if not silent and props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.6 Checkbox
--------------------------------------------------------------------
function MD3:Checkbox(props)
    props = props or {}
    local state = props.Default == true

    local container = create("TextButton", {
        Name = "MD3_Checkbox",
        Text = "",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local box = create("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(box, 2)
    local boxStroke = addStroke(box, Color3.new(1, 1, 1), 2)

    local check = create("Frame", {
        Size = UDim2.new(0, 12, 0, 8),
        Position = UDim2.new(0.5, -6, 0.5, -4),
        BackgroundTransparency = 1,
        Visible = state,
        Parent = box,
    })

    local tick1 = create("Frame", {
        Size = UDim2.new(0, 7, 0, 2),
        Position = UDim2.new(0, 0, 0, 4),
        Rotation = 45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = check,
    })
    local tick2 = create("Frame", {
        Size = UDim2.new(0, 11, 0, 2),
        Position = UDim2.new(0, 3, 0, 2),
        Rotation = -45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = check,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Checkbox",
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })
    applyFont(label, "BodyLarge")

    local comp = newComponent(self, container)

    local function apply()
        local bg = state and self:Color("Primary") or self:Color("Surface")
        local bgTrans = state and 0 or 1
        local strokeCol = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        local tickCol = self:Color("OnPrimary")

        box.BackgroundColor3 = bg
        box.BackgroundTransparency = bgTrans
        boxStroke.Color = strokeCol
        boxStroke.Transparency = state and 1 or 0
        tick1.BackgroundColor3 = tickCol
        tick2.BackgroundColor3 = tickCol
        check.Visible = state
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(apply)

    comp:Connect(container.MouseButton1Click, function()
        state = not state
        tween(box, {
            BackgroundColor3 = state and self:Color("Primary") or self:Color("Surface"),
            BackgroundTransparency = state and 0 or 1,
        }, Dur.short, "spring")

        boxStroke.Color = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        boxStroke.Transparency = state and 1 or 0
        check.Visible = state

        if props.OnChanged then props.OnChanged(state) end
    end)

    function comp:Get() return state end
    function comp:Set(v)
        state = v and true or false
        apply()
        if props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.7 Radio
--------------------------------------------------------------------
function MD3:Radio(props)
    props = props or {}
    local state = props.Default == true

    local container = create("TextButton", {
        Name = "MD3_Radio",
        Text = "",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local ring = create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundTransparency = 1,
        Parent = container,
    })
    addCorner(ring, UDim.new(0.5, 0))
    local ringStroke = addStroke(ring, Color3.new(1, 1, 1), 2)

    local dot = create("Frame", {
        Size = UDim2.new(0, state and 10 or 0, 0, state and 10 or 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = ring,
    })
    addCorner(dot, UDim.new(0.5, 0))

    local label = create("TextLabel", {
        Text = props.Text or "Option",
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })
    applyFont(label, "BodyLarge")

    local comp = newComponent(self, container)

    local function apply(animate)
        local ringCol = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        local dotCol  = self:Color("Primary")
        local goalSize = state and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)

        if animate then
            tween(ringStroke, { Color = ringCol }, Dur.short, "standard")
            tween(dot, { Size = goalSize, BackgroundColor3 = dotCol }, Dur.short, "spring")
        else
            ringStroke.Color = ringCol
            dot.Size = goalSize
            dot.BackgroundColor3 = dotCol
        end
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(function() apply(false) end)

    if props.Group then
        self._radioGroups[props.Group] = self._radioGroups[props.Group] or {}
        table.insert(self._radioGroups[props.Group], comp)
        comp._groupName = props.Group
    end

    comp:Connect(container.MouseButton1Click, function()
        if state then return end
        state = true
        apply(true)
        if props.OnChanged then props.OnChanged(true) end
        if comp._groupName then
            for _, other in ipairs(self._radioGroups[comp._groupName]) do
                if other ~= comp and other:Get() then
                    other:Set(false, true)
                end
            end
        end
    end)

    function comp:Get() return state end
    function comp:Set(v, silent)
        state = v and true or false
        apply(true)
        if not silent and props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.8 Slider (MD3 规范)
--------------------------------------------------------------------
function MD3:Slider(props)
    props = props or {}
    local min   = props.Min or 0
    local max   = props.Max or 100
    local value = props.Default or min
    if max <= min then max = min + 1 end

    local TRACK_HEIGHT   = 16
    local TRACK_THICK    = 4
    local THUMB_W        = 4
    local THUMB_H        = 44
    local THUMB_W_PRESS  = 2
    local TRACK_GAP      = 6
    local STOP_SIZE      = 4

    local container = create("Frame", {
        Name = "MD3_Slider",
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Slider",
        Size = UDim2.new(1, -60, 0, 20),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    applyFont(label, "BodyMedium")

    local valueLabel = create("TextLabel", {
        Text = tostring(math.floor(value + 0.5)),
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container,
    })
    applyFont(valueLabel, "LabelLarge")

    local TRACK_Y = 44

    local trackArea = create("Frame", {
        Name = "TrackArea",
        Size = UDim2.new(1, -THUMB_W, 0, TRACK_HEIGHT),
        Position = UDim2.new(0, THUMB_W / 2, 0, TRACK_Y - TRACK_HEIGHT / 2 + 2),
        BackgroundTransparency = 1,
        Parent = container,
    })

    local inactiveTrack = create("Frame", {
        Name = "InactiveTrack",
        Size = UDim2.new(1, 0, 0, TRACK_THICK),
        Position = UDim2.new(0, 0, 0.5, -TRACK_THICK / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = trackArea,
    })
    addCorner(inactiveTrack, UDim.new(0.5, 0))

    local stopIndicator = create("Frame", {
        Name = "StopIndicator",
        Size = UDim2.new(0, STOP_SIZE, 0, STOP_SIZE),
        Position = UDim2.new(1, STOP_SIZE * 2, 0.5, -STOP_SIZE / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = trackArea,
    })
    addCorner(stopIndicator, UDim.new(0.5, 0))

    local activeTrack = create("Frame", {
        Name = "ActiveTrack",
        Size = UDim2.new(0, 0, 0, TRACK_THICK),
        Position = UDim2.new(0, 0, 0.5, -TRACK_THICK / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = trackArea,
    })
    addCorner(activeTrack, UDim.new(0.5, 0))

    local thumb = create("Frame", {
        Name = "Thumb",
        Size = UDim2.new(0, THUMB_W, 0, THUMB_H),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = trackArea,
    })
    addCorner(thumb, UDim.new(0.5, 0))

    local stateRing = create("Frame", {
        Name = "StateRing",
        Size = UDim2.new(0, 40, 0, 40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = trackArea,
    })
    addCorner(stateRing, UDim.new(0.5, 0))

    local valueBubble = create("Frame", {
        Name = "ValueIndicator",
        Size = UDim2.new(0, 0, 0, 28),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0, 0, 0, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
        Parent = trackArea,
    })
    addCorner(valueBubble, 8)

    local bubbleLabel = create("TextLabel", {
        Text = "",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = valueBubble,
    })
    applyFont(bubbleLabel, "LabelMedium")

    local inputArea = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, THUMB_W * 2, 0, 48),
        Position = UDim2.new(0, -THUMB_W, 0, TRACK_Y - 20),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        AutoLocalize = false,
        ZIndex = 20,
        Parent = container,
    })

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        inactiveTrack.BackgroundColor3 = self:Color("SurfaceContainerHighest")
        activeTrack.BackgroundColor3 = self:Color("Primary")
        thumb.BackgroundColor3 = self:Color("Primary")
        stateRing.BackgroundColor3 = self:Color("Primary")
        stopIndicator.BackgroundColor3 = self:Color("Outline")
        valueBubble.BackgroundColor3 = self:Color("InverseSurface")
        bubbleLabel.TextColor3 = self:Color("InverseOnSurface")
        label.TextColor3 = self:Color("OnSurfaceVariant")
        valueLabel.TextColor3 = self:Color("OnSurface")
    end)

    local dragging = false
    local isHovering = false
    local currentRelX = (value - min) / (max - min)

    local function updateVisuals(relX)
        currentRelX = relX

        local trackW = trackArea.AbsoluteSize.X
        if trackW <= 1 then trackW = 300 end

        local thumbX = relX * trackW
        thumb.Position = UDim2.new(0, thumbX, 0.5, 0)
        stateRing.Position = UDim2.new(0, thumbX, 0.5, 0)
        valueBubble.Position = UDim2.new(0, thumbX, 0, -8)

        local activeW = math.max(0, thumbX - TRACK_GAP)
        activeTrack.Size = UDim2.new(0, activeW, 0, TRACK_THICK)

        local inactiveStart = math.min(trackW, thumbX + TRACK_GAP)
        local inactiveW = math.max(0, trackW - inactiveStart)
        inactiveTrack.Position = UDim2.new(0, inactiveStart, 0.5, -TRACK_THICK / 2)
        inactiveTrack.Size = UDim2.new(0, inactiveW, 0, TRACK_THICK)

        stopIndicator.Position = UDim2.new(0, trackW + TRACK_GAP, 0.5, -STOP_SIZE / 2)

        valueLabel.Text = tostring(math.floor(value + 0.5))
        bubbleLabel.Text = valueLabel.Text
    end

    local function updateFromAbsX(absX, silent)
        local trackW = trackArea.AbsoluteSize.X
        local trackAbsX = trackArea.AbsolutePosition.X
        if trackW <= 1 then return end

        local relX = math.clamp((absX - trackAbsX) / trackW, 0, 1)
        value = min + relX * (max - min)
        updateVisuals(relX)
        if not silent and props.OnChanged then props.OnChanged(value) end
    end

    task.defer(function()
        updateVisuals((value - min) / (max - min))
    end)

    comp:Connect(trackArea:GetPropertyChangedSignal("AbsoluteSize"), function()
        updateVisuals(currentRelX)
    end)

    local function setStateRing(trans, size)
        tween(stateRing, {
            BackgroundTransparency = trans,
            Size = size or UDim2.new(0, 40, 0, 40),
        }, Dur.micro, "standard")
    end

    local function setThumbWidth(w)
        tween(thumb, {
            Size = UDim2.new(0, w, 0, THUMB_H),
        }, Dur.short, "emphasized")
    end

    local function showBubble(show)
        valueBubble.Visible = true
        if show then
            valueBubble.Size = UDim2.new(0, 0, 0, 28)
            tween(valueBubble, { Size = UDim2.new(0, 48, 0, 28) }, Dur.short, "spring")
        else
            local t = tween(valueBubble, { Size = UDim2.new(0, 0, 0, 28) }, Dur.short, "standard")
            t.Completed:Connect(function()
                valueBubble.Visible = false
            end)
        end
    end

    comp:Connect(inputArea.MouseEnter, function()
        isHovering = true
        if not dragging then setStateRing(StateOpacity.Hover) end
    end)
    comp:Connect(inputArea.MouseLeave, function()
        isHovering = false
        if not dragging then setStateRing(1) end
    end)

    comp:Connect(inputArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setStateRing(StateOpacity.Dragged, UDim2.new(0, 44, 0, 44))
            setThumbWidth(THUMB_W_PRESS)
            showBubble(true)
            updateFromAbsX(input.Position.X)
        end
    end)

    comp:Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateFromAbsX(input.Position.X)
        end
    end)

    comp:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if not dragging then return end
            dragging = false
            setStateRing(isHovering and StateOpacity.Hover or 1, UDim2.new(0, 40, 0, 40))
            setThumbWidth(THUMB_W)
            showBubble(false)
        end
    end)

    function comp:Get() return value end
    function comp:Set(v)
        value = math.clamp(v, min, max)
        updateVisuals((value - min) / (max - min))
    end

    return comp
end

--------------------------------------------------------------------
-- 5.9 TextField
--------------------------------------------------------------------
function MD3:TextField(props)
    props = props or {}
    local height = props.Height or 56

    local container = create("Frame", {
        Name = "MD3_TextField",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local bg = create("Frame", {
        Size = UDim2.new(1, 0, 1, -2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(bg, 4)

    local underline = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })

    local focusLine = create("Frame", {
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0.5, 0, 1, -2),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })

    local label = create("TextLabel", {
        Text = props.Label or "Label",
        Size = UDim2.new(1, -Space.lg * 2, 0, 16),
        Position = UDim2.new(0, Space.lg, 0, 6),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })
    applyFont(label, "BodySmall")

    local box = create("TextBox", {
        Text = props.Default or "",
        PlaceholderText = props.Placeholder or "",
        Size = UDim2.new(1, -Space.lg * 2, 0, 24),
        Position = UDim2.new(0, Space.lg, 0, 24),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ClearTextOnFocus = false,
        TextEditable = props.ReadOnly ~= true,
        Parent = container,
    })
    applyFont(box, "BodyLarge")

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        bg.BackgroundColor3 = self:Color("SurfaceContainerHighest")
        underline.BackgroundColor3 = self:Color("OnSurfaceVariant")
        focusLine.BackgroundColor3 = self:Color("Primary")
        label.TextColor3 = self:Color("OnSurfaceVariant")
        box.TextColor3 = self:Color("OnSurface")
        box.PlaceholderColor3 = self:Color("OnSurfaceVariant")
    end)

    comp:Connect(box.Focused, function()
        tween(focusLine, { Size = UDim2.new(1, 0, 0, 2) }, Dur.short, "emphasized")
        label.TextColor3 = self:Color("Primary")
    end)

    comp:Connect(box.FocusLost, function()
        tween(focusLine, { Size = UDim2.new(0, 0, 0, 2) }, Dur.short, "emphasized")
        label.TextColor3 = self:Color("OnSurfaceVariant")
        if props.OnChanged then props.OnChanged(box.Text) end
    end)

    function comp:Get() return box.Text end
    function comp:Set(t) box.Text = t end

    return comp
end

--------------------------------------------------------------------
-- 5.10 SearchBar (新增)
--------------------------------------------------------------------
function MD3:SearchBar(props)
    props = props or {}
    local height = props.Height or 56

    local container = create("Frame", {
        Name = "MD3_SearchBar",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(container, height / 2)

    local searchIcon = create("ImageLabel", {
        Name = "SearchIcon",
        Image = props.Icon or "rbxassetid://0",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, Space.lg, 0.5, -12),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.new(1, 1, 1),
        Parent = container,
    })

    local box = create("TextBox", {
        Text = props.Default or "",
        PlaceholderText = props.Placeholder or "搜索...",
        Size = UDim2.new(1, -Space.lg - 24 - Space.md - Space.lg, 1, 0),
        Position = UDim2.new(0, Space.lg + 24 + Space.md, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ClearTextOnFocus = false,
        Parent = container,
    })
    applyFont(box, "BodyLarge")

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        container.BackgroundColor3 = self:Color("SurfaceContainerHigh")
        searchIcon.ImageColor3 = self:Color("OnSurfaceVariant")
        box.TextColor3 = self:Color("OnSurface")
        box.PlaceholderColor3 = self:Color("OnSurfaceVariant")
    end)

    comp:Connect(box.Focused, function()
        tween(container, {
            BackgroundColor3 = self:Color("SurfaceContainerHighest")
        }, Dur.short, "standard")
        searchIcon.ImageColor3 = self:Color("OnSurface")
    end)

    comp:Connect(box.FocusLost, function()
        tween(container, {
            BackgroundColor3 = self:Color("SurfaceContainerHigh")
        }, Dur.short, "standard")
        searchIcon.ImageColor3 = self:Color("OnSurfaceVariant")
        if props.OnSubmitted then props.OnSubmitted(box.Text) end
    end)

    comp:Connect(box:GetPropertyChangedSignal("Text"), function()
        if props.OnChanged then props.OnChanged(box.Text) end
    end)

    function comp:Get() return box.Text end
    function comp:Set(t) box.Text = t end
    function comp:Focus() box:CaptureFocus() end

    return comp
end

--------------------------------------------------------------------
-- 5.11 Chip
--------------------------------------------------------------------
function MD3:Chip(props)
    props = props or {}
    local selected = props.Selected == true
    local chipHeight = props.Height or 32

    local chip = create("TextButton", {
        Name = "MD3_Chip",
        Text = "",
        Size = resolveSize(props.Width, chipHeight, UDim2.new(0, 80, 0, chipHeight)),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(chip, 8)
    local stroke = addStroke(chip, Color3.new(1, 1, 1), 1)

    local label = create("TextLabel", {
        Text = props.Text or "Chip",
        Size = UDim2.new(1, -Space.lg * 2, 1, 0),
        Position = UDim2.new(0, Space.lg, 0, 0),
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = chip,
    })
    applyFont(label, "LabelLarge")

    local stateLayer = addStateLayer(chip, Color3.new(1, 1, 1), 8)
    local comp = newComponent(self, chip)

    comp:SetThemeFn(function()
        if selected then
            chip.BackgroundColor3 = self:Color("SecondaryContainer")
            chip.BackgroundTransparency = 0
            label.TextColor3 = self:Color("OnSecondaryContainer")
            stroke.Transparency = 1
            stateLayer.BackgroundColor3 = self:Color("OnSecondaryContainer")
        else
            chip.BackgroundColor3 = self:Color("Surface")
            chip.BackgroundTransparency = 1
            label.TextColor3 = self:Color("OnSurfaceVariant")
            stroke.Color = self:Color("Outline")
            stroke.Transparency = 0
            stateLayer.BackgroundColor3 = self:Color("OnSurfaceVariant")
        end
    end)

    comp:Connect(chip.MouseEnter, function()
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(chip.MouseLeave, function()
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(chip.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - chip.AbsolutePosition.X
            local relY = input.Position.Y - chip.AbsolutePosition.Y
            playRipple(chip, relX, relY, label.TextColor3)
        end
    end)

    comp:Connect(chip.MouseButton1Click, function()
        selected = not selected
        comp:RefreshTheme()
        if props.OnChanged then props.OnChanged(selected) end
    end)

    function comp:Get() return selected end
    function comp:Set(v)
        selected = v and true or false
        comp:RefreshTheme()
    end

    return comp
end

--------------------------------------------------------------------
-- 5.12 Badge (新增)
--------------------------------------------------------------------
function MD3:Badge(props)
    props = props or {}
    local variant = props.Variant or "Small"  -- Small / Large
    local count   = props.Count or 0
    local max     = props.Max or 99

    local isSmall = variant == "Small"
    local size = isSmall and 8 or 20
    local width = isSmall and 8 or (count >= 10 and 24 or 20)

    local badge = create("Frame", {
        Name = "MD3_Badge",
        Size = UDim2.new(0, width, 0, size),
        Position = props.Position or UDim2.new(1, -width, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = (props.ZIndex or 1) + 10,
        Parent = props.Parent,
    })
    addCorner(badge, size / 2)

    local label
    if not isSmall then
        label = create("TextLabel", {
            Text = count > max and (tostring(max) .. "+") or tostring(count),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = badge,
        })
        applyFont(label, "LabelSmall")
    end

    local comp = newComponent(self, badge)

    comp:SetThemeFn(function()
        badge.BackgroundColor3 = self:Color("Error")
        if label then label.TextColor3 = self:Color("OnError") end
    end)

    function comp:SetCount(n)
        count = n
        if label then
            label.Text = count > max and (tostring(max) .. "+") or tostring(count)
            badge.Size = UDim2.new(0, count >= 10 and 24 or 20, 0, 20)
        end
    end

    function comp:SetVisible(v)
        badge.Visible = v
    end

    return comp
end

--------------------------------------------------------------------
-- 5.13 Tooltip (新增)
--------------------------------------------------------------------
function MD3:Tooltip(props)
    props = props or {}
    local text    = props.Text or "Tooltip"
    local variant = props.Variant or "Plain"  -- Plain / Rich
    local target  = props.Target
    if not target then
        warn("[MD3UI] Tooltip 需要 Target 参数")
        return nil
    end

    local tooltip = create("Frame", {
        Name = "MD3_Tooltip",
        Size = variant == "Rich" and UDim2.new(0, 320, 0, 0) or UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 500,
        AutomaticSize = Enum.AutomaticSize.XY,
        Parent = self.ScreenGui,
    })
    addCorner(tooltip, 4)
    addPadding(tooltip, UDim.new(0, 8))
    addShadow(tooltip, 2)

    local label = create("TextLabel", {
        Text = text,
        Size = variant == "Rich" and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 1, 0),
        AutomaticSize = variant == "Rich" and Enum.AutomaticSize.Y or Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        TextWrapped = variant == "Rich",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = tooltip,
    })
    applyFont(label, variant == "Rich" and "BodyMedium" or "BodySmall")

    local comp = newComponent(self, tooltip)
    local hoverToken = 0

    comp:SetThemeFn(function()
        tooltip.BackgroundColor3 = self:Color("InverseSurface")
        label.TextColor3 = self:Color("InverseOnSurface")
    end)

    local function position()
        local targetPos = target.AbsolutePosition
        local targetSize = target.AbsoluteSize
        local tp = tooltip.AbsoluteSize

        local x = targetPos.X + targetSize.X / 2 - tp.X / 2
        local y = targetPos.Y - tp.Y - 8

        -- 超出屏幕上方时放下方
        if y < 0 then
            y = targetPos.Y + targetSize.Y + 8
        end

        tooltip.Position = UDim2.new(0, x, 0, y)
    end

    local function show()
        hoverToken = hoverToken + 1
        local myToken = hoverToken
        task.delay(props.Delay or 0.5, function()
            if myToken ~= hoverToken then return end
            tooltip.Visible = true
            position()
            tooltip.BackgroundTransparency = 1
            label.TextTransparency = 1
            tween(tooltip, { BackgroundTransparency = 0 }, Dur.short, "emphasizedDecel")
            tween(label, { TextTransparency = 0 }, Dur.short, "emphasizedDecel")
        end)
    end

    local function hide()
        hoverToken = hoverToken + 1
        tween(tooltip, { BackgroundTransparency = 1 }, Dur.micro, "standard")
        tween(label, { TextTransparency = 1 }, Dur.micro, "standard")
        task.delay(Dur.micro, function()
            tooltip.Visible = false
        end)
    end

    comp:Connect(target.MouseEnter, show)
    comp:Connect(target.MouseLeave, hide)

    return comp
end

--------------------------------------------------------------------
-- 5.14 Card
--------------------------------------------------------------------
function MD3:Card(props)
    props = props or {}
    local height = props.Height or 100

    local card = create("Frame", {
        Name = "MD3_Card",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(card, 12)
    addPadding(card, UDim.new(0, Space.lg))
    addList(card, { Padding = UDim.new(0, Space.sm) })

    if props.Elevated ~= false then
        addShadow(card, 1)
    end

    local titleLabel, bodyLabel, content

    if props.Title then
        titleLabel = create("TextLabel", {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 1,
            Parent = card,
        })
        applyFont(titleLabel, "TitleMedium")
    end

    if props.Body then
        bodyLabel = create("TextLabel", {
            Text = props.Body,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
            Parent = card,
        })
        applyFont(bodyLabel, "BodyMedium")
    end

    if props.Content then
        content = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Parent = card,
        })
        addList(content, { Padding = UDim.new(0, Space.sm) })
    end

    local comp = newComponent(self, card)

    comp:SetThemeFn(function()
        card.BackgroundColor3 = self:Color("SurfaceContainerHigh")
        if titleLabel then titleLabel.TextColor3 = self:Color("OnSurface") end
        if bodyLabel  then bodyLabel.TextColor3  = self:Color("OnSurfaceVariant") end
    end)

    comp.Content = content
    return comp
end

--------------------------------------------------------------------
-- 5.15 Divider
--------------------------------------------------------------------
function MD3:Divider(parent)
    local d = create("Frame", {
        Name = "MD3_Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
        Parent = parent,
    })
    local comp = newComponent(self, d)
    comp:SetThemeFn(function()
        d.BackgroundColor3 = self:Color("OutlineVariant")
    end)
    return comp
end

--------------------------------------------------------------------
-- 5.16 SectionTitle
--------------------------------------------------------------------
function MD3:SectionTitle(props)
    props = props or {}
    local label = create("TextLabel", {
        Name = "MD3_SectionTitle",
        Text = props.Text or "Section",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    applyFont(label, "TitleSmall")

    local comp = newComponent(self, label)
    comp:SetThemeFn(function()
        label.TextColor3 = self:Color("Primary")
    end)
    return comp
end

--------------------------------------------------------------------
-- 5.17 ListItem
--------------------------------------------------------------------
function MD3:ListItem(props)
    props = props or {}
    local height = props.Height or 60

    local item = create("TextButton", {
        Name = "MD3_ListItem",
        Text = "",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local headline = create("TextLabel", {
        Text = props.Headline or "Item",
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, Space.lg, 0, props.Supporting and (height/2 - 22) or (height/2 - 10)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = item,
    })
    applyFont(headline, "BodyLarge")

    local supporting
    if props.Supporting then
        supporting = create("TextLabel", {
            Text = props.Supporting,
            Size = UDim2.new(1, -80, 0, 16),
            Position = UDim2.new(0, Space.lg, 0, height/2 + 2),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = item,
        })
        applyFont(supporting, "BodyMedium")
    end

    local trailing
    if props.Trailing then
        trailing = create("TextLabel", {
            Text = props.Trailing,
            Size = UDim2.new(0, 64, 1, 0),
            Position = UDim2.new(1, -72, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = item,
        })
        applyFont(trailing, "LabelMedium")
    end

    local stateLayer = addStateLayer(item, Color3.new(1, 1, 1), 0)
    local comp = newComponent(self, item)

    comp:SetThemeFn(function()
        headline.TextColor3 = self:Color("OnSurface")
        if supporting then supporting.TextColor3 = self:Color("OnSurfaceVariant") end
        if trailing   then trailing.TextColor3   = self:Color("OnSurfaceVariant") end
        stateLayer.BackgroundColor3 = self:Color("OnSurface")
    end)

    comp:Connect(item.MouseEnter, function()
        tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(item.MouseLeave, function()
        tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(item.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local relX = input.Position.X - item.AbsolutePosition.X
            local relY = input.Position.Y - item.AbsolutePosition.Y
            playRipple(item, relX, relY, self:Color("OnSurface"))
        end
    end)

    if props.OnClick then
        comp:Connect(item.MouseButton1Click, props.OnClick)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.18 ProgressBar
--------------------------------------------------------------------
function MD3:ProgressBar(props)
    props = props or {}
    local barHeight = props.Height or 4

    local container = create("Frame", {
        Name = "MD3_ProgressBar",
        Size = resolveSize(props.Width, barHeight, UDim2.new(1, 0, 0, barHeight)),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(container, UDim.new(0.5, 0))

    local fill = create("Frame", {
        Size = UDim2.new(props.Value or 0, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(fill, UDim.new(0.5, 0))

    local comp = newComponent(self, container)
    local indeterminateActive = false

    comp:SetThemeFn(function()
        container.BackgroundColor3 = self:Color("SurfaceContainerHighest")
        fill.BackgroundColor3 = self:Color("Primary")
    end)

    function comp:SetValue(v)
        v = math.clamp(v, 0, 1)
        indeterminateActive = false
        tween(fill, { Size = UDim2.new(v, 0, 1, 0) }, Dur.short, "standard")
        fill.Position = UDim2.new(0, 0, 0, 0)
    end

    function comp:SetIndeterminate()
        if indeterminateActive then return end
        indeterminateActive = true
        fill.Size = UDim2.new(0.3, 0, 1, 0)
        task.spawn(function()
            while indeterminateActive and fill and fill.Parent do
                fill.Position = UDim2.new(-0.3, 0, 0, 0)
                local t = tween(fill, { Position = UDim2.new(1, 0, 0, 0) }, 1.4, "linear")
                t.Completed:Wait()
            end
        end)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.19 LoadingIndicator (新增)
--------------------------------------------------------------------
function MD3:LoadingIndicator(props)
    props = props or {}
    local size = props.Size or 40
    local strokeWidth = props.StrokeWidth or 4

    local container = create("Frame", {
        Name = "MD3_LoadingIndicator",
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    -- 底圈
    local track = create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(track, UDim.new(0.5, 0))
    local trackStroke = addStroke(track, Color3.new(1, 1, 1), strokeWidth)

    -- 旋转圆弧 (用 ImageLabel 旋转，或者用两个半圆拼合)
    -- 用 UIGradient + Frame 做弧线效果：这里用简化方案 - 旋转的实心圆点
    local spinner = create("Frame", {
        Name = "Spinner",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = container,
    })

    -- 弧线用一根 4dp 宽的条，两端圆角，然后旋转
    local arc = create("Frame", {
        Name = "Arc",
        Size = UDim2.new(0, size, 0, strokeWidth),
        Position = UDim2.new(0, 0, 0, size/2 - strokeWidth/2),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = spinner,
    })
    addCorner(arc, strokeWidth / 2)
    -- 只显示一半 (用 ClipsDescendants + mask 太复杂，直接接受整条)
    arc.Size = UDim2.new(0.5, 0, 0, strokeWidth)

    local comp = newComponent(self, container)
    local rotationConn = nil

    comp:SetThemeFn(function()
        trackStroke.Color = self:Color("SurfaceContainerHighest")
        trackStroke.Transparency = 0
        arc.BackgroundColor3 = self:Color("Primary")
    end)

    -- 旋转动画
    local rotation = 0
    rotationConn = RunService.RenderStepped:Connect(function(dt)
        if comp._destroyed then return end
        rotation = (rotation + dt * 360) % 360
        spinner.Rotation = rotation
    end)
    table.insert(comp._connections, rotationConn)

    return comp
end

--------------------------------------------------------------------
-- 5.20 Dialog
--------------------------------------------------------------------
function MD3:Dialog(props)
    props = props or {}
    local dialogWidth  = props.Width  or 320
    local dialogHeight = props.Height or 200

    local scrim = create("TextButton", {
        Name = "MD3_Scrim",
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        AutoLocalize = false,
        Visible = false,
        ZIndex = 100,
        Parent = self.ScreenGui,
    })

    local dialog = create("Frame", {
        Name = "MD3_Dialog",
        Size = UDim2.new(0, dialogWidth, 0, dialogHeight),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = false,
        ZIndex = 101,
        Parent = self.ScreenGui,
    })
    addCorner(dialog, 28)
    addShadow(dialog, 5)

    local uiScale = create("UIScale", { Scale = 1, Parent = dialog })

    local title = create("TextLabel", {
        Text = props.Title or "Dialog",
        Size = UDim2.new(1, -Space.xl * 2, 0, 32),
        Position = UDim2.new(0, Space.xl, 0, Space.xl),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = dialog,
    })
    applyFont(title, "HeadlineSmall")

    local body = create("TextLabel", {
        Text = props.Body or "",
        Size = UDim2.new(1, -Space.xl * 2, 0, 60),
        Position = UDim2.new(0, Space.xl, 0, Space.xl + 40),
        BackgroundTransparency = 1,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = dialog,
    })
    applyFont(body, "BodyMedium")

    local actions = create("Frame", {
        Size = UDim2.new(1, -Space.xl * 2, 0, 40),
        Position = UDim2.new(0, Space.xl, 1, -Space.xl - 40),
        BackgroundTransparency = 1,
        Parent = dialog,
    })
    addList(actions, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, Space.sm),
    })

    local comp = newComponent(self, dialog)

    comp:SetThemeFn(function()
        dialog.BackgroundColor3 = self:Color("SurfaceContainerHigh")
        title.TextColor3 = self:Color("OnSurface")
        body.TextColor3 = self:Color("OnSurfaceVariant")
    end)

    local buttons = {}
    for _, btnProps in ipairs(props.Actions or {}) do
        local b = self:Button({
            Parent = actions,
            Text = btnProps.Text,
            Variant = btnProps.Variant or "Text",
            Width = 84,
            Height = 40,
            OnClick = function()
                if btnProps.OnClick then btnProps.OnClick() end
                comp:Close()
            end,
        })
        table.insert(buttons, b)
    end

    local isOpen = false

    function comp:Open()
        if isOpen then return end
        isOpen = true
        scrim.Visible = true
        dialog.Visible = true
        scrim.BackgroundTransparency = 1
        uiScale.Scale = 0.85
        tween(scrim, { BackgroundTransparency = 0.5 }, Dur.medium, "standard")
        tween(uiScale, { Scale = 1 }, Dur.long, "emphasizedDecel")
    end

    function comp:Close()
        if not isOpen then return end
        isOpen = false
        tween(scrim, { BackgroundTransparency = 1 }, Dur.short, "standard")
        local t = tween(uiScale, { Scale = 0.85 }, Dur.short, "emphasizedAccel")
        t.Completed:Connect(function()
            if not isOpen then
                scrim.Visible = false
                dialog.Visible = false
                uiScale.Scale = 1
            end
        end)
    end

    function comp:IsOpen() return isOpen end

    comp:Connect(scrim.MouseButton1Click, function()
        if props.DismissOnScrim ~= false then comp:Close() end
    end)

    local baseDestroy = comp.Destroy
    function comp:Destroy()
        if comp._destroyed then return end
        if scrim and scrim.Parent then scrim:Destroy() end
        baseDestroy(comp)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.21 Snackbar (4dp 圆角)
--------------------------------------------------------------------
function MD3:Snackbar(props)
    props = props or {}
    local windowSelf = self

    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local snW = math.min(340, vp.X - 40)

    local container = create("Frame", {
        Name = "MD3_Snackbar",
        Size = UDim2.new(0, snW, 0, 52),
        Position = UDim2.new(0.5, 0, 1, 100),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = false,
        ZIndex = 200,
        Parent = self.ScreenGui,
    })
    addCorner(container, 4)
    addPadding(container, UDim.new(0, Space.lg))
    addShadow(container, 3)

    local label = create("TextLabel", {
        Text = "",
        Size = UDim2.new(1, -84, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })
    applyFont(label, "BodyMedium")

    local comp = newComponent(self, container)
    local actionBtn, hideToken = nil, 0

    comp:SetThemeFn(function()
        container.BackgroundColor3 = self:Color("InverseSurface")
        label.TextColor3 = self:Color("InverseOnSurface")
    end)

    function comp:Show(text, options)
        options = options or {}
        label.Text = text or ""

        if actionBtn then
            actionBtn:Destroy()
            actionBtn = nil
        end

        if options.Action then
            actionBtn = windowSelf:Button({
                Parent = container,
                Text = options.Action,
                Variant = "Text",
                Width = 72,
                Height = 32,
                OnClick = function()
                    if options.OnAction then options.OnAction() end
                    comp:Hide()
                end,
            })
            actionBtn.Root.Position = UDim2.new(1, -72, 0.5, -16)
        end

        hideToken = hideToken + 1
        local myToken = hideToken

        container.Visible = true
        tween(container, {
            Position = UDim2.new(0.5, 0, 1, -20)
        }, Dur.medium, "emphasizedDecel")

        local duration = options.Duration or props.Duration or 3
        task.delay(duration, function()
            if myToken == hideToken then comp:Hide() end
        end)
    end

    function comp:Hide()
        hideToken = hideToken + 1
        local t = tween(container, {
            Position = UDim2.new(0.5, 0, 1, 100)
        }, Dur.short, "emphasizedAccel")
        t.Completed:Connect(function()
            if container and container.Parent then
                container.Visible = false
            end
        end)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.22 SegmentedButton
--------------------------------------------------------------------
function MD3:SegmentedButton(props)
    props = props or {}
    local options = props.Options or {}
    local selectedIndex = props.Default or 1

    local container = create("Frame", {
        Name = "MD3_SegmentedButton",
        Size = resolveSize(props.Width, 40, UDim2.new(1, 0, 0, 40)),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    addList(container, {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local segments = {}
    local comp = newComponent(self, container)

    for i, optText in ipairs(options) do
        local btn = create("TextButton", {
            Name = "Seg_" .. i,
            Text = "",
            Size = UDim2.new(1 / #options, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            AutoLocalize = false,
            LayoutOrder = i,
            Parent = container,
        })

        local corner = Instance.new("UICorner")
        if #options == 1 then
            corner.CornerRadius = UDim.new(0.5, 0)
        elseif i == 1 then
            corner.CornerRadius = UDim.new(0, 20)
        elseif i == #options then
            corner.CornerRadius = UDim.new(0, 20)
        else
            corner.CornerRadius = UDim.new(0, 0)
        end
        corner.Parent = btn

        local stroke = addStroke(btn, Color3.new(1, 1, 1), 1)

        local lbl = create("TextLabel", {
            Text = optText,
            Size = UDim2.new(1, -Space.lg * 2, 1, 0),
            Position = UDim2.new(0, Space.lg, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        applyFont(lbl, "LabelLarge")

        local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), 0)

        local seg = {
            btn = btn, label = lbl, stroke = stroke,
            stateLayer = stateLayer, index = i,
        }
        table.insert(segments, seg)

        local function applySeg()
            local isSelected = (selectedIndex == i)
            if isSelected then
                btn.BackgroundColor3 = self:Color("SecondaryContainer")
                btn.BackgroundTransparency = 0
                lbl.TextColor3 = self:Color("OnSecondaryContainer")
                stroke.Transparency = 1
                stateLayer.BackgroundColor3 = self:Color("OnSecondaryContainer")
            else
                btn.BackgroundColor3 = self:Color("Surface")
                btn.BackgroundTransparency = 1
                lbl.TextColor3 = self:Color("OnSurface")
                stroke.Color = self:Color("Outline")
                stroke.Transparency = 0
                stateLayer.BackgroundColor3 = self:Color("OnSurface")
            end
        end

        seg.apply = applySeg

        comp:Connect(btn.MouseEnter, function()
            tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
        end)
        comp:Connect(btn.MouseLeave, function()
            tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
        end)

        comp:Connect(btn.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                local relX = input.Position.X - btn.AbsolutePosition.X
                local relY = input.Position.Y - btn.AbsolutePosition.Y
                playRipple(btn, relX, relY, lbl.TextColor3)
            end
        end)

        comp:Connect(btn.MouseButton1Click, function()
            if selectedIndex == i then return end
            selectedIndex = i
            for _, s in ipairs(segments) do s.apply() end
            if props.OnChanged then props.OnChanged(i, options[i]) end
        end)
    end

    comp:SetThemeFn(function()
        for _, s in ipairs(segments) do s.apply() end
    end)

    function comp:Get() return selectedIndex end
    function comp:GetValue() return options[selectedIndex] end
    function comp:Set(idx)
        if idx < 1 or idx > #options then return end
        selectedIndex = idx
        for _, s in ipairs(segments) do s.apply() end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.23 NavigationRail (新增)
--------------------------------------------------------------------
function MD3:NavigationRail(props)
    props = props or {}
    local railWidth = props.Width or 80
    local items     = props.Items or {}

    local rail = create("Frame", {
        Name = "MD3_NavigationRail",
        Size = UDim2.new(0, railWidth, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    addPadding(rail, UDim.new(0, Space.sm))
    addList(rail, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, Space.xs),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    -- 顶部 FAB 位 (可选)
    if props.FAB then
        local fabContainer = create("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Parent = rail,
        })
        local fab = self:FAB({
            Parent = fabContainer,
            Icon = props.FAB.Icon,
            Size = 56,
            OnClick = props.FAB.OnClick,
        })
        fab.Root.Position = UDim2.new(0.5, -28, 0.5, -28)
    end

    local buttons = {}
    local currentIndex = props.Default or 1
    local comp = newComponent(self, rail)

    for i, item in ipairs(items) do
        local btn = create("TextButton", {
            Name = "Rail_" .. i,
            Text = "",
            Size = UDim2.new(1, -Space.sm, 0, 56),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            AutoLocalize = false,
            LayoutOrder = i,
            Parent = rail,
        })

        -- 指示器 (药丸形)
        local indicator = create("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 56, 0, 32),
            Position = UDim2.new(0.5, -28, 0, 4),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = btn,
        })
        addCorner(indicator, 16)

        local icon = create("ImageLabel", {
            Name = "Icon",
            Image = item.Icon or "rbxassetid://0",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0.5, -12, 0, 8),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.new(1, 1, 1),
            Parent = btn,
        })

        local lbl = create("TextLabel", {
            Name = "Label",
            Text = item.Label or item.Text or "",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 0, 0, 36),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        applyFont(lbl, "LabelMedium")

        local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), 28)

        local itemRef = {
            btn = btn, indicator = indicator, icon = icon, label = lbl,
            stateLayer = stateLayer, index = i, data = item,
        }
        table.insert(buttons, itemRef)

        local function applyItem()
            local active = (currentIndex == i)
            if active then
                indicator.BackgroundColor3 = self:Color("SecondaryContainer")
                indicator.BackgroundTransparency = 0
                icon.ImageColor3 = self:Color("OnSecondaryContainer")
                lbl.TextColor3 = self:Color("OnSecondaryContainer")
                stateLayer.BackgroundColor3 = self:Color("OnSecondaryContainer")
            else
                indicator.BackgroundTransparency = 1
                icon.ImageColor3 = self:Color("OnSurfaceVariant")
                lbl.TextColor3 = self:Color("OnSurfaceVariant")
                stateLayer.BackgroundColor3 = self:Color("OnSurfaceVariant")
            end
        end

        itemRef.apply = applyItem

        comp:Connect(btn.MouseEnter, function()
            tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
        end)
        comp:Connect(btn.MouseLeave, function()
            tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
        end)

        comp:Connect(btn.MouseButton1Click, function()
            if currentIndex == i then return end
            currentIndex = i
            for _, b in ipairs(buttons) do b.apply() end
            if props.OnChanged then props.OnChanged(i, item) end
        end)
    end

    comp:SetThemeFn(function()
        rail.BackgroundColor3 = self:Color("SurfaceContainer")
        for _, b in ipairs(buttons) do b.apply() end
    end)

    function comp:Get() return currentIndex end
    function comp:Set(idx)
        if idx < 1 or idx > #buttons then return end
        currentIndex = idx
        for _, b in ipairs(buttons) do b.apply() end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.24 BottomSheet
--------------------------------------------------------------------
function MD3:BottomSheet(props)
    props = props or {}
    local windowSelf = self

    local scrim = create("TextButton", {
        Name = "MD3_SheetScrim",
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        AutoLocalize = false,
        Visible = false,
        ZIndex = 150,
        Parent = self.ScreenGui,
    })

    local sheet = create("Frame", {
        Name = "MD3_BottomSheet",
        Size = UDim2.new(1, 0, 0, props.Height or 300),
        Position = UDim2.new(0, 0, 1, 1000),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = false,
        ZIndex = 151,
        Parent = self.ScreenGui,
    })

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 28)
    corner.Parent = sheet

    addShadow(sheet, 4)

    local dragHandle = create("Frame", {
        Name = "DragHandle",
        Size = UDim2.new(0, 32, 0, 4),
        Position = UDim2.new(0.5, -16, 0, 8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = sheet,
    })
    addCorner(dragHandle, UDim.new(0.5, 0))

    local content = create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -Space.xl * 2, 1, -Space.xxl),
        Position = UDim2.new(0, Space.xl, 0, Space.xxl),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.new(1, 1, 1),
        ScrollBarImageTransparency = 0.5,
        Parent = sheet,
    })
    addList(content, { Padding = UDim.new(0, Space.md) })

    local comp = newComponent(self, sheet)
    comp.Content = content

    local isOpen = false
    local sheetHeight = props.Height or 300

    comp:SetThemeFn(function()
        sheet.BackgroundColor3 = self:Color("SurfaceContainerLow")
        dragHandle.BackgroundColor3 = self:Color("OnSurfaceVariant")
    end)

    local dragStartY, sheetStartY = nil, nil
    comp:Connect(dragHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragStartY = input.Position.Y
            sheetStartY = sheet.Position.Y.Offset
        end
    end)
    comp:Connect(UserInputService.InputChanged, function(input)
        if not dragStartY then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position.Y - dragStartY
            if delta > 0 then
                sheet.Position = UDim2.new(0, 0, 1, sheetStartY + delta)
            end
        end
    end)
    comp:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragStartY then
                local delta = input.Position.Y - dragStartY
                if delta > 80 then
                    comp:Close()
                else
                    tween(sheet, { Position = UDim2.new(0, 0, 1, -sheetHeight) }, Dur.medium, "emphasizedDecel")
                end
                dragStartY = nil
            end
        end
    end)

    function comp:Open()
        if isOpen then return end
        isOpen = true
        scrim.Visible = true
        sheet.Visible = true
        scrim.BackgroundTransparency = 1
        sheet.Position = UDim2.new(0, 0, 1, sheetHeight)
        tween(scrim, { BackgroundTransparency = 0.5 }, Dur.medium, "standard")
        tween(sheet, { Position = UDim2.new(0, 0, 1, -sheetHeight) }, Dur.long, "emphasizedDecel")
    end

    function comp:Close()
        if not isOpen then return end
        isOpen = false
        tween(scrim, { BackgroundTransparency = 1 }, Dur.short, "standard")
        local t = tween(sheet, {
            Position = UDim2.new(0, 0, 1, sheetHeight + 20)
        }, Dur.medium, "emphasizedAccel")
        t.Completed:Connect(function()
            if not isOpen then
                scrim.Visible = false
                sheet.Visible = false
            end
        end)
    end

    function comp:IsOpen() return isOpen end

    comp:Connect(scrim.MouseButton1Click, function()
        if props.DismissOnScrim ~= false then comp:Close() end
    end)

    local baseDestroy = comp.Destroy
    function comp:Destroy()
        if comp._destroyed then return end
        if scrim and scrim.Parent then scrim:Destroy() end
        baseDestroy(comp)
    end

    return comp
end

--==================================================================
-- 6. 侧边栏窗口
--==================================================================
function MD3:CreateWindow(props)
    props = props or {}
    local windowSelf = self

    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)

    local maxW = vp.X * 0.92
    local maxH = vp.Y * 0.88
    local width  = math.min(props.Width  or 420, maxW)
    local height = math.min(props.Height or 480, maxH)

    local sidebarWidth = props.SidebarWidth or 120
    local topBarHeight = props.TopBarHeight or 48

    local main = create("Frame", {
        Name = "MD3_Window",
        Size = UDim2.new(0, width, 0, height),
        Position = props.Position or UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
    })
    addCorner(main, 20)
    addShadow(main, 4)

    local uiScale = create("UIScale", { Scale = props.Scale or 1, Parent = main })

    local topBar = create("TextButton", {
        Name = "TopBar",
        Text = "",
        Size = UDim2.new(1, 0, 0, topBarHeight),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AutoLocalize = false,
        ZIndex = 2,
        Parent = main,
    })

    local titleLabel = create("TextLabel", {
        Text = props.Title or "MD3UI",
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, Space.xl - 4, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
        Parent = topBar,
    })
    applyFont(titleLabel, "TitleMedium")

    local closeBtn = create("TextButton", {
        Name = "CloseBtn", Text = "✕",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -42, 0, (topBarHeight - 32) / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false, BorderSizePixel = 0,
        TextSize = 14, ZIndex = 5, AutoLocalize = false,
        Parent = main,
    })
    closeBtn.Font = Enum.Font.GothamBold
    addCorner(closeBtn, 16)
    local closeStateLayer = addStateLayer(closeBtn, Color3.new(1, 1, 1), 16)

    local minBtn = create("TextButton", {
        Name = "MinBtn", Text = "—",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -76, 0, (topBarHeight - 32) / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false, BorderSizePixel = 0,
        TextSize = 14, ZIndex = 5, AutoLocalize = false,
        Parent = main,
    })
    minBtn.Font = Enum.Font.GothamBold
    addCorner(minBtn, 16)
    local minStateLayer = addStateLayer(minBtn, Color3.new(1, 1, 1), 16)

    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -topBarHeight),
        Position = UDim2.new(0, 0, 0, topBarHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = main,
    })

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = body,
    })
    addPadding(sidebar, UDim.new(0, Space.sm))
    addList(sidebar, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, Space.xs),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    -- 拖动
    local dragging, dragStart, startPos = false, nil, nil

    local dragStartConn = topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos  = main.Position
        end
    end)

    local dragMoveConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local pos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = pos - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local dragEndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local comp = newComponent(self, main)
    table.insert(comp._connections, dragStartConn)
    table.insert(comp._connections, dragMoveConn)
    table.insert(comp._connections, dragEndConn)

    comp.Main        = main
    comp.TopBar      = topBar
    comp.Body        = body
    comp.Sidebar     = sidebar
    comp.ContentArea = contentArea
    comp.UIScale     = uiScale

    local tabs = {}
    local currentTab = nil
    comp.Tabs = tabs

    comp:SetThemeFn(function()
        main.BackgroundColor3    = self:Color("SurfaceContainerHigh")
        topBar.BackgroundColor3  = self:Color("SurfaceContainerHigh")
        sidebar.BackgroundColor3 = self:Color("SurfaceContainerLow")
        titleLabel.TextColor3    = self:Color("OnSurface")
        closeBtn.TextColor3      = self:Color("OnSurfaceVariant")
        minBtn.TextColor3        = self:Color("OnSurfaceVariant")
        closeStateLayer.BackgroundColor3 = self:Color("OnSurface")
        minStateLayer.BackgroundColor3   = self:Color("OnSurface")
        for _, t in ipairs(tabs) do t._refresh() end
    end)

    comp:Connect(closeBtn.MouseEnter, function()
        tween(closeStateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(closeBtn.MouseLeave, function()
        tween(closeStateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)
    comp:Connect(minBtn.MouseEnter, function()
        tween(minStateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
    end)
    comp:Connect(minBtn.MouseLeave, function()
        tween(minStateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
    end)

    comp:Connect(closeBtn.MouseButton1Click, function()
        comp:Destroy()
    end)

    local minimized   = false
    local savedHeight = height
    comp:Connect(minBtn.MouseButton1Click, function()
        minimized = not minimized
        if minimized then
            savedHeight = main.Size.Y.Offset
            tween(main, {
                Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, topBarHeight)
            }, Dur.medium, "emphasized")
        else
            tween(main, {
                Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, savedHeight)
            }, Dur.medium, "emphasized")
        end
    end)

    function comp:AddTab(tabProps)
        tabProps = tabProps or {}
        local tabTitle = tabProps.Title or ("Tab " .. (#tabs + 1))

        local btn = create("TextButton", {
            Name = "TabBtn_" .. tabTitle,
            Text = "",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            AutoLocalize = false,
            LayoutOrder = #tabs + 1,
            Parent = sidebar,
        })
        addCorner(btn, 20)

        local btnLabel = create("TextLabel", {
            Text = tabTitle,
            Size = UDim2.new(1, -Space.lg * 2, 1, 0),
            Position = UDim2.new(0, Space.lg, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })
        applyFont(btnLabel, "LabelLarge")

        local stateLayer = addStateLayer(btn, Color3.new(1, 1, 1), 20)

        local page = create("ScrollingFrame", {
            Name = "Page_" .. tabTitle,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.new(1, 1, 1),
            ScrollBarImageTransparency = 0.5,
            Visible = false,
            Parent = contentArea,
        })
        addPadding(page, UDim.new(0, Space.lg))
        addList(page, {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, Space.md),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local tab = {
            Title   = tabTitle,
            Button  = btn,
            Label   = btnLabel,
            Page    = page,
            Content = page,
            Window  = comp,
            _stateLayer = stateLayer,
        }

        function tab._refresh()
            local active = (currentTab == tab)
            if active then
                btn.BackgroundColor3       = windowSelf:Color("SecondaryContainer")
                btn.BackgroundTransparency = 0
                btnLabel.TextColor3        = windowSelf:Color("OnSecondaryContainer")
                stateLayer.BackgroundColor3 = windowSelf:Color("OnSecondaryContainer")
                page.Visible               = true
            else
                btn.BackgroundColor3       = windowSelf:Color("Surface")
                btn.BackgroundTransparency = 1
                btnLabel.TextColor3        = windowSelf:Color("OnSurfaceVariant")
                stateLayer.BackgroundColor3 = windowSelf:Color("OnSurfaceVariant")
                page.Visible               = false
            end
        end

        comp:Connect(btn.MouseEnter, function()
            if currentTab ~= tab then
                tween(stateLayer, { BackgroundTransparency = StateOpacity.Hover }, Dur.micro, "standard")
            end
        end)
        comp:Connect(btn.MouseLeave, function()
            tween(stateLayer, { BackgroundTransparency = 1 }, Dur.micro, "standard")
        end)

        comp:Connect(btn.MouseButton1Click, function()
            currentTab = tab
            for _, t in ipairs(tabs) do t._refresh() end
            comp.Content = tab.Content
        end)

        table.insert(tabs, tab)
        if #tabs == 1 then
            currentTab = tab
            comp.Content = tab.Content
            tab._refresh()
        end

        return tab
    end

    function comp:SetScale(s) uiScale.Scale = s end
    function comp:SetTitle(t) titleLabel.Text = t end

    return comp
end

--==================================================================
return MD3