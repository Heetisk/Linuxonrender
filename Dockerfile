FROM ubuntu:22.04

# Avoid prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install ttyd + useful tools
RUN apt-get update && apt-get install -y \
    ttyd \
    bash \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    python3 \
    python3-pip \
    build-essential \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for the terminal session
RUN useradd -ms /bin/bash termuser && \
    echo "termuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/termuser

# Copy welcome script
COPY welcome.sh /etc/profile.d/welcome.sh
RUN chmod +x /etc/profile.d/welcome.sh

USER termuser

# ttyd listens on PORT env var (Render sets this automatically)
# Falls back to 7681 for local dev
CMD ttyd --port ${PORT:-7681} \
         --writable \
         --base-path / \
         bash --login
