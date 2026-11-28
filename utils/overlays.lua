local tab_new = require("table.new")
local tab_clear = require("table.clear")



local DEFAULT_TABLE_SIZE = 512



-- Stack-safe error context (handles nested hook dispatches cleanly)
local origin_stack = {}
local origin_depth = 0



local error_handler = function(err)
    local traceback = debug.traceback("", 2)
	local origin = origin_stack[origin_depth] or "unknown"

    print(string.format(
        "--------------------------------------------------\n" ..
        "❌ MOD HOOK CRASHED!\n" ..
        "Hook Origin: %s\n" ..
        "Error Reason: %s\n" ..
        "%s\n" ..
        "--------------------------------------------------\n",
        origin, tostring(err), traceback
    ))
end



local function get_caller_location(stack_level)
    local info = debug.getinfo(stack_level, "Sl")
    if not info then return "unknown:line 0" end
    return string.format("%s:line %d", info.short_src or "unknown", info.currentline or 0)
end



-- EXPANDABLE HOOK FRAMEWORK
create_overlays_system = function(system_name, table_size)

	system_name = system_name or nil
	table_size = table_size or DEFAULT_TABLE_SIZE


	local fns = tab_new(table_size, 0)
	local origins = tab_new(table_size, 0)
	local priorities = tab_new(table_size, 0)
    local count = 0
    local dirty_order = false



    -- Sort hooks by priority (higher priority runs first; skipped if all priorities match)
    local function sort_hooks()
        if not dirty_order then return end
        -- Insertion sort: O(n) on already-sorted hooks, zero allocations, preserves registration order
        for i = 2, count do
            local fn = fns[i]
            local orig = origins[i]
            local prio = priorities[i]
            local j = i - 1

            while j >= 1 and priorities[j] < prio do
                fns[j + 1] = fns[j]
                origins[j + 1] = origins[j]
                priorities[j + 1] = priorities[j]
                j = j - 1
            end

            fns[j + 1] = fn
            origins[j + 1] = orig
            priorities[j + 1] = prio
        end
        dirty_order = false
    end



	-- [API] Standard Signaler Registration
    local register = function(fn, priority)
		priority = priority or 0
		count += 1


		fns[count] = fn
		priorities[count] = priority


		-- 1 = get_caller_location - debug.getinfo
		-- 2 = get_caller_location - <below>
		-- 3 = <system>.register
		origins[count] = get_caller_location(3)


        if count > 1 and priority > priorities[count - 1] then
            dirty_order = true
        end
	end



	-- [API] Safe Unregistration Loop
    local unregister = function(call_fn)
		for i = 1, count do
			if fns[i] == call_fn then
				fns[i] = false  -- Tombstone keeps array dense
				origins[i] = false
			end
		end
    end



    -- [API] Full Core Wipe
    local wipe_all = function()
        tab_clear(fns)
        tab_clear(origins)
        tab_clear(priorities)
        count = 0
        dirty_order = false
    end



	-- [API] Compress and clean up tombstoned slots when the CPU is idle  (not every frame)
	local function vacuum_hooks()
        local write_idx = 0

        for read_idx = 1, count do
            local fn = fns[read_idx]
            if fn then
                write_idx = write_idx + 1
                fns[write_idx] = fn
                origins[write_idx] = origins[read_idx]
                priorities[write_idx] = priorities[read_idx]
            end
        end

        for i = write_idx + 1, count do
            fns[i] = nil
            origins[i] = nil
            priorities[i] = nil
        end

        count = write_idx
	end



	local function dispatch()
        if dirty_order then
            sort_hooks()
        end


        local count = count -- Snapshot length against mid-loop additions
        origin_depth = origin_depth + 1


        for i = 1, count do
            local fn = fns[i]
            if fn then
				origin_stack[origin_depth] = origins[i]
				local ok = xpcall(fn, error_handler)

				-- Auto-tombstone broken hooks so they don't spam errors every frame
				if not ok then
					fns[i] = false
					origins[i] = false
				end
			end
        end


        origin_stack[origin_depth] = nil
        origin_depth = origin_depth - 1
	end



    -- Bundle public methods together for the engine manager
    local system_instance = {
        name = system_name,
        add = register,
        remove = unregister,
        clear = wipe_all,
		vacuum = vacuum_hooks,
		run = dispatch,
    }


    return system_instance
end
