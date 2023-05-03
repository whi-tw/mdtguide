---@diagnostic disable: duplicate-set-field
---@meta

---
-- This class contains EmmyLua annotations to help
-- IDEs work with some external classes and types
---

-- WoW methods

---@class stringlib
---@field split fun(delimiter: string, str: string, pieces?: integer): ...: string
---@field trim fun(str: string): string

---@class string
---@field split fun(self: self, delimiter: string, pieces?: integer): ...: string
---@field trim fun(self: self): self

---@class MaximizeMinimizeButtonFrame: Frame
---@field SetOnMaximizedCallback function
---@field SetOnMinimizedCallback function

---@class IconButton: Button

---@class SquareIconButton: IconButton

---@class C_Addons
---@field GetAddOnMetadata fun(addonId: string | number, field: string): string
C_AddOns = {}