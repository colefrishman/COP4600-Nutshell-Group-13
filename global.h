#ifndef GLOBAL_H
#define GLOBAL_H
#include <limits.h>
#include <map>
#include <string>

extern std::map<std::string, std::string> aliasTable;

extern std::map<std::string, std::string> nestedAliases;

std::string decipherAlias(std::string aliasText);

void setNestedVal(std::string s);

bool checkCycle(std::string s, std::string val);

#endif