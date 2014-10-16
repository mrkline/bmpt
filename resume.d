import std.exception;
import std.stdio;
import std.file;
import std.string;

import git;

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

void resumeFromFile()
{
	import std.c.stdlib;

	enforceInRepo();
	string filePath = getRepoRoot() ~ resumeFile;
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

