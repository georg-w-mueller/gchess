defmodule Gchess.Tools.StatefulMap do

  def new() do
    case Agent.start_link(fn -> %{} end) do
      {:ok, pid} -> pid
      x -> raise "start_link returned #{IO.inspect(x)}"
    end
  end

  def put(pid, key, value), do:  Agent.update(pid, &Map.put(&1, key, value))

  def save(value, pid, key) do
    put(pid, key, value)
    value
  end

  def get(pid, key), do:  Agent.get(pid, &Map.get(&1, key))

  def stop(pid), do: Agent.stop(pid)
end
