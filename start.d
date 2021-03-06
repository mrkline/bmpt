import std.stdio;
import std.algorithm;
import std.ascii;
import std.utf;
import std.array;
import std.range;

import pivotal;
import ptbranches;
import processutils;
import git;
import checkout;
import help;

/// The entry point for "bmpt start"
void startStory(string[] args)
{
	import std.getopt;
	import std.c.stdlib;

	string title;
	bool noCheckout;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"title|T", &title,
		"no-checkout|n", &noCheckout);

	args = args[2 .. $];

	if (args.length > 1) {
		writeHelp(helpText);
	}
	else if (args.length == 0) {
		// If no ID is passed, just restart this story
		string storyID = getIDFromCurrentBranch();
		writeln("Restarting story ", storyID, "...");
		storyID.start();
		return;
	}

	string storyID = args[0];

	auto story = getStory(storyID);

	// If the story is a feature, demand it be estimated.
	// This is the behavior from the old BPF tool.
	if (story["story_type"].str == "feature" && !("estimate" in story)) {
		stderr.writeln( "Error: can't start an un-estimated story. "
			"Please estimate the story in Pivotal Tracker before starting.");
		exit(1);
	}

	// TODO: We might want to fetch before we do this

	if (!noCheckout) {
		auto storyBranch = getBranchFromID(storyID);
		if (storyBranch != "") {
			// If the branch already exists, we have a pretty easy job.
			// Just check it out.
			checkoutStory(storyBranch);
			writeln("Restarting story ", storyID, "...");
		}
		else {
			// Otherwise, we need to create the branch.
			if (title == "")
				title = titleFromStoryName(story["name"].str);

			string branchName = IDToBranchName(storyID, title);

			writeln("Creating the branch ", branchName,
				" starting at master (which should match the last release)...");
			run(["git", "checkout", "-b", branchName, getRemote() ~ "/master"]);

			writeln("Pushing the new branch...");
			// TODO: Do we need this complicated of a push?
			run(["git", "push", "--progress", "--recurse-submodules=check", "-u", "origin",
				"refs/heads/" ~ branchName ~ ":refs/heads/" ~ branchName], noRedirect);
		}
	}

	writeln("Marking story as started...");
	storyID.start();
}

string titleFromStoryName(string name)
{
	// I'm not sure why these are forbidden as the branch name.
	// For now we're just following what the old BPF script did.
	// TODO: Figure out the intention here.
	// TODO: Should this be a hash set?
	string[] forbiddenWords = [
		"user", "users", "consumer", "consumers",
		"should ", "can", "cant", "would", "are", "arent",
		"be", "an", "a", "have", "has", "to",
		"does", "do", "doesnt", "will", "wont",
		"for", "from", "the", "of", "on", "with",
		"that", "those", "which", "what", "who", "if"
	];

	return name
		// The old script filters out anything that's not alphanumeric or space
		// TODO: Is this necessary?
		.filter!(c => c.isAlphaNum() || c == ' ')
		.array // We need this as a string again
		.toUTF8() // TODO: Why does .array expand the range into a UTF-32 array?
		.split() // Split into words
		.filter!(w => !forbiddenWords.canFind(w)) // Remove forbidden words
		.take(5) // Take the first five words
		.join("_");

}

private string helpText = q"EOS
Usage: bmpt start [-T <title>] [-n] [<story ID>]

Marks a Pivotal Tracker story as started and creates or checks out its branch.
If no ID is given, the story ID is parsed from the current branch name.
If an ID is given,
  - If a branch exists for the given story ID, it is checked out.
  - If no branch exists for the given ID, a branch is created for it.

Options:

  --help, -h
    Display this help text

  --title, -T
    A title for the branch name.
    If it is not provided, the Pivotal ID will be used instead.

  --no-checkout, -n
    Just start the story, and do not create or check out its branch.

  <story ID>
    The Pivotal Tracker story to start.
    If no ID is provided, it is parsed from the current branch name.
EOS";
