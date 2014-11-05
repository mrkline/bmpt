import std.json;
import std.net.curl;
import std.stdio;
import std.exception;
import std.conv;

/// The current Pivotal Tracker API base URL
private immutable string APIURL = "https://www.pivotaltracker.com/services/v5/";

private JSONValue performJSONRequest(ref HTTP request, string token)
{
	string buffer;

	request.addRequestHeader("X-TrackerToken", token);
	request.addRequestHeader("Content-Type", "application/json");
	request.onReceive = (ubyte[] data) {
		buffer ~= cast(const(char)[])data;
		return data.length;
	};
	request.perform();
	auto response = parseJSON(buffer);
	enforce(request.statusLine.code == 200,
	        "The " ~ request.method.to!string() ~ " failed with HTTP code " ~
	        request.statusLine.code.to!string() ~ " and the following response:\n" ~
	        response.toPrettyString());

	return response;
}

// HTTP.postData only seems to work for POST and hangs otherwise,
// so we'll roll our own here.
// This is lovingly borrowed from how Phobos does the high-level HTTP stuff.
private @property outgoingData(ref HTTP request, const(void)[] sendData)
body
{
	import std.algorithm : min;

	request.contentLength = sendData.length;
	auto remainingData = sendData;
	request.onSend = delegate size_t(void[] buf)
	{
		size_t minLen = min(buf.length, remainingData.length);
		if (minLen == 0) return 0;
		buf[0..minLen] = remainingData[0..minLen];
		remainingData = remainingData[minLen..$];
		return minLen;
	};
}

/// GETs something from the API at the given endpoint using the given API token
JSONValue get(string token, string endpoint)
{
	auto request = HTTP();
	request.method = HTTP.Method.get;
	request.url = APIURL ~ endpoint;
	return performJSONRequest(request, token);
}

/// PUTs something from the API at the given endpoint using the given API token
void put(string token, string endpoint, JSONValue val)
{
	auto request = HTTP();
	request.method = HTTP.Method.put;
	request.url = APIURL ~ endpoint;
	request.outgoingData = val.toString();
	performJSONRequest(request, token);
}

/// Grab the Pivotal Tracker API token from the environment.
/// Note that this throws an exception if it is not there.
@property string environmentPivotalToken()
{
	import std.process;
	return environment["PIVOTAL_TRACKER_TOKEN"];
}

/// Gets info on the PT user from their API token
JSONValue getMe()
{
	return get(environmentPivotalToken, "me");
}

/// Gets a PT story based on the provided ID
JSONValue getStory(string storyID)
{
	writeln("Fetching story ", storyID, " information from Pivotal Tracker...");
	return get(environmentPivotalToken, "stories/" ~ storyID);
}

/// Starts a PT story based on the provided ID
void start(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "started"]));
}

/// Finishes a PT story based on the provided ID
void finish(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "finished"]));
}

/// Accepts a PT story based on the provided ID
void accept(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "accepted"]));
}

/// Rejects a PT story based on the provided ID
void reject(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "rejected"]));
}
