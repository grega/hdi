.PHONY: build test lint clean

BINARY := hdi

build:
	go build -o $(BINARY) ./cmd/hdi/

test:
	go test ./... -count=1

lint:
	golangci-lint run ./...

clean:
	rm -f $(BINARY)
