#include "nutshparser.tab.h"
#include <string>
#include <iostream>
#include <unistd.h>
#include <limits.h>

using namespace std;

string get_intro(){
	char buf[PATH_MAX];
	getcwd(buf, PATH_MAX);
	string homedir = getenv("HOME");
	string dir = string(buf);
	if(homedir.compare(dir.substr(0,homedir.size())) == 0){
		dir = "~" + dir.substr(homedir.size());
	}
	string user = string(getenv("USER"));
	gethostname(buf, PATH_MAX);
	string host = string(buf);
	return user+'@'+host+':'+dir+"$ ";
}

int main() {
	while(1){
		cout << get_intro();
		yyparse();
	}
	return 0;
}

	/*WORD NEWLINE	{ printf("%s",$1); return 1;};*/