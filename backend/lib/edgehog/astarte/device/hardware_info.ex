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

defmodule Edgehog.Astarte.Device.HardwareInfo do
  defstruct [
    :cpu_architecture,
    :cpu_model,
    :cpu_model_name,
    :cpu_vendor,
    :memory_total_bytes
  ]

  alias Astarte.Client.AppEngine
  alias Edgehog.Astarte.Device.HardwareInfo

  @interface "io.edgehog.devicemanager.HardwareInfo"

  def get(%AppEngine{} = client, device_id) do
    # TODO: right now we request the whole interface at once, so `memory_total_bytes` can't
    # be requested as string (see https://github.com/astarte-platform/astarte/issues/630).
    # Request it as string as soon as that issue is solved.
    with {:ok, %{"data" => data}} <-
           AppEngine.Devices.get_properties_data(client, device_id, @interface) do
      hardware_info = %HardwareInfo{
        cpu_architecture: data["cpu"]["architecture"],
        cpu_model: data["cpu"]["model"],
        cpu_model_name: data["cpu"]["modelName"],
        cpu_vendor: data["cpu"]["vendor"],
        memory_total_bytes: data["mem"]["totalBytes"]
      }

      {:ok, hardware_info}
    end
  end
end
