local ffi = require("ffi")



function safecast(type, name)
	if name == nil then
		error('safecast - invalid name', 2)
	end


	return ffi.cast(type, name)


	-- warn: throw error here if invalid will hard crash system
end



function safeoffset(type, name)
	if name == nil then
		error('safeoffset - invalid name - nil', 2)
	end


	-- Create a zero-cost reference to test field indexing
	local success, _ = pcall(function()
		return ffi.new(type)[name]
	end)

	if not success then
		error('safeoffset - invalid name - ' .. tostring(name), 2)
	end


	return ffi.offsetof(type, name)


	-- warn: throw error here if invalid will hard crash system
end
