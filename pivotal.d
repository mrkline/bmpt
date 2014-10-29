import std.json;
import curl = std.net.curl;
import std.stdio;

/// The current Pivotal Tracker API base URL
private immutable string APIURL = "https://www.pivotaltracker.com/services/v5/";

/// GETs something from the API at the given endpoint using the given API token
JSONValue get(string token, string endpoint)
{
	auto client = curl.HTTP();
	client.addRequestHeader("X-TrackerToken", token);
	return parseJSON(curl.get(APIURL ~ endpoint, client));
}

/// PUTs something from the API at the given endpoint using the given API token
void put(string token, string endpoint, JSONValue val)
{
	auto client = curl.HTTP();
	client.addRequestHeader("X-TrackerToken", token);
	client.addRequestHeader("Content-Type", "application/json");
	curl.put(APIURL ~ endpoint, val.toString(), client);
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
