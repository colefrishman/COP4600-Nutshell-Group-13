#ifndef GLOBAL_H
#define GLOBAL_H
#include <limits.h>
#include <map>
#include <string>
#include <vector>
#include <utility>

extern std::map<std::string, std::string> aliasTable;

extern std::map<std::string, std::string> nestedAliases;

std::string decipherAlias(std::string aliasText);

void setNestedVal(std::string s);

bool checkCycle(std::string s, std::string val);

extern std::vector<std::string> path_array;

void updatePath();

int run_pipe(int from, int to);
int run_all_pipes();


struct CommandTable{
	char* name[100];
	int argnum[100];
	char** args[100];
	int input[100];
	int output[100];

	int numPipes;
	std::pair<int, int> pipes[100];

	int idx;
};

int run_word(char* w, char** args);

#endif