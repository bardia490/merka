import std.stdio;
import std.string;
import std.process;
import std.json;
import std.file;
import utilites;

void printHelp(){
    writeln("application help:");
    writeln("type q or quit anytime to quit the app");
    writeln("type h anytime to see the help");
    //writeln("type a or all to see all the reports so far");
    writeln("type cl or clear to clear the screen");
    writeln("type ca or \"calculate\" to calculate the price for a work");
    writeln("type pa or print_all to print all the works");
    writeln("type re or \"reload\" to reload the contents of the settings file");
    //writeln("type \'add\' to add a new work");
}

// use this to initalize (or reload) the settings file
void loadSettings(ref JSONValue settings)
{
    string contents = readText(FILENAME);
    settings = parseJSON(contents);
}

void main(){
    JSONValue settings;
    loadSettings(settings);

    version(Windows)
    {
        import std.process: executeShell;
        executeShell("chcp 65001");
    }

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
                writeln;
				break;
            case "cl", "clear":
                write("\x1b[2J\x1b[H");
                stdout.flush();
                break;
            case "ca" , "calculate":
                calculateWork(settings);
                break;
            case "pa", "print_all":
                printAll(settings);
                break;
            case "re", "reload":
                loadSettings(settings); 
                writeln("new settings loaded");
                printSeperator();
                writeln;
                break;
            case "monjog-error":
                writeln("all works must have monjogs");
                break;
            default:
                writeln("what you entered is not valid: ", user_input);
                printSeperator();
                writeln;
                break;
        }
    }
}
