local bit = require("bit")

function toBytes(str)

    local result = {}

    for i = 1, #str do
        local b = tobin(str:byte(i))
        for j = 1, #b do
            result[#result + 1] = b[#b + 1 - j]
        end
    end

    return result

end


function getControlBitPos(cbit)
    return math.pow(2, cbit - 1)
end

function checkParity(bits, controlBitNum)
    local sum = 0

    local pos = getControlBitPos(controlBitNum)

    while pos <= #bits do
        local to = pos + getControlBitPos(controlBitNum) - 1

        for j = pos, to do
            -- исключаем бит, номер которого с совпадает с контрольным (он нулевой)
            local skip = getControlBitPos(controlBitNum) == j

            if j <= #bits and not skip then
                sum = sum + bits[j]
            end
        end

        pos = pos + 2 * getControlBitPos(controlBitNum)
    end

    return sum % 2
end

function inverseBit(bits, pos)
    -- bit = 0 | 1
    bits[pos] = (bits[pos] + 3) % 2
    return bits
end

function hammingCode(bits)
    -- вставка контрольных битов
    for i = 1, #bits do
        -- если не вышли за массив
        local pos = getControlBitPos(i)
        if pos <= #bits then
            table.insert(bits, pos, 0)
        end
    end

    -- вычисление контрольных битов
    for i = 1, #bits do
        -- если не вышли за массив
        local pos = getControlBitPos(i)

        if pos <= #bits then
            bits[pos] = checkParity(bits, i)
        end
    end
end

function hammingDecode(bits)
    local badBit = 0

    -- вычисление контрольных битов
    for i = 1, #bits do
        -- если не вышли за массив
        local pos = getControlBitPos(i)
        local noMatch = bits[pos] ~= checkParity(bits, i)

        if pos <= #bits and noMatch then
            print("Не совпало значение контрольного бита: " .. i)
            badBit = badBit + pos
        end
    end

    -- исправляем неправильный бит (инвертируем)
    if (badBit ~= 0) then
        inverseBit(bits, badBit)
        print("Исправлен бит: " .. badBit)
    end

    -- отбрасываем контрольные биты
    -- начинать нужно с последнего
    for i = #bits, 1, -1 do
        -- если не вышли за массив
        local pos = getControlBitPos(i)

        if (pos > 0 and pos <= #bits) then
            table.remove(bits, getControlBitPos(i))
        end
    end
end

function printBits(bits, divideBy)
    for i = 1, #bits do
        io.write(bits[i])

        if i % divideBy == 0 then
            io.write(" ")
        end
    end

    print("")
end

function test0()
    local str = "habrahabr"

    for i = 1, #str * 8 do
        local bits = tobits(str)

        --[[  print("Исходные данные: (" .. #bits .. " бит)")
        printBits(bits, 0) ]]
        hammingCode(bits)
        --[[  print("Кодирование по Хеммингу")
        printBits(bits, 0) ]]
        -- портим данные
        inverseBit(bits, i)
        print("Поврежден бит " .. i)

        hammingDecode(bits)
        --[[  print("Декодирование по Хеммингу")
        printBits(bits, 0) ]]
    end
end

function test1()
    bits = tobits("habrahabr")
end

function insertBit(byte, b, pos)
    if b ~= 0 then
        b = 1
    end -- гарантируем что в качестве бита пришел 0 или единица

    -- гарантируем что позиция задана в рамках одного байта
    if pos > 8 then
        print("error: position > 8")
        pos = 8
    end
    if pos < 1 then
        print("error: position < 1")
        pos = 1
    end

    byte = bit.band(byte, 0xFF) -- гарантируем что бит 8

    local carried = bit.band(bit.rshift(byte, 7), 1) -- бит, перенесенный из старшего разряда
    local mask = bit.rshift(0xFF, 8 - pos + 1) -- маска для разделения байта на части
    local low = bit.band(byte, mask) -- сохраняем младшие биты
    local high = bit.band(bit.bnot(mask), byte) -- старшие биты

    byte = bit.band(bit.bor(bit.bor(bit.lshift(high, 1), low), bit.lshift(b, pos - 1)), 0xFF)

    result = {}

    result.byte = byte
    result.carried = carried

    return result
end

function removeBit(byte, pos)
    -- гарантируем что позиция задана в рамках одного байта
    if pos > 8 then
        print("error: position > 8")
        pos = 8
    end
    if pos < 1 then
        print("error: position < 1")
        pos = 1
    end

    byte = bit.band(byte, 0xFF) -- гарантируем что бит 8

    local mask = bit.rshift(0xFF, 8 - pos + 1) -- маска для разделения байта на части
    local low = bit.band(byte, mask) -- сохраняем младшие биты
    local high = bit.band(bit.bnot(mask), byte) -- старшие биты

    local nulMask = bit.rol(0xFE, pos - 1)
    high = bit.band(high, nulMask) -- обнуляем младший бит среди старших
    high = bit.rshift(high, 1) -- сдвигаем старшую часть

    byte = bit.bor(high, low)

    return byte
end

function getBit(byte, pos)
    result = 0

    byte = bit.band(byte, 0xFF) -- гарантируем что бит 8
    -- гарантируем что позиция задана в рамках одного байта
    if pos > 8 then
        print("error: position > 8")
        pos = 8
    end
    if pos < 1 then
        print("error: position < 1")
        pos = 1
    end

    if (bit.band(byte, bit.lshift(1, pos - 1)) > 0) then
        result = 1
    end

    return result
end

function test2()
    local byte = 5
    local result = insertBit(byte, 0, 1)

    print(result.byte)
    print(result.carried)

    result = removeBit(byte, 3)

    print(getBit(10, 1))
    print(getBit(10, 2))
    print(getBit(10, 3))
    print(getBit(10, 4))
end

test2()

p()
