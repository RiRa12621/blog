---
title: "Getting Back in Shape"
author: "Rick Rackow"
date: 2024-05-03T19:00:50+01:00
subtitle: "Go for dummies"
image: ""
tags: ["golang"]
---

Let me set the scene: I've worked a bunch of jobs recently that basically expected a lot of talking and very little
getting actual stuff done. You know, it's just part of the evolution of becoming more senior as an engineer. You don't
really get to make a bigger impact if you just stay in your little comfort zone coding small features and fixing bugs.
You need to go out and talk to people. However, that's a very wide topic and rather of a different day. In this post
we'll talk about getting back in shape with coding. The reality is, if you want to change jobs, it's very likely that
you'll have to code and after completely messing up a coding interview rather recently, I figured that being super
rusty, isn't really helpful. For one, because it's sad to not be able to just work things out in a snap, but on the
other hand, it also is not doing yourself a favor in a live coding scenario when you're under pressure. You want to
be in your comfort zone, so you don't get sweating.

Now that we figured, that it's good to be back in shape with coding, let's talk about the content. I'll basically go
over a bunch of stuff in Go, and maybe we can bring everything together to a small project at the end. Each section
should be self-sufficient, so you can just scroll to the one that interest you.

One small note before we get going: this is not the end all be all go information. There are various books and blogs, as
well as the [Go Documentation](https://go.dev/doc/) that will do that better. This is just what I brushed up on and
small gotchas when I came across them.

## Data Types

### Variables

Nothing really goes without variables. Go allows you to work with variables in a bunch of different ways.

Define a variable with a type:

```Go
var a int
```

In this example we explicitly defined the variable `a` and made it have the type `int` (an integer).

It is important to understand that it matters where you define it. Let's look at some examples. In the first example,
we define our variable inside our main function:

```Go
package main

import "fmt"

func main() {
	var a int

	fmt.Println(a)
}

```

This is probably the most common case: you define a variable where you need it, and if it's needed somewhere else, you
pass it over to the function, that needs it.

The alternative here is to define a global. You can do that, by defining the variable outside any function like so:

```Go
package main

import "fmt"

var a int

func main() {

	fmt.Println(a)
}
```

The advantage is, that now you are able to work with this variable from everywhere. Like so:

```Go
package main

import "fmt"

var a int

func main() {
	maker()

	fmt.Println(a)
}

func maker() {
	a++
}
```

You can see that we defined the variable globally, and so we can increase it in the `maker` function and then use it in
the print statement in the `main` function without passing it around. Not the most meaningful way of using a global, but
I hope it's simple enough to grasp the concept.

So as you can see, we currently just pass a variable around, but it doesn't actually have any value. Let's add one: We
defined our variable to we just need to assign it a value:

```Go
package main

import "fmt"

func main() {
	var a int
	a = 1
	fmt.Println(a)
}

```

Great stuff, but we can do even better: Go allows you to initialize a variable and assign it a value in one go (pun
intended) like so:

```Go
package main

import "fmt"

func main() {
	a := 1
	fmt.Println(a)
}
```

Here's the caveat: you can only do this once. Meaning, after that the variable is initialized and you "just" can assign
it a value like so:

```Go
package main

import "fmt"

func main() {
	a := 1
	fmt.Println(a)

	a = 2

	fmt.Println(a)
}
```

Which will output the following:

```Shell
$ go run main.go
1
2

```

As you can see we initialized the variable `a` and assigned it the value `1` in the very first step, printed the value
and then assigned it a new value of `2` and printed again.

The whole thing with initializing a variable and assigning it a value, gets even more interesting when we get into
functions. We will get more into functions next but let's take a sneak peek:

```Go
package main

import "fmt"

func main() {
	a := 1
	result, err := doSomething(a)

	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(result)
}

func doSomething(num int) (int, error) {
	return num, nil
}
```

Ignore the whole function and everything, but what we have done here, is to initialize and assign multiple variables at
the same time. That, as you can see, is great for assigning the returned values of a function to variables. Now,
something to keep in mind here, is that any variable you create **must** be used. It doesn't matter if you just
initialized it but didn't assign a value. Lets, look at an example for valid and invalid go code.

Valid:

```Go
package main

import "fmt"

func main() {
	var a int

	fmt.Println(a)
}
```
This results in the following output:

```Shell
$ go run main.go
0
```


Invalid:

```Go
package main

import "fmt"

func main() {
	var a int

	fmt.Println("Let's go")
}
```
What happens if you try to run this? It will fail like so:

```Shell
$ go run main.go
# command-line-arguments
./main.go:6:6: a declared and not used

```

### Structs

Structs are basically a collection of fields and each field has a type. Let's look at an example. We could have
a struct called "Person" and that "Person" should have some information about a person, like age, name and hometown.
What would that look like?

```Go
type Person struct {
	Age      int
	Name     string
	Hometown string
}
```

Now we can access our newly made struct and fill it with information like so:

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}

func main() {
	myself := Person{
		Age:      35,
		Name:     "Rick Rackow",
		Hometown: "Berlin",
	}

	fmt.Println(myself)
}
```

As you can see, we filled all fields, but you can also do it individually and access the fields individually as well
as so:

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}

func main() {

	var myself Person

	myself.Name = "Rick Rackow"

	fmt.Println(myself.Name)
}
```

### Arrays and Slices

If you're familiar with any other programming language, you'll know what an array is. Basically just a collection of
"things". This can be just bytes or integers or strings or anything really. Now, Go additionally has something called
a "slice". For us here right now, the key difference is the length. An array is of fixed length whereas a slice is
flexible, ie can be shorter or longer depending on the amount of elements in it, which from my perspective gives you
a large usability improvement. Obviously there are performance implications when the resizing is happening, but that's
a bit too far out for us for now. At this time we will go with the following rule: if we know the amount of elements
that we will end up having, we use an array, otherwise we will use a slice.

Let's look into the implementation. Since the array has a fixed length, we will also have to initialize it with one.
We can do that like so:

```Go
func main() {
	var someArray [2]int
}
```

Now we can access and fill our array like so:

```Go
func main() {
	var someArray [2]int

	someArray[0] = 2
	someArray[1] = 55

	fmt.Println(someArray[0])
}
```

We use the index of the array to fill it and also access it. Not sure that I need to tell you this, but arrays (and slices
for the matter) start from 0. So if you want to access the first element, you need to use `[0]` like in the example
above.

What about the slices? No need to specify the size or anything, but accessing works pretty much the same. In the
following example we will create a slice, add some elements to it and then add some more, so you can see that the
length is completely dynamic.

```Go
func main() {
	someSlice := []int{1, 2, 3, 4, 5}
	fmt.Println(someSlice)

	someSlice = append(someSlice, 6, 7, 8)
	fmt.Println(someSlice)
}
```

The output of the above:

```Shell
$ go run main.go
[1 2 3 4 5]
[1 2 3 4 5 6 7 8]
```

Now that we're done with the basic data types, let's move on to functions.

## Functions

This section will cover functions but also if-clauses and basic loops.

A function in go follows this pattern:

```Go
func functionName(inputName inputType) outputType{

}
```

There are some variations to this, where we can use a function without any input, multiple inputs, no output, multiple
outputs.

No inputs:

```Go
func functionName() outputType{

}
```

Multiple Inputs:

```Go
func functionName(inputName inputType, inputName2 inputType2) outputType{

}
```

No Output:

```Go
func functionName(inputName inputType){

}

```

Multiple Outputs:

```Go
func functionName(inputName inputType)(outputType, outputType2){

}
```


It is important to keep in mind that go is very explicit. That means, if you defined your function to return two things,
 you must also return two things. Likewise, if you expect two things as input, you need to also provide two things as
input. The same goes for the types. If you expect an input of type `string` you need to actually provide a string.

Lets a look at some examples:


```Go
package main

func main() {
	var a int

	doSomething(a)
}

func doSomething(num int) (int, error) {
	return num, nil
}
```

While the above example is valid, it's pretty much useless. The issue is, that we're not working with what we return
from our `doSomething` function, which for one makes the whole thing pretty useless but also means we wouldn't notice
any errors, we could possibly return. To improve this, we will introduce a new concept: if-clauses.

### Conditionals

Sometimes we want to do a certain action (or not do it) in case something happens. For this we can use an if-clause.

The syntax is as follows:

```Go
if <Condition> {
 do something
}
```

The condition basically evaluates to `true` or `false` and therefore go decides if it needs to perform the respective
action. The condition can we constructed in a variety of ways like basic arithmetic or comparisons or outright evaluate
a bool.

Example time.

Using a bool

```Go
package main

import "fmt"

func main() {
	var a int

	condition := true

	if condition {
		fmt.Println("It Works")
	}
}
```

The above example will print "It Works" to stdout.

What happens if we negate the condition:

```Go
package main

import "fmt"

func main() {
	var a int

	condition := true

	if !condition {
		fmt.Println("It Works")
	}
}
```

The above will not print anything because we only execute the instruction if the condition is false, which it can't be,
since we just set it to `true`.

Now, if we were to say "if this happens do x or else do y", there's a way: the `else` statement.

```Go
package main

import "fmt"

func main() {
	var a int

	condition := true

	if !condition {
		fmt.Println("It Works")
	} else {
		fmt.Println("Also works")
	}
}
```

Keep in mind though, that usually the more idiomatic way to do things in go is to prefer `if` statements over if-else.

There's also on more: chaining two conditions. Basically think of it as "if x happens to 1 and if y happens do 2". This
will be done using `if` and `else if` and it looks like this:

```Go
package main

import "fmt"

func main() {
	var a int

	condition := true

	if !condition {
		fmt.Println("It Works")
	} else if condition{
		fmt.Println("Also works")
	}
}
```

So far we covered a couple of possibilities, but what happens if we want to cover a lot of cases? We have the concept of
switch-case. We basically define a lot of possible cases and the respective actions we want our app to perform.

The whole thing looks like this:

```Go
package main

import "fmt"

func main() {
	a := 2

	switch a {
	case 1:
		fmt.Println("It's 1")
	case 2:
		fmt.Println("It's 2")
	case 3:
		fmt.Println("It's 3")
	default:
		fmt.Println("It's some other number")
	}
}
```

Guessing game: what are we outputting?

Answer: "It's 2".

The way this works is that we define the switch that we're supposed to evaluate in this case just what the value of `a`
is. Since we just defined `a` to be `2`, we will evaluate to `2` and therefore do what's defined for that case. You may
notice an additional statement at the end, which doesn't really look like the others but is pretty self-explanatory.
This is the `default` and it acts as a fallback, meaning if all others cases aren't right, this is what will be done.
In our case this would trigger on all values for `a` that aren't either 1, 2 or 3.

## Methods

You can think of methods as a special case of function. The syntax is relatively similar, just that there is a receiver
added. This receiver can be a struct or not (great explanation, isn't it?), however most commonly it is used with a
struct.

Basic syntax:

```Go
func (a anyType) methodName(input type){
}
```

Ok great, now how about an actual example? We just stick to the struct we defined before and do something with it.

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}

func main() {
	myself := Person{
		Age:      35,
		Name:     "Rick Rackow",
		Hometown: "Berlin",
	}

	myself.displayAge()
}

func (p Person) displayAge() {
	fmt.Printf("%v is %v years old", p.Name, p.Age)
}

```


Here's what happens in the example: we have defined our struct `Person` and that has fields for age, name and hometown.
Now in the `main` function we are initializing a new Person `myself` and add some values to its fields. So far so good.
Now comes the method. Since we defined the receiver to be the `Person` struct, we can now use that method on all
`Person` we have. The method itself is pretty simple: we accept no input and just print two fields formatted. The
output is the following:

```Shell
$ go run main.go
Rick Rackow is 35 years old
```

You might be wondering why we're using methods. I mean we can do the same with just a function like so:

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}

func main() {
	myself := Person{
		Age:      35,
		Name:     "Rick Rackow",
		Hometown: "Berlin",
	}

	displayAge(myself)
}

func displayAge(p Person) {
	fmt.Printf("%v is %v years old", p.Name, p.Age)
}
```

One reason is that we can logically group things. For example, we can add more methods to display hometown and age and
they can all be used on `Person` types like this:

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}

func main() {
	myself := Person{
		Age:      35,
		Name:     "Rick Rackow",
		Hometown: "Berlin",
	}

	myself.displayAge()
	myself.displayHometown()
	myself.displayName()
}

func (p Person) displayAge() {
	fmt.Printf("%v is %v years old", p.Name, p.Age)
}
func (p Person) displayHometown() {
	fmt.Printf("%v is from %v", p.Name, p.Hometown)
}
func (p Person) displayName() {
	fmt.Printf("%v", p.Name)
}
```

Additionally, you can define the same method for multiple receivers. You might want to be a bit careful with that,
because your users (or yourself) will expect similar or the same behaviour from the same method. Let's look at an
example that makes sense:

```Go
package main

import "fmt"

type Person struct {
	Age      int
	Name     string
	Hometown string
}
type Dog struct {
	Age  int
	Name string
}

func main() {
	myself := Person{
		Age:      35,
		Name:     "Rick Rackow",
		Hometown: "Berlin",
	}

	myDog := Dog{
		Age:  4,
		Name: "Bandit",
	}

	myself.displayAge()
	myDog.displayAge()

}

func (p Person) displayAge() {
	fmt.Printf("%v is %v years old", p.Name, p.Age)
}

func (d Dog) displayAge() {
	fmt.Printf("%v is %v years old", d.Name, d.Age)
}
```

As you can see, I made the behaviour **very** similar in this case, mostly to bring the point across.

There's some more to cover here, but that deserves a separate blog, especially differences between using values and
pointers as receivers.

In the next section, we'll look at some more stuff that we can do with methods

## What's next?

Next time we'll look into interfaces and then build some fun stuff that actually makes use of everything we know
so far.


