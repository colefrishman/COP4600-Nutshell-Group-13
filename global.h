#ifndef GLOBAL_H
#define GLOBAL_H
#include <limits.h>
#include <map>
#include <string>

extern std::map<std::string, std::string> aliasTable;

std::string decipherAlias(std::string aliasText);

#endif