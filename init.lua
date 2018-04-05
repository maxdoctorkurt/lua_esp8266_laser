string = require("string")

-- Коды операций 
OPCODE_GET_DATA = "1"
OPCODE_INPUT_DATA = "2"
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

function makeBody(opcode, data, csum)
  return "{opcode:" .. "\"" .. opcode .. "\", data:" .. "\"" .. data .. "\", csum:" .. "\"" .. csum .. "\"}"
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
      local csum = string.match(s, "csum[^:]*:[^:\"]*\"([^\"]*)\"") -- контрольная сумма

      local headers = "HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html; charset=utf-8\r\n\r\n"

      local body = "{}"

      if opcode ~= nil and data ~= nil and csum ~= nil then

        -- сохраняем данные и отсылаем "эхо"
        if opcode == OPCODE_INPUT_DATA then
          body = makeBody(OPCODE_ECHO, data, csum)
          outputBufferVals = data
        end

        -- передаем данные лазеру по uart
        if opcode == OPCODE_ACK then
          uart.write(0, outputBufferVals)
        end

        -- "считываем"" данные с лазера по uart
        if opcode == OPCODE_GET_DATA then
          body = makeBody(OPCODE_INPUT_DATA, outputBufferVals, csum)
        end

      end

      conn:send(headers .. body)
     
    end)

    conn:on("sent", function(c) c:close() end)
  end)
end

configure()
