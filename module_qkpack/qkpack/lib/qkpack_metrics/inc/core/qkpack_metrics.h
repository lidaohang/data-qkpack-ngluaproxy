#ifndef __QKPACK_METRICS_H__
#define __QKPACK_METRICS_H__

#include "metrics/reporter.h"

extern "C" {
#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>
#include <yajl/yajl_tree.h>
}

using namespace com::youku::data::qkpack::metrics;

namespace com { 
namespace youku { 
namespace data {
namespace qkpack {
namespace core {
	

class QkPackMetrics : public Reporter 
{
public:
    QkPackMetrics(bool metrics_status,
			boost::chrono::milliseconds rate_unit = boost::chrono::seconds(1),
			boost::chrono::milliseconds duration_unit = boost::chrono::seconds(1));
	virtual ~QkPackMetrics();
	
public:
	/**
     * 
     * 构建metrics 信息
    */
	virtual int Report();
	
	void QKPackTimer(const std::string &metrics_name, const std::string &timer_name);
	
	void QKPackMeter(const std::string &metrics_name, const std::string &meter_name);

	int TimerStop();
	
	/**
	 * 
	 * Metrics埋点(GET,SMEMBERS)Miss
	 * 
	*/
	void CheckUserSceneMetricsMissGetAndSmembers();


	/**
	 * 
	 * Metrics埋点(MGET,ZRANGE)Miss
	 * 
	*/
	void CheckUserSceneMetricsMissMgeAndZRange();

protected:
	/**
     * 
     * 用户场景metric registry
    */
	MetricRegistryPtr QKPackMetricRegistry(const std::string &registry_name);


	double ConvertDurationUnit(double duration_value) const;
	
    double ConvertRateUnit(double rate_value) const;
	
	const char* RateUnitInSecMeter();
	
	const char* RateUnitInSec();
	
	const char* DurationUnitInSec(); 

private:
	void PrintMeter(const MeteredMap::mapped_type& meter, yajl_gen &g); 
	void PrintTimer(const TimerMap::mapped_type& timer, yajl_gen &g); 
	
	bool metrics_status_;
	boost::chrono::milliseconds rate_unit_;
	boost::chrono::milliseconds duration_unit_;
	double rate_factor_;
    double duration_factor_;

	std::map<std::string,MetricRegistryPtr> map_registry_;
	std::vector<TimerContextPtr> vector_timer_;
};

}
}
}
}
}

#endif /* __QKPACK_METRICS_H__ */
