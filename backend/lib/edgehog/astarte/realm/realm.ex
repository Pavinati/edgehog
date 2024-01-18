#
# This file is part of Edgehog.
#
# Copyright 2021-2023 SECO Mind Srl
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
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.Astarte.Realm do
  use Edgehog.MultitenantResource

  alias Edgehog.Validations

  code_interface do
    define_for Edgehog.Astarte
    define :fetch_by_name, action: :by_name, args: [:name]
    define :create
    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    read :by_name do
      get_by :name
    end

    create :create do
      primary? true

      argument :cluster_id, :integer, allow_nil?: false

      change manage_relationship(:cluster_id, :cluster, type: :append)
    end
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string, allow_nil?: false

    attribute :private_key, :string do
      allow_nil? false
      constraints trim?: false
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :cluster, Edgehog.Astarte.Cluster
  end

  identities do
    identity :name_tenant_id, [:name, :tenant_id]
    identity :name_cluster_id, [:name, :cluster_id]
  end

  validations do
    validate Validations.realm_name(:name)
    validate {Validations.PEMPrivateKey, attribute: :private_key}
  end

  postgres do
    table "realms"
    repo Edgehog.Repo
  end
end