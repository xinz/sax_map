defmodule SAXMap.Handler.IgnoreAttribute do
  @moduledoc false
  @behaviour Saxy.Handler

  alias SAXMap.Utils

  def handle_event(:start_document, _prolog, _state) do
    {:ok, {[], [], []}}
  end

  def handle_event(:end_document, _data, {root_name, elements}) do
    {
      :ok,
      %{root_name => Utils.into_map(elements, %{})}
    }
  end
  def handle_event(:end_document, _data, {_queue, _processing, [element]}) do
    {:ok, element}
  end

  def handle_event(:start_element, {name, _attributes}, {queue, processing, elements}) do
    {:ok, {[{:start_element, name} | queue], [name | processing], elements}}
  end

  def handle_event(
        :end_element,
        name,
        {[{:characters, chars}, {:start_element, name} | rest], processing, elements}
      ) do
    {:ok, {rest, processing, [%{name => chars} | elements]}}
  end

  def handle_event(:end_element, name, {[{:start_element, name} | rest], processing, elements})
      when rest != [] do
    children_count = Enum.find_index(processing, fn x -> x == name end)
    processing = Enum.slice(processing, children_count..-1)
    {peer_elements, rest_elements} = Enum.split(elements, children_count)
    new_element = %{name => Utils.merge(peer_elements)}
    {:ok, {rest, processing, [new_element | rest_elements]}}
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

end
