### FOLLOWING COMMANDS ARE TO BE RUN FROM infra FOLDER ###

set IMAGE_NAME=axcloud/jenkins-local
set WORKDIR=/var/jenkins/agent
set ENV_ID=uatsg-it1
set CONTAINER_NAME=jenkins-local-%ENV_ID%

####################################################

### Build Docker image ###

docker build -t %IMAGE_NAME%:latest -f local/Dockerfile .

####################################################


### Start & Stop container ###

# Start container with 3 readonly volumes: .aws (for credentials), infra folder (act as the repo), infra/local/scripts folder (for scripts mimicking Jenkins pipeline run)
docker run -d -t --name=%CONTAINER_NAME% -e ENV_ID=%ENV_ID% -v %USERPROFILE%\.aws:/var/jenkins/.aws:ro -v %CD%:/repo:ro -v %CD%/local/scripts:/scripts:ro %IMAGE_NAME%

# Remove container
docker stop %CONTAINER_NAME% && docker rm /%CONTAINER_NAME%

####################################################


### Resync Infra ###

# Full terraform initialization
docker exec %CONTAINER_NAME% /scripts/init.sh

# Create a new shell session in the container
docker exec -it %CONTAINER_NAME% bash
# Plan re-syncing
terraform plan -input=false -out=tfplan
# Apply to Environment
terraform apply tfplan

####################################################


### More shortcuts ###

# Copy all files from infra folder
docker cp %CD%/. %CONTAINER_NAME%:%WORKDIR%

# Change owner of all files in a directory
docker exec -u root %CONTAINER_NAME% chown -R jenkins: %WORKDIR%


### Additional option for container ###

# Option to share ssh certs (if CodeCommit access is required)
# add this to docker run: -v %USERPROFILE%\.ssh:/var/jenkins/.ssh:ro

# Option to have .terraform folder saved
mkdir %USERPROFILE%\.terraform\%ENV_ID%
# add this to docker run: -v %USERPROFILE%\.terraform\%ENV_ID%:%WORKDIR%/.terraform

####################################################
