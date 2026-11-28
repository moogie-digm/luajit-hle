_G.emu = _G.emu or {}



include 'utils' {
	'aob',
	'state',
}



local system = {
	'nes',
	--'gbc',
	--'snes',
	--'n64',


	--'gg',
	--'sms',
	--'smd',


	--'psx',
}



for _, mod in ipairs(system) do
	incsrc(mod .. '._init')
end
