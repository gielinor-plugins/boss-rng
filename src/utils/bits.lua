-- Bit helpers for var masks.

local bits = {}

-- Number of zero bits below a mask's lowest set bit, e.g. 0xFFFF0000 gives 16.
function bits.LowestBit(mask)
    local shift = 0
    while mask ~= 0 and mask & 1 == 0 do
        mask = mask >> 1
        shift = shift + 1
    end
    return shift
end

return bits
