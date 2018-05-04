defmodule BlinkLeds do
  use GenServer
  @moduledoc """
    BlinkLeds blinks multiple leds connected at the led_list GPIO ports
    REMEMBER to always put resistors with the leds or you can fry your board!
  """

  require Logger
  require Enum
  alias ElixirALE.GPIO

  @on_duration  1000 # ms
  @off_duration 500 # ms
  @gpio_on 1
  @gpio_off 0

  @led_list  [17, 18, 27]

  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end


  def init(_type, _args) do

    Logger.debug "Blink Multiple Leds #{inspect @led_list}"
    led_pids  =  Enum.map(@led_list, fn(led) ->
      {:ok, pid} = GPIO.start_link(led, :output)
      #  led_pids = [ pid | led_pids ]
      Logger.debug "Pid #{inspect pid}"
      pid
    end)
    Logger.debug "Current led pids #{inspect led_pids}"
#    spawn(fn ->  blink_list_forever(led_pids) end)
    start_blinking(led_pids)

    {:ok, self()}
  end

  # call blink_led on each led in the list sequence, repeating forever
  defp start_blinking(led_list) do
    Enum.each(led_list, &async_blink(&1))
  #  blink_list_forever(led_list)
  end

  defp async_blink(pid) do
    spawn(fn ->  blink_led(pid) end )
  end

  defp blink_led(pid) do
  #  Logger.debug "Blinking #{inspect pid} !"
    GPIO.write(pid, @gpio_on)
    on_duration = rand(500, 1200)
    Process.sleep(on_duration)
   off_duration = rand(300, 1000)
    GPIO.write(pid, @gpio_off)
    Process.sleep(off_duration)
    blink_led(pid)

  end

  def rand(min,max) do
    min - 1 + :rand.uniform(max-min+1)
  end

  def disableLed(pid) do
    GPIO.write(pid,0)
    GPIO.release(pid)
  end

#Release
#ElixirALE.GPIO.release(pid("0.225.0"))

end

# BlinkLeds.init([],[])
