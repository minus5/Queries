#import <Cocoa/Cocoa.h>           
// #include <signal.h>


int main(int argc, char *argv[])
{	
	//kada mi pukne konekcija na sql server onda mi freetds digne SIGPIPE singal
	//nisam ga uspio nigdje uhvatiti da napravim nesto korisno s njime, pa stoga ovdje ignore
//	signal(SIGPIPE, SIG_IGN);
  return NSApplicationMain(argc,  (const char **) argv);
}
