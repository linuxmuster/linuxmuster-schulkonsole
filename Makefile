include common.mk

SUBDIRS = po src/util Schulkonsole

build:
	for d in $(SUBDIRS); do           \
	    (cd $$d;                      \
	    make "CFLAGS=$(CFLAGS)"       \
	        "LDFLAGS=$(LDFLAGS)"      \
	        "LIBFLAGS=$(LIBFLAGS)")   \
	done

install:
	for d in $(SUBDIRS); do             \
	    (cd $$d;                        \
	    make install "CFLAGS=$(CFLAGS)" \
	        "LDFLAGS=$(LDFLAGS)"        \
	        "LIBFLAGS=$(LIBFLAGS)")     \
	done

clean:
	for d in $(SUBDIRS); do \
	    (cd $$d;            \
	    make clean)         \
	done
