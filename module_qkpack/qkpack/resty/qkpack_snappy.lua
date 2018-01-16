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
bool qkpack_lua_valid_compressed(const unsigned char *src);
int  qkpack_lua_compress(const unsigned char *src, size_t src_len,unsigned char **dest_buf,size_t *dest_len);
bool qkpack_lua_uncompress(const unsigned char *src, size_t src_len,unsigned char **dest_buf,size_t *dest_len);
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

local _M = {
	    version = base.version
}

--local mt = { __index = _M }


local clib = load_shared_lib("libqkpack_snappy.so")
if not clib then
    error("can not load libqkpack_snappy.so")
end

local str_value_buf = ffi_new("unsigned char *[1]")


--压缩Value
function _M.compress_value(self, src, compress_threshold)
	
	--ngx.log(ngx.DEBUG, "compress_value---------------------------------------------------")
	
	if src == nil or src == ngx.null then
		ngx.log(ngx.ERR, "src is nil")
		return false
	end

	local src_len = #src
	if src_len < compress_threshold then
		return false
	end

	local size = get_string_buf_size()
    local buf = get_string_buf(size)
	
    str_value_buf[0] = buf
    local value_len = get_size_ptr()
    value_len[0] = size
	
    local rc = clib.qkpack_lua_compress(ffi.cast("char *", src), src_len, str_value_buf, value_len);
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_compress is failed")
		return false
	end
	
	local val = nil
	if str_value_buf[0] ~= buf then
		--ngx.say("len: ", tonumber(value_len[0]))
		buf = str_value_buf[0]
		val = ffi_str(buf, value_len[0])
		C.free(buf)
	else
		val = ffi_str(buf, value_len[0])
	end

	--ngx.log(ngx.DEBUG, val)

	local compress_len = #val
	if compress_len > src_len then
		return false
	end
	
	return true, val
end


function _M.uncompress_value(self, src)
	
	--ngx.log(ngx.DEBUG, "uncompress_value---------------------------------------------------")

	if src == nil or src == ngx.null   then
		return false
	end

	local 									src_len = #src
	local 									size = get_string_buf_size()
    	local 									buf = get_string_buf(size)
	local									b;

	--判断是否是snappy格式
	b = clib.qkpack_lua_valid_compressed(ffi.cast("char *", src))
	if b == false then
		return false
	end
	
    --ngx.log(ngx.DEBUG, src)
    
    str_value_buf[0] = buf
    local value_len = get_size_ptr()
    value_len[0] = size
	
    b = clib.qkpack_lua_uncompress(ffi.cast("char *", src), src_len, str_value_buf, value_len);
	if b == false then
		return false
	end
	
	local val = nil
	if str_value_buf[0] ~= buf then
		-- ngx.say("len: ", tonumber(value_len[0]))
		buf = str_value_buf[0]
		val = ffi_str(buf, value_len[0])
		C.free(buf)
	else
		val = ffi_str(buf, value_len[0])
	end
	
	--ngx.log(ngx.DEBUG, val)

	return true, val;
end


return _M
