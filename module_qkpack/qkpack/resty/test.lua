local ffi = require 'ffi'

local base = require "resty.core.base"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C
local str_value_buf = ffi_new("unsigned char *[1]")
local get_string_buf = base.get_string_buf
local get_string_buf_size = base.get_string_buf_size
local get_size_ptr = base.get_size_ptr


ffi.cdef[[
int lua_test(const unsigned char *src, size_t src_len,unsigned char **dest_buf,size_t *dest_len);
]]

if not pcall(function () return C.free end) then
    ffi.cdef[[
        void free(void *ptr);
    ]]
end


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


--
-- Find shared object file package.cpath, obviating the need of setting
-- LD_LIBRARY_PATH
-- Or we should add a little patch for ffi.load ?
--
local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close

    local cpath = package.cpath

    for k, _ in string_gmatch(cpath, "[^;]+") do
        local fpath = string_match(k, "(.*/)")
        fpath = fpath .. so_name

        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(fpath)
        if f ~= nil then
            io_close(f)
            return ffi.load(fpath)
        end
    end
end


local _M = {}
local mt = { __index = _M }


local clib = load_shared_lib("libluatest.so")
if not clib then
    error("can not load libluatest.so")
end

local str_value_buf = ffi_new("unsigned char *[1]")

function _M.get_value(self, str)

	local size = get_string_buf_size()
    local buf = get_string_buf(size)
	
    str_value_buf[0] = buf
    local value_len = get_size_ptr()
    value_len[0] = size
	
    local rc = clib.lua_test(ffi.cast("char *", str), #str, str_value_buf, value_len);
	
	local val = nil
	if str_value_buf[0] ~= buf then
		-- ngx.say("len: ", tonumber(value_len[0]))
		buf = str_value_buf[0]
		val = ffi_str(buf, value_len[0])
		C.free(buf)
	else
		val = ffi_str(buf, value_len[0])
	end
	
	return val
end


return _M
