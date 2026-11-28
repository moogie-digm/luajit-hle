local ffi = require('ffi')


local ADDR_MAX = 0x10000



-- #########################
-- precache
-- #########################


local _cpu = emu.ffi_cpu
local _mem = emu.ffi_mem


local _read_mem = _mem.read
local _write_mem = _mem.write


local _hooks = _cpu.hooks
local _trace = _cpu.debug


local _rom_addr = _cpu.rom_addr
local _cpu_run = _cpu.run




-- #########################
-- globals
-- #########################


local HOOK_PC = 1
local HOOK_READ = 2
local HOOK_WRITE = 4


local CPU_WAIT = 0x100		-- 1-cycle nop
local CPU_FAST = 0x200		-- 0-cycle time
local CPU_SKIP = 0x400		-- skip opcode




-- #########################
-- helpers
-- #########################


local _read_cpu = function(addr)
	return _read_mem[addr](addr)
end



local _write_cpu = function(addr, val)
	_write_mem[addr](addr, val)
end






-- stall cpu 1-time
local _wait_cpu = function()
	_hooks.flags |= CPU_WAIT
end



-- fast cpu; no cycles
local _fast_cpu = function(value)
	_FAST_CPU = value or 0
end



-- ignore opcode
local _skip_cpu = function(value)
	value = value or 0

	cpu.pc += value

	_hooks.flags |= CPU_SKIP
end



local _jsr_cpu = function(call_pc, ret_pc)
	ret_pc = ret_pc - 1		-- rts + 1


	ram[ 0x100 + cpu.s ] = ret_pc >> 8		-- high byte
	cpu.s = cpu.s - 1	-- boundary wrap

	ram[ 0x100 + cpu.s ] = ret_pc	-- low byte
	cpu.s = cpu.s - 1


	cpu.pc = call_pc	-- start next

	_skip_cpu()
end



local _rts_cpu = function()	
	local ret_pc = 0


	cpu.s = cpu.s + 1
	ret_pc = ram[ 0x100 + cpu.s ]	-- low byte


	cpu.s = cpu.s + 1
	ret_pc += ram[ 0x100 + cpu.s ] << 8		-- high byte


	cpu.pc = ret_pc + 1		-- start next

	_skip_cpu()
end



local _jmp_cpu = function(new_pc)
	cpu.pc = new_pc		-- start next

	_skip_cpu()
end



local _ld_flags = function(value)
	cpu.zf = (value == 0)
	cpu.nf = (value >= 128) or (value < 0)		-- signed 8-bit
end



local _lda_cpu = function(value)
	cpu.a = value

	_ld_flags(value)
end



local _ldx_cpu = function(value)	
	cpu.x = value

	_ld_flags(value)
end



local _ldy_cpu = function(value)
	cpu.y = value

	_ld_flags(value)
end




-- cdata = JIT friendly  [avoid name collision with real name]
ffi.cdef[[
    typedef union {
        struct {
            uint8_t c : 1;		// carry
            uint8_t z : 1;		// zero
            uint8_t i : 1;		// interrupt
            uint8_t d : 1;		// decimal
            uint8_t b : 1;		// break
            uint8_t u : 1;		// unused
            uint8_t v : 1;		// overflow
            uint8_t n : 1;		// negative
        };
        uint8_t reg;
    } emu_cpu_flags_t;


    typedef struct {
		uint16_t *_pc;
		uint8_t *_a;
        uint8_t *_x;
        uint8_t *_y;
        uint8_t *_s;
        emu_cpu_flags_t *_p;
		int32_t *_cycles;
    } emu_cpu_t;
]]



-- Let LuaJIT compile into array natively
ffi.metatype("emu_cpu_t", {
    __index = function(self, key)
		if key == 'pc'		then	return self._pc[0]	end
		if key == 'a'		then	return self._a[0]	end
		if key == 'x'		then	return self._x[0]	end
		if key == 'y'		then	return self._y[0]	end

		if key == 's'		then	return self._s[0]	end
		if key == 'sp'		then	return self._s[0]	end

		if key == 'p'		then	return self._p[0]	end
		if key == 'sr'		then	return self._p[0]	end

		if key == 'cycles'	then	return self._cycles[0]	end

		if key == 'cf'		then	return self._p[0].c		end
		if key == 'zf'		then	return self._p[0].z		end
		if key == 'if'		then	return self._p[0].i		end
		if key == 'df'		then	return self._p[0].d		end
		if key == 'vf'		then	return self._p[0].v		end
		if key == 'of'		then	return self._p[0].v		end
		if key == 'nf'		then	return self._p[0].n		end
		if key == 'sf'		then	return self._p[0].n		end


		if key == 'read'	then	return _read_cpu	end
		if key == 'write'	then	return _write_cpu	end

		if key == 'wait'	then	return _wait_cpu	end
		if key == 'fast'	then	return _fast_cpu	end
		if key == 'skip'	then	return _skip_cpu	end

		if key == 'call'	then	return _jsr_cpu		end

		if key == 'jsr'		then	return _jsr_cpu		end
		if key == 'jmp'		then	return _jmp_cpu		end
		if key == 'rts'		then	return _rts_cpu		end

		if key == 'lda'		then	return _lda_cpu		end
		if key == 'ldx'		then	return _ldx_cpu		end
		if key == 'ldy'		then	return _ldy_cpu		end


		error(string.format("cpu_r: '%s' is not a valid property", tostring(key)), 2)
    end,


    __newindex = function(self, key, val)
		if key == 'pc'		then	self._pc[0] = val	return end
		if key == 'a'		then	self._a[0] = val	return end
		if key == 'x'		then	self._x[0] = val	return end
		if key == 'y'		then	self._y[0] = val	return end

		if key == 's'		then	self._s[0] = val	return end
		if key == 'sp'		then	self._s[0] = val	return end

		if key == 'p'		then	self._p[0] = val	return end
		if key == 'sr'		then	self._p[0] = val	return end

		if key == 'cf'		then	self._p[0].c = val		return end
		if key == 'zf'		then	self._p[0].z = val		return end
		if key == 'if'		then	self._p[0].i = val		return end
		if key == 'df'		then	self._p[0].d = val		return end
		if key == 'vf'		then	self._p[0].v = val		return end
		if key == 'of'		then	self._p[0].v = val		return end
		if key == 'nf'		then	self._p[0].n = val		return end
		if key == 'sf'		then	self._p[0].n = val		return end


		error(string.format("cpu_w: '%s' is not a valid property", tostring(key)), 2)
    end
})



-- Hook up the pre-casted FFI pointers 
local cpu_s = ffi.new("emu_cpu_t", {
	_pc			= safecast('uint16_t *', _cpu.pc),
	_a			= safecast('uint8_t *', _cpu.a),
	_x			= safecast('uint8_t *', _cpu.x),
	_y			= safecast('uint8_t *', _cpu.y),
	_s			= safecast('uint8_t *', _cpu.s),
	_p			= safecast('emu_cpu_flags_t *', _cpu.p),
	_cycles		= safecast('int32_t *', _cpu.cycles),
})

_G.emu.cpu = cpu_s




local cpu_sys = create_hook_system("cpu", 65536, 8)




pc_hook = function(addr, priority, cond_fn, pre_fn, post_fn)
	cond_fn = cond_fn or nil
	pre_fn = pre_fn or nil
	post_fn = post_fn or nil


	if addr == nil or addr >= ADDR_MAX then
		error('Bad pc_hook address ' .. hexstr(addr), 2)
	end



	local table = _hooks.hooks
	local index = addr >> 3
	local bit = addr & 7


	if pre_fn then
		table[index] |= 1 << bit
	end


	if post_fn then
		table[index] |= 1 << bit
	end


	cpu_sys.add(addr, priority, cond_fn, pre_fn, post_fn)
end



last_pc = function()
	return _trace.pc[ (_trace.pc_idx - 1) % 1024 ]
end



-- extern func
emu.cpu_run = function()
	local pre_run = cpu_sys.pre_run
	local post_run = cpu_sys.post_run


	_hooks.flags = 0


	while _cpu_run(0) == 0 do
		local _pc = cpu.pc


		if (_hooks.flags & HOOK_PC) == 0 then goto continue end
		pre_run(_pc)	-- pre-detour


		if (_hooks.flags & CPU_SKIP) != 0 then goto continue end
		_cpu_run(1)		-- 1 opcode


		if (_hooks.flags & CPU_WAIT) != 0 then goto continue end
		post_run(_pc)	-- post-detour


		::continue::
		_hooks.flags = 0
	end
end



pc_old = function(idx)
	idx = idx or 0

	pc = _trace.pc[ (_trace.pc_idx + idx - 1) % 1024 ]		-- current pc = -1 index

	return pc
end



pc_rom = function(idx)
	idx = idx or 0

	return _rom_addr( pc_old(idx) )
end



rom_addr = function(addr)
	return _rom_addr(addr)
end



rom_cond = function(addr)
	return function()
		return pc_rom() == addr
	end
end



ram_cond = function(aob)
	--if pc_rom() != addr then return false end

	return false
end



wram_cond = function(addr, aob)
	return function()
		return wramcmp(addr, aob)
	end
end
