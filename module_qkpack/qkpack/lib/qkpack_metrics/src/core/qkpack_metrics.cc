#include "core/qkpack_metrics.h"
#include "metrics/utils.h"
#include "config/easycurl.h"
#include <boost/foreach.hpp>

using namespace com::youku::data::qkpack::metrics;
using namespace com::youku::data::qkpack::config;
using namespace com::youku::data::qkpack::core;

/******************************************
 * 	*metrics name
 * 		*
 * 		******************************************/
//metrics
#define QKPACK_METRICS_SYSNAME												"sysName"
//meters
#define QKPACK_METRICS_METERS												"meters"
#define QKPACK_METRICS_METERS_NAME											"name"
#define QKPACK_METRICS_METERS_COUNT											"count"
#define QKPACK_METRICS_METERS_M15_RATE										"m15_rate"
#define QKPACK_METRICS_METERS_M1_RATE										"m1_rate"
#define QKPACK_METRICS_METERS_M5_RATE										"m5_rate"
#define QKPACK_METRICS_METERS_MEAN_RATE										"mean_rate"
#define QKPACK_METRICS_METERS_UNITS											"units"
//timers
#define QKPACK_METRICS_TIMERS												"timers"
#define QKPACK_METRICS_TIMERS_NAME											"name"
#define QKPACK_METRICS_TIMERS_COUNT											"count"
#define QKPACK_METRICS_TIMERS_MAX											"max"
#define QKPACK_METRICS_TIMERS_MEAN											"mean"
#define QKPACK_METRICS_TIMERS_MIN											"min"
#define QKPACK_METRICS_TIMERS_P50											"p50"
#define QKPACK_METRICS_TIMERS_P75											"p75"
#define QKPACK_METRICS_TIMERS_P95											"p95"
#define QKPACK_METRICS_TIMERS_P98											"p98"
#define QKPACK_METRICS_TIMERS_P99											"p99"
#define QKPACK_METRICS_TIMERS_P999											"p999"
#define QKPACK_METRICS_TIMERS_STDDEV										"stddev"
#define QKPACK_METRICS_TIMERS_M15_RATE										"m15_rate"
#define QKPACK_METRICS_TIMERS_M1_RATE										"m1_rate"
#define QKPACK_METRICS_TIMERS_M5_RATE										"m5_rate"
#define QKPACK_METRICS_TIMERS_MEAN_RATE										"mean_rate"
#define QKPACK_METRICS_TIMERS_DURATION_UNITS								"duration_units"
#define QKPACK_METRICS_TIMERS_RATE_UNITS									"rate_units"


static const int64_t
	one_day			=	boost::chrono::milliseconds(boost::chrono::hours(24)).count(),
	one_hour		=	boost::chrono::milliseconds(boost::chrono::hours(1)).count(),
	one_minute		=	boost::chrono::milliseconds(boost::chrono::minutes(1)).count(),
	one_seconds		=	boost::chrono::milliseconds(boost::chrono::seconds(1)).count(),
	one_millisecond	=	boost::chrono::milliseconds(boost::chrono::milliseconds(1)).count();


QkPackMetrics::QkPackMetrics(bool metrics_status,
		boost::chrono::milliseconds rate_unit,
		boost::chrono::milliseconds duration_unit):
	metrics_status_(metrics_status),
	rate_unit_(rate_unit),
	duration_unit_(duration_unit) 
{		
	rate_factor_ = boost::chrono::milliseconds(1000).count() / rate_unit.count();
	duration_factor_ = static_cast<double>(1.0) / 
		boost::chrono::duration_cast<boost::chrono::nanoseconds>(duration_unit).count();
}


QkPackMetrics::~QkPackMetrics() 
{
/*	std::map<std::string,MetricRegistryPtr>::iterator		it;
	
	for ( it = map_registry_.begin(); it != map_registry_.end(); ++it ) {
		if ( it->second ) {
			delete it->second
			it->second = NULL;
		}
	}
*/
}


MetricRegistryPtr QkPackMetrics::QKPackMetricRegistry(const std::string &registry_name)
{
	std::map<std::string,MetricRegistryPtr>::iterator		it;
	
	it = map_registry_.find(registry_name);
	if ( it != map_registry_.end() ) {
		return it->second;
	}

	map_registry_[registry_name] =  MetricRegistryPtr(new MetricRegistry());
	return map_registry_[registry_name];
}


void QkPackMetrics::QKPackTimer(const std::string &metrics_name, const std::string &timer_name)
{
	MetricRegistryPtr										qkpack_registry;	
	
	qkpack_registry = QKPackMetricRegistry(metrics_name);

	//qkpack_registry->timer(timer_name)->timerContextPtr();
	vector_timer_.push_back(qkpack_registry->timer(timer_name)->timerContextPtr());
}


void QkPackMetrics::QKPackMeter(const std::string &metrics_name, const std::string &meter_name)
{
	MetricRegistryPtr										qkpack_registry;	
	
	qkpack_registry = QKPackMetricRegistry(metrics_name);
	if ( qkpack_registry == NULL ) {
		return;
	}

	qkpack_registry->meter(meter_name)->Mark();
}


int QkPackMetrics::TimerStop() 
{
	int len = vector_timer_.size();
	if ( len <= 0 ) {
		return 0;
	}

	for ( int i = 0; i < len; ++i ) {
		vector_timer_[i]->Stop();
		vector_timer_[i].reset();
	}
	vector_timer_.clear();  

	return 0;
}

int QkPackMetrics::Report()
{
	if ( !metrics_status_ ) {
		return 0;
	}

	/*
	[{
        "sysName":"23_1533_min_10.100.23.195",
        "meters":[
            {
                "name":"1502.PBntwBtBl8.A1.zfixedsetGetByScoreMiss.meter",
                "count":34,
                "m15_rate":0.000704600257957628,
                "m1_rate":2.3078927890808079e-23,
                "m5_rate":0.0000012850722312153454,
                "mean_rate":0.0016760488045125888,
                "units":"events/second"
            }
        ],
        "timers":[
            {
                "name":"1502.PBntwBtBl8.A1.incrBy.timer",
                "count":488,
                "max":0,
                "mean":0.0005691203463114754,
                "min":0,
                "p50":0.0002616745,
                "p75":0.00029114925,
                "p95":0.00034554845000000004,
                "p98":0.0004745816799999999,
                "p99":0.0005644768200000001,
                "p999":0.14631544700000002,
                "stddev":0.006611449136952798,
                "m15_rate":0.03668855431573927,
                "m1_rate":0.009391558374931084,
                "m5_rate":0.03702271661734353,
                "mean_rate":0.02271881570776875,
                "duration_units":"seconds",
                "rate_units":"calls/second"
            }
        ]
    }]
	*/
	std::map<std::string,MetricRegistryPtr>::iterator it = map_registry_.begin();
	
	yajl_gen                  g;
	size_t					  len;
	const unsigned char		  *buf;
			    
	g = yajl_gen_alloc(NULL);
	if (g == NULL) {
		return -1;
	}
	
	yajl_gen_config(g, yajl_gen_beautify, 1);

	yajl_gen_array_open(g);

	for( ; it != map_registry_.end(); ++it ) {
		
		yajl_gen_map_open(g);

		yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_SYSNAME, strlen(QKPACK_METRICS_SYSNAME));
		yajl_gen_string(g, (const unsigned char *) it->first.c_str(), it->first.length());

		MetricRegistryPtr &registry = it->second;
		MeteredMap meter_map(registry->GetMeters());
		TimerMap timer_map(registry->GetTimers());

		if ( meter_map.size() ) {
			//meters array

			yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS, strlen(QKPACK_METRICS_METERS));
			yajl_gen_array_open(g);

    	    BOOST_FOREACH(const MeteredMap::value_type& entry, meter_map) {

				yajl_gen_map_open(g);
			
				yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_NAME, strlen(QKPACK_METRICS_METERS_NAME));
				yajl_gen_string(g, (const unsigned char *) entry.first.c_str(), entry.first.length());
		
    	        PrintMeter(entry.second,g);
				
				yajl_gen_map_close(g);
    	    }

			yajl_gen_array_close(g);
		}

		if ( timer_map.size() ) {
			//meters array
			
			yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS, strlen(QKPACK_METRICS_TIMERS));
			yajl_gen_array_open(g);

    	    BOOST_FOREACH(const TimerMap::value_type& entry, timer_map) {
				
				yajl_gen_map_open(g);
				
				yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_NAME, strlen(QKPACK_METRICS_TIMERS_NAME));
				yajl_gen_string(g, (const unsigned char *) entry.first.c_str(), entry.first.length());
				
				PrintTimer(entry.second,g);
				
				yajl_gen_map_close(g);
    	    }
			yajl_gen_array_close(g);
		}

		yajl_gen_map_close(g);
	}
	
	yajl_gen_array_close(g);

	yajl_gen_status status = yajl_gen_get_buf(g, &buf, &len);
	if(status != yajl_gen_status_ok) {
		yajl_gen_free(g);
		return -1;
	}
	 
	std::string data =  std::string((const char*)buf,len);
	yajl_gen_free(g);

	if ( !len ) {
		return -1;
	}

	EasyCurl	m_curl;

	std::vector<std::string>			headers;
	headers.push_back("Content-Type: application/json");
	
	int code = m_curl.Post("http://dpm.1verge.net/httpServer/reception/json", headers, data);

	if (code != CURLE_OK) {
		//QKPACK_LOG_ERROR("qkpack metrics post is error code=[%d]",code);
		return -1;
	}

	return 0;
}


void QkPackMetrics::PrintMeter(const MeteredMap::mapped_type& meter, yajl_gen  &g) 
{

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_COUNT, strlen(QKPACK_METRICS_METERS_COUNT));
	yajl_gen_integer(g, meter->GetCount());

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_M1_RATE, strlen(QKPACK_METRICS_METERS_M1_RATE));
	yajl_gen_double(g, ConvertRateUnit(meter->GetOneMinuteRate()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_M15_RATE, strlen(QKPACK_METRICS_METERS_M15_RATE));
	yajl_gen_double(g, ConvertRateUnit(meter->GetFifteenMinuteRate()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_M5_RATE, strlen(QKPACK_METRICS_METERS_M5_RATE));
	yajl_gen_double(g, ConvertRateUnit(meter->GetFiveMinuteRate()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_MEAN_RATE, strlen(QKPACK_METRICS_METERS_MEAN_RATE));
	yajl_gen_double(g, ConvertRateUnit(meter->GetMeanRate()));
	
	const char* units = RateUnitInSecMeter();
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_METERS_UNITS, strlen(QKPACK_METRICS_METERS_UNITS));
	yajl_gen_string(g, (const unsigned char *) units, strlen(units));

}

void QkPackMetrics::PrintTimer(const TimerMap::mapped_type& timer, yajl_gen &g) 
{
	SnapshotPtr snapshot = timer->GetSnapshot();

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_COUNT, strlen(QKPACK_METRICS_TIMERS_COUNT));
	yajl_gen_integer(g, timer->GetCount());

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_MAX, strlen(QKPACK_METRICS_TIMERS_MAX));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->GetMax()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_MEAN, strlen(QKPACK_METRICS_TIMERS_MEAN));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->GetMean()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_MIN, strlen(QKPACK_METRICS_TIMERS_MIN));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->GetMin()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P50, strlen(QKPACK_METRICS_TIMERS_P50));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->GetMedian()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P75, strlen(QKPACK_METRICS_TIMERS_P75));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->Get75thPercentile()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P95, strlen(QKPACK_METRICS_TIMERS_P95));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->Get95thPercentile()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P98, strlen(QKPACK_METRICS_TIMERS_P98));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->Get98thPercentile()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P99, strlen(QKPACK_METRICS_TIMERS_P99));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->Get99thPercentile()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_P999, strlen(QKPACK_METRICS_TIMERS_P999));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->Get999thPercentile()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_STDDEV, strlen(QKPACK_METRICS_TIMERS_STDDEV));
	yajl_gen_double(g, ConvertDurationUnit(snapshot->GetStdDev()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_MEAN_RATE, strlen(QKPACK_METRICS_TIMERS_MEAN_RATE));
	yajl_gen_double(g, ConvertRateUnit(timer->GetMeanRate()));
	
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_M1_RATE, strlen(QKPACK_METRICS_TIMERS_M1_RATE));
	yajl_gen_double(g,  ConvertRateUnit(timer->GetOneMinuteRate()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_M5_RATE, strlen(QKPACK_METRICS_TIMERS_M5_RATE));
	yajl_gen_double(g,  ConvertRateUnit(timer->GetFiveMinuteRate()));

	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_M15_RATE, strlen(QKPACK_METRICS_TIMERS_M15_RATE));
	yajl_gen_double(g,  ConvertRateUnit(timer->GetFifteenMinuteRate()));
	

	const char *duration = DurationUnitInSec();
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_DURATION_UNITS, strlen(QKPACK_METRICS_TIMERS_DURATION_UNITS));
	yajl_gen_string(g, (const unsigned char *) duration, strlen(duration));
	
	const char *rate = RateUnitInSec();
	yajl_gen_string(g, (const unsigned char *) QKPACK_METRICS_TIMERS_RATE_UNITS, strlen(QKPACK_METRICS_TIMERS_RATE_UNITS));
	yajl_gen_string(g, (const unsigned char *) rate, strlen(rate));
}


double QkPackMetrics::ConvertDurationUnit(double duration) const
{
    return duration * duration_factor_;
}


double QkPackMetrics::ConvertRateUnit(double rate) const
{
    return rate * rate_factor_;
}


const char* QkPackMetrics::RateUnitInSecMeter() {
		
	int64_t unit_count = rate_unit_.count();

	if (unit_count >= one_day ) {
		return "events/day";
	} else if (unit_count >= one_hour) {
		return "events/hour";
	} else if (unit_count >= one_minute) {
		return "events/minute";
	} else if (unit_count >= one_seconds) {
		return "events/second";
	} else if (unit_count >= one_millisecond) {
		return "events/millisecond";
	}

	return "events/microsecond";
}


const char* QkPackMetrics::RateUnitInSec() {
		
	int64_t unit_count = rate_unit_.count();

	if (unit_count >= one_day ) {
		return "calls/day";
	} else if (unit_count >= one_hour) {
		return "calls/hour";
	} else if (unit_count >= one_minute) {
		return "calls/minute";
	} else if (unit_count >= one_seconds) {
		return "calls/second";
	} else if (unit_count >= one_millisecond) {
		return "calls/millisecond";
	}

	return "calls/microsecond";
}


const char* QkPackMetrics::DurationUnitInSec() 
{	
	int64_t unit_count = duration_unit_.count();

	if (unit_count >= one_day ) {
		return "day";
	} else if (unit_count >= one_hour) {
		return "hour";
	} else if (unit_count >= one_minute) {
		return "minute";
	} else if (unit_count >= one_seconds) {
		return "seconds";
	} else if (unit_count >= one_millisecond) {
		return "millisecond";
	}

	return "microsecond";
}


