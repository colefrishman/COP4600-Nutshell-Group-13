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
#include <fcntl.h>
#include <sys/wait.h>

char* printenv_text = "printenv";
char* alias_text = "alias";
//#define YYSTYPE char*

int yylex(void); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	std::cout << RED << "Error: "<< DEFAULT << e << std::endl;
	yyparse();
}


int run_cd();
int run_cd(char* dir);
int add_word(char* w, std::vector<char*>* args);
int run_word(char* w, char** args, bool background);
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
%token <char*> WORD NEWLINE CD PRINTENV SETENV WHITESPACE UNSETENV ALIAS UNALIAS PIPE AMPERSAND LEFTAB RIGHTAB DOUBLERIGHTAB ERRTO ERRTOOUT
%nterm <std::vector<char*>*> args_list
%nterm <int> input
%nterm <int> command
%nterm <int> pipe_list

%%

input:
	%empty {}
	| pipe_list AMPERSAND NEWLINE {tab.bg=1; return 1;}
	| pipe_list NEWLINE {tab.bg=0; return 1;}
	| command NEWLINE {return 1;}
	| NEWLINE {return 1;}

pipe_list:
	pipe_list ERRTO WORD {$$ = $1; tab.err_re = 2;}
	| pipe_list ERRTOOUT {$$ = $1; tab.err_re=1;}
	| pipe_list DOUBLERIGHTAB WORD {$$ = $1; tab.output_file = $3; tab.output_re = 2;}
	| pipe_list RIGHTAB WORD {$$ = $1; tab.output_file = $3; tab.output_re = 1;}
	| pipe_list LEFTAB WORD {$$ = $1; tab.input_file = $3; tab.input_re = 1;}
	| pipe_list PIPE WORD args_list {$$ = add_pipe($1, add_word($3, $4));}
	| ALIAS	{$$ = add_word("alias", new std::vector<char*>);}
	| PRINTENV	{$$ = add_word("printenv", new std::vector<char*>);}
	| WORD args_list {$$ = add_word($1, $2);}
	
command:	/* empty */
	ALIAS WORD WORD 		{$$ = -1; run_alias($2, $3);}
	| UNALIAS WORD 			{$$ = -1; run_unalias($2);}
	| SETENV WORD WORD 		{$$ = -1; run_setenv($2, $3);}
	| UNSETENV WORD 		{$$ = -1; run_unsetenv($2);}
	| CD WORD 				{$$ = -1; run_cd($2);}
	| CD 					{$$ = -1; run_cd();}


args_list:
	%empty {$$ = new std::vector<char*>;}
	| WORD {$$ = new std::vector<char*>; $$->push_back($1);}
	| args_list WORD {$$=$1; $$->push_back($2);}
%%

int run_cd(){
	chdir(getenv("HOME"));
	return 1;
}
int run_cd(char* dir){
	chdir(dir);
	return 1;
}


int add_pipe(int from, int to){
	tab.pipes[tab.numPipes] = std::pair<int, int>(from, to);
	tab.numPipes = tab.numPipes+1;
	return to;
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

	bool exists;
	struct stat st;
	bool exec = false;
	char s_from[100][100];
	char s_to[100][100];

	for(int j=0; j<n; ++j){
		for (int i=0; i<path_array.size(); ++i){ 
			strcpy(s_from[j], path_array[i].c_str());
			strcat(s_from[j], w_from[j]);
			if (stat((const char*) s_from[j], &st)==0) { break; }
			if (strcmp(w_from[j],printenv_text)==0 || strcmp(w_from[j],alias_text)==0){break;}
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
	if(tab.input_re){
		auto in = open(tab.input_file, O_RDONLY);
		dup2(in,STDIN_FILENO);
		close(in);
	}
	for(int i = 0; i<n; ++i){
		//std::cout << "here " << s_from[i] << " to " << s_to[i] << " : " << i << "/" << n << std::endl;
		if(pipe(fd) == -1){
			std::cout << "pipe error" << std::endl;
			return -1;
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

			if(strcmp(w_from[i], printenv_text)==0){
				run_printenv();
				exit(1);
			}
			else if(strcmp(w_from[i], alias_text)==0){
				run_alias();
				exit(1);
			}
			else{
				execv(s_from[i], args_from[i]);
			}
		}

		close(fd[1]);
			
		inp = fd[0];
	}
	if(tab.output_re==1){
		outp = open(tab.output_file, O_WRONLY|O_CREAT, 0777);
		dup2(outp, STDOUT_FILENO);
		close(outp);
	}
	if(tab.output_re==2){
		outp = open(tab.output_file, O_WRONLY|O_APPEND|O_CREAT, 0777);
		dup2(outp, STDOUT_FILENO);
		close(outp);
	}
	if(tab.err_re==1){
		dup2(STDOUT_FILENO, STDERR_FILENO);
		close(outp);
	}
	if(tab.err_re==2){
		outp = open(tab.output_file, O_WRONLY|O_APPEND|O_CREAT, 0777);
		dup2(outp, STDERR_FILENO);
		close(outp);
	}
	if (inp != 0){
    	dup2 (inp, 0);
		if(strcmp(w_to[n-1], printenv_text)==0){
			run_printenv();
			exit(1);
		}
		else if(strcmp(w_to[n-1], alias_text)==0){
			run_alias();
			exit(1);
		}
		else{
			execv(s_to[n-1], args_to[n-1]);
		}
	}
	return 1; 
}

int run_word(char* w, char** args, bool background)
{
	updatePath();
	struct stat st;
	bool exec = false;
	char s[100];
	bool exists = false;


	for (int i=0; i<path_array.size(); ++i){ 
		strcpy(s, path_array[i].c_str());
		strcat(s, w);
		if (stat((const char*) s, &st)==0){ exists=true; break;}
	}
	exists = exists || (strcmp(w, printenv_text)==0) || (strcmp(w, alias_text)==0);
	if(!exists){
		std::cout<<"Command "<<w<<" not found"<<std::endl;
		return -1;
	}
			int pid = fork();

			if (pid == 0)
			{
				if(tab.input_re){
					auto in = open(tab.input_file, O_RDONLY);
					dup2(in,STDIN_FILENO);
					close(in);
				}
				if(tab.output_re==1){
					auto out = open(tab.output_file, O_WRONLY|O_CREAT, 0777);
					dup2(out,STDOUT_FILENO);
					close(out);
				}
				if(tab.output_re==2){
					auto out = open(tab.output_file, O_WRONLY|O_APPEND|O_CREAT, 0777);
					dup2(out,STDOUT_FILENO);
					close(out);
				}
				if(tab.err_re==1){
					dup2(STDOUT_FILENO, STDERR_FILENO);
				}
				if(tab.err_re==2){
					auto outp = open(tab.output_file, O_WRONLY|O_APPEND|O_CREAT, 0777);
					dup2(outp, STDERR_FILENO);
					close(outp);
				}

				if(strcmp(w, printenv_text)==0){
					run_printenv();
					exit(1);
				}
				else if(strcmp(w, alias_text)==0){
					run_alias();
					exit(1);
				}
				else{
					execv(s, args);
				}
			}
			else if(!background){
				int status;
    			waitpid(pid, &status, 0);
			}
			exec = true;
		
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
	updatePath();
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
		std::cout << RED "Error: " << "alias cannot equal command" << std:: endl;
		return 1;
	}
	
	
	//if nested key is val 
	if (checkCycle(name, val))
	{
		std::cout << RED "Error: " << "Would create long cycle infinite loop" << std::endl;
		return 1;
	}
	
	
	for (auto it=aliasTable.begin(); it!=aliasTable.end(); ++it)
	{
		if (std::string(name) == it->second && std::string(val) == it->first)
		{
			std::cout << RED "Error: " << "cannot create vice versa alias" << std::endl;
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
	if(strcmp(var,"PATH")==0){
		std::cout<<RED<<"ERROR: "<<DEFAULT<<"cannot unsetenv PATH." << std::endl;
	}
	else if(strcmp(var,"HOME")==1){
		std::cout<<RED<<"ERROR: "<<DEFAULT<<"cannot unsetenv HOME." << std::endl;
	}
	else{
		unsetenv(var);
	}
	return 1;
}