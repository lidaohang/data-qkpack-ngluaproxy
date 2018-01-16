local qkpack_common = require "resty.qkpack_common"
local ffi = require 'ffi'

local base = require "resty.core.base"
local ffi_new = ffi.new
local ffi_str = ffi.string
local C = ffi.C


ffi.cdef[[
int  qkpack_lua_destroy();
int  qkpack_lua_report();
int  qkpack_lua_timer_stop();
int  qkpack_lua_timer(const unsigned char *registry_buf, size_t registry_len,unsigned char *timer_buf,size_t timer_len);
int  qkpack_lua_meter(const unsigned char *registry_buf, size_t registry_len,unsigned char *meter_buf,size_t meter_len);
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

_M.timer_status = false
_M.registry_user_name_ = nil
_M.registry_global_name_ = nil

local clib = load_shared_lib("libqkpack_metrics.so")
if not clib then
    error("can not load libqkpack_metrics.so")
end



local handler
handler = function ()
	
        local rc = clib.qkpack_lua_report();
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_report is failed")
	end
	
	if ngx.worker.exiting() == true then
	     rc = clib.qkpack_lua_destroy();     
	     if rc ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_destroy is failed")
	     end

	     ngx.log(ngx.ERR, "exit the timer...")
	     return
	end

	local ok, err = ngx.timer.at(60, handler)
	if not ok then
	     ngx.log(ngx.ERR, "failed to create the timer: ", err)
	     return
	end
end


local function set_registry_user_name(self)
	if self.registry_user_name_ == nil then
		self.registry_user_name_ = qkpack_common.QKPACK_USERSCENE_SYS_ID.."_"..qkpack_common.QKPACK_USERSCENE_SCE_ID.."_min_"..ngx.var.server_addr.."::"..tostring(ngx.worker.pid())
	end
end

local function set_registry_global_name(self)
	if self.registry_global_name_ == nil then
		self.registry_global_name_ = qkpack_common.QKPACK_GLOBALSCENE_G_SYS_ID.."_"..qkpack_common.QKPACK_GLOBALSCENE_G_SCE_ID.."_min_"..ngx.var.server_addr.."::"..tostring(ngx.worker.pid())
	end
end


local function get_user_timer(self, request)
	
	local								data = nil

	if request.kvpair ~= nil then
		data = request.kvpair
	elseif request.multikvpair ~= nil then
		data = request.multikvpair
	elseif request.sset_member ~= nil then
		data = request.sset_member
	elseif request.zset_member ~= nil then
		data = request.zset_member
	elseif request.zset_query ~= nil then
		data = request.zset_query
	end

	if data == nil then
		data = {}
		data.ak = "null"
		request.namespace = "null"
		request.metrics_command = "null"
	end
	
	if data.ak == nil then
		data.ak = "null"
	end
	
	if request.uri_id == nil then
		request.uri_id = 0
	end

	if request.namespace == nil then
		request.namespace = "null"
	end

	if request.metrics_command == nil then
		request.metrics_command = "null"
	end

	
	return tostring(request.uri_id).."."..data.ak.."."..request.namespace.."."..request.metrics_command..".timer"
end

local function get_global_timer(self, request)
	return "G_"..request.script_name..".timer"
end


local function get_user_meter(self, request)
	
	local								data = nil

	if request.kvpair ~= nil then
		data = request.kvpair
	elseif request.multikvpair ~= nil then
		data = request.multikvpair
	elseif request.sset_member ~= nil then
		data = request.sset_member
	elseif request.zset_member ~= nil then
		data = request.zset_member
	elseif request.zset_query ~= nil then
		data = request.zset_query
	end

	if data == nil then
		data = {}
		data.ak = "null"
		request.namespace = "null"
		request.metrics_command = "null"
	end
	
	if data.ak == nil then
		data.ak = "null"
	end

	if request.uri_id == nil then
		request.uri_id = 0
	end

	if request.namespace == nil then
		request.namespace = "null"
	end

	if request.metrics_command == nil then
		request.metrics_command = "null"
	end

	return tostring(request.uri_id).."."..data.ak.."."..request.namespace.."."..request.metrics_command..".meter"
end


local function get_global_meter(self, request)
	return tostring(request.uri_id)..request.metrics_command..".meter"
end



function _M.report(self)

	--ngx.log(ngx.DEBUG, "report---------------------------------------------------")
	
    	local rc = clib.qkpack_lua_report();
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_report is failed")
	end

	local ok, err = ngx.timer.at(60, handler)
	if not ok then
	     ngx.log(ngx.ERR, "failed to create the timer: ", err)
	     return
	end

end

local function timer(self, registry_name, timer_name)
		
	local rc = clib.qkpack_lua_timer(ffi.cast("char *", registry_name), #registry_name, ffi.cast("char *", timer_name), #timer_name);
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_user_scene_timer is failed")
	end

	if self.timer_status == true then
		return
	end

	self.timer_status = true
	local ok, err = ngx.timer.at(60, handler)
	if not ok then
	     ngx.log(ngx.ERR, "failed to create the timer: ", err)
	     return
	end
end


function _M.user_timer(self, request)
	set_registry_user_name(self);
	set_registry_global_name(self);
	
	timer(self, self.registry_user_name_ , get_user_timer(self, request))
end

function _M.global_timer(self,request)
	set_registry_user_name(self);
	set_registry_global_name(self);
	
	timer(self, self.registry_global_name_, get_global_timer(self, request))
end




function _M.timer_stop(self)
        
	local rc = clib.qkpack_lua_timer_stop();
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_user_scene_timer_stop is failed")
	end
end


local function meter(self, registry_name, meter_name)
	
        local rc = clib.qkpack_lua_meter(ffi.cast("char *", registry_name), #registry_name, ffi.cast("char *", meter_name), #meter_name);
	if rc  ~= 0 then
		ngx.log(ngx.ERR, "qkpack_lua_user_scene_timer is failed")
	end
end


function _M.user_meter(self, request)
	set_registry_user_name(self);
	set_registry_global_name(self);
	
	meter(self, self.registry_user_name_ , get_user_meter(self, request))
end





return _M
