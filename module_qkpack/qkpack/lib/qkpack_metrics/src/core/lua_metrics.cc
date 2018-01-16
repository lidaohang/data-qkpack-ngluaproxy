#include "core/qkpack_metrics.h"

extern "C" 
{  
	    #include <lua.h>  
	    #include <lauxlib.h>  
	    #include <lualib.h>  
}

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <stdio.h>
#include <iostream>
#include <sstream>

using namespace com::youku::data::qkpack::core;

static QkPackMetrics *qkpack_metrics_ = new QkPackMetrics(true);

void qkpack_timer(const std::string &registry_name, const std::string &timer_name)
{
	qkpack_metrics_->QKPackTimer(registry_name,timer_name);
}

int qkpack_timer_stop()
{
	return qkpack_metrics_->TimerStop();
}

int report()
{
	return qkpack_metrics_->Report();
}

void qkpack_meter(const std::string &registry_name, const std::string &meter_name)
{
	qkpack_metrics_->QKPackMeter(registry_name, meter_name);
}

int destroy()
{
	if ( qkpack_metrics_ ) {
		delete qkpack_metrics_;
		qkpack_metrics_ = NULL;
		return 0;
	}
	return -1;
}

extern "C"
{


int qkpack_lua_meter(const unsigned char *registry_buf, size_t registry_len,const unsigned char *meter_buf,size_t meter_len) 
{
	std::string registry_name = std::string((char*)registry_buf,registry_len);
	std::string meter_name = std::string((char*)meter_buf, meter_len);
	
	qkpack_meter(registry_name,meter_name);
	
	return 0;
}

int qkpack_lua_timer(const unsigned char *registry_buf, size_t registry_len,const unsigned char *timer_buf,size_t time_len) 
{	
	std::string registry_name = std::string((char*)registry_buf,registry_len);
	std::string timer_name = std::string((char*)timer_buf, time_len);
	
	qkpack_timer(registry_name,timer_name);

	return 0;
}

int qkpack_lua_timer_stop()
{
	return qkpack_timer_stop();
}



int qkpack_lua_report()
{
	return report();
}


int qkpack_lua_destroy()
{
	return destroy();
}

}

