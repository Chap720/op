package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"os/signal"
	"runtime/pprof"
	"syscall"
	"time"

	"github.com/urfave/cli/v2"

	"github.com/ethereum-optimism/optimism/cannon/cmd"
)

func main() {
	app := cli.NewApp()
	app.Name = "cannon"
	app.Usage = "MIPS Fault Proof tool"
	app.Description = "MIPS Fault Proof tool"
	app.Commands = []*cli.Command{
		cmd.LoadELFCommand,
		cmd.WitnessCommand,
		cmd.RunCommand,
	}
	ctx, cancel := context.WithCancel(context.Background())

	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		for {
			<-c
			cancel()
			fmt.Println("\r\nExiting...")
		}
	}()

	profile()

	err := app.RunContext(ctx, os.Args)
	if err != nil {
		if errors.Is(err, ctx.Err()) {
			_, _ = fmt.Fprintf(os.Stderr, "command interrupted")
			os.Exit(130)
		} else {
			_, _ = fmt.Fprintf(os.Stderr, "error: %v", err)
			os.Exit(1)
		}
	}
}

func profile() {
	d, _ := os.MkdirTemp("", "")
	fmt.Println("Writing profile to", d)
	go cpuProfile(d)
	go memProfile(d)
}

func memProfile(d string) {
	f, err := os.Create(fmt.Sprintf("%v/mem.profile", d))
	if err != nil {
		log.Fatal("could not create MEM profile: ", err)
	}
	defer func() {
		if err := f.Close(); err != nil {
			log.Fatal("could not close MEM profile: ", err)
		}
	}()
	time.Sleep(40 * time.Minute)
	pprof.WriteHeapProfile(f)
}

func cpuProfile(d string) {
	f, err := os.Create(fmt.Sprintf("%v/cpu.profile", d))
	if err != nil {
		log.Fatal("could not create CPU profile: ", err)
	}
	defer func() {
		if err := f.Close(); err != nil {
			log.Fatal("could not close CPU profile: ", err)
		}
	}()
	if err := pprof.StartCPUProfile(f); err != nil {
		log.Fatal("could not start CPU profile: ", err)
	}
	time.Sleep(40 * time.Minute)
	pprof.StopCPUProfile()
}
