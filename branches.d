import std.algorithm;
import std.string;
import std.exception;
import std.array;
import std.ascii;
import std.regex;
import std.conv;
import std.traits;
import std.range;
import std.typecons;

import processutils;
import git;

auto getBranchFromID(string id, Flag!"includeRemotes" includeRemotes = Flag!"includeRemotes".yes)
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
	return branchNameToID(getCurrentBranchName());
}

string branchNameToID(S)(S branchName) if (isSomeString!S)
{
	enum branchRegex = ctRegex!(`(?:US-)(\d+)(?:\w+)?`);
	auto match = branchName.matchFirst(branchRegex);
	enforce(match,
		"No ID could be found from the branch name \"" ~ branchName ~ "\"");
	return match[1].to!string;
}

string IDToBranchName(string storyID, string title)
{
	string branchName = "US-" ~ storyID;
	if (isValidTitle(title))
		branchName ~= "-" ~ title;

	return branchName;
}

bool isValidTitle(string title) {
	return title.length > 0 && title.all!(c => c.isAlphaNum() || c == '_');
}
