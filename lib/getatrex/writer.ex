defmodule Getatrex.Writer do
  use GenServer

  def start_link(filename) do
    GenServer.start_link(__MODULE__, %{filename: filename, file_pointer: nil}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def write(%Getatrex.Message{} = message) do
    
  end

  def write(line) do

  end



end
