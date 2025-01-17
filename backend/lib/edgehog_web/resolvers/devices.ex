#
# This file is part of Edgehog.
#
# Copyright 2021 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule EdgehogWeb.Resolvers.Devices do
  alias Edgehog.Devices
  alias Edgehog.Devices.HardwareType
  alias Edgehog.Devices.SystemModel

  def find_hardware_type(%{id: id}, _resolution) do
    Devices.fetch_hardware_type(id)
  end

  def list_hardware_types(_parent, _args, _context) do
    {:ok, Devices.list_hardware_types()}
  end

  def extract_hardware_type_part_numbers(
        %HardwareType{part_numbers: part_numbers},
        _args,
        _context
      ) do
    part_numbers = Enum.map(part_numbers, &Map.get(&1, :part_number))

    {:ok, part_numbers}
  end

  def create_hardware_type(_parent, attrs, _context) do
    with {:ok, hardware_type} <- Devices.create_hardware_type(attrs) do
      {:ok, %{hardware_type: hardware_type}}
    end
  end

  def update_hardware_type(_parent, %{hardware_type_id: id} = attrs, _context) do
    with {:ok, %HardwareType{} = hardware_type} <- Devices.fetch_hardware_type(id),
         {:ok, %HardwareType{} = hardware_type} <-
           Devices.update_hardware_type(hardware_type, attrs) do
      {:ok, %{hardware_type: hardware_type}}
    end
  end

  def find_system_model(%{id: id}, %{context: context}) do
    with {:ok, system_model} <- Devices.fetch_system_model(id) do
      system_model = localize_system_model_description(system_model, context)
      {:ok, system_model}
    end
  end

  def list_system_models(_parent, _args, %{context: context}) do
    system_models =
      Devices.list_system_models()
      |> localize_system_model_description(context)

    {:ok, system_models}
  end

  defp localize_system_model_description(target, %{locale: locale}) do
    # Explicit locale, use that one
    Devices.preload_localized_descriptions_for_system_model(target, locale)
  end

  defp localize_system_model_description(target, %{current_tenant: tenant}) do
    # Fallback
    %{default_locale: default_locale} = tenant

    Devices.preload_localized_descriptions_for_system_model(target, default_locale)
  end

  def extract_system_model_part_numbers(
        %SystemModel{part_numbers: part_numbers},
        _args,
        _context
      ) do
    part_numbers = Enum.map(part_numbers, &Map.get(&1, :part_number))

    {:ok, part_numbers}
  end

  def create_system_model(_parent, %{hardware_type_id: hw_type_id} = attrs, %{
        context: %{current_tenant: current_tenant}
      }) do
    default_locale = current_tenant.default_locale

    with {:ok, hardware_type} <- Devices.fetch_hardware_type(hw_type_id),
         :ok <- check_description_locale(attrs[:description], default_locale),
         attrs = wrap_description(attrs),
         {:ok, system_model} <-
           Devices.create_system_model(hardware_type, attrs) do
      system_model =
        system_model
        |> Devices.preload_localized_descriptions_for_system_model(default_locale)

      {:ok, %{system_model: system_model}}
    end
  end

  def update_system_model(_parent, %{system_model_id: id} = attrs, %{
        context: %{current_tenant: current_tenant}
      }) do
    default_locale = current_tenant.default_locale

    with {:ok, %SystemModel{} = system_model} <- Devices.fetch_system_model(id),
         :ok <- check_description_locale(attrs[:description], default_locale),
         attrs = wrap_description(attrs),
         system_model =
           system_model
           |> Devices.preload_localized_descriptions_for_system_model(default_locale),
         {:ok, %SystemModel{} = system_model} <-
           Devices.update_system_model(system_model, attrs) do
      system_model =
        system_model
        |> Devices.preload_localized_descriptions_for_system_model(default_locale)

      {:ok, %{system_model: system_model}}
    end
  end

  # Only allow a description that uses the tenant default locale in {create,update}_system_model
  defp check_description_locale(nil, _default_locale), do: :ok
  defp check_description_locale(%{locale: default_locale}, default_locale), do: :ok
  defp check_description_locale(%{locale: _other}, _default), do: {:error, :not_default_locale}

  # If it's there, wraps description to descriptions, as {create,update}_system_model expects a list
  defp wrap_description(%{description: description} = attrs) do
    attrs
    |> Map.delete(:description)
    |> Map.put(:descriptions, [description])
  end

  defp wrap_description(attrs), do: attrs

  def extract_localized_description(%SystemModel{descriptions: descriptions}, %{}, _context) do
    # We should always either 0 or 1 description here since the upper layer should take care
    # of only preloading the localized description.
    case descriptions do
      [description] -> {:ok, description}
      _ -> {:ok, nil}
    end
  end
end
