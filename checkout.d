import std.c.stdlib;
import std.stdio;

import help;
import branches;
import processutils;

void checkoutStory(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	if (args.length != 1)
		writeHelp(helpText);

	checkoutStory(args[0]);

}

void checkoutStory(string storyID)
{
	auto storyBranch = getBranchNameFromID(storyID);

	if (storyBranch != "") {
		writeln("Attempting to resume story by checking out branch ", storyBranch, "...");
		run(["git", "checkout", storyBranch], noRedirect);
		return;
	}
	else {
		throw new Exception("Error: No branch exists for the given story ID."
			" Please create one with \"bmpt start\".");
	}
}

private string helpText = q"EOS
Usage: bmpt checkout <story ID>

Options:

  --help, -h
    Display this help text

  <story ID>
    The Pivotal Tracker story to check out
EOS";
