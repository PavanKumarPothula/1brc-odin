package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:time"

main :: proc() {
	inputFile := os.args[1]
	// start := time.now()
	attempt_1(inputFile)
	// duration := time.since(start)

	// fmt.println("Took", time.duration_seconds(duration), "seconds")
}
