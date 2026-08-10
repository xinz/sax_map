alias SAXMap.Bench.PreRefactor

mixed_content_xml =
  "<root>" <>
    String.duplicate("<p>" <> String.duplicate("s<b>1</b>", 200) <> "e</p>", 20) <>
    "</root>"

attribute_dense_xml =
  "<root>" <>
    String.duplicate("<item alpha=\"1\" beta=\"2\" gamma=\"3\">text</item>", 2_000) <>
    "</root>"

inputs = %{
  "alternating mixed content" => {mixed_content_xml, []},
  "attribute-dense" => {attribute_dense_xml, [ignore_attribute: false]},
  "attribute-dense with @ prefix" => {attribute_dense_xml, [ignore_attribute: {false, "@"}]}
}

Enum.each(inputs, fn {name, {xml, opts}} ->
  before = PreRefactor.from_string(xml, opts)
  refactored = SAXMap.from_string(xml, opts)

  if before != refactored do
    raise "before and after results differ for #{name}"
  end
end)

Benchee.run(
  %{
    "Before refactor" => fn {xml, opts} -> PreRefactor.from_string(xml, opts) end,
    "After refactor" => fn {xml, opts} -> SAXMap.from_string(xml, opts) end
  },
  inputs: inputs,
  time: 10,
  memory_time: 2,
  parallel: 1
)
