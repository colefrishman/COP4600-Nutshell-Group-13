
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "helper.h"


int run_printenv(){
    extern char **environ;
    char **s = environ;

    for (; *s; s++) {
        printf("%s\n", *s);
    }
    return 1;
}

int run_cd(){
	printf("home\n"); return 1;
}

int run_word(char* w){
	printf("%s\n", w); return 1;
}