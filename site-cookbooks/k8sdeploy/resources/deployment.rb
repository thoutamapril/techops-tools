actions :deploy
default_action :deploy

attribute :project, kind_of: String, name_attribute: true
attribute :namespace, kind_of: String, default: 'default'
attribute :git_repo, kind_of: String
attribute :git_branch, kind_of: String, default: 'heads/master'
attribute :template, kind_of: String
attribute :template_vars, kind_of: Hash, default: {}
