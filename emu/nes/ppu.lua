local ffi = require('ffi')



-- #########################
-- precache
-- #########################

local _ppu = emu.ffi_ppu


local _get_cycle = _ppu.get_cycle
local _get_scanline = _ppu.get_scanline


local _get_chrbank = _ppu.chr_bank
local _get_chrpage = _ppu.get_chrpage
local _set_chrpage = _ppu.set_chrpage



-- #########################
-- helpers
-- #########################



local _get_hblank = function()
	return _get_cycle() >= 257
end



local _get_vblank = function()
	return _get_scanline() >= 240
end



local _write_scroll = function(coarse_x, fine_x, coarse_y, fine_y, nametable)
	coarse_x &= 31
	coarse_y %= 31
	fine_x &= 7
	fine_y &= 7
	nametable &= 3


	cpu.read(0x2002)	-- reset latch

	cpu.write(0x2006, nametable << 2)
	cpu.write(0x2005, (coarse_y << 3) | fine_y)
	cpu.write(0x2005, fine_x)
	cpu.write(0x2006, (coarse_y << 5) | coarse_x)
end



local _sprite_dma = function(addr, size)
	addr = addr or ram + 0x200
	size = size or 256


	cpu.write(0x2003, 0)


	-- skip normal dma register = adds cpu cycles
	-- plus flag dirty sprites
	for i = 0, size-1 do
		cpu.write(0x2004, addr[i])
	end
end



-- cdata = avoid name collision with real name
ffi.cdef[[
    typedef struct {
		uint32_t *_vram_addr;
		uint32_t *_temp_addr;
		uint8_t *_fine_x;
		uint8_t *_write_latch;
		uint8_t *_regs;
		uint8_t *_palram;
		uint8_t *_sprram;
    } t_ppu;
]]



-- Wire up the Metatype
ffi.metatype("t_ppu", {
    __index = function(self, key)
    	if key == 'vram_addr'	then	return self._vram_addr[0]		end
		if key == 'vaddr'		then	return self._vram_addr[0]		end
		if key == 'v'			then	return self._vram_addr[0]		end
    
		if key == 'temp_addr'	then	return self._temp_addr[0]		end
		if key == 'taddr'		then	return self._temp_addr[0]		end
		if key == 't'			then	return self._temp_addr[0]		end
    
		if key == 'fine_x'		then	return self._fine_x[0]		end
		if key == 'x'			then	return self._fine_x[0]		end
    
		if key == 'write_latch'	then	return self._write_latch[0]	end
		if key == 'latch'		then	return self._write_latch[0]	end
		if key == 'w'			then	return self._write_latch[0]	end
    
		if key == 'control'		then	return self._regs[0]		end
		if key == 'ctrl'		then	return self._regs[0]		end

		if key == 'mask'		then	return self._regs[1]		end

		if key == 'status'		then	return self._regs[2]		end
		if key == 'stat'		then	return self._regs[2]		end

		if key == 'oam_addr'	then	return self._regs[3]		end

		if key == 'pal'			then	return self._palram		end
		if key == 'palram'		then	return self._palram		end

		if key == 'spr'			then	return self._sprram		end
		if key == 'sprram'		then	return self._sprram		end

		if key == 'cycle'		then	return _get_cycle()		end
		if key == 'scanline'	then	return _get_scanline()	end

		if key == 'hblank'		then	return _get_hblank()	end
		if key == 'vblank'		then	return _get_vblank()	end

		if key == 'write_scroll'	then	return _write_scroll	end

		if key == 'chrbank'			then	return _get_chrbank		end
		if key == 'get_chrpage'		then	return _get_chrpage		end
		if key == 'set_chrpage'		then	return _set_chrpage		end


		if key == 'dma'			then	return _sprite_dma		end


		error(string.format("ppu_r: '%s' is not a valid property", tostring(key)), 2)
    end,


    __newindex = function(self, key, val)
		if key == 'vram_addr'	then	self._vram_addr[0] = val		return end
		if key == 'vaddr'		then	self._vram_addr[0] = val		return end
		if key == 'v'			then	self._vram_addr[0] = val		return end
		
		if key == 'temp_addr'	then	self._temp_addr[0] = val		return end
		if key == 'taddr'		then	self._temp_addr[0] = val		return end
		if key == 't'			then	self._temp_addr[0] = val		return end

		if key == 'fine_x'		then	self._fine_x[0] = val	return end
		if key == 'x'			then	self._fine_x[0] = val	return end

		if key == 'write_latch'	then	self._write_latch[0] = val	return end
		if key == 'latch'		then	self._write_latch[0] = val	return end
		if key == 'w' 			then	self._write_latch[0] = val	return end
	
		if key == 'control'		then	self._regs[0] = val		return end
		if key == 'ctrl'		then	self._regs[0] = val		return end

		if key == 'mask'		then	self._regs[1] = val		return end

		if key == 'status'		then	self._regs[2] = val		return end
		if key == 'stat'		then	self._regs[2] = val		return end

		if key == 'oam_addr'	then	self._regs[3] = val		return end


		error(string.format("ppu_w: '%s' is not a valid property", tostring(key)), 2)
    end
})



-- Hook up the pre-casted FFI pointers 
local s_ppu = ffi.new("t_ppu", {
	_vram_addr		= _ppu.vram_addr,
	_temp_addr		= _ppu.temp_addr,
	_fine_x			= _ppu.fine_x,
	_write_latch	= _ppu.write_latch,
	_regs			= _ppu.regs,
	_palram			= _ppu.pal_ram,
	_sprram			= _ppu.spr_ram,
})



_G.emu.ppu = s_ppu
