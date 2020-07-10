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

  def handle_event(:end_element, tag_name, {[{tag_name, content} | []], options}) do
    current = {tag_name, content}
    {:ok, {current, options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, content} | [{parent_tag_name, nil} | rest]], options}) do
    current = {tag_name, format_content(content)}
    parent = {parent_tag_name, [current]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, content} | [{parent_tag_name, parent_content} | rest]], options}) do
    current = {tag_name, format_content(content)}
    parent = {parent_tag_name, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_document, _, {{key, nil}, _opts}) do
    {:ok, %{key => %{}}}
  end

  def handle_event(:end_document, _, {{key, value}, _opts}) do
    {:ok, %{key => format_content(value)}}
  end

  def handle_event(:end_document, _, {map, _opts}) when is_map(map) do
    {:ok, map}
  end

  defp format_content(items) when is_list(items) do
    list_to_map(items, %{})
  end
  defp format_content(item) do
    item
  end

  defp list_to_map([], prepared) do
    prepared
  end
  defp list_to_map([{key, value} | rest], prepared) do
    current_value = Map.get(prepared, key)
    prepared =
      cond do
        current_value == nil ->
          Map.put(prepared, key, value)
        is_list(current_value) ->
          Map.put(prepared, key, [value | current_value])
        true ->
          Map.put(prepared, key, [value, current_value])
      end
    list_to_map(rest, prepared)
  end

end
