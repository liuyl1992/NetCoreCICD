FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-stretch-slim AS base

RUN groupadd -r chaunce && useradd -r -s /bin/false -g chaunce chaunce #新增用户

WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-stretch AS build
WORKDIR /src
COPY ["NetCoreCICD.csproj", ""]
RUN dotnet restore "NetCoreCICD.csproj"
COPY . .
WORKDIR "/src/"
RUN dotnet build "NetCoreCICD.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "NetCoreCICD.csproj" -c Release -o /app
RUN ls -l
RUN pwd
RUN rm -rf /src
RUN cd /
RUN ls -l

FROM base AS final
WORKDIR /app
COPY --from=publish /app .

RUN chown -R chaunce:chaunce /app #限制app目录权限
USER chaunce

ENTRYPOINT ["dotnet", "NetCoreCICD.dll"]
