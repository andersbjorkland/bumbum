defmodule BumbumWeb.Live.TextToken do
  use BumbumWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    task = Task.async(fn ->
      Logger.info("Loading BERT base Named Entity Recognition")
      load_model()
    end)

    Process.send(self(), {:update_model, task}, [])

    socket =
      socket
      |> assign(:status, "not ready")
      |> assign(:model, false)
      |> assign(:input, "Rachel Green works at Ralph Lauren in New York City in the sitcom Friends")
      |> assign(:entities, [])
      |> assign(:output, "")

    {:ok, socket}
  end

  def load_model() do
    {:ok, bert} = Bumblebee.load_model({:hf, "dslim/bert-base-NER"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "bert-base-cased"})

      %{bert: bert, tokenizer: tokenizer}
  end

  def handle_info({:update_model, task}, socket) do
    timeout = 60000

    result = case Task.yield(task, timeout) do
      {:ok, result} -> result
      nil ->
        Logger.warn("Failed to get a result in #{timeout}")
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

    %{bert: bert, tokenizer: tokenizer} = socket.assigns.model

    serving = Bumblebee.Text.token_classification(bert, tokenizer, aggregation: :same)

    %{entities: entities} = Nx.Serving.run(serving, input)

    Logger.info(entities: entities)

    output = Enum.reduce(entities, input, fn term, acc ->
      String.replace(
        acc,
        term.phrase,
        "<span class=\"#{term.label}\">#{term.phrase}</span><sub class=\"term-class\">#{term.label}</sub>"
      )
    end)

    socket =
      socket
      |> assign(:entities, entities)
      |> assign(:output, output)

    {:noreply, socket}
  end
end
