defmodule Subtitlex.Supervisor do
  use Supervisor

  @moduledoc """
  Supervisor that monitors the Subtitlex.Server processes in case something
  goes wrong.
  """
  
  @doc """
  Starts the supervisor and registers the supervisor-PID.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc """
  Starts a Subtitlex.Server process and adds it to the supervision tree. 
  """
  def start_child do
    Supervisor.start_child(__MODULE__, [])
  end

  @doc """
  Terminates a Subtitlex.Server process.
  """
  def terminate_child(server) when server |> is_pid do
    Supervisor.terminate_child __MODULE__, server
  end

  @doc """
  Terminates all Subtitlex.Server processes.
  """
  def terminate_children do
    children = Supervisor.which_children
    children |> Enum.map(fn({:undefined, pid, :worker, [Subtitlex.Server]}) ->
      pid |> terminate_child
    end)
  end

  @doc false
  def init(:ok) do
    children = [worker(Subtitlex.Server, [])]
    supervise(children, strategy: :simple_one_for_one)
  end
end
