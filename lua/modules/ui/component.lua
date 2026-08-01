local balltze = Balltze
local engine = Engine
local blam = require "blam"
local getTag = blam.getTag
local uiWidgetDefinition = blam.uiWidgetDefinition
local unicodeStringList = blam.unicodeStringList
local isNull = blam.isNull
local core = require "ui.core"
--local ether = require "ui.ether"
local logger = balltze.logger
local findWidgetByDefinition = core.findWidgetByDefinition

local isBlockingInputEnabled = false

---@alias uiComponentType "generic" | "list" | "button" | "checkbox" | "slider" | "dropdown" | "text" | "image" | "spinner" | "progress"

---@class uiComponent
local component = {
    ---@type number
    tagId = nil,
    ---@type tag
    tag = nil,
    ---@type uiWidgetDefinition
    widgetDefinition = nil,
    ---@type uiComponentEvents
    events = {},
    ---@type boolean
    isBackgroundAnimated = false,
    ---@type boolean
    isBackgroundLooped = false,
    ---@type number?
    animationWaitTicks = nil,
    ---@type number?
    delayAnimationTicks = nil,
    ---@type uiComponentType
    type = "generic"
    -- @type table<string, widgetAnimation>
    -- animations = {}
}

---@class uiComponentEvents
---@field onClick? fun(value?: string | boolean | number): boolean
---@field onFocus? function
---@field onOpen? fun(previousWidgetTag?: MetaEngineTag)
---@field onClose? fun():boolean
---@field animate? function

---@type table<number, uiComponent>
component.widgets = {}

-- TODO Make this local and port functions to component
VirtualInputValue = {}
---@type MetaEngineTag
local previousWidgetTag
---@type MetaEngineTag?
local lastFocusedWidgetTagEntry

function component.getLastFocusedWidgetHandle()
    if lastFocusedWidgetTagEntry then
        return lastFocusedWidgetTagEntry.handle.value
    end
end

function component.callbacks()
    ---@type MetaEngineTagDataUiWidgetDefinition?
    local editableWidgetTagData
    ---@type MetaEngineTag?
    local editableWidgetTagEntry
    lastFocusedWidgetTagEntry = nil

    ---@param tagHandleValue integer
    ---@param cancel? fun()
    local function onWidgetFocus(tagHandleValue, cancel)
        if isBlockingInputEnabled then
            if cancel then
                cancel()
            end
            return
        end

        local focusedWidgetTag = engine.tag.getTag(tagHandleValue,
                                                   engine.tag.classes.uiWidgetDefinition)
        assert(focusedWidgetTag, "Invalid widget tag")

        local currentComponent = component.widgets[tagHandleValue]
        if currentComponent and currentComponent.events.onFocus and currentComponent:isVisible() then
            currentComponent.events.onFocus()
        end

        lastFocusedWidgetTagEntry = focusedWidgetTag
        ---@diagnostic disable-next-line: undefined-field
        if focusedWidgetTag.data.flags1:editable() or focusedWidgetTag.data.flags1:password() then
            editableWidgetTagData = focusedWidgetTag.data
            editableWidgetTagEntry = focusedWidgetTag
        else
            editableWidgetTagData = nil
            editableWidgetTagEntry = nil
        end
    end

    local function onMouseScroll(widgetTagHandle)
        local widget = findWidgetByDefinition(widgetTagHandle)
        if not widget then
            return
        end
        local uiComponent = component.widgets[widgetTagHandle] --[[@as uiComponentSpinner|uiComponentList]]
        if uiComponent and not uiComponent.events.onScroll then
            -- If the widget doesn't have scroll event, try to get the parent widget's component
            local parentWidget = widget.parentWidget
            if parentWidget then
                local parentWidgetTag = engine.tag.getTag(parentWidget.definitionTagHandle.value,
                                                          engine.tag.classes.uiWidgetDefinition)
                assert(parentWidgetTag, "Invalid parent widget tag")
                uiComponent = component.widgets[parentWidget.definitionTagHandle.value] --[[@as uiComponentSpinner|uiComponentList]]
            end
        end
        if uiComponent then
            -- If the component has onScroll event or is a list, scroll it
            if uiComponent.events.onScroll or uiComponent.type == "list" then
                local mouse = core.getMouseState()
                uiComponent:scroll(mouse.scroll, true)
            end
        end
    end

    local prevTabEventTypes = {
        dpadLeft = true,
        leftAnalogStickLeft = true,
        rightAnalogStickLeft = true
    }
    local nextTabEventTypes = {
        dpadRight = true,
        dpadUp = true,
        dpadDown = true,
        leftAnalogStickRight = true,
        leftAnalogStickUp = true,
        leftAnalogStickDown = true,
        rightAnalogStickRight = true
    }

    local function onListTab(eventType, widgetEvent)
        local widgetListHandle = widgetEvent.definitionTagHandle.value
        local focusedChild = widgetEvent.focusedChild
        if not focusedChild then
            widgetEvent:cancel()
            return
        end

        local previousWidgetHandle = focusedChild.definitionTagHandle.value
        local widgetList = blam.uiWidgetDefinition(widgetListHandle)
        assert(widgetList, "Invalid widget list tag id")

        local currentComponent = component.widgets[widgetListHandle] --[[@as uiComponentSpinner]]
        if currentComponent and currentComponent.type == "spinner" and currentComponent.events.onScroll then
            currentComponent:scroll(prevTabEventTypes[eventType] and -1 or 1)
            return
        end

        local function findNextWidget()
            for childIndex, child in pairs(widgetList.childWidgets) do
                if child.widgetTag == previousWidgetHandle then
                    local nextChildIndex
                    if prevTabEventTypes[eventType] then
                        if childIndex - 1 < 1 then
                            nextChildIndex = widgetList.childWidgetsCount
                        else
                            nextChildIndex = childIndex - 1
                        end
                    elseif nextTabEventTypes[eventType] then
                        if childIndex + 1 > widgetList.childWidgetsCount then
                            nextChildIndex = 1
                        else
                            nextChildIndex = childIndex + 1
                        end
                    end

                    local widgetTagId = (widgetList.childWidgets[nextChildIndex] or {}).widgetTag
                    if widgetTagId and not isNull(widgetTagId) then
                        local widgetTag = engine.tag.getTag(widgetTagId,
                                                            engine.tag.classes.uiWidgetDefinition)
                        assert(widgetTag, "Invalid widget tag")
                        local widgetValues = core.getWidgetValues(widgetTagId)
                        if widgetValues and widgetValues.visible then
                            return widgetTag
                        end
                    end
                end
            end
        end

        local widgetTag = findNextWidget()
        if not widgetTag then
            widgetEvent:cancel()
            return
        end

        onWidgetFocus(widgetTag.handle.value)
    end

    balltze.addEventListener("frame", function()
        local widget = engine.uiWidget.getActiveWidget()
        if widget and lastFocusedWidgetTagEntry then
            local mouse = core.getMouseState()
            if mouse.scroll ~= 0 then
                onMouseScroll(lastFocusedWidgetTagEntry.handle.value)
            end
            if mouse.rightClick > 0 then
                -- TODO BALLTZE MIGRATE
            end
        end

        -- Draggable prototype code
        if false then
            if core.getMouseState().leftClick > 0 then
                local lastFocusedWidget = component.getLastFocusedWidgetHandle()
                if lastFocusedWidget then
                    local widgetDef = blam.uiWidgetDefinition(lastFocusedWidget)
                    assert(widgetDef, "Error, no focused widget found")
                    logger:debug(widgetDef.width .. " " .. widgetDef.height)
                    local x, y = core.getWidgetCursorPosition()
                    logger:debug("X: " .. x .. " Y: " .. y)
                    core.setWidgetValues(lastFocusedWidget, {
                        position = {x = x - (widgetDef.width / 2), y = y - (widgetDef.height / 2)}
                    })
                end
            end
        end
    end)

    balltze.addEventListener("widget_event_dispatch", function(event)
        local widgetEvent = event:getWidget()
        local eventHandler = event:getEventHandler()
        if not widgetEvent or not eventHandler then
            return
        end

        local eventType = eventHandler.eventType
        local tagHandle = widgetEvent.definitionTagHandle.value

        if eventType == "created" then
            local widgetTag = engine.tag.getTag(tagHandle, engine.tag.classes.uiWidgetDefinition)
            assert(widgetTag, "Invalid widget tag")
            local widgetTagData = widgetTag.data

            -- Keep legacy aspect-ratio behavior for root widgets.
            local rootWidget = core.getRenderedUIWidgetTagHandle()
            local isRootWidget = rootWidget and rootWidget == tagHandle
            local isWidgetWidescreen = widgetTagData.bounds.right > 640
            if isRootWidget then
                if isWidgetWidescreen then
                    balltze.features.setUIAspectRatio(16, 9)
                else
                    balltze.features.setUIAspectRatio(4, 3)
                end
            end

            local renderedWidget = findWidgetByDefinition(tagHandle)
            local componentInstance = component.widgets[tagHandle]
            if renderedWidget then
                if componentInstance and componentInstance.events.onOpen then
                    componentInstance.events.onOpen(previousWidgetTag)
                end
                if previousWidgetTag ~= widgetTag then
                    previousWidgetTag = widgetTag
                end

                local widgetCount = #widgetTagData.childWidgets
                if widgetCount > 0 then
                    local optionsWidgetRef = widgetTagData.childWidgets[widgetCount]
                    local optionsWidgetTag = engine.tag.getTag(optionsWidgetRef.widgetTag.tagHandle.value,
                                                               engine.tag.classes.uiWidgetDefinition)
                    assert(optionsWidgetTag, "Invalid options widget tag")
                    local optionsWidgetTagData = optionsWidgetTag.data
                    if optionsWidgetTagData and optionsWidgetTagData.childWidgets[1] then
                        onWidgetFocus(optionsWidgetTagData.childWidgets[1].widgetTag.tagHandle.value)
                    end
                end
            else
                if componentInstance and componentInstance.events.onOpen then
                    componentInstance.events.onOpen()
                end
            end
            return
        end

        if isBlockingInputEnabled then
            event:cancel()
            return
        end

        if eventType == "getFocus" then
            onWidgetFocus(tagHandle, function()
                event:cancel()
            end)
            return
        end

        if eventType == "aButton" or eventType == "leftMouse" then
            local isCanceled = false
            local currentComponent = component.widgets[tagHandle]
            if currentComponent and currentComponent.events.onClick then
                isCanceled = currentComponent.events.onClick() == false
            end
            if isCanceled then
                event:cancel()
            end
            return
        end

        if eventType == "rightMouse" then
            local widgetTag = findWidgetByDefinition(tagHandle)
            if not widgetTag then
                return
            end
            if editableWidgetTagData and editableWidgetTagEntry then
                if widgetTag.definitionTagHandle.value == editableWidgetTagEntry.handle.value then
                    local inputString = core.getStringFromWidget(editableWidgetTagEntry.handle.value)
                    local text = inputString .. core.getClipboard()
                    core.setStringToWidget(text, editableWidgetTagEntry.handle.value)
                    local currentComponent = component.widgets[editableWidgetTagEntry.handle.value] --[[@as uiComponentInput]]
                    if currentComponent and currentComponent.events.onInputText then
                        currentComponent.events.onInputText(text)
                    end
                end
            end
            return
        end

        if eventType == "backButton" then
            local currentComponent = component.widgets[tagHandle]
            if currentComponent and currentComponent.events.onClose then
                if currentComponent.events.onClose() == false then
                    event:cancel()
                end
            end
            editableWidgetTagData = nil
            return
        end

        if prevTabEventTypes[eventType] or nextTabEventTypes[eventType] then
            onListTab(eventType, widgetEvent)
        end
    end)

    balltze.addEventListener("player_input", function(event)
        if console_is_open() then
            return
        end
        if not (editableWidgetTagData and editableWidgetTagEntry) then
            return
        end
        if event:getDevice() ~= "keyboard" then
            return
        end

        local keycode = event:getKeyCode()
        local pressedKey = core.translateKeycode(keycode) or keycode
        if not pressedKey then
            return
        end

        local inputString = core.getStringFromWidget(editableWidgetTagEntry.handle.value)
        local text = core.mapKeyToText(pressedKey, inputString)
        if not text then
            return
        end

        local currentComponent = component.widgets[editableWidgetTagEntry.handle.value]
        if editableWidgetTagData.name:find "password" then
            core.setStringToWidget(text, editableWidgetTagEntry.handle.value, "*")
        else
            if currentComponent and not currentComponent.allowEmptyChars then
                text = text:trim()
            end
            core.setStringToWidget(text, editableWidgetTagEntry.handle.value)
        end
        if currentComponent and currentComponent.events.onInputText then
            currentComponent.events.onInputText(text)
        end
    end)
end

function component.cleanAllEditableWidgets()
    local editableWidgets = blam.findTagsList("input", blam.tagClasses.uiWidgetDefinition) or {}
    for _, widgetTag in pairs(editableWidgets) do
        local widget = blam.uiWidgetDefinition(widgetTag.id)
        assert(widget, "No widget found with tag id " .. widgetTag.id)
        local widgetStrings = blam.unicodeStringList(widget.unicodeStringListTag)
        if widgetStrings then
            local strings = widgetStrings.strings
            strings[1] = ""
            -- logger:debug("Cleaned widget " .. widgetTag.path)
            widgetStrings.strings = strings
        end
    end
end

---@param tagId number
---@return uiComponent
function component.new(tagId)
    local instance = setmetatable({}, {__index = component})
    instance.tagId = tagId
    instance.tag = getTag(instance.tagId) or error("Invalid tagId") --[[@as tag]]
    instance.selectedWidgetTagId = nil
    instance.widgetDefinition = uiWidgetDefinition(tagId) or error("Invalid tagId") --[[@as uiWidgetDefinition]]
    instance.events = {}
    instance.isBackgroundAnimated = false
    component.widgets[tagId] = instance
    return instance
end

---@param tagId number
---@return uiComponent
function component.getComponent(tagId)
    return component.widgets[tagId]
end

---@param self uiComponent
function component.onFocus(self, callback)
    self.events.onFocus = callback
end

---@param self uiComponent
---@return string
function component.getText(self)
    local virtualValue = VirtualInputValue[self.tagId]
    if virtualValue then
        return virtualValue
    end
    local unicodeStrings = blam.unicodeStringList(self.widgetDefinition.unicodeStringListTag)
    if unicodeStrings then
        return unicodeStrings.strings[self.widgetDefinition.stringListIndex + 1]
    end
    error("No unicodeStringList found for widgetDefinition")
end

---@param self uiComponent
---@param text string
---@param mask? string
function component.setText(self, text, mask)
    local childUnicodeStrings
    local childWidgetDefinition
    local widgetDefinition = self.widgetDefinition
    if self.widgetDefinition.childWidgetsCount > 0 then
        local childTagId = self.widgetDefinition.childWidgets[1].widgetTag
        childWidgetDefinition = uiWidgetDefinition(childTagId) --[[@as uiWidgetDefinition]]
        childUnicodeStrings = unicodeStringList(childWidgetDefinition.unicodeStringListTag)
    end
    local unicodeStrings = unicodeStringList(self.widgetDefinition.unicodeStringListTag)
    if not (unicodeStrings and not isNull(unicodeStrings)) then
        unicodeStrings = childUnicodeStrings --[[@as unicodeStringList]]
        widgetDefinition = childWidgetDefinition --[[@as uiWidgetDefinition]]
    end
    if not (unicodeStrings and not isNull(unicodeStrings)) then
        print(debug.traceback())
        error("No unicodeStringList found for widgetDefinition " .. self.tag.path)
    end
    local stringListIndex = widgetDefinition.stringListIndex
    local newStrings = unicodeStrings.strings
    if mask then
        VirtualInputValue[self.tagId] = text
        newStrings[stringListIndex + 1] = string.rep(mask, #text)
    else
        newStrings[stringListIndex + 1] = text
    end
    unicodeStrings.strings = newStrings
end

---@param self uiComponent
---@param callback fun(previousWidgetTag?: MetaEngineTag)
function component.onOpen(self, callback)
    self.events.onOpen = callback
end

---@param self uiComponent
---@param callback fun(): boolean?
function component.onClose(self, callback)
    self.events.onClose = callback
end

---Animate component background as looped
---@param self uiComponent
function component.animate(self)
    self.isBackgroundAnimated = true
    self.isBackgroundLooped = true
end

---Set component background animation state
---@param self uiComponent
---@param isAnimated boolean
---@param isLooped? boolean
---@param animationWaitTime? number Time in seconds to wait before animating the next frame
---@param delayAnimationTicks? number Time in ticks to wait between frames
function component.setAnimated(self, isAnimated, isLooped, animationWaitTime, delayAnimationTicks)
    local isLooped = isLooped or false
    local animationWaitTime = animationWaitTime or 0
    local delayAnimationTicks = delayAnimationTicks or 0
    self.isBackgroundAnimated = isAnimated
    self.isBackgroundLooped = isLooped
    self.animationWaitTicks = math.floor(animationWaitTime * 30)
    self.delayAnimationTicks = delayAnimationTicks
end

function component.free()
    component.widgets = {}
    collectgarbage("collect")
end

---@param self uiComponent
---@return tag[]
function component.getChildWidgetTags(self)
    -- TODO Filter this instead of mapping
    return table.map(self.widgetDefinition.childWidgets, function(childWidget)
        if not isNull(childWidget.widgetTag) then
            local tag = getTag(childWidget.widgetTag)
            return tag
        end
        return nil
    end)
end

---@param self uiComponent
---@param name string
function component.findChildWidgetTag(self, name)
    local childWidgetTags = self:getChildWidgetTags()
    for _, childTag in pairs(childWidgetTags) do
        if childTag.path:find(name, 1, true) then
            return childTag
        end
        local widgetDefinition = uiWidgetDefinition(childTag.id)
        if widgetDefinition then
            for _, childWidget in pairs(widgetDefinition.childWidgets) do
                local tag = getTag(childWidget.widgetTag) --[[@as tag]]
                if not isNull(childWidget.widgetTag) then
                    if tag.path:find(name, 1, true) then
                        return tag
                    end
                end
            end
        end
    end
end

---@param self uiComponent
---@param name string
function component.findChildWidgetDefinition(self, name)
    local childWidgetTags = self:getChildWidgetTags()
    for _, childTag in pairs(childWidgetTags) do
        if childTag.path:find(name, 1, true) then
            return uiWidgetDefinition(childTag.id)
        end
        local widgetDefinition = uiWidgetDefinition(childTag.id)
        if widgetDefinition then
            for _, childWidget in pairs(widgetDefinition.childWidgets) do
                local tag = getTag(childWidget.widgetTag) --[[@as tag]]
                if not isNull(childWidget.widgetTag) then
                    if tag.path:find(name, 1, true) then
                        return uiWidgetDefinition(childWidget.widgetTag)
                    end
                end
            end
        end
    end
end

---Get a child widget tag handle by name
---Shorter and handier version of findChildWidgetTag
---@param self uiComponent
---@param name string
function component.get(self, name)
    local childWidgetTag = self:findChildWidgetTag(name)
    if childWidgetTag then
        return childWidgetTag.id
    end
end

---@param self uiComponent
function component.getType(self)
    return self.type
end

---@param self uiComponent
---@param newWidgetTagId number
function component.replace(self, newWidgetTagId)
    core.replaceWidgetInDom(self.tagId, newWidgetTagId)
    core.setWidgetValues(newWidgetTagId, {neverReceiveEvents = false, visible = true}, false)
    -- local widget = findWidgetByDefinition(newWidgetTagId)
    -- if widget then
    --     engine.uiWidget.focusWidget(widget)
    -- end
end

-- TODO Discuss with Mango so we can have this class also available in Balltze API
---@class MetaEngineWidgetParams
---@field definitionTagHandle? EngineTagHandle
---@field name? string
---@field controllerIndex? boolean
---@field position? EnginePoint2DInt
---@field type? EngineTagDataUIWidgetType
---@field visible? boolean
---@field renderRegardlessOfControllerIndex? boolean
---@field pausesGameTime? boolean
---@field deleted? boolean
---@field creationProcessStartTime? integer
---@field msToClose? integer
---@field msToCloseFadeTime? integer
---@field opacity? number
---@field previousWidget? MetaEngineWidget|nil
---@field nextWidget? MetaEngineWidget|nil
---@field parentWidget? MetaEngineWidget|nil
---@field childWidget? MetaEngineWidget|nil
---@field focusedChild? MetaEngineWidget|nil
---@field textAddress? integer @The address of the text; nil if the widget is not a text widget, be careful!
---@field cursorIndex? integer @Index of the last child widget focused by the mouse
---@field extendedDescriptionWidget? EngineWidget
---@field bitmapIndex? integer

---@param self uiComponent
---@return MetaEngineWidget?
function component.getWidgetValues(self)
    if core.getWidgetHandle(self.tagId) then
        return core.getWidgetValues(self.tagId)
    end
end

---@param self uiComponent
---@param values MetaEngineWidgetParams
function component.setWidgetValues(self, values)
    core.setWidgetValues(self.tagId, values)
end

---@param self uiComponent
function component.setBitmapIndex(self, index)
    core.setWidgetValues(self.tagId, {bitmapIndex = index - 1}, true)
end

---@param self uiComponent
function component.hide(self, isHidden)
    local isHidden = isHidden or true
    core.setWidgetValues(self.tagId,
                         {visible = not isHidden, neverReceiveEvents = isHidden == true}, false)
end

---@param self uiComponent
function component.show(self, isVisible)
    local isVisible = isVisible == nil and true or isVisible
    core.setWidgetValues(self.tagId, {visible = isVisible, neverReceiveEvents = isVisible == false},
                         false)
end

---@param self uiComponent
---@return boolean
function component.isVisible(self)
    local widgetValues = core.getWidgetValues(self.tagId)
    if not widgetValues then
        return false
    end
    return widgetValues.visible == true
end

---@param blockInput boolean
function component.blockInput(blockInput)
    isBlockingInputEnabled = blockInput == true
end

---@param self uiComponent
function component.launch(self)
    engine.uiWidget.launchWidget(self.tagId)
end

return component
