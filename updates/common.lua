local parent, ns = ...
local layout = ns.layout
if(not layout) then return end

local powerBreak = ns.powerBreak
local format = ns.format
local colors = ns.colors

local height, width = ns.height, ns.width

local ColorGradient = function(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if(perc >= 1) then
		return { r3, g3, b3 }
	elseif(perc <= 0) then
		return { r1, g1, b1 }
	end

	local segment, relperc = math.modf(perc * (3 - 1))
	local offset = (segment * 3) + 1

	if(offset == 1) then
		return { r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc}
	end

	return { r2 + (r3 - r2) * relperc, g2 + (g3 - g2) * relperc, b2 + (b3 - b2) * relperc }
end

function layout:Heal_Update(event, unit)
	if(self.unit ~= unit) then return end

	local hp = self.HealPrediction
	local incHeal = UnitGetIncomingHeals(unit)

	if(incHeal) then
		local width = self.Health:GetWidth()
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local per = min / max
		local incPer = incHeal / max
		local incSize = incPer * width
		local size = per * width

		if(incSize + size >= width) then
			incSize = width - size
		end

		if(incSize > 0) then
			hp:SetWidth(incSize)
			hp:SetPoint("LEFT", self, "LEFT", size, 0)
			hp:Show()
		else
			hp:Hide()
		end
	else
		hp:Hide()
	end
end

function layout:Health_Update(unit, current, max)
	self:SetValue(current)
	local val = self.value

	local per = floor(current * 100 / max)

	if(per == 100 or per == 0) then
		return val:Hide()
	else
		local form = format[unit]
		val:Show()

		if(powerBreak[unit]) then
			val:SetFormattedText(form.health_full, per)
		else
			local col = ns:ToHex(unpack(ColorGradient(per/100, 1, 0, 0, 1, 1, 0, 0, 1, 0)))
			-- current will never == per ??
			if(current == per) then
				val:SetFormattedText(form.health_perOnly, col, per)
			else
				val:SetFormattedText(form.health_per, col, current, per)
			end
		end
	end

	local hp = self:GetParent().HealPrediction
	if(hp:IsShown()) then
		local size = per * self:GetWidth()
		hp:SetPoint("LEFT", self, "LEFT", size, 0)
	end
end

function layout:Power_Update(unit, current, max)
	self:SetValue(current)
	local val = self.value

	val:SetText(current)

	local col
	if(unit == "pet") then
		local happiness = GetPetHappiness()
		if(happiness) then
			col = colors.happy[happiness]
		else
			col = colors.mp[UnitPowerType(unit)] or { 1, 1, 1 }
		end
	else
		col = colors.mp[UnitPowerType(unit)] or { 1, 1, 1 }
	end

	self:GetParent().Power:SetStatusBarColor(unpack(col))
	self:GetParent().Power.bg:SetVertexColor(unpack(col))

	if(powerBreak[unit] or current == max or current == 0) then
		val:Hide()
	else
		val:Show()
	end
end

function layout:Name_Update(event, unit)
	if(self.unit ~= unit) then return end

	if(unit == "player") then
		self.Name:Hide()
	else
		self.Name:Show()
	end

	local class = select(2, UnitClass(unit))
	local color = colors.class[class] or { 1, 1, 1 }
	self.Health:SetStatusBarColor(unpack(color))
	self.Health.bg:SetVertexColor(unpack(color))

	local level = UnitLevel(unit)
	local name = UnitName(unit)

	self._level = level
	self._name = name
	self._color = color

	if(powerBreak[unit]) then
		self.Name:SetText(string.sub(name, 1, 5))
		-- Incase playerName == petName
		if(name == playerName and unit ~= "pet") then
			self.Name:SetTextColor(1, 0, 0)
		else
			self.Name:SetTextColor(1, 1, 1)
		end
	else
		self.Name:SetFormattedText(format.all.name, ns:ToHex(unpack(colors.class[select(2, UnitClass(unit))] or "WARRIOR")), level, name)
	end
end
