.PHONY: all test


all:
	./util/lua-releng

test: all
	resty t/decode.lua
