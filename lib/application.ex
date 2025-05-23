defmodule IASCRegistry.Application do
  # See https://hexdocs.pm/elixir/1.18/Application.html
  # for more information on OTP Applications

  @moduledoc false
  use Application

  @registry_name :account_main_registry

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      %{id: AccountDynamicSupervisor, start: {AccountDynamicSupervisor, :start_link, [[]]} },
      # https://hexdocs.pm/elixir/1.18/Registry.html
      {Registry, [keys: :unique, name: @registry_name]}
    ]

    # See https://hexdocs.pm/elixir/1.18/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IASCRegistry.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
