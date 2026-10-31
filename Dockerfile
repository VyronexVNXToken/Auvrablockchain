# Build from a fixed upstream commit; override only after compatibility review.
ARG GO_VERSION=1.25
FROM golang:${GO_VERSION}-bookworm AS builder
ARG BSC_COMMIT=947ba1cb1ef05d4a5f71b738113a3d8b4c16f6b7
RUN apt-get update && apt-get install -y --no-install-recommends git gcc make ca-certificates && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/bnb-chain/bsc.git /src/bsc
WORKDIR /src/bsc
RUN git fetch --no-tags origin "${BSC_COMMIT}" && git checkout --detach "${BSC_COMMIT}" && test "$(git rev-parse HEAD)" = "${BSC_COMMIT}"
ENV CGO_CFLAGS="-O -D__BLST_PORTABLE__"
ENV CGO_CFLAGS_ALLOW="-O -D__BLST_PORTABLE__"
RUN make geth
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* && useradd --system --uid 10001 --home-dir /home/auvra --create-home auvra
COPY --from=builder /src/bsc/build/bin/geth /usr/local/bin/geth
USER 10001:10001
EXPOSE 30303/tcp 30303/udp 8545/tcp 8546/tcp
ENTRYPOINT ["/usr/local/bin/geth"]
CMD ["version"]
