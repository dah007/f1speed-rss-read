using System;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

internal sealed partial class RemoveFeedCommand : InvokableCommand
{
    private readonly Guid _feedId;
    private readonly FeedsManager _feedsManager;

    public RemoveFeedCommand(Guid feedId, FeedsManager feedsManager)
    {
        _feedId = feedId;
        _feedsManager = feedsManager;
        Name = "Remove";
        Icon = new IconInfo("");
    }

    public override CommandResult Invoke()
    {
        return CommandResult.Confirm(new ConfirmationArgs
        {
            Title = "Remove feed?",
            Description = "This feed will no longer be fetched.",
            IsPrimaryCommandCritical = true,
            PrimaryCommand = new AnonymousCommand(() => _feedsManager.Remove(_feedId))
            {
                Name = "Remove",
                Result = CommandResult.KeepOpen(),
            },
        });
    }
}
