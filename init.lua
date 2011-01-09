local oUF = _G.oUF
if(not oUF) then return error("NO OUFZ?!") end

local parent, ns = ...
local layout = setmetatable({}, { __index = oUF })
ns.layout = layout
ns.powerBreak = {
	["targettarget"] = true,
	["focus"] = true,
	["pet"] = true,
}
