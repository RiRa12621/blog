---
title: "Building a fine app"
author: "Rick Rackow"
date: 2024-05-23T19:00:50+01:00
subtitle: "Getting started with Fyne"
image: ""
tags: ["golang", "Fyne"]
---

The hard truth is that I am lazy. Very lazy. Sometimes that's good and
sometimes it's rather not. In this case it's rather not. I want to be able to
build mobile apps. Why is that? Well, sometimes I have some brain fart ideas and
want to be able to prototype them quickly. Now the issue is, that the js package
ecosystem is such a mess that I hate to touch it and therefore React Native is
not really something I am keen on using. So what else can we use that's nicely
building cross-platform? Flutter. The issue with the laziness is now that I
would really need to learn dart and I couldn't convince myself so far beyond
being able to read it and write some basic stuff.

How can I stay lazy and actually make mobile apps? Why isn't there something
in go. I mean I know go already and I could write app and backend in the same
language. How great would that be?! Apparently there is something out there,
that promises to make this work: [Fyne](https://fyne.io/) and I will try this
out. 

This blog may be a little unstructured because I'll write this while I'm
experimenting with Fyne.

## Getting Started

If you've been reading this blog a for a bit, you know that my favorite IDE is
Goland. Yes it's paid, but it's also a big value add for me so that's fine.
Let's get started with a new empty project, nothing really special to see here.

We create a new `main.go` and a go mod file and then look at the
[hello world example](https://docs.fyne.io/started/hello) that's provided on the
fyne docs. 

This example looks something like this:

```golang
package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/widget"
)

func main() {
	a := app.New()
	w := a.NewWindow("Hello World")

	w.SetContent(widget.NewLabel("Hello World!"))
	w.ShowAndRun()
}
```

Great stuff, let's build it and run it (you can use `go run main.go` as well).

![GolandBuildConfig](/imgs/building_a_fine_app/goland_build_config.png)


Now, if we decide to actually run this, we will get a nice window:

![HelloWorldBuild](/imgs/building_a_fine_app/hello_world_window.png)


That was really very, very convenient. Next up, since I'm on a Mac, how about
we try to build the same thing as iOS app. You need to get the Fyne Cli just
like [documented](https://docs.fyne.io/started/) using `go install fyne.io/fyne/v2/cmd/fyne@latest`.
Next up, we use that CLI to create our iOS app like so:

```shell
$ fyne package -os iossimulator -appID com.example.myapp
Missing application icon at "/Users/a1dbe91/GolandProjects/fyniere/Icon.png"

```

If you looked at the [docs](https://docs.fyne.io/started/mobile) you'll see that
I tried to be lazy (again) and not add an Icon, but apparently Fyne doesn't like
that a lot, so we need to add just some random icon. There's a generator that I
used to get a dummy icon: https://jpmallow.github.io/CopiCon/#/dashboard. Not
pretty, but we don't care about that for now. Add the whole shebang to the
`images` directory and then edit our build command to add the icon and run it
again:

```shell
$ fyne package -os iossimulator -appID com.example.myapp -icon resources/_gen/images/ios_store_icon.png
failed to look up certificate : exit status 44

```

Mhkay. A tiny bit of googling later, I found an old issue and got a superfast
response from the maintainers: https://github.com/fyne-io/fyne/issues/4460#issuecomment-2117371642.
I really didn't know what "fully set up" means in this context, so I this is a bit
of trial and error. Long story: you need to actually start up xcode, go to
settings add your appleID and then manage certificates and if you click the little
plus, you can add a developer certificate like so:

![AppleDeveloperCert](/imgs/building_a_fine_app/apple_developer_cert.png)


Now we can run the build again and succeed (or at least not get an error). I am
in fact a little confused, because what exactly did I just build and where is
it? We can probably get to it later. Let's focus on making our app run for now.
To do that, we run `xcrun simctl install booted myapp.app` like so:


```shell
$ fyne package -os iossimulator -appID com.example.myapp -icon resources/_gen/images/ios_store_icon.png && xcrun simctl install booted myapp.app
No devices are booted.

```

Okay, that makes sense, we need to actually have a running simulator device. We
just open the `Simulator` app and start an iPhone 15 from there. Now we can try
again.

```shell
$ fyne package -os iossimulator -appID com.example.myapp -icon resources/_gen/images/ios_store_icon.png && xcrun simctl install booted myapp.app
An error was encountered processing the command (domain=NSPOSIXErrorDomain, code=2):
Simulator device failed to install the application.
An application bundle was not found at the provided path.
Provide a valid path to the desired application bundle.
Underlying error (domain=NSPOSIXErrorDomain, code=2):
        Failed to install the requested application
        An application bundle was not found at the provided path.

```

Well, that's kinda not working and that is just maybe, because I didn't adjust
the name of the app. In my case that's `fyniere` so I need to adjust the command
accordingly to `xcrun simctl install booted fyniere.app` and running that again
will at least not error and actually the app is now on the simulator device:

![IosFyniereSimulator](/imgs/building_a_fine_app/fyniere_iossimulator.png)

The sad part is, that it instantly crashes when I try to click and open it in
the sim so how are we going to debug this? Well apparently, we can't really, or
at least I can't and this conducts the end of the journey for now:
https://github.com/fyne-io/fyne/issues/4828#issuecomment-2128069746

I'll follow up when I can. 
