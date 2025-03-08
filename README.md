
---

# Automated Kaggle Project Setup

This repository contains a Makefile to manage Docker containers and GitHub repositories for a new Kaggle competition project.

Moreover, an optional local instance of MLflow is included.

## Necessary Prerequisites

- [Docker-engine](https://docs.docker.com/engine/) installed on your machine.
- [GitHub CLI](https://cli.github.com) installed and configured.
- [Kaggle CLI](https://www.kaggle.com/docs/api) installed and configured.
- Your `id_rsa.pub` is added for [`ssh`](https://linuxhandbook.com/ssh-basics/) access to the container.
- You know how to use a [Makefile](https://opensource.com/article/18/8/what-how-makefile)

## Repository Structure

| **File Name**          | **Description**                              |
|------------------------|----------------------------------------------|
| `config.env`            | Configuration file for the competition setup   |
| `Dockerfile`            | Dockerfile for the Kaggle container           |
| `id_rsa.pub`           | Public ssh key-file (not included in the repo)|
| `Makefile`              | Contains all commands to setup competition   |
| `mlflow`                | Necessary files for a local MLflow setup       |

## Configuration

Make sure to configure the `config.env` file with the necessary environment variables:

| **Variable Name**      | **Description**                       |
|------------------------|---------------------------------------|
| `IMAGE_NAME`           | Name of the Docker image              |
| `TAG`                  | Tag for the Docker image              |
| `DOCKERFILE`           | Path to the Dockerfile                 |
| `BUILD_DIR`            | Directory to build the Docker image   |
| `ROOT_FOLDER`          | Root folder for the project           |
| `COMPETITION_NAME`     | Name of the competition               |
| `GITHUB_USER`          | GitHub username                       |
| `TEMPLATE_REPO`        | Template repository name              |
| `GITHUB_NO_REPLY_MAIL` | No-reply email for GitHub             |
| `SHM_SIZE`             | Shared memory size for Docker         |
| `MEMORY_LIMIT`         | Memory limit for Docker container     |
| `SWAP_LIMIT`           | Swap limit for Docker container       |

## Using the Makefile

### Initialize a New Competition 

```sh
make competition-init
```

Executes a series of commands to set up everything needed to start working on the defined competition. This includes building the Docker image, initializing the project, running the container, setting up Git, and downloading the competition data.

The Kaggle container will restart and run automatically when you restart your workstation.

### Remove Everything Related to a Competition

```sh
make competition-remove
```

Executes a series of commands to remove everything related to the competition. This includes stopping and removing the container, deleting the local and remote project, and cleaning up Docker resources.

## Set Up Local MLflow Server

Navigate to ./mlflow and run the following command to set up a local instance of MLflow.

The MLflow instance and its related database and object-storage will restart and run automatically when you restart your workstation.

```sh
make mlflow-init
```
---
