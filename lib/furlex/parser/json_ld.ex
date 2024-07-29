defmodule Furlex.Parser.JsonLD do
  @behaviour Furlex.Parser

  @json_library Application.get_env(:furlex, :json_library, Jason)
  
  alias HtmlEntities

  @spec parse(String.t()) :: {:ok, List.t()}
  def parse(html) do
    meta = "script[type=\"application/ld+json\"]"

    with {:ok, document} <- Floki.parse_document(html) do
      case Floki.find(document, meta) do
        [] ->
          {:ok, []}

        elements ->
          json_ld =
            elements
            |> Enum.map(&decode/1)
            |> List.flatten()

          {:ok, json_ld}
      end
    end
  end

  defp decode(element) do
    case element |> Floki.text(js: true) |> @json_library.decode() do
      {:ok, json} -> json |> decode_html_entities()
      {:error, _} -> []
    end
  end

  defp decode_html_entities(result) when is_list(result) do
    Enum.map(result, &decode_html_entities/1)
  end

  defp decode_html_entities(result) when is_map(result) do
    result
    |> Enum.map(fn
      {k, v} ->
        {k, decode_html_entities(v)}
    end)
    |> Enum.into(%{})
  end

  defp decode_html_entities(result) do
    do_decode_html_entities(result)
  end

  defp do_decode_html_entities(result) when is_binary(result) do
    HtmlEntities.decode(result)
  end

  defp do_decode_html_entities(result), do: result
end
