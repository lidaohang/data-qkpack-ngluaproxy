#ifndef __UTILS_H__
#define __UTILS_H__

#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/date_time/time_facet.hpp>
#include "metrics/types.h"

namespace com { 
namespace youku { 
namespace data {
namespace qkpack {
namespace metrics {

inline boost::posix_time::time_duration get_duration_from_epoch() {
    boost::posix_time::ptime time_t_epoch(boost::gregorian::date(1970, 1, 1));
    boost::posix_time::ptime now =
            boost::posix_time::microsec_clock::local_time();
    return (now - time_t_epoch);
}

inline boost::uint64_t get_millis_from_epoch() {
    return get_duration_from_epoch().total_milliseconds();
}

inline boost::uint64_t get_seconds_from_epoch() {
    return get_duration_from_epoch().total_seconds();
}

inline std::string utc_timestamp(const std::locale& current_locale) {
    std::ostringstream ss;
    // assumes std::cout's locale has been set appropriately for the entire app
    boost::posix_time::time_facet* t_facet(new boost::posix_time::time_facet());
    t_facet->time_duration_format("%d-%M-%y %H:%M:%S%F %Q");
    ss.imbue(std::locale(current_locale, t_facet));
    ss << boost::posix_time::microsec_clock::universal_time();
    return ss.str();
}

} /* namespace metrics */
} /* namespace qkpack */
} /* namespace data */
} /* namespace youku */
} /* namespace com */

#endif /* __UTILS_H__ */

