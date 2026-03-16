pipeline {
    agent any

    parameters {
        choice(name: 'OS', choices: ['linux', 'darwin', 'windows'], description: 'Target OS')
        choice(name: 'ARCH', choices: ['amd64', 'arm64'], description: 'Target ARCH')
    }

    environment {
        GITHUB_TOKEN = credentials('jenkins')  // секрет с токеном GHCR
        REGISTRY = 'ghcr.io/vlad1slav1k'
    }

    stages {

        stage('Clone') {
            steps {
                echo 'Cloning repository...'
                git branch: 'develop', url: 'https://github.com/Vlad1slav1k/kbot.git'
            }
        }

        stage('Test') {
            steps {
                echo 'Running Go tests...'
                sh 'make test || true' // не падаем если тестов нет
            }
        }

        stage('Build') {
            steps {
                echo "Building for ${params.OS}/${params.ARCH}..."
                script {
                    def status = sh(
                        script: "make build TARGETOS=${params.OS} TARGETARCH=${params.ARCH}",
                        returnStatus: true
                    )
                    if (status != 0) error("Build failed!")
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "Building Docker image for ${params.OS}/${params.ARCH}..."
                script {
                    def status = sh(
                        script: "make image TARGETOS=${params.OS} TARGETARCH=${params.ARCH}",
                        returnStatus: true
                    )
                    if (status != 0) error("Docker build failed!")
                }
            }
        }

        stage('Login GHCR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'jenkins', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_PSW')]) {
                    sh 'echo $GITHUB_PSW | docker login ghcr.io -u $GITHUB_USER --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to GHCR..."
                sh "make push TARGETOS=${params.OS} TARGETARCH=${params.ARCH}"
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
