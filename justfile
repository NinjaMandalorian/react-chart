set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
set dotenv-load := true

place:
	rojo build -o build/Place.rbxl
	ropen .\build\Place.rbxl

sourcemap:
	wally install
	rojo sourcemap test.project.json --output sourcemap.json
	wally-package-types --sourcemap sourcemap.json Packages/