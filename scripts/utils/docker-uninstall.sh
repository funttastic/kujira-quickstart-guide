#!/bin/bash

echo
echo "    ==================== REMOVING DOCKER ===================="
echo
echo "    Note: You need superuser privileges to uninstall Docker."
echo

read -p "    Are you sure you want to remove Docker and all related files? [y/N]: " confirm
confirm=${confirm:-N}

if [[ $confirm =~ ^[Yy]$ ]]; then
	OS="$(uname -s)"

	echo

	case "$OS" in
	Linux*)
		sudo apt-get purge -y docker-buildx-plugin docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose-plugin
		sudo apt-get autoremove -y docker-buildx-plugin docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose-plugin
		sudo rm -rf /var/lib/docker /etc/docker
		sudo rm /etc/apparmor.d/docker
		sudo groupdel docker
		sudo rm -rf /var/run/docker.sock
		;;
	Darwin*)
		echo
		echo "    To remove Docker on macOS, drag the Docker application to the trash."
		echo
		;;
	*)
		echo
		echo "    Operating system not supported."
		echo
		;;
	esac

	echo
	read -p "    Do you want to remove residual Docker files?
		Be cautious, and make sure you are certain before proceeding. [y/N]: " remove_residual
	remove_residual=${remove_residual:-N}

	if [[ $remove_residual =~ ^[Yy]$ ]]; then
		echo
		echo "    Removing residual Docker files..."
		echo
		sudo find / -name '*docker*' -exec rm -rf {} +
	else
		echo
		echo "    Skipping removal of residual files."
		echo
	fi

else
	echo
	echo "    Operation aborted."
	echo
fi
