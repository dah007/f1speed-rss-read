// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

internal sealed partial class F1RssFeedReadPage : ContentPage
{
    private const int MaxArticlesPerFeed = 6;
    private const int MaxArticlesTotal = 20;
    private static readonly TimeSpan FetchTimeout = TimeSpan.FromSeconds(12);

    private readonly FeedsManager _feedsManager;
    private readonly MarkdownContent _content = new();

    public F1RssFeedReadPage(FeedsManager feedsManager)
    {
        _feedsManager = feedsManager;
        Id = "F1RssFeedRead.News";
        Icon = new IconInfo("🏁");
        Title = "F1 News";
        Name = "Open";
    }

    public override IContent[] GetContent()
    {
        _content.Body = BuildMarkdown();
        return [_content];
    }

    private string BuildMarkdown()
    {
        var feeds = _feedsManager.Feeds;
        if (feeds.Count == 0)
        {
            return "No feeds configured.\n\nOpen **Manage F1 Feeds** to add one.";
        }

        using var cts = new CancellationTokenSource(FetchTimeout);
        List<RssArticle> articles;
        List<string> errors;
        try
        {
            (articles, errors) = RssFetcher.FetchAllAsync(feeds, MaxArticlesPerFeed, cts.Token)
                .GetAwaiter()
                .GetResult();
        }
        catch (Exception ex)
        {
            return $"Couldn't load F1 news.\n\n*{ex.Message}*";
        }

        var ordered = articles
            .OrderByDescending(a => a.Published ?? DateTimeOffset.MinValue)
            .Take(MaxArticlesTotal)
            .ToList();

        if (ordered.Count == 0)
        {
            var reasons = errors.Count > 0 ? string.Join("; ", errors) : "no articles returned";
            return $"Couldn't load any F1 news right now.\n\n*{reasons}*";
        }

        var sb = new StringBuilder();
        sb.AppendLine("# 🏁 F1 News");
        sb.AppendLine();
        sb.AppendLine(CultureInfo.InvariantCulture, $"*Updated {DateTimeOffset.Now:h:mm tt, MMM d}*");
        sb.AppendLine();

        foreach (var article in ordered)
        {
            var when = article.Published is { } p ? p.LocalDateTime.ToString("MMM d, h:mm tt", CultureInfo.InvariantCulture) : string.Empty;
            var titleLine = string.IsNullOrWhiteSpace(article.Link)
                ? $"**{article.Title}**"
                : $"**[{article.Title}]({article.Link})**";

            sb.AppendLine(titleLine);
            sb.AppendLine(when.Length > 0 ? $"*{article.SourceName} · {when}*" : $"*{article.SourceName}*");

            if (!string.IsNullOrWhiteSpace(article.Summary))
            {
                sb.AppendLine();
                sb.AppendLine(article.Summary);
            }

            sb.AppendLine();
            sb.AppendLine("---");
            sb.AppendLine();
        }

        if (errors.Count > 0)
        {
            var failedNames = string.Join(", ", errors.Select(e => e.Split(':')[0]));
            sb.AppendLine(CultureInfo.InvariantCulture, $"⚠ Couldn't load: {failedNames}");
        }

        return sb.ToString();
    }
}
