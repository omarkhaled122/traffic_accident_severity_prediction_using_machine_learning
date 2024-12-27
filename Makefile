.PHONY: clean data lint requirements sync_data_to_s3 sync_data_from_s3

#################################################################################
# GLOBALS                                                                       #
#################################################################################

ifeq (,$(wildcard config))
$(warning config file not found)
else
$(info Loading environment variables from config file)
include config
endif

ifneq (,$(wildcard .env))
$(info Loading environment variables from .env. Some commands will still need you to `export `dotenv list``)
include .env
endif

ifeq (,$(shell which python3))
PYTHON_INTERPRETER=python
else
PYTHON_INTERPRETER=python3
endif

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

ifeq (,$(shell which pip3))
PIP=pip
else
PIP=pip3
endif

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Install Python Dependencies
requirements: test_environment
	$(PIP) install -r requirements.txt

## Delete all compiled Python files
clean:
	find . -name "*.pyc" -exec rm {} \;

## Lint using flake8
lint:
	flake8 --exclude=lib/,bin/,docs/conf.py .

## Upload Data to S3
sync_data_to_s3:
	aws s3 sync data/ s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/data/ --exclude '*' --include '*$(DATA_VARIANT)*'
	aws s3 sync models/ s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/models/  --exclude '*' --include '*$(DATA_VARIANT)*'
	aws s3 sync features/ s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/features/  --exclude '*' --include '*$(DATA_VARIANT)*'

## Download Data from S3
sync_data_from_s3:
	aws s3 sync s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/data/ data/ --exclude '*' --include '*$(DATA_VARIANT)*'
	aws s3 sync s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/models/ models/ --exclude '*' --include '*$(DATA_VARIANT)*'
	aws s3 sync s3://$(S3_BUCKET)/$(ENVIRONMENT)/$(PROJECT_NAME)/features/ features/ --exclude '*' --include '*$(DATA_VARIANT)*'

## Set up python interpreter environment
create_environment:
ifeq (True,$(HAS_CONDA))
		@echo ">>> Detected conda, creating conda environment."
ifeq (3,$(findstring 3,$(PYTHON_INTERPRETER)))
	conda create --name $(PROJECT_NAME) python=3 pip
else
	conda create --name $(PROJECT_NAME) python=2.7 pip
endif
		@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
else
	$(PIP) install -q virtualenv
	$(PYTHON_INTERPRETER) -m venv env
	@echo ">>> New virtualenv created. Activate with:\n\tsource env/bin/activate"
endif

## Test python environment is setup correctly
test_environment:
	$(PYTHON_INTERPRETER) test_environment.py

#################################################################################
# DOCKER                                                                        #
#################################################################################

CODE_VERSION ?= $(shell git rev-parse --short HEAD)
VERSION = $(DATA_VERSION).$(CODE_VERSION)

.PHONY: docker-model docker-app docker-push docker-model-run docker-app-run

## Make docker image for model training
docker-model: Dockerfile
	docker build . -f Dockerfile -t '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:$(VERSION)'
	docker tag '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:$(VERSION)' '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:latest'

## Make docker image for Kingsman API
docker-app: Dockerfile-app
	docker build . -f Dockerfile-app -t '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:$(VERSION)' --build-arg APP_PORT=$(APP_PORT)
	docker tag '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:$(VERSION)' '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:latest'

## Push docker images to registry
docker-push: docker-model docker-app
	docker push '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:$(VERSION)'
	docker push '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:latest'
	docker push '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:$(VERSION)'
	docker push '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:latest'

## > Run docker image for model training
docker-model-run:
	docker run --env-file .env -ti '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-model:latest'

## > Run docker image for Kingsman API
docker-app-run:
	docker run --env-file .env -p '$(APP_PORT):$(APP_PORT)' -ti '$(DOCKER_REGISTRY)/$(PROJECT_NAME)-app:latest'

#################################################################################
# DATA PIPELINE                                                                 #
#################################################################################

# Filename definitions are in the config file.

.PHONY: data train visualize report app test

## Make dataset
data: $(DATASET)

## Train model
train: $(MODEL)

## Make visualizations
visualize: $(VISUALIZATIONS)

## Make report
report: $(TEST_REPORT)

## Run REST API
app: $(MODEL)
	MODEL=$(MODEL) FEATURE_EXTRACTOR=$(FEATURE_EXTRACTOR) $(PYTHON_INTERPRETER) src/app.py

## Runs the tests
test:
	MODEL=$(MODEL) FEATURE_EXTRACTOR=$(FEATURE_EXTRACTOR) pytest --flake8 --isort --cov=src --ignore=docs

# SQL is used as an example
$(DATASET): $(SQL)
	$(PYTHON_INTERPRETER) src/cli.py -v make_dataset $(SQL) $(DATASET)

$(TRAINSET) $(TESTSET): $(DATASET)
	$(PYTHON_INTERPRETER) src/cli.py -v split_dataset $(DATASET) $(TRAINSET) $(TESTSET)

$(FEATURE_EXTRACTOR): $(DATASET)
	$(PYTHON_INTERPRETER) src/cli.py -v build_features $(DATASET) $(FEATURE_EXTRACTOR)

# Model will be trained on the entire dataset, whilst train and test sets are used for evaluation
$(MODEL): $(DATASET) $(FEATURE_EXTRACTOR)
	$(PYTHON_INTERPRETER) src/cli.py -v train_model $(DATASET) $(FEATURE_EXTRACTOR) $(MODEL)

$(MODEL_EVAL): $(TRAINSET) $(FEATURE_EXTRACTOR)
	$(PYTHON_INTERPRETER) src/cli.py -v train_model $(TRAINSET) $(FEATURE_EXTRACTOR) $(MODEL_EVAL)

$(VISUALIZATIONS): $(DATASET)
	$(PYTHON_INTERPRETER) src/cli.py -v visualize_data $(DATASET) $(VISUALIZATIONS)

$(TEST_REPORT) $(TEST_PREDICTIONS): $(MODEL_EVAL) $(FEATURE_EXTRACTOR) $(TESTSET)
	$(PYTHON_INTERPRETER) src/cli.py -v test_model $(MODEL_EVAL) $(FEATURE_EXTRACTORS) $(TESTSET) $(TEST_REPORT) $(TEST_PREDICTIONS)

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := show-help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
