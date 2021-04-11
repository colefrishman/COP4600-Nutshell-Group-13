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

void run_pipes(){
	int i =0;
	int pipes[tab.numPipes][2];
	for(int i=0; i<tab.numPipes; i++){
		if(pipe(pipes[i])==-1){
		   cout << "There was a problem creating a pipe" << endl;
		   return;
		};
	}
}

std::vector<std::string> path_array;

int main() {
	tab.numPipes=0;
	while(1){

		cout << get_intro();
		
		yyparse();
		if(tab.idx>0){
			int pipeNo = 0;
			if(tab.numPipes==0){
				run_word(tab.name[0], tab.args[0], tab.bg);
			}
			else{
				run_all_pipes();
			}
			tab.idx=0;
			tab.numPipes = 0;
		}
	}
	return 0;
}