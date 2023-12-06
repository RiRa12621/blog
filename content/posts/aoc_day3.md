---
title: "Advent of Code - Day 3"
author: "Rick Rackow"
date: 2023-12-05T17:35:50+01:00
subtitle: ""
image: ""
draft: true
tags: ["Advent of Code","AoC","golang"]
---

Day 3, another day, another challenge. Actually, the same day but, that didn't sound
right.

Let's get started

### Part 1


First up the challenge:

```shell

--- Day 3: Gear Ratios ---
You and the Elf eventually reach a gondola lift station; he says the gondola lift will take you up to the water source, but this is as far as he can bring you. You go inside.

It doesn't take long to find the gondolas, but there seems to be a problem: they're not moving.

"Aaah!"

You turn around to see a slightly-greasy Elf with a wrench and a look of surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working right now; it'll still be a while before I can fix it." You offer to help.

The engineer explains that an engine part seems to be missing from the engine, but nobody can figure out which one. If you can add up all the part numbers in the engine schematic, it should be easy to work out which part is missing.

The engine schematic (your puzzle input) consists of a visual representation of the engine. There are lots of numbers and symbols you don't really understand, but apparently any number adjacent to a symbol, even diagonally, is a "part number" and should be included in your sum. (Periods (.) do not count as a symbol.)

Here is an example engine schematic:

467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
In this schematic, two numbers are not part numbers because they are not adjacent to a symbol: 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is a part number; their sum is 4361.

Of course, the actual engine schematic is much larger. What is the sum of all of the part numbers in the engine schematic?

```


Great, let's start with our boilerplate:

```golang
package main

import (
	"flag"
	log "github.com/sirupsen/logrus"
	"os"
)

func main() {
	filePtr := flag.String("input-file", "", "input file to read")
	debugPtr := flag.Bool("debug", false, "decide if debug should be enabled")

	// Parse the flags
	flag.Parse()
	// check if we want debug logs
	if *debugPtr == true {
		log.SetLevel(log.DebugLevel)
	}
	// check if a file is specified
	if *filePtr == "" {
		log.Fatalf("You need to specify an input file")
	}

	// read the given file
	file, err := os.Open(*filePtr)
	if err != nil {
		log.Fatalf("Couldn't open file: %v", err)
	}

```

After that is done, let's actually think about what we're going to do. We can't
really go line by line because we always need information about multiple lines, or at least the next line for that matter.
So what we could do is map out the position of all symbols and all numbers like in
coordinate system so each symbol will get a `line` and a `position` value. The problem is
that we can't do the exact same for the numbers because they can span multiple
positions, or we have to make the position an array of integers.

Let's start with the symbols though.


```golang
type Symbol struct {
	Position int `json:"position"`
}

type Number struct {
	Value int `json:"value"`
	Position []int `json:"position"`
}
```


Not sure yet if we'll need that but that may be a little easier to work with
than an unnamed multidimensional array.

Now scan each line for numbers:



