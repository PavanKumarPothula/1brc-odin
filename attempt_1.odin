package main

import "core:fmt"
import "core:mem/virtual"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:thread"

mmapBuf: []u8
nproc: u8

TempStats :: struct {
	min_temp:    f32,
	max_temp:    f32,
	mean_temp:   f32,
	num_records: u16,
}
CityMapType :: map[string]TempStats

ThreadData :: struct {
	threadID: u8,
	cityMap:  CityMapType,
	isDone:   bool,
}

task :: proc(threadUnit: ^thread.Thread) {
	threadData := (^ThreadData)(threadUnit.data)
	ParserState :: enum {
		cityName,
		cityTemp,
	}

	currentLineNumber: u32 = 0
	toStore := (threadData.threadID == 0)
	currentParserState := ParserState.cityName

	tempCityName: string
	tempBuf: [dynamic]u8
	tempStats: TempStats
	tempCityMap: CityMapType

	// fmt.println("Got mmap of size:", len(mmapBuf))
	for bite, index in mmapBuf {
		// fmt.print(rune(bite))
		switch (bite) {
		case ';':
			{
				switch currentParserState {
				case ParserState.cityName:
					{
						tempCityName = strings.clone_from_bytes(tempBuf[:])
						clear(&tempBuf)
						currentParserState = ParserState.cityTemp
						// fmt.println(tempCityName)
					}
				case ParserState.cityTemp:
					{
						//unreachable
					}
				}
			}
		case '\n':
			{
				if toStore {
					currentTemp, isCasted := strconv.parse_f32(string(tempBuf[:]))
					// currentTemp, floatinCastError := endian.get_f16(tempBuf[:], .Little)
					defer clear(&tempBuf)
					if !isCasted {
						fmt.eprintfln("CannotCast for buf:", tempBuf[:])
						os.exit(1)
					}
					if tempCityName in tempCityMap {
						oldStats := tempCityMap[tempCityName]

						tempCityMap[tempCityName] = TempStats {
							max_temp    = max(currentTemp, oldStats.max_temp),
							min_temp    = min(currentTemp, oldStats.min_temp),
							mean_temp   = (((oldStats.mean_temp / 1 +
										(1 / f32(oldStats.num_records)))) +
								(currentTemp / (f32(oldStats.num_records) + 1))),
							num_records = oldStats.num_records + 1,
						}
					} else {
						tempCityMap[tempCityName] = TempStats {
							mean_temp   = currentTemp,
							max_temp    = currentTemp,
							min_temp    = currentTemp,
							num_records = 1,
						}
					}
					// fmt.println(tempCityName, "::", tempCityMap[tempCityName])
				} else {
					//NotInterestedInThis
				}
				currentLineNumber += 1
				toStore = ((currentLineNumber % u32(nproc)) == u32(threadData.threadID))
				// fmt.println("LineNumber:", currentLineNumber, "toStore", toStore)
				currentParserState = ParserState.cityName
			}
		case:
			{
				append(&tempBuf, bite)
			}
		}
	}

	threadData.cityMap = tempCityMap
	threadData.isDone = true
}
attempt_1 :: proc(inputFile: string) {
	fopenError: virtual.Map_File_Error
	mmapBuf, fopenError = virtual.map_file_from_path(inputFile, {.Read})
	if fopenError != nil {
		fmt.eprintln(fopenError)
		os.exit(1)
	}
	defer virtual.release(raw_data(mmapBuf), len(mmapBuf))
	nproc = cast(u8)os.get_processor_core_count()
	threadHandleArray: [12]^thread.Thread
	threadDataArray: [12]ThreadData
	for tid in 0 ..< nproc {
		threadHandle := thread.create(task, name = "")
		assert(threadHandle != nil)
		threadDataArray[tid] = ThreadData {
			threadID = tid,
			isDone   = false,
		}
		threadHandle.data = &threadDataArray[tid]
		thread.start(threadHandle)
		thread.join(threadHandle)
		threadHandleArray[tid] = threadHandle
	}

	for threadHandle in threadHandleArray {
		thread.destroy(threadHandle)
	}
	numRecords: u32 = 0
	debug := false
	if debug {
		for threadData in threadDataArray {
			fmt.println(
				"threadID:",
				threadData.threadID,
				"cityMapKeySize:",
				len(threadData.cityMap),
				// "citymapData:",
				// threadData.cityMap,
			)
			thisThreadRecords: u32
			for _, v in threadData.cityMap {
				thisThreadRecords += cast(u32)v.num_records
			}
			fmt.printfln("ThisThreadRecords: %d", thisThreadRecords)

			// Iterate through the map keys
			counter: u8
			for key in threadData.cityMap {
				if counter >= 5 {
					break
				}

				fmt.println(key)
				counter += 1
			}

			numRecords += thisThreadRecords

			fmt.println("==================")
		}

		fmt.printfln("TotalRecords: %d", numRecords)
	}
}
