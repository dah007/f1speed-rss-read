using System.Linq;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

internal sealed partial class ManageFeedsPage : ListPage
{
    private readonly FeedsManager _feedsManager;

    public ManageFeedsPage(FeedsManager feedsManager)
    {
        _feedsManager = feedsManager;
        Id = "F1RssFeedRead.ManageFeeds";
        Icon = new IconInfo("");
        Title = "Manage F1 Feeds";
        Name = "Open";
        _feedsManager.FeedsChanged += OnFeedsChanged;
    }

    private void OnFeedsChanged() => RaiseItemsChanged(_feedsManager.Feeds.Count + 1);

    public override IListItem[] GetItems()
    {
        var addItem = new ListItem(new AddFeedPage(_feedsManager))
        {
            Title = "Add feed",
            Subtitle = "Add a new RSS feed by name and URL",
            Icon = new IconInfo(""),
        };

        var feedItems = _feedsManager.Feeds.Select(feed => new ListItem(new OpenUrlCommand(feed.Url))
        {
            Title = feed.Name,
            Subtitle = feed.Url,
            Icon = new IconInfo(""),
            MoreCommands =
            [
                new CommandContextItem(new RemoveFeedCommand(feed.Id, _feedsManager))
                {
                    IsCritical = true,
                },
            ],
        });

        return [addItem, .. feedItems];
    }
}
