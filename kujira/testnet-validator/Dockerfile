# syntax=docker/dockerfile-upstream:1-labs
FROM ubuntu:latest

WORKDIR /root

# Dropping default /root/.bashrc because it will return if not running as interactive shell, thus not invoking PATH settings
RUN :> /root/.bashrc

SHELL [ "/bin/bash", "-lc" ]

RUN \
	apt-get update \
	&& apt-get install --no-install-recommends -y \
		ca-certificates \
		openssh-server \
		build-essential \
		git \
		unzip \
		curl \
		wget \
		jq

RUN <<-EOF
	TESTNET_CHAIN_ID="harpoon-4"
	MONIKER_NAME="<moniker>"
	KUJIRA_WALLET_NAME="<wallet>"

	useradd -m -s /bin/bash kuji
	su -s /bin/bash -l kuji

	rm -rvf /usr/local/go/
	wget https://golang.org/dl/go1.18.3.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
	rm go1.18.3.linux-amd64.tar.gz
	echo 'export GOROOT=/usr/local/go' >> ~/.profile
	echo 'export GOPATH=$HOME/go' >> ~/.profile
	echo 'export GO111MODULE=on' >> ~/.profile
	echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.profile
	source ~/.profile

	go version

	git clone https://github.com/Team-Kujira/core $HOME/kujira-core
	cd $HOME/kujira-core
	git checkout v0.8.5
	make install

	kujirad version

	kujirad init "${MONIKER_NAME}" --chain-id ${TESTNET_CHAIN_ID}
	wget "https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/${TESTNET_CHAIN_ID}.json" -O $HOME/.kujira/config/genesis.json
	wget https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/addrbook.json -O $HOME/.kujira/config/addrbook.json
	sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00119ukuji,0.00150factory\/kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7\/uusk,0.00150ibc\/295548A78785A1007F232DE286149A6FF512F180AF5657780FC89C009E2C348F,0.000125ibc\/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2,0.00126ibc\/47BD209179859CDE4A2806763D7189B6E6FE13A17880FE2B42DE1E6C1E329E23,0.00652ibc\/3607EB5B5E64DD1C0E12E07F077FF470D5BC4706AFCBC98FE1BA960E5AE4CE07,617283951ibc\/F3AA7EF

	echo "[Unit]
	Description=Kujira Daemon
	After=network.target

	[Service]
	Type=simple
	User=$USERNAME
	ExecStart=$HOME/go/bin/kujirad start --log_level error
	Restart=on-abort
	LimitNOFILE=65535

	[Install]
	WantedBy=multi-user.target" > kujirad.service

	mv kujirad.service /etc/systemd/system/kujirad.service
	chmod 644 /etc/systemd/system/kujirad.service

	systemctl daemon-reload
	systemctl enable kujirad
	systemctl start kujirad
	systemctl status kujirad.service

	journalctl -u kujirad -f -o cat
EOF

#RUN <<-EOF
#	apt autoremove -y
#
#	apt clean autoclean
#
#	rm -rf \
#		/var/lib/apt/lists/* \
#		/etc/apt/sources.list \
#		/etc/apt/sources.list.d/*
#EOF
