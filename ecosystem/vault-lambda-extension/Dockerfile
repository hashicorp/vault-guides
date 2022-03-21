#
# Create a build image that installs all the dependencies to create the demo
# function binary.
#
FROM golang:1.16.4 AS build
ENV GOARCH=amd64
ENV GOOS=linux

COPY demo-function/ /go/src/demo-function/
WORKDIR /go/src/demo-function/
RUN go build -ldflags '-s -w' -a -o bin/main main.go

#
# Create the image that contains the demo-function binary and the
# vault-lambda-extension in the required directory.
#
FROM public.ecr.aws/lambda/provided:al2
COPY --from=build /go/src/demo-function/bin/main /main
COPY extensions/vault-lambda-extension /opt/extensions/vault-lambda-extension

ENTRYPOINT [ "/main" ]
