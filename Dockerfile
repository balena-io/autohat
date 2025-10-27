# --- normalize image architectures
# FIXME: migrate off of balenalib images and use custom udev scripts
FROM balenalib/aarch64-node:20-bookworm-build AS cli-build-arm64
FROM balenalib/aarch64-python:3-bookworm-build AS qemu-build-arm64
FROM balenalib/aarch64-python:3-bookworm-run AS run-arm64
FROM balenalib/amd64-node:20-bookworm-build AS cli-build-amd64
FROM balenalib/amd64-python:3-bookworm-build AS qemu-build-amd64
FROM balenalib/amd64-python:3-bookworm-run AS run-amd64


# --- build balena-cli
FROM cli-build-${TARGETARCH} AS cli-build

ARG TARGETARCH

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v22.4.15

WORKDIR /opt

# unpacks to /opt/balena
RUN set -x; arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && wget -qO- "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.tar.gz" | tar -xzf -

# --- build QEMU and Python venv
FROM qemu-build-${TARGETARCH} AS qemu-build

WORKDIR /opt

ENV VIRTUAL_ENV=/opt/venv

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

COPY requirements.txt .

RUN pip install -r requirements.txt

# --- runtime
FROM run-${TARGETARCH}

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="${VIRTUAL_ENV}/bin:/usr/local/bin:${PATH}"

RUN install_packages \
    binutils \
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
    qemu-system-aarch64 \
    qemu-system-x86 \
    qemu-utils \
    rsync \
    systemd \
    zlib1g

COPY --from=cli-build /opt/balena /opt/balena-cli
ENV PATH="/opt/balena-cli/bin:${PATH}"

COPY --from=qemu-build /opt/venv /opt/venv
COPY --from=qemu-build /usr/lib/python3 /usr/lib/python3
COPY --from=qemu-build /usr/local /usr/local

COPY *.robot /opt/

COPY resources/* /opt/resources/

ADD fixtures/ssh_config /root/.ssh/config

ADD udev_rules/autohat.rules /etc/udev/rules.d/

ADD services/dev2.mount /etc/systemd/system/

RUN systemctl enable dev2.mount

RUN chmod 400 /root/.ssh/*

CMD ["/bin/bash"]
