#
# GaroAvisa API - Global Solution 2026/2 (CitizenTech)
# Script de infraestrutura (Azure CLI) - executar no Azure Cloud Shell (Bash)
#
# VERIFIQUE SE ESTA COM A ASSINATURA CORRETA
#
# az account show
# az account list -o table
# az account set --subscription "nome-da-assinatura-correta"


# Variáveis
RESOURCE_GROUP_NAME="rg-gs-garoavisa-rm565698"
WEBAPP_NAME="gs-garoavisa-rm565698"
APP_SERVICE_PLAN="gs-garoavisa-rm565698"
LOCATION="canadacentral"
RUNTIME="DOTNETCORE:10.0"
APP_INSIGHTS_NAME="ai-gs-garoavisa-rm565698"
USERNAME="rm565698"
PASSWORD="xxxxxx"
ORACLE_CONNECTION="User Id=$USERNAME;Password=$PASSWORD;Data Source=oracle.fiap.com.br:1521/ORCL;"
JWT_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"


# Registrar os Serviços utilizados
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ServiceLinker

# Registrar a extensão utilizada
az extension add --name application-insights

# Criação do Grupo de Recursos
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location "$LOCATION"

# Criar Application Insights
az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location "$LOCATION" \
  --resource-group $RESOURCE_GROUP_NAME \
  --application-type web


# Criar o Plano de Serviço
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --sku F1 \
  --is-linux


# Criar o Serviço de Aplicativo (API .NET 10)
az webapp create \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --plan $APP_SERVICE_PLAN \
  --runtime "$RUNTIME"

# Recuperar a String de Conexão do Application Insights (assim podemos nos conectar a esse App Insights)
CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query connectionString \
  --output tsv)

# Configurar as Variáveis de Ambiente necessárias do nosso App e do Application Insights
# ConnectionStrings__OracleConnection e Jwt__Key são lidas pela API .NET
# (equivalem a ConnectionStrings:OracleConnection e Jwt:Key do appsettings.json)
az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="Recommended" \
    XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
    ASPNETCORE_ENVIRONMENT="Production" \
    ConnectionStrings__OracleConnection="$ORACLE_CONNECTION" \
    Jwt__Key="$JWT_KEY"

# Reiniciar o Web App
az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME

# Criar a conexão do nosso Web App com o Application Insights
az monitor app-insights component connect-webapp \
    --app $APP_INSIGHTS_NAME \
    --web-app $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP_NAME
