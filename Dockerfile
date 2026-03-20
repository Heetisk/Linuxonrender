FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Install all tools ────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    ttyd \
    openssh-server \
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
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ── Install Node.js 20 LTS ───────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ── Configure SSH ────────────────────────────────────────────────────
RUN mkdir /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "AllowUsers termuser" >> /etc/ssh/sshd_config

# ── Create user with sudo access ─────────────────────────────────────
RUN useradd -ms /bin/bash termuser && \
    echo "termuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── Copy scripts ─────────────────────────────────────────────────────
COPY welcome.sh /etc/profile.d/welcome.sh
COPY start.sh /start.sh
RUN chmod +x /etc/profile.d/welcome.sh /start.sh

WORKDIR /home/termuser

# Run as root so sshd can start
CMD ["/start.sh"]
