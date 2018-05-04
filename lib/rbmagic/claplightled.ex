

defmodule ClapLightLed do
  use GenServer
  @moduledoc """
  Clap to Light and close led!
  """

  require Logger
  alias ElixirALE.GPIO

  @on_duration  1000 # ms
  @gpio_led %{red: 14, green: 15 , blue: 18}
  @gpio_sensor
  @gpio_on 1
  @gpio_off 0
  @input_pin 17

  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end


  def init(_type, _args) do

    Logger.debug "Change Light based on clap"
    {:ok, red_pid} = GPIO.start_link(@gpio_led.red, :output)
    {:ok, green_pid} = GPIO.start_link(@gpio_led.green, :output)
    {:ok, blue_pid} = GPIO.start_link(@gpio_led.blue, :output)
    {:ok, sound_detector_pid} = GPIO.start_link(@input_pid, :input)

    rgb_led_settings = %{red: red_pid, green: green_pid, blue: blue_pid, blue_status: 0, green_status: 0, red_status: 0}

    #  spawn(fn ->  blink_led_forever(rgb_led_settings) end)

    #Input listening
    Logger.info "Starting pin #{@input_pin} as input"
    {:ok, input_pid} = GPIO.start_link(@input_pin, :input)
    spawn fn -> listen_forever(input_pid, rgb_led_settings) end

    {:ok, self()}
  end

  defp change_rgb_randomly(rgb_led_settings) do

    rand_nr = rand(1,3)
    #  Process.sleep(@on_duration)
    #  GPIO.write(rgb_led_settings.green, @gpio_off)
    #  Process.sleep(@on_duration)
    #  GPIO.write(rgb_led_settings.blue, @gpio_off)
    #  Process.sleep(@on_duration)

    #  blink_led_forever(rgb_led_settings)
    led_pid = case rand_nr do
      1 -> rgb_led_settings.red
      2 -> rgb_led_settings.green
      3 -> rgb_led_settings.blue
    end
    GPIO.write(led_pid, @gpio_on)
    Process.sleep(3500)
    GPIO.write(led_pid, @gpio_off)
  end

  defp listen_forever(input_pid,rgb_led_settings) do
    #GPIO.read(pid) works too
    # Start listening for interrupts on rising and falling edges
    GPIO.set_int(input_pid, :rising)
    listen_loop(rgb_led_settings)
  end

  defp listen_loop(rgb_led_settings) do
    # Infinite loop receiving interrupts from gpio
    receive do
      {:gpio_interrupt, p, :rising} ->
        Logger.debug "Received rising event on pin #{p}"
          spawn fn -> change_rgb_randomly(rgb_led_settings) end
        Process.sleep(500)
        {:gpio_interrupt, p, :falling} ->
          Logger.debug "Received falling event on pin #{p}"
    end
      listen_loop(rgb_led_settings)
    end


    def rand(min,max) do
      min - 1 + :rand.uniform(max-min+1)
    end

  end
