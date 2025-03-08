# Makefile for building and managing the Docker container

# Include environment variables from config.env
include config.env
export $(shell sed 's/=.*//' config.env) 

# Build the Docker image
image-build:
	@echo "Building Docker image: $(IMAGE_NAME):$(TAG)..."
	@docker build -t $(IMAGE_NAME):$(TAG) -f $(DOCKERFILE) $(BUILD_DIR)
	@echo "🚀 Docker image $(IMAGE_NAME) with version $(TAG) succesfully built!"

# Remove the Docker image
image-remove:
	@echo "Removing Docker image: $(IMAGE_NAME):$(TAG)..."
	@docker rmi $(IMAGE_NAME) || echo "Image not found, skipping removal."
	@echo "🗑️ Docker image $(IMAGE_NAME) with version $(TAG) succesfully removed!"

# Initialize project: Create repo folder, GitHub repo, push
project-init:
	@echo "🔍 Checking if local repo exists..."
	@if [ -d "$(ROOT_FOLDER)/$(COMPETITION_NAME)/.git" ]; then \
		echo "⚠️ Local repository $(ROOT_FOLDER)/$(COMPETITION_NAME) already exists."; \
		exit 1; \
	fi

	@echo "🔍 Checking if remote repo exists..."
	@if gh repo view "$(COMPETITION_NAME)" > /dev/null 2>&1; then \
		echo "⚠️ Remote repository $(COMPETITION_NAME) already exists on GitHub."; \
		exit 1; \
	fi

	@echo "📁 Creating project folder..."
	@mkdir -p "$(ROOT_FOLDER)/$(COMPETITION_NAME)"
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && git init

	@echo "🚀 Creating GitHub repository..."
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && gh repo create "$(COMPETITION_NAME)" --private --source=.

	@echo "📦 Adding & committing files..."
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && wget https://github.com/$(GITHUB_USER)/$(TEMPLATE_REPO)/archive/refs/heads/main.zip
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && unzip main.zip -d .
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && mv $(TEMPLATE_REPO)-main/* . 2>/dev/null
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && mv $(TEMPLATE_REPO)-main/.gitignore .
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && rm -r $(TEMPLATE_REPO)-main
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && rm main.zip
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && git add .
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && git commit -m "Initial commit"
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && git branch -M main

	@echo "🔗 Setting up remote & pushing to GitHub..."
	@git config --global user.email $(GITHUB_NO_REPLY_MAIL)
	@cd "$(ROOT_FOLDER)/$(COMPETITION_NAME)" && git push -u origin main

	@echo "✅ Project '$(COMPETITION_NAME)' successfully created and pushed to GitHub!"

# Delete local and remote repository (WARNING: Deletes all the code in repo!)
project-remove:
	@read -p "❗ Are you sure you want to delete the local and remote repository '$(COMPETITION_NAME)'? (y/N) " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		echo "🗑️ Deleting remote repository..."; \
		gh repo delete $(GITHUB_USER)/$(COMPETITION_NAME) --yes; \
		echo "🗑️ Deleting local repository..."; \
		rm -rf $(ROOT_FOLDER)/$(COMPETITION_NAME); \
		echo "✅ Deletion complete." \
	else \
		echo "Operation cancelled."; \
	fi

# Run the Docker container in detached mode
container-run:
	@if [ "$$(docker ps -q -f name=$(COMPETITION_NAME))" ]; then \
		echo "Container $(COMPETITION_NAME) is already running."; \
	else \
		echo "Starting container: $(COMPETITION_NAME)..."; \
		docker run --gpus all -d -it \
			--name $(COMPETITION_NAME) \
			--restart always \
			--shm-size=$(SHM_SIZE) \
			--memory=$(MEMORY_LIMIT) \
			--memory-swap=$(SWAP_LIMIT) \
			-v ~/.kaggle:/home/kaggle/.kaggle:ro \
			-v ~/.vscode-server/extensions:/home/kaggle/.vscode-server/extensions \
			-v $(ROOT_FOLDER)/$(COMPETITION_NAME):/home/kaggle/$(COMPETITION_NAME) \
			-p 2222:22 \
			$(IMAGE_NAME):$(TAG); \
	fi
	@docker exec -it $(COMPETITION_NAME) /bin/bash -c "chown -R kaggle:kaggle /home/kaggle/.vscode-server"
	@docker exec -it $(COMPETITION_NAME) /bin/bash -c "chmod -R 700 /home/kaggle/.vscode-server"
	@docker exec -it $(COMPETITION_NAME) /bin/bash -c "echo 'cd /home/kaggle/$(COMPETITION_NAME)' >> /home/kaggle/.bashrc"
	@docker exec -it --user kaggle $(COMPETITION_NAME) /bin/bash -c "git config --global user.name $(GITHUB_USER) && git config --global user.email $(GITHUB_NO_REPLY_MAIL)"
	@echo "🚀 Docker container $(COMPETITION_NAME) is up and running!"

# Stop the running container
container-stop:
	@echo "Stopping container: $(COMPETITION_NAME)..."
	@docker stop $(COMPETITION_NAME) || echo "Container not running, skipping stop."

# Remove the container
container-remove: container-stop
	@echo "🗑️ Removing container: $(COMPETITION_NAME)..."
	@docker rm $(COMPETITION_NAME) || echo "Container not found, skipping removal."

# View container logs
container-logs:
	@echo "Fetching logs for container: $(COMPETITION_NAME)..."
	@docker logs -f $(COMPETITION_NAME)

# Execute an interactive shell inside the container
container-exec:
	@echo "Opening an interactive shell in container: $(COMPETITION_NAME)..."
	@docker exec -it $(COMPETITION_NAME) /bin/bash

# Download the competition data
data-download:
	@echo "Downloading competition data for $(COMPETITION_NAME)..."
	@kaggle competitions download -c $(COMPETITION_NAME) -p $(ROOT_FOLDER)/$(COMPETITION_NAME)/data --force
	@unzip $(ROOT_FOLDER)/$(COMPETITION_NAME)/data/$(COMPETITION_NAME).zip -d $(ROOT_FOLDER)/$(COMPETITION_NAME)/data/
	@rm $(ROOT_FOLDER)/$(COMPETITION_NAME)/data/$(COMPETITION_NAME).zip

# Remove the competition data
data-remove:
	@echo "🗑️ Removing data for $(COMPETITION_NAME)..."
	@rm -rf /root/$(COMPETITION_NAME)/data/*

git-init:
	@echo "Setting up Git configuration inside the container..."
	@docker exec -it $(COMPETITION_NAME) /bin/bash -c "git config --global user.name $(GITHUB_USER) && git config --global user.email $(GITHUB_NO_REPLY_MAIL)"

# Remove unused Docker resources
prune:
	@echo "🗑️ Cleaning up unused Docker resources..."
	@docker system prune -f

# Initiate everything needed to start working on competition at once
competition-init: image-build project-init container-run git-init data-download
	@echo "Set up $(COMPETITION_NAME) competition!"

# Remove everything related to competition at once
competition-remove: container-remove project-remove prune
	@echo "Removing everything related to $(COMPETITION_NAME)..."