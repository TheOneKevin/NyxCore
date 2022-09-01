TESTS = arith pipeline
SV ?= 1

VERBOSE ?= 0
ifeq ($(VERBOSE),1)
COCOTB_REDUCED_LOG_FMT = 1
else
COCOTB_REDUCED_LOG_FMT = 0
endif

all: ${TESTS}
	for i in ${TESTS}; do \
		( cd $$i && make all SV=${SV} COCOTB_REDUCED_LOG_FMT=${COCOTB_REDUCED_LOG_FMT} ) ; \
	done

clean: ${TESTS}
	for i in ${TESTS}; do \
		( cd $$i && make clean ) ; \
	done
	rm -rf __pycache__
