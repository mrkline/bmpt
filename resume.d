import std.exception;
import std.stdio;

import git;

shared static void function()[string] resumeHandlers;

class ResumeNeededException : Exception
{
	this(string message)
	{
		super(message);
	}

	this()
	{
		super("bmpt must be resumed after some manual intervention.");
	}
}
