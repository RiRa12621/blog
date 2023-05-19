---
title: "Writing a Container Platform - Part 2"
author: "Rick Rackow"
date: 2023-05-19T16:35:50+01:00
subtitle: "APIs and containers"
image: ""
draft: false
tags: ["Cloud","CoE","pleaco", "Docker", "Containers", "Platform Engineering"]
---

Time to get going. First things first: we need to create a repository and initialize it. GitHub is the easy choice here, but also just as good as any other option right now. We follow [the documentation](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/creating-a-new-organization-from-scratch) to create ourselves a nice organisation so just in case this is actually going to be cool, the whole thing doesn't just live in my personal space. Really, when you consider making something cool that might have an open source community in the future, keep it out of your personal space. It's easy, it's free, and it will save you a lot of pain in the future.

Next we need a repository as well and as mentioned in the last post, we will try to squeeze everything into two parts, so we will need two repositories but the starting point will be platform, so we follow [the documentation](https://docs.github.com/en/get-started/quickstart/create-a-repo) and here it is: our shiny new repo: [https://github.com/pleaco/pleaco](https://github.com/pleaco/pleaco). Nicely comes with an open source license and ready to work with. Time to start the "actual" work.

## Just write something

Here's something about me: I'm terrible at making large plans and then following through, so my usual working process is to just start with something and then evolve from there. Here's our something:


```go
package main

func main() {}

// runner runs a container image
func runner() {
}

// pullGit gets the contents of a git repo
func pullGit() {

}

// buildTest builds container from pulled repo to run tests
func buildTest() {

}

// buildProd builds container from pulled repo for prod
func buildProd() {

}

// exposer exposes a set of containers under a load balancer
func exposer() {

}
```

The idea here is really just to think about the parts that we need and then make them work: 

* run a container
* pull the source from git (most likely GitHub for starters)
* build containers: two of them, because the test should be in the container too but return some test results
* expose our amazing creation to the world


So let's imagine how a user would use this: first they'd make a request to request a source to be deployed. What do we need? Exactly, as REST API. Nice thing there is a [tutorial on go.dev](https://go.dev/doc/tutorial/web-service-gin) that we can follow. We could write this completely from scratch, but if even the official go website tells us to use [Gin](https://gin-gonic.com/docs/) who am I to challenge that.

Let's add a type for `runningContainer` and then some more of them in `runningContainers` and define one container:

```go
type runningContainer struct {
	image string `json:"image"`
	tag   string `json:"tag"`
}

// TODO: replace function to query actual running images
var runningContainers = []runningContainer{
	{image: "hello-world", tag: "latest"},
}
```

We must fill this var with the actual running containers, but for now we don't have a mechanism for that, and we should finish this first piece of the API before starting the next thing. To do so, we will add an endpoint `/containers` where we will get the running containers. Now to do that we need to implement the `router` functionality with some basic information like the address it's supposed to listen on. This means we have to make some additions and our main function looks like this:


```go
func main() {
	apiAddr := flag.String("api-address", ":8080", "The address to listen on for API HTTP requests.")
	//debug := flag.Bool("debug", false, "enable debug logging")

	flag.Parse()

	router := gin.Default()
	router.GET("/containers", getRunningContainers)
	router.Run(*apiAddr)
}
```

Here we have added a flag so that we will be able to specify the port when we run pleaco like `pleaco --api-address=8080`. You see that I also added a `debug` option to enable more verbose logging, but since it's not used right now, it's commented out, so my IDE doesn't constantly complain about an unused variable. After that we parse our flags and then initialize the router var. `Default` returns an Engine instance with the Logger and Recovery middleware already attached, so that we don't really have to do anything else, except define the different endpoint, which is what we're doing with the `router.GET("/containers", getRunningContainers)` part. Lastly, we're running the whole thing.

As you can see we are calling `getRunningContainers`, so that also needs to be defined: 

```go
func getRunningContainers(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, runningContainers)
}
```

You see it's really minimal right now and just returns the `runningContainers` in json format and a 200 http status code.

Now before we do anything else, let's make sure to test everything accordingly while we're creating functionality. We could of course just ignore tests (bad, very bad) or write the tests for everything in hindsight, but writing tests along with the functionality is pretty cool because it helps you to think about what you're creating and what you actually want to achieve. 

So off we go, create a new file called `main_test.go`, since everything else is in `main.go`. [Alex Ellis](https://twitter.com/alexellisuk) wrote a nice [blog](https://blog.alexellis.io/golang-writing-unit-tests/) about creating tests that you can take a look at, if you want to understand more about what's happening, because the [guide](https://gin-gonic.com/docs/testing/) from gin is rather...minimal, but if we follow them, we will figure out, that maybe our structure is actually not super great for being tested, so let's revise our main function a little:

```go
func main() {
	apiAddr := flag.String("api-address", ":8080", "The address to listen on for API HTTP requests.")
	//debug := flag.Bool("debug", false, "enable debug logging")

	flag.Parse()

	router := setupRouter()
	router.Run(*apiAddr)
}

func setupRouter() *gin.Engine {
	router := gin.Default()
	router.GET("/containers", getRunningContainers)
	return router
}
```

Now we can actually test the whole thing a bit better like so:

```golang
func TestGetRunningContainersRoute(t *testing.T) {
	router := setupRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/containers", nil)
	router.ServeHTTP(w, req)

	// Test if we receive 200 statuscode
	assert.Equal(t, 200, w.Code)
}

```

As you may have noticed, this is really more testing the route itself, rather than what's in the body, by just checking if we really get a 200 back. You are correct, but we'll leave it as is for now, mainly because we know that the list of containers will change, and so we will have to mock the whole thing in the future.

This basically concludes our first API endpoint. Yay! Next thing we want to do is to run code in a container. Same spiel as before: create an API endpoint to run the container. While writing the following, I actually noticed that it makes more sense to have all containers collected and just make the status of them a field like so :


```go
type container struct {
	image  string `json:"image"`
	tag    string `json:"tag"`
	status string `json:"status"`
}
```

So with this we can just take all containers now and work with the status field. This requires a bit of a rework of our first API, because now we can't just return the whole set we had, but actually need to find the running ones:


```go
func getRunningContainers(c *gin.Context) {
	var runningContainers []container

	for _, runcontainer := range runningContainers {
		if runcontainer.status == "running" {
			runningContainers = append(runningContainers, runcontainer)
		}
	}

	c.IndentedJSON(http.StatusOK, runningContainers)
}
```


The approach we take here is not the fastest, but it's simple. On the other hand it comes with a little caveat, that the whole thing will get slower over time, so we will have to eventually garbage collect in a sense that we remove stopped or deleted containers.

Back to our new endpoint, where we now just append our container to the existing set:

```go
func runContainer(c *gin.Context) {

	var newContainer container

	err := c.BindJSON(newContainer)
	if err != nil {
		log.Error(err)
	}

	// Anything except "running" is unexpected here and we return a 405
	if newContainer.status != "running" {
		log.Debug("Received unexpected status")
		c.JSON(http.StatusMethodNotAllowed, "Only 'running' allowed as status")
	}

	// Return 201 and the container that was created
	if newContainer.status != "running" {
		containers = append(containers)
		c.IndentedJSON(http.StatusCreated, newContainer)
	}
}
```

Now that we have a way to get containers and add new containers, we also need to translate that into actual actions. Because right now we're just collecting information, not running actual containers. So we rename our functions, by prepending `API` and create the next to actual run a container. Why are we not doing that as part of the API call? We want to stay async from the call. The information about running containers will be shared across all nodes and if everything is async we don't have to wait for a node to "pick" a container that still needs to be run. While we are talking about it, let's add another field `hasNode` to our `container` this will be adjusted once it's actually running somewhere. We make `hasNode` a bool because really that's what matters.


Maybe now is a good time to split things up a little: everything API will go into its own folder and everything container in its own and so on:

```shell
├── LICENSE
├── README.md
├── go.mod
├── go.sum
├── main.go
├── pkg
│   ├── api.go
│   ├── api_test.go
│   └── containers.go
└── types
    └── types.go
```


Moving everything out of the main, has some other consequences, like having to import and on the other side making functions available. So in our `main.go` we now have to import the `pkg` folder to use the functions we create there:

```go
package main

import (
	"flag"
	log "github.com/sirupsen/logrus"
	pleaco "pleaco/pkg"
)
```


In our other files, we have to change things we want to access here to start with a capital letter, which is the way to make sure they're exported. The function to set up the router looks like this now:

```go
func SetupRouter() *gin.Engine {
	router := gin.Default()
	router.GET("/containers", getRunningContainersAPI)
	router.POST("/run", runContainerAPI)
	return router
}
```

Back to scheduling containers. We create a function that runs in the background and looks over the list of containers without nodes: 

```go

func RunContainers() {

	for _, schedulecontainer := range pleaco.Containers {
		if schedulecontainer.HasNode == false {
```

Now we put a "lock" on. Meaning as soon as we start the process to run the container, we set it to running, so no other node tries to run it:

```go
			// Lock the container for other nodes
			schedulecontainer.HasNode = true
```

Now goes the whole docke shebang, that's basically taken from the documentation. We need to test and tune this a little, because we of course want to remove our lock if anything goes wrong, which we are trying, but maybe it's not perfect.For now our runner looks like this:


```go
func RunContainers() {
	for {
		for _, schedulecontainer := range pleaco.Containers {
			if schedulecontainer.HasNode == false {

				// Lock the container for other nodes
				schedulecontainer.HasNode = true

				ctx := context.Background()
				cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
				if err != nil {
					log.Error(err)
					schedulecontainer.HasNode = false
					continue
				}
				defer cli.Close()

				out, err := cli.ImagePull(ctx, schedulecontainer.Image, types.ImagePullOptions{})
				if err != nil {
					log.Error(err)
					schedulecontainer.HasNode = false
					continue
				}
				defer out.Close()
				io.Copy(os.Stdout, out)

				resp, err := cli.ContainerCreate(ctx, &container.Config{
					Image: schedulecontainer.Image,
				}, nil, nil, nil, "")
				if err != nil {
					log.Error(err)
					schedulecontainer.HasNode = false
					continue
				}

				if err := cli.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{}); err != nil {
					log.Error(err)
					schedulecontainer.HasNode = false
					continue
				}

				log.Debug(resp.ID)

			}
		}
	}
}
```


Like this, we constantly check all containers if they're supposed to be running and the ones that don't have a node yet, we try to run one by one. We need to observe how this performs and if we maybe have to add a sleep at the end to give it break.

You might rightfully wonder, how we're executing that functionality. The answer is "by putting it in main". So our main looks like this now:

```go
func main() {
	apiAddr := flag.String("api-address", ":8080", "The address to listen on for API HTTP requests.")
	//debug := flag.Bool("debug", false, "enable debug logging")

	flag.Parse()

	go pleaco.RunContainers()
	router := pleaco.SetupRouter()
	err := router.Run(*apiAddr)
	if err != nil {
		log.Fatal(err)
	}
}
```


And that should conclude this post. Everything will be checked in to [the repo](https://github.com/pleaco/pleaco/), but since this is work in progress, don't be surprised if the state in the repo differs a little from the latest post. 

Hopefully the next post will be out soon when we look further into garbage collection for images and containers and maybe start to build the clustering functionality. I will also add more tests, but I'm not sure yet if that will be part of the blog, since I myself already don't find them super exciting.
