# JSONPatch

[![Travis](https://img.shields.io/travis/gamache/json_patch.svg?style=flat-square)](https://travis-ci.org/gamache/json_patch_elixir)
[![Hex.pm](https://img.shields.io/hexpm/v/json_patch.svg?style=flat-square)](https://hex.pm/packages/json_patch)

JSONPatch is an Elixir implementation of the JSON Patch format,
described in [RFC 6902](http://tools.ietf.org/html/rfc6902).

## Examples

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
        {:json_patch, "~> 0.8.0"}
      ]
    end


## Acknowledgements

JSONPatch can be run against the freely available
[JSON Patch test suite](https://github.com/json-patch/json-patch-test).

Run `mix download-tests` to install these tests.


## Authorship and License

JSONPatch is copyright 2018, Pete Gamache.

JSONPatch is released under the MIT License, available at LICENSE.txt.

