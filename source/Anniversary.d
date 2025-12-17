import std.stdio;
import core.thread: Thread;
import core.time: dur;
import std.file: readText;
import std.array: split;
import std.conv: to;

enum RESET = "\x1B[0m";

void draw_heart()
{
    string[] heart = readText("art-gallery/heart.txt").split('\n');
    foreach(index, line; heart)
    {
        writeln("\x1B[38;5;" ~ to!string(index + 160) ~ "m" ~ line);
        Thread.sleep(dur!("msecs")(150));
    }
    writeln(RESET);
}

void draw_i_love_you_baby()
{
    string[4] contents;
    contents[0] = readText("art-gallery/I.txt");
    contents[1] = readText("art-gallery/Love.txt");
    contents[2] = readText("art-gallery/You.txt");
    contents[3] = readText("art-gallery/Baby.txt");
    foreach(index, line; contents)
    {
        write("\x1B[38;5;" ~ to!string(index + 160) ~ "m" ~ line);
        Thread.sleep(dur!("msecs")(500));
    }
    writeln(RESET);
}

void draw_happy_aniversary()
{
    string[] contents = readText("art-gallery/happy_anniversary.txt").split('\n');
    foreach(index, line; contents)
    {
        write("\x1B[38;5;" ~ to!string(index + 160) ~ "m" ~ line);
        Thread.sleep(dur!("msecs")(300));
    }
    writeln(RESET);
}

void write_letter(string[] message)
{
    foreach(index, word; message)
    {
        write("\x1B[38;5;" ~ to!string(index + 160) ~ "m" ~ word ~ " ");
        Thread.sleep(dur!("msecs")(200));
    }
    writeln(RESET);
    writeln;
}

void second_anniversary()
{
    write("\x1b[2J\x1b[H\n");
    draw_happy_aniversary();
    draw_i_love_you_baby();
    string[] letter = "you are the most beautiful, gorgeous and amazing person i have ever known.
    I love you sooooooo much.
    please be mine always and forever".split(" ");
    write_letter(letter);
    draw_heart();
}
