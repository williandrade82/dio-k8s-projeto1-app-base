@echo off
REM VARIÁVEIS
REM -------------------------

rem PREFIX : Define prefixo para os objetos do projeto.
REM ATENÇÃO: quando alterar essa informação, ajustar no arquivo deployment.yaml também.
set PREFIX=projeto-deploy

rem TAG : Define a TAG das imagens a serem criadas. Serão criadas todas com a mesma TAG de Versão
set TAG=v2.0

REM CMD : Comando docker a ser utilizado.
REM São suportados os comandos 'docker' e 'nerdctl'
set CMD=nerdctl

REM USER_DOCKERHUB : Nome do usuário do dockerhub.
REM Lembre-se de deixar o usuário logado já, com o comando %CMD% login
REM ATENÇÃO: quando alterar essa informação, ajustar no arquivo deployment.yaml também.
set USER_DOCKERHUB=williandrade82

REM NAMESPACE : Nome do namespace a ser utilizado.
REM Nao é obrigatório, mas ajuda a organizar os objetos no kubernetes.
set NAMESPACE=ns-deploy

REM DEBUG : [ ON | OFF ] O modo debug irá pausar a cada execução
set DEBUG=ONLY
set DEBUG_MESSAGE=Pausa do DEBUG

REM --------------------------------------
REM FINAL DAS VARIÁVEIS
REM --------------------------------------
REM Não altere daqui pra baixo se não tiver certeza do que está fazendo.

REM #############################################################
if "%DEBUG%"=="ONLY" goto debug_only

REM INICIALIZAÇÃO - Criando as imagens localmente
set PREFIX=%USER_DOCKERHUB%/%PREFIX%
echo.
echo Criando imagem do banco de dados. Prefix: %PREFIX%
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause

cd database
%CMD% build . -t %PREFIX%-db:%TAG%

echo.
echo Criando imagem do backend
cd ../backend
%CMD% build . -t %PREFIX%-backend:%TAG%
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause

cd ..
REM Enviando imagens para o dockerhub
echo.
echo -------------------------------------------
echo Enviando imagens criadas para o dockerhub
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause
%CMD% push %PREFIX%-db:%TAG%
%CMD% push %PREFIX%-backend:%TAG%

echo.
echo Atualizando os versões [latest] do projeto
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause
%CMD% tag %PREFIX%-db:%TAG% %PREFIX%-db:latest
%CMD% tag %PREFIX%-backend:%TAG% %PREFIX%-backend:latest
%CMD% push %PREFIX%-db:latest
%CMD% push %PREFIX%-backend:latest

echo.
echo -------------------------------------------
echo Fazendo o deploy do ambiente em Kubernetes
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause

if "%NAMESPACE%"=="" (
    set NAMESPACE=default
) else (
    kubectl create namespace %NAMESPACE%
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause
)

kubectl config set-context --current --namespace=%NAMESPACE%
echo Namespace de organizacao: %NAMESPACE%

echo Dados do cluster
kubectl get nodes
echo.
echo -------------------------------------------
echo Criando o ambiente
if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause
kubectl apply -f manifests/.

echo ------------------------------------------
echo Processo finalizado. Abrindo o frontend localmente

if "%DEBUG%"=="ON" echo %DEBUG_MESSAGE% && pause
start frontend/index.html

if "%DEBUG%"=="ON" (
    :debug_only
    echo Iniciando o servico para debug 
    kubectl apply -f 99-debug-service.yaml
    set DEBUG=
    echo.
    echo Servico do mysql esta publicado na porta 30001 do hostlocal
    echo.
    echo Conteudo atual:
    :loop
        echo ------------------------------------------------------------------------------------------------
        kubectl exec pod/projeto-deploy-database-0 -- /bin/bash -c "mysql -u root -pSenha123 -D meubanco -e \"select * from mensagens;\""
        set /p input="Digite 's' para sair e interromper o loop ou pressione. Enter para continuar: "
        if /i "%input%"=="s" goto end
    goto loop
    :end
    echo Finalizando...
)
