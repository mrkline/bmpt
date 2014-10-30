import std.stdio;

import pivotal;
import help;

void writeWhoami()
{
	auto me = getMe();
	writeln("Username:  ", me["username"], " (", me["initials"], ")");
	writeln("Email:     ", me["email"]);
	writeln("Id:        ", me["id"]);
	writeln("API Token: ", me["api_token"]);
	writeln("Projects:");
	foreach(p; me["projects"].array) {
		writeln(p["project_name"], " [", p["project_id"], "] ", p["role"]);
	}
}

/// The entry point for bmpt whoami
void writeWhoami(string[] args)
{
	import std.getopt;

	getopt(args,
		std.getopt.config.caseSensitive,
		"help|h",  function void() { writeHelp(helpText); });

	args = args[2 .. $];

	if (args.length > 0)
		writeHelp(helpText);

	writeWhoami();
}

private string helpText = q"EOS
Usage: bmpt whoami

Prints your username, email, ID, API token, and projects from Pivotal Tracker.
Mostly useful as a quick smoke test to check the PT API.

Options:

  --help, -h
    Display this help text.
EOS";
