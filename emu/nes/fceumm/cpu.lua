local ffi = require('ffi')


_G.emu.ffi_cpu = _G.emu.ffi_cpu or {}


local _cpu = _G.emu.ffi_cpu



-- x6502struct.h
ffi.cdef[[
    typedef struct {
        int32_t tcount;

		uint16_t pc;
		uint8_t a;
        uint8_t x;
        uint8_t y;
        uint8_t s;
        uint8_t p;

		uint8_t mooPI;
        uint8_t jammed;
        int32_t count;
        uint32_t IRQlow;
        uint8_t db;
    } ffi_cpu_t;


	typedef struct {
		int flags;

		uint8_t hooks[0x10000 / 8];
	} hook_t;


	typedef struct {
		uint16_t pc[1024];
		int pc_idx;
	} debug_t;


	typedef int (*run_fn)(int);
	typedef int (*rom_addr_fn)(int);
]]



-- inherit fast FFI pointer (avoid lookup), bypass env sandbox
local cpu_regs = safecast('uint8_t *', raw_cpu.regs)

_cpu.pc = safecast('uint16_t *', cpu_regs + safeoffset('ffi_cpu_t', 'pc'))
_cpu.a = safecast('uint8_t *', cpu_regs + safeoffset('ffi_cpu_t', 'a'))
_cpu.x = safecast('uint8_t *', cpu_regs + safeoffset('ffi_cpu_t', 'x'))
_cpu.y = safecast('uint8_t *', cpu_regs + safeoffset('ffi_cpu_t', 'y'))
_cpu.s = safecast('uint8_t *', cpu_regs + safeoffset('ffi_cpu_t', 's'))
_cpu.p = safecast('uint8_t *', cpu_regs + safeoffset('ffi_cpu_t', 'p'))
_cpu.cycles = safecast('int32_t *', cpu_regs + safeoffset('ffi_cpu_t', 'count'))


_cpu.run = safecast('run_fn', raw_cpu.run)
_cpu.rom_addr = safecast('rom_addr_fn', raw_cpu.rom_addr)


_cpu.hooks = safecast('hook_t *', raw_cpu.cpu_hooks)
_cpu.debug = safecast('debug_t *', raw_cpu.cpu_d)
