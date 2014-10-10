import std.stdio;

import help;
import clone;
import rerere;
import whoami;
import start;
import checkout;

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

		case "whoami":
			writeWhoami();
			break;

		case "start":
			startStory(args);
			break;

		case "checkout":
		case "co":
			checkoutStory(args);
			break;

		default:
			writeHelp(helpText);
	}
}

void writeVersion()
{
	import std.c.stdlib;
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

  whoami
    Print some basic information about your Pivotal Tracker account

  start
    Creates a branch for a given PT story

  checkout, co
    Checks out a branch for a given PT story
EOS";

private string versionText = q"EOS
bmpt, version 0.1.0
by Matt Kline, Fluke Networks, 2014
EOS";
