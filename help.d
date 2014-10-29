import std.c.stdlib;
import std.stdio;

/// Writes the provided help text and exits the program.
void writeHelp(string helpText)
{
	writeln(helpText);
	exit(1);
}
