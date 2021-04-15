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
	return BOLD YELLOW+user+'@'+host+':'+BLUE+dir+BLACK "> "+DEFAULT + RESET;
}

extern CommandTable tab;

int done;

std::vector<std::string> path_array;
int main() {

	done = false;

	tab.numPipes=0;
	tab.input_re = 0;
	tab.output_re = 0;
	tab.err_re = 0;
	updatePath();

	while(1){

		if(done){cout<<endl; exit(1);}
		cout << get_intro();
		
		yyparse();
		if(tab.idx>0){
			int pipeNo = 0;
			if(tab.numPipes==0){
				run_word(tab.name[0], tab.args[0], tab.bg);
			}
			else{
				run_all_pipes(tab.bg);
			}
			tab.idx=0;
			tab.numPipes = 0;

			tab.input_re = 0;
			tab.output_re = 0;
			tab.err_re = 0;
		}
	}
	return 0;
}