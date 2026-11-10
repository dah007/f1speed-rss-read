using System;

namespace F1RssFeedRead;

internal sealed record FeedSource(Guid Id, string Name, string Url);
