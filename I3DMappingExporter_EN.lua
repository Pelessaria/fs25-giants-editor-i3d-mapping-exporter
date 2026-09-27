-- Author: [FD] Pelessaria
-- Name: I3D Mapping Exporter (EN)
-- Description: Exports i3dMappings and updates an existing target XML.
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAJASURBVDhPjZJbaJJxGMb/N0U3u+h4G3QRne66iho1g+gmiNaRwUbQVQWSWTGINloHVxusHXJan47ZynRbs+2jMdu82CHIraKGmaBliYpumsfvqE+oTfzcoj3wwMv/5f39eR9eQnLadWotIWT9Kryy9h2/JO8w0Ivdz4b/6Uc9rxf3n1T0E0LWlc8T2RlFE/4jhuOh0tFoUr8aWAY5dFrRkGBFCBwLIQuILIsUwyOTEZFIMeAEEW6vHxrzBCJZ4J62DJIDpAQgGQ2iz2TB1KwD7Wo9HvcO4mYrBaPtI9zhNJR3n0BjHoOKonGgWj649WBdAbIE4OJhtNx/CssHJyiqEydqb+NWhw6qHgvsPyLwh6PweP3wBUJ42G3iSUXFxiIgLWQRCXjh8vjgcn3DZ4cTY5N2ONzfYbVOQDcyC7YkE+rlmwghZEMREEuLJe2CsgACMaH8OS/tc1oKiDNSQJwVUauxY0+9FYbpn5JeTssAib8Az+8o4jyLyS+/sO0KjU0XR1Cnflc+LwXIziobRAEYcDuxXd+FI6ZeUMPjaKOdkPfNo2voPWZso2CmVWDmjQXAi5IMlgDKqXGsabuDLepWzIUDkh+9Q1cRat6McOdugPVA22+TrsDzWXyNLuD8qAUP7DNgRWkm3Cc9Qu07EDEcBYQFaE1vpQBm5bClCs4BSV++pIwlK1RWy5uDMQFJVkSayyLFZvK1xByQygDJ3MWyGbRozCge0k7ZhcqqmvrGqnPXVuXDNTca9x67fD13yn8AoKeQ/zFhq90AAAAASUVORK5CYII=
-- Hide: no
-- AlwaysLoaded: no
-- Namespace: local
--
if XMLFile == nil then
    source("EditorSettings.lua")
end

-- GIANTS Editor 10.0.13: Place the Lua, BAT, and PS1 files together in the Editor scripts folder
-- then start I3D Mapping Exporter (EN) from the Scripts menu.
-- Use "Copy mappings" to copy the generated output to the clipboard.

I3DMappingExporter = {}
I3DMappingExporter.WINDOW_WIDTH = 820
I3DMappingExporter.WINDOW_HEIGHT = 600
I3DMappingExporter.LANGUAGE = "en"

function I3DMappingExporter.new()
    if g_i3dMappingExporter ~= nil then
        g_i3dMappingExporter:close()
    end

    local self = setmetatable({}, { __index = I3DMappingExporter })
    self.window = nil
    self.outputArea = nil
    self.excludeWrapperCheckbox = nil
    self.generatedXml = ""
    self.generatedMappings = {}
    self.currentSceneFilename = nil
    self.targetXmlFilename = ""
    self:refreshProjectSettings()

    self:generateUI()
    g_i3dMappingExporter = self
    return self
end

function I3DMappingExporter:generateUI()
    local windowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(windowSizer, "I3D Mapping Exporter (EN)")

    local contentSizer = UIRowLayoutSizer.new()
    UIPanel.new(windowSizer, contentSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local outputSizer = UIRowLayoutSizer.new()
    UIPanel.new(contentSizer, outputSizer, -1, -1,
        I3DMappingExporter.WINDOW_WIDTH, 430,
        BorderDirection.ALL, 10, 1)

    self.outputArea = UITextArea.new(
        outputSizer,
        "Choose \"Generate from all nodes\" or \"Generate from selection\"." .. "\n" ..
        "Generated mappings will appear here.",
        TextAlignment.LEFT,
        false,
        true,
        -1, -1,
        I3DMappingExporter.WINDOW_WIDTH, 430,
        BorderDirection.ALL, 1, 1)

    UIHorizontalLine.new(contentSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)

    local buttonSizer = UIRowLayoutSizer.new()
    UIPanel.new(contentSizer, buttonSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)

    local targetRowSizer = UIRowLayoutSizer.new()
    UIPanel.new(buttonSizer, targetRowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8, 1)

    local targetPathSizer = UIColumnLayoutSizer.new()
    UIPanel.new(targetRowSizer, targetPathSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4, 1)
    UILabel.new(targetPathSizer, "Target XML:", false, TextAlignment.LEFT, VerticalAlignment.TOP,
        -1, -1, 85, -1, BorderDirection.RIGHT, 5)
    self.targetFileArea = UITextArea.new(
        targetPathSizer,
        self.targetXmlFilename,
        TextAlignment.LEFT,
        true,
        false,
        -1, -1, -1, 28,
        BorderDirection.NONE, 0, 1)
    UIButton.new(targetRowSizer, "Choose XML",
        function() self:chooseTargetXml() end, nil,
        -1, -1, 135, 30, BorderDirection.BOTTOM, 0, 1)

    local actionRowSizer = UIColumnLayoutSizer.new()
    UIPanel.new(buttonSizer, actionRowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UIButton.new(actionRowSizer, "Generate from all nodes",
        function() self:exportAllNodes() end, nil,
        -1, -1, 175, 35, BorderDirection.RIGHT, 5, 1)
    UIButton.new(actionRowSizer, "Generate from selection",
        function() self:exportSelection() end, nil,
        -1, -1, 180, 35, BorderDirection.RIGHT, 5, 1)
    UIButton.new(actionRowSizer, "Copy mappings",
        function() self:copyXml() end, nil,
        -1, -1, 155, 35, BorderDirection.RIGHT, 5, 1)
    UIButton.new(actionRowSizer, "Update XML",
        function() self:updateTargetXml() end, nil,
        -1, -1, 165, 35, BorderDirection.RIGHT, 5, 1)
    UIButton.new(actionRowSizer, "Close",
        function() self:close() end, nil,
        -1, -1, 100, 35, BorderDirection.NONE, 0, 1)

    local footerSizer = UIColumnLayoutSizer.new()
    UIPanel.new(buttonSizer, footerSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    self.statusArea = UITextArea.new(
        footerSizer,
        "Select a target XML for this I3D.",
        TextAlignment.LEFT,
        true,
        false,
        -1, -1, -1, 24,
        BorderDirection.RIGHT, 5, 1)
    self.excludeWrapperCheckbox = UICheckBox.new(
        footerSizer,
        "Omit the <i3dMappings> wrapper",
        -1, -1, 275, 30, BorderDirection.LEFT, 5, 0)
    self.excludeWrapperCheckbox:setValue(true)
    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()
end
function I3DMappingExporter:exportAllNodes()
    self:refreshProjectSettings()
    local rootNode = getRootNode()
    local nodes = {}

    if rootNode == nil or rootNode == 0 then
        self.generatedXml = ""
        self.generatedMappings = {}
        self.outputArea:setValue("No i3d scene is loaded.")
        return
    end

    local function collectChildren(parentNode)
        local childCount = getNumOfChildren(parentNode)
        for childIndex = 0, childCount - 1 do
            local childNode = getChildAt(parentNode, childIndex)
            if childNode ~= nil and childNode ~= 0 then
                nodes[#nodes + 1] = childNode
                collectChildren(childNode)
            end
        end
    end

    collectChildren(rootNode)
    self:showNodes(nodes, rootNode)
end

function I3DMappingExporter:exportSelection()
    self:refreshProjectSettings()
    local selectedNodes = {}
    local seenNodes = {}
    local selectionCount = getNumSelected()

    for selectionIndex = 0, selectionCount - 1 do
        local node = getSelection(selectionIndex)
        if node ~= nil and node ~= 0 and not seenNodes[node] then
            selectedNodes[#selectedNodes + 1] = node
            seenNodes[node] = true
        end
    end

    if #selectedNodes == 0 then
        self.generatedXml = ""
        self.generatedMappings = {}
        self.outputArea:setValue("No nodes are selected.\nSelect one or more nodes in the Scenegraph first.")
        self:setStatus("No nodes are selected.")
        return
    end

    self:showNodes(selectedNodes, getRootNode())
end

function I3DMappingExporter:showNodes(nodes, rootNode)
    local usedIds = {}
    local lines = {}
    local mappings = {}
    local skippedCount = 0

    for _, node in ipairs(nodes) do
        local nodePath = I3DMappingExporter.getNodePath(node, rootNode)
        if nodePath ~= nil then
            local mappingId = I3DMappingExporter.getUniqueMappingId(getName(node), usedIds)
            mappings[#mappings + 1] = {
                id = mappingId,
                node = nodePath
            }
            lines[#lines + 1] = string.format(
                '    <i3dMapping id="%s" node="%s" />',
                I3DMappingExporter.xmlEscape(mappingId),
                I3DMappingExporter.xmlEscape(nodePath))
        else
            skippedCount = skippedCount + 1
        end
    end

    self.generatedMappings = mappings
    local xmlBody = table.concat(lines, "\n")
    if self.excludeWrapperCheckbox:getValue() then
        self.generatedXml = xmlBody
    elseif xmlBody == "" then
        self.generatedXml = "<i3dMappings>\n</i3dMappings>"
    else
        self.generatedXml = "<i3dMappings>\n" .. xmlBody .. "\n</i3dMappings>"
    end

    if skippedCount > 0 then
        print(string.format("I3D Mapping Exporter: %d node(s) without a valid path were skipped.", skippedCount))
    end

    self.outputArea:setValue(self.generatedXml)
    self:setStatus(string.format("%d mapping(s) ready.", #mappings))
end

function I3DMappingExporter:getProjectSettingsFilename()
    if self.currentSceneFilename == nil or self.currentSceneFilename == "" then
        return nil
    end

    return self.currentSceneFilename .. ".i3dMappingExporter.xml"
end

function I3DMappingExporter:refreshProjectSettings()
    local sceneFilename = getSceneFilename()
    if sceneFilename == nil then
        sceneFilename = ""
    end

    if sceneFilename == self.currentSceneFilename then
        return
    end

    self.currentSceneFilename = sceneFilename
    self.targetXmlFilename = ""
    self.generatedMappings = {}
    self.generatedXml = ""

    local settingsFilename = self:getProjectSettingsFilename()
    if settingsFilename ~= nil and fileExists(settingsFilename) then
        local settingsFile = XMLFile.loadIfExists("i3dMappingExporterSettings", settingsFilename)
        if settingsFile ~= nil then
            self.targetXmlFilename = settingsFile:getString("i3dMappingExporterSettings#targetXml") or ""
            settingsFile:delete()
        end
    end

    if self.targetFileArea ~= nil then
        self.targetFileArea:setValue(self.targetXmlFilename)
    end
    if self.outputArea ~= nil then
        self.outputArea:setValue("Choose \"Generate from all nodes\" or \"Generate from selection\"." .. "\n" ..
            "The generated XML will appear here.")
    end
    self:setStatus("Target XML loaded for the open i3d.")
end

function I3DMappingExporter:saveProjectSettings()
    local settingsFilename = self:getProjectSettingsFilename()
    if settingsFilename == nil then
        return false
    end

    local settingsFile = XMLFile.loadIfExists("i3dMappingExporterSettings", settingsFilename)
    if settingsFile == nil then
        settingsFile = XMLFile.create("i3dMappingExporterSettings", settingsFilename, "i3dMappingExporterSettings")
    end
    if settingsFile == nil then
        return false
    end

    settingsFile:setString("i3dMappingExporterSettings#targetXml", self.targetXmlFilename)
    settingsFile:save()
    settingsFile:delete()
    return true
end

function I3DMappingExporter:setStatus(message)
    if self.statusArea ~= nil then
        self.statusArea:setValue(message)
    end
end

function I3DMappingExporter:chooseTargetXml()
    self:refreshProjectSettings()

    if self.currentSceneFilename == "" then
        self:setStatus("No i3d scene is open.")
        return
    end

    local initialFilename = self.targetXmlFilename
    if initialFilename == "" then
        initialFilename = self.currentSceneFilename
    end

    local filename = openFileDialog(initialFilename, "XML Files|*.xml")
    if filename == nil or filename == "" then
        return
    end

    self.targetXmlFilename = filename
    if self.targetFileArea ~= nil then
        self.targetFileArea:setValue(filename)
    end

    if self:saveProjectSettings() then
        self:setStatus("Target XML saved as a project setting.")
    else
        self:setStatus("Target selected, but the project setting could not be saved.")
    end
end

function I3DMappingExporter:updateTargetXml()
    self:refreshProjectSettings()

    if #self.generatedMappings == 0 then
        self:setStatus("Generate mappings first; there are no mappings to update.")
        return
    end
    if self.targetXmlFilename == "" then
        self:setStatus("Select an existing target XML first.")
        return
    end
    if not fileExists(self.targetXmlFilename) then
        self:setStatus("The selected XML file was not found.")
        return
    end

    if type(execute) ~= "function" or type(setClipboard) ~= "function" then
        self:setStatus("The GE execute or setClipboard function is unavailable.")
        return
    end

    -- Custom GE scripts are stored under AppData, not necessarily in the installation folder.
    local scriptsDirectory = nil
    if type(getAppDataPath) == "function" then
        scriptsDirectory = getAppDataPath() .. "scripts/"
    elseif type(getEditorDirectory) == "function" then
        scriptsDirectory = getEditorDirectory() .. "scripts/"
    end
    if scriptsDirectory == nil then
        self:setStatus("Could not locate the GE scripts folder.")
        return
    end

    local batchFilename = scriptsDirectory .. "I3DMappingExporterUpdate.bat"
    local powershellFilename = scriptsDirectory .. "I3DMappingExporterUpdate.ps1"
    if not fileExists(batchFilename) or not fileExists(powershellFilename) then
        self:setStatus("Updater files are missing. Place the BAT and PS1 beside the Lua script in the GE scripts folder.")
        return
    end

    -- The GE XML serializer rewrites the entire file and removes formatting whitespace.
    -- The external helper edits the XML text directly to preserve formatting.
    local clipboardText = self.generatedXml:match("^(.*%S)%s*$") or self.generatedXml
    setClipboard(clipboardText .. "\0")

    -- GE execute starts the batch file; it reads the mappings from the
    -- clipboard and updates the selected XML as raw text.
    local languageArgument = I3DMappingExporter.LANGUAGE or "de"
    local arguments = '"' .. self.targetXmlFilename .. '" "' .. languageArgument .. '"'
    execute(batchFilename, arguments, scriptsDirectory, false)
    self:setStatus("XML update started. The result will appear in a message box.")
end

function I3DMappingExporter:copyXml()
    if self.generatedXml == "" then
        print("I3D Mapping Exporter: Generate mappings first.")
        return
    end

    if type(setClipboard) == "function" then
        -- GE-Clipboard erwartet einen eindeutig abgeschlossenen Textpuffer.
        local clipboardText = self.generatedXml:match("^(.*%S)%s*$") or self.generatedXml
        setClipboard(clipboardText .. "\0")
        print("I3D Mapping Exporter: XML was copied to the clipboard.")
    else
        print("I3D Mapping Exporter: setClipboard is unavailable in this Editor version.")
    end
end

function I3DMappingExporter.getNodePath(node, rootNode)
    if node == rootNode then
        return nil
    end

    local indices = {}
    local currentNode = node
    local steps = 0

    while currentNode ~= nil and currentNode ~= 0 and currentNode ~= rootNode do
        local index = getChildIndex(currentNode)
        if index == nil or index < 0 then
            return nil
        end

        table.insert(indices, 1, tostring(index))
        currentNode = getParent(currentNode)
        steps = steps + 1

        -- Prevents infinite loops for invalid or unexpected node handles.
        if steps > 1024 then
            return nil
        end
    end

    if currentNode ~= rootNode or #indices == 0 then
        return nil
    end

    -- GIANTS node paths start with the first index before the '>'.
    if #indices == 1 then
        return indices[1] .. ">"
    end

    return indices[1] .. ">" .. table.concat(indices, "|", 2)
end

function I3DMappingExporter.getUniqueMappingId(nodeName, usedIds)
    local baseId = tostring(nodeName or "node")
    baseId = baseId:gsub("^%s+", ""):gsub("%s+$", "")
    baseId = baseId:gsub("[^%w_%.%-]", "_")

    if baseId == "" then
        baseId = "node"
    end

    if not baseId:match("^[%a_]") then
        baseId = "node_" .. baseId
    end

    local mappingId = baseId
    local suffix = 1
    while usedIds[mappingId] do
        suffix = suffix + 1
        mappingId = baseId .. string.format("_%02d", suffix)
    end

    usedIds[mappingId] = true
    return mappingId
end

function I3DMappingExporter.xmlEscape(value)
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub('"', "&quot;")
        :gsub("<", "&lt;")
        :gsub("'", "&apos;")
end

function I3DMappingExporter:close()
    if self.window ~= nil then
        self.window:close()
    end
end

function I3DMappingExporter:onClose()
    if g_i3dMappingExporter == self then
        g_i3dMappingExporter = nil
    end
end

I3DMappingExporter.new()