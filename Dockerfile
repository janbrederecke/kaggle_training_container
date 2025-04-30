FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libglib2.0-0 \
    python3.10 \
    python3-pip \
    openssh-server \
    unzip \
    sudo

# Clean up unnecessary files to reduce image size
RUN apt clean && rm -rf /var/lib/apt/lists/*

# Install PyTorch and related packages
RUN pip3 --no-cache-dir install torch torchvision torchaudio pytorch-lightning

# Install MyPy and Ruff
RUN pip3 --no-cache-dir install mypy ruff

# Install Kaggle API and MLflow
RUN pip3 --no-cache-dir install kaggle mlflow-skinny

# Create a non-root user
RUN useradd -m kaggle
RUN adduser kaggle sudo

# Set bash as the default shell for the kaggle user
RUN chsh -s /bin/bash kaggle

# Set up SSH for the non-root user
RUN mkdir -p /home/kaggle/.ssh && \
    chown kaggle:kaggle /home/kaggle/.ssh && \
    chmod 700 /home/kaggle/.ssh

# Add your public key to the authorized_keys file
COPY id_rsa.pub /home/kaggle/.ssh/authorized_keys
RUN chown kaggle:kaggle /home/kaggle/.ssh/authorized_keys && \
    chmod 600 /home/kaggle/.ssh/authorized_keys

# Allow the non-root user to use sudo without a password
RUN echo "kaggle ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH to disallow root login and password authentication
RUN sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create the /run/sshd directory
RUN mkdir -p /run/sshd

# Expose SSH port
EXPOSE 22

# Start SSH on container launch
CMD ["/usr/sbin/sshd", "-D"]