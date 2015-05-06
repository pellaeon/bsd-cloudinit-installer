import re

from fabric.api import task, run, sudo, local, env, settings, runs_once
from fabric.tasks import Task
from fabric.utils import abort

from tools.compute import get_instance


env.shell = "/bin/sh -c"
env.use_ssh_config = True
env.colorize_errors = True
env.hosts = [ get_instance().networks.values()[0][0] ]
env.user = 'freebsd'
env.abort_on_prompts = True


@task
def test_disk_usage():
    run('df -h')


@task
def test_check_log():
    log = run('cat /tmp/cloudinit.log')
    if re.search('CRITICAL', log):
        abort('bsd-cloudinit got CRITICAL error')


@task
def test_sudo():
    sudo('ls /root')


@task
def pkg(cmd=None):
    if cmd is None:
        return

    sudo('pkg {}'.format(cmd))


@task
def install_pkg(pkg_list):
    sudo('pkg install -y {}'.format(' '.join(pkg_list)))


@task
def test_rc_conf():
    run('cat /etc/rc.conf')


@task
def test_loader_conf():
    run('cat /boot/loader.conf')


@task
def test_password():
    pass


@task
def test_id():
    run('id')


@task
def test_permision():
    pass


@task
@runs_once
def main():
    tuple(map(
        lambda x: x[1]() if isinstance(x[1], Task) else None,
        filter(
            lambda x: bool(re.match('test', x[0])),
            globals().iteritems()
        )
    ))
