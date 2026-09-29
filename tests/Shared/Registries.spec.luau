local Shared = game:GetService("ReplicatedStorage").Shared
local AssetRegistry = require(Shared.Modules.AssetRegistry)
local AnimationRegistry = require(Shared.Modules.AnimationRegistry)

return {
	["IsValidName exige prefijo de categoría, grupo y nombre en PascalCase"] = function()
		expect(AssetRegistry.IsValidName("ANIM_Sword_BasicSlash", "Animation")).toBe(true)
		expect(AssetRegistry.IsValidName("VFX_Combat_SlashTrail", "VFX")).toBe(true)
		expect(AssetRegistry.IsValidName("VFX_Sword_BasicSlash", "Animation")).toBe(false)
		expect(AssetRegistry.IsValidName("ANIM_sword_basicSlash", "Animation")).toBe(false)
		expect(AssetRegistry.IsValidName("ANIM_BasicSlash", "Animation")).toBe(false)
		expect(AssetRegistry.IsValidName("ANIM_Sword_Basic Slash", "Animation")).toBe(false)
	end,

	["cada categoría tiene prefijo"] = function()
		for _, category in { "Animation", "Model", "VFX", "SFX", "Music", "UI", "Texture" } do
			expect(AssetRegistry.CATEGORY_PREFIXES[category] ~= nil).toBe(true)
		end
	end,

	["GetContentId devuelve nil sin AssetId o para assets desconocidos"] = function()
		expect(AssetRegistry.GetContentId("NO_Existe_Nada")).toBeNil()
		expect(AnimationRegistry.GetContentId("No.Existe")).toBeNil()
	end,

	["GetEnumPriority traduce todas las prioridades"] = function()
		for _, priority in { "Core", "Idle", "Movement", "Action" } do
			local enumItem =
				AnimationRegistry.GetEnumPriority({ Asset = "", Priority = priority, Looped = false, Markers = {} })
			expect(tostring(enumItem)).toBe(tostring(Enum.AnimationPriority[priority]))
		end
	end,

	["IsValidMarker acepta markers estándar con sufijo numérico"] = function()
		expect(AnimationRegistry.IsValidMarker("Hit")).toBe(true)
		expect(AnimationRegistry.IsValidMarker("Hit2")).toBe(true)
		expect(AnimationRegistry.IsValidMarker("IFrameStart")).toBe(true)
		expect(AnimationRegistry.IsValidMarker("Impact")).toBe(false)
		expect(AnimationRegistry.IsValidMarker("hit")).toBe(false)
		expect(AnimationRegistry.IsValidMarker("Hit_2")).toBe(false)
	end,
}
