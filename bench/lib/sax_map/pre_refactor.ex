defmodule SAXMap.Bench.PreRefactor do
  @moduledoc false

  @spec from_string(xml :: String.t(), opts :: keyword()) ::
          {:ok, map :: map()} | {:error, exception :: Saxy.ParseError.t()}
  def from_string(xml, opts \\ []) do
    ignore_attribute = Keyword.get(opts, :ignore_attribute, true)

    Saxy.parse_string(
      xml,
      SAXMap.Bench.Handler.PreRefactor,
      [ignore_attribute: ignore_attribute],
      cdata_as_characters: false
    )
  end
end
