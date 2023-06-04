defmodule BumbumWeb.Live.Answerer do
  use BumbumWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    task = Task.async(fn ->
      Logger.info("Start loading models")
      model()
    end)

    Process.send(self(), {:update_status, task}, [])

    socket =
      socket
      |> assign(:status, "not loaded")
      |> assign(:content, "he capital of [MASK] is Paris.")
      |> assign(:context, ~s/The Amazon rainforest (Portuguese: Floresta Amazônica or Amazônia; Spanish: Selva Amazónica, Amazonía or usually Amazonia; French: Forêt amazonienne; Dutch: Amazoneregenwoud), also known in English as Amazonia or the Amazon Jungle, is a moist broadleaf forest that covers most of the Amazon basin of South America. This basin encompasses 7,000,000 square kilometres (2,700,000 sq mi), of which 5,500,000 square kilometres (2,100,000 sq mi) are covered by the rainforest. This region includes territory belonging to nine nations. The majority of the forest is contained within Brazil, with 60% of the rainforest, followed by Peru with 13%, Colombia with 10%, and with minor amounts in Venezuela, Ecuador, Bolivia, Guyana, Suriname and French Guiana. States or departments in four nations contain "Amazonas" in their names. The Amazon represents over half of the planet's remaining rainforests, and comprises the largest and most biodiverse tract of tropical rainforest in the world, with an estimated 390 billion individual trees divided into 16,000 species./)
      |> assign(:question, "What is the Spanish name for The Amazons")
      |> assign(:model, false)
      |> assign(:output, "")
      |> assign(:score, 0)

    {:ok, socket}
  end

  def handle_info({:update_status, task}, socket) do
    Logger.info(info: "Handling info!")
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

  def handle_event("submit", %{"context" => context, "question" => question}, socket) do
    if (socket.assigns.model == false) do
      Logger.warn("Submit not ready!")
      Process.sleep(250)
    end

    %{roberta: roberta, tokenizer: tokenizer} = socket.assigns.model

    %{results: results} = Nx.Serving.run(
      Bumblebee.Text.question_answering(roberta, tokenizer),
      %{question: question, context: context}
    )

    [%{text: text, score: score} | _] = results

    socket =
      socket
      |> assign(:context, context)
      |> assign(:question, question)
      |> assign(:output, text)
      |> assign(:score, score)

      {:noreply, socket}
  end

  def model() do
      {:ok, roberta} = Bumblebee.load_model({:hf, "deepset/roberta-base-squad2"})
      {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "roberta-base"})

      %{roberta: roberta, tokenizer: tokenizer}
  end

end
