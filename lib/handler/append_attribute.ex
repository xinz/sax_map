defmodule SAXMap.Handler.AppendAttribute do
  @moduledoc false
  @behaviour Saxy.Handler

  alias SAXMap.Utils

  def handle_event(:start_document, _prolog, opts) do
    {:ok, {[], [], [], opts}}
  end

  def handle_event(:end_document, _data, {{root_name, root_attributes}, elements, opts}) do
    prefix = opts[:attribute_naming_prefix]
    elements = Utils.into_map(elements, %{})
    {
      :ok,
      %{root_name => merge_attributes_and_elements(root_attributes, elements, prefix)}
    }
  end
  def handle_event(:end_document, _data, {_queue, _processing, [element], _opts}) do
    {:ok, element}
  end

  def handle_event(:start_element, {name, attributes}, {queue, processing, elements, opts}) do
    {:ok, {[{:start_element, {name, attributes}} | queue], [name | processing], elements, opts}}
  end

  def handle_event(
        :end_element,
        name,
        {[{:characters, characters}, {:start_element, {name, attributes}} | rest], processing, elements, opts}
      ) do
    element = merge_attributes_and_elements(attributes, %{name => characters}, opts[:attribute_naming_prefix])
    {:ok, {rest, processing, [element | elements], opts}}
  end

  def handle_event(:end_element, name, {[{:start_element, {name, attributes}} | rest], processing, elements, opts})
      when rest != [] do
    children_count = Enum.find_index(processing, fn x -> x == name end)
    processing = Enum.slice(processing, children_count..-1)
    {peer_elements, rest_elements} = Enum.split(elements, children_count)

    new_element = %{name => merge_attributes_and_elements(attributes, Utils.merge(peer_elements), opts[:attribute_naming_prefix])}

    {:ok, {rest, processing, [new_element | rest_elements], opts}}
  end

  def handle_event(
        :end_element,
        root_name,
        {[{:start_element, {root_name, attributes}}], _processing, elements, opts}
      ) do
    {:ok, {{root_name, attributes}, elements, opts}}
  end

  def handle_event(:characters, chars, {queue, processing, elements, opts}) do
    if String.trim(chars) == "" do
      {:ok, {queue, processing, elements, opts}}
    else
      {:ok, {[{:characters, chars} | queue], processing, elements, opts}}
    end
  end

  defp merge_attributes_and_elements(attributes, elements, attribute_naming_prefix) do
    attributes
    |> attributes_to_map(attribute_naming_prefix)
    |> Map.merge(elements)
  end

  defp attributes_to_map([], _prefix), do: %{}
  defp attributes_to_map(attributes, prefix) do
    attributes_to_map(attributes, %{}, prefix)
  end

  defp attributes_to_map([], prepared, _prefix), do: prepared
  defp attributes_to_map([{key, value} | rest], prepared, prefix) do
    prepared = Map.put(prepared, "#{prefix}#{key}", value)
    attributes_to_map(rest, prepared, prefix)
  end

end
