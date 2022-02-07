---
title: "Openshift and Apple Silicon"
author: "Rick Rackow"
date: 2022-02-07T12:49:13+01:00
subtitle: "the pains of an M1 user"
image: ""
tags: ["Cloud","OpenShift","M1","Apple Silicon"]
---

After receiving my new M1 powered MacBooks Pro I was happy. Very happy. 
After all, it was quite the upgrade from the shabby Intel I5 powered MacBook
Pro that I was running while still working at Red Hat. Everything is so 
blazing fast now, and it just feels nice. While I was aware that not all CLI 
tools have yet been cross-compiled for ARM, I had a tiny "what the fuk" 
moment when I wanted to get the work on the "Operating OpenShift" book going 
and found out that basically none of the tooling was ready for Apple Silicon.
As you can imagine, not being able to use any of the CLI tooling isn't 
really great to write a book about OpenShift. In essence, I couldn't create 
clusters or use the `oc` CLI to interact with any clusters.

What to do? Build our own!

Luckily, almost all OpenShift tooling is written in Go which will make
cross-compiling rather easy.

## Installer

After leaving Red Hat I did not have access to automatically spun up 
clusters, so I needed to get going with installing my own clusters. 
Apparently, I must have been the first one to try this, since there are no 
ready-made packages available to run the installer on Apple Silicon.

![NoInstaller](/imgs/openshift_apple_silicon/no_installer_m1.png)

Time to get our hands dirty.

Almost all things in and around the OpenShift ecosystem are publicly 
available on GitHub and the installer is no exception. This allows us to 
clone the repository and start experiments right away.

```bash
$ git clone git@github.com:openshift/installer.git
Cloning into 'installer'...
remote: Enumerating objects: 168691, done.
remote: Total 168691 (delta 0), reused 0 (delta 0), pack-reused 168691
Receiving objects: 100% (168691/168691), 137.17 MiB | 9.45 MiB/s, done.
Resolving deltas: 100% (109974/109974), done.
Updating files: 100% (28328/28328), done.
```

So far, so good. The documentation is not super extensive but a good start. 
It tells us to [make sure we install the build dependencies](https://github.com/openshift/installer/blob/master/docs/dev/dependencies.md).
You can safely assume that the given command won't work on a Mac as it's 
making use of `yum` which isn't available on macOS. Let's take a look what 
we're supposed to install there:

```bash
sudo yum install golang-bin gcc-c++
```
A quick look at [the package](https://centos.pkgs.org/7/okey-x86_64/golang-bin-1.5.1-0.el7.centos.x86_64.rpm.html)
reveals that `golang-bin` is providing "Golang core compiler tools". We 
should have that covered with just a regular Go installation. 
> In case you don't have a working Go environment, now is a good time to get
> that going. Follow the [documentation](https://go.dev/doc/install) and you
> should be good to go.

The other package we're supposed to install is `gcc-c++` which, according to 
[the package](https://centos.pkgs.org/7/centos-x86_64/gcc-c++-4.8.5-44.el7.x86_64.rpm.html)
, "adds C++ support to the GNU Compiler Collection.
It includes support for most of the current C++ specification, including
templates and exception handling." Some googling would get you to the answer,
but to cut it short: installing `gcc` on macOS via homebrew also install the 
C++ compiler. All we have to do is `brew install gcc`.

Now that we are done with the pre-requisites, let's try to follow the 
[documentation](https://github.com/openshift/installer/blob/3f318d7049d5f4b6f98211b4b899fdb43b1f3542/README.md?plain=1#L29)
and run the build script.

```bash
$ ./hack/build.sh
+ minimum_go_version=1.17
++ go version
++ cut -d ' ' -f 3
+ current_go_version=go1.17.6
++ version 1.17.6
++ IFS=.
++ printf '%03d%03d%03d\n' 1 17 6
++ unset IFS
++ version 1.17
++ IFS=.
++ printf '%03d%03d%03d\n' 1 17
++ unset IFS
+ '[' 001017006 -lt 001017000 ']'
+ MODE=release
++ git rev-parse --verify 'HEAD^{commit}'
+ GIT_COMMIT=3f318d7049d5f4b6f98211b4b899fdb43b1f3542
++ git describe --always --abbrev=40 --dirty
+ GIT_TAG=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542
+ DEFAULT_ARCH=amd64
+ GOFLAGS=-mod=vendor
+ LDFLAGS=' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=amd64'
+ TAGS=
+ OUTPUT=bin/openshift-install
+ export CGO_ENABLED=0
+ CGO_ENABLED=0
+ case "${MODE}" in
+ LDFLAGS=' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=amd64 -s -w'
+ TAGS=' release'
+ test '' '!=' y
+ go generate ./data
writing assets_vfsdata.go
+ echo ' release'
+ grep -q libvirt
+ go build -mod=vendor -ldflags ' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=amd64 -s -w' -tags ' release' -o bin/openshift-install ./cmd/openshift-install
```
Works great, except that it hangs here, no further output, no problems 
mentioned.

If we look at the last line, that's basically the only thing that matters. 
The rest of the build script is trying to auto-detect certain values and 
minimum Go version and so on and then assembles the last line. So let's try 
to run the last line, but add a `-v` to make the `go build` command itself a 
little more verbose and not just get the bash trace.

That helped. We now get some actual information and that is, that as part of 
the build process all dependencies are downloaded. We could have figured 
that one our own by looking at the build flag: `mod=vendor`. Time to confirm 
our assumption by checking the [documentation](https://go.dev/ref/mod):
>-mod=vendor tells the go command to use the vendor directory. In this mode, 
the go command will not use the network or the module cache.

By the time, I read through all of that, the build command also actually 
finished, and we've built ourselves a nice working installer binary, 
hopefully. If everything worked, the binary should have landed in the `bin` 
directory, as we can tell from the build command: `-o bin/openshift-install`.

Let's check if we get what we expected:

```bash
$ ls bin/
openshift-install
$ ./bin/openshift-install version
./bin/openshift-install unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542
built from commit 3f318d7049d5f4b6f98211b4b899fdb43b1f3542
release image registry.ci.openshift.org/origin/release:4.10
release architecture amd64
```

YAY!

Wait...no. What is _that_ `release architecture amd64`? Apparently it seems 
like we build a nice binary, but for the wrong architecture. Definitely not 
what we wanted to achieve with this whole odyssey. Back to the drawing board,
or in this case, back to the build script. A close look at the script 
reveals, that it [uses a default arch](https://github.com/openshift/installer/blob/3f318d7049d5f4b6f98211b4b899fdb43b1f3542/hack/build.sh#L19),
which - who would have thought - is not arm64.

If we go ahead and set the value of that variable to `arm64` before running 
the script, we see that part of the build command at the end changes.

```bash
$ export DEFAULT_ARCH=arm64
$ ./hack/build.sh
+ minimum_go_version=1.17
++ go version
++ cut -d ' ' -f 3
+ current_go_version=go1.17.6
++ version 1.17.6
++ IFS=.
++ printf '%03d%03d%03d\n' 1 17 6
++ unset IFS
++ version 1.17
++ IFS=.
++ printf '%03d%03d%03d\n' 1 17
++ unset IFS
+ '[' 001017006 -lt 001017000 ']'
+ MODE=release
++ git rev-parse --verify 'HEAD^{commit}'
+ GIT_COMMIT=3f318d7049d5f4b6f98211b4b899fdb43b1f3542
++ git describe --always --abbrev=40 --dirty
+ GIT_TAG=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542
+ DEFAULT_ARCH=arm64
+ GOFLAGS=-mod=vendor
+ LDFLAGS=' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=arm64'
+ TAGS=
+ OUTPUT=bin/openshift-install
+ export CGO_ENABLED=0
+ CGO_ENABLED=0
+ case "${MODE}" in
+ LDFLAGS=' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=arm64 -s -w'
+ TAGS=' release'
+ test '' '!=' y
+ go generate ./data
writing assets_vfsdata.go
+ echo ' release'
+ grep -q libvirt
+ go build -mod=vendor -ldflags ' -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.Commit=3f318d7049d5f4b6f98211b4b899fdb43b1f3542 -X github.com/openshift/installer/pkg/version.defaultArch=arm64 -s -w' -tags ' release' -o bin/openshift-install ./cmd/openshift-install
```

Seems like it went better this time, and we actually have a proper result:

```bash
$ ./bin/openshift-install version
./bin/openshift-install unreleased-master-5596-g3f318d7049d5f4b6f98211b4b899fdb43b1f3542
built from commit 3f318d7049d5f4b6f98211b4b899fdb43b1f3542
release image registry.ci.openshift.org/origin/release:4.10
release architecture arm64
```

**HUGE SUCCESS!!!**

Building a cluster, is just following [the documentation](https://docs.openshift.com/container-platform/4.9/installing/index.html)
from here on, so I will not duplicate that into this blog. Our upcoming book 
however, will feature a section on installation on cluster size planning, so 
keep an eye out for that.


## OC

What would we do without the actual `oc` command line utility to interact 
with the cluster? Probably use `kubectl` and work around OpenShift specifics,
but that's not what I did and so it's not part of this blog. On the contrary,
we're set out to build a working binary.

Start off again by cloning the repository:

```bash
$ git clone git@github.com:openshift/oc.git
Cloning into 'oc'...
remote: Enumerating objects: 108422, done.
remote: Counting objects: 100% (7396/7396), done.
remote: Compressing objects: 100% (3646/3646), done.
remote: Total 108422 (delta 3424), reused 6966 (delta 3233), pack-reused 101026
Receiving objects: 100% (108422/108422), 97.51 MiB | 9.59 MiB/s, done.
Resolving deltas: 100% (50971/50971), done.
```

We're on the look-out for building instructions again and the [readme](https://github.com/openshift/oc/#building)
happily tells us to use a `make` command, so let's try that.

```bash
$ make oc
go build -mod=vendor -tags 'include_gcs include_oss containers_image_openpgp gssapi' -ldflags "-X github.com/openshift/oc/pkg/version.versionFromGit="v4.2.0-alpha.0-1370-g94f1156" -X github.com/openshift/oc/pkg/version.commitFromGit="94f115668" -X github.com/openshift/oc/pkg/version.gitTreeState="clean" -X github.com/openshift/oc/pkg/version.buildDate="2022-02-07T12:58:52Z" -X k8s.io/component-base/version.gitMajor="1" -X k8s.io/component-base/version.gitMinor="23" -X k8s.io/component-base/version.gitVersion="v0.23.0" -X k8s.io/component-base/version.gitCommit="94f115668" -X k8s.io/component-base/version.buildDate="2022-02-07T12:58:50Z" -X k8s.io/component-base/version.gitTreeState="clean" -X k8s.io/client-go/pkg/version.gitVersion="v4.2.0-alpha.0-1370-g94f1156" -X k8s.io/client-go/pkg/version.gitCommit="94f115668" -X k8s.io/client-go/pkg/version.buildDate="2022-02-07T12:58:50Z" -X k8s.io/client-go/pkg/version.gitTreeState="clean"" github.com/openshift/oc/cmd/oc
# github.com/apcera/gssapi
vendor/github.com/apcera/gssapi/name.go:213:9: could not determine kind of name for C.wrap_gss_canonicalize_name
cgo:
clang errors for preamble:
vendor/github.com/apcera/gssapi/name.go:90:2: error: unknown type name 'gss_const_name_t'
        gss_const_name_t input_name,
        ^
1 error generated.

make: *** [vendor/github.com/openshift/build-machinery-go/make/targets/golang/build.mk:16: build] Error 2
```

Admittedly, I am not surprised, but there is an [issue](https://github.com/openshift/oc/issues/415)
on the GitHub project telling us that installing `heimdal` is supposedly 
fixing our problem. Maybe, next time I should read further than the `make` 
command, since the [readme](https://github.com/openshift/oc/#building) lists 
it as a requirement with install instructions for macOS. My bad, clearly.

After installing `heimdal`, we're giving it another go. Same error as 
before. Back to the open issue and there is a [comment]() giving some useful 
information, that we need to
add `$ CGO_CFLAGS="-I/opt/homebrew/opt/heimdal/include"` to make our build work.

```bash
$ CGO_CFLAGS="-I/opt/homebrew/opt/heimdal/include" make oc

go build -mod=vendor -tags 'include_gcs include_oss containers_image_openpgp gssapi' -ldflags "-X github.com/openshift/oc/pkg/version.versionFromGit="v4.2.0-alpha.0-1370-g94f1156" -X github.com/openshift/oc/pkg/version.commitFromGit="94f115668" -X github.com/openshift/oc/pkg/version.gitTreeState="clean" -X github.com/openshift/oc/pkg/version.buildDate="2022-02-07T13:09:26Z" -X k8s.io/component-base/version.gitMajor="1" -X k8s.io/component-base/version.gitMinor="23" -X k8s.i
o/component-base/version.gitVersion="v0.23.0" -X k8s.io/component-base/version.gitCommit="94f115668" -X k8s.io/component-base/version.buildDate="2022-02-07T13:09:25Z" -X k8s.io/component-base/version.gitTreeState="clean" -X k8s.io/client-go/pkg/version.gitVersion="v4.2.0-alpha.0-1370-g94f1156" -X k8s.io/client-go/pkg/version.gitCommit="94f115668" -X k8s.io/client-go/pkg/version.buildDate="2022-02-07T13:09:25Z" -X k8s.io/client-go/pkg/version.gitTreeState="clean"" github.com
/openshift/oc/cmd/oc
$ ./oc version
```

YAY! We now have a working `oc` binary as well. If you want, you can add it 
to your path, so it's available more easily, than referencing the directory 
you built in.

## Local Clusters and Final Thoughts
This is basically just a sad story for M1 users: as per a [maintainer comment](https://github.com/code-ready/crc/issues/2047#issuecomment-827253324)
CodeReady Containers(CRC) are not available yet and with a bit of 
interpretation also won't be any time soon.

With Minishift considered deprecated and CRC not working on M1, Apple 
Silicon users are left out and have no really other option than to run an 
OpenShift cluster in the cloud or on metal. While for production use cases 
that makes total sense, I personally always appreciated having a local 
option to quickly develop and test against an OpenShift cluster. One could 
argue that nowadays cloud resources are easily available and once you 
compiled the installer yourself, you can have a cluster in no time. However, 
there's a pretty significant cost involved with that.

Apple Silicon users can only hope that at least single node clusters on arm 
are possible soon, so we can install a cluster on a Raspberry Pi and you can 
be sure to read about that here, as soon as it's possible.