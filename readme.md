# Docker

## Hummingbot Installation Guide
It's very recommended to watch this video from the Hummingbot Foundation and their installation guide:
 - https://www.youtube.com/watch?v=t3Su_F_SY_0
 - https://docs.hummingbot.org/installation/
 - https://docs.hummingbot.org/quickstart/

## Prerequisites:
- [Docker](how-to-install-docker.md)

## Client

### Creation

Run:

> ./client/create-client.sh

to create a Client instance. Follow the instructions on the screen.

**Important**: it is needed to be located in the scripts folders, seeing the client folder, otherwise the Dockerfile
will not be able to copy the required files and attach to the required folders.

### Configuration

#### Generate Certificates
From the Hummingbot Client command line type:

> gateway generate-certs

for creating the certificates. Take note about the passphrase used, it is needed for configuring the Gateway.

## Gateway

### Creation

Run:

> ./gateway/create-gateway.sh

to create a Gateway instance. Follow the instructions on the screen
and enter the same passphrase created when configuring the Client.

**Important**: it is needed to be located in the scripts folders, seeing the client folder, otherwise the Dockerfile
will not be able to copy the required files and attach to the required folders.

### Configuration

The Gateway will only start properly if the `./shared/common/certs` contains the certificates
and the informed passphrase is the correct one.

## Running

All the commands given here are for the Hummingbot Client command line.

### Connecting the Wallet
Connect a Kujira wallet with:

> gateway connect kujira

follow the instructions on the screen.

After the wallet configuration check if it is working with:

> balance

You should see the balances of each token you have in your wallet.

**Important**: before running the script, check if you have a minimal balance in the base and quote tokens
of the market. For example, if the market is DEMO-USK, it is needed to have a minimal
amount in DEMO and USK tokens. Also, it is needed to have a minimum amount of KUJI tokens
to pay the transaction fees.

### Adding funds to a Testnet Wallet (optional)

In order to add funds to your wallet, you can use a faucet inside the Kujira Discord.

To join their discord you can use this link:

> https://discord.gg/teamkujira

After joining and doing their verification process, you can look for this channel:

> #public-testnet-faucet

Or try this link:

> https://discord.com/channels/970650215801569330/1009931570263629854

Then you can use the following command there:

> !faucet &lt;change to your kujira wallet address here&gt;

After that you should receive some Kujira tokens on your balance.

If you need more you can contact us here:

> https://discord.gg/6CxA7PWV

### How to use Testnet instead of Mainnet? (optional)

If you would like to start with testnet, which is the recommended, instead of mainnet, 
you can change the network in the file below:

> shared/gateway/conf/kujira.yml

You can also use your preferred RPC if you want.
In this case you'll need to set the "nodeURL" property accordingly.

### Running a PMM Script

Check if the

> ./shared/client/scripts/kujira_pmm_example.py

file has the appropriate configurations.

Then you can start the script as the following:

> start --script kujira_pmm_script_example.py

After that the PMM script will start to run.

It is possible to check the logs on the right side of the Client screen or by the command line with:

> tail -f shared/client/logs/* shared/gateway/logs/*

It's also a good idea to check from the Kujira Fin app if the orders are being created and replaced there
(make sure you're checking the correct network (mainnet or testnet) and the correct RPC (usually located in the bottom of the page)):

> https://fin.kujira.app/

## Running a PMM Strategy

Check if the

> ./shared/client/strategies/kujira_pmm_strategy_example.yml

file has the appropriate configurations.

Import the strategy with:

> import kujira_pmm_strategy_example

And start the strategy with:

> start

Hummingbot might ask if you want to start the strategy, type "Yes".

After that the PMM strategy will start to run.

It is possible to check the logs on the right side of the Client screen or by the command line with:

> tail -f shared/client/logs/* shared/gateway/logs/*

It's also a good idea to check from the Kujira Fin app if the orders are being created and replaced there
(make sure you're checking the correct network (mainnet or testnet) and the correct RPC (usually located in the bottom of the page)):

> https://fin.kujira.app/
