defmodule Appsignal.Tracer do
  alias Appsignal.{Span}

  @nif Application.get_env(:appsignal, :appsignal_tracer_nif, Appsignal.Nif)
  @table :"$appsignal_registry"

  def start_link do
    Agent.start_link(fn -> :ets.new(@table, [:named_table, :public]) end)
  end

  @doc """
  Creates a new span.
  """
  @spec create_span(String.t()) :: Span.t()
  def create_span(name) do
    {:ok, reference} = @nif.create_root_span(name)
    register(%Span{reference: reference})
  end

  @doc """
  Returns the current span.
  """
  @spec current_span() :: Span.t() | nil
  def current_span do
    case :ets.lookup(@table, self()) do
      [{_pid, span} | _] -> span
      [] -> nil
    end
  end

  @doc """
  Closes a span.
  """
  @spec close_span(Span.t() | nil) :: Span.t() | nil
  def close_span(%Span{reference: reference}) do
    :ok = @nif.close_span(reference)
    deregister()
    :ok
  end

  def close_span(nil), do: nil

  defp register(span) do
    :ets.insert(@table, {self(), span})
    span
  end

  defp deregister() do
    :ets.delete(@table, self())
  end
end
