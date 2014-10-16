import std.stdio;

import processutils;
import merge;
import git;

void ongoingCommit(string from, string to)
{
	writeln("Switching to " ~ to ~ " branch...");
	run(["git", "checkout", to], noRedirect);

	writeln("Fetching to make sure " ~ to ~ " is as up-to-date as possible...");
	run(["git", "fetch"], noRedirect);

	writeln("Fast-forwarding your " ~ to ~ " branch to the remote's " ~ to ~ " branch");
	writeln("(any other kind of merge should not be needed)...");
	run(["git", "merge", "--ff-only", getRemote() ~ "/" ~ to], noRedirect);

	mergeBranch(from);
}
