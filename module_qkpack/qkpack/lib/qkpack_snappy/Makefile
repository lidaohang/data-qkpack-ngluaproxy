#--------------------------------------------------------------------
ifeq ($(GCOV_ON),1)
GCOV= -ftest-coverage -fprofile-arcs -lgcov
endif

CC = gcc
CXX = g++
AR = ar cru
CFLAGS = -Wall -D_REENTRANT -D_GNU_SOURCE -g -fPIC $(GCOV)
SOFLAGS = -shared

INC = -Iinc -Isrc -I/usr/local/openresty/luajit/include/luajit-2.1/ -I/usr/local/include/
SYSINC = 
COMMON_INC=/usr/local/include/

SRC = src
LIB = lib
BIN = bin
TEST = test
TESTR = testr
CONF = conf

INCFLAGS = $(INC)             \
	   -I$(SYSINC) -I$(COMMON_INC) -I$(TEST)

CFLAGS += $(INCFLAGS)

LDFLAGS = -L/usr/local/lib/	-L$(LIB) \
		-lz -lpthread -ldl -lsnappy  -lstdc++  $(GCOV)

QKPACK = libqkpack_snappy
QKPACK_A = $(LIB)/$(QKPACK).a
QKPACK_SO = $(LIB)/$(QKPACK).so

EXE = $(BIN)/qkpack_test

#--------------------------------------------------------------------

LIBOBJS =  $(SRC)/osnappystream.o \
	   $(SRC)/snappystreamcfg.o \
	   $(SRC)/isnappystream.o \
	   $(SRC)/snappy_compress.o


TARGET = $(QKPACK_A)                     \
	 $(QKPACK_SO)                    


#--------------------------------------------------------------------
.PHONY: all clean install

all: $(TARGET)

$(QKPACK_SO): $(LIBOBJS)
	$(CXX) $(LDFLAGS)  $(SOFLAGS) $^ -o $@

$(QKPACK_A): $(LIBOBJS)
	$(AR) $@ $^

clean:
	rm -rf  $(LIBOBJS) $(TARGET) $(TESTOBJS) test-output/* 

#--------------------------------------------------------------------

# make rule

%.o : %.cpp
	$(CXX) $(CFLAGS) -c $^ -o $@
	
%.o : %.cc
	$(CXX) $(CFLAGS) -c $^ -o $@	
