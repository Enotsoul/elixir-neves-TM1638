defmodule Rbmagic.Application do
  use Application
  require Logger
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Logger.debug "Starting the app up:)"
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Blinky, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rbmagic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
