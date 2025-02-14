defmodule SAXMap.Handler do
  @moduledoc false

  @behaviour Saxy.Handler

  # The key name of internal text content when process XML mixed content
  @key_text_content "_#{__MODULE__}.TextContent_"

  # The key name of the transfer map result for the text content
  # part extracted from the original XML data
  @key_content "content"

  def handle_event(:start_document, _prolog, opts) do
    ignore_attribute = Keyword.get(opts, :ignore_attribute, true)
    {:ok, {[], ignore_attribute}}
  end

  def handle_event(:start_element, element, {stack, ignore_attribute}) do
    stack = handle_start_element(element, stack, ignore_attribute)
    {:ok, {stack, ignore_attribute}}
  end

  def handle_event(:cdata, cdata, {stack, ignore_attribute}) do
    stack = handle_cdata(cdata, stack)
    {:ok, {stack, ignore_attribute}}
  end

  def handle_event(:characters, chars, {stack, ignore_attribute}) do
    stack = handle_characters(chars, stack, simplify_ignore_attribute_opt(ignore_attribute))
    {:ok, {stack, ignore_attribute}}
  end

  def handle_event(:end_element, _tag_name, {stack, ignore_attribute}) do
    stack = handle_end_element(stack, simplify_ignore_attribute_opt(ignore_attribute))
    {:ok, {stack, ignore_attribute}}
  end

  def handle_event(:end_document, _, {stack, ignore_attribute}) do
    result = handle_end_document(stack, simplify_ignore_attribute_opt(ignore_attribute))
    {:ok, result}
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
    {key, value} = item |> Map.to_list() |> hd()
    existed_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(existed_value, prepared, key, value)
    list_to_map(rest, prepared)
  end

  defp list_to_map([{key, value} | rest], prepared) do
    existed_value = Map.get(prepared, key)
    prepared = put_or_concat_to_map(existed_value, prepared, key, value)
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

  defp ignore_or_extract_characters(chars, stack, value) do
    if String.trim(chars) == "" do
      # ignore
      stack
    else
      extract_characters_into_tag(chars, stack, value)
    end
  end

  defp extract_characters_into_tag(chars, [{tag_name, content} | rest], true) do
    [{tag_name, append_characters_text_content(content, chars)} | rest]
  end

  defp extract_characters_into_tag(chars, [{tag_name, attributes, content} | rest], false) do
    [{tag_name, attributes, append_characters_text_content(content, chars)} | rest]
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

  defp handle_start_element({tag_name, _attributes}, stack, true) do
    stack = prepare_stack_text_when_start_element(stack)
    [{tag_name, nil} | stack]
  end
  defp handle_start_element({tag_name, attributes}, stack, false) do
    stack = prepare_stack_text_when_start_element(stack)
    [{tag_name, attributes, nil} | stack]
  end
  defp handle_start_element({tag_name, attributes}, stack, {false, attribute_prefix}) do
    stack = prepare_stack_text_when_start_element(stack)
    attributes =
      Enum.map(attributes, fn {key, value} ->
        {attribute_prefix <> key, value}
      end)
    [{tag_name, attributes, nil} | stack]
  end

  defp handle_cdata(cdata, [{tag_name, _} | rest]) do
    [{tag_name, cdata} | rest]
  end
  defp handle_cdata(cdata, [{tag_name, attributes, _} | rest]) do
    [{tag_name, attributes, cdata} | rest]
  end

  defp handle_characters("\r" <> _ = data, stack, value) do
    ignore_or_extract_characters(data, stack, value)
  end
  defp handle_characters("\n" <> _ = data, stack, value) do
    ignore_or_extract_characters(data, stack, value)
  end
  defp handle_characters(data, [{_not_end_tag, prepared}] = stack, value) when prepared != nil do
    ignore_or_extract_characters(data, stack, value)
  end
  defp handle_characters(data, stack, value) do
    extract_characters_into_tag(data, stack, value)
  end

  defp handle_end_element([{tag_name, content}], true) do
    {tag_name, content}
  end
  defp handle_end_element([{tag_name, attributes, content}], false) do
    {tag_name, attributes, content}
  end
  defp handle_end_element([{tag_name, content} | [{parenet_tag_name, nil} | rest]], true) do
    current = {tag_name, format_key_value_pairs(content)}
    [{parenet_tag_name, [current]} | rest]
  end
  defp handle_end_element([{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, nil} | rest]], false) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    [{parent_tag_name, parent_attributes, [current]} | rest]
  end
  defp handle_end_element([{tag_name, content} | [{parent_tag_name, parent_content} | rest]], true) do
    current = {tag_name, format_key_value_pairs(content)}
    [{parent_tag_name, [current | parent_content]} | rest]
  end
  defp handle_end_element([{tag_name, attributes, content} | [{parent_tag_name, parent_attributes, parent_content} | rest]], false) do
    formated_content = format_key_value_pairs(content)
    current = %{tag_name => format_key_value_pairs([{@key_content, formated_content} | attributes])}
    [{parent_tag_name, parent_attributes, [current | parent_content]} | rest]
  end

  defp handle_end_document({key, nil}, true) do
    %{key => %{}}
  end
  defp handle_end_document({key, value}, true) do
    %{key => format_key_value_pairs(value)}
  end
  defp handle_end_document({key, attributes, nil}, false) do
    %{key => format_key_value_pairs(attributes)}
  end
  defp handle_end_document({key, attributes, value}, false) do
    value =
      format_key_value_pairs(attributes) |> Map.put(@key_content, format_key_value_pairs(value))
    %{key => value}
  end

  @compile {:inline, simplify_ignore_attribute_opt: 1}
  defp simplify_ignore_attribute_opt(true), do: true
  defp simplify_ignore_attribute_opt(false), do: false
  defp simplify_ignore_attribute_opt({false, _}), do: false

end
