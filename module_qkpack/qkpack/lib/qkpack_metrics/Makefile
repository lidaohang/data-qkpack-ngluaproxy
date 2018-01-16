#--------------------------------------------------------------------
ifeq ($(GCOV_ON),1)
GCOV= -ftest-coverage -fprofile-arcs -lgcov
endif

CC = gcc
CXX = g++
AR = ar cru
CFLAGS = -Wall -D_REENTRANT -D_GNU_SOURCE -g -fPIC $(GCOV)
SOFLAGS = -shared

INC = -Iinc -Isrc -I/usr/local/openresty/luajit/include/luajit-2.1/
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
		-lz -lpthread -ldl \
		-lboost_timer -lboost_chrono -lboost_system -lboost_filesystem -lboost_thread -lboost_date_time -lpthread -lrt \
		-lcurl -lyajl -lstdc++  $(GCOV)


QKPACK = libqkpack_metrics
QKPACK_A = $(LIB)/$(QKPACK).a
QKPACK_SO = $(LIB)/$(QKPACK).so

EXE = $(BIN)/qkpack_test

#--------------------------------------------------------------------

LIBOBJS =  $(SRC)/core/lua_metrics.o \
	   $(SRC)/core/qkpack_metrics.o \
	   $(SRC)/config/easycurl.o \
	   $(SRC)/metrics/uniform_sample.o \
	   $(SRC)/metrics/timer_context.o \
	   $(SRC)/metrics/timer.o \
	   $(SRC)/metrics/snapshot.o \
	   $(SRC)/metrics/metric_registry.o \
	   $(SRC)/metrics/ewma.o \
	   $(SRC)/metrics/meter.o \
	   $(SRC)/metrics/histogram.o \
	   $(SRC)/metrics/exp_decay_sample.o
	

TARGET = $(QKPACK_A)                     \
	 $(QKPACK_SO)                    


#--------------------------------------------------------------------
.PHONY: all clean install

all: $(TARGET)

$(QKPACK_SO): $(LIBOBJS)
	$(CXX) $(LDFLAGS) $(SOFLAGS) $^ -o $@

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
