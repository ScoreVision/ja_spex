defimpl JaSerializer.ParamParser, for: DateTime do
  def parse(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
