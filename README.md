# Set up Jenkins
## Credentials
- name: docker-token <br>
   cred type: secret text <br>
   description: docker token to push nginx image to the registry, can be retrieved from $USER/.docker/config.json<br>
- name: kube-client-cert<br>
   cred type: secret file<br>
   description: PEM cert from kuber to connect to the cluster for nginx update. From kuber admin.conf  client-certificate-data<br>
- name: kube-client-key<br>
   cred type: secret file<br>
   description: PEM cert from kuber to connect to the cluster for nginx update. From kuber admin.conf  client-key-data<br>

### How to get kuber certs
```
echo 'LS0tLS1CR...long...line...from...kuber...admin...conf...' |base64 -d > ./client-cert.pem
echo 'LS0tLS1CR...other...long...line...from...kuber...admin...conf...' |base64 -d > ./client-key.pem
```
Then save to local files and upload as cred files to Jenkins

## Global Configs
### Env vars 
-- key: KUBE_SERVER
   value: http://host:port from kuber admin.conf
   description: Kuber cluster IP for certs 

## Multibranch Pipeline:
### Branch Sources:
- git
- Project Repository: https://github.com/Scandr/nginx_cicd_source.git
- Credentials: none
- Behaviours: Discover branches + Discover tags
- Property strategy: All branches get the same properties
- Build strategies: Regular branches + Tags
- Build Configuration: 
  - Mode: By Jenkinsfile
  - Script Path: Jenkinsfile
- Scan Multibranch Pipeline Triggers: Periodically if not otherwise run
  - Interval: 1 min (for tests)
- Orphaned Item Strategy:
  - Discard old items:
    - Max # of old items to keep: 100

# Set Nginx 
For CI/CD test only index page + default root path are changed <br>
## Directories and files:
- ./source: contains config files for nginx application, including basic pages for default dir
- ./kuber_manifests: original manifests, deployed with the cluster 

