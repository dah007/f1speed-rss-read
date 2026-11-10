// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace F1RssFeedRead;

public partial class F1RssFeedReadCommandsProvider : CommandProvider
{
    private readonly FeedsManager _feedsManager = new();
    private readonly ICommandItem[] _commands;
    private readonly ICommandItem _newsDockItem;

    public F1RssFeedReadCommandsProvider()
    {
        Id = "com.dholmberg.f1rssfeedread";
        DisplayName = "F1Speed Feed Read";
        Icon = IconHelpers.FromRelativePath("Assets\\StoreLogo.png");

        var newsPage = new F1RssFeedReadPage(_feedsManager);
        var manageFeedsPage = new ManageFeedsPage(_feedsManager);

        _newsDockItem = new CommandItem(newsPage)
        {
            Title = "F1 News",
            MoreCommands = [new CommandContextItem(manageFeedsPage)],
        };

        _commands = [
            _newsDockItem,
            new CommandItem(manageFeedsPage) { Title = "Manage F1 Feeds" },
        ];
    }

    public override ICommandItem[] TopLevelCommands()
    {
        return _commands;
    }

    public override ICommandItem[]? GetDockBands()
    {
        return [_newsDockItem];
    }
}
