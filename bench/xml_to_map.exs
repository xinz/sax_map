xml = """
      <root>
        <a>
          <b>b2</b>
          <c>1</c>
          <d>test</d>
          <items>
            <item>1</item>
            <item>2</item>
            <item>3</item>
          </items>
        </a>
        <b>test</b>
        <name>testname</name>
      </root>
    """

Benchee.run(
  %{
    "SAXMap.from_string" => fn -> SAXMap.from_string(xml) end,
    "XmlToMap.naive_map" => fn -> XmlToMap.naive_map(xml) end,
  },
  time: 10,
  memory_time: 2
)
