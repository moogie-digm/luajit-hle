local ARGS = {}
local max_args = 20



local err_ctx_source = nil



local error_handler = function(err)
    local traceback = debug.traceback("", 2)

    print(string.format(
        "--------------------------------------------------\n" ..
        "❌ MOD HOOK CRASHED!\n" ..
        "Hook Origin: %s\n" ..
        "Error Reason: %s\n" ..
        "%s\n" ..
        "--------------------------------------------------\n",
        err_ctx_source, tostring(err), traceback
    ))
end



local loaded_modules = {} -- Ordered list: { "engine.utils.wram_overlays", ... }
local is_tracked = {}     -- Lookup set to avoid duplicate entries



local function track_module(target_path)
    if not is_tracked[target_path] then
        is_tracked[target_path] = true
        table.insert(loaded_modules, target_path)
    end
end



local resolve_module_path = function(clean_dir, module_path)
    local stack = {}

    -- Push caller's directory segments onto stack (e.g., "engine.utils." -> {"engine", "utils"})
    for part in clean_dir:gmatch("[^%.]+") do
        table.insert(stack, part)
    end

    -- Normalize slashes in module_path to dots, preserving ".."
    -- Temporarily replace ".." so it doesn't get split into empty segments
    local normalized = module_path:gsub("[\\/]", "."):gsub("%.%.", "\1")

    for part in normalized:gmatch("[^%.]+") do
        if part == "\1" then
            -- Move up one directory
            if #stack > 0 then
                table.remove(stack)
            else
                error("Attempted to traverse above project root: " .. module_path)
            end
        else
            table.insert(stack, part)
        end
    end

    return table.concat(stack, ".")
end



local load_relative = function(info, force_reload, is_critical, module_path, stack_level, ...)
    if not info or not info.source then return end


    -- Extract file's containing folder path (e.g., ".\project\")
    -- Using a greedy match that explicitly stops at the final slash
    local raw_dir = info.source:match("^@?(.-)[^\\/]+$") or ""

    -- Convert path slashes into Lua require dots
	local clean_dir = raw_dir:gsub("[\\/]", "."):gsub("^%.+", "")

	local target_path = resolve_module_path(clean_dir, module_path)


	track_module(target_path)


    -- Clear cache if hot-reloading
    if force_reload then
        package.loaded[target_path] = nil
    end



	-- include nils
	local totalArgs = select("#", ...)

	-- pass inputs
	for i = 1, totalArgs do
		ARGS[i] = select(i, ...)
	end

	-- wipe rest
	for i = totalArgs+1, 20 do
		ARGS[i] = nil
	end



	err_ctx_source = target_path

    local ok, mod_result = xpcall(require, error_handler, target_path)


	if not ok then
		print('fff')
		if is_critical then
			error("🛑 Critical module failed to load: " .. target_path, 0)
        end

        return false
    end


	if mod_result == nil then return true end
	return mod_result
end



-- relative include
incsrc = function(path, ...)
	local info = debug.getinfo(2, "S")

    return load_relative(info, false, false, path, 3, ...)
end



incsrc_critical = function(path, ...)
    local info = debug.getinfo(2, "S")
    return load_relative(info, false, true, path, 3, ...)
end



reload = function(path, ...)
	local info = debug.getinfo(2, "S")

    return load_relative(info, true, false, path, 3, ...)
end



local make_folder_loader = function(force_reload)
	return function(prefix)
		local path_prefix = (prefix == "." or prefix == "") and "" or (prefix .. "/")

		return function(list)
			local info = debug.getinfo(2, "S")

			for _, mod in ipairs(list) do
				load_relative(info, force_reload, false, path_prefix .. mod, 3)
			end
		end
	end
end



include = make_folder_loader(false)
reinclude = make_folder_loader(true)



reload_all = function()
    print("🔄 Reloading all project modules...")

    -- 1. Wipe all tracked modules from cache first so cross-dependencies re-require fresh copies
    for _, target_path in ipairs(loaded_modules) do
        package.loaded[target_path] = nil
    end

    -- 2. Re-execute in the exact order they were originally loaded
    for _, target_path in ipairs(loaded_modules) do
        err_ctx_source = target_path
        xpcall(require, error_handler, target_path)
    end

    print("✅ Reload complete (" .. #loaded_modules .. " modules).")
end
