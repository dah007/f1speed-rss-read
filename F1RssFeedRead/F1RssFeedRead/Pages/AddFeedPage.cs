using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

internal sealed partial class AddFeedPage : ContentPage
{
    private readonly AddFeedForm _form = new();

    public AddFeedPage(FeedsManager feedsManager)
    {
        Id = "F1RssFeedRead.AddFeed";
        Icon = new IconInfo("");
        Title = "Add feed";
        Name = "Add";

        _form.Submitted += (_, result) => feedsManager.Add(result.Name, result.Url);
    }

    public override IContent[] GetContent() => [_form];
}
