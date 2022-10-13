defmodule AccountDynamicSupervisor do
  use DynamicSupervisor

  @registry_name :account_main_registry

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 4, max_seconds: 5)
  end

  def find_or_create_process(account_id) when is_integer(account_id) do
    if account_process_exists?(account_id) do
      {:ok, account_id}
    else
      account_id |> start_child
    end
  end

  def account_process_exists?(account_id) when is_integer(account_id) do
    case Registry.lookup(@registry_name, account_id) do
      [] -> false
      _ -> true
    end
  end

  def account_ids do
    which_children
    |> Enum.map(fn {_, account_proc_pid, _, _} ->
      Registry.keys(@registry_name, account_proc_pid)
      |> List.first
    end)
    |> Enum.sort
  end

  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def start_child(account_id) do
    #Ejemplo para agregar stack:
    #{:ok, pid} = AccountDynamicSupervisor.start_child(1)
    spec = {Account, {account_id} }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end