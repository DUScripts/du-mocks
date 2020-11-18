#!/usr/bin/env lua
--- Tests on dumocks.LightUnit.
-- @see dumocks.LightUnit

-- set search path to include root of project
package.path = package.path .. ";../?.lua"

local lu = require("luaunit")

local mlu = require("dumocks.LightUnit")
require("tests.Utilities")

_G.TestLightUnit = {}

--- Verify constructor arguments properly handled and independent between instances.
function _G.TestLightUnit.testConstructor()

    -- default element:
    -- ["square light xs"] = {mass = 70.05, maxHitPoints = 50.0}

    local light0 = mlu:new()
    local light1 = mlu:new(nil, 1, "Square Light XS")
    local light2 = mlu:new(nil, 2, "invalid")
    local light3 = mlu:new(nil, 3, "square light l")

    local lightClosure0 = light0:mockGetClosure()
    local lightClosure1 = light1:mockGetClosure()
    local lightClosure2 = light2:mockGetClosure()
    local lightClosure3 = light3:mockGetClosure()

    lu.assertEquals(lightClosure0.getId(), 0)
    lu.assertEquals(lightClosure1.getId(), 1)
    lu.assertEquals(lightClosure2.getId(), 2)
    lu.assertEquals(lightClosure3.getId(), 3)

    -- prove default element is selected only where appropriate
    local defaultMass = 70.05
    lu.assertEquals(lightClosure0.getMass(), defaultMass)
    lu.assertEquals(lightClosure1.getMass(), defaultMass)
    lu.assertEquals(lightClosure2.getMass(), defaultMass)
    lu.assertNotEquals(lightClosure3.getMass(), defaultMass)
end

--- Characterization test to determine in-game behavior, can run on mock and uses assert instead of luaunit to run
-- in-game.
--
-- Test setup:
-- 1. 1x Long Light Light L, connected to Programming Board on slot1
--
-- Exercises: getElementClass, deactivate, activate, toggle, getState, setSignalIn, getSignalIn
function _G.TestLightUnit.testGameBehavior()
    local mock = mlu:new(nil, 1, "long light m")
    local slot1 = mock:mockGetClosure()

    -- stub this in directly to supress print in the unit test
    local unit = {}
    unit.exit = function()
    end
    local system = {}
    system.print = function()
    end

    ---------------
    -- copy from here to unit.start
    ---------------
    -- verify expected functions
    local expectedFunctions = {"activate", "deactivate", "toggle", "getState", 
                               "show", "hide", "getData", "getDataId", "getWidgetType", "getIntegrity", "getHitPoints",
                               "getMaxHitPoints", "getId", "getMass", "getElementClass", "setSignalIn", "getSignalIn",
                               "load"}
    _G.Utilities.verifyExpectedFunctions(slot1, expectedFunctions)

    -- test element class and inherited methods
    assert(slot1.getElementClass() == "LightUnit")
    assert(slot1.getData() == "{}")
    assert(slot1.getDataId() == "")
    assert(slot1.getWidgetType() == "")
    slot1.show()
    slot1.hide()
    assert(slot1.getIntegrity() == 100.0 * slot1.getHitPoints() / slot1.getMaxHitPoints())
    assert(slot1.getMaxHitPoints() == 50.0)
    assert(slot1.getId() > 0)
    assert(slot1.getMass() == 79.34)

    -- play with set signal, has no actual effect on state when set programmatically
    local initialState = slot1.getState()
    slot1.setSignalIn("in", 0.0)
    assert(slot1.getSignalIn("in") == 0.0)
    assert(slot1.getState() == initialState)
    slot1.setSignalIn("in", 1.0)
    assert(slot1.getSignalIn("in") == 1.0)
    assert(slot1.getState() == initialState)
    -- fractions within [0,1] work, and string numbers are cast
    slot1.setSignalIn("in", 0.7)
    assert(slot1.getSignalIn("in") == 0.7)
    assert(slot1.getState() == initialState)
    slot1.setSignalIn("in", "0.5")
    assert(slot1.getSignalIn("in") == 0.5)
    assert(slot1.getState() == initialState)
    slot1.setSignalIn("in", "0.0")
    assert(slot1.getSignalIn("in") == 0.0)
    assert(slot1.getState() == initialState)
    slot1.setSignalIn("in", "7.0")
    assert(slot1.getSignalIn("in") == 1.0)
    assert(slot1.getState() == initialState)
    -- invalid sets to 0
    slot1.setSignalIn("in", "text")
    assert(slot1.getSignalIn("in") == 0.0)
    assert(slot1.getState() == initialState)
    slot1.setSignalIn("in", nil)
    assert(slot1.getSignalIn("in") == 0.0)
    assert(slot1.getState() == initialState)

    -- ensure initial state
    slot1.deactivate()
    assert(slot1.getState() == 0)

    -- validate methods
    slot1.activate()
    assert(slot1.getState() == 1)
    slot1.deactivate()
    assert(slot1.getState() == 0)
    slot1.toggle()
    assert(slot1.getState() == 1)

    system.print("Success")
    unit.exit()
    ---------------
    -- copy to here to unit.start
    ---------------
end

os.exit(lu.LuaUnit.run())
