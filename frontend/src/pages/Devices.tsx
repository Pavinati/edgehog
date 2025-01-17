/*
  This file is part of Edgehog.

  Copyright 2021 SECO Mind Srl

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import React, { Suspense, useEffect, useMemo } from "react";
import { FormattedMessage } from "react-intl";
import { ErrorBoundary } from "react-error-boundary";
import graphql from "babel-plugin-relay/macro";
import {
  usePreloadedQuery,
  useQueryLoader,
  PreloadedQuery,
} from "react-relay/hooks";

import type { Devices_getDevices_Query } from "api/__generated__/Devices_getDevices_Query.graphql";
import Center from "components/Center";
import DevicesTable from "components/DevicesTable";
import Page from "components/Page";
import Spinner from "components/Spinner";

const GET_DEVICES_QUERY = graphql`
  query Devices_getDevices_Query {
    devices {
      id
      deviceId
      lastConnection
      lastDisconnection
      name
      online
      systemModel {
        name
        hardwareType {
          name
        }
      }
    }
  }
`;

interface DevicesContentProps {
  getDevicesQuery: PreloadedQuery<Devices_getDevices_Query>;
}

const DevicesContent = ({ getDevicesQuery }: DevicesContentProps) => {
  const devicesData = usePreloadedQuery(GET_DEVICES_QUERY, getDevicesQuery);

  // TODO: handle readonly type without mapping to mutable type
  const devices = useMemo(
    () => devicesData.devices.map((device) => ({ ...device })),
    [devicesData]
  );

  return (
    <Page>
      <Page.Header
        title={
          <FormattedMessage id="pages.Devices.title" defaultMessage="Devices" />
        }
      />
      <Page.Main>
        <DevicesTable data={devices} />
      </Page.Main>
    </Page>
  );
};

const DevicesPage = () => {
  const [getDevicesQuery, getDevices] =
    useQueryLoader<Devices_getDevices_Query>(GET_DEVICES_QUERY);

  useEffect(() => getDevices({}), [getDevices]);

  return (
    <Suspense
      fallback={
        <Center data-testid="page-loading">
          <Spinner />
        </Center>
      }
    >
      <ErrorBoundary
        FallbackComponent={(props) => (
          <Center data-testid="page-error">
            <Page.LoadingError onRetry={props.resetErrorBoundary} />
          </Center>
        )}
        onReset={() => getDevices({})}
      >
        {getDevicesQuery && (
          <DevicesContent getDevicesQuery={getDevicesQuery} />
        )}
      </ErrorBoundary>
    </Suspense>
  );
};

export default DevicesPage;
