# Use the official pre-compiled Elixir and Erlang image as the base
# This greatly speeds up the build of the development environment
FROM hentioe/elixir:1.18.4-otp-28-void
# 1. Install system dependencies
# - build-base: for compiling native extensions
# - postgresql-client: provides psql tools for connecting to the database from within the container
# - inotify-tools: Phoenix live-reload depends on it to monitor file changes
# - git: Elixir depends on git to pull some deps


RUN set -xe \
    && xbps-install -Suy xbps \
    && xbps-install -Suy \
        base-devel \
        postgresql-client \
        inotify-tools \
        git \
        bash \
        openssl \
        nodejs \
    && rm -rf /var/cache/xbps/* \
    && find /var/db/xbps/ -type d -name "https___repo-*" -exec rm -rf {} +

# 2. Install Hex package manager and Phoenix code generator
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new --force

# 3. Set working directory
WORKDIR /app

# 4. Copy dependency definition files
COPY mix.exs ./
COPY mix.loc[k] ./

# 5. Install Elixir dependencies
# This layer uses Docker's layer caching. As long as mix.lock doesn't change, it won't re-run.
RUN mix deps.get 

# 6. Copy entrypoint script and grant execute permissions
# [Change] Copy from dev_container directory
COPY dev_container/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 7. Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# 8. Expose Phoenix default port
EXPOSE 4000

# 9. Default command is to start Phoenix server
# Using `phx.server` instead of `mix phx.server` allows the script to be gracefully terminated (Ctrl+C)
CMD ["phx.server"]

