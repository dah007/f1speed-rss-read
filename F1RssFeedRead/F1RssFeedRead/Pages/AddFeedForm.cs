using System.Text.Json.Nodes;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;
using Windows.Foundation;

namespace F1RssFeedRead;

internal sealed partial class AddFeedForm : FormContent
{
    public event TypedEventHandler<object, FeedFormResult>? Submitted;

    public AddFeedForm()
    {
        TemplateJson = """
        {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.6",
            "body": [
                {
                    "type": "Input.Text",
                    "id": "name",
                    "label": "Feed name",
                    "isRequired": true,
                    "errorMessage": "Enter a name for this feed",
                    "placeholder": "e.g. Autosport F1 News"
                },
                {
                    "type": "Input.Text",
                    "id": "url",
                    "label": "Feed URL",
                    "isRequired": true,
                    "errorMessage": "Enter the RSS feed's URL",
                    "placeholder": "https://example.com/rss.xml"
                }
            ],
            "actions": [
                {
                    "type": "Action.Submit",
                    "title": "Add feed"
                }
            ]
        }
        """;
    }

    public override CommandResult SubmitForm(string payload)
    {
        var formInput = JsonNode.Parse(payload)?.AsObject();
        if (formInput is null)
        {
            return CommandResult.GoHome();
        }

        var name = formInput["name"]?.ToString() ?? string.Empty;
        var url = formInput["url"]?.ToString() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(url))
        {
            return CommandResult.GoHome();
        }

        Submitted?.Invoke(this, new FeedFormResult(name.Trim(), url.Trim()));
        return CommandResult.GoBack();
    }
}
