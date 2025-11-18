import AppManager;

void main()
{
    import std.stdio: writeln, readln, stdout, write;
    APPManager appManager = new APPManager;
    writeln("starting update");

    version(Windows)
    {
        import std.process: executeShell;
        executeShell("chcp 65001");
    }

    write("\x1b[2J\x1b[H");
    stdout.flush();
    
    appManager.update.reportUpdate;
    writeln("press any key to exit ...");
    readln();
}
