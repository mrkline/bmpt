# BMPT

by Matt Kline, Fluke Networks

## What the?

BMPT is Branch Management for Pivotal Tracker.

More specifically, it's a tool to assist with a Branch-Per-Feature (BPF) workflow using Pivotal.

## Why?

At the time of writing, Fluke already has BPF tooling that works with Pivotal Tracker.
However, it has the following perceived shortcomings (listed roughly from most to least important):

1. If a merge to the `dev` or `rc` branch fails, which is a normal and common occurrence in a BPF workflow,
   the existing tooling waves you good luck and bails.
   Once you manually complete the merge, you are left to manually finish the tasks the tool would normally do
   (there is no "resume after merge" functionality).
   Ideally, the tool would automatically resume itself after you manually handle the merge.

2. Current BPF tools have several major dependencies including Ruby, RubyGems, Python's setuptools,
   and several Python packages through setuptools.
   While these may already be on the system of someone who does lots of web development,
   the BPF tooling is used across many other projects as well.
   It took me a while to poke my system so that everything was set up right.
   Ideally, the tool would contain fewer dependencies.

3. Commands in the existing tools that merge your branch's work into the `dev` or `rc` branch
   also insist on performing a commit first, even if one does not need to be made
   (and will complain if you do not provide a message for the unneeded commit).
   In my opinion, this is conflating two separate actions.
   In any normal git workflow, I would never expect a merge command to also commit my changes to my current branch.

4. The code of the existing tools is not divided into each subcommand.
   _All_ command line arguments are checked up front, even if the given subcommand doesn't need them.
   Additional logic up front maintains a comprehensive list of what subcommands need what certain arguments.
   More cleanly dividing work into each subcommand may result in a cleaner architecture.

None of these are dealbreakers, but this past Friday (2014-10-03) was Prometheus Day at FNet,
where engineers are invited to take a day to explore and experiment with ideas they have.
Since I use our BPF tools on a daily basis, I wanted to see what I could do to improve the situation.

## Goals

BMPT aims to address the concerns listed above by doing the following:

1. Use Git's post-commit hook and create some flag file in the `.git` directory
   in order to automatically resume once the user has finished their merge.

2. Have zero dependencies.
   BMPT is written in D.
   ([For an in-depth rationale, see my "Why D?" gist.](https://gist.github.com/mrkline/6682e4c507acaab3e447))
   By using D's excellent standard library tools for calling other processes such as Git
   and by calling Pivotal Tracker's web API using built-in cURL support,
   BMPT requires nothing but the [D compiler](http://dlang.org/download.html),
   which is provided on all major OSes.

3. Be a drop-in replacement and work in conjunction with existing tools.

4. BMPT's architecture is (hopefully) cleaner:

   - The main module is just a glorified `switch` statement and does little more
     than hand off the command line arguments to a subcommand's module.

   - Each subcommand module contains its own argument parsing, help text, etc.
     Of course, behavior shared among subcommands is broken out into its own modules to avoid code duplication.

5. Be more explicit about what Git commands it is issuing so that it is less of a black box.
   In the future this may be enabled or disabled with some `--verbose` switch.

6. Have a simple `share-rerere` command in order to share resolutions if this needs to be done manually for some reason.

## Why did you decide to rewrite the whole thing (in a different language, no less) instead of trying to improve the existing tooling?

1. The above design goals call for a fairly different architecture than what is in place now.
   A rewrite will arguably take less time than wrangling the existing code base.

2. The goal of "zero dependencies" throws a wrench on using what we have now, as what we have now leans
   on third-party BPF scripts in Ruby.

3. While I realize that it's important to focus on what you build with your tools and not the tools themselves,
   I am a language nerd and really like D.
   I hope it can find its way into common use at Fluke Networks,
   and I think one of the best ways to do so is to demonstrate its merit with small, supporting projects like this.

## So what do you have so far?

So far `clone`, `new`, `whoami`, and `share-rerere` are implemented.
My hope was to crank out a decent proof of concept over the weekend,
but oddly enough, this is a complex tool and developing it will take longer than I initially expected.

## So... timetable?

I'll continue working on this in my free time and if I have downtime between assignments.
Soon?
