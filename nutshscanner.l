%{
// Generated by Bison
#include "nutshparser.tab.h"
#include <string.h>
#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <glob.h>
#include <fnmatch.h>
#include "global.h"

extern int done;

std::map<std::string, std::string> nestedAliases;
std::map<std::string, std::string> aliasTable;
std::string decipherAlias(std::string aliasText){
	if(aliasTable.count(aliasText) > 0){
		return decipherAlias(aliasTable[aliasText]);
	}
	return aliasText;
}
void setNestedVal(std::string s)
{
    for (auto it=aliasTable.begin(); it!=aliasTable.end(); ++it)
	{
		
		if (aliasTable[it->first] == s)
		{
			nestedAliases[it->first] = nestedAliases[s];
			setNestedVal(it->first);
		}
	}
}
bool checkCycle(std::string key, std::string val)
{
	for (auto it=aliasTable.begin(); it!=aliasTable.end(); ++it)
	{
		if (key == it->first)
		{
			return checkCycle(it->second, val);
		}
		else if (nestedAliases[val] == key)
		{
			return true;
		}
	}
	return false;
}

bool beginning = true;

void replaceAlias(char* text){
	
}
%}
%array
%option noyywrap
%x string_condition

CHAR            [*.A-Za-z0-9!?:\/_-][*.A-Za-z0-9!?:\/_-]*
ANYCHAR            [)(}{><*&%$#@!`:;,\.a-zA-Z0-9'/*_=~ -][)(}{><*&%$#@!`:;,\.a-zA-Z0-9'/*_=~ -]*

%%

\$\{{ANYCHAR}+\} {
	std::string y = std::string(yytext);
	char* text = (char*) y.substr(y.find("${")+2, y.find('}')-2).c_str();
	char* env = getenv(text);
	if(env) {
		std::string t = std::string(env);
	    for ( int i = t.length() - 1; i >= 0; --i ){
	     	unput( t[i] );
		}
    }
}

<string_condition>\$\{{ANYCHAR}+\} {
	std::string y = std::string(yytext);
	char* text = (char*) y.substr(y.find("${")+2, y.find('}')-2).c_str();
	char* env = getenv(text);
	if(env) {
		std::string t = std::string(env);
	    for ( int i = t.length() - 1; i >= 0; --i ){
	     	unput( t[i] );
		}
    }
}
<string_condition>{ANYCHAR}+     { yylval.WORD = strdup(yytext); return WORD;}
<string_condition>[\"]          {BEGIN(INITIAL);}


[\"]        { BEGIN(string_condition); }
"| "		{ beginning = true; return PIPE;}
\|			{ beginning = true; return PIPE;}
" |"		{ beginning = true; return PIPE;}
" "		    { beginning = false; }
<<EOF>>		{done=true; return NEWLINE; return 0;}
"2>&1"		{return ERRTOOUT;}
"&"			{return AMPERSAND;}
"<"			{return LEFTAB;}
">>"		{return DOUBLERIGHTAB;}
">"			{return RIGHTAB;}
"2>"		{return ERRTO;}
bye			{if(beginning){exit(1);} else {yylval.WORD = strdup(yytext); return WORD;} }
setenv		{if(beginning){return SETENV;} else {yylval.WORD = strdup(yytext); return WORD;} }
printenv	{if(beginning){return PRINTENV;} else { yylval.WORD = strdup(yytext); return WORD;} }
unsetenv	{if(beginning){return UNSETENV;} else { yylval.WORD = strdup(yytext); return WORD;} }
alias		{if(beginning){return ALIAS;} else { yylval.WORD = strdup(yytext); return WORD;} }
unalias		{if(beginning){return UNALIAS;} else { yylval.WORD = strdup(yytext); return WORD;} }
cd			{if(beginning){return CD;} else { yylval.WORD = strdup(yytext); return WORD;} }
[\n\r]		{ beginning = true; return NEWLINE;}
~{CHAR}* {
	std::string y = std::string(yytext);
	std::string after;
	std::string t;
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

	if(t.find('~')!=std::string::npos){
		
	}
	else if(t!="") {
	    for ( int i = t.length() - 1; i >= 0; --i ){
	     	unput( t[i] );
		}
    }
}
{CHAR}+		{
	glob_t globlist;
	std::string text = std::string(yytext);

	if(beginning && is_alias(yytext)) {
		std::string t = aliasTable[std::string(yytext)]; 
	    for ( int i = t.length() - 1; i >= 0; --i ){
	     	unput( t[i] );
		}
    }
	else if((text.find('*')!=std::string::npos || text.find('?')!=std::string::npos)
	 	&& (glob((text).c_str(), GLOB_TILDE, NULL, &globlist) == 0)){
		std::string t = "";
		for(unsigned int i=0;i<globlist.gl_pathc;++i) {
			t=t+globlist.gl_pathv[i]+" ";
		}

		for ( int i = t.length() - 1; i >= 0; --i ){
	     	unput( t[i] );
		}
	}
	else {
		yylval.WORD = strdup(yytext); return WORD;
	}
}
