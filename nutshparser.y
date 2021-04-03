%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <string>
#include <iostream>
#include "global.h"

//#define YYSTYPE char*

int yylex(void); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}

int run_cd(char* dir = getenv("HOME"));
int run_word(char* w);
int run_printenv();
int run_setenv(char* var, char* val);
int run_unalias(char* a);
int run_alias();
int run_alias(char* name, char* val);
int run_unsetenv(char* var);
%}

%union {
    char *string;
}

%start input
%token <string> WORD NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:	/* empty */
	ALIAS WORD WORD NEWLINE {run_alias($2, $3);}
	| ALIAS NEWLINE {run_alias();}
	| UNALIAS WORD NEWLINE {run_unalias($2);}
	| SETENV WORD WORD NEWLINE {run_setenv($2, $3);}
	| UNSETENV WORD NEWLINE {run_unsetenv($2);}
    | PRINTENV NEWLINE {run_printenv();}
	| CD WORD NEWLINE {run_cd($2);}
	| CD NEWLINE {run_cd();}
    | WORD NEWLINE {run_word($1);}

%%

int run_cd(char* dir){
	chdir(dir);
	return 1;
}

int run_word(char* w){
	printf("%s\n", w); return 1;
}

int run_printenv(){
    extern char **environ;

    for (char **v = environ; *v!=nullptr; ++v) {
        printf("%s\n", *v);
    }
	return 1;
}

int run_setenv(char* var, char* val){
	setenv(var, val, 1);
	return 1;
}

int run_alias(){
	std::cout << "Alias Table:" << std::endl;
	for(auto iterator=aliasTable.begin();iterator!=aliasTable.end();++iterator){
		std::cout << iterator->first << " = " << iterator->second << std::endl;
	}
	return 1;
}

int run_alias(char* name, char* val){
	aliasTable[std::string(name)] = std::string(val);
	return 1;
}

int run_unalias(char* a){
	aliasTable.erase(std::string(a));
	return 1;
}

int run_unsetenv(char* var){
	unsetenv(var);
	return 1;
}