action :deploy do  
  namespace = new_resource.namespace
  yaml_dir = "/etc/kubernetes/#{namespace}/jobs"
  project = new_resource.project
  version = Time.now.strftime('%Y%m%d%H%M%S').to_s
  template = new_resource.template
  template_vars = new_resource.template_vars
  git_repo = new_resource.git_repo
  git_branch = new_resource.git_branch
  with_cron = new_resource.with_cron
  git_version = "unknown"

  ruby_block "deploy" do
    block do
      extend Chef::Mixin::ShellOut     
      git_version = shell_out("GIT_SSH=/tmp/private_code/wrap-ssh4git.sh git ls-remote #{git_repo} #{git_branch} | awk '{printf $1}'").stdout
    end
  end

  directory yaml_dir do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  template "#{yaml_dir}/#{project}.yaml" do
    source "job/#{template}.yaml.erb"
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

  cron "k8s job #{project}" do
    action with_cron ? :create : :delete
    minute new_resource.minute
    hour new_resource.hour
    day new_resource.day
    weekday new_resource.weekday
    month new_resource.month
    command %Q(/usr/local/bin/kubectl delete --ignore-not-found=true -f #{yaml_dir}/#{project}.yaml && /usr/local/bin/kubectl create -f #{yaml_dir}/#{project}.yaml)
  end
end
