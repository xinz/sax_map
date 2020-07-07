defmodule SAXMap.Utils do
  @moduledoc false

  def merge(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Map.merge(acc, map, fn _k, v1, v2 ->
        into_list(v2, v1)
      end)
    end)
  end

  def into_map([], prepared) do
    prepared
  end

  def into_map([item | rest], prepared) do
    prepared =
      Enum.reduce(item, prepared, fn({key, new_value}, acc) ->

        if Map.has_key?(acc, key) do
          prepared_value = Map.get(acc, key)
          value = into_list(new_value, prepared_value)
          Map.put(acc, key, value)
        else
          Map.put(acc, key, new_value)
        end
      end)

    into_map(rest, prepared)
  end

  defp into_list(value, target) when is_list(target) do
    [value | target]
  end

  defp into_list(value, target) do
    [value | [target]]
  end

end
