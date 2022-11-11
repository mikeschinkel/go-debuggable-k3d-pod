
.force:

all: install init build deploy

install: .force
	./util.sh install

init:.force
	./util.sh init

build:.force
	./util.sh build-docker

deploy: push-docker apply

tag-docker: .force
	./util.sh tag-docker

push-docker: tag-docker
	./util.sh push-docker

apply:
	./util.sh apply-kubectl

run: build deploy

cli-debug:.force
	./util.sh cli-debug

kill-app:.force
	./util.sh kill-app

standalone-debug: clean-docker create-docker start-docker
	echo "Docker container with debuggable Go app created"

create-docker: .force
	./util.sh create-docker

start-docker: .force
	./util.sh start-docker

clean-docker:
	./util.sh clean-docker

clean: clean-docker
	./util.sh clean-k3d
	./util.sh clean-files

