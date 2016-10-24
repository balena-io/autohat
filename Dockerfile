FROM resin/nuc-node:5.7

# Install PIP, Robot Framework, Resin-cli and Etcher-cli
RUN apt-get update && apt-get install -y qemu-system-x86 rsync qemu-kvm minicom libftdi-dev python-pip && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --upgrade pip && \
    pip install robotframework requests robotframework-requests pylibftdi && \
    npm install --global resin-cli@^5.0.0 && \
    git clone --depth 1  --branch v1.0.0-beta.13 https://github.com/resin-io/etcher.git && cd /etcher && \
    npm install && npm prune --production && \
    ln -sf /etcher/bin/etcher /usr/local/bin/etcher

ADD fixtures/ssh_config /root/.ssh/config

RUN chmod 400 /root/.ssh/*

CMD ['/bin/bash']
