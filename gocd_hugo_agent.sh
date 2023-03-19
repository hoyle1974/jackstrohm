#!/bin/bash

docker build . -f Dockerfile.hugo -t hugo
docker tag hugo hugo:latest

if [ "$1" == "deploy" ]
then
	docker tag hugo jstrohm/gocd-agent-hugo:latest
	docker push jstrohm/gocd-agent-hugo:latest
fi
