defmodule JSONPatch do
  alias JSONPatch.Path

  @type json_document :: json_object | json_array

  @type json_object :: %{String.t => json_encodable}

  @type json_array :: [json_encodable]

  @type json_encodable ::
    json_object |
    json_array |
    String.t |
    number |
    true | false | nil

  @type patches :: [patch]
  @type patch :: map

  @type return :: {:ok, json_document} | {:error, String.t}

  @doc ~S"""
  Applies JSON Patch (RFC 6902) patches to the given JSON-encodable map.
  Returns `{:ok, patched_map}` or `{:error, reason}`.

  Examples:

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "replace", "path" => "/foo", "value" => 2}])
      {:ok, %{"foo" => 2}}

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "test", "path" => "/foo", "value" => 2}])
      {:error, ~s|condition failed (patches[0], %{"op" => "test", "path" => "/foo", "value" => 2})|}

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "remove", "path" => "/foo"}])
      {:ok, %{}}
  """
  @spec patch(json_document, patches, non_neg_integer) :: return
  def patch(doc, patches, i \\ 0)

  def patch(doc, [], _), do: {:ok, doc}

  def patch(doc, [p | rest], i) do
    case apply_single_patch(doc, p) do
      {:ok, newdoc} -> patch(newdoc, rest, i+1)
      {:error, desc} -> {:error, "#{desc} (patches[#{i}], #{inspect(p)})"}
    end
  end


  @spec apply_single_patch(json_document, patch) :: return
  defp apply_single_patch(doc, patch) do
    cond do
      !Map.has_key?(patch, "op") -> {:error, "missing `op`"}
      !Map.has_key?(patch, "path") -> {:error, "missing `path`"}
      :else -> apply_op(patch["op"], doc, patch)
    end
  end


  @spec apply_op(String.t, json_document, patch) :: return
  defp apply_op("test", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, "missing `value`"}

      :else ->
        case Path.get_value_at_path(doc, patch["path"]) do
          {:ok, path_value} ->
            if path_value == patch["value"] do
              {:ok, doc}
            else
              {:error, "condition failed"}
            end
          err -> err
        end
    end
  end

  defp apply_op("remove", doc, patch) do
    Path.remove_value_at_path(doc, patch["path"])
  end

  defp apply_op("add", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, "missing `value`"}

      :else ->
        Path.add_value_at_path(doc, patch["path"], patch["value"])
    end
  end

  defp apply_op("replace", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, "missing `value`"}

      :else ->
        Path.replace_value_at_path(doc, patch["path"], patch["value"])
    end
  end

  defp apply_op("move", doc, patch) do
    cond do
      !Map.has_key?(patch, "from") ->
        {:error, "missing `from`"}

      :else ->
        with {:ok, value} <- Path.get_value_at_path(doc, patch["from"]),
             {:ok, data} <- Path.remove_value_at_path(doc, patch["from"])
        do
          Path.add_value_at_path(data, patch["path"], value)
        else
          err -> err
        end
    end
  end

  defp apply_op("copy", doc, patch) do
    cond do
      !Map.has_key?(patch, "from") ->
        {:error, "missing `from`"}

      :else ->
        with {:ok, value} <- Path.get_value_at_path(doc, patch["from"])
        do
          Path.add_value_at_path(doc, patch["path"], value)
        else
          err -> err
        end
    end
  end

  defp apply_op(op, _doc, _patch) do
    {:error, "not implemented: #{op}"}
  end
end
