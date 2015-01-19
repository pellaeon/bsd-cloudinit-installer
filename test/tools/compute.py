from os import environ as env

from service import nova


def boot(image_name=env['OS_IMG_NAME'], flavor_name=env['OS_FLAVOR'],
        net_label=env['OS_NET'], vm_name=env['OS_VM_NAME'], keypair=env['OS_KEYPAIR']):
    image = nova.images.find(name=image_name)
    flavor = nova.flavors.find(name=flavor_name)
    net = nova.networks.find(label=net_label)
    nics = [{'net-id': net.id}]
    instance = nova.servers.create(name=vm_name, image=image,
    flavor=flavor, key_name=keypair, nics=nics)


if __name__ == '__main__':
    from sys import argv
    try:
        boot(image_name=argv[1])
    except Exception as e:
        boot
