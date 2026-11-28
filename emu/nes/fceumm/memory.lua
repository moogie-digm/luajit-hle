local ffi = require('ffi')


_G.emu.ffi_mem = _G.emu.ffi_mem or {}


local _mem = _G.emu.ffi_mem



ffi.cdef[[
	typedef int (*read_fn)(int);
	typedef void (*write_fn)(int, int);
]]



_mem.rom = safecast('uint8_t *', raw_memory.rom)
_mem.ram = safecast('uint8_t *', raw_memory.ram)

_mem.wram = safecast('uint8_t *', raw_memory.wram)
_mem.exram = safecast('uint8_t *', raw_memory.exram)


_mem.chr = safecast('uint8_t *', raw_memory.chr)
_mem.chrram = safecast('uint8_t *', raw_memory.chrram)


_mem.chrsize = safecast('uint32_t *', raw_memory.chrsize)
_mem.chrramsize = safecast('uint32_t *', raw_memory.chrramsize)


_mem.read = safecast('read_fn *', raw_memory.read)
_mem.write = safecast('write_fn *', raw_memory.write)
