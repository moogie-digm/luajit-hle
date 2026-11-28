local ffi = require('ffi')


local _mem = emu.ffi_mem



-- cdata = JIT friendly  [avoid name collision with real name]
ffi.cdef[[
    typedef struct {
        uint8_t *_rom;
        uint8_t *_ram;
        uint8_t *_wram;
        uint8_t *_exram;
        uint8_t *_chr;
        uint8_t *_chrram;
    } t_mem;
]]



-- Wire up the Metatype
ffi.metatype("t_mem", {
    __index = function(self, key)
		if key == 'rom'		then	return self._rom		end
		if key == 'ram'		then	return self._ram		end

		if key == 'wram'	then	return self._wram		end
		if key == 'sram'	then	return self._wram		end

		if key == 'exram'	then	return self._exram		end

		if key == 'chr'		then	return self._chr		end
		if key == 'chrram'	then	return self._chrram		end
		if key == 'chr2'	then	return self._chrram		end
		if key == 'exchr'	then	return self._chrram		end


		error(string.format("mem: '%s' is not a valid property", tostring(key)), 2)
    end,
})



-- Hook up the pre-casted FFI pointers 
local s_mem = ffi.new("t_mem", {
	_rom		= _mem.rom,
	_ram		= _mem.ram,
	_wram		= _mem.wram,
	_exram		= _mem.exram,
	_chr		= _mem.chr,
	_chrram		= _mem.chrram,
})


emu.mem = s_mem




romcmp = function(addr, list)
	return memcmp(_mem.rom + addr, list)
end



ramcmp = function(addr, list)
	return memcmp(_mem.ram + addr, list)
end



wramcmp = function(addr, list)
	return memcmp(_mem.wram + addr, list)
end
