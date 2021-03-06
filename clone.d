import std.stdio;
import std.file;
import std.string;
import std.process;

import help;
import processutils;
import rerere;
import git;

/// The entry point for "bmpt clone"
void cloneBPF(string[] args)
{
	import std.getopt;

	// If one isn't specified, assume the remote is "origin"
	string remote = "origin";

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"origin|o", &remote);

	// We don't care where we came from and we know the first arg after that was "clone"
	args = args[2 .. $];

	// We should have no more than two arguments at this point:
	// the remote URL and possibly a directory.
	if (args.length > 2)
		writeHelp(helpText);

	string[] cloneArgs = ["-o", remote] ~ args;

	// Git prints the directory we're cloning into on the first line.
	// Grab that
	writeln("Cloning repository...");
	string clonedDir = cloneRepo(cloneArgs);
	chdir(clonedDir);

	// Create or checkout the dev and rc branches for BPF workflow.
	createOrCheckout("dev", remote);
	createOrCheckout("rc", remote);
	setupRerere(args[0], remote);

	writeln(`Adding "bmpt resume" to the post-commit hook...`);
	runShell(`echo "bmpt resume --silent" >> .git/hooks/post-commit`);
	// TODO: We want a Windows equivalent too
	run(["chmod", "+x", ".git/hooks/post-commit"]);
}

/// Checks out a branch if it exists.
/// If it doesn't, create the branch and push it to the provided remote.
void createOrCheckout(string branch, string remote = "origin")
{
	// A remote has the branch 'rr-cache', switch to it
	if (executeShell("git branch -r | grep " ~ branch).status == 0) {
		writeln("Checking out existing " ~ branch ~ " branch...");
		run(["git", "checkout", branch]);
	}
	// Otherwise create an orphan branch and push it up
	else {
		writeln("Creating and pushing new " ~ branch ~ " branch to " ~ remote ~ "...");
		run(["git", "checkout", "-b", branch]);
		run(["git", "commit", "-a", "--allow-empty", "-m",
			"Automatically creating " ~ branch ~ " branch"]);
		// Don't redirect output for push since it can take a larger amount of time.
		run(["git", "push", remote, branch, "-u"], noRedirect);
	}
}

private string helpText = q"EOS
Usage: bmpt clone [-o <name>] <remote URL> [<directory>]

Clones a git repository and sets it up for BPF usage. This includes
- Creating dev and rc branches
- Creating a shared rerere cache by enabling rerere and turning .git/rr-cache
  into a git repo that points at the rr-cache branch of the given remote URL.
- Adding "bmpt resume --silent" to the post-commit hook

Options:

  --help, -h
    Display this help text.

  --origin, -o <name>
    Specify the remote name. Defaults to "origin", just like Git normally does.

  <remote URL>
    The URL of the repository to clone

  <directory>
    The directory in which to clone
EOS";
