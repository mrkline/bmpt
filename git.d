import std.exception;
import std.string;
import std.process;
import std.range;
import std.typecons;
import std.traits;
import std.algorithm;

import processutils;

bool isInRepo()
{
	return execute(["git", "status"]).status == 0;
}

void enforceInRepo()
{
	enforce(isInRepo(), "The current directory is not in a Git repository.");
}

string getRepoRoot()
{
	return firstLineOf(["git", "rev-parse", "--show-toplevel"]);
}

string cloneRepo(string[] args)
{
	import std.stdio;

	auto pipes = pipeProcess(["git", "clone"] ~ args, Redirect.stderr);

	auto errRange = pipes.stderr.byLine(KeepTerminator.yes);
	string errOutput = errRange.front.strip().idup;
	errRange.popFront();
	// TODO: Doesn't seem to be printing for whatever reason
	foreach (line; errRange)
		writeln(line);

	if (wait(pipes.pid) != 0)
		throw new ProcessException("git clone " ~ args.join(" ") ~ " failed.");

	return errOutput[errOutput.indexOf('\'') + 1 .. errOutput.lastIndexOf('\'')];
}

string getConfig(string option)
{
	return firstLineOf(["git", "config", "--get", option]);
}

void setConfig(string option, string value)
{
	run(["git", "config", option, value]);
}

string getCurrentBranchName()
{
	auto branchName = run(["git", "branch"])
		.byLine
		.filter!(l => l[0] == '*') // The current branch is starred
		.front(); // Grab the line
	branchName.popFrontExactly(2); // Cut off the "* ";
	return branchName.idup;
}

string getRemote()
{
	auto output = run(["git", "remote"]).byLine;
	if (output.empty)
		return "";

	string ret = output.front.strip().idup;
	// TODO: See if there are multiple remotes and warn as needed?
	return ret;
}

S stripRemoteFromBranchName(S)(S branchName)
	if (isSomeString!S)
{
	return branchName[branchName.lastIndexOf('/') + 1 .. $];
}

bool currentBranchIsDescendantOf(S)(S predecessor,
                                 Flag!"includeRemotes" includeRemotes = Flag!"includeRemotes".yes)
	if (isSomeString!S)
{
	string[] branchCommand = ["git", "branch", "-a"];

	return run(branchCommand)
		.byLine
		.map!(l => l[l.lastIndexOf('*') + 1 .. $]) // Remove the star from the current branch
		.map!(l => l.strip())
		.map!(s => stripRemoteFromBranchName(s).idup) // Slice off remote part (before and including '/')
		.array // Sort needs to work on random access ranges.
		.sort
		.uniq
		.canFind(predecessor); // The branch should contain our predecessor
}
