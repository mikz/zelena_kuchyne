PORT=3000
REPO=docker.o2h.cz/zelena_kuchyne
CONTAINER_ID=tmp/docker
OLD=`cat $(CONTAINER_ID)`

all: build

build:
	docker build -t $(REPO) -rm .
push:
	docker push $(REPO)
start:
	docker run -p $(PORT):3000 -d -cidfile=$(CONTAINER_ID) $(REPO)
stop:
	docker stop $(OLD)
	docker rm $(OLD)
	rm $(CONTAINER_ID)

deploy: build stop start
