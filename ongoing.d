import std.stdio;
import std.typecons;
import std.exception;

import processutils;
import merge;
import git;
import help;
import ptbranches;

/// The entry point for "bmpt ongoing"
void ongoingCommit(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	void ongoingHelper(string branchName, string storyID)
	{
		if (branchName == "") {
			stderr.writeln("Error: Story ", storyID, " does not have a local branch.");
			exit(1);
		}

		ongoingCommit(branchName, "dev");
	}

	runOnCurrentOrSpecifiedBranches(&ongoingHelper, args);
}

/// Merges the "from" branch into the "to" branch,
/// making sure "to" is up to date first and
/// using the merge module to share the rerere cache as needed
void ongoingCommit(string from, string to)
{
	writeln("Fetching to make sure branches are as up-to-date as possible...");
	run(["git", "fetch"], noRedirect);

	writeln("Checking out and fast forwarding ", from, "...");
	run(["git", "checkout", from]);
	run(["git", "merge", "--ff-only", getRemote() ~ "/" ~ from]);

	enforce(currentBranchIsDescendantOf("master"),
	        from ~ " is not a descendant of the master branch. "
	        "Rebase " ~ from ~ " onto master before integrating it.");

	writeln("Switching to " ~ to ~ " branch...");
	run(["git", "checkout", to]);

	writeln("Fast-forwarding your " ~ to ~ " branch to the remote's " ~ to ~ " branch");
	writeln("(any other kind of merge should not be needed)...");
	run(["git", "merge", "--ff-only", getRemote() ~ "/" ~ to]);

	mergeBranch(from);
}

private string helpText = q"EOS
Usage: bmpt ongoing

Merges a Pivotal Tracker story's branch into dev.
If no ID is given, the story ID is parsed from the current branch name.

Options:

  --help, -h
    Display this help text

  <story ID>
    The Pivotal Tracker story to merge to dev.
    If no ID is provided, it is parsed from the current branch name.
EOS";
