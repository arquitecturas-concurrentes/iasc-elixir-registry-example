defmodule Account do
  use GenServer
  require Logger

  @account_registry_name :account_main_registry
  @process_lifetime_ms 86_400_000 # 24 hours in milliseconds

  defstruct account_id: 0,
            packages_ordered: 1,
            timer_ref: nil

  @doc """
  Starts a new account process
  """
  # when guard clause to ensure it is an integer
  def start_link(account_id) when is_integer(account_id) do
    GenServer.start_link(__MODULE__, [account_id], name: via_tuple(account_id))
  end

  # child spec
  def child_spec({account_id}) do
    %{id: "account#{account_id}" , start: {__MODULE__, :start_link, [account_id]}, type: :worker, restart: :transient}
  end

  # registry lookup handler
  defp via_tuple(account_id), do: {:via, Registry, {@account_registry_name, account_id}}


  def init([account_id]) do
    send(self(), :init_data)
    send(self(), :set_terminate_timer)

    Logger.info("Process created... Account ID: #{account_id}")

    # Set initial state and return from `init`
    {:ok, %__MODULE__{ account_id: account_id }}
  end

  def handle_call(:get_details, _from, state) do
    response = %{
      id: state.account_id,
      timer_ref: state.timer_ref,
      packages_ordered: state.packages_ordered
    }

    {:reply, response, state}
  end
  
  def handle_call(:get_packages_ordered, _from, %__MODULE__{ packages_ordered: packages_ordered } = state) do
    {:reply, packages_ordered, state}
  end

  def handle_call(:order_package, _from, %__MODULE__{ packages_ordered: packages_ordered } = state) do
    {:reply, :ok, %__MODULE__{ state | packages_ordered: packages_ordered + 1 }}
  end

  def handle_info(:init_data, state = %{account_id: account_id}) do
    updated_state =
      %__MODULE__{ state | packages_ordered: 1 }

    {:noreply, updated_state}
  end

  def handle_info(:set_terminate_timer, %__MODULE__{ timer_ref: nil } = state) do
    updated_state =
      %__MODULE__{ state | timer_ref: Process.send_after(self(), :end_process, @process_lifetime_ms) }

    {:noreply, updated_state}
  end

  def handle_info(:set_terminate_timer, %__MODULE__{ timer_ref: timer_ref } = state) do
    # cancel existing send_after calls
    # https://hexdocs.pm/elixir/1.12/Process.html#cancel_timer/2
    timer_ref |> Process.cancel_timer

    # override timer
    updated_state =
      %__MODULE__{ state | timer_ref: Process.send_after(self(), :end_process, @process_lifetime_ms) }

    {:noreply, updated_state}
  end

  @doc """
  Gracefully end this process
  """
  def handle_info(:end_process, state) do
    Logger.info("Process terminating... Account ID: #{state.account_id}")
    {:stop, :normal, state}
  end

  @doc """
  Return some details (state) for this account process
  """
  def details(account_id) do
    GenServer.call(via_tuple(account_id), :get_details)
  end

  def packages_ordered(account_id) do
    GenServer.call(via_tuple(account_id), :get_packages_ordered)
  end

  def order_package(account_id) do
    GenServer.call(via_tuple(account_id), :order_package)
  end

  @doc """
  Returns the pid for the `account_id` stored in the registry
  """
  def whereis(account_id) do
    case Registry.lookup(@account_registry_name, account_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end
end
