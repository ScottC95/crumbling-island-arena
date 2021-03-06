var hallOfFamePlayers = {
    "FFA_FOUR": 0,
    "DUEL": 1,
    "TWO_TEAMS": 3
};

function HallOfFameChanged(data) {
    if (!data) {
        return;
    }

    $("#HallOfFameLoading").AddClass("Hidden");

    var parent = $("#HallOfFamePlayers");

    for (var mode in data) {
        var players = data[mode];

        if (hallOfFamePlayers[mode] == 0) {
            continue;
        }

        var modePanel = $.CreatePanel("Panel", parent, "");
        modePanel.AddClass("HallOfFameMode");

        var modeName = $.CreatePanel("Label", modePanel, "");
        modeName.text = $.Localize("RankMode_" + mode);
        modeName.AddClass("HallOfFameModeName");

        var modePlayersPanel = $.CreatePanel("Panel", modePanel, "");
        modePlayersPanel.AddClass("HallOfFameModePlayers");

        for (var i = 0; i < hallOfFamePlayers[mode] && i < players.length; i++) {
            var player = players[i];

            var playerPanel = $.CreatePanel("Panel", modePlayersPanel, "");
            playerPanel.AddClass("HallOfFamePlayer");

            var avatarContainer = $.CreatePanel("Panel", playerPanel, "");
            avatarContainer.AddClass("HallOfFameAvatarContainer");

            var avatar = $.CreatePanel("DOTAAvatarImage", avatarContainer, "");
            avatar.steamid = player.steamId64.toString();
            avatar.AddClass("HallOfFameAvatar");

            CreateRankPanelSmall(playerPanel, player, "HallOfFameRank");

            var name = $.CreatePanel("DOTAUserName", playerPanel, "");
            name.steamid = player.steamId64.toString();
            name.AddClass("HallOfFameName");
        }
    }
}

function UpdateTime(label, seasonEndTime) {
    $.Schedule(1, function() {
        UpdateTime(label, seasonEndTime);
    });

    label.text = moment.unix(seasonEndTime).locale($.Localize("locale")).fromNow();
}

function RankedInfoChanged(info) {
    HallOfFameChanged(info.topPlayers);

    var seasonRewardToShow = info.currentSeason;

    if (moment().isBefore(moment.unix(info.seasonEndTime).subtract(20, "days"))) {
        $("#RankedRewardText").text = $.Localize("InfoRankRewardPrev");

        seasonRewardToShow--;
    }

    $("#RankedRewardImage").SetImage("file://{images}/custom_game/rewards/" + seasonRewardToShow + ".png");
    $("#RankedRewardImage").SetScaling("stretch-to-fit-y-preserve-aspect");
    $("#RankedRewardText").SetDialogVariableInt("season", seasonRewardToShow + 1);
    $("#RankedSeasonEndHeader").SetDialogVariableInt("season", info.currentSeason + 1);
    $("#RankedRewardDateText").text = moment.unix(info.seasonEndTime).locale($.Localize("locale")).format("MMMM Do");

    var parent = $("#RankedSeasonCongratulationsPlayers");

    for (var mode in info.previousTopPlayers) {
        var players = info.previousTopPlayers[mode];

        if (hallOfFamePlayers[mode] == 0) {
            continue;
        }

        for (var i = 0; i < hallOfFamePlayers[mode] && i < players.length; i++) {
            var player = players[i];

            var playerPanel = $.CreatePanel("Panel", parent, "");
            playerPanel.AddClass("RankedSeasonCongratulationsPlayer");

            var avatar = $.CreatePanel("DOTAAvatarImage", playerPanel, "");
            avatar.steamid = player.steamId64.toString();
            avatar.AddClass("RankedSeasonCongratulationsPlayerAvatar");

            var icon = $.CreatePanel("Panel", playerPanel, "");
            icon.AddClass("TopPlayerIcon");
            icon.AddClass("RankedSeasonCongratulationsPlayerIcon");
        }
    }

    UpdateTime($("#RankedSeasonEndText"), info.seasonEndTime);
    $("#RankedInfoLoading").AddClass("Hidden");
    $("#RankedInfoContainer").RemoveClass("Hidden");
}

$.AsyncWebRequest("http://178.63.238.188:3637/ranks/info", { type: "GET", 
    success: function( data ) {
        var info = JSON.parse(data);
        RankedInfoChanged(info);
    }
});

var tips = 6;
var tip = Math.floor(Math.random() * (tips + 1));

$("#GameTipText").SetDialogVariable("tip", $.Localize("GameTip" + tip));
$("#GameTipText").text = $.Localize("GameTip", $("#GameTipText"));

var hittestBlocker = $.GetContextPanel().GetParent().FindChild("SidebarAndBattleCupLayoutContainer");

if (hittestBlocker) {
    hittestBlocker.hittest = false;
    hittestBlocker.hittestchildren = false;
}

GameEvents.Subscribe("game_rules_state_change", function(data) {
    if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD)) {
        $("#RankedInfo").SetHasClass("Hidden", true);
        $("#GameTip").SetHasClass("Hidden", true);
    }
});