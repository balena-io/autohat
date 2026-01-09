
# --- download balena-cli
FROM alpine:3.23 AS cli-build

ARG TARGETARCH

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v23.2.16

WORKDIR /opt

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# unpacks to /opt/balena
RUN set -x; arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && wget -qO- "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.tar.gz" | tar -xzf -

# --- build Python venv
FROM python:3.14-slim-trixie AS python-build

WORKDIR /opt

ENV VIRTUAL_ENV=/opt/venv

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# --- runtime
FROM python:3.14-slim-trixie AS runtime

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="${VIRTUAL_ENV}/bin:/usr/local/bin:${PATH}"

# renovate: datasource=repology depName=debian_13/qemu-utils versioning=loose
ARG QEMU_VERSION=1:10.0.6+ds-0+deb13u2

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
    qemu-system-arm=${QEMU_VERSION} \
    qemu-system-x86=${QEMU_VERSION} \
    qemu-utils=${QEMU_VERSION} \
    rsync \
    systemd \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=cli-build /opt/balena /opt/balena-cli
ENV PATH="/opt/balena-cli/bin:${PATH}"

COPY --from=python-build /opt/venv /opt/venv

COPY *.robot /opt/

COPY resources/* /opt/resources/

COPY fixtures/ssh_config /root/.ssh/config

RUN chmod 400 /root/.ssh/*

COPY udev_rules/autohat.rules /etc/udev/rules.d/

COPY services/dev2.mount /etc/systemd/system/

RUN systemctl enable dev2.mount

CMD ["/bin/bash"]
