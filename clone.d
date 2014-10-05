import std.c.stdlib;
import std.stdio;
import std.file;
import std.string;

import processutils;
import rerere;
import git;

void cloneBPF(string[] args)
{
	import std.getopt;

	string remote = "origin";

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  &writeHelp,
		"origin|o", &remote);

	// We don't care where we came from and we know the first arg after that was "clone"
	args = args[2 .. $];

	// We should have a single argument at this point: the remote URL
	if (args.length > 2)
		writeHelp();

	string[] cloneArgs = ["-o", remote] ~ args;

	// Git prints the directory we're cloning into on the first line.
	// Grab that
	writeln("Cloning repository...");
	string clonedDir = cloneRepo(cloneArgs);
	chdir(clonedDir);
	setupRerere(args[0], remote);
}

void writeHelp()
{
	writeln(helpText);
	exit(1);
}

private string helpText = q"EOS
Usage: bmpt clone [-o <name>] <remote URL> [<directory>]

Options:

  --help, -h
    Display this help text.

  --origin, -o <name>
    Specify the remote name. Defaults to "origin", just like Git normally does.

  <remote URL>
    The URL of the repository to clone

  <directory>
    The directory in which to clone
EOS";
