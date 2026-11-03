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

COPY bin/shellcheck .ramekin/bin/mergiraf .ramekin/bin/rex /usr/local/bin/

# lua5.4 + fennel to compile and load-check the Fennel configs (.hammerspoon,
# .config/rex). Rex's init.lua prepends ~/.luarocks/share/lua/5.4/?.lua to its
# embedded Lua's package.path, so link the Debian fennel library there.
RUN apt-get update && apt-get install -y --no-install-recommends \
    lua5.4 fennel && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /root/.luarocks/share/lua/5.4 && \
    ln -s /usr/share/lua/5.4/fennel.lua /root/.luarocks/share/lua/5.4/fennel.lua
