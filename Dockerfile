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
      npm install --global balena-cli@10.17.6 && \
      wget -q https://download.qemu.org/qemu-4.2.0.tar.xz && \
      echo 'd3481d4108ce211a053ef15be69af1bdd9dde1510fda80d92be0f6c3e98768f0  qemu-4.2.0.tar.xz' | sha256sum -c - && \
      tar -xf qemu-4.2.0.tar.xz && cd qemu-4.2.0 && ./configure && make && make install


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

ADD fixtures/ssh_config /root/.ssh/config

ADD udev_rules/autohat.rules /etc/udev/rules.d/

ADD services/dev2.mount /etc/systemd/system/

RUN systemctl enable dev2.mount

RUN chmod 400 /root/.ssh/*

CMD ['/bin/bash']
