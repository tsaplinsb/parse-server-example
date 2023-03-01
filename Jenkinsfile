pipeline {
    environment {
    WORKDIR = '/kaniko/workspace'
    REPOSITORY_URI = 'https://github.com/tsaplinsb'
    REPOSITORY_NAME = 'parse-server-example'
  }
  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
  }

  agent {
    kubernetes {
      yamlFile 'builder.yaml'
    }

  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Clone git repos') {
      steps {
        container('git') {
          script {
            sh "if [ ! -d ${WORKDIR}/${REPOSITORY_NAME} ]; then git clone ${REPOSITORY_URI}/${REPOSITORY_NAME} ${WORKDIR}/${REPOSITORY_NAME} ; fi"
            sh "git -C ${WORKDIR}/${REPOSITORY_NAME} pull ${REPOSITORY_URI}/${REPOSITORY_NAME}"
          }

        }

      }
    }

    stage('Kaniko Build & Push Image') {
      steps {
        container('kaniko') {
          script {
            sh "/kaniko/executor --dockerfile ${WORKDIR}/${REPOSITORY_NAME}/Dockerfile \
            --context ${WORKDIR} \
            --force \
            --destination=cr.yandex/crp7qupp94a729rvpl8o/${REPOSITORY_NAME}:${BUILD_NUMBER} \
            --destination=cr.yandex/crp7qupp94a729rvpl8o/${REPOSITORY_NAME}:latest" 
          }

        }

      }
    }
    // Deploy to k8s
    stage('Deploy') {
      steps {
          container('helm-cli') {
            script {
              withKubeConfig([credentialsId: 'kubernetes-creds', serverUrl: 'https://10.30.73.85', namespace: 'parse-server-example']) {
                      
                      
                      sh "cd ${WORKDIR}/${REPOSITORY_NAME}/helm/app"
                      sh "helm dependency build"
                      
                      sh "helm upgrade ${REPOSITORY_NAME} ${WORKDIR}/${REPOSITORY_NAME}/helm/app --install \
                          --namespace ${REPOSITORY_NAME} --create-namespace \
                          --set image.tag=\"${BUILD_NUMBER}\""

                      sh "helm repo add bitnami https://charts.bitnami.com/bitnami"


                      sh "helm upgrade mongodb bitnami/mongodb --install \
                          --namespace ${REPOSITORY_NAME} --create-namespace \
                          --values ${WORKDIR}/${REPOSITORY_NAME}/helm/mongodb/mongodb-values.yaml"                          
              }
          }
      }
    }
  }
  }  
}