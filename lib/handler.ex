defmodule SAXMap.Handler do
  @moduledoc false

  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, _state) do
    {:ok, {[], []}}
  end

  def handle_event(:start_element, {tag_name, _attributes}, state) do
    {stack, options} = state
    #tag = {tag_name, attributes, nil}
    tag = {tag_name, nil}

    {:ok, {[tag | stack], options}}
  end

  def handle_event(:characters, "\n" <> _, state) do
    {:ok, state}
  end
  def handle_event(:characters, chars, state) do
    {stack, options} = state
    [{tag_name, _content} | stack] = stack

    current = {tag_name, chars}

    {:ok, {[current | stack], options}}
  end

  def handle_event(:end_element, tag_name, state) do
    {stack, options} = state
    [{^tag_name, content} | stack] = stack

    current = {tag_name, content}

    case stack do
      [] ->
        {:ok, {format(current), options}}

      [parent | rest] ->
        {parent_tag_name, parent_content} = parent
        parent =
          if parent_content == nil do
            {parent_tag_name, [format(current)]}
          else
            {parent_tag_name, [format(current) | parent_content]}
          end
        {:ok, {[parent | rest], options}}
    end
  end

  def handle_event(:end_document, _, {{key, nil}, _opts}) do
    {:ok, %{key => %{}}}
  end
  def handle_event(:end_document, _, {{key, value}, _opts}) do
    {:ok, %{key => value}}
  end
  def handle_event(:end_document, _, {map, _opts}) when is_map(map) do
    {:ok, map}
  end

  defp format({parent_key, child_nodes}) when is_list(child_nodes) do
    map =
      Enum.reduce(child_nodes, %{}, fn(node, acc) ->
        case node do
          {_key, _value} ->
            map_put_value_or_keep_as_list(node, acc)
          node when is_map(node) ->
            Enum.reduce(node, acc, &map_put_value_or_keep_as_list/2)
        end
      end)
    %{parent_key => map}
  end
  defp format({key, value}) do
    {key, value}
  end

  defp map_put_value_or_keep_as_list({key, value}, acc) do
    if Map.has_key?(acc, key) do
      Map.put(acc, key, List.flatten([value | [acc[key]]]))
    else
      Map.put(acc, key, value)
    end
  end

end
