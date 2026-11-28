local ffi = require("ffi")


local wrapper_cache = {}


function bind_scalar(light_ud, c_type, prop_name)
    -- Default to "value" if no name is provided
    prop_name = prop_name or "value"
    
    -- Create a unique cache key for this type + property combination
    local cache_key = c_type .. "_" .. prop_name
    local wrapper_t = wrapper_cache[cache_key]
    
    if not wrapper_t then
		-- Add the '*' to the type definition so the struct stores a pointer
        local struct_def = string.format("struct { %s *ptr; }", c_type)
        
        -- We dynamically generate the exact string comparison inside the code block
        local mt = {
            __index = function(self, key)
                if key == prop_name then
                    return self.ptr[0]
                end
                error("Invalid property read: " .. tostring(key))
            end,
            
            __newindex = function(self, key, val)
                if key == prop_name then
                    self.ptr[0] = val
                    return
                end
                error("Invalid property write: " .. tostring(key))
            end
        }
        
        wrapper_t = ffi.metatype(struct_def, mt)
        wrapper_cache[cache_key] = wrapper_t
    end
    
    return wrapper_t(light_ud)
end


--[[
function bind_scalar(light_ud, c_type)
    local ptr = ffi.cast(c_type .. "*", light_ud)
    
    return {
        get = function() return ptr[0] end,
        set = function(val) ptr[0] = val end
    }
end


_G.emu.ppu.scanline = bind_scalar(emu.ppu_scanline, "int")

-- Read and Write
_G.emu.ppu.scanline.set(0)
local current = _G.emu.ppu.scanline.get()
--]]