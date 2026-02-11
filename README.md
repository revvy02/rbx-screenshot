# rbx-screenshot

Capture screenshots from Roblox Studio via CLI. Requires a running [rodeo](https://github.com/revvy02/rodeo) server.

## Usage

Start a rodeo server:

```sh
rodeo serve
```

Take a screenshot:

```sh
rbx-screenshot --cframe "CFrame.new(0, 10, 0)" --fov 35 --focus "CFrame.new(0, 0, 0)" --settle 0.5 --output "screenshot.png"
```

## Options

| Flag | Description |
|------|-------------|
| `--cframe <expr>` | Luau CFrame expression for camera position |
| `--fov <number>` | Camera field of view |
| `--focus <expr>` | Luau CFrame expression for camera focus |
| `--skew <expr>` | Luau CFrame expression applied to camera each frame |
| `--settle <seconds>` | Wait time before capture (for scene stability) |
| `-o, --output <path>` | Output file path (default: `.rodeo-screenshots/<id>.png`) |
