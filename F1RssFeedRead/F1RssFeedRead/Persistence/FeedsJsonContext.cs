using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace F1RssFeedRead;

[JsonSourceGenerationOptions(WriteIndented = true)]
[JsonSerializable(typeof(FeedsData))]
[JsonSerializable(typeof(List<FeedSource>))]
internal sealed partial class FeedsJsonContext : JsonSerializerContext
{
}
