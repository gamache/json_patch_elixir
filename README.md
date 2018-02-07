# JSONPatch

An Elixir implementation of JSON Patch (RFC 6902).

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


## Installation

    # mix.exs
    def deps do
      [
        {:json_patch, "~> 0.5.0"}
      ]
    end


## Acknowledgements

JSONPatch can be run against the freely available JSON Patch test suite,
maintained here: https://github.com/json-patch/json-patch-test

