defmodule LaserFun do
  use GenServer
  @moduledoc """
Laser Fun!
  """

  require Logger
  require Enum
  alias ElixirALE.GPIO


  @gpio_on 1
  @gpio_off 0



  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end


  def init(_, _) do
    {:ok, laser} = GPIO.start_link(17, :output)
#    pid = spawn(fn -> loop(laser) end)
    pid = spawn(fn ->  turn_on(laser) end)
#    turn_on(laser) 
    {:ok, pid}
  end

  def loop(laser) do
    :timer.sleep(200)
    turn_on(laser)

    :timer.sleep(200)
    turn_off(laser)

    loop(laser)
  end

  defp turn_on(pid) do
    GPIO.write(pid, 0)
  end

  defp turn_off(pid) do
    GPIO.write(pid, 1)
  end

end
#LaserFun.init("","")
