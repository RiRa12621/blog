---
title: "CodeReady Containers & Apple Silicon"
author: "Rick Rackow"
date: 2022-02-07T16:35:50+01:00
subtitle: "No OpenShift for Apple Silicon users"
image: ""
tags: ["Cloud","OpenShift","M1","Apple Silicon","CRC","CodeReady Containers"]
---
>**Before you dive deep: This will not give you a working local 
> OpenShift on 
Apple Silicon but a working CRC using Podman.**

At the very end of my [last post](https://yelling.cloud/posts/openshift_apple_silicon/)
I briefly mentioned that CodeReady Containers(CRC) were not available for 
Apple Silicon. Literally two hours later I came across a
[GitHub Issue](https://github.com/code-ready/crc/issues/2480) that's 
functions as an epic ticket for CRC support on M1 and guess what? There's a 
new comment hinting to a [dev preview version](https://github.com/code-ready/crc/discussions/2988).
Naturally, I installed went and tried it and here's how it went.


## Installation
As of now we get to download the installer from [a Google storage blob](https://storage.googleapis.com/crc-bundle-github-ci/crc-macos-arm64.pkg)
which seems just about fine for a prototype if you don't want to leverage 
GitHub's built-in mechanism like marking something as a release candidate, 
which I understand is probably just not feasible here.

Once downloaded, we just click on the downloaded installer and...

![InstallerNotSigned](/imgs/crc_apple_silicon/notsigned.png)

Ok, common issue, no big deal. We just hold down the "option" key, click the 
file and then hit "open" from the dropdown and ... tada.

![overrideUnsigned](/imgs/crc_apple_silicon/override_unsigned.png)

Now we can move ahead and work our way through the installer. This process 
doesn't feel any different from other installers. That's a big compliment. 
It just feels natural for an apple user. The biggest noticeable difference is,
that we're seeing an Apache 2.0 License instead of the usual proprietary 
stuff. Simple, fast, great! After the installation is done, it even moves 
itself to the trash bin.

If you have spotlight search enabled, you can use that right after the 
installation to start CRC. Alternatively you maneuver to your apps directory 
and launch it. Yes, you can totally do it from the CLI, but let's be real: 
you just installed an app with a GUI installer that's a total prototype. 
Just use the GUI.

CRC starts with a little pop-up window that's taking you through an init 
config in a questionnaire style. What's actually annoying is, that I have a 
hard time finding this window again after I moved it to the background, 
because it doesn't show up as open app yet.

![crcInit](/imgs/crc_apple_silicon/crc_init_window.png)

There's a bit of a pitfall on the second question:

![crcInitPodmanOpenShift](/imgs/crc_apple_silicon/crc_init_podman_openshift.png)

You **must** select `Podman` here according the
[GitHub Issue](https://github.com/code-ready/crc/discussions/2988) as 
otherwise the whole thing won't work.

I guess it makes sense to have a working [Podman](https://podman.io/)
installation. This used to be a bit of a hassle, but not anymore. Let's run 
through this real quick:

You can get podman via homebrew with just a single command:

```bash
$ brew install podman
Running `brew update --preinstall`...
==> Auto-updated Homebrew!
Updated 2 taps (homebrew/core and homebrew/cask).
==> Updated Formulae
Updated 7 formulae.
==> Updated Casks
Updated 11 casks.
==> Caveats
==> podman
Bash completion has been installed to:
  /opt/homebrew/etc/bash_completion.d
```

Podman doesn't natively run on Macs, so we need a virtual machine. Until 
not so long ago we would have required to install vagrant or some other 
option and then link to it and what not. I'd rather not think about it, given
Vagrant and Apple Silicon are not best friend either. Now however, there 
is `podman machine`. This little command spins up a virtual machine for you 
to use with podman. Let's take a look:

```bash
$ podman machine init
Downloading VM image: fedora-coreos-35.20220131.2.0-qemu.aarch64.qcow2.xz: done
Extracting compressed file
$ podman machine start
INFO[0000] waiting for clients...
INFO[0000] listening tcp://127.0.0.1:7777
INFO[0000] new connection from  to /var/folders/b9/0wxdz0814kz2v9x2167d9kg40000gn/T/podman/qemu_podman-machine-default.sock
Waiting for VM ...
Machine "podman-machine-default" started successfully
```

Just like that we have a working podman installation and can move on with 
the CRC initialisation.

After we selected "podman" in the wizard, we click our way through. After 
the last step, we're getting a little window inside the wizard's window 
that's presenting us the logs of the CRC installation. Feels a bit weird 
from a UI perspective, but who am I to judge.

After the step has succeeded, the little "Start using CRC" button changes 
from grey to blue, signalling that it's ready to pressed.

![CRC_ready](/imgs/crc_apple_silicon/crc_ready.png)

Alternatively we can also get some guides to getting started or example 
deployments, but for one you're reading this blog, so we don't need the 
guides, and we just want to get started using our new shiny CRC cluster. 
Clicking the button to start using CRC, and we get the little prompt if we 
want to enable notifications. I have no idea what we will be getting 
notified for, but I'm allowing that, so you don't have to.

## Running a Cluster

At the top (or wherever you moved it), we can see the little tray icon now, 
telling us that CRC is running...maybe.

![tray](/imgs/crc_apple_silicon/crc_tray_ux.png)

The little UI problem has been [mentioned](https://github.com/code-ready/crc/discussions/2988#discussioncomment-2112740)
on GitHub before, so we can assume that will be fixed before an actual 
release happens. With the "Configuration" button, we can specify the 
resources allocated and the defaults seems just about fine for now: 2 CPUs, 
2 G Ram, 31 G disk. We can also define a proxy and opt out of sending 
telemetry data. We want a better working product over time, so we opt in. No,
this is not used for marketing or whatever, but mostly just to improve CRC 
and OpenShift as a whole. You can either believe me on this or research your 
way around a bit on GitHub to find out what's actually send as telemetry.

Clicking the little "Stopped" button brings up a window again with some 
information, but it doesn't seem like I can or should do anything.

![crc_window_debug](/imgs/crc_apple_silicon/crc_window_debug.png)

I think it's safe to close this window again. I'm trying to bring the other 
pop up menu up again. Some failed attempts later it's there. There doesn't 
seem to be a pattern that reliably makes it work. I tried quick click, 
double click, click and hold, and it's just pure luck if I get it or not. 
Ignoring that as it's reported already as well. Once we have brought the 
pop-up window to the foreground, we can hit the "start" button. We instantly get 
a notification, which seems rather annoying for something that we consciously 
just asked the system to do. Other than that, we get little feedback. The 
"start" button still is clickable, and you falsely get a notification that 
CRC is starting a cluster, if you click it again. Closing the little pop-up and 
clicking the tray icon again gives us some more options now.

![trayRunning](/imgs/crc_apple_silicon/tray_running)

The "open console" option actually gives us a GUI to allow us to deploy a 
container.

![gui](/imgs/crc_apple_silicon/crc_gui.png)

Let alone that we lose sight of this window as soon as it's in the 
background, because we still cannot get to it using `CMD + TAB`, we want to 
interact a little more with our cluster than just deploying a container,
so we hit "Open Developer Terminal" from the tray again and it ... does nothing.
At least nothing noticeable. That's somehow not what I expected, and I start 
to ask myself if I should have read the "getting started guide" after all.

Using `crc` on the command line is a good try. That's probably what that 
button would do anyway.

```bash
$ crc status
CRC VM:          Running
OpenShift:
Podman:          3.4.4
Disk Usage:      1.822GB of 32.74GB (Inside the CRC VM)
Cache Usage:     34.2GB
Cache Directory: /Users/rackow/.crc/cache
```

Well, that's good enough. Working `crc`  as expected also means that we can 
probably run all other commands, which in turn means, that we can make `oc` 
play nicely by following [CRC documentation](https://crc.dev/crc/#accessing-the-openshift-cluster-with-oc_gsg).

If you don't have a working `oc` on your Apple Silicon Mac yet, you can 
check out the [last post](https://yelling.cloud/posts/openshift_apple_silicon/)
where I explain how to get that working.

Anyway, let's try to run the command to get the environment working:

```bash
$ crc oc-env
Only supported with OpenShift bundles
```

Sounds logical, but somehow not what I expected, given the
[CRC Readme](https://github.com/code-ready/crc/blob/master/README.adoc) 
literally says: 
"Red Hat CodeReady Containers - OpenShift 4 on your Laptop". However, it 
does say exactly that during the initialisation process: "This option will 
allow you to use podman to run containers inside a VM environment." Probably 
only have myself to blame.

This is pretty much the end of the story. It's does add literally 0 extra 
value to run a container using CRC with podman over using docker or podman 
directly. Maybe I just don't get it. But wait! We have a little too much 
persistence in us, so let's just try to run the unsupported "OpenShift" option.
For that we just install what we currently have and the run the installer 
again. This time we choose "OpenShift" instead of podman.


We have to provide a pull secret. The helper is telling us that we could 
click the link, and then it will open a window where you need to log in to 
your Red Hat account. I don't know about you, but my password manager 
doesn't appreciate that. Instead, I just pull up the [page](https://console.redhat.com/openshift/create/local)
in my browser, log in and then download the pull secret. After that, we copy and
paste the whole thing. Continuing through the helper, the familiar console 
eventually shows up and the last log lines are not very promising:


```bash
level=info msg="Downloading crc_hyperkit_4.9.12.crcbundle"
Unknown preset: openshift
Starting daemon process ...
Pull secret stored in keyring
```

However, it still lets us click the "Start using CRC" button and afterward 
we can hit "start" from the tray. It's just, that nothing is happening 
thereafter. Checking the logs also doesn't look too promising:

```bash
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
listening /Users/rackow/.crc/tap.sock
listening /Users/rackow/.crc/crc-http.sock
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking for obsolete admin-helper executable
Checking if running on a supported CPU architecture
Checking minimum RAM requirements
Checking if vfkit is installed
Extracting bundle: crc_hyperkit_4.9.12...
```


Now we're actually really at the end of the story: No OpenShift for Apple 
Silicon users. 