import std.algorithm;
import std.string;
import std.exception;
import std.array;
import std.ascii;

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

bool isValidTitle(string title) {
	return title.all!(c => c.isAlphaNum() || c == '_');
}
