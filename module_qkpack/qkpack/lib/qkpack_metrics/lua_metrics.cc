#include "metrics/qkpack_metrics.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <stdio.h>
#include <snappy.h>
#include <iostream>
#include <sstream>


static QkPackMetrics qkpack_metrics_ = new QkPackMetrics(true);


extern "C" int qkpack_lua_user_scene_timer(const unsigned char *registry_buf, size_t registry_len,unsigned char *timer_buf,size_t time_len) 
{
	std::string registry_name = std::string(registry_buf,registry_len);
	std::string timer_name = std::string(timer_buf, time_len);
	
	qkpack_metrics_->UserSceneTimer(registry_name,timer_name);

	return 0;
}



