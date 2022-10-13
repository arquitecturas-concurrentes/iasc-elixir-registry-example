defmodule IASCRegistry.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  
  @moduledoc false
  use Application

  @registry_name :account_main_registry

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      %{id: AccountDynamicSupervisor, start: {AccountDynamicSupervisor, :start_link, [[]]} },
      {Registry, [keys: :unique, name: @registry_name]}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IASCRegistry.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
