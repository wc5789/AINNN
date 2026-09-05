--[[
	ImGuiStyle: Theme system for the ImGui Library
	Centralizes all colors, sizes, and visual properties
]]

local ImGuiStyle = {}
ImGuiStyle.__index = ImGuiStyle

-- Default monochrome theme (ImGui-inspired)
local DefaultTheme = {
	-- Window properties
	Window = {
		BackgroundColor = Color3.fromRGB(45, 45, 48),
		TitleBarColor = Color3.fromRGB(54, 54, 57),
		BorderColor = Color3.fromRGB(65, 65, 68),
		ShadowColor = Color3.fromRGB(0, 0, 0),
		TitleTextColor = Color3.fromRGB(225, 225, 225),
		MinimizeButtonColor = Color3.fromRGB(180, 180, 180),
		MinimizeButtonHoverColor = Color3.fromRGB(220, 220, 220),
	},
	
	-- Content area
	Content = {
		BackgroundColor = Color3.fromRGB(30, 30, 30),
		DividerColor = Color3.fromRGB(55, 55, 58),
		ScrollBarColor = Color3.fromRGB(65, 65, 68),
		ScrollBarThumbColor = Color3.fromRGB(90, 90, 92),
	},
	
	-- Row properties
	Row = {
		BackgroundColor = Color3.fromRGB(38, 38, 40),
		HoverColor = Color3.fromRGB(52, 52, 55),
		PressedColor = Color3.fromRGB(32, 32, 34),
		SelectedColor = Color3.fromRGB(200, 200, 205),
		TextColor = Color3.fromRGB(210, 210, 215),
		SelectedTextColor = Color3.fromRGB(25, 25, 27),
		SecondaryTextColor = Color3.fromRGB(145, 145, 150),
		ActionIndicatorColor = Color3.fromRGB(130, 130, 135),
	},
	
	-- Slider properties
	Slider = {
		TrackColor = Color3.fromRGB(70, 70, 73),
		TrackFillColor = Color3.fromRGB(160, 160, 165),
		ThumbColor = Color3.fromRGB(230, 230, 235),
		ThumbSize = 14,
		TrackHeight = 4,
		MarkerColor = Color3.fromRGB(100, 100, 103),
		MarkerCount = 5,
		LabelTextColor = Color3.fromRGB(195, 195, 200),
		ValueTextColor = Color3.fromRGB(210, 210, 215),
	},
	
	-- Toggle properties
	Toggle = {
		OffTrackColor = Color3.fromRGB(70, 70, 73),
		OffThumbColor = Color3.fromRGB(230, 230, 235),
		OnTrackColor = Color3.fromRGB(130, 130, 135),
		OnThumbColor = Color3.fromRGB(25, 25, 27),
		TrackWidth = 40,
		TrackHeight = 18,
		ThumbSize = 12,
	},
	
	-- Button properties
	Button = {
		BackgroundColor = Color3.fromRGB(55, 55, 58),
		HoverColor = Color3.fromRGB(70, 70, 73),
		PressedColor = Color3.fromRGB(45, 45, 48),
		BorderColor = Color3.fromRGB(80, 80, 83),
		TextColor = Color3.fromRGB(210, 210, 215),
		CornerRadius = 4,
	},
	
	-- Dropdown properties
	Dropdown = {
		BackgroundColor = Color3.fromRGB(38, 38, 40),
		HoverColor = Color3.fromRGB(52, 52, 55),
		SelectedColor = Color3.fromRGB(65, 65, 68),
		BorderColor = Color3.fromRGB(65, 65, 68),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(160, 160, 165),
		CornerRadius = 4,
	},
	
	-- Section properties
	Section = {
		BackgroundColor = Color3.fromRGB(42, 42, 44),
		ExpandedColor = Color3.fromRGB(48, 48, 50),
		TextColor = Color3.fromRGB(210, 210, 215),
		IndicatorColor = Color3.fromRGB(150, 150, 155),
		CornerRadius = 4,
		ExpandDuration = 0.2,
	},
	
	-- Label properties
	Label = {
		PrimaryTextColor = Color3.fromRGB(210, 210, 215),
		SecondaryTextColor = Color3.fromRGB(145, 145, 150),
	},
	
	-- Typography
	Typography = {
		WindowTitleSize = 14,
		WindowTitleFont = Enum.Font.GothamMedium,
		LabelSize = 13,
		LabelFont = Enum.Font.Gotham,
		SecondaryLabelSize = 11,
		SecondaryLabelFont = Enum.Font.Gotham,
		ValueSize = 12,
		ValueFont = Enum.Font.Gotham,
		ButtonSize = 13,
		ButtonFont = Enum.Font.GothamMedium,
	},
	
	-- Spacing (in pixels at 1x scale)
	Spacing = {
		WindowPadding = 12,
		WindowTitleBarHeight = 32,
		WindowCornerRadius = 6,
		WindowBorderSize = 1,
		RowHeight = 32,
		RowPadding = 10,
		RowSpacing = 2,
		ComponentSpacing = 8,
		SectionSpacing = 6,
		IconSize = 16,
		MinimizeButtonSize = 12,
		ActionIndicatorSize = 16,
		DropdownArrowSize = 10,
		BorderSize = 1,
	},
	
	-- Shadow
	Shadow = {
		Enabled = true,
		Color = Color3.fromRGB(0, 0, 0),
		Offset = Vector2.new(0, 4),
		Size = 12,
		Transparency = 0.4,
		PopupShadowTransparency = 0.35,
		PopupShadowSize = 16,
	},
	
	-- Animation
	Animation = {
		WindowOpenDuration = 0.25,
		WindowCloseDuration = 0.2,
		MinimizeDuration = 0.15,
		HoverDuration = 0.1,
		PressedDuration = 0.08,
		ToggleDuration = 0.15,
		SectionExpandDuration = 0.2,
		DropdownDuration = 0.15,
		EasingStyle = Enum.EasingStyle.Quad,
		OpenDirection = Enum.EasingDirection.Out,
		CloseDirection = Enum.EasingDirection.In,
	},
	
	-- Optional accent color (muted, for specific use cases)
	Accent = {
		Enabled = false,
		Color = Color3.fromRGB(86, 151, 232),
	},
	
	-- Responsive scaling
	Responsive = {
		MinScale = 0.7,
		MaxScale = 1.5,
		DefaultScale = 1.0,
	},
}

function ImGuiStyle.new(overrides)
	local self = setmetatable({}, ImGuiStyle)
	
	-- Deep copy default theme
	self._theme = {}
	for category, props in pairs(DefaultTheme) do
		self._theme[category] = {}
		if type(props) == "table" then
			for key, value in pairs(props) do
				if type(value) == "table" then
					self._theme[category][key] = {}
					for k, v in pairs(value) do
						self._theme[category][key][k] = v
					end
				else
					self._theme[category][key] = value
				end
			end
		else
			self._theme[category] = props
		end
	end
	
	-- Apply overrides
	if overrides then
		self:ApplyOverrides(overrides)
	end
	
	return self
end

function ImGuiStyle:ApplyOverrides(overrides)
	for category, props in pairs(overrides) do
		if self._theme[category] then
			for key, value in pairs(props) do
				self._theme[category][key] = value
			end
		else
			self._theme[category] = props
		end
	end
end

function ImGuiStyle:Get(category)
	return self._theme[category] or {}
end

function ImGuiStyle:GetAll()
	return self._theme
end

function ImGuiStyle:CreateDarkVariant(tint)
	-- Creates a darker/lighter variant of the theme
	local variant = ImGuiStyle.new()
	
	-- Adjust colors based on tint (-1 = darker, 1 = lighter)
	local function adjustColor(color, amount)
		return Color3.new(
			math.clamp(color.R + amount * 0.05, 0, 1),
			math.clamp(color.G + amount * 0.05, 0, 1),
			math.clamp(color.B + amount * 0.05, 0, 1)
		)
	end
	
	-- Apply tint to color categories
	local categories = {"Window", "Content", "Row", "Slider", "Toggle", "Button", "Dropdown", "Section", "Label"}
	for _, cat in ipairs(categories) do
		if variant._theme[cat] then
			for key, value in pairs(variant._theme[cat]) do
				if value and value.R and value.G and value.B then
					variant._theme[cat][key] = adjustColor(value, tint)
				end
			end
		end
	end
	
	return variant
end

return ImGuiStyle
