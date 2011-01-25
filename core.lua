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

local parent, ns = ...
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

local supernova = [[Interface\AddOns\Kanne2\media\nokiafc22.ttf]]
local texture = [[Interface\AddOns\Kanne2\media\HalV.tga]]
local apathy = [[Interface\AddOns\Kanne2\media\Normal.tga]]

local dummy = function() end

local powerBreak = ns.powerBreak
local colors = ns.colors
local format = ns.format

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
	-- TODO: Override
	mp.PostUpdate = self.Power_Update

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

	name.Override = self.Name_Update

	self.Name = name
	self:RegisterEvent("UNIT_LEVEL", self.Name_Update)

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
			if(self.Combo_Update) then
				self:RegisterEvent("UNIT_COMBO_POINTS", self.Combo_Update)
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
		if(self.Holy_Update) then
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
			holy.Override = self.Holy_Update

			self.HolyPower = holy
		elseif(self.Eclipse_Update) then
			local eclipse = CreateFrame("StatusBar", nil, self)
			eclipse:SetHeight(3)
			eclipse:SetStatusBarTexture(texture)
			eclipse:SetPoint("BOTTOM", self, "TOP")
			eclipse:SetPoint("RIGHT", self, "RIGHT")
			eclipse:SetPoint("LEFT", self, "LEFT")

			eclipse.PostUpdatePower = self.Eclipse_Update
			eclipse.PostUpdateVisibility = self.Eclipse_Update
			eclipse.PostDirectionChange = self.Eclipse_Update

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

