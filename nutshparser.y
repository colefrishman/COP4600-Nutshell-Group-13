%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <string>
#include <iostream>
#include "global.h"
#include <dirent.h>
#include <vector>
#include <sys/stat.h>

//#define YYSTYPE char*

int yylex(void); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}

int run_cd(char* dir = getenv("HOME"));
int add_word(char* w, std::vector<char*>* args);
int run_word(char* w, char** args);
int run_printenv();
int run_setenv(char* var, char* val);
int run_unalias(char* a);
int run_alias();
int run_alias(char* name, char* val);
int run_unsetenv(char* var);

CommandTable tab;
%}

%code requires {
	
#include <vector>
}

%define api.value.type union


%start input
%token <char*> WORD NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS
%nterm <std::vector<char*>*> args_list

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:	/* empty */
	ALIAS WORD WORD NEWLINE {run_alias($2, $3); return 1;}
	| ALIAS NEWLINE {run_alias(); return 1;}
	| UNALIAS WORD NEWLINE {run_unalias($2); return 1;}
	| SETENV WORD WORD NEWLINE {run_setenv($2, $3); return 1;}
	| UNSETENV WORD NEWLINE {run_unsetenv($2); return 1;}
    | PRINTENV NEWLINE {run_printenv(); return 1;}
	| CD WORD NEWLINE {run_cd($2); return 1;}
	| CD NEWLINE {run_cd(); return 1;}
    | WORD args_list NEWLINE {add_word($1, $2); return 1;}
    | WORD NEWLINE {add_word($1, new std::vector<char*>); return 1;}


args_list:
	%empty {$$ = new std::vector<char*>;}
	| WORD {$$ = new std::vector<char*>; $$->push_back($1);}
	| args_list WORD {$$=$1; $$->push_back($2);}
%%


int run_cd(char* dir){
	chdir(dir);
	return 1;
}

int run_word(char* w, char** args)
{
	char s[100] = "/usr/bin/";
	strcat(s, w);

	struct stat st;
			
	if (stat((const char*) s, &st)==0)
	{
		int pid = fork();

		if (pid == 0)
		{
			execv(s, args);
		}
	}

	return 1; 
}

int add_word(char* w, std::vector<char*>* args){	
	args->insert(args->begin(), w);
	args->push_back((char*) nullptr);
	tab.name[tab.idx]=w;
	tab.argnum[tab.idx] = args->size();
	tab.args[tab.idx] = args->data();
	++(tab.idx);
	return 1; 
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
	
	if (strcmp(name, val) == 0)
	{
		std::cout << "Error: alias cannot equal command" << std:: endl;
		return 1;
	}
	
	
	//if nested key is val 
	if (checkCycle(name, val))
	{
		std::cout << "Error: Would create long cycle infinite loop" << std::endl;
		return 1;
	}
	
	
	for (auto it=aliasTable.begin(); it!=aliasTable.end(); ++it)
	{
		if (std::string(name) == it->second && std::string(val) == it->first)
		{
			std::cout << "Error: cannot create vice versa alias" << std::endl;
			return 1;
		}
		else if (aliasTable[it->first] == std::string(name) || nestedAliases[it->first] == std::string(name))
		{
			std::cout << "entered" << std::endl;
			nestedAliases[it->first] = std::string(val);
			setNestedVal(it->first);
		}
	}
	
	std::cout << "Nested Aliases:" << std::endl;
	for (auto iter = nestedAliases.begin(); iter != nestedAliases.end(); ++iter)
	{
		if (std::string(name) == iter->first && !nestedAliases[iter->first].empty())
		{
			nestedAliases.erase(iter->first);
		}
		
		if (std::string(val) == iter->first)
		{
			nestedAliases[std::string(name)] = iter->second;
		}
		
		if (!nestedAliases[iter->first].empty())
		{
			std::cout << iter->first << " = " << iter->second << std::endl;
		}
	}

	aliasTable[std::string(name)] = std::string(val);
	return 1;
}

int run_unalias(char* a){
	
	aliasTable.erase(std::string(a));
	nestedAliases.erase(std::string(a));
	setNestedVal(a);
	return 1;
}

int run_unsetenv(char* var){
	unsetenv(var);
	return 1;
}