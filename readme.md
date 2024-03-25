# Funttastic + Kujira + Hummingbot

## Hummingbot Installation Guide

It's very recommended to watch this video from the Hummingbot Foundation and their installation guide:

- <a href="https://docs.hummingbot.org/installation/" target="_blank">Hummingbot Docs</a>
- <a href="https://www.youtube.com/watch?v=t3Su_F_SY_0" target="_blank">Hummingbot Guide (Video Tutorial)</a>
- <a href="https://www.youtube.com/watch?v=NubBPj3N0RE" target="_blank">Kujira Connector for Hummingbot (Video Demonstration)</a>

## Prerequisites:

- \*nix OS (Linux, Unix, macOS) or <a href="https://learn.microsoft.com/en-us/windows/wsl/install" target="_blank">WSL</a> (for Windows)
- <a href="https://docs.docker.com/engine/install/" target="_blank">Docker</a>
- <a href="https://www.coingecko.com/en/api/pricing" target="_blank">CoinGecko API Key</a>
  - You will need a CoinGecko API key so the trading bot can get up-to-date information about tokens and markets, such as the current prices. Access the link to create a demo account and get a free API key.
- Kujira wallet and mnemonic
  - You will need a Kujira wallet and its mnemonic. You can create a new wallet using wallet apps like: <a href="https://www.keplr.app/download" target="_blank">Keplr</a>, <a href="https://sonar.kujira.network/" target="_blank">Sonar</a>, <a href="https://setup-station.terra.money/" target="_blank">Station</a>, <a href="https://www.leapwallet.io/download" target="_blank">Leap</a> and <a href="https://www.xdefi.io/" target="_blank">XDEFI Wallet</a>.
- (Optional) <a href="https://core.telegram.org/bots/features#botfather" target="_blank">Telegram bot</a>
  - You can operate your bot through Telegram, for that you need to <a href="https://core.telegram.org/bots/features#botfather" target="_blank">create a bot</a> and a new channel.
  - You will need the telegram bot token and the channel chat id.

## Installation

<img src="assets/images/Funttastic_Kujira_Hummingbot.png">

### Code

> git clone <a href="https://github.com/funttastic/kujira-quickstart-guide.git" target="_blank">https://github.com/funttastic/kujira-quickstart-guide.git</a>
>
> cd kujira-quickstart-guide
>
> ./configure

### Adding a Kujira wallet

The easiest way is to use our helper script:

> ./configure

and go to the "Actions", then "Add Wallet".

You will need to inform your mnemonic, then your wallet will be encrypted and saved in this folder:

> shared/hummingbot/gateway/conf/wallets/kujira

You can also do that using the Hummingbot Client terminal or calling the Hummingbot Gateway or Funttastic Humminbot Client API directly
(for example using curl or Postman).

### Configuring your strategy and workers

You need to navigate to

> shared/funttastic/client/resources/strategies/pure_market_making/1.0.0

there you can configure you Supervisor (`supervisor.yml`) and your workers (`workers/01.yml`, etc.).

You can use the `workers/common.yml` file if you want a configuration to be replicated to all your workers.
If a specific worker has a different configuration, the worker configuration will then apply.

## Extra (optional)

### More tutorial videos

You can access our playlist explaining how to configure several aspects for the bot:

> <a href="https://www.youtube.com/playlist?list=PLmJF3KyUOI1zgFBoQ0AzP9kt40Vjk2srp" target="_blank">More tutorial videos</a>

### Configuring a telegram integration

Open the following configuration file:

> shared/funttastic/client/resources/configuration/production.yml

You are enabling telegram, we recommend changing to `true` the following:

> logging.use_telegram
>
> telegram.enabled
>
> telegram.listen_commands

Add your telegram token to:

> telegram.token

and your telegram channel chat id to:

> telegram.chat_id

### Adding funds to a testnet wallet

In order to add funds to your wallet, you can use a faucet inside the Kujira Discord.

To join their discord you can use this link:

> <a href="https://discord.gg/teamkujira" target="_blank">https://discord.gg/teamkujira</a>

After joining and doing their verification process, you can look for this channel:

> #public-testnet-faucet

Or try this link:

> <a href="https://discord.com/channels/970650215801569330/1009931570263629854" target="_blank">https://discord.com/channels/970650215801569330/1009931570263629854</a>

Then you can use the following command there:

> !faucet &lt;change to your Kujira wallet address here&gt;

After that you should receive some Kujira tokens on your balance.

## How to contact us

If you need more info you can contact us here:

> <a href="https://funttastic.com/discord" target="_blank">https://funttastic.com/discord</a>
