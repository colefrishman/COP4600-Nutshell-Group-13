%{
#include <stdio.h>

int yylex(); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}
%}

%token INTEGER_LITERAL NULL_LITERAL
%token UNDEFINED

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:
	  %empty
	| input object { printf("int"); } ;

object:
		INTEGER_LITERAL
	| NULL_LITERAL ;

	/*
	A comma-separated list. Three different patterns here now, to represent
	lists with no items, one item, or multiple items.
	*/
