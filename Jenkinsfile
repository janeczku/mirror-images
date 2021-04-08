pipeline {
    agent any
	
    parameters {
        string(name: 'registry', defaultValue: '', description: 'The URL (without schema) of the container registry to import the images to (including namespace basepath if any)')
		string(name: 'registryCredentialId', defaultValue: '', description: 'ID of the Jenkins username/password credential to use for authentication with the private registry')
    }

    stages {

        stage('Mirror vendor images') {
            steps {
				script {
					if (params.registry == '') {
						currentBuild.result = 'ABORTED'
						error('registry parameter was not set')
					}
				}

				docker.withRegistry(${params.registry}, ${params.registryCredentialId}) {
					sh './mirror.sh -r ${params.registry}'
				}
            }
        }

    }
}
