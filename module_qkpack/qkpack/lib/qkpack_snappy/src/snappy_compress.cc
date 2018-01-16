#include "snappystream.h"

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


extern "C"
{	

/**
 * 
 * 压缩
 * 
*/
int qkpack_lua_compress(const unsigned char *src, size_t src_len,unsigned char **dest_buf,size_t *dest_len) 
{
	std::ostringstream					ostr;
	oSnappyStream						osnstrm(ostr);
	
	osnstrm << src;
	osnstrm.flush();
	ostr.flush();

	std::string  value = ostr.str();
	int	value_len = value.length();

	if ( !value_len  ) {
		return -1;
	}

	*dest_buf = (unsigned char*)malloc(value_len);
	if (*dest_buf == NULL) {     
		return -1;
	}
	memcpy(*dest_buf, value.c_str(), value_len);
	*dest_len = value_len;


	return 0;
}


/**
 * 
 * 解压
 * 
*/
bool qkpack_lua_uncompress(const unsigned char *src, size_t src_len,unsigned char **dest_buf,size_t *dest_len) 
{
	std::stringstream					ss;
	std::istringstream					isstr(std::string((const char*)src,src_len), std::ios_base::in);
	iSnappyStream						isnstrm(isstr);
	
	ss << isnstrm.rdbuf();
	ss.flush();
	
	std::string  value = ss.str();
	int	value_len = value.length();

	if ( !value_len  ) {
		return false;
	}

	*dest_buf = (unsigned char*)malloc(value_len);
	if (*dest_buf == NULL) {     
		return false;
	}
	memcpy(*dest_buf, value.c_str(), value_len);
	*dest_len = value_len;

	return true;
}


/**
 * 
 * 验证是否是压缩
 * 
*/
bool qkpack_lua_valid_compressed(const unsigned char *src) 
{
	if ( memcmp ((const char*)src,"snappy\0",7) == 0 ) {
		return true;
	}
	
	return false;
}

}

