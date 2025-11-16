import std.stdio;
import core.stdc.stdlib: exit;

class APPManager
{
    this()
    {}

    void update()
    {
        import std.process: executeShell, execute;
        writeln("checking for updates ...");
        auto buildOutput = executeShell("dub build");
        if (buildOutput.status != 0) writeln("Compilation failed");
        else writeln("update complete");
    }
}
