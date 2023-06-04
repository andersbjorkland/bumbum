defmodule BumbumWeb.Live.Sentiment do
  use BumbumWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do

    task = Task.async(fn ->
      Logger.info("Start loading Sentiment model")
      load_model()
    end)

    Process.send(self(), {:update_model, task}, [])

    socket =
      socket
      |> assign(:model, false)
      |> assign(:input, "")
      |> assign(:output, "")
      |> assign(:score, "")
      |> assign(:status, "Not ready")

    {:ok, socket}
  end

  def handle_info({:update_model, task}, socket) do
    timeout = 60000
    result = case Task.yield(task, timeout) do
      {:ok, result} ->
        result

      nil ->
        Logger.warn("Failed to get a result in #{timeout}ms")
        nil
    end

    socket =
      socket
      |> assign(:status, "ready")
      |> assign(:model, result)

    {:noreply, socket}
  end

  def handle_event("submit", %{"context" => input}, socket) do
    if (socket.assigns.model == false) do
      Logger.warn("Submit not ready!")
      Process.sleep(250)
    end

    %{sentiment: model, tokenizer: tokenizer} = socket.assigns.model

    %{predictions: predictions} = Nx.Serving.run(
      Bumblebee.Text.text_classification(model, tokenizer),
      input
    )

    [%{label: label, score: score} | _] = predictions

    socket =
      socket
      |> assign(:input, input)
      |> assign(:output, label)
      |> assign(:score, score)

      {:noreply, socket}
  end

  def load_model() do
    {:ok, sentiment} = Bumblebee.load_model({:hf, "distilbert-base-uncased-finetuned-sst-2-english"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "distilbert-base-uncased"})

    %{sentiment: sentiment, tokenizer: tokenizer}
end
end
