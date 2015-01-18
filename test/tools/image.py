from __future__ import print_function
from pprint import pprint
from subprocess import check_output
from os import environ as env

from novaclient.exceptions import NotFound
from service import glance, nova


def upload():
    """
    create or update the ``env['OS_IMG_NAME']``
    """
    img_list = list(glance.images.list())
    img_name = env['OS_IMG_NAME']
    img_path = env['MD_FILE']

    img_args = {
        'name': img_name,
        'is_public': 'False',
        'disk_format': 'raw',
        'container_format': 'bare',
        'description': " \n".join([ 
                "uname: {0}".format(check_output(['uname', '-msKr']).strip('\n')),
                "installer: {0}".format(env['INSTALLER_REV']),
            ]),
    }
    try:
        img = nova.images.find(name=img_name)
        print('delete old image {}'.format(img.id))
        glance.images.delete(img.id)
    except NotFound:
        pass


    img = glance.images.create(name=img_args['name'],
        public=img_args['is_public'],
        disk_format=img_args['disk_format'],
        container_format=img_args['container_format'],
        description=img_args['description'],
    )
    print('image info:')
    pprint(img)
    with open(img_path) as fimg:
        print('uploading image...', end='')
        glance.images.upload(image_id=img.id, image_data=fimg)
        print('done')



if __name__ == '__main__':
    upload()
