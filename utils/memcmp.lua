function memcmp(addr, list)
	for i = 0, #list-1 do
		local v = list[i+1]

		if type(v) == "number" and addr[i] ~= v then
			return false
		end
	end

	return true
end
