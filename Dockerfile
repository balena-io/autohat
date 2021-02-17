# build
FROM balenalib/intel-nuc-node:10-stretch-build AS builder

WORKDIR /opt

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential flex bison rsync minicom libftdi-dev python-pip \
      python-setuptools python-wheel systemd && \
      rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv

RUN pip install virtualenv && python -m virtualenv $VIRTUAL_ENV

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt .

# https://github.com/nodejs/node/issues/19348
RUN pip install -r requirements.txt && \
      npm install --global balena-cli@10.17.6

FROM balenalib/intel-nuc-python:3.6-stretch-build AS qemu

RUN apt-get update && apt-get install -y --no-install-recommends \
      ninja-build libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
      valgrind xfslibs-dev && \
      rm -rf /var/lib/apt/lists/*

RUN wget -q https://download.qemu.org/qemu-5.2.0.tar.xz && \
      echo 'cb18d889b628fbe637672b0326789d9b0e3b8027e0445b936537c78549df17bc  qemu-5.2.0.tar.xz' | sha256sum -c - && \
      tar -xf qemu-5.2.0.tar.xz && cd qemu-5.2.0 && \
      ./configure --target-list=x86_64-softmmu && make -j"$(nproc)" && make install

# runtime
FROM balenalib/intel-nuc-node:10-stretch-run

ENV VIRTUAL_ENV=/opt/venv

ENV PATH="$VIRTUAL_ENV/bin:/usr/local/bin:$PATH"

ENV PYTHONHOME=$VIRTUAL_ENV

RUN apt-get update && apt-get install -y --no-install-recommends \
      git openssh-client rsync minicom systemd \
      libxml2 libpixman-1-0 libpng16-16 libjpeg62-turbo \
      libglib2.0-0 libfdt1 zlib1g && \
      rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv

COPY --from=builder /usr/lib/python2.7 /usr/lib/python2.7

COPY --from=builder /usr/local /usr/local

COPY --from=qemu /usr/local /usr/local

ADD fixtures/ssh_config /root/.ssh/config

ADD udev_rules/autohat.rules /etc/udev/rules.d/

ADD services/dev2.mount /etc/systemd/system/

RUN systemctl enable dev2.mount

RUN chmod 400 /root/.ssh/*

CMD ['/bin/bash']
