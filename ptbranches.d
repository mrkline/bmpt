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

/// Searches for the branch for the provided PT story ID,
/// or returns an empty string if one does not exist
auto getBranchFromID(string id, Flag!"includeRemotes" includeRemotes = Flag!"includeRemotes".yes)
{
	string[] branchCommand = ["git", "branch"];
	if (includeRemotes)
		branchCommand ~= "-a";

	auto matchingBranches = run(branchCommand)
		.byLine
		.map!(l => l[l.lastIndexOf('*') + 1 .. $]) // Remove the star from the current branch
		.map!(l => l.strip())
		.map!(s => stripRemoteFromBranchName(s).idup) // Slice off remote part (before and including '/')
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

/// A convenience function that calls branchNameToID on the current branch
string getIDFromCurrentBranch()
{
	return branchNameToID(getCurrentBranchName());
}

/// Finds the Pivotal Tracker ID inside a branch name.
/// As is the case with existing PT tooling, story branches are in the format
/// US-<ID>[-<optional title>]
string branchNameToID(S)(S branchName) if (isSomeString!S)
{
	enum branchRegex = ctRegex!(`(?:US-)(\d+)(?:\w+)?`);
	auto match = branchName.matchFirst(branchRegex);
	enforce(match,
		"No ID could be found in the branch name \"" ~ branchName ~ "\"");
	return match[1].to!string;
}

/// Creates a branch name based on a given Pivotal Tracker ID and a title.
/// If the title is not a valid title (e.g. it is empty), it is omitted.
string IDToBranchName(string storyID, string title)
{
	string branchName = "US-" ~ storyID;
	if (isValidTitle(title))
		branchName ~= "-" ~ title;

	return branchName;
}

/// A valid title is not empty and only contains
/// letters, numbers, and underscores.
bool isValidTitle(string title) {
	return title.length > 0 && title.all!(c => c.isAlphaNum() || c == '_');
}

/**
 * Runs the provided delegate,
 * which receives the branch name and the branch's PT story ID as arguments,
 * on one or more branches.
 *
 * If no arguments are provided, run the provided delegate on the current branch.
 * If arguments are provided, assume each is a PT story ID.
 * Get each ID's branch and run the delegate on each of those branches.
 */
void runOnCurrentOrSpecifiedBranches(void delegate(string, string) toRun, string[] args)
{
	if (args.length == 0) {
		string branchName = getCurrentBranchName();
		string storyID = branchNameToID(branchName);
		toRun(branchName, storyID);
	}
	else {
		foreach (arg; args) {
			string storyID = arg;
			string branchName = getBranchFromID(storyID, Flag!"includeRemotes".no);
			toRun(branchName, storyID);
		}
	}
}
