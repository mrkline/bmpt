import std.c.stdlib;
import std.stdio;
import std.algorithm;
import std.ascii;
import std.utf;
import std.array;

import pivotal;
import branches;
import processutils;
import git;

void startStory(string[] args)
{
	import std.getopt;

	string title;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  &writeHelp,
		"title|T", &title);

	args = args[2 .. $];

	if (args.length < 1)
		writeHelp();

	string storyID = args[0];

	auto story = getStory(storyID);

	if (story["story_type"].str == "feature" && !("estimate" in  story)) {
		stderr.writeln( "Error: can't start an un-estimated story. "
			"Please estimate the story in Pivotal Tracker before starting.");
		exit(1);
	}

	// TODO: We probably want to fetch before we do this

	auto storyBranch = getBranchNameFromID(storyID);

	if (storyBranch != "") {
		writeln("Attempting to resume story by checking out branch ", storyBranch);
		run(["git", "checkout", storyBranch]);
		return;
	}

	if (title == "") {
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

		title = story["name"]
			.str // The JSON value should be a string
			// The old script filters out anything that's not alphanumeric or space
			// TODO: Is this necessary?
			.filter!(c => c.isAlphaNum() || c == ' ')
			.array // We need this as a string again
			.toUTF8() // TODO: Why does .array expand the range into a UTF-32 array?
			.split() // Split into words
			.filter!(w => !forbiddenWords.canFind(w)) // Remove forbidden words
			.join("_");
	}


	string branchName = "US-" ~ storyID;
	if (isValidTitle(title))
		branchName ~= "-" ~ title;

	writeln("Creating the branch ", branchName,
		" starting at master (which should match the last release)...");
	run(["git", "checkout", "-b", branchName, getRemote() ~ "/master"], noRedirect);

	writeln("Pushing the new branch...");
	// TODO: Do we need this complicated of a push?
	run(["git", "push", "--progress", "--recurse-submodules=check", "-u", "origin",
		"refs/heads/" ~ branchName ~ ":refs/heads/" ~ branchName], noRedirect);

	writeln("Marking story as started...");
	storyID.start();
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