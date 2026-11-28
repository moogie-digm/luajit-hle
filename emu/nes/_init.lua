include 'utils' {
	'mapper',
	'patcher',
	'scanner',
}



-- bridge
incsrc('fceumm._init')



-- core
include '.' {
	'cpu',
	'memory',
	'ppu',


	'alias',
}
