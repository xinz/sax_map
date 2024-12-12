defmodule SAXMap.Handler do
  @moduledoc false

  @behaviour Saxy.Handler

  # The key name of internal text content when process XML mixed content
  @key_text_content "_#{__MODULE__}.TextContent_"

  # The key name of the transfer map result for the text content
  # part extracted from the original XML data
  @key_content "content"

  def handle_event(:start_document, _prolog, opts) do
    {:ok, {[], Map.new(opts)}}
  end

  def handle_event(
        :start_element,
        {tag_name, _attributes},
        {stack, %{ignore_attribute: true} = options}
      ) do
    stack = prepare_stack_text_when_start_element(stack)
    tag = {tag_name, nil}
    {:ok, {[tag | stack], options}}
  end

  def handle_event(
        :start_element,
        {tag_name, attributes},
        {stack, %{ignore_attribute: false} = options}
      ) do
    stack = prepare_stack_text_when_start_element(stack)
    tag = {tag_name, attributes, nil}
    {:ok, {[tag | stack], options}}
  end

  def handle_event(
        :start_element,
        {tag_name, attributes},
        {stack, %{ignore_attribute: {false, attribute_prefix}} = options}
      ) do
    stack = prepare_stack_text_when_start_element(stack)
    attributes =
      Enum.map(attributes, fn {key, value} ->
        {"#{attribute_prefix}#{key}", value}
      end)

    tag = {tag_name, attributes, nil}
    {:ok, {[tag | stack], options}}
  end

  def handle_event(:cdata, cdata, {[{tag_name, _} | stack], options}) do
    current = {tag_name, cdata}
    {:ok, {[current | stack], options}}
  end

  def handle_event(:cdata, cdata, {[{tag_name, attributes, _} | stack], options}) do
    current = {tag_name, attributes, cdata}
    {:ok, {[current | stack], options}}
  end

  def handle_event(:characters, "\r" <> _ = chars, state) do
    ignore_or_extract_characters(chars, state)
  end

  def handle_event(:characters, "\n" <> _ = chars, state) do
    ignore_or_extract_characters(chars, state)
  end

  def handle_event(
        :characters,
        chars,
        {[{_not_end_tag, prepared}] = _stack, _} = state
      )
      when prepared != nil do
    ignore_or_extract_characters(chars, state)
  end

  def handle_event(:characters, chars, state) do
    extract_characters(chars, state)
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, content} | []], %{ignore_attribute: true} = options}
      ) do
    current = {tag_name, content}
    {:ok, {current, options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, attributes, content} | []], %{ignore_attribute: false} = options}
      ) do
    current = {tag_name, attributes, content}
    {:ok, {current, options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, attributes, content} | []],
         %{ignore_attribute: {false, _attribute_prefix}} = options}
      ) do
    current = {tag_name, attributes, content}
    {:ok, {current, options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, content} | [{parent_tag_name, nil} | rest]],
         %{ignore_attribute: true} = options}
      ) do
    current = {tag_name, format_key_value_pairs(content)}
    parent = {parent_tag_name, [current]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, nil} | rest]],
         %{ignore_attribute: false} = options}
      ) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, nil} | rest]],
         %{ignore_attribute: {false, _attribute_prefix}} = options}
      ) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[{tag_name, content} | [{parent_tag_name, parent_content} | rest]],
         %{ignore_attribute: true} = options}
      ) do
    current = {tag_name, format_key_value_pairs(content)}
    parent = {parent_tag_name, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[
           {tag_name, attributes, content}
           | [{parent_tag_name, parent_attributes, parent_content} | rest]
         ], %{ignore_attribute: false} = options}
      ) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(
        :end_element,
        tag_name,
        {[
           {tag_name, attributes, content}
           | [{parent_tag_name, parent_attributes, parent_content} | rest]
         ], %{ignore_attribute: {false, _attribute_prefix}} = options}
      ) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    parent = {parent_tag_name, parent_attributes, [current | parent_content]}
    {:ok, {[parent | rest], options}}
  end

  def handle_event(:end_document, _, {{key, nil}, %{ignore_attribute: true}}) do
    {:ok, %{key => %{}}}
  end

  def handle_event(:end_document, _, {{key, attributes, nil}, %{ignore_attribute: false}}) do
    {:ok, %{key => format_key_value_pairs(attributes)}}
  end

  def handle_event(
        :end_document,
        _,
        {{key, attributes, nil}, %{ignore_attribute: {false, _attribute_prefix}}}
      ) do
    {:ok, %{key => format_key_value_pairs(attributes)}}
  end

  def handle_event(:end_document, _, {{key, value}, %{ignore_attribute: true}}) do
    {:ok, %{key => format_key_value_pairs(value)}}
  end

  def handle_event(:end_document, _, {{key, attributes, value}, %{ignore_attribute: false}}) do
    content =
      format_key_value_pairs(attributes) |> Map.put(@key_content, format_key_value_pairs(value))

    {:ok, %{key => content}}
  end

  def handle_event(
        :end_document,
        _,
        {{key, attributes, value}, %{ignore_attribute: {false, _attribute_prefix}}}
      ) do
    content =
      format_key_value_pairs(attributes) |> Map.put(@key_content, format_key_value_pairs(value))
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

  defp list_to_map([%{@key_text_content => text_items} | rest], prepared) do
    # Use "content" instead of @key_text_content as the key name
    list_to_map(rest, Map.put(prepared, @key_content, Enum.reverse(text_items)))
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

  defp ignore_or_extract_characters(chars, state) do
    if String.trim(chars) == "" do
      # ignore
      {:ok, state}
    else
      extract_characters(chars, state)
    end
  end

  defp extract_characters(chars, {stack, %{ignore_attribute: true} = options}) do
    [{tag_name, content} | stack] = stack
    current = {tag_name, append_characters_text_content(content, chars)}
    {:ok, {[current | stack], options}}
  end

  defp extract_characters(chars, {stack, %{ignore_attribute: false} = options}) do
    [{tag_name, attributes, content} | stack] = stack
    current = {tag_name, attributes, append_characters_text_content(content, chars)}
    {:ok, {[current | stack], options}}
  end

  defp extract_characters(
         chars,
         {stack, %{ignore_attribute: {false, _attribute_prefix}} = options}
       ) do
    [{tag_name, attributes, content} | stack] = stack
    current = {tag_name, attributes, append_characters_text_content(content, chars)}
    {:ok, {[current | stack], options}}
  end

  defp prepare_stack_text_when_start_element([{key, value} | rest]) when is_bitstring(value) do
    [{key, [%{@key_text_content => [value]}]} | rest]
  end
  defp prepare_stack_text_when_start_element([{key, attributes, value} | rest]) when is_bitstring(value) do
    [{key, attributes, [%{@key_text_content => [value]}]} | rest]
  end
  defp prepare_stack_text_when_start_element(stack), do: stack

  defp append_characters_text_content(nil, chars), do: chars
  defp append_characters_text_content(content, chars) when is_list(content) do
    case Enum.reverse(content) do
      [%{@key_text_content => text_items} | rest] ->
        Enum.reverse([%{@key_text_content => [chars | text_items]} | rest])
      items ->
        Enum.reverse([%{@key_text_content => [chars]} | items])
    end
  end

end
