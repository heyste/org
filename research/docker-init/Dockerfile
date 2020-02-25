FROM ubuntu:eoan-20200114

ENV KUBEMACS_VERSION=0.0.2 \
    EMACS_VERSION=26.3 \
    DOCKER_VERSION=19.03.5 \
    KIND_VERSION=0.7.0 \
    KUBECTL_VERSION=1.17.2

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y \
  xz-utils \
  sudo \
  curl \
  ca-certificates \
  jq \
  && rm -rf /var/apt/lists/*

# docker client binary
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  | tar --directory=/usr/local/bin --extract --ungzip \
  --strip-components=1 docker/docker

# kind binary
RUN curl -Lo /usr/local/bin/kind \
  https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-$(uname)-amd64 \
  && chmod +x /usr/local/bin/kind

# kubectl binary
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl


RUN mkdir -p /usr/share/kubemacs
ADD kind-cluster-config.yaml kind-cluster+registry.yaml kind-cluster+netboot.yaml kustomization.yaml /usr/share/kubemacs/
ADD manifests /usr/share/kubemacs/manifests
ADD kustomization.yaml /usr/share/kubemacs/manifests

RUN useradd -m -G sudo,users -s /bin/bash -u 2000 ii
COPY bin/* /usr/local/bin/
USER ii

CMD ["simple-init.sh"]
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=5 \
  CMD ["tmate", "-S ", "/tmp/ii.default.target.iisocket", "wait-for", "tmate-ready"] || exit 1
