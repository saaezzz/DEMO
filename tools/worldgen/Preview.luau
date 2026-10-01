--!strict

-- Vista cenital del mapa generado en PNG (world/preview.png): cada pieza se
-- pinta con su color, de abajo arriba. Sirve para revisar el trazado sin
-- abrir Studio.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Preview = {}

local crcTable: { number } = {}
for n = 0, 255 do
	local c = n
	for _ = 1, 8 do
		if bit32.band(c, 1) == 1 then
			c = bit32.bxor(0xEDB88320, bit32.rshift(c, 1))
		else
			c = bit32.rshift(c, 1)
		end
	end
	crcTable[n + 1] = c
end

local function crc32(data: string): number
	local crc = 0xFFFFFFFF
	for i = 1, #data do
		crc = bit32.bxor(crcTable[bit32.band(bit32.bxor(crc, string.byte(data, i)), 0xFF) + 1], bit32.rshift(crc, 8))
	end
	return bit32.bxor(crc, 0xFFFFFFFF)
end

local function chunk(kind: string, data: string): string
	return string.pack(">I4", #data) .. kind .. data .. string.pack(">I4", crc32(kind .. data))
end

local function encodePng(width: number, height: number, pixels: buffer): string
	local rows = table.create(height)
	for y = 0, height - 1 do
		rows[y + 1] = "\0" .. buffer.readstring(pixels, y * width * 3, width * 3)
	end
	local header = string.pack(">I4I4BBBBB", width, height, 8, 2, 0, 0, 0)
	return "\137PNG\r\n\26\n"
		.. chunk("IHDR", header)
		.. chunk("IDAT", serde.compress("zlib", table.concat(rows)))
		.. chunk("IEND", "")
end

type Footprint = {
	Top: number,
	X: number,
	Z: number,
	-- Ejes del rectángulo en planta (unitarios) y medio tamaño.
	UX: number,
	UZ: number,
	VX: number,
	VZ: number,
	HalfU: number,
	HalfV: number,
	Round: boolean,
	R: number,
	G: number,
	B: number,
}

local function footprintOf(part: any): Footprint?
	if part.Transparency >= 0.9 then
		return nil
	end
	local cframe = part.CFrame
	local size = part.Size
	local right, up, back = cframe.RightVector, cframe.UpVector, -cframe.LookVector
	-- Proyección en planta: los dos ejes locales más horizontales.
	local axes = { { right, size.X }, { up, size.Y }, { back, size.Z } }
	table.sort(axes, function(a, b)
		return math.abs(a[1].Y) < math.abs(b[1].Y)
	end)
	local u, v = axes[1], axes[2]
	local uLength = math.max(math.sqrt(u[1].X ^ 2 + u[1].Z ^ 2), 1e-6)
	local vLength = math.max(math.sqrt(v[1].X ^ 2 + v[1].Z ^ 2), 1e-6)
	local shape = if part.ClassName == "Part" then part.Shape.Name else "Block"
	local color = part.Color
	return {
		Top = cframe.Position.Y + math.abs(up.Y) * size.Y / 2,
		X = cframe.Position.X,
		Z = cframe.Position.Z,
		UX = u[1].X / uLength,
		UZ = u[1].Z / uLength,
		VX = v[1].X / vLength,
		VZ = v[1].Z / vLength,
		HalfU = u[2] * uLength / 2,
		HalfV = v[2] * vLength / 2,
		Round = shape == "Ball" or shape == "Cylinder",
		R = math.floor(color.R * 255),
		G = math.floor(color.G * 255),
		B = math.floor(color.B * 255),
	}
end

-- Pinta todas las piezas de `root` en un PNG de `scale` píxeles por stud.
function Preview.Write(
	root: any,
	path: string,
	minX: number,
	minZ: number,
	maxX: number,
	maxZ: number,
	scale: number
): ()
	local width = math.floor((maxX - minX) * scale)
	local height = math.floor((maxZ - minZ) * scale)
	local pixels = buffer.create(width * height * 3)
	buffer.fill(pixels, 0, 40)

	local footprints: { Footprint } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			local footprint = footprintOf(descendant)
			if footprint ~= nil then
				table.insert(footprints, footprint)
			end
		end
	end
	table.sort(footprints, function(a, b)
		return a.Top < b.Top
	end)

	for _, f in footprints do
		local reach = math.abs(f.UX) * f.HalfU + math.abs(f.VX) * f.HalfV
		local reachZ = math.abs(f.UZ) * f.HalfU + math.abs(f.VZ) * f.HalfV
		local x0 = math.max(0, math.floor((f.X - reach - minX) * scale))
		local x1 = math.min(width - 1, math.ceil((f.X + reach - minX) * scale))
		local z0 = math.max(0, math.floor((f.Z - reachZ - minZ) * scale))
		local z1 = math.min(height - 1, math.ceil((f.Z + reachZ - minZ) * scale))
		for pz = z0, z1 do
			local wz = minZ + (pz + 0.5) / scale - f.Z
			for px = x0, x1 do
				local wx = minX + (px + 0.5) / scale - f.X
				local lu = wx * f.UX + wz * f.UZ
				local lv = wx * f.VX + wz * f.VZ
				local inside = if f.Round
					then (lu / f.HalfU) ^ 2 + (lv / f.HalfV) ^ 2 <= 1
					else math.abs(lu) <= f.HalfU and math.abs(lv) <= f.HalfV
				if inside then
					local offset = (pz * width + px) * 3
					buffer.writeu8(pixels, offset, f.R)
					buffer.writeu8(pixels, offset + 1, f.G)
					buffer.writeu8(pixels, offset + 2, f.B)
				end
			end
		end
	end

	fs.writeFile(path, encodePng(width, height, pixels))
end

return Preview
