k8s_deploy_deployment "brat" do
  git_repo "git@github.com:cassj/brat-docker.git"
  template "brat"
  namespace node['k8s_deploy']['namespace']
end
