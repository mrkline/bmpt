import std.stdio;

import help;
import clone;
import rerere;
import whoami;
import start;
import checkout;
import merge;
import finish;
import resume;
import ongoing;

void main(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.passThrough,
		std.getopt.config.caseSensitive,
		"version", &writeVersion);

	if (args.length < 2)
		writeHelp(helpText);

	try {
		switch(args[1]) {
			case "version":
				writeVersion();
				break;

			case "clone":
				cloneBPF(args);
				break;

			case "share-rerere":
				syncRerere();
				break;

			case "whoami":
				writeWhoami();
				break;

			case "checkout":
			case "co":
				checkoutStory(args);
				break;

			case "start":
				startStory(args);
				break;

			case "finish":
				finishStory(args);
				break;

			case "ongoing":
				ongoingCommit(args);
				break;

			case "resume":
				resumeFromFile(args);
				break;

			default:
				writeHelp(helpText);
		}
	}
	catch (ResumeNeededException) {
		// If bmpt needs to be resumed after a manual merge,
		// this exception will bubble up to here. This is not a problem.
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

  version, --version
    Write version information and exit

  clone
    Clone a repository and set up BPF.

  share-rerere
    Synchronize (via a pull then a push) the shared rerere cache.

  whoami
    Print some basic information about your Pivotal Tracker account

  checkout, co
    Check out the branch for a given PT story

  start
    Create a branch for a given PT story and mark it as started in PT

  finish
    Merges a branch for a given PT story into dev and mark it as finished in PT

  ongoing
    Merges a branch for a given PT storoy into dev

  resume
    Used to resume actions after a manual merge
EOS";

private string versionText = q"EOS
bmpt, version 0.1.0
by Matt Kline, Fluke Networks, 2014
EOS";
