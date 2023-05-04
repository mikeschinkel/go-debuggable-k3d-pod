package main

import (
	"fmt"
	"time"
)

const (
	DateFormat = "2006-01-02 3:04:05PM"
	DelayTime  = 3
)

// Debug with Go Remote = localhost:8765
func main() {
	fmt.Println("Starting Debuggable Pod")
	for {
		dt := time.Now().Format(DateFormat)
		fmt.Printf("\n[%s] Hello World!", dt)
		time.Sleep(DelayTime * time.Second)
	}
}
