---
title: "Apple Containers"
author: "Rick Rackow"
date: 2026-08-28T20:00:50+02:00
subtitle: "A real docker replacement?"
image: ""
tags: ["apple", "docker", "container", "apple containers"]
---

Apple Containers seems to be all the hype right now. (besides all things AI)
Against a common misconception, Docker is actually still free. Yes, you can pay 
the 5EUR but as a private user you are free to use Docker, including Docker 
Desktop. That being said, especially on a Mac, Docker still isn't natively
running, so you run Docker desktop, and then that under the hood basically
starts a small Linux VM and in there your actual containers run. So let's find
out if Apple Containers actually let you run things natively, if the performance
is better, how the usability is and so on.

Just so we're clear: this is a) written by me and just me, without some AI 
and b) not a code walk or a product pitch. I'm just trying it out and take 
you along on the way.

# Installation
Installation is fairly simple. You can just go to the Apple Container 
[repository](https://github.com/apple/container) and then get the installer 
from the [release page](https://github.com/apple/container/releases). The 
installer is available signed and unsigned. The signed variant lets you 
click through the installation process, and what I always like, asks you 
nicely if it should move itself to the bin once you're done.

If you want to get started right away, you'll find out that you still have 
to "start the system":

```shell
$ container ps
Error: Plugins are unavailable. Start the container system services and retry:

    container system start

Check to see that the plugin exists under:
  - /usr/local/libexec/container-plugins/ps
  - /usr/local/libexec/container/plugins/ps

Usage: container [--debug] <subcommand>
  See 'container --help' for more information.
```

Let's do that.

We are asked if we want to install the default kernel. What for? No one 
knows, but we will find out in a bit. Interestingly, the default is coming 
from Kata containers:
```shell
$ container system start
Launching container-apiserver...
Testing access to container-apiserver...
Verifying machine API server is running...
No default kernel configured.
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.28.0/kata-static-3.28.0-arm64.tar.zst]? [Y/n]: Y
Installing kernel...
```

# Usage

Now that we're ready, let's see if anything is running:

```shell

$ container ps
Error: Plugin 'container-ps' not found.

- If system services are not running, start them with: container system start
- If the plugin isn't installed, ensure it exists under:

Check to see that the plugin exists under:
  - /usr/local/libexec/container-plugins/ps
  - /usr/local/libexec/container/plugins/ps

Usage: container [--debug] <subcommand>
  See 'container --help' for more information.
$ container system start
Launching container-apiserver...
Testing access to container-apiserver...
Verifying machine API server is running...
```

Soooo no containers? But at least it's running. I think now we're going to 
the
[docs](https://github.com/apple/container/blob/main/docs/tutorials/start-here.md),
and basically it's just the wrong command. Let's try the correct one:

```shell
$ container list --all
ID  IMAGE  OS  ARCH  STATE  IP  CPUS  MEMORY  STARTED
```

Great, that works, but it's honestly already annoying. If something is a 
replacement for something else, I do somewhat expect it to behave the same way.
That is the case, for example, with [Podman](https://podman.io/), where you 
can literally just `alias docker=podman` and use podman (with some 
exceptions, but that's for a different blog).

Maybe I was just a bit unlucky here because the other basic commands seem 
to actually be the same:

```shell
  create                  Create a new container
  delete, rm              Delete one or more containers
  exec                    Run a new command in a running container
  inspect                 Display information about one or more containers
  kill                    Kill one or more running containers
  list, ls                List containers
  logs                    Fetch container stdio or boot logs
  run                     Run a container
  start                   Start a container
  stop                    Stop one or more running containers
```

# Performance and user experience

Now that we know how to use it, let's run some containers.

We can just start off with a simple Ubuntu container:

```shell
$ container run -ti --rm ubuntu /bin/bash
root@be5a98e3-fc95-47ba-b337-9fc436706845:/# whoami
root
```

That went smoothly. Let's actually try and do something useful. We will build a
simple go app that just responds to a get request and then stick that in a
container and respectively expose the port then, so we can reach the app from
outside the container.

First things first: the go app. Since this will not really run anywhere, we can
keep it simple and use net/http instead of bringing in gin and everything. We
will also keep everything in the main here: 

```golang
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello, World")
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

If you're not super familiar with go, that's no big deal. Let me explain:
In the main function we define a handler function and the respective URL
context. We define the handler function inline instead of moving it outside the
 main and basically say that we want to answer a request that we receive on `/`
with "Hello, World". Then we actually start the server and tell it to listen
on port 8080. That's wrapped in a logger, so that if there is any issue when
running the server, we log and exit with statuscode 1.

We can validate that it's doing what it's supposed to on the command line. In
one terminal panel we run the go app like so:

```shell
$ go run main.go 
```

Nothing more to do since we don't accept any input and just hardcoded the listen
port.

To verify that it's doing what it should, we can just curl like so:

```shell\
$ curl localhost:8080
Hello, World
```

So far so good. Now it just has to go in a container. For that we are going to
write ourselves a Dockerfile. Since it's very little extra effort, we'll use a 
nice multi-stage Dockerfile. That also allows us to verify right away that this
also works with Apple Containers.
In case you haven't used one yet, the idea is that you define two or more 
"stages" for your Dockerfile, where each of them is basically a complete
Dockerfile and you can use, for example, artifacts built in one stage in the next
one. 

Let's build our example and then review it:

```dockerfile
FROM golang AS builder

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 go build .

FROM scratch

WORKDIR /app

COPY --from=builder /app/pingServer .

ENTRYPOINT ["/app/pingServer"]

```

As you can see, we have two `FROM` statements. This is where each of our
definitions starts. The first one, we even "named" `builder`. That's nice, so we
can reference it in the second one. You think of these as resembling a stage.
In the first stage, we copy all files from the current directory to the image.
Normally you should be a bit more selective, but in this case I really only have
my `main.go` and its respective go modules file in the directory, so I can do
that. Then we build the go app and set `CGO_ENABLED=0`. Since this is not post
doesn't revolve around go, let's just say it's necessary to run self-contained.


In the second stage we use `scratch` as the base, so pretty much nothing, then 
we make a directory and switch to it. Next, we import the binary that we built
in the first stage and then set it as the entry point. 

Let's build it:

```shell
$ container build -t demo .
[+] Building 21.0s (11/11) FINISHED
 => [resolver] fetching image...docker.io/library/golang                                                                                                                                                                                                                                                                                                               0.0s
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 210B                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => oci-layout://docker.io/library/golang@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                                      5.4s
 => => resolve docker.io/library/golang@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                                        0.0s
 => => sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747 126B / 126B                                                                                                                                                                                                                                                                             0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B                                                                                                                                                                                                                                                                               0.0s
 => => sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15 64.18MB / 64.18MB                                                                                                                                                                                                                                                                       1.5s
 => => sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938 98.42MB / 98.42MB                                                                                                                                                                                                                                                                       1.7s
 => => sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1 67.60MB / 67.60MB                                                                                                                                                                                                                                                                       1.5s
 => => sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7 25.03MB / 25.03MB                                                                                                                                                                                                                                                                       0.6s
 => => sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563 49.67MB / 49.67MB                                                                                                                                                                                                                                                                       1.0s
 => => extracting sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563                                                                                                                                                                                                                                                                              0.6s
 => => extracting sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7                                                                                                                                                                                                                                                                              0.3s
 => => extracting sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1                                                                                                                                                                                                                                                                              0.8s
 => => extracting sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938                                                                                                                                                                                                                                                                              0.9s
 => => extracting sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15                                                                                                                                                                                                                                                                              1.1s
 => => extracting sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747                                                                                                                                                                                                                                                                              0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64/v8 stage-1 1/2] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.0s
 => [internal] load build context                                                                                                                                                                                                                                                                                                                                      0.1s
 => => transferring context: 7.94MB                                                                                                                                                                                                                                                                                                                                    0.1s
 => [linux/arm64/v8 builder 1/4] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.4s
 => [linux/arm64/v8 builder 2/4] COPY . .                                                                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64 builder 3/4] RUN CGO_ENABLED=0 go build .                                                                                                                                                                                                                                                                                                             6.2s
 => [linux/arm64/v8 stage-1 2/2] COPY --from=builder /app/pingServer .                                                                                                                                                                                                                                                                                                 0.0s
 => exporting to oci image format                                                                                                                                                                                                                                                                                                                                      0.2s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.1s
 => => exporting manifest sha256:be374cd295134e5fef9ac3664ba6a7e4682850883e7c54a3dd8e912f8e263935                                                                                                                                                                                                                                                                      0.0s
 => => exporting config sha256:44926a73bb40b245abd7854aa4307e057153d567561bf6aeae344d3622311230                                                                                                                                                                                                                                                                        0.0s
 => => exporting manifest list sha256:1c4a4bb60ec176b69350dfc75fd65d12851e5da8ce51f671870d79f3d59efd52                                                                                                                                                                                                                                                                 0.0s
 => => sending tarball                                                                                                                                                                                                                                                                                                                                                 0.0s
demo:latest
```

That went well. Let's run it. Keep in mind that we need to have port 8080
exposed so that we can receive requests:

```shell
$ container run -p 8080:8080 -ti --rm demo

```

Like in the normal go app, no output as expected, so let's try to curl it:

```shell
$ curl localhost:8080
Hello, World
```

Great! If we ignore our first issue with the `ps` subcommand things do feel
very smooth and also pretty much the same as when we were to use the regular
`docker` commands.

Now that we know that things work, the next question is how well they work.
If we time the above from clean, we get the following:

```shell
$ time container build -t demo .
[+] Building 21.0s (11/11) FINISHED
 => [resolver] fetching image...docker.io/library/golang                                                                                                                                                                                                                                                                                                               0.0s
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 210B                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => oci-layout://docker.io/library/golang@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                                      5.4s
 => => resolve docker.io/library/golang@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                                        0.0s
 => => sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747 126B / 126B                                                                                                                                                                                                                                                                             0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B                                                                                                                                                                                                                                                                               0.0s
 => => sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15 64.18MB / 64.18MB                                                                                                                                                                                                                                                                       1.5s
 => => sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938 98.42MB / 98.42MB                                                                                                                                                                                                                                                                       1.7s
 => => sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1 67.60MB / 67.60MB                                                                                                                                                                                                                                                                       1.5s
 => => sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7 25.03MB / 25.03MB                                                                                                                                                                                                                                                                       0.6s
 => => sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563 49.67MB / 49.67MB                                                                                                                                                                                                                                                                       1.0s
 => => extracting sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563                                                                                                                                                                                                                                                                              0.6s
 => => extracting sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7                                                                                                                                                                                                                                                                              0.3s
 => => extracting sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1                                                                                                                                                                                                                                                                              0.8s
 => => extracting sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938                                                                                                                                                                                                                                                                              0.9s
 => => extracting sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15                                                                                                                                                                                                                                                                              1.1s
 => => extracting sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747                                                                                                                                                                                                                                                                              0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64/v8 stage-1 1/2] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.0s
 => [internal] load build context                                                                                                                                                                                                                                                                                                                                      0.1s
 => => transferring context: 7.94MB                                                                                                                                                                                                                                                                                                                                    0.1s
 => [linux/arm64/v8 builder 1/4] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.4s
 => [linux/arm64/v8 builder 2/4] COPY . .                                                                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64 builder 3/4] RUN CGO_ENABLED=0 go build .                                                                                                                                                                                                                                                                                                             6.2s
 => [linux/arm64/v8 stage-1 2/2] COPY --from=builder /app/pingServer .                                                                                                                                                                                                                                                                                                 0.0s
 => exporting to oci image format                                                                                                                                                                                                                                                                                                                                      0.2s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.1s
 => => exporting manifest sha256:be374cd295134e5fef9ac3664ba6a7e4682850883e7c54a3dd8e912f8e263935                                                                                                                                                                                                                                                                      0.0s
 => => exporting config sha256:44926a73bb40b245abd7854aa4307e057153d567561bf6aeae344d3622311230                                                                                                                                                                                                                                                                        0.0s
 => => exporting manifest list sha256:1c4a4bb60ec176b69350dfc75fd65d12851e5da8ce51f671870d79f3d59efd52                                                                                                                                                                                                                                                                 0.0s
 => => sending tarball                                                                                                                                                                                                                                                                                                                                                 0.0s
demo:latest

real    0m37.588s
user    0m4.192s
sys     0m3.058s
```

For comparison, the same build command with docker (after `system prune -a`) 
on the same machine:

```shell
$ time docker build -t docker .
[+] Building 13.5s (11/11) FINISHED                                                                                                                                                                                                                                                                                                                    docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 213B                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/golang:latest                                                                                                                                                                                                                                                                                                       1.3s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => [builder 1/4] FROM docker.io/library/golang:latest@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                         8.8s
 => => resolve docker.io/library/golang:latest@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec                                                                                                                                                                                                                                                 0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B                                                                                                                                                                                                                                                                               0.1s
 => => sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747 126B / 126B                                                                                                                                                                                                                                                                             0.2s
 => => sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15 64.18MB / 64.18MB                                                                                                                                                                                                                                                                       2.6s
 => => sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1 67.60MB / 67.60MB                                                                                                                                                                                                                                                                       6.1s
 => => sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938 98.42MB / 98.42MB                                                                                                                                                                                                                                                                       6.4s
 => => sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7 25.03MB / 25.03MB                                                                                                                                                                                                                                                                       2.1s
 => => sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563 49.67MB / 49.67MB                                                                                                                                                                                                                                                                       2.1s
 => => extracting sha256:6b89e501e8efce0d3d87e3f6b0f85c417e799a3b36b8f44419609ba7fecf9563                                                                                                                                                                                                                                                                              0.5s
 => => extracting sha256:3198b4d4653b3225aa62931a3b1ff61435a6c99e83b6f2581bd52915332f78b7                                                                                                                                                                                                                                                                              0.2s
 => => extracting sha256:8f4f1d683f65087c4403277cc2e5a3d787025eb59d342271a327b23718904ab1                                                                                                                                                                                                                                                                              0.6s
 => => extracting sha256:dc98e650d0c56d3599a822f7359b264ff24cc3913019a68dc82e051c3dcbe938                                                                                                                                                                                                                                                                              0.8s
 => => extracting sha256:9e4d5c89bdd324edeb5721c09064e2659473bba39ae9d84fae53c9cc0181cf15                                                                                                                                                                                                                                                                              1.2s
 => => extracting sha256:670d42cf8b4364eac939465668b17e1a15c633e59b9bb4e088b31c3ca6c23747                                                                                                                                                                                                                                                                              0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                                                                                                                                                                              0.0s
 => [stage-1 1/2] WORKDIR /app                                                                                                                                                                                                                                                                                                                                         0.0s
 => [internal] load build context                                                                                                                                                                                                                                                                                                                                      0.1s
 => => transferring context: 7.94MB                                                                                                                                                                                                                                                                                                                                    0.1s
 => [builder 2/4] WORKDIR /app                                                                                                                                                                                                                                                                                                                                         0.1s
 => [builder 3/4] COPY . .                                                                                                                                                                                                                                                                                                                                             0.0s
 => [builder 4/4] RUN CGO_ENABLED=0 go build .                                                                                                                                                                                                                                                                                                                         2.9s
 => [stage-1 2/2] COPY --from=builder /app/pingServer .                                                                                                                                                                                                                                                                                                                0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                 0.2s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.2s
 => => exporting manifest sha256:eb62207c6dd2610838e3816237c25a6ca0cba530c24fc1c38889464ce568277b                                                                                                                                                                                                                                                                      0.0s
 => => exporting config sha256:291ba548eecc8b8aae58e5f8873d347ba842dd4d5411288cd37dacbc5c2594ac                                                                                                                                                                                                                                                                        0.0s
 => => exporting attestation manifest sha256:9b484a1c2329cdf2153cb01dcfc77b0889d5c13a06d208aac496ad6b67495cb0                                                                                                                                                                                                                                                          0.0s
 => => exporting manifest list sha256:d6f61272e83ec867e5b895e0d175f5a6e676c77d8d18e2c85412bc80028771a9                                                                                                                                                                                                                                                                 0.0s
 => => naming to docker.io/library/docker:latest                                                                                                                                                                                                                                                                                                                       0.0s
 => => unpacking to docker.io/library/docker:latest                                                                                                                                                                                                                                                                                                                    0.0s

real    0m13.630s
user    0m0.167s
sys     0m0.169s

```

That is 1/3 the time. The performance comparison seems pretty clear.

# Under the Hood

When looking at the results in the last section, I had some concerns. It seemed
very weird that a native container engine should have severely worse performance
than something that needs an additional Linux VM. To understand that, we need
to look into the action implementation of Apple Containers.

Like we saw, when we initialized our system the first time for Container usage,
we had to download some kernel. What's that for? 
Turns out that we do actually run a "light-weight" VM for every container as
stated in the [docs](https://github.com/apple/container/blob/main/docs/technical-overview.md#how-does-container-run-my-container).
Now the question for us is 
if the situation is the same actually at build time, because that's when we
already saw the performance impact. The simple answer is "yes". The more
differentiated answer, however, is that the approach for build time and run time
is slightly different. Apple Containers does not use _a_ VM but multiple. 
Essentially, every container you run runs in its own lightweight VM, as
opposed to the Docker approach, where basically all Containers run in the 
same VM. Now, the exception to the rule is, that for building images, there 
is just a single builder container. That obviously runs in its own VM again. The
whole thing comes up fresh on the first time, which would explain why we are 
seeing those build times being so slow. It's not explicitly stated in the
[docs](https://github.com/apple/container/blob/main/docs/resource-usage.md?utm_source=chatgpt.com#configure-memory-and-cpus-for-large-builds),
but assuming a fresh VM with a fresh container in it has to be provisioned first
and then also doesn't have a build cache, that does make sense. Let's take 
it for another spin. We clean up the existing builder first:

```shell
$ container builder delete --foorce
Error: Unknown option '--foorce'. Did you mean '--force'?
Usage: container builder delete [--force] [--debug]
  See 'container builder delete --help' for more information.
```

With `--force` it just does it, so no output to show here.

Next, we start the builder explicitly **before** we run our build command, 
assuming that we start a fresh container and a fresh VM that also has no 
build cache or anything, so a situation similar situation to Docker after we 
ran the `system prune` command: 

```shell
$ container builder start
```

Yet again there is no output, but I guess that just means that all is fine.

Now let's run the build:

```shell
$ time container build -t demo .
[+] Building 20.9s (11/11) FINISHED
 => [resolver] fetching image...docker.io/library/golang                                                                                                                                                                                                                                                                                                               0.0s
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 210B                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => oci-layout://docker.io/library/golang@sha256:0ecdc2a9f6156af6451080bfe3d8382a662fcc4e209608c6f919e643453514c1                                                                                                                                                                                                                                                      5.4s
 => => resolve docker.io/library/golang@sha256:0ecdc2a9f6156af6451080bfe3d8382a662fcc4e209608c6f919e643453514c1                                                                                                                                                                                                                                                        0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B                                                                                                                                                                                                                                                                               0.0s
 => => sha256:3248ea96287c1c219864b234f06742e9bb4a50f6e1a1dc3b7d79b3eb379dd968 126B / 126B                                                                                                                                                                                                                                                                             0.0s
 => => sha256:7c7d71ede3d0f0c6bd07ffa6581b7c523b2a236cd9c9a0151e44c9cfe43011ab 67.63MB / 67.63MB                                                                                                                                                                                                                                                                       1.6s
 => => sha256:02ae4aa9377d26806ae3cd8b394304961f5e283aaf748a9bada644611d444ed6 98.47MB / 98.47MB                                                                                                                                                                                                                                                                       1.8s
 => => sha256:42fd700369b465b3f57ff668eea94fc0b0e67029df25a71600d2c522a452406d 67.60MB / 67.60MB                                                                                                                                                                                                                                                                       1.6s
 => => sha256:7fa3c72c6402ef534e043b1dca6fc0ab99e044c333c7679d2508eac3817a8570 25.03MB / 25.03MB                                                                                                                                                                                                                                                                       0.6s
 => => sha256:7f50a08a25277c02b8dfc99818a21e12083215981e0aa03cb07cb74c9116f205 49.70MB / 49.70MB                                                                                                                                                                                                                                                                       1.0s
 => => extracting sha256:7f50a08a25277c02b8dfc99818a21e12083215981e0aa03cb07cb74c9116f205                                                                                                                                                                                                                                                                              0.6s
 => => extracting sha256:7fa3c72c6402ef534e043b1dca6fc0ab99e044c333c7679d2508eac3817a8570                                                                                                                                                                                                                                                                              0.3s
 => => extracting sha256:42fd700369b465b3f57ff668eea94fc0b0e67029df25a71600d2c522a452406d                                                                                                                                                                                                                                                                              0.7s
 => => extracting sha256:02ae4aa9377d26806ae3cd8b394304961f5e283aaf748a9bada644611d444ed6                                                                                                                                                                                                                                                                              0.9s
 => => extracting sha256:7c7d71ede3d0f0c6bd07ffa6581b7c523b2a236cd9c9a0151e44c9cfe43011ab                                                                                                                                                                                                                                                                              1.2s
 => => extracting sha256:3248ea96287c1c219864b234f06742e9bb4a50f6e1a1dc3b7d79b3eb379dd968                                                                                                                                                                                                                                                                              0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64/v8 stage-1 1/2] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.0s
 => [internal] load build context                                                                                                                                                                                                                                                                                                                                      0.1s
 => => transferring context: 7.94MB                                                                                                                                                                                                                                                                                                                                    0.1s
 => [linux/arm64/v8 builder 1/4] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.3s
 => [linux/arm64/v8 builder 2/4] COPY . .                                                                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64 builder 3/4] RUN CGO_ENABLED=0 go build .                                                                                                                                                                                                                                                                                                             6.0s
 => [linux/arm64/v8 stage-1 2/2] COPY --from=builder /app/pingServer .                                                                                                                                                                                                                                                                                                 0.0s
 => exporting to oci image format                                                                                                                                                                                                                                                                                                                                      0.2s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.1s
 => => exporting manifest sha256:00f39c80abf195cdf5883fe5c4c195e6a61e39a68b3bf698d81e8dedb49a9459                                                                                                                                                                                                                                                                      0.0s
 => => exporting config sha256:dbd1697c89acd85c15e75963725b110b287a42a61f59385fb9cdcb6fe6e03387                                                                                                                                                                                                                                                                        0.0s
 => => exporting manifest list sha256:f9f5485ac0b0078e9fa9cfa3b830685de446f60d087bb2cf1a2ff86484bf9de0                                                                                                                                                                                                                                                                 0.0s
 => => sending tarball                                                                                                                                                                                                                                                                                                                                                 0.0s
demo:latest

real    0m21.361s
user    0m2.713s
sys     0m2.236s
```

That does already look significantly better than before. The reaming 
difference can actually be well caused by the fact that I allocated 8 CPUS 
and 8 Gig of memory to Docker, whereas the Apple Containers builder just 
comes up with 2 CPUs and 2GB memory by default. We can change that before 
startup like so:


```shell
$ container builder start --cpus 8 --memory 8g
```

Let's test again:

```shell
$ time container build -t demo .
[+] Building 18.0s (11/11) FINISHED
 => [resolver] fetching image...docker.io/library/golang                                                                                                                                                                                                                                                                                                               0.0s
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 210B                                                                                                                                                                                                                                                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => oci-layout://docker.io/library/golang@sha256:0ecdc2a9f6156af6451080bfe3d8382a662fcc4e209608c6f919e643453514c1                                                                                                                                                                                                                                                      5.3s
 => => resolve docker.io/library/golang@sha256:0ecdc2a9f6156af6451080bfe3d8382a662fcc4e209608c6f919e643453514c1                                                                                                                                                                                                                                                        0.0s
 => => sha256:3248ea96287c1c219864b234f06742e9bb4a50f6e1a1dc3b7d79b3eb379dd968 126B / 126B                                                                                                                                                                                                                                                                             0.0s
 => => sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 32B / 32B                                                                                                                                                                                                                                                                               0.0s
 => => sha256:7c7d71ede3d0f0c6bd07ffa6581b7c523b2a236cd9c9a0151e44c9cfe43011ab 67.63MB / 67.63MB                                                                                                                                                                                                                                                                       1.7s
 => => sha256:02ae4aa9377d26806ae3cd8b394304961f5e283aaf748a9bada644611d444ed6 98.47MB / 98.47MB                                                                                                                                                                                                                                                                       1.9s
 => => sha256:42fd700369b465b3f57ff668eea94fc0b0e67029df25a71600d2c522a452406d 67.60MB / 67.60MB                                                                                                                                                                                                                                                                       1.7s
 => => sha256:7fa3c72c6402ef534e043b1dca6fc0ab99e044c333c7679d2508eac3817a8570 25.03MB / 25.03MB                                                                                                                                                                                                                                                                       0.6s
 => => sha256:7f50a08a25277c02b8dfc99818a21e12083215981e0aa03cb07cb74c9116f205 49.70MB / 49.70MB                                                                                                                                                                                                                                                                       1.1s
 => => extracting sha256:7f50a08a25277c02b8dfc99818a21e12083215981e0aa03cb07cb74c9116f205                                                                                                                                                                                                                                                                              0.6s
 => => extracting sha256:7fa3c72c6402ef534e043b1dca6fc0ab99e044c333c7679d2508eac3817a8570                                                                                                                                                                                                                                                                              0.2s
 => => extracting sha256:42fd700369b465b3f57ff668eea94fc0b0e67029df25a71600d2c522a452406d                                                                                                                                                                                                                                                                              0.7s
 => => extracting sha256:02ae4aa9377d26806ae3cd8b394304961f5e283aaf748a9bada644611d444ed6                                                                                                                                                                                                                                                                              0.9s
 => => extracting sha256:7c7d71ede3d0f0c6bd07ffa6581b7c523b2a236cd9c9a0151e44c9cfe43011ab                                                                                                                                                                                                                                                                              1.2s
 => => extracting sha256:3248ea96287c1c219864b234f06742e9bb4a50f6e1a1dc3b7d79b3eb379dd968                                                                                                                                                                                                                                                                              0.0s
 => => extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64/v8 stage-1 1/2] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.0s
 => [internal] load build context                                                                                                                                                                                                                                                                                                                                      0.1s
 => => transferring context: 7.94MB                                                                                                                                                                                                                                                                                                                                    0.1s
 => [linux/arm64/v8 builder 1/4] WORKDIR /app                                                                                                                                                                                                                                                                                                                          0.7s
 => [linux/arm64/v8 builder 2/4] COPY . .                                                                                                                                                                                                                                                                                                                              0.0s
 => [linux/arm64 builder 3/4] RUN CGO_ENABLED=0 go build .                                                                                                                                                                                                                                                                                                             3.0s
 => [linux/arm64/v8 stage-1 2/2] COPY --from=builder /app/pingServer .                                                                                                                                                                                                                                                                                                 0.0s
 => exporting to oci image format                                                                                                                                                                                                                                                                                                                                      0.2s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.2s
 => => exporting manifest sha256:640cb4b8482aae3e3e0bd4ec9f62a188ca4e60ba25a5da8e8014b91706895fd8                                                                                                                                                                                                                                                                      0.0s
 => => exporting config sha256:6222ed8eae20692747b51d7887569d09a50d3fcaf8e6f2e8d2a1bbce50f061de                                                                                                                                                                                                                                                                        0.0s
 => => exporting manifest list sha256:37e81f169edcfde3646b7f0a1853247b94b469a730ea30b74a473fdd889aa9ce                                                                                                                                                                                                                                                                 0.0s
 => => sending tarball                                                                                                                                                                                                                                                                                                                                                 0.0s
demo:latest

real    0m18.793s
user    0m2.603s
sys     0m2.198s
```

Good enough for me to call it even. The biggest chunk of time went into 
downloading the base images, and we are not doing quality measurements for 
that, since this is running on a laptop on my home internet connection via 
Wi-Fi. So there's no guarantee the conditions where exactly the same.


# Conclusion
Can you use Apple Containers? Yes.

Can you use them as a replacement for Docker? To an extent. You can run 
containers, and you can build them, which probably covers a lot of "normal" 
use cases. Additionally, the community seems to adopt it well, given also 
the comments under the [minikube issue](https://github.com/kubernetes/minikube/issues/20933)
requestin support for Apple containers. If people are curious about that, 
let me know, and maybe there will be another blog looking deeper into that.