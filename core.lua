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

local layout = ns.layout

-- Lets kill some things eh?
oUF.Tags = nil
oUF.TagEvents = nil
oUF.UnitlessTagEvents = nil
oUF.Tag = nil
oUF.Untag = nil

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
local _, playerClass = UnitClass("player")

local supernova = [[Interface\AddOns\layout_Kanne2\media\nokiafc22.ttf]]
local texture = [[Interface\AddOns\layout_Kanne2\media\HalV.tga]]
local apathy = [[Interface\AddOns\layout_Kanne2\media\Normal.tga]]

local dummy = function() end

do
	local update = function(self, event, unit)
		if(self.unit ~= unit) then return end
		if(self.OverideUpdateName) then
			self:OverideUpdateName(event, unit)
		else
			local name = UnitName(unit)
			self.Name:SetText(name)
		end
	end

	local enable = function(self, unit)
		if(self.Name) then
			self:RegisterEvent("UNIT_NAME_UPDATE", update)

			return true
		end
	end

	local disable = function(self)
		if(self.Name) then
			self:UnregisterEvent("UNIT_NAME_UPDATE")
		end
	end

	layout:AddElement("Name", update, enable, disable)
end

local colors = {
	mp = setmetatable({
		[0] = { 48/255, 113/255,191/255 }, -- Mana
		[1] = { 226/255, 45/255, 75/255 }, -- Rage
		[2] = { 255/255, 178/255, 0 }, -- Focus
		[3] = { 1, 1, 34/255 }, -- Energy
		[4] = { 0, 1, 1 }, -- Happiness
		[5] = { 0.5, 0.5, 0.5 },
		[6] = { 0, 0.82, 1 }
	}, { __index = PowerBarColor }),
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


local toHex = function(r, g, b)
	return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
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

local Combo_Update = function(self, event, unit)
	if(unit ~= "player" and self.unit ~= "target") then return end

	local c = GetComboPoints(unit, "target")

	if(c == 0) then
		c = self._level
	end

	self.Name:SetFormattedText(format.all.name, toHex(unpack(self._color)), c, self._name)
end

local Holy_Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'HOLY_POWER')) then return end

	local hp = self.HolyPower
	local min = UnitPower('player', SPELL_POWER_HOLY_POWER)
	hp:SetValue(min)
end

local Eclipse_Update = function(self, unit)
	local val = UnitPower("player", SPELL_POWER_ECLIPSE)
	self:SetValue(math.abs(val))

	local col = colors.mp.eclipse[val > 0 and "positive" or "negative"]
	self:SetStatusBarColor(col.r, col.g, col.b)
	self.bg:SetVertexColor(col.r, col.g, col.b)
end

local frame = function(self, unit, single)
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

	hp.PostUpdate = self.Health_Update

	self.Health = hp

	local pred = hp:CreateTexture(nil, "OVERLAY")
	pred:SetPoint("TOP", hp)
	pred:SetPoint("BOTTOM", hp)
	pred:SetHeight(30)
	pred:SetWidth(0)
	pred:SetTexture(texture)
	pred:SetVertexColor(0, 1, 0, 0.8)
	pred:Hide()

	pred.Override = self.Heal_Update

	self.HealPrediction = pred

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
	mp.PostUpdate = Power_Update

	self.Power = mp

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", self, "LEFT", 20, 0)
	name:SetPoint("TOP", 0, -5)
	name:SetPoint("BOTTOM", 0, 5)
	name:SetPoint("RIGHT", hval, "LEFT")
	name:SetJustifyH("LEFT")
	name:SetFont(supernova, 10, "THINOUTLINE")
	name:SetShadowColor(0,0,0,1)
	name:SetShadowOffset(1, -1)
	name:SetTextColor(1,1,1,1)

	self.OverideUpdateName = Name_Update

	self.Name = name
	self.UNIT_LEVEL = Name_Update
	self:RegisterEvent("UNIT_LEVEL")

	local ricon = hp:CreateTexture(nil, "OVERLAY")
	ricon:SetPoint("LEFT", hp, "LEFT", 1, 0)
	ricon:SetHeight(16)
	ricon:SetWidth(16)

	self.RaidIcon = ricon

	if(single) then
		if(powerBreak[unit]) then
			self:SetSize(width * 0.45, height * 0.8)
			hp:SetWidth(width * 0.45)
			hp:SetHeight(27 * 0.8)
			mp:SetHeight(7 * 0.8)
		else
			self:SetSize(width, height)
		end
	end

	if unit == "target" or not unit then
		if unit == "target" then
			if(playerClass == "ROGUE") then
				self.UNIT_COMBO_POINTS = Combo_Update
				self:RegisterEvent("UNIT_COMBO_POINTS")
			end

			local b = CreateFrame("Frame", nil, self)
			b:SetHeight(50)
			b:SetWidth(width)
			b:SetPoint("RIGHT")
			-- They now go under the TOT
			b:SetPoint("TOP", self, "BOTTOM", 0, - 13)
			b.num = 2 * floor(width/25)
			b["growth-x"] = "LEFT"
			b["growth-y"] = "DOWN"
			b.size = 25
			b.initialAnchor = "BOTTOMRIGHT"
			self.Buffs = b

			b.unit = unit
			b.CreateIcon = CreateAuraIcon
			b.PostUpdateIcon = PostUpdateAuraIcon
		end

		local d = CreateFrame("Frame", nil, self)
		d:SetHeight(height)
		d:SetWidth(6 * height)
		d:SetPoint("LEFT", self, "RIGHT", 3, 0)
		d.size = height
		d.initialAnchor = "BOTTOMLEFT"
		d.num = 6
		self.Debuffs = d

		d.unit = unit
		d.CreateIcon = CreateAuraIcon
		d.PostUpdateIcon = PostUpdateAuraIcon
		--self.PreAuraSetPosition = PreAuraSetPosition
	end

	if(unit == "player") then
		if(playerClass == "PALADIN") then
			local holy = CreateFrame("StatusBar", nil, self)
			--holy:SetWidth(width)
			holy:SetHeight(3)
			holy:SetPoint("BOTTOM", self, "TOP")
			holy:SetPoint("LEFT", self, "LEFT")
			holy:SetPoint("RIGHT", self, "RIGHT")
			holy:SetStatusBarTexture(texture)
			local col = colors.mp[9]
			holy:SetStatusBarColor(col.r, col.g, col.b)
			holy:SetMinMaxValues(0, MAX_HOLY_POWER)

			local hobg = holy:CreateTexture(nil, "BORDER")
			hobg:SetAllPoints(holy)
			hobg:SetTexture(texture)
			hobg:SetVertexColor(col.r, col.g, col.b, 0.3)

			holy.bg = hobg
			holy.Override = Holy_Update

			self.HolyPower = holy
		elseif(class == "DRUID") then
			local eclipse = CreateFrame("StatusBar", nil, self)
			eclipse:SetHeight(3)
			eclipse:SetStatusBarTexture(texture)
			eclipse:SetPoint("BOTTOM", self, "TOP")
			eclipse:SetPoint("RIGHT", self, "RIGHT")
			eclipse:SetPoint("LEFT", self, "LEFT")

			eclipse.PostUpdatePower = Eclipse_Update
			eclipse.PostUpdateVisibility = Eclipse_Update
			eclipse.PostDirectionChange = Eclipse_Update

			local ebg = eclipse:CreateTexture(nil, "BORDER")
			ebg:SetAllPoints(eclipse)
			ebg:SetTexture(texture)
			ebg:SetAlpha(0.3)

			eclipse.bg = ebg
			self.EclipseBar = eclipse
		end
	end

	--[[
	if unit == "pet" or unit == "targettarget" then
		local b = CreateFrame("Frame", nil, self)
		b:SetHeight(25)
		b:SetWidth(294 * 0.45)
		b:SetPoint("TOP", self, "BOTTOM", 0, - 3)
		b.size = 22
		b["growth-x"] = unit == "pet" and "LEFT" or "RIGHT"
		b.num = 5
		self.Buffs = b

		local d = CreateFrame("Frame", nil, self)
		d:SetHeight(25)
		d:SetWidth(294 * 0.45)
		d:SetPoint("TOP")
		d.size = 25
		d["growth-x"] = unit == "pet" and "LEFT" or "RIGHT"
		d.num = 5
		self.Debuffs = d

		if unit == "targettarget" then
			b.initialAnchor = "TOPLEFT"
			d.initialAnchor = "TOPLEFT"
			b:SetPoint("LEFT", self, "LEFT", 3, 0)
			d:SetPoint("LEFT", self, "RIGHT", 3, 0)
		else
			b.initialAnchor = "TOPRIGHT"
			d.initialAnchor = "TOPRIGHT"
			b:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			d:SetPoint("RIGHT", self, "LEFT", 0, 0)
		end
	end
	]]

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = 0.4
	end

	--self.Heal = true

	return self
end


layout:Factory(function(self)
	--[[
	local call_meta = { __call = frame }
	local style = setmetatable({
		["initial-height"] = height,
		["initial-width"] = width,
	}, call_meta)

	local style_small = setmetatable({
		["initial-height"] = height * 0.8,
		["initial-width"] = width * 0.45,
	}, call_meta)
	]]

	layout:RegisterStyle("Kanne2", frame)
	layout:SetActiveStyle("Kanne2")

	for i = 1, 5 do
		layout:DisableBlizzard("boss" .. i)
	end

	local player = layout:Spawn("player")
	player:SetPoint("RIGHT", UIParent, "CENTER", - 50, - 175)

	local target = layout:Spawn("target")
	target:SetPoint("LEFT", UIParent, "CENTER", 50, - 175)

	local party = layout:SpawnHeader(nil, nil, "raid,party,solo", "showParty", true, "yOffset", -25,
		"oUF-initialConfigFunction", string.format([[
		self:SetHeight(%d)
		self:SetWidth(%d)
		]], height, width)
	)
	party:SetPoint("LEFT", UIParent, "LEFT", 5, 0)
	party:SetPoint("TOP", MinimapCluster, "BOTTOM", 0, -20)
	party:Show()

	local tot = layout:Spawn("targettarget")
	tot:SetPoint("TOP", target, "BOTTOM", 0, -5)
	tot:SetPoint("RIGHT", target, "RIGHT")

	local pet = layout:Spawn("pet")
	pet:SetPoint("RIGHT", player, "RIGHT")
	pet:SetPoint("TOP", player, "BOTTOM", 0, -5)

	local focus = layout:Spawn("focus")
	focus:SetPoint("LEFT", player, "LEFT")
	focus:SetPoint("BOTTOM", player, "TOP", 0, 5)
end)

