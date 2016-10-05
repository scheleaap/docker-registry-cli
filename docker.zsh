function docker-connect {
  docker exec -i -t $1 sh
}

function docker-clean-images {
  docker rmi $(docker images | grep "<none>" | tr -s " " | cut -d " " -f 3)
}

function docker-clean-containers {
  docker rm  $(docker ps --filter "status=exited" --quiet)
}

function docker-kill-clean {
  if [ "$(docker ps -q)" != "" ]; then
    echo "Kill running containers"
    docker kill $(docker ps --quiet)
    echo
  fi
  if [ "$(docker ps -aq)" != "" ]; then
    echo 'Remove all containers'
    docker rm $(docker ps --quiet --all)
    echo
  fi
  #docker network rm $(docker network ls --filter driver=bridge | grep -v -E -e "(NETWORK ID .*|.*\s+bridge\s+bridge\s+.*)" | sed -r 's/(\w+).*/\1/')
  docker network rm $(docker network ls --filter driver=bridge --quiet)
  echo
}

function docker-list-tags {
  function printUsage {
    echo "Usage: $1 [-f|--full] URL" >&2
  }
  
  local printFullUrl="false"
  while [[ $# -gt 0 ]]
  do
    argument="$1"
    case ${argument} in
      -f|--full)
        printFullUrl="true"
        shift
        ;;
      -*)
        echo "Unknown argument ${argument}" >&2
        printUsage $0
        return 1
        ;;
      *)
        # Not an option, stop processing options
        break
        ;;
    esac
  done

  if [ $# -ne 1 ]; then
    printUsage $0
    return 1
  fi

  local url=${1}
  local registry=$(echo ${url} | cut -d'/' -f1 )
  local name=$(echo ${url} | cut -d'/' -f2-)
  echo ${url} ${registry} ${name} ${printFullUrl} 
  
  for tag in $(curl -s -S http://${registry}/v2/${name}/tags/list | jq -r '.tags | join("\n")' | sort); do
    if [ "${printFullUrl}" = "true" ]; then
      echo ${url}:${tag}
    else
      echo ${tag}
    fi
  done | column


}
# docker run -it --rm alpine /bin/sh
