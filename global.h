#ifndef GLOBAL_H
#define GLOBAL_H
#include <limits.h>
#include <map>
#include <string>
#include <vector>
#include <string.h>
#include <utility>
#define DEFAULT "\x1B[0m"
#define BLACK 	"\x1B[30m"
#define RED 	"\x1B[31m"
#define GREEN	"\x1B[32m"
#define YELLOW	"\x1B[33m"
#define BLUE	"\x1B[34m"
#define MAGENTA	"\x1B[35m"
#define CYAN 	"\x1B[36m"
#define WHITE 	"\x1B[37m"
#define	RESET	"\e[0m"
#define BOLD 	"\e[1m"
#define ITALIC 	"\e[3m"
#define UNDER	"\e[4m"

extern std::map<std::string, std::string> aliasTable;

extern std::map<std::string, std::string> nestedAliases;

std::string decipherAlias(std::string aliasText);

void setNestedVal(std::string s);

bool checkCycle(std::string s, std::string val);

extern std::vector<std::string> path_array;

void updatePath();

int run_all_pipes(bool background);

struct CommandTable{
	char* name[100];
	int argnum[100];
	char** args[100];
	char* input_file;
	char* output_file;
	char err_file[100];
	bool bg;

	bool input_re;
	unsigned char output_re;
	unsigned char err_re;

	int numPipes;
	std::pair<int, int> pipes[100];

	int idx;
};

int run_word(char* w, char** args, bool background);

std::string replaceTilde(std::string y);

bool is_alias(char* str);

char* get_alias(char* str);

#endif