# --- build balena-cli
ARG ARCH=amd64

FROM balenalib/${ARCH}-node:16-bullseye-build AS cli-build

ARG BALENA_CLI_VERSION=12.48.15

WORKDIR /opt

RUN install_packages unzip

RUN wget -q "https://github.com/balena-io/balena-cli/releases/download/v${BALENA_CLI_VERSION}/balena-cli-v${BALENA_CLI_VERSION}-linux-x64-standalone.zip" \
    && unzip -q "balena-cli-v${BALENA_CLI_VERSION}-linux-x64-standalone.zip" \
    && rm -rf "balena-cli-v${BALENA_CLI_VERSION}-linux-x64-standalone.zip"


# --- build QEMU and Python venv
ARG ARCH=amd64

FROM balenalib/${ARCH}-python:3.8-bullseye-build AS qemu-build

ARG QEMU_VERSION=6.1.0

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
    && echo "eebc089db3414bbeedf1e464beda0a7515aad30f73261abc246c9b27503a3c96  qemu-${QEMU_VERSION}.tar.xz" | sha256sum -c - \
    && tar -xf qemu-${QEMU_VERSION}.tar.xz && cd qemu-${QEMU_VERSION} \
    && ./configure --target-list=x86_64-softmmu && make -j"$(nproc)" \
    && make install


# --- runtime
ARG ARCH=amd64

FROM balenalib/${ARCH}-python:3.8-bullseye-run

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
    zlib1g

COPY --from=cli-build /opt/balena-cli /opt/balena-cli
ENV PATH="/opt/balena-cli:${PATH}"

COPY --from=qemu-build /opt/venv /opt/venv
COPY --from=qemu-build /usr/lib/python3 /usr/lib/python3
COPY --from=qemu-build /usr/local /usr/local

ADD fixtures/ssh_config /root/.ssh/config

ADD udev_rules/autohat.rules /etc/udev/rules.d/

ADD services/dev2.mount /etc/systemd/system/

RUN systemctl enable dev2.mount

RUN chmod 400 /root/.ssh/*

CMD ["/bin/bash"]
