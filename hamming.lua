function tobin(num)
    local t = {}
    while num > 0 do
        rest = math.fmod(num, 2)
        t[#t + 1] = rest
        num = (num - rest) / 2
    end

    -- дополняем нулями до целого числа байт если нужно
    for i = 1, (8 - #t % 8) do
        t[#t + 1] = 0
    end

    return t
end

function tobits(str)
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


    for i=1, #str*8 do

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


function bitsToStr(bits)
    -- нужно иметь ввиду биты были развернуты в обратном порядке


end

function test1()
    bits = tobits("habrahabr")
end

test0()
