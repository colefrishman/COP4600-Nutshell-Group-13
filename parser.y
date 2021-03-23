%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define YYSTYPE char*

int yylex(); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}
%}

%token WORD META
%token UNDEFINED

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:
	  %empty
	| input command { printf($2);
	} ;

command:
	WORD;

