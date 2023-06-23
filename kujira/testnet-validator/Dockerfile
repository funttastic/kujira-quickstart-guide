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
		systemd \
		sudo \
		git \
		unzip \
		curl \
		wget \
		jq \
		vim

RUN <<-EOF
	TESTNET_CHAIN_ID="harpoon-4"
	MONIKER_NAME="funttastic"

	useradd -m -s /bin/bash kuji

	rm -rvf /usr/local/go/
	wget https://golang.org/dl/go1.18.3.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
	rm go1.18.3.linux-amd64.tar.gz

	su -s /bin/bash -l kuji

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

	kujirad config chain-id ${TESTNET_CHAIN_ID}

	kujirad init "${MONIKER_NAME}" --chain-id ${TESTNET_CHAIN_ID}
	wget "https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/${TESTNET_CHAIN_ID}.json" -O $HOME/.kujira/config/genesis.json
	wget https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/addrbook.json -O $HOME/.kujira/config/addrbook.json

	sed -i 's/^timeout_commit =.*/timeout_commit = "1500ms"/' $HOME/.kujira/config/config.toml
	sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00119ukuji,0.00150ibc\/295548A78785A1007F232DE286149A6FF512F180AF5657780FC89C009E2C348F,0.000125ibc\/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2,0.00126ibc\/47BD209179859CDE4A2806763D7189B6E6FE13A17880FE2B42DE1E6C1E329E23,0.00652ibc\/3607EB5B5E64DD1C0E12E07F077FF470D5BC4706AFCBC98FE1BA960E5AE4CE07,617283951ibc\/F3AA7EF362EC5E791FE78A0F4CCC69FEE1F9A7485EB1A8CAB3F6601C00522F10,0.000288ibc\/EFF323CC632EC4F747C61BCE238A758EFDB7699C3226565F7C20DA06509D59A5,5ibc\/DA59C009A0B3B95E0549E6BF7B075C8239285989FF457A8EDDBB56F10B2A6986,0.00137ibc\/A358D7F19237777AF6D8AD0E0F53268F8B18AE8A53ED318095C14D6D7F3B2DB5,0.0488ibc\/4F393C3FCA4190C0A6756CE7F6D897D5D1BE57D6CCB80D0BC87393566A7B6602,78492936ibc\/004EBF085BBED1029326D56BE8A2E67C08CECE670A94AC1947DF413EF5130EB2,964351ibc\/1B38805B1C75352B28169284F96DF56BDEBD9E8FAC005BDCC8CF0378C82AA8E7\"/;" $HOME/.kujira/config/app.toml
	sed -i 's/^seeds =.*/seeds = "63158c2af0d639d8105a8e6ca2c53dc243dd156f@seed.kujira.mintserve.org:31897,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:18656"/' $HOME/.kujira/config/config.toml
EOF

RUN <<-EOF
	echo "[Unit]
	Description=Kujira Daemon
	After=network.target

	[Service]
	Type=simple
	User=kuji
	ExecStart=/home/kuji/go/bin/kujirad start
	Restart=on-abort
	LimitNOFILE=65535

	[Install]
	WantedBy=multi-user.target" > kujirad.service

	sudo mv kujirad.service /etc/systemd/system/kujirad.service
	sudo chmod 644 /etc/systemd/system/kujirad.service

	sudo systemctl daemon-reload
	sudo systemctl enable kujirad
	sudo systemctl start kujirad
	sudo systemctl status kujirad.service

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
