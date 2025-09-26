defmodule DevContainerTemplate.Repo do
  use Ecto.Repo,
    otp_app: :dev_container_template,
    adapter: Ecto.Adapters.Postgres
end
