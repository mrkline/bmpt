import std.algorithm;
import std.string;
import std.exception;
import std.array;

import processutils;

auto getBranchesMatchingID(string id, bool includeRemotes = true)
{
	string[] branchCommand = ["git", "branch"];
	if (includeRemotes)
		branchCommand ~= "-a";
	auto matchingBranches = run(branchCommand)
		.byLine
		.map!(s => s[max(0, s.lastIndexOf('/')) .. $]) // Slice off remote part (before and including '/')
		.filter!(s => s.canFind(id)) // The branch should contain our ID
		.array // Sort needs to work on random access ranges.
		.sort // Uniq assumes the input range has been sorted
		.uniq; // Remove duplicates (i.e. local and remote branches)


	if(matchingBranches.empty)
		return "";

	string ret = matchingBranches.front().idup;
	matchingBranches.popFront();

	enforce(matchingBranches.empty,
		"There are multiple branches matching Pivotal ID: " ~ id ~
		". Please manually resolve this.");

	return ret;
}
