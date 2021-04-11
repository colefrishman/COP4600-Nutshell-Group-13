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
#include <sys/wait.h>

//#define YYSTYPE char*

int yylex(void); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);
}

int run_cd(char* dir = getenv("HOME"));
int add_word(char* w, std::vector<char*>* args);
int run_word(char* w, char** args, bool background);
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


%start input
%token <char*> WORD NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS PIPE AMPERSAND
%nterm <std::vector<char*>*> args_list
%nterm <int> input
%nterm <int> command
%nterm <int> pipe_list

%%

input:
	%empty {}
	| pipe_list AMPERSAND NEWLINE {tab.bg=1;return 1;}
	| pipe_list NEWLINE {tab.bg=0; return 1;}
	| command NEWLINE {return 1;}
	| NEWLINE {return 1;}

pipe_list:
	pipe_list PIPE WORD args_list {$$ = add_pipe($1, add_word($3, $4));}
	| WORD args_list {$$ = add_word($1, $2);}
	
command:	/* empty */
	ALIAS WORD WORD 		{$$ = -1; run_alias($2, $3); return 1;}
	| ALIAS 				{$$ = -1; run_alias(); return 1;}
	| UNALIAS WORD 			{$$ = -1; run_unalias($2); return 1;}
	| SETENV WORD WORD 		{$$ = -1; run_setenv($2, $3); return 1;}
	| UNSETENV WORD 		{$$ = -1; run_unsetenv($2); return 1;}
    | PRINTENV 				{$$ = -1; run_printenv(); return 1;}
	| CD WORD 				{$$ = -1; run_cd($2); return 1;}
	| CD 					{$$ = -1; run_cd(); return 1;}


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

int run_pipe(int from, int to)
{
	updatePath();
	char* w_from = tab.name[from];
	char** args_from = tab.args[from];
	char* w_to = tab.name[to];
	char** args_to = tab.args[to];
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


int run_all_pipes(bool background){
	updatePath();
	int n = tab.numPipes;

	char* w_from[100];
	char** args_from[100];
	char* w_to[100];
	char** args_to[100];


	for(int i =0; i<n; ++i){
		w_from[i] = tab.name[tab.pipes[i].first];
		args_from[i] = tab.args[tab.pipes[i].first];
		w_to[i] = tab.name[tab.pipes[i].second];
		args_to[i] = tab.args[tab.pipes[i].second];
	}

	struct stat st;
	bool exec = false;
	char s_from[100][100];
	char s_to[100][100];

	for(int j=0; j<n; ++j){
		for (int i=0; i<path_array.size(); ++i){ 
			strcpy(s_from[j], path_array[i].c_str());
			strcat(s_from[j], w_from[j]);
			if (stat((const char*) s_from[j], &st)==0) { break; }
		}
	}
	for(int j=0; j<n; ++j){
		for (int i=0; i<path_array.size(); ++i){ 
			strcpy(s_to[j], path_array[i].c_str());
			strcat(s_to[j], w_to[j]);
			if (stat((const char*) s_to[j], &st)==0) { break; }
		}
	}

	pid_t pid = fork();
	if(pid != 0){
		if(!background){
			int status;
    		waitpid(pid, &status, 0);
		}
		return 1;
	}

	int fd[2];
	int inp = 0;
	int outp;
	for(int i = 0; i<n; ++i){
		//std::cout << "here " << s_from[i] << " to " << s_to[i] << " : " << i << "/" << n << std::endl;
		if(pipe(fd) == -1){
			std::cout << "pipe error" << std::endl;
		}
		outp = fd[1];
		pid = fork();
		if(pid==0){
			if (inp != 0)
			{
				dup2(inp, 0);
   				close(inp);
			}
			if(outp!=1){
				dup2(outp, 1);
   				close(outp);
			}

			execv(s_from[i], args_from[i]);
		}
				
		close(fd[1]);
			
		inp = fd[0];
	}
	if (inp != 0){
    	dup2 (inp, 0);
		execv(s_to[n-1], args_to[n-1]);
	}
	return 1; 
}

int run_word(char* w, char** args, bool background)
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
			else if(!background){
				int status;
    			waitpid(pid, &status, 0);
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