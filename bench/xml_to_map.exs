xml = """
      <root>
        <a>
          <b attr="1">b2</b>
          <c>1</c>
          <d>test</d>
          <items>
            <item attr="a">1</item>
            <item attr="b">2</item>
            <item attr="c">3</item>
          </items>
        </a>
        <b>test</b>
        <name flag="false">testname</name>
      </root>
    """

Benchee.run(
  %{
    "SAXMap.from_string" => fn -> SAXMap.from_string(xml, ignore_attribute: false) end,
    "XmlToMap.naive_map" => fn -> XmlToMap.naive_map(xml) end,
  },
  time: 10,
  memory_time: 2
)
