FROM rabbitmq:alpine



ENV RABBITMQ_ERLANG_COOKIE=test \
  RABBITMQ_DEFAULT_USER=guest \
  RABBITMQ_DEFAULT_PASS=guest \
  RABBITMQ_DEFAULT_VHOST=/ \
  RABBITMQ_NODE_PORT=5672 \
  RABBITMQ_DIST_PORT=25672 \
  RABBITMQ_NET_TICKTIME=60 \
  RABBITMQ_CLUSTER_PARTITION_HANDLING=ignore \
  ERL_EPMD_PORT=4369 \
  RABBITMQ_MANAGEMENT_PORT=15672 \
  MARATHON_URI=http://leader.mesos:8080


ENV PACKAGES="\
  musl \
  linux-headers \
  build-base \
  git \
  python2 \
  python2-dev \
  py-setuptools \
"
RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \

  # Add the packages, with a CDN-breakage fallback if needed
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \

  # turn back the clock -- so hacky!
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories \
  # make some useful symlinks that are expected to exist
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
  && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \

  # Install and upgrade Pip
  && easy_install pip \
  && pip install --upgrade pip \
  && easy_install requests \
  && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \
  && echo


RUN chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
ADD ./rabbitmq-cluster.py /rabbitmq-cluster.py
RUN chmod +x /rabbitmq-cluster.py
RUN rabbitmq-plugins enable --offline rabbitmq_management

EXPOSE 15671 15672 4369 5671 5672 25672

ENTRYPOINT ["/rabbitmq-cluster.py"]