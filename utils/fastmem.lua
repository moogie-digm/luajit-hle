local ffi = require("ffi")



memcpy = function(dst, src, len)
	return ffi.copy(dst, src, len)
end



memset = function(dst, c, len)
	return ffi.fill(dst, len, c)
end



memnew = function(type)
	return ffi.new(type)
end



local type_cache = {}


malloc = function(ctype_str, tbl)
    local ctype = type_cache[ctype_str]

    if not ctype then
        ctype = ffi.typeof(ctype_str .. '[?]')
        type_cache[ctype_str] = ctype
    end

    return ctype(#tbl, tbl)
end



malloc_u8 = function(tbl) return malloc('uint8_t', tbl) end
malloc_u16 = function(tbl) return malloc('uint16_t', tbl) end
malloc_u32 = function(tbl) return malloc('uint32_t', tbl) end
malloc_u64 = function(tbl) return malloc('uint64_t', tbl) end



UINT8 = function(tbl) return malloc_u8(tbl) end
UINT16 = function(tbl) return malloc_u16(tbl) end
UINT32 = function(tbl) return malloc_u32(tbl) end
UINT64 = function(tbl) return malloc_u64(tbl) end



local uint16_ptr = ffi.typeof("uint16_t *")
local uint32_ptr = ffi.typeof("uint32_t *")


READ16 = function(ptr) return ffi.cast(uint16_ptr, ptr)[0] end
READ32 = function(ptr) return ffi.cast(uint32_ptr, ptr)[0] end
