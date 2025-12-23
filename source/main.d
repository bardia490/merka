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
import Anniversary;

void printNameArt()
{
    string s = readText("art-gallery/art.txt");
    writeln(s);
}

// TODO: make this look nicer
void printHelp()
{
    import std.format;
    writeln("application help:");
    writeln(format("type %=20s or %=40s to quit the app", makeBlue("q"), makeBlue("quit")));
    writeln(format("type %=20s or %=40s to see the help",  makeBlue("h"),  makeBlue("help")));
    //writelformat(n("tye a or all to see all the reports so far");
    writeln(format("type %=20s or %=40s to clear the screen",  makeBlue("cl"),  makeBlue("clear")));
    writeln(format("type %=20s or %=40s to calculate the price for a work",
                 makeBlue("ca"),  makeBlue("calculate-work")));
    writeln(format("type %=20s or %=40s to calculate the price for all work",
                 makeBlue("caa"),  makeBlue("caclulate-works")));
    writeln(format("type %=20s or %=40s to print a specific work",
                 makeBlue("pw"),  makeBlue("print-work")));
    writeln(format("type %=20s or %=40s to print all the works",
                 makeBlue("pa"),  makeBlue("print-all")));
    writeln(format("type %=20s or %=40s to print all the work prices",
                 makeBlue("pap"),  makeBlue("print-all-prices")));
    writeln(format("type %=20s or %=40s to reload the contents of the settings file",
                 makeBlue("re"),  makeBlue("reload")));
    writeln(format("type %=20s or %=40s to add a new work",
                 makeBlue("add"),  makeBlue("add-work")));
    writeln(format("type %=20s or %=40s to remove a previous work",
                 makeBlue("rm"),  makeBlue("remove-work")));
    writeln(format("type %=20s or %=40s to edit an item",
                 makeBlue("ed"),  makeBlue("edit")));
    writeln(format("type %=20s or %=40s for a surperise",
                 makeBlue("an"),  makeBlue("anniversary")));
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
            case "pa", "print-all":
                dbm.printAll;
                break;
            case "pap", "print-all-prices":
                dbm.calculateAllWorkPrices;
                break;
            case "pw", "print_work":
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
            case "an", "anniversary":
                second_anniversary();
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
