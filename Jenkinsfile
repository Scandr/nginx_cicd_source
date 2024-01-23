    podTemplate(containers: [
        containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:v1.19.2-debug', ttyEnabled: true, command: 'sleep', args: '99d'),
        // containerTemplate(name: 'jnlp', image: 'jenkins/inbound-agent:latest-jdk17', command: 'sleep', args: '99d', ttyEnabled: true)
        // containerTemplate(name: 'jnlp', image: 'jenkins/inbound-agent', args: '${computer.jnlpmac} ${computer.name}')
        containerTemplate(name: 'git', image: 'bitnami/git', command: 'sleep', args: '99d')
//         containerTemplate(name: 'kubectl', image: 'bitnami/kubectl:1.28.6', command: 'sleep', args: '99d')
    ]){
        properties([
            pipelineTriggers([
    //             github(
    //             triggerOnPush: true,
    //             triggerOnMergeRequest: true,
    //             triggerOpenMergeRequestOnPush: "source",
    //             branchFilterType: "All",
    //             triggerOnNoteRequest: false)
                pollSCM('5 * * * *') // every 5 min
            ])

        ])
        node(POD_LABEL) {
            // container('jnlp') {
            container('git') {
                stage('Git checkout') {
                    env.BUILD_VERSION = scm.getBranches()[0].toString()
                    sh 'env'
                    sh '''
                    git config --global --add safe.directory $WORKSPACE
                    '''
                    //env.BUILD_VERSION = "main"
                    //git branch: env.BUILD_VERSION,
                    //    url: 'https://github.com/Scandr/nginx_cicd_source.git'
                    //     credentialsId: 'git_creds'
                    checkout scmGit(branches: [[name: "${env.BUILD_VERSION}"]],
                        userRemoteConfigs: [[ url: 'https://github.com/Scandr/nginx_cicd_source.git' ]])
                    env.GIT_TAG_NAME = sh(script: '''git describe --tags | awk -F"-" '/-/{print $1}' ''', returnStdout: true).trim()
                }
            }
            container('kaniko') {
                stage('Build nginx image') {
                    //withCredentials([usernamePassword(credentialsID: 'docker-cred', variable: 'USERPASS')]){
                    withCredentials([string(credentialsId:'docker-token', variable: 'DOCKER_TOKEN')]) {
                        sh '''
                        export DOCKER_CONFIG=/kaniko/.docker
                        #export USERPASS = "$USERNAME:$PASSWORD"
                        #export AUTH=$(echo -n "${USERNAME}:${PASSWORD}" | base64)
                        printf "{\\"auths\\": {\\"https://index.docker.io/v1/\\": {\\"auth\\": \\"$DOCKER_TOKEN\\"}}}\\n" > /kaniko/.docker/config.json
                        #printf "{\\"auths\\": {\\"docker.io\\": {\\"auth\\": \\"%s\\"}}}\\n" $(echo -n "$USERNAME:$PASSWORD" | base64) > /kaniko/.docker/config.json
                        '''
                        sh 'ls -la /kaniko/.docker'
                        sh 'ls -la '
                        sh 'cat /kaniko/.docker/config.json'
                        sh 'cp -r /kaniko/.docker /root/ '
                        withEnv(["PATH=/busybox:/kaniko:${env.PATH}"]){
                            sh '''#!/busybox/sh
                            /kaniko/executor version
                            '''
                        }
                        //withCredentials([usernamePassword(credentialsID: "", usernameVariable: 'LOGIN', passwordVariable: 'PASS')]){
                            sh """#!/busybox/sh
                                /kaniko/executor --verbosity debug --dockerfile ${env.WORKSPACE}/Dockerfile --destination "docker.io/xillah/nginx:${env.BUILD_VERSION}" --context dir://${env.WORKSPACE} --registry-mirror "docker.io" --cleanup --ignore-path=/busybox
                            """
                        //}
                    }
                }
            }
            if (env.GIT_TAG_NAME){
                container('git') {
                    stage('Update image'){
                        withCredentials([
                        file(credentialsId: 'kube-client-cert', variable: 'KUBE_CLIENT_CERT'),
                        file(credentialsId: 'kube-client-key', variable: 'KUBE_CLIENT_KEY'),
                        ]){
                        // must be set in env vars for multibranch pipeline
                        println("KUBE_SERVER = " + env.KUBE_SERVER)
                        //input message: "input request"

                        sh '''
                            echo "GIT_TAG_NAME = ${GIT_TAG_NAME}"
                            #sed -i "/\\        image:/c \\        image: 'xillah/nginx:${GIT_TAG_NAME}'" ${WORKSPACE}/kuber_manifests/deployment.yml
                            #cat ${WORKSPACE}/kuber_manifests/deployment.yml
                            cp $KUBE_CLIENT_CERT ${WORKSPACE}/kube-client-cert.pem
                            cp $KUBE_CLIENT_KEY ${WORKSPACE}/kube-key-cert.pem
                            export NEW_IMAGE="xillah/nginx:$GIT_TAG_NAME"
                            curl --cert ${WORKSPACE}/kube-client-cert.pem --key ${WORKSPACE}/kube-key-cert.pem -k $KUBE_SERVER/apis/apps/v1/namespaces/nginx/deployments/nginx-deployment -X PATCH -H 'Content-Type: application/strategic-merge-patch+json' -d '{"spec": {"template": {"spec": {"containers": [{"name": "nginx","image": $NEW_IMAGE}]}}}}'
                        '''
                        }
                    }
                }
            }
        }
    }