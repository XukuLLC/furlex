defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """

  require Logger

  alias Furlex.Oembed

  @json_library Application.get_env(:furlex, :json_library, Jason)
  @timeout Application.get_env(:furlex, :timeout, 30_000)

  use Tesla

  plug(Tesla.Middleware.Timeout, timeout: @timeout)
  plug(Tesla.Middleware.FollowRedirects)

  @doc """
  Fetches a url and extracts the body
  """
  @spec fetch(String.t(), List.t()) :: {:ok, String.t(), Integer.t()} | {:error, Atom.t()}
  def fetch(url, opts \\ []) do
    opts = Keyword.merge(opts, adapter: [timeout: timeout(opts)])

    case get(url, opts: opts) do
      {:ok, %{body: body, status: status_code}} -> {:ok, body, status_code}
      other -> other
    end
  end

  defp timeout(opts) do
    if timeout_from_opts = Keyword.get(opts, :timeout) do
      timeout_from_opts
    else
      @timeout
    end
  end

  @doc """
  Fetches oembed data for the given url
  """
  @spec fetch_oembed(String.t(), List.t()) :: {:ok, String.t()} | {:ok, nil} | {:error, Atom.t()}
  def fetch_oembed(url, opts \\ []) do
    with {:ok, endpoint} <- Oembed.endpoint_from_url(url),
         params = %{"url" => url},
         opts = Keyword.put(opts, :params, params),
         {:ok, response} <- get(endpoint, opts),
         {:ok, body} <- @json_library.decode(response.body) do
      {:ok, body}
    else
      {:error, :no_oembed_provider} ->
        {:ok, nil}

      other ->
        "Could not fetch oembed for #{inspect(url)}: #{inspect(other)}"
        |> Logger.error()

        {:ok, nil}
    end
  end
end
