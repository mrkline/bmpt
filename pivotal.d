import std.json;
import std.net.curl;

private immutable string APIURL = "https://www.pivotaltracker.com/services/v5/";

JSONValue get(string token, string endpoint)
{
	auto client = HTTP();
	client.addRequestHeader("X-TrackerToken", token);
	return parseJSON(std.net.curl.get(APIURL ~ endpoint, client));
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
	return get(environmentPivotalToken, "stories/" ~ storyID);
}
