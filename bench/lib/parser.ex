defmodule SAXMap.Bench.SimpleFormParser do
  @moduledoc """
  For compare with simple custom parser use `Saxy.SimpleForm`.
  """

  defp parse([{tag, _attrs, children} | tail]) do
      %{}
      |> Map.put(tag, parse(children))
      |> Map.merge(parse(tail), fn 
        _k, v1, v2 when is_list(v2) -> [v1 | v2] 
        _k, v1, v2 -> [v1, v2] 
      end)      
  end

  defp parse(["\n" <> _ | tail]), do: parse(tail)

  defp parse([head | []]), do: head

  defp parse([]), do: %{}

  def from_string(xml) do
    {:ok, result} = Saxy.SimpleForm.parse_string(xml)
    parse([result])
  end
end
