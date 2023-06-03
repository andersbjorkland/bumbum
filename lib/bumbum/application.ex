defmodule Bumbum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BumbumWeb.Telemetry,
      # Start the Ecto repository
      Bumbum.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bumbum.PubSub},
      # Start Finch
      {Finch, name: Bumbum.Finch},
      # Start the Endpoint (http/https)
      BumbumWeb.Endpoint
      # Start a worker by calling: Bumbum.Worker.start_link(arg)
      # {Bumbum.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bumbum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BumbumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
