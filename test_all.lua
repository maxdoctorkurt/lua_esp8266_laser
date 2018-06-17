string = require("string")



-- Коды операций 
OPCODE_GET_DATA = "1"
OPCODE_SET_DATA = "2"
OPCODE_ECHO = "3"
OPCODE_ACK = "4"

-- индексы буфера
INDEX_POWER_HUNDREDS = 1
INDEX_POWER_REST = 2
INDEX_IMPULSE_LENGTH = 3
INDEX_BETWEEN_IMP_T = 4
INDEX_MIX_MODE_EXP_T = 5
INDEX_MIX_MODE_CONT = 6
INDEX_VOLUME = 7
INDEX_BRIGHTNESS_PERC = 8

-- выходной буфер данных (отправляется к медицинскому прибору после подтверждения от компьютера хирурга)
outputBufferVals = ""

-- входной буфер данных (данные полученные от прибора)
inputBufferVals = ""

function makeBody(opcode, data)
  return "{opcode:" .. "\"" .. opcode .. "\", data:" .. "\"" .. data .. "\"}"
end

function setupUart()

    local dataFromMedDevice = ""
    local uartDataBegan = false

    uart.on(
        "data",
        0, 
        function(data)
            print("Пришли данные = " .. data)

            local l
            local r

            l, r = string.find(data, "{") -- начало входящих данных

            if l ~= nil then
                dataFromMedDevice = string.sub(data, l + 1)
                uartDataBegan = true
            elseif uartDataBegan then
                dataFromMedDevice = dataFromMedDevice .. data
            end

            l, r = string.find(data, "}") -- конец входящих данных
            
            if l ~= nil and uartDataBegan then
                dataFromMedDevice = string.sub(dataFromMedDevice, 1, l - 1)
                inputBufferVals = dataFromMedDevice -- сохраняем полученные данные 
                dataFromMedDevice = ""
                uartDataBegan = false
            end
            
        end,
        0
    )

    uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

    mytimer = tmr.create()
    mytimer:register(1000, tmr.ALARM_AUTO, function() 
        uart.write(0, "{}") -- раз в секунду "опрашиваем" мед прибор 
    end)
    mytimer:start()

end

function configure()

  wifi.setmode(wifi.SOFTAP)
  local cfg={}
  cfg.ssid="LaserServer"
  cfg.pwd="00000000"
  wifi.ap.config(cfg)

  -- uart.alt(0)
  uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

  local srv = net.createServer(net.TCP)
  
  srv:listen(80,function(conn)
    conn:on("receive",function(conn,payload)

      local s = tostring(payload)
      local opcode = string.match(s, "opcode[^:]*:[^:\"]*\"([^\"]*)\"") -- код операции
      local data = string.match(s, "data[^:]*:[^:\"]*\"([^\"]*)\"") -- данные

      local headers = "HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html; charset=utf-8\r\n\r\n"

      local body = "{}"

      if opcode ~= nil and data ~= nil then

        -- сохраняем данные и отсылаем "эхо"
        if opcode == OPCODE_SET_DATA then
          body = makeBody(OPCODE_ECHO, data)
          outputBufferVals = data
        end

        -- передаем данные лазеру по uart
        if opcode == OPCODE_ACK and #outputBufferVals > 0 then
          uart.write(0, "{" .. outputBufferVals .. "}")
        end

        -- "отдаем" заранее считанные данные с лазера по uart
        if opcode == OPCODE_GET_DATA then
          body = makeBody(OPCODE_ECHO, inputBufferVals)
        end

      end

      conn:send(headers .. body)
     
    end)

    conn:on("sent", function(c) c:close() end)
  end)

  setupUart()
end




configure()

