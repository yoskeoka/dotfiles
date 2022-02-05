package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	var x, n int
	fmt.Scan(&x, &n)
	// fmt.Scanln()

	fmt.Println(x, n)
}

var sc = bufio.NewScanner(os.Stdin)

func nextLine() string {
	sc.Split(bufio.ScanLines)
	sc.Scan()
	return sc.Text()
}

func nextInt() int {
	sc.Split(bufio.ScanWords)
	sc.Scan()
	i, e := strconv.Atoi(sc.Text())
	if e != nil {
		panic(e)
	}
	return i
}

const bufSize = 10000000

var rdr = bufio.NewReaderSize(os.Stdin, bufSize)

func readLongLine() string {
	buf := make([]byte, 0, bufSize)
	for {
		l, p, e := rdr.ReadLine()
		if e != nil {
			panic(e)
		}
		buf = append(buf, l...)
		if !p {
			break
		}
	}
	return string(buf)
}
