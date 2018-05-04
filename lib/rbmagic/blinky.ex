defmodule Blinky do
  use GenServer
  #Genserver or Application.. init for GenServer - start for Application
  #use Application

  @moduledoc """
  TODO use genserver better
  Simple example to blink a LED light
  on a breadboard which is wired to GPIO #18.
  """

  require Logger
  alias ElixirALE.GPIO

  @on_duration  1000 # ms
  @off_duration 500 # ms
  @gpio_pin 18 #connect to GPIO pin #18
  @gpio_on 1
  @gpio_off 0
  @input_pin 10

  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end


  def init(_type, _args) do

    Logger.debug "Blinkenlights forever on pin #{@gpio_pin}"
    {:ok, pid} = GPIO.start_link(@gpio_pin, :output)

    spawn(fn ->  blink_led_forever(pid) end)

    #Input listening
    Logger.info "Starting pin #{@input_pin} as input"
    {:ok, input_pid} = GPIO.start_link(@input_pin, :input)
    spawn fn -> listen_forever(input_pid) end

    {:ok, self()}
  end

  defp blink_led_forever(pid) do
    GPIO.write(pid, @gpio_on)
    Process.sleep(@on_duration)
    GPIO.write(pid, @gpio_off)
    Process.sleep(@off_duration)

    blink_led_forever(pid)
  end

  defp listen_forever(input_pid) do
    #GPIO.read(pid) works too
    # Start listening for interrupts on rising and falling edges
    GPIO.set_int(input_pid, :both)
    listen_loop()
  end

  defp listen_loop() do
    # Infinite loop receiving interrupts from gpio
    receive do
      {:gpio_interrupt, p, :rising} ->
        Logger.debug "Received rising event on pin #{p}"
        {:gpio_interrupt, p, :falling} ->
          Logger.debug "Received falling event on pin #{p}"
        end
        listen_loop()
      end


    end
