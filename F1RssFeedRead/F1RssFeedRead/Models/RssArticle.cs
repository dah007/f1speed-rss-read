using System;

namespace F1RssFeedRead;

internal sealed record RssArticle(string Title, string Link, string? Summary, DateTimeOffset? Published, string SourceName);
