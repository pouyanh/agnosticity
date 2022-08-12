FROM golang:1.18

MAINTAINER Pouyan Heyratpour <pouyan@janstun.com>

RUN  go install -v github.com/codeskyblue/fswatch@latest && \
	go install -v github.com/go-delve/delve/cmd/dlv@latest

ENTRYPOINT $GOPATH/bin/fswatch

RUN apt-get update && \
	apt-get install -y protobuf-compiler golang-golang-x-tools rsync
RUN go install -v github.com/go-swagger/go-swagger/cmd/swagger@latest && \
	go install -v google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
	go install -v github.com/gogo/protobuf/protoc-gen-gofast@latest && \
	go install -v github.com/gogo/protobuf/protoc-gen-gogo@latest && \
	go install -v github.com/gogo/protobuf/protoc-gen-gogofast@latest && \
	go install -v github.com/gogo/protobuf/protoc-gen-gogofaster@latest && \
	go install -v github.com/gogo/protobuf/protoc-gen-gogoslick@latest && \
	go install -v github.com/bold-commerce/protoc-gen-struct-transformer@latest && \
	go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
	go install -v github.com/ronaksoft/rony/cmd/rony@latest

ARG ACCESS_TOKEN
RUN git config --global url."https://${ACCESS_TOKEN}@github.com".insteadOf "https://github.com"
