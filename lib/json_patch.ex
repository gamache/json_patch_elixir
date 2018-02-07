defmodule JSONPatch do
  @moduledoc ~S"""
  JSONPatch is an Elixir implementation of the JSON Patch format,
  described in [RFC 6902](http://tools.ietf.org/html/rfc6902).

  Examples:

      iex> JSONPatch.patch(%{"a" => 1}, [
      ...>   %{"op" => "add", "path" => "/b", "value" => %{"c" => true}},
      ...>   %{"op" => "test", "path" => "/a", "value" => 1},
      ...>   %{"op" => "move", "from" => "/b/c", "path" => "/c"}
      ...> ])
      {:ok, %{"a" => 1, "b" => %{}, "c" => true}}

      iex> JSONPatch.patch(%{"a" => 22}, [
      ...>   %{"op" => "add", "path" => "/b", "value" => %{"c" => true}},
      ...>   %{"op" => "test", "path" => "/a", "value" => 1},
      ...>   %{"op" => "move", "from" => "/b/c", "path" => "/c"}
      ...> ])
      {:error, :test_failed, ~s|test failed (patches[1], %{"op" => "test", "path" => "/a", "value" => 1})|}
  """

  alias JSONPatch.Path

  @type json_document :: json_object | json_array

  @type json_object :: %{String.t() => json_encodable}

  @type json_array :: [json_encodable]

  @type json_encodable ::
          json_object
          | json_array
          | String.t()
          | number
          | true
          | false
          | nil

  @type patches :: [patch]

  @type patch :: map

  @type return_value :: {:ok, json_encodable} | {:error, error_type, String.t()}

  @type error_type :: :test_failed | :syntax_error | :path_error

  @type status_code :: non_neg_integer

  @doc ~S"""
  Applies JSON Patch (RFC 6902) patches to the given JSON document.
  Returns `{:ok, patched_map}` or `{:error, error_type, description}`.

  Examples:

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "replace", "path" => "/foo", "value" => 2}])
      {:ok, %{"foo" => 2}}

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "test", "path" => "/foo", "value" => 2}])
      {:error, :test_failed, ~s|test failed (patches[0], %{"op" => "test", "path" => "/foo", "value" => 2})|}

      iex> %{"foo" => "bar"} |> JSONPatch.patch([%{"op" => "remove", "path" => "/foo"}])
      {:ok, %{}}
  """
  @spec patch(json_document, patches, non_neg_integer) :: return_value
  def patch(doc, patches) do
    patch(doc, patches, 0)
  end

  defp patch(doc, [], _), do: {:ok, doc}

  defp patch(doc, [p | rest], i) do
    case apply_single_patch(doc, p) do
      {:ok, newdoc} ->
        patch(newdoc, rest, i + 1)

      {:error, type, desc} ->
        {:error, type, "#{desc} (patches[#{i}], #{inspect(p)})"}
    end
  end

  @doc ~S"""
  Converts a `t:return_value/0` to an HTTP status code.

  Example:

      iex> JSONPatch.patch(%{"a" => 1}, [%{"op" => "test", "path" => "/a", "value" => 1}]) |> JSONPatch.status_code
      200

      iex> JSONPatch.patch(%{"a" => 1}, [%{"op" => "test", "path" => "/a", "value" => 22}]) |> JSONPatch.status_code
      409
  """
  @spec status_code(return_value) :: status_code
  def status_code(return_value)

  def status_code({:ok, _}), do: 200

  def status_code({:error, type, _}) do
    error_type_to_status_code(type)
  end

  @doc ~S"""
  Converts an `t:error_type/0` into an HTTP status code.

  Examples:

      iex> JSONPatch.error_type_to_status_code(:test_failed)
      409

      iex> JSONPatch.error_type_to_status_code(:path_error)
      422

      iex> JSONPatch.error_type_to_status_code(:syntax_error)
      400
  """
  @spec error_type_to_status_code(error_type) :: status_code
  def error_type_to_status_code(error_type) do
    case error_type do
      :test_failed -> 409
      :path_error -> 422
      :syntax_error -> 400
      _ -> 400
    end
  end

  @spec apply_single_patch(json_document, patch) :: return_value
  defp apply_single_patch(doc, patch) do
    cond do
      !Map.has_key?(patch, "op") -> {:error, :syntax_error, "missing `op`"}
      !Map.has_key?(patch, "path") -> {:error, :syntax_error, "missing `path`"}
      :else -> apply_op(patch["op"], doc, patch)
    end
  end

  @spec apply_op(String.t(), json_document, patch) :: return_value
  defp apply_op("test", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, :syntax_error, "missing `value`"}

      :else ->
        case Path.get_value_at_path(doc, patch["path"]) do
          {:ok, path_value} ->
            if path_value == patch["value"] do
              {:ok, doc}
            else
              {:error, :test_failed, "test failed"}
            end

          err ->
            err
        end
    end
  end

  defp apply_op("remove", doc, patch) do
    Path.remove_value_at_path(doc, patch["path"])
  end

  defp apply_op("add", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, :syntax_error, "missing `value`"}

      :else ->
        Path.add_value_at_path(doc, patch["path"], patch["value"])
    end
  end

  defp apply_op("replace", doc, patch) do
    cond do
      !Map.has_key?(patch, "value") ->
        {:error, :syntax_error, "missing `value`"}

      :else ->
        Path.replace_value_at_path(doc, patch["path"], patch["value"])
    end
  end

  defp apply_op("move", doc, patch) do
    cond do
      !Map.has_key?(patch, "from") ->
        {:error, :syntax_error, "missing `from`"}

      :else ->
        with {:ok, value} <- Path.get_value_at_path(doc, patch["from"]),
             {:ok, data} <- Path.remove_value_at_path(doc, patch["from"]) do
          Path.add_value_at_path(data, patch["path"], value)
        else
          err -> err
        end
    end
  end

  defp apply_op("copy", doc, patch) do
    cond do
      !Map.has_key?(patch, "from") ->
        {:error, :syntax_error, "missing `from`"}

      :else ->
        with {:ok, value} <- Path.get_value_at_path(doc, patch["from"]) do
          Path.add_value_at_path(doc, patch["path"], value)
        else
          err -> err
        end
    end
  end

  defp apply_op(op, _doc, _patch) do
    {:error, :syntax_error, "not implemented: #{op}"}
  end
end
