import std.exception;
import std.string;
import std.process;

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

string getRemote(string option)
{
	auto output = run(option).byLine;
	if (output.empty)
		return "";

	string ret = output.front.strip().idup;
	// TODO: See if there are multiple remotes and warn as needed?
	return ret;
}
