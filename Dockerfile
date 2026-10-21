
# --- download balena-cli
FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS cli-build

ARG TARGETARCH

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v25.2.7

WORKDIR /opt

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# unpacks to /opt/balena
RUN set -x; arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && wget -qO- "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.tar.gz" | tar -xzf -

# --- build Python venv
FROM python:3.15-slim-trixie@sha256:490c3463f3766091067a01528e6be3208104eebcca11a306beab5de9672ee893 AS python-build

WORKDIR /opt

ENV VIRTUAL_ENV=/opt/venv

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# --- runtime
FROM python:3.15-slim-trixie@sha256:490c3463f3766091067a01528e6be3208104eebcca11a306beab5de9672ee893 AS runtime

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="${VIRTUAL_ENV}/bin:/usr/local/bin:${PATH}"

# Debian keeps only the latest version per suite, so exact apt pins break on
# every point release. The trixie base image bounds qemu to 10.0.x.
# https://packages.debian.org/trixie/qemu-utils
# Fail the build if a base-image change moves qemu to a new major version.
ARG QEMU_MAJOR=10

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    curl \
    fdisk \
    git \
    jq \
    libfdt1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpixman-1-0 \
    libpng16-16 \
    libslirp0 \
    libxml2 \
    minicom \
    openssh-client \
    ovmf \
    qemu-efi-aarch64 \
    qemu-system-arm \
    qemu-system-x86 \
    qemu-utils \
    rsync \
    systemd \
    zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && qemu-system-x86_64 --version | grep "version ${QEMU_MAJOR}\." >/dev/null

COPY --from=cli-build /opt/balena /opt/balena-cli
ENV PATH="/opt/balena-cli/bin:${PATH}"

COPY --from=python-build /opt/venv /opt/venv

COPY resources/* /opt/resources/

COPY fixtures/ssh_config /root/.ssh/config

RUN chmod 400 /root/.ssh/*

COPY udev_rules/autohat.rules /etc/udev/rules.d/

COPY services/dev2.mount /etc/systemd/system/

COPY scripts/extract_persistent_logs.sh /usr/local/bin/

RUN systemctl enable dev2.mount

CMD ["/bin/bash"]
