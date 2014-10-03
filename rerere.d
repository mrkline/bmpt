import std.stdio;
import std.conv;
import std.file;
import std.process;

import processutils;
import git;

void setupRerere(string remoteURL, string remote = "origin")
{
	enforceInRepo();
	writeln("Setting up rerere sharing...");

	writeln("  Enabling rerere...");
	setConfig("rerere.enabled", "true");
	setConfig("rerere.autoupdate", "true");

	writeln("  Setting up shared rerere cache...");
	string root = getRepoRoot();
	string rrPath = root ~ "/.git/rr-cache";
	string rrGitDir = rrPath ~ "/.git";
	if (!exists(rrPath) || !exists(rrGitDir)) {
		run(["git", "init", rrPath]);
		string cwd = getcwd();
		chdir(rrPath);
		scope(exit) chdir(cwd);
		run(["git", "remote", "add", remote, remoteURL]);
		writeln("  Fetching repo for the shared rerere cache...");
		run(["git", "fetch", remote]);
	}
	else {
		writeln("  Rerere cache already exists and is a repository.");
	}

	// Switch to our rerere cache
	string cwd = getcwd();
	chdir(rrPath);
	scope(exit) chdir(cwd);

	// A remote has the branch 'rr-cache', switch to it
	if (executeShell("git branch -r | grep rr-cache").status == 0) {
		writeln("  Checking out existing shared rerere cache...");
		run(["git", "checkout", "rr-cache"]);
	}
	// Otherwise create an orphan branch and push it up
	else {
		writeln("  Creating and pushing new rerere cache branch to " ~ remote);
		run(["git", "checkout", "--orphan", "rr-cache"]);
		run(["git", "rm", "-rf", "--ignore-unmatch", rrPath]);
		run(["git", "commit", "-a", "--allow-empty", "-m",
			"Automatically creating branch to track conflict resolutions"]);
		run(["git", "push", remote, "rr-cache", "-u"]);
	}
}
