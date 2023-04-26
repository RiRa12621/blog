---
title: "Minikube and the image architecture"
author: "Rick Rackow"
date: 2023-04-25T16:35:50+01:00
subtitle: "From stack overflow into a rabbit hole"
image: ""
tags: ["Cloud","Docker","M1","Apple Silicon","minikube", "Stack Overflow"]
---

Recently I've been trying to answer some more questions on stack overflow. 
For one to be a better member of the community but on the other hand also 
because I've been somewhat interested in joining the [Docker Captain's program](https://www.docker.com/community/captains/) and there are some requirements around activity, but that's a story for a different day. Anyhow, after a lot of more or less simple questions, I landed at a super cool one.
The title wasn't instantly giving away how deep of a rabbit hole I was about to explore: ["Minikube to deploy linux/amd64 images on M1 hardware"](https://stackoverflow.com/questions/72325482/minikube-to-deploy-linux-amd64-images-on-m1-hardware).

## The problem

The question of the post is how you can run images built for a different architecture in minikube on an M1 Mac.

The idea is clearly that docker desktop generally allows you to do that if there is an image with multiple architectures
available, by using the flag `--platform` with a value like `linux/amd64`. So why would that not work on minikube?

## What are multi-arch builds

Before we move ahead, I want to set a common ground, and so we need to clarify what a "multi-arch" image actually is.

tl;dr it is what the name says: an image that can run on multiple architecture. 

Doesn't sound so complicated but in the not so long ago times this was not possible. You had to build an image per architecture and so you'd end up with a bunch of different images built on different boxes for each respective architecture that essentially all did the same thing. Obviously not very practical as such but that way also required more effort on the build side as you would either have to have multiple pipelines with different architectures or some other way of doing things by hand. Nowadays, you can build the same image for multiple architectures from the same machine and upload it to a registry like dockerhub.

How does this work? Great question!

Every docker image is technically represented by a manifest and the information is added there, but let's look at an example to understand the issue a bit better. 

First we create ourselves and empty directory to work in and a simple as can be Dockerfile that we will build from.

Now we need to create the Dockerfile:

```dockerfile
FROM alpine

CMD ["./echo", "\"hello\""]
```

As mentioned, we want to keep it simple, so we really only take a small base image. This whole thing could be even smaller using `FROM scratch` instead of an alpine image but that comes with a chunk of caveats that would go over the limits of this post. If the whole story of smaller images and multi-stage images is interesting to you, let me know, and I'll cover it in another post.

Next up we build it "the traditional way" by just running the `docker build` command;

```shell
$ docker build -t quay.io/rira12621/not-multiarch:latest .
[+] Building 0.1s (3/3) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 36B                                                                                                                                                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                 0.0s
 => => writing image sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f                                                                                                                                                                                                                                                                           0.0s
 => => naming to quay.io/rira12621/not-multiarch:latest
```

Great stuff, we have built an image. This was built on my M1 Mac, so what happens if I try to run this somewhere else, let's say a regular non-arm Linux box? Let's find out. To do that, I push the image to the registry and then try to run it on the other box.

On the Mac:

```shell
$ docker push quay.io/rira12621/not-multiarch:latest
The push refers to repository [quay.io/rira12621/not-multiarch]
latest: digest: sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6 size: 313
```

Perfect, now on the Linux box we need to pull it. That box is a Dell R430 running CentOS streams 8 in my basement so nothing special:

```shell
rrackow@clouder:~ $ uname -a
Linux clouder 4.18.0-485.el8.x86_64 #1 SMP Fri Apr 7 20:13:02 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
rrackow@clouder:~ $ cat /etc/redhat-release
CentOS Stream release 8
```

Now on the Linux box, we pull and run the image:

```shell
rrackow@clouder:~ $ docker pull quay.io/rira12621/not-multiarch
Using default tag: latest
latest: Pulling from rira12621/not-multiarch
Digest: sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6
Status: Downloaded newer image for quay.io/rira12621/not-multiarch:latest
quay.io/rira12621/not-multiarch:latest
$ docker run -ti --rm quay.io/rira12621/not-multiarch
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64/v3) and no specific platform was requested
docker: Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown.
```

As you can see that's not going so well, but why? Back to my main machine, we can analyze our built image:

```shell
$ docker inspect quay.io/rira12621/not-multiarch:latest
[                                                                                                                                                                                                                                                                                                                                                                   [0/1915]
    {
        "Id": "sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f",
        "RepoTags": [
            "not-multiarch:latest",
            "quay.io/rira12621/not-multiarch:latest"
        ],
        "RepoDigests": [
            "quay.io/rira12621/not-multiarch@sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6"
        ],
        "Parent": "",
        "Comment": "buildkit.dockerfile.v0",
        "Created": "0001-01-01T00:00:00Z",
        "Container": "",
        "ContainerConfig": {
            "Hostname": "",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": null,
            "Cmd": null,
            "Image": "",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": null
        },
        "DockerVersion": "",
        "Author": "",
        "Config": {
            "Hostname": "",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/sh",
                "-c",
                "echo \"Hello\""
            ],
            "ArgsEscaped": true,
            "Image": "",
            "Volumes": null,
            "WorkingDir": "/",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": null
        },
        "Architecture": "arm64",
        "Os": "linux",
        "Size": 0,
        "VirtualSize": 0,
        "GraphDriver": {
            "Data": null,
            "Name": "overlay2"
        },
        "RootFS": {
            "Type": "layers"
        },
        "Metadata": {
            "LastTagTime": "2023-04-25T14:36:49.237582669Z"
        }
    }
]
```

Close to the bottom is the culprit:

```shell
"Architecture": "arm64",
```

Okay, that's not really unexpected, and we can find the same in the manifest of the image:

```shell
$ docker manifest inspect --verbose quay.io/rira12621/not-multiarch:latest
{
        "Ref": "quay.io/rira12621/not-multiarch:latest",
        "Descriptor": {
                "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                "digest": "sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6",
                "size": 313,
                "platform": {
                        "architecture": "arm64",
                        "os": "linux"
                }
        },
        "SchemaV2Manifest": {
                "schemaVersion": 2,
                "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                "config": {
                        "mediaType": "application/vnd.docker.container.image.v1+json",
                        "size": 404,
                        "digest": "sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f"
                },
                "layers": []
        }
}
```

At this point multi-arch images come into play. An image is built the same way but for multiple architectures. With our test image we could do that for example with `buildx` or from the CLI. We will check out the manual way. To do that we first adjust our Dockerfile a little, so that the base image always has the right architecture:

```dockerfile
FROM --platform=$BUILDARCH alpine

CMD ["echo", "\"hello\""]
```

In the next step we can start the building

```shell
$ docker build --platform arm64 --build-arg BUILDARCH=arm64 -t quay.io/rira12621/multiarch:latest-arm64  .
[+] Building 0.1s (3/3) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 36B                                                                                                                                                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                 0.0s
 => => writing image sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f                                                                                                                                                                                                                                                                           0.0s
 => => naming to quay.io/rira12621/multiarch:latest-arm6
```

Now push it:

```shell
$ docker push quay.io/rira12621/multiarch:latest-arm64
The push refers to repository [quay.io/rira12621/multiarch]
latest-arm64: digest: sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6 size: 313
```

We can now repeat the same step for other architectures:

```shell
$ docker build --platform amd64 --build-arg BUILDARCH=amd64 -t quay.io/rira12621/multiarch:latest-amd64  .
[+] Building 0.1s (3/3) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 36B                                                                                                                                                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                 0.0s
 => => writing image sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f                                                                                                                                                                                                                                                                           0.0s
 => => naming to quay.io/rira12621/not-multiarch:latest-amd64
 
$ docker push quay.io/rira12621/multiarch:latest-amd64
The push refers to repository [quay.io/rira12621/multiarch]
latest-amd64: digest: sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6 size: 3
```

Now that we pushed those images with a separate tag each, we could run them accordingly by referencing the tag when running or pulling. However, that's not very practical, so instead we will make sure to combine them all under a single manifest. We will do that from the CLI:

```shell
$ docker manifest create quay.io/rira12621/multiarch:latest --amend quay.io/rira12621/multiarch:latest-amd64 --amend quay.io/rira12621/multiarch:latest-arm64
Created manifest list quay.io/rira12621/nmultiarch:latest
```

Let's look at our created manifest:

```shell
$ docker manifest inspect --verbose quay.io/rira12621/multiarch:latest
[
        {
                "Ref": "quay.io/rira12621/multiarch:latest-amd64",
                "Descriptor": {
                        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                        "digest": "sha256:af45e8ede5c3bc278f61a82ea3499b32ec08852c8279c8088466cf40a9d506b9",
                        "size": 313,
                        "platform": {
                                "architecture": "amd64",
                                "os": "linux"
                        }
                },
                "SchemaV2Manifest": {
                        "schemaVersion": 2,
                        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                        "config": {
                                "mediaType": "application/vnd.docker.container.image.v1+json",
                                "size": 404,
                                "digest": "sha256:9a70cd696a8011161cc1d79b92ae9c1ca856243bc63080136b637b7b674bd995"
                        },
                        "layers": []
                }
        },
        {
                "Ref": "quay.io/rira12621/multiarch:latest-arm64",
                "Descriptor": {
                        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                        "digest": "sha256:397d8591b4fb45810c09867d524424955eaf6082cfa105947eaf82a55c9204c6",
                        "size": 313,
                        "platform": {
                                "architecture": "arm64",
                                "os": "linux"
                        }
                },
                "SchemaV2Manifest": {
                        "schemaVersion": 2,
                        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                        "config": {
                                "mediaType": "application/vnd.docker.container.image.v1+json",
                                "size": 404,
                                "digest": "sha256:e6fe5c95a8abdecff96b395dfc599b38115307b8f41288d092c2ecaa2b59e42f"
                        },
                        "layers": []
                }
        }
]
```

Nice, we have two different architectures in the same image, referenceing our respective images for each arch. Next up we can go ahead and push it:

```shell
$ docker manifest push  quay.io/rira12621/multiarch:latest
sha256:8673a97c4ca928d2573e2675912a184fd0b25eac01dcdda684519591d52c231a
```


Let's verify that everything worked by running the image on the Linux box again:

```shell
rrackow@clouderb $ docker run --rm quay.io/rira12621/multiarch
Unable to find image 'quay.io/rira12621/multiarch:latest' locally
latest: Pulling from rira12621/multiarch
f56be85fc22e: Pull complete
Digest: sha256:994de28d3f9e015b1a3593739191dcb0cd56ffc06c08e3e15d0e704ae4039d8b
Status: Downloaded newer image for quay.io/rira12621/multiarch:latest
"hello"
```

Note that in the above command I did **not** specify the tag to reference a specific architecture. In fact, I did not specify any tag, so docker defaults to `latest` and  uses the right image, because we added that information in the manifest for the `latest` tag.


## Verification

Now that we're all on the same playing field, let's try out ourselves what the author describe ourselves, just to make sure. This is something that I generally always recommend
to anyone trying to solve an issue from someone else: try it out the same way they did. Sometimes you will find steps along the way, that most likely have led to the issue.

I'm running the latest version of minikube, freshly downloaded and from a fresh start:

```shell
$ minikube delete
🔥  Deleting "minikube" in docker ...
🔥  Deleting container "minikube" ...
🔥  Removing /Users/rackow/.minikube/machines/minikube ...
💀  Removed all traces of the "minikube" cluster.
$ minikube start
😄  minikube v1.30.1 on Darwin 13.3.1 (arm64)
✨  Automatically selected the docker driver. Other choices: qemu2, ssh
📌  Using Docker Desktop driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.26.3 preload ...
    > preloaded-images-k8s-v18-v1...:  330.52 MiB / 330.52 MiB  100.00% 29.40 M
    > gcr.io/k8s-minikube/kicbase...:  336.39 MiB / 336.39 MiB  100.00% 13.25 M
🔥  Creating docker container (CPUs=2, Memory=3885MB) ...
🐳  Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🔎  Verifying Kubernetes components...
🌟  Enabled addons: default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

As you can see I'm using `docker` as the driver, so we _should_ be able to reproduce the issue. The next step is to run an image. To get a better experience, two namespaces for what we're trying to do:

```shell
$ kubectl create namespace multi-arch-runner-arm
namespace/multi-arch-runner-arm created

$ kubectl create namespace multi-arch-runner-amd
namespace/multi-arch-runner-amd created
```

A small note here: if you are doing things in and for production, you obviously don't want to manipulate your Kubernetes cluster via the CLI and also probably want to have some more structure, but in this case, the cluster will go right to the recycling bin after we're done, so that should be ok.

After that is out of the way, let's run the image:

```shell
$ kubens multi-arch-runner-arm
Context "minikube" modified.
Active namespace is "multi-arch-runner-arm".
$ kubectl run arm-pod-via-tag --image=quay.io/rira12621/multiarch:latest-arm64
pod/arm-pod-via-tag created
```

Remember that I'm on an M1 Mac, so this is the appropriate image for my architecture and we should get the exact same image if we run the `latest` tag instead:

```shell
$ kubectl run arm-pod-latest --image=quay.io/rira12621/multiarch:latest
pod/arm-pod-latest created
```

So far, so good, now to the issue: trying to run a cross-arch image, so in this case, we want to run the amd64 image. Let's try:

```shell
$ kubectl run amd-pod-via-tag --image=quay.io/rira12621/multiarch:latest-amd64
pod/amd-pod-via-tag created
```

You think it's working, but you're wrong:

```shell
$ kubectl get pods
NAME              READY   STATUS             RESTARTS      AGE
amd-pod-via-tag   0/1     CrashLoopBackOff   2 (15s ago)   34s
```

However, a couple of seconds later:

```shell
$ kubectl get pods
NAME              READY   STATUS      RESTARTS      AGE
amd-pod-via-tag   0/1     Completed   3 (43s ago)   62s
```


Interesting. Did it do what it was supposed to do?

```shell
$ kubectl logs amd-pod-via-tag
"hello"
```

Yes!

Let's see if we can get some more information about the pod and what had happened there before. `kubectl describe` is our friend for this:

```shell
$ kubectl describe pod amd-pod-via-tag
Name:             amd-pod-via-tag
Namespace:        multi-arch-runner-amd
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Wed, 26 Apr 2023 16:14:35 +0200
Labels:           run=amd-pod-via-tag
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:  10.244.0.5
Containers:
  amd-pod-via-tag:
    Container ID:   docker://128cfdccf70efc3a46bdbfb2f4cb7859d91f1d0424252a1e7f9310ae382dd2c9
    Image:          quay.io/rira12621/multiarch:latest-amd64
    Image ID:       docker-pullable://quay.io/rira12621/multiarch@sha256:c7fa178b9bafd2e8cb8bb21e12227649ddb11fa9c7e25758dc9cf279ca6e77b1
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 26 Apr 2023 16:15:22 +0200
      Finished:     Wed, 26 Apr 2023 16:15:23 +0200
    Ready:          False
    Restart Count:  3
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-92gnk (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
Volumes:
  kube-api-access-92gnk:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  70s                default-scheduler  Successfully assigned multi-arch-runner-amd/amd-pod-via-tag to minikube
  Normal   Pulling    69s                kubelet            Pulling image "quay.io/rira12621/multiarch:latest-amd64"
  Normal   Pulled     66s                kubelet            Successfully pulled image "quay.io/rira12621/multiarch:latest-amd64" in 3.170102169s (3.170192168s including waiting)
  Normal   Created    23s (x4 over 66s)  kubelet            Created container amd-pod-via-tag
  Normal   Pulled     23s (x3 over 65s)  kubelet            Container image "quay.io/rira12621/multiarch:latest-amd64" already present on machine
  Normal   Started    22s (x4 over 66s)  kubelet            Started container amd-pod-via-tag
  Warning  BackOff    8s (x6 over 64s)   kubelet            Back-off restarting failed container amd-pod-via-tag in pod amd-pod-via-tag_multi-arch-runner-amd(9ef80b27-3ff8-4748-95c9-347833e99503)
```

Okay, it seems like we need something that is running constantly and not just a single command, so we can observe things a bit better.

For the ease of it, we will not build that ourselves again, but rather just pull an image that's built for `amd64` and run it. Luckily there is a collection of images nicely grouped by architecture, so we can use `amd64/httpd`. If you're not familiar, [htttp](https://httpd.apache.org/) is an http server and as such should work nicely for us. Time to try:


```shell
$ kubectl run amd-httpd-pod --image=amd64/httpd
pod/amd-httpd-pod created
```

Left it alone for a while and it's still running;

```shell
$ kubectl get pods
NAME            READY   STATUS    RESTARTS   AGE
amd-httpd-pod   1/1     Running   0          70m
```


That is not so great, as it seems that we cannot reproduce the issue. On the other, maybe that wasn't the actual issue. Let's read it again:

>How do I tell Minikube to cause the same effect as `--platform linux/amd64` flag on its deployment?

So it seems the issue isn't that the author cannot run cross-architecture containers, but rather that they cannot specify a specific architecture from a multi-arch image like the one we built.

So the last missing bit is, what happens if we try to run an image, that is not meant for the local architecture. Let's build one and find out. Our Dockerfile stays the same, and we can go right to the building and pushing, but with a small adjustment to our Dockerfile first: we want to sleep a bit, so the container doesn't exit almost instantly every time. Our new Dockerfile looks like this:

```shell
FROM --platform=$BUILDARCH alpine


CMD ["sleep", "3600"]
```

Now we can build and push:

```shell
$ docker build --platform amd64 --build-arg BUILDARCH=amd64 -t quay.io/rira12621/single-arch-amd64:latest .
[+] Building 1.6s (5/5) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 36B                                                                                                                                                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/alpine:latest                                                                                                                                                                                                                                                                                                       1.5s
 => CACHED [1/1] FROM docker.io/library/alpine@sha256:124c7d2707904eea7431fffe91522a01e5a861a624ee31d03372cc1d138a3126                                                                                                                                                                                                                                                 0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                                                                 0.0s
 => => exporting layers                                                                                                                                                                                                                                                                                                                                                0.0s
 => => writing image sha256:8ff41c82afddaef5f3b5f06e3d93545b0846252380b612c6a9ea1c8c7ace1e2d                                                                                                                                                                                                                                                                           0.0s
 => => naming to quay.io/rira12621/single-arch-amd64:latest
 
 $ docker push quay.io/rira12621/single-arch-amd64:latest
The push refers to repository [quay.io/rira12621/single-arch-amd64]
f1417ff83b31: Mounted from rira12621/multiarch
latest: digest: sha256:c7fa178b9bafd2e8cb8bb21e12227649ddb11fa9c7e25758dc9cf279ca6e77b1 size: 527
```

Just to make sure, we will take a look at the manifest again:

```shell
$ docker manifest inspect -v quay.io/rira12621/single-arch-amd64
{
        "Ref": "quay.io/rira12621/single-arch-amd64:latest",
        "Descriptor": {
                "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                "digest": "sha256:c7fa178b9bafd2e8cb8bb21e12227649ddb11fa9c7e25758dc9cf279ca6e77b1",
                "size": 527,
                "platform": {
                        "architecture": "amd64",
                        "os": "linux"
                }
        },
        "SchemaV2Manifest": {
                "schemaVersion": 2,
                "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
                "config": {
                        "mediaType": "application/vnd.docker.container.image.v1+json",
                        "size": 772,
                        "digest": "sha256:8ff41c82afddaef5f3b5f06e3d93545b0846252380b612c6a9ea1c8c7ace1e2d"
                },
                "layers": [
                        {
                                "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
                                "size": 3374563,
                                "digest": "sha256:f56be85fc22e46face30e2c3de3f7fe7c15f8fd7c4e5add29d7f64b87abdaa09"
                        }
                ]
        }
}
```

Just as expected, we built the image for `amd64` and `linux`, so not our local architecture, which would be `arm64`.

Let's try to run it:

```shell
 $ kubectl run single-wrong-arch --image=quay.io/rira12621/single-arch-amd64
pod/single-wrong-arch created
```

And the overview:

```
$ kubectl get pods
NAME                READY   STATUS    RESTARTS   AGE
single-wrong-arch   1/1     Running   0          11s
```

It seems the issue ends here for us as there is no way for us to reproduce what the author was trying and experiencing. However, we did learn quite a bit about multi-arch images so at least that's time well spent.
