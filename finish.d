import std.stdio;
import std.typecons;
import std.process;

import help;
import branches;
import processutils;
import git;
import branches;
import pivotal;

void finishStory(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	string title;
	bool noMerge;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"title|T", &title,
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

	writeln("Switching to dev branch...");
	run(["git", "checkout", "dev"], noRedirect);

	writeln("Fetching to make sure dev is as up-to-date as possible...");
	run(["git", "fetch"], noRedirect);

	writeln("Fast-forwarding your dev to the remote's dev");
	writeln("(any other kind of merge should not be needed)...");
	run(["git", "merge", "--ff-only", getRemote() ~ "/dev"], noRedirect);

	writeln("Attempting to merge ", branchName, " into dev.");
	if (execute(["git", "merge", branchName]) != 0) {
		writeln("An automatic merge failed.");
		writeln("Resolve it manually and bmpt finish will resume when you commit the merge.");
		exit(1); // Is this a success?
	}

	resumeFinish();
}


void resumeFinish()
{
}

private string helpText = q"EOS
Usage: bmpt finish

Options:

  --help, -h
    Display this help text

  --no-merge, -n
    Just finish the story, and do not merge its

  <story ID>
    The Pivotal Tracker story to finish.
    If no ID is provided, it is parsed from the current branch name.
EOS";
