FROM alpine:3.3

# Expose the default UDP input port and HTTP output port (respectively)
EXPOSE 8126
EXPOSE 8080

# Install system runtime dependencies
RUN apk add --update erlang erlang-crypto erlang-sasl erlang-erl-interface

# Install system build dependencies
RUN apk add --update -t build-deps erlang-syntax-tools erlang-eunit elixir && \
    mix do local.hex --force, hex.info, local.rebar

# Copy the source files into a temporary source directory
COPY mix.exs lib config rel/relx.config \
     /opt/promenade/src/
WORKDIR /opt/promenade/src

# Build release and move it to the outer directory
RUN env MIX_ENV=prod mix do deps.get, compile, release --no-confirm-missing && \
    mv rel/promenade/* ..

# Delete source directory and build dependencies (including elixir)
RUN rm -rf /opt/promenade/src && \
    apk del --purge build-deps && \
    rm -rf /var/cache/apk/* ~/.mix ~/.hex

# Ready to roll
WORKDIR /opt/promenade
CMD bin/promenade foreground
