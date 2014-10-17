import std.exception;
import std.stdio;
import std.file;
import std.string;

import git;
import help;

shared static void function(string[])[string] resumeHandlers;

private string resumeFile = "/.git/BMPT_RESUME";

class ResumeNeededException : Exception
{
	this(string message)
	{
		super(message);
	}

	this()
	{
		super("bmpt must be resumed after some manual intervention.");
	}
}

void registerResume(string key)
{
	enforceInRepo();
	auto fh = File(getRepoRoot() ~ resumeFile, "a");
	fh.writeln(key);
}

void resumeFromFile(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	if (args.length > 0)
		writeHelp(helpText);

	enforceInRepo();

	string filePath = getRepoRoot() ~ resumeFile;
	if (!exists(filePath)) {
		stderr.writeln("Error: bmpt has nothing to resume (no file was found at ",
			filePath, ")");
		exit(1);
	}
	if (!isFile(filePath)) {
		stderr.writeln("Error: ", filePath, " is a directory when it should be a file.");
		exit(1);
	}

	auto fh = File(filePath, "r");
	foreach (line; fh.byLine) {
		auto tokens = line.strip().idup.split();
		auto call = tokens[0] in resumeHandlers;
		if (call is null) {
			stderr.writeln("Error: bmpt does not know how to resume the action \"", line, "\"");
			exit(1);
		}
		(*call)(tokens[1 .. $]);
	}
	fh.close();
	// Remove the resume file if all has gone well
	remove(filePath);
}

private string helpText = q"EOS
Usage: bmpt resume

Resumes bmpt after a manual merge.
Some actions such as "bmpt finish" and "bmpt ongoing" may result in a merge
that must be manually resolved.
Once this resolution is done, "bmpt resume" picks up where bmpt left off,
taking actions like marking the story as finished in the case of "bmpt finish"
and syncing the shared rerere cache.

Options:

  --help, -h
    Display this help text
EOS";
