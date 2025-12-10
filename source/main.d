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

void printNameArt()
{
    string s = readText("art.txt");
    writeln(s);
}

// TODO: make this look nicer
void printHelp()
{
    writeln("application help:");
    writeln("type ", makeBlue("q"),"   or ", makeBlue("quit"), "       to quit the app");
    writeln("type ", makeBlue("h"),"   or ", makeBlue("help"), "       to see the help");
    //writeln("type a or all to seeal  l the reports so far");
    writeln("type ", makeBlue("cl"),"  or ", makeBlue("clear"), "      to clear the screen");
    writeln("type ", makeBlue("ca"),"  or ", makeBlue("calculate"), "  to calculate the price for a work");
    writeln("type ", makeBlue("caa"),"  or ", makeBlue("calculate-all"), "  to calculate the price for a work");
    writeln("type ", makeBlue("pa"),"  or ", makeBlue("print_all"), "  to print all the works");
    writeln("type ", makeBlue("pr"),"  or ", makeBlue("print_work"), " to print a specific work");
    writeln("type ", makeBlue("re"),"  or ", makeBlue("reload"), "     to reload the contents of the settings file");
    writeln("type ", makeBlue("add")," or ", makeBlue("add_work"), "   to add a new work");
    writeln("type ", makeBlue("rm") ,"  or ", makeBlue("remove"), "     to remove a previous work");
    writeln("type ", makeBlue("ed") ,"  or ", makeBlue("edit"), "       to edit an item");
    printSeperator();
}

void main(){

    // initialize the data base and app manager for updates
    import DataBase;
    DataBaseManager dbm = new DataBaseManager;

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
                printSeperator;
                break outer;
            case "h", "help":
                printHelp;
				break;
            case "cl", "clear":
                write("\x1b[2J\x1b[H");
                stdout.flush;
                break;
            case "ca" , "calculate":
                dbm.calculateWork("", true);
                break;
            case "caa" , "calculate-all":
                dbm.calculateAllWorkPrices;
                break;
            case "pa", "print_all":
                dbm.printAll;
                break;
            case "pr", "print_work":
                dbm.printWork; // use the no argument printWork function
                break;
            case "re", "reload":
                dbm.reload;
                writeln("new settings loaded");
                break;
            case "add":
                dbm.addWork;
                break;
            case "rm" , "remove":
                dbm.removeWork;
                break;
            case "ed", "edit":
                dbm.edit();
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
