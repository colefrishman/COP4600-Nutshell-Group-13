# Simple Makefile

GPP=/usr/bin/g++

all:  bison-config flex-config nutshell

bison-config:
	bison -d nutshparser.y

flex-config:
	flex nutshscanner.l

nutshell: 
	$(GPP) nutshell.cpp global.cpp nutshparser.tab.c lex.yy.c -o nutshell

clean:
	rm nutshparser.tab.c nutshparser.tab.h lex.yy.c nutshell