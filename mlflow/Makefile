# Makefile

# Define the Docker Compose file name
DOCKER_COMPOSE_FILE := compose.yaml

# Target to run Docker Compose
mlflow-init:
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d

# Target to stop Docker Compose
mlflow-remove:
	docker compose -f $(DOCKER_COMPOSE_FILE) down

# Target to view Docker Compose logs
logs:
	docker compose -f $(DOCKER_COMPOSE_FILE) logs
