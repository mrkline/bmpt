import std.c.stdlib;
import std.stdio;

import clone;
import rerere;

void main(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"version", &writeVersion);

	if (args.length < 2)
		writeHelp();

	switch(args[1]) {
		case "clone":
			cloneBPF(args);
			break;

		case "share-rerere":
			syncRerere();
			break;

		default:
			writeHelp();
	}
}

void writeHelp()
{
	writeln(helpText);
	exit(1);
}

void writeVersion()
{
	writeln(versionText);
	exit(0);
}

private string helpText = q"EOS
Usage: bmpt [subcommand]

Subcommands:

  clone
    Clone a repository and set up BPF.

  share-rerere
    Synchronize (via a pull then a push) the shared rerere cache.
EOS";

private string versionText = q"EOS
bmpt, version 0.1.0
by Matt Kline, Fluke Networks, 2014
EOS";
