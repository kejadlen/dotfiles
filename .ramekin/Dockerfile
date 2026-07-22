FROM ramekin-agent

RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) DS_ARCH="aarch64" ;; \
        x86_64) DS_ARCH="x86_64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/facebook/dotslash/releases/download/v0.5.8/dotslash-linux-musl.${DS_ARCH}.tar.gz" \
    | tar xz -C /usr/local/bin dotslash

RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) MF_ARCH="aarch64" ;; \
        x86_64) MF_ARCH="x86_64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://codeberg.org/mergiraf/mergiraf/releases/download/v0.18.0/mergiraf_${MF_ARCH}-unknown-linux-gnu.tar.gz" \
    | tar xz -C /usr/local/bin mergiraf

COPY bin/shellcheck /usr/local/bin/shellcheck
