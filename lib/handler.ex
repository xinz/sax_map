defmodule SAXMap.Handler do
  @moduledoc false

  @behaviour Saxy.Handler

  # The key name of the transfer map result for the text content
  # part extracted from the original XML data
  @key_content "content"

  # Stack entry formats:
  #
  #   ignore_attribute: true  -> {tag_name, text, children}
  #   ignore_attribute: false -> {tag_name, attributes, text, children}
  #
  # `text` is nil, a single binary, or a list of text chunks in reverse order.
  # `children` is a list of {tag_name, value} entries in reverse document order.
  # Both accumulators use O(1) head-prepends and are finalized only when their
  # enclosing element closes.

  def handle_event(:start_document, _prolog, opts) do
    mode = normalize_ignore_attribute(Keyword.get(opts, :ignore_attribute, true))
    {:ok, {[], mode}}
  end

  def handle_event(:start_element, element, {stack, mode}) do
    {:ok, {handle_start_element(element, stack, mode), mode}}
  end

  def handle_event(:cdata, cdata, {stack, mode}) do
    {:ok, {handle_cdata(cdata, stack), mode}}
  end

  def handle_event(:characters, chars, {stack, mode} = state) do
    case handle_characters(chars, stack, mode) do
      nil -> {:ok, state}
      updated_stack -> {:ok, {updated_stack, mode}}
    end
  end

  def handle_event(:end_element, _tag_name, {stack, mode}) do
    {:ok, {handle_end_element(stack, mode), mode}}
  end

  def handle_event(:end_document, _, {stack, mode}) do
    {:ok, handle_end_document(stack, mode)}
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

  defp list_to_map([{key, value} | rest], prepared) do
    existed_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(existed_value, prepared, key, value)
    list_to_map(rest, prepared)
  end

  defp list_to_map_with_prefix([], _prefix, prepared) do
    prepared
  end

  defp list_to_map_with_prefix([{key, value} | rest], prefix, prepared) do
    key = prefix <> key
    existed_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(existed_value, prepared, key, value)
    list_to_map_with_prefix(rest, prefix, prepared)
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

  defp ignore_or_extract_characters(chars, stack, mode) do
    if all_whitespace?(chars) do
      nil
    else
      extract_characters_into_tag(chars, stack, mode)
    end
  end

  defp all_whitespace?(<<>>), do: true

  defp all_whitespace?(<<char, rest::binary>>) when char in [?\s, ?\t, ?\n, ?\r] do
    all_whitespace?(rest)
  end

  defp all_whitespace?(_), do: false

  defp append_characters_text_content(nil, chars), do: chars

  defp append_characters_text_content(text, chars) when is_binary(text) do
    [chars, text]
  end

  defp append_characters_text_content(text, chars) when is_list(text) do
    [chars | text]
  end

  defp handle_start_element({tag_name, _attributes}, stack, true) do
    [{tag_name, nil, []} | stack]
  end

  defp handle_start_element({tag_name, attributes}, stack, false) do
    [{tag_name, attributes, nil, []} | stack]
  end

  defp handle_start_element({tag_name, attributes}, stack, {false, prefix}) when is_binary(prefix) do
    [{tag_name, attributes, nil, []} | stack]
  end

  defp handle_start_element({tag_name, []}, stack, {false, _prefix}) do
    [{tag_name, [], nil, []} | stack]
  end

  defp handle_start_element({tag_name, [{key, _value} | _] = attributes}, stack, {false, prefix}) do
    _ = prefix <> key
    [{tag_name, attributes, nil, []} | stack]
  end

  # Preserve the existing CDATA event semantics: a CDATA event replaces the
  # current element's accumulated content.
  defp handle_cdata(cdata, [{tag_name, _text, _children} | rest]) do
    [{tag_name, cdata, []} | rest]
  end

  defp handle_cdata(cdata, [{tag_name, attributes, _text, _children} | rest]) do
    [{tag_name, attributes, cdata, []} | rest]
  end

  defp handle_characters("\r" <> _ = data, stack, mode) do
    ignore_or_extract_characters(data, stack, mode)
  end

  defp handle_characters("\n" <> _ = data, stack, mode) do
    ignore_or_extract_characters(data, stack, mode)
  end

  defp handle_characters(data, [{_tag_name, text, children}] = stack, true)
       when text != nil or children != [] do
    ignore_or_extract_characters(data, stack, true)
  end

  defp handle_characters(data, stack, mode) do
    extract_characters_into_tag(data, stack, mode)
  end

  defp extract_characters_into_tag(chars, [{tag_name, text, children} | rest], true) do
    [{tag_name, append_characters_text_content(text, chars), children} | rest]
  end

  defp extract_characters_into_tag(
         chars,
         [{tag_name, attributes, text, children} | rest],
         _attribute_mode
       ) do
    [{tag_name, attributes, append_characters_text_content(text, chars), children} | rest]
  end

  defp handle_end_element([{tag_name, text, children}], true) do
    {tag_name, text, children}
  end

  defp handle_end_element([{tag_name, attributes, text, children}], _attribute_mode) do
    {tag_name, attributes, text, children}
  end

  defp handle_end_element(
         [{tag_name, text, children}, {parent_tag_name, parent_text, parent_children} | rest],
         true
       ) do
    current = {tag_name, format_element_content(text, children)}
    [{parent_tag_name, parent_text, [current | parent_children]} | rest]
  end

  defp handle_end_element(
         [
           {tag_name, attributes, text, children},
           {parent_tag_name, parent_attributes, parent_text, parent_children}
           | rest
         ],
         attribute_mode
       ) do
    current = {tag_name, format_attribute_element(attributes, text, children, attribute_mode)}

    [
      {parent_tag_name, parent_attributes, parent_text, [current | parent_children]}
      | rest
    ]
  end

  defp handle_end_document({key, nil, []}, true) do
    %{key => %{}}
  end

  defp handle_end_document({key, text, children}, true) do
    %{key => format_element_content(text, children)}
  end

  defp handle_end_document({key, attributes, nil, []}, attribute_mode) do
    %{key => format_attributes(attributes, attribute_mode)}
  end

  defp handle_end_document({key, attributes, text, children}, attribute_mode) do
    %{
      key =>
        attributes
        |> format_attributes(attribute_mode)
        |> Map.put(@key_content, format_element_content(text, children))
    }
  end

  defp format_attribute_element(attributes, text, children, attribute_mode) do
    content = format_element_content(text, children)
    format_attributes_with_content(attributes, content, attribute_mode)
  end

  defp format_attributes(attributes, false) do
    list_to_map(attributes, %{})
  end

  defp format_attributes(attributes, {false, prefix}) do
    list_to_map_with_prefix(attributes, prefix, %{})
  end

  defp format_attributes_with_content(attributes, content, false) do
    list_to_map(attributes, %{@key_content => content})
  end

  defp format_attributes_with_content(attributes, content, {false, prefix}) do
    list_to_map_with_prefix(attributes, prefix, %{@key_content => content})
  end

  defp format_element_content(nil, []), do: nil

  defp format_element_content(text, []) do
    text_content(text)
  end

  defp format_element_content(nil, children) do
    format_key_value_pairs(children)
  end

  defp format_element_content(text, children) do
    list_to_map(children, %{@key_content => text_chunks(text)})
  end

  defp text_content(text) when is_binary(text), do: text
  defp text_content(text), do: Enum.reverse(text)

  defp text_chunks(text) when is_binary(text), do: [text]
  defp text_chunks(text), do: Enum.reverse(text)

  defp normalize_ignore_attribute(true), do: true
  defp normalize_ignore_attribute(false), do: false
  defp normalize_ignore_attribute({false, ""}), do: false
  defp normalize_ignore_attribute({false, prefix}), do: {false, prefix}
end
