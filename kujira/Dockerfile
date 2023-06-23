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
		wget

RUN <<-EOF
	useradd -m -s /bin/bash kuji

	# remove old go version
	rm -rvf /usr/local/go/

	# download and install recent go version
	curl -fsSL https://golang.org/dl/go1.18.5.linux-amd64.tar.gz | tar -xzC /usr/local

	# remove unneeded installer
	rm go1.18.5.linux-amd64.tar.gz

	su -l kuji

	# source go
	cat <<FILE >> ~/.profile
	export GOROOT=/usr/local/go
	export GOPATH=$HOME/go
	export GO111MODULE=on
	export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
	FILE
	source ~/.profile
	go version

	git clone https://github.com/Team-Kujira/core $HOME/kujira-core
	cd $HOME/kujira-core
	git checkout v0.8.5
	make install

	kujirad version
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

CMD ["yarn", "start"]
