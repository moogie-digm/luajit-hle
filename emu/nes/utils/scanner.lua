local match_at = function(data, pos, pattern, len)
	for j = 1, len do
		local expected = pattern[j]

		if type(expected) == 'number' and data[pos + j - 1] != expected then
			return false
		end
	end

	return true
end



local aob_scan = function(data, addr, list, mask)
	local pattern, offset = flatten_aob(list)
	local len = #pattern


	local start = addr & ~mask
	local stop = start + mask - len + 1
	local found = nil



	if match_at(data, addr, pattern, len) then
		found = addr
	else
		for i = start, stop do
			if match_at(data, i, pattern, len) then 
				found = i
				break
			end
		end
	end


	return found, offset, pattern
end



rom_patch4 = function(addr, list, patch, name)
	name = name or nil


	local mask = 0x3fff
	local found, offset, pattern = aob_scan(rom, addr, list, mask)


	if found != nil then
		local _addr = found + offset
		local _patch = { patch }


		if name then
			printf('rom_patch4 %s  rom=%x', name, _addr)
		end


		table.insert(patch, 1, _addr)		-- patch addr


		return rom_patch(_patch)
	end


	return nil
end



rom_hook4 = function(pc, addr, list, name)
	name = name or nil


	local mask = 0x3fff
	local found, offset, pattern = aob_scan(rom, addr, list, mask)


	if found != nil then
		local base = pc & ~mask


		local _pc = (found & mask) + base + offset
		local _addr = found + offset


		if name then
			printf('rom_hook4 %s  rom=%x  pc=%x  addr=%x', name, found, _pc, _addr)
		end


		return {
			pc = _pc,
			addr = _addr,
			aob = pattern,
		}
	end


	return nil
end



wram_hook2 = function(pc, list, name)
	name = name or nil


	local mask = 0x1fff
	local addr = pc & mask
	local found, offset, pattern = aob_scan(wram, addr, list, mask)


	if found != nil then
		local base = pc & ~mask


		local _pc = (found & mask) + base + offset
		local _addr = found


		if name then
			printf('wram_hook2 %s  wram=%x  pc=%x  addr=%x', name, found, _pc, _addr)
		end


		return {
			pc = _pc,
			addr = _addr,
			aob = pattern,
		}
	end


	return nil
end
