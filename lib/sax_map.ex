defmodule SAXMap do
  @moduledoc """
  XML to Map conversion.

  SAXMap uses a SAX parser (built on top of [Saxy](https://hex.pm/packages/saxy)) to transfer an XML string into a `Map` containing a collection of pairs where the key is the node name and the value is its content.
  """

  defmodule Handler do
    @moduledoc false
    @behaviour Saxy.Handler

    def handle_event(:start_document, _prolog, _state) do
      {:ok, {[], [], []}}
    end

    def handle_event(:end_document, _data, {root_name, elements}) do
      map = Map.put(%{}, root_name, into_map(elements, %{}))
      {:ok, map}
    end
    def handle_event(:end_document, _data, {_queue, _processing, elements}) do
      {:ok, List.first(elements)}
    end

    def handle_event(:start_element, {name, _attributes}, {queue, processing, elements}) do
      {:ok, {[{:start_element, name} | queue], [name | processing], elements}}
    end

    def handle_event(
          :end_element,
          name,
          {[{:characters, chars}, {:start_element, name} | rest], processing, elements}
        ) do
      element = Map.put(%{}, name, chars)
      {:ok, {rest, processing, [element | elements]}}
    end

    def handle_event(:end_element, name, {[{:start_element, name} | rest], processing, elements})
        when length(rest) > 0 do
      children_count = Enum.find_index(processing, fn x -> x == name end)
      processing = Enum.slice(processing, children_count..-1)
      {peer_elements, rest_elements} = Enum.split(elements, children_count)
      element = Map.put(%{}, name, merge(peer_elements))
      {:ok, {rest, processing, [element | rest_elements]}}
    end

    def handle_event(
          :end_element,
          root_name,
          {[{:start_element, root_name}], _processing, elements}
        ) do
      {:ok, {root_name, elements}}
    end

    def handle_event(:characters, chars, {queue, processing, elements}) do
      if String.trim(chars) == "" do
        {:ok, {queue, processing, elements}}
      else
        {:ok, {[{:characters, chars} | queue], processing, elements}}
      end
    end

    defp merge(maps) do
      Enum.reduce(maps, %{}, fn map, acc ->
        Map.merge(acc, map, fn _k, v1, v2 ->
          into_list(v2, v1)
        end)
      end)
    end

    defp into_map([], result) do
      result
    end

    defp into_map([item | rest], result) do
      [key] = Map.keys(item)
      new_value = Map.get(item, key)

      if Map.has_key?(result, key) do
        result_value = Map.get(result, key)
        value = into_list(new_value, result_value)
        result = Map.put(result, key, value)
        into_map(rest, result)
      else
        result = Map.put(result, key, new_value)
        into_map(rest, result)
      end
    end

    defp into_list(value, target) when is_list(target) do
      [value | target]
    end

    defp into_list(value, target) do
      [value | [target]]
    end
  end

  @doc ~S'''
  Use `Saxy.parse_string/4` with a custom SAX parse handler to extract a `Map` containing a collection of pairs where the key is the node name
  and the value is its content.

  ## Example

  Here is an example:

      iex> xml = """
      ...> <?xml version="1.0" encoding="UTF-8"?>
      ...> <thread>
      ...>   <title>Hello</title>
      ...>   <items>
      ...>     <item>item1</item>
      ...>     <item>item2</item>
      ...>   </items>
      ...> </thread>
      ...> """
      iex> SAXMap.from_string(xml)
      {:ok,
       %{
         "thread" => %{"items" => %{"item" => ["item1", "item2"]}, "title" => "Hello"}
       }}

  Please notice that both XML attributes and comments are ignored.
  '''
  @spec from_string(xml :: String.t()) ::
          {:ok, map :: map()} | {:error, exception :: Saxy.ParseError.t()}
  def from_string(xml) do
    Saxy.parse_string(xml, Handler, nil)
  end

end
