local qkpack_parser = require "resty.qkpack_parser"
local qkpack_acl = require "resty.qkpack_acl"
local qkpack_redis = require "resty.qkpack_redis"
local qkpack_common = require "resty.qkpack_common"
local qkpack_metrics = require "resty.qkpack_metrics"


local _M = {
    _VERSION = '0.01',
}


function _M.handle(self, request)

	--ngx.log(ngx.DEBUG, "handle begin---------------------------------------------------")

	local								rc = 0

	rc = qkpack_parser:parser_request(request)
	if rc ~= qkpack_common.QKPACK_OK then
		--metrics
		request.metrics_command = qkpack_common.QKPACK_METRICS_JSON_PARSER_ERROR_METER
		qkpack_metrics:user_meter(request);	
	
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_PARSE_ERROR
		return qkpack_parser:parser_error(request)
	end

	
	rc = qkpack_acl:process(request)
	if rc ~= qkpack_common.QKPACK_OK then
		--metrics
		request.metrics_command = qkpack_common.QKPACK_METRICS_ACL_ERROR_METER
		qkpack_metrics:user_meter(request);
	
		request.code = qkpack_common.QKPACK_RESPONSE_CODE_ILLEGAL_RIGHT
		return qkpack_parser:parser_error(request)
	end
	
	rc = qkpack_redis:process(request)
	if rc ~= qkpack_common.QKPACK_OK then
		--metrics 
		request.metrics_command = qkpack_common.QKPACK_METRICS_CLUSTER_NODES_ERROR_METER
		qkpack_metrics:user_meter(request);	
	
	
		return qkpack_parser:parser_error(request)
	end

	rc = qkpack_parser:parser_response(request)
	if rc ~= qkpack_common.QKPACK_OK then
		return qkpack_parser:parser_error(request)
	end

	--ngx.log(ngx.DEBUG, "handle end---------------------------------------------------")
	
	return qkpack_common.QKPACK_OK	
end


return _M
