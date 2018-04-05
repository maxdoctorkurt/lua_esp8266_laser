function toBin(num)
    -- returns a table of bits, least significant first.
    local t={} -- will contain the bits
    while num>0 do
        rest=math.fmod(num,2)
        t[#t+1]=rest
        num=(num-rest)/2
    end

    -- дополняем нулями если нужно
    for i=1,(8 - #t % 8) do
        t[#t+1] = 0 
    end 

    return t
end

function bits(str)
    
    local result = {}
    
    for i=1,#str do

        local b = toBin(str:byte(i))
        for j=1,#b do
            result[#result+1] = b[#b+1-j]
        end
  
    end

    return result
    
end

s = "Ab"

r = bits(s)

for i=1,#r do
    io.write(r[i])
end

