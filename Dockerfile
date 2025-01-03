# Dockerfile
FROM debian:bullseye-slim

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Update and install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    git \
    curl \
    wget \
    openssh-server \
    ca-certificates \
    gnupg

# Install GitHub CLI
RUN (type -p wget >/dev/null || (apt-get update && apt-get install wget -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y

# Install pkgs for rust, nodejs, python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    libsqlite3-dev \
    libmariadb-dev

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip

# clean up installation bloats
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set zsh as the default shell
RUN chsh -s /bin/zsh

# Set the default user
ENV ACCOUNT_PASSWORD=password

# Configure SSH
# Configure SSH
RUN mkdir -p /var/run/sshd && \
    chmod 0755 /var/run/sshd

RUN echo "root:${ACCOUNT_PASSWORD}" | chpasswd

RUN ssh-keygen -A

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

RUN echo "export VISIBLE=now" >> /etc/profile

# Create a workspace directory and set it as the working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Expose the SSH port
EXPOSE 22

# Start SSH service and default to Zsh
CMD ["/usr/sbin/sshd", "-D"]
