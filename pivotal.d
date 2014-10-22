import std.json;
import std.net.curl;
import std.stdio;

private immutable string APIURL = "https://www.pivotaltracker.com/services/v5/";

JSONValue get(string token, string endpoint)
{
	auto client = HTTP();
	client.addRequestHeader("X-TrackerToken", token);
	return parseJSON(std.net.curl.get(APIURL ~ endpoint, client));
}

void put(string token, string endpoint, JSONValue val)
{
	auto client = HTTP();
	client.addRequestHeader("X-TrackerToken", token);
	client.addRequestHeader("Content-Type", "application/json");
	// writeln("Putting ", APIURL, endpoint, ": ", val.toString());
	std.net.curl.put(APIURL ~ endpoint, val.toString(), client);
}

@property string environmentPivotalToken()
{
	import std.process;
	return environment["PIVOTAL_TRACKER_TOKEN"];
}

JSONValue getMe()
{
	return get(environmentPivotalToken, "me");
}

JSONValue getStory(string storyID)
{
	writeln("Fetching story ", storyID, " information from Pivotal Tracker...");
	return get(environmentPivotalToken, "stories/" ~ storyID);
}

void start(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "started"]));
}

void finish(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "finished"]));
}

void accept(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "accepted"]));
}

void reject(string storyID)
{
	put(environmentPivotalToken, "stories/" ~ storyID, JSONValue(["current_state" : "rejected"]));
}
