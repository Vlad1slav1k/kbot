pipeline {
    agent any

    parameters {
        choice(name: 'OS', choices: ['linux', 'apple', 'windows'], description: 'Pick OS')
        choice(name: 'ARCH', choices: ['amd64', 'arm64'], description: 'Pick ARCH')
    }

    environment {
        GITHUB_TOKEN = credentials('jenkins')
        REPO = 'https://github.com/Vlad1slav1k/kbot.git'
        BRANCH = 'develop'
        REGISTRY = 'ghcr.io/vlad1slav1k'
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
                sh "make TARGETOS=${params.OS} TARGETARCH=${params.ARCH} test"
            }
        }

        stage('Build') {
            steps {
                echo "Building binary for ${params.OS}-${params.ARCH}"
                sh "make TARGETOS=${params.OS} TARGETARCH=${params.ARCH} build"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image for ${params.OS}-${params.ARCH}"
                sh "make TARGETOS=${params.OS} TARGETARCH=${params.ARCH} image"
            }
        }

        stage('Login to GHCR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-packages',
                        usernameVariable: 'GITHUB_USER',
                        passwordVariable: 'GITHUB_TOKEN_PSW'
                    )
                ]) {
                    sh 'echo $GITHUB_TOKEN_PSW | docker login ghcr.io -u $GITHUB_USER --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "make TARGETOS=${params.OS} TARGETARCH=${params.ARCH} push"
            }
        }
    }

    post {
        always {
            echo 'Logging out from Docker...'
            sh 'docker logout'
        }
    }
}
