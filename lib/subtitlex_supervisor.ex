defmodule Subtitlex.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def start_child do
    Supervisor.start_child(__MODULE__, [])
  end

  def terminate_child(server) when server |> is_pid do
    Supervisor.terminate_child __MODULE__, server
  end

  def terminate_children do
    children = Supervisor.which_children
    children |> Enum.map(fn({:undefined, pid, :worker, [Subtitlex.Server]}) ->
      pid |> terminate_child
    end)
  end

  def init(:ok) do
    children = [worker(Subtitlex.Server, [])]
    supervise(children, strategy: :simple_one_for_one)
  end
end
