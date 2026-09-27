-- Author: [FD] Pelessaria
-- Name: I3D Mapping Exporter
-- Description: Erstellt i3dMappings fuer alle Nodes oder die aktuelle Selektion.
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAJASURBVDhPjZJbaJJxGMb/N0U3u+h4G3QRne66iho1g+gmiNaRwUbQVQWSWTGINloHVxusHXJan47ZynRbs+2jMdu82CHIraKGmaBliYpumsfvqE+oTfzcoj3wwMv/5f39eR9eQnLadWotIWT9Kryy9h2/JO8w0Ivdz4b/6Uc9rxf3n1T0E0LWlc8T2RlFE/4jhuOh0tFoUr8aWAY5dFrRkGBFCBwLIQuILIsUwyOTEZFIMeAEEW6vHxrzBCJZ4J62DJIDpAQgGQ2iz2TB1KwD7Wo9HvcO4mYrBaPtI9zhNJR3n0BjHoOKonGgWj649WBdAbIE4OJhtNx/CssHJyiqEydqb+NWhw6qHgvsPyLwh6PweP3wBUJ42G3iSUXFxiIgLWQRCXjh8vjgcn3DZ4cTY5N2ONzfYbVOQDcyC7YkE+rlmwghZEMREEuLJe2CsgACMaH8OS/tc1oKiDNSQJwVUauxY0+9FYbpn5JeTssAib8Az+8o4jyLyS+/sO0KjU0XR1Cnflc+LwXIziobRAEYcDuxXd+FI6ZeUMPjaKOdkPfNo2voPWZso2CmVWDmjQXAi5IMlgDKqXGsabuDLepWzIUDkh+9Q1cRat6McOdugPVA22+TrsDzWXyNLuD8qAUP7DNgRWkm3Cc9Qu07EDEcBYQFaE1vpQBm5bClCs4BSV++pIwlK1RWy5uDMQFJVkSayyLFZvK1xByQygDJ3MWyGbRozCge0k7ZhcqqmvrGqnPXVuXDNTca9x67fD13yn8AoKeQ/zFhq90AAAAASUVORK5CYII=
-- Hide: no
-- AlwaysLoaded: no
-- Namespace: local
--
-- GIANTS Editor 10.0.13: Diese Datei in den scripts-Ordner des Editors legen
-- und ueber das Menue Scripts -> I3D Mapping Exporter starten.
-- Die Ausgabe kann per "XML kopieren" in die Zwischenablage uebernommen werden.

I3DMappingExporter = {}
I3DMappingExporter.WINDOW_WIDTH = 820
I3DMappingExporter.WINDOW_HEIGHT = 540

function I3DMappingExporter.new()
    if g_i3dMappingExporter ~= nil then
        g_i3dMappingExporter:close()
    end

    local self = setmetatable({}, { __index = I3DMappingExporter })
    self.window = nil
    self.outputArea = nil
    self.excludeWrapperCheckbox = nil
    self.generatedXml = ""

    self:generateUI()
    g_i3dMappingExporter = self
    return self
end

function I3DMappingExporter:generateUI()
    local windowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(windowSizer, "I3D Mapping Exporter")

    local contentSizer = UIRowLayoutSizer.new()
    UIPanel.new(windowSizer, contentSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local outputSizer = UIRowLayoutSizer.new()
    UIPanel.new(contentSizer, outputSizer, -1, -1,
        I3DMappingExporter.WINDOW_WIDTH, I3DMappingExporter.WINDOW_HEIGHT,
        BorderDirection.ALL, 10, 1)

    self.outputArea = UITextArea.new(
        outputSizer,
        "Waehle \"Alle Nodes exportieren\" oder \"Selektion exportieren\".\n" ..
        "Die XML-Ausgabe erscheint hier.",
        TextAlignment.LEFT,
        false,
        true,
        -1, -1,
        I3DMappingExporter.WINDOW_WIDTH, I3DMappingExporter.WINDOW_HEIGHT,
        BorderDirection.ALL, 1, 1)

    local buttonSizer = UIColumnLayoutSizer.new()
    UIPanel.new(contentSizer, buttonSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)

    self.excludeWrapperCheckbox = UICheckBox.new(
        buttonSizer,
        "Oberklasse <i3dMappings> weglassen",
        -1, -1, -1, 35, BorderDirection.LEFT, 10, 1)

    UIButton.new(buttonSizer, "Alle Nodes exportieren",
        function() self:exportAllNodes() end, nil,
        -1, -1, -1, 35, BorderDirection.LEFT, 10, 1)

    UIButton.new(buttonSizer, "Selektion exportieren",
        function() self:exportSelection() end, nil,
        -1, -1, -1, 35, BorderDirection.LEFT, 10, 1)

    UIButton.new(buttonSizer, "XML kopieren",
        function() self:copyXml() end, nil,
        -1, -1, -1, 35, BorderDirection.RIGHT, 10, 1)

    UIButton.new(buttonSizer, "Schliessen",
        function() self:close() end, nil,
        -1, -1, -1, 35, BorderDirection.RIGHT, 10, 1)

    self.window:setOnCloseCallback(function() self:onClose() end)
    self.window:showWindow()
end

function I3DMappingExporter:exportAllNodes()
    local rootNode = getRootNode()
    local nodes = {}

    if rootNode == nil or rootNode == 0 then
        self.generatedXml = ""
        self.outputArea:setValue("Keine geladene i3d-Szene gefunden.")
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
        self.outputArea:setValue("Keine Nodes ausgewaehlt.\nBitte zuerst einen oder mehrere Nodes im Scenegraph auswaehlen.")
        return
    end

    self:showNodes(selectedNodes, getRootNode())
end

function I3DMappingExporter:showNodes(nodes, rootNode)
    local usedIds = {}
    local lines = {}
    local skippedCount = 0

    for _, node in ipairs(nodes) do
        local nodePath = I3DMappingExporter.getNodePath(node, rootNode)
        if nodePath ~= nil then
            local mappingId = I3DMappingExporter.getUniqueMappingId(getName(node), usedIds)
            lines[#lines + 1] = string.format(
                '    <i3dMapping id="%s" node="%s" />',
                I3DMappingExporter.xmlEscape(mappingId),
                I3DMappingExporter.xmlEscape(nodePath))
        else
            skippedCount = skippedCount + 1
        end
    end

    local xmlBody = table.concat(lines, "\n")
    if self.excludeWrapperCheckbox:getValue() then
        self.generatedXml = xmlBody
    elseif xmlBody == "" then
        self.generatedXml = "<i3dMappings>\n</i3dMappings>"
    else
        self.generatedXml = "<i3dMappings>\n" .. xmlBody .. "\n</i3dMappings>"
    end

    if skippedCount > 0 then
        print(string.format("I3D Mapping Exporter: %d Node(s) ohne gueltigen Pfad ausgelassen.", skippedCount))
    end

    self.outputArea:setValue(self.generatedXml)
end

function I3DMappingExporter:copyXml()
    if self.generatedXml == "" then
        print("I3D Mapping Exporter: Zuerst Nodes exportieren.")
        return
    end

    if type(setClipboard) == "function" then
        setClipboard(self.generatedXml)
        -- GE-Clipboard erwartet einen eindeutig abgeschlossenen Textpuffer.
        local clipboardText = self.generatedXml:match("^(.*%S)%s*$") or self.generatedXml
        setClipboard(clipboardText .. "\0")
        print("I3D Mapping Exporter: XML wurde in die Zwischenablage kopiert.")
    else
        print("I3D Mapping Exporter: setClipboard ist in dieser Editor-Version nicht verfuegbar.")
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

        -- Verhindert Endlosschleifen bei fehlerhaften oder fremden Node-Handles.
        if steps > 1024 then
            return nil
        end
    end

    if currentNode ~= rootNode or #indices == 0 then
        return nil
    end

    -- GIANTS-Nodepfade beginnen mit dem ersten Index vor dem Zeichen '>'.
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