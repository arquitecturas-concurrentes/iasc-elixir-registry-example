defmodule RegistrySupervisorWrapper do

  @registry_name :account_main_registry

  def find_or_create_process(account_id) when is_integer(account_id) do
    if account_process_exists?(account_id) do
      # Registry.lookup(:account_main_registry, account_id)
      {:ok, Registry.lookup(@registry_name, account_id) |> List.first |> elem(0) }
    else
      account_id |> AccountDynamicSupervisor.start_child
    end
  end

  def account_process_exists?(account_id) when is_integer(account_id) do
    case Registry.lookup(@registry_name, account_id) do
      [] -> false
      _ -> true
    end
  end

  def account_ids do
    AccountDynamicSupervisor.which_children
    |> Enum.map(fn {_, account_proc_pid, _, _} ->
      Registry.keys(@registry_name, account_proc_pid)
      |> List.first
    end)
    |> Enum.sort
  end
end

#RegistrySupervisorWrapper.find_or_create_process(1)
#RegistrySupervisorWrapper.find_or_create_process(2)
#RegistrySupervisorWrapper.find_or_create_process(3)
#{ok, pid} = RegistrySupervisorWrapper.find_or_create_process(1)