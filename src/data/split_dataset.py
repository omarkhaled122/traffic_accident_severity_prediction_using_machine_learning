# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Splits dataset in training and test sets.')
@click.argument('dataset_path', type=click.Path(exists=True))
@click.argument('trainset_path', type=click.Path())
@click.argument('testset_path', type=click.Path())
def split_dataset(dataset_path, trainset_path, testset_path):
    """Splits dataset in training and test sets.

    Reads a dataset from DATASET_PATH and saves the training set in
    TRAINSET_PATH and the test set in TESTSET_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading dataset from {}'.format(dataset_path))
    logger.info('saving train set in {}'.format(trainset_path))
    logger.info('saving test set in {}'.format(testset_path))
