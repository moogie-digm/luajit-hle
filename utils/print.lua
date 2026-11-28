local ffi = require('ffi')


local u64 = ffi.typeof('uint64_t')



hex64 = function(val)
    return ('%X'):format(ffi.cast(u64, val))
end



hexstr = function(val, width)
    -- Ensure floats or bad inputs don't crash Lua 5.3+
    local num = tonumber(val) or 0
    local fmt = width and string.format("%%0%02dX", width) or "%X"

    return string.format(fmt, num)
end



hexrow = function(cdata, rows, width)
	for i = 1, rows*width, width do
		local row = {}
		for j = i, i+width-1 do
			table.insert(row, string.format("%02X", cdata[j-1]))
		end
		print(table.concat(row, " "))
	end
end



printf = function(fmt, ...)
    print(fmt:format(...))
end
