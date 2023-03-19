#!/bin/bash

GITEA_URL="http://gitea.gunsmoke.local:31468"
GOCD_URL="http://gocd.gunsmoke.local:31468"

GiteaJackStrohm() {
echo "------------------- Setup jackstrohm mirror in Gitea"
curl -H "Content-Type: application/json" -d '{"name":"jackstrohm-initial-setup"}' -u gitea-admin:admin $GITEA_URL'/api/v1/users/gitea-admin/tokens' | tr ',' '\n' | grep sha1 | cut -f2 -d':' | cut -f2 -d'"' >> ./token
TOKEN=`cat token`
echo "Token: $TOKEN"
rm token

curl -X 'POST' \
  $GITEA_URL'/api/v1/repos/migrate' \
  -H "Authorization: token $TOKEN" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{
  \"auth_password\": \"admin\",
  \"auth_token\" : \"$TOKEN\",
  \"auth_username\": \"gitea-admin\",
  \"clone_addr\": \"https://github.com/hoyle1974/jackstrohm.git\",
  \"description\": \"jackstrohm hugo blog\",
  \"issues\": true,
  \"labels\": true,
  \"lfs\": true,
  \"lfs_endpoint\": \"string\",
  \"milestones\": true,
  \"mirror\": true,
  \"mirror_interval\": \"10m0s\",
  \"private\": false,
  \"pull_requests\": true,
  \"releases\": true,
  \"repo_name\": \"jackstrohm\",
  \"repo_owner\": \"gitea-admin\",
  \"service\": \"git\",
  \"uid\": 0,
  \"wiki\": true
}"
}


# https://api.gocd.org/current/#create-a-config-repo
ConfigRepo() {
echo "------------------- Setup jackstrohm build in GOCD"
curl $GOCD_URL'/go/api/admin/config_repos' \
  -H 'Accept:application/vnd.go.cd.v4+json' \
  -H 'Content-Type:application/json' \
  -X POST -d '{
    "id": "jackstrohm",
    "plugin_id": "yaml.config.plugin",
    "material": {
      "type": "git",
      "attributes": {
        "url": "http://gitea-http.gitea.svc.cluster.local:3000/gitea-admin/jackstrohm.git",
        "branch": "main",
        "auto_update": true
      }
    },
    "configuration": [
      {
       "key": "pattern",
       "value": "*.myextension"
     }
    ],
    "rules": [
      {
        "directive": "allow",
        "action": "refer",
        "type": "*",
        "resource": "*"
      }
    ]
  }'
}

# https://api.gocd.org/current/#create-an-elastic-agent-profile
ElasticAgentProfile() {
curl $GOCD_URL'/go/api/elastic/profiles' \
      -H 'Accept: application/vnd.go.cd.v2+json' \
      -H 'Content-Type: application/json' \
      -X POST -d '{
        "id": "hugo",
        "cluster_profile_id": "k8-cluster-profile",
        "properties": [
          {
            "key": "PodSpecType",
            "value" : "yaml"
          },
          {
            "key": "PodConfiguration",
            "value" : "apiVersion: v1
kind: Pod
metadata:
  name: gocd-agent-hugo
  labels:
    app: web
spec:
  containers:
    - name: gocd-agent-container-hugo
      image: docker.io/jstrohm/gocd-agent-hugo
      env:
        - name: DOCKER_PASSWORD
          valueFrom: 
            secretKeyRef: 
              name: docker-password 
              key: password
      securityContext:
        privileged: true"
          }
        ]
      }'
}

GiteaJackStrohm
ConfigRepo
ElasticAgentProfile
