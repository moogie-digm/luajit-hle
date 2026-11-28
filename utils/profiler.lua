local ffi = require("ffi")


if ffi.os == "Windows" then
	ffi.cdef[[
		typedef struct { int64_t QuadPart; } LARGE_INTEGER;
		int QueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCount);
		int QueryPerformanceFrequency(LARGE_INTEGER *lpFrequency);
	]]
	local freq = ffi.new("LARGE_INTEGER")
	ffi.C.QueryPerformanceFrequency(freq)
	local frequency = tonumber(freq.QuadPart)

	-- ALLOCATE ONCE HERE: Re-use this single struct across all counter queries
	local ctr = ffi.new("LARGE_INTEGER[1]")

	-- micro seconds
	get_time_us = function()
		ffi.C.QueryPerformanceCounter(ctr)
		return (tonumber(ctr.QuadPart) / frequency) * 1000000.0
	end
else
	-- Mac / Linux (POSIX clock_gettime)
	ffi.cdef[[
		typedef long time_t;
		typedef long sutime_t;
		struct timeval { time_t tv_sec; sutime_t tv_usec; };
		int gettimeofday(struct timeval *restrict tp, void *restrict tzp);
	]]

	local tv = ffi.new("struct timeval[1]")

	get_time_us = function()
		ffi.C.gettimeofday(tv, nil)
		return (tonumber(tv.tv_sec) * 1000000.0) + tonumber(tv.tv_usec)
	end
end



get_time_ms = function()
    -- highly precise milli seconds
    return get_time_us() / 1000.0
end



--[[
start_time = get_time_us()

<code>

local elapsed = get_time_us() - start_time

if elapsed > 50.0 then
	print(string.format("⚠️ [PERF WARNING] Hook at %s took %.2f μs to execute!", origin, elapsed))
end				
--]]
