pipeline {
    agent any

    parameters {
        choice(name: 'OS', choices: ['linux','apple','windows'], description: 'Pick OS')
        choice(name: 'ARCH', choices: ['amd64','arm64'], description: 'Pick ARCH')
    }

    environment {
        GITHUB_TOKEN = credentials('jenkins')
        REPO = 'https://github.com/Vlad1slav1k/kbot.git'
        BRANCH = 'develop'
    }

    stages {

        stage('clone') {
            steps {
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }

        stage('test') {
            steps {
                sh 'make test'
            }
        }

       stage('build') {
          steps {
              echo "Building binary for platform ${params.OS} on ${params.ARCH} started"
              sh "make build-${params.OS}-${params.ARCH}"
    }
}

        stage('image') {
            steps {
               sh "make ${params.OS} ${params.ARCH}"
            }
        }

        stage('login GHCR') {
            steps {
                sh "echo $GITHUB_TOKEN_PSW | docker login ghcr.io -u $GITHUB_TOKEN_USR --password-stdin"
            }
        }

        stage('push image') {
            steps {
                sh "make ${params.OS} ${params.ARCH} image push"
            }
        }

        stage('logout') {
            steps {
                sh 'docker logout || true'
            }
        }
    }
}
