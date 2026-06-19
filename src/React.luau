local module = script.Parent.Parent:FindFirstChild("React")
if module then
	return require(module :: any)
end

error("React module not found. Please ensure it is installed in Packages.")