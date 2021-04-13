#include "global.h"
#include <string>
#include <vector>
#include <iostream>

void updatePath(){
	path_array.clear();
	std::string p = std::string(getenv("PATH"));

	char delimiter = ':';
	while(p[p.size()-1] == delimiter){ p = p.substr(0,p.size()-2); }
	while(p[0] == delimiter){ p = p.substr(1); }


	while((p.find(delimiter)>=0 && p.find(delimiter)<p.size())){
		
		path_array.push_back('/'+(std::string) p.substr(0,p.find(delimiter))+'/');
		p = p.substr(p.find(delimiter)+2);
	}
	
	if(p.size()>0){
		path_array.push_back((std::string) p.substr(0,p.find(delimiter)));
	}
}

bool is_alias(char* str){
	if(aliasTable.find(std::string(str))==aliasTable.end()){
		return false;
	}
	return true;
}

char* get_alias(char* str){
	char* s = new char[100];
	strcpy(s, aliasTable[std::string(str)].c_str());
	return s;
}