require 'json'

action :deploy do
  namespace = new_resource.namespace
  yaml_dir = "/etc/kubernetes/#{namespace}"
  project = new_resource.project
  version = Time.now.strftime('%Y%m%d%H%M%S').to_s
  template = new_resource.template
  template_vars = new_resource.template_vars
  git_repo = new_resource.git_repo
  git_branch = new_resource.git_branch
  git_version = "unknown"
  pod_checker = "/etc/kubernetes/k8s-pod-checker.sh"

  ruby_block "deploy" do
    block do
      if git_repo != nil
        extend Chef::Mixin::ShellOut
        git_version = shell_out("GIT_SSH=/tmp/private_code/wrap-ssh4git.sh git ls-remote #{git_repo} #{git_branch} | awk '{printf $1}'").stdout
      end
    end
  end

  directory yaml_dir do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  cookbook_file pod_checker do
    source 'tools/k8s-pod-checker.sh'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "#{yaml_dir}/#{project}.yaml" do
    source "deployment/#{template}.yaml.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables lazy {
      {
        namespace: namespace,
        version: version,
        git_version: git_version,
        vars: template_vars
      }
    }
  end

  execute "kubectl apply -n#{namespace} -f #{yaml_dir}/#{project}.yaml" do
    user 'root'
    group 'root'
    command "kubectl apply -n#{namespace} -f #{yaml_dir}/#{project}.yaml"
  end

  execute pod_checker do
    user 'root'
    group 'root'
    command lazy { "#{pod_checker} #{project} #{git_version} #{namespace}" }
  end
end
