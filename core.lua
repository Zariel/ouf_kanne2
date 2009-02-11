--[[
Copyright (c) 2008 Chris Bannister,
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local _G = getfenv(0)
local oUF = _G.oUF

local select = select
local floor = math.floor
local UnitName = UnitName
local UnitDebuff = UnitDebuff
local UnitBuff = UnitBuff
local UnitClass = UnitClass
local UnitAura = UnitAura
local GetTime = GetTime
local SecondsToTimeAbbrev = SecondsToTimeAbbrev

local height, width = 35, 250
local playerName = UnitName("player")

local supernova = [[Interface\AddOns\oUF_Kanne2\media\nokiafc22.ttf]]
local texture = [[Interface\AddOns\oUF_Kanne2\media\HalV.tga]]
local apathy = [[Interface\AddOns\oUF_Kanne2\media\Normal.tga]]

local name, rank, buffTexture, count, duration, timeLeft, dtype

local dummy = function() end

function oUF:UNIT_NAME_UPDATE(event, unit)
	if(self.unit ~= unit) then return end
	local name = UnitName(unit)

	self.Name:SetText(name)
end

table.insert(oUF.subTypes, function(self)
	if(self.Name) then
		self:RegisterEvent"UNIT_NAME_UPDATE"
	end
end)

oUF:RegisterSubTypeMapping("UNIT_NAME_UPDATE")

local colors = {
	mp = {
		[0] = { 48/255, 113/255,191/255 }, -- Mana
		[1] = { 226/255, 45/255, 75/255 }, -- Rage
		[2] = { 255/255, 178/255, 0 }, -- Focus
		[3] = { 1, 1, 34/255 }, -- Energy
		[4] = { 0, 1, 1 }, -- Happiness
		[5] = { 0.5, 0.5, 0.5 },
		[6] = { 0, 0.82, 1 }
	},
	class ={
		["DEATHKNIGHT"] = { 0.77, 0.12, 0.23 },
		["DRUID"] = { 1.0 , 0.49, 0.04 },
		["HUNTER"] = { 0.67, 0.83, 0.45 },
		["MAGE"] = { 0.41, 0.8 , 0.94 },
		["PALADIN"] = { 0.96, 0.55, 0.73 },
		["PRIEST"] = { 1.0 , 1.0 , 1.0 },
		["ROGUE"] = { 1.0 , 0.96, 0.41 },
		["SHAMAN"] = { 0,0.86,0.73 },
		["WARLOCK"] = { 0.58, 0.51, 0.7 },
		["WARRIOR"] = { 0.78, 0.61, 0.43 },
	},
	happy = {
		[1] = { 1, 0, 0 }, -- need.... | unhappy
		[2] = { 1, 1, 0 }, -- new..... | content
		[3] = { 0, 1, 0 }, -- colors.. | happy
	},
}

setmetatable(colors.class, {
	__index = function(self, key)
		return self.WARRIOR
	end
})

local format = setmetatable({
	["all"] = setmetatable({
		["health"] = "%d.%d%%",
		["health_full"] = "%d%%",
		["health_per"] = "|cff%s%d|r.%d%%",
		["health_perOnly"] = "|cff%s%d|r%%",
		["power"] = "%d.|cffADADAD%d|r",
		["power_full"] = "%d",
		["name"] = "|cff%s%s|r %s",
	},{
		__index = function(self, key)
			return "%s"
		end,
	}),
	["player"] = {
	},
	["target"] = {},
	["targettarget"] = {
		["name"] = "%s",
	},
	["pet"] = {},
}, {
	__index = function(self, key)
		return self.all
	end,
})

for k, v in pairs(format) do
	if k ~= "all" then
		k = setmetatable(v, {
			__index = function(self, key)
				return format.all[key]
			end,
		})
	end
end

local powerBreak = {
	["targettarget"] = true,
	["focus"] = true,
	["pet"] = true,
}

local ColorGradient = function(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then
		return {r3, g3, b3}
	elseif perc <= 0 then
		return {r1, g1, b1}
	end

	local segment, relperc = math.modf(perc*(3-1))
	local offset = (segment*3)+1

	if(offset == 1) then
		return {r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc}
	end

	return {r2 + (r3-r2)*relperc, g2 + (g3-g2)*relperc, b2 + (b3-b2)*relperc}
end

local toHex = function(r,g,b)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local Health_Update = function(self, event, unit, bar, current, max)
	bar:SetValue(current)
	local val = bar.value

	local form = format[unit]
	local per = floor((current/max)*100)

	if per == 100 or per == 0 then
		val:Hide()
	else
		val:Show()
		if powerBreak[unit] then
			val:SetFormattedText(form.health_full, per)
		else
			local col = toHex(unpack(ColorGradient(per/100, 1, 0, 0, 1, 1, 0, 0, 1, 0)))
			if current == per then
				val:SetFormattedText(form.health_perOnly, col, per)
			else
				val:SetFormattedText(form.health_per, col, current, per)
			end
		end
	end
end

local Power_Update = function(self, event, unit, bar, current, max)
	bar:SetValue(current)
	local val = bar.value

	val:SetText(current)

	if unit ~= "pet" then
		local col = colors.mp[UnitPowerType(unit)] or {1,1,1}
		self.Power:SetStatusBarColor(unpack(col))
		self.Power.bg:SetVertexColor(unpack(col))

	end

	if powerBreak[unit] then
		return val:Hide()
	end

	if current == max or current == 0 then
		val:Hide()
	else
		val:Show()
	end
end

local Name_Update = function(self, event, unit)
	if self.unit ~= unit then return end
	if unit == "player" then
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
	if powerBreak[unit] then
		self.Name:SetText(string.sub(name, 1, 5))
		if UnitName(unit) == playerName and unit ~= "pet" then
			self.Name:SetTextColor(1,0,0)
		else
			self.Name:SetTextColor(1, 1, 1)
		end
	else
		self.Name:SetFormattedText(format.all.name, toHex(unpack(colors.class[select(2, UnitClass(unit))] or "WARRIOR")), level, name)
	end
end

local Happiness_Update = function(self, event, unit)
	if unit ~= self.unit or not HasPetUI() then return end

	local happiness = GetPetHappiness()
	local col
	if happiness then
		col = colors.happy[happiness]
	else
		col = colors.mp[UnitPowerType(unit)]
	end
	self.Power:SetStatusBarColor(unpack(col))
end

local durationTimer = function(self, elapsed)
	local id = self:GetID()
	local _, _, _, _, _, _, expirationTime = UnitAura(self.unit, self:GetID(), "HARMFUL")

	if expirationTime then
		self.duration:SetText(floor(expirationTime - GetTime() + 0.5))
	else
		return self:SetScript("OnUpdate", nil)
	end
end

local PostUpdateAuraIcon = function(self, icons, unit, icon, index, offset, filter, isDebuff)
	icon.unit = unit

	if isDebuff then
		name, rank, buffTexture, count, dtype, duration, timeLeft = UnitDebuff(unit, index, filter)
	else
		name, rank, buffTexture, count, duration, timeLeft = UnitBuff(unit, index, filter)
	end

	if isDebuff and timeLeft and timeLeft > 0 then
		icon:SetScript("OnUpdate", durationTimer)
		icon.duration:Show()
	else
		icon.duration:Hide()
	end

	if isDebuff then
		local col = DebuffTypeColor[dtype or "none"]
		icon.overlay:SetVertexColor(col.r, col.g, col.b)
	else
		icon.overlay:SetVertexColor(0.45, 0.45, 0.45)
	end
end

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")

	if(self.debuff) then
		GameTooltip:SetUnitDebuff(self.frame.unit, self:GetID(), self.parent.filter)
	else
		GameTooltip:SetUnitBuff(self.frame.unit, self:GetID(), self.parent.filter)
	end
end

local OnLeave = function()
	return GameTooltip:Hide()
end

local condom = setmetatable({}, {__index = function(self, key)
	return dummy
end})

local CreateAuraIcon = function(self, icons, index, isDebuff)
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
	button.debuff = isDebuff
	button.icon = icon
	button.overlay = skin
	button.count = count
	button.duration = duration

	button.cd = condom

	table.insert(icons, button)

	return button
end

local frame = function(settings, self, unit)
	self.menu = menu

	self:EnableMouse(true)

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks("anyup")

	self:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		insets = {left = -2, right = -2, top = -2, bottom = -2},
	})
	self:SetBackdropColor(0, 0, 0, 1)

	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetHeight(30)
	hp:SetWidth(width)
	hp:SetPoint("LEFT")
	hp:SetPoint("RIGHT")
	hp:SetPoint("TOP")
	hp:SetStatusBarTexture(texture)

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg:SetAlpha(0.3)

	local hval = hp:CreateFontString(nil, "OVERLAY")
	hval:SetPoint("TOP")
	hval:SetPoint("BOTTOM")
	hval:SetPoint("RIGHT", hp, "RIGHT", -10, 0)
	hval:SetFont(supernova, 10, "THINOUTLINE")
	hval:SetShadowColor(0,0,0,1)
	hval:SetShadowOffset(1, -1)
	hval:SetTextColor(1, 1, 1)
	hval:SetJustifyH("RIGHT")

	local per = hp:CreateFontString(nil, "OVERLAY")
	per:SetPoint("RIGHT", self, "RIGHT", -15, 0)
	per:SetPoint("CENTER")
	per:SetFont(supernova, 10, "THINOUTLINE")
	per:SetShadowColor(0,0,0,1)
	per:SetShadowOffset(1, -1)
	per:SetTextColor(1,1,1)
	per:SetJustifyH("RIGHT")

	hp.value = hval
	hp.bg = hpbg
	hp.per = per
	self.Health = hp
	self.OverrideUpdateHealth = Health_Update

	local mp = CreateFrame("StatusBar", nil, self)
	mp:SetHeight(5)
	mp:SetWidth(width)
	mp:SetPoint("TOP", hp, "BOTTOM")
	mp:SetPoint("LEFT", hp, "LEFT")
	mp:SetPoint("RIGHT", hp, "RIGHT")
	mp:SetStatusBarTexture(texture)

	local mpbg = mp:CreateTexture(nil, "BORDER")
	mpbg:SetAllPoints(mp)
	mpbg:SetTexture(texture)
	mpbg:SetAlpha(0.3)

	local pval = mp:CreateFontString(nil, "OVERLAY")
	pval:SetPoint("TOP", self, "BOTTOM", 0, -5)
	pval:SetPoint("LEFT", self, "LEFT")
	pval:SetFont(supernova, 10, "THINOUTLINE")
	pval:SetShadowColor(0, 0, 0, 1)
	pval:SetShadowOffset(1, -1)
	pval:SetTextColor(1, 1, 1)
	pval:SetJustifyH("RIGHT")

	mp.value = pval
	mp.bg = mpbg
	self.Power = mp
	self.OverrideUpdatePower = Power_Update

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", self, "LEFT", 14, 0)
	name:SetPoint("TOP", 0, -5)
	name:SetPoint("BOTTOM", 0, 5)
	name:SetPoint("RIGHT", hval, "LEFT")
	name:SetJustifyH("LEFT")
	name:SetFont(supernova, 10, "THINOUTLINE")
	name:SetShadowColor(0,0,0,1)
	name:SetShadowOffset(1, -1)
	name:SetTextColor(1,1,1,1)

	self.Name = name
	self.UNIT_NAME_UPDATE = Name_Update

	local ricon = self:CreateTexture(nil, "OVERLAY")
	ricon:SetPoint("LEFT", hp, "LEFT", 1, 0)
	ricon:SetHeight(16)
	ricon:SetWidth(16)

	self.RaidIcon = ricon
	self.RAID_TARGET_UPDATE = oUF.RAID_TARGET_UPDATE
	self:RegisterEvent("RAID_TARGET_UPDATE")

	if unit == "target" then
	end

	if unit == "target" or self:GetParent():GetName() == "oUF_Party" then
		if unit == "target" then
			local b = CreateFrame("Frame", nil, self)
			b:SetHeight(50)
			b:SetWidth(width)
			b:SetPoint("RIGHT")
			b:SetPoint("BOTTOM", self, "TOP", 0, 3)
			b.num = 2 * floor(width/25)
			b["growth-x"] = "LEFT"
			b["growth-y"] = "UP"
			b.size = 25
			b.initialAnchor = "BOTTOMRIGHT"
			self.Buffs = b
		end

		local d = CreateFrame("Frame", nil, self)
		d:SetHeight(height)
		d:SetWidth(6 * height)
		d:SetPoint("LEFT", self, "RIGHT", 3, 0)
		d.size = height
		d.initialAnchor = "BOTTOMLEFT"
		d.num = 6
		self.Debuffs = d

		self.CreateAuraIcon = CreateAuraIcon
		self.PostUpdateAuraIcon = PostUpdateAuraIcon
	end

	if unit == "targettarget" or unit == "pet" or unit == "focus" then
	--	pval:Hide()
	--	hval:Hide()
		hp:SetWidth(294 * 0.45)
		hp:SetHeight(27 * 0.8)
		mp:SetHeight(7 * 0.8)
	end

	if unit == "pet" then
		self.Happiness = false
		self.UNIT_HAPPINESS = Happiness_Update
	end

	if self:GetParent():GetName() == "oUF_Party" then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = 0.4
	end

	return self
end

local call_meta = {__call = frame}
local style = setmetatable({
	["initial-height"] = height,
	["initial-width"] = width,
}, call_meta)

local style_small = setmetatable({
	["initial-height"] = height*0.8,
	["initial-width"] = width*0.45,
}, call_meta)

oUF:RegisterStyle("Kanne2", style)
oUF:SetActiveStyle("Kanne2")

local player = oUF:Spawn("player")
player:SetPoint("RIGHT", UIParent, "CENTER", -5, -200)

local target = oUF:Spawn("target")
target:SetPoint("LEFT", UIParent, "CENTER", 5, -200)

local party = oUF:Spawn("header", "oUF_Party")
party:SetManyAttributes("showParty", true, "yOffset", -25)
party:SetPoint("LEFT", UIParent, "LEFT", 5, 0)
party:SetPoint("TOP", MinimapCluster, "BOTTOM", 0, -20)
party:Show()

oUF:RegisterStyle("Kanne2-tot", style_small)
oUF:SetActiveStyle("Kanne2-tot")

local tot = oUF:Spawn("targettarget")
tot:SetPoint("TOP", target, "BOTTOM", 0, -5)
tot:SetPoint("RIGHT", target, "RIGHT")

local pet = oUF:Spawn("pet")
pet:SetPoint("RIGHT", player, "RIGHT")
pet:SetPoint("TOP", player, "BOTTOM", 0, -5)

local focus = oUF:Spawn("focus")
focus:SetPoint("LEFT", player, "LEFT")
focus:SetPoint("BOTTOM", player, "TOP", 0, 5)
