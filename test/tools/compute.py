import logging
import time

from pprint import pformat
from os import environ as env

from novaclient.exceptions import NotFound

from service import nova


def get_instance(name=None):
    if name is None:
        try:
            name = env['OS_VM_NAME']
        except:
            raise NotFound
    
    return nova.servers.find(name=name)


def boot(image_name=env['OS_IMG_NAME'], flavor_name=env['OS_FLAVOR'],
        net_label=env['OS_NET'], vm_name=env['OS_VM_NAME'], keypair=env['OS_KEYPAIR']):
    image = nova.images.find(name=image_name)

    try:
        instance = get_instance(name=vm_name)
        logging.info('instance {name} already exists.'.format(name=vm_name))
        logging.info('Rebuild it with image<{img}>.'.format(img=image_name))
        instance.rebuild(image)
    except NotFound as e:
        flavor = nova.flavors.find(name=flavor_name)
        net = nova.networks.find(label=net_label)
        nics = [{'net-id': net.id}]
        instance = nova.servers.create(name=vm_name, image=image,
            flavor=flavor, key_name=keypair, nics=nics)

    logging.info('instance name: {}'.format(instance.name))
    logging.info('instance flavor: {}'.format(pformat(instance.flavor)))
    logging.info('instance net: {}'.format(pformat(instance.networks)))
    logging.info('instance image: {}'.format(pformat(instance.image)))
    logging.info('======== Waiting for instance to become active ========')
    instance = get_instance(name=vm_name)
    while instance.status != u'ACTIVE':
            if instance.status == u'ERROR':
                raise Exception('Instance errored')
            logging.info('instance status: {}'.format(instance.status))
            time.sleep(10)
            instance = get_instance(name=vm_name)
    ip = instance.networks.values()[0][0]
    logging.info('instance ip: {}'.format(instance.networks.values()[0][0]))


if __name__ == '__main__':
    from sys import argv
    logger = logging.getLogger(__name__)
    logging.basicConfig(level=logging.DEBUG)

    try:
        boot(vm_name=argv[1])
    except Exception as e:
        boot()
