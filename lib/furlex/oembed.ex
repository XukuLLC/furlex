defmodule Furlex.Oembed do
  @moduledoc """
  A module for managing oembed data
  """

  use GenServer

  require Logger

  @json_library Application.compile_env(:furlex, :json_library, Jason)
  @timeout Application.compile_env(:furlex, :timeout, 30_000)

  @doc """
  Fetches the list of Oembed providers

  Soft fetch will fetch cached providers. Hard fetch requests
  providers from oembed.com and purges the cache.
  """
  @spec fetch_providers(atom()) :: {:ok, list()} | {:error, atom()}
  def fetch_providers(type \\ :soft)

  def fetch_providers(:hard) do
    case Req.get(oembed_url("/providers.json"), req_options()) do
      {:ok, %Req.Response{body: body}} ->
        case decode_json(body) do
          {:ok, providers} ->
            GenServer.cast(__MODULE__, {:providers, providers})
            {:ok, providers}

          other ->
            Logger.error("Could not decode providers: #{inspect(other)}")
            {:error, :fetch_error}
        end

      other ->
        Logger.error("Could not fetch providers: #{inspect(other)}")
        {:error, :fetch_error}
    end
  end

  def fetch_providers(_soft) do
    case GenServer.call(__MODULE__, :providers) do
      nil -> fetch_providers(:hard)
      providers -> {:ok, providers}
    end
  end

  @doc """
  Returns an Oembed endpoint for the given url

  ## Examples

    iex> Oembed.endpoint_from_url "https://vimeo.com/88856141"
    {:ok, "https://vimeo.com/api/oembed.json"}

    iex> Oembed.endpoint_from_url "https://vimeo.com/88856141", %{"format" => "xml"}
    {:ok, "https://vimeo.com/api/oembed.xml"}
  """
  @spec endpoint_from_url(String.t(), map(), Keyword.t()) :: {:ok, String.t()} | {:error, atom()}
  def endpoint_from_url(url, params \\ %{"format" => "json"}, opts \\ []) do
    case provider_from_url(url, opts) do
      nil ->
        {:error, :no_oembed_provider}

      provider ->
        endpoint_from_provider(provider, params)
    end
  end

  # Maps a url to a provider, or returns nil if no such provider exists
  defp provider_from_url(url, opts) do
    fetch_type = if Keyword.get(opts, :skip_cache?, false), do: :hard, else: :soft

    {:ok, providers} = fetch_providers(fetch_type)

    case URI.parse(url) do
      %URI{host: nil} ->
        nil

      %URI{host: host} ->
        Enum.find(providers, &host_matches?(host, &1))
    end
  end

  defp endpoint_from_provider(provider, params) do
    [endpoint | _] = provider["endpoints"]

    url = endpoint["url"]
    regex = ~r/{(.*?)}/
    url = Regex.replace(regex, url, fn _, key -> params[key] end)

    {:ok, url}
  end

  defp host_matches?(host, %{"provider_url" => provider_url}) do
    Regex.match?(~r/https?:\/\/([a-zA-Z0-9]+\.)?#{host}/, provider_url)
  end

  ## GenServer callbacks

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:providers, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:providers, providers}, _) do
    {:noreply, providers}
  end

  defp config(key) do
    :furlex
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end

  defp oembed_host do
    config(:oembed_host) || "https://oembed.com"
  end

  defp oembed_url(path), do: URI.merge(oembed_host(), path) |> URI.to_string()

  defp req_options do
    [
      connect_options: [timeout: @timeout],
      retry: false,
      receive_timeout: @timeout
    ]
  end

  defp decode_json(body) when is_binary(body), do: @json_library.decode(body)
  defp decode_json(body) when is_list(body) or is_map(body), do: {:ok, body}
  defp decode_json(body), do: {:error, {:invalid_json_body, body}}
end
