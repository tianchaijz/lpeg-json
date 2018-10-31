CC= gcc
CCOPT= -O3 -std=c99 -Wall -pedantic -fomit-frame-pointer -Wall -DNDEBUG

.PHONY: all test

all: libutf8.so

test: all
	./util/lua-releng
	resty t/decode.lua

libutf8.so: util/utf8.c
	$(CC) $(CCOPT) -fPIC -shared $< -o $@
