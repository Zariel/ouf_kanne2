local oUF = _G.oUF
if(not oUF) then return error("NO OUFZ?!") end

local parent, ns = ...
ns.layout = setmetatable({}, { __index = oUF })
ns.powerBreak = {
	["targettarget"] = true,
	["focus"] = true,
	["pet"] = true,
}

ns.colors = {
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

setmetatable(ns.colors.class, {
	__index = function(self, key)
		return self.WARRIOR
	end
})

ns.format = setmetatable({
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

for k, v in pairs(ns.format) do
	if k ~= "all" then
		k = setmetatable(v, {
			__index = function(self, key)
				return ns.format.all[key]
			end,
		})
	end
end

function ns:ToHex(r, g, b)
	return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

ns.nokia22 = [[Interface\AddOns\oUF_Kanne2\media\nokiafc22.ttf]]
ns.halV = [[Interface\AddOns\oUF_Kanne2\media\HalV.tga]]
ns.apathy = [[Interface\AddOns\oUF_Kanne2\media\Normal.tga]]

ns.height = 35
ns.width = 250
