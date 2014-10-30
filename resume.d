/**
 * One of the major design goals of bmpt was to be able to resume
 * after a manual merge.
 * This module is how that's accomplished.
 *
 * If we need to exit bmpt to let the user handle a manual merge,
 * modules that need to resume afterwards call registerResume.
 * Like git does when in the middle of something,
 * we create a file in the .git directory to indicate
 * that we're up to something (we call it BMPT_RESUME).
 * In the file, registerResume writes a line for each module
 * that needs to be resumed.
 * It is assumed that the start of each line is that module's key
 * (see below).
 *
 * At the start of bmpt's run, modules that might need to be resume
 * register themselves with a key using the global resumeHandlers hash map.
 * (see the static module initializers, i.e. the shared static this() blocks,
 *  in some other modules.)
 *
 * When we call "bmpt resume" (or it is called via a post-commit hook),
 * resumeFromFile is called.
 * It goes through the file line by line, grabs the first token of each line,
 * and uses that to lookup the needed handler from resumeHandlers.
 * It passes the handler the rest of the line
 * (tokenized by whitespace since we've already done so anyways),
 * and it's up to each handler from there.
 */

import std.exception;
import std.stdio;
import std.file;
import std.string;

import git;
import help;

shared static void function(string[])[string] resumeHandlers;

private string resumeFile = "/.git/BMPT_RESUME";

/// Thrown when a manual merge is needed.
/// Modules that need to resume aftewards should catch it,
/// call registerResume, and rethrow it.
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

/// Writes a line in the resume file for a module.
void registerResume(string line)
in
{
	auto tokens = line.strip().split();
	// Pass us something
	assert(tokens.length > 0);
	// The first token should be a key from resumeHandlers
	assert(tokens[0] in resumeHandlers);
}
body
{
	enforceInRepo();
	auto fh = File(getRepoRoot() ~ resumeFile, "a");
	fh.writeln(line);
}

/// The entry point for "bmpt resume"
void resumeFromFile(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	bool silent;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"silent|s", &silent);

	// We shouldn't have any other params
	if (args.length > 0)
		writeHelp(helpText);

	enforceInRepo();

	string filePath = getRepoRoot() ~ resumeFile;
	if (!exists(filePath)) {
		if (silent) {
			exit(0);
		}
		else {
			stderr.writeln("Error: bmpt has nothing to resume (no file was found at ",
				filePath, ")");
			exit(1);
		}
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
Usage: bmpt resume [--silent]

Resumes bmpt after a manual merge.
Some actions such as "bmpt finish" and "bmpt ongoing" may result in a merge
that must be manually resolved.
Once this resolution is done, "bmpt resume" picks up where bmpt left off,
taking actions like marking the story as finished in the case of "bmpt finish"
and syncing the shared rerere cache.

Options:

  --silent, -s
    If there is nothing to resume, don't write anything and exit cleanly.
    This is useful when using bmpt resume in a git hook.

  --help, -h
    Display this help text
EOS";
