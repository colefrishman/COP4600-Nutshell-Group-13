#include "nutshparser.tab.h"
#include <string>
#include <iostream>
#include <unistd.h>
#include <limits.h>
#include "global.h"

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

extern CommandTable tab;
int main() {
	while(1){
		tab.idx=0;
		cout << get_intro();
		yyparse();
		if(tab.idx>0){
			run_word(tab.name[0], tab.args[0]);
		}
	}
	return 0;
}

	/*WORD NEWLINE	{ printf("%s",$1); return 1;};*/