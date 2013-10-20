PORT=3000
REPO=docker.o2h.cz/zelena_kuchyne

all: build

build:
	docker build -t $(REPO) -rm .
push:
	docker push $(REPO)
start:
	docker run -p $(PORT):3000 -d $(REPO)
