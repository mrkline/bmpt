import std.algorithm;
import std.string;
import std.exception;
import std.array;
import std.ascii;
import std.regex;
import std.conv;
import std.traits;
import std.range;

import processutils;

auto getBranchNameFromID(string id, bool includeRemotes = true)
{
	string[] branchCommand = ["git", "branch"];
	if (includeRemotes)
		branchCommand ~= "-a";

	auto matchingBranches = run(branchCommand)
		.byLine
		.map!(l => l[max(0, l.lastIndexOf('*') + 1) .. $]) // Remove the star from the current branch
		.map!(l => l.strip())
		.map!(s => s[max(0, s.lastIndexOf('/') + 1) .. $].idup) // Slice off remote part (before and including '/')
		.array // Sort needs to work on random access ranges.
		.sort
		.uniq
		.filter!(s => s.canFind(id)); // The branch should contain our ID


	if(matchingBranches.empty)
		return "";

	string ret = matchingBranches.front().idup;
	matchingBranches.popFront();

	enforce(matchingBranches.empty,
		"There are multiple branches matching Pivotal ID: " ~ id ~
		". Please manually resolve this.");

	return ret;
}

string getIDFromCurrentBranch()
{
	char[] please = "wat".dup;
	please.popFrontExactly(2);

	auto branchName = run(["git", "branch"])
		.byLine
		.filter!(l => l[0] == '*') // The current branch is starred
		.front(); // Grab the line
	branchName.popFrontExactly(2); // Cut off the "* ";
	return getIDFromBranchName(branchName);
}

string getIDFromBranchName(S)(S branchName) if (isSomeString!S)
{
	enum branchRegex = ctRegex!(`(?:US-)(\d+)(?:\w+)?`);
	auto match = branchName.matchFirst(branchRegex);
	enforce(match,
		"No ID could be found from the branch name \"" ~ branchName ~ "\"");
	return match[1].to!string;
}

string getBranchNameFromID(string storyID, string title)
{
	string branchName = "US-" ~ storyID;
	if (isValidTitle(title))
		branchName ~= "-" ~ title;

	return branchName;
}

bool isValidTitle(string title) {
	return title.length > 0 && title.all!(c => c.isAlphaNum() || c == '_');
}
