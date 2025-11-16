/*
 *                                       /$$                
 *                                      | $$                
 *     /$$$$$$/$$$$   /$$$$$$   /$$$$$$ | $$   /$$  /$$$$$$ 
 *    | $$_  $$_  $$ /$$__  $$ /$$__  $$| $$  /$$/ |____  $$
 *    | $$ \ $$ \ $$| $$$$$$$$| $$  \__/| $$$$$$/   /$$$$$$$
 *    | $$ | $$ | $$| $$_____/| $$      | $$_  $$  /$$__  $$
 *    | $$ | $$ | $$|  $$$$$$$| $$      | $$ \  $$|  $$$$$$$
 *    |__/ |__/ |__/ \_______/|__/      |__/  \__/ \_______/
 *                                                          
 *                                                          
 *                                                          
*/
import std.stdio;
import std.string;
import std.process;
import std.json;
import std.file;
import utilites;
import AppManager;

void printNameArt()
{
    string s = readText("art.txt");
    writeln(s);
}

void printHelp()
{
    writeln("application help:");
    writeln("type q or quit anytime to quit the app");
    writeln("type h anytime to see the help");
    //writeln("type a or all to see all the reports so far");
    writeln("type cl or clear to clear the screen");
    writeln("type ca or calculate to calculate the price for a work");
    writeln("type pa or print_all to print all the works");
    writeln("type re or reload to reload the contents of the settings file");
    writeln("type add to add a new work");
    writeln("type rm or remove to remove a previous work");
    writeln("type up or update to update the app");
}

void main(){

    // initialize the data base and app manager for updates
    import DataBase;
    DataBaseManager dbm = new DataBaseManager;
    APPManager am = new APPManager;

    version(Windows)
    {
        import std.process: executeShell;
        executeShell("chcp 65001");
    }

    write("\x1b[2J\x1b[H");
    stdout.flush();

    printNameArt();
    printHelp();
    outer:
    while (true){
        writef("please enter what you want to do: ");
        string user_input = std.string.strip(readln());

        import std.array: replicate;
        switch (user_input) {
            case "q", "quit":
                printSeperator();
                break outer;
            case "h", "help":
                printHelp();
                printSeperator();
				break;
            case "cl", "clear":
                write("\x1b[2J\x1b[H");
                stdout.flush();
                break;
            case "ca" , "calculate":
                if (!dbm.calculateWork())
                {
                    writeln("sorry something went wrong");
                    printSeperator();
                }
                break;
            case "pa", "print_all":
                dbm.printAll;
                break;
            case "re", "reload":
                dbm.reload;
                writeln("new settings loaded");
                printSeperator;
                break;
            case "add":
                dbm.addWork;
                printSeperator;
                break;
            case "rm" , "remove":
                dbm.removeWork;
                printSeperator;
                break;
            case "up", "update":
                am.update.reportUpdate();
                printSeperator();
                break;
            case "monjog-error":
                writeln("all works must have monjogs");
                break;
            default:
                writeln("what you entered is not valid: ", user_input);
                printSeperator;
                break;
        }
    }
}
