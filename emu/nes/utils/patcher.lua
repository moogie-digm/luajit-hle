--[[
local patch = {

	-- 5:8235	ScrollWorldDownOrH - [SBC #$08] - STA ObjY
	-- E9 08 85 84 A5 E2 18
	{ 0x14235, 0xE9, 0x04 },	-- scroll down, player sprite up 1/2 tick


	-- 5:81F9	ScrollWorld[Up] - [ADC #$08] - STA ObjY
	-- 69 08 85 84 A5 E2 38
	{ 0x141F9, 0x69, 0x04 },	-- scroll up, player sprite down 1/2 tick


	-- 5:8497	UpdateMode7Scroll_Sub2 - [ADC #$01] - AND #$03
	-- 69 01 29 03 A4 10
	{ 0x14497, 0x69, 0x00 },	-- starting fractional frame # = current  [full vscroll tick]
}


rom_patch(patch)
--]]



rom_patch = function(patches)
	--local patches = tables[ rom_version ]

	if not patches then return end


	-- handle multiple items
	for i = 1, #patches do
		local list = flatten_aob(patches[i])
		local addr = list[1]


		-- byte sequence
		for b = 2, #list do
			local v = list[b]


			-- not wildcard
			if type(v) == 'number' then
				local offset = b - 2

				rom[addr + offset] = v
			end
		end
	end
end
