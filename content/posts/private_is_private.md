---
title: "Private is Private"
author: "Rick Rackow"
date: 2025-03-27T20:00:50+02:00
subtitle: "except on GitHub"
image: ""
draft: false
tags: ["security", "GitHub" ,"HackerOne"]
---

Before we get going with this one, I need to add a small disclaimer: I am not a
security researcher, neither a bug bounty hunter nor anything similar. That
means when I report a vulnerability somewhere, I either really wanted to try out
a technique that I read about, or I stumbled over it during my regular work.
Now, why am I mentioning this? Well, mostly to be clear that this is not how
I make a living. I work a regular job at [Codesphere](https://codesphere.com)
and that's what I get paid for, so I don't need vulnerabilities to be accepted
so that I can get paid. My biggest focus is always to make products I, or our
users use more secure.

Let's dive into the issue now.

## The issue

After coming out of some very long days with very short nights in the wake of
CVE-2025-1974 I was browsing through some code this morning. Nothing special
but in some places we have *very* big files checked in and then GitHub refuses
to render them directly and instead gives you the _raw_ version of it. So far
no big deal, but I had a question about some part of that code and sent it a
colleague on slack. I don't if it was the lack of sleep or the three Red Bulls
I had before 10am but something seemed off about the link that I just sent. I
looked at it for a little while, and then it hit: why is there `token` parameter
in the URL and what is that token? I didn't put it in there. 

A small detail that I left out, is that this repository that contains the code
in question is actually private because it's basically part of our product.
When I say "private" I mean that it's in a private GitHub repository. 

Could it be that this `token` parameter is actually allowing me to see this
URL? Nah. Can't be. They wouldn't, or would they? 

Let's reproduce this for you in a separate repository, so you can tag along.

We start off with a fresh repo, that is set to "Private".

![RepoCreate](/imgs/private_is_private/repo_create.png)


Next we add a file. It doesn't really matter, what it is, since we don't want
to run this code anyone, so just some very easy `main.go` will do:

```go
package main

import "fmt"

func main() {

	fmt.Println("Only I should ever read this!")

}
```

Good, just to recap: we have a file in *private* repository. This repository is
under my user, so the only person to be able to see this file should be me?
We agree so far?

Next, we need to look at the `raw` file. To do that, you go to the file in the
GitHub UI and then on the right, you will find a little button like this:

![RawButton](/imgs/private_is_private/raw_button.png)

When you click that, GitHub takes you to a page that has a structure of
`https://raw.githubusercontent.com/<org>/<repo>/refs/heads/<branch>/filename`,
which so far makes total sense, but then there is this token again. So the total
URL for this example is
`https://raw.githubusercontent.com/RiRa12621/not_so_private/refs/heads/main/main.go?token=GHSAT0AAAAAACTNX6FVGOVMS7TIU2HI2STSZ7FV4IA`:

![BrowserView](/imgs/private_is_private/browser_view.png)

Again, this is a file in a private repository, so naturally it should not be
available in a scenario, where I'm not logged in, right? We are definitely not
logged in when we use `curl`, so let's see it:

```shell
$ curl https://raw.githubusercontent.com/RiRa12621/not_so_private/refs/heads/main/main.go?token=GHSAT0AAAAAACTNX6FVGOVMS7TIU2HI2STSZ7FV4IA
package main

import "fmt"

func main() {

        fmt.Println("Only I should ever read this!")

}
```

So we can just read this file in a private repository, not only without being
the right user but without being logged in at all? That doesn't feel right.
What if I pasted a link somewhere with my code from my company and someone was
to just copy it because they don't need to be me or anyone I allow in my repo,
to view the file?

In my opinion that's not good and that sounds like a clear information
disclosure vulnerability. I tested if the same is possible on Gitlab, and it's
not. No weird token, you don't get anything on a curl and if you pull it up in
a private browser window, you're also asked to authenticate, so I was pretty
sure this had to be an issue.

What do we do as good citizens of the internet? Report those things!

## The Disclosure

GitHub has a vulnerability disclosure program that they run through ackerone.
If you're not familiar with how those things work, let's break it down:

If you are a company you would rather have people report vulnerabilities to you
than have them just sit on them, so companies basically offer vulnerability
disclosure programs(VDP). I'll really not get into the details of the different ways
to do this, but let's just assume there are some programs that are also
incentivizing security researchers with money or swag or other stuff. If a
company does that in a very structured way, you basically have a bug bounty
program where the company essentially says "you find vulnerabilities, we pay you".
There are some folks that do just that for a living, and they have sick stories
to tell about research and methods and all things, definitely check some of those
out, but that's where our note from the very beginning comes into play: that's
not what I do. I just want this to be fixed. 

Let's get back to the topic. I went to [hackeron](https://hackerone.com), found
the GitHub VDP and started to craft my report. I'll be honest this isn't the
most sophisticated of reports, but should get the issue across. Here's what I
wrote:



>Description:
> 
>raw view of files in private repositories adds an access token to the URL, which is allows viewing the content unauthenticated.
>
>Steps To Reproduce:
> 
>(Add details for how we can reproduce the issue)
> 
>Create private repository
> 
>add file
> 
>click raw view
> 
>copy URL (it includes the token like so githubusercontent.com/rira12621/some-repo/some/ref/branch/some.yml?token=GHSAT0AAAAAACTNX6FU5WT54ZXRAMZ7VAK6Z7FEO2A)
>
>Open the URL in a private sessions, or other where you are not logged in to github at all.
>
>I haven't verified yet the permissions of the token and the longevity.

>Impact
> 
>Users often share links to code files, sometimes as raw, larger files by default aren't rendered and can only be viewed as raw. Sharing this link now allows anyone, even unauthenticated users, to access the given code, leading to possible information disclosure of proprietary information and code.
>
>Users don't expect links to code to be containing secrets and therefore having to treat them as secrets. This essentially means that users have to sanitize every raw link to code and strip it from the token to avoid accidentally sharing secrets


As per my understanding this should have been enough to make the problem clear.
Hackerone additionally allows has you tick some boxes so you get to a CVSS
rating for your report and here's mine:

![CVSSRating](/imgs/private_is_private/cvss.png)

It calculates the score and the rating automatically after you fill in the other
stuff. Keep in mind that this is from an attacker perspective:

>Attack Vector --> Network

That seems pretty clear, you can do this over the network and not local or
physical or something.

>Attack Complexity --> Low

Give me the link and I can view it

>Privileges Required --> Low

Low, because the person that creates the link needs to be able to view the file.

>User Interaction --> Required

Sure, as an attacker I need someone to send me the link.

>Scope --> Unchanged

You can only view the file that you have the link for and not move laterally.

>Confidentially --> High

This is a *private* file that anyone under the sun with an internet connection
can view.

>Integrity --> None

The system isn't impacted by viewing a file.

>Availability --> None

This also doesn't have any effect on GitHub's availability



After I submitted this, I basically did some more testing, and it turns out
that you can also view the logs of GitHub actions publicly if you click the
`raw` button and get that link. That is even worse, because people are
apparently very sloppy with keeping tokens out of their logs. However, the
url for raw build logs at least has an expiration in it, that's set to 10
minutes after you clicked the button.

I added that information in a comment:

>As opposed to other URLs like raw logs of GitHub actions, this does not seem to be short-lived.
>
>To be clear, raw action logs are also public for unauthenticated users but only for as long as the expiration, which seems to be 10m by default.

I'll be honest: I was dead sure this was an issue and at the pointing of writing
this post, still am.

Here's the answer I received from the triager and I'll give you the screenshot
so we're clear that I did not make the tiniest bit up:

![TriageResponse](/imgs/private_is_private/triage_response.png)

>working as expected and does not present a security risk


That's about all there is to say about that. Let alone that half the things
aren't really correct like this "cryptographically signed token". I might
believe that, if I wouldn't spend more than 2 hours a week in the GitHub docs
and be familiar with [this blog](https://github.blog/engineering/platform-security/behind-githubs-new-authentication-token-formats/#identifiable-prefixes)
where they kindly explain how they prefix their various tokens, which means
that we're most likely looking at "server to server" token here. Also, nothing
in the url is dynamically generated, as we looked at the scheme it follows
earlier in this post. The only "dynamic" thing in here is the token. 

Last but not least this is the annoying bit:

>This token is time limited and should not be shared to others that you do not wish to give access to a file with.

It's not the world's greatest implementation to have that token in there, but like
have you considered to at least document that somewhere if you already think
that it's the right way to do this or if not, then acknowledge that fact in the
triage response? No, of course not. 

Ultimately the outcome is that what's in a private repo, is not private, if you
share a link to it and this "working as expected and does not present a security risk".

So be sure to maybe not share those links around.


Last but not least: the tokens do, in fact, expire after a while, so every
token you will see in this blog post will have expired already, by the time you
read it.
