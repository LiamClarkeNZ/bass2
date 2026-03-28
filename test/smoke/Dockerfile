FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    fish \
    python3 \
    curl \
    git \
    ca-certificates \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (SDKMAN refuses to install as root)
RUN useradd -m -s /usr/bin/fish testuser
USER testuser
WORKDIR /home/testuser

# Install SDKMAN
RUN curl -s "https://get.sdkman.io?rcupdate=false" | bash

# Install nvm
ENV NVM_DIR=/home/testuser/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Copy bass2 source
COPY --chown=testuser:testuser functions/ /home/testuser/bass2/functions/
COPY --chown=testuser:testuser test/smoke/ /home/testuser/bass2/test/smoke/

ENTRYPOINT ["fish", "/home/testuser/bass2/test/smoke/smoke_test.fish"]
