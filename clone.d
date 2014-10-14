import std.stdio;
import std.file;
import std.string;
import std.process;

import help;
import processutils;
import rerere;
import git;

void cloneBPF(string[] args)
{
	import std.getopt;

	string remote = "origin";

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); },
		"origin|o", &remote);

	// We don't care where we came from and we know the first arg after that was "clone"
	args = args[2 .. $];

	// We should have a single argument at this point: the remote URL
	if (args.length > 2)
		writeHelp(helpText);

	string[] cloneArgs = ["-o", remote] ~ args;

	// Git prints the directory we're cloning into on the first line.
	// Grab that
	writeln("Cloning repository...");
	string clonedDir = cloneRepo(cloneArgs);
	chdir(clonedDir);
	createOrCheckout("dev", remote);
	createOrCheckout("rc", remote);
	setupRerere(args[0], remote);
}

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
		run(["git", "checkout", "-b", branch], noRedirect);
		run(["git", "commit", "-a", "--allow-empty", "-m",
			"Automatically creating " ~ branch ~ " branch"], noRedirect);
		run(["git", "push", remote, branch, "-u"], noRedirect);
	}
}

private string helpText = q"EOS
Usage: bmpt clone [-o <name>] <remote URL> [<directory>]

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
