--[[
    MD3UI v1.2.0
    Material Design 3 UI Library for Roblox

    特性:
      • 完整 MD3 颜色 Token 系统 (Dark / Light)
      • 17+ 组件 (Button, FAB, Switch, Checkbox, Radio, Slider, TextField,
        Chip, Card, Divider, SectionTitle, ListItem, ProgressBar,
        Dialog, Snackbar, IconButton, Window)
      • 涟漪 (Ripple) 效果
      • 鼠标 + 触摸 支持
      • 实时主题切换（无需重建）
      • 统一销毁 / 连接管理
      • UIScale 响应式缩放

    用法:
        local MD3 = require(path.to.MD3UI)
        local ui = MD3.new({ Theme = "Dark" })
        ui:Button({ Parent = someFrame, Text = "Click me", OnClick = function() print("!") end })
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local MD3 = {}
MD3.__index = MD3
MD3.Version = "1.2.0"

--==================================================================
-- 1. 颜色系统 (MD3 Color Tokens)
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
        SurfaceContainerLowest   = hex("#0F0D13"),
        SurfaceContainerLow      = hex("#1D1B20"),
        SurfaceContainer         = hex("#211F26"),
        SurfaceContainerHigh     = hex("#2B2930"),
        SurfaceContainerHighest  = hex("#36343B"),

        Outline = hex("#938F99"), OutlineVariant = hex("#49454F"),

        InverseSurface = hex("#E6E1E5"), InverseOnSurface = hex("#322F35"),
        InversePrimary = hex("#6750A4"),

        Shadow = hex("#000000"), Scrim = hex("#000000"),
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
        SurfaceContainerLowest   = hex("#FFFFFF"),
        SurfaceContainerLow      = hex("#F7F2FA"),
        SurfaceContainer         = hex("#F3EDF7"),
        SurfaceContainerHigh     = hex("#ECE6F0"),
        SurfaceContainerHighest  = hex("#E6E0E9"),

        Outline = hex("#79747E"), OutlineVariant = hex("#CAC4D0"),

        InverseSurface = hex("#322F35"), InverseOnSurface = hex("#F5EFF7"),
        InversePrimary = hex("#D0BCFF"),

        Shadow = hex("#000000"), Scrim = hex("#000000"),
    },
}

--==================================================================
-- 2. 工具函数
--==================================================================

local function create(className, props)
    local inst = Instance.new(className)
    if props then
        local parent = props.Parent
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
        inst.Parent = parent
    end
    return inst
end

local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    if typeof(radius) == "number" then
        c.CornerRadius = UDim.new(0, radius)
    else
        c.CornerRadius = radius
    end
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

local function tween(inst, props, time, style, dir)
    local info = TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- 涟漪效果
local function playRipple(parent, relX, relY, color)
    if not parent or not parent.Parent then return end
    local maxDim = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    if maxDim <= 2 then return end

    local ripple = create("Frame", {
        Name = "MD3_Ripple",
        BackgroundColor3 = color or Color3.new(1, 1, 1),
        BackgroundTransparency = 0.65,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, relX, 0, relY),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = parent.ZIndex + 1,
        Parent = parent,
    })
    addCorner(ripple, UDim.new(0.5, 0))

    local target = maxDim * 2
    local t = TweenService:Create(
        ripple,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
        if self._destroyed then return end
        local conn = signal:Connect(fn)
        table.insert(self._connections, conn)
        return conn
    end

    function comp:SetThemeFn(fn)
        self._themeFn = fn
        fn()
    end

    function comp:RefreshTheme()
        if self._themeFn and not self._destroyed then
            self._themeFn()
        end
    end

    function comp:SetVisible(v)
        if self.Root then self.Root.Visible = v end
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

        for i, c in ipairs(window._components) do
            if c == self then
                table.remove(window._components, i)
                break
            end
        end

        if self.Root and self.Root.Parent then
            self.Root:Destroy()
        end
    end

    table.insert(window._components, comp)
    return comp
end

--==================================================================
-- 4. 窗口 (MD3 Instance)
--==================================================================

function MD3.new(props)
    props = props or {}
    local self = setmetatable({}, MD3)

    self._themeName = props.Theme or "Dark"
    self._theme     = MD3.Theme[self._themeName] or MD3.Theme.Dark
    self._components = {}
    self._defaultParent = props.Parent or game:GetService("CoreGui")

    self.ScreenGui = create("ScreenGui", {
        Name = props.Name or "MD3UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = props.DisplayOrder or 1,
        Parent = self._defaultParent,
    })

    return self
end

function MD3:Color(role)
    return self._theme[role] or Color3.new(1, 1, 1)
end

function MD3:GetThemeName()
    return self._themeName
end

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
        if not comp._destroyed then
            comp:RefreshTheme()
        end
    end
end

function MD3:Destroy()
    local copy = table.clone(self._components)
    for _, comp in ipairs(copy) do
        comp:Destroy()
    end
    self._components = {}
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

--==================================================================
-- 5. 组件 API
--==================================================================

--------------------------------------------------------------------
-- 5.1 Button  (Filled / Tonal / Outlined / Text / Elevated)
--------------------------------------------------------------------
function MD3:Button(props)
    props = props or {}
    local variant = props.Variant or "Filled"
    local text    = props.Text or "Button"
    local height  = props.Height or 40
    local width   = props.Width  -- number 或 UDim2
    local disabled = props.Disabled or false

    local size
    if width == nil then
        size = UDim2.new(1, 0, 0, height)
    elseif typeof(width) == "number" then
        size = UDim2.new(0, width, 0, height)
    else
        size = width
    end

    local btn = create("TextButton", {
        Name = "MD3_Button",
        Text = "",
        Size = size,
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        TextTransparency = 1,
        ClipsDescendants = true,
        Active = not disabled,
        AutoLocalize = false,
        Parent = props.Parent,
    })
    addCorner(btn, height / 2)

    local label = create("TextLabel", {
        Name = "Label",
        Text = text,
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = props.TextSize or 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn,
    })

    local stroke = nil
    if variant == "Outlined" then
        stroke = addStroke(btn, Color3.new(1, 1, 1), 1)
        stroke.Transparency = 1
    end

    local comp = newComponent(self, btn)

    comp:SetThemeFn(function()
        local bgRole, fgRole, strokeRole
        if variant == "Filled" then
            bgRole, fgRole = "Primary", "OnPrimary"
        elseif variant == "Tonal" then
            bgRole, fgRole = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Elevated" then
            bgRole, fgRole = "SurfaceContainerLow", "Primary"
        elseif variant == "Outlined" then
            fgRole, strokeRole = "Primary", "Outline"
        elseif variant == "Text" then
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
        if stroke then
            stroke.Color = self:Color(strokeRole or "Outline")
            stroke.Transparency = disabled and 0.62 or 0
        end
    end)

    comp:Connect(btn.MouseEnter, function()
        if disabled then return end
        if variant == "Filled" or variant == "Tonal" or variant == "Elevated" then
            btn.BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.08)
        elseif variant == "Text" or variant == "Outlined" then
            btn.BackgroundColor3 = self:Color("Primary")
            btn.BackgroundTransparency = 0.92
        end
    end)

    comp:Connect(btn.MouseLeave, function()
        if disabled then return end
        comp:RefreshTheme()
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
        comp:RefreshTheme()
    end

    return comp
end

--------------------------------------------------------------------
-- 5.2 IconButton
--------------------------------------------------------------------
function MD3:IconButton(props)
    props = props or {}
    local size = props.Size or 40
    local variant = props.Variant or "Standard"  -- Standard / Filled / Tonal / Outlined
    local icon = props.Icon or "rbxassetid://0"

    local btn = create("TextButton", {
        Name = "MD3_IconButton",
        Text = "",
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        Parent = props.Parent,
    })
    addCorner(btn, size / 2)

    local img = create("ImageLabel", {
        Name = "Icon",
        Image = icon,
        Size = UDim2.new(0, size * 0.55, 0, size * 0.55),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.new(1, 1, 1),
        Parent = btn,
    })

    local stroke = nil
    if variant == "Outlined" then
        stroke = addStroke(btn, Color3.new(1, 1, 1), 1)
    end

    local comp = newComponent(self, btn)

    comp:SetThemeFn(function()
        local bg, fg, bgTrans
        if variant == "Filled" then
            bg, fg = "Primary", "OnPrimary"
        elseif variant == "Tonal" then
            bg, fg = "SecondaryContainer", "OnSecondaryContainer"
        elseif variant == "Outlined" then
            fg, bgTrans = "OnSurfaceVariant", 1
            if stroke then stroke.Color = self:Color("Outline") end
        else -- Standard
            fg, bgTrans = "OnSurfaceVariant", 1
        end
        btn.BackgroundColor3 = self:Color(bg or "Surface")
        btn.BackgroundTransparency = bgTrans or 0
        img.ImageColor3 = self:Color(fg)
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
-- 5.3 FAB (Floating Action Button)
--------------------------------------------------------------------
function MD3:FAB(props)
    props = props or {}
    local size = props.Size or 56
    local variant = props.Variant or "Primary"  -- Primary / Secondary / Tertiary / Surface
    local icon = props.Icon or "rbxassetid://0"

    local btn = create("TextButton", {
        Name = "MD3_FAB",
        Text = "",
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        Parent = props.Parent,
    })
    addCorner(btn, size / 2)

    local img = create("ImageLabel", {
        Image = icon,
        Size = UDim2.new(0, size * 0.5, 0, size * 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = btn,
    })

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
-- 5.4 Switch
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
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Switch",
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local track = create("Frame", {
        Size = UDim2.new(0, 52, 0, 32),
        Position = UDim2.new(1, -52, 0.5, -16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(track, UDim.new(0.5, 0))

    local thumb = create("Frame", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(thumb, UDim.new(0.5, 0))

    local comp = newComponent(self, container)

    local function applyVisuals(animate)
        local trackColor = state and self:Color("Primary") or self:Color("SurfaceVariant")
        local thumbColor = state and self:Color("OnPrimary") or self:Color("OnSurfaceVariant")
        local goalPos = state
            and UDim2.new(1, -28, 0.5, -12)
            or  UDim2.new(0, 4, 0.5, -12)

        if animate then
            tween(thumb, { Position = goalPos }, 0.2)
            tween(track, { BackgroundColor3 = trackColor }, 0.2)
            tween(thumb, { BackgroundColor3 = thumbColor }, 0.2)
        else
            thumb.Position = goalPos
            track.BackgroundColor3 = trackColor
            thumb.BackgroundColor3 = thumbColor
        end
    end

    comp:SetThemeFn(function() applyVisuals(false) end)

    comp:Connect(container.MouseButton1Click, function()
        state = not state
        applyVisuals(true)
        if props.OnChanged then props.OnChanged(state) end
    end)

    function comp:Get() return state end
    function comp:Set(v)
        state = v and true or false
        applyVisuals(true)
        if props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.5 Checkbox
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
        Parent = props.Parent,
    })

    local box = create("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(box, 2)
    local boxStroke = addStroke(box, Color3.new(1, 1, 1), 2)

    -- 勾选标记（用两条旋转的 Frame 拼出对勾）
    local check = create("Frame", {
        Size = UDim2.new(0, 10, 0, 6),
        Position = UDim2.new(0.5, -5, 0.5, -3),
        BackgroundTransparency = 1,
        Parent = box,
    })

    local function mkTick(size, pos, rot)
        return create("Frame", {
            Size = size,
            Position = pos,
            Rotation = rot,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = check,
        })
    end
    mkTick(UDim2.new(0, 6, 0, 2), UDim2.new(0, 0, 0, 3), 45)
    mkTick(UDim2.new(0, 10, 0, 2), UDim2.new(0, 2, 0, 1), -45)

    local label = create("TextLabel", {
        Text = props.Text or "Checkbox",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local comp = newComponent(self, container)

    local function applyVisuals(animate)
        local bg     = state and self:Color("Primary") or self:Color("Surface")
        local btrans = state and 0 or 1
        local strokeCol = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        local tickCol = self:Color("OnPrimary")

        if animate then
            tween(box, { BackgroundColor3 = bg, BackgroundTransparency = btrans }, 0.15)
            tween(boxStroke, { Color = strokeCol }, 0.15)
        else
            box.BackgroundColor3 = bg
            box.BackgroundTransparency = btrans
            boxStroke.Color = strokeCol
        end

        for _, t in ipairs(check:GetChildren()) do
            if t:IsA("Frame") then
                if animate then
                    tween(t, { BackgroundColor3 = tickCol }, 0.15)
                else
                    t.BackgroundColor3 = tickCol
                end
            end
        end
        check.Visible = state
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(function() applyVisuals(false) end)

    comp:Connect(container.MouseButton1Click, function()
        state = not state
        applyVisuals(true)
        if props.OnChanged then props.OnChanged(state) end
    end)

    function comp:Get() return state end
    function comp:Set(v)
        state = v and true or false
        applyVisuals(true)
        if props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.6 Radio Button
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
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = ring,
    })
    addCorner(dot, UDim.new(0.5, 0))

    local label = create("TextLabel", {
        Text = props.Text or "Option",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local comp = newComponent(self, container)

    local function applyVisuals(animate)
        local ringCol = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        local dotCol  = self:Color("Primary")
        local goalSize = state and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)

        if animate then
            tween(ringStroke, { Color = ringCol }, 0.15)
            tween(dot, { Size = goalSize, BackgroundColor3 = dotCol }, 0.15)
        else
            ringStroke.Color = ringCol
            dot.Size = goalSize
            dot.BackgroundColor3 = dotCol
        end
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(function() applyVisuals(false) end)

    comp:Connect(container.MouseButton1Click, function()
        state = true
        applyVisuals(true)
        if props.OnChanged then props.OnChanged(true) end
        if props.Group then
            for _, other in ipairs(props.Group) do
                if other ~= comp then other:Set(false) end
            end
        end
    end)

    function comp:Get() return state end
    function comp:Set(v)
        state = v and true or false
        applyVisuals(true)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.7 Slider
--------------------------------------------------------------------
function MD3:Slider(props)
    props = props or {}
    local min   = props.Min or 0
    local max   = props.Max or 100
    local value = props.Default or min
    if max <= min then max = min + 1 end

    local container = create("Frame", {
        Name = "MD3_Slider",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = (props.Text or "Slider"),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local valueLabel = create("TextLabel", {
        Text = tostring(math.floor(value)),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container,
    })

    local trackBg = create("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(trackBg, UDim.new(0.5, 0))

    local fill = create("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = trackBg,
    })
    addCorner(fill, UDim.new(0.5, 0))

    local thumb = create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = container,
    })
    addCorner(thumb, UDim.new(0.5, 0))

    -- 输入热区（比轨道更高，方便触摸）
    local inputArea = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 20, 0, 24),
        Position = UDim2.new(0, -10, 0, 26),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        AutoLocalize = false,
        Parent = container,
    })

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        trackBg.BackgroundColor3 = self:Color("SurfaceVariant")
        fill.BackgroundColor3 = self:Color("Primary")
        thumb.BackgroundColor3 = self:Color("Primary")
        label.TextColor3 = self:Color("OnSurface")
        valueLabel.TextColor3 = self:Color("OnSurfaceVariant")
    end)

    local dragging = false

    local function updateFromAbsX(absX)
        local relX = math.clamp(
            (absX - trackBg.AbsolutePosition.X) / math.max(trackBg.AbsoluteSize.X, 1),
            0, 1
        )
        value = min + relX * (max - min)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        thumb.Position = UDim2.new(relX, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value + 0.5))
        if props.OnChanged then props.OnChanged(value) end
    end

    comp:Connect(inputArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
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
            dragging = false
        end
    end)

    function comp:Get() return value end
    function comp:Set(v)
        value = math.clamp(v, min, max)
        local relX = (value - min) / (max - min)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        thumb.Position = UDim2.new(relX, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value + 0.5))
        if props.OnChanged then props.OnChanged(value) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.8 TextField
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
        Parent = props.Parent,
    })

    local bg = create("Frame", {
        Size = UDim2.new(1, 0, 1, -2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })
    -- MD3 filled 样式：只有上方圆角
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = bg

    -- 底部下划线
    local underline = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = container,
    })

    -- 聚焦指示线
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
        Size = UDim2.new(1, -32, 0, 16),
        Position = UDim2.new(0, 16, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local box = create("TextBox", {
        Text = props.Default or "",
        PlaceholderText = props.Placeholder or "",
        Size = UDim2.new(1, -32, 0, 24),
        Position = UDim2.new(0, 16, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ClearTextOnFocus = false,
        TextEditable = props.ReadOnly ~= true,
        Parent = container,
    })

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        bg.BackgroundColor3 = self:Color("SurfaceContainerHighest")
        underline.BackgroundColor3 = self:Color("OnSurfaceVariant")
        focusLine.BackgroundColor3 = self:Color("Primary")
        label.TextColor3 = self:Color("Primary")
        box.TextColor3 = self:Color("OnSurface")
        box.PlaceholderColor3 = self:Color("OnSurfaceVariant")
    end)

    comp:Connect(box.Focused, function()
        tween(focusLine, {
            Size = UDim2.new(1, 0, 0, 2),
        }, 0.2)
        label.TextColor3 = self:Color("Primary")
    end)

    comp:Connect(box.FocusLost, function()
        tween(focusLine, {
            Size = UDim2.new(0, 0, 0, 2),
        }, 0.2)
        label.TextColor3 = self:Color("OnSurfaceVariant")
        if props.OnChanged then props.OnChanged(box.Text) end
    end)

    comp:Connect(box:GetPropertyChangedSignal("Text"), function()
        if props.OnChanged then props.OnChanged(box.Text) end
    end)

    function comp:Get() return box.Text end
    function comp:Set(t) box.Text = t end

    return comp
end

--------------------------------------------------------------------
-- 5.9 Chip
--------------------------------------------------------------------
function MD3:Chip(props)
    props = props or {}
    local selected = props.Selected == true
    local text = props.Text or "Chip"

    local chip = create("TextButton", {
        Name = "MD3_Chip",
        Text = "",
        Size = props.Width or UDim2.new(0, 80, 0, 32),
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        AutoLocalize = false,
        Parent = props.Parent,
    })
    addCorner(chip, 8)
    local stroke = addStroke(chip, Color3.new(1, 1, 1), 1)

    local label = create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Parent = chip,
    })

    local comp = newComponent(self, chip)

    comp:SetThemeFn(function()
        if selected then
            chip.BackgroundColor3 = self:Color("SecondaryContainer")
            label.TextColor3 = self:Color("OnSecondaryContainer")
            stroke.Transparency = 1
        else
            chip.BackgroundColor3 = self:Color("Surface")
            chip.BackgroundTransparency = 1
            label.TextColor3 = self:Color("OnSurfaceVariant")
            stroke.Color = self:Color("Outline")
            stroke.Transparency = 0
        end
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
-- 5.10 Card
--------------------------------------------------------------------
function MD3:Card(props)
    props = props or {}
    local height = props.Height or 100

    local card = create("Frame", {
        Name = "MD3_Card",
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = props.Parent,
    })
    addCorner(card, 12)
    addPadding(card, UDim.new(0, 16))
    addList(card, { Padding = UDim.new(0, 8) })

    local titleLabel
    if props.Title then
        titleLabel = create("TextLabel", {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = card,
        })
    end

    local bodyLabel
    if props.Body then
        bodyLabel = create("TextLabel", {
            Text = props.Body,
            Size = UDim2.new(1, 0, 0, height - 60),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
            Parent = card,
        })
    end

    local content
    if props.Content then
        content = create("Frame", {
            Size = UDim2.new(1, 0, 0, height - 50),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Parent = card,
        })
        addList(content, { Padding = UDim.new(0, 8) })
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
-- 5.11 Divider
--------------------------------------------------------------------
function MD3:Divider(parent)
    local d = create("Frame", {
        Name = "MD3_Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = parent,
    })

    local comp = newComponent(self, d)
    comp:SetThemeFn(function()
        d.BackgroundColor3 = self:Color("OutlineVariant")
    end)
    return comp
end

--------------------------------------------------------------------
-- 5.12 Section Title
--------------------------------------------------------------------
function MD3:SectionTitle(props)
    props = props or {}

    local label = create("TextLabel", {
        Name = "MD3_SectionTitle",
        Text = props.Text or "Section",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = props.Parent,
    })

    local comp = newComponent(self, label)
    comp:SetThemeFn(function()
        label.TextColor3 = self:Color("Primary")
    end)
    return comp
end

--------------------------------------------------------------------
-- 5.13 ListItem
--------------------------------------------------------------------
function MD3:ListItem(props)
    props = props or {}
    local height = props.Height or 56

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
        Parent = props.Parent,
    })

    local headline = create("TextLabel", {
        Text = props.Headline or "Item",
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.new(0, 16, 0, props.Supporting and (height/2 - 20) or (height/2 - 9)),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = item,
    })

    local supporting
    if props.Supporting then
        supporting = create("TextLabel", {
            Text = props.Supporting,
            Size = UDim2.new(1, -80, 0, 16),
            Position = UDim2.new(0, 16, 0, height/2 + 2),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })
    end

    local trailing
    if props.Trailing then
        trailing = create("TextLabel", {
            Text = props.Trailing,
            Size = UDim2.new(0, 64, 1, 0),
            Position = UDim2.new(1, -80, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = item,
        })
    end

    local comp = newComponent(self, item)

    comp:SetThemeFn(function()
        headline.TextColor3 = self:Color("OnSurface")
        if supporting then supporting.TextColor3 = self:Color("OnSurfaceVariant") end
        if trailing   then trailing.TextColor3   = self:Color("OnSurfaceVariant") end
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
-- 5.14 ProgressBar (Linear)
--------------------------------------------------------------------
function MD3:ProgressBar(props)
    props = props or {}

    local container = create("Frame", {
        Name = "MD3_ProgressBar",
        Size = props.Width or UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
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

    -- 用于 indeterminate 模式的动画
    local indeterminateAnim = nil

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        container.BackgroundColor3 = self:Color("SurfaceContainerHighest")
        fill.BackgroundColor3 = self:Color("Primary")
    end)

    function comp:SetValue(v)
        v = math.clamp(v, 0, 1)
        if indeterminateAnim then
            indeterminateAnim:Cancel()
            indeterminateAnim = nil
        end
        fill.Size = UDim2.new(v, 0, 1, 0)
        fill.Position = UDim2.new(0, 0, 0, 0)
    end

    function comp:SetIndeterminate()
        if indeterminateAnim then return end
        fill.Size = UDim2.new(0.3, 0, 1, 0)
        local function loop()
            fill.Position = UDim2.new(-0.3, 0, 0, 0)
            indeterminateAnim = tween(fill, {
                Position = UDim2.new(1, 0, 0, 0)
            }, 1.4, Enum.EasingStyle.Linear)
            indeterminateAnim.Completed:Connect(function()
                if fill and fill.Parent and indeterminateAnim then
                    loop()
                end
            end)
        end
        loop()
    end

    return comp
end

--------------------------------------------------------------------
-- 5.15 Dialog
--------------------------------------------------------------------
function MD3:Dialog(props)
    props = props or {}

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
        Size = props.Width and UDim2.new(0, props.Width, 0, 0) or UDim2.new(0, 312, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 101,
        Parent = self.ScreenGui,
    })
    addCorner(dialog, 28)

    local layout = addList(dialog, { Padding = UDim.new(0, 0) })

    local title = create("TextLabel", {
        Text = props.Title or "Dialog",
        Size = UDim2.new(1, -48, 0, 32),
        Position = UDim2.new(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dialog,
    })

    local body = create("TextLabel", {
        Text = props.Body or "",
        Size = UDim2.new(1, -48, 0, 40),
        Position = UDim2.new(0, 24, 0, 60),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = dialog,
    })

    local actions = create("Frame", {
        Size = UDim2.new(1, -48, 0, 40),
        Position = UDim2.new(0, 24, 0, 110),
        BackgroundTransparency = 1,
        Parent = dialog,
    })
    addList(actions, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    })

    local comp = newComponent(self, dialog)
    comp.Root = dialog -- 注意 Root 只是 dialog，scrim 单独管理

    comp:SetThemeFn(function()
        dialog.BackgroundColor3 = self:Color("SurfaceContainerHigh")
        title.TextColor3 = self:Color("OnSurface")
        body.TextColor3 = self:Color("OnSurfaceVariant")
    end)

    -- 关闭按钮
    local buttons = {}
    for i, btnProps in ipairs(props.Actions or {}) do
        local b = self:Button({
            Parent = actions,
            Text = btnProps.Text,
            Variant = btnProps.Variant or "Text",
            Width = 0,
            OnClick = function()
                if btnProps.OnClick then btnProps.OnClick() end
                comp:Close()
            end,
        })
        b.Root.Size = UDim2.new(0, 0, 1, 0)
        b.Root.AutomaticSize = Enum.AutomaticSize.X
        b.Root.Size = UDim2.new(0, 0, 1, 0)
        b.Root.Visible = true
        b.Root.LayoutOrder = i
        b.Root.Size = UDim2.new(0, 80, 1, 0)
        table.insert(buttons, b)
    end

    local isOpen = false

    function comp:Open()
        if isOpen then return end
        isOpen = true
        scrim.Visible = true
        dialog.Visible = true
        scrim.BackgroundTransparency = 1

        tween(scrim, { BackgroundTransparency = 0.4 }, 0.2)
        dialog.Size = UDim2.new(0, dialog.AbsoluteSize.X, 0, 0)
        dialog.Size = UDim2.new(0, props.Width or 312, 0, 0)
        tween(dialog, { Size = UDim2.new(0, props.Width or 312, 0, 180) }, 0.25, Enum.EasingStyle.Quad)
    end

    function comp:Close()
        if not isOpen then return end
        isOpen = false
        tween(scrim, { BackgroundTransparency = 1 }, 0.18)
        local t = tween(dialog, { Size = UDim2.new(0, props.Width or 312, 0, 0) }, 0.2)
        t.Completed:Connect(function()
            scrim.Visible = false
            dialog.Visible = false
        end)
    end

    comp:Connect(scrim.MouseButton1Click, function()
        if props.DismissOnScrim ~= false then
            comp:Close()
        end
    end)

    -- 覆盖 Destroy 以同时清理 scrim
    local baseDestroy = comp.Destroy
    function comp:Destroy()
        if scrim and scrim.Parent then scrim:Destroy() end
        baseDestroy(self)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.16 Snackbar
--------------------------------------------------------------------
function MD3:Snackbar(props)
    props = props or {}

    local container = create("Frame", {
        Name = "MD3_Snackbar",
        Size = UDim2.new(0, 320, 0, 48),
        Position = UDim2.new(0.5, 0, 1, 100),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 200,
        Parent = self.ScreenGui,
    })
    addCorner(container, 8)
    addPadding(container, UDim.new(0, 12))

    local label = create("TextLabel", {
        Text = "",
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })

    local actionBtn = nil

    local comp = newComponent(self, container)

    comp:SetThemeFn(function()
        container.BackgroundColor3 = self:Color("InverseSurface")
        label.TextColor3 = self:Color("InverseOnSurface")
    end)

    local hideToken = 0

    function comp:Show(text, options)
        options = options or {}
        label.Text = text or props.Text or ""

        if actionBtn then
            actionBtn:Destroy()
            actionBtn = nil
        end

        if options.Action then
            actionBtn = self:Button({
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

        container.Visible = true
        hideToken = hideToken + 1
        local myToken = hideToken

        tween(container, { Position = UDim2.new(0.5, 0, 1, -16) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        local duration = options.Duration or props.Duration or 3
        task.delay(duration, function()
            if myToken == hideToken and container.Parent then
                comp:Hide()
            end
        end)
    end

    function comp:Hide()
        hideToken = hideToken + 1
        local t = tween(container, {
            Position = UDim2.new(0.5, 0, 1, 100)
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            if container and container.Parent then
                container.Visible = false
            end
        end)
    end

    return comp
end

--==================================================================
-- 6. Draggable Window
--==================================================================

function MD3:CreateWindow(props)
    props = props or {}
    local title = props.Title or "MD3 Window"
    local width = props.Width or 400
    local height = props.Height or 500

    local win = create("Frame", {
        Name = "MD3_Window",
        Size = UDim2.new(0, width, 0, height),
        Position = props.Position or UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    addCorner(win, 16)

    local uiScale = create("UIScale", {
        Scale = props.Scale or 1,
        Parent = win,
    })

    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        Parent = win,
    })

    local titleLabel = create("TextLabel", {
        Text = title,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    local closeBtn = create("TextButton", {
        Text = "✕",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -50, 0.5, -20),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoLocalize = false,
        Parent = titleBar,
    })
    addCorner(closeBtn, 20)

    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -32, 1, -72),
        Position = UDim2.new(0, 16, 0, 64),
        BackgroundTransparency = 1,
        Parent = win,
    })
    addList(content, { Padding = UDim.new(0, 10) })

    local comp = newComponent(self, win)
    comp.Content = content
    comp.TitleBar = titleBar
    comp.UIScale = uiScale

    comp:SetThemeFn(function()
        win.BackgroundColor3 = self:Color("SurfaceContainerHigh")
        titleLabel.TextColor3 = self:Color("OnSurface")
        closeBtn.TextColor3 = self:Color("OnSurfaceVariant")
    end)

    -- 拖拽逻辑
    local dragging = false
    local dragStart, startPos

    comp:Connect(titleBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)

    comp:Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    comp:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    comp:Connect(closeBtn.MouseButton1Click, function()
        comp:Destroy()
    end)

    function comp:SetScale(s) uiScale.Scale = s end
    function comp:SetTitle(t) titleLabel.Text = t end

    return comp
end

--==================================================================

return MD3