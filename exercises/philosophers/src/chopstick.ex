defmodule Chopstick do

  def start() do
    ## We link to the dinner process inorder to avoid zombie chopsticks
    stick = spawn_link(fn -> init() end)
    {:stick, stick}
  end

  def start(node) do
    ## We link to the dinner process inorder to avoid zombie chopsticks
    stick = Node.spawn_link(node, fn -> init() end)
    {:stick, stick}
  end  

  # The synchronous version of requesting a chopstick.
  def request({:stick, pid}) do
    send(pid, {:request, self()})

    receive do
      :granted -> :ok
    end
  end

  def return({:stick, pid}) do
    send(pid, :return)
  end

  
  # Using a timeout to detect deadlock, does it work?
  def request({:stick, pid}, timeout) do
    send(pid, {:request, self()})

    receive do
      :granted ->
        :ok
    after
      timeout ->
        :no
    end
  end

  # The better version, we keep track of requests.
  def request({:stick, pid}, ref, timeout) do
    send(pid, {:request, ref, self()})
    wait(ref, timeout)
  end

  defp wait(ref, timeout) do
    receive do
      {:granted, ^ref} ->
        :ok

      {:granted, _} ->
	## this is an old message that we must ignore
        wait(ref, timeout)
    after
      timeout ->
        :no
    end
  end

  # Return a ref taged stick
  def return({:stick, pid}, ref) do
    send(pid, {:return, ref})
  end
  
  
  # A asynchronous request, divided into sending the
  # request and waiting for the reply.
  def asynch({:stick, pid}, ref) do
    send(pid, {:request, ref, self()})
  end

  # Don't throw anything away (since there are no old messages)
  def synch(ref) do
    receive do
      {:granted, ^ref} ->
        :ok
    end
  end
  
  # To terminate the process.
  def quit({:stick, pid}) do
    send(pid, :quit)
  end

  # Initalizing the chopstick.
  defp init(), do: available()

  # The two states of the chopstick.
  defp available() do
    receive do
      {:request, from} ->
        send(from, :granted)
        gone()
      
      {:request, ref, from} ->
	## only used when we use refs
        send(from, {:granted, ref})
        gone(ref)
      
      :quit ->
        :ok
    end
  end

  defp gone() do
    receive do
      :return ->
        available()

      :quit ->
        :ok
    end
  end

  defp gone(ref) do
    receive do
      {:return, ^ref}->
	available()

      :quit ->
        :ok
    end
  end
  
  
end
