#Fully Inspired by
# https://github.com/thilaire/rpi-TM1638/blob/master/rpi_TM1638/Font.py
#Modifications so it works with Elixir Ale GPIO
defmodule TM1638.GPIO do
  defstruct DIO: nil, CLK: nil, STB: nil

end


defmodule TM1638 do
  defstruct DIO: nil, CLK: nil, STB: nil, DIOINPUT: nil, brightness: 1, GPIO:  %{DIO: nil, CLK: nil, STB: nil}
  #TODO multiple stb's
  require Logger
  require Enum
  use Bitwise
  use GenServer
  #alias ElixirALE.GPIO
  alias GpioRpi, as: GPIO

  @read_mode 0x02
  @write_mode 0x00
  @incr_addr  0x00
  @fixed_addr 0x04

  # The bits are displayed by mapping bellow
  #  -- 0 --
  # |       |
  # 5       1
  # |       |
  #  -- 6 --
  # |       |
  # 4       2
  # |       |
  #  -- 3 --   o 7

  @font  %{
    " " =>  0b00000000,  # (32) <space>
    "!" =>  0b10000110,  # (33) !
    "\"" =>  0b00100010,  # (34) "
    "(" =>  0b00110000,  # (40) (
    ")" =>  0b00000110,  # (41) )
    "," =>  0b00000100,  # (44) ,
    "-" =>  0b01000000,  # (45) -
    "." =>  0b10000000,  # (46) .
    "/" =>  0b01010010,  # (47) /
    "0" =>  0b00111111,  # (48) 0
    "1" =>  0b00000110,  # (49) 1
    "2" =>  0b01011011,  # (50) 2
    "3" =>  0b01001111,  # (51) 3
    "4" =>  0b01100110,  # (52) 4
    "5" =>  0b01101101,  # (53) 5
    "6" =>  0b01111101,  # (54) 6
    "7" =>  0b00100111,  # (55) 7
    "8" =>  0b01111111,  # (56) 8
    "9" =>  0b01101111,  # (57) 9
    "=" =>  0b01001000,  # (61) = \
    "?" =>  0b01010011,  # (63) ?
    "@" =>  0b01011111,  # (64) @
    "A" =>  0b01110111,  # (65) A
    "B" =>  0b01111111,  # (66) B
    "C" =>  0b00111001,  # (67) C
    "D" =>  0b00111111,  # (68) D
    "E" =>  0b01111001,  # (69) E
    "F" =>  0b01110001,  # (70) F
    "G" =>  0b00111101,  # (71) G
    "H" =>  0b01110110,  # (72) H
    "I" =>  0b00000110,  # (73) I
    "J" =>  0b00011111,  # (74) J
    "K" =>  0b01101001,  # (75) K
    "L" =>  0b00111000,  # (76) L
    "M" =>  0b00010101,  # (77) M
    "N" =>  0b00110111,  # (78) N
    "O" =>  0b00111111,  # (79) O
    "P" =>  0b01110011,  # (80) P
    "Q" =>  0b01100111,  # (81) Q
    "R" =>  0b00110001,  # (82) R
    "S" =>  0b01101101,  # (83) S
    "T" =>  0b01111000,  # (84) T
    "U" =>  0b00111110,  # (85) U
    "V" =>  0b00101010,  # (86) V
    "W" =>  0b00011101,  # (87) W
    "X" =>  0b01110110,  # (88) X
    "Y" =>  0b01101110,  # (89) Y
    "Z" =>  0b01011011,  # (90) Z
    "[" =>  0b00111001,  # (91) [ \
    "]" =>  0b00001111,  # (93) ]
    "_" =>  0b00001000,  # (95) _
    "`" =>  0b00100000,  # (96) `
    "a" =>  0b01011111,  # (97) a
    "b" =>  0b01111100,  # (98) b
    "c" =>  0b01011000,  # (99) c
    "d" =>  0b01011110,  # (100) d
    "e" =>  0b01111011,  # (101) e
    "f" =>  0b00110001,  # (102) f
    "g" =>  0b01101111,  # (103) g
    "h" =>  0b01110100,  # (104) h
    "i" =>  0b00000100,  # (105) i
    "j" =>  0b00001110,  # (106) j
    "k" =>  0b01110101,  # (107) k
    "l" =>  0b00110000,  # (108) l
    "m" =>  0b01010101,  # (109) m
    "n" =>  0b01010100,  # (110) n
    "o" =>  0b01011100,  # (111) o
    "p" =>  0b01110011,  # (112) p
    "q" =>  0b01100111,  # (113) q
    "r" =>  0b01010000,  # (114) r
    "s" =>  0b01101101,  # (115) s
    "t" =>  0b01111000,  # (116) t
    "u" =>  0b00011100,  # (117) u
    "v" =>  0b00101010,  # (118) v
    "w" =>  0b00011101,  # (119) w
    "x" =>  0b01110110,  # (120) x
    "y" =>  0b01101110,  # (121) y
    "z" =>  0b01000111,  # (122) z
    "{" =>  0b01000110,  # (123) { \
    "|" =>  0b00000110,  # (124) |
    "}" =>  0b01110000,  # (125) }
    "~" =>  0b00000001,  # (126) ~
  }


  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end



  def init(dio,clk,stb,brightness \\ 1) do

    #  if isinstance(stb, int):
    #			tm._stb = (stb,)
    #		else:
    #tm._stb = tuple(stb)

    {:ok, diopid} = GPIO.start_link(dio, :output)
    {:ok, clkpid} = GPIO.start_link(clk, :output)
    {:ok, stbpid} = GPIO.start_link(stb, :output)
    #  {:ok, dioinput} = GPIO.start_link(dio, :input)
    dioinput =1
    Logger.debug "GPIO connections #{inspect clkpid} #{inspect diopid} #{inspect stbpid}"
    #for stb in tm._stb:
    #GPIO.setup(stb, GPIO.OUT)

    tm = %TM1638{DIO: diopid, CLK: clkpid, STB: stbpid, DIOINPUT: dioinput, brightness: brightness, GPIO: %{DIO: dio, CLK: clk, STB: stb}}
    doStuff(tm)
    Logger.debug "assign issues..?"
    #High STB and CLK
    setStb(tm, :true)

    GPIO.write(clkpid, :true)

    #init the display
    turnOn(tm,brightness)
    clearDisplay(tm)
    Logger.debug "Successfully loaded TM 1638"

    #spawn a listening process
    #spawn fn -> listen_forever(tm) end
    {:ok, tm}
  end

  def doStuff (tm) do

  end




  @doc  """
  Clear the display
  Turn off every led
  """
  def clearDisplay(tm) do
    tm
    setStb(tm,:false )
    setDataMode(tm, @write_mode, @incr_addr)   # set data read mode (automatic address increased)
    sendByte(tm, 0xC0)   # address command set to the 1st address
    for i <- 1..16 do
      sendByte(tm, 0x00)   # set to zero all the addresses
    end
    setStb(tm, :true)
  end

  @doc  """
  Turn off (physically) the leds
  """
  def turnOff(tm) do
    sendCommand(tm, 0x80)
  end

  @doc  """
  Turn on the display and set the brightness
  The pulse width used is set to:
  0 => 1/16       4 => 11/16
  1 => 2/16       5 => 12/16
  2 => 4/16       6 => 13/16
  3 => 10/16      7 => 14/16
  :param brightness: between 0 and 7
  :param TMindex: number of the TM to turn on (None if it's for all the TM)
  """
  def turnOn(tm, brightness) do
    sendCommand(tm, 0x88 ||| (brightness &&& 7))
  end

  @doc  """
  Set Leds
  :param index: index of the led or tuple of indexes
  :param value: (boolean) value to give for this led (it could be a int, evaluated as boolean)

  # the leds are on the bit 0 of the odd addresses (led[0] on address 1, led[1] on address 3)
  # leds from 8 to 15 are on chained TM #2, etc.
  """
  def leds(tm, index, value) do
    value =  cond  do
      value == :true ->        1
      value == :false ->         0
      true -> value
    end
    sendData(tm, rem(index, 8) * 2 + 1, value) # , Integer.floor_div(index,8))
  end

  # ==========================
  # Communication with the TM
  # (mainly used by TMBoards)
  # ==========================
  @doc """
  Send a command
  :param cmd: cmd to send
  :param TMindex: number of the TM to send the command (None if it's for all the TM)
  """
  #TODO all commands to return tm ! so we can PIPE
  def sendCommand(tm, cmd) do

    setStb(tm, :false)
    sendByte(tm, cmd)
    setStb(tm, :true)
  end

  @doc   """
  Send a data at address addr

  ## Parameters
  - addr: adress of the data
  - data: value of the data
  """
  def sendData(tm, addr, data) do
    # set mode
    setStb(tm, :false)
    setDataMode(tm, @write_mode, @fixed_addr)
    setStb(tm,:true)
    # set address and send byte (stb must go high and low before sending address)
    setStb(tm,:false)
    sendByte(tm, 0xC0 ||| addr)
    sendByte(tm, data)
    setStb(tm, :true)
  end

  # ==================
  # Internal functions
  # ==================
  @doc  """
  Set STROBE value
  :param value: value given to the Stb(s)
  """
  defp setStb(tm, value) do
    #def _setStb(tm, value, TMindex) do

    #  if TMindex  == :none do
    #  for stb in tm._stb:
    #    stb = tm.STB
    # Map.get(tm,:STM)
    #  pid = Map.get(tm,:STM)
    #  IO.puts "STM #{inspect tm} and #{inspect pid}"
    GPIO.write(Map.get(tm,:STB), value)
    #  else
    #    GPIO.output(tm._stb[TMindex], value)
    #  end

  end

  @doc   		"""
  Set the data modes
  :param wr_mode: READ_MODE (read the key scan) or WRITE_MODE (write data)
  :param addr_mode: INCR_ADDR (automatic address increased) or FIXED_ADDR
  """
  def setDataMode(tm, wr_mode, addr_mode) do

    sendByte(tm, 0x40 ||| wr_mode ||| addr_mode)
  end


  defp sendByte(tm, data, 0) do

  end
  @doc 		"""
  Send a byte (STROBE must be Low)

  Sending a bit from a byte consists of setting the STROBE to low
  Then setting to CLOCK to low, sending the bit via DIO and
  setting the clock back to HIGH..
  :param data: a byte to send
  """
  defp sendByte(tm, data, counter \\ 8) when counter >= 1 do

    #  for i <- 1..8 do
    GPIO.write(Map.get(tm,:CLK), :false)
    GPIO.write(Map.get(tm,:DIO), (data &&& 1) == 1)
    GPIO.write(Map.get(tm,:CLK), :true)
    cool = (data &&& 1) == 1
#    Logger.debug "Byte #{inspect data} counter #{inspect counter} current #{cool}"
    data = data >>> 1

    sendByte(tm,data,counter-1)
    #end
  end


  @doc """
  Get the data (buttons) of the TM
  :return: the four octets read (as a list)
  """
  def getData(tm) do
    # set in read mode
    setStb(tm, :false)
    setDataMode(tm, @read_mode, @incr_addr)
    #	TODO SLEEP  in microseconds
    #sleep(20e-6) # wait at least 10µs ?
    # read four bytes
    bytes = Enum.map(1..4, fn (x) ->  getByte(tm) end)
    setStb(tm,:true)
    bytes
  end


  @doc  """
  Receive a byte (from the TM previously configured)
  :return: the byte received
  """
  def getByte(tm) do

    # TODO configure DIO in input with pull-up
  #  GPIO.write(Map.get(tm,:DIO),0)
    GPIO.set_direction(Map.get(tm,:DIO), :input, [mode: :up])
    GPIO.set_int(Map.get(tm,:DIO), :rising)


    # read 8 bits
    temp = Enum.reduce(1..8, 0, fn (x,temp) ->
      temp = temp >>> 1
      GPIO.write(Map.get(tm,:CLK), :false)
      #  if GPIO.read(Map.get(tm,:DIO)) do
      if   get_bit_from_byte(tm) do
        temp =  temp ||| 0x80
      end
      GPIO.write(Map.get(tm,:CLK), :true)
      temp
    end)

    # TODO put back DIO in output mode
    GPIO.set_direction(Map.get(tm,:DIO), :output)

    temp
  end


  @doc """
  Changes the mode to :input or :output for GPIO
  It first releases the existing process, then starts a new one
  """
  def set_mode(tm, gpio, mode) do
    GPIO.release(Map.get(tm,gpio))
    GPIO.start_link(Map.get(tm,:DIO))
  end

  defp listen_forever(tm, input_pid \\ 0) do
    #GPIO.read(pid) works too
    # Start listening for interrupts on rising and falling edges
    #    GPIO.set_int(input_pid, :both)
    #    listen_loop()

    data = getData(tm)
    if data != nil do
      Logger.debug "Got data #{inspect data}"
    end

    #  GPIO.set_int(input_pid, :both)

    listen_forever(tm)
  end

  #rising = button pressed, :falling -> button released
  defp get_bit_from_byte(tm) do
    receive do
      {:gpio_interrupt, p, :rising} ->
        Logger.debug "Received rising event on pin #{p}"
        1
      {:gpio_interrupt, p, :falling} ->
          Logger.debug "Received falling event on pin #{p}"
      end
        #    get_bit_from_byte(tm)
        0
    end

      #BUG display locations 0 & 5 have a problem
      @doc """
      Example:
      TM1638.display_segment(tm,1, "")
      -> set the i-th 7-segment display (and all the following, according to the length of value1)
      all the 7-segment displays after the #i are filled by the characters in value1
      this could be one-character string (so 7-segment #i is set to that character)
      or a longer string, and the following 7-segment displays are modified accordingly
      Example:
      TM.segments[0] = '8'    -> the display #0 is set to '8'
      or
      TM.segments[0] = '456'  -> the display #0 is set to '4', the display #1 to '5' and #2 to '6'
      or
      TM.segments[i,j] = boolean
      -> set the j-th segment of the i-th 7-segment
      Example:
      TM.segments[2,3] = True -> set the 3rd segment of the 2nd 7-segment display
      i: index of the 7-segment display (0 for the 1st 7-segments (left of the 1st TM Board), 8 for the 1st of the 2nd board, etc.)
      j: number of the segment (between 0 and 8)
      :param index: index of the 7-segment, or tuple (i,j)
      :param value: string (or one-character string) when index is a int, otherwise a boolean
      """
      def display_segment(tm, index, value) do

        charbyte =  Map.get(@font,value)
        if charbyte === nil do
          raise "Cannot display character #{inspect value}"
        end
        #  sendData(tm, rem(index , 8) * 2, val, index // 8)
        sendData(tm, rem(index , 8) * 2, charbyte)
      end

      @doc """
      Displays text starting from the correct position
      """
      def display_text(tm, text, start \\ 0) do
        #split_text = List.delete_at(String.split(text,""),-1)
        split_text = text |> String.split("") |> List.delete_at(-1)
        Enum.with_index(split_text,start)
        |> Enum.each(fn ({char,location}) ->
          display_segment(tm,location,char)
        end)
      end

      def display_moving_text(tm,text, speed \\ 500, start \\ 8 )  do
        Enum.each(1..100, fn (x) ->
           TM1638.clearDisplay(tm)
           TM1638.display_text(tm, text, start - x )
           Process.sleep(speed)
         end)
    end


    end
    #{:ok, tm}  = TM1638.init(22,27,17)
    #{:ok, tm}  = TM1638.init(11,09,10)
    #TM1638.leds(tm,1,:true)
    #TN1638.display_segment(tm,1,"3")
    #TM1638.sendData(tm,rem(4,8)*2,0b1)
    #TM1638.display_text(tm,"Andrei")
#TM1638.display_moving_text(tm,"Adriana")
