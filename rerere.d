import std.stdio;
import std.conv;
import std.file;
import std.process;
import std.exception;
import std.algorithm;

import processutils;
import git;
import help;

/// Sets up rerere cache sharing for the repository
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

	enforce(!exists(rrPath), "The rerere cache already exists. "
		"Bailing as it is assumed you know what you are doing more than this tool...");
	enforce(!exists(rrGitDir), "The rerere cache is already a git repo. "
		"Bailing as it is assumed you know what you are doing more than this tool...");

	writeln("  Creating rr-cache directory and pointing it at the repo...");

	// The way the rerere cache is actually shared is by making .git/rr-cache its own reposity.
	// Yes, we put Git inside of Git.
	run(["git", "init", rrPath]);
	string cwd = getcwd();
	chdir(rrPath);
	scope(exit) chdir(cwd);
	
	// We can make life a little more sane by only tracking the rr-cache branch
	run(["git", "remote", "add", "-t", "rr-cache", remote, remoteURL]);
	writeln("  Fetching rerere cache...");

	// A remote has the branch 'rr-cache', switch to it
	if (execute(["git", "fetch"]).status == 0) {
		writeln("  Checking out existing shared rerere cache...");
		run(["git", "checkout", "rr-cache"]);
	}
	// Otherwise create an orphan branch and push it up
	else {
		writeln("  Creating and pushing new rerere cache branch to " ~ remote ~ "...");
		run(["git", "checkout", "--orphan", "rr-cache"]);
		run(["git", "rm", "-rf", "--ignore-unmatch", rrPath]);
		run(["git", "commit", "-a", "--allow-empty", "-m",
			"Automatically creating branch to track conflict resolutions"]);
		run(["git", "push", remote, "rr-cache", "-u"]);
	}
}

/// Enforces that we have set up the shared rerere cache
void enforceRerereSetup()
{
	enforceInRepo();
	string rrGitDir = getRepoRoot() ~ "/.git/rr-cache/.git";
	enforce(exists(rrGitDir) && isDir(rrGitDir),
		"The shared rerere cache has not been set up.");
}

/// Pulls the rr-cache branch from the remote
void pullRerere()
{
	enforceRerereSetup();
	string rrPath = getRepoRoot() ~ "/.git/rr-cache";
	string cwd = getcwd();
	chdir(rrPath);
	scope(exit) chdir(cwd);
	writeln("Pulling the latest conflict resolutions...");
	run(["git", "pull"]);
}

/// Commits new rerere resolutions and pushes if there were any
void pushRerere()
{
	import std.regex;

	enforceRerereSetup();
	string rrPath = getRepoRoot() ~ "/.git/rr-cache";
	string cwd = getcwd();
	chdir(rrPath);
	scope(exit) chdir(cwd);
	writeln("Pushing your latest conflict resolutions...");

	// TODO: This follows what the ruby git_bpf gem does,
	//       but maybe a "git add ." would be simpler.
	enum newResolutionRegex = ctRegex!(`\?\?\s(\w+)`);

	auto newResolutions = run(["git", "status", "--porcelain"])
		.byLine
		.map!(s => s.matchFirst(newResolutionRegex))
		.filter!(m => m.to!bool) // Regex matches are converible to booleans if found
		.map!(m => m[1]); // The first match is the directory of the resolution

	bool pushNeeded = !newResolutions.empty;

	foreach (r; newResolutions) {
		writeln("Sharing resolution ", r, "...");
		run(["git", "add", r.to!string]);
		run(["git", "commit", "-m", "Sharing resolution " ~ r.to!string]);
	}

	if (pushNeeded) {
		writeln("Pushing resolutions...");
		run(["git", "push"]);
	}
}

/// The entry point for "bmpt share-rerere"
void syncRerere(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	if (args.length > 0)
		writeHelp(helpText);

	syncRerere();
}

/// Pulls and then pushes the rerere cache
void syncRerere()
{
	pullRerere();
	pushRerere();
}

private string helpText = q"EOS
Usage: bmpt share-rerere

Pulls conflict resolutions from the rr-cache branch,
adds new ones,
and pushes the branch back (if needed) to the remote repo

Options:

  --help, -h
    Display this help text.
EOS";
