# Dockerfile
FROM debian:bullseye-slim

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV ACCOUNT_USERNAME="" \
    ACCOUNT_PASSWORD="" \
    ACCOUNT_EMAIL=""

# Update and install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    git \
    curl \
    wget \
    openssh-server \
    ca-certificates \
    gnupg \
    gh && \
    rm -rf /var/lib/apt/lists/*

# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set zsh as the default shell
RUN chsh -s /bin/zsh

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo "root:${ACCOUNT_PASSWORD}" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile

# Create a workspace directory and set it as the working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Add a non-root user for development
RUN useradd -m ${ACCOUNT_USERNAME} && echo "${ACCOUNT_USERNAME}:${ACCOUNT_PASSWORD}" | chpasswd && adduser ${ACCOUNT_USERNAME} sudo
USER ${ACCOUNT_USERNAME}

# Expose the SSH port
EXPOSE 22

# Start SSH service and default to Zsh
CMD ["/usr/sbin/sshd", "-D"]
