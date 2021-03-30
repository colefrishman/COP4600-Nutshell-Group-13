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
int run_setenv(char* var, char* val);
int run_unsetenv(char* var);
%}

%union {
    char *string;
}

%start input
%token <string> WORD META NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS
%token UNDEFINED

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:	/* empty */
	| SETENV WHITESPACE WORD WHITESPACE WORD NEWLINE {run_setenv($3, $5);}
	| UNSETENV WHITESPACE WORD NEWLINE {run_unsetenv($3);}
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

int run_setenv(char* var, char* val){
	setenv(var, val, 1);
	return 1;
}

int run_unsetenv(char* var){
	unsetenv(var);
	return 1;
}