FROM ramekin-agent

RUN apt-get update && apt-get install -y --no-install-recommends \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/facebook/dotslash/releases/download/v0.5.8/dotslash-linux-musl.x86_64.tar.gz \
    | tar xz -C /usr/local/bin dotslash
