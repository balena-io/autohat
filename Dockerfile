# --- normalize image architectures
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
ARG BALENA_CLI_VERSION=v19.0.15

WORKDIR /opt

RUN install_packages unzip

RUN set -x; arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && wget -q "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && unzip -q "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && rm -rf "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip"


# --- build QEMU and Python venv
FROM qemu-build-${TARGETARCH} AS qemu-build

ARG QEMU_VERSION=8.2.2

WORKDIR /opt

ENV VIRTUAL_ENV=/opt/venv

RUN install_packages \
    libfdt-dev \
    libglib2.0-dev \
    libpixman-1-dev \
    libslirp-dev \
    ninja-build \
    zlib1g-dev

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN wget -q https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz \
    && echo "847346c1b82c1a54b2c38f6edbd85549edeb17430b7d4d3da12620e2962bc4f3  qemu-${QEMU_VERSION}.tar.xz" | sha256sum -c - \
    && tar -xf qemu-${QEMU_VERSION}.tar.xz && cd qemu-${QEMU_VERSION} \
    && ./configure --target-list=x86_64-softmmu --enable-slirp && make -j"$(nproc)" \
    && make install


# --- runtime
FROM run-${TARGETARCH}

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="${VIRTUAL_ENV}/bin:/usr/local/bin:${PATH}"

RUN install_packages \
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
    rsync \
    systemd \
    zlib1g

COPY --from=cli-build /opt/balena-cli /opt/balena-cli
ENV PATH="/opt/balena-cli:${PATH}"

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
