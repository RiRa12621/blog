---
title: "Back to Basics - Kubernetes RBAC"
author: "Rick Rackow"
date: 2025-01-07T09:00:50+02:00
subtitle: "Understanding Role Based Access Control"
image: ""
draft: false
tags: ["kubernetes", "RBAC"]
---

After seeing a lot of blogs and talks it feels like most of them are about really advanced topics, but rarely really
basic things. So I here I am making an effort and starting a new series: back to basics. I'll submit certain topics as
talks at conferences and then publish a blog post afterward, like a talk about container layers that I submitted for
container days. Some other topics will best work as blog posts.

This first blog post in the series will be about Kubernetes RBAC.

## What is RBAC?

RBAC stands for role based access control and the more we'll talk about it, the more you will notice how that is a very
on the nose kind of naming. RBAC is the way authorization works in Kubernetes and also all relevant distributions like
OpenShift or k0s with some nuances here and there, like OpenShift having things like "groups" out of the box, which
vanilla Kubernetes doesn't offer.

Basically, RBAC means that any Role has a given set of permissions, which defines the possible actions that anyone, who
is assigned that role, can perform in the cluster.

## Verbs and Resources

If you worked with Kubernetes, chances are that you have also already worked with `kubectl` to interact with the
cluster like so:

```bash
$ kubectl get pods
NAME                               READY   STATUS    RESTARTS       AGE
coredns-6f6b679f8f-st9q7           1/1     Running   0              120m
etcd-minikube                      1/1     Running   0              120m
kube-apiserver-minikube            1/1     Running   0              120m
kube-controller-manager-minikube   1/1     Running   0              120m
kube-proxy-b464d                   1/1     Running   0              120m
kube-scheduler-minikube            1/1     Running   0              120m
storage-provisioner                1/1     Running   1 (119m ago)   120m
```

This essentially means that you performed a `GET` request for the resource `pod`. `kubectl` commands are by default
namespaced, so you did you query in the current namespace.

All requests against the Kubernetes API work like this and `kubectl` is more or less just a very fancy wrapper around
performing authenticated requests against the API.

The requests you perform are only allowed because you have the correction permissions. You are for example allowed to
`get` the `pods`, but there are more possible verbs:

* GET
* CREATE
* APPLY
* UPDATE
* PATCH
* DELETE
* PROXY
* LIST
* WATCH
* DELETECOLLECTION

I will not list all the possible resources those can apply to, but I recently discovered 
[kubespec.dev](https://kubespec.dev) which lets you explore all resources and their spec.

So essentially what we found out is that the RBAC pattern is "what can you do to which resource?" Next up we will look
into how that's formally specified in Kubernetes.

## Roles and ClusterRoles

This is where the _R_ in _RBAC_ comes from. A role specifies the permissions we talked about before. So, when we want to
allow the above command, we need to think about what that means. We want to be able to `get` the `pods` in the namespace
`kube-system`. Now that we know that, we can write a yaml and apply it (assuming we have the permissions for that) which
looks like so:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace:kube-system
  name:pod-getter
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
```

As you can see, we specified a `namespace` in there. This is the case, since `roles` are namespace scoped. If you wanted
to allow someone to get pods in the whole cluster, you would use a `clusterRole` like so:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name:pod-getter
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
```

If you are an eagle-eyed reader, you will have noticed that there are two verbs and not just one. Why is that? If you
would not have the permissions to `list` `pods` as well, you could only get a speficic pod like so 
`kubectl get pod mypod`.

## RoleBindings and ClusterRoleBindings

In the last section we specified a set of permissions in a role, but now we still need to assign this role to someone.

This is like saying "the designated driver, will have free water the whole evening and be allowed to drive the car", but
when at the end of the night it's not clear who is the designated driver, you will have a bit of an issue.

In Kubernetes this is done using a `RoleBinding` or respectively as `ClusterRoleBinding` if you'd need it cluster-wide.

Let's look at it in practice. We want to allow our my `serviceAccount` the _rickBot_ to get the pods in _kube-system_
namespace, then we will have to create `RoleBinding` like so:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-getter-binding
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-getter
subjects:
  - kind: ServiceAccount
    name: rickBot
    namespace: kube-system

```


 And there you have it, the basics of RBAC.
 
There are obviously some more options and nuances and what not to it, but this really gives you the basics, which seems
like a mission accomplished, given this is the "back to basics" series.