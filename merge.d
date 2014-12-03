import std.stdio;
import std.algorithm;
import std.process;
import std.array;

import git;
import processutils;
import resume;
import help;
import rerere;

// TODO: Should we just put this all in the git module?

// See the resume module for an explanation.
private string resumeKey = "MERGE";

shared static this()
{
	// The handlers are all passed an array of strings,
	// but finishMerge doesn't need any.
	// Wrap it in a lambda.
	resumeHandlers[resumeKey] = (string[]){ finishMerge(); };
}

/// Merges a branch into the current one.
/// If a conflict occurs, register the resume hook to share the rerere cache
/// after the merge has been resolved.
void mergeBranch(string branch)
{

	writeln("Attempting to merge ", branch, " into ", getCurrentBranchName(), ".");
	auto pipes = pipeProcess(["git", "merge", "--no-ff", branch], stderrToStdout);
	if (wait(pipes.pid) != 0 && !pipes.stdout.byLine.filter!(s => s.canFind("CONFLICT")).empty()) {
		writeln("An automatic merge failed.");
		writeln("Resolve it manually and bmpt will resume when you commit the merge.");
		registerResume(resumeKey);
		throw new ResumeNeededException("Manual merge needed");
	}
	else {
		write(pipes.stdout.byLine(KeepTerminator.yes).join());
	}

	finishMerge();
}

private void finishMerge()
{
	writeln("Finishing merge by sharing rerere cache...");
	syncRerere();
}
