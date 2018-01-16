#ifndef __OSNAPPYSTREAM_H__
#define __OSNAPPYSTREAM_H__

#include <iostream>
#include <string>
#include <stdint.h>

#include "snappystreamcfg.h"


class oSnappyStreambuf: public std::streambuf
{
	public:
		explicit oSnappyStreambuf(std::streambuf* dest,
		                          size_t chunksize = Config::defaultChunkSize);
		virtual ~oSnappyStreambuf();
		void init();

	protected:
		virtual int_type overflow(int_type c = traits_type::eof());
		int writeBlock(const char * data,
		               std::streamsize& uncompressed_length,
		               std::streamsize& length,
		               bool compressed,
		               uint32_t cksum);
		virtual int  sync();

	private:
		std::streambuf*  dest_;
		bool             write_cksums_;
		char*            in_buffer_;
		std::string      out_buffer_;
		size_t           chunksize_;
};

class oSnappyStream: public std::ostream
{
	public:
		explicit oSnappyStream(std::streambuf& outbuf, unsigned chunksize =
				Config::defaultChunkSize);
		explicit oSnappyStream(std::ostream& out, unsigned chunksize =
				Config::defaultChunkSize);
		void init() { osbuf_.init(); }
	private:
		oSnappyStreambuf osbuf_;
};




#endif // __OSNAPPYSTREAM_H__

