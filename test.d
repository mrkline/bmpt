import std.stdio;
import std.typecons;

import help;
import ongoing;
import git;
import branches;

void testStories(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	string storyID;
	string branchName;

	void testHelper()
	{
		if (branchName == "") {
			stderr.writeln("Error: Story ", storyID, " does not have a local branch.");
			exit(1);
		}

		ongoingCommit(branchName, "rc");
	}

	if (args.length == 0) {
		branchName = getCurrentBranchName();
		storyID = branchNameToID(branchName);
		testHelper();
	}
	else {
		foreach (arg; args) {
			storyID = args[0];
			branchName = getBranchFromID(storyID, Flag!"includeRemotes".no);
			testHelper();
		}
	}
}

private string helpText = q"EOS
Usage: bmpt test [<story IDs>]

Merge the branch for a Pivotal Tracker story into rc.
If no ID is given, the story ID is parsed from the current branch name.

Options:

  --help, -h
    Display this help text

  <story IDs>
    The Pivotal Tracker story to test.
    If no ID is provided, it is parsed from the current branch name.
EOS";
