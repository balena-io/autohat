# --- normalize image architectures
FROM balenalib/aarch64-node:19-bullseye-build AS cli-build-arm64
FROM balenalib/aarch64-python:3-bullseye-build AS qemu-build-arm64
FROM balenalib/aarch64-python:3-bullseye-run AS run-arm64
FROM balenalib/amd64-node:19-bullseye-build AS cli-build-amd64
FROM balenalib/amd64-python:3-bullseye-build AS qemu-build-amd64
FROM balenalib/amd64-python:3-bullseye-run AS run-amd64


# --- build balena-cli
FROM cli-build-${TARGETARCH} AS cli-build

ARG TARGETARCH

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v17.4.2

WORKDIR /opt

RUN install_packages unzip

RUN set -x; arch=$(echo ${TARGETARCH} | sed 's/amd/x/g') \
    && wget -q "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && unzip -q "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && rm -rf "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip"


# --- build QEMU and Python venv
FROM qemu-build-${TARGETARCH} AS qemu-build

ARG QEMU_VERSION=6.2.0

WORKDIR /opt

ENV VIRTUAL_ENV=/opt/venv

RUN install_packages \
    libfdt-dev \
    libglib2.0-dev \
    libpixman-1-dev \
    ninja-build \
    zlib1g-dev

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN wget -q https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz \
    && echo "68e15d8e45ac56326e0b9a4afa8b49a3dfe8aba3488221d098c84698bca65b45  qemu-${QEMU_VERSION}.tar.xz" | sha256sum -c - \
    && tar -xf qemu-${QEMU_VERSION}.tar.xz && cd qemu-${QEMU_VERSION} \
    && ./configure --target-list=x86_64-softmmu && make -j"$(nproc)" \
    && make install


# --- runtime
FROM run-${TARGETARCH}

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="${VIRTUAL_ENV}/bin:/usr/local/bin:${PATH}"

RUN install_packages \
    git \
    openssh-client \
    rsync \
    minicom \
    systemd \
    libxml2 \
    libpixman-1-0 \
    libpng16-16 \
    libjpeg62-turbo \
    libglib2.0-0 \
    libfdt1 \
    ovmf \
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
