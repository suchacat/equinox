{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
	nativeBuildInputs = with pkgs.buildPackages; [
		pkg-config
		clang
		lxc
		curl.dev
		openssl
	];
}
