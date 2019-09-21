.SILENT:
.PHONY: help

PIP = sudo pip3
SUDO = sudo
PY_BIN = python3
QUAY_REPO=quay.io/riotkit/infracheck
PUSH=true

help:
	@grep -E '^[a-zA-Z\-\_0-9\.@]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build_package install unit_test

build_image: ## Build and push (args: PUSH, ARCH, GIT_TAG)
	set -e; DOCKER_TAG="latest-dev-${ARCH}"; \
	\
	if [[ "${GIT_TAG}" != '' ]]; then \
		DOCKER_TAG=${GIT_TAG}-${ARCH}; \
	fi; \
	\
	${SUDO} docker build . -f ./.infrastructure/${ARCH}.Dockerfile -t ${QUAY_REPO}:$${DOCKER_TAG}; \
	${SUDO} docker tag ${QUAY_REPO}:$${DOCKER_TAG} ${QUAY_REPO}:$${DOCKER_TAG}-$$(date '+%Y-%m-%d'); \
	\
	if [[ "${PUSH}" == "true" ]]; then \
		${SUDO} docker push ${QUAY_REPO}:$${DOCKER_TAG}-$$(date '+%Y-%m-%d'); \
		${SUDO} docker push ${QUAY_REPO}:$${DOCKER_TAG}; \
	fi

run_in_container: ## Run server in container (for testing)
	sudo docker kill infracheck || true
	sudo docker run --name infracheck -p 8000:8000 -t --rm quay.io/riotkit/infracheck:latest-dev-x86_64

run_standalone_server: ## Run server (standalone)
	infracheck --server --server-port 8000

run_standalone: ## Run (standalone)
	infracheck

build_package: ## Build
	${SUDO} ${PY_BIN} ./setup.py build

build_docs: ## Build documentation
	cd ./docs && make html

install: build_package ## Install
	${PIP} install -r ./requirements.txt
	${SUDO} ${PY_BIN} ./setup.py install
	which infracheck
	make clean

clean: ## Clean up the local build directory
	${SUDO} rm -rf ./build ./infracheck.egg-info

unit_test: ## Run unit tests
	${PY_BIN} -m unittest discover -s ./tests

coverage: ## Generate code coverage
	coverage run --rcfile=.coveragerc --source . -m unittest discover -s ./tests
