# Containerized Development Environment
A containerized development environment is provided. It leverage docker/docker-compose to standup:
* A debugging container that has conftest, tflocal, and terraform installed
* A containerized [localstack](https://github.com/localstack/localstack) environment that simulates an AWS account.

## Starting the debugging Environment 
1. Open a command prompt or terminal in the demo-env directory.
2. Run ```docker-compose up``` or ```podman compose up```. If this is the first time you are starting the containers it may take a little time for it to download everything and start. 
3. In a new terminal type ```docker exec -it demo-env-runtime-1 bash``` or ```podman exec -it demo-env-runtime-1 bash```. This will open a shell in our debugging environment.
   
NOTE : _The working directory in the container is workspace_

When debugging inside the container, run ```tflocal``` instead of ```terraform```. For instance instead ```terraform init``` run ```tflocal init```.