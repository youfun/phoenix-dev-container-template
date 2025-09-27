#!/bin/bash
# Strict mode
# set -e ensures the script exits immediately if any command fails.
set -e

# Wait for the database service to fully start
# Here we simply sleep; in production, use a more robust wait-for-it.sh script
echo "Waiting for postgres..."
sleep 5

# This ensures all dependencies are pulled and locked before running any mix tasks.
if [ ! -f "mix.lock" ]; then
  echo "mix.lock not found. Running mix deps.get..."
  mix deps.get
else
  echo "mix.lock found. Skipping mix deps.get."
fi

# If the database doesn't exist, create it. If your project doesn't need a database, comment out this line
# mix ecto.create checks if the database exists and won't re-execute if it does
echo "Creating database if it doesn't exist..."
mix ecto.create

# Run database migrations. If your project doesn't need a database, comment out this line
echo "Running database migrations..."
mix ecto.migrate

# Execute any commands passed to the script (e.g., CMD ["phx.server"] in docker-compose.yml)
# "$@" passes all arguments to the script unchanged to the mix command.
echo "Starting the application..."
exec mix "$@"