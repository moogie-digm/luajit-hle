local ffi = require('ffi')


_G.emu.ffi_ppu = _G.emu.ffi_ppu or {}


local _ppu = _G.emu.ffi_ppu
local _mem = _G.emu.ffi_mem



ffi.cdef[[
	typedef int (*getcycle_fn)();
	typedef int (*getscanline_fn)();
]]



-- inherit fast FFI pointer (avoid lookup), bypass env sandbox
_ppu.vram_addr = safecast('uint32_t *', raw_ppu.refreshaddr)
_ppu.temp_addr = safecast('uint32_t *', raw_ppu.tempaddr)
_ppu.fine_x = safecast('uint8_t *', raw_ppu.xofs)
_ppu.write_latch = safecast('uint8_t *', raw_ppu.vtoggle)


_ppu.regs = safecast('uint8_t *', raw_ppu.regs)
_ppu.pal_ram = safecast('uint8_t *', raw_ppu.palram)
_ppu.spr_ram = safecast('uint8_t *', raw_ppu.spram)



local name_page = safecast('uint8_t **', raw_ppu.ntpage)


local chr_page = safecast('uint8_t **', raw_ppu.chrpage)
local chr_pagesize = 0x400		-- 8 pages
local chr_pagemask = chr_pagesize - 1


_ppu.get_cycle = safecast('getcycle_fn', raw_ppu.getcycle)
_ppu.get_scanline = safecast('getscanline_fn', raw_ppu.getscanline)



_ppu.get_chrpage = function(addr)
	if addr < 8 then
		addr *= chr_pagesize
	end

	return chr_page[addr / chr_pagesize] + addr		-- undo relative offset
end



_ppu.set_chrpage = function(addr, ptr)
	if addr < 8 then
		addr *= chr_pagesize
	end

	chr_page[addr / chr_pagesize] = ptr - (addr & ~chr_pagemask)		-- apply relative offset
end



_ppu.chr_bank = function(addr)
	local ptr = _ppu.get_chrpage(addr) - _mem.chr

	return (ptr >= 0 and ptr < _mem.chrsize[0]) ? ptr / chr_pagesize : -1
end
