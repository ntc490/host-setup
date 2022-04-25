# Nathan's host-setup playbooks

This repo consists of host configuration scripts and dotfiles.  It
uses Ansible playbooks and roles.  You could modify the playbook to
operate on remote machines, but I have written them for use on
localhost.

### Including/Excluding Roles

You can use Ansible tags to pick one or more items to setup on your
system, or to skip certain items using the --tags and --skip-tags
switches.  Use different playbooks to select gross categories of
things.

Here's an example:

    ansible-playbook -t ssh-config --ask-sudo-pass main.yml

### Modules

See the roles directory structure to get an idea what's included in
this repo.  The bulk of things are defined as roles.  Groupings of
roles can be selected by using different playbooks at the root level
of this repo.

* Packages such as tmux, emacs, etc and their dotfiles


### Dependencies

You'll need ansible on your system to make use of the playbooks and
roles.  Use the following command, or an equivalent, on your machine
to get this awesome tool.

    sudo apt install ansible
