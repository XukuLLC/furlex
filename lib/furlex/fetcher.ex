defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """

  alias Furlex.Oembed

  require Logger

  @json_library Application.compile_env(:furlex, :json_library, Jason)
  @timeout Application.compile_env(:furlex, :timeout, 30_000)

  @doc """
  Fetches a url and extracts the body
  """
  @spec fetch(String.t(), Keyword.t()) :: {:ok, String.t(), non_neg_integer()} | {:error, term()}
  def fetch(url, opts \\ []) do
    case Req.get(url, req_options(opts)) do
      {:ok, %Req.Response{body: body, status: status_code}} ->
        {:ok, body, status_code}

      {:error, reason} ->
        {:error, normalize_error(reason)}
    end
  end

  @doc """
  Fetches oembed data for the given url
  """
  @spec fetch_oembed(String.t(), Keyword.t()) :: {:ok, map() | list() | nil}
  def fetch_oembed(url, opts \\ []) do
    with {:ok, endpoint} <- Oembed.endpoint_from_url(url),
         params = %{"url" => url},
         opts = Keyword.put(opts, :params, params),
         {:ok, %Req.Response{body: response_body}} <- Req.get(endpoint, req_options(opts)),
         {:ok, body} <- decode_json(response_body) do
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

  defp req_options(opts) do
    timeout = Keyword.get(opts, :timeout, @timeout)

    connect_options =
      opts |> Keyword.get(:connect_options, []) |> Keyword.put_new(:timeout, timeout)

    opts
    |> Keyword.delete(:timeout)
    |> Keyword.put_new(:redirect, true)
    |> Keyword.put_new(:retry, false)
    |> Keyword.put_new(:receive_timeout, timeout)
    |> Keyword.put(:connect_options, connect_options)
  end

  defp decode_json(body) when is_binary(body), do: @json_library.decode(body)
  defp decode_json(body) when is_list(body) or is_map(body), do: {:ok, body}
  defp decode_json(body), do: {:error, {:invalid_json_body, body}}

  defp normalize_error(%{reason: reason}) when is_atom(reason), do: reason
  defp normalize_error(exception) when is_exception(exception), do: Exception.message(exception)
  defp normalize_error(reason), do: reason
end
