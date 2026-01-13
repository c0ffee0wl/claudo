FROM ubuntu:24.04

ARG BUILD_TIME
LABEL org.opencontainers.image.created="${BUILD_TIME}"

# Add Docker repository for docker-ce-cli
RUN apt-get update && apt-get install -y ca-certificates curl \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    docker-ce-cli \
    iptables \
    curl \
    direnv \
    dnsutils \
    fd-find \
    file \
    fzf \
    git \
    gnupg \
    iputils-ping \
    jq \
    make \
    nano \
    ripgrep \
    sudo \
    tree \
    unzip \
    wget \
    xxd \
    zsh \
    # Required for claude to be installed
    libatomic1 \
    # Python virtual environment support
    python3-venv \
    # Document processing dependencies
    python3-reportlab \
    python3-pandas \
    python3-defusedxml \
    python3-openpyxl \
    python3-lxml \
    python3-pil \
    python3-six \
    python3-yaml \
    pandoc \
    poppler-utils \
    qpdf \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS for MCP plugins
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && groupadd -g 1000 claudo \
    && useradd -m -u 1000 -g 1000 -s /bin/zsh claudo \
    && groupadd -g 999 docker \
    && usermod -aG docker claudo \
    && echo "claudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claudo \
    && chmod 0440 /etc/sudoers.d/claudo

ENV HOSTNAME=claudo
ENV TERM=xterm-256color
ENV CLAUDE_CONFIG_DIR=/claude-config
ENV BUILD_TIME="${BUILD_TIME}"

USER claudo
WORKDIR /home/claudo
ENV PATH="/home/claudo/.local/bin:$PATH"

# Create /workspaces/tmp for --tmp mode and /claude-config for config with correct ownership
USER root
RUN mkdir -p /workspaces/tmp /claude-config && chown claudo:claudo /workspaces/tmp /claude-config
USER claudo

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python packages not available in repos (needs root for --system)
USER root

RUN /home/claudo/.local/bin/uv pip install --system --break-system-packages \
    pypdf pdfplumber pytesseract pdf2image python-pptx python-docx

# Install markdownlint globally
RUN npm install -g markdownlint-cli2

USER claudo

# Install markitdown CLI tool
RUN /home/claudo/.local/bin/uv tool install "markitdown[pptx]"

# Install Claude Code (ARG reference busts cache to get latest version)
ARG BUILD_TIME
RUN curl -fsSL https://claude.ai/install.sh | bash

# Create symlink for fd (Ubuntu installs it as fdfind)
RUN mkdir -p /home/claudo/.local/bin && ln -s $(which fdfind) /home/claudo/.local/bin/fd

COPY --chown=claudo:claudo entrypoint.sh /home/claudo/.local/bin/entrypoint.sh
RUN chmod +x /home/claudo/.local/bin/entrypoint.sh

ENTRYPOINT ["/home/claudo/.local/bin/entrypoint.sh"]
