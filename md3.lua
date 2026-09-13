--[[
    MD3UI v1.3.1
    Material Design 3 UI Library for Roblox

    v1.3.1 修复:
      • tab._refresh 里 self 指向错误 (attempt to call missing method 'Color')
      • Snackbar:Show 里 self:Button 指向错误

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

local MD3 = {}
MD3.__index = MD3
MD3.Version = "1.3.1"

--==================================================================
-- 1. 颜色 Token
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

local function tween(inst, props, time, style, dir)
    local info = TweenInfo.new(
        time  or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function playRipple(parent, relX, relY, color)
    if not parent or not parent.Parent then return end
    local maxDim = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    if maxDim <= 4 then return end

    local ripple = create("Frame", {
        Name = "MD3_Ripple",
        BackgroundColor3 = color or Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, relX, 0, relY),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = (parent.ZIndex or 1) + 2,
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
-- 5. 基础组件
--==================================================================

--------------------------------------------------------------------
-- 5.1 Button
--------------------------------------------------------------------
function MD3:Button(props)
    props = props or {}
    local variant  = props.Variant or "Filled"
    local height   = props.Height or 40
    local width    = props.Width
    local disabled = props.Disabled == true

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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(btn, height / 2)

    local label = create("TextLabel", {
        Text = props.Text or "Button",
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = props.TextSize or 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btn,
    })

    local stroke
    if variant == "Outlined" then
        stroke = addStroke(btn, Color3.new(1, 1, 1), 1)
    end

    local comp = newComponent(self, btn)
    local isHovering = false

    local function apply(bgLerp)
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
            local bg = self:Color(bgRole)
            if bgLerp then bg = bg:Lerp(Color3.new(1, 1, 1), 0.1) end
            btn.BackgroundColor3 = bg
            btn.BackgroundTransparency = disabled and 0.62 or 0
        else
            btn.BackgroundColor3 = self:Color("Primary")
            btn.BackgroundTransparency = isHovering and 0.9 or 1
        end

        label.TextColor3 = self:Color(fgRole)
        label.TextTransparency = disabled and 0.62 or 0

        if stroke then
            stroke.Color = self:Color("Outline")
            stroke.Transparency = disabled and 0.62 or 0
        end
    end

    comp:SetThemeFn(function() apply(isHovering) end)

    comp:Connect(btn.MouseEnter, function()
        if disabled then return end
        isHovering = true
        apply(true)
    end)

    comp:Connect(btn.MouseLeave, function()
        if disabled then return end
        isHovering = false
        apply(false)
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
        apply(isHovering)
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

    local comp = newComponent(self, btn)
    local isHovering = false

    local function apply()
        if variant == "Filled" then
            btn.BackgroundColor3 = self:Color("Primary")
            btn.BackgroundTransparency = 0
            img.ImageColor3 = self:Color("OnPrimary")
        elseif variant == "Tonal" then
            btn.BackgroundColor3 = self:Color("SecondaryContainer")
            btn.BackgroundTransparency = 0
            img.ImageColor3 = self:Color("OnSecondaryContainer")
        elseif variant == "Outlined" then
            btn.BackgroundColor3 = self:Color("Primary")
            btn.BackgroundTransparency = isHovering and 0.9 or 1
            img.ImageColor3 = self:Color("Primary")
            if stroke then
                stroke.Color = self:Color("Outline")
                stroke.Transparency = 0
            end
        else
            btn.BackgroundColor3 = self:Color("Primary")
            btn.BackgroundTransparency = isHovering and 0.9 or 1
            img.ImageColor3 = self:Color("OnSurfaceVariant")
        end
    end

    comp:SetThemeFn(apply)

    comp:Connect(btn.MouseEnter, function()
        isHovering = true; apply()
    end)
    comp:Connect(btn.MouseLeave, function()
        isHovering = false; apply()
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
-- 5.3 FAB
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
    addCorner(btn, size / 2)

    local img = create("ImageLabel", {
        Image = props.Icon or "rbxassetid://0",
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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Switch",
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
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

    local function apply(animate)
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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
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

    local check = create("Frame", {
        Size = UDim2.new(0, 12, 0, 8),
        Position = UDim2.new(0.5, -6, 0.5, -4),
        BackgroundTransparency = 1,
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
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })

    local comp = newComponent(self, container)

    local function apply(animate)
        local bg = state and self:Color("Primary") or self:Color("SurfaceContainerHighest")
        local strokeCol = state and self:Color("Primary") or self:Color("OnSurfaceVariant")
        local tickCol = self:Color("OnPrimary")

        if animate then
            tween(box, { BackgroundColor3 = bg }, 0.15)
            tween(boxStroke, { Color = strokeCol }, 0.15)
            tween(tick1, { BackgroundColor3 = tickCol }, 0.15)
            tween(tick2, { BackgroundColor3 = tickCol }, 0.15)
        else
            box.BackgroundColor3 = bg
            boxStroke.Color = strokeCol
            tick1.BackgroundColor3 = tickCol
            tick2.BackgroundColor3 = tickCol
        end
        check.Visible = state
        label.TextColor3 = self:Color("OnSurface")
    end

    comp:SetThemeFn(function() apply(false) end)

    comp:Connect(container.MouseButton1Click, function()
        state = not state
        apply(true)
        if props.OnChanged then props.OnChanged(state) end
    end)

    function comp:Get() return state end
    function comp:Set(v)
        state = v and true or false
        apply(true)
        if props.OnChanged then props.OnChanged(state) end
    end

    return comp
end

--------------------------------------------------------------------
-- 5.6 Radio
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
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })

    local comp = newComponent(self, container)

    local function apply(animate)
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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })

    local label = create("TextLabel", {
        Text = props.Text or "Slider",
        Size = UDim2.new(1, -60, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local valueLabel = create("TextLabel", {
        Text = tostring(math.floor(value + 0.5)),
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
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

    local inputArea = create("TextButton", {
        Text = "",
        Size = UDim2.new(1, 20, 0, 28),
        Position = UDim2.new(0, -10, 0, 24),
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
        Size = UDim2.new(1, -32, 0, 16),
        Position = UDim2.new(0, 16, 0, 6),
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
        Position = UDim2.new(0, 16, 0, 22),
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
        label.TextColor3 = self:Color("OnSurfaceVariant")
        box.TextColor3 = self:Color("OnSurface")
        box.PlaceholderColor3 = self:Color("OnSurfaceVariant")
    end)

    comp:Connect(box.Focused, function()
        tween(focusLine, { Size = UDim2.new(1, 0, 0, 2) }, 0.2)
        label.TextColor3 = self:Color("Primary")
    end)

    comp:Connect(box.FocusLost, function()
        tween(focusLine, { Size = UDim2.new(0, 0, 0, 2) }, 0.2)
        label.TextColor3 = self:Color("OnSurfaceVariant")
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

    local chip = create("TextButton", {
        Name = "MD3_Chip",
        Text = "",
        Size = props.Width or UDim2.new(0, 80, 0, 32),
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
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = chip,
    })

    local comp = newComponent(self, chip)

    comp:SetThemeFn(function()
        if selected then
            chip.BackgroundColor3 = self:Color("SecondaryContainer")
            chip.BackgroundTransparency = 0
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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
        Parent = props.Parent,
    })
    addCorner(card, 12)
    addPadding(card, UDim.new(0, 16))
    addList(card, { Padding = UDim.new(0, 8) })

    local titleLabel, bodyLabel, content

    if props.Title then
        titleLabel = create("TextLabel", {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 1,
            Parent = card,
        })
    end

    if props.Body then
        bodyLabel = create("TextLabel", {
            Text = props.Body,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
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

    if props.Content then
        content = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
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
-- 5.12 SectionTitle
--------------------------------------------------------------------
function MD3:SectionTitle(props)
    props = props or {}
    local label = create("TextLabel", {
        Name = "MD3_SectionTitle",
        Text = props.Text or "Section",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
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
        LayoutOrder = props.LayoutOrder or self:_nextOrder(),
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
        TextTruncate = Enum.TextTruncate.AtEnd,
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
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = item,
        })
    end

    local trailing
    if props.Trailing then
        trailing = create("TextLabel", {
            Text = props.Trailing,
            Size = UDim2.new(0, 64, 1, 0),
            Position = UDim2.new(1, -72, 0, 0),
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
-- 5.14 ProgressBar
--------------------------------------------------------------------
function MD3:ProgressBar(props)
    props = props or {}

    local container = create("Frame", {
        Name = "MD3_ProgressBar",
        Size = props.Width or UDim2.new(1, 0, 0, 4),
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
        fill.Size = UDim2.new(v, 0, 1, 0)
        fill.Position = UDim2.new(0, 0, 0, 0)
    end

    function comp:SetIndeterminate()
        if indeterminateActive then return end
        indeterminateActive = true
        fill.Size = UDim2.new(0.3, 0, 1, 0)
        task.spawn(function()
            while indeterminateActive and fill and fill.Parent do
                fill.Position = UDim2.new(-0.3, 0, 0, 0)
                local t = tween(fill, { Position = UDim2.new(1, 0, 0, 0) }, 1.4, Enum.EasingStyle.Linear)
                t.Completed:Wait()
            end
        end)
    end

    return comp
end

--------------------------------------------------------------------
-- 5.15 Dialog
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
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 101,
        Parent = self.ScreenGui,
    })
    addCorner(dialog, 28)

    local title = create("TextLabel", {
        Text = props.Title or "Dialog",
        Size = UDim2.new(1, -48, 0, 32),
        Position = UDim2.new(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = dialog,
    })

    local body = create("TextLabel", {
        Text = props.Body or "",
        Size = UDim2.new(1, -48, 0, 60),
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
        Position = UDim2.new(0, 24, 1, -56),
        BackgroundTransparency = 1,
        Parent = dialog,
    })
    addList(actions, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
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
        dialog.BackgroundTransparency = 1
        title.TextTransparency = 1
        body.TextTransparency = 1

        tween(scrim, { BackgroundTransparency = 0.5 }, 0.2)
        tween(dialog, { BackgroundTransparency = 0 }, 0.2)
        tween(title, { TextTransparency = 0 }, 0.25)
        tween(body, { TextTransparency = 0 }, 0.25)
    end

    function comp:Close()
        if not isOpen then return end
        isOpen = false
        tween(scrim, { BackgroundTransparency = 1 }, 0.18)
        tween(dialog, { BackgroundTransparency = 1 }, 0.18)
        tween(title, { TextTransparency = 1 }, 0.18)
        tween(body, { TextTransparency = 1 }, 0.18)
        task.delay(0.2, function()
            if not isOpen then
                scrim.Visible = false
                dialog.Visible = false
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
-- 5.16 Snackbar
--------------------------------------------------------------------
function MD3:Snackbar(props)
    props = props or {}

    -- ⭐ 捕获外层 self (MD3 实例)
    local windowSelf = self

    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local snW = math.min(320, vp.X - 40)

    local container = create("Frame", {
        Name = "MD3_Snackbar",
        Size = UDim2.new(0, snW, 0, 48),
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
        Size = UDim2.new(1, -84, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container,
    })

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
            -- ⭐ 用外层 windowSelf 而不是 comp 自身
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
            Position = UDim2.new(0.5, 0, 1, -16)
        }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        local duration = options.Duration or props.Duration or 3
        task.delay(duration, function()
            if myToken == hideToken then comp:Hide() end
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
-- 6. 侧边栏窗口
--==================================================================
function MD3:CreateWindow(props)
    props = props or {}

    -- ⭐ 捕获外层 self (MD3 实例)，供 tab._refresh 使用
    local windowSelf = self

    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)

    local maxW = vp.X * 0.92
    local maxH = vp.Y * 0.88
    local width  = math.min(props.Width  or 400, maxW)
    local height = math.min(props.Height or 460, maxH)

    local sidebarWidth = props.SidebarWidth or 110
    local topBarHeight = props.TopBarHeight or 44

    -- 主窗
    local main = create("Frame", {
        Name = "MD3_Window",
        Size = UDim2.new(0, width, 0, height),
        Position = props.Position or UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
    })
    addCorner(main, 16)

    local uiScale = create("UIScale", { Scale = props.Scale or 1, Parent = main })

    -- 拖动栏（用 TextButton 兼容触摸）
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
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
        Parent = topBar,
    })

    -- 关闭按钮脱离 topBar，避免误触发拖动
    local closeBtn = create("TextButton", {
        Name = "CloseBtn",
        Text = "✕",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -40, 0, (topBarHeight - 32) / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 5,
        AutoLocalize = false,
        Parent = main,
    })
    addCorner(closeBtn, 16)

    local minBtn = create("TextButton", {
        Name = "MinBtn",
        Text = "—",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -74, 0, (topBarHeight - 32) / 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 5,
        AutoLocalize = false,
        Parent = main,
    })
    addCorner(minBtn, 16)

    -- Body
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
    addPadding(sidebar, UDim.new(0, 8))
    addList(sidebar, {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        BackgroundTransparency = 1,
        Parent = body,
    })

    -- 拖动逻辑
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

    -- 组件容器
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

    -- 主题
    comp:SetThemeFn(function()
        main.BackgroundColor3    = self:Color("SurfaceContainerHigh")
        topBar.BackgroundColor3  = self:Color("SurfaceContainerHigh")
        sidebar.BackgroundColor3 = self:Color("SurfaceContainerLow")
        titleLabel.TextColor3    = self:Color("OnSurface")
        closeBtn.TextColor3      = self:Color("OnSurfaceVariant")
        minBtn.TextColor3        = self:Color("OnSurfaceVariant")
        for _, t in ipairs(tabs) do t._refresh() end
    end)

    -- 关闭 / 最小化
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
            }, 0.22)
        else
            tween(main, {
                Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, savedHeight)
            }, 0.22)
        end
    end)

    -- AddTab
    function comp:AddTab(tabProps)
        tabProps = tabProps or {}
        local tabTitle = tabProps.Title or ("Tab " .. (#tabs + 1))

        local btn = create("TextButton", {
            Name = "TabBtn_" .. tabTitle,
            Text = "",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            AutoLocalize = false,
            LayoutOrder = #tabs + 1,
            Parent = sidebar,
        })
        addCorner(btn, 8)

        local btnLabel = create("TextLabel", {
            Text = tabTitle,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })

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
        addPadding(page, UDim.new(0, 14))
        addList(page, {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local tab = {
            Title   = tabTitle,
            Button  = btn,
            Label   = btnLabel,
            Page    = page,
            Content = page,
            Window  = comp,
        }

        -- ⭐ 关键修复：用 windowSelf 而非 self
        function tab._refresh()
            local active = (currentTab == tab)
            if active then
                btn.BackgroundColor3       = windowSelf:Color("SecondaryContainer")
                btn.BackgroundTransparency = 0
                btnLabel.TextColor3        = windowSelf:Color("OnSecondaryContainer")
                page.Visible               = true
            else
                btn.BackgroundColor3       = windowSelf:Color("SurfaceContainerLow")
                btn.BackgroundTransparency = 1
                btnLabel.TextColor3        = windowSelf:Color("OnSurfaceVariant")
                page.Visible               = false
            end
        end

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