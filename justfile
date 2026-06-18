set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
set dotenv-load := true

place:
	rojo build -o build/Place.rbxl
	ropen .\build\Place.rbxl