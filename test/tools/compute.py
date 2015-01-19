import logging

from pprint import pformat
from os import environ as env

from novaclient.exceptions import NotFound

from service import nova

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)


def boot(image_name=env['OS_IMG_NAME'], flavor_name=env['OS_FLAVOR'],
        net_label=env['OS_NET'], vm_name=env['OS_VM_NAME'], keypair=env['OS_KEYPAIR']):
    try:
        i = nova.servers.find(name=vm_name)
        logging.info('instance {name} already exists. Delete it.'.format(name=vm_name))
        i.delete()
    except NotFound as e:
        pass

    image = nova.images.find(name=image_name)
    flavor = nova.flavors.find(name=flavor_name)
    net = nova.networks.find(label=net_label)
    nics = [{'net-id': net.id}]
    instance = nova.servers.create(name=vm_name, image=image,
        flavor=flavor, key_name=keypair, nics=nics)

    logging.info('instance name: {}'.format(instance.name))
    logging.info('instance flavor: {}'.format(pformat(instance.flavor)))
    logging.info('instance net: {}'.format(pformat(instance.networks)))
    logging.info('instance image: {}'.format(pformat(instance.image)))
    logging.info('instance status: {}'.format(instance.status)


if __name__ == '__main__':
    from sys import argv
    try:
        boot(vm_name=argv[1])
    except Exception as e:
        boot()
