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

/// Runs "git clone" with the provided arguments
/// and returns the cloned directory's name.
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

	// The first line printed to stderr is "Cloning into '<dir>'...
	return errOutput[errOutput.indexOf('\'') + 1 .. errOutput.lastIndexOf('\'')];
}

// Gets a value (as a string) from git config
string getConfig(string option)
{
	return firstLineOf(["git", "config", "--get", option]);
}

// Sets a value (as a string) with git config
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

/// Gets the first listed remote f rom "git remote".
/// TODO: We make the rather callous assumption that you will only be using one remote,
///       though this is usually the case for BPF.
string getRemote()
{
	auto output = run(["git", "remote"]).byLine;
	enforce(!output.empty, "There are currently no remotes set up for this repository");

	string ret = output.front.strip().idup;
	// TODO: See if there are multiple remotes and warn as needed?
	return ret;
}

/// Strips the remote part of a branch name.
/// This is provided as a template so that any string range
/// (such as the result of mapping and filtering) can call it.
S stripRemoteFromBranchName(S)(S branchName)
	if (isSomeString!S)
{
	return branchName[branchName.lastIndexOf('/') + 1 .. $];
}

/// Returns true if the current branch is a descendant of the given commit
bool currentBranchIsDescendantOf(S)(S predecessor,
                                 Flag!"includeRemotes" includeRemotes = Flag!"includeRemotes".yes)
	if (isSomeString!S)
{
	string[] branchCommand = ["git", "branch"];
	if (includeRemotes)
		branchCommand ~= "-a";

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
