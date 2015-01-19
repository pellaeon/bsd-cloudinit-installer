from __future__ import print_function

import logging

from pprint import pprint, pformat
from subprocess import check_output
from os import environ as env

from novaclient.exceptions import NotFound
from service import glance, nova


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)


def upload(img_name=env['OS_IMG_NAME'], img_path=env['OS_IMG_FILE']):
    """
    create or update the ``env['OS_IMG_NAME']``
    """
    img_list = list(glance.images.list())

    img_args = {
        'name': img_name,
        'is_public': 'False',
        'disk_format': 'raw',
        'container_format': 'bare',
        'description': "\r".join([
                "uname: {0}".format(check_output(['uname', '-msKr']).strip('\n')),
                "installer: {0}".format(env['INSTALLER_REV']),
            ]),
    }

    try:
        img = nova.images.find(name=img_name)
        logger.info('Old image {name} <{id}> exists.'.format(name=img.name, id=img.id))
        logger.info('Delete old image {name} <{id}>'.format(name=img.name, id=img.id))
        glance.images.delete(img.id)
    except NotFound:
        pass


    img = glance.images.create(name=img_args['name'],
        public=img_args['is_public'],
        disk_format=img_args['disk_format'],
        container_format=img_args['container_format'],
        description=img_args['description'],
    )
    logger.debug('Image info: {0}'.format(pformat(img)))
    logger.info('Start upload image {name} <{id}>'.format(name=img.name, id=img.id))
    with open(img_path) as fimg:
        glance.images.upload(image_id=img.id, image_data=fimg)
    logger.info('Uploading of {name} <{id}> finished.'.format(name=img.name, id=img.id))



if __name__ == '__main__':
    upload()
