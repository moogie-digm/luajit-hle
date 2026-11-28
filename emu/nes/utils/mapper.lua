write_mmc1 = function(addr, val)
    for i = 0, 4 do
        cpu.write(addr, (val >> i) & 1)
    end
end
