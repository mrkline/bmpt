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
