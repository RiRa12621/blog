---
title: "Containerize Everything - Part 1"
author: "Rick Rackow"
date: 2024-06-13T20:00:50+02:00
subtitle: "First we need google stuff"
image: ""
tags: ["docker", "container", "chrome"]
---

It's been years and years since [Jessie Frazelle](https://x.com/jessfraz) actually gave a phenomenal talk about 
[Container Hacks and Fun Images](https://www.youtube.com/watch?v=cYsVvV1aVss). Basically this talk actually got me into
containers back then so shout-out to Jessie for that. However, it's been long 9 years, tools have changed, docker
changed and I feel like it's about time to give it a shot again, to try to stick everything in a container that's
needed for day to day work. Basically, we'll build our own
[Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/). 
I'll bring you along on the ride again (as per usual), so this is not going to be a pitch
perfect guide, but rather we'll be building those images and commands together. 


## Approach

Basically, we'll just go one-by-one through the tools we usually use and then stick them in a container. We'll try to
keep them as slim as possible all the time and the result should be that we can just use it directly from our machine.
So as an example, let's assume we need Chrome, then we want to be able to either click an icon or run a command like
`runChrome` and get the Chrome window on our desktop, but preferably without running a huge full-blown distro image like
`Ubuntu:latest` as the base.

This whole thing means that best case we can use `scratch` or `distroless` as base and if that doesn't work, then at
least try to use a `slim` or `tiny` version.

The way this will work usually is by just starting a basic docker image and then install and add what we need until
it works, then stick all that in a Dockerfile.

Short notice on OSS: obviously everything here will (or is already) released publicly. That means that all things
required to build the Dockerimages will be in [one repo](https://github.com/RiRa12621/dockerimages) and all the glue
code goes in [another repo](https://github.com/RiRa12621/dockerized-desktop).

### Builds
We'll try to automatically build all images via GitHub actions and where possible also have the whole thing be multi-arch
so that then each image lands in its own repo on DockerHub.


### Chrome
Can't browse the web, means you also can't google stuff if it's broken. So let's just start off with Chrome first. The
sad part is that we're going to break our base approach right on the first thing that we build: not starting from
scratch. We really don't have to make this extra hard on ourselves. 


#### The Image

Let's start with a Debian base. Why Debian? I really like Ubuntu from a desktop usability perspective but reality is,
that it's gotten very bloated and I absolutely despise Snaps by default. 

Let's find ourselves the latest small image on [DockerHub](https://hub.docker.com/_/debian). We can find that
`bookworm:slim` is the one that we want. So let's get started:


```shell
docker run -ti --rm debian:bookworm-slim /bin/bash
Unable to find image 'debian:bookworm-slim' locally
bookworm-slim: Pulling from library/debian
559a76444520: Pull complete
Digest: sha256:67f3931ad8cb1967beec602d8c0506af1e37e8d73c2a0b38b181ec5d8560d395
Status: Downloaded newer image for debian:bookworm-slim
root@0e4de49419c6:/#
```

By the way, in case you're wondering, there is a significant size difference:

```shell
$ docker images
REPOSITORY   TAG             IMAGE ID       CREATED       SIZE
debian       bookworm-slim   a7c3b4aaf0fc   8 hours ago   97.2MB
debian       latest          f9e0f24927db   8 hours ago   139MB
```

Might not look much in absolute numbers, but essentially we're looking at a roughly 40% bigger image and we didn't even
update a single image in there.

Now that that is done, and we're in the container, we can go ahead. Firstly make our way to
[https://www.google.de/linuxrepositories/](https://www.google.de/linuxrepositories/) where we can find some information
about Google's Linux packages and how to use and work with them. Since we have neither `curl` nor `wget` on the slim
image, we need to get that first and then download the signing key.

```shell

apt-get update -y && apt-get install -y wget
Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
Get:2 http://deb.debian.org/debian bookworm-updates InRelease [55.4 kB]
Get:3 http://deb.debian.org/debian-security bookworm-security InRelease [48.0 kB]
Get:4 http://deb.debian.org/debian bookworm/main arm64 Packages [8685 kB]
Get:5 http://deb.debian.org/debian bookworm-updates/main arm64 Packages [13.7 kB]
Get:6 http://deb.debian.org/debian-security bookworm-security/main arm64 Packages [157 kB]
Fetched 9110 kB in 1s (6748 kB/s)
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  ca-certificates libpsl5 libssl3 openssl publicsuffix
The following NEW packages will be installed:
  ca-certificates libpsl5 libssl3 openssl publicsuffix wget
0 upgraded, 6 newly installed, 0 to remove and 0 not upgraded.
Need to get 4494 kB of archives.
After this operation, 13.0 MB of additional disk space will be used.
Get:1 http://deb.debian.org/debian bookworm/main arm64 libssl3 arm64 3.0.11-1~deb12u2 [1803 kB]
Get:2 http://deb.debian.org/debian bookworm/main arm64 openssl arm64 3.0.11-1~deb12u2 [1385 kB]
Get:3 http://deb.debian.org/debian bookworm/main arm64 ca-certificates all 20230311 [153 kB]
Get:4 http://deb.debian.org/debian bookworm/main arm64 libpsl5 arm64 0.21.2-1 [58.6 kB]
Get:5 http://deb.debian.org/debian bookworm/main arm64 wget arm64 1.21.3-1+b1 [967 kB]
Get:6 http://deb.debian.org/debian bookworm/main arm64 publicsuffix all 20230209.2326-1 [126 kB]
Fetched 4494 kB in 1s (8836 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libssl3:arm64.
(Reading database ... 6084 files and directories currently installed.)
Preparing to unpack .../0-libssl3_3.0.11-1~deb12u2_arm64.deb ...
Unpacking libssl3:arm64 (3.0.11-1~deb12u2) ...
Selecting previously unselected package openssl.
Preparing to unpack .../1-openssl_3.0.11-1~deb12u2_arm64.deb ...
Unpacking openssl (3.0.11-1~deb12u2) ...
Selecting previously unselected package ca-certificates.
Preparing to unpack .../2-ca-certificates_20230311_all.deb ...
Unpacking ca-certificates (20230311) ...
Selecting previously unselected package libpsl5:arm64.
Preparing to unpack .../3-libpsl5_0.21.2-1_arm64.deb ...
Unpacking libpsl5:arm64 (0.21.2-1) ...
Selecting previously unselected package wget.
Preparing to unpack .../4-wget_1.21.3-1+b1_arm64.deb ...
Unpacking wget (1.21.3-1+b1) ...
Selecting previously unselected package publicsuffix.
Preparing to unpack .../5-publicsuffix_20230209.2326-1_all.deb ...
Unpacking publicsuffix (20230209.2326-1) ...
Setting up libpsl5:arm64 (0.21.2-1) ...
Setting up wget (1.21.3-1+b1) ...
Setting up libssl3:arm64 (3.0.11-1~deb12u2) ...
Setting up openssl (3.0.11-1~deb12u2) ...
Setting up publicsuffix (20230209.2326-1) ...
Setting up ca-certificates (20230311) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC contains: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.36.0 /usr/local/share/perl/5.36.0 /usr/lib/aarch64-linux-gnu/perl5/5.36 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.36 /usr/share/perl/5.36 /usr/local/lib/site_perl) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 7.)
debconf: falling back to frontend: Teletype
Updating certificates in /etc/ssl/certs...
140 added, 0 removed; done.
Processing triggers for libc-bin (2.36-9+deb12u7) ...
Processing triggers for ca-certificates (20230311) ...
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.

```

Next we get the signing key:

```shell
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg
```

Pleasures of working with a slim image. Let's try that again:

```Shell
apt-get install -y gnupg
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  dirmngr gnupg-l10n gnupg-utils gpg gpg-agent gpg-wks-client gpg-wks-server gpgconf gpgsm libassuan0 libgpm2 libksba8 libldap-2.5-0 libldap-common libncursesw6 libnpth0 libreadline8 libsasl2-2 libsasl2-modules libsasl2-modules-db libsqlite3-0 pinentry-curses readline-common
Suggested packages:
  dbus-user-session libpam-systemd pinentry-gnome3 tor parcimonie xloadimage scdaemon gpm libsasl2-modules-gssapi-mit | libsasl2-modules-gssapi-heimdal libsasl2-modules-ldap libsasl2-modules-otp libsasl2-modules-sql pinentry-doc readline-doc
The following NEW packages will be installed:
  dirmngr gnupg gnupg-l10n gnupg-utils gpg gpg-agent gpg-wks-client gpg-wks-server gpgconf gpgsm libassuan0 libgpm2 libksba8 libldap-2.5-0 libldap-common libncursesw6 libnpth0 libreadline8 libsasl2-2 libsasl2-modules libsasl2-modules-db libsqlite3-0 pinentry-curses readline-common
0 upgraded, 24 newly installed, 0 to remove and 0 not upgraded.
Need to get 9175 kB of archives.
After this operation, 21.3 MB of additional disk space will be used.
Get:1 http://deb.debian.org/debian bookworm/main arm64 readline-common all 8.2-1.3 [69.0 kB]
Get:2 http://deb.debian.org/debian bookworm/main arm64 libassuan0 arm64 2.5.5-5 [45.9 kB]
Get:3 http://deb.debian.org/debian bookworm/main arm64 libreadline8 arm64 8.2-1.3 [155 kB]
Get:4 http://deb.debian.org/debian bookworm/main arm64 gpgconf arm64 2.2.40-1.1 [557 kB]
Get:5 http://deb.debian.org/debian bookworm/main arm64 libksba8 arm64 1.6.3-2 [119 kB]
Get:6 http://deb.debian.org/debian bookworm/main arm64 libsasl2-modules-db arm64 2.1.28+dfsg-10 [20.8 kB]
Get:7 http://deb.debian.org/debian bookworm/main arm64 libsasl2-2 arm64 2.1.28+dfsg-10 [58.0 kB]
Get:8 http://deb.debian.org/debian bookworm/main arm64 libldap-2.5-0 arm64 2.5.13+dfsg-5 [171 kB]
Get:9 http://deb.debian.org/debian bookworm/main arm64 libnpth0 arm64 1.6-3 [18.6 kB]
Get:10 http://deb.debian.org/debian bookworm/main arm64 dirmngr arm64 2.2.40-1.1 [770 kB]
Get:11 http://deb.debian.org/debian bookworm/main arm64 gnupg-l10n all 2.2.40-1.1 [1093 kB]
Get:12 http://deb.debian.org/debian bookworm/main arm64 gnupg-utils arm64 2.2.40-1.1 [880 kB]
Get:13 http://deb.debian.org/debian bookworm/main arm64 libsqlite3-0 arm64 3.40.1-2 [786 kB]
Get:14 http://deb.debian.org/debian bookworm/main arm64 gpg arm64 2.2.40-1.1 [903 kB]
Get:15 http://deb.debian.org/debian bookworm/main arm64 libncursesw6 arm64 6.4-4 [122 kB]
Get:16 http://deb.debian.org/debian bookworm/main arm64 pinentry-curses arm64 1.2.1-1 [75.2 kB]
Get:17 http://deb.debian.org/debian bookworm/main arm64 gpg-agent arm64 2.2.40-1.1 [673 kB]
Get:18 http://deb.debian.org/debian bookworm/main arm64 gpg-wks-client arm64 2.2.40-1.1 [532 kB]
Get:19 http://deb.debian.org/debian bookworm/main arm64 gpg-wks-server arm64 2.2.40-1.1 [524 kB]
Get:20 http://deb.debian.org/debian bookworm/main arm64 gpgsm arm64 2.2.40-1.1 [651 kB]
Get:21 http://deb.debian.org/debian bookworm/main arm64 gnupg all 2.2.40-1.1 [846 kB]
Get:22 http://deb.debian.org/debian bookworm/main arm64 libgpm2 arm64 1.20.7-10+b1 [14.4 kB]
Get:23 http://deb.debian.org/debian bookworm/main arm64 libldap-common all 2.5.13+dfsg-5 [29.3 kB]
Get:24 http://deb.debian.org/debian bookworm/main arm64 libsasl2-modules arm64 2.1.28+dfsg-10 [63.1 kB]
Fetched 9175 kB in 0s (20.1 MB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package readline-common.
(Reading database ... 6684 files and directories currently installed.)
Preparing to unpack .../00-readline-common_8.2-1.3_all.deb ...
Unpacking readline-common (8.2-1.3) ...
Selecting previously unselected package libassuan0:arm64.
Preparing to unpack .../01-libassuan0_2.5.5-5_arm64.deb ...
Unpacking libassuan0:arm64 (2.5.5-5) ...
Selecting previously unselected package libreadline8:arm64.
Preparing to unpack .../02-libreadline8_8.2-1.3_arm64.deb ...
Unpacking libreadline8:arm64 (8.2-1.3) ...
Selecting previously unselected package gpgconf.
Preparing to unpack .../03-gpgconf_2.2.40-1.1_arm64.deb ...
Unpacking gpgconf (2.2.40-1.1) ...
Selecting previously unselected package libksba8:arm64.
Preparing to unpack .../04-libksba8_1.6.3-2_arm64.deb ...
Unpacking libksba8:arm64 (1.6.3-2) ...
Selecting previously unselected package libsasl2-modules-db:arm64.
Preparing to unpack .../05-libsasl2-modules-db_2.1.28+dfsg-10_arm64.deb ...
Unpacking libsasl2-modules-db:arm64 (2.1.28+dfsg-10) ...
Selecting previously unselected package libsasl2-2:arm64.
Preparing to unpack .../06-libsasl2-2_2.1.28+dfsg-10_arm64.deb ...
Unpacking libsasl2-2:arm64 (2.1.28+dfsg-10) ...
Selecting previously unselected package libldap-2.5-0:arm64.
Preparing to unpack .../07-libldap-2.5-0_2.5.13+dfsg-5_arm64.deb ...
Unpacking libldap-2.5-0:arm64 (2.5.13+dfsg-5) ...
Selecting previously unselected package libnpth0:arm64.
Preparing to unpack .../08-libnpth0_1.6-3_arm64.deb ...
Unpacking libnpth0:arm64 (1.6-3) ...
Selecting previously unselected package dirmngr.
Preparing to unpack .../09-dirmngr_2.2.40-1.1_arm64.deb ...
Unpacking dirmngr (2.2.40-1.1) ...
Selecting previously unselected package gnupg-l10n.
Preparing to unpack .../10-gnupg-l10n_2.2.40-1.1_all.deb ...
Unpacking gnupg-l10n (2.2.40-1.1) ...
Selecting previously unselected package gnupg-utils.
Preparing to unpack .../11-gnupg-utils_2.2.40-1.1_arm64.deb ...
Unpacking gnupg-utils (2.2.40-1.1) ...
Selecting previously unselected package libsqlite3-0:arm64.
Preparing to unpack .../12-libsqlite3-0_3.40.1-2_arm64.deb ...
Unpacking libsqlite3-0:arm64 (3.40.1-2) ...
Selecting previously unselected package gpg.
Preparing to unpack .../13-gpg_2.2.40-1.1_arm64.deb ...
Unpacking gpg (2.2.40-1.1) ...
Selecting previously unselected package libncursesw6:arm64.
Preparing to unpack .../14-libncursesw6_6.4-4_arm64.deb ...
Unpacking libncursesw6:arm64 (6.4-4) ...
Selecting previously unselected package pinentry-curses.
Preparing to unpack .../15-pinentry-curses_1.2.1-1_arm64.deb ...
Unpacking pinentry-curses (1.2.1-1) ...
Selecting previously unselected package gpg-agent.
Preparing to unpack .../16-gpg-agent_2.2.40-1.1_arm64.deb ...
Unpacking gpg-agent (2.2.40-1.1) ...
Selecting previously unselected package gpg-wks-client.
Preparing to unpack .../17-gpg-wks-client_2.2.40-1.1_arm64.deb ...
Unpacking gpg-wks-client (2.2.40-1.1) ...
Selecting previously unselected package gpg-wks-server.
Preparing to unpack .../18-gpg-wks-server_2.2.40-1.1_arm64.deb ...
Unpacking gpg-wks-server (2.2.40-1.1) ...
Selecting previously unselected package gpgsm.
Preparing to unpack .../19-gpgsm_2.2.40-1.1_arm64.deb ...
Unpacking gpgsm (2.2.40-1.1) ...
Selecting previously unselected package gnupg.
Preparing to unpack .../20-gnupg_2.2.40-1.1_all.deb ...
Unpacking gnupg (2.2.40-1.1) ...
Selecting previously unselected package libgpm2:arm64.
Preparing to unpack .../21-libgpm2_1.20.7-10+b1_arm64.deb ...
Unpacking libgpm2:arm64 (1.20.7-10+b1) ...
Selecting previously unselected package libldap-common.
Preparing to unpack .../22-libldap-common_2.5.13+dfsg-5_all.deb ...
Unpacking libldap-common (2.5.13+dfsg-5) ...
Selecting previously unselected package libsasl2-modules:arm64.
Preparing to unpack .../23-libsasl2-modules_2.1.28+dfsg-10_arm64.deb ...
Unpacking libsasl2-modules:arm64 (2.1.28+dfsg-10) ...
Setting up libksba8:arm64 (1.6.3-2) ...
Setting up libgpm2:arm64 (1.20.7-10+b1) ...
Setting up libsqlite3-0:arm64 (3.40.1-2) ...
Setting up libsasl2-modules:arm64 (2.1.28+dfsg-10) ...
Setting up libnpth0:arm64 (1.6-3) ...
Setting up libassuan0:arm64 (2.5.5-5) ...
Setting up libldap-common (2.5.13+dfsg-5) ...
Setting up libsasl2-modules-db:arm64 (2.1.28+dfsg-10) ...
Setting up gnupg-l10n (2.2.40-1.1) ...
Setting up libncursesw6:arm64 (6.4-4) ...
Setting up libsasl2-2:arm64 (2.1.28+dfsg-10) ...
Setting up readline-common (8.2-1.3) ...
Setting up pinentry-curses (1.2.1-1) ...
Setting up libreadline8:arm64 (8.2-1.3) ...
Setting up libldap-2.5-0:arm64 (2.5.13+dfsg-5) ...
Setting up gpgconf (2.2.40-1.1) ...
Setting up gpg (2.2.40-1.1) ...
Setting up gnupg-utils (2.2.40-1.1) ...
Setting up gpg-agent (2.2.40-1.1) ...
Setting up gpgsm (2.2.40-1.1) ...
Setting up dirmngr (2.2.40-1.1) ...
Setting up gpg-wks-server (2.2.40-1.1) ...
Setting up gpg-wks-client (2.2.40-1.1) ...
Setting up gnupg (2.2.40-1.1) ...
Processing triggers for libc-bin (2.36-9+deb12u7) ...
```


There we go. Now we need to add the actual package. First tell debian where to find it:

```Shell
echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
```

Note that if you're trying to do this on an Apple Silicon Mac, you will be running an ARM image by default and the next
step will most likely fail.

The next step is to update and install:

```Shell
apt-get update && apt-get install -y google-chrome-stable
Hit:1 http://deb.debian.org/debian bookworm InRelease
Hit:2 http://deb.debian.org/debian bookworm-updates InRelease
Get:3 https://dl.google.com/linux/chrome/deb stable InRelease [1825 B]
Hit:4 http://deb.debian.org/debian-security bookworm-security InRelease
Get:5 https://dl.google.com/linux/chrome/deb stable/main amd64 Packages [1084 B]
Fetched 2909 B in 2s (1451 B/s)
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
```

Perfect, now we can pack all that in a container image:

```Dockerfile
FROM debian:bookworm-slim
LABEL maintainer="Rick Rackow <rick+docker@rackow.io>"
RUN apt-get update -y && \
    apt-get install -y wget \
    gnupg

RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

```

We could clean up a little to keep the whole thing slimmer, but let's just try to make it work and then do the whole
clean up and everything.

You might make a case that chrome doesn't really need a privileged user, so we might add one and use that:

```Dockerfile
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome
USER chrome
```

Lastly, we want this to just run chrome, so we might as well add an entrypoint:

```Dockerfile
ENTRYPOINT [ "google-chrome" ]
```

The whole dockerfile that you can also find [on GitHub](https://github.com/RiRa12621/dockerimages/blob/main/chrome/Dockerfile):

```Dockerfile
FROM debian:bookworm-slim
LABEL maintainer="Rick Rackow <rick+docker@rackow.io>"
RUN apt-get update -y && \
    apt-get install -y wget \
    gnupg

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg

RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

RUN apt-get update && \
    apt-get install -y google-chrome-stable



RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome
USER chrome

ENTRYPOINT [ "google-chrome" ]

```

Let's see if we can build and run it:



```shell
$ docker build -t rira12621/chrome .
[+] Building 1.8s (8/9)                                                                                                                                                                                                                                                                                                                                                                                                docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 678B                                                                                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                                                                                                                                                                                                                                                                                                                                                0.5s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                                                                                        0.0s
 => [1/6] FROM docker.io/library/debian:bookworm-slim@sha256:67f3931ad8cb1967beec602d8c0506af1e37e8d73c2a0b38b181ec5d8560d395                                                                                                                                                                                                                                                                                                          0.0s
 => CACHED [2/6] RUN apt-get update -y &&     apt-get install -y wget     gnupg                                                                                                                                                                                                                                                                                                                                                        0.0s
 => [3/6] RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg                                                                                                                                                                                                                                                                                                       0.3s
 => [4/6] RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list                                                                                                                                                                                                                                                                                                                     0.1s
 => ERROR [5/6] RUN apt-get update &&     apt-get install -y google-chrome-stable                                                                                                                                                                                                                                                                                                                                                      0.8s
------
 > [5/6] RUN apt-get update &&     apt-get install -y google-chrome-stable:
0.190 Hit:1 http://deb.debian.org/debian bookworm InRelease
0.210 Hit:2 http://deb.debian.org/debian bookworm-updates InRelease
0.232 Hit:3 http://deb.debian.org/debian-security bookworm-security InRelease
0.242 Get:4 https://dl.google.com/linux/chrome/deb stable InRelease [1825 B]
0.293 Fetched 1825 B in 0s (10.4 kB/s)
0.293 Reading package lists...
0.528 Reading package lists...
0.758 Building dependency tree...
0.820 Reading state information...
0.823 E: Unable to locate package google-chrome-stable
------
Dockerfile:11
--------------------
  10 |
  11 | >>> RUN apt-get update && \
  12 | >>>     apt-get install -y google-chrome-stable
  13 |
--------------------
ERROR: failed to solve: process "/bin/sh -c apt-get update &&     apt-get install -y google-chrome-stable" did not complete successfully: exit code: 100
```

That's pretty much what I was meaning to say earlier, when I said "there might be an issue on Apple Silicon".
Let's build with setting the platform to `linux/amd64`:

```shell
$ docker build --platform linux/amd64 -t rira12621/chrome .
[+] Building 92.9s (10/10) FINISHED                                                                                                                                                                                                                                                                                                                                                                                    docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 678B                                                                                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                                                                                                                                                                                                                                                                                                                                                0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                                                                                        0.0s
 => CACHED [1/6] FROM docker.io/library/debian:bookworm-slim                                                                                                                                                                                                                                                                                                                                                                           0.0s
 => [2/6] RUN apt-get update -y &&     apt-get install -y wget     gnupg                                                                                                                                                                                                                                                                                                                                                              24.2s
 => [3/6] RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg                                                                                                                                                                                                                                                                                                       0.4s
 => [4/6] RUN echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list                                                                                                                                                                                                                                                                                                                     0.1s
 => [5/6] RUN apt-get update &&     apt-get install -y google-chrome-stable                                                                                                                                                                                                                                                                                                                                                           66.6s
 => [6/6] RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome     && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome                                                                                                                                                                                                                                                                           0.2s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                                                                                 1.4s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                                                                                1.4s
 => => writing image sha256:1884936cd4a9ec845b2c43e984ac41db09f67706b1da749578de84ac4b497f1d                                                                                                                                                                                                                                                                                                                                           0.0s
 => => naming to docker.io/rira12621/chrome
```

Looks a lot better.
The issue here is basically that there's no arm64 package available as stated [here](https://support.google.com/chrome/thread/266305698/where-is-chrome-download-file-aarch64-deb-amd64-for-linux?hl=en).
I am not sure how we'll work around this for building multiarch. Maybe we will have to just use chromium instead, which
does have packages [directly available](https://packages.debian.org/hu/sid/arm64/chromium/download).

The logical next step is to actually run the container:

```shell
$ docker run -ti --rm --platform linux/amd64 -t rira12621/chrome
[1:32:0613/151233.396271:ERROR:bus.cc(407)] Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
[1:1:0613/151233.398567:ERROR:ozone_platform_x11.cc(244)] Missing X server or $DISPLAY
[1:1:0613/151233.398577:ERROR:env.cc(258)] The platform failed to initialize.  Exiting.
```

I am not really surprised. Essentially we need to mount the x11 socket into the container to make the thing work.

"But you said, you were on a Mac", well yes, I am, but how about we take one step after the other maybe? Also, let's
face it: for now, most likely I would and will try to run everything in a container rather on a Linux box than on a
Mac. 

Cool, so let's grab our trusty but slightly ancient X1 Carbon and get to work there.

#### The Build

We want to build automatically and since we're currently going to be incapable of building for ARM anyway thanks to
Google's unwillingness of providing the packages, we'll just do a single arch build directly from Dockerhub.
You can get the same result on Quay or whatever registry you glued together with scripts. This is just a random pick of
mine for now. So we go to hub.docker.com and then click ourselves a new repository and then configure ourselves a build
like below. What matters here is that we sync to our GitHub repo, so we will rebuild on all new pushes and also that we
set the context correctly to `/chrome/` instead of the root of the repo, because, well, that's where our Dockerfile is.

![DockerHubBuildConfig](/imgs/all_things_container_1/dockerhub_repo_build_config.png)

And that's pretty much it. You as well can now get the image yourself and run it https://hub.docker.com/r/rira12621/chrome.
I do somehow need to fix the fact that the description is broken but whatever.

#### Running Chrome

I opted to put this section last and beyond the build step because until that point basically everything works. Now,
however we're hitting an issue that really doesn't seem to have a quickfix:

```shell
$ sudo docker run -ti --rm -v /tmp/.X11-unix:/tmp/.X11-unix --name chrome rira12621/chrome
Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted
[1:1:0613/213319.503949:FATAL:zygote_host_impl_linux.cc(201)] Check failed: . : Operation not permitted (1)
```

Obviously I first doubted myself and what I built there, so I ran Jess' image:

```shell

$ sudo docker run -ti --rm -v /tmp/.X11-unix:/tmp/.X11-unix --name chrome jess/chrome
Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted
```
I am somewhat not unhappy that it's not just my image, but on the other hand that's pretty bad and I'm honestly
way too tired to troubleshoot.

If you google what's happening, chances are that you'll actually land on [an open issue](https://github.com/jessfraz/dockerfiles/issues/350).
Please don't disable the sandbox. We'll dig deep and figure what's up next time.

btw, I tried the recommended fix of `echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/00-local-userns.conf` and
that didn't fix anything for me (yes, I did reload the unit). I also tried to get rid of apparmor just for the sake
of it.

Time to cheat: we look at Jess' run command and tadaaa, there's an actual [seccomp file](https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json).

Let's try:

```shell
$ sudo docker run -ti --rm -v /tmp/.X11-unix:/tmp/.X11-unix --name chrome --security-opt seccomp=$HOME/chrome.json rira12621/chrome
[13:13:0613/214456.989718:FATAL:spawn_subprocess.cc(237)] posix_spawn /opt/google/chrome/chrome_crashpad_handler: Operation not permitted (1)
```

Let's call it a day for now.

## Next

Next we'll dig into what's going on here (unless this is just a bug in the Chrome release, which I somewhat doubt) and
if we still have time, we'll package some more stuff. Maybe something a little easier.