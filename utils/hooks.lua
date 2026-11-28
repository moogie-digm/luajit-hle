local tab_new = require("table.new")



local DEFAULT_TABLE_SIZE = 512
local DEFAULT_HOOKS_SIZE = 8


local no_cond = function() return true end


local err_ctx_addr = 0
local err_ctx_origin = ""


-- Stack-safe error context (handles nested hook dispatches cleanly)
local origin_stack = {}
local origin_depth = 0



-- HIGH-FREQUENCY PROTECTED DISPATCHER
local function error_handler(err)
    local hook_origin_str = string.format("Address [0x%X] -> %s", err_ctx_addr, err_ctx_origin)
    local traceback = debug.traceback("", 2)

    print(string.format(
        "--------------------------------------------------\n" ..
        "❌ MOD HOOK CRASHED!\n" ..
        "Hook Origin: %s\n" ..
        "Error Reason: %s\n" ..
        "%s\n" ..
        "--------------------------------------------------\n",
        hook_origin_str, tostring(err), traceback
    ))
end



local get_caller_location = function(stack_level)
	local info = debug.getinfo(stack_level, "Sl")
	return string.format("%s:line %d", info.short_src or "unknown", info.currentline or 0)
end



-- EXPANDABLE HOOK FRAMEWORK
create_hook_system = function(system_name, table_size, max_hooks)

	system_name = system_name or nil
	table_size = table_size or DEFAULT_TABLE_SIZE
	max_hooks = max_hooks or DEFAULT_HOOKS_SIZE


    local hook_table = tab_new(table_size, 0)
	local func_table = tab_new(table_size, 0)


	-- [API] Standard Hook Registration with Numeric Priority
    local register = function(addr, priority, cond_fn, pre_fn, post_fn)
        local hooks = hook_table[addr]

		priority = priority or 0


        if not hooks then
            hooks = tab_new(max_hooks, 0)
			hook_table[addr] = hooks
		else
			local current_count = #hooks
			
			-- continue to cross subsequent power-of-two boundaries
			if current_count >= max_hooks then
				local new_capacity = current_count * 2
				local new_hooks = tab_new(new_capacity, 0)
				
				-- Bulk copy old hooks to the newly optimized table
				for i = 1, current_count do
					new_hooks[i] = hooks[i]
				end
				
				hooks = new_hooks
				hook_table[addr] = hooks

				max_hooks = new_capacity
			end
        end



        -- Safe closure gatekeeper
        local wrapped_fn = function()
			local fn = pre_fn or no_cond


            -- Protected check ensures broken condition fields don't crash the emulator
            local cond_success, cond_result = xpcall(fn, debug.traceback)

            
            if cond_success and cond_result then
                call_fn()

            elseif not cond_success then
                error("Condition Check crash: " .. tostring(cond_result), 0)
            end
        end



		-- Create a unified hook entry object
		local new_hook = {
			cond_fn = cond_fn,
			pre_fn = pre_fn,
			post_fn = post_fn,

			-- 1 = get_caller_location - debug.getinfo
			-- 2 = get_caller_location - <below>
			-- 3 = <system>.register
			-- 4 = mod - <>_hook
			origin = get_caller_location(4),

			priority = priority
		}
		

		-- Determine insertion index based on priority (Highest Priority first)
		-- If two hooks have the same priority, this preserves creation order (FIFO)

		local insert_idx = #hooks + 1

		-- OPTIMIZATION: If it's lower/equal priority than the last element, it goes at the end.
		-- This keeps debugger initialization at O(1) per hook instead of O(N).
		if #hooks > 0 and priority <= hooks[#hooks].priority then
			hooks[insert_idx] = new_hook
		else
			for i = 1, #hooks do
				if priority > hooks[i].priority then
					insert_idx = i
					break
				end
			end
			
			table.insert(hooks, insert_idx, new_hook)
		end


		-- Track for lookups/removals if needed
		func_table[wrapped_fn] = post_fn or pre_fn
    end



	-- [API] Safe Unregistration Loop
    local unregister = function(addr, call_fn)
        local hooks = hook_table[addr]
        if not hooks then return false end


		local removed = false


		-- Reverse loop avoids JIT array-iteration skip bugs
        for i = #hooks, 1, -1 do
			local wrapped = hooks[i]

            -- Check against the raw function link instead of the wrapper closure
			if wrapped and func_table[wrapped] == call_fn then

                -- SOFT DELETE: Turn them into tombstones
				hooks[i] = false

				func_table[wrapped] = nil

				removed = true
            end
        end

        return removed
    end



    -- [API] Full Core Wipe
    local wipe_all = function()
        -- Loop through every memory address currently tracking hooks
        for addr, _ in pairs(hook_table) do
            -- Setting the keys to nil releases the inner array memory, 
            -- but the master hash layout stays optimized in LuaJIT memory.
            hook_table[addr]  = nil
        end
    end



	-- [API] Compress and clean up tombstoned slots when the CPU is idle  (not every frame)
	local vacuum_hooks = function()
		-- Iterate through every memory address currently tracking hooks
		for addr, hooks in pairs(hook_table) do
			-- Create a clean, temporary array for the compacted data
			local clean_hooks = {}
			
			-- Pull only the active hooks forward, completely stripping the false tombstones
			for i = 1, #hooks do
				local fn = hooks[i]
				if fn then
					local idx = #clean_hooks + 1

					clean_hooks[idx] = fn
				end
			end
			
			-- If no active hooks remain, completely delete the table reference
			if #clean_hooks == 0 then
				hook_table[addr]  = nil
			else
				-- Otherwise, replace the old tables with the fresh, tight arrays
				hook_table[addr] = clean_hooks
			end
		end
	end



	local pre_dispatch = function(addr)
		local hooks = hook_table[addr]
		if not hooks then return end


		local count = #hooks -- Snapshot length against mid-loop additions
		origin_depth = origin_depth + 1


		for i = 1, count do
			local hook = hooks[i]


			local fn = hook.pre_fn
			
			if not fn then goto continue end



			local cond_fn = hook.cond_fn
			
			if cond_fn then
				local _, cond_result = xpcall(cond_fn, error_handler)

				if _ == false or cond_result == false then goto continue end
			end



			-- Set up values for our error handler prior to the xpcall
			local origin = hook.origin or "unknown location"

			err_ctx_addr = addr
			err_ctx_origin = origin


			origin_stack[origin_depth] = origin
			local ok = xpcall(fn, error_handler)

			-- Auto-tombstone broken hooks so they don't spam errors every frame
			if not ok then
				hook.pre_fn = false
			end


			::continue::
		end


        origin_stack[origin_depth] = nil
        origin_depth = origin_depth - 1
	end



	local post_dispatch = function(addr)
		local hooks = hook_table[addr]
		if not hooks then return end


		local count = #hooks -- Snapshot length against mid-loop additions
		origin_depth = origin_depth + 1


		for i = 1, count do
			local hook = hooks[i]


			local fn = hook.post_fn
			
			if not fn then goto continue end



			local cond_fn = hook.cond_fn
			
			if cond_fn then
				local _, cond_result = xpcall(cond_fn, error_handler)

				if _ == false or cond_result == false then goto continue end
			end



			-- Set up values for our error handler prior to the xpcall
			local origin = hook.origin or "unknown location"

			err_ctx_addr = addr
			err_ctx_origin = origin


			origin_stack[origin_depth] = origin
			local ok = xpcall(fn, error_handler)

			-- Auto-tombstone broken hooks so they don't spam errors every frame
			if not ok then
				hook.post_fn = false
			end


			::continue::
		end
	end



    -- Bundle public methods together for the engine manager
    local system_instance = {
        name = system_name,
        add = register,
        remove = unregister,
        clear = wipe_all,
		pre_run = pre_dispatch,
		post_run = post_dispatch,
        --_hooks      = hook_table,  -- Kept outside global reach but accessible to dispatcher
        --_dbgs       = debug_table
    }


    return system_instance
end
