FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      git \
      curl \
      jq \
      python3 \
      python3-pip \
      ripgrep \
      ca-certificates \
      less \
      procps \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY opencode.json.example /usr/local/share/opencode/opencode.json.example

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
EXPOSE 4096
VOLUME ["/root/.config/opencode", "/workspace"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
