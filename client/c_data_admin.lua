local screenW, screenH = guiGetScreenSize()
local ADMIN_ACCESS_LEVEL = 5

AdminPanel = {
    window = nil,
    playerList = nil,
    dataGrid = nil,
    selectedPlayer = nil
}

function AdminPanel.init()
    bindKey("F8", "down", AdminPanel.toggle)
end

function AdminPanel.createGUI()
    AdminPanel.window = guiCreateWindow(screenW-400, 50, 380, 500, "Secure Data System by D4NTE", false)
    guiWindowSetSizable(AdminPanel.window, false)
    
    AdminPanel.playerList = guiCreateGridList(10, 25, 360, 150, false, AdminPanel.window)
    guiGridListAddColumn(AdminPanel.playerList, "Player", 0.5)
    guiGridListAddColumn(AdminPanel.playerList, "ID", 0.2)
    guiGridListAddColumn(AdminPanel.playerList, "Data Entries", 0.3)
    
    AdminPanel.dataGrid = guiCreateGridList(10, 185, 360, 200, false, AdminPanel.window)
    guiGridListAddColumn(AdminPanel.dataGrid, "Key", 0.6)
    guiGridListAddColumn(AdminPanel.dataGrid, "Value", 0.4)
    
    local btnRefresh = guiCreateButton(10, 395, 80, 30, "Refresh", false, AdminPanel.window)
    local btnAdd = guiCreateButton(100, 395, 80, 30, "Add", false, AdminPanel.window)
    local btnEdit = guiCreateButton(190, 395, 80, 30, "Edit", false, AdminPanel.window)
    local btnDelete = guiCreateButton(280, 395, 80, 30, "Delete", false, AdminPanel.window)
    
    addEventHandler("onClientGUIClick", btnRefresh, AdminPanel.refreshData, false)
    addEventHandler("onClientGUIClick", btnAdd, AdminPanel.showAddDialog, false)
    addEventHandler("onClientGUIClick", btnEdit, AdminPanel.showEditDialog, false)
    addEventHandler("onClientGUIClick", btnDelete, AdminPanel.deleteSelected, false)
    addEventHandler("onClientGUIDoubleClick", AdminPanel.dataGrid, AdminPanel.showEditDialog, false)
end

function AdminPanel.toggle()
    if not hasObjectPermissionTo(localPlayer, "function.ban") then
        outputChatBox("No permission!", 255, 0, 0)
        return
    end
    
    if guiGetVisible(AdminPanel.window) then
        AdminPanel.close()
    else
        if not AdminPanel.window then
            AdminPanel.createGUI()
        end
        AdminPanel.refreshPlayerList()
        guiSetVisible(AdminPanel.window, true)
        showCursor(true)
    end
end

function AdminPanel.refreshPlayerList()
    guiGridListClear(AdminPanel.playerList)
    triggerServerEvent("admin:requestPlayerData", resourceRoot)
end

addEvent("admin:receivePlayerData", true)
addEventHandler("admin:receivePlayerData", root,
    function(playersData)
        for player, count in pairs(playersData) do
            local row = guiGridListAddRow(AdminPanel.playerList)
            guiGridListSetItemText(AdminPanel.playerList, row, 1, getPlayerName(player), false, false)
            guiGridListSetItemText(AdminPanel.playerList, row, 2, tostring(getElementData(player, "playerid") or "-", false, false))
            guiGridListSetItemText(AdminPanel.playerList, row, 3, tostring(count), false, false)
            guiGridListSetItemData(AdminPanel.playerList, row, 1, player)
        end
    end
)

function AdminPanel.refreshData()
    if AdminPanel.selectedPlayer then
        triggerServerEvent("admin:requestPlayerDetails", resourceRoot, AdminPanel.selectedPlayer)
    end
end

addEvent("admin:receivePlayerDetails", true)
addEventHandler("admin:receivePlayerDetails", root,
    function(player, data)
        guiGridListClear(AdminPanel.dataGrid)
        for key, value in pairs(data) do
            local row = guiGridListAddRow(AdminPanel.dataGrid)
            guiGridListSetItemText(AdminPanel.dataGrid, row, 1, tostring(key), false, false)
            guiGridListSetItemText(AdminPanel.dataGrid, row, 2, tostring(value), false, false)
        end
    end
)

function AdminPanel.showAddDialog()
    local window = guiCreateWindow(screenW/2-150, screenH/2-100, 300, 200, "Add new key", false)
    local editKey = guiCreateEdit(10, 30, 280, 30, "", false, window)
    local editValue = guiCreateEdit(10, 70, 280, 30, "", false, window)
    local btnConfirm = guiCreateButton(10, 120, 130, 30, "Confirm", false, window)
    local btnCancel = guiCreateButton(160, 120, 130, 30, "Cancel", false, window)
    
    addEventHandler("onClientGUIClick", btnConfirm,
        function()
            local key = guiGetText(editKey)
            local value = guiGetText(editValue)
            if key ~= "" and value ~= "" then
                triggerServerEvent("admin:modifyData", resourceRoot, AdminPanel.selectedPlayer, key, value, "add")
                destroyElement(window)
            end
        end
    )
    
    addEventHandler("onClientGUIClick", btnCancel, function() destroyElement(window) end, false)
end

function AdminPanel.deleteSelected()
    local selectedRow = guiGridListGetSelectedItem(AdminPanel.dataGrid)
    if selectedRow ~= -1 then
        local key = guiGridListGetItemText(AdminPanel.dataGrid, selectedRow, 1)
        triggerServerEvent("admin:modifyData", resourceRoot, AdminPanel.selectedPlayer, key, nil, "delete")
    end
end

addEventHandler("onClientGUIClick", AdminPanel.playerList,
    function()
        local selectedRow = guiGridListGetSelectedItem(AdminPanel.playerList)
        if selectedRow ~= -1 then
            AdminPanel.selectedPlayer = guiGridListGetItemData(AdminPanel.playerList, selectedRow, 1)
            AdminPanel.refreshData()
        end
    end
, false)