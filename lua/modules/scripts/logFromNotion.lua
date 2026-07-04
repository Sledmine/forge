local glue = require "lua.glue"
local inspect = require "lua.inspect"
local currentVersion = require "lua.forge.version"
local csv = require "lua.scripts.modules.csv"

-- TODO Add argparse to simply script interaction

---@class task
---@field name string
---@field type string
---@field property string
---@field status string
---@field version string
---@field pic string
-- TODO Add date created property

---@type task[]
local changes = {}

-- TODO Automate Notion task dump
---@type string | nil
local changesCsv = glue.readfile("temp/notion.csv", "t"):sub(4):gsub(" 🙌", "")

local file = csv.openstring(changesCsv)

local row = 0
local headers = {}
for fields in file:lines() do
    row = row + 1
    local task
    for i, v in ipairs(fields) do
        -- print(i, v)
        if (row == 1) then
            headers[i] = v:lower()
        else
            if (not task) then
                task = {}
            end
            task[headers[i]] = v
        end
    end
    if (task) then
        glue.append(changes, task)
    end
end

-- TODO Generate specific markdown titles for every task type
local changesMd = ""
for k, task in pairs(changes) do
    if ((task.type == "Client Code" or task.type == "Server Code" or task.type ==
        "Server and Client Code") and task.version == currentVersion and task.status ==
        "Done") then
        changesMd = changesMd .. "- " ..
                        task.name:gsub("Add ", "Added "):gsub("Port ", "Ported ")
                            :gsub("Create ", "Created "):gsub("Update ", "Updated ")
                            :gsub("Replace ", "Replaced "):gsub("Rename ", "Renamed ")
                            :gsub("Restore ", "Restored ") .. "\n"
    end
end

print(changesMd)
glue.writefile("temp/changes.md", changesMd, "t")