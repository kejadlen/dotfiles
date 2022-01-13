.PHONY: subterranean-animism
subterranean-animism:
	rsync --recursive --perms --compress --delete --progress --human-readable \
		subterranean-animism/*.nix subterranean-animism:/etc/nixos
	rsync --perms --compress --progress --human-readable \
		subterranean-animism/private/* subterranean-animism:/etc/nixos
	ssh subterranean-animism chown mysql:mysql /etc/nixos/mysql-config
	ssh subterranean-animism nixos-rebuild switch
