# Pinned base image for reproducible builds.
FROM debian:bookworm-slim

LABEL name="shellcheck-action" \
      maintainer="pataraco@gmail.com" \
      version="1.0.0" \
      description="Run ShellCheck on ALL shell files in the repository"

# Pin ShellCheck to a specific release (static binary — avoids apt package drift,
# and keeps the image small/fast). Bump this ARG to upgrade.
ARG SHELLCHECK_VERSION=v0.10.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl xz-utils; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
       amd64) sc_arch="x86_64" ;; \
       arm64) sc_arch="aarch64" ;; \
       *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.${sc_arch}.tar.xz"; \
    curl -fsSL "$url" -o /tmp/shellcheck.tar.xz; \
    tar -xJf /tmp/shellcheck.tar.xz -C /tmp; \
    install -m 0755 "/tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck; \
    rm -rf /tmp/shellcheck.tar.xz "/tmp/shellcheck-${SHELLCHECK_VERSION}"; \
    apt-get purge -y --auto-remove curl xz-utils; \
    rm -rf /var/lib/apt/lists/*; \
    shellcheck --version

COPY run-action.sh /run-action.sh
RUN chmod +x /run-action.sh

ENTRYPOINT ["/run-action.sh"]
