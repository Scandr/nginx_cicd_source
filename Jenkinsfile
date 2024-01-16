podTemplate(label: 'nginx_build_pod', containers: [
    containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:latest', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'git', image: 'alpine/git', command: 'cat', ttyEnabled: true)
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
    node('nginx_build_pod') {
        container('git') {
            stage('Git checkout') {
                env.BUILD_VERSION = scm.getBranches()[0].toString()
                git branch: env.BUILD_VERSION,
                    url: 'https://github.com/Scandr/nginx_cicd_source.git'
//                     credentialsId: 'git_creds'
            }
        }
        container('kaniko') {
            stage('Build nginx image') {
                withCredentials([usernameColonPassword(credentialsID: "docker-cred", variable: 'USERPASS')]){
                    sh ' printf "{\\"auths\\": {\\"docker.io\\": {\\"auth\\": \\"%s\\"}}}\\n" $(echo -n $USERPASS | base64) > /kaniko/.docker/config.json '
                    sh 'ls -la /kaniko/.docker'
                    sh 'ls -la '
                    sh 'cat /kaniko/.docker/config.json'
                    withEnv(["PATH=/busybox:/kaniko:${env.PATH}"]){
                        sh '''#!/busybox/sh
                        /kaniko/executor version
                        '''
                    }
                    withCredentials([usernamePassword(credentialsID: "", usernameVariable: 'LOGIN', passwordVariable: 'PASS')]){
                        sh """#!/busybox/sh
                            /kaniko/executor --vebrosity debug --dockerfile ${env.WORKSPACE}/Dockerfile --destination "docker.io/xillah/nginx:${env.BUILD_VERSION}" --context dir://${env.WORKSPACE} --registry-mirror "docker.io" --cleanup --ignore-path=/busybox
                        """
                    }
                }
            }
        }
    }
}