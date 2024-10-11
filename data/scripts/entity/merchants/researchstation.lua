UpgradeGenerator = include("upgradegenerator")
include("azimuthlib-uiproportionalsplitter")
Azimuth = include("azimuthlib-basic")

local window, aur_itemTypeCombo, aur_typesAllCheckBox, aur_typesCheckBoxes, aur_rarityCombo, aur_materialCombo, aur_minAmountCombo, aur_maxAmountCombo, aur_separateAutoCheckBox, aur_separateAutoLabel, aur_autoBtn, aur_typeScrollFrame, aur_turretDPS, aur_turretDPSLabel, aur_mixTypesCheckBox, aur_mixTypesLabel -- client UI
local aur_systemNames, aur_systemPathByName, aur_systemAmounts, aur_turretNames, aur_turretTypeByName, aur_turretAmounts, aur_typesCheckBoxesCache, aur_type, aur_inProcess -- client
local aur_onShowWindow, aur_onClickResearch -- client extended functions
local aur_initialize -- client/server extended functions
local aur_config, aur_log, aur_playerLocks -- server


if onClient() then


aur_initialize = ResearchStation.initialize
function ResearchStation.initialize(...)
    aur_initialize(...)
    
    invokeServerFunction("aur_sendSettings")
end

function ResearchStation.initUI() -- overridden
    local res = getResolution()
    local size = vec2(1020, 600)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Research /* station title */"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Research"%_t);

    local vPartitions = UIVerticalProportionalSplitter(Rect(window.size), 10, 10, {0.5, 290})

    local hsplit = UIHorizontalSplitter(vPartitions[1], 10, 0, 0.4)

    inventory = window:createInventorySelection(hsplit.bottom, 11)

    local vsplit = UIVerticalSplitter(hsplit.top, 10, 10, 0.35)

    local hsplitleft = UIHorizontalSplitter(vsplit.left, 10, 10, 0.5)

    hsplitleft.padding = 6
    local rect = hsplitleft.top
    rect.width = 220
    required = window:createSelection(rect, 3)

    local rect = hsplitleft.bottom
    rect.width = 150
    optional = window:createSelection(rect, 2)

    for _, sel in pairs({required, optional}) do
        sel.dropIntoEnabled = 1
        sel.entriesSelectable = 0
        sel.onReceivedFunction = "onRequiredReceived"
        sel.onDroppedFunction = "onRequiredDropped"
        sel.onClickedFunction = "onRequiredClicked"
    end

    inventory.dragFromEnabled = 1
    inventory.onClickedFunction = "onInventoryClicked"

    vsplit.padding = 30
    local rect = vsplit.right
    rect.width = 70
    rect.height = 70
    rect.position = rect.position - vec2(180, 0)
    results = window:createSelection(rect, 1)
    results.entriesSelectable = 0
    results.dropIntoEnabled = 0
    results.dragFromEnabled = 0

    vsplit.padding = 10
    local organizer = UIOrganizer(vsplit.right)
    organizer.marginBottom = 5

    button = window:createButton(Rect(vec2(200, 30)), "Research"%_t, "onClickResearch")
    button.maxTextSize = 15
    organizer:placeElementBottomLeft(button)
    button.position = button.position + vec2(-30, 20)
	
    local hsplit = UIHorizontalSplitter(Rect(vsplit.right.lower.x, vsplit.right.lower.y - 15, vsplit.right.upper.x + 15, vsplit.right.upper.y), 5, 5, 0.5)
    aur_itemTypeCombo = window:createComboBox(Rect(vec2(145, 25)), "aur_onItemTypeSelect")
    hsplit:placeElementTopRight(aur_itemTypeCombo)
    aur_itemTypeCombo:addEntry("System"%_t)
    aur_itemTypeCombo:addEntry("Turret"%_t)

    local rect = vPartitions[2]
    aur_typeScrollFrame = window:createScrollFrame(rect)
    aur_typeScrollFrame.scrollSpeed = 40
    
    aur_rarityCombo = window:createComboBox(Rect(vec2(145, 25)), "aur_onItemRaritySelect")
    aur_rarityCombo.position = aur_itemTypeCombo.position + vec2(-155, 0)
    aur_rarityCombo:addEntry("Common"%_t)
    aur_rarityCombo:addEntry("Uncommon"%_t)
    aur_rarityCombo:addEntry("Rare"%_t)
    aur_rarityCombo:addEntry("Exceptional"%_t)
    aur_rarityCombo:addEntry("Exotic"%_t)
    aur_rarityCombo.tooltip = "up to"%_t .. " " .. "Common"%_t
    
    aur_materialCombo = window:createComboBox(Rect(vec2(115, 25)), "aur_onItemMaterialSelect")
    aur_materialCombo.position = aur_rarityCombo.position - vec2(125, 0)
    aur_materialCombo:addEntry("All"%_t)
    for i = 1, NumMaterials() do
        aur_materialCombo:addEntry(Material(i-1).name)
    end
    aur_materialCombo.visible = false
    
    aur_maxAmountCombo = window:createComboBox(Rect(vec2(50, 25)), "aur_onMaxAmountSelect")
    hsplit:placeElementTopRight(aur_maxAmountCombo)
    aur_maxAmountCombo.position = aur_maxAmountCombo.position + vec2(0, 35)
    aur_maxAmountCombo:addEntry(5)
    aur_maxAmountCombo:addEntry(4)
    aur_maxAmountCombo:addEntry(3)
    
    aur_minAmountCombo = window:createComboBox(Rect(vec2(50, 25)), "aur_onMinAmountSelect")
    hsplit:placeElementTopRight(aur_minAmountCombo)
    aur_minAmountCombo.position = aur_minAmountCombo.position + vec2(-60, 35)
    aur_minAmountCombo:addEntry(5)
    aur_minAmountCombo:addEntry(4)
    aur_minAmountCombo:addEntry(3)
    
    local label = window:createLabel(Rect(vec2(150, 25)), "Min & max amount"%_t, 13)
    hsplit:placeElementTopRight(label)
    label.position = label.position + vec2(-120, 35)
    label:setRightAligned()
    
    aur_mixTypesCheckBox = window:createCheckBox(Rect(vec2(340, 20)), "", "")
    hsplit:placeElementTopRight(aur_mixTypesCheckBox)
    aur_mixTypesCheckBox.position = aur_mixTypesCheckBox.position + vec2(0, 70)
    
    aur_mixTypesLabel = window:createLabel(Rect(vec2(320, 20)), "Research selected types together"%_t, 12)
    aur_mixTypesLabel.position = aur_mixTypesCheckBox.position - vec2(10, 0)
    aur_mixTypesLabel:setRightAligned()
    aur_mixTypesLabel.tooltip = "After researching items of the same type, different types will be mixed and researched"%_t
    
    aur_turretDPS = window:createTextBox(Rect(vec2(80, 25)), "")
    hsplit:placeElementTopRight(aur_turretDPS)
    aur_turretDPS.position = aur_turretDPS.position + vec2(0, 100)
    aur_turretDPS.allowedCharacters = "0123456789"
    aur_turretDPS.tooltip = "0/empty = no restrictions"%_t
    
    aur_turretDPSLabel = window:createLabel(Rect(vec2(150, 25)), "Max turret DPS"%_t, 13)
    hsplit:placeElementTopRight(aur_turretDPSLabel)
    aur_turretDPSLabel.position = aur_turretDPSLabel.position + vec2(-90, 100)
    aur_turretDPSLabel:setRightAligned()
    
    aur_separateAutoCheckBox = window:createCheckBox(Rect(vec2(340, 20)), "", "")
    aur_separateAutoCheckBox.checked = true
    hsplit:placeElementTopRight(aur_separateAutoCheckBox)
    aur_separateAutoCheckBox.position = aur_separateAutoCheckBox.position + vec2(0, 135)
    aur_separateAutoCheckBox.visible = false
    
    aur_separateAutoLabel = window:createLabel(Rect(vec2(320, 20)), "Research Auto/Non-auto turrets separately"%_t, 12)
    aur_separateAutoLabel.position = aur_separateAutoCheckBox.position - vec2(10, 0)
    aur_separateAutoLabel:setRightAligned()
    aur_separateAutoLabel.visible = false
    
    if GameVersion() >= Version("2.0") then
        aur_separateAutoCheckBox.active = false
        aur_separateAutoLabel.active = false
        aur_separateAutoCheckBox.tooltip = "No longer used in 2.0+"%_t
        aur_separateAutoLabel.tooltip = "No longer used in 2.0+"%_t
    end
    
    aur_autoBtn = window:createButton(Rect(vec2(200, 30)), "Auto Research"%_t, "aur_onClickAutoResearch")
    aur_autoBtn.maxTextSize = 15
    hsplit:placeElementBottomRight(aur_autoBtn)
    aur_autoBtn.position = aur_autoBtn.position + vec2(0, 20)
    
    ResearchStation.aur_initTypesUI()
end

function ResearchStation.refreshButton()


end

-- TODO CHECK: If player loads sector while being IN research station, initUI will start sooner than server data with custom names, no?

aur_onShowWindow = ResearchStation.onShowWindow
function ResearchStation.onShowWindow()
    aur_onShowWindow()
    
    ResearchStation.aur_updateAmounts()
end

-- CALLBACKS

aur_onClickResearch = ResearchStation.onClickResearch
function ResearchStation.onClickResearch(...)
    if aur_inProcess then return end

    aur_onClickResearch(...)
end

function ResearchStation.aur_onItemTypeSelect()    
    if aur_type == aur_itemTypeCombo.selectedIndex then return end
    aur_type = aur_itemTypeCombo.selectedIndex

    ResearchStation.aur_fillTypes()

    if aur_type == 0 then -- Systems
        aur_materialCombo.visible = false
        aur_turretDPS.visible = false
        aur_turretDPSLabel.visible = false
        aur_separateAutoCheckBox.visible = false
        aur_separateAutoLabel.visible = false
    else -- Turrets
        aur_materialCombo.visible = true
        aur_turretDPS.visible = true
        aur_turretDPSLabel.visible = true
        aur_separateAutoCheckBox.visible = true
        aur_separateAutoLabel.visible = true
    end
end

function ResearchStation.aur_onMinAmountSelect()
    local minAmount = tonumber(aur_minAmountCombo.selectedEntry)
    local maxAmount = tonumber(aur_maxAmountCombo.selectedEntry)
    if minAmount > maxAmount then
        aur_maxAmountCombo.selectedIndex = aur_minAmountCombo.selectedIndex
    end
end

function ResearchStation.aur_onMaxAmountSelect()
    local minAmount = tonumber(aur_minAmountCombo.selectedEntry)
    local maxAmount = tonumber(aur_maxAmountCombo.selectedEntry)
    if minAmount > maxAmount then
        aur_minAmountCombo.selectedIndex = aur_maxAmountCombo.selectedIndex
    end
end

function ResearchStation.aur_onItemRaritySelect()
    aur_rarityCombo.tooltip = "up to"%_t .. " " .. aur_rarityCombo.selectedEntry
end

function ResearchStation.aur_onItemMaterialSelect()
    if aur_materialCombo.selectedEntry == "All"%_t then
        aur_materialCombo.tooltip = nil
    else
        aur_materialCombo.tooltip = "up to"%_t .. " " .. aur_materialCombo.selectedEntry
    end
end

function ResearchStation.aur_onClickAutoResearch()
    if not aur_inProcess then
        -- get system/turret indexex
        local selectedTypes = {}
        local hasTypes = false
        
        local names, typeByName
        if aur_type == 0 then -- systems
            names = aur_systemNames
            typeByName = aur_systemPathByName
        else -- turrets
            names = aur_turretNames
            typeByName = aur_turretTypeByName
        end
        for i = 1, #names do
            local pair = aur_typesCheckBoxes[i]
            if pair.checkBox.checked then
                selectedTypes[typeByName[pair.name]] = true
                hasTypes = true
            end
        end
        if not hasTypes then return end -- no types selected

        local minAmount = tonumber(aur_minAmountCombo.selectedEntry) or 5
        local maxAmount = tonumber(aur_maxAmountCombo.selectedEntry) or 5
        local materialType = aur_materialCombo.selectedIndex - 1
        local maxDPS = tonumber(aur_turretDPS.text) or 0
        local separateAutoTurrets = aur_separateAutoCheckBox.checked
        local mixTypes = aur_mixTypesCheckBox.checked
        aur_inProcess = true
        aur_autoBtn.caption = "Stop"%_t

        invokeServerFunction("aur_start", Rarity(aur_rarityCombo.selectedIndex).value, aur_type, selectedTypes, materialType, minAmount, maxAmount, separateAutoTurrets, maxDPS, mixTypes)
    else -- stop auto research
        invokeServerFunction("aur_stop")
    end
end

function ResearchStation.aur_onTypesAllChecked(checkBox)
    local checked = checkBox.checked
    local count = aur_type == 0 and #aur_systemNames or #aur_turretNames
    for i = 1, count do
        aur_typesCheckBoxes[i].checkBox:setCheckedNoCallback(checked)
    end
end

function ResearchStation.aur_onTypeChecked(checkBox)
    if not checkBox.checked then
        aur_typesAllCheckBox:setCheckedNoCallback(false)
    else
        local allChecked = true
        local count = aur_type == 0 and #aur_systemNames or #aur_turretNames
        for i = 1, count do
            if not aur_typesCheckBoxes[i].checkBox.checked then
                allChecked = false
                break
            end
        end
        aur_typesAllCheckBox:setCheckedNoCallback(allChecked)
    end
end

-- CALLABLE

function ResearchStation.aur_receiveSettings(serverSystems)
    aur_systemNames = serverSystems
    ResearchStation.aur_initTypesUI()
end

function ResearchStation.aur_completed()
    aur_inProcess = false
    aur_autoBtn.caption = "Auto Research"%_t
    
    ResearchStation.aur_updateAmounts()
end

-- CUSTOM

function ResearchStation.aur_initTypesUI()
    if not window then -- initUI didn't happen yet
        return
    end
    if not aur_systemNames then -- aur_receiveSettings didn't happen yet
        return
    end

    -- system upgrades
    local integration = include("AutoResearchIntegration")
    
    local serverSystems = aur_systemNames
    aur_systemNames = {}
    aur_systemPathByName = {}
    local generator = UpgradeGenerator(Seed(0))
    for path in pairs(generator.scripts) do
        local system = SystemUpgradeTemplate(path, Rarity(-1), Seed(0))
        if system and system.script ~= "" then
            if serverSystems[system.script] then
                local customName = (serverSystems[system.script].name%_t) % (serverSystems[system.script].extra or {})
                aur_systemNames[#aur_systemNames + 1] = customName
                aur_systemPathByName[customName] = system.script
            elseif integration[system.script] then
                local customName = (integration[system.script].name%_t) % (integration[system.script].extra or {})
                aur_systemNames[#aur_systemNames + 1] = customName
                aur_systemPathByName[customName] = system.script
            else
                aur_systemNames[#aur_systemNames + 1] = system.name
                aur_systemPathByName[system.name] = system.script
            end
        end
    end
    if isBlackMarketDLCInstalled and isBlackMarketDLCInstalled() then
        local BMGenerator = include("internal/dlc/blackmarket/public/upgradegenerator")
        if BMGenerator then
            local list = {}
            BMGenerator.addUpgrades(list)
            for _, v in ipairs(list) do
                local system = SystemUpgradeTemplate(v.script, Rarity(-1), Seed(0))
                if system and system.script ~= "" then
                    if serverSystems[system.script] then
                        local customName = (serverSystems[system.script].name%_t) % (serverSystems[system.script].extra or {})
                        aur_systemNames[#aur_systemNames + 1] = customName
                        aur_systemPathByName[customName] = system.script
                    elseif integration[system.script] then
                        local customName = (integration[system.script].name%_t) % (integration[system.script].extra or {})
                        aur_systemNames[#aur_systemNames + 1] = customName
                        aur_systemPathByName[customName] = system.script
                    else
                        aur_systemNames[#aur_systemNames + 1] = system.name
                        aur_systemPathByName[system.name] = system.script
                    end
                end
            end
        end
    end
    table.sort(aur_systemNames)
    
    -- turrets
    aur_turretNames = {}
    aur_turretTypeByName = {}
    for weaponType, weaponName in pairs(WeaponTypes.nameByType) do
        aur_turretNames[#aur_turretNames + 1] = weaponName
        aur_turretTypeByName[weaponName] = weaponType
    end
    table.sort(aur_turretNames)
    
    -- create UI
    local lister = UIVerticalLister(Rect(0, 0, aur_typeScrollFrame.localRect.width, aur_typeScrollFrame.localRect.height), 10, 10)
    if GameVersion() >= Version("2.0") then
        lister.marginRight = 15
    else
        lister.marginRight = 30
    end
    
    local rect = lister:placeCenter(vec2(lister.inner.width, 26))
    aur_typesAllCheckBox = aur_typeScrollFrame:createCheckBox(Rect(rect.lower, rect.upper + vec2(0, -1)), "All"%_t, "aur_onTypesAllChecked")
    aur_typesAllCheckBox.fontSize = 12
    aur_typesAllCheckBox.captionLeft = false
    aur_typesAllCheckBox:setCheckedNoCallback(true)
    
    aur_typeScrollFrame:createLine(vec2(rect.lower.x, rect.upper.y), rect.upper)
    
    local count = math.max(#aur_systemNames, #aur_turretNames)
    aur_typesCheckBoxes = {}
    aur_typesCheckBoxesCache = { systems = {}, turrets = {} }
    for i = 1, count do
        local rect = lister:placeCenter(vec2(lister.inner.width, 25))
        local vPartitions = UIVerticalProportionalSplitter(rect, 7, 0, {0.5, 25})
        
        local checkBox = aur_typeScrollFrame:createCheckBox(vPartitions[1], "", "aur_onTypeChecked")
        checkBox.fontSize = 12
        checkBox.captionLeft = false
        checkBox:setCheckedNoCallback(true)
        
        local amountLabel = aur_typeScrollFrame:createLabel(vPartitions[2], "0", 11)
        amountLabel.color = ColorRGB(0.5, 0.5, 0.5)
        amountLabel:setRightAligned()
        
        aur_typesCheckBoxes[i] = {checkBox = checkBox, amountLabel = amountLabel}
    end
    
    for i = 1, #aur_systemNames do
        aur_typesCheckBoxesCache.systems[i] = true
    end
    
    ResearchStation.aur_onItemTypeSelect()
end

function ResearchStation.aur_updateAmounts()
    if aur_inProcess or not window or not window.visible then return end
    
    local amounts = {}
    local items = Player():getInventory():getItems()
    for _, v in pairs(items) do
        if aur_type == 0 and v.item.itemType == InventoryItemType.SystemUpgrade then
            if not amounts[v.item.script] then
                amounts[v.item.script] = 0
            end
            amounts[v.item.script] = amounts[v.item.script] + 1
        elseif aur_type == 1 and (v.item.itemType == InventoryItemType.Turret or v.item.itemType == InventoryItemType.TurretTemplate) then
            local weaponType = WeaponTypes.getTypeOfItem(v.item)
            if weaponType then
                if not amounts[weaponType] then
                    amounts[weaponType] = 0
                end
                amounts[weaponType] = amounts[weaponType] + 1
            end
        end
    end
    
    local names, typeByName
    if aur_type == 0 then -- systems
        names = aur_systemNames
        typeByName = aur_systemPathByName
    else -- turrets
        names = aur_turretNames
        typeByName = aur_turretTypeByName
    end
    local amountLabelByType = {}
    for name, _type in pairs(typeByName) do
        for i, _name in ipairs(names) do
            if name == _name then
                amountLabelByType[_type] = aur_typesCheckBoxes[i].amountLabel
                break
            end
        end
    end
    
    for _type, amount in pairs(amounts) do
        if amountLabelByType[_type] then
            amountLabelByType[_type].caption = amount
            amountLabelByType[_type] = false
        end
    end
    for _, label in pairs(amountLabelByType) do
        if label then
            label.caption = "0"
        end
    end
end

function ResearchStation.aur_fillTypes()
    local allChecked = true
    local oldNames, newNames, oldCache, newCache
    if aur_type == 0 then -- turrets -> systems
        oldNames = aur_turretNames
        newNames = aur_systemNames
        oldCache = "turrets"
        newCache = "systems"
    else -- systems -> turrets
        oldNames = aur_systemNames
        newNames = aur_turretNames
        oldCache = "systems"
        newCache = "turrets"
    end
    -- save old checkbox values
    for i = 1, #oldNames do
        aur_typesCheckBoxesCache[oldCache][i] = aur_typesCheckBoxes[i].checkBox.checked
    end
    -- restore saved checkbox values
    for i = 1, #newNames do
        local data = aur_typesCheckBoxes[i]
        data.name = newNames[i]
        data.checkBox.caption = data.name
        data.checkBox.visible = true
        if not aur_typesCheckBoxesCache[newCache][i] then
            allChecked = false
        end
        data.checkBox:setCheckedNoCallback(aur_typesCheckBoxesCache[newCache][i])
        
        aur_typesCheckBoxes[i].amountLabel.visible = true
    end
    for i = #newNames + 1, #aur_typesCheckBoxes do
        aur_typesCheckBoxes[i].checkBox.visible = false
        aur_typesCheckBoxes[i].amountLabel.visible = false
    end
    aur_typesAllCheckBox:setCheckedNoCallback(allChecked)
    
    ResearchStation.aur_updateAmounts()
end


else -- onServer


aur_initialize = ResearchStation.initialize
function ResearchStation.initialize(...)
    aur_initialize(...)
    
    aur_playerLocks = {} -- save player index in order to prevent from starting 2 researches at the same time
    
    local configOptions = {
      ["_version"] = {"1.3", comment = "Config version. Don't touch."},
      ["ConsoleLogLevel"] = {2, round = -1, min = 0, max = 4, comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."},
      ["FileLogLevel"] = {2, round = -1, min = 0, max = 4, comment = "0 - Disable, 1 - Errors, 2 - Warnings, 3 - Info, 4 - Debug."},
      ["CustomNames"] = {{},
        comment = [[Here you can add custom names for systems to help better describe them.
Format: { ["systemfilename"] = { ["name"] = "System Display Name MK-${mark}", ["extra"] = { mark = "X" } }}.
"Extra" table holds additional name variables - just replace them all with "X ".
Server adds empty names for all used systems for your convenience.]]
      },
      ["CustomNames.*.name"] = {"", required = 1, comment = false},
      ["CustomNames.*.extra"] = {{}, optional = 1},
      ["ResearchGroupVolume"] = {10, round = -1, min = 5, comment = "Make a slight delay after specified amount of researches to prevent server from hanging."},
      ["DelayInterval"] = {1, min = 0.05, comment = "Delay interval in seconds between research batches."}
    }
    local isModified
    aur_config, isModified = Azimuth.loadConfig("AutoResearch", configOptions)
    -- upgrade config
    if aur_config._version == "1.1" then
        aur_config._version = "1.2"
        isModified = true
        aur_config.ResearchGroupVolume = 10
        aur_config.DelayInterval = 1
    end
    if aur_config._version == "1.2" then
        aur_config._version = "1.3"
        aur_config.CustomSystems = nil
    end
    
    -- add all systems to config with empty names so server admins would have easier time changing names
    local systems = {}
    -- vanilla
    local generator = UpgradeGenerator()
    for path in pairs(generator.scripts) do
        local system = SystemUpgradeTemplate(path, Rarity(-1), Seed(0))
        if system and system.script ~= "" then
            if not aur_config.CustomNames[system.script] then
                aur_config.CustomNames[system.script] = { name = "" }
                isModified = true
            end
        end
    end
    -- DLC
    if GameVersion() >= Version("1.3.4") then
        local BMGenerator = include("internal/dlc/blackmarket/public/upgradegenerator")
        if BMGenerator then
            local list = {}
            BMGenerator.addUpgrades(list)
            for _, v in ipairs(list) do
                local system = SystemUpgradeTemplate(v.script, Rarity(-1), Seed(0))
                if system and system.script ~= "" then
                    if not aur_config.CustomNames[system.script] then
                        aur_config.CustomNames[system.script] = { name = "" }
                        isModified = true
                    end
                end
            end
        end
    end
    
    if isModified then
        Azimuth.saveConfig("AutoResearch", aur_config, configOptions)
    end
    aur_log = Azimuth.logs("AutoResearch", aur_config.ConsoleLogLevel, aur_config.FileLogLevel)
end

if not ResearchStation.updateServer then -- fixing deferredCallback
    function ResearchStation.updateServer() end
end

-- CALLABLE

function ResearchStation.aur_sendSettings()
    local r = {}
    for path, data in pairs(aur_config.CustomNames) do
        if data.name ~= "" then
            r[path] = data
        end
    end
    invokeClientFunction(Player(callingPlayer), "aur_receiveSettings", r)
end
callable(ResearchStation, "aur_sendSettings")

function ResearchStation.aur_start(maxRarity, itemType, selectedTypes, materialType, minAmount, maxAmount, separateAutoTurrets, maxTurretDPS, mixTypes)
    maxRarity = tonumber(maxRarity)
    itemType = tonumber(itemType)
    materialType = tonumber(materialType)
    maxTurretDPS = tonumber(maxTurretDPS)
    if anynils(maxRarity, itemType, selectedTypes, materialType, maxTurretDPS) then return end
    minAmount = tonumber(minAmount) or 5
    maxAmount = tonumber(maxAmount) or 5
    minAmount = math.min(minAmount, maxAmount)
    maxAmount = math.max(minAmount, maxAmount)
    maxTurretDPS = math.max(0, maxTurretDPS)
    mixTypes = not not mixTypes

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not player then return end
    if not buyer then
        invokeClientFunction(player, "aur_completed")
        return
    end

    if aur_playerLocks[callingPlayer] then -- auto research is already going
        invokeClientFunction(player, "aur_completed")
        return
    end
    aur_playerLocks[callingPlayer] = 1

    if materialType == -1 then
        materialType = nil
    end
    
    if GameVersion() >= Version("2.0") then
        separateAutoTurrets = false
    else
        separateAutoTurrets = not not separateAutoTurrets
    end

    aur_log:Debug("Player %i - Research started", callingPlayer)
	local callbackParameters = {
		["callingPlayer"] = callingPlayer,
		["inventory"] = inventory,
		["separateAutoTurrets"] = separateAutoTurrets,
		["maxRarity"] = maxRarity,
		["minAmount"] = minAmount,
		["maxAmount"] = maxAmount,
		["itemType"] = itemType,
		["selectedTypes"] = selectedTypes,
		["materialType"] = materialType,
		["maxTurretDPS"] = maxTurretDPS,
		["mixTypes"] = mixTypes,
		["skipRarities"] = {{},{}}
	}
	
    local result = deferredCallback(0, "aur_deferred", callbackParameters)
    if not result then
        aur_log:Error("Player %i - Failed to defer research", callingPlayer)
        aur_playerLocks[callingPlayer] = nil
        invokeClientFunction(player, "aur_completed")
    end
end
callable(ResearchStation, "aur_start")

function ResearchStation.aur_stop()
    aur_playerLocks[callingPlayer] = 2 -- ask to stop
end
callable(ResearchStation, "aur_stop")

-- CUSTOM

function ResearchStation.aur_deferred(parameters)
	local playerIndex = parameters.callingPlayer
	local separateAutoTurrets = parameters.separateAutoTurrets
	local maxRarity = parameters.maxRarity
	local minAmount = parameters.minAmount
	local maxAmount = parameters.maxAmount
	local itemType = parameters.itemType
	local selectedTypes = parameters.selectedTypes
	local materialType = parameters.materialType
	local maxTurretDPS = parameters.maxTurretDPS
	local mixTypes = parameters.mixTypes
	local skipRarities = parameters.skipRarities

	local buyer, ship, player = getInteractingFaction(playerIndex, AlliancePrivilege.SpendResources)
	local inventory = buyer:getInventory() -- get just once

    aur_log:Debug("Player %i - Another iteration: separate %s, min %i, max %i, itemtype %i, system %s, material %s, maxTurretDPS %i, mixTypes %s, skipRarities %s", playerIndex, separateAutoTurrets, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, skipRarities)

    if not Server():isOnline(playerIndex) then -- someone got bored and left..
        aur_log:Debug("Player %i - End of research (player offline/away)", playerIndex)
        aur_playerLocks[playerIndex] = nil -- unlock
        return
    end
	
    local itemIndices, itemsLength, isResearchFine, researchCode
    local separateCounter = 1
    if itemType == 1 and separateAutoTurrets then
        separateCounter = 2
    end
    local timer
    if aur_log.isDebug then
        timer = HighResolutionTimer()
        timer:start()
    end
    local j = 1
    callingPlayer = playerIndex -- make server think that player invoked usual research
    for i = 1, separateCounter do -- if itemType is turret, research independently 2 times (no auto fire and auto fire)
        local separateValue = i
        if not separateAutoTurrets then
            separateValue = 0 -- will turn into -1
        end
        while true do
            if j == aur_config.ResearchGroupVolume then -- we need to make a small delay to prevent script from hanging
                goto aur_finish
            end
            if not aur_playerLocks[playerIndex] then
                break -- interrupted by player
            end

            itemsLength = 0
            if not skipRarities[i][RarityType.Petty] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Petty, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Petty] = true -- skip this rarity in the future
                end
            end
            if itemsLength < minAmount and not skipRarities[i][RarityType.Common] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Common, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Common] = true
                end
            end
            if itemsLength < minAmount and maxRarity >= RarityType.Uncommon and not skipRarities[i][RarityType.Uncommon] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Uncommon, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Uncommon] = true
                end
            end
            if itemsLength < minAmount and maxRarity >= RarityType.Rare and not skipRarities[i][RarityType.Rare] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Rare, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Rare] = true
                end
            end
            if itemsLength < minAmount and maxRarity >= RarityType.Exceptional and not skipRarities[i][RarityType.Exceptional] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Exceptional, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Exceptional] = true
                end
            end
            if itemsLength < minAmount and maxRarity >= RarityType.Exotic and not skipRarities[i][RarityType.Exotic] then
                itemsLength, itemIndices = ResearchStation.aur_getIndices(inventory, RarityType.Exotic, minAmount, maxAmount, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, separateValue)
                if itemsLength < minAmount then
                    skipRarities[i][RarityType.Exotic] = true
                end
            end

            if itemsLength >= minAmount then
                isResearchFine, researchCode = ResearchStation.research(itemIndices) -- thanks for Research Station Lib there is no need for double checks
                if not isResearchFine then break end -- something went wrong
            else
                break
            end
            j = j + 1
        end
    end
    ::aur_finish::
    callingPlayer = nil
    if aur_log.isDebug then
        timer:stop()
        aur_log:Debug("Iteration took %s", timer.secondsStr)
    end
    local endResearch
    if isResearchFine == false then -- something went wrong (didn't pass one of the checks)
        aur_log:Debug("Player %i - End of research (exited with code %i)", playerIndex, researchCode)
        endResearch = true
    elseif itemsLength < minAmount then -- nothing more to research, end auto research
        aur_log:Debug("Player %i - End of research", playerIndex)
        endResearch = true
    elseif aur_playerLocks[playerIndex] and aur_playerLocks[playerIndex] == 2 then -- interrupted by player
        aur_log:Debug("Player %i - End of research (stopped by player)", playerIndex)
        endResearch = true
    end

    if not endResearch then -- continue after a delay
        local result = deferredCallback(aur_config.DelayInterval, "aur_deferred", parameters)
        if result then return end
        aur_log:Error("Player %i - Failed to defer research", playerIndex)
    end

    -- end research
    aur_playerLocks[playerIndex] = nil -- unlock
    invokeClientFunction(player, "aur_completed")
end

function ResearchStation.aur_getIndices(inventory, rarity, minItems, maxItems, itemType, selectedTypes, materialType, maxTurretDPS, mixTypes, isAutoFire)
    local grouped
    if itemType == 0 then
        grouped = ResearchStation.aur_getSystemsByRarity(inventory, rarity, selectedTypes, maxItems)
    else
        grouped = ResearchStation.aur_getTurretsByRarity(inventory, rarity, selectedTypes, maxItems, mixTypes, materialType, maxTurretDPS, isAutoFire - 1)
    end
    
    local itemLength = 0
    local itemIndices = {}
    for _, group in pairs(grouped) do
        local isFullGroup = #group >= minItems
        if isFullGroup then
            itemLength = 0
            itemIndices = {}
        end
        if isFullGroup or mixTypes then
            for i, itemInfo in ipairs(group) do
                itemLength = itemLength + 1
                itemIndices[itemInfo.index] = (itemIndices[itemInfo.index] or 0) + 1
                if itemLength == maxItems then
                    goto aur_indicesFound
                end
            end
        end
    end
    ::aur_indicesFound::

    return itemLength, itemIndices
end

function ResearchStation.aur_getSystemsByRarity(inventory, rarityType, selectedTypes, maxItems)
    local inventoryItems = inventory:getItemsByType(InventoryItemType.SystemUpgrade)
    local grouped = {}

    for i, inventoryItem in pairs(inventoryItems) do
        if (inventoryItem.item.rarity.value == rarityType and not inventoryItem.item.favorite)
          and selectedTypes[inventoryItem.item.script] then
            local existing = grouped[inventoryItem.item.script]
            if existing == nil then
                grouped[inventoryItem.item.script] = {}
                existing = grouped[inventoryItem.item.script]
            end
            -- Systems can stack now
            local length = math.min(inventoryItem.amount, maxItems - #existing)
            for j = 1, length do
                existing[#existing + 1] = { item = inventoryItem.item, index = i }
            end
            if #existing == maxItems then -- no need to search for more, we already have max amount of systems
                aur_log:Debug("Systems (cycle): %s", existing)
                return {existing}
            end
        end
    end

    aur_log:Debug("Systems (end): %s", grouped)
    return grouped
end

function ResearchStation.aur_getTurretsByRarity(inventory, rarityType, selectedTypes, maxItems, mixTypes, materialType, maxDPS, isAutoFire)
    local inventoryItems = inventory:getItemsByType(InventoryItemType.Turret)
    local turretTemplates = inventory:getItemsByType(InventoryItemType.TurretTemplate)
    for i, inventoryItem in pairs(turretTemplates) do
        inventoryItems[i] = inventoryItem
    end
    local grouped = {}

    local selectedKey
    for i, inventoryItem in pairs(inventoryItems) do
        if (inventoryItem.item.rarity.value == rarityType and not inventoryItem.item.favorite) then
            if isAutoFire == -1 or (isAutoFire == 0 and not inventoryItem.item.automatic) or (isAutoFire == 1 and inventoryItem.item.automatic) then
                local weaponType = WeaponTypes.getTypeOfItem(inventoryItem.item)
                local materialValue = inventoryItem.item.material.value
                if selectedTypes[weaponType] and (not materialType or materialValue <= materialType) and (maxDPS == 0 or inventoryItem.item.dps <= maxDPS) then
                    local groupKey = materialValue.."_"..weaponType
                    if not selectedKey or groupKey == selectedKey then
                        local existing = grouped[groupKey] -- group by material, no need to mix iron and avorion
                        if existing == nil then
                            grouped[groupKey] = {}
                            existing = grouped[groupKey]
                        end
                        for j = 1, inventoryItem.amount do
                            existing[#existing + 1] = { item = inventoryItem.item, index = i }
                        end
                        if not selectedKey and #existing >= maxItems then -- we have max amount of items of that turret type + material, just focus on these and remove others
                            selectedKey = groupKey
                            grouped = { [selectedKey] = existing }
                        end
                    end
                end
            end
        end
    end
    if selectedKey then -- got full group, sort it so low-dps weapons will be researched first
        table.sort(grouped[selectedKey], function(a, b) return a.item.dps < b.item.dps end)
        return grouped
    end
    if mixTypes then -- no full groups, pile all turrets into one group and sort them by dps
        local combined = {}
        for _, group in pairs(grouped) do
            for _, itemInfo in ipairs(group) do
                combined[#combined + 1] = itemInfo
            end
        end
        table.sort(combined, function(a, b) return a.item.dps < b.item.dps end)
        
        return {combined}
    end
    
    return {}
end


end