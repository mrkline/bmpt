import std.process;
import std.array;
import std.stdio;
import std.exception;
import std.string;
import std.typecons;

// A quick convenience value that redirects stdout and redirects stderr to it
enum stderrToStdout = Redirect.stdout | Redirect.stderrToStdout;

// Don't redirect anything
enum noRedirect = cast(Redirect)0;

/**
 * We want two functions: one for running straight processes
 * and one for running shell commands.
 * Since they'll be identical in every way except the one function they call
 * to light things off, we'll define a function template here
 * and then instantiate it below.
 *
 * The "alias" template parameter is passed by name,
 * like the arguments for a #define macro in C and C++.
 */
File runTemplate(alias runWith, S)(S command, Redirect flags)
	if (is(S == string) || is(S == string[]))
{
	auto pipes = runWith(command, flags);

	if (wait(pipes.pid) != 0) {
		string commandAsString;
		// We can check at compile time what the type of "command" is
		// and act accordingly.
		static if (is (typeof(command) == string)) {
			commandAsString = command;
		}
		else {
			commandAsString = command.join(" ");
		}

		string exceptionMessage = commandAsString ~ " failed.";

		if ((flags & Redirect.stderrToStdout) == Redirect.stderrToStdout) {
			exceptionMessage ~= " Stderr was redirected to stdout.";
		}
		else if ((flags & Redirect.stderr) != noRedirect) {
			// Add no message about stderr (stderr was not redirected)
		}
		else {
			// Take stderr by line (as this is a convenient way to get its string value)
			// and join those lines together
			string stderr = pipes.stderr.byLine(KeepTerminator.yes).join().strip().idup;
			if (stderr.length > 0)
				exceptionMessage ~= " Stderr was empty.";
			else
				exceptionMessage ~= " Stderr contained:\n" ~ stderr;
		}

		throw new ProcessException(exceptionMessage);
	}
	// Return a null file handle if nothing was redirected
	if ((flags & Redirect.stdout) == cast(Redirect)0)
		return File.init;
	// Otherwise return the stdout handle
	else
		return pipes.stdout;
}

/// Instantiate the template above with pipeProcess
/// as the function to light off the process
auto run(S)(S command, Redirect flags = stderrToStdout)
{
	return runTemplate!pipeProcess(command, flags);
}

/// Instantiate the template above with pipeShell
/// as the function to light off the process
auto runShell(S)(S command, Redirect flags = stderrToStdout)
{
	return runTemplate!pipeShell(command, flags);
}

/// Runs the provided command and gets its first line of output
string firstLineOf(S)(S command, Redirect flags = stderrToStdout)
	if (is(S == string) || is(S == string[]))
{
	auto output = run(command, flags).byLine;
	enforce(!output.empty, "The command returned no output.");
	return output.front.strip().idup;
}
