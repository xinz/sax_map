defmodule SAXMap.Handler do
  @moduledoc false

  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, opts) do
    {:ok, {[], Map.new(opts)}}
  end

  def handle_event(:start_element, {tag_name, _attributes}, {stack, %{ignore_attribute: true} = options}) do
    tag = {tag_name, nil}

    {:ok, {[tag | stack], options}}
  end
  def handle_event(:start_element, {tag_name, attributes}, {stack, %{ignore_attribute: false} = options}) do
    tag = {tag_name, attributes, nil}

    {:ok, {[tag | stack], options}}
  end
  def handle_event(:start_element, {tag_name, attributes}, {stack, %{ignore_attribute: {false, attribute_prefix}} = options}) do
    attributes = Enum.map(attributes, fn({key, value}) ->
      {"#{attribute_prefix}#{key}", value}
    end)
    tag = {tag_name, attributes, nil}
    {:ok, {[tag | stack], options}}
  end


  def handle_event(:characters, "\n" <> _, state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, {stack, %{ignore_attribute: true} = options}) do
    [{tag_name, _content} | stack] = stack
    current = {tag_name, chars}
    {:ok, {[current | stack], options}}
  end
  def handle_event(:characters, chars, {stack, %{ignore_attribute: false} = options}) do
    [{tag_name, attributes, _content} | stack] = stack
    current = {tag_name, attributes, chars}
    {:ok, {[current | stack], options}}
  end
  def handle_event(:characters, chars, {stack, %{ignore_attribute: {false, _attribute_prefix}} = options}) do
    [{tag_name, attributes, _content} | stack] = stack
    current = {tag_name, attributes, chars}
    {:ok, {[current | stack], options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, content} | []], %{ignore_attribute: true} = options}) do
    current = {tag_name, content}
    {:ok, {current, options}}
  end
  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | []], %{ignore_attribute: false} = options}) do
    current = {tag_name, attributes, content}
    {:ok, {current, options}}
  end
  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | []], %{ignore_attribute: {false, _attribute_prefix}} = options}) do
    current = {tag_name, attributes, content}
    {:ok, {current, options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, content} | [{parent_tag_name, nil} | rest]], %{ignore_attribute: true} = options}) do
    current = {tag_name, format_key_value_pairs(content)}
    parent = {parent_tag_name, [current]}
    {:ok, {[parent | rest], options}}
  end
  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, nil} | rest]], %{ignore_attribute: false} = options}) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{"content", formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current]}
    {:ok, {[parent | rest], options}}
  end
  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, nil} | rest]], %{ignore_attribute: {false, _attribute_prefix}} = options}) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{"content", formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, content} | [{parent_tag_name, parent_content} | rest]], %{ignore_attribute: true} = options}) do
    current = {tag_name, format_key_value_pairs(content)}
    parent = {parent_tag_name, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, parent_content} | rest]], %{ignore_attribute: false} = options}) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{"content", formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_element, tag_name, {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, parent_content} | rest]], %{ignore_attribute: {false, _attribute_prefix}} = options}) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{"content", formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_document, _, {{key, nil}, %{ignore_attribute: true}}) do
    {:ok, %{key => %{}}}
  end
  def handle_event(:end_document, _, {{key, attributes, nil}, %{ignore_attribute: false}}) do
    {:ok, %{key => format_key_value_pairs(attributes)}}
  end
  def handle_event(:end_document, _, {{key, attributes, nil}, %{ignore_attribute: {false, _attribute_prefix}}}) do
    {:ok, %{key => format_key_value_pairs(attributes)}}
  end

  def handle_event(:end_document, _, {{key, value}, %{ignore_attribute: true}}) do
    {:ok, %{key => format_key_value_pairs(value)}}
  end
  def handle_event(:end_document, _, {{key, attributes, value}, %{ignore_attribute: false}}) do
    content = format_key_value_pairs(attributes) |> Map.put("content", format_key_value_pairs(value))
    {:ok, %{key => content}}
  end
  def handle_event(:end_document, _, {{key, attributes, value}, %{ignore_attribute: {false, _attribute_prefix}}}) do
    content = format_key_value_pairs(attributes) |> Map.put("content", format_key_value_pairs(value))
    {:ok, %{key => content}}
  end

  defp format_key_value_pairs(items) when is_list(items) do
    list_to_map(items, %{})
  end
  defp format_key_value_pairs(item) do
    item
  end

  defp list_to_map([], prepared) do
    prepared
  end
  defp list_to_map([item | rest], prepared) when is_map(item) do
    [{key, value}] = Map.to_list(item)
    current_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(current_value, prepared, key, value)
    list_to_map(rest, prepared)
  end
  defp list_to_map([{key, value} | rest], prepared) do
    current_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(current_value, prepared, key, value)
    list_to_map(rest, prepared)
  end

  defp put_or_concat_to_map(nil, map, key, value) do
    Map.put(map, key, value)
  end
  defp put_or_concat_to_map(current_value, map, key, value) when is_list(current_value) do
    Map.put(map, key, [value | current_value])
  end
  defp put_or_concat_to_map(current_value, map, key, value) do
    Map.put(map, key, [value, current_value])
  end

end
