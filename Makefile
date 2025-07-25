TAG ?= latest
IMAGE_NAME ?= quay.io/redhat-ai-dev/feedback-harvester
FULL_NAME = $(IMAGE_NAME):$(TAG)
PLATFORM ?= linux/amd64


.PHONY: deploy-postgres
deploy-postgres: 
	bash ./scripts/setup-postgres.sh

.PHONY: deploy-harvester
deploy-harvester:
	bash ./scripts/setup-harvester.sh

.PHONY: deploy-sidecar
deploy-sidecar: 
	bash ./scripts/setup-sidecar.sh

.PHONY: generate-resources
generate-resources: 
	bash ./scripts/generate-resources.sh

.PHONY: build-harvester
build-harvester: 
	podman build --platform=$(PLATFORM) -t $(FULL_NAME) -f src/harvester/Containerfile

.PHONY: remove-sidecar
remove-sidecar:
	bash ./scripts/remove-sidecar.sh

.PHONY: remove-harvester
remove-harvester:
	bash ./scripts/remove-harvester.sh

.PHONY: remove-postgres
remove-postgres:
	bash ./scripts/remove-postgres.sh

.PHONY: remove-all
remove-all: remove-harvester remove-postgres remove-sidecar