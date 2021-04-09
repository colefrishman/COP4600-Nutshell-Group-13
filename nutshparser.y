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
int run_pipe(char* w_from, char** args_from, char* w_to, char** args_to);
int run_printenv();
int run_setenv(char* var, char* val);
int run_unalias(char* a);
int run_alias();
int run_alias(char* name, char* val);
int run_unsetenv(char* var);
int add_pipe(int from, int to);
extern std::vector<std::string> path_array;

CommandTable tab;
%}

%code requires {
	
#include <vector>
}

%define api.value.type union


%start command
%token <char*> WORD NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS PIPE
%nterm <std::vector<char*>*> args_list
%nterm <int> input
%nterm <int> command

%%

input:
	%empty {}
	| command NEWLINE {$<int>$ = -1; return 1;}
	| input PIPE command NEWLINE {$<int>$ = add_pipe($1, $3); return 1;}
	| command PIPE command NEWLINE {$<int>$ = add_pipe($1, $3); return 1;}

command:	/* empty */
	ALIAS WORD WORD NEWLINE 		{$$ = -1; run_alias($2, $3); return 1;}
	| ALIAS NEWLINE 				{$$ = -1; run_alias(); return 1;}
	| UNALIAS WORD NEWLINE 			{$$ = -1; run_unalias($2); return 1;}
	| SETENV WORD WORD NEWLINE 		{$$ = -1; run_setenv($2, $3); return 1;}
	| UNSETENV WORD NEWLINE 		{$$ = -1; run_unsetenv($2); return 1;}
    | PRINTENV NEWLINE 				{$$ = -1; run_printenv(); return 1;}
	| CD WORD NEWLINE 				{$$ = -1; run_cd($2); return 1;}
	| CD NEWLINE 					{$$ = -1; run_cd(); return 1;}
    | WORD args_list NEWLINE		{$$ = add_word($1, $2); return 1;}
    | WORD NEWLINE					{$$ = add_word($1, new std::vector<char*>); return 1;}
	| WORD PIPE WORD NEWLINE {$$ = add_pipe(add_word($1, new std::vector<char*>), add_word($3, new std::vector<char*>)); return 1;}
	| WORD args_list PIPE WORD NEWLINE {$$ = add_pipe(add_word($1, $2), add_word($4, new std::vector<char*>)); return 1;}
	| WORD PIPE WORD args_list NEWLINE {$$ = add_pipe(add_word($1, new std::vector<char*>), add_word($3, $4)); return 1;}
	| WORD args_list PIPE WORD args_list NEWLINE {$$ = add_pipe(add_word($1, $2), add_word($4, $5)); return 1;}


args_list:
	%empty {$$ = new std::vector<char*>;}
	| WORD {$$ = new std::vector<char*>; $$->push_back($1);}
	| args_list WORD {$$=$1; $$->push_back($2);}
%%


int run_cd(char* dir){
	chdir(dir);
	return 1;
}


int add_pipe(int from, int to){
	tab.output[from] = to;
	tab.input[to] = from;
	tab.pipes[tab.numPipes] = std::pair<int, int>(from, to);
	tab.numPipes = tab.numPipes+1;
	return to;
}

int run_pipe(char* w_from, char** args_from, char* w_to, char** args_to)
{
	updatePath();
	struct stat st;
	bool exec = false;
	char s_from[100];
	char s_to[100];
	
	for (int i=0; i<path_array.size(); ++i){ 
		strcpy(s_from, path_array[i].c_str());
		strcat(s_from, w_from);
		if (stat((const char*) s_from, &st)==0) { break; }
	}

	for (int i=0; i<path_array.size(); ++i){ 
		strcpy(s_to, path_array[i].c_str());
		strcat(s_to, w_to);
		if (stat((const char*) s_to, &st)==0) { break; }
	}

		int pid = fork();

		int fd[2];
		if(pipe(fd) == -1){
			std::cout << "pipe error" << std::endl;
		}
		if (pid == 0)
		{
			pid = fork();
			if (pid == 0)
			{
				dup2(fd[1], STDOUT_FILENO);
    			close(fd[1]);
   				close(fd[0]);
				execv(s_from, args_from);
			}
			else{
				dup2(fd[0], STDIN_FILENO);
    			close(fd[1]);
   				close(fd[0]);
				execv(s_to, args_to);
			}
			exit(1);
		}
		exec = true;
	return 1; 
}

int run_word(char* w, char** args)
{
	updatePath();
	struct stat st;
	bool exec = false;
	char s[100];
	
	for (int i=0; i<path_array.size(); ++i){ 
		strcpy(s, path_array[i].c_str());
		strcat(s, w);
		if (stat((const char*) s, &st)==0)
		{
			int pid = fork();

			if (pid == 0)
			{
				execv(s, args);
			}
			exec = true;
			break;
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
	
	return tab.idx-1; 
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