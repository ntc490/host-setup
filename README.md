# Nathan's host-setup playbooks

This repo consists of host configuration scripts and dotfiles.  It
uses Ansible playbooks and roles.  You could modify the playbook to
operate on remote machines, but I have written them for use on
localhost.

### Supported Distros

These distros should be well supported/tested:

- Arch
- Rocky9
- MacOS via brew

I don't use these distros as often. Use tags to skip things, etc.

- Ubuntu

### Including/Excluding Roles

You can use Ansible tags to pick one or more items to setup on your
system, or to skip certain items using the --tags and --skip-tags
switches.  Use different playbooks to select gross categories of
things.

Here's an example:

    ansible-playbook -t ssh-config --ask-sudo-pass main.yml

### Rocky9

In order to get Rocky9 working, you have to run some commands before
the 'main' Ansible Playbook will run. Maybe I will automate this in
the future. However, it's a pretty fundamental requirement and doesn't
appear to be easy to setup via Ansible.

    sudo dnf config-manager --set-enabled crb
    sudo dnf install \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm

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
