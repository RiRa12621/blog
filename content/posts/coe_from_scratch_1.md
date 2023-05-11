---
title: "Writing a Container Platform - Part 1"
author: "Rick Rackow"
date: 2023-05-08T16:35:50+01:00
subtitle: "The Foundation"
image: ""
tags: ["Cloud","CoE","pleaco", "Docker", "Containers", "Platform Engineering"]
---

After spending a lot of time on Stack Overflow recently, a thought started pestering my brain: why is Kubernetes so complicated?
This was followed by "Can I build something simpler?", and so here we are, building our own Container Platform from scratch. Platform engineering is super hot right now so let's have our own go at it. At the end of the whole thing, you will find the whole result oin [GitHub](https://github.com/pleaco), Open Source of course.

## What do we need?

Let's try to see the big picture here. We don't want to run things for the sake of running them, but rather create value. For example a webapp doesn't create value by just being run on the coolest tool on the shelf, but rather by being used by users, therefore everything else is secondary. Where it runs and how it runs doesn't really matter all that much. Sure, at a certain stage there are some legal obligations and the like, but we will ignore that for the beginning.

Back to the topic, so we want to run containers, but it would be cool if we could build them right from source, this also means we need to get the source. If we build it, we probably also want to test it, and it would be nice if we could also have some security built-in like basic vulnerability scanning. So here's what we need:

* Connect to Source Code Management(SCM), git for starters, precisely GitHub
* Pull and store source code
* Build container image for source code
* Run tests in container
* Expose container to the world
* Scale

The last one might make this whole thing a bit problematic, but it would be cool we could have more or less instances of our container and make that depend on the traffic we get, which probably also means that we will need some mechanism to collect metrics.

## Name

Naming things is hard so why not postpone it? Apparently, we will need a GitHub org and repo rather sooner than later to put our work, test everything and get other folks to contribute. Hence, we need a name. We want an easy container platform.

* **Ea**sy
* **Co**ntainer
* **Pl**atform

Since EaCoPl might be a little hard to pronounce, we shuffle a little and voilà _pleaco_ is born. That should about do it for now. Once it's done I might add another domain to my sheer infinite list of "I really need that domain"-purchases.

## Design

Frankly, we will just wing it and learn along the way. So expect progress while you're reading as opposed to a "here are all the answers" blog. The biggest challenge will be to start with an open mind and not get tangled up with what we're used to and then we should be fine. Some things however we do have to think about upfront. Keep in mind that everything is in flux, so if we discover along the way that something isn't working the way we want it to or, worst case, not at all, we will adjust and move on.

### Cluster layout and Consistency
 One of the things we need to think about is the cluster layout and sync. Preferably we will not have different classes of nodes, so no "Server-Node" where each type of instance would do different tasks. The idea is that cluster sizing is completely dynamic and no type of instance is a bottleneck. This means that they somehow need to stay in sync with one another about certain things like which nodes are part of the cluster, which containers are running, where, how many and so on. Everything should be replicated across all nodes, so we don't have issues with a single node going down. There will be a bit of a price to that in terms of storage and compute but since we're not going thousands of nodes for now, the overhead shouldn't be too big.

The elephant in the room is _consistency_. If we assume that in a strong consistency model, the latest read should return the results of the latest write, we have to ask ourselves if we need that. What are we really storing? Each node must know about all cluster nodes, all running containers, all tasks basically, but does it need to know that right after it's been added? Let's hope not. Strongly consistent databases and key-value-stores are really hard to build, run and scale and that's the opposite of what we want, so we'll go with a BASE(Basic Availability, Soft state, Eventual consistency) guarantee for now and see how things work out.


### How to run containers?

The simpler, the better, and so we will just go with [Docker Engine](https://docs.docker.com/engine/) for now. It's well documented, not super tied into the Kubernetes ecosystem anymore and there's an [SDK](https://docs.docker.com/engine/api/sdk/) that makes working with it pretty smooth.


### How to build containers?

We are going with [kaniko](https://github.com/GoogleContainerTools/kaniko) here. Mainly we want to contain (no pun intended) everything into containers and not run something additionally on the hosts, and also I was planning to play with kaniko for a while now already, so this seems like a good time.

### Packaging, distribution and installing

I like the idea of having a golden image. Take the image, install it, done. No manual post-install or even running things on the CLI. Obviously there are downsides with the most prominent one being configuration drift, where your running instance will have strongly diverged from the desired and latest version, so we need to make it possible for pleaco to alter the system it's running on which makes every alarm bell of a security engineer ring. However, we will try for now, and if that doesn't work we still got bash scripts to the rescue until we find something better. So with our golden image, we can also integrate with most infrastructure as code (IaC) solutions because there we'd just specify and image to run.

The biggest issue when installing a node is how to find a cluster to join and do that or, alternatively, determine that it's the first and/or only node and just start to function.


## The Codebase

We mainly split between the UI, which due to really poor frontend skills on my end, we will create later, and the rest. Where "the rest" is really the core including an API to for a given CLI tool or the webUI to talk to. Yes, this is definitely a monolith and given that we set out to build something simple this seems pretty on point.  


## The Process

Learn as we go. Sure an SRE background is helpful here but there is so much to discover here, and so we're off for a good time. I'll try to write about the progress more or less frequently and share what's happening and how, so keep your eyes peeled for more posts.
