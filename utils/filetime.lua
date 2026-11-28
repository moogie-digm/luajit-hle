local ffi = require("ffi")


if ffi.os == "Windows" then
    ffi.cdef[[
        typedef struct {
            uint32_t dwLowDateTime;
            uint32_t dwHighDateTime;
        } FILETIME;
        typedef struct {
            uint32_t dwFileAttributes;
            FILETIME ftCreationTime;
            FILETIME ftLastAccessTime;
            FILETIME ftLastWriteTime;
            uint32_t nFileSizeHigh;
            uint32_t nFileSizeLow;
        } WIN32_FILE_ATTRIBUTE_DATA;
        
        int GetFileAttributesExA(const char* lpFileName, int fInfoLevelId, void* lpFileInformation);
    ]]
    
    function get_file_timestamp(path)
        local info = ffi.new("WIN32_FILE_ATTRIBUTE_DATA")
        -- 0 corresponds to GetFileExInfoStandard
        local success = ffi.C.GetFileAttributesExA(path, 0, info)
        if success == 0 then return 0 end -- File missing or locked
        
        -- Combine high and low bits into a single 64-bit integer timestamp
        local high = ffi.cast("uint64_t", info.ftLastWriteTime.dwHighDateTime)
        local low = ffi.cast("uint64_t", info.ftLastWriteTime.dwLowDateTime)
        return tonumber((high * 2^32) + low)
    end
else
    -- Mac / Linux POSIX stat
    ffi.cdef[[
        // This structural layout works perfectly for standard x86_64 Linux/macOS glibc
        struct stat {
            unsigned long st_dev;
            unsigned long st_ino;
            unsigned long st_nlink;
            unsigned int  st_mode;
            unsigned int  st_uid;
            unsigned int  st_gid;
            int           __pad0;
            unsigned long st_rdev;
            long          st_size;
            long          st_blksize;
            long          st_blocks;
            long          st_atime;
            long          st_atime_nsec;
            long          st_mtime;      // Last modification time (seconds)
            long          st_mtime_nsec; // Nanoseconds
            long          st_ctime;
            long          st_ctime_nsec;
        };
        int stat(const char *path, struct stat *buf);
    ]]
    
    local stat_buf = ffi.new("struct stat")
    function get_file_timestamp(path)
        if ffi.C.stat(path, stat_buf) ~= 0 then return 0 end
        -- Combine seconds and nanoseconds for high accuracy
        return tonumber(stat_buf.st_mtime) * 1000000000 + tonumber(stat_buf.st_mtime_nsec)
    end
end
