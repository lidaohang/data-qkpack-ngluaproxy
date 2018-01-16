#ifndef __ISNAPPYSTREAM_H__
#define __ISNAPPYSTREAM_H__

#include <iostream>
#include <vector>
#include "snappystreamcfg.h"
#include "snappy.h"


class iSnappyStreambuf: public std::streambuf
{
	public:
		explicit iSnappyStreambuf(std::streambuf *src);

	protected:
		virtual int_type underflow();

	protected:
		std::streambuf* src_;
		std::vector<char_type> in_buffer_;
		std::vector<char_type> out_buffer_;
};

class iSnappyStream: public std::istream {
public:
	explicit iSnappyStream(std::streambuf& inbuf);
	explicit iSnappyStream(std::istream& in);
private:
	iSnappyStreambuf isbuf_;
};



#endif // __ISNAPPYSTREAM_H__

