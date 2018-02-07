defmodule JSONPatchTest do
  use ExUnit.Case, async: true
  doctest JSONPatch
  doctest JSONPatch.Path

  if System.get_env("SKIP_TEST_SUITE") do
    IO.puts("Skipping test suite.")
  else
    @test_suites [
      "local_test_suite.json",
      "json-patch-tests/tests.json",
      "json-patch-tests/spec_tests.json"
    ]
    for filename <- @test_suites do
      with {:ok, text} <- "./test/#{filename}" |> File.read() do
        tests = text |> Jason.decode!()

        for {t, i} <- Enum.with_index(tests) do
          test "#{filename}[#{i}] (#{t["comment"]})" do
            tt = unquote(Macro.escape(t))

            cond do
              tt["disabled"] ->
                :skipped

              tt["error"] ->
                assert({:error, type, desc} = JSONPatch.patch(tt["doc"], tt["patch"]))
                if tt["error_type"] do
                  assert(String.to_existing_atom(tt["error_type"]) == type, desc)
                end

              tt["expected"] ->
                assert({:ok, tt["expected"]} == JSONPatch.patch(tt["doc"], tt["patch"]))

              :else ->
                assert(JSONPatch.patch(tt["doc"], tt["patch"]))
            end
          end
        end
      else
        _ ->
          IO.puts(
            "Test suite #{filename} not present -- run `mix download-tests` to download test suite"
          )
      end
    end
  end
end
