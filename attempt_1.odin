package main

import "core:os"
import "core:fmt"
import "core:math"
import "core:bufio"
import "core:slice"
import "core:testing"
import "core:strings"
import "core:strconv"
import vmem "core:mem/virtual"

attempt_1 := proc(path: string) -> string {


    file, file_error := os.open(path)

    if file_error != 0 {
        fmt.panicf("Could not open a file at path '%s'", path)
    }

    defer os.close(file)

    reader: bufio.Reader
	buffer: [1024]byte
	bufio.reader_init_with_buf(&reader, os.stream_from_handle(file), buffer[:])
    defer bufio.reader_destroy(&reader)

    arena: vmem.Arena
	arena_allocator := vmem.arena_allocator(&arena)

    location_map := map[string]Stats{}

    for {
		line, read_error := bufio.reader_read_string(&reader, '\n', context.allocator)
		if read_error != nil do break
        defer delete(line)

        line = strings.trim_right(line, "\r")
        parts, _ := strings.split(line, ";") 
        defer delete(parts)

        key := strings.clone(parts[0], arena_allocator)
        value, _ := strconv.parse_f32(parts[1])

        seen := key in location_map

        if !seen {
            location_map[key] = Stats{value, value, value, 1}
            continue
        }

        location, _ := location_map[key]
        location.min = math.min(location.min, value)
        location.max = math.max(location.max, value)
        location.sum += value
        location.count += 1

        location_map[key] = location
	}

    entries, ok := slice.map_entries(location_map)
    delete(location_map)

    slice.sort_by(entries, proc(x, y: slice.Map_Entry(string, Stats)) -> bool { return x.key < y.key})

    builder := strings.builder_make()
    strings.write_string(&builder, "{")

    for entry in entries {
        k, v := entry.key, entry.value
        summary := fmt.tprintf("%s=%3.1f/%3.1f/%3.1f", k, v.min, v.max, v.sum / v.count)
        strings.write_string(&builder, summary)
        strings.write_string(&builder, ", ")
    }

    // Remove last ", "
    strings.pop_byte(&builder)
    strings.pop_byte(&builder)

    strings.write_string(&builder, "}")
    result := strings.to_string(builder)
    
    strings.builder_destroy(&builder)
    vmem.arena_destroy(&arena)

    return result
}

Stats :: struct {
    min: f32,
    max: f32,
    sum: f32,
    count: f32,
}


@(test)
attempt_1_test :: proc(t: ^testing.T) {
    out := attempt_1("./data/measurements-1_000.txt")
}