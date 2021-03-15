defmodule Furlex.Parser.JsonLD do
  @behaviour Furlex.Parser

  @json_library Application.get_env(:furlex, :json_library, Jason)

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
    element
    |> Floki.text(js: true)
    |> @json_library.decode!()
    |> decode_html_entities()
  end

  defp decode_html_entities(result) when is_list(result) do
    Enum.map(result, &decode_html_entities/1)
  end

  defp decode_html_entities(result) when is_map(result) do
    result
    |> Enum.map(fn
      {k, v} when is_binary(v) ->
        {k, HtmlEntities.decode(v)}

      {k, v} when is_list(v) ->
        {k, decode_html_entities(v)}

      res ->
        res
    end)
    |> Enum.into(%{})
  end

  defp decode_html_entities(result) do
    HtmlEntities.decode(result)
  end
end
