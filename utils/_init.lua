require(((... or ""):match("(.-)[^%.]+$") or "") .. 'incsrc') 	-- local file



include '.' {
	'bindscalar',		-- wrap [0] indexing
	'delta_patch',		-- delta, aob scanner
	'fastmem',			-- memory routines
	'filetime',			-- timestamps
	'hooks',			-- detours, trampolines
	'memcmp',			-- memory compare
	'overlays',			-- signal overlay handlers
	'persist',			-- hot reloading
	'print',			-- strings, output
	--'profiler'		-- performance timing
	'safecast',			-- ffi cast
}
