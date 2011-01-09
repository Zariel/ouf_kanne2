local parent, ns = ...
local layout = ns.layout
if(not layout) then return end

local durationTimer = function(self, elapsed)
	local expirationTime = select(7, UnitAura(self.unit, self:GetID(), "HARMFUL"))

	if expirationTime and ((expirationTime - GetTime())) < 300 and expirationTime > 0 then
		self.duration:SetText(floor(expirationTime - GetTime() + 0.5))
	else
		self.duration:Hide()
		return self:SetScript("OnUpdate", nil)
	end
end

function layout:PostUpdateAuraIcon(unit, icon, index, offset)
	icon.unit = unit

	local name, rank, btexture, count, dtype, duration, timeLeft, caster = UnitAura(unit, index, icon.filter)

	icon.name = name
	icon.caster = caster

	if(caster and (caster == "player" or caster == "pet")) then
		icon:SetAlpha(1)
	else
		icon:SetAlpha(0.5)
	end

	if(icon.debuff and timeLeft and timeLeft > 0) then
		icon:SetScript("OnUpdate", durationTimer)
		icon.duration:Show()
	else
		icon.duration:Hide()
	end

	if icon.debuff then
		local col = DebuffTypeColor[dtype or "none"]
		icon.overlay:SetVertexColor(col.r, col.g, col.b)
	else
		icon.overlay:SetVertexColor(0.45, 0.45, 0.45)
	end
end

function layout:PreAuraSetPosition(self, icons, max)
	table.sort(icons, function(self, a, b)
		if a and b then
			if a.caster == "player" then
				return true
			else
				return a.name < b.name
			end
		else
			return false
		end
	end)
end

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitAura(self.parent.unit, self:GetID(), self.filter)
end

local OnLeave = function()
	return GameTooltip:Hide()
end

local condom = setmetatable({}, { __index = function()
	return dummy
end})

function layout:CreateAuraIcon(index)
	local icons = self -- TODO: FIX THIS
	local size = icons.size or 16

	local button = CreateFrame("Frame", nil, icons)
	button:SetHeight(size)
	button:SetWidth(size)
	button:SetID(index)
	button:EnableMouse(true)

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetPoint("LEFT", 1, 0)
	icon:SetPoint("RIGHT", -1, 0)
	icon:SetPoint("TOP", 0, -1)
	icon:SetPoint("BOTTOM", 0, 1)

	local skin = button:CreateTexture(nil, "OVERLAY")
	skin:SetTexture(apathy)
	skin:SetBlendMode("BLEND")
	skin:SetPoint("TOP", 0, 2)
	skin:SetPoint("LEFT", -2, 0)
	skin:SetPoint("BOTTOM", 0, -2)
	skin:SetPoint("RIGHT", 2, 0)
	skin:SetHeight(size + 2)
	skin:SetWidth(size + 2)
	skin:SetVertexColor(0.45, 0.45, 0.45)
	skin:Show()
	skin.Hide = dummy

	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetFont(supernova, 10, "THINOUTLINE")
	count:SetShadowColor(0, 0, 0, 1)
	count:SetShadowOffset(1, -1)
	count:SetTextColor(1, 1, 0)
	count:SetPoint("BOTTOMRIGHT", -1, 1)
	count:SetJustifyH("RIGHT")

	local duration = button:CreateFontString(nil, "OVERLAY")
	duration:SetFont(supernova, 13, "OUTLINE")
	duration:SetShadowColor(0, 0, 0, 0.8)
	duration:SetShadowOffset(1, -1)
	duration:SetTextColor(1, 0, 0)
	duration:SetPoint("TOPLEFT", 1, -1)
	duration:SetJustifyH("LEFT")

	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	button.parent = icons
	button.frame = self
	button.icon = icon
	button.overlay = skin
	button.count = count
	button.duration = duration

	button.cd = condom
	button.cd.noCooldownCount = true

	table.insert(icons, button)

	return button
end
