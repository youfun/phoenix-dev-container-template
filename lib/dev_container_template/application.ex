defmodule DevContainerTemplate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DevContainerTemplateWeb.Telemetry,
      DevContainerTemplate.Repo,
      {DNSCluster, query: Application.get_env(:dev_container_template, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DevContainerTemplate.PubSub},
      # Start a worker by calling: DevContainerTemplate.Worker.start_link(arg)
      # {DevContainerTemplate.Worker, arg},
      # Start to serve requests, typically the last entry
      DevContainerTemplateWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DevContainerTemplate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DevContainerTemplateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
