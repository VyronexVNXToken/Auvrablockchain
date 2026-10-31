ARG GO_VERSION=1.24
FROM golang:${GO_VERSION}-bookworm AS builder
ARG BSC_VERSION=v1.8.1
RUN apt-get update && apt-get install -y --no-install-recommends git gcc make ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/bnb-chain/bsc.git /src/bsc
WORKDIR /src/bsc
RUN git fetch --tags origin && git checkout --detach "${BSC_VERSION}"
ENV CGO_CFLAGS="-O -D__BLST_PORTABLE__"
ENV CGO_CFLAGS_ALLOW="-O"
RUN make geth
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* && useradd --system --uid 10001 --home-dir /home/auvra --create-home auvra
COPY --from=builder /src/bsc/build/bin/geth /usr/local/bin/geth
USER 10001:10001
EXPOSE 30303/tcp 30303/udp 8545/tcp 8546/tcp
ENTRYPOINT ["/usr/local/bin/geth"]
CMD ["version"]
