---
title: "Writing a Container Platform - Part 3"
author: "Rick Rackow"
date: 2023-05-19T20:35:50+01:00
subtitle: "Repo me"
image: ""
draft: false
tags: ["Cloud","CoE","pleaco", "Docker", "Containers", "Platform Engineering"]
---

This one will be a little shorter, but still something worth talking about: how to set up the repo. I know, I know: "Just click the button". That's not really what I mean. It is more about everything I like to have in repo.


## Community standards

### License

The license topic has gotten pretty hot recently with a bunch of OSS projects moving to very interesting forms of licensing be it SSPL like Elastic and MongoDB haven chosen to or AGPL like Grafana. None of these are relevant for what we are doing here right now, and they're also having their own caveats which are caused by their purpose: protect the main contributor companies. I'll not spark a discussion on this topic, the fact is, we want to use a significantly more open license: Apache 2.0. As for all things there is a great [website](https://opensource.guide/legal/) explaining the importance of licenses and the implications. What matters for us is really the community acceptance but also what it has to offer. The tl;dr is that you can do whatever you want with the code, we're not liable for that, and you can't use the "pleaco" trademark (which we don't have at this point). You can find more choices for licenses [here](https://choosealicense.com/licenses/apache-2.0/) as well as the whole License print.

Nicely enough GitHub lets you pick a license when you create a repo. All that is happening, is that a `LICENSE` file containing the license text is placed in the repository like. You can therefore find the one for pleaco [in the repo](https://github.com/pleaco/pleaco/blob/main/LICENSE).

### Code of Conduct

It is extremely easy to have one generated for you, and it really makes it clear that you care about certain basic values. By now you can do this from your repo: go to _insights_ --> _community standards_ and pick the CoC that you want. I'll use the "Contributor Covenant". Just fill in a contact email that you will actually monitor. The best CoC is worthless if it's not enforced. Best case is that it should never happen, but if anything is wrong, you must make sure to act. 

Here's the tl;dr of what's unacceptable and frankly speaking, that's a very low bar:

* The use of sexualized language or imagery, and sexual attention or advances of any kind
* Trolling, insulting or derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or email address, without their explicit permission
* Other conduct which could reasonably be considered inappropriate in a professional setting


Now commit it and off you go.

### The others
As you might have seen when looking at the "insights" tab, there are some more things that you can and should do, but I like to add most things there over time. The reason being that I cannot figure them out before I have anything. I cannot tell anyone how to meaningfully contribute and help them with common steps before I wrote at least _something_. The same goes for a PR and issue template. At the beginning just let people open PRs and issues any way they want, later we want to add some more structure. 

Last but not least: security. This **is** really important, but not while it's not even built once, let alone running somewhere. As soon as we get a little closer to something that anyone outside of me might be running, we want to set up at least a basic security policy so people can know what to expect. If you click the button to add one, you will see that there's a template from GitHub as well:

```markdown

# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

Use this section to tell people how to report a vulnerability.

Tell them where to go, how often they can expect to get an update on a
reported vulnerability, what to expect if the vulnerability is accepted or
declined, etc.


```


All in all GitHub is doing a great job here guiding people along with the basics for a repo. This doesn't make community work and community building obsolete but it aids the beginning.


## Actions

I like to have the basic automation in place as early as possible. In our case we want to build a go application, so we will add an action. We can do this from the UI or by checking in files. The latter can be scripted easily, so you can make it part of your "repo_init" script, should you decide to have one. Here's the steps:

* create `.github` folder
* in `.github` create `workflows` folder
* add action as yaml file

We can do the first two in one go:

```bash
mkdir -p .github/workflows
```


Now if you have a template for an action, copy it in or use the following for a golang based project:


```yaml
# This workflow will build a golang project
# For more information see: https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-go

name: Go

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:

  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.19

    - name: Build
      run: go build -v ./...

    - name: Test
      run: go test -v ./...

```

This will run on any PR against the `main` branch as well as any direct push, and it will first try to "just" build the project and then try to run the tests.

Now check it in and browse to the actions tab of the repo. It should already be running for the first time.

I also like to have a status badge, so people know what to expect. To generate one, go your job, click the little dots and generate it. You will receive some markdown that you can put in the `README.md`. It should look something like this:


```markdown
[![Go](https://github.com/pleaco/pleaco/actions/workflows/go.yml/badge.svg)](https://github.com/pleaco/pleaco/actions/workflows/go.yml)
```


And that's pretty much it. With those simple steps you have a community ready repo, with a basic PR check. This is how I try to start most repos and also pleaco.
