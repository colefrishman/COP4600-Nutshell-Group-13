%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

//#define YYSTYPE char*

int yylex(); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}

int run_cd();
int run_word(char* w);
int run_printenv();
%}

%union {
    char *string;
}

%start input
%token <string> WORD META NEWLINE CD PRINTENV
%token UNDEFINED

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:	/* empty */
    | PRINTENV NEWLINE {run_printenv();}
    | WORD NEWLINE {run_word($1);}
	| CD NEWLINE {run_cd();};

%%

int run_cd(){
	printf("home\n"); return 1;
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