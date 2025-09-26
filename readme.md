[中文版本](readme_cn.md)

# Development Container Usage Guide

This development container is based on Docker and is used to run the Phoenix application development server in an isolated environment. It includes dependencies such as Elixir, Erlang, and PostgreSQL client, and automatically handles database initialization.

## Prerequisites

- Install Docker and Docker Compose.

## Usage Steps

1. **Enter the development container directory**:
   Open the terminal and navigate to the `dev_container` folder:

2. **Start the container**:
   Use Docker Compose to start the development environment (this will build the image and run the container):
   ```bash
   docker-compose up
   ```
   - On the first run, it will download the base image and install dependencies, which may take a few minutes.
   - The container will automatically wait for PostgreSQL to start, create the database (if it doesn't exist), run migrations, and then start the Phoenix server.

3. **Access the application**:
   - After the server starts, visit `http://localhost:4000` to view the application.
   - If you need to stop, press `Ctrl+C`.

4. **Rebuild the container**:
   If you modified `Dockerfile` or `docker-entrypoint.sh`, you need to rebuild the image:
   ```bash
   docker-compose build --no-cache
   ```
   Then restart:
   ```bash
   docker-compose up
   ```

5. **Development workflow**:
   - File changes inside the container will automatically reload (via inotify-tools).
   - If you need to enter the container for debugging, run `docker-compose exec app bash`.

   ### Installing and Using npm Packages
   If your project requires frontend npm dependencies, you can do so by entering the running container. This allows you to manage frontend dependencies directly in the isolated environment without affecting the host environment.

   1. **Enter the running container**:
      ```bash
      docker-compose exec app bash
      ```
      This provides an interactive terminal to "enter" the container for operations.

   2. **Install all npm dependencies for the first time** (if `package.json` exists in `./assets`):
      - After entering the container, switch to the `./assets` directory:
        ```bash
        cd ./assets
        ```
      - Then run `npm install` to install all dependencies:
        ```bash
        npm install
        ```
      - This installs all packages listed in `package.json`.

   3. **Add new npm packages**:
      - If you only need to add a single new package, you can run from the project root (no need for `cd`):
        ```bash
        npm install some-new-package --prefix ./assets
        ```
      - Replace `some-new-package` with the actual package name.
      - After installation, Phoenix will automatically reload the changes without restarting the server.

   4. **Use installed packages**:
      Write JavaScript code in the `./assets` folder using the newly installed packages. Ensure they are properly imported and integrated in `assets/js/app.js`.

6. **Stop and clean up**:
   - Stop the container: `docker-compose down`.
   - Clean up: `docker-compose down --volumes` (deletes the database volume).

## Debugging

The container provides a safe, isolated environment for debugging and experimentation, making it easy to diagnose issues and reset without risk.

### Centralized Diagnostics
When errors occur, all relevant environment information and logs are contained within the container, simplifying quick diagnosis. You can easily access key information such as:
- `docker logs <container_name>`: Retrieve application stdout and stderr logs with a single command.
- `docker exec -it <container_name> /bin/sh`: Enter the container interactively, like operating an independent Linux host. Use `env` to check environment variables, `npm list` or `pip freeze` to check package versions, or `ls -l` to check file status.
- `docker inspect <container_name>`: Get detailed information about the container configuration, including networks, mounted volumes, etc.

### Safe Environment Modification and Reset
Run `docker-compose down && docker-compose up` to recreate the container from a clean original image, immediately resetting all environmental modifications.

## Notes

- Ensure that project files on the host are mapped to the container (via `volumes` in `docker-compose.yml`).
- If you encounter port conflicts, modify the port mappings in `docker-compose.yml`.
- **Database migration tip**: In `docker-entrypoint.sh`, database migrations are commented out (if not needed). If you need to enable them, uncomment the following lines:
  ```bash
  # echo "Running database migrations..."
  # mix ecto.migrate
  ```
  Then rebuild the container.
- **Server binding configuration**: When running a Phoenix app in a Docker container, you need to modify the server IP binding in `config/dev.exs` to allow access from outside the container. By default, Phoenix binds to `127.0.0.1`, which prevents access from the host inside the container. Here's how to modify it:
  1. Open the `config/dev.exs` file in the project root.
  2. Find the `MyAppWeb.Endpoint` configuration section (usually similar to `config :my_app, MyAppWeb.Endpoint,`).
  3. Change `http: [ip: {127, 0, 0, 1}, port: 4000],` to `http: [ip: {0, 0, 0, 0}, port: 4000],`.
  4. Save the file and restart the container (`docker-compose down && docker-compose up`) to apply the changes.

For more details, refer to `docker-compose.yml` and `Dockerfile`.

## Developing Multiple Phoenix Projects Simultaneously

If developing multiple Phoenix projects on the same machine using the same `docker-compose.yml` template, the following parameters need to be modified to avoid conflicts (such as duplicate container names, port occupation, data isolation, etc.). Assuming each project has its own directory (e.g., `project1`, `project2`), you can copy the template and adjust accordingly.

### Parameters to Modify

- **container_name (Container Name)**:
  Must be changed because Docker container names must be unique on the host. Otherwise, it will error.
  For each project, it is recommended to add a project identifier (such as project name or number).
  Example: For `project1`, change to `container_name: project1_app`; for `project2`, change to `container_name: project2_app`.

- **ports (Port Mapping)**:
  The local port (left side) needs to be changed to avoid conflicts. If multiple projects are running simultaneously, one uses 4000, another uses 4001, etc.
  The container port (right side) usually remains 4000 (Phoenix default) and 5432 (PostgreSQL default).
  Example: For `project1`, keep `ports: - "4000:4000"`; for `project2`, change to `ports: - "4001:4000"`.

- **environment (Environment Variables)**:
  `POSTGRES_DB`: The database name needs to be unique to isolate each project's database.
  Others like `POSTGRES_USER` and `POSTGRES_PASSWORD` can remain the same (if sharing the database service), but for security, it's recommended to make them independent per project.
  Example: For `project1`, keep `POSTGRES_DB: conflux_dev`; for `project2`, change to `POSTGRES_DB: project2_dev`.

- **volumes (Volume Definitions)**:
  The named volume `postgres_data` needs to be renamed to avoid multiple projects sharing the same database data.
  If you want complete isolation, define different volume names for each project.
  Example: For `project1`, keep `postgres_data:`; for `project2`, change to `project2_postgres_data:` (and update accordingly in the `volumes` block).

- **Other Optional Modifications**:
  `depends_on`: Usually doesn't need to be changed; it ensures the db starts first.
  If stronger isolation is needed, consider using different networks for each project (add a `networks` block), but it's not necessary by default.
  Ensure the mount paths in `volumes` (`- ../:/app`) point to the correct project root directory.

After modifications, run `docker-compose up` again to apply the changes. Each project's container will run independently, avoiding conflicts.




