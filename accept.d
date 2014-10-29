import std.stdio;

import help;
import pivotal;
import ptbranches;

void acceptStories(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	void testHelper(string branchName, string storyID)
	{
		auto story = getStory(storyID);
		if (story["current_state"].str != "delivered") {
			stderr.writeln("Error: can't accept a story that isn't delivered.");
			exit(1);
		}

		writeln("Accepting story ", storyID, "...");
		storyID.accept();
	}

	runOnCurrentOrSpecifiedBranches(&testHelper, args);
}

private string helpText = q"EOS
Usage: bmpt accept [<story IDs>]

Accept delivered stories

Options:

  --help, -h
    Display this help text

  <story IDs>
    The Pivotal Tracker stories to accept.
    If no ID is provided, it is parsed from the current branch name.
EOS";
