using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace F1RssFeedRead;

internal static partial class RssFetcher
{
    private static readonly HttpClient Client = CreateClient();

    public static async Task<(List<RssArticle> Articles, List<string> Errors)> FetchAllAsync(
        IEnumerable<FeedSource> feeds, int perFeedLimit, CancellationToken cancellationToken)
    {
        var tasks = feeds.Select(f => FetchOneAsync(f, perFeedLimit, cancellationToken)).ToList();
        var results = await Task.WhenAll(tasks).ConfigureAwait(false);

        var articles = new List<RssArticle>();
        var errors = new List<string>();
        foreach (var (feed, feedArticles, error) in results)
        {
            if (error is not null)
            {
                errors.Add($"{feed.Name}: {error}");
            }
            else
            {
                articles.AddRange(feedArticles);
            }
        }

        return (articles, errors);
    }

    private static async Task<(FeedSource Feed, List<RssArticle> Articles, string? Error)> FetchOneAsync(
        FeedSource feed, int limit, CancellationToken cancellationToken)
    {
        try
        {
            using var response = await Client.GetAsync(feed.Url, cancellationToken).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();
            var xml = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            var articles = ParseRss(xml, feed.Name).Take(limit).ToList();
            return (feed, articles, null);
        }
        catch (Exception ex)
        {
            return (feed, [], ex.Message);
        }
    }

    private static IEnumerable<RssArticle> ParseRss(string xml, string sourceName)
    {
        var doc = XDocument.Parse(xml);
        var ns = doc.Root?.GetDefaultNamespace() ?? XNamespace.None;

        var items = doc.Descendants("item").Any()
            ? doc.Descendants("item")
            : doc.Descendants(ns + "entry");

        foreach (var item in items)
        {
            var title = CleanText(item.Element("title")?.Value ?? item.Element(ns + "title")?.Value) ?? "(untitled)";

            var link = item.Element("link")?.Value;
            if (string.IsNullOrWhiteSpace(link))
            {
                link = item.Elements(ns + "link")
                    .FirstOrDefault(e => e.Attribute("rel") is null || e.Attribute("rel")?.Value == "alternate")?
                    .Attribute("href")?.Value;
            }

            var description = item.Element("description")?.Value
                ?? item.Element(ns + "summary")?.Value
                ?? item.Element(ns + "content")?.Value;

            var pubDateRaw = item.Element("pubDate")?.Value
                ?? item.Element(ns + "published")?.Value
                ?? item.Element(ns + "updated")?.Value;

            DateTimeOffset? published = DateTimeOffset.TryParse(pubDateRaw, out var parsed) ? parsed : null;

            yield return new RssArticle(title, link ?? string.Empty, CleanSummary(description), published, sourceName);
        }
    }

    private static HttpClient CreateClient()
    {
        var handler = new HttpClientHandler { AutomaticDecompression = DecompressionMethods.All };
        var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(10) };
        client.DefaultRequestHeaders.UserAgent.ParseAdd("F1RssFeedRead/1.0");
        return client;
    }

    private static string? CleanText(string? text) =>
        string.IsNullOrWhiteSpace(text) ? null : WebUtility.HtmlDecode(text).Trim();

    private static string? CleanSummary(string? html)
    {
        var text = CleanText(html);
        if (text is null)
        {
            return null;
        }

        text = StripTagsRegex().Replace(text, " ");
        text = CollapseWhitespaceRegex().Replace(text, " ").Trim();

        const int maxLength = 180;
        return text.Length > maxLength ? text[..maxLength].TrimEnd() + "…" : text;
    }

    [GeneratedRegex("<[^>]+>")]
    private static partial Regex StripTagsRegex();

    [GeneratedRegex(@"\s+")]
    private static partial Regex CollapseWhitespaceRegex();
}
