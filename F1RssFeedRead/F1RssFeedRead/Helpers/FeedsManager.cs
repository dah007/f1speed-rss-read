using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

internal sealed class FeedsManager
{
    private static readonly FeedSource[] DefaultFeeds =
    [
        new(Guid.NewGuid(), "BBC Sport Formula 1", "http://feeds.bbci.co.uk/sport/0/formula1/rss.xml"),
        new(Guid.NewGuid(), "Autosport F1 News", "https://www.autosport.com/rss/f1/news/"),
        new(Guid.NewGuid(), "Motorsport.com F1 News", "https://www.motorsport.com/rss/f1/news/"),
        new(Guid.NewGuid(), "Formula1.com Official", "https://www.formula1.com/en/latest/all.xml"),
    ];

    private readonly object _lock = new();
    private readonly string _filePath;
    private readonly List<FeedSource> _feeds;

    public event Action? FeedsChanged;

    public FeedsManager()
    {
        var directory = Utilities.BaseSettingsPath("F1RssFeedRead");
        Directory.CreateDirectory(directory);
        _filePath = Path.Combine(directory, "feeds.json");
        _feeds = Load();
    }

    public IReadOnlyList<FeedSource> Feeds
    {
        get
        {
            lock (_lock)
            {
                return _feeds.ToList();
            }
        }
    }

    public void Add(string name, string url)
    {
        lock (_lock)
        {
            _feeds.Add(new FeedSource(Guid.NewGuid(), name, url));
            Save();
        }

        FeedsChanged?.Invoke();
    }

    public void Remove(Guid id)
    {
        lock (_lock)
        {
            _feeds.RemoveAll(f => f.Id == id);
            Save();
        }

        FeedsChanged?.Invoke();
    }

    private List<FeedSource> Load()
    {
        if (!File.Exists(_filePath))
        {
            var seeded = DefaultFeeds.ToList();
            SaveList(seeded);
            return seeded;
        }

        try
        {
            var json = File.ReadAllText(_filePath);
            var data = JsonSerializer.Deserialize(json, FeedsJsonContext.Default.FeedsData);
            return data?.Feeds is { Count: > 0 } feeds ? feeds : [];
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"F1RssFeedRead: failed to load feeds.json: {ex.Message}");
            return DefaultFeeds.ToList();
        }
    }

    private void Save() => SaveList(_feeds);

    private void SaveList(List<FeedSource> feeds)
    {
        var data = new FeedsData { Feeds = feeds };
        var json = JsonSerializer.Serialize(data, FeedsJsonContext.Default.FeedsData);
        File.WriteAllText(_filePath, json);
    }
}
