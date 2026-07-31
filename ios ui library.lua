local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local iOSUI = {}
iOSUI.__index = iOSUI

local DEFAULT_THEME = {
    Primary = Color3.fromRGB(10, 132, 255),
    Accent  = Color3.fromRGB(88, 86, 214),
    BgTop   = Color3.fromRGB(250, 250, 252),
    BgBot   = Color3.fromRGB(245, 245, 247),
    Text    = Color3.fromRGB(10, 10, 10),
    ShadowId = "rbxassetid://1316045217"
}

local function createRipple(parent, color)
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0,0,0,0)
    ripple.AnchorPoint = Vector2.new(0.5,0.5)
    ripple.Position = UDim2.new(0.5,0,0.5,0)
    ripple.BackgroundColor3 = color or DEFAULT_THEME.Primary
    ripple.BackgroundTransparency = 0.45
    ripple.ZIndex = parent.ZIndex + 5
    ripple.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1,0)
    c.Parent = ripple
    local tween = TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {
        Size = UDim2.new(1.8,0,1.8,0),
        BackgroundTransparency = 1
    })
    tween:Play()
    Debris:AddItem(ripple, 0.5)
end

function iOSUI.new(config)
    config = config or {}
    local self = setmetatable({}, iOSUI)
    
    self.Theme = config.Theme or DEFAULT_THEME
    self.Player = Players.LocalPlayer
    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    self.ScreenGui = config.ScreenGui or Instance.new("ScreenGui")
    if not config.ScreenGui then
        self.ScreenGui.Name = "iOSUI_ScreenGui"
        self.ScreenGui.IgnoreGuiInset = true
        self.ScreenGui.ResetOnSpawn = false
        self.ScreenGui.Parent = self.PlayerGui
    end
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    self.UIScale = Instance.new("UIScale")
    self.UIScale.Parent = self.ScreenGui
    self:_setupScale()
    
    self.Background = nil
    if config.ShowBackground ~= false then
        self:_createBackground()
    end
 
    self:_createNotification()
    
    self.Windows = {}
    self.ActiveWindow = nil
    
    self._connections = {}
    
    return self
end

function iOSUI:_setupScale()
    local function rescale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vs = cam.ViewportSize
        local scale = math.min(vs.X / 1080, vs.Y / 1920) * 0.95
        self.UIScale.Scale = math.clamp(scale, 0.78, 1.12)
    end
    rescale()
    local conn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
    table.insert(self._connections, conn)
end

function iOSUI:_createBackground()
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundTransparency = 1
    bg.Parent = self.ScreenGui
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, self.Theme.Primary),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, self.Theme.BgBot)
    }
    gradient.Rotation = 90
    gradient.Parent = bg
    self.Background = bg
end

function iOSUI:_createNotification()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0, 44)
    frame.Position = UDim2.new(0.1, 0, -0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Parent = self.ScreenGui
    frame.ZIndex = 120
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, -12)
    label.Position = UDim2.new(0,6,0,6)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = self.Theme.Text
    label.Parent = frame
    label.ZIndex = 121
    
    self.Notification = { Frame = frame, Label = label }
end

function iOSUI:ShowNotification(message)
    local n = self.Notification
    if not n then return end
    n.Label.Text = message
    local frame = n.Frame
    frame.Visible = true
    TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.1,0,0.06,0)
    }):Play()
    task.delay(1.4, function()
        TweenService:Create(frame, TweenInfo.new(0.28), {
            Position = UDim2.new(0.1, 0, -0.12, 0)
        }):Play()
        task.wait(0.3)
        frame.Visible = false
    end)
end

function iOSUI:CreateWindow(title, options)
    options = options or {}
    local win = {}
    win.Title = title
    win.Parent = self
    win.Theme = self.Theme
    win._tabs = {}
    win._currentTab = nil
    win._connections = {}
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.85, 0, 0.66, 0)
    frame.Position = UDim2.new(0.5, 0, 1.35, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = self.ScreenGui
    frame.ZIndex = 50
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 36)
    win.Frame = frame
   
    local shadow = Instance.new("ImageLabel")
    shadow.Image = self.Theme.ShadowId
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.78
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1.06, 0, 1.06, 0)
    shadow.Position = UDim2.new(-0.03, 0, -0.03, 0)
    shadow.ZIndex = 45
    shadow.Parent = frame
    win.Shadow = shadow
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 56)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = frame
    titleBar.ZIndex = 60
    win.TitleBar = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.7,0,1,0)
    titleLabel.Position = UDim2.new(0.15,0,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.Parent = titleBar
    win.TitleLabel = titleLabel
   
    local navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(1, 0, 0, 56)
    navBar.Position = UDim2.new(0,0,1,-56)
    navBar.BackgroundTransparency = 1
    navBar.Parent = frame
    navBar.ZIndex = 60
    win.NavBar = navBar
    
    local navLayout = Instance.new("UIListLayout")
    navLayout.Parent = navBar
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    navLayout.Padding = UDim.new(0, 8)
    win.NavLayout = navLayout
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,-112)
    content.Position = UDim2.new(0,0,0,56)
    content.BackgroundTransparency = 1
    content.Parent = frame
    content.ZIndex = 60
    win.Content = content
    
    self:_enableDrag(win)
    
    frame.Visible = true
    TweenService:Create(frame, TweenInfo.new(0.46, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.55, 0)
    }):Play()
    
    table.insert(self.Windows, win)
    self.ActiveWindow = win
    return win
end

function iOSUI:_enableDrag(win)
    local dragging = false
    local dragStart = Vector2.new(0,0)
    local startPos = win.Frame.Position
    local inputConn
    
    win.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = win.Frame.Position
            inputConn = input
        end
    end)
    
    local changedConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input == inputConn then
            local delta = input.Position - dragStart
            win.Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                           startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(win._connections, changedConn)
    
    win.TitleBar.InputEnded:Connect(function(input)
        if input == inputConn then
            dragging = false
        end
    end)
end

function iOSUI:AddTab(win, name, iconText)
    if not win or not win.Frame then return end
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0.28, 0, 1, -10)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = iconText or name
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextColor3 = self.Theme.Primary
    tabBtn.Parent = win.NavBar
    tabBtn.ZIndex = 61
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
    
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 6
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.Parent = win.Content
    page.ZIndex = 61
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    layout.Name = "UIListLayout"
    
    local function updateCanvas()
        page.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 18)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    task.defer(updateCanvas)
    
    win._tabs[name] = { Button = tabBtn, Page = page, Layout = layout }
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(win._tabs) do
            v.Page.Visible = false
            v.Button.TextColor3 = self.Theme.Primary
            v.Button.BackgroundTransparency = 1
        end
        page.Visible = true
        tabBtn.TextColor3 = Color3.fromRGB(255,255,255)
        tabBtn.BackgroundColor3 = self.Theme.Primary
        tabBtn.BackgroundTransparency = 0
        win._currentTab = name
        self:ShowNotification(name .. " 已切换")
        page.Position = UDim2.new(0,0,0,10)
        TweenService:Create(page, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0,0,0,0)
        }):Play()
    end)
    
    if not win._currentTab then
        win._tabs[name].Page.Visible = true
        win._tabs[name].Button.BackgroundColor3 = self.Theme.Primary
        win._tabs[name].Button.TextColor3 = Color3.fromRGB(255,255,255)
        win._currentTab = name
    end
    
    return page
end

function iOSUI:GetTabPage(win, tabName)
    if win and win._tabs and win._tabs[tabName] then
        return win._tabs[tabName].Page
    end
    return nil
end

function iOSUI:AddButton(win, tabName, text, callback)
    local page = self:GetTabPage(win, tabName)
    if not page then return end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 44)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    btn.AutoButtonColor = false
    btn.Text = text
    btn.TextColor3 = self.Theme.Primary
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.Parent = page
    btn.ZIndex = 66
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    btn.MouseButton1Click:Connect(function()
        createRipple(btn, self.Theme.Primary)
        local p = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
            Size = UDim2.new(1, -18, 0, 40)
        })
        p:Play()
        p.Completed:Wait()
        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Bounce), {
            Size = UDim2.new(1, -20, 0, 44)
        }):Play()
        if callback then
            local ok, err = pcall(callback)
            if not ok then warn("Button callback error:", err) end
        end
        self:ShowNotification(text .. " 已激活")
    end)
    
    return btn
end

function iOSUI:AddTextBox(win, tabName, placeholder, callback)
    local page = self:GetTabPage(win, tabName)
    if not page then return end
    
    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -20, 0, 44)
    tb.Position = UDim2.new(0, 10, 0, 0)
    tb.BackgroundColor3 = Color3.fromRGB(250,250,250)
    tb.PlaceholderText = placeholder or ""
    tb.Text = ""
    tb.TextColor3 = self.Theme.Text
    tb.TextScaled = true
    tb.Font = Enum.Font.Gotham
    tb.Parent = page
    tb.ZIndex = 66
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)
    
    tb.Focused:Connect(function()
        TweenService:Create(tb, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(255,255,255)
        }):Play()
    end)
    tb.FocusLost:Connect(function(enter)
        if enter and callback then
            local ok, err = pcall(callback, tb.Text)
            if not ok then warn("TextBox callback error:", err) end
            self:ShowNotification("输入: " .. tb.Text)
        end
        TweenService:Create(tb, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(250,250,250)
        }):Play()
    end)
    
    return tb
end

function iOSUI:AddToggle(win, tabName, text, defaultState, callback)
    local page = self:GetTabPage(win, tabName)
    if not page then return end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 44)
    frame.Position = UDim2.new(0, 10, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = page
    frame.ZIndex = 66
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,0,0,0)
    label.Text = text
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextColor3 = self.Theme.Text
    label.Parent = frame
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 52, 0, 28)
    toggleBg.Position = UDim2.new(0.84, -10, 0.5, -14)
    toggleBg.BackgroundColor3 = Color3.fromRGB(230,230,230)
    toggleBg.Parent = frame
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(0,14)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = UDim2.new(0, 4, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Parent = toggleBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,12)
    knob.ZIndex = 68
    
    local state = defaultState or false
    local function applyState(s, instant)
        state = s
        local targetPos = s and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 4, 0.5, -12)
        local bgColor = s and self.Theme.Primary or Color3.fromRGB(230,230,230)
        if instant then
            knob.Position = targetPos
            toggleBg.BackgroundColor3 = bgColor
        else
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
            TweenService:Create(toggleBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = bgColor}):Play()
        end
    end
    applyState(state, true)
    
    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local newState = not state
            applyState(newState, false)
            if callback then
                local ok, err = pcall(callback, newState)
                if not ok then warn("Toggle callback error:", err) end
            end
            self:ShowNotification(text .. (newState and " 已启用" or " 已禁用"))
        end
    end)
    
    return {
        Frame = frame,
        SetState = function(s) applyState(s, true) end,
        GetState = function() return state end
    }
end

function iOSUI:ShowWindow(win, visible)
    if not win or not win.Frame then return end
    if visible then
        win.Frame.Visible = true
        TweenService:Create(win.Frame, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.55, 0)
        }):Play()
    else
        TweenService:Create(win.Frame, TweenInfo.new(0.36, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 1.35, 0)
        }):Play()
        task.delay(0.4, function() win.Frame.Visible = false end)
    end
end

function iOSUI:Destroy()
    for _, conn in ipairs(self._connections) do
        if conn and conn.Disconnect then
            pcall(conn.Disconnect, conn)
        end
    end
    for _, win in ipairs(self.Windows) do
        for _, conn in ipairs(win._connections or {}) do
            if conn and conn.Disconnect then
                pcall(conn.Disconnect, conn)
            end
        end
        if win.Frame then win.Frame:Destroy() end
    end
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

return iOSUI