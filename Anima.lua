--[[
    AnimeUI v2 — Japanese Anime Style UI Library
    Lightweight • Clean • High-quality Tweens • Full Mobile + PC Support
]]

local AnimeUI = {}
AnimeUI.__index = AnimeUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- THEMES
--============================================================
local Themes = {
	["Purple Anime"] = {
		Primary      = Color3.fromHex("C8A2FF"),
		Secondary    = Color3.fromHex("A98BE8"),
		Accent       = Color3.fromHex("FF9FCB"),
		Background   = Color3.fromHex("15141B"),
		Panel        = Color3.fromHex("1D1B24"),
		Element      = Color3.fromHex("25222E"),
		ElementHover = Color3.fromHex("2E2A38"),
		Text         = Color3.fromHex("F5F2FA"),
		SubText      = Color3.fromHex("AAA5B5"),
		Border       = Color3.fromHex("393342"),
	},
	["Sakura"] = {
		Primary      = Color3.fromHex("FFB7C5"),
		Secondary    = Color3.fromHex("FF9EB5"),
		Accent       = Color3.fromHex("FF8FAB"),
		Background   = Color3.fromHex("1A1518"),
		Panel        = Color3.fromHex("231C20"),
		Element      = Color3.fromHex("2C2429"),
		ElementHover = Color3.fromHex("362C32"),
		Text         = Color3.fromHex("FFF0F3"),
		SubText      = Color3.fromHex("C9B0B8"),
		Border       = Color3.fromHex("3D3338"),
	},
	["Dark Anime"] = {
		Primary      = Color3.fromHex("9B8CFF"),
		Secondary    = Color3.fromHex("7B6FE0"),
		Accent       = Color3.fromHex("C4B5FD"),
		Background   = Color3.fromHex("0F0E14"),
		Panel        = Color3.fromHex("17161D"),
		Element      = Color3.fromHex("1F1E26"),
		ElementHover = Color3.fromHex("292830"),
		Text         = Color3.fromHex("EDE9FE"),
		SubText      = Color3.fromHex("A1A1AA"),
		Border       = Color3.fromHex("2E2D36"),
	},
}

--============================================================
-- UTILITY
--============================================================
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	return inst
end

function Util.Tween(obj, props, dur, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

function Util.Ripple(parent, color)
	local r = Util.Create("Frame", {
		BackgroundColor3 = color or Color3.new(1,1,1),
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = (parent.ZIndex or 1) + 2,
		Parent = parent,
	})
	Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = r})

	local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.6
	Util.Tween(r, {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
	}, 0.32)
	task.delay(0.35, function()
		if r and r.Parent then r:Destroy() end
	end)
end

function Util.IsTouch()
	return UserInputService.TouchEnabled
end

-- Unified input helper (works for both mouse & touch)
local function IsPrimaryInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

--============================================================
-- NOTIFICATION
--============================================================
local NotifGui, NotifList

local function EnsureNotif()
	if NotifGui and NotifGui.Parent then return end

	NotifGui = Util.Create("ScreenGui", {
		Name = "AnimeUI_Notifs",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		IgnoreGuiInset = true,
		Parent = PlayerGui,
	})

	NotifList = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 300, 1, -40),
		Position = UDim2.new(1, -320, 0, 20),
		Parent = NotifGui,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NotifList,
	})
end

function AnimeUI:Notify(opts)
	opts = opts or {}
	local theme = Themes[opts.Theme or "Purple Anime"] or Themes["Purple Anime"]
	local title = opts.Title or "Anime UI"
	local content = opts.Content or ""
	local duration = opts.Duration or 2.8

	EnsureNotif()

	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Parent = NotifList,
	})
	Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = card})
	Util.Create("UIStroke", {
		Color = theme.Border,
		Thickness = 1,
		Transparency = 0.45,
		Parent = card,
	})

	local accent = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Parent = card,
	})
	Util.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = accent})

	local titleL = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.new(0, 14, 0, 8),
		Font = Enum.Font.GothamMedium,
		Text = "✦  " .. title,
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local contentL = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.new(0, 14, 0, 30),
		Font = Enum.Font.Gotham,
		Text = content,
		TextColor3 = theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	-- force layout
	contentL.Size = UDim2.new(1, -20, 0, contentL.TextBounds.Y + 4)
	local h = 42 + contentL.TextBounds.Y
	card.Size = UDim2.new(1, 0, 0, h)

	-- animate in
	card.Position = UDim2.new(1, 50, 0, 0)
	card.BackgroundTransparency = 1
	titleL.TextTransparency = 1
	contentL.TextTransparency = 1
	accent.BackgroundTransparency = 1

	Util.Tween(card, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.08}, 0.3)
	Util.Tween(titleL, {TextTransparency = 0}, 0.25)
	Util.Tween(contentL, {TextTransparency = 0}, 0.25)
	Util.Tween(accent, {BackgroundTransparency = 0}, 0.25)

	task.delay(duration, function()
		if not card or not card.Parent then return end
		Util.Tween(card, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, 0.28)
		Util.Tween(titleL, {TextTransparency = 1}, 0.2)
		Util.Tween(contentL, {TextTransparency = 1}, 0.2)
		Util.Tween(accent, {BackgroundTransparency = 1}, 0.2)
		task.delay(0.32, function()
			if card then card:Destroy() end
		end)
	end)
end

--============================================================
-- WINDOW
--============================================================
function AnimeUI:CreateWindow(opts)
	opts = opts or {}
	local themeName = opts.Theme or "Purple Anime"
	local theme = Themes[themeName] or Themes["Purple Anime"]

	local win = {
		Title = opts.Title or "Anime UI",
		Subtitle = opts.Subtitle or "アニメ UI",
		Theme = theme,
		Tabs = {},
		CurrentTab = nil,
		Connections = {},
		Closed = false,
	}

	-- ScreenGui
	local sg = Util.Create("ScreenGui", {
		Name = "AnimeUI_" .. math.random(10000, 99999),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = PlayerGui,
	})

	-- UIScale
	local uiScale = Util.Create("UIScale", {Scale = 1, Parent = sg})

	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vs = cam.ViewportSize
		local s = 1
		if vs.X < 500 then
			s = 0.78
		elseif vs.X < 700 then
			s = 0.86
		elseif vs.X < 900 then
			s = 0.93
		end
		if Util.IsTouch() then
			s = math.clamp(s * 0.92, 0.72, 0.95)
		end
		uiScale.Scale = s
	end
	updateScale()
	table.insert(win.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

	-- Main Frame
	local main = Util.Create("Frame", {
		Name = "Main",
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(540, 360),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Parent = sg,
	})
	Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = main})
	Util.Create("UIStroke", {
		Color = theme.Border,
		Thickness = 1.2,
		Transparency = 0.3,
		Parent = main,
	})

	-- Header
	local header = Util.Create("Frame", {
		Name = "Header",
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = main,
	})
	Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = header})
	-- bottom fill so corners don't look weird
	Util.Create("Frame", {
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		Parent = header,
	})

	local titleLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		Font = Enum.Font.GothamMedium,
		Text = "✦  " .. win.Title,
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local subLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(0, 130, 0, 0),
		Font = Enum.Font.Gotham,
		Text = win.Subtitle,
		TextColor3 = theme.SubText,
		TextSize = 11,
		TextTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- Window buttons
	local function makeWinBtn(txt, x, cb)
		local b = Util.Create("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, x, 0.5, -13),
			Font = Enum.Font.GothamMedium,
			Text = txt,
			TextColor3 = theme.SubText,
			TextSize = 15,
			AutoButtonColor = false,
			Parent = header,
		})
		b.MouseEnter:Connect(function()
			Util.Tween(b, {TextColor3 = theme.Text}, 0.12)
		end)
		b.MouseLeave:Connect(function()
			Util.Tween(b, {TextColor3 = theme.SubText}, 0.12)
		end)
		b.MouseButton1Click:Connect(cb)
		b.TouchTap:Connect(cb)
		return b
	end

	local minimized = false
	makeWinBtn("—", -78, function()
		minimized = not minimized
		if minimized then
			Util.Tween(main, {Size = UDim2.fromOffset(540, 40)}, 0.22)
		else
			Util.Tween(main, {Size = UDim2.fromOffset(540, 360)}, 0.22)
		end
	end)
	makeWinBtn("□", -50, function() end) -- placeholder
	makeWinBtn("×", -22, function()
		win.Closed = true
		Util.Tween(main, {
			Size = UDim2.fromOffset(540, 0),
			BackgroundTransparency = 1,
		}, 0.2)
		task.delay(0.22, function()
			for _, c in ipairs(win.Connections) do
				if c.Connected then c:Disconnect() end
			end
			sg:Destroy()
		end)
	end)

	-- ========== DRAGGING (Header only, Mouse + Touch) ==========
	local dragging = false
	local dragStart, startPos

	local function beginDrag(input)
		if not IsPrimaryInput(input) then return end
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end

	local function updateDrag(input)
		if not dragging then return end
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	local function endDrag(input)
		if IsPrimaryInput(input) then
			dragging = false
		end
	end

	header.InputBegan:Connect(beginDrag)
	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging then updateDrag(input) end
	end)
	UserInputService.InputEnded:Connect(endDrag)

	-- Body
	local body = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		Parent = main,
	})

	-- Sidebar
	local sidebar = Util.Create("Frame", {
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 132, 1, 0),
		Parent = body,
	})
	Util.Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = sidebar,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})

	-- Content area
	local contentHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -140, 1, 0),
		Position = UDim2.new(0, 140, 0, 0),
		ClipsDescendants = true,
		Parent = body,
	})

	local scroll = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Primary,
		ScrollBarImageTransparency = 0.45,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = contentHolder,
	})

	local scrollLayout = Util.Create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
	end)

	-- Open animation
	main.Size = UDim2.fromOffset(520, 340)
	main.BackgroundTransparency = 1
	main.Position = UDim2.new(0.5, 0, 0.53, 0)
	Util.Tween(main, {
		Size = UDim2.fromOffset(540, 360),
		BackgroundTransparency = 0.06,
		Position = UDim2.fromScale(0.5, 0.5),
	}, 0.28)

	--========================================================
	-- TAB
	--========================================================
	function win:AddTab(tOpts)
		tOpts = tOpts or {}
		local name = tOpts.Name or "Tab"

		local tab = {
			Name = name,
			Active = false,
			Sections = {},
		}

		-- Tab button
		local btn = Util.Create("TextButton", {
			BackgroundColor3 = theme.Element,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Text = "",
			AutoButtonColor = false,
			Parent = sidebar,
		})
		Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})

		local indicator = Util.Create("Frame", {
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 3, 0, 14),
			Position = UDim2.new(0, 0, 0.5, -7),
			BackgroundTransparency = 1,
			Parent = btn,
		})
		Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = indicator})

		local txt = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -18, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			Font = Enum.Font.Gotham,
			Text = "○  " .. name,
			TextColor3 = theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		-- Content container for this tab
		local container = Util.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = scroll,
		})
		local contLayout = Util.Create("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = container,
		})
		contLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			container.Size = UDim2.new(1, 0, 0, contLayout.AbsoluteContentSize.Y)
		end)

		tab.Button = btn
		tab.Indicator = indicator
		tab.Text = txt
		tab.Container = container

		local function activate()
			if win.CurrentTab == tab then return end

			-- deactivate old
			if win.CurrentTab then
				local old = win.CurrentTab
				old.Active = false
				Util.Tween(old.Button, {BackgroundTransparency = 1}, 0.16)
				Util.Tween(old.Indicator, {BackgroundTransparency = 1}, 0.14)
				Util.Tween(old.Text, {TextColor3 = theme.SubText}, 0.14)
				old.Text.Text = "○  " .. old.Name
				Util.Tween(old.Container, {Position = UDim2.new(-0.04, 0, 0, 0)}, 0.16)
				task.delay(0.12, function()
					if old.Container then old.Container.Visible = false end
				end)
			end

			-- activate new
			tab.Active = true
			win.CurrentTab = tab
			Util.Tween(btn, {BackgroundTransparency = 0.35}, 0.16)
			Util.Tween(indicator, {BackgroundTransparency = 0}, 0.16)
			Util.Tween(txt, {TextColor3 = theme.Text}, 0.14)
			txt.Text = "●  " .. name

			container.Visible = true
			container.Position = UDim2.new(0.04, 0, 0, 0)
			Util.Tween(container, {Position = UDim2.new(0, 0, 0, 0)}, 0.18)
		end

		btn.MouseButton1Click:Connect(activate)
		btn.TouchTap:Connect(activate)

		btn.MouseEnter:Connect(function()
			if not tab.Active then
				Util.Tween(btn, {BackgroundTransparency = 0.65}, 0.12)
			end
		end)
		btn.MouseLeave:Connect(function()
			if not tab.Active then
				Util.Tween(btn, {BackgroundTransparency = 1}, 0.12)
			end
		end)

		if #win.Tabs == 0 then
			task.defer(activate)
		end
		table.insert(win.Tabs, tab)

		--====================================================
		-- SECTION
		--====================================================
		function tab:AddSection(sOpts)
			sOpts = sOpts or {}
			local sName = sOpts.Name or "Section"

			local section = Util.Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -4, 0, 0),
				Parent = container,
			})
			local secLayout = Util.Create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = section,
			})

			-- header
			local head = Util.Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Parent = section,
			})
			Util.Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = "✦  " .. string.upper(sName),
				TextColor3 = theme.Primary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = head,
			})

			-- content box
			local box = Util.Create("Frame", {
				BackgroundColor3 = theme.Element,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				Parent = section,
			})
			Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = box})
			Util.Create("UIStroke", {
				Color = theme.Border,
				Thickness = 1,
				Transparency = 0.5,
				Parent = box,
			})
			Util.Create("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = box,
			})
			local boxLayout = Util.Create("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = box,
			})
			boxLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				box.Size = UDim2.new(1, 0, 0, boxLayout.AbsoluteContentSize.Y + 20)
				section.Size = UDim2.new(1, -4, 0, secLayout.AbsoluteContentSize.Y)
			end)

			local sec = {Frame = section, Box = box}

			-- Label
			function sec:AddLabel(o)
				o = o or {}
				return Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Font = Enum.Font.Gotham,
					Text = o.Text or "Label",
					TextColor3 = theme.SubText,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = box,
				})
			end

			-- Divider
			function sec:AddDivider()
				return Util.Create("Frame", {
					BackgroundColor3 = theme.Border,
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 1),
					Parent = box,
				})
			end

			-- Button
			function sec:AddButton(o)
				o = o or {}
				local name = o.Name or "Button"
				local cb = o.Callback or function() end

				local b = Util.Create("TextButton", {
					BackgroundColor3 = theme.Element,
					BackgroundTransparency = 0.15,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 34),
					Text = "",
					AutoButtonColor = false,
					ClipsDescendants = true,
					Parent = box,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = b})
				Util.Create("UIStroke", {
					Color = theme.Border,
					Thickness = 1,
					Transparency = 0.45,
					Parent = b,
				})
				Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -16, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.Gotham,
					Text = name .. "  ›",
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = b,
				})

				b.MouseEnter:Connect(function()
					Util.Tween(b, {BackgroundColor3 = theme.ElementHover}, 0.14)
				end)
				b.MouseLeave:Connect(function()
					Util.Tween(b, {BackgroundColor3 = theme.Element}, 0.14)
				end)

				local function press()
					Util.Tween(b, {Size = UDim2.new(1, -3, 0, 32)}, 0.07)
				end
				local function release()
					Util.Tween(b, {Size = UDim2.new(1, 0, 0, 34)}, 0.11)
				end

				b.InputBegan:Connect(function(i)
					if IsPrimaryInput(i) then press() end
				end)
				b.InputEnded:Connect(function(i)
					if IsPrimaryInput(i) then release() end
				end)

				local function click()
					Util.Ripple(b, theme.Accent)
					task.spawn(cb)
				end
				b.MouseButton1Click:Connect(click)
				b.TouchTap:Connect(click)

				return b
			end

			-- Toggle
			function sec:AddToggle(o)
				o = o or {}
				local name = o.Name or "Toggle"
				local state = o.Default or false
				local cb = o.Callback or function() end

				local frame = Util.Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 28),
					Parent = box,
				})
				Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -55, 1, 0),
					Font = Enum.Font.Gotham,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame,
				})

				local track = Util.Create("Frame", {
					BackgroundColor3 = state and theme.Accent or theme.Border,
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(42, 22),
					Position = UDim2.new(1, -42, 0.5, -11),
					Parent = frame,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = track})

				local thumb = Util.Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(18, 18),
					Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
					Parent = track,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = thumb})

				local glow = Util.Create("UIStroke", {
					Color = theme.Accent,
					Thickness = 0,
					Transparency = 1,
					Parent = track,
				})

				local function set(v, anim)
					state = v
					local d = anim and 0.18 or 0
					Util.Tween(track, {BackgroundColor3 = state and theme.Accent or theme.Border}, d)
					Util.Tween(thumb, {
						Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
					}, d)
					Util.Tween(glow, {
						Thickness = state and 2.5 or 0,
						Transparency = state and 0.55 or 1,
					}, d)
					task.spawn(cb, state)
				end

				local hit = Util.Create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					Parent = frame,
				})
				hit.MouseButton1Click:Connect(function() set(not state, true) end)
				hit.TouchTap:Connect(function() set(not state, true) end)

				set(state, false)

				return {
					Set = function(_, v) set(v, true) end,
					Get = function() return state end,
				}
			end

			-- Slider (fully touch + mouse compatible)
			function sec:AddSlider(o)
				o = o or {}
				local name = o.Name or "Slider"
				local min = o.Min or 0
				local max = o.Max or 100
				local value = math.clamp(o.Default or min, min, max)
				local cb = o.Callback or function() end

				local frame = Util.Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 48),
					Parent = box,
				})

				local top = Util.Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Parent = frame,
				})
				Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.65, 0, 1, 0),
					Font = Enum.Font.Gotham,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = top,
				})
				local valLabel = Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.35, 0, 1, 0),
					Position = UDim2.new(0.65, 0, 0, 0),
					Font = Enum.Font.GothamMedium,
					Text = tostring(value),
					TextColor3 = theme.Primary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = top,
				})

				local track = Util.Create("Frame", {
					BackgroundColor3 = theme.Border,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 0, 28),
					Parent = frame,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = track})

				local fill = Util.Create("Frame", {
					BackgroundColor3 = theme.Accent,
					BorderSizePixel = 0,
					Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
					Parent = track,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})

				local thumb = Util.Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8),
					ZIndex = 3,
					Parent = track,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = thumb})
				Util.Create("UIStroke", {
					Color = theme.Accent,
					Thickness = 1.5,
					Transparency = 0.25,
					Parent = thumb,
				})

				local sliding = false

				local function update(posX)
					local absPos = track.AbsolutePosition.X
					local absSize = track.AbsoluteSize.X
					if absSize <= 0 then return end
					local rel = math.clamp((posX - absPos) / absSize, 0, 1)
					value = math.floor(min + (max - min) * rel + 0.5)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					thumb.Position = UDim2.new(rel, -8, 0.5, -8)
					valLabel.Text = tostring(value)
					task.spawn(cb, value)
				end

				track.InputBegan:Connect(function(input)
					if IsPrimaryInput(input) then
						sliding = true
						Util.Tween(thumb, {Size = UDim2.fromOffset(18, 18)}, 0.1)
						update(input.Position.X)
					end
				end)

				local function onChange(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch) then
						update(input.Position.X)
					end
				end
				track.InputChanged:Connect(onChange)
				table.insert(win.Connections, UserInputService.InputChanged:Connect(onChange))

				local function onEnd(input)
					if IsPrimaryInput(input) then
						sliding = false
						Util.Tween(thumb, {Size = UDim2.fromOffset(16, 16)}, 0.12)
					end
				end
				track.InputEnded:Connect(onEnd)
				table.insert(win.Connections, UserInputService.InputEnded:Connect(onEnd))

				return {
					Set = function(_, v)
						value = math.clamp(v, min, max)
						local rel = (value - min) / (max - min)
						fill.Size = UDim2.new(rel, 0, 1, 0)
						thumb.Position = UDim2.new(rel, -8, 0.5, -8)
						valLabel.Text = tostring(value)
						task.spawn(cb, value)
					end,
					Get = function() return value end,
				}
			end

			-- Dropdown
			function sec:AddDropdown(o)
				o = o or {}
				local name = o.Name or "Dropdown"
				local items = o.Items or {"Option"}
				local selected = o.Default or items[1]
				local cb = o.Callback or function() end
				local open = false

				local frame = Util.Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 34),
					ClipsDescendants = false,
					ZIndex = 8,
					Parent = box,
				})

				local mainBtn = Util.Create("TextButton", {
					BackgroundColor3 = theme.Element,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 34),
					Text = "",
					AutoButtonColor = false,
					ZIndex = 9,
					Parent = frame,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = mainBtn})
				Util.Create("UIStroke", {
					Color = theme.Border,
					Thickness = 1,
					Transparency = 0.45,
					Parent = mainBtn,
				})

				local mainTxt = Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -36, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.Gotham,
					Text = name .. "  ·  " .. selected,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 10,
					Parent = mainBtn,
				})

				local arrow = Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(20, 20),
					Position = UDim2.new(1, -28, 0.5, -10),
					Font = Enum.Font.GothamBold,
					Text = "▼",
					TextColor3 = theme.SubText,
					TextSize = 10,
					ZIndex = 10,
					Parent = mainBtn,
				})

				local list = Util.Create("Frame", {
					BackgroundColor3 = theme.Panel,
					BackgroundTransparency = 0.05,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 38),
					Visible = false,
					ClipsDescendants = true,
					ZIndex = 20,
					Parent = frame,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = list})
				Util.Create("UIStroke", {
					Color = theme.Border,
					Thickness = 1,
					Transparency = 0.35,
					Parent = list,
				})
				Util.Create("UIPadding", {
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					Parent = list,
				})
				local listLayout = Util.Create("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = list,
				})

				local function toggle()
					open = not open
					if open then
						list.Visible = true
						local h = #items * 28 + 12
						Util.Tween(list, {Size = UDim2.new(1, 0, 0, h)}, 0.18)
						Util.Tween(arrow, {Rotation = 180}, 0.18)
						frame.Size = UDim2.new(1, 0, 0, 34 + h + 6)
					else
						Util.Tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
						Util.Tween(arrow, {Rotation = 0}, 0.15)
						task.delay(0.16, function()
							list.Visible = false
						end)
						frame.Size = UDim2.new(1, 0, 0, 34)
					end
				end

				for _, item in ipairs(items) do
					local it = Util.Create("TextButton", {
						BackgroundColor3 = theme.Element,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 26),
						Font = Enum.Font.Gotham,
						Text = "  " .. item,
						TextColor3 = theme.SubText,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false,
						ZIndex = 21,
						Parent = list,
					})
					Util.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = it})

					it.MouseEnter:Connect(function()
						Util.Tween(it, {BackgroundTransparency = 0.35, TextColor3 = theme.Text}, 0.1)
					end)
					it.MouseLeave:Connect(function()
						Util.Tween(it, {BackgroundTransparency = 1, TextColor3 = theme.SubText}, 0.1)
					end)

					local function select()
						selected = item
						mainTxt.Text = name .. "  ·  " .. selected
						toggle()
						task.spawn(cb, selected)
					end
					it.MouseButton1Click:Connect(select)
					it.TouchTap:Connect(select)
				end

				mainBtn.MouseButton1Click:Connect(toggle)
				mainBtn.TouchTap:Connect(toggle)

				return {
					Set = function(_, v)
						if table.find(items, v) then
							selected = v
							mainTxt.Text = name .. "  ·  " .. selected
							task.spawn(cb, selected)
						end
					end,
					Get = function() return selected end,
				}
			end

			-- Textbox
			function sec:AddTextbox(o)
				o = o or {}
				local name = o.Name or "Textbox"
				local placeholder = o.Placeholder or "Enter text..."
				local default = o.Default or ""
				local cb = o.Callback or function() end

				local frame = Util.Create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 54),
					Parent = box,
				})
				Util.Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Font = Enum.Font.Gotham,
					Text = name,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame,
				})

				local box = Util.Create("TextBox", {
					BackgroundColor3 = theme.Element,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 32),
					Position = UDim2.new(0, 0, 0, 22),
					Font = Enum.Font.Gotham,
					Text = default,
					PlaceholderText = placeholder,
					PlaceholderColor3 = theme.SubText,
					TextColor3 = theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					Parent = frame,
				})
				Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = box})
				local stroke = Util.Create("UIStroke", {
					Color = theme.Border,
					Thickness = 1,
					Transparency = 0.45,
					Parent = box,
				})
				Util.Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					Parent = box,
				})

				box.Focused:Connect(function()
					Util.Tween(stroke, {Color = theme.Accent, Transparency = 0.15}, 0.14)
				end)
				box.FocusLost:Connect(function()
					Util.Tween(stroke, {Color = theme.Border, Transparency = 0.45}, 0.14)
					task.spawn(cb, box.Text)
				end)

				return {
					Set = function(_, t) box.Text = t end,
					Get = function() return box.Text end,
				}
			end

			return sec
		end

		return tab
	end

	return win
end

return AnimeUI