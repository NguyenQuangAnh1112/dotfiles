CC ?= gcc
CFLAGS ?= -O2 -Wall -fPIC
LDFLAGS ?= -shared -ldl -lX11
TARGET = ../../lib/libunity-undecorate.so

all: $(TARGET)

$(TARGET): unity-undecorate.c
	mkdir -p ../../lib
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
