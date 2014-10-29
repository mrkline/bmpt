import std.stdio;
import std.exception;

import help;
import ptbranches;
import processutils;

/// The entry point for "bmpt checkout"
void checkoutStory(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	if (args.length != 1)
		writeHelp(helpText);

	checkoutStory(args[0]);

}

/// Checks out the branch for the given Pivotal story if it exists,
/// otherwise throws an exception.
void checkoutStory(string storyID)
{
	auto storyBranch = getBranchFromID(storyID);

	enforce(storyBranch != "",
		"Error: No branch exists for the given story ID."
		" Please create one with \"bmpt start\".");

	writeln("Checking out branch ", storyBranch, "...");
	run(["git", "checkout", storyBranch]);
}

private string helpText = q"EOS
Usage: bmpt checkout <story ID>

Checks out a branch by finding the branch with the provided Pivotal story ID
in its name.

Options:

  --help, -h
    Display this help text

  <story ID>
    The Pivotal Tracker story to check out
EOS";
