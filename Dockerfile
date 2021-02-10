# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://mcr.microsoft.com/v2/dotnet/sdk/tags/list
FROM mcr.microsoft.com/dotnet/sdk:5.0.103-focal-amd64 AS build
WORKDIR /app
COPY src/cartservice.csproj ./src/
WORKDIR /app/src
RUN dotnet restore cartservice.csproj -r linux-musl-x64
COPY src/ .

FROM build AS unittests
WORKDIR /app
COPY tests/unittests/cartservice.unittests.csproj ./tests/unittests/
WORKDIR /app/tests/unittests
RUN dotnet restore cartservice.unittests.csproj
COPY tests/unittests/ .
# Fix the issue on Debian 10: https://github.com/dotnet/dotnet-docker/issues/2470
ENV COMPlus_EnableDiagnostics=0
RUN dotnet test cartservice.unittests.csproj --no-restore


FROM build AS publish
WORKDIR /app/src
# Fix the issue on Debian 10: https://github.com/dotnet/dotnet-docker/issues/2470
ENV COMPlus_EnableDiagnostics=0
RUN dotnet publish cartservice.csproj -p:PublishSingleFile=true -r linux-musl-x64 --self-contained true -p:PublishTrimmed=True -p:TrimMode=Link -c release -o out --no-restore


# https://mcr.microsoft.com/v2/dotnet/runtime-deps/tags/list
FROM mcr.microsoft.com/dotnet/runtime-deps:5.0.2-alpine3.12-amd64
RUN GRPC_HEALTH_PROBE_VERSION=v0.3.6 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
WORKDIR /app
COPY --from=publish /app/src/out ./
ENV ASPNETCORE_URLS http://*:7070
EXPOSE 7070
# OPT OUT OF Diagnostic pipeline so we can run readonly.
ENV COMPlus_EnableDiagnostics=0
USER 1000
ENTRYPOINT ["/app/cartservice"]