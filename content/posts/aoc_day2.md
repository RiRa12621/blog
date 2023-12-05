---
title: "Advent of Code - Day 2"
author: "Rick Rackow"
date: 2023-12-05T10:35:50+01:00
subtitle: ""
image: ""
tags: ["Advent of Code","AoC","golang"]
---

Day 2, another day, another challenge.

Here's the challenge:

```shell

--- Day 2: Cube Conundrum ---
You're launched high into the atmosphere! The apex of your trajectory just barely reaches the surface of a large island floating in the sky. You gently land in a fluffy pile of leaves. It's quite cold, but you don't see much snow. An Elf runs over to greet you.

The Elf explains that you've arrived at Snow Island and apologizes for the lack of snow. He'll be happy to explain the situation, but it's a bit of a walk, so you have some time. They don't get many visitors up here; would you like to play a game in the meantime?

As you walk, the Elf shows you a small bag and some cubes which are either red, green, or blue. Each time you play this game, he will hide a secret number of cubes of each color in the bag, and your goal is to figure out information about the number of cubes.

To get information, once a bag has been loaded with cubes, the Elf will reach into the bag, grab a handful of random cubes, show them to you, and then put them back in the bag. He'll do this a few times per game.

You play several games and record the information from each game (your puzzle input). Each game is listed with its ID number (like the 11 in Game 11: ...) followed by a semicolon-separated list of subsets of cubes that were revealed from the bag (like 3 red, 5 green, 4 blue).

For example, the record of a few games might look like this:

Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
In game 1, three sets of cubes are revealed from the bag (and then put back again). The first set is 3 blue cubes and 4 red cubes; the second set is 1 red cube, 2 green cubes, and 6 blue cubes; the third set is only 2 green cubes.

The Elf would first like to know which games would have been possible if the bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?

In the example above, games 1, 2, and 5 would have been possible if the bag had been loaded with that configuration. However, game 3 would have been impossible because at one point the Elf showed you 20 red cubes at once; similarly, game 4 would also have been impossible because the Elf showed you 15 blue cubes at once. If you add up the IDs of the games that would have been possible, you get 8.

Determine which games would have been possible if the bag had been loaded with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the IDs of those games?
```


Oki doki. I'll not lie, this probably would be easiest in bash as one-liner,
but we want to do some proper coding so off we go.

We start with our usual boilerplate:

```golang
package main

import (
	"flag"
	log "github.com/sirupsen/logrus"
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
}

```

We're accepting a file via flag and also the `--debug` flag for logging options.

Next, we're reading the file again:

```golang
	// read the given file
	file, err := os.Open(*filePtr)
	if err != nil {
		log.Fatalf("Couldn't open file: %v", err)
	}
	defer file.Close()
```

Now we're getting into the actual logic: What do we want to do?

Let's create a `struct` that we can read the line into:

```golang
type Game struct {
	Id    int  `json:"id"`
	Red   int  `json:"red"`
	Blue  int  `json:"blue"`
	Green int  `json:"green"`
	Valid bool `json:"valid"`
}
```


Let's read each line into an array of strings:

```golang


// readLines read a line from a file and adds each lines as string element into an array
func readLines(file *os.File) ([]string, error) {
	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}
```

If we keep on using this function, maybe we can just import it in the future.

Next, we want to read every line into a `Game` type and then have an array of those.
So in our main we do the following:

```golang
	// Create an array of games
	var games []Game

	for _, line := range lines {
		game, err := parseLine(line)
		if err != nil {
			log.Debugf("Couldn't parse line: %v", err)
		}
		games = append(games, game)
	}
```

We need to also create the `parseLine` function and what can I say? Regex again :(

First let's split the line at the colon:

```golang
	parts := strings.Split(line, ":")
	if len(parts) != 2 {
		return game, fmt.Errorf("invalid line format")
	}
```

If there are less than two parts, something is obviously wrong, and we return that
as an error.


Next, we're getting the gameID out:

```golang
	// Match a number
	expression := regexp.MustCompile("[0-9]*")
	gameNumber := expression.FindAllString(parts[0], -1)
	game.Id, err = strconv.Atoi(gameNumber[0])
	if err != nil {
		return game, err
	}
```

So far, so good. Now the ugly bit: counting for the numbers:

```golang
	// split on each semicolon for sets of cubes
	// example structure looks like this now: ["13 blue", "6 green, 4 blue, 11 red", "15 red"]
	cubeSets := strings.Split(parts[1], ";")

	// split every cubeSet into it's color/value pairs
	for _, cubeSet := range cubeSets {
		pairs := strings.Split(cubeSet, ",")
		// pairs is now like so ["6 green", "4 blue", "11 red"]

		for _, pair := range pairs {
			colorValue := strings.Split(pair, " ")
			count, err := strconv.Atoi(colorValue[0])
			if err != nil {
				return game, err
			}

			// Add count depending on value we got.
			switch colorValue[1] {
			case "red":
				gameMap["red"] += count
			case "blue":
				gameMap["blue"] += count
			case "green":
				gameMap["green"] += count
			}

		}
	}
```

I tried to make the comments extensive but let's still talk about what's happening:

We are splitting into the separate sets of cubes on each semicolon, then for each
of the sets of cubes split it on the comma into count and color pairs and then for each
of the pairs split again on a whitespace. This way we end up with [int, string] pairs.
Now we check which color we have, and then depending on that, add to the corresponding
color count in our map.


After all of this is done, we can read into the `game` and return it.

Actually, we can slim this down:

```golang
	// split on each semicolon for sets of cubes
	// example structure looks like this now: ["13 blue", "6 green, 4 blue, 11 red", "15 red"]
	cubeSets := strings.Split(parts[1], ";")

	// split every cubeSet into it's color/value pairs
	for _, cubeSet := range cubeSets {
		pairs := strings.Split(cubeSet, ",")
		// pairs is now like so ["6 green", "4 blue", "11 red"]

		for _, pair := range pairs {
			colorValue := strings.Split(pair, " ")
			count, err := strconv.Atoi(colorValue[0])
			if err != nil {
				return game, err
			}

			// Add count depending on value we got.
			switch colorValue[1] {
			case "red":
				game.Red += count
			case "blue":
				game.Blue += count
			case "green":
				game.Green += count
			}

		}
	}
```

This way, we just add the info right away into the `game`. Now we can return
everything.

Small update: reading is really important. We can validate in each round per game
if it's a valid game or not, and **not** in total. So we make a little addition:

```golang
			case "red":
				if count > 12 {
					game.Valid = false
				}
				game.Red += count
			case "blue":
				if count > 14 {
					game.Valid = false
				}
				game.Blue += count
			case "green":
				if count > 13 {
					game.Valid = false
				}
				game.Green += count
			}
```


For each color, we check the value and if it's over the threshold, set this game
to invalid.

Now we can do the parsing and assertion for every line:

```golang
	for _, line := range lines {
		game, err := parseLine(line)
		if err != nil {
			log.Debugf("Couldn't parse line: %v", err)
		}

		// validate if it's a possible game
		games = append(games, game)
	}
```

That way we end up with a set of games. Technically we don't need all the information,
but I sense that we might need it in a second part. If not, we can obviously just
shrink it all down by a lot.


The last step for this challenge will be to calculate the sum of the IDs of invalid
games, so let's add that to our code:

```golang
func sumGameIds(games []Game) int {
	var result int
	for _, game := range games {
		if !game.Valid {
			result += game.Id
		}
	}
	return result
}
```

Pretty simple stuff: we go over all the games we have, if they're invalid, add
their ID value to our result and then return the result. We also need to access
that value and somehow print it, so we can check if that worked. So in the main
we add the following:

```golang
log.Infof("The solution is: %v", sumGameIds(games))
```

No need to store that somewhere.

### Debug time
Thanks to our finest debug logging, we quickly figure that something is actually
not going well:

```shell
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 
DEBU[0000] Couldn't parse line: strconv.Atoi: parsing "": invalid syntax 

```


Seems there's something wrong when we try to parse a number in a string into an int.
There are not that many occasions where that happens and after a second look, the regex might
be a bit faulty, that we're using to get the gameID. Adjusting that gets us further.


```golang
	// Match a number
	expression := regexp.MustCompile(`\d+`)
	gameNumber := expression.FindAllString(parts[0], -1)
	log.Debugf("Got game number %v", gameNumber)
	log.Debugf("Using %v as gameID", gameNumber[0])
	game.Id, err = strconv.Atoi(gameNumber[0])
	if err != nil {
		log.Debugf("Failed to parse gameID")
		return game, err
	}
```

Added some more debug logging in there, because why not. The whole thing looks better now,
but it's still failing on another string to int conversion. Apparently, we are keeping
a whitespace when we parse the colors. We can either fix that properly, or dirty hack.
Since the info we want is in fact in there, we can just access it correctly:

```golang
	// split every cubeSet into it's color/value pairs
	for _, cubeSet := range cubeSets {
		pairs := strings.Split(cubeSet, ",")
		// pairs is now like so [" 6 green", " 4 blue", " 11 red"]

		for _, pair := range pairs {
			colorValue := strings.Split(pair, " ")
			count, err := strconv.Atoi(colorValue[1])
			if err != nil {
				log.Debugf("Couldn't convert color value")
				log.Debugf("Received %v", colorValue[1])
				return game, err
			}
```

Keep in mind to also adjust the switch statement:

```golang
			// Add count depending on value we got.
			switch colorValue[2] {
			case "red":
				if count > 12 {
					game.Valid = false
				}
				game.Red += count
			case "blue":
				if count > 14 {
					game.Valid = false
				}
				game.Blue += count
			case "green":
				if count > 13 {
					game.Valid = false
				}
				game.Green += count
			}
```

Now that everything is working, we're having another great case of "please read".
We need the sum of games that **are** possible, not the impossible ones. 
Lucky us, we saved everything and just need one adjustment:

```golang
func sumGameIds(games []Game) int {
	var result int
	for _, game := range games {
		if game.Valid {
			log.Debugf("valid game at number  %v", game.Id)
			result += game.Id
		}
	}
	return result
}
```


And that's it!

Code on [GitHub](https://github.com/RiRa12621/advent_of_code23/blob/main/day2/challenge1/main.go)
