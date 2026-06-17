--- @sync entry

local function config_path()
	local home = os.getenv("HOME") or ""
	return home .. "/.config/yazi/yazi.toml"
end

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function write_file(path, content)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return true
end

local function save()
	local r = rt.mgr.ratio
	local ratio = string.format("ratio = [%d, %d, %d]", r.parent, r.current, r.preview)
	local path = config_path()
	local content = read_file(path)

	if not content then
		ya.notify { title = "save-ratio", content = "Cannot read yazi.toml", timeout = 3, level = "error" }
		return false
	end

	local new, n = content:gsub("ratio%s*=%s*%[[^\n%]]+%]", ratio, 1)
	if n == 0 then
		new = content:gsub("%[mgr%]\s*\n", "%0" .. ratio .. "\n", 1)
	end

	if write_file(path, new) then
		ya.notify { title = "save-ratio", content = "Saved " .. ratio, timeout = 1 }
		return true
	end

	ya.notify { title = "save-ratio", content = "Cannot write yazi.toml", timeout = 3, level = "error" }
	return false
end

local function entry(_, job)
	local args = job and job.args or {}
	save()
	if args[1] == "quit" then
		ya.emit("quit", {})
	end
end

return { entry = entry }
