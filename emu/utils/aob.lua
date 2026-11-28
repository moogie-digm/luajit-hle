flatten_aob = function(list)
	local bytes = {}
	local offset = 0

	for i = 1, #list do
		local v = list[i]

		if type(v) == 'number' then
			bytes[#bytes + 1] = v

		elseif type(v) == 'string' then
			for token in v:gmatch('%S+') do
				-- anchor
				if token == '$' then
					offset = #bytes

				-- wildcard
				elseif token == '?' or token == '??' then
					bytes[#bytes + 1] = false

				-- hex
				else
					bytes[#bytes + 1] = tonumber(token, 16)
				end
			end
		end
	end

	return bytes, offset
end
