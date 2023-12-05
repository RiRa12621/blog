---
title: "Advent of Code - Day 1"
author: "Rick Rackow"
date: 2023-12-05T09:35:50+01:00
subtitle: ""
image: ""
tags: ["Advent of Code","AoC","golang"]
---


It's the time of year again where you come together and... DO CODE CHALLENGEEEEEES!

Yes, [Advent of Code](https://adventofcode.com/) is basically happening every year.
With 24 cool challenges, in this case actually more, as we will find out. So I thought,
why not get some coding done and then write a little thing about it. Actually,
I got hooked by Polar Signal's "Let's Profile", so kudos go there. I think it's
probably needless to say ,but I don't, wouldn't and can't claim that my solutions are
the best or fastest or whatever. They're just my solutions, no more, no less.

## Challenge 1


### Part 1
The first challenge is also explanatory and split into two parts, here's the first one:

```shell
--- Day 1: Trebuchet?! ---
Something is wrong with global snow production, and you've been selected to take a look. The Elves have even given you a map; on it, they've used stars to mark the top fifty locations that are likely to be having problems.

You've been doing this long enough to know that to restore snow operations, you need to check all fifty stars by December 25th.

Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

You try to ask why they can't just use a weather machine ("not powerful enough") and where they're even sending you ("the sky") and why your map looks mostly blank ("you sure ask a lot of questions") and hang on did you just say the sky ("of course, where do you think snow comes from") when you realize that the Elves are already loading you into a trebuchet ("please hold still, we need to strap you in").

As they're making the final adjustments, they discover that their calibration document (your puzzle input) has been amended by a very young Elf who was apparently just excited to show off her art skills. Consequently, the Elves are having trouble reading the values on the document.

The newly-improved calibration document consists of lines of text; each line originally contained a specific calibration value that the Elves now need to recover. On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.

For example:

1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
In this example, the calibration values of these four lines are 12, 38, 15, and 77. Adding these together produces 142.

Consider your entire calibration document. What is the sum of all of the calibration values?

```


Additionally, there's a link to a page with **a lot** of lines.

That's all we need to go, so off to the solution.


Let's start with a main. I like some flags there, so that we can specify an input
and also get debug logging:

```golang
func main() {
	filePtr := flag.String("input-file", "", "input file to read")
	debugPtr := flag.Bool("debug", false, "decide if debug should be enabled")

```


Next we open the file.

```golang
	// read the given file
	file, err := os.Open(*filePtr)
	if err != nil {
		log.Fatalf("Couldn't open file: %v", err)
	}
	defer file.Close()
	
```

Now we also need to read each line
```golang
	lines, err := readLines(file)
	if err != nil {
		log.Fatalf("Couldn't read lines in file: %v", err)
	}
```


I put the actual line reading in a separate function. What it does is that it
reads each line in the file that we opened and git it as input. It will return
an array of strings, so each line is one element in the array:

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

Now that we have all the lines ready to work with, what do we do? Exactly, extract
the number for each line:

```golang
	// go over each line and get the number from it, then add the number to the numbers
	for linenumber, line := range lines {
		thisSum, err := getNum(line)
		if err != nil {
			log.Fatalf("Couldn't get number for line %v: %v", linenumber, err)
		}
		log.Debugf("Line %v, has number %v", linenumber, thisSum)
		numbers = append(numbers, thisSum)
	}
```

Note that there's always some logging there. The whole thing could be smaller
and slimmer at this point, but this way is just sticking to better praxis imho.

Let's look at the `getNum` function:

```golang
// getNum gets concatenated number from a string and returns it as int
func getNum(line string) (int, error) {
	// regex match all numbers
	expression := regexp.MustCompile("[0-9]")

	// find the all numbers in the string
	allNumbers := expression.FindAllString(line, -1)
	log.Debugf("All numbers in line: %v", allNumbers)

	// just get the first and last number
	numbers := []string{allNumbers[0], allNumbers[len(allNumbers)-1]}
	log.Debugf("Got number %v", numbers)

	// concatenate the strings
	var str strings.Builder
	for _, number := range numbers {
		str.WriteString(number)
	}
	// return int converted from string
	result, err := strconv.Atoi(str.String())
	if err != nil {
		return result, err
	}
	return result, nil
}
```
We take a string as input and return an int. (mind you that we want to add everything up later)

Maybe let's break it down a little. First we define a regex and then find everything
in the given string that matches this regular expression:

```golang
	// regex match all numbers
	expression := regexp.MustCompile("[0-9]")

	// find the all numbers in the string
	allNumbers := expression.FindAllString(line, -1)
	log.Debugf("All numbers in line: %v", allNumbers)
```

Now the important bit: some lines have multiple numbers. So we need to make sure
to actually just get the first and the last:

```golang
	// just get the first and last number
	numbers := []string{allNumbers[0], allNumbers[len(allNumbers)-1]}
	log.Debugf("Got number %v", numbers)
```

Now we basically glue the numbers together. Basically, now we have `[1,2]` and that
needs to become `12`:

```golang
	// concatenate the strings
	var str strings.Builder
	for _, number := range numbers {
		str.WriteString(number)
	}
```

Next up we have to (or want to) convert this string to an int, so we can add
all the values together:

```golang
	// return int converted from string
	result, err := strconv.Atoi(str.String())
	if err != nil {
		return result, err
	}
	return result, nil
```

The result is what we want to return if everything went well, otherwise we return
and error that we can handle.

The last step is to sum up everything. We could have done that in the main, but
I didn't:

```golang
// sumArray sums all elements in an array of integers and returns the result as new int
func sumArray(sums []int) int {
	result := 0

	for _, number := range sums {
		result += number
	}
	return result
}

```

And then the final step is returning our information:

```golang
	// add the numbers up
	result := sumArray(numbers)
	log.Infof("The result is %v", result)
```

That's it. Done.

The whole code is on [GitHub](https://github.com/RiRa12621/advent_of_code23/blob/main/day1/challenge1/main.go)

Off to part 1


### Part 2

The second part follows up directly and goes like this:


```shell
--- Part Two ---
Your calculation isn't quite right. It looks like some of the digits are actually spelled out with letters: one, two, three, four, five, six, seven, eight, and nine also count as valid "digits".

Equipped with this new information, you now need to find the real first and last digit on each line. For example:

two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
In this example, the calibration values are 29, 83, 13, 24, 42, 14, and 76. Adding these together produces 281.

What is the sum of all of the calibration values?
```


Since I'm a little lazy, so we'll just extend the regex. Remember that we initially,
where just looking for `0-1`:


```golang
expression := regexp.MustCompile("[0-9]")
```


Now we need to extend with `one`, `two`, `three`, `four`, `five`, `six`, `seven`,
`eight`, and `nine`.

```golang
expression := regexp.MustCompile("[0-9]|one|two|three|four|five|six|seven|eight|nine")
```

What is wrong with this? It doesn't account for overlaps. For example in the following line
there are the following numbers (either words or digits) `eigth`, `two`, `six`, 8, `seven`.


```shell
gcqeightwosix8xdlhrnnbkmsevenqdbrjghz

```

If we use our regex from above, we only capture `eight`, `six`, 8, `seven`. No big deal here,
because the result for us stays the same: 87. However, if we have an overlap like
this at the end of the line, we get a wrong result. 

Now if you dig a little into the [go docs](https://pkg.go.dev/regexp) you will find,
that it explicitly states "non-overlapping" matches, which causes a little bit of an
issue for us, because we can't just build a simple regex and get our info. So let's
try to find out where we can actually have overlaps:
* one - eight (oneight)
* two - one (twone)
* three - none
* four - none
* five - none
* six - none
* seven - nine (sevenine)
* eight - two, three (eightwo, eighthree)
* nine - none

The overlapping is "just" an issue if it affects the last given number, since the first
match is what we capture. Let's do some dark magic: in the string that we get, we will
replace the number with the corresponding digit and the first + final letter as that's all we need for the overlap.

```golang
	log.Debugf("Line before replacement: %v", line)
	replacements := map[string]string{
		"one":   "o1e",
		"two":   "t2o",
		"seven": "s7n",
		"eight": "e8t",
	}

	for word, replacement := range replacements {
		line = regexp.MustCompile(word).ReplaceAllString(line, replacement)
	}
	log.Debugf("Line after replacement: %v", line)
```
There are some debug logs in there. You can of course remove them, I used them to validate
what I was doing.


Small issue: this way we will basically not be able to convert to an int, because we have words
and those can't be "just" converted like that. 
So what do we do? Convert, but differently.

```golang
	// Transform words to digits

	// First digit
	switch numbers[0] {
	case "one":
		numbers[0] = "1"
	case "two":
		numbers[0] = "2"
	case "three":
		numbers[0] = "3"
	case "four":
		numbers[0] = "4"
	case "five":
		numbers[0] = "5"
	case "six":
		numbers[0] = "6"
	case "seven":
		numbers[0] = "7"
	case "eight":
		numbers[0] = "8"
	case "nine":
		numbers[0] = "9"
	}

	// Second digit
	switch numbers[1] {
	case "one":
		numbers[1] = "1"
	case "two":
		numbers[1] = "2"
	case "three":
		numbers[1] = "3"
	case "four":
		numbers[1] = "4"
	case "five":
		numbers[1] = "5"
	case "six":
		numbers[1] = "6"
	case "seven":
		numbers[1] = "7"
	case "eight":
		numbers[1] = "8"
	case "nine":
		numbers[1] = "9"
	}
```

That's a pretty lengthy switch case. Basically, checks the first element and then
the second and for each converts a word to a digit.


The rest of the logic stays and that's it. Code is on [GitHub](https://github.com/RiRa12621/advent_of_code23/blob/main/day1/challenge2/main.go) again.

Hope you're also having fun with Advent of Code building your own solution.

