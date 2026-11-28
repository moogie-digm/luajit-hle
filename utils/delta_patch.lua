delta_hooks = function(base, delta)
	local out = {}

	for k, v in pairs(base) do
		if type(v) == 'number' then
			out[k] = v + delta
		else
			out[k] = v
		end
	end

	return out
end



delta_patch = function(base, delta)
	local out = {}

	for i, entry in ipairs(base) do
		-- Create a new entry with the shifted address at index 1
		local new_entry = { entry[1] + delta }

		-- Copy the remaining bytes unchanged
		for j = 2, #entry do
			new_entry[j] = entry[j]
		end

		out[i] = new_entry
	end

	return out
end



aob_scan = function(mem, list, start, stop)
	for i = start, stop do
		for j = 1, #list do
			-- not wildcard
			if type(list[i]) == 'number' then
				if mem[i+j-1] != list[j] then break end
			end

			if j == #list then
				return true, i - start
			end
		end
	end
	
	return false, 0
end
