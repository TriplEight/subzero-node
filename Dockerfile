#
#
#

FROM phusion/baseimage:latest-amd64 as builder
LABEL maintainer "marco@one.io"

ARG PROFILE=release

WORKDIR /subzero
COPY . /subzero

## base system
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y curl cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev

## setup toolchain
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH=$PATH:$HOME/.cargo/bin && \
	rustup update nightly && \
	rustup update stable && \
	rustup target add wasm32-unknown-unknown --toolchain nightly

## setup toolchain + build
RUN	$HOME/.cargo/bin/cargo build --$PROFILE

#
#
#

FROM phusion/baseimage:latest-amd64
LABEL maintainer "marco@one.io"
LABEL description="subzero node template"

ARG PROFILE=release

COPY --from=builder /subzero/target/$PROFILE/subzero /usr/local/bin/subzero

RUN mv /usr/share/ca* /tmp && \
	rm -rf /usr/share/*  && \
	mv /tmp/ca-certificates /usr/share/ && \
	rm -rf /usr/lib/python* && \
	useradd -m -u 1000 -U -s /bin/sh -d /subzero subzero && \
	mkdir -p /subzero/.local/share/subzero && \
	chown -R subzero:subzero /subzero/.local && \
	ln -s /subzero/.local/share/subzero /data && \
	rm -rf /usr/bin /usr/sbin

USER subzero
EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/subzero"]
