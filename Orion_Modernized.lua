local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(12, 18, 34),      -- 主背景（深蓝）
            Second = Color3.fromRGB(22, 30, 50),    -- 次级背景
            Stroke = Color3.fromRGB(70, 140, 255),  -- 边框（亮蓝）
            Divider = Color3.fromRGB(60, 80, 120),  -- 分割线
            Text = Color3.fromRGB(240, 245, 255),   -- 主文本
            TextDark = Color3.fromRGB(160, 180, 220), -- 次要文本
            Accent = Color3.fromRGB(0, 120, 255),   -- 强调色
            Hover = Color3.fromRGB(40, 60, 100),    -- 悬停背景
            Pressed = Color3.fromRGB(20, 40, 80),   -- 按下背景
            Shadow = Color3.fromRGB(0, 0, 0)        -- 阴影色（单独处理透明度）
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

-- Feather Icons (可选)
local Icons = {}
local Success, Response = pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)
if not Success then
    warn("[Orion] Feather Icons load failed: " .. Response)
end

local function GetIcon(IconName)
    return Icons[IconName] or nil
end

-- ===== ScreenGui 创建 =====
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then
    syn.protect_gui(Orion)
    Orion.Parent = game.CoreGui
else
    Orion.Parent = gethui() or game.CoreGui
end
if gethui then
    for _, v in ipairs(gethui():GetChildren()) do
        if v.Name == Orion.Name and v ~= Orion then v:Destroy() end
    end
else
    for _, v in ipairs(game.CoreGui:GetChildren()) do
        if v.Name == Orion.Name and v ~= Orion then v:Destroy() end
    end
end

function OrionLib:IsRunning()
    return Orion.Parent ~= nil
end

local function AddConnection(Signal, Func)
    if not OrionLib:IsRunning() then return end
    local conn = Signal:Connect(Func)
    table.insert(OrionLib.Connections, conn)
    return conn
end

task.spawn(function()
    while OrionLib:IsRunning() do task.wait() end
    for _, conn in ipairs(OrionLib.Connections) do conn:Disconnect() end
end)

local function AddDraggingFunctionality(DragPoint, Main)
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos = false
        DragPoint.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = Input.Position
                FramePos = Main.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        DragPoint.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos
                TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X,
                                         FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
                }):Play()
            end
        end)
    end)
end

-- ===== 基础元素创建 =====
local function Create(Name, Props, Children)
    local obj = Instance.new(Name)
    for k, v in pairs(Props or {}) do obj[k] = v end
    for _, child in ipairs(Children or {}) do child.Parent = obj end
    return obj
end

local function CreateElement(ElementName, ElementFunction)
    OrionLib.Elements[ElementName] = function(...) return ElementFunction(...) end
end

local function MakeElement(ElementName, ...)
    return OrionLib.Elements[ElementName](...)
end

local function SetProps(Element, Props)
    for k, v in pairs(Props) do Element[k] = v end
    return Element
end

local function SetChildren(Element, Children)
    for _, child in ipairs(Children) do child.Parent = Element end
    return Element
end

local function Round(Number, Factor)
    local result = math.floor(Number / Factor + 0.5) * Factor
    return result
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3" end
    if Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
    if Object:IsA("UIStroke") then return "Color" end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3" end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(Object, Type)
    if not OrionLib.ThemeObjects[Type] then OrionLib.ThemeObjects[Type] = {} end
    table.insert(OrionLib.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
    return Object
end

local function SetTheme()
    for name, list in pairs(OrionLib.ThemeObjects) do
        for _, obj in ipairs(list) do
            obj[ReturnProperty(obj)] = OrionLib.Themes[OrionLib.SelectedTheme][name]
        end
    end
end

local function PackColor(Color) return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255} end
local function UnpackColor(Color) return Color3.fromRGB(Color.R, Color.G, Color.B) end

local function LoadCfg(Config)
    local Data = HttpService:JSONDecode(Config)
    for k, v in pairs(Data) do
        if OrionLib.Flags[k] then
            task.spawn(function()
                if OrionLib.Flags[k].Type == "Colorpicker" then
                    OrionLib.Flags[k]:Set(UnpackColor(v))
                else
                    OrionLib.Flags[k]:Set(v)
                end
            end)
        else
            warn("[Orion] Config: unknown flag " .. k)
        end
    end
end

local function SaveCfg(Name)
    local Data = {}
    for k, v in pairs(OrionLib.Flags) do
        if v.Save then
            Data[k] = (v.Type == "Colorpicker") and PackColor(v.Value) or v.Value
        end
    end
    writefile(OrionLib.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(Data))
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
    for _, v in ipairs(Table) do if v == Key then return true end end
    return false
end

-- ==================== 基础 UI 元素 ====================
CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 8)})
end)

CreateElement("Stroke", function(Color, Thickness, Transparency)
    return Create("UIStroke", {
        Color = Color or Color3.fromRGB(255,255,255),
        Thickness = Thickness or 1,
        Transparency = Transparency or 0.3
    })
end)

CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 6)})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 8),
        PaddingLeft = UDim.new(0, Left or 8),
        PaddingRight = UDim.new(0, Right or 8),
        PaddingTop = UDim.new(0, Top or 8)
    })
end)

CreateElement("TFrame", function() return Create("Frame", {BackgroundTransparency = 1}) end)
CreateElement("Frame", function(Color) return Create("Frame", {BackgroundColor3 = Color, BorderSizePixel = 0}) end)
CreateElement("RoundFrame", function(Color, Scale, Offset)
    return Create("Frame", {BackgroundColor3 = Color, BorderSizePixel = 0}, {
        Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 8)})
    })
end)
CreateElement("Button", function()
    return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)
CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = Color or Color3.fromRGB(100, 180, 255),
        BorderSizePixel = 0,
        ScrollBarThickness = Width or 4,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
end)
CreateElement("Image", function(ImageID)
    local img = Create("ImageLabel", {Image = ImageID, BackgroundTransparency = 1})
    if GetIcon(ImageID) then img.Image = GetIcon(ImageID) end
    return img
end)
CreateElement("ImageButton", function(ImageID) return Create("ImageButton", {Image = ImageID, BackgroundTransparency = 1}) end)
CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 14,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- ==================== 通知系统 ====================
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 5)
    })
}), {
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    Parent = Orion
})

function OrionLib:MakeNotification(NotificationConfig)
    task.spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
        NotificationConfig.Time = NotificationConfig.Time or 15

        local Parent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })
        local Frame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 25, 45), 0, 10), {
            Parent = Parent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0.15,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(70, 140, 255), 1.2, 0.4),
            MakeElement("Padding", 10, 10, 10, 10),
            SetProps(MakeElement("Image", NotificationConfig.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(200, 220, 255),
                Name = "Icon"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 13), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 22),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(180, 200, 230),
                TextWrapped = true
            })
        })
        TweenService:Create(Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(NotificationConfig.Time - 0.8)
        TweenService:Create(Frame, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.8}):Play()
        task.wait(0.3)
        Frame:TweenPosition(UDim2.new(1, 20, 0, 0), "In", "Quad", 0.6, true)
        task.wait(0.8)
        Frame:Destroy()
    end)
end

function OrionLib:Init()
    if OrionLib.SaveCfg then
        pcall(function()
            if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
                LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
                OrionLib:MakeNotification({
                    Name = "Config Loaded",
                    Content = "Loaded settings for game " .. game.GameId,
                    Time = 4
                })
            end
        end)
    end
end

-- ==================== 主窗口 ====================
function OrionLib:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "Orion"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.HidePremium = WindowConfig.HidePremium or false
    WindowConfig.IntroEnabled = (WindowConfig.IntroEnabled == nil) and true or WindowConfig.IntroEnabled
    WindowConfig.IntroText = WindowConfig.IntroText or "Orion"
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
    WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
    WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
    OrionLib.Folder = WindowConfig.ConfigFolder
    OrionLib.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig and not isfolder(WindowConfig.ConfigFolder) then
        makefolder(WindowConfig.ConfigFolder)
    end

    -- ====== 布局 ======
    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(100, 180, 255), 4), {
        Size = UDim2.new(1, 0, 1, -48),
        BackgroundTransparency = 0.1
    }), {
        MakeElement("List", 0, 4),
        MakeElement("Padding", 6, 4, 4, 6)
    }), "Divider")
    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 12)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0, 8, 0, 5),
            Size = UDim2.new(0, 18, 0, 18)
        }), "Text")
    })
    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0, 8, 0, 5),
            Size = UDim2.new(0, 18, 0, 18),
            Name = "Ico"
        }), "Text")
    })

    local DragPoint = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1, 0, 0, 42)})

    -- 左侧导航栏
    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
        Size = UDim2.new(0, 120, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 0.15
    }), {
        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0,0,0,0)}), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0)}), "Stroke"),
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 48),
            Position = UDim2.new(0, 0, 1, -48)
        }), {
            AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1, 0, 0, 1)}), "Stroke"),
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(0, 8, 0.5, 0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {Size = UDim2.new(1,0,1,0)}), "Second"),
                MakeElement("Corner", 1)
            }), "Divider"),
            AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 12), {
                Size = UDim2.new(1, -44, 0, 12),
                Position = UDim2.new(0, 40, 0, 16),
                Font = Enum.Font.GothamBold,
                ClipsDescendants = true
            }), "Text")
        }),
    }), "Second")

    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 20, 0, -20),
        Font = Enum.Font.GothamBlack,
        TextSize = 18
    }), "Text")

    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1)
    }), "Stroke")

    -- 主窗口（含阴影）
    local MainShadow = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(0,0,0), 0, 10), {
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0, 4, 0, 4),
        ZIndex = 0
    }), {MakeElement("Corner", 0, 10)})

    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
        Parent = Orion,
        Position = UDim2.new(0.5, -220, 0.5, -160),
        Size = UDim2.new(0, 440, 0, 320),
        ClipsDescendants = true,
        BackgroundTransparency = 0.1
    }), {
        MainShadow,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 42),
            Name = "TopBar"
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 8), {
                Size = UDim2.new(0, 60, 0, 28),
                Position = UDim2.new(1, -76, 0, 7),
                BackgroundTransparency = 0.2
            }), {
                AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 1, 0.3), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 1, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0)
                }), "Stroke"),
                CloseBtn,
                MinimizeBtn
            }), "Second"),
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    if WindowConfig.ShowIcon then
        WindowName.Position = UDim2.new(0, 44, 0, -20)
        local wIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 18, 0, 12)
        })
        wIcon.Parent = MainWindow.TopBar
    end

    AddDraggingFunctionality(DragPoint, MainWindow)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        UIHidden = true
        OrionLib:MakeNotification({Name = "Hidden", Content = "Press RightShift to show", Time = 4})
        WindowConfig.CloseCallback()
    end)
    AddConnection(UserInputService.InputBegan, function(Input)
        if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
            MainWindow.Visible = true
        end
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 440, 0, 320)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.new(0, WindowName.TextBounds.X + 120, 0, 42)}):Play()
            task.wait(0.1)
            WindowStuff.Visible = false
        end
        Minimized = not Minimized
    end)

    -- ===== 启动动画（恢复） =====
    local function LoadSequence()
        MainWindow.Visible = false
        local Logo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 36, 0, 36),
            ImageColor3 = Color3.fromRGB(100, 180, 255),
            ImageTransparency = 1
        })
        local Text = SetProps(MakeElement("Label", WindowConfig.IntroText, 16), {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(200, 220, 255),
            TextTransparency = 1
        })
        TweenService:Create(Logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
        task.wait(0.4)
        TweenService:Create(Text, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
        task.wait(1.8)
        TweenService:Create(Text, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        TweenService:Create(Logo, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
        task.wait(0.4)
        MainWindow.Visible = true
        Logo:Destroy()
        Text:Destroy()
    end

    if WindowConfig.IntroEnabled then
        LoadSequence()
    else
        MainWindow.Visible = true
    end

    -- ===== Tab 系统 =====
    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 28),
            Parent = TabHolder,
            BackgroundTransparency = 0.1
        }), {
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 8, 0.5, 0),
                ImageTransparency = 0.5,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 13), {
                Size = UDim2.new(1, -28, 1, 0),
                Position = UDim2.new(0, 28, 0, 0),
                Font = Enum.Font.GothamSemibold,
                TextTransparency = 0.5,
                Name = "Title"
            }), "Text")
        })
        if GetIcon(TabConfig.Icon) then TabFrame.Ico.Image = GetIcon(TabConfig.Icon) end

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(100, 180, 255), 4), {
            Size = UDim2.new(1, -120, 1, -48),
            Position = UDim2.new(0, 120, 0, 48),
            Parent = MainWindow,
            Visible = false,
            Name = "ItemContainer",
            BackgroundTransparency = 0.05
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 10, 12, 12, 10)
        }), "Divider")
        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 20)
        end)

        if FirstTab then
            FirstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end

        AddConnection(TabFrame.MouseButton1Click, function()
            for _, child in ipairs(TabHolder:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Title.Font = Enum.Font.GothamSemibold
                    TweenService:Create(child.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {ImageTransparency = 0.5}):Play()
                    TweenService:Create(child.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {TextTransparency = 0.5}):Play()
                end
            end
            for _, child in ipairs(MainWindow:GetChildren()) do
                if child.Name == "ItemContainer" then child.Visible = false end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end)

        -- ===== 控件生成函数 =====
        local function GetElements(ItemParent)
            local ElementFunction = {}

            function ElementFunction:AddLabel(Text)
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 0.1,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
                        Size = UDim2.new(1, -10, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke")
                }), "Second")
                local func = {}
                function func:Set(NewText) Frame.Content.Text = NewText end
                return func
            end

            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"
                Content = Content or "Content"
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.1,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
                        Size = UDim2.new(1, -10, 0, 14),
                        Position = UDim2.new(0, 10, 0, 8),
                        Font = Enum.Font.GothamBold,
                        Name = "Title"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "", 13), {
                        Size = UDim2.new(1, -20, 0, 0),
                        Position = UDim2.new(0, 10, 0, 24),
                        Font = Enum.Font.GothamSemibold,
                        Name = "Content",
                        TextWrapped = true
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke")
                }), "Second")
                AddConnection(Frame.Content:GetPropertyChangedSignal("Text"), function()
                    Frame.Content.Size = UDim2.new(1, -20, 0, Frame.Content.TextBounds.Y)
                    Frame.Size = UDim2.new(1, 0, 0, Frame.Content.TextBounds.Y + 32)
                end)
                Frame.Content.Text = Content
                local func = {}
                function func:Set(NewContent) Frame.Content.Text = NewContent end
                return func
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.1
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
                        Size = UDim2.new(0, 18, 0, 18),
                        Position = UDim2.new(1, -26, 0, 6),
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Click
                }), "Second")
                local defaultBg = Frame.BackgroundColor3
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = defaultBg}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Pressed}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                    task.spawn(ButtonConfig.Callback)
                end)
                local func = {}
                function func:Set(NewName) Frame.Content.Text = NewName end
                return func
            end

            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(0, 150, 255)
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false

                local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})

                -- 滑动轨道
                local Track = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(60,70,90), 0, 10), {
                    Size = UDim2.new(0, 36, 0, 20),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.4
                }), {
                    SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(220,230,255), 0, 8), {
                        Size = UDim2.new(0, 16, 0, 16),
                        Position = UDim2.new(0, 2, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 0,
                        Name = "Knob"
                    }), {
                        SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
                            Size = UDim2.new(1,0,1,0),
                            ImageColor3 = Color3.fromRGB(255,255,255),
                            ImageTransparency = 0.3,
                            Name = "Glow"
                        })
                    }),
                    MakeElement("Stroke", Color3.fromRGB(100,150,220), 0.8, 0.3)
                })

                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.1
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Track,
                    Click
                }), "Second")
                local defaultBg = Frame.BackgroundColor3

                function Toggle:Set(Value)
                    Toggle.Value = Value
                    local targetPos = Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    local trackColor = Value and ToggleConfig.Color or Color3.fromRGB(60,70,90)
                    TweenService:Create(Track, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = trackColor}):Play()
                    TweenService:Create(Track.Knob, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
                    ToggleConfig.Callback(Value)
                end
                Toggle:Set(Toggle.Value)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = defaultBg}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Pressed}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                    SaveCfg(game.GameId)
                    Toggle:Set(not Toggle.Value)
                end)

                if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end
                return Toggle
            end

            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(0, 150, 255)
                SliderConfig.Flag = SliderConfig.Flag or nil
                SliderConfig.Save = SliderConfig.Save or false

                local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
                local Dragging = false

                local ValueLabel = AddThemeObject(SetProps(MakeElement("Label", "0", 13), {
                    Size = UDim2.new(0, 36, 0, 14),
                    Position = UDim2.new(1, -40, 0, 10),
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Name = "ValueDisplay"
                }), "Text")

                local Bar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 4), {
                    Size = UDim2.new(1, -72, 0, 4),
                    Position = UDim2.new(0, 10, 0, 32),
                    BackgroundTransparency = 0.5,
                    Name = "Bar"
                }), {
                    SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 4), {
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundTransparency = 0,
                        Name = "Fill"
                    }), {
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                            Size = UDim2.new(0, 12, 0, 12),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(1, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            Name = "Dot"
                        })
                    })
                })

                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 48),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.1
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 10, 0, 8),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Bar,
                    ValueLabel
                }), "Second")

                Bar.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Dragging = true end
                end)
                Bar.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging then
                        local scale = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        Slider:Set(SliderConfig.Min + (SliderConfig.Max - SliderConfig.Min) * scale)
                        SaveCfg(game.GameId)
                    end
                end)

                function Slider:Set(Value)
                    self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    local scale = (self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
                    TweenService:Create(Bar.Fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(scale, 1)}):Play()
                    ValueLabel.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderConfig.Callback(self.Value)
                end
                Slider:Set(Slider.Value)
                if SliderConfig.Flag then OrionLib.Flags[SliderConfig.Flag] = Slider end
                return Slider
            end

            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or ""
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil
                DropdownConfig.Save = DropdownConfig.Save or false

                local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
                if not table.find(Dropdown.Options, Dropdown.Value) then Dropdown.Value = "..." end

                local MaxElements = 5
                local DropdownList = MakeElement("List")
                local Container = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(100, 180, 255), 4), {
                    DropdownList,
                    BackgroundTransparency = 0.1
                }), {
                    Parent = ItemParent,
                    Position = UDim2.new(0, 0, 0, 34),
                    Size = UDim2.new(1, 0, 1, -34),
                    ClipsDescendants = true
                }), "Divider")

                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = ItemParent,
                    ClipsDescendants = true,
                    BackgroundTransparency = 0.1
                }), {
                    Container,
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 14), {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "Content"
                        }), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
                            Size = UDim2.new(0, 14, 0, 14),
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -10, 0.5, 0),
                            ImageColor3 = Color3.fromRGB(200, 220, 255),
                            Name = "Arrow"
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label", "Selected", 12), {
                            Size = UDim2.new(1, -40, 1, 0),
                            Font = Enum.Font.Gotham,
                            Name = "Selected",
                            TextXAlignment = Enum.TextXAlignment.Right
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1, 0, 0, 1),
                            Position = UDim2.new(0, 0, 1, -1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"),
                        Click
                    }), {
                        Size = UDim2.new(1, 0, 0, 34),
                        ClipsDescendants = true,
                        Name = "F"
                    }),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    MakeElement("Corner", 0, 6)
                }), "Second")

                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    Container.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
                end)

                local function AddOptions(Options)
                    for _, Option in ipairs(Options) do
                        local Btn = AddThemeObject(SetProps(SetChildren(MakeElement("Button"), {
                            MakeElement("Corner", 0, 6),
                            AddThemeObject(SetProps(MakeElement("Label", Option, 12, 0.4), {
                                Position = UDim2.new(0, 8, 0, 0),
                                Size = UDim2.new(1, -8, 1, 0),
                                Name = "Title"
                            }), "Text")
                        }), {
                            Parent = Container,
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundTransparency = 1,
                            ClipsDescendants = true
                        }), "Divider")
                        AddConnection(Btn.MouseButton1Click, function()
                            Dropdown:Set(Option)
                            SaveCfg(game.GameId)
                        end)
                        AddConnection(Btn.MouseEnter, function()
                            TweenService:Create(Btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.2}):Play()
                            TweenService:Create(Btn.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
                        end)
                        AddConnection(Btn.MouseLeave, function()
                            if Btn.Title.Text ~= Dropdown.Value then
                                TweenService:Create(Btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                                TweenService:Create(Btn.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                            end
                        end)
                        Dropdown.Buttons[Option] = Btn
                    end
                end

                function Dropdown:Refresh(Options, Delete)
                    if Delete then
                        for _, v in pairs(Dropdown.Buttons) do v:Destroy() end
                        table.clear(Dropdown.Options)
                        table.clear(Dropdown.Buttons)
                    end
                    Dropdown.Options = Options
                    AddOptions(Dropdown.Options)
                end

                function Dropdown:Set(Value)
                    if not table.find(Dropdown.Options, Value) then
                        Dropdown.Value = "..."
                        Frame.F.Selected.Text = Dropdown.Value
                        for _, v in pairs(Dropdown.Buttons) do
                            TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                            TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                        end
                        return
                    end
                    Dropdown.Value = Value
                    Frame.F.Selected.Text = Dropdown.Value
                    for _, v in pairs(Dropdown.Buttons) do
                        TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
                        TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
                    end
                    TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
                    DropdownConfig.Callback(Dropdown.Value)
                end

                AddConnection(Click.MouseButton1Click, function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    Frame.F.Line.Visible = Dropdown.Toggled
                    TweenService:Create(Frame.F.Arrow, TweenInfo.new(.2, Enum.EasingStyle.Quad), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
                    local targetHeight = Dropdown.Toggled and (34 + math.min(#Dropdown.Options, MaxElements) * 26) or 34
                    TweenService:Create(Frame, TweenInfo.new(.25, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                end)

                Dropdown:Refresh(Dropdown.Options, false)
                Dropdown:Set(Dropdown.Value)
                if DropdownConfig.Flag then OrionLib.Flags[DropdownConfig.Flag] = Dropdown end
                return Dropdown
            end

            function ElementFunction:AddBind(BindConfig)
                BindConfig = BindConfig or {}
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Callback = BindConfig.Callback or function() end
                BindConfig.Flag = BindConfig.Flag or nil
                BindConfig.Save = BindConfig.Save or false

                local Bind = {Value = nil, Binding = false, Type = "Bind", Save = BindConfig.Save}
                local Holding = false
                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
                local Box = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.3
                }), {
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label", "None", 13), {
                        Size = UDim2.new(1,0,1,0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Name = "Value"
                    }), "Text")
                }), "Main")
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.1
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Box,
                    Click
                }), "Second")

                AddConnection(Box.Value:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(Box, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, Box.Value.TextBounds.X + 16, 0, 24)}):Play()
                end)

                AddConnection(Click.InputEnded, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        if Bind.Binding then return end
                        Bind.Binding = true
                        Box.Value.Text = "..."
                    end
                end)

                AddConnection(UserInputService.InputBegan, function(Input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
                        if BindConfig.Hold then
                            Holding = true
                            BindConfig.Callback(Holding)
                        else
                            BindConfig.Callback()
                        end
                    elseif Bind.Binding then
                        local Key
                        pcall(function()
                            if not CheckKey(BlacklistedKeys, Input.KeyCode) then
                                Key = Input.KeyCode
                            end
                        end)
                        pcall(function()
                            if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
                                Key = Input.UserInputType
                            end
                        end)
                        Key = Key or Bind.Value
                        Bind:Set(Key)
                        SaveCfg(game.GameId)
                    end
                end)

                AddConnection(UserInputService.InputEnded, function(Input)
                    if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
                        if BindConfig.Hold and Holding then
                            Holding = false
                            BindConfig.Callback(Holding)
                        end
                    end
                end)

                local defaultBg = Frame.BackgroundColor3
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = defaultBg}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Pressed}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                end)

                function Bind:Set(Key)
                    Bind.Binding = false
                    Bind.Value = Key or Bind.Value
                    Bind.Value = Bind.Value.Name or Bind.Value
                    Box.Value.Text = Bind.Value
                end
                Bind:Set(BindConfig.Default)
                if BindConfig.Flag then OrionLib.Flags[BindConfig.Flag] = Bind end
                return Bind
            end

            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end

                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
                local Box = AddThemeObject(Create("TextBox", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(220, 230, 255),
                    PlaceholderColor3 = Color3.fromRGB(160, 180, 220),
                    PlaceholderText = "Type...",
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextSize = 13,
                    ClearTextOnFocus = false
                }), "Text")
                local Container = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.2
                }), {
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Box
                }), "Main")
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.1
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                    Container,
                    Click
                }), "Second")

                AddConnection(Box:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, Box.TextBounds.X + 16, 0, 24)}):Play()
                end)
                AddConnection(Box.FocusLost, function()
                    TextboxConfig.Callback(Box.Text)
                    if TextboxConfig.TextDisappear then Box.Text = "" end
                end)
                Box.Text = TextboxConfig.Default

                local defaultBg = Frame.BackgroundColor3
                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = defaultBg}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Pressed}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = OrionLib.Themes.Default.Hover}):Play()
                    Box:CaptureFocus()
                end)
            end

            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(0, 150, 255)
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
                ColorpickerConfig.Save = ColorpickerConfig.Save or false

                local ColorH, ColorS, ColorV = 1, 1, 1
                local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
                local SelColor = Create("ImageLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })
                local SelHue = Create("ImageLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })
                local ColorArea = Create("ImageLabel", {
                    Size = UDim2.new(1, -24, 1, 0),
                    Visible = false,
                    Image = "rbxassetid://4155801252"
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                    SelColor
                })
                local HueBar = Create("Frame", {
                    Size = UDim2.new(0, 16, 1, 0),
                    Position = UDim2.new(1, -16, 0, 0),
                    Visible = false
                }, {
                    Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,4)),
                        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234,255,0)),
                        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21,255,0)),
                        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0,17,255)),
                        ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255,0,251)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,4))
                    }}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                    SelHue
                })
                local Presets = {
                    Color3.fromRGB(255,0,0), Color3.fromRGB(255,128,0), Color3.fromRGB(255,255,0),
                    Color3.fromRGB(0,255,0), Color3.fromRGB(0,150,255), Color3.fromRGB(128,0,255),
                    Color3.fromRGB(255,0,255), Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0)
                }
                local PresetContainer = Create("Frame", {
                    Size = UDim2.new(1, -40, 0, 22),
                    Position = UDim2.new(0, 20, 0, 86),
                    BackgroundTransparency = 1,
                    Visible = false,
                    Name = "Presets"
                }, {
                    SetProps(MakeElement("List"), {HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal}),
                })
                for _, col in ipairs(Presets) do
                    local btn = SetProps(MakeElement("RoundFrame", col, 0, 6), {
                        Size = UDim2.new(0, 18, 0, 18),
                        BackgroundTransparency = 0.2
                    })
                    AddConnection(btn.MouseButton1Click, function()
                        Colorpicker:Set(col)
                        local h,s,v = Color3.toHSV(col)
                        ColorH, ColorS, ColorV = h, s, v
                        SelColor.Position = UDim2.new(s, 0, 1-v, 0)
                        SelHue.Position = UDim2.new(0.5, 0, 1-h, 0)
                        ColorArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        ColorpickerBox.BackgroundColor3 = col
                    end)
                    btn.Parent = PresetContainer
                end

                local PickerContainer = Create("Frame", {
                    Position = UDim2.new(0, 0, 0, 32),
                    Size = UDim2.new(1, 0, 1, -32),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true
                }, {
                    HueBar,
                    ColorArea,
                    PresetContainer,
                    Create("UIPadding", {PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28), PaddingBottom = UDim.new(0, 8), PaddingTop = UDim.new(0, 12)})
                })

                local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})
                local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.2
                }), {
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke")
                }), "Main")
                local Frame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 6), {
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = ItemParent,
                    ClipsDescendants = true,
                    BackgroundTransparency = 0.1
                }), {
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 14), {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "Content"
                        }), "Text"),
                        ColorpickerBox,
                        Click,
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1, 0, 0, 1),
                            Position = UDim2.new(0, 0, 1, -1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"),
                    }), {
                        Size = UDim2.new(1, 0, 0, 34),
                        ClipsDescendants = true,
                        Name = "F"
                    }),
                    PickerContainer,
                    AddThemeObject(MakeElement("Stroke", Color3.fromRGB(70,140,255), 0.8, 0.2), "Stroke"),
                }), "Second")

                AddConnection(Click.MouseButton1Click, function()
                    Colorpicker.Toggled = not Colorpicker.Toggled
                    local targetHeight = Colorpicker.Toggled and 130 or 34
                    TweenService:Create(Frame, TweenInfo.new(.25, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                    ColorArea.Visible = Colorpicker.Toggled
                    HueBar.Visible = Colorpicker.Toggled
                    PresetContainer.Visible = Colorpicker.Toggled
                    Frame.F.Line.Visible = Colorpicker.Toggled
                end)

                local function UpdateColorPicker()
                    ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                    ColorArea.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                    Colorpicker:Set(ColorpickerBox.BackgroundColor3)
                    ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
                    SaveCfg(game.GameId)
                end

                ColorH = 1 - (math.clamp(SelHue.AbsolutePosition.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y) / HueBar.AbsoluteSize.Y)
                ColorS = (math.clamp(SelColor.AbsolutePosition.X - ColorArea.AbsolutePosition.X, 0, ColorArea.AbsoluteSize.X) / ColorArea.AbsoluteSize.X)
                ColorV = 1 - (math.clamp(SelColor.AbsolutePosition.Y - ColorArea.AbsolutePosition.Y, 0, ColorArea.AbsoluteSize.Y) / ColorArea.AbsoluteSize.Y)

                AddConnection(ColorArea.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                        ColorInput = AddConnection(RunService.RenderStepped, function()
                            local x = math.clamp((Mouse.X - ColorArea.AbsolutePosition.X) / ColorArea.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((Mouse.Y - ColorArea.AbsolutePosition.Y) / ColorArea.AbsoluteSize.Y, 0, 1)
                            SelColor.Position = UDim2.new(x, 0, y, 0)
                            ColorS, ColorV = x, 1 - y
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(ColorArea.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                    end
                end)
                AddConnection(HueBar.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                        HueInput = AddConnection(RunService.RenderStepped, function()
                            local y = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                            SelHue.Position = UDim2.new(0.5, 0, y, 0)
                            ColorH = 1 - y
                            UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(HueBar.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                    end
                end)

                function Colorpicker:Set(Value)
                    Colorpicker.Value = Value
                    ColorpickerBox.BackgroundColor3 = Value
                    ColorpickerConfig.Callback(Value)
                end
                Colorpicker:Set(Colorpicker.Value)
                if ColorpickerConfig.Flag then OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker end
                return Colorpicker
            end

            return ElementFunction
        end

        local ElementFunction = {}

        function ElementFunction:AddSection(SectionConfig)
            SectionConfig.Name = SectionConfig.Name or "Section"
            local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 0, 22),
                Parent = Container
            }), {
                AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 13), {
                    Size = UDim2.new(1, -10, 0, 14),
                    Position = UDim2.new(0, 0, 0, 2),
                    Font = Enum.Font.GothamSemibold
                }), "TextDark"),
                SetChildren(SetProps(MakeElement("TFrame"), {
                    AnchorPoint = Vector2.new(0, 0),
                    Size = UDim2.new(1, 0, 1, -20),
                    Position = UDim2.new(0, 0, 0, 20),
                    Name = "Holder"
                }), {
                    MakeElement("List", 0, 4)
                }),
            })
            AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 22)
                SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)
            local SectionFunc = {}
            for k, v in pairs(GetElements(SectionFrame.Holder)) do SectionFunc[k] = v end
            return SectionFunc
        end

        for k, v in pairs(GetElements(Container)) do ElementFunction[k] = v end

        if TabConfig.PremiumOnly then
            -- 简单显示锁图标，可自行扩展
            for k, v in pairs(ElementFunction) do ElementFunction[k] = function() end end
            local lock = SetProps(MakeElement("Label", "🔒 Premium", 14), {
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextColor3 = Color3.fromRGB(200, 200, 200)
            })
            lock.Parent = Container
        end

        return ElementFunction
    end

    return TabFunction
end

function OrionLib:Destroy()
    Orion:Destroy()
end

function OrionLib:ToggleUi()
    Orion.Enabled = not Orion.Enabled
end

return OrionLib