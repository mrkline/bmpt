import std.stdio;

import pivotal;

void writeWhoami()
{
	auto me = getMe();
	writeln("Username:  ", me["username"], " (", me["initials"], ")");
	writeln("Email:     ", me["email"]);
	writeln("Id:        ", me["id"]);
	writeln("API Token: ", me["api_token"]);
	writeln("Projectss:");
	foreach(p; me["projects"].array) {
		writeln(p["project_name"], " [", p["project_id"], "] ", p["role"]);
	}
}
