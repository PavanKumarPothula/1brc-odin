package main

import "core:fmt"
import "core:time"
import "core:slice"

main :: proc() {
    start := time.now()
    result := attempt_1("./data/measurements.txt")   
    duration := time.since(start)

    fmt.println(result)
    fmt.println("Took", time.duration_seconds(duration), "seconds")
}