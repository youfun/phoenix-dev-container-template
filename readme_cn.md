[English Version](README.md)

# 开发容器使用说明

这个开发容器基于 Docker，用于在隔离环境中运行 Phoenix 应用开发服务器。它包括 Elixir、Erlang、PostgreSQL 客户端等依赖，并自动处理数据库初始化。

## 前提条件

- 如果您使用的是 Windows，请先从 https://www.docker.com 下载并安装 Docker Desktop。
- 安装 Docker 和 Docker Compose。

## 使用步骤

1. **进入开发容器目录**：
   打开终端，导航到 `dev_container` 文件夹：
  
2. **启动容器**：
   使用 Docker Compose 启动开发环境（这会构建镜像并运行容器）：
   ```bash
   docker-compose up
   ```
   - 首次运行时，会下载基础镜像并安装依赖，可能需要几分钟。
   - 容器会自动等待 PostgreSQL 启动、创建数据库（如果不存在）、运行迁移，然后启动 Phoenix 服务器。

3. **访问应用**：
   - 服务器启动后，访问 `http://localhost:4000` 查看应用。
   - 如果需要停止，按 `Ctrl+C`。

4. **重新构建容器**：
   如果修改了 `Dockerfile` 或 `docker-entrypoint.sh`，需要重新构建镜像：
   ```bash
   docker-compose build --no-cache
   ```
   然后重新启动：
   ```bash
   docker-compose up
   ```

5. **开发工作流**：
   - 容器内文件变化会自动重载（通过 inotify-tools）。
   - 如果需要进入容器调试，运行 `docker-compose exec app bash`。

   ### 安装和使用 npm 包
   如果你的项目需要前端npm依赖,可以通过进入正在运行的容器进行操作。这允许你在隔离环境中直接管理前端依赖，而不会影响主机环境。

   1. **进入正在运行的容器**：
      ```bash
      docker-compose exec app bash
      ```
      这会提供一个交互式终端，让你“走进”容器内部进行操作。

   2. **首次安装所有 npm 依赖**（如果 `./assets` 中有 `package.json`）：
      - 进入容器后，先切换到 `./assets` 目录：
        ```bash
        cd ./assets
        ```
      - 然后运行 `npm install` 来安装所有依赖：
        ```bash
        npm install
        ```
      - 这会安装 `package.json` 中列出的所有包。

   3. **添加新 npm 包**：
      - 如果只需添加单个新包，可以从项目根目录（无需 `cd`）运行：
        ```bash
        npm install some-new-package --prefix ./assets
        ```
      - 替换 `some-new-package` 为实际的包名。
      - 安装完成后，Phoenix 会自动重载更改，无需重启服务器。

   4. **使用已安装的包**：
      在 `./assets` 文件夹中编写 JavaScript 代码，使用新安装的包。确保在 `assets/js/app.js` 中正确导入和集成包。

6. **停止和清理**：
   - 停止容器：`docker-compose down`。
   - 清理：`docker-compose down --volumes`（删除数据库卷）。

## 调试

容器提供了一个安全、隔离的环境，用于调试和实验，使诊断问题变得简单，并且可以轻松重置，避免风险。

### 集中式诊断
当发生错误时，所有相关的环境信息和日志都包含在容器内，简化了快速诊断的过程。你可以轻松访问关键信息，例如：
- `docker logs <container_name>`：通过一个命令检索应用程序的标准输出和错误日志。
- `docker exec -it <container_name> /bin/sh`：以交互方式进入容器，就像操作独立的 Linux 主机一样。使用 `env` 检查环境变量，`npm list` 或 `pip freeze` 检查包版本，或 `ls -l` 检查文件状态。
- `docker inspect <container_name>`：获取有关容器配置的详细信息，包括网络、挂载的卷等。

### 安全的环境修改和重置
运行 `docker-compose down && docker-compose up` 以从干净的原始镜像重新创建容器，立即重置所有环境方面的修改。

## 注意事项

- 确保主机上的项目文件映射到容器（通过 `docker-compose.yml` 中的 `volumes`）。
- 如果遇到端口冲突，修改 `docker-compose.yml` 中的端口映射。
- **数据库迁移提示**：在 `docker-entrypoint.sh` 中，数据库迁移已注释掉（如果不需要运行迁移）。如果需要启用，取消注释以下行：
  ```bash
  # echo "Running database migrations..."
  # mix ecto.migrate
  ```
  然后重新构建容器。
- **服务器绑定配置**：在 Docker 容器中运行 Phoenix 应用时，需要修改 `config/dev.exs` 文件中的服务器 IP 绑定，以允许从容器外部访问。默认情况下，Phoenix 绑定到 `127.0.0.1`，这在容器内会导致无法从主机访问。修改方法如下：
  1. 打开项目根目录下的 `config/dev.exs` 文件。
  2. 找到 `MyAppWeb.Endpoint` 的配置部分（通常类似 `config :my_app, MyAppWeb.Endpoint,`）。
  3. 将 `http: [ip: {127, 0, 0, 1}, port: 4000],` 改为 `http: [ip: {0, 0, 0, 0}, port: 4000],`。
  4. 保存文件后，重启容器（`docker-compose down && docker-compose up`）以应用更改。

更多详情请参考 `docker-compose.yml` 和 `Dockerfile`。

## 同时开发多个 Phoenix 项目

如果在同一台机器上开发多个 Phoenix 项目并使用相同的 `docker-compose.yml` 模板，以下参数需要修改以避免冲突（如容器名重复、端口占用、数据隔离等）。假设每个项目有独立的目录（如 `project1`、`project2`），你可以复制模板并调整。

### 需要修改的参数

- **container_name（容器名称）**：
  必须更改，因为 Docker 容器名称在主机上必须唯一。否则会报错。
  对于每个项目，建议添加项目标识符（如项目名或编号）。
  示例：对于 `project1`，改为 `container_name: project1_app`；对于 `project2`，改为 `container_name: project2_app`。

- **ports（端口映射）**：
  本地端口（左侧）需要更改以避免冲突。如果多个项目同时运行，一个用 4000，另一个用 4001 等。
  容器端口（右侧）通常保持 4000（Phoenix 默认）和 5432（PostgreSQL 默认）。
  示例：对于 `project1`，保持 `ports: - "4000:4000"`；对于 `project2`，改为 `ports: - "4001:4000"`。

- **environment（环境变量）**：
  `POSTGRES_DB`：数据库名需要唯一，以隔离每个项目的数据库。
  其他如 `POSTGRES_USER` 和 `POSTGRES_PASSWORD` 可以保持一致（如果共享数据库服务），但为安全起见，建议每个项目独立。
  示例：对于 `project1`，保持 `POSTGRES_DB: conflux_dev`；对于 `project2`，改为 `POSTGRES_DB: project2_dev`。

- **volumes（卷定义）**：
  命名卷 `postgres_data` 需要重命名，以避免多个项目共享同一数据库数据。
  如果你想完全隔离，可以为每个项目定义不同的卷名。
  示例：对于 `project1`，保持 `postgres_data:`；对于 `project2`，改为 `project2_postgres_data:`（并在 `volumes` 块中相应更新）。

- **其他可选修改**：
  `depends_on`：通常不需要改，它确保 db 先启动。
  如果需要更强的隔离，可以考虑为每个项目使用不同的网络（添加 `networks` 块），但默认情况下不必要。
  确保 `volumes` 下的挂载路径（`- ../:/app`）指向正确的项目根目录。

修改后，重新运行 `docker-compose up` 以应用更改。每个项目的容器将独立运行，避免冲突。
