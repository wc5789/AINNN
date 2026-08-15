--[[
    Vape Lite Style UI Library - Optimized
    - PC & Mobile compatible (full touch support)
    - Vape Lite inspired dark theme
    - Smooth animations
    - Efficient (no while wait() loops)
    - Clean, minimal design
]]

local lib = {RainbowColorValue = 0, HueSelectionPosition = 0}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PresetColor = Color3.fromRGB(65, 140, 255) -- Vape Lite blue
local CloseBind = Enum.KeyCode.RightControl

-- Detect mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============== Color Update (efficient, single connection) ==============
local colorUpdateCon = nil
local function startColorUpdate()
    if colorUpdateCon then return end
    colorUpdateCon = RunService.Heartbeat:Connect(function()
        lib.RainbowColorValue = lib.RainbowColorValue + 1 / 255
        lib.HueSelectionPosition = lib.HueSelectionPosition + 1
        if lib.RainbowColorValue >= 1 then lib.RainbowColorValue = 0 end
        if lib.HueSelectionPosition >= 80 then lib.HueSelectionPosition = 0 end
    end)
end
startColorUpdate()

-- ============== UI Setup ==============
local ui = Instance.new("ScreenGui")
ui.Name = "VapeLite"
ui.Parent = game.CoreGui
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.ResetOnSpawn = false

-- ============== Helper: Create Shadow ==============
local function createShadow(parent, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = transparency or 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 49, 49)
    shadow.BackgroundTransparency = 1
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = size or UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end

-- ============== Drag System (PC + Mobile) ==============
local function MakeDraggable(topbarObject, object)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function update(input)
        local delta = input.Position - dragStart
        object.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ============== Window ==============
function lib:Window(text, preset, closebind)
    CloseBind = closebind or Enum.KeyCode.RightControl
    PresetColor = preset or Color3.fromRGB(65, 140, 255)

    local fs = false
    local Main = Instance.new("Frame")
    local MainCorner = Instance.new("UICorner")
    local TabHold = Instance.new("Frame")
    local TabHoldLayout = Instance.new("UIListLayout")
    local Title = Instance.new("TextLabel")
    local TabFolder = Instance.new("Folder")
    local DragFrame = Instance.new("Frame")
    local TopBar = Instance.new("Frame")
    local TopBarLine = Instance.new("Frame")

    -- Main container
    Main.Name = "Main"
    Main.Parent = ui
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.ClipsDescendants = true
    Main.Visible = true

    -- Shadow
    createShadow(Main, UDim2.new(1, 40, 1, 40), 0.65)

    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Name = "MainCorner"
    MainCorner.Parent = Main

    -- Top bar
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 36)

    TopBarLine.Name = "TopBarLine"
    TopBarLine.Parent = Main
    TopBarLine.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TopBarLine.BorderSizePixel = 0
    TopBarLine.Position = UDim2.new(0, 0, 0, 36)
    TopBarLine.Size = UDim2.new(1, 0, 0, 1)

    -- Title
    Title.Name = "Title"
    Title.Parent = TopBar
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Font = Enum.Font.GothamSemibold
    Title.Text = text or "Vape Lite"
    Title.TextColor3 = Color3.fromRGB(200, 200, 200)
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Drag frame (covers top bar)
    DragFrame.Name = "DragFrame"
    DragFrame.Parent = Main
    DragFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DragFrame.BackgroundTransparency = 1
    DragFrame.Size = UDim2.new(1, 0, 0, 36)

    -- Tab sidebar
    TabHold.Name = "TabHold"
    TabHold.Parent = Main
    TabHold.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TabHold.BorderSizePixel = 0
    TabHold.Position = UDim2.new(0, 0, 0, 37)
    TabHold.Size = UDim2.new(0, 115, 0, 270)

    TabHoldLayout.Name = "TabHoldLayout"
    TabHoldLayout.Parent = TabHold
    TabHoldLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabHoldLayout.Padding = UDim.new(0, 2)

    -- Separator line between tabs and content
    local TabSeparator = Instance.new("Frame")
    TabSeparator.Name = "TabSeparator"
    TabSeparator.Parent = Main
    TabSeparator.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabSeparator.BorderSizePixel = 0
    TabSeparator.Position = UDim2.new(0, 115, 0, 37)
    TabSeparator.Size = UDim2.new(0, 1, 0, 270)

    -- Animate in
    Main:TweenSize(UDim2.new(0, 560, 0, 307), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)

    MakeDraggable(DragFrame, Main)

    -- Toggle UI with close key
    local uitoggled = false
    UserInputService.InputBegan:Connect(function(io, p)
        if io.KeyCode == CloseBind and not p then
            if uitoggled == false then
                uitoggled = true
                Main:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.4, true, function()
                    ui.Enabled = false
                end)
            else
                uitoggled = false
                ui.Enabled = true
                Main:TweenSize(UDim2.new(0, 560, 0, 307), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.4, true)
            end
        end
    end)

    TabFolder.Name = "TabFolder"
    TabFolder.Parent = Main

    -- ============== Change Preset Color ==============
    function lib:ChangePresetColor(toch)
        PresetColor = toch
    end

    -- ============== Notification ==============
    function lib:Notification(texttitle, textdesc, textbtn)
        local NotificationHold = Instance.new("TextButton")
        local NotificationFrame = Instance.new("Frame")
        local NotificationFrameCorner = Instance.new("UICorner")
        local OkayBtn = Instance.new("TextButton")
        local OkayBtnCorner = Instance.new("UICorner")
        local OkayBtnTitle = Instance.new("TextLabel")
        local NotificationTitle = Instance.new("TextLabel")
        local NotificationDesc = Instance.new("TextLabel")

        NotificationHold.Name = "NotificationHold"
        NotificationHold.Parent = Main
        NotificationHold.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHold.BackgroundTransparency = 1
        NotificationHold.BorderSizePixel = 0
        NotificationHold.Size = UDim2.new(1, 0, 1, 0)
        NotificationHold.AutoButtonColor = false
        NotificationHold.Font = Enum.Font.SourceSans
        NotificationHold.Text = ""
        NotificationHold.TextColor3 = Color3.fromRGB(0, 0, 0)
        NotificationHold.TextSize = 14
        NotificationHold.ZIndex = 100

        TweenService:Create(NotificationHold, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.65
        }):Play()
        wait(0.35)

        NotificationFrame.Name = "NotificationFrame"
        NotificationFrame.Parent = NotificationHold
        NotificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        NotificationFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        NotificationFrame.BorderSizePixel = 0
        NotificationFrame.ClipsDescendants = true
        NotificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        NotificationFrame.ZIndex = 101

        NotificationFrameCorner.CornerRadius = UDim.new(0, 6)
        NotificationFrameCorner.Parent = NotificationFrame

        NotificationFrame:TweenSize(UDim2.new(0, 170, 0, 190), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)

        OkayBtn.Name = "OkayBtn"
        OkayBtn.Parent = NotificationFrame
        OkayBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
        OkayBtn.Position = UDim2.new(0.06, 0, 0.72, 0)
        OkayBtn.Size = UDim2.new(0, 150, 0, 40)
        OkayBtn.AutoButtonColor = false
        OkayBtn.Font = Enum.Font.SourceSans
        OkayBtn.Text = ""
        OkayBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        OkayBtn.TextSize = 14
        OkayBtn.ZIndex = 102

        OkayBtnCorner.CornerRadius = UDim.new(0, 5)
        OkayBtnCorner.Parent = OkayBtn

        OkayBtnTitle.Name = "OkayBtnTitle"
        OkayBtnTitle.Parent = OkayBtn
        OkayBtnTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        OkayBtnTitle.BackgroundTransparency = 1
        OkayBtnTitle.Size = UDim2.new(1, 0, 1, 0)
        OkayBtnTitle.Font = Enum.Font.GothamSemibold
        OkayBtnTitle.Text = textbtn or "OK"
        OkayBtnTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
        OkayBtnTitle.TextSize = 14
        OkayBtnTitle.ZIndex = 103

        NotificationTitle.Name = "NotificationTitle"
        NotificationTitle.Parent = NotificationFrame
        NotificationTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NotificationTitle.BackgroundTransparency = 1
        NotificationTitle.Position = UDim2.new(0.07, 0, 0.08, 0)
        NotificationTitle.Size = UDim2.new(0, 150, 0, 26)
        NotificationTitle.Font = Enum.Font.GothamSemibold
        NotificationTitle.Text = texttitle
        NotificationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        NotificationTitle.TextSize = 17
        NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left
        NotificationTitle.ZIndex = 102

        NotificationDesc.Name = "NotificationDesc"
        NotificationDesc.Parent = NotificationFrame
        NotificationDesc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NotificationDesc.BackgroundTransparency = 1
        NotificationDesc.Position = UDim2.new(0.07, 0, 0.22, 0)
        NotificationDesc.Size = UDim2.new(0, 150, 0, 90)
        NotificationDesc.Font = Enum.Font.Gotham
        NotificationDesc.Text = textdesc
        NotificationDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
        NotificationDesc.TextSize = 14
        NotificationDesc.TextWrapped = true
        NotificationDesc.TextXAlignment = Enum.TextXAlignment.Left
        NotificationDesc.TextYAlignment = Enum.TextYAlignment.Top
        NotificationDesc.ZIndex = 102

        OkayBtn.MouseEnter:Connect(function()
            TweenService:Create(OkayBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            }):Play()
        end)
        OkayBtn.MouseLeave:Connect(function()
            TweenService:Create(OkayBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(34, 34, 34)
            }):Play()
        end)

        OkayBtn.MouseButton1Click:Connect(function()
            NotificationFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5, true)
            wait(0.4)
            TweenService:Create(NotificationHold, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            wait(0.25)
            NotificationHold:Destroy()
        end)
    end

    -- ============== Tabs ==============
    local tabhold = {}
    function tabhold:Tab(text)
        local TabBtn = Instance.new("TextButton")
        local TabTitle = Instance.new("TextLabel")
        local TabBtnIndicator = Instance.new("Frame")
        local TabBtnIndicatorCorner = Instance.new("UICorner")

        TabBtn.Name = "TabBtn"
        TabBtn.Parent = TabHold
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Size = UDim2.new(0, 115, 0, 28)
        TabBtn.Font = Enum.Font.SourceSans
        TabBtn.Text = ""
        TabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        TabBtn.TextSize = 14

        TabTitle.Name = "TabTitle"
        TabTitle.Parent = TabBtn
        TabTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabTitle.BackgroundTransparency = 1
        TabTitle.Position = UDim2.new(0, 14, 0, 0)
        TabTitle.Size = UDim2.new(0, 100, 1, 0)
        TabTitle.Font = Enum.Font.Gotham
        TabTitle.Text = text
        TabTitle.TextColor3 = Color3.fromRGB(140, 140, 140)
        TabTitle.TextSize = 13
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left

        TabBtnIndicator.Name = "TabBtnIndicator"
        TabBtnIndicator.Parent = TabBtn
        TabBtnIndicator.BackgroundColor3 = PresetColor
        TabBtnIndicator.BorderSizePixel = 0
        TabBtnIndicator.Position = UDim2.new(0, 0, 0.5, -8)
        TabBtnIndicator.Size = UDim2.new(0, 0, 0, 16)

        TabBtnIndicatorCorner.CornerRadius = UDim.new(0, 2)
        TabBtnIndicatorCorner.Name = "TabBtnIndicatorCorner"
        TabBtnIndicatorCorner.Parent = TabBtnIndicator

        -- Keep indicator color updated
        local indicatorCon = RunService.Heartbeat:Connect(function()
            TabBtnIndicator.BackgroundColor3 = PresetColor
        end)

        -- Tab content area
        local Tab = Instance.new("ScrollingFrame")
        local TabLayout = Instance.new("UIListLayout")

        Tab.Name = "Tab"
        Tab.Parent = TabFolder
        Tab.Active = true
        Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Tab.BackgroundTransparency = 1
        Tab.BorderSizePixel = 0
        Tab.Position = UDim2.new(0, 116, 0, 37)
        Tab.Size = UDim2.new(0, 444, 0, 270)
        Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
        Tab.ScrollBarThickness = 2
        Tab.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
        Tab.Visible = false
        Tab.ScrollingEnabled = true
        Tab.ElasticBehavior = Enum.ElasticBehavior.Never
        Tab.ScrollBarImageTransparency = 0.5

        TabLayout.Name = "TabLayout"
        TabLayout.Parent = Tab
        TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabLayout.Padding = UDim.new(0, 5)

        -- First tab is selected by default
        if fs == false then
            fs = true
            TabBtnIndicator.Size = UDim2.new(0, 2, 0, 16)
            TabTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
            Tab.Visible = true
        end

        -- Tab switching
        TabBtn.MouseButton1Click:Connect(function()
            for _, v in next, TabFolder:GetChildren() do
                if v.Name == "Tab" then
                    v.Visible = false
                end
            end
            Tab.Visible = true

            for _, v in next, TabHold:GetChildren() do
                if v.Name == "TabBtn" then
                    v.TabBtnIndicator:TweenSize(
                        UDim2.new(0, 0, 0, 16),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    TweenService:Create(v.TabTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextColor3 = Color3.fromRGB(140, 140, 140)
                    }):Play()
                end
            end

            TabBtnIndicator:TweenSize(
                UDim2.new(0, 2, 0, 16),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quart,
                0.2,
                true
            )
            TweenService:Create(TabTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(220, 220, 220)
            }):Play()
        end)

        -- ============== COMPONENTS ==============
        local tabcontent = {}

        -- Button
        function tabcontent:Button(text, callback)
            local Button = Instance.new("TextButton")
            local ButtonCorner = Instance.new("UICorner")
            local ButtonTitle = Instance.new("TextLabel")

            Button.Name = "Button"
            Button.Parent = Tab
            Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Button.Size = UDim2.new(0, 434, 0, 38)
            Button.AutoButtonColor = false
            Button.Font = Enum.Font.SourceSans
            Button.Text = ""
            Button.TextColor3 = Color3.fromRGB(0, 0, 0)
            Button.TextSize = 14

            ButtonCorner.CornerRadius = UDim.new(0, 5)
            ButtonCorner.Name = "ButtonCorner"
            ButtonCorner.Parent = Button

            ButtonTitle.Name = "ButtonTitle"
            ButtonTitle.Parent = Button
            ButtonTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ButtonTitle.BackgroundTransparency = 1
            ButtonTitle.Position = UDim2.new(0, 12, 0, 0)
            ButtonTitle.Size = UDim2.new(1, -24, 1, 0)
            ButtonTitle.Font = Enum.Font.Gotham
            ButtonTitle.Text = text
            ButtonTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            ButtonTitle.TextSize = 13
            ButtonTitle.TextXAlignment = Enum.TextXAlignment.Left

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                }):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                }):Play()
            end)
            Button.MouseButton1Click:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                }):Play()
                wait(0.08)
                TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                }):Play()
                pcall(callback)
            end)

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Toggle (Vape Lite style - modern pill)
        function tabcontent:Toggle(text, default, callback)
            local toggled = false

            local Toggle = Instance.new("TextButton")
            local ToggleCorner = Instance.new("UICorner")
            local ToggleTitle = Instance.new("TextLabel")
            local ToggleBG = Instance.new("Frame")
            local ToggleBGCorner = Instance.new("UICorner")
            local ToggleFill = Instance.new("Frame")
            local ToggleFillCorner = Instance.new("UICorner")
            local ToggleCircle = Instance.new("Frame")
            local ToggleCircleCorner = Instance.new("UICorner")

            Toggle.Name = "Toggle"
            Toggle.Parent = Tab
            Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Toggle.Size = UDim2.new(0, 434, 0, 38)
            Toggle.AutoButtonColor = false
            Toggle.Font = Enum.Font.SourceSans
            Toggle.Text = ""
            Toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.TextSize = 14

            ToggleCorner.CornerRadius = UDim.new(0, 5)
            ToggleCorner.Name = "ToggleCorner"
            ToggleCorner.Parent = Toggle

            ToggleTitle.Name = "ToggleTitle"
            ToggleTitle.Parent = Toggle
            ToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleTitle.BackgroundTransparency = 1
            ToggleTitle.Position = UDim2.new(0, 12, 0, 0)
            ToggleTitle.Size = UDim2.new(0, 300, 1, 0)
            ToggleTitle.Font = Enum.Font.Gotham
            ToggleTitle.Text = text
            ToggleTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            ToggleTitle.TextSize = 13
            ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- Toggle pill background
            ToggleBG.Name = "ToggleBG"
            ToggleBG.Parent = Toggle
            ToggleBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            ToggleBG.BorderSizePixel = 0
            ToggleBG.Position = UDim2.new(1, -50, 0.5, -9)
            ToggleBG.Size = UDim2.new(0, 36, 0, 18)
            ToggleBG.ZIndex = 2

            ToggleBGCorner.CornerRadius = UDim.new(0, 9)
            ToggleBGCorner.Parent = ToggleBG

            -- Toggle fill (accent color when on)
            ToggleFill.Name = "ToggleFill"
            ToggleFill.Parent = ToggleBG
            ToggleFill.BackgroundColor3 = PresetColor
            ToggleFill.BackgroundTransparency = 1
            ToggleFill.BorderSizePixel = 0
            ToggleFill.Size = UDim2.new(1, 0, 1, 0)
            ToggleFill.ZIndex = 3

            ToggleFillCorner.CornerRadius = UDim.new(0, 9)
            ToggleFillCorner.Parent = ToggleFill

            -- Toggle circle
            ToggleCircle.Name = "ToggleCircle"
            ToggleCircle.Parent = ToggleBG
            ToggleCircle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Position = UDim2.new(0, 2, 0.5, -6)
            ToggleCircle.Size = UDim2.new(0, 12, 0, 12)
            ToggleCircle.ZIndex = 4

            ToggleCircleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCircleCorner.Parent = ToggleCircle

            -- Keep fill color updated
            local fillCon = RunService.Heartbeat:Connect(function()
                ToggleFill.BackgroundColor3 = PresetColor
            end)

            local function setToggle(on)
                if on then
                    TweenService:Create(ToggleFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0
                    }):Play()
                    TweenService:Create(ToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    ToggleCircle:TweenPosition(
                        UDim2.new(1, -14, 0.5, -6),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.25,
                        true
                    )
                else
                    TweenService:Create(ToggleFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()
                    TweenService:Create(ToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(180, 180, 180)
                    }):Play()
                    ToggleCircle:TweenPosition(
                        UDim2.new(0, 2, 0.5, -6),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.25,
                        true
                    )
                end
            end

            Toggle.MouseButton1Click:Connect(function()
                toggled = not toggled
                if toggled then
                    TweenService:Create(Toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    }):Play()
                else
                    TweenService:Create(Toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    }):Play()
                end
                setToggle(toggled)
                pcall(callback, toggled)
            end)

            if default == true then
                toggled = true
                ToggleFill.BackgroundTransparency = 0
                ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleCircle.Position = UDim2.new(1, -14, 0.5, -6)
                Toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Slider (PC + Mobile compatible)
        function tabcontent:Slider(text, min, max, start, callback)
            local dragging = false
            local Slider = Instance.new("TextButton")
            local SliderCorner = Instance.new("UICorner")
            local SliderTitle = Instance.new("TextLabel")
            local SliderValue = Instance.new("TextLabel")
            local SlideFrame = Instance.new("Frame")
            local SlideFrameCorner = Instance.new("UICorner")
            local CurrentValueFrame = Instance.new("Frame")
            local CurrentValueFrameCorner = Instance.new("UICorner")
            local SlideCircle = Instance.new("Frame")
            local SlideCircleCorner = Instance.new("UICorner")

            Slider.Name = "Slider"
            Slider.Parent = Tab
            Slider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Slider.Size = UDim2.new(0, 434, 0, 52)
            Slider.AutoButtonColor = false
            Slider.Font = Enum.Font.SourceSans
            Slider.Text = ""
            Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
            Slider.TextSize = 14

            SliderCorner.CornerRadius = UDim.new(0, 5)
            SliderCorner.Parent = Slider

            SliderTitle.Name = "SliderTitle"
            SliderTitle.Parent = Slider
            SliderTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderTitle.BackgroundTransparency = 1
            SliderTitle.Position = UDim2.new(0, 12, 0, 0)
            SliderTitle.Size = UDim2.new(0, 200, 0, 28)
            SliderTitle.Font = Enum.Font.Gotham
            SliderTitle.Text = text
            SliderTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            SliderTitle.TextSize = 13
            SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

            SliderValue.Name = "SliderValue"
            SliderValue.Parent = Slider
            SliderValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Position = UDim2.new(0, 12, 0, 0)
            SliderValue.Size = UDim2.new(1, -24, 0, 28)
            SliderValue.Font = Enum.Font.GothamSemibold
            SliderValue.Text = tostring(start or min)
            SliderValue.TextColor3 = Color3.fromRGB(200, 200, 200)
            SliderValue.TextSize = 13
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right

            SlideFrame.Name = "SlideFrame"
            SlideFrame.Parent = Slider
            SlideFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            SlideFrame.BorderSizePixel = 0
            SlideFrame.Position = UDim2.new(0, 12, 0, 32)
            SlideFrame.Size = UDim2.new(1, -24, 0, 4)

            SlideFrameCorner.CornerRadius = UDim.new(0, 2)
            SlideFrameCorner.Parent = SlideFrame

            CurrentValueFrame.Name = "CurrentValueFrame"
            CurrentValueFrame.Parent = SlideFrame
            CurrentValueFrame.BackgroundColor3 = PresetColor
            CurrentValueFrame.BorderSizePixel = 0
            CurrentValueFrame.Size = UDim2.new((start or min) / max, 0, 1, 0)

            CurrentValueFrameCorner.CornerRadius = UDim.new(0, 2)
            CurrentValueFrameCorner.Parent = CurrentValueFrame

            SlideCircle.Name = "SlideCircle"
            SlideCircle.Parent = SlideFrame
            SlideCircle.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            SlideCircle.BorderSizePixel = 0
            SlideCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            SlideCircle.Position = UDim2.new((start or min) / max, 0, 0.5, 0)
            SlideCircle.Size = UDim2.new(0, 12, 0, 12)
            SlideCircle.ZIndex = 5

            SlideCircleCorner.CornerRadius = UDim.new(0, 6)
            SlideCircleCorner.Parent = SlideCircle

            -- Keep color updated
            local slideCon = RunService.Heartbeat:Connect(function()
                CurrentValueFrame.BackgroundColor3 = PresetColor
            end)

            local function move(input)
                local pos =
                    UDim2.new(
                    math.clamp((input.Position.X - SlideFrame.AbsolutePosition.X) / SlideFrame.AbsoluteSize.X, 0, 1),
                    0,
                    0.5,
                    0
                )
                CurrentValueFrame.Size = UDim2.new(math.clamp((input.Position.X - SlideFrame.AbsolutePosition.X) / SlideFrame.AbsoluteSize.X, 0, 1), 0, 1, 0)
                SlideCircle.Position = pos
                local value = math.floor(((pos.X.Scale * max) / max) * (max - min) + min)
                SliderValue.Text = tostring(value)
                pcall(callback, value)
            end

            -- PC: Mouse input
            SlideCircle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            SlideCircle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            -- Mobile: Touch input on the whole slider bar
            Slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    move(input)
                end
            end)
            Slider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging then
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                        move(input)
                    end
                end
            end)

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Dropdown (PC + Mobile)
        function tabcontent:Dropdown(text, list, callback)
            local droptog = false
            local framesize = 0
            local itemcount = 0

            local Dropdown = Instance.new("Frame")
            local DropdownCorner = Instance.new("UICorner")
            local DropdownBtn = Instance.new("TextButton")
            local DropdownTitle = Instance.new("TextLabel")
            local ArrowImg = Instance.new("ImageLabel")
            local DropItemHolder = Instance.new("ScrollingFrame")
            local DropLayout = Instance.new("UIListLayout")

            Dropdown.Name = "Dropdown"
            Dropdown.Parent = Tab
            Dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Dropdown.ClipsDescendants = true
            Dropdown.Size = UDim2.new(0, 434, 0, 38)

            DropdownCorner.CornerRadius = UDim.new(0, 5)
            DropdownCorner.Parent = Dropdown

            DropdownBtn.Name = "DropdownBtn"
            DropdownBtn.Parent = Dropdown
            DropdownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            DropdownBtn.BackgroundTransparency = 1
            DropdownBtn.Size = UDim2.new(1, 0, 0, 38)
            DropdownBtn.Font = Enum.Font.SourceSans
            DropdownBtn.Text = ""
            DropdownBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            DropdownBtn.TextSize = 14

            DropdownTitle.Name = "DropdownTitle"
            DropdownTitle.Parent = Dropdown
            DropdownTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            DropdownTitle.BackgroundTransparency = 1
            DropdownTitle.Position = UDim2.new(0, 12, 0, 0)
            DropdownTitle.Size = UDim2.new(0, 350, 1, 0)
            DropdownTitle.Font = Enum.Font.Gotham
            DropdownTitle.Text = text
            DropdownTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            DropdownTitle.TextSize = 13
            DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

            ArrowImg.Name = "ArrowImg"
            ArrowImg.Parent = Dropdown
            ArrowImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ArrowImg.BackgroundTransparency = 1
            ArrowImg.Position = UDim2.new(1, -35, 0, 6)
            ArrowImg.Size = UDim2.new(0, 26, 0, 26)
            ArrowImg.Image = "http://www.roblox.com/asset/?id=6034818375"
            ArrowImg.ImageColor3 = Color3.fromRGB(160, 160, 160)

            DropItemHolder.Name = "DropItemHolder"
            DropItemHolder.Parent = Dropdown
            DropItemHolder.Active = true
            DropItemHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            DropItemHolder.BackgroundTransparency = 1
            DropItemHolder.BorderSizePixel = 0
            DropItemHolder.Position = UDim2.new(0, 5, 0, 40)
            DropItemHolder.Size = UDim2.new(1, -10, 0, 0)
            DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropItemHolder.ScrollBarThickness = 2
            DropItemHolder.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)

            DropLayout.Name = "DropLayout"
            DropLayout.Parent = DropItemHolder
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)

            DropdownBtn.MouseButton1Click:Connect(function()
                if droptog == false then
                    Dropdown:TweenSize(
                        UDim2.new(0, 434, 0, 42 + framesize),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    TweenService:Create(ArrowImg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = 270
                    }):Play()
                    wait(0.2)
                    Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
                else
                    Dropdown:TweenSize(
                        UDim2.new(0, 434, 0, 38),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    TweenService:Create(ArrowImg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = 0
                    }):Play()
                    wait(0.2)
                    Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
                end
                droptog = not droptog
            end)

            for i, v in next, list do
                itemcount = itemcount + 1
                if itemcount <= 4 then
                    framesize = framesize + 28
                end
                DropItemHolder.Size = UDim2.new(1, -10, 0, math.min(itemcount, 4) * 28)

                local Item = Instance.new("TextButton")
                local ItemCorner = Instance.new("UICorner")

                Item.Name = "Item"
                Item.Parent = DropItemHolder
                Item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                Item.ClipsDescendants = true
                Item.Size = UDim2.new(1, -5, 0, 26)
                Item.AutoButtonColor = false
                Item.Font = Enum.Font.Gotham
                Item.Text = v
                Item.TextColor3 = Color3.fromRGB(200, 200, 200)
                Item.TextSize = 13

                ItemCorner.CornerRadius = UDim.new(0, 4)
                ItemCorner.Parent = Item

                Item.MouseEnter:Connect(function()
                    TweenService:Create(Item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(42, 42, 42)
                    }):Play()
                end)
                Item.MouseLeave:Connect(function()
                    TweenService:Create(Item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    }):Play()
                end)
                Item.MouseButton1Click:Connect(function()
                    droptog = false
                    DropdownTitle.Text = text .. " - " .. v
                    pcall(callback, v)
                    Dropdown:TweenSize(
                        UDim2.new(0, 434, 0, 38),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    TweenService:Create(ArrowImg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = 0
                    }):Play()
                    wait(0.2)
                    Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
                end)

                DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y)
            end
            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Colorpicker (PC + Mobile)
        function tabcontent:Colorpicker(text, preset, callback)
            local ColorPickerToggled = false
            local OldToggleColor = Color3.fromRGB(0, 0, 0)
            local OldColor = Color3.fromRGB(0, 0, 0)
            local OldColorSelectionPosition = nil
            local OldHueSelectionPosition = nil
            local ColorH, ColorS, ColorV = 1, 1, 1
            local RainbowColorPicker = false
            local ColorInput = nil
            local HueInput = nil

            local Colorpicker = Instance.new("Frame")
            local ColorpickerCorner = Instance.new("UICorner")
            local ColorpickerTitle = Instance.new("TextLabel")
            local BoxColor = Instance.new("Frame")
            local BoxColorCorner = Instance.new("UICorner")
            local ConfirmBtn = Instance.new("TextButton")
            local ConfirmBtnCorner = Instance.new("UICorner")
            local ConfirmBtnTitle = Instance.new("TextLabel")
            local ColorpickerBtn = Instance.new("TextButton")
            local RainbowToggle = Instance.new("TextButton")
            local RainbowToggleCorner = Instance.new("UICorner")
            local RainbowToggleTitle = Instance.new("TextLabel")
            local RainbowToggleBG = Instance.new("Frame")
            local RainbowToggleBGCorner = Instance.new("UICorner")
            local RainbowToggleFill = Instance.new("Frame")
            local RainbowToggleFillCorner = Instance.new("UICorner")
            local RainbowToggleCircle = Instance.new("Frame")
            local RainbowToggleCircleCorner = Instance.new("UICorner")
            local Color = Instance.new("ImageLabel")
            local ColorCorner = Instance.new("UICorner")
            local ColorSelection = Instance.new("ImageLabel")
            local Hue = Instance.new("ImageLabel")
            local HueCorner = Instance.new("UICorner")
            local HueGradient = Instance.new("UIGradient")
            local HueSelection = Instance.new("ImageLabel")

            Colorpicker.Name = "Colorpicker"
            Colorpicker.Parent = Tab
            Colorpicker.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Colorpicker.ClipsDescendants = true
            Colorpicker.Size = UDim2.new(0, 434, 0, 38)

            ColorpickerCorner.CornerRadius = UDim.new(0, 5)
            ColorpickerCorner.Parent = Colorpicker

            ColorpickerTitle.Name = "ColorpickerTitle"
            ColorpickerTitle.Parent = Colorpicker
            ColorpickerTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ColorpickerTitle.BackgroundTransparency = 1
            ColorpickerTitle.Position = UDim2.new(0, 12, 0, 0)
            ColorpickerTitle.Size = UDim2.new(0, 200, 1, 0)
            ColorpickerTitle.Font = Enum.Font.Gotham
            ColorpickerTitle.Text = text
            ColorpickerTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            ColorpickerTitle.TextSize = 13
            ColorpickerTitle.TextXAlignment = Enum.TextXAlignment.Left

            BoxColor.Name = "BoxColor"
            BoxColor.Parent = Colorpicker
            BoxColor.BackgroundColor3 = preset or Color3.fromRGB(255, 255, 255)
            BoxColor.BorderSizePixel = 0
            BoxColor.Position = UDim2.new(1, -55, 0, 8)
            BoxColor.Size = UDim2.new(0, 40, 0, 22)

            BoxColorCorner.CornerRadius = UDim.new(0, 4)
            BoxColorCorner.Parent = BoxColor

            ConfirmBtn.Name = "ConfirmBtn"
            ConfirmBtn.Parent = Colorpicker
            ConfirmBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            ConfirmBtn.Position = UDim2.new(0, 12, 0, 128)
            ConfirmBtn.Size = UDim2.new(0, 195, 0, 30)
            ConfirmBtn.AutoButtonColor = false
            ConfirmBtn.Font = Enum.Font.SourceSans
            ConfirmBtn.Text = ""
            ConfirmBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            ConfirmBtn.TextSize = 14

            ConfirmBtnCorner.CornerRadius = UDim.new(0, 4)
            ConfirmBtnCorner.Parent = ConfirmBtn

            ConfirmBtnTitle.Name = "ConfirmBtnTitle"
            ConfirmBtnTitle.Parent = ConfirmBtn
            ConfirmBtnTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ConfirmBtnTitle.BackgroundTransparency = 1
            ConfirmBtnTitle.Size = UDim2.new(1, 0, 1, 0)
            ConfirmBtnTitle.Font = Enum.Font.GothamSemibold
            ConfirmBtnTitle.Text = "Confirm"
            ConfirmBtnTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            ConfirmBtnTitle.TextSize = 13

            ColorpickerBtn.Name = "ColorpickerBtn"
            ColorpickerBtn.Parent = Colorpicker
            ColorpickerBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ColorpickerBtn.BackgroundTransparency = 1
            ColorpickerBtn.Size = UDim2.new(1, 0, 0, 38)
            ColorpickerBtn.Font = Enum.Font.SourceSans
            ColorpickerBtn.Text = ""
            ColorpickerBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            ColorpickerBtn.TextSize = 14

            -- Rainbow toggle
            RainbowToggle.Name = "RainbowToggle"
            RainbowToggle.Parent = Colorpicker
            RainbowToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            RainbowToggle.Position = UDim2.new(0, 215, 0, 128)
            RainbowToggle.Size = UDim2.new(0, 207, 0, 30)
            RainbowToggle.AutoButtonColor = false
            RainbowToggle.Font = Enum.Font.SourceSans
            RainbowToggle.Text = ""
            RainbowToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
            RainbowToggle.TextSize = 14

            RainbowToggleCorner.CornerRadius = UDim.new(0, 4)
            RainbowToggleCorner.Parent = RainbowToggle

            RainbowToggleTitle.Name = "RainbowToggleTitle"
            RainbowToggleTitle.Parent = RainbowToggle
            RainbowToggleTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            RainbowToggleTitle.BackgroundTransparency = 1
            RainbowToggleTitle.Position = UDim2.new(0, 10, 0, 0)
            RainbowToggleTitle.Size = UDim2.new(0, 150, 1, 0)
            RainbowToggleTitle.Font = Enum.Font.Gotham
            RainbowToggleTitle.Text = "Rainbow"
            RainbowToggleTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            RainbowToggleTitle.TextSize = 13
            RainbowToggleTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- Rainbow toggle pill
            RainbowToggleBG.Name = "RainbowToggleBG"
            RainbowToggleBG.Parent = RainbowToggle
            RainbowToggleBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            RainbowToggleBG.BorderSizePixel = 0
            RainbowToggleBG.Position = UDim2.new(1, -40, 0.5, -9)
            RainbowToggleBG.Size = UDim2.new(0, 30, 0, 18)
            RainbowToggleBG.ZIndex = 2

            RainbowToggleBGCorner.CornerRadius = UDim.new(0, 9)
            RainbowToggleBGCorner.Parent = RainbowToggleBG

            RainbowToggleFill.Name = "RainbowToggleFill"
            RainbowToggleFill.Parent = RainbowToggleBG
            RainbowToggleFill.BackgroundColor3 = PresetColor
            RainbowToggleFill.BackgroundTransparency = 1
            RainbowToggleFill.BorderSizePixel = 0
            RainbowToggleFill.Size = UDim2.new(1, 0, 1, 0)
            RainbowToggleFill.ZIndex = 3

            RainbowToggleFillCorner.CornerRadius = UDim.new(0, 9)
            RainbowToggleFillCorner.Parent = RainbowToggleFill

            RainbowToggleCircle.Name = "RainbowToggleCircle"
            RainbowToggleCircle.Parent = RainbowToggleBG
            RainbowToggleCircle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            RainbowToggleCircle.BorderSizePixel = 0
            RainbowToggleCircle.Position = UDim2.new(0, 2, 0.5, -6)
            RainbowToggleCircle.Size = UDim2.new(0, 12, 0, 12)
            RainbowToggleCircle.ZIndex = 4

            RainbowToggleCircleCorner.CornerRadius = UDim.new(0, 6)
            RainbowToggleCircleCorner.Parent = RainbowToggleCircle

            -- Color picker area
            Color.Name = "Color"
            Color.Parent = Colorpicker
            Color.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
            Color.Position = UDim2.new(0, 12, 0, 40)
            Color.Size = UDim2.new(0, 200, 0, 80)
            Color.ZIndex = 10
            Color.Image = "rbxassetid://4155801252"

            ColorCorner.CornerRadius = UDim.new(0, 3)
            ColorCorner.Parent = Color

            ColorSelection.Name = "ColorSelection"
            ColorSelection.Parent = Color
            ColorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
            ColorSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ColorSelection.BackgroundTransparency = 1
            ColorSelection.Position = UDim2.new(preset and select(3, Color3.toHSV(preset)), 0, 0, 0)
            ColorSelection.Size = UDim2.new(0, 16, 0, 16)
            ColorSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
            ColorSelection.ScaleType = Enum.ScaleType.Fit
            ColorSelection.Visible = false
            ColorSelection.ZIndex = 11

            Hue.Name = "Hue"
            Hue.Parent = Colorpicker
            Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Hue.Position = UDim2.new(0, 220, 0, 40)
            Hue.Size = UDim2.new(0, 18, 0, 80)
            Hue.ZIndex = 10

            HueCorner.CornerRadius = UDim.new(0, 3)
            HueCorner.Parent = Hue

            HueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
                ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
                ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
                ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
                ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
            })
            HueGradient.Rotation = 270
            HueGradient.Name = "HueGradient"
            HueGradient.Parent = Hue

            HueSelection.Name = "HueSelection"
            HueSelection.Parent = Hue
            HueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
            HueSelection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueSelection.BackgroundTransparency = 1
            HueSelection.Position = UDim2.new(0.48, 0, 1 - select(1, Color3.toHSV(preset or Color3.fromRGB(255,255,255))), 0)
            HueSelection.Size = UDim2.new(0, 16, 0, 16)
            HueSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
            HueSelection.Visible = false
            HueSelection.ZIndex = 11

            -- Keep rainbow toggle fill updated
            local rainbowCon = RunService.Heartbeat:Connect(function()
                RainbowToggleFill.BackgroundColor3 = PresetColor
            end)

            -- Toggle colorpicker
            ColorpickerBtn.MouseButton1Click:Connect(function()
                if ColorPickerToggled == false then
                    ColorSelection.Visible = true
                    HueSelection.Visible = true
                    Colorpicker:TweenSize(
                        UDim2.new(0, 434, 0, 165),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    wait(0.2)
                    Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
                else
                    ColorSelection.Visible = false
                    HueSelection.Visible = false
                    Colorpicker:TweenSize(
                        UDim2.new(0, 434, 0, 38),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.2,
                        true
                    )
                    wait(0.2)
                    Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
                end
                ColorPickerToggled = not ColorPickerToggled
            end)

            local function UpdateColorPicker(nope)
                BoxColor.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                pcall(callback, BoxColor.BackgroundColor3)
            end

            ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
            ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
            ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

            BoxColor.BackgroundColor3 = preset or Color3.fromRGB(255, 255, 255)
            Color.BackgroundColor3 = preset or Color3.fromRGB(255, 255, 255)
            pcall(callback, BoxColor.BackgroundColor3)

            -- Color map input (PC + Mobile)
            Color.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if RainbowColorPicker then return end
                    if ColorInput then ColorInput:Disconnect() end
                    ColorInput = RunService.RenderStepped:Connect(function()
                        local ColorX = math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X
                        local ColorY = math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y
                        ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                        ColorS = ColorX
                        ColorV = 1 - ColorY
                        UpdateColorPicker(true)
                    end)
                end
            end)

            Color.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if ColorInput then ColorInput:Disconnect() end
                end
            end)

            -- Hue bar input (PC + Mobile)
            Hue.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if RainbowColorPicker then return end
                    if HueInput then HueInput:Disconnect() end
                    HueInput = RunService.RenderStepped:Connect(function()
                        local HueY = math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y
                        HueSelection.Position = UDim2.new(0.48, 0, HueY, 0)
                        ColorH = 1 - HueY
                        UpdateColorPicker(true)
                    end)
                end
            end)

            Hue.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    if HueInput then HueInput:Disconnect() end
                end
            end)

            -- Rainbow toggle
            RainbowToggle.MouseButton1Click:Connect(function()
                RainbowColorPicker = not RainbowColorPicker
                if ColorInput then ColorInput:Disconnect() end
                if HueInput then HueInput:Disconnect() end

                if RainbowColorPicker then
                    -- Toggle ON
                    TweenService:Create(RainbowToggleFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0
                    }):Play()
                    TweenService:Create(RainbowToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    RainbowToggleCircle:TweenPosition(
                        UDim2.new(1, -14, 0.5, -6),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.25,
                        true
                    )

                    OldToggleColor = BoxColor.BackgroundColor3
                    OldColor = Color.BackgroundColor3
                    OldColorSelectionPosition = ColorSelection.Position
                    OldHueSelectionPosition = HueSelection.Position

                    while RainbowColorPicker do
                        BoxColor.BackgroundColor3 = Color3.fromHSV(lib.RainbowColorValue, 1, 1)
                        Color.BackgroundColor3 = Color3.fromHSV(lib.RainbowColorValue, 1, 1)
                        ColorSelection.Position = UDim2.new(1, 0, 0, 0)
                        HueSelection.Position = UDim2.new(0.48, 0, 0, lib.HueSelectionPosition)
                        pcall(callback, BoxColor.BackgroundColor3)
                        wait()
                    end
                else
                    -- Toggle OFF
                    TweenService:Create(RainbowToggleFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()
                    TweenService:Create(RainbowToggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(180, 180, 180)
                    }):Play()
                    RainbowToggleCircle:TweenPosition(
                        UDim2.new(0, 2, 0.5, -6),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quart,
                        0.25,
                        true
                    )

                    BoxColor.BackgroundColor3 = OldToggleColor
                    Color.BackgroundColor3 = OldColor
                    ColorSelection.Position = OldColorSelectionPosition
                    HueSelection.Position = OldHueSelectionPosition
                    pcall(callback, BoxColor.BackgroundColor3)
                end
            end)

            ConfirmBtn.MouseButton1Click:Connect(function()
                ColorSelection.Visible = false
                HueSelection.Visible = false
                ColorPickerToggled = false
                Colorpicker:TweenSize(
                    UDim2.new(0, 434, 0, 38),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quart,
                    0.2,
                    true
                )
                wait(0.2)
                Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
            end)

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Label
        function tabcontent:Label(text)
            local Label = Instance.new("TextButton")
            local LabelCorner = Instance.new("UICorner")
            local LabelTitle = Instance.new("TextLabel")

            Label.Name = "Label"
            Label.Parent = Tab
            Label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Label.Size = UDim2.new(0, 434, 0, 38)
            Label.AutoButtonColor = false
            Label.Font = Enum.Font.SourceSans
            Label.Text = ""
            Label.TextColor3 = Color3.fromRGB(0, 0, 0)
            Label.TextSize = 14

            LabelCorner.CornerRadius = UDim.new(0, 5)
            LabelCorner.Parent = Label

            LabelTitle.Name = "LabelTitle"
            LabelTitle.Parent = Label
            LabelTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            LabelTitle.BackgroundTransparency = 1
            LabelTitle.Position = UDim2.new(0, 12, 0, 0)
            LabelTitle.Size = UDim2.new(1, -24, 1, 0)
            LabelTitle.Font = Enum.Font.Gotham
            LabelTitle.Text = text
            LabelTitle.TextColor3 = Color3.fromRGB(170, 170, 170)
            LabelTitle.TextSize = 13
            LabelTitle.TextXAlignment = Enum.TextXAlignment.Left

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Textbox
        function tabcontent:Textbox(text, disapper, callback)
            local Textbox = Instance.new("Frame")
            local TextboxCorner = Instance.new("UICorner")
            local TextboxTitle = Instance.new("TextLabel")
            local TextboxFrame = Instance.new("Frame")
            local TextboxFrameCorner = Instance.new("UICorner")
            local TextBox = Instance.new("TextBox")

            Textbox.Name = "Textbox"
            Textbox.Parent = Tab
            Textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Textbox.ClipsDescendants = true
            Textbox.Size = UDim2.new(0, 434, 0, 38)

            TextboxCorner.CornerRadius = UDim.new(0, 5)
            TextboxCorner.Parent = Textbox

            TextboxTitle.Name = "TextboxTitle"
            TextboxTitle.Parent = Textbox
            TextboxTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextboxTitle.BackgroundTransparency = 1
            TextboxTitle.Position = UDim2.new(0, 12, 0, 0)
            TextboxTitle.Size = UDim2.new(0, 200, 1, 0)
            TextboxTitle.Font = Enum.Font.Gotham
            TextboxTitle.Text = text
            TextboxTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            TextboxTitle.TextSize = 13
            TextboxTitle.TextXAlignment = Enum.TextXAlignment.Left

            TextboxFrame.Name = "TextboxFrame"
            TextboxFrame.Parent = Textbox
            TextboxFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TextboxFrame.BorderSizePixel = 0
            TextboxFrame.Position = UDim2.new(1, -120, 0, 7)
            TextboxFrame.Size = UDim2.new(0, 108, 0, 24)

            TextboxFrameCorner.CornerRadius = UDim.new(0, 4)
            TextboxFrameCorner.Parent = TextboxFrame

            TextBox.Parent = TextboxFrame
            TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextBox.BackgroundTransparency = 1
            TextBox.Size = UDim2.new(0, 100, 0, 24)
            TextBox.Position = UDim2.new(0, 4, 0, 0)
            TextBox.Font = Enum.Font.Gotham
            TextBox.Text = ""
            TextBox.TextColor3 = Color3.fromRGB(230, 230, 230)
            TextBox.TextSize = 13
            TextBox.PlaceholderText = "..."
            TextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)

            TextBox.FocusLost:Connect(function(ep)
                if ep then
                    if #TextBox.Text > 0 then
                        pcall(callback, TextBox.Text)
                        if disapper then
                            TextBox.Text = ""
                        end
                    end
                end
            end)
            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)
        end

        -- Bind (PC + Mobile adapted)
        function tabcontent:Bind(text, keypreset, callback)
            local binding = false
            local Key = keypreset.Name or "None"
            local Bind = Instance.new("TextButton")
            local BindCorner = Instance.new("UICorner")
            local BindTitle = Instance.new("TextLabel")
            local BindText = Instance.new("TextLabel")

            Bind.Name = "Bind"
            Bind.Parent = Tab
            Bind.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Bind.Size = UDim2.new(0, 434, 0, 38)
            Bind.AutoButtonColor = false
            Bind.Font = Enum.Font.SourceSans
            Bind.Text = ""
            Bind.TextColor3 = Color3.fromRGB(0, 0, 0)
            Bind.TextSize = 14

            BindCorner.CornerRadius = UDim.new(0, 5)
            BindCorner.Parent = Bind

            BindTitle.Name = "BindTitle"
            BindTitle.Parent = Bind
            BindTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            BindTitle.BackgroundTransparency = 1
            BindTitle.Position = UDim2.new(0, 12, 0, 0)
            BindTitle.Size = UDim2.new(0, 200, 1, 0)
            BindTitle.Font = Enum.Font.Gotham
            BindTitle.Text = text
            BindTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
            BindTitle.TextSize = 13
            BindTitle.TextXAlignment = Enum.TextXAlignment.Left

            BindText.Name = "BindText"
            BindText.Parent = Bind
            BindText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            BindText.BackgroundTransparency = 1
            BindText.Position = UDim2.new(0, 12, 0, 0)
            BindText.Size = UDim2.new(1, -24, 1, 0)
            BindText.Font = Enum.Font.GothamSemibold
            BindText.Text = Key
            BindText.TextColor3 = Color3.fromRGB(170, 170, 170)
            BindText.TextSize = 13
            BindText.TextXAlignment = Enum.TextXAlignment.Right

            Tab.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 5)

            Bind.MouseButton1Click:Connect(function()
                BindText.Text = "..."
                binding = true
                local inputwait = UserInputService.InputBegan:wait()
                if inputwait.KeyCode.Name ~= "Unknown" then
                    BindText.Text = inputwait.KeyCode.Name
                    Key = inputwait.KeyCode.Name
                end
                binding = false
            end)

            UserInputService.InputBegan:Connect(function(current, pressed)
                if not pressed then
                    if current.KeyCode.Name == Key and binding == false then
                        pcall(callback)
                    end
                end
            end)
        end

        return tabcontent
    end
    return tabhold
end

return lib