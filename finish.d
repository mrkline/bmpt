import std.stdio;
import std.typecons;
import std.process;
import std.exception;

import help;
import branches;
import processutils;
import git;
import branches;
import pivotal;
import resume;
import ongoing;

private string resumeKey = "FINISH";

shared static this()
{
	resumeHandlers[resumeKey] = &resumeFinish;
}

void finishStory(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	bool noMerge;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"no-merge|n", &noMerge);

	args = args[2 .. $];

	string storyID;
	string branchName;

	if (args.length > 1) {
		writeHelp(helpText);
	}
	else if (args.length == 0) {
		branchName = getCurrentBranchName();
		storyID = branchNameToID(branchName);
	}
	else {
		storyID = args[0];
		branchName = getBranchFromID(storyID, Flag!"includeRemotes".no);
	}

	if (noMerge) {
		writeln("Finishing story ", storyID, " without merging to dev...");
		storyID.finish();
		return;
	}

	if (branchName == "") {
		stderr.writeln("Error: Story ", storyID, " does not have a local branch.");
		exit(1);
	}

	try {
		ongoingCommit(branchName, "dev");
	}
	catch (ResumeNeededException ex) {
		// Append our "resume needed" flag to the file
		registerResume(resumeKey ~ " " ~ storyID);
		throw ex;
	}

	resumeFinish([storyID]);
}


private void resumeFinish(string[] tokens)
{
	enforce(tokens.length >= 1, "The bmpt resume file was missing information for bmpt finish");
	// mergeFinish() will take care of sharing rerere, so we just mark the story as finished
	string storyID = tokens[0];
	writeln("Marking story ", storyID, " as finished...");
	storyID.finish();
}

private string helpText = q"EOS
Usage: bmpt finish

Marks a Pivotal Tracker story as finished and merges its branch into dev.
If no ID is given, the story ID is parsed from the current branch name.

Options:

  --help, -h
    Display this help text

  --no-merge, -n
    Just finish the story, and do not merge its

  <story ID>
    The Pivotal Tracker story to finish.
    If no ID is provided, it is parsed from the current branch name.
EOS";
