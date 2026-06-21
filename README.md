# react-chart

`react-chart` is a chart library for react-lua in Roblox.

This library provides generic charts of various types to be used in your game.

## Installation

### Wally

react-chart can be installed by adding this to your [wally.toml](https://github.com/UpliftGames/wally) dependencies:

```toml
ReactChart = "NinjaMandalorian/react-chart@0.1.0"
```

## Usage

Require the package from `Packages` and use the relevant component.

### Line Graph Example

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactChart = require(ReplicatedStorage.Packages.ReactChart)

return React.createElement(ReactChart.LineGraph, {
    Data = {
        0, 2, 5, 3, 6, 4, 8,
    },
    Theme = ReactChart.DEFAULT_THEME,
})
```

To plot multiple series, pass a map of series names to point arrays.

```luau
Data = {
    Sales = {
        { X = 1, Y = 10 },
        { X = 2, Y = 14 },
        { X = 3, Y = 18 },
    },
    Forecast = {
        { X = 1, Y = 8 },
        { X = 2, Y = 12 },
        { X = 3, Y = 16 },
    },
}
```

## Credits

- [Boatbomber's GraphModule](https://github.com/boatbomber/GraphModule/) - Line chart design
- [Pyseph's PacketProfiler](https://github.com/Pyseph/PacketProfiler) - Pie chart design
