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
import test;
import accept;
import reject;

/**
 * bmpt is essentially just a collection of subcommands packaged
 * into the same binary and with lots of shared code.
 * Because of this, the actual entry point just figures out what subcommand
 * is to be run and passes the argument list to that subcommand.
 */
void main(string[] args)
{
	import std.getopt;

	getopt(args,
		// Let args pass through to the entry points for our various commands
		std.getopt.config.passThrough,
		std.getopt.config.caseSensitive,
		"version", &writeVersion);

	// Any one of our subcommands should be "bmpt <subcommand>"
	if (args.length < 2)
		writeHelp(helpText);

	string subcommand = args[1];

	// Shave off "bmpt <subcommand>"
	args = args[2 .. $];

	try {
		switch(subcommand) {
			case "version":
				writeVersion();
				break;

			case "clone":
				cloneBPF(args);
				break;

			case "share-rerere":
				syncRerere(args);
				break;

			case "whoami":
				writeWhoami(args);
				break;

			case "checkout":
			case "co":
				checkoutStory(args);
				break;

			case "start":
				startStory(args);
				break;

			case "finish":
				finishStories(args);
				break;

			case "ongoing":
				ongoingCommit(args);
				break;

			case "test":
				testStories(args);
				break;

			case "accept":
				acceptStories(args);
				break;

			case "reject":
				rejectStories(args);
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
    Merges branches for given PT stories into dev and mark them as finished

  ongoing
    Merges branches for given PT stories into dev

  test
    Merges branches for given PT stories into rc

  accept
    Accepts delivered PT stories

  reject
    Rejects delivered PT stories

  resume
    Used to resume actions after a manual merge

bmpt is Branch Management for Pivotal Tracker,
a tool to assist with a Branch-Per-Feature (BPF) workflow using Pivotal.
See bmpt <subcommand> --help to read about a specific subcommand.
EOS";

private string versionText = q"EOS
bmpt, version 0.1.0
by Matt Kline, Fluke Networks, 2014
EOS";
