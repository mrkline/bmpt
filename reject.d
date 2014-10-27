import std.stdio;

import help;
import pivotal;
import ptbranches;

void rejectStories(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];


	void testHelper(string branchName, string storyID)
	{
		auto story = getStory(storyID);
		if (story["current_state"].str != "delivered") {
			stderr.writeln("Error: can't reject a story that isn't delivered.");
			exit(1);
		}

		writeln("Rejecting story ", storyID, "...");
		storyID.reject();
	}

	runOnCurrentOrSpecifiedBranches(&testHelper, args);
}

private string helpText = q"EOS
Usage: bmpt reject [<story IDs>]

Reject delivered stories

Options:

  --help, -h
    Display this help text

  <story IDs>
    The Pivotal Tracker stories to reject.
    If no ID is provided, it is parsed from the current branch name.
EOS";
