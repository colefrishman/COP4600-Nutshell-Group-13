#include "global.h"
#include <string>
#include <vector>
#include <iostream>
#include <sys/types.h>
#include <pwd.h>

void updatePath(){
	path_array.clear();
	std::string p = std::string(getenv("PATH"));

	if(p.find(".:")==std::string::npos){
		p = ".:"+p;
	}

	char delimiter = ':';
	while(p[p.size()-1] == delimiter){ p = p.substr(0,p.size()-2); }
	while(p[0] == delimiter){ p = p.substr(1); }


	while((p.find(delimiter)>=0 && p.find(delimiter)<p.size())){
		std::string token = p.substr(0,p.find(delimiter));
		if(token!="."){
			path_array.push_back('/'+replaceTilde(token)+'/');
		}
		else{
			path_array.push_back("./");
		}
		p = p.substr(p.find(delimiter)+2);
	}
	if(p.size()>0){
		std::string token = p.substr(0,p.find(delimiter));
		path_array.push_back('/' + replaceTilde(token)+'/');
	}

	std::string path_string = "";
	for(int i=0; i<path_array.size()-1; ++i){
		path_string+=path_array[i].substr(0, path_array[i].size()-1)+':';
	}
	path_string+=path_array[path_array.size()-1].substr(0, path_array[path_array.size()-1].size()-1);

	setenv("PATH", path_string.c_str(), 1);
}

std::string replaceTilde(std::string y){
	if(y[0]!='~'){
		return y;
	}
	std::string after;
	std::string t = "";
	auto user_info = getpwnam("");
	if(y.size() == 1){
		t = std::string(getenv("HOME"));
	}
	else if(y.find('/')==std::string::npos){
		after = y.substr(1);
		user_info = getpwnam(after.c_str());
		if(user_info){
			t = std::string(user_info->pw_dir);
		}
	}
	else {
		after = y.substr(1);
		std::string user = after.substr(0, after.find('/'));
		std::string path2 = after.substr(after.find('/'));
		user_info = getpwnam(user.c_str());
		if(user_info){
			t = std::string(user_info->pw_dir) + path2;
		}
	}
	return t;
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