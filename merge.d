import std.stdio;
import std.algorithm;
import std.process;

import git;
import processutils;
import resume;
import help;
import rerere;

private string resumeKey = "MERGE";

shared static this()
{
	resumeHandlers[resumeKey] = &finishMerge;
}

void mergeBranch(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	if (args.length != 1)
		writeHelp(helpText);

	string branchName = args[0];

	mergeBranch(branchName);
}

void mergeBranch(string branch)
{

	writeln("Attempting to merge ", branch, " into ", getCurrentBranchName(), ".");
	auto pipes = pipeProcess(["git", "merge", branch], stderrToStdout);
	if (wait(pipes.pid) != 0 && !pipes.stdout.byLine.filter!(s => s.canFind("CONFLICT")).empty()) {
		writeln("An automatic merge failed.");
		writeln("Resolve it manually and bmpt will resume when you commit the merge.");
		registerResume(resumeKey);
		throw new ResumeNeededException("Manual merge needed");
	}
	else {
		write(pipes.stdout.byLine(KeepTerminator.yes));
	}

	finishMerge(null);
}

private void finishMerge(string[] tokens)
{
	writeln("Finishing merge by sharing rerere cache...");
	syncRerere();
}

private string helpText = q"EOS
Usage: bmpt merge <branch name>

Options:

  --help, -h
    Display this help text

  <branch name>
    The name of the branch to merge

There is little reason to use this over "git merge && bmpt share-rerere".
It was only added since the functionality was put in place for use in bmpt finish.
EOS";
