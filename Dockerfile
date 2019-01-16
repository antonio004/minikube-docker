FROM debian:stretch

# Install minikube dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
  DEBIAN_FRONTEND=noninteractive apt-get -yy -q --no-install-recommends install \
  iptables \
  ebtables \
  ethtool \
  ca-certificates \
  conntrack \
  socat \
  git \
  nfs-common \
  glusterfs-client \
  cifs-utils \
  apt-transport-https \
  ca-certificates \
  openvswitch-switch \
  python3-pip \
  curl \
  gnupg2 \
  software-properties-common \
  bridge-utils \
  ipcalc \
  aufs-tools \
  sudo \
  && DEBIAN_FRONTEND=noninteractive apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install VsdnEmul
RUN \
git clone https://github.com/fernnf/vsdnemul

# Install docker
RUN \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  apt-key export "9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88" | gpg - && \
  echo "deb [arch=amd64] https://download.docker.com/linux/debian jessie stable" >> \
    /etc/apt/sources.list.d/docker.list && \
  DEBIAN_FRONTEND=noninteractive apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -yy -q --no-install-recommends install \
    docker-ce \
  && DEBIAN_FRONTEND=noninteractive apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
VOLUME /var/lib/docker
EXPOSE 2375

# Install minikube
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.24.1/minikube-linux-amd64 && chmod +x minikube
ENV MINIKUBE_WANTUPDATENOTIFICATION=false
ENV MINIKUBE_WANTREPORTERRORPROMPT=false
ENV CHANGE_MINIKUBE_NONE_USER=true
# minikube --vm-driver=none checks systemctl before starting.  Instead of
# setting up a real systemd environment, install this shim to tell minikube
# what it wants to know: localkube isn't started yet.
COPY fake-systemctl.sh /usr/local/bin/systemctl
EXPOSE 8443

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.1/bin/linux/amd64/kubectl && \
  chmod a+x kubectl && \
  mv kubectl /usr/local/bin

# Copy local start.sh
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# ---%<--- @jglick added:
ADD https://storage.googleapis.com/minikube/k8sReleases/v1.8.0/localkube-linux-amd64 /usr/local/bin/localkube
RUN mkdir -p /root/.minikube/cache/localkube
RUN cp /usr/local/bin/localkube /root/.minikube/cache/localkube/localkube-v1.8.0
RUN echo 546bd1980d0ea7424a21fc7ff3d7a8afd7809cefd362546d40f19a40d805f553 > /root/.minikube/cache/localkube/localkube-v1.8.0.sha256
# --->%---

# If nothing else specified, start up docker and kubernetes.
CMD /start.sh & sleep 4 && tail -F /var/log/docker.log /var/log/dind.log /var/log/minikube-start.log