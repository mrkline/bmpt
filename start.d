import std.c.stdlib;
import std.stdio;

import pivotal;

void startStory(string[] args)
{
	import std.getopt;

	string title;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  &writeHelp,
		"title|T", &title);

	args = args[1 .. $];
	
	if (args.length < 1)
		writeHelp();

	string storyID = args[0];

	auto story = getStory(storyID);

	if (story["story_type"].str == "feature" && !("estimate" in  story)) {
		stderr.writeln( "Error: can't start an un-estimated story. "
			"Please estimate the story in Pivotal Tracker before starting.");
		exit(1);
	}

	auto storyBranch = getBranchNameFromID(storyID);

	if (storyBranch != "") {
		writeln("Attempting to resume story by checking out branch ", storyBranch);
		run(["git", "checkout", storyBranch]);
		return;
	}
}

void writeHelp()
{
	writeln(helpText);
	exit(1);
}

private string helpText = q"EOS
Usage: bmpt start [-T <title>] <story ID>

Options:

  --help, -h
    Display this help text

  --title, -T
    A title for the branch name.
    If it is not provided, the Pivotal ID will be used instead.

  <story ID>
    The Pivotal Tracker story to start
EOS";
