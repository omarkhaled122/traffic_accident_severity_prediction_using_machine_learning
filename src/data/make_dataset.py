# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Downloads or generates raw data')
@click.argument('input_path', type=click.Path(exists=True))
@click.argument('dataset_path', type=click.Path())
def make_dataset(input_path, dataset_path):
    """Downloads or generates raw data.

    Reads an input file from INPUT_PATH and saves the dataset in
    DATASET_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading inputs from {}'.format(input_path))
    logger.info('saving dataset in {}'.format(dataset_path))
