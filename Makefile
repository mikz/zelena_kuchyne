NAME=zelenakuchyne
DB_PASSWORD=iKvLXhGvKmGZHhVA

REPO=docker.o2h.cz/$(NAME)
START=--env DB_PASSWORD=$(DB_PASSWORD) --link postgres:db

all: build

build:
	docker build -t $(REPO) -rm .

push:
	docker push $(REPO)

run:
	docker run -rm -t -i $(START) $(REPO) $(CMD)

start:
	docker run -d $(START) --name $(NAME) $(REPO)

delete:
	docker stop $(NAME)
	docker rm $(NAME)

deploy: build delete start
