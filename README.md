# 利用gitlab测试云厂商自动构建服务

## :boom:  gitlab CICD完整配置文件
### 环境变量：
![](https://github.com/liuyl1992/NetCoreCICD/blob/master/environmentvariable.png)

DOCKER_PATH  Docker文件路径
DOCKER_PWD   Docker密码 
DOCKER_REP   Docker仓库地址 
DOCKER_USER  Docker用户
IMAGE_NAME   镜像名称


### 对应完整配置文件：
```yml

stages:
  - build
  - login
  - tag
  - push
  - recover
  - deploy

#**************************build******************************** 

job_build:
#镜像打包
  stage: build
  tags:
    - aliyun 
  only:
    - hotfix
    
  before_script:
    - echo 执行的runner名称-- $CI_RUNNER_DESCRIPTION
    - echo 仓库地址-- $DOCKER_REP
    - echo 镜像名称-- $IMAGE_NAME
    
    - echo 执行的runner名称-- $CI_RUNNER_DESCRIPTION
    - export COMMIT_TIME=$(git show -s --format=%ct $CI_COMMIT_SHA)
    - export TIME_STAMP=`date -d @${COMMIT_TIME} +%Y%m%d%H%M%S`
    - echo $TIME_STAMP
   
  script:
    - who
    - pwd
    - docker ps
    
    - docker build -f ${DOCKER_PATH} -t ${IMAGE_NAME}:${CI_COMMIT_SHA} ${DOCKER_BUILD_PATH}
    - docker images -a
    - echo 镜像打包成功
    
#***************************tag********************************

job_tag:
#重命名镜像
  stage: tag
  tags:
    - aliyun 
  only:
    - hotfix
    
  before_script:
    - export COMMIT_TIME=$(git show -s --format=%ct $CI_COMMIT_SHA)
    - export TIME_STAMP=`date -d @${COMMIT_TIME} +%Y%m%d%H%M%S`
    - echo $TIME_STAMP
   
  script:
    - docker images -a
    - echo ${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP}
    - docker tag ${IMAGE_NAME}:${CI_COMMIT_SHA} ${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP}
    - echo 镜像tag重命名成功
    
#****************************login*******************************

job_login:
#登录
  stage: login
  tags:
    - aliyun 
  only:
    - hotfix
   
  script:
    - docker login  -u ${DOCKER_USER} -p ${DOCKER_PWD} ${DOCKER_REP}
    - echo 镜像仓库登录成功

#*****************************push******************************
job_push:
#推送镜像
  stage: push
  tags:
    - aliyun 
  only:
    - hotfix
    
  before_script:
    - export COMMIT_TIME=$(git show -s --format=%ct $CI_COMMIT_SHA)
    - export TIME_STAMP=`date -d @${COMMIT_TIME} +%Y%m%d%H%M%S`
    - echo $TIME_STAMP
   
  script:
    - docker push ${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP}

    - echo 镜像 ${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP} 推送成功
    
#****************************recover*********************************

job_recover:
#回复初始环境
  stage: recover
  tags:
    - aliyun 
  only:
    - hotfix
    
  before_script:
    - export COMMIT_TIME=$(git show -s --format=%ct $CI_COMMIT_SHA)
    - export TIME_STAMP=`date -d @${COMMIT_TIME} +%Y%m%d%H%M%S`
    - echo $TIME_STAMP
   
  script:
    #删除没有运行的容器
    - docker container prune -f
    #删除构建过程中产生的中间镜像例如none的镜像
    - docker rmi $(docker images -f "dangling=true" -q) 
    - docker rmi -f ${IMAGE_NAME}:${CI_COMMIT_SHA}
    - docker rmi -f ${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP}
    - echo 清空后的本地镜像
    - docker images -a

    - echo 本地镜像清除完毕

#****************************deploy*********************************

job_deploy:
  stage: deploy
  tags:
    - aliyun 
  only:
    - hotfix
    
  before_script:
    - export COMMIT_TIME=$(git show -s --format=%ct $CI_COMMIT_SHA)
    - export TIME_STAMP=`date -d @${COMMIT_TIME} +%Y%m%d%H%M%S`
    - echo $TIME_STAMP
    
  script:
    - echo $DOCKER_REP/$IMAGE_NAME:$CI_COMMIT_REF_SLUG-$TIME_STAMP
    # 更新k8s服务的镜像，这里默认deployment和容器名称和镜像名一致
    - kubectl set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=${DOCKER_REP}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}-${TIME_STAMP}
    
    - echo 服务镜像已更新

    
```

