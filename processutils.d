import std.process;
import std.array;
import std.stdio;
import std.exception;
import std.string;
import std.typecons;

enum stderrToStdout = Redirect.stdout | Redirect.stderrToStdout;

enum noRedirect = cast(Redirect)0;

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

		string exceptionMessage = commandAsString ~ " failed. ";

		if ((flags & Redirect.stderrToStdout) == Redirect.stderrToStdout) {
			exceptionMessage ~= "Stderr was redirected to stdout.";
		}
		else if ((flags & Redirect.stderr) != cast(Redirect)0) {
			// Add no message about stderr (stderr was not redirected)
		}
		else {
			// Take stderr by line (as this is a convenient way to get its string value)
			// and join those lines together
			string stderr = pipes.stderr.byLine(KeepTerminator.yes).join().strip().idup;
			if (stderr.length > 0)
				exceptionMessage ~= "Stderr was empty.";
			else
				exceptionMessage ~= "Stderr contained:\n" ~ stderr;
		}

		throw new ProcessException(exceptionMessage);
	}
	if ((flags & Redirect.stdout) == cast(Redirect)0)
		return File.init;
	else
		return pipes.stdout;
}

auto run(S)(S command, Redirect flags = Redirect.stderr | Redirect.stdout)
{
	return runTemplate!pipeProcess(command, flags);
}

auto runShell(S)(S command, Redirect flags = Redirect.stderr | Redirect.stdout)
{
	return runTemplate!pipeShell(command, flags);
}

string firstLineOf(S)(S command, Redirect flags = Redirect.stderr | Redirect.stdout)
	if (is(S == string) || is(S == string[]))
{
	auto output = run(command, flags).byLine;
	enforce(!output.empty, "The command returned no output.");
	return output.front.strip().idup;
}
