---
title: "Go's Concurrency and parallelism (in Containers)"
author: "Rick Rackow"
date: 2026-09-08T20:00:50+02:00
subtitle: "How I butchered a demo by not sticking to the script"
image: ""
tags: ["go","docker", "container", "kubernetes"]
---

This one is mostly a follow-up to my recent Containerdays talk about Go's
concurrency and parallelism and how it behaves inside containers. If you've been
there, you'll know that the last demo went somewhat into the wall and that I got
slightly stomped by this.

In this post we'll do a quick recap on the topic as a whole and why next time I
should just trust in what I tested instead of half-winging parts.


# Go's concurrency and Parallelism

If you've worked with Go in the past but never understood the difference
between parallelism and concurrency, this section is for you. If you already
know the deal, you can skip to the later section about containers and
Kubernetes.

All examples are to be found on [GitHub](https://github.com/RiRa12621/cds26) so
we can reference the file and folder structure as seen there.

We start off with a simple program:

```golang
package main

import "fmt"

func main() {
	fmt.Println("I am a demo")
}

```

We are defining a _main_ function and then just have it print "I am a demo".
Running it does exactly that:

```shell
$ go run concurrency_stage_1/main.go
I am a demo
```

The next step is to split the things we want to do into a separate function and
respectively call that from the main like so:

```golang
package main

import "fmt"

func work(id int) {
	fmt.Printf("Job %d\n", id)
}

func main() {
	work(1)
}

```

You can see that we created a new function _work_ that, well, does the work. It
takes in an integer, and so we are calling it with `1` as input. For the sake
of the demo, play that back in the print statement and receive the job number
with the ID we gave in as integer.

```shell
$ go run concurrency_stage_2/main.go
Job 1
```

So far we've really just done some build-up, but now we are adding a loop:

```golang
package main

import "fmt"

func work(id int) {
	fmt.Printf("Job %d\n", id)
}

func main() {
	for i := 1; i <= 8; i++ {
		work(i)
	}
}
```

The idea here is that we do some processing sequentially, so one after the
other. The output will therefore show us counting our jobs up from 1 to 8 as we
sequentially run the _work_ function 8 times for all the numbers from 1 to 8.
This produces a list of job counts like so:

```shell
$ go run concurrency_stage_3/main.go
Job 1
Job 2
Job 3
Job 4
Job 5
Job 6
Job 7
Job 8
```

If that's a little fast, add some sleep time so you see it's actually happening
one of the other and not all at once:

```golang
package main

import (
	"fmt"
	"time"
)

func work(id int) {
	time.Sleep(time.Second)
	fmt.Printf("Job %d\n", id)
}

func main() {
	for i := 1; i <= 8; i++ {
		work(i)
	}
}
```

Output is the same as before, just slower. 

Now we get to the interesting part. Golang allows you to leverage its efficiency
by just calling a function with the _go_ keyword. This starts a go routine like
so:

```golang
package main

import "fmt"

func work(id int) {
	fmt.Printf("Job %d\n", id)
}

func main() {
	for i := 1; i <= 8; i++ {
		go work(i)
	}
}
```

Let's run it:

```shell
$ go run concurrency_stage_5/main.go

```

No output.

```shell
$ echo $?
0
```

We did succeed tho, so what happened?

The loop just runs through its instructions eight times, but the instruction is
to start a goroutine that runs a function. We did not tell it to wait for the
goroutines to actually complete. Hence, we get no output because the loop just
finishes quicker than the actual _work_ function.

So far so good, but go allows us to add some waiting:

```golang
package main

import (
	"fmt"
	"sync"
)

func work(id int) {
	fmt.Printf("Job %d\n", id)
}

func main() {
	var wg sync.WaitGroup

	for i := 1; i <= 8; i++ {
		wg.Add(1)

		go func(id int) {
			defer wg.Done()
			work(id)
		}(i)
	}

	wg.Wait()
}

```

We create a new _WaitGroup_. Godocs explain that nicely like so:

>A WaitGroup is a counting semaphore typically used to wait for a group of goroutines or tasks to finish.

To keep it simple: we count the go routines and then wait until they're all done.

The in-depth explanation is a tad bit longer but not really what you need here.

Let's run it:


```shell
$ go run concurrency_stage_6/main.go
Job 8
Job 4
Job 2
Job 3
Job 6
Job 5
Job 7
Job 1
```

As you can see, we now do receive all the results but not in order. Go basically
distributes the resources it has available in the way it best sees fit. That
means that the order of execution is not guaranteed anymore.

The real question now is this: did we just do something concurrently or in
parallel?

It depends. 

Great, right? 

So the thing is that it mostly depends on your system. If Go can execute those
eight jobs across enough CPUs at the same time, they can run in parallel.
Otherwise, they'll still run concurrently, but not all at once.

Why is that? 

```shell
go work(1)
go work(2)
go work(3)

Time →
  
1:  ███    ████       ██
2 :     ███    ████
3   :               ██    ███

```

In the above scenario we have 1 thread. We are starting all the goroutines, but
since we only have one thread, we can only do one thing. Go now nicely tries to
distribute the resources as it can.

If we have 3 threads, on the other hand, we can do all those things in parallel:

```shell
go work(1)
go work(2)
go work(3)

Time →
  
1:  ███████      
2:  ███████
3:  ███████

```

Neat, now we already know the difference between parallelism and concurrency.

Have a Rob Pine quote with it:

>Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once. Not the same, but related.

Sadly, Go and pretty much every other thing a modern computer does is too fast
to really see the difference. Even on a system with only one thread available,
we will not be able to see a difference on those 8 jobs. We need something
that requires a little more effort and takes a little longer. Math to the rescue:

```golang
package main

import (
	"fmt"
	"sync"
)

func work(id int) {
	var sum uint64

	for i := uint64(0); i < 1_000_000_000_0; i++ {
		sum += i
	}

	fmt.Printf("Job %d done: %d\n", id, sum)
}

func main() {
	var wg sync.WaitGroup

	for i := 1; i <= 8; i++ {
		wg.Add(1)

		go func(id int) {
			defer wg.Done()
			work(id)
		}(i)
	}

	wg.Wait()
}

```

We are basically doing **a lot** of counting and adding here, which takes some
seconds. Let's run it and time it:

```shell
$ time go run parallelism_stage_2/main.go
Job 4 done: 13106511847580896768
Job 6 done: 13106511847580896768
Job 5 done: 13106511847580896768
Job 7 done: 13106511847580896768
Job 8 done: 13106511847580896768
Job 2 done: 13106511847580896768
Job 3 done: 13106511847580896768
Job 1 done: 13106511847580896768

real    0m4.417s
user    0m22.139s
sys     0m0.210s
```

So this is on my local box. The repo contains a small "debugger" that shows us
the number of actual logical CPUs visible to the process. Let's run that too:

(For simplicity, whenever I say CPU in this post, I'm talking about a logical
CPU as seen by the operating system.)

```shell
$ go run debug.go
NumCPU      : 14
GOMAXPROCS  : 14

```

You may notice that besides the number of CPUs (threads actually), we also print
the value for _GOMAXPROCS_. Why are we doing this? It just happens to be that we
can actually tell Go how many CPU threads to use instead of having it autodetect
the amount available and then eat them all. To do that, we set _GOMAXPROCS_.

We can see the effect it has on our parallelism vs. concurrency example like so:

```shell
$ time GOMAXPROCS=8 go run parallelism_stage_2/main.go

Job 2 done: 13106511847580896768
Job 7 done: 13106511847580896768
Job 3 done: 13106511847580896768
Job 4 done: 13106511847580896768
Job 8 done: 13106511847580896768
Job 5 done: 13106511847580896768
Job 6 done: 13106511847580896768
Job 1 done: 13106511847580896768

real    0m3.923s
user    0m21.981s
sys     0m0.150s
```

That's the starting point now let's choke it:

```shell
$ time GOMAXPROCS=4 go run parallelism_stage_2/main.go
Job 5 done: 13106511847580896768
Job 3 done: 13106511847580896768
Job 4 done: 13106511847580896768
Job 7 done: 13106511847580896768
Job 8 done: 13106511847580896768
Job 6 done: 13106511847580896768
Job 1 done: 13106511847580896768
Job 2 done: 13106511847580896768

real    0m6.131s
user    0m21.058s
sys     0m0.124s
```

Half the threads, almost double the time it takes to do the same thing. You have
to account for some variance here, because I run some other stuff as well since
this is just my daily driver laptop.

I think the point is clear, though, from the timing.

# Containers and Kubernetes

So on our local box it's all fun and games, the question is, what happens in a
container.

Let's find out by running the debugger:

```shell
$ docker run -ti --rm demo
NumCPU      : 10
GOMAXPROCS  : 10
```

You may be confused, so let me explain. Docker on Mac runs in a VM, and in the
settings you can assign it CPUs. I gave mine 10, so that's what we'll see. The
more interesting part here is that go automatically knows to set _GOMAXPROCS_
to that exact number. That means, GOMAXPROCS is set to the CPUs available
to the container automagically. This neat feature was added in 1.25, which is
making life so much easier. 

However, if for some reason we do not actually want to make the resources
available to go, or rather make go not use them, we can yet again use
_GOMAXPROCS_ like so:

```shell
$ time docker run -e GOMAXPROCS=8 -ti --rm demo
Job 8 done: 13106511847580896768
Job 6 done: 13106511847580896768
Job 2 done: 13106511847580896768
Job 5 done: 13106511847580896768
Job 1 done: 13106511847580896768
Job 3 done: 13106511847580896768
Job 4 done: 13106511847580896768
Job 7 done: 13106511847580896768

real    0m2.984s
user    0m0.014s
sys     0m0.017s
```

The performance is the same as we saw on the host, and we can do the choking again
in the same way:

```shell
$ time docker run -e GOMAXPROCS=4 -ti --rm demo
Job 6 done: 13106511847580896768
Job 5 done: 13106511847580896768
Job 4 done: 13106511847580896768
Job 1 done: 13106511847580896768
Job 2 done: 13106511847580896768
Job 8 done: 13106511847580896768
Job 7 done: 13106511847580896768
Job 3 done: 13106511847580896768

real    0m5.469s
user    0m0.012s
sys     0m0.011s
```

Half the threads, double the time. 

I can see how that doesn't seem overly useful if you run the whole thing
in a single container on a single host. The point is that you can. How do you
mostly run containers nowadays? Kubernetes (or some other Container
Orchestrator)! 

Let's stick our app in a pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo
spec:
  containers:
    - name: cds-demo
      image: quay.io/rira12621/cds-demo
      resources:
        requests:
          cpu: "250m"
        limits:
          cpu: "1500m"
---
apiVersion: v1
kind: Pod
metadata:
  name: demo-debug
spec:
  containers:
    - name: cds-demo-debug
      image: quay.io/rira12621/cds-demo-debug
      resources:
        requests:
          cpu: "250m"
        limits:
          cpu: "1500m"
```

As you can see, it's actually two pods, because we also want the little debugger
so we can look at what's going on.

Let's do that first:

```shell
$ oc logs -f demo-debug
NumCPU      : 4
GOMAXPROCS  : 2

```

This is on a machine with 4 cores, and as you can see, we did not add any env
vars to the container. So why are we ending up here with a _GOMAXPROCS_ of 2?

Rounding. 

Let me explain.

Technically we are getting the information from the _limits_ we set to the pod,
but then why is it 2? Because there are no fractions of CPUs here. That means
go rounds and more importantly, it's always rounding up. Meaning if we set the
limit to 1250m, we will still receive a GOMAXPROCS of 2. Keep that in mind.


# Breaking a demo

The above is basically a speed run of how the talk was supposed to and how I
tested it. Then for some reason, I had a weird brain fart and decided to not
rely on what I did before, or forgot or whatever.

Here's the outcome with the same pod spec as before:

```shell
$ oc logs -f demo-debug
NumCPU      : 10
GOMAXPROCS  : 2

```
We established that. 

Now, instead of going up to use more CPUs, I went with 0,5 CPUs assigned via the
limits, but keep in mind that go is supposed to round that up to 1 because there
are no fractions:

```shell
$ oc logs demo-debug
NumCPU      : 10
GOMAXPROCS  : 2

```

Uhm...ok.

Now the other way around. We seem to have more available, so let's set the limit
to 8 and see:

```shell
$ oc logs demo-debug
NumCPU      : 10
GOMAXPROCS  : 8

```


This is what happened during the demo, and I slightly lost it. If you were
there, I hope you read this, so we can all move on and assume I'm not a total
idiot, just slightly for changing the demo last minute.

The explanation is relatively simple, though: Go refuses to set the _GOMAXPROCS_ 
to less than two automatically as pointed out in the [docs](https://go.dev/pkg/runtime/?m=old&utm_source=chatgpt.com#hdr-Implementation_details).


That explains why we couldn't go lower, but higher worked flawlessly. 

Note to self for next time: really only live demo what you tested and not some
weird "ohhhhh this could also be cool".

At least we got to write a blog so now you know.


