defmodule FlowRunner.Spec.Blocks.Message do
  @moduledoc """
  A type of block that sends a message to the user.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  def validate_config!(%{"prompt" => prompt}) do
    config = %{prompt: prompt}

    if Vex.valid?(config, prompt: [presence: true, uuid: true]) do
      config
    else
      raise "invalid 'config' for MobilePrimitive.Message block, 'prompt' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid 'config' for MobilePrimitive.Message block, 'prompt' field is required and needs to be a UUID."
  end

  def evaluate_incoming(%Flow{} = flow, %Block{} = block, context, container) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.prompt)

    case Resource.matching_resource(resource, context.language, context.mode, flow) do
      {:ok, prompt} ->
        {:ok, value} = Expression.evaluate(prompt.value, context.vars)

        {
          :ok,
          %Context{context | waiting_for_user_input: false, last_block_uuid: block.uuid},
          %Output{
            prompt: %{value: value}
          }
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end
